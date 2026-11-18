# res://resources/attack_data.gd
class_name AttackData
extends Resource

## Категории атак (для будущих уязвимостей и сопротивлений противников)
enum AttackCategory {
	SLASH,       ## Рубящая атака
	PIERCE,      ## Колющая атака
	BLUNT,       ## Дробящая атака
	RUNIC_FIRE,  ## Рунное пламя
	RUNIC_FROST, ## Рунный мороз
	RUNIC_STORM  ## Рунная буря
}

## Режим QTE (используется только для особых атак; базовые атаки проходят без QTE)
enum QTEMode {
	NONE,
	RUNE_WHEEL,
	KEY_SEQUENCE
}

## Максимальное количество рун, которое можно активировать за одну атаку
const MAX_RUNES_PER_ATTACK: int = 3
## Общее количество рун на колесе (пронумерованы от 1 до 10)
const TOTAL_WHEEL_RUNES: int = 10

@export var attack_id: String = "northern_slash"
@export var attack_name: String = "Рубящий удар"
@export var category: AttackCategory = AttackCategory.SLASH
@export var base_damage: int = 20
@export var is_special_attack: bool = false
@export var qte_mode: QTEMode = QTEMode.NONE

## Приоритетные номера рун (от 1 до 10) для данной атаки
@export var priority_runes: Array[int] = [1, 4, 8]

## Задел под будущие зависимости и комбинации между рунами (например "1+4": 1.25)
@export var rune_synergy_rules: Dictionary = {}

@export_multiline var description: String = "Обычная атака без QTE."

## Создает набор базовых атак героя (без QTE)
static func create_default_player_attacks() -> Array[AttackData]:
	var attacks: Array[AttackData] = []
	
	var slash: AttackData = AttackData.new()
	slash.attack_id = "northern_slash"
	slash.attack_name = "Рубящий удар"
	slash.category = AttackCategory.SLASH
	slash.base_damage = 20
	slash.is_special_attack = false
	slash.qte_mode = QTEMode.NONE
	slash.priority_runes = [1, 4, 8]
	slash.description = "Обычный широкий рубящий взмах без QTE."
	attacks.append(slash)
	
	var pierce: AttackData = AttackData.new()
	pierce.attack_id = "spear_thrust"
	pierce.attack_name = "Колющий выпад"
	pierce.category = AttackCategory.PIERCE
	pierce.base_damage = 18
	pierce.is_special_attack = false
	pierce.qte_mode = QTEMode.NONE
	pierce.priority_runes = [2, 5, 9]
	pierce.description = "Обычный точный пробивающий удар без QTE."
	attacks.append(pierce)
	
	var runic: AttackData = AttackData.new()
	runic.attack_id = "runic_wrath"
	runic.attack_name = "Рунный всполох"
	runic.category = AttackCategory.RUNIC_FIRE
	runic.base_damage = 22
	runic.is_special_attack = false
	runic.qte_mode = QTEMode.NONE
	runic.priority_runes = [3, 6, 10]
	runic.description = "Обычный удар клинком с руническим следом без QTE."
	attacks.append(runic)
	
	return attacks

## Проверяет, является ли руна (1..10) приоритетной для этой атаки
func is_priority_rune(rune_number: int) -> bool:
	return priority_runes.has(rune_number)

## Форматирует список приоритетных рун для отображения в UI
func get_priority_runes_text() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for r: int in priority_runes:
		parts.append("#" + str(r))
	return ", ".join(parts)

## Вычисляет итоговый множитель и оценку атаки по выбранным рунам (не более 3)
## В будущем здесь будут учитываться цепочки зависимостей из rune_synergy_rules
func evaluate_selected_runes(selected_runes: Array[int]) -> Dictionary:
	var priority_hits: int = 0
	var normal_hits: int = 0
	var unique_runes: Array[int] = []
	
	for rune_num: int in selected_runes:
		if rune_num < 1 or rune_num > TOTAL_WHEEL_RUNES:
			continue
		if not unique_runes.has(rune_num):
			unique_runes.append(rune_num)
		if is_priority_rune(rune_num):
			priority_hits += 1
		else:
			normal_hits += 1
	
	var total_hits: int = priority_hits + normal_hits
	var multiplier: float = 0.0
	var grade_text: String = "ПРОМАХ!"
	
	if total_hits == 0:
		multiplier = 0.0
		grade_text = "ПРОМАХ (0 рун)"
	else:
		# Каждая приоритетная руна дает +0.45 к множителю, обычная руна дает +0.20
		multiplier = float(priority_hits) * 0.45 + float(normal_hits) * 0.20
		# Бонус за все 3 приоритетные руны
		if priority_hits >= MAX_RUNES_PER_ATTACK:
			multiplier = 1.5
			grade_text = "★ ИДЕАЛЬНЫЙ РУННЫЙ РЕЗОНАНС (3/3) ★"
		elif priority_hits == 2 and total_hits == 3:
			grade_text = "СИЛЬНЫЙ РЕЗОНАНС (2 приор. + 1 обычн.)"
		elif priority_hits == 2:
			grade_text = "ДВОЙНОЙ РЕЗОНАНС (2 приор. руны)"
		elif priority_hits == 1:
			grade_text = "ЧАСТИЧНЫЙ РЕЗОНАНС (1 приор. руна)"
		else:
			grade_text = "СЛАБЫЙ ОТКЛИК (без приоритетных рун)"
	
	var synergy_bonus: float = _evaluate_future_synergies(unique_runes)
	multiplier += synergy_bonus
	
	return {
		"priority_hits": priority_hits,
		"normal_hits": normal_hits,
		"total_hits": total_hits,
		"damage_multiplier": snappedf(multiplier, 0.05),
		"grade_text": grade_text
	}

## Заглушка под будущие зависимости между конкретными номерами рун
func _evaluate_future_synergies(_unique_runes: Array[int]) -> float:
	return 0.0

