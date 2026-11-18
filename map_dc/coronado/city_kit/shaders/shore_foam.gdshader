shader_type spatial;
// Shore foam (17 Nov, Yasin: "we need some kind of wavy bubbly transition" between the beach and the sea).
// Drawn on one thin strip that follows the curved waterline (built by f_sw.gd): UV.y = 0 on the wet sand, 1 out at
// sea, UV.x = 0..1 along the beach. Bubbly foam from a cellular noise texture; the swash line runs up and down the
// wet sand, a second line of small breaking waves comes and goes 2-3 m out. Unshaded (cheap on Mali), one draw,
// no shadows, no depth write.
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled, fog_disabled;

uniform sampler2D foam_noise : repeat_enable, filter_linear_mipmap;
uniform vec3 foam_color = vec3(0.93, 0.96, 0.96);
uniform float shore_v = 0.21;     // where the still-water line sits across the strip

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float v = UV.y;
	float t = TIME;
	// bubbles: two layers of cellular noise drifting against each other
	float n1 = texture(foam_noise, wpos.xz * 0.30 + vec2(t * 0.020, -t * 0.030)).r;
	float n2 = texture(foam_noise, wpos.xz * 0.85 + vec2(-t * 0.035, t * 0.020)).r;
	float bubbles = smoothstep(0.30, 0.80, n1 * 0.6 + n2 * 0.55);
	// swash: the front laps up the sand and back, foam thinning out seaward of it
	float lap = 0.5 + 0.5 * sin(t * 0.9 + wpos.x * 0.12);
	// (Yasin 17 Nov: push it onto the sand, the water's edge must not show) the swash front laps 0.6-1.6 m up the
	// sand and its foam always reaches past the waterline; a steady foam band sits right over the water's edge
	float front = shore_v - 0.21 + 0.13 * lap;
	float d = v - front;
	float swash = smoothstep(-0.03, 0.0, d) * (1.0 - smoothstep(0.08, 0.30, d));
	float edge = 1.0 - smoothstep(0.03, 0.09, abs(v - shore_v - 0.01));
	// small breakers 2-3 m out, broken along the beach, coming and going
	float br_v = 0.72 + 0.06 * sin(t * 0.6 + wpos.x * 0.08 + 1.3);
	float breaker = (1.0 - smoothstep(0.0, 0.06, abs(v - br_v))) * clamp(0.35 + 0.65 * sin(wpos.x * 0.21 + t * 0.5), 0.0, 1.0);
	float a = max(swash * (0.5 + 0.5 * bubbles), edge * (0.75 + 0.25 * bubbles)) + breaker * bubbles * 0.8;
	// soft edges all round the strip
	a *= smoothstep(0.0, 0.06, v) * (1.0 - smoothstep(0.88, 1.0, v));
	a *= smoothstep(0.0, 0.03, UV.x) * (1.0 - smoothstep(0.97, 1.0, UV.x));
	ALBEDO = foam_color;
	ALPHA = clamp(a, 0.0, 1.0) * 0.92;
}
