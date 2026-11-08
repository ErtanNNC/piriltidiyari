class_name Patpat
extends Firfir
## Tavuk Patpat (Sezon 2 · Bölüm 3 boss): the hen who never won a single fair
## game and closed the whole fair. Same moves as Fırfır (popping corn on
## warned circles, a dash, sitting down tired), her own look: the big hen
## with a festival rosette. At 0 HP she sulks; Sakinleş = "Bir daha
## oynayalım mı?".


func _init() -> void:
	attack_color = Color("#f2c53d")
	tired_hint = "Patpat oturdu, soluk soluğa! Şimdi vur!"
	calm_event = "patpat"


func _make_model() -> Node3D:
	var root := Node3D.new()
	var hen := ModelImport.load_model("kopuklu_tavuk")
	if hen:
		hen.scale = Vector3.ONE * 2.3
		root.add_child(hen)
	else:
		Toon.part(root, "ellipsoid", Vector3(2.0, 2.0, 2.0), Color("#f4e2c0"), Vector3(0, 1.0, 0))
	# a festival rosette and the two faces' stand-ins (tears when she sulks)
	Toon.part(root, "cylinder", Vector3(0.5, 0.08, 0.5), "berry", Vector3(0.55, 1.6, 0.85), Vector3(90, 0, 0), 0.6, 0.02)
	var cross := Node3D.new()
	cross.name = "CrossFace"
	root.add_child(cross)
	MobModels._pus_wisps(cross, 2.6, Color(1, 1, 1), 6, 0.8)
	var soft := Node3D.new()
	soft.name = "SoftFace"
	soft.visible = false
	root.add_child(soft)
	for side: float in [-1.0, 1.0]:
		Toon.part(soft, "ellipsoid", Vector3(0.14, 0.24, 0.06), "sky", Vector3(0.32 * side, 1.7, 1.0), Vector3.ZERO, 0.6, 0.0)
	return root
