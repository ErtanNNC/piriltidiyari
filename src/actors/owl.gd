class_name Owl
extends Node3D
## Pus Baykuşu, the first boss. Circles the tower top, throws feather fans
## and dives at you. Every attack is told 0.8 s ahead. After a dive it is
## dazed on the ground: that's when the quills can hit.

signal hp_changed(hp: int, max_hp: int)
signal phase_changed(phase: int)
signal defeated

const ORBIT_RADIUS := 6.5
const ORBIT_HEIGHT := 3.2

var hp := OwlPlan.MAX_HP
var phase := 1
var active := false
var dazed := false
var _model: Node3D
var _angle := 0.0
var _busy := false
var _stars: Node3D


func _ready() -> void:
	_model = OwlModel.build()
	add_child(_model)
	set_meta("hit_radius", 1.4)
	position = Vector3(0, ORBIT_HEIGHT + 6.0, -ORBIT_RADIUS)


func _process(delta: float) -> void:
	var flap := sin(Time.get_ticks_msec() / (90.0 if not dazed else 400.0)) * (0.6 if not dazed else 0.1)
	_model.get_node("WingL").rotation.z = flap
	_model.get_node("WingR").rotation.z = -flap
	if _stars:
		_stars.rotation.y += delta * 4.0
	if active and not _busy and not dazed:
		_angle += delta * (0.35 + 0.1 * phase)
		var target := Vector3(sin(_angle) * ORBIT_RADIUS, ORBIT_HEIGHT, cos(_angle) * ORBIT_RADIUS)
		position = position.lerp(target, 1.0 - exp(-2.5 * delta))
		_face_player(delta)


func start() -> void:
	active = true
	_loop()


func _loop() -> void:
	while active:
		for attack in OwlPlan.cycle(phase):
			if not active:
				return
			await get_tree().create_timer(OwlPlan.rest(phase), false).timeout
			if not active:
				return
			await GameState.wait_dialogue_closed()
			if not active:
				return
			if attack == "volley":
				await _volley()
			else:
				await _dive()


func _player() -> Player:
	return get_tree().get_first_node_in_group("player")


func _face_player(delta: float) -> void:
	var p := _player()
	if p:
		var to := p.global_position - global_position
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(to.x, to.z), 1.0 - exp(-6.0 * delta))


func _volley() -> void:
	_busy = true
	var p := _player()
	var spec := OwlPlan.volley(phase)
	# tell: puff up and shake for 0.8 s, warning lines on the ground
	var origin := Vector3(global_position.x, 0.0, global_position.z)
	var aim := (p.global_position - origin)
	aim.y = 0.0
	aim = aim.normalized()
	for i in int(spec.x):
		var a := deg_to_rad(-spec.y * 0.5 + spec.y * i / maxf(spec.x - 1.0, 1.0))
		var d := aim.rotated(Vector3.UP, a)
		for k in 3:
			Effects.warning(get_parent(), origin + d * (2.5 + k * 2.0), 0.5, Mob.TELEGRAPH)
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3.ONE * 1.18, Mob.TELEGRAPH).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_model.scale = Vector3.ONE
	for i in int(spec.x):
		var a := deg_to_rad(-spec.y * 0.5 + spec.y * i / maxf(spec.x - 1.0, 1.0))
		var f := Feather.new()
		f.direction = aim.rotated(Vector3.UP, a)
		get_parent().add_child(f)
		f.global_position = origin + Vector3.UP * 0.8 + f.direction * 1.2
	_busy = false


func _dive() -> void:
	_busy = true
	var p := _player()
	var spot := Vector3(p.global_position.x, 0.0, p.global_position.z)
	# rise, then the shadow warning where it will land
	var up := create_tween()
	up.tween_property(self, "position", Vector3(spot.x, 9.0, spot.z), 0.6).set_trans(Tween.TRANS_SINE)
	await up.finished
	Effects.warning(get_parent(), spot, 2.0, Mob.TELEGRAPH)
	await get_tree().create_timer(Mob.TELEGRAPH, false).timeout
	var down := create_tween()
	down.tween_property(self, "position", spot, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await down.finished
	Effects.ring(get_parent(), spot + Vector3.UP * 0.2, 3.0, Tokens.color("pus"), 0.4)
	if p.global_position.distance_to(spot) < 2.2:
		p.hurt(OwlPlan.DIVE_DAMAGE, spot)
	await _daze()
	_busy = false


func _daze() -> void:
	dazed = true
	add_to_group("hittable")
	_stars = Node3D.new()
	_stars.position.y = 4.3
	add_child(_stars)
	for i in 4:
		var a := TAU * i / 4.0
		Toon.part(_stars, "sphere", Vector3(0.35, 0.35, 0.35), "spark-yellow", Vector3(cos(a), 0, sin(a)) * 0.9, Vector3.ZERO, 1.2, 0.02)
	get_tree().call_group("hud", "show_hint", "Sersemledi! Şimdi vur!", "Sersemledi! Şimdi vur!")
	await get_tree().create_timer(OwlPlan.STUN_TIME, false).timeout
	if not active:
		return
	get_tree().call_group("hud", "clear_hint")
	dazed = false
	remove_from_group("hittable")
	_stars.queue_free()
	_stars = null
	var back := create_tween()
	back.tween_property(self, "position:y", ORBIT_HEIGHT, 0.6).set_trans(Tween.TRANS_BACK)
	await back.finished


## Player quills. Only lands while dazed (the group handles that).
func hit(damage: int, _from: Vector3, _push: float) -> void:
	damage = Progression.boss_damage(damage, GameState.data.power)
	Effects.hit(self, true)
	if not dazed or not active:
		return
	hp = maxi(hp - damage, 0)
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 4.5, str(damage), Tokens.color("panel@light"))
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(1.15, 0.85, 1.15), 0.06)
	tw.tween_property(_model, "scale", Vector3.ONE, 0.12)
	hp_changed.emit(hp, OwlPlan.MAX_HP)
	var p := OwlPlan.phase(hp)
	if hp == 0:
		_defeat()
	elif p != phase:
		phase = p
		phase_changed.emit(phase)


func _defeat() -> void:
	active = false
	remove_from_group("hittable")
	get_tree().call_group("hud", "clear_hint")
	if _stars:
		_stars.queue_free()
	for i in 4:
		Effects.sparkle(get_parent(), global_position + Vector3(randf_range(-1, 1), 1.5 + i * 0.6, randf_range(-1, 1)), Tokens.color("pus"), 12)
	var tw := create_tween().set_parallel()
	tw.tween_property(_model, "scale", Vector3(1.6, 0.05, 1.6), 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position:y", position.y + 1.0, 1.4)
	await tw.finished
	_model.visible = false
	defeated.emit()
