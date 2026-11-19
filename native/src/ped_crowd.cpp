// The walking crowd: see ped_crowd.h.
#include "ped_crowd.h"

#include "street_build.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstring>

namespace pc {

float Crowd::std_floor(float f) { return std::floor(f); }

static inline float clampf(float v, float a, float b) { return v < a ? a : (v > b ? b : v); }
static inline float wrap_pi(float a) { a = std::fmod(a + 3.14159265f, 6.2831853f); if (a < 0.0f) a += 6.2831853f; return a - 3.14159265f; }

// people on 100 m of ONE pavement at a busy hour: quiet street, ordinary, busy (high street, centre, strip), promenade, main road
static const float DENS[5] = { 1.0f, 1.6f, 4.0f, 5.0f, 2.0f };
// On a crossing people step out: at least this pace, a quarter faster than their own, and a jog when the light runs out.
// (The map's crossings are 13 to 29 m long and its signals give 15 s: at a stroll nobody would ever get over.)
static inline float cross_pace(float v0) { return std::max(v0 * 1.25f, 1.6f); }
static const float JOG = 3.2f;

// the two files of a pavement lie this far either side of its middle; a person may go this far at most
static inline float file_off(const Seg &S) { return clampf(S.hw - RAD - 0.07f, 0.10f, 0.42f); }
static inline float edge_off(const Seg &S) { return std::max(S.hw - RAD, 0.10f); }

bool Crowd::build(const sg::StreetData &d) {
	built = false;
	node_xz = d.walk_node; pts = d.walk_pts;
	const int nn = (int)node_xz.size() / 2, ns = (int)d.walk_seg.size() / 8, np = (int)pts.size() / 3;
	if (nn <= 0 || ns <= 0 || (int)d.walk_seg_f.size() < ns * 2) return false;
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
		int h = 0; float yy, tx, tz;
		at(S, S.len * 0.5f, 0.0f, h, S.mx, yy, S.mz, tx, tz);
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
			float hwm = BIG;
			for (int k : node_segs[end ? S.b : S.a]) if (segs[k].np >= 2 && segs[k].kind == 0) hwm = std::min(hwm, segs[k].hw);
			const float kd = clampf((hwm < BIG ? hwm : 0.75f) + 0.25f, 0.6f, std::min(3.0f, S.len * 0.3f));
			(end ? S.kb : S.ka) = kd;
		}
	}
	// every junction's own start in the signal cycle, exactly as the traffic takes it (CityTraffic::load_streets)
	const int nj = (int)d.node_i.size() / 4;
	sig_off.assign(nj, 0.0f);
	for (int i = 0; i < nj; i++) {
		const int tx = d.node_i[(size_t)i * 4 + 2], tz = d.node_i[(size_t)i * 4 + 3];
		sig_off[i] = (float)((((tx * 7 + tz * 13) % 30) + 30) % 30);
	}
	built = true;
	reset(1);
	return true;
}

void Crowd::reset(uint64_t seed) {
	std::memset(alive, 0, sizeof(alive));
	hi = 0; n_alive = 0; next_id = 1; tick = 0;
	rng = 0x9E3779B97F4A7C15ull ^ (seed * 0xD1B54A32D192ED03ull);
	if (rng == 0) rng = 1;
	st = Stats();
	cand_tick = -1000; cand.clear(); cand_w.clear(); target = 0;
	for (int k = 0; k < GB; k++) g_head[k] = -1;
}

void Crowd::at(const Seg &S, float p_u, float p_ls, int &r_hint, float &r_x, float &r_y, float &r_z, float &r_tx, float &r_tz) const {
	const float *P = &pts[(size_t)S.p0 * 3];
	const float *D = &pts_s[S.p0];
	int k = std::min(std::max(r_hint, 0), S.np - 2);
	while (k < S.np - 2 && p_u > D[k + 1]) k++;
	while (k > 0 && p_u < D[k]) k--;
	r_hint = k;
	const float ax = P[k * 3], ay = P[k * 3 + 1], az = P[k * 3 + 2], bx = P[k * 3 + 3], by = P[k * 3 + 4], bz = P[k * 3 + 5];
	float tx = bx - ax, tz = bz - az;
	const float tl = std::sqrt(tx * tx + tz * tz);
	if (tl > 1.0e-5f) { tx /= tl; tz /= tl; } else { tx = 0.0f; tz = 1.0f; }
	const float w = p_u - D[k];   // (may run past either end: the line goes on straight there)
	const float l = D[k + 1] - D[k];
	const float f = l > 1.0e-5f ? clampf(w / l, 0.0f, 1.0f) : 0.0f;
	r_x = ax + tx * w + tz * p_ls; r_z = az + tz * w - tx * p_ls; r_y = ay + (by - ay) * f;
	r_tx = tx; r_tz = tz;
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
	return S.kind == 1 && u[i] > S.ka && u[i] < S.len - S.kb;
}

int Crowd::find(int p_id) const {
	for (int i = 0; i < hi; i++) if (alive[i] && id[i] == p_id) return i;
	return -1;
}

void Crowd::grid() {
	for (int k = 0; k < GB; k++) g_head[k] = -1;
	for (int i = 0; i < hi; i++) {
		if (!alive[i]) continue;
		const int c = cell_of(x[i], z[i]);
		g_next[i] = g_head[c]; g_head[c] = (int16_t)i;
	}
}

// May walker i stand at (nx, nz)? Not inside anybody, unless that takes him further out of somebody he is already in.
bool Crowd::free_at(int i, float nx, float nz) const {
	const int gx = (int)std::floor(nx * 0.5f), gz = (int)std::floor(nz * 0.5f);
	const float ri = (i >= 0 && thin[i]) ? RAD_THIN : RAD;
	for (int a = -1; a <= 1; a++) {
		for (int b = -1; b <= 1; b++) {
			const int c = (int)(((uint32_t)((gx + a) * 73856093) ^ (uint32_t)((gz + b) * 19349663)) & (GB - 1));
			for (int j = g_head[c]; j >= 0; j = g_next[j]) {
				if (j == i || !alive[j]) continue;
				const float dx = x[j] - nx, dz = z[j] - nz, d2 = dx * dx + dz * dz;
				const float lim = (ri + (thin[j] ? RAD_THIN : RAD)) * (ri + (thin[j] ? RAD_THIN : RAD));
				if (d2 >= lim) continue;
				if (i < 0) { if (d2 < 1.0e-6f) continue; return false; }
				const float ox = x[j] - x[i], oz = z[j] - z[i];
				if (d2 < ox * ox + oz * oz - 1.0e-7f) return false;
			}
		}
	}
	return true;
}

// Where next at the end of its segment: on along the pavement more often than round the corner, over a crossing now
// and then, never straight back, never from one crossing straight onto the next.
void Crowd::pick_next(int i) {
	const Seg &S = segs[seg[i]];
	const int node = dir[i] > 0 ? S.b : S.a;
	const float *E = &pts[(size_t)(S.p0 + (dir[i] > 0 ? S.np - 2 : 0)) * 3];
	float fx = (E[3] - E[0]) * dir[i], fz = (E[5] - E[2]) * dir[i];
	const float fl = std::sqrt(fx * fx + fz * fz);
	if (fl > 1.0e-5f) { fx /= fl; fz /= fl; }
	nxt[i] = -1;
	for (int pass_ = 0; pass_ < 2 && nxt[i] < 0; pass_++) {
		int opt[8]; float w[8]; int n = 0; float sum = 0.0f;
		for (int k : node_segs[node]) {
			const Seg &N = segs[k];
			if (k == seg[i] || N.np < 2) continue;
			if (pass_ == 0 && S.kind == 1 && N.kind == 1) continue;
			float ww = N.kind == 1 ? 0.45f : 1.0f;
			const bool from_a = N.a == node;
			const float *Q = &pts[(size_t)(N.p0 + (from_a ? 0 : N.np - 2)) * 3];
			float ox = (Q[3] - Q[0]) * (from_a ? 1.0f : -1.0f), oz = (Q[5] - Q[2]) * (from_a ? 1.0f : -1.0f);
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
	const float from_hw = segs[seg[i]].hw;
	const bool from_a = N.a == node;
	const float *P = &pts[(size_t)(N.p0 + (from_a ? 0 : N.np - 2)) * 3];
	float tx = P[3] - P[0], tz = P[5] - P[2];
	const float tl = std::sqrt(tx * tx + tz * tz);
	if (tl > 1.0e-5f) { tx /= tl; tz /= tl; } else { tx = 0.0f; tz = 1.0f; }
	const float ox = from_a ? P[0] : P[3], oz = from_a ? P[2] : P[5];
	const float dx = x[i] - ox, dz = z[i] - oz;
	const float nu = clampf(dx * tx + dz * tz, -1.5f, 1.5f), nl = clampf(dx * tz - dz * tx, -edge_off(N) - 0.22f, edge_off(N) + 0.22f);
	seg[i] = to; dir[i] = from_a ? 1 : -1; u[i] = from_a ? nu : N.len + nu; ls[i] = nl; hint[i] = from_a ? 0 : N.np - 2; nxt[i] = -1;
	looked[i] = 0; wait_t[i] = 0.0f; pass[i] = 0; side_t[i] = 0.0f;
	if (N.kind == 1) {   // a crossing: its own place across the width (on the right half), and where it waits at the kerb
		own_lat[i] = -(0.15f + rnd_of(i) * std::max(edge_off(N) - 0.15f, 0.0f));
		wait_lat[i] = own_lat[i];   // at the kerb they stand on their own half: the other half is where the ones coming over arrive
		hold_u[i] = (from_a ? N.ka : N.kb) - 0.40f;   // toes a hand's width behind the kerb
		(void)from_hw;
	}
}

// Is there time to walk over before the next car is there? (cars standing or creeping wait for people)
bool Crowd::gap_in_cars(const Seg &S, float need) const {
	const int n = (int)cars.size() / 7;
	if (n == 0) return true;
	int h = 0; float mx, my, mz, cx, cz;
	at(S, S.len * 0.5f, 0.0f, h, mx, my, mz, cx, cz);   // the crossing's middle and the way it runs
	for (int c = 0; c < n; c++) {
		const float *q = &cars[(size_t)c * 7];
		const float sp = std::sqrt(q[5] * q[5] + q[6] * q[6]);
		if (sp < 0.8f) continue;
		const float wx = q[5] / sp, wz = q[6] / sp;
		const float dx = mx - q[0], dz = mz - q[1];
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

void Crowd::population() {
	// the pavements people may appear on, once a second
	if (tick - cand_tick >= 20) {
		cand_tick = tick;
		cand.clear(); cand_w.clear(); cand_sum = 0.0f;
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
			cand_sum += S.len * share * DENS[S.zone] * cfg.density / 100.0f;
			cand.push_back(k); cand_w.push_back(cand_sum);
		}
		target = std::min(std::min(cfg.max_peds, (int)MAX_PEDS), (int)cand_sum);
	}
	// who is far, or whose street has left, goes
	if (!cfg.whole || !cell_ok.empty()) {
		for (int i = 0; i < hi; i++) {
			if (!alive[i]) continue;
			const Seg &S = segs[seg[i]];
			const float dx = x[i] - cam_x, dz = z[i] - cam_z;
			const bool gone = (!cfg.whole && dx * dx + dz * dz > cfg.despawn_r * cfg.despawn_r) || (!cell_ok.empty() && (S.cell < 0 || !cell_ok[S.cell]));
			if (gone) { alive[i] = 0; n_alive--; st.despawned++; }
		}
		while (hi > 0 && !alive[hi - 1]) hi--;
	}
	// who is missing appears
	const int tries = tick < 6 ? 4000 : 60;
	for (int t = 0; t < tries && n_alive < target && !cand.empty(); t++) {
		const float r = rnd() * cand_sum;
		const int ci = (int)(std::lower_bound(cand_w.begin(), cand_w.end(), r) - cand_w.begin());
		const int k = cand[std::min(ci, (int)cand.size() - 1)];
		const Seg &S = segs[k];
		const float su = 2.0f + rnd() * (S.len - 4.0f);
		const int d = rnd() < 0.5f ? 1 : -1;
		const float sl = -file_off(S) * (float)d;
		int h = 0; float sx, sy, sz, tx, tz;
		at(S, su, sl, h, sx, sy, sz, tx, tz);
		if (!cfg.whole) {
			const float dx = sx - cam_x, dz = sz - cam_z, dd = std::sqrt(dx * dx + dz * dz);
			if (dd < cfg.ring_in || dd > cfg.ring_out) continue;
			if (dd < cfg.view_r && (cam_fx != 0.0f || cam_fz != 0.0f) && (dx * cam_fx + dz * cam_fz) > 0.5f * dd) continue;   // never close in front of the camera
		}
		// room: nobody within 1.2 m
		bool room = true;
		const int gx = (int)std::floor(sx * 0.5f), gz = (int)std::floor(sz * 0.5f);
		for (int a = -1; a <= 1 && room; a++) for (int b = -1; b <= 1 && room; b++) {
			const int c = (int)(((uint32_t)((gx + a) * 73856093) ^ (uint32_t)((gz + b) * 19349663)) & (GB - 1));
			for (int j = g_head[c]; j >= 0; j = g_next[j]) { const float ex = x[j] - sx, ez = z[j] - sz; if (alive[j] && ex * ex + ez * ez < 1.2f * 1.2f) { room = false; break; } }
		}
		if (!room) continue;
		int i = -1;
		for (int q = 0; q < MAX_PEDS; q++) if (!alive[q]) { i = q; break; }
		if (i < 0) break;
		alive[i] = 1; id[i] = next_id++; seg[i] = k; dir[i] = (int8_t)d; u[i] = su; ls[i] = sl; hint[i] = h; nxt[i] = -1;
		state[i] = ST_WALK; why[i] = WHY_NONE; pass[i] = 0; looked[i] = 0; thin[i] = 0; thin_t[i] = 0.0f;
		x[i] = px[i] = sx; y[i] = py[i] = sy; z[i] = pz[i] = sz; hx[i] = tx * d; hz[i] = tz * d; yaw[i] = pyaw[i] = std::atan2(hx[i], hz[i]);
		rs[i] = rng ^ ((uint64_t)id[i] * 0x9E3779B97F4A7C15ull); if (rs[i] == 0) rs[i] = 1;
		v0[i] = 1.05f + 0.5f * rnd_of(i); v[i] = v0[i];
		look[i] = (uint32_t)(rs[i] >> 20) * 2654435761u;
		wait_t[i] = blocked_t[i] = still_t[i] = pass_t[i] = pause_t[i] = side_t[i] = side_goal[i] = own_lat[i] = wait_lat[i] = hold_u[i] = odo[i] = 0.0f;
		if (i >= hi) hi = i + 1;
		n_alive++; st.spawned++;
		const int c = cell_of(sx, sz);
		g_next[i] = g_head[c]; g_head[c] = (int16_t)i;
	}
}

void Crowd::update(int i, float h, double clock) {
	px[i] = x[i]; py[i] = y[i]; pz[i] = z[i]; pyaw[i] = yaw[i];
	const Seg &S = segs[seg[i]];
	if (state[i] == ST_PAUSE) {   // stands a while where it is (a phone, a shop window)
		pause_t[i] -= h; v[i] = 0.0f; why[i] = WHY_PAUSE; still_t[i] += h;
		if (pause_t[i] <= 0.0f) { state[i] = ST_WALK; still_t[i] = 0.0f; }
		return;
	}
	const int d = dir[i];
	const float rem = d > 0 ? S.len - u[i] : u[i];
	if (nxt[i] < 0 && rem < 10.0f) pick_next(i);
	if (rem <= 0.05f) {
		if (nxt[i] < 0) { dir[i] = (int8_t)-d; pass[i] = 0; return; }   // the pavement ends here: back
		enter(i, nxt[i], d > 0 ? S.b : S.a);
		return;
	}
	const float q = file_off(S), e = edge_off(S);
	float tx, tz, cx, cy, cz;
	at(S, u[i], ls[i], hint[i], cx, cy, cz, tx, tz);
	const float fx = tx * d, fz = tz * d;     // the way it walks
	const float lx = fz, lz = -fx;            // its left
	hx[i] = fx; hz[i] = fz;

	// ---- a crossing: to the kerb, wait there, then over
	bool hold = false;
	float vmax = v0[i];
	uint8_t wy = WHY_NONE;
	if (S.kind == 1) {
		const float gone = d > 0 ? u[i] : S.len - u[i];
		const bool lit = S.phase >= 0 && S.node >= 0;
		const float pace = cross_pace(v0[i]);
		const float rest = S.len - (d > 0 ? S.kb : S.ka) - gone;   // road still to walk
		vmax = pace;
		if (!looked[i]) {
			vmax = v0[i];
			vmax = std::min(v0[i], std::max(0.25f, (hold_u[i] - gone) * 2.5f));   // it slows to the kerb
			if (gone >= hold_u[i] - 0.25f) {
				const float need = std::max(rest, 0.0f) / pace + 2.0f;
				bool go;
				if (lit) {   // while the traffic he crosses has red, and only if he will be over in time (a long crossing: right at the start, and he jogs)
					float left = 0.0f;
					const float window = (float)(SIG_CYCLE * 0.5) - 0.8f;   // (not in the first moment: a late car may still be on it)
					go = walk_light(S, clock, &left) && left <= window && left >= std::min(need, std::max(rest, 0.0f) / JOG + 2.5f);
					wy = WHY_SIGNAL;
				} else {
					go = wait_t[i] >= 0.7f + (float)(look[i] & 7u) * 0.1f;   // it looks first
					wy = WHY_LOOK;
					if (go && !gap_in_cars(S, wait_t[i] > cfg.bold_after ? need * 0.6f : need + 1.5f)) { go = false; wy = WHY_GAP; }
				}
				if (go) { looked[i] = 1; st.crossings++; wait_t[i] = 0.0f; wy = WHY_NONE; vmax = pace; }
				else { hold = gone >= hold_u[i] - 0.03f; wait_t[i] += h; }
			}
		} else if (lit && rest > 0.0f) {   // on its way over: as fast as the light asks
			float left = 0.0f;
			if (!walk_light(S, clock, &left)) vmax = JOG;
			else vmax = clampf(rest / std::max(left - 2.0f, 0.3f), pace, JOG);
		} else if (!lit && rest > 0.0f && !gap_in_cars(S, rest / pace + 3.5f)) vmax = JOG;   // a car comes after all: it runs
	}
	state[i] = hold ? ST_WAIT : (S.kind == 1 ? (looked[i] ? ST_CROSS : ST_WALK) : ST_WALK);

	// ---- now and then somebody stops for a few seconds
	if (cfg.pauses && S.kind == 0 && !pass[i] && rem > 12.0f && S.len - rem > 12.0f && rnd_of(i) < h / 100.0f) {
		state[i] = ST_PAUSE; pause_t[i] = 4.0f + 9.0f * rnd_of(i); v[i] = 0.0f; st.pauses++;
		return;
	}

	// ---- who is near: the one in front, somebody coming, the other file, the place beside
	float lead_gap = BIG, lead_v = 0.0f, onc_gap = BIG;
	int lead_j = -1;
	bool left_busy = false, right_clear = true;
	{
		const int gx = (int)std::floor(x[i] * 0.5f), gz = (int)std::floor(z[i] * 0.5f);
		const float mine = 2.0f * RAD + 0.06f, wide = 2.0f * q + 2.0f * RAD + 0.1f;
		for (int a = -2; a <= 2; a++) {
			for (int b = -2; b <= 2; b++) {
				const int c = (int)(((uint32_t)((gx + a) * 73856093) ^ (uint32_t)((gz + b) * 19349663)) & (GB - 1));
				for (int j = g_head[c]; j >= 0; j = g_next[j]) {
					if (j == i || !alive[j]) continue;
					const float dx = x[j] - x[i], dz = z[j] - z[i];
					const float al = dx * fx + dz * fz, sd = dx * lx + dz * lz;
					if (al < -1.2f || al > 4.0f || std::fabs(sd) > 1.7f) continue;
					const float vj = v[j] * (hx[j] * fx + hz[j] * fz);
					if (al > 0.0f && std::fabs(sd) < mine) {
						if (vj < -0.2f) onc_gap = std::min(onc_gap, al - 2.0f * RAD);
						else if (al - 2.0f * RAD < lead_gap) { lead_gap = al - 2.0f * RAD; lead_v = std::max(vj, 0.0f); lead_j = j; }
					}
					if (al > -0.7f && sd > 0.18f && sd < wide) left_busy = true;
					if (al > -0.9f && al < 1.1f && sd < -0.15f && sd > -wide) right_clear = false;
				}
			}
		}
	}

	// ---- what it does
	float lat_goal = S.kind == 1 ? (looked[i] ? own_lat[i] : wait_lat[i]) : -q;   // (seen along its own way: - = its right)
	float vd = vmax;
	if (pass[i]) {
		pass_t[i] += h;
		if (onc_gap < 3.0f || S.kind == 1 || rem < 3.0f) pass[i] = 0;                 // somebody comes, or the corner: back in
		else if (right_clear && pass_t[i] > 0.8f) { pass[i] = 0; st.passes++; }     // past him
		else lat_goal = q;
	}
	if (lead_gap < BIG) {
		const float vf = lead_v + (lead_gap - 0.30f) / 0.6f;
		if (vf < vd) { vd = std::max(vf, 0.0f); wy = WHY_FOLLOW; }
		if (!pass[i] && S.kind == 0 && v0[i] - lead_v > 0.22f && lead_gap < 1.6f && !left_busy && onc_gap >= BIG && rem > 6.0f) { pass[i] = 1; pass_t[i] = 0.0f; }
	}
	if (onc_gap < BIG) {   // somebody comes at it: each leans to his own right edge, and they slow as they meet
		lat_goal = S.kind == 1 ? std::min(own_lat[i], -q) : -e;
		vd = std::min(vd, std::max(0.3f, onc_gap));
		wy = WHY_ONCOMING;
	}
	if (side_t[i] > 0.0f) { side_t[i] -= h; lat_goal = side_goal[i]; }
	if (hold) vd = 0.0f;
	if (thin[i]) vd = std::min(vd, 0.6f);   // sideways it shuffles
	// Right behind somebody who stands. If he waits at a kerb this one is going to as well, it queues behind him.
	// Otherwise it is held as by any body in its way: it looks for a free place beside him (below).
	bool queued = false;
	if (lead_j >= 0 && lead_gap < 0.5f && lead_v < 0.1f && !hold) {
		const bool to_kerb = S.kind == 1 ? !looked[i] : (nxt[i] >= 0 && segs[nxt[i]].kind == 1 && rem < 4.0f);
		if (state[lead_j] == ST_WAIT && to_kerb) { queued = true; wy = WHY_SIGNAL; }
		else { blocked_t[i] += h; wy = WHY_BLOCKED; }
	}

	// ---- the move, refused if it would end inside somebody
	v[i] = std::max(v[i] + clampf(vd - v[i], -3.5f * h, (vd > v0[i] ? 2.5f : 1.4f) * h), 0.0f);
	const float lt0 = ls[i] * d;
	const float bound = std::max(e, std::fabs(lt0));
	const float lt = clampf(lt0 + clampf(lat_goal - lt0, -0.7f * h, 0.7f * h), -bound, bound);
	float nu = u[i] + d * v[i] * h;
	const float nl = lt * d;
	float nx, ny, nz, ax_, az_;
	int hn = hint[i];
	at(S, nu, nl, hn, nx, ny, nz, ax_, az_);
	bool moved = true;
	if (!free_at(i, nx, nz)) {
		nu = u[i];
		at(S, nu, nl, hn, nx, ny, nz, ax_, az_);
		if (!free_at(i, nx, nz)) moved = false;   // not even sideways
		v[i] = 0.0f;
		blocked_t[i] += h; st.refused++;
		if (!hold) wy = WHY_BLOCKED;
	} else if (v[i] > 0.3f) blocked_t[i] = 0.0f;
	if (moved) {
		const float mx_ = nx - x[i], mz_ = nz - z[i], md = std::sqrt(mx_ * mx_ + mz_ * mz_);
		odo[i] += md;
		still_t[i] = md > 0.002f ? 0.0f : still_t[i] + h;
		u[i] = nu; ls[i] = nl; hint[i] = hn; x[i] = nx; y[i] = ny; z[i] = nz;
	} else still_t[i] += h;
	yaw[i] += clampf(wrap_pi(std::atan2(fx, fz) - yaw[i]), -4.0f * h, 4.0f * h);
	why[i] = wy;
	if (queued) state[i] = ST_WAIT;

	// ---- held for more than a second: a free place beside? Held for long on a pavement: it turns round.
	if (blocked_t[i] > 1.2f && side_t[i] <= 0.0f) {
		const float c3[3] = { -e, 0.0f, e };
		const int k0 = std::min((int)(rnd_of(i) * 3.0f), 2);
		for (int k = 0; k < 3; k++) {
			const float g = c3[(k0 + k) % 3];
			if (std::fabs(g - lt) < 0.12f) continue;
			float sx, sy, sz; int hh = hint[i];
			at(S, u[i] + d * 0.2f, (lt + clampf(g - lt, -0.3f, 0.3f)) * d, hh, sx, sy, sz, ax_, az_);
			if (free_at(i, sx, sz)) { side_goal[i] = g; side_t[i] = 2.5f; st.sidesteps++; break; }
		}
		if (side_t[i] <= 0.0f) side_t[i] = 0.4f, side_goal[i] = lt;   // (nothing free: look again in a moment)
	}
	if (!thin[i] && blocked_t[i] > 3.0f) { thin[i] = 1; thin_t[i] = 0.0f; st.sidled++; }
	else if (thin[i]) {
		thin_t[i] = blocked_t[i] > 0.0f ? 0.0f : thin_t[i] + h;
		if (thin_t[i] > 1.5f && free_at(-1, x[i], z[i]) ) thin[i] = 0;   // (only where it has a whole body's room again)
	}
	if (blocked_t[i] > 9.0f && S.kind == 0 && !hold) { dir[i] = (int8_t)-d; nxt[i] = -1; pass[i] = 0; blocked_t[i] = 0.0f; side_t[i] = 0.0f; st.turned++; }
}

void Crowd::step(float dt, double clock) {
	if (!built) return;
	const auto t0 = std::chrono::steady_clock::now();
	tick++;
	grid();
	if (tick % 5 == 1) population();
	for (int i = 0; i < hi; i++) if (alive[i]) update(i, dt, clock);
	st.step_us = std::chrono::duration<double, std::micro>(std::chrono::steady_clock::now() - t0).count();
}

void Crowd::audit(double clock, int r[4]) const {
	r[0] = r[1] = r[2] = r[3] = 0;
	for (int i = 0; i < hi; i++) {
		if (!alive[i]) continue;
		for (int j = i + 1; j < hi; j++) {
			if (!alive[j]) continue;
			const float dx = x[j] - x[i], dz = z[j] - z[i];
			const float lim = (thin[i] ? RAD_THIN : RAD) + (thin[j] ? RAD_THIN : RAD) - 0.03f;
			if (dx * dx + dz * dz < lim * lim) r[0]++;
		}
		const Seg &S = segs[seg[i]];
		if (std::fabs(ls[i]) > S.hw + 0.05f) r[1]++;
		if (on_road(i) && S.phase >= 0 && S.node >= 0 && !walk_light(S, clock) && !walk_light(S, clock - 1.0)) r[2]++;   // (green for a second already)
		if (still_t[i] > 60.0f) r[3]++;
	}
}

uint64_t Crowd::state_hash() const {
	uint64_t h = 1469598103934665603ull;
	auto mix = [&](uint64_t v_) { h ^= v_; h *= 1099511628211ull; };
	for (int i = 0; i < hi; i++) {
		if (!alive[i]) continue;
		mix((uint64_t)id[i]); mix((uint64_t)seg[i]); mix((uint64_t)(int64_t)std::lround(u[i] * 100.0f)); mix((uint64_t)(int64_t)std::lround(ls[i] * 100.0f));
	}
	return h;
}

} // namespace pc
