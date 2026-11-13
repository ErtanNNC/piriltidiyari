class_name Dondurma
extends Node3D
## Buz Golem Dondurma, Bölüm 4 boss. See GolemPlan.

signal hp_changed(hp: int, max_hp: int)
signal defeated

var hp := GolemPlan.MAX_HP
var phase := 1
var active := false
var open := false
var _model: Node3D
var _player: Player
var _stars: Node3D


func _ready() -> void:
	set_meta("hit_radius", 2.4)
	_model = build_model()
	add_child(_model)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.8
	cyl.height = 5.0
	c.shape = cyl
	c.position.y = 2.5
	body.add_child(c)
	add_child(body)


static func build_model() -> Node3D:
	var real := ModelImport.with_parts("dondurma", {"ArmL": Vector3(-1.6, 3.4, 0), "ArmR": Vector3(1.6, 3.4, 0)})
	if real:
		return real
	var root := Node3D.new()
	# three scoops: pistachio, vanilla, strawberry, a cone hat, waffle arms
	Toon.part(root, "sphere", Vector3(3.4, 2.6, 3.2), Color("#b8e6a8"), Vector3(0, 1.3, 0))
	Toon.part(root, "sphere", Vector3(3.0, 2.4, 2.8), Color("#fff4d6"), Vector3(0, 3.2, 0))
	Toon.part(root, "sphere", Vector3(2.4, 2.1, 2.3), Color("#ffb3c6"), Vector3(0, 4.9, 0.1))
	Toon.part(root, "cone", Vector3(1.6, 2.2, 1.6), Color("#e3a76a"), Vector3(0, 6.6, 0))
	Toon.part(root, "sphere", Vector3(0.5, 0.5, 0.5), "hp", Vector3(0, 7.8, 0))
	for i in 8:
		var a := TAU * i / 8.0
		Toon.part(root, "capsule", Vector3(0.12, 0.35, 0.12), ["berry", "sky", "spark-yellow", "leaf"][i % 4], Vector3(sin(a) * 1.0, 5.6, cos(a) * 0.9 + 0.1), Vector3(randf_range(-40, 40), 0, 70), 0.0, 0.0)
	for side in [-1.0, 1.0]:
		Toon.part(root, "sphere", Vector3(0.36, 0.42, 0.16), "outline", Vector3(0.45 * side, 5.0, 1.12), Vector3.ZERO, 0.0, 0.0)
		Toon.part(root, "box", Vector3(0.5, 0.1, 0.1), "outline", Vector3(0.45 * side, 5.4, 1.08), Vector3(0, 0, 16 * side), 0.0, 0.0)
		Toon.part(root, "sphere", Vector3(0.36, 0.16, 0.08), "berry", Vector3(0.85 * side, 4.7, 1.0), Vector3.ZERO, 0.0, 0.0)
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0 else "ArmR"
		arm.position = Vector3(1.6 * side, 3.4, 0)
		root.add_child(arm)
		Toon.part(arm, "cylinder", Vector3(0.6, 2.0, 0.6), Color("#e3a76a"), Vector3(0.5 * side, -0.7, 0), Vector3(0, 0, 30 * side))
		Toon.part(arm, "sphere", Vector3(1.2, 1.2, 1.2), MountainKit.ICE, Vector3(0.95 * side, -1.6, 0), Vector3.ZERO, 0.25)
	Toon.part(root, "box", Vector3(0.8, 0.14, 0.12), "outline", Vector3(0, 4.55, 1.16), Vector3.ZERO, 0.0, 0.0)
	return root


func _process(delta: float) -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
	if _stars:
		_stars.rotation.y += delta * 4.0
	if active and not open and _player:
		var to := _player.global_position - global_position
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(to.x, to.z), 1.0 - exp(-3.0 * delta))


func start() -> void:
	active = true
	_loop()


func _loop() -> void:
	while active:
		for attack in GolemPlan.cycle(phase):
			if not active:
				return
			await get_tree().create_timer(GolemPlan.rest(phase), false).timeout
			await GameState.wait_dialogue_closed()
			if not active:
				return
			match attack:
				"icicles": await _icicles()
				"breath": await _breath()
				"slam": await _slam()


func _icicles() -> void:
	var spots: Array[Vector3] = [_player.global_position]
	for i in GolemPlan.icicles(phase) - 1:
		spots.append(spots[0] + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)))
	for s in spots:
		Effects.warning(get_parent(), s, 1.1, Mob.TELEGRAPH)
	await get_tree().create_timer(Mob.TELEGRAPH, false).timeout
	for s in spots:
		var ic := Toon.part(get_parent(), "cone", Vector3(0.7, 1.8, 0.7), MountainKit.ICE, s + Vector3.UP * 8.0, Vector3(180, 0, 0), 0.3, 0.03)
		var tw := ic.create_tween()
		tw.tween_property(ic, "global_position", s + Vector3.UP * 0.9, 0.2).set_ease(Tween.EASE_IN)
		tw.tween_interval(0.6)
		tw.tween_property(ic, "scale", Vector3.ZERO, 0.2)
		tw.tween_callback(ic.queue_free)
	await get_tree().create_timer(0.2, false).timeout
	for s in spots:
		Effects.ring(get_parent(), s + Vector3.UP * 0.2, 1.4, Tokens.color("panel@light"), 0.25)
		if Vector2(_player.global_position.x - s.x, _player.global_position.z - s.z).length() < 1.2:
			_player.hurt(GolemPlan.ICICLE_DAMAGE, s)


## Cold breath in a cone in front: slows you down for a moment.
func _breath() -> void:
	var fwd := Vector3(sin(_model.rotation.y), 0, cos(_model.rotation.y))
	for k in 3:
		for j in [-1, 0, 1]:
			var d := fwd.rotated(Vector3.UP, deg_to_rad(j * 20.0))
			Effects.warning(get_parent(), global_position + d * (2.5 + k * 2.0), 0.7, Mob.TELEGRAPH)
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(1.05, 1.08, 1.05), Mob.TELEGRAPH)
	await tw.finished
	_model.scale = Vector3.ONE
	for k in 10:
		var puff := Toon.part(get_parent(), "sphere", Vector3(0.8, 0.8, 0.8), "spark-white", global_position + Vector3.UP * 4.6 + fwd * 1.5, Vector3.ZERO, 0.4, 0.0)
		var target := global_position + fwd.rotated(Vector3.UP, deg_to_rad(randf_range(-28, 28))) * GolemPlan.BREATH_RANGE + Vector3.UP * 0.8
		var pt := puff.create_tween()
		pt.tween_property(puff, "global_position", target, 0.5)
		pt.parallel().tween_property(puff, "scale", Vector3.ONE * 2.0, 0.5)
		pt.tween_callback(puff.queue_free)
	if GolemPlan.in_breath(fwd, _player.global_position - global_position) and _player.hurt(GolemPlan.BREATH_DAMAGE, global_position):
		_player.slow = GolemPlan.BREATH_SLOW
		GameState.toast.emit("Brrr! Biraz donakaldın", "drop")
		await get_tree().create_timer(GolemPlan.BREATH_SLOW_TIME, false).timeout
		_player.slow = 1.0
	else:
		await get_tree().create_timer(0.5, false).timeout


## Both fists slam: a ring runs along the ice (jump over it) and the fists
## stick in the ice for a while — that's the moment.
func _slam() -> void:
	var spot := _player.global_position
	Effects.warning(get_parent(), global_position, 3.2, Mob.TELEGRAPH)
	get_tree().call_group("hud", "show_hint", "Halka geliyor: zıpla!", "Halka: zıpla!")
	var arms: Array[Node3D] = [_model.get_node("ArmL"), _model.get_node("ArmR")]
	var up := create_tween().set_parallel()
	for a in arms:
		up.tween_property(a, "rotation:x", -1.2, Mob.TELEGRAPH)
	await up.finished
	var down := create_tween().set_parallel()
	for a in arms:
		down.tween_property(a, "rotation:x", 0.9, 0.12)
	await down.finished
	if _player.global_position.distance_to(global_position) < 3.2:
		_player.hurt(GolemPlan.SLAM_DAMAGE, global_position)
	await _ring()
	open = true
	add_to_group("hittable")
	_stars = Node3D.new()
	_stars.position.y = 8.6
	add_child(_stars)
	for i in 4:
		var a := TAU * i / 4.0
		Toon.part(_stars, "sphere", Vector3(0.4, 0.4, 0.4), "spark-yellow", Vector3(cos(a), 0, sin(a)) * 1.1, Vector3.ZERO, 1.2, 0.02)
	get_tree().call_group("hud", "show_hint", "Yumrukları buza saplandı! Şimdi vur!", "Yumrukları saplandı! Vur!")
	await get_tree().create_timer(GolemPlan.STUCK_TIME, false).timeout
	if _stars:
		_stars.queue_free()
		_stars = null
	if not active:
		return
	open = false
	remove_from_group("hittable")
	get_tree().call_group("hud", "clear_hint")
	var back := create_tween().set_parallel()
	for a in arms:
		back.tween_property(a, "rotation:x", 0.0, 0.4)


func _ring() -> void:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.92
	t.outer_radius = 1.0
	t.rings = 48
	mi.mesh = t
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Tokens.color("sky")
	mi.material_override = m
	get_parent().add_child(mi)
	mi.global_position = global_position + Vector3.UP * 0.25
	var r := 2.5
	var hit := false
	while r < KingPlan.RING_MAX and active:
		if get_tree().paused:
			await get_tree().process_frame
			continue
		r += KingPlan.RING_SPEED * get_process_delta_time()
		mi.scale = Vector3(r, 3.0, r)
		if not hit:
			var d := Vector2(_player.global_position.x - global_position.x, _player.global_position.z - global_position.z).length()
			if KingPlan.ring_hits(d, r, _player.global_position.y - global_position.y):
				hit = _player.hurt(GolemPlan.RING_DAMAGE, global_position)
		await get_tree().process_frame
	mi.queue_free()


func hit(damage: int, _from: Vector3, _push: float) -> void:
	damage = Progression.boss_damage(damage, GameState.data.power)
	Effects.hit(self, true)
	if not open or not active:
		return
	hp = maxi(hp - damage, 0)
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 6.0, str(damage), Tokens.color("panel@light"))
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(1.06, 0.94, 1.06), 0.06)
	tw.tween_property(_model, "scale", Vector3.ONE, 0.12)
	hp_changed.emit(hp, GolemPlan.MAX_HP)
	phase = GolemPlan.phase(hp)
	if hp == 0:
		_wake()


func _wake() -> void:
	active = false
	open = false
	remove_from_group("hittable")
	if _stars:
		_stars.queue_free()
		_stars = null
	_player.slow = 1.0
	get_tree().call_group("hud", "clear_hint")
	for m in get_tree().get_nodes_in_group("mob"):
		if m.has_method("hit"):
			m.hit(9999, global_position, 0.0)
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 4, Tokens.color("spark-white"), 24)
	defeated.emit()
