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
global uniform vec3 pus_color;
// Drifting cloud shadows on sunny moods (WorldLook sets it per mood).
global uniform float cloud_shadow;
// Soft lighter/darker blotches in world space (ground surfaces, see Decor).
uniform float patch_strength = 0.0;
// 0..1: drains the color toward the Pus grey-violet (imported Pus mobs)
uniform float desat : hint_range(0.0, 1.0) = 0.0;
// what `desat` fades toward (times the grey): Pus grey-violet, or warm red for Kızıl Sis mobs
uniform vec3 desat_tint = vec3(0.82, 0.8, 0.93);
uniform vec4 patch_color : source_color = vec4(1.0);
// Blinking on textured models: eye centers in character space (xyz) and
// radius (w, 0 = no eye); the lid takes the skin color around the eye.
uniform vec4 rig_eye_l = vec4(0.0);
uniform vec4 rig_eye_r = vec4(0.0);
uniform vec4 rig_lid : source_color = vec4(1.0);
uniform float rig_blink = 0.0;
// Fur color choice on textured keepers: texels near fur_from's hue take
// fur_to's hue, saturation and brightness (shading and details stay).
uniform float fur_on = 0.0;
uniform vec4 fur_from : source_color = vec4(1.0);
uniform vec4 fur_to : source_color = vec4(1.0);

// Ground detail (a grey detail map, 0.5 = no change) projected from above in
// world space, sampled at two scales/rotations so the tiling doesn't show.
uniform sampler2D ground_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float ground_strength = 0.0;
uniform float ground_scale = 0.18;

varying vec3 world_pos;
varying float world_up;

#include "res://src/world/noise.gdshaderinc"
#include "res://src/world/rig.gdshaderinc"

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

vec3 fur_shift(vec3 c) {
	vec3 hf = rgb2hsv(fur_from.rgb);
	vec3 ht = rgb2hsv(fur_to.rgb);
	vec3 hc = rgb2hsv(c);
	float dh = abs(hc.x - hf.x);
	dh = min(dh, 1.0 - dh);
	float w = (1.0 - smoothstep(0.04, 0.075, dh)) * smoothstep(0.14, 0.26, hc.y);
	vec3 n = vec3(ht.x, clamp(hc.y * ht.y / max(hf.y, 0.05), 0.0, 1.0), clamp(hc.z * ht.z / max(hf.z, 0.05), 0.0, 1.0));
	return mix(c, hsv2rgb(n), w);
}

vec3 blink_eye(vec3 c, vec4 eye) {
	if (eye.w <= 0.0) {
		return c;
	}
	vec3 d = rig_pos - eye.xyz;
	float ex = d.x / eye.w;
	float ey = d.y / (eye.w * 1.08);
	float rr = ex * ex + ey * ey;
	if (rr > 1.0 || abs(d.z) > eye.w * 2.0) {
		return c;
	}
	float inside = 1.0 - smoothstep(0.86, 1.0, rr);
	// the lid comes down from the top
	float edge = 1.0 - 2.1 * rig_blink;
	float cover = smoothstep(edge - 0.06, edge + 0.06, ey) * inside;
	c = mix(c, rig_lid.rgb, cover);
	// lashes along the lid's edge; closed, they make a soft smile curve
	float lash_y = max(edge, -0.2 + 0.35 * ex * ex);
	float line = 1.0 - smoothstep(0.07, 0.14, abs(ey - lash_y));
	return mix(c, vec3(0.165, 0.129, 0.251), line * inside * smoothstep(0.25, 0.45, rig_blink));
}

void vertex() {
	rig_pos = rig_rest(VERTEX);
	VERTEX = rig_deform(VERTEX, TIME);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_up = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz).y;
}

void fragment() {
	vec3 base = albedo.rgb * texture(albedo_tex, UV).rgb;
	if (rig_blink > 0.0) {
		base = blink_eye(blink_eye(base, rig_eye_l), rig_eye_r);
	}
	if (fur_on > 0.5) {
		base = fur_shift(base);
	}
	if (ground_strength > 0.0) {
		vec2 q = world_pos.xz * ground_scale;
		vec2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * q * 0.41 + vec2(0.37, 0.71);
		float d = texture(ground_tex, q).r + texture(ground_tex, r).r - 1.0;
		base *= 1.0 + d * ground_strength * 2.0 * smoothstep(0.5, 0.9, world_up);
	}
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
		base = mix(base, vec3(grey) * desat_tint, desat);
	}
	vec3 pus_tint = vec3(grey) * pus_color;
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
