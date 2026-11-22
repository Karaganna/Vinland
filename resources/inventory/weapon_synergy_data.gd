# res://resources/inventory/weapon_synergy_data.gd
class_name WeaponSynergyData
extends Resource

## Data-Driven описание парной оружейной синергии двух рук (порядок левой/правой не важен)
@export var synergy_id: String = ""
@export var display_name: String = "Синергия рук"
@export_multiline var description: String = ""
@export var archetype_a: InventoryTypes.WeaponArchetype = InventoryTypes.WeaponArchetype.NONE
@export var archetype_b: InventoryTypes.WeaponArchetype = InventoryTypes.WeaponArchetype.NONE
@export var granted_skill: SkillData = null

## Проверяет совпадение архетипов в левой и правой руке независимо от их порядка
func matches_hands(left_arch: InventoryTypes.WeaponArchetype, right_arch: InventoryTypes.WeaponArchetype) -> bool:
	if archetype_a == InventoryTypes.WeaponArchetype.NONE or archetype_b == InventoryTypes.WeaponArchetype.NONE:
		return false
	if left_arch == InventoryTypes.WeaponArchetype.NONE or right_arch == InventoryTypes.WeaponArchetype.NONE:
		return false
	return (left_arch == archetype_a and right_arch == archetype_b) or (left_arch == archetype_b and right_arch == archetype_a)
