class_name PlayerData
extends RefCounted
## Everything the player owns or has done. Pure data + rules, no nodes,
## so it can be saved and tested headlessly.

signal stats_changed
signal piril_changed(total: int, delta: int)
signal items_changed
signal quest_changed(quest_id: String)
signal leveled_up(level: int)
signal flags_changed

var character_id := "fistik"
var level := 1
var xp := 0
var max_hp := 100
var hp := 100
var max_mp := 50
var mp := 50
var piril := 0
var items: Dictionary = {}    # item_id -> count
var quests: Dictionary = {}   # quest_id -> {state: "active"|"done", objectives: {id: bool}}
var flags: Dictionary = {}    # flag -> true
var sparks: Array[String] = []  # found spark colors, e.g. ["green"]


# --- stats --------------------------------------------------------------

func add_xp(amount: int) -> void:
	xp += amount
	while level < Progression.MAX_LEVEL and xp >= Progression.xp_to_next(level):
		xp -= Progression.xp_to_next(level)
		level += 1
		max_hp += 10
		hp = max_hp
		mp = max_mp
		leveled_up.emit(level)
	if level >= Progression.MAX_LEVEL:
		xp = 0
	stats_changed.emit()


func heal(amount: int) -> void:
	hp = clampi(hp + amount, 0, max_hp)
	stats_changed.emit()


func add_piril(amount: int) -> void:
	piril += amount
	piril_changed.emit(piril, amount)


func spend_piril(amount: int) -> bool:
	if amount > piril:
		return false
	piril -= amount
	piril_changed.emit(piril, -amount)
	return true


# --- items --------------------------------------------------------------

func add_item(item_id: String, count := 1) -> void:
	items[item_id] = items.get(item_id, 0) + count
	items_changed.emit()


func remove_item(item_id: String, count := 1) -> bool:
	if items.get(item_id, 0) < count:
		return false
	items[item_id] -= count
	if items[item_id] <= 0:
		items.erase(item_id)
	items_changed.emit()
	return true


func has_item(item_id: String) -> bool:
	return items.get(item_id, 0) > 0


# --- quests -------------------------------------------------------------

## "none", "active", "ready" (all objectives done, not turned in) or "done".
func quest_state(quest_id: String) -> String:
	if not quests.has(quest_id):
		return "none"
	var q: Dictionary = quests[quest_id]
	if q["state"] == "done":
		return "done"
	for done: bool in q["objectives"].values():
		if not done:
			return "active"
	return "ready"


func start_quest(quest_def: Dictionary) -> bool:
	var id: String = quest_def["id"]
	if quests.has(id):
		return false
	var objectives := {}
	for o: Dictionary in quest_def.get("objectives", []):
		objectives[o["id"]] = false
	quests[id] = {"state": "active", "objectives": objectives}
	quest_changed.emit(id)
	return true


func complete_objective(quest_id: String, objective_id: String) -> bool:
	if quest_state(quest_id) != "active":
		return false
	var objectives: Dictionary = quests[quest_id]["objectives"]
	if not objectives.has(objective_id) or objectives[objective_id]:
		return false
	objectives[objective_id] = true
	quest_changed.emit(quest_id)
	return true


func objective_done(quest_id: String, objective_id: String) -> bool:
	return quests.get(quest_id, {}).get("objectives", {}).get(objective_id, false)


func objective_progress(quest_id: String) -> Vector2i:
	var objectives: Dictionary = quests.get(quest_id, {}).get("objectives", {})
	var done := 0
	for v: bool in objectives.values():
		if v:
			done += 1
	return Vector2i(done, objectives.size())


func complete_quest(quest_def: Dictionary) -> bool:
	var id: String = quest_def["id"]
	if quest_state(id) != "ready":
		return false
	quests[id]["state"] = "done"
	var rewards: Dictionary = quest_def.get("rewards", {})
	if rewards.has("piril"):
		add_piril(int(rewards["piril"]))
	if rewards.has("xp"):
		add_xp(int(rewards["xp"]))
	for item_id: String in rewards.get("items", []):
		add_item(item_id)
	quest_changed.emit(id)
	return true


# --- flags --------------------------------------------------------------

func set_flag(flag: String) -> void:
	flags[flag] = true
	flags_changed.emit()


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)
