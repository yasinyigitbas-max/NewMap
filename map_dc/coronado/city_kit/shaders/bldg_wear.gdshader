// city1 (Yasin 16 Nov: "the entire block looks brand new"): kit building material + weathering.
// Same inputs as the kit's StandardMaterial (atlas albedo x vertex tint, normal, ORM, night-window emission) plus
// dirt that real buildings collect: a band at the foot of the walls (splash, soil, pavement grime), grime in the
// recesses (AO cavities: under sills, eaves, in door and window reveals) and a world-space grime film so no two walls
// read the same. Based on assets/coronado_kit/shaders/prop_wear.gdshader. One extra texture read per pixel.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_disable;      // (anisotropic, 28 Nov night: as albedo_tex; relief does not shimmer at grazing angles)
uniform sampler2D orm_tex : filter_linear_mipmap, repeat_disable;
uniform sampler2D emission_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D grime_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool has_normal = true;
uniform bool has_orm = true;
uniform bool has_emission = false;
uniform float emission_energy = 1.0;
uniform float wear : hint_range(0.0, 1.0) = 0.45;
uniform float foot_m = 1.4;          // height of the dirty band at the foot of the walls
uniform float grime_meters = 2.2;    // world size of the grime film pattern
uniform float streaks = 0.55;        // rain streaks: dirt washed down the walls from sills, edges and parapets
uniform float night_k = 0.0;          // 0 day .. 1 night: set by the game's day cycle when the pieces go in (not wired yet)
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
	// streaks: the grime texture stretched 12x down the wall (walls only, not roofs), fading toward the foot
	float wall = 1.0 - smoothstep(0.5, 0.8, a.y);
	vec2 suv = (a.x >= a.z ? vec2(v_wp.z, v_wp.y) : vec2(v_wp.x, v_wp.y)) * vec2(1.0 / 1.6, 1.0 / 19.0);
	float streak = smoothstep(0.35, 0.85, texture(grime_tex, suv).a) * wall * streaks;
	float amount = clamp((cavity * 0.75 + foot * 0.85 + film + streak * 0.6) * wear, 0.0, 0.9);
	// built-in interiors (22 Nov): faces with vertex alpha < 0.5 are indoors - no street grime, rain streaks or foot dirt
	amount *= step(0.5, COLOR.a);
	vec3 base = alb.rgb * COLOR.rgb;
	vec3 col = mix(base, base * grime.rgb * 1.1, amount * 0.8);
	ALBEDO = col;
	ROUGHNESS = clamp(mix(orm.g, max(orm.g, 0.85), amount), 0.05, 1.0);
	METALLIC = orm.b * (1.0 - amount);
	AO = orm.r;
	if (has_normal) NORMAL_MAP = texture(normal_tex, UV).rgb;
	if (has_emission) EMISSION = texture(emission_tex, UV).rgb * emission_energy * night_k;
}
