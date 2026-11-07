class_name NpcModels
extends RefCounted
## Placeholder villagers from primitives. All face +Z.


static func build(kind: String) -> Node3D:
	var root := Node3D.new()
	match kind:
		"turtle":
			_turtle(root)
		"bunny":
			_critter(root, Color("#f7f1ea"), "berry", 0.75)
			for s in [-1.0, 1.0]:
				Toon.part(root, "capsule", Vector3(0.2, 0.75, 0.14), Color("#f7f1ea"), Vector3(0.14 * s, 1.55, -0.02), Vector3(0, 0, -10 * s))
				Toon.part(root, "capsule", Vector3(0.1, 0.5, 0.06), "berry", Vector3(0.14 * s, 1.55, 0.05), Vector3(0, 0, -10 * s), 0.0, 0.0)
		"duckling":
			_critter(root, "spark-yellow", "sky", 0.7)
			Toon.part(root, "sphere", Vector3(0.3, 0.12, 0.3), Color("#ff9a3c"), Vector3(0, 1.0, 0.36))
		"owl_teacher":
			_owl_teacher(root)
		"spider":
			_spider(root)
		"mole":
			_mole(root, 1.0)
		"mole_kid":
			_mole(root, 0.6)
		"crab_friend":
			var c := KiskacModel.build()
			c.scale = Vector3.ONE * 0.55
			root.add_child(c)
		"snowman":
			_snowman(root)
		"fistik":
			root.add_child(FistikModel.build())
		"star_child":
			root.add_child(MirilModel.star_child())
		"bunny_sleepy":
			_critter(root, Color("#f7faff"), "sky", 0.6)
		"gull_captain":
			_gull(root, 1.0, true)
		"gull_chick":
			_gull(root, 0.55, false)
		"statue":
			Toon.part(root, "cylinder", Vector3(1.6, 1.0, 1.8), Color("#b9b0a4"), Vector3(0, 0.5, 0))
			var f := FistikModel.build(true)
			f.position.y = 1.0
			root.add_child(f)
		"frog":
			_critter(root, "spark-green", "spark-green", 0.7)
			for s in [-1.0, 1.0]:
				Toon.part(root, "sphere", Vector3(0.26, 0.26, 0.26), "spark-green", Vector3(0.2 * s, 1.3, 0.1))
	return root


## A small round village kid: body, head, eyes, cheeks and a scarf.
static func _critter(root: Node3D, body: Variant, scarf: Variant, scale_f: float) -> void:
	var r := Node3D.new()
	r.scale = Vector3.ONE * scale_f
	root.add_child(r)
	Toon.part(r, "sphere", Vector3(0.9, 0.95, 0.85), body, Vector3(0, 0.5, 0))
	Toon.part(r, "sphere", Vector3(0.95, 0.85, 0.9), body, Vector3(0, 1.25, 0.02))
	Toon.part(r, "torus", Vector3(0.8, 0.26, 0.8), scarf, Vector3(0, 0.92, 0))
	for s in [-1.0, 1.0]:
		Toon.part(r, "sphere", Vector3(0.14, 0.2, 0.08), "outline", Vector3(0.17 * s, 1.3, 0.42), Vector3.ZERO, 0.0, 0.0)
		Toon.part(r, "sphere", Vector3(0.05, 0.06, 0.03), Color.WHITE, Vector3(0.15 * s + 0.02, 1.35, 0.46), Vector3.ZERO, 0.0, 0.0)
		Toon.part(r, "sphere", Vector3(0.16, 0.08, 0.05), "berry", Vector3(0.3 * s, 1.16, 0.38), Vector3.ZERO, 0.0, 0.0)
		Toon.part(r, "sphere", Vector3(0.26, 0.18, 0.32), body, Vector3(0.22 * s, 0.08, 0.12))


## Tospik Nine: wise old turtle, leaf shell, honey shawl.
static func _turtle(root: Node3D) -> void:
	var skin := Color("#a8d8a0")
	Toon.part(root, "sphere", Vector3(1.8, 1.4, 1.7), "leaf", Vector3(0, 0.75, -0.15))
	Toon.part(root, "cylinder", Vector3(1.9, 0.2, 1.9), Color("#d8c48a"), Vector3(0, 0.25, -0.15))
	for i in 5:
		var a := deg_to_rad(i * 72.0 + 36.0)
		Toon.part(root, "sphere", Vector3(0.45, 0.2, 0.45), Color("#58b86a"), Vector3(sin(a) * 0.5, 1.32, -0.15 + cos(a) * 0.5), Vector3(-25 * cos(a), 0, 25 * sin(a)), 0.0, 0.0)
	Toon.part(root, "sphere", Vector3(0.75, 0.7, 0.72), skin, Vector3(0, 1.1, 0.85))
	Toon.part(root, "torus", Vector3(0.85, 0.28, 0.85), "honey", Vector3(0, 0.8, 0.75), Vector3(-20, 0, 0))
	for s in [-1.0, 1.0]:
		Toon.part(root, "sphere", Vector3(0.12, 0.15, 0.06), "outline", Vector3(0.15 * s, 1.18, 1.17), Vector3.ZERO, 0.0, 0.0)
		Toon.part(root, "torus", Vector3(0.24, 0.035, 0.24), "ink-muted", Vector3(0.15 * s, 1.18, 1.2), Vector3(90, 0, 0), 0.0, 0.0)
		Toon.part(root, "sphere", Vector3(0.14, 0.08, 0.05), "berry", Vector3(0.28 * s, 1.02, 1.1), Vector3.ZERO, 0.0, 0.0)
		Toon.part(root, "sphere", Vector3(0.38, 0.3, 0.42), skin, Vector3(0.6 * s, 0.15, 0.5))


## Baykuş Öğretmen Hu: a small round green owl with glasses, on a stump.
static func _owl_teacher(root: Node3D) -> void:
	Toon.part(root, "cylinder", Vector3(1.4, 0.8, 1.6), Color("#8a5a3c"), Vector3(0, 0.4, 0))
	var g := Color("#5fbf7a")
	Toon.part(root, "sphere", Vector3(1.0, 1.1, 0.95), g, Vector3(0, 1.35, 0))
	Toon.part(root, "sphere", Vector3(0.7, 0.75, 0.4), Color("#d9f2c4"), Vector3(0, 1.25, 0.32))
	for s in [-1.0, 1.0]:
		Toon.part(root, "cone", Vector3(0.22, 0.32, 0.22), g, Vector3(0.3 * s, 1.95, 0), Vector3(0, 0, -20 * s))
		Toon.part(root, "sphere", Vector3(0.3, 0.3, 0.12), Color.WHITE, Vector3(0.19 * s, 1.55, 0.42), Vector3.ZERO, 0.0, 0.0)
		Toon.part(root, "sphere", Vector3(0.14, 0.16, 0.08), "outline", Vector3(0.19 * s, 1.55, 0.47), Vector3.ZERO, 0.0, 0.0)
		Toon.part(root, "torus", Vector3(0.36, 0.035, 0.36), "honey-deep", Vector3(0.19 * s, 1.55, 0.49), Vector3(90, 0, 0), 0.0, 0.0)
		Toon.part(root, "sphere", Vector3(0.5, 0.2, 0.7), g, Vector3(0.48 * s, 1.3, -0.05), Vector3(0, 0, -30 * s))
	Toon.part(root, "cone", Vector3(0.14, 0.2, 0.14), "honey", Vector3(0, 1.4, 0.5), Vector3(100, 0, 0))


## Terzi Örümcek Dikiş: a cute round spider with four eyes and a thimble hat.
static func _spider(root: Node3D) -> void:
	var b := Color("#ff8fa6")
	Toon.part(root, "sphere", Vector3(1.0, 0.85, 1.1), b, Vector3(0, 0.75, -0.2))
	Toon.part(root, "sphere", Vector3(0.75, 0.7, 0.7), b, Vector3(0, 0.95, 0.4))
	for i in 4:
		var x := -0.24 + i * 0.16
		Toon.part(root, "sphere", Vector3(0.13, 0.15, 0.06), "outline", Vector3(x, 1.08 - absf(x) * 0.3, 0.72), Vector3.ZERO, 0.0, 0.0)
	for s in [-1.0, 1.0]:
		for k in 4:
			var z := 0.35 - k * 0.3
			var leg := Toon.part(root, "capsule", Vector3(0.1, 0.9, 0.1), Color("#c95b78"), Vector3(0.6 * s, 0.45, z), Vector3(0, 0, 55 * s))
			leg.name = "Leg"
		Toon.part(root, "sphere", Vector3(0.14, 0.08, 0.05), "berry", Vector3(0.24 * s, 0.82, 0.68), Vector3.ZERO, 0.0, 0.0)
	Toon.part(root, "cylinder", Vector3(0.36, 0.3, 0.42), "honey", Vector3(0, 1.4, 0.35))


## Madenci Köstebek Kazma (and kids at scale 0.6): a round mole with a
## miner's helmet and a spark-blue lamp.
static func _mole(root: Node3D, s: float) -> void:
	var fur := Color("#7a5a4a")
	var r := Node3D.new()
	r.scale = Vector3.ONE * s
	root.add_child(r)
	Toon.part(r, "sphere", Vector3(1.1, 1.2, 1.0), fur, Vector3(0, 0.65, 0))
	Toon.part(r, "sphere", Vector3(0.7, 0.75, 0.4), Color("#d9b8a0"), Vector3(0, 0.55, 0.35))
	Toon.part(r, "sphere", Vector3(0.3, 0.24, 0.3), "berry", Vector3(0, 1.05, 0.5))
	for side in [-1.0, 1.0]:
		Toon.part(r, "box", Vector3(0.16, 0.04, 0.04), "outline", Vector3(0.18 * side, 1.22, 0.44), Vector3(0, 0, 10 * side), 0.0, 0.0)
		Toon.part(r, "sphere", Vector3(0.36, 0.18, 0.3), Color("#f0c8b0"), Vector3(0.5 * side, 0.6, 0.25), Vector3(0, 0, -30 * side))
	Toon.part(r, "sphere", Vector3(0.95, 0.5, 0.95), "honey", Vector3(0, 1.4, 0))
	Toon.part(r, "sphere", Vector3(0.26, 0.26, 0.16), "spark-blue", Vector3(0, 1.48, 0.44), Vector3.ZERO, 1.6, 0.02)


## Kaptan Martı Pırpır (captain hat) and the gull chicks.
static func _gull(root: Node3D, s: float, captain: bool) -> void:
	var r := Node3D.new()
	r.scale = Vector3.ONE * s
	root.add_child(r)
	var white := Color("#ffffff")
	Toon.part(r, "sphere", Vector3(1.0, 1.0, 1.1), white, Vector3(0, 0.65, 0))
	Toon.part(r, "sphere", Vector3(0.8, 0.75, 0.75), white, Vector3(0, 1.3, 0.2))
	Toon.part(r, "cone", Vector3(0.26, 0.5, 0.26), "honey", Vector3(0, 1.22, 0.75), Vector3(90, 0, 0))
	for side in [-1.0, 1.0]:
		Toon.part(r, "sphere", Vector3(0.13, 0.17, 0.07), "outline", Vector3(0.18 * side, 1.38, 0.53), Vector3.ZERO, 0.0, 0.0)
		Toon.part(r, "sphere", Vector3(0.14, 0.08, 0.05), "berry", Vector3(0.3 * side, 1.18, 0.5), Vector3.ZERO, 0.0, 0.0)
		Toon.part(r, "sphere", Vector3(0.9, 0.18, 0.6), Color("#c6d2e2"), Vector3(0.6 * side, 0.75, -0.05), Vector3(0, 0, -25 * side))
		Toon.part(r, "sphere", Vector3(0.26, 0.14, 0.34), "honey-deep", Vector3(0.22 * side, 0.08, 0.15))
	if captain:
		Toon.part(r, "cylinder", Vector3(1.0, 0.12, 1.0), "outline", Vector3(0, 1.66, 0.15), Vector3.ZERO, 0.0, 0.0)
		Toon.part(r, "cylinder", Vector3(0.7, 0.4, 0.8), "sky", Vector3(0, 1.85, 0.15))
		Toon.part(r, "sphere", Vector3(0.2, 0.2, 0.08), "spark-yellow", Vector3(0, 1.88, 0.55), Vector3.ZERO, 0.6, 0.0)


## Bilge Kuzey: a wise old snowman with a scarf, a hat and twig arms.
static func _snowman(root: Node3D) -> void:
	var snow := MountainKit.SNOW
	Toon.part(root, "sphere", Vector3(1.8, 1.6, 1.8), snow, Vector3(0, 0.8, 0))
	Toon.part(root, "sphere", Vector3(1.3, 1.2, 1.3), snow, Vector3(0, 2.1, 0))
	Toon.part(root, "sphere", Vector3(1.0, 0.95, 1.0), snow, Vector3(0, 3.1, 0))
	Toon.part(root, "torus", Vector3(1.1, 0.26, 1.1), "spark-white", Vector3(0, 2.65, 0))
	Toon.part(root, "torus", Vector3(1.05, 0.22, 1.05), "sky", Vector3(0, 2.62, 0))
	Toon.part(root, "cone", Vector3(0.18, 0.5, 0.18), Color("#ff9a3c"), Vector3(0, 3.05, 0.6), Vector3(90, 0, 0))
	for side in [-1.0, 1.0]:
		Toon.part(root, "sphere", Vector3(0.14, 0.16, 0.08), "outline", Vector3(0.2 * side, 3.25, 0.44), Vector3.ZERO, 0.0, 0.0)
		Toon.part(root, "torus", Vector3(0.3, 0.035, 0.3), "ink-muted", Vector3(0.2 * side, 3.25, 0.47), Vector3(90, 0, 0), 0.0, 0.0)
		Toon.part(root, "cylinder", Vector3(0.08, 1.3, 0.08), Color("#8a5a3c"), Vector3(0.95 * side, 2.3, 0), Vector3(0, 0, 55 * side))
		Toon.part(root, "sphere", Vector3(0.12, 0.08, 0.05), "berry", Vector3(0.32 * side, 3.0, 0.42), Vector3.ZERO, 0.0, 0.0)
	Toon.part(root, "cylinder", Vector3(1.2, 0.1, 1.2), "outline", Vector3(0, 3.5, 0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(root, "cylinder", Vector3(0.7, 0.7, 0.7), "spark-purple", Vector3(0, 3.85, 0))
