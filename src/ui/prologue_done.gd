class_name PrologueDone
extends Control
## End of Season 2's prologue: the keeper is chosen and Mırıl's light trail
## points over the mountains. What comes next (Bölüm 0, Buharlı Kaplıca Köyü)
## and two buttons: walk around the village, or the menu.

signal chosen(id: String)

## Season 3's prologue ends the same way, with its own lines.
const NEXT_S3 := [
	["spark", "sky", "Bölüm 0: Mercan Koyu ve Yaşlı Deniz Feneri"],
	["heart", "honey", "Mors Dede Bıyık ve kapısını kilitleyen köylüler"],
	["star", "spark-purple", "Hortlak Çarşaf ve ilk İşaret Fişeği"],
	["quest", "sky", "Sonra: beş ada, beş inci, korkan beş bekçi"],
]

const NEXT := [
	["spark", "hp", "Bölüm 0: Buharlı Kaplıca Köyü"],
	["heart", "honey", "Tospik Nine ve hiç susmayan köylüler"],
	["star", "spark-purple", "Homurdanan Çaydanlık ve ilk Ses Çanı"],
	["quest", "sky", "Sonra: beş Kor, beş öfkeli bekçi"],
]


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
	panel.custom_minimum_size = Vector2(700, 0)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	panel.add_child(v)
	var title := UiKit.label("Prolog tamamlandı!", "text-title", "ink")
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var s3 := GameState.data.season >= 3
	var sub := UiKit.label("Sezon 3: Titrek Kıyılar" if s3 else "Sezon 2: Kor Vadisi", "text-label", "ink-muted")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(HSeparator.new())
	v.add_child(UiKit.label("Sırada ne var?", "text-heading", "ink"))
	for n: Array in (NEXT_S3 if s3 else NEXT):
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
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	v.add_child(buttons)
	var go := UiKit.button("Denize açıl" if s3 else "Kor Vadisi'ne in")
	go.custom_minimum_size = Vector2(240, 60)
	go.pressed.connect(func() -> void: chosen.emit("s3_chapter0" if s3 else "s2_chapter0"))
	buttons.add_child(go)
	var menu := UiKit.button("Ana menü", false)
	menu.custom_minimum_size = Vector2(180, 60)
	menu.pressed.connect(func() -> void: chosen.emit("title"))
	buttons.add_child(menu)
