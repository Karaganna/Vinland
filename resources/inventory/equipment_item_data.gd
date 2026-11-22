# res://resources/inventory/equipment_item_data.gd
class_name EquipmentItemData
extends ItemData

## Предмет экипировки (оружие, щит, броня, аксессуар)
@export var slot_type: InventoryTypes.EquipmentSlotType = InventoryTypes.EquipmentSlotType.ONE_HAND
@export var weapon_archetype: InventoryTypes.WeaponArchetype = InventoryTypes.WeaponArchetype.NONE

@export_group("Модификаторы характеристик")
@export var bonus_max_hp: int = 0
@export var bonus_attack: int = 0
@export var bonus_magic_power: int = 0
@export var bonus_defense: int = 0
@export var bonus_speed: int = 0
@export_range(-0.5, 1.0, 0.01) var bonus_crit_chance: float = 0.0
@export var bonus_crit_multiplier: float = 0.0

@export_group("Умения и теги")
@export var granted_skills: Array[SkillData] = []
@export var passive_tags: Array[StringName] = []

@export_group("Модификация порогов QTE")
@export var override_qte_thresholds: bool = false
@export_range(0.0, 1.0, 0.01) var qte_miss_threshold: float = 0.30
@export_range(0.0, 1.0, 0.01) var qte_weak_threshold: float = 0.60
@export_range(0.0, 1.0, 0.01) var qte_perfect_threshold: float = 0.90
@export var qte_guaranteed_crit_on_perfect: bool = false
## Сдвиг порогов (например, -0.10 расширяет зону идеального QTE на 10%)
@export_range(-0.5, 0.5, 0.01) var qte_miss_threshold_delta: float = 0.0
@export_range(-0.5, 0.5, 0.01) var qte_perfect_threshold_delta: float = 0.0

func _init() -> void:
	item_category = InventoryTypes.ItemCategory.EQUIPMENT
	stackable = false
	max_stack = 1

## Проверяет, влияет ли предмет на пороги QTE
func has_qte_modification() -> bool:
	return (
		override_qte_thresholds
		or qte_guaranteed_crit_on_perfect
		or not is_zero_approx(qte_miss_threshold_delta)
		or not is_zero_approx(qte_perfect_threshold_delta)
	)

## Возвращает краткую строку бонусов предмета для UI
func get_stat_summary() -> String:
	var parts: PackedStringArray = PackedStringArray()
	if bonus_max_hp != 0:
		parts.append("%+d HP" % bonus_max_hp)
	if bonus_attack != 0:
		parts.append("%+d АТК" % bonus_attack)
	if bonus_magic_power != 0:
		parts.append("%+d МАГ" % bonus_magic_power)
	if bonus_defense != 0:
		parts.append("%+d ЗАЩ" % bonus_defense)
	if bonus_speed != 0:
		parts.append("%+d СКР" % bonus_speed)
	if not is_zero_approx(bonus_crit_chance):
		parts.append("%+d%% Крит" % roundi(bonus_crit_chance * 100.0))
	if not is_zero_approx(bonus_crit_multiplier):
		parts.append("%+.1fx Множ.крита" % bonus_crit_multiplier)
	if not granted_skills.is_empty():
		parts.append("Умений: %d" % granted_skills.size())
	if has_qte_modification():
		parts.append("QTE-мод")
	return ", ".join(parts) if not parts.is_empty() else "Без бонусов"
