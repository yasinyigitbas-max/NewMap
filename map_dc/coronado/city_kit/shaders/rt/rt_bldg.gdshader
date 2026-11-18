// Runtime bake (18 Nov): the city kit's weathered building material (bldg_wear) with two additions:
//  - tint and extra wear PER BUILDING (instance uniforms, no extra material, no extra draw): copies of one model
//    read as different buildings. Default 1 / 0 = exactly the bldg_wear look.
//  - the night window glow follows the global ck_night (0 day .. 1 night); the kit's emissive mask was already bound.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_disable;
uniform sampler2D orm_tex : filter_linear_mipmap, repeat_disable;
uniform sampler2D emission_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D grime_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool has_normal = true;
uniform bool has_orm = true;
uniform bool has_emission = false;
uniform float emission_energy = 1.0;
uniform float wear : hint_range(0.0, 1.0) = 0.45;
uniform float foot_m = 1.4;
uniform float grime_meters = 2.2;
uniform float streaks = 0.55;
uniform vec3 night_color : source_color = vec3(1.0, 0.78, 0.5);
uniform float night_energy = 1.3;
instance uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);
instance uniform float wear_add = 0.0;
instance uniform float lit_seed = 0.0;       // which windows are lit differs per building
global uniform float ck_night;
varying vec3 v_wp;
varying vec3 v_wn;
varying float v_y;
void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_y = VERTEX.y;
}
void fragment() {
	vec4 alb = texture(albedo_tex, UV);
	vec3 orm = has_orm ? texture(orm_tex, UV).rgb : vec3(1.0, 0.8, 0.0);
	vec3 a = abs(v_wn);
	vec2 guv = (a.y >= a.x && a.y >= a.z) ? v_wp.xz : (a.x >= a.z ? v_wp.zy : v_wp.xy);
	vec4 grime = texture(grime_tex, guv / grime_meters);
	float cavity = clamp((1.0 - orm.r) * 1.3, 0.0, 1.0);
	float foot = 1.0 - smoothstep(0.0, foot_m, v_y);
	float film = grime.a * 0.35;
	float wall = 1.0 - smoothstep(0.5, 0.8, a.y);
	vec2 suv = (a.x >= a.z ? vec2(v_wp.z, v_wp.y) : vec2(v_wp.x, v_wp.y)) * vec2(1.0 / 1.6, 1.0 / 19.0);
	float streak = smoothstep(0.35, 0.85, texture(grime_tex, suv).a) * wall * streaks;
	float amount = clamp((cavity * 0.75 + foot * 0.85 + film + streak * 0.6) * clamp(wear + wear_add, 0.0, 1.0), 0.0, 0.9);
	// the tint paints the walls, not the glass or the dark trims: it fades out on dark and on saturated texels
	float lum = dot(alb.rgb, vec3(0.299, 0.587, 0.114));
	float sat = max(alb.r, max(alb.g, alb.b)) - min(alb.r, min(alb.g, alb.b));
	float paint = smoothstep(0.28, 0.55, lum) * (1.0 - smoothstep(0.18, 0.4, sat)) * wall;
	vec3 base = alb.rgb * COLOR.rgb * mix(vec3(1.0), tint, paint);
	vec3 col = mix(base, base * grime.rgb * 1.1, amount * 0.8);
	ALBEDO = col;
	ROUGHNESS = clamp(mix(orm.g, max(orm.g, 0.85), amount), 0.05, 1.0);
	METALLIC = orm.b * (1.0 - amount);
	AO = orm.r;
	if (has_normal) NORMAL_MAP = texture(normal_tex, UV).rgb;
	if (has_emission && ck_night > 0.001) {
		// windows come on one by one at dusk: each 3 m x 3 m bay of each wall has its own switch-on time, about a
		// third stay dark all night
		vec2 bay = floor(vec2(a.x >= a.z ? v_wp.z : v_wp.x, v_wp.y) / 3.0);
		float hsh = fract(sin(dot(bay + lit_seed, vec2(12.9898, 78.233))) * 43758.5453);
		float on = step(0.34, hsh) * smoothstep(hsh * 0.6, hsh * 0.6 + 0.25, ck_night) * mix(0.35, 1.0, fract(hsh * 7.31));      // and not all equally bright
		EMISSION = texture(emission_tex, UV).rgb * night_color * emission_energy * night_energy * on;
	}
}
