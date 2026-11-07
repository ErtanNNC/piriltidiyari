class_name DialogueRules
extends RefCounted
## Picks which conversation an NPC has right now and applies its effects.
##
## An NPC file (content/<chapter>/dialogue/<npc>.json) holds ordered
## "variants". The first variant whose "when" holds is played; a variant
## without "when" always holds. After the last line its "then" is applied.
##
## when: {"quest": id, "state": "none"|"active"|"ready"|"done" (or a list),
##        "has_item": id, "objective_done": "quest/objective",
##        "objective_not_done": "quest/objective", "flag": f, "not_flag": f}
## then: {"start_quest": id, "deliver": {"quest", "objective", "item"},
##        "complete_quest": id, "set_flag": f, "give_piril": n, "give_xp": n,
##        "give_items": {id: n}, "advance": "quest/objective", "goto_scene": id}


static func pick_variant(npc_def: Dictionary, data: PlayerData) -> Dictionary:
	for v: Dictionary in npc_def.get("variants", []):
		if check(v.get("when", {}), data):
			return v
	return {}


static func check(when: Dictionary, data: PlayerData) -> bool:
	if when.has("quest"):
		var state := data.quest_state(when["quest"])
		var wanted: Variant = when.get("state", "active")
		if typeof(wanted) == TYPE_ARRAY:
			if not (wanted as Array).has(state):
				return false
		elif state != wanted:
			return false
	if when.has("has_item") and not data.has_item(when["has_item"]):
		return false
	if when.has("objective_done"):
		var parts: PackedStringArray = String(when["objective_done"]).split("/")
		if not data.objective_done(parts[0], parts[1]):
			return false
	if when.has("objective_not_done"):
		var parts: PackedStringArray = String(when["objective_not_done"]).split("/")
		if data.objective_done(parts[0], parts[1]):
			return false
	if when.has("flag") and not data.has_flag(when["flag"]):
		return false
	if when.has("not_flag") and data.has_flag(when["not_flag"]):
		return false
	return true


## Applies a variant's "then". `quests` maps quest id -> quest definition.
## Returns short event names the UI can react to (e.g. "quest_started").
static func apply(then: Dictionary, data: PlayerData, quests: Dictionary) -> Array[String]:
	var events: Array[String] = []
	if then.has("start_quest") and quests.has(then["start_quest"]):
		if data.start_quest(quests[then["start_quest"]]):
			events.append("quest_started")
	if then.has("deliver"):
		var d: Dictionary = then["deliver"]
		if data.can_advance(d["quest"], d["objective"]) and data.remove_item(d["item"]):
			data.complete_objective(d["quest"], d["objective"])
			events.append("delivered")
	if then.has("complete_quest") and quests.has(then["complete_quest"]):
		if data.complete_quest(quests[then["complete_quest"]]):
			events.append("quest_completed")
	if then.has("set_flag"):
		data.set_flag(then["set_flag"])
	if then.has("give_piril"):
		data.add_piril(int(then["give_piril"]))
	if then.has("give_xp"):
		data.add_xp(int(then["give_xp"]))
	for item_id: String in then.get("give_items", {}):
		data.add_item(item_id, int(then["give_items"][item_id]))
		events.append("item:" + item_id)
	if then.has("advance"):
		var parts: PackedStringArray = String(then["advance"]).split("/")
		if data.advance_objective(parts[0], parts[1]):
			events.append("advanced")
	if then.has("goto_scene"):
		events.append("goto:" + String(then["goto_scene"]))
	return events
