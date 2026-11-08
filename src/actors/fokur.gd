class_name Fokur
extends Node3D
## Kaynar Kurbağa Fokur: a big boiling-red frog on the lake's island. Bubbles
## fall on warned circles, a croak rings out around him (warned ring: step
## away), and a big hop lands on a warned spot; then he sits puffing
## (hittable). At 0 HP he is sad in group "dazed" (Sakinleş → `calmed`).

signal hp_changed(hp: int, max_hp: int)
signal phase_changed(phase: int)
signal sad
signal calmed

var hp := FokurPlan.MAX_HP
var phase := 1
var active := false
var tired := false
var is_sad := false
var home := Vector3.ZERO
var _model: Node3D
var _cross: Node3D
var _soft: Node3D
var _throat: Node3D
var _t := 0.0
var _busy := false


func _ready() -> void:
	_model = build_model()
	add_child(_model)
	_cross = _model.find_child("CrossFace", true, false)
	_soft = _model.find_child("SoftFace", true, false)
	_throat = _model.find_child("Throat", true, false)
	set_meta("hit_radius", 1.6)
	set_meta("calm_reach", 3.4)
	home = position


static func build_model() -> Node3D:
	var root := Node3D.new()
	Toon.default_pus = 0.0
	var skin := Color("#e8604a")
	var belly := Color("#ffd8b8")
	var body := Toon.part(root, "ellipsoid", Vector3(2.2, 1.6, 2.0), skin, Vector3(0, 0.85, 0), Vector3.ZERO, 0.0, 0.035)
	body.name = "Body"
	Toon.part(root, "ellipsoid", Vector3(1.4, 1.1, 0.6), belly, Vector3(0, 0.75, 0.75), Vector3.ZERO, 0.0, 0.0)
	var throat := Toon.part(root, "ellipsoid", Vector3(0.9, 0.55, 0.5), Color("#ffb0a0"), Vector3(0, 1.05, 0.95), Vector3.ZERO, 0.0, 0.0)
	throat.name = "Throat"
	for side: float in [-1.0, 1.0]:
		var bump := Toon.part(root, "sphere", Vector3(0.7, 0.7, 0.65), skin, Vector3(0.55 * side, 1.75, 0.35), Vector3.ZERO, 0.0, 0.035)
		bump.name = "Eye" + ("L" if side < 0 else "R")
		var foot := Toon.part(root, "ellipsoid", Vector3(0.6, 0.2, 0.7), skin.darkened(0.15), Vector3(0.85 * side, 0.1, 0.4))
		foot.name = "FootL" if side < 0 else "FootR"
		var hand := Toon.part(root, "ellipsoid", Vector3(0.35, 0.45, 0.35), skin, Vector3(0.95 * side, 0.6, 0.6), Vector3(0, 0, 25 * side))
		hand.name = "HandL" if side < 0 else "HandR"
	var cross := Node3D.new()
	cross.name = "CrossFace"
	root.add_child(cross)
	var soft := Node3D.new()
	soft.name = "SoftFace"
	soft.visible = false
	root.add_child(soft)
	for side: float in [-1.0, 1.0]:
		for f: Node3D in [cross, soft]:
			Toon.part(f, "ellipsoid", Vector3(0.24, 0.3, 0.1), "outline", Vector3(0.55 * side, 1.78, 0.68), Vector3.ZERO, 0.0, 0.0)
			Toon.part(f, "ellipsoid", Vector3(0.08, 0.09, 0.04), Color.WHITE, Vector3(0.58 * side, 1.86, 0.73), Vector3.ZERO, 0.8, 0.0)
		Toon.part(cross, "box", Vector3(0.42, 0.08, 0.08), "outline", Vector3(0.55 * side, 2.05, 0.6), Vector3(0, 0, -20 * side), 0.0, 0.0)
		Toon.part(soft, "box", Vector3(0.4, 0.07, 0.08), "outline", Vector3(0.55 * side, 2.08, 0.6), Vector3(0, 0, 15 * side), 0.0, 0.0)
		Toon.part(soft, "ellipsoid", Vector3(0.12, 0.18, 0.05), "sky", Vector3(0.62 * side, 1.55, 0.75), Vector3.ZERO, 0.6, 0.0)
	Toon.part(cross, "box", Vector3(0.9, 0.08, 0.08), "outline", Vector3(0, 1.32, 1.0), Vector3(0, 0, 0), 0.0, 0.0)
	Toon.part(soft, "ellipsoid", Vector3(0.5, 0.18, 0.08), "outline", Vector3(0, 1.32, 1.0), Vector3.ZERO, 0.0, 0.0)
	MobModels._pus_wisps(root, 2.2, Color(1, 1, 1), 8, 0.8)
	Toon.default_pus = 1.0
	return root


func _process(delta: float) -> void:
	_t += delta
	if _throat:
		var puff := 1.0 + absf(sin(_t * (5.0 if active else 1.5))) * 0.35
		_throat.scale = Vector3(puff, puff, puff)
	if active and not _busy and not tired:
		var p := _player()
		if p:
			var to := p.global_position - global_position
			to.y = 0.0
			_model.rotation.y = lerp_angle(_model.rotation.y, atan2(to.x, to.z), 1.0 - exp(-5.0 * delta))


func start() -> void:
	active = true
	_loop()


func _loop() -> void:
	while active:
		for attack in FokurPlan.cycle(phase):
			if not active:
				return
			await get_tree().create_timer(FokurPlan.rest(phase)).timeout
			if not active:
				return
			await GameState.wait_dialogue_closed()
			if not active:
				return
			match attack:
				"bubbles":
					await _bubbles()
				"croak":
					await _croak()
				_:
					await _hop()


func _player() -> Player:
	return get_tree().get_first_node_in_group("player")


## Boiling bubbles land on warned circles round the keeper.
func _bubbles() -> void:
	_busy = true
	var p := _player()
	var spots: Array[Vector3] = []
	for i in FokurPlan.bubbles(phase):
		var off := Vector3.ZERO if i == 0 else Vector3(randf_range(-3.5, 3.5), 0, randf_range(-3.5, 3.5))
		spots.append(Vector3(p.global_position.x, home.y, p.global_position.z) + off)
	for s in spots:
		Effects.warning(get_parent(), s, FokurPlan.BUBBLE_RADIUS, Mob.TELEGRAPH)
	await get_tree().create_timer(Mob.TELEGRAPH).timeout
	for s in spots:
		Effects.ring(get_parent(), s + Vector3.UP * 0.2, FokurPlan.BUBBLE_RADIUS, Color("#ffb0a0"), 0.35)
		Effects.sparkle(get_parent(), s + Vector3.UP * 0.6, Color(1, 1, 1), 6)
	for s in spots:
		if Vector2(p.global_position.x - s.x, p.global_position.z - s.z).length() < FokurPlan.BUBBLE_RADIUS:
			p.hurt(FokurPlan.BUBBLE_DAMAGE, s)
			break
	Audio.play("splash")
	_busy = false


## A big croak: the ground ring around him (warned), step back out of it.
func _croak() -> void:
	_busy = true
	var p := _player()
	var at := Vector3(global_position.x, home.y, global_position.z)
	Effects.warning(get_parent(), at, FokurPlan.CROAK_RADIUS, Mob.TELEGRAPH)
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(1.12, 1.18, 1.12), Mob.TELEGRAPH).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_model.scale = Vector3.ONE
	for i in 3:
		Effects.ring(get_parent(), at + Vector3.UP * 0.4, FokurPlan.CROAK_RADIUS * (0.6 + i * 0.25), Color(1, 1, 1, 0.9), 0.3 + i * 0.1)
	Effects.shake(get_viewport(), 0.4)
	if Vector2(p.global_position.x - at.x, p.global_position.z - at.z).length() < FokurPlan.CROAK_RADIUS:
		var away := p.global_position - at
		away.y = 0.0
		p.push(away.normalized() * 10.0)
		p.hurt(FokurPlan.CROAK_DAMAGE, at)
	Audio.play("wind")
	_busy = false


## A big hop onto the keeper's spot (warned), then he sits puffing.
func _hop() -> void:
	_busy = true
	var p := _player()
	var spot := Vector3(p.global_position.x, home.y, p.global_position.z)
	spot.x = clampf(spot.x, home.x - 7.0, home.x + 7.0)
	spot.z = clampf(spot.z, home.z - 7.0, home.z + 7.0)
	var up := create_tween()
	up.tween_property(self, "global_position", Vector3(global_position.x, home.y + 6.0, global_position.z), 0.4).set_trans(Tween.TRANS_SINE)
	await up.finished
	Effects.warning(get_parent(), spot, FokurPlan.HOP_RADIUS, Mob.TELEGRAPH)
	await get_tree().create_timer(Mob.TELEGRAPH).timeout
	var down := create_tween()
	down.tween_property(self, "global_position", spot, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await down.finished
	Effects.ring(get_parent(), spot + Vector3.UP * 0.2, FokurPlan.HOP_RADIUS + 0.8, Color("#ffb0a0"), 0.4)
	Effects.shake(get_viewport(), 0.5)
	if p.global_position.distance_to(spot) < FokurPlan.HOP_RADIUS:
		p.hurt(FokurPlan.HOP_DAMAGE, spot)
	await _rest()
	_busy = false


func _rest() -> void:
	tired = true
	add_to_group("hittable")
	var sit := create_tween()
	sit.tween_property(_model, "scale", Vector3(1.1, 0.85, 1.1), 0.25)
	get_tree().call_group("hud", "show_hint", "Fokur yoruldu, soluk soluğa! Şimdi vur!", "Yoruldu! Şimdi vur!")
	await get_tree().create_timer(FokurPlan.TIRED_TIME).timeout
	if not active:
		return
	get_tree().call_group("hud", "clear_hint")
	tired = false
	remove_from_group("hittable")
	var back := create_tween()
	back.tween_property(_model, "scale", Vector3.ONE, 0.2)


func hit(damage: int, _from: Vector3, _push: float) -> void:
	damage = Progression.boss_damage(damage, GameState.data.power)
	Effects.hit(self, true)
	if not tired or not active:
		return
	hp = maxi(hp - damage, 0)
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 3.0, str(damage), Tokens.color("panel@light"))
	hp_changed.emit(hp, FokurPlan.MAX_HP)
	var p := FokurPlan.phase(hp)
	if hp == 0:
		_become_sad()
	elif p != phase:
		phase = p
		phase_changed.emit(phase)


func _become_sad() -> void:
	active = false
	tired = false
	is_sad = true
	remove_from_group("hittable")
	get_tree().call_group("hud", "clear_hint")
	_cross.visible = false
	_soft.visible = true
	_model.scale = Vector3(1.05, 0.9, 1.05)
	add_to_group("dazed")
	sad.emit()


func breathe_calm() -> void:
	if not is_sad:
		return
	is_sad = false
	remove_from_group("dazed")
	_model.scale = Vector3.ONE
	GameState.notify("breathe", "fokur")
	calmed.emit()


## His song, sung to the end: little notes float up from him.
func sing() -> void:
	for i in 12:
		var note := Toon.part(get_parent(), "sphere", Vector3(0.25, 0.25, 0.25), ["berry", "sky", "spark-yellow", "leaf"][i % 4],
			global_position + Vector3(randf_range(-1, 1), 2.4, randf_range(-0.5, 0.5)), Vector3.ZERO, 1.6, 0.02)
		var tw := note.create_tween()
		tw.tween_interval(i * 0.25)
		tw.tween_property(note, "global_position", note.global_position + Vector3(randf_range(-2, 2), 3.0, 0), 1.6).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(note, "scale", Vector3.ZERO, 1.6)
		tw.tween_callback(note.queue_free)
