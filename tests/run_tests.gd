extends SceneTree
## Headless test suite: `tools/test.sh` (or godot --headless -s res://tests/run_tests.gd).
## Covers the level curve, quest rules, and validates every content pack
## against the design rules (known speakers/items/colors, short lines).

const ContentScript := preload("res://src/autoload/content.gd")
const TokensScript := preload("res://src/autoload/tokens.gd")

var _failures := 0
var _checks := 0


func _init() -> void:
	test_progression()
	test_quest_flow_scene1()
	test_content_is_valid()
	print("\n%d kontrol, %d hata" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		print("  ✗ ", what)


func test_progression() -> void:
	print("Seviye eğrisi")
	check(Progression.xp_to_next(1) == 50, "1→2 için 50 XP")
	check(Progression.xp_to_next(2) == 152, "2→3 için 152 XP")
	check(Progression.xp_to_next(30) == 0, "30 son seviye")
	var d := PlayerData.new()
	var levels: Array[int] = []
	d.leveled_up.connect(func(l: int) -> void: levels.append(l))
	d.add_xp(50 + 152 + 10)
	check(d.level == 3 and d.xp == 10, "212 XP ile seviye 3, artan 10 XP (seviye %d, xp %d)" % [d.level, d.xp])
	check(levels == [2, 3], "her seviye için sinyal")
	check(d.hp == d.max_hp and d.max_hp == 120, "seviye atlayınca can dolar ve artar")
	check(Progression.unlocks_skill(5) and not Progression.unlocks_skill(6), "her 5 seviyede yetenek")


func test_quest_flow_scene1() -> void:
	print("Sahne 1 akışı: Kayıp Fenerler")
	var c: Node = ContentScript.new()
	var d := PlayerData.new()
	var talk := func(npc: String) -> Dictionary:
		var v := DialogueRules.pick_variant(c.npc(npc), d)
		DialogueRules.apply(v.get("then", {}), d, c.quests)
		return v
	check(d.quest_state("kayip_fenerler") == "none", "görev başta yok")
	var first: Dictionary = talk.call("piti")
	check(not first.has("then"), "görev yokken çocuk sadece sohbet eder")
	talk.call("tospik_nine")
	check(d.quest_state("kayip_fenerler") == "active", "Tospik Nine görevi verir")
	talk.call("piti")
	check(not d.objective_done("kayip_fenerler", "pembe"), "fener yokken teslim olmaz")
	for item in ["fener_pembe", "fener_mavi", "fener_yesil"]:
		d.add_item(item)
	for kid in ["piti", "tipis", "zipzip"]:
		talk.call(kid)
	check(d.objective_progress("kayip_fenerler") == Vector2i(3, 3), "üç fener teslim edildi")
	check(d.items.is_empty(), "teslim edilen fenerler çantadan çıktı")
	check(d.quest_state("kayip_fenerler") == "ready", "görev teslime hazır")
	talk.call("tospik_nine")
	check(d.quest_state("kayip_fenerler") == "done", "görev tamamlandı")
	check(d.piril == 30 and d.xp == 40 and d.level == 1, "ödül: 30 Pırıl, 40 XP, seviye atlamadan (Pırıl %d, XP %d)" % [d.piril, d.xp])
	check(d.has_flag("sahne1_bitti"), "sahne 1 bitti bayrağı")
	var after: Dictionary = talk.call("tospik_nine")
	check(not after.has("then"), "tekrar konuşunca ödül tekrar verilmez")
	check(d.piril == 30, "Pırıl ikinci kez eklenmedi")
	c.free()


func test_content_is_valid() -> void:
	print("İçerik paketi kuralları")
	var c: Node = ContentScript.new()
	var t: Node = TokensScript.new()
	for id: String in c.speakers:
		check(t.has_color(c.speakers[id]["color"]), "konuşan %s: renk token'ı var" % id)
		check(c.speakers[id]["color"] != "leaf", "konuşan %s: leaf üstüne metin yazılmaz" % id)
	for id: String in c.items:
		check(t.has_color(c.items[id]["color"]), "eşya %s: renk token'ı var" % id)
	for npc_id: String in c.npcs:
		check(c.speakers.has(npc_id), "NPC %s konuşanlar listesinde" % npc_id)
		for v: Dictionary in c.npcs[npc_id]["variants"]:
			for line: Dictionary in v.get("lines", []):
				check(c.speakers.has(line["speaker"]), "%s: bilinmeyen konuşan %s" % [npc_id, line["speaker"]])
				check(String(line["text"]).length() <= 70, "%s: satır en fazla 2 balon satırı (70 harf): %s" % [npc_id, line["text"]])
				for bad in ["öl", "kan ", "korku"]:
					check(not String(line["text"]).to_lower().begins_with(bad), "%s: yasak sözcük" % npc_id)
			var then: Dictionary = v.get("then", {})
			for key in ["start_quest", "complete_quest"]:
				if then.has(key):
					check(c.quests.has(then[key]), "%s: %s bilinmeyen görev" % [npc_id, then[key]])
			if then.has("deliver"):
				var dl: Dictionary = then["deliver"]
				check(c.items.has(dl["item"]), "%s: bilinmeyen eşya %s" % [npc_id, dl["item"]])
				var ids: Array = c.quests.get(dl["quest"], {}).get("objectives", []).map(func(o: Dictionary) -> String: return o["id"])
				check(ids.has(dl["objective"]), "%s: bilinmeyen hedef %s" % [npc_id, dl["objective"]])
		check(not c.npcs[npc_id]["variants"].back().has("when"), "%s: son konuşma koşulsuz (her zaman bir cevap var)" % npc_id)
	for q: Dictionary in c.quests.values():
		for o: Dictionary in q["objectives"]:
			check(c.items.has(o["item"]), "görev %s: eşya %s" % [q["id"], o["item"]])
			check(c.npcs.has(o["to"]), "görev %s: NPC %s" % [q["id"], o["to"]])
	c.free()
	t.free()
