# res://scripts/battle/states/base_battle_state.gd
class_name BaseBattleState
extends Node

## Сигналы состояний FSM боя (строго снизу вверх, без зависимости от BattleController)
signal transition_requested(next_state_id: StringName)
signal log_requested(message: String)
signal qte_requested(config: QTEConfigData, is_defensive: bool)
signal item_action_requested(actor: Combatant, slot: ItemSlotStub)
signal battle_end_requested(victory: bool, by_vow: bool)

var _context: BattleContext = null

func setup(p_context: BattleContext) -> void:
	_context = p_context

func get_state_id() -> StringName:
	return &""

func enter() -> void:
	pass

func exit() -> void:
	pass

func on_qte_completed(_accuracy: float, _success_tier: String) -> void:
	pass

func _refresh_ui() -> void:
	if _context != null and _context.ui != null:
		_context.ui.refresh_combatants(
			_context.player_party,
			_context.enemy_party,
			_context.get_active_player()
		)
