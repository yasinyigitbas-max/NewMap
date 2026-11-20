// THE SKYLINE RING (20 Nov; tools/city/look/skyline.gd, textures by tools/city/look/make_skyline.py). San Diego round
// the horizon, drawn like the sky: never clipped by the camera's far plane, never culled, behind every object.
//  - the vertex shader puts the rings at the FAR END OF THE DEPTH RANGE (reverse-Z: ndc z = 1e-9; the far plane and
//    the sky are 0), so every surface the camera draws wins the depth test and the cards still cover the sky. No
//    z-fighting: the sea at its last metre before the far plane still writes far more than 1e-9 (0.08 m near / 900 m far:
//    about 1e-7 at 899 m, 9e-5 at 450 m).
//  - FAR layer (UV2.x = 0): direction only (VERTEX is a unit direction), the camera's position is ignored;
//  - NEAR layer (UV2.x = 1): VERTEX is a point on a ring 2-6.4 km out (real distances, skyline.json), seen from the
//    camera (its offset from the ring's centre held under max_off, and blended back toward the centre's view where the
//    camera comes within 600 m of the ring), so downtown and Point Loma shift as you cross the island like the real ones;
//  - SOLIDS (UV2.x = 2): the bridge and Coronado Shores, boxes at their true places seen from the real camera, colour
//    in COLOR (sRGB, alpha = night light). Inside the camera's far plane they write their TRUE depth (so the sea, the
//    land and the city sort with them as with any object); beyond it, 5e-9..1e-7 by distance (in front of the rings,
//    which write 1e-9, and still behind anything of the city);
//  - unshaded, no fog of the engine (fog_disabled): the haze is painted in and tinted to the look's haze here.
// Per card pixel: 2 texture reads (colour + night lights) and a handful of steps. No light loop, no shadow.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_always, cull_disabled, fog_disabled, shadows_disabled, world_vertex_coords;
global uniform float ck_night;
uniform sampler2D day_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D lights_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 tint = vec3(1.0);               // the look's haze now / the haze it was painted with (look.gd sets it)
uniform vec3 haze_col : source_color = vec3(0.80, 0.78, 0.71);
uniform float haze_more = 0.0;               // a thicker look's extra haze (look.gd: from its fog density)
uniform float lights = -1.0;                 // night lights 0..1 (look.gd); below 0 = follow the streamer's ck_night
uniform vec3 light_col = vec3(1.0, 0.74, 0.46);
uniform vec2 centre = vec2(0.0, -600.0);      // the ring's centre in the city frame (skyline.json centre_grid)
uniform float max_off = 1600.0;              // the near layer's parallax follows the camera this far from the centre
varying float v_near;
varying float v_kind;
varying float v_dist;

void vertex() {
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 d = VERTEX;
	float kind = UV2.x;
	float zz = 1.0e-9;
	if (kind > 1.5) {
		d = VERTEX - cam;
		vec4 ct = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(VERTEX, 1.0));      // its true depth inside the far plane ...
		zz = max(ct.z / ct.w, 1.0e-7 * clamp(900.0 / max(length(d), 1.0), 0.05, 1.0));      // ... beyond it, just in front of the rings
	} else if (kind > 0.5) {
		vec2 off = cam.xz - centre;
		float l = length(off);
		if (l > max_off) off *= max_off / l;
		vec2 eye = centre + off;
		eye = mix(centre, eye, smoothstep(250.0, 600.0, length(VERTEX.xz - eye)));      // never inside the ring
		d = VERTEX - vec3(eye.x, cam.y, eye.y);
	}
	vec4 clip = PROJECTION_MATRIX * vec4((VIEW_MATRIX * vec4(d, 0.0)).xyz, 1.0);
	clip.z = clip.w * zz;
	POSITION = clip;
	v_near = step(0.5, kind);
	v_kind = kind;
	v_dist = length(d);
}

void fragment() {
	float night = lights < 0.0 ? ck_night : lights;
	vec3 tn = lights < 0.0 ? mix(vec3(1.0), vec3(0.26, 0.17, 0.11), ck_night) : tint;      // no look: darken by the city's own night
	vec3 hz = haze_col * (lights < 0.0 ? tn : vec3(1.0));
	vec4 t;
	float lit;
	if (v_kind > 1.5) {      // a solid: its colour, the painted haze by its true distance (as make_skyline.py paints)
		vec3 base = pow(COLOR.rgb, vec3(2.2));
		float h = 1.0 - exp(-v_dist / 25000.0);
		t = vec4(mix(base, vec3(0.604, 0.571, 0.462), h), 1.0);      // (the day haze 0.80, 0.78, 0.71 in linear)
		lit = COLOR.a * 0.5;
	} else {
		t = texture(day_tex, UV);
		lit = texture(lights_tex, UV).r;
	}
	vec3 c = t.rgb * tn;
	c = mix(c, hz, haze_more * mix(1.0, 0.6, v_near));
	c += light_col * lit * night * 1.4;
	ALBEDO = c;
	ALPHA = t.a;
}
