extends ChapterBase
## Sezon 2 · Prolog · Sahne 4 – Gürledek. A red thundercloud blocks the
## mountain pass. Three easy phases (GurledekPlan): dodge the warned
## lightning and rain, hit it when it sinks low and tired. At 0 HP it cries;
## Mırıl listens (Sakinleş next to it) and the cloud thins away, leaving a
## red echo. Then Mırıl's choice (Sahne 5).

const ARENA_RADIUS := 11.0
const ROCK := Color("#c98a5e")
const ROCK_DARK := Color("#9c6248")

var _boss: Gurledek
var _echo: Node3D


func _ready() -> void:
	WorldLook.add(self, "aksam")
	Pus.set_color(Pus.RED)
	Pus.set_amount(0.3)
	_build()
	Decor.auto(self, "koy")
	_boss = Gurledek.new()
	add_child(_boss)
	_boss.hp_changed.connect(func(h: int, m: int) -> void: _hud.set_boss_hp(h, m))
	_boss.phase_changed.connect(_on_phase)
	_boss.crying.connect(_on_crying)
	_boss.calmed.connect(_on_calmed)
	_player.respawn_point = _player.global_position
	boss_camera(true, Vector3(0, 0, -3), 0.4, 20.0)
	await get_tree().create_timer(1.9).timeout
	var intro := create_tween()
	intro.tween_property(_boss, "position", Vector3(0, Gurledek.HOVER, -4.0), 1.4).set_trans(Tween.TRANS_BACK)
	GameState.bark("s4b_basla")
	await GameState.dialogue_closed
	_hud.show_boss("Gürledek", _boss.hp, GurledekPlan.MAX_HP)
	_hud.show_hint("Halkalardan kaç. Bulut alçalınca vur!", "Halkalardan kaç, alçalınca vur!")
	_boss.start()
	if DevTools.demo != "":
		_run_demo(DevTools.demo)


func _on_phase(p: int) -> void:
	# a Nane Şekeri and a honey jar roll in at each phase change
	for id: String in ["bal_surubu", "nane_sekeri"]:
		var pk := Pickup.new()
		pk.item_id = id
		add_child(pk)
		pk.global_position = Vector3(randf_range(-5, 5), 0, randf_range(1, 5))
	GameState.bark("s4b_faz%d" % p)


func _on_crying() -> void:
	_hud.hide_boss()
	GameState.bark("s4b_aglama")
	await GameState.dialogue_closed
	_hud.show_hint("Yanına git, Sakinleş'e basılı tut. Onu dinle.", "Yanına git, Sakinleş'e basılı tut!")


func _on_calmed() -> void:
	_hud.clear_hint()
	GameState.data.set_flag("s2_sahne4_bitti")
	await get_tree().create_timer(0.6).timeout
	GameState.bark("s4b_son")
	await GameState.dialogue_closed
	await _boss.dissolve()
	_hud.show_scene_card("", "Gürledek dağıldı", "Ardında kırmızı bir yankı kaldı...")
	_drop_echo()
	await get_tree().create_timer(3.2).timeout
	if DevTools.demo == "win" and DisplayServer.get_name() == "headless":
		print("S4B_WIN flag=%s hp=%d asleep=%s" % [GameState.data.has_flag("s2_sahne4_bitti"), GameState.data.hp, _player.asleep])
		get_tree().quit()
		return
	SceneFlow.go_to("s2_scene5")


## The red echo the cloud leaves: a soft glowing ring that hums.
func _drop_echo() -> void:
	_echo = Node3D.new()
	add_child(_echo)
	_echo.position = Vector3(0, 1.4, -4)
	Toon.part(_echo, "ring", Vector3(1.2, 0.12, 1.2), "hp", Vector3.ZERO, Vector3(90, 0, 0), 2.0, 0.0)
	Toon.part(_echo, "sphere", Vector3(0.5, 0.5, 0.5), "berry", Vector3.ZERO, Vector3.ZERO, 2.0, 0.02)
	var l := OmniLight3D.new()
	l.light_color = Tokens.color("hp")
	l.omni_range = 5.0
	l.light_energy = 1.6
	_echo.add_child(l)
	var tw := _echo.create_tween().set_loops()
	tw.tween_property(_echo, "rotation:y", TAU, 2.4).from(0.0)


func _build() -> void:
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	# the round floor of the pass
	var floor_body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = ARENA_RADIUS + 6.0
	cyl.height = 1.0
	c.shape = cyl
	floor_body.add_child(c)
	floor_body.position.y = -0.5
	lv.add_child(floor_body)
	Toon.part(lv, "cylinder", Vector3(ARENA_RADIUS * 2 + 12, 1.0, ARENA_RADIUS * 2 + 12), Color("#8fb85a"), Vector3(0, -0.5, 0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(lv, "cylinder", Vector3(ARENA_RADIUS * 2, 0.06, ARENA_RADIUS * 2), Color("#e3c08c"), Vector3(0, 0.01, 0), Vector3.ZERO, 0.0, 0.0)
	# a ring of rocks around it (and an invisible wall, so nobody wanders off)
	var leaves := [Color("#e8833a"), Color("#d9542f"), Color("#f2b33d")]
	for i in 18:
		var a := TAU * i / 18.0
		var at := Vector3(cos(a), 0, sin(a)) * (ARENA_RADIUS + 1.5)
		# the rocks on the camera's side stay low so they never hide the fight
		var h := 5.0 + (i % 3) if at.z < 2.0 else 1.6
		Toon.part(lv, "cone", Vector3(3.0, h, 3.0) if at.z < 2.0 else Vector3(2.2, h, 2.2), ROCK if i % 2 == 0 else ROCK_DARK, at + Vector3.UP * h * 0.5)
		Toon.part(lv, "sphere", Vector3(2.4, 1.8, 2.4), leaves[i % 3], at * 1.25 + Vector3.UP * 1.2)
	for i in 24:
		var a := TAU * i / 24.0
		var body := StaticBody3D.new()
		var bc := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(3.2, 6, 1)
		bc.shape = box
		body.add_child(bc)
		lv.add_child(body)
		body.position = Vector3(cos(a), 0, sin(a)) * (ARENA_RADIUS + 0.6) + Vector3.UP * 3.0
		body.rotation.y = -a + PI / 2
		body.set_meta("camera_ignore", true)
	# the way on: a gap in the rocks to the north, glowing red
	var glow := OmniLight3D.new()
	glow.light_color = Tokens.color("hp")
	glow.light_energy = 2.0
	glow.omni_range = 12.0
	glow.position = Vector3(0, 4, -ARENA_RADIUS - 3)
	lv.add_child(glow)


func _run_demo(which: String) -> void:
	match which:
		"win":
			# fight automatically: hit while it is low, breathe when it cries
			DevTools.auto_dialogue = true
			var t := 0.0
			while _boss.active and t < 200.0:
				if _boss.low:
					_player.global_position = Vector3(_boss.global_position.x, 0.2, _boss.global_position.z + 2.2)
					_player._attack_cd = 0.0
					_player.spin_attack()
				await get_tree().create_timer(0.35).timeout
				t += 0.35
				await close_dialogs()
			print("S4B fight t=%.1f hp=%d crying=%s player_hp=%d" % [t, _boss.hp, _boss.is_crying, GameState.data.hp])
			await get_tree().create_timer(1.0).timeout
			await close_dialogs()
			_player.global_position = Vector3(_boss.global_position.x, 0.2, _boss.global_position.z + 2.4)
			await get_tree().create_timer(0.3).timeout
			Input.action_press("calm")
			await get_tree().create_timer(BreathCalm.BREATH_IN + BreathCalm.BREATH_OUT + 0.5).timeout
			Input.action_release("calm")
			print("S4B breathed crying=%s" % _boss.is_crying)
			for i in 20:
				await close_dialogs()
				await get_tree().create_timer(0.5).timeout
		"low":
			while not _boss.low:
				await get_tree().process_frame
			_player.global_position = Vector3(_boss.global_position.x, 0.2, _boss.global_position.z + 2.4)
		"cry":
			_boss.hp = 1
			while not _boss.low:
				await get_tree().process_frame
			_player.global_position = Vector3(_boss.global_position.x, 0.2, _boss.global_position.z + 2.4)
			_player._attack_cd = 0.0
			_player.spin_attack()
