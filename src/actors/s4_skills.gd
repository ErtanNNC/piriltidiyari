class_name S4Skills
extends RefCounted
## Season 4 skills (growing, sharing, cheering), used by `Player.use_skill`:
## Yonca's Tohum Ekme and the skill each keeper learns at level 5. Returns
## false for a skill that isn't one of these.


static func use(p: Player, id: String) -> bool:
	var world := p.get_parent()
	var at := p.global_position
	var fwd := Vector3(sin(p.model.rotation.y), 0, cos(p.model.rotation.y))
	var d := GameState.data
	match id:
		"tohum_ekme":
			# a seed at your feet: a flower that heals whoever stands by it
			_seed_flower(world, at + fwd * 1.4, Tokens.color("spark-green"))
		"takim_pencesi":
			# the last strike is shared: a hit all round, then both are stronger
			Effects.ring(world, at + Vector3.UP * 0.6, 3.0, Tokens.color("berry"), 0.4)
			p._hit_around(3.0, d.power, 4.0)
			GameState.set_buff_until("guc", GameState.clock + Skills.TEAM_TIME)
			_cheer(p, Skills.CHEER_RADIUS)
		"bal_paylasimi":
			# honey for everyone: a good piece of HP back, dazed ones calm
			d.heal(int(d.max_hp * Skills.SHARE_HEAL))
			Effects.ring(world, at + Vector3.UP * 0.4, Skills.CHEER_RADIUS, Tokens.color("honey"), 0.6)
			Effects.sparkle(world, at + Vector3.UP * 1.4, Tokens.color("honey"), 16)
			_cheer(p, Skills.CHEER_RADIUS)
		"alkis_findigi":
			# a nut that lands ahead and claps there: thorns draw back
			var land := at + fwd * Skills.NUT_THROW
			var nut := Toon.part(world, "sphere", Vector3(0.3, 0.3, 0.3), Color("#c98d5e"), at + Vector3.UP * 1.2)
			var tw := nut.create_tween()
			tw.tween_property(nut, "position", land + Vector3.UP * 0.3, 0.35)
			tw.tween_callback(func() -> void:
				nut.queue_free()
				Effects.ring(world, land + Vector3.UP * 0.2, 3.5, Tokens.color("spark-yellow"), 0.45)
				_applaud_at(p, land, 3.5))
		"gunes_damlasi":
			# a pool of sunlight: every seed bed in it grows at once
			Effects.ring(world, at + Vector3.UP * 0.3, Skills.SUN_RADIUS, Tokens.color("spark-yellow"), 0.7)
			TempLight.spawn(world, at, Skills.SUN_RADIUS, 6.0, Tokens.color("spark-yellow"))
			GameState.set_buff_until("gubre", GameState.clock + 6.0)
			for n in p.get_tree().get_nodes_in_group("seed_plot"):
				var sp := n as SeedPlot
				if sp and not sp.is_grown and not sp.yonca_only and sp.global_position.distance_to(at) <= Skills.SUN_RADIUS:
					sp.plant()
			d.heal(10)
		"ortak_ritim":
			# a shared beat: Dikenciler around stop to listen, hits grow stronger
			Audio.play("drum")
			for i in 3:
				Effects.ring(world, at + Vector3.UP * 0.3, Skills.CHEER_RADIUS * (i + 1) / 3.0, Tokens.color("hp"), 0.4 + i * 0.15)
			for n in p.get_tree().get_nodes_in_group("mob"):
				var m := n as Mob
				if m and m.global_position.distance_to(at) <= Skills.CHEER_RADIUS and m.state != "calm":
					m.lull()
			GameState.set_buff_until("guc", GameState.clock + Skills.TEAM_TIME)
		"kabuk_kalesi":
			# a shell big enough for two: nothing lands for a while, a little HP
			S3Skills._guard(p, Skills.FORT_GUARD, Tokens.color("spark-green"))
			d.heal(int(d.max_hp * 0.1))
		"bahce_cemberi":
			# a ring of flowers: thorns around draw back, everyone feels better
			for k in 8:
				var a := TAU * k / 8.0
				Effects.sparkle(world, at + Vector3(cos(a), 0.3, sin(a)) * 3.0, Tokens.color(["berry", "spark-yellow", "sky", "honey"][k % 4]), 6)
			Effects.ring(world, at + Vector3.UP * 0.3, Skills.CHEER_RADIUS, Tokens.color("spark-green"), 0.6)
			_applaud_at(p, at, Skills.CHEER_RADIUS)
			d.heal(int(d.max_hp * 0.15))
		_:
			return false
	return true


## Everything applaudable or dazed within `r` of `at` is cheered.
static func _applaud_at(p: Player, at: Vector3, r: float) -> void:
	for n in p.get_tree().get_nodes_in_group("applaudable"):
		var a := n as Node3D
		if a and a.has_method("applauded") and a.global_position.distance_to(at) <= maxf(r, float(a.get_meta("clap_reach", r)) - 1.0):
			a.call("applauded", p)
	for n in p.get_tree().get_nodes_in_group("dazed"):
		var m := n as Node3D
		if m and m.has_method("breathe_calm") and m.global_position.distance_to(at) <= r:
			m.call("breathe_calm")
	if p.clap:
		p.clap.cool_down()


## A cheer for those around: dazed ones calm, the Diken barı eases.
static func _cheer(p: Player, r: float) -> void:
	for n in p.get_tree().get_nodes_in_group("dazed"):
		var m := n as Node3D
		if m and m.has_method("breathe_calm") and m.global_position.distance_to(p.global_position) <= r:
			m.call("breathe_calm")
	if p.clap:
		p.clap.thorn = ThornRules.after_clap(p.clap.thorn)


## Yonca's flower: stands for a while and heals the keeper beside it.
static func _seed_flower(world: Node, at: Vector3, col: Color) -> void:
	var f := Node3D.new()
	world.add_child(f)
	f.global_position = at
	Toon.part(f, "cylinder", Vector3(0.1, 0.9, 0.1), Color("#4a9a5a"), Vector3(0, 0.45, 0))
	Toon.part(f, "sphere", Vector3(0.7, 0.4, 0.7), Color("#fff7ea"), Vector3(0, 1.0, 0), Vector3.ZERO, 0.6, 0.03)
	Toon.part(f, "sphere", Vector3(0.3, 0.3, 0.3), Color("#ffd23a"), Vector3(0, 1.1, 0), Vector3.ZERO, 1.2, 0.0)
	f.scale = Vector3.ONE * 0.1
	f.create_tween().tween_property(f, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Effects.sparkle(world, at + Vector3.UP, col, 10)
	var t := Timer.new()
	t.wait_time = 1.5
	t.autostart = true
	f.add_child(t)
	t.timeout.connect(func() -> void:
		var p := f.get_tree().get_first_node_in_group("player") as Player
		var d := GameState.data
		if p and p.global_position.distance_to(f.global_position) < 3.2 and d.hp < d.max_hp and not p.asleep:
			d.heal(maxi(3, d.max_hp / 20))
			Effects.sparkle(world, p.global_position + Vector3.UP * 1.4, col, 4))
	f.get_tree().create_timer(Skills.SEED_FLOWER_TIME, false).timeout.connect(func() -> void:
		if is_instance_valid(f):
			f.queue_free())
