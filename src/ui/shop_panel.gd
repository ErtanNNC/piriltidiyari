class_name ShopPanel
extends Control
## A shop window: item slot, name, what it does, Pırıl price, Satın al.
## "Satın al" is the one primary (honey) action per row when affordable.

signal closed

var shop_id := ""
var _rows: VBoxContainer
var _wallet: Label


func _init(id: String) -> void:
	shop_id = id


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
	panel.custom_minimum_size = Vector2(640, 0)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var title := UiKit.label(Content.shops.get(shop_id, {}).get("title", "Dükkân"), "text-title", "ink")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var wallet := HBoxContainer.new()
	wallet.add_theme_constant_override("separation", 4)
	var wi := GameIcon.new()
	wi.kind = "piril"
	wi.fill = Tokens.color("piril")
	wi.custom_minimum_size = Vector2(30, 30)
	wallet.add_child(wi)
	_wallet = UiKit.label("", "text-number", "ink")
	_wallet.add_theme_font_override("font", Tokens.font_for("text-number"))
	wallet.add_child(_wallet)
	head.add_child(wallet)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	v.add_child(_rows)
	var close := UiKit.button("Kapat", false)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free())
	v.add_child(close)
	_refresh()


func _refresh() -> void:
	_wallet.text = str(GameState.data.piril)
	for c in _rows.get_children():
		c.queue_free()
	for entry: Dictionary in Content.shops.get(shop_id, {}).get("items", []):
		_rows.add_child(_row(entry))


func _row(entry: Dictionary) -> Control:
	var id: String = entry["id"]
	var def: Dictionary = Content.items.get(id, {})
	var price := int(entry["price"])
	var once: bool = entry.get("once", false)
	var owned := once and GameState.data.has_flag("owned_" + id)
	var can := GameState.data.piril >= price and not owned
	var row := PanelContainer.new()
	var rs := UiKit.box(Tokens.color("panel-sunken"), "radius-md", 0.0, 0.0)
	rs.set_content_margin_all(Tokens.px("space-2"))
	row.add_theme_stylebox_override("panel", rs)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	row.add_child(h)
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(60, 60)
	slot.add_theme_stylebox_override("panel", UiKit.box(Tokens.color("panel"), "radius-sm", 3.0))
	var icon := GameIcon.new()
	icon.kind = def.get("icon", "heart")
	icon.fill = Tokens.color(def.get("color", "honey"))
	icon.custom_minimum_size = Vector2(36, 36)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.add_child(icon)
	h.add_child(slot)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 0)
	texts.add_child(UiKit.label(def.get("name", id), "text-heading", "ink"))
	texts.add_child(UiKit.label(def.get("desc", ""), "text-caption", "ink-muted"))
	h.add_child(texts)
	var price_row := HBoxContainer.new()
	price_row.add_theme_constant_override("separation", 4)
	var pi := GameIcon.new()
	pi.kind = "piril"
	pi.fill = Tokens.color("piril")
	pi.custom_minimum_size = Vector2(26, 26)
	pi.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	price_row.add_child(pi)
	var pl := UiKit.label(str(price), "text-heading", "ink")
	pl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	price_row.add_child(pl)
	h.add_child(price_row)
	var buy := UiKit.button("Alındı" if owned else "Satın al", can)
	buy.custom_minimum_size = Vector2(140, 56)
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy.disabled = owned
	buy.pressed.connect(func() -> void:
		var r := Shop.buy(GameState.data, def, id, price, once)
		match r:
			"ok":
				GameState.toast.emit(TranslationServer.translate("%s aldın") % TranslationServer.translate(String(def.get("name", id))), "piril")
			"piril":
				GameState.toast.emit("Pırıl yetmiyor", "piril")
		_refresh())
	h.add_child(buy)
	return row
