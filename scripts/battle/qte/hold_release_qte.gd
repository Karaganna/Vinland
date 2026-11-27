# res://scripts/battle/qte/hold_release_qte.gd
class_name HoldReleaseQTE
extends BaseQTEMinigame

## QTE «Удержание» (HOLD_RELEASE): зажать кнопку действия для наполнения шкалы и отпустить в целевой зоне
var _is_holding: bool = false
var _hold_start_sec: float = 0.0
var _charge_ratio: float = 0.0
var _locked_ratio: float = -1.0

var _title_label: Label = null
var _result_label: Label = null

func _on_qte_started() -> void:
	_is_holding = false
	_hold_start_sec = 0.0
	_charge_ratio = 0.0
	_locked_ratio = -1.0
	_ensure_labels()
	if _title_label != null:
		_title_label.text = "УДЕРЖАНИЕ — зажмите [Пробел / E] и отпустите в золотой зоне!"
	if _result_label != null:
		_result_label.text = ""

func _process(_delta: float) -> void:
	if not _is_running or _config == null:
		return
	
	var elapsed: float = _get_synced_elapsed_seconds()
	var max_dur: float = maxf(1.2, _config.duration_seconds + 0.8)
	if _is_holding:
		var held_sec: float = maxf(0.0, elapsed - _hold_start_sec)
		_charge_ratio = held_sec * maxf(0.25, _config.hold_charge_speed)
		if _charge_ratio >= 1.0:
			# Передержка сверх максимума срывает удар
			_charge_ratio = 1.0
			_locked_ratio = 1.0
			_complete_qte(0.15)
			return
	elif elapsed >= max_dur:
		_locked_ratio = 0.0
		_complete_qte(0.0)
		return
	
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _is_running:
		return
	if not _is_holding and _is_hit_action_pressed(event):
		get_viewport().set_input_as_handled()
		_is_holding = true
		_hold_start_sec = _get_synced_elapsed_seconds()
		if _title_label != null:
			_title_label.text = "УДЕРЖИВАЙТЕ... Отпустите в целевом окне!"
		return
	
	if _is_holding and _is_hit_action_released(event):
		get_viewport().set_input_as_handled()
		_is_holding = false
		_judge_release()

func _judge_release() -> void:
	_locked_ratio = clampf(_charge_ratio, 0.0, 1.0)
	var center: float = clampf(_config.hold_target_center, 0.35, 0.90)
	var success_half: float = clampf(_config.success_zone_width * 0.5, 0.05, 0.30)
	var perfect_half: float = clampf(_config.perfect_zone_width * 0.5, 0.02, success_half)
	var diff: float = absf(_locked_ratio - center)
	
	var acc: float = 0.0
	if diff <= perfect_half:
		acc = lerpf(1.0, 0.92, diff / maxf(0.001, perfect_half))
	elif diff <= success_half:
		var t: float = (diff - perfect_half) / maxf(0.001, success_half - perfect_half)
		acc = lerpf(0.88, 0.55, t)
	elif diff <= success_half + 0.12:
		acc = 0.38
	else:
		acc = 0.0
	
	_complete_qte(acc)

func _on_qte_judged(accuracy: float, tier_label: String) -> void:
	if _result_label == null:
		return
	_result_label.text = "%s (%d%%)" % [tier_label, roundi(accuracy * 100.0)]
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
	
	var center: float = clampf(_config.hold_target_center if _config != null else 0.75, 0.35, 0.90)
	var succ_w: float = clampf(_config.success_zone_width if _config != null else 0.22, 0.08, 0.45) * bar_w
	var perf_w: float = clampf(_config.perfect_zone_width if _config != null else 0.08, 0.03, 0.25) * bar_w
	var target_x: float = bar_x + center * bar_w
	
	var cur_ratio: float = _locked_ratio if _locked_ratio >= 0.0 else _charge_ratio
	var fill_w: float = clampf(cur_ratio, 0.0, 1.0) * bar_w
	if fill_w > 0.5:
		var fill_col: Color = Color(0.95, 0.52, 0.18, 0.90) if cur_ratio < 0.95 else Color(0.95, 0.22, 0.22, 0.95)
		draw_rect(Rect2(bar_x, bar_y + 2.0, fill_w, bar_h - 4.0), fill_col)
	
	draw_rect(Rect2(target_x - succ_w * 0.5, bar_y + 2.0, succ_w, bar_h - 4.0), Color(0.25, 0.80, 0.42, 0.55))
	draw_rect(Rect2(target_x - perf_w * 0.5, bar_y + 1.0, perf_w, bar_h - 2.0), Color(1.0, 0.86, 0.22, 0.88))
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.58, 0.68, 0.88, 1.0), false, 2.0)
	
	var marker_x: float = bar_x + fill_w
	draw_line(Vector2(marker_x, bar_y - 3.0), Vector2(marker_x, bar_y + bar_h + 3.0), Color.WHITE, 3.0)

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
