extends Node3D
## Prolog · Sahne 1 – Yıldız Şenliği. Festival evening in Gökkuşağı Köyü.
## Teaches walking, jumping and talking; first quest and first Pırıl.
## Layout lives in the .tscn; this script adds ground, sky and light.

const VILLAGE_RADIUS := 26.0


func _ready() -> void:
	_environment()
	_ground()
	_bounds()
	GameState.data.flags_changed.connect(_on_flags_changed)
	if DevTools.demo != "":
		_run_demo.call_deferred(DevTools.demo)


func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#2b2950")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8f86c9")
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_hdr_threshold = 1.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color("#dcd8ff")
	moon.light_energy = 0.55
	moon.rotation_degrees = Vector3(-55, -35, 0)
	moon.shadow_enabled = true
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
	Toon.part(self, "cylinder", Vector3(VILLAGE_RADIUS * 2.4, 1.0, VILLAGE_RADIUS * 2.4), meadow, Vector3(0, -0.5, 0), Vector3.ZERO, 0.0, 0.0)
	# plaza and paths in cream
	var path := Tokens.color("panel-sunken").lerp(Tokens.color("honey-deep"), 0.18)
	Toon.part(self, "cylinder", Vector3(11, 0.06, 11), path, Vector3(0, 0.01, 0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(self, "box", Vector3(3, 0.06, 12), path, Vector3(0, 0.01, -9), Vector3.ZERO, 0.0, 0.0)
	Toon.part(self, "box", Vector3(3, 0.06, 14), path, Vector3(0, 0.01, 10), Vector3.ZERO, 0.0, 0.0)


## Soft invisible walls at the village edge. Later the Pus curtain lives here.
func _bounds() -> void:
	for n: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var body := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var w := WorldBoundaryShape3D.new()
		w.plane = Plane(-n, -VILLAGE_RADIUS)
		c.shape = w
		body.add_child(c)
		add_child(body)


func _on_flags_changed() -> void:
	if GameState.data.has_flag("sahne1_bitti"):
		get_tree().call_group("hud", "show_scene_card", "Sahne 2", "Gri Rüzgâr", "Çok yakında")


## Puts the game in a known state for screenshots (tools/screenshot.sh).
func _run_demo(which: String) -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	match which:
		"talk":
			player.global_position = $Tospik.global_position + Vector3(0, 0, 2.2)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("tospik_nine")
		"quest":
			GameState.data.start_quest(Content.quests["kayip_fenerler"])
			GameState.data.add_piril(12)
			GameState.data.add_item("fener_pembe")
			GameState.apply_dialogue_effects({"deliver": {"quest": "kayip_fenerler", "objective": "pembe", "item": "fener_pembe"}})
			player.global_position = $Tipis.global_position + Vector3(1.5, 0, 2.5)
		"kids":
			GameState.data.start_quest(Content.quests["kayip_fenerler"])
			GameState.data.add_item("fener_mavi")
			player.global_position = $Tipis.global_position + Vector3(0, 0, 1.8)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("tipis")
		"done":
			GameState.data.add_piril(30)
			GameState.data.set_flag("sahne1_bitti")
