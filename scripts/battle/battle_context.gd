# res://scripts/battle/battle_context.gd
class_name BattleContext
extends RefCounted

## Максимальный размер отряда игрока (до 4 бойцов)
const MAX_PLAYER_PARTY_SIZE: int = 4

var player_party: Array[Combatant] = []
var enemy_party: Array[Combatant] = []
var ui: BattleUIPresenter = null

var turn_number: int = 1
var active_player_index: int = 0
var active_enemy_index: int = 0

var _player_turn_order: Array[int] = []
var _player_order_pos: int = -1
var _enemy_turn_order: Array[int] = []
var _enemy_order_pos: int = -1

## Буфер выбранного действия текущего игрока
var pending_action_type: BattleTypes.ActionType = BattleTypes.ActionType.ATTACK
var pending_skill: SkillData = null
var pending_consumable: ConsumableItemData = null
var pending_target: Combatant = null
var pending_target_part: EnemyPartState = null
var pending_tension_tier: BattleTypes.TensionTier = BattleTypes.TensionTier.LOCKED
## Метаданные последней завершенной QTE-проверки (например, точное число попаданий в SERIES_CHAIN)
var last_qte_metadata: Dictionary = {}

## Буфер текущего действия противника перед/во время защитного QTE
var enemy_pending_actor: Combatant = null
var enemy_pending_skill: SkillData = null
var enemy_pending_target: Combatant = null

## Итоги боя и режим запуска (оверворлд или автономная песочница F6)
var is_overworld_battle: bool = false
var battle_victory: bool = false
var battle_by_vow: bool = false
var outcome_message: String = ""

## Инициализирует отряды игрока и противников (отряд игрока ограничивается до 4 бойцов)
func setup_parties(players: Array[Combatant], enemies: Array[Combatant]) -> void:
	player_party.clear()
	enemy_party.clear()
	
	var player_limit: int = mini(players.size(), MAX_PLAYER_PARTY_SIZE)
	for i: int in range(player_limit):
		if players[i] != null:
			player_party.append(players[i])
	
	for enemy: Combatant in enemies:
		if enemy != null:
			enemy_party.append(enemy)

func get_alive_players() -> Array[Combatant]:
	var list: Array[Combatant] = []
	for c: Combatant in player_party:
		if c != null and c.is_alive():
			list.append(c)
	return list

func get_fallen_players() -> Array[Combatant]:
	var list: Array[Combatant] = []
	for c: Combatant in player_party:
		if c != null and not c.is_alive():
			list.append(c)
	return list

func get_alive_enemies() -> Array[Combatant]:
	var list: Array[Combatant] = []
	for c: Combatant in enemy_party:
		if c != null and c.is_alive():
			list.append(c)
	return list

func get_all_alive_combatants() -> Array[Combatant]:
	var list: Array[Combatant] = []
	for c: Combatant in player_party:
		if c != null and c.is_alive():
			list.append(c)
	for c: Combatant in enemy_party:
		if c != null and c.is_alive():
			list.append(c)
	return list

func get_active_player() -> Combatant:
	if active_player_index >= 0 and active_player_index < player_party.size():
		var c: Combatant = player_party[active_player_index]
		if c != null and c.is_alive():
			return c
	return null

func get_active_enemy() -> Combatant:
	if active_enemy_index >= 0 and active_enemy_index < enemy_party.size():
		var c: Combatant = enemy_party[active_enemy_index]
		if c != null and c.is_alive():
			return c
	return null

## Строит очередь хода отряда игрока с учетом эффективной скорости (SLOW) и статуса ACT_LAST
func reset_player_turn_cursor() -> bool:
	_player_turn_order = _build_turn_order(player_party)
	_player_order_pos = -1
	active_player_index = -1
	return advance_to_next_alive_player()

func advance_to_next_alive_player() -> bool:
	_player_order_pos += 1
	while _player_order_pos < _player_turn_order.size():
		var party_idx: int = _player_turn_order[_player_order_pos]
		if party_idx >= 0 and party_idx < player_party.size():
			var c: Combatant = player_party[party_idx]
			if c != null and c.is_alive():
				active_player_index = party_idx
				return true
		_player_order_pos += 1
	active_player_index = player_party.size()
	return false

## Строит очередь хода врагов с учетом эффективной скорости (SLOW) и статуса ACT_LAST
func reset_enemy_turn_cursor() -> bool:
	_enemy_turn_order = _build_turn_order(enemy_party)
	_enemy_order_pos = -1
	active_enemy_index = -1
	return advance_to_next_alive_enemy()

func advance_to_next_alive_enemy() -> bool:
	_enemy_order_pos += 1
	while _enemy_order_pos < _enemy_turn_order.size():
		var party_idx: int = _enemy_turn_order[_enemy_order_pos]
		if party_idx >= 0 and party_idx < enemy_party.size():
			var c: Combatant = enemy_party[party_idx]
			if c != null and c.is_alive():
				active_enemy_index = party_idx
				return true
		_enemy_order_pos += 1
	active_enemy_index = enemy_party.size()
	return false

func _build_turn_order(group: Array[Combatant]) -> Array[int]:
	var normal_indices: Array[int] = []
	var last_indices: Array[int] = []
	for i: int in range(group.size()):
		var c: Combatant = group[i]
		if c == null or not c.is_alive():
			continue
		if c.acts_last():
			last_indices.append(i)
		else:
			normal_indices.append(i)
	
	normal_indices.sort_custom(func(a: int, b: int) -> bool:
		var spd_a: int = group[a].get_effective_speed()
		var spd_b: int = group[b].get_effective_speed()
		if spd_a == spd_b:
			return a < b
		return spd_a > spd_b
	)
	
	var combined: Array[int] = []
	combined.append_array(normal_indices)
	combined.append_array(last_indices)
	return combined

func find_alive_combatant_by_id(p_runtime_id: String) -> Combatant:
	if p_runtime_id.is_empty():
		return null
	for c: Combatant in get_all_alive_combatants():
		if c.runtime_id == p_runtime_id:
			return c
	return null

func get_taunting_player() -> Combatant:
	for p: Combatant in get_alive_players():
		if p.has_status(BattleTypes.StatusType.TAUNT):
			return p
	return null

## Находит дееспособного союзника в стойке «Начеку» (COVER_ALLY), прикрывающего указанную цель
func find_cover_protector_for(target: Combatant) -> Combatant:
	if target == null or not target.is_player_controlled:
		return null
	for ally: Combatant in get_alive_players():
		if ally == target or ally.is_incapacitated():
			continue
		var cover_st: StatusEffectInstance = ally.get_status(BattleTypes.StatusType.COVER_ALLY)
		if cover_st != null:
			if cover_st.protected_ally_id.is_empty() or cover_st.protected_ally_id == target.runtime_id:
				return ally
	return null

func is_player_party_defeated() -> bool:
	return get_alive_players().is_empty()

func is_enemy_party_defeated() -> bool:
	return get_alive_enemies().is_empty()

## Legacy-заглушка Завета: победа через примирение отключена в актуальном боевом цикле
func is_enemy_party_pacified() -> bool:
	return false

func clear_pending_player_action() -> void:
	pending_action_type = BattleTypes.ActionType.ATTACK
	pending_skill = null
	pending_consumable = null
	pending_target = null
	pending_target_part = null
	pending_tension_tier = BattleTypes.TensionTier.LOCKED
	last_qte_metadata.clear()

func clear_pending_enemy_action() -> void:
	enemy_pending_actor = null
	enemy_pending_skill = null
	enemy_pending_target = null
