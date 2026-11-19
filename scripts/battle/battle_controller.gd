# res://scripts/battle/battle_controller.gd
class_name BattleController
extends Node

## Главные сигналы контроллера боя (строго снизу вверх)
signal battle_finished(victory: bool, by_vow: bool)
signal log_message_emitted(text: String)
signal qte_requested(config: QTEConfigData, is_defensive: bool)

@export var ui_presenter: BattleUIPresenter = null
@export var auto_start_sandbox: bool = true
@export var return_to_overworld_on_finish: bool = false
@export_range(0.0, 1.0, 0.05) var qte_stub_fallback_accuracy: float = 0.75

var context: BattleContext = BattleContext.new()

var _states: Dictionary = {}
var _current_state: BaseBattleState = null
var _states_container: Node = null

func _ready() -> void:
	if ui_presenter == null:
		ui_presenter = get_node_or_null("BattleUIPresenter") as BattleUIPresenter
	context.ui = ui_presenter
	_register_states()
	
	if auto_start_sandbox:
		start_sandbox_battle()

## Запускает тестовый бой с ГГ и Молодым драконом из BattleSandboxFactory
func start_sandbox_battle() -> void:
	var players: Array[Combatant] = BattleSandboxFactory.create_sandbox_player_party()
	var enemies: Array[Combatant] = BattleSandboxFactory.create_sandbox_enemy_party()
	start_battle(players, enemies)

## Запускает бой с переданными отрядами игрока (до 4 бойцов) и противников
func start_battle(players: Array[Combatant], enemies: Array[Combatant]) -> void:
	context.ui = ui_presenter
	context.setup_parties(players, enemies)
	_bind_combatant_signals()
	_change_state(&"battle_start")

## Хук для кнопки ITEM: пока возвращает заглушку при пустом инвентаре
func execute_item_action(actor: Combatant, slot: ItemSlotStub = null) -> String:
	if slot == null or slot.is_empty():
		var empty_msg: String = "Инвентарь пока пуст"
		_emit_log(empty_msg)
		return empty_msg
	
	var parts: PackedStringArray = PackedStringArray()
	parts.append("%s использует «%s»." % [actor.display_name if actor != null else "Боец", slot.item_name])
	if actor != null:
		if slot.heal_hp > 0:
			var healed: int = actor.heal_hp(slot.heal_hp, true)
			parts.append("Восстановлено %d HP." % healed)
		if slot.restore_resource_amount > 0:
			var restored: int = actor.restore_resource(slot.restore_resource_type, slot.restore_resource_amount)
			parts.append("Восстановлено %d %s." % [restored, BattleTypes.get_resource_display_name(slot.restore_resource_type)])
	
	var used_msg: String = " ".join(parts)
	_emit_log(used_msg)
	return used_msg

## Запрос запуска QTE (если внешний QTE-презентер Фазы 3 еще не подключен, использует безопасную заглушку)
func request_qte(config: QTEConfigData, is_defensive: bool) -> void:
	if qte_requested.get_connections().size() > 0:
		qte_requested.emit(config, is_defensive)
		return
	call_deferred("complete_qte", qte_stub_fallback_accuracy, "ЗАГЛУШКА QTE")

## Передает результат завершенной мини-игры QTE активному состоянию FSM
func complete_qte(accuracy: float, success_tier: String) -> void:
	if _current_state != null:
		_current_state.on_qte_completed(accuracy, success_tier)

func get_current_state_id() -> StringName:
	return _current_state.get_state_id() if _current_state != null else &""

func _register_states() -> void:
	_states_container = Node.new()
	_states_container.name = "States"
	add_child(_states_container)
	
	var state_instances: Array[BaseBattleState] = [
		BattleStartState.new(),
		PlayerSelectState.new(),
		PlayerActionState.new(),
		EnemyTurnState.new(),
		DefenseQTEState.new(),
		TurnResolutionState.new(),
		BattleEndState.new()
	]
	
	for st: BaseBattleState in state_instances:
		st.name = String(st.get_state_id())
		st.setup(context)
		st.transition_requested.connect(_on_state_transition_requested)
		st.log_requested.connect(_on_state_log_requested)
		st.qte_requested.connect(_on_state_qte_requested)
		st.item_action_requested.connect(_on_state_item_action_requested)
		st.battle_end_requested.connect(_on_state_battle_end_requested)
		_states_container.add_child(st)
		_states[st.get_state_id()] = st

func _change_state(next_state_id: StringName) -> void:
	if not _states.has(next_state_id):
		push_error("BattleController: неизвестное состояние FSM: " + String(next_state_id))
		return
	
	if _current_state != null:
		_current_state.exit()
	
	_current_state = _states[next_state_id] as BaseBattleState
	_current_state.enter()

func _bind_combatant_signals() -> void:
	var all_combatants: Array[Combatant] = []
	all_combatants.append_array(context.player_party)
	all_combatants.append_array(context.enemy_party)
	for c: Combatant in all_combatants:
		if c != null and not c.died.is_connected(_on_combatant_died):
			c.died.connect(_on_combatant_died)

func _on_combatant_died(dead_combatant: Combatant) -> void:
	if dead_combatant == null:
		return
	for c: Combatant in context.get_all_alive_combatants():
		c.clear_statuses_from_source(dead_combatant.runtime_id)

func _on_state_transition_requested(next_state_id: StringName) -> void:
	_bind_combatant_signals()
	_change_state(next_state_id)

func _on_state_log_requested(message: String) -> void:
	_emit_log(message)

func _on_state_qte_requested(config: QTEConfigData, is_defensive: bool) -> void:
	request_qte(config, is_defensive)

func _on_state_item_action_requested(actor: Combatant, slot: ItemSlotStub) -> void:
	execute_item_action(actor, slot)

func _on_state_battle_end_requested(victory: bool, by_vow: bool) -> void:
	battle_finished.emit(victory, by_vow)
	if return_to_overworld_on_finish and GameManager != null:
		GameManager.return_to_overworld(victory, by_vow)

func _emit_log(message: String) -> void:
	if ui_presenter != null:
		ui_presenter.set_log_text(message)
	log_message_emitted.emit(message)
