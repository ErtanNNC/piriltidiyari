extends S4Garden
## Sezon 4 · Prolog · Sahne 2 – Yeşil Diken. Contest day: the neighbours eye
## each other's gardens and thin green vines come up over the beds. The first
## Dikenciler (Kapıcı Tavşan, Kıskanç Salyangoz) grab carrots and trample
## flowers. Teaches the strike (they sit dazed), Alkış (a clap calms a dazed
## Dikenci; a clap before a garden pulls its thorns back), the Diken barı
## (explained when it first fills) and Nane Limonata (Tospik Nine's gift).
## Quest "yesil_diken" → `s4_sahne2_bitti` → s4_scene3. Linear scene.

const QUEST := "yesil_diken"
const NEED := 3
const DIKENCILER := [["kapici_tavsan", Vector3(5, 0, 9)], ["kiskanc_salyangoz", Vector3(-4, 0, 1)],
	["kapici_tavsan", Vector3(5, 0, -7)]]

var _patches: Array[ThornPatch] = []
var _next_mob := 0
var _mob_t := 2.0
var _seen := {}
var _ended := false


func _ready() -> void:
	begin_garden("s4_scene2")
	Pus.set_amount(0.05)
	Pus.fade_to(self, 0.22, 5.0)
	S4Village.build(self)
	S4Village.villagers(self)
	S4Village.balloon(_player)
	# thin vines over each garden (thorn patches 0..2: flags s4_scene2_d0..2,
	# read by the owners' dialogue)
	for e: Array in S4Village.GARDENS:
		var c: Vector3 = e[3]
		var t := thorns(c + Vector3(-signf(c.x) * 1.5, 0, 0), 4.5, false, true, "bahce", PI * 0.5)
		t.retracted.connect(func(_t: ThornPatch) -> void: _once("bahce", "s4a_bahce"))
		_patches.append(t)
	# Tırıl's own flower from yesterday
	var mine := plot(S4Village.MY_PLOT, "sifa")
	if not mine.is_grown:
		mine.plant()
		mine._t = 99.0
	Decor.auto(self, "koy")
	var d := GameState.data
	if d.quest_state(QUEST) == "none":
		d.start_quest(Content.quests[QUEST])
	if d.quest_state(QUEST) == "active":
		for i in mini(NEED - d.objective_count(QUEST, "dikenci").x, DIKENCILER.size()):
			_spawn_next()
	d.quest_changed.connect(func(_id: String) -> void: _check())
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.5, false).timeout
	if d.quest_state(QUEST) == "done":
		_end()
		return
	GameState.bark("s4a_diken_basla")
	_check()
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _spawn_next() -> void:
	# the spot farthest from Tırıl, so nothing pops up beside the keeper
	var best := 0
	for k in DIKENCILER.size():
		var i := (_next_mob + k) % DIKENCILER.size()
		if (DIKENCILER[i][1] as Vector3).distance_to(_player.global_position) > 9.0:
			best = i
			break
	dikenci(DIKENCILER[best][0], DIKENCILER[best][1])
	_next_mob = best + 1


func _live_mobs() -> int:
	var n := get_tree().get_nodes_in_group("mob").size()
	for m in get_tree().get_nodes_in_group("dazed"):
		if m is Mob:
			n += 1
	return n


## A line said once per visit.
func _once(key: String, bark_id: String) -> bool:
	if _seen.has(key) or _ended:
		return false
	_seen[key] = true
	GameState.bark(bark_id)
	return true


func _process(delta: float) -> void:
	super._process(delta)
	var d := GameState.data
	if _ended or d.quest_state(QUEST) != "active" or GameState.in_dialogue:
		return
	# never a dead end: a Dikenci that calmed by itself didn't count
	_mob_t -= delta
	if _mob_t <= 0.0:
		_mob_t = 3.0
		var left: int = NEED - d.objective_count(QUEST, "dikenci").x
		if _live_mobs() < left:
			_spawn_next()
	if not _seen.has("dikenci"):
		for m: Node3D in get_tree().get_nodes_in_group("mob"):
			if m.global_position.distance_to(_player.global_position) < 7.0:
				_once("dikenci", "s4a_dikenci")
				_hud.show_hint("J: ışığınla vur. Dikenci sersemleyince dur!", "Vur'a bas. Dikenci sersemleyince dur!")
				return
	if not _seen.has("sersem"):
		for m in get_tree().get_nodes_in_group("dazed"):
			if m is Mob:
				_once("sersem", "s4a_sersem")
				_hud.show_hint("C: alkışla! Sersemleyen Dikencinin yanında dur.", "Yanına git, Alkış'a bas!")
				return
	if not _seen.has("ilk_alkis") and d.objective_count(QUEST, "dikenci").x > 0:
		_once("ilk_alkis", "s4a_ilk_alkis")
		_check()
		return
	if not _seen.has("bar") and _player.clap and _player.clap.thorn > 0.3:
		_once("bar", "s4a_bar")
		_hud.show_hint("Diken barın doluyor! Birini alkışla ya da çantadan Nane Limonata iç.",
			"Diken barın doluyor! Alkışla ya da Nane Limonata iç.")
		get_tree().create_timer(9.0, false).timeout.connect(_check)


func _check() -> void:
	var d := GameState.data
	var st := d.quest_state(QUEST)
	var nine := get_node_or_null("Tospik") as Node3D
	var go := st == "ready" or (st == "active" and not d.objective_done(QUEST, "nine"))
	if nine:
		if go and not nine.has_node("Beacon"):
			Beacon.attach(nine, 2.6, Tokens.color("spark-white"))
		elif not go and nine.has_node("Beacon"):
			nine.get_node("Beacon").queue_free()
	if st == "active":
		if not d.objective_done(QUEST, "nine"):
			_hud.show_hint("Meydandaki Tospik Nine ile konuş", "Tospik Nine ile konuş")
		elif not d.objective_done(QUEST, "dikenci"):
			_hud.show_hint("J: Dikenciyi sersemlet. Sonra C: yanında alkışla!", "Vur: sersemlet. Sonra yanında Alkış'a bas!")
		elif not d.objective_done(QUEST, "bahce"):
			_hud.show_hint("C: komşuların dikenli bahçelerinin önünde alkışla", "Dikenli bahçelerin önünde Alkış'a bas")
	elif st == "ready":
		Pus.fade_to(self, 0.04, 3.0)
		_hud.show_hint("Tospik Nine'ye dön", "Tospik Nine'ye dön")
	elif st == "done" and not _ended:
		_hud.clear_hint()
		while GameState.in_dialogue:
			await get_tree().create_timer(0.2, false).timeout
		_end()


## The vines' roots run off towards the forest (Sahne 3).
func _end() -> void:
	if _ended:
		return
	_ended = true
	var d := GameState.data
	d.set_flag("s4_sahne2_bitti")
	await get_tree().create_timer(0.6, false).timeout
	if DevTools.demo != "":
		print("S4A2_DONE quest=%s flag=%s limonata=%d next=s4_scene3" % [d.quest_state(QUEST), d.has_flag("s4_sahne2_bitti"), d.item_count("nane_limonata")])
	SceneFlow.go_to("s4_scene3")


func _run_demo(which: String) -> void:
	var d := GameState.data
	match which:
		"thorn":
			# the whole scene: Tospik's limonata, a Dikenci left alone doesn't
			# count and another comes, strike + clap ×3, the bar by the thorns,
			# three gardens applauded on foot, back to Tospik, on to Sahne 3
			DevTools.auto_dialogue = true
			print("S4A2_START keeper=%s quest=%s mobs=%d thorns=%d" % [d.character_id, d.quest_state(QUEST), _live_mobs(), _patches.size()])
			await walk_to(Vector3(0, 0, -11.0), 16.0)
			await walk_to(S4Village.TOSPIK_AT + Vector3(-0.6, 0, 2.2), 6.0)
			await close_dialogs()
			GameState.talk_to("tospik_nine")
			await close_dialogs()
			print("S4A2_NINE done=%s limonata=%d" % [d.objective_done(QUEST, "nine"), d.item_count("nane_limonata")])
			# one Dikenci is struck and left: it calms by itself, a new one comes
			var first := get_tree().get_nodes_in_group("mob")[0] as Mob
			_player.global_position = first.global_position + Vector3(0, 0.3, 1.4)
			await get_tree().create_timer(0.2, false).timeout
			first.hit(9999, _player.global_position, 0.0)
			await get_tree().create_timer(0.4, false).timeout
			await close_dialogs()
			_player.global_position = Vector3(0, 0.3, 22.0)
			await get_tree().create_timer(Mob.DAZE_TIME + 4.5, false).timeout
			await close_dialogs()
			print("S4A2_ALONE count=%s live=%d" % [d.objective_count(QUEST, "dikenci"), _live_mobs()])
			for i in 6:
				if d.objective_done(QUEST, "dikenci"):
					break
				await _calm_dikenciler()
				await close_dialogs()
				await get_tree().create_timer(3.5, false).timeout
			await close_dialogs()
			print("S4A2_DIKENCI count=%s" % d.objective_count(QUEST, "dikenci"))
			# stand in the vines: the bar fills and is explained
			var g0: Vector3 = S4Village.GARDENS[0][3]
			await walk_to(Vector3(0, 0, g0.z + 1.0), 12.0)
			await walk_to(g0 + Vector3(3.2, 0, 2.4), 8.0)
			await get_tree().create_timer(4.5, false).timeout
			await close_dialogs()
			print("S4A2_BAR thorn=%.2f told=%s" % [_player.clap.thorn, _seen.has("bar")])
			for i in S4Village.GARDENS.size():
				var at: Vector3 = S4Village.GARDENS[i][3]
				await walk_to(Vector3(0, 0, at.z + 1.0), 12.0)
				await walk_to(at + Vector3(-signf(at.x) * 3.2, 0, 2.4), 8.0)
				_player.clap._cd = 0.0
				var hits := _player.clap.clap()
				await get_tree().create_timer(0.9, false).timeout
				await close_dialogs()
				print("S4A2_CLAP %s hits=%d open=%s count=%s thorn=%.2f" % [S4Village.GARDENS[i][0], hits, _patches[i].is_open, d.objective_count(QUEST, "bahce"), _player.clap.thorn])
				await walk_to(Vector3(0, 0, at.z + 1.0), 8.0)
			GameState.talk_to("nilufer_abla")
			await close_dialogs()
			await walk_to(Vector3(0, 0, -11.0), 12.0)
			await walk_to(S4Village.TOSPIK_AT + Vector3(-0.6, 0, 2.2), 6.0)
			print("S4A2_BACK quest=%s near=%.1f" % [d.quest_state(QUEST), _player.global_position.distance_to(S4Village.TOSPIK_AT)])
			DevTools.report_next_scene("S4A2_NEXT")
			GameState.talk_to("tospik_nine")
