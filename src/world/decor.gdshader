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
global uniform vec3 pus_color;
global uniform float cloud_shadow;

#include "res://src/world/noise.gdshaderinc"

varying vec3 tint;
varying vec3 world_pos;
varying float glow;
varying float h;
varying float gust;

void vertex() {
	vec3 base = mix(INSTANCE_CUSTOM.rgb * COLOR.rgb, COLOR.rgb, step(0.5, COLOR.a));
	tint = base;
	glow = INSTANCE_CUSTOM.a;
	h = UV.y;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	gust = 0.0;
	if (sway > 0.0) {
		vec3 wp = world_pos;
		float t = TIME * 1.6 + wp.x * 0.35 + wp.z * 0.27;
		// gusts roll across the meadow in waves: blades bow and catch the light
		gust = smoothstep(0.35, 1.0, sin(dot(wp.xz, vec2(0.16, 0.09)) - TIME * 1.3) * 0.5 + 0.5);
		float k = UV.y * UV.y * sway;
		vec3 push = vec3(sin(t) * 0.5 + sin(t * 2.3 + 1.7) * 0.2 + gust * 1.3, 0.0,
				cos(t * 0.8) * 0.4 + gust * 0.7) * k;
		push.y = -length(push) * 0.35;
		// world push -> the instance's own (randomly turned, scaled) space
		VERTEX += (vec4(push, 0.0) * MODEL_MATRIX).xyz / dot(MODEL_MATRIX[0].xyz, MODEL_MATRIX[0].xyz);
	}
}

void fragment() {
	// grass: darker at the root, lighter at the tip
	vec3 c = tint * mix(1.0 - tip_light * 0.32, 1.0 + tip_light * 0.22, h);
	c *= 1.0 + gust * h * 0.14 * tip_light;
	float grey = dot(c, vec3(0.299, 0.587, 0.114));
	float p = clamp(pus_amount * (1.0 - glow * 0.6), 0.0, 1.0);
	ALBEDO = mix(c, vec3(grey) * pus_color, p);
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
