# res://scripts/battle_arena.gd
class_name BattleArena
extends Node2D

@onready var attack_btn: Button = $BattleUI/ActionMenu/AttackButton
@onready var vow_btn: Button = $BattleUI/ActionMenu/VowButton
@onready var song_btn: Button = $BattleUI/ActionMenu/SongButton
@onready var item_btn: Button = $BattleUI/ActionMenu/ItemButton
@onready var player: Player = $Player

func _ready() -> void:
	# Подключаем сигналы кнопок меню
	attack_btn.pressed.connect(_on_attack_pressed)
	vow_btn.pressed.connect(_on_vow_pressed)
	song_btn.pressed.connect(_on_song_pressed)
	item_btn.pressed.connect(_on_item_pressed)
	
	# Автоматический фокус на первую кнопку для управления с клавиатуры
	attack_btn.grab_focus()

func _on_attack_pressed() -> void:
	print("Выбрано действие: Атака")

func _on_vow_pressed() -> void:
	print("Выбрано действие: Завет / Слово")

func _on_song_pressed() -> void:
	print("Выбрано действие: Песнь (Ритм)")

func _on_item_pressed() -> void:
	print("Выбрано действие: Предмет")
