class_name ChoicePanel
extends Control
## A small modal with a title and big buttons (one per option), e.g.
## "Nereye uçalım?". options: [{id, label, enabled, note}]. Emits chosen("")
## when closed without a choice.

signal chosen(id: String)

var title := ""
var options: Array = []


func _init(t: String, opts: Array) -> void:
	title = t
	options = opts


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
	panel.custom_minimum_size = Vector2(460, 0)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	panel.add_child(v)
	v.add_child(UiKit.label(title, "text-title", "ink"))
	var first := true
	for o: Dictionary in options:
		var ok: bool = o.get("enabled", true)
		var b := UiKit.button(o["label"], ok and first)
		b.custom_minimum_size = Vector2(0, 60)
		b.disabled = not ok
		if ok:
			first = false
		var id: String = o["id"]
		b.pressed.connect(func() -> void: _pick(id))
		v.add_child(b)
		if o.has("note") and not ok:
			v.add_child(UiKit.label(o["note"], "text-caption", "ink-muted"))
	var close := UiKit.button("Vazgeç", false)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(func() -> void: _pick(""))
	v.add_child(close)


func _pick(id: String) -> void:
	chosen.emit(id)
	queue_free()
