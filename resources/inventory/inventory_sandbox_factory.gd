# res://resources/inventory/inventory_sandbox_factory.gd
class_name InventorySandboxFactory
extends RefCounted

## Программная фабрика стартовых расходников, экипировки и оружейных синергий (без ручных .tres)

# -------------------------------------------------------------------------
# Расходники
# -------------------------------------------------------------------------

static func create_healing_brew() -> ConsumableItemData:
	var item: ConsumableItemData = ConsumableItemData.new()
	item.item_id = "healing_brew"
	item.display_name = "Лечебный отвар"
	item.description = "Травяной настой, быстро затягивающий раны. Восстанавливает +45 HP."
	item.heal_hp = 45
	item.restore_resource_amount = 0
	item.usable_in_battle = true
	item.usable_in_overworld = true
	return item

static func create_rune_elixir() -> ConsumableItemData:
	var item: ConsumableItemData = ConsumableItemData.new()
	item.item_id = "rune_elixir"
	item.display_name = "Эликсир рун"
	item.description = "Светящийся фиал с жидкой маной. Восстанавливает +30 Маны."
	item.heal_hp = 0
	item.restore_resource_type = BattleTypes.ResourceType.MANA
	item.restore_resource_amount = 30
	item.usable_in_battle = true
	item.usable_in_overworld = true
	return item

static func create_clarity_herb() -> ConsumableItemData:
	var item: ConsumableItemData = ConsumableItemData.new()
	item.item_id = "clarity_herb"
	item.display_name = "Трава ясности"
	item.description = "Горький лист, проясняющий разум в бою. Снимает Сон и Гипноз."
	item.heal_hp = 0
	item.restore_resource_amount = 0
	var cured: Array[BattleTypes.StatusType] = [
		BattleTypes.StatusType.SLEEP,
		BattleTypes.StatusType.HYPNOSIS
	]
	item.cure_statuses = cured
	item.usable_in_battle = true
	item.usable_in_overworld = false
	return item

# -------------------------------------------------------------------------
# Оружие, щит, броня и уникальные аксессуары
# -------------------------------------------------------------------------

static func create_raider_axe() -> EquipmentItemData:
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "raider_axe"
	eq.display_name = "Топор налётчика"
	eq.description = "Лёгкий одноручный топор. Два топора в обеих руках открывают синергию «Прыжок берсерка»."
	eq.slot_type = InventoryTypes.EquipmentSlotType.ONE_HAND
	eq.weapon_archetype = InventoryTypes.WeaponArchetype.AXE
	eq.is_unique = false
	eq.bonus_attack = 6
	eq.bonus_speed = 1
	return eq

static func create_ash_spear() -> EquipmentItemData:
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "ash_spear"
	eq.display_name = "Ясеневое копьё"
	eq.description = "Сбалансированное одноручное копьё. В паре со щитом открывает синергию «Стена щитов»."
	eq.slot_type = InventoryTypes.EquipmentSlotType.ONE_HAND
	eq.weapon_archetype = InventoryTypes.WeaponArchetype.SPEAR
	eq.is_unique = false
	eq.bonus_attack = 5
	eq.bonus_speed = 2
	eq.bonus_crit_chance = 0.05
	return eq

static func create_oak_shield() -> EquipmentItemData:
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "oak_shield"
	eq.display_name = "Дубовый щит"
	eq.description = "Окованный железом щит. В паре с копьём открывает синергию «Стена щитов»."
	eq.slot_type = InventoryTypes.EquipmentSlotType.SHIELD
	eq.weapon_archetype = InventoryTypes.WeaponArchetype.SHIELD
	eq.is_unique = false
	eq.bonus_defense = 6
	eq.bonus_max_hp = 15
	return eq

static func create_dragonblood_greatsword() -> EquipmentItemData:
	var cleave_qte: QTEConfigData = QTEConfigData.new()
	cleave_qte.qte_type = BattleTypes.QTEType.PRECISION_BAR
	cleave_qte.duration_seconds = 2.6
	cleave_qte.cursor_speed = 1.45
	cleave_qte.success_zone_width = 0.22
	cleave_qte.perfect_zone_width = 0.08
	
	var cleave_skill: SkillData = SkillData.new()
	cleave_skill.skill_id = "dragonblood_cleave"
	cleave_skill.skill_name = "Кровавый рассек"
	cleave_skill.description = "Тяжёлый двуручный удар с Undertale-QTE и пробитием блока."
	cleave_skill.action_category = BattleTypes.ActionType.SKILL
	cleave_skill.target_side = BattleTypes.TargetSide.ENEMY
	cleave_skill.resource_type = BattleTypes.ResourceType.ENERGY
	cleave_skill.resource_cost = 25
	cleave_skill.damage_type = BattleTypes.DamageType.PHYSICAL
	cleave_skill.base_power = 24
	cleave_skill.power_multiplier = 1.30
	cleave_skill.blockability = BattleTypes.Blockability.HIGH_80
	var cleave_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.GUARD_BREAK]
	cleave_skill.tags = cleave_tags
	cleave_skill.guard_break_ignore_ratio = 1.0
	cleave_skill.guard_break_bonus_multiplier = 1.35
	cleave_skill.requires_qte = true
	cleave_skill.qte_config = cleave_qte
	
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "dragonblood_greatsword"
	eq.display_name = "Меч из крови дракона"
	eq.description = "Двуручный клинок. Пробивает блок; промах QTE < 50%, идеальный удар ≥ 90% гарантирует крит."
	eq.slot_type = InventoryTypes.EquipmentSlotType.TWO_HAND
	eq.weapon_archetype = InventoryTypes.WeaponArchetype.SWORD
	eq.is_unique = true
	eq.bonus_attack = 14
	eq.bonus_speed = -2
	eq.bonus_crit_multiplier = 0.25
	var skills_arr: Array[SkillData] = [cleave_skill]
	eq.granted_skills = skills_arr
	var tags_arr: Array[StringName] = [&"GUARD_BREAK"]
	eq.passive_tags = tags_arr
	eq.override_qte_thresholds = true
	eq.qte_miss_threshold = 0.50
	eq.qte_weak_threshold = 0.70
	eq.qte_perfect_threshold = 0.90
	eq.qte_guaranteed_crit_on_perfect = true
	return eq

static func create_seafarer_mail() -> EquipmentItemData:
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "seafarer_mail"
	eq.display_name = "Кольчуга морехода"
	eq.description = "Лёгкая клёпаная кольчуга, защищающая корпус без потери подвижности."
	eq.slot_type = InventoryTypes.EquipmentSlotType.BODY
	eq.weapon_archetype = InventoryTypes.WeaponArchetype.NONE
	eq.is_unique = false
	eq.bonus_defense = 7
	eq.bonus_max_hp = 25
	return eq

static func create_storm_charm() -> EquipmentItemData:
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "storm_charm"
	eq.display_name = "Оберег шторма"
	eq.description = "Уникальный амулет ветра. Повышает скорость и атаку."
	eq.slot_type = InventoryTypes.EquipmentSlotType.ACCESSORY
	eq.weapon_archetype = InventoryTypes.WeaponArchetype.NONE
	eq.is_unique = true
	eq.bonus_speed = 4
	eq.bonus_attack = 4
	var tags_arr: Array[StringName] = [&"EXTRA_DODGE"]
	eq.passive_tags = tags_arr
	return eq

static func create_precision_ring() -> EquipmentItemData:
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "precision_ring"
	eq.display_name = "Кольцо точности"
	eq.description = "Уникальное кольцо мастера клинка. Снижает порог идеального QTE на 10% и повышает крит."
	eq.slot_type = InventoryTypes.EquipmentSlotType.ACCESSORY
	eq.weapon_archetype = InventoryTypes.WeaponArchetype.NONE
	eq.is_unique = true
	eq.bonus_crit_chance = 0.05
	eq.qte_perfect_threshold_delta = -0.10
	return eq

# -------------------------------------------------------------------------
# Каталог оружейных синергий
# -------------------------------------------------------------------------

static func create_synergy_catalog() -> Array[WeaponSynergyData]:
	var list: Array[WeaponSynergyData] = []
	
	# 1. Топор + Топор -> Прыжок берсерка (двойной удар за Энергию)
	var berserker_skill: SkillData = SkillData.new()
	berserker_skill.skill_id = "synergy_berserker_leap"
	berserker_skill.skill_name = "Прыжок берсерка"
	berserker_skill.description = "Синергия (Топор + Топор): сокрушительный двойной удар двумя топорами за Энергию."
	berserker_skill.action_category = BattleTypes.ActionType.SKILL
	berserker_skill.target_side = BattleTypes.TargetSide.ENEMY
	berserker_skill.resource_type = BattleTypes.ResourceType.ENERGY
	berserker_skill.resource_cost = 20
	berserker_skill.damage_type = BattleTypes.DamageType.PHYSICAL
	berserker_skill.base_power = 11
	berserker_skill.power_multiplier = 0.95
	berserker_skill.hit_count = 2
	berserker_skill.blockability = BattleTypes.Blockability.HIGH_80
	var b_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.NO_GUARD]
	berserker_skill.tags = b_tags
	berserker_skill.no_guard_incoming_multiplier = 1.40
	
	var berserker_syn: WeaponSynergyData = WeaponSynergyData.new()
	berserker_syn.synergy_id = "syn_axe_axe"
	berserker_syn.display_name = "Прыжок берсерка"
	berserker_syn.description = "Топор + Топор: открывает двойной удар «Прыжок берсерка»."
	berserker_syn.archetype_a = InventoryTypes.WeaponArchetype.AXE
	berserker_syn.archetype_b = InventoryTypes.WeaponArchetype.AXE
	berserker_syn.granted_skill = berserker_skill
	list.append(berserker_syn)
	
	# 2. Копьё + Щит -> Стена щитов (защитная стойка + TAUNT)
	var shield_wall_skill: SkillData = SkillData.new()
	shield_wall_skill.skill_id = "synergy_shield_wall"
	shield_wall_skill.skill_name = "Стена щитов"
	shield_wall_skill.description = "Синергия (Копьё + Щит): встает в усиленный блок (+15 Энергии) и провоцирует врагов на 2 хода."
	shield_wall_skill.action_category = BattleTypes.ActionType.SKILL
	shield_wall_skill.target_side = BattleTypes.TargetSide.SELF
	shield_wall_skill.resource_type = BattleTypes.ResourceType.ENERGY
	shield_wall_skill.resource_cost = 15
	shield_wall_skill.grants_block_stance = true
	shield_wall_skill.applies_status = true
	shield_wall_skill.status_to_apply = BattleTypes.StatusType.TAUNT
	shield_wall_skill.status_duration_turns = 2
	var s_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.TAUNT]
	shield_wall_skill.tags = s_tags
	
	var shield_wall_syn: WeaponSynergyData = WeaponSynergyData.new()
	shield_wall_syn.synergy_id = "syn_spear_shield"
	shield_wall_syn.display_name = "Стена щитов"
	shield_wall_syn.description = "Копьё + Щит: открывает защитную стойку с провокацией «Стена щитов»."
	shield_wall_syn.archetype_a = InventoryTypes.WeaponArchetype.SPEAR
	shield_wall_syn.archetype_b = InventoryTypes.WeaponArchetype.SHIELD
	shield_wall_syn.granted_skill = shield_wall_skill
	list.append(shield_wall_syn)
	
	return list

# -------------------------------------------------------------------------
# Стартовая комплектация ГГ и инвентаря
# -------------------------------------------------------------------------

## Возвращает стартовый набор экипировки ГГ (Копьё + Щит + Кольчуга морехода)
static func create_default_hero_loadout() -> EquipmentLoadout:
	var loadout: EquipmentLoadout = EquipmentLoadout.new()
	loadout.available_hands = 2
	loadout.equip_into_slot(InventoryTypes.SLOT_LEFT_HAND, create_ash_spear())
	loadout.equip_into_slot(InventoryTypes.SLOT_RIGHT_HAND, create_oak_shield())
	loadout.equip_into_slot(InventoryTypes.SLOT_BODY, create_seafarer_mail())
	return loadout

## Возвращает стартовый инвентарь со всеми тестовыми расходниками, оружием и аксессуарами
static func create_starter_inventory() -> InventoryState:
	var inv: InventoryState = InventoryState.new()
	inv.add_item(create_healing_brew(), 3)
	inv.add_item(create_rune_elixir(), 2)
	inv.add_item(create_clarity_herb(), 2)
	
	inv.add_item(create_raider_axe(), 2)
	inv.add_item(create_dragonblood_greatsword(), 1)
	inv.add_item(create_storm_charm(), 1)
	inv.add_item(create_precision_ring(), 1)
	return inv
