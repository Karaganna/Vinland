# res://scripts/game_manager.gd
extends Node

## Сигналы перехода состояний игры
signal battle_started(enemy: EnemyData)
signal battle_ended(victory: bool, by_vow: bool)
signal location_changed(location_id: String)

const DEFAULT_BATTLE_SCENE_PATH: String = "res://scenes/battle_sandbox.tscn"

## Сохраненная позиция игрока в мире перед битвой или при переходе между локациями
var saved_player_position: Vector2 = Vector2.ZERO
## Флаг наличия валидной сохраненной позиции (для переходов между локациями мира)
var has_saved_player_position: bool = false
## Путь к сцене, из которой начался бой, для точного возврата (legacy-совместимость)
var saved_return_scene_path: String = ""

## Контекст новой модульной боевой сессии и возврата в оверворлд
var pending_enemy_data: EnemyData = null
var pending_enemies: Array[EnemyData] = []
var return_scene_path: String = ""
var return_player_position: Vector2 = Vector2.ZERO
var has_return_position: bool = false
var active_encounter_id: String = ""
## Реестр побежденных одноразовых энкаунтеров {encounter_id: true}
var defeated_encounters: Dictionary = {}

## Активный отряд игрока (задел под до 4 бойцов) и снимки сохраняемых HP / Маны
var party_roster: Array[CombatantData] = []
var party_runtime_snapshots: Dictionary = {}

## Глобальный инвентарь отряда и каталог парных оружейных синергий
var inventory: InventoryState = null
var synergy_catalog: Array[WeaponSynergyData] = []

## Текущая активная локация мира ("home" или "village")
var current_location_id: String = "home"
## Данные текущего противника (legacy-совместимость)
var current_enemy: EnemyData = null
## Флаг нахождения в битве
var is_in_battle: bool = false

## Задержка после окончания/побега из боя (сек), чтобы бой не начался повторно мгновенно
@export var post_battle_grace_seconds: float = 2.5
var _post_battle_grace_until_msec: int = 0

## Пути к сценам
@export var overworld_scene_path: String = "res://scenes/battle_arena.tscn"
@export var village_scene_path: String = "res://scenes/village_location.tscn"
@export var battle_scene_path: String = DEFAULT_BATTLE_SCENE_PATH

## Инициализирует общий инвентарь и каталог оружейных синергий, если еще не созданы
func ensure_inventory_initialized() -> void:
	if synergy_catalog.is_empty():
		synergy_catalog = InventorySandboxFactory.create_synergy_catalog()
	if inventory == null:
		inventory = InventorySandboxFactory.create_starter_inventory()

## Инициализирует отряд игрока стартовым героем и инвентарем, если отряд еще пуст
func ensure_party_initialized() -> void:
	ensure_inventory_initialized()
	if not party_roster.is_empty():
		return
	party_roster.append(BattleSandboxFactory.create_sandbox_hero())

## Собирает runtime-отряд игрока (до 4 бойцов) с переносом HP и Маны и сбросом Энергии/Ярости/Напряжения
func build_player_party_for_battle() -> Array[Combatant]:
	ensure_party_initialized()
	
	var party: Array[Combatant] = []
	var limit: int = mini(party_roster.size(), BattleContext.MAX_PLAYER_PARTY_SIZE)
	for i: int in range(limit):
		var member_data: CombatantData = party_roster[i]
		if member_data == null:
			continue
		var member_id: String = _resolve_member_id(member_data, i)
		
		var combatant: Combatant = Combatant.from_combatant_data(member_data, member_id, synergy_catalog)
		if party_runtime_snapshots.has(member_id):
			var snap: Dictionary = party_runtime_snapshots[member_id] as Dictionary
			if snap.has("current_hp"):
				var saved_hp: int = int(snap.get("current_hp", combatant.max_hp))
				combatant.current_hp = clampi(saved_hp, 0, combatant.max_hp)
			if bool(snap.get("has_mana", false)) and combatant.resources.has_resource(BattleTypes.ResourceType.MANA):
				var saved_mana: int = int(snap.get("current_mana", combatant.resources.get_current(BattleTypes.ResourceType.MANA)))
				combatant.resources.set_current(BattleTypes.ResourceType.MANA, saved_mana)
		
		party.append(combatant)
	
	# Гарантируем наличие хотя бы одного живого бойца перед стартом боя
	var has_alive: bool = false
	for c: Combatant in party:
		if c.is_alive():
			has_alive = true
			break
	if not has_alive and not party.is_empty():
		party[0].current_hp = maxi(1, party[0].max_hp)
	
	return party

## Полный отдых в лагере/доме: восстанавливает HP и Ману всего отряда с учетом экипировки
func rest_at_camp() -> void:
	ensure_party_initialized()
	party_runtime_snapshots.clear()
	for i: int in range(party_roster.size()):
		var member_data: CombatantData = party_roster[i]
		if member_data == null:
			continue
		var member_id: String = _resolve_member_id(member_data, i)
		var preview: Combatant = Combatant.from_combatant_data(member_data, member_id, synergy_catalog)
		var true_max_hp: int = maxi(1, preview.max_hp)
		var has_mana: bool = preview.resources.has_resource(BattleTypes.ResourceType.MANA)
		var true_max_mana: int = preview.resources.get_max(BattleTypes.ResourceType.MANA)
		party_runtime_snapshots[member_id] = {
			"combatant_id": member_id,
			"current_hp": true_max_hp,
			"max_hp": true_max_hp,
			"has_mana": has_mana,
			"current_mana": true_max_mana,
			"max_mana": maxi(1, true_max_mana)
		}

## Возвращает актуальные статы, HP/Ману и активные синергии бойца с учетом экипировки для UI мира
func get_party_member_status(member_data: CombatantData) -> Dictionary:
	ensure_party_initialized()
	if member_data == null:
		return {}
	var idx: int = party_roster.find(member_data)
	var member_id: String = _resolve_member_id(member_data, maxi(0, idx))
	var preview: Combatant = Combatant.from_combatant_data(member_data, member_id, synergy_catalog)
	var cur_hp: int = preview.max_hp
	var cur_mana: int = preview.resources.get_current(BattleTypes.ResourceType.MANA)
	var has_mana: bool = preview.resources.has_resource(BattleTypes.ResourceType.MANA)
	var max_mana: int = preview.resources.get_max(BattleTypes.ResourceType.MANA)
	
	if party_runtime_snapshots.has(member_id):
		var snap: Dictionary = party_runtime_snapshots[member_id] as Dictionary
		if snap.has("current_hp"):
			cur_hp = clampi(int(snap.get("current_hp", cur_hp)), 1, preview.max_hp)
		if has_mana and bool(snap.get("has_mana", false)) and snap.has("current_mana"):
			cur_mana = clampi(int(snap.get("current_mana", cur_mana)), 0, max_mana)
	
	return {
		"combatant_id": member_id,
		"display_name": preview.display_name,
		"current_hp": cur_hp,
		"max_hp": preview.max_hp,
		"has_mana": has_mana,
		"current_mana": cur_mana,
		"max_mana": max_mana,
		"attack": preview.get_base_attack_without_rage(),
		"magic_power": preview.get_effective_magic(),
		"defense": preview.get_effective_defense(),
		"speed": preview.get_effective_speed(),
		"crit_chance": preview.get_effective_crit_chance(),
		"crit_multiplier": preview.get_effective_crit_multiplier(),
		"active_synergies": preview.active_synergies,
		"qte_override": preview.get_effective_qte_override()
	}

## Применяет расходник к бойцу вне боя (в оверворлде) и обновляет снимок HP/Маны
func use_overworld_consumable(member_data: CombatantData, item: ConsumableItemData) -> Dictionary:
	ensure_party_initialized()
	if member_data == null or item == null:
		return {"ok": false, "message": "Не указан боец или расходник."}
	if not item.usable_in_overworld:
		return {"ok": false, "message": "«%s» можно применять только в бою." % item.display_name}
	if inventory == null or inventory.get_item_count(item.item_id) <= 0:
		return {"ok": false, "message": "Предмет закончился."}
	
	var status: Dictionary = get_party_member_status(member_data)
	var member_id: String = str(status.get("combatant_id", ""))
	var cur_hp: int = int(status.get("current_hp", 1))
	var max_hp_val: int = int(status.get("max_hp", 1))
	var has_mana: bool = bool(status.get("has_mana", false))
	var cur_mana: int = int(status.get("current_mana", 0))
	var max_mana_val: int = int(status.get("max_mana", 100))
	
	var healed_hp: int = 0
	if item.heal_hp > 0 and cur_hp < max_hp_val:
		var next_hp: int = mini(max_hp_val, cur_hp + item.heal_hp)
		healed_hp = next_hp - cur_hp
		cur_hp = next_hp
	
	var restored_mana: int = 0
	if item.restore_resource_amount > 0 and item.restore_resource_type == BattleTypes.ResourceType.MANA and has_mana and cur_mana < max_mana_val:
		var next_mana: int = mini(max_mana_val, cur_mana + item.restore_resource_amount)
		restored_mana = next_mana - cur_mana
		cur_mana = next_mana
	
	if healed_hp <= 0 and restored_mana <= 0:
		return {"ok": false, "message": "HP и Мана уже максимальны."}
	
	if not inventory.remove_item(item.item_id, 1):
		return {"ok": false, "message": "Не удалось списать предмет из инвентаря."}
	
	party_runtime_snapshots[member_id] = {
		"combatant_id": member_id,
		"current_hp": cur_hp,
		"max_hp": max_hp_val,
		"has_mana": has_mana,
		"current_mana": cur_mana,
		"max_mana": maxi(1, max_mana_val)
	}
	
	var parts: PackedStringArray = PackedStringArray()
	if healed_hp > 0:
		parts.append("+%d HP" % healed_hp)
	if restored_mana > 0:
		parts.append("+%d Маны" % restored_mana)
	return {"ok": true, "message": "Использовано «%s»: %s." % [item.display_name, ", ".join(parts)]}

func _resolve_member_id(member_data: CombatantData, index: int) -> String:
	var member_id: String = member_data.combatant_id.strip_edges() if member_data != null else ""
	if member_id.is_empty():
		member_id = "hero_%d" % (index + 1)
	return member_id

## Сбрасывает сохраненную позицию игрока после восстановления
func clear_saved_player_position() -> void:
	has_saved_player_position = false
	saved_player_position = Vector2.ZERO
	has_return_position = false
	return_player_position = Vector2.ZERO

## Извлекает позицию возврата из боя и сбрасывает флаги
func consume_return_position() -> Dictionary:
	var result: Dictionary = {
		"valid": has_return_position,
		"position": return_player_position
	}
	has_return_position = false
	return_player_position = Vector2.ZERO
	has_saved_player_position = false
	saved_player_position = Vector2.ZERO
	return result

## Проверяет, побежден ли ранее одноразовый энкаунтер с указанным ключом
func is_encounter_defeated(encounter_id: String) -> bool:
	var key: String = encounter_id.strip_edges()
	if key.is_empty():
		return false
	return bool(defeated_encounters.get(key, false))

## Проверяет, ожидают ли в GameManager данные для старта боя из оверворлда
func has_pending_battle() -> bool:
	return pending_enemy_data != null or not pending_enemies.is_empty()

## Возвращает список врагов, ожидающих старта боя
func get_pending_enemies() -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	for e: EnemyData in pending_enemies:
		if e != null:
			result.append(e)
	if result.is_empty() and pending_enemy_data != null:
		result.append(pending_enemy_data)
	return result

## Проверяет, активен ли защитный интервал после завершения/побега из боя
func is_in_post_battle_grace() -> bool:
	return Time.get_ticks_msec() < _post_battle_grace_until_msec

## Запуск битвы из оверворлда: сохраняет врага, сцену возврата, позицию и ID триггера
func start_battle(
	enemy_data: EnemyData,
	return_scene: String,
	player_pos: Vector2,
	encounter_id: String = "",
	target_battle_scene: String = DEFAULT_BATTLE_SCENE_PATH
) -> void:
	if is_in_battle:
		return
	
	is_in_battle = true
	
	var resolved_return: String = return_scene.strip_edges()
	if resolved_return.is_empty():
		var current_scene: Node = get_tree().current_scene
		if current_scene != null and not current_scene.scene_file_path.is_empty():
			resolved_return = current_scene.scene_file_path
	
	return_scene_path = resolved_return
	saved_return_scene_path = resolved_return
	
	return_player_position = player_pos
	has_return_position = true
	saved_player_position = player_pos
	has_saved_player_position = true
	active_encounter_id = encounter_id.strip_edges()
	
	var enemy_copy: EnemyData = enemy_data.clone() if enemy_data != null else BattleSandboxFactory.create_young_dragon()
	pending_enemy_data = enemy_copy
	pending_enemies.clear()
	pending_enemies.append(enemy_copy)
	current_enemy = enemy_copy
	
	battle_started.emit(pending_enemy_data)
	
	var resolved_battle_scene: String = target_battle_scene.strip_edges()
	if resolved_battle_scene.is_empty():
		resolved_battle_scene = battle_scene_path if not battle_scene_path.is_empty() else DEFAULT_BATTLE_SCENE_PATH
	call_deferred("_switch_to_battle_scene", resolved_battle_scene)

## Завершение боя из новой боевой системы (обновляет HP/Ману отряда, отмечает триггер и возвращает в мир)
func finish_battle(outcome: String, party_snapshot: Array[Dictionary]) -> void:
	var normalized: String = outcome.strip_edges().to_lower()
	var is_vow: bool = normalized == "vow" or normalized == "pacified"
	var is_victory: bool = normalized == "victory" or is_vow
	var is_defeat: bool = normalized == "defeat"
	
	is_in_battle = false
	_post_battle_grace_until_msec = Time.get_ticks_msec() + roundi(post_battle_grace_seconds * 1000.0)
	
	if is_victory and not active_encounter_id.is_empty():
		defeated_encounters[active_encounter_id] = true
	
	if is_defeat:
		if party_snapshot.is_empty():
			rest_at_camp()
		else:
			_apply_party_snapshots(party_snapshot, true)
	elif not party_snapshot.is_empty():
		_apply_party_snapshots(party_snapshot, false)
	
	pending_enemy_data = null
	pending_enemies.clear()
	current_enemy = null
	active_encounter_id = ""
	
	battle_ended.emit(is_victory, is_vow)
	
	if not return_scene_path.is_empty() or not saved_return_scene_path.is_empty():
		call_deferred("_transition_to_overworld")

## Совместимый метод возврата в открытый мир (для старой арены и прямого вызова)
func return_to_overworld(victory: bool, by_vow: bool) -> void:
	is_in_battle = false
	_post_battle_grace_until_msec = Time.get_ticks_msec() + roundi(post_battle_grace_seconds * 1000.0)
	if victory and not active_encounter_id.is_empty():
		defeated_encounters[active_encounter_id] = true
	pending_enemy_data = null
	pending_enemies.clear()
	current_enemy = null
	active_encounter_id = ""
	battle_ended.emit(victory, by_vow)
	
	call_deferred("_transition_to_overworld")

func _apply_party_snapshots(party_snapshot: Array[Dictionary], restore_base_hp: bool) -> void:
	ensure_party_initialized()
	for snap: Dictionary in party_snapshot:
		var cid: String = str(snap.get("combatant_id", "")).strip_edges()
		if cid.is_empty():
			continue
		var max_hp_val: int = maxi(1, int(snap.get("max_hp", 100)))
		var cur_hp_val: int = max_hp_val if restore_base_hp else clampi(int(snap.get("current_hp", max_hp_val)), 0, max_hp_val)
		var has_mana: bool = bool(snap.get("has_mana", false))
		var max_mana_val: int = maxi(1, int(snap.get("max_mana", 100)))
		var cur_mana_val: int = clampi(int(snap.get("current_mana", max_mana_val)), 0, max_mana_val)
		party_runtime_snapshots[cid] = {
			"combatant_id": cid,
			"current_hp": cur_hp_val,
			"max_hp": max_hp_val,
			"has_mana": has_mana,
			"current_mana": cur_mana_val,
			"max_mana": max_mana_val
		}

func _switch_to_battle_scene(target_scene_path: String) -> void:
	if not target_scene_path.is_empty() and ResourceLoader.exists(target_scene_path):
		var err: Error = get_tree().change_scene_to_file(target_scene_path)
		if err == OK:
			return
		push_warning("GameManager: не удалось переключить сцену боя %s (код %d)" % [target_scene_path, int(err)])
	
	if not battle_scene_path.is_empty() and battle_scene_path != target_scene_path and ResourceLoader.exists(battle_scene_path):
		get_tree().change_scene_to_file(battle_scene_path)
		return
	
	# Запасной программный фолбэк, если сцена боя не найдена
	var battle_script: GDScript = load("res://scripts/battle_scene.gd") as GDScript
	if battle_script == null:
		push_error("GameManager: не удалось загрузить запасной скрипт battle_scene.gd")
		is_in_battle = false
		return
	var battle_node: Node = battle_script.new() as Node
	if battle_node == null:
		is_in_battle = false
		return
	battle_node.call("init_battle", current_enemy, saved_player_position)
	
	var current: Node = get_tree().current_scene
	if current != null:
		current.queue_free()
	
	get_tree().root.add_child(battle_node)
	get_tree().current_scene = battle_node

## Переход в локацию Деревня
func transition_to_village(spawn_pos: Vector2 = Vector2(340.0, 356.0)) -> void:
	current_location_id = "village"
	saved_player_position = spawn_pos
	has_saved_player_position = true
	has_return_position = false
	return_player_position = Vector2.ZERO
	return_scene_path = ""
	saved_return_scene_path = ""
	location_changed.emit(current_location_id)
	call_deferred("_switch_to_village_scene")

## Возврат в стартовую локацию (Дом героя)
func transition_to_home(spawn_pos: Vector2 = Vector2(640.0, 265.0)) -> void:
	current_location_id = "home"
	saved_player_position = spawn_pos
	has_saved_player_position = true
	has_return_position = false
	return_player_position = Vector2.ZERO
	return_scene_path = ""
	saved_return_scene_path = ""
	location_changed.emit(current_location_id)
	call_deferred("_switch_to_home_scene")

func _switch_to_village_scene() -> void:
	if ResourceLoader.exists(village_scene_path):
		get_tree().change_scene_to_file(village_scene_path)
		return
	
	var village_script: GDScript = load("res://scripts/village_location.gd") as GDScript
	if village_script == null:
		push_error("GameManager: не удалось загрузить запасной скрипт village_location.gd")
		return
	var village_node: Node = village_script.new() as Node
	if village_node == null:
		return
	var current: Node = get_tree().current_scene
	if current != null:
		current.queue_free()
	
	get_tree().root.add_child(village_node)
	get_tree().current_scene = village_node

func _switch_to_home_scene() -> void:
	if ResourceLoader.exists(overworld_scene_path):
		get_tree().change_scene_to_file(overworld_scene_path)
	else:
		push_error("Сцена дома не найдена по пути: " + overworld_scene_path)

func _transition_to_overworld() -> void:
	var target_scene_path: String = return_scene_path.strip_edges()
	if target_scene_path.is_empty():
		target_scene_path = saved_return_scene_path.strip_edges()
	return_scene_path = ""
	saved_return_scene_path = ""
	
	if not target_scene_path.is_empty() and ResourceLoader.exists(target_scene_path):
		get_tree().change_scene_to_file(target_scene_path)
		return
	
	if current_location_id == "village":
		_switch_to_village_scene()
	else:
		_switch_to_home_scene()
