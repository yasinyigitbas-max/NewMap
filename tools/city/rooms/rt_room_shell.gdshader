// Merged room shell (18 Nov, rooms on all shops; prototype - tools/city/rooms/room_merge.gd): walls, floors, ceilings,
// skirting, frames and light fittings of a room in ONE draw. The room textures are layers of runtime_tex/arr_room.png
// (layer 0 white for the plain-coloured parts). Per vertex: UV2 = (layer, emission), COLOR = linear tint + roughness.
shader_type spatial;
render_mode cull_back;
uniform sampler2DArray room_arr : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying flat float v_layer;
varying flat float v_emit;
void vertex() { v_layer = UV2.x; v_emit = UV2.y; }
void fragment() {
	vec3 c = texture(room_arr, vec3(UV, floor(v_layer + 0.5))).rgb * COLOR.rgb;
	ALBEDO = c;
	ROUGHNESS = COLOR.a;
	EMISSION = c * v_emit;
}
