extends S3Island
## Sezon 3 · Gizli bölge – Mercan Bahçesi. Opens once every Mesaj Şişesi is
## found (flag "yan_sise_bitti"). The underwater garden where Tırıl lived
## with its family: calm and bright, no Mavi Titreme, no Titrekler, nothing
## to fight and nothing that hurts. The keeper moves as if diving (slow
## fall, high soft jumps), rides bubble columns up to the terraces and
## drifts in gentle currents.
##
## Quest "mercan_bahcesi" (Tırıl, at the entrance): meet Tırıl's mother,
## father and little sibling, open the five Anı Kabuğu. Then the family
## gathers at the Işık Kabuğu in the middle: they light the garden (the
## secret last scene), flag "mercan_bahcesi_bitti", and the garden stays a
## place to wander.
##
## Layout (60×50, south = +z): entrance and bubble gate at (0,0,23) · the
## Işık Kabuğu at (0,0,3) · west terrace A (top 2, ramp on its east side) ·
## north-west terrace B (top 5, bubble lift from A) · north-east terrace C
## (top 5, lift from D) · east terrace D (top 2, ramp on its west side) ·
## Mercan Kemer: a deck at 8 between B and C (lifts on B and C, and one from
## the kelp field under it) · shell cave in the south-east corner ·
## mushroom grove in the south-west corner.

const Q := "mercan_bahcesi"
const DONE := "mercan_bahcesi_bitti"
const SAND := Color("#c4b486")
const SAND_DEEP := Color("#4f938f")
const ROCK_A := Color("#e0608f")
const ROCK_B := Color("#7a5fd0")
const ROCK_C := Color("#3fa6a0")
const ROCK_D := Color("#e88a55")
const DECK := Color("#f58fb0")
const GLOW := Color(0.6, 1.0, 0.95)
const WARM := Color(1.0, 0.9, 0.6)
const GATE := Vector3(0, 0, 23.3)
const HEART := Vector3(0, 0, 3)
const MEET := Vector3(0, 0, 7)
const GUIDE := Vector3(-3, 0, 15.5)
## Diving: the keeper's own numbers, set from here (player.gd untouched).
const GRAVITY := 8.0
const JUMP := 6.4
const FALL_MAX := 4.0
## The five Anı Kabuğu: mushroom grove, terrace A, the top of the Mercan
## Kemer, terrace D, the shell cave.
const SHELLS := [Vector3(-23, 0, 17), Vector3(-25, 2, -3), Vector3(4, 8, -19), Vector3(24, 2, -1), Vector3(22, 0, 17)]
const SHELL_COLORS := [Color("#ff9ec4"), Color("#ffd27a"), Color("#9fe8ff"), Color("#c9a6ff"), Color("#9ff0b8")]
## [node name, npc id, home, size, tint, place at the Işık Kabuğu, facing]
const FAMILY := [
	["Kardes", "tiril_kardes", Vector3(-17, 2, 3), 0.6, Vector3(0.85, 1.5, 0.95), Vector3(-1.2, 0, 7.6), 10.0],
	["Anne", "tiril_anne", Vector3(-21, 5, -15), 1.25, Vector3(1.55, 0.9, 1.15), Vector3(-2.9, 0, 6.0), 25.0],
	["Baba", "tiril_baba", Vector3(22, 5, -15), 1.4, Vector3(1.45, 1.2, 0.65), Vector3(2.9, 0, 6.0), -25.0]]
const TIRIL_MEET := Vector3(1.3, 0, 7.8)
## Bubble lifts: [base, height, out]
const LIFTS := [
	[Vector3(-21, 2, -7.1), 3.0, Vector3(0, 0, -1)],     # A → B
	[Vector3(-14.5, 5, -14.1), 3.0, Vector3(0, 0, -1)],  # B → Mercan Kemer
	[Vector3(21, 2, -7.1), 3.0, Vector3(0, 0, -1)],      # D → C
	[Vector3(14.5, 5, -14.1), 3.0, Vector3(0, 0, -1)],   # C → Mercan Kemer
	[Vector3(0, 0, -14.1), 8.0, Vector3(0, 0, -1)]]      # kelp field → Mercan Kemer
## Gentle currents on the floor: [x0, x1, z0, z1, push]
const CURRENTS := [[-11.0, 11.0, -21.5, -10.5, Vector3(1.8, 0, 0)], [-20.0, -6.0, 12.0, 15.5, Vector3(-1.5, 0, 0)]]
## Light-mushrooms the family lights at the end.
const LAMPS := [Vector3(-16, 0, 10.5), Vector3(-4.5, 0, 9.5), Vector3(5, 0, 7.5), Vector3(16, 0, 9), Vector3(-3.5, 0, -4),
	Vector3(-8, 0, -18.5), Vector3(8, 0, -20), Vector3(6, 0, 21.5), Vector3(-6, 0, 21.5),
	Vector3(-15, 2, -6.5), Vector3(-26, 5, -11), Vector3(26, 5, -11), Vector3(16, 2, 2.5), Vector3(27, 0, 20.5)]
## Scenery: [id, x, y, z, height, collider radius (0 = none)]. Tall pieces
## stand on north edges only (the camera looks from the south).
const SCENERY := [
	# terrace B and C, the north rim
	["mercan", -27.0, 5, -23.4, 3.6, 0.8], ["murekkep_mantar", -22.0, 5, -23.6, 4.2, 0.6], ["mercan", -18.2, 5, -23.4, 3.0, 0.7],
	["dev_kabuk", -28.3, 5, -13.0, 1.6, 0.9],
	["mercan", 27.0, 5, -23.4, 3.6, 0.8], ["murekkep_mantar", 22.0, 5, -23.6, 3.8, 0.6], ["mercan", 18.2, 5, -23.4, 2.8, 0.7],
	["dev_kabuk", 28.3, 5, -12.0, 1.5, 0.9],
	# terrace A and D
	["murekkep_mantar", -28.5, 2, -7.6, 2.6, 0.5], ["kiyi_kaya", -28.4, 2, 5.2, 1.2, 0.8], ["mercan", -14.0, 2, -7.9, 2.2, 0.5],
	["mercan", 28.4, 2, -7.6, 2.4, 0.6], ["dev_kabuk", 28.2, 2, 3.4, 1.3, 0.8], ["murekkep_mantar", 14.4, 2, -8.0, 2.0, 0.4],
	# the reef behind the kelp field
	["mercan", -9.0, 3, -23.5, 3.4, 0.0], ["murekkep_mantar", -4.0, 3, -23.6, 3.0, 0.0], ["mercan", 1.5, 3, -23.5, 4.0, 0.0],
	["dev_kabuk", 6.0, 3, -23.6, 1.8, 0.0], ["mercan", 10.0, 3, -23.5, 3.0, 0.0],
	# mushroom grove (south-west)
	["murekkep_mantar", -25.6, 0, 13.4, 3.6, 0.5], ["murekkep_mantar", -20.2, 0, 12.8, 2.8, 0.45], ["murekkep_mantar", -28.0, 0, 20.0, 2.0, 0.4],
	["mercan", -28.3, 0, 10.0, 2.4, 0.6], ["kiyi_kaya", -17.0, 0, 21.8, 0.9, 0.6],
	# shell cave (south-east): a giant shell behind, two beside
	["dev_kabuk", 22.0, 0, 13.0, 5.6, 2.3], ["dev_kabuk", 17.8, 0, 15.4, 2.2, 1.0], ["dev_kabuk", 26.2, 0, 15.4, 2.2, 1.0],
	["murekkep_mantar", 19.9, 0, 15.3, 1.2, 0.0], ["murekkep_mantar", 24.3, 0, 15.2, 1.0, 0.0], ["mercan", 28.4, 0, 9.0, 2.6, 0.6],
	# the middle and the entrance
	["mercan", -11.0, 0, 6.4, 2.0, 0.5], ["mercan", 11.0, 0, 4.4, 1.8, 0.5], ["kiyi_kaya", -12.5, 0, 22.0, 0.9, 0.6],
	["kiyi_kaya", 13.5, 0, 22.4, 1.0, 0.6], ["mercan", 4.4, 0, 23.6, 1.4, 0.0], ["mercan", -4.4, 0, 23.6, 1.4, 0.0],
	# outside the walls
	["mercan", -32.0, 0, 16.0, 3.0, 0.0], ["murekkep_mantar", -32.2, 0, 8.5, 4.0, 0.0], ["kiyi_kaya", -32.0, 0, 23.0, 1.6, 0.0],
	["mercan", 32.0, 0, 14.0, 3.2, 0.0], ["murekkep_mantar", 32.2, 0, 21.0, 3.4, 0.0], ["kiyi_kaya", 32.0, 0, 7.0, 1.8, 0.0],
	["kiyi_kaya", -22.0, 0, 26.6, 0.9, 0.0], ["dev_kabuk", -13.0, 0, 26.8, 1.0, 0.0], ["mercan", -7.0, 0, 26.8, 1.0, 0.0],
	["mercan", 8.0, 0, 26.8, 1.0, 0.0], ["dev_kabuk", 15.0, 0, 26.8, 1.1, 0.0], ["kiyi_kaya", 24.0, 0, 26.6, 0.9, 0.0]]
const KELP := [Vector3(-9.5, 0, -12), Vector3(-6, 0, -20.5), Vector3(-2.5, 0, -17.5), Vector3(4, 0, -20.8), Vector3(9.5, 0, -16),
	Vector3(10.5, 0, -10.5), Vector3(-10.5, 0, -17), Vector3(-14.5, 0, 16.5), Vector3(-10, 0, 20.5), Vector3(14, 0, 14.5),
	Vector3(9, 0, 21.5), Vector3(-8, 0, 0.5), Vector3(8.5, 0, 2.5), Vector3(-27.5, 0, 16)]
const SHAFTS := [Vector3(-8, 0, -14), Vector3(7, 0, -11.5), Vector3(-5, 0, 12.5), Vector3(10, 0, 13), Vector3(-17, 0, 15.5),
	Vector3(17, 0, 12), Vector3(0, 0, -3.5), Vector3(-2, 0, 20)]

var _env: Environment
var _lifts: Array[BubbleLift] = []
var _shells: Array[MemoryShell] = []
var _jellies: Array[Npc] = []
var _lamps: Array[Node3D] = []
var _drift: Node3D
var _syncing := false
var _gathered := false
var _ending := false
var _lit := false
var _rode := false
var _fall_peak := 0.0


func _ready() -> void:
	scene_id = "s3_garden"
	cold_before = 0.0   # no Mavi Titreme here
	var d := GameState.data
	WorldLook.add(self, "ada")
	Pus.set_color(BLUE)
	Pus.set_amount(0.0)
	_underwater()
	lv = Node3D.new()
	lv.name = "Level"
	add_child(lv)
	_build()
	Decor.auto(self, "kumsal")
	# diving: slow fall, high soft jumps, a little drift
	_player.gravity = GRAVITY
	_player.jump_velocity = JUMP
	_player.acceleration = 18.0
	_player.respawn_point = _player.global_position
	if _player.ring:
		_player.ring.cold = 0.0
	var guide := _jelly("Tiril", "tiril", GUIDE, 1.0, Vector3.ZERO, 20.0)
	for f: Array in FAMILY:
		_jelly(f[0], f[1], f[2], f[3], f[4], f[6])
	for i in SHELLS.size():
		var s := MemoryShell.new()
		s.name = "Shell%d" % (i + 1)
		s.bark_id = "mb_ani%d" % (i + 1)
		s.flag = "mb_kabuk%d" % (i + 1)
		s.color = SHELL_COLORS[i]
		s.position = SHELLS[i]
		add_child(s)
		_shells.append(s)
		if not s.is_found():
			Beacon.attach(s, 2.0, s.color.lightened(0.3))
	if d.has_flag(DONE):
		_light_garden(true)
	elif d.quest_state(Q) == "ready":
		_gather(true)
	d.quest_changed.connect(func(_id: String) -> void: _sync())
	d.flags_changed.connect(_sync)
	_sync()
	await get_tree().create_timer(1.8, false).timeout
	if not d.has_flag("mb_geldi"):
		d.set_flag("mb_geldi")
		GameState.bark("mb_basla")
	if d.quest_state(Q) == "none" and not d.has_flag(DONE):
		if not guide.has_node("Beacon"):
			Beacon.attach(guide, 2.8, Tokens.color("spark-white"))
		_hud.show_hint("Girişteki Tırıl ile konuş", "Tırıl ile konuş")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


# --- the look ------------------------------------------------------------

## Blue-green daylight through water instead of the island night.
func _underwater() -> void:
	for c in get_children():
		if c is WorldEnvironment:
			_env = (c as WorldEnvironment).environment
		elif c is DirectionalLight3D:
			var sun := c as DirectionalLight3D
			sun.light_color = Color("#d4fff0")
			sun.light_energy = 0.4
			sun.rotation_degrees = Vector3(-62, 25, 0)
	if _env:
		_env.background_mode = Environment.BG_COLOR
		_env.background_color = Color("#167f98")
		_env.ambient_light_color = Color("#6fd6e0")
		_env.ambient_light_energy = 0.34
		_env.glow_intensity = 0.35
		_env.glow_hdr_threshold = 1.2
		_env.fog_enabled = true
		_env.fog_light_color = Color("#1a88a0")
		_env.fog_density = 0.016
	# rolling light patches on the floor, like sun through waves
	RenderingServer.global_shader_parameter_set("cloud_shadow", 0.3)
	# bubbles and plankton sparkles drifting round the keeper
	_drift = Node3D.new()
	add_child(_drift)
	var b := _cloud(34, 7.0, BubbleLift.bubble_material(), 0.24, Vector3(15, 0.4, 12), Vector3(0, 0.4, 0))
	b.direction = Vector3.UP
	b.spread = 8.0
	b.initial_velocity_min = 0.8
	b.initial_velocity_max = 1.5
	b.scale_amount_min = 0.5
	b.scale_amount_max = 1.6
	b.color_ramp = _fade(Color(0.85, 1.0, 1.0, 0.8))
	var dot := StandardMaterial3D.new()
	dot.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dot.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	dot.vertex_color_use_as_albedo = true
	dot.albedo_texture = Weather.texture("dot")
	var p := _cloud(60, 8.0, dot, 0.08, Vector3(15, 3.5, 12), Vector3(0, 3.0, 0))
	p.spread = 180.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.3
	var pal := Gradient.new()
	pal.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	pal.colors = PackedColorArray([Color(1.2, 2.4, 2.2), Color(2.3, 1.5, 2.0), Color(2.2, 2.2, 1.2)])
	p.color_initial_ramp = pal
	p.color_ramp = _fade(Color.WHITE)


func _cloud(n: int, life: float, mat: Material, size: float, extents: Vector3, offset: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = life
	p.preprocess = life
	p.lifetime_randomness = 0.3
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.position = offset
	p.gravity = Vector3.ZERO
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = mat
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_drift.add_child(p)
	return p


func _fade(col: Color) -> Gradient:
	var g := Gradient.new()
	var clear := Color(col.r, col.g, col.b, 0.0)
	g.offsets = PackedFloat32Array([0.0, 0.15, 0.85, 1.0])
	g.colors = PackedColorArray([clear, col, col, clear])
	return g


func _flat(col: Color, add := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if add:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = col
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	return m


# --- the map -------------------------------------------------------------

func _build() -> void:
	land(Vector3(0, 0, 0), Vector2(60, 50), SAND)
	# the sea floor goes on outside the walls (looks only)
	var far := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	far.mesh = plane
	far.position.y = -0.05
	far.material_override = Toon.material(SAND_DEEP, 0.0)
	lv.add_child(far)
	fence(Vector3.ZERO, Vector2(60, 50))
	_terrace(-30, -12, -9, 7, 2.0, ROCK_A)      # A
	_terrace(-30, -12, -25, -9, 5.0, ROCK_B)    # B
	_terrace(12, 30, -25, -9, 5.0, ROCK_C)      # C
	_terrace(12, 30, -9, 5, 2.0, ROCK_D)        # D
	_terrace(-12, 12, -25, -22, 3.0, ROCK_B.lerp(ROCK_C, 0.5))   # the reef behind the kelp field
	# Mercan Kemer: its feet stand on B and C, the deck runs between them
	land(Vector3(-14.25, 0, -20.5), Vector2(3.5, 9), DECK.darkened(0.12), 7.1, 2.1)
	land(Vector3(14.25, 0, -20.5), Vector2(3.5, 9), DECK.darkened(0.12), 7.1, 2.1)
	land(Vector3(0, 0, -18), Vector2(32, 4), DECK, 8.0, 0.9)
	for sx: float in [-1.0, 1.0]:
		# two coral columns under the long deck
		var col := WorldLook.block(lv, Vector3(sx * 6.0, 3.55, -18.0), Vector3(1.3, 7.1, 1.3), DECK.darkened(0.2))
		col.set_meta("camera_ignore", true)
		prop("mercan", Vector3(sx * 6.0, 8.0, -19.6), 1.6, sx)
		# the arch's rise, drawn under the deck
		for k in 4:
			Toon.part(lv, "box", Vector3(3.2, 0.5, 3.4), DECK.darkened(0.08), Vector3(sx * (11.0 - k * 2.6), 5.9 + k * 0.42, -18.0), Vector3(0, 0, sx * -(26.0 - k * 6.0)))
	_ramp(Vector3(-7, 0, 2), Vector3(-12, 2, 2), 4.0, ROCK_A.lightened(0.12))
	_ramp(Vector3(7, 0, -2), Vector3(12, 2, -2), 4.0, ROCK_D.lightened(0.12))
	for l: Array in LIFTS:
		var lift := BubbleLift.new()
		lift.height = l[1]
		lift.out = l[2]
		lift.position = l[0]
		lv.add_child(lift)
		_lifts.append(lift)
	for c: Array in CURRENTS:
		_current(c)
	# the Işık Kabuğu: where the family gathers
	var heart := Node3D.new()
	heart.name = "Heart"
	heart.position = HEART
	lv.add_child(heart)
	_scenery("dev_kabuk", HEART, 3.6, 0.0)
	_solid(HEART, 1.7, 3.0)
	Toon.part(heart, "sphere", Vector3(0.9, 0.9, 0.9), Color("#fff4d8"), Vector3(0, 0.75, 2.0), Vector3.ZERO, 1.2, 0.02).name = "Pearl"
	var hl := OmniLight3D.new()
	hl.name = "Light"
	hl.light_color = WARM
	hl.omni_range = 9.0
	hl.light_energy = 0.6
	hl.position = Vector3(0, 1.6, 2.0)
	heart.add_child(hl)
	for e: Array in SCENERY:
		var at := Vector3(e[1], e[2], e[3])
		_scenery(e[0], at, e[4], e[1] * 0.7 + e[3] * 0.3)
		if e[5] > 0.0:
			_solid(at, e[5], e[4])
	for at: Vector3 in LAMPS:
		var m := _scenery("murekkep_mantar", at, 1.7, at.x)
		_solid(at, 0.35, 1.6)
		_lamps.append(m)
	for at: Vector3 in KELP:
		_kelp(at)
	for at: Vector3 in SHAFTS:
		_shaft(at)
	_gate()


## A solid block from the floor up to `top`.
func _terrace(x0: float, x1: float, z0: float, z1: float, top: float, col: Color) -> void:
	land(Vector3((x0 + x1) * 0.5, 0, (z0 + z1) * 0.5), Vector2(x1 - x0, z1 - z0), col, top, top + 0.4)


## A walkable slope from `from` up to `to` (both on its middle line).
func _ramp(from: Vector3, to: Vector3, width: float, col: Color) -> void:
	var d := (to - from).normalized()
	var side := Vector3.UP.cross(d).normalized()
	var n := d.cross(side).normalized()
	var body := StaticBody3D.new()
	var size := Vector3(from.distance_to(to) + 0.3, 0.5, width)
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	c.shape = b
	body.add_child(c)
	lv.add_child(body)
	body.transform = Transform3D(Basis(d, n, d.cross(n)), (from + to) * 0.5 - n * 0.25)
	Toon.part(body, "box", size, col, Vector3.ZERO, Vector3.ZERO, 0.0, 0.03)
	# rock under the upper half, so the slope doesn't hang in the water
	var flat := Vector3(d.x, 0, d.z).normalized()
	var under := from.lerp(to, 0.74)
	var h := to.y - from.y
	Toon.part(lv, "box", Vector3(absf(flat.x) * (from.distance_to(to) * 0.5) + absf(flat.z) * width, h * 0.5, absf(flat.z) * (from.distance_to(to) * 0.5) + absf(flat.x) * width),
		col.darkened(0.15), Vector3(under.x, from.y + h * 0.25, under.z))


## Something to bump into (no looks): a prop's trunk.
func _solid(at: Vector3, r: float, h: float) -> void:
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = r
	s.height = h
	c.shape = s
	body.add_child(c)
	body.position = at + Vector3.UP * h * 0.5
	lv.add_child(body)


## A mushroom, a shell, a coral: the model when it exists, else simple shapes.
func _scenery(id: String, at: Vector3, h: float, yaw := 0.0) -> Node3D:
	var m := prop(id, at, h, yaw)
	if m:
		return m
	m = Node3D.new()
	m.position = at
	lv.add_child(m)
	match id:
		"murekkep_mantar":
			Toon.part(m, "cylinder", Vector3(h * 0.22, h * 0.8, h * 0.22), Color("#e6e0f6"), Vector3(0, h * 0.4, 0))
			Toon.part(m, "ellipsoid", Vector3(h * 0.9, h * 0.42, h * 0.9), Color("#7a8ae0"), Vector3(0, h * 0.82, 0))
		"dev_kabuk":
			Toon.part(m, "ellipsoid", Vector3(h * 1.3, h, h * 0.8), Color("#f0d2e0"), Vector3(0, h * 0.45, 0))
		"mercan":
			for k in 3:
				Toon.part(m, "capsule", Vector3(h * 0.16, h * (0.7 + k * 0.15), h * 0.16), Color("#ff8fb0"), Vector3((k - 1) * h * 0.22, h * 0.4, 0), Vector3(0, 0, (k - 1) * -18.0))
		_:
			Toon.part(m, "ellipsoid", Vector3(h * 1.2, h, h), Color("#8a93b8"), Vector3(0, h * 0.4, 0))
	return m


## A tuft of sea grass swaying in the water (no collision).
func _kelp(at: Vector3) -> void:
	var tuft := Node3D.new()
	tuft.position = at
	lv.add_child(tuft)
	for k in 4:
		var h := 1.5 + fmod(at.x * 3.1 + k * 1.7, 1.4)
		var blade := Node3D.new()
		blade.position = Vector3(cos(k * 1.9) * 0.4, 0, sin(k * 1.9) * 0.4)
		tuft.add_child(blade)
		Toon.part(blade, "capsule", Vector3(0.16, h, 0.16), Color("#4fc08a") if k % 2 == 0 else Color("#3aa79a"), Vector3(0, h * 0.5, 0), Vector3.ZERO, 0.0, 0.0)
		var tw := blade.create_tween().set_loops()
		var lean := 9.0 + k * 2.0
		tw.tween_property(blade, "rotation_degrees:z", lean, 1.6 + k * 0.2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(blade, "rotation_degrees:z", -lean, 1.6 + k * 0.2).set_trans(Tween.TRANS_SINE)


## A soft shaft of light coming down through the water.
func _shaft(at: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var cy := CylinderMesh.new()
	cy.top_radius = 0.7
	cy.bottom_radius = 2.2
	cy.height = 9.5
	cy.radial_segments = 12
	cy.cap_top = false
	cy.cap_bottom = false
	mi.mesh = cy
	mi.material_override = _flat(Color(0.8, 1.0, 0.9, 0.045))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = at + Vector3(0, 4.75, 0)
	mi.rotation_degrees = Vector3(0, 0, 10)
	lv.add_child(mi)
	var tw := mi.create_tween().set_loops()
	var wait := 3.0 + fmod(absf(at.x), 2.0)
	tw.tween_property(mi, "rotation_degrees:z", 14.0, wait).set_trans(Tween.TRANS_SINE)
	tw.tween_property(mi, "rotation_degrees:z", 7.0, wait).set_trans(Tween.TRANS_SINE)


## Streaks drifting along a current, so it shows before you feel it.
func _current(c: Array) -> void:
	var push: Vector3 = c[4]
	var p := CPUParticles3D.new()
	p.amount = 26
	p.lifetime = 3.2
	p.preprocess = 3.2
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3((c[1] - c[0]) * 0.5, 0.5, (c[3] - c[2]) * 0.5)
	p.position = Vector3((c[0] + c[1]) * 0.5, 0.8, (c[2] + c[3]) * 0.5)
	p.direction = push.normalized()
	p.spread = 4.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = push.length() * 1.2
	p.initial_velocity_max = push.length() * 1.8
	var q := QuadMesh.new()
	q.size = Vector2(1.5, 0.09)
	var m := _flat(Color.WHITE, false)
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.albedo_texture = Weather.texture("soft")
	q.material = m
	p.mesh = q
	p.color_ramp = _fade(Color(0.85, 1.0, 1.0, 0.55))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lv.add_child(p)


## The way back to Mercan Koyu: a ring of bubbles at the entrance.
func _gate() -> void:
	var g := Node3D.new()
	g.name = "Gate"
	g.position = GATE
	lv.add_child(g)
	Toon.part(g, "ring", Vector3(3.6, 0.22, 3.6), GLOW, Vector3(0, 1.8, 0), Vector3(90, 0, 0), 1.6, 0.0)
	var film := Toon.part(g, "cylinder", Vector3(3.2, 0.02, 3.2), GLOW, Vector3(0, 1.8, 0), Vector3(90, 0, 0), 0.0, 0.0)
	film.material_override = _flat(Color(0.7, 1.0, 1.0, 0.16))
	film.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var p := CPUParticles3D.new()
	p.amount = 18
	p.lifetime = 2.2
	p.preprocess = 2.2
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 1.3
	p.position.y = 0.6
	p.direction = Vector3.UP
	p.spread = 6.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 1.4
	var q := QuadMesh.new()
	q.size = Vector2(0.3, 0.3)
	q.material = BubbleLift.bubble_material()
	p.mesh = q
	p.color_ramp = _fade(Color(0.85, 1.0, 1.0, 0.9))
	g.add_child(p)
	TravelSign.board(lv, "Mercan Koyu", GATE + Vector3(3.4, 1.1, -0.4), 2.6)
	Toon.part(lv, "cylinder", Vector3(0.16, 1.1, 0.16), Color("#a86b45"), GATE + Vector3(3.4, 0.5, -0.5))
	var t := TriggerArea.new()
	t.radius = 1.5
	t.once = false
	t.position = GATE
	lv.add_child(t)
	t.reached.connect(func() -> void: SceneFlow.ask_go("s3_chapter0"))


# --- the family ----------------------------------------------------------

## A jellyfish of Tırıl's family: Tırıl's model, sized and tinted.
func _jelly(node_name: String, npc_id: String, at: Vector3, size: float, tint: Vector3, face: float) -> Npc:
	var n := npc(self, npc_id, "tiril", at, face)
	n.name = node_name
	var m := n._model
	if m.get_child_count() == 0:
		Toon.part(m, "ellipsoid", Vector3(0.9, 0.7, 0.9), Color("#9fd8ff"), Vector3(0, 0.8, 0), Vector3.ZERO, 0.8, 0.02)
		for k in 4:
			Toon.part(m, "capsule", Vector3(0.1, 0.6, 0.1), Color("#c8ecff"), Vector3(cos(k * 1.57) * 0.25, 0.3, sin(k * 1.57) * 0.25), Vector3.ZERO, 0.0, 0.0)
	m.scale *= size
	MobModels._no_pus(m)
	var light_col := Color(0.6, 0.85, 1.0)
	if tint != Vector3.ZERO:
		MobModels._each_material(m, func(mat: ShaderMaterial) -> void:
			mat.set_shader_parameter("desat", 0.6)
			mat.set_shader_parameter("desat_tint", tint))
		light_col = Color(tint.x, tint.y, tint.z) * 0.7
	var l := OmniLight3D.new()
	l.light_color = light_col
	l.omni_range = 3.5
	l.light_energy = 0.9
	l.position.y = 1.0
	n.add_child(l)
	# the name floats above the bigger ones
	for c in n.get_children():
		if c is Label3D:
			(c as Label3D).position.y += maxf(size - 1.0, 0.0) * 1.3 + 0.35
	n.set_meta("float", 0.3 * size)
	_jellies.append(n)
	return n


## Everything found: the family swims to the Işık Kabuğu.
func _gather(instant: bool) -> void:
	if _gathered:
		return
	_gathered = true
	for f: Array in FAMILY:
		_swim(get_node(String(f[0])) as Node3D, f[5], instant)
	_swim(get_node("Tiril") as Node3D, TIRIL_MEET, instant)
	var heart := lv.get_node("Heart") as Node3D
	if not heart.has_node("Beacon"):
		Beacon.attach(heart, 4.4, Tokens.color("spark-yellow"))


func _swim(n: Node3D, to: Vector3, instant: bool) -> void:
	if n.has_node("Beacon"):
		n.get_node("Beacon").queue_free()
	if not instant:
		Effects.sparkle(self, n.global_position + Vector3.UP, GLOW, 14)
	n.global_position = to
	if not instant:
		Effects.sparkle(self, to + Vector3.UP, GLOW, 14)


## Quest steps are counted from the flags (a shell opened or a jellyfish met
## before Tırıl asked counts too), then the garden follows the quest.
func _sync() -> void:
	if _syncing or not is_inside_tree():
		return
	_syncing = true
	var d := GameState.data
	if d.quest_state(Q) == "active":
		for i in 8:
			var c := d.objective_count(Q, "kabuk")
			if _found() <= c.x or c.x >= c.y:
				break
			GameState.notify("collect", "ani_kabugu")
		for i in 4:
			var c := d.objective_count(Q, "aile")
			if _met() <= c.x or c.x >= c.y:
				break
			GameState.notify("meet", "tiril_ailesi")
	_syncing = false
	var state := d.quest_state(Q)
	var guide := get_node_or_null("Tiril") as Node3D
	if guide and state != "none" and guide.has_node("Beacon"):
		guide.get_node("Beacon").queue_free()
		_hud.clear_hint()
	for f: Array in FAMILY:
		var n := get_node_or_null(String(f[0])) as Node3D
		if n == null:
			continue
		var unmet := state == "active" and not d.has_flag("mb_aile_" + String(f[0]).to_lower())
		if unmet and not n.has_node("Beacon"):
			Beacon.attach(n, 2.6 + float(f[3]), Tokens.color("berry"))
		elif not unmet and n.has_node("Beacon"):
			n.get_node("Beacon").queue_free()
	if state == "ready" and not _gathered and not _ending:
		_call_family()


func _found() -> int:
	return _shells.filter(func(s: MemoryShell) -> bool: return s.is_found()).size()


func _met() -> int:
	var n := 0
	for f: Array in FAMILY:
		if GameState.data.has_flag("mb_aile_" + String(f[0]).to_lower()):
			n += 1
	return n


## Waits for the open memory or talk to close, then Tırıl calls you over.
func _call_family() -> void:
	_gathered = true   # only once
	while GameState.in_dialogue:
		await get_tree().create_timer(0.3, false).timeout
	await get_tree().create_timer(0.4, false).timeout
	_gathered = false
	_gather(false)
	Audio.play("lantern")
	GameState.bark("mb_hazir")
	_hud.show_hint("Bahçenin ortasındaki Işık Kabuğu'na git", "Işık Kabuğu'na git")


## The family lights the garden: every light-mushroom, the Işık Kabuğu and
## the water itself.
func _light_garden(instant: bool) -> void:
	if _lit:
		return
	_lit = true
	var heart := lv.get_node("Heart") as Node3D
	(heart.get_node("Light") as OmniLight3D).light_energy = 1.3
	(heart.get_node("Pearl") as MeshInstance3D).material_override = Toon.material(Color("#fff4d8"), 0.02, 1.8)
	if not instant:
		Effects.ring(self, HEART + Vector3(0, 0.3, 2.0), 9.0, WARM, 0.9)
		Audio.play("lantern")
	var soft := Weather.texture("soft")
	for i in _lamps.size():
		var m := _lamps[i]
		if not instant:
			await get_tree().create_timer(0.14, false).timeout
			Effects.sparkle(self, m.global_position + Vector3.UP * 1.8, GLOW, 8)
			if i % 4 == 0:
				Audio.play("blip")
		var col := GLOW if i % 2 == 0 else Color(1.0, 0.75, 0.9)
		for k in 3:
			Toon.part(m, "sphere", Vector3(0.16, 0.16, 0.16), col, Vector3(cos(k * 2.1) * 0.55, 1.6 + k * 0.24, sin(k * 2.1) * 0.55), Vector3.ZERO, 2.6, 0.0)
		# a pool of light on the ground (no real lamp: there are many)
		var pool := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(6.5, 6.5)
		pool.mesh = q
		var pm := _flat(Color(col.r, col.g, col.b, 0.3))
		pm.albedo_texture = soft
		pm.cull_mode = BaseMaterial3D.CULL_BACK
		pool.material_override = pm
		pool.rotation_degrees.x = -90
		pool.position.y = 0.08
		pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.add_child(pool)
	if _env:
		if instant:
			_env.ambient_light_energy = 0.46
		else:
			create_tween().tween_property(_env, "ambient_light_energy", 0.46, 1.2)


## The secret last scene: the family lights the garden, Tırıl's light no
## longer trembles. The reward is the quest's (paid once).
func _finale() -> void:
	_ending = true
	var d := GameState.data
	_hud.clear_hint()
	var heart := lv.get_node("Heart") as Node3D
	if heart.has_node("Beacon"):
		heart.get_node("Beacon").queue_free()
	boss_camera(true, MEET + Vector3(0, 0, -2), 0.5, 16.0)
	GameState.bark("mb_son1")
	await GameState.dialogue_closed
	await _light_garden(false)
	await get_tree().create_timer(1.6, false).timeout
	for n in _jellies:
		Effects.sparkle(self, n.global_position + Vector3.UP * 1.2, WARM, 8)
	GameState.bark("mb_son2")
	await GameState.dialogue_closed
	d.complete_quest(Content.quests[Q])
	d.set_flag(DONE)
	Audio.play("fanfare")
	_hud.show_scene_card("Gizli Bölge", "Mercan Bahçesi ışıl ışıl!", "Kimse karanlıkta yalnız kalmaz.")
	await get_tree().create_timer(3.2, false).timeout
	GameState.bark("mb_son3")
	await GameState.dialogue_closed
	boss_camera(false)
	var gate := lv.get_node("Gate") as Node3D
	if not gate.has_node("Beacon"):
		Beacon.attach(gate, 4.2, Tokens.color("spark-yellow"))
	_hud.show_hint("İstediğin kadar gez. Baloncuk Kapısı seni Mercan Koyu'na götürür.", "Gez ya da Baloncuk Kapısı'ndan dön")
	_ending = false


func _process(delta: float) -> void:
	super._process(delta)
	var t := Time.get_ticks_msec() / 1000.0
	for i in _jellies.size():
		var n := _jellies[i]
		n._model.position.y = float(n.get_meta("float")) + sin(t * 1.3 + i * 1.7) * 0.12
	if _drift:
		_drift.global_position = _player.global_position
	var d := GameState.data
	if _ending or GameState.in_dialogue:
		return
	var at := _player.global_position
	if _gathered and not d.has_flag(DONE) and d.quest_state(Q) == "ready" and at.y < 1.5 \
			and Vector2(at.x - MEET.x, at.z - MEET.z).length() < 5.5 and _player.is_on_floor():
		_finale()
		return
	if _rode and _player.is_on_floor() and at.y > 4.0 and not d.has_flag("mb_baloncuk"):
		d.set_flag("mb_baloncuk")
		GameState.bark("mb_baloncuk")


## Diving: bubble lifts and currents push through `Player.wind`, and nobody
## falls fast.
func _physics_process(delta: float) -> void:
	if _player == null:
		return
	var push := Vector3.ZERO
	var lifted := false
	for l in _lifts:
		push += l.carry(_player, delta)
		lifted = lifted or l.carrying
	if lifted:
		_rode = true
	else:
		var at := _player.global_position
		if at.y < 1.5:
			for c: Array in CURRENTS:
				if at.x > c[0] and at.x < c[1] and at.z > c[2] and at.z < c[3]:
					push += c[4]
	_player.wind = push
	if _player.velocity.y < -FALL_MAX:
		_player.velocity.y = -FALL_MAX
	_fall_peak = minf(_fall_peak, _player.velocity.y)


# --- demo ----------------------------------------------------------------

func _flat_dist(to: Vector3) -> float:
	var a := _player.global_position
	return Vector2(a.x - to.x, a.z - to.z).length()


## Demo: walk through the waypoints; false (and a line) when one isn't reached.
func _go(points: Array, secs := 14.0) -> bool:
	for p: Vector3 in points:
		await walk_to(p, secs)
		if _flat_dist(p) > 1.3:
			print("GARDEN_STUCK want=%s at=%s" % [p, _player.global_position])
			return false
	return true


## Demo: walk into a bubble lift and let it carry (no keys held).
func _ride(i: int) -> bool:
	var l := _lifts[i]
	var ok := await _go([l.global_position], 12.0)
	var top := l.global_position.y + l.height
	for k in 100:
		await get_tree().create_timer(0.1, false).timeout
		if _player.is_on_floor() and _player.global_position.y > top - 0.3:
			break
	await close_dialogs()
	var at := _player.global_position
	ok = ok and _player.is_on_floor() and absf(at.y - top) < 0.4
	print("GARDEN_LIFT n=%d ok=%s landed=(%.1f, %.1f, %.1f)" % [i + 1, ok, at.x, at.y, at.z])
	return ok


func _use(node: Node3D) -> bool:
	await get_tree().create_timer(0.35, false).timeout
	var focus := _player._focus == node
	_player.interact()
	await close_dialogs()
	await get_tree().create_timer(0.2, false).timeout
	await close_dialogs()
	return focus


func _shell_step(i: int, stand: Vector3, route: Array) -> void:
	var d := GameState.data
	var ok := await _go(route + [stand])
	var s := _shells[i]
	var beacon := s.has_node("Beacon")
	var focus := await _use(s)
	print("GARDEN_SHELL n=%d reached=%s floor=%s focus=%s beacon=%s found=%s count=%d/5" % [i + 1, ok, _player.is_on_floor(), focus, beacon,
		s.is_found(), d.objective_count(Q, "kabuk").x])


func _family_step(node_name: String, stand: Vector3, route: Array) -> void:
	var d := GameState.data
	var ok := await _go(route + [stand])
	var focus := await _use(get_node(node_name))
	print("GARDEN_FAMILY id=%s reached=%s floor=%s focus=%s met=%s count=%d/3" % [node_name.to_lower(), ok, _player.is_on_floor(), focus,
		d.has_flag("mb_aile_" + node_name.to_lower()), d.objective_count(Q, "aile").x])


func _run_demo(which: String) -> void:
	match which:
		"garden":
			# the whole garden on foot: every shell, every jellyfish, every lift
			DevTools.auto_dialogue = true
			var d := GameState.data
			var piril0 := d.piril
			print("GARDEN_START open=%s gravity=%.1f jump=%.1f cold=%.1f quest=%s" % [d.has_flag("yan_sise_bitti"), _player.gravity,
				_player.jump_velocity, _player.ring.cold if _player.ring else -1.0, d.quest_state(Q)])
			await _go([GUIDE + Vector3(0.4, 0, 1.7)])
			var focus := await _use(get_node("Tiril"))
			print("GARDEN_QUEST focus=%s state=%s" % [focus, d.quest_state(Q)])
			await _shell_step(0, Vector3(-23, 0, 18.7), [])
			await _family_step("Kardes", Vector3(-17, 2, 4.3), [Vector3(-9, 0, 10), Vector3(-6, 0, 2), Vector3(-13.5, 2, 2)])
			await _shell_step(1, Vector3(-25, 2, -1.3), [])
			await _ride(0)
			await _family_step("Anne", Vector3(-21, 5, -13.2), [])
			await _ride(1)
			await _shell_step(2, Vector3(4, 8, -17.3), [Vector3(-8, 8, -17.3)])
			# east along the deck, off its end: floats down onto terrace C
			await _go([Vector3(12, 8, -17.3), Vector3(18.2, 5, -17.3)])
			await _family_step("Baba", Vector3(20.3, 5, -15), [])
			# off C's south edge down to D
			await _shell_step(3, Vector3(24, 2, -2.7), [Vector3(24, 2, -7)])
			await _ride(2)
			await _ride(3)
			# off the deck into the kelp field, and up again from the floor
			await _go([Vector3(6, 8, -17.3), Vector3(6, 0, -13)], 6.0)
			for k in 60:
				if _player.is_on_floor():
					break
				await get_tree().create_timer(0.1, false).timeout
			var drop := _player.global_position
			print("GARDEN_FALL landed=(%.1f, %.1f, %.1f) fastest=%.1f hp=%d/%d" % [drop.x, drop.y, drop.z, _fall_peak, d.hp, d.max_hp])
			await _ride(4)
			await _go([Vector3(-6, 8, -17.3), Vector3(-6, 0, -13)], 6.0)
			for k in 60:
				if _player.is_on_floor():
					break
				await get_tree().create_timer(0.1, false).timeout
			await _shell_step(4, Vector3(22, 0, 18.8), [Vector3(4, 0, -7), Vector3(9, 0, 10), Vector3(12, 0, 19)])
			for k in 40:
				if _gathered and not GameState.in_dialogue:
					break
				await close_dialogs()
			print("GARDEN_READY state=%s gathered=%s heart_star=%s" % [d.quest_state(Q), _gathered, lv.get_node("Heart").has_node("Beacon")])
			await _go([Vector3(12, 0, 19), Vector3(3, 0, 13), Vector3(0, 0, 10.6)])
			for k in 240:
				if d.has_flag(DONE) and not _ending:
					break
				await close_dialogs()
			var family := _met()
			print("GARDEN_END lit=%s lamps=%d gate_star=%s tiril=%s" % [_lit, _lamps.size(), lv.get_node("Gate").has_node("Beacon"),
				String(DialogueRules.pick_variant(Content.npc("tiril"), d).get("lines", [{}])[0].get("text", ""))])
			# afterwards: a shell reads again, nothing counts twice
			await _go([Vector3(3, 0, 13), Vector3(12, 0, 19), Vector3(22, 0, 18.8)])
			var piril1 := d.piril
			await _use(_shells[4])
			print("GARDEN_AGAIN shell_reads=%s piril_same=%s" % [_shells[4].is_found(), d.piril == piril1])
			print("GARDEN_DONE quest=%s shells=%d/5 family=%d/3 bitti=%s piril=+%d" % [d.quest_state(Q), _found(), family,
				d.has_flag(DONE), d.piril - piril0])
			get_tree().quit()
