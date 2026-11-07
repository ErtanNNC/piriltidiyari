class_name Shop
extends RefCounted
## Buying with Pırıl. Pure rules so they can be tested.

## Result: "ok", "piril" (not enough), or "owned" (a once-only item you have).
static func buy(data: PlayerData, item_def: Dictionary, item_id: String, price: int, once := false) -> String:
	if once and data.has_flag("owned_" + item_id):
		return "owned"
	if not data.spend_piril(price):
		return "piril"
	if item_def.get("kind", "") == "charm":
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
