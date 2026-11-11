# res://scripts/rune_wheel.gd
class_name RuneWheel
extends Node2D

## Сигнал завершения вращения колеса при атаке
## selected_runes: массив нажатых номеров рун (от 1 до 10, максимум 3)
## evaluation: словарь с результатами из AttackData.evaluate_selected_runes()
signal wheel_attack_finished(selected_runes: Array[int], evaluation: Dictionary)
## Сигнал при каждом нажатии пробела на руне
signal rune_activated(rune_number: int, is_priority: bool, current_count: int)

const RUNES_TEXTURE_PATH: String = "res://assets/sprites/fight/runes.png"
const TOTAL_RUNES: int = 10
const SECTOR_ANGLE_DEG: float = 36.0
const MAX_SELECTIONS: int = 3

## Внешний радиус колеса на экране боя (при 640x360)
@export var wheel_radius: float = 90.0
## Скорость вращения стрелки по часовой стрелке (градусов в секунду)
@export var pointer_speed_deg: float = 150.0
## Количество оборотов стрелки за одну атаку (если игрок не нажал 3 руны раньше)
@export var max_revolutions: float = 1.35

var _wheel_sprite: Sprite2D = null
var _pointer_overlay: Node2D = null
var _number_labels: Array[Label] = []
var _status_label: Label = null
var _slots_label: Label = null

var _is_spinning: bool = false
var _start_time_sec: float = 0.0
var _pointer_angle_deg: float = 0.0
var _current_attack: AttackData = null
var _priority_runes: Array[int] = []
var _selected_runes: Array[int] = []

func _ready() -> void:
	_setup_wheel_sprite()
	_setup_rune_number_labels()
	_setup_hud_labels()
	queue_redraw()

## Устанавливает приоритетные руны для предпросмотра на колесе
func set_preview_attack(attack: AttackData) -> void:
	_current_attack = attack
	if attack != null:
		_priority_runes = attack.priority_runes.duplicate()
	else:
		_priority_runes.clear()
	_update_number_label_colors()
	queue_redraw()

## Запускает вращение стрелки по часовой стрелке для выбранной атаки
func start_wheel_attack(attack: AttackData) -> void:
	_current_attack = attack
	if attack != null:
		_priority_runes = attack.priority_runes.duplicate()
	else:
		_priority_runes.clear()
	
	_selected_runes.clear()
	_pointer_angle_deg = 0.0
	_start_time_sec = _get_precise_clock_time()
	_is_spinning = true
	
	_update_number_label_colors()
	_update_slots_display()
	if _status_label != null:
		_status_label.text = "Жмите [ПРОБЕЛ] на приоритетных рунах (" + (attack.get_priority_runes_text() if attack != null else "") + ")!"
		_status_label.modulate = Color(1.0, 0.92, 0.45, 1.0)
	queue_redraw()

func _process(_delta: float) -> void:
	if not _is_spinning:
		return
	
	var elapsed: float = maxf(0.0, _get_precise_clock_time() - _start_time_sec)
	_pointer_angle_deg = elapsed * pointer_speed_deg
	queue_redraw()
	
	var max_angle_deg: float = max_revolutions * 360.0
	if _pointer_angle_deg >= max_angle_deg:
		_pointer_angle_deg = max_angle_deg
		_complete_wheel_attack()

func _unhandled_input(event: InputEvent) -> void:
	if not _is_spinning:
		return
	
	if _is_space_pressed(event):
		get_viewport().set_input_as_handled()
		_handle_space_press()

func _is_space_pressed(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_ev: InputEventKey = event as InputEventKey
		if key_ev.pressed and not key_ev.is_echo():
			if key_ev.keycode == KEY_SPACE or key_ev.physical_keycode == KEY_SPACE:
				return true
	return false

func _handle_space_press() -> void:
	if not _is_spinning or _selected_runes.size() >= MAX_SELECTIONS:
		return
	
	var current_rune: int = get_current_pointed_rune()
	if _selected_runes.has(current_rune):
		if _status_label != null:
			_status_label.text = "Руна #" + str(current_rune) + " уже активирована!"
			_status_label.modulate = Color(1.0, 0.55, 0.35, 1.0)
		return
	
	_selected_runes.append(current_rune)
	var is_prio: bool = _priority_runes.has(current_rune)
	
	if _status_label != null:
		if is_prio:
			_status_label.text = "★ Приоритетная руна #" + str(current_rune) + "! ★"
			_status_label.modulate = Color(0.35, 1.0, 0.55, 1.0)
		else:
			_status_label.text = "Руна #" + str(current_rune) + " (обычная)"
			_status_label.modulate = Color(0.55, 0.85, 1.0, 1.0)
	
	_update_number_label_colors()
	_update_slots_display()
	queue_redraw()
	
	rune_activated.emit(current_rune, is_prio, _selected_runes.size())
	
	if _selected_runes.size() >= MAX_SELECTIONS:
		_complete_wheel_attack()

## Возвращает номер руны (1..10), на которую сейчас указывает стрелка (по часовой от 12 часов)
func get_current_pointed_rune() -> int:
	var wrapped_deg: float = fposmod(_pointer_angle_deg, 360.0)
	var index: int = int(floor(wrapped_deg / SECTOR_ANGLE_DEG)) % TOTAL_RUNES
	return index + 1

func _complete_wheel_attack() -> void:
	if not _is_spinning:
		return
	
	_is_spinning = false
	queue_redraw()
	
	var eval_result: Dictionary = {}
	if _current_attack != null:
		eval_result = _current_attack.evaluate_selected_runes(_selected_runes)
	else:
		eval_result = {
			"priority_hits": 0,
			"normal_hits": _selected_runes.size(),
			"total_hits": _selected_runes.size(),
			"damage_multiplier": float(_selected_runes.size()) * 0.3,
			"grade_text": "АТАКА ЗАВЕРШЕНА"
		}
	
	if _status_label != null:
		_status_label.text = str(eval_result.get("grade_text", ""))
	
	await get_tree().create_timer(0.55).timeout
	
	if _status_label != null:
		_status_label.text = ""
	if _slots_label != null:
		_slots_label.text = ""
	
	var final_runes: Array[int] = _selected_runes.duplicate()
	_selected_runes.clear()
	_update_number_label_colors()
	queue_redraw()
	
	wheel_attack_finished.emit(final_runes, eval_result)

## Синхронизация времени через системные часы + AudioServer согласно требованиям проекта
func _get_precise_clock_time() -> float:
	var sys_sec: float = float(Time.get_ticks_usec()) / 1000000.0
	var mix_offset: float = AudioServer.get_time_since_last_mix()
	return sys_sec + clampf(mix_offset, 0.0, 0.05)

func _setup_wheel_sprite() -> void:
	_wheel_sprite = Sprite2D.new()
	_wheel_sprite.name = "RunesSprite"
	_wheel_sprite.z_index = 1
	_wheel_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if ResourceLoader.exists(RUNES_TEXTURE_PATH):
		var tex: Texture2D = load(RUNES_TEXTURE_PATH) as Texture2D
		if tex != null:
			_wheel_sprite.texture = tex
			var tex_size: Vector2 = tex.get_size()
			if tex_size.x > 0.0:
				var target_diameter: float = wheel_radius * 2.0
				_wheel_sprite.scale = Vector2(target_diameter / tex_size.x, target_diameter / tex_size.y)
	add_child(_wheel_sprite)
	
	_pointer_overlay = Node2D.new()
	_pointer_overlay.name = "PointerOverlay"
	_pointer_overlay.z_index = 4
	_pointer_overlay.draw.connect(_draw_pointer_overlay)
	add_child(_pointer_overlay)

func _setup_rune_number_labels() -> void:
	_number_labels.clear()
	# Размещаем номера рун 1..10 во внутреннем кольце каждого сектора
	var label_radius: float = wheel_radius * 0.49
	for i: int in range(TOTAL_RUNES):
		var rune_num: int = i + 1
		var center_deg_cw: float = float(i) * SECTOR_ANGLE_DEG + (SECTOR_ANGLE_DEG * 0.5)
		var rad: float = deg_to_rad(center_deg_cw - 90.0)
		var pos: Vector2 = Vector2(cos(rad), sin(rad)) * label_radius
		
		var lbl: Label = Label.new()
		lbl.name = "RuneNumber_%d" % rune_num
		lbl.z_index = 2
		lbl.text = str(rune_num)
		lbl.size = Vector2(24.0, 16.0)
		lbl.position = pos - (lbl.size / 2.0)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.15, 0.14, 0.18, 1.0))
		add_child(lbl)
		_number_labels.append(lbl)
	
	_update_number_label_colors()

func _setup_hud_labels() -> void:
	_slots_label = Label.new()
	_slots_label.name = "RuneSlotsLabel"
	_slots_label.z_index = 5
	_slots_label.position = Vector2(-120.0, -wheel_radius - 20.0)
	_slots_label.size = Vector2(240.0, 18.0)
	_slots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slots_label.add_theme_font_size_override("font_size", 11)
	_slots_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7, 1.0))
	add_child(_slots_label)
	
	_status_label = Label.new()
	_status_label.name = "RuneStatusLabel"
	_status_label.z_index = 5
	_status_label.position = Vector2(-160.0, wheel_radius + 2.0)
	_status_label.size = Vector2(320.0, 18.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 11)
	add_child(_status_label)

func _update_slots_display() -> void:
	if _slots_label == null:
		return
	var picked_strs: PackedStringArray = PackedStringArray()
	for r: int in _selected_runes:
		picked_strs.append("#" + str(r))
	var picked_text: String = ", ".join(picked_strs) if not picked_strs.is_empty() else "нет"
	_slots_label.text = "Руны: %d/%d (%s)" % [_selected_runes.size(), MAX_SELECTIONS, picked_text]

func _update_number_label_colors() -> void:
	for i: int in range(_number_labels.size()):
		var rune_num: int = i + 1
		var lbl: Label = _number_labels[i]
		if _selected_runes.has(rune_num):
			lbl.add_theme_color_override("font_color", Color(0.05, 0.35, 0.12, 1.0))
		elif _priority_runes.has(rune_num):
			lbl.add_theme_color_override("font_color", Color(0.55, 0.22, 0.02, 1.0))
		else:
			lbl.add_theme_color_override("font_color", Color(0.18, 0.18, 0.24, 0.95))

func _draw() -> void:
	# 1. Светлая каменная подложка под прозрачный спрайт колеса, чтобы темные линии рун четко читались
	draw_circle(Vector2.ZERO, wheel_radius * 0.99, Color(0.82, 0.79, 0.72, 0.94))
	draw_circle(Vector2.ZERO, wheel_radius * 0.31, Color(0.74, 0.70, 0.62, 0.96))
	
	var pointed_rune: int = get_current_pointed_rune() if _is_spinning else -1
	
	# 2. Подсветка секторов (приоритетные руны, выбранные руны и текущий сектор под стрелкой)
	for i: int in range(TOTAL_RUNES):
		var rune_num: int = i + 1
		var start_deg_cw: float = float(i) * SECTOR_ANGLE_DEG
		var end_deg_cw: float = start_deg_cw + SECTOR_ANGLE_DEG
		
		var is_selected: bool = _selected_runes.has(rune_num)
		var is_priority: bool = _priority_runes.has(rune_num)
		var is_pointed: bool = (rune_num == pointed_rune)
		
		if is_selected:
			var sel_col: Color = Color(0.25, 0.92, 0.45, 0.65) if is_priority else Color(0.35, 0.75, 0.95, 0.60)
			_draw_ring_sector(start_deg_cw, end_deg_cw, wheel_radius * 0.33, wheel_radius * 0.96, sel_col)
		elif is_priority:
			var prio_alpha: float = 0.58 if is_pointed else 0.38
			_draw_ring_sector(start_deg_cw, end_deg_cw, wheel_radius * 0.33, wheel_radius * 0.96, Color(1.0, 0.80, 0.20, prio_alpha))
		elif is_pointed:
			_draw_ring_sector(start_deg_cw, end_deg_cw, wheel_radius * 0.33, wheel_radius * 0.96, Color(1.0, 1.0, 1.0, 0.35))
	
	if _pointer_overlay != null:
		_pointer_overlay.queue_redraw()

func _draw_pointer_overlay() -> void:
	if _pointer_overlay == null:
		return
	var arrow_deg_cw: float = _pointer_angle_deg if _is_spinning else 0.0
	var arrow_rad: float = deg_to_rad(arrow_deg_cw - 90.0)
	var dir: Vector2 = Vector2(cos(arrow_rad), sin(arrow_rad))
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	
	var arrow_len: float = wheel_radius * 0.88
	var tip: Vector2 = dir * arrow_len
	var base_left: Vector2 = dir * 10.0 + perp * 5.0
	var base_right: Vector2 = dir * 10.0 - perp * 5.0
	
	var arrow_color: Color = Color(0.95, 0.22, 0.18, 1.0) if _is_spinning else Color(0.45, 0.25, 0.22, 0.85)
	var arrow_poly: PackedVector2Array = PackedVector2Array([base_left, tip, base_right])
	_pointer_overlay.draw_colored_polygon(arrow_poly, arrow_color)
	_pointer_overlay.draw_polyline(PackedVector2Array([base_left, tip, base_right, base_left]), Color(0.15, 0.05, 0.05, 1.0), 1.5)
	
	# Центральная втулка стрелки
	_pointer_overlay.draw_circle(Vector2.ZERO, 8.0, Color(0.22, 0.18, 0.16, 1.0))
	_pointer_overlay.draw_circle(Vector2.ZERO, 4.5, Color(0.92, 0.78, 0.32, 1.0))

func _draw_ring_sector(start_deg_cw: float, end_deg_cw: float, r_inner: float, r_outer: float, color: Color) -> void:
	var steps: int = 8
	var poly: PackedVector2Array = PackedVector2Array()
	for s: int in range(steps + 1):
		var t: float = float(s) / float(steps)
		var a_rad: float = deg_to_rad(lerpf(start_deg_cw, end_deg_cw, t) - 90.0)
		poly.append(Vector2(cos(a_rad), sin(a_rad)) * r_outer)
	for s: int in range(steps, -1, -1):
		var t: float = float(s) / float(steps)
		var a_rad: float = deg_to_rad(lerpf(start_deg_cw, end_deg_cw, t) - 90.0)
		poly.append(Vector2(cos(a_rad), sin(a_rad)) * r_inner)
	draw_colored_polygon(poly, color)
