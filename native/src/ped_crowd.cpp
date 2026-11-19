// The walking crowd: see ped_crowd.h. This file: the graph, the walking on the pavement's line, who appears and leaves.
#include "ped_crowd.h"

#include "ped_inl.h"
#include "street_build.h"

#include <chrono>
#include <cstring>

namespace pc {

int Crowd::cell_of(float p_x, float p_z) { return grid_ix((int)std::floor(p_x * 0.5f), (int)std::floor(p_z * 0.5f)); }

bool Crowd::build(const sg::StreetData &d) {
	built = false;
	node_xz = d.walk_node; pts = d.walk_pts;
	const int nn = (int)node_xz.size() / 2, ns = (int)d.walk_seg.size() / 8, np = (int)pts.size() / 3;
	if (nn <= 0 || ns <= 0 || (int)d.walk_seg_f.size() < ns * 2 || ns > 32000) return false;
	segs.assign(ns, Seg()); pts_s.assign(np, 0.0f); node_segs.assign(nn, std::vector<int32_t>());
	total_len = 0.0;
	for (int k = 0; k < ns; k++) {
		const int32_t *q = &d.walk_seg[(size_t)k * 8];
		Seg &S = segs[k];
		S.a = q[0]; S.b = q[1]; S.kind = q[2] ? 1 : 0; S.zone = std::min(std::max(q[3], 0), 4); S.node = q[4]; S.phase = q[5]; S.p0 = q[6]; S.np = q[7];
		S.hw = clampf(d.walk_seg_f[(size_t)k * 2 + 1], 0.5f, 3.0f);
		if (S.np < 2 || S.p0 < 0 || S.p0 + S.np > np || S.a < 0 || S.b < 0 || S.a >= nn || S.b >= nn) { S.np = 0; continue; }
		float acc = 0.0f;
		for (int p = 1; p < S.np; p++) {
			const float *a = &pts[(size_t)(S.p0 + p - 1) * 3], *b = a + 3;
			acc += std::sqrt((b[0] - a[0]) * (b[0] - a[0]) + (b[2] - a[2]) * (b[2] - a[2]));
			pts_s[S.p0 + p] = acc;
		}
		S.len = acc;
		if (S.len < 0.6f) { S.np = 0; continue; }
		int h = 0; float yy, tx_, tz_;
		at(S, S.len * 0.5f, 0.0f, h, S.mx, yy, S.mz, tx_, tz_);
		const int cx = (int)std::floor(S.mx / 200.0f) + 32, cz = (int)std::floor(S.mz / 200.0f) + 32;
		S.cell = (cx < 0 || cz < 0 || cx >= 64 || cz >= 64) ? -1 : cz * 64 + cx;
		node_segs[S.a].push_back(k); node_segs[S.b].push_back(k);
		if (S.kind == 0) total_len += S.len;
	}
	// a crossing's line runs from the middle of one pavement to the middle of the other: the kerb at each end is that
	// pavement's half width away (the usable half width + the quarter metre kept clear of the kerb)
	for (Seg &S : segs) {
		if (S.np < 2 || S.kind != 1) continue;
		for (int end = 0; end < 2; end++) {
			// the kerb it leaves from belongs to the pavement that runs ACROSS it (along the street it crosses): of the
			// pavements meeting at its end, the one most square to it (two pavements of different width meet at a corner)
			const int node = end ? S.b : S.a;
			const float *C = &pts[(size_t)(S.p0 + (end ? S.np - 2 : 0)) * 3];
			float cx = C[3] - C[0], cz = C[5] - C[2];
			const float cl = std::sqrt(cx * cx + cz * cz);
			if (cl > 1.0e-5f) { cx /= cl; cz /= cl; }
			float hwm = 0.75f, best = 2.0f;
			for (int k : node_segs[node]) {
				const Seg &P = segs[k];
				if (P.np < 2 || P.kind != 0) continue;
				const float *Q = &pts[(size_t)(P.p0 + (P.a == node ? 0 : P.np - 2)) * 3];
				float qx = Q[3] - Q[0], qz = Q[5] - Q[2];
				const float ql = std::sqrt(qx * qx + qz * qz);
				if (ql < 1.0e-5f) continue;
				const float along = std::fabs((qx * cx + qz * cz) / ql);
				if (along < best) { best = along; hwm = P.hw; }
			}
			(end ? S.kb : S.ka) = clampf(hwm + 0.25f, 0.6f, std::min(3.3f, S.len * 0.3f));
		}
	}
	// every junction's own start in the signal cycle, exactly as the traffic takes it (CityTraffic::load_streets)
	const int nj = (int)d.node_i.size() / 4;
	sig_off.assign(nj, 0.0f);
	for (int i = 0; i < nj; i++) {
		const int tx_ = d.node_i[(size_t)i * 4 + 2], tz_ = d.node_i[(size_t)i * 4 + 3];
		sig_off[i] = (float)((((tx_ * 7 + tz_ * 13) % 30) + 30) % 30);
	}
	pl_cost.assign(nn, BIG); pl_from.assign(nn, -1); pl_heap.reserve(nn + 8);
	seg_places.assign(ns, std::vector<int32_t>());
	built = true;
	reset(1);
	return true;
}

void Crowd::reset(uint64_t seed) {
	std::memset(alive, 0, sizeof(alive));
	hi = 0; n_alive = 0; next_id = 1; next_party = 1; tick = 0;
	rng = 0x9E3779B97F4A7C15ull ^ (seed * 0xD1B54A32D192ED03ull);
	if (rng == 0) rng = 1;
	st = Stats();
	cand_tick = -1000; cand.clear(); cand_w.clear(); door_cand.clear(); target = 0;
	for (int k = 0; k < GB; k++) g_head[k] = -1;
	events.clear(); buses.clear(); scares.clear();
	occ.assign(places.size(), -1);
	inside.assign(places.size(), 0);
	for (size_t p = 0; p < places.size(); p++) if (places[p].kind == PL_SHOP) inside[p] = (int16_t)(1 + hash32((uint32_t)p * 2654435761u) % 4u);   // (a shop is never empty at the start)
	if (place_off.size() != places.size()) place_off.assign(places.size(), 0);
	circles_now = 0; conv_cd = 5.0f; conv_party = 0; conv_t = 0.0f;
}

void Crowd::at(const Seg &S, float p_u, float p_ls, int &r_hint, float &r_x, float &r_y, float &r_z, float &r_tx, float &r_tz) const {
	const float *P = &pts[(size_t)S.p0 * 3];
	const float *D = &pts_s[S.p0];
	int k = std::min(std::max(r_hint, 0), S.np - 2);
	while (k < S.np - 2 && p_u > D[k + 1]) k++;
	while (k > 0 && p_u < D[k]) k--;
	r_hint = k;
	const float ax = P[k * 3], ay = P[k * 3 + 1], az = P[k * 3 + 2], bx_ = P[k * 3 + 3], by = P[k * 3 + 4], bz_ = P[k * 3 + 5];
	float tx_ = bx_ - ax, tz_ = bz_ - az;
	const float tl = std::sqrt(tx_ * tx_ + tz_ * tz_);
	if (tl > 1.0e-5f) { tx_ /= tl; tz_ /= tl; } else { tx_ = 0.0f; tz_ = 1.0f; }
	const float w = p_u - D[k];   // (may run past either end: the line goes on straight there)
	const float l = D[k + 1] - D[k];
	const float f = l > 1.0e-5f ? clampf(w / l, 0.0f, 1.0f) : 0.0f;
	r_x = ax + tx_ * w + tz_ * p_ls; r_z = az + tz_ * w - tx_ * p_ls; r_y = ay + (by - ay) * f;
	r_tx = tx_; r_tz = tz_;
}

int Crowd::nearest_walk(float p_x, float p_z, float max_d, float &r_u, float &r_d, float &r_px, float &r_pz, float &r_py) const {
	int best = -1;
	float bd = max_d * max_d;
	for (int k = 0; k < (int)segs.size(); k++) {
		const Seg &S = segs[k];
		if (S.np < 2 || S.kind != 0) continue;
		const float mx_ = S.mx - p_x, mz_ = S.mz - p_z, reach = S.len * 0.5f + max_d + 20.0f;   // (a bent pavement's middle is not on its chord)
		if (mx_ * mx_ + mz_ * mz_ > reach * reach) continue;
		const float *P = &pts[(size_t)S.p0 * 3];
		for (int q = 0; q + 1 < S.np; q++) {
			const float ax = P[q * 3], az = P[q * 3 + 2], dx = P[q * 3 + 3] - ax, dz = P[q * 3 + 5] - az, l2 = dx * dx + dz * dz;
			if (l2 < 1.0e-8f) continue;
			const float t = clampf(((p_x - ax) * dx + (p_z - az) * dz) / l2, 0.0f, 1.0f);
			const float ex = p_x - (ax + dx * t), ez = p_z - (az + dz * t), e2 = ex * ex + ez * ez;
			if (e2 < bd) {
				bd = e2; best = k;
				r_u = pts_s[S.p0 + q] + t * std::sqrt(l2); r_px = ax + dx * t; r_pz = az + dz * t; r_py = P[q * 3 + 1] + (P[q * 3 + 4] - P[q * 3 + 1]) * t;
			}
		}
	}
	r_d = best >= 0 ? std::sqrt(bd) : max_d;
	return best;
}

bool Crowd::walk_light(const Seg &S, double clock, float *r_left) const {
	if (S.phase < 0 || S.node < 0) { if (r_left) *r_left = BIG; return true; }
	const double off = S.node < (int)sig_off.size() ? (double)sig_off[S.node] : 0.0;
	double ph = std::fmod((clock + off) / SIG_CYCLE + (S.phase ? 0.5 : 0.0), 1.0);
	if (ph < 0.0) ph += 1.0;
	if (r_left) *r_left = ph >= 0.5 ? (float)((1.0 - ph) * SIG_CYCLE) : 0.0f;
	return ph >= 0.5;   // the traffic it crosses has red
}

bool Crowd::on_road(int i) const {
	const Seg &S = segs[seg[i]];
	if (!(mode[i] == M_LINE || mode[i] == M_FOLLOW) || S.kind != 1) return false;
	const float gone = dir[i] > 0 ? u[i] : S.len - u[i];
	return gone > std::max(dir[i] > 0 ? S.ka : S.kb, hold_u[i] + 0.40f) && gone < S.len - (dir[i] > 0 ? S.kb : S.ka);
}

int Crowd::find(int p_id) const {
	for (int i = 0; i < hi; i++) if (alive[i] && id[i] == p_id) return i;
	return -1;
}

void Crowd::move_row(int i, float nx, float nz) {
	const int c0 = cell_of(x[i], z[i]), c1 = cell_of(nx, nz);
	x[i] = px[i] = nx; z[i] = pz[i] = nz;
	if (c0 == c1 || (flags[i] & F_HIDDEN)) return;
	if (g_head[c0] == i) g_head[c0] = g_next[i];
	else for (int j = g_head[c0]; j >= 0; j = g_next[j]) if (g_next[j] == i) { g_next[j] = g_next[i]; break; }
	g_next[i] = g_head[c1]; g_head[c1] = (int16_t)i;
}

void Crowd::grid() {
	for (int k = 0; k < GB; k++) g_head[k] = -1;
	for (int i = 0; i < hi; i++) {
		if (!alive[i] || (flags[i] & F_HIDDEN)) continue;
		const int c = cell_of(x[i], z[i]);
		g_next[i] = g_head[c]; g_head[c] = (int16_t)i;
	}
}

// Is (nx, nz) inside a car's box, widened by r?
bool Crowd::car_at(float nx, float nz, float r) const {
	const int n = (int)cars.size() / 7;
	for (int c = 0; c < n; c++) {
		const float *q = &cars[(size_t)c * 7];
		const float dx = nx - q[0], dz = nz - q[1];
		if (dx * dx + dz * dz > 49.0f) continue;
		const float fx = std::sin(q[2]), fz = std::cos(q[2]);
		if (std::fabs(dx * fx + dz * fz) < q[3] + r && std::fabs(dx * fz - dz * fx) < q[4] + r) return true;
	}
	return false;
}

// May walker i stand at (nx, nz)? Not inside anybody, the player or a car, unless that takes him further out of
// something he is already in. (i = -1: is the place free for a whole body?)
bool Crowd::free_at(int i, float nx, float nz, int self) const {
	veto_what = 0;
	const int gx = (int)std::floor(nx * 0.5f), gz = (int)std::floor(nz * 0.5f);
	const float ri = (i >= 0 && thin[i]) ? RAD_THIN : RAD;
	for (int a = -1; a <= 1; a++) {
		for (int b = -1; b <= 1; b++) {
			for (int j = g_head[grid_ix(gx + a, gz + b)]; j >= 0; j = g_next[j]) {
				if (j == i || j == self || !alive[j]) continue;
				const float dx = x[j] - nx, dz = z[j] - nz, d2 = dx * dx + dz * dz;
				float lim = ri + (thin[j] ? RAD_THIN : RAD);
				if (i >= 0 && party[i] != 0 && party[j] == party[i]) {   // its own people: the leader goes where it must (they make way), the others may brush shoulders
					if (leader[i] == i) continue;
					lim = 2.0f * RAD_THIN;
				}
				if (d2 >= lim * lim) continue;
				if (i < 0) { veto_what = 1; return false; }
				const float ox = x[j] - x[i], oz = z[j] - z[i];
				if (d2 < ox * ox + oz * oz - 1.0e-7f) { veto_what = 1; return false; }
			}
		}
	}
	if (has_player) {
		const float dx = pl_x - nx, dz = pl_z - nz, d2 = dx * dx + dz * dz, lim = ri + 0.30f;
		if (d2 < lim * lim) {
			if (i < 0) { veto_what = 2; return false; }
			const float ox = pl_x - x[i], oz = pl_z - z[i];
			if (d2 < ox * ox + oz * oz - 1.0e-7f) { veto_what = 2; return false; }
		}
	}
	if (!cars.empty() && car_at(nx, nz, ri)) {
		if (i < 0 || !car_at(x[i], z[i], ri)) { veto_what = 3; return false; }   // (already in one: any way out is allowed)
	}
	return true;
}

// Where next at the end of its segment: the planned way if it has one; else on along the pavement more often than
// round the corner, over a crossing now and then, never straight back, never from one crossing straight onto the next.
void Crowd::pick_next(int i) {
	const Seg &S = segs[seg[i]];
	const int node = dir[i] > 0 ? S.b : S.a;
	nxt[i] = -1;
	if (route_n[i] > 0 && route_i[i] < route_n[i]) {
		const int k = route[i][route_i[i]];
		if (k >= 0 && k < (int)segs.size() && k != seg[i] && (segs[k].a == node || segs[k].b == node)) { nxt[i] = k; return; }
		route_n[i] = 0; goal[i] = -1;   // (the way no longer fits where he is: he will choose again)
	}
	const float *E = &pts[(size_t)(S.p0 + (dir[i] > 0 ? S.np - 2 : 0)) * 3];
	float fx = (E[3] - E[0]) * dir[i], fz = (E[5] - E[2]) * dir[i];
	const float fl = std::sqrt(fx * fx + fz * fz);
	if (fl > 1.0e-5f) { fx /= fl; fz /= fl; }
	for (int pass_ = 0; pass_ < 2 && nxt[i] < 0; pass_++) {
		int opt[8]; float w[8]; int n = 0; float sum = 0.0f;
		for (int k : node_segs[node]) {
			const Seg &N = segs[k];
			if (k == seg[i] || N.np < 2) continue;
			if (pass_ == 0 && N.kind == 1 && (S.kind == 1 || flee_t[i] > 0.0f)) continue;   // (who runs away keeps to the pavements)
			float ww = N.kind == 1 ? 0.45f : 1.0f;
			const bool from_a = N.a == node;
			const float *Q = &pts[(size_t)(N.p0 + (from_a ? 0 : N.np - 2)) * 3];
			const float ox = (Q[3] - Q[0]) * (from_a ? 1.0f : -1.0f), oz = (Q[5] - Q[2]) * (from_a ? 1.0f : -1.0f);
			const float ol = std::sqrt(ox * ox + oz * oz);
			if (ol > 1.0e-5f && (ox * fx + oz * fz) / ol > 0.7f) ww *= 2.5f;
			if (n < 8) { opt[n] = k; w[n] = ww; sum += ww; n++; }
		}
		if (n == 0) continue;
		float r = rnd_of(i) * sum;
		int pick = n - 1;
		for (int k = 0; k < n; k++) { r -= w[k]; if (r <= 0.0f) { pick = k; break; } }
		nxt[i] = opt[pick];
	}
}

// Onto the next segment at `node`: the same place on the ground, seen from the new line.
void Crowd::enter(int i, int to, int node) {
	const Seg &N = segs[to];
	const bool from_a = N.a == node;
	const float *P = &pts[(size_t)(N.p0 + (from_a ? 0 : N.np - 2)) * 3];
	float tx_ = P[3] - P[0], tz_ = P[5] - P[2];
	const float tl = std::sqrt(tx_ * tx_ + tz_ * tz_);
	if (tl > 1.0e-5f) { tx_ /= tl; tz_ /= tl; } else { tx_ = 0.0f; tz_ = 1.0f; }
	const float ox = from_a ? P[0] : P[3], oz = from_a ? P[2] : P[5];
	const float dx = x[i] - ox, dz = z[i] - oz;
	const float nu = clampf(dx * tx_ + dz * tz_, -1.5f, 1.5f), nl = clampf(dx * tz_ - dz * tx_, -edge_off(N) - 0.22f, edge_off(N) + 0.22f);
	if (route_n[i] > 0 && route_i[i] < route_n[i] && route[i][route_i[i]] == to) route_i[i]++;
	seg[i] = to; dir[i] = from_a ? 1 : -1; u[i] = from_a ? nu : N.len + nu; ls[i] = nl; hint[i] = from_a ? 0 : N.np - 2; nxt[i] = -1;
	looked[i] = 0; wait_t[i] = 0.0f; pass[i] = 0; side_t[i] = 0.0f;
	if (goal[i] == -3) goal[i] = -1;   // (it found nowhere to go at the last corner: it chooses again here)
	if (N.kind == 1) {   // a crossing: its own place across the width (on the right half), and where it waits at the kerb
		own_lat[i] = -(0.15f + rnd_of(i) * std::max(edge_off(N) - 0.15f, 0.0f));
		wait_lat[i] = own_lat[i];   // at the kerb they stand on their own half: the other half is where the ones coming over arrive
		hold_u[i] = std::max((from_a ? N.ka : N.kb) - 0.40f, from_a ? nu : -nu);   // toes a hand's width behind the kerb (or where he stands, if he came along the kerb's very edge)
	}
}

// Is there time to walk over before the next car is there? (cars standing or creeping wait for people)
bool Crowd::gap_in_cars(const Seg &S, float need) const {
	const int n = (int)cars.size() / 7;
	if (n == 0) return true;
	int h = 0; float mx_, my_, mz_, cx, cz;
	at(S, S.len * 0.5f, 0.0f, h, mx_, my_, mz_, cx, cz);   // the crossing's middle and the way it runs
	for (int c = 0; c < n; c++) {
		const float *q = &cars[(size_t)c * 7];
		const float sp = std::sqrt(q[5] * q[5] + q[6] * q[6]);
		if (sp < 0.8f) continue;
		const float wx = q[5] / sp, wz = q[6] / sp;
		const float dx = mx_ - q[0], dz = mz_ - q[1];
		const float far_ = sp * need + 30.0f;   // (how far he must look depends on how long he will be on the road)
		if (dx * dx + dz * dz > far_ * far_) continue;
		// where the car's straight way meets the crossing's line: t metres ahead of the car, s metres from the crossing's middle
		const float den = wx * cz - wz * cx;
		if (std::fabs(den) < 0.2f) continue;   // (it drives along the crossing, not over it)
		const float t = (dx * cz - dz * cx) / den, sm = (dx * wz - dz * wx) / den;
		if (t < -3.0f || std::fabs(sm) > S.len * 0.5f + 1.5f) continue;   // (it has passed; or its way misses the crossing)
		if (t / sp < need) return false;
	}
	return true;
}

// A new person on pavement k, su along it, walking d, sl beside its line. Its row, or -1 (full).
int Crowd::new_row(int k, float su, int d, float sl, uint32_t p_look) {
	int i = -1;
	for (int q = 0; q < MAX_PEDS; q++) if (!alive[q]) { i = q; break; }
	if (i < 0) return -1;
	const Seg &S = segs[k];
	int h = 0; float sx, sy, sz, tx_, tz_;
	at(S, su, sl, h, sx, sy, sz, tx_, tz_);
	alive[i] = 1; id[i] = next_id++; seg[i] = k; dir[i] = (int8_t)d; u[i] = su; ls[i] = sl; hint[i] = h; nxt[i] = -1;
	state[i] = ST_WALK; why[i] = WHY_NONE; pass[i] = 0; looked[i] = 0; thin[i] = 0; thin_t[i] = 0.0f; mode[i] = M_LINE; act[i] = A_NONE; rise_t[i] = 0.0f; rise_from[i] = 0; mate[i] = 0; kept_goal[i] = -1; kept_stay[i] = 0.0f; kept_enter[i] = 0; hurt_t[i] = 0.0f; hurt_v0[i] = 0.0f; fwin[i] = 0; tier[i] = TIER_FULL; flags[i] = 0;
	x[i] = px[i] = sx; y[i] = py[i] = sy; z[i] = pz[i] = sz; hx[i] = tx_ * d; hz[i] = tz_ * d; yaw[i] = pyaw[i] = std::atan2(hx[i], hz[i]);
	tu[i] = tick; span[i] = 1;
	rs[i] = rng ^ ((uint64_t)id[i] * 0x9E3779B97F4A7C15ull); if (rs[i] == 0) rs[i] = 1;
	v0[i] = 1.05f + 0.5f * rnd_of(i); v[i] = v0[i];
	look[i] = p_look ? p_look : hash32((uint32_t)(rs[i] >> 20) ^ (uint32_t)id[i] * 2654435761u);
	file_bias[i] = (rnd_of(i) - 0.5f) * 0.12f;
	wait_t[i] = blocked_t[i] = still_t[i] = pass_t[i] = pause_t[i] = side_t[i] = side_goal[i] = own_lat[i] = wait_lat[i] = hold_u[i] = odo[i] = 0.0f;
	goal[i] = -1; goal_seg[i] = -1; goal_u[i] = 0.0f; route_n[i] = 0; route_i[i] = 0; tx[i] = tz[i] = ty[i] = tyaw[i] = 0.0f;
	act_t[i] = stay_t[i] = meet_cd[i] = flee_t[i] = say_cd[i] = bump_cd[i] = lookout_cd[i] = face_yaw[i] = bx[i] = bz[i] = 0.0f;
	roll_t[i] = 18.0f + 32.0f * rnd_of(i);
	lagf[i] = 1.0f; enter_goal[i] = 0; boarding[i] = 0;
	party[i] = 0; leader[i] = -1; pkind[i] = PK_NONE; slot[i] = 0; psize[i] = 1; abreast[i] = 0; trail_at[i] = 0; trail_d[i] = 0.0f;
	for (int q = 0; q < TRAIL_N; q++) { trail[i][q][0] = sx; trail[i][q][1] = sy; trail[i][q][2] = sz; }
	if (i >= hi) hi = i + 1;
	n_alive++; st.spawned++;
	const int c = cell_of(sx, sz);
	g_next[i] = g_head[c]; g_head[c] = (int16_t)i;
	event(E_SPAWN, id[i], k, 0.0f);
	return i;
}

void Crowd::kill(int i, int reason) {
	if (!alive[i]) return;
	free_place(i);
	if (party[i]) leave_party(i);
	event(E_DESPAWN, id[i], reason, 0.0f);
	alive[i] = 0; n_alive--; st.despawned++;
}

float Crowd::hour_factor(int zone) const {
	// how full the streets are through the day: [0] homes' streets (a morning and an evening), [1] the busy ones (noon to night)
	static const float QUIET[24] = { 0.05f, 0.03f, 0.03f, 0.03f, 0.05f, 0.12f, 0.30f, 0.65f, 0.90f, 0.75f, 0.65f, 0.65f, 0.70f, 0.65f, 0.60f, 0.65f, 0.80f, 1.00f, 0.95f, 0.75f, 0.55f, 0.35f, 0.20f, 0.10f };
	static const float BUSY[24] = { 0.20f, 0.12f, 0.08f, 0.05f, 0.05f, 0.08f, 0.15f, 0.35f, 0.60f, 0.75f, 0.85f, 0.95f, 1.00f, 1.00f, 0.90f, 0.90f, 0.95f, 1.00f, 1.00f, 0.95f, 0.85f, 0.70f, 0.50f, 0.30f };
	const float *T = (zone == 2 || zone == 3) ? BUSY : QUIET;
	const float hh = std::fmod(std::max(hour, 0.0f), 24.0f);
	const int a = (int)hh % 24, b = (a + 1) % 24;
	float f = T[a] + (T[b] - T[a]) * (hh - (float)a);
	if (weekday >= 5 && (zone == 2 || zone == 3)) f = std::min(1.0f, f * 1.15f);   // the weekend's promenade
	if (rain > 0.5f) f *= 0.6f;
	return f;
}

void Crowd::population(double clock) {
	(void)clock;
	// the pavements people may appear on and the doors they may come out of, once a second
	if (tick - cand_tick >= 20) {
		cand_tick = tick;
		cand.clear(); cand_w.clear(); door_cand.clear(); cand_sum = 0.0f;
		const float reach = cfg.ring_out;
		for (int k = 0; k < (int)segs.size(); k++) {
			const Seg &S = segs[k];
			if (S.np < 2 || S.kind != 0 || S.len < 8.0f) continue;
			if (!cell_ok.empty() && (S.cell < 0 || S.cell >= (int)cell_ok.size() || !cell_ok[S.cell])) continue;
			float share = 1.0f;
			if (!cfg.whole) {
				const float dx = S.mx - cam_x, dz = S.mz - cam_z, dd = std::sqrt(dx * dx + dz * dz);
				if (dd > reach + S.len * 0.5f) continue;
				share = clampf((reach + S.len * 0.5f - dd) / std::max(S.len, 1.0f), 0.0f, 1.0f);   // (about the part of it inside the ring)
			}
			cand_sum += S.len * share * DENS[S.zone] * cfg.density * hour_factor(S.zone) / 100.0f;
			cand.push_back(k); cand_w.push_back(cand_sum);
			for (int p : seg_places[k]) if (places[p].kind == PL_HOME || places[p].kind == PL_SHOP) door_cand.push_back(p);
		}
		target = std::min(std::min(cfg.max_peds, (int)MAX_PEDS - 24), (int)cand_sum);
		residents();
	}
	// who is far, or whose street has left, goes; so does somebody held for long where nobody sees it; and, one at a
	// time, people nobody sees when there are too many (the hour grew late)
	int walkers = 0, extra = -1; float extra_d = 0.0f;
	for (int i = 0; i < hi; i++) {
		if (!alive[i]) continue;
		const Seg &S = segs[seg[i]];
		const float dx = x[i] - cam_x, dz = z[i] - cam_z, d2 = dx * dx + dz * dz;
		if (mode[i] == M_BODY || mode[i] == M_HELD || (flags[i] & F_SCRIPT)) { walkers++; continue; }   // (the game has it)
		const bool gone = (!cfg.whole && d2 > cfg.despawn_r * cfg.despawn_r) || (!cell_ok.empty() && (S.cell < 0 || !cell_ok[S.cell]));
		if (gone) { kill(i, 0); continue; }
		const bool unseen = cfg.whole || d2 > cfg.view_r * cfg.view_r || ((cam_fx != 0.0f || cam_fz != 0.0f) && dx * cam_fx + dz * cam_fz < 0.0f);
		if (unseen && mode[i] == M_LINE && state[i] != ST_PAUSE && still_t[i] > cfg.stuck_s) { kill(i, 2); st.taken_stuck++; continue; }
		if (flags[i] & F_RESIDENT) continue;
		walkers++;
		if (unseen && mode[i] == M_LINE && !party[i] && d2 > extra_d) { extra_d = d2; extra = i; }
	}
	if (walkers > target + 8 && extra >= 0) { kill(extra, 4); st.taken_extra++; walkers--; }
	while (hi > 0 && !alive[hi - 1]) hi--;
	// who is missing appears: about half out of a door, the rest on a pavement at the far edge or out of sight
	const int tries = tick < 6 ? 6000 : 60;
	for (int t = 0; t < tries && walkers < target && !cand.empty(); t++) {
		if (cfg.goals && tick >= 6 && !door_cand.empty() && rnd() < cfg.door_share) {
			const int p = door_cand[std::min((int)(rnd() * (float)door_cand.size()), (int)door_cand.size() - 1)];
			if (places[p].kind == PL_SHOP && (inside[p] <= 0 || !shop_open(p))) continue;
			if (places[p].kind == PL_HOME && rnd() > 0.25f + 0.75f * hour_factor(0)) continue;   // (homes empty in the morning)
			const int before = n_alive;
			come_out(p, false, 0.0f, 0.0f);
			if (n_alive > before) { walkers++; if (places[p].kind == PL_SHOP) inside[p]--; }
			continue;
		}
		const float r = rnd() * cand_sum;
		const int ci = (int)(std::lower_bound(cand_w.begin(), cand_w.end(), r) - cand_w.begin());
		const int k = cand[std::min(ci, (int)cand.size() - 1)];
		const Seg &S = segs[k];
		const float su = 2.0f + rnd() * (S.len - 4.0f);
		const int d = rnd() < 0.5f ? 1 : -1;
		const float sl = -file_off(S) * (float)d;
		int h = 0; float sx, sy, sz, tx_, tz_;
		at(S, su, sl, h, sx, sy, sz, tx_, tz_);
		if (!cfg.whole) {
			const float dx = sx - cam_x, dz = sz - cam_z, dd = std::sqrt(dx * dx + dz * dz);
			if (dd < cfg.ring_in || dd > cfg.ring_out) continue;
			const bool in_front = (cam_fx != 0.0f || cam_fz != 0.0f) && (dx * cam_fx + dz * cam_fz) > 0.5f * dd;
			if (dd < cfg.view_r && in_front) continue;                                   // never close in front of the camera
			if (tick >= 6 && in_front && dd < cfg.ring_out * 0.75f) continue;            // in view only at the far edge
		}
		if (!free_at(-1, sx, sz)) continue;
		const int i = new_row(k, su, d, sl, 0);
		if (i < 0) break;
		walkers++;
		if (cfg.parties) {   // who walks together, by the kind of street
			static const float SHARE[5] = { 0.22f, 0.28f, 0.40f, 0.50f, 0.28f };
			const float pr = rnd();
			if (pr < SHARE[S.zone]) {
				const float kr = rnd();
				const float sailors = (S.zone == 2 || S.zone == 3) ? 0.12f : 0.03f;
				make_party(i, kr < 0.45f ? PK_COUPLE : (kr < 0.70f ? PK_FRIENDS : (kr < 1.0f - sailors ? PK_FAMILY : PK_SAILORS)));
				walkers += psize[i] - 1;
			} else if (pr > 1.0f - (S.zone == 3 ? 0.10f : 0.04f)) make_party(i, PK_JOGGER);
		}
	}
}

// A straight step toward a point off the line (a door, a seat, back to the pavement). true = it is there.
bool Crowd::free_move(int i, float gx, float gz, float speed, float h) {
	const float dx = gx - x[i], dz = gz - z[i], dd = std::sqrt(dx * dx + dz * dz);
	if (dd < 0.10f) { v[i] = 0.0f; return true; }
	const float ux = dx / dd, uz = dz / dd;
	hx[i] = ux; hz[i] = uz;
	v[i] = std::max(v[i] + clampf(std::min(speed, dd * 3.0f + 0.25f) - v[i], -3.5f * h, (speed > 3.0f ? 14.0f : 2.0f) * h), 0.0f);
	const float stp = std::min(v[i] * h, dd);
	float nx = x[i] + ux * stp, nz = z[i] + uz * stp;
	bool ok = free_at(i, nx, nz);
	if (!ok) {
		const bool road = mode[i] == M_FOLLOW && segs[seg[i]].kind == 1;   // (on a road nobody waits a second before going round somebody)
		blocked_t[i] += h; v[i] = 0.0f; st.refused++;
		if (blocked_t[i] > (road ? 0.3f : 3.0f)) thin[i] = 1;
		if (blocked_t[i] > (road ? 0.1f : 1.0f)) {   // round the body in its way: a short step to one side
			const float s = ((id[i] + (int)(blocked_t[i] * 0.5f)) & 1) ? 1.0f : -1.0f, stp2 = road ? 0.12f : 0.06f;
			nx = x[i] + uz * s * stp2; nz = z[i] - ux * s * stp2;
			ok = free_at(i, nx, nz);
		}
	} else if (stp > 0.004f) { blocked_t[i] = 0.0f; if (thin[i] && free_at(-1, nx, nz, i)) thin[i] = 0; }
	if (ok) {
		const float md = std::sqrt((nx - x[i]) * (nx - x[i]) + (nz - z[i]) * (nz - z[i]));
		y[i] += (ty[i] - y[i]) * std::min(1.0f, md / std::max(dd, 0.05f));
		odo[i] += md; still_t[i] = md > 0.002f ? 0.0f : still_t[i] + h;
		x[i] = nx; z[i] = nz;
	} else still_t[i] += h;
	yaw[i] += clampf(wrap_pi(std::atan2(ux, uz) - yaw[i]), -5.0f * h, 5.0f * h);
	return false;
}

void Crowd::update(int i, float h, double clock) {
	px[i] = x[i]; py[i] = y[i]; pz[i] = z[i]; pyaw[i] = yaw[i];
	if (meet_cd[i] > 0.0f) meet_cd[i] -= h;
	if (bump_cd[i] > 0.0f) bump_cd[i] -= h;
	if (lookout_cd[i] > 0.0f) lookout_cd[i] -= h;
	switch (mode[i]) {
		case M_LINE: walk_line(i, h, clock); break;
		case M_OFF:
			if (free_move(i, tx[i], tz[i], std::min(v0[i], 1.4f) * cfg.pace, h)) arrive(i);
			else if (blocked_t[i] > 14.0f && !boarding[i]) { free_place(i); goal[i] = -1; mode[i] = M_BACK; tx[i] = bx[i]; tz[i] = bz[i]; blocked_t[i] = 0.0f; }   // it cannot get there: back
			break;
		case M_BACK:
			if (free_move(i, tx[i], tz[i], v0[i] * cfg.pace, h)) {   // on the pavement's line again, where it left it
				const Seg &S = segs[seg[i]];
				int hh = hint[i]; float ax, ay, az, tx_, tz_;
				at(S, u[i], 0.0f, hh, ax, ay, az, tx_, tz_);
				ls[i] = clampf((x[i] - ax) * tz_ - (z[i] - az) * tx_, -edge_off(S), edge_off(S));
				y[i] = ay; mode[i] = (leader[i] >= 0 && leader[i] != i) ? M_FOLLOW : M_LINE; state[i] = ST_WALK; act[i] = A_NONE; blocked_t[i] = 0.0f;
				if (mode[i] == M_LINE && kept_goal[i] >= 0) {   // (it was knocked about on its way somewhere: it goes on there)
					const int g = kept_goal[i];
					kept_goal[i] = -1;
					set_goal(id[i], g, kept_stay[i], kept_enter[i] != 0);
				}
			}
			break;
		case M_STAY: stay_step(i, h); break;
		case M_FOLLOW: follow(i, h); break;
		case M_DODGE: dodge(i, h); break;
		case M_HELD: v[i] = 0.0f; yaw[i] += clampf(wrap_pi(face_yaw[i] - yaw[i]), -5.0f * h, 5.0f * h); break;
		default: break;   // M_BODY: the game moves it
	}
	if (leader[i] == i && mode[i] != M_LINE) trail_push(i);   // (its people follow it off the pavement too)
	if (v[i] > 0.08f) flags[i] |= F_MOVING; else flags[i] &= (uint8_t)~F_MOVING;
	if (thin[i]) flags[i] |= F_THIN; else flags[i] &= (uint8_t)~F_THIN;
}

// Blows begin: who wins is chance, fixed by who the two are (both work it out alike). The loser will walk away hurt:
// slowly, for cfg.hurt_s seconds. Nobody is killed.
void Crowd::fight_begins(int i) {
	const int o = mate[i];
	if (o == 0) { fwin[i] = 1; return; }
	const uint32_t hh = hash32((uint32_t)(std::min(id[i], o) * 7919 + std::max(id[i], o)) * 2654435761u + 77u);
	fwin[i] = ((id[i] < o) == ((hh & 1u) != 0u)) ? 1 : 0;
	if (!fwin[i] && hurt_t[i] <= 0.0f && cfg.hurt_s > 0.0f) { hurt_v0[i] = v0[i]; v0[i] *= 0.5f; hurt_t[i] = cfg.hurt_s; }
}

// Leaving an act that takes a moment to leave: up from a seat or the ground, out of a crouch, out of a fight
// (cfg.rise_s, set by the game to its animations' lengths). True while that moment lasts; the walker stays where it
// is and shows A_RISE (rise_from says out of what).
bool Crowd::rising(int i, float h) {
	const int a = act[i];
	if (a == A_RISE) {
		rise_t[i] -= h;
		if (rise_t[i] > 0.0f) return true;
		act[i] = A_NONE;
		return false;
	}
	if (a > A_NONE && a < A_COUNT && cfg.rise_s[a] > 0.0f) { rise_from[i] = (uint8_t)a; rise_t[i] = cfg.rise_s[a]; act[i] = A_RISE; return true; }
	return false;
}

void Crowd::walk_line(int i, float h, double clock) {
	const Seg &S = segs[seg[i]];
	if (act_t[i] > 0.0f) {
		act_t[i] -= h;
		if (act_t[i] <= 0.0f) {
			if (state[i] != ST_PAUSE) act[i] = A_NONE;                                  // a wave in passing is over
			else if (act[i] == A_HUG) act[i] = A_CHAT;                                  // after the hug they talk
			else if (act[i] == A_ARGUE && pause_t[i] > 1.0f) { act[i] = A_FIGHT; st.fights++; event(E_FIGHT, id[i], 0, 0.0f); fight_begins(i); }   // the quarrel comes to blows
		}
	}
	if (flee_t[i] > 0.0f) { flee_t[i] -= h; if (flee_t[i] <= 0.0f) flags[i] &= (uint8_t)~F_FLEE; }
	if (hurt_t[i] > 0.0f && state[i] != ST_PAUSE) { hurt_t[i] -= h; if (hurt_t[i] <= 0.0f && hurt_v0[i] > 0.0f) v0[i] = hurt_v0[i]; }   // (hurt: he walks slowly for a while, then as before)
	if (state[i] == ST_PAUSE) {   // stands a while where it is: a phone, a shop window, somebody it knows, a look at something
		pause_t[i] -= h; v[i] = 0.0f; why[i] = WHY_PAUSE; still_t[i] += h;
		if (flags[i] & F_FACE) yaw[i] += clampf(wrap_pi(face_yaw[i] - yaw[i]), -5.0f * h, 5.0f * h);
		if (pause_t[i] <= 0.0f || flee_t[i] > 0.0f) {
			if (act[i] == A_FIGHT && fwin[i] && cfg.cheer_s > 0.0f && flee_t[i] <= 0.0f) { act[i] = A_CHEER; pause_t[i] = cfg.cheer_s; return; }   // he has won
			if (rising(i, h)) return;   // (out of a crouch, out of a fight: that takes a moment)
			state[i] = ST_WALK; act[i] = A_NONE; act_t[i] = 0.0f; mate[i] = 0; flags[i] &= (uint8_t)~F_FACE; still_t[i] = 0.0f;
		}
		return;
	}
	const int d = dir[i];
	const float rem = d > 0 ? S.len - u[i] : u[i];
	// ---- going somewhere
	if (cfg.goals && flee_t[i] <= 0.0f) {
		if (goal[i] == -1 && !(flags[i] & F_SCRIPT)) pick_goal(i);
		if (goal[i] != -1 && seg[i] == goal_seg[i] && S.kind == 0) {
			const float du = goal_u[i] - u[i];
			if (std::fabs(du) < 0.4f) { if (goal[i] >= 0) leave_line(i); else arrive(i); return; }
			if (du * (float)d < 0.0f && !pass[i]) { dir[i] = (int8_t)-d; nxt[i] = -1; return; }   // it is behind him: he turns round
		}
	}
	if (nxt[i] < 0 && rem < 10.0f) pick_next(i);
	if (rem <= 0.05f) {
		if (nxt[i] < 0) { dir[i] = (int8_t)-d; pass[i] = 0; return; }   // the pavement ends here: back
		enter(i, nxt[i], d > 0 ? S.b : S.a);
		return;
	}
	const float q = file_off(S), e = edge_off(S);
	float tx_, tz_, cx, cy, cz;
	at(S, u[i], ls[i], hint[i], cx, cy, cz, tx_, tz_);
	const float fx = tx_ * d, fz = tz_ * d;     // the way it walks
	const float lx = fz, lz = -fx;              // its left
	hx[i] = fx; hz[i] = fz;
	const bool fleeing = flee_t[i] > 0.0f;
	const bool mouth = rem < 4.0f || S.len - rem < 4.0f;   // (a corner, a crossing's mouth: nobody waits for his people there)
	const float lag_now = leader[i] == i ? lagf[i] : 1.0f;
	const float own = (fleeing ? FLEE_V : v0[i] * cfg.pace * (rain > 0.5f ? 1.15f : 1.0f)) * ((leader[i] == i && !mouth) ? lag_now : 1.0f);
	if (leader[i] == i) lagf[i] = 1.0f;   // (its people say again in this step whether they keep up)

	// ---- a crossing: to the kerb, wait there, then over
	bool hold_ = false;
	float vmax = own;
	if (S.kind == 0 && nxt[i] >= 0 && segs[nxt[i]].kind == 1 && rem < 2.0f) vmax = std::min(vmax, 0.5f + rem * 0.8f);   // (it comes to the kerb at a walk it can stop from)
	uint8_t wy = WHY_NONE;
	if (S.kind == 1) {
		const float gone = d > 0 ? u[i] : S.len - u[i];
		const bool lit = S.phase >= 0 && S.node >= 0;
		const float pace = std::max(cross_pace(v0[i]), fleeing ? FLEE_V : v0[i] * cfg.pace);   // (on the road a leader does not dawdle for its people)
		const float rest = S.len - (d > 0 ? S.kb : S.ka) - gone;   // road still to walk
		vmax = pace;
		if (!looked[i]) {
			vmax = std::min(own, std::max(0.25f, (hold_u[i] - gone) * 2.5f));   // it slows to the kerb
			if (gone >= hold_u[i] - 0.25f) {
				const float need = std::max(rest, 0.0f) / pace + 2.0f;
				bool go;
				if (lit) {   // while the traffic he crosses has red, and only if he will be over in time (a long crossing: right at the start, and he jogs)
					float left = 0.0f;
					const float window = (float)(SIG_CYCLE * 0.5) - 0.8f;   // (not in the first moment: a late car may still be on it)
					go = walk_light(S, clock, &left) && left <= window && left >= std::min(need, std::max(rest, 0.0f) / JOG + 4.0f);
					wy = WHY_SIGNAL;
				} else {
					go = wait_t[i] >= 0.7f + (float)(look[i] & 7u) * 0.1f;   // it looks first
					wy = WHY_LOOK;
					if (go && !gap_in_cars(S, wait_t[i] > cfg.bold_after ? need * 0.6f : need + 1.5f)) { go = false; wy = WHY_GAP; }
				}
				if (go && leader[i] == i && lag_now < 1.0f) { go = false; wy = WHY_FOLLOW; }   // (not without its people)
				if (go) { looked[i] = 1; st.crossings++; wait_t[i] = 0.0f; wy = WHY_NONE; vmax = pace; }
				else {
					hold_ = gone >= hold_u[i] - 0.03f;
					if (wait_t[i] == 0.0f) event(lit ? E_WAIT_CROSS : E_LOOK_CROSS, id[i], seg[i], 0.0f);
					wait_t[i] += h;
				}
			}
		} else if (lit && rest > 0.0f) {   // on its way over: as fast as the light asks
			float left = 0.0f;
			const bool red = walk_light(S, clock, &left);
			if (gone < hold_u[i] + 0.35f && (!red || left < rest / JOG + 2.0f)) { looked[i] = 0; vmax = 0.0f; st.crossings--; }   // held before the kerb until it was too late: the next light
			else if (!red) vmax = JOG;
			else vmax = clampf(rest / std::max(left - 2.0f, 0.3f), pace, JOG);
		} else if (!lit && rest > 0.0f && !gap_in_cars(S, rest / pace + 3.5f)) vmax = JOG;   // a car comes after all: it runs
	}
	state[i] = hold_ ? ST_WAIT : (S.kind == 1 ? (looked[i] ? ST_CROSS : ST_WALK) : ST_WALK);

	// ---- street life: a phone call, a shop window, a coin, shelter from the rain
	if (cfg.pauses && S.kind == 0 && !pass[i] && !fleeing && tier[i] != TIER_FAR && leader[i] < 0 && pkind[i] != PK_JOGGER) {
		life_roll(i, h);
		if (state[i] == ST_PAUSE || mode[i] != M_LINE) return;
	}

	// ---- who is near: the one in front, somebody coming, the other file, the place beside, somebody it knows
	float lead_gap = BIG, lead_v = 0.0f, onc_gap = BIG, lead_sd = 0.0f;
	int lead_j = -1, known = -1;
	bool left_busy = false, right_clear = true;
	{
		const int gx = (int)std::floor(x[i] * 0.5f), gz = (int)std::floor(z[i] * 0.5f);
		const float mine = 2.0f * RAD + 0.06f, wide = 2.0f * q + 2.0f * RAD + 0.1f;
		const bool may_meet = cfg.life && tier[i] == TIER_FULL && !party[i] && meet_cd[i] <= 0.0f && S.kind == 0 && !fleeing && act[i] == A_NONE && rem > 6.0f && S.len - rem > 6.0f;   // (nobody stops to chat in a corner or a crossing's mouth)
		const int R = leader[i] == i ? 5 : 2;   // (a leader looks 9 m along the other file: its people must be behind it before somebody comes)
		left_far[i] = 0;
		for (int a = -R; a <= R; a++) {
			for (int b = -R; b <= R; b++) {
				for (int j = g_head[grid_ix(gx + a, gz + b)]; j >= 0; j = g_next[j]) {
					if (j == i || !alive[j]) continue;
					if (leader[i] >= 0 && party[j] == party[i]) continue;   // (its own people keep their places themselves)
					const float dx = x[j] - x[i], dz = z[j] - z[i];
					const float al = dx * fx + dz * fz, sd = dx * lx + dz * lz;
					if (R > 2 && al > 0.0f && al < 9.0f && sd > 0.1f && sd < wide + 0.3f && (v[j] * (hx[j] * fx + hz[j] * fz) < 0.3f)) left_far[i] = 1;
					if (al < -1.2f || al > 4.0f || std::fabs(sd) > 1.7f) continue;
					const float vj = v[j] * (hx[j] * fx + hz[j] * fz);
					if (al > 0.0f && std::fabs(sd) < mine) {
						if (vj < -0.2f) onc_gap = std::min(onc_gap, al - 2.0f * RAD);
						else if (al - 2.0f * RAD < lead_gap) { lead_gap = al - 2.0f * RAD; lead_v = std::max(vj, 0.0f); lead_j = j; lead_sd = sd; }
					}
					if (al > -0.7f && sd > 0.18f && sd < wide) left_busy = true;
					if (al > -0.9f && al < 1.1f && sd < -0.15f && sd > -wide) right_clear = false;
					if (may_meet && vj < -0.2f && al > 0.3f && al < 2.6f && mode[j] == M_LINE && state[j] == ST_WALK && !party[j] && meet_cd[j] <= 0.0f && act[j] == A_NONE &&
							hash32(look[i] ^ look[j]) % 10u == 0u) known = j;
				}
			}
		}
		if (has_player) {   // the player is somebody in the way too: it steps aside for him
			const float dx = pl_x - x[i], dz = pl_z - z[i];
			const float al = dx * fx + dz * fz, sd = dx * lx + dz * lz;
			if (al > 0.0f && al < 3.0f && std::fabs(sd) < mine + 0.1f) {
				if (al - 0.51f < lead_gap) { lead_gap = al - 0.51f; lead_v = std::max(pl_vx * fx + pl_vz * fz, 0.0f); lead_j = -1; }
				if (side_t[i] <= 0.0f) { side_goal[i] = sd > 0.0f ? -e : e; side_t[i] = 1.5f; }
				wy = WHY_PLAYER;
			}
		}
	}
	if (known >= 0) { meet(i, known); if (state[i] == ST_PAUSE) return; }

	// ---- what it does
	float lat_goal = S.kind == 1 ? (looked[i] ? own_lat[i] : wait_lat[i]) : clampf(-q + file_bias[i], -e, e);   // (seen along its own way: - = its right)
	if (leader[i] == i && abreast[i] && S.kind == 0) lat_goal = clampf(-q - 0.05f, -e, e);
	float vd = vmax;
	if (pass[i]) {
		pass_t[i] += h;
		if (onc_gap < 3.0f || S.kind == 1 || rem < 3.0f) pass[i] = 0;                 // somebody comes, or the corner: back in
		else if (right_clear && pass_t[i] > 0.8f) { pass[i] = 0; st.passes++; }     // past him
		else lat_goal = q;
	}
	if (lead_gap < BIG) {
		const float vf = lead_v + (lead_gap - 0.30f) / 0.6f;
		if (vf < vd) {
			if (S.kind == 1 && looked[i] && lead_gap < 1.5f && vmax - lead_v > 0.25f && side_t[i] <= 0.0f && lead_j >= 0) {   // on the road nobody dawdles behind a slower one: round him, either side
				side_goal[i] = clampf(ls[i] * d + (lead_sd > 0.0f ? -0.6f : 0.6f), -e, e); side_t[i] = 1.2f;
			}
			vd = std::max(vf, 0.0f); if (wy != WHY_PLAYER) wy = WHY_FOLLOW;
		}
		if (!pass[i] && S.kind == 0 && own - lead_v > 0.22f && lead_gap < 1.6f && !left_busy && onc_gap >= BIG && rem > 6.0f && lead_j >= 0) { pass[i] = 1; pass_t[i] = 0.0f; }
	}
	if (onc_gap < BIG) {   // somebody comes at it: each leans to his own right edge, and they slow as they meet
		lat_goal = S.kind == 1 ? std::min(own_lat[i], -q) : -e;
		vd = std::min(vd, std::max(0.3f, onc_gap));
		wy = WHY_ONCOMING;
	}
	if (side_t[i] > 0.0f) { side_t[i] -= h; lat_goal = side_goal[i]; }
	if (hold_) vd = 0.0f;
	if (thin[i]) vd = std::min(vd, 0.6f);   // sideways it shuffles
	// Right behind somebody who stands. If he waits at a kerb this one is going to as well, it queues behind him.
	// Otherwise it is held as by any body in its way: it looks for a free place beside him (below).
	bool queued = false;
	if (lead_j >= 0 && lead_gap < 0.5f && lead_v < 0.1f && !hold_) {
		const bool to_kerb = S.kind == 1 ? !looked[i] : (nxt[i] >= 0 && segs[nxt[i]].kind == 1 && rem < 4.0f);
		if (state[lead_j] == ST_WAIT && mode[lead_j] == M_LINE && to_kerb && (S.kind == 1 || wait_t[i] < 35.0f)) { queued = true; wy = WHY_SIGNAL; if (S.kind == 0) wait_t[i] += h; }
		else { blocked_t[i] += h; wy = WHY_BLOCKED; }
	} else if (S.kind == 0 && wait_t[i] > 0.0f && v[i] > 0.3f) {
		wait_t[i] = 0.0f;
	}

	// ---- the move, refused if it would end inside somebody
	v[i] = std::max(v[i] + clampf(vd - v[i], -3.5f * h, (vd > v0[i] ? 2.5f : 1.4f) * h), 0.0f);
	const float lt0 = ls[i] * d;
	const float bound = std::max(std::max(e, std::fabs(lt0)), side_t[i] > 0.0f ? std::min(std::fabs(lat_goal), e + (S.kind == 1 ? 1.0f : 0.25f)) : 0.0f);
	const float lt = clampf(lt0 + clampf(lat_goal - lt0, -0.7f * h, 0.7f * h), -bound, bound);
	float nu = u[i] + d * v[i] * h;
	const float nl = lt * d;
	float nx, ny, nz, ax_, az_;
	int hn = hint[i];
	at(S, nu, nl, hn, nx, ny, nz, ax_, az_);
	bool moved = true;
	if (!free_at(i, nx, nz)) {
		const uint8_t what = veto_what;
		nu = u[i];
		at(S, nu, nl, hn, nx, ny, nz, ax_, az_);
		if (!free_at(i, nx, nz)) moved = false;   // not even sideways
		v[i] = 0.0f;
		blocked_t[i] += h; st.refused++;
		if (!hold_) wy = what == 2 ? WHY_PLAYER : (what == 3 ? WHY_CAR : WHY_BLOCKED);
		if (what == 2 && blocked_t[i] > 1.0f && bump_cd[i] <= 0.0f) { bump_cd[i] = 3.0f; st.bumps++; event(E_BUMP, id[i], 0, 0.0f); }   // the player stands in its way
	} else if (v[i] > 0.3f) blocked_t[i] = 0.0f;
	if (moved) {
		const float mx_ = nx - x[i], mz_ = nz - z[i], md = std::sqrt(mx_ * mx_ + mz_ * mz_);
		odo[i] += md;
		still_t[i] = md > 0.002f ? 0.0f : still_t[i] + h;
		u[i] = nu; ls[i] = nl; hint[i] = hn; x[i] = nx; y[i] = ny; z[i] = nz;
		if (leader[i] == i) trail_push(i);
	} else still_t[i] += h;
	yaw[i] += clampf(wrap_pi(std::atan2(fx, fz) - yaw[i]), -4.0f * h, 4.0f * h);
	why[i] = wy;
	if (queued) state[i] = ST_WAIT;

	// ---- held for more than a second: a free place beside? Held for three: sideways. Held for long on a pavement: round.
	const bool urgent = S.kind == 1 && looked[i];   // (on the road: a way round at once, sideways at once)
	// Standing held for long in a tight place (three people in a corner a metre wide): it squeezes along the very edge.
	if (still_t[i] > 12.0f && blocked_t[i] > 0.0f && side_t[i] <= 0.0f && S.kind == 0 && !hold_) {
		side_goal[i] = (((id[i] + tick / 100) & 1) ? 1.0f : -1.0f) * (e + 0.25f); side_t[i] = 4.0f; st.sidesteps++;
	}
	if (urgent && blocked_t[i] > 1.5f && side_t[i] <= 0.0f) {
		side_goal[i] = (((tick / 60) & 1) ? 1.0f : -1.0f) * (e + 1.0f); side_t[i] = 3.0f; st.sidesteps++;   // (its own right first, then the other side, turn about)
	}
	if (blocked_t[i] > (urgent ? 0.15f : 1.2f) && side_t[i] <= 0.0f) {
		const float c3[3] = { -e, 0.0f, e };
		const int k0 = std::min((int)(rnd_of(i) * 3.0f), 2);
		for (int k = 0; k < 3; k++) {
			const float g = c3[(k0 + k) % 3];
			if (std::fabs(g - lt) < 0.12f) continue;
			float sx, sy, sz; int hh = hint[i];
			at(S, u[i] + d * 0.2f, (lt + clampf(g - lt, -0.3f, 0.3f)) * d, hh, sx, sy, sz, ax_, az_);
			if (free_at(i, sx, sz)) { side_goal[i] = g; side_t[i] = 2.5f; st.sidesteps++; break; }
		}
		if (side_t[i] <= 0.0f) { side_t[i] = 0.4f; side_goal[i] = lt; }   // (nothing free: look again in a moment)
	}
	if (!thin[i] && blocked_t[i] > (urgent ? 0.3f : 3.0f)) { thin[i] = 1; thin_t[i] = 0.0f; st.sidled++; }
	else if (thin[i]) {
		thin_t[i] = blocked_t[i] > 0.0f ? 0.0f : thin_t[i] + h;
		if (thin_t[i] > 1.5f && free_at(-1, x[i], z[i], i)) thin[i] = 0;   // (only where it has a whole body's room again)
	}
	if (blocked_t[i] > 9.0f && S.kind == 0 && !hold_ && veto_what != 2) { dir[i] = (int8_t)-d; nxt[i] = -1; pass[i] = 0; blocked_t[i] = 0.0f; side_t[i] = 0.0f; st.turned++; route_n[i] = 0; goal[i] = -1; }

	// ---- a car coming at it: out of its way
	if (tier[i] == TIER_FULL && !cars.empty() && mode[i] == M_LINE) dodge(i, 0.0f);
}

void Crowd::step(float dt, double clock) {
	if (!built) return;
	const auto t0 = std::chrono::steady_clock::now();
	tick++;
	grid();
	if (tick % 5 == 1) population(clock);
	doors_step(dt);
	danger_step(dt);
	party_step(dt);
	const float rx = has_player ? pl_x : cam_x, rz = has_player ? pl_z : cam_z;
	for (int i = 0; i < hi; i++) {
		if (!alive[i]) continue;
		int n = 1;
		if (cfg.tiers && !cfg.whole) {   // people far from the player are stepped less often, each step covering the time between
			const float dx = x[i] - rx, dz = z[i] - rz, d2 = dx * dx + dz * dz;
			const int t = d2 < cfg.tier_full * cfg.tier_full ? TIER_FULL : (d2 < cfg.tier_mid * cfg.tier_mid ? TIER_MID : TIER_FAR);
			if (mode[i] == M_FOLLOW && leader[i] >= 0) tier[i] = tier[leader[i]]; else tier[i] = (uint8_t)t;
			n = tier[i] == TIER_FULL ? 1 : (tier[i] == TIER_MID ? 2 : 4);
			const int key = leader[i] >= 0 ? leader[i] : i;   // (a party steps together)
			if (n > 1 && (tick + key) % n != 0) continue;
		} else tier[i] = TIER_FULL;
		tu[i] = tick; span[i] = (uint8_t)n;
		update(i, dt * (float)n, clock);
	}
	st.step_us = std::chrono::duration<double, std::micro>(std::chrono::steady_clock::now() - t0).count();
}

void Crowd::audit(double clock, int r[7]) const {
	r[0] = r[1] = r[2] = r[3] = r[4] = r[5] = r[6] = 0;
	for (int i = 0; i < hi; i++) {
		if (!alive[i] || (flags[i] & F_HIDDEN)) continue;
		if (!(x[i] == x[i]) || !(z[i] == z[i]) || !(y[i] == y[i]) || std::fabs(x[i]) > 1.0e5f || std::fabs(z[i]) > 1.0e5f || v[i] < 0.0f || v[i] > 6.0f) r[4]++;
		for (int j = i + 1; j < hi; j++) {
			if (!alive[j] || (flags[j] & F_HIDDEN)) continue;
			const float dx = x[j] - x[i], dz = z[j] - z[i];
			float lim = (thin[i] ? RAD_THIN : RAD) + (thin[j] ? RAD_THIN : RAD) - 0.03f;
			if (party[i] != 0 && party[i] == party[j]) { if (leader[i] == i || leader[j] == j) continue; lim = 2.0f * RAD_THIN - 0.03f; }   // (a leader's own people make way for it)
			if (dx * dx + dz * dz < lim * lim) r[0]++;
		}
		const Seg &S = segs[seg[i]];
		if (mode[i] == M_LINE && std::fabs(ls[i]) > S.hw + (S.kind == 1 ? 1.05f : 0.05f)) r[1]++;   // (round a clot at a crossing's mouth one may walk a metre outside the stripes)
		if (on_road(i) && mode[i] == M_LINE && S.phase >= 0 && S.node >= 0 && !walk_light(S, clock) && !walk_light(S, clock - 2.5)) {   // (green for two and a half seconds already)
			const float gone = dir[i] > 0 ? u[i] : S.len - u[i];
			const float kin = std::max(dir[i] > 0 ? S.ka : S.kb, hold_u[i] + 0.40f), kout = dir[i] > 0 ? S.kb : S.ka;
			if (gone > kin + 1.5f && gone < S.len - kout - 1.5f) r[2]++; else r[6]++;   // out in the road; or a step from the kerb, held up by the people standing there
		}
		if (mode[i] == M_LINE && state[i] != ST_PAUSE && still_t[i] > 60.0f) r[3]++;
		if (mode[i] == M_FOLLOW && leader[i] >= 0 && alive[leader[i]]) {
			const float dx = x[leader[i]] - x[i], dz = z[leader[i]] - z[i];
			if (dx * dx + dz * dz > 100.0f) r[5]++;
		}
	}
}

uint64_t Crowd::state_hash() const {
	uint64_t h = 1469598103934665603ull;
	auto mix = [&](uint64_t v_) { h ^= v_; h *= 1099511628211ull; };
	for (int i = 0; i < hi; i++) {
		if (!alive[i]) continue;
		mix((uint64_t)id[i]); mix((uint64_t)seg[i]); mix((uint64_t)mode[i]); mix((uint64_t)(int64_t)std::lround(x[i] * 100.0f)); mix((uint64_t)(int64_t)std::lround(z[i] * 100.0f));
	}
	return h;
}

} // namespace pc
