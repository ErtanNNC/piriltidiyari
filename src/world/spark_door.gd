class_name SparkDoor
extends Interactable
## A Pus-curtained archway in the castle. Show it the Kıvılcım of its color
## and the Pus gives way ("Dört Kıvılcım oyuncunun elinde parlar").

signal opened(door: SparkDoor)

@export var spark := "green"
@export var width := 4.0
var is_open := false
var _body: StaticBody3D
var _veil: Node3D


func _build() -> void:
	action_label = "Kıvılcımı göster"
	reach = 2.4
	var stone := Color("#6a6484")
	for side in [-1.0, 1.0]:
		Toon.part(self, "box", Vector3(1.0, 4.4, 1.2), stone, Vector3(side * (width * 0.5 + 0.5), 2.2, 0))
	Toon.part(self, "box", Vector3(width + 2.0, 0.8, 1.2), stone, Vector3(0, 4.6, 0))
	Toon.part(self, "sphere", Vector3(0.7, 0.9, 0.4), "spark-" + spark, Vector3(0, 4.6, 0.6), Vector3.ZERO, 1.4, 0.02)
	_veil = Node3D.new()
	add_child(_veil)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Tokens.color("pus").lerp(Tokens.color("spark-" + spark), 0.25)
	mat.albedo_color.a = 0.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 5:
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.9
		s.height = 2.0
		mi.mesh = s
		mi.material_override = mat
		mi.position = Vector3(-width * 0.5 + (i + 0.5) * width / 5.0, 0.9 + (i % 2) * 1.0, 0)
		mi.scale = Vector3(1.0, 1.4, 0.7)
		_veil.add_child(mi)
	_body = StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(width, 5.0, 1.0)
	c.shape = b
	c.position.y = 2.5
	_body.add_child(c)
	add_child(_body)
	if GameState.data.has_flag("kapi_" + spark):
		_open(true)


func use(_by: Node) -> void:
	if is_open:
		return
	if not GameState.data.sparks.has(spark):
		GameState.toast.emit("Bu kapı bir Kıvılcım daha istiyor", "spark")
		return
	GameState.data.set_flag("kapi_" + spark)
	_open(false)
	GameState.notify("light", "kivilcim_kapisi")
	opened.emit(self)


func _open(instant: bool) -> void:
	is_open = true
	_body.queue_free()
	done()
	if instant:
		_veil.queue_free()
		return
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 2.0, Tokens.color("spark-" + spark), 20)
	Effects.ring(get_parent(), global_position + Vector3.UP * 0.3, 5.0, Tokens.color("spark-" + spark), 0.6)
	var tw := _veil.create_tween()
	tw.tween_property(_veil, "scale", Vector3(1.2, 0.01, 1.2), 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_veil.queue_free)
