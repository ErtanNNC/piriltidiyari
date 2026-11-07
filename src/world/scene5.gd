extends Node3D
## Prolog · Sahne 5 – Fıstık'ın Seçimi. Cutscene, no player control:
## the Pus climbs the tower, Fıstık shatters the Büyük Kıvılcım into five
## sparks that fly to the five regions, and turns into a glowing statue.
## The beats live in content/prologue/cutscenes/fistigin_secimi.json.

const SPARKS := ["spark-green", "spark-blue", "spark-yellow", "spark-white", "spark-purple"]

var _crystal: MeshInstance3D
var _fistik: Node3D
var _fog: Array[MeshInstance3D] = []
@onready var _hud: Hud = $Hud
@onready var _cam: Camera3D = $Camera


func _ready() -> void:
	WorldLook.add(self, "kule")
	Pus.set_amount(0.5)
	_crystal = TowerTop.build(self)
	_fistik = FistikModel.build()
	add_child(_fistik)
	_fistik.position = Vector3(0, 0, 4)
	_fistik.rotation.y = PI
	_cam.make_current()
	await get_tree().create_timer(1.9).timeout
	var cs := CutscenePlayer.new()
	cs.scene = self
	cs.camera = _cam
	cs.hud = _hud
	add_child(cs)
	cs.play("fistigin_secimi")


# --- beats called from the cutscene ---------------------------------------

func rise_pus() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Tokens.color("pus")
	mat.albedo_color.a = 0.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 18:
		var a := TAU * i / 18.0
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 1.6
		s.height = 2.4
		mi.mesh = s
		mi.material_override = mat
		add_child(mi)
		mi.position = Vector3(sin(a) * 11.5, -3.0, cos(a) * 11.5)
		_fog.append(mi)
		var tw := mi.create_tween()
		tw.tween_property(mi, "position", Vector3(sin(a) * 9.5, 1.2, cos(a) * 9.5), randf_range(2.5, 4.0)).set_trans(Tween.TRANS_SINE)


func walk_to_crystal() -> void:
	_fistik.rotation.y = 0.0
	var tw := create_tween()
	tw.tween_property(_fistik, "position", Vector3(0, 0, -0.6), 1.6)
	tw.parallel().tween_method(func(k: float) -> void: _fistik.position.y = absf(sin(k * 18.0)) * 0.12, 0.0, 1.0, 1.6)
	tw.tween_property(_fistik, "rotation:y", PI, 0.3)


func quills_glow() -> void:
	Effects.sparkle(self, _fistik.global_position + Vector3.UP * 1.2, Tokens.color("honey"), 18)
	_fistik.rotation.y = 0.0
	var tw := create_tween()
	tw.tween_property(_fistik, "scale", Vector3.ONE * 1.12, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_fistik, "position:z", -0.95, 0.3)


func shatter() -> void:
	var at := _crystal.global_position
	_crystal.visible = false
	Effects.ring(self, at, 8.0, Tokens.color("honey"), 0.8)
	for i in SPARKS.size():
		var shard := Toon.part(self, "sphere", Vector3(0.9, 1.3, 0.9), SPARKS[i], at, Vector3.ZERO, 0.7, 0.05)
		var light := OmniLight3D.new()
		light.light_color = Tokens.color(SPARKS[i])
		light.light_energy = 2.0
		light.omni_range = 5.0
		shard.add_child(light)
		var a := -PI * 0.8 + PI * 1.6 * i / 4.0
		var far := Vector3(sin(a) * 40.0, 24.0 + i * 2.0, -cos(a) * 30.0 - 10.0)
		var tw := shard.create_tween()
		tw.tween_property(shard, "global_position", at + Vector3.UP * 3.0, 0.4).set_trans(Tween.TRANS_BACK)
		tw.tween_property(shard, "global_position", far, 3.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(shard.queue_free)
	for f in _fog:
		var tw := f.create_tween()
		var out := f.position * 1.8 + Vector3.DOWN * 4.0
		tw.tween_property(f, "position", out, 1.6).set_ease(Tween.EASE_OUT)


func petrify() -> void:
	var at := _fistik.position
	var rot := _fistik.rotation
	Effects.sparkle(self, _fistik.global_position + Vector3.UP, Tokens.color("panel"), 16)
	_fistik.queue_free()
	_fistik = FistikModel.build(true)
	add_child(_fistik)
	_fistik.position = at
	_fistik.rotation = rot
	_fistik.rotation.y = 0.0
	_fistik.scale = Vector3.ONE * 1.12
