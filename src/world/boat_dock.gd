class_name BoatDock
extends Interactable
## Season 3: the Kabuk Kayık at an island's little pier. "Bin" lists the
## places the boat can sail to (`ShoreTravel`); you arrive at that island's
## dock (every island scene starts the keeper there).

@export var here := "s3_chapter0"


func _build() -> void:
	action_label = "Bin"
	reach = 2.2
	var wood := Color("#a8794f")
	Toon.part(self, "box", Vector3(2.4, 0.2, 5.0), wood, Vector3(0, 0.1, 0))
	for z: float in [-2.2, 0.0, 2.2]:
		for x: float in [-1.1, 1.1]:
			Toon.part(self, "cylinder", Vector3(0.22, 1.0, 0.22), Color("#7a5236"), Vector3(x, -0.2, z))
	var boat := ModelImport.load_model("kabuk_kayik")
	if boat == null:
		boat = Node3D.new()
		Toon.part(boat, "ellipsoid", Vector3(1.6, 0.7, 2.8), Color("#f4dcc0"), Vector3(0, 0.3, 0))
	boat.scale *= 2.2
	boat.position = Vector3(2.4, -0.25, 0.6)
	boat.rotation.y = 0.3
	add_child(boat)
	var tw := boat.create_tween().set_loops()
	tw.tween_property(boat, "position:y", -0.1, 1.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(boat, "position:y", -0.25, 1.5).set_trans(Tween.TRANS_SINE)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(2.4, 0.4, 5.0)
	c.shape = b
	c.position.y = 0.0
	body.add_child(c)
	add_child(body)
	TravelSign.board(self, "Kabuk Kayık", Vector3(-1.6, 1.5, 2.0), 2.2)
	Toon.part(self, "box", Vector3(0.14, 1.4, 0.14), wood, Vector3(-1.6, 0.7, 1.95))


func use(_by: Node) -> void:
	var d := GameState.data
	var to := ShoreTravel.destinations(d, here)
	if to.is_empty() and not d.has_flag("yan_sise_bitti"):
		GameState.toast.emit("Deniz sisli. Önce buranın İşaret Fişeği'ni yak.", "spark")
		return
	var opts := []
	for id: String in to:
		opts.append({"id": id, "label": ShoreTravel.region(id)})
	# after the season: the race; with every Mesaj Şişesi: Tırıl's garden
	if d.has_flag("sezon3_bitti"):
		opts.append({"id": "s3_regatta", "label": "Gece Regatası"})
	if d.has_flag("yan_sise_bitti"):
		opts.append({"id": "s3_garden", "label": "Mercan Bahçesi"})
	opts.append({"id": "", "label": "Burada kal"})
	var hud := get_tree().get_first_node_in_group("hud") as Hud
	if hud == null:
		return
	var pick: String = await hud.ask("Kabuk Kayık nereye gitsin?", opts)
	if pick == "":
		return
	Audio.play("splash")
	SceneFlow.go_to(pick)
