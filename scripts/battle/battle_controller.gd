# res://scripts/battle/battle_controller.gd
class_name BattleController
extends Node

## Главные сигналы контроллера боя (строго снизу вверх)
signal battle_finished(victory: bool, by_vow: bool)
signal log_message_emitted(text: String)
signal qte_requested(config: QTEConfigData, is_defensive: bool)

@export var ui_presenter: BattleUIPresenter = null
@export var rhythm_sync_audio_player: AudioStreamPlayer = null
@export var auto_start_sandbox: bool = true
@export var return_to_overworld_on_finish: bool = false
## Автоматическое прохождение QTE для рядовых боев (задел на будущее + синхронизация с GameManager)
@export var auto_qte_enabled: bool = false

var context: BattleContext = BattleContext.new()

var _states: Dictionary = {}
var _current_state: BaseBattleState = null
var _states_container: Node = null
var _active_qte: BaseQTEMinigame = null

func _ready() -> void:
	_ensure_ui_presenter()
	context.ui = ui_presenter
	_register_states()
	
	var has_pending: bool = GameManager != null and GameManager.has_pending_battle()
	if has_pending or auto_start_sandbox:
		_change_state(&"battle_start")

func _ensure_ui_presenter() -> void:
	if ui_presenter != null:
		return
	ui_presenter = get_node_or_null("BattleUIPresenter") as BattleUIPresenter
	if ui_presenter == null:
		for child: Node in get_children():
			if child is BattleUIPresenter:
				ui_presenter = child as BattleUIPresenter
				break
			var nested: BattleUIPresenter = child.get_node_or_null("BattleUIPresenter") as BattleUIPresenter
			if nested != null:
				ui_presenter = nested
				break
	var has_pending: bool = GameManager != null and GameManager.has_pending_battle()
	if ui_presenter == null and (auto_start_sandbox or has_pending):
		var layer: CanvasLayer = CanvasLayer.new()
		layer.name = "BattleUILayer"
		add_child(layer)
		ui_presenter = BattleUIPresenter.new()
		ui_presenter.name = "BattleUIPresenter"
		layer.add_child(ui_presenter)

## Запускает тестовый бой с ГГ и Молодым драконом из BattleSandboxFactory
func start_sandbox_battle() -> void:
	context.is_overworld_battle = false
	var players: Array[Combatant] = BattleSandboxFactory.create_sandbox_player_party()
	var enemies: Array[Combatant] = BattleSandboxFactory.create_sandbox_enemy_party()
	start_battle(players, enemies)

## Запускает бой с переданными отрядами игрока (до 4 бойцов) и противников
func start_battle(players: Array[Combatant], enemies: Array[Combatant]) -> void:
	context.ui = ui_presenter
	context.setup_parties(players, enemies)
	_bind_combatant_signals()
	_change_state(&"battle_start")

## Применяет слот расходника (совместимый хук)
func execute_item_action(actor: Combatant, slot: ItemSlotStub = null) -> String:
	if slot == null or slot.is_empty():
		var empty_msg: String = "Не выбран расходник"
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

## Применяет полноценный ресурс расходника ConsumableItemData с логированием
func execute_consumable_action(actor: Combatant, item: ConsumableItemData) -> String:
	if actor == null or item == null:
		return ""
	var parts: PackedStringArray = PackedStringArray()
	parts.append("%s использует «%s»." % [actor.display_name, item.display_name])
	if item.heal_hp > 0:
		var healed: int = actor.heal_hp(item.heal_hp, true)
		parts.append("+%d HP." % healed)
	if item.restore_resource_amount > 0:
		var restored: int = actor.restore_resource(item.restore_resource_type, item.restore_resource_amount)
		parts.append("+%d %s." % [restored, BattleTypes.get_resource_display_name(item.restore_resource_type)])
	var cured_names: PackedStringArray = PackedStringArray()
	for st: BattleTypes.StatusType in item.cure_statuses:
		if actor.has_status(st):
			actor.remove_status(st)
			cured_names.append(BattleTypes.get_status_display_name(st))
	if not cured_names.is_empty():
		parts.append("Сняты статусы: %s." % ", ".join(cured_names))
	
	var msg: String = " ".join(parts)
	_emit_log(msg)
	return msg

## Запускает соответствующую мини-игру QTE внутри qte_slot_container нижней панели
func request_qte(config: QTEConfigData, is_defensive: bool) -> void:
	context.last_qte_metadata.clear()
	qte_requested.emit(config, is_defensive)
	
	if _active_qte != null and is_instance_valid(_active_qte):
		_active_qte.queue_free()
		_active_qte = null
	
	if config == null or config.qte_type == BattleTypes.QTEType.NONE:
		complete_qte(1.0, "НОРМАЛЬНО")
		return
	
	var use_auto_qte: bool = auto_qte_enabled or (GameManager != null and GameManager.auto_qte_enabled)
	if use_auto_qte:
		if config.qte_type == BattleTypes.QTEType.SERIES_CHAIN:
			context.last_qte_metadata = {
				"is_series": true,
				"series_hits": maxi(1, config.series_max_steps - 1),
				"series_max": config.series_max_steps
			}
		complete_qte(0.78, "НОРМАЛЬНО")
		return
	
	var minigame: BaseQTEMinigame = _create_qte_minigame(config.qte_type)
	if minigame == null:
		complete_qte(1.0, "НОРМАЛЬНО")
		return
	
	_active_qte = minigame
	if rhythm_sync_audio_player != null:
		_active_qte.set_audio_sync_player(rhythm_sync_audio_player)
	
	var container: Control = ui_presenter.get_qte_container() if ui_presenter != null else null
	if container != null:
		ui_presenter.set_qte_active(true)
		container.add_child(_active_qte)
	else:
		add_child(_active_qte)
	
	_active_qte.qte_metadata_reported.connect(_on_qte_metadata_reported)
	_active_qte.qte_finished.connect(_on_qte_minigame_finished)
	_active_qte.start_qte(config)

func _create_qte_minigame(qte_type: BattleTypes.QTEType) -> BaseQTEMinigame:
	match qte_type:
		BattleTypes.QTEType.PRECISION_BAR:
			return PrecisionBarQTE.new()
		BattleTypes.QTEType.CIRCULAR_SKILL_CHECK:
			return CircularSkillCheckQTE.new()
		BattleTypes.QTEType.RHYTHM_TRACK:
			return RhythmTrackQTE.new()
		BattleTypes.QTEType.HOLD_RELEASE:
			return HoldReleaseQTE.new()
		BattleTypes.QTEType.SERIES_CHAIN:
			return SeriesChainQTE.new()
		BattleTypes.QTEType.RUNE_SEQUENCE:
			return RuneSequenceQTE.new()
		BattleTypes.QTEType.RUSH_MASH:
			return RushMashQTE.new()
		BattleTypes.QTEType.DICE_ROLL:
			return DiceRollQTE.new()
	return null

func _on_qte_metadata_reported(metadata: Dictionary) -> void:
	context.last_qte_metadata = metadata.duplicate()

func _on_qte_minigame_finished(accuracy: float, success_tier: String) -> void:
	_active_qte = null
	if ui_presenter != null:
		ui_presenter.set_qte_active(false)
	complete_qte(accuracy, success_tier)

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
	if return_to_overworld_on_finish and not context.is_overworld_battle and GameManager != null:
		GameManager.return_to_overworld(victory, by_vow)

func _emit_log(message: String) -> void:
	if ui_presenter != null:
		ui_presenter.set_log_text(message)
	log_message_emitted.emit(message)
