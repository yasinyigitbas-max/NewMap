// Lab A (procedural): the poser. See lab_poser.h. Study sections are named where each rule is applied.
#include "lab_poser.h"
#include "lab_player.h"

#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;
using namespace lab;

static const char *LEG_NAMES[2][4] = { { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "LeftToes" },
	{ "RightUpperLeg", "RightLowerLeg", "RightFoot", "RightToes" } };
static const char *ARM_NAMES[2][4] = { { "LeftShoulder", "LeftUpperArm", "LeftLowerArm", "LeftHand" },
	{ "RightShoulder", "RightUpperArm", "RightLowerArm", "RightHand" } };

bool LabPoser::bind_player(LabPlayer *p) {
	player = p;
	Skeleton3D *sk = get_skeleton();
	if (!sk) {
		UtilityFunctions::push_error("LabPoser: no skeleton parent");
		return false;
	}
	measure(sk);
	return bound;
}

void LabPoser::reset_metrics() {
	metrics = Metrics();
	last_contact[0] = last_contact[1] = -1;
	have_last = false;
}

void LabPoser::measure(Skeleton3D *sk) {
	int n = sk->get_bone_count();
	rest_g.resize(n);
	rest_l.resize(n);
	for (int i = 0; i < n; i++) {
		rest_g[i] = sk->get_bone_global_rest(i);
		rest_l[i] = sk->get_bone_rest(i);
		sk->set_bone_pose(i, rest_l[i]);
	}
	b_hips = sk->find_bone("Hips");
	b_spine[0] = sk->find_bone("Spine");
	b_spine[1] = sk->find_bone("Chest");
	b_spine[2] = sk->find_bone("UpperChest");
	b_neck = sk->find_bone("Neck");
	b_head = sk->find_bone("Head");
	bool ok = b_hips >= 0 && b_spine[0] >= 0 && b_spine[1] >= 0 && b_spine[2] >= 0 && b_neck >= 0 && b_head >= 0;
	for (int s = 0; s < 2; s++) {
		for (int k = 0; k < 4; k++) {
			b_leg[s][k] = sk->find_bone(LEG_NAMES[s][k]);
			b_arm[s][k] = sk->find_bone(ARM_NAMES[s][k]);
			ok = ok && b_leg[s][k] >= 0 && b_arm[s][k] >= 0;
		}
	}
	if (!ok) {
		UtilityFunctions::push_error("LabPoser: the skeleton lacks humanoid bone names (import with the bone map)");
		return;
	}
	// Fingers never straight (1.2 rule 7): more curl toward the little finger.
	const char *fnames[5] = { "Thumb", "Index", "Middle", "Ring", "Little" };
	const char *seg3[3] = { "Proximal", "Intermediate", "Distal" };
	const char *thumb3[3] = { "Metacarpal", "Proximal", "Distal" };
	float base[5] = { 8.0f, 17.0f, 24.0f, 32.0f, 44.0f };
	float segk[3] = { 1.0f, 1.25f, 0.8f };
	for (int s = 0; s < 2; s++) {
		fingers[s].clear();
		for (int f = 0; f < 5; f++) {
			for (int g = 0; g < 3; g++) {
				String nm = String(s == 0 ? "Left" : "Right") + fnames[f] + (f == 0 ? thumb3[g] : seg3[g]);
				int b = sk->find_bone(nm);
				if (b >= 0) fingers[s].push_back(Finger{ b, base[f] * segk[g] * DEG });
			}
		}
	}

	Vector3 hips = rest_g[b_hips].origin;
	dims_.hips_h = hips.y;
	for (int s = 0; s < 2; s++) {
		Vector3 hip = rest_g[b_leg[s][0]].origin, knee = rest_g[b_leg[s][1]].origin;
		Vector3 ank = rest_g[b_leg[s][2]].origin, ball = rest_g[b_leg[s][3]].origin;
		dims_.thigh[s] = hip.distance_to(knee);
		dims_.shin[s] = knee.distance_to(ank);
		dims_.hip_off[s] = hip - hips;
		dims_.ankle_h[s] = ank.y;
		rest_foot_yaw[s] = yaw_of(flat(ball - ank));
		Basis inv = yaw_basis(-rest_foot_yaw[s]);
		Vector3 bl = inv.xform(ball - Vector3(ank.x, 0, ank.z));
		dims_.ball[s] = Vector3(0, bl.y, bl.z);
		dims_.heel[s] = Vector3(0, 0, -0.06f);
		dims_.toe_len[s] = 0.06f;
		Vector3 sh = rest_g[b_arm[s][1]].origin, el = rest_g[b_arm[s][2]].origin, wr = rest_g[b_arm[s][3]].origin;
		dims_.shoulder_off[s] = sh - hips;
		dims_.uarm[s] = sh.distance_to(el);
		dims_.farm[s] = el.distance_to(wr);
	}
	// Heel and toe tip from the mesh: the sole vertices near each foot, in that foot's rest frame.
	TypedArray<Node> meshes = sk->find_children("*", "MeshInstance3D", true, false);
	for (int m = 0; m < meshes.size(); m++) {
		MeshInstance3D *mi = Object::cast_to<MeshInstance3D>(meshes[m]);
		if (!mi || mi->get_mesh().is_null()) continue;
		Ref<Mesh> mesh = mi->get_mesh();
		float zmin[2] = { 0, 0 }, zmax[2] = { 0, 0 };
		int cnt[2] = { 0, 0 };
		for (int sf = 0; sf < mesh->get_surface_count(); sf++) {
			Array arr = mesh->surface_get_arrays(sf);
			PackedVector3Array vs = arr[Mesh::ARRAY_VERTEX];
			for (int k = 0; k < vs.size(); k++) {
				Vector3 v = vs[k];
				if (v.y > 0.03f) continue;
				int s = v.x > 0 ? 0 : 1;
				Vector3 ank = rest_g[b_leg[s][2]].origin;
				Vector3 lv = yaw_basis(-rest_foot_yaw[s]).xform(v - Vector3(ank.x, 0, ank.z));
				if (std::fabs(lv.x) > 0.08f || lv.z < -0.25f || lv.z > 0.35f) continue;
				if (cnt[s] == 0) {
					zmin[s] = zmax[s] = lv.z;
				} else {
					zmin[s] = std::min(zmin[s], lv.z);
					zmax[s] = std::max(zmax[s], lv.z);
				}
				cnt[s]++;
			}
		}
		for (int s = 0; s < 2; s++) {
			if (cnt[s] > 10) {
				// the rig's toe bones sit at different places on the two feet, so the foot rolls over the anatomical
				// ball, 72 % of the sole's length from the heel (1.1 toes), measured on the mesh
				float len = zmax[s] - zmin[s];
				dims_.heel[s] = Vector3(0, 0, zmin[s] + 0.03f);
				dims_.ball[s] = Vector3(0, 0.03f, zmin[s] + 0.72f * len);
				dims_.toe_len[s] = std::max(0.02f, zmax[s] - dims_.ball[s].z);
			}
		}
	}
	for (int s = 0; s < 2; s++) {
		UtilityFunctions::print(String("LabPoser: ") + (s == 0 ? "left" : "right") + " thigh " + String::num(dims_.thigh[s], 3) +
				" shin " + String::num(dims_.shin[s], 3) + " ankle_h " + String::num(dims_.ankle_h[s], 3) + " ball_z " +
				String::num(dims_.ball[s].z, 3) + " heel_z " + String::num(dims_.heel[s].z, 3) + " toe " +
				String::num(dims_.toe_len[s], 3) + " rest foot yaw " + String::num(rest_foot_yaw[s] / DEG, 1) + " uarm " +
				String::num(dims_.uarm[s], 3) + " farm " + String::num(dims_.farm[s], 3));
	}
	bound = true;
}

// Two-bone IK (DECISIONS 1.2, 1.3): analytic, the middle joint goes toward the pole; soft reach above `soft` x length.
void LabPoser::solve_two_bone(const Vector3 &root, const Vector3 &target, float l1, float l2, const Vector3 &pole,
		Vector3 &mid, Vector3 &end, float soft) const {
	Vector3 dv = target - root;
	float dist = dv.length();
	Vector3 dir = dist > 1e-5f ? dv / dist : Vector3(0, -1, 0);
	float L = l1 + l2;
	float ds = soft * L;
	float d = dist;
	if (d > ds) d = ds + (L - ds) * (1.0f - std::exp(-(d - ds) / (L - ds)));
	d = std::max(d, std::fabs(l1 - l2) + 0.01f);
	float a = (l1 * l1 - l2 * l2 + d * d) / (2.0f * d);
	float h = std::sqrt(std::max(0.0f, l1 * l1 - a * a));
	Vector3 bend = pole - dir * pole.dot(dir);
	if (bend.length_squared() < 1e-8f) bend = Vector3(0, 0, 1) - dir * dir.z;
	bend.normalize();
	mid = root + dir * a + bend * h;
	end = root + dir * d;
}

void LabPoser::_process_modification_with_delta(double p_delta) {
	Skeleton3D *sk = get_skeleton();
	if (!sk || !bound || !player) return;
	float frac = (float)Engine::get_singleton()->get_physics_interpolation_fraction();
	if (Engine::get_singleton()->is_in_physics_frame()) frac = 1.0f;
	Targets T = player->interp_targets(frac);
	Transform3D sk_w = sk->get_global_transform_interpolated();
	Transform3D inv = sk_w.affine_inverse();
	Basis ib = inv.basis.orthonormalized();
	auto P = [&](const Vector3 &w) { return inv.xform(w); };
	auto D = [&](const Quaternion &q) { return ib * Basis(q); };

	int n = (int)rest_g.size();
	std::vector<Transform3D> G(n);
	std::vector<bool> set(n, false);

	// pelvis
	Basis Dh = D(T.hips_rot);
	G[b_hips] = Transform3D(Dh * rest_g[b_hips].basis, P(T.hips_pos));
	set[b_hips] = true;
	// spine: the trunk's turn and lean shared over three bones (1.1 lumbar/thoracic)
	Basis Dt = D(T.trunk_rot);
	Quaternion rel = (Dt * Dh.inverse()).get_rotation_quaternion();
	float share[3] = { 0.3f, 0.65f, 1.0f };
	int parent = b_hips;
	for (int k = 0; k < 3; k++) {
		Basis Dk = Basis(qslerp(Quaternion(), rel, share[k])) * Dh;
		int b = b_spine[k];
		G[b] = Transform3D(Dk * rest_g[b].basis, child_origin(G[parent], b));
		set[b] = true;
		parent = b;
	}
	// neck and head: stabilised look, the neck turns at most 75 deg from the chest (1.1 neck, 1.2 rule 6)
	Basis Dhead = D(T.head_rot);
	Quaternion hr = (Dhead * Dt.inverse()).get_rotation_quaternion();
	float ang = 2.0f * std::acos(clampf(std::fabs(hr.w), 0.0f, 1.0f));
	if (ang > 75.0f * DEG) hr = qslerp(Quaternion(), hr, 75.0f * DEG / ang);
	G[b_neck] = Transform3D(Basis(qslerp(Quaternion(), hr, 0.4f)) * Dt * rest_g[b_neck].basis, child_origin(G[b_spine[2]], b_neck));
	G[b_head] = Transform3D(Basis(hr) * Dt * rest_g[b_head].basis, child_origin(G[b_neck], b_head));
	set[b_neck] = set[b_head] = true;

	// legs
	Basis Dtoe_w[2];
	Vector3 body_left = Dh.xform(Vector3(1, 0, 0));
	for (int s = 0; s < 2; s++) {
		int bu = b_leg[s][0], bl = b_leg[s][1], bf = b_leg[s][2], bt = b_leg[s][3];
		Vector3 H = child_origin(G[b_hips], bu);
		Basis Fc = D(T.foot_rot[s]); // canonical foot frame (x left, y up, z fwd)
		Vector3 A = P(T.ankle[s]);
		Vector3 pole = ib.xform(T.knee_pole[s]);
		Vector3 knee, ank;
		Vector3 r_u = rest_g[bl].origin - rest_g[bu].origin, r_l = rest_g[bf].origin - rest_g[bl].origin;
		Vector3 rest_pole(0, 0, 1);
		for (int it = 0; it < 3; it++) {
			solve_two_bone(H, A, dims_.thigh[s], dims_.shin[s], pole, knee, ank, 0.985f);
			// ankle limit (1.2 rule 4): dorsiflexion past 20 deg lifts the heel about the ball
			Vector3 shin_up = (knee - ank).normalized();
			Vector3 ffwd = Fc.xform(Vector3(0, 0, 1));
			float rest_ang = angle_between(-r_l, yaw_basis(rest_foot_yaw[s]).xform(Vector3(0, 0, 1)));
			float dorsi = rest_ang - angle_between(shin_up, ffwd);
			if (dorsi <= 20.0f * DEG + 1e-3f) break;
			float extra = dorsi - 20.0f * DEG;
			Vector3 lat = Fc.xform(Vector3(1, 0, 0));
			// on the heel (loading) the foot slaps flat about the heel (2.1); otherwise the heel lifts about the ball
			Vector3 pv = T.contact[s] == 1 ? A + Fc.xform(Vector3(0, -dims_.ankle_h[s], dims_.heel[s].z))
										   : A + Fc.xform(Vector3(0, dims_.ball[s].y - dims_.ankle_h[s], dims_.ball[s].z));
			Basis R(lat, extra);
			Fc = R * Fc;
			A = pv + R.xform(A - pv);
		}
		Basis du = frame_delta(r_u, rest_pole, knee - H, pole);
		Basis dl = frame_delta(r_l, rest_pole, ank - knee, pole);
		G[bu] = Transform3D(du * rest_g[bu].basis, H);
		G[bl] = Transform3D(dl * rest_g[bl].basis, knee);
		Basis Df = Fc * yaw_basis(-rest_foot_yaw[s]);
		G[bf] = Transform3D(Df * rest_g[bf].basis, ank);
		Basis Dtoe = Basis(Fc.xform(Vector3(1, 0, 0)), -T.toe_bend[s]) * Df;
		Dtoe_w[s] = Basis(Fc.xform(Vector3(1, 0, 0)), -T.toe_bend[s]) * Fc;
		G[bt] = Transform3D(Dtoe * rest_g[bt].basis, child_origin(G[bf], bt));
		set[bu] = set[bl] = set[bf] = set[bt] = true;

		// metrics: joint ranges (1.1)
		float knee_flex = angle_between(knee - H, ank - knee) / DEG;
		Vector3 shin_up = (knee - ank).normalized();
		float rest_ang = angle_between(-r_l, yaw_basis(rest_foot_yaw[s]).xform(Vector3(0, 0, 1)));
		float dorsi = (rest_ang - angle_between(shin_up, Fc.xform(Vector3(0, 0, 1)))) / DEG;
		Vector3 th_l = Dh.inverse().xform((knee - H).normalized());
		float hip_flex = std::atan2(th_l.z, -th_l.y) / DEG;
		metrics.cur_hip[s] = hip_flex;
		metrics.cur_knee[s] = knee_flex;
		metrics.cur_ankle[s] = dorsi;
		metrics.knee_max_deg = std::max(metrics.knee_max_deg, knee_flex);
		metrics.ankle_up_max_deg = std::max(metrics.ankle_up_max_deg, dorsi);
		metrics.ankle_down_max_deg = std::max(metrics.ankle_down_max_deg, -dorsi);
		metrics.hip_flex_max_deg = std::max(metrics.hip_flex_max_deg, hip_flex);
		metrics.hip_ext_max_deg = std::max(metrics.hip_ext_max_deg, -hip_flex);
		if (knee_flex > 140.0f) metrics.knee_violations++;
		if (dorsi > 20.5f || dorsi < -50.5f) metrics.ankle_violations++;
		if (hip_flex > 120.0f || hip_flex < -30.0f) metrics.hip_violations++;

		// metrics: planted-foot slide (4.6 item 1), on the bone positions actually drawn
		if (T.planted[s] && T.contact[s] > 0) {
			Vector3 pt;
			if (T.contact[s] == 4)
				pt = G[bt].origin + Basis(G[bt].basis).orthonormalized().xform(Vector3()) * 0 +
						Dtoe_w[s].xform(Vector3(0, -dims_.ball[s].y, dims_.toe_len[s] * 0.85f));
			else if (T.contact[s] == 3)
				pt = ank + Fc.xform(Vector3(0, dims_.ball[s].y - dims_.ankle_h[s], dims_.ball[s].z));
			else if (T.contact[s] == 1)
				pt = ank + Fc.xform(Vector3(0, -dims_.ankle_h[s], dims_.heel[s].z));
			else
				pt = ank;
			Vector3 pw = sk_w.xform(pt);
			if (last_contact[s] != T.contact[s]) {
				contact_start[s] = pw;
			} else {
				float sl = pw.distance_to(contact_start[s]) * 100.0f;
				if (sl > metrics.slide_max_cm) {
					metrics.slide_max_cm = sl;
					metrics.slide_frame = metrics.frames;
					metrics.slide_foot = s;
					metrics.slide_kind = T.contact[s];
				}
			}
			last_contact[s] = T.contact[s];
		} else {
			last_contact[s] = -1;
		}
	}

	// arms: shoulder girdle follows the chest; hand targets by two-bone IK, elbow behind (2.1, 2.2)
	for (int s = 0; s < 2; s++) {
		int bc = b_arm[s][0], bu = b_arm[s][1], bl = b_arm[s][2], bh = b_arm[s][3];
		G[bc] = Transform3D(Dt * rest_g[bc].basis, child_origin(G[b_spine[2]], bc));
		Vector3 S = child_origin(G[bc], bu);
		Vector3 tgt = S + ib.xform(T.hand_off[s]);
		Vector3 pole = ib.xform(T.elbow_pole[s]);
		Vector3 el, wr;
		solve_two_bone(S, tgt, dims_.uarm[s], dims_.farm[s], pole, el, wr, 0.98f);
		Vector3 r_u = rest_g[bl].origin - rest_g[bu].origin, r_l = rest_g[bh].origin - rest_g[bl].origin;
		Vector3 rest_pole(0, 0, -1); // T-pose: the elbow bends with the hand coming forward, the elbow going back
		Basis du = frame_delta(r_u, rest_pole, el - S, pole);
		Basis dl = frame_delta(r_l, rest_pole, wr - el, pole);
		// hand: in line with the forearm, palm toward the body's midline, thumb forward (2.1)
		Vector3 fdir = (wr - el).normalized();
		Vector3 medial = s == 0 ? -body_left : body_left;
		Vector3 rest_dir = r_l.normalized();
		Basis dhand = frame_delta(rest_dir, Vector3(0, -1, 0), fdir, medial);
		// forearm twist (1.2 rule 1): half the hand's roll goes to the forearm
		Quaternion relq = (dhand * dl.inverse()).get_rotation_quaternion();
		float tw = twist_angle(relq, fdir);
		Basis dl2 = Basis(fdir, 0.5f * tw) * dl;
		G[bu] = Transform3D(du * rest_g[bu].basis, S);
		G[bl] = Transform3D(dl2 * rest_g[bl].basis, el);
		G[bh] = Transform3D(dhand * rest_g[bh].basis, wr);
		set[bc] = set[bu] = set[bl] = set[bh] = true;
		float elbow = angle_between(el - S, wr - el) / DEG;
		metrics.elbow_max_deg = std::max(metrics.elbow_max_deg, elbow);
		if (elbow > 145.0f) metrics.elbow_violations++;
	}
	metrics.joint_violations = metrics.knee_violations + metrics.ankle_violations + metrics.hip_violations + metrics.elbow_violations;

	// write: local = parent^-1 * global
	for (int b = 0; b < n; b++) {
		if (!set[b]) continue;
		int p = sk->get_bone_parent(b);
		if (p < 0) {
			sk->set_bone_pose_position(b, G[b].origin);
			sk->set_bone_pose_rotation(b, G[b].basis.get_rotation_quaternion());
		} else {
			Basis lb = G[p].basis.inverse() * G[b].basis;
			sk->set_bone_pose_rotation(b, lb.get_rotation_quaternion());
		}
	}
	// fingers: resting curl about the hand's flex axis (global Z at rest)
	float fc = T.finger_curl;
	for (int s = 0; s < 2; s++) {
		for (const Finger &f : fingers[s]) {
			Vector3 ax = rest_g[f.bone].basis.inverse().xform(Vector3(0, 0, 1)).normalized();
			float a = (s == 0 ? -1.0f : 1.0f) * f.curl * fc;
			Basis lb = rest_l[f.bone].basis * Basis(ax, a);
			sk->set_bone_pose_rotation(f.bone, lb.get_rotation_quaternion());
		}
	}

	// metrics: hips pop (4.6 item 5): the hips' move in the world this frame, minus the capsule's horizontal travel
	// (the capsule's own vertical hop on a kerb is collision, not the body)
	Vector3 body = player->get_global_transform_interpolated().origin;
	Vector3 hips_rel = T.hips_pos - Vector3(body.x, 0, body.z);
	if (have_last) {
		float pop = hips_rel.distance_to(last_hips_rel) * 100.0f;
		if (pop > metrics.hips_pop_max_cm) {
			metrics.hips_pop_max_cm = pop;
			metrics.pop_frame = metrics.frames;
		}
	}
	last_hips_rel = hips_rel;
	have_last = true;
	metrics.frames++;
}
