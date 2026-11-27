# res://resources/runes/great_bind_data.gd
class_name GreatBindData
extends Resource

## Ресурс Великой вязи: тройка рун (все 3 в активной Вязи на Печати ур. 5) задает Ульту ГГ (масштабирование 50%->100%)
@export var great_bind_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var required_runes: Array[StringName] = []
@export var scales_with_ship_roster: bool = false
@export var bonus_power_per_ship_member: int = 6
@export var ultimate_template: SkillData = null

## Проверяет, стоят ли все 3 руны Великой вязи в активной Вязи на 5-й ступени (Печать)
func is_satisfied(active_runes: Array[StringName], rune_ranks: Dictionary) -> bool:
	if required_runes.size() < 3:
		return false
	for r_id: StringName in required_runes:
		if not active_runes.has(r_id):
			return false
		if int(rune_ranks.get(r_id, 0)) < RuneTypes.SEAL_RANK:
			return false
	return true

## Собирает runtime-копию Ульты ГГ с масштабированием силы от прогресса развития Футарка (50% -> 100%) и резерва корабля
func build_scaled_ultimate(progression_ratio: float, ship_roster_count: int = 0) -> SkillData:
	if ultimate_template == null:
		return null
	var scale_factor: float = clampf(progression_ratio, 0.50, 1.00)
	var pct: int = roundi(scale_factor * 100.0)
	
	var sk: SkillData = SkillData.new()
	sk.skill_id = ultimate_template.skill_id
	sk.skill_name = "%s [%d%%]" % [ultimate_template.skill_name, pct]
	sk.description = ultimate_template.description
	sk.action_category = BattleTypes.ActionType.ULTIMATE
	sk.target_side = ultimate_template.target_side
	sk.is_ultimate = true
	sk.min_tension_tier = ultimate_template.min_tension_tier
	sk.damage_type = ultimate_template.damage_type
	
	var ship_bonus: int = (maxi(0, ship_roster_count) * bonus_power_per_ship_member) if scales_with_ship_roster else 0
	sk.base_power = roundi(float(ultimate_template.base_power + ship_bonus) * scale_factor)
	sk.power_multiplier = ultimate_template.power_multiplier * (0.75 + 0.25 * scale_factor)
	sk.hit_count = ultimate_template.hit_count
	sk.blockability = ultimate_template.blockability
	sk.tags = ultimate_template.tags.duplicate()
	sk.guard_break_ignore_ratio = ultimate_template.guard_break_ignore_ratio
	sk.guard_break_bonus_multiplier = ultimate_template.guard_break_bonus_multiplier
	
	sk.base_heal_amount = roundi(float(ultimate_template.base_heal_amount) * scale_factor)
	sk.shield_barrier_amount = roundi(float(ultimate_template.shield_barrier_amount) * scale_factor)
	sk.revives_fallen_ally = ultimate_template.revives_fallen_ally
	sk.can_target_fallen_ally = ultimate_template.can_target_fallen_ally
	sk.applies_ally_ward = ultimate_template.applies_ally_ward
	sk.ally_ward_damage_reduction = ultimate_template.ally_ward_damage_reduction * scale_factor
	sk.ally_ward_duration_turns = ultimate_template.ally_ward_duration_turns
	
	sk.applies_status = ultimate_template.applies_status
	sk.status_to_apply = ultimate_template.status_to_apply
	sk.status_duration_turns = ultimate_template.status_duration_turns
	sk.status_apply_chance = ultimate_template.status_apply_chance
	sk.status_magnitude = ultimate_template.status_magnitude
	sk.status_stacks_to_apply = ultimate_template.status_stacks_to_apply
	sk.requires_qte = ultimate_template.requires_qte
	sk.qte_config = ultimate_template.qte_config
	return sk
