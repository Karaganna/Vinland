# res://resources/inventory/weapon_catalog_factory.gd
class_name WeaponCatalogFactory
extends RefCounted

## Data-Driven фабрика оружия (фирменное ГГ, 7 категорий мира, комплекты, легендарки, щиты и синергии)
## Все ресурсы собираются программно без ручного создания .tres файлов

# =========================================================================
# 1. ФИРМЕННОЕ СНАРЯЖЕНИЕ ГЛАВНОГО ГЕРОЯ (is_hero_signature = true)
# =========================================================================

static func create_fathers_spear() -> EquipmentItemData:
	var lunge_qte: QTEConfigData = _make_precision_qte(2.5, 1.35, 0.24, 0.08)
	var spear_lunge: SkillData = SkillData.new()
	spear_lunge.skill_id = "hero_spear_lunge"
	spear_lunge.skill_name = "Выпад"
	spear_lunge.description = "Базовый навык Отцовского копья (QTE Центр): точный укол, выбивающий цель из равновесия."
	spear_lunge.action_category = BattleTypes.ActionType.SKILL
	spear_lunge.target_side = BattleTypes.TargetSide.ENEMY
	spear_lunge.resource_type = BattleTypes.ResourceType.ENERGY
	spear_lunge.resource_cost = 20
	spear_lunge.damage_type = BattleTypes.DamageType.PHYSICAL
	spear_lunge.base_power = 18
	spear_lunge.power_multiplier = 1.15
	spear_lunge.blockability = BattleTypes.Blockability.HIGH_80
	var tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.MELEE]
	spear_lunge.tags = tags
	spear_lunge.applies_status = true
	spear_lunge.status_to_apply = BattleTypes.StatusType.UNBALANCED
	spear_lunge.status_duration_turns = 2
	spear_lunge.requires_qte = true
	spear_lunge.qte_config = lunge_qte
	
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "fathers_spear"
	eq.display_name = "Отцовское копьё"
	eq.description = "Фирменное одноручное копьё ГГ (Поток: Энергия). Со щитом открывает «Скьяльдборг», со свободной рукой — «Держать дистанцию»."
	eq.slot_type = InventoryTypes.EquipmentSlotType.ONE_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.HERO_SIGNATURE
	eq.weapon_type = InventoryTypes.WeaponType.SPEAR
	eq.weapon_archetype = InventoryTypes.WeaponArchetype.SPEAR
	eq.is_unique = true
	eq.is_hero_signature = true
	eq.is_heavy = false
	eq.sets_hero_flow_mode = true
	eq.hero_flow_mode = BattleTypes.ResourceType.ENERGY
	eq.bonus_attack = 6
	eq.bonus_speed = 2
	eq.bonus_crit_chance = 0.05
	var base_skills: Array[SkillData] = [spear_lunge]
	eq.granted_skills = base_skills
	return eq

static func create_fathers_round_shield() -> EquipmentItemData:
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "fathers_round_shield"
	eq.display_name = "Круглый щит"
	eq.description = "Фирменный лёгкий щит ГГ (без штрафа к скорости). Активных навыков не даёт; повышает блок (15% шанс полного блока) и гасит огненное дыхание дракона."
	eq.slot_type = InventoryTypes.EquipmentSlotType.SHIELD_LIGHT
	eq.weapon_category = InventoryTypes.WeaponCategory.HERO_SIGNATURE
	eq.weapon_archetype = InventoryTypes.WeaponArchetype.SHIELD
	eq.is_unique = true
	eq.is_hero_signature = true
	eq.is_heavy = false
	eq.bonus_defense = 6
	eq.bonus_max_hp = 15
	eq.bonus_speed = 0
	eq.shield_enhanced_block_chance = 0.35
	eq.shield_full_block_chance = 0.15
	return eq

static func create_dragonblood_greatsword() -> EquipmentItemData:
	var pierce_qte: QTEConfigData = _make_precision_qte(2.5, 1.40, 0.22, 0.08)
	var pierce_skill: SkillData = SkillData.new()
	pierce_skill.skill_id = "dragonblood_pierce"
	pierce_skill.skill_name = "Пронзающий удар"
	pierce_skill.description = "Точный выпад двуручным клинком (QTE Центр). Скейлится от Потока (Ярость) без траты ресурса и раскалывает броню."
	pierce_skill.action_category = BattleTypes.ActionType.SKILL
	pierce_skill.target_side = BattleTypes.TargetSide.ENEMY
	pierce_skill.resource_type = BattleTypes.ResourceType.RAGE
	pierce_skill.resource_cost = 0
	pierce_skill.damage_type = BattleTypes.DamageType.PHYSICAL
	pierce_skill.base_power = 18
	pierce_skill.power_multiplier = 1.20
	pierce_skill.blockability = BattleTypes.Blockability.HIGH_80
	var p_tags: Array[BattleTypes.SkillTag] = [
		BattleTypes.SkillTag.MELEE,
		BattleTypes.SkillTag.SCALES_WITH_RAGE
	]
	pierce_skill.tags = p_tags
	pierce_skill.applies_status = true
	pierce_skill.status_to_apply = BattleTypes.StatusType.DEFENSE_DOWN
	pierce_skill.status_duration_turns = 3
	pierce_skill.status_stacks_to_apply = 1
	pierce_skill.requires_qte = true
	pierce_skill.qte_config = pierce_qte
	
	# «Рассекающий удар» Меча из крови дракона использует QTE «Удержание» (HOLD_RELEASE)
	var cleave_qte: QTEConfigData = QTEConfigData.new()
	cleave_qte.qte_type = BattleTypes.QTEType.HOLD_RELEASE
	cleave_qte.duration_seconds = 2.8
	cleave_qte.hold_target_center = 0.76
	cleave_qte.hold_charge_speed = 0.72
	cleave_qte.success_zone_width = 0.22
	cleave_qte.perfect_zone_width = 0.08
	
	var cleave_skill: SkillData = SkillData.new()
	cleave_skill.skill_id = "dragonblood_cleave"
	cleave_skill.skill_name = "Рассекающий удар"
	cleave_skill.description = "Тяжёлый пробивной удар (QTE Удержание). Пробивает блок цели; скейлится от Потока (Ярость)."
	cleave_skill.action_category = BattleTypes.ActionType.SKILL
	cleave_skill.target_side = BattleTypes.TargetSide.ENEMY
	cleave_skill.resource_type = BattleTypes.ResourceType.RAGE
	cleave_skill.resource_cost = 25
	cleave_skill.damage_type = BattleTypes.DamageType.PHYSICAL
	cleave_skill.base_power = 26
	cleave_skill.power_multiplier = 1.35
	cleave_skill.blockability = BattleTypes.Blockability.HIGH_80
	var c_tags: Array[BattleTypes.SkillTag] = [
		BattleTypes.SkillTag.MELEE,
		BattleTypes.SkillTag.GUARD_BREAK,
		BattleTypes.SkillTag.SCALES_WITH_RAGE
	]
	cleave_skill.tags = c_tags
	cleave_skill.guard_break_ignore_ratio = 1.0
	cleave_skill.guard_break_bonus_multiplier = 1.35
	cleave_skill.requires_qte = true
	cleave_skill.qte_config = cleave_qte
	
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "dragonblood_greatsword"
	eq.display_name = "Меч из крови дракона"
	eq.description = "Фирменный тяжёлый двуручный меч ГГ (Поток: Ярость). При Потоке ≥ 90% клинок загорается и накладывает Ожог!"
	eq.slot_type = InventoryTypes.EquipmentSlotType.TWO_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.HERO_SIGNATURE
	eq.weapon_type = InventoryTypes.WeaponType.GREATSWORD
	eq.weapon_archetype = InventoryTypes.WeaponArchetype.SWORD
	eq.is_unique = true
	eq.is_hero_signature = true
	eq.is_heavy = true
	eq.sets_hero_flow_mode = true
	eq.hero_flow_mode = BattleTypes.ResourceType.RAGE
	eq.has_flow_threshold_passive = true
	eq.flow_threshold_ratio = 0.90
	eq.flow_threshold_status = BattleTypes.StatusType.BURN
	eq.flow_threshold_status_turns = 2
	eq.flow_threshold_status_magnitude = 1.0
	eq.bonus_attack = 14
	eq.bonus_speed = -2
	eq.bonus_crit_multiplier = 0.25
	var skills_arr: Array[SkillData] = [pierce_skill, cleave_skill]
	eq.granted_skills = skills_arr
	var tags_arr: Array[StringName] = [&"GUARD_BREAK"]
	eq.passive_tags = tags_arr
	eq.override_qte_thresholds = true
	eq.qte_miss_threshold = 0.45
	eq.qte_weak_threshold = 0.70
	eq.qte_perfect_threshold = 0.90
	eq.qte_guaranteed_crit_on_perfect = true
	return eq

# =========================================================================
# 2. ОРУЖИЕ РЕКРУТОВ ПО 7 КАТЕГОРИЯМ, КОМПЛЕКТЫ И ЛЕГЕНДАРКИ
# =========================================================================

## POLEARM (Древковое): Ясеневое копье (1H) и Атгейр (2H, Тяжелое)
static func create_recruit_ash_spear() -> EquipmentItemData:
	var thrust: SkillData = _make_melee_skill(
		"spear_base_thrust",
		"Выпад копьём",
		"Точный укол копьём с шансом выбить цель из равновесия.",
		18,
		16,
		1.10,
		true
	)
	thrust.applies_status = true
	thrust.status_to_apply = BattleTypes.StatusType.UNBALANCED
	thrust.status_duration_turns = 2
	
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "recruit_ash_spear"
	eq.display_name = "Ясеневое копьё"
	eq.description = "Древковое одноручное копьё для рекрутов. Со щитом даёт «Начеку», со свободной рукой — «Держать дистанцию»."
	eq.slot_type = InventoryTypes.EquipmentSlotType.ONE_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.POLEARM
	eq.weapon_type = InventoryTypes.WeaponType.SPEAR
	eq.bonus_attack = 6
	eq.bonus_speed = 2
	var sk: Array[SkillData] = [thrust]
	eq.granted_skills = sk
	return eq

static func create_nordic_atgeir() -> EquipmentItemData:
	var sweep: SkillData = _make_melee_skill(
		"atgeir_wide_sweep",
		"Широкий взмах",
		"Круговой удар атгейром по всем врагам.",
		22,
		15,
		1.05,
		true
	)
	sweep.target_side = BattleTypes.TargetSide.ALL_ENEMIES
	
	var hook_trip: SkillData = _make_melee_skill(
		"atgeir_trip_finish",
		"Подсечка древком",
		"Сбивает с ног цель, потерявшую равновесие.",
		20,
		19,
		1.20,
		true
	)
	var t_tags: Array[BattleTypes.SkillTag] = [
		BattleTypes.SkillTag.MELEE,
		BattleTypes.SkillTag.FINISH_UNBALANCED
	]
	hook_trip.tags = t_tags
	
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "nordic_atgeir"
	eq.display_name = "Северный атгейр"
	eq.description = "Тяжёлое двуручное древковое оружие (2 базовых навыка)."
	eq.slot_type = InventoryTypes.EquipmentSlotType.TWO_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.POLEARM
	eq.weapon_type = InventoryTypes.WeaponType.ATGEIR
	eq.is_heavy = true
	eq.bonus_attack = 11
	eq.bonus_speed = -1
	var sk: Array[SkillData] = [sweep, hook_trip]
	eq.granted_skills = sk
	return eq

## LONG_BLADES (Длинные клинки): Хольмсверд (1H), Легендарный хольмсверд «Слово чести», Меч и Лангсакс
static func create_duelist_holmsverd() -> EquipmentItemData:
	var duel_cut: SkillData = _make_melee_skill(
		"holmsverd_duel_cut",
		"Поединковый выпад",
		"Точный клинковый удар дуэлянта (повышенный множитель с QTE Центр).",
		18,
		19,
		1.20,
		true
	)
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "duelist_holmsverd"
	eq.display_name = "Поединковый хольмсверд"
	eq.description = "Одноручный дуэльный клинок. Со свободной второй рукой (или у однорукого бойца) открывает стойку «Вызов»."
	eq.slot_type = InventoryTypes.EquipmentSlotType.ONE_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.LONG_BLADES
	eq.weapon_type = InventoryTypes.WeaponType.HOLMSVERD
	eq.bonus_attack = 8
	eq.bonus_speed = 2
	eq.bonus_crit_chance = 0.08
	var sk: Array[SkillData] = [duel_cut]
	eq.granted_skills = sk
	return eq

static func create_word_of_honor_holmsverd() -> EquipmentItemData:
	var eq: EquipmentItemData = create_duelist_holmsverd()
	eq.item_id = "legendary_word_of_honor"
	eq.display_name = "Хольмсверд «Слово чести»"
	eq.description = "Легендарный хольмсверд тинга. Даёт навыки типа (+синергию свободной руки «Вызов») и 2 легендарных умения поединщика."
	eq.is_legendary = true
	eq.is_unique = true
	eq.bonus_attack = 13
	eq.bonus_speed = 3
	eq.bonus_crit_chance = 0.14
	
	var oath_mark: SkillData = SkillData.new()
	oath_mark.skill_id = "leg_duelist_oath"
	oath_mark.skill_name = "Клятва поединщика"
	oath_mark.description = "Легендарный навык: накладывает Отметку на врага (+25% вх. урона и +15% шанс крита по нему)."
	oath_mark.action_category = BattleTypes.ActionType.SKILL
	oath_mark.target_side = BattleTypes.TargetSide.ENEMY
	oath_mark.resource_type = BattleTypes.ResourceType.ENERGY
	oath_mark.resource_cost = 15
	oath_mark.damage_type = BattleTypes.DamageType.PHYSICAL
	oath_mark.base_power = 10
	oath_mark.power_multiplier = 1.0
	oath_mark.applies_status = true
	oath_mark.status_to_apply = BattleTypes.StatusType.MARKED
	oath_mark.status_duration_turns = 3
	
	var steel_verdict: SkillData = _make_melee_skill(
		"leg_steel_verdict",
		"Суд стали",
		"Легендарный рассекающий приговор с пробитием блока.",
		28,
		26,
		1.35,
		true
	)
	var v_tags: Array[BattleTypes.SkillTag] = [
		BattleTypes.SkillTag.MELEE,
		BattleTypes.SkillTag.GUARD_BREAK
	]
	steel_verdict.tags = v_tags
	
	var leg_list: Array[SkillData] = [oath_mark, steel_verdict]
	eq.legendary_skills = leg_list
	return eq

static func create_nordic_sword() -> EquipmentItemData:
	var slash: SkillData = _make_melee_skill(
		"sword_clean_slash",
		"Рассечение мечом",
		"Сбалансированный рубящий удар одноручным мечом.",
		18,
		17,
		1.15,
		true
	)
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "nordic_sword"
	eq.display_name = "Северный меч"
	eq.description = "Одноручный меч (Длинные клинки). В паре с другим клинком без общей синергии даёт свой базовый навык."
	eq.slot_type = InventoryTypes.EquipmentSlotType.ONE_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.LONG_BLADES
	eq.weapon_type = InventoryTypes.WeaponType.SWORD
	eq.bonus_attack = 7
	eq.bonus_defense = 1
	var sk: Array[SkillData] = [slash]
	eq.granted_skills = sk
	return eq

static func create_iron_langsax() -> EquipmentItemData:
	var rend: SkillData = _make_melee_skill(
		"langsax_bleed_cut",
		"Рваный рез лангсакса",
		"Тяжёлый рез однолезвийным клинком, вызывающий Кровотечение.",
		20,
		16,
		1.15,
		true
	)
	rend.applies_status = true
	rend.status_to_apply = BattleTypes.StatusType.BLEED
	rend.status_duration_turns = 3
	rend.status_stacks_to_apply = 1
	
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "iron_langsax"
	eq.display_name = "Железный лангсакс"
	eq.description = "Длинный однолезвийный клинок (Длинные клинки)."
	eq.slot_type = InventoryTypes.EquipmentSlotType.ONE_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.LONG_BLADES
	eq.weapon_type = InventoryTypes.WeaponType.LANGSAX
	eq.bonus_attack = 8
	var sk: Array[SkillData] = [rend]
	eq.granted_skills = sk
	return eq

## SHORT_BLADES (Короткие клинки): Сакс (1H) и неделимый парный комплект «Сёстры» (is_set_bundle)
static func create_raider_seax() -> EquipmentItemData:
	var quick_cut: SkillData = _make_melee_skill(
		"seax_rib_cut",
		"Удар под рёбра",
		"Быстрый укол саксом с наложением Кровотечения.",
		15,
		14,
		1.10,
		true
	)
	quick_cut.applies_status = true
	quick_cut.status_to_apply = BattleTypes.StatusType.BLEED
	quick_cut.status_duration_turns = 3
	
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "raider_seax"
	eq.display_name = "Волчий сакс"
	eq.description = "Короткий клинок. Два сакса открывают парную синергию «Вихрь саксов»."
	eq.slot_type = InventoryTypes.EquipmentSlotType.ONE_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.SHORT_BLADES
	eq.weapon_type = InventoryTypes.WeaponType.SEAX
	eq.is_heavy = false
	eq.bonus_attack = 5
	eq.bonus_speed = 3
	eq.bonus_crit_chance = 0.06
	var sk: Array[SkillData] = [quick_cut]
	eq.granted_skills = sk
	return eq

static func create_sisters_twin_blades_set() -> EquipmentItemData:
	var dance: SkillData = _make_melee_skill(
		"set_sisters_dance",
		"Танец «Сестёр»",
		"Двойной синхронный выпад парными кинжалами комплекта.",
		20,
		12,
		1.0,
		true
	)
	dance.hit_count = 2
	
	var venom_fang: SkillData = _make_melee_skill(
		"set_sisters_venom",
		"Змеиный росчерк",
		"Режущий удар комплекта, отравляющий кровь врага.",
		22,
		16,
		1.15,
		true
	)
	venom_fang.applies_status = true
	venom_fang.status_to_apply = BattleTypes.StatusType.POISON
	venom_fang.status_duration_turns = 3
	
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "set_sisters_daggers"
	eq.display_name = "Парные клинки «Сёстры»"
	eq.description = "Неделимый парный комплект кинжалов на обе руки (недоступен одноруким бойцам)."
	eq.slot_type = InventoryTypes.EquipmentSlotType.TWO_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.SHORT_BLADES
	eq.weapon_type = InventoryTypes.WeaponType.DAGGER
	eq.is_set_bundle = true
	eq.is_unique = true
	eq.is_heavy = false
	eq.bonus_attack = 10
	eq.bonus_speed = 5
	eq.bonus_crit_chance = 0.12
	var sk: Array[SkillData] = [dance, venom_fang]
	eq.granted_skills = sk
	return eq

## RANGED (Стрелковое): Лук, Легендарный длинный лук «Тисовая вдова», Самострел и Праща (SLING)
static func create_hunter_bow() -> EquipmentItemData:
	var aimed: SkillData = _make_ranged_skill(
		"bow_aimed_shot",
		"Прицельный выстрел",
		"Точный выстрел из охотничьего лука (QTE Центр).",
		18,
		17,
		1.15
	)
	var pin_shot: SkillData = _make_ranged_skill(
		"bow_pinning_arrow",
		"Пригвождающая стрела",
		"Прибивает подол/лапу цели к земле, лишая её уклонения (На привязи).",
		20,
		14,
		1.05
	)
	pin_shot.applies_status = true
	pin_shot.status_to_apply = BattleTypes.StatusType.TETHERED
	pin_shot.status_duration_turns = 2
	
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "hunter_bow"
	eq.display_name = "Охотничий лук"
	eq.description = "Двуручный стрелковый лук (2 базовых навыка)."
	eq.slot_type = InventoryTypes.EquipmentSlotType.TWO_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.RANGED
	eq.weapon_type = InventoryTypes.WeaponType.BOW
	eq.weapon_archetype = InventoryTypes.WeaponArchetype.BOW
	eq.is_heavy = false
	eq.bonus_attack = 8
	eq.bonus_crit_chance = 0.08
	var sk: Array[SkillData] = [aimed, pin_shot]
	eq.granted_skills = sk
	return eq

static func create_yew_widow_longbow() -> EquipmentItemData:
	var armor_pierce: SkillData = _make_ranged_skill(
		"longbow_bodkin_pierce",
		"Бронебойная стрела",
		"Тяжёлая стрела длинного лука: накладывает стакающийся Раскол брони до конца боя.",
		22,
		19,
		1.20
	)
	armor_pierce.applies_status = true
	armor_pierce.status_to_apply = BattleTypes.StatusType.DEFENSE_DOWN
	armor_pierce.status_is_permanent = true
	armor_pierce.status_stacks_to_apply = 1
	
	var far_shot: SkillData = _make_ranged_skill(
		"longbow_far_volley",
		"Дальний настил",
		"Мощный выстрел через всю арену.",
		20,
		21,
		1.20
	)
	
	var widow_arrow: SkillData = _make_ranged_skill(
		"leg_widow_heartseeker",
		"Стрела «Вдовы»",
		"Легендарный выстрел с пробитием блока и огромным уроном по отмеченной цели.",
		30,
		28,
		1.40
	)
	var w_tags: Array[BattleTypes.SkillTag] = [
		BattleTypes.SkillTag.RANGED_ATTACK,
		BattleTypes.SkillTag.GUARD_BREAK
	]
	widow_arrow.tags = w_tags
	
	var rime_arrow: SkillData = _make_ranged_skill(
		"leg_widow_rime_shot",
		"Инеевое оперение",
		"Легендарный выстрел холодом Скади, замораживающий цель на 1 ход.",
		28,
		18,
		1.15
	)
	rime_arrow.damage_type = BattleTypes.DamageType.ICE
	rime_arrow.applies_status = true
	rime_arrow.status_to_apply = BattleTypes.StatusType.FREEZE
	rime_arrow.status_duration_turns = 1
	rime_arrow.status_apply_chance = 0.85
	
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "legendary_yew_widow"
	eq.display_name = "Длинный лук «Тисовая вдова»"
	eq.description = "Легендарный длинный лук: 2 базовых навыка типа LONG_BOW + 2 уникальных легендарных умения."
	eq.slot_type = InventoryTypes.EquipmentSlotType.TWO_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.RANGED
	eq.weapon_type = InventoryTypes.WeaponType.LONG_BOW
	eq.weapon_archetype = InventoryTypes.WeaponArchetype.BOW
	eq.is_legendary = true
	eq.is_unique = true
	eq.is_heavy = false
	eq.bonus_attack = 14
	eq.bonus_crit_chance = 0.15
	eq.bonus_crit_multiplier = 0.25
	var base_sk: Array[SkillData] = [armor_pierce, far_shot]
	var leg_sk: Array[SkillData] = [widow_arrow, rime_arrow]
	eq.granted_skills = base_sk
	eq.legendary_skills = leg_sk
	return eq

static func create_hand_crossbow() -> EquipmentItemData:
	var bolt: SkillData = _make_ranged_skill(
		"crossbow_snap_bolt",
		"Болт навскидку",
		"Короткий выстрел из ручного самострела с пробитием защиты.",
		18,
		16,
		1.15
	)
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "hand_crossbow"
	eq.display_name = "Ручной самострел"
	eq.description = "Одноручный самострел (Стрелковое). Два самострела открывают «Парный залп» (требует перезарядки)."
	eq.slot_type = InventoryTypes.EquipmentSlotType.ONE_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.RANGED
	eq.weapon_type = InventoryTypes.WeaponType.CROSSBOW
	eq.is_heavy = false
	eq.bonus_attack = 7
	eq.bonus_crit_chance = 0.06
	var sk: Array[SkillData] = [bolt]
	eq.granted_skills = sk
	return eq

## TODO (GDD): черновые навыки одноручной пращи (SLING) — уточнить при финализации дизайн-дока
static func create_leather_sling() -> EquipmentItemData:
	# TODO (GDD): Заменить черновой базовый навык пращи после утверждения описания в дизайн-доке
	var stone_cast: SkillData = _make_ranged_skill(
		"sling_stone_cast",
		"Хлёсткий камень",
		"Дальний бросок свинчатки из пращи с шансом выбить врага из равновесия.",
		14,
		13,
		1.10
	)
	stone_cast.applies_status = true
	stone_cast.status_to_apply = BattleTypes.StatusType.UNBALANCED
	stone_cast.status_duration_turns = 2
	stone_cast.status_apply_chance = 0.65
	
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "braided_leather_sling"
	eq.display_name = "Плетёная праща"
	eq.description = "Одноручная праща (Стрелковое). Со свободной рукой или лёгким щитом открывает «Ослепляющий пращный залп»."
	eq.slot_type = InventoryTypes.EquipmentSlotType.ONE_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.RANGED
	eq.weapon_type = InventoryTypes.WeaponType.SLING
	eq.is_heavy = false
	eq.bonus_attack = 5
	eq.bonus_speed = 3
	eq.bonus_crit_chance = 0.07
	var sk: Array[SkillData] = [stone_cast]
	eq.granted_skills = sk
	return eq

## BLUNT (Дробящее): Бородатый топор (1H) и Кистень (1H с обходом щита IGNORES_SHIELD)
static func create_bearded_axe() -> EquipmentItemData:
	var hook_chop: SkillData = _make_melee_skill(
		"bearded_axe_chop",
		"Зацеп бородой топора",
		"Срывает защиту противника, накладывая Раскол брони.",
		18,
		16,
		1.15,
		true
	)
	hook_chop.applies_status = true
	hook_chop.status_to_apply = BattleTypes.StatusType.DEFENSE_DOWN
	hook_chop.status_duration_turns = 3
	
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "raider_axe"
	eq.display_name = "Бородатый топор"
	eq.description = "Одноручный топор (Дробящее). Два бородатых топора открывают синергию «Прыжок берсерка»."
	eq.slot_type = InventoryTypes.EquipmentSlotType.ONE_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.BLUNT
	eq.weapon_type = InventoryTypes.WeaponType.BEARDED_AXE
	eq.weapon_archetype = InventoryTypes.WeaponArchetype.AXE
	eq.bonus_attack = 7
	eq.bonus_speed = 1
	var sk: Array[SkillData] = [hook_chop]
	eq.granted_skills = sk
	return eq

static func create_iron_flail() -> EquipmentItemData:
	var chain_smash: SkillData = _make_melee_skill(
		"flail_wrap_strike",
		"Хлёст через щит",
		"Гибкая цепь кистеня огибает щит цели (IGNORES_SHIELD) и оглушает при удачном попадании.",
		20,
		17,
		1.15,
		true
	)
	var f_tags: Array[BattleTypes.SkillTag] = [
		BattleTypes.SkillTag.MELEE,
		BattleTypes.SkillTag.IGNORES_SHIELD
	]
	chain_smash.tags = f_tags
	chain_smash.applies_status = true
	chain_smash.status_to_apply = BattleTypes.StatusType.STUN
	chain_smash.status_duration_turns = 1
	chain_smash.status_apply_chance = 0.35
	
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "iron_chain_flail"
	eq.display_name = "Боевой кистень"
	eq.description = "Одноручное цепное оружие (Дробящее, Тяжёлое). Все атаки игнорируют защиту и пассивный блок щита!"
	eq.slot_type = InventoryTypes.EquipmentSlotType.ONE_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.BLUNT
	eq.weapon_type = InventoryTypes.WeaponType.FLAIL
	eq.is_heavy = true
	eq.bonus_attack = 9
	eq.bonus_speed = -1
	var p_tags: Array[StringName] = [&"IGNORES_SHIELD"]
	eq.passive_tags = p_tags
	var sk: Array[SkillData] = [chain_smash]
	eq.granted_skills = sk
	return eq

## CRUSHING (Сокрушающее): Датский топор (2H, Тяжелое)
static func create_dane_axe() -> EquipmentItemData:
	var shield_split: SkillData = _make_melee_skill(
		"dane_axe_split",
		"Раскол щита",
		"Сокрушительный удар датским топором с пробитием блока (GUARD_BREAK).",
		22,
		24,
		1.30,
		true
	)
	var s_tags: Array[BattleTypes.SkillTag] = [
		BattleTypes.SkillTag.MELEE,
		BattleTypes.SkillTag.GUARD_BREAK,
		BattleTypes.SkillTag.SCALES_WITH_RAGE
	]
	shield_split.tags = s_tags
	
	var blood_reap: SkillData = _make_melee_skill(
		"dane_axe_reap",
		"Кровавая жатва",
		"Бесплатный размашистый удар, скейлящийся от накопленной Ярости.",
		0,
		16,
		1.15,
		true
	)
	var r_tags: Array[BattleTypes.SkillTag] = [
		BattleTypes.SkillTag.MELEE,
		BattleTypes.SkillTag.SCALES_WITH_RAGE
	]
	blood_reap.tags = r_tags
	
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "heavy_dane_axe"
	eq.display_name = "Датский топор"
	eq.description = "Тяжёлое двуручное оружие категории «Сокрушающее» (2 базовых навыка)."
	eq.slot_type = InventoryTypes.EquipmentSlotType.TWO_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.CRUSHING
	eq.weapon_type = InventoryTypes.WeaponType.DANE_AXE
	eq.is_heavy = true
	eq.bonus_attack = 13
	eq.bonus_speed = -2
	var sk: Array[SkillData] = [shield_split, blood_reap]
	eq.granted_skills = sk
	return eq

## RELICS (Реликвии с проверкой Даров): Песенная таблица (VOICE) и Оберег (CHARM)
static func create_song_tablet() -> EquipmentItemData:
	var rhythm_cfg: QTEConfigData = QTEConfigData.new()
	rhythm_cfg.qte_type = BattleTypes.QTEType.RHYTHM_TRACK
	rhythm_cfg.bpm = 120.0
	rhythm_cfg.note_count = 5
	var lanes: Array[int] = [0, 1, 2, 3, 1]
	rhythm_cfg.note_lanes = lanes
	var beats: Array[float] = [1.0, 2.0, 3.0, 4.0, 5.0]
	rhythm_cfg.note_beat_offsets = beats
	
	var galdr_verse: SkillData = SkillData.new()
	galdr_verse.skill_id = "relic_galdr_verse"
	galdr_verse.skill_name = "Строфа гальдра"
	galdr_verse.description = "Звуковой заговор по врагу (ритм-QTE Ноты), ослабляющий его натиск."
	galdr_verse.action_category = BattleTypes.ActionType.SKILL
	galdr_verse.target_side = BattleTypes.TargetSide.ENEMY
	galdr_verse.resource_type = BattleTypes.ResourceType.MANA
	galdr_verse.resource_cost = 20
	galdr_verse.damage_type = BattleTypes.DamageType.SOUND
	galdr_verse.base_power = 16
	galdr_verse.power_multiplier = 1.20
	galdr_verse.blockability = BattleTypes.Blockability.LOW_40
	var g_tags: Array[BattleTypes.SkillTag] = [
		BattleTypes.SkillTag.SOUND_BASED,
		BattleTypes.SkillTag.CAUSES_CALM
	]
	galdr_verse.tags = g_tags
	galdr_verse.applies_status = true
	galdr_verse.status_to_apply = BattleTypes.StatusType.ATTACK_DOWN
	galdr_verse.status_duration_turns = 2
	galdr_verse.requires_qte = true
	galdr_verse.qte_config = rhythm_cfg
	
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "skald_song_tablet"
	eq.display_name = "Песенная таблица"
	eq.description = "Реликвия (требуется Дар «Голос»). Со свободной рукой открывает «Гимн оберега»."
	eq.slot_type = InventoryTypes.EquipmentSlotType.ONE_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.RELICS
	eq.weapon_type = InventoryTypes.WeaponType.SONG_TABLET
	eq.required_gift = InventoryTypes.RelicGift.VOICE
	eq.is_heavy = false
	eq.bonus_magic_power = 9
	eq.bonus_speed = 1
	var sk: Array[SkillData] = [galdr_verse]
	eq.granted_skills = sk
	return eq

static func create_healer_charm() -> EquipmentItemData:
	var mend: SkillData = SkillData.new()
	mend.skill_id = "relic_charm_mend"
	mend.skill_name = "Заговор раны"
	mend.description = "Целебный заговор Реликвии: восстанавливает здоровье выбранному союзнику."
	mend.action_category = BattleTypes.ActionType.SKILL
	mend.target_side = BattleTypes.TargetSide.ALLY
	mend.resource_type = BattleTypes.ResourceType.MANA
	mend.resource_cost = 18
	mend.base_heal_amount = 38
	
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "bone_charm_amulet"
	eq.display_name = "Костяной оберег"
	eq.description = "Реликвия (требуется Дар «Заговор»). Исцеляет союзников и накладывает защитный барьер."
	eq.slot_type = InventoryTypes.EquipmentSlotType.ONE_HAND
	eq.weapon_category = InventoryTypes.WeaponCategory.RELICS
	eq.weapon_type = InventoryTypes.WeaponType.CHARM_AMULET
	eq.required_gift = InventoryTypes.RelicGift.CHARM
	eq.is_heavy = false
	eq.bonus_magic_power = 8
	eq.bonus_max_hp = 15
	var sk: Array[SkillData] = [mend]
	eq.granted_skills = sk
	return eq

# =========================================================================
# 3. ЩИТЫ (БЕЗ АКТИВНЫХ НАВЫКОВ!), БРОНЯ И АКСЕССУАРЫ
# =========================================================================

static func create_scout_light_shield() -> EquipmentItemData:
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "scout_light_shield"
	eq.display_name = "Лёгкий щит разведчика"
	eq.description = "Лёгкий щит рекрутов (без штрафа к скорости). Навыков не даёт; в стойке Блок 15% шанс полного блока."
	eq.slot_type = InventoryTypes.EquipmentSlotType.SHIELD_LIGHT
	eq.weapon_archetype = InventoryTypes.WeaponArchetype.SHIELD
	eq.is_heavy = false
	eq.bonus_defense = 5
	eq.bonus_max_hp = 10
	eq.bonus_speed = 0
	eq.shield_enhanced_block_chance = 0.35
	eq.shield_full_block_chance = 0.15
	return eq

static func create_hird_heavy_shield() -> EquipmentItemData:
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "hird_heavy_shield"
	eq.display_name = "Тяжёлый щит хирдмана"
	eq.description = "Тяжёлый щит рекрутов (-2 СКР, требует can_wear_heavy). Навыков не даёт; в стойке Блок 35% шанс полного 100% блока!"
	eq.slot_type = InventoryTypes.EquipmentSlotType.SHIELD_HEAVY
	eq.weapon_archetype = InventoryTypes.WeaponArchetype.SHIELD
	eq.is_heavy = true
	eq.bonus_defense = 10
	eq.bonus_max_hp = 28
	eq.bonus_speed = -2
	eq.shield_enhanced_block_chance = 0.45
	eq.shield_full_block_chance = 0.35
	return eq

static func create_seafarer_mail() -> EquipmentItemData:
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "seafarer_mail"
	eq.display_name = "Кольчуга морехода"
	eq.description = "Лёгкая клёпаная кольчуга (доступна всем бойцам)."
	eq.slot_type = InventoryTypes.EquipmentSlotType.BODY
	eq.is_heavy = false
	eq.bonus_defense = 7
	eq.bonus_max_hp = 25
	return eq

static func create_varangian_heavy_armor() -> EquipmentItemData:
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "varangian_heavy_armor"
	eq.display_name = "Доспех варяга"
	eq.description = "Тяжёлый пластинчатый доспех (метка «Тяжёлое»: недоступен лёгким классам)."
	eq.slot_type = InventoryTypes.EquipmentSlotType.BODY
	eq.is_heavy = true
	eq.bonus_defense = 13
	eq.bonus_max_hp = 45
	eq.bonus_speed = -2
	return eq

# =========================================================================
# 4. ПОЛНЫЙ КАТАЛОГ СИНЕРГИЙ ВТОРОЙ РУКИ
# =========================================================================

static func create_synergy_catalog() -> Array[WeaponSynergyData]:
	var list: Array[WeaponSynergyData] = []
	
	# 1. Фирменное Копьё ГГ + Щит -> Скьяльдборг (QTE Круг: таунт + защита союзников без базового Блока)
	var skjald_qte: QTEConfigData = QTEConfigData.new()
	skjald_qte.qte_type = BattleTypes.QTEType.CIRCULAR_SKILL_CHECK
	skjald_qte.duration_seconds = 2.4
	skjald_qte.cursor_speed = 1.45
	skjald_qte.success_zone_width = 0.24
	skjald_qte.perfect_zone_width = 0.08
	
	var skjaldborg: SkillData = SkillData.new()
	skjaldborg.skill_id = "synergy_skjaldborg"
	skjaldborg.skill_name = "Скьяльдборг"
	skjaldborg.description = "Синергия (Отцовское копьё + Щит, QTE Круг): провокация врагов и -25% урона по отряду на 2 хода."
	skjaldborg.action_category = BattleTypes.ActionType.SKILL
	skjaldborg.target_side = BattleTypes.TargetSide.SELF
	skjaldborg.resource_type = BattleTypes.ResourceType.ENERGY
	skjaldborg.resource_cost = 20
	skjaldborg.applies_ally_ward = true
	skjaldborg.ally_ward_damage_reduction = 0.25
	skjaldborg.ally_ward_duration_turns = 2
	skjaldborg.applies_status = true
	skjaldborg.status_to_apply = BattleTypes.StatusType.TAUNT
	skjaldborg.status_duration_turns = 2
	var sk_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.TAUNT]
	skjaldborg.tags = sk_tags
	skjaldborg.requires_qte = true
	skjaldborg.qte_config = skjald_qte
	
	var syn_hero_spear_shield: WeaponSynergyData = WeaponSynergyData.new()
	syn_hero_spear_shield.synergy_id = "syn_hero_spear_shield"
	syn_hero_spear_shield.display_name = "Скьяльдборг"
	syn_hero_spear_shield.description = "Отцовское копьё + Щит: открывает «Скьяльдборг»."
	syn_hero_spear_shield.primary_weapon_type = InventoryTypes.WeaponType.SPEAR
	syn_hero_spear_shield.condition = InventoryTypes.HandSynergyCondition.ANY_SHIELD
	syn_hero_spear_shield.hero_signature_only = true
	syn_hero_spear_shield.granted_skill = skjaldborg
	list.append(syn_hero_spear_shield)
	
	# 2. Копьё (и ГГ, и рекрутов) + Свободная рука -> Держать дистанцию (INTERCEPT_MELEE)
	var keep_dist: SkillData = SkillData.new()
	keep_dist.skill_id = "synergy_spear_keep_distance"
	keep_dist.skill_name = "Держать дистанцию"
	keep_dist.description = "Синергия (Копьё + Свободная рука): стойка перехвата ближней атаки врага контрударом."
	keep_dist.action_category = BattleTypes.ActionType.SKILL
	keep_dist.target_side = BattleTypes.TargetSide.SELF
	keep_dist.resource_type = BattleTypes.ResourceType.ENERGY
	keep_dist.resource_cost = 15
	keep_dist.enters_stance = true
	keep_dist.stance_status = BattleTypes.StatusType.INTERCEPT_MELEE
	keep_dist.stance_duration_turns = 1
	
	var syn_spear_empty: WeaponSynergyData = WeaponSynergyData.new()
	syn_spear_empty.synergy_id = "syn_spear_empty_hand"
	syn_spear_empty.display_name = "Держать дистанцию"
	syn_spear_empty.description = "Копьё + Свободная рука: открывает стойку «Держать дистанцию»."
	syn_spear_empty.primary_weapon_type = InventoryTypes.WeaponType.SPEAR
	syn_spear_empty.condition = InventoryTypes.HandSynergyCondition.EMPTY_HAND
	syn_spear_empty.granted_skill = keep_dist
	list.append(syn_spear_empty)
	
	# 3. Копьё рекрута + Щит -> Стойка «Начеку» (COVER_ALLY)
	var cover_ally_sk: SkillData = SkillData.new()
	cover_ally_sk.skill_id = "synergy_spear_cover_ally"
	cover_ally_sk.skill_name = "Начеку"
	cover_ally_sk.description = "Синергия (Копьё + Щит): прикрывает выбранного союзника, перехватывая удары по нему (-30% урона)."
	cover_ally_sk.action_category = BattleTypes.ActionType.SKILL
	cover_ally_sk.target_side = BattleTypes.TargetSide.ALLY
	cover_ally_sk.resource_type = BattleTypes.ResourceType.ENERGY
	cover_ally_sk.resource_cost = 15
	cover_ally_sk.enters_stance = true
	cover_ally_sk.stance_status = BattleTypes.StatusType.COVER_ALLY
	cover_ally_sk.stance_duration_turns = 2
	
	var syn_rec_spear_shield: WeaponSynergyData = WeaponSynergyData.new()
	syn_rec_spear_shield.synergy_id = "syn_recruit_spear_shield"
	syn_rec_spear_shield.display_name = "Начеку"
	syn_rec_spear_shield.description = "Копьё + Щит: открывает защитное прикрытие союзника «Начеку»."
	syn_rec_spear_shield.primary_weapon_type = InventoryTypes.WeaponType.SPEAR
	syn_rec_spear_shield.condition = InventoryTypes.HandSynergyCondition.ANY_SHIELD
	syn_rec_spear_shield.recruit_only = true
	syn_rec_spear_shield.granted_skill = cover_ally_sk
	list.append(syn_rec_spear_shield)
	
	# 4. Хольмсверд + Свободная рука (в т.ч. однорукий Хольмгангер!) -> Стойка «Вызов» (PARRY_STANCE)
	var challenge_sk: SkillData = SkillData.new()
	challenge_sk.skill_id = "synergy_holmsverd_challenge"
	challenge_sk.skill_name = "Вызов"
	challenge_sk.description = "Синергия (Хольмсверд + Свободная рука): стойка дуэлянта — проверка «Круг» на каждую атаку с контратакой!"
	challenge_sk.action_category = BattleTypes.ActionType.SKILL
	challenge_sk.target_side = BattleTypes.TargetSide.SELF
	challenge_sk.resource_type = BattleTypes.ResourceType.ENERGY
	challenge_sk.resource_cost = 18
	challenge_sk.enters_stance = true
	challenge_sk.stance_status = BattleTypes.StatusType.PARRY_STANCE
	challenge_sk.stance_duration_turns = 1
	
	var syn_holmsverd_empty: WeaponSynergyData = WeaponSynergyData.new()
	syn_holmsverd_empty.synergy_id = "syn_holmsverd_empty_hand"
	syn_holmsverd_empty.display_name = "Стойка «Вызов»"
	syn_holmsverd_empty.description = "Хольмсверд + Свободная рука: открывает дуэльное парирование «Вызов»."
	syn_holmsverd_empty.primary_weapon_type = InventoryTypes.WeaponType.HOLMSVERD
	syn_holmsverd_empty.condition = InventoryTypes.HandSynergyCondition.EMPTY_HAND
	syn_holmsverd_empty.granted_skill = challenge_sk
	list.append(syn_holmsverd_empty)
	
	# 5. Бородатый топор + Бородатый топор -> Прыжок берсерка
	var berserk_leap: SkillData = _make_melee_skill(
		"synergy_berserker_leap",
		"Прыжок берсерка",
		"Синергия (2 Бородатых топора): двойной рубящий удар с Кровотечением.",
		20,
		11,
		0.95,
		false
	)
	berserk_leap.hit_count = 2
	var bl_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.MELEE, BattleTypes.SkillTag.NO_GUARD]
	berserk_leap.tags = bl_tags
	berserk_leap.no_guard_incoming_multiplier = 1.35
	berserk_leap.applies_status = true
	berserk_leap.status_to_apply = BattleTypes.StatusType.BLEED
	berserk_leap.status_duration_turns = 3
	
	var syn_axes: WeaponSynergyData = WeaponSynergyData.new()
	syn_axes.synergy_id = "syn_dual_bearded_axe"
	syn_axes.display_name = "Прыжок берсерка"
	syn_axes.description = "Бородатый топор ×2: открывает двойной удар «Прыжок берсерка»."
	syn_axes.primary_weapon_type = InventoryTypes.WeaponType.BEARDED_AXE
	syn_axes.condition = InventoryTypes.HandSynergyCondition.SAME_TYPE
	syn_axes.granted_skill = berserk_leap
	list.append(syn_axes)
	
	# 6. Сакс + Сакс -> Вихрь саксов
	var seax_flurry: SkillData = _make_melee_skill(
		"synergy_seax_flurry",
		"Вихрь саксов",
		"Синергия (2 Сакса): стремительный двойной порез (2 стака Кровотечения).",
		18,
		10,
		1.0,
		true
	)
	seax_flurry.hit_count = 2
	seax_flurry.applies_status = true
	seax_flurry.status_to_apply = BattleTypes.StatusType.BLEED
	seax_flurry.status_duration_turns = 3
	seax_flurry.status_stacks_to_apply = 1
	
	var syn_seaxes: WeaponSynergyData = WeaponSynergyData.new()
	syn_seaxes.synergy_id = "syn_dual_seax"
	syn_seaxes.display_name = "Вихрь саксов"
	syn_seaxes.description = "Сакс ×2: открывает быстрый двойной порез «Вихрь саксов»."
	syn_seaxes.primary_weapon_type = InventoryTypes.WeaponType.SEAX
	syn_seaxes.condition = InventoryTypes.HandSynergyCondition.SAME_TYPE
	syn_seaxes.granted_skill = seax_flurry
	list.append(syn_seaxes)
	
	# 7. Самострел + Самострел -> Парный залп (накладывает RELOAD_REQUIRED на стрелка)
	var twin_bolts: SkillData = _make_ranged_skill(
		"synergy_twin_crossbows",
		"Парный залп",
		"Синергия (2 Самострела): мощный двойной выстрел; после выстрела требуется Перезарядка.",
		22,
		15,
		1.15
	)
	twin_bolts.hit_count = 2
	
	var syn_crossbows: WeaponSynergyData = WeaponSynergyData.new()
	syn_crossbows.synergy_id = "syn_dual_crossbow"
	syn_crossbows.display_name = "Парный залп"
	syn_crossbows.description = "Самострел ×2: открывает двойной выстрел «Парный залп»."
	syn_crossbows.primary_weapon_type = InventoryTypes.WeaponType.CROSSBOW
	syn_crossbows.condition = InventoryTypes.HandSynergyCondition.SAME_TYPE
	syn_crossbows.granted_skill = twin_bolts
	list.append(syn_crossbows)
	
	# 8. TODO (GDD): Черновая синергия Пращи (SLING) со свободной рукой или легким щитом
	var sling_blinding: SkillData = _make_ranged_skill(
		"synergy_sling_blinding_barrage",
		"Ослепляющий пращный залп",
		"Черновая синергия пращи: 2 быстрых броска с высоким шансом Ослепления.",
		18,
		10,
		1.0
	)
	sling_blinding.hit_count = 2
	sling_blinding.applies_status = true
	sling_blinding.status_to_apply = BattleTypes.StatusType.BLIND
	sling_blinding.status_duration_turns = 2
	sling_blinding.status_apply_chance = 0.75
	
	var syn_sling_empty: WeaponSynergyData = WeaponSynergyData.new()
	syn_sling_empty.synergy_id = "syn_sling_empty_hand"
	syn_sling_empty.display_name = "Пращный залп (свободная рука)"
	syn_sling_empty.description = "Праща + Свободная рука: открывает «Ослепляющий пращный залп»."
	syn_sling_empty.primary_weapon_type = InventoryTypes.WeaponType.SLING
	syn_sling_empty.condition = InventoryTypes.HandSynergyCondition.EMPTY_HAND
	syn_sling_empty.granted_skill = sling_blinding
	list.append(syn_sling_empty)
	
	var syn_sling_lshield: WeaponSynergyData = WeaponSynergyData.new()
	syn_sling_lshield.synergy_id = "syn_sling_light_shield"
	syn_sling_lshield.display_name = "Пращный залп (с лёгким щитом)"
	syn_sling_lshield.description = "Праща + Лёгкий щит: открывает «Ослепляющий пращный залп»."
	syn_sling_lshield.primary_weapon_type = InventoryTypes.WeaponType.SLING
	syn_sling_lshield.condition = InventoryTypes.HandSynergyCondition.LIGHT_SHIELD_ONLY
	syn_sling_lshield.granted_skill = sling_blinding
	list.append(syn_sling_lshield)
	
	# 9. Песенная таблица + Свободная рука -> Гимн оберега (SHIELD_BARRIER всему отряду)
	var ward_hymn: SkillData = SkillData.new()
	ward_hymn.skill_id = "synergy_tablet_ward_hymn"
	ward_hymn.skill_name = "Гимн оберега"
	ward_hymn.description = "Синергия (Песенная таблица + Свободная рука): укрывает весь отряд рунным барьером (+28)."
	ward_hymn.action_category = BattleTypes.ActionType.SKILL
	ward_hymn.target_side = BattleTypes.TargetSide.ALL_ALLIES
	ward_hymn.resource_type = BattleTypes.ResourceType.MANA
	ward_hymn.resource_cost = 24
	ward_hymn.shield_barrier_amount = 28
	ward_hymn.status_duration_turns = 2
	
	var syn_tablet_empty: WeaponSynergyData = WeaponSynergyData.new()
	syn_tablet_empty.synergy_id = "syn_song_tablet_empty"
	syn_tablet_empty.display_name = "Гимн оберега"
	syn_tablet_empty.description = "Песенная таблица + Свободная рука: открывает барьер отряда «Гимн оберега»."
	syn_tablet_empty.primary_weapon_type = InventoryTypes.WeaponType.SONG_TABLET
	syn_tablet_empty.condition = InventoryTypes.HandSynergyCondition.EMPTY_HAND
	syn_tablet_empty.granted_skill = ward_hymn
	list.append(syn_tablet_empty)
	
	# 10. Костяной оберег + Свободная рука -> Покров жизни
	var charm_ward: SkillData = SkillData.new()
	charm_ward.skill_id = "synergy_charm_life_ward"
	charm_ward.skill_name = "Покров жизни"
	charm_ward.description = "Синергия (Оберег + Свободная рука): исцеляет весь отряд (+20 HP) и даёт барьер (+15)."
	charm_ward.action_category = BattleTypes.ActionType.SKILL
	charm_ward.target_side = BattleTypes.TargetSide.ALL_ALLIES
	charm_ward.resource_type = BattleTypes.ResourceType.MANA
	charm_ward.resource_cost = 25
	charm_ward.base_heal_amount = 20
	charm_ward.shield_barrier_amount = 15
	charm_ward.status_duration_turns = 2
	
	var syn_charm_empty: WeaponSynergyData = WeaponSynergyData.new()
	syn_charm_empty.synergy_id = "syn_charm_empty"
	syn_charm_empty.display_name = "Покров жизни"
	syn_charm_empty.description = "Костяной оберег + Свободная рука: открывает групповое лечение «Покров жизни»."
	syn_charm_empty.primary_weapon_type = InventoryTypes.WeaponType.CHARM_AMULET
	syn_charm_empty.condition = InventoryTypes.HandSynergyCondition.EMPTY_HAND
	syn_charm_empty.granted_skill = charm_ward
	list.append(syn_charm_empty)
	
	return list

# =========================================================================
# Вспомогательные конструкторы навыков и QTE
# =========================================================================

static func _make_precision_qte(dur: float, spd: float, succ: float, perf: float) -> QTEConfigData:
	var qte: QTEConfigData = QTEConfigData.new()
	qte.qte_type = BattleTypes.QTEType.PRECISION_BAR
	qte.duration_seconds = dur
	qte.cursor_speed = spd
	qte.success_zone_width = succ
	qte.perfect_zone_width = perf
	return qte

static func _make_melee_skill(
	p_id: String,
	p_name: String,
	p_desc: String,
	p_cost: int,
	p_base: int,
	p_mult: float,
	p_with_qte: bool
) -> SkillData:
	var sk: SkillData = SkillData.new()
	sk.skill_id = p_id
	sk.skill_name = p_name
	sk.description = p_desc
	sk.action_category = BattleTypes.ActionType.SKILL
	sk.target_side = BattleTypes.TargetSide.ENEMY
	sk.resource_type = BattleTypes.ResourceType.ENERGY
	sk.resource_cost = p_cost
	sk.damage_type = BattleTypes.DamageType.PHYSICAL
	sk.base_power = p_base
	sk.power_multiplier = p_mult
	sk.blockability = BattleTypes.Blockability.HIGH_80
	var tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.MELEE]
	sk.tags = tags
	if p_with_qte:
		sk.requires_qte = true
		sk.qte_config = _make_precision_qte(2.5, 1.38, 0.23, 0.08)
	return sk

static func _make_ranged_skill(
	p_id: String,
	p_name: String,
	p_desc: String,
	p_cost: int,
	p_base: int,
	p_mult: float
) -> SkillData:
	var sk: SkillData = SkillData.new()
	sk.skill_id = p_id
	sk.skill_name = p_name
	sk.description = p_desc
	sk.action_category = BattleTypes.ActionType.SKILL
	sk.target_side = BattleTypes.TargetSide.ENEMY
	sk.resource_type = BattleTypes.ResourceType.HAMINGJA
	sk.resource_cost = p_cost
	sk.damage_type = BattleTypes.DamageType.PHYSICAL
	sk.base_power = p_base
	sk.power_multiplier = p_mult
	sk.blockability = BattleTypes.Blockability.MEDIUM_60
	var tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.RANGED_ATTACK]
	sk.tags = tags
	sk.requires_qte = true
	sk.qte_config = _make_precision_qte(2.4, 1.45, 0.22, 0.08)
	return sk
