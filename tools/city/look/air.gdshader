// LOOK QUEUE 2, JOB 5: life in the air, in ONE draw (tools/city/look/air.gd): gulls over the waterfront, a plane now
// and then, smoke and steam from the industrial zone. One MultiMesh of quads; every instance is moved and shaped here
// by TIME (no script work per frame). INSTANCE_CUSTOM: r = kind (0 gull, 1 plane, 2 puff), g = phase 0..1,
// b, a = per kind (gull: circle radius, height; plane: -, -; puff: rise height, life in seconds).
// Unshaded, alpha-blended, no depth write; the haze (fog) applies. Per pixel: a few arithmetic steps, no texture read.
// The quads are small on screen (birds ~1 m, the plane far away, puffs up to ~15 m at 100-400 m).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
global uniform float ck_night;
global uniform vec2 ck_wind_dir;
uniform vec3 light = vec3(0.9);          // ambient + sun, from look.gd
uniform float plane_period = 120.0;      // seconds between two planes
varying flat float v_kind;
varying float v_a;
varying float v_flap;
void vertex() {
	float kind = INSTANCE_CUSTOM.r; float ph = INSTANCE_CUSTOM.g;
	vec3 c = MODEL_MATRIX[3].xyz; vec3 pos = c; float size = 1.0; v_a = 1.0; v_flap = 0.0; v_kind = kind;
	if (kind < 0.5) {            // a gull: circles, rises and sinks a little, flaps now and then
		float sp = 0.18 + fract(ph * 7.13) * 0.16;
		float ang = TIME * sp + ph * 6.2832;
		float rad = INSTANCE_CUSTOM.b * (0.85 + 0.15 * sin(TIME * 0.11 + ph * 17.0));
		pos = c + vec3(cos(ang) * rad, INSTANCE_CUSTOM.a + sin(TIME * 0.27 + ph * 9.0) * 3.0, sin(ang) * rad);
		float glide = smoothstep(0.2, 0.6, sin(TIME * 0.5 + ph * 23.0));
		v_flap = mix(sin(TIME * 7.5 + ph * 40.0), 0.35, glide);
		size = 1.5; v_a = 1.0 - smoothstep(0.4, 0.8, ck_night);      // gulls roost at night
	} else if (kind < 1.5) {     // the plane: crosses high and far, then is gone for a while
		float t = fract(TIME / plane_period + ph);
		float s = t / 0.5;
		pos = c + vec3(-3500.0 + 7000.0 * s, 0.0, -900.0 + 1800.0 * s * 0.3);
		size = 36.0; v_a = step(t, 0.5) * smoothstep(0.0, 0.05, s) * (1.0 - smoothstep(0.95, 1.0, s));
	} else {                     // a puff of smoke or steam: rises, drifts with the wind, grows, fades
		float life = INSTANCE_CUSTOM.a;
		float age = fract(TIME / life + ph);
		pos = c + vec3(0.0, age * INSTANCE_CUSTOM.b, 0.0) + vec3(ck_wind_dir.x, 0.0, ck_wind_dir.y) * age * age * INSTANCE_CUSTOM.b * 1.4;
		size = 2.5 + age * INSTANCE_CUSTOM.b * 0.55;
		v_a = smoothstep(0.0, 0.08, age) * (1.0 - age) * (1.0 - age);
	}
	if (v_a < 0.002) { VERTEX = vec3(0.0); }
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * size, INV_VIEW_MATRIX[1] * size, INV_VIEW_MATRIX[2] * size, vec4(pos, 1.0));
}
void fragment() {
	vec2 q = UV - vec2(0.5);
	vec3 col; float a;
	if (v_kind < 0.5) {          // a gull seen from below / the side: two curved wings, a small body
		float x = abs(q.x);
		float wing = -q.y - (x * (0.55 * v_flap + 0.15) - x * x * 0.9);      // the wing line, bent by the flap
		float th = 0.09 * (1.0 - x * 1.5);
		a = (1.0 - smoothstep(th * 0.5, th, abs(wing))) * step(x, 0.48) + (1.0 - smoothstep(0.04, 0.07, length(q * vec2(1.0, 1.6))));
		col = vec3(0.93, 0.93, 0.90) * light * mix(1.0, 0.75, smoothstep(0.25, 0.45, x));      // grey wing tips
	} else if (v_kind < 1.5) {   // the plane: a thin dark cross far away; at night only its lights, blinking
		float body = (1.0 - smoothstep(0.008, 0.016, abs(q.y))) * step(abs(q.x), 0.16);
		float wings = (1.0 - smoothstep(0.012, 0.022, abs(q.x + 0.02))) * step(abs(q.y), 0.22);
		a = max(body, wings) * (1.0 - ck_night) * 0.8;
		col = vec3(0.32) * light;
		float blink = step(0.85, fract(TIME * 0.9));
		float lamp = (1.0 - smoothstep(0.0, 0.03, length(q - vec2(0.0, 0.22)))) + (1.0 - smoothstep(0.0, 0.03, length(q + vec2(0.0, 0.22))));
		if (lamp * blink > 0.01) { col = vec3(1.0, 0.25, 0.2) * 3.0; a = lamp * blink; }
	} else {                     // a puff: a soft round cloud, lit by the look's light
		float r2 = dot(q, q) * 4.0;
		a = (1.0 - r2) * (1.0 - r2) * step(r2, 1.0) * 0.8;
		col = vec3(0.78, 0.78, 0.76) * light;
	}
	ALBEDO = col;
	ALPHA = clamp(a * v_a, 0.0, 1.0);
}
