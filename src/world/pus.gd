class_name Pus
extends RefCounted
## The grey Pus that steals color. One global amount drives every toon
## material (see toon.gdshader). The game's key visual reward is turning it down.

static var amount := 0.0


## The grey Pus of season 1, and the warm Kızıl Sis of season 2 (Kor Vadisi).
const GREY := Color(0.92, 0.91, 0.98)
const RED := Color(1.18, 0.74, 0.66)


## Which mist tints the world: Pus.GREY or Pus.RED (SceneFlow resets it to grey).
static func set_color(c: Color) -> void:
	RenderingServer.global_shader_parameter_set("pus_color", Vector3(c.r, c.g, c.b))


static func set_amount(v: float) -> void:
	amount = clampf(v, 0.0, 1.0)
	RenderingServer.global_shader_parameter_set("pus_amount", amount)


## Smoothly change the Pus over `seconds` (needs a node to own the tween).
static func fade_to(owner: Node, target: float, seconds: float) -> Tween:
	var tw := owner.create_tween()
	tw.tween_method(set_amount, amount, target, seconds)
	return tw
