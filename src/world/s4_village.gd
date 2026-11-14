class_name S4Village
extends RefCounted
## Season 4 prologue: Gökkuşağı Köyü in spring, shared by Sahne 1, 2 (and 6).
##
## API (all static, call after `begin_garden()` so `g.lv` exists):
##   S4Village.build(g)            ground, sea-less fence, path, three gardens
##                                 with houses, the square with the jury stall,
##                                 a fountain and the contest board.
##   S4Village.villagers(g)        the three garden owners as NPCs (nodes
##                                 "Havuc", "Kok", "Nilufer" under `g`) and
##                                 Tospik Nine (node "Tospik") on the square.
##   S4Village.balloon(player)     Tırıl's water balloon (pale sphere) plus
##                                 the float: hold jump while falling.
## Places: GARDENS[i] = [npc id, model kind, node name, garden centre],
## SQUARE, TOSPIK_AT, MY_PLOT (Tırıl's own bed), SPAWN (0, 0, 20).
## The camera looks from the south (+z): houses stand on the outer sides.

const GRASS := Color("#8fcf7a")
const PATH := Color("#e6d3a8")
const SOIL := Color("#9a6b45")
const GARDENS := [["havuc_teyze", "bunny", "Havuc", Vector3(-11, 0, 10)],
	["kok_amca", "mole", "Kok", Vector3(11, 0, 3)],
	["nilufer_abla", "frog", "Nilufer", Vector3(-11, 0, -5)]]
const FLOWERS := [["lale", "papatya", "lale"], ["lale", "lale", "gul"], ["gul", "papatya", "gul"]]
const SQUARE := Vector3(0, 0, -15)
const TOSPIK_AT := Vector3(2.6, 0, -14.0)
const MY_PLOT := Vector3(6.0, 0, 14.0)
const SPAWN := Vector3(0, 0, 20)
const FLOAT_TIME := 1.6
const FLOAT_FALL := 1.4


static func build(g: S4Garden) -> void:
	var lv := g.lv
	g.land(Vector3(0, 0, -1), Vector2(46, 60), GRASS)
	g.fence(Vector3(0, 0, -1), Vector2(44, 58))
	WorldLook.block(lv, Vector3(0, 0.02, 2), Vector3(3.2, 0.04, 44), PATH, 0.0)
	WorldLook.block(lv, SQUARE + Vector3(0, 0.02, 0), Vector3(14, 0.04, 9), PATH, 0.0)
	for i in GARDENS.size():
		var at: Vector3 = GARDENS[i][3]
		var side := signf(at.x)
		WorldLook.block(lv, Vector3(at.x * 0.5 - side * 0.5, 0.02, at.z + 1.0), Vector3(absf(at.x) - 3.0, 0.04, 1.8), PATH, 0.0)
		# the bed: soil, three rows of flowers, a fence behind and outside
		WorldLook.block(lv, at + Vector3(0, 0.025, 0), Vector3(6.0, 0.05, 5.0), SOIL, 0.0)
		var kinds: Array = FLOWERS[i]
		for k in 6:
			var p := at + Vector3((k % 3 - 1) * 1.8, 0, -1.3 if k < 3 else 0.9)
			if g.prop(kinds[k % 3], p, 1.0 + 0.15 * (k % 2), k * 1.1) == null:
				Toon.part(lv, "sphere", Vector3(0.5, 0.4, 0.5), Tokens.color(["berry", "spark-yellow", "sky"][k % 3]), p + Vector3(0, 0.6, 0))
		for x: float in [-2.0, 2.0]:
			g.prop("bahce_citi", at + Vector3(x, 0, -2.9), 1.0, 0.0)
		g.prop("cicek_tarhi", at + Vector3(side * 2.0, 0, 3.4), 0.9, 0.3)
		# the owner's house on the outer side
		var home := at + Vector3(side * 7.0, 0, -1.0)
		if g.prop("yuva_evi", home, 4.4, -90.0 * side * PI / 180.0) == null:
			Toon.part(lv, "box", Vector3(4, 3.4, 4), Color("#f2dcb8"), home + Vector3(0, 1.7, 0))
		_solid(lv, home, Vector3(3.6, 4.0, 3.6))
	# the square: jury stall, fountain, the board, flower pots
	if g.prop("pazar_tezgahi", SQUARE + Vector3(0, 0, -5.0), 3.0, 0.0) != null:
		_solid(lv, SQUARE + Vector3(0, 0, -5.0), Vector3(3.4, 3.0, 1.6))
	if g.prop("bahar_cesmesi", SQUARE + Vector3(-9.5, 0, -1.0), 3.2, 0.0) != null:
		_solid(lv, SQUARE + Vector3(-9.5, 0, -1.0), Vector3(2.2, 3.0, 2.2))
	TravelSign.board(lv, "Çiçek Yarışması", SQUARE + Vector3(-4.6, 1.5, -3.4), 3.0)
	Toon.part(lv, "box", Vector3(0.16, 1.4, 0.16), Color("#a86b45"), SQUARE + Vector3(-4.6, 0.7, -3.45))
	for x: float in [-6.0, 6.0]:
		g.prop("saksi", SQUARE + Vector3(x, 0, 3.6), 0.8, 0.0)
	g.prop("saksi", MY_PLOT + Vector3(2.0, 0, -0.6), 0.7, 0.0)
	for p: Vector3 in [Vector3(16, 0, 18), Vector3(-17, 0, 22), Vector3(17, 0, -12), Vector3(-17, 0, -20), Vector3(13, 0, -24)]:
		var t := Prop.new()
		t.kind = "tree"
		t.position = p
		lv.add_child(t)


static func villagers(g: S4Garden) -> void:
	for e: Array in GARDENS:
		var at: Vector3 = e[3]
		var side := signf(at.x)
		g.npc(g, e[0], e[1], at + Vector3(-side * 4.3, 0, 1.0), 90.0 * side).name = e[2]
	g.npc(g, "tospik_nine", "turtle", TOSPIK_AT, -160.0).name = "Tospik"


## Tırıl travels on land inside a water balloon. Returns the balloon node
## (it also lets Tırıl float down: hold jump while falling).
static func balloon(player: Player) -> Node3D:
	if player.has_node("WaterBalloon"):
		return player.get_node("WaterBalloon")
	var b := Balloon.new()
	b.name = "WaterBalloon"
	player.add_child(b)
	return b


static func _solid(lv: Node3D, at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	c.shape = s
	c.position.y = size.y * 0.5
	body.add_child(c)
	body.position = at
	lv.add_child(body)


class Balloon extends Node3D:
	var _left := 0.0
	var _fx := 0.0
	var _mesh: MeshInstance3D

	func _ready() -> void:
		_mesh = MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 1.0
		s.height = 2.0
		_mesh.mesh = s
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.72, 0.92, 1.0, 0.2)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.rim_enabled = true
		m.cull_mode = BaseMaterial3D.CULL_BACK
		_mesh.material_override = m
		_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mesh.position.y = 0.95
		add_child(_mesh)
		var tw := _mesh.create_tween().set_loops()
		tw.tween_property(_mesh, "scale", Vector3(1.04, 0.96, 1.04), 0.9).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_mesh, "scale", Vector3(0.97, 1.03, 0.97), 0.9).set_trans(Tween.TRANS_SINE)

	func _physics_process(delta: float) -> void:
		var p := get_parent() as Player
		if p == null:
			return
		if p.is_on_floor():
			_left = S4Village.FLOAT_TIME
		elif _left > 0.0 and p.velocity.y < 0.0 and p.input_enabled and not p.asleep and Input.is_action_pressed("jump"):
			_left -= delta
			p.velocity.y = maxf(p.velocity.y, -S4Village.FLOAT_FALL)
			_fx -= delta
			if _fx <= 0.0:
				_fx = 0.15
				Effects.sparkle(p.get_parent(), p.global_position + Vector3.UP * 0.3, Tokens.color("sky"), 2)


## A thing to press once ("Sula"): the scene decides what happens.
class Spot extends Interactable:
	signal used

	func use(_by: Node) -> void:
		used.emit()
