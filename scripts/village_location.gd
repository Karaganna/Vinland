# res://scripts/village_location.gd
class_name VillageLocation
extends Node2D

const VILLAGE_WIDTH: float = 1672.0
const VILLAGE_HEIGHT: float = 941.0
const PLAYER_SCENE_PATH: String = "res://scenes/Player.tscn"

## Стартовая позиция перед дверью верхнего левого дома героя (с запасом ниже HouseDoorTrigger)
@export var default_spawn_position: Vector2 = Vector2(340.0, 356.0)
@export var player_visual_scale: Vector2 = Vector2(1.0, 1.0)
## Создавать ли программные границы по краям карты, если в сцене нет WorldCollisions
@export var enable_map_boundaries: bool = true
## Деревня по умолчанию является полностью безопасной локацией
@export var enable_random_encounters: bool = false
## Показывать и активировать ли тестовую боевую зону на свободной площади
@export var enable_temp_test_battle_zone: bool = true
## Защита от случайного срабатывания дверного триггера в первые доли секунды после входа в сцену
@export_range(0.0, 2.0, 0.05) var door_entry_grace_seconds: float = 0.45

var player: Player = null
var _inventory_overlay: InventoryMenuOverlay = null
var _scene_enter_grace_until_msec: int = 0

func _ready() -> void:
	GameManager.current_location_id = "village"
	_scene_enter_grace_until_msec = Time.get_ticks_msec() + roundi(door_entry_grace_seconds * 1000.0)
	
	if not _has_map_background():
		_setup_green_background()
	if get_node_or_null("WorldCollisions") == null:
		_setup_boundaries()
	
	_setup_return_to_house_zone()
	_setup_temp_test_battle_zone()
	if enable_random_encounters:
		_setup_village_battle_zone()
	_setup_player_and_camera()
	_handle_return_from_battle()
	_setup_inventory_overlay()

func _has_map_background() -> bool:
	var sprite: Sprite2D = get_node_or_null("GroundLayer/MapBackground") as Sprite2D
	return sprite != null and sprite.texture != null

func _transform_control_rect(ctrl: Control, xform: Transform2D) -> Rect2:
	var p0: Vector2 = xform * Vector2.ZERO
	var p1: Vector2 = xform * ctrl.size
	return Rect2(p0.min(p1), (p1 - p0).abs())

func _get_sprite_local_size(sprite: Sprite2D) -> Vector2:
	if sprite.region_enabled:
		return sprite.region_rect.size
	if sprite.texture != null:
		return sprite.texture.get_size()
	return Vector2.ZERO

func _get_local_map_bounds() -> Rect2:
	var map_sprite: Sprite2D = get_node_or_null("GroundLayer/MapBackground") as Sprite2D
	if map_sprite != null and map_sprite.texture != null:
		var tex_size: Vector2 = _get_sprite_local_size(map_sprite)
		var origin: Vector2 = (-tex_size / 2.0 if map_sprite.centered else Vector2.ZERO) + map_sprite.offset
		var xform: Transform2D = map_sprite.get_transform()
		var ground_layer: Node2D = get_node_or_null("GroundLayer") as Node2D
		if ground_layer != null:
			xform = ground_layer.get_transform() * xform
		var p0: Vector2 = xform * origin
		var p1: Vector2 = xform * (origin + tex_size)
		return Rect2(p0.min(p1), (p1 - p0).abs())
	
	var bg: Control = get_node_or_null("VillageGreenBackground") as Control
	if bg != null:
		return _transform_control_rect(bg, bg.get_transform())
	return Rect2(0.0, 0.0, VILLAGE_WIDTH, VILLAGE_HEIGHT)

func _get_global_map_bounds() -> Rect2:
	var map_sprite: Sprite2D = get_node_or_null("GroundLayer/MapBackground") as Sprite2D
	if map_sprite != null and map_sprite.texture != null:
		var tex_size: Vector2 = _get_sprite_local_size(map_sprite)
		var origin: Vector2 = (-tex_size / 2.0 if map_sprite.centered else Vector2.ZERO) + map_sprite.offset
		var xform: Transform2D = map_sprite.get_global_transform()
		var p0: Vector2 = xform * origin
		var p1: Vector2 = xform * (origin + tex_size)
		return Rect2(p0.min(p1), (p1 - p0).abs())
	
	var bg: Control = get_node_or_null("VillageGreenBackground") as Control
	if bg != null:
		return _transform_control_rect(bg, bg.get_global_transform())
	var local_rect: Rect2 = _get_local_map_bounds()
	var root_xform: Transform2D = get_global_transform()
	var gp0: Vector2 = root_xform * local_rect.position
	var gp1: Vector2 = root_xform * local_rect.end
	return Rect2(gp0.min(gp1), (gp1 - gp0).abs())

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
	var door_trigger: InteractableObject = get_node_or_null("Triggers/HouseDoorTrigger") as InteractableObject
	if door_trigger == null:
		door_trigger = get_node_or_null("Interactable_return_home_door") as InteractableObject
	
	if door_trigger != null:
		door_trigger.trigger_on_enter = true
		door_trigger.show_prompt_hint = false
		if not door_trigger.interacted.is_connected(_on_return_home_triggered):
			door_trigger.interacted.connect(_on_return_home_triggered)
		return
	
	# Программный фолбэк, если сцена собрана без узлов Triggers
	var door_pos: Vector2 = Vector2(340.0, 330.0)
	var door_sz: Vector2 = Vector2(36.0, 14.0)
	var triggers_root: Node = get_node_or_null("Triggers")
	var target_parent: Node = triggers_root if triggers_root != null else self
	var fallback_trigger: InteractableObject = InteractableObject.create_interactable(
		"return_home_door",
		"Вход в дом",
		door_pos,
		door_sz,
		[],
		"[E] Войти в дом"
	)
	fallback_trigger.trigger_on_enter = true
	fallback_trigger.show_prompt_hint = false
	fallback_trigger.interacted.connect(_on_return_home_triggered)
	target_parent.add_child(fallback_trigger)

func _on_return_home_triggered(p: Player, _id: String) -> void:
	if Time.get_ticks_msec() < _scene_enter_grace_until_msec:
		return
	if p != null and p.is_locked:
		return
	GameManager.transition_to_home(Vector2(640.0, 600.0))

## Настраивает или обновляет видимость/активность тестовой боевой зоны на свободной площади
func _setup_temp_test_battle_zone() -> void:
	var test_zone: BattleZone = get_node_or_null("Triggers/TempRedTestBattleZone") as BattleZone
	if test_zone == null:
		test_zone = get_node_or_null("TempRedTestBattleZone") as BattleZone
	
	if test_zone != null:
		test_zone.visible = enable_temp_test_battle_zone
		test_zone.set_deferred("monitoring", enable_temp_test_battle_zone)
		test_zone.set_deferred("monitorable", enable_temp_test_battle_zone)
		return
	
	if not enable_temp_test_battle_zone:
		return
	
	var triggers_root: Node = get_node_or_null("Triggers")
	var target_parent: Node = triggers_root if triggers_root != null else self
	test_zone = BattleZone.new()
	test_zone.name = "TempRedTestBattleZone"
	test_zone.zone_name = "Тестовая зона боя"
	test_zone.position = Vector2(695.0, 680.0)
	test_zone.zone_size = Vector2(140.0, 96.0)
	test_zone.use_time_based_encounters = true
	test_zone.min_encounter_seconds = 0.5
	test_zone.max_encounter_seconds = 0.8
	test_zone.show_visual_marker = true
	test_zone.zone_color = Color(0.9, 0.15, 0.15, 0.25)
	test_zone.border_color = Color(1.0, 0.3, 0.3, 0.95)
	target_parent.add_child(test_zone)

func _setup_player_and_camera() -> void:
	player = get_node_or_null("YSortWorld/Player") as Player
	if player == null:
		player = get_node_or_null("Player") as Player
	
	if player == null:
		var y_sort_root: Node = get_node_or_null("YSortWorld")
		var spawn_parent: Node = y_sort_root if y_sort_root != null else self
		if ResourceLoader.exists(PLAYER_SCENE_PATH):
			var packed: PackedScene = load(PLAYER_SCENE_PATH) as PackedScene
			if packed != null:
				var inst: Node = packed.instantiate()
				if not (inst is Player):
					inst.set_script(load("res://scripts/player.gd"))
				player = inst as Player
				player.name = "Player"
				spawn_parent.add_child(player)
		if player == null:
			player = Player.new()
			player.name = "Player"
			spawn_parent.add_child(player)
	
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
	
	if not player.restored_position_on_ready and not GameManager.has_saved_player_position and not GameManager.has_return_position:
		player.global_position = default_spawn_position
		player.set_facing_direction("down")

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
			player.set_facing_direction("down")
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
