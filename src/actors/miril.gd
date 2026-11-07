class_name Miril
extends Node3D
## Gölge Prens Mırıl. Faz 1 here; Faz 2 (offering the sparks) is run by the
## chapter scene, which calls shrink() for each offered spark and reveal().

signal hp_changed(hp: int, max_hp: int)
signal shadow_calm   ## Faz 1 done: hp reached 0 (he is never "beaten")

var hp := MirilPlan.MAX_HP
var phase := 1
var active := false
var tired := false
var _model: Node3D
var _player: Player
var _sad: Label3D


func _ready() -> void:
	set_meta("hit_radius", 2.4)
	_model = MirilModel.shadow()
	add_child(_model)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.6
	cyl.height = 5.0
	c.shape = cyl
	c.position.y = 2.5
	body.add_child(c)
	add_child(body)


func _process(_delta: float) -> void:
	if not is_instance_valid(_model):
		return
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
	_model.position.y = sin(Time.get_ticks_msec() / 600.0) * 0.15 if not tired else -0.6
	if _player and active and not tired:
		var to := _player.global_position - global_position
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(to.x, to.z), 0.05)


func start() -> void:
	active = true
	_loop()


func _loop() -> void:
	while active:
		for attack in MirilPlan.cycle(phase):
			if not active:
				return
			await get_tree().create_timer(MirilPlan.rest(phase)).timeout
			await GameState.wait_dialogue_closed()
			if not active:
				return
			match attack:
				"copies": await _copies()
				"echo_owl": await _echo_owl()
				"echo_ring": await _echo_ring()
				"echo_icicles": await _echo_icicles()
				"tired": await _tired()


func _copies() -> void:
	var alive := 0
	for m in get_tree().get_nodes_in_group("mob"):
		if (m as Mob).kind == "golge_kopya":
			alive += 1
	var arms: Array[Node3D] = [_model.get_node("ArmL"), _model.get_node("ArmR")]
	var tw := create_tween().set_parallel()
	for a in arms:
		tw.tween_property(a, "rotation:x", -1.0, Mob.TELEGRAPH)
	await tw.finished
	for i in maxi(0, MirilPlan.MAX_COPIES - alive):
		var side := -1.0 if i == 0 else 1.0
		Mob.spawn(get_parent(), "golge_kopya", global_position + Vector3(4.0 * side, 0, 4.0))
	var back := create_tween().set_parallel()
	for a in arms:
		back.tween_property(a, "rotation:x", 0.0, 0.4)
	await back.finished


## A faded owl swoops where the circle warned.
func _echo_owl() -> void:
	var spot := _player.global_position
	Effects.warning(get_parent(), spot, 2.0, Mob.TELEGRAPH)
	var owl := OwlModel.build()
	owl.scale = Vector3.ONE * 0.6
	get_parent().add_child(owl)
	owl.global_position = spot + Vector3(0, 10, -4)
	var tint := Toon.material(Color("#8d89a0"), 0.03, 0.0, 0.0)
	for mi in owl.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = tint
	await get_tree().create_timer(Mob.TELEGRAPH).timeout
	var tw := owl.create_tween()
	tw.tween_property(owl, "global_position", spot, 0.25).set_ease(Tween.EASE_IN)
	await tw.finished
	Effects.ring(get_parent(), spot + Vector3.UP * 0.2, 2.6, Tokens.color("pus"), 0.4)
	if _player.global_position.distance_to(spot) < 2.0:
		_player.hurt(MirilPlan.ECHO_DAMAGE, spot)
	var out := owl.create_tween()
	out.tween_property(owl, "scale", Vector3.ZERO, 0.3)
	out.tween_callback(owl.queue_free)


## The Kütük Kral's ring, in grey: jump over it.
func _echo_ring() -> void:
	get_tree().call_group("hud", "show_hint", "Halka geliyor: zıpla!", "Halka: zıpla!")
	Effects.warning(get_parent(), global_position, 3.0, Mob.TELEGRAPH)
	await get_tree().create_timer(Mob.TELEGRAPH).timeout
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.92
	t.outer_radius = 1.0
	t.rings = 48
	mi.mesh = t
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Tokens.color("spark-purple")
	mi.material_override = m
	get_parent().add_child(mi)
	mi.global_position = global_position + Vector3.UP * 0.25
	var r := 2.5
	var hit := false
	while r < KingPlan.RING_MAX and active:
		r += KingPlan.RING_SPEED * get_process_delta_time()
		mi.scale = Vector3(r, 3.0, r)
		var d := Vector2(_player.global_position.x - global_position.x, _player.global_position.z - global_position.z).length()
		if not hit and KingPlan.ring_hits(d, r, _player.global_position.y - global_position.y):
			hit = _player.hurt(MirilPlan.ECHO_DAMAGE, global_position)
		await get_tree().process_frame
	mi.queue_free()
	get_tree().call_group("hud", "clear_hint")


## Dondurma's icicles, in grey.
func _echo_icicles() -> void:
	var spots: Array[Vector3] = [_player.global_position]
	for i in 4:
		spots.append(spots[0] + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)))
	for s in spots:
		Effects.warning(get_parent(), s, 1.1, Mob.TELEGRAPH)
	await get_tree().create_timer(Mob.TELEGRAPH).timeout
	for s in spots:
		var ic := Toon.part(get_parent(), "cone", Vector3(0.7, 1.8, 0.7), Color("#8d89a0"), s + Vector3.UP * 0.9, Vector3(180, 0, 0), 0.0, 0.03)
		var tw := ic.create_tween()
		tw.tween_interval(0.6)
		tw.tween_property(ic, "scale", Vector3.ZERO, 0.2)
		tw.tween_callback(ic.queue_free)
		if Vector2(_player.global_position.x - s.x, _player.global_position.z - s.z).length() < 1.2:
			_player.hurt(MirilPlan.ECHO_DAMAGE, s)


## He sits down, tired and sad. The moment to reach him.
func _tired() -> void:
	tired = true
	add_to_group("hittable")
	_sad = Label3D.new()
	_sad.text = "..."
	_sad.font = Tokens.font_for("text-hero")
	_sad.font_size = 120
	_sad.pixel_size = 0.008
	_sad.outline_size = 20
	_sad.outline_modulate = Tokens.color("outline")
	_sad.modulate = Tokens.color("spark-purple")
	_sad.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sad.position.y = 6.0
	add_child(_sad)
	get_tree().call_group("hud", "show_hint", "Mırıl yoruldu. Şimdi yaklaş!", "Mırıl yoruldu. Yaklaş!")
	await get_tree().create_timer(MirilPlan.TIRED_TIME).timeout
	if is_instance_valid(_sad):
		_sad.queue_free()
	if not active:
		return
	tired = false
	remove_from_group("hittable")
	get_tree().call_group("hud", "clear_hint")


func hit(damage: int, _from: Vector3, _push: float) -> void:
	damage = Progression.boss_damage(damage, GameState.data.power)
	Effects.hit(self, true)
	if not tired or not active:
		return
	hp = maxi(hp - damage, 0)
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 5.5, str(damage), Tokens.color("panel@light"))
	hp_changed.emit(hp, MirilPlan.MAX_HP)
	phase = MirilPlan.phase(hp)
	if hp == 0:
		active = false
		tired = true
		remove_from_group("hittable")
		get_tree().call_group("hud", "clear_hint")
		for m in get_tree().get_nodes_in_group("mob"):
			if m.has_method("hit"):
				m.hit(9999, global_position, 0.0)
		shadow_calm.emit()


## Faz 2: each offered spark makes the shadow a little smaller.
func shrink(step: int) -> void:
	var k := 1.0 - 0.15 * step
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3.ONE * k, 0.8).set_trans(Tween.TRANS_BACK)


## The shadow falls away; a little star child stands there.
func reveal() -> void:
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 3, Tokens.color("spark-white"), 30)
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(1.4, 0.02, 1.4), 1.2).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_model.queue_free()
	var child := MirilModel.star_child()
	add_child(child)
	_model = child   # the star child is Mırıl now
	child.scale = Vector3.ZERO
	var t2 := child.create_tween()
	t2.tween_property(child, "scale", Vector3.ONE * 1.3, 0.8).set_trans(Tween.TRANS_BACK)
	await t2.finished
