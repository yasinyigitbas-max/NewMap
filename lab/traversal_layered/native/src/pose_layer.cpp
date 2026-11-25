#include "pose_layer.h"
#include "inertial.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/core/class_db.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

namespace lab {

static const float G = 9.81f;

void PoseLayer::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_foot_world", "side"), &PoseLayer::get_foot_world);
	ClassDB::bind_method(D_METHOD("get_foot_locked", "side"), &PoseLayer::get_foot_locked);
	ClassDB::bind_method(D_METHOD("get_lean_deg"), &PoseLayer::get_lean_deg);
	ClassDB::bind_method(D_METHOD("get_head_yaw_deg"), &PoseLayer::get_head_yaw_deg);
	ClassDB::bind_method(D_METHOD("get_ik_clamped"), &PoseLayer::get_ik_clamped);
	ClassDB::bind_method(D_METHOD("set_layers", "mask"), &PoseLayer::set_layers);
	ClassDB::bind_method(D_METHOD("get_layers"), &PoseLayer::get_layers);
}

void PoseLayer::find_bones() {
	Skeleton3D *sk = get_skeleton();
	if (!sk) return;
	H = sk->find_bone("Hips");
	SPINE[0] = sk->find_bone("Spine02");
	SPINE[1] = sk->find_bone("Spine01");
	SPINE[2] = sk->find_bone("Spine");
	NECK = sk->find_bone("neck");
	HEAD = sk->find_bone("Head");
	const char *sd[2] = {"Left", "Right"};
	for (int s = 0; s < 2; s++) {
		String p = sd[s];
		UP[s] = sk->find_bone(p + "UpLeg");
		LO[s] = sk->find_bone(p + "Leg");
		FOOT[s] = sk->find_bone(p + "Foot");
		TOE[s] = sk->find_bone(p + "ToeBase");
		FARM[s] = sk->find_bone(p + "ForeArm");
		HAND[s] = sk->find_bone(p + "Hand");
		leg_len[s][0] = sk->get_bone_rest(LO[s]).origin.length();
		leg_len[s][1] = sk->get_bone_rest(FOOT[s]).origin.length();
	}
	// skeleton units -> metres: the Armature node's scale (player_v3: 0.01)
	Node3D *par = Object::cast_to<Node3D>(sk->get_parent());
	scale = par ? par->get_transform().basis.get_scale().x : 0.01f;
	ready_idx = H >= 0 && HEAD >= 0 && UP[0] >= 0 && UP[1] >= 0;
}

static void spring_to(float &x, float &v, float target, float halflife, float dt) {
	float e = x - target;
	spring_decay(e, v, halflife, dt);
	x = target + e;
}

// rotation that turns direction a into direction b (shortest arc)
static Quaternion arc(const Vector3 &a, const Vector3 &b) {
	const Vector3 an = a.normalized(), bn = b.normalized();
	const float d = an.dot(bn);
	if (d > 0.99999f) return Quaternion();
	if (d < -0.9999f) {
		Vector3 ax = an.cross(Vector3(1, 0, 0));
		if (ax.length_squared() < 1e-6f) ax = an.cross(Vector3(0, 0, 1));
		return Quaternion(ax.normalized(), (float)Math_PI);
	}
	return Quaternion(an, bn);
}

void PoseLayer::leg_ik(Skeleton3D *sk, int s, const Vector3 &target_in, const Basis &foot_basis, const Vector3 &pole) {
	Transform3D gu = sk->get_bone_global_pose(UP[s]);
	Transform3D gl = sk->get_bone_global_pose(LO[s]);
	Transform3D gf = sk->get_bone_global_pose(FOOT[s]);
	const Vector3 a = gu.origin;
	const float l1 = leg_len[s][0], l2 = leg_len[s][1];
	const float L = l1 + l2;
	Vector3 to = target_in - a;
	float d = to.length();
	if (d < 1e-4f) return;
	const Vector3 dir = to / d;
	// soft IK: the last few % of reach approach full extension smoothly, never snap straight (study 4.x)
	const float ds = 0.97f * L;
	if (d > ds) {
		if (d > L) ik_clamped++;
		d = ds + (L - ds) * (1.0f - std::exp(-(d - ds) / (L - ds)));
	}
	d = std::max(d, std::fabs(l1 - l2) + 1e-3f);
	const Vector3 target = a + dir * d;
	// knee in the plane of the hip-ankle line and the pole (knee over the toes, study 1.2/3)
	Vector3 pp = (pole - a) - dir * (pole - a).dot(dir);
	if (pp.length_squared() < 1e-8f) pp = gl.origin - a - dir * (gl.origin - a).dot(dir);
	const Vector3 n = pp.normalized();
	const float ca = std::clamp((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d), -1.0f, 1.0f);
	const float sa = std::sqrt(std::max(0.0f, 1 - ca * ca));
	const Vector3 knee = a + dir * (l1 * ca) + n * (l1 * sa);
	// upper leg: turn so it points at the new knee
	const Quaternion qu = arc(gl.origin - a, knee - a);
	gu.basis = Basis(qu) * gu.basis;
	sk->set_bone_global_pose(UP[s], gu);
	// lower leg: from the new knee, point at the target
	Transform3D gl2 = sk->get_bone_global_pose(LO[s]);
	Transform3D gf2 = sk->get_bone_global_pose(FOOT[s]);
	const Quaternion ql = arc(gf2.origin - gl2.origin, target - gl2.origin);
	gl2.basis = Basis(ql) * gl2.basis;
	sk->set_bone_global_pose(LO[s], gl2);
	// foot keeps the wanted orientation, with the ankle limited (study 1.2/4): at most 20 deg up from the shin's
	// rest angle; past it the heel lifts (the foot pitches down) rather than the ankle bending further
	Transform3D gf3 = sk->get_bone_global_pose(FOOT[s]);
	const Transform3D gl3 = sk->get_bone_global_pose(LO[s]);
	Basis fb = foot_basis;
	const Vector3 shin = (gf3.origin - gl3.origin).normalized();
	const Basis rest_l = sk->get_bone_rest(FOOT[s]).basis;
	const Basis fb_rest = gl3.basis * rest_l; // foot at its rest angle to the shin
	const Vector3 toe_dir_rest = (fb_rest.xform(sk->get_bone_rest(TOE[s]).origin)).normalized();
	const Vector3 toe_dir = (fb.xform(sk->get_bone_rest(TOE[s]).origin)).normalized();
	const float ang_rest = std::acos(std::clamp(toe_dir_rest.dot(-shin), -1.0f, 1.0f));
	const float ang_now = std::acos(std::clamp(toe_dir.dot(-shin), -1.0f, 1.0f));
	const float max_up = (float)Math::deg_to_rad(20.0);
	if (ang_rest - ang_now > max_up) {
		// rotate the foot down about its own side axis by the excess
		const Vector3 ax = toe_dir.cross(-shin).normalized();
		const float ex = (ang_rest - ang_now) - max_up;
		if (ax.length_squared() > 0.5f) fb = Basis(ax, -ex) * fb;
	}
	gf3.basis = fb;
	sk->set_bone_global_pose(FOOT[s], gf3);
}

void PoseLayer::_process_modification_with_delta(double p_delta) {
	Skeleton3D *sk = get_skeleton();
	if (!sk || !in.valid) return;
	if (!ready_idx) find_bones();
	if (!ready_idx) return;
	const float dt = (float)std::max(p_delta, 1e-4);
	ik_clamped = 0;

	// 1. the locomotion pose, interpolated between the last two physics ticks (study 6.5)
	const float fr = (float)Engine::get_singleton()->get_physics_interpolation_fraction();
	pose_blend(in.pose_prev, in.pose_cur, std::clamp(fr, 0.0f, 1.0f), work);
	const int n = std::min(work.size(), sk->get_bone_count());
	for (int i = 0; i < n; i++) sk->set_bone_pose_rotation(i, work.rot[i]);
	sk->set_bone_pose_position(H, work.hips);

	// 2. forearm twist (study 1.2/1): half the hand's twist about the forearm axis moves into the forearm
	if (layers & 8) {
		for (int s = 0; s < 2; s++) {
			const Vector3 ax = sk->get_bone_rest(HAND[s]).origin.normalized(); // forearm -> hand, forearm frame
			const Quaternion lh = sk->get_bone_pose_rotation(HAND[s]);
			const Quaternion rh = sk->get_bone_rest(HAND[s]).basis.get_rotation_quaternion();
			const Quaternion dq = lh * rh.inverse(); // hand's rotation from rest, forearm frame
			const Vector3 v(dq.x, dq.y, dq.z);
			const Vector3 pr = ax * v.dot(ax);
			Quaternion tw(pr.x, pr.y, pr.z, dq.w);
			if (tw.length_squared() < 1e-8f) continue;
			tw = tw.normalized();
			const Quaternion half = Quaternion().slerp(tw, 0.5f);
			sk->set_bone_pose_rotation(FARM[s], sk->get_bone_pose_rotation(FARM[s]) * half);
			sk->set_bone_pose_rotation(HAND[s], (half.inverse() * lh).normalized());
		}
	}

	const Transform3D skw = sk->get_global_transform_interpolated();
	const Transform3D skw_inv = skw.affine_inverse();
	const float s_m = skw.basis.get_scale().y; // world metres per skeleton unit (0.01)

	// 3. foot targets from the clip pose, before the lean (so the lean comes from the feet, study 2.5)
	Vector3 tgt_sk[2], pole_sk[2];
	Basis fbasis_sk[2];
	const Transform3D gh0 = sk->get_bone_global_pose(H);
	const Vector3 hips_ground_w = skw.xform(Vector3(gh0.origin.x, 0, gh0.origin.z));
	Vector3 vdir = Vector3(in.vel_world.x, 0, in.vel_world.z);
	const float vlen = vdir.length();
	if (vlen > 0.05f) vdir /= vlen;
	for (int s = 0; s < 2; s++) {
		const Transform3D gf = sk->get_bone_global_pose(FOOT[s]);
		const Transform3D gk = sk->get_bone_global_pose(LO[s]);
		fbasis_sk[s] = gf.basis;
		Vector3 fw = skw.xform(gf.origin);
		const float clip_h = gf.origin.y * s_m; // ankle height above the clip's ground (metres)
		// stride warping: scale the foot's reach along the travel direction around the hips (study 4.1)
		if (vlen > 0.05f && std::fabs(in.stride_scale - 1.0f) > 0.01f) {
			const Vector3 off = fw - hips_ground_w;
			const float along = off.dot(vdir);
			fw += vdir * (along * (in.stride_scale - 1.0f));
		}
		fw.y = in.ground_y[s] + clip_h;
		// foot lock while the clip says the foot is down (study 4.1)
		if (layers & 2) {
			if (in.contact[s]) {
				if (!locked[s]) {
					locked[s] = true;
					lock_pos[s] = fw;
				}
				Vector3 lp = lock_pos[s];
				if (Vector2(lp.x - fw.x, lp.z - fw.z).length() > 0.30f) {
					// too far from where the clip wants it (a spin, a teleport): let go
					lock_pos[s] = fw;
					lp = fw;
				}
				fw.x = lp.x;
				fw.z = lp.z;
			} else {
				if (locked[s]) {
					locked[s] = false;
					unlock_blend[s] = 1.0f;
				}
				if (unlock_blend[s] > 0) {
					fw.x = fw.x + (lock_pos[s].x - fw.x) * unlock_blend[s];
					fw.z = fw.z + (lock_pos[s].z - fw.z) * unlock_blend[s];
					unlock_blend[s] = std::max(0.0f, unlock_blend[s] - dt / 0.12f);
				}
			}
		}
		foot_world[s] = fw;
		tgt_sk[s] = skw_inv.xform(fw);
		// pole: in front of the knee along the foot's forward (knee over the toes)
		const Vector3 toe_dir = gf.basis.xform(sk->get_bone_rest(TOE[s]).origin).normalized();
		Vector3 fwd_h(toe_dir.x, 0, toe_dir.z);
		if (fwd_h.length_squared() < 1e-6f) fwd_h = Vector3(0, 0, 1);
		pole_sk[s] = gk.origin + fwd_h.normalized() * (40.0f);
	}

	// 4. whole-body lean from the feet: atan(a/g) forward/back, atan(v^2/(g r)) into the turn (study 2.5, 4.5)
	if (layers & 1) {
		const float tf = in.lean_enabled ? std::atan(std::clamp(in.accel_long, -8.0f, 8.0f) / G) * 0.6f : 0.0f;
		const float ts = std::atan(std::clamp(in.accel_lat, -9.0f, 9.0f) / G);
		spring_to(lean_f, lean_fv, std::clamp(tf, -0.35f, 0.35f), 0.06f, dt);
		spring_to(lean_s, lean_sv, std::clamp(ts, -0.6f, 0.6f), 0.06f, dt);
		const Quaternion q = Quaternion(Vector3(0, 0, 1), -lean_s) * Quaternion(Vector3(1, 0, 0), lean_f);
		Transform3D gh = sk->get_bone_global_pose(H);
		const Vector3 pivot(gh.origin.x, 0, gh.origin.z);
		gh.origin = pivot + q.xform(gh.origin - pivot);
		gh.basis = Basis(q) * gh.basis;
		sk->set_bone_global_pose(H, gh);
		lean_total_deg = (float)Math::rad_to_deg(std::sqrt(lean_f * lean_f + lean_s * lean_s));
	}

	// 5. legs to the targets
	if (layers & 2) {
		for (int s = 0; s < 2; s++) leg_ik(sk, s, tgt_sk[s], fbasis_sk[s], pole_sk[s]);
	}

	// 6. head: leads the turn toward the stick (0.2-0.3 s ahead, study 2.5) and stays level (study 1.2/6)
	if (layers & 4) {
		float rel = std::remainder(in.head_yaw_target - in.body_yaw, (float)Math_TAU);
		rel = std::clamp(rel, -1.2f, 1.2f);
		spring_to(head_yaw, head_yaw_v, rel, 0.05f, dt);
		head_yaw_deg = (float)Math::rad_to_deg(head_yaw);
		const Vector3 up(0, 1, 0);
		Transform3D gn = sk->get_bone_global_pose(NECK);
		gn.basis = Basis(Quaternion(up, head_yaw * 0.4f)) * gn.basis;
		sk->set_bone_global_pose(NECK, gn);
		Transform3D ghd = sk->get_bone_global_pose(HEAD);
		ghd.basis = Basis(Quaternion(up, head_yaw * 0.6f)) * ghd.basis;
		// level the head: take half of its tilt away from the rest's up
		const Basis rest_g = sk->get_bone_global_rest(HEAD).basis;
		const Vector3 up_rest_local = rest_g.inverse().xform(up).normalized();
		const Vector3 up_now = ghd.basis.xform(up_rest_local).normalized();
		const Quaternion lev = Quaternion().slerp(arc(up_now, up), 0.5f);
		ghd.basis = Basis(lev) * ghd.basis;
		sk->set_bone_global_pose(HEAD, ghd);
	}
}

} // namespace lab
