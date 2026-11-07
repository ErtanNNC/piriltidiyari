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
