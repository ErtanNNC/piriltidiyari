class_name ShoreBoss
extends Firfir
## Season 3's island keepers (Hortlak Çarşaf, Mürekkep, Pamuk, Bikbik,
## Tombik, Tırıl): one actor, the moves and phases come from `ShorePlan`
## by `boss_id`. They are scared, not angry: between moves they get out of
## breath (hittable); at 0 HP they tremble in group "dazed" and a hand
## (Sakinleş) ends the fight (event "breathe"/`boss_id`).

var boss_id := "carsaf"
var max_hp := 300
var arena := 8.0


func setup(id: String) -> void:
	boss_id = id
	var def: Dictionary = ShorePlan.BOSSES[id]
	max_hp = ShorePlan.max_hp(id)
	hp = max_hp
	attack_color = Color(String(def["color"]))
	tired_hint = "Soluk soluğa kaldı! Şimdi vur!"
	calm_event = id


func _make_model() -> Node3D:
	var def: Dictionary = ShorePlan.BOSSES[boss_id]
	var real := ModelImport.boss(String(def["model"]), ["CrossFace", "SoftFace", "Tail"])
	if real:
		return real
	# placeholder: a big round body with a worried face
	var root := Node3D.new()
	Toon.default_pus = 0.0
	Toon.part(root, "ellipsoid", Vector3(2.2, 2.4, 2.0), attack_color, Vector3(0, 1.2, 0))
	Face.add(root, Vector3(0, 1.5, 0.85), Vector3(0.7, 0.6, 0.3))
	for n: String in ["CrossFace", "SoftFace", "Tail"]:
		var e := Node3D.new()
		e.name = n
		root.add_child(e)
	Toon.default_pus = 1.0
	CharacterRig.attach(root)
	return root


func _process(delta: float) -> void:
	super._process(delta)
	if is_sad:
		# scared stiff: a little tremble until someone holds out a hand
		_model.position.x = sin(_t * 46.0) * 0.04


func _loop() -> void:
	while active:
		for attack: String in ShorePlan.cycle(boss_id, phase):
			if not active:
				return
			await get_tree().create_timer(ShorePlan.rest(phase)).timeout
			if not active:
				return
			await GameState.wait_dialogue_closed()
			if not active:
				return
			match attack:
				"circles":
					await _leaves()
				"dash":
					await _dash()
				"ring":
					await _ring()
				"gust":
					await _gust()
				"ink":
					await _ink()
				"thunder":
					await _thunder()
				"burrow":
					await _burrow()
				_:
					await _rest()


## A wide ring round the boss (a frightened shout, a wing clap): get away.
func _ring() -> void:
	_busy = true
	var at := global_position
	Effects.warning(get_parent(), at, ShorePlan.RING_RADIUS, Mob.TELEGRAPH)
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(1.2, 0.8, 1.2), Mob.TELEGRAPH)
	await tw.finished
	_model.scale = Vector3.ONE
	Effects.ring(get_parent(), at + Vector3.UP * 0.3, ShorePlan.RING_RADIUS, attack_color, 0.4)
	Audio.play("whoosh")
	var p := _player()
	if p and Vector2(p.global_position.x - at.x, p.global_position.z - at.z).length() < ShorePlan.RING_RADIUS:
		p.hurt(ShorePlan.RING_DAMAGE, at)
	_busy = false


## Wind from frightened wings: pushes the keeper away for a while. No
## damage; rolling and standing behind something still work.
func _gust() -> void:
	_busy = true
	var p := _player()
	var dir := (p.global_position - global_position) * Vector3(1, 0, 1)
	dir = dir.normalized() if dir.length() > 0.1 else Vector3.BACK
	for k in 4:
		Effects.ring(get_parent(), global_position + dir * (2.0 + k * 2.0) + Vector3.UP * 1.0, 1.2, Color(1, 1, 1, 0.7), Mob.TELEGRAPH)
	_model.rotation.y = atan2(dir.x, dir.z)
	get_tree().call_group("hud", "show_hint", "Rüzgâr geliyor! Karşı yürü ya da yuvarlan.", "Rüzgâr geliyor!")
	await get_tree().create_timer(Mob.TELEGRAPH).timeout
	Audio.play("wind")
	var t := 0.0
	while t < ShorePlan.GUST_TIME and active:
		p.wind = dir * ShorePlan.GUST_PUSH
		if randf() < 0.3:
			Effects.sparkle(get_parent(), global_position + dir * randf_range(1, 8) + Vector3(randf_range(-2, 2), 1.0, randf_range(-2, 2)), Color(1, 1, 1), 2)
		await get_tree().process_frame
		t += get_process_delta_time()
	p.wind = Vector3.ZERO
	get_tree().call_group("hud", "clear_hint")
	_busy = false


## Dark puddles (ink, shadows of fear) on warned circles: they hurt nobody,
## but standing in one fills the Titreme barı fast.
func _ink() -> void:
	_busy = true
	var p := _player()
	var spots: Array[Vector3] = []
	for i in ShorePlan.count(phase):
		var off := Vector3.ZERO if i == 0 else Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
		spots.append(Vector3(p.global_position.x, global_position.y, p.global_position.z) + off)
	for s in spots:
		Effects.warning(get_parent(), s, 2.2, Mob.TELEGRAPH)
	await get_tree().create_timer(Mob.TELEGRAPH).timeout
	Audio.play("splash")
	for s in spots:
		InkPuddle.spawn(get_parent(), s, 2.2, ShorePlan.INK_TIME)
	_busy = false


## Four strikes on the beat: each lands one beat after its warning, where
## the keeper stood. Keep moving between the beats.
func _thunder() -> void:
	_busy = true
	var p := _player()
	for i in 4:
		if not active:
			break
		var s := Vector3(p.global_position.x, global_position.y, p.global_position.z)
		Effects.warning(get_parent(), s, FirfirPlan.LEAF_RADIUS, ShorePlan.BEAT)
		_strike_later(s)
		await get_tree().create_timer(ShorePlan.BEAT).timeout
	await get_tree().create_timer(ShorePlan.BEAT).timeout
	_busy = false


func _strike_later(s: Vector3) -> void:
	await get_tree().create_timer(ShorePlan.BEAT).timeout
	if not is_inside_tree():
		return
	Audio.play("drum")
	Effects.ring(get_parent(), s + Vector3.UP * 0.3, FirfirPlan.LEAF_RADIUS, Color("#fff1b0"), 0.3)
	Effects.sparkle(get_parent(), s + Vector3.UP * 1.0, Color("#fff1b0"), 6)
	var p := _player()
	if p and active and Vector2(p.global_position.x - s.x, p.global_position.z - s.z).length() < FirfirPlan.LEAF_RADIUS:
		p.hurt(ShorePlan.CIRCLE_DAMAGE, s)


## Hides (in the sand, in its shell) and pops up under a warned circle.
func _burrow() -> void:
	_busy = true
	var p := _player()
	var down := create_tween()
	down.tween_property(_model, "scale", Vector3(1.0, 0.05, 1.0), 0.3)
	await down.finished
	var s := Vector3(p.global_position.x, global_position.y, p.global_position.z)
	s.x = clampf(s.x, home.x - arena, home.x + arena)
	s.z = clampf(s.z, home.z - arena, home.z + arena)
	global_position = s
	Effects.warning(get_parent(), s, ShorePlan.BURROW_RADIUS, Mob.TELEGRAPH)
	await get_tree().create_timer(Mob.TELEGRAPH).timeout
	var up := create_tween()
	up.tween_property(_model, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Effects.ring(get_parent(), s + Vector3.UP * 0.3, ShorePlan.BURROW_RADIUS, attack_color, 0.35)
	if Vector2(p.global_position.x - s.x, p.global_position.z - s.z).length() < ShorePlan.BURROW_RADIUS:
		p.hurt(ShorePlan.RING_DAMAGE, s)
	_busy = false


func hit(damage: int, _from: Vector3, _push: float) -> void:
	damage = Progression.boss_damage(damage, GameState.data.power)
	Effects.hit(self, true)
	if not tired or not active:
		return
	hp = maxi(hp - damage, 0)
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 3.2, str(damage), Tokens.color("panel@light"))
	hp_changed.emit(hp, max_hp)
	var p := ShorePlan.phase(hp, max_hp)
	if hp == 0:
		_become_sad()
	elif p != phase:
		phase = p
		phase_changed.emit(phase)


## Reload after the fight: calm from the start.
func set_calm() -> void:
	active = false
	is_sad = false
	_cross.visible = false
	_soft.visible = true
