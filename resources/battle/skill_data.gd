# res://resources/battle/skill_data.gd
class_name SkillData
extends Resource

## Data-driven описание боевого действия, умения, вражеской атаки или ульты
@export var skill_id: String = "basic_strike"
@export var skill_name: String = "Обычный удар"
@export_multiline var description: String = ""
@export var action_category: BattleTypes.ActionType = BattleTypes.ActionType.SKILL
@export var target_side: BattleTypes.TargetSide = BattleTypes.TargetSide.ENEMY

@export_group("Ресурсы")
@export var resource_type: BattleTypes.ResourceType = BattleTypes.ResourceType.ENERGY
@export var resource_cost: int = 0
@export var energy_restore_on_use: int = 0

@export_group("Урон и Блок")
@export var damage_type: BattleTypes.DamageType = BattleTypes.DamageType.PHYSICAL
@export var base_power: int = 10
@export var power_multiplier: float = 1.0
@export_range(1, 5, 1) var hit_count: int = 1
## Legacy-совместимость (оружейные умения не должны совмещаться с базовым Блоком)
@export var grants_block_stance: bool = false
@export var blockability: BattleTypes.Blockability = BattleTypes.Blockability.FULL_100
@export var tags: Array[BattleTypes.SkillTag] = []

@export_group("Параметры тегов, лечения и защиты")
@export_range(0.0, 1.0, 0.05) var guard_break_ignore_ratio: float = 1.0
@export var guard_break_bonus_multiplier: float = 1.25
@export var no_guard_incoming_multiplier: float = 1.75
@export var no_guard_guaranteed_crit: bool = false
@export_range(0.0, 1.0, 0.05) var rage_to_heal_ratio: float = 0.0
@export var base_heal_amount: int = 0
@export var shield_barrier_amount: int = 0
@export var can_target_fallen_ally: bool = false
@export var revives_fallen_ally: bool = false
@export var applies_ally_ward: bool = false
@export_range(0.0, 0.9, 0.05) var ally_ward_damage_reduction: float = 0.25
@export var ally_ward_duration_turns: int = 2

@export_group("Статус-эффекты и Стойки")
@export var applies_status: bool = false
@export var status_to_apply: BattleTypes.StatusType = BattleTypes.StatusType.STAGGER
@export var status_duration_turns: int = 2
@export_range(0.0, 1.0, 0.05) var status_apply_chance: float = 1.0
@export_range(1, 5, 1) var status_stacks_to_apply: int = 1
@export var status_is_permanent: bool = false
@export var status_magnitude: float = 1.0
@export var enters_stance: bool = false
@export var stance_status: BattleTypes.StatusType = BattleTypes.StatusType.PARRY_STANCE
@export var stance_duration_turns: int = 1

@export_group("QTE, Телеграф и Ульта")
@export var requires_qte: bool = false
@export var qte_config: QTEConfigData = null
@export var is_telegraphed: bool = false
@export var telegraph_turns: int = 1
@export var telegraph_warning_text: String = ""
@export var is_ultimate: bool = false
@export var min_tension_tier: BattleTypes.TensionTier = BattleTypes.TensionTier.HALF_50

## Проверяет наличие указанного тега у навыка
func has_tag(tag: BattleTypes.SkillTag) -> bool:
	return tags.has(tag)

## Возвращает true, если атака пробивает блок
func is_guard_break() -> bool:
	return has_tag(BattleTypes.SkillTag.GUARD_BREAK)

## Возвращает true, если навык открывает бойца для повышенного урона до конца хода
func is_no_guard() -> bool:
	return has_tag(BattleTypes.SkillTag.NO_GUARD)

## Возвращает true, если навык накладывает провокацию (TAUNT)
func is_taunt() -> bool:
	return has_tag(BattleTypes.SkillTag.TAUNT)

## Возвращает true, если навык конвертирует часть ярости в самолечение
func is_rage_to_heal() -> bool:
	return has_tag(BattleTypes.SkillTag.RAGE_TO_HEAL) or rage_to_heal_ratio > 0.0

## Возвращает true, если атака контактная (ближний бой)
func is_melee_attack() -> bool:
	if has_tag(BattleTypes.SkillTag.RANGED_ATTACK) or has_tag(BattleTypes.SkillTag.SOUND_BASED):
		return false
	if has_tag(BattleTypes.SkillTag.MELEE):
		return true
	return damage_type == BattleTypes.DamageType.PHYSICAL
