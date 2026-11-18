shader_type spatial;
// Overhead wires (w_* pieces). Each wire is ONE ribbon whose two edges share a centre line: UV.x = -1 / +1 picks the
// edge, NORMAL carries the wire direction. The vertex shader turns the ribbon to face the camera and never lets it get
// thinner than ~1.3 px, so long spans do not break into dashes (a fixed 4 cm ribbon is sub-pixel past ~25 m).
// Same triangles as a fixed ribbon, one draw, no shadows.
render_mode unshaded, cull_disabled, world_vertex_coords, shadows_disabled;
uniform vec3 color : source_color = vec3(0.06, 0.06, 0.065);
uniform float half_width = 0.012;      // real cable radius (m)
uniform float px_k = 0.00065;          // minimum half width per metre of distance
void vertex() {
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 t = normalize(NORMAL);
	vec3 v = cam - VERTEX;
	float d = length(v);
	vec3 s = normalize(cross(t, v / max(d, 0.001)));
	VERTEX += s * UV.x * max(half_width, d * px_k);
}
void fragment() { ALBEDO = color; }
