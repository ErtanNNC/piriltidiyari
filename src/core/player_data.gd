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
signal skills_changed

const POTION_SLOTS := 4
const POTIONS := ["bal_surubu", "yildiz_tozu", "cesaret_sekeri", "pus_kovucu"]

var character_id := "fistik"
var character_name := "Fıstık"
var character_look := {}       # chosen color variant / accessory
var scene_id := "scene1"       # checkpoint for "Devam et"
var level := 1
var xp := 0
var max_hp := 100
var hp := 100
var max_mp := 50
var mp := 50
var power := 10
var speed := 6.0
var piril := 0
var items: Dictionary = {}    # item_id -> count
var potions: Array = ["", "", "", ""]   # item ids in the 4 potion slots
var skills: Array = []        # unlocked skill ids
## quest_id -> {"state": "active"|"done", "objectives": {id: [progress, needed]}, "ordered": bool}
var quests: Dictionary = {}
var flags: Dictionary = {}
var sparks: Array = []        # found spark colors, e.g. ["green"]


# --- stats --------------------------------------------------------------

func add_xp(amount: int) -> void:
	xp += amount
	while level < Progression.MAX_LEVEL and xp >= Progression.xp_to_next(level):
		xp -= Progression.xp_to_next(level)
		level += 1
		max_hp += 10
		power += 2
		hp = max_hp
		mp = max_mp
		leveled_up.emit(level)
	if level >= Progression.MAX_LEVEL:
		xp = 0
	stats_changed.emit()


func heal(amount: int) -> void:
	hp = clampi(hp + amount, 0, max_hp)
	stats_changed.emit()


## Returns true when this hit put the player to sleep (hp reached 0).
func take_damage(amount: int) -> bool:
	hp = maxi(hp - amount, 0)
	stats_changed.emit()
	return hp == 0


func use_mp(amount: int) -> bool:
	if mp < amount:
		return false
	mp -= amount
	stats_changed.emit()
	return true


func restore_mp(amount: int) -> void:
	mp = clampi(mp + amount, 0, max_mp)
	stats_changed.emit()


func wake_up() -> void:
	hp = max_hp
	mp = max_mp
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


func add_spark(color: String) -> bool:
	if sparks.has(color):
		return false
	sparks.append(color)
	stats_changed.emit()
	return true


func unlock_skill(skill_id: String) -> bool:
	if skills.has(skill_id):
		return false
	skills.append(skill_id)
	skills_changed.emit()
	return true


## The new keeper chosen in Sahne 6. Stats (1–5) come from content/keepers.json:
## can → HP, guc → power, hiz → walking speed. Fresh at level 1; the village's
## Pırıl and potions stay.
func choose_keeper(id: String, stats: Dictionary, look: Dictionary, display_name: String) -> void:
	character_id = id
	character_look = look
	character_name = display_name
	level = 1
	xp = 0
	max_hp = 70 + int(stats.get("can", 3)) * 10
	hp = max_hp
	max_mp = 50
	mp = max_mp
	power = 6 + int(stats.get("guc", 3)) * 2
	speed = 4.6 + float(stats.get("hiz", 3)) * 0.5
	skills = []
	var own := Skills.for_character(id)
	if own != "":
		skills.append(own)
	stats_changed.emit()
	skills_changed.emit()


## The skill the L key / skill button uses right now ("" if none yet).
func active_skill() -> String:
	var own := Skills.for_character(character_id)
	if skills.has(own):
		return own
	return skills[0] if not skills.is_empty() else ""


# --- items --------------------------------------------------------------

func add_item(item_id: String, count := 1) -> void:
	items[item_id] = items.get(item_id, 0) + count
	if POTIONS.has(item_id):
		_slot_potion(item_id)
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


func item_count(item_id: String) -> int:
	return items.get(item_id, 0)


func _slot_potion(item_id: String) -> void:
	if potions.has(item_id):
		return
	var free := potions.find("")
	if free != -1:
		potions[free] = item_id


# --- quests -------------------------------------------------------------

## "none", "active", "ready" (all objectives done, not turned in) or "done".
func quest_state(quest_id: String) -> String:
	if not quests.has(quest_id):
		return "none"
	var q: Dictionary = quests[quest_id]
	if q["state"] == "done":
		return "done"
	for p: Array in q["objectives"].values():
		if p[0] < p[1]:
			return "active"
	return "ready"


func start_quest(quest_def: Dictionary) -> bool:
	var id: String = quest_def["id"]
	if quests.has(id):
		return false
	var objectives := {}
	for o: Dictionary in quest_def.get("objectives", []):
		objectives[o["id"]] = [0, int(o.get("count", 1))]
	quests[id] = {"state": "active", "objectives": objectives, "ordered": quest_def.get("ordered", false)}
	quest_changed.emit(id)
	return true


## The objective that can make progress now: in an ordered quest only the
## first unfinished one; otherwise any unfinished one.
func can_advance(quest_id: String, objective_id: String) -> bool:
	if quest_state(quest_id) != "active":
		return false
	var q: Dictionary = quests[quest_id]
	var objectives: Dictionary = q["objectives"]
	if not objectives.has(objective_id):
		return false
	var p: Array = objectives[objective_id]
	if p[0] >= p[1]:
		return false
	if q.get("ordered", false):
		for oid: String in objectives:
			if objectives[oid][0] < objectives[oid][1]:
				return oid == objective_id
	return true


func advance_objective(quest_id: String, objective_id: String, by := 1) -> bool:
	if not can_advance(quest_id, objective_id):
		return false
	var p: Array = quests[quest_id]["objectives"][objective_id]
	p[0] = mini(p[0] + by, p[1])
	quest_changed.emit(quest_id)
	return true


func complete_objective(quest_id: String, objective_id: String) -> bool:
	if not can_advance(quest_id, objective_id):
		return false
	var p: Array = quests[quest_id]["objectives"][objective_id]
	return advance_objective(quest_id, objective_id, p[1] - p[0])


func objective_done(quest_id: String, objective_id: String) -> bool:
	var p: Array = quests.get(quest_id, {}).get("objectives", {}).get(objective_id, [0, 1])
	return p[0] >= p[1]


func objective_count(quest_id: String, objective_id: String) -> Vector2i:
	var p: Array = quests.get(quest_id, {}).get("objectives", {}).get(objective_id, [0, 1])
	return Vector2i(p[0], p[1])


## Done objectives / all objectives.
func objective_progress(quest_id: String) -> Vector2i:
	var objectives: Dictionary = quests.get(quest_id, {}).get("objectives", {})
	var done := 0
	for p: Array in objectives.values():
		if p[0] >= p[1]:
			done += 1
	return Vector2i(done, objectives.size())


## A world event ("defeat" + mob kind, "reach" + area id, "talk" + npc id)
## advances every matching objective of the active quests.
func notify(event_type: String, target: String, quest_defs: Dictionary) -> void:
	for qid: String in quests.keys():
		if quest_state(qid) != "active" or not quest_defs.has(qid):
			continue
		for o: Dictionary in quest_defs[qid].get("objectives", []):
			if o.get("type", "") == event_type and o.get("target", "") == target:
				advance_objective(qid, o["id"])


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


# --- save ---------------------------------------------------------------

const SAVE_KEYS := ["character_id", "character_name", "character_look", "scene_id", "level", "xp",
	"max_hp", "hp", "max_mp", "mp", "power", "speed", "piril", "items", "potions", "skills", "quests", "flags", "sparks"]


func to_dict() -> Dictionary:
	var d := {"version": 1}
	for k: String in SAVE_KEYS:
		d[k] = get(k)
	return d


func load_dict(d: Dictionary) -> void:
	for k: String in SAVE_KEYS:
		if not d.has(k):
			continue
		var v: Variant = d[k]
		if typeof(get(k)) == TYPE_INT and typeof(v) == TYPE_FLOAT:
			v = int(v)
		set(k, v)
	# JSON turns ints into floats; quest progress is compared as ints.
	for q: Dictionary in quests.values():
		for oid: String in q["objectives"]:
			var p: Array = q["objectives"][oid]
			q["objectives"][oid] = [int(p[0]), int(p[1])]
	for k: String in items.keys():
		items[k] = int(items[k])
	stats_changed.emit()
	items_changed.emit()
	flags_changed.emit()
	piril_changed.emit(piril, 0)
