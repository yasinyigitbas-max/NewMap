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
void fragment() {
	ALBEDO = texture(ground_arr, vec3(UV, floor(v_layer + 0.5))).rgb * COLOR.rgb;
	ROUGHNESS = v_rough;
	if (ck_city_light > 0.0) {      // the city's sky and far shadow (rt_city_light)
		vec3 cl = ck_city_light_at((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz, vec3(0.0, 1.0, 0.0), CAMERA_POSITION_WORLD);
		AO = cl.x; ALBEDO *= ck_city_shade(cl.y, vec3(0.0, 1.0, 0.0));
	}
}
