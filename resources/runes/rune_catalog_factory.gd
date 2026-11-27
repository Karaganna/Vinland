# res://resources/runes/rune_catalog_factory.gd
class_name RuneCatalogFactory
extends RefCounted

## Программная фабрика всех 24 рун Старшего футарка, 10 Бандрун и 6 Великих вязей (без ручных .tres)

static func create_all_runes() -> Array[RuneData]:
	var list: Array[RuneData] = []
	
	# =========================================================================
	# I. АТТ ФРЕЙРА (руны 1..8)
	# =========================================================================
	list.append(_make_rune(
		&"fehu", 1, "ᚠ", "Феху", "Движимое пламя", RuneTypes.RuneAett.FREYR, 1,
		[4, 8, 12, 16], [1, 2, 3, 4], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0],
		"+HP и +АТК по ступеням",
		&"seal_fehu", "Печать Первичного Пламени", "На старте боя +15 Напряжения; базовая атака даёт +6 Потока.",
		"+10 HP, +3 АТК", 10, 3, 0, 0, 0, 0.0
	))
	list.append(_make_rune(
		&"uruz", 2, "ᚢ", "Уруз", "Мощь дикого тура", RuneTypes.RuneAett.FREYR, 1,
		[6, 12, 18, 25], [0, 1, 2, 3], [0, 0, 0, 0], [1, 2, 3, 5], [0, 0, 0, 0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0],
		"+HP, +ЗАЩ и мощь удара",
		&"seal_uruz", "Печать Дикого Тура", "+10% ко всему исходящему физическому урону ГГ.",
		"+16 HP, +2 ЗАЩ, +2 АТК", 16, 2, 0, 2, 0, 0.0
	))
	list.append(_make_rune(
		&"thurisaz", 3, "ᚦ", "Турисаз", "Шип великана", RuneTypes.RuneAett.FREYR, 1,
		[0, 4, 8, 12], [2, 3, 5, 7], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.05, 0.10],
		"+АТК и пробивная мощь",
		&"seal_thurisaz", "Печать Шипа Великана", "Удары ГГ игнорируют 15% защиты цели.",
		"+4 АТК, +8 HP", 8, 4, 0, 0, 0, 0.02
	))
	list.append(_make_rune(
		&"ansuz", 4, "ᚨ", "Ансуз", "Дыхание и слово асов", RuneTypes.RuneAett.FREYR, 1,
		[0, 0, 5, 10], [0, 0, 0, 0], [2, 4, 6, 8], [0, 0, 0, 0], [0, 0, 1, 1], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0],
		"+МАГ и владение словом",
		&"seal_ansuz", "Печать Вещего Слова", "Снижает стоимость умений ГГ по ресурсу на 15%.",
		"+4 МАГ, +1 СКР", 6, 0, 4, 0, 1, 0.0
	))
	list.append(_make_rune(
		&"raidho", 5, "ᚱ", "Райдо", "Путь и колесница", RuneTypes.RuneAett.FREYR, 2,
		[0, 0, 6, 12], [0, 0, 1, 2], [0, 0, 0, 0], [0, 0, 0, 0], [1, 2, 3, 5], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0],
		"+СКР и темп хода",
		&"seal_raidho", "Печать Верного Пути", "Иммунитет к Замедлению (SLOW) и +12 к стартовому Потоку.",
		"+2 СКР, +2 АТК", 6, 2, 0, 0, 2, 0.0
	))
	list.append(_make_rune(
		&"kenaz", 6, "ᚲ", "Кеназ", "Факел знания и огня", RuneTypes.RuneAett.FREYR, 1,
		[0, 0, 0, 0], [0, 1, 2, 3], [1, 2, 3, 5], [0, 0, 0, 0], [0, 0, 0, 0], [0.02, 0.04, 0.06, 0.08], [0.0, 0.0, 0.0, 0.0],
		"+Крит и +МАГ",
		&"seal_kenaz", "Печать Негасимого Факела", "Критические удары ГГ поджигают врага (Ожог на 2 хода).",
		"+4% Крит, +3 МАГ", 6, 1, 3, 0, 0, 0.04
	))
	list.append(_make_rune(
		&"gebo", 7, "ᚷ", "Гебо", "Клятвенный дар", RuneTypes.RuneAett.FREYR, 2,
		[4, 8, 12, 16], [0, 0, 0, 0], [0, 1, 2, 3], [1, 2, 3, 4], [0, 0, 0, 0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0],
		"+HP, +ЗАЩ и союзный обмен",
		&"seal_gebo", "Печать Клятвенного Дара", "Поддержка и стойки ГГ дополнительно накладывают на отряд Барьер (+12).",
		"+10 HP, +2 ЗАЩ", 10, 0, 2, 2, 0, 0.0
	))
	list.append(_make_rune(
		&"wunjo", 8, "ᚹ", "Вуньо", "Боевая радость и слава", RuneTypes.RuneAett.FREYR, 2,
		[4, 8, 10, 14], [0, 0, 1, 2], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0.01, 0.02, 0.03, 0.04], [0.05, 0.10, 0.15, 0.22],
		"+Крит.урон и +HP",
		&"seal_wunjo", "Печать Славы Отряда", "Идеальное QTE ГГ воодушевляет живых союзников (+8 Напряжения).",
		"+4% Крит, +8 HP", 8, 2, 0, 0, 1, 0.04
	))
	
	# =========================================================================
	# II. АТТ ХАГАЛЯ (руны 9..16)
	# =========================================================================
	list.append(_make_rune(
		&"hagalaz", 9, "ᚺ", "Хагалаз", "Разрушительный град", RuneTypes.RuneAett.HAGAL, 1,
		[0, 0, 0, 0], [1, 2, 3, 4], [2, 4, 6, 8], [0, 0, 0, 0], [0, 0, 0, 0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0],
		"+МАГ и +АТК бури",
		&"seal_hagalaz", "Печать Ледяного Града", "+15% урона по ошеломлённым, замороженным или потерявшим равновесие целям.",
		"+3 АТК, +3 МАГ", 6, 3, 3, 0, 0, 0.0
	))
	list.append(_make_rune(
		&"naudhiz", 10, "ᚾ", "Наутиз", "Железная нужда", RuneTypes.RuneAett.HAGAL, 2,
		[4, 8, 14, 20], [0, 0, 0, 0], [0, 0, 0, 0], [2, 3, 5, 7], [0, 0, 0, 0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0],
		"+ЗАЩ и +HP выдержки",
		&"seal_naudhiz", "Печать Железной Нужды", "При HP < 50% ГГ получает -20% вх. урона и +15% исх. урона.",
		"+12 HP, +3 ЗАЩ", 12, 1, 0, 3, 0, 0.0
	))
	list.append(_make_rune(
		&"isa", 11, "ᛁ", "Иса", "Первозданный лёд", RuneTypes.RuneAett.HAGAL, 1,
		[4, 8, 12, 16], [0, 0, 0, 0], [0, 1, 2, 3], [2, 4, 6, 8], [0, 0, 0, 0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0],
		"+ЗАЩ и ледяная стойкость",
		&"seal_isa", "Печать Вечного Льда", "В стойке Блок даёт +15% к блоку и укрывает ГГ Барьером (+14).",
		"+3 ЗАЩ, +10 HP", 10, 0, 2, 3, 0, 0.0
	))
	list.append(_make_rune(
		&"jera", 12, "ᛃ", "Йера", "Коловорот жатвы", RuneTypes.RuneAett.HAGAL, 2,
		[5, 10, 16, 22], [0, 0, 0, 0], [0, 0, 1, 2], [0, 0, 0, 0], [0, 1, 2, 3], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0],
		"+HP и +СКР цикла",
		&"seal_jera", "Печать Щедрой Жатвы", "В конце каждого раунда ГГ восстанавливает +8% HP и +8 Потока.",
		"+12 HP, +1 СКР", 12, 1, 1, 1, 1, 0.0
	))
	list.append(_make_rune(
		&"eihwaz", 13, "ᛇ", "Эйваз", "Мировой тис", RuneTypes.RuneAett.HAGAL, 1,
		[5, 10, 15, 22], [0, 1, 2, 3], [0, 0, 0, 0], [0, 1, 1, 2], [0, 0, 0, 0], [0.02, 0.03, 0.05, 0.07], [0.0, 0.0, 0.0, 0.0],
		"+HP и +Крит меткости тиса",
		&"seal_eihwaz", "Печать Мирового Тиса", "Один раз за бой смертельный удар оставляет ГГ в живых с 1 HP.",
		"+10 HP, +3 АТК, +5% Крит", 10, 3, 0, 1, 1, 0.05
	))
	list.append(_make_rune(
		&"perthro", 14, "ᛈ", "Пертро", "Кубок жребия", RuneTypes.RuneAett.HAGAL, 3,
		[0, 0, 4, 8], [0, 0, 0, 0], [0, 1, 2, 3], [0, 0, 0, 0], [0, 0, 0, 0], [0.03, 0.05, 0.08, 0.11], [0.0, 0.05, 0.10, 0.15],
		"+Крит и удача жребия",
		&"seal_perthro", "Печать Кубка Судеб", "Расширяет идеальное окно QTE ГГ (-6% к порогу идеального попадания).",
		"+5% Крит, +2 МАГ", 6, 1, 2, 0, 0, 0.05
	))
	list.append(_make_rune(
		&"algiz", 15, "ᛉ", "Альгиз", "Охранный знак", RuneTypes.RuneAett.HAGAL, 1,
		[4, 8, 12, 18], [0, 0, 0, 0], [0, 0, 0, 0], [2, 4, 6, 9], [0, 0, 0, 0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0],
		"+ЗАЩ и оберег жизни",
		&"seal_algiz", "Печать Охранного Знака", "ГГ начинает бой с поглощающим рунным Барьером (+26 на 3 хода).",
		"+3 ЗАЩ, +12 HP", 12, 0, 0, 3, 0, 0.0
	))
	list.append(_make_rune(
		&"sowilo", 16, "ᛊ", "Соулу", "Победное солнце", RuneTypes.RuneAett.HAGAL, 2,
		[0, 0, 0, 0], [2, 4, 6, 8], [1, 2, 4, 6], [0, 0, 0, 0], [0, 0, 0, 0], [0.0, 0.01, 0.02, 0.04], [0.0, 0.0, 0.0, 0.0],
		"+АТК и +МАГ солнечного луча",
		&"seal_sowilo", "Печать Полуденного Солнца", "+10% к урону всех навыков и Ульты ГГ.",
		"+3 АТК, +3 МАГ", 6, 3, 3, 0, 0, 0.02
	))
	
	# =========================================================================
	# III. АТТ ТЮРА (руны 17..24)
	# =========================================================================
	list.append(_make_rune(
		&"tiwaz", 17, "ᛏ", "Тейваз", "Копьё Тюра", RuneTypes.RuneAett.TYR, 1,
		[0, 0, 6, 12], [2, 4, 6, 9], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0.02, 0.03, 0.05, 0.06], [0.0, 0.0, 0.0, 0.0],
		"+АТК и +Крит чести",
		&"seal_tiwaz", "Печать Копья Тюра", "+20% урона ГГ по блокирующим целям и усиленное пробитие стойки.",
		"+4 АТК, +4% Крит, +1 СКР", 8, 4, 0, 1, 1, 0.04
	))
	list.append(_make_rune(
		&"berkana", 18, "ᛒ", "Беркана", "Весенняя берёза", RuneTypes.RuneAett.TYR, 1,
		[7, 14, 22, 30], [0, 0, 0, 0], [1, 2, 3, 4], [0, 1, 1, 2], [0, 0, 0, 0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0],
		"+HP и живительная сила",
		&"seal_berkana", "Печать Весенней Берёзы", "Исцеление от умений ГГ и по самому ГГ увеличено на +25%.",
		"+14 HP, +4 МАГ, +1 ЗАЩ", 14, 0, 4, 1, 0, 0.0
	))
	list.append(_make_rune(
		&"ehwaz", 19, "ᛖ", "Эваз", "Боевой скакун", RuneTypes.RuneAett.TYR, 2,
		[0, 4, 8, 12], [1, 2, 3, 4], [0, 0, 0, 0], [0, 0, 0, 0], [1, 2, 4, 6], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0],
		"+СКР и слаженный натиск",
		&"seal_ehwaz", "Печать Стремительного Скакуна", "Даёт +2 СКР всем бойцам активного отряда в бою.",
		"+2 СКР, +2 АТК", 8, 2, 0, 0, 2, 0.0
	))
	list.append(_make_rune(
		&"mannaz", 20, "ᛗ", "Манназ", "Круг людей", RuneTypes.RuneAett.TYR, 1,
		[4, 8, 12, 16], [1, 2, 3, 4], [1, 2, 3, 4], [1, 2, 3, 4], [0, 0, 0, 0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0],
		"Сбалансированный рост статов",
		&"seal_mannaz", "Печать Круга Людей", "+4% исходящего урона ГГ за каждого живого союзника в строю.",
		"+10 HP, +2 АТК, +2 ЗАЩ", 10, 2, 2, 2, 0, 0.0
	))
	list.append(_make_rune(
		&"laguz", 21, "ᛚ", "Лагуз", "Глубинный поток", RuneTypes.RuneAett.TYR, 2,
		[0, 4, 8, 14], [0, 0, 0, 0], [2, 4, 6, 8], [0, 0, 0, 0], [1, 1, 2, 3], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0],
		"+МАГ и глубина Потока",
		&"seal_laguz", "Печать Глубинного Течения", "Увеличивает максимум Потока ГГ на +20 и стартовый запас на +15.",
		"+3 МАГ, +1 СКР, +8 HP", 8, 0, 3, 0, 1, 0.0
	))
	list.append(_make_rune(
		&"ingwaz", 22, "ᛜ", "Ингваз", "Зерно силы", RuneTypes.RuneAett.TYR, 3,
		[6, 12, 18, 26], [0, 1, 2, 3], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0.0, 0.0, 0.0, 0.0], [0.05, 0.10, 0.15, 0.20],
		"+HP и накопленный крит.урон",
		&"seal_ingwaz", "Печать Сокрытого Зерна", "ГГ начинает каждый бой уже с 25 ед. Напряжения (TENSION).",
		"+14 HP, +2 АТК", 14, 2, 0, 1, 0, 0.02
	))
	list.append(_make_rune(
		&"dagaz", 23, "ᛞ", "Дагаз", "Перелом рассвета", RuneTypes.RuneAett.TYR, 3,
		[0, 0, 6, 10], [2, 3, 5, 7], [0, 0, 0, 0], [0, 0, 0, 0], [1, 2, 3, 4], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0],
		"+АТК и +СКР первого удара",
		&"seal_dagaz", "Печать Первого Луча", "В 1-м раунде боя ГГ наносит +25% урона.",
		"+3 АТК, +2 СКР", 6, 3, 0, 0, 2, 0.0
	))
	list.append(_make_rune(
		&"othala", 24, "ᛟ", "Отала", "Наследие рода и драккар", RuneTypes.RuneAett.TYR, 1,
		[5, 10, 16, 24], [0, 1, 2, 3], [0, 0, 0, 0], [1, 2, 3, 4], [0, 0, 0, 0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0],
		"+HP/+ЗАЩ и бонус за каждого рекрута на корабле!",
		&"seal_othala", "Печать Наследия Драккара", "Удваивает бонус от каждого рекрута в ship_roster (+5 АТК, +3 ЗАЩ, +14 HP за бойца на корабле).",
		"+12 HP, +2 АТК, +2 ЗАЩ", 12, 2, 0, 2, 0, 0.0
	))
	
	return list

## Возвращает все 10 Бандрун (пара рун в Вязи ур. >= 3 -> активный рунный навык ГГ)
static func create_all_bindrunes() -> Array[BindruneData]:
	var list: Array[BindruneData] = []
	
	# 1. Бычий натиск (Уруз + Турисаз)
	var bull_qte: QTEConfigData = QTEConfigData.new()
	bull_qte.qte_type = BattleTypes.QTEType.RUSH_MASH
	bull_qte.duration_seconds = 2.3
	bull_qte.mash_target_presses = 9
	var bull_sk: SkillData = _make_bindrune_skill(
		"bindrune_bull_rush",
		"Бычий натиск",
		"Бандруна (ᚢ+ᚦ, QTE Рывок): сокрушительный напор, пробивающий блок и выбивающий врага из равновесия.",
		BattleTypes.TargetSide.ENEMY,
		22,
		BattleTypes.DamageType.PHYSICAL,
		24,
		1.30,
		bull_qte
	)
	var b_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.MELEE, BattleTypes.SkillTag.GUARD_BREAK]
	bull_sk.tags = b_tags
	bull_sk.applies_status = true
	bull_sk.status_to_apply = BattleTypes.StatusType.UNBALANCED
	bull_sk.status_duration_turns = 2
	list.append(_make_bindrune(&"bull_rush", "Бычий натиск", "ᚢ Уруз + ᚦ Турисаз: пробивной таранный удар с потерей равновесия.", &"uruz", &"thurisaz", bull_sk))
	
	# 2. Огненный град (Кеназ + Хагалаз)
	var hail_qte: QTEConfigData = QTEConfigData.new()
	hail_qte.qte_type = BattleTypes.QTEType.HOLD_RELEASE
	hail_qte.duration_seconds = 2.6
	hail_qte.hold_target_center = 0.75
	hail_qte.hold_charge_speed = 0.72
	var hail_sk: SkillData = _make_bindrune_skill(
		"bindrune_fire_hail",
		"Огненный град",
		"Бандруна (ᚲ+ᚺ, QTE Удержание): обрушивает раскалённый град на всех врагов и накладывает Ожог.",
		BattleTypes.TargetSide.ALL_ENEMIES,
		26,
		BattleTypes.DamageType.FIRE,
		21,
		1.20,
		hail_qte
	)
	hail_sk.applies_status = true
	hail_sk.status_to_apply = BattleTypes.StatusType.BURN
	hail_sk.status_duration_turns = 2
	list.append(_make_bindrune(&"fire_hail", "Огненный град", "ᚲ Кеназ + ᚺ Хагалаз: массовый огненный обвал с Ожогом.", &"kenaz", &"hagalaz", hail_sk))
	
	# 3. Стылая волна (Иса + Лагуз)
	var rime_qte: QTEConfigData = _make_center_qte(2.4, 1.40)
	var rime_sk: SkillData = _make_bindrune_skill(
		"bindrune_rime_wave",
		"Стылая волна",
		"Бандруна (ᛁ+ᛚ, QTE Центр): ледяной вал по врагу с Замедлением и шансом Заморозки.",
		BattleTypes.TargetSide.ENEMY,
		20,
		BattleTypes.DamageType.ICE,
		20,
		1.20,
		rime_qte
	)
	rime_sk.applies_status = true
	rime_sk.status_to_apply = BattleTypes.StatusType.FREEZE
	rime_sk.status_duration_turns = 1
	rime_sk.status_apply_chance = 0.65
	list.append(_make_bindrune(&"rime_wave", "Стылая волна", "ᛁ Иса + ᛚ Лагуз: ледяная волна с шансом сковать врага льдом.", &"isa", &"laguz", rime_sk))
	
	# 4. Щит клятвы (Альгиз + Гебо)
	var oath_qte: QTEConfigData = QTEConfigData.new()
	oath_qte.qte_type = BattleTypes.QTEType.CIRCULAR_SKILL_CHECK
	oath_qte.duration_seconds = 2.4
	oath_qte.cursor_speed = 1.45
	oath_qte.success_zone_width = 0.24
	oath_qte.perfect_zone_width = 0.08
	var oath_sk: SkillData = _make_bindrune_skill(
		"bindrune_oath_shield",
		"Щит клятвы",
		"Бандруна (ᛉ+ᚷ, QTE Круг): укрывает весь отряд рунным барьером (+30) и снижает входящий урон.",
		BattleTypes.TargetSide.ALL_ALLIES,
		22,
		BattleTypes.DamageType.MAGICAL,
		0,
		1.0,
		oath_qte
	)
	oath_sk.shield_barrier_amount = 30
	oath_sk.status_duration_turns = 2
	oath_sk.applies_ally_ward = true
	oath_sk.ally_ward_damage_reduction = 0.18
	oath_sk.ally_ward_duration_turns = 2
	list.append(_make_bindrune(&"oath_shield", "Щит клятвы", "ᛉ Альгиз + ᚷ Гебо: групповой рунный барьер и оберег отряда.", &"algiz", &"gebo", oath_sk))
	
	# 5. Первые побеги (Беркана + Йера)
	var sprout_qte: QTEConfigData = QTEConfigData.new()
	sprout_qte.qte_type = BattleTypes.QTEType.RUNE_SEQUENCE
	sprout_qte.sequence_length = 4
	sprout_qte.sequence_preview_step_sec = 0.34
	sprout_qte.duration_seconds = 3.2
	var sprout_sk: SkillData = _make_bindrune_skill(
		"bindrune_first_sprouts",
		"Первые побеги",
		"Бандруна (ᛒ+ᛃ, QTE Вязь знаков): живительная волна, исцеляющая всех живых бойцов отряда (+34 HP).",
		BattleTypes.TargetSide.ALL_ALLIES,
		24,
		BattleTypes.DamageType.MAGICAL,
		0,
		1.0,
		sprout_qte
	)
	sprout_sk.base_heal_amount = 34
	list.append(_make_bindrune(&"first_sprouts", "Первые побеги", "ᛒ Беркана + ᛃ Йера: массовое рунное исцеление отряда.", &"berkana", &"jera", sprout_sk))
	
	# 6. Слово ободрения (Ансуз + Вуньо)
	var word_qte: QTEConfigData = QTEConfigData.new()
	word_qte.qte_type = BattleTypes.QTEType.RHYTHM_TRACK
	word_qte.duration_seconds = 2.6
	word_qte.bpm = 120.0
	word_qte.note_count = 4
	var word_sk: SkillData = _make_bindrune_skill(
		"bindrune_encouraging_word",
		"Слово ободрения",
		"Бандруна (ᚨ+ᚹ, QTE Ноты): исцеляет выбранного союзника (+36 HP) и укрепляет его барьером (+16).",
		BattleTypes.TargetSide.ALLY,
		18,
		BattleTypes.DamageType.MAGICAL,
		0,
		1.0,
		word_qte
	)
	word_sk.base_heal_amount = 36
	word_sk.shield_barrier_amount = 16
	word_sk.status_duration_turns = 2
	list.append(_make_bindrune(&"encouraging_word", "Слово ободрения", "ᚨ Ансуз + ᚹ Вуньо: целебное слово и рунный щит союзнику.", &"ansuz", &"wunjo", word_sk))
	
	# 7. Братство (Манназ + Эваз)
	var bro_qte: QTEConfigData = QTEConfigData.new()
	bro_qte.qte_type = BattleTypes.QTEType.SERIES_CHAIN
	bro_qte.series_max_steps = 3
	bro_qte.series_speed_step_bonus = 0.18
	bro_qte.duration_seconds = 2.0
	bro_qte.cursor_speed = 1.32
	var bro_sk: SkillData = _make_bindrune_skill(
		"bindrune_brotherhood",
		"Братство",
		"Бандруна (ᛗ+ᛖ, QTE Серия 3 уд.): слаженный натиск, накладывающий на цель Отметку для всего отряда.",
		BattleTypes.TargetSide.ENEMY,
		20,
		BattleTypes.DamageType.PHYSICAL,
		11,
		0.95,
		bro_qte
	)
	bro_sk.hit_count = 3
	bro_sk.applies_status = true
	bro_sk.status_to_apply = BattleTypes.StatusType.MARKED
	bro_sk.status_duration_turns = 3
	list.append(_make_bindrune(&"brotherhood", "Братство", "ᛗ Манназ + ᛖ Эваз: тройная серия с наложением Отметки.", &"mannaz", &"ehwaz", bro_sk))
	
	# 8. Руна победы (Тейваз + Соулу)
	var vic_qte: QTEConfigData = _make_center_qte(2.4, 1.45)
	var vic_sk: SkillData = _make_bindrune_skill(
		"bindrune_victory_rune",
		"Руна победы",
		"Бандруна (ᛏ+ᛊ, QTE Центр): сияющий пробивной удар, ломающий блок и раскалывающий броню врага.",
		BattleTypes.TargetSide.ENEMY,
		24,
		BattleTypes.DamageType.FIRE,
		26,
		1.35,
		vic_qte
	)
	var v_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.MELEE, BattleTypes.SkillTag.GUARD_BREAK]
	vic_sk.tags = v_tags
	vic_sk.applies_status = true
	vic_sk.status_to_apply = BattleTypes.StatusType.DEFENSE_DOWN
	vic_sk.status_duration_turns = 3
	vic_sk.status_stacks_to_apply = 2
	list.append(_make_bindrune(&"victory_rune", "Руна победы", "ᛏ Тейваз + ᛊ Соулу: солнечный удар с пробитием блока и расколом брони.", &"tiwaz", &"sowilo", vic_sk))
	
	# 9. На износ (Наутиз + Эйваз)
	var grit_qte: QTEConfigData = QTEConfigData.new()
	grit_qte.qte_type = BattleTypes.QTEType.HOLD_RELEASE
	grit_qte.duration_seconds = 2.6
	grit_qte.hold_target_center = 0.74
	grit_qte.hold_charge_speed = 0.72
	var grit_sk: SkillData = _make_bindrune_skill(
		"bindrune_attrition",
		"На износ",
		"Бандруна (ᚾ+ᛇ, QTE Удержание): тяжёлый удар выдержки, накладывающий Кровотечение и Ослабление атаки врага.",
		BattleTypes.TargetSide.ENEMY,
		20,
		BattleTypes.DamageType.PHYSICAL,
		23,
		1.25,
		grit_qte
	)
	grit_sk.applies_status = true
	grit_sk.status_to_apply = BattleTypes.StatusType.ATTACK_DOWN
	grit_sk.status_duration_turns = 3
	list.append(_make_bindrune(&"attrition", "На износ", "ᚾ Наутиз + ᛇ Эйваз: истощающий удар с ослаблением атаки противника.", &"naudhiz", &"eihwaz", grit_sk))
	
	# 10. Перелом судьбы (Пертро + Дагаз)
	var fate_qte: QTEConfigData = QTEConfigData.new()
	fate_qte.qte_type = BattleTypes.QTEType.DICE_ROLL
	fate_qte.dice_count = 3
	fate_qte.dice_cycle_hz = 7.5
	fate_qte.duration_seconds = 3.0
	var fate_sk: SkillData = _make_bindrune_skill(
		"bindrune_fate_turn",
		"Перелом судьбы",
		"Бандруна (ᛈ+ᛞ, QTE Бросок): удар норн, отбрасывающий врага в конец очереди хода (ACT_LAST).",
		BattleTypes.TargetSide.ENEMY,
		22,
		BattleTypes.DamageType.MAGICAL,
		24,
		1.28,
		fate_qte
	)
	fate_sk.applies_status = true
	fate_sk.status_to_apply = BattleTypes.StatusType.ACT_LAST
	fate_sk.status_duration_turns = 2
	list.append(_make_bindrune(&"fate_turn", "Перелом судьбы", "ᛈ Пертро + ᛞ Дагаз: бросок норн со сдвигом врага в конец раунда.", &"perthro", &"dagaz", fate_sk))
	
	return list

## Возвращает все 6 Великих вязей (тройка рун на Печати ур. 5 -> Ульта ГГ с масштабированием 50%->100%)
static func create_all_great_binds() -> Array[GreatBindData]:
	var list: Array[GreatBindData] = []
	
	# 1. Вязь тура (ᚢ Уруз + ᚦ Турисаз + ᛏ Тейваз)
	var aurochs_qte: QTEConfigData = QTEConfigData.new()
	aurochs_qte.qte_type = BattleTypes.QTEType.RUSH_MASH
	aurochs_qte.duration_seconds = 2.6
	aurochs_qte.mash_target_presses = 11
	var aurochs_ult: SkillData = _make_ult_template(
		"great_bind_aurochs",
		"Вязь тура",
		"Великая вязь (ᚢ+ᚦ+ᛏ): первобытный таран сквозь любую защиту с Оглушением цели!",
		BattleTypes.TargetSide.ENEMY,
		BattleTypes.DamageType.PHYSICAL,
		52,
		1.45,
		aurochs_qte
	)
	var au_tags: Array[BattleTypes.SkillTag] = [BattleTypes.SkillTag.MELEE, BattleTypes.SkillTag.GUARD_BREAK, BattleTypes.SkillTag.UNBLOCKABLE]
	aurochs_ult.tags = au_tags
	aurochs_ult.applies_status = true
	aurochs_ult.status_to_apply = BattleTypes.StatusType.STUN
	aurochs_ult.status_duration_turns = 1
	list.append(_make_great_bind(&"great_aurochs", "Вязь тура", "ᚢ Уруз + ᚦ Турисаз + ᛏ Тейваз: сокрушительная ульта пролома с Оглушением.", [&"uruz", &"thurisaz", &"tiwaz"], aurochs_ult, false))
	
	# 2. Вязь стужи (ᚺ Хагалаз + ᛁ Иса + ᛇ Эйваз)
	var frost_qte: QTEConfigData = QTEConfigData.new()
	frost_qte.qte_type = BattleTypes.QTEType.HOLD_RELEASE
	frost_qte.duration_seconds = 2.8
	frost_qte.hold_target_center = 0.76
	frost_qte.hold_charge_speed = 0.70
	var frost_ult: SkillData = _make_ult_template(
		"great_bind_frost",
		"Вязь стужи",
		"Великая вязь (ᚺ+ᛁ+ᛇ): обрушивает бурю Фимбульвинтер на всех врагов с Заморозкой!",
		BattleTypes.TargetSide.ALL_ENEMIES,
		BattleTypes.DamageType.ICE,
		42,
		1.35,
		frost_qte
	)
	frost_ult.applies_status = true
	frost_ult.status_to_apply = BattleTypes.StatusType.FREEZE
	frost_ult.status_duration_turns = 1
	list.append(_make_great_bind(&"great_frost", "Вязь стужи", "ᚺ Хагалаз + ᛁ Иса + ᛇ Эйваз: массовая ледяная буря с Заморозкой.", [&"hagalaz", &"isa", &"eihwaz"], frost_ult, false))
	
	# 3. Вязь стены (ᛉ Альгиз + ᚷ Гебо + ᚾ Наутиз)
	var wall_qte: QTEConfigData = QTEConfigData.new()
	wall_qte.qte_type = BattleTypes.QTEType.CIRCULAR_SKILL_CHECK
	wall_qte.duration_seconds = 2.5
	wall_qte.cursor_speed = 1.40
	var wall_ult: SkillData = _make_ult_template(
		"great_bind_wall",
		"Вязь стены",
		"Великая вязь (ᛉ+ᚷ+ᚾ): воздвигает несокрушимый барьер (+55) и защиту -35% вх. урона всему отряду!",
		BattleTypes.TargetSide.ALL_ALLIES,
		BattleTypes.DamageType.MAGICAL,
		0,
		1.0,
		wall_qte
	)
	wall_ult.base_heal_amount = 24
	wall_ult.shield_barrier_amount = 55
	wall_ult.status_duration_turns = 3
	wall_ult.applies_ally_ward = true
	wall_ult.ally_ward_damage_reduction = 0.35
	wall_ult.ally_ward_duration_turns = 3
	list.append(_make_great_bind(&"great_wall", "Вязь стены", "ᛉ Альгиз + ᚷ Гебо + ᚾ Наутиз: великая твердыня барьера и защиты отряда.", [&"algiz", &"gebo", &"naudhiz"], wall_ult, false))
	
	# 4. Вязь весны (ᛒ Беркана + ᛃ Йера + ᛜ Ингваз)
	var spring_qte: QTEConfigData = QTEConfigData.new()
	spring_qte.qte_type = BattleTypes.QTEType.RUNE_SEQUENCE
	spring_qte.sequence_length = 4
	spring_qte.sequence_preview_step_sec = 0.34
	spring_qte.duration_seconds = 3.4
	var spring_ult: SkillData = _make_ult_template(
		"great_bind_spring",
		"Вязь весны",
		"Великая вязь (ᛒ+ᛃ+ᛜ): великое цветение жизни, мощно исцеляющее весь отряд (+62 HP) и дающее барьер!",
		BattleTypes.TargetSide.ALL_ALLIES,
		BattleTypes.DamageType.MAGICAL,
		0,
		1.0,
		spring_qte
	)
	spring_ult.base_heal_amount = 62
	spring_ult.shield_barrier_amount = 25
	spring_ult.status_duration_turns = 2
	list.append(_make_great_bind(&"great_spring", "Вязь весны", "ᛒ Беркана + ᛃ Йера + ᛜ Ингваз: мощное групповое исцеление и покров жизни.", [&"berkana", &"jera", &"ingwaz"], spring_ult, false))
	
	# 5. Вязь рассвета (ᛊ Соулу + ᛞ Дагаз + ᚨ Ансуз)
	var dawn_qte: QTEConfigData = _make_center_qte(2.4, 1.48)
	var dawn_ult: SkillData = _make_ult_template(
		"great_bind_dawn",
		"Вязь рассвета",
		"Великая вязь (ᛊ+ᛞ+ᚨ): ослепительное копьё рассвета по всем врагам с Ожогом и Ослеплением!",
		BattleTypes.TargetSide.ALL_ENEMIES,
		BattleTypes.DamageType.FIRE,
		46,
		1.40,
		dawn_qte
	)
	dawn_ult.applies_status = true
	dawn_ult.status_to_apply = BattleTypes.StatusType.BLIND
	dawn_ult.status_duration_turns = 2
	list.append(_make_great_bind(&"great_dawn", "Вязь рассвета", "ᛊ Соулу + ᛞ Дагаз + ᚨ Ансуз: солнечный удар по всем врагам с Ослеплением.", [&"sowilo", &"dagaz", &"ansuz"], dawn_ult, false))
	
	# 6. Вязь рода (ᛟ Отала + ᛗ Манназ + ᚠ Феху) — дополнительно усиливается от резерва драккара (ship_roster)!
	var kin_qte: QTEConfigData = QTEConfigData.new()
	kin_qte.qte_type = BattleTypes.QTEType.SERIES_CHAIN
	kin_qte.series_max_steps = 4
	kin_qte.series_speed_step_bonus = 0.18
	kin_qte.duration_seconds = 2.1
	kin_qte.cursor_speed = 1.32
	var kin_ult: SkillData = _make_ult_template(
		"great_bind_kin",
		"Вязь рода",
		"Великая вязь (ᛟ+ᛗ+ᚠ): натиск всего хирда и драккара (до 4 ударов; мощь растёт за каждого рекрута на корабле)!",
		BattleTypes.TargetSide.ALL_ENEMIES,
		BattleTypes.DamageType.PHYSICAL,
		16,
		1.15,
		kin_qte
	)
	kin_ult.hit_count = 4
	kin_ult.applies_status = true
	kin_ult.status_to_apply = BattleTypes.StatusType.DEFENSE_DOWN
	kin_ult.status_duration_turns = 3
	kin_ult.status_stacks_to_apply = 2
	list.append(_make_great_bind(&"great_kin", "Вязь рода", "ᛟ Отала + ᛗ Манназ + ᚠ Феху: ульта наследия хирда, растущая от рекрутов на драккаре.", [&"othala", &"mannaz", &"fehu"], kin_ult, true))
	
	return list

static func _make_rune(
	p_id: StringName,
	p_order: int,
	p_sym: String,
	p_name: String,
	p_meaning: String,
	p_aett: RuneTypes.RuneAett,
	p_episode: int,
	p_hp: Array[int],
	p_atk: Array[int],
	p_mag: Array[int],
	p_def: Array[int],
	p_spd: Array[int],
	p_crit: Array[float],
	p_cmult: Array[float],
	p_summary: String,
	p_seal_id: StringName,
	p_seal_name: String,
	p_seal_desc: String,
	p_res_desc: String,
	p_res_hp: int,
	p_res_atk: int,
	p_res_mag: int,
	p_res_def: int,
	p_res_spd: int,
	p_res_crit: float
) -> RuneData:
	var r: RuneData = RuneData.new()
	r.rune_id = p_id
	r.order_index = p_order
	r.symbol = p_sym
	r.display_name = p_name
	r.meaning_short = p_meaning
	r.aett = p_aett
	r.unlock_episode = p_episode
	r.hp_per_rank = p_hp
	r.attack_per_rank = p_atk
	r.magic_per_rank = p_mag
	r.defense_per_rank = p_def
	r.speed_per_rank = p_spd
	r.crit_chance_per_rank = p_crit
	r.crit_mult_per_rank = p_cmult
	r.passive_summary = p_summary
	r.seal_id = p_seal_id
	r.seal_name = p_seal_name
	r.seal_description = p_seal_desc
	r.resonance_description = p_res_desc
	r.resonance_hp = p_res_hp
	r.resonance_attack = p_res_atk
	r.resonance_magic = p_res_mag
	r.resonance_defense = p_res_def
	r.resonance_speed = p_res_spd
	r.resonance_crit = p_res_crit
	return r

static func _make_bindrune(
	p_id: StringName,
	p_name: String,
	p_desc: String,
	p_a: StringName,
	p_b: StringName,
	p_skill: SkillData
) -> BindruneData:
	var b: BindruneData = BindruneData.new()
	b.bindrune_id = p_id
	b.display_name = p_name
	b.description = p_desc
	b.rune_a = p_a
	b.rune_b = p_b
	b.granted_skill = p_skill
	return b

static func _make_great_bind(
	p_id: StringName,
	p_name: String,
	p_desc: String,
	p_runes: Array[StringName],
	p_ult: SkillData,
	p_ship_scale: bool
) -> GreatBindData:
	var g: GreatBindData = GreatBindData.new()
	g.great_bind_id = p_id
	g.display_name = p_name
	g.description = p_desc
	g.required_runes = p_runes
	g.ultimate_template = p_ult
	g.scales_with_ship_roster = p_ship_scale
	g.bonus_power_per_ship_member = 4 if p_ult.hit_count > 1 else 10
	return g

static func _make_center_qte(dur: float, spd: float) -> QTEConfigData:
	var qte: QTEConfigData = QTEConfigData.new()
	qte.qte_type = BattleTypes.QTEType.PRECISION_BAR
	qte.duration_seconds = dur
	qte.cursor_speed = spd
	qte.success_zone_width = 0.23
	qte.perfect_zone_width = 0.08
	return qte

static func _make_bindrune_skill(
	p_id: String,
	p_name: String,
	p_desc: String,
	p_side: BattleTypes.TargetSide,
	p_cost: int,
	p_dmg_type: BattleTypes.DamageType,
	p_base: int,
	p_mult: float,
	p_qte: QTEConfigData
) -> SkillData:
	var sk: SkillData = SkillData.new()
	sk.skill_id = p_id
	sk.skill_name = p_name
	sk.description = p_desc
	sk.action_category = BattleTypes.ActionType.SKILL
	sk.target_side = p_side
	sk.resource_type = BattleTypes.ResourceType.ENERGY
	sk.resource_cost = p_cost
	sk.damage_type = p_dmg_type
	sk.base_power = p_base
	sk.power_multiplier = p_mult
	sk.blockability = BattleTypes.Blockability.HIGH_80
	sk.requires_qte = p_qte != null
	sk.qte_config = p_qte
	return sk

static func _make_ult_template(
	p_id: String,
	p_name: String,
	p_desc: String,
	p_side: BattleTypes.TargetSide,
	p_dmg_type: BattleTypes.DamageType,
	p_base: int,
	p_mult: float,
	p_qte: QTEConfigData
) -> SkillData:
	var sk: SkillData = SkillData.new()
	sk.skill_id = p_id
	sk.skill_name = p_name
	sk.description = p_desc
	sk.action_category = BattleTypes.ActionType.ULTIMATE
	sk.is_ultimate = true
	sk.min_tension_tier = BattleTypes.TensionTier.HALF_50
	sk.target_side = p_side
	sk.damage_type = p_dmg_type
	sk.base_power = p_base
	sk.power_multiplier = p_mult
	sk.blockability = BattleTypes.Blockability.NONE_0
	sk.requires_qte = p_qte != null
	sk.qte_config = p_qte
	return sk
