// crowd2 phase 1: the crowd core (see crowd_sim.h for the model). Plain C++, no Godot types.
#include "crowd_sim.h"

#include <algorithm>
#include <cstring>

namespace cc {

namespace {
constexpr uint16_t F_NEED = 256;        // internal: E_NEED_GOAL sent, waiting for set_goal
constexpr double CELL = 50.0;           // segment query cells (same as crowd_layer.gd CELL)
constexpr double GCELL = 2.5;           // walker spatial hash cell
constexpr double PI = 3.14159265358979323846;

inline double wrap_pi(double a) {
	while (a > PI) a -= 2.0 * PI;
	while (a < -PI) a += 2.0 * PI;
	return a;
}
} // namespace

// ------------------------------------------------------------------ setup
void Sim::set_graph(const float *p_node_xz, int p_nn, const int32_t *p_seg_a, const int32_t *p_seg_b, const uint8_t *p_kind,
		const uint8_t *p_zone, const int32_t *p_ctl, const int32_t *p_p0, const int32_t *p_np, const float *p_len, int p_ns,
		const float *p_pts, int p_npts) {
	nn = p_nn; ns = p_ns;
	node_x.resize(nn); node_z.resize(nn);
	float minx = BIG, minz = BIG, maxx = -BIG, maxz = -BIG;
	for (int i = 0; i < nn; i++) {
		node_x[i] = p_node_xz[2 * i]; node_z[i] = p_node_xz[2 * i + 1];
		minx = std::min(minx, node_x[i]); maxx = std::max(maxx, node_x[i]);
		minz = std::min(minz, node_z[i]); maxz = std::max(maxz, node_z[i]);
	}
	seg_a.assign(p_seg_a, p_seg_a + ns); seg_b.assign(p_seg_b, p_seg_b + ns);
	seg_kind.assign(p_kind, p_kind + ns); seg_zone.assign(p_zone, p_zone + ns);
	seg_ctl.assign(p_ctl, p_ctl + ns); seg_p0.assign(p_p0, p_p0 + ns); seg_np.assign(p_np, p_np + ns);
	seg_len.assign(p_len, p_len + ns);
	pts.assign(p_pts, p_pts + (size_t)p_npts * 3);
	// CSR adjacency
	adj_first.assign(nn + 1, 0);
	for (int s = 0; s < ns; s++) { adj_first[seg_a[s] + 1]++; adj_first[seg_b[s] + 1]++; }
	for (int i = 0; i < nn; i++) adj_first[i + 1] += adj_first[i];
	adj_seg.assign(adj_first[nn], -1); adj_node.assign(adj_first[nn], -1);
	std::vector<int32_t> fill(adj_first.begin(), adj_first.end() - 1);
	for (int s = 0; s < ns; s++) {
		int a = seg_a[s], b = seg_b[s];
		adj_seg[fill[a]] = s; adj_node[fill[a]++] = b;
		adj_seg[fill[b]] = s; adj_node[fill[b]++] = a;
	}
	// 50 m cells of segment midpoints
	if (nn == 0) { cgw = cgh = 0; return; }
	cgx0 = (int)std::floor(minx / CELL); cgz0 = (int)std::floor(minz / CELL);
	cgw = (int)std::floor(maxx / CELL) - cgx0 + 1; cgh = (int)std::floor(maxz / CELL) - cgz0 + 1;
	cell_first.assign((size_t)cgw * cgh + 1, 0);
	auto cell_of = [&](int s) {
		double mx = (node_x[seg_a[s]] + node_x[seg_b[s]]) * 0.5, mz = (node_z[seg_a[s]] + node_z[seg_b[s]]) * 0.5;
		return ((int)std::floor(mz / CELL) - cgz0) * cgw + ((int)std::floor(mx / CELL) - cgx0);
	};
	for (int s = 0; s < ns; s++) cell_first[cell_of(s) + 1]++;
	for (size_t i = 0; i + 1 < cell_first.size(); i++) cell_first[i + 1] += cell_first[i];
	cell_seg.assign(ns, -1);
	std::vector<int32_t> cf(cell_first.begin(), cell_first.end() - 1);
	for (int s = 0; s < ns; s++) cell_seg[cf[cell_of(s)]++] = s;
	as_g.assign(nn, 0.0f); as_from.assign(nn, -1); as_gen.assign(nn, 0); as_heap.reserve(4096);
	as_cur = 0;
	node_zone.assign(nn, 6);
	for (int i = 0; i < nn; i++)
		for (int k = adj_first[i]; k < adj_first[i + 1]; k++)
			if (seg_kind[adj_seg[k]] == SEG_WALK) { node_zone[i] = (uint8_t)std::min<int>(seg_zone[adj_seg[k]], MAX_ZONES - 1); break; }
	q_x = q_z = BIG;
}

void Sim::set_places(const uint8_t *p_kind, const int32_t *p_node, const float *p_xz, const float *p_weight, const float *p_hours,
		const int32_t *p_link_first, const float *p_link_pts, int p_n, int p_link_n) {
	n_places = p_n;
	pl_kind.assign(p_kind, p_kind + p_n); pl_node.assign(p_node, p_node + p_n); pl_w.assign(p_weight, p_weight + p_n);
	pl_hours.assign(p_hours, p_hours + (size_t)p_n * 28);
	pl_link0.assign(p_link_first, p_link_first + p_n + 1);
	pl_link.assign(p_link_pts, p_link_pts + (size_t)p_link_n * 3);
	pl_occ.assign(p_n, 0);
	pl_yaw.assign(p_n, 0.0f);
	pl_x.resize(p_n); pl_z.resize(p_n);
	for (int i = 0; i < p_n; i++) { pl_x[i] = p_xz[2 * i]; pl_z[i] = p_xz[2 * i + 1]; }
	q_x = q_z = BIG;
	plc_first.assign((size_t)cgw * cgh + 1, 0);
	if (cgw == 0) return;
	auto cell_of = [&](int i) {
		int gx = std::min(std::max((int)std::floor(pl_x[i] / CELL) - cgx0, 0), cgw - 1), gz = std::min(std::max((int)std::floor(pl_z[i] / CELL) - cgz0, 0), cgh - 1);
		return gz * cgw + gx;
	};
	for (int i = 0; i < p_n; i++) plc_first[cell_of(i) + 1]++;
	for (size_t i = 0; i + 1 < plc_first.size(); i++) plc_first[i + 1] += plc_first[i];
	plc_idx.assign(p_n, -1);
	std::vector<int32_t> cf(plc_first.begin(), plc_first.end() - 1);
	for (int i = 0; i < p_n; i++) plc_idx[cf[cell_of(i)]++] = i;
}

void Sim::set_party_mix(const double *p_mix, int p_zones) {
	for (int z = 0; z < MAX_ZONES; z++)
		for (int k = 0; k < PK_COUNT; k++) party_mix[z][k] = z < p_zones ? p_mix[z * PK_COUNT + k] : 0.0;
}

bool Sim::set_look(int p_id, int p_donor, const float *p_custom4, double p_height) {
	int s = slot_of(p_id);
	if (s < 0) return false;
	look_donor[s] = (int16_t)p_donor; look_h[s] = (float)p_height;
	for (int k = 0; k < 4; k++) look_c[s][k] = p_custom4[k];
	return true;
}
void Sim::clear_near() { std::memset(has_near, 0, sizeof(has_near)); }
bool Sim::set_near(int p_id, bool p_on) {
	int s = slot_of(p_id);
	if (s < 0) return false;
	has_near[s] = p_on ? 1 : 0;
	return true;
}

// The far figures: one row of 16 floats per walker in range, grouped by donor body. This loop was the largest part of
// the crowd's drawing cost in script (0.5 ms for ~60 walkers on the PC).
int Sim::build_far(int p_donors, double p_cam_x, double p_cam_z, double p_r, double p_dt, int p_walk_frames, int p_pose_idle,
		int p_pose_sit, double p_pose_k, double p_stride_m) {
	if ((int)far_rows.size() != p_donors) { far_rows.assign(p_donors, std::vector<float>()); far_n.assign(p_donors, 0); }
	for (int d = 0; d < p_donors; d++) far_n[d] = 0;
	unlooked.clear();
	const double r2 = p_r * p_r;
	int drawn = 0;
	for (int i = 0; i < n_slots; i++) {
		if (!alive[i] || (flags[i] & F_HIDDEN)) continue;
		double dx = x[i] - p_cam_x, dz = z[i] - p_cam_z;
		if (dx * dx + dz * dz > r2) continue;
		int d = look_donor[i];
		if (d < 0 || d >= p_donors) { if (unlooked.size() < 64) unlooked.push_back(id[i]); continue; }
		int pose = p_pose_idle;
		int rest = -1;   // which rest pose (0 sit, 1 back, 2 front), -1 = on the feet
		if (flags[i] & F_MOVING) {
			walk_ph[i] += (float)(v_ema[i] * p_dt / p_stride_m);
			walk_ph[i] -= std::floor(walk_ph[i]);
			pose = (int)(walk_ph[i] * p_walk_frames) % p_walk_frames;
		} else if ((flags[i] & F_SIT) && state[i] == S_STAY && act[i] != A_BENCH) {
			rest = (act[i] >= A_REST_SIT && act[i] <= A_REST_FRONT) ? act[i] - A_REST_SIT : 0;
			pose = p_pose_sit + rest;
		}
		std::vector<float> &buf = far_rows[d];
		size_t b = (size_t)far_n[d] * 16;
		if (buf.size() < b + 16) buf.resize(std::max(b + 16, buf.size() * 2));
		const float hs = look_h[i], c = std::cos(yaw[i]) * hs, s = std::sin(yaw[i]) * hs;
		float *w = buf.data() + b;
		w[0] = c; w[1] = 0.0f; w[2] = s; w[3] = x[i];
		// a resting body is lowered until it touches the ground (the pose alone leaves it at standing / chair height)
		const size_t ro = ((size_t)d * 3 + (size_t)std::max(rest, 0)) * 5;
		w[4] = 0.0f; w[5] = hs; w[6] = 0.0f; w[7] = y[i] + (rest >= 0 && ro < rest_info.size() ? rest_info[ro] * hs : 0.0f);
		w[8] = -s; w[9] = 0.0f; w[10] = c; w[11] = z[i];
		w[12] = look_c[i][0]; w[13] = look_c[i][1]; w[14] = look_c[i][2] + (float)(p_pose_k * pose);
		w[15] = has_near[i] ? look_c[i][3] : -(look_c[i][3] + 1.0f);   // no near body: solid at any distance
		far_n[d]++; drawn++;
	}
	return drawn;
}

// One towel under everybody who rests on the sand within p_r of the camera: as wide and long as the resting body's
// footprint plus a margin, turned with the body, colours and pattern from the walker's seed (the same towel every time).
int Sim::build_towels(double p_cam_x, double p_cam_z, double p_r, int p_cap) {
	towel_rows.clear();
	const double r2 = p_r * p_r;
	int n = 0;
	for (int i = 0; i < n_slots && n < p_cap; i++) {
		if (!alive[i] || (flags[i] & F_HIDDEN) || state[i] != S_STAY || !(flags[i] & F_SIT)) continue;
		if (act[i] < A_REST_SIT || act[i] > A_REST_FRONT) continue;
		double dx = x[i] - p_cam_x, dz = z[i] - p_cam_z;
		if (dx * dx + dz * dz > r2) continue;
		const int d = look_donor[i], rest = act[i] - A_REST_SIT;
		float bx0 = -0.3f, bz0 = -0.5f, bw = 0.6f, bl = 1.0f;
		const size_t ro = ((size_t)std::max(d, 0) * 3 + (size_t)rest) * 5;
		if (d >= 0 && ro + 4 < rest_info.size()) { bx0 = rest_info[ro + 1]; bz0 = rest_info[ro + 2]; bw = rest_info[ro + 3]; bl = rest_info[ro + 4]; }
		const float hs = look_h[i] > 0.1f ? look_h[i] : 1.0f;
		const float sx = std::max(bw * hs + 0.3f, 0.75f), sz = std::max(bl * hs + 0.3f, 1.2f);
		const float cx = (bx0 + bw * 0.5f) * hs, cz = (bz0 + bl * 0.5f) * hs;
		const float c = std::cos(yaw[i]), s = std::sin(yaw[i]);
		float row[16] = {
			c * sx, 0.0f, s * sz, x[i] + cx * c + cz * s,
			0.0f, 1.0f, 0.0f, y[i] + 0.012f,
			-s * sx, 0.0f, c * sz, z[i] - cx * s + cz * c,
			0.0f, 0.0f, 0.0f, 0.0f };
		const uint32_t sd = seed[i];
		const uint32_t ca = sd % 12u;
		row[12] = (float)ca; row[13] = (float)((ca + 1u + (sd / 12u) % 11u) % 12u); row[14] = (float)((sd / 144u) % 4u);
		towel_rows.insert(towel_rows.end(), row, row + 16);
		n++;
	}
	return n;
}

void Sim::set_time(double p_hour, int p_weekday, double p_sunrise, double p_sunset) {
	hour = p_hour; weekday = ((p_weekday % 7) + 7) % 7; sunrise = p_sunrise; sunset = p_sunset;
}

bool Sim::place_open(int p_place, double p_hour) const {
	if (pl_kind[p_place] != PL_SHOP) return true;
	for (int day = 0; day < 2; day++) {            // today, then the after-midnight tail of yesterday
		const float *h = pl_hours.data() + (size_t)p_place * 28 + (size_t)((weekday + (day ? 6 : 0)) % 7) * 4;
		double t = p_hour + (day ? 24.0 : 0.0);
		for (int k = 0; k < 2; k++) if (h[2 * k + 1] > h[2 * k] && t >= h[2 * k] && t < h[2 * k + 1]) return true;
	}
	return false;
}

void Sim::set_controls(const int32_t *p_first, int p_nctl, const float *p_heading_xz, int p_nap) {
	ctl_first.assign(p_first, p_first + p_nctl + 1);
	ctl_hx.resize(p_nap); ctl_hz.resize(p_nap);
	for (int i = 0; i < p_nap; i++) {
		double hx = p_heading_xz[2 * i], hz = p_heading_xz[2 * i + 1];
		double l = std::sqrt(hx * hx + hz * hz);
		ctl_hx[i] = (float)(l > 1e-9 ? hx / l : 0.0); ctl_hz[i] = (float)(l > 1e-9 ? hz / l : 1.0);
	}
	ctl_green.assign(p_nctl, 0xFFFFFFFFu); ctl_known.assign(p_nctl, 0);
}

void Sim::reset(uint64_t p_seed) {
	std::memset(alive, 0, sizeof(alive));
	n_slots = 0; next_id = 1; n_dyn = 0;
	stats = Stats();
	pop_acc = 0.0; clock = 0.0; tick_n = 0;
	rng = p_seed * 0x9E3779B97F4A7C15ull + 0xD1B54A32D192ED03ull;
	if (rng == 0) rng = 1;
	events.clear();
	std::fill(ctl_known.begin(), ctl_known.end(), (uint8_t)0);
	std::fill(ctl_green.begin(), ctl_green.end(), 0xFFFFFFFFu);
	// (19 Nov: a reset is a new start in everything; the old one kept the party numbers, the talk and the last query,
	// so the same seed gave two different runs)
	next_party = 1; talk_party = 0; talk_conv = -1; talk_line = 0; talk_t = 6.0;
	q_x = q_z = BIG; bus_acc = 0.0; boarded = alighted = 0; buses_served.clear(); guests.clear();
	std::fill(pl_occ.begin(), pl_occ.end(), 0);
}

uint32_t Sim::rnd() {
	rng ^= rng >> 12; rng ^= rng << 25; rng ^= rng >> 27;
	return (uint32_t)((rng * 0x2545F4914F6CDD1Dull) >> 32);
}
double Sim::rndf() { return (double)(rnd() >> 8) * (1.0 / 16777216.0); }

// ------------------------------------------------------------------ inputs
void Sim::set_view(double p_x, double p_z, double p_fx, double p_fz, double p_fov_deg) {
	view_x = p_x; view_z = p_z;
	double l = std::sqrt(p_fx * p_fx + p_fz * p_fz);
	if (l > 1e-9) { view_fx = p_fx / l; view_fz = p_fz / l; }
	view_cos = p_fov_deg >= 359.0 ? -1.0 : std::cos(p_fov_deg * 0.5 * PI / 180.0);
}
void Sim::set_player(double p_x, double p_z) { player_x = p_x; player_z = p_z; }
void Sim::set_dynamic(const float *p_rows, int p_n) {
	n_dyn = std::min(p_n, MAX_DYN);
	for (int i = 0; i < n_dyn; i++) {
		const float *r = p_rows + (size_t)i * 6;
		dyn_x[i] = r[0]; dyn_z[i] = r[1]; dyn_r[i] = r[2]; dyn_vx[i] = r[3]; dyn_vz[i] = r[4]; dyn_kind[i] = (uint8_t)r[5];
	}
}
void Sim::set_zone_targets(const double *p_targets, int p_n) {
	for (int i = 0; i < MAX_ZONES; i++) zone_target[i] = i < p_n ? p_targets[i] : 0.0;
}
void Sim::set_signal(int p_ctl, uint32_t p_green_mask) {
	if (p_ctl < 0 || p_ctl >= (int)ctl_green.size()) return;
	ctl_green[p_ctl] = p_green_mask; ctl_known[p_ctl] = 1;
}

// ------------------------------------------------------------------ small helpers
void Sim::emit(int p_type, int p_id, int p_slot, double p_aux) {
	events.push_back((float)p_type); events.push_back((float)p_id);
	events.push_back(p_slot >= 0 ? x[p_slot] : 0.0f); events.push_back(p_slot >= 0 ? y[p_slot] : 0.0f);
	events.push_back(p_slot >= 0 ? z[p_slot] : 0.0f); events.push_back((float)p_aux);
}
int Sim::slot_of(int p_id) const {
	for (int i = 0; i < n_slots; i++) if (alive[i] && id[i] == p_id) return i;
	return -1;
}
int Sim::free_slot() {
	int cap = std::min(MAX_AGENTS, cfg.max_agents);
	for (int i = 0; i < n_slots; i++) if (!alive[i]) return i;
	if (n_slots < cap) return n_slots++;
	return -1;
}
void Sim::kill(int p_slot, int p_reason) {
	if (!alive[p_slot]) return;
	emit(E_DESPAWN, id[p_slot], p_slot, p_reason);
	if (goal_tag[p_slot] >= 0 && goal_tag[p_slot] < n_places && pl_kind[goal_tag[p_slot]] == PL_BENCH) pl_occ[goal_tag[p_slot]] = 0;
	if (p_reason == DESPAWN_DOOR && goal_tag[p_slot] >= 0 && goal_tag[p_slot] < n_places && pl_kind[goal_tag[p_slot]] == PL_SHOP && pl_occ[goal_tag[p_slot]] < 12)
		pl_occ[goal_tag[p_slot]]++;   // the shop lets them out again later (spawn_at_door)
	alive[p_slot] = 0; stats.agents--; stats.retired++;
	if (party[p_slot] != 0 && lead[p_slot] < 0)
		for (int j = 0; j < n_slots; j++)
			if (alive[j] && lead[j] == p_slot) kill(j, p_reason);
}
bool Sim::remove(int p_id, int p_reason) {
	int s = slot_of(p_id);
	if (s < 0) return false;
	kill(s, p_reason);
	return true;
}
bool Sim::seen(double p_x, double p_z) const {
	if (view_cos <= -1.0) return true;
	double dx = p_x - view_x, dz = p_z - view_z;
	double d = std::sqrt(dx * dx + dz * dz);
	if (d < 1.0) return true;
	return (dx * view_fx + dz * view_fz) / d >= view_cos;
}
int Sim::nearest_node(double p_x, double p_z) const {
	// search the segment cells around the point, growing the ring until something is found
	if (cgw == 0) return -1;
	int cx0 = (int)std::floor(p_x / CELL) - cgx0, cz0 = (int)std::floor(p_z / CELL) - cgz0;
	int best = -1; double bd = BIG;
	for (int ring = 0; ring < std::max(cgw, cgh); ring++) {
		for (int dz = -ring; dz <= ring; dz++) for (int dx = -ring; dx <= ring; dx++) {
			if (std::max(std::abs(dx), std::abs(dz)) != ring) continue;
			int gx = cx0 + dx, gz = cz0 + dz;
			if (gx < 0 || gz < 0 || gx >= cgw || gz >= cgh) continue;
			int c = gz * cgw + gx;
			for (int k = cell_first[c]; k < cell_first[c + 1]; k++) {
				int s = cell_seg[k];
				for (int n : { seg_a[s], seg_b[s] }) {
					double ddx = node_x[n] - p_x, ddz = node_z[n] - p_z, d = ddx * ddx + ddz * ddz;
					if (d < bd) { bd = d; best = n; }
				}
			}
		}
		if (best >= 0 && ring >= 1 && std::sqrt(bd) < (ring - 0.5) * CELL) break;
	}
	return best;
}

// ------------------------------------------------------------------ A*
bool Sim::plan(int p_from, int p_to, std::vector<int32_t> &r_nodes) {
	r_nodes.clear();
	if (p_from < 0 || p_to < 0 || p_from >= nn || p_to >= nn) return false;
	stats.plans++;
	if (p_from == p_to) { r_nodes.push_back(p_from); return true; }
	as_cur++;
	const double tx = node_x[p_to], tz = node_z[p_to];
	auto h = [&](int n) { double dx = node_x[n] - tx, dz = node_z[n] - tz; return (float)std::sqrt(dx * dx + dz * dz); };
	// binary heap of (f, node) packed in two parallel vectors
	static thread_local std::vector<float> hf;
	hf.clear(); as_heap.clear();
	auto push = [&](float f, int n) {
		hf.push_back(f); as_heap.push_back(n);
		size_t i = hf.size() - 1;
		while (i > 0) {
			size_t p = (i - 1) / 2;
			if (hf[p] <= hf[i]) break;
			std::swap(hf[p], hf[i]); std::swap(as_heap[p], as_heap[i]); i = p;
		}
	};
	auto pop = [&]() {
		int n = as_heap[0];
		hf[0] = hf.back(); as_heap[0] = as_heap.back(); hf.pop_back(); as_heap.pop_back();
		size_t i = 0, m = hf.size();
		while (true) {
			size_t l = 2 * i + 1, r = l + 1, b = i;
			if (l < m && hf[l] < hf[b]) b = l;
			if (r < m && hf[r] < hf[b]) b = r;
			if (b == i) break;
			std::swap(hf[b], hf[i]); std::swap(as_heap[b], as_heap[i]); i = b;
		}
		return n;
	};
	as_gen[p_from] = as_cur; as_g[p_from] = 0.0f; as_from[p_from] = -1;
	push(h(p_from), p_from);
	int expanded = 0;
	bool found = false;
	while (!hf.empty() && expanded < 20000) {
		float f = hf[0];
		int n = pop();
		if (n == p_to) { found = true; break; }
		if (f > as_g[n] + h(n) + 0.01f) continue;   // stale entry
		expanded++;
		for (int k = adj_first[n]; k < adj_first[n + 1]; k++) {
			int m = adj_node[k];
			float g = as_g[n] + seg_len[adj_seg[k]];
			if (as_gen[m] == as_cur && g >= as_g[m]) continue;
			as_gen[m] = as_cur; as_g[m] = g; as_from[m] = n;
			push(g + h(m), m);
		}
	}
	stats.astar_expanded += expanded;
	if (!found) { stats.plan_fail++; return false; }
	for (int n = p_to; n >= 0; n = as_from[n]) r_nodes.push_back(n);
	std::reverse(r_nodes.begin(), r_nodes.end());
	return true;
}

// ------------------------------------------------------------------ legs
const float *Sim::leg_pt(int p_slot, int p_k) const {
	int idx = p_first[p_slot] + p_k * p_step[p_slot];
	if (flags[p_slot] & F_ON_LINK) return (link_phase[p_slot] == 3 ? back[p_slot] : link[p_slot]).data() + (size_t)idx * 3;
	return pts.data() + (size_t)idx * 3;
}
int Sim::node_at_leg_end(int p_slot) const {
	if (flags[p_slot] & F_ON_LINK) return link_node[p_slot];
	int s = seg[p_slot];
	if (s < 0) return -1;
	return p_step[p_slot] > 0 ? seg_b[s] : seg_a[s];
}
void Sim::leg_from_segment(int p_slot, int p_seg, bool p_from_a) {
	seg[p_slot] = p_seg; p_n[p_slot] = seg_np[p_seg];
	p_first[p_slot] = p_from_a ? seg_p0[p_seg] : seg_p0[p_seg] + seg_np[p_seg] - 1;
	p_step[p_slot] = p_from_a ? 1 : -1;
	pi[p_slot] = 0; pd[p_slot] = 0.0f;
	flags[p_slot] &= ~F_ON_LINK;
	if (seg_kind[p_seg] == SEG_WALK) {
		zone[p_slot] = std::min<int>(seg_zone[p_seg], MAX_ZONES - 1);
		half_w[p_slot] = p_seg < (int)seg_hw.size() ? seg_hw[p_seg] : (float)cfg.half_w[zone[p_slot]];
	} else {
		half_w[p_slot] = (float)cfg.half_w_cross;
	}
}
void Sim::leg_from_link(int p_slot, bool p_reverse) {
	const std::vector<float> &l = p_reverse ? back[p_slot] : link[p_slot];
	int n = (int)l.size() / 3;
	seg[p_slot] = -1; p_n[p_slot] = n;
	p_first[p_slot] = p_reverse ? n - 1 : 0; p_step[p_slot] = p_reverse ? -1 : 1;
	pi[p_slot] = 0; pd[p_slot] = 0.0f;
	flags[p_slot] |= F_ON_LINK;
	half_w[p_slot] = 0.5f;
}

// a walker about to step from the pavement onto a crossing: true = go, false = it now waits at the kerb
// Where a walker stands while it waits at a kerb: on a wide pavement somewhere across its width (a little crowd),
// never within a body of somebody who stands there already; on a narrow one where it arrived (the others queue behind).
void Sim::wait_spot(int p_slot) {
	const double hw = half_w[p_slot];
	if (hw < 1.2) { lat_t[p_slot] = lat[p_slot]; return; }
	const double lx = fz[p_slot], lz = -fx[p_slot];
	double best = lat[p_slot], best_gap = -1.0;
	for (int t = 0; t < 8; t++) {
		const double cand = rndf(-0.8, 0.8) * hw;
		const double px = cx[p_slot] + lx * cand, pz = cz[p_slot] + lz * cand;
		double gap = BIG;
		for (int j = 0; j < n_slots; j++) {
			if (j == p_slot || !alive[j] || state[j] == S_WALK) continue;
			const double ex = x[j] - px, ez = z[j] - pz;
			gap = std::min(gap, ex * ex + ez * ez);
		}
		if (gap > best_gap) { best_gap = gap; best = cand; }
		if (gap > 0.6 * 0.6) break;
	}
	lat_t[p_slot] = (float)best;
}

bool Sim::crossing_gate(int p_slot, int p_seg, int p_n0, int p_n1) {
	int c = seg_ctl[p_seg];
	if (c >= 0 && c < (int)ctl_known.size() && ctl_known[c]) {
		double dx = node_x[p_n1] - node_x[p_n0], dz = node_z[p_n1] - node_z[p_n0];
		double l = std::sqrt(dx * dx + dz * dz);
		if (l > 1e-6) { dx /= l; dz /= l; }
		int best = 0; double bd = -1.0;
		for (int k = ctl_first[c]; k < ctl_first[c + 1]; k++) {
			double d = std::fabs(dx * ctl_hx[k] + dz * ctl_hz[k]);
			if (d > bd) { bd = d; best = k - ctl_first[c]; }
		}
		if (ctl_first[c + 1] > ctl_first[c] && !((ctl_green[c] >> best) & 1u)) {
			state[p_slot] = S_WAIT; why[p_slot] = W_SIGNAL; wait_ctl[p_slot] = c; wait_ap[p_slot] = best; wait_s[p_slot] = 0.0f;
			wait_spot(p_slot);
			stats.waits_signal++;
			emit(E_WAIT_CROSS, id[p_slot], p_slot, c);
			return false;
		}
		return true;
	}
	if (c >= 0) return true;   // a signal nobody told us about: walk (the old crowd did the same without RoadsAPI)
	// unsignalled: a look first (most walkers, near the player only: nobody sees the others), then gap acceptance
	double pdx = x[p_slot] - player_x, pdz = z[p_slot] - player_z;
	bool look = pdx * pdx + pdz * pdz < 40.0 * 40.0 && rndf() < cfg.look_cross_p;
	if (look) {
		state[p_slot] = S_WAIT; why[p_slot] = W_LOOK; wait_ctl[p_slot] = -1; wait_s[p_slot] = 0.0f;
		dwell[p_slot] = (float)rndf(0.6, 1.3);
		emit(E_LOOK_CROSS, id[p_slot], p_slot, 0);
		return false;
	}
	if (!gap_clear(p_seg)) {
		state[p_slot] = S_WAIT; why[p_slot] = W_GAP; wait_ctl[p_slot] = -1; wait_s[p_slot] = 0.0f;
		stats.waits_gap++;
		return false;
	}
	return true;
}

bool Sim::gap_clear(int p_seg) const {
	double mx = (node_x[seg_a[p_seg]] + node_x[seg_b[p_seg]]) * 0.5, mz = (node_z[seg_a[p_seg]] + node_z[seg_b[p_seg]]) * 0.5;
	for (int i = 0; i < n_dyn; i++) {
		if (dyn_kind[i] != DYN_CAR) continue;
		double sp = std::sqrt((double)dyn_vx[i] * dyn_vx[i] + (double)dyn_vz[i] * dyn_vz[i]);
		if (sp < 0.5) continue;
		double rx = mx - dyn_x[i], rz = mz - dyn_z[i];
		double d = std::sqrt(rx * rx + rz * rz);
		if (d > 70.0) continue;
		double along = (rx * dyn_vx[i] + rz * dyn_vz[i]) / sp;      // distance the car still has to the crossing
		if (along < -2.0) continue;                                  // already past
		double miss = std::fabs(rx * dyn_vz[i] - rz * dyn_vx[i]) / sp;   // how far its line passes from the crossing
		if (miss > 5.0) continue;
		if (along / sp < cfg.gap_time_s) return false;
	}
	return true;
}

// the next leg of a walker whose current one ended. false = the walker was retired.
bool Sim::next_leg(int p_slot) {
	if (flags[p_slot] & F_ON_LINK) {
		if (link_phase[p_slot] == 3) {           // back on the graph from a door: on with the route
			link_phase[p_slot] = link[p_slot].empty() ? 0 : 1;
			flags[p_slot] &= ~F_ON_LINK;
			seg[p_slot] = -1;
		} else {                                 // at the door
			link_phase[p_slot] = 2;
			goto arrived;
		}
	}
	ri[p_slot]++;
	if (ri[p_slot] < (int)route[p_slot].size() - 1) {
		int n0 = route[p_slot][ri[p_slot]], n1 = route[p_slot][ri[p_slot] + 1];
		int s = -1;
		for (int k = adj_first[n0]; k < adj_first[n0 + 1]; k++) if (adj_node[k] == n1) { s = adj_seg[k]; break; }
		if (s < 0) { kill(p_slot, DESPAWN_LOST); return false; }
		bool was_cross = seg[p_slot] >= 0 && seg_kind[seg[p_slot]] == SEG_CROSS;
		leg_from_segment(p_slot, s, seg_a[s] == n0);
		if (seg_kind[s] == SEG_CROSS && !was_cross) crossing_gate(p_slot, s, n0, n1);
		return true;
	}
	if (link_phase[p_slot] == 1 && !link[p_slot].empty()) {
		link_node[p_slot] = route[p_slot].empty() ? node_at_leg_end(p_slot) : route[p_slot].back();
		leg_from_link(p_slot, false);
		return true;
	}
arrived:
	emit(E_ARRIVE, id[p_slot], p_slot, goal_tag[p_slot]);
	if (flags[p_slot] & F_ENTER) {
		// at the door of a shop or a home near the player: a moment to open it, then in (far away: gone at once)
		const int gp = goal_tag[p_slot];
		if (tier[p_slot] == TIER_FAR || gp < 0 || gp >= n_places || (pl_kind[gp] != PL_SHOP && pl_kind[gp] != PL_HOME)) { kill(p_slot, DESPAWN_DOOR); return false; }
		state[p_slot] = S_STAY; why[p_slot] = W_DWELL; dwell[p_slot] = 0.8f; pausing[p_slot] = 0; v[p_slot] = 0.0f;
		act[p_slot] = A_DOOR;
		return true;
	}
	state[p_slot] = S_STAY; why[p_slot] = W_DWELL; dwell[p_slot] = goal_dwell[p_slot];
	flags[p_slot] &= ~(F_NEED | F_SCRIPT_GOAL);
	const bool to_bench = goal_tag[p_slot] >= 0 && goal_tag[p_slot] < n_places && pl_kind[goal_tag[p_slot]] == PL_BENCH;
	if (cfg.rain > 0.5 && (to_bench || (flags[p_slot] & F_SIT))) {
		// they set off before the rain: nobody sits down on a wet bench or the wet sand, a look round and on
		if (to_bench) pl_occ[goal_tag[p_slot]] = 0;
		flags[p_slot] &= ~F_SIT;
		dwell[p_slot] = std::min(dwell[p_slot], (float)rndf(1.0, 3.0));
	} else if (to_bench) {
		act[p_slot] = A_BENCH; flags[p_slot] |= F_FACE; face_yaw[p_slot] = pl_yaw[goal_tag[p_slot]];
	} else if (flags[p_slot] & F_SIT) {   // resting on the sand: sit, or lie down on the back or the front
		double q = rndf();
		act[p_slot] = q < 0.45 ? A_REST_SIT : (q < 0.8 ? A_REST_BACK : A_REST_FRONT);
	}
	if (!(flags[p_slot] & F_ON_LINK)) lat_t[p_slot] = (float)(rndf(-0.8, 0.8) * half_w[p_slot]);   // step aside, not on the lane
	return true;
}

bool Sim::start_route(int p_slot, int p_from_node) {
	(void)p_from_node;
	if (act[p_slot] == A_BENCH) {
		for (int p = 0; p < n_places; p++) if (pl_kind[p] == PL_BENCH && pl_occ[p] > 0) {
			double bx = pl_x[p] - x[p_slot], bz = pl_z[p] - z[p_slot];
			if (bx * bx + bz * bz < 4.0) { pl_occ[p] = 0; break; }
		}
		flags[p_slot] &= ~F_FACE;
	}
	act[p_slot] = A_NONE;
	ri[p_slot] = -1;
	state[p_slot] = S_WALK; why[p_slot] = W_NONE;
	flags[p_slot] &= ~F_NEED;
	return true;
}

// a goal of the walker's own: a node 120..520 m away, reached over the graph. People walk through and out of the area.
bool Sim::own_goal(int p_slot) {
	int from = node_at_leg_end(p_slot);
	if (from < 0) return false;
	for (int t = 0; t < 10; t++) {
		double ang = rndf(0.0, 2.0 * PI), d = rndf(cfg.goal_min_m, cfg.goal_max_m);
		double gx = x[p_slot] + std::sin(ang) * d, gz = z[p_slot] + std::cos(ang) * d;
		int cxi = (int)std::floor(gx / CELL) - cgx0, czi = (int)std::floor(gz / CELL) - cgz0;
		if (cxi < 0 || czi < 0 || cxi >= cgw || czi >= cgh) continue;
		int c = czi * cgw + cxi, n = cell_first[c + 1] - cell_first[c];
		if (n <= 0) continue;
		int s = cell_seg[cell_first[c] + (int)(rnd() % (uint32_t)n)];
		if (seg_kind[s] != SEG_WALK) continue;
		int to = (rnd() & 1) ? seg_a[s] : seg_b[s];
		if (to == from) continue;
		if (!plan(from, to, route[p_slot])) continue;
		link[p_slot].clear();
		goal_dwell[p_slot] = 0.0f; goal_tag[p_slot] = -1;
		flags[p_slot] &= ~(F_ENTER | F_SIT | F_SCRIPT_GOAL);
		link_phase[p_slot] = 0;                 // a caller standing at a door walks its link back first (back[] + phase 3)
		return start_route(p_slot, from);
	}
	return false;
}

bool Sim::set_goal(int p_id, int p_node, const float *p_link, int p_link_pts, double p_dwell, bool p_enter, bool p_sit, int p_tag) {
	int s = slot_of(p_id);
	if (s < 0 || p_node < 0 || p_node >= nn) return false;
	bool at_door = (flags[s] & F_ON_LINK) && state[s] == S_STAY;
	if ((flags[s] & F_ON_LINK) && !at_door) return false;   // walking a link: ask again on arrival
	int from = node_at_leg_end(s);
	if (from < 0) return false;
	static thread_local std::vector<int32_t> tmp;
	if (!plan(from, p_node, tmp)) return false;
	if (at_door) { back[s] = link[s]; }
	route[s] = tmp;
	link[s].assign(p_link, p_link + (size_t)std::max(p_link_pts, 0) * 3);
	goal_dwell[s] = (float)p_dwell; goal_tag[s] = p_tag;
	flags[s] &= ~(F_ENTER | F_SIT);
	if (p_enter) flags[s] |= F_ENTER;
	if (p_sit) flags[s] |= F_SIT;
	flags[s] |= F_SCRIPT_GOAL;
	link_phase[s] = link[s].empty() ? 0 : 1;
	bool was_stay = state[s] == S_STAY;
	start_route(s, from);
	if (at_door) {
		link_phase[s] = 3;
		leg_from_link(s, true);
	} else if (was_stay) {
		if (!next_leg(s)) return true;   // retired on the spot (unreachable): still "handled"
	}
	return true;
}

bool Sim::set_stay(int p_id, double p_dwell, bool p_sit) {
	int s = slot_of(p_id);
	if (s < 0) return false;
	state[s] = S_STAY; why[s] = W_DWELL; dwell[s] = (float)p_dwell;
	if (p_sit) flags[s] |= F_SIT; else flags[s] &= ~F_SIT;
	flags[s] &= ~F_NEED;
	return true;
}
bool Sim::set_act(int p_id, int p_act) {
	int s = slot_of(p_id);
	if (s < 0) return false;
	act[s] = (uint8_t)p_act;
	return true;
}
void Sim::set_place_yaw(const float *p_yaw, int p_n) {
	for (int i = 0; i < p_n && i < n_places; i++) pl_yaw[i] = p_yaw[i];
}

// turn round on the current leg (a walker running away from something ahead of it)
void Sim::reverse_leg(int i) {
	if ((flags[i] & F_ON_LINK) || seg[i] < 0 || p_n[i] < 2) return;
	int n = p_n[i];
	int k = std::min(pi[i], n - 2);
	const float *a = leg_pt(i, k), *b = leg_pt(i, k + 1);
	float l = std::sqrt((b[0] - a[0]) * (b[0] - a[0]) + (b[2] - a[2]) * (b[2] - a[2]));
	p_first[i] = p_first[i] + (n - 1) * p_step[i];
	p_step[i] = (int8_t)-p_step[i];
	pi[i] = n - 2 - k;
	pd[i] = std::max(l - pd[i], 0.0f);
	route[i].clear(); route[i].push_back(node_at_leg_end(i)); ri[i] = -1;   // at the end of the leg it picks a new goal
	link[i].clear(); link_phase[i] = 0;
	flags[i] &= ~(F_ENTER | F_SIT | F_SCRIPT_GOAL);
	goal_dwell[i] = 0.0f; goal_tag[i] = -1; errands[i] = 0;
}

int Sim::danger(double p_x, double p_z, double p_duck_r, double p_flee_r, double p_flee_s) {
	int n = 0;
	for (int i = 0; i < n_slots; i++) {
		if (!alive[i] || guest[i] || lead[i] >= 0 || (flags[i] & (F_HIDDEN | F_FACE)) || tier[i] == TIER_FAR || act[i] == A_FIGHT) continue;
		double dx = x[i] - p_x, dz = z[i] - p_z, d2 = dx * dx + dz * dz;
		if (d2 > p_flee_r * p_flee_r) {
			// far enough to be safe, close enough to see it: every second lone walker stops and looks
			if (d2 < (p_flee_r + 14.0) * (p_flee_r + 14.0) && state[i] == S_WALK && act[i] == A_NONE && party[i] == 0
					&& !(flags[i] & F_ON_LINK) && (seed[i] & 1u)) {
				state[i] = S_STAY; pausing[i] = 1; why[i] = W_DWELL; dwell[i] = (float)rndf(3.5, 7.0); v[i] = 0.0f;
				flags[i] |= F_FACE; face_yaw[i] = (float)std::atan2(-dx, -dz);
				act[i] = A_STARE;
			}
			continue;
		}
		n++;
		if (d2 < p_duck_r * p_duck_r) {   // too close to run: down, for a few seconds
			if (state[i] != S_STAY) { state[i] = S_STAY; pausing[i] = 1; why[i] = W_DWELL; dwell[i] = 0.0f; }
			dwell[i] = std::max(dwell[i], (float)rndf(3.0, 5.5));
			act[i] = A_DUCK; v[i] = 0.0f;
			continue;
		}
		if (state[i] == S_STAY && !pausing[i]) continue;   // sitting on the beach / at a place: they look up, they do not run
		if (state[i] != S_WALK) { state[i] = S_WALK; why[i] = W_NONE; pausing[i] = 0; }
		flee_t[i] = (float)p_flee_s;
		if (dx * fx[i] + dz * fz[i] < 0.0) reverse_leg(i);   // heading towards it: turn round
	}
	return n;
}

bool Sim::hold(int p_id, double p_yaw) {
	int s = slot_of(p_id);
	if (s < 0) return false;
	if (lead[s] >= 0) s = lead[s];   // the whole party stops with its leader
	if (state[s] != S_STAY) { state[s] = S_STAY; why[s] = W_DWELL; dwell[s] = 0.0f; flags[s] &= ~F_NEED; }
	dwell[s] = std::max(dwell[s], 1.0e9f);   // an errand's own stay time is over when the talk ends
	flags[s] |= F_FACE; face_yaw[s] = (float)p_yaw;
	v[s] = 0.0f;
	return true;
}
bool Sim::release(int p_id) {
	int s = slot_of(p_id);
	if (s < 0) return false;
	if (lead[s] >= 0) s = lead[s];
	flags[s] &= ~F_FACE;
	if (state[s] == S_STAY) dwell[s] = 0.0f;
	return true;
}
bool Sim::set_hidden(int p_id, bool p_on) {
	int s = slot_of(p_id);
	if (s < 0) return false;
	if (p_on) flags[s] |= F_HIDDEN; else flags[s] &= ~F_HIDDEN;
	return true;
}

// ------------------------------------------------------------------ population
// everything of the walk graph and the places that lies inside the radius, per zone (spawn picks from these lists)
void Sim::refresh_query() {
	q_x = view_x; q_z = view_z;
	for (int zn = 0; zn < MAX_ZONES; zn++) { zq_seg[zn].clear(); zq_cum[zn].clear(); }
	pq.clear();
	if (cgw == 0) return;
	const double r2 = cfg.radius * cfg.radius;
	int cx0 = (int)std::floor(view_x / CELL) - cgx0, cz0 = (int)std::floor(view_z / CELL) - cgz0, n = (int)std::ceil(cfg.radius / CELL) + 1;
	for (int gz = std::max(cz0 - n, 0); gz <= std::min(cz0 + n, cgh - 1); gz++) for (int gx = std::max(cx0 - n, 0); gx <= std::min(cx0 + n, cgw - 1); gx++) {
		int c = gz * cgw + gx;
		for (int k = cell_first[c]; k < cell_first[c + 1]; k++) {
			int s = cell_seg[k];
			if (seg_kind[s] != SEG_WALK || seg_len[s] < 0.5f) continue;
			double mx = (node_x[seg_a[s]] + node_x[seg_b[s]]) * 0.5 - view_x, mz = (node_z[seg_a[s]] + node_z[seg_b[s]]) * 0.5 - view_z;
			if (mx * mx + mz * mz > r2) continue;
			if (!loaded_at(mx + view_x, mz + view_z)) continue;   // (its cell is not in: nobody appears there)
			int zn = std::min<int>(seg_zone[s], MAX_ZONES - 1);
			zq_seg[zn].push_back(s);
			zq_cum[zn].push_back((zq_cum[zn].empty() ? 0.0f : zq_cum[zn].back()) + seg_len[s]);
		}
		if (!plc_first.empty()) for (int k = plc_first[c]; k < plc_first[c + 1]; k++) {
			int p = plc_idx[k];
			double dx = pl_x[p] - view_x, dz = pl_z[p] - view_z;
			if (dx * dx + dz * dz <= r2) pq.push_back(p);
		}
	}
}

// a new walker with everything set except where it stands; -1 = no room
int Sim::make_walker(int p_zone) {
	int i = free_slot();
	if (i < 0) return -1;
	alive[i] = 1; id[i] = next_id++; stats.agents++; stats.spawned++;
	state[i] = S_WALK; why[i] = W_NONE; flags[i] = 0; tier[i] = TIER_FAR; face_yaw[i] = 0.0f;
	party[i] = 0; lead[i] = -1; pkind[i] = PK_NONE; f_back[i] = f_side[i] = 0.0f; f_file[i] = 0.0f; f_rank[i] = 0;
	trail_head[i] = 0; trail_len[i] = 0;
	pause_t[i] = (float)rndf(6.0, cfg.pause_hi_s); pausing[i] = 0; act[i] = A_NONE; flee_t[i] = 0.0f;
	look_donor[i] = -1; look_h[i] = 1.0f; has_near[i] = 0; walk_ph[i] = (float)rndf();
	seed[i] = rnd();
	v_des[i] = (float)rndf(cfg.speed_lo, cfg.speed_hi); v[i] = v_des[i]; v_ema[i] = v_des[i];
	lat[i] = 0.0f; lat_t[i] = 0.0f; half_w[i] = 1.0f;
	dwell[i] = wait_s[i] = blocked_s[i] = need_s[i] = 0.0f;
	gy_x[i] = gy_z[i] = BIG; gy[i] = 0.0f; meet_cd[i] = (float)rndf(2.0, 20.0); meet_x[i] = 0; lat_extra[i] = 0.0f;
	wait_ctl[i] = -1; wait_ap[i] = 0;
	route[i].clear(); ri[i] = -1; link[i].clear(); back[i].clear(); link_phase[i] = 0; link_node[i] = -1;
	goal_dwell[i] = 0.0f; goal_tag[i] = -1;
	errands[i] = (uint8_t)(1 + rnd() % 3);
	seg[i] = -1; p_first[i] = 0; p_n[i] = 0; p_step[i] = 1; pi[i] = 0; pd[i] = 0.0f;
	yaw[i] = 0.0f; fx[i] = 0.0f; fz[i] = 1.0f; x[i] = y[i] = z[i] = cx[i] = cz[i] = 0.0f;
	guest[i] = 0; guest_of[i] = -1;
	zone[i] = (uint8_t)std::min(std::max(p_zone, 0), MAX_ZONES - 1);
	return i;
}

int Sim::spawn_at_segment(int p_seg, double p_s, bool p_from_a, int p_zone) {
	if (p_seg < 0 || p_seg >= ns) return -1;
	int i = make_walker(p_zone);
	if (i < 0) return -1;
	leg_from_segment(i, p_seg, p_from_a);
	zone[i] = (uint8_t)std::min(std::max(p_zone, 0), MAX_ZONES - 1);
	half_w[i] = seg_kind[p_seg] == SEG_WALK ? (p_seg < (int)seg_hw.size() ? seg_hw[p_seg] : (float)cfg.half_w[zone[i]]) : (float)cfg.half_w_cross;
	lat[i] = lat_t[i] = (float)(-cfg.keep_right * half_w[i]);
	pd[i] = (float)std::max(p_s, 0.0);   // seek to arc length p_s
	while (pi[i] < p_n[i] - 1) {
		const float *a = leg_pt(i, pi[i]), *b = leg_pt(i, pi[i] + 1);
		float l = std::sqrt((b[0] - a[0]) * (b[0] - a[0]) + (b[2] - a[2]) * (b[2] - a[2]));
		if (pd[i] <= l) break;
		pd[i] -= l; pi[i]++;
	}
	place(i, 0.0);
	yaw[i] = (float)std::atan2((double)fx[i], (double)fz[i]);
	if (!choose_goal(i)) { route[i].clear(); route[i].push_back(node_at_leg_end(i)); ri[i] = -1; }
	emit(E_SPAWN, id[i], i, zone[i]);
	make_party(i);
	return id[i];
}

// a new walker may bring company (or be a jogger). The leader walks the route; followers hold a place next to it.
void Sim::make_party(int L) {
	const double *mix = party_mix[zone[L]];
	double r = rndf(), acc = 0.0;
	int kind = PK_NONE;
	for (int k = 1; k < PK_COUNT; k++) { acc += mix[k]; if (r < acc) { kind = k; break; } }
	if (kind == PK_NONE) return;
	pkind[L] = (uint8_t)kind;
	if (kind == PK_JOGGER) {
		v_des[L] = (float)rndf(2.6, 3.2); v[L] = v_des[L]; v_ema[L] = v_des[L];
		errands[L] = 0;   // runs through and out of the area
		return;
	}
	int n = kind == PK_COUPLE ? 2 : (kind == PK_FAMILY ? 3 + (int)(rnd() % 2) : 2 + (int)(rnd() % 2));
	static const float BACK[3] = { 0.0f, 0.85f, 0.85f }, SIDE[3] = { 0.62f, 0.0f, 0.62f };
	party[L] = next_party++;
	place(L, 0.0);   // first trail point
	if (kind == PK_FAMILY) v_des[L] *= 0.9f;
	for (int k = 0; k < n - 1; k++) {
		int j = make_walker(zone[L]);
		if (j < 0) break;
		party[j] = party[L]; pkind[j] = (uint8_t)kind; lead[j] = L;
		f_back[j] = BACK[k]; f_side[j] = SIDE[k]; f_rank[j] = (uint8_t)(k + 1);
		if (v_des[j] < v_des[L]) v_des[L] = v_des[j];   // the party walks at its slowest member's pace
		lat[j] = lat[L] + f_side[j];
		yaw[j] = yaw[L];
		follow(j, 0.0);
		emit(E_SPAWN, id[j], j, zone[j]);
	}
	v[L] = v_des[L];
}

// a follower: f_back behind its leader along the path the leader walked and f_side to the left, doing what it does
void Sim::follow(int i, double p_dt) {
	int L = lead[i];
	const uint16_t SHARED = F_SIT | F_FACE | F_HIDDEN;
	flags[i] = (uint16_t)((flags[i] & ~(SHARED | F_ON_LINK)) | (flags[L] & SHARED));
	state[i] = state[L]; why[i] = why[L]; zone[i] = zone[L]; half_w[i] = half_w[L]; face_yaw[i] = face_yaw[L]; v[i] = v[L];
	tier[i] = tier[L]; seg[i] = seg[L];
	// when the leader is going round somebody, following or blocked, the party falls into single file behind it
	// (two abreast would push the others off the pavement); it spreads out again afterwards
	bool tight = (flags[L] & (F_PASSING | F_YIELD)) != 0 || why[L] == W_FOLLOW || why[L] == W_BLOCKED
			|| std::fabs((double)lat_t[L] + cfg.keep_right * half_w[L]) > 0.3 * half_w[L] + 0.12;
	// (19 Nov, the city kit map: many pavements are 1.5 m wide. Where two cannot walk abreast and leave room for
	// somebody coming the other way, a party walks in single file all the way)
	// (the whole party at once: the formation is 0.62 m wide, whatever this member's own place in it)
	if (half_w[L] < 0.62 + 2.0 * cfg.body_r + 0.1) tight = true;
	if (state[L] == S_WALK) {
		double st = (tight ? 3.0 : -1.2) * p_dt;
		f_file[i] = (float)std::min(std::max((double)f_file[i] + st, 0.0), 1.0);
	}
	double backd = f_back[i] + f_file[i] * (0.8 * f_rank[i] - f_back[i]);
	// the point `backd` behind the leader on its trail (straight back along its heading where the trail is too short)
	double px = cx[L], pz = cz[L], hx = fx[L], hz = fz[L];
	if (backd > 0.01) {
		double k = backd / TRAIL_STEP;
		int k0 = (int)k;
		if (k0 + 1 < trail_len[L]) {
			int a = (trail_head[L] - 1 - k0 + 2 * TRAIL_N) % TRAIL_N, b = (a - 1 + TRAIL_N) % TRAIL_N;
			double f = k - k0;
			px = trail_x[L][a] + (trail_x[L][b] - trail_x[L][a]) * f; pz = trail_z[L][a] + (trail_z[L][b] - trail_z[L][a]) * f;
			hx = trail_fx[L][a]; hz = trail_fz[L][a];
		} else {
			px -= hx * backd; pz -= hz * backd;
		}
	}
	double hw = half_w[i], want = (double)lat[L] + f_side[i] * (1.0 - f_file[i]);
	lat_t[i] = (float)std::min(std::max(want, -hw), hw);
	if (p_dt > 0.0) {
		double dl = lat_t[i] - lat[i], st = cfg.lat_speed * (lat_extra[i] > 0.0f ? 2.6 : 1.0) * p_dt;   // a dodge is a quick step
		lat[i] += (float)(dl > st ? st : (dl < -st ? -st : dl));
	} else lat[i] = lat_t[i];
	double nx = px + hz * lat[i], nz = pz - hx * lat[i];
	// the party stands together and talks: everybody on a small circle in front of the leader, turned to its middle
	const bool circle = state[L] == S_STAY && pausing[L] && act[L] == A_CHAT;
	if (circle) {
		int members = 1;
		for (int j = 0; j < n_slots; j++) if (alive[j] && lead[j] == L) members++;
		// (19 Nov: the circle fits the pavement: smaller on a narrow one, and round the pavement's middle, not round
		// where the leader happened to walk)
		const double R = std::max(0.42, std::min(cfg.circle_r * (members > 3 ? 1.25 : 1.0), (double)half_w[L] - 0.25));
		const double mcx = cx[L] + (double)fx[L] * R, mcz = cz[L] + (double)fz[L] * R;
		const double th = std::atan2(-(double)fx[L], -(double)fz[L]) + 2.0 * PI * (double)f_rank[i] / (double)members;
		nx = mcx + std::sin(th) * R; nz = mcz + std::cos(th) * R;
		flags[i] |= F_FACE; face_yaw[i] = (float)std::atan2(mcx - nx, mcz - nz);
		act[i] = A_CHAT;
	} else if (act[i] == A_CHAT && !(state[L] == S_STAY && act[L] == A_CHAT)) act[i] = A_NONE;
	// into the circle and back into the formation at a walk, never in one step
	if (p_dt > 0.0) {
		const double mx0 = nx - x[i], mz0 = nz - z[i], d0 = std::sqrt(mx0 * mx0 + mz0 * mz0), lim = 2.6 * p_dt;
		if (d0 > lim && d0 < 5.0) { nx = x[i] + mx0 / d0 * lim; nz = z[i] + mz0 / d0 * lim; }
	}
	double ny = y[L];
	if (ground_fn && (tier[i] != TIER_FAR || ((nx - view_x) * (nx - view_x) + (nz - view_z) * (nz - view_z) < cfg.ground_r * cfg.ground_r))) {
		double gdx = nx - gy_x[i], gdz = nz - gy_z[i];
		if (gdx * gdx + gdz * gdz > 0.04) {
			double g = ground_fn(ground_user, nx, nz, y[L], true);
			gy[i] = (float)(std::isnan(g) ? y[L] : g);
			gy_x[i] = (float)nx; gy_z[i] = (float)nz;
		}
		ny = gy[i];
	}
	fx[i] = (float)hx; fz[i] = (float)hz;
	if (p_dt > 0.0) {
		double mx = nx - x[i], mz = nz - z[i];
		double sp = std::sqrt(mx * mx + mz * mz) / p_dt;
		v_ema[i] += (float)((sp - v_ema[i]) * std::min(1.0, p_dt * 6.0));
		double ty = (flags[i] & F_FACE) ? (double)face_yaw[i] : std::atan2(hx, hz);
		yaw[i] = (float)wrap_pi(yaw[i] + wrap_pi(ty - yaw[i]) * (1.0 - std::exp(-p_dt * 17.0)));
	} else yaw[i] = (float)std::atan2(hx, hz);
	if (v_ema[i] > 0.25f && state[i] == S_WALK) flags[i] |= F_MOVING; else flags[i] &= ~F_MOVING;
	x[i] = (float)nx; y[i] = (float)ny; z[i] = (float)nz; cx[i] = (float)px; cz[i] = (float)pz;
}

// somebody walks in along the pavement: a walkway of the zone inside the radius, out of sight or at the far edge
bool Sim::spawn_in_zone(int p_zone) {
	const std::vector<int32_t> &segs = zq_seg[p_zone];
	if (segs.empty()) return false;
	const std::vector<float> &cum = zq_cum[p_zone];
	for (int t = 0; t < 12; t++) {
		float pick = (float)(rndf() * cum.back());
		int s = segs[std::min<size_t>(std::lower_bound(cum.begin(), cum.end(), pick) - cum.begin(), segs.size() - 1)];
		double mx = (node_x[seg_a[s]] + node_x[seg_b[s]]) * 0.5, mz = (node_z[seg_a[s]] + node_z[seg_b[s]]) * 0.5;
		double dd = std::sqrt((mx - view_x) * (mx - view_x) + (mz - view_z) * (mz - view_z));
		if (tick_n > 0 && dd < cfg.spawn_min_d) continue;                    // never right next to the player
		if (tick_n > 0 && dd < cfg.radius * 0.75 && seen(mx, mz)) continue;   // in view: only at the far edge
		bool taken = false;
		double tr = seg_len[s] * 0.5 + 1.5;
		for (int i = 0; i < n_slots && !taken; i++)
			if (alive[i] && (x[i] - mx) * (x[i] - mx) + (z[i] - mz) * (z[i] - mz) < tr * tr) taken = true;
		if (taken) continue;
		return spawn_at_segment(s, rndf() * seg_len[s], (rnd() & 1) != 0, p_zone) >= 0;
	}
	return false;
}

// somebody comes out of a door: a shop that people went into, a home at the hours people leave home, a gate
bool Sim::spawn_at_door(int p_zone) {
	if (pq.empty()) return false;
	const double h = hour;
	const double leave_home = h < 5.5 ? 0.02 : (h < 9.5 ? 0.9 : (h < 17.0 ? 0.45 : (h < 21.0 ? 0.25 : 0.05)));
	for (int t = 0; t < 12; t++) {
		int p = pq[rnd() % (uint32_t)pq.size()];
		int kind = pl_kind[p];
		if (kind == PL_BEACH || kind == PL_PARK || kind == PL_BUS || kind == PL_BENCH) continue;
		if (node_zone[pl_node[p]] != p_zone) continue;
		if (kind == PL_SHOP && pl_occ[p] <= 0) continue;
		if (kind == PL_HOME && rndf() > leave_home * std::min(1.0, (double)pl_w[p] / 6.0 + 0.15)) continue;
		if (kind == PL_GATE && rndf() > 0.5) continue;
		double dx = pl_x[p] - player_x, dz = pl_z[p] - player_z;
		if (tick_n > 0 && player_x < BIG * 0.5 && dx * dx + dz * dz < cfg.door_min_d * cfg.door_min_d) continue;
		int np = pl_link0[p + 1] - pl_link0[p];
		if (np < 2) {   // no link: the door is on the walkway, start on a walkway at its node
			int n0 = pl_node[p], s = -1;
			for (int k = adj_first[n0]; k < adj_first[n0 + 1]; k++) if (seg_kind[adj_seg[k]] == SEG_WALK) { s = adj_seg[k]; break; }
			if (s < 0) continue;
			if (kind == PL_SHOP) pl_occ[p]--;
			return spawn_at_segment(s, 0.0, seg_a[s] == n0, p_zone) >= 0;
		}
		int i = make_walker(p_zone);
		if (i < 0) return false;
		if (kind == PL_SHOP) pl_occ[p]--;
		back[i].assign(pl_link.begin() + (size_t)pl_link0[p] * 3, pl_link.begin() + (size_t)pl_link0[p + 1] * 3);
		link_node[i] = pl_node[p];
		link_phase[i] = 3;
		leg_from_link(i, true);
		place(i, 0.0);
		yaw[i] = (float)std::atan2((double)fx[i], (double)fz[i]);
		if (kind != PL_HOME) errands[i] = (uint8_t)(rnd() % 2);   // out of a shop: one more stop at most, then home
		if (!choose_goal(i)) { kill(i, DESPAWN_LOST); return false; }
		link_phase[i] = 3;
		leg_from_link(i, true);            // choose_goal reset the leg bookkeeping: walk the link out first
		emit(E_SPAWN, id[i], i, zone[i]);
		make_party(i);
		return true;
	}
	return false;
}

// how much a kind of place pulls at this hour (0 = nobody goes there now)
static double pull(int p_kind, double h, double p_sunrise, double p_sunset) {
	bool day = h > p_sunrise + 0.5 && h < p_sunset - 0.75;
	switch (p_kind) {
		case PL_HOME: return h < 6.0 ? 1.0 : (h < 9.0 ? 0.15 : (h < 17.0 ? 0.25 : (h < 21.0 ? 0.7 : 1.2)));
		case PL_SHOP: return h < 9.0 ? 0.8 : (h < 20.0 ? 1.0 : 0.6);
		case PL_BEACH: return day ? 0.9 : 0.0;
		case PL_PARK: return day ? 0.5 : 0.1;
		case PL_BUS: return h >= 6.0 && h < 22.0 ? 0.35 : 0.05;
		case PL_BENCH: return day ? 0.45 : 0.08;
		default: return 0.25;
	}
}

// the next place for a walker: a few candidates around it, scored by what pulls at this hour, how big the place is and
// how far it is. -1 = nothing suitable.
int Sim::pick_place(int p_slot) {
	if (n_places == 0 || plc_first.empty()) return -1;
	int best = -1; double bs = 0.0;
	for (int t = 0; t < 16; t++) {
		double ang = rndf(0.0, 2.0 * PI), d = rndf(40.0, 700.0);
		double gx = x[p_slot] + std::sin(ang) * d, gz = z[p_slot] + std::cos(ang) * d;
		int cxi = (int)std::floor(gx / CELL) - cgx0, czi = (int)std::floor(gz / CELL) - cgz0;
		if (cxi < 0 || czi < 0 || cxi >= cgw || czi >= cgh) continue;
		int c = czi * cgw + cxi, n = plc_first[c + 1] - plc_first[c];
		if (n <= 0) continue;
		int p = plc_idx[plc_first[c] + (int)(rnd() % (uint32_t)n)];
		if (p == goal_tag[p_slot]) continue;
		if (pl_kind[p] == PL_BENCH && pl_occ[p] > 0) continue;
		if (pl_w[p] < 0.0f) continue;   // marked unreachable (its link crosses water, a knocked-over bench)
		if (cfg.rain > 0.5 && (pl_kind[p] == PL_BENCH || pl_kind[p] == PL_BEACH || pl_kind[p] == PL_PARK)) continue;   // not in the rain
		double w = pull(pl_kind[p], hour, sunrise, sunset);
		if (w <= 0.0 || !place_open(p, hour + 0.25)) continue;
		double dx = pl_x[p] - x[p_slot], dz = pl_z[p] - z[p_slot];
		double dist = std::sqrt(dx * dx + dz * dz);
		if (dist < 30.0) continue;
		double sc = w * (0.3 + rndf()) * std::min(1.5, 0.4 + (double)pl_w[p] / 8.0) / (1.0 + dist / 250.0);
		if (sc > bs) { bs = sc; best = p; }
	}
	return best;
}

bool Sim::goal_place(int p_slot, int p_place) {
	int from = node_at_leg_end(p_slot);
	if (from < 0) return false;
	if (!plan(from, pl_node[p_place], route[p_slot])) return false;
	link[p_slot].assign(pl_link.begin() + (size_t)pl_link0[p_place] * 3, pl_link.begin() + (size_t)pl_link0[p_place + 1] * 3);
	if (link[p_slot].size() < 6) link[p_slot].clear();
	int kind = pl_kind[p_place];
	flags[p_slot] &= ~(F_ENTER | F_SIT | F_SCRIPT_GOAL);
	goal_tag[p_slot] = p_place;
	if (kind == PL_BEACH || kind == PL_PARK) {
		goal_dwell[p_slot] = (float)rndf(cfg.stay_lo_s, cfg.stay_hi_s);
		if (kind == PL_BEACH && rndf() < 0.6) flags[p_slot] |= F_SIT;
	} else if (kind == PL_BUS) {
		goal_dwell[p_slot] = (float)rndf(15.0, 45.0);   // waits for a bus for a while, then walks on
	} else if (kind == PL_BENCH) {
		goal_dwell[p_slot] = (float)rndf(25.0, 70.0);
		pl_occ[p_place] = 1;                            // the seat is taken until this walker moves on
	} else {
		goal_dwell[p_slot] = 0.0f; flags[p_slot] |= F_ENTER;
	}
	link_phase[p_slot] = link[p_slot].empty() ? 0 : 1;
	return start_route(p_slot, from);
}

// what a walker does next: another place while it has errands left, else it walks on out of the area
bool Sim::choose_goal(int p_slot) {
	if (errands[p_slot] > 0) {
		int p = pick_place(p_slot);
		if (p >= 0 && goal_place(p_slot, p)) { errands[p_slot]--; return true; }
	} else if (n_places > 0 && hour >= 17.0) {   // done for the day: home if one is in reach
		for (int t = 0; t < 6; t++) {
			int p = pick_place(p_slot);
			if (p >= 0 && pl_kind[p] == PL_HOME && goal_place(p_slot, p)) return true;
		}
	}
	return own_goal(p_slot);
}

void Sim::population() {
	int cnt[MAX_ZONES] = { 0 };
	const double rr = cfg.radius * cfg.retire_k;
	for (int i = 0; i < n_slots; i++) {
		if (!alive[i] || guest[i]) continue;
		double dx = x[i] - view_x, dz = z[i] - view_z;
		if (dx * dx + dz * dz > rr * rr || !loaded_at(x[i], z[i])) { kill(i, DESPAWN_FAR); continue; }   // (... or its cell has gone)
		cnt[zone[i]]++;
	}
	if ((q_x - view_x) * (q_x - view_x) + (q_z - view_z) * (q_z - view_z) > 144.0) refresh_query();
	if (!cfg.auto_population) return;
	for (int zn = 0; zn < MAX_ZONES; zn++) {
		double want = zone_target[zn] - cnt[zn];
		// the first pass fills the area at once (a loading screen hides it); later a third of what is missing per pass
		int add = tick_n == 0 ? (int)std::floor(want + rndf()) : std::min(6, (int)std::floor(want * 0.34 + rndf() * 0.999));
		for (int k = 0; k < add; k++) {
			bool door = tick_n > 0 && rndf() < cfg.door_spawn_p;
			if (door ? (spawn_at_door(zn) || spawn_in_zone(zn)) : (spawn_in_zone(zn) || spawn_at_door(zn))) continue;
			break;
		}
		if (want < -2.0) {   // too many (density fell / the view moved to a quieter place): one unseen walker leaves
			for (int i = 0; i < n_slots; i++) {
				if (!alive[i] || guest[i] || zone[i] != zn || tier[i] == TIER_FULL || (flags[i] & F_SCRIPT_GOAL) || seen(x[i], z[i])) continue;
				kill(i, DESPAWN_LEFT); break;
			}
		}
	}
}

// ------------------------------------------------------------------ spatial hash
int Sim::grid_cell(double p_x, double p_z) const {
	int gx = (int)std::floor(p_x / GCELL), gz = (int)std::floor(p_z / GCELL);
	uint32_t h = (uint32_t)gx * 73856093u ^ (uint32_t)gz * 19349663u;
	return (int)(h & ((1u << GRID_BITS) - 1));
}
void Sim::grid_build() {
	std::memset(grid_head, 0xFF, sizeof(grid_head));
	for (int i = 0; i < n_slots; i++) {
		if (!alive[i] || tier[i] == TIER_FAR || (flags[i] & F_HIDDEN)) continue;
		int c = grid_cell(x[i], z[i]);
		grid_next[i] = grid_head[c]; grid_head[c] = i;
	}
	for (int k = 0; k < n_dyn; k++) {
		int c = grid_cell(dyn_x[k], dyn_z[k]);
		grid_next[MAX_AGENTS + k] = grid_head[c]; grid_head[c] = MAX_AGENTS + k;
	}
}

// ------------------------------------------------------------------ the step
// A place that is no place any more (a bench somebody drove over): nobody is sent there, whoever sits there gets up.
bool Sim::disable_place(int p_place) {
	if (p_place < 0 || p_place >= n_places) return false;
	pl_w[p_place] = -1.0f; pl_occ[p_place] = 0;
	for (int i = 0; i < n_slots; i++)
		if (alive[i] && goal_tag[i] == p_place && state[i] == S_STAY) dwell[i] = 0.0f;
	return true;
}

// ------------------------------------------------------------------ meetings
// Somebody who may stop for an acquaintance: walking alone on the pavement, in the tier next to the player (a meeting
// nobody sees is not worth a stop), not running from anything, not met anybody for a while.
bool Sim::can_meet(int k) const {
	return !guest[k] && state[k] == S_WALK && act[k] == A_NONE && party[k] == 0 && lead[k] < 0 && tier[k] == TIER_FULL && pkind[k] != PK_JOGGER
			&& !(flags[k] & (F_ON_LINK | F_HIDDEN | F_YIELD)) && meet_cd[k] <= 0.0f && flee_t[k] <= 0.0f
			&& seg[k] >= 0 && seg_kind[seg[k]] == SEG_WALK;
}

// The two stop where they are, face each other and stay for the same time (a street pause: both walk on along their own
// routes after). What they do comes from the pair's hash, so the same two always do the same: a wave in passing, a chat,
// an embrace (they step up to each other first) followed by a chat, or a quarrel.
void Sim::start_meet(int a, int b, uint32_t p_hash, double p_ahead, double p_side) {
	const uint32_t r = (p_hash >> 8) % 100u;
	const int kind = (cfg.meet_force >= A_GREET && cfg.meet_force <= A_HUG) ? cfg.meet_force : (r < 40 ? A_GREET : (r < 78 ? A_CHAT : (r < 90 ? A_HUG : A_ARGUE)));
	const double u = (double)((p_hash >> 16) % 1000u) / 1000.0;
	const float dur = kind == A_GREET ? 1.8f : (kind == A_HUG ? 3.2f : (kind == A_CHAT ? (float)(7.0 + 9.0 * u) : (float)(5.0 + 5.0 * u)));
	const int pair[2] = { a, b };
	for (int q = 0; q < 2; q++) {
		const int k = pair[q], o = pair[1 - q];
		if (kind == A_HUG && p_ahead > 0.6) pd[k] += (float)((p_ahead - 0.55) * 0.5);   // each steps up to the other
		// each passes on the other's left or right by the same amount: half a sidestep brings them face to face
		if (kind != A_GREET) lat_t[k] = (float)std::min(std::max((double)lat[k] + p_side * 0.5, -(double)half_w[k]), (double)half_w[k]);
		state[k] = S_STAY; pausing[k] = 1; why[k] = W_DWELL; dwell[k] = dur; v[k] = 0.0f;
		flags[k] |= F_FACE; face_yaw[k] = (float)std::atan2((double)x[o] - x[k], (double)z[o] - z[k]);
		act[k] = (uint8_t)kind;
		meet_x[k] = (kind == A_ARGUE && (double)((p_hash >> 4) % 1000u) < cfg.fight_p * 1000.0) ? 1 : 0;
		meet_cd[k] = (float)rndf(90.0, 240.0);
	}
	emit(E_MEET, id[a], a, id[b]);
}

// Other walkers and dynamics ahead: pick the sideways target and cap the speed. Geometry is in the walker's own frame:
// `ahead` along its heading, `side` to its left.
void Sim::interact(int i, double p_dt, double &r_v) {
	(void)p_dt;
	const double hw = half_w[i];
	const double base = -cfg.keep_right * hw + ((double)(seed[i] & 255) / 255.0 - 0.5) * 0.3 * hw;
	double want = base;
	const double need = 2.0 * cfg.body_r + 0.14;
	bool passing = false, dodge = false;
	const double hx = fx[i], hz = fz[i];           // heading
	const double lx = hz, lz = -hx;                // left
	int gx0 = (int)std::floor(x[i] / GCELL), gz0 = (int)std::floor(z[i] / GCELL);
	for (int dzc = -1; dzc <= 1; dzc++) for (int dxc = -1; dxc <= 1; dxc++) {
		uint32_t h = (uint32_t)(gx0 + dxc) * 73856093u ^ (uint32_t)(gz0 + dzc) * 19349663u;
		for (int j = grid_head[h & ((1u << GRID_BITS) - 1)]; j >= 0; j = grid_next[j]) {
			if (j == i) continue;
			if (j < MAX_AGENTS && party[i] != 0 && party[j] == party[i]) continue;   // my own company
			double ox, oz, orad, ovx = 0.0, ovz = 0.0;
			bool is_dyn = j >= MAX_AGENTS, standing;
			if (is_dyn) {
				int k = j - MAX_AGENTS;
				ox = dyn_x[k]; oz = dyn_z[k]; orad = dyn_r[k]; ovx = dyn_vx[k]; ovz = dyn_vz[k];
				standing = ovx * ovx + ovz * ovz < 0.04;
			} else {
				ox = x[j]; oz = z[j]; orad = cfg.body_r;
				standing = state[j] != S_WALK || v[j] < 0.2f;
				if (!standing) { ovx = fx[j] * v[j]; ovz = fz[j] * v[j]; }
			}
			double rx = ox - x[i], rz = oz - z[i];
			double ahead = rx * hx + rz * hz, side = rx * lx + rz * lz;
			double room = cfg.body_r + orad + 0.14;
			// a beggar at their spot, a lone passer-by next to the player: some people always give
			if (!is_dyn && act[j] == A_BEG && state[j] == S_STAY && ahead > 0.2 && ahead < 1.8 && std::fabs(side) < 1.8
					&& state[i] == S_WALK && act[i] == A_NONE && party[i] == 0 && lead[i] < 0 && tier[i] == TIER_FULL && meet_cd[i] <= 0.0f
					&& !(flags[i] & (F_ON_LINK | F_HIDDEN))) {
				uint32_t h = (seed[i] * 2654435761u) ^ (seed[j] * 40503u); h ^= h >> 15; h *= 2246822519u; h ^= h >> 13;
				if ((double)(h % 1000u) < cfg.give_p * 1000.0) {
					state[i] = S_STAY; pausing[i] = 1; why[i] = W_DWELL; dwell[i] = 2.2f; v[i] = 0.0f;
					flags[i] |= F_FACE; face_yaw[i] = (float)std::atan2(rx, rz);
					act[i] = A_GIVE; meet_cd[i] = (float)rndf(60.0, 120.0);
					emit(E_GIVE, id[i], i, id[j]);
					r_v = 0.0;
					return;
				}
				meet_cd[i] = 4.0f;
			}
			// two lone walkers about to pass each other (each on its own side of the pavement), close to the player: do
			// they know each other?
			if (!is_dyn && cfg.meet_p > 0.0 && ahead > 0.3 && ahead < 1.3 && std::fabs(side) < 2.2
					&& (double)fx[i] * fx[j] + (double)fz[i] * fz[j] < -0.5 && can_meet(i) && can_meet(j)) {
				const uint32_t lo = std::min(seed[i], seed[j]), hi = std::max(seed[i], seed[j]);
				uint32_t h = (lo * 2654435761u) ^ (hi * 40503u); h ^= h >> 15; h *= 2246822519u; h ^= h >> 13;
				if ((double)(h % 1000u) < cfg.meet_p * 1000.0) { start_meet(i, j, h, ahead, side); r_v = 0.0; return; }
				meet_cd[i] = meet_cd[j] = 5.0f;   // strangers: not asked again while they pass
			}
			if (ahead < -0.25 || ahead > cfg.look_ahead + orad) continue;
			if (std::fabs(side) > room + 0.35) continue;
			if (!is_dyn && !standing) {
				double d = std::sqrt(rx * rx + rz * rz);
				if (d < stats.min_gap) stats.min_gap = d;
			}
			double o_along = ovx * hx + ovz * hz;      // the other's speed along my heading
			// veto: a body right in front (whatever it does) is never walked into; after 1.5 s of standing face to face
			// with no way round the walker squeezes past (two people in a 1 m gap do the same)
			// (19 Nov, the city kit map's narrow pavements: people who wait at a kerb, and those who stand behind them, are
			// a queue. Nobody squeezes through a queue that faces the same way: the next one stands behind.)
			const bool queue = !is_dyn && standing && (state[j] == S_WAIT || (state[j] == S_WALK && why[j] == W_BLOCKED))
					&& (double)fx[i] * fx[j] + (double)fz[i] * fz[j] > 0.3;
			if (ahead > 0.0 && ahead < cfg.body_r + orad + 0.22 && std::fabs(side) < (cfg.body_r + orad) * 0.92 && (blocked_s[i] < 1.5f || queue)) {
				double keep = ahead < cfg.body_r + orad + 0.05 ? 0.3 : 0.85;   // too close: drop back, else just a little slower
				r_v = std::min(r_v, std::max(o_along, 0.0) * (standing ? 1.0 : keep)); why[i] = standing ? W_BLOCKED : W_FOLLOW;
			}
			bool same = !standing && o_along > 0.3 * std::max(0.3, (double)v_des[i]);
			bool oncoming = !standing && o_along < -0.2;
			if (is_dyn && dyn_kind[j - MAX_AGENTS] == DYN_CAR) {
				// never walk into a vehicle: stop short of it, whatever it does
				if (ahead < orad + 0.9 && std::fabs(side) < orad + 0.3) { r_v = 0.0; why[i] = W_BLOCKED; }
				// a car coming at them: a step aside, away from its side, as far as the pavement goes
				// (off the pavement if it has to be: a car on the pavement leaves no room on it)
				if (o_along < -1.0 && ahead < 9.0 && std::fabs(side) < orad + 1.2) {
					dodge = true;
					want = (double)lat[i] + (side >= 0.0 ? -1.7 : 1.7);
					lat_extra[i] = 1.6f;
				}
				continue;
			}
			if (same) {
				if (o_along >= v_des[i] - 0.12) continue;      // not slower than me: nothing to do
				double tgt = lat[i] + side + room;             // pass on its left
				if (tgt <= hw) { want = std::max(want, tgt); passing = true; }
				else if (ahead < 1.3) { r_v = std::min(r_v, std::max(o_along, 0.0)); why[i] = W_FOLLOW; stats.follows++; }
				continue;
			}
			// standing or oncoming: go round on the side with room, right first for oncoming (both keep right)
			double tr = lat[i] + side - room, tl = lat[i] + side + room;
			// (19 Nov: where the pavement is too narrow to go round somebody who stands, the walker takes half a step
			// off its edge after a moment, as people step off a kerb; the old way was to walk through after 1.5 s)
			const double ex = (!is_dyn && standing && !queue && (blocked_s[i] > 0.7f || lat_extra[i] > 0.05f)) ? 0.45 : 0.0;
			bool can_r = tr >= -(hw + ex), can_l = tl <= hw + ex;
			bool go_r = oncoming ? can_r : (side >= 0.0 ? can_r : !can_l && can_r);
			if (go_r) { want = std::min(want, tr); if (tr < -hw) { lat_extra[i] = 0.45f; dodge = true; } }
			else if (can_l) { want = std::max(want, tl); if (tl > hw) { lat_extra[i] = 0.45f; dodge = true; } }
			else if (ahead < room + 0.35) {
				r_v = oncoming ? r_v * 0.4 : 0.0; why[i] = W_BLOCKED;
				if (is_dyn && dyn_kind[j - MAX_AGENTS] == DYN_PLAYER && !(flags[i] & F_YIELD)) emit(E_BUMP, id[i], i, 0);
				flags[i] |= F_YIELD;
			}
		}
	}
	// A car heading for this walker is seen early (the neighbour cells above only reach a few metres): from where it
	// will be in under two seconds the walker steps aside, off the pavement if it has to be.
	if (tier[i] == TIER_FULL) {
		for (int k = 0; k < n_dyn; k++) {
			if (dyn_kind[k] != DYN_CAR) continue;
			const double rx = (double)dyn_x[k] - x[i], rz = (double)dyn_z[k] - z[i];
			const double ahead = rx * hx + rz * hz, side = rx * lx + rz * lz;
			if (ahead < 0.5 || std::fabs(side) > dyn_r[k] + 1.2) continue;
			const double closing = -((double)dyn_vx[k] * hx + (double)dyn_vz[k] * hz);   // m/s towards the walker
			if (closing < 1.0 || ahead > 3.0 + closing * 1.9) continue;
			dodge = true;
			want = (double)lat[i] + (side >= 0.0 ? -1.7 : 1.7);
			lat_extra[i] = 1.6f;
			break;
		}
	}
	(void)need;
	if (passing) { if (!(flags[i] & F_PASSING)) stats.passes++; flags[i] |= F_PASSING; }
	else flags[i] &= ~F_PASSING;
	if (!dodge && lat_extra[i] > 0.0f) lat_extra[i] = std::max(0.0f, lat_extra[i] - (float)p_dt * 0.8f);   // back onto the pavement
	const double lim = hw + lat_extra[i];
	lat_t[i] = (float)std::min(std::max(want, -lim), lim);
}

void Sim::advance(int i, double p_dt) {
	pd[i] += (float)(v[i] * p_dt);
	for (int guard = 0; guard < 64; guard++) {
		int last = p_n[i] - 1;
		if (pi[i] < last) {
			const float *a = leg_pt(i, pi[i]), *b = leg_pt(i, pi[i] + 1);
			float l = std::sqrt((b[0] - a[0]) * (b[0] - a[0]) + (b[2] - a[2]) * (b[2] - a[2]));
			if (pd[i] > l) { pd[i] -= l; pi[i]++; continue; }
			return;
		}
		float carry = pd[i];
		if (!next_leg(i)) return;
		if (state[i] != S_WALK) { pd[i] = 0.0f; return; }
		pd[i] = carry;
	}
}

void Sim::place(int i, double p_dt) {
	int last = p_n[i] - 1;
	int k0 = std::min(pi[i], std::max(last, 0)), k1 = std::min(pi[i] + 1, std::max(last, 0));
	const float *a = leg_pt(i, k0), *b = leg_pt(i, k1);
	double dx = (double)b[0] - a[0], dz = (double)b[2] - a[2];
	double l = std::sqrt(dx * dx + dz * dz);
	if (l < 1e-4 && k0 > 0) {            // at the very end of a leg: heading from the previous pair
		const float *p = leg_pt(i, k0 - 1);
		dx = (double)a[0] - p[0]; dz = (double)a[2] - p[2];
		double l2 = std::sqrt(dx * dx + dz * dz);
		if (l2 > 1e-4) { dx /= l2; dz /= l2; fx[i] = (float)dx; fz[i] = (float)dz; }
	} else if (l >= 1e-4) {
		fx[i] = (float)(dx / l); fz[i] = (float)(dz / l);
	}
	double f = l > 1e-4 ? std::min(std::max((double)pd[i] / l, 0.0), 1.0) : 0.0;
	double ncx = a[0] + ((double)b[0] - a[0]) * f, ncz = a[2] + ((double)b[2] - a[2]) * f;
	// sideways towards the target lane
	if (p_dt > 0.0) {
		double dl = lat_t[i] - lat[i], st = cfg.lat_speed * (lat_extra[i] > 0.0f ? 2.6 : 1.0) * p_dt;   // a dodge is a quick step
		lat[i] += (float)(dl > st ? st : (dl < -st ? -st : dl));
	}
	double hwc = half_w[i] + lat_extra[i];
	if (lat[i] > hwc) lat[i] = (float)hwc;
	if (lat[i] < -hwc) lat[i] = (float)-hwc;
	double nx = ncx + (double)fz[i] * lat[i], nz = ncz - (double)fx[i] * lat[i];
	// feet height: the road mesh height carried by the path where it has one, else / plus the drawn ground
	bool ha = !std::isnan(a[1]), hb = !std::isnan(b[1]);
	double ref = ha && hb ? a[1] + ((double)b[1] - a[1]) * f : (ha && f * l < 0.25 ? a[1] : (hb && (1.0 - f) * l < 0.25 ? b[1] : NAN));
	bool has_ref = !std::isnan(ref);
	double ny;
	if (ground_fn && (tier[i] != TIER_FAR || ((nx - view_x) * (nx - view_x) + (nz - view_z) * (nz - view_z) < cfg.ground_r * cfg.ground_r))) {
		double gdx = nx - gy_x[i], gdz = nz - gy_z[i];
		if (gdx * gdx + gdz * gdz > 0.04) {
			// Off the walk graph (the link to a door, a bench, a spot on the sand) the feet are on the drawn ground, whatever
			// height the link's points carry: those are the walkway's height at the graph end, and a link that runs down
			// to the beach at that height left people walking 2-7 m up in the air. Never deeper than wading depth.
			const bool on_link = (flags[i] & F_ON_LINK) != 0;
			const bool use_ref = has_ref && !on_link;
			double g = ground_fn(ground_user, nx, nz, use_ref ? ref : 0.0, use_ref);
			if (on_link && !std::isnan(g) && g < -1.0) {
				// the link runs over open water (a spot on the far side of the lagoon): this walker wades the rest, and
				// nobody is sent to that place again
				gy[i] = -0.6f;
				if (goal_tag[i] >= 0 && goal_tag[i] < n_places) pl_w[goal_tag[i]] = -1.0f;
			} else if (!std::isnan(g)) gy[i] = (float)(on_link ? std::max(g, -0.6) : g);
			else if (has_ref) gy[i] = (float)ref;
			gy_x[i] = (float)nx; gy_z[i] = (float)nz;
		}
		ny = gy[i];
	} else {
		ny = has_ref ? ref : gy[i];
	}
	if (p_dt > 0.0) {
		double mx = nx - x[i], mz = nz - z[i];
		double sp = std::sqrt(mx * mx + mz * mz) / p_dt;
		v_ema[i] += (float)((sp - v_ema[i]) * std::min(1.0, p_dt * 6.0));
		// turn towards the heading, frame-rate independent (the old crowd turned 25 % a frame at 60 fps)
		double ty = (flags[i] & F_FACE) ? (double)face_yaw[i] : std::atan2((double)fx[i], (double)fz[i]);
		yaw[i] = (float)wrap_pi(yaw[i] + wrap_pi(ty - yaw[i]) * (1.0 - std::exp(-p_dt * 17.0)));
	}
	if (v_ema[i] > 0.25f && state[i] == S_WALK) flags[i] |= F_MOVING; else flags[i] &= ~F_MOVING;
	x[i] = (float)nx; y[i] = (float)ny; z[i] = (float)nz; cx[i] = (float)ncx; cz[i] = (float)ncz;
	if (party[i] != 0 && lead[i] < 0) {
		int last_i = (trail_head[i] - 1 + TRAIL_N) % TRAIL_N;
		double tx = ncx - trail_x[i][last_i], tz = ncz - trail_z[i][last_i];
		if (trail_len[i] == 0 || tx * tx + tz * tz >= (double)TRAIL_STEP * TRAIL_STEP) {
			int h = trail_head[i];
			trail_x[i][h] = (float)ncx; trail_z[i][h] = (float)ncz; trail_fx[i][h] = fx[i]; trail_fz[i][h] = fz[i];
			trail_head[i] = (uint8_t)((h + 1) % TRAIL_N);
			if (trail_len[i] < TRAIL_N) trail_len[i]++;
		}
	}
}

// ------------------------------------------------------------------ conversations
// The party nearest the player (walking together or standing in a circle, within talk_r) talks: one conversation
// from the data that fits where they are, its lines said in turn by its members, then a pause before the next
// one. The core only says who speaks which line (E_SAY); the script shows the caption and plays the voice.
void Sim::talk_tick(double p_dt) {
	if (conv_lines.empty() || player_x > BIG * 0.5) return;
	talk_t -= p_dt;
	if (talk_t > 0.0) return;
	// the members of the talking party that are still there, nearest first is not needed: by slot
	auto members_of = [&](int pid, int *out, int cap) {
		int n = 0;
		for (int i = 0; i < n_slots && n < cap; i++) if (alive[i] && party[i] == pid && !(flags[i] & F_HIDDEN)) out[n++] = i;
		return n;
	};
	int m[8];
	if (talk_conv >= 0) {
		int n = members_of(talk_party, m, 8);
		bool near = false;
		for (int k = 0; k < n; k++) { double dx = x[m[k]] - player_x, dz = z[m[k]] - player_z; if (dx * dx + dz * dz < (cfg.talk_r + 5.0) * (cfg.talk_r + 5.0)) near = true; }
		if (n >= 2 && near && talk_line < conv_lines[talk_conv]) {
			int sp = m[talk_line % n];
			emit(E_SAY, id[sp], sp, (double)(talk_conv * 64 + talk_line));
			talk_line++;
			talk_t = cfg.talk_line_s;
			return;
		}
		talk_conv = -1; talk_party = 0;
		talk_t = rndf(cfg.talk_gap_lo, cfg.talk_gap_hi);
		return;
	}
	// a new conversation: the nearest party of two or more within talk_r
	int best = -1; double bd = cfg.talk_r * cfg.talk_r;
	for (int i = 0; i < n_slots; i++) {
		if (!alive[i] || party[i] == 0 || lead[i] >= 0 || (flags[i] & F_HIDDEN) || flee_t[i] > 0.0f || act[i] == A_DUCK) continue;
		double dx = x[i] - player_x, dz = z[i] - player_z, d = dx * dx + dz * dz;
		if (d < bd) { bd = d; best = i; }
	}
	if (best < 0 || members_of(party[best], m, 8) < 2) { talk_t = 2.0; return; }
	const uint32_t zbit = 1u << std::min<int>(zone[best], 30);
	int pick = -1, seen = 0;
	for (int c = 0; c < (int)conv_lines.size(); c++) {
		if (conv_lines[c] <= 0 || (conv_zones[c] != 0 && !((uint32_t)conv_zones[c] & zbit))) continue;
		seen++;
		if ((int)(rnd() % (uint32_t)seen) == 0) pick = c;   // one of the fitting ones, each as likely
	}
	if (pick < 0) { talk_t = 5.0; return; }
	talk_party = party[best]; talk_conv = pick; talk_line = 0; talk_t = 0.0;
}

// ------------------------------------------------------------------ buses
// A bus is standing at a stop. Whoever waits at that stop walks to its front door and is gone (boarded); the first
// time the bus is seen there, up to two people get off: they appear at the door and walk to the pavement, then on to a
// goal of their own. The door is on the kerb side (right of the heading), 1.6 m behind the front.
void Sim::bus_tick() {
	if (bus_places.empty() && n_places > 0) {
		for (int p = 0; p < n_places; p++) if (pl_kind[p] == PL_BUS) bus_places.push_back(p);
		if (bus_places.empty()) bus_places.push_back(-1);   // no stops in the data: do not scan again
	}
	const int nb = (int)(buses.size() / 7);
	std::vector<int32_t> now;
	for (int b = 0; b < nb; b++) {
		const float *r = buses.data() + (size_t)b * 7;
		const int bid = (int)r[0];
		now.push_back(bid);
		const double dx = r[1] + r[3] * (r[5] - 1.6) - r[4] * (r[6] + 0.35), dz = r[2] + r[4] * (r[5] - 1.6) + r[3] * (r[6] + 0.35);
		int stop = -1; double bd = 14.0 * 14.0;
		for (int p : bus_places) {
			if (p < 0) continue;
			double sx = pl_x[p] - dx, sz = pl_z[p] - dz, d = sx * sx + sz * sz;
			if (d < bd) { bd = d; stop = p; }
		}
		if (stop < 0) continue;
		// boarding: everybody who came to wait at this stop and is still waiting
		for (int i = 0; i < n_slots; i++) {
			if (!alive[i] || state[i] != S_STAY || goal_tag[i] != stop || lead[i] >= 0 || (flags[i] & (F_ENTER | F_HIDDEN))) continue;
			const float lk[6] = { x[i], NAN, z[i], (float)dx, NAN, (float)dz };
			if (set_goal(id[i], pl_node[stop], lk, 2, 0.0, true, false, -1)) boarded++;
		}
		// getting off: once per stop
		bool served = false;
		for (int32_t s : buses_served) if (s == bid) { served = true; break; }
		if (served) continue;
		buses_served.push_back(bid);
		const int n0 = pl_node[stop];
		const int n_off = hour < 6.0 ? (int)(rnd() % 2u) : (int)(rnd() % 3u);
		for (int k = 0; k < n_off; k++) {
			int i = make_walker(node_zone[n0]);
			if (i < 0) break;
			const float lk[6] = { node_x[n0], NAN, node_z[n0], (float)dx, NAN, (float)dz };   // node -> door; walked backwards
			back[i].assign(lk, lk + 6);
			link_node[i] = n0;
			link_phase[i] = 3;
			leg_from_link(i, true);
			place(i, 0.0);
			yaw[i] = (float)std::atan2((double)fx[i], (double)fz[i]);
			if (!choose_goal(i)) { kill(i, DESPAWN_LOST); continue; }
			link_phase[i] = 3;
			leg_from_link(i, true);
			pd[i] = -(float)k * 0.9f;   // one after the other out of the door, not on top of each other
			emit(E_SPAWN, id[i], i, zone[i]);
			alighted++;
		}
	}
	// a bus that left its stop may be served again at the next one
	std::vector<int32_t> keep;
	for (int32_t s : buses_served) for (int32_t q : now) if (q == s) { keep.push_back(s); break; }
	buses_served.swap(keep);
}

void Sim::step(double p_dt) {
	if (p_dt <= 0.0 || nn == 0) return;
	clock += p_dt;
	bus_acc += p_dt;
	if (bus_acc >= 0.5) { bus_acc = 0.0; bus_tick(); }
	talk_tick(p_dt);
	// tiers
	stats.tier_n[0] = stats.tier_n[1] = stats.tier_n[2] = 0;
	const double pxr = player_x < BIG * 0.5 ? player_x : view_x, pzr = player_z < BIG * 0.5 ? player_z : view_z;
	const double f2 = cfg.full_r * cfg.full_r, m2 = cfg.mid_r * cfg.mid_r;
	for (int i = 0; i < n_slots; i++) {
		if (!alive[i]) continue;
		double dx = x[i] - pxr, dz = z[i] - pzr, d2 = dx * dx + dz * dz;
		tier[i] = d2 < f2 ? TIER_FULL : (d2 < m2 ? TIER_MID : TIER_FAR);
		stats.tier_n[tier[i]]++;
	}
	pop_acc += p_dt;
	if (tick_n == 0 || pop_acc >= cfg.pop_tick_s) { pop_acc = 0.0; population(); }
	grid_build();
	for (int i = 0; i < n_slots; i++) {
		if (!alive[i]) continue;
		if (guest[i]) { guest_move(i, p_dt); continue; }
		double dt = p_dt;
		int ph = lead[i] >= 0 ? lead[i] : i;   // a follower updates in the frames its leader does
		if (tier[ph] == TIER_MID) { if ((ph + tick_n) & 1) continue; dt = p_dt * 2.0; }
		else if (tier[ph] == TIER_FAR) { if ((ph + tick_n) & 3) continue; dt = p_dt * 4.0; }
		if (lead[i] >= 0) {
			if (!alive[lead[i]]) { kill(i, DESPAWN_LEFT); continue; }
			follow(i, dt);
			continue;
		}
		if (state[i] == S_STAY) {
			if (cfg.rain > 0.5 && dwell[i] > 6.0f && (act[i] == A_BENCH || (act[i] >= A_REST_SIT && act[i] <= A_REST_FRONT)))
				dwell[i] = (float)rndf(1.0, 6.0);   // it started to rain: up from the bench / the sand within seconds
			dwell[i] -= (float)dt;
			if (dwell[i] > 0.0f) { place(i, dt); continue; }
			if (act[i] == A_DOOR) { kill(i, DESPAWN_DOOR); continue; }
			if (pausing[i]) {   // a street pause is over: on along the same route
				if (act[i] == A_HUG) { act[i] = A_CHAT; dwell[i] = 7.0f; place(i, dt); continue; }   // after the embrace they talk
				if (act[i] == A_ARGUE && meet_x[i]) {   // the quarrel comes to blows, a few seconds
					act[i] = A_FIGHT; dwell[i] = 4.0f; meet_x[i] = 0;
					emit(E_FIGHT, id[i], i, 0);
					place(i, dt);
					continue;
				}
				if (act[i] == A_FIGHT) flee_t[i] = 4.0f;   // and both hurry off
				pausing[i] = 0; state[i] = S_WALK; why[i] = W_NONE; flags[i] &= ~F_FACE;
				if (act[i] == A_DUCK) { act[i] = A_NONE; flee_t[i] = 6.0f; }   // up again, and away from here
				else if (act[i] >= A_GREET && act[i] <= A_DRINK) act[i] = A_NONE;   // the meeting / the look / the drink is over: on along the route
				place(i, dt);
				continue;
			}
			if (!(flags[i] & F_NEED)) {
				flags[i] |= F_NEED; need_s[i] = (float)cfg.need_goal_wait_s;
				emit(E_NEED_GOAL, id[i], i, node_at_leg_end(i));
			} else {
				need_s[i] -= (float)dt;
				if (need_s[i] <= 0.0f) {
					bool at_door = (flags[i] & F_ON_LINK) != 0;
					if (at_door) back[i] = link[i];
					if (!choose_goal(i)) { kill(i, DESPAWN_LOST); continue; }
					if (at_door) { link_phase[i] = 3; leg_from_link(i, true); }
					else if (!next_leg(i)) continue;
				}
			}
			place(i, dt);
			continue;
		}
		if (state[i] == S_WAIT) {
			wait_s[i] += (float)dt;
			if (why[i] == W_SIGNAL) {
				int c = wait_ctl[i];
				if (c < 0 || c >= (int)ctl_green.size() || ((ctl_green[c] >> wait_ap[i]) & 1u) || wait_s[i] > 120.0f) { state[i] = S_WALK; why[i] = W_NONE; }
			} else if (why[i] == W_LOOK) {
				dwell[i] -= (float)dt;
				if (dwell[i] <= 0.0f) { why[i] = W_GAP; wait_s[i] = 0.0f; }
			} else {
				if (seg[i] < 0 || gap_clear(seg[i]) || wait_s[i] > cfg.gap_max_wait_s) { state[i] = S_WALK; why[i] = W_NONE; }
			}
			place(i, dt);
			continue;
		}
		// walking. Now and then somebody stops for a phone call, or to look into the window of a shop they pass
		if (meet_cd[i] > 0.0f) meet_cd[i] -= (float)dt;
		if (cfg.pauses && pkind[i] != PK_JOGGER && tier[i] != TIER_FAR && !(flags[i] & (F_ON_LINK | F_HIDDEN)) && seg[i] >= 0
				&& seg_kind[seg[i]] == SEG_WALK) {
			pause_t[i] -= (float)dt;
			if (pause_t[i] <= 0.0f) {
				const bool rain = cfg.rain > 0.5;
				pause_t[i] = (float)(rndf(cfg.pause_lo_s, cfg.pause_hi_s) * (rain ? 0.4 : 1.0));
				// a party near the player stops to stand together and talk (a few of them at most at a time)
				if (party[i] != 0 && !rain && tier[i] == TIER_FULL && pkind[i] != PK_JOGGER && rndf() < cfg.circle_p) {
					int circles = 0;
					for (int j = 0; j < n_slots; j++) if (alive[j] && lead[j] < 0 && party[j] != 0 && state[j] == S_STAY && pausing[j] && act[j] == A_CHAT) circles++;
					if (circles < cfg.max_circles) {
						state[i] = S_STAY; pausing[i] = 1; why[i] = W_DWELL; dwell[i] = (float)rndf(18.0, 40.0); v[i] = 0.0f;
						act[i] = A_CHAT;
						place(i, dt);
						continue;
					}
				}
				double r = rndf();
				int shop = -1; double bd = 7.0 * 7.0;
				if (r < (rain ? 0.9 : 0.5))
					for (int p : pq) {
						if (pl_kind[p] != PL_SHOP || !place_open(p, hour)) continue;
						double sx = pl_x[p] - x[i], sz = pl_z[p] - z[i], d = sx * sx + sz * sz;
						if (d < bd && d > 1.0) { bd = d; shop = p; }
					}
				if (shop >= 0 || (!rain && r > 0.82)) {
					state[i] = S_STAY; pausing[i] = 1; v[i] = 0.0f;
					if (shop >= 0 && rain) {
						// sheltering at the shop front: longer, back to the window, watching the rain
						why[i] = W_WINDOW; dwell[i] = (float)rndf(12.0, 30.0);
						flags[i] |= F_FACE; face_yaw[i] = (float)std::atan2((double)x[i] - pl_x[shop], (double)z[i] - pl_z[shop]);
					} else if (shop >= 0) {
						why[i] = W_WINDOW; dwell[i] = (float)rndf(4.0, 9.0);
						flags[i] |= F_FACE; face_yaw[i] = (float)std::atan2((double)pl_x[shop] - x[i], (double)pl_z[shop] - z[i]);
						// a cafe, a bar, an ice-cream shop: every third one who stops there has a drink
						if (pl_flags.size() > (size_t)shop && (pl_flags[shop] & 1) && (seed[i] % 3u) == 0u) { act[i] = A_DRINK; dwell[i] = (float)rndf(14.0, 30.0); }
					} else {
						why[i] = W_PHONE; dwell[i] = (float)rndf(6.0, 14.0);
					}
					place(i, dt);
					continue;
				}
			}
		}
		double vv = v_des[i] * cfg.pace;
		if (flee_t[i] > 0.0f) { flee_t[i] -= (float)dt; vv = std::max(vv, 3.3); }
		why[i] = W_NONE; flags[i] &= ~F_YIELD;
		if (cfg.interact && tier[i] != TIER_FAR && !(flags[i] & F_HIDDEN)) interact(i, dt, vv);
		else lat_t[i] = (float)(-cfg.keep_right * half_w[i]);
		// ease the speed (people do not stop or start in one frame)
		double dv = vv - v[i], acc = (dv > 0 ? 1.6 : 3.5) * dt;
		v[i] += (float)(dv > acc ? acc : (dv < -acc ? -acc : dv));
		if (vv < 0.15) {
			blocked_s[i] += (float)dt;
			if (blocked_s[i] > cfg.stuck_despawn_s && !seen(x[i], z[i])) { kill(i, DESPAWN_LOST); continue; }
		} else blocked_s[i] = 0.0f;
		advance(i, dt);
		if (!alive[i]) continue;
		place(i, dt);
	}
	tick_n++;
}

// ------------------------------------------------------------------ tests
uint64_t Sim::state_hash() const {
	uint64_t h = 1469598103934665603ull;
	auto mix = [&](uint64_t v) { h ^= v; h *= 1099511628211ull; };
	for (int i = 0; i < n_slots; i++) {
		if (!alive[i]) continue;
		mix((uint64_t)id[i]); mix((uint64_t)(int64_t)std::llround((double)x[i] * 1000.0)); mix((uint64_t)(int64_t)std::llround((double)z[i] * 1000.0));
		mix(state[i]); mix((uint64_t)(int64_t)seg[i]); mix((uint64_t)pi[i]);
	}
	mix((uint64_t)stats.agents);
	return h;
}

// walkers near the player (both in the full tier, where people deal with each other) that stand inside each other
int Sim::audit_near() const {
	int n = 0;
	for (int i = 0; i < n_slots; i++) {
		if (!alive[i] || tier[i] != TIER_FULL || (flags[i] & F_HIDDEN)) continue;
		for (int j = i + 1; j < n_slots; j++) {
			if (!alive[j] || tier[j] != TIER_FULL || (flags[j] & F_HIDDEN)) continue;
			double ex = x[i] - x[j], ez = z[i] - z[j];
			if (ex * ex + ez * ez < (cfg.body_r * 1.2) * (cfg.body_r * 1.2)) n++;
		}
	}
	return n;
}

void Sim::audit(int &r_off_path, int &r_nan, int &r_overlap) const {
	r_off_path = r_nan = r_overlap = 0;
	for (int i = 0; i < n_slots; i++) {
		if (!alive[i]) continue;
		if (std::isnan(x[i]) || std::isnan(y[i]) || std::isnan(z[i])) { r_nan++; continue; }
		double dx = x[i] - cx[i], dz = z[i] - cz[i];
		if (std::sqrt(dx * dx + dz * dz) > half_w[i] + 0.6) r_off_path++;
		if (tier[i] == TIER_FAR || (flags[i] & F_HIDDEN)) continue;
		for (int j = i + 1; j < n_slots; j++) {
			if (!alive[j] || tier[j] == TIER_FAR || (flags[j] & F_HIDDEN)) continue;
			double ex = x[i] - x[j], ez = z[i] - z[j];
			if (ex * ex + ez * ez < (cfg.body_r * 1.2) * (cfg.body_r * 1.2)) r_overlap++;
		}
	}
}

// ------------------------------------------------------------------ guests
void Sim::guests_begin() {
	size_t w = 0;
	for (size_t k = 0; k < guests.size(); k++) {
		const int s = guests[k];
		if (alive[s] && guest[s]) { g_seen[s] = 0; guests[w++] = s; }
	}
	guests.resize(w);
}
int Sim::guest_find(int p_ext) const {
	for (int s : guests) if (guest_of[s] == p_ext) return s;
	return -1;
}
// where the other system has its walker now; a new one gets a slot. -> slot, -1 = no room
int Sim::guest_set(int p_ext, double p_x, double p_y, double p_z, double p_yaw, double p_speed, bool p_moving, uint32_t p_seed) {
	int i = guest_find(p_ext);
	if (i < 0) {
		i = make_walker(1);
		if (i < 0) return -1;
		guest[i] = 1; guest_of[i] = p_ext; guests.push_back(i);
		seed[i] = p_seed; walk_ph[i] = (float)(p_seed % 997u) / 997.0f;
		x[i] = cx[i] = (float)p_x; y[i] = (float)p_y; z[i] = cz[i] = (float)p_z;
		yaw[i] = (float)p_yaw; fx[i] = (float)std::sin(p_yaw); fz[i] = (float)std::cos(p_yaw);
		v_des[i] = (float)p_speed; v[i] = v_ema[i] = p_moving ? (float)p_speed : 0.0f;
		meet_cd[i] = BIG;
		if (p_moving) flags[i] |= F_MOVING;
	}
	g_seen[i] = 1;
	g_tx[i] = (float)p_x; g_ty[i] = (float)p_y; g_tz[i] = (float)p_z; g_tyaw[i] = (float)p_yaw;
	g_sp[i] = (float)p_speed; g_mv[i] = p_moving ? 1 : 0;
	return i;
}
void Sim::guests_end() {
	for (int s : guests)
		if (!g_seen[s]) { kill(s, DESPAWN_FAR); guest[s] = 0; }
}
// every frame: towards where the other system has it (it steps at its own, slower rate), feet on the drawn ground
void Sim::guest_move(int i, double p_dt) {
	if (flags[i] & F_FACE) {   // somebody talks to it: it stands and turns to them
		state[i] = S_STAY; why[i] = W_DWELL; v[i] = 0.0f; v_ema[i] *= 0.8f; flags[i] &= ~F_MOVING;
		const double d = wrap_pi(face_yaw[i] - yaw[i]), st = 6.0 * p_dt;
		yaw[i] = (float)wrap_pi(yaw[i] + (d > st ? st : (d < -st ? -st : d)));
		fx[i] = std::sin(yaw[i]); fz[i] = std::cos(yaw[i]);
		return;
	}
	const double dx = (double)g_tx[i] - x[i], dz = (double)g_tz[i] - z[i], d = std::sqrt(dx * dx + dz * dz);
	if (d > 6.0) { x[i] = g_tx[i]; z[i] = g_tz[i]; }   // moved by a cut, not by walking
	else if (d > 1.0e-4) {
		const double sp = std::max((double)g_sp[i], d / 0.12), st = std::min(d, sp * p_dt);
		x[i] += (float)(dx / d * st); z[i] += (float)(dz / d * st);
	}
	cx[i] = x[i]; cz[i] = z[i];
	const float vt = g_mv[i] ? g_sp[i] : 0.0f;
	v[i] = vt; v_ema[i] += (vt - v_ema[i]) * (float)std::min(1.0, p_dt * 8.0);
	if (g_mv[i]) { flags[i] |= F_MOVING; state[i] = S_WALK; why[i] = W_NONE; }
	else { flags[i] &= ~F_MOVING; state[i] = S_WAIT; why[i] = W_SIGNAL; }
	const double dy = wrap_pi(g_tyaw[i] - yaw[i]), ys = 8.0 * p_dt;
	yaw[i] = (float)wrap_pi(yaw[i] + (dy > ys ? ys : (dy < -ys ? -ys : dy)));
	fx[i] = std::sin(yaw[i]); fz[i] = std::cos(yaw[i]);
	// the other system's height is its path's; the drawn pavement / verge beside it may be a little higher
	float lift = 0.0f;
	const double px = x[i] - (player_x < BIG * 0.5 ? player_x : view_x), pz = z[i] - (player_z < BIG * 0.5 ? player_z : view_z);
	if (ground_fn && px * px + pz * pz < cfg.ground_r * cfg.ground_r) {
		const double gx = x[i] - gy_x[i], gz = z[i] - gy_z[i];
		if (gx * gx + gz * gz > 0.04) {
			gy_x[i] = x[i]; gy_z[i] = z[i];
			const double g = ground_fn(ground_user, x[i], z[i], g_ty[i], true);
			gy[i] = std::isnan(g) ? 0.0f : (float)std::min(std::max(g - g_ty[i], 0.0), 1.0);
		}
		lift = gy[i];
	}
	y[i] = g_ty[i] + lift;
}

} // namespace cc
