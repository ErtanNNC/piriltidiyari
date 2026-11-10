class_name StatBar
extends Control
## StatBar: icon + outlined bar + number. Color never carries meaning alone:
## the icon and the number are always there.

@export_enum("hp", "mp", "xp", "anger", "shiver") var stat := "hp"
var value := 1.0
var max_value := 1.0
var _icon: GameIcon
var _text := ""


func _ready() -> void:
	custom_minimum_size = Vector2(220, 30)
	_icon = GameIcon.new()
	_icon.kind = {"hp": "heart", "mp": "drop", "xp": "star", "anger": "spark", "shiver": "drop"}[stat]
	_icon.fill = Tokens.color(_token())
	_icon.outline_color = Tokens.color("outline")
	_icon.position = Vector2(0, 1)
	_icon.size = Vector2(28, 28)
	add_child(_icon)


## The color token of the fill: the stat's own, berry for the Öfke barı.
func _token() -> String:
	return {"anger": "berry", "shiver": "sky"}.get(stat, stat)


func set_values(v: float, m: float, text := "") -> void:
	value = v
	max_value = maxf(m, 1.0)
	_text = text if text != "" else "%d/%d" % [roundi(v), roundi(m)]
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2(34, 4), Vector2(size.x - 34, size.y - 8))
	var track := UiKit.box(Tokens.color("panel-sunken"), "radius-pill")
	draw_style_box(track, r)
	var ratio := clampf(value / max_value, 0.0, 1.0)
	if ratio > 0.0:
		var fill := UiKit.box(Tokens.color(_token()), "radius-pill")
		draw_style_box(fill, Rect2(r.position, Vector2(maxf(r.size.y, r.size.x * ratio), r.size.y)))
	var font := Tokens.font_for("text-caption")
	var fs := Tokens.type_size("text-caption")
	var pos := Vector2(r.position.x + 10, r.position.y + r.size.y * 0.5 + fs * 0.36)
	# Text over the colored fill is on-color (always dark). If the fill is too
	# short to hold the number, it sits on the empty track: use ink instead
	# (light in the Gece theme).
	var text_w := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var on_fill := r.size.x * ratio >= text_w + 16.0
	draw_string(font, pos, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Tokens.color("on-color") if on_fill else Tokens.color("ink"))
