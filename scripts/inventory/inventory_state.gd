# res://scripts/inventory/inventory_state.gd
class_name InventoryState
extends RefCounted

## Сигнал об изменении содержимого инвентаря или экипировки
signal inventory_changed()

## Каталог определений расходников {item_id: ConsumableItemData}
var _consumable_defs: Dictionary = {}
## Количество расходников в стеках {item_id: int}
var _consumable_counts: Dictionary = {}
## Пул неэкипированной экипировки
var _unequipped_equipment: Array[EquipmentItemData] = []

## Добавляет предмет (расходник или экипировку) в инвентарь
func add_item(item: ItemData, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false
	var id_key: String = item.item_id.strip_edges()
	if id_key.is_empty():
		return false
	
	if item is ConsumableItemData:
		var cons: ConsumableItemData = item as ConsumableItemData
		_consumable_defs[id_key] = cons
		var current_cnt: int = int(_consumable_counts.get(id_key, 0))
		var max_limit: int = maxi(1, cons.max_stack) if cons.stackable else 1
		var next_cnt: int = clampi(current_cnt + amount, 0, max_limit)
		if next_cnt == current_cnt:
			return false
		_consumable_counts[id_key] = next_cnt
		inventory_changed.emit()
		return true
	
	if item is EquipmentItemData:
		var eq: EquipmentItemData = item as EquipmentItemData
		var added_any: bool = false
		for i: int in range(amount):
			if eq.is_unique and has_equipment(id_key):
				break
			var instance_eq: EquipmentItemData = eq if i == 0 else (eq.duplicate() as EquipmentItemData)
			_unequipped_equipment.append(instance_eq)
			added_any = true
		if added_any:
			inventory_changed.emit()
		return added_any
	
	return false

## Удаляет указанное количество предметов по item_id
func remove_item(item_id: String, amount: int = 1) -> bool:
	var id_key: String = item_id.strip_edges()
	if id_key.is_empty() or amount <= 0:
		return false
	
	if _consumable_counts.has(id_key):
		var current_cnt: int = int(_consumable_counts.get(id_key, 0))
		if current_cnt < amount:
			return false
		var next_cnt: int = current_cnt - amount
		if next_cnt <= 0:
			_consumable_counts.erase(id_key)
		else:
			_consumable_counts[id_key] = next_cnt
		inventory_changed.emit()
		return true
	
	var matches_found: int = 0
	for eq: EquipmentItemData in _unequipped_equipment:
		if eq != null and eq.item_id == id_key:
			matches_found += 1
	if matches_found < amount:
		return false
	
	var remaining_to_remove: int = amount
	for i: int in range(_unequipped_equipment.size() - 1, -1, -1):
		if remaining_to_remove <= 0:
			break
		var eq: EquipmentItemData = _unequipped_equipment[i]
		if eq != null and eq.item_id == id_key:
			_unequipped_equipment.remove_at(i)
			remaining_to_remove -= 1
	
	inventory_changed.emit()
	return true

## Возвращает количество предметов с указанным item_id в инвентаре
func get_item_count(item_id: String) -> int:
	var id_key: String = item_id.strip_edges()
	if id_key.is_empty():
		return 0
	if _consumable_counts.has(id_key):
		return int(_consumable_counts.get(id_key, 0))
	var cnt: int = 0
	for eq: EquipmentItemData in _unequipped_equipment:
		if eq != null and eq.item_id == id_key:
			cnt += 1
	return cnt

## Проверяет наличие экземпляра экипировки с указанным item_id в пуле инвентаря
func has_equipment(item_id: String) -> bool:
	return get_item_count(item_id) > 0

## Возвращает список доступных расходников: [{item: ConsumableItemData, count: int}]
func get_consumables(battle_only: bool = false, overworld_only: bool = false) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id_key_var: Variant in _consumable_counts.keys():
		var id_key: String = str(id_key_var)
		var cnt: int = int(_consumable_counts.get(id_key, 0))
		if cnt <= 0:
			continue
		var cons: ConsumableItemData = _consumable_defs.get(id_key, null) as ConsumableItemData
		if cons == null:
			continue
		if battle_only and not cons.usable_in_battle:
			continue
		if overworld_only and not cons.usable_in_overworld:
			continue
		result.append({
			"item": cons,
			"count": cnt
		})
	return result

## Возвращает копию массива всей неэкипированной экипировки
func get_all_equipment() -> Array[EquipmentItemData]:
	var list: Array[EquipmentItemData] = []
	for eq: EquipmentItemData in _unequipped_equipment:
		if eq != null:
			list.append(eq)
	return list

## Возвращает неэкипированные предметы, подходящие для указанного слота и количества рук бойца
func get_equipment_for_slot(slot_id: StringName, available_hands: int = 2) -> Array[EquipmentItemData]:
	var result: Array[EquipmentItemData] = []
	for eq: EquipmentItemData in _unequipped_equipment:
		if eq == null:
			continue
		if _does_item_fit_slot(eq, slot_id, available_hands):
			result.append(eq)
	return result

## Подбирает подходящий слот по умолчанию для быстрого надевания предмета
func get_default_slot_for_item(combatant_data: CombatantData, item: EquipmentItemData) -> StringName:
	if item == null:
		return &""
	var loadout: EquipmentLoadout = combatant_data.equipment_loadout if combatant_data != null else null
	var hands_count: int = loadout.available_hands if loadout != null else 2
	
	if item.occupies_both_hands():
		return InventoryTypes.SLOT_LEFT_HAND if hands_count >= 2 else &""
	if item.is_shield_item():
		if hands_count < 2:
			return InventoryTypes.SLOT_LEFT_HAND
		if loadout == null or loadout.is_two_handed_equipped():
			return InventoryTypes.SLOT_RIGHT_HAND
		if loadout.right_hand == null:
			return InventoryTypes.SLOT_RIGHT_HAND
		if loadout.left_hand == null:
			return InventoryTypes.SLOT_LEFT_HAND
		return InventoryTypes.SLOT_RIGHT_HAND
	
	match item.slot_type:
		InventoryTypes.EquipmentSlotType.ONE_HAND:
			if loadout == null or loadout.is_two_handed_equipped():
				return InventoryTypes.SLOT_LEFT_HAND
			if loadout.left_hand == null:
				return InventoryTypes.SLOT_LEFT_HAND
			if hands_count >= 2 and loadout.right_hand == null:
				return InventoryTypes.SLOT_RIGHT_HAND
			return InventoryTypes.SLOT_LEFT_HAND
		InventoryTypes.EquipmentSlotType.BODY:
			return InventoryTypes.SLOT_BODY
		InventoryTypes.EquipmentSlotType.ACCESSORY:
			if loadout == null:
				return InventoryTypes.SLOT_ACCESSORY_1
			if loadout.accessory_1 == null:
				return InventoryTypes.SLOT_ACCESSORY_1
			if loadout.accessory_2 == null:
				return InventoryTypes.SLOT_ACCESSORY_2
			return InventoryTypes.SLOT_ACCESSORY_1
	return &""

## Экипирует предмет из инвентаря в указанный слот бойца (с проверкой категории, Даров, Тяжелого и правил ГГ/рекрутов)
func equip_item(combatant_data: CombatantData, slot_name: StringName, item: EquipmentItemData) -> Dictionary:
	var empty_removed: Array[EquipmentItemData] = []
	if combatant_data == null or item == null:
		return {"ok": false, "reason": "Не указан боец или предмет.", "removed": empty_removed}
	
	if combatant_data.equipment_loadout == null:
		combatant_data.equipment_loadout = EquipmentLoadout.new()
	
	var pool_idx: int = _find_equipment_index(item)
	if pool_idx < 0:
		return {"ok": false, "reason": "Предмет отсутствует в инвентаре.", "removed": empty_removed}
	
	var equip_res: Dictionary = combatant_data.equipment_loadout.equip_into_slot_for_combatant(combatant_data, slot_name, item)
	if not bool(equip_res.get("ok", false)):
		return equip_res
	
	_unequipped_equipment.remove_at(pool_idx)
	
	var removed_variant: Variant = equip_res.get("removed", empty_removed)
	if removed_variant is Array:
		for old_item: Variant in removed_variant:
			if old_item is EquipmentItemData:
				_unequipped_equipment.append(old_item as EquipmentItemData)
	
	inventory_changed.emit()
	return equip_res

## Снимает предмет из указанного слота бойца и возвращает его в инвентарь
func unequip_slot(combatant_data: CombatantData, slot_name: StringName) -> Array[EquipmentItemData]:
	var empty_removed: Array[EquipmentItemData] = []
	if combatant_data == null or combatant_data.equipment_loadout == null:
		return empty_removed
	
	var removed: Array[EquipmentItemData] = combatant_data.equipment_loadout.unequip_from_slot(slot_name)
	if removed.is_empty():
		return removed
	
	for old_item: EquipmentItemData in removed:
		if old_item != null:
			_unequipped_equipment.append(old_item)
	
	inventory_changed.emit()
	return removed

func _find_equipment_index(item: EquipmentItemData) -> int:
	if item == null:
		return -1
	var exact_idx: int = _unequipped_equipment.find(item)
	if exact_idx >= 0:
		return exact_idx
	for i: int in range(_unequipped_equipment.size()):
		var eq: EquipmentItemData = _unequipped_equipment[i]
		if eq != null and eq.item_id == item.item_id:
			return i
	return -1

func _does_item_fit_slot(item: EquipmentItemData, slot_id: StringName, available_hands: int) -> bool:
	if item == null:
		return false
	if item.occupies_both_hands():
		return InventoryTypes.is_hand_slot(slot_id) and available_hands >= 2
	if item.slot_type == InventoryTypes.EquipmentSlotType.ONE_HAND or item.is_shield_item():
		if slot_id == InventoryTypes.SLOT_LEFT_HAND:
			return available_hands >= 1
		if slot_id == InventoryTypes.SLOT_RIGHT_HAND:
			return available_hands >= 2
		return false
	if item.slot_type == InventoryTypes.EquipmentSlotType.BODY:
		return slot_id == InventoryTypes.SLOT_BODY
	if item.slot_type == InventoryTypes.EquipmentSlotType.ACCESSORY:
		return slot_id == InventoryTypes.SLOT_ACCESSORY_1 or slot_id == InventoryTypes.SLOT_ACCESSORY_2
	return false
