# res://scripts/battle/enemy_part_state.gd
class_name EnemyPartState
extends RefCounted

## Runtime-состояние отдельной части тела / зоны атаки противника
var data: EnemyPartData = null
var current_hp: int = 0
var is_broken: bool = false

func _init(p_data: EnemyPartData) -> void:
	data = p_data
	if data != null:
		current_hp = maxi(1, data.max_hp)

## Проверяет, доступна ли данная часть тела для выбора целью в текущий момент боя
func is_targetable(owner_is_staggered: bool, owner_is_telegraphing: bool) -> bool:
	if data == null:
		return false
	if is_broken and not data.stay_targetable_when_broken:
		return false
	if data.vulnerability_windows.is_empty():
		return data.is_targetable_by_default
	if data.vulnerability_windows.has(BattleTypes.VulnerabilityWindow.ALWAYS):
		return true
	if owner_is_staggered and data.vulnerability_windows.has(BattleTypes.VulnerabilityWindow.ON_STAGGER):
		return true
	if owner_is_telegraphing and data.vulnerability_windows.has(BattleTypes.VulnerabilityWindow.ON_TELEGRAPH):
		return true
	return data.is_targetable_by_default

## Наносит урон по части тела и возвращает true, если этот удар сломал часть
func apply_part_damage(amount: int) -> bool:
	if data == null or is_broken or amount <= 0:
		return false
	current_hp = maxi(0, current_hp - amount)
	if current_hp == 0:
		is_broken = true
		return true
	return false
