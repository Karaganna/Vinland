# res://resources/battle/combatant_data.gd
class_name CombatantData
extends Resource

## Шаблон бойца отряда игрока (ГГ со шкалой «Поток» и рекруты со строго одним баком)
@export var combatant_id: String = "hero"
@export var display_name: String = "Герой"
@export var is_player_controlled: bool = true
@export var is_hero: bool = false
## Викинги не могут владеть баком MANA (проверяется при инициализации)
@export var is_viking: bool = true
@export var sprite_color: Color = Color(0.85, 0.25, 0.25, 1.0)
@export var stats: CombatStatsData = null

@export_group("Ресурсный бак и Поток ГГ")
## Единственный основной бак рекрута (ENERGY, MANA, RAGE или HAMINGJA)
@export var primary_resource: BattleTypes.ResourceType = BattleTypes.ResourceType.ENERGY
## Режим Потока ГГ по умолчанию, если в руках нет фирменного оружия
@export var default_flow_mode: BattleTypes.ResourceType = BattleTypes.ResourceType.ENERGY
## Legacy-список ресурсов (для обратной совместимости старых пресетов)
@export var active_resources: Array[BattleTypes.ResourceType] = []
@export var max_energy: int = 100
@export var initial_energy: int = 60
@export var max_mana: int = 100
@export var initial_mana: int = 100
@export var max_rage: int = 100
@export var initial_rage: int = 0
@export var max_hamingja: int = 100
@export var initial_hamingja: int = 50
@export var max_tension: int = 100
@export var initial_tension: int = 0
@export var ultimate_unlocked: bool = true
@export var ultimate_max_tier: BattleTypes.TensionTier = BattleTypes.TensionTier.FULL_100

@export_group("Пороги и штрафы Энергии")
## По умолчанию выключен во избежание спирали поражения; бонус x1.5 при 70-100% всегда активен
@export var enable_low_energy_penalty: bool = false
@export_range(0.0, 0.5, 0.01) var energy_low_threshold_ratio: float = 0.10
@export_range(0.1, 1.0, 0.05) var energy_low_outgoing_multiplier: float = 0.5
@export_range(1.0, 3.0, 0.05) var energy_low_incoming_multiplier: float = 1.5

@export_group("Навыки и прогрессия")
@export var basic_attack: SkillData = null
@export var skills: Array[SkillData] = []
@export var ultimate_skill: SkillData = null
@export var equipment_loadout: EquipmentLoadout = null
@export var equipment_modifiers: Array[EquipmentModifierStub] = []
@export var item_slots: Array[ItemSlotStub] = []
@export var rune_slots: Array[RuneSlotStub] = []

## Возвращает проверенный основной бак рекрута (строго 1 из 4; викинги не могут иметь MANA)
func get_validated_primary_resource() -> BattleTypes.ResourceType:
	var candidate: BattleTypes.ResourceType = primary_resource
	if candidate == BattleTypes.ResourceType.TENSION:
		candidate = BattleTypes.ResourceType.ENERGY
	if not is_hero and is_viking and candidate == BattleTypes.ResourceType.MANA:
		push_warning("CombatantData (%s): викинг не может иметь бак MANA — заменено на ENERGY." % combatant_id)
		return BattleTypes.ResourceType.ENERGY
	return candidate
