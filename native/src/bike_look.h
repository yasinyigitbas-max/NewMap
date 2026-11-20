// The bicycle's look: Yasin's beach cruiser (the assets branch, coronado-source 82d711276; assets/coronado_kit/props/
// bicycle: near / mid / far / col tiers, a rig with wheel_front, wheel_rear, crank, pedals, kickstand, steer; one 512
// page of colour (alpha 1 = the frame's paint), normal and ORM). Shared by the player's bicycle (CityBike: the rig, its
// parts turning), the traffic's cyclists (CityTraffic: the mid tier in one batch) and the fallen bicycles.
//
// THE FRAME everything here is in: the riders' (people_bake.h: the far figures' riding poses, BikeReach): origin on the
// ground under the crank's axle, +z forward. The model's own origin is 0.08 m ahead of the crank, so every mesh and the
// rig are moved forward by SHIFT. Measured from the model (tools/city/traffic/bike_measure.gd, 19 Nov).
#pragma once

#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/shader.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>

namespace godot {
namespace bike_look {

inline String dir() { return String("res://assets/coronado_kit/props/bicycle/"); }
constexpr float SHIFT = 0.08f;                    // the model's crank sits at z -0.08
constexpr float WR = 0.333f;                      // wheel radius
constexpr float BB_Y = 0.28f, CRANK_R = 0.17f, PEDAL_X = 0.124f;   // the crank's axle height, its arm, the pedals' side
constexpr float HUB_F = 0.63f, HUB_R = -0.47f;    // the axles along z (wheelbase 1.10 m)
constexpr float SADDLE_Y = 0.953f, SADDLE_Z = -0.225f;            // the saddle's top
constexpr float GRIP_X = 0.32f, GRIP_Y = 0.974f, GRIP_Z = 0.194f;  // the grips' middles (wide swept-back cruiser bars)
// the steering axis: from the steer pivot (0, 0.693, 0.437) down to the front axle (0, 0.334, 0.63)
inline Vector3 steer_axis() { return Vector3(0.0f, 0.6927f - 0.334f, 0.3566f - 0.55f).normalized(); }

// the rider's figure (seated clip) in the riders' frame: his hips over the saddle (CityBike, the crowd's near riders)
inline Vector3 rider_at() { return Vector3(0.0f, SADDLE_Y - 0.545f + 0.10f, SADDLE_Z + 0.035f + 0.31f); }
inline bool available() { return ResourceLoader::get_singleton()->exists(dir() + String("prop_bicycle_cruiser_rig.glb")); }

inline String shader_code() {
	return String(
		"shader_type spatial;\n"
		"// the beach cruiser (native/src/bike_look.h): colour (alpha 1 = the frame's paint), normal, ORM\n"
		"uniform sampler2D tex_color : source_color, filter_linear_mipmap_anisotropic;\n"
		"uniform sampler2D tex_normal : hint_normal, filter_linear_mipmap;\n"
		"uniform sampler2D tex_orm : hint_default_white, filter_linear_mipmap;\n"
		"uniform vec3 paint_u = vec3(-1.0);   // (one bicycle of its own; < 0: a row of a batch, its colour in the row's custom data)\n"
		"uniform bool normals = true;\n"
		"varying vec3 paint;\n"
		"void vertex() { paint = paint_u.x >= 0.0 ? paint_u : INSTANCE_CUSTOM.rgb; }\n"
		"void fragment() {\n"
		"\tvec4 c = texture(tex_color, UV);\n"
		"\tfloat pm = smoothstep(0.5, 0.9, c.a);\n"
		"\tALBEDO = c.rgb * mix(vec3(1.0), paint, pm);\n"
		"\tvec3 o = texture(tex_orm, UV).rgb;\n"
		"\tAO = o.r; AO_LIGHT_AFFECT = 0.5; ROUGHNESS = o.g; METALLIC = o.b;\n"
		"\tif (normals) NORMAL_MAP = texture(tex_normal, UV).rgb;\n"
		"}\n");
}

inline Ref<ShaderMaterial> material(bool p_normals) {
	ResourceLoader *rl = ResourceLoader::get_singleton();
	Ref<Shader> sh; sh.instantiate(); sh->set_code(shader_code());
	Ref<ShaderMaterial> m; m.instantiate(); m->set_shader(sh);
	m->set_shader_parameter("tex_color", rl->load(dir() + String("bicycle_cruiser_color.png")));
	m->set_shader_parameter("tex_orm", rl->load(dir() + String("bicycle_cruiser_orm.png")));
	if (p_normals) m->set_shader_parameter("tex_normal", rl->load(dir() + String("bicycle_cruiser_normal.png")));
	m->set_shader_parameter("normals", p_normals);
	return m;
}

// A tier's mesh ("near", "mid", "far"), moved into the riders' frame (made at load, never per frame)
inline Ref<Mesh> tier(const char *p_tier) {
	Ref<PackedScene> ps = ResourceLoader::get_singleton()->load(dir() + String("prop_bicycle_cruiser_") + String(p_tier) + String(".glb"));
	if (ps.is_null()) return Ref<Mesh>();
	Node *n = ps->instantiate();
	Ref<Mesh> src;
	std::vector<Node *> st{ n };
	while (!st.empty() && src.is_null()) {
		Node *k = st.back(); st.pop_back();
		if (MeshInstance3D *mi = Object::cast_to<MeshInstance3D>(k)) src = mi->get_mesh();
		for (int c = 0; c < k->get_child_count(); c++) st.push_back(k->get_child(c));
	}
	memdelete(n);
	if (src.is_null()) return src;
	Ref<ArrayMesh> out; out.instantiate();
	for (int s = 0; s < src->get_surface_count(); s++) {
		Array a = src->surface_get_arrays(s);
		PackedVector3Array v = a[Mesh::ARRAY_VERTEX];
		for (int i = 0; i < v.size(); i++) v.set(i, v[i] + Vector3(0, 0, SHIFT));
		a[Mesh::ARRAY_VERTEX] = v;
		out->add_surface_from_arrays(Mesh::PRIMITIVE_TRIANGLES, a);
	}
	return out;
}

// The rig, made a child's tree: frame, crank (pedal_l, pedal_r), kickstand, steer (wheel_front), wheel_rear, moved into
// the riders' frame; every part takes the material
inline Node3D *make_rig(const Ref<ShaderMaterial> &p_mat) {
	Ref<PackedScene> ps = ResourceLoader::get_singleton()->load(dir() + String("prop_bicycle_cruiser_rig.glb"));
	if (ps.is_null()) return nullptr;
	Node3D *r = Object::cast_to<Node3D>(ps->instantiate());
	if (!r) return nullptr;
	r->set_position(Vector3(0, 0, SHIFT));
	std::vector<Node *> st{ r };
	while (!st.empty()) {
		Node *k = st.back(); st.pop_back();
		if (MeshInstance3D *mi = Object::cast_to<MeshInstance3D>(k)) mi->set_material_override(p_mat);
		for (int c = 0; c < k->get_child_count(); c++) st.push_back(k->get_child(c));
	}
	return r;
}

} // namespace bike_look
} // namespace godot
