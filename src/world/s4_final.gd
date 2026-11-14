extends Node3D
## Çiçek Şenliği (end of Season 4). Back in Gökkuşağı Köyü's square: the five
## Bahar Tohumu are planted round the Bahar Çeşmesi and it runs again. The
## Çiçek Yarışması is held once more, this time a festival: everybody gives
## a flower from their own garden to somebody else, and Tospik Nine hands the
## prize to Yonca, who helped every garden. Night falls, Dırıl's Ay Çiçeği
## opens in the square and nobody sleeps: Mırıl lights the sky, Hırıl the
## music, Tırıl the water, Dırıl the soil, side by side for the first time.
## Fıstık grumbles, the keeper's own closing beat, then next season's seed:
## a child sings one note wrong, blushes, and hides in a small pink cloud.
## Then `Season4End`. Beats: content/s4_final/cutscenes/cicek_senligi.json.

const FOUNTAIN := Vector3(0, 0, -6)
const STAGE := Vector3(8.5, 0, 1.5)
const ROW_Z := -2.0
const MEADOW := Color("#8fcf7a")
const PATH := Color("#e6d2a8")
const PINK := Color("#ffc2dc")
const NIGHT_SKY := ["#1b2458", "#56649f", "#141c40", "#8a96c8", "#3a4880", 0.25, 0.8, "#eef2ff", 0.0011]
## Villagers and garden keepers round the square: [model id, place, height]
## (0 = the model's own). Neighbours in the list swap flowers.
const CROWD := [["sikir", Vector3(-9.5, 0, -1.5), 1.9], ["circir", Vector3(-11.0, 0, 2.0), 1.9],
	["pitpit", Vector3(11.5, 0, -2.5), 1.9], ["pacali", Vector3(12.5, 0, 5.0), 1.9],
	["korkuluk", Vector3(-12.5, 0, -5.0), 2.6], ["toprak", Vector3(-6.5, 0, -4.5), 0.0],
	["bunny", Vector3(-7.5, 0, 2.5), 0.0], ["mole", Vector3(-9.0, 0, 5.5), 0.0],
	["frog", Vector3(5.5, 0, -4.0), 0.0], ["duckling", Vector3(7.5, 0, -2.5), 0.0],
	["vizik", Vector3(-4.0, 0, 6.8), 0.0], ["nihan", Vector3(3.0, 0, 7.2), 0.0],
	["boynuz", Vector3(10.0, 0, 7.0), 0.0], ["kozacik", Vector3(6.5, 0, 6.5), 0.0]]
const GIFTS := ["lale", "papatya", "gul", "ay_cicegi"]

@onready var _hud: Hud = $Hud
@onready var _cam: Camera3D = $Camera
var _lv: Node3D
var _env: Environment
var _sun: DirectionalLight3D
var _keeper: Node3D
var _yonca: Node3D
var _tospik: Node3D
var _hiril: Node3D
var _miril: Node3D
var _tiril: Node3D
var _diril: Node3D
var _fistik: Node3D
var _child: Node3D
var _cloud: Node3D
var _crowd: Array[Node3D] = []
var _dancers: Array[Node3D] = []
var _beds: Array[Vector3] = []
var _lamps: Array[Vector3] = []
var _dancing := false
var _t0 := 0


func _ready() -> void:
	_env = WorldLook.add(self, "sabah")
	for c in get_children():
		if c is DirectionalLight3D:
			_sun = c
	Pus.set_amount(0.0)
	_cam.make_current()
	_build_square()
	_cast()
	WorldLook.ground_detail(self, "zemin_cayir", 0.22, 0.09)
	Decor.auto(self, "koy")
	# a keeper with no closing line of their own borrows Pati's
	var d := GameState.data
	if not Content.barks.has("s4f_" + d.character_id):
		Content.barks["s4f_" + d.character_id] = Content.barks.get("s4f_pati", [])
	_t0 = Time.get_ticks_msec()
	await get_tree().create_timer(1.9, false).timeout
	if DevTools.demo != "" and DisplayServer.get_name() == "headless":
		DevTools.auto_dialogue = true
	var cs := CutscenePlayer.new()
	cs.scene = self
	cs.camera = _cam
	cs.hud = _hud
	add_child(cs)
	cs.play("cicek_senligi")


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	if _tiril:
		_tiril.position.y = 0.7 + sin(t * 1.3) * 0.18
	if _dancing:
		for i in _dancers.size():
			var m := _dancers[i]
			if is_instance_valid(m):
				m.position.y = absf(sin(t * 4.0 + i * 0.7)) * 0.25


# --- the square ---------------------------------------------------------

func _build_square() -> void:
	_lv = Node3D.new()
	_lv.name = "Level"
	add_child(_lv)
	WorldLook.block(_lv, Vector3(0, -0.5, -6), Vector3(84, 1, 76), MEADOW, 0.0)
	Toon.part(_lv, "cylinder", Vector3(21, 0.06, 21), PATH, Vector3(0, 0.02, -1.5), Vector3.ZERO, 0.0, 0.0)
	Toon.part(_lv, "box", Vector3(3.4, 0.06, 16), PATH, Vector3(0, 0.0, 16), Vector3.ZERO, 0.0, 0.0)
	if _prop("bahar_cesmesi", FOUNTAIN, 3.6) == null:
		Toon.part(_lv, "cylinder", Vector3(3.4, 0.7, 3.4), Color("#d8d2c4"), FOUNTAIN + Vector3(0, 0.35, 0))
		Toon.part(_lv, "cylinder", Vector3(0.7, 2.6, 0.7), Color("#d8d2c4"), FOUNTAIN + Vector3(0, 1.3, 0))
	# houses behind and beside the square, trees between them
	for h: Array in [[Vector3(-13, 0, -15), 20], [Vector3(-4.5, 0, -18), 0], [Vector3(5, 0, -18), 0],
			[Vector3(13.5, 0, -15), -20], [Vector3(-20, 0, -6), 70], [Vector3(20.5, 0, -6), -70]]:
		if _prop("prop_house", h[0], 5.4, deg_to_rad(h[1])) == null:
			Toon.part(_lv, "box", Vector3(4.6, 3.2, 4.2), Color("#f4e6cf"), h[0] + Vector3(0, 1.6, 0))
			Toon.part(_lv, "cone", Vector3(6.4, 2.4, 6.4), Color("#e8607a"), h[0] + Vector3(0, 4.4, 0))
	for p: Vector3 in [Vector3(-8.8, 0, -17.5), Vector3(0.2, 0, -20.5), Vector3(9.4, 0, -17.5), Vector3(-17.5, 0, -12),
			Vector3(18, 0, -12), Vector3(-21, 0, 2.5), Vector3(21, 0, 3), Vector3(-17, 0, 9), Vector3(17.5, 0, 9.5)]:
		if _prop("prop_tree", p, 5.6) == null:
			Toon.part(_lv, "cylinder", Vector3(0.6, 2.4, 0.6), Color("#8a5a3c"), p + Vector3(0, 1.2, 0))
			Toon.part(_lv, "sphere", Vector3(3.4, 3.4, 3.4), Color("#58b05a"), p + Vector3(0, 3.6, 0))
	# flower beds round the edge of the square, two market stalls
	_beds = [Vector3(-13.5, 0, 1.0), Vector3(13.8, 0, 1.2), Vector3(-10.5, 0, -8.5), Vector3(10.5, 0, -8.5),
		Vector3(-14.5, 0, 6.5), Vector3(15.0, 0, 8.0)]
	for b: Vector3 in _beds:
		if _prop("cicek_tarhi", b, 1.1) == null:
			Toon.part(_lv, "box", Vector3(2.2, 0.4, 1.4), Color("#a8794f"), b + Vector3(0, 0.2, 0))
	_prop("pazar_tezgahi", Vector3(-15.5, 0, -2.5), 3.0, deg_to_rad(60))
	_prop("pazar_tezgahi", Vector3(16.0, 0, -3.0), 3.0, deg_to_rad(-60))
	# the little stage and the hills far behind the roofs
	Toon.part(_lv, "box", Vector3(3.2, 0.4, 2.4), Color("#c79a66"), STAGE + Vector3(0, 0.2, 0))
	for i in 4:
		Toon.part(_lv, "sphere", Vector3(0.3, 0.3, 0.3), Tokens.color(["berry", "spark-yellow", "sky", "spark-green"][i]),
			STAGE + Vector3(-1.2 + i * 0.8, 0.45, 1.25), Vector3.ZERO, 0.0, 0.0)
	for i in 5:
		var hill := _prop("koy_tepe", Vector3(-44.0 + i * 22.0, -0.5, -52.0 - (i % 2) * 6.0), 15.0 + (i % 3) * 4.0, i * 1.3)
		if hill == null:
			Toon.part(_lv, "sphere", Vector3(26, 22, 20), Color("#6fb07a"), Vector3(-44.0 + i * 22.0, 0, -54.0), Vector3.ZERO, 0.0, 0.0)
	# lantern posts: dark by day, lit when the night falls
	_lamps = [Vector3(-7.5, 0, -8.0), Vector3(7.5, 0, -8.0), Vector3(-11.5, 0, 4.5), Vector3(11.5, 0, 9.5), Vector3(0, 0, 9.5)]
	for p: Vector3 in _lamps:
		Toon.part(_lv, "cylinder", Vector3(0.16, 2.6, 0.16), Color("#7a5a44"), p + Vector3(0, 1.3, 0))
		Toon.part(_lv, "sphere", Vector3(0.5, 0.56, 0.5), Color("#f4efe6"), p + Vector3(0, 2.8, 0))


## A scenery model standing on `at`, `h` meters tall (null when it has no file).
func _prop(id: String, at: Vector3, h: float, yaw := 0.0) -> Node3D:
	var m := ModelImport.prop_copy(id)
	if m == null:
		return null
	var b := ModelImport.static_bounds(id)
	var s := h / maxf(b.size.y, 0.01)
	var holder := Node3D.new()
	_lv.add_child(holder)
	holder.position = at
	holder.rotation.y = yaw
	holder.add_child(m)
	m.scale = Vector3.ONE * s
	m.position = -Vector3(b.position.x + b.size.x * 0.5, b.position.y, b.position.z + b.size.z * 0.5) * s
	return holder


func _cast() -> void:
	var d := GameState.data
	_keeper = KeeperModels.build(d.character_id, d.character_look)
	_stand(_keeper, Vector3(-1.6, 0, 2.6), FOUNTAIN)
	_dancers.append(_keeper)
	var others := ["pati", "bado", "citir", "lumi", "tipis_panda", "tosbi", "yonca"]
	others.erase(d.character_id)
	for i in others.size():
		var k := KeeperModels.build(others[i])
		_stand(k, Vector3(-6.4 + i * 2.5, 0, 4.4 + (i % 2) * 0.9), FOUNTAIN)
		_dancers.append(k)
		if others[i] == "yonca":
			_yonca = k
	if _yonca == null:
		_yonca = _keeper   # you are Yonca: the prize comes to you
	_tospik = NpcModels.build("turtle")
	_stand(_tospik, Vector3(-4.6, 0, 0.4), Vector3(0, 0, 4))
	_dancers.append(_tospik)
	_fistik = FistikModel.build()
	_stand(_fistik, Vector3(4.8, 0, 2.4), FOUNTAIN)
	# the four feeling-friends, still scattered among the crowd
	_miril = MirilModel.star_child()
	MobModels._no_pus(_miril)
	_stand(_miril, Vector3(-5.6, 0.3, -2.6), Vector3(0, 0, 6))
	_hiril = HirilModel.build(true)
	MobModels._no_pus(_hiril)
	_stand(_hiril, Vector3(3.6, 0, -1.0), Vector3(0, 0, 6))
	_tiril = _model("tiril", Color("#9fd8ff"))
	_stand(_tiril, Vector3(-2.6, 0.7, -3.4), Vector3(0, 0, 6))
	_diril = _model("diril", Color("#7fcf8a"))
	_stand(_diril, Vector3(5.6, 0, 0.2), Vector3(0, 0, 6))
	for f: Array in CROWD:
		var m := NpcModels.build(f[0])
		if float(f[2]) > 0.0:
			var own := float(ModelImport._options(f[0]).get("height", f[2]))
			m.scale *= float(f[2]) / maxf(own, 0.1)
		_stand(m, f[1], Vector3(0, 0, -1))
		_crowd.append(m)
		_dancers.append(m)
	# the child who will sing, waiting by the stage
	_child = NpcModels.build("bunny_sleepy")
	_child.scale *= 0.8
	_stand(_child, STAGE + Vector3(2.4, 0, 0.8), Vector3(0, 0, 3))


func _model(id: String, col: Color) -> Node3D:
	var m := ModelImport.load_model(id)
	if m == null:
		m = Node3D.new()
		Toon.part(m, "sphere", Vector3(0.9, 0.9, 0.9), col, Vector3(0, 0.6, 0), Vector3.ZERO, 1.2, 0.0)
	MobModels._no_pus(m)
	return m


func _stand(m: Node3D, at: Vector3, look: Vector3) -> void:
	add_child(m)
	m.position = at
	m.rotation.y = atan2(look.x - at.x, look.z - at.z)


# --- beats -------------------------------------------------------------

## The five Bahar Tohumu fly from the keeper to the soil round the fountain
## and a flower pops up from each.
func seeds_planted() -> void:
	var i := 0
	for id: String in GardenTravel.SEEDS:
		var a := deg_to_rad(-64.0 + i * 32.0)
		var spot := FOUNTAIN + Vector3(sin(a) * 3.3, 0, cos(a) * 3.3)
		var orb := Toon.part(self, "sphere", Vector3(0.42, 0.42, 0.42), SeedTracker.COLORS[id], _keeper.position + Vector3(0, 1.2, 0), Vector3.ZERO, 1.6, 0.03)
		var tw := orb.create_tween()
		tw.tween_interval(i * 0.22)
		tw.tween_property(orb, "position", spot + Vector3(0, 0.1, 0), 1.1).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(_sprout.bind(id, spot))
		tw.tween_callback(orb.queue_free)
		i += 1
	Audio.play("memory")


func _sprout(id: String, spot: Vector3) -> void:
	var f := _prop(id, spot, 1.5)
	if f == null:
		# no model (the water lily): a leaf and a pale blue bloom
		f = Node3D.new()
		_lv.add_child(f)
		f.position = spot
		Toon.part(f, "cylinder", Vector3(1.1, 0.08, 1.1), Color("#4faf62"), Vector3(0, 0.05, 0))
		for k in 6:
			var a := k * TAU / 6.0
			Toon.part(f, "ellipsoid", Vector3(0.26, 0.5, 0.2), SeedTracker.COLORS.get(id, Color("#9fd8ff")), Vector3(sin(a) * 0.2, 0.36, cos(a) * 0.2), Vector3(cos(a) * 28.0, 0, -sin(a) * 28.0))
		Toon.part(f, "sphere", Vector3(0.2, 0.2, 0.2), Color("#ffe27a"), Vector3(0, 0.42, 0))
	f.scale = Vector3.ONE * 0.01
	f.create_tween().tween_property(f, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Effects.sparkle(self, spot + Vector3.UP * 0.6, SeedTracker.COLORS.get(id, Color.WHITE), 10)
	Audio.play("stone")


## The Bahar Çeşmesi runs again: a pool round its foot and a jet on top.
func fountain_runs() -> void:
	var pool := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 2.5
	disc.bottom_radius = 2.5
	disc.height = 0.04
	disc.radial_segments = 32
	pool.mesh = disc
	WorldLook.water(pool, "lake")
	_lv.add_child(pool)
	pool.position = FOUNTAIN + Vector3(0, 0.09, 0)
	pool.scale = Vector3(0.05, 1, 0.05)
	pool.create_tween().tween_property(pool, "scale", Vector3.ONE, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for k in 3:
		Effects.ring(self, FOUNTAIN + Vector3(0, 0.2, 0), 3.0 + k * 1.6, Color("#9fd8ff"), 0.6 + k * 0.2)
	Audio.play("fanfare")
	_jet()


func _jet() -> void:
	while is_inside_tree():
		Effects.sparkle(self, FOUNTAIN + Vector3(0, 3.7, 0), Color("#bfe6ff"), 6)
		await get_tree().create_timer(0.8, false).timeout


## Not a contest any more: everybody gives a flower to their neighbour.
func flowers_swap() -> void:
	var n := _crowd.size()
	for i in n:
		var from := _crowd[i]
		var to := _crowd[i + 1 if i % 2 == 0 else i - 1] if n % 2 == 0 or i < n - 1 else _keeper
		_gift(from, to, GIFTS[i % GIFTS.size()], i * 0.12)
	_gift(_tospik, _keeper, "papatya", 0.3)
	_gift(_keeper, _tospik, "lale", 0.5)
	Audio.play("lantern")


func _gift(from: Node3D, to: Node3D, id: String, delay: float) -> void:
	var f := ModelImport.prop_copy(id)
	var holder := Node3D.new()
	add_child(holder)
	if f:
		var b := ModelImport.static_bounds(id)
		var s := 0.7 / maxf(b.size.y, 0.01)
		f.scale = Vector3.ONE * s
		f.position = -Vector3(b.position.x + b.size.x * 0.5, b.position.y, b.position.z + b.size.z * 0.5) * s
		holder.add_child(f)
	else:
		Toon.part(holder, "sphere", Vector3(0.36, 0.36, 0.36), "berry", Vector3(0, 0.35, 0))
	var a := from.position + Vector3(0, 1.3, 0)
	var side := (to.position - from.position).normalized().cross(Vector3.UP) * 0.45
	var b2 := to.position + Vector3(0, 0.05, 0) - (to.position - from.position).normalized() * 0.7 + side
	holder.position = a
	holder.scale = Vector3.ONE * 0.01
	var tw := holder.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(holder, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.5)
	tw.tween_method(func(k: float) -> void:
		holder.position = a.lerp(b2, k) + Vector3(0, sin(k * PI) * 2.2, 0), 0.0, 1.0, 1.3).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		Effects.sparkle(self, holder.position + Vector3.UP * 0.5, Tokens.color("spark-yellow"), 6))


## Tospik Nine's prize: a flower garland floats over to Yonca.
func prize() -> void:
	var crown := Node3D.new()
	add_child(crown)
	Toon.part(crown, "ring", Vector3(0.7, 0.1, 0.7), Color("#58b05a"), Vector3.ZERO)
	for k in 6:
		var a := k * TAU / 6.0
		Toon.part(crown, "sphere", Vector3(0.2, 0.2, 0.2), Tokens.color(["berry", "spark-yellow", "sky"][k % 3]), Vector3(sin(a) * 0.35, 0.04, cos(a) * 0.35), Vector3.ZERO, 0.6, 0.0)
	var a0 := _tospik.position + Vector3(0, 1.6, 0)
	var top := ModelImport._bounds(_yonca, Transform3D.IDENTITY).end.y * _yonca.scale.y
	var b0 := _yonca.position + Vector3(0, clampf(top, 0.8, 2.0) + 0.12, 0)
	crown.position = a0
	var tw := crown.create_tween()
	tw.tween_method(func(k: float) -> void:
		crown.position = a0.lerp(b0, k) + Vector3(0, sin(k * PI) * 1.6, 0)
		crown.rotation.y = k * TAU, 0.0, 1.0, 1.6).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		for k in 3:
			Effects.ring(self, _yonca.position + Vector3.UP * 0.3, 1.6 + k * 1.0, Tokens.color("spark-yellow"), 0.5 + k * 0.2)
		Effects.sparkle(self, b0, Tokens.color("spark-yellow"), 18)
		Audio.play("fanfare")
		_dancers.erase(_yonca)
		var hop := _yonca.create_tween()
		for j in 3:
			hop.tween_property(_yonca, "position:y", 0.5, 0.18).set_ease(Tween.EASE_OUT)
			hop.tween_property(_yonca, "position:y", 0.0, 0.18).set_ease(Tween.EASE_IN)
		hop.tween_callback(func() -> void:
			crown.reparent(_yonca)
			_dancers.append(_yonca)))


## Day turns to a clear spring night; the lanterns of the square light up.
func night_falls() -> void:
	if DevTools.demo != "":
		print("S4F night t=%.1f" % ((Time.get_ticks_msec() - _t0) / 1000.0))
	var day: Array = WorldLook.SKIES["sabah"]
	var sky := WorldLook.sky_material(_env)
	var names := ["top_color", "horizon_color", "bottom_color", "cloud_color", "cloud_shade"]
	var amb0 := _env.ambient_light_color
	var e0 := _env.ambient_light_energy
	var sun0 := _sun.light_color if _sun else Color.WHITE
	var se0 := _sun.light_energy if _sun else 0.6
	_env.glow_hdr_threshold = 1.0
	# the toon shading hardly follows the ambient light: a soft blue wash
	# between the 3D picture and the HUD makes the evening read as night
	var wash_layer := CanvasLayer.new()
	wash_layer.layer = 0
	add_child(wash_layer)
	var wash := ColorRect.new()
	wash.color = Color(0.1, 0.13, 0.36, 0.0)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash_layer.add_child(wash)
	wash.create_tween().tween_property(wash, "color:a", 0.34, 3.2).set_trans(Tween.TRANS_SINE)
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void:
		if sky:
			for i in names.size():
				sky.set_shader_parameter(names[i], Color(String(day[i])).lerp(Color(String(NIGHT_SKY[i])), k))
			sky.set_shader_parameter("cloud_amount", lerpf(float(day[5]), float(NIGHT_SKY[5]), k))
			sky.set_shader_parameter("star_amount", lerpf(float(day[6]), float(NIGHT_SKY[6]), k))
			sky.set_shader_parameter("sun_color", Color(String(day[7])).lerp(Color(String(NIGHT_SKY[7])), k))
			sky.set_shader_parameter("sun_size", lerpf(float(day[8]), float(NIGHT_SKY[8]), k))
		_env.ambient_light_color = amb0.lerp(Color("#8b9de0"), k)
		_env.ambient_light_energy = lerpf(e0, 0.36, k)
		_env.glow_intensity = lerpf(0.35, 0.6, k)
		if _sun:
			_sun.light_color = sun0.lerp(Color("#b8c8ff"), k)
			_sun.light_energy = lerpf(se0, 0.3, k)
		RenderingServer.global_shader_parameter_set("cloud_shadow", lerpf(float(day[9]), 0.0, k)), 0.0, 1.0, 3.2).set_trans(Tween.TRANS_SINE)
	var cols := ["spark-yellow", "berry", "sky", "honey", "spark-green"]
	for i in _lamps.size():
		var at := _lamps[i] + Vector3(0, 2.8, 0)
		var col := Tokens.color(cols[i % cols.size()])
		var lit := get_tree().create_timer(1.4 + i * 0.3, false)
		lit.timeout.connect(func() -> void:
			var gem := Toon.part(self, "sphere", Vector3(0.56, 0.62, 0.56), col, at, Vector3.ZERO, 2.0, 0.0)
			var l := OmniLight3D.new()
			l.light_color = col.lerp(Color("#fff1c0"), 0.6)
			l.omni_range = 9.0
			l.light_energy = 1.5
			gem.add_child(l)
			Audio.play("lantern"))


## Dırıl's hour: the Ay Çiçeği opens in the middle of the square.
func moon_flower() -> void:
	var spot := Vector3(1.0, 0, ROW_Z)
	var tw := _diril.create_tween()
	tw.tween_property(_diril, "position", spot, 1.0).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		var open := ModelImport.load_model("diril_cicek")
		if open:
			MobModels._no_pus(open)
			add_child(open)
			open.position = spot
			_diril.queue_free()
			_diril = open
		_diril.rotation.y = 0.0
		var s := _diril.scale
		_diril.scale = s * 0.3
		_diril.create_tween().tween_property(_diril, "scale", s * 1.5, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var l := OmniLight3D.new()
		l.light_color = Color("#dfe8ff")
		l.omni_range = 12.0
		l.light_energy = 2.0
		l.position = Vector3(0, 1.4, 0.4)
		_diril.add_child(l)
		for k in 3:
			Effects.ring(self, spot + Vector3.UP * 0.1, 2.0 + k * 1.6, Color("#dfe8ff"), 0.7 + k * 0.2)
		Effects.sparkle(self, spot + Vector3.UP * 1.2, Color("#dfe8ff"), 22)
		Audio.play("memory"))


## The four feeling-friends in one row: sky, music, water and soil all glow.
func four_friends() -> void:
	var places := {_miril: Vector3(-3.4, 0.3, ROW_Z), _hiril: Vector3(-1.3, 0, ROW_Z), _tiril: Vector3(3.2, 0.7, ROW_Z)}
	for m: Node3D in places:
		m.rotation.y = 0.0
		m.create_tween().tween_property(m, "position", places[m], 1.2).set_trans(Tween.TRANS_SINE)
	var l := OmniLight3D.new()
	l.light_color = Color("#9fd8ff")
	l.omni_range = 9.0
	l.light_energy = 1.6
	l.position = FOUNTAIN + Vector3(0, 1.2, 1.5)
	add_child(l)
	_dancing = true
	_beat()
	_sky()
	_soil()


func _beat() -> void:
	while _dancing and is_inside_tree():
		Audio.play("drum")
		Effects.ring(self, _hiril.position + Vector3.UP * 0.4, 2.6, Tokens.color("hp"), 0.5)
		await get_tree().create_timer(0.6, false).timeout


func _sky() -> void:
	var cols := ["spark-purple", "sky", "spark-yellow", "berry", "spark-green"]
	while _dancing and is_inside_tree():
		Effects.sparkle(self, Vector3(randf_range(-16, 16), randf_range(8, 13), randf_range(-30, -16)), Tokens.color(cols[randi() % cols.size()]), 14)
		Effects.ring(self, FOUNTAIN + Vector3(0, 0.2, 0), randf_range(2.6, 4.2), Color("#9fd8ff"), 0.8)
		await get_tree().create_timer(0.7, false).timeout


## Dırıl's light: small pale sprouts glow up from the soil of the square.
func _soil() -> void:
	while _dancing and is_inside_tree():
		var at := Vector3(randf_range(-11, 11), 0.0, randf_range(-4, 8))
		var bud := Toon.part(self, "ellipsoid", Vector3(0.22, 0.4, 0.22), Color("#c8ffd0"), at + Vector3(0, 0.2, 0), Vector3.ZERO, 1.8, 0.0)
		bud.scale = Vector3.ONE * 0.01
		var tw := bud.create_tween()
		tw.tween_property(bud, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(2.2)
		tw.tween_property(bud, "scale", Vector3.ONE * 0.01, 0.4)
		tw.tween_callback(bud.queue_free)
		Effects.ring(self, at + Vector3.UP * 0.05, 0.9, Color("#c8ffd0"), 0.6)
		await get_tree().create_timer(0.45, false).timeout


## Next season's seed, part one: a child hops on the stage and sings.
func child_sings() -> void:
	_dancing = false
	for m in _dancers:
		if is_instance_valid(m):
			m.position.y = 0.0
	var top := STAGE + Vector3(0, 0.4, 0)
	var tw := _child.create_tween()
	tw.tween_method(func(k: float) -> void:
		_child.position = (STAGE + Vector3(2.4, 0, 0.8)).lerp(top, k) + Vector3(0, sin(k * PI) * 0.9, 0), 0.0, 1.0, 0.7)
	tw.tween_callback(func() -> void:
		_child.rotation.y = atan2(-STAGE.x, 6.0 - STAGE.z)
		_notes())


func _notes() -> void:
	for i in 5:
		if not is_instance_valid(_child) or _cloud:
			return
		Effects.sparkle(self, _child.position + Vector3(randf_range(-0.5, 0.5), 1.3, 0.2), Tokens.color(["sky", "spark-yellow", "berry"][i % 3]), 4)
		await get_tree().create_timer(0.7, false).timeout


## One wrong note, a giggle: pink cheeks, and a small pink cotton cloud
## settles over the child, who hides inside it.
func pink_cloud() -> void:
	var h := ModelImport._bounds(_child, Transform3D.IDENTITY).end.y * _child.scale.y
	for s: float in [-1.0, 1.0]:
		var cheek := Toon.part(self, "sphere", Vector3(0.16, 0.14, 0.1), Color("#ff8fb4"), _child.position + Vector3(0, h * 0.62, 0), Vector3.ZERO, 0.8, 0.0)
		cheek.position += _child.global_transform.basis.z.normalized() * 0.3 + _child.global_transform.basis.x.normalized() * 0.2 * s
		cheek.set_meta("cheek", true)
		cheek.add_to_group("s4f_cheek")
	Audio.play("pop")
	_cloud = _puff(1.0)
	add_child(_cloud)
	var over := _child.position + Vector3(0, 5.0, 0)
	_cloud.position = over
	_cloud.scale = Vector3.ONE * 0.05
	var tw := _cloud.create_tween()
	tw.tween_property(_cloud, "scale", Vector3.ONE * 0.6, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.4)
	tw.tween_property(_cloud, "position", _child.position + Vector3(0, 0.7, 0), 1.3).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(_cloud, "scale", Vector3.ONE * 1.25, 1.3)
	tw.tween_callback(func() -> void:
		_child.visible = false
		for c in get_tree().get_nodes_in_group("s4f_cheek"):
			c.queue_free()
		Effects.sparkle(self, _cloud.position, PINK, 12)
		Audio.play("memory"))


## A soft cloud of pink cotton balls.
func _puff(size: float) -> Node3D:
	var c := Node3D.new()
	for p: Array in [[Vector3(0, 0, 0), 1.3], [Vector3(-0.7, -0.1, 0.1), 1.0], [Vector3(0.7, -0.1, 0.05), 1.05],
			[Vector3(-0.3, 0.4, -0.1), 0.95], [Vector3(0.35, 0.38, 0.0), 0.9], [Vector3(0.0, -0.15, 0.45), 0.9]]:
		Toon.part(c, "sphere", Vector3.ONE * float(p[1]) * size, PINK, (p[0] as Vector3) * size, Vector3.ZERO, 0.35, 0.0, 0.0)
	return c


## Part two: far over the hills many more pink clouds gather.
func far_clouds() -> void:
	for i in 7:
		var c := _puff(5.0 + (i % 3) * 1.5)
		add_child(c)
		c.position = Vector3(-36.0 + i * 12.0, 30.0, -62.0 - (i % 2) * 6.0)
		c.scale = Vector3.ONE * 0.05
		var tw := c.create_tween()
		tw.tween_interval(i * 0.25)
		tw.tween_property(c, "scale", Vector3.ONE, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(c, "position:y", 19.0 + (i % 3) * 2.5, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Fıstık's spines stand up for a moment.
func fistik_bristles() -> void:
	var s := _fistik.scale
	var tw := _fistik.create_tween()
	tw.tween_property(_fistik, "scale", s * Vector3(1.18, 1.1, 1.18), 0.14).set_ease(Tween.EASE_OUT)
	tw.tween_property(_fistik, "scale", s, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Audio.play("stone")


## The picture goes dark before the summary.
func fade_dark() -> void:
	var f := ColorRect.new()
	f.color = Color(0, 0, 0, 0)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.add_child(f)
	f.create_tween().tween_property(f, "color:a", 1.0, 1.8)


func season_end() -> void:
	_dancing = false
	var d := GameState.data
	d.set_flag("sezon4_bitti")
	d.set_flag("sezon4_senlik")
	d.scene_id = "s4_chapter0"
	SaveGame.write(d)
	var panel := Season4End.new()
	_hud.add_child(panel)
	if DevTools.demo != "" and DisplayServer.get_name() == "headless":
		print("S4FINAL senlik=%s bitti=%s scene_id=%s keeper=%s" % [d.has_flag("sezon4_senlik"), d.has_flag("sezon4_bitti"), d.scene_id, d.character_id])
		get_tree().quit()
		return
	var to: String = await panel.chosen
	SceneFlow.go_to(to, to != "title")
