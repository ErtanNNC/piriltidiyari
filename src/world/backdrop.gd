class_name Backdrop
extends RefCounted
## Far scenery around a scene so its edges don't end in empty sky: rolling
## hills with trees (village), a wall of forest, floating islands, snowy peaks,
## dark castle spires. Placed on a ring outside the walkable floors and tinted
## toward the sky's horizon color (aerial haze). No collision.

const STYLE := {
	"sabah": "hills", "aksam": "hills", "pus": "hills", "kule": "hills",
	"orman": "forest", "liman": "islands", "dag": "peaks", "kale": "spires",
}


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
