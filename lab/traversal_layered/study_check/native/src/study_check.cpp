// STUDY CHECK (LOCKED): see study_check.h. Section numbers refer to HUMAN_MOVEMENT_STUDY.md v2.
#include "study_check.h"

#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/classes/capsule_shape3d.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/physics_shape_query_parameters3d.hpp>
#include <godot_cpp/classes/skin.hpp>
#include <godot_cpp/classes/sphere_shape3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <cmath>
#include <cstdio>

using namespace godot;

namespace study {

static const float G = 9.81f;
static const float PI = 3.14159265358979f;
static inline float deg(float r) { return r * 180.0f / PI; }
static inline float rad(float d) { return d * PI / 180.0f; }
static inline float clampf(float x, float a, float b) { return std::max(a, std::min(b, x)); }
static inline float lerp_lim(float x, float x0, float x1, float y0, float y1) {
	if (x <= x0) return y0;
	if (x >= x1) return y1;
	return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
}
static Vector3 nrm(const Vector3 &v) {
	const float l = v.length();
	return l > 1e-9f ? v / l : Vector3();
}
static Vector3 flat(const Vector3 &v) { return Vector3(v.x, 0, v.z); }
static Quaternion arcq(const Vector3 &a0, const Vector3 &b0) {
	const Vector3 a = nrm(a0), b = nrm(b0);
	const float d = a.dot(b);
	if (d > 0.999999f) return Quaternion();
	if (d < -0.999999f) {
		Vector3 ax = a.cross(Vector3(1, 0, 0));
		if (ax.length_squared() < 1e-6f) ax = a.cross(Vector3(0, 0, 1));
		return Quaternion(nrm(ax), PI);
	}
	return Quaternion(a, b);
}
static Quaternion canon(Quaternion q) {
	q = q.normalized();
	if (q.w < 0) q = Quaternion(-q.x, -q.y, -q.z, -q.w);
	return q;
}
// study 1.5: swing-twist about unit axis d. Returns false for an undefined twist (a ~180 deg swing).
static bool swing_twist(const Quaternion &qin, const Vector3 &d, float &twist_deg, Vector3 &swing_vec_deg) {
	const Quaternion q = canon(qin);
	const Vector3 v(q.x, q.y, q.z);
	const float p = v.dot(d);
	if (std::fabs(p) < 1e-6f && std::fabs(q.w) < 1e-6f) {
		twist_deg = 180;
		swing_vec_deg = Vector3(180, 0, 0);
		return false;
	}
	twist_deg = deg(2.0f * std::atan2(p, q.w));
	if (twist_deg > 180) twist_deg -= 360;
	if (twist_deg < -180) twist_deg += 360;
	const Vector3 pp = d * p;
	Quaternion tw = Quaternion(pp.x, pp.y, pp.z, q.w).normalized();
	Quaternion sw = canon(q * tw.inverse());
	const Vector3 sv(sw.x, sw.y, sw.z);
	const float sl = sv.length();
	const float ang = 2.0f * std::atan2(sl, sw.w);
	swing_vec_deg = sl > 1e-9f ? sv / sl * deg(ang) : Vector3();
	return true;
}

static const char *CH_NAMES[C_COUNT] = {
	"knee_flex_L", "knee_flex_R", "knee_varus_L", "knee_varus_R", "knee_twist_L", "knee_twist_R",
	"dorsi_L", "dorsi_R", "inv_L", "inv_R", "foot_abd_L", "foot_abd_R", "toe_L", "toe_R",
	"hip_flex_L", "hip_flex_R", "hip_abd_L", "hip_abd_R", "hip_rot_L", "hip_rot_R",
	"sh_elev_L", "sh_elev_R", "sh_across_L", "sh_across_R", "sh_twist_L", "sh_twist_R", "elbow_L", "elbow_R",
	"farm_twist_L", "farm_twist_R", "wrist_f_L", "wrist_f_R", "wrist_d_L", "wrist_d_R",
	"lumb_f", "lumb_s", "lumb_t", "thor_f", "thor_s", "thor_t", "neck_f", "neck_s", "neck_t", "pelvis_yaw"};

// joint speed limits (2.3), deg/s, per channel
static float speed_limit(int c) {
	if (c < C_DORSI) return 1500;           // knee
	if (c < C_HIP_FLEX) return 1200;        // ankle, foot, toe
	if (c < C_SH_ELEV) return 1000;         // hip
	if (c < C_ELBOW) return 1200;           // shoulder
	if (c < C_LUMB_F) return 1500;          // elbow, forearm, wrist
	if (c < C_NECK_F) return 300;           // spine
	if (c < C_PELVIS_YAW) return 500;       // neck
	return 720;                             // pelvis yaw (8)
}

void StudyCheck::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_role", "role"), &StudyCheck::set_role);
	ClassDB::bind_method(D_METHOD("get_role"), &StudyCheck::get_role);
	ClassDB::bind_method(D_METHOD("set_peer", "pre_check"), &StudyCheck::set_peer);
	ClassDB::bind_method(D_METHOD("set_controller", "obj"), &StudyCheck::set_controller);
	ClassDB::bind_method(D_METHOD("set_physics_rules", "on"), &StudyCheck::set_physics_rules);
	ClassDB::bind_method(D_METHOD("set_contact_rules", "on"), &StudyCheck::set_contact_rules);
	ClassDB::bind_method(D_METHOD("set_label", "s"), &StudyCheck::set_label);
	ClassDB::bind_method(D_METHOD("set_seed", "s"), &StudyCheck::set_seed);
	ClassDB::bind_method(D_METHOD("set_mu", "mu"), &StudyCheck::set_mu);
	ClassDB::bind_method(D_METHOD("set_log_limit", "n"), &StudyCheck::set_log_limit);
	ClassDB::bind_method(D_METHOD("set_eval_delay", "s"), &StudyCheck::set_eval_delay);
	ClassDB::bind_method(D_METHOD("set_ground_mask", "m"), &StudyCheck::set_ground_mask);
	ClassDB::bind_method(D_METHOD("reset"), &StudyCheck::reset);
	ClassDB::bind_method(D_METHOD("flush"), &StudyCheck::flush);
	ClassDB::bind_method(D_METHOD("get_report"), &StudyCheck::get_report);
	ClassDB::bind_method(D_METHOD("get_log"), &StudyCheck::get_log);
	ClassDB::bind_method(D_METHOD("get_channel", "name"), &StudyCheck::get_channel);
	ClassDB::bind_method(D_METHOD("get_last"), &StudyCheck::get_last);
	ClassDB::bind_method(D_METHOD("is_setup_ok"), &StudyCheck::is_setup_ok);
	ClassDB::bind_method(D_METHOD("get_setup_error"), &StudyCheck::get_setup_error);
	ClassDB::bind_method(D_METHOD("get_sole_points"), &StudyCheck::get_sole_points);
	ClassDB::bind_method(D_METHOD("get_com"), &StudyCheck::get_com);
	ClassDB::bind_method(D_METHOD("get_frames"), &StudyCheck::get_frames);
	ClassDB::bind_method(D_METHOD("get_time"), &StudyCheck::get_time);
	ClassDB::bind_method(D_METHOD("set_bone_prefix", "p"), &StudyCheck::set_bone_prefix);
	ClassDB::bind_method(D_METHOD("set_sole_mode", "m"), &StudyCheck::set_sole_mode);
}

void StudyCheck::set_role(const String &r) { role = r.utf8().get_data(); }

void StudyCheck::reset() {
	t = 0;
	frame = 0;
	buf.clear();
	next_eval = 0;
	rules.clear();
	log_count.clear();
	state_time.clear();
	log_lines.clear();
	limiter_key_frames = limiter_other_frames = 0;
	yaw_init = false;
	for (int s = 0; s < 2; s++) {
		flat_prev[s] = false;
		ev_prev_contact[s] = true;
		for (int k = 0; k < 4; k++) prev_pt[s][k] = false;
	}
	ev_last_td = -1;
	step = StepAcc();
	steps.clear();
	tight_steps = 0;
	prev_head_pitch_range = 0;
	in_flight = false;
	flight_pts.clear();
	last_land_t = -10;
	run_seen_t = -1;
	td_since_run = 0;
	walk_flight_t = 0;
	ds_cur = 0;
	ds_exempt = false;
	flight_acc.clear();
	prev_pitch_valid = false;
}

bool StudyCheck::fail(const std::string &e) {
	setup_ok = false;
	setup_error = e;
	UtilityFunctions::push_error(String("STUDY_CHECK SETUP_FAIL: ") + String(e.c_str()));
	return false;
}

// ------------------------------------------------------------------------------------------------ setup (rest pose)
void StudyCheck::setup(Skeleton3D *sk) {
	setup_done = true;
	setup_ok = true;
	const String pre = String(bone_prefix.c_str());
	auto find = [&](const String &n) -> int {
		int i = sk->find_bone(pre + n);
		if (i < 0) i = sk->find_bone(n);
		return i;
	};
	auto fb = [&](std::initializer_list<const char *> names) -> int {
		for (const char *n : names) {
			const int i = find(n);
			if (i >= 0) return i;
		}
		return -1;
	};
	H = fb({"Hips"});
	// spine: Meshy (Hips > Spine02 > Spine01 > Spine) or Mixamo (Hips > Spine > Spine1 > Spine2)
	const int s02 = find("Spine02");
	if (s02 >= 0 && sk->get_bone_parent(s02) == H) {
		LOW = s02;
		MID = fb({"Spine01"});
		CHEST = fb({"Spine"});
	} else {
		LOW = fb({"Spine"});
		MID = fb({"Spine1"});
		CHEST = fb({"Spine2"});
	}
	NECK = fb({"neck", "Neck"});
	HEAD = fb({"Head"});
	HEADTOP = fb({"head_end", "HeadTop_End"});
	const char *sd[2] = {"Left", "Right"};
	const char *fn[4] = {"Index", "Middle", "Ring", "Pinky"};
	for (int s = 0; s < 2; s++) {
		String p = sd[s];
		UP[s] = find(p + "UpLeg");
		LO[s] = find(p + "Leg");
		FOOT[s] = find(p + "Foot");
		TOE[s] = find(p + "ToeBase");
		SHO[s] = find(p + "Shoulder");
		ARM[s] = find(p + "Arm");
		FARM[s] = find(p + "ForeArm");
		HAND[s] = find(p + "Hand");
		MID1[s] = find(p + "HandMiddle1");
		THUMB1[s] = find(p + "HandThumb1");
		for (int f = 0; f < 4; f++)
			for (int j = 0; j < 3; j++) FING[s][f][j] = find(p + "Hand" + fn[f] + String::num_int64(j + 1));
	}
	for (int b : {H, LOW, MID, CHEST, NECK, HEAD})
		if (b < 0) { fail("missing a spine / neck / head bone"); return; }
	for (int s = 0; s < 2; s++)
		for (int b : {UP[s], LO[s], FOOT[s], TOE[s], SHO[s], ARM[s], FARM[s], HAND[s], MID1[s], THUMB1[s]})
			if (b < 0) { fail("missing a limb bone"); return; }

	const int n = sk->get_bone_count();
	R0.resize(n);
	P0.resize(n);
	rest_xf.resize(n);
	for (int i = 0; i < n; i++) {
		const Transform3D g = sk->get_bone_global_rest(i);
		rest_xf[i] = g;
		R0[i] = g.basis.orthonormalized();
		P0[i] = g.origin;
	}
	const Transform3D w = sk->get_global_transform();
	unit = w.basis.get_scale().y;
	if (unit <= 0) { fail("skeleton world scale is zero"); return; }

	// 1.0 sanity: body facing +Z with its left at +X; head above hips; plausible bone lengths
	if (!(P0[UP[0]].x > P0[UP[1]].x)) { fail("LeftUpLeg is not on +X: the body does not face +Z at rest"); return; }
	if (!(P0[HEAD].y > P0[H].y)) { fail("head below hips at rest"); return; }
	for (int s = 0; s < 2; s++) {
		const float th = P0[UP[s]].distance_to(P0[LO[s]]) * unit, sh = P0[LO[s]].distance_to(P0[FOOT[s]]) * unit;
		if (th < 0.33f || th > 0.52f || sh < 0.33f || sh > 0.52f) {
			char b[160];
			snprintf(b, sizeof b, "implausible leg bones: thigh %.3f m, shin %.3f m (expected 0.33-0.52)", th, sh);
			fail(b);
			return;
		}
	}
	capture_sole_points(sk);
	if (!setup_ok) return;

	const Vector3 F0(0, 0, 1), L0(1, 0, 0), U0(0, 1, 0);
	for (int s = 0; s < 2; s++) {
		const Vector3 t0 = nrm(P0[LO[s]] - P0[UP[s]]);
		const Vector3 a0 = nrm(L0 - t0 * L0.dot(t0));
		hinge_up[s] = R0[UP[s]].transposed().xform(a0);
		hinge_lo[s] = R0[LO[s]].transposed().xform(a0);
		ft_sign[s] = a0.cross(t0).dot(F0) > 0 ? 1.0f : -1.0f;
		const Vector3 s0 = nrm(P0[FOOT[s]] - P0[LO[s]]);
		fs_sign[s] = s0.cross(a0).dot(F0) > 0 ? 1.0f : -1.0f;
		const Vector3 u0 = nrm(P0[FARM[s]] - P0[ARM[s]]);
		Vector3 e0 = nrm(u0.cross(F0));
		if (e0.length_squared() < 0.5f) { fail("upper arm points straight forward at rest"); return; }
		elbow_hinge[s] = R0[ARM[s]].transposed().xform(e0);
		palm_n0[s] = Vector3(0, -1, 0); // assumption: palms face down in the rest T-pose (README)
		thumb0[s] = nrm(P0[THUMB1[s]] - P0[HAND[s]]);
	}
	// bone lengths (6.12)
	bone_pairs.clear();
	rest_len.clear();
	for (int s = 0; s < 2; s++) {
		bone_pairs.push_back({UP[s], LO[s]});
		bone_pairs.push_back({LO[s], FOOT[s]});
		bone_pairs.push_back({FOOT[s], TOE[s]});
		bone_pairs.push_back({SHO[s], ARM[s]});
		bone_pairs.push_back({ARM[s], FARM[s]});
		bone_pairs.push_back({FARM[s], HAND[s]});
		bone_pairs.push_back({HAND[s], MID1[s]});
	}
	bone_pairs.push_back({H, LOW});
	bone_pairs.push_back({LOW, MID});
	bone_pairs.push_back({MID, CHEST});
	bone_pairs.push_back({CHEST, NECK});
	bone_pairs.push_back({NECK, HEAD});
	for (auto &p : bone_pairs) rest_len.push_back(P0[p.first].distance_to(P0[p.second]) * unit);

	// rest pass: every channel's raw value at rest (rest-relative channels subtract it)
	for (int c = 0; c < C_COUNT; c++) rest_ch[c] = 0;
	use_rest = true;
	Sample rs;
	measure(rs, true);
	use_rest = false;
	for (int c = 0; c < C_COUNT; c++) rest_ch[c] = rs.ch[c];
	for (int s = 0; s < 2; s++) { rest_ch[C_SH_ELEV + s] = 0; rest_ch[C_SH_ACROSS + s] = 0; }
	rest_ch[C_PELVIS_YAW] = 0;
}

void StudyCheck::capture_sole_points(Skeleton3D *sk) {
	if (sole_mode == "bones") {
		// CALIBRATION ONLY (reference clips on a skeleton with no mesh): sole points from the foot bones at rest,
		// on the rest ground (y = 0). Never used for the lab's body.
		for (int s = 0; s < 2; s++) {
			const Vector3 an = P0[FOOT[s]] * unit, tb = P0[TOE[s]] * unit;
			const Vector3 fd = nrm(Vector3(tb.x - an.x, 0, tb.z - an.z));
			const Vector3 lat = Vector3(0, 1, 0).cross(fd) * (s == 0 ? 1.0f : -1.0f); // toward +X for the left foot
			const Vector3 heel = Vector3(an.x, 0.005f, an.z) - fd * 0.05f;
			const Vector3 inner = Vector3(tb.x, 0.005f, tb.z) - lat * 0.035f, outer = Vector3(tb.x, 0.005f, tb.z) + lat * 0.045f;
			const Vector3 tip = Vector3(tb.x, 0.01f, tb.z) + fd * 0.07f;
			const Transform3D fi = sk->get_bone_global_rest(FOOT[s]).affine_inverse();
			const Transform3D ti = sk->get_bone_global_rest(TOE[s]).affine_inverse();
			sole_off[s][0] = fi.xform(heel / unit);
			sole_off[s][1] = fi.xform(inner / unit);
			sole_off[s][2] = fi.xform(outer / unit);
			sole_off[s][3] = ti.xform(tip / unit);
			const Vector3 U = (inner - heel).cross(outer - heel);
			u_sign[s] = U.y > 0 ? 1.0f : -1.0f;
			F_rest[s] = nrm((inner + outer) * 0.5f - heel);
			U_rest[s] = nrm(U * u_sign[s]);
		}
		return;
	}
	MeshInstance3D *mi = nullptr;
	for (int i = 0; i < sk->get_child_count() && !mi; i++) mi = Object::cast_to<MeshInstance3D>(sk->get_child(i));
	if (!mi || mi->get_mesh().is_null() || mi->get_skin().is_null()) {
		fail("no skinned MeshInstance3D under the skeleton (sole points come from the mesh, 1.1)");
		return;
	}
	Ref<Mesh> mesh = mi->get_mesh();
	Ref<Skin> skin = mi->get_skin();
	std::vector<int> bind_bone(skin->get_bind_count());
	for (int i = 0; i < skin->get_bind_count(); i++) {
		int b = skin->get_bind_bone(i);
		if (b < 0) b = sk->find_bone(skin->get_bind_name(i));
		bind_bone[i] = b;
	}
	std::vector<Vector3> pts[2];
	for (int si = 0; si < mesh->get_surface_count(); si++) {
		Array arr = mesh->surface_get_arrays(si);
		PackedVector3Array verts = arr[Mesh::ARRAY_VERTEX];
		PackedInt32Array bones = arr[Mesh::ARRAY_BONES];
		PackedFloat32Array wts = arr[Mesh::ARRAY_WEIGHTS];
		if (verts.size() == 0 || bones.size() == 0) continue;
		const int per = bones.size() / verts.size();
		for (int v = 0; v < verts.size(); v++) {
			float wf[2] = {0, 0}, best = -1;
			int bb = -1;
			for (int k = 0; k < per; k++) {
				const int bi = bones[v * per + k];
				const float ww = wts[v * per + k];
				if (bi < 0 || bi >= (int)bind_bone.size()) continue;
				const int b = bind_bone[bi];
				for (int s = 0; s < 2; s++)
					if (b == FOOT[s] || b == TOE[s]) wf[s] += ww;
				if (ww > best) { best = ww; bb = bi; }
			}
			for (int s = 0; s < 2; s++) {
				if (wf[s] < 0.5f || bb < 0) continue;
				const int b = bind_bone[bb];
				const Vector3 p = sk->get_bone_global_rest(b).xform(skin->get_bind_pose(bb).xform(verts[v]));
				pts[s].push_back(p * unit); // metres, skeleton axes
			}
		}
	}
	for (int s = 0; s < 2; s++) {
		if (pts[s].size() < 20) { fail("too few foot vertices in the mesh"); return; }
		float ymin = 1e9f;
		for (auto &p : pts[s]) ymin = std::min(ymin, p.y);
		if (std::fabs(ymin) > 0.03f) {
			char b[160];
			snprintf(b, sizeof b, "the rest sole is %.3f m off the ground: the mesh does not sit on the skeleton's rest", ymin);
			fail(b);
			return;
		}
		const float ztoe = P0[TOE[s]].z * unit;
		const float side = s == 0 ? 1.0f : -1.0f; // lateral = +X for the left foot
		Vector3 heel, inner, outer, tip;
		float hz = 1e9f, tz = -1e9f, imed = 1e9f, olat = -1e9f;
		bool hi = false, ii = false;
		// heel: the lowest vertex in the rear 3 cm of the foot; tip: the lowest in the front 2 cm (1.1)
		float zmin = 1e9f, zmax = -1e9f;
		for (auto &p : pts[s]) { zmin = std::min(zmin, p.z); zmax = std::max(zmax, p.z); }
		float hy = 1e9f, ty = 1e9f;
		for (auto &p : pts[s]) {
			if (p.z <= zmin + 0.03f && p.y < hy) { hy = p.y; heel = p; }
			if (p.z >= zmax - 0.02f && p.y < ty) { ty = p.y; tip = p; }
		}
		(void)hz; (void)tz;
		for (auto &p : pts[s]) {
			if (p.y <= ymin + 0.015f && std::fabs(p.z - ztoe) <= 0.015f) {
				const float lat = p.x * side;
				if (lat < imed) { imed = lat; inner = p; ii = true; }
				if (lat > olat) { olat = lat; outer = p; hi = true; }
			}
		}
		if (!ii || !hi) { fail("no sole vertices under the ball of the foot"); return; }
		const float bw = inner.distance_to(outer);
		if (bw < 0.05f || bw > 0.13f) {
			char b[160];
			snprintf(b, sizeof b, "ball width %.3f m (inner to outer) is implausible", bw);
			fail(b);
			return;
		}
		// heel and balls ride the Foot bone (the metatarsal heads belong to the foot), the tip the Toe bone (README)
		const Transform3D fi = sk->get_bone_global_rest(FOOT[s]).affine_inverse();
		const Transform3D ti = sk->get_bone_global_rest(TOE[s]).affine_inverse();
		sole_off[s][0] = fi.xform(heel / unit);
		sole_off[s][1] = fi.xform(inner / unit);
		sole_off[s][2] = fi.xform(outer / unit);
		sole_off[s][3] = ti.xform(tip / unit);
		const Vector3 U = (inner - heel).cross(outer - heel);
		u_sign[s] = U.y > 0 ? 1.0f : -1.0f;
		F_rest[s] = nrm((inner + outer) * 0.5f - heel);
		U_rest[s] = nrm(U * u_sign[s]);
	}
}

// ------------------------------------------------------------------------------------------------ frame access
Basis StudyCheck::Bw(int b) const {
	if (use_rest) return R0[b];
	return (skw.basis * skc->get_bone_global_pose(b).basis).orthonormalized();
}
Vector3 StudyCheck::Pw(int b) const {
	if (use_rest) return P0[b] * unit;
	return skw.xform(skc->get_bone_global_pose(b).origin);
}
Vector3 StudyCheck::carry(int bone, const Vector3 &v_rest) const { return Bw(bone).xform(R0[bone].transposed().xform(v_rest)); }
Basis StudyCheck::Rrel_now(int p, int c) const { return Bw(p).transposed() * Bw(c); }
Basis StudyCheck::Rrel_rest(int p, int c) const { return R0[p].transposed() * R0[c]; }

// rest-relative rotation of child against parent, in the parent's bone frame, decomposed on body axes carried by it
static void decompose(const Basis &D, const Basis &Rp0, const Vector3 &F0, const Vector3 &L0, const Vector3 &U0,
		float &flex, float &side, float &twist) {
	const Vector3 f = Rp0.transposed().xform(F0), l = Rp0.transposed().xform(L0), u = Rp0.transposed().xform(U0);
	Vector3 sw;
	swing_twist(D.get_rotation_quaternion(), u, twist, sw);
	flex = sw.dot(l);  // + forward (rotation about the body's left takes up toward forward)
	side = sw.dot(f);
}

void StudyCheck::measure(Sample &s, bool rest_pass) {
	const Vector3 F0(0, 0, 1), L0(1, 0, 0), U0(0, 1, 0), up(0, 1, 0);
	for (int c = 0; c < C_COUNT; c++) s.ch[c] = 0;
	const Vector3 pf = carry(H, F0), pl = carry(H, L0), pu = carry(H, U0);
	for (int sd = 0; sd < 2; sd++) {
		const float side_sign = sd == 0 ? 1.0f : -1.0f;
		const Vector3 hip = Pw(UP[sd]), knee = Pw(LO[sd]), ank = Pw(FOOT[sd]);
		const Vector3 t = nrm(knee - hip), sv = nrm(ank - knee);
		// 1.3 knee
		const Vector3 a = Bw(UP[sd]).xform(hinge_up[sd]);
		const Vector3 tp = nrm(t - a * t.dot(a)), sp = nrm(sv - a * sv.dot(a));
		const float mag = deg(std::acos(clampf(tp.dot(sp), -1, 1)));
		const Vector3 f_t = nrm(a.cross(t)) * ft_sign[sd];
		const float sgn = (ank - knee).dot(f_t) < 0 ? 1.0f : -1.0f;
		s.ch[C_KNEE_FLEX + sd] = sgn * mag;
		s.ch[C_KNEE_VARUS + sd] = deg(std::asin(clampf(sv.dot(a), -1, 1))) * (sd == 0 ? -1.0f : 1.0f);
		{
			const Basis D = Rrel_now(UP[sd], LO[sd]) * Rrel_rest(UP[sd], LO[sd]).transposed();
			const Vector3 d = nrm(R0[UP[sd]].transposed().xform(P0[FOOT[sd]] - P0[LO[sd]]));
			float tw;
			Vector3 swv;
			swing_twist(D.get_rotation_quaternion(), d, tw, swv);
			s.ch[C_KNEE_TWIST + sd] = tw;
		}
		// sole points (1.1)
		const Basis bf = use_rest ? R0[FOOT[sd]] : skc->get_bone_global_pose(FOOT[sd]).basis;
		for (int k = 0; k < 4; k++) {
			if (use_rest) {
				const int b = k < 3 ? FOOT[sd] : TOE[sd];
				s.sole[sd][k] = sk_rest_xform(b, sole_off[sd][k]) * unit;
			} else {
				const int b = k < 3 ? FOOT[sd] : TOE[sd];
				s.sole[sd][k] = skw.xform(skc->get_bone_global_pose(b).xform(sole_off[sd][k]));
			}
		}
		(void)bf;
		const Vector3 heel = s.sole[sd][0], bi = s.sole[sd][1], bo = s.sole[sd][2], tip = s.sole[sd][3];
		const Vector3 ball = (bi + bo) * 0.5f;
		const Vector3 F = nrm(ball - heel);
		const Vector3 U = nrm((bi - heel).cross(bo - heel) * u_sign[sd]);
		s.footF[sd] = F;
		s.footU[sd] = U;
		// 1.4 ankle
		const Vector3 a_s = Bw(LO[sd]).xform(hinge_lo[sd]);
		const Vector3 f_s = nrm(sv.cross(a_s)) * fs_sign[sd];
		s.shinF[sd] = f_s;
		const Vector3 Fp = F - a_s * F.dot(a_s);
		s.ch[C_DORSI + sd] = deg(std::atan2(Fp.dot(-sv), Fp.dot(f_s)));
		{
			const Vector3 Fref = carry(LO[sd], F_rest[sd]);
			const Vector3 Fs_p = nrm(F - sv * F.dot(sv)), ref_p = nrm(Fref - sv * Fref.dot(sv));
			const float ang = deg(std::atan2(ref_p.cross(Fs_p).dot(sv), ref_p.dot(Fs_p)));
			s.ch[C_FOOT_ABD + sd] = ang * (sd == 0 ? -1.0f : 1.0f); // + toes out
			const Vector3 Uref = carry(LO[sd], U_rest[sd]);
			const Vector3 U2 = arcq(Fref, F).xform(Uref);
			// lateral of the foot's own reference frame (perpendicular to F and to the shin-carried sole normal),
			// pointing to the body's outside; the pelvis only gives the sign
			const Vector3 lat = carry(H, L0 * side_sign);
			Vector3 latF = nrm(F.cross(U2));
			if (latF.dot(lat) < 0) latF = -latF;
			const Vector3 Uo = U - F * F.dot(U);
			s.ch[C_INV + sd] = deg(std::atan2(Uo.dot(latF), Uo.dot(U2))); // + sole turned in (on the outer edge)
		}
		{
			// the toe joint's own bend: direction from the toe joint to the tip, in the foot's sagittal plane
			const Vector3 side = nrm(F.cross(U));
			Vector3 T = tip - Pw(TOE[sd]);
			T = nrm(T - side * T.dot(side));
			s.ch[C_TOE + sd] = deg(std::atan2(T.dot(U), T.dot(F)));
		}
		// 1.5 hip
		{
			const Vector3 lat = sd == 0 ? pl : -pl;
			s.ch[C_HIP_FLEX + sd] = deg(std::atan2(t.dot(pf), -t.dot(pu)));
			s.ch[C_HIP_ABD + sd] = deg(std::asin(clampf(t.dot(lat), -1, 1)));
			const Vector3 t0 = nrm(P0[LO[sd]] - P0[UP[sd]]);
			const Vector3 a0 = nrm(L0 - t0 * L0.dot(t0));
			const Vector3 ft0 = nrm(a0.cross(t0)) * ft_sign[sd];
			const Vector3 fref = carry(H, ft0), d0c = carry(H, t0);
			const Vector3 fref2 = arcq(d0c, t).xform(fref);
			Vector3 latp = nrm(t.cross(fref2));
			if (latp.dot(lat) < 0) latp = -latp;
			const Vector3 ftp = f_t - t * f_t.dot(t);
			s.ch[C_HIP_ROT + sd] = deg(std::atan2(ftp.dot(latp), ftp.dot(fref2))); // + knee turned out
		}
		// shoulder, elbow, forearm, wrist
		{
			const Vector3 cf = carry(CHEST, F0), cl = carry(CHEST, L0), cu = carry(CHEST, U0);
			const Vector3 sh = Pw(ARM[sd]), el = Pw(FARM[sd]), wr = Pw(HAND[sd]);
			const Vector3 u = nrm(el - sh), fa = nrm(wr - el);
			const float elev = deg(std::acos(clampf(u.dot(-cu), -1, 1)));
			const Vector3 latc = sd == 0 ? cl : -cl;
			const float fw = u.dot(cf), la = u.dot(latc);
			s.sh_fw[sd] = fw;
			s.sh_la[sd] = la;
			s.ch[C_SH_ELEV + sd] = elev;
			s.ch[C_SH_ACROSS + sd] = deg(std::asin(clampf(std::max(0.0f, -la), 0, 1))); // past the body's midline
			{
				const Basis D = Rrel_now(CHEST, ARM[sd]) * Rrel_rest(CHEST, ARM[sd]).transposed();
				const Vector3 d = nrm(R0[CHEST].transposed().xform(P0[FARM[sd]] - P0[ARM[sd]]));
				float tw;
				Vector3 swv;
				swing_twist(D.get_rotation_quaternion(), d, tw, swv);
				s.ch[C_SH_TWIST + sd] = tw * (sd == 0 ? 1.0f : -1.0f); // + internal
			}
			const Vector3 e = Bw(ARM[sd]).xform(elbow_hinge[sd]);
			s.ch[C_ELBOW + sd] = deg(std::atan2(u.cross(fa).dot(e), u.dot(fa)));
			{
				const Basis D = Rrel_now(ARM[sd], HAND[sd]) * Rrel_rest(ARM[sd], HAND[sd]).transposed();
				const Vector3 d = nrm(R0[ARM[sd]].transposed().xform(P0[HAND[sd]] - P0[FARM[sd]]));
				float tw;
				Vector3 swv;
				swing_twist(D.get_rotation_quaternion(), d, tw, swv);
				s.ch[C_FARM_TW + sd] = tw;
			}
			{
				const Basis D = Rrel_now(FARM[sd], HAND[sd]) * Rrel_rest(FARM[sd], HAND[sd]).transposed();
				const Vector3 fa0 = nrm(P0[HAND[sd]] - P0[FARM[sd]]);
				const Basis Ri = R0[FARM[sd]].transposed();
				float tw;
				Vector3 swv;
				swing_twist(D.get_rotation_quaternion(), nrm(Ri.xform(fa0)), tw, swv);
				const Vector3 h = nrm(Ri.xform(fa0.cross(palm_n0[sd])));
				const Vector3 nl = Ri.xform(palm_n0[sd]);
				const float rs = palm_n0[sd].cross(fa0).dot(thumb0[sd]) > 0 ? 1.0f : -1.0f;
				s.ch[C_WRIST_F + sd] = swv.dot(h);       // + toward the palm
				s.ch[C_WRIST_D + sd] = swv.dot(nl) * rs; // + radial (toward the thumb)
			}
		}
	}
	// spine and neck (1.5)
	{
		float f, sd, tw;
		decompose(Rrel_now(H, MID) * Rrel_rest(H, MID).transposed(), R0[H], F0, L0, U0, f, sd, tw);
		s.ch[C_LUMB_F] = f; s.ch[C_LUMB_S] = sd; s.ch[C_LUMB_T] = tw;
		decompose(Rrel_now(MID, CHEST) * Rrel_rest(MID, CHEST).transposed(), R0[MID], F0, L0, U0, f, sd, tw);
		s.ch[C_THOR_F] = f; s.ch[C_THOR_S] = sd; s.ch[C_THOR_T] = tw;
		decompose(Rrel_now(CHEST, HEAD) * Rrel_rest(CHEST, HEAD).transposed(), R0[CHEST], F0, L0, U0, f, sd, tw);
		s.ch[C_NECK_F] = f; s.ch[C_NECK_S] = sd; s.ch[C_NECK_T] = tw;
	}
	// rest-relative
	if (!rest_pass)
		for (int c = 0; c < C_COUNT; c++) s.ch[c] -= rest_ch[c];

	// pelvis yaw, frames, trunk lean, head
	s.pf_h = nrm(flat(pf));
	if (s.pf_h.length_squared() < 0.5f) s.pf_h = Vector3(0, 0, 1);
	s.pl_h = up.cross(s.pf_h);
	{
		const float raw = deg(std::atan2(s.pf_h.x, s.pf_h.z));
		if (!yaw_init || rest_pass) { yaw_unwrapped = raw; yaw_init = !rest_pass; }
		else {
			float d = raw - yaw_prev_raw;
			while (d > 180) d -= 360;
			while (d < -180) d += 360;
			yaw_unwrapped += d;
		}
		yaw_prev_raw = raw;
		s.ch[C_PELVIS_YAW] = yaw_unwrapped;
	}
	s.pc = (Pw(UP[0]) + Pw(UP[1])) * 0.5f;
	s.neck = Pw(NECK);
	{
		const Vector3 tr = nrm(s.neck - s.pc);
		s.trunk_f = deg(std::atan2(tr.dot(s.pf_h), tr.y));
		s.trunk_s = deg(std::atan2(tr.dot(s.pl_h), tr.y));
		const Vector3 th = flat(tr);
		const float ang = deg(std::atan2(th.length(), tr.y));
		const Vector3 dir = nrm(th);
		s.trunk_w = Vector2(dir.x, dir.z) * ang;
		const Vector3 hl = carry(HEAD, L0), hf = carry(HEAD, F0);
		s.head_roll = deg(std::asin(clampf(hl.y, -1, 1)));
		s.head_pitch = deg(std::asin(clampf(hf.y, -1, 1)));
	}
	// centre of mass (1.6, de Leva)
	{
		const Vector3 top = HEADTOP >= 0 ? Pw(HEADTOP) : Pw(HEAD) + carry(HEAD, U0) * 0.2f;
		Vector3 c = (s.neck + top) * 0.5f * 6.9f;
		c += (s.pc + (s.neck - s.pc) * 0.5f) * 43.5f;
		for (int sd = 0; sd < 2; sd++) {
			const Vector3 sh = Pw(ARM[sd]), el = Pw(FARM[sd]), wr = Pw(HAND[sd]), kn = Pw(MID1[sd]);
			c += (sh + (el - sh) * 0.58f) * 2.7f;
			c += (el + (wr - el) * 0.46f) * 1.6f;
			c += (wr + (kn - wr) * 0.79f) * 0.6f;
			const Vector3 hp = Pw(UP[sd]), k = Pw(LO[sd]), an = Pw(FOOT[sd]);
			c += (hp + (k - hp) * 0.41f) * 14.2f;
			c += (k + (an - k) * 0.44f) * 4.3f;
			c += (s.sole[sd][0] + (s.sole[sd][3] - s.sole[sd][0]) * 0.44f) * 1.4f;
		}
		s.com = c / 99.9f;
	}
}

Vector3 StudyCheck::sk_rest_xform(int b, const Vector3 &local) const {
	// rest global transform of bone b (with its scale) applied to a bone-local offset, in skeleton units
	return rest_xf[b].xform(local);
}

// ------------------------------------------------------------------------------------------------ contacts (1.7)
void StudyCheck::contacts(Skeleton3D *sk, Sample &s) {
	PhysicsDirectSpaceState3D *space = nullptr;
	Ref<World3D> w3 = sk->get_world_3d();
	if (w3.is_valid()) space = w3->get_direct_space_state();
	for (int sd = 0; sd < 2; sd++) {
		Vector3 nsum;
		int nn = 0;
		float dmin = 1e9f;
		for (int k = 0; k < 4; k++) {
			s.pt_contact[sd][k] = false;
			s.pt_dist[sd][k] = 1e9f;
			if (!space) continue;
			const Vector3 p = s.sole[sd][k];
			Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(p + Vector3(0, 0.5f, 0), p - Vector3(0, 0.5f, 0), ground_mask);
			Dictionary hit = space->intersect_ray(q);
			if (hit.is_empty()) continue;
			const Vector3 hp = hit["position"];
			const Vector3 hn = hit["normal"];
			const float d = p.y - hp.y;
			s.pt_dist[sd][k] = d;
			dmin = std::min(dmin, d);
			if (std::fabs(d) <= 0.01f) {
				s.pt_contact[sd][k] = true;
				nsum += hn;
				nn++;
			}
			if (nn == 0 && k == 3 && !hit.is_empty()) nsum = hn;
		}
		s.ground_n[sd] = nn > 0 ? nrm(nsum) : (nsum.length_squared() > 0 ? nrm(nsum) : Vector3(0, 1, 0));
		s.foot_contact[sd] = s.pt_contact[sd][0] || s.pt_contact[sd][1] || s.pt_contact[sd][2] || s.pt_contact[sd][3];
		s.heel_up[sd] = !s.pt_contact[sd][0] && (s.pt_contact[sd][1] || s.pt_contact[sd][2]);
		s.foot_dmin[sd] = dmin;
	}
}

// ------------------------------------------------------------------------------------------------ logging
static const char *KEY_RULES[] = {"KNEE_FLEX_MIN", "KNEE_FLEX_MAX", "KNEE_VARUS", "KNEE_TWIST", "ANKLE_DORSI",
	"ANKLE_PLANTAR", "ANKLE_INVERSION", "ANKLE_EVERSION", "FOOT_TWIST", "SOLE_ROLL", "HIP_ROTATION", "LEAN_MAX",
	"LEAN_MISMATCH", "TRUNK_LEAN", "TRUNK_BEND"};

void StudyCheck::violate(const std::string &id0, const std::string &side, float value, float limit, double at, int fr,
		const std::string &extra) {
	std::string id = id0;
	const float excess = std::fabs(value) - std::fabs(limit);
	if (role == "pre") {
		bool key = false;
		for (const char *k : KEY_RULES) key = key || id == k;
		if (!key) return;
		if (std::fabs(value - limit) <= 1.0f) return; // 9.3: the limiter may shave rounding (1 deg)
		id = "PRE_" + id;
	}
	Rule &r = rules[id];
	r.count++;
	const float ex = std::fabs(value - limit);
	if (r.worst_t < 0 || ex > std::fabs(r.worst - r.limit)) {
		r.worst = value;
		r.limit = limit;
		r.worst_t = at;
		r.worst_side = side;
	}
	(void)excess;
	int &lc = log_count[id];
	if (lc < log_limit) {
		lc++;
		char b[512];
		snprintf(b, sizeof b, "t=%.3f frame=%d %s side=%s value=%.3f limit=%.3f state=%s seed=%lld %s %s", at, fr,
				id.c_str(), side.c_str(), value, limit, last.state.c_str(), (long long)seed, label.c_str(), extra.c_str());
		log_lines.push_back(String(b));
	}
}

// ------------------------------------------------------------------------------------------------ per-frame rules
void StudyCheck::immediate_rules(Sample &s) {
	const char *SD[2] = {"L", "R"};
	auto V = [&](const char *id, int sd, float v, float lim) { violate(id, sd >= 0 ? SD[sd] : "", v, lim, s.t, s.frame); };
	for (int sd = 0; sd < 2; sd++) {
		const float kf = s.ch[C_KNEE_FLEX + sd];
		if (kf < -5) V("KNEE_FLEX_MIN", sd, kf, -5);
		if (kf > 155) V("KNEE_FLEX_MAX", sd, kf, 155);
		const float kv = s.ch[C_KNEE_VARUS + sd];
		if (std::fabs(kv) > 8) V("KNEE_VARUS", sd, kv, kv > 0 ? 8 : -8);
		const float tl = lerp_lim(kf, 20, 60, 5, 25), kt = s.ch[C_KNEE_TWIST + sd];
		if (std::fabs(kt) > tl) V("KNEE_TWIST", sd, kt, kt > 0 ? tl : -tl);
		const float dl = lerp_lim(kf, 15, 30, 25, 40), dr = s.ch[C_DORSI + sd];
		if (dr > dl) V("ANKLE_DORSI", sd, dr, dl);
		if (dr < -55) V("ANKLE_PLANTAR", sd, dr, -55);
		const float iv = s.ch[C_INV + sd];
		if (iv > 30) V("ANKLE_INVERSION", sd, iv, 30);
		if (iv < -15) V("ANKLE_EVERSION", sd, iv, -15);
		const float fa = s.ch[C_FOOT_ABD + sd];
		if (fa > 30) V("FOOT_TWIST", sd, fa, 30);
		if (fa < -20) V("FOOT_TWIST", sd, fa, -20);
		if (s.ch[C_TOE + sd] > 80) V("TOE_BEND", sd, s.ch[C_TOE + sd], 80);
		const float hf = s.ch[C_HIP_FLEX + sd], hl = lerp_lim(kf, 20, 60, 90, 125);
		if (hf > hl) V("HIP_FLEX_COUPLED", sd, hf, hl);
		if (hf < -30) V("HIP_EXT", sd, hf, -30);
		const float ha = s.ch[C_HIP_ABD + sd];
		if (ha > 45) V("HIP_ABD", sd, ha, 45);
		if (ha < -30) V("HIP_ABD", sd, ha, -30);
		const float hr = s.ch[C_HIP_ROT + sd];
		if (hr > 50) V("HIP_ROTATION", sd, hr, 50);
		if (hr < -40) V("HIP_ROTATION", sd, hr, -40);
		// shoulder (cone: 180 front and side, 60 straight behind; across the body 40)
		{
			const float el = s.ch[C_SH_ELEV + sd];
			float lim = 180;
			if (s.sh_fw[sd] < 0) {
				const float h = std::sqrt(s.sh_fw[sd] * s.sh_fw[sd] + s.sh_la[sd] * s.sh_la[sd]);
				const float lat_share = h > 1e-4f ? std::fabs(s.sh_la[sd]) / h : 1.0f;
				lim = 60 + 120 * (s.sh_la[sd] > 0 ? lat_share : 0.0f);
			}
			if (el > lim) V("SHOULDER_CONE", sd, el, lim);
			if (s.ch[C_SH_ACROSS + sd] > 40) V("SHOULDER_CONE", sd, s.ch[C_SH_ACROSS + sd], 40);
			const float st = s.ch[C_SH_TWIST + sd];
			if (st > 70) V("SHOULDER_TWIST", sd, st, 70);
			if (st < -90) V("SHOULDER_TWIST", sd, st, -90);
		}
		const float eb = s.ch[C_ELBOW + sd];
		if (eb < -10) V("ELBOW", sd, eb, -10);
		if (eb > 150) V("ELBOW", sd, eb, 150);
		const float ft = s.ch[C_FARM_TW + sd];
		if (std::fabs(ft) > 85) V("FOREARM_TWIST", sd, ft, ft > 0 ? 85 : -85);
		const float wf = s.ch[C_WRIST_F + sd], wd = s.ch[C_WRIST_D + sd];
		if (wf > 80) V("WRIST", sd, wf, 80);
		if (wf < -90) V("WRIST", sd, wf, -90);
		if (wd > 20) V("WRIST", sd, wd, 20);
		if (wd < -35) V("WRIST", sd, wd, -35);
		// fingers (2.1): never past -5; 90 / 110 / 90
		if (!use_rest) {
			const float lim3[3] = {90, 110, 90};
			for (int f = 0; f < 4; f++)
				for (int j = 0; j < 3; j++) {
					const int b = FING[sd][f][j];
					if (b < 0) continue;
					const int p = j == 0 ? HAND[sd] : FING[sd][f][j - 1];
					if (p < 0) continue;
					const Basis D = Rrel_now(p, b) * Rrel_rest(p, b).transposed();
					const int c = j < 2 ? FING[sd][f][j + 1] : -1;
					const Vector3 dir0 = c >= 0 ? nrm(P0[c] - P0[b]) : nrm(P0[b] - P0[p]);
					const Basis Ri = R0[p].transposed();
					float tw;
					Vector3 swv;
					swing_twist(D.get_rotation_quaternion(), nrm(Ri.xform(dir0)), tw, swv);
					const float bend = swv.dot(nrm(Ri.xform(dir0.cross(palm_n0[sd]))));
					if (bend < -5 || bend > lim3[j]) V("FINGERS", sd, bend, bend < -5 ? -5 : lim3[j]);
				}
		}
	}
	// spine, neck
	if (s.ch[C_LUMB_F] > 50) V("SPINE_LUMBAR", -1, s.ch[C_LUMB_F], 50);
	if (s.ch[C_LUMB_F] < -25) V("SPINE_LUMBAR", -1, s.ch[C_LUMB_F], -25);
	if (std::fabs(s.ch[C_LUMB_S]) > 25) V("SPINE_LUMBAR", -1, s.ch[C_LUMB_S], 25);
	if (std::fabs(s.ch[C_LUMB_T]) > 10) V("SPINE_LUMBAR", -1, s.ch[C_LUMB_T], 10);
	if (s.ch[C_THOR_F] > 30) V("SPINE_THORACIC", -1, s.ch[C_THOR_F], 30);
	if (s.ch[C_THOR_F] < -20) V("SPINE_THORACIC", -1, s.ch[C_THOR_F], -20);
	if (std::fabs(s.ch[C_THOR_T]) > 35) V("SPINE_THORACIC", -1, s.ch[C_THOR_T], 35);
	if (s.ch[C_NECK_F] > 50) V("NECK", -1, s.ch[C_NECK_F], 50);
	if (s.ch[C_NECK_F] < -60) V("NECK", -1, s.ch[C_NECK_F], -60);
	if (std::fabs(s.ch[C_NECK_T]) > 80) V("NECK", -1, s.ch[C_NECK_T], 80);
	if (std::fabs(s.ch[C_NECK_S]) > 45) V("NECK", -1, s.ch[C_NECK_S], 45);

	// bone lengths (6.12)
	for (size_t i = 0; i < bone_pairs.size(); i++) {
		const float l = Pw(bone_pairs[i].first).distance_to(Pw(bone_pairs[i].second));
		if (std::fabs(l - rest_len[i]) > 0.0005f) violate("BONE_LENGTH", "", l, rest_len[i], s.t, s.frame);
	}

	// knee over the toes (2.4), contact rules (1.7, 2.1 sole, 4.6 spin)
	for (int sd = 0; sd < 2; sd++) {
		if (s.foot_contact[sd] && s.ch[C_KNEE_FLEX + sd] > 20) {
			const Vector3 a = nrm(flat(s.shinF[sd])), b = nrm(flat(s.footF[sd]));
			if (a.length_squared() > 0.5f && b.length_squared() > 0.5f) {
				const float ang = deg(std::acos(clampf(a.dot(b), -1, 1)));
				if (ang > 35) V("KNEE_OVER_TOE", sd, ang, 35);
			}
		}
		if (!contact_rules) continue;
		int nin = 0;
		for (int k = 0; k < 4; k++) {
			const bool c = s.pt_contact[sd][k];
			nin += c ? 1 : 0;
			if (s.pt_dist[sd][k] < -0.01f && s.pt_dist[sd][k] > -0.45f) V("CONTACT_SINK", sd, s.pt_dist[sd][k], -0.01f);
			if (c && !prev_pt[sd][k]) pt_start[sd][k] = s.sole[sd][k];
			if (c && prev_pt[sd][k]) {
				const float d = flat(s.sole[sd][k] - pt_start[sd][k]).length();
				if (d > 0.01f) violate("FOOT_SLIDE", SD[sd], d, 0.01f, s.t, s.frame, k == 0 ? "point=heel" : k == 3 ? "point=tip" : "point=ball");
			}
			prev_pt[sd][k] = c;
		}
		if (s.has_intent && s.planted_intent[sd] && s.foot_dmin[sd] > 0.01f && s.foot_dmin[sd] < 1e8f)
			V("CONTACT_HOVER", sd, s.foot_dmin[sd], 0.01f);
		if (nin >= 2) {
			const Vector3 n = s.ground_n[sd], F = s.footF[sd], U = s.footU[sd];
			const Vector3 latn = nrm(n.cross(F));
			const float roll = deg(std::asin(clampf(U.dot(latn), -1, 1)));
			if (std::fabs(roll) > 5) V("SOLE_ROLL", sd, roll, roll > 0 ? 5 : -5);
			if (s.pt_contact[sd][0] && (s.pt_contact[sd][1] || s.pt_contact[sd][2])) {
				const float pitch = deg(std::asin(clampf(F.dot(n), -1, 1)));
				if (std::fabs(pitch) > 5) violate("SOLE_ROLL", SD[sd], pitch, pitch > 0 ? 5.0f : -5.0f, s.t, s.frame, "axis=pitch");
			}
		}
		const bool flatc = s.pt_contact[sd][0] && (s.pt_contact[sd][1] || s.pt_contact[sd][2]);
		const float yaw = deg(std::atan2(s.footF[sd].x, s.footF[sd].z));
		if (flatc && !flat_prev[sd]) flat_yaw0[sd] = yaw;
		if (flatc && flat_prev[sd]) {
			float d = yaw - flat_yaw0[sd];
			while (d > 180) d -= 360;
			while (d < -180) d += 360;
			if (std::fabs(d) > 5) V("FOOT_SPIN", sd, d, d > 0 ? 5 : -5);
		}
		flat_prev[sd] = flatc;
	}

	// trunk lean (3.2), in locomotion
	if (s.loco && physics_rules) {
		if (s.trunk_f > 30) V("TRUNK_LEAN", -1, s.trunk_f, 30);
		if (s.trunk_f < -15) V("TRUNK_LEAN", -1, s.trunk_f, -15);
		if (std::fabs(s.trunk_s) > 25) V("TRUNK_LEAN", -1, s.trunk_s, s.trunk_s > 0 ? 25 : -25);
	}

	// limbs through the body (2.4) and the world (6.12): capsules
	{
		struct Cap { Vector3 a, b; float r; };
		auto seg_dist = [](const Vector3 &p1, const Vector3 &q1, const Vector3 &p2, const Vector3 &q2) -> float {
			const Vector3 d1 = q1 - p1, d2 = q2 - p2, r = p1 - p2;
			const float a = d1.dot(d1), e = d2.dot(d2), f = d2.dot(r);
			float s1, t1;
			if (a <= 1e-9f && e <= 1e-9f) return r.length();
			if (a <= 1e-9f) { s1 = 0; t1 = clampf(f / e, 0, 1); }
			else {
				const float c = d1.dot(r);
				if (e <= 1e-9f) { t1 = 0; s1 = clampf(-c / a, 0, 1); }
				else {
					const float b = d1.dot(d2), den = a * e - b * b;
					s1 = den != 0 ? clampf((b * f - c * e) / den, 0, 1) : 0;
					t1 = (b * s1 + f) / e;
					if (t1 < 0) { t1 = 0; s1 = clampf(-c / a, 0, 1); }
					else if (t1 > 1) { t1 = 1; s1 = clampf((b - c) / a, 0, 1); }
				}
			}
			return ((p1 + d1 * s1) - (p2 + d2 * t1)).length();
		};
		Cap trunk{s.pc, s.neck, 0.14f};
		Cap thigh[2], shin[2], uarm[2], farm[2], hand[2];
		for (int sd = 0; sd < 2; sd++) {
			thigh[sd] = {Pw(UP[sd]), Pw(LO[sd]), 0.07f};
			shin[sd] = {Pw(LO[sd]), Pw(FOOT[sd]), 0.05f};
			uarm[sd] = {Pw(ARM[sd]), Pw(FARM[sd]), 0.05f};
			farm[sd] = {Pw(FARM[sd]), Pw(HAND[sd]), 0.04f};
			hand[sd] = {Pw(HAND[sd]), Pw(MID1[sd]), 0.04f};
		}
		auto pen = [&](const Cap &x, const Cap &y) { return x.r + y.r - seg_dist(x.a, x.b, y.a, y.b); };
		auto chk = [&](const char *what, const Cap &x, const Cap &y) {
			const float p = pen(x, y);
			if (p > 0.01f) violate("SELF_INTERSECT", what, p, 0.01f, s.t, s.frame);
		};
		for (int sd = 0; sd < 2; sd++) {
			chk(sd == 0 ? "forearmL-trunk" : "forearmR-trunk", farm[sd], trunk);
			chk(sd == 0 ? "handL-trunk" : "handR-trunk", hand[sd], trunk);
			chk(sd == 0 ? "handL-forearmR" : "handR-forearmL", hand[sd], farm[1 - sd]);
		}
		chk("forearm-forearm", farm[0], farm[1]);
		chk("hand-hand", hand[0], hand[1]);
		chk("thigh-thigh", thigh[0], thigh[1]);
		chk("shin-shin", shin[0], shin[1]);
		// world (mask 1|4|8), penetration beyond 1 cm
		PhysicsDirectSpaceState3D *space = nullptr;
		Ref<World3D> w3 = skc ? skc->get_world_3d() : Ref<World3D>();
		if (w3.is_valid()) space = w3->get_direct_space_state();
		if (space && contact_rules) {
			const Vector3 headc = Pw(HEAD) + carry(HEAD, Vector3(0, 1, 0)) * 0.1f;
			Cap all[11] = {trunk, thigh[0], thigh[1], shin[0], shin[1], uarm[0], uarm[1], farm[0], farm[1],
				{headc, headc, 0.1f}, {s.pc, s.pc, 0.12f}};
			const char *nm[11] = {"trunk", "thighL", "thighR", "shinL", "shinR", "upperarmL", "upperarmR", "forearmL",
				"forearmR", "head", "pelvis"};
			for (int i = 0; i < 11; i++) {
				const Cap &c = all[i];
				const float r = c.r - 0.01f;
				const Vector3 ax = c.b - c.a;
				const float len = ax.length();
				Ref<PhysicsShapeQueryParameters3D> q;
				q.instantiate();
				Transform3D xf;
				xf.origin = (c.a + c.b) * 0.5f;
				if (len > 1e-4f) {
					Ref<CapsuleShape3D> cs;
					cs.instantiate();
					cs->set_radius(r);
					cs->set_height(len + 2 * r);
					xf.basis = Basis(arcq(Vector3(0, 1, 0), ax));
					q->set_shape(cs);
				} else {
					Ref<SphereShape3D> ss;
					ss.instantiate();
					ss->set_radius(r);
					q->set_shape(ss);
				}
				q->set_transform(xf);
				q->set_collision_mask(ground_mask);
				TypedArray<Dictionary> hits = space->intersect_shape(q, 1);
				if (hits.size() > 0) violate("WORLD_INTERSECT", nm[i], 1, 0, s.t, s.frame);
			}
		}
	}

	// the limiter's work (9.3, 10.2): compare with the pose before it, this frame
	if (role == "final" && peer && peer->last_frame() == frame) {
		const Sample &p = peer->last_sample();
		bool key = false, other = false;
		const int key_ch[] = {C_KNEE_FLEX, C_KNEE_VARUS, C_KNEE_TWIST, C_DORSI, C_INV, C_FOOT_ABD, C_HIP_ROT};
		for (int c = 0; c < C_PELVIS_YAW; c++) {
			const float d = std::fabs(p.ch[c] - s.ch[c]);
			bool isk = false;
			for (int k : key_ch) isk = isk || c == k || c == k + 1;
			if (isk && d > 1.0f) key = true;
			if (d > 0.1f) other = true;
		}
		if (std::fabs(p.trunk_f - s.trunk_f) > 1.0f || std::fabs(p.trunk_s - s.trunk_s) > 1.0f) key = true;
		if (key) { limiter_key_frames++; violate("LIMITER_ACTED", "", 1, 0, s.t, s.frame); }
		if (other) limiter_other_frames++;
	}
}

// ------------------------------------------------------------------------------------------------ fits (1.8)
float StudyCheck::value(const Sample &s, int channel, int comp) const {
	if (channel >= 0) return s.ch[channel];
	return comp == 0 ? s.com.x : comp == 1 ? s.com.y : s.com.z;
}

// quadratic least squares around buf[c] over +-40 ms (at least 2 samples each side); v0 value, v1 rate, v2 accel
bool StudyCheck::fit(size_t c, int channel, int comp, bool exclude_center, float &v0, float &v1, float &v2) const {
	const double tc = buf[c].t;
	// +-40 ms (1.8); at low frame rates at least 1 sample each side for rates (a 3-point fit is the exact second
	// difference: no smoothing a real snap away), 2 each side when the centre is left out (a pop check needs a curve)
	const int need = exclude_center ? 2 : 1;
	int lo = (int)c, hi = (int)c;
	int nl = 0, nr = 0;
	while (lo > 0 && (tc - buf[lo - 1].t <= 0.040 + 1e-6 || nl < need)) { lo--; nl++; }
	while (hi + 1 < (int)buf.size() && (buf[hi + 1].t - tc <= 0.040 + 1e-6 || nr < need)) { hi++; nr++; }
	if (nl < need || nr < need) return false;
	double S0 = 0, S1 = 0, S2 = 0, S3 = 0, S4 = 0, Y0 = 0, Y1 = 0, Y2 = 0;
	const float yc = value(buf[c], channel, comp);
	for (int i = lo; i <= hi; i++) {
		if (exclude_center && i == (int)c) continue;
		const double x = buf[i].t - tc;
		double y = value(buf[i], channel, comp);
		if (channel == C_PELVIS_YAW || channel == C_KNEE_TWIST || channel == C_KNEE_TWIST + 1) {
			(void)yc;
		}
		const double x2 = x * x;
		S0 += 1; S1 += x; S2 += x2; S3 += x2 * x; S4 += x2 * x2;
		Y0 += y; Y1 += y * x; Y2 += y * x2;
	}
	// solve [S0 S1 S2; S1 S2 S3; S2 S3 S4] [a b c] = [Y0 Y1 Y2]
	const double A[3][3] = {{S0, S1, S2}, {S1, S2, S3}, {S2, S3, S4}};
	const double det = A[0][0] * (A[1][1] * A[2][2] - A[1][2] * A[2][1]) - A[0][1] * (A[1][0] * A[2][2] - A[1][2] * A[2][0]) +
			A[0][2] * (A[1][0] * A[2][1] - A[1][1] * A[2][0]);
	if (std::fabs(det) < 1e-18) return false;
	auto solve = [&](int col) {
		double M[3][3];
		const double Y[3] = {Y0, Y1, Y2};
		for (int r = 0; r < 3; r++)
			for (int k = 0; k < 3; k++) M[r][k] = k == col ? Y[r] : A[r][k];
		return (M[0][0] * (M[1][1] * M[2][2] - M[1][2] * M[2][1]) - M[0][1] * (M[1][0] * M[2][2] - M[1][2] * M[2][0]) +
					   M[0][2] * (M[1][0] * M[2][1] - M[1][1] * M[2][0])) /
				det;
	};
	v0 = (float)solve(0);
	v1 = (float)solve(1);
	v2 = (float)(2.0 * solve(2));
	return true;
}

// ------------------------------------------------------------------------------------------------ delayed rules
void StudyCheck::evaluate(size_t i) {
	Sample &c = buf[i];
	c.evaluated = true;
	const char *SD[2] = {"L", "R"};
	// joint speeds (2.3) and discontinuities (1.8)
	for (int ch = 0; ch < C_COUNT; ch++) {
		float a, b, cc;
		if (!fit(i, ch, 0, false, a, b, cc)) continue;
		const float lim = speed_limit(ch);
		if (std::fabs(b) > lim) {
			violate(ch == C_PELVIS_YAW ? "PELVIS_YAW_SPEED" : "JOINT_SPEED", CH_NAMES[ch], b, b > 0 ? lim : -lim, c.t, c.frame);
		}
		if (fit(i, ch, 0, true, a, b, cc)) {
			const float r = c.ch[ch] - a;
			if (std::fabs(r) > 3.0f) violate("POSE_DISCONTINUITY", CH_NAMES[ch], r, r > 0 ? 3.0f : -3.0f, c.t, c.frame);
		}
	}
	// centre of mass: velocity, acceleration, discontinuity
	bool com_ok = true;
	Vector3 pred;
	for (int k = 0; k < 3; k++) {
		float a, b, cc;
		if (!fit(i, -1, k, false, a, b, cc)) { com_ok = false; break; }
		c.vel[k] = b;
		c.acc[k] = cc;
		float a2, b2, c2;
		if (fit(i, -1, k, true, a2, b2, c2)) pred[k] = a2; else pred[k] = value(c, -1, k);
	}
	if (!com_ok) return;
	{
		const float r = (c.com - pred).length();
		if (r > 0.005f) violate("POSE_DISCONTINUITY", "com", r, 0.005f, c.t, c.frame);
	}
	const bool any_contact = c.foot_contact[0] || c.foot_contact[1];
	const Vector3 ah = flat(c.acc);
	const float speed = flat(c.vel).length();
	if (c.loco) state_time[c.state] += c.dt; else state_time[c.state] += c.dt;

	if (physics_rules) {
		if (c.acc.y < -(G + 1.0f)) violate("COM_DOWN_GT_G", "", c.acc.y, -(G + 1.0f), c.t, c.frame);
		if (any_contact) {
			const float lim = mu * G + 1.0f;
			if (ah.length() > lim) violate("COM_ACCEL_H", "", ah.length(), lim, c.t, c.frame);
			const bool landing = c.t - last_land_t <= 0.1;
			const float vl = landing ? 80.0f : 30.0f;
			if (c.acc.y > vl) violate("COM_ACCEL_V", "", c.acc.y, vl, c.t, c.frame, landing ? "landing" : "");
		}
		// flight (3.5)
		if (!any_contact) {
			if (!in_flight) { in_flight = true; flight_pts.clear(); flight_t0 = c.t; }
			flight_pts.push_back({c.t, c.com});
			flight_acc.push_back({c.t, ah.length()});
			if (c.loco && speed > 0.3f && speed < 1.8f) {
				walk_flight_t += c.dt;
				if (walk_flight_t > 0.020 && walk_flight_t - c.dt <= 0.020) violate("WALK_FLIGHT", "", (float)walk_flight_t, 0.020f, c.t, c.frame);
			}
		} else {
			walk_flight_t = 0;
			if (in_flight) {
				in_flight = false;
				last_land_t = c.t;
				const double t_end = c.t;
				if (flight_pts.size() >= 3) {
					// least squares p(t) = p0 + v0 t - g t^2 / 2 (vertical), p0 + v0 t (horizontal)
					double S0 = 0, S1 = 0, S2 = 0;
					Vector3 Y0, Y1;
					for (auto &fp : flight_pts) {
						const double x = fp.first - flight_t0;
						const Vector3 y = fp.second + Vector3(0, (float)(0.5 * G * x * x), 0);
						S0 += 1; S1 += x; S2 += x * x;
						Y0 += y; Y1 += y * (float)x;
					}
					const double det = S0 * S2 - S1 * S1;
					if (std::fabs(det) > 1e-12) {
						const Vector3 p0 = (Y0 * (float)S2 - Y1 * (float)S1) / (float)det;
						const Vector3 v0 = (Y1 * (float)S0 - Y0 * (float)S1) / (float)det;
						float worst = 0;
						double wt = flight_t0;
						for (auto &fp : flight_pts) {
							const float x = (float)(fp.first - flight_t0);
							const Vector3 pp = p0 + v0 * x - Vector3(0, 0.5f * G * x * x, 0);
							const float e = (fp.second - pp).length();
							if (e > worst) { worst = e; wt = fp.first; }
						}
						if (worst > 0.01f) violate("FLIGHT_PARABOLA", "path", worst, 0.01f, wt, c.frame);
					}
				}
				for (auto &fa : flight_acc)
					if (fa.first - flight_t0 > 0.040 && t_end - fa.first > 0.040 && fa.second > 1.0f)
						violate("FLIGHT_PARABOLA", "accel_h", fa.second, 1.0f, fa.first, c.frame);
				flight_acc.clear();
			}
		}
	}

	// whole-body lean (1.6, 3.2): centre of pressure from the sole points
	Vector3 cop_f[2];
	bool cf[2] = {false, false};
	for (int sd = 0; sd < 2; sd++) {
		if (!c.foot_contact[sd]) continue;
		cf[sd] = true;
		Vector3 balls;
		int nb = 0;
		for (int k = 1; k <= 3; k++)
			if (c.pt_contact[sd][k]) { balls += c.sole[sd][k]; nb++; }
		if (c.pt_contact[sd][0] && nb > 0) cop_f[sd] = (c.sole[sd][0] + balls / (float)nb) * 0.5f;
		else if (c.pt_contact[sd][0]) cop_f[sd] = c.sole[sd][0];
		else cop_f[sd] = balls / (float)nb;
	}
	c.lean_valid = false;
	if (cf[0] || cf[1]) {
		Vector3 cop;
		if (cf[0] && cf[1]) {
			// double support: weight moves linearly from the back foot (earlier contact) to the front one
			int j0 = (int)i, j1 = (int)i;
			while (j0 > 0 && buf[j0 - 1].foot_contact[0] && buf[j0 - 1].foot_contact[1]) j0--;
			while (j1 + 1 < (int)buf.size() && buf[j1 + 1].foot_contact[0] && buf[j1 + 1].foot_contact[1]) j1++;
			const bool bounded = j0 > 0 && j1 + 1 < (int)buf.size();
			float wfront = 0.5f;
			int front = 0;
			if (bounded) {
				// the front foot is the one that touched down at the start of the double support
				front = buf[j0 - 1].foot_contact[0] ? 1 : 0;
				const double span = buf[j1].t - buf[j0].t;
				wfront = span > 1e-6 ? (float)((c.t - buf[j0].t) / span) : 0.5f;
			}
			cop = cop_f[front] * wfront + cop_f[1 - front] * (1.0f - wfront);
		} else cop = cf[0] ? cop_f[0] : cop_f[1];
		const Vector3 v = c.com - cop;
		if (v.y > 0.2f) {
			const Vector3 h = flat(v);
			const float ang = deg(std::atan2(h.length(), v.y));
			const Vector3 d = nrm(h);
			c.lean_wb = Vector2(d.x, d.z) * ang;
			c.lean_valid = true;
			const float den = G + c.acc.y;
			const float ea = deg(std::atan2(ah.length(), std::max(den, 0.1f)));
			const Vector3 ed = nrm(ah);
			const Vector2 exp(ed.x * ea, ed.z * ea);
			if (physics_rules && c.loco) {
				const float mm = (c.lean_wb - exp).length();
				if (mm > 10) violate("LEAN_MISMATCH", "frame", mm, 10, c.t, c.frame);
			}
		}
	}

	// head level (2.4): roll
	if (physics_rules && c.loco && any_contact && speed > 0.5f) {
		const float om = step_omega_now(i);
		const bool turning = std::fabs(om) > 15.0f;
		const float lim = turning ? std::min(5.0f, 0.5f * std::fabs(c.trunk_s) + 1.0f) : 5.0f;
		if (std::fabs(c.head_roll) > lim) violate("HEAD_LEVEL", "roll", c.head_roll, c.head_roll > 0 ? lim : -lim, c.t, c.frame);
	}

	// running double support on the level (4.3)
	{
		const bool level = c.ground_n[0].y > 0.996f && c.ground_n[1].y > 0.996f;
		if (c.foot_contact[0] && c.foot_contact[1] && speed > 2.5f && level && c.loco) {
			const double before = ds_cur;
			ds_cur += c.dt;
			ds_exempt = ds_exempt || ah.length() > 2.0f || std::fabs(step_omega_now(i)) > 30.0f;
			if (physics_rules && ds_cur > 0.020 && before <= 0.020 && !ds_exempt)
				violate("RUN_DOUBLE_SUPPORT", "", (float)ds_cur, 0.020f, c.t, c.frame);
		} else {
			ds_cur = 0;
			ds_exempt = false;
		}
	}

	// stops from a run (3.4)
	if (speed >= 2.5f) { run_seen_t = c.t; td_since_run = 0; }

	// touchdowns: step boundaries (contact rising edge that lasts at least 20 ms)
	bool td = false;
	for (int sd = 0; sd < 2; sd++) {
		if (c.foot_contact[sd] && !ev_prev_contact[sd]) {
			double held = 0;
			for (size_t j = i + 1; j < buf.size() && buf[j].foot_contact[sd]; j++) held = buf[j].t - c.t;
			if (held >= 0.015) td = true;
		}
		ev_prev_contact[sd] = c.foot_contact[sd];
	}
	if (td) {
		if (run_seen_t >= 0) td_since_run++;
		step_end(i, c.t);
	} else if (step.t0 >= 0 && c.t - step.t0 > 0.5 && speed < 0.3f) {
		step_end(i, c.t); // standing: judge the lean every 0.5 s
	} else if (step.t0 < 0) {
		step_end(i, c.t);
	}
	if (speed < 0.2f && run_seen_t >= 0) {
		if (physics_rules && c.loco && td_since_run < 2) violate("STOP_STEPS", "", (float)td_since_run, 2, c.t, c.frame);
		run_seen_t = -1;
	}
	// accumulate this frame into the current step
	step.n++;
	if (c.lean_valid) { step.lean_sum += c.lean_wb; step.n_lean++; }
	step.speed_min = std::min(step.speed_min, speed);
	step.speed_sum += speed;
	step.all_loco = step.all_loco && c.loco;
	step.trunk.push_back(c.trunk_w);
	step.trunk_t.push_back(c.t);
	step.trunk_f.push_back(c.frame);
	step.head_pitch_min = std::min(step.head_pitch_min, c.head_pitch);
	step.head_pitch_max = std::max(step.head_pitch_max, c.head_pitch);
	(void)SD;
}

float StudyCheck::step_omega_now(size_t i) const {
	// heading rate of the CoM's horizontal velocity (deg/s), from neighbours already fitted
	const Sample &c = buf[i];
	if (i == 0) return 0;
	const Sample &p = buf[i - 1];
	const Vector3 a = flat(p.vel), b = flat(c.vel);
	if (a.length() < 0.5f || b.length() < 0.5f || c.t - p.t <= 0) return 0;
	const float d = deg(std::atan2(a.cross(b).y, a.dot(b)));
	return -d / (float)(c.t - p.t);
}

void StudyCheck::step_end(size_t i, double t_td) {
	const Sample &c = buf[i];
	if (step.t0 >= 0 && physics_rules) {
		const double T = t_td - step.t0;
		const float vmean = step.n > 0 ? step.speed_sum / step.n : 0;
		if (T > 0.12 && T < 1.6 && step.all_loco && step.v0_set) {
			const Vector3 v0 = flat(step.v0), v1 = flat(c.vel);
			const Vector3 am = (v1 - v0) / (float)T;
			if (step.n_lean > 0) {
				const Vector2 lm = step.lean_sum / (float)step.n_lean;
				if (lm.length() > 35) violate("LEAN_MAX", "", lm.length(), 35, c.t, c.frame);
				const float ea = deg(std::atan(am.length() / G));
				const Vector3 ed = nrm(am);
				const Vector2 exp(ed.x * ea, ed.z * ea);
				const float mm = (lm - exp).length();
				if (mm > 5) violate("LEAN_MISMATCH", "step", mm, 5, c.t, c.frame);
				for (size_t k = 0; k < step.trunk.size(); k++) {
					const float b = (step.trunk[k] - lm).length();
					if (b > 15) violate("TRUNK_BEND", "", b, 15, step.trunk_t[k], step.trunk_f[k]);
				}
			}
			// turning (3.3) and cuts per plant
			if (v0.length() > 0.5f && v1.length() > 0.5f) {
				const float dh = std::fabs(deg(std::atan2(v0.cross(v1).y, v0.dot(v1))));
				if (step.speed_min > 2.0f) {
					const float om = dh / (float)T;
					const float l30 = deg(G * std::tan(rad(30)) / vmean), l20 = deg(G * std::tan(rad(20)) / vmean);
					if (om > l30 * 1.05f) violate("TURN_RATE", "cut", om, l30, c.t, c.frame);
					if (om > l20 * 1.05f) tight_steps++;
					else tight_steps = 0;
					if (tight_steps >= 3) violate("TURN_RATE", "sustained", om, l20, c.t, c.frame);
				} else tight_steps = 0;
				if (step.speed_min > 1.0f) {
					const float lim = deg(2.0f * std::asin(std::min(1.0f, 2.0f / (2.0f * vmean))));
					if (dh > lim) violate("CUT_ANGLE", "", dh, lim, c.t, c.frame);
				}
			}
			// head pitch over a stride (2.4)
			const float rng = std::max(step.head_pitch_max, prev_pitch_max) - std::min(step.head_pitch_min, prev_pitch_min);
			if (vmean > 0.5f && rng > 10 && prev_pitch_valid && std::fabs(step_omega_now(i)) < 15.0f)
				violate("HEAD_LEVEL", "pitch_range", rng, 10, c.t, c.frame);
			prev_pitch_min = step.head_pitch_min;
			prev_pitch_max = step.head_pitch_max;
			prev_pitch_valid = true;
		} else prev_pitch_valid = false;
	}
	step = StepAcc();
	step.t0 = t_td;
	step.v0 = c.vel;
	step.v0_set = true;
}

// ------------------------------------------------------------------------------------------------ main
void StudyCheck::_process_modification_with_delta(double p_delta) {
	Skeleton3D *sk = get_skeleton();
	if (!sk) return;
	skc = sk;
	if (!setup_done) {
		setup(sk);
		if (!setup_ok) {
			Rule &r = rules["SETUP_FAIL"];
			r.count++;
			log_lines.push_back(String("SETUP_FAIL ") + String(setup_error.c_str()));
		}
	}
	if (!setup_ok) return;
	skw = sk->get_global_transform_interpolated();
	t += p_delta;
	frame++;
	Sample s;
	s.t = t;
	s.dt = p_delta;
	s.frame = frame;
	measure(s, false);
	contacts(sk, s);
	s.state = "loco";
	if (controller) {
		if (controller->has_method("get_check_state")) s.state = String(controller->call("get_check_state")).utf8().get_data();
		if (controller->has_method("get_contact")) {
			s.has_intent = true;
			for (int sd = 0; sd < 2; sd++) s.planted_intent[sd] = (bool)controller->call("get_contact", sd);
		}
	}
	s.loco = s.state == "loco";
	last = s;
	immediate_rules(s);
	buf.push_back(s);
	while (next_eval < buf.size() && buf.back().t - buf[next_eval].t >= eval_delay) {
		evaluate(next_eval);
		next_eval++;
	}
	// keep 1.2 s
	while (!buf.empty() && next_eval > 0 && buf.back().t - buf.front().t > eval_delay + 0.7) {
		buf.pop_front();
		next_eval--;
	}
}

void StudyCheck::flush() {
	while (next_eval < buf.size()) {
		evaluate(next_eval);
		next_eval++;
	}
}

Dictionary StudyCheck::get_report() const {
	Dictionary d;
	d["role"] = String(role.c_str());
	d["frames"] = frame;
	d["seconds"] = t;
	d["setup_ok"] = setup_ok;
	d["setup_error"] = String(setup_error.c_str());
	Dictionary rr;
	int total = 0;
	for (auto &kv : rules) {
		Dictionary e;
		e["count"] = kv.second.count;
		e["worst"] = kv.second.worst;
		e["limit"] = kv.second.limit;
		e["t"] = kv.second.worst_t;
		e["side"] = String(kv.second.worst_side.c_str());
		rr[String(kv.first.c_str())] = e;
		total += kv.second.count;
	}
	d["rules"] = rr;
	d["violations"] = total;
	Dictionary st;
	for (auto &kv : state_time) st[String(kv.first.c_str())] = kv.second;
	d["state_seconds"] = st;
	d["limiter_key_frames"] = limiter_key_frames;
	d["limiter_other_frames"] = limiter_other_frames;
	return d;
}

float StudyCheck::get_channel(const String &name) const {
	const std::string n = name.utf8().get_data();
	for (int c = 0; c < C_COUNT; c++)
		if (n == CH_NAMES[c]) return last.ch[c];
	if (n == "trunk_f") return last.trunk_f;
	if (n == "trunk_s") return last.trunk_s;
	if (n == "head_roll") return last.head_roll;
	if (n == "head_pitch") return last.head_pitch;
	return NAN;
}

Dictionary StudyCheck::get_last() const {
	Dictionary d;
	for (int c = 0; c < C_COUNT; c++) d[CH_NAMES[c]] = last.ch[c];
	d["trunk_f"] = last.trunk_f;
	d["trunk_s"] = last.trunk_s;
	d["com"] = last.com;
	d["contact_L"] = last.foot_contact[0];
	d["contact_R"] = last.foot_contact[1];
	return d;
}

PackedVector3Array StudyCheck::get_sole_points() const {
	PackedVector3Array a;
	for (int s = 0; s < 2; s++)
		for (int k = 0; k < 4; k++) a.push_back(last.sole[s][k]);
	return a;
}

} // namespace study
