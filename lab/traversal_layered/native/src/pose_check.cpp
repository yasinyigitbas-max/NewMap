#include "pose_check.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/physics_shape_query_parameters3d.hpp>
#include <godot_cpp/classes/capsule_shape3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <cmath>
#include <cstdio>

using namespace godot;

namespace lab {

static const float G = 9.81f;
static const int PROBE_MASK = 1 | 4 | 8; // world contract: never debris (64)

static float lerp_lim(float x, float x0, float x1, float y0, float y1) {
	if (x <= x0) return y0;
	if (x >= x1) return y1;
	return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
}

static bool locomotion(int st) { return st == CS_START || st == CS_LOOP || st == CS_STOP || st == CS_PIVOT; }

// ---------------- static rules (v2 2.1, 2.2, 2.4, 11.2) ----------------
void check_static(const Measures &m, const Contacts &c, const FrameIn &in, std::vector<Hit> &o) {
	auto H = [&](const char *r, int s, float v, float l) { o.push_back({r, s, v, l}); };
	for (int s = 0; s < 2; s++) {
		const float k = m.knee_flex[s];
		if (k < -5) H("KNEE_FLEX_MIN", s, k, -5);
		if (k > 155) H("KNEE_FLEX_MAX", s, k, 155);
		if (std::fabs(m.knee_varus[s]) > 8) H("KNEE_VARUS", s, m.knee_varus[s], 8);
		const float tl = lerp_lim(k, 20, 60, 5, 25);
		if (std::fabs(m.knee_twist[s]) > tl) H("KNEE_TWIST", s, m.knee_twist[s], tl);
		const float dl = lerp_lim(k, 15, 30, 25, 40);
		if (m.ankle_dorsi[s] > dl) H("ANKLE_DORSI", s, m.ankle_dorsi[s], dl);
		if (m.ankle_dorsi[s] < -55) H("ANKLE_PLANTAR", s, m.ankle_dorsi[s], -55);
		if (m.ankle_inv[s] > 30) H("ANKLE_INVERSION", s, m.ankle_inv[s], 30);
		if (m.ankle_inv[s] < -15) H("ANKLE_EVERSION", s, m.ankle_inv[s], -15);
		if (m.foot_abd[s] > 30) H("FOOT_TWIST", s, m.foot_abd[s], 30);
		if (m.foot_abd[s] < -20) H("FOOT_TWIST", s, m.foot_abd[s], -20);
		if (m.toe_bend[s] > 80) H("TOE_BEND", s, m.toe_bend[s], 80);
		const float hl = lerp_lim(k, 20, 60, 90, 125);
		if (m.hip_flex[s] > hl) H("HIP_FLEX_COUPLED", s, m.hip_flex[s], hl);
		if (m.hip_flex[s] < -30) H("HIP_EXT", s, m.hip_flex[s], -30);
		if (m.hip_abd[s] > 45) H("HIP_ABD", s, m.hip_abd[s], 45);
		if (m.hip_abd[s] < -30) H("HIP_ABD", s, m.hip_abd[s], -30);
		if (m.hip_rot[s] < -40) H("HIP_ROTATION", s, m.hip_rot[s], -40);
		if (m.hip_rot[s] > 50) H("HIP_ROTATION", s, m.hip_rot[s], 50);
		if (m.sh_back[s] > 60) H("SHOULDER_CONE", s, m.sh_back[s], 60);
		if (m.sh_across[s] > 40) H("SHOULDER_CONE", s, m.sh_across[s], 40);
		if (m.sh_twist[s] > 70) H("SHOULDER_TWIST", s, m.sh_twist[s], 70);
		if (m.sh_twist[s] < -90) H("SHOULDER_TWIST", s, m.sh_twist[s], -90);
		if (m.elbow_flex[s] < -10) H("ELBOW", s, m.elbow_flex[s], -10);
		if (m.elbow_flex[s] > 150) H("ELBOW", s, m.elbow_flex[s], 150);
		if (std::fabs(m.forearm_twist[s]) > 85) H("FOREARM_TWIST", s, m.forearm_twist[s], 85);
		if (m.wrist_flex[s] > 80) H("WRIST", s, m.wrist_flex[s], 80);
		if (m.wrist_flex[s] < -90) H("WRIST", s, m.wrist_flex[s], -90);
		if (m.wrist_dev[s] > 20) H("WRIST", s, m.wrist_dev[s], 20);
		if (m.wrist_dev[s] < -35) H("WRIST", s, m.wrist_dev[s], -35);
		// contacts (1.7)
		int down = 0;
		float lowest = 1e9f;
		for (int p = 0; p < SOLE_N; p++) {
			if (c.pt[s][p]) down++;
			lowest = std::min(lowest, c.h[s][p]);
			if (c.h[s][p] < -0.01f) H("CONTACT_SINK", s, c.h[s][p] * 100, -1);
		}
		if (in.planted[s] && lowest > 0.01f && in.state != CS_AIR) H("CONTACT_HOVER", s, lowest * 100, 1);
		if (down >= 2) {
			const Vector3 F = m.foot_F[s], U = m.foot_U[s], n = c.n[s];
			const float roll = std::fabs(signed_angle(n, U, F)) * DEG;
			if (roll > 5) H("SOLE_ROLL", s, roll, 5);
			if (c.pt[s][HEEL] && (c.pt[s][BALL_IN] || c.pt[s][BALL_OUT])) {
				const Vector3 side = F.cross(n);
				const float pitch = std::fabs(signed_angle(n, U, side)) * DEG;
				if (pitch > 5) H("SOLE_ROLL", s, pitch, 5); // pitch with heel and ball both down
			}
		}
		if (c.any[s] && m.knee_flex[s] > 20 && m.knee_over_toe[s] > 35) H("KNEE_OVER_TOE", s, m.knee_over_toe[s], 35);
	}
	if (m.lumbar_flex > 50) H("SPINE_LUMBAR", -1, m.lumbar_flex, 50);
	if (m.lumbar_flex < -25) H("SPINE_LUMBAR", -1, m.lumbar_flex, -25);
	if (std::fabs(m.lumbar_side) > 25) H("SPINE_LUMBAR", -1, m.lumbar_side, 25);
	if (std::fabs(m.lumbar_twist) > 10) H("SPINE_LUMBAR", -1, m.lumbar_twist, 10);
	if (m.thor_flex > 30) H("SPINE_THORACIC", -1, m.thor_flex, 30);
	if (m.thor_flex < -20) H("SPINE_THORACIC", -1, m.thor_flex, -20);
	if (std::fabs(m.thor_twist) > 35) H("SPINE_THORACIC", -1, m.thor_twist, 35);
	if (m.neck_flex > 50) H("NECK", -1, m.neck_flex, 50);
	if (m.neck_flex < -60) H("NECK", -1, m.neck_flex, -60);
	if (std::fabs(m.neck_turn) > 80) H("NECK", -1, m.neck_turn, 80);
	if (std::fabs(m.neck_side) > 45) H("NECK", -1, m.neck_side, 45);
	if (m.finger_min < -5) H("FINGERS", -1, m.finger_min, -5);
	if (m.finger_max_excess > 0) H("FINGERS", -1, m.finger_max_excess, 0);
	if (m.max_bone_len_err_mm > 0.5f) H("BONE_LENGTH", -1, m.max_bone_len_err_mm, 0.5f);
	if (locomotion(in.state)) {
		if (m.trunk_fwd > 30) H("TRUNK_LEAN", -1, m.trunk_fwd, 30);
		if (m.trunk_fwd < -15) H("TRUNK_LEAN", -1, m.trunk_fwd, -15);
		if (std::fabs(m.trunk_side) > 25) H("TRUNK_LEAN", -1, m.trunk_side, 25);
	}
}

// ---------------- the node ----------------
void PoseCheck::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_frame_input", "state", "speed", "vel", "planted_l", "planted_r", "grip_l", "grip_r"), &PoseCheck::set_frame_input);
	ClassDB::bind_method(D_METHOD("set_flat_ground", "on", "y"), &PoseCheck::set_flat_ground);
	ClassDB::bind_method(D_METHOD("set_seed", "seed"), &PoseCheck::set_seed);
	ClassDB::bind_method(D_METHOD("set_active", "a"), &PoseCheck::set_active);
	ClassDB::bind_method(D_METHOD("reset"), &PoseCheck::reset);
	ClassDB::bind_method(D_METHOD("get_counts"), &PoseCheck::get_counts);
	ClassDB::bind_method(D_METHOD("get_log"), &PoseCheck::get_log);
	ClassDB::bind_method(D_METHOD("measure_now"), &PoseCheck::measure_now);
	ClassDB::bind_method(D_METHOD("check_static_now"), &PoseCheck::check_static_now);
	ClassDB::bind_method(D_METHOD("step_manual", "dt"), &PoseCheck::step_manual);
	ClassDB::bind_method(D_METHOD("get_frames"), &PoseCheck::get_frames);
	ClassDB::bind_method(D_METHOD("is_model_ok"), &PoseCheck::is_model_ok);
	ClassDB::bind_method(D_METHOD("get_model_error"), &PoseCheck::get_model_error);
	ClassDB::bind_method(D_METHOD("get_com"), &PoseCheck::get_com);
	ClassDB::bind_method(D_METHOD("get_sole_point", "side", "k"), &PoseCheck::get_sole_point);
}

Skeleton3D *PoseCheck::skel() const {
	Skeleton3D *s = get_skeleton();
	if (!s) s = Object::cast_to<Skeleton3D>(get_parent());
	return s;
}

void PoseCheck::ensure_model() {
	if (model.ok || !model.error.is_empty()) return;
	Skeleton3D *sk = skel();
	if (!sk) return;
	if (!model.init(sk)) UtilityFunctions::push_error("PoseCheck: body model: ", model.error);
}

void PoseCheck::set_frame_input(int state, float speed, Vector3 vel, bool pl, bool pr, bool gl, bool gr) {
	in.state = state;
	in.speed = speed;
	in.vel = vel;
	in.planted[0] = pl;
	in.planted[1] = pr;
	in.grip[0] = gl;
	in.grip[1] = gr;
}

void PoseCheck::reset() {
	counts.clear();
	log.clear();
	buf.clear();
	frames = 0;
	t = 0;
	for (int s = 0; s < 2; s++) {
		for (int p = 0; p < SOLE_N; p++) { ep_on[s][p] = false; ep_logged[s][p] = false; ep_max[s][p] = 0; }
		flat_on[s] = false;
		spin_logged[s] = false;
		any_contact_prev[s] = false;
		grip_on[s] = false;
	}
	both_down_since = -1;
	in_flight = false;
	step_t0 = -1;
	have_step = false;
	have_heading = false;
	turn20_since = -1;
	was_running = false;
	stop_contacts = 0;
	head_pitch_hist.clear();
	limiter_acted = 0;
}

void PoseCheck::hit(const char *rule, int side, float value, float limit) {
	counts[rule]++;
	fired_now.push_back(rule);
	if (log.size() < 400) {
		char line[256];
		std::snprintf(line, sizeof(line), "f=%d t=%.3f %s side=%d value=%.2f limit=%.2f state=%d speed=%.2f seed=%d", frames, t, rule,
				side, value, limit, in.state, in.speed, seed);
		log.push_back(line);
	}
}

void PoseCheck::contacts_for(const Measures &me, Contacts &c) {
	Skeleton3D *sk = skel();
	PhysicsDirectSpaceState3D *ss = nullptr;
	if (!use_flat_ground && sk && sk->is_inside_tree() && sk->get_world_3d().is_valid())
		ss = sk->get_world_3d()->get_direct_space_state();
	for (int s = 0; s < 2; s++) {
		Vector3 nsum;
		int nn = 0;
		c.any[s] = false;
		for (int p = 0; p < SOLE_N; p++) {
			const Vector3 pt = me.sole_w[s][p];
			float gy = flat_ground_y;
			Vector3 n(0, 1, 0);
			bool found = use_flat_ground;
			if (ss) {
				Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(pt + Vector3(0, 0.5f, 0), pt - Vector3(0, 1.0f, 0), PROBE_MASK);
				Dictionary h = ss->intersect_ray(q);
				if (!h.is_empty()) {
					gy = ((Vector3)h["position"]).y;
					n = h["normal"];
					found = true;
				}
			}
			c.h[s][p] = found ? pt.y - gy : 1.0f;
			c.pt[s][p] = found && std::fabs(c.h[s][p]) <= 0.01f;
			if (c.pt[s][p] || c.h[s][p] < 0) c.any[s] = true;
			if ((p == HEEL || p == BALL_IN) && found && n.y > std::cos(30 * RAD)) { nsum += n; nn++; } // 10.4: ignore risers
		}
		c.n[s] = nn ? nsum.normalized() : Vector3(0, 1, 0);
	}
}

Dictionary PoseCheck::measure_now() {
	Dictionary d;
	ensure_model();
	Skeleton3D *sk = skel();
	if (!model.ok || !sk) return d;
	sk->force_update_all_bone_transforms();
	world_pose(model, sk, W);
	Measures m;
	measure(model, W.data(), m);
	last = m;
	const char *sd[2] = {"_l", "_r"};
	for (int s = 0; s < 2; s++) {
		String x = sd[s];
		d[String("knee_flex") + x] = m.knee_flex[s];
		d[String("knee_varus") + x] = m.knee_varus[s];
		d[String("knee_twist") + x] = m.knee_twist[s];
		d[String("hip_flex") + x] = m.hip_flex[s];
		d[String("hip_abd") + x] = m.hip_abd[s];
		d[String("hip_rot") + x] = m.hip_rot[s];
		d[String("ankle_dorsi") + x] = m.ankle_dorsi[s];
		d[String("ankle_inv") + x] = m.ankle_inv[s];
		d[String("foot_abd") + x] = m.foot_abd[s];
		d[String("toe_bend") + x] = m.toe_bend[s];
		d[String("sh_elev") + x] = m.sh_elev[s];
		d[String("sh_back") + x] = m.sh_back[s];
		d[String("sh_across") + x] = m.sh_across[s];
		d[String("sh_twist") + x] = m.sh_twist[s];
		d[String("elbow_flex") + x] = m.elbow_flex[s];
		d[String("forearm_twist") + x] = m.forearm_twist[s];
		d[String("wrist_flex") + x] = m.wrist_flex[s];
		d[String("wrist_dev") + x] = m.wrist_dev[s];
		d[String("knee_over_toe") + x] = m.knee_over_toe[s];
		d[String("leg_ext") + x] = m.leg_extension[s];
	}
	d["lumbar_flex"] = m.lumbar_flex;
	d["lumbar_side"] = m.lumbar_side;
	d["lumbar_twist"] = m.lumbar_twist;
	d["thor_flex"] = m.thor_flex;
	d["thor_side"] = m.thor_side;
	d["thor_twist"] = m.thor_twist;
	d["neck_flex"] = m.neck_flex;
	d["neck_side"] = m.neck_side;
	d["neck_turn"] = m.neck_turn;
	d["trunk_fwd"] = m.trunk_fwd;
	d["trunk_side"] = m.trunk_side;
	d["head_roll"] = m.head_roll;
	d["head_pitch"] = m.head_pitch;
	d["finger_min"] = m.finger_min;
	d["finger_excess"] = m.finger_max_excess;
	d["com"] = m.com;
	d["bone_err_mm"] = m.max_bone_len_err_mm;
	return d;
}

PackedStringArray PoseCheck::check_static_now() {
	PackedStringArray r;
	ensure_model();
	Skeleton3D *sk = skel();
	if (!model.ok || !sk) return r;
	sk->force_update_all_bone_transforms();
	world_pose(model, sk, W);
	Measures m;
	measure(model, W.data(), m);
	Contacts c;
	contacts_for(m, c);
	std::vector<Hit> hs;
	check_static(m, c, in, hs);
	for (auto &h : hs) r.push_back(String(h.rule));
	// self intersection is single-frame too
	Capsule cap[CAP_N];
	capsules(model, W.data(), m, cap);
	auto deep = [&](int i, int j) { return seg_seg_dist(cap[i].a, cap[i].b, cap[j].a, cap[j].b) < cap[i].r + cap[j].r - 0.01f; };
	if (deep(CAP_FARM_L, CAP_TRUNK) || deep(CAP_FARM_R, CAP_TRUNK) || deep(CAP_FARM_L, CAP_FARM_R) || deep(CAP_FARM_L, CAP_UARM_R) ||
			deep(CAP_FARM_R, CAP_UARM_L) || deep(CAP_THIGH_L, CAP_THIGH_R))
		r.push_back("SELF_INTERSECT");
	return r;
}

PackedStringArray PoseCheck::step_manual(double dt) {
	fired_now.clear();
	if (Skeleton3D *sk = skel()) sk->force_update_all_bone_transforms();
	evaluate(dt);
	PackedStringArray r;
	for (auto &s : fired_now) r.push_back(String(s.c_str()));
	return r;
}

void PoseCheck::_process_modification_with_delta(double p_delta) {
	if (!active || p_delta <= 0) return;
	if (Engine::get_singleton()->is_editor_hint()) return;
	fired_now.clear();
	evaluate(p_delta);
}

// least-squares polynomial (degree <= 2) through samples, at x = 0; returns value, first and second derivative
static void polyfit(const std::vector<double> &x, const std::vector<double> &y, double &v, double &d1, double &d2) {
	const int n = (int)x.size();
	const int deg = n >= 4 ? 2 : (n >= 2 ? 1 : 0);
	double S[5] = {0, 0, 0, 0, 0}, T[3] = {0, 0, 0};
	for (int i = 0; i < n; i++) {
		double p = 1;
		for (int k = 0; k < 5; k++) { S[k] += p; if (k < 3) T[k] += p * y[i]; p *= x[i]; }
	}
	v = n ? T[0] / S[0] : 0;
	d1 = d2 = 0;
	if (deg == 1) {
		const double den = S[0] * S[2] - S[1] * S[1];
		if (std::fabs(den) > 1e-15) {
			const double b = (S[0] * T[1] - S[1] * T[0]) / den;
			v = (T[0] - b * S[1]) / S[0];
			d1 = b;
		}
	} else if (deg == 2) {
		double A[3][4] = {{S[0], S[1], S[2], T[0]}, {S[1], S[2], S[3], T[1]}, {S[2], S[3], S[4], T[2]}};
		for (int c = 0; c < 3; c++) {
			int piv = c;
			for (int r = c + 1; r < 3; r++)
				if (std::fabs(A[r][c]) > std::fabs(A[piv][c])) piv = r;
			for (int k = 0; k < 4; k++) std::swap(A[c][k], A[piv][k]);
			if (std::fabs(A[c][c]) < 1e-18) return;
			for (int r = 0; r < 3; r++) {
				if (r == c) continue;
				const double f = A[r][c] / A[c][c];
				for (int k = 0; k < 4; k++) A[r][k] -= f * A[c][k];
			}
		}
		v = A[0][3] / A[0][0];
		d1 = A[1][3] / A[1][1];
		d2 = 2 * A[2][3] / A[2][2];
	}
}

void PoseCheck::evaluate(double dt) {
	ensure_model();
	Skeleton3D *sk = skel();
	if (!model.ok || !sk) return;
	t += dt;
	frames++;
	world_pose(model, sk, W);
	Measures m;
	measure(model, W.data(), m);
	Contacts c;
	contacts_for(m, c);
	last = m;
	lastc = c;

	// ---- single-frame rules on the drawn pose ----
	std::vector<Hit> hs;
	check_static(m, c, in, hs);
	for (auto &h : hs) hit(h.rule, h.side, h.value, h.limit);
	{
		Capsule cap[CAP_N];
		capsules(model, W.data(), m, cap);
		const int pairs[][2] = {{CAP_FARM_L, CAP_TRUNK}, {CAP_FARM_R, CAP_TRUNK}, {CAP_FARM_L, CAP_FARM_R}, {CAP_FARM_L, CAP_UARM_R},
				{CAP_FARM_R, CAP_UARM_L}, {CAP_THIGH_L, CAP_THIGH_R}};
		for (auto &p : pairs) {
			const float d = seg_seg_dist(cap[p[0]].a, cap[p[0]].b, cap[p[1]].a, cap[p[1]].b);
			const float lim = cap[p[0]].r + cap[p[1]].r - 0.01f;
			if (d < lim) hit("SELF_INTERSECT", p[0], d, lim);
		}
		// the world (6.12): capsules on mask 1|4|8, the feet excluded (soles may touch)
		if (!use_flat_ground && sk->is_inside_tree()) {
			PhysicsDirectSpaceState3D *ss = sk->get_world_3d()->get_direct_space_state();
			if (cap_shape.is_null()) cap_shape.instantiate();
			Ref<CapsuleShape3D> shape = cap_shape;
			for (int i = 0; i < CAP_N; i++) {
				if (i == CAP_SHIN_L || i == CAP_SHIN_R) continue; // shins stand in steps' risers' range; checked by sole points
				const Vector3 ax = cap[i].b - cap[i].a;
				const float len = ax.length();
				if (len < 1e-3f) continue;
				shape->set_radius(cap[i].r);
				shape->set_height(len + 2 * cap[i].r);
				Ref<PhysicsShapeQueryParameters3D> q;
				q.instantiate();
				q->set_shape(shape);
				q->set_collision_mask(PROBE_MASK);
				q->set_transform(Transform3D(Basis(arc(Vector3(0, 1, 0), ax / len)), (cap[i].a + cap[i].b) * 0.5f));
				TypedArray<Vector3> pts = ss->collide_shape(q, 8);
				float depth = 0;
				for (int k = 0; k + 1 < pts.size(); k += 2) depth = std::max(depth, ((Vector3)pts[k]).distance_to((Vector3)pts[k + 1]));
				if (depth > 0.01f) hit("WORLD_INTERSECT", i, depth * 100, 1);
			}
		}
	}

	// ---- contact episodes: slide, spin (1.7, 4.6, 6.12) ----
	for (int s = 0; s < 2; s++) {
		for (int p = 0; p < SOLE_N; p++) {
			const Vector3 pt = m.sole_w[s][p];
			if (c.pt[s][p]) {
				if (!ep_on[s][p]) { ep_on[s][p] = true; ep_start[s][p] = pt; ep_max[s][p] = 0; ep_logged[s][p] = false; }
				const Vector3 dlt = pt - ep_start[s][p];
				const float slide = std::sqrt(dlt.x * dlt.x + dlt.z * dlt.z);
				ep_max[s][p] = std::max(ep_max[s][p], slide);
				if (slide > 0.01f && !ep_logged[s][p]) { hit("FOOT_SLIDE", s, slide * 100, 1); ep_logged[s][p] = true; }
			} else
				ep_on[s][p] = false;
		}
		const bool flat = c.pt[s][HEEL] && (c.pt[s][BALL_IN] || c.pt[s][BALL_OUT]);
		const float yaw = std::atan2(m.foot_F[s].x, m.foot_F[s].z);
		if (flat) {
			if (!flat_on[s]) { flat_on[s] = true; flat_yaw0[s] = yaw; spin_logged[s] = false; }
			float dy = yaw - flat_yaw0[s];
			while (dy > 3.14159265f) dy -= 6.2831853f;
			while (dy < -3.14159265f) dy += 6.2831853f;
			if (std::fabs(dy) * DEG > 5 && !spin_logged[s]) { hit("FOOT_SPIN", s, std::fabs(dy) * DEG, 5); spin_logged[s] = true; }
		} else
			flat_on[s] = false;
	}
	// hands gripping stay put (6.12)
	for (int s = 0; s < 2; s++) {
		const Vector3 palm = W[model.b.hand[s]].origin.lerp(model.b.knuckle_mid[s] >= 0 ? W[model.b.knuckle_mid[s]].origin : W[model.b.hand[s]].origin, 0.5f);
		if (in.grip[s]) {
			if (!grip_on[s]) { grip_on[s] = true; grip_start[s] = palm; }
			const float d = palm.distance_to(grip_start[s]);
			if (d > 0.01f) { hit("HAND_SLIDE", s, d * 100, 1); grip_start[s] = palm; }
		} else
			grip_on[s] = false;
	}

	// ---- gait rules (4.1, 4.3) ----
	const bool down[2] = {c.any[0], c.any[1]};
	const bool walking = locomotion(in.state) && in.speed < 2.0f && in.speed > 0.3f;
	if (walking && in.state == CS_LOOP && !down[0] && !down[1]) hit("WALK_FLIGHT", -1, 0, 0);
	if (in.state == CS_LOOP && in.speed > 2.5f && down[0] && down[1]) {
		if (both_down_since < 0) both_down_since = t;
		if (t - both_down_since > 0.020 + 1e-6) { hit("RUN_DOUBLE_SUPPORT", -1, (float)((t - both_down_since) * 1000), 20); both_down_since = t + 1e9; }
	} else
		both_down_since = -1;
	// contact starts mark steps
	bool new_contact = false;
	for (int s = 0; s < 2; s++) {
		if (down[s] && !any_contact_prev[s]) new_contact = true;
		any_contact_prev[s] = down[s];
	}

	// ---- controller rules: turn rate, cuts, stops (3.3, 3.4) ----
	{
		const Vector3 v = in.vel;
		const float sp = std::sqrt(v.x * v.x + v.z * v.z);
		const float heading = std::atan2(v.x, v.z);
		if (prev_t_ >= 0 && sp > 0.3f) {
			float dh = heading - prev_heading_;
			while (dh > 3.14159265f) dh -= 6.2831853f;
			while (dh < -3.14159265f) dh += 6.2831853f;
			const float w = dh / (float)dt;
			omega_f_ += (w - omega_f_) * (1.0f - std::exp(-(float)dt / 0.1f)); // 0.1 s per second-based filter (10.5)
		}
		prev_heading_ = heading;
		prev_t_ = t;
		if (sp > 1.8f && locomotion(in.state)) {
			const float lean = std::atan(sp * std::fabs(omega_f_) / G) * DEG;
			if (lean > 30.5f) hit("TURN_RATE", -1, lean, 30);
			if (lean > 20.5f) {
				if (turn20_since < 0) turn20_since = t;
				if (t - turn20_since > 0.75) { hit("TURN_RATE", -1, lean, 20); turn20_since = t; }
			} else
				turn20_since = -1;
		} else
			turn20_since = -1;
		if (new_contact) {
			if (have_heading && sp > 2.2f && locomotion(in.state) && in.state != CS_PIVOT) {
				float dh = heading - step_heading0;
				while (dh > 3.14159265f) dh -= 6.2831853f;
				while (dh < -3.14159265f) dh += 6.2831853f;
				const float lim = 2.0f * std::asin(std::min(1.0f, 1.85f / (2.0f * sp))) * DEG + 1.0f;
				if (std::fabs(dh) * DEG > lim) hit("CUT_ANGLE", -1, std::fabs(dh) * DEG, lim);
			}
			step_heading0 = heading;
			have_heading = sp > 0.3f;
		}
		if (sp > 2.5f) { was_running = true; stop_contacts = 0; }
		else if (was_running) {
			if (new_contact) stop_contacts++;
			if (sp < 0.1f) {
				if (stop_contacts < 2) hit("STOP_STEPS", -1, (float)stop_contacts, 2);
				was_running = false;
			}
		}
	}

	// ---- time series, evaluated at the centre of a +-40 ms window (1.8) ----
	Sample smp{t, m, c, in};
	buf.push_back(smp);
	const double half = std::max(0.04, 1.5 * dt);
	while (!buf.empty() && buf.front().t < t - 2.2 * half - 1.0) buf.pop_front();
	// centre = newest sample at least `half` old
	int ci = -1;
	for (int i = (int)buf.size() - 1; i >= 0; i--)
		if (buf[i].t <= t - half + 1e-9) { ci = i; break; }
	if (ci < 0) return;
	const Sample &C = buf[ci];
	if (C.t - buf.front().t < half - 1e-9) return;
	std::vector<double> xs, xs_nc;
	std::vector<int> idx, idx_nc;
	for (int i = 0; i < (int)buf.size(); i++) {
		const double x = buf[i].t - C.t;
		if (std::fabs(x) <= half + 1e-9) {
			xs.push_back(x);
			idx.push_back(i);
			if (i != ci) { xs_nc.push_back(x); idx_nc.push_back(i); }
		}
	}
	auto fit = [&](auto get, bool exclude_centre, double &v, double &d1, double &d2) {
		std::vector<double> ys;
		const std::vector<int> &I = exclude_centre ? idx_nc : idx;
		for (int i : I) ys.push_back(get(buf[i]));
		polyfit(exclude_centre ? xs_nc : xs, ys, v, d1, d2);
	};
	const bool impact = C.in.state == CS_AIR || C.in.state == CS_TRAVERSE;
	// joint speeds (2.3) and discontinuities (1.8)
	struct J { const char *name; float lim; float Measures::*f1; float (Measures::*f2)[2]; int side; };
	const J js[] = {
		{"knee", 1500, nullptr, &Measures::knee_flex, 0}, {"knee", 1500, nullptr, &Measures::knee_flex, 1},
		{"hip", 1000, nullptr, &Measures::hip_flex, 0}, {"hip", 1000, nullptr, &Measures::hip_flex, 1},
		{"ankle", 1200, nullptr, &Measures::ankle_dorsi, 0}, {"ankle", 1200, nullptr, &Measures::ankle_dorsi, 1},
		{"shoulder", 1200, nullptr, &Measures::sh_elev, 0}, {"shoulder", 1200, nullptr, &Measures::sh_elev, 1},
		{"elbow", 1500, nullptr, &Measures::elbow_flex, 0}, {"elbow", 1500, nullptr, &Measures::elbow_flex, 1},
		{"spine", 300, &Measures::lumbar_flex, nullptr, -1}, {"spine", 300, &Measures::lumbar_side, nullptr, -1},
		{"spine", 300, &Measures::thor_twist, nullptr, -1}, {"neck", 500, &Measures::neck_turn, nullptr, -1},
	};
	for (const J &j : js) {
		auto get = [&](const Sample &s) -> double { return j.f1 ? s.m.*(j.f1) : (s.m.*(j.f2))[j.side]; };
		double v, d1, d2;
		fit(get, false, v, d1, d2);
		if (std::fabs(d1) > j.lim && !impact) hit("JOINT_SPEED", j.side, (float)d1, j.lim);
		if (xs_nc.size() >= 2) {
			double vn, e1, e2;
			fit(get, true, vn, e1, e2);
			const double off = get(C) - vn;
			if (std::fabs(off) > 3.0) hit("POSE_DISCONTINUITY", j.side, (float)off, 3);
		}
	}
	// pelvis yaw speed
	{
		const double y0 = C.m.pelvis_yaw;
		auto get = [&](const Sample &s) -> double {
			double d = s.m.pelvis_yaw - y0;
			while (d > 3.14159265) d -= 6.2831853;
			while (d < -3.14159265) d += 6.2831853;
			return d * DEG;
		};
		double v, d1, d2;
		fit(get, false, v, d1, d2);
		if (std::fabs(d1) > 720) hit("PELVIS_YAW_SPEED", -1, (float)d1, 720);
	}
	// CoM: velocity, acceleration, discontinuity (3.5, 3.6)
	double cv[3], ca[3];
	for (int k = 0; k < 3; k++) {
		auto get = [&](const Sample &s) -> double { return s.m.com[k]; };
		double v, d1, d2;
		fit(get, false, v, d1, d2);
		cv[k] = d1;
		ca[k] = d2;
		if (xs_nc.size() >= 2) {
			double vn, e1, e2;
			fit(get, true, vn, e1, e2);
			if (std::fabs(get(C) - vn) > 0.005) hit("POSE_DISCONTINUITY", -1, (float)((get(C) - vn) * 100), 0.5f);
		}
	}
	const bool contact = C.c.any[0] || C.c.any[1] || C.in.grip[0] || C.in.grip[1];
	const float ah = (float)std::sqrt(ca[0] * ca[0] + ca[2] * ca[2]);
	if (ca[1] < -(G + 1)) hit("COM_DOWN_GT_G", -1, (float)ca[1], -(G + 1));
	if (contact && ah > C.in.mu * G + 1) hit("COM_ACCEL_H", -1, ah, C.in.mu * G + 1);
	if (ca[1] > 30 && C.in.state != CS_AIR) hit("COM_ACCEL_V", -1, (float)ca[1], 30);
	// flight: the take-off parabola (3.5)
	if (!contact) {
		if (!in_flight) { in_flight = true; to_pos = C.m.com; to_vel = Vector3((float)cv[0], (float)cv[1], (float)cv[2]); to_t = C.t; }
		const float tt = (float)(C.t - to_t);
		const Vector3 pred = to_pos + to_vel * tt + Vector3(0, -0.5f * G * tt * tt, 0);
		const float dev = pred.distance_to(C.m.com);
		if (dev > 0.01f) {
			hit(C.in.state == CS_TRAVERSE && cv[1] > 0 ? "RISE_NO_CONTACT" : "FLIGHT_PARABOLA", -1, dev * 100, 1);
			to_pos = C.m.com; // re-anchor so one error isn't counted every frame
			to_vel = Vector3((float)cv[0], (float)cv[1], (float)cv[2]);
			to_t = C.t;
		}
		if (ah > 1.0f + 1e-3f && tt > 0.05f) hit("FLIGHT_PARABOLA", -1, ah, 1);
	} else
		in_flight = false;

	// whole-body lean: CoP -> CoM (1.6, 3.2)
	if (locomotion(C.in.state) && (C.c.any[0] || C.c.any[1])) {
		Vector3 cop;
		float wsum = 0;
		for (int s = 0; s < 2; s++) {
			if (!C.c.any[s]) continue;
			const bool heel = C.c.pt[s][HEEL], ball = C.c.pt[s][BALL_IN] || C.c.pt[s][BALL_OUT];
			const Vector3 bm = (C.m.sole_w[s][BALL_IN] + C.m.sole_w[s][BALL_OUT]) * 0.5f;
			Vector3 p = heel && ball ? (C.m.sole_w[s][HEEL] + bm) * 0.5f : (ball ? bm : (heel ? C.m.sole_w[s][HEEL] : C.m.sole_w[s][TOE_TIP]));
			Vector3 dd = C.m.com - p;
			dd.y = 0;
			const float w = 1.0f / (dd.length() + 0.05f);
			cop += p * w;
			wsum += w;
		}
		cop /= wsum;
		cop_w = cop;
		const Vector3 L = C.m.com - cop;
		const Vector3 A((float)ca[0], (float)(G + ca[1]), (float)ca[2]);
		if (L.y > 0.3f && A.y > 0.5f) {
			const float mis = std::acos(std::clamp(L.normalized().dot(A.normalized()), -1.0f, 1.0f)) * DEG;
			if (mis > 10) hit("LEAN_MISMATCH", -1, mis, 10);
		}
		// per-step averages
		const Vector3 tan_l(L.dot(C.m.pelvis_l) / L.y, L.dot(C.m.pelvis_f) / L.y, 0);
		const bool step_end = (new_contact && C.t - step_t0 > 0.15) || C.t - step_t0 > 0.6; // a long stance closes a step too
		if (step_end && step_t0 >= 0 && step_n > 0) {
			const Vector3 mean = step_lean_sum / (float)step_n;
			const Vector3 vnow((float)cv[0], 0, (float)cv[2]);
			const Vector3 am = (vnow - step_v0) / (float)(C.t - step_t0);
			const float lean_deg = std::atan(mean.length()) * DEG;
			const float lim = std::atan(C.in.mu) * DEG;
			if (lean_deg > lim) hit("LEAN_MAX", -1, lean_deg, lim);
			const Vector3 pred(am.dot(C.m.pelvis_l) / G, am.dot(C.m.pelvis_f) / G, 0);
			const float mis = std::fabs(std::atan(mean.x) - std::atan(pred.x)) * DEG + 0.0f;
			const float misf = std::fabs(std::atan(mean.y) - std::atan(pred.y)) * DEG;
			if (std::max(mis, misf) > 5) hit("LEAN_MISMATCH", -1, std::max(mis, misf), 5);
			last_step_lean = mean;
			have_step = true;
		}
		if (step_end || step_t0 < 0) {
			step_t0 = C.t;
			step_lean_sum = Vector3();
			step_n = 0;
			step_v0 = Vector3((float)cv[0], 0, (float)cv[2]);
		}
		step_lean_sum += tan_l;
		step_n++;
		if (have_step) {
			const float bf = C.m.trunk_fwd - std::atan(last_step_lean.y) * DEG;
			const float bs = C.m.trunk_side - std::atan(last_step_lean.x) * DEG;
			if (std::fabs(bf) > 15) hit("TRUNK_BEND", -1, bf, 15);
			if (std::fabs(bs) > 15) hit("TRUNK_BEND", -1, bs, 15);
		}
	} else if (!locomotion(C.in.state)) {
		step_t0 = -1;
		have_step = false;
	}
	// head level (2.4)
	if (C.in.state == CS_LOOP) {
		const float turning = std::fabs(C.m.trunk_side);
		const float lim = std::max(5.0f, 0.5f * turning);
		if (std::fabs(C.m.head_roll) > lim) hit("HEAD_LEVEL", -1, C.m.head_roll, lim);
		head_pitch_hist.push_back({C.t, C.m.head_pitch});
		const double stride = C.in.speed > 2.2f ? 0.7 : 1.0;
		while (!head_pitch_hist.empty() && head_pitch_hist.front().first < C.t - stride) head_pitch_hist.pop_front();
		if (C.t - head_pitch_hist.front().first > stride * 0.9) {
			float lo = 1e9f, hi = -1e9f;
			for (auto &p : head_pitch_hist) { lo = std::min(lo, p.second); hi = std::max(hi, p.second); }
			if (hi - lo > 10) { hit("HEAD_LEVEL", -1, hi - lo, 10); head_pitch_hist.clear(); }
		}
	} else
		head_pitch_hist.clear();
	if (limiter_acted > 0) {
		hit("LIMITER_ACTED", -1, (float)limiter_acted, 0);
		limiter_acted = 0;
	}
}

Dictionary PoseCheck::get_counts() const {
	Dictionary d;
	for (auto &kv : counts) d[String(kv.first.c_str())] = kv.second;
	return d;
}

PackedStringArray PoseCheck::get_log() const {
	PackedStringArray r;
	for (auto &s : log) r.push_back(String(s.c_str()));
	return r;
}

} // namespace lab
