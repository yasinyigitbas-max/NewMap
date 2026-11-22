// mo::Motor, step 7: jumps, falls off edges and landings (Yasin, 23 Nov: "in place jumps are terrible, use other
// animations, it looks like climbing an invisible wall"; "better edge jump down, use soft or hard landing like festive
// work"). Festive's clips only (ptrav), none of its code; its thresholds as the spec: a drop from a ledge from 0.5 m;
// landing by the height fallen - under 3 m soft, from 3 m hard, from 5 m hard 90 % / flat 10 %, from 7 m flat.
//
// A JUMP standing or walking: Jumping_Up (the take-off, the feet leaving the ground), then a real flight - the body
// thrown up 4.3 m/s with the pace it had, gravity on it, a little steering - in the air pose (Falling_Idle). Running:
// Running_Jump_a, its own leap (a root clip). Off an edge: the same flight from the pace he had.
// THE LANDING is chosen by the height fallen and started so that its own first touch of the feet comes as the body
// reaches the ground (the time to it from the flight); a root clip from there (its hips carry the body), then he stands,
// or walks / runs on if the stick is held.
#include "mo_motor.h"

#include "city_ped.h"
#include "mo_inertial.h"
#include "mo_limbs.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>

using namespace godot;
using namespace godot::mo;

namespace {
const Vector3 UP(0, 1, 0);
const float G = 9.8f;
Vector3 lvl(const Vector3 &v) { return Vector3(v.x, 0.0f, v.z); }
// the first moment a clip has a foot down (its landing's touch)
double first_touch(const Clip &c) {
	if (!c.ok()) return 0.0;
	for (int k = 0; k < (int)c.d->f.size(); k++) if (c.d->f[k].down[0] || c.d->f[k].down[1]) return k / 30.0;
	return 0.0;
}
} // namespace

void Motor::load_air() {
	ai_up = load("ptrav/Jumping_Up"); ai_loop = load("ptrav/Falling_Idle"); ai_run = load("ptrav/Running_Jump_a");
	ai_stand = load("ptrav/Jump_a"); ai_stand2 = load("ms/S3_Jump_In_Place");   // (Yasin, 24 Nov: "set 1, 3 jump standing rotate randomly") ai_walk = load("ptrav/Jumping_c");   // (Yasin, 24 Nov: the standing and walking jumps were the bad ones - festive's own jumps instead)
	ai_soft = load("ptrav/Falling_To_Landing"); ai_hard = load("ptrav/Hard_Landing_b");
	ai_flat = load("ptrav/Falling_Flat_Impact"); ai_getup = load("ptrav/Getting_Up");
	tc_soft = first_touch(ai_soft); tc_hard = first_touch(ai_hard); tc_flat = first_touch(ai_flat);
	load_descent(dn_hop, "mx/Ledge_Climb_Down"); load_descent(dn_jump, "mx/Ledge_Drop"); load_descent(dn_climb, "mx/Climbing_Down");   // (Yasin's own clips, 24 Nov: "use this climb down animation for 1 meter, for 1.8m use this jump off anim for walk off")
}

// a descent clip measured: how high its ledge is over its floor (its feet at the start against at the end), when its
// feet leave the ledge and when they come down
void Motor::load_descent(Descent &r_d, const char *p_name) {
	r_d.c = load(p_name);
	if (!r_d.c.ok()) return;
	const ClipData &D = *r_d.c.d;
	const int n = (int)D.f.size();
	const float y0 = std::min((float)D.f[0].foot[0].y, (float)D.f[0].foot[1].y), y1 = std::min((float)D.f[n - 1].foot[0].y, (float)D.f[n - 1].foot[1].y);
	r_d.ledge_h = y0 - y1;
	int k_off = 0, k_land = n - 1;
	for (int k = 0; k < n; k++) { if (std::min((float)D.f[k].foot[0].y, (float)D.f[k].foot[1].y) > y0 - 0.06f) k_off = k; else break; }
	for (int k = k_off; k < n; k++) if (std::min((float)D.f[k].foot[0].y, (float)D.f[k].foot[1].y) < y1 + 0.04f) { k_land = k; break; }
	r_d.t_off = k_off / 30.0; r_d.t_land = k_land / 30.0;
	// its feet below its ledge (from here the floor may go down: lowered sooner, they sank into the ledge - Yasin, 24 Nov:
	// "landing character clips into the shape")
	int k_drop = k_land;
	for (int k = k_off; k < k_land; k++) if (std::min((float)D.f[k].foot[0].y, (float)D.f[k].foot[1].y) < y0 - 0.05f) { k_drop = k; break; }
	r_d.t_drop = k_drop / 30.0;
	// ITS CORNER: where the hand going down past its ledge's top passes it (a hand brushes the corner as he drops - Yasin,
	// 24 Nov: "the hand doesnt reach the corner of the obstacle"); its edge is there. (Taken from the foot that pushed off,
	// the take was placed 20 cm short: the feet went down inside the ledge.)
	const float top = y0 - 0.10f;   // (its ledge's top: the ankles stand 10 cm over it)
	r_d.hand = -1; int kc = -1;
	for (int k = std::max(0, k_drop - 12); k < k_land && kc < 0; k++) for (int h = 0; h < 2; h++)
		if ((float)D.f[k].hand[h].y < top + 0.12f && (float)D.f[k].hand[h].z > 0.2f) { kc = k; r_d.hand = h; break; }
	if (kc >= 0) {
		r_d.edge_z = (float)D.f[kc].hand[r_d.hand].z;
		r_d.h0 = kc / 30.0 - 0.12; r_d.h1 = kc / 30.0 + 0.06;
	} else r_d.edge_z = std::min((float)D.f[k_drop].foot[0].z, (float)D.f[k_drop].foot[1].z) - 0.15f;
}

// walking at a ledge: the drop just ahead, the move for it, fitted so its feet leave this edge and land on that ground
bool Motor::descend_probe(const Vector3 &p_fwd) {
	if (!host) return false;
	const Vector3 p = host->position();
	const float here = ground_below(p, 0.6f);
	if (here < -1e8f) return false;
	float drop = -1.0f, ground = 0.0f;
	for (float a = 0.25f; a <= 1.25f; a += 0.1f) {   // (as far as the take starts from its edge)
		const Vector3 q = p + p_fwd * a;
		const float g = ground_below(Vector3(q.x, here + 1.2f, q.z), 4.2f);   // (from over his head: from his feet, up a 30 deg ramp the ray began inside it and saw a drop)
		if (g > here - 0.1f && g > -1e8f) continue;
		if (g < -1e8f) { drop = 9.0f; break; }
		if (here - g >= 0.5f) { drop = here - g; ground = g; break; }   // (under 0.5 m: stepped down, the feet fitted)
		return false;   // (the ground going down by less first: stairs, a ramp - walked down, not jumped off; looking 1.25 m on,
		// the steps of a stair added up to a "ledge")
	}
	if (drop < 0.5f || drop > 2.0f) return false;   // (no drop; or higher: the fall and its landing)
	// (Yasin, 24 Nov: "walk off 1m goes away, we use walk off 1.8m for both") - his Jumping Down for every height
	Descent *d = &dn_jump;
	if (!d->c.ok()) load_descent(*d, "mx/Ledge_Drop");   // (the "mx" library can come after the motor)
	if (!d->c.ok()) return false;
	// the edge, to 2 cm, and his distance to it against the clip's own: walked on until they agree (its feet push off its
	// edge, the step before it lands where his are)
	float de = 1.4f;
	for (float a = 0.0f; a <= 1.4f; a += 0.02f) {
		const Vector3 q = p + p_fwd * a;
		const float g = ground_below(Vector3(q.x, here + 1.2f, q.z), 4.2f);
		if (g < -1e8f || g < here - 0.3f) { de = a; break; }
	}
	{   // (a sheer edge: just short of it the ground is still his level)
		const Vector3 q = p + p_fwd * std::max(0.0f, de - 0.06f);
		const float g = ground_below(Vector3(q.x, here + 1.2f, q.z), 4.2f);
		if (g < here - 0.1f) return false;
	}
	const float want_d = d->edge_z - (float)d->c.d->f[0].hips.z;
	if (de > want_d + 0.04f) return false;   // (not there yet)
	if (limbs) { limbs->lock_on = false; limbs->unlock_all(); }
	rate = 1.0f;
	root_start(d->c, 0.0, 0.25f, yaw, nullptr, false);
	rp.vy_on = true;
	rp.ay_from = here - d->ledge_h;   // (its floor where its feet stand on this ledge)
	rp.ay_to = ground;                // (its floor on the ground below)
	rp.vy_t0 = std::max(d->t_off, d->t_drop - 0.12); rp.vy_t1 = std::max(d->t_land, rp.vy_t0 + 0.1);
	if (de < want_d) {   // (a little too close: the clip moved back that much while he still stands, before he pushes off)
		rp.a_to = rp.a_from - p_fwd * (want_d - de); rp.a_to.y = rp.a_from.y; rp.t0 = 0.0; rp.t_warp = std::max(0.2, d->t_off * 0.6);
	}
	dn_cur = d; dn_edge = p + p_fwd * de; dn_edge.y = here; dn_n = -p_fwd;
	// the moment, on this ledge, a hand going down passes its top (lowered at another rate than the clip's own ledge, its
	// hand passes the corner sooner or later than in the take): the hand pinned on the corner around it
	dn_hand = -1;
	for (double tt = d->t_off; tt < d->t_land && dn_hand < 0; tt += 1.0 / 30.0) {
		const Frame f = d->c.d->lerp(tt);
		for (int h = 0; h < 2; h++) {
			const Vector3 w = root_anchor(tt) + Basis(UP, rp.yaw).xform(f.hand[h]);
			if ((float)w.y < here + 0.12f && (float)(w - dn_edge).dot(p_fwd) > -0.6f) { dn_hand = h; dn_h0 = tt - 0.12; dn_h1 = tt + 0.16; break; }
		}
	}
	rp.a_from.y = rp.ay_from; rp.a_to.y = rp.ay_to;
	fig->set_global_transform(Transform3D(Basis(UP, rp.yaw), root_anchor(0.0)));
	st = DESCEND; n_descents++;
	if (std::getenv("MO_DBG")) std::printf("DESCEND drop %.2f at %.2f %.2f %.2f\n", drop, (float)p.x, (float)p.y, (float)p.z);
	return true;
}

bool Motor::air_ready() const { return ai_up.ok() && ai_loop.ok() && ai_soft.ok() && ai_hard.ok(); }

// the ground under a point within p_down (none: -1e9)
float Motor::ground_below(const Vector3 &p_at, float p_down) const {
	if (!host) return -1e9f;
	Vector3 g, n;
	if (host->ray(p_at + Vector3(0, 0.3f, 0), p_at - Vector3(0, p_down, 0), g, n) && n.y > 0.5f) return (float)g.y;
	return -1e9f;
}

void Motor::jump_start(const Vector3 &p_dir, float p_want_speed) {
	if (limbs) { limbs->lock_on = false; limbs->unlock_all(); }
	jump_chain = since_land < 2.5f ? jump_chain + 1 : 1;   // (back to back: within 2.5 s of the last landing - stamina)
	if (speed > 2.2f && ai_run.ok()) {   // running: the running leap (its own travel; Yasin, 24 Nov: "revert the running jump to previous one")
		rate = std::min(std::max(speed / 4.2f, 0.75f), 1.15f);
		root_start(ai_run, 0.0, 0.15f, yaw, nullptr, false);
		rp.c = &ai_run;
		st = RUNJUMP; n_jumps++;
		return;
	}
	// standing or walking: festive's whole jump in place, Jump_a (Yasin, 24 Nov: "jump standing is okay, use that for
	// jump walking too"). Walking, it is entered after its idle start, and carries him on at his pace while his feet are
	// off the ground (its flight 0.7 - 1.33 s).
	if (ai_stand.ok()) {
		const bool walking = speed >= 0.3f;
		if (p_dir.length() > 0.1f && !walking) yaw = std::atan2((float)p_dir.x, (float)p_dir.z);
		const float pace = walking ? std::min(speed, 1.6f) : 0.0f;
		rate = 1.0f;
		const Clip &J = (ai_stand2.ok() && rnd() < 0.5f) ? ai_stand2 : ai_stand;
		root_start(J, walking ? std::min(0.3, J.d->len * 0.15) : 0.0, walking ? 0.2f : 0.15f, yaw, nullptr, false);
		rp.c = &J;
		if (pace > 0.0f) {   // (carried on at his pace while both feet are off the ground: its own flight)
			int k0 = -1, k1 = -1;
			for (int k = 0; k < (int)J.d->f.size(); k++) if (!J.d->f[k].down[0] && !J.d->f[k].down[1]) { if (k0 < 0) k0 = k; k1 = k; }
			const double f0 = k0 >= 0 ? k0 / 30.0 : 0.62, f1 = k1 >= 0 ? (k1 + 1) / 30.0 : 1.4;
			rp.a_to = rp.a_from + fwd_of_yaw() * pace * (float)(f1 - f0 + 0.15);
			rp.t0 = f0 - 0.08; rp.t_warp = f1 + 0.08;
		}
		st = RUNJUMP; n_jumps++;
		return;
	}
	// (else: the take-off, then the flight)
	air_v = lvl(fwd_of_yaw()) * std::min(speed, 1.6f);
	if (p_dir.length() > 0.1f && speed < 0.3f) air_v = lvl(p_dir).normalized() * std::min(p_want_speed, 1.2f);   // (from a stand, a hop the way pushed)
	rate = 1.0f;
	play(ai_up, 0.0, 0.12f);
	st = JUMP; n_jumps++;
}

void Motor::air_start(const Vector3 &p_vel, bool p_from_jump) {
	if (limbs) { limbs->lock_on = false; limbs->unlock_all(); }
	air_v = p_vel;
	air_top = (float)host->position().y;
	air_t = 0.0f;
	rate = 1.0f; turn_k = 1.0f;
	face_only = true;   // (the body is the flight's: no alignment)
	play(ai_loop, 0.0, p_from_jump ? 0.15f : 0.25f);
	st = AIR; n_falls += p_from_jump ? 0 : 1;
}

// the flight: gravity, a little steering; the landing chosen and started so its touch meets the ground
void Motor::air_step(float p_dt, const Intent &p_in) {
	air_t += p_dt;
	advance(p_dt);
	const Vector3 dir = lvl(p_in.dir);
	if (dir.length() > 0.1f) air_v += dir.normalized() * std::min((float)dir.length(), 1.0f) * 1.5f * p_dt;   // (a little steering)
	const Vector3 hv = lvl(air_v);
	if (hv.length() > 0.3f) yaw += std::remainder(std::atan2((float)hv.x, (float)hv.z) - yaw, 6.2831853f) * std::min(1.0f, 3.0f * p_dt);
	air_v.y -= G * p_dt;
	const Vector3 p = host->position();
	air_top = std::max(air_top, (float)p.y);
	// THE LANDING: the time to the ground ahead along the flight
	const float gy = ground_below(p + lvl(air_v) * 0.1f, 60.0f);
	if (gy > -1e8f) {
		const float h = (float)p.y - gy;
		const float vy = (float)air_v.y;
		const float tau = (vy + std::sqrt(std::max(0.0f, vy * vy + 2.0f * G * h))) / G;   // (h + vy t - g t^2 / 2 = 0)
		const float fallen = air_top - gy;
		const Clip *lc = &ai_soft; double tc = tc_soft;
		if (fallen >= 7.0f && ai_flat.ok()) { lc = &ai_flat; tc = tc_flat; }
		else if (fallen >= 5.0f && ai_flat.ok() && rnd() < 0.1f) { lc = &ai_flat; tc = tc_flat; }
		else if (fallen >= 3.0f) { lc = &ai_hard; tc = tc_hard; }
		if (air_v.y < 0.0f && tau <= tc + 1e-3) {
			land_fallen = fallen;
			const Vector3 land = Vector3(p.x, gy, p.z) + lvl(air_v) * tau;
			// the landing clip: its hips at its touch over where he comes down; the body follows it from here
			const Frame ft = lc->d->lerp(tc);
			host->teleport(Vector3(p.x, gy, p.z));
			draw_y = gy; draw_v = 0.0f; draw_ok = true;
			root_start(*lc, std::max(0.0, tc - tau), 0.12f, yaw, nullptr, false);
			// (its anchor: the clip's hips at its touch over the landing spot, the floor the ground)
			rp.a_from = land - Basis(UP, yaw).xform(lvl(ft.hips)); rp.a_from.y = gy;
			rp.a_to = rp.a_from;
			fig->set_global_transform(Transform3D(Basis(UP, yaw), rp.a_from));
			st = LAND; n_landings++;
			if (lc == &ai_hard) n_hard++; else if (lc == &ai_flat) n_flat++; else n_soft++;
			return;
		}
	}
	// on in the flight
	const Vector3 got = host->slide(air_v, p_dt);
	if (host->on_floor() && air_v.y < 0.0f) {   // (down sooner than the rays saw: a soft landing from its touch)
		land_fallen = air_top - (float)host->position().y;
		draw_y = (float)host->position().y; draw_ok = true;
		root_start(ai_soft, tc_soft, 0.12f, yaw, nullptr, false);
		st = LAND; n_landings++; n_soft++;
		return;
	}
	(void)got;
	draw_y = (float)host->position().y; draw_ok = true;
	fig->set_global_transform(Transform3D(Basis(UP, yaw), host->position()));
	speed = (float)lvl(air_v).length();
}

Vector3 Motor::fwd_of_yaw() const { return Vector3(std::sin(yaw), 0.0f, std::cos(yaw)); }

// A JUMP ASKED WHILE RUNNING: the run goes on (at most 0.35 s) to the stride most like the leap's take-off, then the leap
// from there (Yasin, 23 Nov: "jumping while jogging is bad": begun on whatever foot was down, it began with a stumble)
bool Motor::run_jump_when() {
	if (!ai_run.ok() || loop_i < 0) return true;
	const Clip &L = loops[loop_i];
	double best_w = 0.0; float best_c = 1e30f;
	for (double w = 0.0; w <= 0.35 + 1e-6; w += 1.0 / 60.0) {
		float c = 0.0f;
		best_entry(*L.d, t + w * rate, *ai_run.d, 0.0, std::min(0.3, ai_run.d->len * 0.35), &c);
		c += 0.1f * (float)w;
		if (c < best_c) { best_c = c; best_w = w; }
	}
	return best_w < 0.5 / 60.0;
}
