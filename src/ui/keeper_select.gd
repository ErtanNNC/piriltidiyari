class_name KeeperSelect
extends Control
## Sahne 6: "Bekçini seç". Four candidate cards; picking one sends the spark
## to that keeper and they say their line. Then color, accessory and name.
## Emits `chosen` with (id, look, name).

signal highlighted(id: String)
signal look_changed(id: String, look: Dictionary)
signal chosen(id: String, look: Dictionary, display_name: String)

const ORDER := ["pati", "bado", "citir", "lumi"]

## Which keepers are offered (Season 2 adds Tıpış) and, optionally, the
## line each says when highlighted (Season 2 has new ones). Set before adding.
var order: Array = ORDER
var lines: Dictionary = {}

var current := ""
var look := {"variant": 0, "accessory": "yok"}
var _cards: Dictionary = {}
var _title: Label
var _line: Label
var _line_pill: PanelContainer
var _pick: Button
var _cards_row: HBoxContainer
var _custom: PanelContainer
var _name_edit: LineEdit
var _swatches: HBoxContainer
var _accessories: HBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := Tokens.px("space-6")
	_title = UiKit.outlined(UiKit.label("Bekçini seç", "text-title", "panel@light"), 10)
	_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.offset_top = m
	add_child(_title)
	_line_pill = PanelContainer.new()
	var ls := UiKit.box(Tokens.color("panel"), "radius-pill", 4.0)
	ls.content_margin_left = 20
	ls.content_margin_right = 20
	ls.content_margin_top = 6
	ls.content_margin_bottom = 6
	_line_pill.add_theme_stylebox_override("panel", ls)
	_line_pill.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_line_pill.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_line_pill.offset_top = m + 56
	_line_pill.visible = false
	add_child(_line_pill)
	_line = UiKit.label("", "text-body", "ink")
	_line_pill.add_child(_line)

	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.offset_bottom = -m
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	add_child(bottom)
	_cards_row = HBoxContainer.new()
	_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_row.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	bottom.add_child(_cards_row)
	for id in order:
		var card := KeeperCard.new(id)
		if order.size() > 4:
			card.custom_minimum_size.x = 226
		card.pressed.connect(func() -> void: select(id))
		_cards_row.add_child(card)
		_cards[id] = card
	_pick = UiKit.button("Seç")
	_pick.custom_minimum_size = Vector2(200, 60)
	_pick.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_pick.disabled = true
	_pick.pressed.connect(_open_custom)
	bottom.add_child(_pick)
	_build_custom()


func select(id: String) -> void:
	current = id
	look = {"variant": 0, "accessory": "yok"}
	for k: String in _cards:
		(_cards[k] as KeeperCard).set_selected(k == id)
	var info: Dictionary = Content.keeper(id)
	_line.text = TranslationServer.translate("%s: “%s”") % [TranslationServer.translate(info["name"]), TranslationServer.translate(lines.get(id, info["line"]))]
	_line_pill.visible = true
	_pick.disabled = false
	_pick.text = TranslationServer.translate("Seç: %s") % TranslationServer.translate(info["name"])
	highlighted.emit(id)


func _build_custom() -> void:
	_custom = PanelContainer.new()
	_custom.add_theme_stylebox_override("panel", UiKit.panel_style())
	_custom.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_custom.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_custom.grow_vertical = Control.GROW_DIRECTION_BOTH
	_custom.offset_right = -Tokens.px("space-6")
	_custom.custom_minimum_size = Vector2(380, 0)
	_custom.visible = false
	add_child(_custom)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	_custom.add_child(v)
	v.add_child(UiKit.label("Görünüşün", "text-heading", "ink"))
	v.add_child(UiKit.label("Renk", "text-label", "ink-muted"))
	_swatches = HBoxContainer.new()
	_swatches.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	v.add_child(_swatches)
	v.add_child(UiKit.label("Aksesuar", "text-label", "ink-muted"))
	_accessories = HBoxContainer.new()
	_accessories.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	v.add_child(_accessories)
	for acc in KeeperModels.ACCESSORIES:
		var b := UiKit.button(KeeperModels.ACCESSORY_NAMES[acc], false)
		b.custom_minimum_size = Vector2(76, 52)
		b.add_theme_font_size_override("font_size", 16)
		b.toggle_mode = true
		b.pressed.connect(func() -> void:
			look["accessory"] = acc
			_refresh_custom()
			look_changed.emit(current, look))
		b.set_meta("acc", acc)
		_accessories.add_child(b)
	v.add_child(UiKit.label("Adın", "text-label", "ink-muted"))
	_name_edit = LineEdit.new()
	_name_edit.max_length = 12
	_name_edit.custom_minimum_size = Vector2(0, 52)
	_name_edit.add_theme_font_override("font", Tokens.font_for("text-heading"))
	_name_edit.add_theme_font_size_override("font_size", 22)
	_name_edit.add_theme_color_override("font_color", Tokens.color("ink"))
	var es := UiKit.box(Tokens.color("panel-sunken"), "radius-md")
	es.content_margin_left = 14
	_name_edit.add_theme_stylebox_override("normal", es)
	_name_edit.add_theme_stylebox_override("focus", es)
	v.add_child(_name_edit)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	v.add_child(row)
	var back := UiKit.button("Geri", false)
	back.pressed.connect(func() -> void:
		_custom.visible = false
		_cards_row.visible = true
		_pick.visible = true)
	row.add_child(back)
	var go := UiKit.button("Başla")
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.pressed.connect(func() -> void:
		var n := _name_edit.text.strip_edges()
		if n == "":
			n = Content.keeper(current)["name"]
		chosen.emit(current, look.duplicate(), n))
	row.add_child(go)


func _open_custom() -> void:
	if current == "":
		return
	_cards_row.visible = false
	_pick.visible = false
	_custom.visible = true
	_name_edit.text = Content.keeper(current)["name"]
	for c in _swatches.get_children():
		c.queue_free()
	var variants: Array = KeeperModels.INFO[current]["variants"]
	for i in variants.size():
		var sw := Button.new()
		sw.custom_minimum_size = Vector2(56, 56)
		sw.focus_mode = Control.FOCUS_NONE
		sw.set_meta("i", i)
		sw.pressed.connect(func() -> void:
			look["variant"] = i
			_refresh_custom()
			look_changed.emit(current, look))
		_swatches.add_child(sw)
	_refresh_custom.call_deferred()


func _refresh_custom() -> void:
	var variants: Array = KeeperModels.INFO[current]["variants"]
	for sw: Button in _swatches.get_children():
		var i: int = sw.get_meta("i")
		var st := UiKit.box(KeeperModels.swatch(current, i), "radius-pill", 4.0 if i == look["variant"] else 0.0, 5.0 if i == look["variant"] else 3.0)
		if i == look["variant"]:
			st.border_color = Tokens.color("honey-deep")
		for k in ["normal", "hover", "pressed"]:
			sw.add_theme_stylebox_override(k, st)
	for b: Button in _accessories.get_children():
		b.button_pressed = b.get_meta("acc") == look["accessory"]
		var fill := Tokens.color("honey") if b.button_pressed else Tokens.color("panel")
		var st := UiKit.box(fill, "radius-md", 4.0)
		b.add_theme_stylebox_override("normal", st)
		b.add_theme_stylebox_override("hover", st)
