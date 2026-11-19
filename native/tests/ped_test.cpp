// A person's balancing body on a test floor, without the game (plain C++, a console program):
//   bash native/tests/run_ped_test.sh
// It stands one person up and does to it what the game will: nothing (it must stand still), shoves (each a push
// lasting a fifth of a second) of growing
// strength at the chest from the front, the back and the side (it must hold the small ones without a step, stagger
// and catch the middle ones, go down under the big ones and come to rest), a shove at one shoulder, a kick at a leg,
// a frail person, a slope, a car at walking pace and a car at 30 km/h. It prints one line each and PASS / FAIL.
// What "PASS" means here: the body behaves as a body (stands, staggers, falls, lies still), nothing explodes, nothing
// sinks into the ground or stays inside the car. How it LOOKS is not tested here.
#include "../src/ped_body.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>

using namespace pb;

static const float DT = 1.0f / 60.0f;

struct Out {
	bool fell = false, rested = false, settled = false, bad = false, in_box = false;
	int steps = 0;
	float max_tilt = 0, moved = 0, t_settle = -1, t_rest = -1, max_speed = 0, sunk = 0, end_h = 0;
};

struct Case {
	const char *name;
	float imp = 0;        // N s
	vd::V3 dir{ 0, 0, 1 };
	int body = B_CHEST;
	float skill = 1.0f, slope = 0.0f;
	float car = 0.0f;     // a car's speed along +z, m/s (0 = no car)
	float secs = 11.0f;
};

static bool g_trace = false;
static Out run(const Case &k) {
	Out o;
	Person p;
	const float th = std::atan(k.slope);
	p.gn = vd::V3{ 0, std::cos(th), -std::sin(th) }; p.gd = 0;   // (set before build: it stands the person on it)
	p.skill = k.skill;
	p.build(Rest());
	p.skill = k.skill;
	Box car; car.half = vd::V3{ 0.95f, 0.65f, 2.3f }; car.c = vd::V3{ 0, 0.85f, -9.0f }; car.v = vd::V3{ 0, 0, k.car };
	vd::V3 c0{};
	float t_push = 1.0f;
	const int n = (int)(k.secs / DT);
	for (int f = 0; f < n; f++) {
		const float t = f * DT;
		if (k.car > 0.0f) {   // the car comes, and brakes to a stop a little after the place the person stood
			if (t > 1.0f) { car.c = car.c + car.v * DT; if (car.c.z > 4.0f) car.v.z = std::max(0.0f, car.v.z - 7.0f * DT); }
			p.box[0] = car; p.n_box = 1;
		}
		if (f == (int)(t_push / DT)) c0 = p.com();
		// a shove is a push that lasts a fifth of a second (a hand, a shoulder), not a hammer blow
		if (k.imp > 0.0f && t >= t_push && t < t_push + 0.2f - 1.0e-4f) p.impulse(k.body, p.b[k.body].x, vd::norm(k.dir) * (k.imp * DT / 0.2f));
		p.step(DT);
		if (g_trace && t > t_push - 0.05f && t < t_push + 3.0f && f % 3 == 0) {
			const vd::V3 c = p.com(), v = p.com_v();
			std::printf("  t %.2f st %d | com (%.2f %.2f %.2f) v (%.2f %.2f %.2f) | pelvis y %.2f lean %.0f | feet L (%.2f %.2f)%s R (%.2f %.2f)%s | steps %d strength %.2f\n", t - t_push, p.state, c.x, c.y, c.z, v.x, v.y, v.z,
					p.b[B_PELVIS].x.y, p.tilt * 57.3f, p.foot[0].p.x, p.foot[0].p.z, p.foot[0].planted ? "" : "^", p.foot[1].p.x, p.foot[1].p.z, p.foot[1].planted ? "" : "^", p.steps, p.strength);
		}
		for (int i = 0; i < NB; i++) {
			const Body &B = p.b[i];
			if (!(B.x.x == B.x.x) || !(B.q.w == B.q.w) || std::fabs(B.x.x) > 1.0e4f) o.bad = true;
		}
		if (o.bad) break;
		if (t > t_push) {
			o.max_tilt = std::max(o.max_tilt, p.tilt);
			o.steps = std::max(o.steps, p.steps);
			if (p.state != ST_BALANCE) o.fell = true;
			if (p.state == ST_REST && o.t_rest < 0) { o.t_rest = t - t_push; o.rested = true; }
			if (p.state == ST_BALANCE && p.settled && o.t_settle < 0 && t > t_push + 0.3f) { o.t_settle = t - t_push; o.settled = true; }
			if (!p.settled && p.state == ST_BALANCE && o.t_settle >= 0 && p.quiet == 0.0f && false) o.t_settle = -1;
		}
	}
	const vd::V3 c1 = p.com();
	o.moved = std::sqrt((c1.x - c0.x) * (c1.x - c0.x) + (c1.z - c0.z) * (c1.z - c0.z));
	o.max_speed = p.max_speed;
	o.end_h = p.b[B_PELVIS].x.y - (p.gd - p.gn.x * p.b[B_PELVIS].x.x - p.gn.z * p.b[B_PELVIS].x.z) / p.gn.y;
	for (int i = 0; i < NB; i++) {   // how far any part ends under the ground, and whether one ends inside the car
		const Body &B = p.b[i];
		for (int e = 0; e < 2; e++) {
			const vd::V3 q = B.x + vd::rot(B.q, e == 0 ? B.a : B.b);
			o.sunk = std::max(o.sunk, B.r - (vd::dot(q, p.gn) - p.gd));
			if (k.car > 0.0f) {
				const vd::V3 d = q - car.c;
				if (std::fabs(d.x) < car.half.x - 0.05f && std::fabs(d.y) < car.half.y - 0.05f && std::fabs(d.z) < car.half.z - 0.05f) o.in_box = true;
			}
		}
	}
	return o;
}

int main(int argc, char **argv) {
	const int only = argc > 1 ? std::atoi(argv[1]) : -1;
	g_trace = only >= 0;
	const vd::V3 F{ 0, 0, 1 }, Bk{ 0, 0, -1 }, L{ 1, 0, 0 };
	// what must happen: 0 = whatever, 1 = stays on its feet, 2 = goes down and lies still
	struct Row { Case c; int must; int max_steps; };
	const Row rows[] = {
		{ { "stands, nothing done to it", 0, F }, 1, 0 },
		{ { "stands on a slope of 14 %", 0, F, B_CHEST, 1.0f, 0.14f }, 1, 0 },
		{ { "a nudge from behind, 15 N s", 15, F }, 1, 0 },
		{ { "a push from behind, 30 N s", 30, F }, 1, 1 },
		{ { "a push from behind, 50 N s", 50, F }, 1, 99 },
		{ { "a shove from behind, 80 N s", 80, F }, 1, 99 },
		{ { "a hard shove from behind, 120 N s", 120, F }, 0, 99 },
		{ { "a hard shove from behind, 170 N s", 170, F }, 0, 99 },
		{ { "a charge from behind, 240 N s", 240, F }, 0, 99 },
		{ { "run into from behind, 400 N s", 400, F }, 2, 99 },
		{ { "a push in the chest, 30 N s", 30, Bk }, 1, 1 },
		{ { "a shove in the chest, 80 N s", 80, Bk }, 1, 99 },
		{ { "a hard shove in the chest, 170 N s", 170, Bk }, 0, 99 },
		{ { "run into from the front, 400 N s", 400, Bk }, 2, 99 },
		{ { "a push from the side, 30 N s", 30, L }, 1, 1 },
		{ { "a shove from the side, 80 N s", 80, L }, 1, 99 },
		{ { "a hard shove from the side, 170 N s", 170, L }, 0, 99 },
		{ { "run into from the side, 400 N s", 400, L }, 2, 99 },
		{ { "a shove at one shoulder, 60 N s", 60, F, B_UARM_L }, 1, 99 },
		{ { "a kick at one leg, 90 N s", 90, L, B_CALF_L }, 0, 99 },
		{ { "a frail person, a push of 50 N s", 50, F, B_CHEST, 0.55f }, 0, 99 },
		{ { "a frail person, a shove of 120 N s", 120, F, B_CHEST, 0.55f }, 0, 99 },
		{ { "an athlete, a hard shove of 170 N s", 170, F, B_CHEST, 1.3f }, 0, 99 },
		{ { "a car at walking pace (5 km/h)", 0, F, B_CHEST, 1.0f, 0.0f, 1.4f, 14.0f }, 0, 99 },
		{ { "a car at 30 km/h", 0, F, B_CHEST, 1.0f, 0.0f, 8.3f, 12.0f }, 2, 99 },
		{ { "a car at 60 km/h", 0, F, B_CHEST, 1.0f, 0.0f, 16.7f, 12.0f }, 2, 99 },
	};
	int fails = 0;
	std::printf("BODY  what | outcome | steps | most lean deg | moved m | on its feet and quiet after s | lying still after s | fastest part m/s | sunk m\n");
	int ri = -1;
	for (const Row &r : rows) {
		ri++;
		if (only >= 0 && ri != only) continue;
		const Out o = run(r.c);
		char why[200] = "";
		auto bad = [&](bool c, const char *w) { if (c) { std::snprintf(why + std::strlen(why), sizeof(why) - std::strlen(why), "%s; ", w); } };
		bad(o.bad, "wild numbers");
		bad(o.max_speed > 30.0f, "a part flew off");
		bad(o.sunk > 0.06f, "sunk into the ground");
		bad(o.in_box, "ends inside the car");
		bad(r.must == 1 && o.fell, "fell");
		bad(r.must == 1 && !o.settled, "never stood quietly again");
		bad(r.must == 1 && o.steps > r.max_steps, "took steps it should not need");
		bad(r.must == 2 && !o.fell, "did not go down");
		bad(o.fell && !o.rested, "never lay still");
		const bool ok = why[0] == 0;
		if (!ok) fails++;
		std::printf("BODY  %-38s | %-22s | %d | %4.0f | %5.2f | %5.1f | %5.1f | %5.1f | %.3f | %s%s\n", r.c.name,
				o.fell ? (o.rested ? "goes down, lies still" : "goes down") : (o.settled ? "stays on its feet" : "on its feet, unsteady"),
				o.steps, o.max_tilt * 57.3f, o.moved, o.t_settle, o.t_rest, o.max_speed, std::max(o.sunk, 0.0f), ok ? "ok" : "FAIL: ", why);
	}
	std::printf("RESULT %s\n", fails == 0 ? "PASS" : "FAIL");
	return fails == 0 ? 0 : 1;
}
