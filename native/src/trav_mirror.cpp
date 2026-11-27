#ifdef TRAV_IN_GAME
#include "trav_mirror.h"
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/skeleton_modifier3d.hpp>
#include <cmath>

using namespace godot;

// ---------------------------------------------------------------------------------------------- the pose copy
// The old figure (Rocketbox bones) goes on playing every act, not drawn; its pose is put on the new body's skeleton
// (the mixamo bones) bone by bone: how far each old bone is turned from its rest, in the figure's own frame, turns the
// new bone from ITS rest, once that rest has been turned to face as the old one does (F) and its bone to point as the
// old bone points at rest (A: the old bodies rest with their arms lower than the new ones). The hips are set where the
// old hips are, by the share of the two bodies' hip heights.
static const char *const MAP[][2] = {
	{ "Hips", "Pelvis" }, { "Spine", "Spine" }, { "Spine1", "Spine1" }, { "Spine2", "Spine2" }, { "Neck", "Neck" }, { "Head", "Head" },
	{ "LeftShoulder", "L_Clavicle" }, { "LeftArm", "L_UpperArm" }, { "LeftForeArm", "L_Forearm" }, { "LeftHand", "L_Hand" },
	{ "RightShoulder", "R_Clavicle" }, { "RightArm", "R_UpperArm" }, { "RightForeArm", "R_Forearm" }, { "RightHand", "R_Hand" },
	{ "LeftUpLeg", "L_Thigh" }, { "LeftLeg", "L_Calf" }, { "LeftFoot", "L_Foot" }, { "RightUpLeg", "R_Thigh" }, { "RightLeg", "R_Calf" }, { "RightFoot", "R_Foot" },
	{ "LeftHandThumb1", "L_Finger0" }, { "LeftHandThumb2", "L_Finger01" }, { "LeftHandThumb3", "L_Finger02" },
	{ "LeftHandIndex1", "L_Finger1" }, { "LeftHandIndex2", "L_Finger11" }, { "LeftHandIndex3", "L_Finger12" },
	{ "LeftHandMiddle1", "L_Finger2" }, { "LeftHandMiddle2", "L_Finger21" }, { "LeftHandMiddle3", "L_Finger22" },
	{ "LeftHandRing1", "L_Finger3" }, { "LeftHandRing2", "L_Finger31" }, { "LeftHandRing3", "L_Finger32" },
	{ "LeftHandPinky1", "L_Finger4" }, { "LeftHandPinky2", "L_Finger41" }, { "LeftHandPinky3", "L_Finger42" },
	{ "RightHandThumb1", "R_Finger0" }, { "RightHandThumb2", "R_Finger01" }, { "RightHandThumb3", "R_Finger02" },
	{ "RightHandIndex1", "R_Finger1" }, { "RightHandIndex2", "R_Finger11" }, { "RightHandIndex3", "R_Finger12" },
	{ "RightHandMiddle1", "R_Finger2" }, { "RightHandMiddle2", "R_Finger21" }, { "RightHandMiddle3", "R_Finger22" },
	{ "RightHandRing1", "R_Finger3" }, { "RightHandRing2", "R_Finger31" }, { "RightHandRing3", "R_Finger32" },
	{ "RightHandPinky1", "R_Finger4" }, { "RightHandPinky2", "R_Finger41" }, { "RightHandPinky3", "R_Finger42" },
};
// which bone a bone points at, at rest (new names); none: the two rests are only turned to face alike
static const char *const POINTS[][2] = {
	{ "Hips", "Spine" }, { "Spine", "Spine1" }, { "Spine1", "Spine2" }, { "Spine2", "Neck" }, { "Neck", "Head" },
	{ "LeftShoulder", "LeftArm" }, { "LeftArm", "LeftForeArm" }, { "LeftForeArm", "LeftHand" }, { "LeftHand", "LeftHandMiddle1" },
	{ "RightShoulder", "RightArm" }, { "RightArm", "RightForeArm" }, { "RightForeArm", "RightHand" }, { "RightHand", "RightHandMiddle1" },
	{ "LeftUpLeg", "LeftLeg" }, { "LeftLeg", "LeftFoot" }, { "RightUpLeg", "RightLeg" }, { "RightLeg", "RightFoot" },
};

static int new_bone(Skeleton3D *sk, const char *n) {
	int b = sk->find_bone(String("mixamorig_") + n);
	if (b < 0) b = sk->find_bone(String("mixamorig:") + n);
	return b;
}

bool TravMirror::map(Node3D *p_body, Node3D *p_old, Skeleton3D *p_os) {
	if (map_ok) return true;
	Node *ch = p_body->get_node_or_null("Character");
	Skeleton3D *nsk = ch ? Object::cast_to<Skeleton3D>((Object *)ch->get("skel")) : nullptr;
	Skeleton3D *os = p_os;
	if (!nsk || !os || !nsk->is_inside_tree() || !os->is_inside_tree()) return false;
	sk = nsk;
	const int nn = sk->get_bone_count();
	// both rests in their figure's own frame (the node the crowd moves; the body)
	const Basis on = (p_body->get_global_transform().affine_inverse() * sk->get_global_transform()).basis.orthonormalized();
	const Transform3D mo = p_old->get_global_transform().affine_inverse() * os->get_global_transform();
	const Basis oo = mo.basis.orthonormalized();
	const int nl = new_bone(sk, "LeftUpLeg"), nr = new_bone(sk, "RightUpLeg"), nh = new_bone(sk, "Hips");
	const int ol = os->find_bone("Bip01_L_Thigh"), orr = os->find_bone("Bip01_R_Thigh"), oh = os->find_bone("Bip01_Pelvis");
	if (nl < 0 || nr < 0 || nh < 0 || ol < 0 || orr < 0 || oh < 0) return false;
	Vector3 ln = on.xform(sk->get_bone_global_rest(nl).origin - sk->get_bone_global_rest(nr).origin);
	Vector3 lo = oo.xform(os->get_bone_global_rest(ol).origin - os->get_bone_global_rest(orr).origin);
	ln.y = 0; lo.y = 0;
	if (ln.length() < 1e-5f || lo.length() < 1e-5f) return false;
	const Basis F(Vector3(0, 1, 0), std::atan2(lo.x, lo.z) - std::atan2(ln.x, ln.z));   // the new rest turned to face as the old one
	m_old.assign((size_t)nn, -1); m_fix.assign((size_t)nn, Basis()); m_old_rest_inv.assign((size_t)nn, Basis());
	for (const auto &m : MAP) {
		const int b = new_bone(sk, m[0]), o = os->find_bone(String("Bip01_") + m[1]);
		if (b < 0 || o < 0) continue;
		const Basis rn = F * on * sk->get_bone_global_rest(b).basis.orthonormalized();
		const Basis ro = oo * os->get_bone_global_rest(o).basis.orthonormalized();
		Basis A;
		for (const auto &pt : POINTS) {
			if (String(pt[0]) != String(m[0])) continue;
			const int bc = new_bone(sk, pt[1]);
			int oc = -1;
			for (const auto &m2 : MAP) if (String(m2[0]) == String(pt[1])) oc = os->find_bone(String("Bip01_") + m2[1]);
			if (bc < 0 || oc < 0) break;
			const Vector3 dn = (F * on).xform(sk->get_bone_global_rest(bc).origin - sk->get_bone_global_rest(b).origin).normalized();
			const Vector3 dd = oo.xform(os->get_bone_global_rest(oc).origin - os->get_bone_global_rest(o).origin).normalized();
			if (dn.length() > 0.5f && dd.length() > 0.5f && dn.dot(dd) < 0.99999f && dn.dot(dd) > -0.999f) A = Basis(Quaternion(dn, dd));
			break;
		}
		m_old[(size_t)b] = o; m_fix[(size_t)b] = A * rn; m_old_rest_inv[(size_t)b] = ro.inverse();
	}
	const float hn = on.xform(sk->get_bone_global_rest(nh).origin).y * (p_body->get_global_transform().affine_inverse() * sk->get_global_transform()).basis.get_scale().y;
	const float ho = mo.xform(os->get_bone_global_rest(oh).origin).y;
	m_scale = ho > 0.2f && hn > 0.2f ? hn / ho : 1.0f;
	map_ok = true;
	return true;
}

bool TravMirror::set(Node3D *p_body, Node3D *p_old, Skeleton3D *p_os, bool p_on) {
	if (p_on && !map(p_body, p_old, p_os)) p_on = false;
	if (on != p_on) {
		on = p_on;
		p_body->set_process_mode(p_on ? Node::PROCESS_MODE_DISABLED : Node::PROCESS_MODE_INHERIT);
		if (sk) {
			const TypedArray<Node> kids = sk->get_children();
			for (int c = 0; c < kids.size(); c++) {
				if (SkeletonModifier3D *md = Object::cast_to<SkeletonModifier3D>((Object *)kids[c])) md->set_active(!p_on);
				// (a thing in his hand, his phone: not while his pose is another figure's; their owners show them again)
				else if (p_on && !Object::cast_to<MeshInstance3D>((Object *)kids[c])) { if (Node3D *thing = Object::cast_to<Node3D>((Object *)kids[c])) thing->set_visible(false); }
			}
			if (!p_on) sk->reset_bone_poses();
		}
	}
	if (!p_on) return false;
	Skeleton3D *os = p_os;
	Transform3D at = p_old->get_global_transform();
	at.basis = at.basis.orthonormalized();
	p_body->set_global_transform(at);
	const Transform3D mn = at.affine_inverse() * sk->get_global_transform();
	const Basis on_inv = mn.basis.orthonormalized().inverse();
	const Transform3D mo = p_old->get_global_transform().affine_inverse() * os->get_global_transform();
	const Basis oo = mo.basis.orthonormalized();
	const int nn = sk->get_bone_count();
	static thread_local std::vector<Basis> g;      // each new bone's turn in the skeleton's frame, as set this frame
	g.assign((size_t)nn, Basis());
	std::vector<char> done((size_t)nn, 0);
	// (a parent before its children, whatever the order of the bones: the new bodies' root is their last bone)
	for (int pass = 0; pass < 8; pass++) {
		bool all = true;
		for (int b = 0; b < nn; b++) {
			if (done[(size_t)b]) continue;
			const int par = sk->get_bone_parent(b);
			if (par >= 0 && !done[(size_t)par]) { all = false; continue; }
			const Basis gp = par >= 0 ? g[(size_t)par] : Basis();
			const int o = m_old[(size_t)b];
			if (o < 0) { g[(size_t)b] = gp * sk->get_bone_rest(b).basis.orthonormalized(); sk->set_bone_pose_rotation(b, sk->get_bone_rest(b).basis.get_rotation_quaternion()); done[(size_t)b] = 1; continue; }
			const Basis go = oo * os->get_bone_global_pose(o).basis.orthonormalized();
			const Basis gn = on_inv * (go * m_old_rest_inv[(size_t)b] * m_fix[(size_t)b]);
			g[(size_t)b] = gn;
			sk->set_bone_pose_rotation(b, (gp.inverse() * gn).orthonormalized().get_rotation_quaternion());
			done[(size_t)b] = 1;
		}
		if (all) break;
	}
	const int nh = new_bone(sk, "Hips"), oh = os->find_bone("Bip01_Pelvis");
	if (nh >= 0 && oh >= 0) {
		const Vector3 p = mo.xform(os->get_bone_global_pose(oh).origin) * m_scale;      // in the figure's frame, at the new body's size
		const int par = sk->get_bone_parent(nh);
		const Transform3D pg = par >= 0 ? sk->get_bone_global_pose(par) : Transform3D();
		sk->set_bone_pose_position(nh, (mn * pg).affine_inverse().xform(p));
	}
	return true;
}

#endif
