extends Node3D
## Prolog · Sahne 2 – Gri Rüzgâr. The stars go out and the grey Pus rolls in.
## Teaches attacking (quill spin), rolling under a fallen beam, and Bal Şurubu.
## Stages follow the ordered quest "gri_ruzgar" (content/prologue/quests).

const QUEST := "gri_ruzgar"

var _stage := 0
var _potion_hint_shown := false
@onready var _hud: Hud = $Hud


func _ready() -> void:
	var d := GameState.data
	if d.quest_state(QUEST) == "none":
		d.start_quest(Content.quests[QUEST])
	Pus.set_amount(0.15)
	Pus.fade_to(self, 0.6, 5.0)
	_drift_fog()
	d.quest_changed.connect(func(_id: String) -> void: _advance())
	d.stats_changed.connect(_maybe_potion_hint)
	await get_tree().create_timer(1.5).timeout
	_advance()
	if DevTools.demo != "":
		_run_demo(DevTools.demo)


## Moves the scene along as quest objectives complete.
func _advance() -> void:
	var d := GameState.data
	if _stage == 0:
		_stage = 1
		_spawn_wave($Spawns/Wave1)
		_hud.show_hint("J: Dikenlerinle vur!", "Saldır'a bas: dikenlerinle vur!")
	if _stage == 1 and d.objective_done(QUEST, "sumuklu"):
		_stage = 2
		_spawn_wave($Spawns/Wave2)
		GameState.toast.emit("Tospik Nine: Fıstık, buraya!", "quest")
		_hud.show_hint("K: Top ol, kirişin altından geç!", "Yuvarlan: kirişin altından geç!")
	if _stage == 2 and d.objective_done(QUEST, "tospik"):
		_stage = 3
		_hud.show_hint("E: Tospik Nine ile konuş", "Konuş'a bas")
	if _stage == 3 and d.objective_done(QUEST, "konus"):
		_stage = 4
		_hud.clear_hint()
		_spawn_wave($Spawns/Wave3)
	if _stage == 4 and d.quest_state(QUEST) == "ready":
		_stage = 5
		Pus.fade_to(self, 0.35, 2.5)
		_hud.show_hint("Tospik Nine'ye dön", "")


func _maybe_potion_hint() -> void:
	var d := GameState.data
	if _potion_hint_shown or not d.has_item("bal_surubu") or d.hp > d.max_hp * 0.7:
		return
	_potion_hint_shown = true
	_hud.show_hint("1: Bal Şurubu iç, canın dolsun!", "Kalbe dokun: Bal Şurubu iç!")
	await get_tree().create_timer(5.0).timeout
	if _stage < 5:
		_hud.clear_hint()


func _spawn_wave(wave: Node3D) -> void:
	for marker: Node3D in wave.get_children():
		Mob.spawn(self, marker.get_meta("kind", "sumuklu"), marker.global_position)


## Soft grey fog puffs drifting across the village.
func _drift_fog() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Tokens.color("pus")
	mat.albedo_color.a = 0.16
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 26:
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 1.0
		s.height = 1.2
		mi.mesh = s
		mi.material_override = mat
		var p := Vector3(rng.randf_range(-24, 24), rng.randf_range(0.3, 1.2), rng.randf_range(-22, 24))
		if p.length() < 5.0:
			continue
		mi.position = p
		mi.scale = Vector3(1.0, 0.35, 1.0) * rng.randf_range(1.5, 3.2)
		add_child(mi)
		var tw := mi.create_tween().set_loops()
		var dx := rng.randf_range(-2.5, 2.5)
		tw.tween_property(mi, "position:x", p.x + dx, rng.randf_range(4, 7)).set_trans(Tween.TRANS_SINE)
		tw.tween_property(mi, "position:x", p.x, rng.randf_range(4, 7)).set_trans(Tween.TRANS_SINE)


func _run_demo(which: String) -> void:
	var player: Player = _hud.player()
	match which:
		"fight":
			await get_tree().create_timer(1.6).timeout
			player.global_position = Vector3(0, 0, 11)
			GameState.data.take_damage(30)
			await get_tree().create_timer(0.4).timeout
			player.spin_attack()
		"touchtest":
			# press the on-screen buttons the way a finger does
			var tc: TouchControls = _hud.find_children("*", "TouchControls", true, false)[0]
			var results := {}
			for label in ["Saldır", "Yuvarlan", "Zıpla"]:
				player.global_position = Vector3(0, 0, 4)
				player._attack_cd = 0.0
				await get_tree().create_timer(0.8).timeout
				var b: Button = null
				for c in tc.find_children("*", "Button", true, false):
					if (c as Button).text == label:
						b = c
				var y0 := player.global_position.y
				b.button_down.emit()
				await get_tree().physics_frame
				await get_tree().physics_frame
				var acted := false
				match label:
					"Saldır": acted = player._attack_cd > 0.0
					"Yuvarlan": acted = player.rolling
					"Zıpla": acted = player.velocity.y > 0.0 or player.global_position.y > y0
				b.button_up.emit()
				results[label] = acted
			print("TOUCHTEST ", results)
			get_tree().quit()
		"beamtest":
			for m in get_tree().get_nodes_in_group("mob"):
				m.queue_free()
			player.global_position = Vector3(0, 0, -7.5)
			Input.action_press("move_forward")
			await get_tree().create_timer(1.2).timeout
			var walked := player.global_position.z
			player.global_position = Vector3(0, 0, -7.5)
			player.velocity.y = 9.0  # try to jump over
			await get_tree().create_timer(1.2).timeout
			var jumped := player.global_position.z
			Input.action_release("move_forward")
			player.global_position = Vector3(0, 0, -7.5)
			await get_tree().create_timer(0.3).timeout
			player._roll_dir = Vector3.FORWARD
			player.start_roll()
			await get_tree().create_timer(1.0).timeout
			print("BEAMTEST walked_z=%.2f jumped_z=%.2f rolled_z=%.2f rolling=%s" % [walked, jumped, player.global_position.z, player.rolling])
			get_tree().quit()
		"beam":
			GameState.data.advance_objective(QUEST, "sumuklu", 3)
			player.global_position = Vector3(0, 0, -7.5)
		"potion":
			for i in 3:
				GameState.data.advance_objective(QUEST, "sumuklu")
			GameState.data.complete_objective(QUEST, "tospik")
			GameState.data.add_item("bal_surubu", 3)
			GameState.data.complete_objective(QUEST, "konus")
			GameState.data.take_damage(45)
			player.global_position = Vector3(0, 0, -13)
