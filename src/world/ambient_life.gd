class_name AmbientLife
extends Node3D
## Things that make a place feel alive, in world space (not following the
## camera like Weather): fluffy clouds drifting across the sky and wrapping
## around, and butterflies fluttering near the keeper once the Pus is low.
## Added by WorldLook.add for the outdoor moods.

const CLOUD_MOODS := {"sabah": Color("#ffffff"), "aksam": Color("#e6c6e6"), "orman": Color("#eef6ea"),
	"liman": Color("#ffffff"), "dag": Color("#f6f4ff")}
const BUTTERFLY_MOODS := ["sabah", "orman", "liman"]
const SPAN := 110.0      # clouds wrap around this far from the center
const FLY_RADIUS := 7.0  # butterflies stay this close to their spot

var mood := ""
var _clouds: Array = []        # [node, speed]
var _flies: Array = []         # [node, wings: Array, home: Vector3, phase, speed]
var _center := Vector3.ZERO
var _t := 0.0


static func add(parent: Node3D, mood_id: String) -> AmbientLife:
	if not CLOUD_MOODS.has(mood_id) and not mood_id in BUTTERFLY_MOODS:
		return null
	var a := AmbientLife.new()
	a.name = "AmbientLife"
	a.mood = mood_id
	parent.add_child(a)
	return a


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(mood) + 7
	if CLOUD_MOODS.has(mood):
		var low := mood == "liman"  # Bulut Limanı floats in the clouds
		for i in 9:
			var at := Vector3(rng.randf_range(-SPAN, SPAN), rng.randf_range(-6.0, 4.0) if low else rng.randf_range(24.0, 34.0), rng.randf_range(-SPAN, SPAN))
			_clouds.append([_cloud(at, rng, CLOUD_MOODS[mood]), rng.randf_range(1.2, 2.4)])
	if mood in BUTTERFLY_MOODS:
		for i in 6:
			_flies.append(_butterfly(rng, i))


func _cloud(at: Vector3, rng: RandomNumberGenerator, col: Color) -> Node3D:
	var c := Node3D.new()
	c.position = at
	add_child(c)
	var s := rng.randf_range(3.0, 6.0)
	for k in rng.randi_range(4, 6):
		var off := Vector3(rng.randf_range(-1.6, 1.6) * s, rng.randf_range(-0.2, 0.5) * s, rng.randf_range(-0.8, 0.8) * s)
		var size := Vector3(1.4, 0.9, 1.1) * s * rng.randf_range(0.7, 1.15)
		var mi := Toon.part(c, "ellipsoid", size, col, off, Vector3.ZERO, 0.25, 0.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# a flat shaded underside so it reads as a cartoon cloud
	var under := Toon.part(c, "ellipsoid", Vector3(3.6, 0.5, 2.0) * s, col.darkened(0.12), Vector3(0, -0.3 * s, 0), Vector3.ZERO, 0.0, 0.0)
	under.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return c


func _butterfly(rng: RandomNumberGenerator, i: int) -> Array:
	var col: Color = [Color("#ffd24a"), Color("#ff9ad0"), Color("#9fd6ff"), Color("#ffffff"), Color("#c9a6ff"), Color("#ffb36b")][i % 6]
	var b := Node3D.new()
	b.visible = false
	b.scale = Vector3.ONE * 1.8
	add_child(b)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.025
	cap.height = 0.16
	body.mesh = cap
	body.rotation_degrees.x = 90
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.albedo_color = Tokens.color("outline")
	body.material_override = bm
	b.add_child(body)
	var wings: Array = []
	for s: float in [-1.0, 1.0]:
		var hinge := Node3D.new()
		b.add_child(hinge)
		# a big round front wing and a smaller back wing, flat ovals
		for lobe: Array in [[Vector3(0.09, 0.0, 0.035), Vector3(0.17, 0.01, 0.13), 20.0], [Vector3(0.065, 0.0, -0.055), Vector3(0.11, 0.01, 0.09), -25.0]]:
			var w := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radial_segments = 12
			sm.rings = 4
			w.mesh = sm
			w.material_override = mat
			w.scale = lobe[1]
			w.position = (lobe[0] as Vector3) * Vector3(s, 1, 1)
			w.rotation_degrees.y = float(lobe[2]) * s
			w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			hinge.add_child(w)
		wings.append([hinge, s])
	return [b, wings, Vector3.INF, rng.randf() * TAU, rng.randf_range(0.7, 1.1)]


func _process(delta: float) -> void:
	_t += delta
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var focus := cam.global_position - cam.global_basis.z * 12.0
	_center = Vector3(focus.x, 0.0, focus.z)
	for c: Array in _clouds:
		var n: Node3D = c[0]
		n.position.x += float(c[1]) * delta
		# wrap around the view so the sky never runs out of clouds
		if n.position.x > _center.x + SPAN:
			n.position.x -= SPAN * 2.0
		elif n.position.x < _center.x - SPAN:
			n.position.x += SPAN * 2.0
		if n.position.z > _center.z + SPAN:
			n.position.z -= SPAN * 2.0
		elif n.position.z < _center.z - SPAN:
			n.position.z += SPAN * 2.0
	if _flies.is_empty():
		return
	var show := Pus.amount < 0.45
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var near: Vector3 = player.global_position if player else focus
	for f: Array in _flies:
		var b: Node3D = f[0]
		b.visible = show
		if not show:
			f[2] = Vector3.INF
			continue
		var home: Vector3 = f[2]
		if home == Vector3.INF or Vector2(home.x - near.x, home.z - near.z).length() > 16.0:
			# pick a new spot around the keeper, not right on top of it
			var a := randf() * TAU
			home = near + Vector3(cos(a), 0.0, sin(a)) * randf_range(3.0, 9.0)
			f[2] = home
		var ph: float = f[3]
		var sp: float = f[4]
		var tt := _t * sp + ph
		var p := home + Vector3(sin(tt * 0.7) * FLY_RADIUS * 0.5 + sin(tt * 1.9) * 0.6,
			1.0 + sin(tt * 1.3) * 0.45 + sin(tt * 3.1) * 0.15,
			cos(tt * 0.55) * FLY_RADIUS * 0.4 + cos(tt * 2.3) * 0.5)
		var prev := b.position
		b.position = p
		var dir := p - prev
		if Vector2(dir.x, dir.z).length() > 0.0005:
			b.rotation.y = atan2(dir.x, dir.z)
		var flap := sin(_t * 22.0 + ph) * 0.9
		for w: Array in f[1]:
			(w[0] as Node3D).rotation.z = flap * float(w[1])
