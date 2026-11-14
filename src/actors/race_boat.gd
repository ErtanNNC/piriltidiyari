class_name RaceBoat
extends Node3D
## Gece Regatası: the Kabuk Kayık you steer. Not a physics body: it moves
## by itself over the flat sea and is pushed out of round obstacles (islets,
## rocks), so it bounces softly and can never get stuck.
##
## Speed = base + a bonus per friend on board ("el ele") and the boat parts
## from Olta's stall: Yıldız Yelken (top speed), Hafif Kürek (turning and
## pick-up), Pruva Feneri (bow light: blue mist hardly slows the boat).

signal bumped

const BASE_SPEED := 9.0
const FRIEND_SPEED := 0.7
const SAIL := 1.25
const RADIUS := 1.7
const FRIEND_IDS := ["tosbi", "tiril", "pati", "bado", "citir", "lumi", "tipis_panda"]
## Seats (boat space, bow = +Z) for the friends; the keeper sits at `KEEPER_SEAT`.
const SEATS := [Vector3(-0.55, 0, 0.75), Vector3(0.55, 0, 0.75), Vector3(-0.6, 0, -0.15),
	Vector3(0.6, 0, -0.15), Vector3(0.0, 0, 1.45)]
const KEEPER_SEAT := Vector3(0, 0.35, -0.95)

var heading := PI           ## bow direction (0 = +Z); starts facing north
var speed := 0.0
var velocity := Vector3.ZERO
var top := BASE_SPEED
var accel := 6.5
var turn := 2.3
var mist_factor := 0.42
var friends := 0
var in_mist := false
## Round things in the sea: Vector3(x, z, radius).
var obstacles: Array[Vector3] = []
## Blue mist patches: Vector3(x, z, radius).
var mists: Array[Vector3] = []
## The sea ends softly here: Vector3(x, z, radius).
var bounds := Vector3(0, 0, 95)

var _hull: Node3D
var _lamp: OmniLight3D
var _t := 0.0
var _wake_t := 0.0
var _spark_t := 0.0
var _bump_cd := 0.0
var _lean := 0.0


## The numbers for a boat with `n` friends and these parts.
static func stats(n: int, sail: bool, oar: bool, lamp: bool) -> Dictionary:
	return {
		"top": (BASE_SPEED + FRIEND_SPEED * clampi(n, 0, 5)) * (SAIL if sail else 1.0),
		"accel": 11.0 if oar else 6.5,
		"turn": 3.5 if oar else 2.3,
		"mist": 0.92 if lamp else 0.42,
		"light": 15.0 if lamp else 7.0,
	}


static func stats_for(d: PlayerData) -> Dictionary:
	return stats(ShoreTravel.pearls(d), d.has_flag("owned_tekne_yelken"), d.has_flag("owned_tekne_kurek"),
		d.has_flag("owned_tekne_fener"))


func _ready() -> void:
	_hull = Node3D.new()
	add_child(_hull)
	var boat := ModelImport.load_model("kabuk_kayik")
	if boat == null:
		boat = Node3D.new()
		Toon.part(boat, "ellipsoid", Vector3(1.6, 0.7, 2.8), Color("#f4dcc0"), Vector3(0, 0.3, 0))
	boat.scale *= 2.6
	boat.position.y = -0.3
	_hull.add_child(boat)
	_lamp = OmniLight3D.new()
	_lamp.light_color = Color(1.0, 0.82, 0.5)
	_lamp.light_energy = 1.6
	_lamp.position = Vector3(0, 1.6, 1.8)
	_hull.add_child(_lamp)
	rotation.y = heading


## Takes the numbers (`stats`) and shows the parts and the friends.
func fit(s: Dictionary, n: int, sail: bool, oar: bool, lamp: bool, skip_id := "") -> void:
	top = s["top"]
	accel = s["accel"]
	turn = s["turn"]
	mist_factor = s["mist"]
	_lamp.omni_range = s["light"]
	_lamp.light_energy = 2.4 if lamp else 1.4
	for c in _hull.get_children():
		if c.has_meta("fit"):
			c.queue_free()
	if lamp:
		_mark(Toon.part(_hull, "sphere", Vector3(0.45, 0.45, 0.45), Color("#ffd98a"), Vector3(0, 1.25, 2.1), Vector3.ZERO, 2.5, 0.0))
		_mark(Toon.part(_hull, "cylinder", Vector3(0.08, 1.0, 0.08), Color("#7a5236"), Vector3(0, 0.7, 2.1)))
	if sail:
		_mark(Toon.part(_hull, "cylinder", Vector3(0.1, 3.2, 0.1), Color("#7a5236"), Vector3(0, 1.9, 0.3)))
		_mark(Toon.part(_hull, "cone", Vector3(1.9, 2.4, 1.9), Color("#ffe9a6"), Vector3(0, 2.2, 0.32), Vector3.ZERO, 0.5, 0.02)).scale = Vector3(0.12, 1.0, 1.0)
	if oar:
		for sx: float in [-1.0, 1.0]:
			_mark(Toon.part(_hull, "cylinder", Vector3(0.08, 1.8, 0.08), Color("#9fd6f2"), Vector3(sx * 1.25, 0.45, -0.3), Vector3(0, 0, sx * 62.0)))
	friends = clampi(n, 0, SEATS.size())
	var seat := 0
	for id: String in FRIEND_IDS:
		if seat >= friends:
			break
		if id == skip_id:
			continue
		var m := ModelImport.load_model(id)
		if m == null:
			m = Node3D.new()
			Toon.part(m, "sphere", Vector3(0.9, 0.9, 0.9), Color("#f2c7a0"), Vector3(0, 0.45, 0))
		var holder := Node3D.new()
		holder.set_meta("fit", true)
		holder.position = SEATS[seat] + Vector3(0, 0.3, 0)
		holder.scale = Vector3.ONE * 0.5
		holder.add_child(m)
		_hull.add_child(holder)
		seat += 1


func _mark(n: Node) -> Node3D:
	n.set_meta("fit", true)
	return n as Node3D


## Where the keeper sits (world space).
func keeper_seat() -> Vector3:
	return _hull.global_transform * KEEPER_SEAT


## One step: `dir` is where the stick points in the world (length 0..1).
func steer(dir: Vector3, delta: float) -> void:
	_t += delta
	_bump_cd = maxf(_bump_cd - delta, 0.0)
	in_mist = false
	var here := Vector2(position.x, position.z)
	for m in mists:
		if here.distance_to(Vector2(m.x, m.y)) < m.z:
			in_mist = true
	var cap := top * (mist_factor if in_mist else 1.0)
	var mag := minf(dir.length(), 1.0)
	var target := 0.0
	var turned := 0.0
	if mag > 0.15:
		var diff := wrapf(atan2(dir.x, dir.z) - heading, -PI, PI)
		turned = clampf(diff, -turn * delta, turn * delta)
		heading += turned
		# still creeps ahead while it turns, so a kid never has to "park"
		target = cap * mag * clampf(cos(diff), 0.3, 1.0)
	if speed > cap:
		speed = move_toward(speed, cap, 14.0 * delta)
	speed = move_toward(speed, target, (accel if target > speed else 4.5) * delta)
	var fwd := Vector3(sin(heading), 0, cos(heading))
	# a little drift: the boat slides a moment before it follows its bow
	velocity = velocity.lerp(fwd * speed, 1.0 - exp(-4.0 * delta))
	position += velocity * delta
	_collide()
	rotation.y = heading
	_lean = lerpf(_lean, clampf(-turned / maxf(delta, 0.001) * 0.09, -0.28, 0.28) * minf(speed / 6.0, 1.0), minf(delta * 6.0, 1.0))
	_hull.rotation.z = _lean + sin(_t * 1.7) * 0.03
	_hull.rotation.x = sin(_t * 1.3) * 0.03 - minf(speed / maxf(top, 1.0), 1.0) * 0.06
	_hull.position.y = sin(_t * 2.1) * 0.06
	_trail(delta, fwd)


func _collide() -> void:
	for o in obstacles:
		var away := Vector3(position.x - o.x, 0, position.z - o.y)
		var gap := o.z + RADIUS
		if away.length() >= gap:
			continue
		var n := away.normalized() if away.length() > 0.01 else Vector3(0, 0, -1)
		position = Vector3(o.x, position.y, o.y) + n * gap
		var into := velocity.dot(n)
		if into < 0.0:
			velocity -= n * into * 1.5   # bounce off, half as fast
			# turn the bow along the rock so holding the stick slides past it
			var side := n.cross(Vector3.UP)
			if side.dot(Vector3(sin(heading), 0, cos(heading))) < 0.0:
				side = -side
			heading = lerp_angle(heading, atan2(side.x, side.z), 0.35)
			if into < -2.0 and _bump_cd <= 0.0:
				_bump_cd = 0.6
				speed *= 0.6
				bumped.emit()
	var out := Vector3(position.x - bounds.x, 0, position.z - bounds.y)
	if out.length() > bounds.z:
		var n2 := out.normalized()
		position -= n2 * (out.length() - bounds.z)
		velocity -= n2 * maxf(velocity.dot(n2), 0.0)


func _trail(delta: float, fwd: Vector3) -> void:
	if speed < 1.5:
		return
	_wake_t -= delta
	if _wake_t <= 0.0:
		_wake_t = 0.09
		var stern := global_position - fwd * 2.0
		stern.y = -0.3
		Effects.dust(get_parent(), stern, Color(0.75, 0.92, 1.0, 0.8), 1, 0.9)
	_spark_t -= delta
	if _spark_t <= 0.0 and speed > top * 0.75:
		_spark_t = 0.4
		Effects.sparkle(get_parent(), global_position - fwd * 2.2 + Vector3(0, 0.2, 0), Color(1.0, 0.92, 0.6), 2 + friends)
