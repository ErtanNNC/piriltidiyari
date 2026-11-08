class_name Prop
extends Node3D
## Greybox village pieces. Place them in a level scene and pick `kind`;
## real art replaces them later without moving anything.

@export_enum("house", "tower", "tree", "big_tree", "well", "flowers", "lantern_post", "bush", "fence", "low_beam", "rock") var kind := "house"
@export var length := 6.0   ## fence length (m), along local X
@export var accent := "berry"   ## design-system color token for roofs, flowers, lights


func _ready() -> void:
	match kind:
		"house": _house()
		"tower": _tower()
		"tree": _tree(1.0)
		"big_tree": _tree(1.8)
		"well": _well()
		"flowers": _flowers()
		"lantern_post": _lantern_post()
		"bush": _bush()
		"fence": _fence()
		"low_beam": _low_beam()
		"rock": _rock()
	_real_model()


## A real model (assets/models/prop_<kind>.glb) takes the primitive look's
## place; colliders, lights, smoke and the glowing parts stay.
func _real_model() -> void:
	var id: String = {"house": "prop_house", "tree": "prop_tree", "big_tree": "prop_tree", "well": "prop_well",
		"lantern_post": "prop_lantern", "bush": "prop_bush", "tower": "prop_tower"}.get(kind, "")
	if id == "":
		return
	var keep: Array = []
	for n in ["BuyukKivilcim", "Glow"]:
		var k := get_node_or_null(n)
		if k:
			keep.append(k)
	var roof: Variant = Tokens.color(accent) if kind in ["house", "well"] else null
	var m := PropModel.swap(self, id, keep, roof)
	if m and kind in ["tree", "big_tree"]:
		Sway.add(m, 0.014)


func _collider(radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = radius
	s.height = height
	c.shape = s
	c.position.y = height * 0.5
	body.add_child(c)
	add_child(body)


const WALL := Color("#fff3dc")
const WOOD := Color("#a86b45")
const WOOD_LIGHT := Color("#c98d5e")
const STONE := Color("#c9bfae")
const GLASS := Color("#ffe08a")


## A pivot turned to angle `deg` around the house; children at +Z face outward.
func _around(deg: float) -> Node3D:
	var n := Node3D.new()
	n.rotation_degrees.y = deg
	add_child(n)
	return n


## A round cottage: stone footing, timber band, two round lit windows with
## flower boxes, a framed door with a step and a lamp, a layered roof with a
## finial, and a brick chimney that puffs a little smoke.
func _house() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name) + hash(accent)
	var roof := Tokens.color(accent)
	# walls on a stone footing
	Toon.part(self, "cylinder", Vector3(3.5, 0.45, 3.6), STONE, Vector3(0, 0.22, 0))
	Toon.part(self, "cylinder", Vector3(3.0, 2.4, 3.2), WALL, Vector3(0, 1.4, 0))
	Toon.part(self, "ring", Vector3(3.24, 0.09, 3.24), WOOD_LIGHT, Vector3(0, 2.45, 0), Vector3.ZERO, 0.0, 0.02)
	# wooden posts around the wall
	for a in [60.0, 120.0, 240.0, 300.0]:
		var piv := _around(a)
		Toon.part(piv, "box", Vector3(0.16, 2.2, 0.08), WOOD_LIGHT, Vector3(0, 1.45, 1.53), Vector3(-2, 0, 0), 0.0, 0.02)
	# door: frame, panel, knob, step, little lamp
	var door := _around(0.0)
	Toon.part(door, "capsule", Vector3(1.15, 1.95, 0.3), WOOD_LIGHT, Vector3(0, 1.15, 1.48))
	Toon.part(door, "capsule", Vector3(0.9, 1.7, 0.3), WOOD, Vector3(0, 1.1, 1.56))
	Toon.part(door, "box", Vector3(0.04, 1.3, 0.04), WOOD.darkened(0.25), Vector3(-0.15, 1.05, 1.72), Vector3.ZERO, 0.0, 0.0)
	Toon.part(door, "box", Vector3(0.04, 1.3, 0.04), WOOD.darkened(0.25), Vector3(0.15, 1.05, 1.72), Vector3.ZERO, 0.0, 0.0)
	Toon.part(door, "sphere", Vector3(0.1, 0.1, 0.1), "honey", Vector3(0.28, 1.0, 1.74), Vector3.ZERO, 0.6, 0.015)
	Toon.part(door, "cylinder", Vector3(1.4, 0.18, 0.9), STONE, Vector3(0, 0.09, 1.9))
	Toon.part(door, "box", Vector3(0.05, 0.05, 0.35), "outline", Vector3(0.95, 2.35, 1.62), Vector3.ZERO, 0.0, 0.0)
	Toon.part(door, "cylinder", Vector3(0.03, 0.25, 0.03), "outline", Vector3(0.95, 2.22, 1.78), Vector3.ZERO, 0.0, 0.0)
	Toon.part(door, "sphere", Vector3(0.26, 0.32, 0.26), "honey", Vector3(0.95, 1.98, 1.8), Vector3.ZERO, 1.4, 0.02)
	# round windows with frames, warm glass, cross bars and flower boxes
	for a in [rng.randf_range(65, 85), rng.randf_range(-85, -65)]:
		var w := _around(a)
		Toon.part(w, "ring", Vector3(0.8, 0.08, 0.8), WOOD_LIGHT, Vector3(0, 1.75, 1.54), Vector3(90, 0, 0), 0.0, 0.02)
		Toon.part(w, "cylinder", Vector3(0.66, 0.05, 0.66), GLASS, Vector3(0, 1.75, 1.53), Vector3(90, 0, 0), 1.1, 0.0)
		Toon.part(w, "box", Vector3(0.66, 0.05, 0.03), WOOD, Vector3(0, 1.75, 1.57), Vector3.ZERO, 0.0, 0.0)
		Toon.part(w, "box", Vector3(0.05, 0.66, 0.03), WOOD, Vector3(0, 1.75, 1.57), Vector3.ZERO, 0.0, 0.0)
		Toon.part(w, "box", Vector3(0.8, 0.18, 0.24), WOOD_LIGHT, Vector3(0, 1.28, 1.62))
		for k in 3:
			Toon.part(w, "sphere", Vector3(0.17, 0.15, 0.17), ["berry", "spark-yellow", "sky", "spark-purple"][(k + int(a)) % 4],
				Vector3(-0.25 + k * 0.25, 1.43, 1.64), Vector3.ZERO, 0.1, 0.015)
	# layered roof: three tiers of shingles, a trim band and a finial
	Toon.part(self, "cylinder", Vector3(4.3, 0.18, 4.3), roof.darkened(0.15), Vector3(0, 2.65, 0))
	Toon.part(self, "cone", Vector3(4.2, 1.2, 4.2), roof, Vector3(0, 3.25, 0))
	Toon.part(self, "cone", Vector3(3.3, 1.1, 3.3), roof.lightened(0.12), Vector3(0, 3.85, 0))
	Toon.part(self, "cone", Vector3(2.2, 1.2, 2.2), roof, Vector3(0, 4.45, 0))
	Toon.part(self, "sphere", Vector3(0.36, 0.36, 0.36), "honey", Vector3(0, 5.12, 0), Vector3.ZERO, 0.5, 0.02)
	# a little dormer window in the roof
	var dorm := _around(rng.randf_range(150, 210))
	Toon.part(dorm, "box", Vector3(0.7, 0.6, 0.5), WALL, Vector3(0, 3.55, 1.15), Vector3(-10, 0, 0))
	Toon.part(dorm, "cylinder", Vector3(0.4, 0.04, 0.4), GLASS, Vector3(0, 3.58, 1.41), Vector3(80, 0, 0), 1.0, 0.0)
	Toon.part(dorm, "cone", Vector3(0.95, 0.5, 0.75), roof.darkened(0.1), Vector3(0, 4.05, 1.1))
	# brick chimney with a cap and smoke
	var ch := _around(rng.randf_range(120, 150))
	Toon.part(ch, "box", Vector3(0.5, 1.4, 0.5), Color("#c8735a"), Vector3(0, 4.3, 0.85))
	Toon.part(ch, "box", Vector3(0.62, 0.14, 0.62), "ink-muted", Vector3(0, 5.03, 0.85))
	for k in 3:
		Toon.part(ch, "box", Vector3(0.52, 0.04, 0.52), Color("#a85a46"), Vector3(0, 3.95 + k * 0.32, 0.85), Vector3.ZERO, 0.0, 0.0)
	_smoke(ch, Vector3(0, 5.2, 0.85))
	# a bush by the door
	Toon.part(door, "sphere", Vector3(0.8, 0.65, 0.7), "leaf", Vector3(-1.05, 0.35, 1.55))
	Toon.part(door, "sphere", Vector3(0.55, 0.5, 0.5), Color("#3fae5c"), Vector3(-1.4, 0.3, 1.2))
	_collider(1.6, 3.0)


## Slow soft puffs rising from a chimney (CPU particles, cheap).
func _smoke(parent: Node3D, at: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.amount = 6
	p.lifetime = 3.5
	p.preprocess = 3.5
	p.position = at
	p.direction = Vector3(0.3, 1, 0)
	p.spread = 12.0
	p.gravity = Vector3(0.15, 0.25, 0)
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 0.7
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(1, 1.6))
	p.scale_amount_curve = curve
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(0.95, 0.94, 1.0, 0.55), Color(1, 1, 1, 0)])
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(0.7, 0.7)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = Weather.texture("soft")
	q.material = m
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)


func _tower() -> void:
	# Fener Kulesi: stone base, three tiers with windows and balconies,
	# banners, a pointed roof and the Büyük Kıvılcım on top (same place).
	var wall := Color("#efe2c8")
	Toon.part(self, "cylinder", Vector3(5.2, 0.8, 5.6), STONE, Vector3(0, 0.4, 0))
	for i in 10:
		var piv := _around(i * 36.0)
		Toon.part(piv, "box", Vector3(0.9, 0.5, 0.3), STONE.darkened(0.08), Vector3(0, 0.42, 2.62), Vector3.ZERO, 0.0, 0.02)
	Toon.part(self, "cylinder", Vector3(4.0, 3.6, 4.6), wall, Vector3(0, 2.6, 0))
	Toon.part(self, "cylinder", Vector3(4.8, 0.5, 4.8), "honey-deep", Vector3(0, 4.2, 0))
	_rail(2.35, 4.45, 12)
	Toon.part(self, "cylinder", Vector3(3.2, 4.0, 3.8), wall, Vector3(0, 6.4, 0))
	Toon.part(self, "cylinder", Vector3(4.0, 0.5, 4.0), "honey-deep", Vector3(0, 8.6, 0))
	_rail(1.95, 8.85, 10)
	Toon.part(self, "cylinder", Vector3(2.6, 2.0, 2.8), wall, Vector3(0, 9.8, 0))
	Toon.part(self, "cylinder", Vector3(3.9, 0.2, 3.9), Color("#d65a7a"), Vector3(0, 10.85, 0))
	Toon.part(self, "cone", Vector3(3.6, 2.0, 3.6), "berry", Vector3(0, 11.8, 0))
	# windows on each tier
	for t: Array in [[3.0, 2.1, [50.0, 130.0, 230.0, 310.0]], [6.6, 1.72, [0.0, 90.0, 180.0, 270.0]], [9.9, 1.36, [45.0, 135.0, 225.0, 315.0]]]:
		for a: float in t[2]:
			var w := _around(a)
			Toon.part(w, "capsule", Vector3(0.6, 1.0, 0.2), WOOD, Vector3(0, t[0], t[1]), Vector3.ZERO, 0.0, 0.02)
			Toon.part(w, "capsule", Vector3(0.42, 0.8, 0.2), GLASS, Vector3(0, t[0], t[1] + 0.06), Vector3.ZERO, 1.0, 0.0)
	# banners hanging from the first balcony
	for a in [35.0, 145.0, 215.0, 325.0]:
		var b := _around(a)
		var cols := ["berry", "sky", "spark-yellow", "leaf"]
		Toon.part(b, "box", Vector3(0.6, 1.3, 0.05), cols[int(a) % 4], Vector3(0, 3.35, 2.36), Vector3(-4, 0, 0), 0.0, 0.02)
		Toon.part(b, "cone", Vector3(0.6, 0.35, 0.05), cols[int(a) % 4], Vector3(0, 2.55, 2.36), Vector3(180, 0, 0), 0.0, 0.02)
	Toon.part(self, "capsule", Vector3(1.3, 2.4, 0.4), WOOD_LIGHT, Vector3(0, 1.3, 2.25))
	Toon.part(self, "capsule", Vector3(1.0, 2.0, 0.4), WOOD, Vector3(0, 1.2, 2.32))
	var crystal := Toon.part(self, "sphere", Vector3(1.4, 2.0, 1.4), "honey", Vector3(0, 13.6, 0), Vector3.ZERO, 2.0, 0.05)
	crystal.name = "BuyukKivilcim"
	var l := OmniLight3D.new()
	l.light_color = Tokens.color("honey")
	l.light_energy = 3.0
	l.omni_range = 14.0
	l.position.y = 13.6
	add_child(l)
	_collider(2.3, 12.0)


## A balcony railing ring: posts and a top rail.
func _rail(radius: float, y: float, posts: int) -> void:
	Toon.part(self, "ring", Vector3(radius * 2.0, 0.06, radius * 2.0), WOOD_LIGHT, Vector3(0, y + 0.5, 0), Vector3.ZERO, 0.0, 0.015)
	for i in posts:
		var piv := _around(360.0 * i / posts)
		Toon.part(piv, "cylinder", Vector3(0.08, 0.55, 0.08), WOOD_LIGHT, Vector3(0, y + 0.25, radius), Vector3.ZERO, 0.0, 0.0)


func _tree(s: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name) + int(position.x * 13.0 + position.z * 7.0)
	var greens := [Color("#4fbf62"), Color("#3fae5c"), Color("#66cc6e"), Color("#58b86a")]
	# trunk with roots
	Toon.part(self, "cylinder", Vector3(0.45, 1.9, 0.75) * s, WOOD, Vector3(0, 0.95 * s, 0))
	for i in 3:
		var a := TAU * i / 3.0 + rng.randf()
		Toon.part(self, "capsule", Vector3(0.22, 0.8, 0.22) * s, WOOD, Vector3(cos(a) * 0.32, 0.1, sin(a) * 0.32) * s, Vector3(0, -rad_to_deg(a), 70))
	Toon.part(self, "capsule", Vector3(0.18, 0.9, 0.18) * s, WOOD, Vector3(0.35, 1.9, 0.1) * s, Vector3(0, 0, -40))
	# a fluffy crown of overlapping leaf balls in a few greens
	var crown := [[Vector3(0, 2.6, 0), 2.3], [Vector3(0.7, 2.9, 0.3), 1.6], [Vector3(-0.7, 2.8, -0.2), 1.6],
		[Vector3(0.1, 3.5, 0.2), 1.6], [Vector3(-0.2, 2.5, 0.8), 1.3], [Vector3(0.4, 2.4, -0.8), 1.3]]
	for i in crown.size():
		var c: Array = crown[i]
		var d: float = c[1]
		Toon.part(self, "ellipsoid", Vector3(d, d * 0.85, d) * s, greens[(i + rng.randi()) % greens.size()], (c[0] as Vector3) * s)
	# a few fruits or blossoms
	for i in rng.randi_range(2, 4):
		var a := rng.randf() * TAU
		Toon.part(self, "sphere", Vector3(0.22, 0.22, 0.22) * s, ["berry", "spark-yellow", Color("#ff9a52")][rng.randi() % 3],
			Vector3(cos(a) * 1.1, rng.randf_range(2.3, 3.4), sin(a) * 1.1) * s, Vector3.ZERO, 0.15, 0.02)
	Sway.crown(self, 2.2 * s, 1.9 * s, 0.035)
	_collider(0.45 * s, 2.0 * s)


func _well() -> void:
	Toon.part(self, "cylinder", Vector3(1.9, 0.95, 1.9), STONE, Vector3(0, 0.47, 0))
	for i in 8:
		var piv := _around(i * 45.0 + 22.5)
		Toon.part(piv, "box", Vector3(0.62, 0.3, 0.2), STONE.darkened(0.1), Vector3(0, 0.3 + (i % 2) * 0.32, 0.9), Vector3.ZERO, 0.0, 0.015)
	Toon.part(self, "ring", Vector3(1.95, 0.1, 1.95), STONE.lightened(0.1), Vector3(0, 0.95, 0), Vector3.ZERO, 0.0, 0.02)
	WorldLook.water(Toon.part(self, "cylinder", Vector3(1.45, 0.08, 1.45), "sky", Vector3(0, 0.84, 0), Vector3.ZERO, 0.3, 0.0), "lake")
	for x in [-0.85, 0.85]:
		Toon.part(self, "cylinder", Vector3(0.16, 1.7, 0.16), WOOD, Vector3(x, 1.6, 0))
	Toon.part(self, "cylinder", Vector3(0.12, 1.9, 0.12), WOOD_LIGHT, Vector3(0, 2.05, 0), Vector3(0, 0, 90))
	Toon.part(self, "cylinder", Vector3(0.02, 0.6, 0.02), "outline", Vector3(0, 1.75, 0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(self, "cylinder", Vector3(0.32, 0.3, 0.26), WOOD_LIGHT, Vector3(0, 1.35, 0))
	Toon.part(self, "ring", Vector3(0.34, 0.03, 0.34), "ink-muted", Vector3(0, 1.42, 0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(self, "cone", Vector3(2.4, 0.9, 1.6), Tokens.color(accent), Vector3(0, 2.75, 0))
	Toon.part(self, "cone", Vector3(1.6, 0.6, 1.1), Tokens.color(accent).lightened(0.15), Vector3(0, 3.0, 0))
	_collider(0.9, 1.2)


func _flowers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name)
	var cols: Array[String] = ["berry", "spark-yellow", "sky", "spark-purple", "honey"]
	for i in 18:
		var p := Vector3(rng.randf_range(-2.2, 2.2), 0, rng.randf_range(-1.6, 1.6))
		Toon.part(self, "cylinder", Vector3(0.05, 0.4, 0.05), "leaf", p + Vector3(0, 0.2, 0), Vector3.ZERO, 0.0, 0.0)
		Toon.part(self, "sphere", Vector3(0.28, 0.2, 0.28), cols[i % cols.size()], p + Vector3(0, 0.45, 0), Vector3.ZERO, 0.15, 0.02)


func _lantern_post() -> void:
	Toon.part(self, "cylinder", Vector3(0.5, 0.25, 0.55), STONE, Vector3(0, 0.12, 0))
	Toon.part(self, "cylinder", Vector3(0.18, 2.4, 0.22), WOOD, Vector3(0, 1.2, 0))
	Toon.part(self, "ring", Vector3(0.3, 0.04, 0.3), "honey-deep", Vector3(0, 1.0, 0), Vector3.ZERO, 0.0, 0.0)
	# lantern cage: cap, glowing core, base
	Toon.part(self, "cone", Vector3(0.62, 0.32, 0.62), "ink-muted", Vector3(0, 2.92, 0))
	Toon.part(self, "sphere", Vector3(0.16, 0.16, 0.16), "honey-deep", Vector3(0, 3.12, 0))
	Toon.part(self, "cylinder", Vector3(0.5, 0.08, 0.5), "ink-muted", Vector3(0, 2.2, 0))
	for i in 4:
		var piv := _around(45.0 + i * 90.0)
		Toon.part(piv, "cylinder", Vector3(0.04, 0.6, 0.04), "ink-muted", Vector3(0, 2.5, 0.22), Vector3.ZERO, 0.0, 0.0)
	Toon.part(self, "sphere", Vector3(0.42, 0.55, 0.42), accent, Vector3(0, 2.5, 0), Vector3.ZERO, 1.3, 0.02).name = "Glow"
	var l := OmniLight3D.new()
	l.light_color = Tokens.color(accent)
	l.light_energy = 2.0
	l.omni_range = 5.0
	l.position.y = 2.5
	add_child(l)
	_collider(0.15, 2.4)


## Garden fence: posts and two rails, solid (you can't jump over it).
func _fence() -> void:
	var wood := Color("#c98d5e")
	var n := maxi(2, int(length / 1.5) + 1)
	for i in n:
		var x := -length * 0.5 + length * i / float(n - 1)
		Toon.part(self, "cylinder", Vector3(0.22, 1.3, 0.22), wood, Vector3(x, 0.65, 0))
		Toon.part(self, "sphere", Vector3(0.26, 0.2, 0.26), wood, Vector3(x, 1.32, 0))
	for y in [0.5, 1.0]:
		Toon.part(self, "box", Vector3(length, 0.14, 0.1), wood, Vector3(0, y, 0), Vector3.ZERO, 0.0, 0.025)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(length, 4.0, 0.5)
	c.shape = b
	c.position.y = 2.0
	body.add_child(c)
	add_child(body)


## A fallen festival beam resting on two crates: too low to walk under,
## too high to jump over — roll under it (top olup yuvarlan).
func _low_beam() -> void:
	var wood := Color("#a86b45")
	for x in [-1.6, 1.6]:
		Toon.part(self, "box", Vector3(0.7, 0.95, 0.7), Color("#c98d5e"), Vector3(x, 0.475, 0))
	Toon.part(self, "cylinder", Vector3(0.6, 4.2, 0.6), wood, Vector3(0, 1.25, 0), Vector3(0, 0, 90))
	for x in [-1.0, 0.0, 1.0]:
		Toon.part(self, "sphere", Vector3(0.36, 0.42, 0.36), accent, Vector3(x, 0.88, 0.0), Vector3.ZERO, 1.1, 0.02)
	# solid crates
	for x in [-1.6, 1.6]:
		var sb := StaticBody3D.new()
		var sc := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(0.7, 0.95, 0.7)
		sc.shape = bx
		sc.position = Vector3(x, 0.475, 0)
		sb.add_child(sc)
		add_child(sb)
	# the beam: blocks a standing player (layer 16) but not a rolling one
	var beam := StaticBody3D.new()
	beam.collision_layer = 16
	beam.collision_mask = 0
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(2.6, 3.0, 0.6)
	c.shape = b
	c.position.y = 2.45  # from 0.95 m up: a 0.9 m ball fits under
	beam.add_child(c)
	add_child(beam)
	var high := StaticBody3D.new()  # stops jumping over it
	var hc := CollisionShape3D.new()
	var hb := BoxShape3D.new()
	hb.size = Vector3(4.0, 4.0, 0.3)
	hc.shape = hb
	hc.position.y = 3.95 + 2.0
	high.add_child(hc)
	add_child(high)


func _bush() -> void:
	Toon.part(self, "ellipsoid", Vector3(1.2, 0.9, 1.1), "leaf", Vector3(0, 0.42, 0))
	Toon.part(self, "ellipsoid", Vector3(0.8, 0.7, 0.75), Color("#3fae5c"), Vector3(0.45, 0.55, -0.15))
	Toon.part(self, "ellipsoid", Vector3(0.75, 0.6, 0.7), Color("#66cc6e"), Vector3(-0.42, 0.38, 0.2))
	for i in 4:
		Toon.part(self, "sphere", Vector3(0.16, 0.16, 0.16), ["berry", "spark-yellow", "sky"][i % 3],
			Vector3(-0.4 + i * 0.27, 0.75 + (i % 2) * 0.12, 0.38), Vector3.ZERO, 0.1, 0.015)


func _rock() -> void:
	var c := Color("#b9b0c4")
	Toon.part(self, "ellipsoid", Vector3(1.6, 1.1, 1.4), c, Vector3(0, 0.45, 0), Vector3(0, 0, 6))
	Toon.part(self, "ellipsoid", Vector3(0.9, 0.7, 0.8), c.darkened(0.08), Vector3(0.75, 0.3, 0.35), Vector3(0, 30, -10))
	Toon.part(self, "ellipsoid", Vector3(0.6, 0.4, 0.55), c.lightened(0.08), Vector3(-0.7, 0.2, 0.4))
	# moss on top
	Toon.part(self, "ellipsoid", Vector3(0.9, 0.18, 0.7), Color("#7cc46a"), Vector3(-0.1, 0.98, 0.0), Vector3(0, 0, 6), 0.0, 0.015)
	_collider(0.75, 1.0)
