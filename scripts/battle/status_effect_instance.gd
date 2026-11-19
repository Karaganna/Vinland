# res://scripts/battle/status_effect_instance.gd
class_name StatusEffectInstance
extends RefCounted

## Runtime-экземпляр активного статус-эффекта на бойце
var status_type: BattleTypes.StatusType = BattleTypes.StatusType.STAGGER
var remaining_turns: int = 1
var source_combatant_id: String = ""
var magnitude: float = 1.0
var guaranteed_crit_against: bool = false

func _init(
	p_type: BattleTypes.StatusType = BattleTypes.StatusType.STAGGER,
	p_turns: int = 1,
	p_source_id: String = "",
	p_magnitude: float = 1.0,
	p_guaranteed_crit: bool = false
) -> void:
	status_type = p_type
	remaining_turns = maxi(1, p_turns)
	source_combatant_id = p_source_id
	magnitude = p_magnitude
	guaranteed_crit_against = p_guaranteed_crit

## Уменьшает счетчик длительности на 1 ход и возвращает true, если статус истек
func tick_turn() -> bool:
	remaining_turns -= 1
	return remaining_turns <= 0

## Возвращает true, если статус относится к эффектам контроля (снижает Ярость)
func is_control_status() -> bool:
	return (
		status_type == BattleTypes.StatusType.SLEEP
		or status_type == BattleTypes.StatusType.HYPNOSIS
		or status_type == BattleTypes.StatusType.CALM
	)
