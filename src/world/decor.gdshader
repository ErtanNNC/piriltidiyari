shader_type spatial;
// Small ground decor drawn with MultiMesh (grass, flowers, pebbles...).
// Vertex COLOR.a < 0.5 marks parts tinted by the instance's custom color
// (INSTANCE_CUSTOM.rgb); INSTANCE_CUSTOM.a is the glow amount.
// UV.y is the sway weight (0 at the base, 1 at a grass tip).
render_mode specular_disabled, cull_disabled;

uniform float sway = 0.0;
uniform float tip_light = 0.0;
uniform float band_threshold = 0.15;
global uniform float pus_amount;
global uniform float cloud_shadow;

#include "res://src/world/noise.gdshaderinc"

varying vec3 tint;
varying vec3 world_pos;
varying float glow;
varying float h;

void vertex() {
	vec3 base = mix(INSTANCE_CUSTOM.rgb * COLOR.rgb, COLOR.rgb, step(0.5, COLOR.a));
	tint = base;
	glow = INSTANCE_CUSTOM.a;
	h = UV.y;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (sway > 0.0) {
		vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float t = TIME * 1.6 + wp.x * 0.35 + wp.z * 0.27;
		float w = sin(t) * 0.6 + sin(t * 2.3 + 1.7) * 0.25;
		VERTEX.x += w * sway * UV.y * UV.y;
		VERTEX.z += cos(t * 0.8) * sway * 0.5 * UV.y * UV.y;
	}
}

void fragment() {
	// grass: darker at the root, lighter at the tip
	vec3 c = tint * mix(1.0 - tip_light * 0.32, 1.0 + tip_light * 0.22, h);
	float grey = dot(c, vec3(0.299, 0.587, 0.114));
	float p = clamp(pus_amount * (1.0 - glow * 0.6), 0.0, 1.0);
	ALBEDO = mix(c, vec3(grey) * vec3(0.92, 0.91, 0.98), p);
	EMISSION = ALBEDO * glow * 1.6;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	vec3 band;
	if (LIGHT_IS_DIRECTIONAL) {
		float lit = smoothstep(band_threshold - 0.05, band_threshold + 0.05, max(ndl, 0.35) * ATTENUATION);
		band = mix(vec3(0.66, 0.6, 0.8), vec3(1.0), lit);
		if (cloud_shadow > 0.0) {
			band = mix(band, mix(band, vec3(0.66, 0.6, 0.8), 0.75), cloud_mask(world_pos, TIME) * cloud_shadow);
		}
	} else {
		band = mix(vec3(0.66, 0.6, 0.8), vec3(1.0), smoothstep(0.1, 0.2, ndl)) * ATTENUATION;
	}
	DIFFUSE_LIGHT += band * LIGHT_COLOR / PI;
}
