// The shop signs inside the merged rooms (tools/city/rooms/room_merge.gd): one shared shader, each room's sign plate only
// passes its own picture. (20 Nov: each room had its own StandardMaterial3D, and the engine generated and compiled a
// shader for every one the first time it was used: 65-82 ms on the main thread per room on the PC, 48-74 ms on the
// Redmi, a stutter every time a shop came into range.) Same look as before: the picture as albedo, roughness 0.7.
shader_type spatial;
render_mode cull_back;

uniform sampler2D sign_tex : source_color, filter_linear_mipmap_anisotropic;

void fragment() {
	ALBEDO = texture(sign_tex, UV).rgb;
	ROUGHNESS = 0.7;
}
