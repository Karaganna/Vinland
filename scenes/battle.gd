# res://scenes/battle.gd
class_name BattleArena
extends Node2D

@onready var player: Player = $Player

func _ready() -> void:
	_handle_return_from_battle()
	_ensure_battle_zone_exists()

## Восстанавливает позицию игрока и разблокирует управление при возврате из боя
func _handle_return_from_battle() -> void:
	if GameManager.saved_player_position != Vector2.ZERO:
		if player != null:
			player.global_position = GameManager.saved_player_position
			player.unlock_movement()
		# Сбрасываем позицию после успешного восстановления
		GameManager.saved_player_position = Vector2.ZERO

## Проверяет наличие боевых зон и создает демонстрационную зону, если сцена пуста
func _ensure_battle_zone_exists() -> void:
	var existing_zones: Array[Node] = get_tree().get_nodes_in_group("battle_zones")
	if existing_zones.is_empty():
		_create_default_battle_zone()

## Создает демонстрационную боевую локацию на карте мира
func _create_default_battle_zone() -> void:
	var demo_zone: BattleZone = BattleZone.new()
	demo_zone.name = "BattleZone_Grassland"
	demo_zone.zone_name = "Опасная пустошь (Боевая локация)"
	demo_zone.position = Vector2(1200.0, 540.0)
	demo_zone.zone_size = Vector2(600.0, 500.0)
	demo_zone.encounter_rate = 0.35 # 35% шанс при шаге для комфортного тестирования
	demo_zone.step_interval = 40.0
	demo_zone.entry_grace_distance = 50.0
	demo_zone.show_visual_marker = true
	add_child(demo_zone)
