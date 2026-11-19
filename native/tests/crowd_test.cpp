// The walking crowd on the map's real pavements, without the game (plain C++, a console program):
//   bash native/tests/run_crowd_test.sh [seed]
// It reads the streets file the game uses and lets the crowd walk on it:
//   A. 500 people all over the map for 30 minutes, checked every second;
//   B. the same again: the same seed must give the same crowd;
//   C. as in the game: at most 150 people in a ring round a camera that drives a circle through the centre;
//   D. cars (dumb ones that never brake, one every 30 s) over every crossing without signals: people must take the
//      gaps (the rule "after 12 s at the kerb step out, the cars will brake" is off here: these cars do not).
// What must be 0: people standing inside each other, people beside their pavement, people on the road part of a
// signalled crossing while its traffic has green, people who have not moved for a minute, (C) people appearing close
// in front of the camera, (D) people in front of a car that is less than a second away.
// How it LOOKS is not tested here, and these cars do not brake: the traffic's own cars are not in this test.
#include "../src/ped_crowd.h"
#include "../src/street_build.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <vector>

using namespace pc;

static const float DT = 0.05f;
static int fails = 0;

static void check(bool ok, const char *what) {
	if (!ok) fails++;
	std::printf("CROWD   %s: %s\n", ok ? "ok" : "FAIL", what);
}

struct Sum {
	long long inside = 0, beside = 0, on_green = 0, checks = 0;
	int stuck_most = 0, most = 0;
	double v_sum = 0, v_n = 0, us_sum = 0, us_worst = 0, wait_most = 0, walking = 0, waiting = 0, crossing = 0, pausing = 0, rows = 0;
	int worst_id = -1; float worst_x = 0, worst_z = 0; int worst_why = 0, worst_seg = -1, worst_kind = 0;
	bool said = false, said2 = false;
};

static void watch(Crowd &c, double clock, Sum &s) {
	int r[4];
	c.audit(clock, r);
	s.inside += r[0]; s.beside += r[1]; s.on_green += r[2]; s.checks++;
	if (r[2] > 0 && !s.said) {   // the first one caught on the road at green: who, where, doing what
		for (int i = 0; i < c.hi; i++) {
			if (!c.alive[i]) continue;
			const Seg &S = c.segs[c.seg[i]];
			if (!(c.on_road(i) && S.phase >= 0 && S.node >= 0 && !c.walk_light(S, clock))) continue;
			const float gone = c.dir[i] > 0 ? c.u[i] : S.len - c.u[i];
			std::printf("CROWD     the first on the road at green: walker %d at %.0f s on crossing %d (%.1f m long), %.1f m over, speed %.2f (his own pace %.2f), why %d, state %d, beside the line %.2f, held %.1f s, standing %.1f s\n",
					c.id[i], clock, c.seg[i], S.len, gone, c.v[i], c.v0[i], (int)c.why[i], (int)c.state[i], c.ls[i] * c.dir[i], c.blocked_t[i], c.still_t[i]);
			s.said = true; break;
		}
	}
	if (r[3] > s.stuck_most) {
		s.stuck_most = r[3];
		for (int i = 0; i < c.hi; i++) if (c.alive[i] && c.still_t[i] > 60.0f) {
			s.worst_id = c.id[i]; s.worst_x = c.x[i]; s.worst_z = c.z[i]; s.worst_why = c.why[i]; s.worst_seg = c.seg[i]; s.worst_kind = c.segs[c.seg[i]].kind;
			if (!s.said2) {
				s.said2 = true;
				const Seg &S = c.segs[c.seg[i]];
				std::printf("CROWD     the first who stands a minute: walker %d at %.0f s, %.1f of %.1f m along %s %d (half width %.2f), going %s, %.2f beside the line (his left +), state %d why %d, held %.1f s, next %d, side step left %.1f s to %.2f\n",
						c.id[i], clock, c.u[i], S.len, S.kind ? "crossing" : "pavement", c.seg[i], S.hw, c.dir[i] > 0 ? "up" : "down", c.ls[i] * c.dir[i], (int)c.state[i], (int)c.why[i], c.blocked_t[i], c.nxt[i], c.side_t[i], c.side_goal[i]);
				for (int j = 0; j < c.hi; j++) {
					if (!c.alive[j] || j == i) continue;
					const float dx = c.x[j] - c.x[i], dz = c.z[j] - c.z[i];
					if (dx * dx + dz * dz > 1.5f * 1.5f) continue;
					std::printf("CROWD       near him: walker %d, %.2f m ahead, %.2f m to his left, on %s %d going %s, state %d why %d, speed %.2f, standing %.0f s, held %.1f s\n", c.id[j],
							dx * c.hx[i] + dz * c.hz[i], dx * c.hz[i] - dz * c.hx[i], c.segs[c.seg[j]].kind ? "crossing" : "pavement", c.seg[j], c.dir[j] > 0 ? "up" : "down", (int)c.state[j], (int)c.why[j], c.v[j], c.still_t[j], c.blocked_t[j]);
				}
			}
			break;
		}
	}
	s.most = std::max(s.most, c.n_alive);
	for (int i = 0; i < c.hi; i++) {
		if (!c.alive[i]) continue;
		s.rows++;
		if (c.state[i] == ST_WALK) { s.walking++; s.v_sum += c.v[i]; s.v_n++; }
		else if (c.state[i] == ST_WAIT) { s.waiting++; s.wait_most = std::max(s.wait_most, (double)c.wait_t[i]); }
		else if (c.state[i] == ST_CROSS) s.crossing++;
		else s.pausing++;
	}
}

int main(int argc, char **argv) {
	const uint64_t seed = argc > 1 ? (uint64_t)std::atoll(argv[1]) : 20261119ull;
	const char *path = "../map_dc/coronado/city_kit/traffic/streets.bin";
	std::FILE *f = std::fopen(path, "rb");
	if (!f) { std::printf("CROWD ERROR no streets file (%s): run tools/city/traffic/make_streets.gd\nRESULT FAIL\n", path); return 1; }
	std::vector<uint8_t> bytes;
	{ uint8_t buf[65536]; size_t n; while ((n = std::fread(buf, 1, sizeof(buf), f)) > 0) bytes.insert(bytes.end(), buf, buf + n); }
	std::fclose(f);
	sg::StreetData d;
	if (!d.load(bytes.data(), bytes.size())) { std::printf("CROWD ERROR %s is not a streets file\nRESULT FAIL\n", path); return 1; }
	Crowd *c = new Crowd();
	if (!c->build(d)) { std::printf("CROWD ERROR the streets file has no pavements\nRESULT FAIL\n"); return 1; }

	int n_walk = 0, n_cross = 0, n_lit = 0, n_dead = 0, n_bad = 0;
	float hw_min = 1e9f, hw_max = 0, cl_min = 1e9f, cl_max = 0, chw_min = 1e9f, chw_max = 0;
	for (const Seg &S : c->segs) {
		if (S.np < 2) { n_bad++; continue; }
		if (S.kind == 0) { n_walk++; hw_min = std::min(hw_min, S.hw); hw_max = std::max(hw_max, S.hw); }
		else { n_cross++; if (S.phase >= 0 && S.node >= 0) n_lit++; cl_min = std::min(cl_min, S.len); cl_max = std::max(cl_max, S.len); chw_min = std::min(chw_min, S.hw); chw_max = std::max(chw_max, S.hw); }
	}
	for (const auto &v : c->node_segs) if (v.size() == 1) n_dead++;
	std::printf("CROWD the map: %d pavements, %.1f km, half width %.2f to %.2f m; %d crossings (%d at signals), %.1f to %.1f m long, half width %.2f to %.2f m; %d pavement ends; %d pieces too short to use\n",
			n_walk, c->total_len / 1000.0, hw_min, hw_max, n_cross, n_lit, cl_min, cl_max, chw_min, chw_max, n_dead, n_bad);

	char line[512];
	// ---- A and B: the whole map, twice
	uint64_t hash[2] = { 0, 0 };
	for (int run = 0; run < 2; run++) {
		c->cfg = Config(); c->cfg.whole = true; c->cfg.max_peds = 500;
		c->reset(seed);
		c->cell_ok.clear(); c->cars.clear();
		Sum s;
		double clock = 0.0;
		const int ticks = 30 * 60 * 20;
		for (int t = 0; t < ticks; t++) {
			c->step(DT, clock); clock += DT;
			s.us_sum += c->st.step_us; s.us_worst = std::max(s.us_worst, c->st.step_us);
			if (t % 20 == 19) watch(*c, clock, s);
		}
		hash[run] = c->state_hash();
		if (run == 1) break;
		std::printf("CROWD A. %d people all over the map, 30 minutes (seed %llu):\n", s.most, (unsigned long long)seed);
		std::snprintf(line, sizeof(line), "nobody stands inside anybody (%lld pairs in %lld looks)", s.inside, s.checks); check(s.inside == 0, line);
		std::snprintf(line, sizeof(line), "nobody is beside his pavement (%lld)", s.beside); check(s.beside == 0, line);
		std::snprintf(line, sizeof(line), "nobody is on the road while the traffic he crosses has green (%lld)", s.on_green); check(s.on_green == 0, line);
		std::snprintf(line, sizeof(line), "nobody stands for a minute (most at once %d%s)", s.stuck_most, s.stuck_most ? "" : ""); check(s.stuck_most == 0, line);
		if (s.stuck_most) std::printf("CROWD     the first of them: walker %d at (%.1f, %.1f), on %s %d, why %d\n", s.worst_id, s.worst_x, s.worst_z, s.worst_kind ? "crossing" : "pavement", s.worst_seg, s.worst_why);
		std::printf("CROWD     of them at any moment: %.0f %% walking (%.2f m/s on average), %.1f %% waiting at a kerb (longest %.0f s), %.1f %% on a crossing, %.1f %% standing a while\n",
				100.0 * s.walking / s.rows, s.v_n > 0 ? s.v_sum / s.v_n : 0.0, 100.0 * s.waiting / s.rows, s.wait_most, 100.0 * s.crossing / s.rows, 100.0 * s.pausing / s.rows);
		std::printf("CROWD     in the 30 minutes: %d crossings walked, %d times somebody passed a slower one, %d moves refused (a body in the way), %d side steps, %d times somebody turned sideways to get past, %d turned round, %d stops for a while\n",
				c->st.crossings, c->st.passes, c->st.refused, c->st.sidesteps, c->st.sidled, c->st.turned, c->st.pauses);
		std::printf("CROWD     a step for %d people: %.3f ms on average, %.3f ms at worst\n", s.most, s.us_sum / ticks / 1000.0, s.us_worst / 1000.0);
		check(c->st.crossings > 200 && c->st.passes > 50, "they do cross and they do pass each other");
	}
	std::snprintf(line, sizeof(line), "B. the same seed gives the same crowd (%016llx and %016llx)", (unsigned long long)hash[0], (unsigned long long)hash[1]);
	check(hash[0] == hash[1], line);

	// ---- C: as in the game
	{
		c->cfg = Config(); c->cfg.max_peds = 150;
		c->reset(seed + 1);
		Sum s;
		double clock = 0.0;
		long long close_in_view = 0;
		int known = 0;
		const int ticks = 10 * 60 * 20;
		for (int t = 0; t < ticks; t++) {
			const float ang = (float)clock * 12.0f / 300.0f;   // 12 m/s round a circle of 300 m
			const float cx = -600.0f + 300.0f * std::cos(ang), cz = -1000.0f + 300.0f * std::sin(ang);
			const float fx = -std::sin(ang), fz = std::cos(ang);
			c->set_view(cx, cz, fx, fz);
			const int before = c->next_id;
			c->step(DT, clock); clock += DT;
			for (int i = 0; i < c->hi; i++) {   // who appeared in this step: how near, and in front?
				if (!c->alive[i] || c->id[i] < before) continue;
				const float dx = c->x[i] - cx, dz = c->z[i] - cz, dd = std::sqrt(dx * dx + dz * dz);
				if (dd < 40.0f || (dd < 80.0f && dx * fx + dz * fz > 0.5f * dd)) close_in_view++;
			}
			known = c->next_id;
			if (t % 20 == 19) watch(*c, clock, s);
		}
		(void)known;
		std::printf("CROWD C. as in the game (a camera driving at 43 km/h, at most 150 people round it, 10 minutes): %.0f people on average, most %d; %d appeared, %d left\n",
				s.rows / std::max(s.checks, 1LL), s.most, c->st.spawned, c->st.despawned);
		std::snprintf(line, sizeof(line), "inside each other %lld, beside the pavement %lld, on the road at green %lld, standing a minute %d", s.inside, s.beside, s.on_green, s.stuck_most);
		check(s.inside == 0 && s.beside == 0 && s.on_green == 0 && s.stuck_most == 0, line);
		std::snprintf(line, sizeof(line), "nobody appears within 40 m, or within 80 m in front of the camera (%lld)", close_in_view); check(close_in_view == 0, line);
		check(s.most > 20, "there are people round the camera");
	}

	// ---- D: cars over every crossing without signals
	{
		c->cfg = Config(); c->cfg.whole = true; c->cfg.max_peds = 500; c->cfg.bold_after = 1.0e9f;
		c->reset(seed + 2);
		std::vector<int> open;
		for (int k = 0; k < (int)c->segs.size(); k++) if (c->segs[k].np >= 2 && c->segs[k].kind == 1 && !(c->segs[k].phase >= 0 && c->segs[k].node >= 0)) open.push_back(k);
		Sum s;
		double clock = 0.0;
		long long under = 0, gap_waits = 0;
		std::vector<float> cars;
		const float sp = 12.0f, period = 30.0f;
		const int ticks = 10 * 60 * 20;
		for (int t = 0; t < ticks; t++) {
			cars.clear();
			for (int k : open) {   // one car line through the crossing's middle, square to it
				const Seg &S = c->segs[k];
				int h = 0; float mx, my, mz, tx, tz;
				c->at(S, S.len * 0.5f, 0.0f, h, mx, my, mz, tx, tz);
				const float vx = tz * sp, vz = -tx * sp;
				// (a car is there from 150 m before its crossing until it is over it: the cars of the next junction along the
				// street must not close this one's gaps)
				const float ahead = sp * (period - (float)std::fmod(clock + (double)(k % 7), (double)period));   // metres still to go to the crossing
				if (ahead > 150.0f && ahead < sp * period - 6.0f) continue;
				const float go = ahead > 150.0f ? ahead - sp * period : ahead;
				const float q[7] = { mx - vx / sp * go, mz - vz / sp * go, std::atan2(vx, vz), 2.2f, 0.95f, vx, vz };
				cars.insert(cars.end(), q, q + 7);
			}
			c->set_cars((int)cars.size() / 7, cars.data());
			c->step(DT, clock); clock += DT;
			for (int i = 0; i < c->hi; i++) {
				if (!c->alive[i]) continue;
				if (c->why[i] == WHY_GAP) gap_waits++;
				const Seg &S = c->segs[c->seg[i]];
				if (!c->on_road(i) || (S.phase >= 0 && S.node >= 0)) continue;
				// any car whose straight way runs over him within a second?
				for (size_t n = 0; n + 7 <= cars.size(); n += 7) {
					const float wx = cars[n + 5] / sp, wz = cars[n + 6] / sp;
					const float dx = c->x[i] - cars[n], dz = c->z[i] - cars[n + 1];
					// (one of these test cars may drive LENGTHWISE along somebody else's crossing, which no street's traffic does:
					// its line was laid square to its own crossing only. Such a car is not counted.)
					if (std::fabs(wx * c->hz[i] - wz * c->hx[i]) < 0.2f) continue;
					const float along = dx * wx + dz * wz, side = std::fabs(dx * wz - dz * wx);
					if (along > -2.2f && along < sp * 1.0f + 2.2f && side < 0.95f + RAD) {
						if (under == 0) std::printf("CROWD     the first in front of a car: walker %d at %.2f s, %.1f of %.1f m along crossing %d (kerbs at %.2f and %.2f from its ends), going %s, speed %.2f, state %d why %d, held %.1f s; the car is %.1f m away, its way %.2f m beside him, car %d of %d\n",
								c->id[i], clock, c->u[i], S.len, c->seg[i], S.ka, S.kb, c->dir[i] > 0 ? "up" : "down", c->v[i], (int)c->state[i], (int)c->why[i], c->blocked_t[i], along, side, (int)(n / 7), (int)(cars.size() / 7));
						under++; break;
					}
				}
			}
			if (t % 20 == 19) watch(*c, clock, s);
		}
		std::printf("CROWD D. a car every 30 s over each of the %d crossings without signals, 10 minutes: %d crossings walked in all, %.0f walker-seconds spent waiting for a gap\n", (int)open.size(), c->st.crossings, gap_waits * DT);
		std::snprintf(line, sizeof(line), "nobody is on the road with a car less than a second away (%lld walker-steps)", under); check(under == 0, line);
		std::snprintf(line, sizeof(line), "inside each other %lld, standing a minute %d", s.inside, s.stuck_most); check(s.inside == 0 && s.stuck_most == 0, line);
		if (!open.empty()) check(gap_waits > 0, "people do wait for gaps");
	}
	std::printf("RESULT %s\n", fails == 0 ? "PASS" : "FAIL");
	delete c;
	return fails == 0 ? 0 : 1;
}
