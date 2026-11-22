# res://scripts/battle/combatant.gd
class_name Combatant
extends RefCounted

## Сигналы runtime-состояния бойца (строго снизу вверх)
signal hp_changed(current_hp: int, max_hp: int)
signal resolve_changed(current_resolve: int, max_resolve: int)
signal died(combatant: Combatant)
signal status_applied(status_type: BattleTypes.StatusType)
signal status_removed(status_type: BattleTypes.StatusType)
signal part_broken(part_id: String)
signal telegraph_started(skill: SkillData, warning_text: String)
signal telegraph_cleared()

var runtime_id: String = ""
var display_name: String = "Боец"
var is_player_controlled: bool = false
var sprite_color: Color = Color.WHITE

var stats: CombatStatsData = null
var max_hp: int = 100
var current_hp: int = 100

## Характеристики примирения (совместимость с системой Завета)
var max_resolve: int = 100
var current_resolve: int = 0
var resolve_per_vow: int = 35

var resources: ResourcePool = null
var basic_attack: SkillData = null
var skills: Array[SkillData] = []
var ultimate_skill: SkillData = null

var equipment_modifiers: Array[EquipmentModifierStub] = []
var item_slots: Array[ItemSlotStub] = []
var rune_slots: Array[RuneSlotStub] = []

var parts: Array[EnemyPartState] = []
var statuses: Array[StatusEffectInstance] = []

var is_blocking: bool = false
var block_energy_restore: int = 20

var pending_telegraph_skill: SkillData = null
var telegraph_turns_left: int = 0

var source_enemy_data: EnemyData = null

func _init() -> void:
	resources = ResourcePool.new()
	stats = CombatStatsData.new()

## Создает runtime-бойца для отряда игрока из иммутабельного ресурса CombatantData
static func from_combatant_data(data: CombatantData, p_runtime_id: String = "") -> Combatant:
	var c: Combatant = Combatant.new()
	if data == null:
		return c
	
	c.runtime_id = p_runtime_id if not p_runtime_id.is_empty() else data.combatant_id
	c.display_name = data.display_name
	c.is_player_controlled = data.is_player_controlled
	c.sprite_color = data.sprite_color
	c.stats = data.stats.create_copy() if data.stats != null else CombatStatsData.new()
	
	c.equipment_modifiers = data.equipment_modifiers.duplicate()
	c.item_slots = data.item_slots.duplicate()
	c.rune_slots = data.rune_slots.duplicate()
	
	c.max_hp = maxi(1, c.stats.max_hp + c._get_equipment_hp_bonus())
	c.current_hp = c.max_hp
	
	c.basic_attack = data.basic_attack
	c.skills = data.skills.duplicate()
	c.ultimate_skill = data.ultimate_skill
	
	c.resources.energy_low_threshold_ratio = data.energy_low_threshold_ratio
	c.resources.energy_low_outgoing_multiplier = data.energy_low_outgoing_multiplier
	c.resources.energy_low_incoming_multiplier = data.energy_low_incoming_multiplier
	c.resources.ultimate_unlocked = data.ultimate_unlocked
	c.resources.ultimate_max_tier = data.ultimate_max_tier
	
	var active_list: Array[BattleTypes.ResourceType] = data.active_resources
	if active_list.has(BattleTypes.ResourceType.ENERGY):
		c.resources.configure_resource(BattleTypes.ResourceType.ENERGY, data.max_energy, data.initial_energy, true)
	if active_list.has(BattleTypes.ResourceType.MANA):
		c.resources.configure_resource(BattleTypes.ResourceType.MANA, data.max_mana, data.initial_mana, true)
	if active_list.has(BattleTypes.ResourceType.RAGE):
		c.resources.configure_resource(BattleTypes.ResourceType.RAGE, data.max_rage, data.initial_rage, true)
	if active_list.has(BattleTypes.ResourceType.TENSION):
		c.resources.configure_resource(BattleTypes.ResourceType.TENSION, data.max_tension, data.initial_tension, true)
	
	return c

## Создает runtime-бойца противника из ресурса EnemyData (с обратной совместимостью со старыми ресурсами)
static func from_enemy_data(data: EnemyData, p_runtime_id: String = "") -> Combatant:
	var c: Combatant = Combatant.new()
	if data == null:
		return c
	
	c.source_enemy_data = data
	var resolved_id: String = p_runtime_id.strip_edges()
	if resolved_id.is_empty():
		resolved_id = data.enemy_id.strip_edges()
	if resolved_id.is_empty():
		resolved_id = "enemy_legacy"
	c.runtime_id = resolved_id
	c.display_name = data.enemy_name if not data.enemy_name.strip_edges().is_empty() else "Противник"
	c.is_player_controlled = false
	c.sprite_color = data.sprite_color
	c.equipment_modifiers = data.equipment_modifiers.duplicate()
	
	if data.combat_stats != null:
		c.stats = data.combat_stats.create_copy()
	else:
		c.stats = CombatStatsData.new()
		c.stats.max_hp = maxi(1, data.max_hp)
		c.stats.attack = maxi(1, data.attack_power)
		c.stats.magic_power = maxi(1, data.attack_power)
		c.stats.defense = maxi(1, roundi(float(data.attack_power) * 0.3))
		c.stats.speed = 10
	
	c.max_hp = maxi(1, c.stats.max_hp + c._get_equipment_hp_bonus())
	if data.combat_stats == null and data.max_hp > 0 and data.current_hp > 0 and data.current_hp < data.max_hp:
		c.current_hp = clampi(data.current_hp, 1, c.max_hp)
	else:
		c.current_hp = c.max_hp
	
	c.max_resolve = maxi(1, data.max_resolve)
	c.current_resolve = clampi(data.current_resolve, 0, c.max_resolve)
	c.resolve_per_vow = data.resolve_per_vow
	
	if data.basic_attack != null:
		c.basic_attack = data.basic_attack
	else:
		c.basic_attack = _create_legacy_basic_attack(data, c.runtime_id)
	
	c.skills.clear()
	for sk: SkillData in data.skills:
		if sk != null:
			c.skills.append(sk)
	
	for res_type: BattleTypes.ResourceType in data.active_resources:
		c.resources.configure_resource(res_type, 100, 50 if res_type == BattleTypes.ResourceType.ENERGY else 0, true)
	
	for part_data: EnemyPartData in data.parts:
		if part_data != null:
			c.parts.append(EnemyPartState.new(part_data))
	
	return c

## Создает базовый навык атаки для старых EnemyData без настроенного SkillData
static func _create_legacy_basic_attack(data: EnemyData, p_enemy_id: String) -> SkillData:
	var fallback: SkillData = SkillData.new()
	fallback.skill_id = "%s_legacy_attack" % p_enemy_id
	fallback.skill_name = "Выпад врага"
	fallback.description = "Базовая атака из классического ресурса EnemyData."
	fallback.action_category = BattleTypes.ActionType.ATTACK
	fallback.target_side = BattleTypes.TargetSide.ENEMY
	fallback.resource_type = BattleTypes.ResourceType.ENERGY
	fallback.resource_cost = 0
	fallback.damage_type = BattleTypes.DamageType.PHYSICAL
	var atk_power: int = data.attack_power if data != null else 10
	fallback.base_power = maxi(4, roundi(float(atk_power) * 0.6))
	fallback.power_multiplier = 1.0
	fallback.blockability = BattleTypes.Blockability.FULL_100
	fallback.requires_qte = false
	return fallback

## Создает снимок сохраняемого состояния бойца (HP и Мана) для переноса между боями
func create_persistent_snapshot() -> Dictionary:
	return {
		"combatant_id": runtime_id,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"has_mana": resources.has_resource(BattleTypes.ResourceType.MANA),
		"current_mana": resources.get_current(BattleTypes.ResourceType.MANA),
		"max_mana": resources.get_max(BattleTypes.ResourceType.MANA)
	}

func is_alive() -> bool:
	return current_hp > 0

func get_base_attack_without_rage() -> int:
	var base_val: int = stats.attack
	for eq: EquipmentModifierStub in equipment_modifiers:
		if eq != null:
			base_val += eq.bonus_attack
	return maxi(1, base_val)

func get_effective_attack() -> int:
	return maxi(1, roundi(float(get_base_attack_without_rage()) * resources.get_rage_attack_multiplier()))

func get_effective_magic() -> int:
	return maxi(1, stats.magic_power)

func get_effective_defense() -> int:
	var base_val: int = stats.defense
	for eq: EquipmentModifierStub in equipment_modifiers:
		if eq != null:
			base_val += eq.bonus_defense
	return maxi(0, base_val)

func get_effective_speed() -> int:
	var base_val: int = stats.speed
	for eq: EquipmentModifierStub in equipment_modifiers:
		if eq != null:
			base_val += eq.bonus_speed
	return maxi(1, base_val + resources.get_rage_speed_bonus())

## Переводит бойца в стойку блока: восстанавливает Энергию и снижает Ярость
func enter_block_stance(energy_gain: int = -1) -> int:
	is_blocking = true
	var restore_amt: int = energy_gain if energy_gain >= 0 else block_energy_restore
	var gained: int = resources.restore_resource(BattleTypes.ResourceType.ENERGY, restore_amt)
	resources.decay_rage_on_idle_or_block()
	return gained

func clear_block_stance() -> void:
	is_blocking = false

## Запускает подготовку (телеграф) спецатаки противника
func start_telegraph(skill: SkillData) -> void:
	if skill == null:
		return
	pending_telegraph_skill = skill
	telegraph_turns_left = maxi(1, skill.telegraph_turns)
	var warning: String = skill.telegraph_warning_text
	if warning.is_empty():
		warning = "%s готовит особую атаку «%s»!" % [display_name, skill.skill_name]
	telegraph_started.emit(skill, warning)

## Продвигает таймер телеграфа на 1 ход и возвращает готовый к применению навык (либо null)
func advance_telegraph() -> SkillData:
	if pending_telegraph_skill == null:
		return null
	telegraph_turns_left -= 1
	if telegraph_turns_left <= 0:
		var ready_skill: SkillData = pending_telegraph_skill
		clear_telegraph()
		return ready_skill
	return null

func clear_telegraph() -> void:
	if pending_telegraph_skill != null:
		pending_telegraph_skill = null
		telegraph_turns_left = 0
		telegraph_cleared.emit()

func is_telegraphing() -> bool:
	return pending_telegraph_skill != null and telegraph_turns_left > 0

## Накладывает или обновляет статус-эффект на бойце
func apply_status(
	status_type: BattleTypes.StatusType,
	duration_turns: int,
	source_id: String = "",
	magnitude: float = 1.0,
	guaranteed_crit: bool = false
) -> void:
	var existing: StatusEffectInstance = get_status(status_type)
	if existing != null:
		existing.remaining_turns = maxi(existing.remaining_turns, duration_turns)
		existing.source_combatant_id = source_id
		existing.magnitude = maxf(existing.magnitude, magnitude)
		existing.guaranteed_crit_against = existing.guaranteed_crit_against or guaranteed_crit
	else:
		statuses.append(StatusEffectInstance.new(status_type, duration_turns, source_id, magnitude, guaranteed_crit))
	
	if status_type == BattleTypes.StatusType.SLEEP or status_type == BattleTypes.StatusType.HYPNOSIS or status_type == BattleTypes.StatusType.CALM:
		resources.decay_rage_on_control_status()
	if status_type == BattleTypes.StatusType.STAGGER:
		clear_block_stance()
		clear_telegraph()
	
	status_applied.emit(status_type)

func remove_status(status_type: BattleTypes.StatusType) -> void:
	for i: int in range(statuses.size() - 1, -1, -1):
		if statuses[i].status_type == status_type:
			statuses.remove_at(i)
			status_removed.emit(status_type)

func has_status(status_type: BattleTypes.StatusType) -> bool:
	return get_status(status_type) != null

func get_status(status_type: BattleTypes.StatusType) -> StatusEffectInstance:
	for st: StatusEffectInstance in statuses:
		if st.status_type == status_type:
			return st
	return null

## Снимает статусы (например, HYPNOSIS), наложенные указанным источником после его гибели
func clear_statuses_from_source(source_id: String) -> void:
	if source_id.is_empty():
		return
	for i: int in range(statuses.size() - 1, -1, -1):
		if statuses[i].source_combatant_id == source_id:
			var removed_type: BattleTypes.StatusType = statuses[i].status_type
			statuses.remove_at(i)
			status_removed.emit(removed_type)

## Обновляет длительности всех статусов в конце хода и возвращает список истекших
func tick_statuses() -> Array[BattleTypes.StatusType]:
	var expired: Array[BattleTypes.StatusType] = []
	for i: int in range(statuses.size() - 1, -1, -1):
		var st: StatusEffectInstance = statuses[i]
		if st.tick_turn():
			statuses.remove_at(i)
			expired.append(st.status_type)
			status_removed.emit(st.status_type)
	return expired

func is_staggered() -> bool:
	return has_status(BattleTypes.StatusType.STAGGER)

func is_incapacitated() -> bool:
	return has_status(BattleTypes.StatusType.SLEEP) or has_status(BattleTypes.StatusType.STAGGER)

func is_hypnotized() -> bool:
	return has_status(BattleTypes.StatusType.HYPNOSIS)

func get_taunt_source_id() -> String:
	var taunt_st: StatusEffectInstance = get_status(BattleTypes.StatusType.TAUNT)
	return taunt_st.source_combatant_id if taunt_st != null else ""

func get_no_guard_status() -> StatusEffectInstance:
	return get_status(BattleTypes.StatusType.NO_GUARD)

## Возвращает доступные для атаки части тела многосоставного врага
func get_targetable_parts() -> Array[EnemyPartState]:
	var result: Array[EnemyPartState] = []
	var staggered: bool = is_staggered()
	var telegraphing: bool = is_telegraphing()
	for part: EnemyPartState in parts:
		if part.is_targetable(staggered, telegraphing):
			result.append(part)
	return result

func get_part_by_id(part_id: String) -> EnemyPartState:
	for part: EnemyPartState in parts:
		if part.data != null and part.data.part_id == part_id:
			return part
	return null

## Применяет урон к бойцу и выбранной части тела, возвращая итоговый результат
func take_damage(raw_amount: int, target_part: EnemyPartState = null) -> Dictionary:
	var actual_hp_damage: int = maxi(0, raw_amount)
	var part_broke_now: bool = false
	var triggered_stagger: bool = false
	var broken_part_id: String = ""
	
	if target_part != null and target_part.data != null:
		var part_dmg: int = actual_hp_damage
		actual_hp_damage = maxi(0, roundi(float(actual_hp_damage) * target_part.data.shared_hp_transfer_ratio))
		if target_part.apply_part_damage(part_dmg):
			part_broke_now = true
			broken_part_id = target_part.data.part_id
			part_broken.emit(broken_part_id)
			if target_part.data.triggers_stagger_on_break:
				triggered_stagger = true
				apply_status(
					BattleTypes.StatusType.STAGGER,
					target_part.data.stagger_duration_turns,
					runtime_id
				)
	
	var prev_hp: int = current_hp
	current_hp = maxi(0, current_hp - actual_hp_damage)
	var applied_damage: int = prev_hp - current_hp
	
	if applied_damage > 0:
		resources.add_rage_on_damage_taken()
		hp_changed.emit(current_hp, max_hp)
		if has_status(BattleTypes.StatusType.SLEEP):
			remove_status(BattleTypes.StatusType.SLEEP)
	
	if prev_hp > 0 and current_hp == 0:
		died.emit(self)
	
	return {
		"damage_taken": applied_damage,
		"part_broken": part_broke_now,
		"broken_part_id": broken_part_id,
		"triggered_stagger": triggered_stagger
	}

## Восстанавливает здоровье (при внешнем лечении дополнительно снижает Ярость)
func heal_hp(amount: int, is_external: bool = true) -> int:
	if amount <= 0 or not is_alive():
		return 0
	var prev_hp: int = current_hp
	current_hp = mini(max_hp, current_hp + amount)
	var healed: int = current_hp - prev_hp
	if healed > 0:
		hp_changed.emit(current_hp, max_hp)
	if is_external:
		resources.decay_rage_on_external_heal()
	return healed

## Продвигает шкалу Завета / Примирения (совместимость с Dual Victory Condition)
func add_resolve(amount: int) -> int:
	if amount <= 0:
		return 0
	var prev_val: int = current_resolve
	current_resolve = mini(max_resolve, current_resolve + amount)
	var gained: int = current_resolve - prev_val
	if gained > 0:
		resolve_changed.emit(current_resolve, max_resolve)
	return gained

func is_pacified() -> bool:
	return not is_player_controlled and current_resolve >= max_resolve

## Делегирует восполнение ресурса в ResourcePool
func restore_resource(res_type: BattleTypes.ResourceType, amount: int) -> int:
	return resources.restore_resource(res_type, amount)

## Возвращает модификатор уязвимости/сопротивления от исходных данных врага
func get_damage_type_multiplier(damage_type: BattleTypes.DamageType) -> float:
	if source_enemy_data != null:
		return source_enemy_data.get_damage_type_modifier(damage_type)
	return 1.0

func _get_equipment_hp_bonus() -> int:
	var total: int = 0
	for eq: EquipmentModifierStub in equipment_modifiers:
		if eq != null:
			total += eq.bonus_max_hp
	return total
