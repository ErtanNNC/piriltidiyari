class_name Kiskac
extends Node3D
## Kristal Yengeç Kıskaç, Bölüm 2 boss. See CrabPlan.

signal hp_changed(hp: int, max_hp: int)
signal defeated

var hp := CrabPlan.MAX_HP
var phase := 1
var active := false
var open := false   ## can be hit right now (claw stuck / dizzy)
var arena_center := Vector3.ZERO
var arena_radius := 9.0
var _model: Node3D
var _stars: Node3D


func _ready() -> void:
	set_meta("hit_radius", 2.2)
	_model = KiskacModel.build()
	add_child(_model)


func _process(delta: float) -> void:
	if _stars:
		_stars.rotation.y += delta * 4.0
	if active and not open:
		var p := _player()
		if p:
			var to := p.global_position - global_position
			_model.rotation.y = lerp_angle(_model.rotation.y, atan2(to.x, to.z), 1.0 - exp(-5.0 * delta))


func _player() -> Player:
	return get_tree().get_first_node_in_group("player")


func start() -> void:
	active = true
	_loop()


func _loop() -> void:
	while active:
		for attack in CrabPlan.cycle(phase):
			if not active:
				return
			await get_tree().create_timer(CrabPlan.rest(phase)).timeout
			await GameState.wait_dialogue_closed()
			if not active:
				return
			match attack:
				"bubbles": await _bubbles()
				"claw": await _claw()
				"spin": await _spin()


func _scuttle_to(target: Vector3, seconds: float) -> void:
	var to := target - arena_center
	to.y = 0.0
	if to.length() > arena_radius:
		target = arena_center + to.normalized() * arena_radius
	var tw := create_tween()
	tw.tween_property(self, "global_position", Vector3(target.x, global_position.y, target.z), seconds).set_trans(Tween.TRANS_SINE)
	await tw.finished


func _bubbles() -> void:
	var p := _player()
	var aim := p.global_position - global_position
	aim.y = 0.0
	aim = aim.normalized()
	var n := CrabPlan.bubbles(phase)
	var spread := 70.0
	for i in n:
		var d := aim.rotated(Vector3.UP, deg_to_rad(-spread * 0.5 + spread * i / maxf(n - 1, 1)))
		for k in 2:
			Effects.warning(get_parent(), global_position + d * (3.0 + k * 2.2), 0.45, Mob.TELEGRAPH)
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(1.1, 0.9, 1.1), Mob.TELEGRAPH).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_model.scale = Vector3.ONE
	for i in n:
		var b := Bubble.new()
		b.direction = aim.rotated(Vector3.UP, deg_to_rad(-spread * 0.5 + spread * i / maxf(n - 1, 1)))
		get_parent().add_child(b)
		b.global_position = global_position + b.direction * 1.8 + Vector3.UP * 0.8


func _claw() -> void:
	var p := _player()
	var near := p.global_position + (global_position - p.global_position).normalized() * 3.0
	await _scuttle_to(near, 0.7)
	var spot := Vector3(p.global_position.x, 0.0, p.global_position.z)
	Effects.warning(get_parent(), spot, 1.6, Mob.TELEGRAPH)
	var claw: Node3D = _model.get_node("ClawR")
	var up := create_tween()
	up.tween_property(claw, "rotation_degrees:x", -60.0, Mob.TELEGRAPH)
	await up.finished
	var down := create_tween()
	down.tween_property(claw, "rotation_degrees:x", 35.0, 0.12)
	await down.finished
	Effects.ring(get_parent(), spot + Vector3.UP * 0.2, 2.2, Tokens.color("sky"), 0.3)
	if Vector2(p.global_position.x - spot.x, p.global_position.z - spot.z).length() < 1.7:
		p.hurt(CrabPlan.CLAW_DAMAGE, spot)
	await _opening(CrabPlan.STUCK_TIME, "Kıskacı saplandı! Şimdi vur!")
	var back := create_tween()
	back.tween_property(claw, "rotation_degrees:x", 0.0, 0.3)


func _spin() -> void:
	var shell: Node3D = _model.get_node("Shell")
	for c in ["ClawL", "ClawR"]:
		(_model.get_node(c) as Node3D).scale = Vector3.ONE * 0.5
	for dash in CrabPlan.SPIN_DASHES:
		if not active:
			return
		var p := _player()
		var dir := p.global_position - global_position
		dir.y = 0.0
		dir = dir.normalized()
		var end := global_position + dir * 9.0
		var to := end - arena_center
		to.y = 0.0
		if to.length() > arena_radius:
			end = arena_center + to.normalized() * arena_radius
		for k in 4:
			Effects.warning(get_parent(), global_position.lerp(end, (k + 1) / 4.0), 1.0, Mob.TELEGRAPH)
		var spin := create_tween()
		spin.tween_property(_model, "rotation:y", _model.rotation.y + TAU, Mob.TELEGRAPH)
		await spin.finished
		var start := global_position
		var t := 0.0
		var hit := false
		while t < 0.6:
			t += get_process_delta_time()
			global_position = start.lerp(end, minf(t / 0.6, 1.0))
			_model.rotation.y += get_process_delta_time() * 18.0
			if not hit and p.global_position.distance_to(global_position) < 2.2:
				hit = p.hurt(CrabPlan.SPIN_DAMAGE, global_position)
			await get_tree().process_frame
	for c in ["ClawL", "ClawR"]:
		(_model.get_node(c) as Node3D).scale = Vector3.ONE
	await _opening(CrabPlan.DIZZY_TIME, "Başı döndü! Şimdi vur!")


func _opening(seconds: float, hint: String) -> void:
	open = true
	add_to_group("hittable")
	_stars = Node3D.new()
	_stars.position.y = 3.6
	add_child(_stars)
	for i in 4:
		var a := TAU * i / 4.0
		Toon.part(_stars, "sphere", Vector3(0.35, 0.35, 0.35), "spark-yellow", Vector3(cos(a), 0, sin(a)) * 1.0, Vector3.ZERO, 1.2, 0.02)
	get_tree().call_group("hud", "show_hint", hint, hint)
	await get_tree().create_timer(seconds).timeout
	if _stars:
		_stars.queue_free()
		_stars = null
	if not active:
		return
	open = false
	remove_from_group("hittable")
	get_tree().call_group("hud", "clear_hint")


func hit(damage: int, _from: Vector3, _push: float) -> void:
	if not open or not active:
		return
	hp = maxi(hp - damage, 0)
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 3.8, str(damage), Tokens.color("panel@light"))
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(1.08, 0.92, 1.08), 0.06)
	tw.tween_property(_model, "scale", Vector3.ONE, 0.12)
	hp_changed.emit(hp, CrabPlan.MAX_HP)
	phase = CrabPlan.phase(hp)
	if hp == 0:
		_befriend()


## Beaten: he realizes you're a keeper, not the Pus. Friends now.
func _befriend() -> void:
	active = false
	open = false
	remove_from_group("hittable")
	if _stars:
		_stars.queue_free()
		_stars = null
	get_tree().call_group("hud", "clear_hint")
	for m in get_tree().get_nodes_in_group("mob"):
		if m.has_method("hit"):
			m.hit(9999, global_position, 0.0)
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 3, Tokens.color("spark-blue"), 24)
	var tw := create_tween()
	tw.tween_property(_model, "rotation:y", 0.0, 0.5)
	defeated.emit()
