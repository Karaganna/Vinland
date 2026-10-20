# res://scripts/player.gd
class_name Player
extends CharacterBody2D

## Сигнал, оповещающий об окончании анимации восклицательного знака
signal encounter_alert_finished

@export var speed: float = 120.0
@export var is_movement_locked: bool = false

## Узел для отображения восклицательного знака над головой
var _alert_marker: Node2D = null

func _ready() -> void:
	add_to_group("player")
	_setup_alert_marker()

func _physics_process(_delta: float) -> void:
	if is_movement_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var direction: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	velocity = direction * speed
	move_and_slide()

## Запускает отображение восклицательного знака при обнаружении битвы
func trigger_encounter_alert(duration: float = 0.75) -> void:
	is_movement_locked = true
	velocity = Vector2.ZERO
	
	if _alert_marker == null:
		_setup_alert_marker()
	
	_alert_marker.visible = true
	_alert_marker.scale = Vector2.ZERO
	_alert_marker.position = Vector2(0.0, -18.0)
	
	var tween: Tween = create_tween().set_parallel(false)
	# Эффект выпрыгивания знака вверх
	tween.tween_property(_alert_marker, "scale", Vector2(1.3, 1.3), 0.15)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(_alert_marker, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Небольшая пауза для эффекта неожиданности
	await get_tree().create_timer(duration).timeout
	
	encounter_alert_finished.emit()

func hide_encounter_alert() -> void:
	if _alert_marker != null:
		_alert_marker.visible = false

func unlock_movement() -> void:
	is_movement_locked = false
	hide_encounter_alert()

func lock_movement() -> void:
	is_movement_locked = true
	velocity = Vector2.ZERO

## Процедурное создание пиксельного знака '!' над персонажем
func _setup_alert_marker() -> void:
	if _alert_marker != null:
		return
	
	_alert_marker = Node2D.new()
	_alert_marker.name = "AlertMarker"
	_alert_marker.position = Vector2(0.0, -18.0)
	_alert_marker.visible = false
	_alert_marker.z_index = 10
	add_child(_alert_marker)
	
	# Фон знака (темная рамка и желтый фон)
	var bg: ColorRect = ColorRect.new()
	bg.name = "AlertBackground"
	bg.size = Vector2(12.0, 14.0)
	bg.position = Vector2(-6.0, -14.0)
	bg.color = Color(0.1, 0.1, 0.12, 1.0)
	_alert_marker.add_child(bg)
	
	var inner: ColorRect = ColorRect.new()
	inner.name = "AlertInner"
	inner.size = Vector2(10.0, 12.0)
	inner.position = Vector2(-5.0, -13.0)
	inner.color = Color(1.0, 0.85, 0.1, 1.0) # Ярко-желтый цвет JRPG предупреждения
	_alert_marker.add_child(inner)
	
	# Верхняя черта восклицательного знака
	var bar: ColorRect = ColorRect.new()
	bar.name = "AlertBar"
	bar.size = Vector2(2.0, 6.0)
	bar.position = Vector2(-1.0, -12.0)
	bar.color = Color(0.1, 0.1, 0.12, 1.0)
	_alert_marker.add_child(bar)
	
	# Точка восклицательного знака
	var dot: ColorRect = ColorRect.new()
	dot.name = "AlertDot"
	dot.size = Vector2(2.0, 2.0)
	dot.position = Vector2(-1.0, -4.0)
	dot.color = Color(0.1, 0.1, 0.12, 1.0)
	_alert_marker.add_child(dot)
