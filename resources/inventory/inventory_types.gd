# res://resources/inventory/inventory_types.gd
class_name InventoryTypes
extends RefCounted

## Категории предметов инвентаря
enum ItemCategory {
	CONSUMABLE,
	EQUIPMENT
}

## Типы слотов экипировки (включая легкие и тяжелые щиты; броня — один слот BODY)
enum EquipmentSlotType {
	ONE_HAND,
	TWO_HAND,
	SHIELD,
	SHIELD_LIGHT,
	SHIELD_HEAVY,
	BODY,
	ACCESSORY
}

## 7 категорий оружия для рекрутов + фирменное сюжетное оружие ГГ
enum WeaponCategory {
	NONE,
	POLEARM,
	LONG_BLADES,
	SHORT_BLADES,
	RANGED,
	BLUNT,
	CRUSHING,
	RELICS,
	HERO_SIGNATURE
}

## Все 35 типов оружия (по 5 типов в каждой из 7 категорий)
enum WeaponType {
	NONE,
	# 1. Древковое (POLEARM)
	SPEAR,
	ATGEIR,
	BOAR_SPEAR,
	GAFF_HOOK,
	HARPOON,
	# 2. Длинные клинки (LONG_BLADES)
	SWORD,
	LANGSAX,
	HOLMSVERD,
	BROAD_BLADE,
	CURVED_BLADE,
	# 3. Короткие клинки (SHORT_BLADES)
	SEAX,
	THROWING_KNIFE,
	DAGGER,
	SICKLE,
	WIDE_KNIFE,
	# 4. Стрелковое (RANGED)
	BOW,
	LONG_BOW,
	SHORT_BOW,
	CROSSBOW,
	SLING,
	# 5. Дробящее (BLUNT)
	CLUB,
	MORNINGSTAR,
	FLAIL,
	BEARDED_AXE,
	ONE_HAND_HAMMER,
	# 6. Сокрушающее (CRUSHING)
	DANE_AXE,
	WARHAMMER,
	GREATSWORD,
	TWO_HAND_CLUB,
	WAR_FLAIL,
	# 7. Реликвии (RELICS)
	SONG_TABLET,
	VOLVA_STAFF,
	RUNE_BONES,
	CHARM_AMULET,
	TOTEM_TALISMAN
}

## 5 Даров для экипировки соответствующих типов Реликвий
enum RelicGift {
	NONE,
	VOICE,
	SEIDR,
	LOT,
	CHARM,
	BEAST
}

## Условия срабатывания синергии второй руки для одноручного оружия
enum HandSynergyCondition {
	NONE,
	SAME_TYPE,
	ANY_SHIELD,
	LIGHT_SHIELD_ONLY,
	EMPTY_HAND,
	LEGACY_ARCHETYPE_PAIR
}

## Legacy-архетипы (сохранены для обратной совместимости)
enum WeaponArchetype {
	NONE,
	AXE,
	SPEAR,
	SWORD,
	BOW,
	SHIELD
}

const SLOT_LEFT_HAND: StringName = &"left_hand"
const SLOT_RIGHT_HAND: StringName = &"right_hand"
const SLOT_BODY: StringName = &"body"
const SLOT_ACCESSORY_1: StringName = &"accessory_1"
const SLOT_ACCESSORY_2: StringName = &"accessory_2"

## Возвращает упорядоченный список всех 5 идентификаторов слотов экипировки
static func get_all_slot_ids() -> Array[StringName]:
	return [
		SLOT_LEFT_HAND,
		SLOT_RIGHT_HAND,
		SLOT_BODY,
		SLOT_ACCESSORY_1,
		SLOT_ACCESSORY_2
	]

## Проверяет, относится ли слот к слотам рук
static func is_hand_slot(slot_id: StringName) -> bool:
	return slot_id == SLOT_LEFT_HAND or slot_id == SLOT_RIGHT_HAND

## Проверяет, является ли тип предмета щитом (легким, тяжелым или общим)
static func is_shield_slot_type(slot_type: EquipmentSlotType) -> bool:
	return (
		slot_type == EquipmentSlotType.SHIELD
		or slot_type == EquipmentSlotType.SHIELD_LIGHT
		or slot_type == EquipmentSlotType.SHIELD_HEAVY
	)

## Проверяет, является ли тип предмета легким щитом
static func is_light_shield_slot_type(slot_type: EquipmentSlotType) -> bool:
	return slot_type == EquipmentSlotType.SHIELD_LIGHT or slot_type == EquipmentSlotType.SHIELD

## Определяет родную категорию оружия для любого из 35 типов WeaponType
static func get_category_for_weapon_type(w_type: WeaponType) -> WeaponCategory:
	match w_type:
		WeaponType.SPEAR, WeaponType.ATGEIR, WeaponType.BOAR_SPEAR, WeaponType.GAFF_HOOK, WeaponType.HARPOON:
			return WeaponCategory.POLEARM
		WeaponType.SWORD, WeaponType.LANGSAX, WeaponType.HOLMSVERD, WeaponType.BROAD_BLADE, WeaponType.CURVED_BLADE:
			return WeaponCategory.LONG_BLADES
		WeaponType.SEAX, WeaponType.THROWING_KNIFE, WeaponType.DAGGER, WeaponType.SICKLE, WeaponType.WIDE_KNIFE:
			return WeaponCategory.SHORT_BLADES
		WeaponType.BOW, WeaponType.LONG_BOW, WeaponType.SHORT_BOW, WeaponType.CROSSBOW, WeaponType.SLING:
			return WeaponCategory.RANGED
		WeaponType.CLUB, WeaponType.MORNINGSTAR, WeaponType.FLAIL, WeaponType.BEARDED_AXE, WeaponType.ONE_HAND_HAMMER:
			return WeaponCategory.BLUNT
		WeaponType.DANE_AXE, WeaponType.WARHAMMER, WeaponType.GREATSWORD, WeaponType.TWO_HAND_CLUB, WeaponType.WAR_FLAIL:
			return WeaponCategory.CRUSHING
		WeaponType.SONG_TABLET, WeaponType.VOLVA_STAFF, WeaponType.RUNE_BONES, WeaponType.CHARM_AMULET, WeaponType.TOTEM_TALISMAN:
			return WeaponCategory.RELICS
	return WeaponCategory.NONE

## Возвращает требуемый Дар для типа Реликвии (либо NONE для обычного оружия)
static func get_required_gift_for_weapon_type(w_type: WeaponType) -> RelicGift:
	match w_type:
		WeaponType.SONG_TABLET:
			return RelicGift.VOICE
		WeaponType.VOLVA_STAFF:
			return RelicGift.SEIDR
		WeaponType.RUNE_BONES:
			return RelicGift.LOT
		WeaponType.CHARM_AMULET:
			return RelicGift.CHARM
		WeaponType.TOTEM_TALISMAN:
			return RelicGift.BEAST
	return RelicGift.NONE

## Возвращает значение по умолчанию для ношения «Тяжелого» снаряжения по категории оружия рекрута
static func can_category_wear_heavy_by_default(category: WeaponCategory) -> bool:
	return (
		category != WeaponCategory.SHORT_BLADES
		and category != WeaponCategory.RANGED
		and category != WeaponCategory.RELICS
	)

## Возвращает локализованное название слота экипировки
static func get_slot_display_name(slot_id: StringName) -> String:
	match slot_id:
		SLOT_LEFT_HAND:
			return "Левая рука"
		SLOT_RIGHT_HAND:
			return "Правая рука"
		SLOT_BODY:
			return "Тело"
		SLOT_ACCESSORY_1:
			return "Аксессуар 1"
		SLOT_ACCESSORY_2:
			return "Аксессуар 2"
	return "Слот"

## Возвращает локализованное название типа слота предмета
static func get_slot_type_display_name(slot_type: EquipmentSlotType) -> String:
	match slot_type:
		EquipmentSlotType.ONE_HAND:
			return "Одноручное"
		EquipmentSlotType.TWO_HAND:
			return "Двуручное"
		EquipmentSlotType.SHIELD:
			return "Щит"
		EquipmentSlotType.SHIELD_LIGHT:
			return "Лёгкий щит"
		EquipmentSlotType.SHIELD_HEAVY:
			return "Тяжёлый щит"
		EquipmentSlotType.BODY:
			return "Броня"
		EquipmentSlotType.ACCESSORY:
			return "Аксессуар"
	return "Снаряжение"

## Возвращает локализованное название категории оружия
static func get_weapon_category_display_name(category: WeaponCategory) -> String:
	match category:
		WeaponCategory.POLEARM:
			return "Древковое"
		WeaponCategory.LONG_BLADES:
			return "Длинные клинки"
		WeaponCategory.SHORT_BLADES:
			return "Короткие клинки"
		WeaponCategory.RANGED:
			return "Стрелковое"
		WeaponCategory.BLUNT:
			return "Дробящее"
		WeaponCategory.CRUSHING:
			return "Сокрушающее"
		WeaponCategory.RELICS:
			return "Реликвии"
		WeaponCategory.HERO_SIGNATURE:
			return "Фирменное (ГГ)"
	return "Общее"

## Возвращает локализованное название каждого из 35 типов оружия
static func get_weapon_type_display_name(w_type: WeaponType) -> String:
	match w_type:
		WeaponType.SPEAR: return "Копьё"
		WeaponType.ATGEIR: return "Атгейр"
		WeaponType.BOAR_SPEAR: return "Рогатина"
		WeaponType.GAFF_HOOK: return "Багор"
		WeaponType.HARPOON: return "Гарпун"
		WeaponType.SWORD: return "Меч"
		WeaponType.LANGSAX: return "Лангсакс"
		WeaponType.HOLMSVERD: return "Хольмсверд"
		WeaponType.BROAD_BLADE: return "Широкий клинок"
		WeaponType.CURVED_BLADE: return "Изогнутый клинок"
		WeaponType.SEAX: return "Сакс"
		WeaponType.THROWING_KNIFE: return "Метательный нож"
		WeaponType.DAGGER: return "Кинжал"
		WeaponType.SICKLE: return "Серп"
		WeaponType.WIDE_KNIFE: return "Широкий нож"
		WeaponType.BOW: return "Лук"
		WeaponType.LONG_BOW: return "Длинный лук"
		WeaponType.SHORT_BOW: return "Короткий лук"
		WeaponType.CROSSBOW: return "Самострел"
		WeaponType.SLING: return "Праща"
		WeaponType.CLUB: return "Палица"
		WeaponType.MORNINGSTAR: return "Моргенштерн"
		WeaponType.FLAIL: return "Кистень"
		WeaponType.BEARDED_AXE: return "Бородатый топор"
		WeaponType.ONE_HAND_HAMMER: return "Одноручный молот"
		WeaponType.DANE_AXE: return "Датский топор"
		WeaponType.WARHAMMER: return "Боевой молот"
		WeaponType.GREATSWORD: return "Двуручный меч"
		WeaponType.TWO_HAND_CLUB: return "Двуручная дубина"
		WeaponType.WAR_FLAIL: return "Боевой цеп"
		WeaponType.SONG_TABLET: return "Песенная таблица"
		WeaponType.VOLVA_STAFF: return "Посох вёльвы"
		WeaponType.RUNE_BONES: return "Рунные кости"
		WeaponType.CHARM_AMULET: return "Оберег"
		WeaponType.TOTEM_TALISMAN: return "Талисман"
	return "Нет"

## Возвращает локализованное название Дара Реликвии
static func get_relic_gift_display_name(gift: RelicGift) -> String:
	match gift:
		RelicGift.VOICE:
			return "Голос"
		RelicGift.SEIDR:
			return "Сейд"
		RelicGift.LOT:
			return "Жребий"
		RelicGift.CHARM:
			return "Заговор"
		RelicGift.BEAST:
			return "Зверь"
	return "Нет"

## Возвращает локализованное название условия синергии второй руки
static func get_synergy_condition_display_name(cond: HandSynergyCondition) -> String:
	match cond:
		HandSynergyCondition.SAME_TYPE:
			return "Парное (тот же тип)"
		HandSynergyCondition.ANY_SHIELD:
			return "Со щитом"
		HandSynergyCondition.LIGHT_SHIELD_ONLY:
			return "С лёгким щитом"
		HandSynergyCondition.EMPTY_HAND:
			return "Свободная рука"
		HandSynergyCondition.LEGACY_ARCHETYPE_PAIR:
			return "Парная связка"
	return ""

## Legacy-метод названия архетипа
static func get_archetype_display_name(archetype: WeaponArchetype) -> String:
	match archetype:
		WeaponArchetype.AXE: return "Топор"
		WeaponArchetype.SPEAR: return "Копьё"
		WeaponArchetype.SWORD: return "Меч"
		WeaponArchetype.BOW: return "Лук"
		WeaponArchetype.SHIELD: return "Щит"
	return "Нет"
