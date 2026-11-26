# res://resources/inventory/equipment_item_data.gd
class_name EquipmentItemData
extends ItemData

## Предмет экипировки (оружие, легкий/тяжелый щит, броня, аксессуар)
@export var slot_type: InventoryTypes.EquipmentSlotType = InventoryTypes.EquipmentSlotType.ONE_HAND
@export var weapon_category: InventoryTypes.WeaponCategory = InventoryTypes.WeaponCategory.NONE
@export var weapon_type: InventoryTypes.WeaponType = InventoryTypes.WeaponType.NONE
## Legacy-архетип (сохраняется для совместимости)
@export var weapon_archetype: InventoryTypes.WeaponArchetype = InventoryTypes.WeaponArchetype.NONE

@export_group("Ограничения, комплекты, легендарность и Дары")
## Метка «Тяжелое» (недоступно бойцам с can_wear_heavy == false)
@export var is_heavy: bool = false
## Неделимый парный комплект на обе руки (например, клинки «Сёстры»; недоступен одноруким)
@export var is_set_bundle: bool = false
## Легендарное оружие мира (для рекрутов: дает навыки типа/синергии + 2 легендарных навыка)
@export var is_legendary: bool = false
## Фирменное сюжетное оружие или щит Главного Героя (недоступно рекрутам)
@export var is_hero_signature: bool = false
## Требуемый Дар для использования предмета категории RELICS
@export var required_gift: InventoryTypes.RelicGift = InventoryTypes.RelicGift.NONE

@export_group("Модификаторы характеристик")
@export var bonus_max_hp: int = 0
@export var bonus_attack: int = 0
@export var bonus_magic_power: int = 0
@export var bonus_defense: int = 0
@export var bonus_speed: int = 0
@export_range(-0.5, 1.0, 0.01) var bonus_crit_chance: float = 0.0
@export var bonus_crit_multiplier: float = 0.0

@export_group("Пассивные свойства щита (в стойке Блок)")
## Шанс усиленного блока (+25% к эффективности блока) в стойке ActionType.BLOCK
@export_range(0.0, 1.0, 0.05) var shield_enhanced_block_chance: float = 0.0
## Шанс полного 100% блока урона в стойке ActionType.BLOCK
@export_range(0.0, 1.0, 0.05) var shield_full_block_chance: float = 0.0

@export_group("Навыки типа оружия, легендарные умения и Поток ГГ")
## Базовые навыки типа оружия (1 для 1H, 2 для 2H/комплекта; у щитов всегда пусто!)
@export var granted_skills: Array[SkillData] = []
## 2 уникальных легендарных навыка (выдаются сверх навыков типа при is_legendary == true)
@export var legendary_skills: Array[SkillData] = []
@export var passive_tags: Array[StringName] = []
@export var sets_hero_flow_mode: bool = false
@export var hero_flow_mode: BattleTypes.ResourceType = BattleTypes.ResourceType.ENERGY
@export var has_flow_threshold_passive: bool = false
@export_range(0.0, 1.0, 0.05) var flow_threshold_ratio: float = 0.90
@export var flow_threshold_status: BattleTypes.StatusType = BattleTypes.StatusType.BURN
@export var flow_threshold_status_turns: int = 2
@export var flow_threshold_status_magnitude: float = 1.0

@export_group("Модификация порогов QTE")
@export var override_qte_thresholds: bool = false
@export_range(0.0, 1.0, 0.01) var qte_miss_threshold: float = 0.30
@export_range(0.0, 1.0, 0.01) var qte_weak_threshold: float = 0.60
@export_range(0.0, 1.0, 0.01) var qte_perfect_threshold: float = 0.90
@export var qte_guaranteed_crit_on_perfect: bool = false
@export_range(-0.5, 0.5, 0.01) var qte_miss_threshold_delta: float = 0.0
@export_range(-0.5, 0.5, 0.01) var qte_perfect_threshold_delta: float = 0.0

func _init() -> void:
	item_category = InventoryTypes.ItemCategory.EQUIPMENT
	stackable = false
	max_stack = 1

## Возвращает true, если предмет является щитом (легким, тяжелым или общим)
func is_shield_item() -> bool:
	return InventoryTypes.is_shield_slot_type(slot_type)

## Возвращает true, если предмет является легким щитом
func is_light_shield_item() -> bool:
	return InventoryTypes.is_light_shield_slot_type(slot_type)

## Возвращает true, если предмет является оружием (не щитом, не броней и не аксессуаром)
func is_weapon_item() -> bool:
	return (
		(slot_type == InventoryTypes.EquipmentSlotType.ONE_HAND or slot_type == InventoryTypes.EquipmentSlotType.TWO_HAND)
		and not is_shield_item()
	)

## Возвращает true, если предмет неделимо занимает обе руки (двуручное оружие или парный комплект)
func occupies_both_hands() -> bool:
	return slot_type == InventoryTypes.EquipmentSlotType.TWO_HAND or is_set_bundle

## Возвращает эффективный требуемый Дар для Реликвии
func get_effective_required_gift() -> InventoryTypes.RelicGift:
	if required_gift != InventoryTypes.RelicGift.NONE:
		return required_gift
	if weapon_category == InventoryTypes.WeaponCategory.RELICS:
		return InventoryTypes.get_required_gift_for_weapon_type(weapon_type)
	return InventoryTypes.RelicGift.NONE

## Возвращает эффективную категорию оружия (автоматически определяя по WeaponType, если не задана явно)
func get_effective_weapon_category() -> InventoryTypes.WeaponCategory:
	if weapon_category != InventoryTypes.WeaponCategory.NONE:
		return weapon_category
	if weapon_type != InventoryTypes.WeaponType.NONE:
		return InventoryTypes.get_category_for_weapon_type(weapon_type)
	return InventoryTypes.WeaponCategory.NONE

## Проверяет, влияет ли предмет на пороги QTE
func has_qte_modification() -> bool:
	return (
		override_qte_thresholds
		or qte_guaranteed_crit_on_perfect
		or not is_zero_approx(qte_miss_threshold_delta)
		or not is_zero_approx(qte_perfect_threshold_delta)
	)

## Возвращает краткую строку типа, меток и бонусов предмета для UI
func get_stat_summary() -> String:
	var parts: PackedStringArray = PackedStringArray()
	if weapon_type != InventoryTypes.WeaponType.NONE:
		parts.append(InventoryTypes.get_weapon_type_display_name(weapon_type))
	if is_heavy:
		parts.append("Тяж.")
	if is_set_bundle:
		parts.append("Комплект")
	var req_gift: InventoryTypes.RelicGift = get_effective_required_gift()
	if req_gift != InventoryTypes.RelicGift.NONE:
		parts.append("Дар: %s" % InventoryTypes.get_relic_gift_display_name(req_gift))
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
		parts.append("%+.1fx Крит.ур" % bonus_crit_multiplier)
	if is_shield_item() and (shield_full_block_chance > 0.0 or shield_enhanced_block_chance > 0.0):
		parts.append("Блок 100%%: %d%%" % roundi(shield_full_block_chance * 100.0))
	elif not is_shield_item() and (not granted_skills.is_empty() or not legendary_skills.is_empty()):
		var total_sk: int = granted_skills.size() + (legendary_skills.size() if is_legendary else 0)
		parts.append("Навыков: %d" % total_sk)
	if passive_tags.has(&"IGNORES_SHIELD"):
		parts.append("Обход щита")
	if has_qte_modification():
		parts.append("QTE-мод")
	return ", ".join(parts) if not parts.is_empty() else "Без бонусов"
