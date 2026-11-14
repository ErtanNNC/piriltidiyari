class_name KeeperCard
extends PanelContainer
## CharacterCard: name, species, Can / Güç / Hız as 1–5 pips, special skill.
## Selected: honey contour and raised.

signal pressed

var id := ""
var _selected := false
## Eight keepers in one row (Yeni Oyun+): a narrow card, long words end in “…”.
var compact := false


func _init(keeper_id: String) -> void:
	id = keeper_id
	custom_minimum_size = Vector2(250, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# pad / keyboard: move onto a card, accept picks it
	focus_mode = Control.FOCUS_ALL
	UiFocus.track(self)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	UiFocus.ring("radius-lg").changed.connect(queue_redraw)


func _ready() -> void:
	var info: Dictionary = Content.keeper(id)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	v.add_child(head)
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(30, 30) if compact else Vector2(36, 36)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.add_theme_stylebox_override("panel", UiKit.box(Tokens.color(Content.text_safe(info["color"])), "radius-pill"))
	var letter := UiKit.label(TranslationServer.translate(String(info["name"])).left(1), "text-label", "on-color")
	letter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dot.add_child(letter)
	head.add_child(dot)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -4)
	head.add_child(names)
	names.add_child(UiKit.label(info["name"], "text-heading", "ink"))
	var species := UiKit.label(info["species"], "text-caption", "ink-muted")
	if compact:
		species.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		species.clip_text = true
		v.add_child(species)
	else:
		names.add_child(species)
	for stat in [["can", "Can", "hp"], ["guc", "Güç", "berry"], ["hiz", "Hız", "sky"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var l := UiKit.label(stat[1], "text-caption", "ink")
		l.custom_minimum_size.x = 30 if compact else 44
		row.add_child(l)
		var n: int = int(info["stats"][stat[0]])
		for i in 5:
			var pip := Panel.new()
			pip.custom_minimum_size = Vector2(15, 12) if compact else Vector2(26, 14)
			pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			pip.add_theme_stylebox_override("panel", UiKit.box(Tokens.color(stat[2]) if i < n else Tokens.color("panel-sunken"), "radius-pill", 0.0, 2.0))
			row.add_child(pip)
		v.add_child(row)
	var special := UiKit.label(String(info["special"]).get_slice(":", 0), "text-caption", "ink-muted")
	if compact:
		v.add_theme_constant_override("separation", 2)
		special.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		special.clip_text = true
	v.add_child(special)
	set_selected(false)


func set_selected(on: bool) -> void:
	_selected = on
	var s := UiKit.box(Tokens.color("panel"), "radius-lg", 4.0, 5.0 if on else 3.0)
	if on:
		s.border_color = Tokens.color("honey-deep")
	s.set_content_margin_all(Tokens.px("space-2") if compact else Tokens.px("space-3"))
	add_theme_stylebox_override("panel", s)
	position.y = 0
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE * (1.05 if on else 1.0), 0.15).set_trans(Tween.TRANS_BACK)
	pivot_offset = size * 0.5


func _draw() -> void:
	if has_focus():
		draw_style_box(UiFocus.ring("radius-lg"), Rect2(Vector2.ZERO, size))


func _gui_input(event: InputEvent) -> void:
	# a tap arrives as a touch AND as a mouse click: take one, or it fires twice
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()
	elif event.is_action_pressed("ui_accept") and not event.is_echo():
		Input.action_release("jump")
		pressed.emit()
		accept_event()
