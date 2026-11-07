class_name ShipModel
extends RefCounted
## Kaptan Pırpır's sky ship: a round wooden boat under a striped balloon.


static func build() -> Node3D:
	var root := Node3D.new()
	var wood := Color("#c98d5e")
	Toon.part(root, "sphere", Vector3(3.0, 1.6, 6.0), wood, Vector3(0, 0.4, 0))
	Toon.part(root, "box", Vector3(2.6, 0.2, 5.0), Color("#e8c795"), Vector3(0, 1.0, 0), Vector3.ZERO, 0.0, 0.02)
	Toon.part(root, "cone", Vector3(0.6, 1.2, 0.6), wood, Vector3(0, 0.6, 3.2), Vector3(90, 0, 0))
	for x in [-1.1, 1.1]:
		Toon.part(root, "cylinder", Vector3(0.1, 4.0, 0.1), "outline", Vector3(x, 3.0, 0), Vector3.ZERO, 0.0, 0.0)
	var balloon := Node3D.new()
	balloon.name = "Balloon"
	balloon.position.y = 6.2
	root.add_child(balloon)
	Toon.part(balloon, "sphere", Vector3(5.0, 4.0, 6.5), "sky", Vector3.ZERO)
	for z in [-1.6, 0.0, 1.6]:
		Toon.part(balloon, "torus", Vector3(4.6, 0.25, 4.6), "spark-yellow", Vector3(0, 0, z), Vector3(90, 0, 0), 0.0, 0.0)
	Toon.part(root, "cylinder", Vector3(0.12, 2.4, 0.12), "outline", Vector3(0, 2.0, -2.0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(root, "box", Vector3(1.2, 0.8, 0.06), "berry", Vector3(0.6, 2.8, -2.0), Vector3.ZERO, 0.0, 0.02)
	return root
