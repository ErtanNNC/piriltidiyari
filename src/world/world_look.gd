class_name WorldLook
extends RefCounted
## Sky, ambient light and the sun/moon for a mood. Shared by every level.
##   aksam  – festival evening (Sahne 1)
##   pus    – the grey Pus night (Sahne 2–3)
##   kule   – tower top in the Pus, cold and windy (Sahne 4–5)
##   sabah  – morning after (Sahne 6, Bölüm 0)


static func add(parent: Node, mood: String) -> Environment:
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
		"sabah":
			env.background_color = Color("#cfe6ff")
			env.ambient_light_color = Color("#fff2dc")
			env.ambient_light_energy = 0.45
			sun.light_color = Color("#fff4dc")
			sun.light_energy = 0.75
			sun.rotation_degrees = Vector3(-40, 30, 0)
	var we := WorldEnvironment.new()
	we.environment = env
	parent.add_child(we)
	parent.add_child(sun)
	return env


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
