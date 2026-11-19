# res://scripts/battle/states/turn_resolution_state.gd
class_name TurnResolutionState
extends BaseBattleState

## Конец раунда: тики статусов, спад/сброс временных эффектов, рост Напряжения, проверка конца боя
func get_state_id() -> StringName:
	return &"turn_resolution"

func enter() -> void:
	if _context == null:
		return
	
	for c: Combatant in _context.get_all_alive_combatants():
		c.tick_statuses()
		c.clear_block_stance()
	
	for hero: Combatant in _context.get_alive_players():
		hero.restore_resource(BattleTypes.ResourceType.TENSION, 10)
	
	_context.turn_number += 1
	_refresh_ui()
	
	if _context.is_enemy_party_defeated():
		_context.battle_victory = true
		_context.battle_by_vow = false
		_context.outcome_message = "Победа в бою!"
		transition_requested.emit(&"battle_end")
		return
	
	if _context.is_enemy_party_pacified():
		_context.battle_victory = true
		_context.battle_by_vow = true
		_context.outcome_message = "Бой завершен примирением (Завет)!"
		transition_requested.emit(&"battle_end")
		return
	
	if _context.is_player_party_defeated():
		_context.battle_victory = false
		_context.battle_by_vow = false
		_context.outcome_message = "Поражение..."
		transition_requested.emit(&"battle_end")
		return
	
	_context.reset_player_turn_cursor()
	transition_requested.emit(&"player_select")
