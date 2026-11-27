# res://resources/inventory/equipment_loadout.gd
class_name EquipmentLoadout
extends Resource

## Сигнал об изменении экипировки бойца
signal loadout_changed()

## Количество доступных рук у бойца (1 у однорукого бойца — активирует EMPTY_HAND и блокирует 2H/комплекты)
@export_range(1, 2, 1) var available_hands: int = 2

## 5 слотов экипировки (броня представлена единственным слотом body)
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

## Возвращает true, если обе руки заняты одним двуручным оружием или неделимым парным комплектом
func is_two_handed_equipped() -> bool:
	return left_hand != null and left_hand.occupies_both_hands()

## Возвращает предмет в указанном слоте
func get_slot_item(slot_id: StringName) -> EquipmentItemData:
	match slot_id:
		InventoryTypes.SLOT_LEFT_HAND:
			return left_hand
		InventoryTypes.SLOT_RIGHT_HAND:
			return right_hand if available_hands >= 2 else null
		InventoryTypes.SLOT_BODY:
			return body
		InventoryTypes.SLOT_ACCESSORY_1:
			return accessory_1
		InventoryTypes.SLOT_ACCESSORY_2:
			return accessory_2
	return null

## Возвращает уникальные экземпляры экипировки без двойного учета двуручного оружия / комплекта
func get_equipped_unique_items() -> Array[EquipmentItemData]:
	var result: Array[EquipmentItemData] = []
	if left_hand != null:
		result.append(left_hand)
	if available_hands >= 2 and right_hand != null and not is_two_handed_equipped():
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

## Базовая проверка совместимости предмета со слотом, числом рук и уникальностью
func can_equip_item(slot_id: StringName, item: EquipmentItemData) -> Dictionary:
	if item == null:
		return {"ok": false, "reason": "Предмет не указан."}
	if not InventoryTypes.get_all_slot_ids().has(slot_id):
		return {"ok": false, "reason": "Неизвестный слот экипировки."}
	
	if item.occupies_both_hands():
		if not InventoryTypes.is_hand_slot(slot_id):
			return {"ok": false, "reason": "Двуручное оружие и комплекты надеваются только в руки."}
		if available_hands < 2:
			return {"ok": false, "reason": "Однорукий боец не может носить двуручное оружие или парные комплекты."}
	elif item.slot_type == InventoryTypes.EquipmentSlotType.ONE_HAND or item.is_shield_item():
		if not InventoryTypes.is_hand_slot(slot_id):
			return {"ok": false, "reason": "Этот предмет предназначен для слота руки."}
		if slot_id == InventoryTypes.SLOT_RIGHT_HAND and available_hands < 2:
			return {"ok": false, "reason": "У однорукого бойца недоступна вторая рука."}
	elif item.slot_type == InventoryTypes.EquipmentSlotType.BODY:
		if slot_id != InventoryTypes.SLOT_BODY:
			return {"ok": false, "reason": "Броня надевается только в слот «Тело»."}
	elif item.slot_type == InventoryTypes.EquipmentSlotType.ACCESSORY:
		if slot_id != InventoryTypes.SLOT_ACCESSORY_1 and slot_id != InventoryTypes.SLOT_ACCESSORY_2:
			return {"ok": false, "reason": "Аксессуар надевается только в слоты аксессуаров."}
	
	if item.is_unique and is_item_id_equipped(item.item_id, slot_id):
		return {"ok": false, "reason": "Уникальный предмет «%s» уже экипирован." % item.display_name}
	
	return {"ok": true, "reason": ""}

## Полная проверка экипировки с учетом правил ГГ vs рекрутов, категории оружия, «Тяжелого» и Даров Реликвий
func can_equip_for_combatant(combatant_data: CombatantData, slot_id: StringName, item: EquipmentItemData) -> Dictionary:
	var base_check: Dictionary = can_equip_item(slot_id, item)
	if not bool(base_check.get("ok", false)):
		return base_check
	if combatant_data == null or item == null:
		return base_check
	
	# 1. Разделение фирменного оружия/щитов ГГ и оружия мира / легендарок рекрутов
	if item.is_weapon_item() or item.is_shield_item():
		if combatant_data.is_hero:
			if not item.is_hero_signature:
				return {"ok": false, "reason": "Главный герой использует только фирменное сюжетное оружие и щиты."}
			if item.is_legendary:
				return {"ok": false, "reason": "Легендарное оружие мира предназначено только для рекрутов."}
		else:
			if item.is_hero_signature:
				return {"ok": false, "reason": "Фирменное снаряжение «%s» доступно только Главному герою." % item.display_name}
	
	# 2. Привязка рекрута к своей категории оружия (щиты разрешены с учетом проверки «Тяжелого», кроме строго двуручного POLEARM)
	if not combatant_data.is_hero and combatant_data.weapon_category == InventoryTypes.WeaponCategory.POLEARM and item.is_shield_item():
		return {
			"ok": false,
			"reason": "Категория «Древковое» у рекрутов строго двуручная — щиты не используются."
		}
	if not combatant_data.is_hero and item.is_weapon_item():
		var item_cat: InventoryTypes.WeaponCategory = item.get_effective_weapon_category()
		if combatant_data.weapon_category != InventoryTypes.WeaponCategory.NONE and item_cat != combatant_data.weapon_category:
			return {
				"ok": false,
				"reason": "Боец владеет только категорией «%s»." % InventoryTypes.get_weapon_category_display_name(combatant_data.weapon_category)
			}
	
	# 3. Проверка метки «Тяжелое» (на оружии, тяжелых щитах и тяжелой броне)
	if item.is_heavy and not combatant_data.can_wear_heavy:
		return {"ok": false, "reason": "Боец не может носить тяжёлое снаряжение."}
	
	# 4. Проверка Дара Реликвии для категории RELICS
	var req_gift: InventoryTypes.RelicGift = item.get_effective_required_gift()
	if req_gift != InventoryTypes.RelicGift.NONE and not combatant_data.has_relic_gift(req_gift):
		return {
			"ok": false,
			"reason": "Требуется Дар «%s» для использования этой реликвии." % InventoryTypes.get_relic_gift_display_name(req_gift)
		}
	
	return {"ok": true, "reason": ""}

## Надевает предмет с полной проверкой ограничений конкретного бойца
func equip_into_slot_for_combatant(combatant_data: CombatantData, slot_id: StringName, item: EquipmentItemData) -> Dictionary:
	var check: Dictionary = can_equip_for_combatant(combatant_data, slot_id, item)
	if not bool(check.get("ok", false)):
		var empty_removed: Array[EquipmentItemData] = []
		return {
			"ok": false,
			"reason": str(check.get("reason", "Невозможно надеть предмет.")),
			"removed": empty_removed
		}
	return _perform_equip_into_slot(slot_id, item)

## Надевает предмет в слот с базовой проверкой слота и рук (для фабрик пресетов)
func equip_into_slot(slot_id: StringName, item: EquipmentItemData) -> Dictionary:
	var check: Dictionary = can_equip_item(slot_id, item)
	if not bool(check.get("ok", false)):
		var empty_removed: Array[EquipmentItemData] = []
		return {
			"ok": false,
			"reason": str(check.get("reason", "Невозможно надеть предмет.")),
			"removed": empty_removed
		}
	return _perform_equip_into_slot(slot_id, item)

func _perform_equip_into_slot(slot_id: StringName, item: EquipmentItemData) -> Dictionary:
	var removed: Array[EquipmentItemData] = []
	if item.occupies_both_hands():
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

## Снимает предмет из слота (при двуручном оружии / комплекте очищает обе руки и возвращает 1 экземпляр)
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

## Суммирует бонусы характеристик всех надетых вещей без дублирования двуручного оружия / комплекта
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

## Вычисляет активные оружейные синергии рук (включая EMPTY_HAND у одноруких и со свободной второй рукой)
func get_active_synergies(synergy_catalog: Array[WeaponSynergyData]) -> Array[WeaponSynergyData]:
	var active: Array[WeaponSynergyData] = []
	if is_two_handed_equipped():
		return active
	
	var eff_right: EquipmentItemData = right_hand if available_hands >= 2 else null
	if left_hand == null and eff_right == null:
		return active
	
	var seen_ids: Array[String] = []
	for syn: WeaponSynergyData in synergy_catalog:
		if syn == null:
			continue
		if syn.matches_loadout_hands(left_hand, eff_right, available_hands):
			if not syn.synergy_id.is_empty() and seen_ids.has(syn.synergy_id):
				continue
			if not syn.synergy_id.is_empty():
				seen_ids.append(syn.synergy_id)
			active.append(syn)
	return active

## Формирует набор активных навыков строго по 4 правилам рук, синергий, комплектов и легендарок (щиты навыков не дают)
func get_granted_skills(synergy_catalog: Array[WeaponSynergyData]) -> Array[SkillData]:
	var collected: Array[SkillData] = []
	var seen_skill_ids: Array[String] = []
	
	# 1. Двуручное оружие или неделимый комплект: до 2 базовых навыков типа + 2 легендарных (если легендарное)
	if is_two_handed_equipped() and left_hand != null and left_hand.is_weapon_item():
		var base_limit: int = mini(2, left_hand.granted_skills.size())
		for i: int in range(base_limit):
			_append_unique_skill(collected, seen_skill_ids, left_hand.granted_skills[i])
		if left_hand.is_legendary:
			for leg_sk: SkillData in left_hand.legendary_skills:
				_append_unique_skill(collected, seen_skill_ids, leg_sk)
	else:
		# 2. Одноручная конфигурация рук
		var eff_right: EquipmentItemData = right_hand if available_hands >= 2 else null
		var left_w: EquipmentItemData = left_hand if (left_hand != null and left_hand.is_weapon_item()) else null
		var right_w: EquipmentItemData = eff_right if (eff_right != null and eff_right.is_weapon_item()) else null
		var active_syns: Array[WeaponSynergyData] = get_active_synergies(synergy_catalog)
		
		if not active_syns.is_empty():
			# Правило 1: Одноручное + подходящая вторая рука (SAME_TYPE / SHIELD / LIGHT_SHIELD / EMPTY_HAND) -> 1 базовый + 1 синергийный
			var primary_w: EquipmentItemData = left_w if left_w != null else right_w
			if primary_w != null and not primary_w.granted_skills.is_empty():
				_append_unique_skill(collected, seen_skill_ids, primary_w.granted_skills[0])
			for syn: WeaponSynergyData in active_syns:
				_append_unique_skill(collected, seen_skill_ids, syn.granted_skill)
		else:
			# Правило 2: Два разных одноручных без синергии (или одно без синергии) -> по 1 базовому навыку от каждого оружия
			if left_w != null and not left_w.granted_skills.is_empty():
				_append_unique_skill(collected, seen_skill_ids, left_w.granted_skills[0])
			if right_w != null and not right_w.granted_skills.is_empty():
				_append_unique_skill(collected, seen_skill_ids, right_w.granted_skills[0])
		
		# Правило 4: Легендарное одноручное оружие дает поверх 2 уникальных легендарных навыка
		if left_w != null and left_w.is_legendary:
			for leg_sk: SkillData in left_w.legendary_skills:
				_append_unique_skill(collected, seen_skill_ids, leg_sk)
		if right_w != null and right_w.is_legendary and right_w != left_w:
			for leg_sk: SkillData in right_w.legendary_skills:
				_append_unique_skill(collected, seen_skill_ids, leg_sk)
	
	# Навыки от брони/аксессуаров (если заданы; щиты гарантированно навыков не выдают)
	for non_hand_eq: EquipmentItemData in [body, accessory_1, accessory_2]:
		if non_hand_eq != null and not non_hand_eq.is_shield_item():
			for sk: SkillData in non_hand_eq.granted_skills:
				_append_unique_skill(collected, seen_skill_ids, sk)
	
	return collected

static func _append_unique_skill(target_list: Array[SkillData], seen_ids: Array[String], sk: SkillData) -> void:
	if sk == null:
		return
	if not sk.skill_id.is_empty():
		if seen_ids.has(sk.skill_id):
			return
		seen_ids.append(sk.skill_id)
	target_list.append(sk)

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

## Определяет режим шкалы «Поток» у ГГ по надетому фирменному оружию
func resolve_hero_flow_mode(fallback_mode: BattleTypes.ResourceType = BattleTypes.ResourceType.ENERGY) -> BattleTypes.ResourceType:
	for eq: EquipmentItemData in get_equipped_unique_items():
		if eq != null and eq.sets_hero_flow_mode:
			return eq.hero_flow_mode
	return fallback_mode

## Возвращает экипированные предметы с пороговыми пассивками от уровня «Потока»
func get_flow_threshold_items() -> Array[EquipmentItemData]:
	var items: Array[EquipmentItemData] = []
	for eq: EquipmentItemData in get_equipped_unique_items():
		if eq != null and eq.has_flow_threshold_passive:
			items.append(eq)
	return items

## Проверяет, экипирован ли на бойце щит (SHIELD, SHIELD_LIGHT или SHIELD_HEAVY)
func has_shield_equipped() -> bool:
	for eq: EquipmentItemData in get_equipped_unique_items():
		if eq != null and eq.is_shield_item():
			return true
	return false

## Возвращает суммарную прибавку защиты именно от экипированных щитов (для обхода через IGNORES_SHIELD)
func get_shield_defense_bonus() -> int:
	var shield_def: int = 0
	for eq: EquipmentItemData in get_equipped_unique_items():
		if eq != null and eq.is_shield_item():
			shield_def += maxi(0, eq.bonus_defense)
	return shield_def

## Возвращает пассивные шансы усиленного и полного блока от экипированного щита в стойке Блок
func get_shield_block_chances() -> Dictionary:
	var has_sh: bool = false
	var enhanced_ch: float = 0.0
	var full_ch: float = 0.0
	for eq: EquipmentItemData in get_equipped_unique_items():
		if eq != null and eq.is_shield_item():
			has_sh = true
			enhanced_ch = maxf(enhanced_ch, eq.shield_enhanced_block_chance)
			full_ch = maxf(full_ch, eq.shield_full_block_chance)
	return {
		"has_shield": has_sh,
		"enhanced_chance": clampf(enhanced_ch, 0.0, 1.0),
		"full_chance": clampf(full_ch, 0.0, 1.0)
	}
