extends Node
## Loads a chapter's content pack: content/<chapter>/chapter.json lists its
## quests and dialogue files, so adding story means adding data, not code.

var chapter: Dictionary = {}
var quests: Dictionary = {}     # id -> quest def
var npcs: Dictionary = {}       # npc id -> dialogue def
var items: Dictionary = {}      # id -> item def
var speakers: Dictionary = {}   # id -> {name, color}
var keepers: Dictionary = {}    # id -> keeper candidate (content/keepers.json)
## Season 2: new keepers (Tıpış), the select order and the keepers' lines
## (content/keepers_s2.json).
var keepers_s2: Dictionary = {}
var shops: Dictionary = {}      # id -> {title, items: [{id, price, once?}]}
var barks: Dictionary = {}      # id -> [lines]: short monologues and asides
## Season 2 side collections (content/s2_side.json, see SideQuests).
var side: Dictionary = {}


func _init() -> void:
	items = read_json("res://content/items.json").get("items", {})
	speakers = read_json("res://content/speakers.json").get("speakers", {})
	keepers = read_json("res://content/keepers.json").get("keepers", {})
	keepers_s2 = read_json("res://content/keepers_s2.json")
	side = read_json("res://content/s2_side.json")
	load_chapter("prologue")


func load_chapter(chapter_id: String) -> void:
	var root := "res://content/%s" % chapter_id
	chapter = read_json("%s/chapter.json" % root)
	quests.clear()
	npcs.clear()
	for q: String in chapter.get("quests", []):
		var def := read_json("%s/quests/%s.json" % [root, q])
		quests[def["id"]] = def
	barks = read_json("%s/%s.json" % [root, chapter["barks"]]).get("barks", {}) if chapter.has("barks") else {}
	shops = read_json("%s/%s.json" % [root, chapter["shop"]]).get("shops", {}) if chapter.has("shop") else {}
	for n: String in chapter.get("dialogue", []):
		var def := read_json("%s/dialogue/%s.json" % [root, n])
		npcs[def["npc"]] = def


## Any keeper (Season 1's four or Season 2's new ones).
func keeper(id: String) -> Dictionary:
	if keepers.has(id):
		return keepers[id]
	return keepers_s2.get("keepers", {}).get(id, {})


func npc(npc_id: String) -> Dictionary:
	return npcs.get(npc_id, {})


## A color token safe to put text on (the design system forbids text on leaf).
static func text_safe(token: String) -> String:
	return "spark-green" if token == "leaf" else token


func item_name(item_id: String) -> String:
	return TranslationServer.translate(String(items.get(item_id, {}).get("name", item_id)))


func speaker(speaker_id: String) -> Dictionary:
	return speakers.get(speaker_id, {"name": speaker_id, "color": "honey"})


static func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Content: dosya yok %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Content: JSON okunamadı %s" % path)
		return {}
	return parsed
