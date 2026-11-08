class_name Kettle
extends Node3D
## Homurdanan Çaydanlık: the big copper kettle in the village square. Steam
## jets and boiling splashes, each warned 0.8 s ahead; when the lid pops up
## it can be hit. At 0 HP it simmers in group "dazed" (wide `calm_reach`),
## so Sakinleş cools it down (`breathe_calm` → `calmed`).

signal hp_changed(hp: int, max_hp: int)
signal phase_changed(phase: int)
signal simmering
signal calmed

var hp := KettlePlan.MAX_HP
var phase := 1
var active := false
var lid_up := false
var is_simmering := false
var _model: Node3D
var _lid: Node3D
var _face_cross: Node3D
var _face_calm: Node3D
var _t := 0.0


func _ready() -> void:
	_model = build_model()
	add_child(_model)
	_lid = _model.get_node("Lid")
	_face_cross = _model.get_node("CrossFace")
	_face_calm = _model.get_node("CalmFace")
	set_meta("hit_radius", 1.8)
	set_meta("calm_reach", 3.4)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.4
	cyl.height = 2.4
	c.shape = cyl
	c.position.y = 1.2
	body.add_child(c)
	add_child(body)
	MobModels._pus_wisps(_model, 2.9, Color(1, 1, 1), 10, 1.2)


static func build_model() -> Node3D:
	var root := Node3D.new()
	Toon.default_pus = 0.0
	var copper := Color("#d9784a")
	var copper_dark := Color("#a9553a")
	Toon.part(root, "ellipsoid", Vector3(2.8, 2.2, 2.8), copper, Vector3(0, 1.2, 0), Vector3.ZERO, 0.0, 0.035)
	Toon.part(root, "cylinder", Vector3(2.0, 0.3, 2.0), copper_dark, Vector3(0, 0.12, 0))
	# spout and handle
	Toon.part(root, "cone", Vector3(0.5, 1.4, 0.5), copper_dark, Vector3(1.6, 1.6, 0.0), Vector3(0, 0, -55))
	Toon.part(root, "ring", Vector3(1.6, 0.14, 1.6), Color("#6e5040"), Vector3(0, 2.35, 0), Vector3(90, 0, 0))
	var lid := Node3D.new()
	lid.name = "Lid"
	lid.position = Vector3(0, 2.25, 0)
	root.add_child(lid)
	Toon.part(lid, "cylinder", Vector3(1.6, 0.2, 1.6), copper_dark, Vector3.ZERO, Vector3.ZERO, 0.0, 0.03)
	Toon.part(lid, "sphere", Vector3(0.35, 0.3, 0.35), "honey", Vector3(0, 0.22, 0), Vector3.ZERO, 0.6, 0.02)
	var cross := Node3D.new()
	cross.name = "CrossFace"
	root.add_child(cross)
	var calm := Node3D.new()
	calm.name = "CalmFace"
	calm.visible = false
	root.add_child(calm)
	for side: float in [-1.0, 1.0]:
		for f: Node3D in [cross, calm]:
			Toon.part(f, "ellipsoid", Vector3(0.26, 0.34, 0.1), "outline", Vector3(0.42 * side, 1.45, 1.32), Vector3.ZERO, 0.0, 0.0)
			Toon.part(f, "ellipsoid", Vector3(0.09, 0.1, 0.04), Color.WHITE, Vector3(0.45 * side, 1.54, 1.38), Vector3.ZERO, 0.8, 0.0)
		Toon.part(cross, "box", Vector3(0.42, 0.1, 0.08), "outline", Vector3(0.42 * side, 1.72, 1.32), Vector3(0, 0, -24 * side), 0.0, 0.0)
		Toon.part(cross, "box", Vector3(0.3, 0.08, 0.06), "outline", Vector3(0.12 * side, 1.02, 1.38), Vector3(0, 0, 20 * side), 0.0, 0.0)
		Toon.part(calm, "box", Vector3(0.28, 0.07, 0.06), "outline", Vector3(0.11 * side, 1.02, 1.38), Vector3(0, 0, -18 * side), 0.0, 0.0)
		var blush := Toon.part(calm, "ellipsoid", Vector3(0.2, 0.1, 0.04), "berry", Vector3(0.7 * side, 1.2, 1.2), Vector3.ZERO, 0.0, 0.0)
		blush.transparency = 0.3
	Toon.default_pus = 1.0
	return root


func _process(delta: float) -> void:
	_t += delta
	if active and not lid_up:
		# the lid rattles while it boils
		_lid.position.y = 2.25 + absf(sin(_t * 14.0)) * 0.06
	_model.scale = Vector3(1.0 + sin(_t * 3.0) * 0.015, 1.0 - sin(_t * 3.0) * 0.015, 1.0)


func start() -> void:
	active = true
	_loop()


func _loop() -> void:
	while active:
		for attack in KettlePlan.cycle(phase):
			if not active:
				return
			await get_tree().create_timer(KettlePlan.rest(phase)).timeout
			if not active:
				return
			await GameState.wait_dialogue_closed()
			if not active:
				return
			match attack:
				"jets":
					await _jets()
				"splash":
					await _splash()
				_:
					await _pop_lid()


func _player() -> Player:
	return get_tree().get_first_node_in_group("player")


## Steam jets straight out along 4 (or 8) directions, warned as dots.
func _jets() -> void:
	var dirs: Array[Vector3] = []
	var n := KettlePlan.jets(phase)
	var spin := randf() * TAU / n
	for i in n:
		var a := spin + TAU * i / n
		dirs.append(Vector3(cos(a), 0, sin(a)))
	var base := Vector3(global_position.x, 0, global_position.z)
	for d in dirs:
		for k in 4:
			Effects.warning(get_parent(), base + d * (2.2 + k * 1.5), 0.55, Mob.TELEGRAPH)
	await get_tree().create_timer(Mob.TELEGRAPH).timeout
	var p := _player()
	for d in dirs:
		for k in 5:
			Effects.sparkle(get_parent(), base + d * (2.0 + k * 1.3) + Vector3.UP * 0.6, Color(1, 1, 1), 2)
		# hit if the keeper stands on the jet's line
		var to := p.global_position - base
		to.y = 0.0
		var along := to.dot(d)
		var off := (to - d * along).length()
		if along > 1.5 and along < KettlePlan.JET_LENGTH and off < 0.7:
			p.hurt(KettlePlan.JET_DAMAGE, base + d * along)
	Audio.play("wind")


## Boiling drops land in circles around the keeper.
func _splash() -> void:
	var p := _player()
	var spots: Array[Vector3] = []
	for i in 2 + phase:
		var off := Vector3.ZERO if i == 0 else Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		spots.append(Vector3(p.global_position.x, 0, p.global_position.z) + off)
	for s in spots:
		Effects.warning(get_parent(), s, KettlePlan.SPLASH_RADIUS, Mob.TELEGRAPH)
	await get_tree().create_timer(Mob.TELEGRAPH).timeout
	for s in spots:
		Effects.ring(get_parent(), s + Vector3.UP * 0.15, KettlePlan.SPLASH_RADIUS, Tokens.color("sky"), 0.3)
		Effects.sparkle(get_parent(), s + Vector3.UP * 0.5, Tokens.color("sky"), 6)
	for s in spots:
		if Vector2(p.global_position.x - s.x, p.global_position.z - s.z).length() < KettlePlan.SPLASH_RADIUS:
			p.hurt(KettlePlan.SPLASH_DAMAGE, s)
			break
	Audio.play("splash")


## Puffed out: the lid pops up and it can be hit for a moment.
func _pop_lid() -> void:
	lid_up = true
	add_to_group("hittable")
	var tw := create_tween()
	tw.tween_property(_lid, "position:y", 3.4, 0.3).set_trans(Tween.TRANS_BACK)
	get_tree().call_group("hud", "show_hint", "Kapağı kalktı! Şimdi vur!", "Kapak kalktı! Şimdi vur!")
	await get_tree().create_timer(KettlePlan.LID_TIME).timeout
	if not active:
		return
	get_tree().call_group("hud", "clear_hint")
	lid_up = false
	remove_from_group("hittable")
	var back := create_tween()
	back.tween_property(_lid, "position:y", 2.25, 0.25)
	await back.finished


func hit(damage: int, _from: Vector3, _push: float) -> void:
	damage = Progression.boss_damage(damage, GameState.data.power)
	Effects.hit(self, true)
	if not lid_up or not active:
		return
	hp = maxi(hp - damage, 0)
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 3.6, str(damage), Tokens.color("panel@light"))
	hp_changed.emit(hp, KettlePlan.MAX_HP)
	var p := KettlePlan.phase(hp)
	if hp == 0:
		_simmer()
	elif p != phase:
		phase = p
		phase_changed.emit(phase)


func _simmer() -> void:
	active = false
	lid_up = false
	is_simmering = true
	remove_from_group("hittable")
	get_tree().call_group("hud", "clear_hint")
	var tw := create_tween()
	tw.tween_property(_lid, "position:y", 2.25, 0.3)
	add_to_group("dazed")
	simmering.emit()


func breathe_calm() -> void:
	if not is_simmering:
		return
	is_simmering = false
	remove_from_group("dazed")
	_face_cross.visible = false
	_face_calm.visible = true
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 2.5, Tokens.color("sky"), 18)
	GameState.notify("breathe", "caydanlik")
	calmed.emit()
