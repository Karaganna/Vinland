# res://scripts/village_location.gd
class_name VillageLocation
extends Node2D

const VILLAGE_WIDTH: float = 1280.0
const VILLAGE_HEIGHT: float = 783.0
const PLAYER_SCENE_PATH: String = "res://scenes/Player.tscn"

@export var default_spawn_position: Vector2 = Vector2(640.0, 140.0)
@export var player_visual_scale: Vector2 = Vector2(3.0, 3.0)
## Деревня по умолчанию является полностью безопасной локацией
@export var enable_random_encounters: bool = false
## Временная красная зона для тестирования новой боевой системы с Колесом Рун
@export var enable_temp_test_battle_zone: bool = true

var player: Player = null

func _ready() -> void:
	_setup_green_background()
	_setup_boundaries()
	_setup_return_to_house_zone()
	if enable_temp_test_battle_zone:
		_setup_temp_test_battle_zone()
	if enable_random_encounters:
		_setup_village_battle_zone()
	_setup_player_and_camera()
	_handle_return_from_battle()

func _setup_green_background() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.name = "VillageGreenBackground"
	bg.position = Vector2.ZERO
	bg.size = Vector2(VILLAGE_WIDTH, VILLAGE_HEIGHT)
	bg.color = Color(0.18, 0.45, 0.22, 1.0)
	add_child(bg)
	
	# Тропинка от входа в дом вниз
	var path_rect: ColorRect = ColorRect.new()
	path_rect.name = "VillagePathPlaceholder"
	path_rect.position = Vector2(590.0, 0.0)
	path_rect.size = Vector2(100.0, VILLAGE_HEIGHT)
	path_rect.color = Color(0.36, 0.28, 0.18, 0.65)
	add_child(path_rect)
	
	var title_label: Label = Label.new()
	title_label.name = "VillagePlaceholderLabel"
	title_label.text = "ДЕРЕВНЯ (безопасная локация — заглушка)"
	title_label.position = Vector2(0.0, 16.0)
	title_label.size = Vector2(VILLAGE_WIDTH, 32.0)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.98, 0.9, 0.9))
	add_child(title_label)

func _setup_boundaries() -> void:
	var bounds: StaticBody2D = StaticBody2D.new()
	bounds.name = "VillageBoundaries"
	add_child(bounds)
	
	var wall_thickness: float = 32.0
	var rects: Array[Rect2] = [
		Rect2(0.0, -wall_thickness, VILLAGE_WIDTH, wall_thickness),
		Rect2(0.0, VILLAGE_HEIGHT, VILLAGE_WIDTH, wall_thickness),
		Rect2(-wall_thickness, 0.0, wall_thickness, VILLAGE_HEIGHT),
		Rect2(VILLAGE_WIDTH, 0.0, wall_thickness, VILLAGE_HEIGHT)
	]
	for i: int in range(rects.size()):
		var r: Rect2 = rects[i]
		var col: CollisionShape2D = CollisionShape2D.new()
		col.name = "Boundary_%d" % i
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = r.size
		col.shape = shape
		col.position = r.position + (r.size / 2.0)
		bounds.add_child(col)

func _setup_return_to_house_zone() -> void:
	var door_visual: ColorRect = ColorRect.new()
	door_visual.name = "HouseEntranceMarker"
	door_visual.position = Vector2(590.0, 0.0)
	door_visual.size = Vector2(100.0, 48.0)
	door_visual.color = Color(0.28, 0.18, 0.1, 1.0)
	add_child(door_visual)
	
	var door_label: Label = Label.new()
	door_label.text = "↑ Дом героя"
	door_label.position = Vector2(570.0, 50.0)
	door_label.size = Vector2(140.0, 20.0)
	door_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	door_label.add_theme_font_size_override("font_size", 11)
	door_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7, 1.0))
	add_child(door_label)
	
	var return_trigger: InteractableObject = InteractableObject.create_interactable(
		"return_home_door",
		"Вход в дом",
		Vector2(640.0, 32.0),
		Vector2(100.0, 44.0),
		[],
		"[E] Войти в дом"
	)
	return_trigger.trigger_on_enter = true
	return_trigger.show_prompt_hint = false
	return_trigger.interacted.connect(_on_return_home_triggered)
	add_child(return_trigger)

func _on_return_home_triggered(_p: Player, _id: String) -> void:
	GameManager.transition_to_home(Vector2(640.0, 600.0))

## Создает временную боевую зону с красным фоном справа от тропинки для тестирования боя
func _setup_temp_test_battle_zone() -> void:
	var zone_pos: Vector2 = Vector2(850.0, 250.0)
	var zone_sz: Vector2 = Vector2(220.0, 160.0)
	
	var red_bg: ColorRect = ColorRect.new()
	red_bg.name = "TempBattleZoneRedBg"
	red_bg.position = zone_pos - (zone_sz / 2.0)
	red_bg.size = zone_sz
	red_bg.color = Color(0.85, 0.12, 0.12, 0.55)
	add_child(red_bg)
	
	var zone_label: Label = Label.new()
	zone_label.name = "TempBattleZoneLabel"
	zone_label.text = "ТЕСТОВАЯ БОЕВАЯ ЗОНА\n(зайдите для проверки Колеса Рун)"
	zone_label.position = zone_pos - Vector2(130.0, 22.0)
	zone_label.size = Vector2(260.0, 44.0)
	zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	zone_label.add_theme_font_size_override("font_size", 11)
	zone_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.92, 1.0))
	add_child(zone_label)
	
	var test_zone: BattleZone = BattleZone.new()
	test_zone.name = "TempRedTestBattleZone"
	test_zone.zone_name = "Тестовая зона боя"
	test_zone.position = zone_pos
	test_zone.zone_size = zone_sz
	test_zone.use_time_based_encounters = true
	test_zone.min_encounter_seconds = 0.5
	test_zone.max_encounter_seconds = 0.8
	test_zone.show_visual_marker = true
	test_zone.zone_color = Color(0.9, 0.15, 0.15, 0.25)
	test_zone.border_color = Color(1.0, 0.3, 0.3, 0.95)
	add_child(test_zone)

func _setup_player_and_camera() -> void:
	player = get_node_or_null("Player") as Player
	if player == null:
		if ResourceLoader.exists(PLAYER_SCENE_PATH):
			var packed: PackedScene = load(PLAYER_SCENE_PATH) as PackedScene
			if packed != null:
				var inst: Node = packed.instantiate()
				if not (inst is Player):
					inst.set_script(load("res://scripts/player.gd"))
				player = inst as Player
				player.name = "Player"
				add_child(player)
		if player == null:
			player = Player.new()
			player.name = "Player"
			add_child(player)
	
	player.scale = player_visual_scale
	player.speed = 180.0
	
	var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		player.add_child(camera)
	
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(VILLAGE_WIDTH)
	camera.limit_bottom = int(VILLAGE_HEIGHT)
	camera.editor_draw_limits = true
	
	if GameManager.saved_player_position == Vector2.ZERO:
		player.global_position = default_spawn_position

func _handle_return_from_battle() -> void:
	if GameManager.saved_player_position != Vector2.ZERO:
		if player != null:
			var target_pos: Vector2 = GameManager.saved_player_position
			# Если возвращаемся из боя внутри красной тестовой зоны (x > 720), сдвигаем чуть левее на безопасную тропу
			if target_pos.x > 720.0:
				target_pos.x = 680.0
			player.global_position = target_pos
			player.unlock_movement()
		GameManager.saved_player_position = Vector2.ZERO

func _setup_village_battle_zone() -> void:
	var zone: BattleZone = BattleZone.new()
	zone.name = "VillageOutskirtsBattleZone"
	zone.zone_name = "Окрестности Деревни"
	zone.position = Vector2(VILLAGE_WIDTH / 2.0, VILLAGE_HEIGHT / 2.0)
	zone.zone_size = Vector2(VILLAGE_WIDTH, VILLAGE_HEIGHT)
	zone.use_time_based_encounters = true
	zone.min_encounter_seconds = 30.0
	zone.max_encounter_seconds = 45.0
	zone.show_visual_marker = false
	add_child(zone)
