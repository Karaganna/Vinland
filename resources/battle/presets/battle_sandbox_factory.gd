# res://resources/battle/presets/battle_sandbox_factory.gd
class_name BattleSandboxFactory
extends RefCounted

## Программная фабрика отряда из 4 бойцов (ГГ + 3 рекрута), резерва корабля и босса песочницы

# =========================================================================
# 1. ГЛАВНЫЙ ГЕРОЙ (Слот 0, единая шкала «Поток» + Напряжение)
# =========================================================================

static func create_sandbox_hero() -> CombatantData:
	var hero: CombatantData = CombatantData.new()
	hero.combatant_id = "sandbox_hero"
	hero.display_name = "Главный герой"
	hero.role_title = "Вождь дружины"
	hero.is_player_controlled = true
	hero.is_hero = true
	hero.is_viking = true
	hero.weapon_category = InventoryTypes.WeaponCategory.HERO_SIGNATURE
	hero.can_wear_heavy = true
	hero.patron_god = BattleTypes.GodId.NONE
	hero.sprite_color = Color(0.25, 0.58, 0.94, 1.0)
	
	var st: CombatStatsData = CombatStatsData.new()
	st.max_hp = 140
	st.attack = 16
	st.magic_power = 18
	st.defense = 6
	st.speed = 12
	st.crit_chance = 0.10
	st.crit_multiplier = 1.5
	hero.stats = st
	
	hero.default_flow_mode = BattleTypes.ResourceType.ENERGY
	hero.primary_resource = BattleTypes.ResourceType.ENERGY
	hero.max_energy = 100
	hero.initial_energy = 75
	hero.max_mana = 100
	hero.initial_mana = 100
	hero.max_rage = 100
	hero.initial_rage = 0
	hero.max_hamingja = 100
	hero.initial_hamingja = 50
	hero.max_tension = 100
	hero.initial_tension = 0
	hero.ultimate_unlocked = true
	hero.ultimate_max_tier = BattleTypes.TensionTier.FULL_100
	hero.enable_low_energy_penalty = false
	
	hero.basic_attack = _make_basic_attack(
		"hero_basic_strike",
		"Быстрый удар",
		"Бесплатная контактная атака. В режиме Энергии восполняет +25 Потока.",
		BattleTypes.DamageType.PHYSICAL,
		8,
		25,
		true
	)
	
	var second_wind: SkillData = SkillData.new()
	second_wind.skill_id = "hero_second_wind"
	second_wind.skill_name = "Второе дыхание"
	second_wind.description = "Самолечение (+34 HP). В режиме Ярости сжигает часть накопленного Потока."
	second_wind.action_category = BattleTypes.ActionType.SKILL
	second_wind.target_side = BattleTypes.TargetSide.SELF
	second_wind.resource_type = BattleTypes.ResourceType.ENERGY
	second_wind.resource_cost = 15
	second_wind.base_heal_amount = 34
	var sw_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.SELF_HEAL_BURNS_RAGE]
	second_wind.tags = sw_tags
	
	var p_skills: Array[SkillData] = [second_wind]
	hero.personal_skills = p_skills
	hero.skills.clear()
	
	var ult_qte: QTEConfigData = QTEConfigData.new()
	ult_qte.qte_type = BattleTypes.QTEType.PRECISION_BAR
	ult_qte.duration_seconds = 2.6
	ult_qte.cursor_speed = 1.50
	ult_qte.success_zone_width = 0.22
	ult_qte.perfect_zone_width = 0.08
	
	var ult: SkillData = SkillData.new()
	ult.skill_id = "ancient_rune_cleave"
	ult.skill_name = "Древний Рунный Разлом"
	ult.description = "Ульта ГГ (усиливается на 50% и 100% Напряжения)."
	ult.action_category = BattleTypes.ActionType.ULTIMATE
	ult.target_side = BattleTypes.TargetSide.ENEMY
	ult.resource_type = BattleTypes.ResourceType.TENSION
	ult.damage_type = BattleTypes.DamageType.MAGICAL
	ult.base_power = 36
	ult.power_multiplier = 1.45
	ult.blockability = BattleTypes.Blockability.NONE_0
	var ult_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.UNBLOCKABLE]
	ult.tags = ult_tags
	ult.is_ultimate = true
	ult.min_tension_tier = BattleTypes.TensionTier.HALF_50
	ult.requires_qte = true
	ult.qte_config = ult_qte
	hero.ultimate_skill = ult
	
	hero.equipment_loadout = InventorySandboxFactory.create_default_hero_loadout()
	return hero

# =========================================================================
# 2. ТРИ АКТИВНЫХ РЕКРУТА ОТРЯДА (ENERGY / HAMINGJA / MANA)
# =========================================================================

## 2. Хольмгангер Эйнар: однорукий (available_hands = 1), LONG_BLADES, ENERGY, TYR, руна TIWAZ
static func create_recruit_holmganger() -> CombatantData:
	var rec: CombatantData = CombatantData.new()
	rec.combatant_id = "recruit_holmganger"
	rec.display_name = "Эйнар"
	rec.role_title = "Хольмгангер (1 рука)"
	rec.is_player_controlled = true
	rec.is_hero = false
	rec.is_viking = true
	rec.weapon_category = InventoryTypes.WeaponCategory.LONG_BLADES
	rec.can_wear_heavy = true
	rec.primary_resource = BattleTypes.ResourceType.ENERGY
	rec.ancestral_rune_id = &"tiwaz"
	rec.patron_god = BattleTypes.GodId.TYR
	rec.sprite_color = Color(0.88, 0.72, 0.24, 1.0)
	
	var st: CombatStatsData = CombatStatsData.new()
	st.max_hp = 128
	st.attack = 17
	st.magic_power = 8
	st.defense = 6
	st.speed = 13
	st.crit_chance = 0.12
	st.crit_multiplier = 1.55
	rec.stats = st
	rec.max_energy = 100
	rec.initial_energy = 70
	
	rec.basic_attack = _make_basic_attack(
		"holmganger_basic",
		"Финт поединщика",
		"Быстрый укол клинком (+22 Энергии).",
		BattleTypes.DamageType.PHYSICAL,
		8,
		22,
		true
	)
	
	# Личный навык с QTE «Серия» (SERIES_CHAIN): точное число ударов до первого промаха!
	var series_cfg: QTEConfigData = QTEConfigData.new()
	series_cfg.qte_type = BattleTypes.QTEType.SERIES_CHAIN
	series_cfg.series_max_steps = 4
	series_cfg.series_speed_step_bonus = 0.20
	series_cfg.duration_seconds = 2.0
	series_cfg.cursor_speed = 1.30
	series_cfg.success_zone_width = 0.24
	series_cfg.perfect_zone_width = 0.08
	
	var stinging_series: SkillData = SkillData.new()
	stinging_series.skill_id = "holmganger_stinging_series"
	stinging_series.skill_name = "Жалящая серия"
	stinging_series.description = "QTE Серия (до 4 ударов подряд): наносит ровно столько выпадов, сколько раз вы попали без промаха!"
	stinging_series.action_category = BattleTypes.ActionType.SKILL
	stinging_series.target_side = BattleTypes.TargetSide.ENEMY
	stinging_series.resource_type = BattleTypes.ResourceType.ENERGY
	stinging_series.resource_cost = 24
	stinging_series.damage_type = BattleTypes.DamageType.PHYSICAL
	stinging_series.base_power = 9
	stinging_series.power_multiplier = 0.85
	stinging_series.hit_count = 4
	var ss_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.MELEE]
	stinging_series.tags = ss_tags
	stinging_series.requires_qte = true
	stinging_series.qte_config = series_cfg
	
	# Личный навык с QTE «Рывок» (RUSH_MASH)
	var mash_cfg: QTEConfigData = QTEConfigData.new()
	mash_cfg.qte_type = BattleTypes.QTEType.RUSH_MASH
	mash_cfg.duration_seconds = 2.3
	mash_cfg.mash_target_presses = 9
	mash_cfg.mash_decay_per_second = 0.14
	
	var press_rush: SkillData = SkillData.new()
	press_rush.skill_id = "holmganger_press_rush"
	press_rush.skill_name = "Теснящий натиск"
	press_rush.description = "QTE Рывок: шквальный напор плечом и эфесом, сбивающий равновесие цели."
	press_rush.action_category = BattleTypes.ActionType.SKILL
	press_rush.target_side = BattleTypes.TargetSide.ENEMY
	press_rush.resource_type = BattleTypes.ResourceType.ENERGY
	press_rush.resource_cost = 18
	press_rush.damage_type = BattleTypes.DamageType.PHYSICAL
	press_rush.base_power = 16
	press_rush.power_multiplier = 1.15
	var pr_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.MELEE]
	press_rush.tags = pr_tags
	press_rush.applies_status = true
	press_rush.status_to_apply = BattleTypes.StatusType.UNBALANCED
	press_rush.status_duration_turns = 2
	press_rush.requires_qte = true
	press_rush.qte_config = mash_cfg
	
	var p_list: Array[SkillData] = [stinging_series, press_rush]
	rec.personal_skills = p_list
	rec.ultimate_skill = _make_recruit_ultimate(
		"ult_holmganger_verdict",
		"Приговор Тинга",
		"Неотвратимый удар правосудия Тюра с пробитием защиты.",
		BattleTypes.DamageType.PHYSICAL,
		34,
		BattleTypes.QTEType.PRECISION_BAR
	)
	
	var loadout: EquipmentLoadout = EquipmentLoadout.new()
	loadout.available_hands = 1
	loadout.equip_into_slot(InventoryTypes.SLOT_LEFT_HAND, WeaponCatalogFactory.create_duelist_holmsverd())
	loadout.equip_into_slot(InventoryTypes.SLOT_BODY, WeaponCatalogFactory.create_seafarer_mail())
	rec.equipment_loadout = loadout
	return rec

## 3. Снайпер Ингрид: RANGED, can_wear_heavy = false, HAMINGJA, SKADI, руна EIHWAZ
static func create_recruit_sniper() -> CombatantData:
	var rec: CombatantData = CombatantData.new()
	rec.combatant_id = "recruit_sniper"
	rec.display_name = "Ингрид"
	rec.role_title = "Охотница скал"
	rec.is_player_controlled = true
	rec.is_hero = false
	rec.is_viking = true
	rec.weapon_category = InventoryTypes.WeaponCategory.RANGED
	rec.can_wear_heavy = false
	rec.primary_resource = BattleTypes.ResourceType.HAMINGJA
	rec.ancestral_rune_id = &"eihwaz"
	rec.patron_god = BattleTypes.GodId.SKADI
	rec.sprite_color = Color(0.32, 0.86, 0.72, 1.0)
	
	var st: CombatStatsData = CombatStatsData.new()
	st.max_hp = 106
	st.attack = 16
	st.magic_power = 12
	st.defense = 4
	st.speed = 15
	st.crit_chance = 0.15
	st.crit_multiplier = 1.65
	rec.stats = st
	rec.max_hamingja = 100
	rec.initial_hamingja = 55
	
	rec.basic_attack = _make_basic_attack(
		"sniper_basic_shot",
		"Быстрая стрела",
		"Бесплатный выстрел навскидку.",
		BattleTypes.DamageType.PHYSICAL,
		7,
		0,
		false
	)
	
	# Личный навык с QTE «Серия» (SERIES_CHAIN) на 3 стрелы
	var volley_cfg: QTEConfigData = QTEConfigData.new()
	volley_cfg.qte_type = BattleTypes.QTEType.SERIES_CHAIN
	volley_cfg.series_max_steps = 3
	volley_cfg.series_speed_step_bonus = 0.22
	volley_cfg.duration_seconds = 2.0
	volley_cfg.cursor_speed = 1.35
	volley_cfg.success_zone_width = 0.24
	volley_cfg.perfect_zone_width = 0.09
	
	var rapid_volley: SkillData = SkillData.new()
	rapid_volley.skill_id = "sniper_rapid_volley"
	rapid_volley.skill_name = "Беглый залп"
	rapid_volley.description = "QTE Серия (до 3 стрел): выпускает столько стрел подряд, сколько попаданий выбили без промаха!"
	rapid_volley.action_category = BattleTypes.ActionType.SKILL
	rapid_volley.target_side = BattleTypes.TargetSide.ENEMY
	rapid_volley.resource_type = BattleTypes.ResourceType.HAMINGJA
	rapid_volley.resource_cost = 20
	rapid_volley.damage_type = BattleTypes.DamageType.PHYSICAL
	rapid_volley.base_power = 10
	rapid_volley.power_multiplier = 0.90
	rapid_volley.hit_count = 3
	var rv_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.RANGED_ATTACK]
	rapid_volley.tags = rv_tags
	rapid_volley.requires_qte = true
	rapid_volley.qte_config = volley_cfg
	
	# Личный навык с QTE «Бросок» (DICE_ROLL)
	var dice_cfg: QTEConfigData = QTEConfigData.new()
	dice_cfg.qte_type = BattleTypes.QTEType.DICE_ROLL
	dice_cfg.dice_count = 3
	dice_cfg.dice_cycle_hz = 7.5
	dice_cfg.duration_seconds = 3.2
	
	var fate_shot: SkillData = SkillData.new()
	fate_shot.skill_id = "sniper_fate_arrow"
	fate_shot.skill_name = "Выстрел жребия"
	fate_shot.description = "QTE Бросок (3 кости): урон скейлится от суммы граней и накладывает Отметку на цель."
	fate_shot.action_category = BattleTypes.ActionType.SKILL
	fate_shot.target_side = BattleTypes.TargetSide.ENEMY
	fate_shot.resource_type = BattleTypes.ResourceType.HAMINGJA
	fate_shot.resource_cost = 18
	fate_shot.damage_type = BattleTypes.DamageType.PHYSICAL
	fate_shot.base_power = 18
	fate_shot.power_multiplier = 1.25
	var fa_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.RANGED_ATTACK]
	fate_shot.tags = fa_tags
	fate_shot.applies_status = true
	fate_shot.status_to_apply = BattleTypes.StatusType.MARKED
	fate_shot.status_duration_turns = 2
	fate_shot.requires_qte = true
	fate_shot.qte_config = dice_cfg
	
	var p_list: Array[SkillData] = [rapid_volley, fate_shot]
	rec.personal_skills = p_list
	rec.ultimate_skill = _make_recruit_ultimate(
		"ult_sniper_skadi_blizzard",
		"Стрела Бурана Скади",
		"Ледяная стрела по всем врагам с шансом Заморозки.",
		BattleTypes.DamageType.ICE,
		30,
		BattleTypes.QTEType.PRECISION_BAR,
		true
	)
	
	var loadout: EquipmentLoadout = EquipmentLoadout.new()
	loadout.available_hands = 2
	loadout.equip_into_slot(InventoryTypes.SLOT_LEFT_HAND, WeaponCatalogFactory.create_hunter_bow())
	loadout.equip_into_slot(InventoryTypes.SLOT_BODY, WeaponCatalogFactory.create_seafarer_mail())
	rec.equipment_loadout = loadout
	return rec

## 4. Певица гальдра Сигрун: RELICS, is_viking = false (бак MANA разрешен), дары VOICE + CHARM, FREYJA, руна BERKANA
static func create_recruit_galdr_singer() -> CombatantData:
	var rec: CombatantData = CombatantData.new()
	rec.combatant_id = "recruit_galdr"
	rec.display_name = "Сигрун"
	rec.role_title = "Певица гальдра"
	rec.is_player_controlled = true
	rec.is_hero = false
	rec.is_viking = false
	rec.weapon_category = InventoryTypes.WeaponCategory.RELICS
	rec.can_wear_heavy = false
	var g_list: Array[InventoryTypes.RelicGift] = [
		InventoryTypes.RelicGift.VOICE,
		InventoryTypes.RelicGift.CHARM
	]
	rec.gifts = g_list
	rec.primary_resource = BattleTypes.ResourceType.MANA
	rec.ancestral_rune_id = &"berkana"
	rec.patron_god = BattleTypes.GodId.FREYJA
	rec.sprite_color = Color(0.68, 0.45, 0.96, 1.0)
	
	var st: CombatStatsData = CombatStatsData.new()
	st.max_hp = 104
	st.attack = 9
	st.magic_power = 20
	st.defense = 4
	st.speed = 11
	st.crit_chance = 0.08
	st.crit_multiplier = 1.50
	rec.stats = st
	rec.max_mana = 110
	rec.initial_mana = 110
	
	rec.basic_attack = _make_basic_attack(
		"galdr_basic_whisper",
		"Звуковой отзвук",
		"Легкий звуковой импульс по врагу.",
		BattleTypes.DamageType.SOUND,
		8,
		0,
		false
	)
	
	# Личный навык лечения союзника с QTE «Вязь знаков» (RUNE_SEQUENCE)
	var seq_cfg: QTEConfigData = QTEConfigData.new()
	seq_cfg.qte_type = BattleTypes.QTEType.RUNE_SEQUENCE
	seq_cfg.sequence_length = 4
	seq_cfg.sequence_preview_step_sec = 0.30
	seq_cfg.duration_seconds = 3.2
	
	var heal_weave: SkillData = SkillData.new()
	heal_weave.skill_id = "galdr_healing_weave"
	heal_weave.skill_name = "Вязь исцеления"
	heal_weave.description = "QTE Вязь знаков: восстанавливает здоровье выбранному живому союзнику (+42 HP)."
	heal_weave.action_category = BattleTypes.ActionType.SKILL
	heal_weave.target_side = BattleTypes.TargetSide.ALLY
	heal_weave.resource_type = BattleTypes.ResourceType.MANA
	heal_weave.resource_cost = 22
	heal_weave.base_heal_amount = 42
	heal_weave.requires_qte = true
	heal_weave.qte_config = seq_cfg
	
	# Навык возвращения в строй павшего союзника
	var freyja_breath: SkillData = SkillData.new()
	freyja_breath.skill_id = "galdr_freyja_revive"
	freyja_breath.skill_name = "Дыхание Фрейи"
	freyja_breath.description = "Возвращает павшего союзника (HP = 0) в бой с +40 HP."
	freyja_breath.action_category = BattleTypes.ActionType.SKILL
	freyja_breath.target_side = BattleTypes.TargetSide.ALLY
	freyja_breath.resource_type = BattleTypes.ResourceType.MANA
	freyja_breath.resource_cost = 35
	freyja_breath.base_heal_amount = 40
	freyja_breath.revives_fallen_ally = true
	
	var p_list: Array[SkillData] = [heal_weave, freyja_breath]
	rec.personal_skills = p_list
	
	var ult: SkillData = SkillData.new()
	ult.skill_id = "ult_galdr_valhalla_choir"
	ult.skill_name = "Хор Фолькванга"
	ult.description = "Ульта поддержки: исцеляет весь отряд (+45 HP) и дает прочный Барьер (+30)."
	ult.action_category = BattleTypes.ActionType.ULTIMATE
	ult.target_side = BattleTypes.TargetSide.ALL_ALLIES
	ult.resource_type = BattleTypes.ResourceType.TENSION
	ult.base_heal_amount = 45
	ult.shield_barrier_amount = 30
	ult.status_duration_turns = 2
	ult.is_ultimate = true
	ult.min_tension_tier = BattleTypes.TensionTier.HALF_50
	ult.requires_qte = true
	ult.qte_config = seq_cfg
	rec.ultimate_skill = ult
	
	var loadout: EquipmentLoadout = EquipmentLoadout.new()
	loadout.available_hands = 2
	loadout.equip_into_slot(InventoryTypes.SLOT_LEFT_HAND, WeaponCatalogFactory.create_song_tablet())
	rec.equipment_loadout = loadout
	return rec

# =========================================================================
# 3. РЕЗЕРВ НА КОРАБЛЕ (ship_roster: Берсерк с RAGE + Щитоносец с COVER_ALLY)
# =========================================================================

## 5. Берсерк Бьёрн (на корабле): CRUSHING, RAGE, ODIN, руна THURISAZ
static func create_ship_recruit_berserker() -> CombatantData:
	var rec: CombatantData = CombatantData.new()
	rec.combatant_id = "recruit_berserker"
	rec.display_name = "Бьёрн"
	rec.role_title = "Берсерк (Ярость)"
	rec.is_player_controlled = true
	rec.is_hero = false
	rec.is_viking = true
	rec.weapon_category = InventoryTypes.WeaponCategory.CRUSHING
	rec.can_wear_heavy = true
	rec.primary_resource = BattleTypes.ResourceType.RAGE
	rec.ancestral_rune_id = &"thurisaz"
	rec.patron_god = BattleTypes.GodId.ODIN
	rec.sprite_color = Color(0.92, 0.30, 0.24, 1.0)
	
	var st: CombatStatsData = CombatStatsData.new()
	st.max_hp = 152
	st.attack = 19
	st.magic_power = 6
	st.defense = 5
	st.speed = 11
	st.crit_chance = 0.12
	st.crit_multiplier = 1.60
	rec.stats = st
	rec.max_rage = 100
	rec.initial_rage = 0
	
	rec.basic_attack = _make_basic_attack(
		"berserker_basic_smash",
		"Дикий замах",
		"Тяжёлый удар топором (накапливает Ярость и скейлится от неё).",
		BattleTypes.DamageType.PHYSICAL,
		10,
		0,
		true
	)
	
	var mash_cfg: QTEConfigData = QTEConfigData.new()
	mash_cfg.qte_type = BattleTypes.QTEType.RUSH_MASH
	mash_cfg.duration_seconds = 2.4
	mash_cfg.mash_target_presses = 10
	mash_cfg.mash_decay_per_second = 0.15
	
	var frenzy_rush: SkillData = SkillData.new()
	frenzy_rush.skill_id = "berserker_frenzy_rush"
	frenzy_rush.skill_name = "Бешеный натиск"
	frenzy_rush.description = "QTE Рывок: бесплатный сокрушительный напор, усиливающийся от накопленной Ярости!"
	frenzy_rush.action_category = BattleTypes.ActionType.SKILL
	frenzy_rush.target_side = BattleTypes.TargetSide.ENEMY
	frenzy_rush.resource_type = BattleTypes.ResourceType.RAGE
	frenzy_rush.resource_cost = 0
	frenzy_rush.damage_type = BattleTypes.DamageType.PHYSICAL
	frenzy_rush.base_power = 20
	frenzy_rush.power_multiplier = 1.25
	var fr_tags: Array[BattleTypes.SkillTag] = [
		BattleTypes.SkillTag.MELEE,
		BattleTypes.SkillTag.SCALES_WITH_RAGE,
		BattleTypes.SkillTag.NO_GUARD
	]
	frenzy_rush.tags = fr_tags
	frenzy_rush.no_guard_incoming_multiplier = 1.45
	frenzy_rush.requires_qte = true
	frenzy_rush.qte_config = mash_cfg
	
	var rage_mend: SkillData = SkillData.new()
	rage_mend.skill_id = "berserker_blood_roar"
	rage_mend.skill_name = "Рёв зверя"
	rage_mend.description = "Сжигает 50% текущей Ярости для мгновенного самолечения."
	rage_mend.action_category = BattleTypes.ActionType.SKILL
	rage_mend.target_side = BattleTypes.TargetSide.SELF
	rage_mend.resource_type = BattleTypes.ResourceType.RAGE
	rage_mend.resource_cost = 0
	var rm_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.RAGE_TO_HEAL]
	rage_mend.tags = rm_tags
	rage_mend.rage_to_heal_ratio = 0.50
	rage_mend.base_heal_amount = 14
	
	var p_list: Array[SkillData] = [frenzy_rush, rage_mend]
	rec.personal_skills = p_list
	rec.ultimate_skill = _make_recruit_ultimate(
		"ult_berserker_odin_wrath",
		"Ярость Одина",
		"Сокрушительный удар сквозь любую защиту.",
		BattleTypes.DamageType.PHYSICAL,
		38,
		BattleTypes.QTEType.RUSH_MASH
	)
	
	var loadout: EquipmentLoadout = EquipmentLoadout.new()
	loadout.available_hands = 2
	loadout.equip_into_slot(InventoryTypes.SLOT_LEFT_HAND, WeaponCatalogFactory.create_dane_axe())
	rec.equipment_loadout = loadout
	return rec

## 6. Щитоносец Хальвдан (на корабле): POLEARM, тяжелый щит + «Начеку», ENERGY, THOR, руна URUZ
static func create_ship_recruit_shieldbearer() -> CombatantData:
	var rec: CombatantData = CombatantData.new()
	rec.combatant_id = "recruit_shieldbearer"
	rec.display_name = "Хальвдан"
	rec.role_title = "Хирдман со щитом"
	rec.is_player_controlled = true
	rec.is_hero = false
	rec.is_viking = true
	rec.weapon_category = InventoryTypes.WeaponCategory.POLEARM
	rec.can_wear_heavy = true
	rec.primary_resource = BattleTypes.ResourceType.ENERGY
	rec.ancestral_rune_id = &"uruz"
	rec.patron_god = BattleTypes.GodId.THOR
	rec.sprite_color = Color(0.42, 0.72, 0.92, 1.0)
	
	var st: CombatStatsData = CombatStatsData.new()
	st.max_hp = 156
	st.attack = 14
	st.magic_power = 8
	st.defense = 9
	st.speed = 9
	st.crit_chance = 0.07
	st.crit_multiplier = 1.45
	rec.stats = st
	rec.max_energy = 100
	rec.initial_energy = 70
	
	rec.basic_attack = _make_basic_attack(
		"shieldbearer_basic",
		"Толчок древком",
		"Контактный удар древком (+24 Энергии).",
		BattleTypes.DamageType.PHYSICAL,
		7,
		24,
		true
	)
	
	var hold_cfg: QTEConfigData = QTEConfigData.new()
	hold_cfg.qte_type = BattleTypes.QTEType.HOLD_RELEASE
	hold_cfg.duration_seconds = 2.8
	hold_cfg.hold_target_center = 0.74
	hold_cfg.hold_charge_speed = 0.70
	hold_cfg.success_zone_width = 0.24
	hold_cfg.perfect_zone_width = 0.09
	
	var shield_ram: SkillData = SkillData.new()
	shield_ram.skill_id = "shieldbearer_wall_breach"
	shield_ram.skill_name = "Пролом строя"
	shield_ram.description = "QTE Удержание: таранный удар, сбивающий с ног цель в состоянии Потери равновесия."
	shield_ram.action_category = BattleTypes.ActionType.SKILL
	shield_ram.target_side = BattleTypes.TargetSide.ENEMY
	shield_ram.resource_type = BattleTypes.ResourceType.ENERGY
	shield_ram.resource_cost = 20
	shield_ram.damage_type = BattleTypes.DamageType.PHYSICAL
	shield_ram.base_power = 18
	shield_ram.power_multiplier = 1.20
	var sr_tags: Array[BattleTypes.SkillTag] = [
		BattleTypes.SkillTag.MELEE,
		BattleTypes.SkillTag.FINISH_UNBALANCED
	]
	shield_ram.tags = sr_tags
	shield_ram.requires_qte = true
	shield_ram.qte_config = hold_cfg
	
	var p_list: Array[SkillData] = [shield_ram]
	rec.personal_skills = p_list
	rec.ultimate_skill = _make_recruit_ultimate(
		"ult_shieldbearer_thunder_wall",
		"Молот Грома",
		"Громовой удар Тора по всем противникам.",
		BattleTypes.DamageType.LIGHTNING,
		32,
		BattleTypes.QTEType.HOLD_RELEASE,
		true
	)
	
	var loadout: EquipmentLoadout = EquipmentLoadout.new()
	loadout.available_hands = 2
	loadout.equip_into_slot(InventoryTypes.SLOT_LEFT_HAND, WeaponCatalogFactory.create_recruit_ash_spear())
	loadout.equip_into_slot(InventoryTypes.SLOT_RIGHT_HAND, WeaponCatalogFactory.create_hird_heavy_shield())
	loadout.equip_into_slot(InventoryTypes.SLOT_BODY, WeaponCatalogFactory.create_varangian_heavy_armor())
	rec.equipment_loadout = loadout
	return rec

## Возвращает стартовую активную четверку (ГГ + Хольмгангер + Снайпер + Певица гальдра)
static func create_sandbox_active_party_data() -> Array[CombatantData]:
	return [
		create_sandbox_hero(),
		create_recruit_holmganger(),
		create_recruit_sniper(),
		create_recruit_galdr_singer()
	]

## Возвращает резерв на корабле (2 рекрута, включая Берсерка с баком RAGE и Щитоносца)
static func create_sandbox_ship_roster_data() -> Array[CombatantData]:
	return [
		create_ship_recruit_berserker(),
		create_ship_recruit_shieldbearer()
	]

# =========================================================================
# 4. ПРОТИВНИК: МОЛОДОЙ ДРАКОН (откалиброван под бой 4v1)
# =========================================================================

static func create_young_dragon() -> EnemyData:
	var dragon: EnemyData = EnemyData.new()
	dragon.enemy_id = "young_dragon"
	dragon.enemy_name = "Молодой дракон"
	dragon.max_hp = 380
	dragon.current_hp = 380
	dragon.attack_power = 21
	dragon.max_resolve = 120
	dragon.current_resolve = 0
	dragon.resolve_per_vow = 40
	dragon.sprite_color = Color(0.75, 0.20, 0.16, 1.0)
	
	var st: CombatStatsData = CombatStatsData.new()
	st.max_hp = 380
	st.attack = 21
	st.magic_power = 24
	st.defense = 7
	st.speed = 11
	st.crit_chance = 0.06
	st.crit_multiplier = 1.5
	dragon.combat_stats = st
	
	var dragon_res: Array[BattleTypes.ResourceType] = [
		BattleTypes.ResourceType.ENERGY,
		BattleTypes.ResourceType.RAGE
	]
	dragon.active_resources = dragon_res
	
	var torso: EnemyPartData = EnemyPartData.new()
	torso.part_id = "torso"
	torso.part_name = "Туловище"
	torso.max_hp = 380
	torso.armor = 8
	torso.damage_multiplier = 0.85
	torso.shared_hp_transfer_ratio = 1.0
	torso.is_targetable_by_default = true
	torso.stay_targetable_when_broken = true
	var torso_windows: Array[BattleTypes.VulnerabilityWindow] = [BattleTypes.VulnerabilityWindow.ALWAYS]
	torso.vulnerability_windows = torso_windows
	
	var legs: EnemyPartData = EnemyPartData.new()
	legs.part_id = "legs"
	legs.part_name = "Лапы"
	legs.max_hp = 105
	legs.armor = 3
	legs.damage_multiplier = 1.0
	legs.shared_hp_transfer_ratio = 0.85
	legs.triggers_stagger_on_break = true
	legs.stagger_duration_turns = 2
	legs.is_targetable_by_default = true
	legs.stay_targetable_when_broken = false
	legs.break_message = "Лапы дракона подкашиваются — он падает в ОШЕЛОМЛЕНИЕ!"
	
	var neck: EnemyPartData = EnemyPartData.new()
	neck.part_id = "neck"
	neck.part_name = "Шея"
	neck.max_hp = 140
	neck.armor = 0
	neck.damage_multiplier = 2.0
	neck.shared_hp_transfer_ratio = 1.25
	neck.is_targetable_by_default = false
	neck.stay_targetable_when_broken = true
	var neck_windows: Array[BattleTypes.VulnerabilityWindow] = [
		BattleTypes.VulnerabilityWindow.ON_STAGGER,
		BattleTypes.VulnerabilityWindow.ON_TELEGRAPH
	]
	neck.vulnerability_windows = neck_windows
	
	var dragon_parts: Array[EnemyPartData] = [torso, legs, neck]
	dragon.parts = dragon_parts
	
	var claw: SkillData = SkillData.new()
	claw.skill_id = "dragon_claw"
	claw.skill_name = "Удар когтями"
	claw.action_category = BattleTypes.ActionType.ATTACK
	claw.target_side = BattleTypes.TargetSide.ENEMY
	claw.damage_type = BattleTypes.DamageType.PHYSICAL
	claw.base_power = 14
	claw.power_multiplier = 1.0
	claw.blockability = BattleTypes.Blockability.FULL_100
	var claw_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.MELEE]
	claw.tags = claw_tags
	dragon.basic_attack = claw
	
	var tail_crush: SkillData = SkillData.new()
	tail_crush.skill_id = "dragon_tail_crush"
	tail_crush.skill_name = "Таран хвостом"
	tail_crush.action_category = BattleTypes.ActionType.SKILL
	tail_crush.target_side = BattleTypes.TargetSide.ENEMY
	tail_crush.damage_type = BattleTypes.DamageType.PHYSICAL
	tail_crush.base_power = 18
	tail_crush.power_multiplier = 1.15
	tail_crush.blockability = BattleTypes.Blockability.MEDIUM_60
	var tail_tags: Array[BattleTypes.SkillTag] = [
		BattleTypes.SkillTag.MELEE,
		BattleTypes.SkillTag.GUARD_BREAK
	]
	tail_crush.tags = tail_tags
	tail_crush.guard_break_ignore_ratio = 1.0
	tail_crush.guard_break_bonus_multiplier = 1.35
	
	var breath_qte: QTEConfigData = QTEConfigData.new()
	breath_qte.qte_type = BattleTypes.QTEType.CIRCULAR_SKILL_CHECK
	breath_qte.duration_seconds = 2.4
	breath_qte.cursor_speed = 1.5
	breath_qte.success_zone_width = 0.24
	breath_qte.perfect_zone_width = 0.08
	
	var fire_breath: SkillData = SkillData.new()
	fire_breath.skill_id = "dragon_fire_breath"
	fire_breath.skill_name = "Огненное дыхание"
	fire_breath.action_category = BattleTypes.ActionType.SKILL
	fire_breath.target_side = BattleTypes.TargetSide.ENEMY
	fire_breath.damage_type = BattleTypes.DamageType.FIRE
	fire_breath.base_power = 26
	fire_breath.power_multiplier = 1.35
	fire_breath.blockability = BattleTypes.Blockability.HIGH_80
	var breath_tags: Array[BattleTypes.SkillTag] = [
		BattleTypes.SkillTag.TELEGRAPHED,
		BattleTypes.SkillTag.DRAGON_FIRE_BREATH
	]
	fire_breath.tags = breath_tags
	fire_breath.is_telegraphed = true
	fire_breath.telegraph_turns = 1
	fire_breath.telegraph_warning_text = "Дракон вдыхает пламя! Открыта уязвимая Шея (щит полностью гасит дыхание)!"
	fire_breath.applies_status = true
	fire_breath.status_to_apply = BattleTypes.StatusType.BURN
	fire_breath.status_duration_turns = 2
	fire_breath.status_apply_chance = 0.75
	fire_breath.requires_qte = true
	fire_breath.qte_config = breath_qte
	
	var dragon_skills: Array[SkillData] = [tail_crush, fire_breath]
	dragon.skills = dragon_skills
	
	dragon.dialogue_intro = "Перед отрядом приземляется Молодой дракон! Его чешуя пылает багровым жаром."
	dragon.dialogue_on_attack = "Дракон рычит и готовит ответный выпад!"
	dragon.dialogue_defeat = "Молодой дракон повержен!"
	return dragon

## Создает runtime-отряд из 4 бойцов для автономного запуска battle_sandbox.tscn по F6
static func create_sandbox_player_party(synergy_catalog: Array[WeaponSynergyData] = []) -> Array[Combatant]:
	var resolved_synergies: Array[WeaponSynergyData] = synergy_catalog
	if resolved_synergies.is_empty():
		resolved_synergies = InventorySandboxFactory.create_synergy_catalog()
	var party: Array[Combatant] = []
	var data_list: Array[CombatantData] = create_sandbox_active_party_data()
	for i: int in range(data_list.size()):
		var d: CombatantData = data_list[i]
		if d != null:
			party.append(Combatant.from_combatant_data(d, d.combatant_id, resolved_synergies))
	return party

static func create_sandbox_enemy_party() -> Array[Combatant]:
	var party: Array[Combatant] = []
	party.append(Combatant.from_enemy_data(create_young_dragon(), "enemy_1"))
	return party

# =========================================================================
# Вспомогательные фабричные конструкторы
# =========================================================================

static func _make_basic_attack(
	p_id: String,
	p_name: String,
	p_desc: String,
	p_dmg_type: BattleTypes.DamageType,
	p_base: int,
	p_energy_restore: int,
	p_is_melee: bool
) -> SkillData:
	var sk: SkillData = SkillData.new()
	sk.skill_id = p_id
	sk.skill_name = p_name
	sk.description = p_desc
	sk.action_category = BattleTypes.ActionType.ATTACK
	sk.target_side = BattleTypes.TargetSide.ENEMY
	sk.resource_type = BattleTypes.ResourceType.ENERGY
	sk.resource_cost = 0
	sk.energy_restore_on_use = p_energy_restore
	sk.damage_type = p_dmg_type
	sk.base_power = p_base
	sk.power_multiplier = 1.0
	sk.blockability = BattleTypes.Blockability.FULL_100
	var tags: Array[BattleTypes.SkillTag] = [
		BattleTypes.SkillTag.MELEE if p_is_melee else BattleTypes.SkillTag.RANGED_ATTACK
	]
	sk.tags = tags
	sk.requires_qte = false
	return sk

static func _make_recruit_ultimate(
	p_id: String,
	p_name: String,
	p_desc: String,
	p_dmg_type: BattleTypes.DamageType,
	p_base: int,
	p_qte_type: BattleTypes.QTEType,
	p_all_enemies: bool = false
) -> SkillData:
	var qte: QTEConfigData = QTEConfigData.new()
	qte.qte_type = p_qte_type
	qte.duration_seconds = 2.6
	qte.cursor_speed = 1.45
	qte.success_zone_width = 0.22
	qte.perfect_zone_width = 0.08
	qte.hold_target_center = 0.75
	qte.hold_charge_speed = 0.72
	qte.mash_target_presses = 10
	
	var ult: SkillData = SkillData.new()
	ult.skill_id = p_id
	ult.skill_name = p_name
	ult.description = p_desc
	ult.action_category = BattleTypes.ActionType.ULTIMATE
	ult.target_side = BattleTypes.TargetSide.ALL_ENEMIES if p_all_enemies else BattleTypes.TargetSide.ENEMY
	ult.resource_type = BattleTypes.ResourceType.TENSION
	ult.damage_type = p_dmg_type
	ult.base_power = p_base
	ult.power_multiplier = 1.40
	ult.blockability = BattleTypes.Blockability.NONE_0
	var tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.UNBLOCKABLE]
	ult.tags = tags
	ult.is_ultimate = true
	ult.min_tension_tier = BattleTypes.TensionTier.HALF_50
	ult.requires_qte = true
	ult.qte_config = qte
	if p_dmg_type == BattleTypes.DamageType.ICE:
		ult.applies_status = true
		ult.status_to_apply = BattleTypes.StatusType.FREEZE
		ult.status_duration_turns = 1
		ult.status_apply_chance = 0.70
	return ult
