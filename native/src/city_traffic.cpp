// CityTraffic: see city_traffic.h
#include "city_traffic.h"
#include <cstdlib>

#include "car_models.h"
#include "ped_places.h"
#include "traffic_sim.h"

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>

#include <algorithm>
#include <functional>
#include <queue>
#include <chrono>
#include <cmath>
#include <vector>

namespace godot {

CityTraffic::CityTraffic() {
	sim = new tc::Sim();
	route_sc = new tc::RouteScratch();
}

CityTraffic::~CityTraffic() {
	if (threaded) {   // (the node was freed without leaving the tree first)
		quit.store(true);
		if (worker.joinable()) worker.join();
	}
	delete sim;
	delete route_sc;
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
	// every junction's own start in the signal cycle: whole seconds from its clock tile (streets.sig_grid), so the lamps' shader can be
	// given exactly the same number (stage 2c)
	const int nn = (int)streets.node_i.size() / 4;
	std::vector<float> off(nn, 0.0f);
	for (int i = 0; i < nn; i++) {
		const int tx = streets.node_i[(size_t)i * 4 + 2], tz = streets.node_i[(size_t)i * 4 + 3];
		off[i] = (float)((((tx * 7 + tz * 13) % 30) + 30) % 30);
	}
	sim->set_signal_offsets(nn, off.data());
	ready = sim->build();
	parking.init(streets);
	if (ready) make_bus_lines();
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

Dictionary CityTraffic::run_test(int p_cars, double p_minutes, int64_t p_seed, const Vector3 &p_cam, bool p_whole_city, bool p_stuck_rule, double p_density, bool p_parking) {
	Dictionary d;
	if (!ready) { d["error"] = "no streets"; return d; }
	tc::Config keep = sim->cfg;
	sim->cfg.max_cars = std::min(p_cars, (int)tc::MAX_CARS);
	sim->cfg.max_bikes = cyclists;
	int bikes_most = 0;
	sim->cfg.hour_factor = 1.0f;
	sim->cfg.dens_scale = (float)p_density;
	sim->cfg.stuck_despawn_s = p_stuck_rule ? 60.0f : 1.0e9f;
	if (p_whole_city) {
		sim->cfg.spawn_r_in = 0.0f; sim->cfg.spawn_r_out = 2400.0f; sim->cfg.despawn_r = 5000.0f; sim->cfg.behind_despawn_r = 5000.0f;
		sim->cfg.view_safe_r = 0.0f; sim->cfg.tier_full_r = 6000.0f; sim->cfg.tier_mid_r = 7000.0f;
	}
	sim->reset_cars((uint64_t)p_seed);
	parking.init(streets); parking.rng = 0x9E3779B97F4A7C15ull ^ (uint64_t)p_seed; parking.on = p_parking;
	parking.set_cells(std::vector<uint8_t>(), true);
	int64_t ov_parked = 0;
	Array touch_cases;
	Array trace;
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
		parking.tick(*sim, dt);
		parking.events.clear();
		sim->set_dynamic((int)parking.dyn.size() / tc::DYN_STRIDE, parking.dyn.data());
		sim->set_time_of_day(std::fmod(clock, 86400.0));
		sim->step(dt, clock);
		clock += dt;
		sim->events.clear();
		if (debug_car >= 0) {   // the one car a failure named: where it is, where it aims, what it is doing, twice a second
			const int di = sim->find_car(debug_car);
			if (di >= 0 && t % 10 == 0 && trace.size() < 400)
				trace.push_back(vformat("t %.1f lane %d path %d s %.1f | aims %.2f is %.2f goal_lat %.2f | v %.1f steer %.2f yaw %.2f | kind %d pull %d man %d why %d arrived %d flags %d colour %d | stopped by %d lead %d | at (%.1f, %.1f) | refused %d by %d (%.1f)",
						clock, sim->lane[di], sim->conn[di], sim->s[di], sim->lat[di], sim->latm[di], sim->goal_lat[di], sim->v[di], sim->steer[di], sim->yaw[di], (int)sim->kind[di], (int)sim->pull[di], (int)sim->man[di], (int)sim->why[di],
						(int)sim->arrived[di], (int)sim->flags[di], (int)sim->colour[di], sim->veto_by[di], sim->lead_id[di], sim->x[di], sim->z[di], (int)sim->yinfo[di][0], (int)sim->yinfo[di][1], sim->yinfo[di][2]));
		}
		us_sum += sim->st.last_step_us; us_max = std::max(us_max, sim->st.last_step_us);
		alive_max = std::max(alive_max, sim->n_alive);
		bikes_most = std::max(bikes_most, sim->n_bikes);
		if (t % 20 == 0) {   // once a second of traffic time
			int a[3] = { 0, 0, 0 };
			sim->audit(a);
			ov_car += a[0]; ov_static += a[1]; ov_dyn += a[2]; checks++;
			if (p_parking) {
				const int nt = parking.audit(*sim);
				ov_parked += nt;
				int ti[6]; float tf[6];
				if (nt > 0 && touch_cases.size() < 8 && parking.touch_case(*sim, ti, tf))
					touch_cases.push_back(vformat("at %.0f s car %d (%s, manoeuvre %d, kind %d, why %d) touches the car in stall %d, %.1f m ahead: aims %.2f m beside its lane's middle, is %.2f m, the stall is %.2f m; speed %.1f; parked cars shown to the core as boxes this step: %.0f",
							clock, ti[0], ti[1] == 1 ? "parking" : (ti[1] == 2 ? "just pulled out" : "passing"), ti[2], ti[3], ti[5], ti[4], tf[3], tf[0], tf[1], tf[2], tf[4], tf[5]));
			}
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
	d["parking"] = p_parking; d["pulled_out"] = parking.pulled_out; d["parked"] = parking.parked; d["parking_gave_up"] = parking.gave_up; d["touching_parked"] = ov_parked;
	parking.init(streets); parking.on = true;
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
	d["touch_cases"] = touch_cases;
	d["worst_in_junction"] = vformat("at (%.0f, %.0f) at %.1f m/s, its line %.2f m beside the path's middle, path %d turn %d, a step of %.2f s, car %d", sim->st.worst_j[0], sim->st.worst_j[1], sim->st.worst_j[2], sim->st.worst_j[3], (int)sim->st.worst_j[4], (int)sim->st.worst_j[5], sim->st.worst_j[6], (int)sim->st.worst_j[7]);
	d["worst_over_edge"] = vformat("at (%.0f, %.0f) at %.1f m/s, %.1f m along lane %d of %.1f m, a step of %.2f s, car %d", sim->st.worst_o[0], sim->st.worst_o[1], sim->st.worst_o[2], sim->st.worst_o[3], (int)sim->st.worst_o[4], sim->st.worst_o[5], sim->st.worst_o[6], (int)sim->st.worst_o[7]);
	d["trace"] = trace;
	d["stalls_beside_a_lane"] = parking.n_lane_stalls; d["stalls_turned"] = parking.n_skewed; d["stalls_close_together"] = parking.n_close;
	d["stalls_cars_use"] = parking.n_usable;
	d["line_miss_mean"] = sim->st.trk_n > 0 ? sim->st.trk_sum / (double)sim->st.trk_n : 0.0; d["line_miss_lane"] = sim->st.trk_max; d["line_miss_holding"] = sim->st.trk_max_calm; d["line_miss_junction"] = sim->st.trk_max_junction;
	d["over_lane_edge"] = sim->st.lane_over_max; d["side_accel_most"] = sim->st.latacc_max; d["turn_a_step_most"] = sim->st.yaw_step_max;
	d["moves_at_full_lock"] = sim->st.steer_sat; d["body_moves"] = sim->st.trk_n; d["crept_round"] = sim->st.crawl_round;
	d["park_off_mean"] = parking.parked > 0 ? parking.park_off / parking.parked : 0.0; d["park_off_most"] = parking.park_off_max;
	d["park_yaw_mean_deg"] = parking.parked > 0 ? parking.park_yaw / parking.parked * 57.2958 : 0.0; d["park_yaw_most_deg"] = parking.park_yaw_max * 57.2958;
	d["bus_lines"] = (int)sim->routes.size(); d["buses_spawned"] = sim->st.buses_spawned; d["bus_stops_served"] = sim->st.bus_stops_served;
	d["bikes_down"] = sim->st.bikes_down;
	d["bikes_wanted"] = cyclists; d["bikes_most"] = bikes_most; d["bikes_spawned"] = sim->st.bikes_spawned; d["bike_squeezes"] = sim->st.bike_squeezes;
	d["routes_found"] = sim->routes_ok.load(); d["routes_failed"] = sim->routes_no.load(); d["reroutes"] = sim->st.reroutes;
	d["hash"] = (int64_t)(sim->state_hash() & 0x7fffffffffffffffULL);
	sim->cfg = keep;
	return d;
}

// The bus lines: made here from the map's own bus stops (places.bin), not written down anywhere, so a new bake's stops
// are served without anybody's hand. A line starts at a stop and goes on to the stop not yet served that the lanes
// reach soonest (of the six nearest), up to 14 stops or 5 km, and comes back to where it started: a loop. Up to three
// lines: the first from the stop in the middle of the map, the others from the stop farthest from every served one.
// The two sides of a street are two stops, so a line serves both directions on its way round.
void CityTraffic::make_bus_lines() {
	sim->routes.clear(); lines_info.clear();
	if (!buses_on || !ready) return;
	const PackedByteArray pb = FileAccess::get_file_as_bytes(places_path);
	pc::PlaceData pd;
	if (pb.size() < 12 || !pd.load(pb.ptr(), (size_t)pb.size())) return;
	struct Stop { int place, lane; float s, x, z; bool used; };
	std::vector<Stop> stops;
	for (int p = 0; p < (int)pd.places.size(); p++) {
		const pc::Place &P = pd.places[p];
		if (P.kind != pc::PL_BUS || P.lane < 0 || P.lane >= sim->n_lanes) continue;
		const int f = sim->l_flags[P.lane];
		if (!(f & tc::LF_DRIVE) || (f & (tc::LF_BLOCKED | tc::LF_DEADEND | tc::LF_EXIT | tc::LF_ROUNDABOUT)) || sim->p_len[P.lane] < 30.0f) continue;
		stops.push_back(Stop{ p, P.lane, std::min(std::max(P.lane_s, 12.0f), sim->p_len[P.lane] - 8.0f), P.ax, P.az, false });
	}
	if (stops.size() < 4) return;
	auto d2 = [&](int a, int b) { const float dx = stops[a].x - stops[b].x, dz = stops[a].z - stops[b].z; return dx * dx + dz * dz; };
	// the shortest way from one lane to another THROUGH JUNCTIONS ONLY, never by changing lanes: a bus that has to
	// change lanes between a stop at the kerb and a turn a few metres on does not always get across, and then stands
	// at the end of its lane for good (seen in the first run of tests/traffic/test_bus.gd). The core's route finder.
	auto conn_route = [&](int from, int to, std::vector<int32_t> &out) -> bool {
		return sim->find_route_ex(from, to, tc::RO_NO_LANE_CHANGE | tc::RO_NO_DEADEND | tc::RO_NO_EXIT, *route_sc, out);
	};
	// metres along the lanes from one stop to another (-1: no way, or it is behind on the same lane)
	auto way = [&](int a, int b, std::vector<int32_t> &out) -> float {
		const int la = stops[a].lane, lb = stops[b].lane;
		if (la == lb) { out.assign(1, la); return stops[b].s - stops[a].s > 25.0f ? stops[b].s - stops[a].s : -1.0f; }
		if (!conn_route(la, lb, out) || out.size() < 2) return -1.0f;
		float m = sim->p_len[la] - stops[a].s + stops[b].s;
		for (size_t k = 1; k + 1 < out.size(); k++) m += sim->p_len[out[k]];
		return m;
	};
	float cx = 0.0f, cz = 0.0f;
	for (const Stop &st : stops) { cx += st.x; cz += st.z; }
	cx /= (float)stops.size(); cz /= (float)stops.size();
	float tph[24];
	for (int h = 0; h < 24; h++) tph[h] = 12.0f;
	for (int line = 0; line < 3; line++) {
		int start = -1, left = 0; float best = line == 0 ? 1e18f : -1.0f;
		for (int j = 0; j < (int)stops.size(); j++) {
			if (stops[j].used) continue;
			left++;
			float d = 1e18f;
			if (line == 0) d = (stops[j].x - cx) * (stops[j].x - cx) + (stops[j].z - cz) * (stops[j].z - cz);
			else for (int k = 0; k < (int)stops.size(); k++) if (stops[k].used) d = std::min(d, d2(j, k));
			if (line == 0 ? d < best : d > best) { best = d; start = j; }
		}
		if (start < 0 || left < 4) break;
		std::vector<int32_t> lanes{ stops[start].lane }, ri{ 0 }, tags{ stops[start].place };
		std::vector<float> ss{ stops[start].s };
		stops[start].used = true;
		int cur = start, members = 1; float total = 0.0f;
		std::vector<int32_t> path, bpath;
		while (members < 14 && total < 5000.0f) {
			std::vector<std::pair<float, int>> near_;
			for (int j = 0; j < (int)stops.size(); j++) if (!stops[j].used) near_.push_back({ d2(cur, j), j });
			std::sort(near_.begin(), near_.end());
			int pick = -1; float pm = 1500.0f;
			for (int k = 0; k < std::min(6, (int)near_.size()); k++) {
				const float m = way(cur, near_[k].second, path);
				if (m > 60.0f && m < pm) { pm = m; pick = near_[k].second; bpath = path; }
			}
			if (pick < 0) break;
			for (size_t k = 1; k < bpath.size(); k++) lanes.push_back(bpath[k]);
			ri.push_back((int32_t)lanes.size() - 1); ss.push_back(stops[pick].s); tags.push_back(stops[pick].place);
			stops[pick].used = true; members++; cur = pick; total += pm;
		}
		bool loop = false;
		if (cur != start) {   // back to where it started
			const float m = way(cur, start, path);
			if (m > 0.0f && path.size() >= 2) {
				for (size_t k = 1; k < path.size(); k++) lanes.push_back(path[k]);
				ri.push_back((int32_t)lanes.size() - 1); ss.push_back(stops[start].s); tags.push_back(stops[start].place);
				total += m; loop = true;
			}
		}
		if (members < 3) continue;
		const int r = sim->add_route(lanes.data(), (int)lanes.size(), ri.data(), ss.data(), (int)ri.size(), tph, bus_model);
		if (r < 0) continue;
		tc::Sim::Route &R = sim->routes[r];
		if (R.stop_ri.size() != tags.size()) { sim->routes.pop_back(); continue; }
		R.stop_tag = tags; R.loop = (loop && R.lanes.front() == R.lanes.back()) ? 1 : 0;
		LineInfo li; li.stops = members; li.metres = R.length; li.loop = R.loop != 0; li.places = tags;
		lines_info.push_back(li);
	}
}

Array CityTraffic::bus_lines() const {
	Array out;
	for (const LineInfo &li : lines_info) {
		Dictionary d; d["stops"] = li.stops; d["metres"] = li.metres; d["loop"] = li.loop;
		PackedInt32Array pl; for (int32_t p : li.places) pl.push_back(p);
		d["places"] = pl;
		out.push_back(d);
	}
	return out;
}

void CityTraffic::set_bus_tph(double p_tph) {
	bus_tph = p_tph;
	std::lock_guard<std::mutex> lock(mx);
	input.bus_tph = (float)p_tph;
}

void CityTraffic::set_hour(double p_hour) {
	hour = p_hour;
	std::lock_guard<std::mutex> lock(mx);
	input.hour = (float)p_hour;
}

// ---------------------------------------------------------------- the way on the map, the game's own cars
Dictionary CityTraffic::route(const Vector3 &p_from, const Vector3 &p_to, bool p_bike) const {
	Dictionary d;
	d["ok"] = false; d["metres"] = -1.0;
	if (!ready) return d;
	std::vector<int32_t> lanes;
	std::vector<float> pts;
	const auto t0 = std::chrono::steady_clock::now();
	float m = sim->route_points(p_from.x, p_from.z, p_to.x, p_to.z, p_bike ? tc::RO_BIKE : tc::RO_NO_EXIT, *route_sc, lanes, &pts);
	d["car_roads"] = !p_bike;
	if (m < 0.0f && p_bike) {   // no way a bike rides (the fast roads, the bridge): the way by the car roads, and it says so
		m = sim->route_points(p_from.x, p_from.z, p_to.x, p_to.z, tc::RO_NO_EXIT, *route_sc, lanes, &pts);
		d["car_roads"] = true;
	}
	d["us"] = (double)std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::steady_clock::now() - t0).count();
	d["searched"] = route_sc->expanded;
	if (m < 0.0f) return d;
	PackedVector3Array pv;
	pv.resize((int64_t)pts.size() / 3);
	for (int64_t k = 0; k < pv.size(); k++) pv.set(k, Vector3(pts[k * 3], pts[k * 3 + 1], pts[k * 3 + 2]));
	PackedInt32Array pl;
	for (int32_t l : lanes) pl.push_back(l);
	d["ok"] = true; d["metres"] = m; d["points"] = pv; d["lanes"] = pl;
	return d;
}

PackedVector2Array CityTraffic::map_lines() const {
	PackedVector2Array out;
	if (!ready) return out;
	for (int pc = 0; pc < sim->n_pieces; pc++) {
		if (pc < sim->n_lanes && !(sim->l_flags[pc] & tc::LF_DRIVE)) continue;
		const int o = sim->p_off[pc], n = sim->p_n[pc];
		for (int k = 0; k + 1 < n; k++) { out.push_back(Vector2(sim->ptx[o + k], sim->ptz[o + k])); out.push_back(Vector2(sim->ptx[o + k + 1], sim->ptz[o + k + 1])); }
	}
	return out;
}

PackedVector3Array CityTraffic::lane_points(double p_step) const {
	PackedVector3Array out;
	if (!ready) return out;
	const float step = std::max((float)p_step, 0.25f);
	for (int pc = 0; pc < sim->n_pieces; pc++) {
		if (pc < sim->n_lanes && !(sim->l_flags[pc] & tc::LF_DRIVE)) continue;
		const int o = sim->p_off[pc], n = sim->p_n[pc];
		for (int k = 0; k + 1 < n; k++) {
			const float x0 = sim->ptx[o + k], y0 = sim->pty[o + k], z0 = sim->ptz[o + k];
			const float dx = sim->ptx[o + k + 1] - x0, dy = sim->pty[o + k + 1] - y0, dz = sim->ptz[o + k + 1] - z0;
			const float len = std::sqrt(dx * dx + dz * dz);
			const int m = std::max(1, (int)(len / step));
			for (int q = 0; q < m; q++) { const float u = (float)q / (float)m; out.push_back(Vector3(x0 + dx * u, y0 + dy * u, z0 + dz * u)); }
		}
	}
	return out;
}

PackedVector3Array CityTraffic::lane_points_across(double p_step, double p_half, double p_across) const {
	PackedVector3Array out;
	if (!ready) return out;
	const float step = std::max((float)p_step, 0.25f), half = std::max((float)p_half, 0.0f), across = std::max((float)p_across, 0.1f);
	const int na = std::max(1, (int)std::ceil(2.0f * half / across));
	for (int pc = 0; pc < sim->n_pieces; pc++) {
		if (pc < sim->n_lanes && !(sim->l_flags[pc] & tc::LF_DRIVE)) continue;
		const int o = sim->p_off[pc], n = sim->p_n[pc];
		for (int k = 0; k + 1 < n; k++) {
			const float x0 = sim->ptx[o + k], y0 = sim->pty[o + k], z0 = sim->ptz[o + k];
			const float dx = sim->ptx[o + k + 1] - x0, dy = sim->pty[o + k + 1] - y0, dz = sim->ptz[o + k + 1] - z0;
			const float len = std::sqrt(dx * dx + dz * dz);
			if (len < 1.0e-5f) continue;
			const float sx = dz / len, sz = -dx / len;   // across the lane
			const int m = std::max(1, (int)(len / step));
			for (int q = 0; q < m; q++) {
				const float u = (float)q / (float)m;
				for (int a = 0; a <= na; a++) {
					const float l = -half + 2.0f * half * (float)a / (float)na;
					out.push_back(Vector3(x0 + dx * u + sx * l, y0 + dy * u, z0 + dz * u + sz * l));
				}
			}
		}
	}
	return out;
}

int CityTraffic::exec_order(const Input::Order &o) {
	switch (o.type) {
		case O_SPAWN: { const int id = sim->spawn_scripted(o.model, o.ax, o.az, o.bx, o.bz, false); return id >= 0 ? id : -1; }
		case O_DRIVE: return sim->drive_to(o.car, o.bx, o.bz) ? 1 : -1;
		case O_PULL: return sim->pull_over(o.car, o.bx, o.bz, o.side) ? 1 : -1;
		case O_RELEASE: return sim->release_car(o.car) ? 1 : -1;
		default: return -1;
	}
}

int CityTraffic::spawn_driver(const Vector3 &p_from, const Vector3 &p_to, int p_model) {
	Input::Order o{ O_SPAWN, next_ticket++, -1, p_from.x, p_from.z, p_to.x, p_to.z, 0, p_model };
	if (!threaded) { answers.push_back({ o.ticket, ready ? exec_order(o) : -1 }); return o.ticket; }
	std::lock_guard<std::mutex> lock(mx);
	input.orders.push_back(o);
	return o.ticket;
}
int CityTraffic::drive_car_to(int p_car, const Vector3 &p_to) {
	Input::Order o{ O_DRIVE, next_ticket++, p_car, 0, 0, p_to.x, p_to.z, 0, 0 };
	if (!threaded) { answers.push_back({ o.ticket, ready ? exec_order(o) : -1 }); return o.ticket; }
	std::lock_guard<std::mutex> lock(mx);
	input.orders.push_back(o);
	return o.ticket;
}
int CityTraffic::pull_car_over(int p_car, const Vector3 &p_to, int p_side) {
	Input::Order o{ O_PULL, next_ticket++, p_car, 0, 0, p_to.x, p_to.z, p_side, 0 };
	if (!threaded) { answers.push_back({ o.ticket, ready ? exec_order(o) : -1 }); return o.ticket; }
	std::lock_guard<std::mutex> lock(mx);
	input.orders.push_back(o);
	return o.ticket;
}
int CityTraffic::let_car_go(int p_car) {
	Input::Order o{ O_RELEASE, next_ticket++, p_car, 0, 0, 0, 0, 0, 0 };
	if (!threaded) { answers.push_back({ o.ticket, ready ? exec_order(o) : -1 }); return o.ticket; }
	std::lock_guard<std::mutex> lock(mx);
	input.orders.push_back(o);
	return o.ticket;
}
void CityTraffic::panic(const Vector3 &p_at, double p_radius, double p_seconds) {
	(void)p_seconds;
	if (!threaded) {
		if (!ready || !sim) return;
		const float r2 = (float)(p_radius * p_radius);
		for (int i = 0; i < sim->hi; i++) {
			if (!sim->alive[i] || sim->kind[i] != tc::K_AMBIENT) continue;
			const float dx = sim->x[i] - (float)p_at.x, dz = sim->z[i] - (float)p_at.z;
			if (dx * dx + dz * dz <= r2 && sim->temper[i] != 2) { sim->temper[i] = 2; panicked++; }
		}
		return;
	}
	std::lock_guard<std::mutex> lock(mx);
	input.panics.push_back((float)p_at.x); input.panics.push_back((float)p_at.z); input.panics.push_back((float)p_radius);
}
int CityTraffic::order_result(int p_ticket) {
	if (threaded) {
		std::lock_guard<std::mutex> lock(mx);
		answers.insert(answers.end(), order_done.begin(), order_done.end());
		order_done.clear();
	}
	for (size_t k = 0; k < answers.size(); k++) {
		if (answers[k].first != p_ticket) continue;
		const int r = answers[k].second;
		answers.erase(answers.begin() + (long)k);
		return r;
	}
	return -9;
}

void CityTraffic::_bind_methods() {
	ClassDB::bind_method(D_METHOD("load_streets", "path"), &CityTraffic::load_streets);
	ClassDB::bind_method(D_METHOD("attach", "streamer"), &CityTraffic::attach);
	ClassDB::bind_method(D_METHOD("_on_cell_in", "key"), &CityTraffic::_on_cell_in);
	ClassDB::bind_method(D_METHOD("_on_cell_out", "key"), &CityTraffic::_on_cell_out);
	ClassDB::bind_method(D_METHOD("report"), &CityTraffic::report);
	ClassDB::bind_method(D_METHOD("set_player_car", "car", "half_len", "half_w"), &CityTraffic::set_player_car);
	ClassDB::bind_method(D_METHOD("map_lines"), &CityTraffic::map_lines);
	ClassDB::bind_method(D_METHOD("set_max_cars", "n"), &CityTraffic::set_max_cars);
	ClassDB::bind_method(D_METHOD("get_max_cars"), &CityTraffic::get_max_cars);
	ClassDB::bind_method(D_METHOD("set_parked", "on"), &CityTraffic::set_parked);
	ClassDB::bind_method(D_METHOD("get_parked"), &CityTraffic::get_parked);
	ClassDB::bind_method(D_METHOD("set_density", "scale"), &CityTraffic::set_density);
	ClassDB::bind_method(D_METHOD("get_density"), &CityTraffic::get_density);
	ClassDB::bind_method(D_METHOD("set_shadows", "on"), &CityTraffic::set_shadows);
	ClassDB::bind_method(D_METHOD("get_shadows"), &CityTraffic::get_shadows);
	ClassDB::bind_method(D_METHOD("set_bodies", "on"), &CityTraffic::set_bodies);
	ClassDB::bind_method(D_METHOD("get_bodies"), &CityTraffic::get_bodies);
	ClassDB::bind_method(D_METHOD("set_night", "night"), &CityTraffic::set_night);
	ClassDB::bind_method(D_METHOD("get_night"), &CityTraffic::get_night);
	ClassDB::bind_method(D_METHOD("set_streets_path", "path"), &CityTraffic::set_streets_path);
	ClassDB::bind_method(D_METHOD("get_streets_path"), &CityTraffic::get_streets_path);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "max_cars"), "set_max_cars", "get_max_cars");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "parked"), "set_parked", "get_parked");
	ClassDB::bind_method(D_METHOD("set_buses", "on"), &CityTraffic::set_buses);
	ClassDB::bind_method(D_METHOD("get_buses"), &CityTraffic::get_buses);
	ClassDB::bind_method(D_METHOD("set_places_path", "path"), &CityTraffic::set_places_path);
	ClassDB::bind_method(D_METHOD("get_places_path"), &CityTraffic::get_places_path);
	ClassDB::bind_method(D_METHOD("set_bus_model", "model"), &CityTraffic::set_bus_model);
	ClassDB::bind_method(D_METHOD("get_bus_model"), &CityTraffic::get_bus_model);
	ClassDB::bind_method(D_METHOD("set_hour", "hour"), &CityTraffic::set_hour);
	ClassDB::bind_method(D_METHOD("get_hour"), &CityTraffic::get_hour);
	ClassDB::bind_method(D_METHOD("make_bus_lines"), &CityTraffic::make_bus_lines);
	ClassDB::bind_method(D_METHOD("bus_lines"), &CityTraffic::bus_lines);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "buses"), "set_buses", "get_buses");
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "places_path"), "set_places_path", "get_places_path");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "bus_model"), "set_bus_model", "get_bus_model");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "hour"), "set_hour", "get_hour");
	ClassDB::bind_method(D_METHOD("set_bus_tph", "buses_an_hour"), &CityTraffic::set_bus_tph);
	ClassDB::bind_method(D_METHOD("get_bus_tph"), &CityTraffic::get_bus_tph);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "bus_tph"), "set_bus_tph", "get_bus_tph");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "density"), "set_density", "get_density");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "shadows"), "set_shadows", "get_shadows");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "bodies"), "set_bodies", "get_bodies");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "night"), "set_night", "get_night");
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "streets_path"), "set_streets_path", "get_streets_path");
	ClassDB::bind_method(D_METHOD("set_debug_car", "id"), &CityTraffic::set_debug_car);
	ClassDB::bind_method(D_METHOD("get_debug_car"), &CityTraffic::get_debug_car);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "debug_car"), "set_debug_car", "get_debug_car");
	ClassDB::bind_method(D_METHOD("set_knock", "on"), &CityTraffic::set_knock);
	ClassDB::bind_method(D_METHOD("get_knock"), &CityTraffic::get_knock);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "knock"), "set_knock", "get_knock");
	ClassDB::bind_method(D_METHOD("set_knock_feel", "feel"), &CityTraffic::set_knock_feel);
	ClassDB::bind_method(D_METHOD("get_knock_feel"), &CityTraffic::get_knock_feel);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "knock_feel"), "set_knock_feel", "get_knock_feel");
	ClassDB::bind_method(D_METHOD("cars_near", "at", "radius"), &CityTraffic::cars_near);
	ClassDB::bind_method(D_METHOD("route", "from", "to", "bike"), &CityTraffic::route, DEFVAL(false));
	ClassDB::bind_method(D_METHOD("spawn_driver", "from", "to", "model"), &CityTraffic::spawn_driver);
	ClassDB::bind_method(D_METHOD("drive_car_to", "car", "to"), &CityTraffic::drive_car_to);
	ClassDB::bind_method(D_METHOD("pull_car_over", "car", "to", "side"), &CityTraffic::pull_car_over);
	ClassDB::bind_method(D_METHOD("panic", "at", "radius", "seconds"), &CityTraffic::panic);
	ClassDB::bind_method(D_METHOD("let_car_go", "car"), &CityTraffic::let_car_go);
	ClassDB::bind_method(D_METHOD("order_result", "ticket"), &CityTraffic::order_result);
	ClassDB::bind_method(D_METHOD("bike_stats"), &CityTraffic::bike_stats);
	ClassDB::bind_method(D_METHOD("lane_points", "step"), &CityTraffic::lane_points);
	ClassDB::bind_method(D_METHOD("lane_points_across", "step", "half", "across"), &CityTraffic::lane_points_across);
	ClassDB::bind_method(D_METHOD("set_cyclists", "n"), &CityTraffic::set_cyclists);
	ClassDB::bind_method(D_METHOD("get_cyclists"), &CityTraffic::get_cyclists);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "cyclists"), "set_cyclists", "get_cyclists");
	ClassDB::bind_method(D_METHOD("stalls_near", "at", "radius"), &CityTraffic::stalls_near);
	ClassDB::bind_method(D_METHOD("knock_stats"), &CityTraffic::knock_stats);
	ClassDB::bind_method(D_METHOD("is_built"), &CityTraffic::is_built);
	ClassDB::bind_method(D_METHOD("street_stats"), &CityTraffic::street_stats);
	ClassDB::bind_method(D_METHOD("run_test", "cars", "minutes", "seed", "cam", "whole_city", "stuck_rule", "density", "parking"), &CityTraffic::run_test, DEFVAL(false));
}

} // namespace godot
