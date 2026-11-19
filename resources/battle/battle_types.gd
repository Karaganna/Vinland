# res://resources/battle/battle_types.gd
class_name BattleTypes
extends RefCounted

## Типы боевых ресурсов бойца
enum ResourceType {
	ENERGY,
	MANA,
	RAGE,
	TENSION
}

## Типы урона
enum DamageType {
	PHYSICAL,
	MAGICAL,
	FIRE,
	ICE,
	LIGHTNING,
	SOUND,
	TRUE_DAMAGE
}

## Теги навыков для модификации механик боя
enum SkillTag {
	GUARD_BREAK,
	NO_GUARD,
	TAUNT,
	RAGE_TO_HEAL,
	TELEGRAPHED,
	UNBLOCKABLE,
	SOUND_BASED
}

## Типы статус-эффектов
enum StatusType {
	SLEEP,
	HYPNOSIS,
	STAGGER,
	NO_GUARD,
	TAUNT,
	CALM
}

## Градиентная степень блокируемости атаки противника/героя
enum Blockability {
	FULL_100 = 100,
	HIGH_80 = 80,
	MEDIUM_60 = 60,
	LOW_40 = 40,
	MINIMAL_20 = 20,
	NONE_0 = 0
}

## Типы мини-игр QTE
enum QTEType {
	NONE,
	PRECISION_BAR,
	CIRCULAR_SKILL_CHECK,
	RHYTHM_TRACK
}

## Основные действия хода (5 кнопок меню)
enum ActionType {
	ATTACK,
	SKILL,
	BLOCK,
	ITEM,
	ULTIMATE
}

## Направленность цели действия
enum TargetSide {
	ENEMY,
	ALLY,
	SELF,
	ALL_ENEMIES,
	ALL_ALLIES
}

## Уровень заряда ультимативной шкалы Напряжения (50% / 100%)
enum TensionTier {
	LOCKED = 0,
	HALF_50 = 50,
	FULL_100 = 100
}

## Условие открытия уязвимой зоны (части тела) врага
enum VulnerabilityWindow {
	NONE,
	ON_STAGGER,
	ON_TELEGRAPH,
	ALWAYS
}

## Возвращает коэффициент снижения урона при активном блоке (от 0.0 до 1.0)
static func get_blockability_ratio(blockability: Blockability) -> float:
	return clampf(float(int(blockability)) / 100.0, 0.0, 1.0)

## Возвращает локализованное название боевого ресурса
static func get_resource_display_name(res_type: ResourceType) -> String:
	match res_type:
		ResourceType.ENERGY:
			return "Энергия"
		ResourceType.MANA:
			return "Мана"
		ResourceType.RAGE:
			return "Ярость"
		ResourceType.TENSION:
			return "Напряжение"
	return "Ресурс"

## Возвращает локализованное название статус-эффекта
static func get_status_display_name(status_type: StatusType) -> String:
	match status_type:
		StatusType.SLEEP:
			return "Сон"
		StatusType.HYPNOSIS:
			return "Гипноз"
		StatusType.STAGGER:
			return "Ошеломление"
		StatusType.NO_GUARD:
			return "Открытая стойка"
		StatusType.TAUNT:
			return "Провокация"
		StatusType.CALM:
			return "Успокоение"
	return "Статус"
