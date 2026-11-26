# res://scripts/battle/battle_calculator.gd
class_name BattleCalculator
extends RefCounted

## Базовые пороги точности QTE (<0.30 промах 0.0x, ~0.50 ослабленный 0.5x, >=0.90 идеальный 1.5x)
const DEFAULT_MISS_THRESHOLD: float = 0.30
const DEFAULT_WEAK_THRESHOLD: float = 0.60
const DEFAULT_PERFECT_THRESHOLD: float = 0.90
const BLIND_MISS_CHANCE: float = 0.35

## Оценивает множитель результата QTE с учетом переопределений из экипировки, EquipmentLoadout или навыка
static func evaluate_qte_multiplier(
	accuracy: float,
	config: QTEConfigData,
	equipment_list: Array[EquipmentModifierStub] = [],
	loadout_qte_override: Dictionary = {}
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
	
	for eq: EquipmentModifierStub in equipment_list:
		if eq != null and eq.override_qte_thresholds:
			miss_t = eq.qte_miss_threshold
			weak_t = eq.qte_weak_threshold
			perfect_t = eq.qte_perfect_threshold
	
	if bool(loadout_qte_override.get("has_override", false)):
		if bool(loadout_qte_override.get("use_absolute", false)):
			miss_t = float(loadout_qte_override.get("miss_threshold", miss_t))
			weak_t = float(loadout_qte_override.get("weak_threshold", weak_t))
			perfect_t = float(loadout_qte_override.get("perfect_threshold", perfect_t))
		miss_t = clampf(miss_t + float(loadout_qte_override.get("miss_delta", 0.0)), 0.0, 0.95)
		perfect_t = clampf(perfect_t + float(loadout_qte_override.get("perfect_delta", 0.0)), 0.05, 1.0)
	
	weak_t = maxf(miss_t, weak_t)
	perfect_t = maxf(weak_t, perfect_t)
	
	var guaranteed_crit: bool = bool(loadout_qte_override.get("guaranteed_crit_on_perfect", false))
	
	if acc < miss_t:
		return {
			"multiplier": miss_mult,
			"tier": "ПРОМАХ",
			"guaranteed_crit": false,
			"miss_threshold": miss_t,
			"is_miss": true
		}
	if acc <= weak_t:
		return {
			"multiplier": weak_mult,
			"tier": "СЛАБО",
			"guaranteed_crit": false,
			"miss_threshold": miss_t,
			"is_miss": false
		}
	if acc >= perfect_t:
		return {
			"multiplier": perfect_mult,
			"tier": "ИДЕАЛЬНО",
			"guaranteed_crit": guaranteed_crit,
			"miss_threshold": miss_t,
			"is_miss": false
		}
	return {
		"multiplier": normal_mult,
		"tier": "НОРМАЛЬНО",
		"guaranteed_crit": false,
		"miss_threshold": miss_t,
		"is_miss": false
	}

## Расчет градиентного блока, взаимодействий щита (DRAGON_FIRE_BREATH / IGNORES_SHIELD) и GUARD_BREAK
static func calculate_block_mitigation(
	skill: SkillData,
	target: Combatant,
	defense_qte_multiplier: float = 1.0,
	has_defense_qte: bool = false,
	attacker: Combatant = null
) -> Dictionary:
	if skill == null or target == null:
		return {"block_ratio": 0.0, "was_blocked": false, "guard_broken": false, "guard_break_bonus": 1.0, "shield_nullified_breath": false}
	
	if skill.has_tag(BattleTypes.SkillTag.UNBLOCKABLE):
		return {"block_ratio": 0.0, "was_blocked": false, "guard_broken": false, "guard_break_bonus": 1.0, "shield_nullified_breath": false}
	
	var ignores_shield: bool = (
		skill.has_tag(BattleTypes.SkillTag.IGNORES_SHIELD)
		or (attacker != null and attacker.has_passive_tag(&"IGNORES_SHIELD"))
	)
	var target_has_shield: bool = target.has_shield_equipped() and not ignores_shield
	
	# Щит полностью гасит огненное дыхание дракона при активном блоке, прикрытии или Скьяльдборге
	if (
		target_has_shield
		and skill.has_tag(BattleTypes.SkillTag.DRAGON_FIRE_BREATH)
		and (
			target.is_blocking
			or target.has_status(BattleTypes.StatusType.WARD_AURA)
			or target.has_status(BattleTypes.StatusType.COVER_ALLY)
		)
	):
		return {
			"block_ratio": 1.0,
			"was_blocked": true,
			"guard_broken": false,
			"guard_break_bonus": 1.0,
			"shield_nullified_breath": true
		}
	
	var base_block_ratio: float = BattleTypes.get_blockability_ratio(skill.blockability)
	var effective_block_ratio: float = 0.0
	var was_blocked: bool = false
	var shield_full_proc: bool = false
	var shield_enhanced_proc: bool = false
	
	if target.is_blocking:
		was_blocked = true
		effective_block_ratio = base_block_ratio
		if target_has_shield:
			var shield_ch: Dictionary = target.get_shield_block_chances()
			var full_ch: float = float(shield_ch.get("full_chance", 0.0))
			var enh_ch: float = float(shield_ch.get("enhanced_chance", 0.0))
			if full_ch > 0.0 and randf() < full_ch:
				effective_block_ratio = 1.0
				shield_full_proc = true
			elif enh_ch > 0.0 and randf() < enh_ch:
				effective_block_ratio = clampf(effective_block_ratio + 0.25, 0.0, 0.95)
				shield_enhanced_proc = true
	
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
	var attacker_breaks_guard: bool = skill.is_guard_break() or (attacker != null and attacker.has_passive_tag(&"GUARD_BREAK"))
	if attacker_breaks_guard and (target.is_blocking or effective_block_ratio > 0.0):
		guard_broken = true
		shield_full_proc = false
		shield_enhanced_proc = false
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
		"guard_break_bonus": guard_break_bonus,
		"shield_nullified_breath": false,
		"shield_full_proc": shield_full_proc,
		"shield_enhanced_proc": shield_enhanced_proc
	}

## Полный расчет урона с учетом Энергии, Ярости, Хамингьи, Потока, статусов и градиентного блока
static func calculate_damage(
	attacker: Combatant,
	target: Combatant,
	skill: SkillData,
	target_part: EnemyPartState = null,
	qte_multiplier: float = 1.0,
	defense_qte_multiplier: float = 1.0,
	tension_tier: BattleTypes.TensionTier = BattleTypes.TensionTier.LOCKED,
	has_defense_qte: bool = false,
	force_crit: bool = false
) -> Dictionary:
	if attacker == null or target == null or skill == null:
		return {
			"final_damage": 0,
			"was_blocked": false,
			"block_ratio": 0.0,
			"guard_broken": false,
			"is_crit": false,
			"missed_by_blind": false,
			"shield_nullified_breath": false
		}
	
	# Ослепление атакующего дает шанс промаха (кроме неотвратимых ульт/умений)
	if (
		attacker.has_status(BattleTypes.StatusType.BLIND)
		and not skill.has_tag(BattleTypes.SkillTag.UNBLOCKABLE)
		and randf() < BLIND_MISS_CHANCE
	):
		return {
			"final_damage": 0,
			"was_blocked": false,
			"block_ratio": 0.0,
			"guard_broken": false,
			"is_crit": false,
			"missed_by_blind": true,
			"shield_nullified_breath": false
		}
	
	var is_magic: bool = (
		skill.damage_type == BattleTypes.DamageType.MAGICAL
		or skill.damage_type == BattleTypes.DamageType.FIRE
		or skill.damage_type == BattleTypes.DamageType.ICE
		or skill.damage_type == BattleTypes.DamageType.LIGHTNING
		or skill.damage_type == BattleTypes.DamageType.SOUND
	)
	
	var stat_power: int = attacker.get_effective_magic() if is_magic else attacker.get_base_attack_without_rage()
	var raw_power: float = (float(stat_power) + float(skill.base_power)) * skill.power_multiplier
	
	# Модификаторы Энергии, Ярости (включая SCALES_WITH_RAGE без траты ресурса) и Хамингьи
	var energy_mod: float = attacker.resources.get_energy_outgoing_multiplier()
	var uses_rage_scale: bool = (not is_magic) or skill.has_tag(BattleTypes.SkillTag.SCALES_WITH_RAGE)
	var rage_mod: float = attacker.resources.get_rage_attack_multiplier() if uses_rage_scale else 1.0
	var hamingja_mod: float = attacker.resources.get_hamingja_power_multiplier()
	raw_power *= energy_mod * rage_mod * hamingja_mod
	
	# Бонус от активного QTE атаки
	raw_power *= maxf(0.0, qte_multiplier)
	
	# Бонус уровня ультимативной шкалы Напряжения (50% / 100%) и слотов рун
	if skill.is_ultimate:
		var tension_mult: float = 1.5 if tension_tier == BattleTypes.TensionTier.FULL_100 else 1.0
		var rune_bonus: float = 0.0
		for rune: RuneSlotStub in attacker.rune_slots:
			if rune != null and rune.unlocked:
				rune_bonus += rune.ultimate_power_bonus
		raw_power *= (tension_mult + rune_bonus)
	
	# Броня цели и выбранной части тела (оружие с IGNORES_SHIELD игнорирует защиту от щита)
	var ignores_shield_def: bool = (
		skill.has_tag(BattleTypes.SkillTag.IGNORES_SHIELD)
		or attacker.has_passive_tag(&"IGNORES_SHIELD")
	)
	var total_defense: int = target.get_effective_defense()
	if ignores_shield_def:
		total_defense = maxi(0, total_defense - target.get_shield_defense_bonus())
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
	
	# Модификаторы состояний цели (STAGGER, KNOCKED_DOWN, UNBALANCED, MARKED, WARD_AURA)
	if target.is_staggered():
		mitigated *= 1.25
	if target.has_status(BattleTypes.StatusType.KNOCKED_DOWN):
		mitigated *= 1.30
	elif target.has_status(BattleTypes.StatusType.UNBALANCED):
		mitigated *= 1.15
	
	var marked_st: StatusEffectInstance = target.get_status(BattleTypes.StatusType.MARKED)
	if marked_st != null:
		mitigated *= 1.25
	
	var ward_st: StatusEffectInstance = target.get_status(BattleTypes.StatusType.WARD_AURA)
	if ward_st != null:
		mitigated *= clampf(1.0 - ward_st.magnitude, 0.25, 1.0)
	
	# Проверка NO_GUARD и крита (с учетом прибавки крита от Хамингьи и MARKED)
	var is_crit: bool = false
	var no_guard_triggered: bool = false
	var eff_crit_chance: float = attacker.get_effective_crit_chance()
	if marked_st != null:
		eff_crit_chance = clampf(eff_crit_chance + 0.15, 0.0, 1.0)
	var eff_crit_mult: float = attacker.get_effective_crit_multiplier()
	var no_guard_status: StatusEffectInstance = target.get_no_guard_status()
	if no_guard_status != null:
		no_guard_triggered = true
		mitigated *= maxf(1.0, no_guard_status.magnitude)
		if no_guard_status.guaranteed_crit_against or (force_crit and raw_power > 0.0):
			is_crit = true
			mitigated *= eff_crit_mult
	elif raw_power > 0.0 and (force_crit or randf() < eff_crit_chance):
		is_crit = true
		mitigated *= eff_crit_mult
	
	# Штраф входящего урона при истощении Энергии цели (только если включен флаг)
	mitigated *= target.resources.get_energy_incoming_multiplier()
	
	# Градиентный блок и симметричный GUARD_BREAK
	var block_info: Dictionary = calculate_block_mitigation(skill, target, defense_qte_multiplier, has_defense_qte, attacker)
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
		"shield_nullified_breath": bool(block_info.get("shield_nullified_breath", false)),
		"shield_full_proc": bool(block_info.get("shield_full_proc", false)),
		"shield_enhanced_proc": bool(block_info.get("shield_enhanced_proc", false)),
		"is_crit": is_crit,
		"missed_by_blind": false,
		"energy_modifier": energy_mod,
		"rage_modifier": rage_mod,
		"hamingja_modifier": hamingja_mod,
		"part_multiplier": part_mult,
		"no_guard_triggered": no_guard_triggered,
		"resistance_modifier": resist_mod
	}
