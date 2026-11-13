extends S3Island
## Sezon 3 · Bölüm 5 – Kayıp Ada, İnci Beyazı (levels 25–30, the final). A
## small island that winds like a maze in the thickest mist: every way
## looks the same, and only Hırıl's far drum shows the right one (four
## forks: the right gate pulses with the beat, the wrong one's mist walks
## you gently back). In the middle lies a sunken toy boat, Tırıl's hiding
## place; Hırıl has sat beside it for days, drumming softly.
##
## Final, two phases. Faz 1: Tırıl, frightened, calls up the keepers' fears
## as shadows (`ShoreBoss` "tiril": dark, wind, thunder). Faz 2 is no fight
## but hide-and-seek: Tırıl hides in four spots; each "Seni buldum!" brings
## one more friend into the hand-in-hand chain. At the last one everybody
## stands in a ring, Tırıl in the middle: a hand (Sakinleş), the trembling
## light holds steady and the Mavi Titreme is gone. İnci Beyazı; Hırıl sends
## you home to the Fener Gecesi (`s3_final`).
##
## Layout (−z is into the island): pier z 30 · fork rooms at z 18, 2, −14,
## −30 (gate rows 8 m north of each) · the clearing with the toy boat at
## (0, 0, −52), flare at (−9, 0, −45).

const Q1 := "davulun_izi"
const Q2 := "tiril"
const SAND := Color("#aeb6d6")
const SAND_DARK := Color("#7f88b0")
const ROOM_Z := [18.0, 2.0, -14.0, -30.0]
## The right gate of each fork (−1 = left, 1 = right).
const RIGHT_SIDE := [-1.0, 1.0, 1.0, -1.0]
const GATE_X := 4.5
const CLEARING := Vector3(0, 0, -52.0)
const HIDES := [Vector3(-9, 0, -58), Vector3(9, 0, -47), Vector3(8, 0, -59), Vector3(-10, 0, -50)]
const FRIENDS := ["pati", "bado", "citir", "lumi", "tipis_panda", "tosbi"]

var _beat_t := 0.0
var _phase2 := false
var _found := 0
var _glimmer: Node3D
var _chain: Array[Node3D] = []
var _hiril: Npc
var _veil: ShiverVeil


func _ready() -> void:
	begin("s3_chapter5")
	var d := GameState.data
	flare_flag = "s3_fisek5"
	mist(0.6)
	cold_before = 1.2
	_build()
	Decor.auto(self, "kumsal")
	_hiril = npc(self, "hiril", "hiril", CLEARING + Vector3(-3.5, 0, 3.0), 60.0)
	_hiril.name = "Hiril"
	make_boss("tiril", CLEARING, d.objective_done(Q2, "tiril"))
	boss.sad.disconnect(_on_boss_sad)
	boss.sad.connect(_start_hide_and_seek)
	boss.visible = d.quest_state(Q2) != "none"
	if d.objective_done(Q2, "tiril") and not d.has_flag("inci_beyaz"):
		_drop()
	if d.quest_state(Q1) == "none":
		d.start_quest(Content.quests[Q1])
	if d.quest_state(Q1) != "done":
		titreks([["sis_kuklasi", Vector3(-5, 0, 20)], ["korku_golgesi", Vector3(5, 0, 4)],
			["sis_kuklasi", Vector3(-5, 0, -12)], ["korku_golgesi", Vector3(5, 0, -28)]])
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	_refresh()
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.8, false).timeout
	if not d.has_flag("s3c5_geldi"):
		d.set_flag("s3c5_geldi")
		GameState.bark("s3k5_basla")
		_hud.show_hint("Her yol aynı görünüyor. Davulun çaldığı kapıdan geç!", "Davulun çaldığı kapıdan geç!")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _build() -> void:
	land(Vector3(0, 0, -16), Vector2(22, 100), SAND)
	land(CLEARING, Vector2(34, 30), SAND)
	fence(Vector3(0, 0, 9), Vector2(20, 48))
	dock(Vector3(0, 0, 33.5))
	# the fork rooms: a torch each, and a gate row with a wall in the middle
	for i in ROOM_Z.size():
		var z: float = ROOM_Z[i]
		torch(Vector3(0, 0, z + 2.0))
		var gz := z - 8.0
		for x: float in [-9.5, 0.0, 9.5]:
			var w := WorldLook.block(lv, Vector3(x, 2.0, gz), Vector3(3.0 if x != 0.0 else 4.0, 4.0, 2.0), SAND_DARK)
			ModelImport.cover_block(w, "kiyi_kaya", Vector3(1.2, 1.1, 1.2))
		prop("sis_agaci", Vector3(0, 4.0, gz), 4.5, i * 1.3)
		for s: float in [-1.0, 1.0]:
			var good: bool = s == RIGHT_SIDE[i]
			var t := TriggerArea.new()
			t.area_id = "s3k5_kapi%d" % i if good else ""
			t.radius = 1.6
			t.once = good
			t.position = Vector3(GATE_X * s, 0, gz - 1.0)
			lv.add_child(t)
			if not good:
				var back := Vector3(0, 0.3, z + 3.0)
				t.reached.connect(func() -> void: _wrong_gate(back))
	# walls along the maze strip (the sea is behind them)
	for s: float in [-1.0, 1.0]:
		var wall := StaticBody3D.new()
		wall.set_meta("camera_ignore", true)
		var c := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = Vector3(1, 12, 70)
		c.shape = b
		wall.add_child(c)
		wall.position = Vector3(11.0 * s, 6, 0)
		lv.add_child(wall)
		for k in 9:
			prop("sis_agaci" if k % 2 == 0 else "kiyi_kaya", Vector3(12.5 * s, 0, 30.0 - k * 8.0), 5.0 if k % 2 == 0 else 2.2, k * 0.9)
	# the clearing: the sunken toy boat, the flare, a ring of pale trees
	fence(CLEARING, Vector2(32, 28))
	if prop("oyuncak_tekne", CLEARING + Vector3(0, -0.3, -4.5), 3.6, 0.5) == null:
		Toon.part(lv, "ellipsoid", Vector3(2.6, 1.2, 5.0), Color("#7fa0c8"), CLEARING + Vector3(0, 0.3, -4.5), Vector3(0, 30, 18))
	var bb := StaticBody3D.new()
	var bc := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(4.5, 2.5, 2.6)
	bc.shape = bs
	bc.position.y = 1.2
	bb.add_child(bc)
	bb.position = CLEARING + Vector3(0, 0, -4.5)
	lv.add_child(bb)
	flare(CLEARING + Vector3(-9, 0, 7), "s3_fisek5", Q1, "s3k5_kilit")
	for k in 10:
		var a := TAU * k / 10.0
		prop("sis_agaci", CLEARING + Vector3(cos(a) * 15.0, 0, sin(a) * 13.0 - 1.0), 5.5, a)
	_veil = veil(Vector3(0, 0, -39.5), 20.0, "s3k5_perde", false)
	var t := TriggerArea.new()
	t.area_id = "tekne"
	t.radius = 5.0
	t.position = CLEARING + Vector3(0, 0, 8.0)
	lv.add_child(t)


## The wrong gate: thick mist carries you gently back to the fork.
func _wrong_gate(back: Vector3) -> void:
	Audio.play("whoosh")
	Effects.ring(self, _player.global_position + Vector3.UP * 0.3, 2.4, Color(0.6, 0.78, 1.0), 0.5)
	_player.global_position = back
	_player.velocity = Vector3.ZERO
	GameState.toast.emit("Sis seni geri getirdi. Davulu dinle: hangi kapıdan geliyor?", "spark")


func _process(delta: float) -> void:
	super._process(delta)
	# Hırıl's drum: the right gate of the nearest fork ahead pulses
	_beat_t -= delta
	if _beat_t <= 0.0:
		_beat_t = 1.1
		for i in ROOM_Z.size():
			var z: float = ROOM_Z[i]
			if _player.global_position.z <= z + 8.0 and _player.global_position.z > z - 9.0:
				var at := Vector3(GATE_X * RIGHT_SIDE[i], 0.3, z - 8.0)
				Effects.ring(self, at, 1.8, Tokens.color("hp"), 0.6)
				FloatText.spawn(self, at + Vector3.UP * 1.6, "♪", Tokens.color("hp"))
				if not GameState.in_dialogue:
					Audio.play("drum")
	if _phase2 and _glimmer and not GameState.in_dialogue:
		var t := Time.get_ticks_msec() / 1000.0
		_glimmer.position.x = HIDES[_found].x + sin(t * 40.0) * 0.04
		if _player.global_position.distance_to(_glimmer.global_position) < 2.4:
			_find()


func fight_ready() -> bool:
	var d := GameState.data
	return d.quest_state(Q2) == "active" and d.has_flag("s3_fisek5") and not d.objective_done(Q2, "tiril") and not _phase2


func _begin_fight() -> void:
	boss.visible = true
	start_fight("s3k5_tiril", "Gölgeler korkudan geliyor. Kaç, Tırıl yorulunca vur!", "Gölgelerden kaç, yorulunca vur!")


func _on_flare() -> void:
	_veil.open()
	GameState.bark("s3k5_fisek")
	_refresh()


# --- Faz 2: saklambaç -------------------------------------------------------

## No more fighting: Tırıl hides, the keeper seeks.
func _start_hide_and_seek() -> void:
	_phase2 = true
	boss.is_sad = false
	boss.remove_from_group("dazed")
	boss.visible = false
	_hud.hide_boss()
	boss_camera(false)
	GameState.bark("s3k5_faz2")
	await GameState.dialogue_closed
	_hide_next()


func _hide_next() -> void:
	_glimmer = Node3D.new()
	add_child(_glimmer)
	_glimmer.position = HIDES[_found] + Vector3.UP * 0.6
	Toon.part(_glimmer, "sphere", Vector3(0.35, 0.35, 0.35), Color("#9fd8ff"), Vector3.ZERO, Vector3.ZERO, 1.6, 0.0)
	var l := OmniLight3D.new()
	l.light_color = Color("#9fd8ff")
	l.light_energy = 0.9
	l.omni_range = 3.0
	_glimmer.add_child(l)
	prop("sis_agaci" if _found % 2 == 0 else "kiyi_kaya", HIDES[_found] + Vector3(0.9, 0, 0.9), 2.6, _found * 1.1)
	_hud.show_hint("Tırıl saklandı. Titreyen küçük ışığı bul! (%d/4)" % _found, "Titreyen ışığı bul! (%d/4)" % _found)


## "Seni buldum!" – and one more friend joins the chain.
func _find() -> void:
	var at := _glimmer.global_position
	_glimmer.queue_free()
	_glimmer = null
	Audio.play("quest")
	Effects.sparkle(self, at + Vector3.UP * 0.5, Color("#9fd8ff"), 14)
	GameState.notify("collect", "saklambac")
	_add_friend()
	GameState.bark("s3k5_buldum%d" % (_found + 1))
	_found += 1
	await GameState.dialogue_closed
	if _found < HIDES.size():
		_hide_next()
	else:
		_ring_of_hands()


## One more keeper walks in and takes the last one's hand.
func _add_friend() -> void:
	var ids: Array = FRIENDS.duplicate()
	ids.erase(GameState.data.character_id)
	var id: String = ids[_chain.size() % ids.size()]
	var m := KeeperModels.build(id)
	add_child(m)
	var a := PI * 0.25 + _chain.size() * PI * 0.3
	m.position = CLEARING + Vector3(cos(a) * 3.2, 0, sin(a) * 3.2 + 1.0)
	m.rotation.y = atan2(-cos(a), -sin(a))
	Effects.sparkle(self, m.position + Vector3.UP, Tokens.color("spark-yellow"), 10)
	_chain.append(m)


## Everybody in a ring, Tırıl in the middle: the last hand.
func _ring_of_hands() -> void:
	_hud.clear_hint()
	for id: String in ["tosbi" if GameState.data.character_id != "tosbi" else "pati"]:
		_add_friend()
	_hiril.position = CLEARING + Vector3(-3.2, 0, 1.0)
	boss.position = CLEARING + Vector3(0, 0, 1.0)
	boss.visible = true
	boss.is_sad = true
	boss.add_to_group("dazed")
	Effects.ring(self, CLEARING + Vector3(0, 0.3, 1.0), 4.0, Tokens.color("spark-yellow"), 0.8)
	GameState.bark("s3k5_halka")
	await GameState.dialogue_closed
	_hud.show_hint("Halkanın ortasına gir. Sakinleş'e basılı tut: el uzat.", "Ortaya gir, Sakinleş'e basılı tut!")


func _on_boss_calmed() -> void:
	_phase2 = false
	_hud.clear_hint()
	Pus.fade_to(self, 0.0, 4.0)
	cold_after = 0.0
	for i in 3:
		Effects.ring(self, boss.global_position + Vector3.UP * 0.5, 5.0 + i * 4.0, Color("#fff7ea"), 0.8 + i * 0.3)
	Audio.play("fanfare")
	GameState.bark("s3k5_son")
	await GameState.dialogue_closed
	_drop()


func _drop() -> void:
	drop_pearl("beyaz", CLEARING + Vector3(0, 0, 5.0), "İnci Beyazı", "Mavi Titreme dağıldı")


func _on_pearl(_id: String) -> void:
	GameState.bark("s3k5_inci")
	_refresh()


func _refresh() -> void:
	var d := GameState.data
	var go := d.quest_state(Q1) == "ready" or d.quest_state(Q2) == "ready"
	if go and not _hiril.has_node("Beacon"):
		Beacon.attach(_hiril, 2.6, Tokens.color("spark-white"))
	elif not go and _hiril.has_node("Beacon"):
		_hiril.get_node("Beacon").queue_free()
	if d.quest_state(Q2) != "none":
		boss.visible = boss.visible or not _phase2 and not d.objective_done(Q2, "tiril")
	var fl := lv.get_node_or_null("Flare") as Node3D
	if fl and d.quest_state(Q2) == "active" and not d.has_flag("s3_fisek5") and not fl.has_node("Beacon"):
		Beacon.attach(fl, 3.4, Tokens.color("spark-yellow"))
		_hud.show_hint("Kayıp Ada'nın İşaret Fişeği'ni yak", "İşaret Fişeği'ni yak")


func _run_demo(which: String) -> void:
	match which:
		"island":
			# the whole final: wrong gate, the maze by the drum, Hırıl, the
			# flare, the fight, hide-and-seek, the ring, the pearl, home
			DevTools.auto_dialogue = true
			var d := GameState.data
			_player.global_position = Vector3(GATE_X * -RIGHT_SIDE[0], 0.3, ROOM_Z[0] - 8.6)
			await get_tree().create_timer(0.6, false).timeout
			print("S3K5_WRONG back=%s z=%.1f" % [_player.global_position.z > ROOM_Z[0], _player.global_position.z])
			for n in lv.get_children():
				var bt := n as BeachTorch
				if bt and not bt.lit:
					_player.global_position = bt.global_position + Vector3(0, 0.3, 1.2)
					await get_tree().create_timer(0.4, false).timeout
					_player.interact()
					await get_tree().create_timer(0.2, false).timeout
			await _calm_all()
			for i in ROOM_Z.size():
				_player.global_position = Vector3(GATE_X * RIGHT_SIDE[i], 0.3, ROOM_Z[i] - 8.8)
				await get_tree().create_timer(0.5, false).timeout
			_player.global_position = CLEARING + Vector3(0, 0.3, 9.0)
			await get_tree().create_timer(0.8, false).timeout
			print("S3K5_Q1 state=%s" % d.quest_state(Q1))
			await _talk("hiril", "Hiril")
			_player.global_position = lv.get_node("Flare").global_position + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.5, false).timeout
			_player.interact()
			await close_dialogs()
			print("S3K5_FLARE q2=%s fisek=%s veil=%s" % [d.quest_state(Q2), d.has_flag("s3_fisek5"), _veil.is_open])
			_player.global_position = CLEARING + Vector3(0, 0.3, 7.0)
			for i in 80:
				if fighting:
					break
				await get_tree().create_timer(0.25, false).timeout
			await close_dialogs()
			for i in 2400:
				if _phase2:
					break
				if boss.tired:
					boss.hit(60, _player.global_position, 0.0)
				await get_tree().create_timer(0.1, false).timeout
				if d.hp < 30:
					d.heal(100)
			await close_dialogs()
			print("S3K5_FAZ2 on=%s" % _phase2)
			for i in HIDES.size():
				for k in 40:
					if _glimmer:
						break
					await get_tree().create_timer(0.2, false).timeout
					await close_dialogs()
				_player.global_position = HIDES[i] + Vector3(0, 0.3, 1.2)
				await get_tree().create_timer(0.5, false).timeout
				await close_dialogs()
			await get_tree().create_timer(0.6, false).timeout
			await close_dialogs()
			print("S3K5_FOUND n=%d chain=%d sad=%s" % [_found, _chain.size(), boss.is_sad])
			_player.global_position = boss.global_position + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.3, false).timeout
			Input.action_press("calm")
			for i in 60:
				if not boss.is_sad:
					break
				await get_tree().create_timer(0.2, false).timeout
			Input.action_release("calm")
			await close_dialogs()
			await get_tree().create_timer(0.6, false).timeout
			await close_dialogs()
			_player.global_position = CLEARING + Vector3(0, 0.3, 5.0)
			await get_tree().create_timer(0.8, false).timeout
			await close_dialogs()
			print("S3K5_PEARL tiril=%s inci=%s pus=%.2f" % [d.objective_done(Q2, "tiril"), d.has_flag("inci_beyaz"), Pus.amount])
			DevTools.report_next_scene("S3K5_NEXT")
			await _talk("hiril", "Hiril")
			print("S3K5_DONE q2=%s fisek=%s inci=%s bitti=%s sezon=%s" % [d.quest_state(Q2), d.has_flag("s3_fisek5"), d.has_flag("inci_beyaz"), d.has_flag("s3_bolum5_bitti"), d.has_flag("sezon3_bitti")])
			await get_tree().create_timer(3.0, false).timeout
			get_tree().quit()
