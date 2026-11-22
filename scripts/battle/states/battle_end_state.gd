# res://scripts/battle/states/battle_end_state.gd
class_name BattleEndState
extends BaseBattleState

## Фиксация результата боя, подтверждение выхода и передача снимка отряда в GameManager
var _is_finalizing: bool = false
var _is_listening_end_ui: bool = false

func get_state_id() -> StringName:
	return &"battle_end"

func enter() -> void:
	if _context == null:
		return
	
	_is_finalizing = false
	
	if _context.ui != null:
		_context.ui.hide_sub_menu()
		_context.ui.clear_telegraph_banner()
		_context.ui.set_action_menu_visible(false)
	
	_refresh_ui()
	
	var msg: String = _context.outcome_message
	if msg.is_empty():
		msg = "Победа!" if _context.battle_victory else "Поражение!"
	
	_emit_log(msg)
	
	var can_return_to_world: bool = (
		_context.is_overworld_battle
		and GameManager != null
		and (not GameManager.return_scene_path.is_empty() or not GameManager.saved_return_scene_path.is_empty())
	)
	
	if _context.ui != null:
		_connect_end_ui()
		_context.ui.show_battle_end_options(can_return_to_world)
	else:
		await get_tree().create_timer(1.5).timeout
		if _context == null:
			return
		var auto_action: String = "return_to_world" if can_return_to_world else "restart_sandbox"
		_finalize_battle_end(auto_action)

func exit() -> void:
	_disconnect_end_ui()
	_is_finalizing = false
	if _context != null and _context.ui != null:
		_context.ui.hide_sub_menu()

func _connect_end_ui() -> void:
	if _context == null or _context.ui == null or _is_listening_end_ui:
		return
	if not _context.ui.battle_end_action_selected.is_connected(_on_battle_end_action_selected):
		_context.ui.battle_end_action_selected.connect(_on_battle_end_action_selected)
	_is_listening_end_ui = true

func _disconnect_end_ui() -> void:
	if _context == null or _context.ui == null or not _is_listening_end_ui:
		return
	if _context.ui.battle_end_action_selected.is_connected(_on_battle_end_action_selected):
		_context.ui.battle_end_action_selected.disconnect(_on_battle_end_action_selected)
	_is_listening_end_ui = false

func _on_battle_end_action_selected(action_id: String) -> void:
	_finalize_battle_end(action_id)

func _finalize_battle_end(action_id: String) -> void:
	if _is_finalizing or _context == null:
		return
	_is_finalizing = true
	_disconnect_end_ui()
	if _context.ui != null:
		_context.ui.hide_sub_menu()
	
	_emit_battle_end(_context.battle_victory, _context.battle_by_vow)
	
	if action_id == "return_to_world" and _context.is_overworld_battle and GameManager != null:
		var party_snapshot: Array[Dictionary] = _collect_party_snapshot()
		var outcome: String = _resolve_outcome_string()
		GameManager.finish_battle(outcome, party_snapshot)
		return
	
	# Автономный режим песочницы (F6): перезапуск боя без обращения к сценам оверворлда
	if action_id == "restart_sandbox":
		_context.player_party.clear()
		_context.enemy_party.clear()
		_context.is_overworld_battle = false
		_emit_transition(&"battle_start")

func _collect_party_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	if _context == null:
		return snapshot
	for member: Combatant in _context.player_party:
		if member != null:
			snapshot.append(member.create_persistent_snapshot())
	return snapshot

func _resolve_outcome_string() -> String:
	if _context == null:
		return "defeat"
	if _context.battle_victory:
		return "vow" if _context.battle_by_vow else "victory"
	return "defeat"
