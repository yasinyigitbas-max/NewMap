// Runtime bake (18 Nov): the whole ground of a 200 m cell in ONE draw. The nine tiling ground textures are layers of
// runtime_tex/arr_ground.png. Per vertex: UV = the piece's own world-metre UVs, UV2 = (layer, roughness),
// COLOR = the surface's tint (asphalt, concrete, kerb, tactile yellow ... all as built).
shader_type spatial;
render_mode cull_back;
#include "res://map_dc/coronado/city_kit/shaders/rt/rt_city_light.gdshaderinc"
uniform sampler2DArray ground_arr : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying flat float v_layer;
varying flat float v_rough;
void vertex() { v_layer = UV2.x; v_rough = UV2.y; }
// GROUND VARIATION (look uplift, 28 Nov; the audit: "lawns and lots are one tiled grass texture, edge to edge"; the
// asphalt "reads as dirt, not road"): one small noise picture read twice in world metres (97 m and 23 m) breaks every
// surface's even colour; grass gets dry, yellowed patches; asphalt gets a fine grain within 25 m of the camera (the
// walls' detail picture). ck_look_ground 0 = as before. 2-3 reads of small textures per ground pixel.
global uniform float ck_look_ground;
global uniform sampler2D ck_look_noise : filter_linear_mipmap, repeat_enable;
global uniform sampler2D ck_look_detail_tex : filter_linear_mipmap, repeat_enable;
void fragment() {
	float layer = floor(v_layer + 0.5);
	ALBEDO = texture(ground_arr, vec3(UV, layer)).rgb * COLOR.rgb;
	ROUGHNESS = v_rough;
	if (ck_look_ground > 0.0) {
		vec3 gwp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float n1 = texture(ck_look_noise, gwp.xz / 97.0).r;
		float n2 = texture(ck_look_noise, gwp.xz / 23.0 + vec2(0.37, 0.11)).g;
		float m = n1 * 0.65 + n2 * 0.35;
		float k = ck_look_ground;
		if (layer == 2.0) {      // grass: lusher and drier patches
			float n3 = texture(ck_look_noise, gwp.xz / 6.5 + vec2(0.71, 0.53)).r;      // clumps
			float dry = smoothstep(0.42, 0.72, m) * 0.9 * k;
			ALBEDO = mix(ALBEDO * mix(0.7, 1.12, n2) * mix(0.82, 1.12, n3), ALBEDO * vec3(1.45, 1.18, 0.55), dry);
		} else if (layer == 0.0) {      // asphalt: worn lighter and patched darker, and its grain up close
			ALBEDO *= mix(1.0, mix(0.7, 1.22, m), k);
			float dn = distance(CAMERA_POSITION_WORLD, gwp);
			float nf = 1.0 - smoothstep(10.0, 25.0, dn);
			if (nf > 0.01) ALBEDO *= 1.0 + (texture(ck_look_detail_tex, gwp.xz / 1.3).r - 0.5) * 0.45 * nf * k;
		} else if (layer < 5.0 || layer > 6.5) {      // concrete, dry ground, stone, gravel, sand, rock (not the paint lines)
			ALBEDO *= mix(1.0, mix(0.8, 1.14, m), k);
		}
	}
	if (ck_city_light > 0.0) {      // the city's sky and far shadow (rt_city_light)
		vec3 cl = ck_city_light_at((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz, vec3(0.0, 1.0, 0.0), CAMERA_POSITION_WORLD);
		AO = cl.x; ALBEDO *= ck_city_shade(cl.y, vec3(0.0, 1.0, 0.0));
	}
}
