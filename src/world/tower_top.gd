class_name TowerTop
extends RefCounted
## The round top of Fener Kulesi with its low wall, four lanterns and the
## Büyük Kıvılcım on a pedestal. Shared by Sahne 4 (boss) and Sahne 5.


static func build(parent: Node3D, arena_radius := 10.0) -> MeshInstance3D:
	var self_ := parent
	var stone := Color("#cdbfa6")
	# round tower top with a low wall and the crystal on its pedestal
	var floor_body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = arena_radius + 1.0
	cyl.height = 1.0
	c.shape = cyl
	c.position.y = -0.5
	floor_body.add_child(c)
	self_.add_child(floor_body)
	Toon.part(self_, "cylinder", Vector3((arena_radius + 1.0) * 2, 1.0, (arena_radius + 1.0) * 2), stone, Vector3(0, -0.5, 0))
	Toon.part(self_, "cylinder", Vector3(arena_radius * 1.2, 0.06, arena_radius * 1.2), "honey-deep", Vector3(0, 0.01, 0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(self_, "cylinder", Vector3(arena_radius * 1.1, 0.07, arena_radius * 1.1), stone, Vector3(0, 0.02, 0), Vector3.ZERO, 0.0, 0.0)
	for i in 24:
		var a := TAU * i / 24.0
		var at := Vector3(sin(a), 0, cos(a)) * (arena_radius + 0.4)
		Toon.part(self_, "box", Vector3(2.4, 1.0, 0.7), stone.darkened(0.08), at + Vector3.UP * 0.5, Vector3(0, rad_to_deg(a), 0))
		var wall := StaticBody3D.new()
		var wc := CollisionShape3D.new()
		var wb := BoxShape3D.new()
		wb.size = Vector3(2.8, 6.0, 0.8)
		wc.shape = wb
		wall.add_child(wc)
		self_.add_child(wall)
		wall.position = at + Vector3.UP * 3.0
		wall.rotation.y = a
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4
		var post := Prop.new()
		post.kind = "lantern_post"
		post.accent = "honey"
		self_.add_child(post)
		post.position = Vector3(sin(a), 0, cos(a)) * (arena_radius - 1.2)
	# Büyük Kıvılcım
	Toon.part(self_, "cylinder", Vector3(1.6, 1.2, 2.0), stone.darkened(0.1), Vector3(0, 0.6, -2))
	var crystal := Toon.part(self_, "sphere", Vector3(1.4, 2.0, 1.4), "honey", Vector3(0, 2.3, -2), Vector3.ZERO, 2.2, 0.05)
	crystal.name = "BuyukKivilcim"
	var tw := crystal.create_tween().set_loops()
	tw.tween_property(crystal, "position:y", 2.5, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(crystal, "position:y", 2.3, 1.2).set_trans(Tween.TRANS_SINE)
	var l := OmniLight3D.new()
	l.light_color = Tokens.color("honey")
	l.light_energy = 2.0
	l.omni_range = 9.0
	l.position = Vector3(0, 2.5, -2)
	self_.add_child(l)
	var pedestal := StaticBody3D.new()
	var pc := CollisionShape3D.new()
	var ps := CylinderShape3D.new()
	ps.radius = 1.0
	ps.height = 3.0
	pc.shape = ps
	pc.position = Vector3(0, 1.5, -2)
	pedestal.add_child(pc)
	self_.add_child(pedestal)
	return crystal
