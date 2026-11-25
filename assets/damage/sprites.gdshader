shader_type spatial;
// The damage system's particles (CityDamage, 25 Nov 2026): dust, chips, sparks, splinters, leaves, glass, drops, clods.
// ONE MultiMesh of camera-facing quads, moved on the CPU (city_damage.cpp step_parts): one draw while any flies.
// Lit like the world (so dust is dark at night); a spark glows on its own (INSTANCE_CUSTOM.y).
//  COLOR = tint and alpha, INSTANCE_CUSTOM.x = the tile on sprites.png (4 x 4, tools/damage/make_mark_sheet.py)
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, specular_disabled;
uniform sampler2D sheet : source_color, filter_linear_mipmap, repeat_disable;
varying vec2 v_uv;
varying float v_glow;
void vertex() {
	float tile = floor(INSTANCE_CUSTOM.x + 0.5);
	vec2 cell = vec2(mod(tile, 4.0), floor(tile / 4.0));
	v_uv = (cell + clamp(UV, vec2(0.01), vec2(0.99))) * 0.25;
	v_glow = INSTANCE_CUSTOM.y;
}
void fragment() {
	vec4 t = texture(sheet, v_uv);
	ALBEDO = t.rgb * COLOR.rgb;
	ALPHA = t.a * COLOR.a;
	EMISSION = t.rgb * COLOR.rgb * v_glow;
	ROUGHNESS = 1.0;
}
