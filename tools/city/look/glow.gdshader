// LOOK JOB 3 (18 Nov, sky session): the look pack's lamp glow. The same quads the bake makes for every lamp
// (glow_halo: a billboard at the lamp head, glow_pool: a flat quad on the ground; one MultiMesh each per cell,
// INSTANCE_CUSTOM.rgb = the lamp's colour), drawn differently. look.gd puts this material on a cell's glow nodes when
// the cell comes in (rig --glow=1, the default with the look); --glow=0 keeps the bake's rt_glow.gdshader.
// The bake's shader is not changed; docs/look_patches/glow.md has the same change written for it.
//  halo  a hot core + a wide soft glow, street lamps warmer (sodium), pulled 0.4 m towards the camera so it does not
//        cut into the lamp head or the wall behind it (the old one was a flat white disc);
//  pool  lifted 0.18 m so kerbs and pavements no longer slice it with a hard line, a light-like falloff that reaches
//        0 at the edge, drawn 15 % smaller (the faint rim cost pixels for nothing);
//  both  fade with distance at about the night haze's density (fog stays disabled: the engine's fog would grey an
//        additive glow instead of dimming it).
// Per pixel: a few more arithmetic steps than before, no texture read, additive blend as before. The halo quad is
// 1.8 x wider (3.2 x the pixels of a small quad); the pool quad 0.85 x (0.72 x the pixels of the big ones).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
global uniform float ck_night;
uniform float energy = 1.0;
uniform bool billboard = false;
uniform float halo_scale = 1.8;
uniform float pull = 0.4;
uniform float pool_scale = 0.85;
uniform float pool_lift = 0.18;
uniform float haze = 0.0022;
uniform vec3 warm = vec3(1.0, 0.80, 0.56);
varying vec3 v_col;
varying float v_fade;
void vertex() {
	v_col = INSTANCE_CUSTOM.rgb;
	if (v_col.r > v_col.b) v_col *= warm;      // warm lamps towards sodium; the cool lot lights stay white
	float sc = length(MODEL_MATRIX[0].xyz);
	vec3 at = MODEL_MATRIX[3].xyz;
	vec3 eye = INV_VIEW_MATRIX[3].xyz;
	v_fade = exp(-distance(at, eye) * haze);
	if (billboard) {
		sc *= halo_scale;
		at += normalize(eye - at) * pull;
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sc, INV_VIEW_MATRIX[1] * sc, INV_VIEW_MATRIX[2] * sc, vec4(at, 1.0));
	} else {
		VERTEX.xy *= pool_scale;
		VERTEX.z += pool_lift / sc;      // the pool's quad is turned flat: its local +Z is up
	}
	if (ck_night < 0.02) VERTEX = vec3(0.0);
}
void fragment() {
	float r = clamp(length(UV - vec2(0.5)) * 2.0, 0.0, 1.0);
	float r2 = r * r;
	float e = (1.0 - r2) * (1.0 - r2);
	float a;
	if (billboard) {
		a = (exp(-r2 * 90.0) * 1.6 + exp(-r2 * 9.0) * 0.45 + 0.08) * e;      // core, glow, faint haze
	} else {
		a = exp(-r2 * 3.2) * e * 1.3;
	}
	ALBEDO = v_col * a * energy * smoothstep(0.15, 0.6, ck_night) * v_fade;
}
