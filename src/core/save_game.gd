class_name SaveGame
extends RefCounted
## One save slot in user://kayit.json, written at every scene checkpoint.
## Crash-safe: the new save goes to a .tmp file first, the previous one is
## kept as .bak, then the .tmp is renamed into place. Loading tries the main
## file, then the .bak. Old saves are migrated step by step (VERSION).

const PATH := "user://kayit.json"
## 1: first release · 2: base stats, equipped, powers (Sezon 1 güncellemeleri)
const VERSION := 2

## Set by the last write(): OK or the error (the HUD tells the player).
static var last_error := OK


static func exists() -> bool:
	return FileAccess.file_exists(PATH) or FileAccess.file_exists(PATH + ".bak")


static func write(data: PlayerData, path := PATH) -> Error:
	var d := data.to_dict()
	d["version"] = VERSION
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
static func load_dict(path := PATH) -> Dictionary:
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


static func read_into(data: PlayerData, path := PATH) -> bool:
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


static func clear() -> void:
	for p: String in [PATH, PATH + ".bak", PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
