# res://scripts/battle_scene.gd
class_name BattleScene
extends Node2D

## Сигнал продвижения диалога по нажатию кнопки действия
signal advance_pressed

## Состояния боевой системы (FSM)
enum State {
	INTRO,
	PLAYER_TURN,
	ATTACK_SELECTION,
	PLAYER_ATTACK_QTE,
	ACTION_RESOLUTION,
	ENEMY_TURN,
	PLAYER_DODGE_QTE,
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

## Список доступных атак героя с приоритетными рунами
var player_attacks: Array[AttackData] = []
var _active_attack: AttackData = null

## Флаги управления диалогом
var _is_waiting_for_advance: bool = false
var _prompt_tween: Tween = null

## Узлы интерфейса и визуалов
var _player_visual: Node2D = null
var _enemy_sprite: ColorRect = null
var _rune_wheel: RuneWheel = null
var _player_hp_bar: ProgressBar = null
var _enemy_hp_bar: ProgressBar = null
var _enemy_resolve_bar: ProgressBar = null
var _dialogue_label: Label = null
var _dialogue_header: Label = null
var _dialogue_prompt: Label = null
var _attack_selection_box: VBoxContainer = null

var _attack_btn: Button = null
var _vow_btn: Button = null
var _song_btn: Button = null
var _item_btn: Button = null
var _flee_btn: Button = null

func _ready() -> void:
	if GameManager.current_enemy != null:
		enemy_data = GameManager.current_enemy
		return_world_position = GameManager.saved_player_position
	elif enemy_data == null:
		_create_fallback_enemy()
	
	player_attacks = AttackData.create_default_player_attacks()
	if not player_attacks.is_empty():
		_active_attack = player_attacks[0]
	
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
	enemy_data.dialogue_on_attack = "Скиталец содрогается от удара. Он собирает остатки сил для ответного выпадения!"
	enemy_data.dialogue_on_vow = "Слова Завета проникают сквозь тьму в его сердце. Дух колеблется и вспоминает давно забытый свет."
	enemy_data.dialogue_pacified = "Скиталец обретает покой и склоняет голову. Он благословляет вас и мирно растворяется в свете."
	enemy_data.dialogue_defeat = "Теневой Скиталец рассеивается в воздухе. Бой окончен."

func _start_battle_intro() -> void:
	current_state = State.INTRO
	_set_action_buttons_enabled(false)
	_set_attack_selection_visible(false)
	
	_animate_intro()
	
	var intro_text: String = enemy_data.dialogue_intro
	if intro_text.is_empty():
		intro_text = "Перед вами возникает " + enemy_data.enemy_name + "!"
	
	await _play_dialogue_sequence("[ ВСТРЕЧА ]", intro_text)
	_enter_player_turn()

func _enter_player_turn() -> void:
	current_state = State.PLAYER_TURN
	_set_attack_selection_visible(false)
	_update_dialogue_immediate(
		"[ ВАШ ХОД ]",
		"Выберите действие: атака, Завет, песнь или предмет."
	)
	_set_action_buttons_enabled(true)
	if _attack_btn != null and _attack_btn.is_inside_tree():
		_attack_btn.grab_focus()

func _set_action_buttons_enabled(enabled: bool) -> void:
	if _attack_btn != null: _attack_btn.disabled = not enabled
	if _vow_btn != null: _vow_btn.disabled = not enabled
	if _song_btn != null: _song_btn.disabled = not enabled
	if _item_btn != null: _item_btn.disabled = not enabled
	if _flee_btn != null: _flee_btn.disabled = not enabled

func _set_attack_selection_visible(vis: bool) -> void:
	if _attack_selection_box != null:
		_attack_selection_box.visible = vis
	if _dialogue_label != null:
		_dialogue_label.visible = not vis

## Воспроизведение реплики по 1 предложению за нажатие кнопки действия
func _play_dialogue_sequence(header: String, full_text: String) -> void:
	_set_attack_selection_visible(false)
	var sentences: Array[String] = _split_into_sentences(full_text)
	if sentences.is_empty():
		return
	
	if _dialogue_header != null:
		_dialogue_header.text = header
	
	for sentence: String in sentences:
		if _dialogue_label != null:
			_dialogue_label.text = sentence
		
		_start_prompt_animation()
		await _wait_for_advance_input()
		_stop_prompt_animation()

## Ожидание нажатия кнопки действия игроком
func _wait_for_advance_input() -> void:
	_is_waiting_for_advance = true
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
			while i + 1 < length and trimmed[i + 1] in [".", "!", "?"]:
				i += 1
				current += trimmed[i]
			
			while i + 1 < length and trimmed[i + 1] in [")", "\"", "»", "”"]:
				i += 1
				current += trimmed[i]
			
			result.append(current.strip_edges())
			current = ""
			
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

## Нажатие кнопки "Атака" — обычная атака срабатывает сразу без QTE и колеса рун
func _on_attack_pressed() -> void:
	if current_state != State.PLAYER_TURN:
		return
	
	var attack: AttackData = _active_attack
	if attack == null and not player_attacks.is_empty():
		attack = player_attacks[0]
	_execute_basic_attack(attack)

## Единая точка входа для выполнения любой атаки (обычной без QTE или особой с QTE)
func execute_attack(attack: AttackData) -> void:
	if attack != null and (attack.is_special_attack or attack.qte_mode != AttackData.QTEMode.NONE):
		_start_special_attack_qte(attack)
	else:
		_execute_basic_attack(attack)

## Выполнение обычной атаки без QTE
func _execute_basic_attack(attack: AttackData) -> void:
	current_state = State.ACTION_RESOLUTION
	_set_action_buttons_enabled(false)
	_set_attack_selection_visible(false)
	
	var used_attack: AttackData = attack if attack != null else AttackData.new()
	_active_attack = used_attack
	
	_animate_player_attack()
	
	var resist_modifier: float = enemy_data.get_damage_resistance_modifier(used_attack.category)
	var damage: int = max(0, int(round(float(used_attack.base_damage) * resist_modifier)))
	
	var attack_msg: String = ""
	if damage > 0:
		attack_msg = "Вы наносите «%s»! %s получает %d урона." % [
			used_attack.attack_name,
			enemy_data.enemy_name,
			damage
		]
	else:
		attack_msg = "Вы используете «%s», но %s не получает урона." % [
			used_attack.attack_name,
			enemy_data.enemy_name
		]
	
	await _apply_attack_damage_and_advance(damage, "[ АТАКА ]", attack_msg)

## Анимация выпада героя при обычной атаке
func _animate_player_attack() -> void:
	if _player_visual == null:
		return
	var orig_pos: Vector2 = _player_visual.position
	var tween: Tween = create_tween()
	tween.tween_property(_player_visual, "position:x", orig_pos.x + 28.0, 0.09)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_player_visual, "position:x", orig_pos.x, 0.14)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

## Общий переход в состояние QTE для особых атак
func _begin_special_attack_qte_state(attack: AttackData, header: String, body: String) -> void:
	_active_attack = attack
	current_state = State.PLAYER_ATTACK_QTE
	_set_action_buttons_enabled(false)
	_set_attack_selection_visible(false)
	
	# Снимаем фокус с UI-кнопок, чтобы нажатия клавиш QTE не активировали кнопки меню
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()
	
	_update_dialogue_immediate(header, body)

## Применяет урон от атаки игрока, обновляет интерфейс и переходит к следующему этапу боя
func _apply_attack_damage_and_advance(
	damage: int,
	header: String,
	attack_msg: String,
	flash_color: Color = Color.WHITE
) -> void:
	enemy_data.current_hp = max(0, enemy_data.current_hp - damage)
	_update_bars()
	
	if damage > 0:
		_shake_node(_enemy_sprite)
		_flash_node(_enemy_sprite, flash_color)
	
	await _play_dialogue_sequence(header, attack_msg)
	
	if enemy_data.current_hp <= 0:
		_resolve_victory_combat()
	else:
		_enter_enemy_turn()

## Запуск QTE для будущих особых атак (отвязано от обычных атак)
func _start_special_attack_qte(attack: AttackData) -> void:
	if attack == null:
		_execute_basic_attack(null)
		return
	
	match attack.qte_mode:
		AttackData.QTEMode.RUNE_WHEEL:
			_start_rune_wheel_qte(attack)
		AttackData.QTEMode.KEY_SEQUENCE:
			_start_wasd_attack_qte(attack)
		_:
			_execute_basic_attack(attack)

## Запуск Колеса Рун (спавнится временно только при особой атаке)
func _start_rune_wheel_qte(attack: AttackData) -> void:
	if attack == null:
		return
	
	if _rune_wheel != null:
		_rune_wheel.queue_free()
		_rune_wheel = null
	
	_begin_special_attack_qte_state(
		attack,
		"[ ОСОБАЯ АТАКА: " + attack.attack_name.to_upper() + " ]",
		"Стрелка вращается по часовой! Жмите [ПРОБЕЛ] на рунах (макс. 3). Приоритетные руны: " + attack.get_priority_runes_text() + "."
	)
	
	var wheel: RuneWheel = RuneWheel.new()
	wheel.name = "SpecialAttackRuneWheel"
	wheel.position = Vector2(320.0, 118.0)
	wheel.wheel_radius = 84.0
	wheel.z_index = 10
	wheel.wheel_attack_finished.connect(_on_rune_wheel_attack_finished)
	add_child(wheel)
	_rune_wheel = wheel
	wheel.start_wheel_attack(attack)

## Обработка завершения вращения Колеса Рун и освобождение временного узла
func _on_rune_wheel_attack_finished(selected_runes: Array[int], evaluation: Dictionary) -> void:
	if _rune_wheel != null:
		_rune_wheel.queue_free()
		_rune_wheel = null
	
	current_state = State.ACTION_RESOLUTION
	
	var attack: AttackData = _active_attack
	var base_damage: int = attack.base_damage if attack != null else 20
	var attack_cat: int = attack.category if attack != null else AttackData.AttackCategory.SLASH
	
	var rune_multiplier: float = float(evaluation.get("damage_multiplier", 0.0))
	var priority_hits: int = int(evaluation.get("priority_hits", 0))
	var total_hits: int = int(evaluation.get("total_hits", 0))
	var grade_text: String = str(evaluation.get("grade_text", ""))
	
	# Учет будущих уязвимостей и сопротивлений противника
	var resist_modifier: float = enemy_data.get_damage_resistance_modifier(attack_cat, selected_runes)
	var damage: int = max(0, int(round(float(base_damage) * rune_multiplier * resist_modifier)))
	
	var runes_str_arr: PackedStringArray = PackedStringArray()
	for r: int in selected_runes:
		if attack != null and attack.is_priority_rune(r):
			runes_str_arr.append("#" + str(r) + "★")
		else:
			runes_str_arr.append("#" + str(r))
	var runes_summary: String = ", ".join(runes_str_arr) if not runes_str_arr.is_empty() else "нет"
	
	var flash_color: Color = Color.WHITE
	var attack_msg: String = ""
	if damage > 0:
		if priority_hits >= 2:
			flash_color = Color(1.0, 0.9, 0.3, 1.0)
			attack_msg = grade_text + "! Активированы руны: [" + runes_summary + "]. " + enemy_data.enemy_name + " получает " + str(damage) + " урона!"
		else:
			attack_msg = grade_text + ". Активированы руны: [" + runes_summary + "] (приоритетных: " + str(priority_hits) + "/" + str(total_hits) + "). Нанесено " + str(damage) + " урона."
	else:
		attack_msg = grade_text + "! Вы не активировали ни одной руны. Удар сорвался!"
	
	await _apply_attack_damage_and_advance(damage, "[ РЕЗУЛЬТАТ ОСОБОЙ АТАКИ ]", attack_msg, flash_color)

## Запуск клавишного QTE (WASD) для будущих особых атак
func _start_wasd_attack_qte(attack: AttackData) -> void:
	if attack == null:
		return
	
	_begin_special_attack_qte_state(
		attack,
		"[ QTE ОСОБОЙ АТАКИ: " + attack.attack_name.to_upper() + " ]",
		"Приготовьтесь! Нажимайте подсвеченные клавиши на клавиатуре (WASD)."
	)
	
	var qte: AttackQTE = AttackQTE.new()
	qte.name = "AttackQTEOverlay"
	qte.qte_completed.connect(_on_attack_qte_completed)
	add_child(qte)
	qte.start_qte()

## Обработка завершения клавишного QTE особой атаки
func _on_attack_qte_completed(score_ratio: float, grade_text: String, damage_multiplier: float) -> void:
	current_state = State.ACTION_RESOLUTION
	
	var attack: AttackData = _active_attack
	var base_damage: int = attack.base_damage if attack != null else 20
	var attack_cat: int = attack.category if attack != null else AttackData.AttackCategory.SLASH
	var resist_modifier: float = enemy_data.get_damage_resistance_modifier(attack_cat)
	var damage: int = max(0, int(round(float(base_damage) * damage_multiplier * resist_modifier)))
	
	var flash_color: Color = Color.WHITE
	var attack_msg: String = ""
	if damage > 0:
		if damage_multiplier >= 1.2 or score_ratio >= 0.99:
			flash_color = Color(1.0, 0.9, 0.3, 1.0)
			attack_msg = "QTE: " + grade_text + "! Сокрушительная особая атака! " + enemy_data.enemy_name + " получает " + str(damage) + " крит. урона."
		elif damage_multiplier >= 1.0:
			attack_msg = "QTE: " + grade_text + "! Точный удар! " + enemy_data.enemy_name + " получает " + str(damage) + " урона."
		else:
			flash_color = Color(0.8, 0.8, 0.8, 1.0)
			attack_msg = "QTE: " + grade_text + ". Удар нанесён неточно. " + enemy_data.enemy_name + " получает " + str(damage) + " урона."
	else:
		attack_msg = "QTE: " + grade_text + "! Вы сбились с темпа, и особая атака сорвалась. Урон не нанесён."
	
	await _apply_attack_damage_and_advance(damage, "[ РЕЗУЛЬТАТ ОСОБОЙ АТАКИ ]", attack_msg, flash_color)

func _on_vow_pressed() -> void:
	if current_state != State.PLAYER_TURN and current_state != State.ATTACK_SELECTION:
		return
	
	current_state = State.ACTION_RESOLUTION
	_set_action_buttons_enabled(false)
	_set_attack_selection_visible(false)
	
	var vow_gain: int = enemy_data.resolve_per_vow
	enemy_data.current_resolve = min(enemy_data.max_resolve, enemy_data.current_resolve + vow_gain)
	_update_bars()
	
	_flash_node(_enemy_sprite, Color(0.9, 0.85, 0.3, 1.0))
	
	var vow_msg: String = enemy_data.dialogue_on_vow
	if vow_msg.is_empty():
		vow_msg = "Вы обращаетесь со словами Завета к разуму противника."
	vow_msg += " Завет увеличился на " + str(vow_gain) + "."
	
	await _play_dialogue_sequence("[ СЛОВО ЗАВЕТА ]", vow_msg)
	
	if enemy_data.current_resolve >= enemy_data.max_resolve:
		_resolve_victory_vow()
	else:
		_enter_enemy_turn()

func _on_song_pressed() -> void:
	if current_state != State.PLAYER_TURN and current_state != State.ATTACK_SELECTION:
		return
	
	current_state = State.ACTION_RESOLUTION
	_set_action_buttons_enabled(false)
	_set_attack_selection_visible(false)
	
	player_defense_buff = true
	_flash_node(_player_visual, Color(0.4, 0.7, 1.0, 1.0))
	
	await _play_dialogue_sequence(
		"[ ПЕСНЬ ЗАЩИТЫ ]",
		"Вы напеваете ритмичную мелодию. Входящий урон в следующем раунде снижен вдвое!"
	)
	_enter_enemy_turn()

func _on_item_pressed() -> void:
	if current_state != State.PLAYER_TURN and current_state != State.ATTACK_SELECTION:
		return
	
	current_state = State.ACTION_RESOLUTION
	_set_action_buttons_enabled(false)
	_set_attack_selection_visible(false)
	
	var heal: int = 30
	player_current_hp = min(player_max_hp, player_current_hp + heal)
	_update_bars()
	_flash_node(_player_visual, Color(0.3, 1.0, 0.4, 1.0))
	
	await _play_dialogue_sequence(
		"[ ПРЕДМЕТ ]",
		"Вы используете целебное снадобье. Восстановлено " + str(heal) + " HP!"
	)
	_enter_enemy_turn()

func _on_flee_pressed() -> void:
	if current_state != State.PLAYER_TURN and current_state != State.ATTACK_SELECTION:
		return
	
	current_state = State.ACTION_RESOLUTION
	_set_action_buttons_enabled(false)
	_set_attack_selection_visible(false)
	
	await _play_dialogue_sequence("[ ПОБЕГ ]", "Вы благополучно отступаете назад в мир.")
	_exit_battle(false, false)

## Ход противника
func _enter_enemy_turn() -> void:
	current_state = State.ENEMY_TURN
	_set_action_buttons_enabled(false)
	_set_attack_selection_visible(false)
	
	var damage: int = enemy_data.attack_power
	if player_defense_buff:
		damage = int(round(damage / 2.0))
		player_defense_buff = false
	
	if player_current_hp <= damage:
		_start_dodge_sequence(damage)
		return
	
	_apply_enemy_attack(damage)

func _apply_enemy_attack(damage: int) -> void:
	player_current_hp = max(0, player_current_hp - damage)
	_update_bars()
	
	_shake_node(_player_visual)
	_flash_node(_player_visual, Color(1.0, 0.2, 0.2, 1.0))
	
	var enemy_msg: String = enemy_data.dialogue_on_attack
	if enemy_msg.is_empty():
		enemy_msg = enemy_data.enemy_name + " атакует вас!"
	enemy_msg += " Нанесено " + str(damage) + " урона."
	
	await _play_dialogue_sequence("[ ХОД ВРАГА ]", enemy_msg)
	
	if player_current_hp <= 0:
		_resolve_defeat()
	else:
		_enter_player_turn()

func _start_dodge_sequence(incoming_damage: int) -> void:
	current_state = State.PLAYER_DODGE_QTE
	_update_dialogue_immediate(
		"[ ⚠ СМЕРТЕЛЬНЫЙ УДАР ⚠ ]",
		enemy_data.enemy_name + " замахивается для добивающего удара! Жмите СТРЕЛКИ для уклонения!"
	)
	
	var dodge_qte: DodgeQTE = DodgeQTE.new()
	dodge_qte.name = "DodgeQTEOverlay"
	dodge_qte.dodge_completed.connect(
		func(is_success: bool, score_ratio: float, grade_text: String) -> void:
			_on_dodge_qte_completed(is_success, score_ratio, grade_text, incoming_damage)
	)
	add_child(dodge_qte)
	dodge_qte.start_qte(3, 2.4)

func _on_dodge_qte_completed(is_success: bool, score_ratio: float, grade_text: String, original_damage: int) -> void:
	current_state = State.ACTION_RESOLUTION
	
	var attack_msg: String = ""
	if is_success:
		_animate_player_dodge()
		if score_ratio >= 0.99:
			attack_msg = "УКЛОНЕНИЕ: " + grade_text + "! Вы молниеносно уходите с траектории удара! Враг рассёк лишь воздух (Урон: 0)."
		else:
			player_current_hp = 1
			_update_bars()
			_shake_node(_player_visual)
			attack_msg = "УКЛОНЕНИЕ: " + grade_text + "! Вы частично смягчили удар и чудом устояли на ногах (осталось 1 HP)!"
		
		await _play_dialogue_sequence("[ ИСХОД АТАКИ ]", attack_msg)
		_enter_player_turn()
	else:
		player_current_hp = 0
		_update_bars()
		_shake_node(_player_visual)
		_flash_node(_player_visual, Color(1.0, 0.1, 0.1, 1.0))
		
		attack_msg = "УКЛОНЕНИЕ: " + grade_text + "! Добивающий удар " + enemy_data.enemy_name + " достиг цели! Нанесено " + str(original_damage) + " урона."
		await _play_dialogue_sequence("[ СМЕРТЕЛЬНЫЙ УДАР ]", attack_msg)
		_resolve_defeat()

func _animate_player_dodge() -> void:
	if _player_visual == null:
		return
	var orig_pos: Vector2 = _player_visual.position
	var tween: Tween = create_tween()
	tween.tween_property(_player_visual, "position:x", orig_pos.x - 24.0, 0.1)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_player_visual, "modulate:a", 0.4, 0.1)
	tween.tween_property(_player_visual, "position:x", orig_pos.x, 0.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_player_visual, "modulate:a", 1.0, 0.15)

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

func _animate_intro() -> void:
	if _player_visual != null:
		var start_p_x: float = _player_visual.position.x - 60.0
		var final_p_x: float = _player_visual.position.x
		_player_visual.position.x = start_p_x
		create_tween().tween_property(_player_visual, "position:x", final_p_x, 0.5)\
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
	for i: int in range(4):
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

## Построение интерфейса и боевой сцены (чистая арена без фонового колеса рун)
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
	arena_floor.position = Vector2(20.0, 12.0)
	arena_floor.size = Vector2(600.0, 212.0)
	arena_floor.color = Color(0.12, 0.14, 0.20, 1.0)
	add_child(arena_floor)
	
	var arena_border: ReferenceRect = ReferenceRect.new()
	arena_border.position = Vector2(20.0, 12.0)
	arena_border.size = Vector2(600.0, 212.0)
	arena_border.border_color = Color(0.24, 0.28, 0.40, 1.0)
	arena_border.border_width = 2.0
	arena_border.editor_only = false
	add_child(arena_border)
	
	# 2. Игрок слева
	var player_group: Node2D = Node2D.new()
	player_group.name = "PlayerCombatant"
	player_group.position = Vector2(105.0, 105.0)
	add_child(player_group)
	
	_player_visual = Node2D.new()
	_player_visual.name = "PlayerVisual"
	player_group.add_child(_player_visual)
	
	var hero_tex_path: String = "res://assets/sprites/player/walk/right/sprite_0.png"
	if ResourceLoader.exists(hero_tex_path):
		var hero_spr: Sprite2D = Sprite2D.new()
		hero_spr.texture = load(hero_tex_path) as Texture2D
		hero_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hero_spr.scale = Vector2(1.0, 1.0)
		hero_spr.position = Vector2(0.0, 8.0)
		_player_visual.add_child(hero_spr)
	else:
		var fallback_rect: ColorRect = ColorRect.new()
		fallback_rect.size = Vector2(28.0, 36.0)
		fallback_rect.position = Vector2(-14.0, 0.0)
		fallback_rect.color = Color(0.85, 0.15, 0.15, 1.0)
		_player_visual.add_child(fallback_rect)
	
	var player_name_lbl: Label = Label.new()
	player_name_lbl.text = "ГЕРОЙ"
	player_name_lbl.position = Vector2(-45.0, -42.0)
	player_name_lbl.size = Vector2(90.0, 16.0)
	player_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_group.add_child(player_name_lbl)
	
	_player_hp_bar = ProgressBar.new()
	_player_hp_bar.max_value = player_max_hp
	_player_hp_bar.value = player_current_hp
	_player_hp_bar.position = Vector2(-40.0, -24.0)
	_player_hp_bar.size = Vector2(80.0, 10.0)
	_player_hp_bar.show_percentage = false
	player_group.add_child(_player_hp_bar)
	
	# 3. Враг справа
	var enemy_group: Node2D = Node2D.new()
	enemy_group.name = "EnemyCombatant"
	enemy_group.position = Vector2(535.0, 95.0)
	add_child(enemy_group)
	
	_enemy_sprite = ColorRect.new()
	_enemy_sprite.name = "EnemySprite"
	_enemy_sprite.size = Vector2(36.0, 48.0)
	_enemy_sprite.position = Vector2(-18.0, 0.0)
	_enemy_sprite.color = enemy_data.sprite_color
	enemy_group.add_child(_enemy_sprite)
	
	var enemy_name_lbl: Label = Label.new()
	enemy_name_lbl.text = enemy_data.enemy_name
	enemy_name_lbl.position = Vector2(-65.0, -44.0)
	enemy_name_lbl.size = Vector2(130.0, 16.0)
	enemy_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_group.add_child(enemy_name_lbl)
	
	_enemy_hp_bar = ProgressBar.new()
	_enemy_hp_bar.max_value = enemy_data.max_hp
	_enemy_hp_bar.value = enemy_data.current_hp
	_enemy_hp_bar.position = Vector2(-50.0, -26.0)
	_enemy_hp_bar.size = Vector2(100.0, 8.0)
	_enemy_hp_bar.show_percentage = false
	enemy_group.add_child(_enemy_hp_bar)
	
	_enemy_resolve_bar = ProgressBar.new()
	_enemy_resolve_bar.max_value = enemy_data.max_resolve
	_enemy_resolve_bar.value = enemy_data.current_resolve
	_enemy_resolve_bar.position = Vector2(-50.0, -14.0)
	_enemy_resolve_bar.size = Vector2(100.0, 6.0)
	_enemy_resolve_bar.show_percentage = false
	_enemy_resolve_bar.modulate = Color(0.9, 0.85, 0.2, 1.0)
	enemy_group.add_child(_enemy_resolve_bar)
	
	# 4. НИЖНЯЯ ПАНЕЛЬ ДЛЯ КНОПОК И ДИАЛОГОВ
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
	
	var separator: VSeparator = VSeparator.new()
	h_layout.add_child(separator)
	
	# Правая часть: Окно диалогов и панель выбора конкретной атаки
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
	_dialogue_header.add_theme_font_size_override("font_size", 11)
	_dialogue_header.modulate = Color(0.9, 0.8, 0.3, 1.0)
	dialogue_box.add_child(_dialogue_header)
	
	_dialogue_label = Label.new()
	_dialogue_label.text = "Перед вами враг."
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_box.add_child(_dialogue_label)
	
	# Контейнер выбора вида атаки с отображением приоритетных рун
	_attack_selection_box = VBoxContainer.new()
	_attack_selection_box.name = "AttackSelectionBox"
	_attack_selection_box.visible = false
	_attack_selection_box.add_theme_constant_override("separation", 3)
	dialogue_box.add_child(_attack_selection_box)
	
	for atk: AttackData in player_attacks:
		var atk_btn: Button = Button.new()
		if atk.is_special_attack and atk.qte_mode == AttackData.QTEMode.RUNE_WHEEL:
			atk_btn.text = "⚔ %s  (Приоритетные руны: %s)" % [atk.attack_name, atk.get_priority_runes_text()]
		else:
			atk_btn.text = "⚔ %s" % atk.attack_name
		atk_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		atk_btn.add_theme_font_size_override("font_size", 11)
		atk_btn.pressed.connect(func() -> void:
			execute_attack(atk)
		)
		_attack_selection_box.add_child(atk_btn)
	
	_dialogue_prompt = Label.new()
	_dialogue_prompt.name = "DialoguePrompt"
	_dialogue_prompt.text = "▼ [E / Пробел]"
	_dialogue_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dialogue_prompt.modulate = Color(0.8, 0.85, 1.0, 0.8)
	_dialogue_prompt.visible = false
	dialogue_box.add_child(_dialogue_prompt)
