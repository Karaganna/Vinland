# res://scripts/village_location.gd
class_name VillageLocation
extends Node2D

const VILLAGE_WIDTH: float = 1280.0
const VILLAGE_HEIGHT: float = 783.0
const PLAYER_SCENE_PATH: String = "res://scenes/Player.tscn"

@export var default_spawn_position: Vector2 = Vector2(640.0, 140.0)
@export var player_visual_scale: Vector2 = Vector2(3.0, 3.0)
## Создавать ли невидимые границы по краям карты (подстраиваются под VillageGreenBackground)
@export var enable_map_boundaries: bool = true
## Деревня по умолчанию является полностью безопасной локацией
@export var enable_random_encounters: bool = false
## Временная красная зона для тестирования новой боевой системы с Колесом Рун
@export var enable_temp_test_battle_zone: bool = true

var player: Player = null

func _ready() -> void:
	GameManager.current_location_id = "village"
	_setup_green_background()
	_setup_boundaries()
	_setup_return_to_house_zone()
	if enable_temp_test_battle_zone:
		_setup_temp_test_battle_zone()
	if enable_random_encounters:
		_setup_village_battle_zone()
	_setup_player_and_camera()
	_handle_return_from_battle()

func _transform_control_rect(ctrl: Control, xform: Transform2D) -> Rect2:
	var p0: Vector2 = xform * Vector2.ZERO
	var p1: Vector2 = xform * ctrl.size
	return Rect2(p0.min(p1), (p1 - p0).abs())

func _get_local_map_bounds() -> Rect2:
	var bg: Control = get_node_or_null("VillageGreenBackground") as Control
	if bg != null:
		return _transform_control_rect(bg, bg.get_transform())
	return Rect2(0.0, 0.0, VILLAGE_WIDTH, VILLAGE_HEIGHT)

func _get_global_map_bounds() -> Rect2:
	var bg: Control = get_node_or_null("VillageGreenBackground") as Control
	if bg != null:
		return _transform_control_rect(bg, bg.get_global_transform())
	var local_rect: Rect2 = _get_local_map_bounds()
	var xform: Transform2D = get_global_transform()
	var p0: Vector2 = xform * local_rect.position
	var p1: Vector2 = xform * local_rect.end
	return Rect2(p0.min(p1), (p1 - p0).abs())

func _setup_green_background() -> void:
	var bg: ColorRect = get_node_or_null("VillageGreenBackground") as ColorRect
	if bg == null:
		bg = ColorRect.new()
		bg.name = "VillageGreenBackground"
		bg.position = Vector2.ZERO
		bg.size = Vector2(VILLAGE_WIDTH, VILLAGE_HEIGHT)
		bg.color = Color(0.18, 0.45, 0.22, 1.0)
		bg.z_index = -10
		add_child(bg)
		move_child(bg, 0)
	
	# Тропинка от входа в дом вниз
	var path_rect: ColorRect = get_node_or_null("VillagePathPlaceholder") as ColorRect
	if path_rect == null:
		path_rect = ColorRect.new()
		path_rect.name = "VillagePathPlaceholder"
		path_rect.position = Vector2(590.0, 0.0)
		path_rect.size = Vector2(100.0, VILLAGE_HEIGHT)
		path_rect.color = Color(0.36, 0.28, 0.18, 0.65)
		path_rect.z_index = -9
		add_child(path_rect)
	
	var bounds_rect: Rect2 = _get_local_map_bounds()
	var title_label: Label = get_node_or_null("VillagePlaceholderLabel") as Label
	if title_label == null:
		title_label = Label.new()
		title_label.name = "VillagePlaceholderLabel"
		title_label.text = "ДЕРЕВНЯ (безопасная локация — заглушка)"
		title_label.position = Vector2(bounds_rect.position.x, bounds_rect.position.y + 16.0)
		title_label.size = Vector2(bounds_rect.size.x, 32.0)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", 16)
		title_label.add_theme_color_override("font_color", Color(0.95, 0.98, 0.9, 0.9))
		add_child(title_label)

func _setup_boundaries() -> void:
	if not enable_map_boundaries or get_node_or_null("VillageBoundaries") != null:
		return
	
	var bounds: StaticBody2D = StaticBody2D.new()
	bounds.name = "VillageBoundaries"
	add_child(bounds)
	
	var bounds_rect: Rect2 = _get_local_map_bounds()
	var wall_thickness: float = 32.0
	var rects: Array[Rect2] = [
		Rect2(bounds_rect.position.x, bounds_rect.position.y - wall_thickness, bounds_rect.size.x, wall_thickness),
		Rect2(bounds_rect.position.x, bounds_rect.end.y, bounds_rect.size.x, wall_thickness),
		Rect2(bounds_rect.position.x - wall_thickness, bounds_rect.position.y, wall_thickness, bounds_rect.size.y),
		Rect2(bounds_rect.end.x, bounds_rect.position.y, wall_thickness, bounds_rect.size.y)
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
	var door_visual: ColorRect = get_node_or_null("HouseEntranceMarker") as ColorRect
	if door_visual == null:
		door_visual = ColorRect.new()
		door_visual.name = "HouseEntranceMarker"
		door_visual.position = Vector2(590.0, 0.0)
		door_visual.size = Vector2(100.0, 48.0)
		door_visual.color = Color(0.28, 0.18, 0.1, 1.0)
		door_visual.z_index = -8
		add_child(door_visual)
	
	var door_rect: Rect2 = _transform_control_rect(door_visual, door_visual.get_transform())
	
	var door_label: Label = get_node_or_null("HouseEntranceLabel") as Label
	if door_label == null:
		door_label = Label.new()
		door_label.name = "HouseEntranceLabel"
		door_label.text = "↑ Дом героя"
		door_label.position = Vector2(door_rect.get_center().x - 70.0, door_rect.end.y + 2.0)
		door_label.size = Vector2(140.0, 20.0)
		door_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		door_label.add_theme_font_size_override("font_size", 11)
		door_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7, 1.0))
		add_child(door_label)
	
	var return_trigger: InteractableObject = get_node_or_null("Interactable_return_home_door") as InteractableObject
	if return_trigger == null:
		return_trigger = InteractableObject.create_interactable(
			"return_home_door",
			"Вход в дом",
			door_rect.get_center(),
			door_rect.size,
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
	
	var red_bg: ColorRect = get_node_or_null("TempBattleZoneRedBg") as ColorRect
	if red_bg == null:
		red_bg = ColorRect.new()
		red_bg.name = "TempBattleZoneRedBg"
		red_bg.position = zone_pos - (zone_sz / 2.0)
		red_bg.size = zone_sz
		red_bg.color = Color(0.85, 0.12, 0.12, 0.55)
		red_bg.z_index = -8
		add_child(red_bg)
	else:
		var red_rect: Rect2 = _transform_control_rect(red_bg, red_bg.get_transform())
		zone_pos = red_rect.get_center()
		zone_sz = red_rect.size
	
	var zone_label: Label = get_node_or_null("TempBattleZoneLabel") as Label
	if zone_label == null:
		zone_label = Label.new()
		zone_label.name = "TempBattleZoneLabel"
		zone_label.text = "ТЕСТОВАЯ БОЕВАЯ ЗОНА\n(зайдите для проверки Колеса Рун)"
		zone_label.position = zone_pos - Vector2(130.0, 22.0)
		zone_label.size = Vector2(260.0, 44.0)
		zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		zone_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		zone_label.add_theme_font_size_override("font_size", 11)
		zone_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.92, 1.0))
		add_child(zone_label)
	
	var test_zone: BattleZone = get_node_or_null("TempRedTestBattleZone") as BattleZone
	if test_zone == null:
		test_zone = BattleZone.new()
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
	
	var global_bounds: Rect2 = _get_global_map_bounds()
	camera.limit_left = int(floor(global_bounds.position.x))
	camera.limit_top = int(floor(global_bounds.position.y))
	camera.limit_right = int(ceil(global_bounds.end.x))
	camera.limit_bottom = int(ceil(global_bounds.end.y))
	camera.editor_draw_limits = true
	
	if not GameManager.has_saved_player_position:
		player.global_position = default_spawn_position

func _handle_return_from_battle() -> void:
	if GameManager.has_saved_player_position:
		if player != null:
			player.global_position = GameManager.saved_player_position
			player.unlock_movement()
		GameManager.clear_saved_player_position()

func _setup_village_battle_zone() -> void:
	var bounds_rect: Rect2 = _get_local_map_bounds()
	var zone: BattleZone = BattleZone.new()
	zone.name = "VillageOutskirtsBattleZone"
	zone.zone_name = "Окрестности Деревни"
	zone.position = bounds_rect.get_center()
	zone.zone_size = bounds_rect.size
	zone.use_time_based_encounters = true
	zone.min_encounter_seconds = 30.0
	zone.max_encounter_seconds = 45.0
	zone.show_visual_marker = false
	add_child(zone)
