shader_type spatial;
// Cartoon water / syrup / ice: flat color with drifting light ripple lines
// and sparkles in world space (no textures, no depth reads, phone friendly).
render_mode unshaded, cull_disabled, shadows_disabled;

#include "res://src/world/noise.gdshaderinc"
global uniform float pus_amount;
global uniform float cloud_shadow;

uniform vec4 deep : source_color = vec4(0.3, 0.6, 0.9, 1.0);
uniform vec4 light : source_color = vec4(0.8, 0.95, 1.0, 1.0);
uniform float speed = 1.0;
uniform float scale = 1.0;
uniform float sparkle = 1.0;
uniform float bob = 0.03;

varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(TIME * 1.3 * speed + wp.x * 0.7 + wp.z * 0.5) * bob;
}

void fragment() {
	vec2 q = wp.xz * 0.35 * scale;
	float t = TIME * 0.25 * speed;
	// wavy bands: noise-warped stripes, cut into thin cartoon lines
	float warp = vnoise(q * 0.8 + vec2(t, -t * 0.6)) * 2.2;
	float band = sin((q.x * 0.6 + q.y) * 3.2 + warp * 3.0 + t * 4.0);
	float line = smoothstep(0.86, 0.93, band);
	float blot = smoothstep(0.55, 0.62, vnoise(q * 0.5 - vec2(t * 0.7, t * 0.3)));
	vec3 c = mix(deep.rgb, mix(deep.rgb, light.rgb, 0.35), blot);
	c = mix(c, light.rgb, line * 0.8);
	// tiny twinkles
	vec2 cell = floor(q * 3.0);
	float r = hash21(cell);
	float tw = step(0.965, r) * smoothstep(0.6, 1.0, sin(TIME * 3.0 * speed + r * 50.0));
	c = mix(c, vec3(1.0), tw * sparkle * (1.0 - smoothstep(0.0, 0.35, length(fract(q * 3.0) - 0.5))));
	float grey = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(grey) * vec3(0.92, 0.91, 0.98), clamp(pus_amount, 0.0, 1.0));
	ALBEDO = c;
}
