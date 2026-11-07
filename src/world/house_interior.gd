extends ChapterBase
## Inside a village house (SceneFlow.house_id):
##   dukkan – Terzi Dikiş (outfits) and Usta Tıkır (tools, Işık Sapanı, seeds)
##   bekci  – Bekçi Evi: the magic mirror changes your keeper, the wardrobe
##            changes outfit and tool; the four keepers wait on pedestals.
## Walk out through the door to go back to the village.

const W := 6.0       # half width of the room
const D := 4.5       # half depth
const WALL := Color("#f6e3c4")
const WOOD := Color("#a86b45")
const FLOOR := Color("#d9a877")

var _id := "dukkan"


class Spot extends Interactable:
	var on_use: Callable

	func use(by: Node) -> void:
		on_use.call(by)


func _ready() -> void:
	_id = SceneFlow.house_id
	Pus.set_amount(0.0)
	WorldLook.add(self, "ev")
	_room()
	if _id == "bekci":
		_keeper_house()
	else:
		_shop()
	_player.global_position = Vector3(0, 0.05, D - 1.6)
	_player.respawn_point = _player.global_position
	_player.model.rotation.y = PI
	var cam: FollowCamera = $Camera
	# keep the whole room in view: look between the keeper and the back wall
	cam.distance = 12.5
	cam.pitch_degrees = 58.0
	cam.anchor = Vector3(0, 0.5, -1.6)
	cam.anchor_weight = 0.6
	var out := TriggerArea.new()
	out.area_id = "ev_cikis"
	out.radius = 0.9
	out.position = Vector3(0, 0, D + 1.4)
	add_child(out)
	out.reached.connect(_leave)
	await get_tree().create_timer(0.6).timeout
	_hud.show_hint("Kapıdan çıkınca köye dönersin", "Kapıdan çıkınca köye dönersin")
	if DevTools.demo != "":
		_run_demo(DevTools.demo)


func _leave() -> void:
	if SceneFlow.busy:
		return
	Audio.play("door")
	SceneFlow.go_to("chapter0", true, false)


# --- the room --------------------------------------------------------------

func _room() -> void:
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	WorldLook.block(lv, Vector3(0, -0.5, 0.6), Vector3(W * 2, 1.0, D * 2 + 3.0), FLOOR, 0.0)
	# floor boards
	for i in 9:
		Toon.part(lv, "box", Vector3(W * 2 - 0.1, 0.02, 0.04), WOOD, Vector3(0, 0.005, -D + 0.5 + i * 1.0), Vector3.ZERO, 0.0, 0.0)
	# back and side walls; the front wall is low so the camera sees in
	WorldLook.block(lv, Vector3(0, 1.75, -D - 0.25), Vector3(W * 2 + 1.0, 3.5, 0.5), WALL)
	for sd: float in [-1.0, 1.0]:
		WorldLook.block(lv, Vector3(sd * (W + 0.25), 1.75, 0), Vector3(0.5, 3.5, D * 2), WALL)
		WorldLook.block(lv, Vector3(sd * (W + 1.0) * 0.5 + sd * 0.5, 0.35, D + 0.25), Vector3(W - 1.0, 0.7, 0.5), WALL)
		_invisible_wall(lv, Vector3(sd * (W + 1.0) * 0.5 + sd * 0.5, 2.0, D + 0.25), Vector3(W - 1.0, 4.0, 0.5))
		# a skirting board and a window with curtains on the back wall
		Toon.part(lv, "box", Vector3(0.1, 0.25, D * 2), WOOD, Vector3(sd * W, 0.12, 0), Vector3.ZERO, 0.0, 0.0)
		Toon.part(lv, "box", Vector3(1.4, 1.1, 0.06), Color("#bfe4ff"), Vector3(sd * 3.6, 2.0, -D + 0.02), Vector3.ZERO, 0.6, 0.02)
		Toon.part(lv, "box", Vector3(0.06, 1.1, 0.08), WOOD, Vector3(sd * 3.6, 2.0, -D + 0.05), Vector3.ZERO, 0.0, 0.0)
		for c: float in [-1.0, 1.0]:
			Toon.part(lv, "box", Vector3(0.35, 1.4, 0.06), "berry", Vector3(sd * 3.6 + c * 0.85, 1.95, -D + 0.08), Vector3.ZERO, 0.0, 0.015)
	# side walls block the corridor outside the door
	for sd: float in [-1.0, 1.0]:
		_invisible_wall(lv, Vector3(sd * 1.5, 2.0, D + 1.6), Vector3(0.4, 4.0, 2.6))
	Toon.part(lv, "box", Vector3(W * 2, 0.25, 0.1), WOOD, Vector3(0, 0.12, -D), Vector3.ZERO, 0.0, 0.0)
	# door frame and a welcome mat
	for sd: float in [-1.0, 1.0]:
		Toon.part(lv, "box", Vector3(0.25, 2.4, 0.3), WOOD, Vector3(sd * 1.1, 1.2, D + 0.25))
	Toon.part(lv, "box", Vector3(2.45, 0.25, 0.3), WOOD, Vector3(0, 2.4, D + 0.25))
	Toon.part(lv, "box", Vector3(1.8, 0.03, 1.0), "berry", Vector3(0, 0.015, D + 1.1), Vector3.ZERO, 0.0, 0.0)
	Toon.part(lv, "cylinder", Vector3(4.2, 0.03, 3.0), "sky", Vector3(0, 0.015, 0.6), Vector3.ZERO, 0.0, 0.0)
	Toon.part(lv, "ring", Vector3(4.2, 0.2, 3.0), "honey", Vector3(0, 0.02, 0.6), Vector3.ZERO, 0.0, 0.0)
	# warm lamps
	for x in [-3.0, 3.0]:
		var l := OmniLight3D.new()
		l.light_color = Color("#ffd9a0")
		l.light_energy = 1.4
		l.omni_range = 7.0
		l.position = Vector3(x, 2.8, -1.0)
		add_child(l)
		Toon.part(lv, "sphere", Vector3(0.4, 0.4, 0.4), "honey", Vector3(x, 3.3, -D + 0.35), Vector3.ZERO, 1.4, 0.02)


func _invisible_wall(parent: Node3D, center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	c.shape = b
	body.add_child(c)
	parent.add_child(body)
	body.position = center


func _spot(at: Vector3, label: String, cb: Callable) -> Spot:
	var s := Spot.new()
	s.action_label = label
	s.reach = 1.3
	s.on_use = cb
	s.position = at
	$Level.add_child(s)
	return s


# --- Dükkân ----------------------------------------------------------------

func _shop() -> void:
	var lv: Node3D = $Level
	for sd: float in [-1.0, 1.0]:
		# counter
		WorldLook.block(lv, Vector3(sd * 3.0, 0.5, -1.7), Vector3(3.0, 1.0, 0.8), WOOD)
		Toon.part(lv, "box", Vector3(3.2, 0.1, 1.0), Color("#c98d5e"), Vector3(sd * 3.0, 1.03, -1.7))
		TravelSign.board(lv, "Kıyafetler" if sd < 0 else "Aletler", Vector3(sd * 3.0, 0.62, -1.24), 2.4, 0.55)
		# shelves on the back wall
		for k in 2:
			Toon.part(lv, "box", Vector3(3.0, 0.1, 0.5), WOOD, Vector3(sd * 3.0, 1.0 + k * 0.9, -D + 0.3))
	npc(lv, "dikis", "spider", Vector3(-3.0, 0, -2.8), 0)
	npc(lv, "tikir", "frog", Vector3(3.0, 0, -2.8), 0)
	# goods on display
	var outfits := ["cicek_taci", "kasif_sapkasi", "minik_migfer"]
	for i in outfits.size():
		var p := KeeperModels.outfit_piece(outfits[i])
		p.position = Vector3(-4.0 + i * 1.0, 1.1, -D + 0.32)
		lv.add_child(p)
	var cape := KeeperModels.outfit_piece("yildiz_pelerini")
	cape.position = Vector3(-5.1, 1.4, -1.0)
	cape.rotation_degrees.y = 90
	lv.add_child(cape)
	Toon.part(lv, "cylinder", Vector3(0.08, 1.4, 0.08), WOOD, Vector3(-5.1, 0.7, -1.0))
	var tools := ["isik_degnegi", "yildiz_asasi", "kivilcim_kilici", "isik_sapani"]
	for i in tools.size():
		var t := KeeperModels.tool_piece(tools[i])
		t.position = Vector3(1.9 + i * 0.75, 1.95, -D + 0.32)
		t.rotation_degrees.z = 12
		lv.add_child(t)
	for i in 3:
		Toon.part(lv, "sphere", Vector3(0.18, 0.18, 0.18), "spark-yellow", Vector3(2.4 + i * 0.25, 1.15, -1.55), Vector3.ZERO, 1.2, 0.015)
	Toon.part(lv, "cylinder", Vector3(0.5, 0.3, 0.5), WOOD, Vector3(2.6, 1.2, -1.7))


# --- Bekçi Evi -------------------------------------------------------------

func _keeper_house() -> void:
	var lv: Node3D = $Level
	# the magic mirror in the middle of the back wall
	Toon.part(lv, "ellipsoid", Vector3(1.7, 2.4, 0.2), "honey-deep", Vector3(0, 1.6, -D + 0.15))
	Toon.part(lv, "ellipsoid", Vector3(1.35, 2.05, 0.2), Color("#d9ecff"), Vector3(0, 1.6, -D + 0.22), Vector3.ZERO, 0.8, 0.0)
	Toon.part(lv, "sphere", Vector3(0.3, 0.3, 0.3), "honey", Vector3(0, 2.95, -D + 0.25), Vector3.ZERO, 1.2, 0.02)
	_spot(Vector3(0, 0, -D + 1.1), "Bekçini değiştir", func(_by: Node) -> void: _open_mirror())
	TravelSign.board(lv, "Sihirli Ayna", Vector3(0, 0.5, -D + 0.75), 2.0, 0.5)
	# the wardrobe on the left
	WorldLook.block(lv, Vector3(-W + 0.6, 1.2, -1.5), Vector3(1.0, 2.4, 2.0), Color("#c98d5e"))
	Toon.part(lv, "box", Vector3(0.05, 2.0, 0.04), WOOD, Vector3(-W + 1.12, 1.2, -1.5), Vector3.ZERO, 0.0, 0.0)
	for z in [-1.7, -1.3]:
		Toon.part(lv, "sphere", Vector3(0.1, 0.1, 0.1), "honey", Vector3(-W + 1.14, 1.2, z), Vector3.ZERO, 0.4, 0.015)
	_spot(Vector3(-W + 1.8, 0, -1.5), "Dolap", func(_by: Node) -> void: _open_wardrobe())
	TravelSign.board(lv, "Dolap", Vector3(-W + 1.16, 2.65, -1.5), 1.2, 0.45).rotation_degrees.y = 90
	# the four keepers on pedestals on the right, with their names
	var ids := ["pati", "bado", "citir", "lumi"]
	for i in ids.size():
		var at := Vector3(2.4 + (i % 2) * 2.0, 0, -2.6 + int(i / 2) * 2.2)
		WorldLook.block(lv, at + Vector3(0, 0.25, 0), Vector3(1.3, 0.5, 1.3), Color("#e8d8c0"))
		var m := KeeperModels.build(ids[i], {"variant": 0})
		m.position = at + Vector3(0, 0.5, 0)
		m.scale = Vector3.ONE * 0.7
		lv.add_child(m)
		var name_l := Label3D.new()
		name_l.text = String(Content.keepers[ids[i]]["name"])
		name_l.font = Tokens.font_for("text-heading")
		name_l.font_size = 64
		name_l.pixel_size = 0.006
		name_l.outline_size = 14
		name_l.modulate = Tokens.color("panel@light")
		name_l.outline_modulate = Tokens.color("outline")
		name_l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		name_l.position = at + Vector3(0, 2.1, 0)
		lv.add_child(name_l)
	# a cosy bed and a lamp table
	WorldLook.block(lv, Vector3(-W + 1.3, 0.35, 2.4), Vector3(2.0, 0.7, 1.4), Color("#c98d5e"))
	Toon.part(lv, "box", Vector3(1.9, 0.2, 1.3), "sky", Vector3(-W + 1.3, 0.8, 2.4))
	Toon.part(lv, "ellipsoid", Vector3(0.6, 0.25, 0.9), Color.WHITE, Vector3(-W + 0.6, 0.98, 2.4))


func _open_mirror() -> void:
	var sel := KeeperSelect.new()
	_hud.cinematic(true)
	_player.input_enabled = false
	GameState.in_dialogue = true
	_hud.add_child(sel)
	sel.select(GameState.data.character_id if GameState.data.character_id in KeeperSelect.ORDER else "pati")
	var back := UiKit.button("Vazgeç", false)
	back.custom_minimum_size = Vector2(160, 56)
	back.position = Vector2(Tokens.px("space-6"), Tokens.px("space-6"))
	sel.add_child(back)
	var finish := func() -> void:
		sel.queue_free()
		_hud.cinematic(false)
		_player.input_enabled = true
		GameState.in_dialogue = false
	back.pressed.connect(finish)
	sel.chosen.connect(func(id: String, look: Dictionary, display_name: String) -> void:
		var d := GameState.data
		d.switch_keeper(id, Content.keepers[id]["stats"], look, display_name, Content.items)
		SaveGame.write(d)
		finish.call()
		Audio.play("levelup")
		GameState.toast.emit("Artık %s ile oynuyorsun!" % display_name, "star"))


func _open_wardrobe() -> void:
	var w := WardrobePanel.new()
	_player.input_enabled = false
	GameState.in_dialogue = true
	_hud.add_child(w)
	w.closed.connect(func() -> void:
		_player.input_enabled = true
		GameState.in_dialogue = false
		SaveGame.write(GameState.data))


func _run_demo(which: String) -> void:
	match which:
		"mirror":
			_open_mirror()
		"wardrobe":
			_open_wardrobe()
		"shopping":
			# buy a hat, a staff, the sling and seeds, then fling a seed
			var d := GameState.data
			d.add_piril(600)
			for spec in [["kasif_sapkasi", 60], ["yildiz_asasi", 150], ["isik_sapani", 80], ["isik_tohumu", 15]]:
				Shop.buy(d, Content.items[spec[0]], spec[0], spec[1], spec[0] != "isik_tohumu")
			await get_tree().create_timer(0.4).timeout
			_player.shoot()
			await get_tree().create_timer(0.2).timeout
			print("SHOP outfit=%s weapon=%s seeds=%d power=%d attack=%d" % [d.equipped["outfit"], d.equipped["weapon"],
				d.item_count("isik_tohumu"), d.power, _player.attack_power()])
			if DisplayServer.get_name() == "headless":
				get_tree().quit()
		"switch":
			var d := GameState.data
			var lv := d.level
			d.switch_keeper("lumi", Content.keepers["lumi"]["stats"], {"variant": 1}, "Lumi", Content.items)
			await get_tree().create_timer(0.3).timeout
			print("SWITCH id=%s level=%d same_level=%s model_ok=%s" % [d.character_id, d.level, d.level == lv, _player.model != null])
			if DisplayServer.get_name() == "headless":
				get_tree().quit()
		"leave":
			# as if coming in from the shop door, then walking back out
			SceneFlow.return_point = Vector3(11, 0.05, -3.8)
			_player.global_position = Vector3(0, 0.05, D + 1.3)
