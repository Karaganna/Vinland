# res://resources/battle/combat_stats_data.gd
class_name CombatStatsData
extends Resource

## Заглушка базовых характеристик бойца (для последующего подключения системы атрибутов)
@export var max_hp: int = 100
@export var attack: int = 15
@export var magic_power: int = 12
@export var defense: int = 5
@export var speed: int = 10
@export_range(0.0, 1.0, 0.01) var crit_chance: float = 0.05
@export var crit_multiplier: float = 1.5

## Создает изолированную копию статов для runtime-обертки бойца
func create_copy() -> CombatStatsData:
	var copy: CombatStatsData = CombatStatsData.new()
	copy.max_hp = max_hp
	copy.attack = attack
	copy.magic_power = magic_power
	copy.defense = defense
	copy.speed = speed
	copy.crit_chance = crit_chance
	copy.crit_multiplier = crit_multiplier
	return copy
