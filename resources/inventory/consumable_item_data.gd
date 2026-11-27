# res://resources/inventory/consumable_item_data.gd
class_name ConsumableItemData
extends ItemData

## Расходный предмет для применения в бою и/или в оверворлде (включая ритуальный сброс рун)
@export var heal_hp: int = 0
@export var restore_resource_type: BattleTypes.ResourceType = BattleTypes.ResourceType.MANA
@export var restore_resource_amount: int = 0
@export var cure_statuses: Array[BattleTypes.StatusType] = []
@export var is_rune_reset_item: bool = false
@export var usable_in_battle: bool = true
@export var usable_in_overworld: bool = true

func _init() -> void:
	item_category = InventoryTypes.ItemCategory.CONSUMABLE
	stackable = true
	if max_stack < 1:
		max_stack = 99
	is_unique = false

## Возвращает краткое текстовое описание эффекта расходника для UI
func get_effect_summary() -> String:
	var parts: PackedStringArray = PackedStringArray()
	if is_rune_reset_item:
		parts.append("Сброс Футарка (возврат 100% Знаков)")
	if heal_hp > 0:
		parts.append("+%d HP" % heal_hp)
	if restore_resource_amount > 0:
		parts.append("+%d %s" % [restore_resource_amount, BattleTypes.get_resource_display_name(restore_resource_type)])
	if not cure_statuses.is_empty():
		var status_names: PackedStringArray = PackedStringArray()
		for st: BattleTypes.StatusType in cure_statuses:
			status_names.append(BattleTypes.get_status_display_name(st))
		parts.append("Снимает: %s" % ", ".join(status_names))
	return ", ".join(parts) if not parts.is_empty() else "Без эффекта"
