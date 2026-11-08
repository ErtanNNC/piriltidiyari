shader_type spatial;
// Pırıltı Diyarı toon shading: two flat bands (lit / shade) with a warm
// purple shade tint instead of black, plus a thin rim light.
// Pair with outline.gdshader as next_pass for the dark cartoon contour.
render_mode specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
// Imported models (ModelImport) bring their own color texture.
uniform sampler2D albedo_tex : source_color, hint_default_white, filter_linear_mipmap;
uniform vec4 shade_color : source_color = vec4(0.62, 0.56, 0.78, 1.0);
uniform float band_threshold : hint_range(-1.0, 1.0) = 0.2;
uniform float band_softness : hint_range(0.0, 0.5) = 0.04;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.25;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_strength = 0.0;
// How much the Pus can grey this surface (lanterns and sparks resist it).
uniform float pus_affect : hint_range(0.0, 1.0) = 1.0;
// 0 = full color, 1 = everything grey. Set with Pus.set_amount().
global uniform float pus_amount;
// Drifting cloud shadows on sunny moods (WorldLook sets it per mood).
global uniform float cloud_shadow;
// Soft lighter/darker blotches in world space (ground surfaces, see Decor).
uniform float patch_strength = 0.0;
// 0..1: drains the color toward the Pus grey-violet (imported Pus mobs)
uniform float desat : hint_range(0.0, 1.0) = 0.0;
uniform vec4 patch_color : source_color = vec4(1.0);

varying vec3 world_pos;

#include "res://src/world/noise.gdshaderinc"

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base = albedo.rgb * texture(albedo_tex, UV).rgb;
	if (patch_strength > 0.0) {
		vec2 q = world_pos.xz;
		float n = vnoise(q * 0.16) * 0.65 + vnoise(q * 0.47 + 7.1) * 0.35;
		// two soft steps so it stays cartoon-flat, not noisy
		float darker = 1.0 - smoothstep(0.33, 0.39, n);
		float lighter = smoothstep(0.61, 0.67, n);
		base = mix(base, base * (1.0 - patch_strength), darker * 0.8);
		base = mix(base, mix(base, patch_color.rgb, 0.5) * (1.0 + patch_strength * 0.5), lighter * 0.8);
	}
	float grey = dot(base, vec3(0.299, 0.587, 0.114));
	if (desat > 0.0) {
		base = mix(base, vec3(grey) * vec3(0.82, 0.8, 0.93), desat);
	}
	vec3 pus_tint = vec3(grey) * vec3(0.92, 0.91, 0.98);
	float p = clamp(pus_amount * pus_affect, 0.0, 1.0);
	ALBEDO = mix(base, pus_tint, p);
	EMISSION = mix(emission_color.rgb, vec3(grey), p * 0.7) * emission_strength;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	vec3 band;
	if (LIGHT_IS_DIRECTIONAL) {
		// Sun / moon: hard two-tone band; cast shadows fall into the shade tone.
		float lit = smoothstep(band_threshold - band_softness, band_threshold + band_softness, ndl * ATTENUATION);
		band = mix(shade_color.rgb, vec3(1.0), lit);
		band += smoothstep(0.62, 0.68, 1.0 - dot(NORMAL, VIEW)) * lit * rim_strength;
		if (cloud_shadow > 0.0) {
			band = mix(band, mix(band, shade_color.rgb, 0.75), cloud_mask(world_pos, TIME) * cloud_shadow);
		}
	} else {
		// Lanterns: same bands, faded by distance so they make soft pools.
		float lit = smoothstep(band_threshold - band_softness, band_threshold + band_softness, ndl);
		band = mix(shade_color.rgb, vec3(1.0), lit) * ATTENUATION;
	}
	DIFFUSE_LIGHT += band * LIGHT_COLOR / PI;
}
