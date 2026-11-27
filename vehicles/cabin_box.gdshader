shader_type spatial;
// The cabin seen through an open door (CityCar, the old cars with real doors): an inward-facing box the size of the cabin
// box, showing the same cabin picture as the glass's interior mapping (car_paint.gdshader cabin_*), by the direction
// from the box centre. Drawn only while a door is open.
render_mode cull_front, diffuse_lambert;
uniform vec3 cabin_lo = vec3(-0.7, 0.35, -1.0);
uniform vec3 cabin_hi = vec3(0.7, 1.2, 0.3);
uniform sampler2D cabin_cube : source_color, filter_linear, repeat_disable;
varying vec3 v_p;
void vertex() { v_p = VERTEX; }
vec3 cabin_face(vec3 d) {
	vec3 a = abs(d);
	vec3 f; vec3 u; float i;
	if (a.x >= a.y && a.x >= a.z) { f = vec3(sign(d.x), 0.0, 0.0); u = vec3(0.0, 1.0, 0.0); i = d.x > 0.0 ? 0.0 : 1.0; }
	else if (a.y >= a.z) { f = vec3(0.0, sign(d.y), 0.0); u = vec3(0.0, 0.0, -sign(d.y)); i = d.y > 0.0 ? 2.0 : 3.0; }
	else { f = vec3(0.0, 0.0, sign(d.z)); u = vec3(0.0, 1.0, 0.0); i = d.z > 0.0 ? 4.0 : 5.0; }
	vec3 r = cross(f, u);
	float df = dot(d, f);
	vec2 st = clamp(vec2(dot(d, r), dot(d, u)) / df, -0.995, 0.995);
	vec2 fuv = vec2(st.x + 1.0, 1.0 - st.y) * 0.5;
	return texture(cabin_cube, (vec2(mod(i, 3.0), floor(i / 3.0)) + fuv) / vec2(3.0, 2.0)).rgb;
}
void fragment() {
	ALBEDO = cabin_face(normalize(v_p - (cabin_lo + cabin_hi) * 0.5));
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
}
