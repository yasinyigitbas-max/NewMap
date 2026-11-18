// Runtime bake (18 Nov): the FAR WORLD. One mesh per material per 500 m chunk holds the far versions of every
// building, tree and big prop of the island; it stays loaded always (the skyline needs no streamed piece).
// CUSTOM0 = xyz the object's origin (mesh space), w = how far it is drawn. An object shows from range_begin
// (where its mid tier ends) to that distance; nearer or farther it collapses to a point.
// UV2.x = flat + 2 * page: flat 1 = vertex colour only (far props), 0 = the far atlas (painted facades, tree cards).
// UV2.y = the 200 m cell the object lives in, as (x + 32) + (z + 32) * 64.
// NO HOLE: ck_cells_loaded (64 x 64, written by city_stream.gd) says which cells are in the scene. While an object's
// cell is NOT in, its far version shows at every distance; the near / mid versions take over only once they exist.
#ifdef RT_CUT
uniform sampler2DArray albedo_arr : source_color, filter_linear_mipmap, repeat_disable;     // the plant pages; UV2.y = page
#else
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;           // the kit's far atlas
#endif
uniform float range_begin = 220.0;
uniform float scissor = 0.5;
global uniform sampler2D ck_cells_loaded;
varying float v_flat;
varying flat float v_page;
void vertex() {
	vec3 pivot = (MODEL_MATRIX * vec4(CUSTOM0.xyz, 1.0)).xyz;
	float d = distance(MAIN_CAM_INV_VIEW_MATRIX[3].xyz, pivot);
	float code = floor(UV2.y + 0.5);
	float cell_in = texelFetch(ck_cells_loaded, ivec2(int(mod(code, 64.0)), int(floor(code / 64.0))), 0).r;
	if ((d < range_begin && cell_in > 0.5) || d >= CUSTOM0.w) VERTEX = CUSTOM0.xyz;
	v_page = floor(UV2.x / 2.0 + 0.01); v_flat = UV2.x - v_page * 2.0;
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
#endif
}
