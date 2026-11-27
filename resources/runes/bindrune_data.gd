# res://resources/runes/bindrune_data.gd
class_name BindruneData
extends Resource

## Ресурс Бандруны: пара рун (обе в активной Вязи на уровне >= 3) открывает ГГ активное рунное умение
@export var bindrune_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var rune_a: StringName = &""
@export var rune_b: StringName = &""
@export var granted_skill: SkillData = null

## Проверяет, активна ли Бандруна при текущей Вязи и уровнях рун
func is_satisfied(active_runes: Array[StringName], rune_ranks: Dictionary) -> bool:
	if rune_a == &"" or rune_b == &"":
		return false
	if not active_runes.has(rune_a) or not active_runes.has(rune_b):
		return false
	var rank_a: int = int(rune_ranks.get(rune_a, 0))
	var rank_b: int = int(rune_ranks.get(rune_b, 0))
	return rank_a >= RuneTypes.MIN_BINDRUNE_RANK and rank_b >= RuneTypes.MIN_BINDRUNE_RANK
