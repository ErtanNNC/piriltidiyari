extends S4Garden
## Sezon 4 · Prolog · Sahne 1 – İlk Bahar. Tırıl's first spring on land:
## Gökkuşağı Köyü gets ready for the Çiçek Yarışması. Tırıl floats about in
## a water balloon (hold jump while falling), meets three neighbours at
## their gardens, plants a first seed ("Ek") and waters it ("Sula": the
## sprout waits for water, then grows). Tospik Nine, head of the jury, says
## the best-loved garden wins; nobody listens. Quest "ilk_bahar" →
## `s4_sahne1_bitti` → s4_scene2. Linear: always starts from the beginning.

const QUEST := "ilk_bahar"

var _plot: SeedPlot
var _water: S4Village.Spot
var _sown := false
var _ended := false


func _ready() -> void:
	begin_garden("s4_scene1")
	Pus.set_amount(0.0)
	S4Village.build(self)
	S4Village.villagers(self)
	S4Village.balloon(_player)
	_plot = plot(S4Village.MY_PLOT, "sifa")
	_plot.grown.connect(func(_p: SeedPlot) -> void:
		GameState.bark("s4a_cicek")
		_check())
	Decor.auto(self, "koy")
	var d := GameState.data
	if d.quest_state(QUEST) == "none":
		d.start_quest(Content.quests[QUEST])
	if _plot.is_grown:
		# grown on an earlier visit: both steps count
		GameState.notify("collect", "ekim")
		GameState.notify("collect", "su")
	d.quest_changed.connect(func(_id: String) -> void: _check())
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.4, false).timeout
	if d.quest_state(QUEST) == "done":
		_end()
		return
	GameState.bark("s4a_basla")
	_check()
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _process(delta: float) -> void:
	super._process(delta)
	if not _sown and _plot._planted and not _plot.is_grown:
		_on_sown()


## The seed is in: the sprout stays tiny until Tırıl waters it.
func _on_sown() -> void:
	_sown = true
	_plot.set_process(false)
	_plot.done()
	GameState.notify("collect", "ekim")
	GameState.bark("s4a_ekim")
	_water = S4Village.Spot.new()
	_water.name = "Water"
	_water.action_label = "Sula"
	_water.reach = 1.6
	_water.position = _plot.position
	lv.add_child(_water)
	Beacon.attach(_water, 1.6, Tokens.color("sky"))
	_water.used.connect(_on_watered)
	_check()


func _on_watered() -> void:
	if _water == null:
		return
	_water.done()
	_water.queue_free()
	_water = null
	Audio.play("pop")
	var at := _plot.global_position
	for i in 3:
		Effects.sparkle(self, at + Vector3(0, 1.4 - i * 0.4, 0), Tokens.color("sky"), 8)
	Effects.ring(self, at + Vector3.UP * 0.15, 1.6, Tokens.color("sky"), 0.5)
	GameState.notify("collect", "su")
	# watered: it opens in a moment
	_plot._t = maxf(Growth.seconds("sifa") - 1.5, 0.0)
	_plot.set_process(true)


func _talks_left() -> int:
	var d := GameState.data
	var n := 0
	for o: String in ["havuc", "kok", "nilufer"]:
		if not d.objective_done(QUEST, o):
			n += 1
	return n


func _check() -> void:
	var d := GameState.data
	var st := d.quest_state(QUEST)
	var nine := get_node_or_null("Tospik") as Node3D
	if st == "active":
		if _talks_left() > 0:
			_hud.show_hint("Bahçelerdeki üç komşunla konuş. Zıplayınca Boşluk'u bırakma: süzülürsün!",
				"Üç komşunla konuş. Zıpla'ya basılı tut: süzülürsün!")
		elif not d.objective_done(QUEST, "ek"):
			_hud.show_hint("Yolun sağındaki toprağa git, E ile tohumunu ek", "Sağdaki toprağa git, Ek'e bas")
		elif not d.objective_done(QUEST, "su"):
			_hud.show_hint("Filiz susamış. E ile su balonundan sula!", "Filiz susamış: Sula'ya bas!")
	elif st == "ready":
		_hud.show_hint("Meydandaki Tospik Nine'ye git", "Tospik Nine'ye git")
		if nine and not nine.has_node("Beacon"):
			Beacon.attach(nine, 2.6, Tokens.color("spark-white"))
	elif st == "done" and not _ended:
		_hud.clear_hint()
		if nine and nine.has_node("Beacon"):
			nine.get_node("Beacon").queue_free()
		while GameState.in_dialogue:
			await get_tree().create_timer(0.2, false).timeout
		_end()


## Nobody heard her: everyone is busy measuring flowers (Sahne 2).
func _end() -> void:
	if _ended:
		return
	_ended = true
	var d := GameState.data
	d.set_flag("s4_sahne1_bitti")
	await get_tree().create_timer(0.6, false).timeout
	GameState.bark("s4a_son")
	if DevTools.demo != "":
		await close_dialogs()
		print("S4A1_DONE quest=%s flag=%s next=s4_scene2" % [d.quest_state(QUEST), d.has_flag("s4_sahne1_bitti")])
	while GameState.in_dialogue:
		await get_tree().create_timer(0.2, false).timeout
	SceneFlow.go_to("s4_scene2")


func _run_demo(which: String) -> void:
	var d := GameState.data
	match which:
		"spring":
			# the whole scene on foot: float, three neighbours, seed, water,
			# the flower, Tospik Nine, on to Sahne 2
			DevTools.auto_dialogue = true
			print("S4A1_START keeper=%s quest=%s balloon=%s clap=%s" % [d.character_id, d.quest_state(QUEST), _player.has_node("WaterBalloon"), _player.clap != null])
			var air := [0.0, 0.0]
			for k in 2:
				# a plain jump, then one with jump held: the balloon floats
				Input.action_press("jump")
				await get_tree().physics_frame
				await get_tree().physics_frame
				if k == 0:
					Input.action_release("jump")
				var t := 0.0
				await get_tree().create_timer(0.1, false).timeout
				while not _player.is_on_floor() and t < 6.0:
					await get_tree().physics_frame
					t += get_physics_process_delta_time()
				Input.action_release("jump")
				air[k] = t
				await get_tree().create_timer(0.3, false).timeout
			print("S4A1_FLOAT plain=%.2f held=%.2f floats=%s" % [air[0], air[1], air[1] > air[0] + 0.3])
			for e: Array in S4Village.GARDENS:
				var n := get_node(String(e[2])) as Node3D
				await walk_to(Vector3(0, 0, n.global_position.z), 10.0)
				await walk_to(n.global_position + Vector3(-signf(n.global_position.x) * 1.7, 0, 0), 8.0)
				var near := _player.global_position.distance_to(n.global_position)
				GameState.talk_to(e[0])
				await close_dialogs()
				print("S4A1_TALK %s near=%.1f left=%d" % [e[0], near, _talks_left()])
				await walk_to(Vector3(0, 0, n.global_position.z), 8.0)
			await walk_to(Vector3(0, 0, S4Village.MY_PLOT.z + 1.2), 10.0)
			await walk_to(S4Village.MY_PLOT + Vector3(0, 0, 1.1), 6.0)
			await get_tree().create_timer(0.4, false).timeout
			_player.interact()
			await get_tree().create_timer(0.5, false).timeout
			await close_dialogs()
			await get_tree().create_timer(2.0, false).timeout
			print("S4A1_SOW planted=%s ek=%s waits=%s" % [_plot._planted, d.objective_done(QUEST, "ek"), not _plot.is_grown])
			_player.interact()
			for i in 40:
				if _plot.is_grown:
					break
				await get_tree().create_timer(0.25, false).timeout
			await close_dialogs()
			print("S4A1_WATER su=%s grown=%s quest=%s" % [d.objective_done(QUEST, "su"), _plot.is_grown, d.quest_state(QUEST)])
			await walk_to(Vector3(0, 0, S4Village.MY_PLOT.z), 8.0)
			await walk_to(Vector3(0, 0, -11.0), 14.0)
			await walk_to(S4Village.TOSPIK_AT + Vector3(-0.6, 0, 2.2), 6.0)
			print("S4A1_SQUARE near=%.1f" % _player.global_position.distance_to(S4Village.TOSPIK_AT))
			DevTools.report_next_scene("S4A1_NEXT")
			GameState.talk_to("tospik_nine")
