class_name MirrorStone
extends Interactable
## Season 4, Ayna Gölü: a mirror stone at a fork of the lily-pad paths.
## "Bak": whoever looks into the lake here sees somebody else's reflection:
## the creature whose path is the firm one. The reflection (a small pale
## copy of the creature with its name) then stays over the stone
## (`read_flag`). While `covered` (a clump of Yeşil Diken grew over it) it
## only says to clap. Event: "collect"/"ayna"; signal `read`.

signal read(stone: MirrorStone)

## Model id of the creature in the reflection and its name on the label.
@export var creature := "taklitci_kurbaga"
@export var creature_name := "Kurbağa"
@export var read_flag := ""
@export var bark_id := ""
var covered := false
var is_read := false
var _glass: Node3D


func _build() -> void:
	action_label = "Bak"
	reach = 1.9
	var m := ModelImport.prop_copy("ayna_tasi")
	if m:
		var b := ModelImport.static_bounds("ayna_tasi")
		var s := 1.7 / maxf(b.size.y, 0.01)
		m.scale = Vector3.ONE * s
		m.position = -Vector3(b.position.x + b.size.x * 0.5, b.position.y, b.position.z + b.size.z * 0.5) * s
		add_child(m)
	else:
		Toon.part(self, "ellipsoid", Vector3(1.2, 1.7, 0.5), Color("#9aa3b8"), Vector3(0, 0.85, 0))
		Toon.part(self, "ellipsoid", Vector3(0.85, 1.2, 0.1), Color("#cfeaff"), Vector3(0, 0.9, 0.24), Vector3.ZERO, 0.5, 0.0)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.45
	cyl.height = 1.6
	c.shape = cyl
	c.position.y = 0.8
	body.add_child(c)
	add_child(body)
	if read_flag != "" and GameState.data.has_flag(read_flag):
		is_read = true
		_show(true)
	else:
		Beacon.attach(self, 2.4, Tokens.color("sky"))


func use(_by: Node) -> void:
	if covered:
		GameState.toast.emit("Sarmaşık aynayı örtmüş. Yanında alkışla!", "spark")
		return
	var first := not is_read
	if first:
		is_read = true
		if read_flag != "":
			GameState.data.set_flag(read_flag)
		if has_node("Beacon"):
			get_node("Beacon").queue_free()
		_show(false)
		GameState.notify("collect", "ayna")
	else:
		Effects.sparkle(get_parent(), global_position + Vector3.UP * 2.4, Tokens.color("sky"), 8)
	Audio.play("crystal")
	if bark_id != "":
		GameState.bark(bark_id)
	if first:
		read.emit(self)


## The reflection: a small copy of the creature in a ring of water light.
func _show(quiet: bool) -> void:
	if _glass:
		return
	_glass = Node3D.new()
	_glass.name = "Reflection"
	_glass.position = Vector3(0, 2.3, 0)
	add_child(_glass)
	Toon.part(_glass, "ring", Vector3(1.5, 0.07, 1.5), Tokens.color("sky"), Vector3(0, 0.45, 0), Vector3(90, 0, 0), 0.8, 0.0)
	var m := ModelImport.prop_copy(creature)
	if m:
		var b := ModelImport.static_bounds(creature)
		var s := 0.95 / maxf(b.size.y, maxf(b.size.x, 0.01))
		m.scale = Vector3.ONE * s
		m.position = -Vector3(b.position.x + b.size.x * 0.5, b.position.y, b.position.z + b.size.z * 0.5) * s
		_glass.add_child(m)
	else:
		Toon.part(_glass, "sphere", Vector3(0.8, 0.8, 0.8), Tokens.color("sky"), Vector3(0, 0.45, 0), Vector3.ZERO, 0.6, 0.02)
	var tag := Label3D.new()
	tag.text = creature_name
	tag.font = Tokens.font_for("text-heading")
	tag.font_size = 44
	tag.pixel_size = 0.006
	tag.modulate = Tokens.color("panel@light")
	tag.outline_modulate = Color("#2a2433")
	tag.outline_size = 10
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.position = Vector3(0, 1.35, 0)
	_glass.add_child(tag)
	var tw := _glass.create_tween().set_loops()
	tw.tween_property(_glass, "position:y", 2.45, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_glass, "position:y", 2.3, 1.2).set_trans(Tween.TRANS_SINE)
	if not quiet:
		_glass.scale = Vector3.ONE * 0.1
		var pop := _glass.create_tween()
		pop.tween_property(_glass, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Effects.ring(get_parent(), global_position + Vector3.UP * 0.2, 2.2, Tokens.color("sky"), 0.5)
