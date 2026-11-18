// Runtime bake (18 Nov): the kit's prop wear shader (prop_wear_fix) for baked batches. Same look, plus:
//  - an exact distance window PER OBJECT inside a batch (near / mid tier): objects outside [range_begin, range_end)
//    collapse to a point in the vertex shader, so one batch can hold many props and still switch tiers per prop;
//  - the wear level rides with each prop (clean 0.2 / worn 0.55 / dirty 1.0), so wear no longer splits materials.
// RT_MERGED: props merged into one mesh. CUSTOM0 (half floats) = xyz the prop's origin (mesh space),
//   w = page * 16 + flags * 2 + wear (flags: 1 = normal map, 2 = ORM map, 4 = traffic signal).
// otherwise: a MultiMesh. Origin = the instance transform, INSTANCE_CUSTOM = (wear, page, flags, -).
// The kit's prop atlas pages are layers of one texture array (runtime_tex/arr_prop_*.png), so every prop of a batch
// shares this material whatever page it is on. Per prop: page, and whether its kit material had a normal / ORM map.
uniform sampler2DArray albedo_arr : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2DArray normal_arr : hint_normal, filter_linear_mipmap, repeat_disable;
uniform sampler2DArray orm_arr : filter_linear_mipmap, repeat_disable;
uniform sampler2D grime_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float range_begin = 0.0;
uniform float range_end = 60.0;
uniform float grime_meters : hint_range(0.15, 2.0) = 0.45;
uniform float bottom_bias : hint_range(0.0, 1.0) = 0.65;
uniform float cavity_bias : hint_range(0.0, 2.0) = 1.2;
uniform float instance_variation : hint_range(0.0, 1.0) = 1.0;
uniform float normal_depth : hint_range(0.0, 2.0) = 1.0;
uniform float signal_cycle = 30.0;
varying vec3 v_world_pos;
varying vec3 v_world_n;
varying float v_local_y;
varying vec3 v_origin;
varying float v_wear;
varying flat float v_page;
varying flat float v_flags;

void vertex() {
#ifdef RT_MERGED
	vec3 pivot = CUSTOM0.xyz;
	v_page = floor(CUSTOM0.w / 16.0); float rem = CUSTOM0.w - v_page * 16.0;      // w = page * 16 + flags * 2 + wear
	v_flags = floor(rem / 2.0); v_wear = rem - v_flags * 2.0;
#else
	vec3 pivot = vec3(0.0);
	v_wear = INSTANCE_CUSTOM.x; v_page = INSTANCE_CUSTOM.y; v_flags = INSTANCE_CUSTOM.z;
#endif
	v_origin = (MODEL_MATRIX * vec4(pivot, 1.0)).xyz;
	float d = distance(MAIN_CAM_INV_VIEW_MATRIX[3].xyz, v_origin);
	v_local_y = VERTEX.y - pivot.y;
	if (d < range_begin || d >= range_end) VERTEX = pivot;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

vec2 wear_uv(vec3 p, vec3 n) {
	vec3 a = abs(n);
	vec2 uv;
	if (a.y >= a.x && a.y >= a.z) { uv = p.xz; } else if (a.x >= a.z) { uv = p.zy; } else { uv = p.xy; }
	return uv / max(grime_meters, 0.05);
}

void fragment() {
	vec3 uvw = vec3(UV, floor(v_page + 0.5));
	float fl = floor(v_flags + 0.5);
	bool has_normal = mod(fl, 2.0) > 0.5; bool has_orm = mod(floor(fl / 2.0), 2.0) > 0.5; bool is_signal = fl > 3.5;
	vec4 alb = texture(albedo_arr, uvw);
	vec3 orm = vec3(1.0);     // (an unset ORM read white in the kit shader too)
	if (has_orm) orm = texture(orm_arr, uvw).rgb;
	float ao = orm.r; float rough = orm.g; float metal = orm.b;
	float v = hash13(v_origin);
	float wear_eff = clamp(v_wear * mix(1.0 - 0.25 * instance_variation, 1.0 + 0.2 * instance_variation, v), 0.0, 1.0);
	vec4 grime = texture(grime_tex, wear_uv(v_world_pos, v_world_n));
	float cavity = clamp((1.0 - ao) * cavity_bias, 0.0, 1.0);
	float bottom = (1.0 - smoothstep(0.02, 0.90, v_local_y)) * bottom_bias;
	float mask = clamp(0.18 + 0.82 * max(cavity, bottom * 0.85 + cavity * 0.35), 0.0, 1.0);
	mask *= mix(0.45, 1.0, grime.a);
	float spread = mix(1.35, 0.55, wear_eff);
	float amount = clamp(pow(mask, spread) * wear_eff * 1.15, 0.0, 1.0);
	vec3 dirt_col = grime.rgb;
	vec3 worn_alb = mix(alb.rgb, alb.rgb * dirt_col * 1.15, amount * 0.85);
	worn_alb = mix(worn_alb, dirt_col * 0.55, amount * 0.28 * wear_eff);
	float mc = max(max(COLOR.r, COLOR.g), max(COLOR.b, 0.04));
	vec3 tint = COLOR.rgb / mc * mix(1.0, mc, 0.5);
	ALBEDO = worn_alb * tint;
	ROUGHNESS = clamp(mix(rough, max(rough, 0.78), amount * 0.7), 0.04, 1.0);
	METALLIC = metal * (1.0 - amount * 0.85);
	AO = ao;
	AO_LIGHT_AFFECT = 1.0;
	vec3 nm = vec3(0.5, 0.5, 1.0);
	if (has_normal) nm = texture(normal_arr, uvw).rgb;
	NORMAL_MAP = nm; NORMAL_MAP_DEPTH = normal_depth;
	if (is_signal) {
		// Traffic signals cycle (18 Nov).
		// A head facing along X runs half a cycle after a head facing along Z; every junction (200 m lattice) has
		// its own start time. signal_cycle seconds: green 40 %, amber 10 %, red 50 %. (The traffic system can take
		// over later through ck_signal_time; until then it is the clock.)
		// The lenses are the fully saturated red / amber / green texels of the signal model (linear values measured
		// 18 Nov: red 0.4-0.6, amber 0.33, green about 0.15-0.26).
		// KNOWN FLAW: the green street-name board on the mast arm has the same green as the green lens, so it lights
		// with it. Colour cannot tell them apart (tried a brightness limit: it cuts the lens too). The fix is to mark
		// the lens faces: in the kit model, or in the bake (a first try tagged small saturated triangles by vertex
		// colour alpha, but missed the main lens faces; not finished).
		float mx = max(alb.r, max(alb.g, alb.b)); float mn = min(alb.r, min(alb.g, alb.b));
		if (mx - mn > 0.75 * mx && mx > 0.12) {
			float kind = alb.g > alb.r * 1.05 ? 2.0 : (alb.g > alb.r * 0.22 ? 1.0 : 0.0);      // 0 red, 1 amber, 2 green
			vec2 jn = floor((v_origin.xz + 100.0) / 200.0);
			float t = TIME + fract(sin(dot(jn, vec2(12.9898, 78.233))) * 43758.5453) * signal_cycle;
			if (abs(v_world_n.x) > abs(v_world_n.z)) t += signal_cycle * 0.5;
			float ph = fract(t / signal_cycle);
			float now = ph < 0.4 ? 2.0 : (ph < 0.5 ? 1.0 : 0.0);
			float on = 1.0 - step(0.5, abs(kind - now));
			ALBEDO *= mix(0.3, 1.0, on);
			vec3 lens = kind > 1.5 ? vec3(0.0, 1.0, 0.3) : (kind > 0.5 ? vec3(1.0, 0.55, 0.03) : vec3(1.0, 0.06, 0.04));
			EMISSION = lens * 1.6 * on;
		}
	}
}
