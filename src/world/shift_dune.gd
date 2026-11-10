class_name ShiftDune
extends AnimatableBody3D
## Season 3 · Değişen Kumlar: a dune that walks. It rests in one gap of a
## dune row (`a`), then slides along the row into the other gap (`b`) and
## back, every `period` seconds: one gap closes, the other opens, so there
## is always a way through. Every shift is announced `Mob.TELEGRAPH` ahead
## with a warning where the dune will arrive, and the dune never moves onto
## anyone: it waits while the keeper (or a Titrek) stands where it is going.

signal shifted(at_b: bool)

const SPEED := 4.5
const MARGIN := 0.75   ## how close to someone the dune will come
const HEAR_DIST := 16.0

var a := Vector3.ZERO
var b := Vector3.ZERO
var size := Vector3(5.0, 5.0, 3.0)   ## collider (tall: nobody hops over)
var period := 8.0
var offset := 0.0   ## seconds already waited at the start (rows out of step)
var col := Color("#edd08c")
var at_b := false
var moving := false
var held := false   ## waiting for someone to step out of the way
var _state := "rest"   ## rest | warn | move
var _t := 0.0


func _ready() -> void:
	sync_to_physics = false
	position = a
	_t = offset
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	c.shape = s
	c.position.y = size.y * 0.5
	add_child(c)
	heap(self, Vector3.ZERO, Vector2(size.x, size.z), col.lightened(0.08), 1.9)


## The look of a dune over a `footprint` (x, z) round `at`: the kum_tepesi
## model stretched over it, or soft sand-coloured mounds.
static func heap(parent: Node3D, at: Vector3, footprint: Vector2, color: Color, height := 1.7) -> void:
	var n := maxi(1, roundi(footprint.x / 4.5))
	var w := footprint.x / n
	for i in n:
		var x := -footprint.x * 0.5 + w * (i + 0.5)
		var h := height * (1.0 if (i + n) % 2 == 0 else 0.84)
		var p := at + Vector3(x, 0, 0)
		if ModelImport.fit_static("kum_tepesi", parent, p + Vector3.UP * h * 0.5, Vector3(w * 1.12, h, footprint.y * 1.1), PI if i % 2 == 1 else 0.0) == null:
			Toon.part(parent, "ellipsoid", Vector3(w * 1.25, h * 2.0, footprint.y * 1.2), color, p + Vector3(0, -0.05, 0))
			Toon.part(parent, "ellipsoid", Vector3(w * 0.6, h * 1.2, footprint.y * 0.8), color.darkened(0.06), p + Vector3(w * 0.22, 0, footprint.y * 0.2))


func target() -> Vector3:
	return a if at_b else b


func _physics_process(delta: float) -> void:
	match _state:
		"rest":
			_t += delta
			if _t < period:
				return
			held = _someone_in(target(), 1.4)
			if held:
				return   # not now: someone is standing in the other gap
			_state = "warn"
			_t = 0.0
			if _keeper_near():
				Effects.warning(get_parent(), target() + Vector3.UP * 0.05, maxf(size.x, size.z) * 0.5, Mob.TELEGRAPH)
		"warn":
			_t += delta
			if _t >= Mob.TELEGRAPH:
				_state = "move"
				moving = true
				if _keeper_near():
					Audio.play("whoosh")
		"move":
			var next := position.move_toward(target(), SPEED * delta)
			held = _someone_in(next, MARGIN)
			if held:
				return
			position = next
			if position.distance_to(target()) < 0.01:
				position = target()
				at_b = not at_b
				moving = false
				_state = "rest"
				_t = 0.0
				if _keeper_near():
					Effects.ring(get_parent(), position + Vector3.UP * 0.3, size.x * 0.6, col, 0.4)
				shifted.emit(at_b)


## Is the keeper or a Titrek inside the dune's box at `at` (+ `grow`)?
func _someone_in(at: Vector3, grow: float) -> bool:
	var base := (get_parent() as Node3D).global_transform * at
	var who := get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("titrek")
	for n: Node in who:
		var p := (n as Node3D).global_position - base
		if absf(p.x) < size.x * 0.5 + grow and absf(p.z) < size.z * 0.5 + grow:
			return true
	return false


## Far-away dunes shift quietly (no warning sound from across the island;
## the keeper cannot get there within the warning time anyway).
func _keeper_near() -> bool:
	var p := get_tree().get_first_node_in_group("player") as Node3D
	return p != null and p.global_position.distance_to(global_position) < HEAR_DIST + position.distance_to(target())
