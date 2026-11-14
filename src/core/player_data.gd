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
## Hikâye Taşları in Season 1 (the design's 20 arrive over two seasons).
const STORY_STONES := 10
const POTIONS := ["bal_surubu", "yildiz_tozu", "cesaret_sekeri", "pus_kovucu", "nane_sekeri", "papatya_cayi", "sis_kalkani", "sicak_kakao", "atesbocegi_kavanozu", "cesaret_kurabiyesi"]

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
var equipped: Dictionary = {"outfit": "", "weapon": ""}   # worn outfit / held tool (item ids)
var powers: Dictionary = {}   # level-up powers: id -> rank (1..Powers.MAX_RANK)
var power_picks := 0          # level-ups whose power choice is still waiting
## The keeper's own starting numbers; max_hp/power/speed are derived from
## these (recompute_stats). Empty in saves from before version 2.
var base_stats: Dictionary = {"hp": 100, "power": 10, "speed": 6.0}
## 1 = Pırıltı Diyarı, 2 = Kor Vadisi (opens after "sezon1_bitti").
var season := 1
## Season 1's keeper {"id", "name", "look"}: Season 2's prologue is played as
## Mırıl, then the keepers come back (Sahne 6).
var s1_keeper: Dictionary = {}
## The keeper who finished Season 2 (Season 3's prologue is played as Hırıl).
var s2_keeper: Dictionary = {}
## Season 3's keeper, kept while Season 4's prologue is played as Tırıl.
var s3_keeper: Dictionary = {}
## How many times Yeni Oyun+ was started in this save (0 in older saves).
var ng_plus_runs := 0


# --- stats --------------------------------------------------------------

func add_xp(amount: int) -> void:
	xp += amount
	while level < Progression.MAX_LEVEL and xp >= Progression.xp_to_next(level):
		xp -= Progression.xp_to_next(level)
		level += 1
		max_hp += Progression.hp_gain(level)
		power += Progression.power_gain(level)
		power_picks += 1
		hp = max_hp
		mp = max_mp
		leveled_up.emit(level)
		learn_season_skill()
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
	base_stats = {"hp": 70 + int(stats.get("can", 3)) * 10, "power": 6 + int(stats.get("guc", 3)) * 2,
		"speed": 4.6 + float(stats.get("hiz", 3)) * 0.5}
	max_hp = int(base_stats["hp"])
	hp = max_hp
	max_mp = 50
	mp = max_mp
	power = int(base_stats["power"])
	speed = float(base_stats["speed"])
	skills = []
	var own := Skills.for_character(id)
	if own != "":
		skills.append(own)
	stats_changed.emit()
	skills_changed.emit()


## Bekçi Evi: become another keeper but keep the adventure. Level, XP,
## Pırıl, items, quests and sparks stay; HP/power/speed are rebuilt from the
## new keeper's stats plus the level-ups and the charms already bought.
## `item_defs` = Content.items (for charm bonuses).
func switch_keeper(id: String, stats: Dictionary, look: Dictionary, display_name: String, item_defs: Dictionary) -> void:
	var lv := level
	var x := xp
	var old_skills := skills.duplicate()
	choose_keeper(id, stats, look, display_name)
	level = lv
	xp = x
	recompute_stats(item_defs)
	# skills that belong to nobody stay; every other character's own and
	# season skills go (whoever the previous keeper was: Hırıl and Tırıl too)
	for s: String in old_skills:
		var whose := String((Skills.DEFS.get(s, {}) as Dictionary).get("owner", ""))
		if (whose == "" or whose == id) and not skills.has(s):
			skills.append(s)
	learn_season_skill()  # from level 5: the new keeper's skill of this season too
	hp = max_hp
	mp = max_mp
	stats_changed.emit()
	skills_changed.emit()


## The skill the L key / skill button uses right now ("" if none yet).
func active_skill() -> String:
	# Season 2: the calming skill takes the skill button once it's learned
	var s2 := Skills.season_for(character_id, season)
	if s2 != "" and skills.has(s2):
		return s2
	var own := Skills.for_character(character_id)
	if skills.has(own):
		return own
	return skills[0] if not skills.is_empty() else ""


## Season 2: from level 5 a keeper knows their calming skill (also lifts
## saves that were already past level 5). True when it was just learned.
func learn_season_skill() -> bool:
	if season < 2 or level < Skills.S2_LEVEL:
		return false
	var s2 := Skills.season_for(character_id, season)
	return s2 != "" and unlock_skill(s2)


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
	if free == -1:
		# every slot was used once: an emptied potion gives its place away
		for i in potions.size():
			if item_count(String(potions[i])) <= 0:
				free = i
				break
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


## The open quest to show on the HUD among `chapter_quests` (the loaded
## chapter's, in its order: main quest first). Open quests of other chapters
## are skipped: their text isn't loaded here.
func tracked_quest(chapter_quests: Dictionary) -> String:
	for id: String in chapter_quests:
		var s := quest_state(id)
		if s == "active" or s == "ready":
			return id
	return ""


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


# --- seasons ------------------------------------------------------------

## True when this save may start Season 2 (Season 1 done, not started yet).
func can_start_season2() -> bool:
	return has_flag("sezon1_bitti") and season < 2


## Season 2 (Kor Vadisi) starts here: the keepers left their power in the
## Fener, so it's level 1 again (no powers, no skills, no Pırıl). Owned
## outfits, tools and charms stay. The prologue is played as Mırıl.
func start_season2(item_defs: Dictionary) -> void:
	s1_keeper = {"id": character_id, "name": character_name, "look": character_look.duplicate()}
	season = 2
	character_id = "miril"
	character_name = "Mırıl"
	character_look = {}
	level = 1
	xp = 0
	powers = {}
	power_picks = 0
	skills = []
	piril = 0
	base_stats = {"hp": 90, "power": 9, "speed": 6.2}
	max_mp = 50
	recompute_stats(item_defs)
	hp = max_hp
	mp = max_mp
	scene_id = "s2_scene1"
	set_flag("sezon2")
	stats_changed.emit()
	skills_changed.emit()
	piril_changed.emit(piril, 0)


## True when this save may start Season 3 (Season 2 done, not started yet).
func can_start_season3() -> bool:
	return has_flag("sezon2_bitti") and season < 3


## Season 3 (Titrek Kıyılar) starts here: like Season 2, level 1 again with
## no powers, skills or Pırıl; owned outfits, tools and charms stay. The
## prologue is played as Hırıl, the little volcano drummer.
func start_season3(item_defs: Dictionary) -> void:
	s2_keeper = {"id": character_id, "name": character_name, "look": character_look.duplicate()}
	season = 3
	character_id = "hiril"
	character_name = "Hırıl"
	character_look = {}
	level = 1
	xp = 0
	powers = {}
	power_picks = 0
	skills = []
	piril = 0
	base_stats = {"hp": 95, "power": 9, "speed": 6.0}
	max_mp = 50
	recompute_stats(item_defs)
	hp = max_hp
	mp = max_mp
	scene_id = "s3_scene1"
	set_flag("sezon3")
	stats_changed.emit()
	skills_changed.emit()
	piril_changed.emit(piril, 0)


## True when this save may start Season 4 (Season 3 done, not started yet).
func can_start_season4() -> bool:
	return has_flag("sezon3_bitti") and season < 4


## Season 4 (Dikenli Bahçeler): like Season 3's start. Level 1 again, the
## prologue is played as Tırıl; owned outfits, tools and charms stay.
func start_season4(item_defs: Dictionary) -> void:
	s3_keeper = {"id": character_id, "name": character_name, "look": character_look.duplicate()}
	season = 4
	character_id = "tiril"
	character_name = "Tırıl"
	character_look = {}
	level = 1
	xp = 0
	powers = {}
	power_picks = 0
	skills = []
	piril = 0
	base_stats = {"hp": 90, "power": 9, "speed": 6.4}
	max_mp = 50
	recompute_stats(item_defs)
	hp = max_hp
	mp = max_mp
	scene_id = "s4_scene1"
	set_flag("sezon4")
	stats_changed.emit()
	skills_changed.emit()
	piril_changed.emit(piril, 0)


## Yeni Oyun+ keeps these flags (by prefix): what you own, side collections,
## finished seasons, the regatta and coral garden, NG+ itself, and the marks
## of Seasons 1 and 2. Every other flag is Season 3's story and is forgotten.
const NG_KEEP := ["owned_", "yan_", "sezon", "regata_", "mercan_", "ng_",
	"s2", "kor_", "bolum", "sahne", "prolog_", "tas_", "sandik_", "spot_", "ani_", "can_", "kapi_"]


## True when this save may start Yeni Oyun+: Season 3 is finished, and a
## Yeni Oyun+ already under way has reached the Fener Gecesi again.
func can_start_new_game_plus() -> bool:
	return has_flag("sezon3_bitti") and season >= 3 and (has_flag("sezon3_senlik") or not has_flag("ng_plus"))


## Yeni Oyun+: Season 3's story starts again from the keeper choice (El Ele).
## Level, XP, powers, skills, Pırıl, items, potions and everything owned or
## worn stay. `story_quests` = the ids of Season 3's quests (they are
## forgotten); flags go unless NG_KEEP holds them (pearls, torches, flares,
## veils and every story mark). Sets flag "ng_plus" (Hırıl and Tırıl can be
## chosen) and counts the run. Calling it again changes nothing more.
func start_new_game_plus(item_defs: Dictionary = {}, story_quests: Array = []) -> void:
	for f: String in flags.keys():
		var keep := false
		for pre: String in NG_KEEP:
			if f.begins_with(pre):
				keep = true
				break
		if not keep:
			flags.erase(f)
	flags.erase("sezon3_senlik")  # this run's Fener Gecesi is still ahead
	for q: Variant in story_quests:
		quests.erase(String(q))
	if not has_flag("ng_plus") or ng_plus_runs == 0 or scene_id != "s3_scene6":
		ng_plus_runs += 1  # a second call before the choice is the same run
	flags["ng_plus"] = true
	season = 3
	scene_id = "s3_scene6"
	if not item_defs.is_empty():
		recompute_stats(item_defs)
	hp = max_hp
	mp = max_mp
	flags_changed.emit()
	for q: Variant in story_quests:
		quest_changed.emit(String(q))
	stats_changed.emit()


# --- save ---------------------------------------------------------------

const SAVE_KEYS := ["character_id", "character_name", "character_look", "scene_id", "level", "xp",
	"max_hp", "hp", "max_mp", "mp", "power", "speed", "piril", "items", "potions", "skills", "quests", "flags", "sparks", "equipped", "powers", "power_picks", "base_stats", "season", "s1_keeper", "s2_keeper", "s3_keeper", "ng_plus_runs"]


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


## Raise an old save to the level its progress calls for (see
## Progression.catch_up_level). Each level gained waits for a power card.
func catch_up() -> void:
	if season >= 2:
		return  # Season 2 starts over at level 1 on purpose
	var target := Progression.catch_up_level(sparks.size(), has_flag("bolum0_bitti"))
	while level < target and level < Progression.MAX_LEVEL:
		add_xp(Progression.xp_to_next(level) - xp)
	# don't greet the keeper with a dozen card screens: three to choose,
	# the rest are taken for them
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	while power_picks > 3:
		Powers.pick(self, Powers.choices(powers, rng)[0]["id"])


# --- derived stats --------------------------------------------------------------

## The parts of max HP / power / speed that don't come from the keeper's base.
func _gains(item_defs: Dictionary) -> Dictionary:
	var g := {"hp": Powers.bonus_hp(powers), "power": 0, "speed": 0.0}
	for l in range(2, level + 1):
		g["hp"] += Progression.hp_gain(l)
		g["power"] += Progression.power_gain(l)
	for item_id: String in item_defs:
		var def: Dictionary = item_defs[item_id]
		if def.get("kind", "") == "charm" and has_flag("owned_" + item_id):
			g["hp"] += int(def.get("max_hp", 0))
			g["speed"] += float(def.get("speed", 0.0))
			g["power"] += int(def.get("power", 0))
	return g


## Rebuild max HP, power and speed from base stats + level + charms + powers,
## so they can never drift. Keeps current HP (capped at the new max).
func recompute_stats(item_defs: Dictionary) -> void:
	ensure_base(item_defs)
	var g := _gains(item_defs)
	max_hp = int(base_stats["hp"]) + int(g["hp"])
	power = int(base_stats["power"]) + int(g["power"])
	speed = float(base_stats["speed"]) + float(g["speed"])
	hp = mini(hp, max_hp)
	stats_changed.emit()


## Saves from before version 2 have no base stats: work them out backwards
## from the stored numbers (whatever they were, the keeper keeps them).
func ensure_base(item_defs: Dictionary) -> void:
	if base_stats.has("hp") and base_stats.has("power") and base_stats.has("speed"):
		return
	var g := _gains(item_defs)
	base_stats = {"hp": max_hp - int(g["hp"]), "power": power - int(g["power"]), "speed": speed - float(g["speed"])}
