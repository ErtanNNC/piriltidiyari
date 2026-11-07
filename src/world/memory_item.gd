class_name MemoryItem
extends Interactable
## One of Mırıl's memories in the castle. Picking it up lets that memory
## shine brighter in the final (Faz 2).

@export var memory := 1
@export var accent := "berry"
## Display only (the final shows the memory, no pickup).
@export var display := false


func _build() -> void:
	action_label = "Al"
	match memory:
		1:  # oyuncak ayı
			Toon.part(self, "sphere", Vector3(0.7, 0.75, 0.6), Color("#c98d5e"), Vector3(0, 0.45, 0))
			Toon.part(self, "sphere", Vector3(0.55, 0.5, 0.5), Color("#c98d5e"), Vector3(0, 1.0, 0.05))
			for s in [-1.0, 1.0]:
				Toon.part(self, "sphere", Vector3(0.2, 0.2, 0.15), Color("#c98d5e"), Vector3(0.22 * s, 1.25, 0))
		2:  # doğum günü şapkası
			Toon.part(self, "cone", Vector3(0.6, 0.9, 0.6), "berry", Vector3(0, 0.55, 0))
			Toon.part(self, "sphere", Vector3(0.2, 0.2, 0.2), "spark-yellow", Vector3(0, 1.05, 0))
		3:  # yıldız haritası
			Toon.part(self, "cylinder", Vector3(0.3, 1.0, 0.3), Color("#e8d4a8"), Vector3(0, 0.4, 0), Vector3(0, 0, 90))
			Toon.part(self, "sphere", Vector3(0.18, 0.18, 0.1), "spark-yellow", Vector3(0.1, 0.62, 0.1), Vector3.ZERO, 1.0, 0.0)
		4:  # küçük fener
			Toon.part(self, "sphere", Vector3(0.5, 0.6, 0.5), "spark-white", Vector3(0, 0.55, 0), Vector3.ZERO, 0.8)
			Toon.part(self, "torus", Vector3(0.3, 0.05, 0.3), "outline", Vector3(0, 0.95, 0), Vector3(90, 0, 0), 0.0, 0.0)
	var glow := OmniLight3D.new()
	glow.light_color = Tokens.color("spark-purple")
	glow.omni_range = 3.0
	glow.light_energy = 1.0
	glow.position.y = 0.8
	add_child(glow)
	if not display and not GameState.data.has_flag("ani_%d" % memory):
		Beacon.attach(self, 1.9, Tokens.color("spark-purple").lightened(0.3))
	if display:
		(func() -> void: done()).call_deferred()
	elif GameState.data.has_flag("ani_%d" % memory):
		(func() -> void: queue_free()).call_deferred()


func _process(delta: float) -> void:
	rotation.y += delta * 0.8


func use(_by: Node) -> void:
	if GameState.data.has_flag("ani_%d" % memory):
		return
	GameState.data.set_flag("ani_%d" % memory)
	Audio.play("memory")
	GameState.notify("collect", "ani")
	GameState.bark("ani_%d" % memory)
	Effects.sparkle(get_parent(), global_position + Vector3.UP, Tokens.color("spark-purple"), 14)
	done()
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
