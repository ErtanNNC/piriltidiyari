extends S3Island
## Sezon 3 · Bölüm 3 – Değişen Kumlar, Kum İncisi (levels 15–20). An island
## whose dunes change place every night, so no map of it stays true. Tospik
## Nine (she came along on the boat) asks for "Kayan Kumlar": light the
## torches between the dune rows, calm the Titrekler and lead two lost
## starfish by the hand back to the tide pool by the landing. Then the
## İşaret Fişeği opens the Titreme Perdesi to the hermit crab Bikbik, who is
## stuck in the old shell he has outgrown and swings his claws out of fear.
## Calmed, he and the keeper pick a new shell together (three to choose
## from, every choice is right), he gives the Kum İncisi, and the pearl
## shows Tırıl's first memory: the coral garden.
##
## Special: `ShiftDune`. Each of the three dune rows has two gaps and one
## walking dune that slides from one gap to the other (warned 0.8 s ahead,
## never onto the keeper), so one gap is always open. An arrow post in
## front of every row points at the open gap.
##
## Layout: sand 34×76 round (0,0,-8) · pier south (0,0,31.5) · landing with
## Tospik and the tide pool (-9,0,22) · dune rows at z = 6, -4, -14 with
## gaps at x = ±9 · flare (4,0,-20) · veil z = -25 · Bikbik's arena
## (0,0,-36), the three shells on its west side.

const Q1 := "kayan_kumlar"
const Q2 := "dar_kabuk"
const SAND := Color("#e0bf7a")
const DUNE := Color("#edd08c")
const POOL := Vector3(-9, 0, 22)
const ARENA := Vector3(0, 0, -36)
const FLARE := Vector3(4, 0, -20)
const ROWS := [6.0, -4.0, -14.0]
const GAP_X := 9.0
const GAP_W := 5.0
const ROW_DEPTH := 3.0
const TORCHES := [Vector3(3, 0, 19.5), Vector3(-5, 0, 11), Vector3(5, 0, 11), Vector3(-5, 0, 1),
	Vector3(5, 0, 1), Vector3(-5, 0, -9), Vector3(5, 0, -9), Vector3(-3, 0, -19.5)]
const TITREKS := [["kumdan_hortlak", Vector3(13.5, 0, 11.5)], ["kumdan_hortlak", Vector3(-13.5, 0, 1)],
	["kumdan_hortlak", Vector3(13.5, 0, -9)], ["kayip_denizyildizi", Vector3(-12.5, 0, -20)]]
const STARFISH := [Vector3(13.5, 0, 1), Vector3(-13.5, 0, -9)]
const SHELLS := [
	{"id": "pembe", "label": "Pembe Sarmal", "at": Vector3(-11.5, 0, -31), "h": 2.6, "col": "#f2a7b8"},
	{"id": "altin", "label": "Altın Külah", "at": Vector3(-13, 0, -36), "h": 3.2, "col": "#f0c860"},
	{"id": "mavi", "label": "Mavi Kubbe", "at": Vector3(-11.5, 0, -41), "h": 3.8, "col": "#8fc4ee"}]

var dunes: Array[ShiftDune] = []
var _arrows: Array[Node3D] = []
var _veil: ShiverVeil
var _choosing := false


func _ready() -> void:
	begin("s3_chapter3")
	var d := GameState.data
	flare_flag = "s3_fisek3"
	mist(0.45)
	_build()
	Decor.auto(self, "kumsal")
	npc(self, "tospik_nine", "turtle", Vector3(4, 0, 23.5), -150.0).name = "Tospik"
	if d.character_id != "tosbi":
		npc(self, "tosbi", "tosbi", Vector3(6, 0, 22), -130.0).name = "Tosbi"
	if d.quest_state(Q1) != "done":
		titreks(TITREKS)
		for i in STARFISH.size():
			if d.objective_count(Q1, "el").x > i:
				continue
			var f := friend("yildiz", "kayip_denizyildizi", STARFISH[i], POOL)
			f.goal_radius = 3.2
			f.arrived.connect(_on_starfish_home)
	make_boss("bikbik", ARENA, d.objective_done(Q2, "bikbik"))
	if d.objective_done(Q2, "bikbik"):
		_stand_by_shell(_chosen_shell(), false)
		drop_pearl("kum", ARENA + Vector3(0, 0, 5), "Kum İncisi", "Bikbik'in eski kabuğundan çıktı.")
		_friends_to_arena(false)
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	_refresh()
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.8, false).timeout
	if not d.has_flag("s3c3_geldi"):
		d.set_flag("s3c3_geldi")
		GameState.bark("s3k3_basla")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _build() -> void:
	land(Vector3(0, 0, -8), Vector2(34, 76), SAND)
	fence(Vector3(0, 0, -8), Vector2(32, 74))
	dock(Vector3(0, 0, 31.5))
	for at: Vector3 in TORCHES:
		torch(at)
	# the tide pool by the landing: where the lost starfish belong
	var pool := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 2.6
	disc.bottom_radius = 2.6
	disc.height = 0.04
	pool.mesh = disc
	pool.position = POOL + Vector3.UP * 0.03
	WorldLook.water(pool, "sea_night")
	lv.add_child(pool)
	for i in 9:
		var a := TAU * i / 9.0
		Toon.part(lv, "ellipsoid", Vector3(1.1, 0.5, 0.9), Color("#b89a6a") if i % 2 == 0 else Color("#9c8a78"),
			POOL + Vector3(cos(a) * 2.8, 0.05, sin(a) * 2.8), Vector3(0, rad_to_deg(a), 0))
	TravelSign.board(lv, "Gelgit Havuzu", POOL + Vector3(0, 1.5, -3.6), 2.6)
	Toon.part(lv, "box", Vector3(0.14, 1.4, 0.14), Color("#a8794f"), POOL + Vector3(0, 0.7, -3.65))
	TravelSign.board(lv, "Kumlar yürür! Oka bak.", Vector3(-3.5, 1.6, 15.5), 3.6)
	Toon.part(lv, "box", Vector3(0.14, 1.5, 0.14), Color("#a8794f"), Vector3(-3.5, 0.75, 15.45))
	# three dune rows: sides and middle stand still, one dune walks between
	# the two gaps
	var side_w := 17.0 - (GAP_X + GAP_W * 0.5)
	var mid_w := (GAP_X - GAP_W * 0.5) * 2.0
	for i in ROWS.size():
		var z: float = ROWS[i]
		_dune(Vector3(-17.0 + side_w * 0.5, 0, z), side_w)
		_dune(Vector3(0, 0, z), mid_w)
		_dune(Vector3(17.0 - side_w * 0.5, 0, z), side_w)
		var sd := ShiftDune.new()
		var s := -1.0 if i % 2 == 0 else 1.0
		sd.a = Vector3(GAP_X * s, 0, z)
		sd.b = Vector3(-GAP_X * s, 0, z)
		sd.size = Vector3(GAP_W, 5.0, ROW_DEPTH)
		sd.offset = [3.0, 5.5, 0.5][i]
		sd.col = DUNE
		sd.name = "ShiftDune%d" % i
		lv.add_child(sd)
		dunes.append(sd)
		_arrows.append(_arrow_post(Vector3(0, 0, z + 2.7)))
		_point(i, false)
		sd.shifted.connect(func(_b: bool) -> void: _on_shift(i))
	# the keeper's place: the veil between two dunes, the flare before it
	_dune(Vector3(-11, 0, -25), 12.0)
	_dune(Vector3(11, 0, -25), 12.0)
	flare(FLARE, "s3_fisek3", Q1, "s3k3_kilit")
	_veil = veil(Vector3(0, 0, -25), 10.0, "s3c3_perde")
	for sh: Dictionary in SHELLS:
		_shell(sh)
	# palms, rocks and washed-up shells along the shore (never on the route)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var spots := [Vector3(-14.5, 0, 26), Vector3(14, 0, 26.5), Vector3(13.5, 0, 17), Vector3(-15, 0, 16),
		Vector3(15, 0, -20.5), Vector3(-15.2, 0, -29), Vector3(14.5, 0, -30), Vector3(13, 0, -43.5),
		Vector3(-6, 0, -44.2), Vector3(5, 0, -44.4), Vector3(15, 0, -38)]
	for i in spots.size():
		var id: String = ["koy_cali", "kiyi_kaya", "dev_kabuk"][i % 3]
		var h: float = [2.4, 2.0, 1.6][i % 3] * rng.randf_range(0.85, 1.15)
		if prop(id, spots[i], h, rng.randf() * TAU) == null:
			_fallback_prop(i % 3, spots[i], h)


## A dune that stands still: a wall across the row (tall collider).
func _dune(center: Vector3, width: float) -> void:
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(width, 5.0, ROW_DEPTH)
	c.shape = b
	c.position.y = 2.5
	body.add_child(c)
	body.position = center
	lv.add_child(body)
	ShiftDune.heap(body, Vector3.ZERO, Vector2(width, ROW_DEPTH), DUNE)


## A post with a big arrow that turns toward the row's open gap.
func _arrow_post(at: Vector3) -> Node3D:
	var wood := Color("#a8794f")
	Toon.part(lv, "box", Vector3(0.16, 2.2, 0.16), wood, at + Vector3(0, 1.1, 0))
	var arrow := Node3D.new()
	arrow.position = at + Vector3(0, 2.3, 0)
	lv.add_child(arrow)
	Toon.part(arrow, "box", Vector3(1.5, 0.34, 0.14), Color("#fff3dc"), Vector3(-0.2, 0, 0), Vector3.ZERO, 0.6)
	Toon.part(arrow, "cone", Vector3(0.8, 0.7, 0.16), Color("#f0c860"), Vector3(0.85, 0, 0), Vector3(0, 0, -90), 1.2)
	return arrow


## Turn row `i`'s arrow to the gap that is open now.
func _point(i: int, smooth := true) -> void:
	var sd := dunes[i]
	var open_x := sd.a.x if sd.at_b else sd.b.x
	var yaw := 0.0 if open_x > 0.0 else PI
	if smooth:
		_arrows[i].create_tween().tween_property(_arrows[i], "rotation:y", yaw, 0.4).set_trans(Tween.TRANS_BACK)
	else:
		_arrows[i].rotation.y = yaw


func _on_shift(i: int) -> void:
	_point(i)
	var d := GameState.data
	if d.has_flag("s3c3_kum") or GameState.in_dialogue or fighting or DevTools.demo != "":
		return
	if _player.global_position.distance_to(dunes[i].global_position) < 22.0:
		d.set_flag("s3c3_kum")
		GameState.bark("s3k3_kum")


## One of the three empty shells by the arena, with its name on a board.
func _shell(sh: Dictionary) -> void:
	var at: Vector3 = sh["at"]
	var h: float = sh["h"]
	var col := Color(String(sh["col"]))
	if prop("dev_kabuk", at, h, 0.6) == null:
		# a spiral: rounds that shrink toward the tip, a dark doorway
		for k in 4:
			var r := h * (0.95 - k * 0.2)
			Toon.part(lv, "ellipsoid", Vector3(r, r * 0.6, r), col.darkened(0.08 * (k % 2)), at + Vector3(0, h * (0.22 + k * 0.2), 0))
		Toon.part(lv, "cone", Vector3(h * 0.3, h * 0.3, h * 0.3), col.lightened(0.2), at + Vector3(0, h * 1.02, 0))
		Toon.part(lv, "ellipsoid", Vector3(h * 0.4, h * 0.36, 0.2), Color("#5a4636"), at + Vector3(h * 0.2, h * 0.2, h * 0.42))
	# its colour as a small lamp, so the three are told apart at night
	Toon.part(lv, "sphere", Vector3(0.45, 0.45, 0.45), col, at + Vector3(0, h + 0.5, 0), Vector3.ZERO, 2.0, 0.0)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = h * 0.42
	s.height = h
	c.shape = s
	c.position.y = h * 0.5
	body.add_child(c)
	body.position = at
	lv.add_child(body)
	TravelSign.board(lv, String(sh["label"]), at + Vector3(2.2, 1.0, 1.6), 2.4, 0.7)


func _fallback_prop(kind: int, at: Vector3, h: float) -> void:
	match kind:
		0:   # palm
			Toon.part(lv, "cylinder", Vector3(0.4, h, 0.4), Color("#a8794f"), at + Vector3(0, h * 0.5, 0), Vector3(0, 0, 5))
			for k in 5:
				var a := TAU * k / 5.0
				Toon.part(lv, "ellipsoid", Vector3(2.6, 0.3, 0.9), Color("#5f9a6a"), at + Vector3(cos(a) * 1.1, h, sin(a) * 1.1), Vector3(0, -rad_to_deg(a), -18))
		1:   # shore rock
			Toon.part(lv, "ellipsoid", Vector3(h * 1.4, h * 1.6, h * 1.2), Color("#9c8a78"), at)
		_:   # a washed-up shell
			Toon.part(lv, "ellipsoid", Vector3(h, h * 1.2, h), Color("#f4dcc0"), at + Vector3(0, h * 0.3, 0))
			Toon.part(lv, "cone", Vector3(h * 0.5, h * 0.6, h * 0.5), Color("#f2a7b8"), at + Vector3(0, h * 1.0, 0))


func _on_starfish_home() -> void:
	Effects.ring(self, POOL + Vector3.UP * 0.2, 2.6, Color("#9fd8ff"), 0.5)
	Audio.play("splash")
	if not GameState.data.has_flag("s3c3_havuz"):
		GameState.data.set_flag("s3c3_havuz")
		GameState.bark("s3k3_havuz")


func fight_ready() -> bool:
	var d := GameState.data
	return d.quest_state(Q2) == "active" and d.has_flag("s3_fisek3") and not d.objective_done(Q2, "bikbik")


func _begin_fight() -> void:
	start_fight("s3k3_bikbik", "Kıskaçtan ve kum çukurundan kaç. Bikbik yorulunca vur!", "Kıskaçtan kaç, yorulunca vur!")


func _on_boss_sad() -> void:
	super._on_boss_sad()
	GameState.bark("s3k3_bikbik_yorgun")


## He can't stay in the old shell: a new one is picked together.
func _on_boss_calmed() -> void:
	_hud.clear_hint()
	boss_camera(false)
	_choosing = true
	_friends_to_arena(true)
	GameState.bark("s3k3_bikbik_son_tosbi" if GameState.data.character_id == "tosbi" else "s3k3_bikbik_son")
	await GameState.dialogue_closed
	var opts := []
	for sh: Dictionary in SHELLS:
		opts.append({"id": sh["id"], "label": sh["label"]})
	var pick: String = await _hud.ask("Bikbik hangi kabuğu denesin?", opts)
	if pick == "":
		pick = "altin"
	GameState.data.set_flag("s3c3_kabuk_" + pick)
	await _stand_by_shell(_chosen_shell(), true)
	GameState.bark("s3k3_kabuk_" + pick)
	await GameState.dialogue_closed
	_choosing = false
	drop_pearl("kum", ARENA + Vector3(0, 0, 5), "Kum İncisi", "Bikbik'in eski kabuğundan çıktı.")
	_refresh()


func _chosen_shell() -> Dictionary:
	for sh: Dictionary in SHELLS:
		if GameState.data.has_flag("s3c3_kabuk_" + String(sh["id"])):
			return sh
	return {}


## Bikbik next to the shell he chose (walks there with sparkles, or is just
## placed after a reload).
func _stand_by_shell(sh: Dictionary, walk: bool) -> void:
	if sh.is_empty():
		return
	var at: Vector3 = sh["at"]
	var to := at + Vector3(float(sh["h"]) * 0.42 + 2.0, 0, 0.6)
	var col := Color(String(sh["col"]))
	if not walk:
		boss.position = to
		return
	Audio.play("quest")
	var tw := boss.create_tween()
	tw.tween_property(boss, "position", to, 1.4).set_trans(Tween.TRANS_SINE)
	await tw.finished
	Effects.ring(self, at + Vector3.UP * 0.3, float(sh["h"]) * 0.9, col, 0.6)
	Effects.sparkle(self, at + Vector3.UP * float(sh["h"]) * 0.6, col.lightened(0.3), 24)
	Effects.sparkle(self, boss.global_position + Vector3.UP * 1.5, Tokens.color("spark-yellow"), 16)
	Audio.play("fanfare")


## Tospik Nine (and Tosbi) come over to the arena, so the last talk is there.
func _friends_to_arena(walk: bool) -> void:
	giver_comes("Tospik", ARENA + Vector3(4.5, 0, 6.5), walk)
	if has_node("Tosbi"):
		(get_node("Tosbi") as Node3D).global_position = ARENA + Vector3(6.5, 0, 5.5)
	_refresh.call_deferred()


func _on_flare() -> void:
	_hud.clear_hint()
	_veil.open()
	GameState.bark("s3k3_fisek")
	_refresh()


## The pearl, then what it remembers: Tırıl's first memory.
func _on_pearl(_id: String) -> void:
	GameState.bark("s3k3_inci")
	await GameState.dialogue_closed
	var d := GameState.data
	if not d.has_flag("s3c3_ani"):
		d.set_flag("s3c3_ani")
		Audio.play("memory")
		_hud.show_scene_card("Anı", "Mercan Bahçesi", "Tırıl'ın ilk anısı")
		await get_tree().create_timer(2.6, false).timeout
		GameState.bark("s3k3_ani")
		await GameState.dialogue_closed
	_refresh()


func _refresh() -> void:
	var d := GameState.data
	var nine := get_node_or_null("Tospik") as Node3D
	if nine == null:
		return
	var go := d.quest_state(Q1) in ["none", "ready"] or d.quest_state(Q2) == "ready"
	if go and not nine.has_node("Beacon"):
		Beacon.attach(nine, 2.8, Tokens.color("spark-white"))
	elif not go and nine.has_node("Beacon"):
		nine.get_node("Beacon").queue_free()
	var fl := lv.get_node_or_null("Flare") as Node3D
	if fl and d.quest_state(Q2) == "active" and not d.has_flag("s3_fisek3") and not fl.has_node("Beacon"):
		Beacon.attach(fl, 3.4, Tokens.color("spark-yellow"))
		_hud.show_hint("Kumların kuzeyindeki İşaret Fişeği'ni yak", "İşaret Fişeği'ni yak")
	var dk := lv.get_node_or_null("Dock") as Node3D
	if dk and d.has_flag("s3_bolum3_bitti") and not d.has_flag("s3_fisek4") and not dk.has_node("Beacon"):
		Beacon.attach(dk, 3.0, Tokens.color("spark-white"))
		_hud.show_hint("Kabuk Kayık'a bin: Fırtına Kayası'na açıl", "Kayığa bin: Fırtına Kayası")


func _run_demo(which: String) -> void:
	match which:
		"view":
			# screenshots: stand in the dune field (--at=Z picks the spot)
			_player.global_position = Vector3(0, 0.3, 10.0)
		"island":
			# the whole chapter by its quests (headless)
			DevTools.auto_dialogue = true
			var d := GameState.data
			await _demo_dunes()
			await _talk("tospik_nine", "Tospik")
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
				_player.global_position = POOL + Vector3(0, 0.3, 2.0)
				await get_tree().create_timer(1.5, false).timeout
				await close_dialogs()
			print("S3K3_Q1 mesale=%s el=%s" % [d.objective_done(Q1, "mesale"), d.objective_done(Q1, "el")])
			await _calm_all()
			print("S3K3_Q1 titrek=%s" % d.objective_done(Q1, "titrek"))
			await _talk("tospik_nine", "Tospik")
			print("S3K3_Q1 state=%s q2=%s level=%d" % [d.quest_state(Q1), d.quest_state(Q2), d.level])
			_player.global_position = FLARE + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.5, false).timeout
			_player.interact()
			await close_dialogs()
			print("S3K3_FISEK fisek=%s perde=%s" % [d.has_flag("s3_fisek3"), _veil.is_open])
			_player.global_position = ARENA + Vector3(0, 0.3, 7.0)
			await _beat_boss()
			print("S3K3_BOSS bikbik=%s" % d.objective_done(Q2, "bikbik"))
			# the shell: pick the blue one
			for i in 100:
				await close_dialogs()
				var cp := _find_choice()
				if cp:
					cp._pick("mavi")
					break
				await get_tree().create_timer(0.1, false).timeout
			for i in 100:
				await close_dialogs()
				if not _choosing:
					break
				await get_tree().create_timer(0.1, false).timeout
			print("S3K3_KABUK mavi=%s yaninda=%s" % [d.has_flag("s3c3_kabuk_mavi"), boss.position.distance_to(SHELLS[2]["at"]) < 5.0])
			_player.global_position = ARENA + Vector3(0, 0.3, 5.0)
			for i in 60:
				await close_dialogs()
				if d.has_flag("s3c3_ani") and not GameState.in_dialogue:
					break
				await get_tree().create_timer(0.2, false).timeout
			await close_dialogs()
			print("S3K3_INCI inci=%s ani=%s" % [d.has_flag("inci_kum"), d.has_flag("s3c3_ani")])
			await _talk("tospik_nine", "Tospik")
			print("S3K3_DONE q2=%s fisek=%s inci=%s bitti=%s" % [d.quest_state(Q2) == "done", d.has_flag("s3_fisek3"), d.has_flag("inci_kum"), d.has_flag("s3_bolum3_bitti")])
			get_tree().quit()


func _find_choice() -> ChoicePanel:
	for n: Node in _hud._root.get_children():
		if n is ChoicePanel:
			return n
	return null


## Demo: the first row's closed gap blocks, the open one lets through; a
## dune waits while the keeper stands where it wants to go, then shifts.
func _demo_dunes() -> void:
	var sd := dunes[0]
	# start right after a shift, so the dune rests for a whole period
	var at_start := sd.at_b
	for i in 300:
		if sd.at_b != at_start:
			break
		await get_tree().create_timer(0.1, false).timeout
	var closed_x := sd.position.x
	var open_x := -closed_x
	var z := sd.a.z
	_player.global_position = Vector3(closed_x, 0.3, z + 4.0)
	await walk_to(Vector3(closed_x, 0, z - 4.0), 2.0)
	var blocked := _player.global_position.z > z + 1.0
	_player.global_position = Vector3(open_x, 0.3, z + 4.0)
	await walk_to(Vector3(open_x, 0, z - 4.0), 3.0)
	var passed := _player.global_position.z < z - 1.5
	print("S3K3_DUNE closed_blocks=%s open_passes=%s" % [blocked, passed])
	# stand in the open gap: the dune must not come
	_player.global_position = Vector3(open_x, 0.3, z)
	var was_b := sd.at_b
	await get_tree().create_timer(sd.period + 3.0, false).timeout
	var waited := sd.at_b == was_b and not sd.moving and sd.held
	var free := absf(_player.global_position.x - open_x) < 0.5 and absf(_player.global_position.z - z) < 1.2   # still in the gap, not pushed out
	# step out: warned, then it slides over and the other gap opens
	_player.global_position = Vector3(0, 0.3, z + 6.0)
	var warned := false
	for i in 120:
		if lv.get_children().any(func(n: Node) -> bool: return String(n.name).begins_with("Warning")):
			warned = true
		if sd.at_b != was_b:
			break
		await get_tree().create_timer(0.1, false).timeout
	_player.global_position = Vector3(closed_x, 0.3, z + 4.0)
	await walk_to(Vector3(closed_x, 0, z - 4.0), 3.0)
	var now_open := _player.global_position.z < z - 1.5
	print("S3K3_DUNE waits_for_keeper=%s keeper_free=%s warned=%s shifted=%s old_gap_open=%s arrow=%s" % [waited, free, warned,
		sd.at_b != was_b, now_open, is_equal_approx(absf(_arrows[0].rotation.y), 0.0) == (closed_x > 0.0)])
