# res://scripts/battle/resource_pool.gd
class_name ResourcePool
extends RefCounted

## Сигналы изменения ресурсов и достижения порогов Напряжения
signal resource_changed(resource_type: BattleTypes.ResourceType, current_value: int, max_value: int)
signal tension_tier_reached(tier: BattleTypes.TensionTier)

## Настраиваемые параметры порогов Энергии
var energy_high_threshold_ratio: float = 0.70
var energy_high_outgoing_multiplier: float = 1.5
var energy_low_threshold_ratio: float = 0.10
var energy_low_outgoing_multiplier: float = 0.5
var energy_low_incoming_multiplier: float = 1.0

## Настраиваемые параметры Ярости
var rage_attack_scale: float = 0.50
var rage_speed_scale: int = 8
var rage_gain_on_deal_damage: int = 12
var rage_gain_on_take_damage: int = 18
var rage_decay_on_idle_or_block: int = 15
var rage_decay_on_external_heal: int = 20
var rage_decay_on_control_status: int = 25

## Настройки Ультимативной шкалы Напряжения (TENSION)
var ultimate_unlocked: bool = true
var ultimate_max_tier: BattleTypes.TensionTier = BattleTypes.TensionTier.FULL_100

var _active_flags: Dictionary = {}
var _current_values: Dictionary = {}
var _max_values: Dictionary = {}

func _init() -> void:
	for res_type: BattleTypes.ResourceType in [
		BattleTypes.ResourceType.ENERGY,
		BattleTypes.ResourceType.MANA,
		BattleTypes.ResourceType.RAGE,
		BattleTypes.ResourceType.TENSION
	]:
		_active_flags[res_type] = false
		_current_values[res_type] = 0
		_max_values[res_type] = 100

## Настраивает активную шкалу ресурса с начальным и максимальным значением
func configure_resource(res_type: BattleTypes.ResourceType, max_val: int, initial_val: int, is_active: bool = true) -> void:
	var clamped_max: int = maxi(1, max_val)
	_active_flags[res_type] = is_active
	_max_values[res_type] = clamped_max
	_current_values[res_type] = clampi(initial_val, 0, clamped_max)
	if is_active:
		resource_changed.emit(res_type, get_current(res_type), clamped_max)

## Проверяет, активна ли указанная шкала у данного бойца
func has_resource(res_type: BattleTypes.ResourceType) -> bool:
	return bool(_active_flags.get(res_type, false))

## Возвращает текущее значение ресурса
func get_current(res_type: BattleTypes.ResourceType) -> int:
	return int(_current_values.get(res_type, 0))

## Возвращает максимальное значение ресурса
func get_max(res_type: BattleTypes.ResourceType) -> int:
	return maxi(1, int(_max_values.get(res_type, 100)))

## Возвращает заполненность шкалы ресурса в диапазоне [0.0 .. 1.0]
func get_ratio(res_type: BattleTypes.ResourceType) -> float:
	if not has_resource(res_type):
		return 0.0
	return clampf(float(get_current(res_type)) / float(get_max(res_type)), 0.0, 1.0)

## Возвращает список всех активных ресурсов бойца
func get_active_resource_types() -> Array[BattleTypes.ResourceType]:
	var list: Array[BattleTypes.ResourceType] = []
	for res_type: BattleTypes.ResourceType in [
		BattleTypes.ResourceType.ENERGY,
		BattleTypes.ResourceType.MANA,
		BattleTypes.ResourceType.RAGE,
		BattleTypes.ResourceType.TENSION
	]:
		if has_resource(res_type):
			list.append(res_type)
	return list

## Проверяет достаточность ресурса для оплаты стоимости
func can_afford(res_type: BattleTypes.ResourceType, cost: int) -> bool:
	if cost <= 0:
		return true
	if not has_resource(res_type):
		return false
	return get_current(res_type) >= cost

## Тратит указанное количество ресурса, возвращая true при успехе
func spend_resource(res_type: BattleTypes.ResourceType, amount: int) -> bool:
	if amount <= 0:
		return true
	if not can_afford(res_type, amount):
		return false
	var next_val: int = clampi(get_current(res_type) - amount, 0, get_max(res_type))
	_current_values[res_type] = next_val
	resource_changed.emit(res_type, next_val, get_max(res_type))
	return true

## Универсальный метод восполнения ресурса (включая Ману через предметы/отдых/саппортов)
func restore_resource(res_type: BattleTypes.ResourceType, amount: int) -> int:
	if amount <= 0 or not has_resource(res_type):
		return 0
	var prev_val: int = get_current(res_type)
	var max_val: int = get_max(res_type)
	var next_val: int = clampi(prev_val + amount, 0, max_val)
	var gained: int = next_val - prev_val
	_current_values[res_type] = next_val
	if gained > 0:
		resource_changed.emit(res_type, next_val, max_val)
		if res_type == BattleTypes.ResourceType.TENSION:
			_check_tension_tier_crossing(prev_val, next_val, max_val)
	return gained

## Возвращает множитель исходящего урона от порогов Энергии (70-100% -> x1.5; <=10% -> штраф)
func get_energy_outgoing_multiplier() -> float:
	if not has_resource(BattleTypes.ResourceType.ENERGY):
		return 1.0
	var ratio: float = get_ratio(BattleTypes.ResourceType.ENERGY)
	if ratio >= energy_high_threshold_ratio:
		return energy_high_outgoing_multiplier
	if ratio <= energy_low_threshold_ratio:
		return energy_low_outgoing_multiplier
	return 1.0

## Возвращает множитель входящего урона при истощении Энергии
func get_energy_incoming_multiplier() -> float:
	if not has_resource(BattleTypes.ResourceType.ENERGY):
		return 1.0
	var ratio: float = get_ratio(BattleTypes.ResourceType.ENERGY)
	if ratio <= energy_low_threshold_ratio:
		return energy_low_incoming_multiplier
	return 1.0

## Возвращает множитель силы атаки от накопленной Ярости
func get_rage_attack_multiplier() -> float:
	if not has_resource(BattleTypes.ResourceType.RAGE):
		return 1.0
	return 1.0 + (get_ratio(BattleTypes.ResourceType.RAGE) * rage_attack_scale)

## Возвращает прибавку к скорости от накопленной Ярости
func get_rage_speed_bonus() -> int:
	if not has_resource(BattleTypes.ResourceType.RAGE):
		return 0
	return roundi(get_ratio(BattleTypes.ResourceType.RAGE) * float(rage_speed_scale))

## Накопление Ярости при нанесении урона
func add_rage_on_damage_dealt(custom_amount: int = -1) -> int:
	var amount: int = custom_amount if custom_amount >= 0 else rage_gain_on_deal_damage
	return restore_resource(BattleTypes.ResourceType.RAGE, amount)

## Накопление Ярости при получении урона
func add_rage_on_damage_taken(custom_amount: int = -1) -> int:
	var amount: int = custom_amount if custom_amount >= 0 else rage_gain_on_take_damage
	return restore_resource(BattleTypes.ResourceType.RAGE, amount)

## Спад Ярости (возвращает фактически потерянное количество)
func decay_rage(amount: int) -> int:
	if amount <= 0 or not has_resource(BattleTypes.ResourceType.RAGE):
		return 0
	var prev_val: int = get_current(BattleTypes.ResourceType.RAGE)
	if prev_val <= 0:
		return 0
	var next_val: int = maxi(0, prev_val - amount)
	var lost: int = prev_val - next_val
	_current_values[BattleTypes.ResourceType.RAGE] = next_val
	if lost > 0:
		resource_changed.emit(BattleTypes.ResourceType.RAGE, next_val, get_max(BattleTypes.ResourceType.RAGE))
	return lost

## Спад Ярости при бездействии, пропуске или блоке
func decay_rage_on_idle_or_block() -> int:
	return decay_rage(rage_decay_on_idle_or_block)

## Спад Ярости при получении внешнего лечения
func decay_rage_on_external_heal() -> int:
	return decay_rage(rage_decay_on_external_heal)

## Спад Ярости от статуса контроля (сон, гипноз, успокоение)
func decay_rage_on_control_status() -> int:
	return decay_rage(rage_decay_on_control_status)

## Конвертирует часть Ярости в самолечение и возвращает словарь {rage_spent, heal_amount}
func convert_rage_to_heal(convert_ratio: float, heal_per_rage_point: float = 0.6) -> Dictionary:
	if not has_resource(BattleTypes.ResourceType.RAGE):
		return {"rage_spent": 0, "heal_amount": 0}
	var current_rage: int = get_current(BattleTypes.ResourceType.RAGE)
	if current_rage <= 0 or convert_ratio <= 0.0:
		return {"rage_spent": 0, "heal_amount": 0}
	var to_spend: int = clampi(roundi(float(current_rage) * clampf(convert_ratio, 0.0, 1.0)), 1, current_rage)
	if not spend_resource(BattleTypes.ResourceType.RAGE, to_spend):
		return {"rage_spent": 0, "heal_amount": 0}
	var heal_val: int = maxi(1, roundi(float(to_spend) * heal_per_rage_point))
	return {"rage_spent": to_spend, "heal_amount": heal_val}

## Возвращает доступный уровень Ультимативной способности по шкале Напряжения (50% / 100%)
func get_available_tension_tier() -> BattleTypes.TensionTier:
	if not ultimate_unlocked or not has_resource(BattleTypes.ResourceType.TENSION):
		return BattleTypes.TensionTier.LOCKED
	var pct: float = get_ratio(BattleTypes.ResourceType.TENSION) * 100.0
	if ultimate_max_tier == BattleTypes.TensionTier.FULL_100 and pct >= 99.9:
		return BattleTypes.TensionTier.FULL_100
	if pct >= 50.0:
		return BattleTypes.TensionTier.HALF_50
	return BattleTypes.TensionTier.LOCKED

## Проверяет готовность ультимативной способности с требуемым минимальным порогом
func can_use_ultimate(min_tier: BattleTypes.TensionTier = BattleTypes.TensionTier.HALF_50) -> bool:
	if not ultimate_unlocked or not has_resource(BattleTypes.ResourceType.TENSION):
		return false
	var current_tier: BattleTypes.TensionTier = get_available_tension_tier()
	return int(current_tier) >= int(min_tier) and current_tier != BattleTypes.TensionTier.LOCKED

## Тратит Напряжение при активации Ульты и возвращает достигнутый уровень силы (50% или 100%)
func consume_tension_for_ultimate() -> BattleTypes.TensionTier:
	var tier: BattleTypes.TensionTier = get_available_tension_tier()
	if tier == BattleTypes.TensionTier.LOCKED:
		return BattleTypes.TensionTier.LOCKED
	var max_val: int = get_max(BattleTypes.ResourceType.TENSION)
	var cost: int = max_val if tier == BattleTypes.TensionTier.FULL_100 else roundi(float(max_val) * 0.5)
	spend_resource(BattleTypes.ResourceType.TENSION, mini(cost, get_current(BattleTypes.ResourceType.TENSION)))
	return tier

func _check_tension_tier_crossing(prev_val: int, next_val: int, max_val: int) -> void:
	var prev_pct: float = (float(prev_val) / float(max_val)) * 100.0
	var next_pct: float = (float(next_val) / float(max_val)) * 100.0
	if prev_pct < 50.0 and next_pct >= 50.0:
		tension_tier_reached.emit(BattleTypes.TensionTier.HALF_50)
	if prev_pct < 99.9 and next_pct >= 99.9 and ultimate_max_tier == BattleTypes.TensionTier.FULL_100:
		tension_tier_reached.emit(BattleTypes.TensionTier.FULL_100)
