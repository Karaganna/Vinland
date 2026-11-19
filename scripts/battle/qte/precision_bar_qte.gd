# res://scripts/battle/qte/precision_bar_qte.gd
class_name PrecisionBarQTE
extends BaseQTEMinigame

## Шкала точности в стиле Undertale (бегущий ползунок к центру для атак мечом / ульты)
var _cursor_pos: float = 0.0
var _locked_cursor_pos: float = -1.0
var _title_label: Label = null
var _result_label: Label = null

func _on_qte_started() -> void:
	_cursor_pos = 0.0
	_locked_cursor_pos = -1.0
	_ensure_labels()
	if _title_label != null:
		_title_label.text = "ШКАЛА ТОЧНОСТИ — жмите [Пробел / E / Enter] в центре!"
	if _result_label != null:
		_result_label.text = ""

func _process(_delta: float) -> void:
	if not _is_running or _config == null:
		return
	
	var elapsed: float = _get_synced_elapsed_seconds()
	var duration: float = maxf(0.6, _config.duration_seconds)
	if elapsed >= duration:
		_locked_cursor_pos = _cursor_pos
		_complete_qte(0.0)
		return
	
	var speed: float = maxf(0.3, _config.cursor_speed)
	var cycle: float = fmod(elapsed * speed * 0.75, 2.0)
	_cursor_pos = cycle if cycle <= 1.0 else (2.0 - cycle)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _is_running:
		return
	if _is_hit_action_pressed(event):
		get_viewport().set_input_as_handled()
		_judge_press()

func _judge_press() -> void:
	_locked_cursor_pos = _cursor_pos
	var success_half: float = clampf(_config.success_zone_width * 0.5, 0.04, 0.45)
	var perfect_half: float = clampf(_config.perfect_zone_width * 0.5, 0.015, success_half)
	var dist: float = absf(_cursor_pos - 0.5)
	
	var accuracy: float = 0.0
	if dist <= perfect_half:
		accuracy = lerpf(1.0, 0.92, dist / maxf(0.001, perfect_half))
	elif dist <= success_half:
		var t: float = (dist - perfect_half) / maxf(0.001, success_half - perfect_half)
		accuracy = lerpf(0.88, 0.45, t)
	else:
		var out_t: float = (dist - success_half) / maxf(0.01, 0.5 - success_half)
		accuracy = maxf(0.0, 0.25 * (1.0 - out_t))
	
	_complete_qte(accuracy)

func _on_qte_judged(accuracy: float, tier_label: String) -> void:
	if _result_label == null:
		return
	_result_label.text = "%s (%d%%)" % [tier_label, roundi(accuracy * 100.0)]
	if accuracy >= 0.90:
		_result_label.modulate = Color(1.0, 0.9, 0.25, 1.0)
	elif accuracy >= 0.30:
		_result_label.modulate = Color(0.45, 0.95, 0.55, 1.0)
	else:
		_result_label.modulate = Color(1.0, 0.35, 0.35, 1.0)

func _draw() -> void:
	var w: float = maxf(240.0, size.x)
	var h: float = maxf(76.0, size.y)
	var bar_w: float = w - 36.0
	var bar_h: float = 24.0
	var bar_x: float = 18.0
	var bar_y: float = clampf(h * 0.42, 24.0, h - 38.0)
	
	# Фон трека
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.10, 0.12, 0.18, 1.0))
	
	var success_w: float = clampf(_config.success_zone_width if _config != null else 0.22, 0.05, 0.9) * bar_w
	var perfect_w: float = clampf(_config.perfect_zone_width if _config != null else 0.08, 0.02, 0.5) * bar_w
	var center_x: float = bar_x + (bar_w * 0.5)
	
	# Зона попадания
	draw_rect(Rect2(center_x - success_w * 0.5, bar_y + 2.0, success_w, bar_h - 4.0), Color(0.22, 0.62, 0.34, 0.85))
	# Идеальная центральная зона
	draw_rect(Rect2(center_x - perfect_w * 0.5, bar_y + 1.0, perfect_w, bar_h - 2.0), Color(1.0, 0.82, 0.20, 0.95))
	# Центральная риска
	draw_line(Vector2(center_x, bar_y - 2.0), Vector2(center_x, bar_y + bar_h + 2.0), Color(1.0, 1.0, 1.0, 0.7), 1.5)
	# Рамка шкалы
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.55, 0.65, 0.85, 1.0), false, 2.0)
	
	# Бегущий ползунок
	var active_pos: float = _locked_cursor_pos if _locked_cursor_pos >= 0.0 else _cursor_pos
	var cursor_x: float = bar_x + clampf(active_pos, 0.0, 1.0) * bar_w
	draw_line(Vector2(cursor_x, bar_y - 4.0), Vector2(cursor_x, bar_y + bar_h + 4.0), Color(1.0, 1.0, 1.0, 1.0), 4.0)
	draw_line(Vector2(cursor_x, bar_y - 3.0), Vector2(cursor_x, bar_y + bar_h + 3.0), Color(0.95, 0.25, 0.25, 1.0), 2.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_labels()
		queue_redraw()

func _ensure_labels() -> void:
	if _title_label == null:
		_title_label = Label.new()
		_title_label.name = "PrecisionTitle"
		_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_title_label.add_theme_font_size_override("font_size", 10)
		_title_label.modulate = Color(0.92, 0.94, 1.0, 1.0)
		add_child(_title_label)
	
	if _result_label == null:
		_result_label = Label.new()
		_result_label.name = "PrecisionResult"
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
		_result_label.position = Vector2(8.0, maxf(58.0, h - 20.0))
		_result_label.size = Vector2(w - 16.0, 18.0)
