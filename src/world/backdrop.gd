class_name Backdrop
extends RefCounted
## Far scenery around a scene so its edges don't end in empty sky: rolling
## hills with trees (village), a wall of forest, floating islands, snowy peaks,
## dark castle spires. Placed on a ring outside the walkable floors and tinted
## toward the sky's horizon color (aerial haze). No collision.

const STYLE := {
	"sabah": "hills", "aksam": "hills", "pus": "hills", "kule": "hills",
	"orman": "forest", "liman": "islands", "dag": "peaks", "kale": "spires",
	"kanyon": "mesas",
}
## Real rock models (FLUX + TRELLIS) for the canyon's edge and horizon.
const CANYON_ROCKS := ["kanyon_kaya_a", "kanyon_kaya_b", "kanyon_kaya_a"]


static func add(scene: Node3D, mood: String) -> void:
	if not STYLE.has(mood):
		return
	await scene.get_tree().process_frame
	if not is_instance_valid(scene):
		return
	var floors: Array = []
	var paths: Array = []
	Decor._collect(scene, floors, paths)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var floor_y := INF
	for f: Dictionary in floors:
		var t: Transform3D = f["xform"]
		var half: Vector2 = f["half"]
		var r := maxf(half.x, half.y)
		lo = Vector2(minf(lo.x, t.origin.x - r), minf(lo.y, t.origin.z - r))
		hi = Vector2(maxf(hi.x, t.origin.x + r), maxf(hi.y, t.origin.z + r))
		floor_y = minf(floor_y, float(f["top"]))
	if floors.is_empty():
		lo = Vector2(-30, -30)
		hi = Vector2(30, 30)
		floor_y = 0.0
	var holder := Node3D.new()
	holder.name = "Backdrop"
	scene.add_child(holder)
	_border(scene, holder, floors, mood)
	var k: Array = WorldLook.SKIES.get(mood, [])
	var haze := Color(String(k[1])) if not k.is_empty() else Color("#cfe6ff")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(mood) + int(lo.x * 7.0 + hi.y)
	var center := (lo + hi) * 0.5
	var radius := (hi - lo).length() * 0.5
	var style: String = STYLE[mood]
	var count := 30
	for i in count:
		var a := TAU * (i + rng.randf_range(-0.3, 0.3)) / count
		var dist := radius + rng.randf_range(18.0, 34.0)
		var at := Vector3(center.x + cos(a) * dist, floor_y, center.y + sin(a) * dist)
		var far := clampf((dist - radius - 18.0) / 16.0, 0.0, 1.0)
		var mix := 0.35 + far * 0.25
		match style:
			"hills": _hill(holder, at, rng, haze, mix, mood)
			"forest": _forest(holder, at, rng, haze, mix)
			"islands": _island(holder, at, rng, haze, mix)
			"peaks": _peak(holder, at, rng, haze, mix)
			"spires": _spire(holder, at, rng, haze, mix)
			"mesas": _mesa(holder, at, rng, haze, mix, i)


static func _p(parent: Node3D, shape: String, size: Vector3, col: Color, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := Toon.part(parent, shape, size, col, pos, rot, 0.0, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _hill(h: Node3D, at: Vector3, rng: RandomNumberGenerator, haze: Color, mix: float, mood: String) -> void:
	var green := Color("#6cc46f") if mood == "sabah" else Color("#5a9a72")
	var w := rng.randf_range(14, 24)
	_p(h, "ellipsoid", Vector3(w, rng.randf_range(7, 12), w * 0.8), green.lerp(haze, mix), at + Vector3(0, -2.0, 0))
	for t in rng.randi_range(1, 3):
		var p := at + Vector3(rng.randf_range(-w * 0.3, w * 0.3), rng.randf_range(1.5, 3.0), rng.randf_range(-w * 0.2, w * 0.2))
		var tree := Node3D.new()
		tree.position = p
		h.add_child(tree)
		_p(tree, "cylinder", Vector3(0.6, 2.2, 0.6), Color("#8a5a3c").lerp(haze, mix), Vector3(0, 1.1, 0))
		_p(tree, "ellipsoid", Vector3(2.8, 2.6, 2.8), Color("#3fae5c").lerp(haze, mix), Vector3(0, 3.0, 0))
		Sway.crown(tree, 2.5, 2.0, 0.05)


static func _forest(h: Node3D, at: Vector3, rng: RandomNumberGenerator, haze: Color, mix: float) -> void:
	for t in 4:
		var p := at + Vector3(rng.randf_range(-6, 6), 0, rng.randf_range(-4, 4))
		var s := rng.randf_range(1.2, 2.0)
		var tree := Node3D.new()
		tree.position = p
		h.add_child(tree)
		_p(tree, "cylinder", Vector3(1.0, 5.0, 1.0) * s, ForestKit.BARK.lerp(haze, mix), Vector3(0, 2.5 * s, 0))
		_p(tree, "ellipsoid", Vector3(5.0, 4.4, 5.0) * s, Color("#3f8f55").lerp(haze, mix), Vector3(0, 6.2 * s, 0))
		_p(tree, "ellipsoid", Vector3(3.4, 3.0, 3.4) * s, Color("#58b86a").lerp(haze, mix), Vector3(0.8, 7.6 * s, 0.4))
		Sway.crown(tree, 5.5 * s, 4.8 * s, 0.03)


static func _island(h: Node3D, at: Vector3, rng: RandomNumberGenerator, haze: Color, mix: float) -> void:
	var s := rng.randf_range(2.5, 5.0)
	var p := at + Vector3(0, rng.randf_range(-6.0, 6.0), 0)
	_p(h, "cone", Vector3(2.0, 2.6, 2.0) * s, Color("#b38558").lerp(haze, mix), p + Vector3(0, -1.3 * s, 0), Vector3(180, 0, 0))
	_p(h, "cylinder", Vector3(2.05, 0.4, 2.05) * s, Color("#7fd36b").lerp(haze, mix), p + Vector3(0, 0.2 * s, 0))
	if rng.randf() < 0.6:
		_p(h, "ellipsoid", Vector3(0.9, 0.9, 0.9) * s, Color("#3fae5c").lerp(haze, mix), p + Vector3(0.3 * s, 0.9 * s, 0))
	# a cloud puff drifting below
	_p(h, "ellipsoid", Vector3(rng.randf_range(8, 14), 2.5, rng.randf_range(6, 10)), Color("#ffffff").lerp(haze, 0.3), at + Vector3(rng.randf_range(-6, 6), rng.randf_range(-12, -8), 0))


static func _peak(h: Node3D, at: Vector3, rng: RandomNumberGenerator, haze: Color, mix: float) -> void:
	var s := rng.randf_range(1.0, 1.8)
	var height := rng.randf_range(16, 26) * s
	var w := height * rng.randf_range(0.8, 1.1)
	var rock := Color("#8f94b0").lerp(haze, mix)
	_p(h, "cone", Vector3(w, height, w), rock, at + Vector3(0, height * 0.5 - 4.0, 0))
	# snow cap: the cone's top third, white
	_p(h, "cone", Vector3(w * 0.4, height * 0.4, w * 0.4) * 1.03, Color("#ffffff").lerp(haze, mix * 0.5), at + Vector3(0, height * 0.8 - 4.0 + 0.05, 0))


static func _spire(h: Node3D, at: Vector3, rng: RandomNumberGenerator, haze: Color, mix: float) -> void:
	var dark := Color("#3a3358").lerp(haze, mix * 0.6)
	for t in rng.randi_range(1, 3):
		var p := at + Vector3(rng.randf_range(-5, 5), -2.0, rng.randf_range(-4, 4))
		var height := rng.randf_range(10, 22)
		var w := rng.randf_range(2.0, 4.0)
		_p(h, "cylinder", Vector3(w, height, w), dark, p + Vector3(0, height * 0.5, 0))
		_p(h, "cone", Vector3(w * 1.3, w * 1.8, w * 1.3), dark.darkened(0.15), p + Vector3(0, height + w * 0.9, 0))
		if rng.randf() < 0.5:
			# a faint purple window glow
			_p(h, "box", Vector3(0.6, 0.9, 0.1), Color(0.75, 0.55, 1.0), p + Vector3(0, height * 0.7, w * 0.5))


# --- the map's edge --------------------------------------------------------------

## Where you can't go shouldn't look like empty sky: the ground carries on
## past the walkable area (a frame of ground around it, so lakes and pits
## inside stay as they are), and a ring of low mounds with bushes, rocks or
## trees marks the edge. The edge comes from the scene's WorldBoundary walls
## (else the floors' extent); exits (TriggerAreas near the edge) get a gap.
## A red sandstone mesa (real model) far out, hazed toward the horizon;
## every third spot gets a rock pillar instead, for a broken skyline.
static func _mesa(h: Node3D, at: Vector3, rng: RandomNumberGenerator, haze: Color, mix: float, i: int) -> void:
	var id := "kanyon_mesa" if i % 3 != 2 else "kanyon_kaya_b"
	var m := ModelImport.load_static(id)
	if m == null:
		_peak(h, at, rng, haze, mix)
		return
	var tall := rng.randf_range(9.0, 15.0) if id == "kanyon_mesa" else rng.randf_range(12.0, 18.0)
	m.scale = Vector3.ONE * tall / ModelImport.static_height(id)
	m.position = at + Vector3(0, -0.6, 0)
	m.rotation.y = rng.randf() * TAU
	_haze(m, haze, mix)
	h.add_child(m)


## Tint every toon material of a model toward the sky's haze color.
static func _haze(node: Node, haze: Color, mix: float) -> void:
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for s in m.get_surface_override_material_count():
			var mat := m.get_surface_override_material(s)
			if mat == null:
				mat = m.mesh.surface_get_material(s)
			if mat is ShaderMaterial:
				var c := (mat as ShaderMaterial).duplicate() as ShaderMaterial
				c.set_shader_parameter("albedo", Color.WHITE.lerp(haze, mix))
				m.set_surface_override_material(s, c)


static func _border(scene: Node3D, holder: Node3D, floors: Array, mood: String) -> void:
	var style: String = STYLE.get(mood, "")
	if floors.is_empty() or style in ["islands", "spires"]:
		return
	# the ground: among the big floors, the one at the keeper's height (not a
	# lake bed or a low pit that happens to be wider)
	var biggest := 0.0
	for f: Dictionary in floors:
		biggest = maxf(biggest, float(f["area"]))
	var player := scene.get_node_or_null("Player") as Node3D
	var py := player.global_position.y if player else 0.0
	var main: Dictionary = floors[0]
	var best := INF
	for f: Dictionary in floors:
		if float(f["area"]) < biggest * 0.15:
			continue
		var dy := absf(float(f["top"]) - py)
		if dy < best - 0.3 or (absf(dy - best) <= 0.3 and float(f["area"]) > float(main["area"])):
			best = dy
			main = f
	var ground_y: float = main["top"]
	var ground: Color = main["color"]
	var rect := _walk_rect(scene, floors, main)
	var lo: Vector2 = rect[0]
	var hi: Vector2 = rect[1]
	# ground frame outside the walkable rectangle
	var far := 70.0
	var skirt := ground.darkened(0.06)
	var y := ground_y - 0.08
	for side in [[Vector2(lo.x - far, hi.y + 1.0), Vector2(hi.x + far, hi.y + far)],
			[Vector2(lo.x - far, lo.y - far), Vector2(hi.x + far, lo.y - 1.0)],
			[Vector2(lo.x - far, lo.y - 1.0), Vector2(lo.x - 1.0, hi.y + 1.0)],
			[Vector2(hi.x + 1.0, lo.y - 1.0), Vector2(hi.x + far, hi.y + 1.0)]]:
		var a2: Vector2 = side[0]
		var b2: Vector2 = side[1]
		var c := (a2 + b2) * 0.5
		var sz := b2 - a2
		_p(holder, "box", Vector3(sz.x, 0.1, sz.y), skirt, Vector3(c.x, y - 0.05, c.y))
	# the exits along the edge stay open
	var exits: Array[Vector3] = []
	for n in scene.find_children("*", "TriggerArea", true, false):
		var at := (n as Node3D).global_position
		var near_edge := minf(minf(absf(at.x - lo.x), absf(at.x - hi.x)), minf(absf(at.z - lo.y), absf(at.z - hi.y)))
		if near_edge < 4.0:
			exits.append(at)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(mood) + int(lo.x * 3.0 + hi.y * 5.0)
	var mound := ground.darkened(0.12)
	var leafy: bool = String(main["class"]) == "green"
	var snowy: bool = String(main["class"]) == "snow"
	var edges := [[Vector2(lo.x, lo.y), Vector2(hi.x, lo.y), Vector2(0, -1)],
		[Vector2(lo.x, hi.y), Vector2(hi.x, hi.y), Vector2(0, 1)],
		[Vector2(lo.x, lo.y), Vector2(lo.x, hi.y), Vector2(-1, 0)],
		[Vector2(hi.x, lo.y), Vector2(hi.x, hi.y), Vector2(1, 0)]]
	for e: Array in edges:
		var from: Vector2 = e[0]
		var to: Vector2 = e[1]
		var out: Vector2 = e[2]
		var length := from.distance_to(to)
		var steps := int(length / 4.5) + 1
		for i in steps + 1:
			var p2 := from.lerp(to, float(i) / float(maxi(steps, 1))) + out * rng.randf_range(1.6, 3.2)
			var at := Vector3(p2.x, ground_y, p2.y)
			var blocked := false
			for x: Vector3 in exits:
				if Vector2(x.x - at.x, x.z - at.z).length() < 5.0:
					blocked = true
			if blocked:
				continue
			if style == "mesas" and _rock(holder, at, rng):
				continue
			var w := rng.randf_range(4.0, 7.0)
			var h := rng.randf_range(1.6, 3.4)
			_p(holder, "ellipsoid", Vector3(w, h * 2.0, w * 0.8), mound.lerp(ground, rng.randf() * 0.4), at + Vector3(0, -h * 0.35, 0), Vector3(0, rng.randf() * 180.0, 0))
			if snowy:
				_p(holder, "ellipsoid", Vector3(w * 0.6, h * 0.7, w * 0.5), Color("#f4f8ff"), at + Vector3(0, h * 0.5, 0))
			var r := rng.randf()
			var top := at + Vector3(rng.randf_range(-1.0, 1.0), h * 0.55, rng.randf_range(-0.8, 0.8))
			if leafy and r < 0.45:
				_p(holder, "ellipsoid", Vector3(1.6, 1.2, 1.5), Color("#4fae5a"), top + Vector3(0, 0.3, 0))
			elif leafy and r < 0.7 and style in ["forest", "hills"]:
				_p(holder, "cylinder", Vector3(0.35, 1.6, 0.35), Color("#8a5a3c"), top + Vector3(0, 0.8, 0))
				_p(holder, "cone" if style == "forest" else "ellipsoid", Vector3(1.9, 2.4, 1.9), Color("#3f9a52"), top + Vector3(0, 2.1, 0))
			elif r < 0.85:
				_p(holder, "sphere", Vector3(1.2, 0.8, 1.0), ground.darkened(0.3) if not snowy else Color("#c9d3e2"), top)


## A canyon rock model on the edge (false without the files).
static func _rock(holder: Node3D, at: Vector3, rng: RandomNumberGenerator) -> bool:
	var id: String = CANYON_ROCKS[rng.randi() % CANYON_ROCKS.size()]
	var m := ModelImport.load_static(id)
	if m == null:
		return false
	var tall := rng.randf_range(3.0, 5.5) if id != "kanyon_kaya_b" else rng.randf_range(5.0, 7.5)
	m.scale = Vector3.ONE * tall / ModelImport.static_height(id)
	m.position = at + Vector3(0, -0.3, 0)
	m.rotation.y = rng.randf() * TAU
	holder.add_child(m)
	return true


## The walkable rectangle [lo, hi] (x, z): the WorldBoundary walls where a
## scene has them, else the extent of its floors.
static func _walk_rect(scene: Node3D, floors: Array, main: Dictionary) -> Array:
	# start from the main floor and take in the floors that touch it (far-off
	# decoration slabs don't count)
	var mt: Transform3D = main["xform"]
	var mh: Vector2 = _extent(mt, main["half"])
	var lo := Vector2(mt.origin.x - mh.x, mt.origin.z - mh.y)
	var hi := Vector2(mt.origin.x + mh.x, mt.origin.z + mh.y)
	var grew := true
	while grew:
		grew = false
		for f: Dictionary in floors:
			var t: Transform3D = f["xform"]
			var half: Vector2 = f["half"]
			if absf(float(f["top"]) - float(main["top"])) > 6.0:
				continue
			var ext := _extent(t, half)
			var flo := Vector2(t.origin.x - ext.x, t.origin.z - ext.y)
			var fhi := Vector2(t.origin.x + ext.x, t.origin.z + ext.y)
			var touches := flo.x <= hi.x + 1.0 and fhi.x >= lo.x - 1.0 and flo.y <= hi.y + 1.0 and fhi.y >= lo.y - 1.0
			if touches and (flo.x < lo.x - 0.01 or flo.y < lo.y - 0.01 or fhi.x > hi.x + 0.01 or fhi.y > hi.y + 0.01):
				lo = Vector2(minf(lo.x, flo.x), minf(lo.y, flo.y))
				hi = Vector2(maxf(hi.x, fhi.x), maxf(hi.y, fhi.y))
				grew = true
	for c in scene.find_children("*", "CollisionShape3D", true, false):
		var cs := c as CollisionShape3D
		if not cs.shape is WorldBoundaryShape3D:
			continue
		var pl: Plane = (cs.shape as WorldBoundaryShape3D).plane
		var n := cs.global_transform.basis * pl.normal
		var p := cs.global_transform * (pl.normal * pl.d)
		if n.x < -0.5:
			hi.x = p.x
		elif n.x > 0.5:
			lo.x = p.x
		elif n.z < -0.5:
			hi.y = p.z
		elif n.z > 0.5:
			lo.y = p.z
	return [lo, hi]


## A (rotated) floor's half size along world x and z.
static func _extent(t: Transform3D, half: Vector2) -> Vector2:
	var bx := t.basis.x.normalized()
	var bz := t.basis.z.normalized()
	return Vector2(absf(bx.x) * half.x + absf(bz.x) * half.y, absf(bx.z) * half.x + absf(bz.z) * half.y)
