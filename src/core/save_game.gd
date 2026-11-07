class_name SaveGame
extends RefCounted
## One save slot in user://kayit.json. Written at every scene checkpoint.

const PATH := "user://kayit.json"


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


static func write(data: PlayerData) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data.to_dict(), "\t"))


static func read_into(data: PlayerData) -> bool:
	if not exists():
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	data.load_dict(parsed)
	return true


static func clear() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
