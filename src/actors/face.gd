class_name Face
extends RefCounted
## Shared cartoon face: big glossy eyes with two highlights (they blink, see
## CharacterRig), a small mouth, blush and optional brows, placed on the
## surface of a head ellipsoid (`center`, `radii`, facing +Z).
##   mouth: "smile", "cat" (w), "o", "flat", "teeth", "none"
## `eye_y` is the eye height relative to the head center (in radii.y units).


static func add(head: Node3D, center: Vector3, radii: Vector3, mouth := "smile",
		brows := false, spread := 0.38, eye_y := 0.1, eye_size := 1.0, iris: Variant = "outline") -> Node3D:
	var face := Node3D.new()
	face.name = "Face"
	head.add_child(face)
	var k := radii.x / 0.45 * eye_size  # feature scale
	for s: float in [-1.0, 1.0]:
		var ex := spread * radii.x * s
		var ey := eye_y * radii.y
		var eye := Node3D.new()
		eye.name = "EyeL" if s > 0 else "EyeR"
		eye.add_to_group("rig_eye")
		eye.position = _on(center, radii, ex, ey, -0.015 * k)
		# turn the eye to sit flat on the curved head
		eye.rotation.y = asin(clampf(ex / radii.x, -1.0, 1.0)) * 0.6
		face.add_child(eye)
		Toon.part(eye, "ellipsoid", Vector3(0.15, 0.2, 0.07) * k, iris, Vector3.ZERO, Vector3.ZERO, 0.0, 0.0)
		Toon.part(eye, "ellipsoid", Vector3(0.1, 0.09, 0.04) * k, Color("#6a55a8"), Vector3(0, -0.045, 0.02) * k, Vector3.ZERO, 0.0, 0.0)
		Toon.part(eye, "ellipsoid", Vector3(0.065, 0.075, 0.03) * k, Color.WHITE, Vector3(0.025 * s, 0.045, 0.032) * k, Vector3.ZERO, 0.7, 0.0)
		Toon.part(eye, "ellipsoid", Vector3(0.03, 0.03, 0.02) * k, Color.WHITE, Vector3(-0.03 * s, -0.05, 0.034) * k, Vector3.ZERO, 0.7, 0.0)
		var bx := (spread + 0.27) * radii.x * s
		var blush := Toon.part(face, "ellipsoid", Vector3(0.16, 0.075, 0.04) * k, "berry",
			_on(center, radii, bx, ey - 0.3 * radii.y, -0.012 * k), Vector3(0, rad_to_deg(asin(clampf(bx / radii.x, -1.0, 1.0))), 0), 0.0, 0.0)
		blush.transparency = 0.3
		if brows:
			Toon.part(face, "capsule", Vector3(0.032, 0.12, 0.032) * k, "outline",
				_on(center, radii, ex, ey + 0.36 * radii.y, 0.0), Vector3(0, 0, 75 * s), 0.0, 0.0)
	var my := eye_y * radii.y - 0.4 * radii.y
	var mz := func(x: float) -> Vector3: return _on(center, radii, x, my, -0.004 * k)
	match mouth:
		"smile":
			for s: float in [-1.0, 1.0]:
				Toon.part(face, "capsule", Vector3(0.026, 0.08, 0.026) * k, "outline", mz.call(0.028 * s * k), Vector3(0, 0, -62 * s), 0.0, 0.0)
		"teeth":
			for s: float in [-1.0, 1.0]:
				Toon.part(face, "capsule", Vector3(0.026, 0.08, 0.026) * k, "outline", mz.call(0.028 * s * k), Vector3(0, 0, -62 * s), 0.0, 0.0)
				Toon.part(face, "box", Vector3(0.035, 0.05, 0.02) * k, Color.WHITE, mz.call(0.019 * s * k) + Vector3(0, -0.035 * k, 0), Vector3.ZERO, 0.0, 0.01)
		"cat":
			for s: float in [-1.0, 1.0]:
				Toon.part(face, "capsule", Vector3(0.024, 0.065, 0.024) * k, "outline", mz.call(0.02 * s * k), Vector3(0, 0, -58 * s), 0.0, 0.0)
				Toon.part(face, "capsule", Vector3(0.024, 0.065, 0.024) * k, "outline", mz.call(0.062 * s * k), Vector3(0, 0, 58 * s), 0.0, 0.0)
		"o":
			Toon.part(face, "ellipsoid", Vector3(0.07, 0.08, 0.03) * k, Color("#7a3550"), mz.call(0.0), Vector3.ZERO, 0.0, 0.0)
		"flat":
			Toon.part(face, "capsule", Vector3(0.024, 0.09, 0.024) * k, "outline", mz.call(0.0), Vector3(0, 0, 90), 0.0, 0.0)
	return face


## A point on the front of the ellipsoid at (x, y) from its center, pushed out by `out`.
static func _on(center: Vector3, radii: Vector3, x: float, y: float, out: float) -> Vector3:
	var u := 1.0 - pow(x / radii.x, 2) - pow(y / radii.y, 2)
	var z := radii.z * sqrt(maxf(u, 0.0))
	return center + Vector3(x, y, z + out + 0.012)
