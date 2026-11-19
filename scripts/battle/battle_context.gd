# res://scripts/battle/battle_context.gd
class_name BattleContext
extends RefCounted

## Максимальный размер отряда игрока (для расширения до 4 бойцов)
const MAX_PLAYER_PARTY_SIZE: int = 4

var player_party: Array[Combatant] = []
var enemy_party: Array[Combatant] = []
var ui: BattleUIPresenter = null

var turn_number: int = 1
var active_player_index: int = 0
var active_enemy_index: int = 0

## Буфер выбранного действия текущего игрока
var pending_action_type: BattleTypes.ActionType = BattleTypes.ActionType.ATTACK
var pending_skill: SkillData = null
var pending_target: Combatant = null
var pending_target_part: EnemyPartState = null
var pending_tension_tier: BattleTypes.TensionTier = BattleTypes.TensionTier.LOCKED

## Буфер текущего действия противника перед/во время защитного QTE
var enemy_pending_actor: Combatant = null
var enemy_pending_skill: SkillData = null
var enemy_pending_target: Combatant = null

## Итоги боя
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

func reset_player_turn_cursor() -> bool:
	active_player_index = -1
	return advance_to_next_alive_player()

func advance_to_next_alive_player() -> bool:
	active_player_index += 1
	while active_player_index < player_party.size():
		var c: Combatant = player_party[active_player_index]
		if c != null and c.is_alive():
			return true
		active_player_index += 1
	return false

func reset_enemy_turn_cursor() -> bool:
	active_enemy_index = -1
	return advance_to_next_alive_enemy()

func advance_to_next_alive_enemy() -> bool:
	active_enemy_index += 1
	while active_enemy_index < enemy_party.size():
		var c: Combatant = enemy_party[active_enemy_index]
		if c != null and c.is_alive():
			return true
		active_enemy_index += 1
	return false

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

func is_player_party_defeated() -> bool:
	return get_alive_players().is_empty()

func is_enemy_party_defeated() -> bool:
	return get_alive_enemies().is_empty()

func is_enemy_party_pacified() -> bool:
	var alive_enemies: Array[Combatant] = get_alive_enemies()
	if alive_enemies.is_empty():
		return false
	for enemy: Combatant in alive_enemies:
		if not enemy.is_pacified():
			return false
	return true

func clear_pending_player_action() -> void:
	pending_action_type = BattleTypes.ActionType.ATTACK
	pending_skill = null
	pending_target = null
	pending_target_part = null
	pending_tension_tier = BattleTypes.TensionTier.LOCKED

func clear_pending_enemy_action() -> void:
	enemy_pending_actor = null
	enemy_pending_skill = null
	enemy_pending_target = null
