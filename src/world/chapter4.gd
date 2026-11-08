extends ChapterBase
## Bölüm 4 – Uyku Dağı. A sleepy snowy mountain climbed terrace by terrace:
##   T0 base camp (y 0)  – Dağ Feneri
##   T1 (y 3)            – campfire 1 melts the sleepy fog on ramp 2; ice field
##   T2 (y 6)            – campfire 2 melts the fog on ramp 3
##   T3 summit (y 9)     – Bilge Kuzey tells Mırıl's story; campfire 3 +
##                         the lesson open the frozen lake where Dondurma waits
## Snowballs roll down the ramps (honey circles warn first).

const QUEST := "uyku_dagi"
const X := 12.0
const LAKE := Vector3(0, 9, -78)

var _gates: Array[PusGate] = []
var _fogs: Array = []          ## sleepy fog nodes per campfire index
var _boss: Dondurma
var _fog_told := false
var _env: Environment


func _ready() -> void:
	_env = WorldLook.add(self, "dag")
	Decor.auto(self, "dag")
	var d := GameState.data
	if d.quest_state(QUEST) == "none":
		d.start_quest(Content.quests[QUEST])
	Pus.set_amount(0.55 if not d.objective_done(QUEST, "fener") else 0.4)
	_build()
	d.quest_changed.connect(func(_id: String) -> void: _advance())
	d.flags_changed.connect(_on_flags)
	_restore_progress()
	await get_tree().create_timer(1.9).timeout
	if DevTools.demo != "":
		_run_demo(DevTools.demo)
		return
	if not d.objective_done(QUEST, "fener"):
		GameState.bark("c4_giris")
		_hud.show_hint("Dağ Feneri'ni yak", "Dağ Feneri'ni yak")


func _advance() -> void:
	var d := GameState.data
	if d.objective_done(QUEST, "fener") and d.objective_count(QUEST, "ates").x == 0:
		_hud.show_hint("Kamp ateşini yak, uykulu sisi erit", "Kamp ateşini yak")
	elif d.objective_count(QUEST, "ates").x > 0 and not d.objective_done(QUEST, "kuzey"):
		_hud.show_hint("Zirveye tırman, Bilge Kuzey'i bul", "")
	_open_lake_if_ready()


func _open_lake_if_ready() -> void:
	var d := GameState.data
	if d.objective_done(QUEST, "ates") and d.objective_done(QUEST, "kuzey") and not _gates[2].is_open:
		_gates[2].open()
		_hud.show_hint("Donmuş göle git: Dondurma orada", "Donmuş göle git")


func _restore_progress() -> void:
	var d := GameState.data
	if d.objective_done(QUEST, "fener"):
		$Level/DagFeneri.light_up(true)
	var n := d.objective_count(QUEST, "ates").x
	for i in n:
		get_node("Level/KampAtesi%d" % i).light_up(true)
		_clear_fog(i, true)
	if d.objective_done(QUEST, "ates") and d.objective_done(QUEST, "kuzey"):
		_gates[2].open(true)
	if d.quest_state(QUEST) == "done":
		$Level/KivilcimFeneri.light_up(true)
		_melt(true)


# --- level -------------------------------------------------------------------

func _build() -> void:
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	# terraces and ramps
	MountainKit.terrace(lv, X, 48, 10, 0)
	MountainKit.terrace(lv, X, 10, -14, 3)
	MountainKit.terrace(lv, X, -14, -38, 6)
	MountainKit.terrace(lv, X, -38, -96, 9)
	MountainKit.ramp(lv, 0, 5, 18, 0, 10, 3)
	MountainKit.ramp(lv, 6, 5, -6, 3, -14, 6)
	MountainKit.ramp(lv, -6, 5, -30, 6, -38, 9)
	# side walls at each terrace's height, and the far end
	for t in [[48.0, 10.0, 0.0], [10.0, -14.0, 3.0], [-14.0, -38.0, 6.0], [-38.0, -96.0, 9.0]]:
		for side in [-1.0, 1.0]:
			MountainKit.wall(lv, Vector3(side * X, t[2], t[0]), Vector3(side * X, t[2], t[1]))
	MountainKit.wall(lv, Vector3(-X, 0, 48), Vector3(X, 0, 48))
	MountainKit.wall(lv, Vector3(-X, 9, -96), Vector3(X, 9, -96))
	# base camp
	var f := SmallLantern.new()
	f.name = "DagFeneri"
	f.big = true
	f.accent = "spark-white"
	f.lantern_id = "dag_feneri"
	f.position = Vector3(-3, 0, 34)
	lv.add_child(f)
	f.lit.connect(_on_lantern)
	var back := TravelSign.new()
	back.target_scene = "chapter0"
	back.title = "Gökkuşağı Köyü"
	back.action = "Köye dön"
	back.position = Vector3(4, 0, 42)
	lv.add_child(back)
	for at in [Vector3(-7, 0, 40), Vector3(6, 0, 28), Vector3(-8, 0, 22)]:
		_pine(lv, at)
	Mob.spawn(self, "kar_tavsani", Vector3(5, 0, 24))
	# campfires, each melting the sleepy fog and gate up the next ramp
	var fires := [Vector3(-6, 3, 4), Vector3(4, 6, -20), Vector3(6, 9, -46)]
	var gate_at := [Vector3(6, 3, -5.2), Vector3(-6, 6, -29.2), Vector3(0, 9, -60)]
	var fog_at := [Vector3(6, 3, -2.5), Vector3(-6, 6, -26.5), Vector3(0, 9, -57)]
	for i in 3:
		var cf := SmallLantern.new()
		cf.name = "KampAtesi%d" % i
		cf.style = "campfire"
		cf.accent = "honey"
		cf.lantern_id = "kamp_atesi"
		cf.position = fires[i]
		lv.add_child(cf)
		cf.lit.connect(_on_lantern)
		var g := PusGate.new()
		g.width = 5.4 if i < 2 else 4.0
		g.message = "Bu sis çok uykulu... Yakındaki ateşi yak!"
		g.position = gate_at[i]
		lv.add_child(g)
		_gates.append(g)
		var fog := MountainKit.sleepy_fog(lv, fog_at[i], Vector2(7, 4))
		fog.body_entered.connect(func(b: Node3D) -> void:
			if b is Player and not _fog_told:
				_fog_told = true
				GameState.bark("c4_sis"))
		_fogs.append(fog)
	# the lake wall: one gap where gate 3 stands
	MountainKit.wall(lv, Vector3(-X, 9, -60), Vector3(-2.0, 9, -60))
	MountainKit.wall(lv, Vector3(2.0, 9, -60), Vector3(X, 9, -60))
	# T1: ice field with an ice spike, snowballs on ramp 2
	MountainKit.ice(lv, Vector3(-5, 3, -6), Vector2(10, 7))
	Mob.spawn(self, "buz_dikeni", Vector3(-5, 3, -6))
	var lane1 := SnowballLane.new()
	lane1.top = Vector3(6, 6, -14)
	lane1.bottom = Vector3(6, 3, -4)
	lv.add_child(lane1)
	# T2
	for spec in [["kar_tavsani", Vector3(-5, 6, -18)], ["kar_tavsani", Vector3(2, 6, -34)], ["buz_dikeni", Vector3(0, 6, -26)]]:
		Mob.spawn(self, spec[0], spec[1])
	var lane2 := SnowballLane.new()
	lane2.top = Vector3(-6, 9, -38)
	lane2.bottom = Vector3(-6, 6, -28)
	lane2.delay = 1.2
	lv.add_child(lane2)
	for at in [Vector3(9, 6, -16), Vector3(-9, 6, -35)]:
		_pine(lv, at)
	# T3 summit: Bilge Kuzey, then the frozen lake
	npc(lv, "kuzey", "snowman", Vector3(-4, 9, -48), 20)
	for at in [Vector3(9, 9, -42), Vector3(-9, 9, -54)]:
		_pine(lv, at)
	MountainKit.ice(lv, LAKE + Vector3(-6, 0, 4), Vector2(4, 8))
	MountainKit.ice(lv, LAKE + Vector3(6, 0, 4), Vector2(4, 8))
	WorldLook.water(Toon.part(lv, "cylinder", Vector3(20, 0.06, 20), MountainKit.ICE, LAKE + Vector3(0, 0.02, -2), Vector3.ZERO, 0.15, 0.0), "ice")
	var kf := SmallLantern.new()
	kf.name = "KivilcimFeneri"
	kf.big = true
	kf.accent = "spark-white"
	kf.lantern_id = "kivilcim_feneri"
	kf.position = LAKE + Vector3(-8, 0, -12)
	lv.add_child(kf)
	# after the boss: a shortcut home next to the Kıvılcım Feneri
	TravelSign.exit_home(lv, kf.position + Vector3(4, 0, 2.5), "bolum4_bitti")
	var arena := TriggerArea.new()
	arena.area_id = "donmus_gol"
	arena.radius = 3.0
	arena.checkpoint = true
	arena.position = Vector3(0, 9, -64)
	lv.add_child(arena)
	arena.reached.connect(_start_boss)
	_side_content(lv)
	_player.respawn_point = _player.global_position


func _pine(parent: Node3D, at: Vector3) -> void:
	var tree := Node3D.new()
	tree.position = at
	parent.add_child(tree)
	Toon.part(tree, "cylinder", Vector3(0.4, 1.2, 0.5), Color("#8a5a3c"), Vector3(0, 0.6, 0))
	for k in 3:
		Toon.part(tree, "cone", Vector3(2.4 - k * 0.6, 1.6, 2.4 - k * 0.6), Color("#5a9e78"), Vector3(0, 1.6 + k * 0.9, 0))
		Toon.part(tree, "cone", Vector3(1.8 - k * 0.5, 0.5, 1.8 - k * 0.5), MountainKit.SNOW, Vector3(0, 2.2 + k * 0.9, 0), Vector3.ZERO, 0.0, 0.0)
	Sway.crown(tree, 1.5, 1.1, 0.025)


func _clear_fog(i: int, silent := false) -> void:
	if i < 2:
		_gates[i].open(silent)
	var fog: Area3D = _fogs[i]
	if is_instance_valid(fog):
		_player.slow = 1.0
		fog.queue_free()


func _on_lantern(l: SmallLantern) -> void:
	var d := GameState.data
	GameState.notify("light", l.lantern_id)
	if l.lantern_id == "dag_feneri":
		Pus.fade_to(self, 0.4, 2.0)
		GameState.bark("c4_fener")
	elif l.lantern_id == "kamp_atesi":
		var i := int(String(l.name).trim_prefix("KampAtesi"))
		_clear_fog(i)
		Pus.fade_to(self, maxf(Pus.amount - 0.06, 0.2), 1.0)
		GameState.bark("c4_ates")
		_open_lake_if_ready()
	SaveGame.write(d)


func _on_flags() -> void:
	for i in [1, 2, 3]:
		var n := get_node_or_null("Level/Uykucu%d" % i)
		if n and GameState.data.has_flag("uykulu_yavru%d" % i) and not n.has_meta("leaving"):
			n.set_meta("leaving", true)
			var tw := n.create_tween()
			tw.tween_interval(0.6)
			tw.tween_property(n, "scale", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw.tween_callback(n.queue_free)
	var d := GameState.data
	if d.quest_state("uykulu_yavrular") == "ready":
		d.complete_quest(Content.quests["uykulu_yavrular"])
		d.set_flag("c4_yavrular")
		GameState.bark("c4_yavrular")


# --- boss --------------------------------------------------------------------

func _start_boss() -> void:
	var d := GameState.data
	if _boss != null or d.objective_done(QUEST, "dondurma"):
		return
	_boss = Dondurma.new()
	add_child(_boss)
	_boss.position = LAKE + Vector3(0, 0, 2.5)
	_boss.hp_changed.connect(func(h: int, m: int) -> void: _hud.set_boss_hp(h, m))
	_boss.defeated.connect(_on_golem_awake)
	boss_camera(true, LAKE + Vector3(0, 3, 4), 0.5, 24.0)
	if DevTools.demo == "":
		GameState.bark("c4_dondurma_basla")
		await GameState.dialogue_closed
	_hud.show_boss("Buz Golem Dondurma", _boss.hp, GolemPlan.MAX_HP)
	_hud.show_hint("Nefesinden kaç, halkada zıpla, yumruklar saplanınca vur!", "Yumruklar saplanınca vur!")
	_boss.start()


func _on_golem_awake() -> void:
	_hud.hide_boss()
	GameState.notify("defeat", "dondurma")
	await get_tree().create_timer(0.8).timeout
	_hud.show_scene_card("", "Dondurma uyandı!", "Meğer sadece bir sarılma istiyormuş")
	await get_tree().create_timer(3.2).timeout
	GameState.bark("c4_dondurma_son")
	await GameState.dialogue_closed
	await fly_spark(_boss.global_position + Vector3.UP * 6.0, "spark-white")
	var d := GameState.data
	d.add_spark("white")
	$Level/KivilcimFeneri.light_up()
	boss_camera(false)
	_melt(false)
	_hud.show_scene_card("Kıvılcım bulundu!", "Beyaz Kıvılcım", "Uyku Dağı uyandı")
	await get_tree().create_timer(3.4).timeout
	if d.quest_state(QUEST) == "ready":
		d.complete_quest(Content.quests[QUEST])
	d.set_flag("bolum4_bitti")
	SaveGame.write(d)
	GameState.bark("c4_eriyor")
	await GameState.dialogue_closed
	_hud.show_hint("Köye dön: Pus Kalesi'nin yolu açıldı", "")


## The mountain thaws: warmer light, the Pus lifts, flowers on the snow.
func _melt(instant: bool) -> void:
	var t := 0.01 if instant else 3.0
	Pus.fade_to(self, 0.05, t)
	var tw := create_tween().set_parallel()
	tw.tween_property(_env, "background_color", Color("#bfe3ff"), t)
	tw.tween_property(_env, "ambient_light_color", Color("#fff2dc"), t)
	# the sky warms up too: bluer top, golden horizon, more sun
	var sky := WorldLook.sky_material(_env)
	if sky:
		tw.tween_property(sky, "shader_parameter/top_color", Color("#6fb2f0"), t)
		tw.tween_property(sky, "shader_parameter/horizon_color", Color("#fff1d6"), t)
		tw.tween_property(sky, "shader_parameter/cloud_amount", 0.3, t)
	if not instant:
		for i in 14:
			var at := Vector3(randf_range(-10, 10), 9.05, randf_range(-90, -40))
			var fl := Toon.part($Level, "sphere", Vector3(0.3, 0.2, 0.3), ["berry", "spark-yellow", "sky"][i % 3], at, Vector3.ZERO, 0.3, 0.02)
			fl.scale = Vector3.ZERO
			var ft := fl.create_tween()
			ft.tween_interval(randf() * 2.0)
			ft.tween_property(fl, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK)


# --- side content ------------------------------------------------------------

func _side_content(lv: Node3D) -> void:
	var d := GameState.data
	var kids := [Vector3(10, 0, 36), Vector3(-10, 3, -12), Vector3(9, 6, -36)]
	for i in 3:
		if d.has_flag("uykulu_yavru%d" % (i + 1)):
			continue
		var n := npc(lv, "uykulu_yavru%d" % (i + 1), "bunny_sleepy", kids[i], 0)
		n.name = "Uykucu%d" % (i + 1)
	for spec in [[7, Vector3(-9, 3, 7)], [8, Vector3(9, 9, -56)]]:
		var st := StoryStone.new()
		st.stone = spec[0]
		st.position = spec[1]
		lv.add_child(st)
	var rock := MountainKit.ROCK
	# Pati: a tall icy rock on the base camp
	WorldLook.block(lv, Vector3(9, 1.15, 30), Vector3(2.2, 2.3, 2.2), rock)
	var c1 := Chest.new()
	c1.chest_id = "c4_sutun"
	c1.piril = 80
	c1.position = Vector3(9, 2.3, 30)
	lv.add_child(c1)
	# Bado: alcove on T2 behind a boulder
	var A := Vector3(-8, 6, -20)
	WorldLook.block(lv, A + Vector3(-2.3, 1.1, 0), Vector3(1.0, 2.2, 3.6), rock)
	WorldLook.block(lv, A + Vector3(2.3, 1.1, 0), Vector3(1.0, 2.2, 3.6), rock)
	WorldLook.block(lv, A + Vector3(0, 1.1, -2.0), Vector3(5.6, 2.2, 1.0), rock)
	var boulder := WorldLook.block(lv, A + Vector3(0, 1.1, 2.1), Vector3(3.6, 2.2, 1.4), MountainKit.SNOW_SHADE)
	var c2 := Chest.new()
	c2.chest_id = "c4_kaya"
	c2.piril = 80
	c2.position = A
	lv.add_child(c2)
	var s1 := AbilitySpot.new()
	s1.keeper = "bado"
	s1.spot_id = "c4_kaya"
	s1.blocker = boulder
	s1.push = Vector3(3.8, 0, 0)
	s1.position = A + Vector3(0, 0, 4.0)
	lv.add_child(s1)
	# Çıtır: a crevasse in T2's east corner (clear of the ramps), rope bridge
	var B := Vector3(9, 6, -30)
	var cut := StaticBody3D.new()
	var cc := CollisionShape3D.new()
	var cb := BoxShape3D.new()
	cb.size = Vector3(6.0, 4.0, 2.0)
	cc.shape = cb
	cc.position.y = 2.0
	cut.add_child(cc)
	lv.add_child(cut)
	cut.position = B + Vector3(0, 0, -2.0)
	Toon.part(lv, "box", Vector3(6.0, 0.08, 2.0), Color("#3d4a6e"), B + Vector3(0, 0.05, -2.0), Vector3.ZERO, 0.0, 0.0)
	MountainKit.wall(lv, B + Vector3(-3.0, 0, -3.0), B + Vector3(-3.0, 0, -8.0))
	MountainKit.wall(lv, B + Vector3(-3.0, 0, -8.0), B + Vector3(3.0, 0, -8.0))
	var bridge := Node3D.new()
	bridge.position = B + Vector3(0, 0, -2.0)
	lv.add_child(bridge)
	var planks := Node3D.new()
	planks.visible = false
	bridge.add_child(planks)
	for i in 4:
		Toon.part(planks, "box", Vector3(1.8, 0.12, 0.42), Color("#c98d5e"), Vector3(0, 0.14, -0.75 + i * 0.5), Vector3.ZERO, 0.0, 0.02)
	var gap := StaticBody3D.new()
	var gc := CollisionShape3D.new()
	var gb := BoxShape3D.new()
	gb.size = Vector3(2.0, 4.0, 2.0)
	gc.shape = gb
	gc.position.y = 2.0
	gap.add_child(gc)
	bridge.add_child(gap)
	# the crevasse collider leaves room for the bridge: split it
	cut.queue_free()
	for seg in [[-2.0, 2.0], [2.0, 2.0]]:
		var w := StaticBody3D.new()
		var wc := CollisionShape3D.new()
		var wb := BoxShape3D.new()
		wb.size = Vector3(seg[1], 4.0, 2.0)
		wc.shape = wb
		wc.position.y = 2.0
		w.add_child(wc)
		lv.add_child(w)
		w.position = B + Vector3(seg[0], 0, -2.0)
	var c3 := Chest.new()
	c3.chest_id = "c4_yarik"
	c3.piril = 80
	c3.position = B + Vector3(0, 0, -5.5)
	lv.add_child(c3)
	var s2 := AbilitySpot.new()
	s2.keeper = "citir"
	s2.spot_id = "c4_yarik"
	s2.blocker = bridge
	s2.position = B + Vector3(1.6, 0, 0.6)
	lv.add_child(s2)
	# Lumi: a dark ice cave on the summit
	var C := Vector3(-8.5, 9, -42)
	WorldLook.block(lv, C + Vector3(0, 1.1, -2.5), Vector3(4.0, 2.2, 1.0), rock)
	WorldLook.block(lv, C + Vector3(0, 1.1, 2.5), Vector3(4.0, 2.2, 1.0), rock)
	var dark := StaticBody3D.new()
	var dc := CollisionShape3D.new()
	var db := BoxShape3D.new()
	db.size = Vector3(1.4, 4.0, 4.4)
	dc.shape = db
	dc.position.y = 2.0
	dark.add_child(dc)
	lv.add_child(dark)
	dark.position = C + Vector3(2.2, 0, 0)
	for i in 4:
		Toon.part(dark, "sphere", Vector3(1.6, 1.6, 1.6), Color("#2b2f52"), Vector3(0, 0.8 + (i % 2) * 0.5, -1.6 + i * 1.1), Vector3.ZERO, 0.0, 0.03)
	var c4 := Chest.new()
	c4.chest_id = "c4_magara"
	c4.piril = 80
	c4.position = C + Vector3(-0.8, 0, 0)
	c4.rotation_degrees.y = 90
	lv.add_child(c4)
	var s3 := AbilitySpot.new()
	s3.keeper = "lumi"
	s3.spot_id = "c4_magara"
	s3.blocker = dark
	s3.position = C + Vector3(4.0, 0, 0)
	lv.add_child(s3)


func _run_demo(which: String) -> void:
	var d := GameState.data
	match which:
		"start":
			pass
		"climb":
			for m in get_tree().get_nodes_in_group("mob"):
				m.queue_free()
			var route := [
				["walk", Vector3(-3, 0, 35.8)], ["use", null],
				["walk", Vector3(0, 0, 37)], ["walk", Vector3(0, 0, 19)], ["walk", Vector3(0, 3, 9)], ["walk", Vector3(-6, 3, 5.8)], ["use", null],
				["walk", Vector3(6, 3, 2)], ["walk", Vector3(6, 3, -3)], ["walk", Vector3(6, 6, -15)], ["walk", Vector3(4, 6, -18.2)], ["use", null],
				["walk", Vector3(-6, 6, -22)], ["walk", Vector3(-6, 6, -28)], ["walk", Vector3(-6, 9, -39)], ["walk", Vector3(6, 9, -44.2)], ["use", null],
				["walk", Vector3(-4, 9, -46)], ["use", null],
				["walk", Vector3(0, 9, -58)], ["walk", Vector3(0, 9, -63)]]
			for step: Array in route:
				await close_dialogs()
				if step[0] == "walk":
					await walk_to(step[1], 8.0)
				else:
					_player.interact()
					await get_tree().create_timer(0.4).timeout
				print("  step %s -> pos=%s" % [step[0], _player.global_position.round()])
			await close_dialogs()
			print("CLIMB pos=%s fener=%s ates=%s kuzey=%s lake_open=%s boss=%s hp=%d" % [_player.global_position.round(),
				d.objective_done(QUEST, "fener"), d.objective_count(QUEST, "ates"), d.objective_done(QUEST, "kuzey"), _gates[2].is_open, _boss != null, d.hp])
			get_tree().quit()
		"camp":
			GameState.notify("light", "dag_feneri")
			$Level/DagFeneri.light_up(true)
			_player.global_position = Vector3(1, 0, 30)
			await close_dialogs()
		"fog":
			GameState.notify("light", "dag_feneri")
			$Level/DagFeneri.light_up(true)
			for m in get_tree().get_nodes_in_group("mob"):
				m.queue_free()
			_player.global_position = Vector3(3, 3.1, 1)
			await close_dialogs()
		"kuzey":
			GameState.notify("light", "dag_feneri")
			_player.global_position = Vector3(-3.2, 9.1, -46.2)
			await close_dialogs()
			_player.interact()
			await get_tree().create_timer(4.2).timeout
			for i in 4:
				_hud._dialog.advance()
				_hud._dialog.advance()
				await get_tree().create_timer(0.1).timeout
		"ramp":
			for m in get_tree().get_nodes_in_group("mob"):
				m.queue_free()
			_player.global_position = Vector3(0, 0.1, 21)
			await get_tree().create_timer(0.3).timeout
			Input.action_press("move_forward")
			for i in 30:
				await get_tree().create_timer(0.1).timeout
				if i % 3 == 0:
					print("RAMP t=%.1f pos=(%.2f, %.2f, %.2f) floor=%s" % [i * 0.1, _player.global_position.x, _player.global_position.y, _player.global_position.z, _player.is_on_floor()])
			Input.action_release("move_forward")
			get_tree().quit()
		"ice":
			for m in get_tree().get_nodes_in_group("mob"):
				m.queue_free()
			_player.global_position = Vector3(-8, 3.1, -3.5)
			await get_tree().create_timer(0.3).timeout
			Input.action_press("move_right")
			await get_tree().create_timer(0.8).timeout
			Input.action_release("move_right")
			var x0 := _player.global_position.x
			await get_tree().create_timer(0.6).timeout
			var ice_slide := _player.global_position.x - x0
			_player.global_position = Vector3(-2, 3.1, 4)
			await get_tree().create_timer(0.3).timeout
			Input.action_press("move_right")
			await get_tree().create_timer(0.8).timeout
			Input.action_release("move_right")
			x0 = _player.global_position.x
			await get_tree().create_timer(0.6).timeout
			print("ICE slide_after_release ice=%.2f m snow=%.2f m" % [ice_slide, _player.global_position.x - x0])
			get_tree().quit()
		"boss", "bossfight":
			for o in ["fener", "ates", "kuzey"]:
				d.complete_objective(QUEST, o)
			_restore_progress()
			await close_dialogs()
			_player.global_position = Vector3(0, 9.2, -63)
			if which == "boss":
				return
			while _boss == null or not _boss.active:
				await get_tree().process_frame
			var t := 0.0
			while _boss.active and t < 240.0:
				if _boss.open:
					_player.global_position = _boss.global_position + Vector3(0, 0.2, 3.0)
					_player._attack_cd = 0.0
					_player.spin_attack()
				await get_tree().create_timer(0.1).timeout
				t += 0.1
				if _hud._dialog.is_open():
					_hud._dialog.advance()
			print("GOLEM hp=%d active=%s phase=%d t=%.1f player_hp=%d" % [_boss.hp, _boss.active, _boss.phase, t, d.hp])
			for i in 200:
				if _hud._dialog.is_open():
					_hud._dialog.advance()
					_hud._dialog.advance()
				await get_tree().create_timer(0.1).timeout
			print("GOLEM2 quest=%s sparks=%s flag=%s exit=%s" % [d.quest_state(QUEST), d.sparks, d.has_flag("bolum4_bitti"), ($Level/ExitSign as Node3D).visible])
			get_tree().quit()
		"spots":
			var me := d.character_id
			for m in get_tree().get_nodes_in_group("mob"):
				m.queue_free()
			var A := Vector3(-8, 6, -20)
			var B := Vector3(9, 6, -30)
			var C := Vector3(-8.5, 9, -42)
			var start: Vector3 = {"bado": A + Vector3(0, 0, 6), "citir": B + Vector3(0, 0, 2), "lumi": C + Vector3(5, 0, 0), "pati": Vector3(9, 0, 32.4)}[me]
			var spot: Vector3 = {"bado": A + Vector3(0, 0, 4.0), "citir": B + Vector3(1.6, 0, 0.6), "lumi": C + Vector3(4.0, 0, 0), "pati": start}[me]
			var chest: Vector3 = {"bado": A, "citir": B + Vector3(0, 0, -5.5), "lumi": C + Vector3(-0.8, 0, 0), "pati": Vector3(9, 2.3, 30)}[me]
			_player.global_position = start + Vector3.UP * 0.1
			await get_tree().create_timer(0.3).timeout
			if me != "pati":
				await walk_to(chest, 2.5)
				var blocked := _player.global_position.distance_to(chest) > 1.6
				_player.global_position = spot + Vector3.UP * 0.1
				await get_tree().create_timer(0.3).timeout
				_player.interact()
				await get_tree().create_timer(1.2).timeout
				await close_dialogs()
				if me == "citir":
					_player.global_position = B + Vector3(0, 0.1, 0.8)
				await walk_to(chest, 4.0)
				print("SPOT %s blocked_before=%s reached=%s" % [me, blocked, _player.global_position.distance_to(chest) < 1.6])
			else:
				Input.action_press("move_forward")
				Input.action_press("jump")
				await get_tree().physics_frame
				Input.action_release("jump")
				await get_tree().create_timer(0.3).timeout
				Input.action_press("jump")
				await get_tree().physics_frame
				Input.action_release("jump")
				for i in 30:
					await get_tree().physics_frame
					if _player.global_position.z < 30.6 and _player.global_position.y > 2.0:
						break
				Input.action_release("move_forward")
				await get_tree().create_timer(0.5).timeout
				print("SPOT pati reached=%s y=%.2f" % [_player.global_position.distance_to(chest) < 1.6, _player.global_position.y])
			get_tree().quit()
