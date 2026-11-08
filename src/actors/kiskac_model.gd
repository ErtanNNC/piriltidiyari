class_name KiskacModel
extends RefCounted
## Kristal Yengeç Kıskaç: a big round coral crab with candy crystals on
## its shell. Claws are named "ClawL"/"ClawR". Faces +Z.


static func build() -> Node3D:
	var real := ModelImport.with_parts("kiskac", {"Shell": Vector3(0, 0, 0), "ClawL": Vector3(-1.6, 1.2, 1.0), "ClawR": Vector3(1.6, 1.2, 1.0)})
	if real:
		return real
	var root := Node3D.new()
	var body := Color("#ff7a8f")
	var dark := Color("#d9506a")
	Toon.part(root, "sphere", Vector3(3.2, 1.6, 2.6), body, Vector3(0, 1.1, 0))
	Toon.part(root, "sphere", Vector3(2.6, 0.9, 2.1), dark, Vector3(0, 1.75, -0.1))
	var shell := Node3D.new()
	shell.name = "Shell"
	root.add_child(shell)
	for i in 7:
		var a := TAU * i / 7.0
		var col: String = ["sky", "spark-blue", "spark-purple"][i % 3]
		Toon.part(shell, "cone", Vector3(0.55, 1.1 + (i % 2) * 0.4, 0.55), col, Vector3(sin(a) * 0.8, 2.3, cos(a) * 0.6 - 0.2), Vector3(cos(a) * 20, 0, -sin(a) * 20), 0.7, 0.02)
	Toon.part(shell, "cone", Vector3(0.8, 1.7, 0.8), "spark-blue", Vector3(0, 2.6, -0.2), Vector3.ZERO, 0.9, 0.03)
	for side in [-1.0, 1.0]:
		# eye stalks
		Toon.part(root, "cylinder", Vector3(0.14, 0.6, 0.14), dark, Vector3(0.5 * side, 1.95, 1.05))
		Toon.part(root, "sphere", Vector3(0.42, 0.42, 0.42), Color.WHITE, Vector3(0.5 * side, 2.3, 1.1), Vector3.ZERO, 0.0, 0.02)
		Toon.part(root, "sphere", Vector3(0.2, 0.24, 0.12), "outline", Vector3(0.5 * side, 2.3, 1.3), Vector3.ZERO, 0.0, 0.0)
		Toon.part(root, "sphere", Vector3(0.3, 0.14, 0.08), "berry", Vector3(0.95 * side, 1.4, 1.15), Vector3.ZERO, 0.0, 0.0)
		# legs
		for k in 3:
			Toon.part(root, "capsule", Vector3(0.24, 1.3, 0.24), dark, Vector3(1.6 * side, 0.5, 0.5 - k * 0.6), Vector3(0, 0, 55 * side))
		# claws
		var claw := Node3D.new()
		claw.name = "ClawL" if side < 0 else "ClawR"
		claw.position = Vector3(1.6 * side, 1.2, 1.0)
		root.add_child(claw)
		Toon.part(claw, "capsule", Vector3(0.45, 1.2, 0.45), body, Vector3(0.2 * side, 0, 0.4), Vector3(70, 0, 0))
		Toon.part(claw, "sphere", Vector3(1.0, 0.8, 1.2), body, Vector3(0.3 * side, 0.1, 1.2))
		Toon.part(claw, "cone", Vector3(0.4, 0.8, 0.4), dark, Vector3(0.15 * side, 0.35, 1.9), Vector3(80, 0, 0))
		Toon.part(claw, "cone", Vector3(0.4, 0.8, 0.4), dark, Vector3(0.15 * side, -0.15, 1.9), Vector3(100, 0, 0))
	Toon.part(root, "box", Vector3(0.6, 0.1, 0.1), "outline", Vector3(0, 1.5, 1.3), Vector3.ZERO, 0.0, 0.0)
	return root
