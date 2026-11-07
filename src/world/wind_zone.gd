class_name WindZone
extends Node3D
## Storm gusts over an island. Every few seconds arrows appear on the ground
## (the 0.8 s tell), then the wind pushes everyone that way for a while.
## Standing next to a shelter rock (group "shelter") keeps you safe.

signal gust_started(dir: Vector3)

@export var radius := 13.0
@export var strength := 4.0
@export var rest := 3.5
@export var gust_time := 2.0
var active := true
var directions: Array[Vector3] = [Vector3.RIGHT, Vector3.BACK, Vector3.LEFT, Vector3.FORWARD]
var _i := 0
var _blowing := false
var _dir := Vector3.ZERO
var _player: Player


func _ready() -> void:
	_cycle()


func _cycle() -> void:
	while is_inside_tree():
		await get_tree().create_timer(rest).timeout
		if not active or not is_inside_tree():
			continue
		await GameState.wait_dialogue_closed()
		_dir = directions[_i % directions.size()]
		_i += 1
		_tell(_dir)
		await get_tree().create_timer(Mob.TELEGRAPH).timeout
		if not active:
			continue
		Audio.play("wind")
		gust_started.emit(_dir)
		_blowing = true
		_streaks(_dir)
		await get_tree().create_timer(gust_time).timeout
		_blowing = false
		if _player:
			_player.wind = Vector3.ZERO


func _physics_process(_delta: float) -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		return
	if not _blowing:
		return
	var p := _player.global_position
	var flat := Vector2(p.x - global_position.x, p.z - global_position.z)
	if flat.length() > radius + 2.0 or absf(p.y - global_position.y) > 6.0:
		_player.wind = Vector3.ZERO
		return
	_player.wind = Vector3.ZERO if is_sheltered(p) else _dir * strength


func is_sheltered(p: Vector3) -> bool:
	for s in get_tree().get_nodes_in_group("shelter"):
		var n := s as Node3D
		if Vector2(p.x - n.global_position.x, p.z - n.global_position.z).length() < n.get_meta("shelter_radius", 2.4):
			return true
	return false


## Honey arrows pointing where the wind will blow.
func _tell(dir: Vector3) -> void:
	for k in 6:
		var at := global_position + Vector3(randf_range(-radius * 0.6, radius * 0.6), 0.08, randf_range(-radius * 0.6, radius * 0.6))
		var arrow := Node3D.new()
		get_parent().add_child(arrow)
		arrow.global_position = at
		arrow.look_at(at + dir, Vector3.UP)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Tokens.color("honey")
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var mi := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 0.6
		c.height = 1.2
		mi.mesh = c
		mi.material_override = mat
		mi.rotation_degrees.x = -90
		arrow.add_child(mi)
		var tw := arrow.create_tween()
		tw.tween_property(arrow, "global_position", at + dir * 1.5, Mob.TELEGRAPH)
		tw.parallel().tween_property(mat, "albedo_color:a", 0.2, Mob.TELEGRAPH)
		tw.tween_callback(arrow.queue_free)


func _streaks(dir: Vector3) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 1, 1, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for k in 14:
		var mi := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.05
		cap.height = 2.2
		mi.mesh = cap
		mi.material_override = mat
		get_parent().add_child(mi)
		var start := global_position - dir * radius + Vector3(randf_range(-radius, radius), randf_range(0.5, 3.0), randf_range(-radius, radius)) * Vector3(absf(dir.z) + 0.2, 1, absf(dir.x) + 0.2)
		mi.global_position = start
		mi.look_at(start + dir, Vector3.UP)
		mi.rotate_object_local(Vector3.RIGHT, PI / 2)
		var tw := mi.create_tween()
		tw.tween_interval(randf() * gust_time * 0.5)
		tw.tween_property(mi, "global_position", start + dir * radius * 2.0, 0.9)
		tw.tween_callback(mi.queue_free)
