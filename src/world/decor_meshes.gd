class_name DecorMeshes
extends RefCounted
## Little procedural meshes for ground decor (see Decor). Vertex color alpha 0
## = tinted by the instance color, alpha 1 = keeps its own color. UV.y is the
## sway weight for grass and flowers.

static var _cache: Dictionary = {}

const STEM := Color(0.36, 0.62, 0.32, 1.0)
const CREAM := Color(1.0, 0.95, 0.84, 1.0)
const HONEY := Color(1.0, 0.8, 0.3, 1.0)
const TINT := Color(1, 1, 1, 0)


static func get_mesh(id: String) -> ArrayMesh:
	if _cache.has(id):
		return _cache[id]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var smooth_normals := true
	match id:
		"grass": _grass(st, rng, 7, 0.32); smooth_normals = false
		"grass_short": _grass(st, rng, 6, 0.2); smooth_normals = false
		"flower": _flower(st, rng, 5); smooth_normals = false
		"tulip": _flower(st, rng, 3); smooth_normals = false
		"pebble": _rock(st, rng, Vector3(0.22, 0.12, 0.18), 0.18)
		"rock": _rock(st, rng, Vector3(0.55, 0.38, 0.46), 0.22)
		"mushroom": _mushroom(st)
		"fern": _fern(st, rng); smooth_normals = false
		"crystal": _crystal(st); smooth_normals = false
		"leaf": _leaf(st); smooth_normals = false
		"tuft": _rock(st, rng, Vector3(0.5, 0.2, 0.42), 0.08)
	if smooth_normals:
		st.generate_normals()
	var mesh := st.commit()
	_cache[id] = mesh
	return mesh


static func _v(st: SurfaceTool, p: Vector3, c: Color, h: float, n := Vector3.UP) -> void:
	st.set_color(c)
	st.set_uv(Vector2(0, h))
	st.set_normal(n)
	st.add_vertex(p)


## A clump of bent blades (3 triangles each), normals up so they light like the ground.
static func _grass(st: SurfaceTool, rng: RandomNumberGenerator, blades: int, height: float) -> void:
	for i in blades:
		var a := TAU * i / blades + rng.randf_range(-0.4, 0.4)
		var r := rng.randf_range(0.0, 0.12)
		var root := Vector3(cos(a) * r, 0, sin(a) * r)
		var out := Vector3(cos(a), 0, sin(a))
		var side := out.cross(Vector3.UP).normalized() * rng.randf_range(0.022, 0.032)
		var h := height * rng.randf_range(0.7, 1.25)
		var lean := out * rng.randf_range(0.04, 0.12)
		var mid := root + lean * 0.4 + Vector3(0, h * 0.55, 0)
		var tip := root + lean + Vector3(0, h, 0)
		var v := rng.randf_range(0.9, 1.1)
		var col := Color(v, v, v, 0)
		_v(st, root - side, col, 0.0); _v(st, root + side, col, 0.0); _v(st, mid + side * 0.6, col, 0.55)
		_v(st, root - side, col, 0.0); _v(st, mid + side * 0.6, col, 0.55); _v(st, mid - side * 0.6, col, 0.55)
		_v(st, mid - side * 0.6, col, 0.55); _v(st, mid + side * 0.6, col, 0.55); _v(st, tip, col, 1.0)


static func _flower(st: SurfaceTool, rng: RandomNumberGenerator, petals: int) -> void:
	var top := Vector3(0, rng.randf_range(0.26, 0.34), 0)
	# stem: two crossed thin quads
	for s: Vector3 in [Vector3(0.018, 0, 0), Vector3(0, 0, 0.018)]:
		_v(st, -s, STEM, 0.0); _v(st, s, STEM, 0.0); _v(st, top + s, STEM, 1.0)
		_v(st, -s, STEM, 0.0); _v(st, top + s, STEM, 1.0); _v(st, top - s, STEM, 1.0)
	# two leaves
	for s: float in [-1.0, 1.0]:
		var b := Vector3(0, 0.06, 0)
		var l := Vector3(0.11 * s, 0.13, 0.02)
		_v(st, b, STEM, 0.2); _v(st, b + Vector3(0, 0.05, 0.025), STEM, 0.3); _v(st, l, STEM, 0.45)
	# petals: flat diamonds around the head, slightly tilted up
	var pr := 0.085 if petals > 3 else 0.07
	for i in petals:
		var a := TAU * i / petals
		var d := Vector3(cos(a), 0, sin(a))
		var side := d.cross(Vector3.UP) * 0.045
		var c := top + Vector3(0, 0.01, 0)
		var far := top + d * pr * 2.0 + Vector3(0, 0.05 if petals > 3 else 0.12, 0)
		var m := top + d * pr + Vector3(0, 0.03, 0)
		_v(st, c, TINT, 1.0); _v(st, m + side, TINT, 1.0); _v(st, far, TINT, 1.0)
		_v(st, c, TINT, 1.0); _v(st, far, TINT, 1.0); _v(st, m - side, TINT, 1.0)
	# center
	for i in 6:
		var a0 := TAU * i / 6.0
		var a1 := TAU * (i + 1) / 6.0
		var c := top + Vector3(0, 0.035, 0)
		_v(st, c + Vector3(0, 0.012, 0), HONEY, 1.0)
		_v(st, c + Vector3(cos(a0), 0, sin(a0)) * 0.035, HONEY, 1.0)
		_v(st, c + Vector3(cos(a1), 0, sin(a1)) * 0.035, HONEY, 1.0)


## A squashed, jittered low-poly ball (pebble, rock, snow tuft).
static func _rock(st: SurfaceTool, rng: RandomNumberGenerator, size: Vector3, jitter: float) -> void:
	var rings := 4
	var segs := 7
	var pts: Array = []
	for r in rings + 1:
		var row: Array = []
		var phi := PI * float(r) / rings
		for s in segs:
			var th := TAU * float(s) / segs
			var p := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
			if r > 0 and r < rings:
				p *= 1.0 + rng.randf_range(-jitter, jitter)
			p = p * size * 0.5
			p.y = maxf(p.y, -size.y * 0.15) + size.y * 0.32
			row.append(p)
		pts.append(row)
	for r in rings:
		for s in segs:
			var a: Vector3 = pts[r][s]
			var b: Vector3 = pts[r][(s + 1) % segs]
			var c: Vector3 = pts[r + 1][s]
			var d: Vector3 = pts[r + 1][(s + 1) % segs]
			for p: Vector3 in [a, c, b, b, c, d]:
				st.set_color(TINT)
				st.set_uv(Vector2(0, 0))
				st.add_vertex(p)


static func _mushroom(st: SurfaceTool) -> void:
	var segs := 8
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		# stem
		for p: Vector3 in [d0 * 0.05, d1 * 0.05, d0 * 0.04 + Vector3(0, 0.16, 0),
				d1 * 0.05, d1 * 0.04 + Vector3(0, 0.16, 0), d0 * 0.04 + Vector3(0, 0.16, 0)]:
			st.set_color(CREAM); st.set_uv(Vector2(0, 0)); st.add_vertex(p)
		# cap: two rings to a dome
		var y0 := 0.13
		for ring in 3:
			var r0 := 0.14 * cos(PI * 0.5 * ring / 3.0)
			var r1 := 0.14 * cos(PI * 0.5 * (ring + 1) / 3.0)
			var h0 := y0 + 0.1 * sin(PI * 0.5 * ring / 3.0)
			var h1 := y0 + 0.1 * sin(PI * 0.5 * (ring + 1) / 3.0)
			var p00 := d0 * r0 + Vector3(0, h0, 0)
			var p01 := d1 * r0 + Vector3(0, h0, 0)
			var p10 := d0 * r1 + Vector3(0, h1, 0)
			var p11 := d1 * r1 + Vector3(0, h1, 0)
			for p: Vector3 in [p00, p10, p01, p01, p10, p11]:
				st.set_color(TINT); st.set_uv(Vector2(0, 0)); st.add_vertex(p)
		# underside
		for p: Vector3 in [Vector3(0, y0 - 0.01, 0), d1 * 0.14 + Vector3(0, y0, 0), d0 * 0.14 + Vector3(0, y0, 0)]:
			st.set_color(CREAM); st.set_uv(Vector2(0, 0)); st.add_vertex(p)
	# white dots
	for dot: Vector3 in [Vector3(0.05, 0.225, 0.03), Vector3(-0.06, 0.215, -0.02), Vector3(0.0, 0.232, -0.06)]:
		for i in 5:
			var a0 := TAU * i / 5.0
			var a1 := TAU * (i + 1) / 5.0
			for p: Vector3 in [dot + Vector3(0, 0.006, 0), dot + Vector3(cos(a1), 0, sin(a1)) * 0.022, dot + Vector3(cos(a0), 0, sin(a0)) * 0.022]:
				st.set_color(Color(1, 1, 1, 1)); st.set_uv(Vector2(0, 0)); st.add_vertex(p)


static func _fern(st: SurfaceTool, rng: RandomNumberGenerator) -> void:
	var fronds := 6
	for i in fronds:
		var a := TAU * i / fronds + rng.randf_range(-0.2, 0.2)
		var d := Vector3(cos(a), 0, sin(a))
		var side := d.cross(Vector3.UP)
		var length := rng.randf_range(0.45, 0.6)
		var steps := 4
		for k in steps:
			var t0 := float(k) / steps
			var t1 := float(k + 1) / steps
			var p0 := d * length * t0 + Vector3(0, 0.32 * sin(PI * 0.75 * t0), 0)
			var p1 := d * length * t1 + Vector3(0, 0.32 * sin(PI * 0.75 * t1), 0)
			var w0 := 0.07 * sin(PI * minf(t0 + 0.12, 1.0))
			var w1 := 0.07 * sin(PI * minf(t1 + 0.12, 1.0)) if k < steps - 1 else 0.0
			_v(st, p0 - side * w0, TINT, t0); _v(st, p0 + side * w0, TINT, t0); _v(st, p1 + side * w1, TINT, t1)
			_v(st, p0 - side * w0, TINT, t0); _v(st, p1 + side * w1, TINT, t1); _v(st, p1 - side * w1, TINT, t1)


static func _crystal(st: SurfaceTool) -> void:
	# three hexagonal shards leaning out from one point
	var shards := [[Vector3.ZERO, 0.0, 0.0, 0.42], [Vector3(0.09, 0, 0.03), 25.0, 0.6, 0.28], [Vector3(-0.08, 0, -0.05), -22.0, 2.4, 0.24]]
	for s: Array in shards:
		var basis := Basis(Vector3.UP, float(s[2])) * Basis(Vector3.RIGHT, deg_to_rad(float(s[1])))
		var h: float = s[3]
		var r := h * 0.22
		for i in 6:
			var a0 := TAU * i / 6.0
			var a1 := TAU * (i + 1) / 6.0
			var b0 := Vector3(cos(a0) * r, 0, sin(a0) * r)
			var b1 := Vector3(cos(a1) * r, 0, sin(a1) * r)
			var t0 := b0 + Vector3(0, h * 0.72, 0)
			var t1 := b1 + Vector3(0, h * 0.72, 0)
			var tip := Vector3(0, h, 0)
			var n := (b0 + b1).normalized()
			for p: Vector3 in [b0, t0, b1, b1, t0, t1]:
				st.set_color(TINT); st.set_uv(Vector2(0, 0)); st.set_normal(basis * n); st.add_vertex(s[0] + basis * p)
			var nt := (n + Vector3.UP).normalized()
			for p: Vector3 in [t0, tip, t1]:
				st.set_color(TINT); st.set_uv(Vector2(0, 0)); st.set_normal(basis * nt); st.add_vertex(s[0] + basis * p)


static func _leaf(st: SurfaceTool) -> void:
	var n := 8
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var p0 := Vector3(cos(a0) * 0.11, 0.012 + absf(cos(a0)) * 0.025, sin(a0) * 0.06)
		var p1 := Vector3(cos(a1) * 0.11, 0.012 + absf(cos(a1)) * 0.025, sin(a1) * 0.06)
		_v(st, Vector3(0, 0.012, 0), TINT, 0.0); _v(st, p0, TINT, 0.0); _v(st, p1, TINT, 0.0)
