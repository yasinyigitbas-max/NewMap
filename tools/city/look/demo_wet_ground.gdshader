// LOOK JOB 5, DEMO ONLY: rt_ground.gdshader (18 Nov) + the wet-ground snippet (sky_reflect.gdshaderinc), so the
// pictures can show the rain mood. look.gd puts it on each cell's ground only with rig --wet above 0. The real change
// belongs in rt_ground.gdshader (the building session's): the two lines marked WET below.
shader_type spatial;
render_mode cull_back;
#include "res://tools/city/look/sky_reflect.gdshaderinc"
uniform sampler2DArray ground_arr : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool debug = false;      // true: show only what the sky map gives (to check the map is bound)
uniform sampler2D puddle_tex : filter_linear_mipmap, repeat_enable;      // the look's sky noise (R): where water lies
varying flat float v_layer;
varying flat float v_rough;
void vertex() { v_layer = UV2.x; v_rough = UV2.y; }
void fragment() {
	ALBEDO = texture(ground_arr, vec3(UV, floor(v_layer + 0.5))).rgb * COLOR.rgb;
	ROUGHNESS = v_rough;
	float puddle = smoothstep(0.35, 0.75, texture(puddle_tex, UV * 0.045).r) * 0.85 + 0.15;      // WET: puddles + a thin film everywhere
	ck_wet_ground(ALBEDO, ROUGHNESS, EMISSION, NORMAL, VIEW, INV_VIEW_MATRIX, puddle);            // WET
	if (debug) { ALBEDO = vec3(0.0); EMISSION = ck_sky_reflect(NORMAL, VIEW, INV_VIEW_MATRIX, 1.0, 1.0); }
}
