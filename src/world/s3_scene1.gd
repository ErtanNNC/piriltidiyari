extends S3Beach
## Sezon 3 · Prolog · Sahne 1 – Kumsalda Davul Gecesi. After the Gökkuşağı
## Şenliği the village spends its first summer night on the beach. Hırıl is
## the festival's drummer: a steady rhythm (J, `Rhythm`) makes the sand
## castles dance, the friends chat round the fire, Mırıl lights up the sky
## and Fıstık dozes on a deck chair. Teaches walking, the drum and talking.

const QUEST := "davul_gecesi"

var _castles: Array[SandCastle] = []
var _miril: Node3D
var _show_t := 0.0
var _ended := false


func _ready() -> void:
	WorldLook.add(self, "kumsal")
	Pus.set_amount(0.0)
	var lv := _build_beach()
	for i in TORCHES.size():
		var t := BeachTorch.new()
		t.position = TORCHES[i]
		lv.add_child(t)
		t.light_up(true)
	_place_friends(lv, false)
	_add_miril(lv)
	for i in CASTLES.size():
		var c := SandCastle.new()
		c.name = "Castle%d" % i
		c.position = CASTLES[i]
		lv.add_child(c)
		_castles.append(c)
	Decor.auto(self, "kumsal")
	var d := GameState.data
	if d.quest_state(QUEST) == "none":
		d.start_quest(Content.quests[QUEST])
	var done := 3 if d.quest_state(QUEST) in ["ready", "done"] else d.objective_count(QUEST, "kale").x
	for i in mini(done, _castles.size()):
		_castles[i].set_done()
	d.quest_changed.connect(func(_id: String) -> void: _check())
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.4, false).timeout
	if d.quest_state(QUEST) == "done":
		_end()
		return
	GameState.bark("s3_basla")
	_hud.show_hint("J ile davul çal: düzenli vur, kale dans etsin!", "Vur'a düzenli bas: kale dans etsin!")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


## Mırıl floats over the sea and paints the sky with light.
func _add_miril(lv: Node3D) -> void:
	var n := npc(lv, "miril", "star_child", Vector3(4.0, 0, -9.0), 180.0)
	n.name = "Miril"
	_npcs["miril"] = n
	_miril = n
	var tw := n.create_tween().set_loops()
	tw.tween_property(n, "position:y", 0.6, 1.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(n, "position:y", 0.2, 1.6).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	_show_t -= delta
	if _show_t <= 0.0 and _miril:
		_show_t = 1.3
		var cols := ["spark-purple", "sky", "spark-yellow", "berry", "spark-green"]
		var at := Vector3(randf_range(-14, 14), randf_range(7, 11), randf_range(-24, -14))
		Effects.sparkle(self, at, Tokens.color(cols[randi() % cols.size()]), 14)


func _check() -> void:
	var d := GameState.data
	if d.quest_state(QUEST) == "active" and d.objective_done(QUEST, "kale") and not d.has_flag("s3_kaleler"):
		d.set_flag("s3_kaleler")
		GameState.bark("s3_kale")
		_hud.show_hint("Kaleler dans etti! Şimdi arkadaşlarınla konuş.", "Kaleler dans etti! Arkadaşlarınla konuş.")
	if d.quest_state(QUEST) == "ready":
		_hud.show_hint("Ateşin yanında Tospik Nine'ye dön", "Tospik Nine'ye dön")
		if not _npcs["tospik_nine"].has_node("Beacon"):
			Beacon.attach(_npcs["tospik_nine"], 2.6, Tokens.color("spark-white"))
	if d.quest_state(QUEST) == "done" and not _ended:
		_hud.clear_hint()
		if _npcs["tospik_nine"].has_node("Beacon"):
			_npcs["tospik_nine"].get_node("Beacon").queue_free()
		while GameState.in_dialogue:
			await get_tree().create_timer(0.2, false).timeout
		_end()


## The blue mist rolls in from the sea (Sahne 2).
func _end() -> void:
	if _ended:
		return
	_ended = true
	await get_tree().create_timer(0.6, false).timeout
	GameState.bark("s3_son")
	if DevTools.demo == "drum" and DisplayServer.get_name() == "headless":
		await close_dialogs()
		var d := GameState.data
		print("S3_DRUM quest=%s flag=%s level=%d" % [d.quest_state(QUEST), d.has_flag("s3_sahne1_bitti"), d.level])
		get_tree().quit()
		return
	while GameState.in_dialogue:
		await get_tree().create_timer(0.2, false).timeout
	SceneFlow.go_to("s3_scene2")


func _run_demo(which: String) -> void:
	match which:
		"drum":
			# the whole scene: three castles by rhythm, four friends, Tospik
			DevTools.auto_dialogue = true
			var odd := _castles[0]
			_player.global_position = odd.global_position + Vector3(0, 0.3, 2.5)
			for gap: float in [0.6, 0.2, 1.5]:
				# an uneven rhythm doesn't count
				_player.spin_attack()
				await get_tree().create_timer(gap, false).timeout
			print("S3_UNEVEN danced=%s" % odd.danced)
			for c in _castles:
				_player.global_position = c.global_position + Vector3(0, 0.3, 2.5)
				await get_tree().create_timer(1.0, false).timeout
				for i in 5:
					_player.spin_attack()
					await get_tree().create_timer(0.6, false).timeout
			print("S3_CASTLES danced=%d" % _castles.filter(func(c: SandCastle) -> bool: return c.danced).size())
			for id: String in ["pati", "bado", "citir", "lumi", "tipis_panda", "fistik", "miril", "tospik_nine"]:
				_player.global_position = _npcs[id].global_position + Vector3(0, 0.3, 1.6)
				await get_tree().create_timer(0.3, false).timeout
				GameState.talk_to(id)
				await close_dialogs()
				print("S3_TALK %s quest=%s" % [id, GameState.data.quest_state(QUEST)])
