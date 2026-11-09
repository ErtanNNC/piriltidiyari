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
	test_save_safety_and_stats()
	test_save_slots_and_tracker()
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
	check(d.hp == d.max_hp and d.max_hp == 100 + Progression.hp_gain(2) + Progression.hp_gain(3), "seviye atlayınca can dolar ve artar")
	check(d.power_picks == 2, "her seviye bir güç seçimi bekletir")
	check(Progression.power_gain(20) > Progression.power_gain(2) and Progression.hp_gain(20) > Progression.hp_gain(2), "ileri seviyeler daha çok güç ve can verir")
	check(Progression.xp_to_next(10) > Progression.xp_to_next(5), "her yeni seviye daha zor")
	test_mob_levels_and_powers()
	check(Progression.unlocks_skill(5) and not Progression.unlocks_skill(6), "her 5 seviyede yetenek")


func test_mob_levels_and_powers() -> void:
	print("Mob seviyeleri ve güçler")
	var easy := MobStats.scaled("mantar", MobStats.level_of("mantar"))
	var hard := MobStats.scaled("golge_kopya", MobStats.level_of("golge_kopya"))
	check(hard["xp"] > easy["xp"] * 20, "zor yaratık çok daha fazla XP verir (%d / %d)" % [hard["xp"], easy["xp"]])
	check(hard["hp"] > easy["hp"] * 4 and hard["damage"] > easy["damage"], "ileri bölüm yaratıkları daha dayanıklı ve güçlü")
	for k: String in MobStats.KINDS:
		var lv := MobStats.level_of(k)
		var st := MobStats.scaled(k, lv)
		# a keeper of the same level calms it in a handful of hits
		var hits := ceili(float(st["hp"]) / Progression.expected_power(lv))
		check(hits >= 2 and hits <= (14 if k == "dev_mantar" else 9), "%s (Sv %d) aynı seviyedeki bekçiyle %d vuruşta sakinleşir" % [k, lv, hits])
		var sleeps_after := ceili(float(Progression.expected_hp(lv)) / st["damage"])
		check(sleeps_after >= 6, "%s bekçiyi en az 6 vuruşta uyutabilir (%d)" % [k, sleeps_after])
	check(MobStats.level_of("kirpi_topu") >= 5 and MobStats.level_of("golge_kopya") >= 25, "mob seviyeleri bölüm aralığında")
	check(Progression.boss_damage(36, 36) == 18 and Progression.boss_damage(10, 10) == 10, "güçlü bekçinin boss vuruşu ayarlanır, zayıfınki aynen kalır")
	# level-up cards
	var d := PlayerData.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	d.add_xp(Progression.xp_to_next(1))
	var c := Powers.choices(d.powers, rng)
	check(c.size() == 3 and Powers.DEFS[c[0]["id"]]["kind"] == "active" and c[0]["new"], "ilk seçimde yeni bir aktif güç var")
	Powers.pick(d, c[0]["id"])
	check(Powers.rank(d.powers, c[0]["id"]) == 1 and d.power_picks == 0, "seçilen güç öğrenilir, bekleyen seçim biter")
	d.power_picks = 1
	Powers.pick(d, c[0]["id"])
	check(Powers.rank(d.powers, c[0]["id"]) == 2, "aynı güç seçilirse yükselir")
	d.powers["yildiz_yagmuru"] = 1
	d.powers["gokkusagi_dalgasi"] = 1
	d.powers["baloncuk_patlamasi"] = 0
	d.powers.erase("baloncuk_patlamasi")
	d.powers.erase("isik_donencesi")
	var ok := true
	for i in 30:
		for ch: Dictionary in Powers.choices(d.powers, rng):
			if ch["new"] and Powers.DEFS[ch["id"]]["kind"] == "active" and Powers.actives(d.powers).size() >= 2:
				ok = false
	check(ok, "en fazla 2 aktif güç: yuvalar doluyken yeni aktif gelmez")
	var hp0 := d.max_hp
	d.power_picks = 1
	Powers.pick(d, "kocaman_yurek")
	check(d.max_hp == hp0 + 15, "Kocaman Yürek canı 15 artırır")
	check(is_equal_approx(Powers.attack_mult({"guclu_vurus": 3}), 1.3), "Güçlü Vuruş 3: %30")
	var full := {}
	for id: String in Powers.DEFS:
		full[id] = Powers.MAX_RANK
	check(Powers.choices(full, rng)[0]["id"] == Powers.FALLBACK, "hepsi tamken Pırıl kesesi gelir")
	var e := PlayerData.new()
	e.load_dict(JSON.parse_string(JSON.stringify(d.to_dict())))
	check(Powers.rank(e.powers, "kocaman_yurek") == 1, "güçler kayıtta kalır")
	var old := PlayerData.new()
	old.sparks = ["green", "blue"]
	old.catch_up()
	check(old.level == 15 and old.power_picks == 3 and not old.powers.is_empty(), "eski kayıt bölümün seviyesine yükselir; 3 kart seçilir, gerisi otomatik")
	old.catch_up()
	check(old.level == 15, "yakalama seviyeyi düşürmez, tekrar etmez")


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


func test_save_slots_and_tracker() -> void:
	print("Kayıt yuvaları ve görev paneli")
	var old_base := SaveGame.base
	var old_slot := SaveGame.slot
	SaveGame.base = "user://test_yuva"
	for s in range(1, SaveGame.SLOTS + 1):
		SaveGame.clear(s)
	check(not SaveGame.exists() and SaveGame.latest_slot() == 0, "boş yuvalar: kayıt yok")
	var a := PlayerData.new()
	a.character_name = "Pati"
	a.add_piril(7)
	a.scene_id = "chapter3"
	SaveGame.slot = 1
	SaveGame.write(a)
	var b := PlayerData.new()
	b.character_name = "Bado"
	b.scene_id = "scene1"
	SaveGame.slot = 3
	SaveGame.write(b)
	check(SaveGame.slot_exists(1) and not SaveGame.slot_exists(2) and SaveGame.slot_exists(3), "iki ayrı yuvaya kaydedilir")
	var s1 := SaveGame.summary(1)
	check(s1["name"] == "Pati" and s1["piril"] == 7 and s1["scene_id"] == "chapter3" and float(s1["saved_at"]) > 0.0, "yuva özeti: ad, Pırıl, yer, saat")
	check(SaveGame.summary(2).is_empty(), "boş yuvanın özeti boş")
	check(SaveGame.latest_slot() == 3, "Devam et en son kaydedilen yuvayı açar")
	SaveGame.slot = 1
	var e := PlayerData.new()
	check(SaveGame.read_into(e) and e.character_name == "Pati", "seçilen yuva yüklenir (öteki yuva karışmaz)")
	SaveGame.clear(3)
	check(not SaveGame.slot_exists(3) and SaveGame.slot_exists(1), "yuva silinir, ötekiler kalır")
	check(SaveGame.path_for(1) == "user://test_yuva.json", "1. yuva eski tek kaydın dosyası")
	for s in range(1, SaveGame.SLOTS + 1):
		SaveGame.clear(s)
	SaveGame.base = old_base
	SaveGame.slot = old_slot
	# the quest panel only follows quests of the loaded chapter
	var c3 := {"marti_yavrulari": _quest("chapter3", "marti_yavrulari")}
	var c4 := {"uyku_dagi": _quest("chapter4", "uyku_dagi"), "uykulu_yavrular": _quest("chapter4", "uykulu_yavrular")}
	var d := PlayerData.new()
	d.start_quest(c3["marti_yavrulari"])
	check(d.tracked_quest(c4) == "", "başka bölümün açık görevi boş panel açmaz")
	d.start_quest(c4["uykulu_yavrular"])
	d.start_quest(c4["uyku_dagi"])
	check(d.tracked_quest(c4) == "uyku_dagi", "bölümün ana görevi önce gösterilir")


func _quest(chapter: String, id: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://content/%s/quests/%s.json" % [chapter, id]))


func test_save_safety_and_stats() -> void:
	print("Kayıt güvenliği ve türetilmiş statlar")
	var path := "user://test_kayit.json"
	for p: String in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	var d := PlayerData.new()
	d.add_piril(10)
	check(SaveGame.write(d, path) == OK, "ilk kayıt yazılır")
	d.add_piril(5)
	check(SaveGame.write(d, path) == OK and FileAccess.file_exists(path + ".bak"), "ikinci kayıtta eskisi .bak olarak kalır")
	var e := PlayerData.new()
	check(SaveGame.read_into(e, path) and e.piril == 15, "en yeni kayıt okunur")
	# a crash mid-write leaves a broken main file: the .bak saves the day
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{\"piril\": 1")
	f.close()
	var g := PlayerData.new()
	check(SaveGame.read_into(g, path) and g.piril == 10, "bozuk kayıtta yedekten (.bak) yüklenir")
	check(SaveGame.migrate({"version": 99}).is_empty(), "daha yeni oyunun kaydı reddedilir")
	var old := SaveGame.migrate({"piril": 3, "level": 4, "max_hp": 150, "power": 20, "speed": 6.0})
	check(int(old["version"]) == SaveGame.VERSION and old.has("equipped") and old.has("powers"), "sürüm 1 kaydı yeni alanlarla yükseltilir")
	var h := PlayerData.new()
	h.load_dict(old)
	h.recompute_stats({})
	check(h.max_hp == 150 and h.power == 20, "eski kayıtta statlar korunur (taban geriye doğru bulunur)")
	for p: String in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	# derived stats equal the step-by-step ones and can't drift
	var items: Dictionary = ContentScript.read_json("res://content/items.json")["items"]
	var keepers: Dictionary = ContentScript.read_json("res://content/keepers.json")["keepers"]
	var k := PlayerData.new()
	k.choose_keeper("citir", keepers["citir"]["stats"], {}, "Çıtır")
	k.add_piril(500)
	k.add_xp(Progression.xp_to_next(1) + Progression.xp_to_next(2) + Progression.xp_to_next(3))
	Shop.buy(k, items["kristal_tilsim"], "kristal_tilsim", 120, true)
	k.power_picks = 1
	Powers.pick(k, "kocaman_yurek")
	var before := [k.max_hp, k.power, k.speed]
	k.max_hp += 999  # drift
	k.recompute_stats(items)
	check([k.max_hp, k.power, k.speed] == before, "yeniden hesap adım adım toplamla aynı, sapma düzelir")


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
	for chapter in ["prologue", "chapter0", "chapter1", "chapter2", "chapter3", "chapter4", "chapter5", "s2_prologue", "s2_chapter0", "s2_chapter1", "s2_chapter2", "s2_chapter3", "s2_chapter4", "s2_chapter5"]:
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
	test_season2()
	test_language()


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
	check(Shop.outfit_bonus(d, items).get("magnet", 0.0) > 0.0 and Shop.outfit_bonus(d, items).get("speed", 0.0) > 0.0, "Kâşif Şapkası hız ve mıknatıs verir")
	check(Shop.equip(d, "outfit", "") and d.equipped["outfit"] == "", "kıyafet çıkarılabilir")
	check(Shop.outfit_bonus(d, items).is_empty(), "kıyafetsiz bonus yok")
	d.set_flag("owned_minik_migfer")
	Shop.equip(d, "outfit", "minik_migfer")
	check(Shop.guarded(20, Shop.outfit_bonus(d, items)) == 14 and Shop.guarded(1, Shop.outfit_bonus(d, items)) == 1, "Minik Miğfer hasarı %30 azaltır, en az 1")
	for o: String in ["cicek_taci", "kasif_sapkasi", "yildiz_pelerini", "minik_migfer"]:
		check(not (items[o].get("bonus", {}) as Dictionary).is_empty(), "%s bir bonus verir" % o)
	Shop.equip(d, "outfit", "")
	# keeper house: switch keepers but keep the adventure
	Shop.buy(d, items["kristal_tilsim"], "kristal_tilsim", 120, true)
	d.add_xp(Progression.xp_to_next(1) + Progression.xp_to_next(2))
	var lv := d.level
	var piril := d.piril
	d.switch_keeper("bado", keepers["bado"]["stats"], {"variant": 1}, "Bado", items)
	var base := PlayerData.new()
	base.choose_keeper("bado", keepers["bado"]["stats"], {}, "Bado")
	check(d.character_id == "bado" and d.level == lv and d.piril == piril, "bekçi değişince seviye ve Pırıl kalır")
	var hgain := 0
	for l in range(2, lv + 1):
		hgain += Progression.hp_gain(l)
	check(d.max_hp == base.max_hp + hgain + 15, "yeni bekçinin canı: kendi canı + seviyeler + tılsım")
	var gain := 0
	for l in range(2, lv + 1):
		gain += Progression.power_gain(l)
	check(d.power == base.power + gain, "güç seviyelerle birlikte gelir")
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


func test_language() -> void:
	print("Dil")
	TranslationServer.set_locale("tr")
	check(TranslationServer.translate("Başla") == "Başla", "Türkçe seçiliyken metin Türkçe kalır (yedek dil İngilizce değil)")
	TranslationServer.set_locale("en")
	check(TranslationServer.translate("Başla") == "Start", "İngilizce seçiliyken metin İngilizce")
	TranslationServer.set_locale("tr")


func test_season2() -> void:
	print("Sezon 2: Kor Vadisi")
	var d := PlayerData.new()
	d.choose_keeper("pati", {"can": 3, "guc": 4, "hiz": 5}, {"variant": 2}, "Pati")
	while d.level < 12:
		d.add_xp(Progression.xp_to_next(d.level) - d.xp)
	d.set_flag("owned_yildiz_pelerini")
	d.equipped["outfit"] = "yildiz_pelerini"
	d.add_piril(300)
	check(not d.can_start_season2(), "Sezon 1 bitmeden Sezon 2 açılmaz")
	d.set_flag("sezon1_bitti")
	check(d.can_start_season2(), "Sezon 1 bitince Sezon 2 açılır")
	d.start_season2({})
	check(d.season == 2 and not d.can_start_season2(), "Sezon 2 başladı, bir daha başlatılmaz")
	check(d.level == 1 and d.xp == 0 and d.powers.is_empty() and d.skills.is_empty(), "Sezon 2 seviye 1, güç ve yetenek yok")
	check(d.piril == 0, "Sezon 2 Pırıl sıfırdan")
	check(d.character_id == "miril" and d.scene_id == "s2_scene1", "Prolog Mırıl ile, Sahne 1'den")
	check(d.has_flag("owned_yildiz_pelerini") and d.equipped["outfit"] == "yildiz_pelerini", "Kıyafetler kalır")
	check(d.s1_keeper.get("id", "") == "pati" and int(d.s1_keeper["look"].get("variant", 0)) == 2, "Sezon 1 bekçisi ve rengi saklanır")
	d.catch_up()
	check(d.level == 1, "Eski kayıt düzeltmesi Sezon 2'de seviyeyi yükseltmez")
	var e := PlayerData.new()
	e.load_dict(JSON.parse_string(JSON.stringify(d.to_dict())))
	check(e.season == 2 and e.s1_keeper.get("id", "") == "pati", "Sezon bilgisi kayda girer")
	check(MobStats.breathes("kopuklu_tavuk") and MobStats.breathes("gurultucu_kurbaga") and not MobStats.breathes("sumuklu"),
		"Köpüklüler nefesle sakinleşir, eski moblar değil")
	for k: String in ["kopuklu_tavuk", "gurultucu_kurbaga"]:
		check(int(MobStats.LEVELS[k]) <= 5, "%s köy seviyesinde" % k)
	check(PlayerData.POTIONS.has("nane_sekeri"), "Nane Şekeri iksir yuvasına girer")
	check(Skills.for_character("miril") == "yildiz_ninnisi", "Mırıl'ın yeteneği Yıldız Ninnisi")
	d.unlock_skill("yildiz_ninnisi")
	check(d.active_skill() == "yildiz_ninnisi", "Ninni öğrenilince L tuşunda")
	check(GurledekPlan.phase(GurledekPlan.MAX_HP) == 1 and GurledekPlan.phase(GurledekPlan.MAX_HP / 2) == 2 and GurledekPlan.phase(10) == 3, "Gürledek üç faz")
	for p in [1, 2, 3]:
		check(GurledekPlan.cycle(p).back() == "low", "Gürledek her turun sonunda alçalır (faz %d)" % p)
		check(GurledekPlan.rest(p) >= 1.0, "Gürledek saldırıları arası en az 1 sn (faz %d)" % p)
	var c := ContentScript.new()
	var s2: Dictionary = c.keepers_s2
	check((s2["order"] as Array).size() == 5 and "tipis_panda" in s2["order"], "Sezon 2 seçiminde 5 bekçi (Tıpış dahil)")
	for k: String in s2["order"]:
		check(not c.keeper(k).is_empty(), "Sezon 2 bekçisi tanımlı: %s" % k)
		check(String(s2["lines"].get(k, "")).length() in range(1, 71), "Sezon 2 repliği kısa: %s" % k)
		check(Skills.for_character(k) != "", "Sezon 2 bekçisinin yeteneği var: %s" % k)
		check(KeeperModels.INFO.has(k), "Sezon 2 bekçisinin renkleri var: %s" % k)
	check(Skills.for_character("tipis_panda") == "derin_nefes", "Tıpış: Derin Nefes")
	check(KettlePlan.phase(KettlePlan.MAX_HP) == 1 and KettlePlan.phase(10) == 2, "Çaydanlık iki faz")
	for p in [1, 2]:
		check(KettlePlan.cycle(p).back() == "lid", "Çaydanlık her turun sonunda kapağını kaldırır (faz %d)" % p)
	c.load_chapter("s2_chapter0")
	var v := PlayerData.new()
	v.start_quest(c.quests["kopuk_koy"])
	for nid: String in ["pitpit", "pamuk", "toprak", "bidik"]:
		check(c.npcs.has(nid), "Bölüm 0 komşusu konuşur: %s" % nid)
	v.start_quest(c.quests["homurdanan_caydanlik"])
	v.notify("ring", "ses_cani", c.quests)
	check(not v.objective_done("homurdanan_caydanlik", "can"), "Çan, kazan sakinleşmeden sayılmaz (sıralı)")
	v.notify("breathe", "caydanlik", c.quests)
	v.notify("ring", "ses_cani", c.quests)
	check(v.quest_state("homurdanan_caydanlik") == "ready", "Kazan + çan: görev hazır")
	check(c.shops.has("tospik"), "Tospik Nine'nin kaplıca tezgâhı var")
	check(FirfirPlan.phase(FirfirPlan.MAX_HP) == 1 and FirfirPlan.phase(FirfirPlan.MAX_HP / 2) == 2 and FirfirPlan.phase(5) == 3, "Fırfır üç faz")
	for p in [1, 2, 3]:
		check(FirfirPlan.cycle(p).back() == "tired", "Fırfır her turun sonunda oturur (faz %d)" % p)
	for k in ["kapici_rakun", "somurtkan_sincap"]:
		check(MobStats.breathes(k) and int(MobStats.LEVELS[k]) in range(5, 11), "%s: nefesle sakinleşir, orman seviyesi" % k)
	c.load_chapter("s2_chapter1")
	var o := PlayerData.new()
	o.start_quest(c.quests["once_sor"])
	for it: String in ["oyuncak_top", "oyuncak_ucurtma", "oyuncak_bebek"]:
		check(c.items.has(it), "oyuncak eşyası: %s" % it)
	o.start_quest(c.quests["firfir"])
	o.notify("breathe", "firfir", c.quests)
	check(not o.objective_done("firfir", "firfir"), "Fırfır'ı dinlemek çandan önce sayılmaz")
	check(FokurPlan.phase(FokurPlan.MAX_HP) == 1 and FokurPlan.phase(10) == 3, "Fokur üç faz")
	for p in [1, 2, 3]:
		check(FokurPlan.cycle(p).back() == "hop", "Fokur her turu zıplayıp yorularak bitirir (faz %d)" % p)
	for k in ["balon_balik", "laf_kesen_ordek"]:
		check(MobStats.breathes(k) and int(MobStats.LEVELS[k]) in range(10, 16), "%s: nefesle sakinleşir, göl seviyesi" % k)
	c.load_chapter("s2_chapter2")
	var sb := PlayerData.new()
	sb.start_quest(c.quests["sira_bekle"])
	sb.advance_objective("sira_bekle", "kucuk")
	check(not sb.objective_done("sira_bekle", "kucuk"), "Sıra bekle: en küçük önce konuşamaz")
	sb.advance_objective("sira_bekle", "dede")
	sb.advance_objective("sira_bekle", "orta")
	sb.advance_objective("sira_bekle", "kucuk")
	check(sb.quest_state("sira_bekle") == "ready", "Sıra bekle: sırayla dinleyince tamam")
	check(c.items.has("papatya_cayi") and PlayerData.POTIONS.has("papatya_cayi"), "Papatya Çayı iksir")
	for k in ["patlayan_misir", "kiskanc_civciv"]:
		check(MobStats.breathes(k) and int(MobStats.LEVELS[k]) in range(15, 21), "%s: nefesle sakinleşir, tarla seviyesi" % k)
	c.load_chapter("s2_chapter3")
	var pn := PlayerData.new()
	pn.start_quest(c.quests["panayir"])
	pn.notify("win", "balon", c.quests)
	check(pn.quest_state("panayir") == "active", "Panayır: tek oyun yetmez")
	pn.notify("win", "kosu", c.quests)
	check(pn.quest_state("panayir") == "ready", "Panayır: iki oyun kazanılınca tamam")
	# Bölüm 4: Gümbür's drum fight and the echo hunt
	for p in [1, 2, 3]:
		for bar: String in GumburPlan.bars(p):
			check(GumburPlan.valid_bar(bar), "Gümbür ölçüsü '%s' 4 vuruş, sessiz başlar (faz %d)" % [bar, p])
		check(GumburPlan.bars(p).size() == p + 1, "Gümbür faz %d: %d ölçü" % [p, p + 1])
	check(is_equal_approx(GumburPlan.BEAT, Mob.TELEGRAPH), "Gümbür: bir vuruş = uyarı süresi (ritim)")
	check(GumburPlan.phase(GumburPlan.MAX_HP) == 1 and GumburPlan.phase(0) == 3, "Gümbür fazları")
	check(GumburPlan.RING_RADIUS < 6.0, "Gümbür halkası, kenarda durunca kaçılabilir")
	for k in ["yanki_yarasasi", "tepinen_keci"]:
		check(MobStats.breathes(k) and int(MobStats.LEVELS[k]) in range(20, 26), "%s: nefesle sakinleşir, kanyon seviyesi" % k)
	c.load_chapter("s2_chapter4")
	var yk := PlayerData.new()
	yk.start_quest(c.quests["yankilar"])
	for i in 4:
		yk.notify("collect", "yanki", c.quests)
	yk.notify("collect", "tokmak", c.quests)
	check(yk.quest_state("yankilar") == "active", "Yankılar: dört yankı yetmez")
	yk.notify("collect", "yanki", c.quests)
	check(yk.quest_state("yankilar") == "ready", "Yankılar: beş yankı ve tokmak bulununca tamam")
	check(c.quests["gumbur"].get("ordered", false), "Gümbür görevi sıralı (önce çan)")
	# Bölüm 5: Hırıl's final and the words on the mountain
	for p in [1, 2, 3]:
		check(HirilPlan.cycle(p).back() == "tired", "Hırıl her turu buharı bitip yorularak bitirir (faz %d)" % p)
	check(not "summon" in HirilPlan.cycle(1), "Hırıl ilk fazda kimseyi çağırmaz")
	check(HirilPlan.MAX_SUMMONED <= 2, "Hırıl en fazla iki eski öfkeyi çağırır")
	for k in HirilPlan.SUMMONS:
		check(MobStats.breathes(k), "Hırıl'ın çağırdığı %s nefesle sakinleşir" % k)
	check(HirilPlan.steam_left(0) == 1.0 and HirilPlan.steam_left(HirilPlan.ECHOES) == 0.0, "Faz 2: her söz buharı azaltır, sonuncusu bitirir")
	for k in ["lav_damlacigi", "sus_bulutu"]:
		check(MobStats.breathes(k) and int(MobStats.LEVELS[k]) in range(25, 31), "%s: nefesle sakinleşir, dağ seviyesi" % k)
	c.load_chapter("s2_chapter5")
	for i in HirilPlan.ECHOES:
		check(c.barks.has("s2c5_e%d" % i), "Hırıl'ın söylenemeyen sözü %d var" % i)
	check(c.barks.get("s2c5_cevap", []).size() >= 2, "Faz 2: en az iki cevap seçeneği")
	var sz := PlayerData.new()
	sz.start_quest(c.quests["soylenemeyen"])
	for i in 5:
		sz.notify("collect", "hiril_soz", c.quests)
	check(sz.quest_state("soylenemeyen") == "active", "Söylenemeyen sözler: Minnoş bulunmadan bitmez")
	sz.notify("breathe", "minnos", c.quests)
	check(sz.quest_state("soylenemeyen") == "ready", "Söylenemeyen sözler: beş söz ve Minnoş ile tamam")
	var fin := PlayerData.new()
	fin.start_quest(c.quests["hiril"])
	fin.notify("listen", "hiril", c.quests)
	check(not fin.objective_done("hiril", "hiril"), "Hırıl'ı dinlemek çandan önce sayılmaz (sıralı)")
	for k: String in ["pati", "bado", "citir", "lumi", "tipis_panda"]:
		check(Season2End.ENDINGS.has(k), "Sezon 2 kapanış cümlesi: %s" % k)
	# Gökkuşağı Şenliği: every Season 2 keeper has a closing beat
	for k: String in ["pati", "bado", "citir", "lumi", "tipis_panda"]:
		check(c.barks.has("s2f_" + k), "Şenlik: %s için kapanış konuşması" % k)
	var cs: Dictionary = ContentScript.read_json("res://content/s2_chapter5/cutscenes/senlik.json")
	for step: Dictionary in cs["steps"]:
		if step.has("say"):
			check(c.barks.has(step["say"]), "Şenlik ara sahnesi: konuşma %s var" % step["say"])
	var sf := FileAccess.get_file_as_string("res://src/autoload/scene_flow.gd")
	check(sf.contains("\"s2_final\": \"res://scenes/season2/s2_final.tscn\"") and sf.contains("\"s2_final\": \"s2_chapter5\""), "Şenlik sahnesi kayıtlı")
	# Season 2 calming skills: learned at level 5, then on the skill button
	for k: String in ["pati", "bado", "citir", "lumi"]:
		var s2k := Skills.season2_for(k)
		check(s2k != "" and Skills.for_character(k) != s2k, "%s: Sezon 2 sakinleştirme yeteneği ayrı" % k)
		var kp := PlayerData.new()
		kp.season = 2
		kp.choose_keeper(k, {"max_hp": 100, "max_mp": 50, "power": 10, "speed": 6.0}, {}, k)
		check(kp.active_skill() == Skills.for_character(k), "%s: seviye 1'de kendi yeteneği" % k)
		while kp.level < Skills.S2_LEVEL:
			kp.add_xp(Progression.xp_to_next(kp.level) - kp.xp)
		check(kp.active_skill() == s2k, "%s: seviye 5'te %s açılır" % [k, s2k])
	var s1k := PlayerData.new()
	s1k.choose_keeper("pati", {"max_hp": 100, "max_mp": 50, "power": 10, "speed": 6.0}, {}, "Pati")
	while s1k.level < 8:
		s1k.add_xp(Progression.xp_to_next(s1k.level) - s1k.xp)
	check(s1k.active_skill() == "pence_kombosu", "Sezon 1'de Sezon 2 yeteneği açılmaz")
	# Ses Çanları are travel points
	var bt := PlayerData.new()
	check(BellTravel.destinations(bt, "s2_can0").is_empty(), "Seyahat: başka çan çalmadan yer yok")
	bt.set_flag("s2_can0")
	bt.set_flag("s2_can2")
	check(BellTravel.destinations(bt, "s2_can0") == ["s2_can2"], "Seyahat: yalnız çalınmış diğer çanlar")
	for b_id: String in BellTravel.BELLS:
		check(BellTravel.scene_of(b_id).begins_with("s2_chapter"), "Seyahat %s: sahne var" % b_id)
	# Sis Kalkanı and Gümbür's Ritim Tılsımı
	check(c.items.has("sis_kalkani") and PlayerData.POTIONS.has("sis_kalkani"), "Sis Kalkanı iksir")
	var rt := PlayerData.new()
	rt.choose_keeper("pati", {"max_hp": 100, "max_mp": 50, "power": 10, "speed": 6.0}, {}, "Pati")
	rt.add_piril(200)
	var pw := rt.power
	check(Shop.buy(rt, c.items["ritim_tilsimi"], "ritim_tilsimi", 120, true) == "ok" and rt.power == pw + 4, "Ritim Tılsımı +4 güç")
	rt.recompute_stats(c.items)
	check(rt.power == pw + 4, "Ritim Tılsımı gücü yeniden hesapta kalır")
	var tp := PlayerData.new()
	tp.choose_keeper("tipis_panda", c.keeper("tipis_panda")["stats"], {}, "Tıpış")
	check(tp.level == 1 and tp.active_skill() == "derin_nefes", "Tıpış seçilince seviye 1 ve Derin Nefes")
	c.load_chapter("s2_prologue")
	var dir := DirAccess.open("res://content/s2_prologue/cutscenes")
	for fname in dir.get_files():
		if fname.ends_with(".json"):
			for step: Dictionary in ContentScript.read_json("res://content/s2_prologue/cutscenes/" + fname)["steps"]:
				if step.has("say"):
					check(c.barks.has(step["say"]), "s2 ara sahne %s: konuşma %s var" % [fname, step["say"]])
	check(c.quests.has("davetiyeler") and c.quests.has("kirmizi_ruzgar"), "Sezon 2 prolog görevleri")
	var f := PlayerData.new()
	f.start_quest(c.quests["kirmizi_ruzgar"])
	f.notify("breathe", "any", c.quests)
	check(f.objective_done("kirmizi_ruzgar", "nefes"), "Bir nefes 'nefes' hedefini tamamlar")
	c.free()


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
			check(o.get("type", "deliver") in ["deliver", "defeat", "reach", "talk", "light", "ring", "collect", "breathe", "lull", "win", "listen"], "görev %s: hedef türü" % q["id"])
			if o.get("type", "") == "defeat":
				check(o["target"] in MobStats.KINDS or o["target"] in ["pus", "kutuk_kral", "kiskac", "ruzgar", "dondurma", "miril"], "görev %s: bilinmeyen mob %s" % [q["id"], o["target"]])
	c.free()
	t.free()
