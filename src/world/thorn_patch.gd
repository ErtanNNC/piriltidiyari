class_name ThornPatch
extends Node3D
## Season 4: a clump of the Yeşil Diken. Standing in or near it fills the
## Diken barı (`Applause.heat`); with `blocks` it is also a wall across a
## path. It draws back when someone is applauded here (`clap_opens`: the
## thorns of a neighbour's garden), when `open()` is called (an ark opened,
## a boss calmed) or when its `open_flag` is already set. Never hurts.

signal retracted(patch: ThornPatch)

@export var size := Vector3(4.0, 2.2, 1.6)
@export var blocks := true
@export var clap_opens := false
@export var open_flag := ""
@export var strength := 1.0
## Event sent when a clap opens it: "clap"/<id> ("" = none).
@export var clap_id := ""
var is_open := false
var _body: StaticBody3D
var _look: Node3D
var _player: Player


func _ready() -> void:
	_look = Node3D.new()
	add_child(_look)
	var n := maxi(1, roundi(size.x / 2.0))
	for i in n:
		var x := (i - (n - 1) * 0.5) * (size.x / n)
		var piece := ModelImport.prop_copy("sarmasik" if i % 2 == 0 else "diken_citi")
		if piece:
			var id := "sarmasik" if i % 2 == 0 else "diken_citi"
			var b := ModelImport.static_bounds(id)
			var s := size.y / maxf(b.size.y, 0.01)
			piece.scale = Vector3.ONE * s
			piece.position = Vector3(x, 0, 0) - Vector3(b.position.x + b.size.x * 0.5, b.position.y, b.position.z + b.size.z * 0.5) * s
			piece.rotation.y = i * 1.3
			_look.add_child(piece)
		else:
			Toon.part(_look, "ellipsoid", Vector3(size.x / n * 1.1, size.y, size.z), Color("#3f8a4a"), Vector3(x, size.y * 0.5, 0))
			for k in 4:
				Toon.part(_look, "cone", Vector3(0.25, 0.5, 0.25), Color("#2c6a38"), Vector3(x + (k - 1.5) * 0.4, size.y * (0.5 + 0.12 * k), size.z * 0.4), Vector3(60, k * 40, 0))
	if blocks:
		_body = StaticBody3D.new()
		var c := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = Vector3(size.x, 4.0, size.z)
		c.shape = b
		c.position.y = 2.0
		_body.add_child(c)
		add_child(_body)
	if clap_opens:
		add_to_group("applaudable")
		set_meta("clap_reach", maxf(size.x * 0.5 + 3.0, Applause.REACH))
	if open_flag != "" and GameState.data.has_flag(open_flag):
		_gone()


func _process(_delta: float) -> void:
	if is_open:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
		return
	if _player.clap == null:
		return
	var local := to_local(_player.global_position)
	if absf(local.x) < size.x * 0.5 + 2.2 and absf(local.z) < size.z * 0.5 + 2.2 and absf(local.y) < 4.0:
		_player.clap.heat = maxf(_player.clap.heat, strength)


## A clap for the garden these thorns grew over.
func applauded(_by: Node) -> bool:
	if is_open or not clap_opens:
		return false
	if clap_id != "":
		GameState.notify("clap", clap_id)
	open()
	return true


func open() -> void:
	if is_open:
		return
	is_open = true
	if open_flag != "":
		GameState.data.set_flag(open_flag)
	if _body:
		_body.queue_free()
		_body = null
	Audio.play("page")
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 1.2, Tokens.color("spark-green"), 14)
	var tw := _look.create_tween()
	tw.tween_property(_look, "scale", Vector3(1.0, 0.05, 1.0), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(_flowers)
	retracted.emit(self)


func _gone() -> void:
	is_open = true
	if _body:
		_body.queue_free()
		_body = null
	_flowers()


## Where thorns were, a few flowers stay.
func _flowers() -> void:
	_look.visible = false
	remove_from_group("applaudable")
	var n := maxi(2, roundi(size.x / 1.5))
	for i in n:
		var x := (i - (n - 1) * 0.5) * (size.x / n)
		var col := Tokens.color(["berry", "spark-yellow", "sky", "honey"][i % 4])
		Toon.part(self, "cylinder", Vector3(0.06, 0.4, 0.06), Color("#4a9a5a"), Vector3(x, 0.2, 0))
		Toon.part(self, "sphere", Vector3(0.3, 0.2, 0.3), col, Vector3(x, 0.45, 0), Vector3.ZERO, 0.3, 0.02)
