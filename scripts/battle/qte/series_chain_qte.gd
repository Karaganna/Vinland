# res://scripts/battle/qte/series_chain_qte.gd
class_name SeriesChainQTE
extends BaseQTEMinigame

## QTE «Серия» (SERIES_CHAIN): N проверок «Центр» подряд; каждое попадание дает удар, первый промах обрывает серию
var _max_steps: int = 4
var _current_step: int = 0
var _landed_hits: int = 0
var _sum_accuracy: float = 0.0
var _step_start_sec: float = 0.0
var _cursor_pos: float = 0.0
var _step_results: Array[int] = [] # 0 = ожидание, 1 = попал, 2 = идеальн., -1 = промах

var _title_label: Label = null
var _result_label: Label = null

func _on_qte_started() -> void:
	_max_steps = maxi(2, _config.series_max_steps if _config != null else 4)
	_current_step = 0
	_landed_hits = 0
	_sum_accuracy = 0.0
	_step_start_sec = _get_synced_elapsed_seconds()
	_cursor_pos = 0.0
	_step_results.clear()
	for _i: int in range(_max_steps):
		_step_results.append(0)
	_ensure_labels()
	_update_header()
	if _result_label != null:
		_result_label.text = ""

func _process(_delta: float) -> void:
	if not _is_running or _config == null:
		return
	
	var now_sec: float = _get_synced_elapsed_seconds()
	var step_elapsed: float = maxf(0.0, now_sec - _step_start_sec)
	var step_dur: float = maxf(0.75, _config.duration_seconds)
	if step_elapsed >= step_dur:
		_break_series_on_miss()
		return
	
	var eff_speed: float = maxf(0.4, _config.cursor_speed + float(_current_step) * _config.series_speed_step_bonus)
	var cycle: float = fmod(step_elapsed * eff_speed * 0.80, 2.0)
	_cursor_pos = cycle if cycle <= 1.0 else (2.0 - cycle)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _is_running:
		return
	if _is_hit_action_pressed(event):
		get_viewport().set_input_as_handled()
		_judge_step_press()

func _judge_step_press() -> void:
	var success_half: float = clampf(_config.success_zone_width * 0.5, 0.04, 0.45)
	var perfect_half: float = clampf(_config.perfect_zone_width * 0.5, 0.015, success_half)
	var dist: float = absf(_cursor_pos - 0.5)
	
	if dist > success_half:
		_break_series_on_miss()
		return
	
	var step_acc: float = 0.78
	if dist <= perfect_half:
		step_acc = lerpf(1.0, 0.92, dist / maxf(0.001, perfect_half))
		_step_results[_current_step] = 2
	else:
		var t: float = (dist - perfect_half) / maxf(0.001, success_half - perfect_half)
		step_acc = lerpf(0.88, 0.64, t)
		_step_results[_current_step] = 1
	
	_landed_hits += 1
	_sum_accuracy += step_acc
	_current_step += 1
	
	if _current_step >= _max_steps:
		_finish_series()
		return
	
	_step_start_sec = _get_synced_elapsed_seconds()
	_cursor_pos = 0.0 if (_current_step % 2 == 0) else 1.0
	_update_header()
	queue_redraw()

func _break_series_on_miss() -> void:
	if _current_step >= 0 and _current_step < _step_results.size():
		_step_results[_current_step] = -1
	_finish_series()

func _finish_series() -> void:
	result_metadata = {
		"is_series": true,
		"series_hits": _landed_hits,
		"series_max": _max_steps
	}
	if _landed_hits <= 0:
		_complete_qte(0.0)
		return
	var avg_acc: float = clampf(_sum_accuracy / float(_landed_hits), 0.62, 1.0)
	_complete_qte(avg_acc)

func _update_header() -> void:
	if _title_label != null:
		_title_label.text = "СЕРИЯ УДАРОВ (%d/%d) — первый промах обрывает цепочку!" % [_landed_hits, _max_steps]

func _on_qte_judged(_accuracy: float, tier_label: String) -> void:
	if _result_label == null:
		return
	_result_label.text = "СЕРИЯ: %d из %d ударов (%s)" % [_landed_hits, _max_steps, tier_label]
	_result_label.modulate = (
		Color(1.0, 0.9, 0.25, 1.0) if _landed_hits >= _max_steps
		else (Color(0.45, 0.95, 0.55, 1.0) if _landed_hits > 0 else Color(1.0, 0.35, 0.35, 1.0))
	)

func _draw() -> void:
	var w: float = maxf(240.0, size.x)
	var bar_w: float = w - 36.0
	var bar_h: float = 20.0
	var bar_x: float = 18.0
	var bar_y: float = 34.0
	
	# Индикаторы шагов серии
	var pip_w: float = 18.0
	var pip_gap: float = 6.0
	var total_pips_w: float = float(_max_steps) * pip_w + float(_max_steps - 1) * pip_gap
	var start_px: float = (w - total_pips_w) * 0.5
	for i: int in range(_max_steps):
		var pr: Rect2 = Rect2(start_px + float(i) * (pip_w + pip_gap), 19.0, pip_w, 10.0)
		var st_code: int = _step_results[i]
		var p_col: Color = Color(0.22, 0.26, 0.36, 0.9)
		if st_code == 2:
			p_col = Color(1.0, 0.86, 0.22, 1.0)
		elif st_code == 1:
			p_col = Color(0.32, 0.88, 0.48, 1.0)
		elif st_code == -1:
			p_col = Color(0.95, 0.28, 0.28, 1.0)
		elif i == _current_step and _is_running:
			p_col = Color(0.45, 0.72, 1.0, 0.95)
		draw_rect(pr, p_col)
		draw_rect(pr, Color.WHITE, false, 1.0)
	
	# Шкала текущего удара
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.10, 0.12, 0.18, 1.0))
	var succ_w: float = clampf(_config.success_zone_width if _config != null else 0.22, 0.06, 0.6) * bar_w
	var perf_w: float = clampf(_config.perfect_zone_width if _config != null else 0.08, 0.02, 0.3) * bar_w
	var cx: float = bar_x + bar_w * 0.5
	draw_rect(Rect2(cx - succ_w * 0.5, bar_y + 2.0, succ_w, bar_h - 4.0), Color(0.22, 0.62, 0.34, 0.85))
	draw_rect(Rect2(cx - perf_w * 0.5, bar_y + 1.0, perf_w, bar_h - 2.0), Color(1.0, 0.82, 0.20, 0.95))
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.55, 0.65, 0.85, 1.0), false, 1.8)
	
	var cur_x: float = bar_x + clampf(_cursor_pos, 0.0, 1.0) * bar_w
	draw_line(Vector2(cur_x, bar_y - 3.0), Vector2(cur_x, bar_y + bar_h + 3.0), Color.WHITE, 3.5)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_labels()
		queue_redraw()

func _ensure_labels() -> void:
	if _title_label == null:
		_title_label = Label.new()
		_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_title_label.add_theme_font_size_override("font_size", 9)
		add_child(_title_label)
	if _result_label == null:
		_result_label = Label.new()
		_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_result_label.add_theme_font_size_override("font_size", 10)
		add_child(_result_label)
	_layout_labels()

func _layout_labels() -> void:
	var w: float = maxf(240.0, size.x)
	var h: float = maxf(76.0, size.y)
	if _title_label != null:
		_title_label.position = Vector2(8.0, 1.0)
		_title_label.size = Vector2(w - 16.0, 16.0)
	if _result_label != null:
		_result_label.position = Vector2(8.0, maxf(57.0, h - 19.0))
		_result_label.size = Vector2(w - 16.0, 17.0)
