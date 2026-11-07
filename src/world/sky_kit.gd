class_name SkyKit
extends RefCounted
## Building blocks of Bulut Limanı: floating islands, cloud sea, docks.

const GRASS := Color("#8fd38a")
const EARTH := Color("#c79a6e")


## A round floating island: grass top at `center.y`, earthy cone below.
static func island(parent: Node3D, center: Vector3, radius: float, grass := GRASS) -> StaticBody3D:
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = 1.0
	c.shape = cyl
	c.position.y = -0.5
	body.add_child(c)
	parent.add_child(body)
	body.position = center
	Toon.part(body, "cylinder", Vector3(radius * 2, 1.0, radius * 2), grass, Vector3(0, -0.5, 0))
	Toon.part(body, "cone", Vector3(radius * 2, radius * 1.1, radius * 2), EARTH, Vector3(0, -1.0 - radius * 0.55, 0), Vector3(180, 0, 0))
	for i in int(radius / 2.0):
		var a := TAU * i / int(radius / 2.0)
		Toon.part(body, "sphere", Vector3(1.4, 1.0, 1.4), Color("#b38558"), Vector3(sin(a) * radius * 0.6, -radius * 0.7, cos(a) * radius * 0.6))
	return body


## Soft white clouds far below the islands.
static func cloud_sea(parent: Node3D, center: Vector3, extent: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("#ffffff")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 40:
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 1.0
		s.height = 2.0
		s.radial_segments = 12
		s.rings = 6
		mi.mesh = s
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		mi.position = center + Vector3(rng.randf_range(-extent, extent), rng.randf_range(-16, -12), rng.randf_range(-extent, extent))
		mi.scale = Vector3(rng.randf_range(6, 12), rng.randf_range(2, 3.5), rng.randf_range(6, 12))


## A wooden dock sticking out of an island edge.
static func dock(parent: Node3D, at: Vector3, yaw_deg: float) -> void:
	var d := Node3D.new()
	parent.add_child(d)
	d.position = at
	d.rotation_degrees.y = yaw_deg
	WorldLook.block(d, Vector3(0, -0.15, 2.5), Vector3(3.2, 0.3, 5.0), Color("#c98d5e"))
	for x in [-1.4, 1.4]:
		Toon.part(d, "cylinder", Vector3(0.3, 2.4, 0.3), Color("#a86b45"), Vector3(x, -0.6, 4.8))
