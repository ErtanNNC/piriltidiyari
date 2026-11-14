class_name HirilModel
extends RefCounted
## Hırıl: a little volcano kid from Kor Vadisi's mountain. A round warm-brown
## cone of a body, a glowing ember crater on top, stubby arms and feet, big
## eyes under grumpy brows, and steam puffing out of the crater. Built from
## named parts (Body, Head, HandL/R, FootL/R) so CharacterRig breathes and
## steps it. Faces +Z.


static func build(calm := false) -> Node3D:
	var real := ModelImport.boss("hiril", [])
	if real:
		if calm:
			real.tree_entered.connect(_wear.bind(real), CONNECT_ONE_SHOT)
		return real
	var root := Node3D.new()
	Toon.default_pus = 0.0
	var rock := Color("#8a4a3a")
	var rock_light := Color("#a85a42")
	var body := Toon.part(root, "cone", Vector3(1.25, 1.35, 1.2), rock, Vector3(0, 0.72, 0), Vector3.ZERO, 0.0, 0.035)
	body.name = "Body"
	var belly := Toon.part(body, "ellipsoid", Vector3(0.7, 0.55, 0.3), rock_light, Vector3(0, -0.18, 0.42), Vector3.ZERO, 0.0, 0.0)
	belly.name = "Belly"
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.25, 0)
	root.add_child(head)
	# the crater: a glowing ember ring on top
	Toon.part(head, "cylinder", Vector3(0.62, 0.16, 0.62), rock, Vector3(0, 0.1, 0), Vector3.ZERO, 0.0, 0.03)
	Toon.part(head, "cylinder", Vector3(0.44, 0.06, 0.44), "honey" if calm else "hp", Vector3(0, 0.19, 0), Vector3.ZERO, 2.4, 0.0)
	var glow := OmniLight3D.new()
	glow.light_color = Tokens.color("honey" if calm else "hp")
	glow.light_energy = 1.2
	glow.omni_range = 3.0
	glow.position = Vector3(0, 0.5, 0)
	head.add_child(glow)
	# face on the front of the body
	for side: float in [-1.0, 1.0]:
		var eye := Node3D.new()
		eye.add_to_group("rig_eye")
		eye.position = Vector3(0.17 * side, 0.92, 0.42)
		root.add_child(eye)
		Toon.part(eye, "ellipsoid", Vector3(0.17, 0.22, 0.07), "outline", Vector3.ZERO, Vector3.ZERO, 0.0, 0.0)
		Toon.part(eye, "ellipsoid", Vector3(0.06, 0.07, 0.03), Color.WHITE, Vector3(0.03 * side, 0.05, 0.035), Vector3.ZERO, 0.7, 0.0)
		if not calm:
			Toon.part(root, "box", Vector3(0.2, 0.05, 0.05), "outline", Vector3(0.17 * side, 1.08, 0.44), Vector3(0, 0, -24 * side), 0.0, 0.0)
		else:
			var blush := Toon.part(root, "ellipsoid", Vector3(0.12, 0.06, 0.03), "berry", Vector3(0.3 * side, 0.8, 0.4), Vector3.ZERO, 0.0, 0.0)
			blush.transparency = 0.3
		var hand := Toon.part(root, "ellipsoid", Vector3(0.22, 0.3, 0.22), rock_light, Vector3(0.6 * side, 0.6, 0.1), Vector3(0, 0, 25 * side), 0.0, 0.03)
		hand.name = "HandL" if side < 0 else "HandR"
		var foot := Toon.part(root, "ellipsoid", Vector3(0.3, 0.16, 0.36), rock, Vector3(0.25 * side, 0.08, 0.08), Vector3.ZERO, 0.0, 0.03)
		foot.name = "FootL" if side < 0 else "FootR"
	for side: float in [-1.0, 1.0]:
		Toon.part(root, "capsule", Vector3(0.03, 0.09, 0.03), "outline", Vector3(0.03 * side, 0.74, 0.45),
			Vector3(0, 0, (55.0 if not calm else -55.0) * side), 0.0, 0.0)
	# steam from the crater (white when calm, warm grey when cross)
	MobModels._pus_wisps(head, 0.35, Color(1, 1, 1) if calm else Color(0.85, 0.75, 0.75), 6, 0.6)
	Toon.default_pus = 1.0
	CharacterRig.attach(root)
	if calm:
		root.tree_entered.connect(_wear.bind(root), CONNECT_ONE_SHOT)
	return root


## Hırıl as the keeper in play (Yeni Oyun+): Player builds him straight from
## here, so the shop outfit and tool go on when the model joins the player.
## (KeeperModels.build dresses its own copies; `dress` runs once per model.)
static func _wear(model: Node3D) -> void:
	if not (model.get_parent() is Player) or GameState.data.character_id != "hiril":
		return
	var eq: Dictionary = GameState.data.equipped
	KeeperModels.dress(model, "hiril", {"outfit": eq.get("outfit", ""), "weapon": eq.get("weapon", "")})
