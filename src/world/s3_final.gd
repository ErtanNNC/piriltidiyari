extends S3Island
## Sezon 3 · Kapanış – Fener Gecesi (yapım aşamasında).


func _ready() -> void:
	begin("s3_final")
	land(Vector3.ZERO, Vector2(40, 40), Color("#c7ad7c"))
	fence(Vector3.ZERO, Vector2(40, 40))
	dock(Vector3(0, 0, 18))
