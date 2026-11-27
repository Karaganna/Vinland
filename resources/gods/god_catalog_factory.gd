# res://resources/gods/god_catalog_factory.gd
class_name GodCatalogFactory
extends RefCounted

## Программная фабрика 8 богов (4 пары антагонистов), умений пути, Благословений отряда и тестовых выборов

static func create_all_gods() -> Array[GodData]:
	var list: Array[GodData] = []
	
	# -------------------------------------------------------------------------
	# Пара 1: СКАДИ <-> ФРЕЙР
	# -------------------------------------------------------------------------
	var skadi_t1: SkillData = _make_god_skill(
		"god_skadi_frost_bite",
		"Озноб охотницы",
		"Дар Скади (QTE Центр): хладный выпад/выстрел, замедляющий цель и повышающий урон по ней.",
		BattleTypes.TargetSide.ENEMY,
		18,
		BattleTypes.DamageType.ICE,
		20,
		1.20,
		BattleTypes.QTEType.PRECISION_BAR
	)
	skadi_t1.applies_status = true
	skadi_t1.status_to_apply = BattleTypes.StatusType.SLOW
	skadi_t1.status_duration_turns = 2
	
	var skadi_t2: SkillData = _make_god_skill(
		"god_skadi_winter_mark",
		"Тропа волчицы",
		"Путь Скади II (QTE Удержание): пронзающий удар стужи с Отметкой и шансом Заморозки.",
		BattleTypes.TargetSide.ENEMY,
		24,
		BattleTypes.DamageType.ICE,
		26,
		1.32,
		BattleTypes.QTEType.HOLD_RELEASE
	)
	skadi_t2.applies_status = true
	skadi_t2.status_to_apply = BattleTypes.StatusType.MARKED
	skadi_t2.status_duration_turns = 3
	
	list.append(_make_god(
		BattleTypes.GodId.SKADI, BattleTypes.GodId.FREYR,
		"Скади", "Охота, горы и беспощадная зима",
		"+3 АТК, +2 СКР, +6% Крит",
		0, 3, 0, 0, 2, 0.06,
		skadi_t1, skadi_t2,
		"Благословение Зимней Охоты", "+3 АТК, +2 СКР и +6% Крит всему отряду",
		0, 3, 0, 0, 2, 0.06, 0
	))
	
	var freyr_t1: SkillData = _make_god_skill(
		"god_freyr_warm_breeze",
		"Дар летнего поля",
		"Дар Фрейра (QTE Ноты): тёплое дуновение исцеляет весь отряд (+26 HP).",
		BattleTypes.TargetSide.ALL_ALLIES,
		20,
		BattleTypes.DamageType.MAGICAL,
		0,
		1.0,
		BattleTypes.QTEType.RHYTHM_TRACK
	)
	freyr_t1.base_heal_amount = 26
	
	var freyr_t2: SkillData = _make_god_skill(
		"god_freyr_golden_peace",
		"Золотой заслон Фрейра",
		"Путь Фрейра II (QTE Круг): исцеляет отряд (+30 HP) и даёт рунный барьер (+22).",
		BattleTypes.TargetSide.ALL_ALLIES,
		26,
		BattleTypes.DamageType.MAGICAL,
		0,
		1.0,
		BattleTypes.QTEType.CIRCULAR_SKILL_CHECK
	)
	freyr_t2.base_heal_amount = 30
	freyr_t2.shield_barrier_amount = 22
	freyr_t2.status_duration_turns = 2
	
	list.append(_make_god(
		BattleTypes.GodId.FREYR, BattleTypes.GodId.SKADI,
		"Фрейр", "Плодородие, щедрость и мирный достаток",
		"+22 HP, +3 МАГ, +2 ЗАЩ",
		22, 0, 3, 2, 0, 0.0,
		freyr_t1, freyr_t2,
		"Благословение Щедрой Жатвы", "+18 HP, +2 ЗАЩ и стартовый Барьер +14 всему отряду",
		18, 0, 2, 2, 0, 0.0, 14
	))
	
	# -------------------------------------------------------------------------
	# Пара 2: ЛОКИ <-> ТЮР
	# -------------------------------------------------------------------------
	var loki_t1: SkillData = _make_god_skill(
		"god_loki_cinder_trick",
		"Горсть пепла",
		"Дар Локи (QTE Бросок): коварный бросок, ослепляющий врага на 2 хода.",
		BattleTypes.TargetSide.ENEMY,
		16,
		BattleTypes.DamageType.FIRE,
		18,
		1.15,
		BattleTypes.QTEType.DICE_ROLL
	)
	loki_t1.applies_status = true
	loki_t1.status_to_apply = BattleTypes.StatusType.BLIND
	loki_t1.status_duration_turns = 2
	
	var loki_t2: SkillData = _make_god_skill(
		"god_loki_venom_jest",
		"Злая насмешка",
		"Путь Локи II (QTE Серия 3 уд.): серия коварных выпадов с наложением Яда.",
		BattleTypes.TargetSide.ENEMY,
		22,
		BattleTypes.DamageType.PHYSICAL,
		11,
		0.95,
		BattleTypes.QTEType.SERIES_CHAIN
	)
	loki_t2.hit_count = 3
	loki_t2.applies_status = true
	loki_t2.status_to_apply = BattleTypes.StatusType.POISON
	loki_t2.status_duration_turns = 3
	
	list.append(_make_god(
		BattleTypes.GodId.LOKI, BattleTypes.GodId.TYR,
		"Локи", "Хитрость, обман и нарушение устоев",
		"+3 СКР, +7% Крит, +2 МАГ",
		0, 1, 2, 0, 3, 0.07,
		loki_t1, loki_t2,
		"Благословение Коварной Удачи", "+2 СКР и +7% Крит всему отряду",
		0, 2, 0, 0, 2, 0.07, 0
	))
	
	var tyr_t1: SkillData = _make_god_skill(
		"god_tyr_just_strike",
		"Удар правосудия",
		"Дар Тюра (QTE Центр): честный прямой удар с пробитием блока и расколом брони.",
		BattleTypes.TargetSide.ENEMY,
		18,
		BattleTypes.DamageType.PHYSICAL,
		22,
		1.25,
		BattleTypes.QTEType.PRECISION_BAR
	)
	var tyr_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.MELEE, BattleTypes.SkillTag.GUARD_BREAK]
	tyr_t1.tags = tyr_tags
	tyr_t1.applies_status = true
	tyr_t1.status_to_apply = BattleTypes.StatusType.DEFENSE_DOWN
	tyr_t1.status_duration_turns = 3
	
	var tyr_t2: SkillData = _make_god_skill(
		"god_tyr_iron_oath",
		"Железная клятва Тинга",
		"Путь Тюра II (QTE Круг): снижает входящий урон по всему отряду на 28% и провоцирует врагов.",
		BattleTypes.TargetSide.SELF,
		22,
		BattleTypes.DamageType.PHYSICAL,
		0,
		1.0,
		BattleTypes.QTEType.CIRCULAR_SKILL_CHECK
	)
	tyr_t2.applies_ally_ward = true
	tyr_t2.ally_ward_damage_reduction = 0.28
	tyr_t2.ally_ward_duration_turns = 2
	tyr_t2.applies_status = true
	tyr_t2.status_to_apply = BattleTypes.StatusType.TAUNT
	tyr_t2.status_duration_turns = 2
	
	list.append(_make_god(
		BattleTypes.GodId.TYR, BattleTypes.GodId.LOKI,
		"Тюр", "Закон тинга, воинская честь и жертвенный долг",
		"+4 АТК, +3 ЗАЩ, +10 HP",
		10, 4, 0, 3, 0, 0.0,
		tyr_t1, tyr_t2,
		"Благословение Клятвы Тинга", "+3 АТК, +3 ЗАЩ и +10 HP всему отряду",
		10, 3, 0, 3, 0, 0.0, 0
	))
	
	# -------------------------------------------------------------------------
	# Пара 3: ОДИН <-> ТОР
	# -------------------------------------------------------------------------
	var odin_t1: SkillData = _make_god_skill(
		"god_odin_raven_gaze",
		"Взор Хугина",
		"Дар Одина (QTE Вязь знаков): прозревает слабину врага, нанося урон и накладывая Отметку.",
		BattleTypes.TargetSide.ENEMY,
		18,
		BattleTypes.DamageType.MAGICAL,
		19,
		1.20,
		BattleTypes.QTEType.RUNE_SEQUENCE
	)
	odin_t1.applies_status = true
	odin_t1.status_to_apply = BattleTypes.StatusType.MARKED
	odin_t1.status_duration_turns = 3
	
	var odin_t2: SkillData = _make_god_skill(
		"god_odin_gungnir_echo",
		"Отблеск Гунгнира",
		"Путь Одина II (QTE Центр): неотвратимый бросок рунного копья сквозь любой блок.",
		BattleTypes.TargetSide.ENEMY,
		26,
		BattleTypes.DamageType.MAGICAL,
		30,
		1.35,
		BattleTypes.QTEType.PRECISION_BAR
	)
	var od_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.UNBLOCKABLE, BattleTypes.SkillTag.GUARD_BREAK]
	odin_t2.tags = od_tags
	
	list.append(_make_god(
		BattleTypes.GodId.ODIN, BattleTypes.GodId.THOR,
		"Один", "Тайное знание, расчёт и цена жертвы",
		"+5 МАГ, +2 АТК, +4% Крит",
		0, 2, 5, 0, 1, 0.04,
		odin_t1, odin_t2,
		"Благословение Воронова Взора", "+4 МАГ, +2 АТК и +5% Крит всему отряду",
		0, 2, 4, 0, 0, 0.05, 0
	))
	
	var thor_t1: SkillData = _make_god_skill(
		"god_thor_thunder_clap",
		"Раскат грома",
		"Дар Тора (QTE Рывок): громовой удар по врагу с выведением из равновесия.",
		BattleTypes.TargetSide.ENEMY,
		18,
		BattleTypes.DamageType.LIGHTNING,
		23,
		1.25,
		BattleTypes.QTEType.RUSH_MASH
	)
	thor_t1.applies_status = true
	thor_t1.status_to_apply = BattleTypes.StatusType.UNBALANCED
	thor_t1.status_duration_turns = 2
	
	var thor_t2: SkillData = _make_god_skill(
		"god_thor_storm_hammer",
		"Буря Мидгарда",
		"Путь Тора II (QTE Удержание): молния бьёт всех противников и ослабляет их атаку.",
		BattleTypes.TargetSide.ALL_ENEMIES,
		26,
		BattleTypes.DamageType.LIGHTNING,
		24,
		1.25,
		BattleTypes.QTEType.HOLD_RELEASE
	)
	thor_t2.applies_status = true
	thor_t2.status_to_apply = BattleTypes.StatusType.ATTACK_DOWN
	thor_t2.status_duration_turns = 2
	
	list.append(_make_god(
		BattleTypes.GodId.THOR, BattleTypes.GodId.ODIN,
		"Тор", "Прямая мощь, гром и защита людей Мидгарда",
		"+16 HP, +4 АТК, +2 ЗАЩ",
		16, 4, 0, 2, 0, 0.0,
		thor_t1, thor_t2,
		"Благословение Громовника", "+16 HP, +4 АТК и +2 ЗАЩ всему отряду",
		16, 4, 0, 2, 0, 0.0, 0
	))
	
	# -------------------------------------------------------------------------
	# Пара 4: ХЕЛЬ <-> ФРЕЙЯ
	# -------------------------------------------------------------------------
	var hel_t1: SkillData = _make_god_skill(
		"god_hel_grave_chill",
		"Дыхание Нифльхейма",
		"Дар Хель (QTE Удержание): хладная хватка ослабляет атаку и замедляет врага.",
		BattleTypes.TargetSide.ENEMY,
		18,
		BattleTypes.DamageType.ICE,
		20,
		1.20,
		BattleTypes.QTEType.HOLD_RELEASE
	)
	hel_t1.applies_status = true
	hel_t1.status_to_apply = BattleTypes.StatusType.ATTACK_DOWN
	hel_t1.status_duration_turns = 3
	
	var hel_t2: SkillData = _make_god_skill(
		"god_hel_silent_shroud",
		"Покров безмолвия",
		"Путь Хель II (QTE Круг): укрывает весь отряд плотным ледяным саваном (+34 Барьера).",
		BattleTypes.TargetSide.ALL_ALLIES,
		24,
		BattleTypes.DamageType.ICE,
		0,
		1.0,
		BattleTypes.QTEType.CIRCULAR_SKILL_CHECK
	)
	hel_t2.shield_barrier_amount = 34
	hel_t2.status_duration_turns = 3
	
	list.append(_make_god(
		BattleTypes.GodId.HEL, BattleTypes.GodId.FREYJA,
		"Хель", "Покой мёртвых, неизбежность и тихая стойкость",
		"+20 HP, +4 ЗАЩ, +2 МАГ",
		20, 0, 2, 4, 0, 0.0,
		hel_t1, hel_t2,
		"Благословение Порога Хель", "+15 HP, +3 ЗАЩ и стартовый Барьер +18 всему отряду",
		15, 0, 0, 3, 0, 0.0, 18
	))
	
	var freyja_t1: SkillData = _make_god_skill(
		"god_freyja_seidr_pulse",
		"Нить сейда",
		"Дар Фрейи (QTE Ноты): восстанавливает союзнику +34 HP и укрывает барьером (+14).",
		BattleTypes.TargetSide.ALLY,
		18,
		BattleTypes.DamageType.MAGICAL,
		0,
		1.0,
		BattleTypes.QTEType.RHYTHM_TRACK
	)
	freyja_t1.base_heal_amount = 34
	freyja_t1.shield_barrier_amount = 14
	freyja_t1.status_duration_turns = 2
	
	var freyja_t2: SkillData = _make_god_skill(
		"god_freyja_valkyrie_call",
		"Клич Фолькванга",
		"Путь Фрейи II (QTE Вязь знаков): поднимает павшего союзника или исцеляет живого (+42 HP).",
		BattleTypes.TargetSide.ALLY,
		26,
		BattleTypes.DamageType.MAGICAL,
		0,
		1.0,
		BattleTypes.QTEType.RUNE_SEQUENCE
	)
	freyja_t2.base_heal_amount = 42
	freyja_t2.revives_fallen_ally = true
	freyja_t2.can_target_fallen_ally = true
	
	list.append(_make_god(
		BattleTypes.GodId.FREYJA, BattleTypes.GodId.HEL,
		"Фрейя", "Жажда жизни, сейд и крылья валькирий",
		"+16 HP, +4 МАГ, +4% Крит",
		16, 1, 4, 0, 1, 0.04,
		freyja_t1, freyja_t2,
		"Благословение Крыльев Фрейи", "+14 HP, +4 МАГ и +1 СКР всему отряду",
		14, 0, 4, 0, 1, 0.0, 0
	))
	
	return list

## Тестовые мировоззренческие поступки для вкладки «Боги» (по 1 дилемме на каждую пару антагонистов)
static func create_test_deeds() -> Array[Dictionary]:
	return [
		{
			"pair_title": "Охота vs Плодородие (Скади ↔ Фрейр)",
			"left_label": "Добить раненого зверя (Скади)",
			"left_god": BattleTypes.GodId.SKADI,
			"right_label": "Отпустить зверя в лес (Фрейр)",
			"right_god": BattleTypes.GodId.FREYR,
			"delta": 15
		},
		{
			"pair_title": "Хитрость vs Закон (Локи ↔ Тюр)",
			"left_label": "Обхитрить стражу у ворот (Локи)",
			"left_god": BattleTypes.GodId.LOKI,
			"right_label": "Сдержать клятву на тинге (Тюр)",
			"right_god": BattleTypes.GodId.TYR,
			"delta": 15
		},
		{
			"pair_title": "Тайна vs Защита людей (Один ↔ Тор)",
			"left_label": "Пожертвовать ради рун (Один)",
			"left_god": BattleTypes.GodId.ODIN,
			"right_label": "Прикрыть хутор от набега (Тор)",
			"right_god": BattleTypes.GodId.THOR,
			"delta": 15
		},
		{
			"pair_title": "Покой мёртвых vs Сейд жизни (Хель ↔ Фрейя)",
			"left_label": "Оставить курган в покое (Хель)",
			"left_god": BattleTypes.GodId.HEL,
			"right_label": "Разжечь обряд жизни (Фрейя)",
			"right_god": BattleTypes.GodId.FREYJA,
			"delta": 15
		}
	]

static func _make_god(
	p_id: BattleTypes.GodId,
	p_ant: BattleTypes.GodId,
	p_name: String,
	p_domain: String,
	p_pat_sum: String,
	p_hp: int,
	p_atk: int,
	p_mag: int,
	p_def: int,
	p_spd: int,
	p_crit: float,
	p_s1: SkillData,
	p_s2: SkillData,
	p_bl_name: String,
	p_bl_desc: String,
	p_bl_hp: int,
	p_bl_atk: int,
	p_bl_mag: int,
	p_bl_def: int,
	p_bl_spd: int,
	p_bl_crit: float,
	p_bl_bar: int
) -> GodData:
	var g: GodData = GodData.new()
	g.god_id = p_id
	g.antagonist_id = p_ant
	g.display_name = p_name
	g.domain_summary = p_domain
	g.patron_summary = p_pat_sum
	g.patron_hp_bonus = p_hp
	g.patron_attack_bonus = p_atk
	g.patron_magic_bonus = p_mag
	g.patron_defense_bonus = p_def
	g.patron_speed_bonus = p_spd
	g.patron_crit_bonus = p_crit
	g.tier_1_skill = p_s1
	g.tier_2_skill = p_s2
	g.blessing_name = p_bl_name
	g.blessing_description = p_bl_desc
	g.blessing_hp_bonus = p_bl_hp
	g.blessing_attack_bonus = p_bl_atk
	g.blessing_magic_bonus = p_bl_mag
	g.blessing_defense_bonus = p_bl_def
	g.blessing_speed_bonus = p_bl_spd
	g.blessing_crit_bonus = p_bl_crit
	g.blessing_start_barrier = p_bl_bar
	return g

static func _make_god_skill(
	p_id: String,
	p_name: String,
	p_desc: String,
	p_side: BattleTypes.TargetSide,
	p_cost: int,
	p_dmg_type: BattleTypes.DamageType,
	p_base: int,
	p_mult: float,
	p_qte_type: BattleTypes.QTEType
) -> SkillData:
	var qte: QTEConfigData = QTEConfigData.new()
	qte.qte_type = p_qte_type
	qte.duration_seconds = 2.5
	qte.cursor_speed = 1.40
	qte.success_zone_width = 0.23
	qte.perfect_zone_width = 0.08
	qte.sequence_length = 4
	qte.mash_target_presses = 9
	qte.dice_count = 3
	qte.series_max_steps = 3
	qte.bpm = 120.0
	qte.note_count = 4
	
	var sk: SkillData = SkillData.new()
	sk.skill_id = p_id
	sk.skill_name = p_name
	sk.description = p_desc
	sk.action_category = BattleTypes.ActionType.SKILL
	sk.target_side = p_side
	sk.resource_type = BattleTypes.ResourceType.ENERGY
	sk.resource_cost = p_cost
	sk.damage_type = p_dmg_type
	sk.base_power = p_base
	sk.power_multiplier = p_mult
	sk.blockability = BattleTypes.Blockability.HIGH_80
	sk.requires_qte = (p_qte_type != BattleTypes.QTEType.NONE)
	sk.qte_config = qte
	return sk
