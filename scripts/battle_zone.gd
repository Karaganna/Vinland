# res://scripts/battle_zone.gd
class_name BattleZone
extends Area2D

## Сигнал о начале случайной битвы в этой зоне
signal encounter_triggered(enemy: EnemyData)

@export_group("Настройки битвы")
@export var zone_name: String = "Опасная пустошь"
## Шанс встречи (от 0.0 до 1.0) при прохождении каждого интервала шагов
@export_range(0.01, 1.0, 0.01) var encounter_rate: float = 0.25
## Дистанция в пикселях, которую нужно пройти для проверки случайной битвы
@export var step_interval: float = 45.0
## Начальный буфер шагов при входе в зону (чтобы драка не начиналась мгновенно)
@export var entry_grace_distance: float = 60.0
## Список возможных противников для этой зоны (если пуст, создается базовый)
@export var possible_enemies: Array[EnemyData] = []

@export_group("Визуализация на карте")
## Показывать ли полупрозрачную подсветку боевой зоны на карте
@export var show_visual_marker: bool = true
@export var zone_color: Color = Color(0.85, 0.2, 0.2, 0.15)
@export var border_color: Color = Color(0.9, 0.3, 0.3, 0.6)
@export var zone_size: Vector2 = Vector2(400.0, 300.0)

var _player_in_zone: Player = null
var _accumulated_distance: float = 0.0
var _grace_distance_left: float = 0.0
var _is_encounter_active: bool = false
var _collision_shape: CollisionShape2D = null

func _ready() -> void:
	add_to_group("battle_zones")
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_ensure_collision_shape()
	queue_redraw()

func _ensure_collision_shape() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			_collision_shape = child
			return
	
	# Если коллизия не была настроена вручную в редакторе, создаем дефолтную
	_collision_shape = CollisionShape2D.new()
	var rect_shape: RectangleShape2D = RectangleShape2D.new()
	rect_shape.size = zone_size
	_collision_shape.shape = rect_shape
	add_child(_collision_shape)

func _physics_process(delta: float) -> void:
	if _player_in_zone == null or _is_encounter_active:
		return
	
	if _player_in_zone.is_movement_locked:
		return
	
	var current_velocity: Vector2 = _player_in_zone.velocity
	if current_velocity.length() > 5.0:
		var moved_dist: float = current_velocity.length() * delta
		
		# Сначала тратится льготная дистанция (grace buffer)
		if _grace_distance_left > 0.0:
			_grace_distance_left -= moved_dist
			return
		
		_accumulated_distance += moved_dist
		if _accumulated_distance >= step_interval:
			_accumulated_distance = 0.0
			_roll_for_encounter()

func _roll_for_encounter() -> void:
	var roll: float = randf()
	if roll <= encounter_rate:
		_start_encounter_sequence()

func _start_encounter_sequence() -> void:
	_is_encounter_active = true
	var enemy: EnemyData = _select_enemy()
	
	# Уведомляем систему через сигнал
	encounter_triggered.emit(enemy)
	
	# Над игроком появляется восклицательный знак
	if _player_in_zone != null:
		var player_ref: Player = _player_in_zone
		player_ref.trigger_encounter_alert(0.8)
		
		# Ожидаем завершения анимации восклицательного знака перед перемещением
		player_ref.encounter_alert_finished.connect(
			func() -> void:
				_on_alert_finished(enemy, player_ref.global_position),
			CONNECT_ONE_SHOT
		)

func _on_alert_finished(enemy: EnemyData, player_pos: Vector2) -> void:
	# Вызываем глобальный менеджер игры для перехода в боевую локацию
	GameManager.start_battle(enemy, player_pos)

func _select_enemy() -> EnemyData:
	if not possible_enemies.is_empty():
		var chosen: EnemyData = possible_enemies.pick_random()
		return chosen.clone()
	
	# Если врагов не задано, создаем дефолтного
	var default_enemy: EnemyData = EnemyData.new()
	default_enemy.enemy_name = "Дикий Лесной Дух"
	default_enemy.max_hp = 50
	default_enemy.current_hp = 50
	default_enemy.attack_power = 10
	default_enemy.max_resolve = 100
	default_enemy.current_resolve = 0
	default_enemy.resolve_per_vow = 35
	default_enemy.dialogue_intro = "Из зарослей появляется Дикий Лесной Дух!"
	default_enemy.dialogue_on_attack = "Дух вздрагивает от удара и готовится напасть!"
	default_enemy.dialogue_on_vow = "Слова мира смягчают гнев духа..."
	default_enemy.dialogue_pacified = "Дух склоняет голову в знак примирения и уходит."
	default_enemy.dialogue_defeat = "Дух растворяется в листве."
	return default_enemy

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_zone = body
		_accumulated_distance = 0.0
		_grace_distance_left = entry_grace_distance
		_is_encounter_active = false

func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_zone:
		_player_in_zone = null
		_accumulated_distance = 0.0

func _draw() -> void:
	if not show_visual_marker:
		return
	
	# Рисуем контур и заливку зоны для наглядности в мире
	var draw_rect_bounds: Rect2
	if _collision_shape != null and _collision_shape.shape is RectangleShape2D:
		var r_shape: RectangleShape2D = _collision_shape.shape as RectangleShape2D
		draw_rect_bounds = Rect2(-r_shape.size / 2.0, r_shape.size)
	else:
		draw_rect_bounds = Rect2(-zone_size / 2.0, zone_size)
	
	draw_rect(draw_rect_bounds, zone_color)
	draw_rect(draw_rect_bounds, border_color, false, 2.0)
	
	# Пиксельные угловые маркеры
	var corner_len: float = 12.0
	var top_left: Vector2 = draw_rect_bounds.position
	var bottom_right: Vector2 = draw_rect_bounds.end
	draw_line(top_left, top_left + Vector2(corner_len, 0.0), border_color, 3.0)
	draw_line(top_left, top_left + Vector2(0.0, corner_len), border_color, 3.0)
	draw_line(bottom_right, bottom_right - Vector2(corner_len, 0.0), border_color, 3.0)
	draw_line(bottom_right, bottom_right - Vector2(0.0, corner_len), border_color, 3.0)
