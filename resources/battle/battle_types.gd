# res://resources/battle/battle_types.gd
class_name BattleTypes
extends RefCounted

## Константа названия единой рабочей шкалы Главного Героя (легко переименовать в одном месте)
const HERO_FLOW_DISPLAY_NAME: String = "Поток"

## Типы боевых ресурсов бойца (4 основных бака + шкала ульты TENSION)
enum ResourceType {
	ENERGY,
	MANA,
	RAGE,
	HAMINGJA,
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
	SOUND_BASED,
	DRAGON_FIRE_BREATH,
	IGNORES_SHIELD,
	MELEE,
	RANGED_ATTACK,
	CAUSES_CALM,
	SCALES_WITH_RAGE,
	SELF_HEAL_BURNS_RAGE,
	APPLIES_BURN_AT_HIGH_FLOW,
	FINISH_UNBALANCED
}

## Типы статус-эффектов и боевых стоек
enum StatusType {
	SLEEP,
	HYPNOSIS,
	STAGGER,
	NO_GUARD,
	TAUNT,
	CALM,
	BURN,
	BLEED,
	POISON,
	FREEZE,
	STUN,
	UNBALANCED,
	KNOCKED_DOWN,
	SLOW,
	ACT_LAST,
	BLIND,
	DEFENSE_DOWN,
	ATTACK_DOWN,
	TETHERED,
	MARKED,
	SHIELD_BARRIER,
	RELOAD_REQUIRED,
	WARD_AURA,
	COVER_ALLY,
	PARRY_STANCE,
	INTERCEPT_MELEE
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
		ResourceType.HAMINGJA:
			return "Хамингья"
		ResourceType.TENSION:
			return "Напряжение"
	return "Ресурс"

## Возвращает краткую метку ресурса для компактного UI (640x360)
static func get_resource_short_tag(res_type: ResourceType) -> String:
	match res_type:
		ResourceType.ENERGY:
			return "ЭН"
		ResourceType.MANA:
			return "МН"
		ResourceType.RAGE:
			return "ЯР"
		ResourceType.HAMINGJA:
			return "ХМ"
		ResourceType.TENSION:
			return "УЛ"
	return "РС"

## Возвращает заголовок шкалы Потока ГГ с указанием активного режима
static func get_flow_display_label(flow_mode: ResourceType) -> String:
	return "%s (%s)" % [HERO_FLOW_DISPLAY_NAME, get_resource_short_tag(flow_mode)]

## Возвращает цвет полосы для указанного типа ресурса / режима Потока
static func get_resource_color(res_type: ResourceType) -> Color:
	match res_type:
		ResourceType.ENERGY:
			return Color(0.95, 0.80, 0.20, 1.0)
		ResourceType.MANA:
			return Color(0.25, 0.60, 0.98, 1.0)
		ResourceType.RAGE:
			return Color(0.92, 0.28, 0.22, 1.0)
		ResourceType.HAMINGJA:
			return Color(0.30, 0.86, 0.72, 1.0)
		ResourceType.TENSION:
			return Color(0.75, 0.38, 0.98, 1.0)
	return Color(0.75, 0.78, 0.85, 1.0)

## Проверяет, является ли статус боевой стойкой оружия
static func is_stance_status(status_type: StatusType) -> bool:
	return (
		status_type == StatusType.COVER_ALLY
		or status_type == StatusType.PARRY_STANCE
		or status_type == StatusType.INTERCEPT_MELEE
	)

## Возвращает локализованное название статус-эффекта или стойки
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
		StatusType.BURN:
			return "Ожог"
		StatusType.BLEED:
			return "Кровотечение"
		StatusType.POISON:
			return "Яд"
		StatusType.FREEZE:
			return "Заморозка"
		StatusType.STUN:
			return "Оглушение"
		StatusType.UNBALANCED:
			return "Потеря равновесия"
		StatusType.KNOCKED_DOWN:
			return "Сбит с ног"
		StatusType.SLOW:
			return "Замедление"
		StatusType.ACT_LAST:
			return "Ход последним"
		StatusType.BLIND:
			return "Ослепление"
		StatusType.DEFENSE_DOWN:
			return "Раскол брони"
		StatusType.ATTACK_DOWN:
			return "Ослабление"
		StatusType.TETHERED:
			return "На привязи"
		StatusType.MARKED:
			return "Отметка"
		StatusType.SHIELD_BARRIER:
			return "Барьер"
		StatusType.RELOAD_REQUIRED:
			return "Перезарядка"
		StatusType.WARD_AURA:
			return "Скьяльдборг"
		StatusType.COVER_ALLY:
			return "Начеку"
		StatusType.PARRY_STANCE:
			return "Стойка «Вызов»"
		StatusType.INTERCEPT_MELEE:
			return "Держать дистанцию"
	return "Статус"
