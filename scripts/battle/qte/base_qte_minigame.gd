# res://scripts/battle/qte/base_qte_minigame.gd
class_name BaseQTEMinigame
extends Control

## Единый сигнал завершения QTE мини-игры
signal qte_finished(accuracy: float, success_tier: String)

var _config: QTEConfigData = null
var _is_running: bool = false
var _start_usec: int = 0
var _audio_player: AudioStreamPlayer = null
var _audio_start_offset_sec: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Привязывает AudioStreamPlayer для точной музыкальной синхронизации ритм-QTE
func set_audio_sync_player(player: AudioStreamPlayer) -> void:
	_audio_player = player

## Единый контракт запуска мини-игры QTE
func start_qte(config: QTEConfigData) -> void:
	_config = config if config != null else QTEConfigData.new()
	_release_ui_focus()
	_begin_clock()
	_is_running = true
	_on_qte_started()
	queue_redraw()

## Переопределяется в наследниках для инициализации визуала и данных QTE
func _on_qte_started() -> void:
	pass

## Вызывается при завершении QTE для показа краткой визуальной реакции
func _on_qte_judged(_accuracy: float, _tier_label: String) -> void:
	pass

func _begin_clock() -> void:
	_start_usec = Time.get_ticks_usec()
	if _audio_player != null and is_instance_valid(_audio_player) and _audio_player.playing:
		_audio_start_offset_sec = _audio_player.get_playback_position()
	else:
		_audio_start_offset_sec = 0.0

## Точное синхронизированное время без накопления ошибки кадра _process(delta)
func _get_synced_elapsed_seconds() -> float:
	if _audio_player != null and is_instance_valid(_audio_player) and _audio_player.playing:
		var audio_sec: float = (
			_audio_player.get_playback_position()
			+ AudioServer.get_time_since_last_mix()
			- AudioServer.get_output_latency()
			- _audio_start_offset_sec
		)
		return maxf(0.0, audio_sec)
	return maxf(0.0, float(Time.get_ticks_usec() - _start_usec) / 1000000.0)

## Проверяет нажатие подтверждающего действия строго через InputMap (без хардкода KEY_*)
func _is_hit_action_pressed(event: InputEvent) -> bool:
	if event.is_echo():
		return false
	if InputMap.has_action("rhythm_hit") and event.is_action_pressed("rhythm_hit"):
		return true
	if InputMap.has_action("interact") and event.is_action_pressed("interact"):
		return true
	if event.is_action_pressed("ui_accept"):
		return true
	return false

func _release_ui_focus() -> void:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var focused: Control = viewport.gui_get_focus_owner()
	if focused != null:
		focused.release_focus()

func _complete_qte(raw_accuracy: float) -> void:
	if not _is_running:
		return
	_is_running = false
	
	var acc: float = clampf(raw_accuracy, 0.0, 1.0)
	var eval_res: Dictionary = BattleCalculator.evaluate_qte_multiplier(acc, _config)
	var tier_label: String = str(eval_res.get("tier", "НОРМАЛЬНО"))
	
	_on_qte_judged(acc, tier_label)
	queue_redraw()
	
	if is_inside_tree():
		await get_tree().create_timer(0.35).timeout
	
	qte_finished.emit(acc, tier_label)
	queue_free()
