// Contact shadows between models (look job 4, prototype; tools/city/look/contact_proto.gd): soft dark where one model
// meets another - a building on the pavement, the wall under an awning. Multiplies what is behind it (no lighting,
// no texture read): COLOR.a = how dark at this vertex, interpolated across the quad. ck_look_between 0 = off.
shader_type spatial;
render_mode blend_mul, unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
global uniform float ck_look_between;
uniform float strength = 1.0;
void fragment() {
	float a = clamp(COLOR.a * strength * ck_look_between, 0.0, 0.9);
	ALBEDO = vec3(1.0 - a * a * (3.0 - 2.0 * a) * 0.85);
}
