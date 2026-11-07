class_name Pus
extends RefCounted
## The grey Pus that steals color. One global amount drives every toon
## material (see toon.gdshader). The game's key visual reward is turning it down.

static var amount := 0.0


static func set_amount(v: float) -> void:
	amount = clampf(v, 0.0, 1.0)
	RenderingServer.global_shader_parameter_set("pus_amount", amount)


## Smoothly change the Pus over `seconds` (needs a node to own the tween).
static func fade_to(owner: Node, target: float, seconds: float) -> Tween:
	var tw := owner.create_tween()
	tw.tween_method(set_amount, amount, target, seconds)
	return tw
