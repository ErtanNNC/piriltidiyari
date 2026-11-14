extends Node3D
## Sezon 4 · Prolog · Sahne 5 – Tırıl'ın Seçimi. Cutscene, no player
## control: behind the forest a thorny gate opens. In a dark corner beyond
## it sits a small brown seed, Dırıl: "Herkes çiçek açtı. Ben hiç açamadım.
## Sen bile ışık saçıyorsun!" The vines swell. Tırıl knows that feeling,
## floats to Dırıl's side; the vines close the gate. Tırıl stays inside to
## light the corner: a pale blue line of light seeps out under the gate.
## Beats: content/s4_prologue/cutscenes/tiril_secimi.json.

const GREEN := Color(0.62, 1.1, 0.6)
const LIGHT := Color("#9fd8ff")
const GATE := Vector3(0, 0, -4.0)
const CORNER := Vector3(0, 0, -10.0)

var _lv: Node3D
var _tiril: Node3D
var _diril: Node3D
var _door_vines: Array[Node3D] = []   # across the gate: open, then closed again
var _side_vines: Array[Node3D] = []   # round the gate: they swell
var _seep: MeshInstance3D
var _floating := true
@onready var _hud: Hud = $Hud
@onready var _cam: Camera3D = $Camera


func _ready() -> void:
	WorldLook.add(self, "orman")
	Pus.set_color(GREEN)
	Pus.set_amount(0.2)
	_lv = Node3D.new()
	_lv.name = "Level"
	add_child(_lv)
	WorldLook.block(_lv, Vector3(0, -0.5, 0), Vector3(60, 1, 50), Color("#7cbf6e"), 0.0)
	# the dark corner behind the gate
	var dark := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 6.5
	disc.bottom_radius = 6.5
	disc.height = 0.04
	dark.mesh = disc
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color("#3c5a48")
	dark.material_override = dm
	dark.position = CORNER + Vector3(0, 0.03, 0)
	_lv.add_child(dark)
	for x: float in [-13.0, -8.0, 8.0, 13.0]:
		if _prop("orman_agaclar", Vector3(x, 0, -6.0 - absf(x) * 0.3), 8.0, x) == null:
			_prop("prop_tree", Vector3(x, 0, -7.0), 6.5)
	for x: float in [-9.0, -3.0, 3.5, 9.5]:
		_prop("orman_agaclar", Vector3(x, 0, -16.0), 9.0, x * 0.7)
	if _prop("bahar_kapisi", GATE, 4.6) == null:
		for side: float in [-1.0, 1.0]:
			Toon.part(_lv, "cylinder", Vector3(0.6, 4.4, 0.6), Color("#8a6a4a"), GATE + Vector3(side * 1.9, 2.2, 0))
		Toon.part(_lv, "box", Vector3(4.6, 0.6, 0.6), Color("#8a6a4a"), GATE + Vector3(0, 4.4, 0))
	# thorny hedge to both sides of the gate, vines on its posts
	for side: float in [-1.0, 1.0]:
		for k in 3:
			var h := _vine("diken_citi" if k % 2 == 0 else "sarmasik", GATE + Vector3(side * (3.6 + k * 2.6), 0, 0.2), 2.4 + k * 0.2, k * 1.1)
			if k == 0 and h:
				_side_vines.append(h)
		var v := _vine("sarmasik", GATE + Vector3(side * 2.2, 0, 0.5), 2.6, side)
		if v:
			_side_vines.append(v)
	for x: float in [-1.0, 0.0, 1.0]:
		var v := _vine("sarmasik", GATE + Vector3(x * 1.05, 0, 0.15), 3.3, x * 2.0)
		if v:
			_door_vines.append(v)
	# the line of light under the gate (shown at the very end)
	_seep = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.2, 0.05, 0.5)
	_seep.mesh = bm
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_color = Color(LIGHT.r, LIGHT.g, LIGHT.b, 0.0)
	_seep.material_override = sm
	_seep.position = GATE + Vector3(0, 0.07, 1.1)
	_lv.add_child(_seep)
	# Dırıl, a small brown seed with his back half turned
	_diril = ModelImport.load_model("diril")
	if _diril == null:
		_diril = Node3D.new()
		Toon.part(_diril, "ellipsoid", Vector3(0.7, 0.9, 0.7), Color("#8a5a3c"), Vector3(0, 0.45, 0))
		Face.add(_diril, Vector3(0, 0.55, 0.3), Vector3(0.3, 0.25, 0.1))
	MobModels._no_pus(_diril)
	add_child(_diril)
	_diril.position = CORNER
	_diril.rotation.y = 0.5
	# Tırıl, floating in from the pumpkin patch
	_tiril = ModelImport.load_model("tiril")
	if _tiril == null:
		_tiril = Node3D.new()
		Toon.part(_tiril, "sphere", Vector3(0.9, 0.9, 0.9), LIGHT, Vector3(0, 0.6, 0), Vector3.ZERO, 1.5, 0.0)
	MobModels._no_pus(_tiril)
	add_child(_tiril)
	_tiril.position = Vector3(0.8, 0.5, 4.5)
	_tiril.rotation.y = PI
	var l := OmniLight3D.new()
	l.name = "Glow"
	l.light_color = LIGHT
	l.light_energy = 1.6
	l.omni_range = 6.0
	l.position.y = 0.7
	_tiril.add_child(l)
	_cam.make_current()
	await get_tree().create_timer(1.6, false).timeout
	var cs := CutscenePlayer.new()
	cs.scene = self
	cs.camera = _cam
	cs.hud = _hud
	add_child(cs)
	cs.play("tiril_secimi")


## A scenery model standing on the ground, `h` tall.
func _prop(id: String, at: Vector3, h: float, yaw := 0.0) -> Node3D:
	var m := ModelImport.prop_copy(id)
	if m == null:
		return null
	var b := ModelImport.static_bounds(id)
	var s := h / maxf(b.size.y, 0.01)
	var holder := Node3D.new()
	_lv.add_child(holder)
	holder.position = at
	holder.rotation.y = yaw
	holder.add_child(m)
	m.scale = Vector3.ONE * s
	m.position = -Vector3(b.position.x + b.size.x * 0.5, b.position.y, b.position.z + b.size.z * 0.5) * s
	return holder


func _vine(id: String, at: Vector3, h: float, yaw: float) -> Node3D:
	var v := _prop(id, at, h, yaw)
	if v == null:
		v = Node3D.new()
		_lv.add_child(v)
		v.position = at
		Toon.part(v, "ellipsoid", Vector3(1.3, h, 1.0), Color("#3f8a4a"), Vector3(0, h * 0.5, 0))
	return v


func _process(_delta: float) -> void:
	if _floating and _tiril:
		_tiril.position.y = 0.5 + sin(Time.get_ticks_msec() / 1000.0 * 1.6) * 0.18


# --- beats -------------------------------------------------------------

## The vines across the gate draw aside by themselves.
func gate_opens() -> void:
	Audio.play("page")
	for i in _door_vines.size():
		var v := _door_vines[i]
		var tw := create_tween()
		tw.tween_interval(i * 0.15)
		tw.tween_property(v, "scale", Vector3(1.0, 0.04, 1.0), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(v.hide)
	Effects.sparkle(self, GATE + Vector3(0, 1.6, 0.6), Tokens.color("spark-green"), 14)


## "Sen bile ışık saçıyorsun!": the vines round the gate swell.
func vines_swell() -> void:
	Audio.play("whoosh")
	for v in _side_vines:
		var tw := create_tween()
		tw.tween_property(v, "scale", Vector3(1.45, 1.5, 1.45), 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var tw2 := create_tween()
	tw2.tween_property(_diril, "scale", Vector3(1.08, 0.86, 1.08), 0.3)
	tw2.tween_property(_diril, "scale", Vector3.ONE, 0.4)


## Tırıl floats through the gate to Dırıl's side.
func tiril_floats() -> void:
	_floating = false
	var tw := create_tween()
	tw.tween_property(_tiril, "position", GATE + Vector3(0, 0.9, 0.0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_tiril, "position", CORNER + Vector3(1.4, 0.45, 0.5), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		_tiril.rotation.y = -1.2
		_diril.rotation.y = 0.9
		Effects.sparkle(self, _tiril.position + Vector3.UP, LIGHT, 12))


## The vines grow back over the gate, thicker than before.
func gate_closes() -> void:
	Audio.play("whoosh")
	for i in _door_vines.size():
		var v := _door_vines[i]
		v.show()
		var tw := create_tween()
		tw.tween_interval(i * 0.2)
		tw.tween_property(v, "scale", Vector3(1.25, 1.2, 1.25), 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Pus.fade_to(self, 0.55, 2.0)


## Tırıl lights the corner: a pale blue line under the gate.
func light_seeps() -> void:
	Audio.play("blip")
	var mat := _seep.material_override as StandardMaterial3D
	var tw := create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.85, 1.4)
	var l := OmniLight3D.new()
	l.light_color = LIGHT
	l.light_energy = 0.0
	l.omni_range = 5.0
	l.position = GATE + Vector3(0, 0.5, 1.4)
	add_child(l)
	create_tween().tween_property(l, "light_energy", 1.8, 1.4)
	Effects.sparkle(self, GATE + Vector3(0, 0.3, 1.3), LIGHT, 10)


func finish() -> void:
	GameState.data.set_flag("s4_sahne5_bitti")
	if DevTools.demo == "flow" and DisplayServer.get_name() == "headless":
		print("S4B5_CHOICE flag=%s tiril_in=%s gate_closed=%s seep=%.2f" % [GameState.data.has_flag("s4_sahne5_bitti"), _tiril.position.z < GATE.z, _door_vines.all(func(v: Node3D) -> bool: return v.visible and v.scale.y > 1.0), (_seep.material_override as StandardMaterial3D).albedo_color.a])
		get_tree().quit()
