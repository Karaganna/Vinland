# res://scripts/battle/qte/circular_skill_check_qte.gd
class_name CircularSkillCheckQTE
extends BaseQTEMinigame

## Круговой скилл-чек в стиле Dead by Daylight (для защитного блока против телеграфируемых спецатак)
var _needle_angle_deg: float = 0.0
var _locked_angle_deg: float = -1.0
var _target_center_deg: float = 180.0
var _success_span_deg: float = 72.0
var _perfect_span_deg: float = 24.0

var _info_label: Label = null
var _result_label: Label = null

func _on_qte_started() -> void:
	_needle_angle_deg = 0.0
	_locked_angle_deg = -1.0
	_target_center_deg = randf_range(115.0, 265.0)
	_success_span_deg = clampf(_config.success_zone_width, 0.08, 0.45) * 360.0
	_perfect_span_deg = clampf(_config.perfect_zone_width, 0.03, 0.20) * 360.0
	_ensure_labels()
	if _info_label != null:
		_info_label.text = "ЗАЩИТНЫЙ СКИЛЛ-ЧЕК!\nНажмите [Пробел / E] в зоне"
	if _result_label != null:
		_result_label.text = ""

func _process(_delta: float) -> void:
	if not _is_running or _config == null:
		return
	
	var elapsed: float = _get_synced_elapsed_seconds()
	var rev_duration: float = maxf(0.85, _config.duration_seconds / clampf(_config.cursor_speed, 0.6, 2.0))
	_needle_angle_deg = (elapsed / rev_duration) * 360.0
	
	if _needle_angle_deg >= 360.0:
		_needle_angle_deg = 360.0
		_locked_angle_deg = 360.0
		_complete_qte(0.0)
		return
	
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _is_running:
		return
	if _is_hit_action_pressed(event):
		get_viewport().set_input_as_handled()
		_judge_press()

func _judge_press() -> void:
	_locked_angle_deg = _needle_angle_deg
	var diff: float = absf(_shortest_angle_diff_deg(_needle_angle_deg, _target_center_deg))
	var perfect_half: float = _perfect_span_deg * 0.5
	var success_half: float = _success_span_deg * 0.5
	
	var accuracy: float = 0.0
	if diff <= perfect_half:
		accuracy = lerpf(1.0, 0.92, diff / maxf(0.1, perfect_half))
	elif diff <= success_half:
		var t: float = (diff - perfect_half) / maxf(0.1, success_half - perfect_half)
		accuracy = lerpf(0.86, 0.56, t)
	elif diff <= success_half + 14.0:
		accuracy = 0.42
	else:
		accuracy = 0.0
	
	_complete_qte(accuracy)

func _on_qte_judged(accuracy: float, tier_label: String) -> void:
	if _result_label == null:
		return
	_result_label.text = "ИТОГ: %s (%d%%)" % [tier_label, roundi(accuracy * 100.0)]
	if accuracy >= 0.90:
		_result_label.modulate = Color(1.0, 0.9, 0.25, 1.0)
	elif accuracy >= 0.30:
		_result_label.modulate = Color(0.45, 0.95, 0.55, 1.0)
	else:
		_result_label.modulate = Color(1.0, 0.35, 0.35, 1.0)

func _draw() -> void:
	var h: float = maxf(76.0, size.y)
	var radius: float = clampf(h * 0.37, 24.0, 34.0)
	var center: Vector2 = Vector2(clampf(size.x * 0.24, radius + 16.0, 120.0), h * 0.5)
	
	# Базовое темное кольцо
	draw_circle(center, radius + 6.0, Color(0.08, 0.09, 0.14, 0.92))
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.32, 0.36, 0.48, 1.0), 6.0)
	
	# Успешная дуга
	var suc_start: float = _cw_deg_to_rad(_target_center_deg - _success_span_deg * 0.5)
	var suc_end: float = _cw_deg_to_rad(_target_center_deg + _success_span_deg * 0.5)
	draw_arc(center, radius, suc_start, suc_end, 24, Color(0.28, 0.85, 0.45, 0.95), 7.0)
	
	# Идеальная дуга внутри успешной
	var perf_start: float = _cw_deg_to_rad(_target_center_deg - _perfect_span_deg * 0.5)
	var perf_end: float = _cw_deg_to_rad(_target_center_deg + _perfect_span_deg * 0.5)
	draw_arc(center, radius, perf_start, perf_end, 12, Color(1.0, 0.90, 0.25, 1.0), 8.0)
	
	# Вращающаяся стрелка
	var cur_deg: float = _locked_angle_deg if _locked_angle_deg >= 0.0 else _needle_angle_deg
	var rad: float = _cw_deg_to_rad(cur_deg)
	var tip: Vector2 = center + Vector2(cos(rad), sin(rad)) * (radius + 6.0)
	draw_line(center, tip, Color(1.0, 0.28, 0.24, 1.0), 3.0)
	draw_circle(center, 4.5, Color(0.95, 0.95, 1.0, 1.0))

func _cw_deg_to_rad(deg_cw: float) -> float:
	return deg_to_rad(deg_cw - 90.0)

func _shortest_angle_diff_deg(a_deg: float, b_deg: float) -> float:
	return fposmod(a_deg - b_deg + 540.0, 360.0) - 180.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_labels()
		queue_redraw()

func _ensure_labels() -> void:
	if _info_label == null:
		_info_label = Label.new()
		_info_label.name = "SkillCheckInfo"
		_info_label.add_theme_font_size_override("font_size", 10)
		_info_label.modulate = Color(1.0, 0.88, 0.65, 1.0)
		add_child(_info_label)
	
	if _result_label == null:
		_result_label = Label.new()
		_result_label.name = "SkillCheckResult"
		_result_label.add_theme_font_size_override("font_size", 11)
		add_child(_result_label)
	
	_layout_labels()

func _layout_labels() -> void:
	var w: float = maxf(240.0, size.x)
	var text_x: float = clampf(w * 0.40, 120.0, 220.0)
	var text_w: float = maxf(160.0, w - text_x - 8.0)
	if _info_label != null:
		_info_label.position = Vector2(text_x, 12.0)
		_info_label.size = Vector2(text_w, 36.0)
	if _result_label != null:
		_result_label.position = Vector2(text_x, 52.0)
		_result_label.size = Vector2(text_w, 24.0)
