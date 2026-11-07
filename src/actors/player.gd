class_name Player
extends CharacterBody3D
## Fıstık in the prologue (later: the chosen keeper). Moves on the ground
## plane relative to the fixed camera; jumps, quill-spins, rolls into a ball,
## drinks potions and talks. Nobody dies: at 0 HP the player falls asleep
## and wakes at the last lit lantern (respawn_point).

signal focus_changed(target: Node)
signal fell_asleep
signal fell_off   ## dropped off the world (e.g. into the clouds)

const LAYER_WORLD := 1
const LAYER_LOW_BARRIER := 16   ## beams you can only roll under
const ATTACK_RADIUS := 1.9
const ROLL_TIME := 0.55
const ROLL_SPEED := 13.0
const INVULNERABLE_TIME := 1.0
const SKILL_COST := 20

@export var speed := 6.0
@export var acceleration := 40.0
@export var jump_velocity := 7.5
@export var gravity := 22.0

var input_enabled := true
## Walking speed multiplier (syrup pools set it below 1).
var slow := 1.0
## Steady push from storm wind (m/s), set by WindZone; shelters zero it.
var wind := Vector3.ZERO
## On slippery ice: very low grip, you slide.
var ice := false
var model: Node3D
var respawn_point := Vector3.ZERO
var rolling := false
var asleep := false
var climbing := false   ## set by ClimbZone while touching a vine wall
var _focus: Node = null
var _spin_tween: Tween
var _bob_time := 0.0
var _rig: CharacterRig
var _was_grounded := true
var _air_time := 0.0
var _nearby: Array[Area3D] = []
var _attack_cd := 0.0
var _invulnerable := 0.0
var _roll_left := 0.0
var _roll_dir := Vector3.FORWARD
var _knock := Vector3.ZERO
var _move := Vector3.ZERO   ## walking velocity, without knockback
var _power_until := 0.0     ## Cesaret Şekeri: stronger until this time (s)
var _air_jumps := 0
var _shield := 0.0
var _shield_mesh: MeshInstance3D
var _col: CollisionShape3D
var _stand_shape: CapsuleShape3D
var _ball_shape: SphereShape3D


func _ready() -> void:
	add_to_group("player")
	speed = GameState.data.speed
	respawn_point = global_position
	collision_mask = LAYER_WORLD | LAYER_LOW_BARRIER
	_col = CollisionShape3D.new()
	_stand_shape = CapsuleShape3D.new()
	_stand_shape.radius = 0.45
	_stand_shape.height = 1.5
	_ball_shape = SphereShape3D.new()
	_ball_shape.radius = 0.45
	_col.shape = _stand_shape
	_col.position.y = 0.75
	add_child(_col)
	model = FistikModel.build() if GameState.data.character_id == "fistik" \
		else KeeperModels.build(GameState.data.character_id, GameState.data.character_look)
	add_child(model)
	_rig = CharacterRig.of(model)
	var sensor := Area3D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 4  # interactables
	sensor.monitorable = false
	var sc := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.8
	sc.shape = sphere
	sensor.add_child(sc)
	add_child(sensor)
	sensor.area_entered.connect(func(a: Area3D) -> void: _nearby.append(a))
	sensor.area_exited.connect(func(a: Area3D) -> void: _nearby.erase(a))


func _physics_process(delta: float) -> void:
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	if _shield > 0.0:
		_shield -= delta
		if _shield <= 0.0 and _shield_mesh:
			_shield_mesh.queue_free()
			_shield_mesh = null
	model.visible = _invulnerable <= 0.0 or rolling or fmod(_invulnerable, 0.16) < 0.1
	if rolling:
		_process_roll(delta)
		return
	var dir := Vector3.ZERO
	if input_enabled and not asleep:
		var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		dir = Vector3(v.x, 0.0, v.y)
	var target := dir * speed * slow
	var grip := acceleration * (0.12 if ice else 1.0)
	_move.x = move_toward(_move.x, target.x, grip * delta)
	_move.z = move_toward(_move.z, target.z, grip * delta)
	velocity.x = _move.x + _knock.x + wind.x
	velocity.z = _move.z + _knock.z + wind.z
	_knock = _knock.move_toward(Vector3.ZERO, 30.0 * delta)
	if climbing:
		var up := Input.get_axis("move_back", "move_forward") if input_enabled else 0.0
		velocity.y = up * 4.0
		if input_enabled and Input.is_action_just_pressed("jump"):
			climbing = false
			velocity.y = jump_velocity * 0.8
	elif is_on_floor():
		_air_jumps = 1 if GameState.data.character_id == "pati" else 0
		if input_enabled and not asleep and Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			if _rig:
				_rig.jump()
	else:
		velocity.y -= gravity * delta
		# Pati's world ability: a second jump in the air
		if _air_jumps > 0 and input_enabled and not asleep and Input.is_action_just_pressed("jump"):
			_air_jumps -= 1
			velocity.y = jump_velocity * 0.9
			if _rig:
				_rig.jump()
			Effects.ring(get_parent(), global_position + Vector3.UP * 0.2, 1.2, Tokens.color("berry"), 0.25)
	move_and_slide()
	if global_position.y < -12.0:
		_fall_back()
	if _rig:
		var grounded := is_on_floor() or climbing
		if grounded and not _was_grounded and _air_time > 0.15:
			_rig.land()
		_air_time = 0.0 if grounded else _air_time + delta
		_was_grounded = grounded
		_rig.airborne = not grounded and _air_time > 0.1
		_rig.speed = Vector2(_move.x, _move.z).length() / maxf(speed, 0.1)
	if dir.length() > 0.1:
		_roll_dir = dir.normalized()
		var want := atan2(dir.x, dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, want, 1.0 - exp(-14.0 * delta))
		_bob_time += delta * 14.0
		model.position.y = abs(sin(_bob_time)) * (0.05 if _rig else 0.12)
	else:
		model.position.y = move_toward(model.position.y, 0.0, delta)
	_update_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or asleep:
		return
	if event.is_action_pressed("interact") and _focus:
		interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("attack"):
		spin_attack()
	elif event.is_action_pressed("roll"):
		start_roll()
	elif event.is_action_pressed("skill"):
		use_skill()
	else:
		for i in 4:
			if event.is_action_pressed("potion_%d" % (i + 1)):
				drink_potion(i)


func current_focus() -> Node:
	return _focus


func interact() -> void:
	if _focus and _focus.has_method("interact"):
		_focus.interact(self)


# --- combat ------------------------------------------------------------

## Basic quill attack: a quick spin that hits every mob around Fıstık.
func spin_attack() -> void:
	if _attack_cd > 0.0 or rolling:
		return
	_attack_cd = 0.38
	if _rig:
		_rig.attack()
	if _spin_tween and _spin_tween.is_running():
		_spin_tween.kill()
	_spin_tween = create_tween()
	var start := model.rotation.y
	_spin_tween.tween_property(model, "rotation:y", start + TAU, 0.3).set_trans(Tween.TRANS_QUAD)
	_hit_around(ATTACK_RADIUS, attack_power(), 7.0)


## L key / skill button: the character's special skill.
func use_skill() -> void:
	var id := GameState.data.active_skill()
	if id == "" or _attack_cd > 0.0 or rolling or asleep:
		return
	if not GameState.data.use_mp(int(Skills.DEFS[id]["mp"])):
		GameState.toast.emit("Enerjin az. Yıldız Tozu iç!", "drop")
		return
	match id:
		"dikenli_donus": _dikenli_donus()
		"pence_kombosu": _pence_kombosu()
		"kucaklama_kalkani": _kucaklama_kalkani()
		"findik_firlatma": _findik_firlatma()
		"isik_patlamasi": _isik_patlamasi()


## Kept for older callers (tests, demos).
func dikenli_donus() -> void:
	if GameState.data.active_skill() == "dikenli_donus":
		use_skill()


## Fıstık, learned in Sahne 3: a big double spin with a shock ring.
func _dikenli_donus() -> void:
	_attack_cd = 0.7
	var tw := create_tween()
	tw.tween_property(model, "rotation:y", model.rotation.y + TAU * 2.0, 0.55).set_trans(Tween.TRANS_CUBIC)
	Effects.ring(get_parent(), global_position + Vector3.UP * 0.4, 3.6, Tokens.color("honey"), 0.45)
	_hit_around(3.4, attack_power() * 2 + 5, 8.0)


## Pati: three quick claw swipes in front.
func _pence_kombosu() -> void:
	_attack_cd = 0.75
	var fwd := Vector3(sin(model.rotation.y), 0, cos(model.rotation.y))
	for i in 3:
		var tw := create_tween()
		tw.tween_property(model, "position", fwd * 0.5, 0.06)
		tw.tween_property(model, "position", Vector3.ZERO, 0.08)
		Effects.ring(get_parent(), global_position + fwd * 1.4 + Vector3.UP * 0.6, 1.0, Tokens.color("berry"), 0.18)
		for m in get_tree().get_nodes_in_group("hittable"):
			var n := m as Node3D
			var to := n.global_position - global_position
			to.y = 0.0
			if to.length() <= 2.6 + n.get_meta("hit_radius", 0.5) and (to.length() < 0.8 or to.normalized().dot(fwd) > 0.3):
				n.hit(attack_power(), global_position, 3.0)
		await get_tree().create_timer(0.16).timeout


## Bado: a big warm hug-shield — no damage for a while.
func _kucaklama_kalkani() -> void:
	_attack_cd = 0.4
	_shield = 4.0
	if _shield_mesh:
		_shield_mesh.queue_free()
	_shield_mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.1
	sm.height = 2.2
	_shield_mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Tokens.color("spark-green")
	mat.albedo_color.a = 0.3
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shield_mesh.material_override = mat
	_shield_mesh.position.y = 0.9
	add_child(_shield_mesh)
	Effects.ring(get_parent(), global_position + Vector3.UP * 0.3, 2.4, Tokens.color("spark-green"), 0.4)


## Çıtır: a hazelnut that bounces between up to three mobs.
func _findik_firlatma() -> void:
	_attack_cd = 0.5
	var targets: Array[Node3D] = []
	var from := global_position + Vector3.UP * 0.9
	for b in Skills.NUT_BOUNCES:
		var best: Node3D = null
		var best_d := 9.0
		for m in get_tree().get_nodes_in_group("hittable"):
			var n := m as Node3D
			if targets.has(n):
				continue
			var d := n.global_position.distance_to(from)
			if d < best_d:
				best_d = d
				best = n
		if best == null:
			break
		targets.append(best)
		from = best.global_position
	var nut := Toon.part(get_parent(), "sphere", Vector3(0.3, 0.34, 0.3), Color("#b5713e"), global_position + Vector3.UP * 0.9)
	if targets.is_empty():
		var fwd := Vector3(sin(model.rotation.y), 0, cos(model.rotation.y))
		var tw := nut.create_tween()
		tw.tween_property(nut, "global_position", nut.global_position + fwd * 6.0, 0.35)
		tw.tween_callback(nut.queue_free)
		return
	for t in targets:
		var tw := nut.create_tween()
		tw.tween_property(nut, "global_position", t.global_position + Vector3.UP * 0.8, 0.15)
		await tw.finished
		if is_instance_valid(t) and t.is_in_group("hittable"):
			t.hit(attack_power() + 4, nut.global_position, 4.0)
	nut.queue_free()


## Lumi: a burst of light that hits everything around and heals.
func _isik_patlamasi() -> void:
	_attack_cd = 0.7
	Effects.ring(get_parent(), global_position + Vector3.UP * 0.5, 4.2, Tokens.color("spark-yellow"), 0.5)
	Effects.sparkle(get_parent(), global_position + Vector3.UP, Tokens.color("spark-yellow"), 16)
	_hit_around(4.0, attack_power() + 6, 6.0)
	GameState.data.heal(Skills.LIGHT_HEAL)
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 2.0, "+%d" % Skills.LIGHT_HEAL, Tokens.color("leaf"))


func _hit_around(radius: float, damage: int, push: float) -> void:
	for m in get_tree().get_nodes_in_group("hittable"):
		var n := m as Node3D
		if n and n.global_position.distance_to(global_position) <= radius + n.get_meta("hit_radius", 0.5):
			n.hit(damage, global_position, push)


func start_roll() -> void:
	if rolling or not is_on_floor() or climbing:
		return
	rolling = true
	_roll_left = ROLL_TIME
	_col.shape = _ball_shape
	_col.position.y = 0.45
	collision_mask = LAYER_WORLD
	var tw := create_tween()
	tw.tween_property(model, "scale", Vector3(0.8, 0.6, 0.8), 0.08)


func _process_roll(delta: float) -> void:
	_roll_left -= delta
	velocity.x = _roll_dir.x * ROLL_SPEED
	velocity.z = _roll_dir.z * ROLL_SPEED
	velocity.y -= gravity * delta
	move_and_slide()
	model.rotate_object_local(Vector3.RIGHT, delta * 22.0)
	for m in get_tree().get_nodes_in_group("hittable"):
		var n := m as Node3D
		if n and n.global_position.distance_to(global_position) < 1.1 + n.get_meta("hit_radius", 0.5) and n.has_method("bump"):
			n.bump(global_position)
	if _roll_left <= 0.0 and not _ceiling_blocked():
		rolling = false
		_col.shape = _stand_shape
		_col.position.y = 0.75
		collision_mask = LAYER_WORLD | LAYER_LOW_BARRIER
		model.rotation.x = 0.0
		model.rotation.z = 0.0
		var tw := create_tween()
		tw.tween_property(model, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK)


## Keep rolling while still under a beam, so we never stand up inside it.
func _ceiling_blocked() -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _stand_shape
	q.transform = Transform3D(Basis(), global_position + Vector3.UP * 0.8)
	q.collision_mask = LAYER_LOW_BARRIER
	return not get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


## Attack power, ×1.5 while a Cesaret Şekeri is active.
func attack_power() -> int:
	var p := GameState.data.power
	return int(p * 1.5) if Time.get_ticks_msec() / 1000.0 < _power_until else p


## A shove from an explosion or a gust (added to knockback).
func push(v: Vector3) -> void:
	if rolling:
		return
	_knock += Vector3(v.x, 0, v.z)


## Called by mobs and hazards. Returns false while invulnerable.
func hurt(amount: int, from: Vector3) -> bool:
	if _invulnerable > 0.0 or rolling or asleep:
		return false
	if _shield > 0.0:
		Effects.ring(get_parent(), global_position + Vector3.UP * 0.9, 1.6, Tokens.color("spark-green"), 0.2)
		amount = Skills.shielded_damage(amount)
		if amount <= 0:
			return false
	_invulnerable = INVULNERABLE_TIME
	var away := (global_position - from)
	away.y = 0.0
	_knock = away.normalized() * 9.0
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 2.0, str(amount), Tokens.color("hp"))
	if GameState.data.take_damage(amount):
		_fall_asleep()
	return true


func drink_potion(slot: int) -> void:
	var d := GameState.data
	var id: String = d.potions[slot] if slot < d.potions.size() else ""
	if id == "" or not d.has_item(id):
		return
	var def: Dictionary = Content.items.get(id, {})
	if def.has("heal"):
		if d.hp >= d.max_hp:
			GameState.toast.emit("Canın zaten dolu", "heart")
			return
		d.heal(int(def["heal"]))
		FloatText.spawn(get_parent(), global_position + Vector3.UP * 2.0, "+%d" % int(def["heal"]), Tokens.color("leaf"))
	elif def.has("mp"):
		d.restore_mp(int(def["mp"]))
		FloatText.spawn(get_parent(), global_position + Vector3.UP * 2.0, "+%d" % int(def["mp"]), Tokens.color("mp"))
	elif def.get("buff", "") == "guc":
		_power_until = Time.get_ticks_msec() / 1000.0 + float(def["seconds"])
		GameState.toast.emit("%d saniye gücün arttı!" % int(def["seconds"]), "star")
	elif def.get("buff", "") == "kovucu":
		GameState.repel_until = Time.get_ticks_msec() / 1000.0 + float(def["seconds"])
		GameState.toast.emit("%d saniye moblar seni zor fark eder" % int(def["seconds"]), "drop")
	d.remove_item(id)
	Effects.ring(get_parent(), global_position + Vector3.UP * 0.2, 1.4, Tokens.color(def.get("color", "honey")), 0.3)


func _fall_asleep() -> void:
	asleep = true
	fell_asleep.emit()
	var tw := create_tween()
	tw.tween_property(model, "rotation:z", PI / 2.2, 0.4).set_trans(Tween.TRANS_BOUNCE)
	await get_tree().create_timer(0.6).timeout
	get_tree().call_group("hud", "show_scene_card", "", "Uykuya daldın", "Fener'in yanında uyanıyorsun...")
	await get_tree().create_timer(2.2).timeout
	global_position = respawn_point
	velocity = Vector3.ZERO
	model.rotation.z = 0.0
	GameState.data.wake_up()
	asleep = false
	_invulnerable = 2.0


func _fall_back() -> void:
	global_position = respawn_point + Vector3.UP * 0.5
	velocity = Vector3.ZERO
	fell_off.emit()
	hurt(10, global_position)
	_invulnerable = 1.5


func _update_focus() -> void:
	var best: Node = null
	var best_d := INF
	for a in _nearby:
		if not is_instance_valid(a):
			continue
		var owner_node: Node = a.get_meta("interactable", null)
		if owner_node == null:
			continue
		var d := global_position.distance_squared_to(a.global_position)
		if d < best_d:
			best_d = d
			best = owner_node
	if best != _focus:
		_focus = best
		focus_changed.emit(_focus)


## Caves: the keeper carries a small warm light. Lumi's own glow reaches
## much further (her world ability, Aydınlatma).
func carry_light() -> OmniLight3D:
	var l := OmniLight3D.new()
	var lumi := GameState.data.character_id == "lumi"
	l.light_color = Tokens.color("spark-yellow") if lumi else Color("#ffe2b0")
	l.light_energy = 1.8 if lumi else 1.5
	l.omni_range = 12.0 if lumi else 8.0
	l.position = Vector3(0, 2.2, 0.4)
	add_child(l)
	return l
