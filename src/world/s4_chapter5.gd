extends S4Garden
## Sezon 4 · Bölüm 5 – Gölge Köşesi. STUB: replaced by the real scene.


func _ready() -> void:
	begin_garden("s4_chapter5")
	land(Vector3(0, 0, 0), Vector2(40, 56), Color("#8fcf7a"))
	fence(Vector3(0, 0, 0), Vector2(38, 54))
	gate(Vector3(0, 0, 25.0))
	Decor.auto(self, "cayir")
	_player.respawn_point = _player.global_position
