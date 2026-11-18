// "iron" variant (17 Nov, Yasin: balconies black, not white on red brick): same as prop_wear_fix, then every
// bright, unsaturated texel (white-painted rails, slab edges) becomes weathered black iron; coloured texels (chairs,
// plants, cushions) keep their colour. Used for kit props that only ship a white "clean" model.
// --- base: city1 copy of assets/coronado_kit/shaders/prop_wear.gdshader with one fix: INSTANCE_CUSTOM is only readable in
// vertex() in Godot 4.7, so it is passed to fragment() through a varying (the original fails to compile: props render
// white). Second change: vertex colours are applied as hue + half their darkness (they carry both the colour variant
// and baked shading; multiplied raw they turned bandstand rails near black, dropped they turned red containers white).
// Coronado props: procedural wear / dirt over the clean colour atlas.
// Godot 4.7, Vulkan Mobile renderer. 0 = clean, 0.5 = worn, 1 = dirty.
//
// Assign this Spatial shader to a prop material. Hook the shared atlas
// pages to albedo_tex / normal_tex / orm_tex, and atlases/props_grime.png
// to grime_tex. See shaders/README.md.
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_disable;
uniform sampler2D orm_tex : filter_linear_mipmap, repeat_disable; // R = AO, G = roughness, B = metallic
uniform sampler2D grime_tex : source_color, filter_linear_mipmap, repeat_enable;

uniform float wear : hint_range(0.0, 1.0) = 0.0;
uniform float grime_meters : hint_range(0.15, 2.0) = 0.45;
uniform float bottom_bias : hint_range(0.0, 1.0) = 0.65;
uniform float cavity_bias : hint_range(0.0, 2.0) = 1.2;
uniform float instance_variation : hint_range(0.0, 1.0) = 1.0;
uniform float normal_depth : hint_range(0.0, 2.0) = 1.0;

varying vec3 v_world_pos;
varying vec3 v_world_n;
varying float v_local_y;
varying vec3 v_origin;
varying vec4 v_custom;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_local_y = VERTEX.y;
	v_origin = MODEL_MATRIX[3].xyz;   // includes the MultiMesh instance transform: each instance varies
	v_custom = INSTANCE_CUSTOM;
}

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

// Single-axis world projection (cheaper than full triplanar; fine for messy grime).
vec2 wear_uv(vec3 p, vec3 n) {
	vec3 a = abs(n);
	vec2 uv;
	if (a.y >= a.x && a.y >= a.z) {
		uv = p.xz;
	} else if (a.x >= a.z) {
		uv = p.zy;
	} else {
		uv = p.xy;
	}
	return uv / max(grime_meters, 0.05);
}

void fragment() {
	vec4 alb = texture(albedo_tex, UV);
	vec3 orm = texture(orm_tex, UV).rgb;
	float ao = orm.r;
	float rough = orm.g;
	float metal = orm.b;

	float v;
	if (v_custom.a > 0.5) {
		v = clamp(v_custom.x, 0.0, 1.0);
	} else {
		v = hash13(v_origin);
	}
	float wear_eff = clamp(wear * mix(1.0 - 0.25 * instance_variation, 1.0 + 0.2 * instance_variation, v), 0.0, 1.0);

	vec4 grime = texture(grime_tex, wear_uv(v_world_pos, v_world_n));
	float cavity = clamp((1.0 - ao) * cavity_bias, 0.0, 1.0);
	// Dirt gathers at the foot of the object. 0.9 m fade works for hydrants
	// and fences; short props simply read as a bit dirtier overall, which is fine.
	float bottom = (1.0 - smoothstep(0.02, 0.90, v_local_y)) * bottom_bias;
	float mask = clamp(0.18 + 0.82 * max(cavity, bottom * 0.85 + cavity * 0.35), 0.0, 1.0);
	mask *= mix(0.45, 1.0, grime.a);

	// worn (0.5) stays mostly in cavities and at the base; dirty (1.0) spreads.
	float spread = mix(1.35, 0.55, wear_eff);
	float amount = clamp(pow(mask, spread) * wear_eff * 1.15, 0.0, 1.0);

	vec3 dirt_col = grime.rgb;
	// Keep some of the original colour so paint still reads under the film.
	vec3 worn_alb = mix(alb.rgb, alb.rgb * dirt_col * 1.15, amount * 0.85);
	worn_alb = mix(worn_alb, dirt_col * 0.55, amount * 0.28 * wear_eff);

	// vertex colour = the kit's colour variant (red / blue containers, bins) AND baked shading (near black in a
	// bandstand's cavities). Keep the hue fully, keep half of the darkness: variants stay coloured, nothing goes black.
	float mc = max(max(COLOR.r, COLOR.g), max(COLOR.b, 0.04));
	vec3 tint = COLOR.rgb / mc * mix(1.0, mc, 0.5);
	vec3 base_col = worn_alb * tint;
	float lum = dot(alb.rgb, vec3(0.299, 0.587, 0.114));
	float sat = max(max(alb.r, alb.g), alb.b) - min(min(alb.r, alb.g), alb.b);
	float iron_mask = smoothstep(0.45, 0.65, lum) * (1.0 - smoothstep(0.08, 0.18, sat));
	vec3 iron_col = mix(vec3(0.055, 0.055, 0.06), vec3(0.11, 0.09, 0.075), grime.r * amount);   // a little rust in the dirt
	ALBEDO = mix(base_col, iron_col, iron_mask);
	ROUGHNESS = clamp(mix(rough, max(rough, 0.78), amount * 0.7), 0.04, 1.0);
	METALLIC = mix(metal * (1.0 - amount * 0.85), 0.45, iron_mask);
	AO = ao;
	AO_LIGHT_AFFECT = 1.0;
	NORMAL_MAP = texture(normal_tex, UV).rgb;
	NORMAL_MAP_DEPTH = normal_depth;
}
