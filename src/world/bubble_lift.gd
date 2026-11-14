class_name BubbleLift
extends Node3D
## Mercan Bahçesi: a column of bubbles that carries the keeper up to a
## higher terrace. Stand in it and you rise; near the top it pushes you
## `out` over the edge and holds you up until you are above solid ground.
## The scene calls `carry()` every physics frame and adds what it returns to
## `Player.wind` (the player script is not touched).

const RISE := 5.0        ## m/s upward inside the column
const PUSH := 4.5        ## m/s sideways at the top
const OVER := 0.9        ## how far above `height` the push begins
const REACH := 2.6       ## the push goes on this far outside the column

## How much higher the upper terrace is than the lift's own floor.
var height := 3.0
var radius := 1.6
## Unit vector toward the upper terrace.
var out := Vector3.FORWARD
var color := Color(0.75, 1.0, 1.0)
## True while the keeper is being carried (the scene's first-ride bark).
var carrying := false


func _ready() -> void:
	add_to_group("bubble_lift")
	Toon.part(self, "ring", Vector3(radius * 2.0, 0.12, radius * 2.0), color, Vector3(0, 0.08, 0), Vector3.ZERO, 1.6, 0.0)
	Toon.part(self, "cylinder", Vector3(radius * 1.7, 0.04, radius * 1.7), Color(0.55, 0.9, 0.95), Vector3(0, 0.03, 0), Vector3.ZERO, 0.8, 0.0)
	var p := CPUParticles3D.new()
	p.amount = int(10 + height * 5.0)
	p.lifetime = (height + 2.0) / 2.6
	p.preprocess = p.lifetime
	p.lifetime_randomness = 0.25
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius * 0.7
	p.position.y = 0.3
	p.direction = Vector3.UP
	p.spread = 4.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 2.2
	p.initial_velocity_max = 3.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.5
	var q := QuadMesh.new()
	q.size = Vector2(0.34, 0.34)
	q.material = bubble_material()
	p.mesh = q
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.1, 0.8, 1.0])
	g.colors = PackedColorArray([Color(color, 0.0), Color(color, 0.9), Color(color, 0.8), Color(color, 0.0)])
	p.color_ramp = g
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	# a faint shaft so the column reads from the top-down camera
	var shaft := Toon.part(self, "cylinder", Vector3(radius * 1.5, height + 1.5, radius * 1.5), color, Vector3(0, (height + 1.5) * 0.5, 0), Vector3.ZERO, 0.0, 0.0)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(color.r, color.g, color.b, 0.07)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	shaft.material_override = m
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## A round bubble: a soft ring with a clear middle (shared by every lift,
## the gate and the drifting bubbles).
static var _bubble_mat: StandardMaterial3D


static func bubble_material() -> StandardMaterial3D:
	if _bubble_mat:
		return _bubble_mat
	var n := 48
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (x + 0.5) / n * 2.0 - 1.0
			var v := (y + 0.5) / n * 2.0 - 1.0
			var r := sqrt(u * u + v * v)
			var a := clampf(1.0 - absf(r - 0.8) * 7.0, 0.0, 1.0) * 0.9
			a = maxf(a, 0.16 if r < 0.8 else 0.0)
			# a small shine up left
			a = maxf(a, clampf(1.0 - Vector2(u + 0.35, v + 0.35).length() * 5.0, 0.0, 1.0))
			img.set_pixel(x, y, Color(1, 1, 1, a))
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	_bubble_mat = m
	return m


## Lifts `p` when it stands in the column; returns the sideways push to add
## to the keeper's `wind` this frame.
func carry(p: Player, delta: float) -> Vector3:
	var rel := p.global_position - global_position
	var flat := Vector3(rel.x, 0.0, rel.z)
	var d := flat.length()
	carrying = false
	if rel.y < -0.6 or rel.y > height + 3.0 or p.climbing:
		return Vector3.ZERO
	var top := height + OVER
	if d < radius:
		carrying = true
		# rise, then hover a little above the upper floor
		var want := RISE if rel.y < top + 0.4 else 0.0
		p.velocity.y = move_toward(p.velocity.y, want, 40.0 * delta) if p.velocity.y < want else p.velocity.y
		if rel.y < top:
			# keep to the middle on the way up (never under a ledge)
			return -flat.normalized() * 1.5 if d > 0.35 else Vector3.ZERO
		return out * PUSH
	# out of the column near the top: carried on until over the terrace
	if d < radius + REACH and rel.y > height + 0.15 and not p.is_on_floor():
		carrying = true
		p.velocity.y = maxf(p.velocity.y, -0.6)
		return out * PUSH
	return Vector3.ZERO
