# res://scripts/battle/status_effect_instance.gd
class_name StatusEffectInstance
extends RefCounted

## Runtime-экземпляр активного статус-эффекта или боевой стойки на бойце
var status_type: BattleTypes.StatusType = BattleTypes.StatusType.STAGGER
var remaining_turns: int = 1
var is_permanent_in_battle: bool = false
var stacks: int = 1
var max_stacks: int = 5
var source_combatant_id: String = ""
var protected_ally_id: String = ""
var magnitude: float = 1.0
var barrier_hp: int = 0
var guaranteed_crit_against: bool = false

func _init(
	p_type: BattleTypes.StatusType = BattleTypes.StatusType.STAGGER,
	p_turns: int = 1,
	p_source_id: String = "",
	p_magnitude: float = 1.0,
	p_guaranteed_crit: bool = false,
	p_stacks: int = 1,
	p_permanent: bool = false,
	p_barrier_hp: int = 0,
	p_protected_ally_id: String = ""
) -> void:
	status_type = p_type
	remaining_turns = maxi(1, p_turns)
	is_permanent_in_battle = p_permanent
	stacks = clampi(p_stacks, 1, max_stacks)
	source_combatant_id = p_source_id
	protected_ally_id = p_protected_ally_id
	magnitude = p_magnitude
	barrier_hp = maxi(0, p_barrier_hp)
	guaranteed_crit_against = p_guaranteed_crit

## Добавляет стаки к стакающемуся статусу (например, BLEED или DEFENSE_DOWN)
func add_stacks(add_count: int, p_duration_turns: int, p_magnitude: float = -1.0) -> void:
	stacks = clampi(stacks + maxi(1, add_count), 1, max_stacks)
	if not is_permanent_in_battle:
		remaining_turns = maxi(remaining_turns, p_duration_turns)
	if p_magnitude > 0.0:
		magnitude = maxf(magnitude, p_magnitude)

## Уменьшает счетчик длительности на 1 ход и возвращает true, если статус истек
func tick_turn() -> bool:
	if status_type == BattleTypes.StatusType.SHIELD_BARRIER and barrier_hp <= 0:
		return true
	if is_permanent_in_battle:
		return false
	remaining_turns -= 1
	return remaining_turns <= 0

## Возвращает true, если статус относится к эффектам контроля (снижает Ярость)
func is_control_status() -> bool:
	return (
		status_type == BattleTypes.StatusType.SLEEP
		or status_type == BattleTypes.StatusType.HYPNOSIS
		or status_type == BattleTypes.StatusType.CALM
		or status_type == BattleTypes.StatusType.FREEZE
		or status_type == BattleTypes.StatusType.STUN
		or status_type == BattleTypes.StatusType.KNOCKED_DOWN
	)

## Возвращает true, если статус полностью блокирует выбор действия в ход бойца
func causes_turn_skip() -> bool:
	return (
		status_type == BattleTypes.StatusType.SLEEP
		or status_type == BattleTypes.StatusType.STAGGER
		or status_type == BattleTypes.StatusType.FREEZE
		or status_type == BattleTypes.StatusType.STUN
		or status_type == BattleTypes.StatusType.KNOCKED_DOWN
	)

## Проверяет, допускает ли данный тип статуса накопление стаков
static func is_stackable_type(p_type: BattleTypes.StatusType) -> bool:
	return (
		p_type == BattleTypes.StatusType.BLEED
		or p_type == BattleTypes.StatusType.DEFENSE_DOWN
	)
