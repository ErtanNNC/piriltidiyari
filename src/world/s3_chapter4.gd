extends S3Island
## Sezon 3 · Bölüm 4 – Fırtına Kayası, Gümüş İnci (levels 20–25). A loud
## island: lightning never stops and its keeper, the seal Tombik, covers his
## ears and shouts at every clap, which only makes the storm bigger. The
## lesson: a loud sound is less scary once you can tell when it comes.
##
## Thunder on a beat: five rows of scorch marks cross the route. Every bar
## (4 beats of `ShorePlan.BEAT` = `Mob.TELEGRAPH`) a row is warned, lands one
## beat later, then stays quiet for two beats: you cross in the silences.
## Neighbouring rows are half a bar apart. Rock overhangs (a pale floor
## mark, a big rock north of it, a torch) are shelters: no mark lies in one
## and nobody standing in one is hit. The rows hold while a dialogue is open
## and stop for good once the island's İşaret Fişeği burns.
##
## Quest 1 "Gök Davulu" (helper at the landing: Tıpış, or Tosbi when the
## player is Tıpış): five torches, four Titrekler, climb the Üst Kaya, lead
## the seal pup by hand to the landing. Quest 2 "Bağıran Bekçi": flare →
## the veil on the stone bridge opens → Tombik (`ShoreBoss` "tombik") → four
## steady beats next to him (thunder is a drum) → Gümüş İnci → a short
## memory of the night Tırıl got lost.
##
## Layout (x east, z south): pier (0,0,31.5) · landing z 19..29 · route
## north with shelters at (-3,11) (3,3) (-3,-5) (3,-13), strike rows at
## z 16, 7, -1, -9, -17 · Üst Kaya east (x 7..13, z -24..-14, top 1.5, stairs
## on its south face) · flare (-5,0,-21) · stone bridge x ±4, z -28..-24
## with the veil · Tombik's arena round (0,0,-37).

signal struck(row: int)

const Q1 := "gok_davulu"
const Q2 := "bagiran_bekci"
const ROCK := Color("#4a5568")
const ROCK_DARK := Color("#343c4e")
const ROCK_LIGHT := Color("#5f6d85")
const MARK := Color("#8fa3c4")
const BOLT := Color("#fff1b0")
const LANDING := Vector3(-2, 0, 23)
const HELPER_AT := Vector3(-4.5, 0, 21.5)
const ARENA := Vector3(0, 0, -37)
const FLARE_AT := Vector3(-5, 0, -21)
const UPPER := Vector3(10, 1.5, -19)
const UPPER_TOP := 1.5
const PUP_AT := Vector3(10.8, 1.5, -20.2)
const SHELTERS := [Vector3(-3, 0, 11), Vector3(3, 0, 3), Vector3(-3, 0, -5), Vector3(3, 0, -13), Vector3(10, 1.5, -19.6)]
const SHELTER_R := 2.2
const ROW_Z := [16.0, 7.0, -1.0, -9.0, -17.0]
const STRIKE_R := 1.8
const STRIKE_DAMAGE := 5
const BAR := 4
const TITREKS := [["gok_bulutu", Vector3(-8, 0, 12)], ["irkilen_fok_yavrusu", Vector3(8, 0, 4)],
	["gok_bulutu", Vector3(-8, 0, -6)], ["irkilen_fok_yavrusu", Vector3(-8, 0, -13)]]

var helper_id := "tipis_panda"
var _veil: ShiverVeil
var _rows: Array = []          ## per row: the marks (Vector3) a strike lands on
var _marks: Node3D
var _beat_t := 0.0
var _beat := 0
var _q1_spawned := false
var _q1_was_none := false
var _rhythm_on := false
var _pup: HandFriend


func _ready() -> void:
	begin("s3_chapter4")
	var d := GameState.data
	flare_flag = "s3_fisek4"
	mist(0.45)
	if d.character_id == "tipis_panda":
		helper_id = "tosbi"
	_build()
	Decor.auto(self, "kumsal")
	npc(self, helper_id, helper_id, HELPER_AT, 25.0).name = "Helper"
	make_boss("tombik", ARENA, d.objective_done(Q2, "tombik"))
	if d.objective_done(Q2, "tombik"):
		if not d.has_flag("s3_bolum4_bitti"):
			giver_comes("Helper", ARENA + Vector3(-3.5, 0, 3.5), false)
		drop_pearl("gumus", ARENA + Vector3(0, 0, 4.5), "Gümüş İnci", "Gök davul çalıyor: say, ritim tut.")
	_q1_was_none = d.quest_state(Q1) == "none"
	d.quest_changed.connect(func(_id: String) -> void:
		_sync_q1()
		_refresh())
	_player.drummed.connect(_on_drummed)
	_sync_q1()
	_refresh()
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.8).timeout
	if not d.has_flag("s3c4_geldi"):
		d.set_flag("s3c4_geldi")
		GameState.bark(_b("s3k4_basla"))
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


## Barks the helper speaks in have a second copy for Tosbi ("_t").
func _b(id: String) -> String:
	return id + ("_t" if helper_id == "tosbi" else "")


func _build() -> void:
	# the rock: a long southern block, a stone bridge, the keeper's round
	land(Vector3(0, 0, 3), Vector2(26, 54), ROCK)
	land(Vector3(0, 0, -26), Vector2(8, 4), ROCK_LIGHT)
	land(Vector3(0, 0, -37.5), Vector2(26, 19), ROCK)
	for w: Array in [[Vector3(0, 0, 29.5), Vector2(28, 1)], [Vector3(-12.5, 0, 2.5), Vector2(1, 55)], [Vector3(12.5, 0, 2.5), Vector2(1, 55)],
			[Vector3(-8.5, 0, -24.5), Vector2(9, 1)], [Vector3(8.5, 0, -24.5), Vector2(9, 1)],
			[Vector3(-4.5, 0, -26), Vector2(1, 4)], [Vector3(4.5, 0, -26), Vector2(1, 4)],
			[Vector3(-8.5, 0, -27.5), Vector2(9, 1)], [Vector3(8.5, 0, -27.5), Vector2(9, 1)],
			[Vector3(-12.5, 0, -37), Vector2(1, 20)], [Vector3(12.5, 0, -37), Vector2(1, 20)], [Vector3(0, 0, -46.5), Vector2(26, 1)]]:
		_wall(w[0], w[1])
	dock(Vector3(0, 0, 31.5))
	# the Üst Kaya: a ledge on the east side, three steps up its south face
	land(UPPER, Vector2(6, 10), ROCK_LIGHT, UPPER_TOP)
	for i in 2:
		land(Vector3(10, 0, -13.4 + i * 1.2), Vector2(4, 1.2), ROCK_LIGHT, 1.0 - i * 0.5)
	var up := TriggerArea.new()
	up.area_id = "ust_kaya"
	up.radius = 2.6
	up.once = false
	up.position = Vector3(10, UPPER_TOP, -16.2)
	lv.add_child(up)
	up.reached.connect(_on_upper)
	# shelters: a pale floor mark, a big rock leaning over it, a torch
	for i in SHELTERS.size():
		_shelter(SHELTERS[i], i * 1.3)
	# strike rows across the route (none in a shelter, on a rock or the ledge)
	for z: float in ROW_Z:
		var row: Array = []
		for k in 7:
			var at := Vector3(-10.8 + k * 3.6, 0, z)
			if _free_mark(at):
				row.append(at)
		_rows.append(row)
	_rows[4].append(Vector3(5.6, 0, ROW_Z[4]))   # between the last rock and the ledge
	if not GameState.data.has_flag(flare_flag):
		_draw_marks()
	flare(FLARE_AT, "s3_fisek4", Q1, "s3k4_kilit")
	_veil = veil(Vector3(0, 0, -25.6), 8.0, "s3k4_perde")
	# wet rocks in the surf all round (outside the walls), pillars further out
	var rng := RandomNumberGenerator.new()
	rng.seed = 44
	for i in 11:
		var z := 24.0 - i * 6.8
		for s: float in [-1.0, 1.0]:
			if absf(z + 26.0) < 3.0:
				continue
			var tall := (i + int(s > 0)) % 3 == 0
			_rock("kayalik_sutun" if tall else "kiyi_kaya", Vector3(s * (15.0 + rng.randf() * 1.5), -0.4, z + rng.randf_range(-1.5, 1.5)),
				rng.randf_range(6.0, 8.5) if tall else rng.randf_range(2.2, 3.4), rng.randf() * TAU)
	for s: float in [-1.0, 1.0]:
		_rock("kiyi_kaya", Vector3(s * 8.5, -0.4, -26), 1.8, s)
	for i in 5:
		_rock(["volkan_kaya", "firtina_kaya"][i % 2], Vector3(-12.0 + i * 6.0, -0.4, -50.0 - (i % 2) * 1.5), 7.0 + (i % 3) * 1.5, i * 1.1)


## An invisible wall round the walkable rock (nobody walks into the sea).
func _wall(center: Vector3, size: Vector2) -> void:
	var wall := StaticBody3D.new()
	wall.set_meta("camera_ignore", true)   # invisible: never pushes the camera in
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(size.x, 12.0, size.y)
	c.shape = b
	wall.add_child(c)
	wall.position = Vector3(center.x, 6.0, center.z)
	lv.add_child(wall)


## A scenery rock; a dark primitive when its model isn't there (yet).
func _rock(id: String, at: Vector3, h: float, yaw := 0.0) -> void:
	if prop(id, at, h, yaw) == null:
		var w := h * (0.45 if id == "kayalik_sutun" else 1.1)
		Toon.part(lv, "ellipsoid", Vector3(w, h * 1.3, w), ROCK_DARK, at + Vector3.UP * h * 0.4, Vector3(0, rad_to_deg(yaw), 6))


## A rock overhang: safe from the lightning. The rock stands north of the
## floor mark (it hides nothing from the camera), the torch under it.
func _shelter(at: Vector3, yaw: float) -> void:
	Toon.part(lv, "cylinder", Vector3(SHELTER_R * 2.0, 0.04, SHELTER_R * 2.0), MARK, at + Vector3.UP * 0.03, Vector3.ZERO, 0.0, 0.0)
	Toon.part(lv, "ring", Vector3(SHELTER_R * 2.0, 0.12, SHELTER_R * 2.0), BOLT.darkened(0.25), at + Vector3.UP * 0.06, Vector3.ZERO, 0.4, 0.0)
	var rock_at := at + Vector3(0, 0, -(SHELTER_R + 1.3))
	if prop("firtina_kaya", rock_at, 4.4, yaw) == null:
		Toon.part(lv, "ellipsoid", Vector3(3.6, 6.4, 3.0), ROCK_DARK, rock_at + Vector3.UP * 1.8, Vector3(0, rad_to_deg(yaw), 0))
		Toon.part(lv, "box", Vector3(4.6, 0.5, 2.8), ROCK_DARK, at + Vector3(0, 3.4, -SHELTER_R + 0.4), Vector3(-14, 0, 0))
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = 1.9
	s.height = 4.0
	c.shape = s
	c.position.y = 2.0
	body.add_child(c)
	body.position = rock_at
	lv.add_child(body)
	torch(at + Vector3(-1.1, 0, -1.0))


func _sheltered(at: Vector3) -> bool:
	for s: Vector3 in SHELTERS:
		if Vector2(at.x - s.x, at.z - s.z).length() < SHELTER_R and absf(at.y - s.y) < 1.2:
			return true
	return false


## A strike mark must not touch a shelter, its rock, the ledge or its steps.
func _free_mark(at: Vector3) -> bool:
	for s: Vector3 in SHELTERS:
		if Vector2(at.x - s.x, at.z - s.z).length() < SHELTER_R + STRIKE_R and s.y < 1.0:
			return false
		if Vector2(at.x - s.x, at.z - (s.z - SHELTER_R - 1.3)).length() < 1.6:
			return false
	return not (at.x > 7.0 - STRIKE_R * 0.5 and at.z < -11.6 + STRIKE_R * 0.5)


## Scorch marks: where the lightning always lands (gone with the flare).
func _draw_marks() -> void:
	_marks = Node3D.new()
	lv.add_child(_marks)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.08, 0.1, 0.16, 0.5)
	var disc := CylinderMesh.new()
	disc.top_radius = STRIKE_R * 0.8
	disc.bottom_radius = STRIKE_R * 0.8
	disc.height = 0.02
	disc.radial_segments = 24
	for row: Array in _rows:
		for at: Vector3 in row:
			var mi := MeshInstance3D.new()
			mi.mesh = disc
			mi.material_override = mat
			mi.position = at + Vector3.UP * 0.03
			_marks.add_child(mi)


func storm_on() -> bool:
	return not GameState.data.has_flag(flare_flag)


func _process(delta: float) -> void:
	super._process(delta)
	if not storm_on() or GameState.in_dialogue:
		return
	_beat_t += delta
	if _beat_t < ShorePlan.BEAT:
		return
	_beat_t -= ShorePlan.BEAT
	_beat = (_beat + 1) % BAR
	for i in _rows.size():
		if (i % 2) * 2 == _beat:
			_warn_row(i)


## Beat 1 of a row's bar: the warning. It lands one beat later.
func _warn_row(i: int) -> void:
	for at: Vector3 in _rows[i]:
		Effects.warning(self, at, STRIKE_R, ShorePlan.BEAT)
	await get_tree().create_timer(ShorePlan.BEAT).timeout
	if not is_inside_tree() or not storm_on():
		return
	Audio.play("drum")
	for at: Vector3 in _rows[i]:
		_bolt(at)
	var p := _player.global_position
	if not GameState.in_dialogue and not _sheltered(p) and p.y < 1.0:
		for at: Vector3 in _rows[i]:
			if Vector2(p.x - at.x, p.z - at.z).length() < STRIKE_R:
				_player.hurt(STRIKE_DAMAGE, at)
				break
	struck.emit(i)


## A lightning bolt: a bright line from the sky, a ring, a short flash.
func _bolt(at: Vector3, big := false) -> void:
	var line := Toon.part(self, "cylinder", Vector3(0.22, 16.0, 0.22), BOLT, at + Vector3.UP * 8.0, Vector3(0, 0, randf_range(-4, 4)), 3.0, 0.0)
	var tw := line.create_tween()
	tw.tween_property(line, "scale", Vector3(0.1, 1, 0.1), 0.22)
	tw.tween_callback(line.queue_free)
	Effects.ring(self, at + Vector3.UP * 0.3, STRIKE_R * (1.6 if big else 1.0), BOLT, 0.3)
	if big:
		Effects.sparkle(self, at + Vector3.UP, BOLT, 8)
		var l := OmniLight3D.new()
		l.light_color = BOLT
		l.omni_range = 16.0
		l.light_energy = 4.0
		add_child(l)
		l.global_position = at + Vector3.UP * 4.0
		var lt := l.create_tween()
		lt.tween_property(l, "light_energy", 0.0, 0.35)
		lt.tween_callback(l.queue_free)


# --- Quest 1 ---------------------------------------------------------------

## Titrekler and the seal pup appear when the quest asks for them (calmed or
## led before that, their events would be lost); torches lit earlier count.
func _sync_q1() -> void:
	var d := GameState.data
	if d.quest_state(Q1) != "active":
		return
	if _q1_was_none:
		_q1_was_none = false
		for n in lv.get_children():
			var bt := n as BeachTorch
			if bt and bt.lit:
				GameState.notify("light", "mesale")
	if _q1_spawned:
		return
	_q1_spawned = true
	for i in range(d.objective_count(Q1, "titrek").x, TITREKS.size()):
		titrek(TITREKS[i][0], TITREKS[i][1])
	if not d.objective_done(Q1, "el"):
		_make_pup()


## The startled seal pup under the Üst Kaya's overhang: a small Tombik.
func _make_pup() -> void:
	_pup = HandFriend.new()
	_pup.friend_id = "yavru"
	_pup.model_id = "tombik"
	_pup.goal = LANDING
	_pup.goal_radius = 3.5
	var m: Node3D
	if ModelImport.load_model("tombik") != null:
		m = NpcModels.build("tombik")
		m.scale *= 0.45
	else:
		m = Node3D.new()
		Toon.default_pus = 0.0
		Toon.part(m, "ellipsoid", Vector3(0.7, 0.6, 1.0), Color("#c9d4e8"), Vector3(0, 0.3, 0))
		Toon.part(m, "sphere", Vector3(0.5, 0.5, 0.5), Color("#c9d4e8"), Vector3(0, 0.6, 0.4))
		Face.add(m, Vector3(0, 0.62, 0.62), Vector3(0.3, 0.25, 0.2))
		Toon.default_pus = 1.0
		CharacterRig.attach(m)
	_pup.set_model(m)
	_pup.position = PUP_AT
	add_child(_pup)
	_pup.arrived.connect(func() -> void:
		GameState.bark("s3k4_yavru")
		_refresh())


func _on_upper() -> void:
	var d := GameState.data
	if d.quest_state(Q1) != "active" or d.objective_done(Q1, "el") or d.has_flag("s3c4_ust"):
		return
	d.set_flag("s3c4_ust")
	GameState.bark("s3k4_ust")
	_hud.show_hint("Yavrunun elini tut. Sessizlikte yürü, kaya altında bekle.", "El tut, sessizlikte yürü")


# --- Quest 2 ---------------------------------------------------------------

func _on_flare() -> void:
	_hud.clear_hint()
	_veil.open()
	if _marks:
		_marks.queue_free()
		_marks = null
	GameState.bark(_b("s3k4_fisek"))
	_refresh()


func fight_ready() -> bool:
	var d := GameState.data
	return d.quest_state(Q2) == "active" and d.has_flag(flare_flag) and not d.objective_done(Q2, "tombik")


func _begin_fight() -> void:
	start_fight("s3k4_tombik", "Şimşek dört vuruşla düşer: say, arada koş. Yorulunca vur!", "Vuruşları say, yorulunca vur!")


func _on_boss_sad() -> void:
	super._on_boss_sad()
	GameState.bark("s3k4_tombik_yorgun")


## Thunder is a drum: the helper comes over and the keeper plays four
## steady beats next to Tombik, a flash on each. Then the pearl.
func _on_boss_calmed() -> void:
	_hud.clear_hint()
	boss_camera(false)
	giver_comes("Helper", ARENA + Vector3(-3.5, 0, 3.5))
	GameState.bark(_b("s3k4_ritim"))
	await GameState.dialogue_closed
	_rhythm_on = true
	_hud.show_hint("Tombik'in yanında dur, dört düzenli vuruş yap: güm, güm, güm, güm", "Tombik'in yanında dört düzenli vuruş yap")


func _on_drummed(n: int) -> void:
	if not _rhythm_on or _player.global_position.distance_to(boss.global_position) > 7.0:
		return
	Audio.play("drum")
	_bolt(boss.global_position + Vector3(randf_range(-5, 5), 0, -5.0 - randf() * 3.0), true)
	FloatText.spawn(self, boss.global_position + Vector3.UP * 3.2, str(mini(n, 4)), Tokens.color("spark-yellow"))
	if n < 4:
		return
	_rhythm_on = false
	GameState.data.set_flag("s3c4_ritim")
	_hud.clear_hint()
	GameState.bark(_b("s3k4_ritim_son"))
	await GameState.dialogue_closed
	drop_pearl("gumus", ARENA + Vector3(0, 0, 4.5), "Gümüş İnci", "Gök davul çalıyor: say, ritim tut.")
	_refresh()


## After the pearl: the stormy night Tırıl got lost.
func _on_pearl(_id: String) -> void:
	var d := GameState.data
	await get_tree().create_timer(2.6).timeout
	GameState.bark("s3k4_inci")
	await GameState.dialogue_closed
	if not d.has_flag("s3c4_ani"):
		d.set_flag("s3c4_ani")
		_hud.show_scene_card("Anı", "Fırtınalı Gece", "Tırıl o gece batık bir oyuncak tekneye saklandı.")
		await get_tree().create_timer(2.8).timeout
		GameState.bark("s3k4_ani")
		await GameState.dialogue_closed
	_refresh()


func _refresh() -> void:
	var d := GameState.data
	var helper := get_node_or_null("Helper") as Node3D
	if helper:
		var go := d.quest_state(Q1) in ["none", "ready"] or d.quest_state(Q2) == "ready"
		if go and not helper.has_node("Beacon"):
			Beacon.attach(helper, 2.8, Tokens.color("spark-white"))
		elif not go and helper.has_node("Beacon"):
			helper.get_node("Beacon").queue_free()
	var fl := lv.get_node_or_null("Flare") as Node3D
	if fl and d.quest_state(Q2) == "active" and not d.has_flag(flare_flag) and not fl.has_node("Beacon"):
		Beacon.attach(fl, 3.4, Tokens.color("spark-yellow"))
		_hud.show_hint("Kuzeyde, taş köprünün önündeki İşaret Fişeği'ni yak", "İşaret Fişeği'ni yak")
	var dk := lv.get_node_or_null("Dock") as Node3D
	if dk and d.has_flag("s3_bolum4_bitti") and not d.has_flag("s3_fisek5") and not dk.has_node("Beacon"):
		Beacon.attach(dk, 3.0, Tokens.color("spark-white"))
		_hud.show_hint("Kabuk Kayık'a bin: Kayıp Ada'ya açıl", "Kayığa bin: Kayıp Ada")


# --- demos -----------------------------------------------------------------

## Demo: keeps the Titreme barı empty and the keeper healthy while a
## scripted run stands about in the dark.
func _demo_keeper() -> void:
	while is_inside_tree():
		if _player.ring:
			_player.ring.shiver = 0.0
		if GameState.data.hp < GameState.data.max_hp / 2:
			GameState.data.heal(GameState.data.max_hp)
		await get_tree().create_timer(0.4).timeout


func _run_demo(which: String) -> void:
	match which:
		"look":
			# screenshots: stand mid-route (--z=N picks the spot), a quest running
			var z := 5.0
			for arg in OS.get_cmdline_user_args():
				if arg.begins_with("--z="):
					z = float(arg.get_slice("=", 1))
			GameState.data.start_quest(Content.quests[Q1])
			_player.global_position = Vector3(0, 0.3, z)
		"island":
			# the storm first, then the whole chapter by its quests (headless)
			DevTools.auto_dialogue = true
			var d := GameState.data
			_demo_keeper()
			# 1) standing on a mark in the open: hit within two bars
			var mark: Vector3 = _rows[0][3]
			_player.global_position = mark + Vector3.UP * 0.3
			var hp0 := d.hp
			for i in 3:
				await struck
			var hurt_open := d.hp < hp0
			# 2) under a rock overhang: never hit, and no mark lies in one
			_player.global_position = SHELTERS[0] + Vector3.UP * 0.3
			await get_tree().create_timer(1.6).timeout
			d.heal(d.max_hp)
			hp0 = d.hp
			await get_tree().create_timer(ShorePlan.BEAT * BAR * 2.0).timeout
			var safe_shelter := d.hp == hp0
			var clear := true
			for row: Array in _rows:
				for at: Vector3 in row:
					for sh: Vector3 in SHELTERS:
						if sh.y < 1.0 and Vector2(at.x - sh.x, at.z - sh.z).length() < SHELTER_R + STRIKE_R:
							clear = false
			# 3) crossing a row in its silence: walk through right after it lands
			_player.global_position = Vector3(0, 0.3, 18.6)
			while await struck != 0:
				pass
			hp0 = d.hp
			await walk_to(Vector3(0, 0, 13.4), 2.0)
			var crossed := _player.global_position.z < 14.2
			await get_tree().create_timer(0.3).timeout
			print("S3K4_STORM hurt_open=%s safe_shelter=%s marks_clear=%s cross_quiet=%s unhurt=%s rows=%s" % [hurt_open, safe_shelter, clear, crossed, d.hp == hp0, _rows.map(func(r: Array) -> int: return r.size())])
			# Quest 1
			await _talk(helper_id, "Helper")
			print("S3K4_Q1 start=%s helper=%s titrek=%d pup=%s" % [d.quest_state(Q1), helper_id, get_tree().get_nodes_in_group("titrek").size(), _pup != null])
			for n in lv.get_children():
				var bt := n as BeachTorch
				if bt and not bt.lit:
					_player.global_position = bt.global_position + Vector3(0.4, 0.3, 1.1)
					await get_tree().create_timer(0.4).timeout
					_player.interact()
					await get_tree().create_timer(0.2).timeout
			await _calm_all()
			# the steps up the Üst Kaya, on foot (a hop per step)
			_player.global_position = Vector3(10, 0.3, -10.4)
			await get_tree().create_timer(0.3).timeout
			Input.action_press("move_forward")
			for i in 12:
				Input.action_press("jump")
				await get_tree().create_timer(0.2).timeout
				Input.action_release("jump")
				await get_tree().create_timer(0.3).timeout
				if _player.global_position.z < -16.0:
					break
			Input.action_release("move_forward")
			await get_tree().create_timer(0.4).timeout
			print("S3K4_UPPER y=%.2f reach=%s" % [_player.global_position.y, d.objective_done(Q1, "ust_kaya")])
			await close_dialogs()
			_player.global_position = _pup.global_position + Vector3(-0.3, 0.3, 1.2)
			await get_tree().create_timer(0.5).timeout
			_player.interact()
			await get_tree().create_timer(0.3).timeout
			var held := _pup.holding
			_player.global_position = LANDING + Vector3(0, 0.3, 1.0)
			await get_tree().create_timer(1.5).timeout
			await close_dialogs()
			print("S3K4_Q1 mesale=%s titrek=%s ust=%s held=%s el=%s" % [d.objective_done(Q1, "mesale"), d.objective_done(Q1, "titrek"), d.objective_done(Q1, "ust_kaya"), held, d.objective_done(Q1, "el")])
			await _talk(helper_id, "Helper")
			print("S3K4_Q1 state=%s q2=%s level=%d" % [d.quest_state(Q1), d.quest_state(Q2), d.level])
			# the flare: the veil opens, the lightning leaves the route
			_player.global_position = FLARE_AT + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.5).timeout
			_player.interact()
			await close_dialogs()
			_player.global_position = mark + Vector3.UP * 0.3
			await get_tree().create_timer(1.6).timeout
			hp0 = d.hp
			await get_tree().create_timer(ShorePlan.BEAT * BAR * 1.5).timeout
			print("S3K4_FLARE fisek=%s veil=%s storm=%s quiet=%s" % [d.has_flag("s3_fisek4"), _veil.is_open, storm_on(), d.hp == hp0])
			# Tombik
			_player.global_position = ARENA + Vector3(0, 0.3, 7.0)
			await _beat_boss()
			print("S3K4_BOSS tombik=%s" % d.objective_done(Q2, "tombik"))
			for i in 40:
				if _rhythm_on:
					break
				await close_dialogs()
			_player.global_position = boss.global_position + Vector3(0, 0.3, 2.4)
			await get_tree().create_timer(1.3).timeout
			for i in 10:
				if d.has_flag("s3c4_ritim"):
					break
				_player.spin_attack()
				await get_tree().create_timer(0.6).timeout
			print("S3K4_RHYTHM ritim=%s" % d.has_flag("s3c4_ritim"))
			await close_dialogs()
			await get_tree().create_timer(0.4).timeout
			_player.global_position = ARENA + Vector3(0, 0.3, 4.5)
			for i in 40:
				await close_dialogs()
				if d.has_flag("s3c4_ani") and not GameState.in_dialogue and i > 12:
					break
			print("S3K4_PEARL inci=%s ani=%s" % [d.has_flag("inci_gumus"), d.has_flag("s3c4_ani")])
			await _talk(helper_id, "Helper")
			print("S3K4_DONE q2=%s fisek=%s inci=%s bitti=%s open=%s" % [d.quest_state(Q2), d.has_flag("s3_fisek4"), d.has_flag("inci_gumus"), d.has_flag("s3_bolum4_bitti"), ShoreTravel.destinations(d, "s3_chapter4")])
			get_tree().quit()
