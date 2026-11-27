# res://scripts/battle/qte/rune_sequence_qte.gd
class_name RuneSequenceQTE
extends BaseQTEMinigame

## QTE «Вязь знаков» (RUNE_SEQUENCE): поочередная подсветка рун/направлений и повтор через InputMap
const GLYPHS: Array[String] = ["ᚠ ←", "ᚢ ↓", "ᛏ ↑", "ᚱ →", "ᛟ ✦"]

var _sequence: Array[int] = []
var _states: Array[int] = [] # 0 = ждет, 1 = верно, -1 = ошибка
var _preview_phase: bool = true
var _preview_index: int = -1
var _input_index: int = 0
var _correct_count: int = 0
var _input_start_sec: float = 0.0

var _title_label: Label = null
var _result_label: Label = null

func _on_qte_started() -> void:
	var seq_len: int = clampi(_config.sequence_length if _config != null else 4, 3, 6)
	_sequence.clear()
	_states.clear()
	for _i: int in range(seq_len):
		_sequence.append(randi() % GLYPHS.size())
		_states.append(0)
	_preview_phase = true
	_preview_index = 0
	_input_index = 0
	_correct_count = 0
	_input_start_sec = 0.0
	_ensure_labels()
	if _title_label != null:
		_title_label.text = "ВЯЗЬ ЗНАКОВ — запомните порядок рун!"
	if _result_label != null:
		_result_label.text = ""

func _process(_delta: float) -> void:
	if not _is_running or _config == null:
		return
	
	var elapsed: float = _get_synced_elapsed_seconds()
	var step_sec: float = maxf(0.18, _config.sequence_preview_step_sec)
	var total_preview_sec: float = float(_sequence.size()) * step_sec
	
	if _preview_phase:
		if elapsed >= total_preview_sec:
			_preview_phase = false
			_preview_index = -1
			_input_start_sec = elapsed
			if _title_label != null:
				_title_label.text = "ПОВТОРИТЕ ВЯЗЬ! [←/↓/↑/→ и Пробел/E для ✦]"
		else:
			_preview_index = clampi(int(floor(elapsed / step_sec)), 0, _sequence.size() - 1)
		queue_redraw()
		return
	
	var input_elapsed: float = maxf(0.0, elapsed - _input_start_sec)
	if input_elapsed >= maxf(1.5, _config.duration_seconds + 0.8):
		_finish_sequence()
		return
	
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _is_running or _preview_phase or event.is_echo():
		return
	
	var code: int = _map_event_to_glyph_code(event)
	if code < 0:
		return
	
	get_viewport().set_input_as_handled()
	if _input_index >= _sequence.size():
		return
	
	if code == _sequence[_input_index]:
		_states[_input_index] = 1
		_correct_count += 1
	else:
		_states[_input_index] = -1
	
	_input_index += 1
	queue_redraw()
	if _input_index >= _sequence.size():
		_finish_sequence()

func _map_event_to_glyph_code(event: InputEvent) -> int:
	if (InputMap.has_action("move_left") and event.is_action_pressed("move_left")) or event.is_action_pressed("ui_left"):
		return 0
	if (InputMap.has_action("move_down") and event.is_action_pressed("move_down")) or event.is_action_pressed("ui_down"):
		return 1
	if (InputMap.has_action("move_up") and event.is_action_pressed("move_up")) or event.is_action_pressed("ui_up"):
		return 2
	if (InputMap.has_action("move_right") and event.is_action_pressed("move_right")) or event.is_action_pressed("ui_right"):
		return 3
	if _is_hit_action_pressed(event):
		return 4
	return -1

func _finish_sequence() -> void:
	var acc: float = float(_correct_count) / float(maxi(1, _sequence.size()))
	result_metadata = {
		"sequence_correct": _correct_count,
		"sequence_total": _sequence.size()
	}
	_complete_qte(acc)

func _on_qte_judged(accuracy: float, tier_label: String) -> void:
	if _result_label == null:
		return
	_result_label.text = "ВЯЗЬ: %d/%d знаков — %s (%d%%)" % [
		_correct_count,
		_sequence.size(),
		tier_label,
		roundi(accuracy * 100.0)
	]
	_result_label.modulate = (
		Color(1.0, 0.9, 0.25, 1.0) if accuracy >= 0.90
		else (Color(0.45, 0.95, 0.55, 1.0) if accuracy >= 0.30 else Color(1.0, 0.35, 0.35, 1.0))
	)

func _draw() -> void:
	var w: float = maxf(240.0, size.x)
	var count: int = maxi(1, _sequence.size())
	var box_w: float = 52.0
	var box_h: float = 30.0
	var gap: float = 8.0
	var total_w: float = float(count) * box_w + float(count - 1) * gap
	var start_x: float = (w - total_w) * 0.5
	var box_y: float = 23.0
	
	for i: int in range(count):
		var rx: float = start_x + float(i) * (box_w + gap)
		var r: Rect2 = Rect2(rx, box_y, box_w, box_h)
		var bg_col: Color = Color(0.12, 0.15, 0.22, 0.95)
		var border_col: Color = Color(0.42, 0.52, 0.72, 1.0)
		
		if _preview_phase and i == _preview_index:
			bg_col = Color(0.35, 0.52, 0.88, 0.95)
			border_col = Color(1.0, 0.90, 0.32, 1.0)
		elif _states[i] == 1:
			bg_col = Color(0.18, 0.58, 0.32, 0.95)
			border_col = Color(0.48, 1.0, 0.62, 1.0)
		elif _states[i] == -1:
			bg_col = Color(0.62, 0.18, 0.20, 0.95)
			border_col = Color(1.0, 0.42, 0.42, 1.0)
		elif not _preview_phase and i == _input_index and _is_running:
			border_col = Color(1.0, 0.88, 0.30, 1.0)
		
		draw_rect(r, bg_col)
		draw_rect(r, border_col, false, 2.0)
		
		var show_glyph: bool = _preview_phase or i < _input_index or not _is_running
		# Оставляем символы видимыми с легким приглушением во время повтора, чтобы акцент был на точном темпе и безошибочном вводе
		var glyph_txt: String = GLYPHS[_sequence[i]]
		var txt_alpha: float = 1.0 if show_glyph or i == _preview_index else 0.78
		draw_string(
			ThemeDB.fallback_font,
			Vector2(rx + 8.0, box_y + 20.0),
			glyph_txt,
			HORIZONTAL_ALIGNMENT_LEFT,
			box_w - 8.0,
			12,
			Color(0.96, 0.96, 1.0, txt_alpha)
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
