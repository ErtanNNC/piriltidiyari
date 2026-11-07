extends ChapterBase
## Bölüm 5 – Pus Kalesi (the final). Through Mırıl's grey castle, room by
## room, showing each Kıvılcım to the Pus-curtained doors and finding his
## memories; up to the top, where Gölge Prens Mırıl waits.
##   Faz 1 – a fight (Miril / MirilPlan)
##   Faz 2 – no fighting: offer the four sparks; each lights a memory.

const QUEST := "pus_kalesi"
const X := 12.0
const STONE := Color("#5a5578")
const FLOOR := Color("#4a4560")
const TOP := Vector3(0, 4, -76)

var _miril: Miril
var _offer_btn: Button
var _offered := 0


func _ready() -> void:
	WorldLook.add(self, "kale")
	Decor.auto(self, "kale")
	var d := GameState.data
	if d.quest_state(QUEST) == "none":
		d.start_quest(Content.quests[QUEST])
	Pus.set_amount(0.6 if not d.objective_done(QUEST, "fener") else 0.5)
	_player.carry_light()
	_build()
	d.quest_changed.connect(func(_id: String) -> void: _advance())
	if d.objective_done(QUEST, "fener"):
		$Level/KaleFeneri.light_up(true)
	await get_tree().create_timer(1.9).timeout
	if DevTools.demo != "":
		_run_demo(DevTools.demo)
		return
	if not d.objective_done(QUEST, "fener"):
		GameState.bark("c5_giris")
		_hud.show_hint("Kale Feneri'ni yak", "Kale Feneri'ni yak")


func _advance() -> void:
	var d := GameState.data
	if d.objective_done(QUEST, "fener") and not d.objective_done(QUEST, "kapilar"):
		_hud.show_hint("Kapıya Kıvılcımını göster", "Kapıya Kıvılcımını göster")
	elif d.objective_done(QUEST, "kapilar") and not d.objective_done(QUEST, "miril"):
		_hud.show_hint("Kalenin tepesine çık", "")


# --- level -------------------------------------------------------------------

func _build() -> void:
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	WorldLook.block(lv, Vector3(0, -0.5, -2), Vector3(X * 2, 1, 100), FLOOR, 0.0)
	WorldLook.block(lv, Vector3(0, 2.0, -74), Vector3(X * 2, 4, 28), FLOOR)
	MountainKit.ramp(lv, 0, 5, -50, 0, -60, 4, STONE)
	for side in [-1.0, 1.0]:
		_wall(lv, Vector3(side * X, 0, 48), Vector3(side * X, 0, -60))
		_wall(lv, Vector3(side * X, 4, -60), Vector3(side * X, 4, -88))
	_wall(lv, Vector3(-X, 0, 48), Vector3(X, 0, 48))
	_wall(lv, Vector3(-X, 4, -88), Vector3(X, 4, -88))
	# the yard and Kale Feneri
	var f := SmallLantern.new()
	f.name = "KaleFeneri"
	f.big = true
	f.accent = "spark-purple"
	f.lantern_id = "kale_feneri"
	f.position = Vector3(-3, 0, 36)
	lv.add_child(f)
	f.lit.connect(func(_l: SmallLantern) -> void:
		GameState.notify("light", "kale_feneri")
		Pus.fade_to(self, 0.5, 2.0)
		GameState.bark("c5_fener")
		SaveGame.write(GameState.data))
	var back := TravelSign.new()
	back.target_scene = "chapter0"
	back.title = "Gökkuşağı Köyü"
	back.action = "Köye dön"
	back.position = Vector3(4, 0, 43)
	lv.add_child(back)
	# rooms divided by walls with a spark door each
	var doors := [[24.0, "green"], [4.0, "blue"], [-18.0, "yellow"], [-40.0, "white"]]
	for dd: Array in doors:
		var z: float = dd[0]
		_wall(lv, Vector3(-X, 0, z), Vector3(-3.0, 0, z))
		_wall(lv, Vector3(3.0, 0, z), Vector3(X, 0, z))
		var door := SparkDoor.new()
		door.spark = dd[1]
		door.position = Vector3(0, 0, z)
		lv.add_child(door)
		door.opened.connect(func(_dr: SparkDoor) -> void:
			Pus.fade_to(self, maxf(Pus.amount - 0.08, 0.2), 1.2)
			GameState.bark("c5_kapi")
			SaveGame.write(GameState.data))
	_toy_room(lv)
	_birthday_hall(lv)
	_star_gallery(lv)
	_lantern_room(lv)
	for spec in [[Vector3(-4, 0, 30)], [Vector3(5, 0, 14)], [Vector3(-5, 0, -8)], [Vector3(4, 0, -30)], [Vector3(-3, 0, -34)]]:
		Mob.spawn(self, "golge_kopya", spec[0])
	var arena := TriggerArea.new()
	arena.area_id = "kale_tepesi"
	arena.radius = 3.0
	arena.checkpoint = true
	arena.position = Vector3(0, 4, -62.5)
	lv.add_child(arena)
	arena.reached.connect(_start_final)
	_player.respawn_point = _player.global_position


func _wall(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var mid := (a + b) * 0.5
	var length := a.distance_to(b)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 6.0, 1.2)
	c.shape = box
	c.position.y = 3.0
	body.add_child(c)
	parent.add_child(body)
	body.position = mid
	body.rotation.y = atan2(-(b.z - a.z), b.x - a.x)
	Toon.part(body, "box", Vector3(length, 3.0, 1.2), STONE, Vector3(0, 1.5, 0), Vector3.ZERO, 0.0, 0.03)
	var n := maxi(1, int(length / 1.6))
	for i in n:
		if i % 2 == 0:
			Toon.part(body, "box", Vector3(0.8, 0.6, 1.3), STONE.lightened(0.1), Vector3(-length * 0.5 + (i + 0.5) * length / n, 3.3, 0), Vector3.ZERO, 0.0, 0.02)


func _memory(parent: Node3D, n: int, at: Vector3) -> void:
	var m := MemoryItem.new()
	m.memory = n
	m.position = at
	parent.add_child(m)


func _toy_room(lv: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in 10:
		var at := Vector3(rng.randf_range(-10, 10), 0.4, rng.randf_range(8, 22))
		if absf(at.x) < 3.0:
			continue
		Toon.part(lv, "box", Vector3(0.8, 0.8, 0.8), ["berry", "sky", "honey", "spark-purple"][i % 4], at, Vector3(0, rng.randf() * 90, 0))
	# a rocking horse
	Toon.part(lv, "capsule", Vector3(0.8, 1.8, 0.8), Color("#c98d5e"), Vector3(8, 1.0, 20), Vector3(0, 0, 90))
	Toon.part(lv, "sphere", Vector3(0.8, 0.8, 0.7), Color("#c98d5e"), Vector3(9.2, 1.6, 20))
	Toon.part(lv, "torus", Vector3(2.4, 0.15, 2.4), "berry", Vector3(8, 0.3, 20), Vector3(90, 0, 0))
	_memory(lv, 1, Vector3(-8, 0, 12))
	var st := StoryStone.new()
	st.stone = 9
	st.position = Vector3(8, 0, 9)
	lv.add_child(st)


func _birthday_hall(lv: Node3D) -> void:
	WorldLook.block(lv, Vector3(-6, 0.5, -6), Vector3(2.4, 1.0, 12), Color("#a86b45"))
	for i in 6:
		var z := -11.0 + i * 2.0
		Toon.part(lv, "cylinder", Vector3(0.8, 0.06, 0.8), Color("#e8e2ff"), Vector3(-6, 1.04, z), Vector3.ZERO, 0.0, 0.02)
	Toon.part(lv, "cylinder", Vector3(1.4, 0.8, 1.4), Color("#d9cfe6"), Vector3(-6, 1.4, -6))
	for i in 5:
		Toon.part(lv, "cylinder", Vector3(0.08, 0.4, 0.08), Color("#e8e2ff"), Vector3(-6 + (i - 2) * 0.25, 2.0, -6), Vector3.ZERO, 0.0, 0.0)
	for z in [-14.0, -8.0, -2.0]:
		Toon.part(lv, "torus", Vector3(3.0, 0.08, 3.0), "pus", Vector3(0, 3.6, z), Vector3(90, 0, 0), 0.0, 0.0)
	_memory(lv, 2, Vector3(6, 0, -10))


func _star_gallery(lv: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 24:
		Toon.part(lv, "sphere", Vector3(0.24, 0.08, 0.24), "spark-white", Vector3(rng.randf_range(-11, 11), 0.05, rng.randf_range(-38, -20)), Vector3.ZERO, 0.6, 0.0)
	_memory(lv, 3, Vector3(-7, 0, -27))
	var st := StoryStone.new()
	st.stone = 10
	st.position = Vector3(8, 0, -36)
	lv.add_child(st)


func _lantern_room(lv: Node3D) -> void:
	for i in 8:
		var a := TAU * i / 8.0
		Toon.part(lv, "sphere", Vector3(0.5, 0.6, 0.5), "spark-off", Vector3(sin(a) * 8.0, 0.4, -45 + cos(a) * 3.5), Vector3.ZERO, 0.0, 0.02)
	_memory(lv, 4, Vector3(5, 0, -45))


# --- the final ---------------------------------------------------------------

func _start_final() -> void:
	var d := GameState.data
	if _miril != null or d.objective_done(QUEST, "miril"):
		return
	_miril = Miril.new()
	add_child(_miril)
	_miril.position = TOP
	_miril.hp_changed.connect(func(h: int, m: int) -> void: _hud.set_boss_hp(h, m))
	_miril.shadow_calm.connect(_faz2)
	boss_camera(true, TOP + Vector3(0, 2, 5), 0.5, 22.0)
	if DevTools.demo == "":
		GameState.bark("c5_miril_basla")
		await GameState.dialogue_closed
	_hud.show_boss("Gölge Prens Mırıl", _miril.hp, MirilPlan.MAX_HP)
	_hud.show_hint("Kopyalardan ve yankılardan kaç. Yorulunca yaklaş!", "Yorulunca yaklaş!")
	_miril.start()


## Faz 2: no fighting. Offer the four sparks, one by one.
func _faz2() -> void:
	_hud.hide_boss()
	await get_tree().create_timer(0.8).timeout
	GameState.bark("c5_faz2")
	await GameState.dialogue_closed
	_offered = 0
	_offer_btn = UiKit.button("Kıvılcım uzat")
	_offer_btn.custom_minimum_size = Vector2(300, 84)
	_offer_btn.add_theme_font_size_override("font_size", 26)
	_offer_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_offer_btn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_offer_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_offer_btn.offset_bottom = -Tokens.px("space-6") - 90
	_offer_btn.offset_left = -150
	_offer_btn.offset_right = 150
	_offer_btn.pressed.connect(offer_next)
	_hud.add_child(_offer_btn)
	_tint_offer_button()
	_hud.show_hint("Kıvılcımlarını Mırıl'a uzat", "Kıvılcımlarını Mırıl'a uzat")


func _tint_offer_button() -> void:
	if _offered >= MirilPlan.OFFER_ORDER.size():
		return
	var col := Tokens.color("spark-" + MirilPlan.OFFER_ORDER[_offered])
	for k in ["normal", "hover"]:
		var st := UiKit.box(col, "radius-md", 4.0)
		st.content_margin_left = 20
		st.content_margin_right = 20
		_offer_btn.add_theme_stylebox_override(k, st)


func _unhandled_input(event: InputEvent) -> void:
	if _offer_btn and _offer_btn.visible and not _offer_btn.disabled \
			and (event.is_action_pressed("interact") or event.is_action_pressed("attack")):
		offer_next()
		get_viewport().set_input_as_handled()


func offer_next() -> void:
	if _offer_btn.disabled or _offered >= MirilPlan.OFFER_ORDER.size():
		return
	_offer_btn.disabled = true
	var color: String = MirilPlan.OFFER_ORDER[_offered]
	var orb := Toon.part(self, "sphere", Vector3(0.7, 0.9, 0.7), "spark-" + color, _player.global_position + Vector3.UP * 1.2, Vector3.ZERO, 1.4, 0.03)
	var tw := orb.create_tween()
	tw.tween_property(orb, "global_position", _miril.global_position + Vector3.UP * 4.5, 1.0).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(orb.queue_free)
	await tw.finished
	Effects.sparkle(self, _miril.global_position + Vector3.UP * 4.5, Tokens.color("spark-" + color), 18)
	# the memory appears beside him, bright if it was found in the castle
	var mem := MemoryItem.new()
	mem.memory = _offered + 1
	mem.display = true
	var side := -1.0 if _offered % 2 == 0 else 1.0
	mem.position = TOP + Vector3(side * (3.0 + _offered * 0.6), 0, 2.0)
	add_child(mem)
	if not GameState.data.has_flag("ani_%d" % (_offered + 1)):
		mem.scale = Vector3.ONE * 0.7
	_offered += 1
	_miril.shrink(_offered)
	GameState.bark("c5_isik_" + color)
	await GameState.dialogue_closed
	if _offered >= MirilPlan.OFFER_ORDER.size():
		_offer_btn.queue_free()
		_offer_btn = null
		_hud.clear_hint()
		_star_child()
	else:
		_offer_btn.disabled = false
		_tint_offer_button()


func _star_child() -> void:
	await _miril.reveal()
	Pus.fade_to(self, 0.0, 3.0)
	GameState.bark("c5_yildiz")
	await GameState.dialogue_closed
	var d := GameState.data
	if d.item_count("hikaye_tasi") >= PlayerData.STORY_STONES:
		GameState.bark("c5_taslar")
		await GameState.dialogue_closed
	await fly_spark(_miril.global_position + Vector3.UP * 1.5, "spark-purple")
	d.add_spark("purple")
	GameState.notify("defeat", "miril")
	boss_camera(false)
	_hud.show_scene_card("Kıvılcım bulundu!", "Mor Kıvılcım", "Pus dağıldı. Mırıl artık yalnız değil")
	await get_tree().create_timer(3.6).timeout
	if d.quest_state(QUEST) == "ready":
		d.complete_quest(Content.quests[QUEST])
	d.set_flag("bolum5_bitti")
	SaveGame.write(d)
	SceneFlow.go_to("final")


func _run_demo(which: String) -> void:
	var d := GameState.data
	match which:
		"start":
			pass
		"yard":
			GameState.notify("light", "kale_feneri")
			$Level/KaleFeneri.light_up(true)
			_player.global_position = Vector3(1, 0, 28)
			await close_dialogs()
		"walk":
			for m in get_tree().get_nodes_in_group("mob"):
				m.queue_free()
			var route := [["walk", Vector3(-3, 0, 37.8)], ["use", null], ["walk", Vector3(0, 0, 26.2)], ["use", null],
				["walk", Vector3(0, 0, 20)], ["walk", Vector3(-7.2, 0, 12.6)], ["use", null], ["walk", Vector3(0, 0, 6.2)], ["use", null],
				["walk", Vector3(5.2, 0, -9.4)], ["use", null], ["walk", Vector3(0, 0, -15.8)], ["use", null],
				["walk", Vector3(-6.2, 0, -26.4)], ["use", null], ["walk", Vector3(0, 0, -37.8)], ["use", null],
				["walk", Vector3(4.2, 0, -44.4)], ["use", null], ["walk", Vector3(0, 0, -49)], ["walk", Vector3(0, 4, -62.5)]]
			for step: Array in route:
				await close_dialogs()
				if step[0] == "walk":
					await walk_to(step[1], 8.0)
				else:
					_player.interact()
					await get_tree().create_timer(0.4).timeout
			await close_dialogs()
			print("CASTLE pos=%s fener=%s kapilar=%s anilar=%s miril=%s" % [_player.global_position.round(), d.objective_done(QUEST, "fener"),
				d.objective_count(QUEST, "kapilar"), d.objective_count(QUEST, "anilar"), _miril != null])
			get_tree().quit()
		"final", "finalfight":
			for o in ["fener", "kapilar", "anilar"]:
				d.complete_objective(QUEST, o)
			for i in [1, 2, 3, 4]:
				d.set_flag("ani_%d" % i)
			_player.global_position = Vector3(0, 4.2, -62.5)
			if which == "final":
				return
			while _miril == null or not _miril.active:
				await get_tree().process_frame
			var t := 0.0
			while _miril.active and t < 240.0:
				if _miril.tired:
					_player.global_position = _miril.global_position + Vector3(0, 0.2, 3.0)
					_player._attack_cd = 0.0
					_player.spin_attack()
				await get_tree().create_timer(0.1).timeout
				t += 0.1
				if _hud._dialog.is_open():
					_hud._dialog.advance()
			print("MIRIL faz1 hp=%d t=%.1f player_hp=%d" % [_miril.hp, t, d.hp])
			var guard := 0
			while _offer_btn == null and guard < 100:
				guard += 1
				if _hud._dialog.is_open():
					_hud._dialog.advance()
					_hud._dialog.advance()
				await get_tree().create_timer(0.1).timeout
			for i in 4:
				while _offer_btn != null and _offer_btn.disabled:
					if _hud._dialog.is_open():
						_hud._dialog.advance()
						_hud._dialog.advance()
					await get_tree().create_timer(0.1).timeout
				if _offer_btn:
					_offer_btn.pressed.emit()
				await get_tree().create_timer(1.5).timeout
				print("  offered %d" % _offered)
			for i in 150:
				if _hud._dialog.is_open():
					_hud._dialog.advance()
					_hud._dialog.advance()
				await get_tree().create_timer(0.1).timeout
			print("MIRIL2 sparks=%s quest=%s flag=%s scene=%s" % [d.sparks, d.quest_state(QUEST), d.has_flag("bolum5_bitti"), SceneFlow.current])
			get_tree().quit()
