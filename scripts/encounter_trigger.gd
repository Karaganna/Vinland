# res://scripts/encounter_trigger.gd
class_name EncounterTrigger
extends Area2D

## Сигнал о запуске боевой встречи (снизу вверх)
signal encounter_started(enemy: EnemyData, resolved_encounter_id: String)

@export var enemy_data: EnemyData = null
## Уникальный ID триггера; если пуст — строится автоматически из пути сцены и имени узла
@export var encounter_id: String = ""
@export var battle_scene_path: String = "res://scenes/battle_sandbox.tscn"
@export var disable_after_victory: bool = true
@export var fallback_to_young_dragon: bool = false

var _is_triggered: bool = false

func _ready() -> void:
	var resolved_id: String = get_resolved_encounter_id()
	if disable_after_victory and GameManager != null and GameManager.is_encounter_defeated(resolved_id):
		_disable_trigger_permanently()
		return
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

## Возвращает стабильный идентификатор энкаунтера для реестра побежденных триггеров
func get_resolved_encounter_id() -> String:
	var explicit_id: String = encounter_id.strip_edges()
	if not explicit_id.is_empty():
		return explicit_id
	
	var scene_path: String = ""
	var node_rel_path: String = String(name)
	var tree: SceneTree = get_tree()
	if tree != null and tree.current_scene != null:
		scene_path = tree.current_scene.scene_file_path
		if is_inside_tree() and tree.current_scene.is_ancestor_of(self):
			node_rel_path = String(tree.current_scene.get_path_to(self))
	elif not scene_file_path.is_empty():
		scene_path = scene_file_path
	
	if scene_path.is_empty():
		scene_path = "overworld"
	
	return "%s::%s" % [scene_path, node_rel_path]

func _on_body_entered(body: Node2D) -> void:
	if _is_triggered:
		return
	if not (body is Player):
		return
	
	var player_body: Player = body as Player
	if player_body.is_locked:
		return
	
	if GameManager == null:
		return
	if GameManager.is_in_battle or GameManager.is_in_post_battle_grace():
		return
	
	var resolved_id: String = get_resolved_encounter_id()
	if disable_after_victory and GameManager.is_encounter_defeated(resolved_id):
		_disable_trigger_permanently()
		return
	
	_is_triggered = true
	player_body.is_locked = true
	
	var current_scene: Node = get_tree().current_scene
	var return_scene: String = current_scene.scene_file_path if current_scene != null else ""
	var chosen_enemy: EnemyData = _resolve_enemy_data()
	
	encounter_started.emit(chosen_enemy, resolved_id)
	GameManager.start_battle(
		chosen_enemy,
		return_scene,
		player_body.global_position,
		resolved_id if disable_after_victory else "",
		battle_scene_path
	)

func _resolve_enemy_data() -> EnemyData:
	if enemy_data != null:
		return enemy_data.clone()
	if fallback_to_young_dragon:
		return BattleSandboxFactory.create_young_dragon()
	
	var legacy_enemy: EnemyData = EnemyData.new()
	legacy_enemy.enemy_id = "wild_forest_spirit"
	legacy_enemy.enemy_name = "Дикий Лесной Дух"
	legacy_enemy.max_hp = 50
	legacy_enemy.current_hp = 50
	legacy_enemy.attack_power = 10
	legacy_enemy.max_resolve = 100
	legacy_enemy.current_resolve = 0
	legacy_enemy.resolve_per_vow = 35
	legacy_enemy.dialogue_intro = "Из зарослей появляется Дикий Лесной Дух!"
	legacy_enemy.dialogue_on_attack = "Дух вздрагивает от удара и готовится напасть!"
	legacy_enemy.dialogue_on_vow = "Слова мира смягчают гнев духа..."
	legacy_enemy.dialogue_pacified = "Дух склоняет голову в знак примирения и уходит."
	legacy_enemy.dialogue_defeat = "Дух растворяется в листве."
	return legacy_enemy

func _disable_trigger_permanently() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	visible = false
	queue_free()
