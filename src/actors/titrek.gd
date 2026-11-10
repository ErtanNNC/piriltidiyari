class_name Titrek
extends CharacterBody3D
## Season 3 mob: a creature caught by the Mavi Titreme. It never attacks: it
## trembles, runs from the keeper and pushes whoever is in its way. A calm,
## steady drum rhythm (`hear_rhythm`, from Hırıl's drum) makes it stop and
## listen; a light (the keeper's ring while it listens, or any lit torch)
## then calms it: it smiles and goes home (to the sea or the sky).

signal calmed

const FLEE_DIST := 5.0
const LISTEN_TIME := 6.0
const HOME_RANGE := 8.0
const HEAR_DIST := 7.0
const HEAR_STREAK := 3

@export var kind := "titrek_yengec"
var state := "scared"   ## scared | listening | calm
var home := Vector3.ZERO
var _model: Node3D
var _listen := 0.0
var _wander := Vector3.ZERO
var _wander_t := 0.0
var _push_cd := 0.0
var _away := Vector3.ZERO
var _note: Label3D


func _ready() -> void:
	add_to_group("titrek")
	add_to_group("rhythm_listener")
	collision_layer = 2
	collision_mask = 1 | 16
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 0.9
	col.shape = cap
	col.position.y = 0.45
	add_child(col)
	_model = ModelImport.load_model(kind)
	if _model == null:
		_model = _primitive()
		CharacterRig.attach(_model)
	add_child(_model)
	_note = Label3D.new()
	_note.text = "♪"
	_note.font_size = 96
	_note.pixel_size = 0.006
	_note.outline_size = 16
	_note.modulate = Tokens.color("sky")
	_note.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_note.position.y = 1.5
	_note.visible = false
	add_child(_note)
	if home == Vector3.ZERO:
		home = global_position


func _primitive() -> Node3D:
	var r := Node3D.new()
	if kind == "urkek_marti":
		Toon.part(r, "ellipsoid", Vector3(0.6, 0.7, 0.7), Color("#f4f4f0"), Vector3(0, 0.45, 0))
		Toon.part(r, "sphere", Vector3(0.42, 0.42, 0.42), Color("#f4f4f0"), Vector3(0, 0.95, 0.05))
		Toon.part(r, "cone", Vector3(0.14, 0.2, 0.14), Color("#ffb347"), Vector3(0, 0.92, 0.3), Vector3(90, 0, 0))
	else:
		Toon.part(r, "ellipsoid", Vector3(0.9, 0.5, 0.7), Color("#e0533a"), Vector3(0, 0.35, 0))
		for s: float in [-1.0, 1.0]:
			Toon.part(r, "sphere", Vector3(0.3, 0.26, 0.26), Color("#e0533a"), Vector3(0.55 * s, 0.5, 0.2))
	Face.add(r, Vector3(0, 0.6 if kind != "urkek_marti" else 1.0, 0.3), Vector3(0.3, 0.25, 0.2))
	return r


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = -0.5
	_push_cd = maxf(_push_cd - delta, 0.0)
	var pl := get_tree().get_first_node_in_group("player") as Player
	var t := Time.get_ticks_msec() / 1000.0
	var move := Vector3.ZERO
	match state:
		"scared":
			_model.position.x = sin(t * 55.0) * 0.035
			var to_pl := Vector3.ZERO
			if pl:
				to_pl = pl.global_position - global_position
				to_pl.y = 0.0
			if LightRing.torch_near(get_tree(), global_position):
				_calm()
			elif pl and to_pl.length() < FLEE_DIST and not GameState.in_dialogue:
				_away = -to_pl.normalized()
				# stay near home: running away bends back toward it
				var back := home - global_position
				back.y = 0.0
				if back.length() > HOME_RANGE * 0.6:
					_away = (_away + back.normalized() * 1.2).normalized()
				move = _away * _speed()
				if to_pl.length() < 1.15 and _push_cd <= 0.0:
					_push_cd = 1.0
					pl.push(to_pl.normalized() * 7.0)
					Audio.play("boing")
			else:
				_wander_t -= delta
				if _wander_t <= 0.0:
					_wander_t = randf_range(0.8, 1.8)
					var target := home + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
					_wander = (target - global_position) * Vector3(1, 0, 1)
					_wander = _wander.normalized() if _wander.length() > 0.3 else Vector3.ZERO
				move = _wander * _speed() * 0.45
		"listening":
			_model.position.x = sin(t * 18.0) * 0.012
			_listen -= delta
			_note.position.y = 1.5 + sin(t * 4.0) * 0.1
			if pl:
				_face(pl.global_position - global_position, delta)
			if LightRing.lit_at(get_tree(), global_position):
				_calm()
			elif _listen <= 0.0:
				state = "scared"
				_note.visible = false
		"calm":
			_model.position.x = 0.0
	if move.length() > 0.05:
		_face(move, delta)
	velocity.x = move.x
	velocity.z = move.z
	move_and_slide()
	if kind == "urkek_marti" and state == "scared" and move.length() > 0.5:
		_model.position.y = absf(sin(t * 9.0)) * 0.35   # nervous flaps and hops
	elif state != "calm":
		_model.position.y = move_toward(_model.position.y, 0.0, delta * 2.0)


func _speed() -> float:
	return 5.0 if kind == "urkek_marti" else 4.4


func _face(dir: Vector3, delta: float) -> void:
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	var want := atan2(dir.x, dir.z)
	_model.rotation.y = lerp_angle(_model.rotation.y, want, minf(delta * 8.0, 1.0))


## Hırıl's drum: a steady rhythm near a frightened one makes it listen.
func hear_rhythm(from: Vector3, streak: int) -> void:
	if state == "calm" or streak < HEAR_STREAK or from.distance_to(global_position) > HEAR_DIST:
		return
	if state == "scared":
		Effects.ring(get_parent(), global_position + Vector3.UP * 0.2, 1.2, Tokens.color("sky"), 0.4)
	state = "listening"
	_listen = LISTEN_TIME
	_note.visible = true


func _calm() -> void:
	if state == "calm":
		return
	state = "calm"
	_note.visible = false
	Audio.play("calm")
	Effects.sparkle(get_parent(), global_position + Vector3.UP, Tokens.color("spark-yellow"), 10)
	var d := GameState.data
	d.add_xp(int(Progression.xp_to_next(d.level) * 0.22))
	d.add_piril(3)
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 1.6, "+3", Tokens.color("spark-yellow"))
	GameState.notify("titrek", kind)
	GameState.notify("titrek", "any")
	calmed.emit()
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return
	# off home: crabs scuttle to the sea, gulls fly up
	var tw := create_tween()
	if kind == "urkek_marti":
		tw.tween_property(self, "global_position", global_position + Vector3(0, 9, -6), 2.2)
	else:
		tw.tween_property(self, "global_position", global_position + Vector3(0, -0.2, -10), 3.0)
	tw.tween_callback(queue_free)
