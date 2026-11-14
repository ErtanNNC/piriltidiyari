class_name UiFocus
extends Node
## Gamepad / keyboard focus for the menus. One node on the root (made by
## UiKit the first time a menu button is built) that:
##   - remembers whether the last input was a pad/key (`pad`) or a touch/mouse,
##     so the focus ring only ever shows for players who steer with buttons;
##   - finds the menu on top (a Control marked with `UiKit.menu`, or any
##     full-screen blocking Control that holds menu buttons) and keeps the
##     focus inside it: first focus when it opens, the nearest button when the
##     focused one is rebuilt (shop rows, save slot confirms);
##   - lets ui_cancel press the menu's back/close button;
##   - never leaves a focus on a button outside a menu (in play), so Space or
##     the A button can't press it again.
## A dialogue takes the accept key for itself: no focus while one is open.

static var pad := false

static var _inst: UiFocus
static var _items: Array = []   # focusable menu controls (buttons, cards)
static var _rings: Array = []   # shared focus styleboxes, hidden for touch

var _last_top: Control
var _last_pos := Vector2.ZERO
var _last_time := 0
var _prune := 0


## A control the menus may focus (UiKit.button does this by itself).
static func track(c: Control) -> void:
	c.set_meta("ui_item", true)
	_items.append(c)
	ensure()


static func ensure() -> void:
	if _inst != null and is_instance_valid(_inst):
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	_inst = UiFocus.new()
	_inst.name = "UiFocus"
	tree.root.add_child.call_deferred(_inst)


## The focus ring: a honey-deep frame just outside the control's own outline.
## One shared box per corner radius; invisible while the player uses touch.
static func ring(radius_token := "radius-md") -> StyleBoxFlat:
	for r: StyleBoxFlat in _rings:
		if r.get_meta("radius") == radius_token:
			return r
	var s := StyleBoxFlat.new()
	s.set_meta("radius", radius_token)
	s.draw_center = false
	s.set_border_width_all(5)
	s.set_expand_margin_all(6)
	s.set_corner_radius_all(int(Tokens.px(radius_token)) + 6)
	s.anti_aliasing = true
	s.border_color = _ring_color()
	_rings.append(s)
	return s


static func _ring_color() -> Color:
	var c := Tokens.color("honey-deep")
	c.a = 1.0 if pad else 0.0
	return c


static func _set_pad(on: bool) -> void:
	if pad == on:
		return
	pad = on
	for r: StyleBoxFlat in _rings:
		r.border_color = _ring_color()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton:
		_set_pad(false)
	elif event is InputEventKey:
		# the phone's back key is not a keyboard
		if event.pressed and event.keycode != KEY_BACK:
			_set_pad(true)
	elif event is InputEventJoypadButton:
		if event.pressed:
			_set_pad(true)
	elif event is InputEventJoypadMotion:
		if absf(event.axis_value) > 0.5:
			_set_pad(true)
	if pad and event.is_action_pressed("ui_cancel") and not _dialog_open():
		var top := _top_menu()
		if top != null and top.has_meta("ui_back"):
			var back: Variant = top.get_meta("ui_back")
			if is_instance_valid(back) and back is BaseButton and _usable(back):
				get_viewport().set_input_as_handled()
				(back as BaseButton).pressed.emit()


func _process(_delta: float) -> void:
	_prune += 1
	if _prune >= 120:
		_prune = 0
		_items = _items.filter(func(c: Variant) -> bool: return is_instance_valid(c))
	var cur := get_viewport().gui_get_focus_owner()
	if not pad and (cur == null or not cur.has_meta("ui_item")):
		return
	if _dialog_open():
		if cur != null and cur.has_meta("ui_item"):
			cur.release_focus()
		return
	var top := _top_menu()
	if cur != null and top != null and top.is_ancestor_of(cur) and cur.is_visible_in_tree() \
			and not (cur is BaseButton and (cur as BaseButton).disabled):
		_last_top = top
		_last_pos = cur.get_global_rect().get_center()
		_last_time = Time.get_ticks_msec()
		return
	if cur != null and cur.has_meta("ui_item") and (top == null or not pad):
		# a menu button outside the menu on top (or in play): let go of it
		cur.release_focus()
		return
	if top == null or not pad:
		return
	var pick := _first(top)
	if pick != null:
		pick.grab_focus()


func _dialog_open() -> bool:
	for d in get_tree().get_nodes_in_group("ui_dialog"):
		if (d as Control).is_visible_in_tree():
			return true
	return false


static func _usable(c: Variant) -> bool:
	if not is_instance_valid(c) or not (c is Control):
		return false
	var k := c as Control
	if not k.is_inside_tree() or k.is_queued_for_deletion() or k.focus_mode == Control.FOCUS_NONE \
			or not k.is_visible_in_tree():
		return false
	return not (k is BaseButton and (k as BaseButton).disabled)


## The menu a control belongs to: the nearest marked ancestor, else the
## nearest full-screen Control that blocks the mouse (a modal built elsewhere).
static func _menu_of(c: Control) -> Control:
	var n := c.get_parent()
	while n != null:
		if n is Control:
			var k := n as Control
			if k.has_meta("ui_menu"):
				return k
			if k.mouse_filter == Control.MOUSE_FILTER_STOP:
				var p := k.get_parent()
				var full: Vector2 = (p as Control).size if p is Control else k.get_viewport_rect().size
				if k.size.x >= full.x - 2.0 and k.size.y >= full.y - 2.0 and full.x > 100.0:
					return k
		n = n.get_parent()
	return null


static func _layer(c: Node) -> int:
	var n := c
	while n != null:
		if n is CanvasLayer:
			return (n as CanvasLayer).layer
		n = n.get_parent()
	return 0


func _top_menu() -> Control:
	var best: Control = null
	var best_layer := 0
	for c: Variant in _items:
		if not _usable(c):
			continue
		var m := _menu_of(c)
		if m == null or m == best:
			continue
		var l := _layer(m)
		if best == null or l > best_layer or (l == best_layer and m.is_greater_than(best)):
			best = m
			best_layer = l
	return best


## Where the focus starts in `top`: the control the menu named, the one
## nearest to where the focus just was (a rebuilt row), the first honey
## button, or simply the first one.
func _first(top: Control) -> Control:
	var list: Array[Control] = []
	for c: Variant in _items:
		if _usable(c) and top.is_ancestor_of(c):
			list.append(c)
	if list.is_empty():
		return null
	var recent := Time.get_ticks_msec() - _last_time < 400
	var same := is_instance_valid(_last_top) and _last_top == top
	if recent and same:
		var near: Control = list[0]
		for c in list:
			if c.get_global_rect().get_center().distance_squared_to(_last_pos) \
					< near.get_global_rect().get_center().distance_squared_to(_last_pos):
				near = c
		return near
	if top.has_meta("ui_first"):
		var f: Variant = top.get_meta("ui_first")
		if _usable(f):
			return f
	var first: Control = null
	var primary: Control = null
	for c in list:
		if first == null or first.is_greater_than(c):
			first = c
		if c.get_meta("ui_primary", false) and (primary == null or primary.is_greater_than(c)):
			primary = c
	return primary if primary != null else first
