# res://resources/battle/combatant_data.gd
class_name CombatantData
extends Resource

## Шаблон бойца отряда игрока (ГГ и будущих спутников до 4 бойцов)
@export var combatant_id: String = "hero"
@export var display_name: String = "Герой"
@export var is_player_controlled: bool = true
@export var sprite_color: Color = Color(0.85, 0.25, 0.25, 1.0)
@export var stats: CombatStatsData = null

@export_group("Шкалы ресурсов")
@export var active_resources: Array[BattleTypes.ResourceType] = []
@export var max_energy: int = 100
@export var initial_energy: int = 50
@export var max_mana: int = 100
@export var initial_mana: int = 100
@export var max_rage: int = 100
@export var initial_rage: int = 0
@export var max_tension: int = 100
@export var initial_tension: int = 0
@export var ultimate_unlocked: bool = true
@export var ultimate_max_tier: BattleTypes.TensionTier = BattleTypes.TensionTier.FULL_100

@export_group("Штрафы низкой энергии")
@export_range(0.0, 0.5, 0.01) var energy_low_threshold_ratio: float = 0.10
@export_range(0.1, 1.0, 0.05) var energy_low_outgoing_multiplier: float = 0.5
@export_range(1.0, 3.0, 0.05) var energy_low_incoming_multiplier: float = 1.0

@export_group("Навыки и заглушки прогрессии")
@export var basic_attack: SkillData = null
@export var skills: Array[SkillData] = []
@export var ultimate_skill: SkillData = null
@export var equipment_modifiers: Array[EquipmentModifierStub] = []
@export var item_slots: Array[ItemSlotStub] = []
@export var rune_slots: Array[RuneSlotStub] = []
