# res://scripts/battle/battle_calculator.gd
class_name BattleCalculator
extends RefCounted

## Базовые пороги точности QTE (<0.30 промах 0.0x, ~0.50 ослабленный 0.5x, >=0.90 идеальный 1.5x)
const DEFAULT_MISS_THRESHOLD: float = 0.30
const DEFAULT_WEAK_THRESHOLD: float = 0.60
const DEFAULT_PERFECT_THRESHOLD: float = 0.90

## Оценивает множитель результата QTE с учетом переопределений из экипировки или конфигурации навыка
static func evaluate_qte_multiplier(
	accuracy: float,
	config: QTEConfigData,
	equipment_list: Array[EquipmentModifierStub] = []
) -> Dictionary:
	var acc: float = clampf(accuracy, 0.0, 1.0)
	var miss_t: float = DEFAULT_MISS_THRESHOLD
	var weak_t: float = DEFAULT_WEAK_THRESHOLD
	var perfect_t: float = DEFAULT_PERFECT_THRESHOLD
	
	var miss_mult: float = 0.0
	var weak_mult: float = 0.5
	var normal_mult: float = 1.0
	var perfect_mult: float = 1.5
	
	if config != null:
		miss_mult = config.miss_multiplier
		weak_mult = config.weak_multiplier
		normal_mult = config.normal_multiplier
		perfect_mult = config.perfect_multiplier
		if config.use_custom_thresholds:
			miss_t = config.miss_threshold
			weak_t = config.weak_threshold
			perfect_t = config.perfect_threshold
	
	# Экипировка/оружие может переопределять пороги (например, "промах < 0.5, крит >= 0.9")
	for eq: EquipmentModifierStub in equipment_list:
		if eq != null and eq.override_qte_thresholds:
			miss_t = eq.qte_miss_threshold
			weak_t = eq.qte_weak_threshold
			perfect_t = eq.qte_perfect_threshold
	
	weak_t = maxf(miss_t, weak_t)
	perfect_t = maxf(weak_t, perfect_t)
	
	if acc < miss_t:
		return {"multiplier": miss_mult, "tier": "ПРОМАХ"}
	if acc <= weak_t:
		return {"multiplier": weak_mult, "tier": "СЛАБО"}
	if acc >= perfect_t:
		return {"multiplier": perfect_mult, "tier": "ИДЕАЛЬНО"}
	return {"multiplier": normal_mult, "tier": "НОРМАЛЬНО"}

## Расчет градиентного блока (100/80/60/40/20/0%) и симметричного пробития GUARD_BREAK
static func calculate_block_mitigation(
	skill: SkillData,
	target: Combatant,
	defense_qte_multiplier: float = 1.0,
	has_defense_qte: bool = false
) -> Dictionary:
	if skill == null or target == null:
		return {"block_ratio": 0.0, "was_blocked": false, "guard_broken": false, "guard_break_bonus": 1.0}
	
	if skill.has_tag(BattleTypes.SkillTag.UNBLOCKABLE):
		return {"block_ratio": 0.0, "was_blocked": false, "guard_broken": false, "guard_break_bonus": 1.0}
	
	var base_block_ratio: float = BattleTypes.get_blockability_ratio(skill.blockability)
	var effective_block_ratio: float = 0.0
	var was_blocked: bool = false
	
	if target.is_blocking:
		was_blocked = true
		effective_block_ratio = base_block_ratio
	
	if has_defense_qte:
		var qte_scale: float = 0.0
		if defense_qte_multiplier >= 1.4:
			qte_scale = 1.0
		elif defense_qte_multiplier >= 0.9:
			qte_scale = 0.75
		elif defense_qte_multiplier >= 0.4:
			qte_scale = 0.40
		
		var qte_block: float = base_block_ratio * qte_scale
		if target.is_blocking:
			effective_block_ratio = clampf(maxf(effective_block_ratio, qte_block), 0.0, 1.0)
		elif qte_block > 0.0:
			was_blocked = true
			effective_block_ratio = qte_block
	
	var guard_broken: bool = false
	var guard_break_bonus: float = 1.0
	if skill.is_guard_break() and (target.is_blocking or effective_block_ratio > 0.0):
		guard_broken = true
		effective_block_ratio *= (1.0 - clampf(skill.guard_break_ignore_ratio, 0.0, 1.0))
		if target.is_blocking:
			guard_break_bonus = maxf(1.0, skill.guard_break_bonus_multiplier)
		if effective_block_ratio <= 0.001:
			effective_block_ratio = 0.0
			was_blocked = false
	
	return {
		"block_ratio": effective_block_ratio,
		"was_blocked": was_blocked,
		"guard_broken": guard_broken,
		"guard_break_bonus": guard_break_bonus
	}

## Полный расчет урона с учетом ресурсов, статов, QTE, зон тела, NO_GUARD и градиентного блока
static func calculate_damage(
	attacker: Combatant,
	target: Combatant,
	skill: SkillData,
	target_part: EnemyPartState = null,
	qte_multiplier: float = 1.0,
	defense_qte_multiplier: float = 1.0,
	tension_tier: BattleTypes.TensionTier = BattleTypes.TensionTier.LOCKED,
	has_defense_qte: bool = false
) -> Dictionary:
	if attacker == null or target == null or skill == null:
		return {"final_damage": 0, "was_blocked": false, "block_ratio": 0.0, "guard_broken": false, "is_crit": false}
	
	var is_magic: bool = (
		skill.damage_type == BattleTypes.DamageType.MAGICAL
		or skill.damage_type == BattleTypes.DamageType.FIRE
		or skill.damage_type == BattleTypes.DamageType.ICE
		or skill.damage_type == BattleTypes.DamageType.LIGHTNING
		or skill.damage_type == BattleTypes.DamageType.SOUND
	)
	
	var stat_power: int = attacker.get_effective_magic() if is_magic else attacker.get_base_attack_without_rage()
	var raw_power: float = (float(stat_power) + float(skill.base_power)) * skill.power_multiplier
	
	# Модификаторы Энергии и Ярости атакующего
	var energy_mod: float = attacker.resources.get_energy_outgoing_multiplier()
	var rage_mod: float = 1.0 if is_magic else attacker.resources.get_rage_attack_multiplier()
	raw_power *= energy_mod * rage_mod
	
	# Бонус от активного QTE атаки
	raw_power *= maxf(0.0, qte_multiplier)
	
	# Бонус уровня ультимативной шкалы Напряжения (50% / 100%) и заглушек рун
	if skill.is_ultimate:
		var tension_mult: float = 1.5 if tension_tier == BattleTypes.TensionTier.FULL_100 else 1.0
		var rune_bonus: float = 0.0
		for rune: RuneSlotStub in attacker.rune_slots:
			if rune != null and rune.unlocked:
				rune_bonus += rune.ultimate_power_bonus
		raw_power *= (tension_mult + rune_bonus)
	
	# Броня цели и выбранной части тела (если не TRUE_DAMAGE)
	var total_defense: int = target.get_effective_defense()
	var part_mult: float = 1.0
	if target_part != null and target_part.data != null:
		total_defense += target_part.data.armor
		part_mult = target_part.data.damage_multiplier
	
	var mitigated: float = raw_power
	if skill.damage_type != BattleTypes.DamageType.TRUE_DAMAGE:
		mitigated = maxf(1.0, raw_power - float(total_defense) * 0.5) if raw_power > 0.0 else 0.0
	
	mitigated *= part_mult
	
	# Уязвимости / сопротивления по типу урона
	var resist_mod: float = target.get_damage_type_multiplier(skill.damage_type)
	mitigated *= resist_mod
	
	# Бонус урона по ошеломленной цели (STAGGER)
	if target.is_staggered():
		mitigated *= 1.25
	
	# Проверка NO_GUARD на цели (повышенный входящий урон и/или гарантированный крит)
	var is_crit: bool = false
	var no_guard_triggered: bool = false
	var no_guard_status: StatusEffectInstance = target.get_no_guard_status()
	if no_guard_status != null:
		no_guard_triggered = true
		mitigated *= maxf(1.0, no_guard_status.magnitude)
		if no_guard_status.guaranteed_crit_against:
			is_crit = true
			mitigated *= attacker.stats.crit_multiplier
	elif raw_power > 0.0 and randf() < attacker.stats.crit_chance:
		is_crit = true
		mitigated *= attacker.stats.crit_multiplier
	
	# Штраф входящего урона при истощении Энергии цели
	mitigated *= target.resources.get_energy_incoming_multiplier()
	
	# Градиентный блок и симметричный GUARD_BREAK
	var block_info: Dictionary = calculate_block_mitigation(skill, target, defense_qte_multiplier, has_defense_qte)
	var block_ratio: float = float(block_info.get("block_ratio", 0.0))
	var guard_break_bonus: float = float(block_info.get("guard_break_bonus", 1.0))
	
	mitigated *= guard_break_bonus
	mitigated *= (1.0 - block_ratio)
	
	var final_damage: int = 0
	if raw_power > 0.0:
		if block_ratio >= 0.999:
			final_damage = 0
		else:
			final_damage = maxi(1, roundi(mitigated))
	
	return {
		"final_damage": final_damage,
		"was_blocked": bool(block_info.get("was_blocked", false)),
		"block_ratio": block_ratio,
		"guard_broken": bool(block_info.get("guard_broken", false)),
		"is_crit": is_crit,
		"energy_modifier": energy_mod,
		"rage_modifier": rage_mod,
		"part_multiplier": part_mult,
		"no_guard_triggered": no_guard_triggered,
		"resistance_modifier": resist_mod
	}
