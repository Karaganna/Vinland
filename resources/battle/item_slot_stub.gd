# res://resources/battle/item_slot_stub.gd
class_name ItemSlotStub
extends Resource

## Заглушка слота расходника для будущего подключения инвентаря
@export var item_id: String = ""
@export var item_name: String = ""
@export var quantity: int = 0
@export var heal_hp: int = 0
@export var restore_resource_type: BattleTypes.ResourceType = BattleTypes.ResourceType.MANA
@export var restore_resource_amount: int = 0
@export_multiline var description: String = "Заглушка слота предмета для будущего инвентаря."

## Возвращает true, если слот пуст или расходник закончился
func is_empty() -> bool:
	return item_id.is_empty() or quantity <= 0
