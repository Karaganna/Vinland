# res://resources/battle/qte_config_data.gd
class_name QTEConfigData
extends Resource

## Конфигурация мини-игры QTE (для атак, защитных блоков и звуковых ритм-партий)
@export var qte_type: BattleTypes.QTEType = BattleTypes.QTEType.NONE
@export var duration_seconds: float = 2.5
@export var cursor_speed: float = 1.4
@export_range(0.05, 0.5, 0.01) var success_zone_width: float = 0.22
@export_range(0.02, 0.25, 0.01) var perfect_zone_width: float = 0.08

@export_group("Пороги оценки")
@export var use_custom_thresholds: bool = false
@export_range(0.0, 1.0, 0.01) var miss_threshold: float = 0.30
@export_range(0.0, 1.0, 0.01) var weak_threshold: float = 0.60
@export_range(0.0, 1.0, 0.01) var perfect_threshold: float = 0.90
@export var miss_multiplier: float = 0.0
@export var weak_multiplier: float = 0.5
@export var normal_multiplier: float = 1.0
@export var perfect_multiplier: float = 1.5

@export_group("Ритм-дорожка (Falling Keys)")
@export var bpm: float = 120.0
@export var note_count: int = 6
@export var note_lanes: Array[int] = []
@export var note_beat_offsets: Array[float] = []
@export var apply_status_on_fail: bool = false
@export var fail_status_to_apply: BattleTypes.StatusType = BattleTypes.StatusType.SLEEP
@export var fail_status_duration: int = 2
