class_name LilyPad
extends StaticBody3D
## A round lily pad to hop on: notched leaf with veins, a darker rim, a pink
## lotus on some pads, a soft ripple ring on the water and a slow bob, so it
## reads as "stand here" from far away. Collider: a flat cylinder whose top
## is at the node's origin.

const RADIUS := 1.25
const LEAF := Color("#74c94e")
const RIM := Color("#3f8a34")
const VEIN := Color("#98d66c")
const NOTCH := 0.42  # half angle of the notch (radians)

@export var flower := true
@export var turn := 0.0


func _ready() -> void:
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = RADIUS
	cyl.height = 0.3
	c.shape = cyl
	c.position = Vector3(0, -0.15, 0)
	add_child(c)
	var look := Node3D.new()
	look.name = "Look"
	look.rotation.y = turn
	add_child(look)
	var leaf := MeshInstance3D.new()
	leaf.mesh = _leaf_mesh(RADIUS + 0.05, 0.12)
	leaf.material_override = Toon.material(LEAF, 0.04)
	leaf.position.y = -0.1
	look.add_child(leaf)
	var rim := MeshInstance3D.new()
	rim.mesh = _leaf_mesh(RADIUS + 0.1, 0.06)
	rim.material_override = Toon.material(RIM, 0.0)
	rim.position.y = -0.14
	look.add_child(rim)
	var veins := MeshInstance3D.new()
	veins.mesh = _vein_mesh(RADIUS * 0.92)
	veins.material_override = Toon.material(VEIN, 0.0)
	veins.position.y = 0.025
	look.add_child(veins)
	if flower:
		_lotus(look, Vector3(-0.45, 0.02, -0.4))
	# ripple ring on the water
	var ring := Toon.part(self, "ring", Vector3(RADIUS * 2.5, 0.07, RADIUS * 2.5), Color("#e9f6ff"), Vector3(0, -0.2, 0), Vector3.ZERO, 0.4, 0.0)
	ring.name = "Ripple"
	var rt := ring.create_tween().set_loops()
	rt.tween_property(ring, "scale", Vector3.ONE * 1.12, 1.4).set_trans(Tween.TRANS_SINE)
	rt.tween_property(ring, "scale", Vector3.ONE, 1.4).set_trans(Tween.TRANS_SINE)
	# slow bob (look only; the collider stays put)
	var bt := look.create_tween().set_loops()
	bt.tween_interval(randf() * 0.8)
	bt.tween_property(look, "position:y", -0.04, 1.1).set_trans(Tween.TRANS_SINE)
	bt.tween_property(look, "position:y", 0.0, 1.1).set_trans(Tween.TRANS_SINE)


## Flat disc with a V notch, `h` thick; top at y = h / 2.
static func _leaf_mesh(r: float, h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 40
	var a0 := NOTCH
	var a1 := TAU - NOTCH
	var top := h * 0.5
	var pts: Array[Vector2] = []
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		pts.append(Vector2(cos(a), sin(a)) * r)
	var mid := Vector2(r * 0.12, 0)  # notch tip, a little off center
	for i in n:
		var p0 := pts[i]
		var p1 := pts[i + 1]
		# top
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(mid.x, top, mid.y))
		st.add_vertex(Vector3(p0.x, top, p0.y))
		st.add_vertex(Vector3(p1.x, top, p1.y))
		# bottom
		st.set_normal(Vector3.DOWN)
		st.add_vertex(Vector3(mid.x, -top, mid.y))
		st.add_vertex(Vector3(p1.x, -top, p1.y))
		st.add_vertex(Vector3(p0.x, -top, p0.y))
		# side
		var nn := Vector3(p0.x + p1.x, 0, p0.y + p1.y).normalized()
		st.set_normal(nn)
		st.add_vertex(Vector3(p0.x, top, p0.y))
		st.add_vertex(Vector3(p1.x, -top, p1.y))
		st.add_vertex(Vector3(p1.x, top, p1.y))
		st.add_vertex(Vector3(p0.x, top, p0.y))
		st.add_vertex(Vector3(p0.x, -top, p0.y))
		st.add_vertex(Vector3(p1.x, -top, p1.y))
	# the notch walls
	for e: Vector2 in [pts[0], pts[n]]:
		var nn := Vector3(e.y, 0, -e.x).normalized() * (1.0 if e == pts[0] else -1.0)
		st.set_normal(nn)
		st.add_vertex(Vector3(mid.x, top, mid.y))
		st.add_vertex(Vector3(e.x, -top, e.y))
		st.add_vertex(Vector3(e.x, top, e.y))
		st.add_vertex(Vector3(mid.x, top, mid.y))
		st.add_vertex(Vector3(mid.x, -top, mid.y))
		st.add_vertex(Vector3(e.x, -top, e.y))
	return st.commit()


## Thin light veins from the notch tip out to the edge.
static func _vein_mesh(r: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	var w := 0.022
	for i in 7:
		var a := lerpf(NOTCH + 0.45, TAU - NOTCH - 0.45, i / 6.0)
		var d := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-d.z, 0, d.x) * w
		var a3 := Vector3(r * 0.14, 0, 0)
		var b3 := d * r
		st.add_vertex(a3 + side)
		st.add_vertex(b3 - side * 0.4)
		st.add_vertex(b3 + side * 0.4)
		st.add_vertex(a3 + side)
		st.add_vertex(a3 - side)
		st.add_vertex(b3 - side * 0.4)
	return st.commit()


## A pink lotus: two rings of petals round a yellow heart.
static func _lotus(parent: Node3D, at: Vector3) -> void:
	var f := Node3D.new()
	f.name = "Lotus"
	f.position = at
	parent.add_child(f)
	for i in 7:
		var a := i * TAU / 7.0
		var p := Toon.part(f, "ellipsoid", Vector3(0.2, 0.42, 0.12), Color("#ff9ac4"),
			Vector3(cos(a) * 0.16, 0.16, sin(a) * 0.16), Vector3.ZERO, 0.15, 0.025)
		p.rotation = Vector3(0, -a + PI * 0.5, 0)
		p.rotate_object_local(Vector3.RIGHT, -0.75)
	for i in 5:
		var a := i * TAU / 5.0 + 0.3
		var p := Toon.part(f, "ellipsoid", Vector3(0.16, 0.36, 0.1), Color("#ffd2e4"),
			Vector3(cos(a) * 0.07, 0.2, sin(a) * 0.07), Vector3.ZERO, 0.2, 0.02)
		p.rotation = Vector3(0, -a + PI * 0.5, 0)
		p.rotate_object_local(Vector3.RIGHT, -0.35)
	Toon.part(f, "sphere", Vector3(0.14, 0.1, 0.14), Color("#ffd23a"), Vector3(0, 0.2, 0), Vector3.ZERO, 0.5, 0.0)
