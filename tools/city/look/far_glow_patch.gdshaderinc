// Look job 5 (18 Nov), the PROPOSED far shader with night windows - the change docs/look_patches/far_windows.md asks
// for in city_kit/shaders/rt/rt_far.gdshaderinc (this session may not edit rt_far*). look_shots_bld.gd --farglow uses
// this file in memory for its pictures. Differences from rt_far.gdshaderinc are marked "NIGHT".
#ifdef RT_CUT
uniform sampler2DArray albedo_arr : source_color, filter_linear_mipmap, repeat_disable;
#else
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;     // NIGHT: far_color_glow.png, alpha = window mask
#endif
uniform float range_begin = 220.0;
uniform float scissor = 0.5;
uniform float far_glow = 1.3;        // NIGHT: as rt_bldg's emission_energy * night_energy
global uniform sampler2D ck_cells_loaded;
global uniform float ck_night;        // NIGHT
global uniform float ck_look_windows; // NIGHT: the near windows' switch drives the far ones too
varying float v_flat;
varying flat float v_page;
varying vec3 v_wp;                    // NIGHT
varying vec3 v_wn;                    // NIGHT
void vertex() {
	vec3 pivot = (MODEL_MATRIX * vec4(CUSTOM0.xyz, 1.0)).xyz;
	float d = distance(MAIN_CAM_INV_VIEW_MATRIX[3].xyz, pivot);
	float code = floor(UV2.y + 0.5);
	float cell_in = texelFetch(ck_cells_loaded, ivec2(int(mod(code, 64.0)), int(floor(code / 64.0))), 0).r;
	if ((d < range_begin && cell_in > 0.5) || d >= CUSTOM0.w) VERTEX = CUSTOM0.xyz;
	v_page = floor(UV2.x / 2.0 + 0.01); v_flat = UV2.x - v_page * 2.0;
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;                       // NIGHT
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);            // NIGHT
}
void fragment() {
#ifdef RT_CUT
	vec4 t = texture(albedo_arr, vec3(UV, floor(v_page + 0.5)));
#else
	vec4 t = texture(albedo_tex, UV);
#endif
	ALBEDO = mix(t.rgb, vec3(1.0), v_flat) * COLOR.rgb;
	ROUGHNESS = 0.9;
	SPECULAR = 0.3;
#ifdef RT_CUT
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = scissor;
#else
	// NIGHT: the painted windows (mask in the atlas alpha: no extra read) light up like the near ones - a third dark, the
	// rest on one by one at dusk, mostly warm bulbs, some neutral, a few cold - per 3 m bay of each wall
	if (ck_night > 0.001 && v_flat < 0.5 && t.a > 0.02) {
		float along = v_wp.x * v_wn.z - v_wp.z * v_wn.x;
		vec2 c = floor(vec2(along, v_wp.y) / 3.0) + floor(dot(v_wn.xz, vec2(17.0, 43.0)) + 0.5);
		vec2 hw = fract(sin(vec2(dot(c, vec2(12.9898, 78.233)), dot(c, vec2(39.3468, 11.135)))) * 43758.5453);
		float on = step(0.34, hw.x) * smoothstep(hw.x * 0.6, hw.x * 0.6 + 0.25, ck_night);
		vec3 lamp = mix(vec3(1.0, 0.56, 0.24), vec3(1.0, 0.7, 0.42), smoothstep(0.0, 0.55, hw.y));
		lamp = mix(lamp, vec3(1.0, 0.8, 0.58), step(0.72, hw.y));
		lamp = mix(lamp, vec3(0.3, 0.38, 0.52), step(0.92, hw.y));
		if (ck_look_windows < 0.5) lamp = vec3(1.0, 0.78, 0.5) * 0.7;
		EMISSION = t.a * lamp * (far_glow * on * mix(0.35, 0.85, fract(hw.y * 7.31)));
	}
#endif
}
