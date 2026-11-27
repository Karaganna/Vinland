# res://scripts/battle/qte/rush_mash_qte.gd
class_name RushMashQTE
extends BaseQTEMinigame

## QTE «Рывок» (RUSH_MASH): быстрое нажатие кнопки действия за короткое окно для заполнения шкалы
var _fill_ratio: float = 0.0
var _press_count: int = 0
var _prev_elapsed_sec: float = 0.0

var _title_label: Label = null
var _result_label: Label = null

func _on_qte_started() -> void:
	_fill_ratio = 0.0
	_press_count = 0
	_prev_elapsed_sec = 0.0
	_ensure_labels()
	if _title_label != null:
		_title_label.text = "РЫВОК — быстро жмите [Пробел / E / Enter] для напора!"
	if _result_label != null:
		_result_label.text = ""

func _process(_delta: float) -> void:
	if not _is_running or _config == null:
		return
	
	var elapsed: float = _get_synced_elapsed_seconds()
	var dt: float = maxf(0.0, elapsed - _prev_elapsed_sec)
	_prev_elapsed_sec = elapsed
	
	var decay: float = maxf(0.0, _config.mash_decay_per_second) * dt
	_fill_ratio = clampf(_fill_ratio - decay, 0.0, 1.0)
	
	var duration: float = maxf(1.0, _config.duration_seconds)
	if elapsed >= duration:
		result_metadata = {"mash_presses": _press_count}
		_complete_qte(_fill_ratio)
		return
	
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _is_running:
		return
	if _is_hit_action_pressed(event):
		get_viewport().set_input_as_handled()
		_press_count += 1
		var target_presses: int = maxi(4, _config.mash_target_presses if _config != null else 10)
		_fill_ratio = clampf(_fill_ratio + (1.0 / float(target_presses)) * 1.15, 0.0, 1.0)
		queue_redraw()
		if _fill_ratio >= 0.999:
			result_metadata = {"mash_presses": _press_count}
			_complete_qte(1.0)

func _on_qte_judged(accuracy: float, tier_label: String) -> void:
	if _result_label == null:
		return
	_result_label.text = "РЫВОК: %s (%d%%)" % [tier_label, roundi(accuracy * 100.0)]
	_result_label.modulate = (
		Color(1.0, 0.9, 0.25, 1.0) if accuracy >= 0.90
		else (Color(0.45, 0.95, 0.55, 1.0) if accuracy >= 0.30 else Color(1.0, 0.35, 0.35, 1.0))
	)

func _draw() -> void:
	var w: float = maxf(240.0, size.x)
	var h: float = maxf(76.0, size.y)
	var bar_w: float = w - 36.0
	var bar_h: float = 22.0
	var bar_x: float = 18.0
	var bar_y: float = clampf(h * 0.42, 22.0, h - 36.0)
	
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.10, 0.12, 0.18, 1.0))
	var fill_w: float = clampf(_fill_ratio, 0.0, 1.0) * bar_w
	if fill_w > 0.5:
		var col: Color = Color(0.95, 0.38, 0.22, 0.95) if _fill_ratio < 0.90 else Color(1.0, 0.86, 0.22, 1.0)
		draw_rect(Rect2(bar_x, bar_y + 2.0, fill_w, bar_h - 4.0), col)
	
	# Отметка порога 90% (ИДЕАЛЬНО)
	var perf_x: float = bar_x + 0.90 * bar_w
	draw_line(Vector2(perf_x, bar_y - 2.0), Vector2(perf_x, bar_y + bar_h + 2.0), Color(1.0, 0.90, 0.28, 0.9), 2.0)
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.62, 0.70, 0.88, 1.0), false, 2.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_labels()
		queue_redraw()

func _ensure_labels() -> void:
	if _title_label == null:
		_title_label = Label.new()
		_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_title_label.add_theme_font_size_override("font_size", 10)
		add_child(_title_label)
	if _result_label == null:
		_result_label = Label.new()
		_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_result_label.add_theme_font_size_override("font_size", 11)
		add_child(_result_label)
	_layout_labels()

func _layout_labels() -> void:
	var w: float = maxf(240.0, size.x)
	var h: float = maxf(76.0, size.y)
	if _title_label != null:
		_title_label.position = Vector2(8.0, 2.0)
		_title_label.size = Vector2(w - 16.0, 18.0)
	if _result_label != null:
		_result_label.position = Vector2(8.0, maxf(56.0, h - 20.0))
		_result_label.size = Vector2(w - 16.0, 18.0)
