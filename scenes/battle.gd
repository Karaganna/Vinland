# res://scenes/battle.gd
class_name BattleArena
extends Node2D

const MAP_WIDTH: float = 1085.0
const MAP_HEIGHT: float = 992.0
const LOCATION_TEXTURE_PATH: String = "res://assets/locations/test_locate.png"

## Начальная точка появления игрока в центральном святилище
@export var default_spawn_position: Vector2 = Vector2(540.0, 520.0)
## Отображать ли контуры невидимых стен для отладки
@export var debug_show_invisible_walls: bool = false

@onready var player: Player = $Player

## Прямоугольники коллизий невидимых стен (перекрывают бездну и препятствия вокруг биомов и мостов)
const WALL_RECTS: Array[Rect2] = [
	Rect2(0.0, 0.0, 1088.0, 64.0),
	Rect2(0.0, 64.0, 512.0, 96.0),
	Rect2(576.0, 64.0, 512.0, 32.0),
	Rect2(576.0, 96.0, 256.0, 128.0),
	Rect2(928.0, 96.0, 160.0, 896.0),
	Rect2(560.0, 128.0, 16.0, 128.0),
	Rect2(832.0, 144.0, 16.0, 80.0),
	Rect2(912.0, 144.0, 16.0, 848.0),
	Rect2(0.0, 160.0, 80.0, 832.0),
	Rect2(256.0, 160.0, 256.0, 96.0),
	Rect2(576.0, 224.0, 32.0, 32.0),
	Rect2(880.0, 224.0, 32.0, 48.0),
	Rect2(256.0, 256.0, 176.0, 160.0),
	Rect2(608.0, 256.0, 192.0, 208.0),
	Rect2(896.0, 272.0, 16.0, 720.0),
	Rect2(432.0, 288.0, 176.0, 176.0),
	Rect2(800.0, 288.0, 32.0, 240.0),
	Rect2(80.0, 320.0, 80.0, 160.0),
	Rect2(192.0, 320.0, 64.0, 48.0),
	Rect2(208.0, 368.0, 48.0, 32.0),
	Rect2(160.0, 400.0, 48.0, 80.0),
	Rect2(832.0, 400.0, 16.0, 64.0),
	Rect2(880.0, 400.0, 16.0, 64.0),
	Rect2(288.0, 416.0, 144.0, 48.0),
	Rect2(208.0, 432.0, 16.0, 64.0),
	Rect2(288.0, 464.0, 112.0, 48.0),
	Rect2(640.0, 464.0, 160.0, 48.0),
	Rect2(80.0, 480.0, 32.0, 512.0),
	Rect2(784.0, 512.0, 16.0, 16.0),
	Rect2(256.0, 544.0, 144.0, 112.0),
	Rect2(640.0, 544.0, 80.0, 336.0),
	Rect2(720.0, 560.0, 32.0, 432.0),
	Rect2(208.0, 576.0, 48.0, 96.0),
	Rect2(400.0, 576.0, 112.0, 304.0),
	Rect2(560.0, 576.0, 80.0, 304.0),
	Rect2(752.0, 608.0, 144.0, 384.0),
	Rect2(304.0, 656.0, 96.0, 336.0),
	Rect2(112.0, 688.0, 80.0, 304.0),
	Rect2(192.0, 720.0, 112.0, 272.0),
	Rect2(400.0, 880.0, 16.0, 112.0),
	Rect2(656.0, 880.0, 64.0, 112.0),
	Rect2(416.0, 960.0, 240.0, 32.0),
]

func _ready() -> void:
	_clean_legacy_nodes()
	_setup_map_visuals()
	_setup_invisible_walls()
	_setup_player_and_camera()
	_handle_return_from_battle()
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

## Создает спрайт пиксельной локации с правильной фильтрацией
func _setup_map_visuals() -> void:
	# Темный фон бездны
	var bg_void: ColorRect = get_node_or_null("BackgroundVoid") as ColorRect
	if bg_void == null:
		bg_void = ColorRect.new()
		bg_void.name = "BackgroundVoid"
		bg_void.offset_left = 0.0
		bg_void.offset_top = 0.0
		bg_void.offset_right = MAP_WIDTH
		bg_void.offset_bottom = MAP_HEIGHT
		bg_void.color = Color(0.015, 0.015, 0.025, 1.0)
		add_child(bg_void)
		move_child(bg_void, 0)
	
	# Спрайт локации
	var sprite: Sprite2D = get_node_or_null("LocationSprite") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "LocationSprite"
		sprite.centered = false
		sprite.position = Vector2.ZERO
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		if ResourceLoader.exists(LOCATION_TEXTURE_PATH):
			var tex: Texture2D = load(LOCATION_TEXTURE_PATH) as Texture2D
			sprite.texture = tex
		add_child(sprite)
		move_child(sprite, 1)

## Процедурная расстановка невидимых стен по всей карте
func _setup_invisible_walls() -> void:
	var walls_node: StaticBody2D = get_node_or_null("InvisibleWalls") as StaticBody2D
	if walls_node != null:
		return
	
	walls_node = StaticBody2D.new()
	walls_node.name = "InvisibleWalls"
	add_child(walls_node)
	
	for i in range(WALL_RECTS.size()):
		var rect: Rect2 = WALL_RECTS[i]
		var col_shape: CollisionShape2D = CollisionShape2D.new()
		col_shape.name = "Wall_%d" % i
		
		var rect_shape: RectangleShape2D = RectangleShape2D.new()
		rect_shape.size = rect.size
		col_shape.shape = rect_shape
		col_shape.position = rect.position + (rect.size / 2.0)
		
		walls_node.add_child(col_shape)

## Настройка камеры и начальной позиции персонажа
func _setup_player_and_camera() -> void:
	if player == null:
		return
	
	# Настройка ограничений камеры под размер карты (1085x992)
	var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(MAP_WIDTH)
		camera.limit_bottom = int(MAP_HEIGHT)
		camera.editor_draw_limits = true
	
	# Установка начальной позиции, если не было сохранения перед боем
	if GameManager.saved_player_position == Vector2.ZERO:
		player.global_position = default_spawn_position

## Восстанавливает позицию игрока и разблокирует управление при возврате из боя
func _handle_return_from_battle() -> void:
	if GameManager.saved_player_position != Vector2.ZERO:
		if player != null:
			player.global_position = GameManager.saved_player_position
			player.unlock_movement()
		GameManager.saved_player_position = Vector2.ZERO

## Боевая зона на всей территории локации со случайными битвами
func _setup_corridor_battle_zone() -> void:
	# Очищаем старые тестовые зоны
	var existing_zones: Array[Node] = get_tree().get_nodes_in_group("battle_zones")
	for zone in existing_zones:
		if zone != null and zone.is_inside_tree():
			zone.queue_free()
	
	var world_battle_zone: BattleZone = BattleZone.new()
	world_battle_zone.name = "CorridorBattleZone"
	world_battle_zone.zone_name = "Святилище Семи Миров"
	# Центр карты для Area2D
	world_battle_zone.position = Vector2(MAP_WIDTH / 2.0, MAP_HEIGHT / 2.0)
	world_battle_zone.zone_size = Vector2(MAP_WIDTH, MAP_HEIGHT)
	world_battle_zone.use_time_based_encounters = true
	world_battle_zone.min_encounter_seconds = 30.0 # Минимум 30 сек активной ходьбы до боя
	world_battle_zone.max_encounter_seconds = 45.0 # Максимум 45 сек активной ходьбы до боя
	world_battle_zone.show_visual_marker = false # Отключаем заливку, чтобы не перекрывать пиксель-арт
	
	# Наполнение зоны тематическими противниками с двойной системой победы (HP и Завет)
	world_battle_zone.possible_enemies = _create_location_enemies()
	
	add_child(world_battle_zone)

## Создает противников для локации с учетом механики Завета (Dual Victory Condition)
func _create_location_enemies() -> Array[EnemyData]:
	var list: Array[EnemyData] = []
	
	# 1. Хранитель Храма
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
	
	# 2. Морозный Фантом
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
	
	# 3. Пепельный Скиталец
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
	
	# Отрисовка невидимых стен для наглядной отладки в игре
	var debug_color: Color = Color(1.0, 0.1, 0.1, 0.35)
	var border_color: Color = Color(1.0, 0.3, 0.3, 0.8)
	for rect in WALL_RECTS:
		draw_rect(rect, debug_color)
		draw_rect(rect, border_color, false, 1.0)
