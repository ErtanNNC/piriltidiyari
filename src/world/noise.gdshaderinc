// Shared cheap noise + the moving cloud-shadow mask (toon, decor, sky).
// Needs: global uniform float cloud_shadow; (0 = off) declared by the includer.

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
			mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

// 0..1: how much a world point lies under a drifting cloud shadow.
float cloud_mask(vec3 wp, float t) {
	vec2 q = wp.xz * 0.03 + t * vec2(0.012, 0.006);
	float c = vnoise(q) * 0.62 + vnoise(q * 2.7 + 5.3) * 0.38;
	return smoothstep(0.56, 0.64, c);
}
