class_name S3Beach
extends ChapterBase
## Season 3 prologue: the moonlit beach below Gökkuşağı Köyü, shared by
## Sahne 1 (Kumsalda Davul Gecesi) and Sahne 2 (Mavi Titreme).
##
## Layout: sand z −11..19, x −24..24; the sea beyond z −11 (an invisible
## wall at the waterline); the campfire in the middle at (0, 0, 2).

const SAND := Color("#c7ad7c")
const SAND_WET := Color("#a8906a")
const FIRE := Vector3(0, 0, 2)
const SHORE_Z := -11.0
const CASTLES := [Vector3(-12, 0, -6), Vector3(12, 0, 5), Vector3(-1.5, 0, -8.0)]
const TORCHES := [Vector3(-7, 0, -4), Vector3(8, 0, -3), Vector3(-15, 0, 6)]

var _npcs := {}


func _build_beach() -> Node3D:
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	WorldLook.block(lv, Vector3(0, -0.5, 4), Vector3(48, 1, 30), SAND, 0.0)
	Toon.part(lv, "box", Vector3(48, 0.04, 2.4), SAND_WET, Vector3(0, 0.01, SHORE_Z + 1.2), Vector3.ZERO, 0.0, 0.0)
	# the sea: a wide night water plane, and the waterline nobody walks past
	var sea := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(140, 70)
	plane.subdivide_width = 40
	plane.subdivide_depth = 20
	sea.mesh = plane
	sea.position = Vector3(0, -0.12, SHORE_Z - 35)
	WorldLook.water(sea, "sea_night")
	lv.add_child(sea)
	var wall := StaticBody3D.new()
	var wc := CollisionShape3D.new()
	var wb := BoxShape3D.new()
	wb.size = Vector3(60, 6, 1)
	wc.shape = wb
	wall.add_child(wc)
	wall.position = Vector3(0, 3, SHORE_Z - 0.4)
	lv.add_child(wall)
	# dunes and rocks along the back and sides
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	for x in range(-24, 25, 4):
		var h := 1.4 + rng.randf() * 1.6
		Toon.part(lv, "ellipsoid", Vector3(5.5, h, 3.5), SAND_WET, Vector3(x + rng.randf() * 1.5, h * 0.25, 19.5))
	# the campfire with logs to sit on
	var fire := SmallLantern.new()
	fire.style = "campfire"
	fire.lantern_id = "s3_ates"
	fire.accent = "honey"
	fire.position = FIRE
	lv.add_child(fire)
	fire.light_up(true)
	for a in 3:
		var ang := TAU * a / 3.0 + 0.4
		Toon.part(lv, "capsule", Vector3(0.45, 2.0, 0.45), Color("#8a5a3a"), FIRE + Vector3(cos(ang) * 2.4, 0.22, sin(ang) * 2.4), Vector3(0, -rad_to_deg(ang), 90))
	# Fıstık's deck chair and the shell boat
	var chair := ModelImport.load_model("sezlong")
	if chair:
		chair.position = Vector3(11, 0, -5)
		chair.rotation_degrees.y = 200
		lv.add_child(chair)
	else:
		Toon.part(lv, "box", Vector3(0.9, 0.08, 1.8), Color("#7fc4f2"), Vector3(11, 0.45, -5), Vector3(-18, 20, 0))
		Toon.part(lv, "box", Vector3(1.0, 0.4, 1.9), Color("#a86b45"), Vector3(11, 0.2, -5), Vector3(0, 20, 0))
	var boat := ModelImport.load_model("kabuk_kayik")
	if boat:
		boat.position = Vector3(-17, 0, -8.5)
		boat.rotation_degrees.y = 70
		lv.add_child(boat)
	return lv


## The friends round the fire. `scared` = Sahne 2: they huddle closer.
func _place_friends(lv: Node3D, scared: bool) -> void:
	var k := 0.7 if scared else 1.0
	var spots := {
		"tospik_nine": [Vector3(-3.2, 0, 4.5), 150.0, "turtle", "Tospik"],
		"pati": [Vector3(4.5, 0, -0.5) * k, -60.0, "pati", "Pati"],
		"bado": [Vector3(-6.5, 0, -1.5) * k, 60.0, "bado", "Bado"],
		"citir": [Vector3(6.5, 0, 6.5) * k, -130.0, "citir", "Citir"],
		"lumi": [Vector3(-7.5, 0, 6.5) * k, 130.0, "lumi", "Lumi"],
		"tipis_panda": [Vector3(2.5, 0, 8.0), 180.0, "tipis_panda", "Tipis"],
	}
	for id: String in spots:
		var s: Array = spots[id]
		var n := npc(lv, id, s[2], s[0], s[1])
		n.name = s[3]
		_npcs[id] = n
	# Minnoş next to Bado
	var minnos := KeeperModels.build("bado")
	minnos.scale = Vector3.ONE * 0.5
	minnos.position = _npcs["bado"].position + Vector3(1.0, 0, 0.6)
	minnos.rotation.y = 0.8
	lv.add_child(minnos)
	var f := npc(lv, "fistik", "fistik", Vector3(11, 0.35, -5.6), 200.0)
	f.name = "Fistik"
	_npcs["fistik"] = f
	if not scared:
		var zzz := Label3D.new()
		zzz.text = "Zzz"
		zzz.font = Tokens.font_for("text-heading")
		zzz.font_size = 72
		zzz.pixel_size = 0.006
		zzz.outline_size = 16
		zzz.modulate = Tokens.color("panel@light")
		zzz.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		zzz.position = Vector3(11.4, 2.4, -5.6)
		lv.add_child(zzz)
		var tw := zzz.create_tween().set_loops()
		tw.tween_property(zzz, "position:y", 2.8, 1.4).set_trans(Tween.TRANS_SINE)
		tw.tween_property(zzz, "position:y", 2.4, 1.4).set_trans(Tween.TRANS_SINE)
