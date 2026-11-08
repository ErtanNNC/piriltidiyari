class_name SeasonEnd
extends Control
## "Sezon 1 tamamlandı!" — a summary of the season and a short look at what
## the next season brings. Buttons: keep exploring the village, or the menu.

signal chosen(id: String)

const NEXT := [
	["spark", "hp", "Kırmızı sis: diyarın ötesinde yeni bir gizem"],
	["star", "spark-purple", "10 yeni Hikâye Taşı ve Düşen Yıldız Tarlası"],
	["heart", "honey", "Fıstık ve Mırıl oynanabilir oluyor (Yeni Oyun+)"],
	["star", "sky", "Işık Arenası: dalga dalga gelen eski dostlar"],
	["quest", "leaf", "Bekçilerin imza eşyası görevlerinin devamı"],
]


func _ready() -> void:
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
	var title := UiKit.label("Sezon 1 tamamlandı!", "text-title", "ink")
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UiKit.label("Pırıltı Diyarı · Kıvılcım Bekçileri", "text-label", "ink-muted")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var d := GameState.data
	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	v.add_child(chips)
	for c in [["spark", "honey", TranslationServer.translate("Kıvılcımlar %d/5") % d.sparks.size()],
			["star", "spark-purple", TranslationServer.translate("Hikâye Taşları %d/%d") % [d.item_count("hikaye_tasi"), PlayerData.STORY_STONES]],
			["star", "xp", TranslationServer.translate("Seviye %d") % d.level], ["piril", "piril", TranslationServer.translate("%d Pırıl") % d.piril]]:
		chips.add_child(_chip(c[0], c[1], c[2]))
	v.add_child(HSeparator.new())
	v.add_child(UiKit.label("Sezon 2'de seni neler bekliyor?", "text-heading", "ink"))
	for n: Array in NEXT:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", int(Tokens.px("space-2")))
		var ic := GameIcon.new()
		ic.kind = n[0]
		ic.fill = Tokens.color(n[1])
		ic.custom_minimum_size = Vector2(26, 26)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(ic)
		row.add_child(UiKit.label(n[2], "text-body", "ink"))
		v.add_child(row)
	var thanks := UiKit.label("Oynadığın için teşekkürler! · Just A Game Studios", "text-caption", "ink-muted")
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(thanks)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	v.add_child(buttons)
	var stay := UiKit.button("Köyde dolaş")
	stay.custom_minimum_size = Vector2(220, 60)
	stay.pressed.connect(func() -> void: chosen.emit("chapter0"))
	buttons.add_child(stay)
	var menu := UiKit.button("Ana menü", false)
	menu.custom_minimum_size = Vector2(180, 60)
	menu.pressed.connect(func() -> void: chosen.emit("title"))
	buttons.add_child(menu)


func _chip(icon: String, col: String, text: String) -> PanelContainer:
	var p := PanelContainer.new()
	var s := UiKit.box(Tokens.color("panel-sunken"), "radius-pill", 0.0, 2.0)
	s.content_margin_left = 10
	s.content_margin_right = 14
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", s)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	p.add_child(h)
	var ic := GameIcon.new()
	ic.kind = icon
	ic.fill = Tokens.color(col)
	ic.custom_minimum_size = Vector2(22, 22)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	h.add_child(UiKit.label(text, "text-label", "ink"))
	return p
