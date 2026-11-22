# res://resources/inventory/equipment_loadout.gd
class_name EquipmentLoadout
extends Resource

## Сигнал об изменении экипировки бойца
signal loadout_changed()

## Количество доступных рук у бойца (задел для будущих спутников с 1 рукой)
@export_range(1, 2, 1) var available_hands: int = 2

## 5 слотов экипировки
@export var left_hand: EquipmentItemData = null
@export var right_hand: EquipmentItemData = null
@export var body: EquipmentItemData = null
@export var accessory_1: EquipmentItemData = null
@export var accessory_2: EquipmentItemData = null

## Создает изолированную копию набора экипировки (правило иммутабельности ресурсов)
func create_copy() -> EquipmentLoadout:
	var copy: EquipmentLoadout = EquipmentLoadout.new()
	copy.available_hands = available_hands
	copy.left_hand = left_hand
	copy.right_hand = right_hand
	copy.body = body
	copy.accessory_1 = accessory_1
	copy.accessory_2 = accessory_2
	return copy

## Возвращает true, если обе руки заняты одним двуручным оружием
func is_two_handed_equipped() -> bool:
	return left_hand != null and left_hand.slot_type == InventoryTypes.EquipmentSlotType.TWO_HAND

## Возвращает предмет в указанном слоте
func get_slot_item(slot_id: StringName) -> EquipmentItemData:
	match slot_id:
		InventoryTypes.SLOT_LEFT_HAND:
			return left_hand
		InventoryTypes.SLOT_RIGHT_HAND:
			return right_hand
		InventoryTypes.SLOT_BODY:
			return body
		InventoryTypes.SLOT_ACCESSORY_1:
			return accessory_1
		InventoryTypes.SLOT_ACCESSORY_2:
			return accessory_2
	return null

## Возвращает уникальные экземпляры экипировки без двойного учета двуручного оружия
func get_equipped_unique_items() -> Array[EquipmentItemData]:
	var result: Array[EquipmentItemData] = []
	if left_hand != null:
		result.append(left_hand)
	if right_hand != null and not is_two_handed_equipped():
		result.append(right_hand)
	if body != null:
		result.append(body)
	if accessory_1 != null:
		result.append(accessory_1)
	if accessory_2 != null:
		result.append(accessory_2)
	return result

## Проверяет, экипирован ли уже предмет с таким item_id в другом слоте
func is_item_id_equipped(p_item_id: String, ignore_slot: StringName = &"") -> bool:
	if p_item_id.is_empty():
		return false
	var ignore_both_hands: bool = is_two_handed_equipped() and InventoryTypes.is_hand_slot(ignore_slot)
	for slot_id: StringName in InventoryTypes.get_all_slot_ids():
		if slot_id == ignore_slot:
			continue
		if ignore_both_hands and InventoryTypes.is_hand_slot(slot_id):
			continue
		var eq: EquipmentItemData = get_slot_item(slot_id)
		if eq != null and eq.item_id == p_item_id:
			return true
	return false

## Проверяет возможность надеть предмет в указанный слот с учетом рук и уникальности
func can_equip_item(slot_id: StringName, item: EquipmentItemData) -> Dictionary:
	if item == null:
		return {"ok": false, "reason": "Предмет не указан."}
	if not InventoryTypes.get_all_slot_ids().has(slot_id):
		return {"ok": false, "reason": "Неизвестный слот экипировки."}
	
	match item.slot_type:
		InventoryTypes.EquipmentSlotType.TWO_HAND:
			if not InventoryTypes.is_hand_slot(slot_id):
				return {"ok": false, "reason": "Двуручное оружие надевается только в руки."}
			if available_hands < 2:
				return {"ok": false, "reason": "Недостаточно свободных рук для двуручного оружия."}
		InventoryTypes.EquipmentSlotType.ONE_HAND, InventoryTypes.EquipmentSlotType.SHIELD:
			if not InventoryTypes.is_hand_slot(slot_id):
				return {"ok": false, "reason": "Этот предмет предназначен для слота руки."}
			if slot_id == InventoryTypes.SLOT_RIGHT_HAND and available_hands < 2:
				return {"ok": false, "reason": "У бойца недоступна вторая рука."}
		InventoryTypes.EquipmentSlotType.BODY:
			if slot_id != InventoryTypes.SLOT_BODY:
				return {"ok": false, "reason": "Броня надевается только в слот «Тело»."}
		InventoryTypes.EquipmentSlotType.ACCESSORY:
			if slot_id != InventoryTypes.SLOT_ACCESSORY_1 and slot_id != InventoryTypes.SLOT_ACCESSORY_2:
				return {"ok": false, "reason": "Аксессуар надевается только в слоты аксессуаров."}
	
	if item.is_unique and is_item_id_equipped(item.item_id, slot_id):
		return {"ok": false, "reason": "Уникальный предмет «%s» уже экипирован." % item.display_name}
	
	return {"ok": true, "reason": ""}

## Надевает предмет в слот, соблюдая правила одноручного/двуручного оружия, и возвращает снятые вещи
func equip_into_slot(slot_id: StringName, item: EquipmentItemData) -> Dictionary:
	var check: Dictionary = can_equip_item(slot_id, item)
	if not bool(check.get("ok", false)):
		var empty_removed: Array[EquipmentItemData] = []
		return {
			"ok": false,
			"reason": str(check.get("reason", "Невозможно надеть предмет.")),
			"removed": empty_removed
		}
	
	var removed: Array[EquipmentItemData] = []
	if item.slot_type == InventoryTypes.EquipmentSlotType.TWO_HAND:
		if is_two_handed_equipped():
			removed.append(left_hand)
		else:
			if left_hand != null:
				removed.append(left_hand)
			if right_hand != null:
				removed.append(right_hand)
		left_hand = item
		right_hand = item
	elif InventoryTypes.is_hand_slot(slot_id):
		if is_two_handed_equipped():
			removed.append(left_hand)
			left_hand = null
			right_hand = null
		elif slot_id == InventoryTypes.SLOT_LEFT_HAND and left_hand != null:
			removed.append(left_hand)
			left_hand = null
		elif slot_id == InventoryTypes.SLOT_RIGHT_HAND and right_hand != null:
			removed.append(right_hand)
			right_hand = null
		
		if slot_id == InventoryTypes.SLOT_LEFT_HAND:
			left_hand = item
		else:
			right_hand = item
	elif slot_id == InventoryTypes.SLOT_BODY:
		if body != null:
			removed.append(body)
		body = item
	elif slot_id == InventoryTypes.SLOT_ACCESSORY_1:
		if accessory_1 != null:
			removed.append(accessory_1)
		accessory_1 = item
	elif slot_id == InventoryTypes.SLOT_ACCESSORY_2:
		if accessory_2 != null:
			removed.append(accessory_2)
		accessory_2 = item
	
	loadout_changed.emit()
	return {"ok": true, "reason": "", "removed": removed}

## Снимает предмет из слота (при двуручном оружии очищает обе руки и возвращает 1 экземпляр)
func unequip_from_slot(slot_id: StringName) -> Array[EquipmentItemData]:
	var removed: Array[EquipmentItemData] = []
	if InventoryTypes.is_hand_slot(slot_id) and is_two_handed_equipped():
		removed.append(left_hand)
		left_hand = null
		right_hand = null
		loadout_changed.emit()
		return removed
	
	match slot_id:
		InventoryTypes.SLOT_LEFT_HAND:
			if left_hand != null:
				removed.append(left_hand)
				left_hand = null
		InventoryTypes.SLOT_RIGHT_HAND:
			if right_hand != null:
				removed.append(right_hand)
				right_hand = null
		InventoryTypes.SLOT_BODY:
			if body != null:
				removed.append(body)
				body = null
		InventoryTypes.SLOT_ACCESSORY_1:
			if accessory_1 != null:
				removed.append(accessory_1)
				accessory_1 = null
		InventoryTypes.SLOT_ACCESSORY_2:
			if accessory_2 != null:
				removed.append(accessory_2)
				accessory_2 = null
	
	if not removed.is_empty():
		loadout_changed.emit()
	return removed

## Суммирует бонусы характеристик всех надетых вещей без дублирования двуручного оружия
func get_total_stat_bonuses() -> Dictionary:
	var totals: Dictionary = {
		"max_hp": 0,
		"attack": 0,
		"magic_power": 0,
		"defense": 0,
		"speed": 0,
		"crit_chance": 0.0,
		"crit_multiplier": 0.0
	}
	for eq: EquipmentItemData in get_equipped_unique_items():
		totals["max_hp"] = int(totals["max_hp"]) + eq.bonus_max_hp
		totals["attack"] = int(totals["attack"]) + eq.bonus_attack
		totals["magic_power"] = int(totals["magic_power"]) + eq.bonus_magic_power
		totals["defense"] = int(totals["defense"]) + eq.bonus_defense
		totals["speed"] = int(totals["speed"]) + eq.bonus_speed
		totals["crit_chance"] = float(totals["crit_chance"]) + eq.bonus_crit_chance
		totals["crit_multiplier"] = float(totals["crit_multiplier"]) + eq.bonus_crit_multiplier
	return totals

## Вычисляет активные парные оружейные синергии для текущих рук
func get_active_synergies(synergy_catalog: Array[WeaponSynergyData]) -> Array[WeaponSynergyData]:
	var active: Array[WeaponSynergyData] = []
	if available_hands < 2 or is_two_handed_equipped():
		return active
	if left_hand == null or right_hand == null:
		return active
	
	var seen_ids: Array[String] = []
	for syn: WeaponSynergyData in synergy_catalog:
		if syn == null:
			continue
		if syn.matches_hands(left_hand.weapon_archetype, right_hand.weapon_archetype):
			if not syn.synergy_id.is_empty() and seen_ids.has(syn.synergy_id):
				continue
			if not syn.synergy_id.is_empty():
				seen_ids.append(syn.synergy_id)
			active.append(syn)
	return active

## Собирает умения от надетых предметов и активных оружейных синергий (без дублей)
func get_granted_skills(synergy_catalog: Array[WeaponSynergyData]) -> Array[SkillData]:
	var collected: Array[SkillData] = []
	var seen_skill_ids: Array[String] = []
	
	for eq: EquipmentItemData in get_equipped_unique_items():
		for sk: SkillData in eq.granted_skills:
			if sk == null:
				continue
			if not sk.skill_id.is_empty() and seen_skill_ids.has(sk.skill_id):
				continue
			if not sk.skill_id.is_empty():
				seen_skill_ids.append(sk.skill_id)
			collected.append(sk)
	
	for syn: WeaponSynergyData in get_active_synergies(synergy_catalog):
		if syn.granted_skill == null:
			continue
		var sk: SkillData = syn.granted_skill
		if not sk.skill_id.is_empty() and seen_skill_ids.has(sk.skill_id):
			continue
		if not sk.skill_id.is_empty():
			seen_skill_ids.append(sk.skill_id)
		collected.append(sk)
	
	return collected

## Возвращает сводный словарь модификации порогов QTE от всей экипировки
func get_effective_qte_overrides() -> Dictionary:
	var has_override: bool = false
	var use_absolute: bool = false
	var miss_t: float = 0.30
	var weak_t: float = 0.60
	var perfect_t: float = 0.90
	var miss_delta: float = 0.0
	var perfect_delta: float = 0.0
	var guaranteed_crit_on_perfect: bool = false
	
	for eq: EquipmentItemData in get_equipped_unique_items():
		if eq.override_qte_thresholds:
			has_override = true
			use_absolute = true
			miss_t = eq.qte_miss_threshold
			weak_t = eq.qte_weak_threshold
			perfect_t = eq.qte_perfect_threshold
		if eq.qte_guaranteed_crit_on_perfect:
			has_override = true
			guaranteed_crit_on_perfect = true
		if not is_zero_approx(eq.qte_miss_threshold_delta) or not is_zero_approx(eq.qte_perfect_threshold_delta):
			has_override = true
			miss_delta += eq.qte_miss_threshold_delta
			perfect_delta += eq.qte_perfect_threshold_delta
	
	return {
		"has_override": has_override,
		"use_absolute": use_absolute,
		"miss_threshold": miss_t,
		"weak_threshold": weak_t,
		"perfect_threshold": perfect_t,
		"miss_delta": miss_delta,
		"perfect_delta": perfect_delta,
		"guaranteed_crit_on_perfect": guaranteed_crit_on_perfect
	}

## Собирает все пассивные теги надетых предметов
func get_passive_tags() -> Array[StringName]:
	var result: Array[StringName] = []
	for eq: EquipmentItemData in get_equipped_unique_items():
		for tag: StringName in eq.passive_tags:
			if not tag.is_empty() and not result.has(tag):
				result.append(tag)
	return result
