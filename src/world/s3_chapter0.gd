extends S3Island
## Sezon 3 · Bölüm 0 – Mercan Koyu ve Yaşlı Deniz Feneri (levels 1–5, the
## hub). A fishing village on the shore: at night everyone locks the door.
## Mors Dede Bıyık tries to light the lighthouse alone, but its five pearls
## are gone. First "Gece Bekçileri": light the village torches, walk two
## scared villagers to the fire hand in hand, calm the Titrekler. Then the
## mini boss Hortlak Çarşaf on the clothesline (under it: two giggling
## heron chicks), and the cove's İşaret Fişeği opens the sea to Mürekkep
## Adası. Stalls: Mors Dede (potions), Kerpeten (tools), Dantel (outfits),
## Olta (by the pier).
##
## Layout: sand 60×52 round (0,0,0) · pier south (0,0,24) · square with the
## fire at (0,0,6) · cottages west · lighthouse north-east (18,0,-18) ·
## clothesline yard east (20,0,2).

const Q1 := "gece_bekcileri"
const Q2 := "hortlak_carsaf"
const SAND := Color("#c7ad7c")
const FIRE := Vector3(0, 0, 6)
const YARD := Vector3(19, 0, 2)
const LIGHTHOUSE := Vector3(18, 0, -18)
const VILLAGERS := [["gull_chick", Vector3(-22, 0, -14)], ["crab_friend", Vector3(22, 0, 18)]]
const TITREKS := [["titrek_yengec", Vector3(-10, 0, -12)], ["urkek_marti", Vector3(8, 0, -10)],
	["titrek_yengec", Vector3(-16, 0, 14)], ["urkek_marti", Vector3(12, 0, 16)]]

var _chicks: Array[Node3D] = []
var _night := false


func _ready() -> void:
	begin("s3_chapter0")
	var d := GameState.data
	flare_flag = "s3_fisek0"
	mist(0.4)
	_build()
	Decor.auto(self, "kumsal")
	npc(self, "mors_dede", "mors_dede", LIGHTHOUSE + Vector3(-4.0, 0, 4.0), 30.0).name = "Mors"
	npc(self, "kerpeten", "kerpeten", Vector3(-9, 0, 2), 80.0).name = "Kerpeten"
	npc(self, "dantel", "dantel", Vector3(-7, 0, 10), 110.0).name = "Dantel"
	npc(self, "olta", "olta", Vector3(-4.5, 0, 21), 150.0).name = "Olta"
	npc(self, "tospik_nine", "turtle", FIRE + Vector3(3.2, 0, 2.2), -120.0).name = "Tospik"
	if d.character_id != "tosbi":
		npc(self, "tosbi", "tosbi", FIRE + Vector3(4.6, 0, 0.4), -100.0).name = "Tosbi"
	_spawn_night()
	make_boss("carsaf", YARD, d.objective_done(Q2, "carsaf"))
	if d.objective_done(Q2, "carsaf"):
		boss.visible = false
		_show_chicks()
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	_refresh()
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.8, false).timeout
	if not d.has_flag("s3c0_geldi"):
		d.set_flag("s3c0_geldi")
		GameState.bark("s3k0_basla")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


## The Titrekler and the scared villagers come with Quest 1 (calmed or
## walked home before it starts they wouldn't count); torches lit early are
## counted when it starts.
func _spawn_night() -> void:
	var d := GameState.data
	if _night or d.quest_state(Q1) != "active":
		return
	_night = true
	titreks(TITREKS)
	for i in VILLAGERS.size():
		if d.objective_count(Q1, "el").x > i:
			continue
		var f := friend("koylu", VILLAGERS[i][0], VILLAGERS[i][1], FIRE)
		f.goal_radius = 3.5
	var lit := 0
	for n in lv.get_children():
		if n is BeachTorch and (n as BeachTorch).lit:
			lit += 1
	for i in maxi(lit - d.objective_count(Q1, "mesale").x, 0):
		GameState.notify("light", "mesale")


func _build() -> void:
	land(Vector3(0, 0, 0), Vector2(60, 52), SAND)
	fence(Vector3(0, 0, 0), Vector2(58, 50))
	dock(Vector3(0, 0, 27.5))
	# the square: a fire, logs, three torches round the village
	var fire := SmallLantern.new()
	fire.style = "campfire"
	fire.lantern_id = "s3k0_ates"
	fire.accent = "honey"
	fire.position = FIRE
	lv.add_child(fire)
	fire.light_up(true)
	for at: Vector3 in [Vector3(-14, 0, -6), Vector3(10, 0, -4), Vector3(-2, 0, 17)]:
		torch(at)
	# cottages along the west side, doors shut
	for i in 4:
		var at := Vector3(-22.0 + (i % 2) * 7.0, 0, -4.0 + i * 5.5)
		if prop("balikci_evi", at, 4.6, PI * 0.5) == null:
			Toon.part(lv, "box", Vector3(4, 3, 4), Color("#f4efe6"), at + Vector3.UP * 1.5)
			Toon.part(lv, "cone", Vector3(5.6, 2.0, 5.6), Color("#7fb2e0"), at + Vector3.UP * 4.0)
		var body := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = Vector3(3.6, 4, 3.6)
		c.shape = b
		c.position.y = 2.0
		body.add_child(c)
		body.position = at
		lv.add_child(body)
	# the old lighthouse on its rock, dark until the pearls come back
	land(LIGHTHOUSE, Vector2(10, 10), Color("#8f8aa0"), 0.6)
	if prop("deniz_feneri", LIGHTHOUSE + Vector3(0, 0.6, 0), 12.0) == null:
		Toon.part(lv, "cylinder", Vector3(3.0, 10.0, 3.0), Color("#f4efe6"), LIGHTHOUSE + Vector3(0, 5.6, 0))
		Toon.part(lv, "cone", Vector3(3.6, 2.0, 3.6), Color("#e8463a"), LIGHTHOUSE + Vector3(0, 11.6, 0))
	var lb := StaticBody3D.new()
	var lc := CollisionShape3D.new()
	var ls := CylinderShape3D.new()
	ls.radius = 1.9
	ls.height = 8.0
	lc.shape = ls
	lc.position.y = 4.6
	lb.add_child(lc)
	lb.position = LIGHTHOUSE
	lv.add_child(lb)
	var fl := flare(LIGHTHOUSE + Vector3(-5.5, 0, 6.5), "s3_fisek0", "hortlak_carsaf/carsaf", "s3k0_kilit")
	fl.fire_target = "fisek"
	# the clothesline yard: two poles, a line, sheets
	for x: float in [-4.5, 4.5]:
		Toon.part(lv, "cylinder", Vector3(0.2, 3.4, 0.2), Color("#8a5a3a"), YARD + Vector3(x, 1.7, -4.0))
	Toon.part(lv, "box", Vector3(9.0, 0.05, 0.05), Color("#f4efe6"), YARD + Vector3(0, 3.3, -4.0), Vector3.ZERO, 0.0, 0.0)
	for x: float in [-3.0, 3.2]:
		Toon.part(lv, "box", Vector3(1.6, 1.8, 0.06), Color("#cfe0ff") if x < 0 else Color("#ffd9e0"), YARD + Vector3(x, 2.3, -4.0))
	# palms, coral and rocks round the cove
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 14:
		var a := TAU * i / 14.0
		var at := Vector3(cos(a) * 27.0, 0, sin(a) * 23.0)
		if absf(at.x) < 6.0 and at.z > 15.0:
			continue   # the pier stays clear
		var id: String = ["koy_cali", "kiyi_kaya", "mercan"][i % 3]
		prop(id, at, [2.6, 2.2, 2.6][i % 3] * rng.randf_range(0.85, 1.2), rng.randf() * TAU)


func fight_ready() -> bool:
	var d := GameState.data
	return d.quest_state(Q2) == "active" and not d.objective_done(Q2, "carsaf")


func _begin_fight() -> void:
	start_fight("s3k0_carsaf", "Uçuşan halkalardan kaç. Çarşaf yorulunca vur!", "Halkalardan kaç, yorulunca vur!")


func _on_boss_sad() -> void:
	super._on_boss_sad()
	GameState.bark("s3k0_carsaf_yorgun")


## Under the sheet: two giggling heron chicks.
func _on_boss_calmed() -> void:
	_hud.clear_hint()
	boss_camera(false)
	var tw := boss.create_tween()
	tw.tween_property(boss, "scale", Vector3(1.0, 0.05, 1.0), 0.5)
	tw.tween_callback(func() -> void: boss.visible = false)
	_show_chicks()
	Audio.play("laugh")
	GameState.bark("s3k0_carsaf_son")
	await GameState.dialogue_closed
	_refresh()


func _show_chicks() -> void:
	if not _chicks.is_empty():
		return
	for s: float in [-1.0, 1.0]:
		var m := NpcModels.build("balikcil")
		m.position = YARD + Vector3(0.8 * s, 0, 0.4)
		m.rotation.y = -0.4 * s
		add_child(m)
		_chicks.append(m)


func _on_flare() -> void:
	_hud.clear_hint()
	GameState.bark("s3k0_fisek")
	_refresh()


func _refresh() -> void:
	var d := GameState.data
	_spawn_night()
	var mors := get_node("Mors") as Node3D
	var go := d.quest_state(Q1) in ["none", "ready"] or d.quest_state(Q2) in ["none", "ready"] and d.quest_state(Q1) == "done"
	if go and not mors.has_node("Beacon"):
		Beacon.attach(mors, 3.0, Tokens.color("spark-white"))
	elif not go and mors.has_node("Beacon"):
		mors.get_node("Beacon").queue_free()
	var fl := lv.get_node_or_null("Flare") as Node3D
	if fl and d.objective_done(Q2, "carsaf") and not d.has_flag("s3_fisek0") and not fl.has_node("Beacon"):
		Beacon.attach(fl, 3.4, Tokens.color("spark-yellow"))
		_hud.show_hint("Deniz Feneri'nin yanındaki İşaret Fişeği'ni yak", "İşaret Fişeği'ni yak")
	var dk := lv.get_node_or_null("Dock") as Node3D
	if dk and d.has_flag("s3_bolum0_bitti") and not d.has_flag("s3_fisek1") and not dk.has_node("Beacon"):
		Beacon.attach(dk, 3.0, Tokens.color("spark-white"))
		_hud.show_hint("Kabuk Kayık'a bin: Mürekkep Adası'na açıl", "Kayığa bin: Mürekkep Adası")


func _run_demo(which: String) -> void:
	match which:
		"cove":
			# the whole chapter by its quests (headless)
			DevTools.auto_dialogue = true
			var d := GameState.data
			await _talk("mors_dede", "Mors")
			for n in lv.get_children():
				var bt := n as BeachTorch
				if bt and not bt.lit:
					_player.global_position = bt.global_position + Vector3(0, 0.3, 1.2)
					await get_tree().create_timer(0.4, false).timeout
					_player.interact()
					await get_tree().create_timer(0.2, false).timeout
			for f: HandFriend in get_children().filter(func(n: Node) -> bool: return n is HandFriend):
				_player.global_position = f.global_position + Vector3(0, 0.3, 1.2)
				await get_tree().create_timer(0.5, false).timeout
				_player.interact()
				await get_tree().create_timer(0.3, false).timeout
				_player.global_position = FIRE + Vector3(0, 0.3, 2.0)
				await get_tree().create_timer(1.5, false).timeout
			print("S3K0_Q1 mesale=%s el=%s" % [d.objective_done(Q1, "mesale"), d.objective_done(Q1, "el")])
			await _calm_all()
			await _talk("mors_dede", "Mors")
			print("S3K0_Q1 state=%s q2=%s level=%d" % [d.quest_state(Q1), d.quest_state(Q2), d.level])
			_player.global_position = YARD + Vector3(0, 0.3, 7.0)
			await _beat_boss()
			print("S3K0_BOSS carsaf=%s" % d.objective_done(Q2, "carsaf"))
			_player.global_position = lv.get_node("Flare").global_position + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.5, false).timeout
			_player.interact()
			await close_dialogs()
			await _talk("mors_dede", "Mors")
			print("S3K0_DONE q2=%s fisek=%s bitti=%s open=%s" % [d.quest_state(Q2), d.has_flag("s3_fisek0"), d.has_flag("s3_bolum0_bitti"), ShoreTravel.destinations(d, "s3_chapter0")])
			print("S3K0_WAY dock_star=%s hint=%s" % [lv.get_node("Dock").has_node("Beacon"), _hud._hint_label.text if _hud._hint.visible else ""])
			# walk to the pier's end: the boat must come into reach ("Bin")
			_player.global_position = Vector3(0, 0.3, 20.0)
			Input.action_press("move_back")
			await get_tree().create_timer(2.0, false).timeout
			Input.action_release("move_back")
			await get_tree().create_timer(0.3, false).timeout
			print("S3K0_DOCK z=%.1f focus=%s" % [_player.global_position.z, _player._focus.name if _player._focus else "-"])
			get_tree().quit()
