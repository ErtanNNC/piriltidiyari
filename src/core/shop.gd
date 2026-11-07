class_name Shop
extends RefCounted
## Buying with Pırıl. Pure rules so they can be tested.

## Result: "ok", "piril" (not enough), or "owned" (a once-only item you have).
static func buy(data: PlayerData, item_def: Dictionary, item_id: String, price: int, once := false) -> String:
	if once and data.has_flag("owned_" + item_id):
		return "owned"
	if not data.spend_piril(price):
		return "piril"
	var kind: String = item_def.get("kind", "")
	if kind in ["outfit", "weapon"]:
		# wearable / holdable: owned once, put on right away
		data.set_flag("owned_" + item_id)
		data.equipped[kind] = item_id
		data.stats_changed.emit()
	elif kind == "sling":
		data.set_flag("owned_" + item_id)
	elif kind == "ammo":
		data.add_item(item_id, int(item_def.get("count", 1)))
	elif kind == "charm":
		data.set_flag("owned_" + item_id)
		if item_def.has("speed"):
			data.speed += float(item_def["speed"])
		if item_def.has("max_hp"):
			data.max_hp += int(item_def["max_hp"])
			data.heal(int(item_def["max_hp"]))
	else:
		data.add_item(item_id)
		if once:
			data.set_flag("owned_" + item_id)
	return "ok"


## Extra power from the held tool (Işık Değneği, Yıldız Asası...).
static func weapon_power(data: PlayerData, item_defs: Dictionary) -> int:
	var w: String = data.equipped.get("weapon", "")
	if w == "" or not data.has_flag("owned_" + w):
		return 0
	return int(item_defs.get(w, {}).get("power", 0))


## Put on / take off something you own ("" takes it off).
static func equip(data: PlayerData, slot: String, item_id: String) -> bool:
	if item_id != "" and not data.has_flag("owned_" + item_id):
		return false
	data.equipped[slot] = item_id
	data.stats_changed.emit()
	return true
