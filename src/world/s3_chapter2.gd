extends S3Island
## Sezon 3 · Bölüm 2 – Rüzgârlı Kayalıklar ve Turkuaz İnci (levels 10–15).
## A rocky island reaching for the sky, home of gulls and albatrosses. Its
## keeper Pamuk, an albatross chick grown far too big for the nest, is
## afraid of heights and never leaves it; his nervous wing-flapping makes
## storms. Kaşif Penguen Paytak maps the cliffs at the landing (stall
## "paytak"). First "Rüzgârın Yolu": light the torches up the climb, calm
## the Titrekler, walk a dizzy gull chick over the first bridge hand in
## hand, reach the upper ledge. Then the İşaret Fişeği opens the veil on
## the second bridge; Pamuk's fight in the nest; calmed, the keeper holds
## his wing and they jump together: he glides for the first time. Lesson:
## when you try something for the first time, hold someone's hand.
##
## Special mechanic: wind. On the two bridges (sideways) and in the rock
## tunnel (against you) a gust blows every few seconds while the keeper is
## there: warned 0.8 s ahead, then `Player.wind` for 1.5 s. Walk against
## it (the bridges have a rope rail on the windward side), wait in the lee
## of a rock, or roll between gusts. Falling off a bridge lands on the
## safe floor below: stairs lead back up.
##
## Layout (north = −z, the camera looks from the south): floor 40×78 round
## (0,0,−9) · pier south (0,0,31.5) · landing z 30..19 · steps z 19..16.6 ·
## ledge A (top 1.5) z 16.6..6 · bridge 1 z 6..−2 · ledge B z −2..−7 with
## the chick's nest · wind tunnel z −7..−14 · steps z −14..−16.4 · ledge C
## (top 3) z −16.4..−23 with the flare · bridge 2 + veil z −23..−30 · the
## nest ledge D (top 3) z −30..−47, arena (0,3,−38.5). A rock row at
## z −16.9 splits the floor: the north pit has its own steps up to C.

signal gust_started(i: int)
signal gust_ended(i: int)

const Q1 := "ruzgar_yolu"
const Q2 := "ilk_kanat"
const ROCK := Color("#8492a8")
const ROCK_DARK := Color("#5f6c84")
const GRASS := Color("#7fae6a")
const PEBBLE := Color("#6a7890")
const SAND := Color("#b9b3a0")
const WOOD := Color("#9a6b45")
const ARENA := Vector3(0, 3, -38.5)
const PAYTAK_AT := {"landing": Vector3(-4, 0, 23), "ledge": Vector3(-2.5, 3, -21), "arena": Vector3(-4.5, 3, -32.5)}
const NEST_B := Vector3(4.0, 1.5, -4.5)
const CHICK_AT := Vector3(4.5, 1.5, 9.0)
const FLARE_AT := Vector3(-5.5, 3, -19.5)
const LAND_AT := Vector3(4.5, 3, -36.0)   ## where Pamuk lands after his glide
const TORCHES := [Vector3(-4.2, 0, 19.6), Vector3(-4, 1.5, 10.5), Vector3(2.1, 1.5, 2.0),
	Vector3(-4, 1.5, -4), Vector3(1.9, 1.5, -13.2), Vector3(3.4, 3, -18.4)]
const TITREKS := [["basi_donen_marti", Vector3(10, 0, 22)], ["basi_donen_marti", Vector3(-11, 0, 21.5)],
	["kayan_tas_kaplumbagasi", Vector3(6, 1.5, 14)], ["kayan_tas_kaplumbagasi", Vector3(7.5, 3, -21)]]
## Windy stretches: a rectangle (x0, z0, x1, z1) on a floor at `top`; the
## gust blows along `dir`; standing close behind a rock (its lee) is calm.
const STRETCHES := [
	{"rect": [-3.0, -2.0, 3.0, 6.0], "top": 1.5, "dir": Vector3.RIGHT, "push": 3.4, "rocks": [Vector3(-2.3, 1.5, 2.0)]},
	{"rect": [-2.5, -14.0, 2.5, -7.0], "top": 1.5, "dir": Vector3.BACK, "push": 4.4,
		"rocks": [Vector3(-1.4, 1.5, -9.2), Vector3(1.3, 1.5, -11.4)]},
	{"rect": [-3.0, -30.0, 3.0, -23.0], "top": 3.0, "dir": Vector3.LEFT, "push": 3.4, "rocks": [Vector3(2.3, 3.0, -26.5)]}]
const GUST_REST := 3.0
const GUST_TIME := 1.5
const LEE := 1.9

var _veil: ShiverVeil
var _gust := -1          ## the stretch that blows right now
var _blown := false      ## this script set Player.wind (so it resets it)
var _fell_from := -1
var _cues := 0
var _spot := "landing"   ## where Paytak stands
var _called := false
var _reach_t := 0.0
var _gliding := false


func _ready() -> void:
	begin("s3_chapter2")
	var d := GameState.data
	flare_flag = "s3_fisek2"
	mist(0.45)
	_build()
	Decor.auto(self, "kumsal")
	_spot = _want_spot()
	npc(self, "paytak", "paytak", PAYTAK_AT[_spot], 140.0).name = "Paytak"
	if d.quest_state(Q1) != "done":
		titreks(TITREKS)
		if not d.objective_done(Q1, "civciv"):
			var f := friend("civciv", "balikcil", CHICK_AT, NEST_B)
			f.name = "Civciv"
			f.goal_radius = 3.5
			f.scale = Vector3.ONE * 0.8
			f.held.connect(func() -> void: GameState.bark("s3k2_civciv_el"))
			f.arrived.connect(func() -> void: GameState.bark("s3k2_civciv_yuva"))
	make_boss("pamuk", ARENA, d.objective_done(Q2, "pamuk"))
	if d.objective_done(Q2, "pamuk"):
		boss.position = LAND_AT
		boss.home = LAND_AT
		drop_pearl("turkuaz", ARENA + Vector3(0, 0, 4.5), "Turkuaz İnci", "Pamuk ilk kez süzüldü: el ele.")
	child_entered_tree.connect(_lift_fx)
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	_refresh()
	_player.respawn_point = _player.global_position
	_wind_loop()
	await get_tree().create_timer(1.8, false).timeout
	if not d.has_flag("s3c2_geldi"):
		d.set_flag("s3c2_geldi")
		GameState.bark("s3k2_basla")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


# --- the map --------------------------------------------------------------

func _build() -> void:
	land(Vector3(0, 0, -9), Vector2(40, 78), PEBBLE)
	land(Vector3(0, 0, 24.5), Vector2(40, 11), SAND, 0.04, 0.2)
	# the sea all round, and the rock row that splits the lower floor
	_wall(Vector3(0, 6, 30.5), Vector3(42, 16, 1))
	_wall(Vector3(0, 6, -48.5), Vector3(42, 16, 1))
	for s: float in [-1.0, 1.0]:
		_wall(Vector3(20.5 * s, 6, -9), Vector3(1, 16, 80))
		land(Vector3(14.5 * s, 0, -16.9), Vector2(11, 1.0), ROCK_DARK, 1.6)
		_wall(Vector3(14.5 * s, 8, -16.9), Vector3(11, 14, 1.0))
	dock(Vector3(0, 0, 31.5))
	# steps up to ledge A
	for i in 2:
		land(Vector3(0, 0, 18.4 - i * 1.2), Vector2(6, 1.2), ROCK, 0.5 * (i + 1))
	_ledge(Vector3(0, 0, 11.3), Vector2(18, 10.6), 1.5)
	_bridge(2.0, 8.0, 1.5, -1.0)
	_ledge(Vector3(0, 0, -4.5), Vector2(18, 5), 1.5)
	# the wind tunnel: a corridor between two rock walls, steps at its end
	land(Vector3(0, 0, -10.5), Vector2(5, 7), ROCK, 1.5)
	for s: float in [-1.0, 1.0]:
		land(Vector3(4.0 * s, 0, -11.7), Vector2(3, 9.4), ROCK_DARK, 4.2)
		if prop("kiyi_kaya", Vector3(4.0 * s, 4.2, -9.0), 1.6, s) == null:
			Toon.part(lv, "ellipsoid", Vector3(2.2, 1.4, 2.6), ROCK, Vector3(4.0 * s, 4.6, -9.0))
	for i in 2:
		land(Vector3(0, 0, -14.6 - i * 1.2), Vector2(5, 1.2), ROCK, 2.0 + 0.5 * i)
	for at: Vector3 in STRETCHES[1]["rocks"]:
		_rock(at, Vector3(1.5, 1.2, 0.8))
	_ledge(Vector3(0, 0, -19.7), Vector2(18, 6.6), 3.0)
	# out of the north pit: steps up both sides of ledge C
	for s: float in [-1.0, 1.0]:
		for i in 5:
			land(Vector3((9.6 + 1.2 * i) * s, 0, -20.0), Vector2(1.2, 2.6), ROCK, 2.5 - 0.5 * i)
	_bridge(-26.5, 7.0, 3.0, 1.0)
	_veil = veil(Vector3(0, 3, -24.0), 5.0, "s3k2_perde")
	# the nest ledge: nobody is blown off it
	_ledge(Vector3(0, 0, -38.5), Vector2(22, 17), 3.0)
	for s: float in [-1.0, 1.0]:
		_wall(Vector3(11.5 * s, 9, -38.5), Vector3(1, 12, 18))
		_wall(Vector3(6.7 * s, 9, -29.5), Vector3(9.6, 12, 1))
	if prop("albatros_yuva", ARENA + Vector3(0, 0, -6.2), 2.2) == null:
		Toon.part(lv, "ring", Vector3(5.0, 0.9, 5.0), Color("#a98558"), ARENA + Vector3(0, 0.45, -6.2))
	if prop("albatros_yuva", NEST_B + Vector3(1.4, 0, -0.6), 0.9) == null:
		Toon.part(lv, "ring", Vector3(1.8, 0.4, 1.8), Color("#a98558"), NEST_B + Vector3(1.4, 0.2, -0.6))
	for at: Vector3 in TORCHES:
		torch(at)
	var fl := flare(FLARE_AT, "s3_fisek2", Q1, "s3k2_kilit")
	fl.fire_target = "fisek"
	# rock pillars: beside and north of the route, never south of it
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for e: Array in [[-15, 9, 9], [15.5, 6, 11], [-16, -6, 12], [16, -3, 9], [-15, -27, 13], [15.5, -40, 14],
			[-16, -42, 11], [-25, 2, 16], [26, -14, 18], [-27, -30, 20], [25, -46, 15], [-8, -54, 19], [9, -56, 22]]:
		_pillar(Vector3(e[0], 0, e[1]), float(e[2]) * rng.randf_range(0.9, 1.1), rng.randf() * TAU)
	for e: Array in [[-17, 27], [17, 26], [-13, 16], [13, 15], [-17.5, -12], [17.5, -22], [-14, -33], [15, -31]]:
		prop("kiyi_kaya", Vector3(e[0], 0, e[1]), rng.randf_range(1.2, 2.0), rng.randf() * TAU)
	for x: float in [-8.0, 8.5]:
		prop("dag_kaya", Vector3(x, 3, -45.6), rng.randf_range(2.6, 3.4), rng.randf() * TAU)


## A ledge: grey-blue rock with a grassy top.
func _ledge(center: Vector3, size: Vector2, top: float) -> void:
	land(center, size, ROCK, top - 0.4)
	land(center, size, GRASS, top, 0.4)


func _wall(center: Vector3, size: Vector3) -> void:
	var wall := StaticBody3D.new()
	wall.set_meta("camera_ignore", true)   # invisible: never pushes the camera in
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	c.shape = b
	wall.add_child(c)
	wall.position = center
	lv.add_child(wall)


## A windbreak rock standing on the floor at `at`.
func _rock(at: Vector3, size: Vector3) -> void:
	WorldLook.block(lv, at + Vector3.UP * size.y * 0.5, size, ROCK_DARK)
	Toon.part(lv, "ellipsoid", Vector3(size.x * 0.9, 0.5, size.z * 1.1), GRASS, at + Vector3.UP * size.y)


## A rope bridge on a rock causeway (centre z, length, top). `wind` = the
## side the gust comes from (−1 west, +1 east): the rope rail and the
## windbreak rock of the wider middle are on that side.
func _bridge(z: float, length: float, top: float, wind: float) -> void:
	land(Vector3(0, 0, z), Vector2(3.6, length), ROCK_DARK, top - 0.1)
	land(Vector3(0, 0, z), Vector2(3.4, length), WOOD, top, 0.1)
	land(Vector3(0, 0, z), Vector2(6.2, 3.2), ROCK, top)
	_rock(Vector3(2.3 * wind, top, z), Vector3(1.0, 1.3, 2.2))
	for s: float in [-1.0, 1.0]:
		# the rail: both ends of the bridge on the windward side
		var seg := (length - 3.2) * 0.5
		var cz := z + s * (1.6 + seg * 0.5)
		_wall(Vector3(1.75 * wind, top + 0.6, cz), Vector3(0.2, 1.2, seg))
		Toon.part(lv, "box", Vector3(0.06, 0.06, seg), Color("#e8d8b0"), Vector3(1.75 * wind, top + 0.95, cz), Vector3.ZERO, 0.0, 0.0)
		for e: float in [-0.5, 0.5]:
			Toon.part(lv, "cylinder", Vector3(0.14, 1.1, 0.14), WOOD, Vector3(1.75 * wind, top + 0.55, cz + seg * e))
			Toon.part(lv, "cylinder", Vector3(0.14, 0.5, 0.14), WOOD, Vector3(-1.75 * wind, top + 0.25, cz + seg * e))


func _pillar(at: Vector3, h: float, yaw: float) -> void:
	if prop("kayalik_sutun", at, h, yaw) != null:
		return
	Toon.part(lv, "cylinder", Vector3(h * 0.28, h, h * 0.28), ROCK_DARK, at + Vector3.UP * h * 0.5)
	Toon.part(lv, "ellipsoid", Vector3(h * 0.32, h * 0.1, h * 0.32), GRASS, at + Vector3.UP * h)


# --- wind -----------------------------------------------------------------

## The stretch the keeper stands in (−1 = none); `grow` widens the test.
func _stretch_at(p: Vector3, grow := 0.0) -> int:
	for i in STRETCHES.size():
		var r: Array = STRETCHES[i]["rect"]
		if p.x > r[0] - grow and p.x < r[2] + grow and p.z > r[1] - grow and p.z < r[3] + grow \
				and p.y > float(STRETCHES[i]["top"]) - 0.7 and p.y < float(STRETCHES[i]["top"]) + 4.0:
			return i
	return -1


## Close behind a rock, out of the wind.
func _in_lee(i: int, p: Vector3) -> bool:
	var dir: Vector3 = STRETCHES[i]["dir"]
	for rock: Vector3 in STRETCHES[i]["rocks"]:
		var to := (p - rock) * Vector3(1, 0, 1)
		var along := to.dot(dir)
		if along > 0.2 and along < LEE and (to - dir * along).length() < 1.1:
			return true
	return false


func _wind_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(GUST_REST, false).timeout
		if not is_inside_tree():
			return
		var i := _stretch_at(_player.global_position, 3.5)
		if i < 0 or fighting or _gliding or GameState.in_dialogue:
			continue
		_cue(i)
		await get_tree().create_timer(Mob.TELEGRAPH, false).timeout
		if not is_inside_tree():
			return
		if fighting or _gliding:
			continue
		Audio.play("wind")
		_gust = i
		gust_started.emit(i)
		await get_tree().create_timer(GUST_TIME, false).timeout
		_gust = -1
		_stop_wind()
		if _cues <= 2:
			_hud.clear_hint()
		gust_ended.emit(i)


## The 0.8 s tell: rings on the floor along the stretch, puffs of air on
## the side the wind comes from, and a hint the first times.
func _cue(i: int) -> void:
	var st: Dictionary = STRETCHES[i]
	var r: Array = st["rect"]
	var dir: Vector3 = st["dir"]
	var top := float(st["top"])
	var along_z := absf(dir.x) > 0.5
	for k in 4:
		var f := (k + 0.5) / 4.0
		var at := Vector3(0.0, top, lerpf(r[1], r[3], f)) if along_z else Vector3(lerpf(r[0], r[2], f), top, r[1] + 1.0)
		Effects.ring(self, at - dir * 1.4 + Vector3.UP * 1.0, 1.1, Color(1, 1, 1, 0.8), Mob.TELEGRAPH)
		if k % 2 == 0:
			Effects.warning(self, Vector3(0.0, top, lerpf(r[1], r[3], f + 0.125)), 1.3, Mob.TELEGRAPH)
	_cues += 1
	if _cues <= 2:
		_hud.show_hint("Rüzgâr geliyor! Karşı yürü, kayanın ardında bekle ya da yuvarlan.", "Rüzgâr! Karşı yürü ya da kayanın ardına geç.")


func _stop_wind() -> void:
	if _blown:
		_blown = false
		_player.wind = Vector3.ZERO


func _physics_process(delta: float) -> void:
	var p := _player.global_position
	var d := GameState.data
	var here := _stretch_at(p)
	# the gust: only while the keeper stands in that stretch, out of the lee
	if _gust >= 0 and here == _gust and not _in_lee(_gust, p) and not GameState.in_dialogue and not fighting:
		_player.wind = STRETCHES[_gust]["dir"] * float(STRETCHES[_gust]["push"])
		_blown = true
		if randf() < 0.35:
			var dir: Vector3 = STRETCHES[_gust]["dir"]
			Effects.sparkle(self, p - dir * randf_range(0.5, 2.5) + Vector3(randf_range(-1, 1), randf_range(0.4, 1.6), randf_range(-1, 1)), Color(1, 1, 1), 2)
		if not d.has_flag("s3k2_ruzgar"):
			d.set_flag("s3k2_ruzgar")
			_bark_soon("s3k2_ruzgar")
	else:
		_stop_wind()
	# blown off a bridge: a soft landing below, said once
	if here >= 0:
		_fell_from = here
	elif _fell_from >= 0 and _player.is_on_floor():
		if p.y < float(STRETCHES[_fell_from]["top"]) - 1.0 and not d.has_flag("s3k2_dustu"):
			d.set_flag("s3k2_dustu")
			GameState.bark("s3k2_dustu")
		_fell_from = -1
	# Paytak calls out to a keeper who walks past him
	if d.quest_state(Q1) == "none" and not GameState.in_dialogue and DevTools.demo == "":
		if p.z > 22.5:
			_called = false
		elif p.z < 20.5 and not _called and d.has_flag("s3c2_geldi"):
			_called = true
			GameState.talk_to("paytak")
	# the upper ledge counts whenever the quest asks for it
	_reach_t -= delta
	if _reach_t <= 0.0 and d.quest_state(Q1) == "active" and not d.objective_done(Q1, "ust") \
			and p.y > 2.6 and p.z < -17.0 and p.z > -23.0 and absf(p.x) < 9.0:
		_reach_t = 0.5
		GameState.notify("reach", "s3k2_ust")
		if d.objective_done(Q1, "ust"):
			_bark_soon("s3k2_ust")


## A bark once nothing else is being said.
func _bark_soon(id: String) -> void:
	await get_tree().create_timer(GUST_TIME if id == "s3k2_ruzgar" else 0.4, false).timeout
	await GameState.wait_dialogue_closed()
	if is_inside_tree() and not fighting and not _gliding:
		GameState.bark(id)


## Pamuk's warnings and rings are drawn at y 0 (the boss code assumes a
## shore-level arena): lift them onto the nest ledge.
func _lift_fx(n: Node) -> void:
	if fighting and (n is MeshInstance3D or String(n.name).begins_with("Warning")):
		_lift_later.call_deferred(n)


func _lift_later(n: Node) -> void:
	var n3 := n as Node3D
	if n3 and is_instance_valid(n3) and n3.is_inside_tree() and n3.global_position.y < 1.5 \
			and n3.global_position.z < -29.5 and absf(n3.global_position.x) < 11.5:
		n3.global_position.y += ARENA.y


# --- the story ------------------------------------------------------------

func fight_ready() -> bool:
	var d := GameState.data
	return d.quest_state(Q2) == "active" and d.has_flag("s3_fisek2") and not d.objective_done(Q2, "pamuk") \
		and not _gliding and _player.global_position.z < -29.0


func _begin_fight() -> void:
	_stop_wind()
	start_fight("s3k2_pamuk", "Rüzgâra karşı yürü, halkalardan kaç. Pamuk yorulunca vur!", "Halkalardan kaç, yorulunca vur!")


func _on_boss_sad() -> void:
	super._on_boss_sad()
	GameState.bark("s3k2_pamuk_yorgun")


## The keeper holds Pamuk's wing and they jump together.
func _on_boss_calmed() -> void:
	_hud.clear_hint()
	fighting = false
	_gliding = true
	_player.wind = Vector3.ZERO
	GameState.bark("s3k2_pamuk_son")
	await GameState.dialogue_closed
	await _glide()
	_gliding = false
	boss_camera(false)
	GameState.bark("s3k2_sustu")
	await GameState.dialogue_closed
	drop_pearl("turkuaz", ARENA + Vector3(0, 0, 4.5), "Turkuaz İnci", "Pamuk ilk kez süzüldü: el ele.")
	_refresh()


## Up from the nest, out over the cliff edge in a wide arc, back down
## beside the arena. Input is off for these few seconds only.
func _glide() -> void:
	_hud.cinematic(true)
	_player.input_enabled = false
	_player.set_physics_process(false)
	_player.velocity = Vector3.ZERO
	_player.wind = Vector3.ZERO
	var from := boss.global_position
	var pts := [from, ARENA + Vector3(-9, 0, -17), ARENA + Vector3(15, 0, -12), LAND_AT]
	Audio.play("whoosh")
	Effects.ring(self, from + Vector3.UP * 0.3, 3.0, Tokens.color("spark-yellow"), 0.5)
	var tw := create_tween()
	tw.tween_method(_glide_step.bind(pts), 0.0, 1.0, 5.0).set_trans(Tween.TRANS_SINE)
	await tw.finished
	boss.global_position = LAND_AT
	boss.home = LAND_AT
	boss.rotation = Vector3.ZERO
	_player.global_position = LAND_AT + Vector3(-2.0, 0.3, 1.0)
	_player.velocity = Vector3.ZERO
	_player.set_physics_process(true)
	_player.input_enabled = true
	_hud.cinematic(false)
	Audio.play("fanfare")
	Effects.ring(self, LAND_AT + Vector3.UP * 0.3, 3.5, Tokens.color("spark-yellow"), 0.6)
	Effects.sparkle(self, LAND_AT + Vector3.UP * 1.5, Tokens.color("spark-yellow"), 24)


func _glide_step(t: float, pts: Array) -> void:
	var u := 1.0 - t
	var at: Vector3 = pts[0] * u * u * u + pts[1] * 3.0 * u * u * t + pts[2] * 3.0 * u * t * t + pts[3] * t * t * t
	at.y = lerpf(pts[0].y, pts[3].y, t) + sin(t * PI) * 5.0
	var was := boss.global_position
	boss.global_position = at
	var move := (at - was) * Vector3(1, 0, 1)
	if move.length() > 0.01:
		boss.rotation.y = lerp_angle(boss.rotation.y, atan2(move.x, move.z), 0.2)
	# wing in hand: the keeper flies at his side
	_player.global_position = at + Vector3(cos(boss.rotation.y), 0.0, -sin(boss.rotation.y)) * 1.9 + Vector3.UP * 0.3
	if Engine.get_process_frames() % 4 == 0:
		Effects.sparkle(self, at + Vector3.UP * 1.2, Tokens.color("spark-yellow"), 2)


func _on_flare() -> void:
	_hud.clear_hint()
	_veil.open()
	GameState.bark("s3k2_fisek")
	_refresh()


func _on_pearl(_id: String) -> void:
	GameState.bark("s3k2_inci")
	_refresh()


func _want_spot() -> String:
	var d := GameState.data
	if d.objective_done(Q2, "pamuk"):
		return "arena"
	if d.quest_state(Q1) in ["ready", "done"]:
		return "ledge"
	return "landing"


func _refresh() -> void:
	var want := _want_spot()
	if want != _spot and has_node("Paytak"):
		_spot = want
		await giver_comes("Paytak", PAYTAK_AT[want])
	if not is_inside_tree():
		return
	var d := GameState.data
	var paytak := get_node_or_null("Paytak") as Node3D
	if paytak:
		var go := d.quest_state(Q1) in ["none", "ready"] or d.quest_state(Q2) == "ready"
		if go and not paytak.has_node("Beacon"):
			Beacon.attach(paytak, 2.8, Tokens.color("spark-white"))
		elif not go and paytak.has_node("Beacon"):
			paytak.get_node("Beacon").queue_free()
	var fl := lv.get_node_or_null("Flare") as Node3D
	if fl and d.quest_state(Q1) in ["ready", "done"] and not d.has_flag("s3_fisek2") and not fl.has_node("Beacon"):
		Beacon.attach(fl, 3.4, Tokens.color("spark-yellow"))
	if d.quest_state(Q2) == "active" and not d.objective_done(Q2, "pamuk") and not fighting:
		if d.has_flag("s3_fisek2"):
			_hud.show_hint("İkinci köprüden geç: Pamuk'un yuvası orada", "Köprüden geç: Pamuk'un yuvası")
		else:
			_hud.show_hint("Üst kattaki İşaret Fişeği'ni yak", "İşaret Fişeği'ni yak")
	var dk := lv.get_node_or_null("Dock") as Node3D
	if dk and d.has_flag("s3_bolum2_bitti") and not d.has_flag("s3_fisek3") and not dk.has_node("Beacon"):
		Beacon.attach(dk, 3.0, Tokens.color("spark-white"))
		_hud.show_hint("Kabuk Kayık'a bin: Değişen Kumlar'a açıl", "Kayığa bin: Değişen Kumlar")


# --- demos ----------------------------------------------------------------

## Demo: stand at `at` through one whole gust; `press` holds a move action
## while it blows. Returns where the keeper ended up.
func _demo_gust(at: Vector3, press := "") -> Vector3:
	_player.global_position = at
	_player.velocity = Vector3.ZERO
	await gust_started
	if press != "":
		Input.action_press(press)
	await gust_ended
	if press != "":
		Input.action_release(press)
	await get_tree().create_timer(0.6, false).timeout
	return _player.global_position


func _demo_wind() -> void:
	# bridge 1 blows east: standing still you are blown off, onto the floor
	var a := await _demo_gust(Vector3(0, 1.8, 4.8))
	print("S3K2_WIND still: x=%.1f y=%.1f blown_off=%s safe_floor=%s" % [a.x, a.y, a.x > 1.9, a.y > -0.2 and a.y < 1.0])
	var b := await _demo_gust(Vector3(-1.2, 1.8, 2.0))
	print("S3K2_WIND lee: x=%.1f y=%.1f stayed=%s" % [b.x, b.y, absf(b.x + 1.2) < 0.4 and b.y > 1.3])
	var c := await _demo_gust(Vector3(0, 1.8, 4.8), "move_left")
	print("S3K2_WIND against: x=%.1f y=%.1f on_bridge=%s" % [c.x, c.y, c.y > 1.3 and absf(c.x) < 1.9])
	# the tunnel blows south: pushed back when still, forward when walking
	var e := await _demo_gust(Vector3(0, 1.8, -10.0))
	_player.global_position = Vector3(0, 1.8, -8.5)
	await gust_started
	var z0 := _player.global_position.z
	Input.action_press("move_forward")
	await gust_ended
	Input.action_release("move_forward")
	print("S3K2_WIND tunnel: still_dz=%.1f walking_dz=%.1f wind_reset=%s" % [e.z + 10.0, _player.global_position.z - z0, _player.wind == Vector3.ZERO])


func _run_demo(which: String) -> void:
	match which:
		"wind":
			await _demo_wind()
			get_tree().quit()
		"chick":
			DevTools.auto_dialogue = true
			await _talk("paytak", "Paytak")
			var cf := get_node_or_null("Civciv") as HandFriend
			_player.global_position = cf.global_position + Vector3(0, 0.3, 1.1)
			await get_tree().create_timer(0.5, false).timeout
			_player.interact()
			await close_dialogs()
			_player.global_position = NEST_B + Vector3(-1.2, 0.3, 0.6)
			await get_tree().create_timer(1.5, false).timeout
			await close_dialogs()
			print("S3K2_CHICK done=%s civciv=%s" % [cf.done, GameState.data.objective_done(Q1, "civciv")])
			get_tree().quit()
		"island":
			# the whole chapter by its quests (headless)
			DevTools.auto_dialogue = true
			var d := GameState.data
			await _talk("paytak", "Paytak")
			for n in lv.get_children():
				var bt := n as BeachTorch
				if bt and not bt.lit:
					_player.global_position = bt.global_position + Vector3(0, 0.3, 1.1)
					await get_tree().create_timer(0.4, false).timeout
					_player.interact()
					await get_tree().create_timer(0.2, false).timeout
			await close_dialogs()
			await _demo_wind()
			await close_dialogs()
			var f := get_node_or_null("Civciv") as HandFriend
			if f:
				_player.global_position = f.global_position + Vector3(0, 0.3, 1.1)
				await get_tree().create_timer(0.5, false).timeout
				_player.interact()
				await close_dialogs()
				_player.global_position = NEST_B + Vector3(-1.2, 0.3, 0.6)
				await get_tree().create_timer(1.5, false).timeout
				await close_dialogs()
			_player.global_position = Vector3(0, 3.3, -19.5)
			await get_tree().create_timer(1.0, false).timeout
			await close_dialogs()
			print("S3K2_Q1 mesale=%s civciv=%s ust=%s" % [d.objective_done(Q1, "mesale"), d.objective_done(Q1, "civciv"), d.objective_done(Q1, "ust")])
			await _calm_all()
			await get_tree().create_timer(2.5, false).timeout
			await close_dialogs()
			var paytak := get_node("Paytak") as Node3D
			print("S3K2_Q1 titrek=%s state=%s paytak_up=%s" % [d.objective_done(Q1, "titrek"), d.quest_state(Q1), paytak.global_position.y > 2.5])
			var fl := lv.get_node("Flare") as Node3D
			_player.global_position = fl.global_position + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.5, false).timeout
			_player.interact()
			await close_dialogs()
			print("S3K2_LOCK fisek_before_turn_in=%s veil_open=%s" % [d.has_flag("s3_fisek2"), _veil.is_open])
			await _talk("paytak", "Paytak")
			print("S3K2_Q1 state=%s q2=%s level=%d" % [d.quest_state(Q1), d.quest_state(Q2), d.level])
			if not d.has_flag("s3_fisek2"):
				_player.global_position = fl.global_position + Vector3(0, 0.3, 1.6)
				await get_tree().create_timer(0.5, false).timeout
				_player.interact()
				await close_dialogs()
			print("S3K2_FLARE fisek=%s veil_open=%s obj=%s" % [d.has_flag("s3_fisek2"), _veil.is_open, d.objective_done(Q2, "fisek")])
			_player.global_position = ARENA + Vector3(0, 0.3, 7.0)
			await _beat_boss()
			for i in 200:
				await close_dialogs()
				if has_node("Pearl"):
					break
			print("S3K2_BOSS pamuk=%s glided=%s input=%s on_ledge=%s" % [d.objective_done(Q2, "pamuk"),
				boss.global_position.distance_to(LAND_AT) < 0.5, _player.input_enabled and _player.is_physics_processing(),
				_player.global_position.y > 2.5])
			_player.global_position = ARENA + Vector3(0, 0.3, 4.5)
			await get_tree().create_timer(1.0, false).timeout
			await close_dialogs()
			await get_tree().create_timer(2.0, false).timeout
			await _talk("paytak", "Paytak")
			print("S3K2_DONE q2=%s fisek=%s inci=%s bitti=%s" % [d.quest_state(Q2) == "done", d.has_flag("s3_fisek2"), d.has_flag("inci_turkuaz"), d.has_flag("s3_bolum2_bitti")])
			get_tree().quit()
