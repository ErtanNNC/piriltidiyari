class_name ArmSwing
extends SkeletonModifier3D
## Bends a rigged model's arms after its animation clip played (the clip
## alone barely moves them): CharacterRig sets `lift` and `chop` for a strike.

var arm_r := -1
var arm_l := -1
var fwd := Vector3(0, 0, 1)
var lift := 0.0
var chop := 0.0


func _process_modification() -> void:
	if absf(lift) < 0.001 and absf(chop) < 0.001:
		return
	var sk := get_skeleton()
	if sk == null:
		return
	var side_axis := fwd.cross(Vector3.UP).normalized()
	for b: int in [arm_r, arm_l]:
		if b < 0:
			continue
		var right := b == arm_r
		var amount := 1.0 if right else 0.3
		var s_out := -1.0 if right else 1.0
		var g := sk.get_bone_global_pose(b)
		g.basis = Basis(side_axis, chop * amount) * Basis(fwd, s_out * lift * 1.3 * amount) * g.basis
		sk.set_bone_global_pose(b, g)
