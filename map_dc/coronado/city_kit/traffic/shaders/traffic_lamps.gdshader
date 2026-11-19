shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
// The lamps of the traffic's cars: ONE batch for every car that shows a light (CityTraffic, native/src). The mesh is
// four small squares at the corners of a unit car (two at the front, two at the back; UV2.x = 1 for the front ones), a
// row scales it to its car. The car models do not mark their lamps (the old game drew glow pieces too), so the glow
// is drawn over the lens. A row's custom data: (braking 0/1, -, lights on 0..1, -).
varying float v_i;
varying float v_front;

void vertex() {
	v_front = UV2.x;
	v_i = UV2.x > 0.5 ? INSTANCE_CUSTOM.z * 1.5 : INSTANCE_CUSTOM.z * 0.6 + INSTANCE_CUSTOM.x * 1.6;   // headlights; tail lights, brighter when braking
	// a lamp shows only to the side it faces (headlights forward, tail lights back), fading as the car turns away
	vec3 n = normalize((MODELVIEW_MATRIX * vec4(0.0, 0.0, UV2.x > 0.5 ? 1.0 : -1.0, 0.0)).xyz);
	vec3 p = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_i *= clamp(dot(n, normalize(-p)) * 3.0, 0.0, 1.0);
	if (v_i < 0.01) VERTEX = vec3(0.0);   // nothing to show: no pixels
}

void fragment() {
	vec2 d = UV * 2.0 - 1.0;
	float f = clamp(1.0 - dot(d, d), 0.0, 1.0);
	ALBEDO = (v_front > 0.5 ? vec3(1.0, 0.93, 0.78) : vec3(1.0, 0.05, 0.03)) * f * f * v_i;
}
