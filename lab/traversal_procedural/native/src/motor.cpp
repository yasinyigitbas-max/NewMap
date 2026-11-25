// Lab A (procedural): the motor. See motor.h and DECISIONS.md sections 2-3. Every number here names its study section.
#include "motor.h"

#include <algorithm>

namespace lab {

Targets lerp_targets(const Targets &a, const Targets &b, float t) {
	Targets r = b;
	r.hips_pos = a.hips_pos.lerp(b.hips_pos, t);
	r.hips_rot = qslerp(a.hips_rot, b.hips_rot, t);
	r.trunk_rot = qslerp(a.trunk_rot, b.trunk_rot, t);
	r.head_rot = qslerp(a.head_rot, b.head_rot, t);
	for (int i = 0; i < 2; i++) {
		r.ankle[i] = a.ankle[i].lerp(b.ankle[i], t);
		r.foot_rot[i] = qslerp(a.foot_rot[i], b.foot_rot[i], t);
		r.toe_bend[i] = lerpf(a.toe_bend[i], b.toe_bend[i], t);
		r.knee_pole[i] = a.knee_pole[i].lerp(b.knee_pole[i], t);
		r.hand_off[i] = a.hand_off[i].lerp(b.hand_off[i], t);
		r.elbow_pole[i] = a.elbow_pole[i].lerp(b.elbow_pole[i], t);
		r.contact_pt[i] = a.contact_pt[i].lerp(b.contact_pt[i], t);
	}
	r.body_lean = lerpf(a.body_lean, b.body_lean, t);
	return r;
}

static Basis align_up(const Vector3 &n) {
	Vector3 nn = n.normalized();
	float c = clampf(UP.dot(nn), -1.0f, 1.0f);
	if (c > 0.9999f) return Basis();
	Vector3 axis = UP.cross(nn).normalized();
	return Basis(axis, std::acos(c));
}

void Motor::reset(const Vector3 &pos, float yaw_) {
	yaw = yaw_;
	look_yaw = yaw_;
	active = false;
	phase = 0;
	gait = 0;
	gait_w = 0;
	prev_vel = Vector3();
	accel_f = Vector3();
	for (int i = 0; i < 2; i++) {
		Foot &F = foot[i];
		F = Foot();
		F.plant = idle_spot(i, pos, yaw_);
		RayHit h = probe(F.plant, pos.y);
		if (h.hit) {
			F.plant.y = h.pos.y;
			F.normal = h.normal;
		}
		F.ground_ref = F.plant;
		F.fyaw = idle_yaw(i, yaw_);
		F.planted = true;
		F.load = 0.5f;
	}
	float stand = d.ankle_h[0] + 0.99f * d.leg(0) - d.hip_off[0].y; // hips bone height standing
	hips_y.x = pos.y + stand - 0.012f;
	hips_y.v = 0;
	hips_side.x = Vector3();
	hips_side.v = Vector3();
	lean_s.x = Vector3();
	lean_s.v = Vector3();
	lean_off = Vector3();
	stopping = false;
	steps_taken = 0;
	step(MotorInput{ pos, Vector3(), Vector3(), Vector3(), 1.0f / 60.0f, true });
}

// Standing: ankles under the hip joints (~20 cm apart), toes out 7 deg (2.1: step width 8-12 cm walking, wider standing).
Vector3 Motor::idle_spot(int i, const Vector3 &pos, float yaw_) const {
	float half = 0.10f;
	return pos + yaw_left(yaw_) * (i == 0 ? half : -half);
}
float Motor::idle_yaw(int i, float yaw_) const { return yaw_ + (i == 0 ? 7.0f : -7.0f) * DEG; }

RayHit Motor::probe(const Vector3 &xz, float ref_y) const {
	if (!ground) return RayHit{ true, Vector3(xz.x, ref_y, xz.z), UP };
	RayHit h = ground(Vector3(xz.x, ref_y + 0.7f, xz.z), Vector3(xz.x, ref_y - 0.9f, xz.z));
	if (!h.hit) h.pos = Vector3(xz.x, ref_y, xz.z);
	return h;
}

// GTA V-like response (brief; study 8.3, 8.5): quick starts, stops in 1-2 walk steps / 2-4 run steps (2.3, 2.4).
Vector3 Motor::steer(const Vector3 &vel, const Vector3 &vel_des, float dt) const {
	Vector3 v = flat(vel), vd = flat(vel_des);
	float s = v.length();
	Vector3 dv = vd - v;
	if (dv.length_squared() < 1e-8f) return vd;
	float a_acc = vd.length() > 2.2f ? 4.0f : 1.3f; // walk full speed in 2-3 steps (2.3), run 4.6 m/s in 3-5 steps
	float a_brk = lerpf(3.0f, 7.0f, clampf(s / 4.6f, 0.0f, 1.0f)); // stop: walk 1-2 steps, run 2-4 steps
	float a_turn = 8.0f; // sideways: lean atan(8/9.81) ~ 39 deg max at the tightest turn (2.5)
	Vector3 out;
	if (s < 0.05f) {
		out = v + dv.limit_length(a_acc * dt);
	} else {
		Vector3 dir = v / s;
		float par = dv.dot(dir);
		Vector3 perp = dv - dir * par;
		float par_lim = par >= 0 ? a_acc : a_brk;
		par = clampf(par, -par_lim * dt, par_lim * dt);
		perp = perp.limit_length(a_turn * dt);
		out = v + dir * par + perp;
	}
	return out;
}

void Motor::start(const MotorInput &in) {
	// Which foot steps first (2.3): toward the side we move to, else the foot further behind along the move.
	Vector3 m = flat(in.vel_des);
	int first = 0;
	if (m.length() > 0.05f) {
		m.normalize();
		float lat = m.dot(yaw_left(yaw));
		if (std::fabs(lat) > 0.5f) {
			first = lat > 0 ? 0 : 1;
		} else {
			float b0 = (foot[0].plant - in.pos).dot(m), b1 = (foot[1].plant - in.pos).dot(m);
			first = b0 <= b1 ? 0 : 1;
		}
	} else {
		// re-plant: the foot furthest from its spot moves first
		float e0 = foot[0].plant.distance_to(idle_spot(0, in.pos, yaw));
		float e1 = foot[1].plant.distance_to(idle_spot(1, in.pos, yaw));
		first = e0 >= e1 ? 0 : 1;
	}
	// Start the clock 0.1 stride before that foot lifts: its weight moves onto the other leg first (2.3 rule 1).
	float lead = 0.10f;
	phase = frac((first == 0 ? 0.0f : 0.5f) + beta_cur - lead);
	for (int i = 0; i < 2; i++) {
		foot[i].prev_p = local_p(i);
		foot[i].planted = true;
	}
	active = true;
	idle_time = 0;
}

void Motor::plan_swing(int i, const MotorInput &in, float T_rem, float T_st) {
	Foot &F = foot[i];
	Vector3 v = flat(in.vel), vd = flat(in.vel_des);
	Vector3 v_td = v + (vd - v).limit_length(4.0f * T_rem);
	if (stopping) v_td = v + (vd - v).limit_length(lerpf(3.0f, 7.0f, clampf(v.length() / 4.6f, 0, 1)) * T_rem);
	if (v.dot(v_td) < 0) v_td = Vector3(); // braking through zero: plan to stop first (2.5 pivot)
	// under the leaning body, not the capsule (2.5); when stopping, under the capsule where the body will stand
	Vector3 P_td = in.pos + (stopping ? Vector3() : lean_off) + (v + v_td) * 0.5f * T_rem;
	// 2.1 / 2.2: the body passes over the foot in its stance; running lands closer under the body (no overstriding).
	float k_ahead = lerpf(0.33f, 0.28f, gait_w); // 2.2: running lands under the knee, close under the body
	Vector3 ahead = v_td * (T_st * k_ahead);
	float yaw_td = yaw + clampf(wrap_pi(look_yaw - yaw), -9.0f * T_rem, 9.0f * T_rem);
	if (v_td.length() > 0.6f) yaw_td = yaw_of(v_td);
	float s_td = v_td.length();
	float w_move = lerpf(0.10f, 0.06f, gait_w); // 2.1: 8-12 cm walking; narrower running
	float w = stopping ? 0.20f : lerpf(0.20f, w_move, clampf(s_td / 0.8f, 0.0f, 1.0f));
	Vector3 tgt = P_td + ahead + yaw_left(yaw_td) * (i == 0 ? 0.5f * w : -0.5f * w);
	RayHit h = probe(tgt, in.pos.y);
	tgt.y = h.pos.y;
	if (F.u > 0.75f) {
		// late in the swing the foot is committed: the target may only drift (no snapping onto a new spot)
		tgt = F.target + (tgt - F.target).limit_length(3.0f * in.dt);
	}
	F.target = tgt;
	F.target_rel = tgt - P_td;
	F.target_normal = h.normal;
	F.target_yaw = yaw_td + (i == 0 ? 7.0f : -7.0f) * DEG * clampf(s_td < 3.0f ? 1.0f : 0.5f, 0, 1);
}

// Foot roll (2.1): heel strike rolls about the heel (pitch < 0); push-off rolls about the ball with the toes flat
// (0 < pitch <= BALL_MAX), then about the toe tips with the toes held bent (pitch > BALL_MAX: toe-off).
void Motor::foot_geom(int i, const Vector3 &ref, const Basis &Rflat, float pitch, int pivot, Vector3 &ankle, Basis &rot) const {
	Vector3 A(0, d.ankle_h[i], 0);
	const Vector3 X(1, 0, 0);
	if (pivot == 3 && pitch > BALL_MAX) {
		Basis R1 = Rflat * Basis(X, BALL_MAX);
		Vector3 Wb = ref + Rflat.xform(d.ball[i]);
		Vector3 a1 = Wb + R1.xform(A - d.ball[i]);
		Vector3 tip = ref + Rflat.xform(Vector3(0, 0, d.ball[i].z + d.toe_len[i] * 0.85f));
		Basis Rt(Rflat.xform(X), pitch - BALL_MAX);
		ankle = tip + Rt.xform(a1 - tip);
		rot = Rt * R1;
		return;
	}
	Basis R = Rflat * Basis(X, pitch);
	Vector3 pc;
	if (pivot == 1)
		pc = d.heel[i];
	else if (pivot == 3)
		pc = d.ball[i];
	ankle = ref + Rflat.xform(pc) + R.xform(A - pc);
	rot = R;
}

void Motor::foot_pose(int i, Vector3 &ankle, Basis &rot) const {
	const Foot &F = foot[i];
	Basis align = F.planted ? align_up(F.normal) : Basis();
	Basis Rflat = align * yaw_basis(F.fyaw);
	foot_geom(i, F.ground_ref + UP * F.clearance, Rflat, F.pitch, F.pivot, ankle, rot);
}

void Motor::step(const MotorInput &in) {
	const float dt = in.dt;
	Vector3 vel = flat(in.vel);
	float s = vel.length();
	Vector3 vd = flat(in.vel_des);
	float s_des = vd.length();
	stopping = s_des < 0.1f;

	// smoothed acceleration for the lean (2.5, 4.5: 0.1-0.2 s)
	Vector3 acc = (vel - prev_vel) / dt;
	prev_vel = vel;
	accel_f = approach(accel_f, acc, 0.12f, dt);

	// facing: follow the path when moving; turn to the stick when slow (pivot) (2.5)
	float yaw_goal = yaw;
	Vector3 look = flat(in.look_dir);
	bool stick = look.length() > 0.1f;
	if (s > 0.6f)
		yaw_goal = yaw_of(vel);
	else if (stick)
		yaw_goal = yaw_of(look);
	float w_max = lerpf(9.0f, 5.0f, clampf(s / 4.6f, 0, 1));
	yaw += clampf(wrap_pi(yaw_goal - yaw), -w_max * dt, w_max * dt);
	yaw = wrap_pi(yaw);
	// head leads: aims at the stick direction at once (2.5 top-down order, 4.5)
	float look_goal = stick ? yaw_of(look) : yaw;
	look_yaw = approach_angle(look_yaw, look_goal, 0.05f, dt);

	// gait choice (2.2: switch at 2.0-2.2 m/s, never held in the band)
	float s_cad = std::max(s, 0.75f * s_des);
	if (stopping && active) s_cad = std::max(s_cad, 1.0f); // stopping steps keep a walking rhythm (2.4)
	int want = gait;
	if (gait == 0 && s_des > 2.3f && (s > 1.7f || !active)) want = 1;
	if (gait == 1 && s_des < 2.0f && s < 2.4f) want = 0;
	if (!active) gait = want;
	gait_w = approach(gait_w, (float)gait, 0.12f, dt);
	float cad = lerpf(walk_cadence(std::min(s_cad, 2.2f)), run_cadence(std::max(s_cad, 2.5f)), gait_w);
	beta_cur = lerpf(walk_beta(s_cad), run_beta(s_cad), gait_w);
	freq_cur = cad / 120.0f; // strides per second
	speed_s = s;

	// idle and starting
	if (!active) {
		idle_time += dt;
		bool misplaced = false;
		for (int i = 0; i < 2; i++) {
			if (foot[i].plant.distance_to(idle_spot(i, in.pos, yaw)) > 0.16f) misplaced = true;
			if (std::fabs(wrap_pi(foot[i].fyaw - idle_yaw(i, yaw))) > 30.0f * DEG) misplaced = true;
		}
		if (s_des > 0.15f || (misplaced && idle_time > 0.2f)) start(in);
	}

	if (active) {
		phase = frac(phase + freq_cur * dt);
		int adjust_done = 0;
		for (int i = 0; i < 2; i++) {
			Foot &F = foot[i];
			Foot &O = foot[1 - i];
			float p = local_p(i);
			float prev = F.prev_p;
			if (F.planted) {
				if (prev > p) F.skip = false; // a new stride
				// any planted foot past its stance share lifts (beta moves with speed, so "crossing" it is not enough)
				bool crossed = p >= beta_cur && !F.skip;
				// catch step (DECISIONS 3.7): the leg can no longer reach or is twisted under the body
				Vector3 hip = in.pos + lean_off + yaw_basis(yaw).xform(flat(d.hip_off[i]));
				float reach = flat(F.plant - hip).length();
				bool twisted = std::fabs(wrap_pi(F.fyaw - yaw)) > 75.0f * DEG;
				if (!crossed && O.planted && p > 0.15f && (reach > 0.75f * d.leg(i) || twisted)) crossed = true;
				if (crossed) {
					bool near_spot = F.plant.distance_to(idle_spot(i, in.pos, yaw)) < 0.08f &&
							std::fabs(wrap_pi(F.fyaw - idle_yaw(i, yaw))) < 12.0f * DEG;
					if (stopping && s < 0.3f && near_spot) {
						adjust_done++;
						F.skip = true;
					} else {
						F.planted = false;
						F.lift = F.plant;
						F.lift_rel = F.plant - in.pos;
						F.lift_yaw = F.fyaw;
						F.lift_beta = std::min(p, 0.95f);
						F.lift_pitch = F.pitch;
						F.lift_toe = F.toe;
						F.u = 0;
						F.target = F.plant;
						F.target_yaw = F.fyaw;
					}
				}
			} else {
				bool wrapped = prev > p + 0.5f;
				if (wrapped) {
					F.planted = true;
					F.plant = F.target;
					F.ground_ref = F.plant;
					F.fyaw = F.target_yaw;
					F.normal = F.target_normal;
					F.clearance = 0;
					F.u = 1;
					steps_taken++;
					gait = want; // gait switches at a foot strike (DECISIONS 2.3)
				}
			}
			F.prev_p = p;
		}
		// halt the clock: both feet down at their spots, body stopped (2.4: the second foot comes alongside)
		if (stopping && s < 0.05f && foot[0].planted && foot[1].planted) {
			bool ok = true;
			for (int i = 0; i < 2; i++) {
				if (foot[i].plant.distance_to(idle_spot(i, in.pos, yaw)) > 0.10f) ok = false;
				if (std::fabs(wrap_pi(foot[i].fyaw - idle_yaw(i, yaw))) > 15.0f * DEG) ok = false;
			}
			if (ok || adjust_done > 0) {
				active = false;
				idle_time = 0;
			}
		}
	}

	// per-foot pose: swing arcs (2.1, 2.2) and stance roll (2.1 heel strike -> flat -> heel lift -> push-off)
	float sc = clampf(std::max(s, active ? 0.75f * s_des : 0.0f) / 0.9f, 0.0f, 1.0f);
	if (stopping) sc = clampf(s / 0.9f, 0.0f, 1.0f);
	float th_hs = lerpf(lerpf(12.0f, 16.0f, clampf(s / 1.6f, 0, 1)), 5.0f, gait_w) * DEG * sc;
	float th_to = lerpf(lerpf(30.0f, 42.0f, clampf(s / 1.6f, 0, 1)), 40.0f, gait_w) * DEG * sc;
	float load_end = lerpf(0.10f, 0.05f, gait_w);
	float hr0 = lerpf(0.30f * beta_cur / 0.6f, 0.5f * beta_cur, gait_w);
	float c_mid = lerpf(0.02f, 0.06f, gait_w); // 2.1: toe clears by 1-2 cm at mid-swing walking
	float c_early = lerpf(0.10f, 0.12f + 0.12f * clampf((s - 2.5f) / 2.1f, 0, 1), gait_w) * std::max(sc, 0.4f);
	for (int i = 0; i < 2; i++) {
		Foot &F = foot[i];
		float p = local_p(i);
		if (F.planted) {
			F.ground_ref = F.plant;
			F.clearance = 0;
			float th = 0, toe = 0;
			int pv = 2;
			if (active) {
				if (p < load_end && F.u >= 1.0f) {
					th = -th_hs * (1.0f - smooth01(p / load_end));
					pv = 1;
				} else if (p >= hr0 && p <= beta_cur + 0.02f) {
					float x = clampf((p - hr0) / std::max(0.05f, beta_cur - hr0), 0.0f, 1.0f);
					th = th_to * std::pow(x, 1.5f);
					toe = std::min(th, BALL_MAX);
					pv = 3;
				}
			}
			// 2.1 terminal stance: the body falls forward over the ball, so the heel lifts as far as the leg needs to keep
			// its knee soft (leg <= 96 % of its length from the hip), up to the toes' range (1.1: toes bend 55-70 deg).
			if (active && pv != 1 && p > load_end) {
				Vector3 hip = in.pos + lean_off + hips_side.x + yaw_basis(yaw).xform(flat(d.hip_off[i]));
				hip.y = hips_y.x + d.hip_off[i].y;
				float Lm = 0.975f * d.leg(i);
				Basis Rflat = align_up(F.normal) * yaw_basis(F.fyaw);
				auto ankle_at = [&](float a) {
					Vector3 an;
					Basis rr;
					foot_geom(i, F.plant, Rflat, a, 3, an, rr);
					return an;
				};
				bool behind = (F.plant - hip).dot(yaw_fwd(yaw)) < 0.0f; // only a trailing foot rolls onto its toes
				if (behind && ankle_at(std::max(th, 0.0f)).distance_to(hip) > Lm) {
					float lo = std::max(th, 0.0f), hi = 70.0f * DEG;
					for (int k = 0; k < 12; k++) {
						float mid = 0.5f * (lo + hi);
						if (ankle_at(mid).distance_to(hip) > Lm)
							lo = mid;
						else
							hi = mid;
					}
					th = hi;
					pv = 3;
					toe = std::min(th, BALL_MAX);
				}
			}
			float th_geo = th;
			F.pitch = approach(F.pitch, th, 0.025f, dt);
			F.toe = approach(F.toe, toe, 0.025f, dt);
			if (pv == 3 && th_geo > F.pitch) { // the heel lift the leg needs is never late (no reach shortfall)
				F.pitch = th_geo;
				F.toe = std::max(F.toe, std::min(th_geo, BALL_MAX));
			}
			F.pivot = F.pitch < -0.002f ? 1 : (F.pitch > 0.002f ? 3 : 2);
		} else {
			float T_sw = (1.0f - F.lift_beta) / freq_cur;
			F.u = clampf((p - F.lift_beta) / (1.0f - F.lift_beta), 0.0f, 1.0f);
			float T_rem = (1.0f - F.u) * T_sw;
			float T_st = beta_cur / freq_cur;
			plan_swing(i, in, T_rem, T_st);
			// the swing foot travels relative to the body (2.2: the foot's path is an oval about the hip, it lands under
			// the knee), and is handed over to its world landing spot over the last 20 % of the swing
			float sh = minjerk(F.u);
			Vector3 rel = F.lift_rel.lerp(F.target_rel, sh);
			Vector3 body_path = in.pos + rel;
			body_path.y = lerpf(F.lift.y, F.target.y, sh);
			Vector3 world_path = F.lift.lerp(F.target, sh);
			F.ground_ref = body_path.lerp(world_path, smooth01((F.u - 0.8f) / 0.2f));
			F.fyaw = F.lift_yaw + wrap_pi(F.target_yaw - F.lift_yaw) * sh;
			float th;
			if (F.u < 0.45f)
				th = F.lift_pitch * (1.0f - smooth01(F.u / 0.45f));
			else
				th = -th_hs * smooth01((F.u - 0.55f) / 0.45f);
			F.pitch = th;
			F.toe = F.lift_toe * (1.0f - smooth01(F.u / 0.3f));
			F.pivot = th >= 0 ? 3 : 1;
			float rise = std::max(0.0f, F.target.y - F.lift.y);
			F.clearance = c_mid * std::sin(PI_F * F.u) + c_early * std::sin(PI_F * clampf(F.u / 0.5f, 0, 1)) +
					rise * 0.5f * std::sin(PI_F * F.u);
			if (stopping && s < 0.3f) F.clearance *= 0.6f; // a small adjusting step
		}
	}

	// weight per foot: unloads in the last 0.1 stride before lift-off, loads in the first 0.1 after strike (2.1, 2.3)
	float loads[2];
	for (int i = 0; i < 2; i++) {
		Foot &F = foot[i];
		float p = local_p(i);
		if (!F.planted) {
			loads[i] = 0;
		} else if (!active) {
			loads[i] = 1.0f;
		} else {
			float l = 1.0f;
			if (p <= beta_cur) l *= smooth01((beta_cur - p) / 0.1f);
			if (F.u >= 1.0f) l *= std::max(0.05f, smooth01(p / 0.1f));
			loads[i] = l;
		}
	}
	if (!active) {
		idle_w_phase += dt * 2.0f * PI_F / 6.0f; // weight moves foot to foot every ~6 s (4.5)
		float sh = 0.5f + 0.15f * std::sin(idle_w_phase);
		loads[0] = sh;
		loads[1] = 1.0f - sh;
	}
	float lsum = std::max(1e-4f, loads[0] + loads[1]);
	for (int i = 0; i < 2; i++) foot[i].load = loads[i] / lsum;

	// foot ankle targets (world)
	Vector3 ankles[2];
	Basis frots[2];
	for (int i = 0; i < 2; i++) foot_pose(i, ankles[i], frots[i]);

	// ----- centre of mass path -----
	Vector3 left = yaw_left(yaw), fwd = yaw_fwd(yaw);
	float ground_y = 0.5f * (foot[0].ground_ref.y + foot[1].ground_ref.y);
	if (foot[0].planted && !foot[1].planted) ground_y = foot[0].plant.y;
	if (foot[1].planted && !foot[0].planted) ground_y = foot[1].plant.y;
	float hip_drop = d.hip_off[0].y; // hip joint below the hips bone (negative)
	float stand_hip = d.ankle_h[0] + 0.99f * d.leg(0);

	// lateral: over the loaded foot (2.1: 2-4 cm; start: the weight shift of 2.3)
	float k_side = lerpf(0.55f, 0.25f, gait_w);
	float side = 0;
	for (int i = 0; i < 2; i++) side += foot[i].load * (foot[i].ground_ref - in.pos).dot(left);
	Vector3 side_v = left * (side * k_side);
	hips_side.step(side_v, 18.0f, dt);

	// vertical
	float h;
	if (!active) {
		h = ground_y + stand_hip - hip_drop - 0.012f + 0.002f * std::sin(breath); // breathing (4.5)
	} else {
		// walk: inverted pendulum over each loaded foot (2.1), smooth-min where both are down
		float hw = 1e9f;
		for (int i = 0; i < 2; i++) {
			if (!foot[i].planted && foot[i].u < 0.9f) continue;
			Vector3 hip = in.pos + lean_off + hips_side.x + yaw_basis(yaw).xform(flat(d.hip_off[i]));
			float dx = flat(ankles[i] - hip).length();
			float L = 0.985f * d.leg(i); // heel strike: knee nearly straight (2.1)
			float hy = ankles[i].y + std::sqrt(std::max(0.0f, L * L - dx * dx)) - hip_drop;
			hw = hw > 1e8f ? hy : smin(hw, hy, 0.025f);
		}
		float cap = ground_y + d.ankle_h[0] + 0.99f * d.leg(0) - hip_drop; // midstance knee ~15 deg (2.1)
		if (hw > 1e8f) hw = cap;
		hw = std::min(hw, cap);
		// run: spring-mass, lowest at midstance (2.2), 6-10 cm
		float A = clampf(0.05f + 0.02f * (s - 2.5f) / 2.1f, 0.05f, 0.07f); // 2.2: 6-10 cm incl. the landing dip
		float s_step = frac(phase * 2.0f);
		float hr = cap - 0.055f - 0.5f * A * std::cos(2.0f * PI_F * (s_step - beta_cur));
		h = lerpf(hw, hr, gait_w);
	}
	hips_y.step(h, 30.0f, dt);

	// lean from the feet (2.5, 4.5): atan(a/g) toward the acceleration (forward, braking and turning in one)
	// the lean vector (tan of the tilt) rides a critically damped spring, ~0.2 s to settle (4.5: 0.1-0.2 s)
	Vector3 tilt_t = flat(accel_f) / GRAV;
	tilt_t = tilt_t.limit_length(std::tan(16.0f * DEG)); // 2.5: a 3 m/s^2 push-off is ~17 deg
	{
		Vector3 before = lean_s.x;
		lean_s.step(tilt_t, 11.0f, dt);
		Vector3 dl = lean_s.x - before;
		float mx = 1.0f * dt; // at most ~57 deg/s: the hips move < 2 cm per frame from the lean (4.6 item 5)
		if (dl.length() > mx) {
			lean_s.x = before + dl.normalized() * mx;
			lean_s.v = dl.normalized() * (mx / dt);
		}
	}
	Vector3 a_h = flat(lean_s.x);
	float a_len = a_h.length();
	float lean = std::atan(a_len);
	Basis L;
	if (a_len > 1e-4f) L = Basis(UP.cross(a_h / a_len).normalized(), lean);
	Vector3 G(in.pos.x, ground_y, in.pos.z);
	Vector3 hips_nom(in.pos.x, hips_y.x, in.pos.z);
	hips_nom += hips_side.x;
	t.hips_pos = G + L.xform(hips_nom - G);
	lean_off = flat(t.hips_pos - hips_nom);

	// pelvis follows the lower foot (2.6, 4.5): a planted leg is never asked to reach past 99.5 % of its length, so the
	// foot never has to slide. The limit is fed back into the spring so releasing it is smooth.
	{
		Basis Rp = L * yaw_basis(yaw);
		float y_max = 1e9f;
		for (int i = 0; i < 2; i++) {
			float u0 = lerpf(0.8f, 0.55f, gait_w); // running: the hips settle over the whole late swing (no landing pop)
			float wgt = foot[i].planted ? 1.0f : smooth01((foot[i].u - u0) / (1.0f - u0));
			if (wgt <= 0.0f) continue;
			Vector3 hip = t.hips_pos + Rp.xform(d.hip_off[i]);
			Vector3 dv = ankles[i] - hip;
			float Lm = 0.985f * d.leg(i); // inside the poser's soft-IK zone (98 %): the foot is always reached
			float dxz2 = dv.x * dv.x + dv.z * dv.z;
			float ym = ankles[i].y + std::sqrt(std::max(0.0f, Lm * Lm - dxz2)) - d.hip_off[i].y;
			ym += (1.0f - wgt) * 0.3f;
			y_max = std::min(y_max, ym);
		}
		if (t.hips_pos.y > y_max) {
			float over = t.hips_pos.y - y_max;
			hips_y.x -= over;
			hips_y.v = std::min(hips_y.v, 0.0f);
			t.hips_pos.y = y_max;
		}
	}

	// pelvis turn and list (1.2 rule 5), chest counter-turn (1.1 thoracic)
	float osc_sc = active ? sc : 0.0f;
	float A_yaw = lerpf(4.5f * clampf(s / 1.35f, 0, 1), 6.0f, gait_w) * DEG * osc_sc;
	float A_list = lerpf(4.0f, 3.0f, gait_w) * DEG * osc_sc;
	float yaw_osc = -A_yaw * std::cos(2.0f * PI_F * phase);
	float list = A_list * std::cos(2.0f * PI_F * (phase - 0.5f * beta_cur));
	Basis R_body = yaw_basis(yaw);
	float tilt = 8.0f * DEG * gait_w; // running: pelvis tips forward with the trunk (1.1 lumbar)
	Basis pelvis = L * R_body * Basis(UP, yaw_osc) * Basis(Vector3(0, 0, 1), list) * Basis(Vector3(1, 0, 0), tilt);
	t.hips_rot = pelvis.get_rotation_quaternion();
	float posture = lerpf(2.0f, 12.0f, gait_w) * DEG; // 2.2: trunk forward 5-15 deg running
	breath += dt * 2.0f * PI_F / 4.0f;
	float br = 0.6f * DEG * std::sin(breath);
	Basis trunk = L * R_body * Basis(UP, -1.3f * yaw_osc) * Basis(Vector3(1, 0, 0), posture + br);
	t.trunk_rot = trunk.get_rotation_quaternion();
	float look_pitch = active ? 5.0f * DEG : 0.0f;
	t.head_rot = (yaw_basis(look_yaw) * Basis(Vector3(1, 0, 0), look_pitch)).get_rotation_quaternion();
	t.body_lean = lean;

	// legs
	for (int i = 0; i < 2; i++) {
		t.ankle[i] = ankles[i];
		t.foot_rot[i] = frots[i].get_rotation_quaternion();
		t.toe_bend[i] = foot[i].toe;
		t.knee_pole[i] = yaw_fwd(foot[i].fyaw); // 1.2 rule 3: knee over the toes
		t.planted[i] = foot[i].planted;
		t.contact[i] = foot[i].planted ? foot[i].pivot : 0;
		Basis Rflat = (foot[i].planted ? align_up(foot[i].normal) : Basis()) * yaw_basis(foot[i].fyaw);
		Vector3 pc = foot[i].pivot == 1 ? d.heel[i] : (foot[i].pivot == 3 ? d.ball[i] : Vector3());
		if (foot[i].pivot == 3 && foot[i].pitch > BALL_MAX) {
			pc = Vector3(0, 0, d.ball[i].z + d.toe_len[i] * 0.85f);
			t.contact[i] = foot[i].planted ? 4 : 0;
		}
		t.contact_pt[i] = foot[i].ground_ref + Rflat.xform(pc);
	}

	// arms (2.1, 2.2): opposite to the legs, from the shoulder; run elbows ~90 deg, hands in but never across
	float A_arm_w = (8.0f + 10.0f * clampf(s / 1.35f, 0, 1)) * DEG;
	float A_arm_r = clampf(30.0f + 12.0f * (s - 2.5f) / 2.1f, 30.0f, 45.0f) * DEG;
	float A_arm = lerpf(A_arm_w, A_arm_r, gait_w) * osc_sc;
	float lag = 0.03f;
	for (int i = 0; i < 2; i++) {
		float sgn = i == 0 ? -1.0f : 1.0f;
		// relaxed arms hang a little forward and out of the body line; the swing is about that (2.1)
		float al = 7.0f * DEG + sgn * A_arm * std::cos(2.0f * PI_F * (phase - lag));
		float fw = A_arm > 1e-4f ? std::max(0.0f, (al - 7.0f * DEG) / A_arm) : 0.0f;
		float e_w = (12.0f + 14.0f * fw + 6.0f * clampf(s / 1.35f, 0, 1)) * DEG;
		float e_r = (82.0f + 12.0f * fw) * DEG;
		float e = lerpf(e_w, e_r, gait_w);
		if (!active) e = (10.0f + 1.0f * std::sin(breath)) * DEG;
		float abd = lerpf(10.0f, 12.0f, gait_w) * DEG * (i == 0 ? -1.0f : 1.0f); // away from the body
		Vector3 u = Basis(fwd, -abd).xform(Basis(left, -al).xform(-UP));
		Vector3 v = Basis(fwd, -abd * 0.5f).xform(Basis(left, -(al + e)).xform(-UP));
		float inward = lerpf(4.0f, 12.0f, gait_w) * DEG * (i == 0 ? -1.0f : 1.0f);
		v = Basis(UP, inward).xform(v);
		Vector3 E = u * d.uarm[i];
		Vector3 Hd = E + v * d.farm[i];
		t.hand_off[i] = Hd;
		t.elbow_pole[i] = E - Hd.normalized() * E.dot(Hd.normalized());
	}
	t.finger_curl = 1.0f;
}

} // namespace lab
