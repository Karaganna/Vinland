# res://resources/inventory/weapon_synergy_data.gd
class_name WeaponSynergyData
extends Resource

## Data-Driven описание синергии одноручного типа оружия со второй рукой (щит, пара того же типа, свободная рука)
@export var synergy_id: String = ""
@export var display_name: String = "Синергия рук"
@export_multiline var description: String = ""

## Тип оружия, для которого определена синергия
@export var primary_weapon_type: InventoryTypes.WeaponType = InventoryTypes.WeaponType.NONE
## Условие для второй руки (SAME_TYPE, ANY_SHIELD, LIGHT_SHIELD_ONLY, EMPTY_HAND)
@export var condition: InventoryTypes.HandSynergyCondition = InventoryTypes.HandSynergyCondition.NONE
## Различать ли синергию только для фирменного оружия ГГ vs оружия рекрутов
@export var hero_signature_only: bool = false
@export var recruit_only: bool = false

## Legacy-поля архетипов (для обратной совместимости)
@export var archetype_a: InventoryTypes.WeaponArchetype = InventoryTypes.WeaponArchetype.NONE
@export var archetype_b: InventoryTypes.WeaponArchetype = InventoryTypes.WeaponArchetype.NONE

## Синергийный навык, открываемый при выполнении условия второй руки
@export var granted_skill: SkillData = null

## Проверяет выполнение условия синергии для пары предметов в руках (либо однорукого бойца)
func matches_loadout_hands(
	left_item: EquipmentItemData,
	right_item: EquipmentItemData,
	available_hands: int
) -> bool:
	# Если оба слота заняты одним двуручным оружием или неделимым комплектом — синергия одноручных рук не применяется
	if left_item != null and left_item.occupies_both_hands():
		return false
	if right_item != null and right_item.occupies_both_hands():
		return false
	
	if condition == InventoryTypes.HandSynergyCondition.LEGACY_ARCHETYPE_PAIR or (
		primary_weapon_type == InventoryTypes.WeaponType.NONE
		and archetype_a != InventoryTypes.WeaponArchetype.NONE
	):
		if left_item == null or right_item == null or available_hands < 2:
			return false
		return matches_hands(left_item.weapon_archetype, right_item.weapon_archetype)
	
	if primary_weapon_type == InventoryTypes.WeaponType.NONE:
		return false
	
	# Случай однорукого бойца (available_hands == 1): активна только левая рука, вторая всегда считается EMPTY_HAND
	if available_hands == 1:
		if condition != InventoryTypes.HandSynergyCondition.EMPTY_HAND:
			return false
		return _matches_primary_weapon(left_item)
	
	# Случай двурукого бойца (available_hands == 2)
	match condition:
		InventoryTypes.HandSynergyCondition.SAME_TYPE:
			return (
				left_item != null
				and right_item != null
				and _matches_primary_weapon(left_item)
				and _matches_primary_weapon(right_item)
			)
		InventoryTypes.HandSynergyCondition.ANY_SHIELD:
			return (
				(_matches_primary_weapon(left_item) and right_item != null and right_item.is_shield_item())
				or (_matches_primary_weapon(right_item) and left_item != null and left_item.is_shield_item())
			)
		InventoryTypes.HandSynergyCondition.LIGHT_SHIELD_ONLY:
			return (
				(_matches_primary_weapon(left_item) and right_item != null and right_item.is_light_shield_item())
				or (_matches_primary_weapon(right_item) and left_item != null and left_item.is_light_shield_item())
			)
		InventoryTypes.HandSynergyCondition.EMPTY_HAND:
			return (
				(_matches_primary_weapon(left_item) and right_item == null)
				or (_matches_primary_weapon(right_item) and left_item == null)
			)
	return false

func _matches_primary_weapon(item: EquipmentItemData) -> bool:
	if item == null or not item.is_weapon_item():
		return false
	if item.weapon_type != primary_weapon_type:
		return false
	if hero_signature_only and not item.is_hero_signature:
		return false
	if recruit_only and item.is_hero_signature:
		return false
	return true

## Legacy-проверка совпадения архетипов в левой и правой руке
func matches_hands(left_arch: InventoryTypes.WeaponArchetype, right_arch: InventoryTypes.WeaponArchetype) -> bool:
	if archetype_a == InventoryTypes.WeaponArchetype.NONE or archetype_b == InventoryTypes.WeaponArchetype.NONE:
		return false
	if left_arch == InventoryTypes.WeaponArchetype.NONE or right_arch == InventoryTypes.WeaponArchetype.NONE:
		return false
	return (left_arch == archetype_a and right_arch == archetype_b) or (left_arch == archetype_b and right_arch == archetype_a)
