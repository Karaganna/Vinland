# res://scripts/game_manager.gd
extends Node

## Сигналы перехода состояний игры
signal battle_started(enemy: EnemyData)
signal battle_ended(victory: bool, by_vow: bool)

## Сохраненная позиция игрока в мире перед битвой
var saved_player_position: Vector2 = Vector2.ZERO
## Данные текущего противника
var current_enemy: EnemyData = null
## Флаг нахождения в битве
var is_in_battle: bool = false

## Пути к сценам
@export var overworld_scene_path: String = "res://scenes/battle_arena.tscn"
@export var battle_scene_path: String = "res://scenes/battle_scene.tscn"

## Запуск битвы: сохраняет позицию и переносит на боевую арену
func start_battle(enemy: EnemyData, player_pos: Vector2) -> void:
	if is_in_battle:
		return
	
	is_in_battle = true
	saved_player_position = player_pos
	current_enemy = enemy.clone()
	battle_started.emit(current_enemy)
	
	_transition_to_battle()

## Возврат в открытый мир после боя
func return_to_overworld(victory: bool, by_vow: bool) -> void:
	is_in_battle = false
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

func _transition_to_overworld() -> void:
	if ResourceLoader.exists(overworld_scene_path):
		get_tree().change_scene_to_file(overworld_scene_path)
	else:
		push_error("Сцена мира не найдена по пути: " + overworld_scene_path)
