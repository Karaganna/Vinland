# res://resources/gods/god_data.gd
class_name GodData
extends Resource

## Ресурс бога-покровителя: антагонист, дары покровителя ГГ, умения пути и Благословение отряда (2+ бойца)
@export var god_id: BattleTypes.GodId = BattleTypes.GodId.NONE
@export var antagonist_id: BattleTypes.GodId = BattleTypes.GodId.NONE
@export var display_name: String = ""
@export var domain_summary: String = ""
@export var patron_summary: String = ""

@export_group("Пассивные бонусы активного покровителя для ГГ")
@export var patron_hp_bonus: int = 0
@export var patron_attack_bonus: int = 0
@export var patron_magic_bonus: int = 0
@export var patron_defense_bonus: int = 0
@export var patron_speed_bonus: int = 0
@export var patron_crit_bonus: float = 0.0

@export_group("Умения пути бога по порогам склонности (15 и 30)")
@export var tier_1_skill: SkillData = null
@export var tier_2_skill: SkillData = null

@export_group("Благословение отряда (>= 2 бойцов этого бога в активном отряде)")
@export var blessing_name: String = ""
@export var blessing_description: String = ""
@export var blessing_hp_bonus: int = 0
@export var blessing_attack_bonus: int = 0
@export var blessing_magic_bonus: int = 0
@export var blessing_defense_bonus: int = 0
@export var blessing_speed_bonus: int = 0
@export var blessing_crit_bonus: float = 0.0
@export var blessing_start_barrier: int = 0
