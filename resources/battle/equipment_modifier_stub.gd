# res://resources/battle/equipment_modifier_stub.gd
class_name EquipmentModifierStub
extends Resource

## Заглушка модификаторов экипировки (оружия, брони, аксессуаров)
@export var slot_id: String = "weapon"
@export var equipment_name: String = "Базовое снаряжение"

@export_group("Бонусы к характеристикам")
@export var bonus_attack: int = 0
@export var bonus_defense: int = 0
@export var bonus_speed: int = 0
@export var bonus_max_hp: int = 0

@export_group("Переопределение порогов QTE")
@export var override_qte_thresholds: bool = false
@export_range(0.0, 1.0, 0.01) var qte_miss_threshold: float = 0.30
@export_range(0.0, 1.0, 0.01) var qte_weak_threshold: float = 0.60
@export_range(0.0, 1.0, 0.01) var qte_perfect_threshold: float = 0.90
