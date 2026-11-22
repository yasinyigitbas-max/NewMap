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
	ai_soft = load("ptrav/Falling_To_Landing"); ai_hard = load("ptrav/Hard_Landing_b");
	ai_flat = load("ptrav/Falling_Flat_Impact"); ai_getup = load("ptrav/Getting_Up");
	tc_soft = first_touch(ai_soft); tc_hard = first_touch(ai_hard); tc_flat = first_touch(ai_flat);
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
	if (speed > 2.2f && ai_run.ok()) {   // running: the running leap (its own travel)
		rate = std::min(std::max(speed / 4.2f, 0.75f), 1.15f);
		root_start(ai_run, 0.0, 0.15f, yaw, nullptr, false);
		rp.c = &ai_run;
		st = RUNJUMP; n_jumps++;
		return;
	}
	// standing or walking: the take-off, then the flight
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
