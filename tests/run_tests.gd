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
	test_quest_flow_scene2()
	test_save_roundtrip()
	test_owl_plan()
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
	check(d.piril == 30 and d.xp == 20 and d.level == 1, "ödül: 30 Pırıl, 20 XP, seviye atlamadan (Pırıl %d, XP %d)" % [d.piril, d.xp])
	check(d.has_flag("sahne1_bitti"), "sahne 1 bitti bayrağı")
	var after: Dictionary = talk.call("tospik_nine")
	check(not after.has("then"), "tekrar konuşunca ödül tekrar verilmez")
	check(d.piril == 30, "Pırıl ikinci kez eklenmedi")
	c.free()


func test_quest_flow_scene2() -> void:
	print("Sahne 2 akışı: Gri Rüzgâr")
	var c: Node = ContentScript.new()
	var d := PlayerData.new()
	var q: Dictionary = c.quests["gri_ruzgar"]
	var talk := func(npc: String) -> Dictionary:
		var v := DialogueRules.pick_variant(c.npc(npc), d)
		DialogueRules.apply(v.get("then", {}), d, c.quests)
		return v
	d.start_quest(q)
	d.notify("defeat", "pus", c.quests)
	check(d.objective_count("gri_ruzgar", "yol").x == 0, "sıralı görev: sonraki hedef erken ilerlemez")
	for i in 3:
		d.notify("defeat", "sumuklu", c.quests)
	check(d.objective_done("gri_ruzgar", "sumuklu"), "3 sümüklü sakinleşti")
	var early: Dictionary = talk.call("tospik_nine")
	check(not early.has("then"), "kirişi geçmeden Tospik iksir vermez")
	d.notify("reach", "tospik_bahce", c.quests)
	talk.call("tospik_nine")
	check(d.item_count("bal_surubu") == 3 and d.potions[0] == "bal_surubu", "3 Bal Şurubu, ilk iksir yuvasında")
	check(d.objective_done("gri_ruzgar", "konus"), "konuşma hedefi tamam")
	var again: Dictionary = talk.call("tospik_nine")
	check(not again.has("then") and d.item_count("bal_surubu") == 3, "iksirler bir kez verilir")
	for i in 4:
		d.notify("defeat", "pus", c.quests)
	check(d.quest_state("gri_ruzgar") == "ready", "yol açıldı, teslime hazır")
	var fin: Dictionary = talk.call("tospik_nine")
	check(fin["then"].get("goto_scene", "") == "scene3", "Sahne 3'e geçiş")
	check(d.has_flag("sahne2_bitti") and d.quest_state("gri_ruzgar") == "done", "sahne 2 bitti")
	check(talk.call("piti")["lines"][0]["text"].contains("Sis"), "çocuklar Sahne 2'de sisten söz eder")
	c.free()


func test_save_roundtrip() -> void:
	print("Kayıt")
	var a := PlayerData.new()
	a.add_xp(60)
	a.add_piril(42)
	a.add_item("bal_surubu", 2)
	a.unlock_skill("dikenli_donus")
	a.start_quest({"id": "q", "objectives": [{"id": "o", "count": 3}]})
	a.advance_objective("q", "o")
	a.set_flag("x")
	var json := JSON.stringify(a.to_dict())
	var b := PlayerData.new()
	b.load_dict(JSON.parse_string(json))
	check(b.level == 2 and b.xp == 10 and b.piril == 42, "seviye, XP, Pırıl geri geldi")
	check(b.item_count("bal_surubu") == 2 and b.potions[0] == "bal_surubu", "eşyalar ve iksir yuvası")
	check(b.objective_count("q", "o") == Vector2i(1, 3), "görev ilerlemesi")
	check(b.advance_objective("q", "o"), "yüklenen görev ilerleyebilir")
	check(b.has_flag("x") and b.skills.has("dikenli_donus"), "bayrak ve yetenek")


func test_owl_plan() -> void:
	print("Pus Baykuşu planı")
	check(OwlPlan.phase(OwlPlan.MAX_HP) == 1 and OwlPlan.phase(OwlPlan.MAX_HP / 2) == 2 and OwlPlan.phase(10) == 3, "üç faz")
	for p in [1, 2, 3]:
		check(OwlPlan.cycle(p).has("dive"), "faz %d: her döngüde dalış (vurma fırsatı) var" % p)
		check(OwlPlan.rest(p) >= 1.0, "faz %d: saldırılar arası en az 1 sn" % p)
	check(OwlPlan.volley(1).x < OwlPlan.volley(3).x, "fazlar zorlaşır")
	check(OwlPlan.FEATHER_DAMAGE * 3 + OwlPlan.DIVE_DAMAGE < 100, "ilk döngüde hiç kaçmayan oyuncu bile uyumaz")


func test_content_is_valid() -> void:
	for chapter in ["prologue", "chapter0"]:
		_validate_chapter(chapter)
	test_chapter0_flow()


func test_chapter0_flow() -> void:
	print("Bölüm 0 akışı")
	var c: Node = ContentScript.new()
	c.load_chapter("chapter0")
	var d := PlayerData.new()
	d.choose_keeper("bado", c.keepers["bado"]["stats"], {}, "Bado")
	check(d.max_hp == 120 and d.speed < 6.0 and d.level == 1, "Bado: çok can, yavaş, seviye 1")
	check(d.active_skill() == "kucaklama_kalkani", "Bado'nun özel yeteneği Kucaklama Kalkanı")
	for k: String in c.keepers:
		check(Skills.for_character(k) != "", "%s için özel yetenek tanımlı" % k)
		check(String(c.keepers[k]["special"]).begins_with(Skills.DEFS[Skills.for_character(k)]["name"]), "%s: yetenek adı karakter dokümanıyla aynı" % k)
	var f := PlayerData.new()
	check(f.active_skill() == "", "Fıstık Sahne 3'ten önce yeteneksiz")
	f.unlock_skill("dikenli_donus")
	check(f.active_skill() == "dikenli_donus", "Fıstık: Dikenli Dönüş")
	var talk := func(npc: String) -> Dictionary:
		var v := DialogueRules.pick_variant(c.npc(npc), d)
		DialogueRules.apply(v.get("then", {}), d, c.quests)
		return v
	talk.call("tospik_nine")
	check(d.quest_state("ilk_adim") == "active", "Tospik ilk görevi verir")
	d.notify("defeat", "dev_mantar", c.quests)
	check(not d.objective_done("ilk_adim", "mantar"), "önce heykel ziyaret edilmeli (sıralı)")
	talk.call("fistik_heykeli")
	d.notify("defeat", "dev_mantar", c.quests)
	check(d.quest_state("ilk_adim") == "ready", "mantar uyandı, görev hazır")
	talk.call("tospik_nine")
	check(d.has_flag("bolum0_bitti") and d.level == 2, "Bölüm 0 başlangıcı biter, seviye 2")
	c.free()


func _validate_chapter(chapter: String) -> void:
	print("İçerik paketi kuralları: ", chapter)
	var c: Node = ContentScript.new()
	c.load_chapter(chapter)
	var t: Node = TokensScript.new()
	for id: String in c.speakers:
		check(t.has_color(c.speakers[id]["color"]), "konuşan %s: renk token'ı var" % id)
		check(c.speakers[id]["color"] != "leaf", "konuşan %s: leaf üstüne metin yazılmaz" % id)
	for id: String in c.barks:
		for line: Dictionary in c.barks[id]:
			check(c.speakers.has(line["speaker"]), "bark %s: bilinmeyen konuşan" % id)
			check(String(line["text"]).length() <= 70, "bark %s: satır en fazla 70 harf: %s" % [id, line["text"]])
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
			if o.has("item"):
				check(c.items.has(o["item"]), "görev %s: eşya %s" % [q["id"], o["item"]])
			if o.has("to"):
				check(c.npcs.has(o["to"]), "görev %s: NPC %s" % [q["id"], o["to"]])
			check(o.get("type", "deliver") in ["deliver", "defeat", "reach", "talk"], "görev %s: hedef türü" % q["id"])
			if o.get("type", "") == "defeat":
				check(o["target"] in MobStats.KINDS or o["target"] == "pus", "görev %s: bilinmeyen mob %s" % [q["id"], o["target"]])
	c.free()
	t.free()
