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
var _step_t := 0.0
var _step_side := 1.0
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
	_build_model()
	_refresh_bonus()
	GameState.data.stats_changed.connect(_maybe_rebuild)
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
			Audio.play("jump")
			if _rig:
				_rig.jump()
	else:
		velocity.y -= gravity * delta
		# Pati's world ability: a second jump in the air
		if _air_jumps > 0 and input_enabled and not asleep and Input.is_action_just_pressed("jump"):
			_air_jumps -= 1
			velocity.y = jump_velocity * 0.9
			Audio.play("jump2")
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
			Audio.play("land")
			_step_fx(3)
		_air_time = 0.0 if grounded else _air_time + delta
		_was_grounded = grounded
		_rig.airborne = not grounded and _air_time > 0.1
		_rig.speed = Vector2(_move.x, _move.z).length() / maxf(speed, 0.1)
	if dir.length() > 0.1:
		_roll_dir = dir.normalized()
		var want := atan2(dir.x, dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, want, 1.0 - exp(-14.0 * delta))
		_bob_time += delta * 14.0
		if is_on_floor() and Vector2(velocity.x, velocity.z).length() > 2.0:
			_step_t -= delta
			if _step_t <= 0.0:
				_step_t = 0.26
				_step_fx(1)
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
	elif event.is_action_pressed("shoot"):
		shoot()
	elif event.is_action_pressed("tool_1"):
		switch_tool(0)
	elif event.is_action_pressed("tool_2"):
		switch_tool(1)
	elif event.is_action_pressed("tool_3"):
		switch_tool(2)
	elif event.is_action_pressed("power_1"):
		use_power(0)
	elif event.is_action_pressed("power_2"):
		use_power(1)
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
	Audio.play("swish")
	if _rig:
		_rig.attack()
	if _spin_tween and _spin_tween.is_running():
		_spin_tween.kill()
	_spin_tween = create_tween()
	var start := model.rotation.y
	_spin_tween.tween_property(model, "rotation:y", start + TAU, 0.3).set_trans(Tween.TRANS_QUAD)
	var tool: String = GameState.data.equipped.get("weapon", "")
	if not GameState.data.has_flag("owned_" + tool):
		tool = ""
	match tool:
		"yildiz_asasi":
			# Yıldız Halkası: a wide purple star ring around the keeper
			Effects.ring(get_parent(), global_position + Vector3.UP * 0.4, 3.4, Tokens.color("spark-purple"), 0.35)
			Effects.sparkle(get_parent(), global_position + Vector3.UP, Tokens.color("spark-purple"), 8)
			_hit_around(3.2, attack_power(), 9.0)
		"isik_degnegi":
			# Yıldız Atışı: the spin plus a little star bolt straight ahead
			_hit_around(ATTACK_RADIUS, attack_power(), 7.0)
			LightSeed.fire(get_parent(), global_position + Vector3.UP + _facing() * 0.7, _facing(), maxi(1, attack_power() / 2), "spark-yellow", 8.0, 0.8)
		"kivilcim_kilici":
			# Kıvılcım Dalgası: the spin plus a sky-blue wave that runs forward
			_hit_around(ATTACK_RADIUS, attack_power(), 7.0)
			_spark_wave()
		_:
			_hit_around(ATTACK_RADIUS, attack_power(), 7.0)


## L key / skill button: the character's special skill.
func use_skill() -> void:
	var id := GameState.data.active_skill()
	if id == "" or _attack_cd > 0.0 or rolling or asleep:
		return
	if not GameState.data.use_mp(int(Skills.DEFS[id]["mp"])):
		GameState.toast.emit("Enerjin az. Yıldız Tozu iç!", "drop")
		return
	Audio.play("skill")
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
	Audio.play("roll")
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
	var p := roundi((GameState.data.power + Shop.weapon_power(GameState.data, Content.items)) * Powers.attack_mult(GameState.data.powers))
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
	amount = Shop.guarded(amount, _bonus)
	_invulnerable = INVULNERABLE_TIME
	Audio.play("hurt")
	Effects.shake(get_viewport(), 0.22)
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
	Audio.play("heal")
	Effects.ring(get_parent(), global_position + Vector3.UP * 0.2, 1.4, Tokens.color(def.get("color", "honey")), 0.3)


func _fall_asleep() -> void:
	asleep = true
	Audio.play("sleep")
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
	Audio.play("wake")
	asleep = false
	_invulnerable = 2.0


func _fall_back() -> void:
	global_position = respawn_point + Vector3.UP * 0.5
	velocity = Vector3.ZERO
	Audio.play("fall")
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


## A step: paw prints in snow, a small dust puff elsewhere (not on ice/syrup).
func _step_fx(count: int) -> void:
	var feet := global_position
	if WorldLook.current_mood == "dag" and not ice:
		_step_side = -_step_side
		var side := Vector3(cos(model.rotation.y), 0, -sin(model.rotation.y)) * 0.16 * _step_side
		Effects.footprint(get_parent(), feet + side, model.rotation.y, Color(0.62, 0.68, 0.86, 0.55))
		if count > 1:
			Effects.dust(get_parent(), feet, Color(1, 1, 1, 0.8), count, 0.5)
	elif not ice and slow >= 1.0:
		var col := Color(1.0, 0.97, 0.9, 0.55) if WorldLook.current_mood != "magara" else Color(0.75, 0.68, 0.95, 0.45)
		Effects.dust(get_parent(), feet, col, count, 0.45 if count == 1 else 0.6)


# --- looks (Bekçi Evi, Terzi Dikiş) ------------------------------------------

var _look_key := ""


## The keeper's model with their look plus the worn outfit and held tool.
func _build_model() -> void:
	var d := GameState.data
	var look: Dictionary = d.character_look.duplicate()
	look["outfit"] = d.equipped.get("outfit", "")
	look["weapon"] = d.equipped.get("weapon", "")
	_look_key = "%s|%s" % [d.character_id, JSON.stringify(look)]
	var yaw := model.rotation.y if model else 0.0
	if model:
		model.queue_free()
	model = FistikModel.build() if d.character_id == "fistik" else KeeperModels.build(d.character_id, look)
	model.rotation.y = yaw
	add_child(model)
	_rig = CharacterRig.of(model)


## Rebuild only when the keeper, look, outfit or tool really changed.
func _maybe_rebuild() -> void:
	var d := GameState.data
	_refresh_bonus()
	var look: Dictionary = d.character_look.duplicate()
	look["outfit"] = d.equipped.get("outfit", "")
	look["weapon"] = d.equipped.get("weapon", "")
	if "%s|%s" % [d.character_id, JSON.stringify(look)] != _look_key:
		_build_model()
		Effects.sparkle(get_parent(), global_position + Vector3.UP, Tokens.color("honey"), 12)


# --- Işık Sapanı ------------------------------------------------------------

const SEED := "isik_tohumu"
var _shoot_cd := 0.0


## I key / At button: fling a Işık Tohumu forward (needs the sling and seeds).
func shoot() -> void:
	var d := GameState.data
	if not d.has_flag("owned_isik_sapani") or asleep or rolling:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now < _shoot_cd:
		return
	if d.item_count(SEED) <= 0:
		GameState.toast.emit("Işık Tohumun kalmadı. Usta Tıkır'dan alabilirsin", "drop")
		return
	_shoot_cd = now + 0.35
	d.remove_item(SEED)
	Audio.play("swish")
	var fwd := Vector3(sin(model.rotation.y), 0, cos(model.rotation.y))
	LightSeed.fire(get_parent(), global_position + Vector3.UP * 1.0 + fwd * 0.6, fwd, attack_power())


## Facing direction on the ground.
func _facing() -> Vector3:
	return Vector3(sin(model.rotation.y), 0, cos(model.rotation.y))


## Kıvılcım Kılıcı: a bright wave that sweeps 6 m forward and hits along the way.
func _spark_wave() -> void:
	var fwd := _facing()
	var start := global_position + Vector3.UP * 0.6
	var wave := Toon.part(get_parent(), "ellipsoid", Vector3(1.6, 0.5, 0.35), "sky", start + fwd * 0.8, Vector3.ZERO, 1.6, 0.02)
	wave.look_at_from_position(wave.global_position, wave.global_position + fwd, Vector3.UP)
	var hit_ids := {}
	var tw := wave.create_tween()
	tw.tween_method(func(t: float) -> void:
		var p := start + fwd * (0.8 + t * 5.2)
		wave.global_position = p
		for m in get_tree().get_nodes_in_group("hittable"):
			var n := m as Node3D
			if n and not hit_ids.has(n.get_instance_id()) and (n.global_position + Vector3.UP * 0.6).distance_to(p) < 1.2 + float(n.get_meta("hit_radius", 0.5)):
				hit_ids[n.get_instance_id()] = true
				n.hit(attack_power(), p - fwd, 5.0), 0.0, 1.0, 0.35)
	tw.tween_callback(wave.queue_free)


# --- outfit bonuses -----------------------------------------------------------

var _bonus: Dictionary = {}
var _regen_t := 0.0
var _mp_t := 0.0
var _base_mp_t := 0.0
## How far Pırıl drifts to you (Kâşif Şapkası makes it bigger).
var magnet_range := 3.2


func _refresh_bonus() -> void:
	var d := GameState.data
	_bonus = Shop.outfit_bonus(d, Content.items)
	speed = d.speed + float(_bonus.get("speed", 0.0)) + Powers.bonus_speed(d.powers)
	magnet_range = 3.2 + float(_bonus.get("magnet", 0.0))


func _process(delta: float) -> void:
	if asleep:
		return
	var d := GameState.data
	# energy slowly fills up by itself (+1 every 1.5 s); Yıldız Tozu is faster
	if d.mp < d.max_mp:
		_base_mp_t += delta
		if _base_mp_t >= 1.5:
			_base_mp_t = 0.0
			d.restore_mp(1)
	if _bonus.is_empty():
		return
	if _bonus.has("regen") and d.hp < d.max_hp:
		_regen_t += delta
		if _regen_t >= 2.0:
			_regen_t = 0.0
			d.heal(int(_bonus["regen"]))
	if _bonus.has("mp_regen") and d.mp < d.max_mp:
		_mp_t += delta
		if _mp_t >= 1.0:
			_mp_t = 0.0
			d.restore_mp(int(_bonus["mp_regen"]))


# --- level-up powers (O / P keys, power buttons) -------------------------------

var _power_ready: Dictionary = {}


## Seconds until power `id` can be used again (0 = ready).
func power_wait(id: String) -> float:
	return maxf(0.0, float(_power_ready.get(id, 0.0)) - Time.get_ticks_msec() / 1000.0)


func use_power(slot: int) -> void:
	var d := GameState.data
	var list := Powers.actives(d.powers)
	if slot >= list.size() or asleep or rolling or not input_enabled:
		return
	var id: String = list[slot]
	var def: Dictionary = Powers.DEFS[id]
	if power_wait(id) > 0.0:
		return
	if not d.use_mp(int(def["mp"])):
		GameState.toast.emit("Enerjin az. Yıldız Tozu iç!", "drop")
		return
	_power_ready[id] = Time.get_ticks_msec() / 1000.0 + float(def["cd"])
	var n := Powers.numbers(id, Powers.rank(d.powers, id))
	var dmg := maxi(1, roundi(attack_power() * float(n.get("mult", 1.0))))
	if _rig:
		_rig.happy()
	match id:
		"yildiz_yagmuru": _star_rain(int(n["count"]), dmg, float(n["radius"]))
		"gokkusagi_dalgasi": _rainbow_wave(float(n["reach"]), dmg)
		"baloncuk_patlamasi": _bubble_burst(int(n["count"]), dmg)
		"isik_donencesi": _light_orbit(int(n["count"]), dmg, float(n["seconds"]))


func _near_targets(radius: float) -> Array:
	var out := []
	for m in get_tree().get_nodes_in_group("hittable"):
		var n := m as Node3D
		if n and n.global_position.distance_to(global_position) <= radius:
			out.append(n)
	out.sort_custom(func(a: Node3D, b: Node3D) -> bool: return a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position))
	return out


## Yıldız Yağmuru: stars drop on the nearest targets (or around you).
func _star_rain(count: int, dmg: int, radius: float) -> void:
	Audio.play("crystal")
	var targets := _near_targets(radius)
	for i in count:
		var t: Node3D = targets[i % targets.size()] if not targets.is_empty() else null
		var spot := t.global_position if t else global_position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		var star := Effects.sprite(get_parent(), spot + Vector3.UP * 7.0, "star", Color(1.0, 0.92, 0.5), 1.1)
		var tw := star.create_tween()
		tw.tween_interval(i * 0.12)
		tw.tween_property(star, "global_position", spot + Vector3.UP * 0.8, 0.3).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			Effects.ring(get_parent(), spot + Vector3.UP * 0.2, 1.4, Tokens.color("spark-yellow"), 0.3)
			if t and is_instance_valid(t) and t.is_in_group("hittable"):
				t.hit(dmg, spot + Vector3.UP, 3.0)
			star.queue_free())


## Gökkuşağı Dalgası: a fan of colors sweeping forward.
func _rainbow_wave(reach: float, dmg: int) -> void:
	Audio.play("whoosh")
	var fwd := _facing()
	var cols := ["hp", "honey", "spark-yellow", "leaf", "sky", "spark-purple"]
	for i in cols.size():
		var arc := Toon.part(get_parent(), "ring", Vector3(1.0, 0.12, 1.0), cols[i], global_position + Vector3.UP * (0.4 + i * 0.12), Vector3.ZERO, 1.2, 0.0)
		var tw := arc.create_tween().set_parallel()
		tw.tween_property(arc, "scale", Vector3(reach * 2.0, 1.0, reach * 2.0) * (0.75 + i * 0.05), 0.45).set_ease(Tween.EASE_OUT)
		tw.chain().tween_callback(arc.queue_free)
	for n: Node3D in _near_targets(reach + 0.5):
		var to := n.global_position - global_position
		to.y = 0.0
		if to.length() < 0.1 or fwd.dot(to.normalized()) > 0.55:
			n.hit(dmg, global_position, 8.0)


## Baloncuk Patlaması: glowing bubbles in every direction.
func _bubble_burst(count: int, dmg: int) -> void:
	Audio.play("pop")
	for i in count:
		var a := TAU * i / count
		var dir := Vector3(sin(a), 0, cos(a))
		LightSeed.fire(get_parent(), global_position + Vector3.UP * 0.9 + dir * 0.6, dir, dmg, "spark-blue", 6.5, 1.6)


## Işık Dönencesi: purple light balls circle you for a few seconds.
func _light_orbit(count: int, dmg: int, seconds: float) -> void:
	Audio.play("skill")
	var o := LightOrbit.new()
	o.count = count
	o.damage = dmg
	o.seconds = seconds
	add_child(o)


## Quick bar tool slots (5, 6, 7 / tap): hold that tool, or put it away if
## it's already in your paw.
func switch_tool(index: int) -> void:
	var d := GameState.data
	var owned := ToolSlot.owned_tools()
	if index >= owned.size():
		return
	var id: String = owned[index]
	var now_held: bool = d.equipped.get("weapon", "") == id
	Shop.equip(d, "weapon", "" if now_held else id)
	Audio.play("click")
	GameState.toast.emit(("%s kaldırıldı" if now_held else "%s elinde") % Content.items[id]["name"], "star")
