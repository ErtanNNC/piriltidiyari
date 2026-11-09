class_name SideQuests
extends RefCounted
## Season 2 side collections (content/s2_side.json): Minnoş'un İzleri
## (drawings), Susturulmuş Davullar (three per region) and Fıstık'ın
## Mektupları (one per region, after its bell). Every spot is a flag
## "yan_<set>_<scene>_<i>" (i = index in that scene's spot list), so saves
## need nothing new. Rewards: per region (davul) and for a full set.


static func flag(scene: String, i: int, set_id: String) -> String:
	return "yan_%s_%s_%d" % [set_id, scene, i]


## The spots of `scene` as [index, spot] pairs, optionally of one set.
static func spots(side: Dictionary, scene: String, set_id := "") -> Array:
	var out := []
	var list: Array = side.get("spots", {}).get(scene, [])
	for i in list.size():
		if set_id == "" or list[i]["set"] == set_id:
			out.append([i, list[i]])
	return out


static func total(side: Dictionary, set_id: String) -> int:
	var n := 0
	for scene: String in side.get("spots", {}):
		n += spots(side, scene, set_id).size()
	return n


static func found(data: PlayerData, side: Dictionary, set_id: String, scene := "") -> int:
	var n := 0
	for sc: String in side.get("spots", {}):
		if scene != "" and sc != scene:
			continue
		for pair: Array in spots(side, sc, set_id):
			if data.has_flag(flag(sc, pair[0], set_id)):
				n += 1
	return n


## A spot can be used once its "needs" flag (the region bell) is set.
static func available(data: PlayerData, spot: Dictionary) -> bool:
	return spot.get("needs", "") == "" or data.has_flag(spot["needs"])


## Marks spot `i` of `scene` found and pays rewards. Returns the events:
## "found", "first" (first of the set), "region" (a region's set complete),
## "done" (the whole set complete). Empty when already found / not ready.
static func take(data: PlayerData, side: Dictionary, scene: String, i: int) -> Array[String]:
	var out: Array[String] = []
	var list: Array = side.get("spots", {}).get(scene, [])
	if i < 0 or i >= list.size():
		return out
	var spot: Dictionary = list[i]
	var set_id: String = spot["set"]
	var f := flag(scene, i, set_id)
	if data.has_flag(f) or not available(data, spot):
		return out
	var def: Dictionary = side["sets"][set_id]
	var first := found(data, side, set_id) == 0
	data.set_flag(f)
	out.append("found")
	if first:
		out.append("first")
	if def.has("region_reward") and found(data, side, set_id, scene) == spots(side, scene, set_id).size():
		_pay(data, def["region_reward"])
		out.append("region")
	if found(data, side, set_id) == total(side, set_id):
		data.set_flag("yan_%s_bitti" % set_id)
		_pay(data, def.get("reward", {}))
		out.append("done")
	return out


static func _pay(data: PlayerData, reward: Dictionary) -> void:
	if reward.has("piril"):
		data.add_piril(int(reward["piril"]))
	if reward.has("xp"):
		data.add_xp(int(reward["xp"]))
