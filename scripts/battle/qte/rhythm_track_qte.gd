# res://scripts/battle/qte/rhythm_track_qte.gd
class_name RhythmTrackQTE
extends BaseQTEMinigame

## Ритм-дорожка с падающими нотами (для звуковых навыков и защиты от песен)
## Синхронизируется через BaseQTEMinigame._get_synced_elapsed_seconds() (AudioServer + монотонные часы)

const LANE_COUNT: int = 4
const LEAD_IN_SEC: float = 0.85
const PERFECT_WINDOW_SEC: float = 0.09
const GOOD_WINDOW_SEC: float = 0.17
const MISS_WINDOW_SEC: float = 0.25
const FALL_SPEED_PX: float = 78.0

var _notes: Array[Dictionary] = []
var _lane_flash_until_sec: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _lane_flash_colors: Array[Color] = [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]
var _total_score: float = 0.0
var _hits_count: int = 0

var _status_label: Label = null

func _on_qte_started() -> void:
	_total_score = 0.0
	_hits_count = 0
	_lane_flash_until_sec = [0.0, 0.0, 0.0, 0.0]
	_build_note_schedule()
	_ensure_labels()
	_update_status_label()

func _build_note_schedule() -> void:
	_notes.clear()
	var bpm: float = maxf(40.0, _config.bpm if _config != null else 120.0)
	var beat_sec: float = 60.0 / bpm
	var count: int = maxi(1, _config.note_count if _config != null else 6)
	
	for i: int in range(count):
		var lane: int = i % LANE_COUNT
		if _config != null and i < _config.note_lanes.size():
			lane = clampi(_config.note_lanes[i], 0, LANE_COUNT - 1)
		var beat_offset: float = float(i + 1)
		if _config != null and i < _config.note_beat_offsets.size():
			beat_offset = _config.note_beat_offsets[i]
		var target_sec: float = LEAD_IN_SEC + beat_offset * beat_sec
		_notes.append({
			"lane": lane,
			"target_sec": target_sec,
			"judged": false,
			"score": 0.0
		})

func _process(_delta: float) -> void:
	if not _is_running:
		return
	
	var elapsed: float = _get_synced_elapsed_seconds()
	var expired_any: bool = false
	for note: Dictionary in _notes:
		if bool(note.get("judged", false)):
			continue
		var target_sec: float = float(note.get("target_sec", 0.0))
		if elapsed - target_sec > MISS_WINDOW_SEC:
			note["judged"] = true
			note["score"] = 0.0
			var lane: int = int(note.get("lane", 0))
			_trigger_lane_flash(lane, Color(1.0, 0.25, 0.25, 1.0), elapsed)
			expired_any = true
	
	if expired_any:
		_update_status_label()
	
	queue_redraw()
	
	if _are_all_notes_judged():
		var final_acc: float = _total_score / float(maxi(1, _notes.size()))
		_complete_qte(final_acc)

func _unhandled_input(event: InputEvent) -> void:
	if not _is_running or event.is_echo():
		return
	
	var lane: int = _get_lane_from_input(event)
	if lane < 0:
		return
	
	get_viewport().set_input_as_handled()
	_judge_lane_press(lane)

func _get_lane_from_input(event: InputEvent) -> int:
	if (InputMap.has_action("move_left") and event.is_action_pressed("move_left")) or event.is_action_pressed("ui_left"):
		return 0
	if (InputMap.has_action("move_down") and event.is_action_pressed("move_down")) or event.is_action_pressed("ui_down"):
		return 1
	if (InputMap.has_action("move_up") and event.is_action_pressed("move_up")) or event.is_action_pressed("ui_up"):
		return 2
	if (InputMap.has_action("move_right") and event.is_action_pressed("move_right")) or event.is_action_pressed("ui_right"):
		return 3
	return -1

func _judge_lane_press(lane: int) -> void:
	var elapsed: float = _get_synced_elapsed_seconds()
	var best_idx: int = -1
	var best_diff: float = 999.0
	
	for i: int in range(_notes.size()):
		var note: Dictionary = _notes[i]
		if bool(note.get("judged", false)) or int(note.get("lane", -1)) != lane:
			continue
		var diff: float = absf(elapsed - float(note.get("target_sec", 0.0)))
		if diff < best_diff:
			best_diff = diff
			best_idx = i
	
	if best_idx < 0 or best_diff > MISS_WINDOW_SEC:
		_trigger_lane_flash(lane, Color(0.85, 0.3, 0.3, 0.9), elapsed)
		return
	
	var hit_note: Dictionary = _notes[best_idx]
	hit_note["judged"] = true
	
	var note_score: float = 0.0
	var flash_col: Color = Color.WHITE
	if best_diff <= PERFECT_WINDOW_SEC:
		note_score = 1.0
		_hits_count += 1
		flash_col = Color(1.0, 0.88, 0.25, 1.0)
	elif best_diff <= GOOD_WINDOW_SEC:
		note_score = 0.72
		_hits_count += 1
		flash_col = Color(0.35, 0.95, 0.50, 1.0)
	else:
		note_score = 0.42
		_hits_count += 1
		flash_col = Color(0.45, 0.75, 1.0, 1.0)
	
	hit_note["score"] = note_score
	_total_score += note_score
	_trigger_lane_flash(lane, flash_col, elapsed)
	_update_status_label()
	queue_redraw()
	
	if _are_all_notes_judged():
		var final_acc: float = _total_score / float(maxi(1, _notes.size()))
		_complete_qte(final_acc)

func _are_all_notes_judged() -> bool:
	for note: Dictionary in _notes:
		if not bool(note.get("judged", false)):
			return false
	return true

func _trigger_lane_flash(lane: int, color: Color, now_sec: float) -> void:
	if lane < 0 or lane >= LANE_COUNT:
		return
	_lane_flash_colors[lane] = color
	_lane_flash_until_sec[lane] = now_sec + 0.18

func _on_qte_judged(accuracy: float, tier_label: String) -> void:
	if _status_label != null:
		_status_label.text = "РИТМ: %s (%d%%)" % [tier_label, roundi(accuracy * 100.0)]

func _update_status_label() -> void:
	if _status_label != null:
		_status_label.text = "РИТМ [A/S/W/D]  Попаданий: %d/%d" % [_hits_count, _notes.size()]

func _draw() -> void:
	var w: float = maxf(240.0, size.x)
	var h: float = maxf(76.0, size.y)
	var track_w: float = minf(260.0, w - 24.0)
	var track_x: float = (w - track_w) * 0.5
	var top_y: float = 18.0
	var hit_y: float = h - 18.0
	var lane_w: float = track_w / float(LANE_COUNT)
	var elapsed: float = _get_synced_elapsed_seconds()
	
	# Фон ритм-дорожки
	draw_rect(Rect2(track_x, top_y, track_w, hit_y - top_y + 12.0), Color(0.08, 0.10, 0.16, 0.95))
	draw_rect(Rect2(track_x, top_y, track_w, hit_y - top_y + 12.0), Color(0.35, 0.45, 0.65, 0.9), false, 1.5)
	
	var lane_labels: Array[String] = ["←", "↓", "↑", "→"]
	for i: int in range(LANE_COUNT):
		var lx: float = track_x + float(i) * lane_w
		if i > 0:
			draw_line(Vector2(lx, top_y), Vector2(lx, hit_y + 12.0), Color(0.25, 0.30, 0.42, 0.7), 1.0)
		
		var receptor_rect: Rect2 = Rect2(lx + 6.0, hit_y - 5.0, lane_w - 12.0, 10.0)
		var flash_active: bool = elapsed <= _lane_flash_until_sec[i]
		var rec_col: Color = _lane_flash_colors[i] if flash_active else Color(0.24, 0.28, 0.38, 0.85)
		draw_rect(receptor_rect, rec_col)
		draw_rect(receptor_rect, Color(0.75, 0.82, 0.95, 0.9), false, 1.2)
		
		var lbl_pos: Vector2 = Vector2(lx + lane_w * 0.5 - 4.0, hit_y + 15.0)
		draw_string(ThemeDB.fallback_font, lbl_pos, lane_labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.85, 0.9, 1.0, 0.9))
	
	# Линия попадания
	draw_line(Vector2(track_x, hit_y), Vector2(track_x + track_w, hit_y), Color(1.0, 0.88, 0.35, 0.8), 1.5)
	
	# Падающие ноты (позиция вычисляется напрямую от времени без накопления delta)
	var lane_colors: Array[Color] = [
		Color(0.95, 0.35, 0.45, 1.0),
		Color(0.35, 0.75, 1.0, 1.0),
		Color(0.40, 0.95, 0.55, 1.0),
		Color(1.0, 0.80, 0.25, 1.0)
	]
	for note: Dictionary in _notes:
		if bool(note.get("judged", false)):
			continue
		var lane: int = int(note.get("lane", 0))
		var target_sec: float = float(note.get("target_sec", 0.0))
		var y_pos: float = hit_y - ((target_sec - elapsed) * FALL_SPEED_PX)
		if y_pos < top_y - 6.0 or y_pos > hit_y + 10.0:
			continue
		var nx: float = track_x + float(lane) * lane_w + 8.0
		var note_rect: Rect2 = Rect2(nx, y_pos - 4.0, lane_w - 16.0, 8.0)
		draw_rect(note_rect, lane_colors[lane])
		draw_rect(note_rect, Color.WHITE, false, 1.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_labels()
		queue_redraw()

func _ensure_labels() -> void:
	if _status_label == null:
		_status_label = Label.new()
		_status_label.name = "RhythmStatusLabel"
		_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_status_label.add_theme_font_size_override("font_size", 10)
		_status_label.modulate = Color(0.92, 0.95, 1.0, 1.0)
		add_child(_status_label)
	
	_layout_labels()

func _layout_labels() -> void:
	if _status_label != null:
		_status_label.position = Vector2(8.0, 0.0)
		_status_label.size = Vector2(maxf(240.0, size.x) - 16.0, 16.0)
