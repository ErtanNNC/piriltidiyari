class_name SpringGate
extends Interactable
## Season 4: a Bahar Kapısı, the arch between the gardens ("Geç"). Lists
## every garden in story order like the Kabuk Kayık's menu (`GardenTravel`):
## buradasın / tamam / ŞİMDİ BURAYA! / dikenli. You arrive at that garden's
## own gate (every garden scene starts the keeper there).

@export var here := "s4_chapter0"


func _build() -> void:
	action_label = "Geç"
	reach = 2.2
	if ModelImport.fit_static("bahar_kapisi", self, Vector3(0, 2.1, 0), Vector3(4.2, 4.2, 1.6)) == null:
		for x: float in [-1.6, 1.6]:
			Toon.part(self, "box", Vector3(0.7, 3.4, 0.9), Color("#b9b3c4"), Vector3(x, 1.7, 0))
		Toon.part(self, "box", Vector3(3.9, 0.7, 0.9), Color("#b9b3c4"), Vector3(0, 3.6, 0))
		Toon.part(self, "ring", Vector3(3.2, 0.12, 3.2), Color("#3f8a4a"), Vector3(0, 2.0, 0.1), Vector3(90, 0, 0))
	TravelSign.board(self, "Bahar Kapısı", Vector3(-2.6, 1.5, 0.4), 2.4)
	Toon.part(self, "box", Vector3(0.14, 1.4, 0.14), Color("#a8794f"), Vector3(-2.6, 0.7, 0.35))


func use(_by: Node) -> void:
	var d := GameState.data
	var hud := get_tree().get_first_node_in_group("hud") as Hud
	if hud == null:
		return
	var opts := []
	var noted := false
	for e: Dictionary in GardenTravel.menu(d, here):
		var name_tr := TranslationServer.translate(GardenTravel.region(e["scene"]))
		var o := {"id": e["scene"], "label": "%d · %s" % [e["n"], name_tr], "primary": false}
		match e["state"]:
			"here":
				o["label"] += TranslationServer.translate(" · buradasın")
				o["enabled"] = false
				if not GardenTravel.is_done(d, here):
					noted = true
					o["note"] = "Bu bahçenin işi bitmedi. Bitince sıradaki kapı çiçek açar."
			"done":
				o["label"] += TranslationServer.translate(" · tamam")
			"next":
				o["label"] += TranslationServer.translate(" · ŞİMDİ BURAYA!")
				o["primary"] = true
			"locked":
				o["label"] += TranslationServer.translate(" · dikenli")
				o["enabled"] = false
				if not noted:
					noted = true
					o["note"] = "Kapı henüz çiçek açmadı."
		opts.append(o)
	var pick: String = await hud.ask("Bahar Kapısı nereye açılsın?", opts)
	if pick == "":
		return
	Audio.play("whoosh")
	SceneFlow.go_to(pick)
