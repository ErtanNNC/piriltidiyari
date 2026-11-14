class_name LevelUpPanel
extends Control
## "Seviye atladın!": three power cards. Pick a new power or rank one up.
## The game waits (paused) until a card is chosen.

signal picked(id: String)

var _choices: Array = []


func _init(choices: Array) -> void:
	_choices = choices


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.color = Tokens.color("scrim")
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", int(Tokens.px("space-4")))
	add_child(v)
	var d := GameState.data
	var title := UiKit.outlined(UiKit.label(TranslationServer.translate("Seviye %d!") % d.level, "text-hero", "panel@light"), 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UiKit.outlined(UiKit.label("Bir güç seç: yeni bir güç öğren ya da bildiğini yükselt", "text-body", "panel@light"), 8)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(Tokens.px("space-4")))
	v.add_child(row)
	for c: Dictionary in _choices:
		row.add_child(_card(c))
	UiKit.menu(self)
	Audio.play("levelup")


func _card(c: Dictionary) -> Control:
	var id: String = c["id"]
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(250, 270)
	var st := UiKit.panel_style()
	card.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	card.add_child(v)
	var name := "Pırıl Kesesi"
	var desc := TranslationServer.translate("%d Pırıl kazanırsın") % Powers.FALLBACK_PIRIL
	var color := "piril"
	var tag := "Hediye"
	if id != Powers.FALLBACK:
		var def: Dictionary = Powers.DEFS[id]
		name = def["name"]
		color = def["color"]
		desc = def["desc"] if c["new"] else def["up"]
		var kind := "Buton" if def["kind"] == "active" else "Her zaman açık"
		tag = (TranslationServer.translate("YENİ · %s") % TranslationServer.translate(kind)) if c["new"] else TranslationServer.translate("Kademe %d → %d") % [int(c["rank"]) - 1, c["rank"]]
	var pill := PanelContainer.new()
	var ps := UiKit.box(Tokens.color(Content.text_safe(color)), "radius-pill", 0.0)
	ps.content_margin_left = 10
	ps.content_margin_right = 10
	pill.add_theme_stylebox_override("panel", ps)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pill.add_child(UiKit.label(tag, "text-caption", "on-color"))
	v.add_child(pill)
	var icon := GameIcon.new()
	icon.kind = "spark" if id != Powers.FALLBACK else "piril"
	icon.fill = Tokens.color(color)
	icon.custom_minimum_size = Vector2(56, 56)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(icon)
	var n := UiKit.label(name, "text-heading", "ink")
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	var dl := UiKit.label(desc, "text-body", "ink-muted")
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dl.custom_minimum_size = Vector2(220, 0)
	dl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(dl)
	var b := UiKit.button("Seç")
	b.custom_minimum_size = Vector2(0, 56)
	b.pressed.connect(func() -> void: picked.emit(id))
	v.add_child(b)
	return card
