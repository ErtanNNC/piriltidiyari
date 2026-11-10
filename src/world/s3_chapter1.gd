extends S3Island
## Sezon 3 · Bölüm 1 – Mürekkep Adası, Lacivert İnci (levels 5–10). An
## island sunk in night, full of mushrooms and seashells. Its keeper, the
## octopus Mürekkep, is so afraid of the dark that he hides everything
## under ink, which only makes the island darker. Ink puddles lie across
## the route: standing in one fills the Titreme barı fast, but ink draws
## back from a lit light-mushroom (a torch), so the keeper lights a safe
## path. Quest 1 "Saklananlara Işık" (Minik Kol): light the six
## light-mushrooms, calm the Titrekler, lead Minik Kol's little sibling out
## of the ink-dark corner to the landing fire by hand. Then the İşaret
## Fişeği opens the Titreme Perdesi, the fight with Mürekkep among ink
## puddles, an Ateşböceği Kavanozu for him ("Karanlıkta yanında bir ışık
## olsun yeter."), the Lacivert İnci, and Mürekkep's charm stall.
##
## Layout (south = +z, the pier): landing 30×18 round (0,0,22), fire at
## (-5,0,21), pier (0,0,32.5) · mushroom grove 18×26 round (0,0,0) with
## three bands of ink at z 7, -1, -9 · the dark corner west of it 14×14
## round (-16,0,0) · flare clearing 30×14 round (0,0,-20), flare at
## (-7,0,-21) · Titreme Perdesi at z -27 · Mürekkep's arena 28×24 round
## (0,0,-39).

const Q1 := "isik_yolu"
const Q2 := "murekkebin_isigi"
const GROUND := Color("#3a3560")
const GROUND_LIGHT := Color("#4a4478")
const GROUND_DARK := Color("#2f2b52")
const WARM := Color(1.0, 0.86, 0.45)
const FIRE := Vector3(-5, 0, 21)
const GIVER := Vector3(-1.5, 0, 22.5)
const FLARE := Vector3(-7, 0, -21)
const ARENA := Vector3(0, 0, -39)
const NOOK := Vector3(-18.5, 0, -0.5)
const INK_COLD := 7.0
## The light-mushrooms: the landing, one per ink band, the clearing, the
## dark corner. Each stands just outside the puddles it clears.
const LIGHTS := [Vector3(-3, 0, 15.5), Vector3(2, 0, 9.6), Vector3(-2, 0, 1.6), Vector3(2, 0, -6.4),
	Vector3(3.5, 0, -14.8), Vector3(-15.2, 0, 3.0)]
## [center, radius]: three bands across the grove, two in the dark corner.
const INK := [[Vector3(-5, 0, 7), 2.9], [Vector3(0, 0, 7), 2.9], [Vector3(5, 0, 7), 2.9],
	[Vector3(-5, 0, -1), 2.9], [Vector3(0, 0, -1), 2.9], [Vector3(5, 0, -1), 2.9],
	[Vector3(-5, 0, -9), 2.9], [Vector3(0, 0, -9), 2.9], [Vector3(5, 0, -9), 2.9],
	[Vector3(-12.5, 0, -0.5), 3.2], [Vector3(-18, 0, 0.5), 3.0]]
const ARENA_INK := [Vector3(-8, 0, -33), Vector3(8, 0, -34), Vector3(-9, 0, -45), Vector3(9, 0, -46)]
const TITREKS := [["saklambac_ahtapotu", Vector3(10, 0, 18)], ["golge_baligi", Vector3(-10, 0, 26)],
	["saklambac_ahtapotu", Vector3(5.5, 0, 3)], ["golge_baligi", Vector3(-10, 0, -17)],
	["saklambac_ahtapotu", Vector3(10, 0, -24)]]
## Scenery on the rim, outside the walls: [id, x, z, height]. Low pieces on
## south edges (the camera looks from the south).
const RIM := [["murekkep_mantar", -14.3, 16, 3.4], ["kiyi_kaya", -14.3, 21, 1.8], ["murekkep_mantar", -14.3, 27, 2.6],
	["mercan", 14.3, 15, 2.2], ["murekkep_mantar", 14.3, 20, 4.0], ["dev_kabuk", 14.3, 26, 1.6],
	["dev_kabuk", -11, 30.4, 1.0], ["kiyi_kaya", -6, 30.4, 0.9], ["mercan", 7, 30.4, 1.0], ["dev_kabuk", 12, 30.4, 1.1],
	["murekkep_mantar", 8.3, 10, 3.0], ["mercan", 8.3, 3, 2.0], ["murekkep_mantar", 8.3, -4, 4.2], ["dev_kabuk", 8.3, -10, 1.5],
	["murekkep_mantar", -8.3, 10, 3.6], ["murekkep_mantar", -8.3, -10, 3.0],
	["murekkep_mantar", -12, 6.3, 3.2], ["murekkep_mantar", -17, 6.3, 4.4], ["kiyi_kaya", -21, 6.3, 2.0],
	["murekkep_mantar", -22.3, 2, 3.0], ["dev_kabuk", -22.3, -3, 1.4], ["dev_kabuk", -13, -6.3, 0.9], ["mercan", -19, -6.3, 1.0],
	["murekkep_mantar", -14.3, -16, 3.8], ["kiyi_kaya", -14.3, -23, 2.0], ["dev_kabuk", 14.3, -17, 1.8], ["murekkep_mantar", 14.3, -24, 3.4],
	["murekkep_mantar", -13.3, -31, 4.0], ["mercan", -13.3, -38, 2.4], ["murekkep_mantar", -13.3, -46, 3.0],
	["kiyi_kaya", 13.3, -32, 2.2], ["murekkep_mantar", 13.3, -40, 4.6], ["dev_kabuk", 13.3, -47, 1.6],
	["murekkep_mantar", -8, -50.3, 5.0], ["dev_kabuk", 0, -50.3, 2.4], ["murekkep_mantar", 8, -50.3, 4.4]]

var _veil: ShiverVeil
var _torches: Array[BeachTorch] = []
var _inks: Array[InkPuddle] = []
var _q1_spawned := false


func _ready() -> void:
	begin("s3_chapter1")
	var d := GameState.data
	flare_flag = "s3_fisek1"
	mist(0.45)
	_build()
	Decor.auto(self, "kumsal")
	var giver := npc(self, "minik_kol", "saklambac_ahtapotu", GIVER, 20.0)
	giver.name = "MinikKol"
	var calm := d.objective_done(Q2, "murekkep") or d.quest_state(Q2) == "done"
	make_boss("murekkep", ARENA, calm)
	if calm:
		_jar()
		giver_comes("MinikKol", ARENA + Vector3(4.0, 0, 7.0), false)
		if not d.has_flag("inci_lacivert"):
			drop_pearl("lacivert", ARENA + Vector3(0, 0, 5.5), "Lacivert İnci", "Karanlıkta küçük bir ışık yeter.")
	else:
		for at: Vector3 in ARENA_INK:
			_ink(at, 2.4)
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	d.flags_changed.connect(_refresh)
	_refresh()
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(0.5).timeout
	_dry_ink()
	await get_tree().create_timer(1.3).timeout
	if not d.has_flag("s3c1_geldi"):
		d.set_flag("s3c1_geldi")
		GameState.bark("s3k1_basla")
		_hud.show_hint("Ateşin yanındaki Minik Kol ile konuş", "Minik Kol ile konuş")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _build() -> void:
	land(Vector3(0, 0, 22), Vector2(30, 18), GROUND_LIGHT)
	land(Vector3(0, 0, 0), Vector2(18, 26), GROUND)
	land(Vector3(-16, 0, 0), Vector2(14, 14), GROUND_DARK)
	land(Vector3(0, 0, -20), Vector2(30, 14), GROUND_LIGHT)
	land(Vector3(0, 0, -39), Vector2(28, 24), GROUND)
	# walls along the walkable outline (nobody walks into the sea)
	for w: Array in [
			[-13.5, 30.5, 13.5, 30.5], [13.5, 30.5, 13.5, 13], [-13.5, 30.5, -13.5, 13],
			[-13.5, 13, -7.5, 13], [7.5, 13, 13.5, 13],
			[7.5, 13, 7.5, -13], [-7.5, 13, -7.5, 5.5], [-7.5, -5.5, -7.5, -13],
			[-21.5, 5.5, -7.5, 5.5], [-21.5, -5.5, -7.5, -5.5], [-21.5, 5.5, -21.5, -5.5],
			[-13.5, -13, -7.5, -13], [7.5, -13, 13.5, -13], [13.5, -13, 13.5, -27], [-13.5, -13, -13.5, -27],
			[-13.5, -27, -4.5, -27], [4.5, -27, 13.5, -27],
			[12.5, -27, 12.5, -49.5], [-12.5, -27, -12.5, -49.5], [-12.5, -49.5, 12.5, -49.5]]:
		_wall(Vector2(w[0], w[1]), Vector2(w[2], w[3]))
	dock(Vector3(0, 0, 32.5))
	# the landing fire: the hiding family gathers here
	var fire := SmallLantern.new()
	fire.style = "campfire"
	fire.lantern_id = "s3k1_ates"
	fire.accent = "honey"
	fire.position = FIRE
	lv.add_child(fire)
	fire.light_up(true)
	# ink over the route and the dark corner, then the light-mushrooms
	for e: Array in INK:
		_ink(e[0], e[1])
	for at: Vector3 in LIGHTS:
		_light_mushroom(at)
	flare(FLARE, "s3_fisek1", Q1, "s3k1_kilit")
	_veil = veil(Vector3(0, 0, -27), 8.0, "s3c1_perde")
	for e: Array in RIM:
		_scenery(e[0], Vector3(e[1], 0, e[2]), e[3], (e[1] * 7.0 + e[2] * 3.0))


func _wall(a: Vector2, b: Vector2) -> void:
	var wall := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(absf(b.x - a.x) + 1.0, 12.0, absf(b.y - a.y) + 1.0)
	c.shape = s
	wall.add_child(c)
	wall.set_meta("camera_ignore", true)   # invisible: never pushes the camera in
	wall.position = Vector3((a.x + b.x) * 0.5, 6.0, (a.y + b.y) * 0.5)
	lv.add_child(wall)


## A permanent ink puddle: colder than the ones Mürekkep squirts.
func _ink(at: Vector3, r: float) -> InkPuddle:
	var p := InkPuddle.spawn(lv, at, r, 0.0)
	p.cold = INK_COLD
	_inks.append(p)
	return p


## A mushroom, a shell... the model when it exists, else simple shapes.
func _scenery(id: String, at: Vector3, h: float, yaw := 0.0) -> Node3D:
	var m := prop(id, at, h, yaw)
	if m:
		return m
	m = Node3D.new()
	m.position = at
	lv.add_child(m)
	match id:
		"murekkep_mantar":
			Toon.part(m, "cylinder", Vector3(h * 0.22, h * 0.8, h * 0.22), Color("#d8d0ee"), Vector3(0, h * 0.4, 0))
			Toon.part(m, "ellipsoid", Vector3(h * 0.9, h * 0.42, h * 0.9), Color("#6a5acd"), Vector3(0, h * 0.82, 0))
		"dev_kabuk":
			Toon.part(m, "ellipsoid", Vector3(h * 1.3, h, h * 0.8), Color("#e8c8d8"), Vector3(0, h * 0.45, 0), Vector3(0, rad_to_deg(yaw), 0))
		"mercan":
			for k in 3:
				Toon.part(m, "capsule", Vector3(h * 0.16, h * (0.7 + k * 0.15), h * 0.16), Color("#c86a9a"), Vector3((k - 1) * h * 0.22, h * 0.4, 0), Vector3(0, 0, (k - 1) * -18.0))
		_:
			Toon.part(m, "ellipsoid", Vector3(h * 1.2, h, h), Color("#5a5578"), Vector3(0, h * 0.4, 0))
	return m


## A torch with a light-mushroom beside it: the mushroom glows once lit.
func _light_mushroom(at: Vector3) -> void:
	var t := torch(at)
	t.name = "Light%d" % _torches.size()
	_torches.append(t)
	var m := _scenery("murekkep_mantar", at + Vector3(0.9, 0, -0.7), 1.5, at.x)
	if t.lit:
		_glow(m)
	t.lit_up.connect(func() -> void:
		_glow(m)
		_dry_ink()
		if not GameState.data.has_flag("s3c1_mantar"):
			GameState.data.set_flag("s3c1_mantar")
			GameState.bark("s3k1_mantar"))


func _glow(m: Node3D) -> void:
	var col := Color(0.55, 0.95, 1.0)
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = 0.9
	l.omni_range = 3.2
	l.position.y = 1.7
	m.add_child(l)
	for k in 3:
		Toon.part(m, "sphere", Vector3(0.14, 0.14, 0.14), col, Vector3(cos(k * 2.1) * 0.5, 1.45 + k * 0.22, sin(k * 2.1) * 0.5), Vector3.ZERO, 2.4, 0.0)


## Ink draws back from the light: puddles under a lit light shrink (they
## are harmless there anyway, see InkPuddle).
func _dry_ink() -> void:
	for p in _inks:
		if not is_instance_valid(p) or p.has_meta("dry") or not LightRing.torch_near(get_tree(), p.global_position):
			continue
		p.set_meta("dry", true)
		p.create_tween().tween_property(p, "scale", Vector3(0.45, 1.0, 0.45), 0.8).set_trans(Tween.TRANS_SINE)


## The hiding ones come out once Minik Kol has asked for light (nothing can
## be done before the quest counts it).
func _spawn_q1() -> void:
	if _q1_spawned:
		return
	_q1_spawned = true
	var d := GameState.data
	var c := d.objective_count(Q1, "titrek")
	for i in range(mini(c.x, TITREKS.size()), TITREKS.size()):
		titrek(TITREKS[i][0], TITREKS[i][1])
	if d.objective_done(Q1, "kardes"):
		return
	var f := HandFriend.new()
	f.name = "Kardes"
	f.friend_id = "kardes"
	f.model_id = "saklambac_ahtapotu"
	f.goal = FIRE
	f.goal_radius = 3.5
	f.set_model(_small_octopus())
	f.position = NOOK
	add_child(f)
	f.held.connect(func() -> void:
		if not d.has_flag("s3c1_kardes"):
			d.set_flag("s3c1_kardes")
			GameState.bark("s3k1_kardes"))
	f.arrived.connect(func() -> void: GameState.bark("s3k1_kardes_geldi"))


func _small_octopus() -> Node3D:
	var m := NpcModels.build("saklambac_ahtapotu")
	m.scale *= 0.6
	return m


func _process(delta: float) -> void:
	super._process(delta)
	var d := GameState.data
	if d.has_flag("s3c1_bas") or GameState.in_dialogue or fighting:
		return
	var at := _player.global_position
	for p in _inks:
		if is_instance_valid(p) and not p.has_meta("dry") and Vector2(at.x - p.global_position.x, at.z - p.global_position.z).length() < p.radius:
			d.set_flag("s3c1_bas")
			GameState.bark("s3k1_bas")
			return


func fight_ready() -> bool:
	var d := GameState.data
	return d.quest_state(Q2) == "active" and d.has_flag("s3_fisek1") and not d.objective_done(Q2, "murekkep")


func _begin_fight() -> void:
	start_fight("s3k1_murekkep", "Mürekkebe basma, halkalardan kaç. Mürekkep yorulunca vur!", "Mürekkepten kaç, yorulunca vur!")


func _on_boss_sad() -> void:
	super._on_boss_sad()
	GameState.bark("s3k1_yorgun")


## The keeper gives Mürekkep an Ateşböceği Kavanozu: a small light beside
## him, the arena's ink fades, then he hands over the pearl.
func _on_boss_calmed() -> void:
	_hud.clear_hint()
	boss_camera(false)
	GameState.bark("s3k1_kavanoz")
	await GameState.dialogue_closed
	_jar()
	Audio.play("lantern")
	Effects.ring(self, boss.global_position + Vector3.UP * 0.3, 6.0, WARM, 0.7)
	_fade_arena_ink()
	await get_tree().create_timer(1.4).timeout
	GameState.bark("s3k1_inci_dustu")
	await GameState.dialogue_closed
	drop_pearl("lacivert", ARENA + Vector3(0, 0, 5.5), "Lacivert İnci", "Karanlıkta küçük bir ışık yeter.")
	giver_comes("MinikKol", ARENA + Vector3(4.0, 0, 7.0))
	_refresh()


## The jar of fireflies that stays beside Mürekkep (a light that counts as
## a torch).
func _jar() -> void:
	if has_node("Jar"):
		return
	var j := TempLight.spawn(self, ARENA + Vector3(2.0, 0, 1.3), 4.0, 1.0e8, WARM)
	j.name = "Jar"
	Toon.part(j, "cylinder", Vector3(0.5, 0.12, 0.5), Color("#8a5a3a"), Vector3(0, 0.2, 0))
	Toon.part(j, "cylinder", Vector3(0.44, 0.1, 0.44), Color("#8a5a3a"), Vector3(0, 0.82, 0))
	for k in 4:
		Toon.part(j, "sphere", Vector3(0.08, 0.08, 0.08), Color("#fff1b0"), Vector3(cos(k * 1.7) * 0.32, 0.9 + k * 0.18, sin(k * 1.7) * 0.32), Vector3.ZERO, 2.6, 0.0)


func _fade_arena_ink() -> void:
	for p: Node3D in get_tree().get_nodes_in_group("ink"):
		if p.global_position.z > -27.0:
			continue
		var tw := p.create_tween()
		tw.tween_property(p, "scale", Vector3(0.05, 1.0, 0.05), 1.0).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(p.queue_free)


func _on_flare() -> void:
	_hud.clear_hint()
	_veil.open()
	GameState.bark("s3k1_fisek")
	_refresh()


func _on_pearl(_id: String) -> void:
	_hud.clear_hint()
	GameState.bark("s3k1_inci")
	_refresh()


## Calm for good: Mürekkep keeps a charm stall where he hid.
func _boss_to_shop() -> void:
	if has_node("Murekkep"):
		return
	boss.visible = false
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	var n := npc(self, "murekkep", "murekkep", ARENA, 0.0)
	n.name = "Murekkep"
	n._model.scale *= 1.2


func _refresh() -> void:
	var d := GameState.data
	var q1 := d.quest_state(Q1)
	var q2 := d.quest_state(Q2)
	if q1 == "active":
		_spawn_q1()
		# light-mushrooms lit before Minik Kol asked still count
		var lit := _torches.filter(func(t: BeachTorch) -> bool: return t.lit).size()
		var c := d.objective_count(Q1, "mantar")
		if lit > c.x:
			d.advance_objective(Q1, "mantar", lit - c.x)
			return   # quest_changed calls _refresh again
	var giver := get_node("MinikKol") as Node3D
	var go := q1 in ["none", "ready"] or q2 == "ready"
	if go and not giver.has_node("Beacon"):
		Beacon.attach(giver, 2.4, Tokens.color("spark-white"))
	elif not go and giver.has_node("Beacon"):
		giver.get_node("Beacon").queue_free()
	var fl := lv.get_node_or_null("Flare") as Node3D
	if fl and q1 in ["ready", "done"] and not d.has_flag("s3_fisek1") and not fl.has_node("Beacon"):
		Beacon.attach(fl, 3.4, Tokens.color("spark-yellow"))
	if q2 == "active" and not d.has_flag("s3_fisek1"):
		_hud.show_hint("Kuzeydeki açıklıkta İşaret Fişeği'ni yak", "İşaret Fişeği'ni yak")
	if d.has_flag("s3_bolum1_bitti"):
		_boss_to_shop()
		var dk := lv.get_node_or_null("Dock") as Node3D
		if dk and not d.has_flag("s3_fisek2") and not dk.has_node("Beacon"):
			Beacon.attach(dk, 3.0, Tokens.color("spark-white"))
			_hud.show_hint("Kabuk Kayık'a bin: Rüzgârlı Kayalıklar'a açıl", "Kayığa bin: Rüzgârlı Kayalıklar")


func _run_demo(which: String) -> void:
	match which:
		"island":
			# the whole chapter by its quests (headless)
			DevTools.auto_dialogue = true
			var d := GameState.data
			var ring := _player.ring
			# the ink: cold in the dark, harmless once its light-mushroom burns
			var mid: Vector3 = INK[1][0]
			_player.global_position = mid + Vector3(0, 0.3, 0)
			await get_tree().create_timer(0.3).timeout
			await close_dialogs()
			ring.warm()
			await get_tree().create_timer(1.0).timeout
			var dark := ring.shiver
			_player.global_position = _torches[1].global_position + Vector3(0, 0.3, 1.2)
			await get_tree().create_timer(0.4).timeout
			_player.interact()
			await close_dialogs()
			_player.global_position = mid + Vector3(0, 0.3, 0)
			ring.warm()
			ring.shiver = 0.5
			await get_tree().create_timer(1.0).timeout
			print("S3K1_INK dark=+%.2f lit=0.50->%.2f torch=%s dry=%s west_dark=%s" % [dark, ring.shiver, _torches[1].lit,
				_inks[1].has_meta("dry"), not _inks[0].has_meta("dry")])
			ring.warm()
			await _talk("minik_kol", "MinikKol")
			print("S3K1_Q1 state=%s early_mantar=%d titrek=%d friend=%s" % [d.quest_state(Q1), d.objective_count(Q1, "mantar").x,
				get_tree().get_nodes_in_group("titrek").size(), has_node("Kardes")])
			for bt in _torches:
				if not bt.lit:
					_player.global_position = bt.global_position + Vector3(0, 0.3, 1.2)
					await get_tree().create_timer(0.4).timeout
					_player.interact()
					await close_dialogs()
			var f := get_node("Kardes") as HandFriend
			_player.global_position = f.global_position + Vector3(0, 0.3, 1.2)
			await get_tree().create_timer(0.5).timeout
			_player.interact()
			await close_dialogs()
			var held := ring.holding_hands
			_player.global_position = FIRE + Vector3(0, 0.3, 2.0)
			await get_tree().create_timer(1.5).timeout
			await close_dialogs()
			print("S3K1_Q1 mantar=%s kardes=%s held=%s" % [d.objective_done(Q1, "mantar"), d.objective_done(Q1, "kardes"), held])
			await _calm_all()
			await close_dialogs()
			print("S3K1_Q1 titrek=%s veil_shut=%s" % [d.objective_done(Q1, "titrek"), not _veil.is_open])
			await _talk("minik_kol", "MinikKol")
			print("S3K1_Q1 state=%s q2=%s level=%d" % [d.quest_state(Q1), d.quest_state(Q2), d.level])
			_player.global_position = FLARE + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.5).timeout
			_player.interact()
			await close_dialogs()
			print("S3K1_FLARE fisek=%s veil_open=%s" % [d.has_flag("s3_fisek1"), _veil.is_open])
			_player.global_position = ARENA + Vector3(0, 0.3, 7.0)
			await _beat_boss()
			for i in 80:
				if has_node("Pearl"):
					break
				await close_dialogs()
			print("S3K1_BOSS murekkep=%s jar=%s arena_ink=%d pearl=%s" % [d.objective_done(Q2, "murekkep"), has_node("Jar"),
				get_tree().get_nodes_in_group("ink").filter(func(p: Node3D) -> bool: return p.global_position.z < -27.0 and p.scale.x > 0.1).size(),
				has_node("Pearl")])
			_player.global_position = ARENA + Vector3(0, 0.3, 5.5)
			await get_tree().create_timer(0.6).timeout
			await close_dialogs()
			await get_tree().create_timer(2.0).timeout
			await _talk("minik_kol", "MinikKol")
			await get_tree().create_timer(0.3).timeout
			var keeper := get_node_or_null("Murekkep") as Node3D
			print("S3K1_SHOP npc=%s boss_hidden=%s shop=%s" % [keeper != null, not boss.visible, Content.shops.has("murekkep")])
			print("S3K1_DONE q2=%s fisek=%s inci=%s bitti=%s open=%s" % [d.quest_state(Q2), d.has_flag("s3_fisek1"),
				d.has_flag("inci_lacivert"), d.has_flag("s3_bolum1_bitti"), ShoreTravel.destinations(d, "s3_chapter1")])
			get_tree().quit()
