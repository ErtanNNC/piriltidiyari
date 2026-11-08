class_name ForestKit
extends RefCounted
## Building blocks of Fısıltı Ormanı: hedge walls, big friendly trees
## with faces, fireflies.

const HEDGE := Color("#3f8f55")
const HEDGE_DARK := Color("#2f7344")
const BARK := Color("#8a5a3c")


## A solid hedge from a to b (on the ground), height 2.4 m.
static func hedge(parent: Node3D, a: Vector3, b: Vector3, thickness := 1.6) -> void:
	var mid := (a + b) * 0.5
	var length := a.distance_to(b)
	if length < 0.1:
		return
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 4.0, thickness)
	c.shape = box
	c.position.y = 2.0
	body.add_child(c)
	parent.add_child(body)
	body.position = mid
	body.rotation.y = atan2(-(b.z - a.z), b.x - a.x)
	Toon.part(body, "box", Vector3(length, 1.8, thickness), HEDGE, Vector3(0, 0.9, 0), Vector3.ZERO, 0.0, 0.03)
	var n := maxi(1, int(length / 2.2))
	for i in n:
		var x := -length * 0.5 + (i + 0.5) * length / n
		Toon.part(body, "sphere", Vector3(2.2, 1.4, thickness + 0.3), HEDGE_DARK if i % 2 == 0 else HEDGE, Vector3(x, 1.9, 0), Vector3.ZERO, 0.0, 0.03)
		# leafy tufts and a few flowers on the hedge
		Toon.part(body, "ellipsoid", Vector3(1.1, 0.8, 1.0), HEDGE.lightened(0.1), Vector3(x + 0.5, 2.45, 0.2), Vector3.ZERO, 0.0, 0.02)
		if (i + int(mid.x)) % 3 == 0:
			for k in 3:
				Toon.part(body, "sphere", Vector3(0.2, 0.2, 0.2), ["berry", "spark-yellow", Color.WHITE][k], Vector3(x - 0.5 + k * 0.45, 2.2 + (k % 2) * 0.3, thickness * 0.5 + 0.12), Vector3.ZERO, 0.12, 0.015)


## A big friendly tree with a sleepy face. Solid trunk.
static func face_tree(parent: Node3D, at: Vector3, s := 1.0, grey := false) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	var leaves: Variant = Color("#8f8aa0") if grey else Color("#3fae5c")
	var leaves2: Variant = Color("#a19db2") if grey else Color("#58c472")
	var bark: Variant = Color("#7a7488") if grey else BARK
	if grey:
		Toon.default_pus = 0.0
	Toon.part(root, "cylinder", Vector3(1.1, 3.2, 1.5) * s, bark, Vector3(0, 1.6, 0) * s)
	Toon.part(root, "sphere", Vector3(3.6, 2.8, 3.4) * s, leaves, Vector3(0, 4.2, 0) * s)
	Toon.part(root, "sphere", Vector3(2.4, 2.0, 2.2) * s, leaves2, Vector3(0.8, 5.0, 0.4) * s)
	# a fuller crown, roots, a branch and a few mushrooms at the foot
	Toon.part(root, "ellipsoid", Vector3(2.2, 1.8, 2.2) * s, leaves2, Vector3(-1.1, 4.6, -0.3) * s)
	Toon.part(root, "ellipsoid", Vector3(1.8, 1.5, 1.8) * s, leaves, Vector3(-0.2, 5.5, -0.6) * s)
	Toon.part(root, "ellipsoid", Vector3(1.6, 1.3, 1.6) * s, leaves2, Vector3(0.3, 3.6, 1.2) * s)
	Toon.part(root, "capsule", Vector3(0.28, 1.4, 0.28) * s, bark, Vector3(0.75, 3.2, 0.1) * s, Vector3(0, 0, -50))
	for i in 4:
		var a := TAU * i / 4.0 + 0.5
		Toon.part(root, "capsule", Vector3(0.36, 1.2, 0.36) * s, bark, Vector3(cos(a) * 0.55, 0.15, sin(a) * 0.55) * s, Vector3(0, -rad_to_deg(a), 72))
	if not grey:
		for i in 3:
			var a2 := 2.2 + i * 0.45
			var mp := Vector3(cos(a2) * 0.95, 0.0, sin(a2) * 0.95 + 0.2) * s
			Toon.part(root, "cylinder", Vector3(0.12, 0.25, 0.12) * s, Color("#fff3dc"), mp + Vector3(0, 0.12, 0) * s)
			Toon.part(root, "ellipsoid", Vector3(0.34, 0.2, 0.34) * s * (1.0 - i * 0.15), ["berry", Color("#ff9a52"), "spark-purple"][i], mp + Vector3(0, 0.28, 0) * s)
		for i in 4:
			var a3 := randf() * TAU
			Toon.part(root, "sphere", Vector3(0.24, 0.24, 0.24) * s, ["berry", "spark-yellow"][i % 2], Vector3(cos(a3) * 1.5, randf_range(3.6, 5.0), sin(a3) * 1.4) * s, Vector3.ZERO, 0.15, 0.02)
	# face on the trunk
	for side in [-1.0, 1.0]:
		if grey:
			Toon.part(root, "box", Vector3(0.24, 0.05, 0.05) * s, "outline", Vector3(0.2 * side, 2.3, 0.58) * s, Vector3(0, 0, 14 * side), 0.0, 0.0)
		else:
			Toon.part(root, "sphere", Vector3(0.18, 0.1, 0.06) * s, "outline", Vector3(0.2 * side, 2.25, 0.6) * s, Vector3.ZERO, 0.0, 0.0)
		Toon.part(root, "sphere", Vector3(0.2, 0.1, 0.05) * s, "berry" if not grey else Color("#8d89a0"), Vector3(0.36 * side, 2.05, 0.55) * s, Vector3.ZERO, 0.0, 0.0)
	Toon.part(root, "box", Vector3(0.2, 0.05, 0.05) * s, "outline", Vector3(0, 1.88, 0.62) * s, Vector3(0, 0, 0 if not grey else 180), 0.0, 0.0)
	Toon.default_pus = 1.0
	if grey or PropModel.swap(root, "prop_face_tree") == null:
		Sway.crown(root, 3.5 * s, 3.0 * s, 0.025)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.7 * s
	cyl.height = 3.0
	c.shape = cyl
	c.position.y = 1.5
	body.add_child(c)
	root.add_child(body)
	return root


## Little glowing dots drifting over an area (no lights: cheap on phones).
static func fireflies(parent: Node3D, center: Vector3, extent: Vector3, count := 24) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("#d9ff8a")
	var mesh := SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12
	mesh.radial_segments = 6
	mesh.rings = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = int(center.z * 31.0 + center.x)
	for i in count:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		var p := center + Vector3(rng.randf_range(-extent.x, extent.x), rng.randf_range(0.6, 3.0), rng.randf_range(-extent.z, extent.z))
		mi.position = p
		var tw := mi.create_tween().set_loops()
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 0.4), rng.randf_range(-1, 1))
		tw.tween_property(mi, "position", p + d, rng.randf_range(2.0, 3.5)).set_trans(Tween.TRANS_SINE)
		tw.tween_property(mi, "position", p, rng.randf_range(2.0, 3.5)).set_trans(Tween.TRANS_SINE)
