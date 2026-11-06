shader_type spatial;
// Pırıltı Diyarı toon shading: two flat bands (lit / shade) with a warm
// purple shade tint instead of black, plus a thin rim light.
// Pair with outline.gdshader as next_pass for the dark cartoon contour.
render_mode specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 shade_color : source_color = vec4(0.62, 0.56, 0.78, 1.0);
uniform float band_threshold : hint_range(-1.0, 1.0) = 0.2;
uniform float band_softness : hint_range(0.0, 0.5) = 0.04;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.25;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_strength = 0.0;

void fragment() {
	ALBEDO = albedo.rgb;
	EMISSION = emission_color.rgb * emission_strength;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	vec3 band;
	if (LIGHT_IS_DIRECTIONAL) {
		// Sun / moon: hard two-tone band; cast shadows fall into the shade tone.
		float lit = smoothstep(band_threshold - band_softness, band_threshold + band_softness, ndl * ATTENUATION);
		band = mix(shade_color.rgb, vec3(1.0), lit);
		band += smoothstep(0.62, 0.68, 1.0 - dot(NORMAL, VIEW)) * lit * rim_strength;
	} else {
		// Lanterns: same bands, faded by distance so they make soft pools.
		float lit = smoothstep(band_threshold - band_softness, band_threshold + band_softness, ndl);
		band = mix(shade_color.rgb, vec3(1.0), lit) * ATTENUATION;
	}
	DIFFUSE_LIGHT += band * LIGHT_COLOR / PI;
}
