# res://resources/battle/qte_config_data.gd
class_name QTEConfigData
extends Resource

## Конфигурация всех 8 типов мини-игр QTE
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

@export_group("Ритм-дорожка (RHYTHM_TRACK)")
@export var bpm: float = 120.0
@export var note_count: int = 6
@export var note_lanes: Array[int] = []
@export var note_beat_offsets: Array[float] = []
@export var apply_status_on_fail: bool = false
@export var fail_status_to_apply: BattleTypes.StatusType = BattleTypes.StatusType.SLEEP
@export var fail_status_duration: int = 2

@export_group("Удержание (HOLD_RELEASE)")
@export_range(0.35, 0.90, 0.01) var hold_target_center: float = 0.75
@export var hold_charge_speed: float = 0.72

@export_group("Серия (SERIES_CHAIN)")
@export_range(2, 6, 1) var series_max_steps: int = 4
@export var series_speed_step_bonus: float = 0.18

@export_group("Вязь знаков (RUNE_SEQUENCE)")
@export_range(3, 6, 1) var sequence_length: int = 4
@export var sequence_preview_step_sec: float = 0.32

@export_group("Рывок (RUSH_MASH)")
@export_range(4, 24, 1) var mash_target_presses: int = 10
@export var mash_decay_per_second: float = 0.16

@export_group("Бросок костей (DICE_ROLL)")
@export_range(1, 5, 1) var dice_count: int = 3
@export var dice_cycle_hz: float = 7.5
