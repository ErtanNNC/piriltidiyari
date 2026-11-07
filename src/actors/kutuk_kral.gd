class_name KutukKral
extends Node3D
## Kütük Kral, Bölüm 1 boss. A huge grumpy stump with a crown who has
## swallowed the Yeşil Kıvılcım. See KingPlan for the rules.

signal hp_changed(hp: int, max_hp: int)
signal phase_changed(phase: int)
signal defeated

var hp := KingPlan.MAX_HP
var phase := 1
var active := false
var dazed := false
var _model: Node3D
var _zzz: Label3D


func _ready() -> void:
	set_meta("hit_radius", 2.0)
	_model = _build_model()
	add_child(_model)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.9
	cyl.height = 3.0
	c.shape = cyl
	c.position.y = 1.5
	body.add_child(c)
	add_child(body)
	_zzz = Label3D.new()
	_zzz.text = "z z Z"
	_zzz.font = Tokens.font_for("text-hero")
	_zzz.font_size = 96
	_zzz.pixel_size = 0.008
	_zzz.outline_size = 20
	_zzz.outline_modulate = Tokens.color("outline")
	_zzz.modulate = Tokens.color("sky")
	_zzz.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_zzz.position = Vector3(1.4, 5.2, 0)
	_zzz.visible = false
	add_child(_zzz)


func _process(_delta: float) -> void:
	if dazed:
		_zzz.position.y = 5.2 + sin(Time.get_ticks_msec() / 300.0) * 0.2
		_model.rotation.z = sin(Time.get_ticks_msec() / 500.0) * 0.06


static func _build_model() -> Node3D:
	var root := Node3D.new()
	var bark := Color("#9a6744")
	Toon.part(root, "cylinder", Vector3(3.4, 3.0, 3.9), bark, Vector3(0, 1.5, 0))
	Toon.part(root, "cylinder", Vector3(3.2, 0.12, 3.2), Color("#e8c795"), Vector3(0, 3.02, 0), Vector3.ZERO, 0.0, 0.02)
	Toon.part(root, "torus", Vector3(2.0, 0.06, 2.0), Color("#c49a6c"), Vector3(0, 3.08, 0), Vector3.ZERO, 0.0, 0.0)
	# crown
	for i in 5:
		var a := TAU * i / 5.0
		Toon.part(root, "cone", Vector3(0.5, 0.9, 0.5), "honey", Vector3(sin(a) * 1.15, 3.5, cos(a) * 1.15))
	Toon.part(root, "torus", Vector3(2.7, 0.18, 2.7), "honey-deep", Vector3(0, 3.15, 0))
	# grumpy sleepy face with eye bags
	for s in [-1.0, 1.0]:
		Toon.part(root, "sphere", Vector3(0.6, 0.5, 0.2), Color("#e8c795"), Vector3(0.6 * s, 2.0, 1.72))
		Toon.part(root, "sphere", Vector3(0.28, 0.32, 0.12), "outline", Vector3(0.6 * s, 2.05, 1.8), Vector3.ZERO, 0.0, 0.0)
		Toon.part(root, "box", Vector3(0.7, 0.12, 0.12), "outline", Vector3(0.6 * s, 2.45, 1.76), Vector3(0, 0, 14 * s), 0.0, 0.0)
		Toon.part(root, "sphere", Vector3(0.5, 0.16, 0.1), Color("#7a5236"), Vector3(0.6 * s, 1.68, 1.8), Vector3.ZERO, 0.0, 0.0)
		# branch arms with leaves
		Toon.part(root, "cylinder", Vector3(0.3, 1.8, 0.36), bark, Vector3(2.05 * s, 1.9, 0), Vector3(0, 0, 60 * s))
		Toon.part(root, "sphere", Vector3(1.1, 0.9, 1.0), "leaf", Vector3(2.8 * s, 2.5, 0))
		# roots
		for k in 2:
			Toon.part(root, "capsule", Vector3(0.5, 1.6, 0.5), bark, Vector3(1.6 * s, 0.25, 0.9 - k * 1.8), Vector3(0, 0, 70 * s))
	Toon.part(root, "box", Vector3(0.9, 0.14, 0.12), "outline", Vector3(0, 1.3, 1.82), Vector3(0, 0, 180), 0.0, 0.0)
	return root


func start() -> void:
	active = true
	_loop()


func _player() -> Player:
	return get_tree().get_first_node_in_group("player")


func _loop() -> void:
	while active:
		for attack in KingPlan.cycle(phase):
			if not active:
				return
			await get_tree().create_timer(KingPlan.rest(phase)).timeout
			if not active:
				return
			await GameState.wait_dialogue_closed()
			if not active:
				return
			match attack:
				"roots": await _roots()
				"summon": await _summon()
				"stomp": await _stomp()


func _roots() -> void:
	var p := _player()
	var spots: Array[Vector3] = []
	var base := Vector3(p.global_position.x, 0, p.global_position.z)
	spots.append(base)
	for i in KingPlan.root_count(phase) - 1:
		spots.append(base + Vector3(randf_range(-3.5, 3.5), 0, randf_range(-3.5, 3.5)))
	for s in spots:
		Effects.warning(get_parent(), s, 1.1, Mob.TELEGRAPH)
	_model.scale = Vector3(1.04, 0.96, 1.04)
	await get_tree().create_timer(Mob.TELEGRAPH).timeout
	_model.scale = Vector3.ONE
	var roots: Array[Node3D] = []
	for s in spots:
		var r := Node3D.new()
		get_parent().add_child(r)
		r.global_position = s
		Toon.part(r, "cone", Vector3(0.7, 1.6, 0.7), Color("#9a6744"), Vector3(0, 0.8, 0))
		Toon.part(r, "sphere", Vector3(0.5, 0.3, 0.5), "leaf", Vector3(0.2, 1.2, 0))
		r.scale = Vector3(1, 0.05, 1)
		var tw := r.create_tween()
		tw.tween_property(r, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK)
		roots.append(r)
		if Vector2(p.global_position.x - s.x, p.global_position.z - s.z).length() < 1.2:
			p.hurt(KingPlan.ROOT_DAMAGE, s)
	await get_tree().create_timer(0.7).timeout
	for r in roots:
		var tw := r.create_tween()
		tw.tween_property(r, "scale", Vector3(1, 0.01, 1), 0.2)
		tw.tween_callback(r.queue_free)


func _summon() -> void:
	for side in [-1.0, 1.0]:
		Mob.spawn(get_parent(), "kirpi_topu", global_position + Vector3(3.5 * side, 0, 3.0))
	await get_tree().create_timer(0.6).timeout


func _stomp() -> void:
	# tell: rise up and shake for 0.8 s
	get_tree().call_group("hud", "show_hint", "Halka geliyor: üstünden zıpla!", "Halka geliyor: zıpla!")
	var up := create_tween()
	up.tween_property(_model, "position:y", 1.6, Mob.TELEGRAPH).set_trans(Tween.TRANS_SINE)
	await up.finished
	var down := create_tween()
	down.tween_property(_model, "position:y", 0.0, 0.12).set_ease(Tween.EASE_IN)
	await down.finished
	await _ring()
	await _daze()


## The shockwave: a ring spreading along the ground; jump over it.
func _ring() -> void:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.92
	t.outer_radius = 1.0
	t.rings = 48
	mi.mesh = t
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Tokens.color("honey-deep")
	mi.material_override = m
	get_parent().add_child(mi)
	mi.global_position = global_position + Vector3.UP * 0.25
	var r := 2.0
	var hit := false
	var p := _player()
	while r < KingPlan.RING_MAX and active:
		r += KingPlan.RING_SPEED * get_process_delta_time()
		mi.scale = Vector3(r, 3.0, r)
		if not hit and p:
			var d := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
			if KingPlan.ring_hits(d, r, p.global_position.y):
				hit = p.hurt(KingPlan.RING_DAMAGE, global_position)
		await get_tree().process_frame
	mi.queue_free()


func _daze() -> void:
	dazed = true
	add_to_group("hittable")
	_zzz.visible = true
	get_tree().call_group("hud", "show_hint", "Kral esniyor! Şimdi vur!", "Kral esniyor! Şimdi vur!")
	await get_tree().create_timer(KingPlan.DAZE_TIME).timeout
	if not active:
		return
	get_tree().call_group("hud", "clear_hint")
	dazed = false
	_zzz.visible = false
	_model.rotation.z = 0.0
	remove_from_group("hittable")


func hit(damage: int, _from: Vector3, _push: float) -> void:
	if not dazed or not active:
		return
	hp = maxi(hp - damage, 0)
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 4.5, str(damage), Tokens.color("panel"))
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(1.08, 0.92, 1.08), 0.06)
	tw.tween_property(_model, "scale", Vector3.ONE, 0.12)
	hp_changed.emit(hp, KingPlan.MAX_HP)
	var ph := KingPlan.phase(hp)
	if hp == 0:
		_wake()
	elif ph != phase:
		phase = ph
		phase_changed.emit(phase)


## Beaten: he finally wakes up properly — and he's sorry.
func _wake() -> void:
	active = false
	dazed = false
	remove_from_group("hittable")
	_zzz.visible = false
	_model.rotation.z = 0.0
	get_tree().call_group("hud", "clear_hint")
	for m in get_tree().get_nodes_in_group("mob"):
		if m.has_method("hit"):
			m.hit(9999, global_position, 0.0)
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 3, Tokens.color("spark-green"), 24)
	defeated.emit()
