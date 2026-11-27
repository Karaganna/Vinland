# res://resources/gods/god_types.gd
class_name GodTypes
extends RefCounted

## Ступени сложности вербовки рекрута в зависимости от склонности ГГ к богу рекрута и его антагонисту
enum RecruitmentTier {
	IMMEDIATE,
	STANDARD,
	HARD_1,
	HARD_2,
	HARD_MAX
}

const PATRON_THRESHOLD: int = 15
const TIER_2_SKILL_THRESHOLD: int = 30
const CHOSEN_THRESHOLD: int = 50
const MAX_AFFINITY: int = 100

## Возвращает все 8 богов в порядке 4 пар антагонистов
static func get_all_god_ids() -> Array[BattleTypes.GodId]:
	return [
		BattleTypes.GodId.SKADI,
		BattleTypes.GodId.FREYR,
		BattleTypes.GodId.LOKI,
		BattleTypes.GodId.TYR,
		BattleTypes.GodId.ODIN,
		BattleTypes.GodId.THOR,
		BattleTypes.GodId.HEL,
		BattleTypes.GodId.FREYJA
	]

## Возвращает бога-антагониста из 4 мировоззренческих пар (SKADI<->FREYR, LOKI<->TYR, ODIN<->THOR, HEL<->FREYJA)
static func get_antagonist(god_id: BattleTypes.GodId) -> BattleTypes.GodId:
	match god_id:
		BattleTypes.GodId.SKADI:
			return BattleTypes.GodId.FREYR
		BattleTypes.GodId.FREYR:
			return BattleTypes.GodId.SKADI
		BattleTypes.GodId.LOKI:
			return BattleTypes.GodId.TYR
		BattleTypes.GodId.TYR:
			return BattleTypes.GodId.LOKI
		BattleTypes.GodId.ODIN:
			return BattleTypes.GodId.THOR
		BattleTypes.GodId.THOR:
			return BattleTypes.GodId.ODIN
		BattleTypes.GodId.HEL:
			return BattleTypes.GodId.FREYJA
		BattleTypes.GodId.FREYJA:
			return BattleTypes.GodId.HEL
	return BattleTypes.GodId.NONE

## Возвращает словесную ступень склонности (в духе Fear & Hunger) с опциональным debug-числом
static func get_verbal_affinity_label(affinity_value: int, show_numbers: bool = false) -> String:
	var val: int = maxi(0, affinity_value)
	var verbal: String = "Холодное безразличие"
	if val >= CHOSEN_THRESHOLD:
		verbal = "Живое воплощение воли"
	elif val >= TIER_2_SKILL_THRESHOLD:
		verbal = "Глубокое родство"
	elif val >= PATRON_THRESHOLD:
		verbal = "Благосклонность"
	elif val > 0:
		verbal = "Едва заметный взор"
	
	if show_numbers:
		return "%s [%d]" % [verbal, val]
	return verbal

## Возвращает короткий код ступени вербовки для UI и проверок
static func get_recruitment_tier_code(tier: RecruitmentTier) -> String:
	match tier:
		RecruitmentTier.IMMEDIATE:
			return "IMMEDIATE"
		RecruitmentTier.STANDARD:
			return "STANDARD"
		RecruitmentTier.HARD_1:
			return "HARD_1"
		RecruitmentTier.HARD_2:
			return "HARD_2"
		RecruitmentTier.HARD_MAX:
			return "HARD_MAX"
	return "STANDARD"

## Возвращает локализованное описание ступени сложности вербовки (вербовка всегда остается возможной)
static func get_recruitment_tier_description(tier: RecruitmentTier) -> String:
	match tier:
		RecruitmentTier.IMMEDIATE:
			return "Сразу в отряд (IMMEDIATE)"
		RecruitmentTier.STANDARD:
			return "Базовый квест (STANDARD)"
		RecruitmentTier.HARD_1:
			return "Усложнённо I (HARD_1)"
		RecruitmentTier.HARD_2:
			return "Трудный спор II (HARD_2)"
		RecruitmentTier.HARD_MAX:
			return "Макс. испытание [Потолок] (HARD_MAX)"
	return "Базовый квест (STANDARD)"
