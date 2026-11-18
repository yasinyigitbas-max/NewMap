// Runtime bake (18 Nov): night glow of the lamps. One MultiMesh of quads per cell and kind, drawn only at night:
//  RT_BILLBOARD  the lamp head's halo (always faces the camera);  otherwise the pool of light lying on the ground.
// The REAL light of the nearest lamps comes from the engine's mobile light grid (32 omni for a fixed cost): the bake
// records every lamp as a light anchor (cell meta "lights") and tools/city/bake/city_lights.gd lights the nearest.
// The halos and pools carry every other lamp of the loaded cells for two draws a cell. INSTANCE_CUSTOM.rgb = colour.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
global uniform float ck_night;
uniform float energy = 1.0;
uniform bool billboard = false;
varying vec3 v_col;
void vertex() {
	v_col = INSTANCE_CUSTOM.rgb;
	if (billboard) {
		float sc = length(MODEL_MATRIX[0].xyz);
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sc, INV_VIEW_MATRIX[1] * sc, INV_VIEW_MATRIX[2] * sc, MODEL_MATRIX[3]);
	}
	if (ck_night < 0.02) VERTEX = vec3(0.0);
}
void fragment() {
	float r = clamp(length(UV - vec2(0.5)) * 2.0, 0.0, 1.0);
	float a = (1.0 - r) * (1.0 - r);
	ALBEDO = v_col * a * energy * smoothstep(0.15, 0.6, ck_night);
}
