class_name PropModel
extends RefCounted
## Real 3D models for world props (houses, trees, lanterns...). Call
## `PropModel.swap(node, id, keep)` after a prop built its primitive look:
## if `assets/models/<id>.glb` exists, the primitive meshes are taken away
## (colliders, particles, lights and the nodes in `keep` stay) and the model
## is put in their place, scaled to the same height and centered on the same
## footprint. No rig (props do not breathe). Returns the model or null.
## `roof`: recolors the json "fur" hue to this color (house roofs, well roofs).

static func swap(node: Node3D, id: String, keep: Array = [], roof: Variant = null) -> Node3D:
	if ModelImport.path_for(id) == "":
		return null
	var box := _visual_bounds(node, keep)
	var model := ModelImport.load_static(id)
	if model == null or box.size.y < 0.01:
		return null
	_strip(node, node, keep)
	var mb := ModelImport._bounds(model, Transform3D.IDENTITY)
	if mb.size.y > 0.001:
		var s := box.size.y / mb.size.y
		model.scale = Vector3.ONE * s
		var c := box.get_center()
		model.position = Vector3(c.x - mb.get_center().x * s, box.position.y - mb.position.y * s, c.z - mb.get_center().z * s)
	node.add_child(model)
	var own := String(ModelImport._options(id).get("fur", ""))
	if roof != null and own != "":
		for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			for i in mi.get_surface_override_material_count():
				var m := mi.get_surface_override_material(i) as ShaderMaterial
				if m:
					m.set_shader_parameter("fur_on", 1.0)
					m.set_shader_parameter("fur_from", Color(own))
					m.set_shader_parameter("fur_to", roof)
	return model


static func _kept(n: Node, keep: Array) -> bool:
	for k: Node in keep:
		if is_instance_valid(k) and (n == k or k.is_ancestor_of(n) or n.is_ancestor_of(k)):
			return true
	return false


static func _visual_bounds(node: Node3D, keep: Array) -> AABB:
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if _kept(mi, keep) or not mi.visible:
			continue
		var t := Transform3D.IDENTITY
		var n: Node = mi
		while n != null and n != node:
			if n is Node3D:
				t = (n as Node3D).transform * t
			n = n.get_parent()
		var b := t * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


## Frees the primitive meshes and the empty pivots they leave behind.
static func _strip(top: Node3D, n: Node, keep: Array) -> void:
	for c in n.get_children():
		if _kept(c, keep) or c is CollisionObject3D or c is GPUParticles3D or c is CPUParticles3D or c is Light3D:
			continue
		if c is MeshInstance3D:
			c.free()
			continue
		_strip(top, c, keep)
		if c is Node3D and c.get_class() == "Node3D" and c.get_child_count() == 0 and c.get_script() == null:
			c.free()
