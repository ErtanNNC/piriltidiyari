class_name Firfir
extends Node3D
## Tilki Fırfır: an orange fox with a big white-tipped tail. Leaf whirls drop
## on warned circles; he dashes along a warned line; then sits down panting
## (hittable). At 0 HP he is sad in group "dazed" (Sakinleş → `calmed`).

signal hp_changed(hp: int, max_hp: int)
signal phase_changed(phase: int)
signal sad
signal calmed

var hp := FirfirPlan.MAX_HP
var phase := 1
var active := false
var tired := false
var is_sad := false
var home := Vector3.ZERO
var _model: Node3D
var _cross: Node3D
var _soft: Node3D
var _t := 0.0
var _busy := false
var _tail: Node3D
## Reused by other bosses with the same moves (Tavuk Patpat): their own
## model, attack color, hint line and calm event.
var attack_color := Color("#e8833a")
var tired_hint := "Fırfır oturdu, soluk soluğa! Şimdi vur!"
var calm_event := "firfir"


func _ready() -> void:
	_model = _make_model()
	add_child(_model)
	_cross = _model.find_child("CrossFace", true, false)
	_soft = _model.find_child("SoftFace", true, false)
	_tail = _model.find_child("Tail", true, false)
	set_meta("hit_radius", 1.3)
	set_meta("calm_reach", 3.2)
	home = position


func _make_model() -> Node3D:
	return build_model()


static func build_model() -> Node3D:
	var real := ModelImport.boss("firfir", ["CrossFace", "SoftFace", "Tail"])
	if real:
		return real
	var root := Node3D.new()
	Toon.default_pus = 0.0
	var fur := Color("#e8722e")
	var cream := Color("#fff1dc")
	var dark := Color("#5a3428")
	var body := Toon.part(root, "ellipsoid", Vector3(1.3, 1.25, 1.5), fur, Vector3(0, 0.9, 0), Vector3.ZERO, 0.0, 0.035)
	body.name = "Body"
	Toon.part(root, "ellipsoid", Vector3(0.8, 0.9, 0.5), cream, Vector3(0, 0.85, 0.55), Vector3.ZERO, 0.0, 0.0)
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.95, 0.2)
	root.add_child(head)
	Toon.part(head, "ellipsoid", Vector3(1.2, 1.0, 1.0), fur, Vector3.ZERO, Vector3.ZERO, 0.0, 0.035)
	Toon.part(head, "ellipsoid", Vector3(0.75, 0.5, 0.6), cream, Vector3(0, -0.2, 0.42))
	Toon.part(head, "sphere", Vector3(0.16, 0.13, 0.12), "outline", Vector3(0, -0.12, 0.74), Vector3.ZERO, 0.0, 0.0)
	for side: float in [-1.0, 1.0]:
		Toon.part(head, "cone", Vector3(0.4, 0.6, 0.22), fur, Vector3(0.36 * side, 0.65, -0.05), Vector3(0, 0, -16 * side))
		Toon.part(head, "cone", Vector3(0.2, 0.25, 0.1), dark, Vector3(0.43 * side, 0.9, -0.05), Vector3(0, 0, -16 * side), 0.0, 0.0)
		var foot := Toon.part(root, "ellipsoid", Vector3(0.36, 0.22, 0.46), dark, Vector3(0.3 * side, 0.1, 0.25))
		foot.name = "FootL" if side < 0 else "FootR"
		var hand := Toon.part(root, "ellipsoid", Vector3(0.28, 0.4, 0.28), fur, Vector3(0.62 * side, 0.85, 0.35), Vector3(0, 0, 20 * side))
		hand.name = "HandL" if side < 0 else "HandR"
	# the big fluffy tail
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.7, -0.7)
	root.add_child(tail)
	for i in 4:
		Toon.part(tail, "ellipsoid", Vector3(0.7, 0.7, 0.8) * (1.0 - i * 0.12), fur if i < 3 else cream, Vector3(0, 0.25 * i, -0.4 * i), Vector3.ZERO, 0.0, 0.03)
	var cross := Node3D.new()
	cross.name = "CrossFace"
	head.add_child(cross)
	var soft := Node3D.new()
	soft.name = "SoftFace"
	soft.visible = false
	head.add_child(soft)
	for side: float in [-1.0, 1.0]:
		for f: Node3D in [cross, soft]:
			Toon.part(f, "ellipsoid", Vector3(0.18, 0.24, 0.08), "outline", Vector3(0.27 * side, 0.12, 0.46), Vector3.ZERO, 0.0, 0.0)
			Toon.part(f, "ellipsoid", Vector3(0.07, 0.07, 0.03), Color.WHITE, Vector3(0.29 * side, 0.18, 0.5), Vector3.ZERO, 0.8, 0.0)
		Toon.part(cross, "box", Vector3(0.3, 0.07, 0.06), "outline", Vector3(0.27 * side, 0.32, 0.47), Vector3(0, 0, -22 * side), 0.0, 0.0)
		Toon.part(soft, "box", Vector3(0.28, 0.06, 0.06), "outline", Vector3(0.27 * side, 0.34, 0.47), Vector3(0, 0, 16 * side), 0.0, 0.0)
		Toon.part(soft, "ellipsoid", Vector3(0.1, 0.16, 0.05), "sky", Vector3(0.32 * side, -0.05, 0.5), Vector3.ZERO, 0.6, 0.0)
	Toon.default_pus = 1.0
	CharacterRig.attach(root)
	return root


func _process(delta: float) -> void:
	_t += delta
	if _tail:
		_tail.rotation.y = sin(_t * (6.0 if active and not tired else 2.0)) * 0.35
	if active and not _busy and not tired:
		var p := _player()
		if p:
			var to := p.global_position - global_position
			to.y = 0.0
			_model.rotation.y = lerp_angle(_model.rotation.y, atan2(to.x, to.z), 1.0 - exp(-6.0 * delta))
			# keep a little distance, circling the glade
			var want := home + Vector3(sin(_t * 0.5) * 3.0, 0, cos(_t * 0.4) * 2.0)
			position = position.lerp(want, 1.0 - exp(-1.2 * delta))


func start() -> void:
	active = true
	_loop()


func _loop() -> void:
	while active:
		for attack in FirfirPlan.cycle(phase):
			if not active:
				return
			await get_tree().create_timer(FirfirPlan.rest(phase), false).timeout
			if not active:
				return
			await GameState.wait_dialogue_closed()
			if not active:
				return
			match attack:
				"leaves":
					await _leaves()
				"dash":
					await _dash()
				_:
					await _rest()


func _player() -> Player:
	return get_tree().get_first_node_in_group("player")


## Leaf whirls: warned circles around the keeper, then spinning leaves.
func _leaves() -> void:
	_busy = true
	var p := _player()
	var spots: Array[Vector3] = []
	for i in FirfirPlan.whirls(phase):
		var off := Vector3.ZERO if i == 0 else Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
		spots.append(Vector3(p.global_position.x, global_position.y, p.global_position.z) + off)
	for s in spots:
		Effects.warning(get_parent(), s, FirfirPlan.LEAF_RADIUS, Mob.TELEGRAPH)
	var spin := create_tween()
	spin.tween_property(_model, "rotation:y", _model.rotation.y + TAU, Mob.TELEGRAPH)
	await spin.finished
	for s in spots:
		Effects.ring(get_parent(), s + Vector3.UP * 0.3, FirfirPlan.LEAF_RADIUS, attack_color, 0.4)
		for k in 4:
			Effects.sparkle(get_parent(), s + Vector3(randf_range(-1, 1), 0.6, randf_range(-1, 1)), attack_color, 2)
	for s in spots:
		if Vector2(p.global_position.x - s.x, p.global_position.z - s.z).length() < FirfirPlan.LEAF_RADIUS:
			p.hurt(FirfirPlan.LEAF_DAMAGE, s)
			break
	_busy = false


## A dash across the glade along a warned line.
func _dash() -> void:
	_busy = true
	var p := _player()
	var from := global_position   # warnings on the boss's own floor (raised arenas)
	var dir := Vector3(p.global_position.x, from.y, p.global_position.z) - from
	dir = dir.normalized() if dir.length() > 0.1 else Vector3.BACK
	var length := 9.0
	for k in 5:
		Effects.warning(get_parent(), from + dir * (1.5 + k * 1.8), 0.8, Mob.TELEGRAPH)
	_model.rotation.y = atan2(dir.x, dir.z)
	await get_tree().create_timer(Mob.TELEGRAPH, false).timeout
	var to := from + dir * length
	to.x = clampf(to.x, home.x - 8.0, home.x + 8.0)
	to.z = clampf(to.z, home.z - 8.0, home.z + 8.0)
	var hit := false
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void:
		global_position = from.lerp(to, k)
		if not hit and p.global_position.distance_to(global_position) < 1.3:
			hit = p.hurt(FirfirPlan.DASH_DAMAGE, global_position), 0.0, 1.0, 0.45)
	await tw.finished
	Effects.ring(get_parent(), global_position + Vector3.UP * 0.2, 1.6, attack_color, 0.3)
	_busy = false


## Out of breath: he sits down (the moment to hit).
func _rest() -> void:
	_busy = true
	tired = true
	add_to_group("hittable")
	var sit := create_tween()
	sit.tween_property(_model, "scale", Vector3(1.1, 0.85, 1.1), 0.25)
	get_tree().call_group("hud", "show_hint", tired_hint, "Oturdu! Şimdi vur!")
	await get_tree().create_timer(FirfirPlan.TIRED_TIME, false).timeout
	if not active:
		return
	get_tree().call_group("hud", "clear_hint")
	tired = false
	remove_from_group("hittable")
	var up := create_tween()
	up.tween_property(_model, "scale", Vector3.ONE, 0.2)
	_busy = false


func hit(damage: int, _from: Vector3, _push: float) -> void:
	damage = Progression.boss_damage(damage, GameState.data.power)
	Effects.hit(self, true)
	if not tired or not active:
		return
	hp = maxi(hp - damage, 0)
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 3.2, str(damage), Tokens.color("panel@light"))
	hp_changed.emit(hp, FirfirPlan.MAX_HP)
	var p := FirfirPlan.phase(hp)
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
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 2.0, attack_color, 18)
	GameState.notify("breathe", calm_event)
	calmed.emit()
