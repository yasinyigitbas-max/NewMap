// Lab A (procedural): the motor. See motor.h and DECISIONS.md sections 2-3. Every number here names its study section.
#include "motor.h"

#include <algorithm>

namespace lab {

Targets lerp_targets(const Targets &a, const Targets &b, float t) {
	Targets r = t < 0.5f ? a : b; // flags (planted, contact) from the nearer tick, so they match the drawn pose
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
	edge_landings = 0;
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
	RayHit h = ground(Vector3(xz.x, ref_y + 0.7f, xz.z), Vector3(xz.x, ref_y - 0.9f, xz.z), false);
	if (!h.hit) h.pos = Vector3(xz.x, ref_y, xz.z);
	return h;
}

float Profile::h_at(float x) const {
	if (n <= 0) return origin.y;
	float f = (x - X0) / DX;
	int k = (int)std::floor(f + 0.5f);
	k = k < 0 ? 0 : (k >= n ? n - 1 : k);
	return h[k];
}
bool Profile::clear(float a, float b) const {
	for (int e = 0; e < n_edges; e++)
		if (edge_x[e] >= a && edge_x[e] <= b) return false;
	return true;
}
float Profile::max_h(float a, float b) const {
	if (n <= 0) return origin.y;
	// only the samples whose centre lies inside [a, b] (rounding outward would read the level across an edge)
	int ka = std::max(0, (int)std::ceil((a - X0) / DX - 1e-4f)), kb = std::min(n - 1, (int)std::floor((b - X0) / DX + 1e-4f));
	if (ka > kb) return h_at(0.5f * (a + b));
	float m = -1e9f;
	for (int k = ka; k <= kb; k++) m = std::max(m, h[k]);
	return m > -1e8f ? m : h_at(a);
}

// The ground ahead (2.8: people look at a kerb ~2 steps ahead; 4.4: detect 1.5-3 m ahead). Each sample's ray starts
// 0.5 m above the last one, so stairs are followed up; a ray that starts inside something is a wall: the profile ends.
void Motor::scan(const MotorInput &in, const Vector3 &dir) {
	Profile &P = prof;
	P.origin = in.pos;
	P.dir = dir;
	P.n = 0;
	P.n_edges = 0;
	P.stairs = false;
	P.first_stair = 1e9f;
	float prev = in.pos.y;
	for (int k = 0; k < Profile::N; k++) {
		Vector3 c = in.pos + dir * (Profile::X0 + k * Profile::DX);
		float top = prev + 0.5f;
		RayHit hit = ground ? ground(Vector3(c.x, top, c.z), Vector3(c.x, prev - 1.2f, c.z), true) : RayHit{ true, Vector3(c.x, in.pos.y, c.z), UP };
		if (!hit.hit) {
			P.h[k] = prev - 1.2f; // a drop deeper than 1.2 m: step 6
		} else if (hit.pos.y > top - 0.005f) {
			break; // a wall (or something taller than 0.5 m): step 6 decides what to do with it
		} else {
			P.h[k] = hit.pos.y;
		}
		prev = P.h[k];
		P.n = k + 1;
	}
	float rise_sum = 0, run_sum = 0;
	for (int k = 0; k + 1 < P.n; k++) {
		float dh = P.h[k + 1] - P.h[k];
		float x = Profile::X0 + (k + 0.5f) * Profile::DX;
		if (std::fabs(dh) > 0.025f) {
			// merge with an edge in the last sample (a steep face spanning two samples)
			if (P.n_edges > 0 && x - P.edge_x[P.n_edges - 1] < 0.05f && (dh > 0) == (P.edge_rise[P.n_edges - 1] > 0)) {
				P.edge_rise[P.n_edges - 1] += dh;
			} else if (P.n_edges < 24) {
				P.edge_x[P.n_edges] = x;
				P.edge_rise[P.n_edges] = dh;
				P.n_edges++;
			}
		} else if (x > 0.0f && x < 1.2f) {
			rise_sum += dh;
			run_sum += Profile::DX;
		}
	}
	P.slope = run_sum > 0.2f ? std::atan(rise_sum / run_sum) : 0.0f;
	// stairs (2.7): two or more edges the same way, 0.18-0.5 m apart, risers 8-26 cm
	int first = -1;
	for (int e = 0; e < P.n_edges; e++) {
		if (P.edge_x[e] > -0.35f && std::fabs(P.edge_rise[e]) > 0.08f) {
			first = e;
			break;
		}
	}
	if (first >= 0) {
		int cnt = 1;
		float sp = 0, rs = std::fabs(P.edge_rise[first]);
		for (int e = first + 1; e < P.n_edges && cnt < 5; e++) {
			float gap = P.edge_x[e] - P.edge_x[e - 1];
			float r = P.edge_rise[e];
			if (gap < 0.18f || gap > 0.5f || (r > 0) != (P.edge_rise[first] > 0) || std::fabs(r) < 0.08f || std::fabs(r) > 0.26f) break;
			sp += gap;
			rs += std::fabs(r);
			cnt++;
		}
		if (cnt >= 2) {
			P.stairs = true;
			P.tread = sp / (cnt - 1);
			P.riser = (P.edge_rise[first] > 0 ? 1.0f : -1.0f) * rs / cnt;
			P.first_stair = P.edge_x[first];
		}
	}
}

// 2.8 / 4.4: no foot lands on an edge. The landing slides by up to 25 % of the step to the nearest spot where the
// foot stands on one level (the whole sole; on stairs at least the ankle and the ball), preferring a spot from which
// the next step is also clear, and sticking to the spot it chose before (no flicker).
void Motor::choose_landing(int i, Vector3 &tgt, float yaw_td) {
	const Profile &P = prof;
	Foot &F = foot[i];
	if (P.n_edges == 0 || P.n < 4) {
		F.has_choice = false;
		return;
	}
	float x_nom = P.x_of(tgt);
	if (P.clear(x_nom - 0.7f, x_nom + 0.7f)) {
		F.has_choice = false;
		return;
	}
	float x_o = P.x_of(foot[1 - i].plant);
	float L = std::max(0.2f, x_nom - x_o);
	float hz = d.heel[i].z, bz = d.ball[i].z, tz = d.ball[i].z + d.toe_len[i];
	float span = std::max(0.06f, (P.stairs ? 0.45f : 0.25f) * L); // on stairs the step follows the tread
	float best = 1e9f, best_x = x_nom;
	for (float x = x_nom - span; x <= x_nom + span + 1e-4f; x += 0.01f) {
		// the whole sole on one level; below a drop the heel lands well past the edge so the leg reaches down
		// during the swing (2.8, 3.3), and the toes stay 3 cm off a riser ahead
		bool full = P.clear(x + hz - 0.03f, x + tz + 0.03f);
		// stairs (2.7): the ball carries the foot; the heel or toes may hang over a LOWER level, never into a higher
		// one (a riser, a kerb face)
		bool part = P.clear(x + bz - 0.06f, x + bz + 0.03f) && P.max_h(x + hz - 0.01f, x + tz + 0.02f) <= P.h_at(x + bz) + 0.01f;
		bool drop_ok = true;
		for (int e = 0; e < P.n_edges; e++) {
			float r = P.edge_rise[e];
			float m = P.stairs ? 0.03f : 0.06f + 0.25f * -r;
			if (r < -0.05f && P.edge_x[e] < x && P.edge_x[e] > x + hz - m) drop_ok = false;
		}
		if ((!full && !part) || !drop_ok) continue;
		float xn = x + L;
		bool next_ok = P.clear(xn - 0.03f, xn + bz + 0.03f) || xn > Profile::X0 + Profile::DX * P.n;
		float sc = std::fabs(x - x_nom) + (full ? 0.0f : 0.06f) + (next_ok ? 0.0f : 0.03f);
		if (F.has_choice) sc += 0.3f * std::fabs(x - F.choice_x);
		// stairs (2.7): one tread per step walking, two running - the landing one (two) risers from the other foot
		if (P.stairs && std::fabs(P.riser) > 0.05f) {
			float k = gait_w > 0.5f ? 2.0f : 1.0f;
			float h_exp = foot[1 - i].plant.y + k * P.riser;
			float h_land = P.h_at(x + bz);
			bool level_exists = P.max_h(P.X0, P.X0 + P.DX * P.n) >= std::min(h_exp, foot[1 - i].plant.y) - 0.02f;
			if (level_exists) sc += std::min(0.4f, 0.4f * std::fabs(h_land - h_exp) / std::fabs(P.riser));
		}
		if (sc < best) {
			best = sc;
			best_x = x;
		}
	}
	if (best < 1e8f) {
		tgt += P.dir * (best_x - x_nom);
		F.choice_x = best_x;
		F.has_choice = true;
	}
	(void)yaw_td;
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
	choose_landing(i, tgt, yaw_td);
	// the foot stands at the height under its ball (on stairs the heel may hang over the step below)
	Vector3 ball_pt = tgt + yaw_basis(yaw_td).xform(Vector3(0, 0, d.ball[i].z));
	RayHit h = probe(ball_pt, in.pos.y);
	RayHit ha = probe(tgt, in.pos.y);
	if (ha.pos.y > h.pos.y) h = ha; // never sink the ankle into a higher level
	tgt.y = h.pos.y;
	if (F.u > 0.75f) {
		// late in the swing the foot is committed: the spot may only drift (no snapping onto a new spot); its height
		// is always the ground's at that spot
		Vector3 dxz = flat(tgt - F.target).limit_length(3.0f * in.dt);
		Vector3 t2 = F.target + dxz;
		RayHit h2 = probe(t2, in.pos.y);
		if (std::fabs(h2.pos.y - F.target.y) < 0.03f) { // drift on the same level only, never over an edge
			t2.y = h2.pos.y;
			tgt = t2;
			h = h2;
		} else {
			tgt = F.target;
			h.pos = F.target;
			h.normal = F.target_normal;
		}
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

	// the ground ahead, along the way the body goes
	{
		Vector3 dir = s > 0.2f ? vel / s : (s_des > 0.1f ? vd / s_des : yaw_fwd(yaw));
		scan(in, dir);
		const Profile &P = prof;
		float a = P.slope / DEG;
		// 2.6: up to 5 deg nothing changes; steeper slopes slow the walk (shorter steps)
		slope_mult = 1.0f - 0.012f * std::max(0.0f, std::fabs(a) - 5.0f);
		speed_cap = 1e9f;
		if (P.stairs) {
			// 2.7: one tread per step walking (~95 steps/min up, ~105 down), two treads running
			bool running = s_des > 2.2f;
			float cad = running ? 150.0f : (P.riser > 0 ? 95.0f : 105.0f);
			float v_st = P.tread * (running ? 2.0f : 1.0f) * cad / 60.0f;
			// slow down over the last metre so the first step lands on the first tread (4.4: adjust 2-3 steps out)
			speed_cap = v_st + 1.2f * std::max(0.0f, P.first_stair - 0.35f);
		} else {
			// 2.8: a step over ~18-20 cm is an obvious bigger step: a pause in the rhythm
			for (int e = 0; e < P.n_edges; e++) {
				if (P.edge_x[e] > 0.0f && P.edge_x[e] < 1.2f && P.edge_rise[e] > 0.18f) speed_cap = std::min(speed_cap, 1.0f);
			}
		}
		// posture: trunk forward uphill (~ the slope + a few deg) and on stairs up, eyes down on stairs down (2.6, 2.7)
		float pe = 0, ld = 0;
		if (s > 0.2f) {
			pe = a > 0 ? (a * 0.8f + 3.0f * smooth01(a / 5.0f)) * DEG : a * 0.2f * DEG;
			if (P.stairs && P.first_stair < 1.0f) {
				if (P.riser > 0)
					pe = std::max(pe, 12.0f * DEG);
				else
					ld = 22.0f * DEG;
			}
			for (int e = 0; e < P.n_edges; e++) {
				if (P.edge_x[e] > 0.3f && P.edge_x[e] < 1.8f && std::fabs(P.edge_rise[e]) > 0.05f) ld = std::max(ld, 8.0f * DEG);
			}
		}
		posture_extra = approach(posture_extra, pe, 0.25f, dt);
		look_down = approach(look_down, ld, 0.2f, dt);
	}

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
	// steep slopes: shorter, quicker steps (2.6) - the speed is already lower, the step rate rises a little
	cad *= 1.0f + 0.25f * clampf((std::fabs(prof.slope) - 5.0f * DEG) / (20.0f * DEG), 0.0f, 1.0f);
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
					F.has_choice = false;
					{
						// did the foot land across an edge? (heel / ankle / ball / toe at different heights)
						float xa = prof.x_of(F.plant);
						if (prof.n > 0 && !prof.clear(xa + d.ball[i].z - 0.05f, xa + d.ball[i].z + 0.02f)) edge_landings++;
					}
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
				float le = F.land_pitch > 0 ? 0.15f : load_end; // toes first: the heel lowers as the knee brakes (2.7)
				if (p < le && F.u >= 1.0f && std::fabs(F.land_pitch) > 1e-4f) {
					th = F.land_pitch * (1.0f - smooth01(p / le));
					pv = F.land_pitch < 0 ? 1 : 3;
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
			F.t_rem = T_rem;
			float T_st = beta_cur / freq_cur;
			plan_swing(i, in, T_rem, T_st);
			// the swing foot travels relative to the body (2.2: the foot's path is an oval about the hip, it lands under
			// the knee), and is handed over to its world landing spot over the last 20 % of the swing
			// 2.7 / 2.8 / 3.3: stepping down, the foot first reaches out past the edge, then lowers; stepping up, it rises
			// first, then moves onto the step
			float dy = F.target.y - F.lift.y;
			float sh = dy < -0.05f ? minjerk(F.u / 0.8f) : minjerk(F.u);
			float sv = dy > 0.05f ? smooth01(F.u / 0.6f) : (dy < -0.05f ? smooth01((F.u - 0.45f) / 0.55f) : minjerk(F.u));
			Vector3 rel = F.lift_rel.lerp(F.target_rel, sh);
			Vector3 body_path = in.pos + rel;
			body_path.y = lerpf(F.lift.y, F.target.y, sv);
			Vector3 world_path = F.lift.lerp(F.target, sh);
			world_path.y = body_path.y;
			F.ground_ref = body_path.lerp(world_path, smooth01((F.u - 0.8f) / 0.2f));
			F.fyaw = F.lift_yaw + wrap_pi(F.target_yaw - F.lift_yaw) * sh;
			float th;
			// 2.7 / 3.3: stepping up lands flat (forefoot), stepping down lands toes first, level ground heel first
			// on a smooth slope (no edge between the feet): uphill lands flatter, downhill heel first (2.6)
			float rise_o = F.target.y - foot[1 - i].plant.y;
			float xo = prof.x_of(foot[1 - i].plant), xt2 = prof.x_of(F.target);
			bool edge_between = !prof.clear(std::min(xo, xt2), std::max(xo, xt2));
			if (edge_between)
				F.land_pitch = rise_o > 0.05f ? 0.0f : (rise_o < -0.05f ? 12.0f * DEG : -th_hs);
			else
				F.land_pitch = prof.slope > 8.0f * DEG ? 0.0f : -th_hs;
			if (F.u < 0.45f)
				th = F.lift_pitch * (1.0f - smooth01(F.u / 0.45f));
			else
				th = F.land_pitch * smooth01((F.u - 0.55f) / 0.45f);
			F.pitch = th;
			F.toe = F.lift_toe * (1.0f - smooth01(F.u / 0.3f));
			F.pivot = th >= 0 ? 3 : 1;
			float rise = std::max(0.0f, F.target.y - F.lift.y);
			(void)rise;
			float c_nom = c_mid * std::sin(PI_F * F.u) + c_early * std::sin(PI_F * clampf(F.u / 0.5f, 0, 1));
			if (stopping && s < 0.3f) c_nom *= 0.6f; // a small adjusting step
			// 2.7 / 2.8: each sole point (heel, ball, toe tip) clears the ground under it by 3-5 cm, and the toe also what
			// is just ahead of it (a kerb face, the next nosing); the margin fades at lift-off and touchdown
			float c_prev = F.clearance;
			F.clearance = 0;
			Vector3 a0;
			Basis r0;
			foot_pose(i, a0, r0);
			Vector3 Av(0, d.ankle_h[i], 0);
			float bz = d.ball[i].z, tz = d.ball[i].z + d.toe_len[i];
			Vector3 pts[3] = { a0 + r0.xform(d.heel[i] - Av), a0 + r0.xform(Vector3(0, 0, bz) - Av), a0 + r0.xform(Vector3(0, 0, tz) - Av) };
			float margin = 0.04f * std::min(1.0f, std::min(F.u / 0.15f, (1.0f - F.u) / 0.12f));
			float need = 0;
			for (int q = 0; q < 3; q++) {
				float xq = prof.x_of(pts[q]);
				float g = prof.max_h(xq - 0.02f, xq + 0.02f);
				if (g > pts[q].y - 0.01f) need = std::max(need, g + margin - pts[q].y);
			}
			{
				float xtip = prof.x_of(pts[2]);
				float xt = prof.x_of(F.target);
				float look = 0.10f + 0.25f * (1.0f - F.u);
				float hi_x = std::min(xtip + look, xt + tz - 0.05f);
				if (hi_x > xtip) {
					float g = prof.max_h(xtip, hi_x);
					if (g > pts[2].y - 0.01f) need = std::max(need, g + margin - pts[2].y);
				}
			}
			float c = std::max(c_nom, need);
			if (c > c_prev + 2.5f * dt) c = std::max(std::min(c_nom, c_prev + 2.5f * dt), c_prev + 2.5f * dt); // no snap up
			F.clearance = std::max(c, 0.0f);
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
	// 2.7: the hips glide on the line between the support foot and where the next foot goes, not step by step
	float ground_y;
	{
		Vector3 a, b;
		if (foot[0].planted && foot[1].planted) {
			a = foot[0].plant;
			b = foot[1].plant;
		} else {
			int st = foot[0].planted ? 0 : 1;
			a = foot[st].plant;
			b = foot[1 - st].planted ? foot[1 - st].plant : foot[1 - st].target;
		}
		Vector3 ab = flat(b - a);
		float l2 = ab.length_squared();
		float tt = l2 > 0.0025f ? clampf(flat(in.pos + lean_off - a).dot(ab) / l2, 0.0f, 1.0f) : 0.5f;
		ground_y = lerpf(a.y, b.y, tt);
	}
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
	// a swinging foot near touchdown: the hips aim low enough to meet it where it will land (soft, through the spring)
	for (int i = 0; i < 2; i++) {
		const Foot &F = foot[i];
		float u0 = lerpf(0.6f, 0.45f, gait_w);
		if (F.planted || F.u < u0 || !active) continue;
		Vector3 hip = in.pos + lean_off + hips_side.x + yaw_basis(yaw).xform(flat(d.hip_off[i])) + vel * F.t_rem;
		Vector3 ank = F.target + UP * d.ankle_h[i];
		float Lm = 0.985f * d.leg(i);
		float dxz2 = flat(ank - hip).length_squared();
		float ym = ank.y + std::sqrt(std::max(0.0f, Lm * Lm - dxz2)) - d.hip_off[i].y;
		float w = smooth01((F.u - u0) / (1.0f - u0));
		h = std::min(h, lerpf(std::max(h, ym), ym, w));
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

	// pelvis follows the lower foot (2.6, 4.5): a planted leg is kept within 97.5 % of its length, the hips lowering
	// at most 1.8 cm a frame (4.6 item 5); past 99.5 % (out of the soft-IK zone) the limit is immediate so the foot
	// never slides. The limit is fed back into the spring so releasing it is smooth.
	{
		Basis Rp = L * yaw_basis(yaw);
		float y_soft = 1e9f, y_hard = 1e9f;
		for (int i = 0; i < 2; i++) {
			if (!foot[i].planted) continue;
			Vector3 hip = t.hips_pos + Rp.xform(d.hip_off[i]);
			Vector3 dv = ankles[i] - hip;
			float dxz2 = dv.x * dv.x + dv.z * dv.z;
			float L1 = 0.975f * d.leg(i), L2 = 0.995f * d.leg(i);
			y_soft = std::min(y_soft, ankles[i].y + std::sqrt(std::max(0.0f, L1 * L1 - dxz2)) - d.hip_off[i].y);
			y_hard = std::min(y_hard, ankles[i].y + std::sqrt(std::max(0.0f, L2 * L2 - dxz2)) - d.hip_off[i].y);
		}
		float y_max = std::max(y_soft, t.hips_pos.y - 0.018f);
		y_max = std::min(y_max, y_hard);
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
	Basis trunk = L * R_body * Basis(UP, -1.3f * yaw_osc) * Basis(Vector3(1, 0, 0), posture + br + posture_extra);
	t.trunk_rot = trunk.get_rotation_quaternion();
	float look_pitch = (active ? 5.0f * DEG : 0.0f) + look_down;
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
