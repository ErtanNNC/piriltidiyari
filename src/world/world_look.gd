class_name WorldLook
extends RefCounted
## Sky, ambient light and the sun/moon for a mood. Shared by every level.
##   aksam  – festival evening (Sahne 1)
##   pus    – the grey Pus night (Sahne 2–3)
##   kule   – tower top in the Pus, cold and windy (Sahne 4–5)
##   sabah  – morning after (Sahne 6, Bölüm 0)
##   orman  – Fısıltı Ormanı (Bölüm 1)
##   magara – Şekerleme Mağaraları (Bölüm 2), dark
##   liman  – Bulut Limanı (Bölüm 3), floating islands over clouds
##   dag    – Uyku Dağı (Bölüm 4), snowy sleepy dusk


const SKY_SHADER := preload("res://src/world/sky.gdshader")

## Sky per mood: [top, horizon, bottom, cloud, cloud shade, cloud amount,
## stars, sun color, sun size, cloud shadow on the ground]
const SKIES := {
	"aksam": ["#3a3478", "#d99ac0", "#2b2950", "#c9b0dc", "#7d6aa8", 0.35, 0.7, "#fff2d8", 0.0008, 0.0],
	"pus": ["#4a4858", "#77738a", "#3a3848", "#8e8a9c", "#5e5a6e", 0.75, 0.0, "#d8d4e8", 0.0, 0.0],
	"kule": ["#34324a", "#6a6684", "#2e2c40", "#7e7a96", "#4e4a66", 0.7, 0.15, "#d8d4e8", 0.0, 0.0],
	"sabah": ["#6fb2f0", "#eaf6ff", "#cfe6ff", "#ffffff", "#c8d8f2", 0.45, 0.0, "#fff4d0", 0.0016, 0.22],
	"orman": ["#3d6f62", "#b7d9b8", "#22362e", "#e2f0dc", "#9cbca8", 0.35, 0.0, "#fff6d8", 0.0014, 0.16],
	"liman": ["#4f9ff0", "#e2f2ff", "#8fc4f2", "#ffffff", "#c6dcf4", 0.5, 0.0, "#fff4d0", 0.0016, 0.2],
	"dag": ["#8494d4", "#f2e6f2", "#9fadd6", "#ffffff", "#c8cdec", 0.4, 0.1, "#fff0e0", 0.0013, 0.12],
	"kumsal": ["#1e2a5e", "#5a6aa8", "#141c40", "#8a96c8", "#3a4880", 0.3, 0.75, "#e8eeff", 0.0009, 0.05],
	"ada": ["#1a2658", "#56689f", "#121a3c", "#8a96c8", "#364478", 0.3, 0.8, "#e8eeff", 0.0009, 0.05],
	"kanyon": ["#d9845e", "#ffe2bf", "#e8a27c", "#fff4e6", "#f2c1a0", 0.4, 0.05, "#fff0d8", 0.0012, 0.14],
	"kale": ["#100d24", "#4a3f72", "#1e1b30", "#3e3666", "#2a2448", 0.4, 0.85, "#e8e0ff", 0.0009, 0.0],
}


## A ground detail map (assets/textures/<name>.png, grey around 0.5) on every
## floor and path of the scene: sand grains, pebbles, cracks. Floors keep
## their own colours; only the detail is added.
static func ground_detail(scene: Node3D, name: String, strength := 0.5, scale := 0.18) -> void:
	var tex := load("res://assets/textures/%s.png" % name) as Texture2D
	if tex == null:
		return
	await scene.get_tree().process_frame
	if not is_instance_valid(scene):
		return
	var floors: Array = []
	var paths: Array = []
	Decor._collect(scene, floors, paths)
	for f: Dictionary in floors + paths:
		var mi := f["mi"] as MeshInstance3D
		var mat := mi.material_override as ShaderMaterial
		if mat == null or mat.get_shader_parameter("albedo") == null:
			continue
		mat = mat.duplicate() as ShaderMaterial
		mat.set_shader_parameter("ground_tex", tex)
		mat.set_shader_parameter("ground_strength", strength)
		mat.set_shader_parameter("ground_scale", scale)
		mi.material_override = mat


## The mood of the scene being played (footprints, dust colors...).
static var current_mood := ""


static func add(parent: Node, mood: String) -> Environment:
	current_mood = mood
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_hdr_threshold = 1.2
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.shadow_enabled = true
	# one shadow pass over what the camera sees (the default is four over 100 m)
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 60.0
	match mood:
		"aksam":
			env.background_color = Color("#2b2950")
			env.ambient_light_color = Color("#8f86c9")
			env.ambient_light_energy = 0.45
			sun.light_color = Color("#dcd8ff")
			sun.light_energy = 0.55
		"pus", "kule":
			env.background_color = Color("#3a3848") if mood == "pus" else Color("#2e2c40")
			env.ambient_light_color = Color("#9a97a6")
			env.ambient_light_energy = 0.5
			env.fog_enabled = true
			env.fog_light_color = Tokens.color("pus")
			env.fog_density = 0.02 if mood == "pus" else 0.012
			env.fog_sky_affect = 0.0
			sun.light_color = Color("#c9c6d8")
			sun.light_energy = 0.45
		"orman":
			# deep green forest dusk; the Pus greys it until the lanterns burn
			env.background_color = Color("#22362e")
			env.ambient_light_color = Color("#9fc7a8")
			env.ambient_light_energy = 0.42
			env.fog_enabled = true
			env.fog_light_color = Color("#6f8a7c")
			env.fog_density = 0.012
			env.fog_sky_affect = 0.0
			sun.light_color = Color("#e6f2d8")
			sun.light_energy = 0.55
			sun.rotation_degrees = Vector3(-60, 20, 0)
		"magara":
			# dark candy-crystal caves: almost no sky light; lanterns, crystals
			# and the keeper's own light do the work
			env.background_color = Color("#120f22")
			env.ambient_light_color = Color("#8077c0")
			env.ambient_light_energy = 0.5
			env.glow_intensity = 0.55
			env.glow_hdr_threshold = 0.9
			sun.light_color = Color("#b3a8e8")
			sun.light_energy = 0.3
			sun.shadow_enabled = false
		"liman":
			# Bulut Limanı: high sky over a sea of clouds, stormy while the Pus holds
			env.background_color = Color("#8fc4f2")
			env.ambient_light_color = Color("#c9dcf5")
			env.ambient_light_energy = 0.28
			env.glow_hdr_threshold = 1.4
			env.fog_enabled = true
			env.fog_light_color = Color("#bcd3ee")
			env.fog_density = 0.004
			env.fog_sky_affect = 0.0
			sun.light_color = Color("#fff3dc")
			sun.light_energy = 0.55
			sun.rotation_degrees = Vector3(-50, 25, 0)
		"dag":
			# Uyku Dağı: pale snowy dusk, soft and sleepy
			env.background_color = Color("#9fadd6")
			env.ambient_light_color = Color("#c9d0f0")
			env.ambient_light_energy = 0.26
			env.glow_hdr_threshold = 1.4
			env.fog_enabled = true
			env.fog_light_color = Color("#b8c2e2")
			env.fog_density = 0.005
			env.fog_sky_affect = 0.0
			sun.light_color = Color("#fff0e0")
			sun.light_energy = 0.42
			sun.rotation_degrees = Vector3(-40, 35, 0)
		"kumsal", "ada":
			# Titrek Kıyılar: a warm summer night on the beach, moonlit
			env.background_color = Color("#141c40")
			env.ambient_light_color = Color("#8b9de0")
			env.ambient_light_energy = 0.3
			env.glow_intensity = 0.6
			env.glow_hdr_threshold = 1.0
			env.fog_enabled = true
			env.fog_light_color = Color("#2a3870")
			env.fog_density = 0.006
			env.fog_sky_affect = 0.0
			sun.light_color = Color("#b8c8ff")
			sun.light_energy = 0.26
			sun.rotation_degrees = Vector3(-48, 150, 0)
		"kanyon":
			# Gümbür Kanyonu: warm late afternoon over red sandstone
			env.background_color = Color("#e8a27c")
			env.ambient_light_color = Color("#ffd9bd")
			env.ambient_light_energy = 0.3
			env.glow_hdr_threshold = 1.4
			env.fog_enabled = true
			env.fog_light_color = Color("#f0c4a2")
			env.fog_density = 0.004
			env.fog_sky_affect = 0.0
			sun.light_color = Color("#ffe6c8")
			sun.light_energy = 0.58
			sun.rotation_degrees = Vector3(-38, 40, 0)
		"kale":
			# Pus Kalesi: gloomy grey-purple, readable; sparks bring the color
			env.background_color = Color("#1e1b30")
			env.ambient_light_color = Color("#8a83b8")
			env.ambient_light_energy = 0.5
			env.glow_intensity = 0.5
			env.glow_hdr_threshold = 1.0
			env.fog_enabled = true
			env.fog_light_color = Color("#4a4568")
			env.fog_density = 0.01
			env.fog_sky_affect = 0.0
			sun.light_color = Color("#c9c0f0")
			sun.light_energy = 0.35
		"ev":
			# inside a cosy house: warm lamps, no sky
			env.background_color = Color("#2b2140")
			env.ambient_light_color = Color("#ffe6c4")
			env.ambient_light_energy = 0.55
			sun.light_color = Color("#fff0d8")
			sun.light_energy = 0.35
			sun.rotation_degrees = Vector3(-65, 20, 0)
			sun.shadow_enabled = false
		"sabah":
			env.background_color = Color("#cfe6ff")
			env.ambient_light_color = Color("#fff2dc")
			env.ambient_light_energy = 0.32
			sun.light_color = Color("#fff4dc")
			sun.light_energy = 0.6
			sun.rotation_degrees = Vector3(-40, 30, 0)
	_sky(env, mood)
	RenderingServer.global_shader_parameter_set("cloud_shadow", float(SKIES[mood][9]) if SKIES.has(mood) else 0.0)
	var we := WorldEnvironment.new()
	we.environment = env
	parent.add_child(we)
	parent.add_child(sun)
	var sway := Sway.new()
	sway.name = "Sway"
	parent.add_child(sway)
	if parent is Node3D:
		Weather.add(parent as Node3D, mood, env)
		AmbientLife.add(parent as Node3D, mood)
		Backdrop.add(parent as Node3D, mood)
	return env


## Replaces the flat background with the cartoon sky for this mood.
static func _sky(env: Environment, mood: String) -> void:
	if not SKIES.has(mood):
		return
	var k: Array = SKIES[mood]
	var m := ShaderMaterial.new()
	m.shader = SKY_SHADER
	m.set_shader_parameter("top_color", Color(String(k[0])))
	m.set_shader_parameter("horizon_color", Color(String(k[1])))
	m.set_shader_parameter("bottom_color", Color(String(k[2])))
	m.set_shader_parameter("cloud_color", Color(String(k[3])))
	m.set_shader_parameter("cloud_shade", Color(String(k[4])))
	m.set_shader_parameter("cloud_amount", float(k[5]))
	m.set_shader_parameter("star_amount", float(k[6]))
	m.set_shader_parameter("sun_color", Color(String(k[7])))
	m.set_shader_parameter("sun_size", float(k[8]))
	m.set_shader_parameter("sun_visible", 1.0 if float(k[8]) > 0.0 else 0.0)
	var sky := Sky.new()
	sky.sky_material = m
	# the sky only paints the background: ambient stays a flat color and
	# reflections are off, so the animated sky never re-bakes radiance
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED


const WATER_SHADER := preload("res://src/world/water.gdshader")
## kind -> [deep, light, speed, bob, sparkle, scale]
const WATERS := {
	"lake": ["#4fa3e0", "#d9f3ff", 1.0, 0.03, 1.0, 1.0],
	"syrup": ["#ff8fbd", "#ffe3f0", 0.45, 0.015, 0.6, 0.8],
	"ice": ["#b9def2", "#ffffff", 0.12, 0.0, 1.6, 0.7],
	"sea_night": ["#1d3570", "#7fb2ee", 0.6, 0.06, 1.3, 0.8],
}
static var _waters: Dictionary = {}


## Gives a flat water/syrup/ice surface the moving cartoon-water look.
static func water(mi: MeshInstance3D, kind: String) -> void:
	if not _waters.has(kind):
		var k: Array = WATERS[kind]
		var m := ShaderMaterial.new()
		m.shader = WATER_SHADER
		m.set_shader_parameter("deep", Color(String(k[0])))
		m.set_shader_parameter("light", Color(String(k[1])))
		m.set_shader_parameter("speed", float(k[2]))
		m.set_shader_parameter("bob", float(k[3]))
		m.set_shader_parameter("sparkle", float(k[4]))
		m.set_shader_parameter("scale", float(k[5]))
		_waters[kind] = m
	mi.material_override = _waters[kind]


static func sky_material(env: Environment) -> ShaderMaterial:
	if env and env.sky:
		return env.sky.sky_material as ShaderMaterial
	return null


## A solid block (ground piece, ledge, wall) with the toon look.
static func block(parent: Node, center: Vector3, size: Vector3, col: Variant, outline := 0.03) -> StaticBody3D:
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	c.shape = b
	body.add_child(c)
	parent.add_child(body)
	body.position = center
	Toon.part(body, "box", size, col, Vector3.ZERO, Vector3.ZERO, 0.0, outline)
	return body
