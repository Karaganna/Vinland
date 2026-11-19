# res://scripts/battle/states/battle_end_state.gd
class_name BattleEndState
extends BaseBattleState

## Фиксация результата боя и отправка сигнала завершения вверх
func get_state_id() -> StringName:
	return &"battle_end"

func enter() -> void:
	if _context == null:
		return
	
	if _context.ui != null:
		_context.ui.hide_sub_menu()
		_context.ui.clear_telegraph_banner()
		_context.ui.set_action_menu_visible(false)
	
	var msg: String = _context.outcome_message
	if msg.is_empty():
		msg = "Победа!" if _context.battle_victory else "Поражение!"
	
	log_requested.emit(msg)
	battle_end_requested.emit(_context.battle_victory, _context.battle_by_vow)
