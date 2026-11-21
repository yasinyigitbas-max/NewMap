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
#include <godot_cpp/classes/fbx_document.hpp>
#include <godot_cpp/classes/fbx_state.hpp>
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

// MIXAMO (Yasin, 21 Nov: "okay go for mixamo"): the same pairs for Mixamo's rig (its bones are "mixamorig:Hips" ..., found
// by the part after the prefix). Its arms are a T at rest like the Quaternius figure's; each limb is laid along it.
const BonePair PAIRS_MX[] = {
	{ "Bip01_Pelvis", "Hips", nullptr, nullptr },
	{ "Bip01_Spine", "Spine", "Bip01_Spine1", "Spine1" }, { "Bip01_Spine1", "Spine1", "Bip01_Spine2", "Spine2" }, { "Bip01_Spine2", "Spine2", "Bip01_Neck", "Neck" },
	{ "Bip01_Neck", "Neck", "Bip01_Head", "Head" }, { "Bip01_Head", "Head", nullptr, nullptr },
	{ "Bip01_L_Clavicle", "LeftShoulder", "Bip01_L_UpperArm", "LeftArm" }, { "Bip01_L_UpperArm", "LeftArm", "Bip01_L_Forearm", "LeftForeArm" },
	{ "Bip01_L_Forearm", "LeftForeArm", "Bip01_L_Hand", "LeftHand" }, { "Bip01_L_Hand", "LeftHand", "Bip01_L_Finger2", "LeftHandMiddle1" },
	{ "Bip01_R_Clavicle", "RightShoulder", "Bip01_R_UpperArm", "RightArm" }, { "Bip01_R_UpperArm", "RightArm", "Bip01_R_Forearm", "RightForeArm" },
	{ "Bip01_R_Forearm", "RightForeArm", "Bip01_R_Hand", "RightHand" }, { "Bip01_R_Hand", "RightHand", "Bip01_R_Finger2", "RightHandMiddle1" },
	{ "Bip01_L_Thigh", "LeftUpLeg", "Bip01_L_Calf", "LeftLeg" }, { "Bip01_L_Calf", "LeftLeg", "Bip01_L_Foot", "LeftFoot" }, { "Bip01_L_Foot", "LeftFoot", nullptr, nullptr },
	{ "Bip01_R_Thigh", "RightUpLeg", "Bip01_R_Calf", "RightLeg" }, { "Bip01_R_Calf", "RightLeg", "Bip01_R_Foot", "RightFoot" }, { "Bip01_R_Foot", "RightFoot", nullptr, nullptr },
	{ "Bip01_L_Finger0", "LeftHandThumb1", "Bip01_L_Finger01", "LeftHandThumb2" }, { "Bip01_L_Finger01", "LeftHandThumb2", "Bip01_L_Finger02", "LeftHandThumb3" }, { "Bip01_L_Finger02", "LeftHandThumb3", nullptr, nullptr },
	{ "Bip01_L_Finger1", "LeftHandIndex1", "Bip01_L_Finger11", "LeftHandIndex2" }, { "Bip01_L_Finger11", "LeftHandIndex2", "Bip01_L_Finger12", "LeftHandIndex3" }, { "Bip01_L_Finger12", "LeftHandIndex3", nullptr, nullptr },
	{ "Bip01_L_Finger2", "LeftHandMiddle1", "Bip01_L_Finger21", "LeftHandMiddle2" }, { "Bip01_L_Finger21", "LeftHandMiddle2", "Bip01_L_Finger22", "LeftHandMiddle3" }, { "Bip01_L_Finger22", "LeftHandMiddle3", nullptr, nullptr },
	{ "Bip01_L_Finger3", "LeftHandRing1", "Bip01_L_Finger31", "LeftHandRing2" }, { "Bip01_L_Finger31", "LeftHandRing2", "Bip01_L_Finger32", "LeftHandRing3" }, { "Bip01_L_Finger32", "LeftHandRing3", nullptr, nullptr },
	{ "Bip01_L_Finger4", "LeftHandPinky1", "Bip01_L_Finger41", "LeftHandPinky2" }, { "Bip01_L_Finger41", "LeftHandPinky2", "Bip01_L_Finger42", "LeftHandPinky3" }, { "Bip01_L_Finger42", "LeftHandPinky3", nullptr, nullptr },
	{ "Bip01_R_Finger0", "RightHandThumb1", "Bip01_R_Finger01", "RightHandThumb2" }, { "Bip01_R_Finger01", "RightHandThumb2", "Bip01_R_Finger02", "RightHandThumb3" }, { "Bip01_R_Finger02", "RightHandThumb3", nullptr, nullptr },
	{ "Bip01_R_Finger1", "RightHandIndex1", "Bip01_R_Finger11", "RightHandIndex2" }, { "Bip01_R_Finger11", "RightHandIndex2", "Bip01_R_Finger12", "RightHandIndex3" }, { "Bip01_R_Finger12", "RightHandIndex3", nullptr, nullptr },
	{ "Bip01_R_Finger2", "RightHandMiddle1", "Bip01_R_Finger21", "RightHandMiddle2" }, { "Bip01_R_Finger21", "RightHandMiddle2", "Bip01_R_Finger22", "RightHandMiddle3" }, { "Bip01_R_Finger22", "RightHandMiddle3", nullptr, nullptr },
	{ "Bip01_R_Finger3", "RightHandRing1", "Bip01_R_Finger31", "RightHandRing2" }, { "Bip01_R_Finger31", "RightHandRing2", "Bip01_R_Finger32", "RightHandRing3" }, { "Bip01_R_Finger32", "RightHandRing3", nullptr, nullptr },
	{ "Bip01_R_Finger4", "RightHandPinky1", "Bip01_R_Finger41", "RightHandPinky2" }, { "Bip01_R_Finger41", "RightHandPinky2", "Bip01_R_Finger42", "RightHandPinky3" }, { "Bip01_R_Finger42", "RightHandPinky3", nullptr, nullptr },
};

// a source bone by name: as it is, or after a rig prefix ("mixamorig:Hips", "mixamorig_Hips", "mixamorig1:Hips")
int find_src(Skeleton3D *sk, const char *p_name) {
	const String nm(p_name);
	const int b = sk->find_bone(nm);
	if (b >= 0) return b;
	for (int i = 0; i < sk->get_bone_count(); i++) {
		const String s = sk->get_bone_name(i);
		const int c = std::max(s.rfind(":"), s.rfind("_"));
		if (c >= 0 && s.substr(c + 1) == nm && s.to_lower().begins_with("mixamorig")) return i;
	}
	return -1;
}

// a clip's loop: a walk, a run or an idle loops; a start, a stop, a turn plays once
bool mx_loops(const String &n) {
	const String l = n.to_lower();
	if (l.contains("start") || l.contains("stop") || l.contains("turn") || l.contains(" to ") || l.contains("_to_") || l.contains("jump") || l.contains("climb") || l.contains("stairs")) return l.contains("stairs") && !l.contains("start");
	return l.contains("walk") || l.contains("run") || l.contains("jog") || l.contains("idle") || l.contains("sprint") || l.contains("sneak") || l.ends_with("_loop");
}


// THE CLIP'S OWN MOTION (Mixamo, the Animator 21 Nov): the game moves and turns the bodies itself, so a clip that walks
// off or turns round would carry the figure away from its body and snap back. Measured, written down, taken out:
//  - meta "yaw": the hips' turn about the vertical, per 1/30 s (radians, + to the left), and "done_at" (the turn is 97 %
//    done): a turning clip (its name says turn, over 20 degrees) has it taken out (the body turns by it instead)
//  - meta "vz", "vx": the travel per 1/30 s in the body's own frame (m/s, forward and to its left) and "pace" (= vz: the
//    step code moves the body at native pace x pace)
//  - a loop: its straight drift taken out (an "in place" one has none) and meta "ground_v" (m/s: the drift, or the
//    planted foot's own pace) and "left_down" (the share of the loop where the left foot is furthest forward: the
//    stride's phase, for handing one loop to the next in step); a walking start, stop or turn: its travel taken out
//    (its sway kept); anything else keeps its travel (a fall, a dive, a stumble shows where it goes)
//  - meta "tpose": the share of frames the arms are held straight out (a download in its T pose, not a clip)
static float wrap_pi(float a) { while (a > 3.14159265f) a -= 6.2831853f; while (a < -3.14159265f) a += 6.2831853f; return a; }
void mx_motion(Ref<Animation> &o, const String &name, const std::vector<Vector3> &hip, const std::vector<Vector3> &lf, const std::vector<Vector3> &rf,
		const std::vector<Quaternion> &pq, int tr_pos, int tr_pel, int t_pel, Skeleton3D *tsk, const Transform3D &tnode, const Quaternion &tnode_q, float tpose, PackedStringArray &rep) {
	const int n = (int)hip.size();
	const float dt = 1.0f / 30.0f;
	const String l = name.to_lower();
	const bool loop = o->get_loop_mode() != Animation::LOOP_NONE;
	// the turn: the hips' forward, turned from the first frame's
	std::vector<float> yaw(n, 0.0f);
	for (int f = 1; f < n; f++) {
		const Vector3 v = (pq[f] * pq[0].inverse()).xform(Vector3(0, 0, 1));
		yaw[f] = yaw[f - 1] + wrap_pi(std::atan2(v.x, v.z) - yaw[f - 1]);
	}
	const bool turn = l.contains("turn") && std::fabs(yaw[n - 1]) > 0.35f;
	// (a fight's steps and a jump too: the game moves the body through them)
	const bool locomotion = loop || l.contains("start") || l.contains("stop") || l.contains("turn") || l.contains("to_run") || l.contains("to_stop") || l.contains("step") || l.contains("jump") && !l.contains("climb") && !l.contains("hang");
	// the path: a loop's straight drift, or (a locomotion move) the hips smoothed over half a second
	std::vector<Vector3> path(n);
	if (loop) { const Vector3 d = hip[n - 1] - hip[0]; for (int f = 0; f < n; f++) path[f] = hip[0] + Vector3(d.x, 0, d.z) * ((float)f / (float)(n - 1)); }
	else {
		const int w = 7;
		for (int f = 0; f < n; f++) {
			Vector3 acc; int c = 0;
			for (int k = std::max(0, f - w); k <= std::min(n - 1, f + w); k++) { acc += hip[k]; c++; }
			path[f] = acc / (float)c; path[f].y = hip[0].y;
		}
		path[0] = Vector3(hip[0].x, hip[0].y, hip[0].z); path[n - 1] = Vector3(hip[n - 1].x, hip[0].y, hip[n - 1].z);
		for (int f = 1; f < n - 1; f++) if (f <= 7 || f >= n - 8) { const float u = f <= 7 ? (float)f / 8.0f : (float)(n - 1 - f) / 8.0f; const Vector3 e = f <= 7 ? hip[0] : hip[n - 1]; path[f] = Vector3(e.x, hip[0].y, e.z).lerp(path[f], u); }
	}
	PackedFloat32Array vz, vx, yw;
	vz.resize(n); vx.resize(n); yw.resize(n);
	for (int f = 0; f < n; f++) {
		const int a = std::max(0, f - 1), b = std::min(n - 1, f + 1);
		const Vector3 v = (path[b] - path[a]) / (dt * (float)std::max(b - a, 1));
		const float c = std::cos(yaw[f]), sn = std::sin(yaw[f]);   // into the body's own frame (it faced +z at the start)
		vz[f] = v.z * c + v.x * sn; vx[f] = v.x * c - v.z * sn; yw[f] = yaw[f];
	}
	o->set_meta("vz", vz); o->set_meta("vx", vx); o->set_meta("pace", vz); o->set_meta("yaw", yw);
	o->set_meta("travel", Vector3(path[n - 1].x - path[0].x, 0, path[n - 1].z - path[0].z));
	o->set_meta("tpose", tpose);
	{ int k = n - 1; const float y_end = yaw[n - 1]; for (int f = 0; f < n; f++) if (std::fabs(yaw[f]) >= 0.97f * std::fabs(y_end)) { k = f; break; } o->set_meta("done_at", (float)k * dt); }
	// the stride (a loop): the left foot furthest forward, and its own pace
	if (loop) {
		int best = 0; float most = -1e9f;
		for (int f = 0; f < n - 1; f++) { const float z = lf[f].z - hip[f].z; if (z > most) { most = z; best = f; } }
		o->set_meta("left_down", (float)best / (float)(n - 1));
		const float drift = Vector2(hip[n - 1].x - hip[0].x, hip[n - 1].z - hip[0].z).length() / ((float)(n - 1) * dt);
		float gv = drift;
		if (drift < 0.15f) {   // in place: how fast the lower foot goes back under the body
			float sum = 0.0f; int c = 0;
			for (int f = 1; f < n; f++) { const bool left = lf[f].y < rf[f].y; const Vector3 &p1 = left ? lf[f] : rf[f], &p0 = left ? lf[f - 1] : rf[f - 1]; if (((left ? lf : rf)[f].y - std::min(lf[f].y, rf[f].y)) < 0.01f) { sum += -(p1.z - p0.z) / dt; c++; } }
			gv = c ? std::max(sum / (float)c, 0.0f) : 0.0f;
		}
		o->set_meta("ground_v", gv);
	}
	// taken out: the travel (a loop's drift, a locomotion move's path), the turn (a turning clip)
	if (!locomotion && !turn) { if (tpose > 0.5f) rep.push_back(vformat("ANIMS T-POSE %s (%.0f %% of its frames: a download without its motion?)", name, tpose * 100.0f)); return; }
	const Transform3D inv = tnode.affine_inverse();
	for (int f = 0; f < n; f++) {
		const float t = std::min((float)o->get_length(), (float)f * dt);
		Vector3 h = hip[f];
		const Vector3 off = Vector3(h.x - path[f].x, 0, h.z - path[f].z);   // (the sway round the path)
		const Quaternion un = turn ? Quaternion(Vector3(0, 1, 0), -yaw[f]) : Quaternion();
		const Vector3 o2 = un.xform(off);
		h = Vector3(hip[0].x + o2.x, h.y, hip[0].z + o2.z);
		o->track_set_key_value(tr_pos, f, inv.xform(h));
		if (turn && tr_pel >= 0) {
			const int par = tsk->get_bone_parent(t_pel);
			(void)par;
			const Quaternion lq = o->track_get_key_value(tr_pel, f);
			// the pelvis's own key is under its parent (not moved by the clip): turning the world turn back turns the key
			Quaternion pw = tnode_q;   // (the pelvis's parents carry no clip turn: their rest turns, root first)
			{ std::vector<int> chain; for (int q = par; q >= 0; q = tsk->get_bone_parent(q)) chain.push_back(q); for (int k = (int)chain.size() - 1; k >= 0; k--) pw = pw * tsk->get_bone_rest(chain[k]).basis.get_rotation_quaternion(); }
			o->track_set_key_value(tr_pel, f, (pw.inverse() * un * pw * lq).normalized());
		}
		(void)t;
	}
	if (tpose > 0.5f) rep.push_back(vformat("ANIMS T-POSE %s (%.0f %% of its frames)", name, tpose * 100.0f));
}

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
	struct Source { Node3D *scene; Skeleton3D *skel; AnimationPlayer *ap; Transform3D node; std::vector<Transform3D> rest; String file; };
	std::vector<Source> src;
	for (int k = 0; k < p_sources.size(); k++) {
		const bool fbx = p_sources[k].to_lower().ends_with(".fbx");   // (Mixamo's downloads)
		Ref<GLTFDocument> doc; Ref<GLTFState> st;
		if (fbx) { Ref<FBXDocument> fd; fd.instantiate(); doc = fd; Ref<FBXState> fs; fs.instantiate(); st = fs; }
		else { doc.instantiate(); st.instantiate(); }
		if (doc->append_from_file(p_sources[k], st) != OK) { rep.push_back("ANIMS ERROR cannot read " + p_sources[k]); continue; }
		Node3D *scene = Object::cast_to<Node3D>(doc->generate_scene(st));
		if (!scene) { rep.push_back("ANIMS ERROR no scene in " + p_sources[k]); continue; }
		p_parent->add_child(scene);
		const TypedArray<Node> sks = scene->find_children("*", "Skeleton3D", true, false), aps = scene->find_children("*", "AnimationPlayer", true, false);
		if (sks.size() == 0 || aps.size() == 0) { rep.push_back("ANIMS ERROR no skeleton or no clips in " + p_sources[k]); scene->queue_free(); continue; }
		Source s;
		s.scene = scene; s.skel = Object::cast_to<Skeleton3D>(sks[0]); s.ap = Object::cast_to<AnimationPlayer>(aps[0]);
		s.node = chain_to(s.skel, scene);
		s.file = p_sources[k].get_file().get_basename().replace(" ", "_");
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
			const BonePair *pairs = mixamo ? PAIRS_MX : PAIRS;
			const int n_pairs = mixamo ? (int)(sizeof(PAIRS_MX) / sizeof(PAIRS_MX[0])) : (int)(sizeof(PAIRS) / sizeof(PAIRS[0]));
			for (int pi = 0; pi < n_pairs; pi++) {
				const BonePair &p = pairs[pi];
				const int tb = tsk->find_bone(p.ours), sb = find_src(S.skel, p.theirs);
				if (tb < 0 || sb < 0) continue;
				follow[tb] = sb;
				if (!p.ours_next) continue;
				const int tn = tsk->find_bone(p.ours_next), sn = find_src(S.skel, p.theirs_next);
				if (tn < 0 || sn < 0) continue;
				const Vector3 dt = ((tnode * trest[tn]).origin - (tnode * trest[tb]).origin).normalized(), ds = ((S.node * S.rest[sn]).origin - (S.node * S.rest[sb]).origin).normalized();
				if (dt.length_squared() > 0.5f && ds.length_squared() > 0.5f && dt.dot(ds) > -0.999f) lay[tb] = Quaternion(dt, ds);
			}
			const int t_pel = tsk->find_bone("Bip01_Pelvis"), s_pel = find_src(S.skel, mixamo ? "Hips" : "pelvis");
			if (t_pel < 0 || s_pel < 0) continue;
			const Vector3 tp0 = (tnode * trest[t_pel]).origin, sp0 = (S.node * S.rest[s_pel]).origin;
			const float k_h = sp0.y > 0.1f ? tp0.y / sp0.y : 1.0f;
			std::vector<Quaternion> trest_w(nt), srest_w_inv(S.skel->get_bone_count());
			for (int b = 0; b < nt; b++) trest_w[b] = tnode_q * qrot(trest[b]);
			const Quaternion snode_q = qrot(S.node);
			for (int b = 0; b < S.skel->get_bone_count(); b++) srest_w_inv[b] = (snode_q * qrot(S.rest[b])).inverse();

			const PackedStringArray list = S.ap->get_animation_list();
			for (int ci = 0; ci < list.size(); ci++) {
				if (list[ci] == "A_TPose" || list[ci] == "RESET") continue;
				// (a Mixamo file holds one clip, "mixamo.com": it is named after the file)
				const String name = mixamo ? (list.size() == 1 || list[ci] == "mixamo.com" ? S.file : S.file + String("_") + list[ci]) : String(list[ci]);
				if (lib->has_animation(name)) continue;
				{ bool out_ = false; for (int q = 0; q < skip.size(); q++) if (name.contains(skip[q])) out_ = true; if (out_) { n_skipped++; continue; } }
				Ref<Animation> a = S.ap->get_animation(list[ci]);
				if (a.is_null()) continue;
				const float len = (float)a->get_length();
				const int frames = std::max((int)std::ceil(len * 30.0f), 1);
				Ref<Animation> o; o.instantiate();
				o->set_length(len);
				o->set_loop_mode((mixamo ? mx_loops(name) : name.ends_with("_Loop")) ? Animation::LOOP_LINEAR : Animation::LOOP_NONE);
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
				// (Mixamo) per frame: the hips' place and turn, the feet, the hands against the shoulders (for the motion's
				// own travel and turn, the stride, and a broken download held in its T)
				std::vector<Vector3> m_hip, m_lf, m_rf; std::vector<Quaternion> m_pq; int m_t = 0;
				const int s_lf = mixamo ? find_src(S.skel, "LeftFoot") : -1, s_rf = mixamo ? find_src(S.skel, "RightFoot") : -1;
				const int s_lh = mixamo ? find_src(S.skel, "LeftHand") : -1, s_rh = mixamo ? find_src(S.skel, "RightHand") : -1;
				const int s_la = mixamo ? find_src(S.skel, "LeftArm") : -1, s_ra = mixamo ? find_src(S.skel, "RightArm") : -1;
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
					if (mixamo && s_lf >= 0 && s_rf >= 0) {
						m_hip.push_back(tp); m_pq.push_back(tw[t_pel]);
						m_lf.push_back(tp0 + ((S.node * sg[s_lf]).origin - sp0) * k_h); m_rf.push_back(tp0 + ((S.node * sg[s_rf]).origin - sp0) * k_h);
						if (s_lh >= 0 && s_rh >= 0 && s_la >= 0 && s_ra >= 0) {
							const Vector3 lh = (S.node * sg[s_lh]).origin, rh = (S.node * sg[s_rh]).origin, la = (S.node * sg[s_la]).origin, ra = (S.node * sg[s_ra]).origin;
							const float hgt = std::max(sp0.y, 0.1f) * 2.0f;
							if (std::fabs(lh.y - la.y) < 0.08f * hgt && std::fabs(rh.y - ra.y) < 0.08f * hgt && (lh - rh).length() > 0.75f * hgt) m_t++;
						}
					}
				}
				if (mixamo && m_hip.size() > 2) mx_motion(o, name, m_hip, m_lf, m_rf, m_pq, tr_pos, tr[t_pel], t_pel, tsk, tnode, tnode_q, (float)m_t / (float)m_hip.size(), rep);
				lib->add_animation(name, o);
				names += name + String(" ");
				made++;
			}
		}
		// the mixed clips: every track of the base, but the arms', the neck's and the head's from the top clip, stretched
		// over a whole number of rounds of the base (three rounds of the walk under one phone call)
		for (int li = 0; li < layers.size(); li++) {
			const Array L = layers[li];
			if (L.size() < 3) continue;
			const StringName nm = String(L[0]), bn = String(L[1]), tn = String(L[2]);
			if (lib->has_animation(nm) || !lib->has_animation(bn) || !lib->has_animation(tn)) continue;
			const Ref<Animation> base = lib->get_animation(bn), top = lib->get_animation(tn);
			const float bl = std::max((float)base->get_length(), 0.05f), tl = std::max((float)top->get_length(), 0.05f);
			const int rounds = std::max(1, (int)std::lround(tl / bl));
			const float len = bl * (float)rounds;
			const int frames = std::max((int)std::ceil(len * 30.0f), 1);
			Ref<Animation> o; o.instantiate();
			o->set_length(len); o->set_loop_mode(Animation::LOOP_LINEAR);
			static const char *const UPPER[] = { "Neck", "Head", "Clavicle", "UpperArm", "Forearm", "Hand", "Finger" };
			for (int ti = 0; ti < base->get_track_count(); ti++) {
				const NodePath path = base->track_get_path(ti);
				const Animation::TrackType ty = base->track_get_type(ti);
				int from_top = -1;
				if (ty == Animation::TYPE_ROTATION_3D) {
					const String ps = String(path);
					bool upper = false;
					for (const char *u : UPPER) if (ps.contains(u)) upper = true;
					if (upper) from_top = top->find_track(path, ty);
				}
				const int nt_ = o->add_track(ty);
				o->track_set_path(nt_, path);
				for (int f = 0; f <= frames; f++) {
					const float t = std::min(len, (float)f / 30.0f);
					const float tb = f == frames ? 0.0f : std::fmod(t, bl);
					if (ty == Animation::TYPE_ROTATION_3D) o->rotation_track_insert_key(nt_, t, from_top >= 0 ? top->rotation_track_interpolate(from_top, std::min(t * tl / len, tl)) : base->rotation_track_interpolate(ti, tb));
					else if (ty == Animation::TYPE_POSITION_3D) o->position_track_insert_key(nt_, t, base->position_track_interpolate(ti, tb));
				}
			}
			lib->add_animation(nm, o);
			if (g == 0) names += String(nm) + String(" ");
			n_layered++;
		}
		const String out = p_dir + out_prefix + gn + String(".res");
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
	ClassDB::bind_method(D_METHOD("set_skip", "names"), &AnimRetarget::set_skip);
	ClassDB::bind_method(D_METHOD("get_skip"), &AnimRetarget::get_skip);
	ClassDB::bind_method(D_METHOD("skipped"), &AnimRetarget::skipped);
	ClassDB::bind_method(D_METHOD("set_layers", "layers"), &AnimRetarget::set_layers);
	ClassDB::bind_method(D_METHOD("layered"), &AnimRetarget::layered);
	ClassDB::bind_method(D_METHOD("set_rig", "rig"), &AnimRetarget::set_rig);
	ClassDB::bind_method(D_METHOD("set_out_prefix", "prefix"), &AnimRetarget::set_out_prefix);
}

} // namespace godot
