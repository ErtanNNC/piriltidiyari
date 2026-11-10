class_name GiantShadow
extends Node3D
## The Dev Gölge (Season 3 prologue, Sahne 4): a huge dark crab shape
## standing over the cliff. Claw sweeps along a warned line, falling rocks
## on warned circles, a slam on a big warned circle. It can't be hit: each
## round frees a torch (`torch_free`), and every torch lit makes it smaller
## (`shrink`). After the third it is tiny and `revealed` fires.

signal torch_free(index: int)
signal revealed

var phase := 1
var active := false
var home := Vector3.ZERO
var _shape: Node3D
var _claws: Array[Node3D] = []
var _t := 0.0
var _waiting_torch := false


func _ready() -> void:
	_shape = Node3D.new()
	add_child(_shape)
	var dark := Color("#141a3a")
	Toon.default_pus = 0.0
	var body := Toon.part(_shape, "ellipsoid", Vector3(7.0, 4.2, 1.0), dark, Vector3(0, 3.4, 0), Vector3.ZERO, 0.0, 0.0)
	body.name = "Body"
	for s: float in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(3.6 * s, 4.2, 0)
		_shape.add_child(arm)
		Toon.part(arm, "capsule", Vector3(0.9, 3.4, 0.6), dark, Vector3(1.0 * s, 1.2, 0), Vector3(0, 0, -35 * s), 0.0, 0.0)
		Toon.part(arm, "ellipsoid", Vector3(2.6, 2.0, 0.7), dark, Vector3(2.2 * s, 3.0, 0), Vector3.ZERO, 0.0, 0.0)
		Toon.part(arm, "cone", Vector3(0.9, 1.6, 0.5), dark, Vector3(2.9 * s, 4.2, 0), Vector3(0, 0, -20 * s), 0.0, 0.0)
		Toon.part(arm, "cone", Vector3(0.7, 1.3, 0.5), dark, Vector3(1.7 * s, 4.1, 0), Vector3(0, 0, 25 * s), 0.0, 0.0)
		_claws.append(arm)
		for k in 3:
			Toon.part(_shape, "capsule", Vector3(0.4, 2.6, 0.3), dark, Vector3((2.2 + k * 1.1) * s, 1.3, 0), Vector3(0, 0, (-28.0 - k * 12.0) * s), 0.0, 0.0)
		# two pale eyes, more worried than fierce
		Toon.part(_shape, "ellipsoid", Vector3(0.8, 1.0, 0.3), Color("#cfe0ff"), Vector3(1.1 * s, 5.9, 0.3), Vector3.ZERO, 1.2, 0.0)
		Toon.part(_shape, "capsule", Vector3(0.25, 1.0, 0.2), dark, Vector3(1.1 * s, 5.2, 0), Vector3.ZERO, 0.0, 0.0)
	Toon.default_pus = 1.0
	# a shadow lies on the ground: flat over the arena, feet at the lantern
	_shape.rotation.x = PI * 0.5
	_shape.scale = Vector3(1.6, 1.6, 0.05)
	_shape.position.y = 0.12
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.05, 0.07, 0.2, 0.62)
	for mi: MeshInstance3D in _shape.find_children("*", "MeshInstance3D", true, false):
		if mi.position.y < 5.5 or mi.mesh is CapsuleMesh:
			mi.material_override = mat
	home = position


func _process(delta: float) -> void:
	_t += delta
	for i in _claws.size():
		_claws[i].rotation.z = sin(_t * 1.6 + i * PI) * 0.18
	_shape.position.z = sin(_t * 1.1) * 0.25


func start() -> void:
	active = true
	_loop()


func _player() -> Player:
	return get_tree().get_first_node_in_group("player")


func _loop() -> void:
	while active:
		for move in DevGolgePlan.cycle(phase):
			if not active:
				return
			await get_tree().create_timer(DevGolgePlan.rest(phase)).timeout
			if not active:
				return
			await GameState.wait_dialogue_closed()
			if not active:
				return
			match move:
				"claw":
					await _claw()
				"rocks":
					await _rocks()
				"slam":
					await _slam()
				_:
					if not _waiting_torch:
						_waiting_torch = true
						torch_free.emit(phase - 1)


## A claw sweeps along a line across the keeper's spot.
func _claw() -> void:
	var p := _player()
	var side := -1.0 if randf() < 0.5 else 1.0
	var mid := Vector3(p.global_position.x, global_position.y, p.global_position.z)
	var spots: Array[Vector3] = []
	for k in 6:
		spots.append(mid + Vector3((k - 2.5) * 1.9 * side, 0, 0))
	for s in spots:
		Effects.warning(get_parent(), s, 1.0, Mob.TELEGRAPH)
	var claw := _claws[0 if side < 0 else 1]
	var tw := create_tween()
	tw.tween_property(claw, "rotation:z", -0.9 * side, Mob.TELEGRAPH)
	await tw.finished
	Audio.play("whoosh")
	var back := create_tween()
	back.tween_property(claw, "rotation:z", 0.5 * side, 0.15)
	back.tween_property(claw, "rotation:z", 0.0, 0.4)
	for s in spots:
		Effects.ring(get_parent(), s + Vector3.UP * 0.3, 1.0, Color("#3a4a8a"), 0.3)
		if Vector2(p.global_position.x - s.x, p.global_position.z - s.z).length() < 1.0:
			p.hurt(DevGolgePlan.CLAW_DAMAGE, s)
			break


## The cliff shakes: small rocks drop on warned circles.
func _rocks() -> void:
	var p := _player()
	var spots: Array[Vector3] = []
	for i in DevGolgePlan.rocks(phase):
		var off := Vector3.ZERO if i == 0 else Vector3(randf_range(-5, 5), 0, randf_range(-4, 4))
		spots.append(Vector3(p.global_position.x, global_position.y, p.global_position.z) + off)
	for s in spots:
		Effects.warning(get_parent(), s, DevGolgePlan.ROCK_RADIUS, Mob.TELEGRAPH)
	get_tree().call_group("camera", "shake", 0.3)
	await get_tree().create_timer(Mob.TELEGRAPH).timeout
	Audio.play("stone")
	for s in spots:
		var rock := Toon.part(get_parent(), "sphere", Vector3(1.0, 0.8, 1.0), Color("#6a6680"), s + Vector3.UP * 0.3)
		var tw := rock.create_tween()
		tw.tween_property(rock, "scale", Vector3(0.1, 0.1, 0.1), 0.6).set_delay(0.3)
		tw.tween_callback(rock.queue_free)
		if Vector2(p.global_position.x - s.x, p.global_position.z - s.z).length() < DevGolgePlan.ROCK_RADIUS:
			p.hurt(DevGolgePlan.ROCK_DAMAGE, s)


## The whole shadow leans over: one big circle.
func _slam() -> void:
	var p := _player()
	var s := Vector3(p.global_position.x, global_position.y, p.global_position.z)
	Effects.warning(get_parent(), s, DevGolgePlan.SLAM_RADIUS, Mob.TELEGRAPH)
	var tw := create_tween()
	tw.tween_property(_shape, "scale", Vector3(2.0, 2.0, 0.05), Mob.TELEGRAPH)
	await tw.finished
	Audio.play("stone")
	Effects.ring(get_parent(), s + Vector3.UP * 0.3, DevGolgePlan.SLAM_RADIUS, Color("#3a4a8a"), 0.4)
	var back := create_tween()
	back.tween_property(_shape, "scale", Vector3(1.6, 1.6, 0.05), 0.5)
	if Vector2(p.global_position.x - s.x, p.global_position.z - s.z).length() < DevGolgePlan.SLAM_RADIUS:
		p.hurt(DevGolgePlan.SLAM_DAMAGE, s)


## A torch was lit (`lit` so far): the shadow is smaller now.
func shrink(lit: int) -> void:
	_waiting_torch = false
	var k: float = DevGolgePlan.SCALE[clampi(lit, 0, 3)]
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * k, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Effects.ring(get_parent(), global_position + Vector3.UP * 0.3, 6.0, Color(1.0, 0.85, 0.5), 0.6)
	if lit >= DevGolgePlan.PHASES:
		active = false
		await tw.finished
		var fade := create_tween()
		fade.tween_property(self, "scale", Vector3.ONE * 0.01, 0.6)
		fade.tween_callback(func() -> void:
			visible = false
			revealed.emit())
	else:
		phase = lit + 1
