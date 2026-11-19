# res://scripts/game_manager.gd
extends Node

## Сигналы перехода состояний игры
signal battle_started(enemy: EnemyData)
signal battle_ended(victory: bool, by_vow: bool)
signal location_changed(location_id: String)

## Сохраненная позиция игрока в мире перед битвой или при переходе между локациями
var saved_player_position: Vector2 = Vector2.ZERO
## Флаг наличия валидной сохраненной позиции (чтобы корректно обрабатывать даже (0, 0))
var has_saved_player_position: bool = false
## Путь к сцене, из которой начался бой, для точного возврата
var saved_return_scene_path: String = ""
## Текущая активная локация мира ("home" или "village")
var current_location_id: String = "home"
## Данные текущего противника
var current_enemy: EnemyData = null
## Флаг нахождения в битве
var is_in_battle: bool = false

## Задержка после окончания/побега из боя (сек), чтобы бой не начался повторно мгновенно
@export var post_battle_grace_seconds: float = 2.5
var _post_battle_grace_until_msec: int = 0

## Пути к сценам
@export var overworld_scene_path: String = "res://scenes/battle_arena.tscn"
@export var village_scene_path: String = "res://scenes/village_location.tscn"
@export var battle_scene_path: String = "res://scenes/battle_scene.tscn"

## Сбрасывает сохраненную позицию игрока после восстановления
func clear_saved_player_position() -> void:
	has_saved_player_position = false
	saved_player_position = Vector2.ZERO

## Проверяет, активен ли защитный интервал после завершения/побега из боя
func is_in_post_battle_grace() -> bool:
	return Time.get_ticks_msec() < _post_battle_grace_until_msec

## Запуск битвы: сохраняет позицию и текущую сцену и переносит на боевую арену
func start_battle(enemy: EnemyData, player_pos: Vector2) -> void:
	if is_in_battle:
		return
	
	is_in_battle = true
	saved_player_position = player_pos
	has_saved_player_position = true
	
	var current_scene: Node = get_tree().current_scene
	if current_scene != null and not current_scene.scene_file_path.is_empty():
		saved_return_scene_path = current_scene.scene_file_path
	else:
		saved_return_scene_path = ""
	
	current_enemy = enemy.clone()
	battle_started.emit(current_enemy)
	
	_transition_to_battle()

## Возврат в открытый мир после боя
func return_to_overworld(victory: bool, by_vow: bool) -> void:
	is_in_battle = false
	_post_battle_grace_until_msec = Time.get_ticks_msec() + int(round(post_battle_grace_seconds * 1000.0))
	battle_ended.emit(victory, by_vow)
	
	_transition_to_overworld()

func _transition_to_battle() -> void:
	# Проверяем, существует ли файл battle_scene.tscn
	if ResourceLoader.exists(battle_scene_path):
		var battle_packed: PackedScene = load(battle_scene_path) as PackedScene
		if battle_packed != null:
			get_tree().change_scene_to_packed(battle_packed)
			return
	
	# Если файла сцены .tscn нет, инстанциируем боевую арену программно
	var battle_node: BattleScene = BattleScene.new()
	battle_node.init_battle(current_enemy, saved_player_position)
	
	var current: Node = get_tree().current_scene
	if current != null:
		current.queue_free()
	
	get_tree().root.add_child(battle_node)
	get_tree().current_scene = battle_node

## Переход в локацию Деревня (с зеленым фоном-заглушкой, если .tscn еще не создан)
func transition_to_village(spawn_pos: Vector2 = Vector2(640.0, 140.0)) -> void:
	current_location_id = "village"
	saved_player_position = spawn_pos
	has_saved_player_position = true
	saved_return_scene_path = ""
	location_changed.emit(current_location_id)
	call_deferred("_switch_to_village_scene")

## Возврат в стартовую локацию (Дом героя)
func transition_to_home(spawn_pos: Vector2 = Vector2(640.0, 295.0)) -> void:
	current_location_id = "home"
	saved_player_position = spawn_pos
	has_saved_player_position = true
	saved_return_scene_path = ""
	location_changed.emit(current_location_id)
	call_deferred("_switch_to_home_scene")

func _switch_to_village_scene() -> void:
	if ResourceLoader.exists(village_scene_path):
		get_tree().change_scene_to_file(village_scene_path)
		return
	
	var village_node: VillageLocation = VillageLocation.new()
	var current: Node = get_tree().current_scene
	if current != null:
		current.queue_free()
	
	get_tree().root.add_child(village_node)
	get_tree().current_scene = village_node

func _switch_to_home_scene() -> void:
	if ResourceLoader.exists(overworld_scene_path):
		get_tree().change_scene_to_file(overworld_scene_path)
	else:
		push_error("Сцена дома не найдена по пути: " + overworld_scene_path)

func _transition_to_overworld() -> void:
	if not saved_return_scene_path.is_empty() and ResourceLoader.exists(saved_return_scene_path):
		var target_scene_path: String = saved_return_scene_path
		saved_return_scene_path = ""
		get_tree().change_scene_to_file(target_scene_path)
		return
	
	if current_location_id == "village":
		_switch_to_village_scene()
	else:
		_switch_to_home_scene()
