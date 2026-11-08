class_name OwlModel
extends RefCounted
## Pus Baykuşu: a big round owl made of grey smoke. Grumpy, still cute.
## Returns the root; wings are named "WingL"/"WingR" for flapping.


static func build() -> Node3D:
	var real := ModelImport.with_parts("pus_baykusu", {"WingL": Vector3(-1.05, 2.0, -0.1), "WingR": Vector3(1.05, 2.0, -0.1)})
	if real:
		return real
	var root := Node3D.new()
	Toon.default_pus = 0.0
	var grey := Color("#77738a")
	var light := Color("#a19db2")
	Toon.part(root, "sphere", Vector3(2.4, 2.6, 2.2), grey, Vector3(0, 1.5, 0))
	Toon.part(root, "sphere", Vector3(1.7, 1.9, 1.0), light, Vector3(0, 1.3, 0.62))
	Toon.part(root, "sphere", Vector3(2.0, 1.6, 1.9), grey, Vector3(0, 3.0, 0.1))
	for s in [-1.0, 1.0]:
		# ear tufts
		Toon.part(root, "cone", Vector3(0.5, 0.8, 0.5), grey, Vector3(0.62 * s, 3.85, 0), Vector3(0, 0, -25 * s))
		# big eyes with lighter rims, grumpy brows
		Toon.part(root, "sphere", Vector3(0.78, 0.78, 0.3), light, Vector3(0.45 * s, 3.05, 0.85))
		Toon.part(root, "sphere", Vector3(0.42, 0.48, 0.2), "outline", Vector3(0.45 * s, 3.05, 0.98), Vector3.ZERO, 0.0, 0.0)
		Toon.part(root, "sphere", Vector3(0.13, 0.15, 0.08), Color.WHITE, Vector3(0.4 * s + 0.06, 3.15, 1.06), Vector3.ZERO, 0.0, 0.0)
		Toon.part(root, "box", Vector3(0.7, 0.14, 0.12), "outline", Vector3(0.45 * s, 3.55, 0.95), Vector3(0, 0, 16 * s), 0.0, 0.0)
		var wing := Node3D.new()
		wing.name = "WingL" if s < 0 else "WingR"
		wing.position = Vector3(1.05 * s, 2.0, -0.1)
		root.add_child(wing)
		Toon.part(wing, "sphere", Vector3(1.8, 0.45, 1.5), grey, Vector3(0.75 * s, -0.2, 0), Vector3(0, 0, -30 * s))
		Toon.part(root, "sphere", Vector3(0.4, 0.22, 0.5), "honey-deep", Vector3(0.35 * s, 0.12, 0.35))
	Toon.part(root, "cone", Vector3(0.32, 0.4, 0.32), "honey-deep", Vector3(0, 2.72, 1.0), Vector3(110, 0, 0))
	Toon.default_pus = 1.0
	return root
