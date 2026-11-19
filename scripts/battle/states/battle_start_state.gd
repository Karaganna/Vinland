# res://scripts/battle/states/battle_start_state.gd
class_name BattleStartState
extends BaseBattleState

## Инициализация массивов отрядов и стартового состояния интерфейса
func get_state_id() -> StringName:
	return &"battle_start"

func enter() -> void:
	if _context == null:
		return
	
	if _context.player_party.is_empty():
		_context.setup_parties(
			BattleSandboxFactory.create_sandbox_player_party(),
			_context.enemy_party
		)
	if _context.enemy_party.is_empty():
		_context.setup_parties(
			_context.player_party,
			BattleSandboxFactory.create_sandbox_enemy_party()
		)
	
	_context.turn_number = 1
	_context.clear_pending_player_action()
	_context.clear_pending_enemy_action()
	_context.reset_player_turn_cursor()
	_context.reset_enemy_turn_cursor()
	
	if _context.ui != null:
		_context.ui.hide_sub_menu()
		_context.ui.clear_telegraph_banner()
		_context.ui.set_action_menu_visible(false)
	
	_refresh_ui()
	
	var enemy_names: PackedStringArray = PackedStringArray()
	for enemy: Combatant in _context.get_alive_enemies():
		enemy_names.append(enemy.display_name)
	var intro_msg: String = "Бой начался! Противник: %s." % ", ".join(enemy_names)
	log_requested.emit(intro_msg)
	
	transition_requested.emit(&"player_select")
