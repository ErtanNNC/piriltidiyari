extends Node3D
## Bölüm 0 – Gökkuşağı Köyü ve Çayır (start). The new keeper's first steps:
## greet Fıstık's statue, calm the giant grumpy mushroom in the meadow, and
## get pointed to Fısıltı Ormanı. The prologue ends here.

const QUEST := "ilk_adim"

@onready var _hud: Hud = $Hud
var _boss: Mob


func _ready() -> void:
	Pus.set_amount(0.3 if not GameState.data.has_flag("bolum1_bitti") else 0.12)
	var sign := TravelSign.new()
	sign.target_scene = "chapter1"
	sign.title = "Fısıltı Ormanı"
	sign.requires_flag = "bolum0_bitti"
	sign.position = Vector3(-3.5, 0, -2.5)
	add_child(sign)
	var d := GameState.data
	d.quest_changed.connect(func(_id: String) -> void: _advance())
	d.flags_changed.connect(_on_flags)
	_advance()
	await get_tree().create_timer(1.9).timeout
	if d.quest_state(QUEST) == "none":
		var sk := d.active_skill()
		if sk != "":
			GameState.toast.emit("Özel yeteneğin: %s (L)" % Skills.DEFS[sk]["name"], "star")
		_hud.show_hint("Tospik Nine ile konuş", "Tospik Nine ile konuş")
	if DevTools.demo != "":
		_run_demo(DevTools.demo)


func _advance() -> void:
	var d := GameState.data
	if d.quest_state(QUEST) == "active" and d.objective_done(QUEST, "heykel") and _boss == null:
		_hud.show_hint("Çayıra git: köyün güneyi", "Çayıra git: köyün güneyi")
		_boss = Mob.spawn(self, "dev_mantar", Vector3(0, 0, 19))
		for at in [Vector3(-4, 0, 16), Vector3(4, 0, 16)]:
			Mob.spawn(self, "mantar", at)
		_boss.calmed.connect(func(_m: Mob) -> void:
			Pus.fade_to(self, 0.15, 2.0)
			_hud.show_hint("Tospik Nine'ye dön", ""))
	elif d.quest_state(QUEST) == "active" and not d.objective_done(QUEST, "heykel"):
		_hud.show_hint("Fıstık'ın heykelini ziyaret et", "")


func _on_flags() -> void:
	if not GameState.data.has_flag("bolum0_bitti") or GameState.data.has_flag("_son_gosterildi"):
		return
	GameState.data.set_flag("_son_gosterildi")
	_hud.clear_hint()
	SaveGame.write(GameState.data)
	await get_tree().create_timer(0.5).timeout
	_hud.show_scene_card("Prolog tamamlandı!", "Sıradaki: Fısıltı Ormanı", "Kuzeye, ormanın sönmüş fenerine")
	await get_tree().create_timer(4.0).timeout
	SceneFlow.go_to("chapter1")


func _run_demo(which: String) -> void:
	var player: Player = _hud.player()
	match which:
		"skills":
			var d := GameState.data
			var mobs: Array[Mob] = []
			for at in [Vector3(0, 0, 3.5), Vector3(1.5, 0, 4.5), Vector3(-1.5, 0, 4.5)]:
				mobs.append(Mob.spawn(self, "dev_mantar", at))
			player.global_position = Vector3(0, 0, 2)
			player.model.rotation.y = 0.0
			await get_tree().create_timer(0.3).timeout
			d.take_damage(30)
			var hp_before := d.hp
			var before := mobs.map(func(m: Mob) -> int: return m.hp)
			player.use_skill()
			await get_tree().create_timer(1.0).timeout
			var after := mobs.map(func(m: Mob) -> int: return m.hp)
			var shield_test := player.hurt(20, player.global_position + Vector3.FORWARD)
			print("SKILL %s mp=%d mobs %s -> %s hp %d -> %d hurt_while_shield=%s" % [d.active_skill(), d.mp, before, after, hp_before, d.hp, shield_test])
			# double jump
			player.global_position = Vector3(8, 0, 0)
			await get_tree().create_timer(0.4).timeout
			var top := 0.0
			Input.action_press("jump")
			await get_tree().physics_frame
			Input.action_release("jump")
			await get_tree().create_timer(0.25).timeout
			Input.action_press("jump")
			await get_tree().physics_frame
			Input.action_release("jump")
			for i in 60:
				top = maxf(top, player.global_position.y)
				await get_tree().physics_frame
			print("JUMP top=%.2f" % top)
			get_tree().quit()
		"walk":
			player.global_position = Vector3(0, 0, 2)
		"meadow":
			var d := GameState.data
			d.start_quest(Content.quests[QUEST])
			d.complete_objective(QUEST, "heykel")
			player.global_position = Vector3(0, 0, 11)
