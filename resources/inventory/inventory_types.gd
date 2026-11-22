# res://resources/inventory/inventory_types.gd
class_name InventoryTypes
extends RefCounted

## Категории предметов инвентаря
enum ItemCategory {
	CONSUMABLE,
	EQUIPMENT
}

## Типы слотов экипировки
enum EquipmentSlotType {
	ONE_HAND,
	TWO_HAND,
	SHIELD,
	BODY,
	ACCESSORY
}

## Оружейные архетипы для проверки синергий и ограничений спутников
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
		EquipmentSlotType.BODY:
			return "Тело"
		EquipmentSlotType.ACCESSORY:
			return "Аксессуар"
	return "Снаряжение"

## Возвращает локализованное название архетипа оружия
static func get_archetype_display_name(archetype: WeaponArchetype) -> String:
	match archetype:
		WeaponArchetype.AXE:
			return "Топор"
		WeaponArchetype.SPEAR:
			return "Копьё"
		WeaponArchetype.SWORD:
			return "Меч"
		WeaponArchetype.BOW:
			return "Лук"
		WeaponArchetype.SHIELD:
			return "Щит"
	return "Нет"
