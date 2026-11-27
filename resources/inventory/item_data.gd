# res://resources/inventory/item_data.gd
class_name ItemData
extends Resource

## Базовый Data-Driven ресурс предмета (расходник или экипировка)
@export var item_id: String = ""
@export var display_name: String = "Предмет"
@export_multiline var description: String = ""
@export var item_category: InventoryTypes.ItemCategory = InventoryTypes.ItemCategory.CONSUMABLE
@export var stackable: bool = true
@export_range(1, 999, 1) var max_stack: int = 99
@export var is_unique: bool = false
## Опциональная пользовательская текстура иконки из Aseprite (если null — берется PNG по item_id или процедурная из InventoryVisualFactory)
@export var icon_texture: Texture2D = null
