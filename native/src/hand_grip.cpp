// HandGrip: see hand_grip.h.
#include "hand_grip.h"

#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/world3d.hpp>

#include <algorithm>
#include <cmath>

namespace godot {

namespace {
inline Basis arc(Vector3 a, Vector3 b) {
	if (a.length_squared() < 1e-10f || b.length_squared() < 1e-10f) return Basis();
	a.normalize(); b.normalize();
	const Vector3 ax = a.cross(b);
	const float sn = ax.length(), cs = a.dot(b);
	if (sn < 1e-6f) return cs > 0.0f ? Basis() : Basis(std::fabs(a.x) < 0.9f ? Vector3(1, 0, 0).cross(a).normalized() : Vector3(0, 1, 0).cross(a).normalized(), 3.14159265f);
	return Basis(ax / sn, std::atan2(sn, cs));
}
}

void HandGrip::find_bones(Skeleton3D *sk) {
	found = true;
	const char *ua[2] = { "Bip01_L_UpperArm", "Bip01_R_UpperArm" }, *fa[2] = { "Bip01_L_Forearm", "Bip01_R_Forearm" }, *hd[2] = { "Bip01_L_Hand", "Bip01_R_Hand" };
	for (int s = 0; s < 2; s++) {
		b_ua[s] = sk->find_bone(ua[s]); b_fa[s] = sk->find_bone(fa[s]); b_hd[s] = sk->find_bone(hd[s]);
		n_fing[s] = 0;
		// the four fingers' joints, base to tip (the thumb is left as the clip has it)
		for (int f = 1; f <= 4; f++) for (int j = 0; j < 3; j++) {
			const String nm = String(s == 0 ? "Bip01_L_Finger" : "Bip01_R_Finger") + String::num_int64(f) + (j == 0 ? String() : String::num_int64(j));
			const int b = sk->find_bone(nm);
			if (b >= 0 && n_fing[s] < 15) b_fing[s][n_fing[s]++] = b;
		}
	}
}

void HandGrip::reach(Skeleton3D *sk, int a, int b, int c, const Vector3 &target, const Vector3 &pole) {
	if (a < 0 || b < 0 || c < 0) return;
	const Transform3D Ga = sk->get_bone_global_pose(a), Gb = sk->get_bone_global_pose(b), Gc = sk->get_bone_global_pose(c);
	const Vector3 pa = Ga.origin, pb = Gb.origin, pc = Gc.origin;
	const float la = (pb - pa).length(), lb = (pc - pb).length();
	if (la < 1e-4f || lb < 1e-4f) return;
	const Vector3 tv = target - pa;
	const float d = std::min(std::max(tv.length(), std::fabs(la - lb) + 1e-3f), la + lb - 1e-3f);
	const Vector3 u = tv.normalized();
	Vector3 v = pole - u * pole.dot(u);
	if (v.length_squared() < 1e-8f) v = Vector3(0, 0, 1) - u * u.z;
	v.normalize();
	const float ca = std::min(std::max((la * la + d * d - lb * lb) / (2.0f * la * d), -1.0f), 1.0f);
	const Vector3 knee = pa + (u * ca + v * std::sqrt(std::max(0.0f, 1.0f - ca * ca))) * la;
	sk->set_bone_global_pose(a, Transform3D(arc(pb - pa, knee - pa) * Ga.basis, pa));
	const Transform3D Gb2 = sk->get_bone_global_pose(b), Gc2 = sk->get_bone_global_pose(c);
	sk->set_bone_global_pose(b, Transform3D(arc(Gc2.origin - Gb2.origin, pa + u * d - Gb2.origin) * Gb2.basis, Gb2.origin));
}

void HandGrip::_process_modification_with_delta(double p_delta) {
	(void)p_delta;
	Skeleton3D *sk = get_skeleton();
	if (!sk) return;
	if (!found) find_bones(sk);
	const Transform3D to_sk = sk->get_global_transform().affine_inverse();
	const Vector3 out_s = to_sk.basis.xform(out).normalized(), side_s = to_sk.basis.xform(side).normalized(), up_s = to_sk.basis.xform(Vector3(0, 1, 0)).normalized();
	const float k = to_sk.basis.get_column(0).length();   // (skeleton units a metre)
	for (int s = 0; s < 2; s++) {
		if (b_ua[s] < 0 || b_fa[s] < 0 || b_hd[s] < 0) continue;
		const float sgn = s == 0 ? 1.0f : -1.0f;
		// the wrist a little back from the edge and up off the top (the palm lies on the top, the fingers over the edge)
		const Vector3 target = to_sk.xform(grip[s]) + out_s * (0.07f * k) + up_s * (0.035f * k);
		reach(sk, b_ua[s], b_fa[s], b_hd[s], target, side_s * sgn * 1.4f - up_s * 0.6f + out_s * 0.4f);
		// the hand: its length along the way onto the top (away from the climber), its palm down
		const Transform3D Gh = sk->get_bone_global_pose(b_hd[s]);
		Vector3 fingers_dir = Vector3();
		if (n_fing[s] > 0) fingers_dir = sk->get_bone_global_pose(b_fing[s][0]).origin - Gh.origin;
		if (fingers_dir.length_squared() > 1e-8f) {
			const Basis turn = arc(fingers_dir, -out_s);   // the fingers toward the edge (over it, away from him)
			sk->set_bone_global_pose(b_hd[s], Transform3D(turn * Gh.basis, Gh.origin));
		}
		// the fingers curled down over the edge: each joint bent about the climber's side axis
		for (int j = 0; j < n_fing[s]; j++) {
			const int b = b_fing[s][j];
			const Transform3D Gf = sk->get_bone_global_pose(b);
			const float bend = (j % 3 == 0) ? curl * 0.6f : curl * 0.5f;
			sk->set_bone_global_pose(b, Transform3D(Basis(side_s, bend) * Gf.basis, Gf.origin));
		}
		miss[s] = sk->get_bone_global_pose(b_hd[s]).origin.distance_to(target) / std::max(k, 1e-4f);
		{   // the middle finger's last joint against the top of the edge
			const int tip = sk->find_bone(s == 0 ? "Bip01_L_Finger22" : "Bip01_R_Finger22");
			if (tip >= 0) tip_dy[s] = sk->get_global_transform().xform(sk->get_bone_global_pose(tip).origin).y - grip[s].y;
		}
	}
}

// ---------------------------------------------------------------- the feet
void FootPlant::find_bones(Skeleton3D *sk) {
	found = true;
	b_pel = sk->find_bone("Bip01_Pelvis");
	const char *th[2] = { "Bip01_L_Thigh", "Bip01_R_Thigh" }, *ca[2] = { "Bip01_L_Calf", "Bip01_R_Calf" }, *ft[2] = { "Bip01_L_Foot", "Bip01_R_Foot" };
	for (int s = 0; s < 2; s++) { b_th[s] = sk->find_bone(th[s]); b_ca[s] = sk->find_bone(ca[s]); b_ft[s] = sk->find_bone(ft[s]); }
	// the ankle's height over the sole: the foot bone's rest height over the figure's feet (its rest stands on 0)
	if (b_ft[0] >= 0) {
		const float k = sk->get_global_transform().basis.get_column(0).length();
		ankle_h = std::min(std::max(sk->get_bone_global_rest(b_ft[0]).origin.y * k, 0.03f), 0.15f);
	}
}

void FootPlant::_process_modification_with_delta(double p_delta) {
	(void)p_delta;
	Skeleton3D *sk = get_skeleton();
	if (!sk || !sk->get_world_3d().is_valid()) return;
	if (!found) find_bones(sk);
	if (b_pel < 0 || b_ft[0] < 0 || b_ft[1] < 0) return;
	PhysicsDirectSpaceState3D *ss = sk->get_world_3d()->get_direct_space_state();
	if (!ss) return;
	const Transform3D sg = sk->get_global_transform(), to_sk = sg.affine_inverse();
	float want[2];
	bool got[2] = { false, false };
	for (int s = 0; s < 2; s++) {
		const Vector3 fw = sg.xform(sk->get_bone_global_pose(b_ft[s]).origin);
		Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(fw + Vector3(0, 0.45f, 0), fw - Vector3(0, 0.5f, 0), 1);
		TypedArray<RID> ex; if (skip.is_valid()) ex.push_back(skip); q->set_exclude(ex);
		const Dictionary h = ss->intersect_ray(q);
		if (h.is_empty()) { want[s] = 0.0f; continue; }
		const float gy = ((Vector3)h["position"]).y;
		const float d = gy + ankle_h - fw.y;   // + : the ground is above where the clip put the ankle (a step), - : below
		if (std::fabs(d) > 0.45f) { want[s] = 0.0f; continue; }
		// (Yasin: "They should plant on the real collision surface, not where the animation puts them"): a foot the clip
		// has down (its ankle within 10 cm of the clip's own floor) is set on the collision under it; a foot it has up
		// (stepping over) stays up, only never into the surface
		const bool down = fw.y - sg.origin.y < ankle_h + 0.10f;
		if (!down && d <= 0.0f) { want[s] = 0.0f; continue; }
		want[s] = d;
		got[s] = true;
	}
	// the hips go down with the lower foot (so both legs reach); the higher foot is bent up onto its ground
	float drop = 0.0f;
	for (int s = 0; s < 2; s++) if (got[s] && fabsf(want[s]) > 0.0f) drop = std::min(drop, want[s]);
	drop = std::max(drop, -0.3f);
	hips_drop = drop;
	const Vector3 up_s = to_sk.basis.xform(Vector3(0, 1, 0));
	if (drop < 0.0f) {
		const Transform3D Gp = sk->get_bone_global_pose(b_pel);
		sk->set_bone_global_pose(b_pel, Transform3D(Gp.basis, Gp.origin + up_s * drop));
	}
	const Vector3 fwd_s = to_sk.basis.xform(fwd.length_squared() > 1e-6f ? fwd : Vector3(0, 0, 1)).normalized();
	for (int s = 0; s < 2; s++) {
		if (!got[s] || b_th[s] < 0 || b_ca[s] < 0) continue;
		const Vector3 cur = sk->get_bone_global_pose(b_ft[s]).origin;   // (after the hips went down)
		const Vector3 target = cur + up_s * (want[s] - drop);
		// a two-bone reach, the knee forward
		const int a = b_th[s], b = b_ca[s], c = b_ft[s];
		const Transform3D Ga = sk->get_bone_global_pose(a), Gb = sk->get_bone_global_pose(b), Gc = sk->get_bone_global_pose(c);
		const Vector3 pa = Ga.origin, pb = Gb.origin, pc = Gc.origin;
		const float la = (pb - pa).length(), lb = (pc - pb).length();
		if (la < 1e-4f || lb < 1e-4f) continue;
		const Vector3 tv = target - pa;
		const float d = std::min(std::max(tv.length(), std::fabs(la - lb) + 1e-3f), la + lb - 1e-3f);
		const Vector3 u = tv.normalized();
		Vector3 v = fwd_s - u * fwd_s.dot(u);
		if (v.length_squared() < 1e-8f) continue;
		v.normalize();
		const float ca = std::min(std::max((la * la + d * d - lb * lb) / (2.0f * la * d), -1.0f), 1.0f);
		const Vector3 knee = pa + (u * ca + v * std::sqrt(std::max(0.0f, 1.0f - ca * ca))) * la;
		const Basis foot_keep = Gc.basis;
		sk->set_bone_global_pose(a, Transform3D(arc(pb - pa, knee - pa) * Ga.basis, pa));
		const Transform3D Gb2 = sk->get_bone_global_pose(b), Gc2 = sk->get_bone_global_pose(c);
		sk->set_bone_global_pose(b, Transform3D(arc(Gc2.origin - Gb2.origin, pa + u * d - Gb2.origin) * Gb2.basis, Gb2.origin));
		const Transform3D Gc3 = sk->get_bone_global_pose(c);
		sk->set_bone_global_pose(c, Transform3D(foot_keep, Gc3.origin));   // (the sole stays as the clip had it: flat)
		const float k = sg.basis.get_column(0).length();
		foot_off[s] = (sg.xform(Gc3.origin).y - sg.xform(target).y) * (k > 0.0f ? 1.0f : 1.0f);
	}
}

} // namespace godot
