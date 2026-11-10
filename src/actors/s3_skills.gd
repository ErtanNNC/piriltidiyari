class_name S3Skills
extends RefCounted
## Season 3 skills (light and hands), used by `Player.use_skill`: Hırıl's
## Gümbür Dalgası, Tosbi's Kabuk Kalkanı and the six courage skills each
## keeper learns at level 5. Returns false for a skill that isn't one.


static func use(p: Player, id: String) -> bool:
	var world := p.get_parent()
	var at := p.global_position
	var fwd := Vector3(sin(p.model.rotation.y), 0, cos(p.model.rotation.y))
	match id:
		"gumbur_dalgasi":
			# a big slow drum wave: every Titrek around stops and listens
			Audio.play("drum")
			for i in 3:
				Effects.ring(world, at + Vector3.UP * 0.3, Skills.DRUM_WAVE * (i + 1) / 3.0, Tokens.color("hp"), 0.5 + i * 0.15)
			_listen_around(p, Skills.DRUM_WAVE)
		"kabuk_kalkani":
			_guard(p, Skills.SHELL_GUARD, Tokens.color("spark-green"))
		"onden_giden":
			# a short run ahead that leaves little lights behind
			for i in Skills.LEAD_LIGHTS:
				var t: Array = Skills.TEMP_LIGHT[id]
				TempLight.spawn(world, at + fwd * Skills.LEAD_STEP * (i + 1), t[0], t[1], Tokens.color("berry"))
			p.push(fwd * 16.0)
		"ayi_kucagi":
			Effects.ring(world, at + Vector3.UP * 0.8, 1.8, Tokens.color("leaf"), 0.5)
			var best: Titrek = null
			var best_d := Skills.BEAR_HUG
			for n in p.get_tree().get_nodes_in_group("titrek"):
				var t := n as Titrek
				if t and t.state != "calm" and t.global_position.distance_to(at) <= best_d:
					best = t
					best_d = t.global_position.distance_to(at)
			if best:
				best.breathe_calm()
			if p.ring:
				p.ring.warm()
		"fener_findigi":
			var t2: Array = Skills.TEMP_LIGHT[id]
			var land := at + fwd * Skills.NUT_THROW
			Effects.sparkle(world, at + Vector3.UP, Tokens.color("sky"), 6)
			TempLight.spawn(world, Vector3(land.x, at.y, land.z), t2[0], t2[1], Tokens.color("sky"))
		"gece_lambasi":
			var t3: Array = Skills.TEMP_LIGHT[id]
			TempLight.spawn(world, at, t3[0], t3[1], Tokens.color("xp"))
			GameState.data.heal(Skills.LAMP_HEAL)
		"ritim_kalkani":
			Audio.play("drum")
			Effects.ring(world, at + Vector3.UP * 0.3, Skills.RHYTHM_SHIELD, Tokens.color("hp"), 0.5)
			_listen_around(p, Skills.RHYTHM_SHIELD)
			_guard(p, 2.0, Tokens.color("hp"))
		"kabuk_yuvasi":
			# tucked into the shell: safe, warm, and those around feel safe too
			_guard(p, Skills.SHELL_GUARD, Tokens.color("spark-green"))
			if p.ring:
				p.ring.warm()
			_listen_around(p, 4.0)
		_:
			return false
	return true


static func _listen_around(p: Player, radius: float) -> void:
	for n in p.get_tree().get_nodes_in_group("titrek"):
		var t := n as Titrek
		if t and t.global_position.distance_to(p.global_position) <= radius:
			t.listen()


static func _guard(p: Player, seconds: float, col: Color) -> void:
	p._guard_until = Time.get_ticks_msec() / 1000.0 + seconds
	Effects.ring(p.get_parent(), p.global_position + Vector3.UP * 0.9, 1.5, col, seconds)
	var tw := p.create_tween()
	tw.tween_property(p.model, "scale", Vector3(1.1, 0.85, 1.1), 0.2)
	tw.tween_interval(maxf(seconds - 0.5, 0.1))
	tw.tween_property(p.model, "scale", Vector3.ONE, 0.3)
