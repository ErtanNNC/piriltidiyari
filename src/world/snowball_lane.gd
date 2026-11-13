class_name SnowballLane
extends Node3D
## A lane down a slope where big snowballs roll every few seconds. Honey
## circles along the lane warn 0.8 s before each one.

@export var top := Vector3.ZERO      ## global start
@export var bottom := Vector3.ZERO   ## global end
@export var interval := 3.4
@export var delay := 0.0
@export var damage := 10
var _t := 0.0


func _ready() -> void:
	_t = -delay


func _process(delta: float) -> void:
	_t += delta
	if _t >= interval:
		_t = 0.0
		_roll()


func _roll() -> void:
	await GameState.wait_dialogue_closed()
	for k in 4:
		Effects.warning(get_parent(), top.lerp(bottom, (k + 0.5) / 4.0), 1.0, Mob.TELEGRAPH)
	await get_tree().create_timer(Mob.TELEGRAPH, false).timeout
	var ball := Node3D.new()
	get_parent().add_child(ball)
	Toon.part(ball, "sphere", Vector3(1.8, 1.8, 1.8), MountainKit.SNOW, Vector3.ZERO)
	ball.global_position = top + Vector3.UP * 0.9
	var p: Player = get_tree().get_first_node_in_group("player")
	var t := 0.0
	var hit := false
	while t < 1.4:
		t += get_process_delta_time()
		ball.global_position = top.lerp(bottom, t / 1.4) + Vector3.UP * 0.9
		ball.rotate_x(get_process_delta_time() * 8.0)
		if p and not hit and p.global_position.distance_to(ball.global_position - Vector3.UP * 0.6) < 1.4:
			hit = p.hurt(damage, ball.global_position)
		await get_tree().process_frame
	var tw := ball.create_tween()
	tw.tween_property(ball, "scale", Vector3.ZERO, 0.25)
	tw.tween_callback(ball.queue_free)
	Effects.sparkle(get_parent(), bottom + Vector3.UP, Tokens.color("panel@light"), 8)
