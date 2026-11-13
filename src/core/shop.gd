class_name Shop
extends RefCounted
## Buying with Pırıl. Pure rules so they can be tested.

## Result: "ok", "piril" (not enough), or "owned" (a once-only item you have).
static func buy(data: PlayerData, item_def: Dictionary, item_id: String, price: int, once := false) -> String:
	if (once or item_def.get("kind", "") == "charm") and data.has_flag("owned_" + item_id):
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
		if item_def.has("power"):
			data.power += int(item_def["power"])
			data.stats_changed.emit()
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


## The worn outfit's bonus: {"regen": hp per 2 s, "speed": +walk, "magnet": +m,
## "mp_regen": mp per s, "guard": 0..1 less damage}. Empty without an outfit.
static func outfit_bonus(data: PlayerData, item_defs: Dictionary) -> Dictionary:
	var o: String = data.equipped.get("outfit", "")
	if o == "" or not data.has_flag("owned_" + o):
		return {}
	return item_defs.get(o, {}).get("bonus", {})


## Damage after the outfit's guard (always at least 1).
static func guarded(amount: int, bonus: Dictionary) -> int:
	var g := clampf(float(bonus.get("guard", 0.0)), 0.0, 0.8)
	return maxi(1, int(ceil(amount * (1.0 - g))))
