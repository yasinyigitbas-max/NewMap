// Runtime bake (18 Nov): trees, palms, shrubs, hedges and the kit's other cut-out props (chain-link panels).
// Replaces the kit's StandardMaterial (same textures, roughness, two-sided, alpha cut) and adds:
//  - wind: the crown sways and the leaves flutter, the trunk's foot stays put (vertex shader only, no extra draw);
//  - the per-object distance window (see rt_prop.gdshaderinc);
//  - alpha that keeps its coverage when mipmaps average the leaves away (distant crowns stay full).
// World-space vertices. RT_MERGED: CUSTOM0.xyz = the plant's foot (mesh space). RT_CUT: alpha cut-out.
// The plant atlases (and the two prop pages with cut-out panels) are layers of runtime_tex/arr_fol_*.png: one material
// for every plant of a batch. Per plant: page, wind amount (0 = stiff: fences), normal map or not.
//   RT_MERGED: CUSTOM0 (half floats) = xyz the foot, w = page * 16 + (wind + 2 * normal map) * 2;   MultiMesh: INSTANCE_CUSTOM = (page, wind, normal map, -)
#include "res://map_dc/coronado/city_kit/shaders/rt/rt_tier.gdshaderinc"
uniform sampler2DArray albedo_arr : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2DArray normal_arr : hint_normal, filter_linear_mipmap, repeat_disable;
varying flat float v_page;
varying flat float v_hasn;
#ifdef CK_TIERS
varying vec2 v_tw;
#endif
uniform float roughness = 0.85;
uniform float scissor = 0.5;
uniform float range_begin = 0.0;
uniform float range_end = 60.0;
uniform float sway_height = 8.0;      // a crown this high above the foot sways the full amount
global uniform float ck_wind_strength;
global uniform vec2 ck_wind_dir;

void vertex() {
#ifdef RT_MERGED
	vec3 pivot = (MODEL_MATRIX * vec4(CUSTOM0.xyz, 1.0)).xyz;
	v_page = floor(CUSTOM0.w / 16.0); float fl2 = floor((CUSTOM0.w - v_page * 16.0) / 2.0 + 0.5);      // w = page * 16 + (wind + 2 * normal map) * 2
	float wind_amount = mod(fl2, 2.0); v_hasn = step(1.5, fl2);
#else
	vec3 pivot = MODEL_MATRIX[3].xyz;
	v_page = INSTANCE_CUSTOM.x; float wind_amount = INSTANCE_CUSTOM.y; v_hasn = INSTANCE_CUSTOM.z;
#endif
	float d = distance(MAIN_CAM_INV_VIEW_MATRIX[3].xyz, pivot);
#ifdef CK_TIERS
	float ck_s = CK_FAR_M * ck_cell_ramp(pivot);      // see rt_tier.gdshaderinc
	v_tw = ck_weights(d, min(range_begin, ck_s), min(range_end, ck_s));
	if (v_tw.x <= 0.0 || v_tw.y <= 0.0) {
#else
	if (d < range_begin || d >= range_end) {
#endif
		VERTEX = pivot;
	} else if (wind_amount > 0.0) {
		float ws = ck_wind_strength * wind_amount;
		float h = max(VERTEX.y - pivot.y, 0.0);
		float hn = min(h / sway_height, 1.5);
		float ph = dot(pivot.xz, vec2(0.37, 0.53));
		float gust = 0.6 + 0.4 * sin(TIME * 0.35 + ph * 0.21);
		float bend = (sin(TIME * 1.1 + ph) * 0.6 + sin(TIME * 2.3 + ph * 1.7) * 0.25 + 0.35) * gust;
		float r = length(VERTEX.xz - pivot.xz);
		float fl = sin(TIME * 4.7 + VERTEX.x * 1.3 + VERTEX.z * 1.7 + VERTEX.y * 0.9) * 0.025 * smoothstep(0.3, 2.0, r) * smoothstep(0.5, 2.5, h);
		VERTEX.xz += ck_wind_dir * (bend * hn * hn * 0.12 + fl) * ws;
		VERTEX.y += fl * 0.6 * ws;
	}
}

void fragment() {
#ifdef CK_TIERS
	CK_DITHER
#endif
	vec3 uvw = vec3(UV, floor(v_page + 0.5));
	vec4 t = texture(albedo_arr, uvw);
	ALBEDO = t.rgb;
	ROUGHNESS = roughness;
#ifndef CK_CHEAP
	vec3 nm = vec3(0.5, 0.5, 1.0);
	if (v_hasn > 0.5) nm = texture(normal_arr, uvw).rgb;
	NORMAL_MAP = nm;
#endif
// CK_CHEAP: no normal map; CK_OPAQUE: the cut-out drawn solid (both only for the drawing census, never baked in)
#ifndef CK_OPAQUE
#ifdef RT_CUT
	vec2 ts = vec2(textureSize(albedo_arr, 0).xy);
	vec2 dx = dFdx(UV * ts); vec2 dy = dFdy(UV * ts);
	float lod = max(0.0, 0.5 * log2(max(dot(dx, dx), dot(dy, dy))));
	ALPHA = clamp(t.a * (1.0 + lod * 0.3), 0.0, 1.0);
	ALPHA_SCISSOR_THRESHOLD = scissor;
#endif
#endif
}
