extends ChapterBase
## Sezon 2 · Prolog · Sahne 3 – Yankıların Peşinde. Mırıl follows the voice
## in the red wind up the mountain path: boiling springs that puff steam
## (announced like every attack), Köpüklüler to breathe calm, a chasm only a
## float crosses, the first level-up and Mırıl's lullaby (Yıldız Ninnisi),
## then the pass where a red thundercloud waits (Sahne 4).
##
## Layout (−z is up the path): A springs z 14..−10 (y 0) · stairs · B terrace
## z −11..−20 (top 3) · gap z −20..−28 with a safe floor and stairs back to B
## · D ledge z −28..−50 (top 2.5) · pass at z −47.

const QUEST := "yankilarin_pesinde"
const ROCK := Color("#c98a5e")
const ROCK_DARK := Color("#9c6248")
const SOIL := Color("#8fb85a")
const B_TOP := 3.0
const D_TOP := 2.5
const VENTS := [Vector3(-2.2, 0, 6.0), Vector3(2.4, 0, 2.0), Vector3(-1.4, 0, -2.5)]
const VENT_PERIOD := 3.2
const VENT_RADIUS := 1.3

var _stage := 0
var _ninni_mobs: Array[Mob] = []
var _vents_on := true


func _ready() -> void:
	WorldLook.add(self, "aksam")
	Pus.set_color(Pus.RED)
	Pus.set_amount(0.18)
	_build()
	Decor.auto(self, "koy")
	var d := GameState.data
	if d.quest_state(QUEST) == "none":
		d.start_quest(Content.quests[QUEST])
	d.quest_changed.connect(func(_id: String) -> void: _advance())
	for i in VENTS.size():
		_vent_loop(VENTS[i], i * 1.0)
	await get_tree().create_timer(1.6).timeout
	GameState.bark("s3b_basla")
	_hud.show_hint("Fokurdayan suya dikkat: halka çıkınca uzak dur!", "Fokurdayan suya dikkat!")
	_advance()
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _advance() -> void:
	var d := GameState.data
	if _stage == 0 and d.objective_done(QUEST, "kaynak"):
		_stage = 1
		_hud.show_hint("Köpüklüler! Vur, oturunca Sakinleş.", "Vur, oturunca Sakinleş!")
	if _stage == 1 and d.objective_done(QUEST, "nefes"):
		_stage = 2
		_hud.show_hint("Basamaklardan çık, uçurumdan süzül!", "Basamaklardan çık, süzül!")
		GameState.bark("s3b_ucurum")
	if _stage == 2 and d.objective_done(QUEST, "ucurum"):
		_stage = 3
		_hud.clear_hint()
		_learn_lullaby()
	if _stage == 4 and d.objective_done(QUEST, "ninni"):
		_stage = 5
		_hud.show_hint("Dağ geçidine yürü", "Dağ geçidine yürü")
	if _stage == 5 and d.quest_state(QUEST) == "ready":
		_stage = 6
		_hud.clear_hint()
		d.complete_quest(Content.quests[QUEST])
		d.set_flag("s2_sahne3_bitti")
		_end()


## The first proper level-up of the season and Mırıl's own skill.
func _learn_lullaby() -> void:
	var d := GameState.data
	if d.level < 3:
		d.add_xp(Progression.xp_to_next(d.level) - d.xp)
	await get_tree().create_timer(1.2).timeout
	d.unlock_skill("yildiz_ninnisi")
	_hud.show_scene_card("Yeni yetenek!", "Yıldız Ninnisi", "Yakındaki Köpüklüler oturup sersemler")
	await get_tree().create_timer(3.0).timeout
	GameState.bark("s3b_yetenek")
	await GameState.dialogue_closed
	for k in 4:
		_spawn_ninni_mob(k)
	_stage = 4
	GameState.bark("s3b_ninni")
	_hud.show_hint("L: Yıldız Ninnisi! Hepsi birden otursun.", "Ninni'ye bas: hepsi birden otursun!")


func _spawn_ninni_mob(k: int) -> void:
	var a := TAU * k / 4.0
	var m := Mob.spawn(self, "kopuklu_tavuk" if k % 2 == 0 else "gurultucu_kurbaga", Vector3(cos(a) * 2.2, D_TOP, -37.0 + sin(a) * 2.2))
	_ninni_mobs.append(m)


## Never a dead end: if too few Köpüklüler are left to lull (some were hit
## and calmed instead), new ones come, with a reminder to use the lullaby.
var _wave_t := 0.0


func _process(delta: float) -> void:
	if GameState.in_dialogue:
		return
	var d := GameState.data
	# the breathing step: creatures that calmed on their own leave nobody to
	# breathe with, so one more comes along
	_wave_t -= delta
	if _stage <= 1 and _wave_t <= 0.0 and not d.objective_done(QUEST, "nefes") \
			and get_tree().get_nodes_in_group("mob").is_empty() and get_tree().get_nodes_in_group("dazed").is_empty():
		_wave_t = 2.0
		var at := _player.global_position + Vector3(2.5, 0, -2.5)
		at.y = 0.0 if at.z > -9.0 else B_TOP
		Mob.spawn(self, "kopuklu_tavuk", at)
	if _stage != 4:
		return
	if d.objective_done(QUEST, "ninni"):
		return
	var need := d.objective_count(QUEST, "ninni")
	var left := need.y - need.x
	var lullable := 0
	for m in _ninni_mobs:
		if is_instance_valid(m) and not m.state in ["dazed", "calm"]:
			lullable += 1
	if lullable < left:
		for k in left - lullable:
			_spawn_ninni_mob(_ninni_mobs.size() + k)
		_hud.show_hint("Yeni Köpüklüler geldi! Vurma, Ninni ile uyut.", "Vurma, Ninni ile uyut!")


func _end() -> void:
	await get_tree().create_timer(0.8).timeout
	GameState.bark("s3b_ses")
	await GameState.dialogue_closed
	if DevTools.demo == "path" and DisplayServer.get_name() == "headless":
		var d := GameState.data
		print("S3B_PATH level=%d skill=%s flag=%s quest=%s" % [d.level, d.skills, d.has_flag("s2_sahne3_bitti"), d.quest_state(QUEST)])
		get_tree().quit()
		return
	SceneFlow.go_to("s2_scene4")


# --- level ---------------------------------------------------------------

func _build() -> void:
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	# A: the springs path
	WorldLook.block(lv, Vector3(0, -0.5, 8), Vector3(40, 1, 40), SOIL, 0.0)
	Toon.part(lv, "box", Vector3(3, 0.06, 30), Color("#e8c890"), Vector3(0, 0.01, 6), Vector3.ZERO, 0.0, 0.0)
	for v: Vector3 in VENTS:
		var pool := Toon.part(lv, "cylinder", Vector3(1.8, 0.08, 1.8), Color("#e86f5a"), v + Vector3.UP * 0.03, Vector3.ZERO, 0.6, 0.0)
		pool.name = "Pool"
		Toon.part(lv, "cylinder", Vector3(2.1, 0.06, 2.1), ROCK_DARK, v + Vector3.UP * 0.02, Vector3.ZERO, 0.0, 0.0)
	# stairs up to terrace B
	for i in 3:
		var h := float(i + 1)
		WorldLook.block(lv, Vector3(0, h * 0.5, -10.0 - i * 1.4 + 0.7), Vector3(6, h, 1.4), ROCK)
	# B: terrace
	WorldLook.block(lv, Vector3(0, B_TOP * 0.5, -16.6), Vector3(12, B_TOP, 7.2), ROCK)
	Toon.part(lv, "box", Vector3(12.05, 0.1, 7.25), SOIL, Vector3(0, B_TOP + 0.01, -16.6), Vector3.ZERO, 0.0, 0.0)
	# the chasm: a safe floor below (falling just means walking back up)
	WorldLook.block(lv, Vector3(0, -0.5, -24), Vector3(14, 1, 8.4), ROCK_DARK, 0.0)
	for i in 3:
		var h := float(i + 1)
		WorldLook.block(lv, Vector3(-5.2, h * 0.5, -22.2 + i * 0.7), Vector3(1.6, h, 0.8), ROCK)
	# D: the high ledge on the far side and the pass
	WorldLook.block(lv, Vector3(0, D_TOP * 0.5, -39), Vector3(12, D_TOP, 22), ROCK)
	Toon.part(lv, "box", Vector3(12.05, 0.1, 22.05), SOIL, Vector3(0, D_TOP + 0.01, -39), Vector3.ZERO, 0.0, 0.0)
	# side walls all the way up (nobody falls off the mountain)
	var leaves := [Color("#e8833a"), Color("#d9542f"), Color("#f2b33d"), Color("#c9452f")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for side: float in [-1.0, 1.0]:
		WorldLook.block(lv, Vector3(7.2 * side, 3.5, -16), Vector3(2.4, 7, 72), ROCK_DARK)
		for z in range(20, -52, -6):
			Toon.part(lv, "cone", Vector3(2.6, 4.0 + float(absi(z)) * 0.05, 2.6), ROCK, Vector3(8.0 * side, 8.6, float(z)))
			# autumn bushes along the rim of the path
			Toon.part(lv, "sphere", Vector3(2.2, 1.6, 2.2), leaves[rng.randi() % leaves.size()], Vector3(6.4 * side, 7.6, float(z) - 3.0))
		# outside the walls: more autumn trees, so the edge of the world never shows
		for z in range(24, -56, -5):
			var x := (10.5 + rng.randf() * 6.0) * side
			Toon.part(lv, "cylinder", Vector3(0.5, 3.0, 0.5), Color("#7a4a32"), Vector3(x, 1.5, float(z)))
			Toon.part(lv, "sphere", Vector3(3.2, 2.8, 3.2), leaves[rng.randi() % leaves.size()], Vector3(x, 4.0, float(z)))
	# the pass: two big rocks and a red glow behind them
	for side: float in [-1.0, 1.0]:
		Toon.part(lv, "cone", Vector3(4, 7, 4), ROCK_DARK, Vector3(3.6 * side, D_TOP + 3.5, -49))
	var glow := OmniLight3D.new()
	glow.light_color = Tokens.color("hp")
	glow.light_energy = 2.5
	glow.omni_range = 10.0
	glow.position = Vector3(0, D_TOP + 3.0, -51)
	lv.add_child(glow)
	WorldLook.block(lv, Vector3(0, 4, -51.5), Vector3(14, 8, 1), ROCK_DARK)
	# crackling stones by the path: little sparks pop out of them now and then
	for p: Vector3 in [Vector3(-4.6, 0, 9), Vector3(4.4, 0, -6), Vector3(4.6, D_TOP, -32), Vector3(-4.4, D_TOP, -44)]:
		var s := Toon.part(lv, "sphere", Vector3(1.1, 0.8, 1.0), Color("#8a5a4a"), p + Vector3.UP * 0.35, Vector3.ZERO, 0.0, 0.03)
		_crackle(s)
	_checkpoint(lv, "kaynak_sonu", Vector3(0, 0, -7.0))
	_checkpoint(lv, "ucurum_ote", Vector3(0, D_TOP, -30.5))
	_checkpoint(lv, "dag_gecidi", Vector3(0, D_TOP, -46.0))
	TravelSign.board(lv, "Dağ Geçidi ↑", Vector3(-3.2, D_TOP + 1.3, -44.5), 2.4)
	Toon.part(lv, "box", Vector3(0.16, 1.2, 0.16), Color("#a86b45"), Vector3(-3.2, D_TOP + 0.6, -44.55))
	for at: Vector3 in [Vector3(-2.5, 0, -6.5), Vector3(2.5, 0, -7.5)]:
		Mob.spawn(self, "kopuklu_tavuk", at)
	Mob.spawn(self, "gurultucu_kurbaga", Vector3(0, 0, -8.5))
	_player.respawn_point = _player.global_position


func _checkpoint(parent: Node3D, area_id: String, at: Vector3) -> void:
	var t := TriggerArea.new()
	t.area_id = area_id
	t.checkpoint = true
	t.radius = 2.4 if area_id != "ucurum_ote" else 5.5
	parent.add_child(t)
	t.position = at
	t.reached.connect(func() -> void:
		Effects.sparkle(self, at + Vector3.UP * 1.5, Tokens.color("spark-white"), 10))


## A boiling spring: every few seconds a steam ring is announced (0.8 s, like
## every attack), then puffs. Standing in it stings a little and pushes back.
func _vent_loop(at: Vector3, delay: float) -> void:
	await get_tree().create_timer(2.0 + delay).timeout
	while is_inside_tree() and _vents_on:
		Effects.warning(self, at, VENT_RADIUS, Mob.TELEGRAPH)
		await get_tree().create_timer(Mob.TELEGRAPH).timeout
		if not is_inside_tree():
			return
		Effects.ring(self, at + Vector3.UP * 0.4, VENT_RADIUS + 0.3, Color(1, 1, 1, 0.9), 0.5)
		Effects.sparkle(self, at + Vector3.UP * 1.2, Color(1, 1, 1), 8)
		var flat := Vector2(_player.global_position.x - at.x, _player.global_position.z - at.z)
		if flat.length() < VENT_RADIUS and _player.global_position.y < 1.0 and not GameState.in_dialogue:
			if _player.hurt(5, at):
				_player.push(Vector3(flat.x, 0, flat.y).normalized() * 8.0)
				if not GameState.data.has_flag("s3b_kaynak"):
					GameState.data.set_flag("s3b_kaynak")
					GameState.bark("s3b_kaynak")
		await get_tree().create_timer(VENT_PERIOD).timeout


func _crackle(stone: Node3D) -> void:
	var tw := stone.create_tween().set_loops()
	tw.tween_interval(randf_range(1.5, 3.5))
	tw.tween_callback(func() -> void:
		Effects.sparkle(self, stone.global_position + Vector3.UP * 0.5, Tokens.color("honey"), 3))


func _run_demo(which: String) -> void:
	match which:
		"hitfirst":
			# the softlock check: daze every Köpüklü by hitting, then lull the newcomers
			DevTools.auto_dialogue = true
			var d := GameState.data
			for oid: String in ["kaynak", "nefes", "ucurum"]:
				while not d.objective_done(QUEST, oid):
					d.advance_objective(QUEST, oid)
			_advance()
			for i in 40:
				await get_tree().create_timer(0.3).timeout
				await close_dialogs()
				if _stage == 4:
					break
			for m in _ninni_mobs.duplicate():
				m.hit(9999, m.global_position + Vector3.BACK, 0.0)
			await get_tree().create_timer(1.0).timeout
			var fresh := 0
			for m in _ninni_mobs:
				if is_instance_valid(m) and not m.state in ["dazed", "calm"]:
					fresh += 1
			_player.global_position = Vector3(0, D_TOP + 0.3, -36.0)
			await get_tree().create_timer(0.4).timeout
			d.mp = d.max_mp
			_player._attack_cd = 0.0
			_player.use_skill()
			await get_tree().create_timer(0.5).timeout
			print("S3B_HITFIRST fresh=%d ninni=%s" % [fresh, d.objective_done(QUEST, "ninni")])
			get_tree().quit()
		"path":
			# the whole scene, scripted (headless check): springs, breathe two,
			# float over the chasm, lullaby, the pass
			DevTools.auto_dialogue = true
			await walk_to(Vector3(0, 0, -6.0), 6.0)
			for i in 40:
				var dazed := get_tree().get_nodes_in_group("dazed")
				var mobs := get_tree().get_nodes_in_group("mob")
				if GameState.data.objective_done(QUEST, "nefes"):
					break
				print("S3B loop %d mobs=%d dazed=%d" % [i, mobs.size(), dazed.size()])
				if not dazed.is_empty():
					_player.global_position = (dazed[0] as Node3D).global_position + Vector3(0, 0.3, 1.3)
					await get_tree().physics_frame
					Input.action_press("calm")
					await get_tree().create_timer(BreathCalm.BREATH_IN + BreathCalm.BREATH_OUT + 0.4).timeout
					Input.action_release("calm")
				elif not mobs.is_empty():
					(mobs[0] as Mob).hit(999, _player.global_position, 0.5)
				await get_tree().create_timer(0.3).timeout
			await close_dialogs()
			print("S3B nefes=%s" % GameState.data.objective_done(QUEST, "nefes"))
			# up the stairs onto the terrace, to its far edge
			await walk_to(Vector3(0, 0, -8.0), 3.0)
			await _hop_to(Vector3(0, B_TOP, -14.0), 4.0)
			await walk_to(Vector3(0, B_TOP, -19.4), 3.0)
			print("S3B terrace y=%.2f z=%.2f" % [_player.global_position.y, _player.global_position.z])
			# jump and float north across the chasm
			Input.action_press("move_forward")
			Input.action_press("jump")
			await get_tree().create_timer(2.4).timeout
			Input.action_release("jump")
			await get_tree().create_timer(0.4).timeout
			Input.action_release("move_forward")
			print("S3B chasm y=%.2f z=%.2f ucurum=%s" % [_player.global_position.y, _player.global_position.z, GameState.data.objective_done(QUEST, "ucurum")])
			for i in 30:
				await get_tree().create_timer(0.5).timeout
				await close_dialogs()
				if _stage >= 4:
					break
			await walk_to(Vector3(0, D_TOP, -35.0), 3.0)
			await get_tree().create_timer(0.3).timeout
			GameState.data.mp = GameState.data.max_mp
			_player.use_skill()
			await get_tree().create_timer(1.0).timeout
			print("S3B ninni=%s lulled=%d" % [GameState.data.objective_done(QUEST, "ninni"), GameState.data.objective_count(QUEST, "ninni").x])
			if not GameState.data.objective_done(QUEST, "ninni"):
				GameState.data.mp = GameState.data.max_mp
				_player._attack_cd = 0.0
				_player.use_skill()
			await close_dialogs()
			await walk_to(Vector3(0, D_TOP, -46.0), 5.0)
		"jumponly":
			# a plain jump must not cross the chasm
			_player.global_position = Vector3(0, B_TOP + 0.3, -19.4)
			await get_tree().create_timer(0.4).timeout
			Input.action_press("move_forward")
			Input.action_press("jump")
			await get_tree().physics_frame
			await get_tree().physics_frame
			Input.action_release("jump")
			await get_tree().create_timer(2.0).timeout
			Input.action_release("move_forward")
			print("S3B jumponly y=%.2f z=%.2f ucurum=%s" % [_player.global_position.y, _player.global_position.z, GameState.data.objective_done(QUEST, "ucurum")])
			# and from the chasm floor the stairs lead back up to the terrace
			await walk_to(Vector3(-5.2, 0, -23.5), 4.0)
			await _hop_to(Vector3(-5.2, 3, -18.5), 4.0)
			print("S3B back y=%.2f z=%.2f" % [_player.global_position.y, _player.global_position.z])
			get_tree().quit()
		"stairs":
			_player.global_position = Vector3(0, 0.3, -7.5)
			await get_tree().create_timer(0.3).timeout
			await _hop_to(Vector3(0, B_TOP, -14.0), 5.0)
			print("S3B stairs y=%.2f z=%.2f" % [_player.global_position.y, _player.global_position.z])
			get_tree().quit()
		"springs":
			_player.global_position = Vector3(0, 0.3, 5.0)
		"ledge":
			_player.global_position = Vector3(0, D_TOP + 0.3, -34.0)


## Test helper: walk toward `target`, jumping every half second (stairs).
func _hop_to(target: Vector3, seconds: float) -> void:
	var t := 0.0
	var hop := 0.0
	while t < seconds:
		var aim := target - _player.global_position
		aim.y = 0.0
		if aim.length() < 0.8:
			break
		var dir := aim.normalized()
		for a in ["move_left", "move_right", "move_forward", "move_back"]:
			Input.action_release(a)
		if dir.x > 0.2: Input.action_press("move_right", dir.x)
		if dir.x < -0.2: Input.action_press("move_left", -dir.x)
		if dir.z > 0.2: Input.action_press("move_back", dir.z)
		if dir.z < -0.2: Input.action_press("move_forward", -dir.z)
		hop -= get_physics_process_delta_time()
		if hop <= 0.0 and _player.is_on_floor():
			hop = 0.45
			Input.action_press("jump")
		elif hop < 0.3:
			Input.action_release("jump")
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	for a in ["move_left", "move_right", "move_forward", "move_back", "jump"]:
		Input.action_release(a)
