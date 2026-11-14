class_name WardrobePanel
extends Control
## Bekçi Evi's wardrobe: put on an outfit or pick a tool you own (or none).

signal closed

const SLOTS := [["outfit", "Kıyafet"], ["weapon", "Alet"]]

var _list: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.color = Tokens.color("scrim")
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_style())
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(620, 0)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	panel.add_child(v)
	v.add_child(UiKit.label("Dolap", "text-title", "ink"))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	v.add_child(_list)
	var close := UiKit.button("Kapat", false)
	close.custom_minimum_size = Vector2(160, 56)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free())
	v.add_child(close)
	UiKit.menu(self, null, close)
	_refresh()


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var d := GameState.data
	for slot: Array in SLOTS:
		var kind: String = slot[0]
		_list.add_child(UiKit.label(slot[1], "text-heading", "ink"))
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", int(Tokens.px("space-2")))
		row.add_theme_constant_override("v_separation", int(Tokens.px("space-2")))
		_list.add_child(row)
		var owned := [""]
		for id: String in Content.items:
			if Content.items[id].get("kind", "") == kind and d.has_flag("owned_" + id):
				owned.append(id)
		for id: String in owned:
			var on: bool = d.equipped.get(kind, "") == id
			var label := "Yok" if id == "" else String(Content.items[id].get("name", id))
			var b := UiKit.button(label, on)
			b.custom_minimum_size = Vector2(0, 52)
			b.pressed.connect(func() -> void:
				Shop.equip(d, kind, id)
				_refresh())
			row.add_child(b)
		var worn: String = d.equipped.get(kind, "")
		if worn != "":
			_list.add_child(UiKit.label(String(Content.items[worn].get("desc", "")), "text-caption", "ink-muted"))
		if owned.size() == 1:
			var hint := UiKit.label("Henüz yok. Köydeki dükkândan alabilirsin.", "text-caption", "ink-muted")
			_list.add_child(hint)
