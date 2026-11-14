extends S4Garden
## Sezon 4 · Bölüm 1 – Parlak Pazar, Lale Tohumu (levels 5–10). A market of
## stalls and flags where everybody wants the neighbour's toy and nobody
## plays with their own. Kapkaç Kargalar have grabbed the three stall
## owners' shiny toys (`ShinyToy`): calm a crow, pick the toy up, take it
## back to the RIGHT owner (the neighbour only sighs for it), then clap for
## the owner's OWN toy in front of the stall: the thorns over it draw back
## (a clap for an empty stall does nothing). Çiçekçi Arı Vızık asks for all
## three and for a ladder seed up the terrace (quest "pazar_parlasin").
## Then the ark sluice ("sikirin_yuvasi"): the hedge on the terrace dries and
## Saksağan Şıkır waits in her nest full of shiny things: fight, she sulks,
## a clap, the question "Bunlardan hangisi en sevdiğin?" (she can't say),
## her own first bead at the bottom of the nest, the Lale Tohumu. Calm for
## good she keeps a swap stall (`s4_bolum1_bitti`).
##
## Layout (the camera looks from the south, +z): gate at z 27, spawn z 23,
## Vızık and her stall at z 18, the market square with the three stalls at
## z 10 (west), 2 (east) and -3 (west); Yonca's ladder to a Pırıl platform
## in the east at z 13–19. The terrace (1.6 m up) starts at z -9: the ladder
## plot at x 0, z -5.2 is the only way up. On it: the ark at z -13.5, the
## thorn hedge at z -19, Şıkır's nest arena at z -31.

const Q1 := "pazar_parlasin"
const Q2 := "sikirin_yuvasi"
const GRASS := Color("#8fcf7a")
const TERRACE := Color("#a5d488")
const PATH := Color("#e6d3a8")
const TOP := 1.6
const ARENA := Vector3(0, TOP, -31.0)
const VIZIK_AT := Vector3(4.0, 0, 18.5)
const LADDER_AT := Vector3(0, 0, -5.2)
const ARK_AT := Vector3(7.0, TOP, -13.5)
const PLATFORM := Vector3(18.0, 2.6, 13.0)
## [owner id, model kind, stall position, own toy]: the thorns over the
## stalls are thorn patches 0..2 (flags s4_chapter1_d0..2, read by dialogue)
const STALLS := [["ponpon", "bunny", Vector3(-12, 0, 10), "zil"], ["tombis", "turtle", Vector3(12, 0, 2), "bilye"],
	["virak", "frog", Vector3(-12, 0, -3), "firildak"]]
## the crow that took toy i waits here
const CROWS := [Vector3(5, 0, 10), Vector3(-5, 0, 3), Vector3(6, 0, -4)]
const MICE := [Vector3(-6, 0, -6), Vector3(15, 0, -5)]
const FLAGS := [Color("#f08ac0"), Color("#ffd24a"), Color("#7fd0ff"), Color("#8fd06a"), Color("#ff9a5a")]

var _hedge: ThornPatch
var _stall_thorns: Array[ThornPatch] = []
var _stall_toys: Array[Node3D] = [null, null, null]
var _lip_block: StaticBody3D
var _ladder: SeedPlot
var _mobs := false
var _crows := {}


func _ready() -> void:
	begin_garden("s4_chapter1")
	var d := GameState.data
	ark_flag = "s4_ark1"
	haze(0.3)
	_build()
	Decor.auto(self, "koy")
	npc(self, "vizik", "vizik", VIZIK_AT, -150.0).name = "Vizik"
	for s: Array in STALLS:
		var at: Vector3 = s[2]
		var side := signf(at.x)
		npc(self, s[0], s[1], at + Vector3(-side * 4.6, 0, 1.6), 90.0 * side).name = String(s[0]).capitalize()
	make_boss("sikir", ARENA, d.objective_done(Q2, "sikir") or d.quest_state(Q2) == "done")
	if d.objective_done(Q2, "sikir") and d.quest_state(Q2) != "done":
		_show_bead()
		if d.objective_done(Q2, "tohum"):
			giver_comes("Vizik", ARENA + Vector3(3.5, 0, 5.0), false)
		else:
			drop_seed("lale", ARENA + Vector3(0, 0, 4.5), "Lale Tohumu", "Elindekini sevmek, daha fazlasını istemekten güzelmiş.")
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	d.flags_changed.connect(_sync_stalls)
	_sync_stalls()
	_refresh()
	_player.respawn_point = _player.global_position
	if _player.clap:
		_player.clap.clapped.connect(_on_clapped)
	await get_tree().create_timer(1.8, false).timeout
	if not d.has_flag("s4c1_geldi"):
		d.set_flag("s4c1_geldi")
		GameState.bark("s4k1_basla")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _build() -> void:
	land(Vector3(0, 0, 11), Vector2(46, 40), GRASS)
	land(Vector3(0, 0, -27), Vector2(46, 36), TERRACE, TOP, 4.0)
	fence(Vector3(0, 0, -7), Vector2(44, 74))
	gate(Vector3(0, 0, 27.0))
	# paths: up the middle to the ladder, a lane to every stall, and on the
	# terrace on to the nest
	WorldLook.block(lv, Vector3(0, 0.02, 8.5), Vector3(3.2, 0.04, 29), PATH, 0.0)
	WorldLook.block(lv, Vector3(0, TOP + 0.02, -21), Vector3(3.2, 0.04, 22), PATH, 0.0)
	for s: Array in STALLS:
		var at: Vector3 = s[2]
		WorldLook.block(lv, Vector3(at.x * 0.5, 0.02, at.z + 1.6), Vector3(absf(at.x), 0.04, 2.0), PATH, 0.0)
	# the three stalls, each under its own clump of Yeşil Diken (the first
	# three thorn patches: flags ..._d0, _d1, _d2). They open only to a clap
	# for the owner's own toy, so `clap_opens` is switched on once the toy
	# is back (`_sync_stalls`).
	for i in STALLS.size():
		var at: Vector3 = STALLS[i][2]
		var side := signf(at.x)
		_stall(at + Vector3(side * 1.6, 0, 0), -90.0 * side * PI / 180.0)
		var t := thorns(at + Vector3(-side * 1.2, 0, 0), 4.5, false, false, "tezgah", PI * 0.5)
		t.retracted.connect(func(_t: ThornPatch) -> void:
			if not GameState.data.has_flag("s4c1_ilk_tezgah"):
				GameState.data.set_flag("s4c1_ilk_tezgah")
				GameState.bark("s4k1_tezgah"))
		_stall_thorns.append(t)
	# Vızık's flower stall by the gate
	_stall(Vector3(8.5, 0, 18.0), -PI * 0.5)
	prop("cicek_tarhi", Vector3(7.0, 0, 21.0), 1.1, 0.4)
	for p: Vector3 in [Vector3(5.6, 0, 16.2), Vector3(6.2, 0, 20.0), Vector3(-6, 0, 22)]:
		prop("lale", p, 1.0, p.x)
	for x: float in [-6.0, 6.0]:
		prop("saksi", Vector3(x, 0, 24.0), 0.8, 0.0)
	# strings of flags over the lanes (north of the path, so they hide nobody)
	_flags(Vector3(-9, 0, 14.5), Vector3(-2.2, 0, 14.5))
	_flags(Vector3(2.2, 0, 6.5), Vector3(9, 0, 6.5))
	_flags(Vector3(-9, 0, 1.5), Vector3(-2.2, 0, 1.5))
	# the terrace lip: only the ladder gets you up (a double jump must not)
	for x: float in [-12.15, 12.15]:
		_wall(Vector3(x, 0, -8.7), Vector2(21.7, 0.6))
	_lip_block = _wall(Vector3(0, 0, -8.7), Vector2(2.6, 0.6))
	_ladder = plot(LADDER_AT, "merdiven", Vector3(0, TOP, -4.0))
	_ladder.grown.connect(func(p: SeedPlot) -> void:
		_open_lip()
		_ramp(p)
		GameState.bark("s4k1_tohum")
		_refresh())
	if _ladder.is_grown:
		_open_lip()
		_ramp(_ladder)
	# Yonca's corner: a ladder only she can sprout, up to a crate platform
	# with Pırıl (too high for any jump)
	land(Vector3(PLATFORM.x, 0, PLATFORM.z), Vector2(5, 5), Color("#c9a26a"), PLATFORM.y, PLATFORM.y)
	var corner := plot(Vector3(PLATFORM.x, 0, 19.7), "merdiven", Vector3(0, PLATFORM.y, -4.4), true)
	corner.grown.connect(_ramp)
	if corner.is_grown:
		_ramp(corner)
	for k in 5:
		var pk := Pickup.new()
		pk.amount = 4
		lv.add_child(pk)
		pk.position = PLATFORM + Vector3(cos(k * TAU / 5.0) * 1.3, 0.1, sin(k * TAU / 5.0) * 1.3)
	# the ark sluice and the hedge that dries when it opens
	ark(ARK_AT, "s4_ark1", Q1, "s4k1_kilit", PI)
	_hedge = thorns(Vector3(0, TOP, -19.0), 44.0, true)
	if GameState.data.has_flag("s4_ark1") and not _hedge.is_open:
		_hedge.open()
	# plain clumps beside the route (they only fill the Diken barı)
	thorns(Vector3(7.5, 0, -6.5), 4.0, false)
	thorns(Vector3(-7.5, TOP, -14.0), 4.0, false)
	# Şıkır's nest, north of the arena, and the shiny things she piled up
	if prop("yuva_evi", ARENA + Vector3(0, 0, -8.5), 4.6, 0.0) == null:
		Toon.part(lv, "ellipsoid", Vector3(6, 2.4, 4), Color("#a8794f"), ARENA + Vector3(0, 1.2, -8.5))
	var kinds := ["zil", "bilye", "firildak"]
	for k in 14:
		var a := k * 2.4
		var r := 7.2 + fmod(k * 1.7, 2.6)
		var p := ARENA + Vector3(cos(a) * r, 0, -absf(sin(a)) * r * 0.75 - 1.5)
		ShinyToy.look(lv, kinds[k % 3], p, 0.9).rotation.y = a
	for x: float in [-13.0, 13.0]:
		prop("cicek_tarhi", Vector3(x, TOP, -24.0), 1.1, 0.3 * x)
	prop("bahar_cesmesi", Vector3(-16, 0, 20), 3.4, 0.0)


## A market stall: the model and a box to bump into.
func _stall(at: Vector3, yaw: float) -> void:
	if prop("pazar_tezgahi", at, 3.0, yaw) == null:
		Toon.part(lv, "box", Vector3(2.4, 1.0, 3.0), Color("#c9a26a"), at + Vector3(0, 0.5, 0))
		Toon.part(lv, "box", Vector3(2.8, 0.2, 3.4), Color("#f08ac0"), at + Vector3(0, 2.6, 0))
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(2.2, 3.0, 3.0)
	c.shape = b
	c.position.y = 1.5
	body.add_child(c)
	body.position = at
	lv.add_child(body)


## A string of little flags between two poles.
func _flags(from: Vector3, to: Vector3) -> void:
	for p: Vector3 in [from, to]:
		Toon.part(lv, "cylinder", Vector3(0.14, 3.0, 0.14), Color("#b98a5a"), p + Vector3(0, 1.5, 0))
	var n := 7
	for i in n:
		var f := (i + 0.5) / n
		var sag := 0.5 * sin(f * PI)
		Toon.part(lv, "cone", Vector3(0.42, 0.5, 0.08), FLAGS[i % FLAGS.size()], from.lerp(to, f) + Vector3(0, 2.75 - sag, 0), Vector3(180, 0, 0), 0.2, 0.02)


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


## The leaf steps of a grown ladder are 0.4 m high: too much for the
## keeper's round foot to walk up. An unseen ramp over their front edges
## makes the ladder a plain walk (north-going ladders only).
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


func _open_lip() -> void:
	if _lip_block and is_instance_valid(_lip_block):
		_lip_block.queue_free()
		_lip_block = null


## A toy that is back shows on its stall, and only then a clap opens the
## thorns over it.
func _sync_stalls() -> void:
	if not is_inside_tree():
		return
	var d := GameState.data
	for i in STALLS.size():
		var toy := String(STALLS[i][3])
		if not d.has_flag("s4c1_verdi_" + toy):
			continue
		var at: Vector3 = STALLS[i][2]
		if _stall_toys[i] == null:
			_stall_toys[i] = ShinyToy.look(lv, toy, at + Vector3(-signf(at.x) * 0.2, 1.25, 1.9), 1.3)
		var t := _stall_thorns[i]
		if not t.is_open and not t.clap_opens:
			t.clap_opens = true
			t.add_to_group("applaudable")
			t.set_meta("clap_reach", maxf(t.size.x * 0.5 + 3.0, Applause.REACH))


## A clap that reached nobody in front of a stall without its toy: say why.
func _on_clapped(hits: int) -> void:
	var d := GameState.data
	if hits > 0 or d.quest_state(Q1) != "active" or d.has_flag("s4c1_bos") or GameState.in_dialogue:
		return
	for t in _stall_thorns:
		if not t.is_open and not t.clap_opens and t.global_position.distance_to(_player.global_position) < 5.5:
			d.set_flag("s4c1_bos")
			GameState.bark("s4k1_bos")
			return


## The crows (each with the toy it took) and the mice come with Quest 1. A
## toy counts as taken once the keeper holds it (flag s4c1_var_<toy>).
func _spawn_mobs() -> void:
	var d := GameState.data
	if _mobs or d.quest_state(Q1) != "active":
		return
	_mobs = true
	for i in STALLS.size():
		var toy := String(STALLS[i][3])
		if d.has_flag("s4c1_var_" + toy):
			continue
		var m := dikenci("kapkac_karga", CROWS[i])
		_crows[toy] = m
		ShinyToy.look(m, toy, Vector3(0, 1.9, 0), 1.0)
		Beacon.attach(m, 2.8, Color(String(ShinyToy.KINDS[toy]["color"])).lightened(0.3))
		m.calmed.connect(func(mob: Mob) -> void: _drop_toy(toy, mob.global_position))
	if not d.objective_done(Q1, "oyuncak"):
		dikenciler([["benim_faresi", MICE[0]], ["benim_faresi", MICE[1]]])
	if not d.has_flag("s4c1_ilk_karga"):
		d.set_flag("s4c1_ilk_karga")
		GameState.bark("s4k1_karga")


func _drop_toy(toy: String, from: Vector3) -> void:
	var t := ShinyToy.new()
	t.toy_id = toy
	t.held_flag = "s4c1_var_" + toy
	t.name = "Toy_" + toy
	add_child(t)
	# on the lower market floor, clear of the stalls
	t.global_position = Vector3(clampf(from.x, -8.0, 8.0), 0, clampf(from.z + 0.8, -4.0, 22.0))
	t.taken.connect(func(_id: String) -> void:
		if not GameState.data.has_flag("s4c1_ilk_oyuncak"):
			GameState.data.set_flag("s4c1_ilk_oyuncak")
			GameState.bark("s4k1_oyuncak")
		_refresh())


func _on_ark() -> void:
	_hedge.open()
	GameState.bark("s4k1_ark")
	_refresh()


func fight_ready() -> bool:
	var d := GameState.data
	return d.quest_state(Q2) == "active" and d.has_flag("s4_ark1") and not d.objective_done(Q2, "sikir")


func _begin_fight() -> void:
	start_fight("s4k1_sikir", "Halkalardan kaç, atılınca kenara çekil. Şıkır yorulunca vur!", "Halkalardan kaç, yorulunca vur!")


## The doc's ending: the keeper asks which shiny thing she loves best. She
## can't tell; then she finds her own first bead at the bottom of the nest.
func _on_boss_calmed() -> void:
	_hud.clear_hint()
	boss_camera(false)
	GameState.bark("s4k1_sakin")
	await GameState.dialogue_closed
	await _hud.ask("Bunlardan hangisi en sevdiğin?", [
		{"id": "dugme", "label": "Şu altın düğme mi?"},
		{"id": "kasik", "label": "Şu gümüş kaşık mı?"},
		{"id": "ayna", "label": "Şu minik ayna mı?"}])
	GameState.bark("s4k1_bilemez")
	await GameState.dialogue_closed
	_show_bead(true)
	await get_tree().create_timer(0.9, false).timeout
	Audio.play("laugh")
	GameState.bark("s4k1_boncuk")
	await GameState.dialogue_closed
	drop_seed("lale", ARENA + Vector3(0, 0, 4.5), "Lale Tohumu", "Elindekini sevmek, daha fazlasını istemekten güzelmiş.")
	_refresh()


## Her first bead, beside her.
func _show_bead(fresh := false) -> void:
	if has_node("Bead"):
		return
	var b := ShinyToy.look(self, "boncuk", ARENA + Vector3(1.6, 0.9, 1.2), 1.2)
	b.name = "Bead"
	if fresh:
		var to := b.position
		b.position = ARENA + Vector3(0, 0.3, -6.0)
		var tw := b.create_tween()
		tw.tween_property(b, "position", to, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Effects.sparkle(self, to, Color(String(ShinyToy.KINDS["boncuk"]["color"])), 16)
		Audio.play("crystal")


func _on_seed(_id: String) -> void:
	_hud.clear_hint()
	GameState.bark("s4k1_tohum_al")
	await GameState.dialogue_closed
	await giver_comes("Vizik", ARENA + Vector3(3.5, 0, 5.0))
	_refresh()


## Calm for good: Şıkır keeps a swap stall by her nest.
func _boss_to_shop() -> void:
	if has_node("Sikir"):
		return
	boss.visible = false
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	npc(self, "sikir", "sikir", ARENA, 0.0).name = "Sikir"


func _refresh() -> void:
	var d := GameState.data
	_spawn_mobs()
	var q1 := d.quest_state(Q1)
	var q2 := d.quest_state(Q2)
	# a ladder planted before Vızık asked still counts
	if q1 == "active" and _ladder and _ladder.is_grown and not d.objective_done(Q1, "tohum"):
		d.advance_objective(Q1, "tohum")
		return   # quest_changed calls _refresh again
	if d.has_flag("s4_bolum1_bitti") or q2 == "done":
		_boss_to_shop()
	var v := get_node_or_null("Vizik") as Node3D
	if v == null:
		return
	var go := q1 in ["none", "ready"] or q2 == "ready"
	if go and not v.has_node("Beacon"):
		Beacon.attach(v, 2.6, Tokens.color("spark-white"))
	elif not go and v.has_node("Beacon"):
		v.get_node("Beacon").queue_free()
	if q1 == "none":
		_hud.show_hint("Kapının yanındaki Çiçekçi Vızık ile konuş", "Çiçekçi Vızık ile konuş")
	elif q1 == "active":
		if not d.objective_done(Q1, "oyuncak") or not d.objective_done(Q1, "alkis"):
			_hud.show_hint("Kargayı sersemlet, C ile alkışla. Oyuncağı sahibine götür, tezgâhında alkışla!", "Oyuncağı sahibine götür, tezgâhında Alkış'a bas!")
		else:
			_hud.show_hint("Kuzeyde, taraçanın dibindeki toprağa merdiven tohumu ek", "Taraçanın dibine tohum ek")
	elif q1 == "ready" or q2 == "ready":
		_hud.show_hint("Çiçekçi Vızık'a dön", "Vızık'a dön")
	elif q2 == "active" and not d.has_flag("s4_ark1"):
		_hud.show_hint("Yaprak merdivenden taraçaya çık, ark kapağının çarkını çevir", "Taraçaya çık, ark kapağını aç")
	elif q2 == "active" and not d.objective_done(Q2, "sikir") and not fighting:
		_hud.show_hint("Taraçanın kuzeyindeki yuvaya git: Saksağan Şıkır orada", "Kuzeydeki yuvaya git")
	elif q2 == "active" and d.objective_done(Q2, "sikir") and not d.objective_done(Q2, "tohum") and has_node("Seed"):
		_hud.show_hint("Yuvanın önünde parlayan Lale Tohumu'nu al", "Lale Tohumu'nu al")


## Demo: answer the question panel when it shows.
func _demo_answer() -> bool:
	for p in _hud.find_children("*", "ChoicePanel", true, false):
		(p as ChoicePanel)._pick("dugme")
		return true
	return false


func _run_demo(which: String) -> void:
	var d := GameState.data
	match which:
		"garden":
			# the whole chapter on foot: quest, crows and toys, the right and
			# the wrong owner, claps before and after, the ladder seed, the
			# ark, the hedge, Şıkır, the question, the seed, the last talk
			DevTools.auto_dialogue = true
			await walk_to(VIZIK_AT + Vector3(-1.5, 0, 1.8), 6.0)
			GameState.talk_to("vizik")
			await close_dialogs()
			await get_tree().create_timer(0.5, false).timeout
			await close_dialogs()
			print("S4K1_Q1 state=%s mobs=%d clap=%s" % [d.quest_state(Q1), get_tree().get_nodes_in_group("mob").size(), _player.clap != null])
			# a clap for an empty stall does nothing
			var first: Vector3 = STALLS[0][2]
			await walk_to(Vector3(0, 0, first.z + 1.6), 8.0)
			await walk_to(first + Vector3(4.6, 0, 3.2), 8.0)
			_player.clap._cd = 0.0
			var empty_hits := _player.clap.clap()
			await get_tree().create_timer(0.9, false).timeout
			await close_dialogs()
			print("S4K1_EMPTY hits=%d open=%s said=%s" % [empty_hits, _stall_thorns[0].is_open, d.has_flag("s4c1_bos")])
			# calm only the bell's crow first and show the bell to the wrong owner
			var crow: Mob = _crows["zil"]
			_player.global_position = crow.global_position + Vector3(0, 0.3, 3.0)
			await get_tree().create_timer(0.15, false).timeout
			crow.hit(9999, _player.global_position, 0.0)
			await get_tree().create_timer(0.3, false).timeout
			_player.global_position = crow.global_position + Vector3(0, 0.3, 3.0)
			_player.clap._cd = 0.0
			_player.clap.clap()
			await get_tree().create_timer(0.4, false).timeout
			var bell := get_node_or_null("Toy_zil") as Node3D
			var dropped := bell != null
			if bell:
				await walk_to(bell.global_position, 4.0)
			await get_tree().create_timer(0.6, false).timeout
			await close_dialogs()
			await _talk("virak", "Virak")
			print("S4K1_WRONG dropped=%s held=%s given=%s count=%s" % [dropped, d.has_flag("s4c1_var_zil"), d.has_flag("s4c1_verdi_zil"), d.objective_count(Q1, "oyuncak")])
			await _calm_dikenciler()
			await close_dialogs()
			for id: String in ["bilye", "firildak"]:
				var toy := get_node_or_null("Toy_" + id) as Node3D
				if toy:
					_player.global_position = toy.global_position + Vector3(2.0, 0.3, 0)
					await walk_to(toy.global_position, 4.0)
				await get_tree().create_timer(0.5, false).timeout
				await close_dialogs()
			for i in STALLS.size():
				var s: Array = STALLS[i]
				var at: Vector3 = s[2]
				_player.global_position = Vector3(0, 0.3, at.z + 1.6)
				await walk_to(at + Vector3(-signf(at.x) * 4.6, 0, 3.2), 8.0)
				GameState.talk_to(s[0])
				await close_dialogs()
				_player.clap._cd = 0.0
				var hits := _player.clap.clap()
				await get_tree().create_timer(0.9, false).timeout
				await close_dialogs()
				print("S4K1_STALL %s given=%s hits=%d open=%s toys=%s alkis=%s" % [s[0], d.has_flag("s4c1_verdi_" + String(s[3])), hits,
					_stall_thorns[i].is_open, d.objective_count(Q1, "oyuncak"), d.objective_count(Q1, "alkis")])
			# the terrace: no way up without the ladder
			_player.global_position = Vector3(0, 0.3, 0)
			await walk_to(LADDER_AT + Vector3(0, 0, 1.2), 6.0)
			await walk_to(Vector3(1.6, 0, -7.6), 3.0)
			for k in 3:
				Input.action_press("jump")
				await walk_to(Vector3(1.6, 0, -12.0), 0.6)
				Input.action_release("jump")
				await get_tree().create_timer(0.1, false).timeout
			await get_tree().create_timer(0.6, false).timeout
			print("S4K1_LIP blocked=%s z=%.1f y=%.1f" % [_player.global_position.z > -8.5, _player.global_position.z, _player.global_position.y])
			await walk_to(LADDER_AT + Vector3(0, 0, 1.2), 5.0)
			await get_tree().create_timer(0.3, false).timeout
			_player.interact()
			for i in 60:
				if _ladder.is_grown:
					break
				await get_tree().create_timer(0.25, false).timeout
			await close_dialogs()
			print("S4K1_GROW grown=%s tohum=%s q1=%s" % [_ladder.is_grown, d.objective_done(Q1, "tohum"), d.quest_state(Q1)])
			await _talk("vizik", "Vizik")
			print("S4K1_Q2 q1=%s q2=%s" % [d.quest_state(Q1), d.quest_state(Q2)])
			_player.global_position = Vector3(0, 0.3, -2.0)
			await walk_to(LADDER_AT + Vector3(0, 0, 0.6), 5.0)
			await walk_to(Vector3(0, 0, -11.5), 8.0)
			print("S4K1_LADDER up=%s z=%.1f y=%.1f" % [_player.global_position.y > TOP - 0.2 and _player.global_position.z < -9.5, _player.global_position.z, _player.global_position.y])
			await walk_to(ARK_AT + Vector3(0, 0, 1.8), 6.0)
			await get_tree().create_timer(0.3, false).timeout
			_player.interact()
			await get_tree().create_timer(1.0, false).timeout
			await close_dialogs()
			print("S4K1_ARK ark=%s hedge_open=%s" % [d.has_flag("s4_ark1"), _hedge.is_open])
			await walk_to(Vector3(0, 0, -15.0), 6.0)
			await walk_to(ARENA + Vector3(0, 0, 6.0), 8.0)
			print("S4K1_HEDGE passed=%s z=%.1f" % [_player.global_position.z < -19.5, _player.global_position.z])
			await _beat_boss()
			var asked := false
			for i in 120:
				await close_dialogs()
				asked = _demo_answer() or asked
				if has_node("Seed"):
					break
				await get_tree().create_timer(0.2, false).timeout
			print("S4K1_BOSS sikir=%s asked=%s bead=%s seed=%s" % [d.objective_done(Q2, "sikir"), asked, has_node("Bead"), has_node("Seed")])
			await walk_to(ARENA + Vector3(0, 0, 4.5), 6.0)
			await get_tree().create_timer(1.0, false).timeout
			await close_dialogs()
			await get_tree().create_timer(2.5, false).timeout
			await close_dialogs()
			print("S4K1_SEED tohum=%s q2=%s" % [d.has_flag("tohum_lale"), d.quest_state(Q2)])
			await _talk("vizik", "Vizik")
			await get_tree().create_timer(3.5, false).timeout
			await _talk("sikir", "Sikir")
			await get_tree().create_timer(0.5, false).timeout
			print("S4K1_SHOP npc=%s shops=%s" % [has_node("Sikir"), [Content.shops.has("vizik"), Content.shops.has("sikir")]])
			print("S4K1_DONE q2=%s ark=%s tohum=%s bitti=%s gate_star=%s next=%s" % [d.quest_state(Q2), d.has_flag("s4_ark1"), d.has_flag("tohum_lale"),
				d.has_flag("s4_bolum1_bitti"), lv.get_node("Gate").has_node("Beacon"), GardenTravel.next_stop(d)])
			get_tree().quit()
