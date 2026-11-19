// traffic2: routed cars. Buses follow a timetable route (data/traffic/transit.json lanes) and dwell at their stops;
// scripted cars (CityRide) get a route to a kerb point and stop there. A route is a list of lanes; two consecutive
// lanes are joined by a junction connector or are neighbours on one road (a lane change on the way).
#include "traffic_sim.h"

#include <algorithm>
#include <cmath>
#include <queue>

namespace tc {

namespace {
inline float clampf(float v, float a, float b) { return v < a ? a : (v > b ? b : v); }
}

static int sibling_side(const Sim &S, int from, int to) {   // +1: `to` is to the left of `from`, -1 right, 0 neither
	for (int l = S.l_left[from], g = 0; l >= 0 && g < 8; l = S.l_left[l], g++) if (l == to) return 1;
	for (int l = S.l_right[from], g = 0; l >= 0 && g < 8; l = S.l_right[l], g++) if (l == to) return -1;
	return 0;
}

static int conn_between(const Sim &S, int from, int to) {
	for (int k = S.l_out_off[from]; k < S.l_out_off[from] + S.l_out_n[from]; k++) {
		int c = S.out_conn[k];
		if (S.c_to[c] == to && !S.p_blocked[S.n_lanes + c]) return c;
	}
	return -1;
}

// Dijkstra on lanes: a junction move costs the lane + connector length, a lane change 25 m (only on lanes long enough
// to change on). Lanes closed by parked boxes or not public are only used as start or goal.
bool Sim::find_route(int from, int to, std::vector<int32_t> &out) const {
	out.clear();
	if (from < 0 || to < 0 || from >= n_lanes || to >= n_lanes) return false;
	if (from == to) { out.push_back(from); return true; }
	std::vector<float> dist(n_lanes, BIG);
	std::vector<int32_t> prev(n_lanes, -1);
	typedef std::pair<float, int32_t> QE;
	std::priority_queue<QE, std::vector<QE>, std::greater<QE>> q;
	dist[from] = 0.0f;
	q.push(QE(0.0f, from));
	int expanded = 0;
	auto usable = [&](int l) { return l == to || ((l_flags[l] & LF_DRIVE) && !(l_flags[l] & LF_BLOCKED)); };
	while (!q.empty()) {
		QE e = q.top(); q.pop();
		int l = e.second;
		if (e.first > dist[l]) continue;
		if (l == to) break;
		if (++expanded > 60000) break;
		for (int k = l_out_off[l]; k < l_out_off[l] + l_out_n[l]; k++) {
			int c = out_conn[k], t = c_to[c];
			if (p_blocked[n_lanes + c] || !usable(t)) continue;
			float nd_ = e.first + p_len[l] + p_len[n_lanes + c] + (c_turn[c] == T_LEFT ? 12.0f : (c_turn[c] == T_UTURN ? 80.0f : 0.0f));
			if (nd_ < dist[t]) { dist[t] = nd_; prev[t] = l; q.push(QE(nd_, t)); }
		}
		if (p_len[l] > 40.0f) {
			int nb[2] = { l_left[l], l_right[l] };
			for (int t : nb) {
				if (t < 0 || !usable(t)) continue;
				float nd_ = e.first + 25.0f;
				if (nd_ < dist[t]) { dist[t] = nd_; prev[t] = l; q.push(QE(nd_, t)); }
			}
		}
	}
	if (dist[to] >= BIG * 0.5f) return false;
	for (int l = to; l >= 0; l = prev[l]) { out.push_back(l); if (l == from) break; }
	std::reverse(out.begin(), out.end());
	return !out.empty() && out[0] == from;
}

// Next connector for car i at the end of lane_. Ambient cars choose freely; routed cars take the connector to their
// next route lane, or ask for a lane change (lc_need) and stop at the lane end until it is done.
int Sim::pick_routed(int i, int lane_) {
	lc_need[i] = 0;
	if (kind[i] == K_AMBIENT || rt[i].empty()) return pick_next(lane_);
	const std::vector<int32_t> &r = rt[i];
	int ri = rt_i[i];
	if (ri < 0 || ri >= (int)r.size() || r[ri] != lane_) {   // off the route (should not happen): find our lane in it
		ri = -1;
		for (int k = 0; k < (int)r.size(); k++) if (r[k] == lane_) { ri = k; break; }
		if (ri < 0) { rt[i].clear(); goal_ri[i] = -1; return pick_next(lane_); }
		rt_i[i] = ri;
	}
	if (ri + 1 >= (int)r.size()) return -1;   // route end
	int nx = r[ri + 1];
	int side = sibling_side(*this, lane_, nx);
	if (side != 0) { lc_need[i] = (int8_t)side; return -1; }
	int c = conn_between(*this, lane_, nx);
	if (c >= 0) return c;
	// the route does not fit the lane graph here: route again from this lane to the route's last lane
	std::vector<int32_t> nr;
	int last = r.back();
	int gl = goal_ri[i] >= 0 ? r[goal_ri[i]] : -1;
	if (find_route(lane_, last, nr) && nr.size() >= 2) {
		st.reroutes++;
		rt[i] = nr; rt_i[i] = 0;
		if (gl >= 0) { goal_ri[i] = -1; for (int k = 0; k < (int)nr.size(); k++) if (nr[k] == gl) { goal_ri[i] = k; break; } }
		return pick_routed(i, lane_);
	}
	rt[i].clear(); goal_ri[i] = -1;
	return pick_next(lane_);
}

int Sim::peek_routed(int i, int after_lane) {
	const std::vector<int32_t> &r = rt[i];
	for (int k = std::max(rt_i[i], 0); k + 1 < (int)r.size(); k++) {
		if (r[k] != after_lane) continue;
		return conn_between(*this, after_lane, r[k + 1]);   // -1 also when a lane change is needed there (no chaining)
	}
	return -1;
}

int Sim::spawn_routed(int kind_, int model_, const std::vector<int32_t> &route, int ri, float s_, float speed) {
	if (route.empty() || ri < 0 || ri >= (int)route.size()) return -1;
	int i = place_car(route[ri], s_, speed, model_, 1);
	if (i < 0) return -1;
	if (blocked_by(i, x[i], y[i], z[i], fx[i], fz[i], 0.3f)) { alive[i] = 0; n_alive--; while (hi > 0 && !alive[hi - 1]) hi--; return -1; }
	kind[i] = (uint8_t)kind_;
	rt[i] = route; rt_i[i] = ri;
	nconn[i] = pick_routed(i, route[ri]);
	return i;
}

// nearest public driving lane to a point; s on it
static int nearest_drive_lane(const Sim &S, float qx, float qz, float max_d, float &out_s) {
	int best = -1;
	float bd = max_d * max_d, bs = 0.0f;
	int cx0 = std::max(0, (int)((qx - max_d - S.gx0) / S.GC)), cx1 = std::min(S.gw - 1, (int)((qx + max_d - S.gx0) / S.GC));
	int cz0 = std::max(0, (int)((qz - max_d - S.gz0) / S.GC)), cz1 = std::min(S.gh - 1, (int)((qz + max_d - S.gz0) / S.GC));
	for (int cz = cz0; cz <= cz1; cz++) {
		for (int cx = cx0; cx <= cx1; cx++) {
			int c = cz * S.gw + cx;
			for (int e = S.sg_off[c]; e < S.sg_off[c + 1]; e++) {
				int L = S.sg_piece[e];
				if (L >= S.n_lanes || !(S.l_flags[L] & LF_DRIVE) || (S.l_flags[L] & LF_BLOCKED)) continue;
				int q = S.p_off[L] + S.sg_pt[e];
				float ux = S.ptx[q + 1] - S.ptx[q], uz = S.ptz[q + 1] - S.ptz[q];
				float l2 = ux * ux + uz * uz;
				float t = l2 > 1e-10f ? clampf(((qx - S.ptx[q]) * ux + (qz - S.ptz[q]) * uz) / l2, 0.0f, 1.0f) : 0.0f;
				float dx = qx - (S.ptx[q] + ux * t), dz = qz - (S.ptz[q] + uz * t);
				float d2 = dx * dx + dz * dz;
				if (d2 < bd) { bd = d2; best = L; bs = S.ptc[q] + (S.ptc[q + 1] - S.ptc[q]) * t; }
			}
		}
	}
	out_s = bs;
	return best;
}

// route from (lane a, s_a) to (lane b, s_b): when both are the same lane and the goal is behind, go round the block
static bool route_to(Sim &S, int a, float sa, int b, float sb, std::vector<int32_t> &out) {
	if (a != b || sb > sa + 2.0f) return S.find_route(a, b, out);
	float best = BIG;
	std::vector<int32_t> tmp;
	for (int k = S.l_out_off[a]; k < S.l_out_off[a] + S.l_out_n[a]; k++) {
		int c = S.out_conn[k];
		if (S.p_blocked[S.n_lanes + c]) continue;
		if (!S.find_route(S.c_to[c], b, tmp)) continue;
		float L = 0.0f;
		for (int l : tmp) L += S.p_len[l];
		if (L < best) { best = L; out.clear(); out.push_back(a); out.insert(out.end(), tmp.begin(), tmp.end()); }
	}
	return best < BIG;
}

int Sim::spawn_scripted(int model_, float fx_, float fz_, float tx, float tz, bool hidden) {
	if (!built) return -1;
	float sa, sb;
	int a = nearest_drive_lane(*this, fx_, fz_, 30.0f, sa), b = nearest_drive_lane(*this, tx, tz, 40.0f, sb);
	if (a < 0 || b < 0) return -1;
	std::vector<int32_t> r;
	if (!route_to(*this, a, sa, b, sb, r)) return -1;
	sa = clampf(sa, 2.5f, std::max(p_len[a] - 2.5f, 2.6f));
	int i = place_car(a, sa, 0.0f, model_, 1);
	if (i < 0) return -1;
	if (hidden && in_cone(x[i], z[i])) {
		float dx = x[i] - cam_x, dz = z[i] - cam_z;
		if (dx * dx + dz * dz < cfg.view_safe_r * cfg.view_safe_r) { alive[i] = 0; n_alive--; while (hi > 0 && !alive[hi - 1]) hi--; return -1; }
	}
	if (blocked_by(i, x[i], y[i], z[i], fx[i], fz[i], 0.2f)) { alive[i] = 0; n_alive--; while (hi > 0 && !alive[hi - 1]) hi--; return -1; }
	kind[i] = K_SCRIPTED; tier[i] = TIER_FULL;
	rt[i] = r; rt_i[i] = 0;
	goal_ri[i] = (int32_t)r.size() - 1; goal_s[i] = clampf(sb, hl[i] + 0.5f, p_len[b] - 0.5f); goal_lat[i] = 0.0f; pull[i] = 0;
	nconn[i] = pick_routed(i, a);
	st.spawned++;
	event(E_SPAWN, i, (float)a);
	return id[i];
}

bool Sim::drive_to(int car_id, float tx, float tz) {
	int i = find_car(car_id);
	if (i < 0) return false;
	float sb;
	int b = nearest_drive_lane(*this, tx, tz, 40.0f, sb);
	if (b < 0) return false;
	int a = lane[i];
	float sa = conn[i] >= 0 ? 0.0f : s[i];
	std::vector<int32_t> r;
	if (!route_to(*this, a, sa, b, sb, r)) return false;
	if (flags[i] & F_RES) revoke(i);
	kind[i] = K_SCRIPTED; tier[i] = TIER_FULL;
	rt[i] = r; rt_i[i] = 0;
	goal_ri[i] = (int32_t)r.size() - 1; goal_s[i] = clampf(sb, hl[i] + 0.5f, p_len[b] - 0.5f); goal_lat[i] = 0.0f; pull[i] = 0;
	arrived[i] = 0; dwell[i] = 0.0f; lc_stuck[i] = 0.0f;
	nconn[i] = pick_routed(i, a);
	return true;
}

// Stop at the kerb beside the goal: side 1 = the right kerb, -1 = the left one
bool Sim::pull_over(int car_id, float tx, float tz, int side) {
	int i = find_car(car_id);
	if (i < 0) return false;
	if (goal_ri[i] < 0 && !drive_to(car_id, tx, tz)) return false;
	int gl = rt[i][goal_ri[i]];
	float off = std::max(p_hw[gl] - hw[i], 0.0f) + 0.45f;
	goal_lat[i] = side >= 0 ? -off : off;
	pull[i] = 1;
	return true;
}

// An ambient car parks: its goal is a place on the lane it is on, beside which a free stall lies.
bool Sim::park_at(int car_id, float s_goal, float lat_goal, float pull_d_) {
	int i = find_car(car_id);
	if (i < 0 || kind[i] != K_AMBIENT || conn[i] >= 0 || (flags[i] & F_RES)) return false;
	if (s_goal < s[i] + 20.0f || s_goal > p_len[lane[i]] - 5.0f) return false;
	kind[i] = K_SCRIPTED;
	rt[i].assign(1, lane[i]); rt_i[i] = 0;
	goal_ri[i] = 0; goal_s[i] = s_goal; goal_lat[i] = lat_goal; pull[i] = 1; pull_d[i] = pull_d_;
	arrived[i] = 0; dwell[i] = 0.0f; lc_stuck[i] = 0.0f; lc_need[i] = 0;
	nconn[i] = -1;   // (it stops on this lane)
	return true;
}

// A parked car pulls out: a car standing beside lane_ at s_ (lat_ off its middle); it drives off and into the lane
// as the sideways rules of the core let it. -1 = no room in the pool.
int Sim::unpark(int lane_, float s_, float lat_, int model_, int temper_) {
	int i = place_car(lane_, s_, 0.0f, model_, temper_);
	if (i < 0) return -1;
	lat[i] = lat_; latv[i] = 0.0f;
	float o[7];
	pose_at(lane_, s[i], lat[i], 0.0f, 0.0f, 1.0f, seg[i], o);
	x[i] = px[i] = o[0]; y[i] = py[i] = o[1]; z[i] = pz[i] = o[2]; fx[i] = o[3]; fz[i] = o[4]; pitch[i] = ppitch[i] = o[5]; yaw[i] = pyaw[i] = o[6];
	latm[i] = lat[i]; rpitch[i] = o[5];
	out_lat0[i] = lat_; out_d[i] = 0.0f; calm[i] = 0.0f;
	st.spawned++;
	event(E_SPAWN, i, (float)lane_);
	return i;
}

bool Sim::release_car(int car_id) {
	int i = find_car(car_id);
	if (i < 0) return false;
	kind[i] = K_AMBIENT; rt[i].clear(); goal_ri[i] = -1; pull[i] = 0; arrived[i] = 0; lc_need[i] = 0; dwell[i] = 0.0f; out_lat0[i] = 0.0f;
	if (!(flags[i] & F_RES)) nconn[i] = pick_next(lane[i]);
	return true;
}

bool Sim::set_hold(int car_id, bool on) {
	int i = find_car(car_id);
	if (i < 0) return false;
	hold_[i] = on ? 1 : 0;
	if (on) { v[i] = 0.0f; arrived[i] = 1; }
	return true;
}

// the car's sideways place in its lane (+ = left of travel), e.g. at the kerb after a teleport
bool Sim::set_kerb_lat(int car_id, float lat_) {
	int i = find_car(car_id);
	if (i < 0) return false;
	lat[i] = lat_; goal_lat[i] = lat_; pull[i] = 1; latv[i] = 0.0f;
	int p = conn[i] >= 0 ? n_lanes + conn[i] : lane[i];
	float o[7];
	pose_at(p, s[i], lat[i], 0.0f, fx[i], fz[i], seg[i], o);
	x[i] = px[i] = o[0]; y[i] = py[i] = o[1]; z[i] = pz[i] = o[2]; fx[i] = o[3]; fz[i] = o[4]; pitch[i] = ppitch[i] = o[5]; yaw[i] = pyaw[i] = o[6];
	latm[i] = lat[i]; rpitch[i] = o[5]; steer[i] = 0.0f;
	return true;
}

// put a car somewhere else (scene cuts): no reservations, standing, route = just this lane until drive_to
bool Sim::teleport_car(int car_id, int lane_, float s_) {
	int i = find_car(car_id);
	if (i < 0 || lane_ < 0 || lane_ >= n_lanes) return false;
	release_all(i);
	lane[i] = lane_; conn[i] = -1; seg[i] = 0; line_passed[i] = 0; stop_tick[i] = -1;
	s[i] = clampf(s_, 0.0f, p_len[lane_] - 0.01f); lat[i] = 0.0f; latv[i] = 0.0f; hoff[i] = 0.0f; v[i] = 0.0f; acc[i] = 0.0f;
	man[i] = MAN_NONE; lc_need[i] = 0; wait_t[i] = 0.0f; crash_t[i] = 0.0f;
	if (kind[i] != K_AMBIENT) { rt[i].assign(1, lane_); rt_i[i] = 0; goal_ri[i] = -1; }
	nconn[i] = pick_routed(i, lane_);
	float o[7];
	pose_at(lane_, s[i], 0.0f, 0.0f, fx[i], fz[i], seg[i], o);
	x[i] = px[i] = o[0]; y[i] = py[i] = o[1]; z[i] = pz[i] = o[2]; fx[i] = o[3]; fz[i] = o[4]; pitch[i] = ppitch[i] = o[5]; yaw[i] = pyaw[i] = o[6];
	latm[i] = 0.0f; rpitch[i] = o[5]; steer[i] = 0.0f;
	tu[i] = tick; span[i] = 1;
	return true;
}

// a scripted car placed at a lane position (scenes); drive_to gives it somewhere to go
int Sim::spawn_at(int model_, int lane_, float s_, float speed) {
	if (!built || lane_ < 0 || lane_ >= n_lanes) return -1;
	int i = place_car(lane_, s_, speed, model_, 1);
	if (i < 0) return -1;
	kind[i] = K_SCRIPTED; tier[i] = TIER_FULL;
	rt[i].assign(1, lane_); rt_i[i] = 0;
	nconn[i] = pick_routed(i, lane_);
	st.spawned++;
	event(E_SPAWN, i, (float)lane_);
	return id[i];
}

int Sim::route_lanes(int car_id, int32_t *out, int max) const {
	int i = find_car(car_id);
	if (i < 0) return 0;
	int n = 0;
	for (int k = std::max(rt_i[i], 0); k < (int)rt[i].size() && n < max; k++) out[n++] = rt[i][k];
	return n;
}

// a bus at a stop: dwell, then on to the next stop of the route (none left: drive to the route end)
void Sim::route_advance(int i) {
	arrived[i] = 0; dwell[i] = 0.0f; pull[i] = 0;
	if (kind[i] != K_BUS || route_of[i] < 0) { goal_ri[i] = -1; return; }
	const Route &R = routes[route_of[i]];
	goal_ri[i] = -1;
	while (++next_stop[i] < (int)R.stop_ri.size()) {
		int sl = R.lanes[R.stop_ri[next_stop[i]]];
		for (int k = std::max(rt_i[i], 0); k < (int)rt[i].size(); k++) if (rt[i][k] == sl) { goal_ri[i] = k; break; }
		if (goal_ri[i] >= 0) break;   // a stop not on the (re-routed) way is skipped
	}
	if (goal_ri[i] < 0) return;
	goal_s[i] = R.stop_s[next_stop[i]];
	float off = std::max(p_hw[rt[i][goal_ri[i]]] - hw[i], 0.0f) + 0.35f;
	goal_lat[i] = -off; pull[i] = 1;
}

int Sim::add_route(const int32_t *lanes_, int n, const int32_t *stop_ri, const float *stop_s, int ns, const float *tph, int model_) {
	Route R;
	std::vector<int32_t> remap(n, -1);   // input index -> index in R.lanes (unknown lanes are dropped)
	for (int k = 0; k < n; k++) {
		if (lanes_[k] < 0 || lanes_[k] >= n_lanes) continue;
		if (!R.lanes.empty()) {   // the data turns into any lane of the next road: turn into the one the junction leads to, then change lanes
			int prev = R.lanes.back(), nx = lanes_[k];
			if (conn_between(*this, prev, nx) < 0 && sibling_side(*this, prev, nx) == 0) {
				for (int q = l_out_off[prev]; q < l_out_off[prev] + l_out_n[prev]; q++) {
					int t = c_to[out_conn[q]];
					if (!p_blocked[n_lanes + out_conn[q]] && sibling_side(*this, t, nx) != 0) { R.lanes.push_back(t); break; }
				}
			}
		}
		remap[k] = (int32_t)R.lanes.size(); R.lanes.push_back(lanes_[k]);
	}
	if (R.lanes.size() < 2) return -1;
	R.cum.resize(R.lanes.size() + 1, 0.0f);
	for (size_t k = 0; k < R.lanes.size(); k++) {
		float add = p_len[R.lanes[k]];
		if (k + 1 < R.lanes.size()) {
			if (sibling_side(*this, R.lanes[k], R.lanes[k + 1]) != 0) add = 0.0f;
			else { int c = conn_between(*this, R.lanes[k], R.lanes[k + 1]); if (c >= 0) add += p_len[n_lanes + c]; }
		}
		R.cum[k + 1] = R.cum[k] + add;
	}
	R.length = R.cum.back();
	for (int k = 0; k < ns; k++) {
		if (stop_ri[k] < 0 || stop_ri[k] >= n || remap[stop_ri[k]] < 0) continue;
		int ri = remap[stop_ri[k]];
		R.stop_ri.push_back(ri); R.stop_s.push_back(clampf(stop_s[k], 3.0f, std::max(p_len[R.lanes[ri]] - 1.0f, 3.0f)));
	}
	for (int h = 0; h < 24; h++) R.tph[h] = tph ? std::max(tph[h], 0.0f) : 0.0f;
	R.model = model_;
	routes.push_back(R);
	return (int)routes.size() - 1;
}

// Timetable buses: trip k of hour h leaves the first stop at h:00 + k * 60 / tph and moves at bus_speed (stops
// included). A trip whose virtual position lies in the spawn ring, out of view, is put on the road there.
void Sim::buses_population() {
	if (routes.empty()) return;
	if (last_tod >= 0.0 && tod < last_tod - 600.0) trips_out.clear();   // a new day
	last_tod = tod;
	int nbus = 0;
	for (int i = 0; i < hi; i++) if (alive[i] && kind[i] == K_BUS) nbus++;
	if (nbus >= 6 || n_alive >= MAX_CARS - 2) return;
	for (int r = 0; r < (int)routes.size(); r++) {
		const Route &R = routes[r];
		double span = R.length / std::max(cfg.bus_speed, 1.0f);
		int h1 = (int)std::floor(tod / 3600.0), h0 = (int)std::floor((tod - span) / 3600.0) - 1;
		for (int h = h0; h <= h1; h++) {
			float tph = R.tph[((h % 24) + 24) % 24];
			if (tph <= 0.0f) continue;
			int n = (int)std::round(tph);
			for (int k = 0; k < n; k++) {
				double dep = h * 3600.0 + k * 3600.0 / n;
				double d = (tod - dep) * cfg.bus_speed;
				if (d < 0.0 || d > R.length - 20.0) continue;
				int64_t key = ((int64_t)r << 32) | (int64_t)(((int64_t)std::floor(dep) % 86400 + 86400) % 86400);
				if (trips_out.count(key)) continue;
				int ri = 0;
				while (ri + 1 < (int)R.lanes.size() && R.cum[ri + 1] <= d) ri++;
				int L = R.lanes[ri];
				float s_ = clampf((float)(d - R.cum[ri]), 4.0f, std::max(p_len[L] - 6.0f, 4.1f));
				float o[5];
				piece_pose(L, s_, 0.0f, o);
				float dx = o[0] - cam_x, dz = o[2] - cam_z, dd = std::sqrt(dx * dx + dz * dz);
				if (dd > cfg.spawn_r_out || dd < cfg.spawn_r_in) continue;
				bool vis = in_cone(o[0], o[2]);
				if ((vis && dd < cfg.view_safe_r) || (!vis && dd > cfg.behind_despawn_r - 20.0f)) continue;
				bool clear = true;
				for (int j = 0; j < hi && clear; j++) {
					if (!alive[j]) continue;
					float ex = x[j] - o[0], ez = z[j] - o[2];
					if (ex * ex + ez * ez < 20.0f * 20.0f) clear = false;
				}
				if (!clear) continue;
				int i = spawn_routed(K_BUS, R.model, R.lanes, ri, s_, std::min(p_vmax[L], 8.0f) * 0.7f);
				trips_out.insert(key);
				if (i < 0) continue;
				route_of[i] = r; trip[i] = key;
				next_stop[i] = -1;
				// the first stop still ahead
				float here = R.cum[ri] + s_;
				for (int k2 = 0; k2 < (int)R.stop_ri.size(); k2++) {
					if (R.cum[R.stop_ri[k2]] + R.stop_s[k2] > here + 3.0f) { next_stop[i] = k2 - 1; break; }
				}
				if (next_stop[i] < 0 && !R.stop_ri.empty() && R.cum[R.stop_ri.back()] + R.stop_s.back() <= here + 3.0f) next_stop[i] = (int)R.stop_ri.size() - 1;
				route_advance(i);
				tier[i] = dd < cfg.tier_full_r ? TIER_FULL : (dd < cfg.tier_mid_r ? TIER_MID : TIER_FAR);
				st.spawned++; st.buses_spawned++;
				event(E_SPAWN, i, (float)L);
				return;   // one per tick
			}
		}
	}
}

} // namespace tc
