class_name BeachTorch
extends Node3D
## Season 3: a torch on a pole. "Yak" lights it; a lit torch keeps a big
## warm circle where the Titreme barı empties and Titrekler calm down. Lit
## torches stay lit (safe paths through the dark).

signal lit_up

const RADIUS := 4.5

@export var torch_id := "mesale"
## Set to keep the torch lit across saves (lit torches are safe paths).
@export var save_flag := ""
var radius := RADIUS
var lit := false
## A locked torch can't be lit yet (the Dev Gölge covers it).
var locked := false
var _area: Area3D
var _flame: Node3D
var _light: OmniLight3D
var _glow: MeshInstance3D


func _ready() -> void:
	var model := ModelImport.load_model("mesale")
	if model:
		add_child(model)
	else:
		Toon.part(self, "cylinder", Vector3(0.14, 1.7, 0.14), Color("#8a5a3a"), Vector3(0, 0.85, 0))
		Toon.part(self, "cone", Vector3(0.42, 0.34, 0.42), Color("#6e4a30"), Vector3(0, 1.82, 0), Vector3(180, 0, 0))
	_flame = Node3D.new()
	_flame.position.y = 2.05
	_flame.visible = false
	add_child(_flame)
	Toon.part(_flame, "sphere", Vector3(0.36, 0.5, 0.36), Color("#ffb347"), Vector3.ZERO, Vector3.ZERO, 1.6, 0.0)
	Toon.part(_flame, "sphere", Vector3(0.2, 0.32, 0.2), Color("#fff1b0"), Vector3(0, 0.04, 0), Vector3.ZERO, 2.0, 0.0)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.72, 0.42)
	_light.light_energy = 0.0
	_light.omni_range = RADIUS * 1.5
	_light.position.y = 2.1
	add_child(_light)
	_glow = MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = RADIUS
	m.bottom_radius = RADIUS
	m.height = 0.02
	m.radial_segments = 48
	_glow.mesh = m
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(1.0, 0.7, 0.35, 0.05)
	_glow.material_override = mat
	_glow.position.y = 0.04
	_glow.visible = false
	add_child(_glow)
	_area = Area3D.new()
	_area.collision_layer = 4
	_area.collision_mask = 0
	_area.monitoring = false
	_area.set_meta("interactable", self)
	set_meta("action_label", "Yak")
	var col := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.8
	col.shape = s
	col.position.y = 0.9
	_area.add_child(col)
	add_child(_area)
	var body := StaticBody3D.new()
	var bc := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.18
	cyl.height = 2.0
	bc.shape = cyl
	bc.position.y = 1.0
	body.add_child(bc)
	add_child(body)
	Beacon.attach(self, 2.9, Color(1.0, 0.75, 0.4))
	if save_flag != "" and GameState.data.has_flag(save_flag):
		light_up(true)


func interact(_by: Node) -> void:
	if not locked:
		light_up()


## Lock (no star, no "Yak") or unlock the torch.
func set_locked(on: bool) -> void:
	locked = on
	if lit:
		return
	_area.collision_layer = 0 if on else 4
	if on and has_node("Beacon"):
		get_node("Beacon").queue_free()
	elif not on and not has_node("Beacon"):
		Beacon.attach(self, 2.9, Color(1.0, 0.75, 0.4))


func light_up(silent := false) -> void:
	if lit:
		return
	lit = true
	add_to_group("light_ring")
	_flame.visible = true
	_glow.visible = true
	_area.queue_free()
	if has_node("Beacon"):
		get_node("Beacon").queue_free()
	if silent:
		_light.light_energy = 1.6
		return
	if save_flag != "":
		GameState.data.set_flag(save_flag)
	create_tween().tween_property(_light, "light_energy", 1.6, 0.6)
	Audio.play("lantern")
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 2.0, Color(1.0, 0.8, 0.4), 12)
	Effects.ring(get_parent(), global_position + Vector3.UP * 0.1, RADIUS, Color(1.0, 0.8, 0.45, 0.9), 0.6)
	GameState.notify("light", torch_id)
	lit_up.emit()


func _process(_delta: float) -> void:
	if lit:
		var t := Time.get_ticks_msec() / 1000.0
		_flame.scale = Vector3.ONE * (1.0 + sin(t * 13.0) * 0.08 + sin(t * 7.3) * 0.05)
		_light.light_energy = 1.5 + sin(t * 11.0) * 0.15
