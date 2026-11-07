class_name Village
extends Node3D
## Gökkuşağı Köyü: ground, paths, village edge, sky and light. Props are
## children in village.tscn. `mood` sets the lighting for each prologue scene.

const RADIUS := 26.0

@export_enum("aksam", "pus", "sabah") var mood := "aksam"

var environment: Environment
var moon: DirectionalLight3D


func _ready() -> void:
	_ground()
	_bounds()
	_light()


func _light() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.glow_enabled = true
	environment.glow_intensity = 0.35
	environment.glow_hdr_threshold = 1.2
	moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55, -35, 0)
	moon.shadow_enabled = true
	match mood:
		"aksam":
			environment.background_color = Color("#2b2950")
			environment.ambient_light_color = Color("#8f86c9")
			environment.ambient_light_energy = 0.45
			moon.light_color = Color("#dcd8ff")
			moon.light_energy = 0.55
		"pus":
			environment.background_color = Color("#3a3848")
			environment.ambient_light_color = Color("#9a97a6")
			environment.ambient_light_energy = 0.5
			environment.fog_enabled = true
			environment.fog_light_color = Tokens.color("pus")
			environment.fog_density = 0.02
			environment.fog_sky_affect = 0.0
			moon.light_color = Color("#c9c6d8")
			moon.light_energy = 0.45
		"sabah":
			environment.background_color = Color("#cfe6ff")
			environment.ambient_light_color = Color("#fff2dc")
			environment.ambient_light_energy = 0.45
			moon.light_color = Color("#fff4dc")
			moon.light_energy = 0.75
			moon.rotation_degrees = Vector3(-40, 30, 0)
	var we := WorldEnvironment.new()
	we.environment = environment
	add_child(we)
	add_child(moon)


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
	Toon.part(self, "cylinder", Vector3(11, 0.06, 11), path, Vector3(0, 0.01, 0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(self, "box", Vector3(3, 0.06, 12), path, Vector3(0, 0.01, -9), Vector3.ZERO, 0.0, 0.0)
	Toon.part(self, "box", Vector3(3, 0.06, 14), path, Vector3(0, 0.01, 10), Vector3.ZERO, 0.0, 0.0)


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
