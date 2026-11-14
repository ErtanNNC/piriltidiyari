class_name ShinyToy
extends Area3D
## Season 4 · Parlak Pazar: a shiny toy a Kapkaç Karga let go. Walking into
## it picks it up (flag `held_flag`): the keeper then carries it back to the
## stall it was taken from. `look()` draws a toy anywhere (in a crow's beak,
## on its owner's stall, in Şıkır's nest).

signal taken(toy_id: String)

const KINDS := {
	"zil": {"name": "Altın Zil", "color": "#ffd24a"},
	"bilye": {"name": "Cam Bilye", "color": "#7fd0ff"},
	"firildak": {"name": "Gümüş Fırıldak", "color": "#f08ac0"},
	"boncuk": {"name": "İlk Boncuk", "color": "#6ad0a0"},
}

var toy_id := "zil"
var held_flag := ""
var _visual: Node3D
var _t := 0.0
var _taken := false


## A small glowing toy under `parent`.
static func look(parent: Node3D, id: String, at := Vector3.ZERO, s := 1.0) -> Node3D:
	var col := Color(String(KINDS.get(id, KINDS["zil"])["color"]))
	var n := Node3D.new()
	n.position = at
	n.scale = Vector3.ONE * s
	parent.add_child(n)
	match id:
		"zil":
			Toon.part(n, "cone", Vector3(0.44, 0.44, 0.44), col, Vector3(0, 0.26, 0), Vector3.ZERO, 0.9, 0.025)
			Toon.part(n, "sphere", Vector3(0.14, 0.14, 0.14), col.darkened(0.25), Vector3(0, 0.03, 0), Vector3.ZERO, 0.4, 0.02)
			Toon.part(n, "ring", Vector3(0.16, 0.03, 0.16), col.darkened(0.2), Vector3(0, 0.52, 0), Vector3(90, 0, 0), 0.4, 0.0)
		"firildak":
			Toon.part(n, "cylinder", Vector3(0.05, 0.6, 0.05), Color("#b98a5a"), Vector3(0, 0.1, 0))
			for k in 4:
				var a := k * PI * 0.5
				Toon.part(n, "ellipsoid", Vector3(0.3, 0.14, 0.05), col if k % 2 == 0 else Color("#e8eef6"),
					Vector3(cos(a) * 0.15, 0.4 + sin(a) * 0.15, 0.05), Vector3(0, 0, rad_to_deg(a)), 0.8, 0.02)
		_:
			Toon.part(n, "sphere", Vector3(0.36, 0.36, 0.36), col, Vector3(0, 0.22, 0), Vector3.ZERO, 1.0, 0.025)
			Toon.part(n, "sphere", Vector3(0.12, 0.12, 0.12), col.lightened(0.6), Vector3(0.07, 0.3, 0.1), Vector3.ZERO, 1.4, 0.0)
	return n


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var c := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.9
	c.shape = s
	c.position.y = 0.6
	add_child(c)
	_visual = look(self, toy_id, Vector3(0, 0.5, 0), 1.5)
	var l := OmniLight3D.new()
	l.light_color = Color(String(KINDS[toy_id]["color"]))
	l.omni_range = 3.0
	l.light_energy = 1.2
	l.position.y = 0.9
	add_child(l)
	Beacon.attach(self, 1.8, Color(String(KINDS[toy_id]["color"])).lightened(0.3))
	body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_t += delta
	_visual.position.y = 0.5 + sin(_t * 2.5) * 0.12
	_visual.rotation.y += delta * 1.6


func _on_body(body: Node3D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	if held_flag != "":
		GameState.data.set_flag(held_flag)
	Audio.play("coin")
	GameState.toast.emit(TranslationServer.translate("%s bulundu!") % TranslationServer.translate(String(KINDS[toy_id]["name"])), "star")
	taken.emit(toy_id)
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
