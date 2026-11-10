extends S3Island
## Sezon 3 · Bölüm 1 – Mürekkep Adası (yapım aşamasında).


func _ready() -> void:
	begin("s3_chapter1")
	land(Vector3.ZERO, Vector2(40, 40), Color("#c7ad7c"))
	fence(Vector3.ZERO, Vector2(40, 40))
	dock(Vector3(0, 0, 18))
