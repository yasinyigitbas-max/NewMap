// CityCrowd: see city_crowd.h
#include "city_crowd.h"

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <map>
#include <vector>

namespace godot {

namespace {
const double PIECE_M = 8.0;   // the tool's stretches of pavement are cut into pieces of about this length
}

CityCrowd::CityCrowd() {
	sim = new cc::Sim();
}

CityCrowd::~CityCrowd() {
	delete sim;
}

bool CityCrowd::load_streets(const String &p_path) {
	ready = false;
	const PackedByteArray bytes = FileAccess::get_file_as_bytes(p_path);
	if (bytes.size() < 16 || !streets.load(bytes.ptr(), (size_t)bytes.size())) return false;
	const sg::StreetData &d = streets;
	const int ns0 = (int)d.walk_seg.size() / 8, nn0 = (int)d.walk_node.size() / 2;
	if (ns0 <= 0 || nn0 <= 0) return false;

	// ---- the signal controls: one a junction with signals, two approaches (the street along z, the street along x)
	std::vector<int32_t> node_ctl(d.node_i.size() / 4, -1);
	ctl_node.clear(); ctl_off.clear();
	for (int k = 0; k < ns0; k++) {
		const int32_t *q = &d.walk_seg[(size_t)k * 8];
		if (q[2] != 1 || q[5] < 0 || q[4] < 0 || q[4] >= (int)node_ctl.size()) continue;
		if (node_ctl[q[4]] < 0) {
			node_ctl[q[4]] = (int32_t)ctl_node.size();
			ctl_node.push_back(q[4]);
			const int tx = d.node_i[(size_t)q[4] * 4 + 2], tz = d.node_i[(size_t)q[4] * 4 + 3];
			ctl_off.push_back((float)((((tx * 7 + tz * 13) % SIG_CYCLE_S) + SIG_CYCLE_S) % SIG_CYCLE_S));   // (CityTraffic::load_streets has the same line)
		}
	}

	// ---- the graph: every stretch cut into pieces of about 8 m (a crossing stays whole: a walker decides at its kerb)
	std::vector<float> &node_xz = gr_node_xz, &seg_len = gr_len, &seg_hw = gr_hw, &pts = gr_pts;
	std::vector<int32_t> &seg_a = gr_a, &seg_b = gr_b, &seg_ctl = gr_ctl, &seg_p0 = gr_p0, &seg_np = gr_np;
	std::vector<uint8_t> &seg_kind = gr_kind, &seg_zone = gr_zone;
	node_xz.assign(d.walk_node.begin(), d.walk_node.end());
	seg_a.clear(); seg_b.clear(); seg_ctl.clear(); seg_p0.clear(); seg_np.clear(); seg_kind.clear(); seg_zone.clear(); seg_len.clear(); seg_hw.clear(); pts.clear();
	n_cross = n_cross_signal = 0; walk_m = 0.0;
	for (int k = 0; k < ns0; k++) {
		const int32_t *q = &d.walk_seg[(size_t)k * 8];
		const int p0 = q[6], np = q[7];
		if (np < 2) continue;
		const float *P = &d.walk_pts[(size_t)p0 * 3];
		std::vector<double> cum(np, 0.0);
		for (int i = 1; i < np; i++) cum[i] = cum[i - 1] + std::hypot(P[i * 3] - P[i * 3 - 3], P[i * 3 + 2] - P[i * 3 - 1]);
		const double len = cum[np - 1];
		if (len < 0.05) continue;
		const bool cross = q[2] == 1;
		const int pieces = cross ? 1 : std::max(1, (int)std::ceil(len / PIECE_M));
		const float hw = d.walk_seg_f[(size_t)k * 2 + 1];
		int ctl = -1;
		if (cross) { n_cross++; if (q[5] >= 0 && q[4] >= 0 && q[4] < (int)node_ctl.size()) { ctl = node_ctl[q[4]]; n_cross_signal++; } }
		else walk_m += len;
		int from = q[0], at = 0;   // (at: the first original point not yet passed)
		double s0 = 0.0;
		for (int c = 0; c < pieces; c++) {
			const double s1 = c == pieces - 1 ? len : len * (double)(c + 1) / (double)pieces;
			auto point_at = [&](double s, float out[3]) {
				int i = 1;
				while (i < np - 1 && cum[i] < s) i++;
				const double t = cum[i] > cum[i - 1] ? (s - cum[i - 1]) / (cum[i] - cum[i - 1]) : 0.0;
				for (int a = 0; a < 3; a++) out[a] = (float)(P[(i - 1) * 3 + a] + (P[i * 3 + a] - P[(i - 1) * 3 + a]) * t);
			};
			const int first = (int)pts.size() / 3;
			float a3[3]; point_at(s0, a3); pts.insert(pts.end(), a3, a3 + 3);
			while (at < np && cum[at] <= s0 + 0.02) at++;
			while (at < np && cum[at] < s1 - 0.02) { pts.insert(pts.end(), P + at * 3, P + at * 3 + 3); at++; }
			float b3[3]; point_at(s1, b3); pts.insert(pts.end(), b3, b3 + 3);
			int to = q[1];
			if (c < pieces - 1) { to = (int)node_xz.size() / 2; node_xz.push_back(b3[0]); node_xz.push_back(b3[2]); }
			seg_a.push_back(from); seg_b.push_back(to); seg_kind.push_back(cross ? (uint8_t)cc::SEG_CROSS : (uint8_t)cc::SEG_WALK);
			seg_zone.push_back((uint8_t)std::min(std::max(q[3], 0), cc::MAX_ZONES - 1)); seg_ctl.push_back(ctl);
			seg_p0.push_back(first); seg_np.push_back((int)pts.size() / 3 - first);
			seg_len.push_back((float)(s1 - s0)); seg_hw.push_back(std::max(hw, 0.45f));
			from = to; s0 = s1;
		}
	}
	n_nodes = (int)node_xz.size() / 2; n_segs = (int)seg_a.size();
	feed();
	// the same pieces in 16 m cells, for off_walk()
	g_pts = pts; g_p0 = seg_p0; g_np = seg_np; g_hw = seg_hw;
	for (int k = 0; k < n_segs; k++) if (seg_kind[k] == cc::SEG_CROSS) g_hw[k] = (float)sim->cfg.half_w_cross;
	g_cells.clear();
	for (int k = 0; k < n_segs; k++) {
		int64_t last = INT64_MIN;
		for (int q = 0; q < g_np[k]; q++) {
			const float *a = &g_pts[(size_t)(g_p0[k] + q) * 3];
			const int64_t key = ((int64_t)std::floor(a[0] / 16.0f) << 32) ^ (int64_t)(uint32_t)(int32_t)std::floor(a[2] / 16.0f);
			if (key != last) { std::vector<int32_t> &v = g_cells[key]; if (v.empty() || v.back() != k) v.push_back(k); last = key; }
		}
	}
	ready = true;
	return true;
}

// The graph, the signal controls and who walks together, into the core (a new core gets the same)
void CityCrowd::feed() {
	sim->set_graph(gr_node_xz.data(), n_nodes, gr_a.data(), gr_b.data(), gr_kind.data(), gr_zone.data(), gr_ctl.data(), gr_p0.data(), gr_np.data(),
			gr_len.data(), n_segs, gr_pts.data(), (int)gr_pts.size() / 3);
	sim->set_seg_half_widths(gr_hw.data(), n_segs);
	// the controls: approach 0 heads along z, approach 1 along x (the lamps' and the traffic's two phases)
	std::vector<int32_t> first(ctl_node.size() + 1, 0);
	std::vector<float> heads;
	for (size_t c = 0; c < ctl_node.size(); c++) { first[c] = (int32_t)c * 2; heads.insert(heads.end(), { 0.0f, 1.0f, 1.0f, 0.0f }); }
	first[ctl_node.size()] = (int32_t)ctl_node.size() * 2;
	sim->set_controls(first.data(), (int)ctl_node.size(), heads.data(), (int)ctl_node.size() * 2);
	// who walks together, by zone: alone, couple, friends, family, sailors, jogger
	double mix[cc::MAX_ZONES * cc::PK_COUNT];
	const double by_zone[5][cc::PK_COUNT] = {
		{ 0.66, 0.16, 0.06, 0.08, 0.0, 0.04 },    // 0 quiet streets
		{ 0.64, 0.18, 0.08, 0.07, 0.0, 0.03 },    // 1
		{ 0.52, 0.22, 0.16, 0.09, 0.0, 0.01 },    // 2 the busy streets
		{ 0.44, 0.24, 0.14, 0.10, 0.02, 0.06 },   // 3 the waterfront walk
		{ 0.74, 0.12, 0.08, 0.03, 0.0, 0.03 } };  // 4 beside the arterials
	for (int z = 0; z < cc::MAX_ZONES; z++) for (int k = 0; k < cc::PK_COUNT; k++) mix[z * cc::PK_COUNT + k] = by_zone[std::min(z, 4)][k];
	sim->set_party_mix(mix, cc::MAX_ZONES);
	sim->set_time(12.0, 2, 6.0, 19.0);
}

Dictionary CityCrowd::walk_stats() const {
	Dictionary d;
	d["built"] = ready; d["nodes"] = n_nodes; d["pieces"] = n_segs; d["pavement_km"] = walk_m / 1000.0;
	d["crossings"] = n_cross; d["crossings_at_signals"] = n_cross_signal; d["signal_junctions"] = (int)ctl_node.size();
	return d;
}

int CityCrowd::off_walk() const {
	int n = 0;
	for (int i = 0; i < sim->n_slots; i++) {
		if (!sim->alive[i] || (sim->flags[i] & (cc::F_HIDDEN | cc::F_ON_LINK))) continue;
		const float px = sim->x[i], pz = sim->z[i];
		const int cx = (int)std::floor(px / 16.0f), cz = (int)std::floor(pz / 16.0f);
		bool on = false;
		for (int gz = cz - 1; gz <= cz + 1 && !on; gz++) for (int gx = cx - 1; gx <= cx + 1 && !on; gx++) {
			const auto it = g_cells.find(((int64_t)gx << 32) ^ (int64_t)(uint32_t)(int32_t)gz);
			if (it == g_cells.end()) continue;
			for (int k : it->second) {
				const float lim = g_hw[k] + 0.35f;
				for (int q = 0; q + 1 < g_np[k] && !on; q++) {
					const float *a = &g_pts[(size_t)(g_p0[k] + q) * 3], *b = a + 3;
					const float dx = b[0] - a[0], dz = b[2] - a[2], l2 = dx * dx + dz * dz;
					const float t = l2 > 1.0e-8f ? std::min(std::max(((px - a[0]) * dx + (pz - a[2]) * dz) / l2, 0.0f), 1.0f) : 0.0f;
					const float ex = px - (a[0] + dx * t), ez = pz - (a[2] + dz * t);
					if (ex * ex + ez * ez <= lim * lim) on = true;
				}
				if (on) break;
			}
		}
		if (!on) n++;
	}
	return n;
}

void CityCrowd::push_signals(double p_clock) {
	for (size_t c = 0; c < ctl_off.size(); c++) {
		uint32_t mask = 0;
		for (int ph = 0; ph < 2; ph++) {
			double f = std::fmod((p_clock + ctl_off[c]) / (double)SIG_CYCLE_S + (ph ? 0.5 : 0.0), 1.0);
			if (f < 0.0) f += 1.0;
			if (f < 5.0 / (double)SIG_CYCLE_S) mask |= 1u << ph;   // "walk": the first 5 s of that street's green
		}
		sim->set_signal((int)c, mask);
	}
}

void CityCrowd::push_targets() {
	double t[cc::MAX_ZONES], sum = 0.0;
	for (int z = 0; z < cc::MAX_ZONES; z++) { t[z] = sim->zone_metres(z) * dens[z] * density; sum += t[z]; }
	if (sum > (double)max_people && sum > 0.0) for (int z = 0; z < cc::MAX_ZONES; z++) t[z] *= (double)max_people / sum;
	sim->set_zone_targets(t, cc::MAX_ZONES);
}

Dictionary CityCrowd::run_test(int p_people, double p_minutes, int64_t p_seed, const Vector3 &p_cam, double p_density) {
	Dictionary d;
	if (!ready) { d["error"] = "no streets"; return d; }
	const int keep_people = max_people; const double keep_density = density;
	max_people = p_people; density = p_density;
	delete sim; sim = new cc::Sim(); feed();   // (a core that has never run: what a walker's slot held before is not carried into this run)
	sim->cfg.max_agents = std::min(p_people + 40, (int)cc::MAX_AGENTS);
	sim->set_cells(std::vector<uint8_t>(), true);
	sim->reset((uint64_t)p_seed);
	sim->set_view(p_cam.x, p_cam.z, 0.0, 1.0, 360.0);
	sim->set_player(p_cam.x, p_cam.z);   // (the player stands at the view's centre: the people round it are the ones that deal with each other)
	const double dt = 0.05;
	const int ticks = (int)(p_minutes * 60.0 / dt);
	double clock = 0.0, us_sum = 0.0, us_max = 0.0;
	int most = 0, checks = 0;
	int64_t off = 0, nan = 0, over = 0, on_red = 0, crossing_now = 0;
	double v_sum = 0.0; int64_t v_n = 0, standing = 0;
	int64_t over_near = 0;
	std::map<int, int> dbg_kinds;   // DEBUGTMP
	for (int t = 0; t < ticks; t++) {
		push_signals(clock);
		if (t % 20 == 0) push_targets();
		const auto t0 = std::chrono::steady_clock::now();
		sim->step(dt);
		const double us = (double)std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::steady_clock::now() - t0).count() / 1000.0;
		us_sum += us; us_max = std::max(us_max, us);
		sim->events.clear();
		clock += dt;
		most = std::max(most, sim->stats.agents);
		if (t % 20 == 0) {
			int a = 0, b = 0, c = 0;
			sim->audit(a, b, c);
			(void)a; nan += b; over += c; checks++;
			off += off_walk();
			over_near += sim->audit_near();
			for (int i = 0; i < sim->n_slots; i++) {   // DEBUGTMP: what the pairs that stand inside each other are doing
				if (!sim->alive[i] || sim->tier[i] != cc::TIER_FULL) continue;
				for (int j = i + 1; j < sim->n_slots; j++) {
					if (!sim->alive[j] || sim->tier[j] != cc::TIER_FULL) continue;
					const double ex = sim->x[i] - sim->x[j], ez = sim->z[i] - sim->z[j];
					if (ex * ex + ez * ez >= 0.312 * 0.312) continue;
					const int a2 = sim->state[i] * 10 + sim->why[i], b2 = sim->state[j] * 10 + sim->why[j];
					const bool same = sim->party[i] != 0 && sim->party[i] == sim->party[j];
					const bool opp = sim->fx[i] * sim->fx[j] + sim->fz[i] * sim->fz[j] < 0.0f;
					dbg_kinds[(std::min(a2, b2) * 1000 + std::max(a2, b2)) * 100 + (same ? 10 : 0) + (opp ? 1 : 0) + ((sim->lead[i] >= 0 || sim->lead[j] >= 0) ? 20 : 0) + ((sim->act[i] || sim->act[j]) ? 40 : 0)]++;
				}
			}
			for (int i = 0; i < sim->n_slots; i++) {
				if (!sim->alive[i]) continue;
				if (sim->state[i] == cc::S_WALK) { v_sum += sim->v[i]; v_n++; } else standing++;
			}
		}
	}
	d["ticks"] = ticks; d["checks"] = checks;
	d["people_most"] = most; d["people_at_end"] = sim->stats.agents; d["appeared"] = sim->stats.spawned; d["left"] = sim->stats.retired;
	d["inside_each_other_near"] = over_near;
	{ String ks;   // DEBUGTMP
		std::vector<std::pair<int, int>> v(dbg_kinds.begin(), dbg_kinds.end());
		std::sort(v.begin(), v.end(), [](const std::pair<int, int> &a, const std::pair<int, int> &b) { return a.second > b.second; });
		for (size_t k = 0; k < v.size() && k < 8; k++) ks += vformat("[%d: %d] ", v[k].first, v[k].second);
		d["near_kinds"] = ks; }
	d["off_their_pavement"] = off; d["bad_numbers"] = nan; d["inside_each_other"] = over;
	d["routes"] = sim->stats.plans; d["routes_failed"] = sim->stats.plan_fail; d["passes"] = sim->stats.passes;
	d["waited_at_a_signal"] = sim->stats.waits_signal; d["waited_for_a_gap"] = sim->stats.waits_gap;
	d["mean_speed"] = v_n > 0 ? v_sum / (double)v_n : 0.0; d["standing_share"] = (v_n + standing) > 0 ? (double)standing / (double)(v_n + standing) : 0.0;
	d["closest_two_came"] = sim->stats.min_gap;
	d["step_us_mean"] = ticks > 0 ? us_sum / ticks : 0.0; d["step_us_worst"] = us_max;
	d["hash"] = (int64_t)(sim->state_hash() & 0x7fffffffffffffffULL);
	(void)on_red; (void)crossing_now;
	max_people = keep_people; density = keep_density;
	return d;
}

void CityCrowd::_bind_methods() {
	ClassDB::bind_method(D_METHOD("load_streets", "path"), &CityCrowd::load_streets);
	ClassDB::bind_method(D_METHOD("is_built"), &CityCrowd::is_built);
	ClassDB::bind_method(D_METHOD("walk_stats"), &CityCrowd::walk_stats);
	ClassDB::bind_method(D_METHOD("run_test", "people", "minutes", "seed", "cam", "density"), &CityCrowd::run_test);
}

} // namespace godot
