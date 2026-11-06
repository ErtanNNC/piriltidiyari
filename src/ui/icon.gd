@tool
class_name GameIcon
extends Control
## Simple placeholder icons on the 24px grid until the real icon set exists:
## heart (hp), drop (mp), star (xp), piril, lantern, spark, quest (!), check.
## Fill + outline, 2px stroke-icon, round joins — max two colors.

@export_enum("heart", "drop", "star", "piril", "lantern", "spark", "quest", "check") var kind := "heart":
	set(v):
		kind = v
		queue_redraw()
@export var fill := Color("#e5484d"):
	set(v):
		fill = v
		queue_redraw()
@export var outline_color := Color("#2a2140")
@export var stroke := 2.0


func _init() -> void:
	custom_minimum_size = Vector2(24, 24)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var s := minf(size.x, size.y) / 24.0
	var o := (size - Vector2(24, 24) * s) * 0.5
	var pts := PackedVector2Array()
	match kind:
		"heart":
			for i in 40:
				var t := TAU * i / 40.0
				var x := 16.0 * pow(sin(t), 3)
				var y := 13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t)
				pts.append(Vector2(12 + x * 0.6, 12.5 - y * 0.6))
		"drop", "piril":
			for i in 33:
				var a := -PI * 0.25 + PI * 1.5 * i / 32.0
				pts.append(Vector2(12 + cos(a) * 7.0, 14 + sin(a) * 7.0))
			pts.append(Vector2(12, 2.5))
		"star", "spark":
			var n := 5 if kind == "star" else 4
			for i in n * 2:
				var r := 10.0 if i % 2 == 0 else (4.4 if kind == "star" else 3.6)
				var a := -PI / 2 + PI * i / n
				pts.append(Vector2(12 + cos(a) * r, 12.8 + sin(a) * r))
		"lantern":
			for i in 32:
				var a := TAU * i / 32.0
				pts.append(Vector2(12 + cos(a) * 7.0, 14 + sin(a) * 7.5))
		"quest":
			pts = PackedVector2Array([Vector2(9, 3), Vector2(15, 3), Vector2(14, 15), Vector2(10, 15)])
		"check":
			pts = PackedVector2Array([Vector2(3, 12), Vector2(7, 8), Vector2(10, 11), Vector2(17, 4), Vector2(21, 8), Vector2(10, 19)])
	for i in pts.size():
		pts[i] = o + pts[i] * s
	draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, outline_color, stroke * s, true)
	if kind == "quest":
		draw_circle(o + Vector2(12, 19.5) * s, 2.6 * s, fill)
		draw_circle(o + Vector2(12, 19.5) * s, 2.6 * s, outline_color, false, stroke * s, true)
	elif kind == "piril":
		draw_circle(o + Vector2(10, 12) * s, 1.8 * s, Color(1, 1, 1, 0.9))
	elif kind == "lantern":
		draw_rect(Rect2(o + Vector2(8, 3.5) * s, Vector2(8, 3) * s), outline_color)
