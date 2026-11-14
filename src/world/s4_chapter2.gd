extends S4Garden
## Sezon 4 · Bölüm 2 – Şarkı Çayırı (Papatya Tohumu). The meadow's concert
## has gone quiet: Cırcır's chirping drowned every singer out. Bülbül Nihan
## (quest giver, stall) asks for the concert back (quest "cayirin_konseri"):
## keep a steady beat beside the three hushed singers (`SongStage`: four even
## strikes, event "ritim"/"sarkici"), clap for each singing one (their stage's
## thorn hedge draws back, event "clap"/"sarkici"), calm four Dikenciler and
## plant the bridge seed over the brook. Then the ark sluice opens
## ("circirin_ritmi"): the hedge of the big stage dries, Cırcır fights on the
## beat (thunder rows and rings), sulks, one clap, and then Nihan and Cırcır
## play TOGETHER (`_duet`: she sings, he keeps the rhythm) and the Papatya
## Tohumu drops. Nihan sends you on to Yuva Ağacı (`s4_bolum2_bitti`).
##
## Layout (the camera looks from the south, +z): gate at z 34, spawn z 29.5,
## Nihan and her stall at z 26, stage 1 (frog) at z 18 with hedge A at z 13,
## stage 2 (duckling) at z 6 with hedge B at z 1.5, the brook at z -4 (bridge
## plot at x 0), a ramp up to the upper meadow (top 1.2) at z -7..-11, stage 3
## (bunny) at z -16 with hedge C at z -20.5, the ark at z -23.5, the ark
## hedge D at z -27, Cırcır's big stage at z -34. Yonca's corner: a ledge in
## the east (x 15..21, z 15..22) with Pırıl, her ladder from z 26.

const Q1 := "cayirin_konseri"
const Q2 := "circirin_ritmi"
const GRASS := Color("#9bd67a")
const UPPER := Color("#a9dd84")
const PATH := Color("#ecd9a6")
const UP := 1.2
const ARENA := Vector3(0, UP, -34.0)
const NIHAN_AT := Vector3(3.5, 0, 26.0)
const DUET_AT := Vector3(2.8, 0, 1.2)
## [npc id, villager kind, stage position, hedge z, color token]: hedges are
## thorn patches 0..2 (flags s4_chapter2_d0..2), songs s4c2_sarki0..2
const SINGERS := [["sarki_kurbaga", "frog", Vector3(-8, 0, 18), 13.0, "spark-green"],
	["sarki_ordek", "duckling", Vector3(8, 0, 6), 1.5, "spark-yellow"],
	["sarki_tavsan", "bunny", Vector3(-8, UP, -16), -20.5, "berry"]]
const DIKENCILER := [["bagiran_kurbaga", Vector3(5, 0, 20)], ["susturucu_sinek", Vector3(-5, 0, 9)],
	["bagiran_kurbaga", Vector3(-9, 0, 5)], ["susturucu_sinek", Vector3(3, 0, 8)]]

var _stages: Array[SongStage] = []
var _hedge: ThornPatch
var _brook_block: StaticBody3D
var _bridge: SeedPlot
var _corner: SeedPlot
var _mobs := false


func _ready() -> void:
	begin_garden("s4_chapter2")
	var d := GameState.data
	ark_flag = "s4_ark2"
	haze(0.3)
	_build()
	Decor.auto(self, "koy")
	npc(self, "nihan", "nihan", NIHAN_AT, -150.0).name = "Nihan"
	make_boss("circir", ARENA, d.objective_done(Q2, "circir"))
	if d.objective_done(Q2, "circir") and d.quest_state(Q2) != "done":
		giver_comes("Nihan", ARENA + DUET_AT, false)
		drop_seed("papatya", ARENA + Vector3(0, 0, 4.5), "Papatya Tohumu", "Birlikte çalınan şarkıdan açtı.")
	_spawn_mobs()
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	_refresh()
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.8, false).timeout
	if not d.has_flag("s4c2_geldi"):
		d.set_flag("s4c2_geldi")
		GameState.bark("s4k2_basla")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _build() -> void:
	land(Vector3(0, 0, 13.75), Vector2(46, 50.5), GRASS)
	land(Vector3(0, 0, -27.0), Vector2(46, 31.6), UPPER, UP)
	fence(Vector3(0, 0, -2.5), Vector2(44, 79))
	gate(Vector3(0, 0, 34.0))
	# the path up the middle and the ramp to the upper meadow
	WorldLook.block(lv, Vector3(0, 0.02, 12.0), Vector3(3.2, 0.04, 42), PATH, 0.0)
	WorldLook.block(lv, Vector3(0, UP + 0.02, -20.0), Vector3(3.2, 0.04, 17), PATH, 0.0)
	MountainKit.ramp(lv, 0.0, 6.0, -7.0, 0.0, -11.3, UP, PATH)
	# the three stages; each one's hedge (thorn patches 0..2) lies across the
	# way north of it and opens with a clap for its singer
	for i in SINGERS.size():
		var s: Array = SINGERS[i]
		var at: Vector3 = s[2]
		var hedge := thorns(Vector3(0, at.y, float(s[3])), 44.0, true)
		var st := SongStage.new()
		st.name = "Stage%d" % i
		st.sung_flag = "s4c2_sarki%d" % i
		st.color = Tokens.color(s[4])
		st.patch = hedge
		st.position = at
		lv.add_child(st)
		_stages.append(st)
		var who := npc(self, s[0], s[1], at + Vector3(0, 0.25, 0), -signf(at.x) * 35.0)
		who.name = "Singer%d" % i
		st.singer = who
		if st.is_sung:
			st._set_sung()
		st.sang.connect(func(_s: SongStage) -> void:
			if not GameState.data.has_flag("s4c2_ilk_sarki"):
				GameState.data.set_flag("s4c2_ilk_sarki")
				GameState.bark("s4k2_sarki"))
		st.cheered.connect(func(_s: SongStage) -> void:
			if not GameState.data.has_flag("s4c2_ilk_alkis"):
				GameState.data.set_flag("s4c2_ilk_alkis")
				GameState.bark("s4k2_alkis"))
		WorldLook.block(lv, Vector3(at.x * 0.5, at.y + 0.02, at.z), Vector3(absf(at.x), 0.04, 2.0), PATH, 0.0)
		prop("papatya", at + Vector3(-2.6, 0, -1.6), 1.3, 0.4 * i)
		prop("papatya", at + Vector3(2.7, 0, -1.2), 1.0, 1.1 * i)
	# Nihan's stall by the gate
	prop("pazar_tezgahi", NIHAN_AT + Vector3(4.0, 0, 0.5), 3.0, -PI * 0.5)
	for x: float in [-6.0, 6.0]:
		prop("saksi", Vector3(x, 0, 31.5), 0.8, 0.0)
	# the brook: water right across, passable only by the leaf bridge
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(44, 3.0)
	water.mesh = pm
	water.position = Vector3(0, 0.07, -4.0)
	WorldLook.water(water, "lake")
	lv.add_child(water)
	for x: float in [-12.0, 12.0]:
		_wall(Vector3(x, 0, -4.0), Vector2(21.0, 2.6))
	_brook_block = _wall(Vector3(0, 0, -4.0), Vector2(3.0, 2.6))
	_bridge = plot(Vector3(0, 0, -1.6), "kopru", Vector3(0, 0, -4.8))
	_bridge.grown.connect(func(_p: SeedPlot) -> void:
		_open_brook()
		GameState.bark("s4k2_tohum_kopru"))
	if _bridge.is_grown:
		_open_brook()
	# Yonca's corner: a tall ledge in the east, a ladder only she can sprout
	land(Vector3(18, 0, 18.5), Vector2(6, 7), UPPER, 2.4)
	_corner = plot(Vector3(18, 0, 26.0), "merdiven", Vector3(0, 2.4, -4.4), true)
	_corner.grown.connect(func(_p: SeedPlot) -> void: _ladder_ramp())
	if _corner.is_grown:
		_ladder_ramp()
	for k in 5:
		var pk := Pickup.new()
		pk.amount = 3
		lv.add_child(pk)
		pk.position = Vector3(16.6 + (k % 3) * 1.4, 2.4, 17.0 + (k / 3) * 2.4)
	prop("papatya", Vector3(20.0, 2.4, 16.0), 1.6, 0.6)
	# a healing daisy off the path, before the big stage
	plot(Vector3(-9, UP, -24.5), "sifa")
	# the ark sluice and the hedge of the big stage that dries when it opens
	ark(Vector3(7.0, UP, -23.5), "s4_ark2", Q1, "s4k2_kilit", PI)
	_hedge = thorns(Vector3(0, UP, -27.0), 44.0, true)
	if GameState.data.has_flag("s4_ark2") and not _hedge.is_open:
		_hedge.open()
	# loose thorn clumps beside the route (they fill the Diken barı)
	thorns(Vector3(-7.5, 0, 24.5), 4.0, false)
	thorns(Vector3(7.5, 0, 12.0), 4.0, false, false, "", 0.5)
	thorns(Vector3(-8, 0, -7.0), 4.0, false, false, "", -0.4)
	thorns(Vector3(9, UP, -14.0), 4.0, false)
	# the big stage: a round floor and daisies behind it
	Toon.part(lv, "cylinder", Vector3(13, 0.06, 13), Color("#f3e3b4"), ARENA + Vector3(0, 0.03, 0), Vector3.ZERO, 0.0, 0.0)
	for p: Vector3 in [Vector3(-9, 0, -6), Vector3(9, 0, -6), Vector3(-12, 0, -2), Vector3(12, 0, -2), Vector3(0, 0, -7.5)]:
		prop("papatya", ARENA + p, 2.2, 0.5 * p.x)
	# trees and mushrooms on the edges (never south of the path)
	for p: Vector3 in [Vector3(-19, 0, 28), Vector3(19, 0, 30), Vector3(-19.5, 0, 8), Vector3(-19, UP, -14), Vector3(19, UP, -19), Vector3(-18, UP, -38), Vector3(18, UP, -39)]:
		prop("prop_tree", p, 5.0, p.z)
	for p: Vector3 in [Vector3(-15, 0, 14.5), Vector3(14, 0, -1), Vector3(-14, UP, -12.5), Vector3(15, UP, -30)]:
		prop("orman_mantar", p, 1.1, p.x)
	prop("cicek_tarhi", Vector3(-12, 0, 28.5), 1.1, 0.3)


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


## The leaf steps alone are too steep to walk: a hidden slope under them.
func _ladder_ramp() -> void:
	var from := Vector3(18, 0, 26.6)
	var to := Vector3(18, 2.4, 21.7)
	var run := from.z - to.z
	var a := atan2(to.y - from.y, run)
	var body := StaticBody3D.new()
	body.set_meta("camera_ignore", true)
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(2.0, 0.2, Vector2(run, to.y - from.y).length())
	c.shape = b
	body.add_child(c)
	lv.add_child(body)
	body.rotation.x = a
	body.position = (from + to) * 0.5 - Vector3(0, cos(a), sin(a)) * 0.1


func _open_brook() -> void:
	if _brook_block and is_instance_valid(_brook_block):
		_brook_block.queue_free()
		_brook_block = null


## The Dikenciler come with Quest 1 (calmed before it they wouldn't count).
func _spawn_mobs() -> void:
	var d := GameState.data
	if _mobs or d.quest_state(Q1) != "active":
		return
	_mobs = true
	var done := d.objective_count(Q1, "dikenci").x
	for i in range(mini(done, DIKENCILER.size()), DIKENCILER.size()):
		dikenci(DIKENCILER[i][0], DIKENCILER[i][1])
	if not d.has_flag("s4c2_ilk_dikenci"):
		d.set_flag("s4c2_ilk_dikenci")
		GameState.bark("s4k2_dikenci")


## Stages listen only while the concert quest runs; what stays done by a flag
## (songs, opened hedges, the bridge) is counted again from the flags.
func _sync_stages() -> void:
	var d := GameState.data
	var on := d.quest_state(Q1) == "active"
	var sung := 0
	var cheered := 0
	for st in _stages:
		st.listening = on
		sung += int(st.is_sung)
		cheered += int(st.is_sung and st.patch.is_open)
	if not on:
		return
	_count(Q1, "ritim", sung)
	_count(Q1, "alkis", cheered)
	_count(Q1, "tohum", int(_bridge.is_grown))


func _count(quest: String, objective: String, have: int) -> void:
	var c := GameState.data.objective_count(quest, objective)
	if have > c.x and c.x < c.y:
		GameState.data.advance_objective(quest, objective, mini(have, c.y) - c.x)


func _on_ark() -> void:
	_hedge.open()
	GameState.bark("s4k2_ark")
	_refresh()


func fight_ready() -> bool:
	var d := GameState.data
	return d.quest_state(Q2) == "active" and d.has_flag("s4_ark2") and not d.objective_done(Q2, "circir")


func _begin_fight() -> void:
	start_fight("s4k2_circir", "Vuruşlar ritimle iner: uyarıyı gör, bir say, çekil. Yorulunca vur!", "Uyarıyı gör, çekil. Yorulunca vur!")


## The clap showed him his own gift: the steadiest rhythm of the meadow. Nihan
## comes and the two play together, then the daisy's seed drops.
func _on_boss_calmed() -> void:
	_hud.clear_hint()
	GameState.bark("s4k2_sakin")
	await GameState.dialogue_closed
	await giver_comes("Nihan", boss.global_position + DUET_AT)
	var n := get_node_or_null("Nihan") as Node3D
	if n and n.has_node("Beacon"):
		n.get_node("Beacon").queue_free()
	GameState.bark("s4k2_duet_once")
	await GameState.dialogue_closed
	await _duet()
	GameState.bark("s4k2_duet")
	await GameState.dialogue_closed
	boss_camera(false)
	drop_seed("papatya", boss.global_position + Vector3(0, 0, 4.5), "Papatya Tohumu", "Birlikte çalınan şarkıdan açtı.")
	_refresh()


## She sings the melody, he keeps the rhythm: eight steady beats.
func _duet() -> void:
	var n := get_node_or_null("Nihan") as Node3D
	var gold := Tokens.color("spark-yellow")
	var pink := Tokens.color("berry")
	for i in 8:
		Audio.play("drum")
		var bt := boss.create_tween()
		bt.tween_property(boss, "scale", Vector3(1.1, 0.88, 1.1), 0.1).set_trans(Tween.TRANS_SINE)
		bt.tween_property(boss, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK)
		Effects.ring(self, boss.global_position + Vector3.UP * 0.15, 2.2 + 0.3 * (i % 2), gold, 0.35)
		if n:
			var nt := n.create_tween()
			nt.tween_interval(0.25)
			nt.tween_property(n, "scale", Vector3(0.94, 1.1, 0.94), 0.12).set_trans(Tween.TRANS_SINE)
			nt.tween_property(n, "scale", Vector3.ONE, 0.12)
			SongStage.note(self, n.global_position + Vector3(randf_range(-0.5, 0.5), 2.0, 0.3), pink)
		if i % 2 == 1:
			Effects.sparkle(self, boss.global_position + Vector3(randf_range(-2.5, 2.5), 2.6, randf_range(-1.0, 1.0)), gold if i % 4 == 1 else pink, 8)
		await get_tree().create_timer(0.5, false).timeout
	Audio.play("fanfare")
	Effects.ring(self, boss.global_position + Vector3.UP * 0.2, 6.0, Tokens.color("spark-white"), 0.7)
	for k in 6:
		SongStage.note(self, boss.global_position + Vector3(randf_range(-3, 3), 1.6, randf_range(-1, 2)), gold if k % 2 == 0 else pink)
	await get_tree().create_timer(0.8, false).timeout


func _on_seed(_id: String) -> void:
	GameState.bark("s4k2_tohum")
	var n := get_node_or_null("Nihan") as Node3D
	if n and not n.has_node("Beacon"):
		Beacon.attach(n, 2.8, Tokens.color("spark-white"))
	_refresh()


func _refresh() -> void:
	var d := GameState.data
	_spawn_mobs()
	_sync_stages()
	var t := get_node_or_null("Nihan") as Node3D
	if t == null:
		return
	var q1 := d.quest_state(Q1)
	var q2 := d.quest_state(Q2)
	var go := q1 in ["none", "ready"] or q2 == "ready"
	if go and not t.has_node("Beacon"):
		Beacon.attach(t, 2.6, Tokens.color("spark-white"))
	elif not go and t.has_node("Beacon") and q2 != "active":
		t.get_node("Beacon").queue_free()
	if q1 == "none":
		_hud.show_hint("Kapının yanındaki Bülbül Nihan ile konuş", "Bülbül Nihan ile konuş")
	elif q1 == "active":
		if not d.objective_done(Q1, "ritim") or not d.objective_done(Q1, "alkis"):
			_hud.show_hint("Şarkıcının yanında dört düzenli vuruş yap (J). Şarkı gelince C: alkışla!", "Şarkıcının yanında dört düzenli Vur. Sonra Alkış!")
		elif not d.objective_done(Q1, "tohum"):
			_hud.show_hint("Derenin başındaki toprağa köprü tohumu ek", "Derenin başına tohum ek")
		else:
			_hud.show_hint("Dikencileri sersemlet, sonra yanlarında alkışla", "Dikencileri sersemlet, sonra Alkış!")
	elif q1 == "ready" or q2 == "ready":
		_hud.show_hint("Bülbül Nihan ile konuş", "Bülbül Nihan ile konuş")
	elif q2 == "active" and not d.has_flag("s4_ark2"):
		_hud.show_hint("Yukarı çayıra çık, ark kapağının çarkını çevir", "Yukarı çayırda ark kapağını aç")
	elif q2 == "active" and not d.objective_done(Q2, "circir") and not fighting:
		_hud.show_hint("Kuzeydeki büyük sahneye git: Cırcır orada", "Kuzeydeki büyük sahneye git")
	elif q2 == "active" and d.objective_done(Q2, "circir") and not d.has_flag("tohum_papatya") and has_node("Seed"):
		_hud.show_hint("Sahnedeki Papatya Tohumu'nu al", "Papatya Tohumu'nu al")


## Demo: `n` strikes `gap` seconds apart beside a stage.
func _beats(n: int, gap := 0.6) -> void:
	for k in n:
		_player.spin_attack()
		await get_tree().create_timer(gap, false).timeout


func _clap() -> int:
	_player.clap._cd = 0.0
	var hits := _player.clap.clap()
	await get_tree().create_timer(0.9, false).timeout
	await close_dialogs()
	return hits


func _run_demo(which: String) -> void:
	var d := GameState.data
	match which:
		"garden":
			# the whole chapter on foot: quest, three stages (beat, clap, hedge),
			# Dikenciler, the bridge seed, the ramp, the ark, Cırcır, the duet, the
			# seed, the last talk
			DevTools.auto_dialogue = true
			# before the quest a stage does not listen
			_player.global_position = SINGERS[0][2] + Vector3(0, 0.3, 2.8)
			await _beats(5)
			print("S4K2_EARLY sung=%s" % _stages[0].is_sung)
			_player.global_position = Vector3(0, 0.3, 29.5)
			await walk_to(NIHAN_AT + Vector3(0, 0, 1.8), 6.0)
			GameState.talk_to("nihan")
			await close_dialogs()
			print("S4K2_Q1 state=%s mobs=%d listening=%s" % [d.quest_state(Q1), get_tree().get_nodes_in_group("mob").size(), _stages[0].listening])
			await _calm_dikenciler()
			await close_dialogs()
			print("S4K2_DIKENCI count=%s" % d.objective_count(Q1, "dikenci"))
			_player.global_position = Vector3(0, 0.3, 24.0)
			for i in SINGERS.size():
				var s: Array = SINGERS[i]
				var at: Vector3 = s[2]
				var hz := float(s[3])
				var st := _stages[i]
				if i == 2:
					# stage 3 is over the brook and up the ramp
					await walk_to(Vector3(0, 0, -8.0), 8.0)
					await walk_to(Vector3(0, UP, -13.0), 6.0)
					print("S4K2_RAMP y=%.2f z=%.1f up=%s" % [_player.global_position.y, _player.global_position.z, _player.global_position.y > UP - 0.2])
				# the hedge is a wall until the singer is applauded
				await walk_to(Vector3(0, at.y, hz + 3.0), 8.0)
				await walk_to(Vector3(0, at.y, hz - 3.0), 2.0)
				var blocked := _player.global_position.z > hz
				await walk_to(Vector3(0, at.y, at.z + 2.0), 6.0)
				await walk_to(at + Vector3(0, 0, 2.8), 8.0)
				# a clap before the song opens nothing
				var early := await _clap()
				var closed := not st.patch.is_open
				# a hurried rattle is not a rhythm
				await _beats(5, 0.12)
				var rattle := st.is_sung
				await get_tree().create_timer(1.3, false).timeout
				await _beats(5)
				await close_dialogs()
				var sung := st.is_sung
				var hits := await _clap()
				print("S4K2_STAGE %d blocked=%s early_clap=%d closed=%s rattle=%s sung=%s clap=%d open=%s ritim=%s alkis=%s" % [i, blocked, early, closed, rattle, sung, hits, st.patch.is_open, d.objective_count(Q1, "ritim"), d.objective_count(Q1, "alkis")])
				await walk_to(Vector3(0, at.y, at.z + 2.0), 6.0)
				await walk_to(Vector3(0, at.y, hz - 2.5), 8.0)
				print("S4K2_HEDGE %d passed=%s z=%.1f" % [i, _player.global_position.z < hz - 1.0, _player.global_position.z])
				if i == 1:
					# the brook: blocked, then the bridge seed
					await walk_to(Vector3(0, 0, -6.5), 2.5)
					print("S4K2_BROOK blocked=%s z=%.1f" % [_player.global_position.z > -3.0, _player.global_position.z])
					await walk_to(Vector3(0, 0, -0.5), 4.0)
					await get_tree().create_timer(0.3, false).timeout
					_player.interact()
					for k in 60:
						if _bridge.is_grown:
							break
						await get_tree().create_timer(0.25, false).timeout
					await close_dialogs()
					print("S4K2_GROW grown=%s tohum=%s" % [_bridge.is_grown, d.objective_done(Q1, "tohum")])
			print("S4K2_Q1DONE q1=%s" % d.quest_state(Q1))
			# the concert is back: the ark turns already (its event is counted
			# again when Nihan's second quest starts)
			await walk_to(Vector3(7.0, UP, -21.7), 6.0)
			await get_tree().create_timer(0.3, false).timeout
			_player.interact()
			await get_tree().create_timer(0.8, false).timeout
			await close_dialogs()
			print("S4K2_ARKFIRST ark=%s hedge_open=%s" % [d.has_flag("s4_ark2"), _hedge.is_open])
			await _talk("nihan", "Nihan")
			print("S4K2_Q2 q1=%s q2=%s" % [d.quest_state(Q1), d.quest_state(Q2)])
			_player.global_position = Vector3(0, UP + 0.3, -22.0)
			await walk_to(Vector3(7.0, UP, -21.7), 6.0)
			await get_tree().create_timer(0.3, false).timeout
			_player.interact()
			await get_tree().create_timer(1.0, false).timeout
			await close_dialogs()
			print("S4K2_ARK ark=%s hedge_open=%s" % [d.has_flag("s4_ark2"), _hedge.is_open])
			await walk_to(Vector3(0, UP, -24.0), 6.0)
			await close_dialogs()
			# the fight (and its first bark) starts 10 m from the arena, still
			# south of the dried hedge; the walk to the seed later crosses it
			await walk_to(ARENA + Vector3(0, 0, 5.0), 8.0)
			print("S4K2_BIGSTAGE fight=%s z=%.1f" % [fighting or GameState.in_dialogue, _player.global_position.z])
			await _beat_boss()
			for k in 80:
				await close_dialogs()
				if has_node("Seed") or d.has_flag("tohum_papatya"):
					break
				await get_tree().create_timer(0.5, false).timeout
			var nihan := get_node("Nihan") as Node3D
			print("S4K2_DUET circir=%s seed=%s nihan_near=%s" % [d.objective_done(Q2, "circir"), has_node("Seed"), nihan.global_position.distance_to(boss.global_position) < 4.0])
			await walk_to(boss.global_position + Vector3(0, 0, 4.5), 8.0)
			await get_tree().create_timer(1.0, false).timeout
			await close_dialogs()
			print("S4K2_SEED tohum=%s q2=%s past_hedge=%s" % [d.has_flag("tohum_papatya"), d.quest_state(Q2), _player.global_position.z < -27.5])
			await _talk("nihan", "Nihan")
			await get_tree().create_timer(3.5, false).timeout
			print("S4K2_DONE q2=%s ark=%s tohum=%s bitti=%s gate_star=%s" % [d.quest_state(Q2) == "done", d.has_flag("s4_ark2"), d.has_flag("tohum_papatya"), d.has_flag("s4_bolum2_bitti"), lv.get_node("Gate").has_node("Beacon")])
			get_tree().quit()
		"corner":
			# Yonca's corner: the plot answers only her (run with and without
			# --keeper=yonca)
			DevTools.auto_dialogue = true
			_player.global_position = Vector3(14.0, 0.3, 28.5)
			await walk_to(Vector3(18, 0, 27.3), 5.0)
			await get_tree().create_timer(0.3, false).timeout
			_player.interact()
			for k in 40:
				if _corner.is_grown:
					break
				await get_tree().create_timer(0.25, false).timeout
			var before := d.piril
			await walk_to(Vector3(18, 2.4, 19.5), 6.0)
			await get_tree().create_timer(0.5, false).timeout
			print("S4K2_CORNER keeper=%s grown=%s y=%.2f on_ledge=%s piril=+%d" % [d.character_id, _corner.is_grown, _player.global_position.y, _player.global_position.y > 2.0, d.piril - before])
			get_tree().quit()
