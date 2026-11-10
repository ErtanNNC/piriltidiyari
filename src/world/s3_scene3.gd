extends S3Island
## Sezon 3 · Prolog · Sahne 3 – Kıyı Yolu. A thin trembling voice in the
## mist ("Kimse beni bulmayacak...") leads Hırıl up the rocky shore path.
## On the way sits Tosbi, Tospik Nine's grandson, frozen with fear: the
## first hand to hold. Hand in hand the two light rings join, the dark
## Titreme Perdesi opens, and at the big torch Hırıl levels up and learns
## Gümbür Dalgası. Stages follow the quest "kiyi_yolu".
##
## Layout (−z is up the path, the sea on the left): dark shore z 14..−16 ·
## veil z −18 · rock steps z −22..−30 (top 1.5) · ledge z −30..−58 with the
## big torch at z −40 and the pass at z −55.

const QUEST := "kiyi_yolu"
const ROCK := Color("#8f8aa0")
const ROCK_DARK := Color("#6a6680")
const SAND := Color("#b8a27a")
const TOP := 1.5
const TOSBI_AT := Vector3(2.0, 0, -11.0)
const BIG_TORCH := Vector3(0, TOP, -40.0)
const PASS_AT := Vector3(0, TOP, -55.0)

var _tosbi: HandFriend
var _big: BeachTorch
var _wave_told := false


func _ready() -> void:
	begin("s3_scene3")
	Pus.set_amount(0.45)
	_build()
	Decor.auto(self, "kumsal")
	var d := GameState.data
	if d.quest_state(QUEST) == "none":
		d.start_quest(Content.quests[QUEST])
	d.quest_changed.connect(func(_id: String) -> void: _check())
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.5).timeout
	GameState.bark("s3c_basla")
	_hud.show_hint("Sesin peşinden git. Meşaleleri yak: ışık yolu güvenli yapar.", "Meşaleleri yak, yoldan git.")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _build() -> void:
	# the shore: sand below, a rock ledge further up, cliffs on the right
	land(Vector3(0, 0, -4), Vector2(18, 40), SAND)
	for i in 3:
		var h := TOP * (i + 1) / 3.0
		land(Vector3(0, 0, -23.0 - i * 1.2), Vector2(8, 1.2), ROCK, h)
		land(Vector3(-6.5, 0, -23.0 - i * 1.2), Vector2(5, 1.2), ROCK_DARK, 0.0)
		land(Vector3(6.5, 0, -23.0 - i * 1.2), Vector2(5, 1.2), ROCK_DARK, 0.0)
	land(Vector3(0, 0, -42.5), Vector2(18, 33), ROCK, TOP)
	ModelImport.cover_row(WorldLook.block(lv, Vector3(10.2, 3.0, -22), Vector3(2.4, 8, 76), ROCK_DARK), ["kiyi_kaya", "koy_kaya"], 6.0)
	ModelImport.cover_row(WorldLook.block(lv, Vector3(0, 3.0, -60.2), Vector3(22, 8, 2.4), ROCK_DARK), ["kiyi_kaya", "koy_kaya"], 6.0)
	for k: Array in [[Vector3(0, 6, 16.5), Vector3(24, 12, 1)], [Vector3(-9.5, 6, -22), Vector3(1, 12, 78)]]:
		var wall := StaticBody3D.new()
		wall.set_meta("camera_ignore", true)
		var c := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = k[1]
		c.shape = b
		wall.add_child(c)
		wall.position = k[0]
		lv.add_child(wall)
	# dark shore: two torches make a safe path
	torch(Vector3(-3.0, 0, 5.0))
	torch(Vector3(3.5, 0, -4.0))
	for e: Array in [["titrek_yengec", Vector3(-4, 0, -1)], ["urkek_marti", Vector3(5, 0, 7)]]:
		titrek(e[0], e[1])
	# Tosbi, frozen by the path; the veil only opens hand in hand
	var d := GameState.data
	_tosbi = friend("tosbi", "tosbi", TOSBI_AT, BIG_TORCH + Vector3(0, 0, 1.5))
	_tosbi.name = "Tosbi"
	_tosbi.goal_radius = 3.0
	_tosbi.held.connect(func() -> void:
		GameState.bark("s3c_el")
		_hud.show_hint("El ele: ışığınız büyüdü! Birlikte sis perdesinden geçin.", "El ele sis perdesinden geçin."))
	_tosbi.arrived.connect(_on_tosbi_arrived)
	veil(Vector3(0, 0, -18.0), 18.0, "s3c_perde", true)
	# the big torch on the ledge and the frightened ones behind it
	_big = torch(BIG_TORCH + Vector3(2.5, 0, 0), "buyuk_mesale")
	_big.light_up(true)
	if d.objective_done(QUEST, "tosbi"):
		_tosbi.global_position = BIG_TORCH + Vector3(-1.5, 0, 1.0)
		_tosbi.done = true
		_tosbi._area.queue_free()
		if _tosbi.has_node("Beacon"):
			_tosbi.get_node("Beacon").queue_free()
	for e: Array in [["titrek_yengec", Vector3(-5, TOP, -47)], ["urkek_marti", Vector3(4, TOP, -49)], ["titrek_yengec", Vector3(0, TOP, -51)]]:
		titrek(e[0], e[1])
	var t := TriggerArea.new()
	t.area_id = "kayaliklar"
	t.radius = 3.0
	t.position = PASS_AT
	lv.add_child(t)
	TravelSign.board(lv, "Kayalıklar ↑", PASS_AT + Vector3(-4.0, 1.4, 1.0), 2.4)
	Toon.part(lv, "box", Vector3(0.16, 1.3, 0.16), Color("#a86b45"), PASS_AT + Vector3(-4.0, 0.65, 0.95))


func _process(delta: float) -> void:
	super._process(delta)
	if not _player.ring:
		return
	# the mist is cold all along the path (torches and a held hand help)
	_player.ring.cold = 1.0
	var d := GameState.data
	if not d.has_flag("s3c_tosbi_gor") and _player.global_position.distance_to(TOSBI_AT) < 6.0 and not GameState.in_dialogue:
		d.set_flag("s3c_tosbi_gor")
		GameState.bark("s3c_tosbi")
		_hud.show_hint("Tosbi donakalmış. Yanına git ve elini tut.", "Tosbi'nin yanına git, El tut'a bas.")


func _on_tosbi_arrived() -> void:
	var d := GameState.data
	_hud.clear_hint()
	GameState.bark("s3c_mesale")
	await GameState.dialogue_closed
	# the first level-up, and Hırıl's drum wave
	while d.level < 2:
		d.add_xp(Progression.xp_to_next(d.level) - d.xp)
	if d.unlock_skill("gumbur_dalgasi"):
		GameState.toast.emit(TranslationServer.translate("Yeni yetenek: %s!") % TranslationServer.translate("Gümbür Dalgası"), "spark")
	_hud.show_hint("L: Gümbür Dalgası. Çevrendeki bütün Titrekler durup dinler!", "Dalga düğmesi: bütün Titrekler dinler!")


func _check() -> void:
	var d := GameState.data
	if d.objective_done(QUEST, "titrek") and not d.objective_done(QUEST, "gecit") and not _wave_told:
		_wave_told = true
		_hud.show_hint("Yol açık. Kayalıklara çık!", "Kayalıklara çık!")
	if d.quest_state(QUEST) in ["ready", "done"] and not d.has_flag("s3_sahne3_bitti"):
		d.set_flag("s3_sahne3_bitti")
		if d.quest_state(QUEST) == "ready":
			d.complete_quest(Content.quests[QUEST])
		_end()


func _end() -> void:
	_hud.clear_hint()
	GameState.bark("s3c_son")
	if DevTools.demo == "path" and DisplayServer.get_name() == "headless":
		await close_dialogs()
		var d := GameState.data
		print("S3_PATH quest=%s flag=%s level=%d skill=%s" % [d.quest_state(QUEST), d.has_flag("s3_sahne3_bitti"), d.level, d.active_skill()])
		get_tree().quit()
		return
	await GameState.dialogue_closed
	SceneFlow.go_to("s3_scene4")


func _run_demo(which: String) -> void:
	match which:
		"path":
			# the whole path: torches, the veil stays shut alone, Tosbi's
			# hand opens it, the wave stills the Titrekler, the pass
			DevTools.auto_dialogue = true
			for n in lv.get_children():
				var bt := n as BeachTorch
				if bt and not bt.lit:
					_player.global_position = bt.global_position + Vector3(0, 0.3, 1.2)
					await get_tree().create_timer(0.4).timeout
					_player.interact()
					await get_tree().create_timer(0.3).timeout
			await close_dialogs()
			_player.global_position = Vector3(0, 0.3, -16.0)
			Input.action_press("move_forward")
			await get_tree().create_timer(1.5).timeout
			Input.action_release("move_forward")
			print("S3_VEIL alone z=%.1f blocked=%s" % [_player.global_position.z, _player.global_position.z > -18.0])
			_player.global_position = TOSBI_AT + Vector3(0, 0.3, 1.3)
			await get_tree().create_timer(0.6).timeout
			await close_dialogs()
			_player.interact()
			await close_dialogs()
			print("S3_HAND holding=%s ring=%.1f" % [_tosbi.holding, _player.ring.radius])
			_player.global_position = Vector3(0, 0.3, -16.0)
			Input.action_press("move_forward")
			await get_tree().create_timer(1.6).timeout
			Input.action_release("move_forward")
			print("S3_VEIL hand z=%.1f through=%s" % [_player.global_position.z, _player.global_position.z < -18.5])
			_player.global_position = BIG_TORCH + Vector3(0, 0.4, 3.0)
			await get_tree().create_timer(1.5).timeout
			await close_dialogs()
			await get_tree().create_timer(1.0).timeout
			await close_dialogs()
			print("S3_TOSBI done=%s level=%d skill=%s" % [_tosbi.done, GameState.data.level, GameState.data.active_skill()])
			for i in 12:
				var left := get_tree().get_nodes_in_group("titrek").filter(func(t: Titrek) -> bool: return t.state != "calm" and t.global_position.z < -40.0)
				if left.is_empty():
					break
				var t: Titrek = left[0]
				_player.global_position = t.global_position + Vector3(0, 0.3, 4.0)
				await get_tree().create_timer(0.3).timeout
				GameState.data.mp = GameState.data.max_mp
				_player.use_skill()
				await get_tree().create_timer(0.4).timeout
				print("S3_WAVE %s state=%s" % [t.kind, t.state])
				_player.global_position = t.global_position + Vector3(0, 0.3, 1.2)
				await get_tree().create_timer(0.8).timeout
			_player.global_position = PASS_AT + Vector3(0, 0.3, 1.0)
