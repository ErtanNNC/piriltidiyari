class_name AbilitySpot
extends Interactable
## A side path only one keeper can open with their world ability:
##   bado  – "Kayayı it"     pushes the rock aside
##   citir – "Halat at"      throws a rope bridge over the stream
##   lumi  – "Aydınlat"      lights up the dark brambles, which melt away
## Others get a friendly hint who could do it. Opened state is saved.

@export_enum("bado", "citir", "lumi") var keeper := "bado"
@export var spot_id := "kaya"
## Node to remove (or move) when opened; set by the level.
var blocker: Node3D
var push := Vector3(0, 0, -3.2)


func _build() -> void:
	action_label = {"bado": "Kayayı it", "citir": "Halat at", "lumi": "Aydınlat"}[keeper]
	match keeper:
		"citir":
			Toon.part(self, "cylinder", Vector3(0.3, 1.4, 0.34), Color("#c98d5e"), Vector3(0, 0.7, 0))
			Toon.part(self, "torus", Vector3(0.6, 0.12, 0.6), Color("#e8d4a8"), Vector3(0, 1.2, 0), Vector3(0, 0, 0))
	if GameState.data.has_flag("spot_" + spot_id):
		_open.call_deferred(true)


func use(_by: Node) -> void:
	var me := GameState.data.character_id
	if me != keeper:
		var who: String = Content.keepers[keeper]["name"]
		var what: String = {"bado": "Bu kaya çok ağır. %s itebilirdi!", "citir": "Karşıya halat lazım. %s atabilirdi!",
			"lumi": "Burası çok karanlık. %s aydınlatabilirdi!"}[keeper] % who
		GameState.toast.emit(what, "quest")
		return
	GameState.data.set_flag("spot_" + spot_id)
	_open(false)


func _open(instant: bool) -> void:
	done()
	if blocker == null:
		return
	match keeper:
		"bado":
			var to := blocker.position + push
			if instant:
				blocker.position = to
			else:
				var tw := blocker.create_tween()
				tw.tween_property(blocker, "position", to, 0.9).set_trans(Tween.TRANS_SINE)
				Effects.ring(get_parent(), blocker.global_position, 2.0, Tokens.color("spark-green"), 0.4)
		"citir":
			for c in blocker.get_children():
				if c is StaticBody3D:
					c.queue_free()   # the stream's gap collider
				else:
					(c as Node3D).visible = true
			if not instant:
				blocker.scale = Vector3(1, 1, 0.05)
				var tw := blocker.create_tween()
				tw.tween_property(blocker, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK)
		"lumi":
			if not instant:
				Effects.sparkle(get_parent(), blocker.global_position + Vector3.UP, Tokens.color("spark-yellow"), 20)
				var tw := blocker.create_tween()
				tw.tween_property(blocker, "scale", Vector3(1, 0.01, 1), 0.7)
				tw.tween_callback(blocker.queue_free)
			else:
				blocker.queue_free()
