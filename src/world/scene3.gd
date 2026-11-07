extends Node3D
## Prolog · Sahne 3 – Kule'ye Koşu. Run up the path under falling beams,
## climb the vines, cross the swaying lanterns, reach the tower roof.
## Teaches climbing and platforming; first level-up and the Dikenli Dönüş skill.

const QUEST := "kuleye_kosu"
const STONE := Color("#cdbfa6")
const GROUND := Color("#9fc79a")

var _stage := 0
var _roof_mobs: Array[Mob] = []
@onready var _hud: Hud = $Hud


func _ready() -> void:
	WorldLook.add(self, "pus")
	Decor.auto(self, "kule")
	Pus.set_amount(0.6)
	_build()
	var d := GameState.data
	if d.quest_state(QUEST) == "none":
		d.start_quest(Content.quests[QUEST])
	d.quest_changed.connect(func(_id: String) -> void: _advance())
	await get_tree().create_timer(1.8).timeout
	if DevTools.demo != "":
		_run_demo(DevTools.demo)
		return
	GameState.bark("s3_basla")
	_hud.show_hint("Boşluk: zıpla · W: sarmaşıkta tırman", "Zıpla · joystick yukarı: tırman")


func _advance() -> void:
	var d := GameState.data
	if _stage == 0 and d.objective_done(QUEST, "dip"):
		_stage = 1
		_hud.show_hint("Sarmaşığa yürü, yukarı tırman!", "Sarmaşığa yürü, joystick yukarı!")
	if _stage == 1 and d.objective_done(QUEST, "balkon1"):
		_stage = 2
		_hud.show_hint("Sallanan fenerlere zıpla!", "")
	if _stage == 2 and d.objective_done(QUEST, "balkon2"):
		_stage = 3
		_hud.show_hint("Bir sarmaşık daha! Çatıya tırman", "")
	if _stage == 3 and d.quest_state(QUEST) == "ready":
		_stage = 4
		_hud.clear_hint()
		d.complete_quest(Content.quests[QUEST])
		_learn_skill()


func _learn_skill() -> void:
	await get_tree().create_timer(3.2).timeout
	GameState.data.unlock_skill("dikenli_donus")
	_hud.show_scene_card("Yeni yetenek!", "Dikenli Dönüş", "Etrafındaki herkese birden vurur")
	await get_tree().create_timer(3.2).timeout
	GameState.bark("s3_yetenek")
	await GameState.dialogue_closed
	for at in [Vector3(26, 14, -30.5), Vector3(30.5, 14, -31), Vector3(28, 14, -28.5)]:
		var m := Mob.spawn(self, "sumuklu", at)
		_roof_mobs.append(m)
		m.calmed.connect(_on_roof_mob_calmed)
	_hud.show_hint("L: Dikenli Dönüş! Hepsini birden sakinleştir", "Dönüş'e bas: hepsini birden sakinleştir!")


func _on_roof_mob_calmed(m: Mob) -> void:
	_roof_mobs.erase(m)
	if not _roof_mobs.is_empty():
		return
	_hud.clear_hint()
	GameState.data.set_flag("sahne3_bitti")
	await get_tree().create_timer(1.2).timeout
	GameState.bark("s3_kapi", {"goto_scene": "scene4"})


# --- level ---------------------------------------------------------------

func _build() -> void:
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	WorldLook.block(lv, Vector3(11, -0.5, -4), Vector3(70, 1, 76), GROUND, 0.0)
	Toon.part(lv, "box", Vector3(3, 0.06, 36), Tokens.color("panel-sunken").lerp(Tokens.color("honey-deep"), 0.18), Vector3(0, 0.01, -3), Vector3.ZERO, 0.0, 0.0)
	# hedges along the path
	for side in [-1.0, 1.0]:
		var f := Prop.new()
		f.kind = "fence"
		f.length = 26.0
		lv.add_child(f)
		f.position = Vector3(3.2 * side, 0, -3)
		f.rotation_degrees.y = 90
	for z in [10.0, 4.0, -2.0, -8.0, -14.0]:
		for side in [-1.0, 1.0]:
			var t := Prop.new()
			t.kind = "tree"
			lv.add_child(t)
			t.position = Vector3(6.5 * side + randf_range(-0.5, 0.5), 0, z)
	# falling beams on the path
	for i in 3:
		var b := FallingBeam.new()
		b.delay = i * 1.0
		lv.add_child(b)
		b.position = Vector3(0, 0, 3 - i * 6.5)
	# the tower: tall section on the left, lower roof on the right
	WorldLook.block(lv, Vector3(6, 8, -28), Vector3(32, 16, 4), STONE)
	WorldLook.block(lv, Vector3(28, 7, -30), Vector3(12, 14, 8), STONE)
	for y in [5.5, 11.0]:
		Toon.part(lv, "box", Vector3(32.4, 0.5, 4.4), "honey-deep", Vector3(6, y, -28))
	Toon.part(lv, "box", Vector3(12.4, 0.4, 8.4), "honey-deep", Vector3(28, 13.6, -30))
	Toon.part(lv, "box", Vector3(0.2, 2.4, 1.6), Color("#a86b45"), Vector3(22.1, 15.2, -30.5))  # door
	Toon.part(lv, "cone", Vector3(14, 8, 14), "berry", Vector3(6, 20, -34))
	var crystal := Toon.part(lv, "sphere", Vector3(3, 4, 3), "honey", Vector3(6, 25.5, -34), Vector3.ZERO, 2.0, 0.06)
	crystal.name = "BuyukKivilcim"
	var glow := OmniLight3D.new()
	glow.light_color = Tokens.color("honey")
	glow.light_energy = 2.0
	glow.omni_range = 16.0
	glow.position = Vector3(6, 25, -32)
	lv.add_child(glow)
	# first ledge + vine
	WorldLook.block(lv, Vector3(4, 2.5, -24), Vector3(12, 5, 4), STONE)
	var v1 := ClimbZone.new()
	v1.size = Vector3(2.2, 5.6, 0.8)
	lv.add_child(v1)
	v1.position = Vector3(1, 0, -21.6)
	# swaying lantern platforms
	for i in 3:
		var p := MovingPlatform.new()
		p.travel = Vector3(0, 0, 1.5)
		p.period = 3.6
		p.phase = i * 0.1
		p.accent = ["berry", "sky", "spark-purple"][i]
		p.position = Vector3(12.6 + i * 3.0, 5.2 + i * 0.5, -24)
		lv.add_child(p)
	# second ledge + vine up to the roof
	WorldLook.block(lv, Vector3(26, 3.5, -24), Vector3(10, 7, 4), STONE)
	var v2 := ClimbZone.new()
	v2.size = Vector3(2.2, 7.6, 0.8)
	lv.add_child(v2)
	v2.position = Vector3(29, 7, -25.6)
	# checkpoints / quest areas (lanterns light up when reached)
	_checkpoint(lv, "kule_dibi", Vector3(0, 0, -18.5))
	_checkpoint(lv, "ilk_balkon", Vector3(6.5, 5, -24))
	_checkpoint(lv, "ikinci_balkon", Vector3(23.5, 7, -24))
	_checkpoint(lv, "kule_catisi", Vector3(26, 14, -29))
	for at in [Vector3(0, 0, -13), Vector3(1.2, 0, -15.5)]:
		Mob.spawn(self, "sumuklu", at)
	$Player.respawn_point = $Player.global_position


func _checkpoint(parent: Node3D, area_id: String, at: Vector3) -> void:
	var post := Prop.new()
	post.kind = "lantern_post"
	post.accent = "spark-off"
	parent.add_child(post)
	post.position = at + Vector3(1.6, 0, 0.6)
	var t := TriggerArea.new()
	t.area_id = area_id
	t.checkpoint = true
	t.radius = 2.0
	parent.add_child(t)
	t.position = at
	t.reached.connect(func() -> void:
		post.queue_free()
		var lit := Prop.new()
		lit.kind = "lantern_post"
		lit.accent = "honey"
		parent.add_child(lit)
		lit.position = at + Vector3(1.6, 0, 0.6)
		Effects.sparkle(self, lit.global_position + Vector3.UP * 2.5, Tokens.color("honey"), 12)
		GameState.toast.emit("Fener yandı!", "lantern"))


func _run_demo(which: String) -> void:
	var player: Player = _hud.player()
	match which:
		"climb":
			player.global_position = Vector3(1, 0, -20.5)
			Input.action_press("move_forward")
			await get_tree().create_timer(1.6).timeout
			print("CLIMB y=%.2f z=%.2f" % [player.global_position.y, player.global_position.z])
			await get_tree().create_timer(1.2).timeout
			Input.action_release("move_forward")
			print("CLIMB2 y=%.2f z=%.2f obj=%s" % [player.global_position.y, player.global_position.z, GameState.data.objective_done(QUEST, "balkon1")])
			get_tree().quit()
		"platforms":
			player.global_position = Vector3(9, 5, -24)
			player.respawn_point = player.global_position
		"hop":
			# scripted run across the lanterns: jump right at each platform
			player.global_position = Vector3(9.2, 5.1, -24)
			await get_tree().create_timer(0.5).timeout
			var plats := get_tree().get_nodes_in_group("_none")
			for i in 4:
				var target_x := 12.6 + i * 3.0 if i < 3 else 22.5
				var target_z := -24.0
				for n in $Level.get_children():
					if n is MovingPlatform and absf(n.position.x - target_x) < 0.1:
						target_z = n.position.z
				# wait until the platform is near the middle of its sway
				Input.action_press("move_right")
				player.velocity.y = player.jump_velocity
				var t := 0.0
				while t < 0.75:
					var dz := target_z - player.global_position.z
					if absf(dz) > 0.3:
						Input.action_press("move_forward" if dz < 0 else "move_back", clampf(absf(dz) / 2.0, 0.2, 1.0))
					else:
						Input.action_release("move_forward")
						Input.action_release("move_back")
					await get_tree().physics_frame
					t += get_physics_process_delta_time()
					if player.global_position.x >= target_x - 0.4:
						Input.action_release("move_right")
				Input.action_release("move_right")
				Input.action_release("move_forward")
				Input.action_release("move_back")
				await get_tree().create_timer(0.35).timeout
				print("HOP %d x=%.2f y=%.2f z=%.2f floor=%s" % [i, player.global_position.x, player.global_position.y, player.global_position.z, player.is_on_floor()])
			get_tree().quit()
		"climb2":
			player.global_position = Vector3(29, 7.1, -24.2)
			Input.action_press("move_forward")
			await get_tree().create_timer(3.0).timeout
			Input.action_release("move_forward")
			print("CLIMB2 y=%.2f z=%.2f" % [player.global_position.y, player.global_position.z])
			get_tree().quit()
		"flow":
			for o in ["dip", "balkon1", "balkon2"]:
				GameState.data.complete_objective(QUEST, o)
			player.global_position = Vector3(26, 14.2, -29)
			await get_tree().create_timer(6.8).timeout
			for i in 6:
				var hud_dialog_open: bool = _hud._dialog.is_open()
				if hud_dialog_open:
					_hud._dialog.advance()
					_hud._dialog.advance()
				await get_tree().create_timer(0.3).timeout
			print("FLOW level=%d skill=%s mobs=%d" % [GameState.data.level, GameState.data.skills, _roof_mobs.size()])
			var tries := 0
			while not _roof_mobs.is_empty() and tries < 8:
				tries += 1
				var m: Mob = _roof_mobs[0]
				player.global_position = m.global_position + Vector3(0, 0.2, 1.5)
				await get_tree().create_timer(0.2).timeout
				player.dikenli_donus()
				await get_tree().create_timer(0.8).timeout
				player._attack_cd = 0.0
				for k in 3:
					player.spin_attack()
					player._attack_cd = 0.0
					await get_tree().create_timer(0.1).timeout
			await get_tree().create_timer(3.0).timeout
			for i in 4:
				if _hud._dialog.is_open():
					_hud._dialog.advance()
					_hud._dialog.advance()
				await get_tree().create_timer(0.3).timeout
			await get_tree().create_timer(3.5).timeout
			for m in _roof_mobs:
				print("LEFT ", m.state, " hp=", m.hp, " pos=", m.global_position, " player=", player.global_position, " valid=", is_instance_valid(m))
			print("FLOW2 mobs=%d flag=%s scene=%s" % [_roof_mobs.size(), GameState.data.has_flag("sahne3_bitti"), SceneFlow.current])
			get_tree().quit()
		"roof":
			for o in ["dip", "balkon1", "balkon2"]:
				GameState.data.complete_objective(QUEST, o)
			player.global_position = Vector3(26, 14.2, -29)
