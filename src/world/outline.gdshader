shader_type spatial;
// Inverted-hull outline: the mesh is pushed out along its normals and only
// its back faces are drawn, leaving a dark contour around the silhouette.
render_mode unshaded, cull_front, shadows_disabled;

uniform vec4 outline_color : source_color = vec4(0.165, 0.129, 0.251, 1.0);
uniform float thickness = 0.035;

void vertex() {
	VERTEX += NORMAL * thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
