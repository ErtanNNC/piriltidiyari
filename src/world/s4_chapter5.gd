extends S4Garden
## Sezon 4 · Bölüm 5 – Gölge Köşesi, Ay Çiçeği Tohumu (levels 25–30, the
## season's final). Behind tall ivy walls where the sun never falls: the
## thickest thorns and wooden signs that all ask "Neden ben değilim?".
## Yonca waits at the gate (Solucan Dede Toprak when the player IS Yonca).
##
## Quest 1 "golgenin_yolu": clap two thorn gates open, clap for four
## Dikenciler, plant the ladder seed up the terrace, plant the Gece Çiçeği
## (it will NOT open by day: the lesson the final rests on) and reach the
## last hedge. The giver follows to the ark; the ark sluice dries the hedge.
##
## Quest 2 "dirilin_saati" = the final, two phases. Faz 1: the fight with
## Dırıl (`ShoreBoss` "diril"). At 0 HP it sulks, but a clap does not end it:
## the clap starts Faz 2 (objective "faz1"). Faz 2 is a garden, no fighting:
## four SeedPlots round Dırıl, one per Bahar Tohumu, each with its garden's
## keeper beside it; every flower that opens brings one line for Dırıl. When
## all four bloom, night falls: the Fener's blue night light reaches the
## corner from the south, Tırıl adds its light, the moon rises and Dırıl
## opens as an Ay Çiçeği; every thorn in the garden turns to flowers (event
## "listen"/"diril"), the Ay Çiçeği Tohumu drops. Tırıl's last talk sets
## `s4_bolum5_bitti` (+ `sezon4_bitti` here) and leads to `s4_final`.
##
## Reload: "faz1" done → Faz 2 starts at once (plots keep their flags);
## "diril" done → the night stays, the seed drops again if not taken.
##
## Layout (the camera looks from the south, +z): gate z 28, spawn z 24, the
## giver z 21 · thorn gate 1 at z 13 · Dikenciler z 0–9 · the terrace (2.6 m
## up) starts at z −6, ladder plot at z −1 · on the terrace: Gece Çiçeği
## plot (−5, −10), Yonca's corner on the east ledge (14.5, −13.5), thorn
## gate 2 at z −18, ark (7, −23), the last hedge z −27, Dırıl and Tırıl in
## the middle (0, −38).

const Q1 := "golgenin_yolu"
const Q2 := "dirilin_saati"
const GRASS := Color("#5f9a6a")
const GRASS_UP := Color("#4f8a62")
const PATH := Color("#b9a98a")
const T := 2.6   ## terrace height
const ARENA := Vector3(0, T, -38.0)
const GIVER_AT := Vector3(3.5, 0, 21.0)
const GIVER_UP := Vector3(-4.0, T, -22.0)
const TIRIL_AT := Vector3(-3.6, T, -41.0)
const DIKENCILER := [["diken_topu", Vector3(-6, 0, 7)], ["neden_golgesi", Vector3(6, 0, 8)],
	["diken_topu", Vector3(7, 0, 1)], ["neden_golgesi", Vector3(-7, 0, 1)]]
## Faz 2: [seed id, the garden's keeper (model + speaker), plot offset from Dırıl]
const FAZ2 := [["lale", "sikir", Vector3(-5.5, 0, 1.0)], ["papatya", "circir", Vector3(-2.6, 0, 4.6)],
	["gul", "pitpit", Vector3(2.6, 0, 4.6)], ["nilufer", "pacali", Vector3(5.5, 0, 1.0)]]
const NIGHT_SKY := {"top_color": Color("#141a44"), "horizon_color": Color("#3a4a8a"), "bottom_color": Color("#1c2350"), "star_amount": 0.9, "cloud_amount": 0.1}

var _giver_id := "yonca"
var _giver: Npc
var _tiril: Npc
var _gates: Array[ThornPatch] = []
var _hedge: ThornPatch
var _ladder: SeedPlot
var _gece: SeedPlot
var _plots: Array[SeedPlot] = []
var _mobs := false
var _giver_up := false
var _syncing := false
var _await_clap := false
var _faz2 := false
var _night_started := false
var _bloomed := false


func _ready() -> void:
	begin_garden("s4_chapter5", "orman")
	var d := GameState.data
	ark_flag = "s4_ark5"
	haze(0.3)
	if d.character_id == "yonca":
		_giver_id = "toprak"
	_build()
	Decor.auto(self, "orman")
	_giver_up = d.quest_state(Q1) in ["ready", "done"]
	_giver = npc(self, _giver_id, _giver_id, GIVER_UP if _giver_up else GIVER_AT, 30.0 if _giver_up else -150.0)
	_giver.name = "Giver"
	_tiril = npc(self, "tiril", "tiril", TIRIL_AT, 20.0)
	_tiril.name = "Tiril"
	var tl := OmniLight3D.new()
	tl.name = "Glow"
	tl.light_color = Color("#9fd8ff")
	tl.light_energy = 0.8
	tl.omni_range = 4.5
	tl.position.y = 1.2
	_tiril.add_child(tl)
	make_boss("diril", ARENA, d.objective_done(Q2, "diril"))
	boss.sad.disconnect(_on_boss_sad)
	boss.sad.connect(_on_diril_sad)
	if _player.clap:
		_player.clap.clapped.connect(_on_clap)
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	d.flags_changed.connect(_season_flag)
	if d.objective_done(Q2, "diril"):
		_apply_night(true)
		_bloom(true)
		for i in FAZ2.size():
			_keeper(i, true)
		if not d.has_flag("tohum_ay_cicegi"):
			_drop()
	elif d.objective_done(Q2, "faz1"):
		boss._become_sad.call_deferred()
	_spawn_mobs()
	_refresh()
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.8, false).timeout
	if not d.has_flag("s4c5_geldi"):
		d.set_flag("s4c5_geldi")
		GameState.bark("s4k5_basla")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _build() -> void:
	land(Vector3(0, 0, 12.5), Vector2(44, 37), GRASS)
	land(Vector3(0, 0, -28), Vector2(44, 44), GRASS_UP, T, 4.0)
	fence(Vector3(0, 0, -10), Vector2(40, 79))
	gate(Vector3(0, 0, 28.0))
	WorldLook.block(lv, Vector3(0, 0.02, 12), Vector3(3.0, 0.04, 26), PATH, 0.0)
	WorldLook.block(lv, Vector3(0, T + 0.02, -17), Vector3(3.0, 0.04, 20), PATH, 0.0)
	# the tall ivy walls: north and both sides (never south of the route)
	var wb := ModelImport.static_bounds("golge_duvar")
	var step := maxf(wb.size.x * 7.0 / maxf(wb.size.y, 0.01) * 0.9, 3.0)
	var x := -21.0
	while x <= 21.0:
		prop("golge_duvar", Vector3(x, T, -51.5), 7.0, 0.0)
		x += step
	for s: float in [-1.0, 1.0]:
		var z := -46.0
		while z <= 26.0:
			prop("golge_duvar", Vector3(22.0 * s, T if z < -6.0 else 0.0, z), 7.0, PI * 0.5 * s)
			z += step
	# "Neden ben değilim?" on wooden thorn signs along the way
	for at: Vector3 in [Vector3(-4.6, 0, 17.5), Vector3(5.0, 0, 5.0), Vector3(-8.0, T, -9.0), Vector3(5.0, T, -30.0)]:
		_sign(at)
	# thorn gate 1 (a clap opens it), hedges to both walls
	_gate_row(13.0, 0.0)
	# loose clumps beside the way (they only fill the Diken barı)
	thorns(Vector3(-10, 0, 5), 4.0, false)
	thorns(Vector3(11, 0, 4), 4.0, false)
	# the terrace: only the ladder seed gets you up (higher than any jump)
	_ladder = plot(Vector3(0, 0, -1.0), "merdiven", Vector3(0, T, -5.6))
	_ladder.grown.connect(func(_p: SeedPlot) -> void: GameState.bark("s4k5_merdiven"))
	_ramp_when_grown(_ladder)
	# the Gece Çiçeği beside the way: a closed bud until the night comes
	_gece = plot(Vector3(-5.0, T, -10.0), "gece")
	_gece.grown.connect(_on_gece_grown)
	# Yonca's corner: a nazlı plot, leaf steps up the east ledge, Pırıl on top
	land(Vector3(14.5, 0, -13.5), Vector2(7, 4), GRASS, T + 2.6, 2.6)
	_ramp_when_grown(plot(Vector3(14.5, T, -7.3), "merdiven", Vector3(0, 2.6, -4.6), true))
	for k in 4:
		var pk := Pickup.new()
		pk.amount = 10
		pk.position = Vector3(12.4 + k * 1.4, T + 2.6, -13.5)
		lv.add_child(pk)
	thorns(Vector3(10, T, -11), 3.0, false)
	# thorn gate 2, the reach point, the ark and the last hedge
	_gate_row(-18.0, T)
	var reach := TriggerArea.new()
	reach.area_id = "son_cit"
	reach.radius = 3.0
	reach.position = Vector3(0, T, -22.5)
	lv.add_child(reach)
	ark(Vector3(7.0, T, -23.0), "s4_ark5", Q1, "s4k5_kilit", PI)
	_hedge = thorns(Vector3(0, T, -27.0), 42.0, true)
	if GameState.data.has_flag("s4_ark5") and not _hedge.is_open:
		_hedge.open()
	# the middle: bare soil where nothing has opened yet
	WorldLook.block(lv, ARENA + Vector3(0, 0.02, 0), Vector3(15, 0.04, 14), Color("#6b5a48"), 0.0)
	for p: Vector3 in [Vector3(-12, 0, -6), Vector3(12, 0, -7), Vector3(-14, 0, 4), Vector3(14, 0, 3)]:
		prop("sarmasik", ARENA + p, 2.6, p.x)


## A blocking hedge row at `z` with a clap gate in the middle.
func _gate_row(z: float, y: float) -> void:
	var g := thorns(Vector3(0, y, z), 5.0, true, true, "golge")
	g.retracted.connect(func(_t: ThornPatch) -> void:
		if not GameState.data.has_flag("s4c5_ilk_kapi"):
			GameState.data.set_flag("s4c5_ilk_kapi")
			GameState.bark("s4k5_kapi"))
	_gates.append(g)
	for s: float in [-1.0, 1.0]:
		thorns(Vector3(11.5 * s, y, z), 18.0, true)


## The leaf steps are for the eye; an unseen ramp over them is what the
## keeper walks on (there is no step-up in the Player).
func _ramp_when_grown(p: SeedPlot) -> void:
	if p.is_grown:
		_ramp(p)
	else:
		p.grown.connect(_ramp)


func _ramp(p: SeedPlot) -> void:
	var run := absf(p.span.z)
	var a := atan2(p.span.y, run)
	var body := StaticBody3D.new()
	body.set_meta("camera_ignore", true)
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(2.0, 0.2, Vector2(run, p.span.y).length())
	c.shape = b
	body.add_child(c)
	lv.add_child(body)
	body.rotation.x = a
	body.position = p.position + Vector3(0, p.span.y * 0.5, 0.7 - run * 0.5) - Vector3(0, cos(a), sin(a)) * 0.1


func _sign(at: Vector3) -> void:
	Toon.part(lv, "box", Vector3(0.16, 1.3, 0.16), Color("#7a5236"), at + Vector3(0, 0.65, 0))
	for k in 3:
		Toon.part(lv, "cone", Vector3(0.14, 0.3, 0.14), Color("#2c6a38"), at + Vector3((k - 1) * 0.9, 1.95, -0.05), Vector3(0, 0, (1 - k) * 25))
	TravelSign.board(lv, "Neden ben değilim?", at + Vector3(0, 1.45, 0.1), 2.8)


## The Dikenciler come with Quest 1 (calmed before it they wouldn't count).
func _spawn_mobs() -> void:
	var d := GameState.data
	if _mobs or d.quest_state(Q1) != "active":
		return
	_mobs = true
	var done := d.objective_count(Q1, "dikenci").x
	for i in range(mini(done, DIKENCILER.size()), DIKENCILER.size()):
		dikenci(DIKENCILER[i][0], DIKENCILER[i][1])
	if not d.has_flag("s4c5_ilk_dikenci"):
		d.set_flag("s4c5_ilk_dikenci")
		GameState.bark("s4k5_dikenci")


func _process(delta: float) -> void:
	super._process(delta)
	# the Gece Çiçeği was planted (it stays a bud by day)
	if _gece and _gece._planted and not _gece.is_grown and not night and not GameState.data.has_flag("s4c5_gece_ekildi"):
		GameState.data.set_flag("s4c5_gece_ekildi")
		GameState.notify("collect", "gece_tohumu")
		_say_later("s4k5_gece")


func _say_later(bark_id: String) -> void:
	await get_tree().create_timer(1.2, false).timeout
	await GameState.wait_dialogue_closed()
	GameState.bark(bark_id)


func _on_gece_grown(_p: SeedPlot) -> void:
	# it opens during the night scene: say so once that scene is over
	while is_inside_tree() and not GameState.data.objective_done(Q2, "diril"):
		await get_tree().create_timer(0.5, false).timeout
	await get_tree().create_timer(1.5, false).timeout
	await GameState.wait_dialogue_closed()
	GameState.bark("s4k5_gece_cicegi")


func _on_ark() -> void:
	_hedge.open()
	GameState.bark("s4k5_ark")
	_refresh()


func _season_flag() -> void:
	var d := GameState.data
	if d.has_flag("s4_bolum5_bitti") and not d.has_flag("sezon4_bitti"):
		d.set_flag("sezon4_bitti")


# --- Faz 1: the fight -------------------------------------------------------

func fight_ready() -> bool:
	var d := GameState.data
	return d.quest_state(Q2) == "active" and d.has_flag("s4_ark5") and not d.objective_done(Q2, "faz1") and not _faz2


func _begin_fight() -> void:
	start_fight("s4k5_diril", "Sarmaşık halkalarından kaç. Dırıl yorulunca vur!", "Halkalardan kaç, yorulunca vur!")


## 0 HP: Dırıl sulks. A clap is asked for, but it will not be enough.
func _on_diril_sad() -> void:
	_hud.hide_boss()
	boss_camera(false)
	boss.remove_from_group("dazed")   # one clap must not end the final
	if GameState.data.objective_done(Q2, "faz1"):
		_start_faz2(true)
		return
	_await_clap = true
	_hud.show_hint("Dırıl küstü. Yanına git, Alkış'a bas!", "Yanına git, Alkış'a bas!")


func _on_clap(_hits: int) -> void:
	if not _await_clap or _player.global_position.distance_to(boss.global_position) > 5.5:
		return
	_await_clap = false
	GameState.notify("clap", "diril")
	_start_faz2(false)


# --- Faz 2: a garden, no fighting -------------------------------------------

func _start_faz2(quiet: bool) -> void:
	if _faz2:
		return
	_faz2 = true
	fighting = true
	_hud.clear_hint()
	var tw := boss.create_tween()
	tw.tween_property(boss, "global_position", ARENA, 0.6)
	if not quiet:
		GameState.bark("s4k5_faz2")
		await GameState.dialogue_closed
	for i in FAZ2.size():
		var p := SeedPlot.new()
		p.name = "Faz2Plot%d" % i
		p.kind = "kalkan"
		p.plot_flag = "s4c5_faz2_t%d" % i
		p.position = ARENA + (FAZ2[i][2] as Vector3)
		lv.add_child(p)
		_plots.append(p)
		_keeper(i, false)
		if p.is_grown:
			_dress(p, i)
		else:
			p.grown.connect(_on_flower.bind(i))
	_recount()
	_faz2_hint()
	if _grown_count() >= FAZ2.size():
		_night_falls()


func _grown_count() -> int:
	return _plots.filter(func(p: SeedPlot) -> bool: return p.is_grown).size()


func _faz2_hint() -> void:
	if _night_started:
		return
	var n := _grown_count()
	_hud.show_hint(TranslationServer.translate("Dövüş bitti. Dırıl'ın çevresindeki dört toprağa tohum ek (%d/4)") % n,
		TranslationServer.translate("Dört toprağa tohum ek (%d/4)") % n)


## The garden's keeper beside its plot (calm, a guest now).
func _keeper(i: int, quiet: bool) -> void:
	var off: Vector3 = FAZ2[i][2]
	var m := NpcModels.build(String(FAZ2[i][1]))
	m.name = "Keeper%d" % i
	add_child(m)
	m.position = ARENA + off + Vector3(signf(off.x) * 2.1, 0, -0.4)
	m.scale = Vector3.ONE * 0.6
	m.rotation.y = atan2(-m.position.x + ARENA.x, -m.position.z + ARENA.z)
	if not quiet:
		Effects.sparkle(self, m.position + Vector3.UP, Tokens.color("spark-yellow"), 12)
		Audio.play("blip")


## The plot's flower becomes its garden's own (the plot grows a tulip).
func _dress(p: SeedPlot, i: int) -> void:
	var id: String = FAZ2[i][0]
	var grown := p.get_node_or_null("Grown") as Node3D
	if grown == null or id == "lale":
		return
	for c in grown.get_children():
		if not c is OmniLight3D:
			c.queue_free()
	var col: Color = SeedTracker.COLORS[id]
	if ModelImport.fit_static(id, grown, Vector3(0, 0.9, 0), Vector3(1.3, 1.8, 1.3)) == null:
		# a water lily: a flat leaf and a round pale flower
		Toon.part(grown, "ellipsoid", Vector3(1.5, 0.12, 1.5), Color("#4a9a5a"), Vector3(0, 0.2, 0))
		for k in 6:
			var a := TAU * k / 6.0
			Toon.part(grown, "ellipsoid", Vector3(0.3, 0.5, 0.2), col, Vector3(cos(a) * 0.3, 0.5, sin(a) * 0.3), Vector3(sin(a) * 30, 0, -cos(a) * 30), 0.4, 0.02)
		Toon.part(grown, "sphere", Vector3(0.3, 0.3, 0.3), Color("#fff1b0"), Vector3(0, 0.5, 0), Vector3.ZERO, 0.6, 0.02)
	for c in grown.get_children():
		if c is OmniLight3D:
			(c as OmniLight3D).light_color = col


## A flower opened: its keeper says one thing to Dırıl.
func _on_flower(p: SeedPlot, i: int) -> void:
	_dress(p, i)
	_faz2_hint()
	await GameState.wait_dialogue_closed()
	var k := get_node_or_null("Keeper%d" % i) as Node3D
	if k:
		Effects.sparkle(self, k.position + Vector3.UP * 1.6, SeedTracker.COLORS[FAZ2[i][0]], 12)
	GameState.bark("s4k5_cicek_%s" % FAZ2[i][0])
	await GameState.dialogue_closed
	if _grown_count() >= FAZ2.size():
		_night_falls()


func _env() -> Environment:
	for c in get_children():
		if c is WorldEnvironment:
			return (c as WorldEnvironment).environment
	return null


func _sun() -> DirectionalLight3D:
	for c in get_children():
		if c is DirectionalLight3D:
			return c
	return null


## Night over the corner: dark blue sky, a pale sun turned moonlight, small
## stars over the garden, the moon behind Dırıl.
func _apply_night(instant: bool) -> void:
	night = true
	var secs := 0.01 if instant else 3.0
	var env := _env()
	var sun := _sun()
	var tw := create_tween().set_parallel()
	if env:
		tw.tween_property(env, "ambient_light_color", Color("#8f9be0"), secs)
		tw.tween_property(env, "ambient_light_energy", 0.5, secs)
		tw.tween_property(env, "fog_light_color", Color("#2a3466"), secs)
		var sky := WorldLook.sky_material(env)
		if sky:
			for key: String in NIGHT_SKY:
				var from: Variant = sky.get_shader_parameter(key)
				if from != null:
					tw.tween_method(func(v: Variant) -> void: sky.set_shader_parameter(key, v), from, NIGHT_SKY[key], secs)
	if sun:
		tw.tween_property(sun, "light_color", Color("#b8c8ff"), secs)
		tw.tween_property(sun, "light_energy", 0.32, secs)
	Pus.fade_to(self, 0.0, secs)
	for k in 26:
		var st := Toon.part(self, "sphere", Vector3.ONE * randf_range(0.08, 0.16), Color("#f4f6ff"),
			Vector3(randf_range(-18, 18), T + randf_range(3.0, 5.5), randf_range(-48, -8)), Vector3.ZERO, 3.0, 0.0, 0.0)
		st.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var tws := st.create_tween().set_loops()
		tws.tween_property(st, "scale", Vector3.ONE * 0.4, randf_range(0.6, 1.4))
		tws.tween_property(st, "scale", Vector3.ONE, randf_range(0.6, 1.4))
	if instant:
		_moon(true)


func _glow_mat(col: Color, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(col.r, col.g, col.b, alpha)
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


## The moon rises behind Dırıl and lays silver light over the middle.
func _moon(instant: bool) -> void:
	var moon := MeshInstance3D.new()
	moon.name = "Moon"
	var sm := SphereMesh.new()
	sm.radius = 2.8
	sm.height = 5.6
	moon.mesh = sm
	moon.material_override = _glow_mat(Color("#f4f6ff"))
	moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(moon)
	var up := Vector3(0, T + 3.8, -49.0)
	moon.position = up + Vector3.DOWN * (0.0 if instant else 8.0)
	var l := OmniLight3D.new()
	l.name = "MoonLight"
	l.light_color = Color("#dfe8ff")
	l.omni_range = 24.0
	l.light_energy = 1.5 if instant else 0.0
	add_child(l)
	l.position = ARENA + Vector3(0, 6.0, -2.0)
	if instant:
		return
	Audio.play("crystal")
	var tw := create_tween().set_parallel()
	tw.tween_property(moon, "position", up, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "light_energy", 1.5, 2.6)
	await tw.finished


## The Fener's blue night light, from far in the south down to Dırıl.
func _beam() -> void:
	var from := Vector3(26, T + 20.0, 44.0)
	var to := ARENA + Vector3(0, 0.8, 0)
	var pivot := Node3D.new()
	pivot.name = "FenerBeam"
	add_child(pivot)
	pivot.position = from
	pivot.look_at(to, Vector3.UP)
	var len := from.distance_to(to)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.45, 0.45, len)
	mi.mesh = bm
	mi.position.z = -len * 0.5
	mi.material_override = _glow_mat(Color("#8fd0ff"), 0.55)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pivot.add_child(mi)
	pivot.scale = Vector3(1, 1, 0.01)
	Audio.play("whoosh")
	var tw := create_tween()
	tw.tween_property(pivot, "scale", Vector3.ONE, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	Effects.ring(self, to, 3.5, Color("#8fd0ff"), 0.7)
	Effects.sparkle(self, to + Vector3.UP, Color("#8fd0ff"), 16)


## Dırıl opens: the Ay Çiçeği form over the little seed.
func _bloom(instant: bool) -> void:
	_bloomed = true
	var flower: Node3D = null
	if ModelImport.path_for("diril_cicek") != "":
		flower = NpcModels.build("diril_cicek")
	if flower:
		boss._model.visible = false
		flower.name = "Bloom"
		boss.add_child(flower)
		flower.scale = Vector3.ONE * (1.7 if instant else 0.2)
		if not instant:
			var tw := flower.create_tween()
			tw.tween_property(flower, "scale", Vector3.ONE * 1.7, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		boss._model.scale = Vector3.ONE * 1.5
		Toon.part(boss, "sphere", Vector3(1.2, 0.6, 1.2), Color("#dfe8ff"), Vector3(0, 1.6, 0), Vector3.ZERO, 1.2, 0.02)
	var l := OmniLight3D.new()
	l.light_color = Color("#dfe8ff")
	l.omni_range = 7.0
	l.light_energy = 1.4
	l.position.y = 1.6
	boss.add_child(l)
	# Tırıl's light, steady and bright now
	var g := _tiril.get_node_or_null("Glow") as OmniLight3D
	if g:
		g.light_energy = 1.8
		g.omni_range = 7.0


## All four flowers are open: the night Dırıl has waited for.
func _night_falls() -> void:
	if _night_started:
		return
	_night_started = true
	_hud.clear_hint()
	await GameState.wait_dialogue_closed()
	boss_camera(true, ARENA, 0.6, 21.0)
	Audio.play("wind")
	_apply_night(false)
	if _gece and not _gece._planted:
		_gece.plant()
	await get_tree().create_timer(2.4, false).timeout
	GameState.bark("s4k5_karardi")
	await GameState.dialogue_closed
	await _beam()
	GameState.bark("s4k5_fener")
	await GameState.dialogue_closed
	Effects.ring(self, _tiril.global_position + Vector3.UP * 0.6, 4.0, Color("#9fd8ff"), 0.8)
	Effects.sparkle(self, _tiril.global_position + Vector3.UP * 1.2, Color("#9fd8ff"), 18)
	await _moon(false)
	_bloom(false)
	Audio.play("fanfare")
	for i in 3:
		Effects.ring(self, ARENA + Vector3.UP * 0.4, 4.0 + i * 4.0, Color("#eef2ff"), 0.8 + i * 0.3)
	for k in 8:
		Effects.sparkle(self, ARENA + Vector3(randf_range(-5, 5), randf_range(1.0, 3.5), randf_range(-4, 5)), Color("#eef2ff"), 8)
	# the Yeşil Diken dries: flowers where every thorn stood
	for n in lv.get_children():
		var tp := n as ThornPatch
		if tp and not tp.is_open:
			tp.open()
			await get_tree().create_timer(0.08, false).timeout
	await get_tree().create_timer(0.9, false).timeout
	GameState.bark("s4k5_acti")
	await GameState.dialogue_closed
	boss.is_sad = false
	boss.set_calm()
	fighting = false
	_faz2 = false
	boss_camera(false)
	GameState.notify("listen", "diril")
	_drop()
	_refresh()


func _drop() -> void:
	drop_seed("ay_cicegi", ARENA + Vector3(0, 0, 6.5), "Ay Çiçeği Tohumu", "Dırıl'ın saati geceymiş")


func _on_seed(_id: String) -> void:
	GameState.bark("s4k5_tohum")
	_refresh()


# --- quests ----------------------------------------------------------------

## Things that stay done by a flag count again once their quest asks.
func _recount() -> void:
	if _syncing:
		return
	_syncing = true
	var d := GameState.data
	if d.quest_state(Q1) == "active":
		var open := _gates.filter(func(g: ThornPatch) -> bool: return g.is_open).size()
		for i in range(d.objective_count(Q1, "alkis").x, open):
			GameState.notify("clap", "golge")
		if _ladder.is_grown and not d.objective_done(Q1, "merdiven"):
			GameState.notify("grow", "merdiven")
		if d.has_flag("s4c5_gece_ekildi") and not d.objective_done(Q1, "gece"):
			GameState.notify("collect", "gece_tohumu")
	if d.quest_state(Q2) == "active" and d.objective_done(Q2, "faz1"):
		for i in range(d.objective_count(Q2, "cicek").x, _grown_count()):
			GameState.notify("grow", "kalkan")
	_syncing = false


func _refresh() -> void:
	var d := GameState.data
	_spawn_mobs()
	_recount()
	if _giver == null:
		return
	var q1 := d.quest_state(Q1)
	var q2 := d.quest_state(Q2)
	if q1 in ["ready", "done"] and not _giver_up:
		_giver_up = true
		giver_comes("Giver", GIVER_UP)
	_star(_giver, q1 in ["none", "ready"])
	_star(_tiril, q2 == "ready")
	if fighting or _faz2 or _await_clap:
		return
	if q1 == "none":
		if _giver_id == "toprak":
			_hud.show_hint("Kapının yanındaki Solucan Dede Toprak ile konuş", "Dede Toprak ile konuş")
		else:
			_hud.show_hint("Kapının yanındaki Yonca ile konuş", "Yonca ile konuş")
	elif q1 == "active":
		_hud.show_hint("C: alkışla. Diken kapılarını aç, tohumla sete çık, kuzeye yürü!", "Alkışla, tohum ek, kuzeye yürü!")
	elif q1 == "ready":
		_hud.show_hint("Ark kapağının yanında seni bekleyenle konuş", "Ark kapağının yanında konuş")
	elif q2 == "active" and not d.has_flag("s4_ark5"):
		_hud.show_hint("Ark kapağının çarkını çevir: son çit kurusun", "Ark kapağını aç")
	elif q2 == "active" and not d.objective_done(Q2, "faz1"):
		_hud.show_hint("Kuzeye yürü: Dırıl ile Tırıl köşenin ortasında", "Kuzeye yürü: Dırıl ortada")
	elif q2 == "active" and d.objective_done(Q2, "diril"):
		_hud.show_hint("Ay Çiçeği Tohumu'nu al", "Tohumu al")
	elif q2 == "ready":
		_hud.show_hint("Tırıl ile konuş: eve dönme vakti", "Tırıl ile konuş")


func _star(n: Node3D, on: bool) -> void:
	if on and not n.has_node("Beacon"):
		Beacon.attach(n, 2.6, Tokens.color("spark-white"))
	elif not on and n.has_node("Beacon"):
		n.get_node("Beacon").queue_free()


# --- demos -----------------------------------------------------------------

func _demo_clap() -> int:
	_player.clap._cd = 0.0
	var hits := _player.clap.clap()
	await get_tree().create_timer(0.9, false).timeout
	await close_dialogs()
	return hits


func _run_demo(which: String) -> void:
	var d := GameState.data
	match which:
		"night":
			# screenshots: straight to the night scene
			DevTools.auto_dialogue = true
			_player.global_position = ARENA + Vector3(2.5, 0.3, 8.0)
			_start_faz2(true)
			for p in _plots:
				p.plant()
		"garden":
			# the whole final on foot: the giver, gate 1, Dikenciler, the
			# ladder (blocked without), the Gece Çiçeği (shut by day), gate
			# 2, the ark, the hedge, Faz 1, Faz 2, the night, Tırıl
			DevTools.auto_dialogue = true
			await walk_to(GIVER_AT + Vector3(-1.5, 0, 1.6), 6.0)
			GameState.talk_to(_giver_id)
			await close_dialogs()
			await close_dialogs()
			print("S4K5_Q1 state=%s giver=%s mobs=%d" % [d.quest_state(Q1), _giver_id, get_tree().get_nodes_in_group("mob").size()])
			await walk_to(Vector3(0, 0, 17.0), 6.0)
			await walk_to(Vector3(0, 0, 11.0), 2.5)
			var z_before := _player.global_position.z
			var hits: int = await _demo_clap()
			await walk_to(Vector3(0, 0, 10.0), 6.0)
			print("S4K5_GATE1 blocked=%s hits=%d passed=%s count=%s" % [z_before > 13.5, hits, _player.global_position.z < 12.0, d.objective_count(Q1, "alkis")])
			await _calm_dikenciler()
			await close_dialogs()
			print("S4K5_DIKENCI count=%s" % d.objective_count(Q1, "dikenci"))
			_player.global_position = Vector3(0, 0.3, 4.0)
			await walk_to(Vector3(0, 0, -2.4), 5.0)
			# without the ladder: the terrace is higher than a (double) jump
			for k in 3:
				Input.action_press("jump")
				await get_tree().create_timer(0.12, false).timeout
				Input.action_release("jump")
				await walk_to(Vector3(0, 0, -9.0), 0.5)
				Input.action_press("jump")
				await get_tree().create_timer(0.12, false).timeout
				Input.action_release("jump")
				await walk_to(Vector3(0, 0, -9.0), 1.0)
			print("S4K5_CLIFF blocked=%s y=%.1f z=%.1f" % [_player.global_position.y < 1.0, _player.global_position.y, _player.global_position.z])
			await walk_to(Vector3(0, 0, 0.2), 4.0)
			await get_tree().create_timer(0.3, false).timeout
			_player.interact()
			for i in 60:
				if _ladder.is_grown:
					break
				await get_tree().create_timer(0.25, false).timeout
			await close_dialogs()
			await walk_to(Vector3(0, 0, -8.5), 8.0)
			print("S4K5_LADDER grown=%s up=%s y=%.1f z=%.1f" % [_ladder.is_grown, _player.global_position.y > T - 0.2, _player.global_position.y, _player.global_position.z])
			await walk_to(Vector3(-5.0, 0, -8.8), 5.0)
			await get_tree().create_timer(0.3, false).timeout
			_player.interact()
			await get_tree().create_timer(8.0, false).timeout
			await close_dialogs()
			print("S4K5_GECE_DAY planted=%s grown=%s night=%s gece=%s" % [_gece._planted, _gece.is_grown, night, d.objective_done(Q1, "gece")])
			await walk_to(Vector3(0, 0, -10.0), 5.0)
			await walk_to(Vector3(0, 0, -15.8), 5.0)
			z_before = _player.global_position.z
			await walk_to(Vector3(0, 0, -21.0), 1.5)
			var stopped := _player.global_position.z > -18.5
			hits = await _demo_clap()
			await walk_to(Vector3(0, 0, -22.5), 6.0)
			await get_tree().create_timer(1.8, false).timeout
			await close_dialogs()
			print("S4K5_GATE2 blocked=%s hits=%d q1=%s giver_up=%s" % [stopped, hits, d.quest_state(Q1), _giver_up])
			await walk_to(GIVER_UP + Vector3(0.5, 0, 1.8), 5.0)
			GameState.talk_to(_giver_id)
			await close_dialogs()
			await close_dialogs()
			print("S4K5_Q2 q1=%s q2=%s" % [d.quest_state(Q1), d.quest_state(Q2)])
			await walk_to(Vector3(0, 0, -23.5), 4.0)
			await walk_to(Vector3(0, 0, -30.0), 1.5)
			var hedge_stop := _player.global_position.z > -27.0
			await walk_to(Vector3(7.0, 0, -21.2), 6.0)
			await get_tree().create_timer(0.3, false).timeout
			_player.interact()
			await get_tree().create_timer(1.0, false).timeout
			await close_dialogs()
			print("S4K5_ARK ark=%s hedge_blocked=%s hedge_open=%s" % [d.has_flag("s4_ark5"), hedge_stop, _hedge.is_open])
			await walk_to(Vector3(0, 0, -24.0), 6.0)
			await walk_to(ARENA + Vector3(0, 0, 7.0), 8.0)
			print("S4K5_HEDGE passed=%s z=%.1f" % [_player.global_position.z < -28.0, _player.global_position.z])
			for i in 80:
				if fighting:
					break
				await get_tree().create_timer(0.25, false).timeout
			await close_dialogs()
			for i in 2400:
				if boss.is_sad:
					break
				if boss.tired:
					boss.hit(60, _player.global_position, 0.0)
				await get_tree().create_timer(0.1, false).timeout
				if d.hp < 30:
					d.heal(100)
			await close_dialogs()
			print("S4K5_FAZ1 sad=%s dazed=%s await_clap=%s" % [boss.is_sad, boss.is_in_group("dazed"), _await_clap])
			_player.global_position = boss.global_position + Vector3(0, 0.3, 1.8)
			await get_tree().create_timer(0.3, false).timeout
			await _demo_clap()
			await close_dialogs()
			for i in 40:
				if _plots.size() == FAZ2.size():
					break
				await get_tree().create_timer(0.25, false).timeout
				await close_dialogs()
			print("S4K5_FAZ2 on=%s still_sad=%s faz1=%s diril=%s plots=%d" % [_faz2, boss.is_sad, d.objective_done(Q2, "faz1"), d.objective_done(Q2, "diril"), _plots.size()])
			for i in _plots.size():
				await walk_to(_plots[i].global_position + Vector3(0, 0, 1.1), 6.0)
				await get_tree().create_timer(0.3, false).timeout
				_player.interact()
				for k in 60:
					if _plots[i].is_grown:
						break
					await get_tree().create_timer(0.25, false).timeout
				await close_dialogs()
				await close_dialogs()
				print("S4K5_FLOWER %s grown=%s count=%s" % [FAZ2[i][0], _plots[i].is_grown, d.objective_count(Q2, "cicek")])
			for i in 200:
				if d.objective_done(Q2, "diril"):
					break
				await close_dialogs()
				await get_tree().create_timer(0.2, false).timeout
			await close_dialogs()
			var open_thorns := 0
			var all_thorns := 0
			for n in lv.get_children():
				if n is ThornPatch:
					all_thorns += 1
					open_thorns += 1 if (n as ThornPatch).is_open else 0
			for i in 40:
				if _gece.is_grown:
					break
				await get_tree().create_timer(0.25, false).timeout
				await close_dialogs()
			print("S4K5_NIGHT night=%s bloom=%s thorns=%d/%d gece_grown=%s diril=%s" % [night, _bloomed, open_thorns, all_thorns, _gece.is_grown, d.objective_done(Q2, "diril")])
			await walk_to(ARENA + Vector3(0, 0, 6.5), 8.0)
			await get_tree().create_timer(0.8, false).timeout
			await close_dialogs()
			print("S4K5_SEED tohum=%s q2=%s" % [d.has_flag("tohum_ay_cicegi"), d.quest_state(Q2)])
			var faz2 := "%d/%d" % [_grown_count(), FAZ2.size()]
			var is_night := night
			var bloom := _bloomed
			DevTools.report_next_scene("S4K5_NEXT")
			await _talk("tiril", "Tiril")
			print("S4K5_DONE q2=%s faz2=%s night=%s bloom=%s tohum=%s bitti=%s sezon=%s next=%s" % [d.quest_state(Q2), faz2, is_night, bloom,
				d.has_flag("tohum_ay_cicegi"), d.has_flag("s4_bolum5_bitti"), d.has_flag("sezon4_bitti"), "s4_final" if SceneFlow.busy else "-"])
			await get_tree().create_timer(4.0, false).timeout
			get_tree().quit()
