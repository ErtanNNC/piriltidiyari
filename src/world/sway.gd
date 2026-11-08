class_name Sway
extends Node
## Trees in the wind: a tree's crown (leaf balls, fruits) is moved under a
## pivot at the top of the trunk and gently rocked, with slow gusts rolling
## across the world. One Sway node (added by WorldLook.add) moves them all.
##   Sway.crown(tree_root, from_y)  # every mesh child at or above from_y

static var _items: Array = []  # [pivot: Node3D, phase: float, amp: float]

var _t := 0.0


## Puts the mesh children of `root` whose position.y >= from_y under a new
## "Crown" pivot at (0, pivot_y, 0) and registers it. Returns the pivot.
static func crown(root: Node3D, from_y: float, pivot_y: float, amp := 0.04) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = "Crown"
	pivot.position = Vector3(0, pivot_y, 0)
	var kids: Array = []
	for c in root.get_children():
		if c is MeshInstance3D and (c as Node3D).position.y >= from_y:
			kids.append(c)
	root.add_child(pivot)
	for c: Node3D in kids:
		root.remove_child(c)
		pivot.add_child(c)
		c.position -= pivot.position
	add(pivot, amp)
	return pivot


static func add(pivot: Node3D, amp := 0.04) -> void:
	_items.append([pivot, randf() * TAU, amp])


func _process(delta: float) -> void:
	_t += delta
	var keep: Array = []
	for it: Array in _items:
		if not is_instance_valid(it[0]):
			continue
		var p: Node3D = it[0]
		keep.append(it)
		if not p.is_visible_in_tree():
			continue
		var ph: float = it[1]
		var amp: float = it[2]
		var at := p.global_position if p.is_inside_tree() else Vector3.ZERO
		# a gust rolls across the world now and then; trees lean with it
		var gust := 0.55 + 0.45 * sin(_t * 0.45 - at.x * 0.04 - at.z * 0.025)
		var rx := (sin(_t * 1.3 + ph) * 0.6 + gust * 0.5) * amp
		var rz := (sin(_t * 1.05 + ph * 1.7) * 0.7 + gust * 0.3) * amp
		p.rotation = Vector3(rx, 0.0, rz)
	_items = keep
