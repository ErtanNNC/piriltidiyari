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
	for chapter in ["prologue", "chapter0", "chapter1", "chapter2", "chapter3", "chapter4", "chapter5"]:
		_validate_chapter(chapter)
	test_chapter0_flow()
	test_chapter1_flow()
	test_king_plan()
	test_chapter2_flow()
	test_crab_plan()
	test_shop()
	test_chapter3_flow()
	test_gull_plan()
	test_chapter4_flow()
	test_golem_plan()
	test_chapter5_and_ending()


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


func test_chapter1_flow() -> void:
	print("Bölüm 1 akışı: Fısıltı Ormanı")
	var c: Node = ContentScript.new()
	c.load_chapter("chapter1")
	var d := PlayerData.new()
	var q: Dictionary = c.quests["fisilti_ormani"]
	var talk := func(npc: String) -> Dictionary:
		var v := DialogueRules.pick_variant(c.npc(npc), d)
		DialogueRules.apply(v.get("then", {}), d, c.quests)
		return v
	d.start_quest(q)
	check(not talk.call("hu").has("then"), "Hu önce Orman Feneri'ni ister")
	d.notify("light", "orman_feneri", c.quests)
	check(d.objective_done("fisilti_ormani", "fener"), "Orman Feneri yandı")
	var lesson: Dictionary = talk.call("hu")
	var text := ""
	for l: Dictionary in lesson["lines"]:
		text += String(l["text"]) + " "
	check(text.contains("gri") and text.contains("tersini"), "Hu gri ağacın tersini söylediğini öğretir")
	check(d.objective_done("fisilti_ormani", "hu"), "Hu dersi tamam")
	check(not talk.call("hu").has("then"), "Hu dersi bir kez verir")
	for i in 3:
		d.notify("light", "kucuk_fener", c.quests)
	check(d.objective_count("fisilti_ormani", "fenerler") == Vector2i(3, 3), "3 küçük fener")
	d.notify("reach", "orman_kalbi", c.quests)
	d.notify("defeat", "kutuk_kral", c.quests)
	check(d.quest_state("fisilti_ormani") == "ready", "Kral uyandı, görev hazır")
	check(d.complete_quest(q) and d.piril == 80 and d.item_count("bal_surubu") == 2, "ödüller: 80 Pırıl, 2 Bal Şurubu")
	check(d.add_spark("green") and not d.add_spark("green"), "Yeşil Kıvılcım bir kez eklenir")
	# side quest: three lost young ones
	d.start_quest(c.quests["kayip_yavrular"])
	for i in [1, 2, 3]:
		var first: Dictionary = talk.call("yavru%d" % i)
		check(first.has("then"), "yavru%d ilk konuşmada bulunur" % i)
		check(not talk.call("yavru%d" % i).has("then"), "yavru%d ikinci kez sayılmaz" % i)
	check(d.quest_state("kayip_yavrular") == "ready", "üç yavru bulundu")
	# whisper rule: every crossroads has one consistent answer
	for j: Dictionary in c.chapter["junctions"]:
		for t: Array in j["trees"]:
			var says_right: bool = String(t[2]).begins_with("Sağ")
			var truth_right: bool = says_right != bool(t[1])
			check(truth_right == (int(j["right"]) == 1), "kavşak %s: ağaç '%s' (gri=%s) doğru yolu gösterir" % [j["wall"], t[2], t[1]])
	c.free()


func test_king_plan() -> void:
	print("Kütük Kral planı")
	for p in [1, 2, 3]:
		check(KingPlan.cycle(p).back() == "stomp", "faz %d: döngü yer sarsmayla (vurma fırsatı) biter" % p)
	check(KingPlan.ring_hits(5.0, 5.2, 0.0), "yerdeyken halka çarpar")
	check(not KingPlan.ring_hits(5.0, 5.2, 0.8), "zıplayınca halka çarpmaz")
	check(not KingPlan.ring_hits(5.0, 8.0, 0.0), "halka uzaktayken çarpmaz")
	check(KingPlan.ROOT_DAMAGE * KingPlan.root_count(3) < 100, "bütün kökler değse bile tek seferde uyunmaz")


func test_chapter2_flow() -> void:
	print("Bölüm 2 akışı: Şekerleme Mağaraları")
	var c: Node = ContentScript.new()
	c.load_chapter("chapter2")
	check(c.chapter["theme"] == "dark", "mağaralar Gece temasında")
	var d := PlayerData.new()
	var q: Dictionary = c.quests["sekerleme_magaralari"]
	var talk := func(npc: String) -> Dictionary:
		var v := DialogueRules.pick_variant(c.npc(npc), d)
		DialogueRules.apply(v.get("then", {}), d, c.quests)
		return v
	d.start_quest(q)
	check(not talk.call("kazma").has("then"), "Kazma önce Mağara Feneri'ni ister")
	d.notify("light", "magara_feneri", c.quests)
	talk.call("kazma")
	check(d.objective_done("sekerleme_magaralari", "kazma"), "Kazma kristal kuralını anlatır")
	check(d.quest_state("kazma_cocuklari") == "active", "Kazma çocuk görevini verir")
	for i in [1, 2, 3]:
		talk.call("kazma_cocuk%d" % i)
		talk.call("kazma_cocuk%d" % i)
	check(d.quest_state("kazma_cocuklari") == "ready", "üç minik köstebek bulundu (ikişer konuşmayla)")
	for t in ["kristal_salon", "kristal_tunel"]:
		d.notify("light", t, c.quests)
	d.notify("defeat", "kiskac", c.quests)
	check(d.quest_state("sekerleme_magaralari") == "ready", "Kıskaç dost oldu, görev hazır")
	check(not talk.call("kazma").get("then", {}).has("open_shop"), "dükkân Kıskaç'tan önce kapalı")
	d.set_flag("kazma_dukkan")
	var events := DialogueRules.apply(talk.call("kazma").get("then", {}), d, c.quests)
	check(c.shops.has("kazma"), "Kazma dükkânı tanımlı")
	c.free()


func test_crab_plan() -> void:
	print("Kıskaç planı")
	for p in [1, 2, 3]:
		check(CrabPlan.has_opening(p), "faz %d: vurma fırsatı var" % p)
		check(CrabPlan.rest(p) >= 1.0, "faz %d: saldırılar arası en az 1 sn" % p)
	check(CrabPlan.bubbles(1) < CrabPlan.bubbles(3), "fazlar zorlaşır")
	check(CrabPlan.CLAW_DAMAGE < 20 and CrabPlan.SPIN_DAMAGE * CrabPlan.SPIN_DASHES < 50, "tek seferde uyutmaz")


func test_shop() -> void:
	print("Dükkân")
	var d := PlayerData.new()
	var bal := {"name": "Bal Şurubu", "kind": "potion"}
	var tilsim := {"name": "Kristal Tılsım", "kind": "charm", "max_hp": 15}
	check(Shop.buy(d, bal, "bal_surubu", 15) == "piril", "Pırıl yoksa alınamaz")
	d.add_piril(200)
	check(Shop.buy(d, bal, "bal_surubu", 15) == "ok" and d.piril == 185 and d.item_count("bal_surubu") == 1, "Bal Şurubu alındı, 15 Pırıl düştü")
	var hp_before := d.max_hp
	check(Shop.buy(d, tilsim, "kristal_tilsim", 120, true) == "ok" and d.max_hp == hp_before + 15, "Kristal Tılsım canı kalıcı 15 artırır")
	check(Shop.buy(d, tilsim, "kristal_tilsim", 120, true) == "owned" and d.piril == 65, "tılsım ikinci kez satılmaz, Pırıl gitmez")
	var json := JSON.stringify(d.to_dict())
	var e := PlayerData.new()
	e.load_dict(JSON.parse_string(json))
	check(e.max_hp == d.max_hp and e.has_flag("owned_kristal_tilsim"), "tılsım kayıtta kalır")
	test_village_shop_and_keeper_house()


func test_village_shop_and_keeper_house() -> void:
	print("Köy dükkânı ve Bekçi Evi")
	var items: Dictionary = ContentScript.read_json("res://content/items.json")["items"]
	var keepers: Dictionary = ContentScript.read_json("res://content/keepers.json")["keepers"]
	var d := PlayerData.new()
	d.choose_keeper("pati", keepers["pati"]["stats"], {}, "Pati")
	d.add_piril(1000)
	check(Shop.buy(d, items["kasif_sapkasi"], "kasif_sapkasi", 60, true) == "ok" and d.equipped["outfit"] == "kasif_sapkasi", "kıyafet alınınca giyilir")
	check(Shop.weapon_power(d, items) == 0, "alet yokken ek güç yok")
	check(Shop.buy(d, items["yildiz_asasi"], "yildiz_asasi", 150, true) == "ok" and Shop.weapon_power(d, items) == 6, "Yıldız Asası +6 güç")
	check(Shop.buy(d, items["yildiz_asasi"], "yildiz_asasi", 150, true) == "owned", "asa ikinci kez satılmaz")
	check(Shop.buy(d, items["isik_tohumu"], "isik_tohumu", 15) == "ok" and d.item_count("isik_tohumu") == 10, "tohum paketi 10 tane")
	check(Shop.buy(d, items["isik_sapani"], "isik_sapani", 80, true) == "ok" and d.has_flag("owned_isik_sapani"), "sapan alınır")
	check(not Shop.equip(d, "weapon", "kivilcim_kilici"), "sahip olunmayan alet takılamaz")
	check(Shop.equip(d, "outfit", "") and d.equipped["outfit"] == "", "kıyafet çıkarılabilir")
	# keeper house: switch keepers but keep the adventure
	Shop.buy(d, items["kristal_tilsim"], "kristal_tilsim", 120, true)
	d.add_xp(Progression.xp_to_next(1) + Progression.xp_to_next(2))
	var lv := d.level
	var piril := d.piril
	d.switch_keeper("bado", keepers["bado"]["stats"], {"variant": 1}, "Bado", items)
	var base := PlayerData.new()
	base.choose_keeper("bado", keepers["bado"]["stats"], {}, "Bado")
	check(d.character_id == "bado" and d.level == lv and d.piril == piril, "bekçi değişince seviye ve Pırıl kalır")
	check(d.max_hp == base.max_hp + (lv - 1) * 10 + 15, "yeni bekçinin canı: kendi canı + seviyeler + tılsım")
	check(d.power == base.power + (lv - 1) * 2, "güç seviyelerle birlikte gelir")
	check(d.skills.has(Skills.for_character("bado")) and not d.skills.has(Skills.for_character("pati")), "yeni bekçinin yeteneği gelir, eskisininki gider")
	check(Shop.weapon_power(d, items) == 6 and d.item_count("isik_tohumu") == 10, "aletler ve tohumlar kalır")
	var e := PlayerData.new()
	e.load_dict(JSON.parse_string(JSON.stringify(d.to_dict())))
	check(e.equipped["weapon"] == "yildiz_asasi", "takılı alet kayıtta kalır")


func test_chapter3_flow() -> void:
	print("Bölüm 3 akışı: Bulut Limanı")
	var c: Node = ContentScript.new()
	c.load_chapter("chapter3")
	var d := PlayerData.new()
	var q: Dictionary = c.quests["bulut_limani"]
	var talk := func(npc: String) -> Dictionary:
		var v := DialogueRules.pick_variant(c.npc(npc), d)
		DialogueRules.apply(v.get("then", {}), d, c.quests)
		return v
	d.start_quest(q)
	check(not talk.call("pirpir").has("then"), "Pırpır önce feneri ister")
	d.notify("light", "liman_feneri", c.quests)
	talk.call("pirpir")
	check(d.objective_done("bulut_limani", "pirpir") and d.quest_state("marti_yavrulari") == "active", "Pırpır görevi ve yavru görevini verir")
	for i in 3:
		d.notify("ring", "firtina_cani", c.quests)
	check(d.objective_done("bulut_limani", "canlar"), "üç çan çaldı")
	d.notify("reach", "balon_tepesi", c.quests)
	d.notify("defeat", "ruzgar", c.quests)
	check(d.quest_state("bulut_limani") == "ready", "Rüzgâr sakinleşti, görev hazır")
	for i in [1, 2, 3]:
		talk.call("marti_yavru%d" % i)
	check(d.quest_state("marti_yavrulari") == "ready", "üç martı yavrusu bulundu")
	d.set_flag("pirpir_pazar")
	check(talk.call("pirpir").get("then", {}).get("open_shop", "") == "pirpir", "Pırpır'ın pazarı açılır")
	var items: Dictionary = ContentScript.read_json("res://content/items.json")["items"]
	check(items["cesaret_sekeri"]["buff"] == "guc" and items["pus_kovucu"]["buff"] == "kovucu", "iksir etkileri tanımlı")
	check("cesaret_sekeri" in PlayerData.POTIONS and "pus_kovucu" in PlayerData.POTIONS, "yeni iksirler yuvaya girer")
	d.add_piril(500)
	var sp := d.speed
	check(Shop.buy(d, items["ruzgar_tilsimi"], "ruzgar_tilsimi", 150, true) == "ok" and d.speed > sp, "Rüzgâr Tılsımı hızı kalıcı artırır")
	c.free()


func test_gull_plan() -> void:
	print("Rüzgâr planı")
	for p in [1, 2, 3]:
		check(GullPlan.cycle(p).back() == "dive", "faz %d: döngü pikeyle (vurma fırsatı) biter" % p)
	check(GullPlan.GALE_STRENGTH * GullPlan.GALE_TIME < 7.0, "saklanmayan oyuncu bile tek rüzgârda adadan uçmaz (7 m)")
	check(GullPlan.BOLT_DAMAGE * GullPlan.bolts(3) < 100, "bütün yıldırımlar değse bile uyunmaz")


func test_chapter4_flow() -> void:
	print("Bölüm 4 akışı: Uyku Dağı")
	var c: Node = ContentScript.new()
	c.load_chapter("chapter4")
	var d := PlayerData.new()
	var q: Dictionary = c.quests["uyku_dagi"]
	var talk := func(npc: String) -> Dictionary:
		var v := DialogueRules.pick_variant(c.npc(npc), d)
		DialogueRules.apply(v.get("then", {}), d, c.quests)
		return v
	d.start_quest(q)
	check(not talk.call("kuzey").has("then"), "Kuzey önce Dağ Feneri'ni ister")
	d.notify("light", "dag_feneri", c.quests)
	var lore: Dictionary = talk.call("kuzey")
	var text := ""
	for l: Dictionary in lore["lines"]:
		text += String(l["text"]) + " "
	check(text.contains("Mırıl") and text.contains("yıldız") and text.contains("yalnızlık"), "Kuzey Mırıl'ın hikâyesini anlatır: düşen yıldız, Pus = yalnızlık")
	check(d.has_flag("miril_ogrenildi") and d.quest_state("uykulu_yavrular") == "active", "hikâye öğrenildi, yavru görevi başladı")
	for i in 3:
		d.notify("light", "kamp_atesi", c.quests)
	d.notify("defeat", "dondurma", c.quests)
	check(d.quest_state("uyku_dagi") == "ready", "Dondurma uyandı, görev hazır")
	for i in [1, 2, 3]:
		talk.call("uykulu_yavru%d" % i)
	check(d.quest_state("uykulu_yavrular") == "ready", "üç uykucu yavru uyandı")
	d.complete_quest(q)
	d.add_item("hikaye_tasi", 3)
	var then: Dictionary = talk.call("kuzey").get("then", {})
	check(then.get("read_stones", false), "görev sonrası Kuzey Hikâye Taşlarını okur")
	c.free()


func test_golem_plan() -> void:
	print("Dondurma planı")
	for p in [1, 2, 3]:
		check(GolemPlan.cycle(p).has("slam"), "faz %d: yumruk darbesi (vurma fırsatı) var" % p)
	check(GolemPlan.in_breath(Vector3.FORWARD, Vector3(0, 0, -4)), "önündeki nefes koninin içinde")
	check(not GolemPlan.in_breath(Vector3.FORWARD, Vector3(4, 0, 0)), "yanındaki nefesten etkilenmez")
	check(not GolemPlan.in_breath(Vector3.FORWARD, Vector3(0, 0, -9)), "uzaktaki nefesten etkilenmez")
	check(GolemPlan.BREATH_SLOW > 0.2, "nefes dondurmaz, sadece yavaşlatır")


func test_chapter5_and_ending() -> void:
	print("Bölüm 5 ve kapanış")
	var c: Node = ContentScript.new()
	c.load_chapter("chapter5")
	var d := PlayerData.new()
	d.start_quest(c.quests["pus_kalesi"])
	d.notify("light", "kale_feneri", c.quests)
	for i in 4:
		d.notify("light", "kivilcim_kapisi", c.quests)
		d.notify("collect", "ani", c.quests)
	d.notify("defeat", "miril", c.quests)
	check(d.quest_state("pus_kalesi") == "ready", "kale görevi tamamlanır")
	for p in [1, 2, 3]:
		check(MirilPlan.cycle(p).back() == "tired", "faz %d: Mırıl her döngüde yorulur (yaklaşma fırsatı)" % p)
	check(not MirilPlan.can_offer(["green", "blue"]), "dört Kıvılcım olmadan Faz 2 başlamaz")
	check(MirilPlan.can_offer(["green", "blue", "yellow", "white"]), "dört Kıvılcım ile Faz 2")
	for col in MirilPlan.OFFER_ORDER:
		check(c.barks.has("c5_isik_" + col), "Faz 2: %s Kıvılcım bir anıyı aydınlatır" % col)
	for k: String in c.keepers:
		check(c.barks.has("final_" + k), "kapanış cümlesi: %s" % k)
	# every cutscene "say" exists (with {keeper} for every keeper)
	for ch in ["prologue", "chapter3", "chapter5"]:
		c.load_chapter(ch)
		var dir := DirAccess.open("res://content/%s/cutscenes" % ch)
		for f in dir.get_files():
			if not f.ends_with(".json"):
				continue
			for step: Dictionary in ContentScript.read_json("res://content/%s/cutscenes/%s" % [ch, f])["steps"]:
				if step.has("say"):
					for k: String in c.keepers:
						var id := String(step["say"]).replace("{keeper}", k)
						check(c.barks.has(id), "%s/%s: konuşma %s var" % [ch, f, id])
	check(PlayerData.STORY_STONES == 10, "Sezon 1'de 10 Hikâye Taşı")
	var stones := {}
	for ch in ["chapter1", "chapter2", "chapter3", "chapter4", "chapter5"]:
		c.load_chapter(ch)
		for id: String in c.barks:
			if id.begins_with("tas_"):
				stones[id] = true
	check(stones.size() == PlayerData.STORY_STONES, "her taşın metni var (%d)" % stones.size())
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
			check(c.speakers.has(line["speaker"]) or line["speaker"] == "oyuncu", "bark %s: bilinmeyen konuşan" % id)
			check(String(line["text"]).length() <= 70, "bark %s: satır en fazla 70 harf: %s" % [id, line["text"]])
	for id: String in c.items:
		check(t.has_color(c.items[id]["color"]), "eşya %s: renk token'ı var" % id)
	for npc_id: String in c.npcs:
		check(c.speakers.has(npc_id), "NPC %s konuşanlar listesinde" % npc_id)
		for v: Dictionary in c.npcs[npc_id]["variants"]:
			for line: Dictionary in v.get("lines", []):
				check(c.speakers.has(line["speaker"]) or line["speaker"] == "oyuncu", "%s: bilinmeyen konuşan %s" % [npc_id, line["speaker"]])
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
			check(o.get("type", "deliver") in ["deliver", "defeat", "reach", "talk", "light", "ring", "collect"], "görev %s: hedef türü" % q["id"])
			if o.get("type", "") == "defeat":
				check(o["target"] in MobStats.KINDS or o["target"] in ["pus", "kutuk_kral", "kiskac", "ruzgar", "dondurma", "miril"], "görev %s: bilinmeyen mob %s" % [q["id"], o["target"]])
	c.free()
	t.free()
