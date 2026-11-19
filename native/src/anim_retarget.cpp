// AnimRetarget: the tool that fits the Quaternius Universal Animation Library's clips (CC0; its own 65-bone rig, arms
// straight out) to this game's 50-bone figure (the Rocketbox "Bip01" rig, arms down at an angle), all C++.
// For every clip, 30 times a second: where each of the library's bones points in the world, compared with where it
// points at rest, is the turn that bone has made; the same turn is given to our figure's matching bone, starting from
// our figure standing as the library's figure stands at rest (each limb first laid along the library's limb). The hips'
// place is carried over scaled by the two figures' hip heights, so feet stay on the ground and a lying figure lies.
// The result is an ordinary clip library for our skeleton (characters/rocketbox/clips_ual_<kind>.res).
// Run by tools/city/traffic/make_anims.gd; nothing here runs in the game.
#include "anim_retarget.h"

#include <godot_cpp/classes/animation.hpp>
#include <godot_cpp/classes/animation_library.hpp>
#include <godot_cpp/classes/animation_player.hpp>
#include <godot_cpp/classes/gltf_document.hpp>
#include <godot_cpp/classes/gltf_state.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/resource_saver.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <cmath>
#include <vector>

namespace godot {

namespace {

// our bone, the library's bone, our bone further along the same limb (its direction at rest is laid along the library's)
struct BonePair { const char *ours, *theirs, *ours_next, *theirs_next; };
const BonePair PAIRS[] = {
	{ "Bip01_Pelvis", "pelvis", nullptr, nullptr },
	{ "Bip01_Spine", "spine_01", "Bip01_Spine1", "spine_02" }, { "Bip01_Spine1", "spine_02", "Bip01_Spine2", "spine_03" }, { "Bip01_Spine2", "spine_03", "Bip01_Neck", "neck_01" },
	{ "Bip01_Neck", "neck_01", "Bip01_Head", "Head" }, { "Bip01_Head", "Head", nullptr, nullptr },
	{ "Bip01_L_Clavicle", "clavicle_l", "Bip01_L_UpperArm", "upperarm_l" }, { "Bip01_L_UpperArm", "upperarm_l", "Bip01_L_Forearm", "lowerarm_l" },
	{ "Bip01_L_Forearm", "lowerarm_l", "Bip01_L_Hand", "hand_l" }, { "Bip01_L_Hand", "hand_l", "Bip01_L_Finger2", "middle_01_l" },
	{ "Bip01_R_Clavicle", "clavicle_r", "Bip01_R_UpperArm", "upperarm_r" }, { "Bip01_R_UpperArm", "upperarm_r", "Bip01_R_Forearm", "lowerarm_r" },
	{ "Bip01_R_Forearm", "lowerarm_r", "Bip01_R_Hand", "hand_r" }, { "Bip01_R_Hand", "hand_r", "Bip01_R_Finger2", "middle_01_r" },
	{ "Bip01_L_Thigh", "thigh_l", "Bip01_L_Calf", "calf_l" }, { "Bip01_L_Calf", "calf_l", "Bip01_L_Foot", "foot_l" }, { "Bip01_L_Foot", "foot_l", nullptr, nullptr },
	{ "Bip01_R_Thigh", "thigh_r", "Bip01_R_Calf", "calf_r" }, { "Bip01_R_Calf", "calf_r", "Bip01_R_Foot", "foot_r" }, { "Bip01_R_Foot", "foot_r", nullptr, nullptr },
	{ "Bip01_L_Finger0", "thumb_01_l", "Bip01_L_Finger01", "thumb_02_l" }, { "Bip01_L_Finger01", "thumb_02_l", "Bip01_L_Finger02", "thumb_03_l" }, { "Bip01_L_Finger02", "thumb_03_l", nullptr, nullptr },
	{ "Bip01_L_Finger1", "index_01_l", "Bip01_L_Finger11", "index_02_l" }, { "Bip01_L_Finger11", "index_02_l", "Bip01_L_Finger12", "index_03_l" }, { "Bip01_L_Finger12", "index_03_l", nullptr, nullptr },
	{ "Bip01_L_Finger2", "middle_01_l", "Bip01_L_Finger21", "middle_02_l" }, { "Bip01_L_Finger21", "middle_02_l", "Bip01_L_Finger22", "middle_03_l" }, { "Bip01_L_Finger22", "middle_03_l", nullptr, nullptr },
	{ "Bip01_L_Finger3", "ring_01_l", "Bip01_L_Finger31", "ring_02_l" }, { "Bip01_L_Finger31", "ring_02_l", "Bip01_L_Finger32", "ring_03_l" }, { "Bip01_L_Finger32", "ring_03_l", nullptr, nullptr },
	{ "Bip01_L_Finger4", "pinky_01_l", "Bip01_L_Finger41", "pinky_02_l" }, { "Bip01_L_Finger41", "pinky_02_l", "Bip01_L_Finger42", "pinky_03_l" }, { "Bip01_L_Finger42", "pinky_03_l", nullptr, nullptr },
	{ "Bip01_R_Finger0", "thumb_01_r", "Bip01_R_Finger01", "thumb_02_r" }, { "Bip01_R_Finger01", "thumb_02_r", "Bip01_R_Finger02", "thumb_03_r" }, { "Bip01_R_Finger02", "thumb_03_r", nullptr, nullptr },
	{ "Bip01_R_Finger1", "index_01_r", "Bip01_R_Finger11", "index_02_r" }, { "Bip01_R_Finger11", "index_02_r", "Bip01_R_Finger12", "index_03_r" }, { "Bip01_R_Finger12", "index_03_r", nullptr, nullptr },
	{ "Bip01_R_Finger2", "middle_01_r", "Bip01_R_Finger21", "middle_02_r" }, { "Bip01_R_Finger21", "middle_02_r", "Bip01_R_Finger22", "middle_03_r" }, { "Bip01_R_Finger22", "middle_03_r", nullptr, nullptr },
	{ "Bip01_R_Finger3", "ring_01_r", "Bip01_R_Finger31", "ring_02_r" }, { "Bip01_R_Finger31", "ring_02_r", "Bip01_R_Finger32", "ring_03_r" }, { "Bip01_R_Finger32", "ring_03_r", nullptr, nullptr },
	{ "Bip01_R_Finger4", "pinky_01_r", "Bip01_R_Finger41", "pinky_02_r" }, { "Bip01_R_Finger41", "pinky_02_r", "Bip01_R_Finger42", "pinky_03_r" }, { "Bip01_R_Finger42", "pinky_03_r", nullptr, nullptr },
};

// a node's place inside the scene it was made in, from the nodes' own transforms (a tool's nodes have no global one)
Transform3D chain_to(Node *from, Node *root) {
	Transform3D t;
	for (Node *n = from; n; n = n->get_parent()) {
		Node3D *n3 = Object::cast_to<Node3D>(n);
		if (n3) t = n3->get_transform() * t;
		if (n == root) break;
	}
	return t;
}

// the bones' places for a clip at a time, worked out here parent by parent (skeleton space)
void pose_of(Skeleton3D *skel, const Ref<Animation> &a, float t, std::vector<Transform3D> &glob) {
	const int n = skel->get_bone_count();
	std::vector<Vector3> pos(n), scl(n);
	std::vector<Quaternion> rot(n);
	for (int b = 0; b < n; b++) { const Transform3D r = skel->get_bone_rest(b); pos[b] = r.origin; rot[b] = r.basis.get_rotation_quaternion(); scl[b] = r.basis.get_scale(); }
	if (a.is_valid()) {
		for (int ti = 0; ti < a->get_track_count(); ti++) {
			const NodePath path = a->track_get_path(ti);
			if (path.get_subname_count() < 1) continue;
			const int b = skel->find_bone(path.get_subname(0));
			if (b < 0) continue;
			switch (a->track_get_type(ti)) {
				case Animation::TYPE_POSITION_3D: pos[b] = a->position_track_interpolate(ti, t); break;
				case Animation::TYPE_ROTATION_3D: rot[b] = a->rotation_track_interpolate(ti, t); break;
				case Animation::TYPE_SCALE_3D: scl[b] = a->scale_track_interpolate(ti, t); break;
				default: break;
			}
		}
	}
	glob.resize(n);
	for (int b = 0; b < n; b++) {
		const int par = skel->get_bone_parent(b);
		const Transform3D local(Basis(rot[b]).scaled_local(scl[b]), pos[b]);
		glob[b] = (par >= 0 && par < b) ? glob[par] * local : local;
	}
}

inline Quaternion qrot(const Transform3D &t) { return t.basis.orthonormalized().get_rotation_quaternion(); }

} // namespace

PackedStringArray AnimRetarget::retarget(Node *p_parent, const PackedStringArray &p_sources, const String &p_dir) {
	PackedStringArray rep;
	n_clips = 0;
	if (!p_parent) { rep.push_back("ANIMS ERROR no node to work under"); return rep; }
	ResourceLoader *rl = ResourceLoader::get_singleton();
	// ---- the library's figures and their clips
	struct Source { Node3D *scene; Skeleton3D *skel; AnimationPlayer *ap; Transform3D node; std::vector<Transform3D> rest; };
	std::vector<Source> src;
	for (int k = 0; k < p_sources.size(); k++) {
		Ref<GLTFDocument> doc; doc.instantiate();
		Ref<GLTFState> st; st.instantiate();
		if (doc->append_from_file(p_sources[k], st) != OK) { rep.push_back("ANIMS ERROR cannot read " + p_sources[k]); continue; }
		Node3D *scene = Object::cast_to<Node3D>(doc->generate_scene(st));
		if (!scene) { rep.push_back("ANIMS ERROR no scene in " + p_sources[k]); continue; }
		p_parent->add_child(scene);
		const TypedArray<Node> sks = scene->find_children("*", "Skeleton3D", true, false), aps = scene->find_children("*", "AnimationPlayer", true, false);
		if (sks.size() == 0 || aps.size() == 0) { rep.push_back("ANIMS ERROR no skeleton or no clips in " + p_sources[k]); scene->queue_free(); continue; }
		Source s;
		s.scene = scene; s.skel = Object::cast_to<Skeleton3D>(sks[0]); s.ap = Object::cast_to<AnimationPlayer>(aps[0]);
		s.node = chain_to(s.skel, scene);
		pose_of(s.skel, Ref<Animation>(), 0.0f, s.rest);
		src.push_back(s);
	}
	if (src.empty()) return rep;

	for (int g = 0; g < 2; g++) {
		const String gn = g ? "female" : "male";
		Ref<PackedScene> ps = rl->load(p_dir + String("hero_") + gn + String(".scn"));
		Node3D *model = ps.is_valid() ? Object::cast_to<Node3D>(ps->instantiate()) : nullptr;
		if (!model) { rep.push_back("ANIMS ERROR no " + gn + " figure"); continue; }
		p_parent->add_child(model);
		const TypedArray<Node> sks = model->find_children("*", "Skeleton3D", true, false);
		Skeleton3D *tsk = sks.size() ? Object::cast_to<Skeleton3D>(sks[0]) : nullptr;
		if (!tsk) { rep.push_back("ANIMS ERROR no skeleton in the " + gn + " figure"); model->queue_free(); continue; }
		const String track_base = String(model->get_path_to(tsk)) + String(":");
		Transform3D tnode = chain_to(tsk, model);
		std::vector<Transform3D> trest;
		pose_of(tsk, Ref<Animation>(), 0.0f, trest);
		{   // the figure faces +z (as the library's does): turned round if its hand's fingers point the other way
			const int hand = tsk->find_bone("Bip01_L_Hand"), fing = tsk->find_bone("Bip01_L_Finger1");
			if (hand >= 0 && fing >= 0 && ((tnode * trest[fing]).origin.z - (tnode * trest[hand]).origin.z) < 0.0f) tnode = Transform3D(Basis(Vector3(0, 1, 0), 3.14159265f), Vector3()) * tnode;
		}
		const Quaternion tnode_q = qrot(tnode);
		const int nt = tsk->get_bone_count();
		Ref<AnimationLibrary> lib; lib.instantiate();
		int made = 0;
		String names;
		for (Source &S : src) {
			// which of the library's bones each of ours follows, and the turn that lays our limb along its limb at rest
			std::vector<int> follow(nt, -1);
			std::vector<Quaternion> lay(nt, Quaternion());
			for (const BonePair &p : PAIRS) {
				const int tb = tsk->find_bone(p.ours), sb = S.skel->find_bone(p.theirs);
				if (tb < 0 || sb < 0) continue;
				follow[tb] = sb;
				if (!p.ours_next) continue;
				const int tn = tsk->find_bone(p.ours_next), sn = S.skel->find_bone(p.theirs_next);
				if (tn < 0 || sn < 0) continue;
				const Vector3 dt = ((tnode * trest[tn]).origin - (tnode * trest[tb]).origin).normalized(), ds = ((S.node * S.rest[sn]).origin - (S.node * S.rest[sb]).origin).normalized();
				if (dt.length_squared() > 0.5f && ds.length_squared() > 0.5f && dt.dot(ds) > -0.999f) lay[tb] = Quaternion(dt, ds);
			}
			const int t_pel = tsk->find_bone("Bip01_Pelvis"), s_pel = S.skel->find_bone("pelvis");
			if (t_pel < 0 || s_pel < 0) continue;
			const Vector3 tp0 = (tnode * trest[t_pel]).origin, sp0 = (S.node * S.rest[s_pel]).origin;
			const float k_h = sp0.y > 0.1f ? tp0.y / sp0.y : 1.0f;
			std::vector<Quaternion> trest_w(nt), srest_w_inv(S.skel->get_bone_count());
			for (int b = 0; b < nt; b++) trest_w[b] = tnode_q * qrot(trest[b]);
			const Quaternion snode_q = qrot(S.node);
			for (int b = 0; b < S.skel->get_bone_count(); b++) srest_w_inv[b] = (snode_q * qrot(S.rest[b])).inverse();

			const PackedStringArray list = S.ap->get_animation_list();
			for (int ci = 0; ci < list.size(); ci++) {
				const String name = list[ci];
				if (name == "A_TPose" || name == "RESET" || lib->has_animation(name)) continue;
				Ref<Animation> a = S.ap->get_animation(name);
				if (a.is_null()) continue;
				const float len = (float)a->get_length();
				const int frames = std::max((int)std::ceil(len * 30.0f), 1);
				Ref<Animation> o; o.instantiate();
				o->set_length(len);
				o->set_loop_mode(name.ends_with("_Loop") ? Animation::LOOP_LINEAR : Animation::LOOP_NONE);
				std::vector<int> tr(nt, -1);
				for (int b = 0; b < nt; b++) {
					if (follow[b] < 0) continue;
					tr[b] = o->add_track(Animation::TYPE_ROTATION_3D);
					o->track_set_path(tr[b], NodePath(track_base + tsk->get_bone_name(b)));
				}
				const int tr_pos = o->add_track(Animation::TYPE_POSITION_3D);
				o->track_set_path(tr_pos, NodePath(track_base + String("Bip01_Pelvis")));
				std::vector<Transform3D> sg;
				std::vector<Quaternion> tw(nt);
				for (int f = 0; f <= frames; f++) {
					const float t = std::min(len, (float)f / 30.0f);
					pose_of(S.skel, a, t, sg);
					for (int b = 0; b < nt; b++) {
						const int par = tsk->get_bone_parent(b);
						const Quaternion parent_w = (par >= 0 && par < b) ? tw[par] : tnode_q;
						if (follow[b] >= 0) {
							const Quaternion turned = (snode_q * qrot(sg[follow[b]])) * srest_w_inv[follow[b]];   // the turn the library's bone has made in the world
							tw[b] = (turned * lay[b] * trest_w[b]).normalized();
							o->rotation_track_insert_key(tr[b], t, (parent_w.inverse() * tw[b]).normalized());
						} else tw[b] = (parent_w * tsk->get_bone_rest(b).basis.get_rotation_quaternion()).normalized();
					}
					const Vector3 sp = (S.node * sg[s_pel]).origin;
					const Vector3 tp = tp0 + (sp - sp0) * k_h;
					o->position_track_insert_key(tr_pos, t, tnode.affine_inverse().xform(tp));
				}
				lib->add_animation(name, o);
				names += name + String(" ");
				made++;
			}
		}
		const String out = p_dir + String("clips_ual_") + gn + String(".res");
		const Error err = ResourceSaver::get_singleton()->save(lib, out, ResourceSaver::FLAG_COMPRESS);
		rep.push_back(vformat("ANIMS %s figure: %d clips fitted and saved to %s (%s)", gn, made, out, err == OK ? "ok" : "NOT SAVED"));
		if (g == 0) rep.push_back("ANIMS clips: " + names);
		n_clips += made;
		model->queue_free();
	}
	for (Source &S : src) S.scene->queue_free();
	return rep;
}

void AnimRetarget::_bind_methods() {
	ClassDB::bind_method(D_METHOD("retarget", "parent", "sources", "rocketbox_dir"), &AnimRetarget::retarget);
	ClassDB::bind_method(D_METHOD("count"), &AnimRetarget::count);
}

} // namespace godot
