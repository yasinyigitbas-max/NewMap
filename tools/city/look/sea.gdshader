// LOOK QUEUE 2, JOB 3: the sea (tools/city/look/sea.gd). Unshaded: the light is worked out here from the look's
// sun and ambient (set by look.gd), so the engine's light loop and sky reflection do not run on water pixels.
//  - colour by depth: the depth rides in the vertex (COLOR.r x 20 m), shallow water near the shore lighter and greener;
//  - small moving ripples: two reads of the look's noise texture, moving against each other (TIME: a spatial shader
//    may use it; only a sky shader with TIME costs a redraw of the reflection map);
//  - the look's sky map (ck_sky_map, 128 x 64) as the reflection, weighted by Fresnel, and a glint of the sun;
//  - no depth-buffer read, no screen-space reflection, no extra pass. The engine's fog still applies (the haze).
// Per water pixel: 3 texture reads (2 ripples + the sky map) and about 40 arithmetic steps.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;
#include "res://tools/city/look/sky_reflect.gdshaderinc"
uniform sampler2D ripple_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 shallow : source_color = vec3(0.30, 0.42, 0.36);      // GTA 4-ish: grey-green, not tropical
uniform vec3 deep_col : source_color = vec3(0.05, 0.11, 0.13);
uniform vec3 light = vec3(0.9);          // what lights the water's body: ambient + sun (look.gd)
uniform vec3 sun_dir = vec3(0.0, 0.7, 0.7);
uniform vec3 sun_light = vec3(1.0);      // sun colour x energy (look.gd)
uniform float ripple = 0.35;             // how much the ripples tilt the surface
uniform float glint = 3.0;
varying float v_depth;
varying vec3 v_world;
void vertex() {
	v_depth = COLOR.r * 20.0;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = v_world.xz;
	vec2 n1 = texture(ripple_tex, p * 0.029 + TIME * vec2(0.010, 0.006)).rg - 0.5;
	vec2 n2 = texture(ripple_tex, p * 0.091 - TIME * vec2(0.016, 0.012)).gr - 0.5;
	vec3 eye = INV_VIEW_MATRIX[3].xyz;
	float dist = distance(eye, v_world);
	float calm = 1.0 / (1.0 + dist * 0.004);      // far water looks calmer (the ripples average out)
	vec3 n = normalize(vec3((n1.x + n2.x * 0.7) * ripple * calm, 1.0, (n1.y + n2.y * 0.7) * ripple * calm));
	vec3 v = normalize(eye - v_world);
	vec3 r = reflect(-v, n);
	r.y = max(r.y, 0.01);
	float c = 1.0 - max(dot(n, v), 0.0);
	float fres = 0.02 + 0.98 * c * c * c * c * c;
	vec3 sky = ck_sky_map_read(r);
	float dk = 1.0 - exp(-v_depth * 0.22);
	vec3 body = mix(shallow, deep_col, dk) * light;
	float g = max(dot(r, normalize(sun_dir)), 0.0);
	float g2 = g * g; g2 *= g2; g2 *= g2; g2 *= g2; g2 *= g2; g2 *= g2;      // ^64
	vec3 col = mix(body, sky, clamp(fres, 0.0, 1.0)) + sun_light * (g2 * g2) * glint * step(0.0, sun_dir.y);
	ALBEDO = col;
}
