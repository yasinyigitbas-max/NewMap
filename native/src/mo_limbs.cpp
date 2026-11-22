// MoLimbs: see mo_limbs.h.
#include "mo_limbs.h"

#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/variant/quaternion.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

namespace {
// the turn taking direction a onto direction b
Basis arc(const Vector3 &a, const Vector3 &b) {
	const Vector3 u = a.normalized(), v = b.normalized();
	const Vector3 c = u.cross(v);
	const float d = (float)u.dot(v);
	if (c.length_squared() < 1e-12f) return d > 0.0f ? Basis() : Basis(Vector3(1, 0, 0).cross(u).length_squared() > 1e-6f ? Vector3(1, 0, 0).cross(u).normalized() : Vector3(0, 1, 0), 3.14159265f);
	return Basis(Quaternion(u, v));
}
} // namespace

void MoLimbs::find_bones(Skeleton3D *sk) {
	const char *TH[2] = { "Bip01_L_Thigh", "Bip01_R_Thigh" }, *CA[2] = { "Bip01_L_Calf", "Bip01_R_Calf" }, *FT[2] = { "Bip01_L_Foot", "Bip01_R_Foot" };
	const char *UA[2] = { "Bip01_L_UpperArm", "Bip01_R_UpperArm" }, *FA[2] = { "Bip01_L_Forearm", "Bip01_R_Forearm" }, *HD[2] = { "Bip01_L_Hand", "Bip01_R_Hand" };
	for (int s = 0; s < 2; s++) {
		b_th[s] = sk->find_bone(TH[s]); b_ca[s] = sk->find_bone(CA[s]); b_ft[s] = sk->find_bone(FT[s]);
		b_ua[s] = sk->find_bone(UA[s]); b_fa[s] = sk->find_bone(FA[s]); b_hd[s] = sk->find_bone(HD[s]);
	}
	found = true;
}

void MoLimbs::reach(Skeleton3D *sk, int a, int b, int c, const Vector3 &p_target, const Vector3 &p_pole) {
	if (a < 0 || b < 0 || c < 0) return;
	const Transform3D Ga = sk->get_bone_global_pose(a), Gb = sk->get_bone_global_pose(b), Gc = sk->get_bone_global_pose(c);
	const Vector3 pa = Ga.origin, pb = Gb.origin, pc = Gc.origin;
	const float la = (float)(pb - pa).length(), lb = (float)(pc - pb).length();
	if (la < 1e-4f || lb < 1e-4f) return;
	const Vector3 tv = p_target - pa;
	const float d = std::min(std::max((float)tv.length(), std::fabs(la - lb) + 1e-3f), la + lb - 1e-3f);
	const Vector3 u = tv.normalized();
	Vector3 v = p_pole - u * p_pole.dot(u);
	if (v.length_squared() < 1e-10f) v = (pb - pa) - u * (pb - pa).dot(u);
	if (v.length_squared() < 1e-10f) return;
	v.normalize();
	const float ca = std::min(std::max((la * la + d * d - lb * lb) / (2.0f * la * d), -1.0f), 1.0f);
	const Vector3 knee = pa + (u * ca + v * std::sqrt(std::max(0.0f, 1.0f - ca * ca))) * la;
	sk->set_bone_global_pose(a, Transform3D(arc(pb - pa, knee - pa) * Ga.basis, pa));
	const Transform3D Gb2 = sk->get_bone_global_pose(b), Gc2 = sk->get_bone_global_pose(c);
	sk->set_bone_global_pose(b, Transform3D(arc(Gc2.origin - Gb2.origin, pa + u * d - Gb2.origin) * Gb2.basis, Gb2.origin));
	const Transform3D Gc3 = sk->get_bone_global_pose(c);
	sk->set_bone_global_pose(c, Transform3D(Gc.basis, Gc3.origin));   // (the foot / hand keeps the clip's own turn)
}

void MoLimbs::_process_modification_with_delta(double p_delta) {
	Skeleton3D *sk = get_skeleton();
	if (!sk) return;
	if (!found) find_bones(sk);
	const float dt = (float)p_delta;
	const Transform3D G = sk->get_global_transform(), Gi = G.affine_inverse();
	for (int s = 0; s < 2; s++) {
		pull[s] = 0.0f;
		if (b_th[s] < 0 || b_ca[s] < 0 || b_ft[s] < 0) continue;
		const Vector3 anim_w = G.xform(sk->get_bone_global_pose(b_ft[s]).origin);
		if (!lock_on) { locked[s] = false; rel_t[s] = 9.0f; continue; }
		if (down[s]) {
			if (!locked[s]) { if ((float)anim_w.y - ground_y < pin_h) { locked[s] = true; lock_w[s] = anim_w; rel_t[s] = 9.0f; locks++; } }
			else if ((lock_w[s] - anim_w).length() > max_pull) { locked[s] = false; rel_off[s] = Vector3(); rel_t[s] = 9.0f; }
		} else if (locked[s]) {   // the clip lifts it: the pin lets go, its offset fading
			locked[s] = false; rel_off[s] = lock_w[s] - anim_w; rel_t[s] = 0.0f;
		}
		Vector3 want_w;
		if (locked[s]) want_w = lock_w[s];
		else if (rel_t[s] < release_s) {
			rel_t[s] += dt;
			const float u = std::min(rel_t[s] / release_s, 1.0f), f = 1.0f - u * u * (3.0f - 2.0f * u);
			if (f <= 0.0f) continue;
			want_w = anim_w + rel_off[s] * f;
		} else continue;
		pull[s] = (float)(want_w - anim_w).length();
		if (pull[s] < 1e-4f) continue;
		// the knee toward where the clip has it (its own bend), a little forward of the line hip-foot
		const Vector3 hip = sk->get_bone_global_pose(b_th[s]).origin, knee = sk->get_bone_global_pose(b_ca[s]).origin;
		reach(sk, b_th[s], b_ca[s], b_ft[s], Gi.xform(want_w), knee - hip);
	}
	for (int s = 0; s < 2; s++) {
		if (hand_w[s] <= 0.001f || b_ua[s] < 0 || b_fa[s] < 0 || b_hd[s] < 0) continue;
		const Vector3 wr = sk->get_bone_global_pose(b_hd[s]).origin;
		const Vector3 tgt = wr.lerp(Gi.xform(hand_target[s]), std::min(hand_w[s], 1.0f));
		const Vector3 sh = sk->get_bone_global_pose(b_ua[s]).origin, el = sk->get_bone_global_pose(b_fa[s]).origin;
		reach(sk, b_ua[s], b_fa[s], b_hd[s], tgt, el - sh);
	}
}
