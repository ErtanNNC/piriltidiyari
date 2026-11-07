class_name CrystalGate
extends Node3D
## Big grey crystal shards blocking a passage. open() sinks them.

@export var width := 3.6
@export var message := "Salonun bütün kristallerini yak"
var is_open := false
var _body: StaticBody3D
var _shards: Node3D
var _last_msg := -10.0


func _ready() -> void:
	_body = StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(width, 5.0, 1.0)
	c.shape = b
	c.position.y = 2.5
	_body.add_child(c)
	add_child(_body)
	_shards = Node3D.new()
	add_child(_shards)
	Toon.default_pus = 0.0
	for i in 4:
		var x := -width * 0.5 + (i + 0.5) * width / 4.0
		Toon.part(_shards, "cone", Vector3(1.0, 2.6 + (i % 2) * 0.8, 1.0), Color("#8d89a0"), Vector3(x, 1.3 + (i % 2) * 0.4, 0), Vector3(0, 0, (i - 1.5) * 8.0), 0.0, 0.03)
	Toon.default_pus = 1.0
	var sense := Area3D.new()
	sense.collision_layer = 0
	sense.collision_mask = 1
	var sc := CollisionShape3D.new()
	var sb := BoxShape3D.new()
	sb.size = Vector3(width + 1.0, 4.0, 3.0)
	sc.shape = sb
	sc.position.y = 2.0
	sense.add_child(sc)
	add_child(sense)
	sense.body_entered.connect(func(body: Node3D) -> void:
		if not is_open and body.is_in_group("player") and Time.get_ticks_msec() / 1000.0 - _last_msg > 3.0:
			_last_msg = Time.get_ticks_msec() / 1000.0
			GameState.toast.emit(message, "spark"))


func open(silent := false) -> void:
	if is_open:
		return
	is_open = true
	if not silent:
		Audio.play("door")
	_body.queue_free()
	if silent:
		_shards.queue_free()
		return
	var tw := _shards.create_tween()
	tw.tween_property(_shards, "position:y", -3.5, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(_shards.queue_free)
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 1.5, Tokens.color("spark-blue"), 20)
