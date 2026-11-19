// Parked cars as part of the traffic (docs/TRAFFIC_PEOPLE_PORT.md section 14): which stall holds which car, a parked
// car that pulls out into its lane, a moving car that pulls into a free kerb stall. A parked car and a moving car are
// the same car in two states: when one parks, the moving car is taken out of the core and its stall takes its model
// and colour; when one pulls out, the stall is emptied and a car of that model and colour starts at the stall.
//
// Runs with the core, on the core's thread (CityTraffic::step_once) and in the test (CityTraffic::run_test). Plain C++.
#pragma once

#include "car_models.h"
#include "street_build.h"
#include "traffic_sim.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <vector>

namespace tp {

inline uint32_t hash32(uint32_t v) {
	v ^= v >> 16; v *= 0x7feb352dU; v ^= v >> 15; v *= 0x846ca68bU; v ^= v >> 16;
	return v;
}

// Which car stands in stall k when its cell comes in: fixed by the stall's own number, so a street looks the same
// every time. Kerb stalls are fuller than car parks. model 255 = empty.
inline void seed_stall(int k, bool kerb, uint8_t &model, uint8_t &colour) {
	model = 255; colour = 0;
	const uint32_t h = hash32((uint32_t)k * 2654435761u + 977u);
	if ((h & 1023u) >= (kerb ? 720u : 560u)) return;   // 70 % of kerb stalls, 55 % of car-park stalls
	float wsum = 0.0f;
	for (int m = 0; m < cm::N_MODELS; m++) wsum += cm::MODELS[m].weight;
	float r = (float)((h >> 10) & 1023u) / 1024.0f * wsum;
	int m = 0;
	for (; m < cm::N_MODELS - 1; m++) { r -= cm::MODELS[m].weight; if (r <= 0.0f) break; }
	model = (uint8_t)m; colour = (uint8_t)cm::pick_colour(hash32(h + 0x9e3779b9u));
}

struct Event { int32_t stall; uint8_t model, colour; };   // the stall's new state (model 255 = empty)

struct Parking {
	enum { EMPTY = 255, RESERVED = 254 };
	struct Stall {
		int32_t lane = -1;          // -1 = a car-park stall (not part of the traffic)
		float s = 0, lat = 0;       // along its lane, and sideways from the lane's middle (+ = left of travel)
		float x = 0, y = 0, z = 0, yaw = 0;
		int32_t prev = -1, next = -1;   // the kerb stalls right before / after it on the same lane (within 8 m), or -1
		int32_t cell = -1;
		uint8_t model = EMPTY, colour = 0, loaded = 0;
		float skew = 0;             // how far it is turned against its lane, rad (0 = along the kerb)
		uint8_t usable = 0;         // a steered car can drive into and out of it: along the kerb, with room to the next ones
	};
	std::vector<Stall> st;
	std::vector<std::vector<int32_t>> lane_stalls;   // per lane: its kerb stalls, by s
	std::vector<uint8_t> kerb_kind;                  // per stall: 1 = a kerb stall in streets.bin (what it holds at first depends on it)
	std::vector<int32_t> cand;                       // kerb stalls of the loaded cells
	struct Job { int32_t car_id, stall; float t; };
	std::vector<Job> jobs;                           // cars on their way into a stall
	struct Fresh { int32_t car_id; float t; };
	std::vector<Fresh> fresh;                        // cars that have just pulled out (the parked cars round them are shown to the core)
	std::vector<float> dyn;                          // the boxes for Sim::set_dynamic (the caller hands them over, with its own)
	std::vector<uint32_t> shown;                     // per stall: the step it was last put in dyn
	uint32_t show_stamp = 0;
	std::vector<Event> events;                       // what changed since the caller last took them
	uint64_t rng = 0x9E3779B97F4A7C15ull;
	int pulled_out = 0, parked = 0, gave_up = 0;
	int n_lane_stalls = 0, n_skewed = 0, n_close = 0, n_usable = 0;   // of the kerb stalls beside a lane
	double park_off = 0.0, park_yaw = 0.0;   // summed over the cars that parked: how far beside the stall's middle, how far from its direction (rad)
	float park_off_max = 0.0f, park_yaw_max = 0.0f;
	float every_s = 4.0f;       // about one car pulls out and one parks in this many seconds, where there are cars to do it
	bool on = true;
	int grid = 64; float cell_m = 200.0f;

	inline float rnd() { rng ^= rng >> 12; rng ^= rng << 25; rng ^= rng >> 27; return (float)((rng * 0x2545F4914F6CDD1Dull) >> 40) / 16777216.0f; }
	inline int cell_index(float x, float z) const {
		const int cx = (int)std::floor(x / cell_m) + grid / 2, cz = (int)std::floor(z / cell_m) + grid / 2;
		return (cx < 0 || cz < 0 || cx >= grid || cz >= grid) ? -1 : cz * grid + cx;
	}

	// The stalls of streets.bin against the lanes: where each kerb stall lies along its lane and beside it.
	void init(const sg::StreetData &d) {
		const int ns = (int)d.stall_i.size() / 4, nl = (int)d.lane_off.size() - 1;
		st.assign(ns, Stall());
		kerb_kind.assign(ns, 0);
		jobs.clear(); fresh.clear(); events.clear(); dyn.clear(); cand.clear();
		pulled_out = parked = gave_up = 0; park_off = park_yaw = 0.0; park_off_max = park_yaw_max = 0.0f;
		lane_stalls.assign(std::max(nl, 0), std::vector<int32_t>());
		for (int k = 0; k < ns; k++) {
			Stall &q = st[k];
			const float *f = &d.stall_f[(size_t)k * 8];
			q.x = f[0]; q.y = f[1]; q.z = f[2]; q.yaw = f[3];
			q.cell = cell_index(q.x, q.z);
			const bool kerb = d.stall_i[(size_t)k * 4] == 0;
			kerb_kind[k] = kerb ? 1 : 0;
			seed_stall(k, kerb, q.model, q.colour);
			const int L = d.stall_i[(size_t)k * 4 + 1];
			if (!kerb || L < 0 || L >= nl) continue;
			// the nearest point of the lane's line
			const int o0 = d.lane_off[L], o1 = d.lane_off[L + 1];
			float best = 1.0e9f, acc = 0.0f;
			for (int p = o0; p + 1 < o1; p++) {
				const float ax = d.lane_pts[(size_t)p * 3], az = d.lane_pts[(size_t)p * 3 + 2], bx = d.lane_pts[(size_t)p * 3 + 3], bz = d.lane_pts[(size_t)p * 3 + 5];
				const float dx = bx - ax, dz = bz - az, len = std::sqrt(dx * dx + dz * dz);
				if (len < 1.0e-4f) continue;
				const float t = std::min(std::max(((q.x - ax) * dx + (q.z - az) * dz) / (len * len), 0.0f), 1.0f);
				const float ex = q.x - (ax + dx * t), ez = q.z - (az + dz * t), d2 = ex * ex + ez * ez;
				if (d2 < best) {   // left of travel = (dz, -dx)
					best = d2; q.s = acc + t * len; q.lat = ((q.x - ax) * dz - (q.z - az) * dx) / len;
					float dy = std::fabs(std::atan2(dx, dz) - q.yaw);
					while (dy > 3.14159265f) dy = std::fabs(dy - 6.2831853f);
					q.skew = dy > 1.5708f ? 3.14159265f - dy : dy;   // (a stall has no front and back)
				}
				acc += len;
			}
			if (best > 6.0f * 6.0f || std::fabs(q.lat) < 2.0f || std::fabs(q.lat) > 4.5f) continue;   // (not beside its lane after all: it stays a car that only stands)
			q.lane = L;
			lane_stalls[L].push_back(k);
		}
		for (auto &v : lane_stalls) {
			std::sort(v.begin(), v.end(), [&](int a, int b) { return st[a].s < st[b].s; });
			for (size_t i = 0; i + 1 < v.size(); i++) if (st[v[i + 1]].s - st[v[i]].s < 8.0f) { st[v[i]].next = v[i + 1]; st[v[i + 1]].prev = v[i]; }
		}
		// A steered car drives into and out of a stall that lies ALONG the kerb with a car's length to its neighbours.
		// The others (turned stalls, stalls closer together than a car is long) keep cars that only stand.
		n_lane_stalls = n_skewed = n_close = n_usable = 0;
		for (int k = 0; k < ns; k++) {
			Stall &q = st[k];
			if (q.lane < 0) continue;
			n_lane_stalls++;
			const bool skewed = q.skew > 0.10f;
			const bool close = (q.prev >= 0 && q.s - st[q.prev].s < 5.4f) || (q.next >= 0 && st[q.next].s - q.s < 5.4f);
			if (skewed) n_skewed++;
			if (close) n_close++;
			q.usable = (!skewed && !close) ? 1 : 0;
			if (q.usable) n_usable++;
		}
	}

	// The streamer's cells (64 x 64, 1 = in; empty = everything counts as in). A stall whose cell is not in goes back
	// to what it holds when its cell comes in: the same street every time.
	void set_cells(const std::vector<uint8_t> &cells, bool all) {
		cand.clear();
		for (int k = 0; k < (int)st.size(); k++) {
			Stall &q = st[k];
			const bool in = all || (q.cell >= 0 && q.cell < (int)cells.size() && cells[q.cell]);
			if (!in && q.loaded) {
				bool busy = false;
				for (const Job &j : jobs) if (j.stall == k) busy = true;
				if (!busy) seed_stall(k, kerb_kind[k] != 0, q.model, q.colour);
			}
			q.loaded = in ? 1 : 0;
			if (in && q.lane >= 0) cand.push_back(k);
		}
	}
	inline bool taken(int k) const { return k >= 0 && st[k].model < RESERVED; }

	// One step of the core's time. Before sim.step(): it may place a car, give one a goal, take one out.
	void tick(tc::Sim &sim, float h) {
		if (!on) { dyn.clear(); return; }
		// ---- cars on their way into a stall
		for (size_t j = 0; j < jobs.size();) {
			Job &jb = jobs[j];
			jb.t += h;
			Stall &q = st[jb.stall];
			const int i = sim.find_car(jb.car_id);
			bool done = false;
			if (i < 0) { q.model = EMPTY; done = true; }   // (the car is gone: its cell left, or it was taken away)
			else if (sim.arrived[i] && (std::fabs(sim.latm[i] - q.lat) < 0.3f || (sim.wait_t[i] > 5.0f && std::fabs(sim.latm[i] - q.lat) < 0.8f))) {
				// it stands in the stall (or, rarely, a little off it after 5 s: then it counts as in)
				{
					const float off = std::fabs(sim.latm[i] - q.lat);
					float dy = std::fabs(sim.yaw[i] - q.yaw); while (dy > 3.14159265f) dy = std::fabs(dy - 6.2831853f);
					if (dy > 1.5708f) dy = 3.14159265f - dy;   // (a stall has no front and back)
					park_off += off; park_yaw += dy; park_off_max = std::max(park_off_max, off); park_yaw_max = std::max(park_yaw_max, dy);
				}
				q.model = sim.model[i]; q.colour = car_colour(sim, i);
				events.push_back(Event{ jb.stall, q.model, q.colour });
				sim.despawn(i, 7);
				parked++; done = true;
			} else {
				const float dx = sim.x[i] - sim.cam_x, dz = sim.z[i] - sim.cam_z;
				if (jb.t > 50.0f || dx * dx + dz * dz > 330.0f * 330.0f || !q.loaded || (sim.arrived[i] && sim.wait_t[i] > 8.0f)) {
					// it does not get there: it drives on (or leaves with its cell). The parked cars round it stay
					// boxes to the core until it is back in its lane.
					sim.release_car(jb.car_id);
					fresh.push_back(Fresh{ jb.car_id, 0.0f });
					q.model = EMPTY; gave_up++; done = true;
				}
			}
			if (done) { jobs[j] = jobs.back(); jobs.pop_back(); } else j++;
		}
		for (size_t j = 0; j < fresh.size();) {
			fresh[j].t += h;
			// (until it is back in its lane: a steered car needs some metres for that, not a fixed time)
			const int fi = sim.find_car(fresh[j].car_id);
			const bool back = fi >= 0 && fresh[j].t > 3.0f && std::fabs(sim.lat[fi]) < 0.25f && std::fabs(sim.latm[fi]) < 0.5f;
			if (fi < 0 || back) { fresh[j] = fresh.back(); fresh.pop_back(); } else j++;
		}
		// ---- now and then: one pulls out, one parks
		if (sim.tick % 10 == 0) {
			const float p = 0.5f / std::max(every_s, 0.5f);   // (twice a second)
			if (rnd() < p) try_pull_out(sim);
			if (rnd() < p * 1.5f) try_park(sim);   // (a try to park fails more often than a try to pull out: about as many of each in the end)
		}
		// ---- the parked cars round a car that is parking or has just pulled out are boxes to the core: it never moves
		// into them (the lanes themselves keep 0.85 m off the parked cars; this is for the way in and out)
		dyn.clear();
		if (shown.size() != st.size()) shown.assign(st.size(), 0);
		show_stamp++;
		auto show = [&](int car_id) {
			const int i = sim.find_car(car_id);
			if (i < 0) return;
			const int L = sim.lane[i];
			if (L < 0 || L >= (int)lane_stalls.size()) return;
			for (int k : lane_stalls[L]) {
				const Stall &q = st[k];
				if (q.model >= RESERVED || std::fabs(q.s - sim.s[i]) > 45.0f || (int)dyn.size() >= 200 * tc::DYN_STRIDE || shown[k] == show_stamp) continue;
				shown[k] = show_stamp;
				const cm::CarModel &m = cm::MODELS[q.model];
				const float b[tc::DYN_STRIDE] = { q.x, q.y, q.z, q.yaw, m.half_len, m.half_w, 0.0f, 0.0f, (float)tc::DYN_OTHER, (float)(100000 + k), 0.0f };
				dyn.insert(dyn.end(), b, b + tc::DYN_STRIDE);
			}
		};
		for (const Job &jb : jobs) show(jb.car_id);
		for (const Fresh &f : fresh) show(f.car_id);
	}

	// a moving car's paint: its own (a car that pulled out keeps the colour it stood there with), or by its number
	static inline uint8_t car_colour(const tc::Sim &sim, int i) {
		return sim.colour[i] >= 100 ? (uint8_t)(sim.colour[i] - 100) : (uint8_t)cm::pick_colour(hash32((uint32_t)sim.id[i] * 2246822519u + 31u));
	}

	// is any stall of lane L taken whose middle lies between s0 and s1 (not stall `but`)?
	bool taken_between(int L, float s0, float s1, int but) const {
		for (int k : lane_stalls[L]) {
			if (k == but) continue;
			const Stall &q = st[k];
			if (q.s <= s0) continue;
			if (q.s >= s1) break;
			if (q.model != EMPTY) return true;   // (a stall somebody is on his way into counts)
		}
		return false;
	}

	void try_pull_out(tc::Sim &sim) {
		if (cand.empty() || sim.n_alive >= sim.cfg.max_cars + 4 || sim.n_alive >= tc::MAX_CARS - 4) return;
		for (int tries = 0; tries < 10; tries++) {
			const int k = cand[std::min((int)(rnd() * (float)cand.size()), (int)cand.size() - 1)];
			Stall &q = st[k];
			if (q.model >= RESERVED || !q.loaded || !q.usable) continue;
			const int L = q.lane;
			if (taken_between(L, q.s, q.s + tc::OUT_M + 4.5f, k)) continue;   // free kerb ahead for the S out into the lane
			if (q.s < 45.0f || q.s > sim.p_len[L] - 30.0f) continue;       // not at a junction
			const float dx = q.x - sim.cam_x, dz = q.z - sim.cam_z, d2 = dx * dx + dz * dz;
			if (d2 < 14.0f * 14.0f || d2 > 300.0f * 300.0f) continue;      // not on top of the camera, not where nobody sees it
			bool clear = true;
			for (int j = 0; j < sim.hi && clear; j++) {
				if (!sim.alive[j]) continue;
				if (sim.conn[j] < 0 && sim.lane[j] == L && sim.s[j] > q.s - 45.0f && sim.s[j] < q.s + 14.0f) clear = false;
				const float ex = sim.x[j] - q.x, ez = sim.z[j] - q.z;
				if (ex * ex + ez * ez < 9.0f * 9.0f) clear = false;
			}
			if (!clear) continue;
			const int i = sim.unpark(L, q.s, q.lat, q.model, (int)(rnd() * 3.0f));
			if (i < 0) return;
			sim.colour[i] = (uint8_t)(100 + q.colour);
			fresh.push_back(Fresh{ sim.id[i], 0.0f });
			q.model = EMPTY;
			events.push_back(Event{ k, EMPTY, 0 });
			pulled_out++;
			return;
		}
	}

	void try_park(tc::Sim &sim) {
		if (sim.hi <= 0 || (int)jobs.size() >= 3) return;
		for (int tries = 0; tries < 10; tries++) {
			const int i = std::min((int)(rnd() * (float)sim.hi), sim.hi - 1);
			if (!sim.alive[i] || sim.kind[i] != tc::K_AMBIENT || sim.conn[i] >= 0 || (sim.flags[i] & tc::F_RES) || sim.v[i] < 3.0f || std::fabs(sim.lat[i]) > 0.4f) continue;
			if (sim.model[i] >= cm::N_MODELS || cm::MODELS[sim.model[i]].half_len > 2.7f) continue;   // (a bus does not park at the kerb)
			const int L = sim.lane[i];
			if (L >= (int)lane_stalls.size() || lane_stalls[L].empty()) continue;
			for (int k : lane_stalls[L]) {
				Stall &q = st[k];
				const float ahead = q.s - sim.s[i];
				if (ahead < 35.0f) continue;
				if (ahead > 120.0f) break;
				if (q.model != EMPTY || !q.loaded || !q.usable || q.s > sim.p_len[L] - 30.0f) continue;
				if (taken_between(L, q.s - 20.0f, q.s, k)) continue;   // free kerb before it for the S in
				{ const float dx = q.x - sim.cam_x, dz = q.z - sim.cam_z; if (dx * dx + dz * dz > 300.0f * 300.0f) continue; }
				bool other = false;
				for (const Job &jb : jobs) if (jb.stall == q.prev || jb.stall == q.next) other = true;
				if (other) continue;
				if (!sim.park_at(sim.id[i], q.s, q.lat, 20.0f)) break;
				q.model = RESERVED;
				jobs.push_back(Job{ sim.id[i], k, 0.0f });
				return;
			}
		}
	}

	// For the test's failure lines: the first moving car that touches a parked one, and what it is doing
	bool touch_case(const tc::Sim &sim, int out_i[6], float out_f[6]) const {
		for (int i = 0; i < sim.hi; i++) {
			if (!sim.alive[i] || sim.conn[i] >= 0) continue;
			const int L = sim.lane[i];
			if (L < 0 || L >= (int)lane_stalls.size()) continue;
			for (int k : lane_stalls[L]) {
				const Stall &q = st[k];
				if (q.model >= RESERVED || std::fabs(q.s - sim.s[i]) > 9.0f) continue;
				const cm::CarModel &m = cm::MODELS[q.model];
				if (!boxes_touch(sim.x[i], sim.z[i], sim.fx[i], sim.fz[i], sim.hl[i], sim.hw[i], q.x, q.z, std::sin(q.yaw), std::cos(q.yaw), m.half_len, m.half_w)) continue;
				int role = 0;   // 1 = on its way into a stall, 2 = has just pulled out
				for (const Job &jb : jobs) if (jb.car_id == sim.id[i]) role = 1;
				for (const Fresh &f : fresh) if (f.car_id == sim.id[i]) role = 2;
				out_i[0] = sim.id[i]; out_i[1] = role; out_i[2] = sim.man[i]; out_i[3] = sim.kind[i]; out_i[4] = k; out_i[5] = sim.why[i];
				out_f[0] = sim.lat[i]; out_f[1] = sim.latm[i]; out_f[2] = q.lat; out_f[3] = q.s - sim.s[i]; out_f[4] = sim.v[i]; out_f[5] = (float)dyn.size() / (float)tc::DYN_STRIDE;
				return true;
			}
		}
		return false;
	}

	// For the test: moving cars that touch a parked car (must be 0). The car that is entering a stall does not count
	// against that stall (it is empty until the car stands in it).
	int audit(const tc::Sim &sim) const {
		int n = 0;
		for (int i = 0; i < sim.hi; i++) {
			if (!sim.alive[i] || sim.conn[i] >= 0) continue;
			const int L = sim.lane[i];
			if (L < 0 || L >= (int)lane_stalls.size()) continue;
			for (int k : lane_stalls[L]) {
				const Stall &q = st[k];
				if (q.model >= RESERVED || std::fabs(q.s - sim.s[i]) > 9.0f) continue;
				const cm::CarModel &m = cm::MODELS[q.model];
				if (boxes_touch(sim.x[i], sim.z[i], sim.fx[i], sim.fz[i], sim.hl[i], sim.hw[i], q.x, q.z, std::sin(q.yaw), std::cos(q.yaw), m.half_len, m.half_w)) n++;
			}
		}
		return n;
	}
	static inline bool boxes_touch(float ax, float az, float afx, float afz, float ahl, float ahw, float bx, float bz, float bfx, float bfz, float bhl, float bhw) {
		const float dx = bx - ax, dz = bz - az;
		const float axes[4][2] = { { afx, afz }, { afz, -afx }, { bfx, bfz }, { bfz, -bfx } };
		for (int k = 0; k < 4; k++) {
			const float ux = axes[k][0], uz = axes[k][1];
			const float ra = ahl * std::fabs(afx * ux + afz * uz) + ahw * std::fabs(afz * ux - afx * uz);
			const float rb = bhl * std::fabs(bfx * ux + bfz * uz) + bhw * std::fabs(bfz * ux - bfx * uz);
			if (std::fabs(dx * ux + dz * uz) > ra + rb) return false;
		}
		return true;
	}
};

} // namespace tp
