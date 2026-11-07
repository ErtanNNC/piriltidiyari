extends Node3D
## Prolog · Sahne 1 – Yıldız Şenliği. Festival evening in Gökkuşağı Köyü.
## Teaches walking, jumping and talking; first quest and first Pırıl.
## Layout lives in the .tscn; the shared village is scenes/prologue/village.tscn.

func _ready() -> void:
	if DevTools.demo != "":
		_run_demo.call_deferred(DevTools.demo)


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
