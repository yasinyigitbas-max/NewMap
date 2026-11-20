// Runtime bake (18 Nov): the FAR WORLD. One mesh per material per 500 m chunk holds the far versions of every
// building, tree and big prop of the island; it stays loaded always (the skyline needs no streamed piece).
// CUSTOM0 = xyz the object's origin (mesh space), w = how far it is drawn. An object shows from range_begin
// (where its mid tier ends) to that distance; nearer or farther it collapses to a point.
// UV2.x = flat + 2 * page: flat 1 = vertex colour only (far props), 0 = the far atlas (painted facades, tree cards).
// UV2.y = the 200 m cell the object lives in, as (x + 32) + (z + 32) * 64.
// NO HOLE: ck_cells_loaded (64 x 64, written by city_stream.gd) says which cells are in the scene. While an object's
// cell is NOT in, its far version shows at every distance; the near / mid versions take over only once they exist.
// CK_TIERS (rt_tier.gdshaderinc): the take-over sweeps out from the camera while a cell arrives, and fades.
#ifdef RT_CUT
uniform sampler2DArray albedo_arr : source_color, filter_linear_mipmap, repeat_disable;     // the plant pages; UV2.y = page
#else
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;           // the kit's far atlas
#endif
uniform float range_begin = 220.0;
#ifndef RT_CUT
global uniform float ck_night;
global uniform vec4 ck_look_sky_horizon : source_color;
#define ck_far_sky ck_look_sky_horizon
uniform float far_glass = 0.0;     // (0.2 on the bld_lod page) straight-on sky reflection of the far glass (rt_bldg glass_reflect 0.15 .. grazing)
uniform float far_wear = 1.0;      // (0.92 on the bld_lod page) the near / mid's grime (wear 0.65) on average, which the far does not compute
#endif
uniform float scissor = 0.5;
#include "res://map_dc/coronado/city_kit/shaders/rt/rt_tier.gdshaderinc"
varying float v_flat;
varying flat float v_page;
#ifdef CK_TIERS
varying vec2 v_tw;
#endif
void vertex() {
	vec3 pivot = (MODEL_MATRIX * vec4(CUSTOM0.xyz, 1.0)).xyz;
	float d = distance(MAIN_CAM_INV_VIEW_MATRIX[3].xyz, pivot);
	float code = floor(UV2.y + 0.5);
	float cell_in = texelFetch(ck_cells_loaded, ivec2(int(mod(code, 64.0)), int(floor(code / 64.0))), 0).r;
#ifdef CK_TIERS
	// the outer partner of the mid tier: from S (220 m once the cell is in, sweeping out while it arrives) on, with
	// the band; while the cell is not in, S = 0 and the far version shows at every distance (rt_tier.gdshaderinc)
	v_tw = ck_weights(d, min(range_begin, CK_FAR_M * cell_in), CUSTOM0.w);
	v_tw.y = d >= CUSTOM0.w ? 0.0 : 1.0;      // the far end stays a hard cut (1-1.5 km, under a pixel)
	if (v_tw.x <= 0.0 || v_tw.y <= 0.0) VERTEX = CUSTOM0.xyz;
#else
	if ((d < range_begin && cell_in > 0.5) || d >= CUSTOM0.w) VERTEX = CUSTOM0.xyz;
#endif
	v_page = floor(UV2.x / 2.0 + 0.01); v_flat = UV2.x - v_page * 2.0;
}
void fragment() {
#ifdef CK_TIERS
	CK_DITHER
#endif
#ifdef RT_CUT
	vec4 t = texture(albedo_arr, vec3(UV, floor(v_page + 0.5)));
#else
	vec4 t = texture(albedo_tex, UV);
#endif
#ifdef RT_CUT
	ALBEDO = mix(t.rgb, vec3(1.0), v_flat) * COLOR.rgb;
#else
	// a far prop (v_flat 1): its flat vertex colour. A far building (LOD match, 20 Nov): the near baked into
	// bld_lod_color.png; COLOR = the building's tint, applied like rt_bldg does (walls, not glass or dark / saturated
	// texels), and its glass (alpha = 1 - glass) a little lighter, as the near's glass reflects the sky straight on
	float lum = dot(t.rgb, vec3(0.299, 0.587, 0.114));
	float sat = max(t.r, max(t.g, t.b)) - min(t.r, min(t.g, t.b));
	float paint = smoothstep(0.28, 0.55, lum) * (1.0 - smoothstep(0.18, 0.4, sat));
	vec3 bld = mix(t.rgb, ck_far_sky.rgb, (1.0 - t.a) * far_glass * (1.0 - 0.94 * ck_night)) * mix(vec3(1.0), COLOR.rgb, paint) * far_wear;
	ALBEDO = mix(bld, COLOR.rgb, v_flat);
#endif
	ROUGHNESS = 0.9;
	SPECULAR = 0.3;
#ifdef RT_CUT
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = scissor;
#endif
}
