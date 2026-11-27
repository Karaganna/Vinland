# res://resources/inventory/inventory_sandbox_factory.gd
class_name InventorySandboxFactory
extends RefCounted

## Программная фабрика стартовых расходников, каталога синергий и арсенала песочницы (без ручных .tres)

const RITUAL_ASH_ITEM_ID: String = "ritual_ash"

# -------------------------------------------------------------------------
# Расходники
# -------------------------------------------------------------------------

static func create_healing_brew() -> ConsumableItemData:
	var item: ConsumableItemData = ConsumableItemData.new()
	item.item_id = "healing_brew"
	item.display_name = "Лечебный отвар"
	item.description = "Травяной настой, быстро затягивающий раны. Восстанавливает +45 HP (снижает Ярость при внешнем лечении)."
	item.heal_hp = 45
	item.restore_resource_amount = 0
	item.usable_in_battle = true
	item.usable_in_overworld = true
	return item

static func create_rune_elixir() -> ConsumableItemData:
	var item: ConsumableItemData = ConsumableItemData.new()
	item.item_id = "rune_elixir"
	item.display_name = "Эликсир рун"
	item.description = "Светящийся фиал с жидкой маной. Восстанавливает +30 Маны (для носителей бака Маны)."
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
	item.description = "Горький лист, проясняющий разум и согревающий кровь. Снимает Сон, Гипноз, Заморозку и Ослепление."
	item.heal_hp = 0
	item.restore_resource_amount = 0
	var cured: Array[BattleTypes.StatusType] = [
		BattleTypes.StatusType.SLEEP,
		BattleTypes.StatusType.HYPNOSIS,
		BattleTypes.StatusType.FREEZE,
		BattleTypes.StatusType.BLIND
	]
	item.cure_statuses = cured
	item.usable_in_battle = true
	item.usable_in_overworld = false
	return item

static func create_ritual_ash() -> ConsumableItemData:
	var item: ConsumableItemData = ConsumableItemData.new()
	item.item_id = RITUAL_ASH_ITEM_ID
	item.display_name = "Зола обряда"
	item.description = "Дешёвая жертвенная зола с кострища. Полностью очищает ветки Старшего футарка и возвращает все вложенные Знаки."
	item.is_rune_reset_item = true
	item.usable_in_battle = false
	item.usable_in_overworld = true
	return item

# -------------------------------------------------------------------------
# Алиасы совместимости на WeaponCatalogFactory и аксессуары
# -------------------------------------------------------------------------

static func create_raider_axe() -> EquipmentItemData:
	return WeaponCatalogFactory.create_bearded_axe()

static func create_ash_spear() -> EquipmentItemData:
	return WeaponCatalogFactory.create_fathers_spear()

static func create_oak_shield() -> EquipmentItemData:
	return WeaponCatalogFactory.create_fathers_round_shield()

static func create_dragonblood_greatsword() -> EquipmentItemData:
	return WeaponCatalogFactory.create_dragonblood_greatsword()

static func create_seafarer_mail() -> EquipmentItemData:
	return WeaponCatalogFactory.create_seafarer_mail()

static func create_storm_charm() -> EquipmentItemData:
	var eq: EquipmentItemData = EquipmentItemData.new()
	eq.item_id = "storm_charm"
	eq.display_name = "Оберег шторма"
	eq.description = "Уникальный амулет ветра. Повышает скорость и атаку."
	eq.slot_type = InventoryTypes.EquipmentSlotType.ACCESSORY
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
	eq.is_unique = true
	eq.bonus_crit_chance = 0.05
	eq.qte_perfect_threshold_delta = -0.10
	return eq

static func create_synergy_catalog() -> Array[WeaponSynergyData]:
	return WeaponCatalogFactory.create_synergy_catalog()

## Возвращает стартовый набор экипировки ГГ (Отцовское копьё + Круглый щит + Кольчуга морехода)
static func create_default_hero_loadout() -> EquipmentLoadout:
	var loadout: EquipmentLoadout = EquipmentLoadout.new()
	loadout.available_hands = 2
	loadout.equip_into_slot(InventoryTypes.SLOT_LEFT_HAND, WeaponCatalogFactory.create_fathers_spear())
	loadout.equip_into_slot(InventoryTypes.SLOT_RIGHT_HAND, WeaponCatalogFactory.create_fathers_round_shield())
	loadout.equip_into_slot(InventoryTypes.SLOT_BODY, WeaponCatalogFactory.create_seafarer_mail())
	return loadout

## Возвращает стартовый инвентарь со всеми тестовыми предметами, «Золой обряда», оружием рекрутов и легендарками
static func create_starter_inventory() -> InventoryState:
	var inv: InventoryState = InventoryState.new()
	inv.add_item(create_healing_brew(), 4)
	inv.add_item(create_rune_elixir(), 3)
	inv.add_item(create_clarity_herb(), 2)
	inv.add_item(create_ritual_ash(), 3)
	
	# Фирменное второе оружие ГГ
	inv.add_item(WeaponCatalogFactory.create_dragonblood_greatsword(), 1)
	
	# Оружие мира, комплекты, праща, кистень, древковое 2H и легендарки для рекрутов
	inv.add_item(WeaponCatalogFactory.create_word_of_honor_holmsverd(), 1)
	inv.add_item(WeaponCatalogFactory.create_yew_widow_longbow(), 1)
	inv.add_item(WeaponCatalogFactory.create_sisters_twin_blades_set(), 1)
	inv.add_item(WeaponCatalogFactory.create_nordic_sword(), 1)
	inv.add_item(WeaponCatalogFactory.create_iron_langsax(), 1)
	inv.add_item(WeaponCatalogFactory.create_nordic_atgeir(), 1)
	inv.add_item(WeaponCatalogFactory.create_leather_sling(), 1)
	inv.add_item(WeaponCatalogFactory.create_hand_crossbow(), 2)
	inv.add_item(WeaponCatalogFactory.create_bearded_axe(), 2)
	inv.add_item(WeaponCatalogFactory.create_iron_flail(), 1)
	inv.add_item(WeaponCatalogFactory.create_dane_axe(), 1)
	inv.add_item(WeaponCatalogFactory.create_healer_charm(), 1)
	
	# Щиты, тяжелая броня и аксессуары
	inv.add_item(WeaponCatalogFactory.create_scout_light_shield(), 1)
	inv.add_item(WeaponCatalogFactory.create_hird_heavy_shield(), 1)
	inv.add_item(WeaponCatalogFactory.create_varangian_heavy_armor(), 1)
	inv.add_item(create_storm_charm(), 1)
	inv.add_item(create_precision_ring(), 1)
	return inv
