class_name Season3End
extends Control
## "Sezon 3 tamamlandı!" — the five pearls, a closing line that depends on
## the keeper you played, and the way home: walk around the cove, or the menu.

signal chosen(id: String)

## The last line for each keeper (the story's closing, per character).
const ENDINGS := {
	"pati": "Herkesin önünde denize atladın ve yüzdün. Su o kadar da ıslak değilmiş!",
	"bado": "Minnoş ilk kez gece lambasız uyudu. Sen yanındaydın.",
	"citir": "Haritana bir güvenli liman çizdin: \"Kaybolursan buraya gel.\"",
	"lumi": "Ateşböceği ailen ve Tırıl'ın ailesi birlikte bir ışık dansı yaptı.",
	"tipis_panda": "Hırıl ile kumsalda ilk ortak davul konserinizi verdiniz.",
	"tosbi": "Tospik Nine sana dedenin kabuk kalkanını verdi: saklanmak da cesarettir.",
	# Yeni Oyun+ keepers
	"hiril": "Davulun bu kez bütün kıyıya yetti. Tırıl ritmini ezbere biliyor!",
	"tiril": "Küçük bir Titrek'e ışığını gösterdin: \"Ben de korkmuştum. Bak, geçti.\"",
}


func _ready() -> void:
	# a full-screen summary: works even while the game is paused, and the
	# HUD holds the level-up cards until it is gone (they'd open behind it)
	add_to_group("hud_overlay")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	UiKit.menu(self)
	var bg := ColorRect.new()
	bg.color = Tokens.color("scrim")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_style())
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(760, 0)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	panel.add_child(v)
	var title := UiKit.label("Sezon 3 tamamlandı!", "text-title", "ink")
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UiKit.label("Titrek Kıyılar · Kıvılcım Bekçileri 3", "text-label", "ink-muted")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var pearls := PearlTracker.new()
	pearls.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(pearls)
	v.add_child(HSeparator.new())
	var d := GameState.data
	for line: String in ["Beş inci yerine kondu, Yaşlı Deniz Feneri yeniden yandı.",
			"Tırıl ailesine kavuştu. Işığı artık titremiyor.",
			"Pırıltı Diyarı'nın Feneri geceleri mavi bir gece lambası: korkan herkes için."]:
		var l := UiKit.label(line, "text-body", "ink")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(680, 0)
		v.add_child(l)
	var mine := UiKit.label(ENDINGS.get(d.character_id, ENDINGS["pati"]), "text-body", "ink")
	mine.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mine.custom_minimum_size = Vector2(680, 0)
	v.add_child(mine)
	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	v.add_child(chips)
	chips.add_child(UiKit.label(TranslationServer.translate("Seviye %d") % d.level, "text-label", "ink-muted"))
	chips.add_child(UiKit.label(TranslationServer.translate("%d Pırıl") % d.piril, "text-label", "ink-muted"))
	var thanks := UiKit.label("Oynadığın için teşekkürler! · Just A Game Studios", "text-caption", "ink-muted")
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(thanks)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	v.add_child(buttons)
	var stay := UiKit.button("Koyda dolaş")
	stay.custom_minimum_size = Vector2(220, 60)
	stay.pressed.connect(func() -> void: chosen.emit("s3_chapter0"))
	buttons.add_child(stay)
	# the next season: Dikenli Bahçeler
	if d.can_start_season4():
		var s4 := UiKit.button("Sezon 4'e başla")
		s4.name = "Season4"
		s4.custom_minimum_size = Vector2(220, 60)
		s4.pressed.connect(func() -> void: SeasonFlow.start_season4())
		buttons.add_child(s4)
	if d.can_start_new_game_plus():
		var ng := UiKit.button("Yeni Oyun+", false)
		ng.name = "NewGamePlus"
		ng.custom_minimum_size = Vector2(200, 60)
		ng.pressed.connect(func() -> void:
			var ask := SeasonFlow.ng_confirm()
			add_child(ask)
			if await ask.answered:
				SeasonFlow.start_new_game_plus())
		buttons.add_child(ng)
	var menu := UiKit.button("Ana menü", false)
	menu.custom_minimum_size = Vector2(180, 60)
	menu.pressed.connect(func() -> void: chosen.emit("title"))
	buttons.add_child(menu)
