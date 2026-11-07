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
		"bush": Toon.part(self, "sphere", Vector3(1.2, 0.9, 1.2), "leaf", Vector3(0, 0.4, 0))
		"fence": _fence()
		"low_beam": _low_beam()
		"rock":
			Toon.part(self, "sphere", Vector3(1.6, 1.1, 1.4), Color("#b9b0c4"), Vector3(0, 0.45, 0))
			_collider(0.75, 1.0)


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


func _house() -> void:
	Toon.part(self, "cylinder", Vector3(3.0, 2.4, 3.2), Color("#fff3dc"), Vector3(0, 1.2, 0))
	Toon.part(self, "cone", Vector3(4.0, 2.2, 4.0), accent, Vector3(0, 3.5, 0))
	Toon.part(self, "capsule", Vector3(0.9, 1.6, 0.4), Color("#a86b45"), Vector3(0, 0.75, 1.45))
	Toon.part(self, "sphere", Vector3(0.6, 0.6, 0.3), "honey", Vector3(0.95, 1.6, 1.15), Vector3(0, 40, 0), 1.2, 0.02)
	Toon.part(self, "cylinder", Vector3(0.35, 0.9, 0.35), "ink-muted", Vector3(0.8, 4.2, -0.4))
	_collider(1.6, 3.0)


func _tower() -> void:
	# Fener Kulesi: stacked tiers with the Büyük Kıvılcım on top.
	Toon.part(self, "cylinder", Vector3(4.0, 4.0, 4.6), Color("#efe2c8"), Vector3(0, 2.0, 0))
	Toon.part(self, "cylinder", Vector3(4.8, 0.5, 4.8), "honey-deep", Vector3(0, 4.2, 0))
	Toon.part(self, "cylinder", Vector3(3.2, 4.0, 3.8), Color("#efe2c8"), Vector3(0, 6.4, 0))
	Toon.part(self, "cylinder", Vector3(4.0, 0.5, 4.0), "honey-deep", Vector3(0, 8.6, 0))
	Toon.part(self, "cylinder", Vector3(2.6, 2.0, 2.8), Color("#efe2c8"), Vector3(0, 9.8, 0))
	Toon.part(self, "cone", Vector3(3.6, 2.0, 3.6), "berry", Vector3(0, 11.8, 0))
	Toon.part(self, "capsule", Vector3(1.0, 2.0, 0.4), Color("#a86b45"), Vector3(0, 1.0, 2.2))
	var crystal := Toon.part(self, "sphere", Vector3(1.4, 2.0, 1.4), "honey", Vector3(0, 13.6, 0), Vector3.ZERO, 2.0, 0.05)
	crystal.name = "BuyukKivilcim"
	var l := OmniLight3D.new()
	l.light_color = Tokens.color("honey")
	l.light_energy = 3.0
	l.omni_range = 14.0
	l.position.y = 13.6
	add_child(l)
	_collider(2.3, 12.0)


func _tree(s: float) -> void:
	Toon.part(self, "cylinder", Vector3(0.5, 1.6, 0.7) * s, Color("#a86b45"), Vector3(0, 0.8 * s, 0))
	Toon.part(self, "sphere", Vector3(2.4, 2.0, 2.4) * s, "leaf", Vector3(0, 2.4 * s, 0))
	Toon.part(self, "sphere", Vector3(1.6, 1.4, 1.6) * s, Color("#3fae5c"), Vector3(0.5 * s, 3.2 * s, 0.3 * s))
	_collider(0.45 * s, 2.0 * s)


func _well() -> void:
	Toon.part(self, "cylinder", Vector3(1.8, 0.9, 1.8), Color("#c9bfae"), Vector3(0, 0.45, 0))
	Toon.part(self, "cylinder", Vector3(1.4, 0.1, 1.4), "sky", Vector3(0, 0.88, 0), Vector3.ZERO, 0.3, 0.0)
	for x in [-0.8, 0.8]:
		Toon.part(self, "cylinder", Vector3(0.15, 1.6, 0.15), Color("#a86b45"), Vector3(x, 1.5, 0))
	Toon.part(self, "cone", Vector3(2.2, 0.8, 1.4), accent, Vector3(0, 2.6, 0))
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
	Toon.part(self, "cylinder", Vector3(0.18, 2.4, 0.22), Color("#a86b45"), Vector3(0, 1.2, 0))
	Toon.part(self, "sphere", Vector3(0.5, 0.6, 0.5), accent, Vector3(0, 2.5, 0), Vector3.ZERO, 1.3, 0.03)
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
