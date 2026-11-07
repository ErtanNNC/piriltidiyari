class_name TouchControls
extends Control
## Mobile controls: a virtual joystick (left) and big Zıpla / Saldır buttons
## (right), all 48px+ targets. Shown only on touch screens, or with
## `-- --touch` on the command line for previews.

var _stick_center := Vector2.ZERO
var _stick_vec := Vector2.ZERO
var _stick_touch := -1
const STICK_RADIUS := 80.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = OS.has_feature("mobile") or OS.get_cmdline_user_args().has("--touch") \
		or (OS.has_feature("web") and DisplayServer.is_touchscreen_available())
	if not visible:
		return
	var m := Tokens.px("space-6")
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.offset_right = -m
	box.offset_bottom = -m
	box.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	add_child(box)
	for spec in [["At", "shoot", false], ["Dönüş", "skill", false], ["Yuvarlan", "roll", false], ["Saldır", "attack", false], ["Zıpla", "jump", true]]:
		var b := UiKit.button(spec[0], spec[2])
		if spec[1] == "shoot":
			# only with the Işık Sapanı; shows how many seeds are left
			var refresh_shot := func() -> void:
				var d := GameState.data
				b.visible = d.has_flag("owned_isik_sapani")
				b.text = "At (%d)" % d.item_count("isik_tohumu")
			refresh_shot.call()
			GameState.data.items_changed.connect(refresh_shot)
			GameState.data.flags_changed.connect(refresh_shot)
		if spec[1] == "skill":
			var refresh := func() -> void:
				var sk := GameState.data.active_skill()
				b.visible = sk != ""
				if sk != "":
					b.text = Skills.DEFS[sk]["short"]
			refresh.call()
			GameState.data.skills_changed.connect(refresh)
		b.custom_minimum_size = Vector2(132, 72)
		var action: String = spec[1]
		# Send a real input event (like a key press), not just the action
		# state: attack/roll/skill listen for events, jump polls the state.
		b.button_down.connect(func() -> void: _send(action, true))
		b.button_up.connect(func() -> void: _send(action, false))
		box.add_child(b)
	_stick_center = Vector2(m + STICK_RADIUS + 20, 0)


static func _send(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var left_half: bool = event.position.x < get_viewport_rect().size.x * 0.4
		if event.pressed and _stick_touch == -1 and left_half:
			_stick_touch = event.index
			_stick_center = event.position
			_set_stick(Vector2.ZERO)
		elif not event.pressed and event.index == _stick_touch:
			_stick_touch = -1
			_set_stick(Vector2.ZERO)
	elif event is InputEventScreenDrag and event.index == _stick_touch:
		_set_stick((event.position - _stick_center).limit_length(STICK_RADIUS) / STICK_RADIUS)


func _set_stick(v: Vector2) -> void:
	_stick_vec = v
	for pair in [["move_left", -v.x], ["move_right", v.x], ["move_forward", -v.y], ["move_back", v.y]]:
		if pair[1] > 0.15:
			Input.action_press(pair[0], pair[1])
		else:
			Input.action_release(pair[0])
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var c := _stick_center
	if _stick_touch == -1:
		c = Vector2(Tokens.px("space-6") + STICK_RADIUS + 20, size.y - Tokens.px("space-6") - STICK_RADIUS - 20)
	var ring := Tokens.color("panel")
	ring.a = 0.55
	draw_circle(c, STICK_RADIUS, ring)
	draw_circle(c, STICK_RADIUS, Tokens.color("outline"), false, Tokens.px("stroke-ui"), true)
	var knob := c + _stick_vec * STICK_RADIUS * 0.6
	draw_circle(knob, 34, Tokens.color("honey"))
	draw_circle(knob, 34, Tokens.color("outline"), false, Tokens.px("stroke-ui"), true)
