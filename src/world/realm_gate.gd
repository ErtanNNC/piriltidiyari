class_name RealmGate
extends Interactable
## After Season 3 the three realms are one travel net: the Kabuk Kayık sails
## to Gökkuşağı Köyü and Kaplıca Köyü ("Başka yerler…" on the boat), and
## this little flare post in those villages ("Seyahat") brings you back.
## Only there in a Season 3 save that finished the season.

const REALMS := {
	"chapter0": "Pırıltı Diyarı: Gökkuşağı Köyü",
	"s2_chapter0": "Kor Vadisi: Kaplıca Köyü",
	"s3_chapter0": "Titrek Kıyılar: Mercan Koyu",
}

var here := ""


## Adds the post to a village scene when this save may travel.
static func place(scene: Node3D, scene_id: String, at: Vector3) -> void:
	var d := GameState.data
	if not d.has_flag("sezon3_bitti"):
		return
	var g := RealmGate.new()
	g.name = "RealmGate"
	g.here = scene_id
	g.position = at
	scene.add_child(g)


func _build() -> void:
	action_label = "Seyahat"
	reach = 1.8
	if not ModelImport.fit_static("isaret_fisegi", self, Vector3(0, 0.9, 0), Vector3(0.8, 1.8, 0.8)):
		Toon.part(self, "cylinder", Vector3(0.3, 1.4, 0.3), Color("#e8604a"), Vector3(0, 0.7, 0))
		Toon.part(self, "sphere", Vector3(0.4, 0.5, 0.4), "spark-yellow", Vector3(0, 1.6, 0), Vector3.ZERO, 1.4, 0.02)
	TravelSign.board(self, "Diyarlar Arası", Vector3(0, 2.4, 0), 2.4)
	Beacon.attach(self, 3.2, Tokens.color("spark-white"))


func use(_by: Node) -> void:
	var hud := get_tree().get_first_node_in_group("hud") as Hud
	if hud == null:
		return
	var opts := []
	for id: String in REALMS:
		if id != here:
			opts.append({"id": id, "label": REALMS[id]})
	var pick: String = await hud.ask("Nereye gidelim?", opts)
	if pick == "":
		return
	Audio.play("whoosh")
	SceneFlow.go_to(pick)
