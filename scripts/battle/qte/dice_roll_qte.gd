# res://scripts/battle/qte/dice_roll_qte.gd
class_name DiceRollQTE
extends BaseQTEMinigame

## QTE «Бросок» (DICE_ROLL): вращаются кости/грани жребия, игрок по очереди останавливает их нажатием
var _dice_count: int = 3
var _dice_values: Array[int] = []
var _locked_flags: Array[bool] = []
var _active_die_index: int = 0

var _title_label: Label = null
var _result_label: Label = null

func _on_qte_started() -> void:
	_dice_count = clampi(_config.dice_count if _config != null else 3, 1, 5)
	_dice_values.clear()
	_locked_flags.clear()
	for i: int in range(_dice_count):
		_dice_values.append((i % 6) + 1)
		_locked_flags.append(false)
	_active_die_index = 0
	_ensure_labels()
	_update_header()
	if _result_label != null:
		_result_label.text = ""

func _process(_delta: float) -> void:
	if not _is_running or _config == null:
		return
	
	var elapsed: float = _get_synced_elapsed_seconds()
	var hz: float = maxf(2.0, _config.dice_cycle_hz)
	for i: int in range(_dice_count):
		if not _locked_flags[i]:
			var tick: int = int(floor(elapsed * (hz + float(i) * 1.3))) + i * 2
			_dice_values[i] = (tick % 6) + 1
	
	if elapsed >= maxf(1.5, _config.duration_seconds + 0.8):
		# При истечении времени незафиксированные кости падают слабой гранью (1)
		for i: int in range(_dice_count):
			if not _locked_flags[i]:
				_dice_values[i] = 1
				_locked_flags[i] = true
		_finish_dice_roll()
		return
	
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _is_running:
		return
	if _is_hit_action_pressed(event):
		get_viewport().set_input_as_handled()
		if _active_die_index < _dice_count:
			_locked_flags[_active_die_index] = true
			_active_die_index += 1
			_update_header()
			queue_redraw()
			if _active_die_index >= _dice_count:
				_finish_dice_roll()

func _finish_dice_roll() -> void:
	var sum_val: int = 0
	for v: int in _dice_values:
		sum_val += v
	var min_sum: int = _dice_count
	var max_sum: int = _dice_count * 6
	var norm: float = float(sum_val - min_sum) / float(maxi(1, max_sum - min_sum))
	var acc: float = clampf(norm * 1.08, 0.0, 1.0)
	result_metadata = {
		"dice_values": _dice_values.duplicate(),
		"dice_sum": sum_val,
		"dice_max": max_sum
	}
	_complete_qte(acc)

func _update_header() -> void:
	if _title_label != null:
		_title_label.text = "БРОСОК ЖРЕБИЯ (%d/%d) — жмите [Пробел / E], чтобы остановить грань!" % [
			mini(_active_die_index, _dice_count),
			_dice_count
		]

func _on_qte_judged(accuracy: float, tier_label: String) -> void:
	if _result_label == null:
		return
	var sum_val: int = 0
	for v: int in _dice_values:
		sum_val += v
	_result_label.text = "ЖРЕБИЙ: сумма %d/%d — %s (%d%%)" % [
		sum_val,
		_dice_count * 6,
		tier_label,
		roundi(accuracy * 100.0)
	]
	_result_label.modulate = (
		Color(1.0, 0.9, 0.25, 1.0) if accuracy >= 0.90
		else (Color(0.45, 0.95, 0.55, 1.0) if accuracy >= 0.30 else Color(1.0, 0.35, 0.35, 1.0))
	)

func _draw() -> void:
	var w: float = maxf(240.0, size.x)
	var die_size: float = 32.0
	var gap: float = 12.0
	var total_w: float = float(_dice_count) * die_size + float(_dice_count - 1) * gap
	var start_x: float = (w - total_w) * 0.5
	var die_y: float = 22.0
	
	for i: int in range(_dice_count):
		var dx: float = start_x + float(i) * (die_size + gap)
		var r: Rect2 = Rect2(dx, die_y, die_size, die_size)
		var locked: bool = _locked_flags[i]
		var val: int = _dice_values[i]
		var bg_col: Color = Color(0.20, 0.26, 0.36, 0.96) if not locked else (
			Color(0.26, 0.56, 0.34, 0.96) if val >= 5 else Color(0.18, 0.22, 0.30, 0.96)
		)
		var b_col: Color = Color(1.0, 0.88, 0.28, 1.0) if (i == _active_die_index and _is_running) else Color(0.62, 0.72, 0.90, 1.0)
		draw_rect(r, bg_col)
		draw_rect(r, b_col, false, 2.0)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(dx + 11.0, die_y + 22.0),
			str(val),
			HORIZONTAL_ALIGNMENT_LEFT,
			die_size,
			15,
			Color(1.0, 0.95, 0.65, 1.0) if val == 6 else Color.WHITE
		)

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
		_title_label.position = Vector2(8.0, 2.0)
		_title_label.size = Vector2(w - 16.0, 18.0)
	if _result_label != null:
		_result_label.position = Vector2(8.0, maxf(57.0, h - 19.0))
		_result_label.size = Vector2(w - 16.0, 17.0)
