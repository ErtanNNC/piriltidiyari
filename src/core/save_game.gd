class_name SaveGame
extends RefCounted
## Three save slots (Kayıt 1–3), written at every scene checkpoint and from
## the Mola menu. Slot 1 is user://kayit.json (the old single save), the others
## user://kayit_2.json and user://kayit_3.json. `slot` is the one in play.
## Crash-safe: the new save goes to a .tmp file first, the previous one is
## kept as .bak, then the .tmp is renamed into place. Loading tries the main
## file, then the .bak. Old saves are migrated step by step (VERSION).

const PATH := "user://kayit.json"
const SLOTS := 3
## The slot the current adventure saves into.
static var slot := 1
## 1: first release · 2: base stats, equipped, powers (Sezon 1 güncellemeleri)
const VERSION := 2

## Set by the last write(): OK or the error (the HUD tells the player).
static var last_error := OK


## File name stem of the slots (tests point it elsewhere).
static var base := "user://kayit"


## Bölüm seç plays in this slot, so the real saves stay as they are (it is
## not one of the three slots: Devam et / Kayıtlar never show it).
const PRACTICE := 9


## Has any of the three saves reached this flag (a finished season)?
static func any_has_flag(flag: String) -> bool:
	for s in range(1, SLOTS + 1):
		var f: Variant = load_dict(path_for(s)).get("flags", [])
		if (f is Array and flag in f) or (f is Dictionary and (f as Dictionary).has(flag)):
			return true
	return false


static func path_for(s: int) -> String:
	return base + ".json" if s <= 1 else "%s_%d.json" % [base, s]


static func current_path() -> String:
	return path_for(slot)


## Is there any save at all (any slot)?
static func exists() -> bool:
	for s in range(1, SLOTS + 1):
		if slot_exists(s):
			return true
	return false


static func slot_exists(s: int) -> bool:
	var p := path_for(s)
	return FileAccess.file_exists(p) or FileAccess.file_exists(p + ".bak")


## The slot saved most recently (0 = none), for "Devam et".
static func latest_slot() -> int:
	var best := 0
	var best_t := -1.0
	for s in range(1, SLOTS + 1):
		if not slot_exists(s):
			continue
		var t := float(summary(s).get("saved_at", 0))
		if t > best_t:
			best_t = t
			best = s
	return best


## What a slot card shows: {} for an empty slot, otherwise name, level,
## scene_id, piril, sparks, saved_at (unix seconds).
static func summary(s: int) -> Dictionary:
	var d := load_dict(path_for(s))
	if d.is_empty():
		return {}
	var t: float = d.get("saved_at", 0.0)
	if t <= 0.0 and FileAccess.file_exists(path_for(s)):
		t = FileAccess.get_modified_time(path_for(s))
	return {"name": d.get("character_name", ""), "level": int(d.get("level", 1)),
		"scene_id": d.get("scene_id", "scene1"), "piril": int(d.get("piril", 0)),
		"sparks": (d.get("sparks", []) as Array).size() if d.get("sparks") is Array else 0,
		"saved_at": t}


static func write(data: PlayerData, path := "") -> Error:
	if path == "":
		path = current_path()
	var d := data.to_dict()
	d["version"] = VERSION
	d["saved_at"] = Time.get_unix_time_from_system()
	last_error = write_atomic(path, JSON.stringify(d, "\t"))
	return last_error


## temp file + keep the last good save as .bak + rename into place.
static func write_atomic(path: String, text: String) -> Error:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	if not f.store_string(text):
		f.close()
		return ERR_FILE_CANT_WRITE
	f.close()
	var full := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var bak := full + ".bak"
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(bak)
		DirAccess.rename_absolute(full, bak)
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), full)


## The newest loadable save as a migrated Dictionary ({} = none).
static func load_dict(path := "") -> Dictionary:
	if path == "":
		path = current_path()
	for p: String in [path, path + ".bak"]:
		if not FileAccess.file_exists(p):
			continue
		var j := JSON.new()  # quiet: a broken file is expected after a crash
		if j.parse(FileAccess.get_file_as_string(p)) != OK:
			continue
		var parsed: Variant = j.data
		if parsed is Dictionary:
			var m := migrate(parsed)
			if not m.is_empty():
				return m
	return {}


static func read_into(data: PlayerData, path := "") -> bool:
	var d := load_dict(path)
	if d.is_empty():
		return false
	data.load_dict(d)
	return true


## Bring a save of any older version up to VERSION ({} if it's from a newer game).
static func migrate(d: Dictionary) -> Dictionary:
	var v := int(d.get("version", 1))
	if v > VERSION:
		return {}
	if v < 2:
		# v2 added equipped tools/outfits, level-up powers and base stats
		# (base stats are rebuilt from the save by PlayerData.ensure_base)
		if not d.has("equipped"):
			d["equipped"] = {"outfit": "", "weapon": ""}
		if not d.has("powers"):
			d["powers"] = {}
		if not d.has("power_picks"):
			d["power_picks"] = 0
		if not d.has("base_stats"):
			d["base_stats"] = {}
		v = 2
	d["version"] = v
	return d


## Remove a slot (default: the one in play).
static func clear(s := 0) -> void:
	var base := path_for(s if s > 0 else slot)
	for p: String in [base, base + ".bak", base + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
