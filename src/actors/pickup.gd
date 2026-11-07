class_name Pickup
extends Area3D
## Something to collect by walking into it: a Pırıl light drop or a quest
## item (e.g. a lost lantern). Bobs and spins so kids spot it.

@export var item_id := ""          ## empty = Pırıl
@export var amount := 1

var _visual: Node3D
var _t := randf() * TAU
var _taken := false
var _pull := 0.0
const MAGNET := 3.2


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var c := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.7
	c.shape = s
	c.position.y = 0.6
	add_child(c)
	_visual = Node3D.new()
	add_child(_visual)
	if item_id == "":
		Toon.part(_visual, "sphere", Vector3(0.36, 0.36, 0.36), "piril", Vector3(0, 0.6, 0), Vector3.ZERO, 0.5, 0.025)
		Toon.part(_visual, "cone", Vector3(0.3, 0.3, 0.3), "piril", Vector3(0, 0.84, 0), Vector3.ZERO, 0.5, 0.025)
	else:
		var col: String = Content.items.get(item_id, {}).get("color", "honey")
		_lantern(_visual, col)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	# Pırıl drifts to a nearby keeper like a little magnet
	if item_id == "" and not _taken:
		var p := get_tree().get_first_node_in_group("player") as Node3D
		if p:
			var to := p.global_position - global_position
			var d := to.length()
			if d < MAGNET and d > 0.05 and absf(to.y) < 0.8 and _clear_to(p):
				_pull = minf(_pull + delta * 14.0, 12.0)
				global_position += to / d * minf(_pull * delta, d)
			else:
				_pull = 0.0
	_visual.position.y = sin(_t * 2.5) * 0.12
	_visual.rotation.y += delta * 1.6


func _on_body_entered(body: Node3D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	if item_id == "":
		GameState.data.add_piril(amount)
		FloatText.spawn(get_parent(), global_position + Vector3.UP * 1.2, "+%d" % amount, Tokens.color("piril"))
	else:
		GameState.data.add_item(item_id, amount)
		Audio.play("coin")
		GameState.toast.emit("%s bulundu!" % Content.item_name(item_id), "lantern")
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


static func _lantern(parent: Node3D, col: String) -> void:
	Toon.part(parent, "cylinder", Vector3(0.42, 0.06, 0.42), "outline", Vector3(0, 0.3, 0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(parent, "sphere", Vector3(0.55, 0.62, 0.55), col, Vector3(0, 0.62, 0), Vector3.ZERO, 0.9, 0.03)
	Toon.part(parent, "cylinder", Vector3(0.3, 0.08, 0.3), "outline", Vector3(0, 0.96, 0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(parent, "torus", Vector3(0.24, 0.04, 0.24), "outline", Vector3(0, 1.08, 0), Vector3(90, 0, 0), 0.0, 0.0)
	var light := OmniLight3D.new()
	light.light_color = Tokens.color(col)
	light.omni_range = 2.5
	light.light_energy = 1.5
	light.position.y = 0.62
	parent.add_child(light)


## Only pull through open air: keeper-only corners (behind walls, up on
## ledges, past barriers) must still need the keeper's ability.
func _clear_to(p: Node3D) -> bool:
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.6, p.global_position + Vector3.UP * 0.6)
	q.collision_mask = Player.LAYER_WORLD | Player.LAYER_LOW_BARRIER
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()
