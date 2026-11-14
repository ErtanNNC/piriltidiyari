extends S4Garden
## Sezon 4 · Bölüm 4 – Ayna Gölü. A still lake whose surface shows somebody
## else to whoever looks in. Ördek Yavrusu Paçalı covered it with vines so
## that nobody sees the swans. A Kuğu at the shore asks (quest
## "golun_aynalari") to read the three mirror stones, clap the vines off the
## islets, plant the bridge seed and calm four Dikenciler. The lake is
## crossed on lily pads: at each of three forks two pad paths leave, each
## marked by a creature; the fork's `MirrorStone` shows the creature whose
## path is firm. The other path wobbles (warned), sinks gently and the water
## carries you back to the fork (never hurts). Then the Kuğu swims over, the
## ark sluice opens ("sari_ayaklar"), the hedge before the reeds dries and
## Paçalı can be met: fight, it sulks, a clap, the lake clears and Paçalı
## sees its own reflection for the first time: huge, yellow, lovable feet.
## The Nilüfer Tohumu drops and shows a memory (`s4c4_ani`): the child who
## planted Dırıl came one night, but a storm kept the child from coming back.
##
## Layout (the camera looks from the south, +z): gate and spawn at z 23–27,
## the Kuğu at z 20, the lake from z 16 to -32 with the fork islets at
## z 11.5, -0.5 and -12.5 (pad paths left/right of each), the thorny islet
## at z -24.5 (clap hedge, bridge plot), the north shore from z -32 (ark at
## x 7, Yonca's ledge at x -15), the hedge at z -41.3, the reed terrace
## (0.4 m up, a ramp at z -43.5) with Paçalı at z -51.5.

const Q1 := "golun_aynalari"
const Q2 := "sari_ayaklar"
const GRASS := Color("#8fcf7a")
const SAND := Color("#e6d3a8")
const ARENA := Vector3(0, 0.4, -51.5)
const KUGU_S := Vector3(3.5, 0, 20.5)
const KUGU_N := Vector3(-4.0, 0, -35.0)
const POND := Vector3(0, 0.4, -46.0)
const ISLET_R := 2.8
const THORN_ISLET := Vector3(0, 0, -24.5)
const PLOT_AT := Vector3(0, 0, -27.3)
## Fork islets, south to north.
const FORKS := [Vector3(0, 0, 11.5), Vector3(0, 0, -0.5), Vector3(0, 0, -12.5)]
## One side's pads, relative to its fork (left side; mirrored for the right).
const PATH := [Vector2(-3.0, -2.3), Vector2(-4.4, -4.0), Vector2(-4.9, -6.0), Vector2(-4.4, -8.0), Vector2(-3.0, -9.7)]
## Per fork: [left model, left name, right model, right name, firm side].
const SIDES := [
	["taklitci_kurbaga", "Kurbağa", "ayna_baligi", "Balık", -1],
	["turtle", "Kaplumbağa", "kugu", "Kuğu", 1],
	["ayna_baligi", "Balık", "taklitci_kurbaga", "Kurbağa", -1]]
const DIKENCILER := [["ayna_baligi", Vector3(-9, 0, 21)], ["taklitci_kurbaga", Vector3(10, 0, 19.5)],
	["taklitci_kurbaga", Vector3(-8, 0, -37)], ["ayna_baligi", Vector3(13, 0, -35)]]
const VINES := [Vector3(-11, 0, 6), Vector3(11, 0, 3), Vector3(-12, 0, -8), Vector3(11, 0, -18), Vector3(-10, 0, -22), Vector3(12, 0, 11)]

var _hedge: ThornPatch
var _islet_thorn: ThornPatch
var _clap_thorns: Array[ThornPatch] = []
var _bridge: SeedPlot
var _shore_block: StaticBody3D
var _corner: SeedPlot
var _mirrors: Array[MirrorStone] = []
## Per fork: the pads of the path that sinks.
var _wrong: Array = [[], [], []]
var _sinking := [false, false, false]
var _lake_clear := false
var _vines: Array[Node3D] = []
var _falls := 0
var _mobs := false
var _kugu_north := false
var _counting := false


func _ready() -> void:
	begin_garden("s4_chapter4")
	var d := GameState.data
	ark_flag = "s4_ark4"
	haze(0.3)
	_lake_clear = d.has_flag("s4c4_gol_temiz")
	_build()
	Decor.auto(self, "koy")
	var q1 := d.quest_state(Q1)
	_kugu_north = q1 in ["ready", "done"]
	npc(self, "kugu", "kugu", KUGU_N if _kugu_north else KUGU_S, 150.0 if _kugu_north else -150.0).name = "Kugu"
	var calm := d.objective_done(Q2, "pacali")
	make_boss("pacali", ARENA, calm)
	if calm and d.quest_state(Q2) != "done":
		giver_comes("Kugu", ARENA + Vector3(3.5, 0, 5.0), false)
		if not _lake_clear:
			_clear_lake(true)
		_show_feet()
		drop_seed("nilufer", POND, "Nilüfer Tohumu", "Herkesin kendine ait bir güzelliği vardır.")
	_spawn_mobs()
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	_refresh()
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.8, false).timeout
	if not d.has_flag("s4c4_geldi"):
		d.set_flag("s4c4_geldi")
		GameState.bark("s4k4_basla")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


# --- level ---------------------------------------------------------------

func _build() -> void:
	# shores, the two reed banks that frame the lake, the reed terrace
	land(Vector3(0, 0, 23), Vector2(40, 14), GRASS)
	land(Vector3(0, 0, -45), Vector2(40, 26), GRASS)
	land(Vector3(0, 0, -51.25), Vector2(40, 13.5), GRASS, 0.4)
	# a gentle ramp up to it (the keeper doesn't climb steps without a jump)
	var ramp := WorldLook.block(lv, Vector3(0, 0.004, -43.51), Vector3(40, 0.4, 1.96), GRASS.darkened(0.05), 0.0)
	ramp.rotation.x = atan2(0.4, 1.9)
	for side: float in [-1.0, 1.0]:
		land(Vector3(18.5 * side, 0, -8), Vector2(3, 48), GRASS)
		_wall(Vector3(18.5 * side, 0, -8), Vector2(3.0, 48.0))
		for k in 9:
			prop("gol_saz", Vector3(18.6 * side, 0, 13.0 - k * 5.4), 2.2 + 0.3 * (k % 3), k * 1.1)
	fence(Vector3(0, 0, -14.5), Vector2(38, 87))
	gate(Vector3(0, 0, 27.0))
	Toon.part(lv, "box", Vector3(3.2, 0.04, 9.0), SAND, Vector3(0, 0.02, 20.5), Vector3.ZERO, 0.0, 0.0)
	Toon.part(lv, "box", Vector3(40, 0.04, 2.0), SAND, Vector3(0, 0.02, 17.0), Vector3.ZERO, 0.0, 0.0)
	_lake()
	# the way over: one pad off the shore, then three forks
	_pad(Vector3(0, 0, 15.0), 0)
	for f in FORKS.size():
		_fork(f)
	# the thorny islet: a clap hedge across it, then the bridge plot
	_islet(THORN_ISLET, 3.6)
	_checkpoint(THORN_ISLET + Vector3(0, 0, 1.9), 1.6)
	_islet_thorn = thorns(THORN_ISLET + Vector3(0, 0, -0.5), 7.4, true, true, "sarmasik")
	_watch_clap(_islet_thorn)
	_bridge = plot(PLOT_AT, "kopru", Vector3(0, 0, -5.5))
	for x: float in [-9.25, 9.25]:
		_wall(Vector3(x, 0, -31.5), Vector2(15.5, 1.0))
	_shore_block = _wall(Vector3(0, 0, -31.5), Vector2(3.0, 1.0))
	_bridge.grown.connect(func(_p: SeedPlot) -> void:
		_open_shore()
		GameState.bark("s4k4_tohum"))
	if _bridge.is_grown:
		_open_shore()
	_checkpoint(Vector3(0, 0, -34.5), 2.2)
	# thorn clumps beside the route (they only fill the Diken barı)
	thorns(Vector3(-14, 0, 19), 4.0, false)
	thorns(Vector3(14, 0, 25), 4.0, false)
	thorns(Vector3(13, 0, -39), 4.0, false)
	# the ark sluice and the hedge before the reeds
	ark(Vector3(7.0, 0, -37.0), "s4_ark4", Q1, "s4k4_kilit", PI)
	_hedge = thorns(Vector3(0, 0, -41.3), 40.0, true)
	if GameState.data.has_flag("s4_ark4") and not _hedge.is_open:
		_hedge.open()
	# Yonca's corner: a ledge with Pırıl, off the route
	land(Vector3(-15.5, 0, -37), Vector2(5, 6), GRASS.darkened(0.08), 2.0)
	_corner = plot(Vector3(-10.4, 0, -37), "merdiven", Vector3(-2.9, 2.0, 0), true)
	for k in 3:
		var pk := Pickup.new()
		pk.amount = 5
		lv.add_child(pk)
		pk.position = Vector3(-15.0 - k * 0.9, 2.0, -38.2 + k * 1.2)
	# Paçalı's reeds and the little pond it never looks into
	for p: Vector3 in [Vector3(-9, 0.4, -47), Vector3(9, 0.4, -47), Vector3(-11, 0.4, -55), Vector3(11, 0.4, -55), Vector3(0, 0.4, -57)]:
		prop("gol_saz", p, 2.6, p.x)
	prop("gol_kaya", Vector3(-15, 0.4, -51), 2.2, 0.6)
	prop("gol_kaya", Vector3(15, 0, 21), 1.8, 2.0)
	var pond := MeshInstance3D.new()
	var disc := PlaneMesh.new()
	disc.size = Vector2(3.6, 3.6)
	pond.mesh = disc
	pond.position = POND + Vector3(0, 0.05, 0)
	WorldLook.water(pond, "lake")
	lv.add_child(pond)
	Toon.part(lv, "ring", Vector3(5.2, 0.3, 5.2), Color("#b9b3a6"), POND + Vector3(0, 0.05, 0), Vector3.ZERO, 0.0, 0.02)
	if not _lake_clear:
		var cover := prop("sarmasik", POND, 1.2, 0.7)
		if cover:
			_vines.append(cover)
		for v: Vector3 in VINES:
			var vine := prop("sarmasik", v + Vector3(0, -0.3, 0), 1.7, v.x)
			if vine:
				_vines.append(vine)


## The lake: a deep floor (bodies only: no ground decor down there), the
## surface, and the water that carries the keeper back.
func _lake() -> void:
	var bed := StaticBody3D.new()
	var bc := CollisionShape3D.new()
	var bb := BoxShape3D.new()
	bb.size = Vector3(34, 1, 48)
	bc.shape = bb
	bed.add_child(bc)
	bed.position = Vector3(0, -4.0, -8)
	lv.add_child(bed)
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(34, 48)
	water.mesh = plane
	water.position = Vector3(0, -0.35, -8)
	WorldLook.water(water, "lake")
	lv.add_child(water)
	var wet := Area3D.new()
	wet.collision_layer = 0
	wet.collision_mask = 1 | 2
	var wc := CollisionShape3D.new()
	var wb := BoxShape3D.new()
	wb.size = Vector3(34, 1.2, 48)
	wc.shape = wb
	wet.add_child(wc)
	wet.position = Vector3(0, -1.0, -8)
	lv.add_child(wet)
	wet.body_entered.connect(_on_water)


## A fork: its islet, the mirror stone, two marked pad paths to the next islet.
func _fork(f: int) -> void:
	var at: Vector3 = FORKS[f]
	var info: Array = SIDES[f]
	_islet(at, ISLET_R)
	_checkpoint(at, 1.9)
	var firm := int(info[4])
	var m := MirrorStone.new()
	m.name = "Mirror%d" % f
	m.creature = info[0] if firm < 0 else info[2]
	m.creature_name = info[1] if firm < 0 else info[3]
	m.read_flag = "s4c4_ayna%d" % f
	m.bark_id = "s4k4_ayna%d" % f
	m.position = at + Vector3(0, 0, -1.7)
	lv.add_child(m)
	_mirrors.append(m)
	if f == 2:
		# the last mirror hides under a clump of vines until someone claps
		var t := thorns(at + Vector3(0, 0, -1.9), 3.0, false, true, "sarmasik")
		m.covered = not t.is_open
		t.retracted.connect(func(_t: ThornPatch) -> void: m.covered = false)
		_watch_clap(t)
	for side: int in [-1, 1]:
		for i in PATH.size():
			var o: Vector2 = PATH[i]
			var pad := _pad(at + Vector3(-o.x * side, 0, o.y), f * 10 + i + (5 if side > 0 else 0))
			if side != firm:
				_wrong[f].append(pad)
		_marker(at + Vector3(5.7 * side, 0, -1.5), info[0] if side < 0 else info[2], info[1] if side < 0 else info[3], -0.5 * side)


func _pad(at: Vector3, n: int) -> LilyPad:
	var pad := LilyPad.new()
	pad.name = "Pad%d" % n
	pad.flower = n % 3 == 0
	pad.turn = n * 1.7
	pad.position = at
	lv.add_child(pad)
	return pad


func _islet(center: Vector3, r: float) -> void:
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = r
	cyl.height = 1.0
	c.shape = cyl
	body.add_child(c)
	body.position = center + Vector3.DOWN * 0.5
	lv.add_child(body)
	Toon.part(body, "cylinder", Vector3(r * 2, 1.0, r * 2), GRASS, Vector3.ZERO, Vector3.ZERO, 0.0, 0.03)
	Toon.part(body, "cylinder", Vector3(r * 1.3, 0.05, r * 1.3), SAND, Vector3(0, 0.51, 0), Vector3.ZERO, 0.0, 0.0)


## The creature that waits at the start of a pad path (on a stone in the water).
func _marker(at: Vector3, model_id: String, title: String, yaw: float) -> void:
	Toon.part(lv, "cylinder", Vector3(1.5, 0.7, 1.5), Color("#a9a39a"), at + Vector3(0, -0.3, 0), Vector3.ZERO, 0.0, 0.03)
	if prop(model_id, at + Vector3(0, 0.05, 0), 1.25, yaw) == null:
		Toon.part(lv, "sphere", Vector3(0.9, 0.9, 0.9), Tokens.color("sky"), at + Vector3(0, 0.5, 0))
	var tag := Label3D.new()
	tag.text = title
	tag.font = Tokens.font_for("text-heading")
	tag.font_size = 44
	tag.pixel_size = 0.006
	tag.modulate = Tokens.color("panel@light")
	tag.outline_modulate = Color("#2a2433")
	tag.outline_size = 10
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = at + Vector3(0, 1.9, 0)
	lv.add_child(tag)


func _checkpoint(at: Vector3, r: float) -> void:
	var t := TriggerArea.new()
	t.radius = r
	t.checkpoint = true
	t.once = false
	lv.add_child(t)
	t.position = at


func _wall(center: Vector3, size: Vector2) -> StaticBody3D:
	var wall := StaticBody3D.new()
	wall.set_meta("camera_ignore", true)
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(size.x, 8.0, size.y)
	c.shape = b
	wall.add_child(c)
	wall.position = center + Vector3(0, 4, 0)
	lv.add_child(wall)
	return wall


func _open_shore() -> void:
	if _shore_block and is_instance_valid(_shore_block):
		_shore_block.queue_free()
		_shore_block = null


func _watch_clap(t: ThornPatch) -> void:
	_clap_thorns.append(t)
	t.retracted.connect(func(_t: ThornPatch) -> void:
		if not GameState.data.has_flag("s4c4_ilk_alkis"):
			GameState.data.set_flag("s4c4_ilk_alkis")
			GameState.bark("s4k4_sarmasik"))


# --- the lake's rules ----------------------------------------------------

func _process(delta: float) -> void:
	super._process(delta)
	if _lake_clear or _player == null or get_tree().paused:
		return
	var p := _player.global_position
	if p.y > 0.5 or p.y < -0.4:
		return
	for f in _wrong.size():
		if _sinking[f]:
			continue
		for pad: LilyPad in _wrong[f]:
			if Vector2(p.x - pad.position.x, p.z - pad.position.z).length() < LilyPad.RADIUS:
				_sink(f, pad.position)
				break


## The path that isn't the mirror's: every pad wobbles (the warning), then
## they sink gently together, and come up again a little later.
func _sink(f: int, at: Vector3) -> void:
	_sinking[f] = true
	Effects.warning(lv, at + Vector3(0, 0.05, 0), LilyPad.RADIUS, Mob.TELEGRAPH)
	for pad: LilyPad in _wrong[f]:
		var look := pad.get_node("Look") as Node3D
		var tw := look.create_tween()
		for k in 4:
			tw.tween_property(look, "rotation:z", 0.14 if k % 2 == 0 else -0.14, Mob.TELEGRAPH / 4.0)
		tw.tween_property(look, "rotation:z", 0.0, 0.1)
	await get_tree().create_timer(Mob.TELEGRAPH, false).timeout
	Audio.play("splash")
	for pad: LilyPad in _wrong[f]:
		pad.create_tween().tween_property(pad, "position:y", -1.8, 0.6).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(2.6, false).timeout
	for pad: LilyPad in _wrong[f]:
		pad.create_tween().tween_property(pad, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.8, false).timeout
	_sinking[f] = false


## The water never hurts: it sets the keeper down on the last islet.
func _on_water(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	var p := body as Player
	_falls += 1
	Effects.sparkle(self, p.global_position + Vector3.UP * 0.6, Tokens.color("sky"), 10)
	p.global_position = p.respawn_point + Vector3.UP * 0.5
	p.velocity = Vector3.ZERO
	Audio.play("splash")
	Effects.sparkle(self, p.global_position + Vector3.UP, Tokens.color("sky"), 10)
	var d := GameState.data
	var sunk: bool = _sinking.has(true)
	var id := "s4k4_batti" if sunk else "s4k4_su"
	var flag := "s4c4_batti" if sunk else "s4c4_su"
	if not d.has_flag(flag) and not GameState.in_dialogue:
		d.set_flag(flag)
		GameState.bark(id)


## The vines draw back from the water and every pad holds from now on.
func _clear_lake(quiet: bool) -> void:
	_lake_clear = true
	GameState.data.set_flag("s4c4_gol_temiz")
	for v in _vines:
		if not is_instance_valid(v):
			continue
		if quiet:
			v.queue_free()
		else:
			var tw := v.create_tween()
			tw.tween_property(v, "scale", Vector3(1.0, 0.05, 1.0), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw.tween_callback(v.queue_free)
	_vines.clear()
	if quiet:
		Pus.set_amount(0.0)
		return
	Pus.fade_to(self, 0.0, 2.5)
	Audio.play("crystal")
	for k in 8:
		Effects.sparkle(self, Vector3(randf_range(-14, 14), 0.3, randf_range(-28, 12)), Tokens.color("sky"), 8)
	Effects.ring(self, POND + Vector3(0, 0.1, 0), 3.2, Tokens.color("sky"), 0.6)


## What the pond shows Paçalı: two huge yellow feet.
func _show_feet() -> void:
	if lv.has_node("Feet"):
		return
	var feet := Node3D.new()
	feet.name = "Feet"
	feet.position = POND + Vector3(0, 0.1, 0)
	lv.add_child(feet)
	for side: float in [-1.0, 1.0]:
		Toon.part(feet, "ellipsoid", Vector3(0.95, 0.08, 1.35), Color("#ffd23a"), Vector3(0.6 * side, 0, 0.1), Vector3(0, -18 * side, 0), 0.5, 0.02)
		for k in 3:
			Toon.part(feet, "ellipsoid", Vector3(0.3, 0.08, 0.5), Color("#ffb52e"), Vector3(0.6 * side + (k - 1) * 0.32, 0.0, 0.75), Vector3(0, -18 * side + (k - 1) * -14, 0), 0.5, 0.0)


# --- story ---------------------------------------------------------------

## The Dikenciler come with Quest 1 (calmed before it they wouldn't count).
func _spawn_mobs() -> void:
	var d := GameState.data
	if _mobs or d.quest_state(Q1) != "active":
		return
	_mobs = true
	var done := d.objective_count(Q1, "dikenci").x
	for i in range(mini(done, DIKENCILER.size()), DIKENCILER.size()):
		dikenci(DIKENCILER[i][0], DIKENCILER[i][1])
	if not d.has_flag("s4c4_ilk_dikenci"):
		d.set_flag("s4c4_ilk_dikenci")
		GameState.bark("s4k4_dikenci")


## Mirrors read, vines clapped and the bridge planted before the quest asked
## for them still count (they stay done by their flags).
func _recount() -> void:
	var d := GameState.data
	if _counting or d.quest_state(Q1) != "active":
		return
	_counting = true
	_sync("ayna", _mirrors.filter(func(m: MirrorStone) -> bool: return m.is_read).size())
	_sync("alkis", _clap_thorns.filter(func(t: ThornPatch) -> bool: return t.is_open).size())
	_sync("tohum", 1 if _bridge.is_grown else 0)
	_counting = false


func _sync(objective: String, have: int) -> void:
	var d := GameState.data
	var c := d.objective_count(Q1, objective)
	if have > c.x and c.x < c.y:
		d.advance_objective(Q1, objective, mini(have, c.y) - c.x)


## Quest 1 is done on the far side: the Kuğu swims over to the north shore.
func _kugu_swims() -> void:
	_kugu_north = true
	await get_tree().create_timer(0.9, false).timeout
	GameState.bark("s4k4_kugu")
	await GameState.dialogue_closed
	var k := get_node_or_null("Kugu") as Node3D
	if k:
		k.rotation.y = deg_to_rad(150.0)
	await giver_comes("Kugu", KUGU_N)
	_refresh()


func _on_ark() -> void:
	_hedge.open()
	GameState.bark("s4k4_ark")
	_refresh()


func fight_ready() -> bool:
	var d := GameState.data
	return d.quest_state(Q2) == "active" and d.has_flag("s4_ark4") and not d.objective_done(Q2, "pacali")


func _begin_fight() -> void:
	start_fight("s4k4_pacali", "Halkalardan kaç, toprağın kabardığı yerden çekil. Yorulunca vur!", "Halkalardan kaç, yorulunca vur!")


## The lake clears and Paçalı sees its own reflection for the first time.
func _on_boss_calmed() -> void:
	_hud.clear_hint()
	boss_camera(false)
	GameState.bark("s4k4_sakin")
	await GameState.dialogue_closed
	_clear_lake(false)
	await get_tree().create_timer(1.2, false).timeout
	_show_feet()
	Effects.sparkle(self, POND + Vector3.UP * 0.6, Tokens.color("spark-yellow"), 18)
	Audio.play("laugh")
	GameState.bark("s4k4_yansima")
	await GameState.dialogue_closed
	drop_seed("nilufer", POND, "Nilüfer Tohumu", "Herkesin kendine ait bir güzelliği vardır.")
	await giver_comes("Kugu", ARENA + Vector3(3.5, 0, 5.0))
	_refresh()


## The seed, then what it remembers: the night the child came to look.
func _on_seed(_id: String) -> void:
	var d := GameState.data
	await get_tree().create_timer(2.6, false).timeout
	GameState.bark("s4k4_tohum_al")
	await GameState.dialogue_closed
	if not d.has_flag("s4c4_ani"):
		d.set_flag("s4c4_ani")
		Audio.play("memory")
		_hud.show_scene_card("Anı", "Gece Gelen Çocuk", "Dırıl'ı eken çocuk bir gece köşeye bakmaya gelmişti.")
		await get_tree().create_timer(2.8, false).timeout
		GameState.bark("s4k4_ani")
		await GameState.dialogue_closed
	_refresh()


func _refresh() -> void:
	var d := GameState.data
	_spawn_mobs()
	_recount()
	var k := get_node_or_null("Kugu") as Node3D
	if k == null:
		return
	var q1 := d.quest_state(Q1)
	var q2 := d.quest_state(Q2)
	if q1 == "ready" and not _kugu_north:
		_kugu_swims()
	var go := q1 in ["none", "ready"] or q2 == "ready"
	if go and not k.has_node("Beacon"):
		Beacon.attach(k, 2.8, Tokens.color("spark-white"))
	elif not go and k.has_node("Beacon"):
		k.get_node("Beacon").queue_free()
	if q1 == "none":
		_hud.show_hint("Kıyıdaki Kuğu ile konuş", "Kuğu ile konuş")
	elif q1 == "active":
		_hud.show_hint("Ayna taşına bak: suda kimi görürsen onun yaprak yolundan git", "Ayna taşına bak, gördüğünün yolundan git")
	elif q1 == "ready":
		_hud.show_hint("Kuğu kuzey kıyıya yüzdü: yaprak köprüden geç, onunla konuş", "Kuzey kıyıdaki Kuğu ile konuş")
	elif q2 == "ready":
		_hud.show_hint("Kuğu ile konuş", "Kuğu ile konuş")
	elif q2 == "active" and not d.has_flag("s4_ark4"):
		_hud.show_hint("Kuzey kıyıdaki ark kapağının çarkını çevir", "Ark kapağını aç")
	elif q2 == "active" and not d.objective_done(Q2, "pacali") and not fighting:
		_hud.show_hint("Kuzeydeki sazlığa git: Paçalı orada", "Kuzeydeki sazlığa git")
	elif q2 == "active" and not d.has_flag("tohum_nilufer"):
		_hud.show_hint("Gölcüğün üstündeki Nilüfer Tohumu'nu al", "Nilüfer Tohumu'nu al")


# --- demos ---------------------------------------------------------------

## Demo: walk toward `target`; false as soon as the water carried us back.
func _walk_or_fall(target: Vector3, seconds: float) -> bool:
	var falls := _falls
	var t := 0.0
	var ok := true
	while t < seconds:
		if _falls > falls:
			ok = false
			break
		var aim := target - _player.global_position
		aim.y = 0.0
		for a in ["move_left", "move_right", "move_forward", "move_back"]:
			Input.action_release(a)
		if aim.length() < 0.5:
			break
		var dir := aim.normalized()
		if dir.x > 0.2: Input.action_press("move_right", dir.x)
		if dir.x < -0.2: Input.action_press("move_left", -dir.x)
		if dir.z > 0.2: Input.action_press("move_back", dir.z)
		if dir.z < -0.2: Input.action_press("move_forward", -dir.z)
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	for a in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(a)
	return ok


## Demo: one side's pads of fork `f`, northward (or back south).
func _walk_path(f: int, side: int, back := false) -> bool:
	var at: Vector3 = FORKS[f]
	var pts: Array = []
	for o: Vector2 in PATH:
		pts.append(at + Vector3(-o.x * side, 0, o.y))
	pts.append(at + Vector3(0, 0, -12.0 + (2.2 if f == 2 else 0.6)))
	if back:
		pts.pop_back()
		pts.reverse()
		pts.append(at)
	for p: Vector3 in pts:
		if not await _walk_or_fall(p, 3.0):
			return false
	return true


func _dist(to: Vector3) -> float:
	var a := _player.global_position - to
	a.y = 0.0
	return a.length()


func _run_demo(which: String) -> void:
	var d := GameState.data
	match which:
		"garden":
			# the whole chapter on foot: quest, Dikenciler, three forks (the
			# other path first, then the mirror's), the clap hedge, the
			# bridge seed, the ark, the hedge, Paçalı, the seed, the way home
			DevTools.auto_dialogue = true
			await walk_to(KUGU_S + Vector3(0, 0, 1.8), 6.0)
			GameState.talk_to("kugu")
			await close_dialogs()
			print("S4K4_Q1 state=%s mobs=%d clap=%s" % [d.quest_state(Q1), get_tree().get_nodes_in_group("mob").size(), _player.clap != null])
			await _calm_dikenciler()
			await close_dialogs()
			print("S4K4_DIKENCI count=%s" % d.objective_count(Q1, "dikenci"))
			_player.global_position = Vector3(0, 0.3, 19.0)
			await get_tree().create_timer(0.4, false).timeout
			await _walk_or_fall(Vector3(0, 0, 15.0), 4.0)
			for f in FORKS.size():
				var at: Vector3 = FORKS[f]
				await _walk_or_fall(at, 4.0)
				await get_tree().create_timer(0.3, false).timeout
				if f == 2:
					_player.interact()
					await get_tree().create_timer(0.4, false).timeout
					var before := _mirrors[f].is_read
					_player.clap._cd = 0.0
					var hits := _player.clap.clap()
					await get_tree().create_timer(0.9, false).timeout
					await close_dialogs()
					print("S4K4_COVER read_before_clap=%s hits=%d covered=%s alkis=%s" % [before, hits, _mirrors[f].covered, d.objective_count(Q1, "alkis")])
				_player.interact()
				await get_tree().create_timer(0.6, false).timeout
				await close_dialogs()
				# the side comes from what the mirror shows, nothing else
				var shown := _mirrors[f].creature
				var side := -1 if String(SIDES[f][0]) == shown else 1
				var crossed_other := await _walk_path(f, -side)
				await get_tree().create_timer(0.8, false).timeout
				await close_dialogs()
				print("S4K4_FORK%d mirror=%s read=%s other_path_crossed=%s back_at_fork=%s" % [f, shown, _mirrors[f].is_read, crossed_other, _dist(at) < 2.6])
				for i in 40:
					if not _sinking[f]:
						break
					await get_tree().create_timer(0.25, false).timeout
				var crossed := await _walk_path(f, side)
				print("S4K4_FORK%d mirror_path_crossed=%s z=%.1f ayna=%s" % [f, crossed, _player.global_position.z, d.objective_count(Q1, "ayna")])
			# the thorny islet: hedge, clap, then the gap without and with the bridge
			await _walk_or_fall(PLOT_AT + Vector3(0, 0, 0.9), 2.5)
			var held_z := _player.global_position.z
			_player.clap._cd = 0.0
			_player.clap.clap()
			await get_tree().create_timer(0.9, false).timeout
			await close_dialogs()
			await _walk_or_fall(PLOT_AT + Vector3(0, 0, 0.9), 4.0)
			print("S4K4_HEDGE blocked=%s open=%s z=%.1f alkis=%s" % [held_z > -24.4, _islet_thorn.is_open, _player.global_position.z, d.objective_count(Q1, "alkis")])
			var over := await _walk_or_fall(Vector3(0.9, 0, -34.5), 3.0)
			await get_tree().create_timer(0.5, false).timeout
			await close_dialogs()
			print("S4K4_GAP crossed_without_bridge=%s z=%.1f" % [over and _player.global_position.z < -32.0, _player.global_position.z])
			await _walk_or_fall(PLOT_AT + Vector3(0, 0, 0.9), 5.0)
			await get_tree().create_timer(0.3, false).timeout
			_player.interact()
			for i in 60:
				if _bridge.is_grown:
					break
				await get_tree().create_timer(0.25, false).timeout
			await close_dialogs()
			await _walk_or_fall(Vector3(0, 0, -34.5), 6.0)
			print("S4K4_BRIDGE grown=%s crossed=%s z=%.1f q1=%s" % [_bridge.is_grown, _player.global_position.z < -33.0, _player.global_position.z, d.quest_state(Q1)])
			for i in 40:
				var k := get_node("Kugu") as Node3D
				if k.global_position.distance_to(KUGU_N) < 0.3 and not GameState.in_dialogue:
					break
				await close_dialogs()
				await get_tree().create_timer(0.25, false).timeout
			print("S4K4_KUGU north=%s" % ((get_node("Kugu") as Node3D).global_position.distance_to(KUGU_N) < 0.3))
			await _talk("kugu", "Kugu")
			print("S4K4_Q2 q1=%s q2=%s" % [d.quest_state(Q1), d.quest_state(Q2)])
			await walk_to(Vector3(7.0, 0, -35.2), 8.0)
			await get_tree().create_timer(0.3, false).timeout
			_player.interact()
			await get_tree().create_timer(1.0, false).timeout
			await close_dialogs()
			print("S4K4_ARK ark=%s hedge_open=%s" % [d.has_flag("s4_ark4"), _hedge.is_open])
			await walk_to(Vector3(0, 0, -38.5), 6.0)
			await walk_to(ARENA + Vector3(0, 0, 6.0), 8.0)
			print("S4K4_HEDGE2 passed=%s z=%.1f y=%.2f" % [_player.global_position.z < -44.6 and _player.global_position.y > 0.3, _player.global_position.z, _player.global_position.y])
			await _beat_boss()
			for i in 80:
				if has_node("Seed") and not GameState.in_dialogue:
					break
				await close_dialogs()
				await get_tree().create_timer(0.25, false).timeout
			print("S4K4_BOSS pacali=%s lake_clear=%s feet=%s seed=%s" % [d.objective_done(Q2, "pacali"), d.has_flag("s4c4_gol_temiz"), lv.has_node("Feet"), has_node("Seed")])
			await walk_to(POND + Vector3(0, 0, 0.3), 8.0)
			for i in 80:
				await close_dialogs()
				await get_tree().create_timer(0.3, false).timeout
				if d.has_flag("s4c4_ani") and not GameState.in_dialogue and i > 12:
					break
			print("S4K4_SEED tohum=%s ani=%s" % [d.has_flag("tohum_nilufer"), d.has_flag("s4c4_ani")])
			await _talk("kugu", "Kugu")
			await get_tree().create_timer(3.5, false).timeout
			# the way home: the pads that sank hold now
			var falls := _falls
			await walk_to(Vector3(0, 0, -38.5), 8.0)
			await _walk_or_fall(Vector3(0, 0, -34.0), 6.0)
			await _walk_or_fall(PLOT_AT, 6.0)
			await _walk_or_fall(THORN_ISLET + Vector3(0, 0, 2.2), 4.0)
			var home := await _walk_path(2, -int(SIDES[2][4]), true)
			print("S4K4_HOME firm=%s falls=%d z=%.1f" % [home, _falls - falls, _player.global_position.z])
			print("S4K4_DONE q2=%s ark=%s tohum=%s bitti=%s gate_star=%s" % [d.quest_state(Q2), d.has_flag("s4_ark4"), d.has_flag("tohum_nilufer"), d.has_flag("s4_bolum4_bitti"), lv.get_node("Gate").has_node("Beacon")])
			get_tree().quit()
		"corner":
			# Yonca's ledge: the soil answers only her
			DevTools.auto_dialogue = true
			_player.global_position = Vector3(-8.6, 0.3, -37)
			await get_tree().create_timer(0.4, false).timeout
			await walk_to(Vector3(-9.4, 0, -37), 3.0)
			_player.interact()
			for i in 30:
				if _corner.is_grown:
					break
				await get_tree().create_timer(0.25, false).timeout
			var before := d.piril
			await walk_to(Vector3(-15.0, 0, -37), 4.0)
			var walked_y := _player.global_position.y
			# hop up the leaf steps (a kid presses Zıpla on each one)
			for k in 6:
				Input.action_press("jump")
				await walk_to(Vector3(-15.5, 0, -37.5), 0.5)
				Input.action_release("jump")
				await get_tree().create_timer(0.15, false).timeout
			await walk_to(Vector3(-15.5, 0, -37.5), 2.0)
			await get_tree().create_timer(0.6, false).timeout
			print("S4K4_CORNER keeper=%s grown=%s walked_y=%.2f up=%s x=%.1f y=%.2f piril=+%d" % [d.character_id, _corner.is_grown, walked_y, _player.global_position.y > 1.7, _player.global_position.x, _player.global_position.y, d.piril - before])
			get_tree().quit()
