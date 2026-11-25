shader_type spatial;
// The damage system's hit marks (CityDamage, 25 Nov 2026): every mark of the world is one quad of ONE MultiMesh, so all
// marks are one draw. Multiplied onto what is behind them (white = no change): a hole darkens a sunlit wall and a wall
// at night by the same share, with no light of its own, so it needs no lighting (unshaded) and casts nothing.
//  INSTANCE_CUSTOM.x = the tile on marks.png (4 x 4, tools/damage/make_mark_sheet.py), .y = how strong (the oldest fade)
render_mode blend_mul, unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform sampler2D sheet : source_color, filter_linear_mipmap, repeat_disable;
uniform float far = 70.0;          // gone by here (a mark is a few centimetres: nothing to see farther)
varying vec2 v_uv;
varying float v_a;
void vertex() {
	float tile = floor(INSTANCE_CUSTOM.x + 0.5);
	vec2 cell = vec2(mod(tile, 4.0), floor(tile / 4.0));
	v_uv = (cell + clamp(UV, vec2(0.004), vec2(0.996))) * 0.25;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float d = length(wp - CAMERA_POSITION_WORLD);
	v_a = INSTANCE_CUSTOM.y * (1.0 - smoothstep(far * 0.8, far, d));
	// pulled a little towards the camera (more with distance), so it never fights the wall it lies on
	vec3 to_cam = normalize(CAMERA_POSITION_WORLD - wp);
	VERTEX = (inverse(MODEL_MATRIX) * vec4(wp + to_cam * (0.004 + d * 0.0006), 1.0)).xyz;
}
void fragment() {
	vec3 m = texture(sheet, v_uv).rgb;
	ALBEDO = mix(vec3(1.0), m, v_a);
}
