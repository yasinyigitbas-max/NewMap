// MoLimbs: see mo_limbs.h.
#include "mo_limbs.h"

#include <godot_cpp/classes/engine.hpp>
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
	// (time moves once a frame: the skeleton can be posed more than once in one)
	const uint64_t fr = Engine::get_singleton()->get_process_frames();
	if (p_delta > 0.0) dt_frame = (float)p_delta;
	const float dt = fr != frame_id ? dt_frame : 0.0f;
	frame_id = fr;
	const Transform3D G = sk->get_global_transform(), Gi = G.affine_inverse();
	// THE GROUND: where the clip has each foot, fitted to the ground under it (fit_off, from the motor's rays: the ground
	// there against the figure's own floor, weighted by how near the clip has the foot to its floor). The HIPS DROP
	// when a fitted foot is lower than the clip's (downhill, a step down): the leg could not reach it straight
	Vector3 raw[2], fit[2];
	float need = 0.0f;
	for (int s = 0; s < 2; s++) {
		if (b_ft[s] < 0) continue;
		raw[s] = G.xform(sk->get_bone_global_pose(b_ft[s]).origin);
		fit[s] = raw[s] + Vector3(0, (lock_on && fit_on) ? fit_off[s] : 0.0f, 0);
		if (!lock_on || !fit_on) continue;
		need = std::max(need, (float)(raw[s].y - fit[s].y));
		if (locked[s]) need = std::max(need, (float)(raw[s].y - lock_w[s].y));
	}
	need = std::max(0.0f, std::min(need - drop_slack, drop_max));
	// (on a critically damped spring, down quicker than back up: eased by a rate, the hips' rise jumped 4-5 cm a frame at
	// every stair, the ease starting at full speed)
	if (dt > 0.0f) {
		const float w = need > drop ? drop_down : drop_up;
		drop_v += (w * w * (need - drop) - 2.0f * w * drop_v) * dt;
		drop += drop_v * dt;
		if (drop < 0.0f) { drop = 0.0f; drop_v = std::max(drop_v, 0.0f); }
	}
	if (b_root < 0) { b_root = b_ft[0] >= 0 ? b_ft[0] : -1; while (b_root >= 0 && sk->get_bone_parent(b_root) >= 0) b_root = sk->get_bone_parent(b_root); }
	if (b_root >= 0 && drop > 1e-4f) sk->set_bone_pose_position(b_root, sk->get_bone_pose_position(b_root) + Gi.basis.xform(Vector3(0, -drop, 0)));
	for (int s = 0; s < 2; s++) {
		pull[s] = 0.0f; pull_v[s] = Vector3();
		if (b_th[s] < 0 || b_ca[s] < 0 || b_ft[s] < 0) continue;
		const Vector3 anim_w = fit[s];   // the clip's foot, on the ground here
		const Vector3 drawn = raw[s] - Vector3(0, drop, 0);
		if (!lock_on) { locked[s] = false; rel_t[s] = 9.0f; step_t[s] = -1.0f; held[s] = 0.0f; continue; }
		Vector3 want_w;
		bool have = false;
		// a re-plant step under way: from the old pin to where the clip has the foot, in an arc, then pinned there
		if (step_t[s] >= 0.0f) {
			if (!down[s] || !may_step) {   // (the clip lifts it, or he moves off: the step's offset fades like a release)
				const float u = std::min(step_t[s] / step_s, 1.0f), e = u * u * (3.0f - 2.0f * u);
				rel_off[s] = step_from[s].lerp(anim_w, e) + Vector3(0, step_h * std::sin(3.14159265f * u), 0) - anim_w;
				rel_t[s] = 0.0f; step_t[s] = -1.0f; locked[s] = false;
			} else {
				step_t[s] += dt;
				const float u = std::min(step_t[s] / step_s, 1.0f), e = u * u * (3.0f - 2.0f * u);
				want_w = step_from[s].lerp(anim_w, e) + Vector3(0, step_h * std::sin(3.14159265f * u), 0);
				if (u >= 1.0f) { step_t[s] = -1.0f; locked[s] = true; lock_w[s] = anim_w; held[s] = 0.0f; want_w = anim_w; }
				pull[s] = (float)(want_w - anim_w).length();
				have = true;
			}
		}
		if (!have) {
			if (down[s]) {
				// (pinned only near the ground: the clip's foot near its floor; a hand-over can hold a foot up)
				if (!locked[s]) { if ((float)raw[s].y - ground_y < pin_h) { locked[s] = true; lock_w[s] = anim_w; rel_t[s] = 9.0f; lock_t[s] = 0.0f; locks++; } }
				else if ((lock_w[s] - anim_w).length() > max_pull) {
					// (standing: a step there, not a snap - a stop into the idle moved the clip's foot 27 cm in 0.1 s)
					if (may_step && down[1 - s] && step_t[1 - s] < 0.0f) { step_t[s] = 0.0f; step_from[s] = lock_w[s]; steps++; }
					else { locked[s] = false; rel_off[s] = Vector3(); rel_t[s] = 9.0f; }
				}
			} else if (locked[s]) {   // the clip lifts it: the pin lets go, its offset fading
				locked[s] = false; rel_off[s] = lock_w[s] - anim_w; rel_t[s] = 0.0f;
			}
			// held off the clip's place while standing, both feet down, the other not stepping: a re-plant step
			if (locked[s] && may_step && down[0] && down[1] && step_t[1 - s] < 0.0f && (lock_w[s] - anim_w).length() > step_pull) {
				held[s] += dt;
				if ((held[s] >= step_after && held[s] >= held[1 - s]) || (lock_w[s] - anim_w).length() > step_now) { step_t[s] = 0.0f; step_from[s] = lock_w[s]; steps++; }   // (held on its pin this frame; it lifts from the next)
			} else held[s] = 0.0f;
			// (a pin's HEIGHT is the clip's own contact height on this ground, eased onto over 0.1 s: taken from the pose
			// as drawn, a foot pinned during a hand-over stood 3 cm up for its whole contact)
			if (locked[s] && fit_on && lock_t[s] < 9.0f) {
				lock_t[s] += dt;
				const float u = std::min(lock_t[s] / 0.1f, 1.0f);
				lock_w[s].y += (fit_y[s] - (float)lock_w[s].y) * (u * u * (3.0f - 2.0f * u));
				if (u >= 1.0f) { lock_w[s].y = fit_y[s]; lock_t[s] = 9.0f; }
			}
			if (locked[s]) { want_w = lock_w[s]; if (step_t[s] >= 0.0f) locked[s] = false; }
			else if (rel_t[s] < release_s) {
				rel_t[s] += dt;
				const float u = std::min(rel_t[s] / release_s, 1.0f), f = 1.0f - u * u * (3.0f - 2.0f * u);
				want_w = anim_w + rel_off[s] * std::max(f, 0.0f);
			} else want_w = anim_w;
			pull[s] = (float)(want_w - anim_w).length();
			if (locked[s]) pull_v[s] = want_w - anim_w;
		}
		if ((want_w - drawn).length() < 1e-4f) continue;
		// the knee toward where the clip has it (its own bend), a little forward of the line hip-foot
		const Vector3 hip = sk->get_bone_global_pose(b_th[s]).origin, knee = sk->get_bone_global_pose(b_ca[s]).origin;
		reach(sk, b_th[s], b_ca[s], b_ft[s], Gi.xform(want_w), knee - hip);
		// the sole turned onto the ground's slope while the clip has the foot down (at most 30 degrees)
		if (fit_on && fit_w[s] > 0.01f && ground_n[s].y > 0.5f) {
			Vector3 n = ground_n[s];
			const float ang = (float)std::acos(std::min(1.0f, (float)n.y));
			if (ang > 0.52f) n = Vector3(0, 1, 0).slerp(n, 0.52f / ang);
			const Vector3 up_s = Gi.basis.xform(Vector3(0, 1, 0)).normalized(), n_s = Gi.basis.xform(n).normalized();
			const Quaternion q = Quaternion().slerp(Quaternion(up_s, n_s), std::min(fit_w[s], 1.0f));
			const Transform3D F = sk->get_bone_global_pose(b_ft[s]);
			sk->set_bone_global_pose(b_ft[s], Transform3D(Basis(q) * F.basis, F.origin));
		}
	}
	for (int s = 0; s < 2; s++) {
		if (hand_w[s] <= 0.001f || b_ua[s] < 0 || b_fa[s] < 0 || b_hd[s] < 0) continue;
		const Vector3 wr = sk->get_bone_global_pose(b_hd[s]).origin;
		const Vector3 tgt = wr.lerp(Gi.xform(hand_target[s]), std::min(hand_w[s], 1.0f));
		const Vector3 sh = sk->get_bone_global_pose(b_ua[s]).origin, el = sk->get_bone_global_pose(b_fa[s]).origin;
		reach(sk, b_ua[s], b_fa[s], b_hd[s], tgt, el - sh);
	}
}
