# res://scenes/battle.gd
class_name BattleArena
extends Node2D

const MAP_WIDTH: float = 1280.0
const MAP_HEIGHT: float = 783.0
const LOCATION_TEXTURE_PATH: String = "res://assets/locations/home.png"

## Начальная точка появления игрока у камина
@export var default_spawn_position: Vector2 = Vector2(640.0, 265.0)
## Масштаб персонажа под пропорции интерьера дома (спрайты 64x64 -> 128px)
@export var player_visual_scale: Vector2 = Vector2(2.0, 2.0)
## Скорость передвижения персонажа в доме
@export var player_move_speed: float = 180.0
## Отображать ли контуры невидимых стен и зон для отладки
@export var debug_show_invisible_walls: bool = false
## Включать ли случайные битвы прямо в этой локации (в доме отключено по умолчанию)
@export var enable_random_encounters: bool = false

@onready var player: Player = $Player
var _inventory_overlay: InventoryMenuOverlay = null

## Прямоугольники коллизий стен и мебели в доме (1280x783)
const WALL_RECTS: Array[Rect2] = [
	# Верхняя стена, камин, полки и окно
	Rect2(0.0, 0.0, 1280.0, 240.0),
	Rect2(440.0, 240.0, 50.0, 32.0),   # Табурет слева от камина
	Rect2(490.0, 240.0, 260.0, 22.0),  # Каменное основание камина
	Rect2(800.0, 200.0, 108.0, 58.0),  # Шкаф с банками справа от камина
	# Кровать и тумбочка в левом верхнем углу
	Rect2(56.0, 180.0, 180.0, 138.0),
	Rect2(240.0, 220.0, 96.0, 45.0),
	# Левая стена и мебель слева
	Rect2(0.0, 0.0, 64.0, 783.0),
	Rect2(64.0, 324.0, 104.0, 84.0),   # Сундук под кроватью
	Rect2(64.0, 510.0, 386.0, 135.0),  # Письменный стол с картой, бочка и ящики
	# Правая стена и мебель справа
	Rect2(1216.0, 0.0, 64.0, 783.0),
	Rect2(920.0, 200.0, 296.0, 80.0),  # Бочка, сундук и стойка с копьями сверху справа
	Rect2(1110.0, 280.0, 106.0, 150.0),# Ящики у правой стены
	Rect2(1152.0, 480.0, 64.0, 165.0), # Растение и мешок справа снизу
	Rect2(885.0, 560.0, 215.0, 85.0),  # Сундук и бочка справа снизу
	# Центральный обеденный стол со скамьей и стулом
	Rect2(532.0, 355.0, 268.0, 155.0),
	# Нижняя стена слева и справа от выхода в деревню (проход x = 580..696 открыт)
	Rect2(0.0, 640.0, 580.0, 143.0),
	Rect2(696.0, 640.0, 584.0, 143.0),
	# Нижний край за ступеньками выхода
	Rect2(580.0, 760.0, 116.0, 23.0),
]

func _ready() -> void:
	GameManager.current_location_id = "home"
	_clean_legacy_nodes()
	_setup_map_visuals()
	_setup_invisible_walls()
	_setup_player_and_camera()
	_handle_return_from_battle()
	_setup_inventory_overlay()
	_setup_house_interactables()
	_setup_exit_to_village()
	if enable_random_encounters:
		_setup_corridor_battle_zone()
	queue_redraw()

## Удаляет старый зеленый фон и границы арены 1920x1080
func _clean_legacy_nodes() -> void:
	var legacy_bg: Node = get_node_or_null("Background")
	if legacy_bg != null and legacy_bg is ColorRect and (legacy_bg as ColorRect).color.g > 0.3:
		legacy_bg.queue_free()
	
	var legacy_bounds: Node = get_node_or_null("Boundaries")
	if legacy_bounds != null:
		legacy_bounds.queue_free()

## Создает или обновляет спрайт стартовой локации (Дом героя)
func _setup_map_visuals() -> void:
	var bg_void: ColorRect = get_node_or_null("BackgroundVoid") as ColorRect
	if bg_void == null:
		bg_void = ColorRect.new()
		bg_void.name = "BackgroundVoid"
		add_child(bg_void)
		move_child(bg_void, 0)
	
	bg_void.offset_left = 0.0
	bg_void.offset_top = 0.0
	bg_void.offset_right = MAP_WIDTH
	bg_void.offset_bottom = MAP_HEIGHT
	bg_void.color = Color(0.04, 0.03, 0.03, 1.0)
	
	var sprite: Sprite2D = get_node_or_null("LocationSprite") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "LocationSprite"
		add_child(sprite)
		move_child(sprite, 1)
	
	sprite.centered = false
	sprite.position = Vector2.ZERO
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(LOCATION_TEXTURE_PATH):
		var tex: Texture2D = load(LOCATION_TEXTURE_PATH) as Texture2D
		sprite.texture = tex

## Процедурная расстановка невидимых стен по всей карте дома
func _setup_invisible_walls() -> void:
	var walls_node: StaticBody2D = get_node_or_null("InvisibleWalls") as StaticBody2D
	if walls_node != null:
		walls_node.queue_free()
	
	walls_node = StaticBody2D.new()
	walls_node.name = "InvisibleWalls"
	add_child(walls_node)
	
	for i: int in range(WALL_RECTS.size()):
		var rect: Rect2 = WALL_RECTS[i]
		var col_shape: CollisionShape2D = CollisionShape2D.new()
		col_shape.name = "Wall_%d" % i
		
		var rect_shape: RectangleShape2D = RectangleShape2D.new()
		rect_shape.size = rect.size
		col_shape.shape = rect_shape
		col_shape.position = rect.position + (rect.size / 2.0)
		
		walls_node.add_child(col_shape)

## Настройка камеры, масштаба и начальной позиции персонажа у камина
func _setup_player_and_camera() -> void:
	if player == null:
		return
	
	player.scale = player_visual_scale
	player.speed = player_move_speed
	
	var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(MAP_WIDTH)
		camera.limit_bottom = int(MAP_HEIGHT)
		camera.editor_draw_limits = true
	
	# Помещаем героя у камина при старте, если нет сохраненной позиции
	if not player.restored_position_on_ready and not GameManager.has_saved_player_position and not GameManager.has_return_position:
		player.global_position = default_spawn_position

## Восстанавливает позицию игрока и разблокирует управление при возврате
func _handle_return_from_battle() -> void:
	if GameManager.has_return_position:
		var return_data: Dictionary = GameManager.consume_return_position()
		if bool(return_data.get("valid", false)) and player != null:
			if return_data.has("position") and return_data["position"] is Vector2:
				player.global_position = return_data["position"] as Vector2
			player.is_locked = false
	elif GameManager.has_saved_player_position:
		if player != null:
			player.global_position = GameManager.saved_player_position
			player.unlock_movement()
		GameManager.clear_saved_player_position()
	elif player != null and player.restored_position_on_ready:
		player.is_locked = false

func _setup_inventory_overlay() -> void:
	_inventory_overlay = get_node_or_null("InventoryMenuOverlay") as InventoryMenuOverlay
	if _inventory_overlay == null:
		_inventory_overlay = InventoryMenuOverlay.new()
		_inventory_overlay.name = "InventoryMenuOverlay"
		add_child(_inventory_overlay)
	_inventory_overlay.bind_player(player)

## Универсальный метод для добавления интерактивного объекта в локацию
func register_interactable(
	p_id: String,
	p_title: String,
	p_pos: Vector2,
	p_size: Vector2,
	p_lines: Array[String],
	p_prompt: String = "[E] Осмотреть"
) -> InteractableObject:
	var obj: InteractableObject = InteractableObject.create_interactable(
		p_id, p_title, p_pos, p_size, p_lines, p_prompt
	)
	obj.debug_show_zone = debug_show_invisible_walls
	obj.interacted.connect(_on_house_object_interacted)
	add_child(obj)
	return obj

## Базовые интерактивные объекты в доме (готовый шаблон для расширения)
func _setup_house_interactables() -> void:
	register_interactable(
		"fireplace",
		"Камин",
		Vector2(640.0, 285.0),
		Vector2(140.0, 50.0),
		["В очаге потрескивают сосновые поленья. Тепло огня придает сил перед дорогой."],
		"[E] Согреться"
	)
	register_interactable(
		"map_desk",
		"Письменный стол",
		Vector2(210.0, 495.0),
		Vector2(180.0, 50.0),
		["На столе развернута старая карта северных земель и записи о древних Заветах."],
		"[E] Изучить карту"
	)

func _on_house_object_interacted(_p: Player, _object_id: String) -> void:
	# Сюда в будущем можно добавлять квестовые триггеры по _object_id
	pass

## Зона выхода из дома снизу -> переносит игрока в Деревню
func _setup_exit_to_village() -> void:
	var exit_zone: InteractableObject = InteractableObject.create_interactable(
		"exit_to_village",
		"Выход в деревню",
		Vector2(638.0, 705.0),
		Vector2(112.0, 70.0),
		[],
		"Выход в деревню"
	)
	exit_zone.trigger_on_enter = true
	exit_zone.show_prompt_hint = false
	exit_zone.debug_show_zone = debug_show_invisible_walls
	exit_zone.interacted.connect(_on_exit_to_village_entered)
	add_child(exit_zone)

func _on_exit_to_village_entered(_p: Player, _id: String) -> void:
	GameManager.transition_to_village(Vector2(340.0, 356.0))

## Боевая зона со случайными битвами (используется только если enable_random_encounters = true)
func _setup_corridor_battle_zone() -> void:
	var existing_zones: Array[Node] = get_tree().get_nodes_in_group("battle_zones")
	for zone: Node in existing_zones:
		if zone != null and zone.is_inside_tree():
			zone.queue_free()
	
	var world_battle_zone: BattleZone = BattleZone.new()
	world_battle_zone.name = "CorridorBattleZone"
	world_battle_zone.zone_name = "Святилище Семи Миров"
	world_battle_zone.position = Vector2(MAP_WIDTH / 2.0, MAP_HEIGHT / 2.0)
	world_battle_zone.zone_size = Vector2(MAP_WIDTH, MAP_HEIGHT)
	world_battle_zone.use_time_based_encounters = true
	world_battle_zone.min_encounter_seconds = 30.0
	world_battle_zone.max_encounter_seconds = 45.0
	world_battle_zone.show_visual_marker = false
	world_battle_zone.possible_enemies = _create_location_enemies()
	add_child(world_battle_zone)

## Создает противников с учетом механики Завета (Dual Victory Condition)
func _create_location_enemies() -> Array[EnemyData]:
	var list: Array[EnemyData] = []
	
	var guardian: EnemyData = EnemyData.new()
	guardian.enemy_name = "Хранитель Святилища"
	guardian.max_hp = 65
	guardian.current_hp = 65
	guardian.attack_power = 12
	guardian.max_resolve = 100
	guardian.current_resolve = 0
	guardian.resolve_per_vow = 35
	guardian.sprite_color = Color(0.9, 0.75, 0.2, 1.0)
	guardian.dialogue_intro = "Древний бронзовый Хранитель оживает от стука шагов! Его клинок пылает золотым светом."
	guardian.dialogue_on_attack = "Хранитель парирует удар и готовит сокрушительный ответ!"
	guardian.dialogue_on_vow = "Слова древнего Завета отзываются в механизме Хранителя. Он замедляет движения."
	guardian.dialogue_pacified = "Хранитель опускает клинок и склоняется перед истинным наследником."
	guardian.dialogue_defeat = "Бронзовый доспех с грохотом рассыпается на плитах храма."
	list.append(guardian)
	
	var frost: EnemyData = EnemyData.new()
	frost.enemy_name = "Морозный Фантом"
	frost.max_hp = 50
	frost.current_hp = 50
	frost.attack_power = 14
	frost.max_resolve = 90
	frost.current_resolve = 0
	frost.resolve_per_vow = 30
	frost.sprite_color = Color(0.3, 0.65, 0.95, 1.0)
	frost.dialogue_intro = "Ледяной вихрь с северных пиков материализуется в Морозного Фантома!"
	frost.dialogue_on_attack = "Фантом шипит от ярости, воздух вокруг замерзает!"
	frost.dialogue_on_vow = "Тепло искренних слов согревает замерзшую душу призрака."
	frost.dialogue_pacified = "Фантом улыбается и растворяется в морозном воздухе, оставив кристалл мира."
	frost.dialogue_defeat = "Ледяной призрак раскалывается на осколки и тает."
	list.append(frost)
	
	var ashen: EnemyData = EnemyData.new()
	ashen.enemy_name = "Пепельный Скиталец"
	ashen.max_hp = 55
	ashen.current_hp = 55
	ashen.attack_power = 11
	ashen.max_resolve = 100
	ashen.current_resolve = 0
	ashen.resolve_per_vow = 40
	ashen.sprite_color = Color(0.85, 0.3, 0.15, 1.0)
	ashen.dialogue_intro = "Из трещин магматических пещер поднимается клубящийся Пепельный Скиталец!"
	ashen.dialogue_on_attack = "Скиталец взрывается искрами и бросается в атаку!"
	ashen.dialogue_on_vow = "Завет гасит пламя гнева, оставляя лишь тихое мерцание углей."
	ashen.dialogue_pacified = "Скиталец опускается на колени и затихает, обретя долгожданный покой."
	ashen.dialogue_defeat = "Пепел оседает на камнях."
	list.append(ashen)
	
	return list

func _draw() -> void:
	if not debug_show_invisible_walls:
		return
	
	var debug_color: Color = Color(1.0, 0.1, 0.1, 0.35)
	var border_color: Color = Color(1.0, 0.3, 0.3, 0.8)
	for rect: Rect2 in WALL_RECTS:
		draw_rect(rect, debug_color)
		draw_rect(rect, border_color, false, 1.0)
