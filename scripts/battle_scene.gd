# res://scripts/battle_scene.gd
class_name BattleScene
extends Node2D

## Сигнал продвижения диалога по нажатию кнопки действия
signal advance_pressed

## Состояния боевой системы (FSM)
enum State {
	INTRO,
	PLAYER_TURN,
	ACTION_RESOLUTION,
	ENEMY_TURN,
	VICTORY_COMBAT,
	VICTORY_VOW,
	DEFEAT
}

var current_state: State = State.INTRO

## Данные участников боя
var enemy_data: EnemyData = null
var player_max_hp: int = 100
var player_current_hp: int = 100
var player_defense_buff: bool = false
var return_world_position: Vector2 = Vector2.ZERO

## Флаги управления диалогом
var _is_waiting_for_advance: bool = false
var _prompt_tween: Tween = null

## Узлы интерфейса и визуалов
var _player_sprite: ColorRect = null
var _enemy_sprite: ColorRect = null
var _player_hp_bar: ProgressBar = null
var _enemy_hp_bar: ProgressBar = null
var _enemy_resolve_bar: ProgressBar = null
var _dialogue_label: Label = null
var _dialogue_header: Label = null
var _dialogue_prompt: Label = null

var _attack_btn: Button = null
var _vow_btn: Button = null
var _song_btn: Button = null
var _item_btn: Button = null
var _flee_btn: Button = null

func _ready() -> void:
	# Получаем данные из GameManager, если они там есть
	if GameManager.current_enemy != null:
		enemy_data = GameManager.current_enemy
		return_world_position = GameManager.saved_player_position
	elif enemy_data == null:
		_create_fallback_enemy()
	
	_build_battle_ui()
	_start_battle_intro()

func _unhandled_input(event: InputEvent) -> void:
	if not _is_waiting_for_advance:
		return
	
	if _is_advance_event(event):
		get_viewport().set_input_as_handled()
		advance_pressed.emit()

## Проверяет, является ли событие нажатием кнопки действия
func _is_advance_event(event: InputEvent) -> bool:
	if event.is_action_pressed("interact"):
		return true
	if event.is_action_pressed("ui_accept"):
		return true
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			return true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return true
	return false

## Метод инициализации при программном создании
func init_battle(enemy: EnemyData, return_pos: Vector2) -> void:
	enemy_data = enemy.clone()
	return_world_position = return_pos

func _create_fallback_enemy() -> void:
	enemy_data = EnemyData.new()
	enemy_data.enemy_name = "Теневой Скиталец"
	enemy_data.max_hp = 60
	enemy_data.current_hp = 60
	enemy_data.attack_power = 12
	enemy_data.max_resolve = 100
	enemy_data.current_resolve = 0
	enemy_data.resolve_per_vow = 35
	enemy_data.dialogue_intro = "Перед вами возникает Теневой Скиталец! Его призрачный силуэт окутан холодным туманом. Он преграждает путь."
	enemy_data.dialogue_on_attack = "Скиталец содрогается от боли. Он собирает остатки сил для ответного удара!"
	enemy_data.dialogue_on_vow = "Слова Завета проникают сквозь тьму в его сердце. Дух колеблется и вспоминает давно забытый свет."
	enemy_data.dialogue_pacified = "Скиталец обретает покой и склоняет голову. Он благословляет вас и мирно растворяется в свете."
	enemy_data.dialogue_defeat = "Теневой Скиталец рассеивается в воздухе. Бой окончен."

func _start_battle_intro() -> void:
	current_state = State.INTRO
	_set_action_buttons_enabled(false)
	
	_animate_intro()
	
	var intro_text: String = enemy_data.dialogue_intro
	if intro_text.is_empty():
		intro_text = "Перед вами возникает " + enemy_data.enemy_name + "!"
	
	await _play_dialogue_sequence("[ ВСТРЕЧА ]", intro_text)
	_enter_player_turn()

func _enter_player_turn() -> void:
	current_state = State.PLAYER_TURN
	_update_dialogue_immediate("[ ВАШ ХОД ]", "Выберите действие: атака, Завет, песнь или предмет.")
	_set_action_buttons_enabled(true)
	if _attack_btn != null and _attack_btn.is_inside_tree():
		_attack_btn.grab_focus()

func _set_action_buttons_enabled(enabled: bool) -> void:
	if _attack_btn != null: _attack_btn.disabled = not enabled
	if _vow_btn != null: _vow_btn.disabled = not enabled
	if _song_btn != null: _song_btn.disabled = not enabled
	if _item_btn != null: _item_btn.disabled = not enabled
	if _flee_btn != null: _flee_btn.disabled = not enabled

## Воспроизведение реплики по 1 предложению за нажатие кнопки действия
func _play_dialogue_sequence(header: String, full_text: String) -> void:
	var sentences: Array[String] = _split_into_sentences(full_text)
	if sentences.is_empty():
		return
	
	if _dialogue_header != null:
		_dialogue_header.text = header
	
	for sentence in sentences:
		if _dialogue_label != null:
			_dialogue_label.text = sentence
		
		_start_prompt_animation()
		await _wait_for_advance_input()
		_stop_prompt_animation()

## Ожидание нажатия кнопки действия игроком
func _wait_for_advance_input() -> void:
	_is_waiting_for_advance = true
	# Небольшая пауза для исключения случайного двойного клика
	await get_tree().create_timer(0.12).timeout
	await advance_pressed
	_is_waiting_for_advance = false

## Разбиение текста на отдельные предложения
func _split_into_sentences(text: String) -> Array[String]:
	var result: Array[String] = []
	var trimmed: String = text.strip_edges()
	if trimmed.is_empty():
		return result
	
	var current: String = ""
	var i: int = 0
	var length: int = trimmed.length()
	
	while i < length:
		var c: String = trimmed[i]
		current += c
		
		if c in [".", "!", "?"]:
			# Захватываем идущие подряд знаки препинания (например "...", "!?")
			while i + 1 < length and trimmed[i + 1] in [".", "!", "?"]:
				i += 1
				current += trimmed[i]
			
			# Захватываем закрывающие скобки или кавычки сразу после знака
			while i + 1 < length and trimmed[i + 1] in [")", "\"", "»", "”"]:
				i += 1
				current += trimmed[i]
			
			result.append(current.strip_edges())
			current = ""
			
			# Пропускаем пробелы и переносы перед следующим предложением
			while i + 1 < length and trimmed[i + 1] in [" ", "\t", "\n", "\r"]:
				i += 1
		elif c == "\n":
			if not current.strip_edges().is_empty():
				result.append(current.strip_edges())
				current = ""
		
		i += 1
	
	if not current.strip_edges().is_empty():
		result.append(current.strip_edges())
	
	return result

func _start_prompt_animation() -> void:
	if _dialogue_prompt == null:
		return
	_dialogue_prompt.visible = true
	if _prompt_tween != null and _prompt_tween.is_valid():
		_prompt_tween.kill()
	_prompt_tween = create_tween().set_loops()
	_prompt_tween.tween_property(_dialogue_prompt, "modulate:a", 0.3, 0.35)
	_prompt_tween.tween_property(_dialogue_prompt, "modulate:a", 1.0, 0.35)

func _stop_prompt_animation() -> void:
	if _prompt_tween != null and _prompt_tween.is_valid():
		_prompt_tween.kill()
	if _dialogue_prompt != null:
		_dialogue_prompt.visible = false

## Обработка действий игрока
func _on_attack_pressed() -> void:
	if current_state != State.PLAYER_TURN:
		return
	
	current_state = State.ACTION_RESOLUTION
	_set_action_buttons_enabled(false)
	
	var damage: int = 20
	enemy_data.current_hp = max(0, enemy_data.current_hp - damage)
	_update_bars()
	
	_shake_node(_enemy_sprite)
	_flash_node(_enemy_sprite, Color.WHITE)
	
	var attack_msg: String = "Вы наносите стремительный удар! " + enemy_data.enemy_name + " получает " + str(damage) + " урона."
	await _play_dialogue_sequence("[ АТАКА ]", attack_msg)
	
	# Проверка победы боем
	if enemy_data.current_hp <= 0:
		_resolve_victory_combat()
	else:
		_enter_enemy_turn()

func _on_vow_pressed() -> void:
	if current_state != State.PLAYER_TURN:
		return
	
	current_state = State.ACTION_RESOLUTION
	_set_action_buttons_enabled(false)
	
	var vow_gain: int = enemy_data.resolve_per_vow
	enemy_data.current_resolve = min(enemy_data.max_resolve, enemy_data.current_resolve + vow_gain)
	_update_bars()
	
	_flash_node(_enemy_sprite, Color(0.9, 0.85, 0.3, 1.0))
	
	var vow_msg: String = enemy_data.dialogue_on_vow
	if vow_msg.is_empty():
		vow_msg = "Вы обращаетесь со словами Завета к разуму противника."
	vow_msg += " Завет увеличился на " + str(vow_gain) + "."
	
	await _play_dialogue_sequence("[ СЛОВО ЗАВЕТА ]", vow_msg)
	
	# Проверка победы Заветом / Примирением
	if enemy_data.current_resolve >= enemy_data.max_resolve:
		_resolve_victory_vow()
	else:
		_enter_enemy_turn()

func _on_song_pressed() -> void:
	if current_state != State.PLAYER_TURN:
		return
	
	current_state = State.ACTION_RESOLUTION
	_set_action_buttons_enabled(false)
	
	player_defense_buff = true
	_flash_node(_player_sprite, Color(0.4, 0.7, 1.0, 1.0))
	
	await _play_dialogue_sequence(
		"[ ПЕСНЬ ЗАЩИТЫ ]",
		"Вы напеваете ритмичную мелодию. Входящий урон в следующем раунде снижен вдвое!"
	)
	_enter_enemy_turn()

func _on_item_pressed() -> void:
	if current_state != State.PLAYER_TURN:
		return
	
	current_state = State.ACTION_RESOLUTION
	_set_action_buttons_enabled(false)
	
	var heal: int = 30
	player_current_hp = min(player_max_hp, player_current_hp + heal)
	_update_bars()
	_flash_node(_player_sprite, Color(0.3, 1.0, 0.4, 1.0))
	
	await _play_dialogue_sequence(
		"[ ПРЕДМЕТ ]",
		"Вы используете целебное снадобье. Восстановлено " + str(heal) + " HP!"
	)
	_enter_enemy_turn()

func _on_flee_pressed() -> void:
	if current_state != State.PLAYER_TURN:
		return
	
	current_state = State.ACTION_RESOLUTION
	_set_action_buttons_enabled(false)
	
	await _play_dialogue_sequence("[ ПОБЕГ ]", "Вы благополучно отступаете назад в мир.")
	_exit_battle(false, false)

## Ход противника
func _enter_enemy_turn() -> void:
	current_state = State.ENEMY_TURN
	_set_action_buttons_enabled(false)
	
	var damage: int = enemy_data.attack_power
	if player_defense_buff:
		damage = int(round(damage / 2.0))
		player_defense_buff = false
	
	player_current_hp = max(0, player_current_hp - damage)
	_update_bars()
	
	_shake_node(_player_sprite)
	_flash_node(_player_sprite, Color(1.0, 0.2, 0.2, 1.0))
	
	var enemy_msg: String = enemy_data.dialogue_on_attack
	if enemy_msg.is_empty():
		enemy_msg = enemy_data.enemy_name + " атакует вас!"
	enemy_msg += " Нанесено " + str(damage) + " урона."
	
	await _play_dialogue_sequence("[ ХОД ВРАГА ]", enemy_msg)
	
	if player_current_hp <= 0:
		_resolve_defeat()
	else:
		_enter_player_turn()

## Разрешение исходов битвы
func _resolve_victory_combat() -> void:
	current_state = State.VICTORY_COMBAT
	
	var tween: Tween = create_tween()
	tween.tween_property(_enemy_sprite, "modulate:a", 0.0, 0.8)
	
	var victory_msg: String = enemy_data.dialogue_defeat
	if victory_msg.is_empty():
		victory_msg = enemy_data.enemy_name + " повержен в бою!"
	
	await _play_dialogue_sequence("[ ПОБЕДА ОРУЖИЕМ ]", victory_msg)
	_exit_battle(true, false)

func _resolve_victory_vow() -> void:
	current_state = State.VICTORY_VOW
	
	# Золотое свечение и вознесение в знак примирения
	var tween: Tween = create_tween()
	tween.tween_property(_enemy_sprite, "position:y", _enemy_sprite.position.y - 30.0, 0.8)
	tween.parallel().tween_property(_enemy_sprite, "modulate:a", 0.0, 0.8)
	
	var pacified_msg: String = enemy_data.dialogue_pacified
	if pacified_msg.is_empty():
		pacified_msg = "Достигнуто согласие Заветом! Враг мирно отступает."
	
	await _play_dialogue_sequence("[ ПРИМИРЕНИЕ ЗАВЕТОМ ]", pacified_msg)
	_exit_battle(true, true)

func _resolve_defeat() -> void:
	current_state = State.DEFEAT
	await _play_dialogue_sequence("[ ПОРАЖЕНИЕ ]", "Ваши силы иссякли... Возвращение в безопасное место.")
	_exit_battle(false, false)

func _exit_battle(victory: bool, by_vow: bool) -> void:
	GameManager.return_to_overworld(victory, by_vow)

## Вспомогательные анимации
func _animate_intro() -> void:
	if _player_sprite != null:
		var start_p_x: float = _player_sprite.position.x - 60.0
		var final_p_x: float = _player_sprite.position.x
		_player_sprite.position.x = start_p_x
		create_tween().tween_property(_player_sprite, "position:x", final_p_x, 0.5)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if _enemy_sprite != null:
		var start_e_x: float = _enemy_sprite.position.x + 60.0
		var final_e_x: float = _enemy_sprite.position.x
		_enemy_sprite.position.x = start_e_x
		create_tween().tween_property(_enemy_sprite, "position:x", final_e_x, 0.5)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _shake_node(node: CanvasItem) -> void:
	if node == null:
		return
	var orig_pos: Vector2 = node.position
	var tween: Tween = create_tween()
	for i in range(4):
		var offset: Vector2 = Vector2(randf_range(-4.0, 4.0), randf_range(-3.0, 3.0))
		tween.tween_property(node, "position", orig_pos + offset, 0.05)
	tween.tween_property(node, "position", orig_pos, 0.05)

func _flash_node(node: CanvasItem, flash_color: Color) -> void:
	if node == null:
		return
	var orig_mod: Color = node.modulate
	var tween: Tween = create_tween()
	tween.tween_property(node, "modulate", flash_color, 0.08)
	tween.tween_property(node, "modulate", orig_mod, 0.12)

func _update_dialogue_immediate(header: String, body: String) -> void:
	if _dialogue_header != null:
		_dialogue_header.text = header
	if _dialogue_label != null:
		_dialogue_label.text = body
	_stop_prompt_animation()

func _update_bars() -> void:
	if _player_hp_bar != null:
		_player_hp_bar.value = player_current_hp
	if _enemy_hp_bar != null:
		_enemy_hp_bar.value = enemy_data.current_hp
	if _enemy_resolve_bar != null:
		_enemy_resolve_bar.value = enemy_data.current_resolve

## Построение интерфейса и боевой сцены
func _build_battle_ui() -> void:
	# 1. Задний фон арены
	var bg: ColorRect = ColorRect.new()
	bg.name = "BattleBackground"
	bg.size = Vector2(640.0, 360.0)
	bg.color = Color(0.08, 0.09, 0.13, 1.0)
	add_child(bg)
	
	# Камера арены, центрирующая экран 640x360
	var cam: Camera2D = Camera2D.new()
	cam.position = Vector2(320.0, 180.0)
	add_child(cam)
	
	# Верхняя боевая зона (пол арены)
	var arena_floor: ColorRect = ColorRect.new()
	arena_floor.name = "ArenaFloor"
	arena_floor.position = Vector2(20.0, 20.0)
	arena_floor.size = Vector2(600.0, 200.0)
	arena_floor.color = Color(0.12, 0.14, 0.20, 1.0)
	add_child(arena_floor)
	
	# Декоративная рамка арены
	var arena_border: ReferenceRect = ReferenceRect.new()
	arena_border.position = Vector2(20.0, 20.0)
	arena_border.size = Vector2(600.0, 200.0)
	arena_border.border_color = Color(0.24, 0.28, 0.40, 1.0)
	arena_border.border_width = 2.0
	arena_border.editor_only = false
	add_child(arena_border)
	
	# 2. Игрок слева
	var player_group: Node2D = Node2D.new()
	player_group.name = "PlayerCombatant"
	player_group.position = Vector2(120.0, 80.0)
	add_child(player_group)
	
	_player_sprite = ColorRect.new()
	_player_sprite.name = "PlayerSprite"
	_player_sprite.size = Vector2(28.0, 36.0)
	_player_sprite.position = Vector2(-14.0, 0.0)
	_player_sprite.color = Color(0.85, 0.15, 0.15, 1.0)
	player_group.add_child(_player_sprite)
	
	var player_name_lbl: Label = Label.new()
	player_name_lbl.text = "ИГРОК"
	player_name_lbl.position = Vector2(-40.0, -32.0)
	player_name_lbl.size = Vector2(80.0, 16.0)
	player_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_group.add_child(player_name_lbl)
	
	_player_hp_bar = ProgressBar.new()
	_player_hp_bar.max_value = player_max_hp
	_player_hp_bar.value = player_current_hp
	_player_hp_bar.position = Vector2(-40.0, -14.0)
	_player_hp_bar.size = Vector2(80.0, 10.0)
	_player_hp_bar.show_percentage = false
	player_group.add_child(_player_hp_bar)
	
	# 3. Враг справа
	var enemy_group: Node2D = Node2D.new()
	enemy_group.name = "EnemyCombatant"
	enemy_group.position = Vector2(500.0, 70.0)
	add_child(enemy_group)
	
	_enemy_sprite = ColorRect.new()
	_enemy_sprite.name = "EnemySprite"
	_enemy_sprite.size = Vector2(36.0, 48.0)
	_enemy_sprite.position = Vector2(-18.0, 0.0)
	_enemy_sprite.color = enemy_data.sprite_color
	enemy_group.add_child(_enemy_sprite)
	
	var enemy_name_lbl: Label = Label.new()
	enemy_name_lbl.text = enemy_data.enemy_name
	enemy_name_lbl.position = Vector2(-60.0, -42.0)
	enemy_name_lbl.size = Vector2(120.0, 16.0)
	enemy_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_group.add_child(enemy_name_lbl)
	
	# Полоса HP врага
	_enemy_hp_bar = ProgressBar.new()
	_enemy_hp_bar.max_value = enemy_data.max_hp
	_enemy_hp_bar.value = enemy_data.current_hp
	_enemy_hp_bar.position = Vector2(-50.0, -24.0)
	_enemy_hp_bar.size = Vector2(100.0, 8.0)
	_enemy_hp_bar.show_percentage = false
	enemy_group.add_child(_enemy_hp_bar)
	
	# Полоса Завета / Разрешения (Resolve)
	_enemy_resolve_bar = ProgressBar.new()
	_enemy_resolve_bar.max_value = enemy_data.max_resolve
	_enemy_resolve_bar.value = enemy_data.current_resolve
	_enemy_resolve_bar.position = Vector2(-50.0, -12.0)
	_enemy_resolve_bar.size = Vector2(100.0, 6.0)
	_enemy_resolve_bar.show_percentage = false
	_enemy_resolve_bar.modulate = Color(0.9, 0.85, 0.2, 1.0) # Золотистый оттенок
	enemy_group.add_child(_enemy_resolve_bar)
	
	# 4. НИЖНЯЯ ПАНЕЛЬ ДЛЯ КНОПОК И ДИАЛОГОВ (Оставлено место снизу, Y = 230..350)
	var bottom_panel: PanelContainer = PanelContainer.new()
	bottom_panel.name = "BottomInteractionPanel"
	bottom_panel.position = Vector2(20.0, 230.0)
	bottom_panel.size = Vector2(600.0, 120.0)
	add_child(bottom_panel)
	
	var h_layout: HBoxContainer = HBoxContainer.new()
	h_layout.name = "BottomLayout"
	bottom_panel.add_child(h_layout)
	
	# Левая часть: Кнопки взаимодействия
	var actions_box: VBoxContainer = VBoxContainer.new()
	actions_box.name = "ActionsContainer"
	actions_box.custom_minimum_size = Vector2(180.0, 110.0)
	h_layout.add_child(actions_box)
	
	var actions_title: Label = Label.new()
	actions_title.text = "ДЕЙСТВИЯ:"
	actions_box.add_child(actions_title)
	
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	actions_box.add_child(grid)
	
	_attack_btn = Button.new()
	_attack_btn.text = "⚔ Атака"
	_attack_btn.pressed.connect(_on_attack_pressed)
	grid.add_child(_attack_btn)
	
	_vow_btn = Button.new()
	_vow_btn.text = "📜 Завет"
	_vow_btn.pressed.connect(_on_vow_pressed)
	grid.add_child(_vow_btn)
	
	_song_btn = Button.new()
	_song_btn.text = "🎵 Песнь"
	_song_btn.pressed.connect(_on_song_pressed)
	grid.add_child(_song_btn)
	
	_item_btn = Button.new()
	_item_btn.text = "🧪 Предмет"
	_item_btn.pressed.connect(_on_item_pressed)
	grid.add_child(_item_btn)
	
	_flee_btn = Button.new()
	_flee_btn.text = "🏃 Побег"
	_flee_btn.pressed.connect(_on_flee_pressed)
	actions_box.add_child(_flee_btn)
	
	# Разделитель
	var separator: VSeparator = VSeparator.new()
	h_layout.add_child(separator)
	
	# Правая часть: Окно диалогов и сообщений
	var dialogue_box: VBoxContainer = VBoxContainer.new()
	dialogue_box.name = "DialogueContainer"
	dialogue_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_box.gui_input.connect(
		func(event: InputEvent) -> void:
			if _is_waiting_for_advance and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				advance_pressed.emit()
	)
	h_layout.add_child(dialogue_box)
	
	_dialogue_header = Label.new()
	_dialogue_header.text = "[ ВСТРЕЧА ]"
	_dialogue_header.modulate = Color(0.9, 0.8, 0.3, 1.0)
	dialogue_box.add_child(_dialogue_header)
	
	_dialogue_label = Label.new()
	_dialogue_label.text = "Перед вами враг."
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_box.add_child(_dialogue_label)
	
	# Индикатор кнопки действия (подсказка для пропуска)
	_dialogue_prompt = Label.new()
	_dialogue_prompt.name = "DialoguePrompt"
	_dialogue_prompt.text = "▼ [E / Пробел]"
	_dialogue_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dialogue_prompt.modulate = Color(0.8, 0.85, 1.0, 0.8)
	_dialogue_prompt.visible = false
	dialogue_box.add_child(_dialogue_prompt)
