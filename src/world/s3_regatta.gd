extends S3Island
## Sezon 3 · oyun sonrası – Gece Regatası. A boat race round the islets of
## the night sea: the keeper sits in the Kabuk Kayık (`RaceBoat`) and steers
## it through the lit buoy gates in order. The more friends on board (one
## per pearl found), the faster it goes; Olta's boat parts help too. Nobody
## loses: finishing gives a medal by time (bronz for any finish), each medal
## pays once. Olta hosts on the start islet and keeps his boat stall.
##
## Layout: start islet 12×10 round (0,0,0), pier north of it, boat at
## (2.6,0,-10). The course runs clockwise: north-east round the lighthouse
## rock and two islets, south, then west round the fourth islet and back.

const SAND := Color("#c7ad7c")
const START := Vector3(2.6, 0, -10.0)
const GATE_REACH := 5.2
const GATE_HALF := 4.6
## Gate centres [x, z] in order; the last one is the finish.
const GATES := [[8, -26], [24, -44], [48, -46], [58, -22], [46, -6], [62, 10], [54, 30],
	[30, 26], [10, 34], [-18, 22], [-42, 6], [-52, -20], [-36, -38], [-14, -24]]
## Islets and rocks: [x, z, radius, look].
const ROCKS := [[0, 0.5, 7.4, "start"], [-2, -45, 7.0, "fener"], [40, -30, 6.0, "kaya"], [48, 14, 7.0, "mercan"],
	[-38, -18, 6.0, "kabuk"], [22, 4, 3.0, "sutun"], [-20, -4, 3.0, "sutun"], [-8, 52, 3.5, "sutun"],
	[76, -8, 3.5, "sutun"], [-60, 8, 3.0, "sutun"], [14, -62, 3.0, "sutun"]]
## Blue mist patches on the racing line: [x, z, radius].
const MISTS := [[36, -45, 6.5], [20, 30, 6.5], [-47, -7, 6.5]]
## Seconds for silver and gold (bronze: any finish).
const SILVER := 50.0
const GOLD := 38.0
const PAY := {"bronz": [30, 40], "gumus": [60, 80], "altin": [120, 150]}

## "Tekrar yarış" starts the next run straight from the countdown.
static var again := false

var boat: RaceBoat
var state := "shore"      ## shore → count → race → done
var time := 0.0
var next := 0
var medal := ""
var paid: Array[String] = []
var paid_piril := 0
var _gates: Array[Node3D] = []
var _gate_light: OmniLight3D
var _count: Label3D
var _hint_t := 0.0
var _tip_t := 0.0
var _pulse := 0.0
var _quit_t := 0.0
var _away := false
var _sign: BoatSign
var _arrow: Node3D


## The board by the pier: "Bin".
class BoatSign extends Interactable:
	var pressed: Callable

	func _build() -> void:
		action_label = "Bin"
		reach = 2.0
		Toon.part(self, "box", Vector3(0.14, 1.4, 0.14), Color("#a8794f"), Vector3(0, 0.7, 0))
		TravelSign.board(self, "Gece Regatası", Vector3(0, 1.6, 0.05), 2.6)

	func use(_by: Node) -> void:
		pressed.call()


func _ready() -> void:
	begin("s3_regatta")
	cold_before = 0.0
	Pus.set_amount(0.06)
	var d := GameState.data
	_build()
	boat = RaceBoat.new()
	boat.name = "Boat"
	boat.position = START
	add_child(boat)
	for r: Array in ROCKS:
		boat.obstacles.append(Vector3(r[0], r[1], r[2]))
	for m: Array in MISTS:
		boat.mists.append(Vector3(m[0], m[1], m[2]))
	boat.bounds = Vector3(5, -8, 84)
	boat.bumped.connect(func() -> void:
		Audio.play("boing")
		Effects.ring(self, boat.global_position, 2.5, Color(0.8, 0.95, 1.0, 0.8), 0.4))
	_fit_boat()
	d.flags_changed.connect(_fit_boat)   # a part bought at Olta's stall shows at once
	npc(self, "olta", "olta", Vector3(-3.2, 0, -2.4), 150.0).name = "Olta"
	_sign = BoatSign.new()
	_sign.name = "Sign"
	_sign.pressed = _on_sign
	_sign.position = Vector3(2.4, 0, -4.2)
	lv.add_child(_sign)
	Beacon.attach(_sign, 2.9, Tokens.color("spark-white"))
	_player.respawn_point = _player.global_position
	if DevTools.demo != "":
		DevTools.auto_dialogue = true
		await get_tree().create_timer(1.0, false).timeout
		await close_dialogs()
		_run_demo(DevTools.demo)
		return
	await get_tree().create_timer(1.8, false).timeout
	if state != "shore":
		return
	if again:
		again = false
		_board()
	elif not d.has_flag("regata_geldi"):
		d.set_flag("regata_geldi")
		GameState.bark("rg_basla")
		await GameState.dialogue_closed
		_shore_hint()
	else:
		_shore_hint()


func _shore_hint() -> void:
	if state == "shore":
		_hud.show_hint("Yıldızlı tabelaya git: kayığa bin. Olta'da kayık parçaları var.", "Yıldızlı tabelaya git, Bin'e bas!")


func _fit_boat() -> void:
	var d := GameState.data
	var s := RaceBoat.stats_for(d)
	boat.fit(s, ShoreTravel.pearls(d), d.has_flag("owned_tekne_yelken"), d.has_flag("owned_tekne_kurek"),
		d.has_flag("owned_tekne_fener"), d.character_id)


# --- the sea ------------------------------------------------------------------

func _build() -> void:
	land(Vector3(0, 0, 0), Vector2(12, 10), SAND)
	# two slabs under the sea at the corners of the course: the Backdrop puts
	# its far islands outside every floor, so they stay off the racing line
	for c: Vector3 in [Vector3(-62, -1.2, -66), Vector3(72, -1.2, 50)]:
		Toon.part(lv, "box", Vector3(2.0, 0.4, 2.0), Color("#1d2a52"), c, Vector3.ZERO, 0.0, 0.0)
	fence(Vector3(0, 0, 0), Vector2(12, 10))
	# the pier (only to look at: the keeper boards from the board on the sand)
	var wood := Color("#a8794f")
	Toon.part(lv, "box", Vector3(2.2, 0.2, 7.0), wood, Vector3(0.2, 0.05, -8.2))
	for z: float in [-6.0, -8.5, -11.2]:
		for x: float in [-0.8, 1.2]:
			Toon.part(lv, "cylinder", Vector3(0.22, 1.0, 0.22), Color("#7a5236"), Vector3(x, -0.3, z))
	if prop("balikci_evi", Vector3(-3.4, 0, 2.6), 4.2, 0.5) == null:
		Toon.part(lv, "box", Vector3(3.0, 2.4, 2.6), Color("#d9b48a"), Vector3(-3.4, 1.2, 2.6))
	prop("sezlong", Vector3(3.6, 0, 2.8), 1.1, -0.6)
	_torch_post(Vector3(-4.6, 0, -3.8))
	_torch_post(Vector3(4.8, 0, -3.8))
	for r: Array in ROCKS:
		if String(r[3]) != "start":
			_islet(Vector3(r[0], 0, r[1]), float(r[2]), String(r[3]))
	for m: Array in MISTS:
		_mist_patch(Vector3(m[0], 0, m[1]), float(m[2]))
	# little things adrift, off the racing line
	var b1 := prop("mesaj_sisesi", Vector3(30, SEA_Y - 0.1, -16), 1.2, 0.8)
	if b1:
		b1.rotation.z = 0.5
	prop("oyuncak_tekne", Vector3(-28, SEA_Y - 0.2, 34), 2.2, 2.1)
	prop("oyuncak_tekne", Vector3(66, SEA_Y - 0.2, -40), 2.2, -0.7)
	for i in GATES.size():
		_gates.append(_gate(i))
	_gate_light = OmniLight3D.new()
	_gate_light.light_color = Color(1.0, 0.86, 0.45)
	_gate_light.omni_range = 12.0
	_gate_light.light_energy = 2.2
	lv.add_child(_gate_light)
	_gate_light.visible = false


func _torch_post(at: Vector3) -> void:
	Toon.part(lv, "cylinder", Vector3(0.16, 1.8, 0.16), Color("#7a5236"), at + Vector3(0, 0.9, 0))
	Toon.part(lv, "sphere", Vector3(0.5, 0.6, 0.5), Color("#ffb85a"), at + Vector3(0, 2.0, 0), Vector3.ZERO, 2.5, 0.0)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.75, 0.45)
	l.omni_range = 9.0
	l.light_energy = 1.6
	l.position = at + Vector3(0, 2.2, 0)
	lv.add_child(l)


## A round islet of sand or rock with something on it.
func _islet(at: Vector3, r: float, look: String) -> void:
	if look == "sutun":
		if prop("kayalik_sutun", at + Vector3(0, SEA_Y - 0.4, 0), r * 2.6, at.x * 0.3) == null:
			Toon.part(lv, "cone", Vector3(r * 1.6, r * 2.4, r * 1.6), Color("#6f7a8c"), at + Vector3(0, r * 1.0, 0))
		prop("kiyi_kaya", at + Vector3(r * 0.5, SEA_Y - 0.3, r * 0.4), r * 0.9, at.z * 0.2)
		return
	var sand := Toon.part(lv, "cylinder", Vector3(r * 1.9, 0.9, r * 2.05), SAND, at + Vector3(0, -0.4, 0), Vector3.ZERO, 0.0, 0.02)
	sand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	match look:
		"fener":
			if prop("deniz_feneri", at, 13.0, 0.4) == null:
				Toon.part(lv, "cylinder", Vector3(1.6, 9.0, 2.4), Color("#f1ede2"), at + Vector3(0, 4.5, 0))
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.9, 0.6)
			l.omni_range = 22.0
			l.light_energy = 2.0
			l.position = at + Vector3(0, 9.0, 3.0)
			lv.add_child(l)
			prop("kiyi_kaya", at + Vector3(-4.0, 0, 2.5), 2.4, 1.0)
			prop("kiyi_kaya", at + Vector3(4.2, 0, -2.0), 2.0, 2.4)
		"kaya":
			prop("kiyi_kaya", at + Vector3(-1.0, 0, 0.5), 5.0, 0.3)
			prop("kiyi_kaya", at + Vector3(2.8, 0, -1.6), 3.2, 1.9)
			prop("sis_agaci", at + Vector3(1.2, 0, 2.6), 4.6, 0.0)
		"mercan":
			prop("mercan", at + Vector3(-2.0, 0, -1.0), 4.4, 0.0)
			prop("mercan", at + Vector3(2.4, 0, 1.4), 3.2, 1.6)
			prop("kum_kalesi", at + Vector3(0.6, 0, -2.8), 2.2, 0.4)
			prop("murekkep_mantar", at + Vector3(-1.4, 0, 3.0), 2.0, 0.0)
		"kabuk":
			prop("dev_kabuk", at + Vector3(0.0, 0, 0.0), 4.2, 0.9)
			prop("kiyi_kaya", at + Vector3(-3.0, 0, -2.2), 2.2, 0.2)
			prop("mercan", at + Vector3(2.8, 0, 2.4), 2.4, 2.0)


## Blue mist lying on the water: slows the boat (hardly with the Pruva Feneri).
func _mist_patch(at: Vector3, r: float) -> void:
	var holder := Node3D.new()
	holder.position = at
	lv.add_child(holder)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.5, 0.75, 1.0, 0.6)
	mat.albedo_texture = Weather.texture("soft")
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var rng := RandomNumberGenerator.new()
	rng.seed = int(at.x * 31.0 + at.z)
	for i in 14:
		var q := MeshInstance3D.new()
		var mesh := QuadMesh.new()
		var s := rng.randf_range(4.0, 7.0)
		mesh.size = Vector2(s, s * 0.7)
		q.mesh = mesh
		q.material_override = mat
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var a := rng.randf() * TAU
		var rr := sqrt(rng.randf()) * (r - 1.5)
		q.position = Vector3(cos(a) * rr, rng.randf_range(0.4, 1.8), sin(a) * rr)
		holder.add_child(q)
		var tw := q.create_tween().set_loops()
		var drift := Vector3(rng.randf_range(-1.2, 1.2), 0, rng.randf_range(-1.2, 1.2))
		tw.tween_property(q, "position", q.position + drift, rng.randf_range(2.5, 4.0)).set_trans(Tween.TRANS_SINE)
		tw.tween_property(q, "position", q.position, rng.randf_range(2.5, 4.0)).set_trans(Tween.TRANS_SINE)
	var ring := Toon.part(holder, "ring", Vector3(r * 2.0, 0.18, r * 2.0), Color(0.35, 0.55, 1.0), Vector3(0, SEA_Y + 0.12, 0), Vector3.ZERO, 0.5, 0.0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _gate_pos(i: int) -> Vector3:
	return Vector3(GATES[i][0], 0, GATES[i][1])


## Two lit buoys across the racing line, a ring on the water between them.
func _gate(i: int) -> Node3D:
	var g := Node3D.new()
	g.name = "Gate" + str(i + 1)
	g.position = _gate_pos(i)
	var before := START if i == 0 else _gate_pos(i - 1)
	var after := _gate_pos(mini(i + 1, GATES.size() - 1))
	var along := (after - before) if i < GATES.size() - 1 else (g.position - before)
	g.rotation.y = atan2(along.x, along.z)
	lv.add_child(g)
	var last := i == GATES.size() - 1
	for sx: float in [-1.0, 1.0]:
		var b := Node3D.new()
		b.name = "BuoyL" if sx < 0.0 else "BuoyR"
		b.position = Vector3(sx * GATE_HALF, SEA_Y, 0)
		g.add_child(b)
		Toon.part(b, "sphere", Vector3(1.2, 1.0, 1.2), Color("#e8674f") if not last else Color("#f4f1e6"), Vector3(0, 0.25, 0))
		Toon.part(b, "cylinder", Vector3(0.14, 2.2, 0.14), Color("#f4f1e6"), Vector3(0, 1.6, 0))
		var lamp := Toon.part(b, "sphere", Vector3(0.6, 0.6, 0.6), Color("#8a94a6"), Vector3(0, 2.8, 0), Vector3.ZERO, 0.4, 0.0)
		lamp.name = "Lamp"
		if last:
			Toon.part(b, "box", Vector3(0.9, 0.6, 0.06), Color("#f4f1e6"), Vector3(0.5, 2.2, 0))
		var tw := b.create_tween().set_loops()
		var off := 0.4 + 0.1 * float(i % 3)
		tw.tween_property(b, "position:y", SEA_Y + 0.12, 1.1 + off).set_trans(Tween.TRANS_SINE)
		tw.tween_property(b, "position:y", SEA_Y, 1.1 + off).set_trans(Tween.TRANS_SINE)
	var ring := Toon.part(g, "ring", Vector3(GATE_HALF * 1.7, 0.16, GATE_HALF * 1.7), Color("#8a94a6"), Vector3(0, SEA_Y + 0.1, 0), Vector3.ZERO, 0.3, 0.0)
	ring.name = "Ring"
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return g


## Colours a gate: "wait" (grey), "next" (gold, star, light) or "done" (green).
func _paint(i: int, how: String) -> void:
	var g := _gates[i]
	var col: Color = {"wait": Color("#8a94a6"), "next": Color("#ffd35a"), "done": Color("#7be08a")}[how]
	var glow: float = {"wait": 0.4, "next": 1.4, "done": 0.7}[how]
	for n in g.find_children("Lamp", "MeshInstance3D", true, false) + g.find_children("Ring", "MeshInstance3D", false, false):
		(n as MeshInstance3D).material_override = Toon.material(col, 0.0, glow)
	var old := g.get_node_or_null("Beacon")
	if old:
		old.queue_free()
	if how == "next":
		Beacon.attach(g, 4.2, Tokens.color("spark-yellow"))
		_gate_light.visible = true
		_gate_light.position = g.position + Vector3(0, 2.5, 0)


# --- the race -----------------------------------------------------------------

func _on_sign() -> void:
	if state != "shore":
		return
	var pick: String = await _hud.ask("Gece Regatası", [{"id": "go", "label": "Yarışa başla"},
		{"id": "home", "label": "Koya dön"}, {"id": "", "label": "Burada kal"}])
	if pick == "go":
		_board()
	elif pick == "home":
		Audio.play("splash")
		SceneFlow.go_to("s3_chapter0")


## The keeper gets in, the camera follows the boat, 3-2-1.
func _board() -> void:
	if state != "shore":
		return
	state = "count"
	_hud.clear_hint()
	if _sign.has_node("Beacon"):
		_sign.get_node("Beacon").queue_free()
	Audio.play("splash")
	_player.set_physics_process(false)
	_player.velocity = Vector3.ZERO
	_seat()
	var cam: FollowCamera = $Camera
	cam._target = boat
	cam.distance = 23.0
	cam.look_height = 0.4
	next = 0
	_paint(0, "next")
	# a small arrow before the bow always points at the next gate
	_arrow = Node3D.new()
	add_child(_arrow)
	Toon.part(_arrow, "cone", Vector3(0.9, 1.5, 0.9), Color("#ffd35a"), Vector3(0, 0, 0.4), Vector3(90, 0, 0), 1.0, 0.0).scale.z = 0.35
	_count = Label3D.new()
	_count.font = Tokens.font_for("text-hero")
	_count.font_size = 220
	_count.pixel_size = 0.012
	_count.modulate = Tokens.color("panel@light")
	_count.outline_size = 36
	_count.outline_modulate = Tokens.color("outline")
	_count.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_count.no_depth_test = true
	_count.position = Vector3(0, 5.0, 0)
	boat.add_child(_count)
	for n: String in ["3", "2", "1"]:
		_count.text = n
		_pop(_count)
		Audio.play("blip")
		await get_tree().create_timer(0.8, false).timeout
	_count.text = "Başla!"
	_pop(_count)
	Audio.play("bell")
	state = "race"
	time = 0.0
	_show_progress(true)
	await get_tree().create_timer(0.9, false).timeout
	if is_instance_valid(_count):
		_count.queue_free()


func _pop(l: Node3D) -> void:
	l.scale = Vector3.ONE * 0.5
	l.create_tween().tween_property(l, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## The keeper sits in the boat (also after Mola → "Takıldım" moved them).
func _seat() -> void:
	_player.input_enabled = false
	_player.global_position = boat.keeper_seat()
	_player.respawn_point = _player.global_position
	_player.velocity = Vector3.ZERO
	_player._focus = null
	if _player.model:
		_player.model.visible = true
		_player.model.rotation.y = boat.heading


func _process(delta: float) -> void:
	if _player.ring:
		_player.ring.cold = 0.0
	if state == "shore":
		return
	_pulse += delta
	if next < _gates.size() and state != "done":
		var ring := _gates[next].get_node("Ring") as Node3D
		ring.scale = Vector3.ONE * (1.0 + 0.08 * sin(_pulse * 5.0))
		_gate_light.light_energy = 2.2 + 0.9 * sin(_pulse * 5.0)
		var to := _gate_pos(next) - boat.global_position
		to.y = 0.0
		_arrow.visible = state == "race" and to.length() > 9.0
		_arrow.global_position = boat.global_position + to.normalized() * (5.0 + 0.4 * sin(_pulse * 5.0)) + Vector3(0, 0.6, 0)
		_arrow.rotation.y = atan2(to.x, to.z)
	elif _arrow:
		_arrow.visible = false


func _physics_process(delta: float) -> void:
	if state == "shore":
		return
	var dir := Vector3.ZERO
	if state == "race" and not GameState.in_dialogue:
		time += delta
		var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		dir = Vector3(v.x, 0, v.y)
		var cam := $Camera as FollowCamera
		if cam.yaw != 0.0:
			dir = dir.rotated(Vector3.UP, cam.yaw)
	boat.steer(dir, delta)
	_seat()
	if state != "race":
		return
	# back at the pier in the middle of a race: a way out without the menu
	_quit_t = maxf(_quit_t - delta, 0.0)
	if _away and time > 4.0 and _quit_t <= 0.0 and boat.global_position.distance_to(START) < 5.0 and DevTools.demo == "":
		_away = false
		_ask_quit()
	elif boat.global_position.distance_to(START) > 14.0:
		_away = true
	_check_gates()
	_tip_t = maxf(_tip_t - delta, 0.0)
	if boat.in_mist and boat.mist_factor < 0.8 and _tip_t <= 0.0:
		_tip_t = 9.0
		GameState.toast.emit("Mavi sis kayığı yavaşlatır. Etrafından dolan!", "spark")
	_hint_t -= delta
	if _hint_t <= 0.0:
		_hint_t = 0.1
		_show_progress(false)


func _check_gates() -> void:
	var here := boat.global_position
	here.y = 0.0
	if here.distance_to(_gate_pos(next)) < GATE_REACH:
		_pass_gate()
		return
	# a later gate first: tell which one is next, nothing else happens
	if _tip_t <= 0.0:
		for i in range(next + 1, GATES.size()):
			if here.distance_to(_gate_pos(i)) < GATE_REACH:
				_tip_t = 5.0
				Audio.play("click")
				GameState.toast.emit("Önce yıldızlı kapı! Geri dön, acele yok.", "star")
				break


func _pass_gate() -> void:
	var g := _gates[next]
	_paint(next, "done")
	Effects.ring(self, g.global_position + Vector3(0, 0.2, 0), GATE_HALF + 1.0, Color(0.6, 1.0, 0.65, 0.9), 0.5)
	Effects.sparkle(self, boat.global_position + Vector3.UP, Color(1.0, 0.9, 0.5), 10)
	next += 1
	if DevTools.demo != "":
		print("REGATTA_GATE n=%d/%d time=%.1f" % [next, GATES.size(), time])
	if next >= GATES.size():
		_finish()
		return
	Audio.play("crystal")
	_paint(next, "next")
	_show_progress(true)


## The hint line: gate n/N and the time.
func _show_progress(pop: bool) -> void:
	var text := TranslationServer.translate("Kapı %d/%d · %s sn") % [next, GATES.size(), "%.1f" % time]
	if pop:
		_hud.show_hint(text)
	else:
		_hud._hint_label.text = text


static func medal_for(t: float) -> String:
	return "altin" if t <= GOLD else ("gumus" if t <= SILVER else "bronz")


## Pays every medal up to `m` that was not paid before. Returns their ids.
static func pay(d: PlayerData, m: String) -> Array[String]:
	var out: Array[String] = []
	var order := ["bronz", "gumus", "altin"]
	for i in order.find(m) + 1:
		var id: String = order[i]
		if d.has_flag("regata_" + id):
			continue
		d.set_flag("regata_" + id)
		d.add_piril(int(PAY[id][0]))
		d.add_xp(int(PAY[id][1]))
		out.append(id)
	return out


func _finish() -> void:
	state = "done"
	_gate_light.visible = false
	var d := GameState.data
	medal = medal_for(time)
	var before := d.piril
	paid = pay(d, medal)
	paid_piril = d.piril - before
	if not paid.is_empty() and DevTools.demo == "":
		SaveGame.write(d)  # linear scenes don't autosave: a new medal is kept now
	Audio.play("fanfare")
	Effects.ring(self, boat.global_position, 8.0, Color(1.0, 0.9, 0.5, 0.9), 0.8)
	Effects.sparkle(self, boat.global_position + Vector3.UP * 1.5, Color(1.0, 0.9, 0.5), 30)
	_hud.clear_hint()
	if DevTools.demo == "race":
		return
	await get_tree().create_timer(0.8, false).timeout
	GameState.bark("rg_yine" if paid.is_empty() else "rg_" + medal)
	await GameState.dialogue_closed
	var secs := "%.1f" % time
	var sub := TranslationServer.translate("Süre: %s sn") % secs
	if paid_piril > 0:
		sub = TranslationServer.translate("Süre: %s sn · +%d Pırıl") % [secs, paid_piril]
	match medal:
		"altin": _hud.show_scene_card("Gece Regatası", "Altın madalya!", sub)
		"gumus": _hud.show_scene_card("Gece Regatası", "Gümüş madalya!", sub)
		_: _hud.show_scene_card("Gece Regatası", "Bronz madalya!", sub)
	await get_tree().create_timer(3.4, false).timeout
	var pick: String = await _hud.ask("Yarış bitti! Şimdi ne yapalım?", [{"id": "again", "label": "Tekrar yarış"},
		{"id": "home", "label": "Koya dön"}])
	if pick == "again":
		again = true
		SceneFlow.go_to("s3_regatta")
	else:
		Audio.play("splash")
		SceneFlow.go_to("s3_chapter0")


# --- demos --------------------------------------------------------------------

func _arg(key: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.get_slice("=", 1)
	return fallback


func _run_demo(id: String) -> void:
	var d := GameState.data
	match id:
		"speed":
			var b := RaceBoat.stats(0, false, false, false)
			var y := RaceBoat.stats(0, true, false, false)
			var k := RaceBoat.stats(0, false, true, false)
			var f := RaceBoat.stats(0, false, false, true)
			var f5 := RaceBoat.stats(5, false, false, false)
			var all := RaceBoat.stats(5, true, true, true)
			# measured too: a straight run on open sea with the save's own boat
			boat.position = Vector3(0, 0, 60)
			boat.obstacles.clear()
			boat.mists.clear()
			var seen := 0.0
			for i in 360:
				boat.steer(Vector3(1, 0, 0), 1.0 / 60.0)
				seen = maxf(seen, boat.velocity.length())
			print("REGATTA_SPEED base=%.2f yelken=%.2f friends5=%.2f mist_nofener=%.2f mist_fener=%.2f" % [b["top"], y["top"], f5["top"], b["top"] * b["mist"], f["top"] * f["mist"]])
			print("REGATTA_TURN base=%.2f kurek=%.2f accel_base=%.1f accel_kurek=%.1f all_top=%.2f" % [b["turn"], k["turn"], b["accel"], k["accel"], all["top"]])
			print("REGATTA_MEASURED friends=%d top=%.2f seen=%.2f" % [boat.friends, boat.top, seen])
			get_tree().quit()
		"again":
			# the end of a race as a player sees it, then "Tekrar yarış"
			if again:
				again = false
				_board()
				await get_tree().create_timer(4.5, false).timeout
				print("REGATTA_AGAIN restarted=true state=%s bronz=%s" % [state, d.has_flag("regata_bronz")])
				get_tree().quit()
				return
			_board()
			await get_tree().create_timer(4.0, false).timeout
			time = 70.0
			next = GATES.size() - 1
			boat.position = _gate_pos(next)
			for i in 400:
				await get_tree().create_timer(0.1, false).timeout
				var cps := _hud._root.find_children("*", "ChoicePanel", true, false)
				if not cps.is_empty():
					print("REGATTA_END medal=%s paid=%s piril=%d" % [medal, ",".join(paid), paid_piril])
					(cps[0] as ChoicePanel).chosen.emit("again")
					cps[0].queue_free()
					break
		"race":
			# --friends=N and --up=yelken,kurek,fener try other boats; --pay=0 keeps old medals
			var n := int(_arg("friends", str(ShoreTravel.pearls(d))))
			var up := _arg("up", "save")
			if up != "save":
				for part: String in ["yelken", "kurek", "fener"]:
					d.flags.erase("owned_tekne_" + part)
					if part in up.split(","):
						d.set_flag("owned_tekne_" + part)
			var s := RaceBoat.stats(n, d.has_flag("owned_tekne_yelken"), d.has_flag("owned_tekne_kurek"), d.has_flag("owned_tekne_fener"))
			boat.fit(s, n, d.has_flag("owned_tekne_yelken"), d.has_flag("owned_tekne_kurek"), d.has_flag("owned_tekne_fener"), d.character_id)
			var piril0 := d.piril
			_on_sign()
			await get_tree().create_timer(0.5, false).timeout
			var asked := _hud._root.find_children("*", "ChoicePanel", true, false).size()
			for cp in _hud._root.find_children("*", "ChoicePanel", true, false):
				(cp as ChoicePanel).chosen.emit("go")
				cp.queue_free()
			print("REGATTA_START asked=%d friends=%d top=%.2f" % [asked, boat.friends, boat.top])
			var bumps := [0]
			boat.bumped.connect(func() -> void: bumps[0] += 1)
			var unstuck := false
			while state != "done" and time < 240.0:
				for a in ["move_left", "move_right", "move_forward", "move_back"]:
					Input.action_release(a)
				if state == "race":
					var aim := (_gate_pos(next) - boat.global_position)
					aim.y = 0.0
					aim = aim.normalized()
					if aim.x > 0.05: Input.action_press("move_right", aim.x)
					if aim.x < -0.05: Input.action_press("move_left", -aim.x)
					if aim.z > 0.05: Input.action_press("move_back", aim.z)
					if aim.z < -0.05: Input.action_press("move_forward", -aim.z)
					if next == 3 and not unstuck:
						unstuck = true
						_player.unstick()   # Mola → "Takıldım" in the middle of the race
				await get_tree().physics_frame
			for a in ["move_left", "move_right", "move_forward", "move_back"]:
				Input.action_release(a)
			await get_tree().create_timer(0.3, false).timeout
			var seated := _player.global_position.distance_to(boat.keeper_seat()) < 0.5
			print("REGATTA_DONE gates=%d/%d time=%.1f medal=%s paid=%s piril=%d bumps=%d seated=%s" % [next, GATES.size(), time, medal, ",".join(paid), d.piril - piril0, bumps[0], seated])
			get_tree().quit()


func _ask_quit() -> void:
	var pick: String = await _hud.ask("Yarışı bırakalım mı?", [{"id": "", "label": "Yarışa devam"}, {"id": "home", "label": "Koya dön"}])
	_quit_t = 6.0
	if pick == "home":
		Audio.play("splash")
		SceneFlow.go_to("s3_chapter0")
