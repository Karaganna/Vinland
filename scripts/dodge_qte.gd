# res://scripts/dodge_qte.gd
class_name DodgeQTE
extends Control

## Сигнал окончания QTE уклонения
## is_success: удалось ли избежать гибели (true/false)
## score_ratio: точность нажатий (0.0 .. 1.0)
## grade_text: текстовая оценка ("★ ЧИСТЫЙ УКЛОН! ★", "СКОЛЬЗЯЩИЙ УКЛОН!", "ПРОВАЛ!")
signal dodge_completed(is_success: bool, score_ratio: float, grade_text: String)

## Состояния карточек стрелок
enum CardState {
	PENDING,
	ACTIVE,
	SUCCESS,
	FAILED
}

## Настройки и состояние
var _sequence: Array[String] = []
var _card_nodes: Array[PanelContainer] = []
var _symbol_labels: Array[Label] = []
var _text_labels: Array[Label] = []

var _current_index: int = 0
var _success_count: int = 0
var _time_limit: float = 2.4
var _time_left: float = 2.4
var _is_active: bool = false
var _active_pulse_tween: Tween = null
var _warning_pulse_tween: Tween = null

## Элементы интерфейса
var _main_panel: PanelContainer = null
var _timer_bar: ProgressBar = null
var _timer_fill_style: StyleBoxFlat = null
var _prompt_label: Label = null
var _title_label: Label = null

func _ready() -> void:
	custom_minimum_size = Vector2(640.0, 360.0)
	size = Vector2(640.0, 360.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not _is_active:
		return
	
	_time_left -= delta
	if _timer_bar != null:
		_timer_bar.value = max(0.0, _time_left)
		
		# Экстренная полоса времени (Ярко-оранжевый -> Тревожно-красный)
		var progress: float = _time_left / _time_limit
		if _timer_fill_style != null:
			_timer_fill_style.bg_color = Color(1.0, 0.3, 0.2, 1.0).lerp(
				Color(1.0, 0.75, 0.2, 1.0),
				progress
			)
	
	if _time_left <= 0.0:
		_time_left = 0.0
		_on_time_expired()

func _unhandled_input(event: InputEvent) -> void:
	if not _is_active:
		return
	
	if not (event is InputEventKey):
		return
	
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.is_echo():
		return
	
	var pressed_arrow: String = _get_arrow_input(key_event)
	if pressed_arrow.is_empty():
		return
	
	get_viewport().set_input_as_handled()
	_process_arrow_input(pressed_arrow)

## Запуск QTE уклонения
func start_qte(arrow_count: int = 3, duration: float = 2.4) -> void:
	_sequence = _generate_arrow_sequence(arrow_count)
	_time_limit = duration
	_time_left = duration
	_current_index = 0
	_success_count = 0
	
	_build_ui()
	
	_is_active = true
	_set_card_state(0, CardState.ACTIVE)

## Генерация разнообразной последовательности стрелок
func _generate_arrow_sequence(count: int) -> Array[String]:
	var all_arrows: Array[String] = ["UP", "DOWN", "LEFT", "RIGHT"]
	var result: Array[String] = []
	var prev: String = ""
	
	for i in range(count):
		var candidates: Array[String] = all_arrows.filter(func(a: String) -> bool: return a != prev)
		var picked: String = candidates.pick_random()
		result.append(picked)
		prev = picked
	
	return result

## Обработка нажатия стрелки
func _process_arrow_input(pressed_arrow: String) -> void:
	if not _is_active or _current_index >= _sequence.size():
		return
	
	var target_arrow: String = _sequence[_current_index]
	var is_correct: bool = (pressed_arrow == target_arrow)
	
	if is_correct:
		_success_count += 1
		_set_card_state(_current_index, CardState.SUCCESS)
		_prompt_label.text = "Уворот! [" + _get_symbol_for_arrow(pressed_arrow) + "]"
		_prompt_label.modulate = Color(0.3, 1.0, 0.6, 1.0)
	else:
		_set_card_state(_current_index, CardState.FAILED)
		_prompt_label.text = "Не туда! Нажато [" + _get_symbol_for_arrow(pressed_arrow) + "], нужно [" + _get_symbol_for_arrow(target_arrow) + "]"
		_prompt_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
	
	_current_index += 1
	
	if _current_index < _sequence.size():
		_set_card_state(_current_index, CardState.ACTIVE)
	else:
		_finish_qte()

## Истечение времени на уклонение
func _on_time_expired() -> void:
	_finish_qte()

## Завершение QTE уклонения
func _finish_qte() -> void:
	if not _is_active:
		return
	
	_is_active = false
	_stop_active_pulse()
	_stop_warning_pulse()
	
	# Неуспевшие стрелки отмечаем как провал
	for i in range(_current_index, _sequence.size()):
		_set_card_state(i, CardState.FAILED)
	
	var total: int = _sequence.size()
	var ratio: float = float(_success_count) / float(max(1, total))
	
	var is_success: bool = false
	var grade_text: String = ""
	var result_color: Color = Color.WHITE
	
	if ratio >= 0.99:
		is_success = true
		grade_text = "★ ЧИСТЫЙ УКЛОН! ★"
		result_color = Color(0.3, 1.0, 0.6, 1.0) # Зеленый
	elif ratio >= 0.6:
		is_success = true
		grade_text = "СКОЛЬЗЯЩИЙ УКЛОН!"
		result_color = Color(1.0, 0.85, 0.25, 1.0) # Золотисто-желтый
	else:
		is_success = false
		grade_text = "УКЛОНЕНИЕ ПРОВАЛЕНО!"
		result_color = Color(1.0, 0.25, 0.25, 1.0) # Красный
	
	_prompt_label.text = grade_text
	_prompt_label.modulate = result_color
	
	# Пульсация результата
	_prompt_label.pivot_offset = _prompt_label.size / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(_prompt_label, "scale", Vector2(1.15, 1.15), 0.12)
	tween.tween_property(_prompt_label, "scale", Vector2.ONE, 0.12)
	
	await get_tree().create_timer(0.6).timeout
	
	var fade_tween: Tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await fade_tween.finished
	
	dodge_completed.emit(is_success, ratio, grade_text)
	queue_free()

## Считывание стрелок (с поддержкой стрелок клавиатуры и дублирующих WASD)
func _get_arrow_input(key_event: InputEventKey) -> String:
	# 1. Физические сканкоды стрелок
	var phys: Key = key_event.physical_keycode
	if phys == KEY_UP: return "UP"
	if phys == KEY_DOWN: return "DOWN"
	if phys == KEY_LEFT: return "LEFT"
	if phys == KEY_RIGHT: return "RIGHT"
	
	# 2. Логические сканкоды стрелок
	var code: Key = key_event.keycode
	if code == KEY_UP: return "UP"
	if code == KEY_DOWN: return "DOWN"
	if code == KEY_LEFT: return "LEFT"
	if code == KEY_RIGHT: return "RIGHT"
	
	# 3. Дублирующий ввод WASD (для клавиатур без выделенного блока стрелок)
	if phys == KEY_W or code == KEY_W: return "UP"
	if phys == KEY_S or code == KEY_S: return "DOWN"
	if phys == KEY_A or code == KEY_A: return "LEFT"
	if phys == KEY_D or code == KEY_D: return "RIGHT"
	
	# 4. Кириллические аналоги WASD (Ц, Ы, Ф, В)
	if key_event.unicode > 0:
		var u_char: String = String.chr(key_event.unicode).to_upper()
		if u_char == "Ц": return "UP"
		if u_char == "Ы": return "DOWN"
		if u_char == "Ф": return "LEFT"
		if u_char == "В": return "RIGHT"
	
	return ""

## Отображение символа стрелки
func _get_symbol_for_arrow(arrow: String) -> String:
	match arrow:
		"UP": return "▲"
		"DOWN": return "▼"
		"LEFT": return "◄"
		"RIGHT": return "►"
		_: return "•"

## Отображение подписи стрелки
func _get_text_for_arrow(arrow: String) -> String:
	match arrow:
		"UP": return "ВВЕРХ"
		"DOWN": return "ВНИЗ"
		"LEFT": return "ВЛЕВО"
		"RIGHT": return "ВПРАВО"
		_: return ""

## Построение интерфейса тревожного окна уклонения
func _build_ui() -> void:
	_main_panel = PanelContainer.new()
	_main_panel.name = "DodgePanel"
	_main_panel.position = Vector2(170.0, 48.0)
	_main_panel.size = Vector2(300.0, 142.0)
	_main_panel.custom_minimum_size = Vector2(300.0, 142.0)
	
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.14, 0.07, 0.09, 0.96) # Темно-бордовый тревожный фон
	panel_style.border_color = Color(0.95, 0.25, 0.25, 1.0) # Ярко-красная тревожная рамка
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel_style.content_margin_top = 8.0
	panel_style.content_margin_bottom = 8.0
	panel_style.content_margin_left = 12.0
	panel_style.content_margin_right = 12.0
	_main_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_main_panel)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	_main_panel.add_child(vbox)
	
	# Тревожный заголовок
	_title_label = Label.new()
	_title_label.text = "⚠ СМЕРТЕЛЬНЫЙ УДАР! УКЛОНЕНИЕ ⚠"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 12)
	_title_label.modulate = Color(1.0, 0.35, 0.35, 1.0)
	vbox.add_child(_title_label)
	
	# Контейнер карточек стрелок
	var cards_container: HBoxContainer = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 12)
	vbox.add_child(cards_container)
	
	_card_nodes.clear()
	_symbol_labels.clear()
	_text_labels.clear()
	
	for i in range(_sequence.size()):
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(62.0, 50.0)
		
		var card_vbox: VBoxContainer = VBoxContainer.new()
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_vbox.add_theme_constant_override("separation", 1)
		card.add_child(card_vbox)
		
		var sym_lbl: Label = Label.new()
		sym_lbl.text = _get_symbol_for_arrow(_sequence[i])
		sym_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sym_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sym_lbl.add_theme_font_size_override("font_size", 18)
		card_vbox.add_child(sym_lbl)
		
		var txt_lbl: Label = Label.new()
		txt_lbl.text = _get_text_for_arrow(_sequence[i])
		txt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		txt_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		txt_lbl.add_theme_font_size_override("font_size", 10)
		txt_lbl.modulate = Color(0.8, 0.7, 0.7, 0.8)
		card_vbox.add_child(txt_lbl)
		
		_card_nodes.append(card)
		_symbol_labels.append(sym_lbl)
		_text_labels.append(txt_lbl)
		cards_container.add_child(card)
		
		_set_card_state(i, CardState.PENDING)
	
	# Полоса оставшегося времени
	_timer_bar = ProgressBar.new()
	_timer_bar.min_value = 0.0
	_timer_bar.max_value = _time_limit
	_timer_bar.value = _time_left
	_timer_bar.show_percentage = false
	_timer_bar.custom_minimum_size = Vector2(230.0, 6.0)
	_timer_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var bg_bar_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_bar_style.bg_color = Color(0.18, 0.10, 0.12, 1.0)
	bg_bar_style.set_corner_radius_all(2)
	_timer_bar.add_theme_stylebox_override("background", bg_bar_style)
	
	_timer_fill_style = StyleBoxFlat.new()
	_timer_fill_style.bg_color = Color(1.0, 0.35, 0.25, 1.0)
	_timer_fill_style.set_corner_radius_all(2)
	_timer_bar.add_theme_stylebox_override("fill", _timer_fill_style)
	vbox.add_child(_timer_bar)
	
	# Подсказка
	_prompt_label = Label.new()
	_prompt_label.text = "Нажимайте СТРЕЛКИ на клавиатуре!"
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 11)
	_prompt_label.modulate = Color(1.0, 0.9, 0.7, 0.95)
	vbox.add_child(_prompt_label)
	
	# Анимация появления с пульсацией тревоги
	_main_panel.modulate.a = 0.0
	_main_panel.scale = Vector2(0.92, 0.92)
	_main_panel.pivot_offset = _main_panel.size / 2.0
	var appear_tween: Tween = create_tween().set_parallel(true)
	appear_tween.tween_property(_main_panel, "modulate:a", 1.0, 0.15)
	appear_tween.tween_property(_main_panel, "scale", Vector2.ONE, 0.15)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	_start_warning_pulse()

## Визуальное обновление карточки стрелки
func _set_card_state(index: int, state: CardState) -> void:
	if index < 0 or index >= _card_nodes.size():
		return
	
	var card: PanelContainer = _card_nodes[index]
	var sym_lbl: Label = _symbol_labels[index]
	var txt_lbl: Label = _text_labels[index]
	
	match state:
		CardState.PENDING:
			card.add_theme_stylebox_override(
				"panel",
				_create_card_style(Color(0.20, 0.10, 0.12, 1.0), Color(0.45, 0.22, 0.25, 1.0))
			)
			card.modulate = Color(0.8, 0.7, 0.7, 0.7)
			sym_lbl.modulate = Color.WHITE
			txt_lbl.modulate = Color(0.7, 0.65, 0.65, 0.8)
			sym_lbl.text = _get_symbol_for_arrow(_sequence[index])
			txt_lbl.text = _get_text_for_arrow(_sequence[index])
		
		CardState.ACTIVE:
			card.add_theme_stylebox_override(
				"panel",
				_create_card_style(Color(0.35, 0.20, 0.08, 1.0), Color(1.0, 0.85, 0.25, 1.0))
			)
			card.modulate = Color.WHITE
			sym_lbl.modulate = Color(1.0, 0.95, 0.4, 1.0)
			txt_lbl.modulate = Color(1.0, 0.85, 0.3, 1.0)
			sym_lbl.text = _get_symbol_for_arrow(_sequence[index])
			txt_lbl.text = _get_text_for_arrow(_sequence[index])
			_start_active_pulse(card)
		
		CardState.SUCCESS:
			_stop_active_pulse()
			card.add_theme_stylebox_override(
				"panel",
				_create_card_style(Color(0.12, 0.35, 0.18, 1.0), Color(0.35, 0.95, 0.5, 1.0))
			)
			card.modulate = Color.WHITE
			sym_lbl.modulate = Color(0.4, 1.0, 0.6, 1.0)
			txt_lbl.modulate = Color(0.4, 1.0, 0.6, 1.0)
			sym_lbl.text = "✔"
			_play_pop_effect(card)
		
		CardState.FAILED:
			_stop_active_pulse()
			card.add_theme_stylebox_override(
				"panel",
				_create_card_style(Color(0.42, 0.12, 0.12, 1.0), Color(1.0, 0.25, 0.25, 1.0))
			)
			card.modulate = Color.WHITE
			sym_lbl.modulate = Color(1.0, 0.4, 0.4, 1.0)
			txt_lbl.modulate = Color(1.0, 0.3, 0.3, 1.0)
			sym_lbl.text = "✘"
			_play_shake_effect(card)

func _create_card_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	return style

## Пульсация тревоги на рамке окна
func _start_warning_pulse() -> void:
	_stop_warning_pulse()
	if _title_label == null:
		return
	_warning_pulse_tween = create_tween().set_loops()
	_warning_pulse_tween.tween_property(_title_label, "modulate:a", 0.4, 0.25)
	_warning_pulse_tween.tween_property(_title_label, "modulate:a", 1.0, 0.25)

func _stop_warning_pulse() -> void:
	if _warning_pulse_tween != null and _warning_pulse_tween.is_valid():
		_warning_pulse_tween.kill()
		_warning_pulse_tween = null

func _start_active_pulse(card: Control) -> void:
	_stop_active_pulse()
	card.pivot_offset = card.size / 2.0
	_active_pulse_tween = create_tween().set_loops()
	_active_pulse_tween.tween_property(card, "scale", Vector2(1.08, 1.08), 0.2)
	_active_pulse_tween.tween_property(card, "scale", Vector2.ONE, 0.2)

func _stop_active_pulse() -> void:
	if _active_pulse_tween != null and _active_pulse_tween.is_valid():
		_active_pulse_tween.kill()
		_active_pulse_tween = null
	if _current_index >= 0 and _current_index < _card_nodes.size():
		_card_nodes[_current_index].scale = Vector2.ONE
		_card_nodes[_current_index].rotation = 0.0

func _play_pop_effect(card: Control) -> void:
	card.pivot_offset = card.size / 2.0
	var pop_tween: Tween = create_tween()
	pop_tween.tween_property(card, "scale", Vector2(1.18, 1.18), 0.08)
	pop_tween.tween_property(card, "scale", Vector2.ONE, 0.12)

func _play_shake_effect(card: Control) -> void:
	card.pivot_offset = card.size / 2.0
	var shake_tween: Tween = create_tween()
	shake_tween.tween_property(card, "rotation", deg_to_rad(-6.0), 0.04)
	shake_tween.tween_property(card, "rotation", deg_to_rad(6.0), 0.04)
	shake_tween.tween_property(card, "rotation", deg_to_rad(-4.0), 0.04)
	shake_tween.tween_property(card, "rotation", 0.0, 0.04)
