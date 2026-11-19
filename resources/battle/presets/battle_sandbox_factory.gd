# res://resources/battle/presets/battle_sandbox_factory.gd
class_name BattleSandboxFactory
extends RefCounted

## Программная фабрика тестовых данных (Sandbox) без ручной генерации .tres файлов

## Создает тестового Главного Героя с 3 шкалами ресурсов (+ Tension) и базовыми/QTE навыками
static func create_sandbox_hero() -> CombatantData:
	var hero: CombatantData = CombatantData.new()
	hero.combatant_id = "sandbox_hero"
	hero.display_name = "Главный герой"
	hero.is_player_controlled = true
	hero.sprite_color = Color(0.25, 0.55, 0.90, 1.0)
	
	var st: CombatStatsData = CombatStatsData.new()
	st.max_hp = 140
	st.attack = 16
	st.magic_power = 18
	st.defense = 6
	st.speed = 12
	st.crit_chance = 0.10
	st.crit_multiplier = 1.5
	hero.stats = st
	
	var active_res: Array[BattleTypes.ResourceType] = [
		BattleTypes.ResourceType.ENERGY,
		BattleTypes.ResourceType.MANA,
		BattleTypes.ResourceType.RAGE,
		BattleTypes.ResourceType.TENSION
	]
	hero.active_resources = active_res
	hero.max_energy = 100
	hero.initial_energy = 60
	hero.max_mana = 100
	hero.initial_mana = 80
	hero.max_rage = 100
	hero.initial_rage = 0
	hero.max_tension = 100
	hero.initial_tension = 0
	hero.ultimate_unlocked = true
	hero.ultimate_max_tier = BattleTypes.TensionTier.FULL_100
	hero.energy_low_threshold_ratio = 0.10
	hero.energy_low_outgoing_multiplier = 0.5
	hero.energy_low_incoming_multiplier = 1.5
	
	# 1. Обычная бесплатная атака (восстанавливает Энергию)
	var basic: SkillData = SkillData.new()
	basic.skill_id = "hero_basic_strike"
	basic.skill_name = "Быстрый удар"
	basic.description = "Бесплатная атака клинком. Восстанавливает +25 Энергии."
	basic.action_category = BattleTypes.ActionType.ATTACK
	basic.target_side = BattleTypes.TargetSide.ENEMY
	basic.resource_type = BattleTypes.ResourceType.ENERGY
	basic.resource_cost = 0
	basic.energy_restore_on_use = 25
	basic.damage_type = BattleTypes.DamageType.PHYSICAL
	basic.base_power = 8
	basic.power_multiplier = 1.0
	basic.blockability = BattleTypes.Blockability.FULL_100
	basic.requires_qte = false
	hero.basic_attack = basic
	
	# 2. Атака мечом с Undertale-style QTE (шкала точности)
	var precision_qte: QTEConfigData = QTEConfigData.new()
	precision_qte.qte_type = BattleTypes.QTEType.PRECISION_BAR
	precision_qte.duration_seconds = 2.6
	precision_qte.cursor_speed = 1.35
	precision_qte.success_zone_width = 0.24
	precision_qte.perfect_zone_width = 0.08
	
	var sword_qte: SkillData = SkillData.new()
	sword_qte.skill_id = "sword_precision_slash"
	sword_qte.skill_name = "Рассечение мечом"
	sword_qte.description = "Удар с QTE-шкалой точности (Undertale-style). Идеальное попадание наносит 1.5x урона."
	sword_qte.action_category = BattleTypes.ActionType.SKILL
	sword_qte.target_side = BattleTypes.TargetSide.ENEMY
	sword_qte.resource_type = BattleTypes.ResourceType.ENERGY
	sword_qte.resource_cost = 20
	sword_qte.damage_type = BattleTypes.DamageType.PHYSICAL
	sword_qte.base_power = 18
	sword_qte.power_multiplier = 1.15
	sword_qte.blockability = BattleTypes.Blockability.HIGH_80
	sword_qte.requires_qte = true
	sword_qte.qte_config = precision_qte
	
	# 3. Мощный удар с NO_GUARD и GUARD_BREAK
	var reckless: SkillData = SkillData.new()
	reckless.skill_id = "reckless_no_guard"
	reckless.skill_name = "Безрассудный сокрушитель"
	reckless.description = "Пробивает блок цели (GUARD_BREAK), но оставляет героя открытым (NO_GUARD: x1.75 входящего урона до конца хода)."
	reckless.action_category = BattleTypes.ActionType.SKILL
	reckless.target_side = BattleTypes.TargetSide.ENEMY
	reckless.resource_type = BattleTypes.ResourceType.ENERGY
	reckless.resource_cost = 25
	reckless.damage_type = BattleTypes.DamageType.PHYSICAL
	reckless.base_power = 26
	reckless.power_multiplier = 1.35
	reckless.blockability = BattleTypes.Blockability.FULL_100
	var reckless_tags: Array[BattleTypes.SkillTag] = [
		BattleTypes.SkillTag.NO_GUARD,
		BattleTypes.SkillTag.GUARD_BREAK
	]
	reckless.tags = reckless_tags
	reckless.guard_break_ignore_ratio = 1.0
	reckless.guard_break_bonus_multiplier = 1.30
	reckless.no_guard_incoming_multiplier = 1.75
	reckless.no_guard_guaranteed_crit = false
	
	# 4. Навык провокации (TAUNT)
	var taunt: SkillData = SkillData.new()
	taunt.skill_id = "battle_taunt"
	taunt.skill_name = "Боевой клич (Таунт)"
	taunt.description = "Принуждает врагов атаковать этого бойца на протяжении 2 ходов."
	taunt.action_category = BattleTypes.ActionType.SKILL
	taunt.target_side = BattleTypes.TargetSide.SELF
	taunt.resource_type = BattleTypes.ResourceType.ENERGY
	taunt.resource_cost = 15
	taunt.damage_type = BattleTypes.DamageType.PHYSICAL
	taunt.base_power = 0
	taunt.power_multiplier = 0.0
	var taunt_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.TAUNT]
	taunt.tags = taunt_tags
	taunt.applies_status = true
	taunt.status_to_apply = BattleTypes.StatusType.TAUNT
	taunt.status_duration_turns = 2
	
	# 5. Звуковой удар с ритм-QTE (Falling Keys)
	var rhythm_qte: QTEConfigData = QTEConfigData.new()
	rhythm_qte.qte_type = BattleTypes.QTEType.RHYTHM_TRACK
	rhythm_qte.bpm = 120.0
	rhythm_qte.note_count = 6
	var lanes: Array[int] = [0, 1, 2, 3, 1, 2]
	rhythm_qte.note_lanes = lanes
	var offsets: Array[float] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
	rhythm_qte.note_beat_offsets = offsets
	
	var sound_skill: SkillData = SkillData.new()
	sound_skill.skill_id = "resonant_sound_strike"
	sound_skill.skill_name = "Резонансная песнь"
	sound_skill.description = "Звуковая атака за Ману с ритм-QTE (падающие ноты)."
	sound_skill.action_category = BattleTypes.ActionType.SKILL
	sound_skill.target_side = BattleTypes.TargetSide.ENEMY
	sound_skill.resource_type = BattleTypes.ResourceType.MANA
	sound_skill.resource_cost = 25
	sound_skill.damage_type = BattleTypes.DamageType.SOUND
	sound_skill.base_power = 16
	sound_skill.power_multiplier = 1.2
	sound_skill.blockability = BattleTypes.Blockability.LOW_40
	var sound_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.SOUND_BASED]
	sound_skill.tags = sound_tags
	sound_skill.requires_qte = true
	sound_skill.qte_config = rhythm_qte
	
	# 6. Конвертация Ярости в самолечение
	var rage_heal: SkillData = SkillData.new()
	rage_heal.skill_id = "rage_self_heal"
	rage_heal.skill_name = "Прилив ярости"
	rage_heal.description = "Конвертирует 50% текущей Ярости в самолечение."
	rage_heal.action_category = BattleTypes.ActionType.SKILL
	rage_heal.target_side = BattleTypes.TargetSide.SELF
	rage_heal.resource_type = BattleTypes.ResourceType.RAGE
	rage_heal.resource_cost = 0
	rage_heal.base_power = 0
	rage_heal.power_multiplier = 0.0
	var heal_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.RAGE_TO_HEAL]
	rage_heal.tags = heal_tags
	rage_heal.rage_to_heal_ratio = 0.5
	rage_heal.base_heal_amount = 10
	
	var hero_skills: Array[SkillData] = [sword_qte, reckless, taunt, sound_skill, rage_heal]
	hero.skills = hero_skills
	
	# Ультимативная способность (50% / 100% Tension)
	var ult_qte: QTEConfigData = QTEConfigData.new()
	ult_qte.qte_type = BattleTypes.QTEType.PRECISION_BAR
	ult_qte.duration_seconds = 2.8
	ult_qte.cursor_speed = 1.55
	ult_qte.success_zone_width = 0.22
	ult_qte.perfect_zone_width = 0.08
	
	var ult: SkillData = SkillData.new()
	ult.skill_id = "ancient_rune_cleave"
	ult.skill_name = "Древний Рунный Разлом"
	ult.description = "Ультимативная способность (усиливается на 50% и 100% Напряжения)."
	ult.action_category = BattleTypes.ActionType.ULTIMATE
	ult.target_side = BattleTypes.TargetSide.ENEMY
	ult.resource_type = BattleTypes.ResourceType.TENSION
	ult.resource_cost = 0
	ult.damage_type = BattleTypes.DamageType.MAGICAL
	ult.base_power = 34
	ult.power_multiplier = 1.4
	ult.blockability = BattleTypes.Blockability.NONE_0
	var ult_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.UNBLOCKABLE]
	ult.tags = ult_tags
	ult.is_ultimate = true
	ult.min_tension_tier = BattleTypes.TensionTier.HALF_50
	ult.requires_qte = true
	ult.qte_config = ult_qte
	hero.ultimate_skill = ult
	
	# Заглушки экипировки и рун
	var weapon_stub: EquipmentModifierStub = EquipmentModifierStub.new()
	weapon_stub.slot_id = "weapon"
	weapon_stub.equipment_name = "Стальной клинок (заглушка)"
	weapon_stub.bonus_attack = 2
	var eq_list: Array[EquipmentModifierStub] = [weapon_stub]
	hero.equipment_modifiers = eq_list
	
	var rune_stub: RuneSlotStub = RuneSlotStub.new()
	rune_stub.rune_id = "rune_slot_1"
	rune_stub.rune_name = "Пустой слот руны"
	rune_stub.unlocked = false
	var rune_list: Array[RuneSlotStub] = [rune_stub]
	hero.rune_slots = rune_list
	
	return hero

## Создает прототип многосоставного врага «Молодой дракон»
static func create_young_dragon() -> EnemyData:
	var dragon: EnemyData = EnemyData.new()
	dragon.enemy_id = "young_dragon"
	dragon.enemy_name = "Молодой дракон"
	dragon.max_hp = 220
	dragon.current_hp = 220
	dragon.attack_power = 18
	dragon.max_resolve = 120
	dragon.current_resolve = 0
	dragon.resolve_per_vow = 40
	dragon.sprite_color = Color(0.75, 0.20, 0.16, 1.0)
	
	var st: CombatStatsData = CombatStatsData.new()
	st.max_hp = 220
	st.attack = 18
	st.magic_power = 22
	st.defense = 6
	st.speed = 11
	st.crit_chance = 0.05
	st.crit_multiplier = 1.5
	dragon.combat_stats = st
	
	var dragon_res: Array[BattleTypes.ResourceType] = [
		BattleTypes.ResourceType.ENERGY,
		BattleTypes.ResourceType.RAGE
	]
	dragon.active_resources = dragon_res
	
	# 3 зоны тела: Туловище, Лапы -> STAGGER, Шея -> окно уязвимости
	var torso: EnemyPartData = EnemyPartData.new()
	torso.part_id = "torso"
	torso.part_name = "Туловище"
	torso.max_hp = 220
	torso.armor = 8
	torso.damage_multiplier = 0.85
	torso.shared_hp_transfer_ratio = 1.0
	torso.is_targetable_by_default = true
	torso.stay_targetable_when_broken = true
	var torso_windows: Array[BattleTypes.VulnerabilityWindow] = [BattleTypes.VulnerabilityWindow.ALWAYS]
	torso.vulnerability_windows = torso_windows
	
	var legs: EnemyPartData = EnemyPartData.new()
	legs.part_id = "legs"
	legs.part_name = "Лапы"
	legs.max_hp = 70
	legs.armor = 3
	legs.damage_multiplier = 1.0
	legs.shared_hp_transfer_ratio = 0.85
	legs.triggers_stagger_on_break = true
	legs.stagger_duration_turns = 2
	legs.is_targetable_by_default = true
	legs.stay_targetable_when_broken = false
	legs.break_message = "Лапы дракона подкашиваются — он падает в ОШЕЛОМЛЕНИЕ!"
	
	var neck: EnemyPartData = EnemyPartData.new()
	neck.part_id = "neck"
	neck.part_name = "Шея"
	neck.max_hp = 90
	neck.armor = 0
	neck.damage_multiplier = 2.0
	neck.shared_hp_transfer_ratio = 1.25
	neck.is_targetable_by_default = false
	neck.stay_targetable_when_broken = true
	var neck_windows: Array[BattleTypes.VulnerabilityWindow] = [
		BattleTypes.VulnerabilityWindow.ON_STAGGER,
		BattleTypes.VulnerabilityWindow.ON_TELEGRAPH
	]
	neck.vulnerability_windows = neck_windows
	
	var dragon_parts: Array[EnemyPartData] = [torso, legs, neck]
	dragon.parts = dragon_parts
	
	# 1. Обычная атака когтями
	var claw: SkillData = SkillData.new()
	claw.skill_id = "dragon_claw"
	claw.skill_name = "Удар когтями"
	claw.action_category = BattleTypes.ActionType.ATTACK
	claw.target_side = BattleTypes.TargetSide.ENEMY
	claw.damage_type = BattleTypes.DamageType.PHYSICAL
	claw.base_power = 12
	claw.power_multiplier = 1.0
	claw.blockability = BattleTypes.Blockability.FULL_100
	dragon.basic_attack = claw
	
	# 2. GUARD_BREAK удар хвостом
	var tail_crush: SkillData = SkillData.new()
	tail_crush.skill_id = "dragon_tail_crush"
	tail_crush.skill_name = "Таран хвостом"
	tail_crush.action_category = BattleTypes.ActionType.SKILL
	tail_crush.target_side = BattleTypes.TargetSide.ENEMY
	tail_crush.damage_type = BattleTypes.DamageType.PHYSICAL
	tail_crush.base_power = 16
	tail_crush.power_multiplier = 1.15
	tail_crush.blockability = BattleTypes.Blockability.MEDIUM_60
	var tail_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.GUARD_BREAK]
	tail_crush.tags = tail_tags
	tail_crush.guard_break_ignore_ratio = 1.0
	tail_crush.guard_break_bonus_multiplier = 1.35
	
	# 3. Телеграфируемое Огненное дыхание с DbD-скиллчеком
	var breath_qte: QTEConfigData = QTEConfigData.new()
	breath_qte.qte_type = BattleTypes.QTEType.CIRCULAR_SKILL_CHECK
	breath_qte.duration_seconds = 2.4
	breath_qte.cursor_speed = 1.5
	breath_qte.success_zone_width = 0.24
	breath_qte.perfect_zone_width = 0.08
	
	var fire_breath: SkillData = SkillData.new()
	fire_breath.skill_id = "dragon_fire_breath"
	fire_breath.skill_name = "Огненное дыхание"
	fire_breath.action_category = BattleTypes.ActionType.SKILL
	fire_breath.target_side = BattleTypes.TargetSide.ENEMY
	fire_breath.damage_type = BattleTypes.DamageType.FIRE
	fire_breath.base_power = 24
	fire_breath.power_multiplier = 1.35
	fire_breath.blockability = BattleTypes.Blockability.HIGH_80
	var breath_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.TELEGRAPHED]
	fire_breath.tags = breath_tags
	fire_breath.is_telegraphed = true
	fire_breath.telegraph_turns = 1
	fire_breath.telegraph_warning_text = "Молодой дракон глубоко вдыхает! Готовится к Огненному дыханию (открылась уязвимая Шея)!"
	fire_breath.requires_qte = true
	fire_breath.qte_config = breath_qte
	
	var dragon_skills: Array[SkillData] = [tail_crush, fire_breath]
	dragon.skills = dragon_skills
	
	dragon.dialogue_intro = "Перед вами приземляется Молодой дракон! Его чешуя отливает багровым жаром."
	dragon.dialogue_on_attack = "Дракон рычит и готовит ответный выпад!"
	dragon.dialogue_on_vow = "Дракон прислушивается к голосу Завета, опустив крылья."
	dragon.dialogue_pacified = "Молодой дракон склоняет голову и улетает в горы."
	dragon.dialogue_defeat = "Молодой дракон повержен!"
	
	return dragon

## Создает стартовый отряд игрока (до 4 бойцов; сейчас 1 ГГ)
static func create_sandbox_player_party() -> Array[Combatant]:
	var party: Array[Combatant] = []
	party.append(Combatant.from_combatant_data(create_sandbox_hero(), "hero_1"))
	return party

## Создает тестовый отряд противников (сейчас 1 Молодой дракон)
static func create_sandbox_enemy_party() -> Array[Combatant]:
	var party: Array[Combatant] = []
	party.append(Combatant.from_enemy_data(create_young_dragon(), "enemy_1"))
	return party
