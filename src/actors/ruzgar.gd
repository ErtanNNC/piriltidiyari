class_name Ruzgar
extends Node3D
## Fırtına Martısı Rüzgâr, Bölüm 3 boss: a big storm gull. See GullPlan.

signal hp_changed(hp: int, max_hp: int)
signal defeated

var hp := GullPlan.MAX_HP
var phase := 1
var active := false
var dazed := false
var center := Vector3.ZERO
var orbit := 9.0
var height := 5.0
var _model: Node3D
var _angle := 0.0
var _busy := false
var _stars: Node3D
var _player: Player


func _ready() -> void:
	set_meta("hit_radius", 1.6)
	_model = build_model()
	add_child(_model)


static func build_model() -> Node3D:
	var real := ModelImport.with_parts("ruzgar", {"WingL": Vector3(-0.95, 1.8, -0.1), "WingR": Vector3(0.95, 1.8, -0.1)})
	if real:
		return real
	var root := Node3D.new()
	var white := Color("#f4f7ff")
	var storm := Color("#7d8fb0")
	Toon.part(root, "sphere", Vector3(2.0, 1.9, 2.4), white, Vector3(0, 1.4, 0))
	Toon.part(root, "sphere", Vector3(1.5, 1.4, 1.4), white, Vector3(0, 2.6, 0.5))
	Toon.part(root, "cone", Vector3(0.5, 0.9, 0.5), "honey", Vector3(0, 2.45, 1.4), Vector3(90, 0, 0))
	# storm crest: lightning feathers
	for i in 3:
		Toon.part(root, "cone", Vector3(0.35, 1.0, 0.2), "spark-yellow", Vector3((i - 1) * 0.3, 3.4, 0.3 - i * 0.2), Vector3(-20, 0, (i - 1) * -20), 0.8, 0.02)
	for side in [-1.0, 1.0]:
		Toon.part(root, "sphere", Vector3(0.36, 0.42, 0.16), "outline", Vector3(0.36 * side, 2.75, 1.12), Vector3.ZERO, 0.0, 0.0)
		Toon.part(root, "box", Vector3(0.5, 0.1, 0.1), "outline", Vector3(0.36 * side, 3.05, 1.1), Vector3(0, 0, 18 * side), 0.0, 0.0)
		var wing := Node3D.new()
		wing.name = "WingL" if side < 0 else "WingR"
		wing.position = Vector3(0.95 * side, 1.8, -0.1)
		root.add_child(wing)
		Toon.part(wing, "sphere", Vector3(2.4, 0.35, 1.3), storm, Vector3(1.1 * side, 0, 0), Vector3(0, 0, -15 * side))
		Toon.part(root, "sphere", Vector3(0.36, 0.2, 0.5), "honey-deep", Vector3(0.36 * side, 0.12, 0.3))
	return root


func _process(delta: float) -> void:
	var flap := sin(Time.get_ticks_msec() / (110.0 if not dazed else 450.0)) * (0.55 if not dazed else 0.08)
	_model.get_node("WingL").rotation.z = flap
	_model.get_node("WingR").rotation.z = -flap
	if _stars:
		_stars.rotation.y += delta * 4.0
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
	if active and not _busy and not dazed:
		_angle += delta * (0.3 + 0.08 * phase)
		var target := center + Vector3(sin(_angle) * orbit, height, cos(_angle) * orbit)
		global_position = global_position.lerp(target, 1.0 - exp(-2.0 * delta))
	if _player and not dazed:
		var to := _player.global_position - global_position
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(to.x, to.z), 1.0 - exp(-6.0 * delta))


func start() -> void:
	active = true
	_loop()


func _loop() -> void:
	while active:
		for attack in GullPlan.cycle(phase):
			if not active:
				return
			await get_tree().create_timer(GullPlan.rest(phase), false).timeout
			await GameState.wait_dialogue_closed()
			if not active:
				return
			_busy = true
			match attack:
				"gale": await _gale()
				"lightning": await _lightning()
				"dive": await _dive()
			_busy = false


## A wall of wind across the arena: hide by a pillar (group "shelter").
func _gale() -> void:
	var dir := (_player.global_position - center)
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.5 else Vector3.RIGHT
	get_tree().call_group("hud", "show_hint", "Rüzgâr esiyor! Bir sütunun dibine saklan", "Sütunun dibine saklan!")
	for k in 8:
		var at := center + Vector3(randf_range(-7, 7), 0.1, randf_range(-7, 7))
		Effects.warning(get_parent(), at, 0.6, Mob.TELEGRAPH)
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3.ONE * 1.2, Mob.TELEGRAPH)
	await tw.finished
	_model.scale = Vector3.ONE
	var t := 0.0
	while t < GullPlan.GALE_TIME and active:
		if get_tree().paused:
			await get_tree().process_frame
			continue
		var safe := false
		for s in get_tree().get_nodes_in_group("shelter"):
			var n := s as Node3D
			if Vector2(_player.global_position.x - n.global_position.x, _player.global_position.z - n.global_position.z).length() < n.get_meta("shelter_radius", 2.4):
				safe = true
		_player.wind = Vector3.ZERO if safe else dir * GullPlan.GALE_STRENGTH
		await get_tree().process_frame
		t += get_process_delta_time()
	_player.wind = Vector3.ZERO
	get_tree().call_group("hud", "clear_hint")


func _lightning() -> void:
	var spots: Array[Vector3] = [Vector3(_player.global_position.x, _player.global_position.y, _player.global_position.z)]
	for i in GullPlan.bolts(phase) - 1:
		spots.append(spots[0] + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)))
	for s in spots:
		Effects.warning(get_parent(), s, 1.1, Mob.TELEGRAPH)
	await get_tree().create_timer(Mob.TELEGRAPH, false).timeout
	for s in spots:
		var bolt := Toon.part(get_parent(), "cylinder", Vector3(0.35, 12.0, 0.35), "spark-yellow", s + Vector3.UP * 6.0, Vector3.ZERO, 2.0, 0.03)
		var tw := bolt.create_tween()
		tw.tween_property(bolt, "scale", Vector3(0.1, 1, 0.1), 0.25)
		tw.tween_callback(bolt.queue_free)
		Effects.ring(get_parent(), s + Vector3.UP * 0.2, 1.6, Tokens.color("spark-yellow"), 0.3)
		if _player.global_position.distance_to(s) < 1.3:
			_player.hurt(GullPlan.BOLT_DAMAGE, s)


func _dive() -> void:
	var spot := _player.global_position
	var up := create_tween()
	up.tween_property(self, "global_position", spot + Vector3.UP * 8.0, 0.6).set_trans(Tween.TRANS_SINE)
	await up.finished
	spot = _player.global_position
	Effects.warning(get_parent(), spot, 2.0, Mob.TELEGRAPH)
	await get_tree().create_timer(Mob.TELEGRAPH, false).timeout
	var down := create_tween()
	down.tween_property(self, "global_position", spot, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await down.finished
	Effects.ring(get_parent(), spot + Vector3.UP * 0.2, 3.0, Color(1, 1, 1, 0.9), 0.4)
	if _player.global_position.distance_to(spot) < 2.0:
		_player.hurt(GullPlan.DIVE_DAMAGE, spot)
	dazed = true
	add_to_group("hittable")
	_stars = Node3D.new()
	_stars.position.y = 4.0
	add_child(_stars)
	for i in 4:
		var a := TAU * i / 4.0
		Toon.part(_stars, "sphere", Vector3(0.35, 0.35, 0.35), "spark-yellow", Vector3(cos(a), 0, sin(a)), Vector3.ZERO, 1.2, 0.02)
	get_tree().call_group("hud", "show_hint", "Sersemledi! Şimdi vur!", "Sersemledi! Şimdi vur!")
	await get_tree().create_timer(GullPlan.DAZE_TIME, false).timeout
	if _stars:
		_stars.queue_free()
		_stars = null
	if not active:
		return
	get_tree().call_group("hud", "clear_hint")
	dazed = false
	remove_from_group("hittable")


func hit(damage: int, _from: Vector3, _push: float) -> void:
	damage = Progression.boss_damage(damage, GameState.data.power)
	Effects.hit(self, true)
	if not dazed or not active:
		return
	hp = maxi(hp - damage, 0)
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 4.0, str(damage), Tokens.color("panel@light"))
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(1.12, 0.88, 1.12), 0.06)
	tw.tween_property(_model, "scale", Vector3.ONE, 0.12)
	hp_changed.emit(hp, GullPlan.MAX_HP)
	phase = GullPlan.phase(hp)
	if hp == 0:
		_calm()


func _calm() -> void:
	active = false
	dazed = false
	remove_from_group("hittable")
	if _stars:
		_stars.queue_free()
		_stars = null
	if _player:
		_player.wind = Vector3.ZERO
	get_tree().call_group("hud", "clear_hint")
	for m in get_tree().get_nodes_in_group("mob"):
		if m.has_method("hit"):
			m.hit(9999, global_position, 0.0)
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 3, Tokens.color("spark-yellow"), 24)
	defeated.emit()
