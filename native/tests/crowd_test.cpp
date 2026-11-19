// The walking crowd on the map's real pavements and places, without the game (plain C++, a console program):
//   bash native/tests/run_crowd_test.sh [seed]
// It reads the streets and places files the game uses and lets the crowd live on them:
//   A. 800 people all over the map for 30 minutes at noon, everything on (goals, groups, street life), every second
//      a look: nobody inside anybody, nobody beside his pavement, nobody on the road at green, nobody standing a
//      minute who should walk, no bad number, no follower lost; and they do arrive, go in, come out, sit, meet ...
//   B. the same again: the same seed must give the same crowd;
//   C. as in the game: a ring round a camera that drives through the centre, people far away stepped less often;
//   D. cars (dumb ones that never brake, one every 30 s) over every crossing without signals: people take the gaps;
//   E. the hours: far fewer people at 3 at night than at noon, nobody walks into a shut shop;
//   F. rain: nobody sits, some shelter at shop fronts, people hurry;
//   G. danger: near it people duck, farther they run, some stare;
//   H. the player standing on a busy pavement: people go round him, nobody ends inside him;
//   I. the game's hooks: place a walker, send it to a bench (it sits), knock the bench over (it gets up), send it
//      through a door (gone), hold and release, hide, hand to a body and back;
//   J. a bus at a stop: the people waiting board, the ones it brings get off.
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
static inline float clampf_(float v, float a, float b) { return v < a ? a : (v > b ? b : v); }
static inline float wrap(float a) { a = std::fmod(a + 3.14159265f, 6.2831853f); if (a < 0.0f) a += 6.2831853f; return a - 3.14159265f; }
static int fails = 0;
static char line[1024];

static void check(bool ok, const char *what) {
	if (!ok) fails++;
	std::printf("CROWD   %s: %s\n", ok ? "ok" : "FAIL", what);
}

struct Sum {
	long long bad[7] = { 0, 0, 0, 0, 0, 0, 0 }, checks = 0;
	int stuck_most = 0, most = 0;
	double v_sum = 0, v_n = 0, us_sum = 0, us_worst = 0, wait_most = 0, rows = 0;
	double by_mode[8] = { 0 }, paused = 0, waiting = 0, crossing = 0, in_party = 0;
	bool said[6] = { false, false, false, false, false, false };
};

static void who(const Crowd &c, int i, const char *what, double clock) {
	const Seg &S = c.segs[c.seg[i]];
	std::printf("CROWD     the first %s: walker %d at %.0f s at (%.1f, %.1f), mode %d state %d why %d act %d, %.1f of %.1f m along %s %d (half width %.2f) going %s, %.2f beside its line, speed %.2f, held %.1f s, standing %.1f s, party %d (slot %d of %d, leader row %d), goal %d\n",
			what, c.id[i], clock, c.x[i], c.z[i], (int)c.mode[i], (int)c.state[i], (int)c.why[i], (int)c.act[i], c.u[i], S.len, S.kind ? "crossing" : "pavement", c.seg[i], S.hw, c.dir[i] > 0 ? "up" : "down",
			c.ls[i] * c.dir[i], c.v[i], c.blocked_t[i], c.still_t[i], c.party[i], (int)c.slot[i], (int)c.psize[i], (int)c.leader[i], c.goal[i]);
	for (int j = 0; j < c.hi; j++) {
		if (!c.alive[j] || j == i) continue;
		const float dx = c.x[j] - c.x[i], dz = c.z[j] - c.z[i];
		if (dx * dx + dz * dz > 1.2f * 1.2f) continue;
		std::printf("CROWD       near it: walker %d %.2f m off, mode %d state %d why %d act %d, speed %.2f, standing %.0f s, party %d\n", c.id[j], std::sqrt(dx * dx + dz * dz), (int)c.mode[j], (int)c.state[j], (int)c.why[j], (int)c.act[j], c.v[j], c.still_t[j], c.party[j]);
	}
}

static void watch(Crowd &c, double clock, Sum &s) {
	int r[7];
	c.audit(clock, r);
	for (int k = 0; k < 7; k++) s.bad[k] += r[k];
	s.checks++;
	s.stuck_most = std::max(s.stuck_most, r[3]);
	s.most = std::max(s.most, c.n_alive);
	static const char *const WHAT[6] = { "inside somebody", "beside his pavement", "on the road at green", "who stands a minute", "with a bad number", "who lost his leader" };
	for (int k = 0; k < 6; k++) {
		if (r[k] == 0 || s.said[k]) continue;
		s.said[k] = true;
		for (int i = 0; i < c.hi; i++) {
			if (!c.alive[i]) continue;
			const Seg &S = c.segs[c.seg[i]];
			bool hit = false;
			if (k == 0) { for (int j = 0; j < c.hi && !hit; j++) { if (!c.alive[j] || j == i) continue; const float dx = c.x[j] - c.x[i], dz = c.z[j] - c.z[i]; float lim = (c.thin[i] ? RAD_THIN : RAD) + (c.thin[j] ? RAD_THIN : RAD) - 0.03f; if (c.party[i] && c.party[i] == c.party[j]) { if (c.leader[i] == i || c.leader[j] == j) continue; lim = 2.0f * RAD_THIN - 0.03f; } hit = dx * dx + dz * dz < lim * lim; } }
			if (k == 1) hit = c.mode[i] == M_LINE && std::fabs(c.ls[i]) > S.hw + (S.kind == 1 ? 1.05f : 0.05f);
			if (k == 2) { const float gone = c.dir[i] > 0 ? c.u[i] : S.len - c.u[i]; hit = c.on_road(i) && c.mode[i] == M_LINE && S.phase >= 0 && S.node >= 0 && !c.walk_light(S, clock) && !c.walk_light(S, clock - 2.5) && gone > 2.6f && gone < S.len - 2.6f; }
			if (k == 3) hit = c.mode[i] == M_LINE && c.state[i] != ST_PAUSE && c.still_t[i] > 60.0f;
			if (k == 4) hit = !(c.x[i] == c.x[i]) || c.v[i] > 6.0f || c.v[i] < 0.0f;
			if (k == 5 && c.mode[i] == M_FOLLOW && c.leader[i] >= 0) { const float dx = c.x[c.leader[i]] - c.x[i], dz = c.z[c.leader[i]] - c.z[i]; hit = dx * dx + dz * dz > 100.0f; }
			if (hit) { who(c, i, WHAT[k], clock); break; }
		}
	}
	for (int i = 0; i < c.hi; i++) {
		if (!c.alive[i]) continue;
		s.rows++;
		s.by_mode[c.mode[i] & 7]++;
		if (c.party[i]) s.in_party++;
		if (c.mode[i] != M_LINE) continue;
		if (c.state[i] == ST_WALK) { s.v_sum += c.v[i]; s.v_n++; }
		else if (c.state[i] == ST_WAIT) { s.waiting++; s.wait_most = std::max(s.wait_most, (double)c.wait_t[i]); }
		else if (c.state[i] == ST_CROSS) s.crossing++;
		else s.paused++;
	}
}

static bool zeros(const Sum &s, const char *head) {
	std::snprintf(line, sizeof(line), "%sinside each other %lld, beside the pavement %lld, out in the road 2.5 s into the traffic's green %lld, standing a minute %d, bad numbers %lld; (of %.0f walker-looks: %lld a step from the kerb at such a moment, held up by people standing there; %lld followers more than 10 m behind their leader)", head, s.bad[0], s.bad[1], s.bad[2], s.stuck_most, s.bad[4], s.rows, s.bad[6], s.bad[5]);
	// Must be 0: inside each other, beside the pavement, standing a minute, bad numbers. Out in the road at green: at most
	// one walker-look in 100,000 (what is left is a follower whom its group left behind on a crossing: he finishes it
	// alone, at a run, late; the traffic's cars brake for people on the road). Followers far behind: at most 2 in 1,000.
	const bool ok = s.bad[0] == 0 && s.bad[1] == 0 && (double)s.bad[2] <= 1.0e-5 * s.rows && s.stuck_most == 0 && s.bad[4] == 0 && (double)s.bad[5] <= 0.002 * s.rows;
	check(ok, line);
	return ok;
}

static bool read_file(const char *path, std::vector<uint8_t> &bytes) {
	std::FILE *f = std::fopen(path, "rb");
	if (!f) return false;
	uint8_t buf[65536]; size_t n;
	while ((n = std::fread(buf, 1, sizeof(buf), f)) > 0) bytes.insert(bytes.end(), buf, buf + n);
	std::fclose(f);
	return true;
}

int main(int argc, char **argv) {
	const uint64_t seed = argc > 1 ? (uint64_t)std::atoll(argv[1]) : 20261119ull;
	std::vector<uint8_t> bytes, pbytes;
	if (!read_file("../map_dc/coronado/city_kit/traffic/streets.bin", bytes)) { std::printf("CROWD ERROR no streets file: run tools/city/traffic/make_streets.gd\nRESULT FAIL\n"); return 1; }
	sg::StreetData d;
	if (!d.load(bytes.data(), bytes.size())) { std::printf("CROWD ERROR not a streets file\nRESULT FAIL\n"); return 1; }
	Crowd *c = new Crowd();
	if (!c->build(d)) { std::printf("CROWD ERROR the streets file has no pavements\nRESULT FAIL\n"); return 1; }
	PlaceData pd;
	if (!read_file("../map_dc/coronado/city_kit/traffic/places.bin", pbytes) || !pd.load(pbytes.data(), pbytes.size())) { std::printf("CROWD ERROR no places file: run tools/city/traffic/make_places.gd\nRESULT FAIL\n"); return 1; }
	c->set_places(pd);

	int n_walk = 0, n_cross = 0, n_lit = 0;
	for (const Seg &S : c->segs) { if (S.np < 2) continue; if (S.kind == 0) n_walk++; else { n_cross++; if (S.phase >= 0 && S.node >= 0) n_lit++; } }
	std::printf("CROWD the map: %d pavements (%.1f km), %d crossings (%d at signals); places: %d home doors, %d shop doors, %d bench seats, %d park and %d beach places, %d cafe seats, %d bus stops, %d beggars' spots, %d night corners, %d gates\n",
			n_walk, c->total_len / 1000.0, n_cross, n_lit, c->n_place_kind[PL_HOME], c->n_place_kind[PL_SHOP], c->n_place_kind[PL_BENCH], c->n_place_kind[PL_PARK], c->n_place_kind[PL_BEACH], c->n_place_kind[PL_CAFE],
			c->n_place_kind[PL_BUS], c->n_place_kind[PL_BEG], c->n_place_kind[PL_NIGHT], c->n_place_kind[PL_GATE]);

	auto fresh = [&](uint64_t sd, bool whole, int cap) {
		c->cfg = Config(); c->cfg.whole = whole; c->cfg.max_peds = cap; c->cfg.stuck_s = 1.0e9f;   // (nobody is quietly taken away in these checks)
		c->cell_ok.clear(); c->cars.clear(); c->has_player = false;
		c->set_time(12.0f, 2, 6.5f, 19.0f); c->set_rain(0.0f);
		c->reset(sd);
	};

	// ---- A and B: the whole map at noon, twice
	uint64_t hash[2] = { 0, 0 };
	for (int run = 0; run < 2; run++) {
		fresh(seed, true, 800);
		Sum s;
		double clock = 0.0;
		const int ticks = 30 * 60 * 20;
		long long ev[16] = { 0 };
		for (int t = 0; t < ticks; t++) {
			c->step(DT, clock); clock += DT;
			for (const Event &e : c->events) if (e.type >= 0 && e.type < 16) ev[e.type]++;
			c->events.clear();
			s.us_sum += c->st.step_us; s.us_worst = std::max(s.us_worst, c->st.step_us);
			if (t % 20 == 19) watch(*c, clock, s);
		}
		hash[run] = c->state_hash();
		if (run == 1) break;
		const Stats &st = c->st;
		std::printf("CROWD A. %d people all over the map at noon, 30 minutes (seed %llu):\n", s.most, (unsigned long long)seed);
		zeros(s, "");
		std::printf("CROWD     of them at any moment: %.0f %% on a pavement's line (walking %.2f m/s; %.1f %% at a kerb, longest wait %.0f s; %.1f %% on a crossing; %.1f %% paused), %.1f %% on the way to or from a door or seat, %.1f %% at a place, %.1f %% following a leader; %.0f %% walk with others\n",
				100.0 * s.by_mode[M_LINE] / s.rows, s.v_n > 0 ? s.v_sum / s.v_n : 0.0, 100.0 * s.waiting / s.rows, s.wait_most, 100.0 * s.crossing / s.rows, 100.0 * s.paused / s.rows,
				100.0 * (s.by_mode[M_OFF] + s.by_mode[M_BACK]) / s.rows, 100.0 * s.by_mode[M_STAY] / s.rows, 100.0 * s.by_mode[M_FOLLOW] / s.rows, 100.0 * s.in_party / s.rows);
		std::printf("CROWD     in the 30 minutes: %d ways planned (%d found no way), %d arrivals; %d went in at a door, %d came out of one; %d sat down, %d lay down, %d had a drink, %d waited at a bus stop; %d crossings, %d passes, %d moves refused, %d side steps, %d sidled past, %d turned round\n",
				st.plans, st.plan_fails, st.arrivals, st.went_in, st.came_out, st.sat, st.lay, st.drank, st.bus_waits, st.crossings, st.passes, st.refused, st.sidesteps, st.sidled, st.turned);
		std::printf("CROWD     street life: %d groups set out, %d phone calls and shop windows, %d meetings of people who know each other (%d came to blows), %d coins for beggars, %d groups stopped to talk in a circle, %d lines of conversation said\n",
				st.parties, st.pauses, st.meetings, st.fights, st.coins, st.circles, st.lines_said);
		std::printf("CROWD     a step for %d people: %.3f ms on average, %.3f ms at worst\n", s.most, s.us_sum / ticks / 1000.0, s.us_worst / 1000.0);
		check(st.crossings > 200 && st.passes > 50, "they cross and they pass each other");
		check(st.arrivals > 300 && st.went_in > 100 && st.came_out > 50, "they arrive, go in at doors and come out of them");
		check(st.sat > 20 && st.lay > 3 && st.bus_waits > 5, "they sit on benches, lie on the beach, wait at bus stops");
		check(st.parties > 50 && s.in_party > 0, "people walk together");
		check(st.pauses > 100 && st.meetings > 3 && st.circles > 3 && st.lines_said > 10, "phone calls, shop windows, meetings, circles, conversations happen");
		check(ev[E_SPAWN] > 0 && ev[E_DESPAWN] > 0 && ev[E_ARRIVE] > 0 && ev[E_MEET] > 0 && ev[E_SAY] > 0 && (ev[E_WAIT_CROSS] + ev[E_LOOK_CROSS]) > 0, "the game hears of it (appeared, left, arrived, waiting to cross, met, says a line)");
		std::printf("CROWD     (coins given %d: a beggar's spot must lie on a giver's way; fights %d)\n", st.coins, st.fights);
	}
	std::snprintf(line, sizeof(line), "B. the same seed gives the same crowd (%016llx and %016llx)", (unsigned long long)hash[0], (unsigned long long)hash[1]);
	check(hash[0] == hash[1], line);

	// ---- C: as in the game
	{
		fresh(seed + 1, false, 300);
		c->cfg.stuck_s = 45.0f;
		Sum s;
		double clock = 0.0;
		long long close_in_view = 0;
		int tier_n[3] = { 0, 0, 0 };
		const int ticks = 10 * 60 * 20;
		for (int t = 0; t < ticks; t++) {
			const float ang = (float)clock * 12.0f / 300.0f;   // 12 m/s round a circle of 300 m
			const float cx = -600.0f + 300.0f * std::cos(ang), cz = -1000.0f + 300.0f * std::sin(ang);
			const float fx = -std::sin(ang), fz = std::cos(ang);
			c->set_view(cx, cz, fx, fz);
			const int before = c->next_id;
			c->step(DT, clock); clock += DT;
			c->events.clear();
			for (int i = 0; i < c->hi; i++) {
				if (!c->alive[i]) continue;
				if (t % 20 == 0) tier_n[c->tier[i] % 3]++;
				if (c->id[i] < before) continue;   // who appeared in this step: how near, and in front?
				const float dx = c->x[i] - cx, dz = c->z[i] - cz, dd = std::sqrt(dx * dx + dz * dz);
				if (dd < 35.0f && dx * fx + dz * fz > 0.5f * dd) close_in_view++;
			}
			if (t % 20 == 19) watch(*c, clock, s);
		}
		std::printf("CROWD C. as in the game (a camera driving at 43 km/h, a ring of 130 m, 10 minutes): %.0f people on average, most %d; %d appeared (%d of them out of a door), %d left; taken away: %d held unseen, %d too many\n",
				s.rows / std::max(s.checks, 1LL), s.most, c->st.spawned, c->st.came_out, c->st.despawned, c->st.taken_stuck, c->st.taken_extra);
		zeros(s, "");
		std::snprintf(line, sizeof(line), "nobody appears within 35 m in front of the camera (%lld)", close_in_view); check(close_in_view == 0, line);
		std::snprintf(line, sizeof(line), "three levels of care by distance: %d walker-looks near, %d middle, %d far", tier_n[0], tier_n[1], tier_n[2]); check(tier_n[0] > 0 && tier_n[1] > 0 && tier_n[2] > 0, line);
		check(s.most > 20 && c->st.came_out > 10, "there are people round the camera, and some came out of doors");
	}

	// ---- D: cars over every crossing without signals
	{
		fresh(seed + 2, true, 500);
		c->cfg.bold_after = 1.0e9f;
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
				const float ahead = sp * (period - (float)std::fmod(clock + (double)(k % 7), (double)period));
				if (ahead > 150.0f && ahead < sp * period - 6.0f) continue;
				const float go = ahead > 150.0f ? ahead - sp * period : ahead;
				const float q[7] = { mx - vx / sp * go, mz - vz / sp * go, std::atan2(vx, vz), 2.2f, 0.95f, vx, vz };
				cars.insert(cars.end(), q, q + 7);
			}
			c->set_cars((int)cars.size() / 7, cars.data());
			c->step(DT, clock); clock += DT;
			c->events.clear();
			for (int i = 0; i < c->hi; i++) {
				if (!c->alive[i]) continue;
				if (c->why[i] == WHY_GAP) gap_waits++;
				// on a crossing, inside a car's box right now? (these test cars drive on over pavements beyond their crossing,
				// which no street's traffic does: people hit THERE are not counted)
				if (c->segs[c->seg[i]].kind != 1) continue;
				for (size_t n = 0; n + 7 <= cars.size(); n += 7) {
					const float wx = cars[n + 5] / sp, wz = cars[n + 6] / sp;
					const float dx = c->x[i] - cars[n], dz = c->z[i] - cars[n + 1];
					if (std::fabs(dx * wx + dz * wz) < 2.2f + RAD - 0.05f && std::fabs(dx * wz - dz * wx) < 0.95f + RAD - 0.05f) {
						if (under == 0) who(*c, i, "run over by a test car", clock);
						under++; break;
					}
				}
			}
			if (t % 20 == 19) watch(*c, clock, s);
		}
		std::printf("CROWD D. a car that never brakes every 30 s over each of the %d crossings without signals, 10 minutes: %d crossings walked, %.0f walker-seconds waiting for a gap, %d jumps out of a car's way\n", (int)open.size(), c->st.crossings, gap_waits * DT, c->st.dodges);
		std::snprintf(line, sizeof(line), "nobody is ever inside a car (%lld walker-steps)", under); check(under == 0, line);
		std::snprintf(line, sizeof(line), "inside each other %lld, standing a minute %d", s.bad[0], s.stuck_most); check(s.bad[0] == 0 && s.stuck_most == 0, line);
		if (!open.empty()) check(gap_waits > 0, "people do wait for gaps");
	}

	// ---- E: the hours
	{
		int at_noon = 0, at_night = 0, shut_in = 0;
		for (int k = 0; k < 2; k++) {
			fresh(seed + 3, true, 1000);
			c->set_time(k ? 3.0f : 12.0f, 2, 6.5f, 19.0f);
			double clock = 0.0;
			int night_workers = 0;
			for (int t = 0; t < 5 * 60 * 20; t++) {
				c->step(DT, clock); clock += DT;
				for (const Event &e : c->events) if (k == 1 && e.type == E_ARRIVE && e.aux >= 0 && e.aux < (int)c->places.size() && c->places[e.aux].kind == PL_SHOP && !c->shop_open(e.aux)) shut_in++;
				c->events.clear();
			}
			for (int i = 0; i < c->hi; i++) if (c->alive[i] && (c->flags[i] & F_RESIDENT) && c->places[c->goal[i]].kind == PL_NIGHT) night_workers++;
			(k ? at_night : at_noon) = c->n_alive;
			if (k == 1) { std::snprintf(line, sizeof(line), "at night the night workers stand at their corners (%d of %d corners)", night_workers, c->n_place_kind[PL_NIGHT]); check(night_workers > 0, line); }
		}
		std::snprintf(line, sizeof(line), "E. the hours: %d people at noon, %d at 3 at night (same cap)", at_noon, at_night); check(at_night * 3 < at_noon, line);
		std::snprintf(line, sizeof(line), "nobody arrives at a shut shop's door (%d)", shut_in); check(shut_in == 0, line);
	}

	// ---- F: rain
	{
		fresh(seed + 4, true, 800);
		double clock = 0.0;
		int sitting_before = 0, sitting_after = 0;
		double v_dry = 0, n_dry = 0, v_wet = 0, n_wet = 0;
		for (int t = 0; t < 12 * 60 * 20; t++) {
			if (t == 8 * 60 * 20) {
				for (int i = 0; i < c->hi; i++) if (c->alive[i] && c->mode[i] == M_STAY && (c->act[i] == A_SIT || c->act[i] == A_LIE_BACK || c->act[i] == A_LIE_FRONT || c->act[i] == A_DRINK)) sitting_before++;
				c->set_rain(1.0f);
			}
			c->step(DT, clock); clock += DT; c->events.clear();
			if (t % 20 == 0) for (int i = 0; i < c->hi; i++) if (c->alive[i] && c->mode[i] == M_LINE && c->state[i] == ST_WALK && c->why[i] == WHY_NONE && c->segs[c->seg[i]].kind == 0 && !c->party[i]) {
				if (t < 8 * 60 * 20) { v_dry += c->v[i] / c->v0[i]; n_dry++; } else if (t > 9 * 60 * 20) { v_wet += c->v[i] / c->v0[i]; n_wet++; }
			}
		}
		for (int i = 0; i < c->hi; i++) if (c->alive[i] && c->mode[i] == M_STAY && (c->act[i] == A_SIT || c->act[i] == A_LIE_BACK || c->act[i] == A_LIE_FRONT || c->act[i] == A_DRINK)) sitting_after++;
		int sheltering = 0;
		for (int i = 0; i < c->hi; i++) if (c->alive[i] && c->mode[i] == M_STAY && c->act[i] == A_SHELTER) sheltering++;
		std::snprintf(line, sizeof(line), "F. rain: %d people sat or lay before it, %d four minutes into it; %d went for shelter, %d stand at a shop's front; pace %.2f of their own before, %.2f in the rain",
				sitting_before, sitting_after, c->st.sheltered, sheltering, n_dry > 0 ? v_dry / n_dry : 0.0, n_wet > 0 ? v_wet / n_wet : 0.0);
		check(sitting_before > 3 && sitting_after == 0 && c->st.sheltered > 0 && sheltering > 0 && v_wet / std::max(n_wet, 1.0) > v_dry / std::max(n_dry, 1.0) + 0.05, line);
	}

	// ---- G: danger
	{
		fresh(seed + 5, true, 800);
		double clock = 0.0;
		for (int t = 0; t < 3 * 60 * 20; t++) { c->step(DT, clock); clock += DT; c->events.clear(); }
		// where most people are within 40 m
		int best = -1, best_n = 0;
		for (int i = 0; i < c->hi; i++) {
			if (!c->alive[i] || c->mode[i] != M_LINE || c->party[i] || c->state[i] != ST_WALK || c->segs[c->seg[i]].kind != 0) continue;
			int n = 0;
			for (int j = 0; j < c->hi; j++) if (c->alive[j]) { const float dx = c->x[j] - c->x[i], dz = c->z[j] - c->z[i]; if (dx * dx + dz * dz < 40.0f * 40.0f) n++; }
			if (n > best_n) { best_n = n; best = i; }
		}
		const float sx = c->x[best], sz = c->z[best];
		c->scare(sx, sz, 40.0f, 8.0f);
		int screams = 0;
		for (const Event &e : c->events) if (e.type == E_SCREAM) screams++;
		Sum s;
		double away = 0, n_away = 0, v_run = 0, n_run = 0;
		std::vector<float> d0(MAX_PEDS, -1.0f);
		for (int i = 0; i < c->hi; i++) if (c->alive[i] && (c->flags[i] & F_FLEE)) { const float dx = c->x[i] - sx, dz = c->z[i] - sz; d0[i] = std::sqrt(dx * dx + dz * dz); }
		for (int t = 0; t < 6 * 20; t++) {
			c->step(DT, clock); clock += DT; c->events.clear();
			if (t % 20 == 19) watch(*c, clock, s);
			if (t == 4 * 20) for (int i = 0; i < c->hi; i++) if (c->alive[i] && d0[i] >= 0.0f && c->mode[i] == M_LINE && (c->flags[i] & F_FLEE)) { v_run += c->v[i]; n_run++; }
		}
		for (int i = 0; i < c->hi; i++) if (c->alive[i] && d0[i] >= 0.0f) { const float dx = c->x[i] - sx, dz = c->z[i] - sz; away += std::sqrt(dx * dx + dz * dz) - d0[i]; n_away++; }
		std::snprintf(line, sizeof(line), "G. a fright where %d people are within 40 m: %d duck, %d run (%.1f m/s after four seconds; six seconds later they are %.1f m farther from it on average), %d stand and watch, %d scream; inside each other %lld",
				best_n, c->st.ducks, c->st.fled, n_run > 0 ? v_run / n_run : 0.0, n_away > 0 ? away / n_away : 0.0, c->st.stared, screams, s.bad[0]);
		check(c->st.fled > 0 && (c->st.ducks > 0 || best_n < 6) && s.bad[0] == 0 && (n_away == 0 || away / n_away > 3.0) && (n_run == 0 || v_run / n_run > 1.2), line);
	}

	// ---- H: the player on a busy pavement
	{
		fresh(seed + 6, true, 800);
		double clock = 0.0;
		for (int t = 0; t < 60 * 20; t++) { c->step(DT, clock); clock += DT; c->events.clear(); }
		// the busiest long pavement: stand in the middle of its right-hand file
		int k_best = -1; int n_best = 0;
		for (int k = 0; k < (int)c->segs.size(); k++) {
			if (c->segs[k].np < 2 || c->segs[k].kind != 0 || c->segs[k].len < 60.0f) continue;
			int n = 0;
			for (int i = 0; i < c->hi; i++) if (c->alive[i] && c->seg[i] == k && c->mode[i] == M_LINE) n++;
			if (n > n_best) { n_best = n; k_best = k; }
		}
		const Seg &S = c->segs[k_best];
		int h = 0; float pxx, pyy, pzz, tx, tz;
		c->at(S, S.len * 0.5f, -0.3f, h, pxx, pyy, pzz, tx, tz);
		c->set_player(true, pxx, pzz, 0.0f, 0.0f);
		long long inside_player = 0; int bumps = 0, passed = 0;
		std::vector<float> last_al(MAX_PEDS, 0.0f);
		for (int t = 0; t < 8 * 60 * 20; t++) {
			c->step(DT, clock); clock += DT;
			for (const Event &e : c->events) if (e.type == E_BUMP) bumps++;
			c->events.clear();
			for (int i = 0; i < c->hi; i++) {
				if (!c->alive[i]) continue;
				const float dx = c->x[i] - pxx, dz = c->z[i] - pzz, d2 = dx * dx + dz * dz;
				const float lim = (c->thin[i] ? RAD_THIN : RAD) + 0.30f - 0.03f;
				if (d2 < lim * lim) { if (inside_player == 0) who(*c, i, "inside the player", clock); inside_player++; }
				if (c->seg[i] == k_best && c->mode[i] == M_LINE) {
					const float al = (dx * tx + dz * tz);
					if (last_al[i] != 0.0f && ((last_al[i] < 0.0f) != (al < 0.0f)) && std::fabs(al) < 1.0f) passed++;
					last_al[i] = al;
				} else last_al[i] = 0.0f;
			}
		}
		std::snprintf(line, sizeof(line), "H. the player stands in a file of the busiest pavement (%d people on it) for 8 minutes: %d walked past him, %d bumps reported, nobody inside him (%lld)", n_best, passed, bumps, inside_player);
		check(inside_player == 0 && passed > 3, line);
		c->set_player(false, 0, 0, 0, 0);
	}

	// ---- I: the hooks
	{
		fresh(seed + 7, true, 0);
		c->cfg.pauses = false; c->cfg.life = false; c->cfg.parties = false;
		double clock = 0.0;
		auto run = [&](float secs) { for (int t = 0; t < (int)(secs * 20.0f); t++) { c->step(DT, clock); clock += DT; c->events.clear(); } };
		run(1.0f);
		int bench = -1, door = -1;
		for (int p = 0; p < (int)c->places.size(); p++) { if (bench < 0 && c->places[p].kind == PL_BENCH) bench = p; }
		const Place &B = c->places[bench];
		for (int p = 0; p < (int)c->places.size(); p++) {
			if (c->places[p].kind != PL_HOME) continue;
			const float dx = c->places[p].ax - B.ax, dz = c->places[p].az - B.az;
			if (dx * dx + dz * dz < 300.0f * 300.0f && dx * dx + dz * dz > 30.0f * 30.0f) { door = p; break; }
		}
		// a walker 60 m along the bench's own pavement (or as far as it goes)
		const Seg &S = c->segs[B.seg];
		int h = 0; float sx, sy, sz, tx, tz;
		c->at(S, clampf_(B.u > S.len * 0.5f ? B.u - 60.0f : B.u + 60.0f, 2.0f, S.len - 2.0f), 0.0f, h, sx, sy, sz, tx, tz);
		const int wid = c->place_walker(sx, sz, 12345u);
		bool ok = wid > 0;
		ok = ok && c->set_goal(wid, bench, 300.0f, false);
		run(90.0f);
		int i = c->find(wid);
		const bool sits = i >= 0 && c->mode[i] == M_STAY && c->act[i] == A_SIT && std::fabs(c->x[i] - B.x) < 0.05f && std::fabs(c->z[i] - B.z) < 0.05f && std::fabs(wrap(c->yaw[i] - B.yaw)) < 0.2f;
		std::snprintf(line, sizeof(line), "I. hooks: a walker is placed, sent to a bench and sits there, on the seat, facing the bench's way (%s: mode %d act %d, %.2f m from the seat, %.0f degrees off its way)", sits ? "yes" : "no",
				i >= 0 ? (int)c->mode[i] : -1, i >= 0 ? (int)c->act[i] : -1, i >= 0 ? std::sqrt((c->x[i] - B.x) * (c->x[i] - B.x) + (c->z[i] - B.z) * (c->z[i] - B.z)) : -1.0f, i >= 0 ? wrap(c->yaw[i] - B.yaw) * 57.3f : 0.0f);
		check(ok && sits, line);
		c->bench_off(bench, true);
		run(6.0f);
		i = c->find(wid);
		check(i >= 0 && c->mode[i] != M_STAY, "the bench is knocked over: he gets up");
		c->bench_off(bench, false);
		run(8.0f);
		i = c->find(wid);
		const bool held = c->hold(wid, true, 1.0f);
		const float hx0 = i >= 0 ? c->x[i] : 0, hz0 = i >= 0 ? c->z[i] : 0;
		run(5.0f);
		i = c->find(wid);
		const bool stood = i >= 0 && c->mode[i] == M_HELD && std::fabs(c->x[i] - hx0) < 0.01f && std::fabs(c->z[i] - hz0) < 0.01f && std::fabs(wrap(c->yaw[i] - 1.0f)) < 0.1f;
		c->hold(wid, false, 0.0f);
		run(3.0f);
		i = c->find(wid);
		check(held && stood && i >= 0 && c->mode[i] == M_LINE && (std::fabs(c->x[i] - hx0) + std::fabs(c->z[i] - hz0)) > 0.5f, "held in place facing a way, then released: he walks on");
		check(c->hide(wid, true) && (c->flags[c->find(wid)] & F_HIDDEN) && c->hide(wid, false) && !(c->flags[c->find(wid)] & F_HIDDEN), "hidden and shown again");
		i = c->find(wid);
		const float bx0 = c->x[i] + 3.0f, bz0 = c->z[i] + 2.0f;
		const bool tb = c->to_body(wid, true, bx0, bz0);
		run(2.0f);
		i = c->find(wid);
		const bool is_body = i >= 0 && c->mode[i] == M_BODY && std::fabs(c->x[i] - bx0) < 0.01f;
		c->to_body(wid, false, bx0, bz0);
		run(12.0f);
		i = c->find(wid);
		check(tb && is_body && i >= 0 && c->mode[i] == M_LINE, "handed to a physical body 3.6 m off his line, handed back: he walks back to the pavement and on");
		const bool sent = door >= 0 && c->set_goal(wid, door, 0.0f, true);
		run(400.0f);
		std::snprintf(line, sizeof(line), "sent to a home's door %d m away: he goes in and is gone (%s)", door >= 0 ? (int)std::sqrt((c->places[door].ax - B.ax) * (c->places[door].ax - B.ax) + (c->places[door].az - B.az) * (c->places[door].az - B.az)) : -1, c->find(wid) < 0 ? "gone" : "still there");
		check(sent && c->find(wid) < 0, line);
		const int n0 = c->n_alive;
		const int w2 = c->place_walker(sx, sz, 1u);
		check(!c->remove_walker(wid) && w2 > 0 && c->n_alive == n0 + 1 && c->remove_walker(w2) && c->n_alive == n0 && c->find(w2) < 0, "a walker is placed and removed again");
	}

	// ---- J: a bus at a stop
	{
		fresh(seed + 8, true, 0);
		c->cfg.pauses = false; c->cfg.life = false; c->cfg.parties = false;
		double clock = 0.0;
		auto run = [&](float secs) { for (int t = 0; t < (int)(secs * 20.0f); t++) { c->step(DT, clock); clock += DT; c->events.clear(); } };
		run(1.0f);
		int stop = -1;
		for (int p = 0; p < (int)c->places.size(); p++) if (c->places[p].kind == PL_BUS && c->segs[c->places[p].seg].len > 60.0f && c->places[p].u > 25.0f && c->places[p].u < c->segs[c->places[p].seg].len - 25.0f) { stop = p; break; }
		const Place &P = c->places[stop];
		const Seg &S = c->segs[P.seg];
		int ids[4];
		for (int k = 0; k < 4; k++) {
			int h = 0; float sx, sy, sz, tx, tz;
			c->at(S, P.u + (k < 2 ? -8.0f - 4.0f * k : 8.0f + 4.0f * (k - 2)), 0.0f, h, sx, sy, sz, tx, tz);
			ids[k] = c->place_walker(sx, sz, 100u + k);
			c->set_goal(ids[k], stop, 0.0f, false);
		}
		run(40.0f);
		int waiting = 0;
		for (int k = 0; k < 4; k++) { const int i = c->find(ids[k]); if (i >= 0 && c->mode[i] == M_STAY && c->act[i] == A_WAIT) waiting++; }
		// the bus stands 2.2 m out from the sign, its front door there
		const float ddx = P.x - P.ax, ddz = P.z - P.az, dl = std::max(std::sqrt(ddx * ddx + ddz * ddz), 0.1f);
		const float door_x = P.x + ddx / dl * 2.2f, door_z = P.z + ddz / dl * 2.2f;
		c->bus_at(stop, true, door_x, door_z, 3);
		run(40.0f);
		const int boarded = c->st.boarded, off = c->st.alighted;
		if (boarded != 4) for (int k = 0; k < 4; k++) {
			const int i = c->find(ids[k]);
			if (i < 0) { std::printf("CROWD     (walker %d is gone)\n", ids[k]); continue; }
			std::printf("CROWD     (walker %d: mode %d act %d boarding %d, held %.1f s, speed %.2f, %.2f m from the door, %.2f m from where he is to go, stays %.0f s more, goal %d, buses known %d)\n", ids[k], (int)c->mode[i], (int)c->act[i], (int)c->boarding[i], c->blocked_t[i], c->v[i],
					std::sqrt((c->x[i] - door_x) * (c->x[i] - door_x) + (c->z[i] - door_z) * (c->z[i] - door_z)), std::sqrt((c->x[i] - c->tx[i]) * (c->x[i] - c->tx[i]) + (c->z[i] - c->tz[i]) * (c->z[i] - c->tz[i])), c->stay_t[i], c->goal[i], (int)c->buses.size());
		}
		c->bus_at(stop, false, 0, 0, 0);
		run(20.0f);
		std::snprintf(line, sizeof(line), "J. a bus stop: %d of 4 people sent there wait at it; the bus comes: %d board through its front door, %d of 3 get off", waiting, boarded, off);
		check(waiting == 4 && boarded == 4 && off == 3, line);
	}

	std::printf("RESULT %s\n", fails == 0 ? "PASS" : "FAIL");
	delete c;
	return fails == 0 ? 0 : 1;
}
