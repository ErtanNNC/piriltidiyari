class_name Gumbur
extends Firfir
## Davulcu Keçi Gümbür (Sezon 2 · Bölüm 4 boss): the goat whose drumming was
## laughed at. He fights to his drum (`GumburPlan`): every beat is exactly
## the warning time, so a "bum" lands one beat after its circle shows. Then
## he stops to catch his breath (hittable). At 0 HP he is sad; Sakinleş =
## "Davulunu dinlemek istiyorum."

signal beat(n: int)

var _drum: Node3D


func _init() -> void:
	hp = GumburPlan.MAX_HP
	attack_color = Color("#d9894a")
	tired_hint = "Gümbür nefesleniyor! Şimdi vur!"
	calm_event = "gumbur"


func _make_model() -> Node3D:
	var root := Node3D.new()
	var imported := ModelImport.load_model("gumbur")
	var head: Node3D
	if imported:
		root.add_child(imported)
		head = Node3D.new()
		head.position = Vector3(0, 2.6, 0.9)
		root.add_child(head)
	else:
		Toon.default_pus = 0.0
		var goat := Node3D.new()
		goat.scale = Vector3.ONE * 1.6
		root.add_child(goat)
		MobModels.goat(goat, false, 1.0, true)
		Toon.default_pus = 1.0
		CharacterRig.attach(goat)
		head = goat.find_child("Head", true, false)
	# angry brows (CrossFace) and teary cheeks (SoftFace)
	var cross := Node3D.new()
	cross.name = "CrossFace"
	head.add_child(cross)
	var soft := Node3D.new()
	soft.name = "SoftFace"
	soft.visible = false
	head.add_child(soft)
	for side: float in [-1.0, 1.0]:
		Toon.part(cross, "box", Vector3(0.22, 0.05, 0.05), "outline", Vector3(0.14 * side, 0.24, 0.36), Vector3(0, 0, -22 * side), 0.0, 0.0)
		Toon.part(soft, "ellipsoid", Vector3(0.08, 0.14, 0.04), "sky", Vector3(0.2 * side, -0.04, 0.38), Vector3.ZERO, 0.6, 0.0)
	MobModels._pus_wisps(cross, 1.0, Color(1, 1, 1), 5, 0.6)
	_drum = root.find_child("Drum", true, false)
	return root


func _loop() -> void:
	while active:
		for bar: String in GumburPlan.bars(phase):
			for i in 4:
				if not active:
					return
				await GameState.wait_dialogue_closed()
				if not active:
					return
				_play_beat(bar[i], i)
				await get_tree().create_timer(GumburPlan.BEAT).timeout
		if not active:
			return
		await _rest()


## One beat: the drum thumps, and a warned circle shows where the NEXT beat
## lands (so every hit comes exactly one beat after its warning).
func _play_beat(mark: String, n: int) -> void:
	beat.emit(n)
	if _drum:
		var tw := _drum.create_tween()
		tw.tween_property(_drum, "scale", Vector3(1.12, 1.12, 0.9), 0.06)
		tw.tween_property(_drum, "scale", Vector3.ONE, 0.18)
	if mark == "-":
		Audio.play("drum", -8.0)
		return
	Audio.play("drum")
	var p := _player()
	if not p:
		return
	var spot := global_position if mark == "o" else Vector3(p.global_position.x, 0, p.global_position.z)
	spot.y = 0.0
	var r := GumburPlan.RING_RADIUS if mark == "o" else GumburPlan.HIT_RADIUS
	Effects.warning(get_parent(), spot, r, Mob.TELEGRAPH)
	_land(spot, r)


func _land(spot: Vector3, r: float) -> void:
	await get_tree().create_timer(Mob.TELEGRAPH).timeout
	if not active:
		return
	Effects.ring(get_parent(), spot + Vector3.UP * 0.3, r, attack_color, 0.35)
	Effects.sparkle(get_parent(), spot + Vector3.UP * 0.6, attack_color, 6)
	var p := _player()
	if p and Vector2(p.global_position.x - spot.x, p.global_position.z - spot.z).length() < r \
			and p.global_position.y < 1.2 and not GameState.in_dialogue:
		p.hurt(GumburPlan.DAMAGE, spot)


func _rest() -> void:
	_busy = true
	tired = true
	add_to_group("hittable")
	var sit := create_tween()
	sit.tween_property(_model, "scale", Vector3(1.1, 0.85, 1.1), 0.25)
	get_tree().call_group("hud", "show_hint", tired_hint, "Nefesleniyor! Şimdi vur!")
	await get_tree().create_timer(GumburPlan.TIRED_TIME).timeout
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
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 3.6, str(damage), Tokens.color("panel@light"))
	hp_changed.emit(hp, GumburPlan.MAX_HP)
	var p := GumburPlan.phase(hp)
	if hp == 0:
		_become_sad()
	elif p != phase:
		phase = p
		phase_changed.emit(phase)
