# res://resources/battle/enemy_part_data.gd
class_name EnemyPartData
extends Resource

## Описание части тела / зоны атаки многосоставного противника
@export var part_id: String = "body"
@export var part_name: String = "Туловище"
@export var max_hp: int = 80
@export var armor: int = 4
@export var damage_multiplier: float = 1.0
@export_range(0.0, 2.0, 0.05) var shared_hp_transfer_ratio: float = 1.0

@export_group("Состояния и окна уязвимости")
@export var triggers_stagger_on_break: bool = false
@export var stagger_duration_turns: int = 1
@export var is_targetable_by_default: bool = true
@export var stay_targetable_when_broken: bool = false
@export var vulnerability_windows: Array[BattleTypes.VulnerabilityWindow] = []
@export var break_message: String = ""
