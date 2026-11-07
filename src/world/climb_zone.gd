class_name ClimbZone
extends Area3D
## A vine-covered wall strip. While the player is inside it they climb:
## forward/back moves up/down, jump lets go.

@export var size := Vector3(2.0, 5.0, 0.8)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	c.shape = b
	c.position.y = size.y * 0.5
	add_child(c)
	# vines: leafy stripes and little flowers
	for i in 3:
		var x := -size.x * 0.33 + i * size.x * 0.33
		Toon.part(self, "box", Vector3(0.22, size.y, 0.12), "leaf", Vector3(x, size.y * 0.5, -size.z * 0.5 + 0.06), Vector3.ZERO, 0.0, 0.02)
		for j in int(size.y / 0.9):
			Toon.part(self, "sphere", Vector3(0.36, 0.3, 0.2), Color("#3fae5c"), Vector3(x + (0.15 if j % 2 == 0 else -0.15), 0.4 + j * 0.9, -size.z * 0.5 + 0.12), Vector3.ZERO, 0.0, 0.02)
		Toon.part(self, "sphere", Vector3(0.2, 0.2, 0.1), "berry", Vector3(x, size.y * 0.7, -size.z * 0.5 + 0.2), Vector3.ZERO, 0.4, 0.0)
	body_entered.connect(func(b: Node3D) -> void:
		if b is Player and not (b as Player).rolling:
			(b as Player).climbing = true)
	body_exited.connect(func(b: Node3D) -> void:
		if b is Player:
			(b as Player).climbing = false)
