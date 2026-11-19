// CityCrowd, the smaller things round the people: twelve collision capsules that stand on the people nearest the
// player (so he bumps into them), umbrellas in rain, towels under the people who lie on the beach, and a quiet murmur
// where a group stands and talks. See city_crowd.h.
#include "city_crowd.h"

#include "city_ped.h"
#include "ped_inl.h"

#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/classes/audio_stream_ogg_vorbis.hpp>
#include <godot_cpp/classes/audio_stream_player3d.hpp>
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/physics_server3d.hpp>
#include <godot_cpp/classes/rendering_server.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/variant/packed_color_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>

namespace godot {

namespace {

const int XROW = 16;   // a row of the props' batches: transform 12, colour 4
const float UMB[8][3] = { { 0.08f, 0.08f, 0.09f }, { 0.12f, 0.16f, 0.32f }, { 0.55f, 0.08f, 0.1f }, { 0.1f, 0.3f, 0.2f }, { 0.75f, 0.72f, 0.65f }, { 0.85f, 0.7f, 0.15f }, { 0.3f, 0.3f, 0.33f }, { 0.5f, 0.2f, 0.45f } };
const float TOWEL[6][3] = { { 0.85f, 0.2f, 0.2f }, { 0.15f, 0.4f, 0.75f }, { 0.95f, 0.85f, 0.3f }, { 0.2f, 0.65f, 0.6f }, { 0.9f, 0.9f, 0.88f }, { 0.9f, 0.5f, 0.2f } };

// an umbrella held up: a shallow eight-sided canopy over the walker's head, its stick down to his hand (the figure's
// frame: +x his left, +z ahead; he holds it in his right hand, a little ahead)
Ref<ArrayMesh> umbrella_mesh() {
	PackedVector3Array v, n; PackedInt32Array ix;
	const Vector3 top(-0.18f, 2.28f, 0.14f);
	const float rim_y = 2.05f, r = 0.58f;
	v.push_back(top); n.push_back(Vector3(0, 1, 0));
	for (int k = 0; k < 8; k++) {
		const float a = (float)k * 0.7853982f;
		v.push_back(Vector3(top.x + std::sin(a) * r, rim_y, top.z + std::cos(a) * r));
		n.push_back(Vector3(std::sin(a) * 0.5f, 0.87f, std::cos(a) * 0.5f));
	}
	for (int k = 0; k < 8; k++) { ix.push_back(0); ix.push_back(1 + k); ix.push_back(1 + (k + 1) % 8); }
	// the stick: a thin four-sided rod from the hand to the top
	const int s0 = (int)v.size();
	const float sr = 0.012f, y0 = 1.12f;
	for (int k = 0; k < 4; k++) {
		const float a = (float)k * 1.5707963f;
		const Vector3 o(std::sin(a) * sr, 0, std::cos(a) * sr);
		v.push_back(Vector3(top.x, y0, top.z) + o); n.push_back(o.normalized());
		v.push_back(Vector3(top.x, top.y, top.z) + o); n.push_back(o.normalized());
	}
	for (int k = 0; k < 4; k++) {
		const int a = s0 + k * 2, b = s0 + ((k + 1) % 4) * 2;
		ix.push_back(a); ix.push_back(b); ix.push_back(a + 1); ix.push_back(b); ix.push_back(b + 1); ix.push_back(a + 1);
	}
	Array arr; arr.resize(Mesh::ARRAY_MAX);
	arr[Mesh::ARRAY_VERTEX] = v; arr[Mesh::ARRAY_NORMAL] = n; arr[Mesh::ARRAY_INDEX] = ix;
	Ref<ArrayMesh> m; m.instantiate();
	m->add_surface_from_arrays(Mesh::PRIMITIVE_TRIANGLES, arr);
	return m;
}

Ref<ArrayMesh> towel_mesh() {
	PackedVector3Array v, n; PackedInt32Array ix;
	const float hw = 0.45f, hl = 1.0f;
	v.push_back(Vector3(-hw, 0.012f, -hl)); v.push_back(Vector3(hw, 0.012f, -hl)); v.push_back(Vector3(hw, 0.012f, hl)); v.push_back(Vector3(-hw, 0.012f, hl));
	for (int k = 0; k < 4; k++) n.push_back(Vector3(0, 1, 0));
	const int q[6] = { 0, 2, 1, 0, 3, 2 };
	for (int k = 0; k < 6; k++) ix.push_back(q[k]);
	Array arr; arr.resize(Mesh::ARRAY_MAX);
	arr[Mesh::ARRAY_VERTEX] = v; arr[Mesh::ARRAY_NORMAL] = n; arr[Mesh::ARRAY_INDEX] = ix;
	Ref<ArrayMesh> m; m.instantiate();
	m->add_surface_from_arrays(Mesh::PRIMITIVE_TRIANGLES, arr);
	return m;
}

void put(float *r, float x, float y, float z, float yaw, float s, const float *col) {
	const float c = std::cos(yaw) * s, sn = std::sin(yaw) * s;
	r[0] = c; r[1] = 0.0f; r[2] = sn; r[3] = x;
	r[4] = 0.0f; r[5] = s; r[6] = 0.0f; r[7] = y;
	r[8] = -sn; r[9] = 0.0f; r[10] = c; r[11] = z;
	r[12] = col[0]; r[13] = col[1]; r[14] = col[2]; r[15] = 1.0f;
}

} // namespace

void CityCrowd::make_extras() {
	RenderingServer *rs = RenderingServer::get_singleton();
	Ref<StandardMaterial3D> m; m.instantiate();
	m->set_flag(BaseMaterial3D::FLAG_ALBEDO_FROM_VERTEX_COLOR, true);
	m->set_cull_mode(BaseMaterial3D::CULL_DISABLED);
	m->set_roughness(0.85f);
	mat_prop = m;
	mesh_umb = umbrella_mesh(); mesh_towel = towel_mesh();
	for (int k = 0; k < 2; k++) {
		prop_mm[k] = rs->multimesh_create();
		rs->multimesh_allocate_data(prop_mm[k], k ? 128 : 512, RenderingServer::MULTIMESH_TRANSFORM_3D, true, false);
		rs->multimesh_set_mesh(prop_mm[k], (k ? mesh_towel : mesh_umb)->get_rid());
		rs->multimesh_set_visible_instances(prop_mm[k], 0);
		prop_inst[k] = rs->instance_create2(prop_mm[k], get_world_3d()->get_scenario());
		rs->instance_set_custom_aabb(prop_inst[k], AABB(Vector3(-4000, -200, -4000), Vector3(8000, 600, 8000)));
		rs->instance_geometry_set_material_override(prop_inst[k], mat_prop->get_rid());
		rs->instance_geometry_set_cast_shadows_setting(prop_inst[k], RenderingServer::SHADOW_CASTING_SETTING_OFF);
		rs->instance_set_visible(prop_inst[k], false);
		prop_buf[k].resize((int64_t)(k ? 128 : 512) * XROW);
		prop_shown[k] = 0;
	}
	// the capsules round the player: made once, moved afterwards (their layer is 6: the player's body looks at it)
	PhysicsServer3D *ps = PhysicsServer3D::get_singleton();
	const RID space = get_world_3d()->get_space();
	for (int k = 0; k < CAPSULES; k++) {
		cap_shape[k] = ps->capsule_shape_create();
		Dictionary d; d["radius"] = 0.24; d["height"] = 1.7;
		ps->shape_set_data(cap_shape[k], d);
		cap_body[k] = ps->body_create();
		ps->body_set_mode(cap_body[k], PhysicsServer3D::BODY_MODE_STATIC);
		ps->body_add_shape(cap_body[k], cap_shape[k]);
		ps->body_set_collision_layer(cap_body[k], 32);
		ps->body_set_collision_mask(cap_body[k], 0);
		ps->body_set_state(cap_body[k], PhysicsServer3D::BODY_STATE_TRANSFORM, Transform3D(Basis(), Vector3(0, -900.0f - k * 4.0f, 0)));
		ps->body_set_space(cap_body[k], space);
		cap_on[k] = false;
	}
	// the murmur: two voices, set where groups stand and talk
	Ref<AudioStreamOggVorbis> og = AudioStreamOggVorbis::load_from_file("res://audio/amb/crowd_murmur.ogg");
	if (og.is_valid()) {
		og->set_loop(true);
		for (int k = 0; k < 2; k++) {
			murmur[k] = memnew(AudioStreamPlayer3D);
			murmur[k]->set_stream(og);
			murmur[k]->set_unit_size(3.0);
			murmur[k]->set_max_distance(22.0);
			murmur[k]->set_volume_db(-9.0);
			add_child(murmur[k]);
		}
	}
	extras = true;
}

void CityCrowd::free_extras() {
	if (!extras) return;
	RenderingServer *rs = RenderingServer::get_singleton();
	PhysicsServer3D *ps = PhysicsServer3D::get_singleton();
	for (int k = 0; k < 2; k++) { if (prop_inst[k].is_valid()) rs->free_rid(prop_inst[k]); if (prop_mm[k].is_valid()) rs->free_rid(prop_mm[k]); prop_inst[k] = RID(); prop_mm[k] = RID(); murmur[k] = nullptr; }
	for (int k = 0; k < CAPSULES; k++) { ps->free_rid(cap_body[k]); ps->free_rid(cap_shape[k]); }
	extras = false;
}

// Every frame: who carries an umbrella, who lies on a towel, where the murmur is.
void CityCrowd::extras_update(double p_alpha) {
	if (!extras) return;
	RenderingServer *rs = RenderingServer::get_singleton();
	float *wu = prop_buf[0].ptrw(), *wt = prop_buf[1].ptrw();
	int nu = 0, ntw = 0;
	const bool wet = rain > 0.5;
	const float alpha = (float)p_alpha;
	Vector3 talk[2]; float talk_d[2] = { 1.0e9f, 1.0e9f };
	Viewport *vp = get_viewport();
	Camera3D *cam = vp ? vp->get_camera_3d() : nullptr;
	const Vector3 ear = cam ? cam->get_global_transform().origin : Vector3();
	for (int i = 0; i < crowd->hi; i++) {
		if (!crowd->alive[i] || (crowd->flags[i] & pc::F_HIDDEN) || crowd->mode[i] == pc::M_BODY) continue;
		const float a = std::min(std::max(((float)(crowd->tick - crowd->tu[i]) + alpha) / (float)std::max((int)crowd->span[i], 1), 0.0f), 1.0f);
		const float x = crowd->px[i] + (crowd->x[i] - crowd->px[i]) * a, y = crowd->py[i] + (crowd->y[i] - crowd->py[i]) * a, z = crowd->pz[i] + (crowd->z[i] - crowd->pz[i]) * a;
		const int act = crowd->act[i];
		const bool down = crowd->mode[i] == pc::M_STAY && (act == pc::A_SIT || act == pc::A_GSIT || act == pc::A_LIE_BACK || act == pc::A_LIE_FRONT || act == pc::A_DRINK || act == pc::A_BEG);
		// two people in five have an umbrella with them when it rains (always the same ones); children walk under their parents'
		if (wet && !down && nu < 512 && (crowd->look[i] >> 24) % 5u < 2u && !(crowd->pkind[i] == pc::PK_FAMILY && crowd->slot[i] >= 2) && crowd->flee_t[i] <= 0.0f)
			put(wu + (size_t)(nu++) * XROW, x, y, z, crowd->yaw[i], 1.0f, UMB[(crowd->look[i] >> 14) % 8u]);
		// who lies on the beach lies on a towel
		if (crowd->mode[i] == pc::M_STAY && (act == pc::A_LIE_BACK || act == pc::A_LIE_FRONT) && ntw < 128) {
			const float yw = crowd->yaw[i] + lie_yaw;
			const float cy = std::cos(crowd->yaw[i]), sy = std::sin(crowd->yaw[i]);
			put(wt + (size_t)(ntw++) * XROW, x + lie_c.x * cy + lie_c.z * sy, y, z - lie_c.x * sy + lie_c.z * cy, yw, 1.0f, TOWEL[(crowd->look[i] >> 16) % 6u]);
		}
		// where a group stands and talks (its leader), the nearest two
		if (crowd->leader[i] == i && crowd->psize[i] >= 2 && (act == pc::A_CHAT || act == pc::A_TALK)) {
			const float d2 = (float)Vector3(x, y, z).distance_squared_to(ear);
			const int k = d2 < talk_d[0] ? 0 : (d2 < talk_d[1] ? 1 : -1);
			if (k == 0) { talk[1] = talk[0]; talk_d[1] = talk_d[0]; }
			if (k >= 0) { talk[k] = Vector3(x, y + 1.5f, z); talk_d[k] = d2; }
		}
	}
	const int counts[2] = { nu, ntw };
	for (int k = 0; k < 2; k++) {
		if (counts[k] > 0) rs->multimesh_set_buffer(prop_mm[k], prop_buf[k]);
		if (counts[k] != prop_shown[k]) { rs->multimesh_set_visible_instances(prop_mm[k], counts[k]); rs->instance_set_visible(prop_inst[k], counts[k] > 0); prop_shown[k] = counts[k]; }
	}
	for (int k = 0; k < 2; k++) {
		if (!murmur[k]) continue;
		const bool on = talk_d[k] < 22.0f * 22.0f;
		if (on) { murmur[k]->set_global_position(talk[k]); if (!murmur[k]->is_playing()) murmur[k]->play((float)(k * 7)); }
		else if (murmur[k]->is_playing()) murmur[k]->stop();
	}
	cnt.umbrellas += nu;
}

// The capsules stand on the people nearest the player (within 8 m): he bumps into them.
void CityCrowd::_physics_process(double p_delta) {
	(void)p_delta;
	if (!extras || !ready) return;
	PhysicsServer3D *ps = PhysicsServer3D::get_singleton();
	int pick[CAPSULES]; float pd[CAPSULES]; int n = 0;
	if (crowd->has_player) {
		for (int i = 0; i < crowd->hi; i++) {
			if (!crowd->alive[i] || (crowd->flags[i] & pc::F_HIDDEN) || crowd->mode[i] == pc::M_BODY) continue;
			const float dx = crowd->x[i] - crowd->pl_x, dz = crowd->z[i] - crowd->pl_z, d2 = dx * dx + dz * dz;
			if (d2 > 64.0f) continue;
			int at = n < CAPSULES ? n++ : -1;
			if (at < 0) { int worst = 0; for (int q = 1; q < CAPSULES; q++) if (pd[q] > pd[worst]) worst = q; if (pd[worst] > d2) at = worst; }
			if (at >= 0) { pick[at] = i; pd[at] = d2; }
		}
	}
	for (int k = 0; k < CAPSULES; k++) {
		if (k < n) {
			const int i = pick[k];
			const bool low = crowd->mode[i] == pc::M_STAY && (crowd->act[i] == pc::A_LIE_BACK || crowd->act[i] == pc::A_LIE_FRONT);
			ps->body_set_state(cap_body[k], PhysicsServer3D::BODY_STATE_TRANSFORM, Transform3D(Basis(), Vector3(crowd->x[i], crowd->y[i] + (low ? -0.5f : 0.85f), crowd->z[i])));
			cap_on[k] = true;
		} else if (cap_on[k]) {
			ps->body_set_state(cap_body[k], PhysicsServer3D::BODY_STATE_TRANSFORM, Transform3D(Basis(), Vector3(0, -900.0f - k * 4.0f, 0)));
			cap_on[k] = false;
		}
	}
}

} // namespace godot
