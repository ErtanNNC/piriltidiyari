extends Node
## The running game's single PlayerData plus helpers the scenes share.

signal dialogue_requested(npc_id: String)
signal toast(text: String, icon: String)

var data := PlayerData.new()


## Asks the HUD to open an NPC's current conversation.
func talk_to(npc_id: String) -> void:
	dialogue_requested.emit(npc_id)


## A world event: "defeat" + mob kind, "reach" + area id, "talk" + npc id.
func notify(event_type: String, target: String) -> void:
	data.notify(event_type, target, Content.quests)


func apply_dialogue_effects(then: Dictionary) -> void:
	var events := DialogueRules.apply(then, data, Content.quests)
	for e in events:
		if e.begins_with("item:"):
			var id := e.substr(5)
			toast.emit("%s ×%d aldın" % [Content.item_name(id), int(then["give_items"][id])], "piril")
			continue
		if e.begins_with("goto:"):
			SceneFlow.go_to(e.substr(5))
			continue
		match e:
			"quest_started":
				toast.emit("Yeni görev: %s" % Content.quests[then["start_quest"]]["title"], "quest")
			"quest_completed":
				toast.emit("Görev tamam!", "star")
			"delivered":
				toast.emit("%s teslim edildi" % Content.item_name(then["deliver"]["item"]), "lantern")


## The quest the HUD tracker shows: the first active/ready one.
func tracked_quest() -> String:
	for id: String in data.quests:
		var s := data.quest_state(id)
		if s == "active" or s == "ready":
			return id
	return ""
