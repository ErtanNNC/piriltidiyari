extends Node3D
## Prolog · Sahne 4 – Pus Baykuşu. Boss fight on the tower top around the
## Büyük Kıvılcım. Easy, three phases (OwlPlan); the owl leaves a whisper.

const ARENA_RADIUS := 10.0

@onready var _hud: Hud = $Hud
var _owl: Owl


func _ready() -> void:
	WorldLook.add(self, "kule")
	Pus.set_amount(0.55)
	_build()
	_owl = Owl.new()
	add_child(_owl)
	_owl.hp_changed.connect(func(h: int, m: int) -> void: _hud.set_boss_hp(h, m))
	_owl.phase_changed.connect(_on_phase)
	_owl.defeated.connect(_on_defeated)
	$Player.respawn_point = $Player.global_position
	await get_tree().create_timer(1.9).timeout
	var intro := create_tween()
	intro.tween_property(_owl, "position", Vector3(0, Owl.ORBIT_HEIGHT, -Owl.ORBIT_RADIUS), 1.2).set_trans(Tween.TRANS_BACK)
	if DevTools.demo == "":
		GameState.bark("s4_basla")
		await GameState.dialogue_closed
	_hud.show_boss("Pus Baykuşu", _owl.hp, OwlPlan.MAX_HP)
	_hud.show_hint("Tüylerden kaç ya da yuvarlan. Dalıştan sonra vur!", "Tüylerden kaç. Dalıştan sonra vur!")
	_owl.start()
	await get_tree().create_timer(6.0).timeout
	if _owl.active and not _owl.dazed:
		_hud.clear_hint()
	if DevTools.demo != "":
		_run_demo(DevTools.demo)


func _on_phase(p: int) -> void:
	# a jar of honey rolls onto the arena at each phase change
	var pk := Pickup.new()
	pk.item_id = "bal_surubu"
	add_child(pk)
	pk.global_position = Vector3(randf_range(-5, 5), 0, randf_range(2, 6))
	GameState.bark("s4_faz%d" % p)


func _on_defeated() -> void:
	_hud.hide_boss()
	GameState.data.set_flag("sahne4_bitti")
	await get_tree().create_timer(0.8).timeout
	_hud.show_scene_card("", "Pus Baykuşu dağıldı", "Ama arkasında bir fısıltı kaldı...")
	await get_tree().create_timer(3.2).timeout
	GameState.bark("s4_son", {"goto_scene": "scene5"})


func _build() -> void:
	var stone := Color("#cdbfa6")
	# round tower top with a low wall and the crystal on its pedestal
	var floor_body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = ARENA_RADIUS + 1.0
	cyl.height = 1.0
	c.shape = cyl
	c.position.y = -0.5
	floor_body.add_child(c)
	add_child(floor_body)
	Toon.part(self, "cylinder", Vector3((ARENA_RADIUS + 1.0) * 2, 1.0, (ARENA_RADIUS + 1.0) * 2), stone, Vector3(0, -0.5, 0))
	Toon.part(self, "cylinder", Vector3(ARENA_RADIUS * 1.2, 0.06, ARENA_RADIUS * 1.2), "honey-deep", Vector3(0, 0.01, 0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(self, "cylinder", Vector3(ARENA_RADIUS * 1.1, 0.07, ARENA_RADIUS * 1.1), stone, Vector3(0, 0.02, 0), Vector3.ZERO, 0.0, 0.0)
	for i in 24:
		var a := TAU * i / 24.0
		var at := Vector3(sin(a), 0, cos(a)) * (ARENA_RADIUS + 0.4)
		Toon.part(self, "box", Vector3(2.4, 1.0, 0.7), stone.darkened(0.08), at + Vector3.UP * 0.5, Vector3(0, rad_to_deg(a), 0))
		var wall := StaticBody3D.new()
		var wc := CollisionShape3D.new()
		var wb := BoxShape3D.new()
		wb.size = Vector3(2.8, 6.0, 0.8)
		wc.shape = wb
		wall.add_child(wc)
		add_child(wall)
		wall.position = at + Vector3.UP * 3.0
		wall.rotation.y = a
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4
		var post := Prop.new()
		post.kind = "lantern_post"
		post.accent = "honey"
		add_child(post)
		post.position = Vector3(sin(a), 0, cos(a)) * (ARENA_RADIUS - 1.2)
	# Büyük Kıvılcım
	Toon.part(self, "cylinder", Vector3(1.6, 1.2, 2.0), stone.darkened(0.1), Vector3(0, 0.6, -2))
	var crystal := Toon.part(self, "sphere", Vector3(1.4, 2.0, 1.4), "honey", Vector3(0, 2.3, -2), Vector3.ZERO, 2.2, 0.05)
	crystal.name = "BuyukKivilcim"
	var tw := crystal.create_tween().set_loops()
	tw.tween_property(crystal, "position:y", 2.5, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(crystal, "position:y", 2.3, 1.2).set_trans(Tween.TRANS_SINE)
	var l := OmniLight3D.new()
	l.light_color = Tokens.color("honey")
	l.light_energy = 2.0
	l.omni_range = 9.0
	l.position = Vector3(0, 2.5, -2)
	add_child(l)
	var pedestal := StaticBody3D.new()
	var pc := CollisionShape3D.new()
	var ps := CylinderShape3D.new()
	ps.radius = 1.0
	ps.height = 3.0
	pc.shape = ps
	pc.position = Vector3(0, 1.5, -2)
	pedestal.add_child(pc)
	add_child(pedestal)


func _run_demo(which: String) -> void:
	var player: Player = _hud.player()
	match which:
		"daze":
			while not _owl.dazed:
				await get_tree().process_frame
			player.global_position = _owl.global_position + Vector3(0, 0, 2.0)
			player.spin_attack()
		"win":
			# fight automatically: dodge by rolling, hit when dazed
			var t := 0.0
			while _owl.active and t < 150.0:
				if _owl.dazed:
					player.global_position = _owl.global_position + Vector3(0, 0.2, 1.8)
					player._attack_cd = 0.0
					player.spin_attack()
					if GameState.data.mp >= Player.SKILL_COST:
						player._attack_cd = 0.0
						player.dikenli_donus()
				await get_tree().create_timer(0.4).timeout
				t += 0.4
				for i in 2:
					if _hud._dialog.is_open():
						_hud._dialog.advance()
			print("WIN owl_hp=%d active=%s phase=%d t=%.1f player_hp=%d asleep=%s" % [_owl.hp, _owl.active, _owl.phase, t, GameState.data.hp, player.asleep])
			await get_tree().create_timer(5.0).timeout
			for i in 6:
				if _hud._dialog.is_open():
					_hud._dialog.advance()
					_hud._dialog.advance()
				await get_tree().create_timer(0.3).timeout
			await get_tree().create_timer(3.0).timeout
			print("WIN2 flag=%s scene=%s" % [GameState.data.has_flag("sahne4_bitti"), SceneFlow.current])
			get_tree().quit()
