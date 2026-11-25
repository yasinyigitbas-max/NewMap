// city1: ground wear marks (cracks, sealed cracks, patches, oil, tyre marks, grime, scuffs, kerb paint) from the
// main branch's photo atlas map_dc/coronado/streets/street_wear/wear_atlas.png. One merged mesh per piece, laid on the
// surface (1 cm lift), alpha blended, no depth write, faded out by distance so far marks never shimmer.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_disabled;
uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform float fade_from = 60.0;
uniform float fade_to = 90.0;
void fragment() {
	vec4 t = texture(atlas, UV);
	float d = length(VERTEX);
	ALBEDO = t.rgb * COLOR.rgb;
	ROUGHNESS = 0.9;
	ALPHA = t.a * COLOR.a * (1.0 - smoothstep(fade_from, fade_to, d));
}
