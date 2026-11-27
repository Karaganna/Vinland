# res://resources/runes/rune_data.gd
class_name RuneData
extends Resource

## Ресурс одной из 24 рун Старшего футарка (ступени 1..4 — пассивки, ступень 5 — Печать, плюс Резонанс рекрутов)
@export var rune_id: StringName = &""
@export var order_index: int = 1
@export var symbol: String = "ᚠ"
@export var display_name: String = "Феху"
@export var meaning_short: String = "Движимая сила"
@export var aett: RuneTypes.RuneAett = RuneTypes.RuneAett.FREYR
@export_range(1, 6, 1) var unlock_episode: int = 1

@export_group("Пассивные прибавки на ступенях 1..4 (кумулятивно по рангу)")
@export var hp_per_rank: Array[int] = [0, 0, 0, 0]
@export var attack_per_rank: Array[int] = [0, 0, 0, 0]
@export var magic_per_rank: Array[int] = [0, 0, 0, 0]
@export var defense_per_rank: Array[int] = [0, 0, 0, 0]
@export var speed_per_rank: Array[int] = [0, 0, 0, 0]
@export var crit_chance_per_rank: Array[float] = [0.0, 0.0, 0.0, 0.0]
@export var crit_mult_per_rank: Array[float] = [0.0, 0.0, 0.0, 0.0]
@export var passive_summary: String = ""

@export_group("5-я ступень — Печать (Seal)")
@export var seal_id: StringName = &""
@export var seal_name: String = ""
@export_multiline var seal_description: String = ""

@export_group("Резонанс родовой руны рекрута")
@export var resonance_description: String = ""
@export var resonance_hp: int = 10
@export var resonance_attack: int = 2
@export var resonance_magic: int = 0
@export var resonance_defense: int = 1
@export var resonance_speed: int = 1
@export var resonance_crit: float = 0.03

## Возвращает суммарные числовые бонусы руны на указанном уровне (0..5), когда руна стоит в активной Вязи
func get_bonuses_for_rank(rank: int) -> Dictionary:
	var clamped_rank: int = clampi(rank, 0, RuneTypes.MAX_RUNE_RANK)
	if clamped_rank <= 0:
		return {
			"max_hp": 0,
			"attack": 0,
			"magic_power": 0,
			"defense": 0,
			"speed": 0,
			"crit_chance": 0.0,
			"crit_multiplier": 0.0,
			"has_seal": false
		}
	var idx: int = mini(clamped_rank, 4) - 1
	return {
		"max_hp": hp_per_rank[idx] if idx >= 0 and idx < hp_per_rank.size() else 0,
		"attack": attack_per_rank[idx] if idx >= 0 and idx < attack_per_rank.size() else 0,
		"magic_power": magic_per_rank[idx] if idx >= 0 and idx < magic_per_rank.size() else 0,
		"defense": defense_per_rank[idx] if idx >= 0 and idx < defense_per_rank.size() else 0,
		"speed": speed_per_rank[idx] if idx >= 0 and idx < speed_per_rank.size() else 0,
		"crit_chance": crit_chance_per_rank[idx] if idx >= 0 and idx < crit_chance_per_rank.size() else 0.0,
		"crit_multiplier": crit_mult_per_rank[idx] if idx >= 0 and idx < crit_mult_per_rank.size() else 0.0,
		"has_seal": clamped_rank >= RuneTypes.SEAL_RANK
	}

## Возвращает заголовок руны вида «ᚠ Феху»
func get_titled_name() -> String:
	return "%s %s" % [symbol, display_name]
