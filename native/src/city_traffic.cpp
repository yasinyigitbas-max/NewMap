// CityTraffic: see city_traffic.h
#include "city_traffic.h"

#include "car_models.h"
#include "traffic_sim.h"

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <vector>

namespace godot {

CityTraffic::CityTraffic() {
	sim = new tc::Sim();
}

CityTraffic::~CityTraffic() {
	delete sim;
}

bool CityTraffic::load_streets(const String &p_path) {
	ready = false;
	const PackedByteArray bytes = FileAccess::get_file_as_bytes(p_path);
	if (bytes.size() < 16 || !streets.load(bytes.ptr(), (size_t)bytes.size())) return false;
	const int nl = streets.lanes();
	if (nl <= 0) return false;
	std::vector<float> models;
	for (int i = 0; i < cm::N_MODELS; i++) {
		models.push_back(cm::MODELS[i].half_len); models.push_back(cm::MODELS[i].half_w); models.push_back(cm::MODELS[i].weight);
	}
	sim->set_models(cm::N_MODELS, models.data());
	sim->set_lanes(nl, streets.lane_pts.data(), streets.lane_off.data(), streets.lane_f.data(), streets.lane_i.data());
	sim->set_connections(streets.connections(), streets.conns.data());
	// every junction's own start in the signal cycle: whole seconds from its 200 m tile, so the lamps' shader can be
	// given exactly the same number (stage 2c)
	const int nn = (int)streets.node_i.size() / 4;
	std::vector<float> off(nn, 0.0f);
	for (int i = 0; i < nn; i++) {
		const int tx = streets.node_i[(size_t)i * 4 + 2], tz = streets.node_i[(size_t)i * 4 + 3];
		off[i] = (float)((((tx * 7 + tz * 13) % 30) + 30) % 30);
	}
	sim->set_signal_offsets(nn, off.data());
	ready = sim->build();
	return ready;
}

Dictionary CityTraffic::street_stats() const {
	Dictionary d;
	d["built"] = ready;
	d["lanes"] = sim->n_lanes;
	d["paths"] = sim->n_conns;
	d["conflict_pairs"] = sim->st.n_conflict_pairs;
	d["dead_end_lanes"] = sim->st.n_deadend_lanes;
	d["blocked_lanes"] = sim->st.n_blocked_lanes;
	d["build_ms"] = sim->st.build_ms;
	int sig = 0, stop = 0, exits = 0;
	for (int l = 0; l < sim->n_lanes; l++) {
		if (sim->l_ctl[l] == tc::C_SIGNAL) sig++;
		if (sim->l_ctl[l] == tc::C_STOP) stop++;
		if (sim->l_flags[l] & tc::LF_EXIT) exits++;
	}
	d["lanes_at_signals"] = sig; d["lanes_at_stops"] = stop; d["lanes_out_of_the_map"] = exits;
	return d;
}

Dictionary CityTraffic::run_test(int p_cars, double p_minutes, int64_t p_seed, const Vector3 &p_cam, bool p_whole_city, bool p_stuck_rule, double p_density) {
	Dictionary d;
	if (!ready) { d["error"] = "no streets"; return d; }
	tc::Config keep = sim->cfg;
	sim->cfg.max_cars = std::min(p_cars, (int)tc::MAX_CARS);
	sim->cfg.hour_factor = 1.0f;
	sim->cfg.dens_scale = (float)p_density;
	sim->cfg.stuck_despawn_s = p_stuck_rule ? 60.0f : 1.0e9f;
	if (p_whole_city) {
		sim->cfg.spawn_r_in = 0.0f; sim->cfg.spawn_r_out = 2400.0f; sim->cfg.despawn_r = 5000.0f; sim->cfg.behind_despawn_r = 5000.0f;
		sim->cfg.view_safe_r = 0.0f; sim->cfg.tier_full_r = 6000.0f; sim->cfg.tier_mid_r = 7000.0f;
	}
	sim->reset_cars((uint64_t)p_seed);
	sim->set_view(p_cam.x, p_cam.y, p_cam.z, 0.0f, 1.0f, 0.0f);   // no view cone: cars may appear anywhere in the ring
	const float dt = 0.05f;
	const int ticks = (int)(p_minutes * 60.0 / dt);
	double clock = 0.0, us_sum = 0.0, us_max = 0.0;
	int64_t ov_car = 0, ov_static = 0, ov_dyn = 0;
	int alive_max = 0, stuck_max = 0, stuck_id = -1, checks = 0;
	float stuck_x = 0.0f, stuck_z = 0.0f, stuck_wait = 0.0f; int stuck_why = 0;
	double v_sum = 0.0; int64_t v_n = 0;
	// who stands, longest first: for finding the head of a jam. Taken at the moment most cars stand.
	Array worst_standing;
	auto snapshot = [&]() {
		std::vector<int> order;
		for (int i = 0; i < sim->hi; i++) if (sim->alive[i] && sim->wait_t[i] > 45.0f) order.push_back(i);
		std::sort(order.begin(), order.end(), [&](int a, int b) { return sim->wait_t[a] > sim->wait_t[b]; });
		Array standing;
		for (size_t k = 0; k < order.size() && k < 14; k++) {
			const int i = order[k];
			Dictionary c;
			c["id"] = sim->id[i]; c["x"] = sim->x[i]; c["z"] = sim->z[i]; c["wait_s"] = sim->wait_t[i]; c["why"] = sim->why[i];
			c["lane"] = sim->lane[i]; c["on_path"] = sim->conn[i]; c["next_path"] = sim->nconn[i]; c["s"] = sim->s[i]; c["lane_len"] = sim->p_len[sim->lane[i]];
			c["leader"] = sim->lead_id[i]; c["stopped_by"] = sim->veto_by[i];
			c["refused_why"] = sim->yinfo[i][0]; c["refused_by"] = sim->yinfo[i][1]; c["refused_value"] = sim->yinfo[i][2];
			c["control"] = sim->l_ctl[sim->lane[i]]; c["signal"] = sim->signal_state(sim->lane[i], clock);
			c["turn"] = sim->nconn[i] >= 0 ? (int)sim->c_turn[sim->nconn[i]] : -1;
			c["to_lane"] = sim->nconn[i] >= 0 ? sim->c_to[sim->nconn[i]] : -1;
			c["node"] = sim->l_node1[sim->lane[i]];
			c["flags"] = (int)sim->flags[i]; c["man"] = sim->man[i];
			// the car named in the last refusal: where it is and what holds IT
			const int hj = sim->find_car((int)sim->yinfo[i][1]);
			String hs = "gone";
			if (hj >= 0) {
				hs = vformat("car %d at (%.0f, %.0f) v %.1f wait %.0f s why %d lane %d s %.1f/%.1f on path %d next path %d turn %d holds go-ahead %s control %d signal %d stopped by %d refused %d by %d",
						sim->id[hj], sim->x[hj], sim->z[hj], sim->v[hj], sim->wait_t[hj], (int)sim->why[hj], sim->lane[hj], sim->s[hj], sim->p_len[sim->lane[hj]], sim->conn[hj], sim->nconn[hj],
						sim->nconn[hj] >= 0 ? (int)sim->c_turn[sim->nconn[hj]] : -1, (sim->flags[hj] & tc::F_RES) ? "yes" : "no", (int)sim->l_ctl[sim->lane[hj]], sim->signal_state(sim->lane[hj], clock),
						sim->veto_by[hj], (int)sim->yinfo[hj][0], (int)sim->yinfo[hj][1]);
			}
			if ((int)sim->yinfo[i][0] == 5 && sim->nconn[i] >= 0) {   // "no room behind the exit": who is counted as on the way in?
				const int to = sim->c_to[sim->nconn[i]];
				hs = vformat("exit lane %d is %.1f m; on their way in:", to, sim->p_len[to]);
				for (int j = 0; j < sim->hi; j++) {
					if (!sim->alive[j] || j == i) continue;
					bool in_ = false;
					if (sim->lane[j] == to) in_ = true;
					else {
						in_ = (sim->flags[j] & tc::F_RES) && sim->nconn[j] >= 0 && sim->c_to[sim->nconn[j]] == to;
						for (int q = 0; q < sim->chain_n[j] && !in_; q++) in_ = sim->c_to[sim->chain_c[j][q]] == to;
					}
					if (!in_) continue;
					hs += vformat(" [car %d at (%.0f, %.0f) lane %d s %.1f/%.1f on path %d next %d v %.1f wait %.0f why %d go-ahead %s refused %d ctl %d sig %d]", sim->id[j], sim->x[j], sim->z[j], sim->lane[j],
							sim->s[j], sim->p_len[sim->lane[j]], sim->conn[j], sim->nconn[j], sim->v[j], sim->wait_t[j], (int)sim->why[j], (sim->flags[j] & tc::F_RES) ? "yes" : "no", (int)sim->yinfo[j][0],
							(int)sim->l_ctl[sim->lane[j]], sim->signal_state(sim->lane[j], clock));
				}
			}
			hs += vformat(" | itself: lat %.2f latv %.2f hoff %.2f pass_lat %.2f lc_dir %d lane half width %.2f; near it:", sim->lat[i], sim->latv[i], sim->hoff[i], sim->pass_lat[i], (int)sim->lc_dir[i], sim->p_hw[sim->lane[i]]);
			for (int j = 0; j < sim->hi; j++) {
				if (!sim->alive[j] || j == i) continue;
				const float dx = sim->x[j] - sim->x[i], dz = sim->z[j] - sim->z[i];
				if (dx * dx + dz * dz > 14.0f * 14.0f) continue;
				// ahead / left of this car
				const float ah = dx * sim->fx[i] + dz * sim->fz[i], lf = dx * sim->fz[i] - dz * sim->fx[i];
				hs += vformat(" [car %d %.1f m ahead %.1f m left, lane %d path %d v %.1f wait %.0f why %d lat %.2f]", sim->id[j], ah, lf, sim->lane[j], sim->conn[j], sim->v[j], sim->wait_t[j], (int)sim->why[j], sim->lat[j]);
			}
			c["holder"] = hs;
			standing.push_back(c);
		}
		worst_standing = standing;
	};
	for (int t = 0; t < ticks; t++) {
		sim->set_dynamic(0, nullptr);
		sim->step(dt, clock);
		clock += dt;
		sim->events.clear();
		us_sum += sim->st.last_step_us; us_max = std::max(us_max, sim->st.last_step_us);
		alive_max = std::max(alive_max, sim->n_alive);
		if (t % 20 == 0) {   // once a second of traffic time
			int a[3] = { 0, 0, 0 };
			sim->audit(a);
			ov_car += a[0]; ov_static += a[1]; ov_dyn += a[2]; checks++;
			int stuck = 0;
			for (int i = 0; i < sim->hi; i++) {
				if (!sim->alive[i]) continue;
				v_sum += sim->v[i]; v_n++;
				if (sim->wait_t[i] > 120.0f && sim->why[i] != tc::W_SIGNAL) {
					stuck++;
					if (sim->wait_t[i] > stuck_wait) { stuck_wait = sim->wait_t[i]; stuck_id = sim->id[i]; stuck_x = sim->x[i]; stuck_z = sim->z[i]; stuck_why = sim->why[i]; }
				}
			}
			if (stuck > stuck_max) snapshot();
			stuck_max = std::max(stuck_max, stuck);
		}
	}
	d["ticks"] = ticks; d["checks"] = checks;
	d["streets_carry"] = sim->carry;
	d["cars_wanted"] = sim->cfg.max_cars; d["cars_at_end"] = sim->n_alive; d["cars_most"] = alive_max;
	d["overlaps_car_car"] = ov_car; d["overlaps_car_parked"] = ov_static; d["overlaps_car_other"] = ov_dyn;
	d["stuck_over_2min_most"] = stuck_max; d["stuck_longest_s"] = stuck_wait; d["stuck_at"] = Vector3(stuck_x, 0, stuck_z); d["stuck_why"] = stuck_why; d["stuck_id"] = stuck_id;
	d["spawned"] = sim->st.spawned; d["despawned"] = sim->st.despawned; d["taken_away_stuck"] = sim->st.stuck_despawned; d["taken_away_dead_end"] = sim->st.deadend_despawned;
	d["crashes"] = sim->st.crashes; d["emergency_brakes"] = sim->st.emergencies; d["hard_brakes"] = sim->st.hard_brakes; d["honks"] = sim->st.honks;
	d["asks"] = sim->st.asks; d["let_through"] = sim->st.let_through;
	d["lane_changes"] = sim->st.lane_changes; d["passes"] = sim->st.passes; d["reservations"] = sim->st.reservations; d["moves_refused"] = sim->st.vetoes;
	d["mean_speed_kmh"] = v_n > 0 ? v_sum / (double)v_n * 3.6 : 0.0;
	d["step_us_mean"] = ticks > 0 ? us_sum / ticks : 0.0; d["step_us_worst"] = us_max;
	d["standing"] = worst_standing;
	d["hash"] = (int64_t)(sim->state_hash() & 0x7fffffffffffffffULL);
	sim->cfg = keep;
	return d;
}

void CityTraffic::_bind_methods() {
	ClassDB::bind_method(D_METHOD("load_streets", "path"), &CityTraffic::load_streets);
	ClassDB::bind_method(D_METHOD("is_built"), &CityTraffic::is_built);
	ClassDB::bind_method(D_METHOD("street_stats"), &CityTraffic::street_stats);
	ClassDB::bind_method(D_METHOD("run_test", "cars", "minutes", "seed", "cam", "whole_city", "stuck_rule", "density"), &CityTraffic::run_test);
}

} // namespace godot
