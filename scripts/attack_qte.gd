# res://scripts/attack_qte.gd
class_name AttackQTE
extends Control

## Сигнал окончания QTE атаки
## score_ratio: доля успешных нажатий (0.0 .. 1.0)
## grade_text: текстовая оценка ("★ ИДЕАЛЬНО! ★", "ХОРОШО!", "СЛАБО", "ПЛОХО", "ПРОМАХ!")
## damage_multiplier: множитель урона (1.3, 1.0, 0.6, 0.3, 0.0)
signal qte_completed(score_ratio: float, grade_text: String, damage_multiplier: float)

## Состояния карточек клавиш
enum CardState {
	PENDING,
	ACTIVE,
	SUCCESS,
	FAILED
}

## Статический счетчик атак для плавной кривой обучения:
## 1-я атака всегда базовый порядок [W, A, S, D], далее перемешивается
static var _total_qte_count: int = 0

## Настройки и состояние
var _sequence: Array[String] = []
var _card_nodes: Array[PanelContainer] = []
var _letter_labels: Array[Label] = []
var _arrow_labels: Array[Label] = []

var _current_index: int = 0
var _success_count: int = 0
var _time_limit: float = 3.0
var _time_left: float = 3.0
var _is_active: bool = false
var _active_pulse_tween: Tween = null

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
		
		# Плавное изменение цвета полосы времени (Голубой -> Желтый -> Красный)
		var progress: float = _time_left / _time_limit
		if _timer_fill_style != null:
			if progress > 0.5:
				_timer_fill_style.bg_color = Color(0.3, 0.85, 1.0, 1.0).lerp(
					Color(1.0, 0.85, 0.2, 1.0),
					(1.0 - progress) * 2.0
				)
			else:
				_timer_fill_style.bg_color = Color(1.0, 0.85, 0.2, 1.0).lerp(
					Color(1.0, 0.25, 0.25, 1.0),
					(0.5 - progress) * 2.0
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
	
	var pressed_key: String = _get_key_as_string(key_event)
	if pressed_key.is_empty():
		return
	
	get_viewport().set_input_as_handled()
	_process_key_input(pressed_key)

## Запуск QTE с настраиваемой последовательностью и таймером
func start_qte(custom_sequence: Array[String] = [], duration: float = 3.0) -> void:
	if not custom_sequence.is_empty():
		_sequence = custom_sequence.duplicate()
	else:
		_sequence = _generate_wasd_sequence()
	
	_time_limit = duration
	_time_left = duration
	_current_index = 0
	_success_count = 0
	
	_build_ui()
	
	_is_active = true
	_set_card_state(0, CardState.ACTIVE)

## Генерация последовательности клавиш WASD
func _generate_wasd_sequence() -> Array[String]:
	_total_qte_count += 1
	var base_keys: Array[String] = ["W", "A", "S", "D"]
	
	# Первая атака всегда каноничный порядок [W, A, S, D]
	if _total_qte_count == 1:
		return ["W", "A", "S", "D"]
	
	# Последующие атаки перемешивают последовательность, требуя внимательности
	var shuffled: Array[String] = base_keys.duplicate()
	shuffled.shuffle()
	return shuffled

## Обработка ввода определенной клавиши
func _process_key_input(pressed_key: String) -> void:
	if not _is_active or _current_index >= _sequence.size():
		return
	
	var target_key: String = _sequence[_current_index]
	var is_correct: bool = (pressed_key == target_key)
	
	if is_correct:
		_success_count += 1
		_set_card_state(_current_index, CardState.SUCCESS)
		_prompt_label.text = "Точно! [" + pressed_key + "]"
		_prompt_label.modulate = Color(0.4, 1.0, 0.5, 1.0)
	else:
		_set_card_state(_current_index, CardState.FAILED)
		_prompt_label.text = "Мимо! Нажата [" + pressed_key + "], требовалась [" + target_key + "]"
		_prompt_label.modulate = Color(1.0, 0.35, 0.35, 1.0)
	
	_current_index += 1
	
	if _current_index < _sequence.size():
		_set_card_state(_current_index, CardState.ACTIVE)
	else:
		_finish_qte()

## Истечение лимита времени
func _on_time_expired() -> void:
	_finish_qte()

## Завершение QTE и расчет результата
func _finish_qte() -> void:
	if not _is_active:
		return
	
	_is_active = false
	_stop_active_pulse()
	
	# Все оставшиеся клавиши помечаем как невыполненные
	for i in range(_current_index, _sequence.size()):
		_set_card_state(i, CardState.FAILED)
	
	var total: int = _sequence.size()
	var ratio: float = float(_success_count) / float(max(1, total))
	
	var grade_text: String = ""
	var damage_multiplier: float = 1.0
	var result_color: Color = Color.WHITE
	
	if ratio >= 0.99:
		grade_text = "★ ИДЕАЛЬНО! ★"
		damage_multiplier = 1.3
		result_color = Color(1.0, 0.88, 0.2, 1.0)
	elif ratio >= 0.74:
		grade_text = "ХОРОШО!"
		damage_multiplier = 1.0
		result_color = Color(0.35, 0.95, 0.5, 1.0)
	elif ratio >= 0.49:
		grade_text = "СЛАБО"
		damage_multiplier = 0.6
		result_color = Color(1.0, 0.7, 0.25, 1.0)
	elif ratio >= 0.24:
		grade_text = "ПЛОХО"
		damage_multiplier = 0.3
		result_color = Color(1.0, 0.4, 0.4, 1.0)
	else:
		grade_text = "ПРОМАХ!"
		damage_multiplier = 0.0
		result_color = Color(0.9, 0.25, 0.25, 1.0)
	
	_prompt_label.text = grade_text + " (x" + str(snapped(damage_multiplier, 0.1)) + ")"
	_prompt_label.modulate = result_color
	
	# Анимация подтверждения оценки
	_prompt_label.pivot_offset = _prompt_label.size / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(_prompt_label, "scale", Vector2(1.15, 1.15), 0.12)
	tween.tween_property(_prompt_label, "scale", Vector2(1.0, 1.0), 0.12)
	
	await get_tree().create_timer(0.65).timeout
	
	# Плавное исчезновение окна QTE
	var fade_tween: Tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.22)
	await fade_tween.finished
	
	qte_completed.emit(ratio, grade_text, damage_multiplier)
	queue_free()

## Определение нажатой клавиши с поддержкой физических сканкодов, стрелок и кириллицы
func _get_key_as_string(key_event: InputEventKey) -> String:
	# 1. Физический сканкод (не зависит от EN/RU раскладки)
	var phys: Key = key_event.physical_keycode
	if phys == KEY_W or phys == KEY_UP:
		return "W"
	if phys == KEY_A or phys == KEY_LEFT:
		return "A"
	if phys == KEY_S or phys == KEY_DOWN:
		return "S"
	if phys == KEY_D or phys == KEY_RIGHT:
		return "D"
	
	# 2. Логический сканкод
	var code: Key = key_event.keycode
	if code == KEY_W or code == KEY_UP:
		return "W"
	if code == KEY_A or code == KEY_LEFT:
		return "A"
	if code == KEY_S or code == KEY_DOWN:
		return "S"
	if code == KEY_D or code == KEY_RIGHT:
		return "D"
	
	# 3. Кириллический ввод (Ц, Ф, Ы, В)
	if key_event.unicode > 0:
		var u_char: String = String.chr(key_event.unicode).to_upper()
		if u_char == "Ц":
			return "W"
		if u_char == "Ф":
			return "A"
		if u_char == "Ы":
			return "S"
		if u_char == "В":
			return "D"
	
	return ""

## Подсказка стрелки для клавиши
func _get_arrow_for_key(key: String) -> String:
	match key:
		"W": return "↑"
		"A": return "←"
		"S": return "↓"
		"D": return "→"
		_: return "•"

## Построение интерфейса окна QTE
func _build_ui() -> void:
	# Главная панель в центре боевой зоны (между игроком и врагом)
	_main_panel = PanelContainer.new()
	_main_panel.name = "QTEPanel"
	_main_panel.position = Vector2(170.0, 48.0)
	_main_panel.size = Vector2(300.0, 142.0)
	_main_panel.custom_minimum_size = Vector2(300.0, 142.0)
	
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.10, 0.16, 0.95)
	panel_style.border_color = Color(0.35, 0.45, 0.65, 1.0)
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
	
	# Заголовок
	_title_label = Label.new()
	_title_label.text = "⚡ БЫСТРАЯ АТАКА (QTE) ⚡"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 13)
	_title_label.modulate = Color(1.0, 0.88, 0.3, 1.0)
	vbox.add_child(_title_label)
	
	# Контейнер клавиш
	var cards_container: HBoxContainer = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 10)
	vbox.add_child(cards_container)
	
	_card_nodes.clear()
	_letter_labels.clear()
	_arrow_labels.clear()
	
	for i in range(_sequence.size()):
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(46.0, 48.0)
		
		var card_vbox: VBoxContainer = VBoxContainer.new()
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_vbox.add_theme_constant_override("separation", 1)
		card.add_child(card_vbox)
		
		var key_lbl: Label = Label.new()
		key_lbl.text = _sequence[i]
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		key_lbl.add_theme_font_size_override("font_size", 16)
		card_vbox.add_child(key_lbl)
		
		var arrow_lbl: Label = Label.new()
		arrow_lbl.text = _get_arrow_for_key(_sequence[i])
		arrow_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arrow_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		arrow_lbl.add_theme_font_size_override("font_size", 11)
		card_vbox.add_child(arrow_lbl)
		
		_card_nodes.append(card)
		_letter_labels.append(key_lbl)
		_arrow_labels.append(arrow_lbl)
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
	bg_bar_style.bg_color = Color(0.12, 0.14, 0.18, 1.0)
	bg_bar_style.set_corner_radius_all(2)
	_timer_bar.add_theme_stylebox_override("background", bg_bar_style)
	
	_timer_fill_style = StyleBoxFlat.new()
	_timer_fill_style.bg_color = Color(0.3, 0.85, 1.0, 1.0)
	_timer_fill_style.set_corner_radius_all(2)
	_timer_bar.add_theme_stylebox_override("fill", _timer_fill_style)
	vbox.add_child(_timer_bar)
	
	# Подсказка / Статус выполнения
	_prompt_label = Label.new()
	_prompt_label.text = "Нажимайте клавиши WASD по очереди!"
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 11)
	_prompt_label.modulate = Color(0.8, 0.85, 0.95, 0.9)
	vbox.add_child(_prompt_label)
	
	# Анимация плавного появления окна
	_main_panel.modulate.a = 0.0
	_main_panel.scale = Vector2(0.92, 0.92)
	_main_panel.pivot_offset = _main_panel.size / 2.0
	var appear_tween: Tween = create_tween().set_parallel(true)
	appear_tween.tween_property(_main_panel, "modulate:a", 1.0, 0.15)
	appear_tween.tween_property(_main_panel, "scale", Vector2.ONE, 0.15)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Обновление визуального стиля карточки
func _set_card_state(index: int, state: CardState) -> void:
	if index < 0 or index >= _card_nodes.size():
		return
	
	var card: PanelContainer = _card_nodes[index]
	var letter_lbl: Label = _letter_labels[index]
	var arrow_lbl: Label = _arrow_labels[index]
	
	match state:
		CardState.PENDING:
			card.add_theme_stylebox_override(
				"panel",
				_create_card_style(Color(0.12, 0.14, 0.20, 1.0), Color(0.25, 0.30, 0.42, 1.0))
			)
			card.modulate = Color(0.7, 0.75, 0.85, 0.7)
			letter_lbl.modulate = Color.WHITE
			arrow_lbl.modulate = Color(0.6, 0.65, 0.75, 0.8)
			arrow_lbl.text = _get_arrow_for_key(_sequence[index])
		
		CardState.ACTIVE:
			card.add_theme_stylebox_override(
				"panel",
				_create_card_style(Color(0.24, 0.22, 0.10, 1.0), Color(1.0, 0.88, 0.25, 1.0))
			)
			card.modulate = Color(1.0, 1.0, 1.0, 1.0)
			letter_lbl.modulate = Color(1.0, 0.95, 0.4, 1.0)
			arrow_lbl.modulate = Color(1.0, 0.85, 0.3, 1.0)
			arrow_lbl.text = _get_arrow_for_key(_sequence[index])
			_start_active_pulse(card)
		
		CardState.SUCCESS:
			_stop_active_pulse()
			card.add_theme_stylebox_override(
				"panel",
				_create_card_style(Color(0.12, 0.34, 0.16, 1.0), Color(0.35, 0.95, 0.45, 1.0))
			)
			card.modulate = Color(1.0, 1.0, 1.0, 1.0)
			letter_lbl.modulate = Color(0.5, 1.0, 0.6, 1.0)
			arrow_lbl.modulate = Color(0.4, 1.0, 0.5, 1.0)
			arrow_lbl.text = "✔"
			_play_pop_effect(card)
		
		CardState.FAILED:
			_stop_active_pulse()
			card.add_theme_stylebox_override(
				"panel",
				_create_card_style(Color(0.36, 0.12, 0.12, 1.0), Color(0.95, 0.25, 0.25, 1.0))
			)
			card.modulate = Color(1.0, 1.0, 1.0, 1.0)
			letter_lbl.modulate = Color(1.0, 0.4, 0.4, 1.0)
			arrow_lbl.modulate = Color(1.0, 0.3, 0.3, 1.0)
			arrow_lbl.text = "✘"
			_play_shake_effect(card)

## Создание стиля для карточки
func _create_card_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	return style

## Пульсирующая анимация для активной карточки
func _start_active_pulse(card: Control) -> void:
	_stop_active_pulse()
	card.pivot_offset = card.size / 2.0
	_active_pulse_tween = create_tween().set_loops()
	_active_pulse_tween.tween_property(card, "scale", Vector2(1.08, 1.08), 0.22)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_pulse_tween.tween_property(card, "scale", Vector2.ONE, 0.22)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Остановка пульсирующей анимации
func _stop_active_pulse() -> void:
	if _active_pulse_tween != null and _active_pulse_tween.is_valid():
		_active_pulse_tween.kill()
		_active_pulse_tween = null
	if _current_index >= 0 and _current_index < _card_nodes.size():
		_card_nodes[_current_index].scale = Vector2.ONE
		_card_nodes[_current_index].rotation = 0.0

## Эффект отскока при правильном нажатии
func _play_pop_effect(card: Control) -> void:
	card.pivot_offset = card.size / 2.0
	var pop_tween: Tween = create_tween()
	pop_tween.tween_property(card, "scale", Vector2(1.18, 1.18), 0.08)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(card, "scale", Vector2.ONE, 0.12)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

## Эффект встряски при ошибке
func _play_shake_effect(card: Control) -> void:
	card.pivot_offset = card.size / 2.0
	var shake_tween: Tween = create_tween()
	shake_tween.tween_property(card, "rotation", deg_to_rad(-6.0), 0.04)
	shake_tween.tween_property(card, "rotation", deg_to_rad(6.0), 0.04)
	shake_tween.tween_property(card, "rotation", deg_to_rad(-4.0), 0.04)
	shake_tween.tween_property(card, "rotation", 0.0, 0.04)
