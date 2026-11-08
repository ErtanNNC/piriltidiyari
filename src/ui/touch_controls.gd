class_name TouchControls
extends Control
## Mobile controls, laid out like action games on phones:
##   left side   - a floating joystick wherever the thumb lands
##   bottom right - a big round Vur button with the other actions on an arc
##                 around it (Zıpla, Yuvarlan, the keeper's skill, both
##                 level-up powers, the sling)
##   anywhere else on the right - drag to turn the camera around the keeper
##                 (sideways) and tilt it (up / down)
## Shown only on touch screens, or with `-- --touch` for previews. Keeps
## running while the game is paused, so a finger lifted during a pause
## (level-up cards, Mola) is never lost; `release_all()` clears everything.

const STICK_RADIUS := 80.0
const MAIN_R := 74.0        # Vur button radius
const SMALL_R := 42.0       # the arc buttons
const ARC_DIST := 138.0     # from the Vur button's center
const CAM_SPEED := 0.0065   # radians per pixel dragged sideways
const TILT_SPEED := 0.08    # degrees per pixel dragged up / down

var power_buttons: Array[Button] = []

var _stick_center := Vector2.ZERO
var _stick_vec := Vector2.ZERO
var _stick_touch := -1
var _cam_touch := -1
var _cam_last := Vector2.ZERO
var _round: Array[Button] = []
var _held: Dictionary = {}   # action -> true while a button holds it


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = OS.has_feature("mobile") or OS.get_cmdline_user_args().has("--touch") \
		or (OS.has_feature("web") and DisplayServer.is_touchscreen_available())
	if not visible:
		return
	var main := _round_button("Vur", "attack", MAIN_R, "honey", 26)
	# arc slots: angle in degrees (0 = right, 90 = down, 180 = left, 270 = up)
	var jump := _round_button("Zıpla", "jump", SMALL_R, "sky", 18)
	var roll := _round_button("Yuvarlan", "roll", SMALL_R, "panel", 15)
	var skill := _round_button("", "skill", SMALL_R, "spark-purple", 15)
	var p1 := _round_button("", "power_1", SMALL_R, "berry", 14)
	var p2 := _round_button("", "power_2", SMALL_R, "berry", 14)
	var shoot := _round_button("At", "shoot", SMALL_R, "spark-green", 15)
	power_buttons = [p1, p2]
	for b in [p1, p2]:
		b.visible = false
	_place(main, 0.0, 0.0)
	_place(jump, 180.0, ARC_DIST)
	_place(roll, 270.0, ARC_DIST)
	_place(skill, 225.0, ARC_DIST)
	_place(p1, 195.0, ARC_DIST * 1.78)
	_place(p2, 238.0, ARC_DIST * 1.78)
	_place(shoot, 275.0, ARC_DIST * 1.78)
	var refresh_shot := func() -> void:
		var d := GameState.data
		shoot.visible = d.has_flag("owned_isik_sapani")
		shoot.text = TranslationServer.translate("At\n%d") % d.item_count("isik_tohumu")
	refresh_shot.call()
	GameState.data.items_changed.connect(refresh_shot)
	GameState.data.flags_changed.connect(refresh_shot)
	var refresh_skill := func() -> void:
		var sk := GameState.data.active_skill()
		skill.visible = sk != ""
		if sk != "":
			skill.text = Skills.DEFS[sk]["short"]
	refresh_skill.call()
	GameState.data.skills_changed.connect(refresh_skill)
	_stick_center = Vector2(Tokens.px("space-6") + STICK_RADIUS + 20, 0)


## A round button that sends `action` while held.
func _round_button(text: String, action: String, r: float, fill: String, font: int) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(r, r) * 2.0
	b.size = Vector2(r, r) * 2.0
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", font)
	b.add_theme_color_override("font_color", Tokens.color("on-color") if fill != "panel" else Tokens.color("ink"))
	b.add_theme_color_override("font_pressed_color", Tokens.color("on-color") if fill != "panel" else Tokens.color("ink"))
	b.add_theme_color_override("font_hover_color", Tokens.color("on-color") if fill != "panel" else Tokens.color("ink"))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var c := Tokens.color(fill)
		if state == "pressed":
			c = c.darkened(0.15)
		var st := UiKit.box(c, "radius-pill", 0.0 if state == "pressed" else 4.0)
		st.set_corner_radius_all(int(r))
		st.bg_color.a = 0.9
		b.add_theme_stylebox_override(state, st)
	b.set_meta("action", action)
	b.set_meta("radius", r)
	b.button_down.connect(func() -> void:
		_held[action] = true
		_send(action, true))
	b.button_up.connect(func() -> void:
		_held.erase(action)
		_send(action, false))
	add_child(b)
	_round.append(b)
	return b


## Puts a button `dist` px from the Vur button's center at `deg`.
func _place(b: Button, deg: float, dist: float) -> void:
	b.set_meta("deg", deg)
	b.set_meta("dist", dist)
	_layout_one(b)


func _layout_one(b: Button) -> void:
	# inside this control's own rect (the HUD already keeps it within the
	# phone's safe area), with extra room for rounded screen corners
	var m := Tokens.px("space-6") + 14.0
	var area := size if size.x > 10.0 else (get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720))
	var center := Vector2(area.x - m - MAIN_R, area.y - m - MAIN_R)
	var a := deg_to_rad(float(b.get_meta("deg")))
	var c := center + Vector2(cos(a), sin(a)) * float(b.get_meta("dist"))
	var r: float = b.get_meta("radius")
	b.position = c - Vector2(r, r)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		for b in _round:
			_layout_one(b)


static func _send(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)


## Lets go of everything (the stick, held buttons, a camera drag).
func release_all() -> void:
	_stick_touch = -1
	_cam_touch = -1
	_set_stick(Vector2.ZERO)
	for action: String in _held.keys():
		_send(action, false)
	_held.clear()


func _on_round_button(p: Vector2) -> bool:
	for b in _round:
		if b.visible and p.distance_to(b.global_position + b.size * 0.5) <= float(b.get_meta("radius")) + 6.0:
			return true
	return false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var vp := get_viewport_rect().size
	if event is InputEventScreenTouch:
		var p: Vector2 = event.position
		if event.pressed:
			var paused := get_tree().paused
			if _stick_touch == -1 and p.x < vp.x * 0.4 and not paused and p.y > 120.0:
				_stick_touch = event.index
				_stick_center = p
				_set_stick(Vector2.ZERO)
			elif _cam_touch == -1 and p.x >= vp.x * 0.4 and not paused and p.y > 110.0 \
					and (p.x > vp.x * 0.62 or p.y < vp.y - 110.0) and not _on_round_button(p):
				_cam_touch = event.index
				_cam_last = p
		else:
			if event.index == _stick_touch:
				_stick_touch = -1
				_set_stick(Vector2.ZERO)
			if event.index == _cam_touch:
				_cam_touch = -1
	elif event is InputEventScreenDrag:
		if event.index == _stick_touch:
			_set_stick((event.position - _stick_center).limit_length(STICK_RADIUS) / STICK_RADIUS)
		elif event.index == _cam_touch:
			var d: Vector2 = event.position - _cam_last
			_cam_last = event.position
			var cam := get_viewport().get_camera_3d() as FollowCamera
			if cam:
				cam.drag(d.x * CAM_SPEED, d.y * TILT_SPEED)


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
