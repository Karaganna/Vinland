# res://scripts/player.gd
class_name Player
extends CharacterBody2D

## Сигнал, оповещающий об окончании анимации восклицательного знака
signal encounter_alert_finished

@export var speed: float = 120.0
@export var is_movement_locked: bool = false
@export var walk_animation_fps: float = 9.0

## Совместимое свойство блокировки (синхронизировано с is_movement_locked)
var is_locked: bool = false: set = _set_is_locked, get = _get_is_locked

## Флаг для координации порядка _ready() с контроллером локации
var restored_position_on_ready: bool = false

const WALK_SPRITES_BASE_PATH: String = "res://assets/sprites/player/walk"
const MAX_WALK_FRAMES: int = 32

## Узел для отображения восклицательного знака над головой
var _alert_marker: Node2D = null
## Анимированный спрайт персонажа
var _animated_sprite: AnimatedSprite2D = null
## Последнее направление взгляда ("left", "right", "up", "down")
var _last_facing_dir: String = "right"

func _ready() -> void:
	add_to_group("player")
	_setup_collision_bounds()
	_setup_animated_sprite()
	_setup_alert_marker()
	_restore_return_position_if_needed()

## Проверяет в GameManager возврат из боя, восстанавливает позицию и снимает блокировку
func _restore_return_position_if_needed() -> void:
	restored_position_on_ready = false
	if GameManager == null:
		return
	if GameManager.has_return_position:
		var return_data: Dictionary = GameManager.consume_return_position()
		if bool(return_data.get("valid", false)):
			if return_data.has("position") and return_data["position"] is Vector2:
				global_position = return_data["position"] as Vector2
			restored_position_on_ready = true
			unlock_movement()

func _setup_collision_bounds() -> void:
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if col != null and col.shape is RectangleShape2D:
		var rect_shape: RectangleShape2D = col.shape.duplicate() as RectangleShape2D
		rect_shape.size = Vector2(16.0, 10.0)
		col.shape = rect_shape
		col.position = Vector2(0.0, 27.0)

func _physics_process(_delta: float) -> void:
	if is_movement_locked:
		velocity = Vector2.ZERO
		_update_walk_animation(Vector2.ZERO)
		move_and_slide()
		return
	
	var direction: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	velocity = direction * speed
	_update_walk_animation(direction)
	move_and_slide()

## Настраивает AnimatedSprite2D и загружает доступные кадры ходьбы
func _setup_animated_sprite() -> void:
	_animated_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if _animated_sprite == null:
		_animated_sprite = AnimatedSprite2D.new()
		_animated_sprite.name = "AnimatedSprite2D"
		add_child(_animated_sprite)
	
	_animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	var frames: SpriteFrames = SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	
	var directions: Array[String] = ["left", "right", "up", "down"]
	var has_any_frames: bool = false
	for dir_name: String in directions:
		if _load_direction_frames(frames, dir_name):
			has_any_frames = true
	
	_animated_sprite.sprite_frames = frames
	
	if has_any_frames:
		# Скрываем временные заглушки (ColorRect / старый Sprite2D), если они есть
		var placeholder_rect: ColorRect = get_node_or_null("ColorRect") as ColorRect
		if placeholder_rect != null:
			placeholder_rect.visible = false
		var placeholder_sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
		if placeholder_sprite != null:
			placeholder_sprite.visible = false
		
		var initial_anim: String = "walk_" + _last_facing_dir
		if frames.has_animation(initial_anim):
			_animated_sprite.animation = initial_anim
			_animated_sprite.frame = 0

## Динамически загружает кадры ходьбы (sprite_0.png .. sprite_N.png) для указанного направления
func _load_direction_frames(frames: SpriteFrames, dir_name: String) -> bool:
	var loaded_textures: Array[Texture2D] = []
	for i: int in range(MAX_WALK_FRAMES):
		var path: String = "%s/%s/sprite_%d.png" % [WALK_SPRITES_BASE_PATH, dir_name, i]
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex != null:
				loaded_textures.append(tex)
		elif i == 0:
			continue
		else:
			break
	
	if loaded_textures.is_empty():
		return false
	
	var anim_name: String = "walk_" + dir_name
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, true)
	frames.set_animation_speed(anim_name, walk_animation_fps)
	for tex: Texture2D in loaded_textures:
		frames.add_frame(anim_name, tex)
	return true

## Обновляет анимацию ходьбы в зависимости от вектора движения
func _update_walk_animation(direction: Vector2) -> void:
	if _animated_sprite == null or _animated_sprite.sprite_frames == null:
		return
	
	var frames: SpriteFrames = _animated_sprite.sprite_frames
	if direction == Vector2.ZERO:
		if _animated_sprite.is_playing():
			_animated_sprite.stop()
		_animated_sprite.frame = 0
		return
	
	var target_dir: String = _last_facing_dir
	if absf(direction.x) > 0.01:
		target_dir = "left" if direction.x < 0.0 else "right"
		_last_facing_dir = target_dir
	elif absf(direction.y) > 0.01:
		var vertical_dir: String = "up" if direction.y < 0.0 else "down"
		if frames.has_animation("walk_" + vertical_dir):
			target_dir = vertical_dir
			_last_facing_dir = vertical_dir
	
	var anim_name: String = "walk_" + target_dir
	if not frames.has_animation(anim_name):
		# Фолбэк на доступную горизонтальную анимацию, пока нет спрайтов вверх/вниз
		if frames.has_animation("walk_right"):
			anim_name = "walk_right"
		elif frames.has_animation("walk_left"):
			anim_name = "walk_left"
		else:
			return
	
	if _animated_sprite.animation != anim_name or not _animated_sprite.is_playing():
		_animated_sprite.play(anim_name)

## Запускает отображение восклицательного знака при обнаружении битвы
func trigger_encounter_alert(duration: float = 0.75) -> void:
	is_movement_locked = true
	velocity = Vector2.ZERO
	_update_walk_animation(Vector2.ZERO)
	
	if _alert_marker == null:
		_setup_alert_marker()
	
	_alert_marker.visible = true
	_alert_marker.scale = Vector2.ZERO
	_alert_marker.position = Vector2(0.0, -36.0)
	
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
	_update_walk_animation(Vector2.ZERO)

func _get_is_locked() -> bool:
	return is_movement_locked

func _set_is_locked(value: bool) -> void:
	if value:
		lock_movement()
	else:
		unlock_movement()

## Процедурное создание пиксельного знака '!' над персонажем
func _setup_alert_marker() -> void:
	if _alert_marker != null:
		return
	
	_alert_marker = Node2D.new()
	_alert_marker.name = "AlertMarker"
	_alert_marker.position = Vector2(0.0, -36.0)
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
