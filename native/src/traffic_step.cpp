// traffic2 phase 1: the per-tick part of the traffic core (sensing, speed, junction rules, manoeuvres, population).
// Nothing here allocates (the event list keeps its capacity) and nothing touches Godot types.
#include "traffic_sim.h"

#include <algorithm>
#include <chrono>
#include <cstring>

namespace tc {

namespace {
inline float clampf(float v, float a, float b) { return v < a ? a : (v > b ? b : v); }
inline float adiff(float a, float b) {   // shortest signed angle from a to b
	float d = std::fmod(b - a + 3.14159265f, 6.2831853f);
	if (d < 0) d += 6.2831853f;
	return d - 3.14159265f;
}
} // namespace

void Sim::event(int type, int i, float aux) {
	if (events.size() > 6 * 1024) return;   // nobody is reading: do not grow without bound
	events.push_back((float)type); events.push_back((float)id[i]);
	events.push_back(x[i]); events.push_back(y[i]); events.push_back(z[i]); events.push_back(aux);
}

void Sim::sample(int piece, float s_, int &hint, float &ox, float &oy, float &oz) const {
	int o = p_off[piece], n = p_n[piece];
	if (hint > n - 2) hint = n - 2;
	if (hint < 0) hint = 0;
	while (hint < n - 2 && ptc[o + hint + 1] < s_) hint++;
	while (hint > 0 && ptc[o + hint] > s_) hint--;
	int q = o + hint;
	float sl = ptc[q + 1] - ptc[q];
	float u = sl > 1e-6f ? clampf((s_ - ptc[q]) / sl, 0.0f, 1.0f) : 0.0f;
	ox = ptx[q] + (ptx[q + 1] - ptx[q]) * u; oy = pty[q] + (pty[q + 1] - pty[q]) * u; oz = ptz[q] + (ptz[q + 1] - ptz[q]) * u;
}

// Pose of a box on a piece: position at s shifted sideways by lat, heading along the chord from s - 1.3 to s + 1.3
// (smooth over polyline corners) turned by hoff (the car's own heading offset while it moves sideways).
// out: x, y, z, fx, fz, pitch, yaw
void Sim::pose_at(int piece, float s_, float lat_, float hoff_, float dfx, float dfz, int &hint, float out[7]) const {
	float len = p_len[piece];
	float ax, ay, az, bx, by, bz, cx, cy, cz;
	sample(piece, std::max(s_ - 1.3f, 0.0f), hint, ax, ay, az);
	sample(piece, clampf(s_, 0.0f, len), hint, cx, cy, cz);
	int keep = hint;
	sample(piece, std::min(s_ + 1.3f, len), hint, bx, by, bz);
	hint = keep;
	float tx = bx - ax, tz = bz - az;
	float l = std::sqrt(tx * tx + tz * tz);
	if (l > 1e-3f) { tx /= l; tz /= l; } else { tx = dfx; tz = dfz; }
	out[0] = cx + tz * lat_; out[1] = cy; out[2] = cz - tx * lat_;
	float hx = tx, hz = tz;
	if (hoff_ != 0.0f) {   // + = towards the left of travel (tz, -tx)
		float c = std::cos(hoff_), sn = std::sin(hoff_);
		hx = tx * c + tz * sn; hz = tz * c - tx * sn;
	}
	out[3] = hx; out[4] = hz;
	out[5] = l > 1e-3f ? std::atan2(by - ay, l) : 0.0f;
	out[6] = std::atan2(hx, hz);
}

float Sim::vcap_at(int piece, float s_, int hint) const {
	int o = p_off[piece], n = p_n[piece];
	hint = std::min(std::max(hint, 0), n - 2);
	while (hint < n - 2 && ptc[o + hint + 1] < s_) hint++;
	while (hint > 0 && ptc[o + hint] > s_) hint--;
	int q = o + hint;
	float sl = ptc[q + 1] - ptc[q];
	float u = sl > 1e-6f ? clampf((s_ - ptc[q]) / sl, 0.0f, 1.0f) : 0.0f;
	return ptv[q] + (ptv[q + 1] - ptv[q]) * u;
}

bool Sim::conflict(int a, int b) const {
	for (int k = cf_off[a]; k < cf_off[a] + cf_n[a]; k++) if (cf_idx[k] == b) return true;
	return false;
}

// Next connector at the end of a lane: straight on is preferred, more so on main roads; lanes that are closed off
// or lead nowhere are avoided while there is another choice.
int Sim::pick_next(int lane_) {
	int cs[24]; float ws[24]; int n = 0; float sum = 0.0f;
	for (int pass = 0; pass < 2 && n == 0; pass++) {
		for (int k = l_out_off[lane_]; k < l_out_off[lane_] + l_out_n[lane_] && n < 24; k++) {
			int c = out_conn[k], t = c_to[c];
			if (p_blocked[n_lanes + c] || !(l_flags[t] & LF_DRIVE) || (l_flags[t] & LF_BLOCKED)) continue;
			if (pass == 0 && (l_flags[t] & LF_DEADEND)) continue;
			float tw = c_turn[c] == T_STRAIGHT ? 3.0f + (float)l_class[lane_] : (c_turn[c] == T_UTURN ? 0.02f : 1.0f);
			float wgt = tw * (0.4f + 0.3f * (float)l_class[t]);
			cs[n] = c; ws[n] = wgt; sum += wgt; n++;
		}
	}
	if (n == 0) return -1;
	float r = rnd() * sum;
	for (int k = 0; k < n; k++) { r -= ws[k]; if (r <= 0.0f) return cs[k]; }
	return cs[n - 1];
}

// Distance from the car's nose to the next point it may not pass without a reservation (stop line, or the lane end
// once the nose is past the stop line).
float Sim::entry_dist(int i) const {
	int L = lane[i];
	float front = s[i] + hl[i];
	float base = conn[i] >= 0 ? p_len[n_lanes + conn[i]] - front : -front;
	return base + (line_passed[i] ? p_len[L] : l_stop_s[L]);
}

void Sim::build_window(int i, float LA, Window &w) const {
	int L = lane[i];
	w.np = 0; w.n = 0;
	if (conn[i] >= 0) w.piece[w.np++] = n_lanes + conn[i];
	w.piece[w.np++] = L;
	if (nconn[i] >= 0) {
		w.piece[w.np++] = n_lanes + nconn[i];
		if (w.np < 4) w.piece[w.np++] = c_to[nconn[i]];
	}
	float base = -s[i];
	for (int k = 0; k < w.np; k++) {
		int p = w.piece[k], o = p_off[p], n = p_n[p];
		w.off[k] = base;
		int start = 0;
		if (k == 0) {
			start = std::min(std::max(seg[i], 0), n - 2);
			float sb = s[i] - 8.0f;
			while (start > 0 && ptc[o + start] > sb) start--;
		}
		for (int j = start; j < n; j++) {
			float ws = base + ptc[o + j];
			if (w.n > 0 && ws - w.s[w.n - 1] < 0.05f) continue;   // the joint point of two pieces
			if (w.n == WIN_MAX) return;
			w.x[w.n] = ptx[o + j]; w.z[w.n] = ptz[o + j]; w.s[w.n] = ws; w.n++;
			if (ws > LA) return;
		}
		base += p_len[p];
	}
}

// Project a box on the path window: nearest segment, then the box's extent along and across that segment.
bool Sim::make_track(const Window &w, float qx, float qz, float qfx, float qfz, float qhl, float qhw, float vx, float vz, float band, Track &t, float &vlat) const {
	if (w.n < 2) return false;
	float bd = BIG; int bk = -1;
	for (int k = 0; k < w.n - 1; k++) {
		float ux = w.x[k + 1] - w.x[k], uz = w.z[k + 1] - w.z[k];
		float l2 = ux * ux + uz * uz;
		float tt = l2 > 1e-10f ? clampf(((qx - w.x[k]) * ux + (qz - w.z[k]) * uz) / l2, 0.0f, 1.0f) : 0.0f;
		float dx = qx - (w.x[k] + ux * tt), dz = qz - (w.z[k] + uz * tt);
		float d2 = dx * dx + dz * dz;
		if (d2 < bd) { bd = d2; bk = k; }
	}
	float lim = band + qhl + qhw;
	if (bk < 0 || bd > lim * lim) return false;
	float ux = w.x[bk + 1] - w.x[bk], uz = w.z[bk + 1] - w.z[bk];
	float sl = std::sqrt(ux * ux + uz * uz);
	if (sl < 1e-5f) return false;
	ux /= sl; uz /= sl;
	float rx = qx - w.x[bk], rz = qz - w.z[bk];
	float sc = w.s[bk] + rx * ux + rz * uz;
	float lc = rx * uz - rz * ux;
	float dot = qfx * ux + qfz * uz;
	float c = std::fabs(dot), sn = std::fabs(qfx * uz - qfz * ux);
	float elon = c * qhl + sn * qhw, elat = c * qhw + sn * qhl;
	if (lc - elat > band || lc + elat < -band) return false;
	t.sa = sc - elon; t.sb = sc + elon; t.la = lc - elat; t.lb = lc + elat;
	t.v = vx * ux + vz * uz;
	t.facing = dot < -0.5f;
	vlat = vx * uz - vz * ux;
	return true;
}

int Sim::gather_tracks(int i, const Window &w, float LA, Track *tr) const {
	int nt = 0;
	float R = LA + 14.0f, R2 = R * R, back = -hl[i] - 8.0f;
	float vlat;
	for (int j = 0; j < hi && nt < TRK_MAX - 12; j++) {
		if (!alive[j] || j == i) continue;
		float dx = x[j] - x[i], dz = z[j] - z[i];
		if (dx * dx + dz * dz > R2 || std::fabs(y[j] - y[i]) > 3.0f) continue;
		Track t;
		if (!make_track(w, x[j], z[j], fx[j], fz[j], hl[j], hw[j], v[j] * fx[j], v[j] * fz[j], 7.0f, t, vlat)) continue;
		if (t.sb < back) continue;
		t.type = TRK_CAR; t.idx = (int16_t)j;
		tr[nt++] = t;
	}
	for (int d = 0; d < nd && nt < TRK_MAX - 6; d++) {
		if (d_id[d] == -1 && kind[i] == K_SCRIPTED) continue;   // CityRide's taxi and its own rider / passenger
		float dx = d_x[d] - x[i], dz = d_z[d] - z[i];
		if (dx * dx + dz * dz > R2 || std::fabs(d_y[d] - y[i]) > 3.0f) continue;
		Track t;
		if (!make_track(w, d_x[d], d_z[d], d_fx[d], d_fz[d], d_hl[d], d_hw[d], d_vx[d], d_vz[d], 7.0f, t, vlat)) continue;
		if (t.sb < back) continue;
		// a walker standing at the kerb beside a turning path: after a while it no longer holds the car (the veto still
		// keeps the bodies apart); walkers ON the road always do
		if (d_kind[d] == DYN_PED && !(d_flag[d] & DF_ON_ROAD) && wait_t[i] > 8.0f && why[i] == W_WALKER && d_vx[d] * d_vx[d] + d_vz[d] * d_vz[d] < 0.01f) continue;
		if (d_kind[d] == DYN_XWALK) {   // a walker waiting to cross: yield only when a comfortable stop is still possible
			float gap = t.sa - hl[i];
			if (gap < v[i] * v[i] / (2.0f * cfg.t_b[temper[i]]) + 1.0f) continue;
			if (wait_t[i] > 5.0f && why[i] == W_WALKER) continue;   // courtesy has a limit: the walker waits for a gap
			t.type = TRK_XWALK; t.idx = (int16_t)d; t.facing = false; t.v = 0.0f;
			tr[nt++] = t;
			continue;
		}
		// where it will be when the car gets there (a pedestrian stepping off the kerb)
		float tp = clampf((t.sa - hl[i]) / std::max(v[i], 1.0f), 0.3f, 2.5f);
		if (vlat > 0.0f) t.lb += vlat * tp; else t.la += vlat * tp;
		t.type = TRK_DYN; t.idx = (int16_t)d; t.facing = false;
		tr[nt++] = t;
	}
	for (int k = 0; k < w.np; k++) {
		int p = w.piece[k];
		for (int e = in_off[p]; e < in_off[p] + in_n[p] && nt < TRK_MAX; e++) {
			float s0 = w.off[k] + in_s0[e], s1 = w.off[k] + in_s1[e];
			if (s1 < back) continue;
			if (s0 > LA) break;
			Track t;
			t.sa = s0; t.sb = s1; t.la = in_l0[e]; t.lb = in_l1[e]; t.v = 0.0f; t.type = TRK_STATIC; t.idx = (int16_t)(e & 0x7fff); t.facing = false;
			tr[nt++] = t;
		}
	}
	for (int a = 1; a < nt; a++) {   // nearest first
		Track t = tr[a];
		int b = a - 1;
		while (b >= 0 && tr[b].sa > t.sa) { tr[b + 1] = tr[b]; b--; }
		tr[b + 1] = t;
	}
	return nt;
}

void Sim::revoke(int i) {
	if (!(flags[i] & F_RES)) return;
	int c = nconn[i];
	for (int k = 0; k < MAX_HELD; k++) {
		if (h_conn[i][k] == c && h_rem[i][k] >= BIG * 0.5f) { h_conn[i][k] = -1; c_res[c]--; break; }
	}
	for (int q = 0; q < chain_n[i]; q++) {
		int cc = chain_c[i][q];
		for (int k = 0; k < MAX_HELD; k++) {
			if (h_conn[i][k] == cc && h_rem[i][k] >= BIG * 0.5f) { h_conn[i][k] = -1; c_res[cc]--; break; }
		}
	}
	chain_n[i] = 0;
	flags[i] &= ~(uint32_t)F_RES;
	st.revoked++;
}

void Sim::release_all(int i) {
	for (int k = 0; k < MAX_HELD; k++) {
		if (h_conn[i][k] >= 0) { c_res[h_conn[i][k]]--; h_conn[i][k] = -1; }
	}
	chain_n[i] = 0;
	flags[i] &= ~(uint32_t)F_RES;
}

// Ask for the movement through the junction. Returns 0 when granted, else the reason (W_*).
int Sim::try_reserve(int i, float de) {
	int c = nconn[i], L = lane[i];
	int tp = temper[i];
	int prio = c_prio[c];
	int node = c_node[c];
	int slot = -1;
	for (int k = 0; k < MAX_HELD; k++) if (h_conn[i][k] < 0) { slot = k; break; }
	auto why_ = [&](int code, int other, float val, int w) { yinfo[i][0] = (float)code; yinfo[i][1] = (float)other; yinfo[i][2] = val; return w; };
	if (slot < 0) return why_(6, -1, 0.0f, W_YIELD);
	if (l_ctl[L] == C_SIGNAL) {
		int sg = signal_state(L, clock);
		// The map's signals have no left-turn phase and a short green. So, as drivers do: a car that has stood at its
		// line waiting to turn left takes the amber, and the first two seconds of red, once the oncoming traffic has
		// stopped (it still gives way to whoever is coming, below; the cross street waits for it: it holds the path).
		const bool left_waited = c_turn[c] == T_LEFT && stop_tick[i] >= 0 && (float)(tick - stop_tick[i]) * dt >= 1.0f;
		if (sg == SIG_YELLOW) {
			if (!left_waited && v[i] * v[i] / (2.0f * 3.0f) < de - 0.5f) return W_SIGNAL;   // can stop: stop
		} else if (sg == SIG_RED) {
			// right turn on red: after a full stop, give way to everybody
			if (c_turn[c] == T_RIGHT && stop_tick[i] >= 0 && (float)(tick - stop_tick[i]) * dt >= 1.0f) prio = -1000;
			else if (left_waited && signal_red_age(L, clock) < 6.0f) {}
			else return W_SIGNAL;
		}
	} else if (l_ctl[L] == C_STOP) {
		if (stop_tick[i] < 0 || (float)(tick - stop_tick[i]) * dt < cfg.t_stop_wait[tp]) return W_STOPSIGN;
		for (int j = 0; j < hi; j++) {   // first come, first served among the cars waiting at this junction's stop lines
			if (!alive[j] || j == i || conn[j] >= 0 || nconn[j] < 0 || stop_tick[j] < 0 || (flags[j] & F_RES)) continue;
			if (c_node[nconn[j]] != node || l_ctl[lane[j]] != C_STOP || why[j] == W_EXIT) continue;
			if (stop_tick[j] > stop_tick[i] || (stop_tick[j] == stop_tick[i] && id[j] > id[i])) continue;
			if (conflict(c, nconn[j])) return why_(2, id[j], 0.0f, W_STOPSIGN);
		}
	}
	// FAIRNESS. Somebody who has waited long at the head of a lane has asked for a path that crosses this one: a car
	// that can still stop comfortably before its line lets them go first.
	//  - at signals the asker is a left-turner taking the amber (and the first moments of red): the street that has
	//    just got its green waits for it, as drivers wait for the junction to clear;
	//  - elsewhere (a side street at a stop line) it counts against cars that have waited less than the asker.
	const float my_wait = stop_tick[i] >= 0 ? wait_t[i] : 0.0f;
	// may this car ask for its path itself, if it is refused below?
	bool may_ask = false;
	if (stop_tick[i] >= 0) {
		if (l_ctl[L] == C_SIGNAL) {
			const int sg = signal_state(L, clock);
			may_ask = c_turn[c] == T_LEFT && (sg == SIG_YELLOW || (sg == SIG_RED && signal_red_age(L, clock) < 6.0f));
			// ... and a car that goes straight on or turns right and still stands at its line on GREEN: the oncoming
			// cars that turn left across it are to let it go (straight before left). Without this a steady stream of
			// left-turners, each cleared while still rolling up to the line, kept the junction for the whole green
			// (3rd St x a side street: a car stood through four greens).
			if (c_turn[c] != T_LEFT && sg == SIG_GREEN) may_ask = true;
		} else may_ask = wait_t[i] > cfg.ask_after_s;
	}
	// (a car that stands at its line can always stay: before 19 Nov only one with half a metre to spare counted, and a
	// car stopped with its nose ON the line never let anybody through: Amber x 6th, a left-turner stood four greens)
	if (v[i] < 0.5f || v[i] * v[i] / (2.0f * cfg.t_b[tp]) < de - 0.5f) {
		for (int k = cf_off[c]; k < cf_off[c] + cf_n[c]; k++) {
			const int q = cf_idx[k];
			if (c_ask[q] < 0 || c_ask[q] == id[i] || tick - c_ask_tick[q] > 12) continue;
			const int Lq = c_from[q];
			// between two cars that may both ask (two left-turners facing each other on amber, two side streets), the
			// one that has waited longer goes first; they never wait for each other
			const bool i_first = c_ask_wait[q] < my_wait || (c_ask_wait[q] == my_wait && c_ask[q] > id[i]);
			if ((l_ctl[Lq] != C_SIGNAL || may_ask) && i_first) continue;
			st.let_through++;
			return why_(7, c_ask[q], (float)q, W_YIELD);
		}
	}
	auto ask = [&]() {
		if (!may_ask) return;
		if (c_ask[c] != id[i] || tick - c_ask_tick[c] > 12) st.asks++;
		c_ask[c] = id[i]; c_ask_tick[c] = tick; c_ask_wait[c] = wait_t[i];
	};
	// a link shorter than the car between two junction nodes (median crossings, offset junctions) is part of the
	// junction: the move out of it is reserved together with the move into it, so nobody ever stops inside
	int chain[MAX_CHAIN];
	int nch = 0;
	int exit_lane = c_to[c];
	{
		int to = c_to[c];
		while (nch < MAX_CHAIN && short_link(i, to) && l_out_n[to] > 0) {
			int c2 = kind[i] == K_AMBIENT || rt[i].empty() ? pick_next(to) : peek_routed(i, to);
			if (c2 < 0) break;
			if (l_ctl[to] == C_SIGNAL && signal_state(to, clock) != SIG_GREEN) return why_(1, -1, 0.0f, W_SIGNAL);
			chain[nch++] = c2;
			to = c_to[c2];
		}
		exit_lane = to;
		int free_slots = 0;
		for (int k = 0; k < MAX_HELD; k++) if (h_conn[i][k] < 0) free_slots++;
		if (free_slots < nch + 1) return why_(6, -1, 0.0f, W_YIELD);
	}
	// nobody is in, or cleared to enter, a conflicting movement (of the chained moves too)
	for (int q = 0; q < nch; q++) {
		int c2 = chain[q];
		for (int k = cf_off[c2]; k < cf_off[c2] + cf_n[c2]; k++) {
			if (c_res[cf_idx[k]] <= 0) continue;
			bool mine = false;
			for (int r = 0; r < MAX_HELD; r++) if (h_conn[i][r] == cf_idx[k]) mine = true;
			if (!mine) return why_(3, -1, (float)cf_idx[k], W_YIELD);
		}
	}
	for (int k = cf_off[c]; k < cf_off[c] + cf_n[c]; k++) {
		if (c_res[cf_idx[k]] <= 0) continue;
		int holder = -1;
		for (int j = 0; j < hi && holder < 0; j++) if (alive[j]) for (int q = 0; q < MAX_HELD; q++) if (h_conn[j][q] == cf_idx[k]) holder = id[j];
		ask();
		return why_(3, holder, (float)cf_idx[k], W_YIELD);
	}
	// give way: traffic with right of way that would arrive before this car is out of the junction
	{
		float D = std::max(de, 0.0f) + p_len[n_lanes + c] + 2.0f * hl[i];
		float a = cfg.t_a[tp] * 0.7f;
		float t_clear = (-v[i] + std::sqrt(v[i] * v[i] + 2.0f * a * D)) / a + cfg.t_gap[tp];
		for (int j = 0; j < hi; j++) {
			if (!alive[j] || j == i || nconn[j] < 0 || (flags[j] & F_RES)) continue;
			int cj = nconn[j];
			if (c_node[cj] != node || c_prio[cj] <= prio) continue;
			int Lj = lane[j];
			if (l_ctl[Lj] == C_STOP) continue;
			if (l_ctl[Lj] == C_SIGNAL) {
				const int sj = signal_state(Lj, clock);
				if (sj == SIG_RED) continue;
				// on amber, a car that can still stop comfortably before its line will stop: it is not coming
				if (sj == SIG_YELLOW && v[j] * v[j] / (2.0f * 3.0f) < entry_dist(j) - 0.5f) continue;
			}
			if (!conflict(c, cj)) continue;
			// a car standing at its line that is itself held (no room behind its exit, a walker on its path) is not coming
			if (v[j] < 0.5f && wait_t[j] > 2.0f && !(flags[j] & F_RES)) continue;
			float dj = std::max(entry_dist(j), 0.0f);
			if (dj / std::max(v[j], 2.5f) < t_clear) {
				// (a car that would let this one through, because it has asked and they can stop, is not "coming")
				if (c_ask[c] == id[i] && tick - c_ask_tick[c] <= 12 && v[j] * v[j] / (2.0f * cfg.t_b[temper[j]]) < dj - 0.5f) continue;
				ask();
				return why_(4, id[j], dj, W_YIELD);
			}
		}
	}
	// do not block the box: room for the whole car behind the last car on the exit lane (after a short link: its exit)
	{
		int to = exit_lane;
		float need = 2.0f * hl[i] + 1.5f;
		float minrear = p_len[to], tail_v = BIG, inbound = 0.0f;
		int tail_id = -1;
		for (int j = 0; j < hi; j++) {
			if (!alive[j] || j == i) continue;
			if (lane[j] == to) {
				if (conn[j] < 0) { float rear = s[j] - hl[j]; if (rear < minrear) { minrear = rear; tail_v = v[j]; tail_id = id[j]; } }
				else inbound += 2.0f * hl[j] + 1.5f;
			} else {
				bool in_ = (flags[j] & F_RES) && c_to[nconn[j]] == to;
				for (int q = 0; q < chain_n[j] && !in_; q++) in_ = c_to[chain_c[j][q]] == to;
				if (in_) inbound += 2.0f * hl[j] + 1.5f;
			}
		}
		float free_ = minrear - inbound;
		if (p_len[to] < need) { if (inbound > 0.0f || minrear < p_len[to]) return why_(5, tail_id, free_, W_EXIT); }
		else if (free_ < need && !(tail_v < BIG * 0.5f && tail_v > 3.0f && free_ > 2.0f)) return why_(5, tail_id, free_, W_EXIT);
	}
	h_conn[i][slot] = c; h_rem[i][slot] = BIG;
	c_res[c]++;
	chain_n[i] = 0;
	for (int q = 0; q < nch; q++) {
		for (int k = 0; k < MAX_HELD; k++) if (h_conn[i][k] < 0) { h_conn[i][k] = chain[q]; h_rem[i][k] = BIG; c_res[chain[q]]++; break; }
		chain_c[i][chain_n[i]++] = chain[q];
	}
	flags[i] |= F_RES;
	st.reservations++;
	return 0;
}

int Sim::blocked_by(int i, float bx, float by, float bz, float bfx, float bfz, float infl) {
	float ahl = hl[i] + infl, ahw = hw[i] + infl;
	for (int j = 0; j < hi; j++) {
		if (!alive[j] || j == i) continue;
		float dx = x[j] - bx, dz = z[j] - bz, rr = rad[i] + rad[j] + 0.3f;
		if (dx * dx + dz * dz > rr * rr || std::fabs(y[j] - by) > 2.5f) continue;
		if (obb_overlap(bx, bz, bfx, bfz, ahl, ahw, x[j], z[j], fx[j], fz[j], hl[j], hw[j])) { veto_by[i] = id[j]; return 1; }
	}
	if (static_overlap(bx, by, bz, bfx, bfz, ahl, ahw)) { veto_by[i] = -2; return 2; }
	for (int d = 0; d < nd; d++) {
		if (d_kind[d] == DYN_XWALK || (d_id[d] == -1 && kind[i] == K_SCRIPTED) || std::fabs(d_y[d] - by) > 2.5f) continue;
		if (obb_overlap(bx, bz, bfx, bfz, ahl, ahw, d_x[d], d_z[d], d_fx[d], d_fz[d], d_hl[d], d_hw[d])) { veto_by[i] = -3; return 3; }
	}
	veto_by[i] = -1;
	return 0;
}

// Can the car move over to the neighbour lane nb right now? Gives its position in nb's frame.
bool Sim::lane_change_ok(int i, int nb, float &ns, float &nlat, bool relax) const {
	int L = lane[i];
	if (conn[i] >= 0 || nb < 0 || (line_passed[i] && !relax)) return false;
	if (!relax && (!(l_flags[nb] & LF_DRIVE) || (l_flags[nb] & (LF_BLOCKED | LF_DEADEND)))) return false;
	const float end_min = relax ? 10.0f : 25.0f;   // room to straighten up before the junction
	if (v[i] < 2.0f) return false;   // only on the move: a car standing in a queue cannot slide over
	if (p_len[L] - s[i] < end_min || s[i] < 3.0f) return false;
	// project the car on nb
	int o = p_off[nb], n = p_n[nb];
	float bd = BIG; int bk = -1; float bt = 0.0f;
	for (int k = 0; k < n - 1; k++) {
		float ux = ptx[o + k + 1] - ptx[o + k], uz = ptz[o + k + 1] - ptz[o + k];
		float l2 = ux * ux + uz * uz;
		float tt = l2 > 1e-10f ? clampf(((x[i] - ptx[o + k]) * ux + (z[i] - ptz[o + k]) * uz) / l2, 0.0f, 1.0f) : 0.0f;
		float dx = x[i] - (ptx[o + k] + ux * tt), dz = z[i] - (ptz[o + k] + uz * tt);
		float d2 = dx * dx + dz * dz;
		if (d2 < bd) { bd = d2; bk = k; bt = tt; }
	}
	if (bk < 0) return false;
	float ux = ptx[o + bk + 1] - ptx[o + bk], uz = ptz[o + bk + 1] - ptz[o + bk];
	float sl = std::sqrt(ux * ux + uz * uz);
	if (sl < 1e-5f) return false;
	ux /= sl; uz /= sl;
	ns = ptc[o + bk] + sl * bt;
	nlat = (x[i] - ptx[o + bk]) * uz - (z[i] - ptz[o + bk]) * ux;
	if (std::fabs(nlat) > 5.5f || std::fabs(nlat) < 1.0f) return false;
	if (ns < 3.0f || p_len[nb] - ns < (relax ? 1.5f : 22.0f)) return false;
	// gaps in the target lane, in the car's own frame (the lane centre is -nlat to the side)
	float dl = -nlat;
	float lx = fz[i], lz = -fx[i];
	auto gap_ok = [&](float qx, float qz, float qhl, float qhw, float qv) {
		float rx = qx - x[i], rz = qz - z[i];
		float along = rx * fx[i] + rz * fz[i], side = rx * lx + rz * lz;
		float reach = std::max(qhl, qhw);
		if (std::fabs(side - dl) > reach + hw[i] + 0.4f) return true;
		if (along >= 0.0f) return along - hl[i] - reach >= 3.0f + std::max(0.0f, v[i] - qv) * 1.5f;
		return -along - hl[i] - reach >= 3.0f + std::max(0.0f, qv - v[i]) * 2.0f + qv * 0.6f;
	};
	for (int j = 0; j < hi; j++) {
		if (!alive[j] || j == i) continue;
		float dx = x[j] - x[i], dz = z[j] - z[i];
		if (dx * dx + dz * dz > 60.0f * 60.0f) continue;
		float qv = v[j] * (fx[j] * fx[i] + fz[j] * fz[i]);
		if (!gap_ok(x[j], z[j], hl[j], hw[j], qv)) return false;
	}
	for (int d = 0; d < nd; d++) {
		if (d_kind[d] == DYN_XWALK) continue;
		float qv = d_vx[d] * fx[i] + d_vz[d] * fz[i];
		if (!gap_ok(d_x[d], d_z[d], d_hl[d], d_hw[d], qv)) return false;
	}
	for (int e = in_off[nb]; e < in_off[nb] + in_n[nb]; e++) {   // parked boxes in the target lane just ahead
		if (in_s1[e] < ns - 6.0f || in_s0[e] > ns + 25.0f) continue;
		if (in_l0[e] < hw[i] + 0.3f && in_l1[e] > -hw[i] - 0.3f) return false;
	}
	return true;
}

// Is the strip on the oncoming side free for a pass of length dpass at lateral offset lreq?
bool Sim::pass_clear(int i, const Window &w, const Track *tr, int nt, int blk, float lreq, float dpass) const {
	float lo = lreq - hw[i] - 0.3f, hi_ = lreq + hw[i] + 0.3f;
	for (int k = 0; k < nt; k++) {
		if (k == blk || tr[k].type == TRK_XWALK) continue;
		const Track &u = tr[k];
		if (u.lb <= lo || u.la >= hi_) continue;
		float g = u.sa - hl[i];
		if (u.v < -0.5f || u.facing) {
			if (g < dpass + (-std::min(u.v, 0.0f)) * (dpass / 3.5f + 2.0f) + 12.0f) return false;
		} else if (g < dpass + 5.0f && u.sb > -hl[i] - 2.0f) return false;
	}
	// parked boxes on the other side of the road
	float R = dpass + 12.0f;
	int cx0 = std::max(0, (int)((x[i] - R - gx0) / GC)), cx1 = std::min(gw - 1, (int)((x[i] + R - gx0) / GC));
	int cz0 = std::max(0, (int)((z[i] - R - gz0) / GC)), cz1 = std::min(gh - 1, (int)((z[i] + R - gz0) / GC));
	float vlat;
	for (int cz = cz0; cz <= cz1 && !sb_x.empty(); cz++) {
		for (int cx = cx0; cx <= cx1; cx++) {
			int c = cz * gw + cx;
			for (int e = bg_off[c]; e < bg_off[c + 1]; e++) {
				int b = bg_idx[e];
				Track t;
				if (!make_track(w, sb_x[b], sb_z[b], sb_fx[b], sb_fz[b], sb_hl[b], sb_hw[b], 0.0f, 0.0f, 7.0f, t, vlat)) continue;
				if (t.lb <= lo || t.la >= hi_) continue;
				if (t.sa - hl[i] < dpass + 4.0f && t.sb > -hl[i] - 1.0f) {
					// the blocker itself (and its row) shows up here too: it is to the right of the pass strip's centre
					if (t.lb <= lreq - hw[i] - 0.05f) continue;
					return false;
				}
			}
		}
	}
	return true;
}

// Advance along the path (lane -> reserved connector -> lane), keep the reservations up to date.
void Sim::commit_move(int i, float ds) {
	s[i] += ds;
	for (int step_ = 0; step_ < 2; step_++) {
		int L = lane[i];
		if (conn[i] < 0) {
			if (s[i] < p_len[L]) break;
			if (!(flags[i] & F_RES) || nconn[i] < 0) { s[i] = p_len[L] - 0.01f; break; }
			int c = nconn[i];
			s[i] -= p_len[L];
			conn[i] = c; lane[i] = c_to[c];
			flags[i] &= ~(uint32_t)F_RES;
			line_passed[i] = 0; stop_tick[i] = -1; seg[i] = 0;
			for (int k = 0; k < MAX_HELD; k++) {
				if (h_conn[i][k] == c && h_rem[i][k] >= BIG * 0.5f) { h_rem[i][k] = p_len[n_lanes + c] - s[i] + hl[i] + 0.6f + ds; break; }
			}
			if (!rt[i].empty() && rt_i[i] + 1 < (int)rt[i].size() && rt[i][rt_i[i] + 1] == lane[i]) rt_i[i]++;
			if (chain_n[i] > 0 && c_from[chain_c[i][0]] == lane[i]) {   // a short link: the way out is already reserved
				nconn[i] = chain_c[i][0];
				for (int q = 1; q < chain_n[i]; q++) chain_c[i][q - 1] = chain_c[i][q];
				chain_n[i]--; lc_need[i] = 0;
				flags[i] |= F_RES;
			} else { chain_n[i] = 0; nconn[i] = pick_routed(i, lane[i]); }
		} else {
			int p = n_lanes + conn[i];
			if (s[i] < p_len[p]) break;
			s[i] -= p_len[p];
			conn[i] = -1; seg[i] = 0;
		}
	}
	{
		int p = conn[i] >= 0 ? n_lanes + conn[i] : lane[i];
		if (s[i] > p_len[p] - 0.01f) s[i] = p_len[p] - 0.01f;
	}
	for (int k = 0; k < MAX_HELD; k++) {
		if (h_conn[i][k] < 0 || h_rem[i][k] >= BIG * 0.5f) continue;
		h_rem[i][k] -= ds;
		if (h_rem[i][k] <= 0.0f) { c_res[h_conn[i][k]]--; h_conn[i][k] = -1; }
	}
	if (man[i] == MAN_PASS) pass_rem[i] -= ds;
}

void Sim::update_car(int i, float h) {
	// ---- the pose shown right now becomes the "from" pose of the next interpolation span
	{
		float u = span[i] > 0 ? clampf((float)(tick - tu[i]) / (float)span[i], 0.0f, 1.0f) : 1.0f;
		px[i] += (x[i] - px[i]) * u; py[i] += (y[i] - py[i]) * u; pz[i] += (z[i] - pz[i]) * u;
		pyaw[i] += adiff(pyaw[i], yaw[i]) * u; ppitch[i] += (pitch[i] - ppitch[i]) * u;
	}
	tu[i] = tick;
	span[i] = tier[i] == TIER_FULL ? 1 : (tier[i] == TIER_MID ? 4 : 8);
	honk_cd[i] = std::max(0.0f, honk_cd[i] - h);
	hard_cd[i] = std::max(0.0f, hard_cd[i] - h);
	const int tp = temper[i];
	const float hl_ = hl[i], hw_ = hw[i];
	const float v_ = v[i];
	const float bc = cfg.t_b[tp], am = cfg.t_a[tp];
	uint32_t nf = flags[i] & (uint32_t)F_RES;

	// ---- held by a scene (boarding, a cutscene): stands where it is
	if (hold_[i]) {
		acc[i] = 0.0f; v[i] = 0.0f; latv[i] = 0.0f; why[i] = W_GOAL; wait_t[i] += h;
		flags[i] = (flags[i] & (uint32_t)F_RES) | F_BRAKE;
		return;
	}

	// ---- a dynamic box (player's car, pedestrian) moved into the car: stop, wait, then drive on
	int touch = -1;
	for (int d = 0; d < nd; d++) {
		if (d_kind[d] == DYN_XWALK || (d_id[d] == -1 && kind[i] == K_SCRIPTED) || std::fabs(d_y[d] - y[i]) > 2.5f) continue;
		if (obb_overlap(x[i], z[i], fx[i], fz[i], hl_ + 0.02f, hw_ + 0.02f, d_x[d], d_z[d], d_fx[d], d_fz[d], d_hl[d], d_hw[d])) { touch = d; break; }
	}
	if (touch >= 0) {
		if (!touching[i]) {
			touching[i] = 1;
			crash_t[i] = 3.0f + 3.0f * rnd();
			st.crashes++;
			event(E_CRASH, i, (float)d_id[touch]);
		}
		crash_t[i] = std::max(crash_t[i], 1.5f);
	} else touching[i] = 0;
	if (touch >= 0 || crash_t[i] > 0.0f) {
		if (touch < 0) crash_t[i] = std::max(0.0f, crash_t[i] - h);
		acc[i] = 0.0f; v[i] = 0.0f; latv[i] = 0.0f; why[i] = W_CRASH; wait_t[i] += h;
		steer[i] *= 0.5f; latacc[i] = 0.0f;
		flags[i] = nf | F_BRAKE | (touch >= 0 ? (uint32_t)F_EMERG : 0u);
		return;
	}

	int L = lane[i];
	const int cp = conn[i] >= 0 ? n_lanes + conn[i] : L;
	float LA = clampf(v_ * v_ / (2.0f * bc) + v_ * 1.5f + 14.0f, 18.0f, 90.0f);
	if (long_look[i]) LA = std::max(LA, 110.0f);
	Window w;
	build_window(i, LA, w);
	Track tr[TRK_MAX];
	const int nt = gather_tracks(i, w, LA, tr);

	// ---- routed car with a goal (bus stop, CityRide kerb): distance from the car's centre to the goal point
	float dg = BIG;
	if (kind[i] != K_AMBIENT && goal_ri[i] >= 0 && goal_ri[i] < (int)rt[i].size()) {
		if (rt_i[i] == goal_ri[i]) dg = (conn[i] >= 0 ? p_len[cp] - s[i] : -s[i]) + goal_s[i];
		else if (rt_i[i] + 1 == goal_ri[i] && conn[i] < 0 && nconn[i] >= 0 && c_to[nconn[i]] == rt[i][goal_ri[i]])
			dg = p_len[L] - s[i] + p_len[n_lanes + nconn[i]] + goal_s[i];
	}

	// ---- sideways: where in the lane to drive
	const float lane_hw = p_hw[cp];
	const float lim = std::max(lane_hw - hw_ - 0.05f, 0.0f);
	float amin = std::min(-lim, lat[i]), amax = std::max(lim, lat[i]);
	float want = 0.0f;
	if (man[i] == MAN_PASS && pass_rem[i] > 0.0f) { want = pass_lat[i]; amax = std::max(amax, want); }
	else if (pull[i] && dg < 45.0f && conn[i] < 0) { want = goal_lat[i]; amin = std::min(amin, want); amax = std::max(amax, want); }
	for (int k = 0; k < nt; k++) {   // boxes alongside: never move into them
		const Track &t = tr[k];
		if (t.type == TRK_XWALK || t.sa >= hl_ + 0.5f || t.sb <= -hl_ - 0.5f) continue;
		if (t.la >= lat[i] + hw_ - 0.05f) amax = std::min(amax, std::max(lat[i], t.la - hw_ - 0.25f));
		else if (t.lb <= lat[i] - hw_ + 0.05f) amin = std::max(amin, std::min(lat[i], t.lb + hw_ + 0.25f));
	}
	int blk = -1;
	const float avoid_r = std::max(16.0f, v_ * 3.5f);
	for (int k = 0; k < nt; k++) {   // slow or standing boxes ahead: go around inside the lane when there is room
		const Track &t = tr[k];
		float gap = t.sa - hl_;
		if (t.type == TRK_XWALK || t.sb <= -hl_ - 1.0f || gap > avoid_r) continue;
		if (t.type != TRK_STATIC && std::fabs(t.v) >= 1.5f) continue;
		bool ped = t.type == TRK_DYN && d_kind[t.idx] == DYN_PED;
		if (ped && d_vx[t.idx] * d_vx[t.idx] + d_vz[t.idx] * d_vz[t.idx] > 0.09f) continue;   // a walker on the move: wait for them
		float m = ped ? 0.6f : 0.3f;
		float cur = clampf(want, amin, amax);
		if (t.lb <= cur - hw_ - m || t.la >= cur + hw_ + m) continue;
		float lreq = t.lb + hw_ + m, rreq = t.la - hw_ - m;
		bool okl = lreq <= amax + 1e-3f, okr = rreq >= amin - 1e-3f;
		if (okl && okr) { if (std::fabs(lreq - want) <= std::fabs(rreq - want)) okr = false; else okl = false; }
		if (okl) amin = std::max(amin, lreq);
		else if (okr) amax = std::min(amax, rreq);
		else if (blk < 0 && gap > -0.5f) blk = k;
	}
	const float lat_t = amin <= amax ? clampf(want, amin, amax) : lat[i];

	// ---- ahead: everything in the car's corridor is a leader (IDM) and bounds the safe speed
	const float ratio = man[i] != MAN_NONE ? 0.9f : 0.4f;
	float a_int = 0.0f, vsafe = BIG, lead_gap = BIG;
	int lead = -1;
	for (int k = 0; k < nt; k++) {
		const Track &t = tr[k];
		float gap = t.sa - hl_;
		if (gap < -0.3f) continue;   // alongside or behind
		float reach = 0.7f * ratio * std::max(gap, 0.0f);
		float lr = lat[i] + clampf(lat_t - lat[i], -reach, reach);
		bool ped = t.type == TRK_DYN && d_kind[t.idx] == DYN_PED;
		float m = ped ? 0.5f : (std::fabs(t.v) > 1.0f ? 0.2f : 0.3f);
		if (t.lb <= lr - hw_ - m || t.la >= lr + hw_ + m) continue;
		float vl = t.v, g = gap;
		if (vl < -0.3f || t.facing) { g = gap + std::min(vl, 0.0f) * 2.0f - 10.0f; vl = 0.0f; }   // head on: keep well back
		float s0 = cfg.t_s0[tp];
		if (t.type == TRK_STATIC) s0 = 6.5f;   // room to pull out around it
		else if (t.type == TRK_XWALK) s0 = 2.0f;
		else if (t.type == TRK_DYN) s0 = ped ? 2.5f : (std::fabs(t.v) < 0.5f ? 4.5f : s0);
		else if (crash_t[t.idx] > 0.0f) s0 = 4.5f;
		if (gap < lead_gap) { lead_gap = gap; lead = k; }
		float ge = std::max(g, 0.1f);
		float dv = v_ - vl;
		float ss = s0 + std::max(0.0f, v_ * cfg.t_T[tp] + v_ * dv / (2.0f * std::sqrt(am * bc)));
		a_int = std::min(a_int, -am * (ss / ge) * (ss / ge));
		float b = 0.9f * cfg.b_hard;
		vsafe = std::min(vsafe, -b * h + std::sqrt(b * b * h * h + vl * vl + 2.0f * b * std::max(g - 0.6f, 0.0f)));
	}

	// ---- junction: stop point until the movement is reserved
	const float front = s[i] + hl_;
	float de_line, de_end;
	if (conn[i] < 0) { de_line = l_stop_s[L] - front; de_end = p_len[L] - front; }
	else { float base = p_len[cp] - front; de_line = base + l_stop_s[L]; de_end = base + p_len[L]; }
	if (!line_passed[i] && de_line < -0.4f) line_passed[i] = 1;
	const float de = line_passed[i] ? de_end : de_line;
	float stop_d = BIG, v0_e2 = BIG;
	int wj = W_NONE;
	bool res = (flags[i] & F_RES) != 0;
	if (nconn[i] < 0 && (l_flags[L] & LF_EXIT)) {
		// the map ends here: it drives on at its speed and is taken out as it reaches the end (population())
	} else if (nconn[i] < 0) {
		stop_d = de_end;
		if (v_ < 0.3f && de_end < 3.0f) wj = W_DEADEND;
	} else {
		if (res && l_ctl[L] == C_SIGNAL && !line_passed[i] && !short_link(i, L)) {   // the light changed after the go-ahead
			int sg = signal_state(L, clock);
			bool rtor = c_turn[nconn[i]] == T_RIGHT && stop_tick[i] >= 0;
			bool must = (sg == SIG_RED && !rtor) || (sg == SIG_YELLOW && v_ * v_ / (2.0f * 3.0f) < de_line - 0.5f);
			if (must && v_ * v_ / (2.0f * cfg.b_hard) < de_line - 0.3f) { revoke(i); res = false; }
		}
		if (!res) {
			bool first = lead_gap > de - 0.3f;
			if (stop_tick[i] < 0 && v_ < 0.15f && de < 2.5f && first) stop_tick[i] = tick;   // the full stop at the line
			if (!first && lead >= 0 && tr[lead].type == TRK_CAR) {   // the car ahead is already going through from this lane
				int j = tr[lead].idx;
				first = (conn[j] < 0 && lane[j] == L && (flags[j] & F_RES)) || (conn[j] >= 0 && c_from[conn[j]] == L);
				if (l_ctl[L] == C_STOP) first = false;
			}
			float d_res = v_ * v_ / (2.0f * bc) + v_ * 1.0f + 8.0f;
			// never into the junction while still out to the side (a late lane change, a pass): straighten up first
			// (but not for ever: a car that stopped at its line a little to one side cannot straighten up standing still, and
			// it stood there for good, with the whole lane behind it. After 4 s it goes and straightens up as it moves.)
			if (std::fabs(lat[i] - lat_t) > 0.4f && man[i] != MAN_PASS && wait_t[i] < 4.0f) first = false;
			if (de < d_res && first) {
				wj = try_reserve(i, de);
				res = wj == 0;
			}
		}
		if (!res) stop_d = de;
		else {   // the entry point after this junction is not reserved yet: stay able to stop there
			int to = c_to[nconn[i]];
			float de2 = de_end + p_len[n_lanes + nconn[i]] + l_stop_s[to];
			v0_e2 = std::sqrt(2.0f * bc * std::max(de2 - 1.0f, 0.3f));
		}
	}

	bool at_goal = false;
	if (dg < BIG * 0.5f) {
		stop_d = std::min(stop_d, dg);
		if (dg < 0.9f && v_ < 0.3f) at_goal = true;
		// held a few metres short (a parked car or a queue on the stop): close enough, stop here
		else if (dg < 8.0f && v_ < 0.2f && wait_t[i] > 3.0f) at_goal = true;
	}
	if (at_goal) {
		if (!arrived[i]) {
			arrived[i] = 1; st.arrivals++;
			event(E_ARRIVE, i, (float)goal_ri[i]);
			if (kind[i] == K_BUS) { dwell[i] = cfg.bus_dwell * (0.7f + 0.6f * rnd()); st.bus_stops_served++; }
		}
		if (kind[i] == K_BUS) { dwell[i] -= h; if (dwell[i] <= 0.0f) route_advance(i); }
	}
	// ---- a routed car that must change lanes before its next junction
	if (lc_need[i] != 0 && conn[i] < 0) {
		if (man[i] == MAN_NONE) {
			int nb = lc_need[i] > 0 ? l_left[L] : l_right[L];
			float ns, nl;
			bool relax = p_len[L] - s[i] < 40.0f || lc_stuck[i] > 3.0f;
			if (nb >= 0 && lane_change_ok(i, nb, ns, nl, relax)) { man[i] = MAN_LC_PEND; lc_dir[i] = lc_need[i]; lc_t[i] = 0.4f; }
		}
		lc_stuck[i] += h;
		if (lc_stuck[i] > 25.0f && kind[i] != K_AMBIENT && !rt[i].empty()) {   // no gap for a long time: another way round
			int gidx = goal_ri[i] >= 0 ? goal_ri[i] : (int)rt[i].size() - 1;
			int gl = rt[i][gidx];
			std::vector<int32_t> tmp;
			for (int k = l_out_off[L]; k < l_out_off[L] + l_out_n[L]; k++) {
				int c = out_conn[k];
				if (p_blocked[n_lanes + c] || !find_route(c_to[c], gl, tmp)) continue;
				std::vector<int32_t> nr(1, L);
				nr.insert(nr.end(), tmp.begin(), tmp.end());
				rt[i] = nr; rt_i[i] = 0;
				if (goal_ri[i] >= 0) goal_ri[i] = (int32_t)nr.size() - 1;
				nconn[i] = c; lc_need[i] = 0; lc_stuck[i] = 0.0f; man[i] = MAN_NONE;
				st.reroutes++;
				break;
			}
		}
	}

	// ---- a routed car (taxi, bus) held at a junction for long: another way out, then the route again from there
	if (kind[i] != K_AMBIENT && !rt[i].empty() && conn[i] < 0 && !res && nconn[i] >= 0 && wait_t[i] > 45.0f && de < 4.0f && v_ < 0.2f) {
		int gidx = goal_ri[i] >= 0 ? goal_ri[i] : (int)rt[i].size() - 1;
		int gl = rt[i][gidx];
		std::vector<int32_t> tmp;
		for (int k = l_out_off[L]; k < l_out_off[L] + l_out_n[L]; k++) {
			int c = out_conn[k];
			if (c == nconn[i] || p_blocked[n_lanes + c] || !find_route(c_to[c], gl, tmp)) continue;
			std::vector<int32_t> nr(1, L);
			nr.insert(nr.end(), tmp.begin(), tmp.end());
			rt[i] = nr; rt_i[i] = 0;
			if (goal_ri[i] >= 0) goal_ri[i] = (int32_t)nr.size() - 1;
			nconn[i] = c; wait_t[i] = 0.0f;
			st.reroutes++;
			break;
		}
	}

	// ---- manoeuvres around a blocker that cannot be passed inside the lane (take effect from the next update)
	{
		bool pass_type = false, is_static = false, ped = false;
		float bgap = BIG;
		if (blk >= 0) {
			const Track &b = tr[blk];
			bgap = b.sa - hl_;
			if (b.type == TRK_STATIC) pass_type = is_static = true;
			else if (b.type == TRK_DYN) {
				ped = d_kind[b.idx] == DYN_PED;
				pass_type = d_vx[b.idx] * d_vx[b.idx] + d_vz[b.idx] * d_vz[b.idx] < 0.09f;
			} else pass_type = crash_t[b.idx] > 0.0f || why[b.idx] == W_DEADEND || why[b.idx] == W_GOAL;
		}
		if (pass_type && !is_static && v_ < 0.5f && bgap < 10.0f) blocked_t[i] += h;
		else if (v_ > 1.0f || !pass_type) blocked_t[i] = 0.0f;
		long_look[i] = (pass_type && bgap < 45.0f) || man[i] == MAN_PASS;
		float honk_after = cfg.t_honk[tp] * (ped ? 1.5f : 1.0f);
		if (pass_type && !is_static && blocked_t[i] >= honk_after && honk_cd[i] <= 0.0f) {
			event(E_HONK, i, (float)tr[blk].type);
			honk_cd[i] = 6.0f + 4.0f * rnd();
			st.honks++;
		}
		if (man[i] == MAN_NONE && conn[i] < 0 && tier[i] != TIER_FAR && !line_passed[i]) {
			bool ready = false;
			if (pass_type) ready = is_static ? bgap < std::max(22.0f, 3.0f * v_) : blocked_t[i] >= honk_after + 1.5f;
			// a slow car ahead on a road with more lanes: normal and pushy drivers overtake
			bool slow = false;
			if (!ready && tp > 0 && lead >= 0 && tr[lead].type == TRK_CAR && tr[lead].v > 1.0f && lead_gap < 25.0f) {
				float lim_v = p_vmax[cp] * cfg.t_vf[tp];
				if (tr[lead].v < 0.6f * lim_v && v_ < 0.75f * lim_v) slow = true;
			}
			slow_t[i] = slow ? slow_t[i] + h : 0.0f;
			if (slow_t[i] > (tp == 2 ? 2.5f : 5.0f)) ready = true;
			if (ready) {
				float ns, nl;
				for (int side = 0; side < 2 && man[i] == MAN_NONE; side++) {
					int nb = side == 0 ? l_left[L] : l_right[L];
					if (nb >= 0 && lane_change_ok(i, nb, ns, nl)) { man[i] = MAN_LC_PEND; lc_dir[i] = side == 0 ? 1 : -1; lc_t[i] = 0.6f; slow_t[i] = 0.0f; }
				}
				if (man[i] == MAN_NONE && pass_type && l_left[L] < 0 && l_opp[L] >= 0) {
					float lreq = tr[blk].lb + hw_ + 0.35f;
					float dpass = tr[blk].sb + hl_ + 2.5f;
					for (int k = blk + 1; k < nt; k++) {   // a row of parked cars: one pass for all of them
						const Track &t = tr[k];
						if (t.type != TRK_STATIC || t.sa - hl_ > dpass + 8.0f) continue;
						if (t.lb <= -hw_ - 0.3f || t.la >= hw_ + 0.3f) continue;
						dpass = std::max(dpass, t.sb + hl_ + 2.5f); lreq = std::max(lreq, t.lb + hw_ + 0.35f);
					}
					float lmax = lane_hw + 2.0f * p_hw[l_opp[L]] - hw_ - 0.2f;
					bool feas = lreq <= lmax && lreq - lat[i] <= 0.7f * 0.9f * std::max(bgap - 0.3f, 0.0f) && dpass + 8.0f < de_line;
					if (feas && pass_clear(i, w, tr, nt, blk, lreq, dpass)) {
						if (res) { revoke(i); res = false; stop_d = de; }
						man[i] = MAN_PASS; pass_lat[i] = lreq; pass_rem[i] = dpass;
						st.passes++;
					}
				}
			}
		} else if (man[i] == MAN_PASS) {
			if (pass_rem[i] > 0.0f) {
				float lmax = lane_hw + (l_opp[L] >= 0 ? 2.0f * p_hw[l_opp[L]] : 0.0f) - hw_ - 0.2f;
				bool abort_ = false;
				for (int k = 0; k < nt; k++) {
					const Track &t = tr[k];
					float gap = t.sa - hl_;
					if ((t.type == TRK_STATIC || (t.type == TRK_CAR && crash_t[t.idx] > 0.0f)) && gap < 14.0f && t.sb > -hl_ && !(t.lb <= -hw_ - 0.3f || t.la >= hw_ + 0.3f)) {
						pass_rem[i] = std::max(pass_rem[i], t.sb + hl_ + 2.5f);   // the next one in the row
						pass_lat[i] = std::min(std::max(pass_lat[i], t.lb + hw_ + 0.35f), lmax);
					}
					// oncoming traffic turned up and the car is not yet beside the blocker: back into the lane
					if ((t.v < -0.5f || t.facing) && gap < 30.0f && gap > 0.0f && t.lb > pass_lat[i] - hw_ - 0.3f && t.la < pass_lat[i] + hw_ + 0.3f) abort_ = true;
				}
				if (abort_ && blk >= 0 && tr[blk].sa - hl_ > 1.0f && std::fabs(lat[i]) < lim + 0.6f) pass_rem[i] = 0.0f;
			}
			if (pass_rem[i] <= 0.0f && std::fabs(lat[i]) <= lim + 0.05f) man[i] = MAN_NONE;
		} else if (man[i] == MAN_LC_PEND) {
			lc_t[i] -= h;
			if (lc_t[i] <= 0.0f) {
				int nb = lc_dir[i] > 0 ? l_left[L] : l_right[L];
				float ns, nl;
				bool relax = lc_need[i] != 0 && (p_len[L] - s[i] < 40.0f || lc_stuck[i] > 3.0f);
				if (conn[i] < 0 && lane_change_ok(i, nb, ns, nl, relax)) {
					if (res) { revoke(i); res = false; }
					lane[i] = nb; s[i] = ns; lat[i] = nl; seg[i] = 0;
					line_passed[i] = 0; stop_tick[i] = -1;
					if (!rt[i].empty() && rt_i[i] + 1 < (int)rt[i].size() && rt[i][rt_i[i] + 1] == nb) rt_i[i]++;
					lc_stuck[i] = 0.0f;
					nconn[i] = pick_routed(i, nb);
					man[i] = MAN_LC_MOVE;
					st.lane_changes++;
					flags[i] = nf | F_LANECHANGE | (lc_dir[i] > 0 ? (uint32_t)F_IND_L : (uint32_t)F_IND_R);
					flags[i] &= ~(uint32_t)F_RES;
					update_car(i, h);   // plan again on the new lane
					return;
				}
				if (lc_t[i] < -3.0f) man[i] = MAN_NONE;   // no gap: give up
			}
		} else if (man[i] == MAN_LC_MOVE) {
			if (std::fabs(lat[i]) < 0.25f || (std::fabs(lat[i] - lat_t) < 0.15f && v_ < 0.5f)) man[i] = MAN_NONE;
		}
	}

	// ---- speed
	float v0 = p_vmax[cp] * cfg.t_vf[tp];
	const float cfac = cfg.t_cf[tp];
	v0 = std::min(v0, std::max(vcap_at(cp, s[i], seg[i]) * cfac, 2.0f));
	for (int k = 1; k < w.np; k++) {   // limits and curves on the pieces ahead: slow down in time
		int p = w.piece[k];
		float vl = std::min(p_vmax[p] * cfg.t_vf[tp], std::max(ptv[p_off[p]] * cfac, 2.0f));
		v0 = std::min(v0, std::sqrt(vl * vl + 2.0f * cfg.b_curve * std::max(w.off[k], 0.0f)));
	}
	v0 = std::min(v0, v0_e2);
	if (std::fabs(lat_t - lat[i]) > 0.25f) v0 = std::min(v0, 8.0f);
	if (man[i] == MAN_PASS) v0 = std::min(v0, 5.5f);
	v0 = std::max(v0, 0.5f);
	float a_free;
	if (v_ <= v0) { float r = v_ / v0; r *= r; a_free = am * (1.0f - r * r); }
	else a_free = std::max(-bc, (v0 - v_) / 1.0f);
	float a = std::max(a_free + a_int, -cfg.b_hard);
	float vn = v_ + a * h;
	bool emerg = false;
	if (stop_d < BIG * 0.5f) {   // smooth stop at the stop point
		float D = std::max(stop_d - 0.3f, 0.0f), b = 0.8f * bc;
		float venv = -b * h + std::sqrt(b * b * h * h + 2.0f * b * D);
		if (vn > venv) {
			float need = v_ * v_ / (2.0f * std::max(D, 0.05f));
			vn = std::max(venv, v_ - clampf(need * 1.1f, b, cfg.b_emerg) * h);
		}
	}
	if (vn > vsafe) vn = std::max(vsafe, v_ - cfg.b_emerg * h);
	if (vn < 0.0f) vn = 0.0f;
	if (vn < 0.06f && vn <= v_) vn = 0.0f;

	// ---- move: sideways rate follows the forward speed, then the veto
	float vm = 0.5f * (v_ + vn);
	float ds = vm * h;
	if (!res) {   // never past an unreserved entry point
		float lim_d = std::max(stop_d - 0.05f, 0.0f);
		if (ds > lim_d) { ds = lim_d; if (v_ > 1.5f) emerg = true; vn = 0.0f; vm = ds / h; }
	}
	float vlmax = std::min(1.6f, ratio * vm);
	if (std::fabs(lat[i]) > lim + 0.05f && man[i] != MAN_PASS) vlmax = std::max(vlmax, 0.3f);   // creep back into the lane even when held
	float lv = latv[i] + clampf(clampf((lat_t - lat[i]) * 2.0f, -vlmax, vlmax) - latv[i], -4.0f * h, 4.0f * h);
	lv = clampf(lv, -vlmax, vlmax);
	float nlat = lat[i] + lv * h;
	if ((lat_t - lat[i]) * (lat_t - nlat) <= 0.0f) { nlat = lat_t; lv = 0.0f; }
	float nhoff = hoff[i] + clampf(clampf(std::atan2(lv, std::max(vm, 0.8f)), -0.75f, 0.75f) - hoff[i], -0.45f * ds, 0.45f * ds);
	// where that leads (lane -> reserved connector -> lane), without touching the state yet
	int np_ = cp; float ns_ = s[i] + ds;
	if (conn[i] < 0) {
		if (ns_ >= p_len[L]) {
			if (res) {
				ns_ -= p_len[L]; np_ = n_lanes + nconn[i];
				if (ns_ >= p_len[np_]) { ns_ -= p_len[np_]; np_ = c_to[nconn[i]]; }
			}
		}
	} else if (ns_ >= p_len[cp]) {
		ns_ -= p_len[cp]; np_ = L;
		if (ns_ >= p_len[L] && res) { ns_ -= p_len[L]; np_ = n_lanes + nconn[i]; }
	}
	if (ns_ > p_len[np_] - 0.01f) ns_ = p_len[np_] - 0.01f;
	float o[7];
	bool moved = ds > 1e-5f || std::fabs(nlat - lat[i]) > 1e-5f;
	if (moved) {
		int hint = np_ == cp ? seg[i] : 0;
		pose_at(np_, ns_, nlat, nhoff, fx[i], fz[i], hint, o);
		int hit = blocked_by(i, o[0], o[1], o[2], o[3], o[4], 0.06f);
		if (hit && std::fabs(nlat - lat[i]) > 1e-5f) {   // try again without the sideways part
			pose_at(np_, ns_, lat[i], hoff[i], fx[i], fz[i], hint, o);
			if (ds > 1e-5f && !blocked_by(i, o[0], o[1], o[2], o[3], o[4], 0.06f)) { hit = 0; nlat = lat[i]; lv = 0.0f; nhoff = hoff[i]; }
		}
		if (hit == 2 && ds > 1e-5f) {   // a parked car's corner in the way (turning bodies sweep wide): nudge past it inside the lane
			const float nudges[4] = { 0.3f, -0.3f, 0.6f, -0.6f };
			float lane_room = std::max(p_hw[np_] - hw_ + 0.3f, 0.3f);
			for (float nd_ : nudges) {
				float tl = lat[i] + nd_;
				if (std::fabs(tl) > lane_room) continue;
				pose_at(np_, ns_, tl, hoff[i], fx[i], fz[i], hint, o);
				if (!blocked_by(i, o[0], o[1], o[2], o[3], o[4], 0.06f)) { hit = 0; nlat = tl; lv = 0.0f; nhoff = hoff[i]; break; }
			}
			if (hit) pose_at(np_, ns_, nlat, nhoff, fx[i], fz[i], hint, o);
		}
		if (hit) {
			st.vetoes++;
			if (v_ > 1.0f) emerg = true;
			vn = 0.0f; ds = 0.0f; nlat = lat[i]; lv = 0.0f; nhoff = hoff[i];
			moved = false;
		}
	}
	const float old_yaw = yaw[i];
	acc[i] = (vn - v_) / h;
	v[i] = vn; latv[i] = lv;
	if (moved) {
		lat[i] = nlat; hoff[i] = nhoff;
		commit_move(i, ds);
		int p = conn[i] >= 0 ? n_lanes + conn[i] : lane[i];
		pose_at(p, s[i], lat[i], hoff[i], fx[i], fz[i], seg[i], o);
		x[i] = o[0]; y[i] = o[1]; z[i] = o[2]; fx[i] = o[3]; fz[i] = o[4]; pitch[i] = o[5]; yaw[i] = o[6];
	}
	float dyaw = adiff(old_yaw, yaw[i]);
	float steer_t = ds > 0.02f ? clampf(std::atan(2.7f * dyaw / ds), -0.6f, 0.6f) : steer[i];
	steer[i] += (steer_t - steer[i]) * 0.5f;
	latacc[i] += (vm * dyaw / h - latacc[i]) * 0.5f;

	// ---- flags, reasons, events
	L = lane[i];
	nf = flags[i] & (uint32_t)F_RES;
	if (line_passed[i]) nf |= F_LINE;
	if (acc[i] < -0.6f || vn < 0.1f) nf |= F_BRAKE;
	if (acc[i] < -4.5f || emerg) {
		nf |= F_HARD;
		if (hard_cd[i] <= 0.0f) { event(E_HARDBRAKE, i, -acc[i]); hard_cd[i] = 2.0f; st.hard_brakes++; }
	}
	if (emerg) { nf |= F_EMERG; st.emergencies++; }
	int turn = -1;
	if (conn[i] >= 0) turn = c_turn[conn[i]];
	else if (nconn[i] >= 0 && p_len[L] - s[i] < 30.0f) turn = c_turn[nconn[i]];
	if (turn == T_LEFT || turn == T_UTURN) nf |= F_IND_L;
	if (turn == T_RIGHT) nf |= F_IND_R;
	if (man[i] == MAN_LC_PEND || man[i] == MAN_LC_MOVE) nf |= F_LANECHANGE | (lc_dir[i] > 0 ? (uint32_t)F_IND_L : (uint32_t)F_IND_R);
	if (man[i] == MAN_PASS) nf |= F_PASS | (pass_rem[i] > 0.0f ? (uint32_t)F_IND_L : (uint32_t)F_IND_R);
	else if (std::fabs(lat[i]) > lim + 0.05f && man[i] == MAN_NONE) nf |= F_PASS;   // still on the way back into the lane
	if (std::fabs(lat[i]) > 0.15f || std::fabs(lat_t) > 0.05f) nf |= F_AVOID;
	flags[i] = nf;
	lead_id[i] = (lead >= 0 && tr[lead].type == TRK_CAR) ? id[tr[lead].idx] : -1;
	if (vn > 0.5f) why[i] = W_NONE;
	else if (at_goal) why[i] = W_GOAL;
	else if (stop_d < 3.0f && wj != W_NONE) why[i] = (uint8_t)wj;
	else if (stop_d < 3.0f && nconn[i] >= 0 && !res) why[i] = l_ctl[L] == C_SIGNAL ? W_SIGNAL : (l_ctl[L] == C_STOP ? W_STOPSIGN : W_YIELD);
	else if (lead >= 0) why[i] = tr[lead].type == TRK_CAR ? W_LEADER : ((tr[lead].type == TRK_XWALK || (tr[lead].type == TRK_DYN && d_kind[tr[lead].idx] == DYN_PED)) ? W_WALKER : W_OBSTACLE);
	else why[i] = (uint8_t)wj;
	if (vn < 0.2f) wait_t[i] += h; else if (vn > 0.5f) wait_t[i] = 0.0f;
}

int Sim::place_car(int lane_, float s_, float speed, int model_, int temper_) {
	int i = -1;
	for (int k = 0; k < MAX_CARS; k++) if (!alive[k]) { i = k; break; }
	if (i < 0 || lane_ < 0 || lane_ >= n_lanes) return -1;
	int nm = (int)m_hl.size();
	model_ = nm > 0 ? std::min(std::max(model_, 0), nm - 1) : 0;
	alive[i] = 1; kind[i] = 0; model[i] = (uint8_t)model_; temper[i] = (uint8_t)std::min(std::max(temper_, 0), 2);
	colour[i] = (uint8_t)(rnd() * (float)std::max(cfg.n_colours, 1));
	id[i] = next_id++;
	hl[i] = nm > 0 ? m_hl[model_] : 2.2f; hw[i] = nm > 0 ? m_hw[model_] : 0.95f;
	rad[i] = std::sqrt(hl[i] * hl[i] + hw[i] * hw[i]);
	lane[i] = lane_; conn[i] = -1; seg[i] = 0;
	s[i] = clampf(s_, 0.0f, p_len[lane_] - 0.01f); lat[i] = 0; latv[i] = 0; hoff[i] = 0; v[i] = speed; acc[i] = 0;
	nconn[i] = pick_next(lane_);
	float o[7];
	pose_at(lane_, s[i], 0.0f, 0.0f, 0.0f, 1.0f, seg[i], o);
	x[i] = px[i] = o[0]; y[i] = py[i] = o[1]; z[i] = pz[i] = o[2]; fx[i] = o[3]; fz[i] = o[4]; pitch[i] = ppitch[i] = o[5]; yaw[i] = pyaw[i] = o[6];
	tu[i] = tick; span[i] = 1; stop_tick[i] = -1; flags[i] = 0; tier[i] = TIER_FULL;
	why[i] = 0; man[i] = 0; line_passed[i] = 0; touching[i] = 0; long_look[i] = 0; lc_dir[i] = 0;
	steer[i] = latacc[i] = wait_t[i] = blocked_t[i] = honk_cd[i] = crash_t[i] = slow_t[i] = lc_t[i] = pass_lat[i] = pass_rem[i] = hard_cd[i] = 0.0f;
	for (int k = 0; k < MAX_HELD; k++) { h_conn[i][k] = -1; h_rem[i][k] = 0.0f; }
	rt[i].clear(); rt_i[i] = 0; goal_ri[i] = -1; lead_id[i] = -1; chain_n[i] = 0; hold_[i] = 0; veto_by[i] = -1; route_of[i] = -1; next_stop[i] = -1; trip[i] = -1;
	goal_s[i] = goal_lat[i] = dwell[i] = lc_stuck[i] = 0.0f; lc_need[i] = 0; arrived[i] = 0; pull[i] = 0;
	if (i >= hi) hi = i + 1;
	n_alive++;
	return i;
}

int Sim::spawn_car(int lane_, float s_, float speed, int model_, int temper_) {
	if (!built) return -1;
	int i = place_car(lane_, s_, speed, model_, temper_);
	if (i < 0) return -1;
	if (blocked_by(i, x[i], y[i], z[i], fx[i], fz[i], 0.06f)) { alive[i] = 0; n_alive--; return -1; }
	st.spawned++;
	event(E_SPAWN, i, (float)lane_);
	return id[i];
}

void Sim::despawn(int i, int reason) {
	event(E_DESPAWN, i, (float)reason);
	release_all(i);
	alive[i] = 0; n_alive--;
	while (hi > 0 && !alive[hi - 1]) hi--;
	st.despawned++;
	if (reason == 1) st.deadend_despawned++;
	if (reason == 2) st.stuck_despawned++;
}

int Sim::find_car(int car_id) const {
	for (int i = 0; i < hi; i++) if (alive[i] && id[i] == car_id) return i;
	return -1;
}

bool Sim::remove_car(int car_id) {
	int i = find_car(car_id);
	if (i < 0) return false;
	despawn(i, 3);
	return true;
}

// One spawn try: a random point of the ring around the camera, a lane segment in that grid cell, accepted with a
// chance proportional to the lane's density. Never inside the view cone closer than view_safe_r.
bool Sim::try_spawn() {
	float ang = rnd() * 6.2831853f;
	float ri = cfg.spawn_r_in, ro = std::max(cfg.spawn_r_out, ri + 1.0f);
	float r = std::sqrt(rnd()) * ro;   // anywhere in the ring's disc (its centre runs ahead of the camera), then the camera's own rules
	float qx = ring_x + std::sin(ang) * r, qz = ring_z + std::cos(ang) * r;
	int c = cell_of(qx, qz);
	if (c < 0) return false;
	int n = sg_off[c + 1] - sg_off[c];
	if (n <= 0) return false;
	int e = sg_off[c] + std::min((int)(rnd() * (float)n), n - 1);
	int L = sg_piece[e];
	if (L >= n_lanes || !(l_flags[L] & LF_DRIVE) || (l_flags[L] & (LF_BLOCKED | LF_DEADEND))) return false;
	float d = l_dens[L];
	dens_ref = std::max(d, dens_ref * 0.98f);
	if (rnd() * dens_ref > d) return false;
	int q = p_off[L] + sg_pt[e];
	float s_ = ptc[q] + rnd() * (ptc[q + 1] - ptc[q]);
	int nm = (int)m_hl.size();
	int md = 0;
	if (nm > 0 && m_wsum > 0.0f) {
		float rr = rnd() * m_wsum;
		for (md = 0; md < nm - 1; md++) { rr -= m_w[md]; if (rr <= 0.0f) break; }
	}
	float rt = rnd();
	int tp = rt < cfg.t_weight[0] ? 0 : (rt < cfg.t_weight[0] + cfg.t_weight[1] ? 1 : 2);
	float mhl = nm > 0 ? m_hl[md] : 2.2f;
	if (s_ < mhl + 4.0f || s_ > l_stop_s[L] - mhl - 10.0f) return false;
	int hint = 0;
	float o[7];
	pose_at(L, s_, 0.0f, 0.0f, 0.0f, 1.0f, hint, o);
	float dx = o[0] - cam_x, dz = o[2] - cam_z, dd = std::sqrt(dx * dx + dz * dz);
	if (dd < ri) return false;
	{ float rx = o[0] - ring_x, rz = o[2] - ring_z; if (rx * rx + rz * rz > ro * ro) return false; }
	if (!loaded_at(o[0], o[2])) return false;   // its street is not there yet (or no longer)
	bool vis = in_cone(o[0], o[2]);
	if ((vis && dd < cfg.view_safe_r) || (!vis && dd > cfg.behind_despawn_r - 20.0f)) return false;   // never where it would be despawned at once
	for (int j = 0; j < hi; j++) {
		if (!alive[j]) continue;
		float ex = x[j] - o[0], ez = z[j] - o[2];
		if (ex * ex + ez * ez < 16.0f * 16.0f) return false;
	}
	for (int k = 0; k < nd; k++) {
		float ex = d_x[k] - o[0], ez = d_z[k] - o[2];
		if (ex * ex + ez * ez < 14.0f * 14.0f) return false;
	}
	if (static_overlap(o[0], o[1], o[2], o[3], o[4], mhl + 0.5f, (nm > 0 ? m_hw[md] : 0.95f) + 0.3f)) return false;
	float sp = std::min(p_vmax[L] * cfg.t_vf[tp], std::max(vcap_at(L, s_, hint) * cfg.t_cf[tp], 2.0f)) * 0.9f;
	sp = std::min(sp, std::sqrt(2.0f * 1.2f * std::max(l_stop_s[L] - s_ - mhl - 1.0f, 0.0f)));
	int i = place_car(L, s_, sp, md, tp);
	if (i < 0) return false;
	tier[i] = dd < cfg.tier_full_r ? TIER_FULL : (dd < cfg.tier_mid_r ? TIER_MID : TIER_FAR);
	st.spawned++;
	event(E_SPAWN, i, (float)L);
	return true;
}

void Sim::population() {
	for (int i = 0; i < hi; i++) {
		if (!alive[i] || kind[i] == K_SCRIPTED) continue;   // scripted cars live until their owner removes them
		float dx = x[i] - cam_x, dz = z[i] - cam_z;
		float d2 = dx * dx + dz * dz;
		bool vis = in_cone(x[i], z[i]);
		bool bus_done = kind[i] == K_BUS && goal_ri[i] < 0 && nconn[i] < 0 && lc_need[i] == 0 && conn[i] < 0 && p_len[lane[i]] - s[i] < 10.0f;
		if (kind[i] == K_AMBIENT && conn[i] < 0 && (l_flags[lane[i]] & LF_EXIT) && p_len[lane[i]] - s[i] < hl[i] + 2.5f) despawn(i, 5);   // it has left the map
		else if ((d2 > cfg.despawn_r * cfg.despawn_r && (x[i] - ring_x) * (x[i] - ring_x) + (z[i] - ring_z) * (z[i] - ring_z) > cfg.despawn_r * cfg.despawn_r) ||
				(!vis && d2 > cfg.behind_despawn_r * cfg.behind_despawn_r)) despawn(i, 0);
		else if (!loaded_at(x[i], z[i]) && (!vis || d2 > 250.0f * 250.0f)) despawn(i, 6);   // its cell has gone: so has it
		else if (kind[i] == K_AMBIENT && why[i] == W_DEADEND && wait_t[i] > 4.0f) despawn(i, 1);
		else if (bus_done && (!vis || d2 > 80.0f * 80.0f)) despawn(i, 4);
		else if (wait_t[i] > cfg.stuck_despawn_s && why[i] != W_SIGNAL && why[i] != W_CRASH && why[i] != W_GOAL && (!vis || tier[i] == TIER_FAR)) despawn(i, 2);
	}
	buses_population();
	// How many cars: what the streets round the camera CARRY (each lane's cars per metre x its length inside the ring,
	// x the hour, x cfg.dens_scale), never more than cfg.max_cars. (The old game asked for max_cars wherever the
	// camera was; on this map's short green lights a quiet street cannot take what an arterial takes.)
	if (tick - carry_tick >= 40 || carry_tick < 0) {
		carry_tick = tick;
		double sum = 0.0;
		const float ro2 = cfg.spawn_r_out * cfg.spawn_r_out;
		for (int L = 0; L < n_lanes; L++) {
			if (!(l_flags[L] & LF_DRIVE) || (l_flags[L] & (LF_BLOCKED | LF_DEADEND))) continue;
			const int o = p_off[L], n = p_n[L];
			for (int k = 0; k + 1 < n; k++) {
				// cut every stretch into pieces of 20 m at most, so a long straight lane counts by what is inside
				const float len = ptc[o + k + 1] - ptc[o + k];
				const int parts = std::max(1, (int)(len / 20.0f));
				for (int q = 0; q < parts; q++) {
					const float u = ((float)q + 0.5f) / (float)parts;
					const float wx = ptx[o + k] + (ptx[o + k + 1] - ptx[o + k]) * u, wz = ptz[o + k] + (ptz[o + k + 1] - ptz[o + k]) * u;
					const float mx = wx - ring_x, mz = wz - ring_z;
					if (mx * mx + mz * mz < ro2 && loaded_at(wx, wz)) sum += (double)(len / (float)parts) * l_dens[L];
				}
			}
		}
		carry = (float)sum;
	}
	const float want = std::min((float)cfg.max_cars, carry * cfg.dens_scale) * clampf(cfg.hour_factor, 0.0f, 1.0f);
	int target = std::min(std::min(cfg.max_cars, MAX_CARS), (int)std::ceil(want));
	// tries a step: 4 standing still (the old game's number), more the faster the camera goes (the ring's lead is 2 s of
	// its travel): at 280 km/h a car lives 5 s before the camera has passed it, and 4 tries filled only half the street
	const float lead = std::sqrt((ring_x - cam_x) * (ring_x - cam_x) + (ring_z - cam_z) * (ring_z - cam_z));
	const int tries_n = 4 + (int)(lead / 8.0f);
	for (int tries = 0; tries < tries_n && n_alive < target; tries++) try_spawn();
}

void Sim::set_view(float x_, float y_, float z_, float fx_, float fz_, float fov_deg) {
	cam_x = x_; cam_y = y_; cam_z = z_;
	ring_x = x_; ring_z = z_;   // (set_ring moves it ahead, after this)
	float l = std::sqrt(fx_ * fx_ + fz_ * fz_);
	if (l < 1e-5f || fov_deg <= 0.0f) { cam_fx = 0; cam_fz = 1; cam_cos = 2.0f; return; }
	cam_fx = fx_ / l; cam_fz = fz_ / l;
	float half = std::min((fov_deg * 0.5f + cfg.cone_margin_deg) * 0.0174532925f, 3.14159265f);
	cam_cos = std::cos(half);
}

void Sim::set_dynamic(int n, const float *b) {
	nd = std::min(n, MAX_DYN);
	nd_ext = nd;
	for (int k = 0; k < nd; k++) {
		const float *r = b + k * DYN_STRIDE;
		d_x[k] = r[0]; d_y[k] = r[1]; d_z[k] = r[2]; d_fx[k] = std::sin(r[3]); d_fz[k] = std::cos(r[3]);
		d_hl[k] = r[4]; d_hw[k] = r[5]; d_vx[k] = r[6]; d_vz[k] = r[7]; d_kind[k] = (int32_t)r[8]; d_id[k] = (int32_t)r[9];
		d_flag[k] = (uint8_t)r[10];
	}
}

// One tick. FULL cars (near the camera) are updated every tick, MID cars every 4th, FAR cars every 8th, each with
// the time that passed since its last update; the slot index staggers them over the ticks.
void Sim::step(float dt_, double clock_) {
	if (!built) return;
	auto t0 = std::chrono::steady_clock::now();
	tick++; dt = dt_; clock = clock_;
	if (auto_pop) population();
	for (int i = 0; i < hi; i++) {
		if (!alive[i]) continue;
		float dx = x[i] - cam_x, dz = z[i] - cam_z;
		float d2 = dx * dx + dz * dz;
		float rf = cfg.tier_full_r + (tier[i] == TIER_FULL ? 5.0f : 0.0f), rm = cfg.tier_mid_r + (tier[i] != TIER_FAR ? 10.0f : 0.0f);
		tier[i] = d2 < rf * rf ? TIER_FULL : (d2 < rm * rm ? TIER_MID : TIER_FAR);
		if (kind[i] == K_SCRIPTED) tier[i] = TIER_FULL;
		bool due = tier[i] == TIER_FULL || ((tick + i) & (tier[i] == TIER_MID ? 3 : 7)) == 0;
		if (!due) continue;
		int n = std::min(std::max(tick - tu[i], 1), 8);
		update_car(i, dt * (float)n);
	}
	st.last_step_us = std::chrono::duration<double, std::micro>(std::chrono::steady_clock::now() - t0).count();
}

} // namespace tc
