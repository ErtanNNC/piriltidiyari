class_name Hiril
extends Firfir
## Hırıl (Sezon 2 final boss), big and boiling on the summit of Kükreyen
## Dağ. Faz 1 (`HirilPlan`): lava balls on warned circles, angry ghosts of
## earlier Köpüklüler, then out of steam (hittable). At 0 HP `sad` fires and
## the scene runs Faz 2 (listening); `hear(n)` lets the steam go down step by
## step, `become_calm()` shows the small warm kor child underneath.

var _summons := 0
var _steam: Node3D


func _init() -> void:
	hp = HirilPlan.MAX_HP
	attack_color = Color("#ff6a3a")
	tired_hint = "Hırıl'ın buharı bitti! Şimdi vur!"
	calm_event = "hiril"


func _make_model() -> Node3D:
	var root := Node3D.new()
	var h := HirilModel.build(false)
	h.name = "Angry"
	h.scale = Vector3.ONE * 2.2
	root.add_child(h)
	var cross := Node3D.new()
	cross.name = "CrossFace"
	root.add_child(cross)
	_steam = Node3D.new()
	_steam.name = "Steam"
	cross.add_child(_steam)
	MobModels._pus_wisps(_steam, 3.4, Tokens.color("hp"), 10, 1.0)
	var soft := Node3D.new()
	soft.name = "SoftFace"
	soft.visible = false
	root.add_child(soft)
	return root


func _loop() -> void:
	while active:
		for attack in HirilPlan.cycle(phase):
			if not active:
				return
			await get_tree().create_timer(HirilPlan.rest(phase), false).timeout
			if not active:
				return
			await GameState.wait_dialogue_closed()
			if not active:
				return
			match attack:
				"lava":
					await _lava()
				"summon":
					_summon()
				_:
					await _rest()


## Lava balls: warned circles round the keeper, then warm splashes.
func _lava() -> void:
	_busy = true
	var p := _player()
	var spots: Array[Vector3] = []
	for i in HirilPlan.balls(phase):
		var off := Vector3.ZERO if i == 0 else Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
		spots.append(Vector3(p.global_position.x, 0, p.global_position.z) + off)
	for s in spots:
		Effects.warning(get_parent(), s, HirilPlan.LAVA_RADIUS, Mob.TELEGRAPH)
	var puff := create_tween()
	puff.tween_property(_model, "scale", Vector3(1.08, 1.15, 1.08), Mob.TELEGRAPH * 0.7)
	puff.tween_property(_model, "scale", Vector3.ONE, Mob.TELEGRAPH * 0.3)
	await puff.finished
	Audio.play("stone")
	for s in spots:
		Effects.ring(get_parent(), s + Vector3.UP * 0.3, HirilPlan.LAVA_RADIUS, attack_color, 0.4)
		Effects.sparkle(get_parent(), s + Vector3.UP * 0.6, Color("#ffd27a"), 5)
	for s in spots:
		if Vector2(p.global_position.x - s.x, p.global_position.z - s.z).length() < HirilPlan.LAVA_RADIUS \
				and not GameState.in_dialogue:
			p.hurt(HirilPlan.LAVA_DAMAGE, s)
			break
	_busy = false


## Calls up an angry ghost of an earlier Köpüklü (never more than two awake).
func _summon() -> void:
	var awake := 0
	for m in get_tree().get_nodes_in_group("mob"):
		if m.has_meta("summoned"):
			awake += 1
	if awake >= HirilPlan.MAX_SUMMONED:
		return
	var kind := HirilPlan.summon_kind(_summons)
	_summons += 1
	var at := home + Vector3(randf_range(-6, 6), 0, randf_range(2, 6))
	Effects.warning(get_parent(), at, 1.2, Mob.TELEGRAPH)
	await get_tree().create_timer(Mob.TELEGRAPH, false).timeout
	if not active:
		return
	var m := Mob.spawn(get_parent(), kind, at)
	m.set_meta("summoned", true)


func _rest() -> void:
	_busy = true
	tired = true
	add_to_group("hittable")
	_steam.visible = false
	var sit := create_tween()
	sit.tween_property(_model, "scale", Vector3(1.1, 0.85, 1.1), 0.25)
	get_tree().call_group("hud", "show_hint", tired_hint, "Buharı bitti! Şimdi vur!")
	await get_tree().create_timer(HirilPlan.TIRED_TIME, false).timeout
	if not active:
		return
	get_tree().call_group("hud", "clear_hint")
	tired = false
	_steam.visible = true
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
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 4.0, str(damage), Tokens.color("panel@light"))
	hp_changed.emit(hp, HirilPlan.MAX_HP)
	var p := HirilPlan.phase(hp)
	if hp == 0:
		_faz2()
	elif p != phase:
		phase = p
		phase_changed.emit(phase)


## 0 HP: the fight stops; the summoned ghosts calm down by themselves and
## Hırıl just stands there boiling. Faz 2 (listening) is the scene's.
func _faz2() -> void:
	active = false
	tired = false
	is_sad = true
	remove_from_group("hittable")
	_steam.visible = true
	get_tree().call_group("hud", "clear_hint")
	_model.scale = Vector3.ONE
	for m in get_tree().get_nodes_in_group("mob"):
		if m.has_meta("summoned"):
			Effects.sparkle(get_parent(), m.global_position + Vector3.UP, Tokens.color("spark-green"), 8)
			m.queue_free()
	sad.emit()


## One echo heard: the steam goes down a step.
func hear(heard: int) -> void:
	var left := HirilPlan.steam_left(heard)
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3.ONE * (0.75 + 0.25 * left), 0.5).set_trans(Tween.TRANS_BACK)
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 3.0, Color("#ffd9a8"), 10)


## The last echo: the steam is gone and a small, warm kor child is left.
func become_calm() -> void:
	is_sad = false
	_steam.visible = false
	var angry := _model.get_node("Angry") as Node3D
	var tw := create_tween()
	tw.tween_property(angry, "scale", Vector3.ONE * 0.01, 0.6)
	tw.tween_callback(angry.queue_free)
	var small := HirilModel.build(true)
	small.name = "Calm"
	small.scale = Vector3.ONE * 0.01
	_model.add_child(small)
	_model.scale = Vector3.ONE
	var grow := create_tween()
	grow.tween_interval(0.6)
	grow.tween_property(small, "scale", Vector3.ONE * 1.1, 0.5).set_trans(Tween.TRANS_BACK)
	Effects.ring(get_parent(), global_position + Vector3.UP * 0.3, 4.0, Color("#ffd9a8"), 0.6)
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 1.5, Color("#ffd9a8"), 24)
	GameState.notify("listen", "hiril")
	calmed.emit()


## A restored save: Hırıl is already the small calm kor child.
func show_calm() -> void:
	is_sad = false
	active = false
	_steam.visible = false
	_model.get_node("Angry").queue_free()
	var small := HirilModel.build(true)
	small.name = "Calm"
	small.scale = Vector3.ONE * 1.1
	_model.add_child(small)
