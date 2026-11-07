class_name DialogBox
extends Control
## DialogBox: bottom of the screen over a scrim. Speaker name in a pill of the
## speaker's color, portrait circle, body text (max 2 lines), and a ▶ hint.
## Tap / E / Space advances; the first press finishes the typewriter.

signal finished

const CHARS_PER_SEC := 45.0

var _lines: Array = []
var _index := 0
var _then: Dictionary = {}
var _scrim: ColorRect
var _panel: PanelContainer
var _name_pill: PanelContainer
var _name: Label
var _portrait: Panel
var _portrait_letter: Label
var _body: Label
var _next: GameIcon
var _typing: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_scrim = ColorRect.new()
	_scrim.color = Tokens.color("scrim")
	_scrim.color.a *= 0.55
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scrim)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiKit.panel_style())
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.custom_minimum_size = Vector2(820, 150)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_bottom = -Tokens.px("space-6")
	_panel.offset_left = -410
	_panel.offset_right = 410
	add_child(_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(Tokens.px("space-4")))
	_panel.add_child(row)
	_portrait = Panel.new()
	_portrait.custom_minimum_size = Vector2(96, 96)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_portrait)
	_portrait_letter = UiKit.label("", "text-title", "on-color")
	_portrait_letter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait.add_child(_portrait_letter)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	row.add_child(col)
	_name_pill = PanelContainer.new()
	_name_pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(_name_pill)
	_name = UiKit.label("", "text-heading", "on-color")
	_name_pill.add_child(_name)
	_body = UiKit.label("", "text-body", "ink")
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(560, 56)
	_body.max_lines_visible = 2
	col.add_child(_body)

	_next = GameIcon.new()
	_next.kind = "spark"
	_next.fill = Tokens.color("honey")
	_next.custom_minimum_size = Vector2(28, 28)
	_next.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(_next)


func open(lines: Array, then: Dictionary) -> void:
	if lines.is_empty():
		return
	_lines = lines
	_then = then
	_index = 0
	visible = true
	Audio.play("pop")
	_show_line()


func is_open() -> bool:
	return visible


func advance() -> void:
	if _typing and _typing.is_running():
		_typing.kill()
		_body.visible_ratio = 1.0
		_next.visible = true
		return
	_index += 1
	if _index >= _lines.size():
		visible = false
		GameState.apply_dialogue_effects(_then)
		finished.emit()
	else:
		_show_line()


func _show_line() -> void:
	var line: Dictionary = _lines[_index]
	Audio.play("blip")
	var sp := Content.speaker(line.get("speaker", ""))
	var c := Tokens.color(sp["color"])
	_name.text = sp["name"]
	var pill := UiKit.box(c, "radius-pill", 0.0)
	pill.content_margin_left = 14
	pill.content_margin_right = 14
	pill.content_margin_top = 2
	pill.content_margin_bottom = 2
	_name_pill.add_theme_stylebox_override("panel", pill)
	_portrait.add_theme_stylebox_override("panel", UiKit.box(c, "radius-pill", 4.0))
	_portrait_letter.text = String(sp["name"]).left(1)
	_body.text = line.get("text", "")
	_body.visible_ratio = 0.0
	_next.visible = false
	_typing = create_tween()
	_typing.tween_property(_body, "visible_ratio", 1.0, _body.text.length() / CHARS_PER_SEC)
	_typing.tween_callback(func() -> void: _next.visible = true)
	if DevTools.auto_dialogue:
		var shown := _index
		await get_tree().create_timer(_body.text.length() / CHARS_PER_SEC + 1.4).timeout
		if visible and _index == shown:
			advance()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("interact") or event.is_action_pressed("jump")):
		advance()
		get_viewport().set_input_as_handled()
