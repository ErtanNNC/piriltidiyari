extends Node3D
## Sezon 2 · Prolog · Sahne 5 – Mırıl'ın Seçimi. Cutscene, no player
## control: past the pass a small red steaming creature appears – Hırıl.
## It growls, the red mist swells, but Mırıl knows that voice ("Ben seni
## duyuyorum"). Hırıl asks Mırıl to stay; Mırıl throws a piece of its light
## back toward the village and goes with Hırıl on the red wind, by choice.
## Beats: content/s2_prologue/cutscenes/miril_secimi.json.

const ROCK := Color("#c98a5e")
const ROCK_DARK := Color("#9c6248")

var _miril: Node3D
var _hiril: Node3D
var _mist: Array[MeshInstance3D] = []
@onready var _hud: Hud = $Hud
@onready var _cam: Camera3D = $Camera


func _ready() -> void:
	WorldLook.add(self, "aksam")
	Pus.set_color(Pus.RED)
	Pus.set_amount(0.2)
	_build()
	_miril = MirilModel.star_child()
	add_child(_miril)
	MobModels._no_pus(_miril)
	_miril.position = Vector3(-1.3, 0, 1.0)
	_miril.rotation.y = PI
	_cam.make_current()
	await get_tree().create_timer(1.9).timeout
	var cs := CutscenePlayer.new()
	cs.scene = self
	cs.camera = _cam
	cs.hud = _hud
	add_child(cs)
	cs.play("miril_secimi")


func _build() -> void:
	var floor_body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(60, 1, 60)
	c.shape = b
	floor_body.add_child(c)
	floor_body.position.y = -0.5
	add_child(floor_body)
	Toon.part(self, "box", Vector3(60, 1, 60), Color("#8fb85a"), Vector3(0, -0.5, 0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(self, "cylinder", Vector3(14, 0.06, 14), Color("#e3c08c"), Vector3(0, 0.01, 0), Vector3.ZERO, 0.0, 0.0)
	var leaves := [Color("#e8833a"), Color("#d9542f"), Color("#f2b33d")]
	for i in 14:
		var a := PI + PI * i / 13.0
		var at := Vector3(cos(a) * 9.0, 0, sin(a) * 9.0 - 2.0)
		Toon.part(self, "cone", Vector3(3.0, 5.0 + (i % 3), 3.0), ROCK if i % 2 == 0 else ROCK_DARK, at + Vector3.UP * 2.5)
		Toon.part(self, "sphere", Vector3(2.4, 1.8, 2.4), leaves[i % 3], at * 1.2 + Vector3.UP * 1.0)
	# far behind: the red valley glowing over the mountains
	Toon.part(self, "cone", Vector3(26, 14, 20), Color("#8a5a6a"), Vector3(0, 6, -30))
	var glow := OmniLight3D.new()
	glow.light_color = Tokens.color("hp")
	glow.light_energy = 2.5
	glow.omni_range = 14.0
	glow.position = Vector3(0, 4, -10)
	add_child(glow)


# --- beats called from the cutscene ---------------------------------------

## Hırıl hops in from the north, steaming.
func hiril_appears() -> void:
	_hiril = HirilModel.build()
	add_child(_hiril)
	_hiril.position = Vector3(0, 0, -9.0)
	Effects.sparkle(self, _hiril.position + Vector3.UP, Tokens.color("hp"), 12)
	var tw := create_tween()
	for i in 4:
		var z := -9.0 + (i + 1) * 1.5
		tw.tween_property(_hiril, "position", Vector3(0.6, 0.6, z - 0.75), 0.18).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_hiril, "position", Vector3(0.6, 0, z), 0.18).set_trans(Tween.TRANS_SINE)
	_miril.rotation.y = PI * 0.85


## The red mist swells around them when Hırıl growls.
func mist_swell() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Tokens.color("hp")
	mat.albedo_color.a = 0.32
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 14:
		var a := TAU * i / 14.0
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 1.2
		s.height = 1.8
		mi.mesh = s
		mi.material_override = mat
		add_child(mi)
		mi.position = Vector3(sin(a) * 7.0, -1.0, cos(a) * 6.0 - 1.5)
		_mist.append(mi)
		var tw := mi.create_tween()
		tw.tween_property(mi, "position", Vector3(sin(a) * 5.0, 0.8, cos(a) * 4.5 - 1.5), randf_range(1.5, 2.5)).set_trans(Tween.TRANS_SINE)
	Pus.fade_to(self, 0.45, 1.5)
	var shake := create_tween()
	shake.tween_property(_hiril, "scale", Vector3(1.15, 0.9, 1.15), 0.15)
	shake.tween_property(_hiril, "scale", Vector3.ONE, 0.2)


## A piece of Mırıl's light flies back south, toward the village (a trail
## on the mountain the keepers will follow later).
func throw_light() -> void:
	var orb := Toon.part(self, "sphere", Vector3(0.6, 0.6, 0.6), "spark-white", _miril.position + Vector3.UP * 1.2, Vector3.ZERO, 2.0, 0.02)
	var l := OmniLight3D.new()
	l.light_color = Tokens.color("spark-white")
	l.light_energy = 2.0
	l.omni_range = 5.0
	orb.add_child(l)
	Effects.sparkle(self, orb.position, Tokens.color("spark-white"), 14)
	var tw := orb.create_tween()
	tw.tween_property(orb, "position", Vector3(4, 9, 30), 2.0).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(orb.queue_free)
	for i in 10:
		var dot := Toon.part(self, "sphere", Vector3(0.15, 0.15, 0.15), "spark-yellow", Vector3(i * 0.3, 1.2 + i * 0.6, 1.0 + i * 2.6), Vector3.ZERO, 2.0, 0.0)
		dot.scale = Vector3.ZERO
		var d := dot.create_tween()
		d.tween_interval(i * 0.15)
		d.tween_property(dot, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)


## The red wind lifts Mırıl and Hırıl away to the north, together.
func red_wind() -> void:
	Effects.ring(self, Vector3(0, 0.3, 0), 6.0, Tokens.color("hp"), 0.8)
	Effects.shake(get_viewport(), 0.6)
	for n: Node3D in [_miril, _hiril]:
		var tw := n.create_tween()
		tw.tween_property(n, "rotation:y", n.rotation.y + TAU * 2.0, 1.2)
		tw.parallel().tween_property(n, "position", n.position + Vector3(0, 3.0, -2.0), 1.2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(n, "position", Vector3(n.position.x * 0.5, 10.0, -28.0), 1.8).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(n, "scale", Vector3.ONE * 0.3, 1.8)
	for m in _mist:
		var tw := m.create_tween()
		tw.tween_property(m, "position", m.position + Vector3(0, 6, -18), 2.4).set_ease(Tween.EASE_IN)
	Pus.fade_to(self, 0.15, 3.0)


func finish() -> void:
	GameState.data.set_flag("s2_sahne5_bitti")
	if DevTools.demo == "flow" and DisplayServer.get_name() == "headless":
		print("S5B_FLOW flag=%s" % GameState.data.has_flag("s2_sahne5_bitti"))
		get_tree().quit()
