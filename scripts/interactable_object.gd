# res://scripts/interactable_object.gd
class_name InteractableObject
extends Area2D

## Сигнал вызывается при взаимодействии игрока с объектом
signal interacted(player: Player, object_id: String)
## Сигнал вызывается после закрытия диалогового окна осмотра объекта
signal interaction_finished(player: Player, object_id: String)
## Сигналы входа и выхода игрока из зоны взаимодействия
signal player_entered_range(player: Player, object_id: String)
signal player_exited_range(player: Player, object_id: String)

@export_group("Параметры объекта")
## Уникальный идентификатор объекта (например: "fireplace", "bed", "map_table")
@export var object_id: String = "interactable_object"
## Название объекта для подсказки или заголовка окна
@export var display_name: String = "Объект"
## Текст всплывающей подсказки при приближении
@export var prompt_text: String = "[E] Осмотреть"
## Реплики/описание, которые выводятся при осмотре объекта (если пусто — только сигнал interacted)
@export_multiline var interaction_lines: Array[String] = []
## Если true, взаимодействие срабатывает сразу при входе в зону без нажатия клавиши
@export var trigger_on_enter: bool = false
## Если true, объект можно активировать только один раз
@export var one_shot: bool = false

@export_group("Геометрия и отображение")
## Размер зоны взаимодействия (если CollisionShape2D не добавлен вручную в редакторе)
@export var interaction_size: Vector2 = Vector2(64.0, 48.0)
## Смещение всплывающей подсказки относительно центра объекта
@export var prompt_offset: Vector2 = Vector2(0.0, -36.0)
## Показывать ли всплывающую подсказку над объектом
@export var show_prompt_hint: bool = true
## Отладочная отрисовка границ зоны взаимодействия
@export var debug_show_zone: bool = false

var _player_in_range: Player = null
var _has_been_used: bool = false
var _is_showing_dialogue: bool = false
var _current_line_index: int = 0

var _collision_shape: CollisionShape2D = null
var _prompt_container: Node2D = null
var _prompt_label: Label = null
var _dialogue_layer: CanvasLayer = null
var _dialogue_text_label: Label = null
var _dialogue_title_label: Label = null

func _ready() -> void:
	add_to_group("interactables")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_ensure_collision_shape()
	_setup_prompt_ui()
	queue_redraw()

## Вспомогательный фабричный метод для быстрого создания интерактивного объекта из кода
static func create_interactable(
	p_id: String,
	p_name: String,
	p_pos: Vector2,
	p_size: Vector2,
	p_lines: Array[String] = [],
	p_prompt: String = "[E] Осмотреть"
) -> InteractableObject:
	var obj: InteractableObject = InteractableObject.new()
	obj.name = "Interactable_" + p_id
	obj.object_id = p_id
	obj.display_name = p_name
	obj.position = p_pos
	obj.interaction_size = p_size
	obj.interaction_lines = p_lines
	obj.prompt_text = p_prompt
	return obj

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	
	if _is_showing_dialogue:
		get_viewport().set_input_as_handled()
		_advance_dialogue()
		return
	
	if _player_in_range != null and not _player_in_range.is_movement_locked:
		if one_shot and _has_been_used:
			return
		get_viewport().set_input_as_handled()
		trigger_interaction(_player_in_range)

## Запускает взаимодействие с объектом
func trigger_interaction(player: Player) -> void:
	if one_shot and _has_been_used:
		return
	
	_has_been_used = true
	_set_prompt_visible(false)
	interacted.emit(player, object_id)
	
	if not interaction_lines.is_empty():
		_start_dialogue(player)
	else:
		interaction_finished.emit(player, object_id)

func _ensure_collision_shape() -> void:
	for child: Node in get_children():
		if child is CollisionShape2D:
			_collision_shape = child as CollisionShape2D
			return
	
	_collision_shape = CollisionShape2D.new()
	_collision_shape.name = "CollisionShape2D"
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = interaction_size
	_collision_shape.shape = rect
	add_child(_collision_shape)

func _setup_prompt_ui() -> void:
	_prompt_container = Node2D.new()
	_prompt_container.name = "PromptContainer"
	_prompt_container.position = prompt_offset
	_prompt_container.z_index = 20
	_prompt_container.visible = false
	add_child(_prompt_container)
	
	var bg: ColorRect = ColorRect.new()
	bg.name = "PromptBg"
	bg.size = Vector2(120.0, 22.0)
	bg.position = Vector2(-60.0, -11.0)
	bg.color = Color(0.08, 0.06, 0.05, 0.88)
	_prompt_container.add_child(bg)
	
	_prompt_label = Label.new()
	_prompt_label.name = "PromptLabel"
	_prompt_label.text = prompt_text
	_prompt_label.size = Vector2(120.0, 22.0)
	_prompt_label.position = Vector2(-60.0, -11.0)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 11)
	_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.65, 1.0))
	_prompt_container.add_child(_prompt_label)

func _set_prompt_visible(is_vis: bool) -> void:
	if _prompt_container == null:
		return
	if not show_prompt_hint or (one_shot and _has_been_used):
		_prompt_container.visible = false
		return
	if _prompt_label != null:
		_prompt_label.text = prompt_text
	_prompt_container.visible = is_vis

func _start_dialogue(player: Player) -> void:
	_is_showing_dialogue = true
	_current_line_index = 0
	if player != null:
		player.lock_movement()
	
	if _dialogue_layer == null:
		_create_dialogue_box()
	
	_dialogue_layer.visible = true
	_update_dialogue_text()

func _advance_dialogue() -> void:
	_current_line_index += 1
	if _current_line_index >= interaction_lines.size():
		_close_dialogue()
	else:
		_update_dialogue_text()

func _update_dialogue_text() -> void:
	if _dialogue_title_label != null:
		_dialogue_title_label.text = display_name
	if _dialogue_text_label != null and _current_line_index < interaction_lines.size():
		_dialogue_text_label.text = interaction_lines[_current_line_index]

func _close_dialogue() -> void:
	_is_showing_dialogue = false
	if _dialogue_layer != null:
		_dialogue_layer.visible = false
	
	if _player_in_range != null:
		_player_in_range.unlock_movement()
		if not (one_shot and _has_been_used):
			_set_prompt_visible(true)
	
	interaction_finished.emit(_player_in_range, object_id)

func _create_dialogue_box() -> void:
	_dialogue_layer = CanvasLayer.new()
	_dialogue_layer.name = "InteractionDialogueLayer"
	_dialogue_layer.layer = 15
	add_child(_dialogue_layer)
	
	var outer_panel: ColorRect = ColorRect.new()
	outer_panel.name = "OuterBorder"
	outer_panel.position = Vector2(40.0, 256.0)
	outer_panel.size = Vector2(560.0, 88.0)
	outer_panel.color = Color(0.75, 0.58, 0.32, 1.0)
	_dialogue_layer.add_child(outer_panel)
	
	var inner_panel: ColorRect = ColorRect.new()
	inner_panel.name = "InnerBox"
	inner_panel.position = Vector2(2.0, 2.0)
	inner_panel.size = Vector2(556.0, 84.0)
	inner_panel.color = Color(0.1, 0.08, 0.07, 0.96)
	outer_panel.add_child(inner_panel)
	
	_dialogue_title_label = Label.new()
	_dialogue_title_label.name = "TitleLabel"
	_dialogue_title_label.position = Vector2(12.0, 6.0)
	_dialogue_title_label.size = Vector2(532.0, 18.0)
	_dialogue_title_label.add_theme_font_size_override("font_size", 12)
	_dialogue_title_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35, 1.0))
	inner_panel.add_child(_dialogue_title_label)
	
	_dialogue_text_label = Label.new()
	_dialogue_text_label.name = "TextLabel"
	_dialogue_text_label.position = Vector2(12.0, 26.0)
	_dialogue_text_label.size = Vector2(532.0, 40.0)
	_dialogue_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_text_label.add_theme_font_size_override("font_size", 11)
	_dialogue_text_label.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88, 1.0))
	inner_panel.add_child(_dialogue_text_label)
	
	var continue_hint: Label = Label.new()
	continue_hint.name = "ContinueHint"
	continue_hint.text = "[E / Пробел] Далее"
	continue_hint.position = Vector2(410.0, 64.0)
	continue_hint.size = Vector2(136.0, 16.0)
	continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_hint.add_theme_font_size_override("font_size", 9)
	continue_hint.add_theme_color_override("font_color", Color(0.7, 0.68, 0.62, 1.0))
	inner_panel.add_child(continue_hint)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player: Player = body as Player
		_player_in_range = player
		player_entered_range.emit(player, object_id)
		
		if trigger_on_enter:
			trigger_interaction(player)
		else:
			_set_prompt_visible(true)

func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		var exiting_player: Player = _player_in_range
		_player_in_range = null
		_set_prompt_visible(false)
		player_exited_range.emit(exiting_player, object_id)

func _draw() -> void:
	if not debug_show_zone:
		return
	var rect: Rect2 = Rect2(-interaction_size / 2.0, interaction_size)
	draw_rect(rect, Color(0.2, 0.85, 1.0, 0.25))
	draw_rect(rect, Color(0.2, 0.85, 1.0, 0.85), false, 1.5)
