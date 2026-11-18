// Far ground (19 Nov): the ground of every cell of the island - streets, pavements, grass, plazas - as one mesh in the
// far world, so streets are there before their cell loads (until now a cell's ground came from nothing over a plane).
// Per cell a 200 m patch on a 20 m grid that follows the ground's heights, drawn with ONE top-down picture of the
// whole island's real ground (bake_runtime.gd _build_far_ground renders it: 1.25 m a texel, VRAM-compressed, mipmaps).
// A patch collapses (no pixel) in the frame its cell is in: the cell's own ground then lies where it was.
// Per pixel: one texture read, lit like the ground (no normal map, no extras). UV = place in the picture,
// UV2.y = the cell, as in rt_far.
shader_type spatial;
render_mode cull_back;
uniform sampler2D ground_top : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform float roughness = 0.9;
global uniform sampler2D ck_cells_loaded;
void vertex() {
	float code = floor(UV2.y + 0.5);
	float cell_in = texelFetch(ck_cells_loaded, ivec2(int(mod(code, 64.0)), int(floor(code / 64.0))), 0).r;
	if (cell_in > 0.0) VERTEX = vec3(0.0);
}
void fragment() {
	ALBEDO = texture(ground_top, UV).rgb;
	ROUGHNESS = roughness;
}
