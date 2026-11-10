class_name LightRing
extends Node3D
## Season 3: the small warm light round the keeper at night, and the
## Titreme barı. The scene sets `cold` (0..1) where the Mavi Titreme is
## thick; inside a lit torch's light (group "light_ring", nodes with
## `radius` and `lit`) the bar empties again (`ShiverRules`). Full bar =
## donakaldın for a moment: hold Sakinleş (a deep breath) to thaw faster.

signal shiver_changed(value: float)

const BASE := 2.4

var radius := BASE
var cold := 0.0
## Set every frame by dark puddles (InkPuddle); used once, then cleared.
var extra_cold := 0.0
## Cesaret Kurabiyesi: the bar does not fill until then.
var brave_until := 0.0
var shiver := 0.0
var frozen := 0.0
var holding_hands := false
var boost_until := 0.0
var lit := true
var _disc: MeshInstance3D
var _light: OmniLight3D


func _ready() -> void:
	add_to_group("light_ring")
	_disc = MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = 1.0
	m.bottom_radius = 1.0
	m.height = 0.02
	m.radial_segments = 40
	_disc.mesh = m
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(1.0, 0.75, 0.4, 0.13)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_disc.material_override = mat
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disc.position.y = 0.05
	add_child(_disc)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.78, 0.5)
	_light.light_energy = 1.1
	_light.position.y = 1.6
	add_child(_light)


func _process(delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var want := BASE * (2.0 if now < boost_until else 1.0) * (1.6 if holding_hands else 1.0)
	radius = lerpf(radius, want, minf(delta * 3.0, 1.0))
	_disc.scale = Vector3(radius, 1.0, radius)
	_light.omni_range = radius * 1.8
	_light.light_energy = 1.1 if cold > 0.0 or holding_hands else 0.5
	var before := shiver
	var was_frozen := frozen > 0.0
	if frozen > 0.0:
		var p := get_parent() as Player
		var breath := Input.is_action_pressed("calm") and p != null and p.input_enabled
		frozen -= delta * (ShiverRules.BREATH_SPEED if breath else 1.0)
		if frozen <= 0.0:
			frozen = 0.0
			shiver = 0.4
			GameState.toast.emit("Oh... Derin bir nefes, titreme geçti.", "heart")
	else:
		var c := 0.0 if torch_near(get_tree(), global_position) else cold
		c = maxf(c, extra_cold)
		extra_cold = 0.0
		if now < brave_until:
			c = 0.0
		shiver = ShiverRules.fill(shiver, c, delta, holding_hands)
		if shiver >= 1.0:
			frozen = ShiverRules.FROZEN_TIME
			Audio.play("warn")
			GameState.toast.emit("Donakaldın! Sakinleş'e basılı tut: derin nefes.", "spark")
	if not is_equal_approx(before, shiver) or was_frozen != (frozen > 0.0):
		shiver_changed.emit(shiver)


func is_frozen() -> bool:
	return frozen > 0.0


## Sıcak Kakao: the bar is empty, a frozen keeper moves again.
func warm() -> void:
	shiver = 0.0
	frozen = 0.0
	shiver_changed.emit(shiver)


## A lit torch (not the keeper's own small light) covers this point.
static func torch_near(tree: SceneTree, at: Vector3) -> bool:
	for n in tree.get_nodes_in_group("light_ring"):
		if n is LightRing or not n.lit:
			continue
		var d := Vector2(n.global_position.x - at.x, n.global_position.z - at.z).length()
		if d < float(n.radius):
			return true
	return false


## Any light (a torch or a keeper's ring) covers this point.
static func lit_at(tree: SceneTree, at: Vector3) -> bool:
	for n in tree.get_nodes_in_group("light_ring"):
		if not n.lit:
			continue
		var d := Vector2(n.global_position.x - at.x, n.global_position.z - at.z).length()
		if d < float(n.radius):
			return true
	return false
