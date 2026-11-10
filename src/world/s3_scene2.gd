extends S3Beach
## Sezon 3 · Prolog · Sahne 2 – Mavi Titreme. A pale blue mist rolls in
## from the sea: the beach goes dark, the torches go out, friends huddle
## and shiver, and the first Titrekler (Titrek Yengeç, Ürkek Martı) run
## and bump into you. Teaches the light ring (relight the torches), the
## calm rhythm (frightened ones stop and listen), the Titreme barı and
## Sıcak Kakao. Stages follow the quest "mavi_titreme".

const QUEST := "mavi_titreme"
const BLUE := Color(0.7, 0.86, 1.25)
const TITREKS := [["titrek_yengec", Vector3(-10, 0, -7)], ["urkek_marti", Vector3(11, 0, -1)],
	["titrek_yengec", Vector3(6, 0, -8)], ["urkek_marti", Vector3(-14, 0, 2)]]

var _torches: Array[BeachTorch] = []
var _seen_titrek := false
var _seen_listen := false
var _seen_frozen := false
var _ended := false


func _ready() -> void:
	WorldLook.add(self, "kumsal")
	Pus.set_color(BLUE)
	Pus.set_amount(0.15)
	Pus.fade_to(self, 0.55, 5.0)
	var lv := _build_beach()
	var d := GameState.data
	for i in TORCHES.size():
		var t := BeachTorch.new()
		t.position = TORCHES[i]
		lv.add_child(t)
		_torches.append(t)
	if d.quest_state(QUEST) in ["ready", "done"]:
		for t in _torches:
			t.light_up(true)
	else:
		for i in mini(d.objective_count(QUEST, "mesale").x, _torches.size()):
			_torches[i].light_up(true)
	_place_friends(lv, true)
	Decor.auto(self, "kumsal")
	if d.quest_state(QUEST) == "none":
		d.start_quest(Content.quests[QUEST])
	if d.quest_state(QUEST) == "active":
		var left: int = TITREKS.size() - d.objective_count(QUEST, "titrek").x
		for i in left:
			var t := Titrek.new()
			t.kind = TITREKS[i][0]
			t.position = TITREKS[i][1]
			add_child(t)
	d.quest_changed.connect(func(_id: String) -> void: _check())
	_player.respawn_point = _player.global_position
	if DevTools.demo == "resume":
		# a save from before Sahne 3 existed: the scene was done, nothing came next
		DevTools.auto_dialogue = true
		DevTools._finish(d, QUEST)
		get_tree().create_timer(1.0).timeout.connect(func() -> void: DevTools.report_next_scene("S3_RESUME"))
	await get_tree().create_timer(1.5).timeout
	if d.quest_state(QUEST) == "done":
		_end()
		return
	GameState.bark("s3b_basla")
	_hud.show_hint("Sönmüş meşalelere git ve yak. Işık titremeyi geçirir.", "Meşalelere git, Yak'a bas.")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _process(_delta: float) -> void:
	if not _player.ring:
		return
	var d := GameState.data
	# the mist is cold until the beach is lit again
	_player.ring.cold = 0.0 if d.quest_state(QUEST) in ["ready", "done"] else 1.0
	if not _seen_titrek:
		for t: Titrek in get_tree().get_nodes_in_group("titrek"):
			if t.global_position.distance_to(_player.global_position) < 6.0:
				_seen_titrek = true
				GameState.bark("s3b_titrek")
				_hud.show_hint("Kovalama! J ile düzenli davul çal: durup dinlerler.", "Kovalama! Vur'a düzenli bas.")
				break
	if not _seen_listen:
		for t: Titrek in get_tree().get_nodes_in_group("titrek"):
			if t.state == "listening":
				_seen_listen = true
				GameState.bark("s3b_dinle")
				_hud.show_hint("Dinlerken yanına git: ışığın onu ısıtır.", "Dinlerken yanına git.")
				break
	if not _seen_frozen and _player.ring.is_frozen():
		_seen_frozen = true
		GameState.bark("s3b_don")


func _check() -> void:
	var d := GameState.data
	if d.quest_state(QUEST) == "ready":
		Pus.fade_to(self, 0.25, 3.0)
		_hud.show_hint("Ateşin yanında Tospik Nine'ye dön", "Tospik Nine'ye dön")
		if not _npcs["tospik_nine"].has_node("Beacon"):
			Beacon.attach(_npcs["tospik_nine"], 2.6, Tokens.color("spark-white"))
	if d.quest_state(QUEST) == "done" and not _ended:
		_hud.clear_hint()
		if _npcs["tospik_nine"].has_node("Beacon"):
			_npcs["tospik_nine"].get_node("Beacon").queue_free()
		while GameState.in_dialogue:
			await get_tree().create_timer(0.2).timeout
		_end()


## A thin voice from far over the sea: on to the shore path (Sahne 3).
func _end() -> void:
	if _ended:
		return
	_ended = true
	await get_tree().create_timer(0.6).timeout
	GameState.bark("s3b_son")
	if DevTools.demo == "shiver" and DisplayServer.get_name() == "headless":
		await close_dialogs()
		var d := GameState.data
		print("S3_SHIVER quest=%s flag=%s kakao=%d level=%d" % [d.quest_state(QUEST), d.has_flag("s3_sahne2_bitti"), d.item_count("sicak_kakao"), d.level])
		get_tree().quit()
		return
	while GameState.in_dialogue:
		await get_tree().create_timer(0.2).timeout
	SceneFlow.go_to("s3_scene3")


func _run_demo(which: String) -> void:
	match which:
		"shiver":
			# the whole scene: get frozen in the dark, thaw with a breath,
			# light the torches, drum the Titrekler still, calm them, Tospik
			DevTools.auto_dialogue = true
			_player.global_position = Vector3(16, 0.3, 12)
			for i in 60:
				if _player.ring.is_frozen():
					break
				await get_tree().create_timer(0.5).timeout
			print("S3_FROZEN shiver=%.2f frozen=%s" % [_player.ring.shiver, _player.ring.is_frozen()])
			await close_dialogs()
			_player.ring.frozen = ShiverRules.FROZEN_TIME
			Input.action_press("calm")
			await get_tree().create_timer(1.2).timeout
			Input.action_release("calm")
			print("S3_THAW frozen=%s" % _player.ring.is_frozen())
			for t in _torches:
				_player.global_position = t.global_position + Vector3(0, 0.3, 1.2)
				await get_tree().create_timer(0.4).timeout
				_player.interact()
				await get_tree().create_timer(0.3).timeout
			print("S3_TORCHES lit=%d shiver=%.2f" % [_torches.filter(func(t: BeachTorch) -> bool: return t.lit).size(), _player.ring.shiver])
			for i in 30:
				var left := get_tree().get_nodes_in_group("titrek").filter(func(t: Titrek) -> bool: return t.state != "calm")
				if left.is_empty():
					break
				var t: Titrek = left[0]
				_player.global_position = t.global_position + Vector3(0, 0.3, 5.5)
				for k in 4:
					_player.spin_attack()
					await get_tree().create_timer(0.6).timeout
				print("S3_LISTEN %s state=%s" % [t.kind, t.state])
				_player.global_position = t.global_position + Vector3(0, 0.3, 1.2)
				await get_tree().create_timer(0.5).timeout
			_player.global_position = _npcs["tospik_nine"].global_position + Vector3(0, 0.3, 1.8)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("tospik_nine")
			await close_dialogs()
