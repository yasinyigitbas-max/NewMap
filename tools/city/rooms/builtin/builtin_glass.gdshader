shader_type spatial;
// Built-in interiors (22 Nov, Yasin: "see-through windows"): the shop window glass of a kit building that carries its
// own interior. The kit's rule is "no transparency on buildings" (SPEC.md: cut-outs alone cost 5.5 ms on the Redmi), so
// this is the cheapest pane that still reads as glass you see through:
//  - ONE alpha-blended surface for all the panes of a building (one draw), unshaded (no lights, no shadows), no
//    texture fetch, no depth write: per pixel a fresnel term and a two-colour sky reflection, nothing else;
//  - near (< far_begin) it is almost clear: the real interior props show through, with a faint tint and reflection;
//  - from far_begin to far_end it closes to an opaque-looking dark reflective pane, the kit's painted-glass look, so the
//    interior props can be culled there (their visibility range ends at far_end) and nobody sees an empty room;
//  - crack (instance, 0..1): a procedural star of cracks round crack_at (window damage, builtin_window.gd).
// Overdraw: only the panes' own pixels, once (they never overlap each other on screen from the street).
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled, fog_disabled;
uniform vec3 tint : source_color = vec3(0.60, 0.68, 0.70);
uniform vec3 sky_top : source_color = vec3(0.50, 0.66, 0.86);
uniform vec3 sky_horizon : source_color = vec3(0.82, 0.86, 0.88);
uniform vec3 street : source_color = vec3(0.20, 0.19, 0.18);
uniform float clear_alpha = 0.10;      // straight on, near
uniform float far_begin = 24.0;
uniform float far_end = 30.0;
uniform float far_alpha = 0.92;
instance uniform float crack = 0.0;
instance uniform vec2 crack_at = vec2(0.5, 0.5);      // in the pane's UV (0..1 across the pane)
varying vec3 v_wn;
void vertex() { v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }
float h11(float x) { return fract(sin(x * 91.345) * 47453.21); }
void fragment() {
	float d = length(VERTEX);
	vec3 n = normalize(NORMAL);
	float nv = abs(dot(n, VIEW));
	float f = 1.0 - nv; float f2 = f * f;
	float fres = 0.04 + 0.96 * f2 * f2 * f;
	vec3 wv = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	vec3 wn = normalize(v_wn) * (dot(v_wn, wv) < 0.0 ? -1.0 : 1.0);
	vec3 r = reflect(-wv, wn);
	float up = clamp(r.y * 3.0 + 0.15, 0.0, 1.0);
	vec3 refl = mix(street, mix(sky_horizon, sky_top, clamp(r.y, 0.0, 1.0)), up);
	float far = smoothstep(far_begin, far_end, d);
	float a = clamp(clear_alpha + fres * 0.55, 0.0, 0.9);
	a = mix(a, far_alpha, far);
	vec3 col = mix(tint * 0.35, refl, clamp(fres + far * 0.55, 0.0, 1.0));
	if (crack > 0.001) {
		vec2 p = (UV - crack_at) * vec2(1.0, 2.0);
		float ang = atan(p.y, p.x); float rad = length(p);
		float k = floor((ang + 3.1416) / 6.2832 * 11.0);
		float c0 = (k + 0.5 + (h11(k) - 0.5) * 0.6) / 11.0 * 6.2832 - 3.1416;
		float line = 1.0 - smoothstep(0.0, 0.012 + rad * 0.004, abs(sin(ang - c0)) * rad);
		line *= step(rad, 0.25 + 0.75 * h11(k + 7.0)) * crack;
		float ring = (1.0 - smoothstep(0.0, 0.01, abs(fract(rad * 4.0 + h11(k) * 0.3) - 0.5) - 0.47)) * step(rad, 0.6) * crack * 0.7;
		float cr = clamp(max(line, ring), 0.0, 1.0);
		col = mix(col, vec3(0.92, 0.95, 0.96), cr);
		a = max(a, cr * 0.85);
	}
	ALBEDO = col;
	ALPHA = a;
}
