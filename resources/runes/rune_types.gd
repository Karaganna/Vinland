# res://resources/runes/rune_types.gd
class_name RuneTypes
extends RefCounted

## Три атта Старшего футарка (по 8 рун в каждом = 24 руны)
enum RuneAett {
	FREYR,
	HAGAL,
	TYR
}

const MAX_RUNE_RANK: int = 5
const SEAL_RANK: int = 5
const MIN_BINDRUNE_RANK: int = 3
const MIN_BIND_SLOTS: int = 2
const MAX_BIND_SLOTS: int = 6

## Возвращает локализованное название атта Старшего футарка
static func get_aett_display_name(aett: RuneAett) -> String:
	match aett:
		RuneAett.FREYR:
			return "Атт Фрейра"
		RuneAett.HAGAL:
			return "Атт Хагаля"
		RuneAett.TYR:
			return "Атт Тюра"
	return "Атт"

## Возвращает короткое название атта для компактных списков 640x360
static func get_aett_short_name(aett: RuneAett) -> String:
	match aett:
		RuneAett.FREYR:
			return "Фрейр"
		RuneAett.HAGAL:
			return "Хагаль"
		RuneAett.TYR:
			return "Тюр"
	return "Атт"
