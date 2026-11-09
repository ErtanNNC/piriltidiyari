extends Node
## Dev only: prints an ASCII height map of the loaded scene (--probe).
func _ready() -> void:
	await get_tree().create_timer(4.0).timeout
	var root := get_tree().current_scene as Node3D
	var space := root.get_world_3d().direct_space_state
	var marks := {}
	for n in root.find_children("*", "Npc", true, false):
		marks[Vector2i(roundi((n as Node3D).global_position.x / 2.0), roundi((n as Node3D).global_position.z / 2.0))] = "N"
	for n in root.find_children("*", "Mob", true, false):
		marks[Vector2i(roundi((n as Node3D).global_position.x / 2.0), roundi((n as Node3D).global_position.z / 2.0))] = "m"
	var p := root.get_node("Player") as Node3D
	marks[Vector2i(roundi(p.global_position.x / 2.0), roundi(p.global_position.z / 2.0))] = "P"
	print("PROBE %s player=%s" % [root.name, p.global_position])
	for c in root.find_children("*", "CollisionShape3D", true, false):
		var cs := c as CollisionShape3D
		if cs.shape is WorldBoundaryShape3D:
			var pl: Plane = (cs.shape as WorldBoundaryShape3D).plane
			print("WALL n=%s at=%s" % [cs.global_transform.basis * pl.normal, cs.global_transform * (pl.normal * pl.d)])
	var line := "      "
	for x in range(-35, 36):
		line += str(absi(x) % 10)
	print(line)
	for z in range(-40, 36):
		line = "%5d " % (z * 2)
		for x in range(-35, 36):
			var k := Vector2i(x, z)
			if marks.has(k):
				line += marks[k]
				continue
			var q := PhysicsRayQueryParameters3D.create(Vector3(x * 2.0, 40, z * 2.0), Vector3(x * 2.0, -10, z * 2.0))
			q.collide_with_areas = true
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				line += " "
			elif hit["collider"] is Area3D:
				line += "~"
			else:
				var y: float = hit["position"].y
				line += "#" if y > 9.5 else (str(int(floor(y))) if y >= 0 else "-")
		print(line)
	get_tree().quit()
