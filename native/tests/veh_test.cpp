// The physical car on a test track, without the game (plain C++, a console program):
//   bash native/tests/run_veh_test.sh            every car in both feels, one line each + PASS / FAIL
//   bash native/tests/run_veh_test.sh stern_g    one car, with the reasons
// What it drives: standing still (must not creep or shake), a 15 % hill on the handbrake, 0-100 km/h, top speed,
// 100-0 braking, a slowly tightening turn at 72 km/h (most side grip, how far the body leans, does it push or spin),
// a sudden turn of the wheel at 80 km/h (does it settle), a handbrake turn at 50 km/h (does the tail come round).
#include "../src/veh_dyn.h"

#include <algorithm>
#include <cstdio>
#include <cstring>

using namespace vd;

static const char *NAMES[12] = { "stern_e", "volt_s", "stern_g", "volt_x", "sakura_t", "sakura", "van", "fiamma_r", "fiamma_gt", "taxi", "bus_city", "bus_mini" };
static const float DT = 1.0f / 60.0f;
static const int SUB = 6;

struct Rig {
	Car car;
	Chassis c;
	V3 n{ 0, 1, 0 };   // the ground: a plane through the origin
	float t = 0;
	void start(int model, int feel, float slope) {
		car.init(make_spec(model, feel));
		const float th = std::atan(slope);
		n = { 0, std::cos(th), -std::sin(th) };   // rises along +z
		c = Chassis();
		c.q = { std::sin(-th * 0.5f), 0, 0, std::cos(-th * 0.5f) };
		c.p = n * car.rest_height();
		t = 0;
	}
	void tick() {
		for (int i = 0; i < 4; i++) {
			V3 from, dir; float L;
			car.ray(i, c, from, dir, L);
			const float dn = dot(dir, n);
			const float d = dn < -1e-4f ? -dot(from, n) / dn : 1e9f;
			car.set_ground(i, d >= 0.0f && d <= L, from + dir * d, n, 1.0f);
		}
		car.step(c, DT, SUB, true);
		t += DT;
	}
	float roll_deg() const { return std::asin(clampf(rot(c.q, V3{ 1, 0, 0 }).y, -1, 1)) * 57.296f; }
	float pitch_deg() const { return std::asin(clampf(rot(c.q, V3{ 0, 0, 1 }).y, -1, 1)) * 57.296f; }
	float yaw_rate() const { return dot(c.w, rot(c.q, V3{ 0, 1, 0 })); }
	float beta_deg() const { const V3 f = rot(c.q, V3{ 0, 0, 1 }), l = rot(c.q, V3{ 1, 0, 0 }); return std::atan2(dot(c.v, l), std::fabs(dot(c.v, f)) + 0.01f) * 57.296f; }
	// hold a speed with the pedals
	void cruise(float v, float most = 1.0f) { const float e = v - car.speed; car.in.throttle = clampf(e * 0.8f + 0.12f, 0, most); car.in.brake = clampf(-e * 0.5f - 0.3f, 0, 1); }
	void to_speed(float v) { car.in = Input(); for (int k = 0; k < 60 * 60 && car.speed < v; k++) { car.in.throttle = 1; tick(); } }
};

struct Result {
	float still_move, still_shake, hill_move, t100, top, brake_m, brake_g, lat_g, lean, lean_05, push, step_over, step_settle, hb_turn, launch_slip, dive, squat, power_beta;
	bool spun, step_spun;
};

static Result drive(int model, int feel) {
	Result r{};
	Rig g;
	// standing still for 5 s
	g.start(model, feel, 0.0f);
	g.car.in = Input(); g.car.in.brake = 1;
	float shake = 0;
	for (int k = 0; k < 300; k++) { g.tick(); if (k > 180) shake = std::max(shake, len(g.c.v)); }
	r.still_move = std::sqrt(g.c.p.x * g.c.p.x + g.c.p.z * g.c.p.z); r.still_shake = shake;
	// the hill, handbrake only, 6 s
	g.start(model, feel, 0.15f);
	g.car.in = Input(); g.car.in.handbrake = 1; g.car.in.dir = 0;
	for (int k = 0; k < 120; k++) g.tick();
	const V3 p0 = g.c.p;
	for (int k = 0; k < 360; k++) g.tick();
	r.hill_move = len(g.c.p - p0);
	// 0-100, top speed
	g.start(model, feel, 0.0f);
	for (int k = 0; k < 60; k++) { g.car.in = Input(); g.car.in.brake = 1; g.tick(); }
	g.car.in = Input(); g.car.in.throttle = 1;
	const float t0 = g.t; r.t100 = -1; r.squat = 0; r.launch_slip = 0;
	for (int k = 0; k < 60 * 70; k++) {
		g.tick();
		if (k < 120) { r.squat = std::max(r.squat, g.pitch_deg()); for (int i = 0; i < 4; i++) if (g.car.wh[i].driven) r.launch_slip = std::max(r.launch_slip, g.car.wh[i].slip); }
		if (r.t100 < 0 && g.car.speed >= 27.78f) r.t100 = g.t - t0;
	}
	r.top = g.car.speed * 3.6f;
	// 100-0
	g.start(model, feel, 0.0f);
	g.to_speed(27.9f);
	g.car.in = Input(); g.car.in.brake = 1;
	const V3 b0 = g.c.p; const float v0 = g.car.speed; const float tb = g.t; r.dive = 0;
	for (int k = 0; k < 60 * 20 && g.car.speed > 0.3f; k++) { g.tick(); r.dive = std::min(r.dive, g.pitch_deg()); }
	r.brake_m = len(g.c.p - b0); r.brake_g = v0 / std::max(g.t - tb, 0.01f) / G;
	// a slowly tightening left turn at 72 km/h
	g.start(model, feel, 0.0f);
	g.to_speed(20.0f);
	r.lat_g = 0; r.lean = 0; r.lean_05 = 0; r.spun = false; r.push = 0;
	for (int k = 0; k < 60 * 14; k++) {
		g.car.in = Input(); g.cruise(20.0f, 0.4f);   // a steady foot: enough to hold the speed, not enough to kick the tail out
		g.car.in.steer = clampf((float)k / (60.0f * 12.0f), 0, 1);
		g.tick();
		const float ay = std::fabs(g.car.speed * g.yaw_rate()) / G;
		if (std::fabs(g.beta_deg()) > 35.0f) { r.spun = true; break; }
		if (ay > r.lat_g && std::fabs(g.beta_deg()) < 10.0f) { r.lat_g = ay; r.lean = std::fabs(g.roll_deg()); }
		if (ay > 0.48f && ay < 0.52f) r.lean_05 = std::fabs(g.roll_deg());
		r.push = g.beta_deg();
	}
	// a sudden third of the lock at 80 km/h
	g.start(model, feel, 0.0f);
	g.to_speed(22.2f);
	float peak = 0, last = 0; r.step_spun = false; r.step_settle = 0;
	for (int k = 0; k < 60 * 6; k++) {
		g.car.in = Input(); g.cruise(22.2f, 0.4f);
		// the wheel jerked to what a turn of half a g needs
		g.car.in.steer = k < 30 ? 0.0f : std::atan(g.car.s.wheelbase * 0.5f * G / (22.2f * 22.2f)) * 1.6f / (g.car.s.lock_deg * 0.017453f) / std::min(1.0f, (std::atan(g.car.s.wheelbase * g.car.s.mu * G / (22.2f * 22.2f)) + 1.5f * g.car.s.slip_peak_deg * 0.017453f) / (g.car.s.lock_deg * 0.017453f));
		g.tick();
		const float yr = g.yaw_rate();
		peak = std::max(peak, yr); last = yr;
		if (std::fabs(g.beta_deg()) > 35.0f) { r.step_spun = true; break; }
	}
	r.step_over = last > 0.01f ? peak / last : 0;
	// the tail on the throttle: a steady turn at 50 km/h, then the foot down for 2 s (rear and all wheel drive slide, front pushes)
	g.start(model, feel, 0.0f);
	g.to_speed(13.9f);
	r.power_beta = 0;
	for (int k = 0; k < 60 * 6; k++) {
		g.car.in = Input(); g.cruise(13.9f, 0.4f); g.car.in.steer = 0.45f;
		if (k > 240) { g.car.in.throttle = 1; g.car.in.brake = 0; }
		g.tick();
		if (k > 240) r.power_beta = std::min(r.power_beta, g.beta_deg());
	}
	// handbrake turn at 50 km/h: full lock and the handbrake for 1.6 s
	g.start(model, feel, 0.0f);
	g.to_speed(13.9f);
	const V3 f0 = rot(g.c.q, V3{ 0, 0, 1 });
	for (int k = 0; k < 96; k++) { g.car.in = Input(); g.car.in.steer = 1; g.car.in.handbrake = k > 18 ? 1.0f : 0.0f; g.tick(); }
	const V3 f1 = rot(g.c.q, V3{ 0, 0, 1 });
	r.hb_turn = std::atan2(f0.z * f1.x - f0.x * f1.z, f0.x * f1.x + f0.z * f1.z) * 57.296f;
	return r;
}

int main(int argc, char **argv) {
	const char *only = argc > 1 ? argv[1] : nullptr;
	int fails = 0;
	std::printf("CAR  model      feel | still: moved m, shake m/s | hill moved m | 0-100 s | top km/h | 100-0 m (g) | side grip g | lean at 0.5 g / at most | sudden turn: overshoot | handbrake turn deg | squat / dive deg | wheelspin\n");
	for (int m = 0; m < 12; m++) {
		if (only && std::strcmp(only, NAMES[m]) != 0) continue;
		for (int f = 0; f < 2; f++) {
			const Result r = drive(m, f);
			const bool bus = m >= 10;
			char why[256] = "";
			auto bad = [&](bool c, const char *w) { if (c) { std::strncat(why, w, sizeof(why) - std::strlen(why) - 1); std::strncat(why, "; ", sizeof(why) - std::strlen(why) - 1); } };
			bad(r.still_move > 0.02f || r.still_shake > 0.02f, "does not stand still");
			bad(r.hill_move > 0.05f, "rolls on the hill");
			bad(r.t100 < 0 || r.t100 > (bus ? 60.0f : 16.0f), "too slow to 100");
			bad(r.brake_m > (bus ? 90.0f : 60.0f) || r.brake_m < 28.0f, "braking distance");
			bad(r.lat_g < (bus ? 0.45f : 0.7f) || r.lat_g > 1.35f, "side grip");
			bad(r.step_spun, "spins on a sudden turn");
			bad(r.step_over > 1.6f, "swings after a sudden turn");
			bad(!bus && std::fabs(r.hb_turn) < 35.0f, "handbrake does not bring the tail round");
			const bool ok = why[0] == 0;
			if (!ok) fails++;
			std::printf("CAR  %-10s %s | %.3f %.3f | %.3f | %5.1f | %3.0f | %4.1f (%.2f) | %.2f%s | %.1f / %.1f | %.2f | %4.0f | %.1f / %.1f | %.1f | %s%s\n", NAMES[m], f == 0 ? "IV" : "V ",
				r.still_move, r.still_shake, r.hill_move, r.t100, r.top, r.brake_m, r.brake_g, r.lat_g, r.spun ? " then spins" : "", r.lean_05, r.lean, r.step_over, r.hb_turn, r.squat, r.dive, r.power_beta, ok ? "ok" : "FAIL: ", why);
		}
	}
	std::printf("RESULT %s\n", fails == 0 ? "PASS" : "FAIL");
	return fails == 0 ? 0 : 1;
}
