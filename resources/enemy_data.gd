# res://resources/enemy_data.gd
class_name EnemyData
extends Resource

@export var enemy_name: String = "Теневой Скиталец"
@export var max_hp: int = 60
@export var current_hp: int = 60
@export var attack_power: int = 12

## Характеристики Завета / Примирения (Dual Victory Condition)
@export var max_resolve: int = 100
@export var current_resolve: int = 0
@export var resolve_per_vow: int = 35

## Визуальные настройки врага
@export var sprite_color: Color = Color(0.85, 0.25, 0.25, 1.0)

## Тексты диалогов и реакции в бою (разбиваются по 1 предложению на нажатие кнопки действия)
@export_group("Диалоги")
@export_multiline var dialogue_intro: String = "Перед вами возникает Теневой Скиталец! Его призрачный силуэт окутан холодным туманом. Он преграждает путь."
@export_multiline var dialogue_on_attack: String = "Скиталец содрогается от боли. Он собирает остатки сил для ответного удара!"
@export_multiline var dialogue_on_vow: String = "Слова Завета проникают сквозь тьму в его сердце. Дух колеблется и вспоминает давно забытый свет."
@export_multiline var dialogue_pacified: String = "Скиталец обретает покой и склоняет голову. Он благословляет вас и мирно растворяется в свете."
@export_multiline var dialogue_defeat: String = "Теневой Скиталец рассеивается в воздухе. Бой окончен."

func clone() -> EnemyData:
	var copy: EnemyData = EnemyData.new()
	copy.enemy_name = enemy_name
	copy.max_hp = max_hp
	copy.current_hp = max_hp
	copy.attack_power = attack_power
	copy.max_resolve = max_resolve
	copy.current_resolve = current_resolve
	copy.resolve_per_vow = resolve_per_vow
	copy.sprite_color = sprite_color
	copy.dialogue_intro = dialogue_intro
	copy.dialogue_on_attack = dialogue_on_attack
	copy.dialogue_on_vow = dialogue_on_vow
	copy.dialogue_pacified = dialogue_pacified
	copy.dialogue_defeat = dialogue_defeat
	return copy
