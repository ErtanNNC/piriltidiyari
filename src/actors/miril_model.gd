class_name MirilModel
extends RefCounted
## Gölge Prens Mırıl. shadow(): a tall cloak of soft grey mist with purple
## glints and two big glowing eyes — imposing but not scary.
## star_child(): what's under the shadow — a tiny glowing star child.


static func shadow() -> Node3D:
	var root := Node3D.new()
	Toon.default_pus = 0.0
	var mist := Color("#5c5a72")
	var mist2 := Color("#77738f")
	Toon.part(root, "cone", Vector3(3.6, 4.4, 3.4), mist, Vector3(0, 2.2, 0))
	Toon.part(root, "sphere", Vector3(2.4, 2.2, 2.2), mist2, Vector3(0, 4.6, 0))
	Toon.part(root, "cone", Vector3(1.2, 1.4, 1.0), mist, Vector3(0, 5.9, -0.2), Vector3(-15, 0, 0))
	for i in 6:
		var a := TAU * i / 6.0
		Toon.part(root, "sphere", Vector3(1.4, 1.0, 1.4), mist2, Vector3(sin(a) * 1.5, 0.4 + (i % 2) * 0.3, cos(a) * 1.4))
	for i in 5:
		Toon.part(root, "sphere", Vector3(0.18, 0.18, 0.18), "spark-purple", Vector3(randf_range(-1.2, 1.2), randf_range(1.0, 4.0), randf_range(0.6, 1.3)), Vector3.ZERO, 1.6, 0.0)
	for side in [-1.0, 1.0]:
		Toon.part(root, "sphere", Vector3(0.6, 0.7, 0.3), "spark-purple", Vector3(0.45 * side, 4.7, 1.0), Vector3.ZERO, 2.2, 0.02)
		Toon.part(root, "sphere", Vector3(0.18, 0.22, 0.1), Color.WHITE, Vector3(0.4 * side + 0.08, 4.85, 1.16), Vector3.ZERO, 0.0, 0.0)
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0 else "ArmR"
		arm.position = Vector3(1.4 * side, 3.6, 0.2)
		root.add_child(arm)
		Toon.part(arm, "capsule", Vector3(0.7, 2.4, 0.7), mist, Vector3(0.4 * side, -0.9, 0.2), Vector3(0, 0, 25 * side))
	Toon.default_pus = 1.0
	return root


static func star_child() -> Node3D:
	var root := Node3D.new()
	Toon.default_pus = 0.0
	for i in 5:
		var a := TAU * i / 5.0
		Toon.part(root, "cone", Vector3(0.45, 0.8, 0.3), "spark-white", Vector3(sin(a) * 0.55, 1.0 + cos(a) * 0.55, 0), Vector3(0, 0, -rad_to_deg(a)), 1.4, 0.03)
	Toon.part(root, "sphere", Vector3(1.0, 1.0, 0.6), "spark-white", Vector3(0, 1.0, 0), Vector3.ZERO, 1.6, 0.03)
	for side in [-1.0, 1.0]:
		Toon.part(root, "sphere", Vector3(0.12, 0.15, 0.06), "outline", Vector3(0.16 * side, 1.08, 0.3), Vector3.ZERO, 0.0, 0.0)
		Toon.part(root, "sphere", Vector3(0.14, 0.07, 0.04), "spark-purple", Vector3(0.28 * side, 0.92, 0.28), Vector3.ZERO, 0.8, 0.0)
	Toon.part(root, "box", Vector3(0.18, 0.04, 0.04), "outline", Vector3(0, 0.88, 0.31), Vector3.ZERO, 0.0, 0.0)
	var l := OmniLight3D.new()
	l.light_color = Tokens.color("spark-white")
	l.omni_range = 4.0
	l.light_energy = 1.2
	l.position.y = 1.0
	root.add_child(l)
	Toon.default_pus = 1.0
	return root
