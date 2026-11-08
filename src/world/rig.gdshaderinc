// Shape-based "rig" for imported models that have no skeleton (CharacterRig
// drives it, ModelImport sets it up). Vertices are moved in character space
// (the Pose: feet on y=0, facing +Z) by where they sit on the body:
//   feet (low)        -> step forward/back and lift, left/right in turn
//   arms (out to the sides, mid height) -> swing, strike, cheer, or flap
//   head (high)       -> look around, nod, tilt
//   tail (far behind) -> wag
// Weights fade softly between regions, so the mesh bends instead of tearing.
// Also used by outline.gdshader so the contour moves with the body.

uniform float rig_on = 0.0;
uniform mat4 rig_to;     // mesh space -> character space
uniform mat4 rig_from;   // character space -> mesh space
uniform float rig_h = 2.0;  // model height (m); shape values are fractions of it
// x: legs below, y: arms start this far out, z/w: arm band (low, high)
uniform vec4 rig_shape = vec4(0.14, 0.17, 0.14, 0.42);
// x: neck height, y: tail behind this z (0 = none), z: wings (0..1), w: leg stride
uniform vec4 rig_shape2 = vec4(0.46, 0.0, 0.0, 1.0);
// x: step phase, y: walk 0..1, z: strike 0..1, w: arms up 0..1
uniform vec4 rig_motion = vec4(0.0);
// x: head yaw, y: nod, z: tilt, w: tail wag (radians)
uniform vec4 rig_head = vec4(0.0);
// Extra arm/wing/claw turns driven by game code (bosses): x/y = rotation
// around X/Z of the +x side, z/w = the same for the -x side.
uniform vec4 rig_arms = vec4(0.0);

// set in vertex() before deforming: rig_pos = rig_rest(VERTEX);
varying vec3 rig_pos;

vec3 rig_rest(vec3 v) {
	return rig_on > 0.5 ? (rig_to * vec4(v, 1.0)).xyz : vec3(0.0);
}

vec3 rig_rx(vec3 p, float a) {
	float c = cos(a), s = sin(a);
	return vec3(p.x, p.y * c - p.z * s, p.y * s + p.z * c);
}

vec3 rig_ry(vec3 p, float a) {
	float c = cos(a), s = sin(a);
	return vec3(p.x * c + p.z * s, p.y, -p.x * s + p.z * c);
}

vec3 rig_rz(vec3 p, float a) {
	float c = cos(a), s = sin(a);
	return vec3(p.x * c - p.y * s, p.x * s + p.y * c, p.z);
}

vec3 rig_deform(vec3 v, float time) {
	if (rig_on < 0.5) {
		return v;
	}
	vec3 p = (rig_to * vec4(v, 1.0)).xyz;
	float H = rig_h;
	float hn = p.y / H;
	float sgn = p.x >= 0.0 ? 1.0 : -1.0;
	float side = clamp(p.x / (0.05 * H), -1.0, 1.0);
	float s = sin(rig_motion.x);
	float walk = rig_motion.y;
	// --- head: look, nod, tilt around the neck
	float neck = rig_shape2.x;
	float wh = smoothstep(neck - 0.05, neck + 0.05, hn);
	if (wh > 0.0) {
		vec3 piv = vec3(0.0, neck * H, 0.0);
		vec3 r = p - piv;
		r = rig_ry(r, rig_head.x * wh);
		r = rig_rx(r, rig_head.y * wh);
		r = rig_rz(r, rig_head.z * wh);
		p = piv + r;
	}
	// --- arms (or wings)
	float ax = abs(p.x) / H;
	float wa = smoothstep(rig_shape.y, rig_shape.y + 0.07, ax)
			* smoothstep(rig_shape.z - 0.05, rig_shape.z + 0.02, hn)
			* (1.0 - smoothstep(rig_shape.w - 0.02, rig_shape.w + 0.05, hn));
	if (wa > 0.0) {
		vec3 piv = vec3(sgn * rig_shape.y * H, rig_shape.w * H * 0.92, 0.0);
		vec3 r = p - piv;
		float wings = rig_shape2.z;
		if (wings > 0.0) {
			float flap = sin(time * (7.0 + 7.0 * walk)) * (0.25 + 0.4 * walk) * wings;
			r = rig_rz(r, sgn * (flap + rig_motion.w * 0.6) * wa);
		} else {
			// walk swing opposite to the legs; the right arm (-x) strikes
			float swing = sgn * s * 0.8 * walk;
			float strike = rig_motion.z * (sgn < 0.0 ? -1.9 : -0.35);
			r = rig_rx(r, (swing + strike) * wa);
			r = rig_rz(r, sgn * rig_motion.w * 1.2 * wa);
		}
		vec2 extra = sgn > 0.0 ? rig_arms.xy : rig_arms.zw;
		r = rig_rx(r, extra.x * wa);
		r = rig_rz(r, extra.y * wa);
		p = piv + r;
	}
	// --- legs: the low part steps, left and right in turn
	float wl = 1.0 - smoothstep(rig_shape.x * 0.3, rig_shape.x, hn);
	if (wl > 0.0 && walk > 0.0) {
		float stride = rig_shape2.w;
		p.z += side * s * 0.1 * H * walk * wl * stride;
		p.y += max(0.0, side * s) * 0.06 * H * walk * wl * stride;
	}
	// --- tail wag
	if (rig_shape2.y < 0.0) {
		float tz = rig_shape2.y * H;
		float wt = smoothstep(tz, tz - 0.12 * H, p.z);
		if (wt > 0.0) {
			vec3 piv = vec3(0.0, p.y, tz);
			p = piv + rig_ry(p - piv, rig_head.w * wt);
		}
	}
	return (rig_from * vec4(p, 1.0)).xyz;
}
