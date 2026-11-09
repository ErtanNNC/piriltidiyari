class_name Season2End
extends Control
## "Sezon 2 tamamlandı!" — the five Kor, a closing line that depends on the
## keeper you played, and the way home: walk around the village, or the menu.

signal chosen(id: String)

## The last line for each keeper (the story's closing, per character).
const ENDINGS := {
	"pati": "Fıstık sana kendi kalkanını verdi: artık çırak değil, şövalyesin!",
	"bado": "Minnoş ilk kez söyledi: \"Beni dinlediğin için teşekkürler, ağabey.\"",
	"citir": "İki diyarı tek haritada birleştirdin ve araya bir dağ yolu çizdin.",
	"lumi": "Mırıl, Hırıl ve sen: artık üç arkadaşsınız.",
	"tipis_panda": "Hırıl ile kırık davulu birlikte tamir ettiniz.",
}


func _ready() -> void:
	# a full-screen summary: works even while the game is paused, and the
	# HUD holds the level-up cards until it is gone (they'd open behind it)
	add_to_group("hud_overlay")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
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
	var title := UiKit.label("Sezon 2 tamamlandı!", "text-title", "ink")
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UiKit.label("Kor Vadisi · Kıvılcım Bekçileri 2", "text-label", "ink-muted")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var kors := KorTracker.new()
	kors.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(kors)
	v.add_child(HSeparator.new())
	var d := GameState.data
	for line: String in ["Beş Kor bir oldu, Kızıl Sis dağıldı.",
			"Mırıl ve Hırıl birlikte Pırıltı Diyarı'na dönüyor.",
			"Fener yedinci rengini aldı: kırmızı. Gökkuşağı tamam!"]:
		v.add_child(UiKit.label(line, "text-body", "ink"))
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
	var stay := UiKit.button("Köyde dolaş")
	stay.custom_minimum_size = Vector2(220, 60)
	stay.pressed.connect(func() -> void: chosen.emit("s2_chapter0"))
	buttons.add_child(stay)
	var menu := UiKit.button("Ana menü", false)
	menu.custom_minimum_size = Vector2(180, 60)
	menu.pressed.connect(func() -> void: chosen.emit("title"))
	buttons.add_child(menu)
