shader_type sky;
// Cartoon sky: color gradient, sun/moon disc with a soft halo, flat two-tone
// clouds drifting by, twinkling stars and a rainbow. The Pus greys it all
// (same pus_amount as the world). Colors come per mood from WorldLook.

global uniform float pus_amount;
global uniform float cloud_shadow;
#include "res://src/world/noise.gdshaderinc"

uniform vec4 top_color : source_color = vec4(0.48, 0.72, 0.94, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.91, 0.96, 1.0, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.81, 0.9, 1.0, 1.0);
uniform vec4 cloud_color : source_color = vec4(1.0);
uniform vec4 cloud_shade : source_color = vec4(0.8, 0.85, 0.95, 1.0);
uniform float cloud_amount : hint_range(0.0, 1.0) = 0.5;
uniform float star_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 sun_color : source_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform float sun_size = 0.0012;
uniform float sun_visible : hint_range(0.0, 1.0) = 1.0;
uniform float rainbow : hint_range(0.0, 1.0) = 0.0;

vec3 hue(float h) {
	vec3 k = clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return k;
}

void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	vec3 col;
	if (h > 0.0) {
		col = mix(horizon_color.rgb, top_color.rgb, smoothstep(0.0, 0.55, h));
	} else {
		col = mix(horizon_color.rgb, bottom_color.rgb, smoothstep(0.0, -0.25, h));
	}
	if (!AT_CUBEMAP_PASS) {
		float clear = 1.0 - pus_amount;
		// stars: one dot per cell of a dome projection, twinkling
		if (star_amount > 0.0 && h > 0.02) {
			vec2 uv = d.xz / (h + 0.35) * 26.0;
			vec2 cell = floor(uv);
			float r = hash21(cell);
			if (r > 0.9) {
				vec2 c = cell + vec2(hash21(cell + 3.1), hash21(cell + 7.7)) * 0.6 + 0.2;
				float dist = length(uv - c);
				float tw = 0.65 + 0.35 * sin(TIME * (1.5 + r * 3.0) + r * 40.0);
				float star = smoothstep(0.09, 0.0, dist) * tw * star_amount * smoothstep(0.02, 0.25, h);
				col = mix(col, vec3(1.0, 0.97, 0.88), star * (0.4 + 0.6 * clear));
			}
		}
		// rainbow: a ring 40-43 degrees from the point opposite the sun
		if (rainbow > 0.0 && LIGHT0_ENABLED && h > -0.02) {
			float a = acos(clamp(dot(d, -LIGHT0_DIRECTION), -1.0, 1.0));
			float band = (a - 0.69) / 0.06;
			if (band > 0.0 && band < 1.0) {
				float edge = smoothstep(0.0, 0.15, band) * smoothstep(1.0, 0.85, band);
				col = mix(col, hue(0.78 * band), edge * 0.55 * rainbow * smoothstep(-0.02, 0.15, h));
			}
		}
		// sun or moon
		if (LIGHT0_ENABLED) {
			float dist = 1.0 - dot(d, LIGHT0_DIRECTION);
			float disc = 1.0 - smoothstep(sun_size * 0.8, sun_size, dist);
			float halo = exp(-dist * 60.0) * 0.35 + exp(-dist * 8.0) * 0.12;
			float vis = sun_visible * clear;
			col = mix(col, sun_color.rgb, disc * vis);
			col += sun_color.rgb * halo * vis;
		}
		// two-tone clouds on a dome, drifting
		if (cloud_amount > 0.0 && h > 0.0) {
			vec2 uv = d.xz / (h + 0.18) * 0.95 + TIME * vec2(0.022, 0.006);
			float n = vnoise(uv) * 0.55 + vnoise(uv * 2.3 + 4.0) * 0.3 + vnoise(uv * 5.1 + 9.0) * 0.15;
			float lim = 1.0 - cloud_amount * 0.62;
			float m = smoothstep(lim, lim + 0.04, n);
			// lit top edge vs shaded body: sample a bit lower in the dome
			float n2 = vnoise(uv + vec2(0.0, 0.18)) * 0.55 + vnoise((uv + vec2(0.0, 0.18)) * 2.3 + 4.0) * 0.3 + vnoise((uv + vec2(0.0, 0.18)) * 5.1 + 9.0) * 0.15;
			float lit = smoothstep(lim + 0.06, lim + 0.1, n2);
			vec3 cc = mix(cloud_shade.rgb, cloud_color.rgb, 1.0 - lit * 0.7);
			col = mix(col, cc, m * smoothstep(0.0, 0.12, h));
		}
	}
	float grey = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(grey) * vec3(0.92, 0.91, 0.98), clamp(pus_amount * 0.85, 0.0, 1.0));
	COLOR = col;
}
