// PeopleBake: the tool that poses the far figures, all C++. Every body of characters/rocketbox (its light "_far" mesh)
// is put into 12 poses once (8 steps of the walk, standing, sitting, lying on the back, lying on the front) with the
// figure's own skeleton and clips, and the corners of all of them are written into ONE table (far_poses.bin) that the
// people's shader reads (rb_person.gdshader, far_merged): so the whole far crowd is one draw, and nothing is posed or
// read back while the game runs. Run by tools/city/traffic/make_people.gd; nothing here runs in the game.
#include "people_bake.h"

#include <godot_cpp/classes/animation.hpp>
#include <godot_cpp/classes/animation_library.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/classes/skin.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <vector>

namespace godot {

namespace {

uint16_t half_of(float f) {   // a float as 16 bits (enough for a body's corners: a tenth of a millimetre at 2 m)
	uint32_t x; std::memcpy(&x, &f, 4);
	const uint32_t sign = (x >> 16) & 0x8000u;
	int e = (int)((x >> 23) & 0xFFu) - 127 + 15;
	uint32_t m = x & 0x7FFFFFu;
	if (e <= 0) { if (e < -10) return (uint16_t)sign; m = (m | 0x800000u) >> (1 - e); return (uint16_t)(sign | ((m + 0x1000u) >> 13)); }
	if (e >= 31) return (uint16_t)(sign | 0x7C00u);
	return (uint16_t)(sign | ((uint32_t)e << 10) | ((m + 0x1000u) >> 13));
}

struct Donor {
	String id;
	int layer = 0, female = 0, corners = 0;
	float height = 1.7f, foot = 0.0f;
	std::vector<float> data;   // per pose: corners * 3 positions, corners * 3 normals; then corners * 3 (u, v, layer)
};

} // namespace

PackedStringArray PeopleBake::bake(Node *p_parent, const String &p_dir, const String &p_out) {
	PackedStringArray rep;
	if (!p_parent) { rep.push_back("PEOPLE ERROR no node to work under"); return rep; }
	ResourceLoader *rl = ResourceLoader::get_singleton();
	const Variant mv = JSON::parse_string(FileAccess::get_file_as_string(p_dir + String("rb_meta.json")));
	if (mv.get_type() != Variant::DICTIONARY) { rep.push_back("PEOPLE ERROR no rb_meta.json"); return rep; }
	const Dictionary donors = ((Dictionary)mv).get("donors", Dictionary());
	const Array ids = donors.keys();
	std::vector<Donor> out;
	static const char *const POSE_CLIP[POSES] = { "walk", "walk", "walk", "walk", "walk", "walk", "walk", "walk", "idle", "sit_idle", "sleep", "sleep" };
	float stride_m[2] = { 1.4f, 1.3f };
	for (int g = 0; g < 2; g++) {
		const String gn = g ? "female" : "male";
		Ref<PackedScene> ps = rl->load(p_dir + String("hero_") + gn + String(".scn"));
		Ref<Skin> skin = rl->load(p_dir + String("skin_") + gn + String(".res"));
		Ref<AnimationLibrary> lib = rl->load(p_dir + String("clips_") + gn + String(".res"));
		if (ps.is_null() || skin.is_null() || lib.is_null()) { rep.push_back("PEOPLE ERROR the " + gn + " figure is not whole (scene, skin, clips)"); return rep; }
		Node3D *model = Object::cast_to<Node3D>(ps->instantiate());
		if (!model) continue;
		p_parent->add_child(model);
		const TypedArray<Node> sks = model->find_children("*", "Skeleton3D", true, false);
		Skeleton3D *skel = sks.size() ? Object::cast_to<Skeleton3D>(sks[0]) : nullptr;
		if (!skel) { rep.push_back("PEOPLE ERROR no skeleton in the " + gn + " scene"); model->queue_free(); return rep; }
		// A clip's pose at a time, set on the skeleton bone by bone from the clip's own tracks (an animation player does
		// not run in a tool that draws nothing: the first table had everybody standing with their arms out).
		// (the bones' places are then worked out here, parent by parent: a skeleton that is not in a drawn tree keeps
		// handing back its rest pose)
		const int n_bones = skel->get_bone_count();
		std::vector<Transform3D> glob(n_bones);
		auto pose_at = [&](const StringName &clip, float t) {
			skel->reset_bone_poses();
			if (!lib->has_animation(clip)) { for (int b = 0; b < n_bones; b++) glob[b] = skel->get_bone_global_rest(b); return; }
			Ref<Animation> a = lib->get_animation(clip);
			for (int ti = 0; ti < a->get_track_count(); ti++) {
				const NodePath path = a->track_get_path(ti);
				if (path.get_subname_count() < 1) continue;
				const int b = skel->find_bone(path.get_subname(0));
				if (b < 0) continue;
				switch (a->track_get_type(ti)) {
					case Animation::TYPE_POSITION_3D: skel->set_bone_pose_position(b, a->position_track_interpolate(ti, t)); break;
					case Animation::TYPE_ROTATION_3D: skel->set_bone_pose_rotation(b, a->rotation_track_interpolate(ti, t)); break;
					case Animation::TYPE_SCALE_3D: skel->set_bone_pose_scale(b, a->scale_track_interpolate(ti, t)); break;
					default: break;
				}
			}
			for (int b = 0; b < n_bones; b++) {
				const int par = skel->get_bone_parent(b);
				const Transform3D local(Basis(skel->get_bone_pose_rotation(b)).scaled_local(skel->get_bone_pose_scale(b)), skel->get_bone_pose_position(b));
				glob[b] = (par >= 0 && par < b) ? glob[par] * local : local;
			}
		};
		// the figure faces +z with its feet at the origin (as CityPed sets it up): turned round if it faces the other way
		const int hand = skel->find_bone("Bip01_L_Hand"), fing = skel->find_bone("Bip01_L_Finger1");
		// (the skeleton inside the model, from the nodes' own transforms: the tool's nodes are not drawn, they have no global one)
		Transform3D to_model = model->get_transform();
		{
			Transform3D chain;
			for (Node *n = skel; n && n != model; n = n->get_parent()) { Node3D *n3 = Object::cast_to<Node3D>(n); if (n3) chain = n3->get_transform() * chain; }
			to_model = to_model * chain;
		}
		Transform3D face;
		if (hand >= 0 && fing >= 0 && ((to_model * skel->get_bone_global_rest(fing)).origin.z - (to_model * skel->get_bone_global_rest(hand)).origin.z) < 0.0f) face = Transform3D(Basis(Vector3(0, 1, 0), 3.14159265f), Vector3());
		// the bones' places in every pose
		const int nb = skin->get_bind_count();
		std::vector<int> bind_bone(nb, -1);
		for (int b = 0; b < nb; b++) {
			int k = skin->get_bind_bone(b);
			const String nm = skin->get_bind_name(b);
			if (!nm.is_empty()) k = skel->find_bone(nm);
			bind_bone[b] = k;
		}
		std::vector<std::vector<Transform3D>> pose_m(POSES, std::vector<Transform3D>(nb));
		for (int p = 0; p < POSES; p++) {
			const StringName clip(POSE_CLIP[p]);
			float t = 0.0f;
			if (lib->has_animation(clip)) {
				Ref<Animation> a = lib->get_animation(clip);
				const float len = (float)a->get_length();
				t = p < 8 ? len * (float)p / 8.0f : (p == 8 ? std::min(0.5f, len) : (p == 9 ? std::min(1.0f, len * 0.5f) : 0.0f));
			}
			pose_at(clip, t);
			for (int b = 0; b < nb; b++) {
				const int k = bind_bone[b];
				pose_m[p][b] = k >= 0 ? face * to_model * glob[k] * skin->get_bind_pose(b) : Transform3D();
			}
		}
		// how long a step of the walk clip is: the feet's swing fore and aft over the clip
		{
			const int lf = skel->find_bone("Bip01_L_Foot");
			if (lf >= 0 && lib->has_animation("walk")) {
				float lo = 1e9f, hi = -1e9f;
				Ref<Animation> a = lib->get_animation("walk");
				for (int k = 0; k < 16; k++) {
					pose_at("walk", (float)a->get_length() * (float)k / 16.0f);
					const float fz = (face * to_model * glob[lf]).origin.z;
					lo = std::min(lo, fz); hi = std::max(hi, fz);
				}
				if (hi - lo > 0.2f) stride_m[g] = (hi - lo) * 2.0f;
			}
		}
		// every body of this kind
		for (int di = 0; di < ids.size(); di++) {
			const String id = ids[di];
			const Dictionary dn = donors[id];
			const bool fem = String(dn.get("g", "men")) == "women";
			if (fem != (g == 1)) continue;
			Ref<Mesh> mesh = rl->load(p_dir + String("bodies/") + id + String("_far.res"));
			if (mesh.is_null() || mesh->get_surface_count() < 1) { rep.push_back("PEOPLE no far mesh for " + id + ": left out"); continue; }
			const Array arr = mesh->surface_get_arrays(0);
			const PackedVector3Array V = arr[Mesh::ARRAY_VERTEX], N = arr[Mesh::ARRAY_NORMAL];
			const PackedVector2Array UV = arr[Mesh::ARRAY_TEX_UV];
			const PackedInt32Array BN = arr[Mesh::ARRAY_BONES], IX = arr[Mesh::ARRAY_INDEX];
			const PackedFloat32Array WT = arr[Mesh::ARRAY_WEIGHTS];
			const int nv = (int)V.size();
			if (nv == 0 || BN.size() < nv * 4 || WT.size() < nv * 4 || N.size() < nv || UV.size() < nv) { rep.push_back("PEOPLE the far mesh of " + id + " has no bones or no normals: left out"); continue; }
			const int per = (int)BN.size() / nv;
			Donor D;
			D.id = id; D.female = g; D.layer = (int)(double)dn.get("layer", 0.0);
			D.corners = IX.size() > 0 ? (int)IX.size() : nv;
			D.data.resize((size_t)D.corners * 3 * (2 * POSES + 1));
			float top = 0.0f;
			for (int p = 0; p < POSES; p++) {
				float *PO = &D.data[(size_t)p * 2 * D.corners * 3], *NO = PO + (size_t)D.corners * 3;
				float ymin = 1e9f;
				Vector3 lo(1e9f, 1e9f, 1e9f), hi(-1e9f, -1e9f, -1e9f);
				for (int c = 0; c < D.corners; c++) {
					const int vi = IX.size() > 0 ? IX[c] : c;
					Vector3 sp, sn;
					for (int k = 0; k < per; k++) {
						const float w = WT[vi * per + k];
						const int b = BN[vi * per + k];
						if (w <= 0.0f || b < 0 || b >= nb) continue;
						sp += pose_m[p][b].xform(V[vi]) * w;
						sn += pose_m[p][b].basis.xform(N[vi]) * w;
					}
					sn = sn.length_squared() > 1e-12f ? sn.normalized() : Vector3(0, 1, 0);
					PO[c * 3] = sp.x; PO[c * 3 + 1] = sp.y; PO[c * 3 + 2] = sp.z;
					NO[c * 3] = sn.x; NO[c * 3 + 1] = sn.y; NO[c * 3 + 2] = sn.z;
					ymin = std::min(ymin, sp.y); lo = lo.min(sp); hi = hi.max(sp);
				}
				if (p == 8) { top = hi.y; D.foot = lo.y; }
				if (p == 11) {   // lying on the front: the lying figure turned over about its own length, laid back on the ground
					const bool along_x = hi.x - lo.x > hi.z - lo.z;
					const float cy = 0.5f * (lo.y + hi.y), cq = along_x ? 0.5f * (lo.z + hi.z) : 0.5f * (lo.x + hi.x);
					for (int c = 0; c < D.corners; c++) {
						float &q = along_x ? PO[c * 3 + 2] : PO[c * 3];
						float &nq = along_x ? NO[c * 3 + 2] : NO[c * 3];
						q = 2.0f * cq - q; PO[c * 3 + 1] = 2.0f * cy - PO[c * 3 + 1];
						nq = -nq; NO[c * 3 + 1] = -NO[c * 3 + 1];
					}
				}
				if (p >= 10) {   // lying: on the ground, whatever height the clip's bed has
					float m = 1e9f;
					for (int c = 0; c < D.corners; c++) m = std::min(m, PO[c * 3 + 1]);
					for (int c = 0; c < D.corners; c++) PO[c * 3 + 1] -= m - 0.02f;
				}
				(void)ymin;
			}
			D.height = top;
			float *UO = &D.data[(size_t)POSES * 2 * D.corners * 3];
			for (int c = 0; c < D.corners; c++) {
				const int vi = IX.size() > 0 ? IX[c] : c;
				UO[c * 3] = UV[vi].x; UO[c * 3 + 1] = UV[vi].y; UO[c * 3 + 2] = (float)D.layer;
			}
			out.push_back(D);
		}
		model->queue_free();
	}
	if (out.empty()) { rep.push_back("PEOPLE ERROR no body could be posed"); return rep; }
	// ---- the table: W wide; per body a block of (2 * POSES + 1) * corner_h rows (per pose its corners' places, then their normals; last their UVs and texture layer)
	int most = 0, tris = 0;
	for (const Donor &D : out) { most = std::max(most, D.corners); tris += D.corners / 3; }
	const int W = 512, corner_h = (most + W - 1) / W, block_rows = (2 * POSES + 1) * corner_h, H = block_rows * (int)out.size();
	std::vector<uint16_t> px((size_t)W * H * 4, 0);
	for (size_t d = 0; d < out.size(); d++) {
		const Donor &D = out[d];
		for (int blk = 0; blk < 2 * POSES + 1; blk++) {
			const float *src = &D.data[(size_t)blk * D.corners * 3];
			for (int c = 0; c < corner_h * W; c++) {
				uint16_t *o = &px[((size_t)(d * block_rows + blk * corner_h) * W + c) * 4];
				if (c < D.corners) { o[0] = half_of(src[c * 3]); o[1] = half_of(src[c * 3 + 1]); o[2] = half_of(src[c * 3 + 2]); o[3] = half_of(1.0f); }
				// (corners past a body's own count stay at 0, 0, 0: triangles of no size)
			}
		}
	}
	Ref<FileAccess> f = FileAccess::open_compressed(p_out, FileAccess::WRITE, FileAccess::COMPRESSION_ZSTD);
	if (f.is_null()) { rep.push_back("PEOPLE ERROR cannot write " + p_out); return rep; }
	f->store_32(0x31525046u);   // "FPR1"
	f->store_32((uint32_t)W); f->store_32((uint32_t)H); f->store_32((uint32_t)corner_h); f->store_32((uint32_t)POSES); f->store_32((uint32_t)out.size()); f->store_32((uint32_t)(corner_h * W));
	f->store_float(stride_m[0]); f->store_float(stride_m[1]);
	for (const Donor &D : out) { f->store_pascal_string(D.id); f->store_32((uint32_t)D.layer); f->store_32((uint32_t)D.female); f->store_32((uint32_t)D.corners); f->store_float(D.height); }
	PackedByteArray bytes; bytes.resize((int64_t)px.size() * 2);
	std::memcpy(bytes.ptrw(), px.data(), px.size() * 2);
	f->store_buffer(bytes);
	f->close();
	n_bodies = (int)out.size();
	rep.push_back(vformat("PEOPLE posed %d bodies in %d poses: %d triangles a body on average, the most corners %d; table %d x %d (%d rows a body), %.1f MB as it is used; a step of the walk: men %.2f m, women %.2f m",
			(int)out.size(), (int)POSES, tris / (int)out.size(), most, W, H, block_rows, (double)px.size() * 2.0 / 1048576.0, stride_m[0], stride_m[1]));
	String hs = "PEOPLE standing heights (m):";
	float foot_lo = 1e9f, foot_hi = -1e9f;
	for (const Donor &D : out) { hs += vformat(" %s %.2f", D.id, D.height); foot_lo = std::min(foot_lo, D.foot); foot_hi = std::max(foot_hi, D.foot); }
	hs += vformat(" | their soles standing: %.3f to %.3f m over the figure's origin", foot_lo, foot_hi);
	rep.push_back(hs);
	return rep;
}

void PeopleBake::_bind_methods() {
	ClassDB::bind_method(D_METHOD("bake", "parent", "rocketbox_dir", "out_path"), &PeopleBake::bake);
	ClassDB::bind_method(D_METHOD("count"), &PeopleBake::count);
}

} // namespace godot
