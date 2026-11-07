class_name FistikModel
extends RefCounted
## Placeholder Fıstık built from primitives: an old hedgehog knight with a
## honey cape, small helmet and quills that glow in the light. Faces +Z.


## stone = true builds the statue Fıstık becomes in Sahne 5: grey stone,
## only the quills still glowing honey ("ışıkla uyuyor").
static func build(stone := false) -> Node3D:
	var root := Node3D.new()
	root.name = "Fistik"
	var cream := Color("#f3dcb4") if not stone else Color("#b3aca2")
	var quill := Color("#8a5a3c") if not stone else Color("#8f887e")
	if stone:
		Toon.default_pus = 0.0
	# body + belly
	Toon.part(root, "sphere", Vector3(1.0, 1.0, 1.0), quill, Vector3(0, 0.55, 0))
	Toon.part(root, "sphere", Vector3(0.78, 0.82, 0.6), cream, Vector3(0, 0.55, 0.22))
	# quills: rows of cones pointing back and up, tips glowing honey
	for row in 3:
		for i in 5:
			var a := deg_to_rad(-60.0 + i * 30.0)
			var y := 0.55 + row * 0.22
			var pos := Vector3(sin(a) * 0.42, y, -cos(a) * 0.38 - 0.05)
			var c := Toon.part(root, "cone", Vector3(0.22, 0.45, 0.22), "honey" if stone else "honey-deep", pos, Vector3.ZERO, 1.6 if stone else 0.25)
			c.look_at_from_position(pos, pos + Vector3(sin(a) * 0.6, 0.7 - row * 0.15, -1.0), Vector3.UP)
			c.rotate_object_local(Vector3.RIGHT, -PI / 2)
	# head
	Toon.part(root, "sphere", Vector3(0.82, 0.74, 0.8), quill, Vector3(0, 1.25, 0.05))
	Toon.part(root, "sphere", Vector3(0.62, 0.52, 0.5), cream, Vector3(0, 1.18, 0.3))
	Toon.part(root, "sphere", Vector3(0.2, 0.16, 0.22), cream, Vector3(0, 1.12, 0.58))
	Toon.part(root, "sphere", Vector3(0.1, 0.09, 0.1), "outline", Vector3(0, 1.15, 0.69), Vector3.ZERO, 0.0, 0.0)
	for s in [-1.0, 1.0]:
		if stone:
			# eyes closed: sleeping in the light
			Toon.part(root, "box", Vector3(0.16, 0.03, 0.04), "outline", Vector3(0.15 * s, 1.28, 0.52), Vector3(0, 0, -8 * s), 0.0, 0.0)
		else:
			Toon.part(root, "sphere", Vector3(0.13, 0.17, 0.08), "outline", Vector3(0.15 * s, 1.3, 0.5), Vector3.ZERO, 0.0, 0.0)
			Toon.part(root, "sphere", Vector3(0.05, 0.05, 0.03), Color.WHITE, Vector3(0.13 * s + 0.02, 1.34, 0.54), Vector3.ZERO, 0.0, 0.0)
			Toon.part(root, "sphere", Vector3(0.14, 0.08, 0.05), "berry", Vector3(0.25 * s, 1.14, 0.5), Vector3.ZERO, 0.0, 0.0)
		# white whiskers (moustache)
		Toon.part(root, "capsule", Vector3(0.07, 0.3, 0.07), Color.WHITE if not stone else cream, Vector3(0.14 * s, 1.07, 0.6), Vector3(0, 0, 70 * s), 0.0, 0.02)
		# feet + hands
		Toon.part(root, "sphere", Vector3(0.3, 0.2, 0.38), quill, Vector3(0.24 * s, 0.1, 0.12))
		Toon.part(root, "sphere", Vector3(0.22, 0.22, 0.22), cream, Vector3(0.5 * s, 0.6, 0.18))
	# small dented helmet
	Toon.part(root, "sphere", Vector3(0.66, 0.4, 0.66), "ink-muted" if not stone else Color("#8f887e"), Vector3(0, 1.55, -0.02))
	Toon.part(root, "cylinder", Vector3(0.08, 0.16, 0.08), "honey", Vector3(0, 1.8, -0.02))
	# honey cape
	Toon.part(root, "cylinder", Vector3(0.7, 0.75, 1.0), "honey" if not stone else Color("#a39c91"), Vector3(0, 0.62, -0.33), Vector3(-12, 0, 0))
	Toon.default_pus = 1.0
	return root
