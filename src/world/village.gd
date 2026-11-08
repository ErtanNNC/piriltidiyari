class_name Village
extends Node3D
## Gökkuşağı Köyü: ground, paths, village edge, sky and light. Props are
## children in village.tscn. `mood` sets the lighting for each prologue scene.

const RADIUS := 26.0

@export_enum("aksam", "pus", "sabah") var mood := "aksam"

var environment: Environment


func _ready() -> void:
	_ground()
	_bounds()
	_light()
	Decor.auto(get_parent() if get_parent() is Node3D else self, "koy")


func _light() -> void:
	environment = WorldLook.add(self, mood)


func _ground() -> void:
	var meadow := Tokens.color("spark-green").lerp(Tokens.color("bg"), 0.15)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(80, 1, 80)
	col.shape = shape
	col.position.y = -0.5
	body.add_child(col)
	add_child(body)
	Toon.part(self, "cylinder", Vector3(RADIUS * 2.4, 1.0, RADIUS * 2.4), meadow, Vector3(0, -0.5, 0), Vector3.ZERO, 0.0, 0.0)
	var path := Tokens.color("panel-sunken").lerp(Tokens.color("honey-deep"), 0.18)
	# the round square sits a hair above the two paths: where they overlap the
	# tops are never level (no flicker where the road meets the square)
	Toon.part(self, "cylinder", Vector3(11, 0.06, 11), path, Vector3(0, 0.02, 0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(self, "box", Vector3(3, 0.06, 12), path, Vector3(0, 0.0, -9), Vector3.ZERO, 0.0, 0.0)
	Toon.part(self, "box", Vector3(3, 0.06, 14), path, Vector3(0, 0.0, 10), Vector3.ZERO, 0.0, 0.0)


## Soft invisible walls at the village edge.
func _bounds() -> void:
	for n: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var body := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var w := WorldBoundaryShape3D.new()
		w.plane = Plane(-n, -RADIUS)
		c.shape = w
		body.add_child(c)
		add_child(body)
