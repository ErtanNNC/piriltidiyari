class_name MovingPlatform
extends AnimatableBody3D
## A hanging festival lantern platform that sways back and forth.
## The player rides it (sync_to_physics).

@export var travel := Vector3(0, 0, 3.0)
@export var period := 3.0
@export var size := Vector3(2.4, 0.5, 2.4)
@export var accent := "honey"
@export var phase := 0.0

var _origin := Vector3.ZERO
var _t := 0.0


func _ready() -> void:
	sync_to_physics = true
	_origin = position
	_t = phase * period
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	c.shape = b
	add_child(c)
	Toon.part(self, "cylinder", Vector3(size.x, size.y, size.z), Color("#c98d5e"), Vector3.ZERO)
	Toon.part(self, "sphere", Vector3(size.x * 0.75, 0.6, size.z * 0.75), accent, Vector3(0, -0.45, 0), Vector3.ZERO, 1.0, 0.02)
	for s in [-1.0, 1.0]:
		Toon.part(self, "cylinder", Vector3(0.06, 6.0, 0.06), "outline", Vector3(s * size.x * 0.4, 3.2, 0), Vector3.ZERO, 0.0, 0.0)


func _physics_process(delta: float) -> void:
	_t += delta
	position = _origin + travel * sin(_t / period * TAU)
