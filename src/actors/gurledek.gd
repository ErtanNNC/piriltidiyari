class_name Gurledek
extends Node3D
## Gürledek, Season 2's first boss: a red thundercloud blocking the mountain
## pass. It drifts above the arena, throws lightning (spots warned 0.8 s
## ahead) and rain, then sinks low and tired: that's when it can be hit.
## At 0 HP it starts to cry and sits in group "dazed" (with a wider reach),
## so Sakinleş calms it (BreathCalm → breathe_calm): then it dissolves.

signal hp_changed(hp: int, max_hp: int)
signal phase_changed(phase: int)
signal crying
signal calmed

const HOVER := 4.2
const LOW := 1.1
const DRIFT := 4.5

var hp := GurledekPlan.MAX_HP
var phase := 1
var active := false
var low := false
var is_crying := false
var _model: Node3D
var _angry_face: Node3D
var _sad_face: Node3D
var _t := 0.0
var _busy := false
var _tears: CPUParticles3D


func _ready() -> void:
	_model = build_model()
	add_child(_model)
	_angry_face = _model.get_node("AngryFace")
	_sad_face = _model.get_node("SadFace")
	set_meta("hit_radius", 2.0)
	# Sakinleş reaches a big cloud from a little further away
	set_meta("calm_reach", 3.6)
	position = Vector3(0, HOVER + 6.0, -4.0)


## A puffy red-violet cloud with a grumpy face (and a sad one for later).
static func build_model() -> Node3D:
	var root := Node3D.new()
	Toon.default_pus = 0.0
	var cols := [Color("#c9566a"), Color("#b0475e"), Color("#d97384"), Color("#a43f56")]
	var puffs := [[Vector3(0, 0, 0), 1.9], [Vector3(-1.5, -0.2, 0.1), 1.4], [Vector3(1.5, -0.15, 0.1), 1.45],
		[Vector3(-0.8, 0.9, -0.2), 1.3], [Vector3(0.8, 0.95, -0.2), 1.25], [Vector3(-2.4, -0.5, -0.2), 0.95],
		[Vector3(2.4, -0.45, -0.2), 1.0], [Vector3(0, -0.8, 0.2), 1.3], [Vector3(0, 1.4, -0.5), 1.0]]
	for i in puffs.size():
		var p: Array = puffs[i]
		var r: float = p[1]
		Toon.part(root, "sphere", Vector3(r, r * 0.85, r) * 1.9, cols[i % cols.size()], p[0], Vector3.ZERO, 0.0, 0.035)
	var angry := Node3D.new()
	angry.name = "AngryFace"
	root.add_child(angry)
	var sad := Node3D.new()
	sad.name = "SadFace"
	sad.visible = false
	root.add_child(sad)
	for side: float in [-1.0, 1.0]:
		for face: Node3D in [angry, sad]:
			Toon.part(face, "ellipsoid", Vector3(0.36, 0.46, 0.12), "outline", Vector3(0.6 * side, 0.25, 1.75), Vector3.ZERO, 0.0, 0.0)
			Toon.part(face, "ellipsoid", Vector3(0.12, 0.13, 0.05), Color.WHITE, Vector3(0.64 * side, 0.36, 1.82), Vector3.ZERO, 0.8, 0.0)
		# angry: slanted brows and a zigzag frown
		Toon.part(angry, "box", Vector3(0.55, 0.12, 0.1), "outline", Vector3(0.6 * side, 0.62, 1.8), Vector3(0, 0, -22 * side), 0.0, 0.0)
		Toon.part(angry, "box", Vector3(0.36, 0.09, 0.08), "outline", Vector3(0.16 * side, -0.35, 1.82), Vector3(0, 0, 20 * side), 0.0, 0.0)
		# sad: brows up in the middle, a wobbly mouth, tear drops
		Toon.part(sad, "box", Vector3(0.5, 0.1, 0.1), "outline", Vector3(0.6 * side, 0.66, 1.8), Vector3(0, 0, 18 * side), 0.0, 0.0)
		Toon.part(sad, "box", Vector3(0.3, 0.08, 0.08), "outline", Vector3(0.14 * side, -0.38, 1.82), Vector3(0, 0, -18 * side), 0.0, 0.0)
		Toon.part(sad, "ellipsoid", Vector3(0.14, 0.22, 0.08), "sky", Vector3(0.68 * side, -0.05, 1.85), Vector3.ZERO, 0.6, 0.0)
	Toon.default_pus = 1.0
	return root


func _process(delta: float) -> void:
	_t += delta
	var bob := sin(_t * 1.6) * 0.2
	_model.scale = Vector3(1.0 + sin(_t * 2.2) * 0.03, 1.0 - sin(_t * 2.2) * 0.03, 1.0)
	if is_crying:
		_model.position.y = sin(_t * 9.0) * 0.05  # sobs
		return
	if active and not _busy and not low:
		var p := _player()
		var target := Vector3(sin(_t * 0.45) * DRIFT, HOVER + bob, -3.0 + cos(_t * 0.3) * 2.0)
		if p:
			target.x = lerpf(target.x, p.global_position.x, 0.35)
		position = position.lerp(target, 1.0 - exp(-1.6 * delta))
		_face_player(delta)


func start() -> void:
	active = true
	_loop()


func _loop() -> void:
	while active:
		for attack in GurledekPlan.cycle(phase):
			if not active:
				return
			await get_tree().create_timer(GurledekPlan.rest(phase)).timeout
			if not active:
				return
			await GameState.wait_dialogue_closed()
			if not active:
				return
			match attack:
				"bolt":
					await _bolts()
				"rain":
					await _rain()
				_:
					await _sink_low()


func _player() -> Player:
	return get_tree().get_first_node_in_group("player")


func _face_player(delta: float) -> void:
	var p := _player()
	if p:
		var to := p.global_position - global_position
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(to.x, to.z), 1.0 - exp(-4.0 * delta))


## Lightning: spots around the keeper are warned, then struck.
func _bolts() -> void:
	_busy = true
	var p := _player()
	var spots: Array[Vector3] = []
	var n := GurledekPlan.bolts(phase)
	for i in n:
		var off := Vector3.ZERO if i == 0 else Vector3(randf_range(-3.5, 3.5), 0, randf_range(-3.5, 3.5))
		spots.append(Vector3(p.global_position.x, 0.0, p.global_position.z) + off)
	for s in spots:
		Effects.warning(get_parent(), s, GurledekPlan.BOLT_RADIUS, Mob.TELEGRAPH)
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3.ONE * 1.15, Mob.TELEGRAPH).set_trans(Tween.TRANS_SINE)
	await tw.finished
	for s in spots:
		_strike(s)
	Effects.shake(get_viewport(), 0.5)
	Audio.play("hit")
	for s in spots:
		if Vector2(p.global_position.x - s.x, p.global_position.z - s.z).length() < GurledekPlan.BOLT_RADIUS:
			p.hurt(GurledekPlan.BOLT_DAMAGE, s)
			break
	_busy = false


func _strike(at: Vector3) -> void:
	var bolt := Toon.part(get_parent(), "box", Vector3(0.25, HOVER + 1.0, 0.25), "spark-yellow", at + Vector3.UP * (HOVER + 1.0) * 0.5, Vector3.ZERO, 3.0, 0.0)
	Effects.ring(get_parent(), at + Vector3.UP * 0.15, GurledekPlan.BOLT_RADIUS + 0.2, Tokens.color("spark-yellow"), 0.3)
	var tw := bolt.create_tween()
	tw.tween_interval(0.15)
	tw.tween_property(bolt, "scale", Vector3(0.1, 1.0, 0.1), 0.12)
	tw.tween_callback(bolt.queue_free)


## Rain: a few wide circles get soaked for a moment (small damage).
func _rain() -> void:
	_busy = true
	var p := _player()
	var spots: Array[Vector3] = []
	for i in 2 + phase / 2:
		var off := Vector3.ZERO if i == 0 else Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
		spots.append(Vector3(p.global_position.x, 0.0, p.global_position.z) + off)
	for s in spots:
		Effects.warning(get_parent(), s, GurledekPlan.RAIN_RADIUS, Mob.TELEGRAPH)
	await get_tree().create_timer(Mob.TELEGRAPH).timeout
	for s in spots:
		_shower(s)
	for tick in 3:
		for s in spots:
			if Vector2(p.global_position.x - s.x, p.global_position.z - s.z).length() < GurledekPlan.RAIN_RADIUS:
				p.hurt(GurledekPlan.RAIN_DAMAGE, s)
				break
		await get_tree().create_timer(0.35).timeout
	_busy = false


func _shower(at: Vector3) -> void:
	var r := CPUParticles3D.new()
	r.amount = 40
	r.lifetime = 0.6
	r.one_shot = true
	r.explosiveness = 0.0
	r.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	r.emission_box_extents = Vector3(GurledekPlan.RAIN_RADIUS, 0.1, GurledekPlan.RAIN_RADIUS)
	r.direction = Vector3.DOWN
	r.spread = 2.0
	r.gravity = Vector3(0, -30, 0)
	r.initial_velocity_min = 6.0
	r.initial_velocity_max = 8.0
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Tokens.color("sky")
	var q := BoxMesh.new()
	q.size = Vector3(0.05, 0.4, 0.05)
	q.material = m
	r.mesh = q
	get_parent().add_child(r)
	r.global_position = at + Vector3.UP * 4.0
	r.emitting = true
	get_tree().create_timer(1.6).timeout.connect(r.queue_free)


## Tired: it sinks low and puffs; this is when it can be hit.
func _sink_low() -> void:
	_busy = true
	var down := create_tween()
	down.tween_property(self, "position:y", LOW, 0.6).set_trans(Tween.TRANS_SINE)
	await down.finished
	low = true
	add_to_group("hittable")
	get_tree().call_group("hud", "show_hint", "Yoruldu, alçaldı! Şimdi vur!", "Alçaldı! Şimdi vur!")
	await get_tree().create_timer(GurledekPlan.LOW_TIME).timeout
	if not active:
		return
	get_tree().call_group("hud", "clear_hint")
	low = false
	remove_from_group("hittable")
	var up := create_tween()
	up.tween_property(self, "position:y", HOVER, 0.7).set_trans(Tween.TRANS_BACK)
	await up.finished
	_busy = false


## Only lands while it is low and tired.
func hit(damage: int, _from: Vector3, _push: float) -> void:
	damage = Progression.boss_damage(damage, GameState.data.power)
	Effects.hit(self, true)
	if not low or not active:
		return
	hp = maxi(hp - damage, 0)
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 2.8, str(damage), Tokens.color("panel@light"))
	hp_changed.emit(hp, GurledekPlan.MAX_HP)
	var p := GurledekPlan.phase(hp)
	if hp == 0:
		_cry()
	elif p != phase:
		phase = p
		phase_changed.emit(phase)


## Out of thunder: it sits down and cries. A breath (Sakinleş) is the way on.
func _cry() -> void:
	active = false
	low = false
	is_crying = true
	remove_from_group("hittable")
	get_tree().call_group("hud", "clear_hint")
	var down := create_tween()
	down.tween_property(self, "position:y", LOW, 0.5)
	_angry_face.visible = false
	_sad_face.visible = true
	_tears = CPUParticles3D.new()
	_tears.amount = 10
	_tears.lifetime = 0.8
	_tears.direction = Vector3.DOWN
	_tears.gravity = Vector3(0, -6, 0)
	_tears.initial_velocity_min = 0.5
	_tears.initial_velocity_max = 1.0
	_tears.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_tears.emission_box_extents = Vector3(0.8, 0.05, 0.1)
	var q := SphereMesh.new()
	q.radius = 0.07
	q.height = 0.14
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Tokens.color("sky")
	q.material = m
	_tears.mesh = q
	_tears.position = Vector3(0, -0.1, 1.7)
	_model.add_child(_tears)
	add_to_group("dazed")
	crying.emit()


## Sakinleş on the crying cloud: the rumble quiets down.
func breathe_calm() -> void:
	if not is_crying:
		return
	is_crying = false
	remove_from_group("dazed")
	if _tears:
		_tears.emitting = false
	GameState.notify("breathe", "gurledek")
	calmed.emit()


## The end: the cloud thins into soft wisps and is gone.
func dissolve() -> void:
	for i in 5:
		Effects.sparkle(get_parent(), global_position + Vector3(randf_range(-2, 2), randf_range(-0.5, 1.5), randf_range(-1, 1)), Color("#d97384"), 10)
	var tw := create_tween().set_parallel()
	tw.tween_property(_model, "scale", Vector3(1.8, 0.05, 1.8), 1.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position:y", position.y + 1.5, 1.6)
	await tw.finished
	_model.visible = false
