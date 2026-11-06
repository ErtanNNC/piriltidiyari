class_name UiKit
extends RefCounted
## Design-system building blocks for Godot UI. Everything reads tokens:
## 3px outline contour, flat hard drop shadow (shadow-pop), rounded corners.


## A toy-like box: fill + outline contour + optional hard bottom "pop" shadow.
## The pop shadow is drawn as a thicker bottom border in the outline color,
## which gives the unblurred toy shadow from the design system.
static func box(fill: Color, radius_token := "radius-lg", pop := 0.0, border := -1.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = Tokens.color("outline")
	var b := Tokens.px("stroke-ui") if border < 0.0 else border
	s.set_border_width_all(int(b))
	s.border_width_bottom = int(b + pop)
	s.set_corner_radius_all(int(Tokens.px(radius_token)))
	s.anti_aliasing = true
	return s


static func panel_style(float_shadow := true) -> StyleBoxFlat:
	var s := box(Tokens.color("panel"), "radius-lg")
	s.set_content_margin_all(Tokens.px("space-4"))
	if float_shadow:
		s.shadow_color = Tokens.color("outline")
		s.shadow_color.a = 0.18
		s.shadow_offset = Vector2(0, 8)
		s.shadow_size = 1
	return s


static func label(text: String, style := "text-body", col_token := "ink") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Tokens.font_for(style))
	l.add_theme_font_size_override("font_size", Tokens.type_size(style))
	l.add_theme_color_override("font_color", Tokens.color(col_token))
	return l


## A number with the text-number outline (for counters drawn over the scene).
static func outlined(l: Label, size := 8) -> Label:
	l.add_theme_color_override("font_outline_color", Tokens.color("outline"))
	l.add_theme_constant_override("outline_size", size)
	return l


## GameButton: honey (primary) or panel (secondary), 48px+ touch target,
## pressed state slides 2px down and the shadow shrinks from 4px to 2px.
static func button(text: String, primary := true) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 56)
	b.focus_mode = Control.FOCUS_NONE
	var fill := Tokens.color("honey") if primary else Tokens.color("panel")
	var normal := box(fill, "radius-md", 4.0)
	normal.content_margin_left = 20
	normal.content_margin_right = 20
	normal.content_margin_top = Tokens.px("space-3")
	normal.content_margin_bottom = Tokens.px("space-3")
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = fill.lightened(0.12)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Tokens.color("honey-deep") if primary else Tokens.color("panel-sunken")
	pressed.border_width_bottom = int(Tokens.px("stroke-ui") + 2)
	pressed.expand_margin_top = -2
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var ink := Tokens.color("on-color") if primary else Tokens.color("ink")
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, ink)
	b.add_theme_font_override("font", Tokens.font_for("text-label"))
	b.add_theme_font_size_override("font_size", 20)
	return b
