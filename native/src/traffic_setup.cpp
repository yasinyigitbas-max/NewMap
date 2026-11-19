// traffic2 phase 1: setup of the traffic core (lanes -> pieces, junction connectors, speed caps, conflict lists,
// grids, parked boxes that reach into lanes) and the stateless queries.
#include "traffic_sim.h"

#include "street_curve.h"

#include <algorithm>
#include <chrono>
#include <cstring>
#include <unordered_map>

namespace tc {

namespace {

inline float clampf(float v, float a, float b) { return v < a ? a : (v > b ? b : v); }

float pt_seg_d2(float qx, float qz, float ax, float az, float bx, float bz, float &t) {
	float ux = bx - ax, uz = bz - az;
	float l2 = ux * ux + uz * uz;
	t = l2 > 1e-12f ? clampf(((qx - ax) * ux + (qz - az) * uz) / l2, 0.0f, 1.0f) : 0.0f;
	float dx = qx - (ax + ux * t), dz = qz - (az + uz * t);
	return dx * dx + dz * dz;
}

bool seg_cross(float ax, float az, float bx, float bz, float cx, float cz, float dx, float dz) {
	auto orient = [](float px, float pz, float qx, float qz, float rx, float rz) { return (qx - px) * (rz - pz) - (qz - pz) * (rx - px); };
	float o1 = orient(ax, az, bx, bz, cx, cz), o2 = orient(ax, az, bx, bz, dx, dz);
	float o3 = orient(cx, cz, dx, dz, ax, az), o4 = orient(cx, cz, dx, dz, bx, bz);
	return ((o1 > 0) != (o2 > 0)) && ((o3 > 0) != (o4 > 0));
}

float seg_seg_d2(float ax, float az, float bx, float bz, float cx, float cz, float dx, float dz) {
	if (seg_cross(ax, az, bx, bz, cx, cz, dx, dz)) return 0.0f;
	float t;
	float d = pt_seg_d2(ax, az, cx, cz, dx, dz, t);
	d = std::min(d, pt_seg_d2(bx, bz, cx, cz, dx, dz, t));
	d = std::min(d, pt_seg_d2(cx, cz, ax, az, bx, bz, t));
	d = std::min(d, pt_seg_d2(dx, dz, ax, az, bx, bz, t));
	return d;
}

struct P3 { float x, y, z; };

// cut a polyline (with xz cumulative lengths) to [s0, s1]
void cut_poly(const std::vector<P3> &in, const std::vector<float> &cum, float s0, float s1, std::vector<P3> &out) {
	out.clear();
	auto at = [&](float s) {
		size_t i = 0;
		while (i + 2 < in.size() && cum[i + 1] < s) i++;
		float seg = cum[i + 1] - cum[i];
		float u = seg > 1e-6f ? clampf((s - cum[i]) / seg, 0.0f, 1.0f) : 0.0f;
		return P3{ in[i].x + (in[i + 1].x - in[i].x) * u, in[i].y + (in[i + 1].y - in[i].y) * u, in[i].z + (in[i + 1].z - in[i].z) * u };
	};
	out.push_back(at(s0));
	for (size_t i = 0; i < in.size(); i++) {
		if (cum[i] > s0 + 0.2f && cum[i] < s1 - 0.2f) out.push_back(in[i]);
	}
	out.push_back(at(s1));
}

} // namespace

void Sim::set_lanes(int n, const float *pts, const int32_t *off, const float *fa, const int32_t *ia) {
	built = false;
	n_lanes = n; n_conns = 0; n_pieces = n;
	p_off.clear(); p_n.clear(); ptx.clear(); pty.clear(); ptz.clear(); ptc.clear(); ptv.clear();
	p_len.clear(); p_vmax.clear(); p_hw.clear();
	l_edge.assign(n, 0); l_left.assign(n, -1); l_right.assign(n, -1); l_opp.assign(n, -1); l_node0.assign(n, -1); l_node1.assign(n, -1);
	l_sig.assign(n, 0); l_dir.assign(n, 0); l_idx.assign(n, 0); l_ctl.assign(n, 0); l_phase.assign(n, 0); l_class.assign(n, 0);
	l_flags.assign(n, 0); l_stop_s.assign(n, 0); l_dens.assign(n, 0);
	std::vector<P3> raw, cutp;
	std::vector<float> cum;
	std::unordered_map<int64_t, int32_t> by_key;   // (edge, dir, idx) -> lane
	for (int i = 0; i < n; i++) {
		raw.clear(); cum.clear();
		for (int k = off[i]; k < off[i + 1]; k++) {
			P3 p{ pts[k * 3], pts[k * 3 + 1], pts[k * 3 + 2] };
			if (!raw.empty()) {
				float dx = p.x - raw.back().x, dz = p.z - raw.back().z;
				if (dx * dx + dz * dz < 0.25f) {
					if (k == off[i + 1] - 1 && raw.size() >= 2) raw.back() = p;   // keep the true end point
					continue;
				}
			}
			raw.push_back(p);
		}
		if (raw.size() < 2) {   // degenerate lane: keep a tiny straight piece so indices stay valid
			P3 a = raw.empty() ? P3{ 0, 0, 0 } : raw[0];
			P3 b = (off[i + 1] - off[i] >= 2) ? P3{ pts[(off[i + 1] - 1) * 3], pts[(off[i + 1] - 1) * 3 + 1], pts[(off[i + 1] - 1) * 3 + 2] } : a;
			if (std::fabs(b.x - a.x) + std::fabs(b.z - a.z) < 0.02f) b.x += 0.05f;
			raw.clear(); raw.push_back(a); raw.push_back(b);
		}
		cum.push_back(0.0f);
		for (size_t k = 1; k < raw.size(); k++) {
			float dx = raw[k].x - raw[k - 1].x, dz = raw[k].z - raw[k - 1].z;
			cum.push_back(cum.back() + std::sqrt(dx * dx + dz * dz));
		}
		float full = cum.back();
		const float *f = fa + i * 6;
		float t0 = std::max(f[2], 0.0f), t1 = std::max(f[3], 0.0f);
		if (full - t0 - t1 < 2.0f) { t0 = 0.0f; t1 = 0.0f; }
		if (t0 > 0.0f || t1 > 0.0f) cut_poly(raw, cum, t0, full - t1, cutp); else cutp = raw;
		p_off.push_back((int32_t)ptx.size()); p_n.push_back((int32_t)cutp.size());
		float c = 0.0f;
		for (size_t k = 0; k < cutp.size(); k++) {
			if (k > 0) { float dx = cutp[k].x - cutp[k - 1].x, dz = cutp[k].z - cutp[k - 1].z; c += std::sqrt(dx * dx + dz * dz); }
			ptx.push_back(cutp[k].x); pty.push_back(cutp[k].y); ptz.push_back(cutp[k].z); ptc.push_back(c); ptv.push_back(f[0]);
		}
		float len = std::max(c, 0.02f);
		p_len.push_back(len); p_vmax.push_back(std::max(f[0], 1.0f)); p_hw.push_back(std::max(f[1], 1.0f));
		l_stop_s[i] = f[4] < 0.0f ? len : clampf(full - f[4] - t0, std::min(1.0f, len), len);
		l_dens[i] = std::max(f[5], 0.0f);
		const int32_t *a = ia + i * 12;
		l_edge[i] = a[0]; l_dir[i] = (uint8_t)a[1]; l_idx[i] = (uint8_t)a[2]; l_left[i] = a[3]; l_right[i] = a[4];
		l_node0[i] = a[5]; l_node1[i] = a[6]; l_class[i] = (uint8_t)a[7]; l_flags[i] = (uint8_t)(a[8] & (LF_DRIVE | LF_ROUNDABOUT | LF_EXIT));
		l_ctl[i] = (uint8_t)a[9]; l_sig[i] = a[10]; l_phase[i] = (uint8_t)a[11];
		by_key[((int64_t)a[0] << 8) | ((int64_t)(a[1] & 1) << 7) | (a[2] & 127)] = i;
	}
	for (int i = 0; i < n; i++) {   // the lane to pass on: the innermost lane of the other direction on the same edge
		if (l_idx[i] != 0) continue;
		auto it = by_key.find(((int64_t)l_edge[i] << 8) | ((int64_t)(1 - (l_dir[i] & 1)) << 7));
		if (it != by_key.end()) l_opp[i] = it->second;
	}
	raw_conns.clear();
}

void Sim::set_connections(int n, const int32_t *conns) {
	built = false;
	raw_conns.assign(conns, conns + n * 5);
}

void Sim::set_static_boxes(int n, const float *b) {
	built = false;
	sb_x.resize(n); sb_y.resize(n); sb_z.resize(n); sb_fx.resize(n); sb_fz.resize(n); sb_hl.resize(n); sb_hw.resize(n);
	for (int i = 0; i < n; i++) {
		sb_x[i] = b[i * 6]; sb_y[i] = b[i * 6 + 1]; sb_z[i] = b[i * 6 + 2];
		sb_fx[i] = std::sin(b[i * 6 + 3]); sb_fz[i] = std::cos(b[i * 6 + 3]);
		sb_hl[i] = b[i * 6 + 4]; sb_hw[i] = b[i * 6 + 5];
	}
}

void Sim::set_models(int n, const float *m) {
	m_hl.resize(n); m_hw.resize(n); m_w.resize(n); m_wsum = 0;
	for (int i = 0; i < n; i++) { m_hl[i] = m[i * 3]; m_hw[i] = m[i * 3 + 1]; m_w[i] = std::max(m[i * 3 + 2], 0.0f); m_wsum += m_w[i]; }
}

// Junction connectors: a cubic Bezier from the end of the from-lane to the start of the to-lane (tangent to both);
// when the cubic would loop (the two ends side by side in a wide junction) a quadratic through the rays' meeting point.
void Sim::build_connectors() {
	n_conns = 0;
	p_off.resize(n_lanes); p_n.resize(n_lanes); p_len.resize(n_lanes); p_vmax.resize(n_lanes); p_hw.resize(n_lanes);
	size_t npt = (size_t)p_off[n_lanes - 1] + p_n[n_lanes - 1];
	ptx.resize(npt); pty.resize(npt); ptz.resize(npt); ptc.resize(npt); ptv.resize(npt);
	c_from.clear(); c_to.clear(); c_node.clear(); c_turn.clear();
	int nraw = (int)raw_conns.size() / 5;
	// sort by from lane so each lane's outgoing connectors are one run (stable: keeps the input order inside a lane)
	std::vector<int32_t> order(nraw);
	for (int i = 0; i < nraw; i++) order[i] = i;
	std::stable_sort(order.begin(), order.end(), [&](int32_t a, int32_t b) { return raw_conns[a * 5] < raw_conns[b * 5]; });
	l_out_off.assign(n_lanes, 0); l_out_n.assign(n_lanes, 0); out_conn.clear();
	for (int oi = 0; oi < nraw; oi++) {
		const int32_t *r = &raw_conns[order[oi] * 5];
		int A = r[0], B = r[1];
		if (A < 0 || B < 0 || A >= n_lanes || B >= n_lanes) continue;
		int ia = p_off[A] + p_n[A] - 1, ib = p_off[B];
		float pax = ptx[ia], pay = pty[ia], paz = ptz[ia], pbx = ptx[ib], pby = pty[ib], pbz = ptz[ib];
		float dax = pax - ptx[ia - 1], daz = paz - ptz[ia - 1], dbx = ptx[ib + 1] - pbx, dbz = ptz[ib + 1] - pbz;
		float la = std::sqrt(dax * dax + daz * daz), lb = std::sqrt(dbx * dbx + dbz * dbz);
		if (la > 1e-6f) { dax /= la; daz /= la; }
		if (lb > 1e-6f) { dbx /= lb; dbz /= lb; }
		float dist = std::sqrt((pbx - pax) * (pbx - pax) + (pbz - paz) * (pbz - paz));
		// the path through the junction: the SAME curve the street tool checked against the kerbs (street_curve.h)
		std::vector<float> path;
		sg::junction_path(pax, pay, paz, dax, daz, pbx, pby, pbz, dbx, dbz, (float)r[4] * 0.01f, path);
		std::vector<P3> pts;
		for (size_t q = 0; q + 2 < path.size(); q += 3) pts.push_back(P3{ path[q], path[q + 1], path[q + 2] });
		(void)dist;
		int ci = n_conns++;
		c_from.push_back(A); c_to.push_back(B); c_turn.push_back((uint8_t)r[2]);
		c_node.push_back(l_node1[A] >= 0 ? l_node1[A] : r[3]);
		p_off.push_back((int32_t)ptx.size()); p_n.push_back((int32_t)pts.size());
		float c = 0.0f;
		float vm = std::min(p_vmax[A], p_vmax[B]);
		if (r[2] == T_UTURN) vm = std::min(vm, 4.5f);
		for (size_t i = 0; i < pts.size(); i++) {
			if (i > 0) { float dx = pts[i].x - pts[i - 1].x, dz = pts[i].z - pts[i - 1].z; c += std::sqrt(dx * dx + dz * dz); }
			ptx.push_back(pts[i].x); pty.push_back(pts[i].y); ptz.push_back(pts[i].z); ptc.push_back(c); ptv.push_back(vm);
		}
		if (c < 0.02f) { c = 0.02f; ptc.back() = c; }
		p_len.push_back(c); p_vmax.push_back(vm); p_hw.push_back(std::min(p_hw[A], p_hw[B]));
		if (l_out_n[A] == 0) l_out_off[A] = (int32_t)out_conn.size();
		l_out_n[A]++; out_conn.push_back(ci);
	}
	n_pieces = n_lanes + n_conns;
	c_res.assign(n_conns, 0);
	c_ask.assign(n_conns, -1); c_ask_tick.assign(n_conns, -1000000); c_ask_wait.assign(n_conns, 0.0f);
}

// Speed cap per point: curvature (comfortable lateral acceleration), then a backward pass so the cap ramps down
// ahead of a curve with gentle braking. A connector ends at its to-lane's first cap.
void Sim::build_speed_caps() {
	auto pass = [&](int p) {
		int o = p_off[p], n = p_n[p];
		float vm = p_vmax[p];
		for (int i = 0; i < n; i++) {
			float cap = vm;
			if (i > 0 && i < n - 1) {
				int j1 = i - 1, j2 = i + 1;
				// heading change between chords 5 m back and ahead: the real radius of a curve (chord angle / chord
				// length = 1 / R), while the few-degree kinks of the map polylines no longer read as tight bends
				while (j1 > 0 && ptc[o + i] - ptc[o + j1] < 5.0f) j1--;
				while (j2 < n - 1 && ptc[o + j2] - ptc[o + i] < 5.0f) j2++;
				float ax = ptx[o + i] - ptx[o + j1], az = ptz[o + i] - ptz[o + j1], bx = ptx[o + j2] - ptx[o + i], bz = ptz[o + j2] - ptz[o + i];
				float la = std::sqrt(ax * ax + az * az), lb = std::sqrt(bx * bx + bz * bz);
				if (la > 0.05f && lb > 0.05f) {
					float th = std::fabs(std::atan2(ax * bz - az * bx, ax * bx + az * bz));
					float kappa = th / (0.5f * (la + lb));
					if (kappa > 1e-4f) cap = std::min(cap, std::max(std::sqrt(cfg.a_lat / kappa), 2.5f));
				}
			}
			ptv[o + i] = cap;
		}
	};
	auto back = [&](int p) {
		int o = p_off[p], n = p_n[p];
		for (int i = n - 2; i >= 0; i--) {
			float ds = ptc[o + i + 1] - ptc[o + i];
			ptv[o + i] = std::min(ptv[o + i], std::sqrt(ptv[o + i + 1] * ptv[o + i + 1] + 2.0f * cfg.b_curve * ds));
		}
	};
	for (int p = 0; p < n_lanes; p++) { pass(p); back(p); }
	for (int c = 0; c < n_conns; c++) {
		int p = n_lanes + c;
		pass(p);
		int last = p_off[p] + p_n[p] - 1;
		ptv[last] = std::min(ptv[last], ptv[p_off[c_to[c]]]);
		back(p);
	}
}

// Two connectors of one junction conflict when they end in the same lane or their centrelines come closer than a
// car width (plus a margin). Lanes of one approach running side by side are only in conflict when they really cross.
void Sim::build_conflicts() {
	std::vector<int32_t> order(n_conns);
	for (int i = 0; i < n_conns; i++) order[i] = i;
	std::stable_sort(order.begin(), order.end(), [&](int32_t a, int32_t b) { return c_node[a] < c_node[b]; });
	std::vector<std::vector<int32_t>> lists(n_conns);
	st.n_conflict_pairs = 0;
	auto sib = [&](int a, int b) { return a != b && l_edge[a] == l_edge[b] && l_dir[a] == l_dir[b]; };
	for (int i0 = 0; i0 < n_conns;) {
		int i1 = i0;
		while (i1 < n_conns && c_node[order[i1]] == c_node[order[i0]]) i1++;
		for (int ia = i0; ia < i1; ia++) {
			for (int ib = ia + 1; ib < i1; ib++) {
				int a = order[ia], b = order[ib];
				if (c_from[a] == c_from[b]) continue;
				bool hit = c_to[a] == c_to[b];
				if (!hit) {
					float thr = (sib(c_from[a], c_from[b]) || sib(c_to[a], c_to[b])) ? 1.2f : 2.5f;
					float thr2 = thr * thr;
					int pa = n_lanes + a, pb = n_lanes + b;
					for (int k = 0; k < p_n[pa] - 1 && !hit; k++) {
						int q = p_off[pa] + k;
						for (int m = 0; m < p_n[pb] - 1; m++) {
							int r = p_off[pb] + m;
							if (seg_seg_d2(ptx[q], ptz[q], ptx[q + 1], ptz[q + 1], ptx[r], ptz[r], ptx[r + 1], ptz[r + 1]) < thr2) { hit = true; break; }
						}
					}
				}
				if (hit) { lists[a].push_back(b); lists[b].push_back(a); st.n_conflict_pairs++; }
			}
		}
		i0 = i1;
	}
	cf_off.assign(n_conns, 0); cf_n.assign(n_conns, 0); cf_idx.clear();
	for (int c = 0; c < n_conns; c++) {
		cf_off[c] = (int32_t)cf_idx.size(); cf_n[c] = (int32_t)lists[c].size();
		cf_idx.insert(cf_idx.end(), lists[c].begin(), lists[c].end());
	}
	// Right of way. Higher value goes first; equal values = first come first served.
	//  control: free flow / signal 2, give way 1, stop 0; traffic already on a roundabout 3, entering one 1
	//  then road class (main roads first), then the turn (straight, right, left, u-turn)
	c_prio.assign(n_conns, 0);
	for (int c = 0; c < n_conns; c++) {
		int A = c_from[c], B = c_to[c];
		int rank = l_ctl[A] == C_STOP ? 0 : (l_ctl[A] == C_GIVEWAY ? 1 : 2);
		if (l_flags[A] & LF_ROUNDABOUT) rank = 3;
		else if ((l_flags[B] & LF_ROUNDABOUT) && rank > 1) rank = 1;
		int turn = c_turn[c] == T_STRAIGHT ? 3 : (c_turn[c] == T_RIGHT ? 2 : (c_turn[c] == T_LEFT ? 1 : 0));
		c_prio[c] = rank * 100 + (int)l_class[A] * 10 + turn;
	}
}

void Sim::build_grids() {
	float x0 = BIG, z0 = BIG, x1 = -BIG, z1 = -BIG;
	for (size_t i = 0; i < ptx.size(); i++) { x0 = std::min(x0, ptx[i]); x1 = std::max(x1, ptx[i]); z0 = std::min(z0, ptz[i]); z1 = std::max(z1, ptz[i]); }
	for (size_t i = 0; i < sb_x.size(); i++) { x0 = std::min(x0, sb_x[i]); x1 = std::max(x1, sb_x[i]); z0 = std::min(z0, sb_z[i]); z1 = std::max(z1, sb_z[i]); }
	if (x0 > x1) { x0 = z0 = 0; x1 = z1 = 1; }
	gx0 = x0 - GC; gz0 = z0 - GC;
	gw = (int)((x1 - gx0) / GC) + 2; gh = (int)((z1 - gz0) / GC) + 2;
	int nc = gw * gh;
	// segments: two passes (count, fill)
	std::vector<int32_t> cnt(nc + 1, 0);
	auto each_seg = [&](bool fill) {
		for (int p = 0; p < n_pieces; p++) {
			for (int k = 0; k < p_n[p] - 1; k++) {
				int q = p_off[p] + k;
				int cx0 = (int)((std::min(ptx[q], ptx[q + 1]) - gx0) / GC), cx1 = (int)((std::max(ptx[q], ptx[q + 1]) - gx0) / GC);
				int cz0 = (int)((std::min(ptz[q], ptz[q + 1]) - gz0) / GC), cz1 = (int)((std::max(ptz[q], ptz[q + 1]) - gz0) / GC);
				for (int cz = cz0; cz <= cz1; cz++) {
					for (int cx = cx0; cx <= cx1; cx++) {
						int c = cz * gw + cx;
						if (!fill) cnt[c]++;
						else { int at = sg_off[c] + cnt[c]++; sg_piece[at] = p; sg_pt[at] = k; }
					}
				}
			}
		}
	};
	each_seg(false);
	sg_off.assign(nc + 1, 0);
	for (int c = 0; c < nc; c++) sg_off[c + 1] = sg_off[c] + cnt[c];
	sg_piece.assign(sg_off[nc], 0); sg_pt.assign(sg_off[nc], 0);
	std::fill(cnt.begin(), cnt.end(), 0);
	each_seg(true);
	// boxes by centre cell
	std::fill(cnt.begin(), cnt.end(), 0);
	int nb = (int)sb_x.size();
	for (int i = 0; i < nb; i++) cnt[cell_of(sb_x[i], sb_z[i])]++;
	bg_off.assign(nc + 1, 0);
	for (int c = 0; c < nc; c++) bg_off[c + 1] = bg_off[c] + cnt[c];
	bg_idx.assign(nb, 0);
	std::fill(cnt.begin(), cnt.end(), 0);
	for (int i = 0; i < nb; i++) { int c = cell_of(sb_x[i], sb_z[i]); bg_idx[bg_off[c] + cnt[c]++] = i; }
}

// Parked boxes that reach into a lane or connector, stored per piece in the piece's own (s, lateral) frame.
void Sim::build_intrusions() {
	struct In { int32_t piece; float s0, s1, l0, l1; };
	struct Cand { int32_t piece, pt; float d2, t; };
	std::vector<In> all;
	std::vector<Cand> cands;
	int nb = (int)sb_x.size();
	for (int b = 0; b < nb; b++) {
		float R = sb_hl[b] + 6.0f;
		int cx0 = std::max(0, (int)((sb_x[b] - R - gx0) / GC)), cx1 = std::min(gw - 1, (int)((sb_x[b] + R - gx0) / GC));
		int cz0 = std::max(0, (int)((sb_z[b] - R - gz0) / GC)), cz1 = std::min(gh - 1, (int)((sb_z[b] + R - gz0) / GC));
		cands.clear();
		for (int cz = cz0; cz <= cz1; cz++) {
			for (int cx = cx0; cx <= cx1; cx++) {
				int c = cz * gw + cx;
				for (int e = sg_off[c]; e < sg_off[c + 1]; e++) {
					int q = p_off[sg_piece[e]] + sg_pt[e];
					float t;
					float d2 = pt_seg_d2(sb_x[b], sb_z[b], ptx[q], ptz[q], ptx[q + 1], ptz[q + 1], t);
					if (d2 < R * R) cands.push_back(Cand{ sg_piece[e], sg_pt[e], d2, t });
				}
			}
		}
		std::sort(cands.begin(), cands.end(), [](const Cand &a, const Cand &c) { return a.piece != c.piece ? a.piece < c.piece : (a.d2 != c.d2 ? a.d2 < c.d2 : a.pt < c.pt); });
		for (size_t i = 0; i < cands.size(); i++) {
			if (i > 0 && cands[i].piece == cands[i - 1].piece) continue;   // nearest segment of each piece only
			const Cand &cd = cands[i];
			int q = p_off[cd.piece] + cd.pt;
			float ux = ptx[q + 1] - ptx[q], uz = ptz[q + 1] - ptz[q];
			float sl = std::sqrt(ux * ux + uz * uz);
			if (sl < 1e-4f) continue;
			ux /= sl; uz /= sl;
			float py_ = pty[q] + (pty[q + 1] - pty[q]) * cd.t;
			if (sb_y[b] > -900.0f && std::fabs(sb_y[b] - py_) > 2.5f) continue;
			float rx = sb_x[b] - ptx[q], rz = sb_z[b] - ptz[q];
			float sc = ptc[q] + rx * ux + rz * uz;
			float lc = rx * uz - rz * ux;   // left normal = (uz, -ux)
			float c = std::fabs(sb_fx[b] * ux + sb_fz[b] * uz), sn = std::fabs(sb_fx[b] * uz - sb_fz[b] * ux);
			float elon = c * sb_hl[b] + sn * sb_hw[b], elat = c * sb_hw[b] + sn * sb_hl[b];
			float lim = p_hw[cd.piece] + 0.2f;
			if (lc - elat >= lim || lc + elat <= -lim) continue;
			if (sc + elon < -1.0f || sc - elon > p_len[cd.piece] + 1.0f) continue;
			all.push_back(In{ cd.piece, sc - elon, sc + elon, lc - elat, lc + elat });
		}
	}
	std::sort(all.begin(), all.end(), [](const In &a, const In &b) { return a.piece != b.piece ? a.piece < b.piece : (a.s0 != b.s0 ? a.s0 < b.s0 : a.l0 < b.l0); });
	in_off.assign(n_pieces, 0); in_n.assign(n_pieces, 0);
	in_s0.clear(); in_s1.clear(); in_l0.clear(); in_l1.clear();
	for (const In &e : all) {
		if (in_n[e.piece] == 0) in_off[e.piece] = (int32_t)in_s0.size();
		in_n[e.piece]++;
		in_s0.push_back(e.s0); in_s1.push_back(e.s1); in_l0.push_back(e.l0); in_l1.push_back(e.l1);
	}
	st.n_intrusions = (int)all.size();
}

// Lanes ambient traffic must not use: closed off by a parked box with no way around, or leading only to such lanes
// (or to non-public lanes / dead ends).
void Sim::build_flags() {
	const float W = 2.1f + 0.7f;   // widest common car + side clearances
	p_blocked.assign(n_pieces, 0);
	st.n_blocked_lanes = 0; st.n_pass_lanes = 0; st.n_deadend_lanes = 0;
	for (int p = 0; p < n_pieces; p++) {
		bool blocked = false, pass = false;
		for (int e = in_off[p]; e < in_off[p] + in_n[p]; e++) {
			float fl = p_hw[p] - in_l1[e], fr = in_l0[e] + p_hw[p];
			if (std::max(fl, fr) >= W) continue;   // room inside the lane
			if (p < n_lanes && (l_left[p] >= 0 || l_right[p] >= 0)) continue;   // change lane
			if (p < n_lanes && l_opp[p] >= 0 && fl + 2.0f * p_hw[l_opp[p]] >= W) { pass = true; continue; }   // around it on the oncoming side
			blocked = true;
		}
		if (blocked) { p_blocked[p] = 1; if (p < n_lanes) { l_flags[p] |= LF_BLOCKED; st.n_blocked_lanes++; } }
		else if (pass) st.n_pass_lanes++;
	}
	bool changed = true;
	int guard = 0;
	while (changed && guard++ < 400) {
		changed = false;
		for (int l = 0; l < n_lanes; l++) {
			if (l_flags[l] & (LF_DEADEND | LF_EXIT)) continue;   // (a lane out of the map leads somewhere: away)
			bool any = false;
			for (int k = l_out_off[l]; k < l_out_off[l] + l_out_n[l]; k++) {
				int c = out_conn[k], t = c_to[c];
				if (p_blocked[n_lanes + c]) continue;
				if ((l_flags[t] & LF_DRIVE) && !(l_flags[t] & (LF_BLOCKED | LF_DEADEND))) { any = true; break; }
			}
			if (!any) { l_flags[l] |= LF_DEADEND; changed = true; }
		}
	}
	for (int l = 0; l < n_lanes; l++) if ((l_flags[l] & LF_DEADEND) && (l_flags[l] & LF_DRIVE)) st.n_deadend_lanes++;
}

bool Sim::build() {
	auto t0 = std::chrono::steady_clock::now();
	if (n_lanes <= 0) return false;
	build_connectors();
	build_speed_caps();
	build_conflicts();
	build_grids();
	build_intrusions();
	build_flags();
	built = true;
	reset_cars(cfg.seed);
	st.build_ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
	return true;
}

void Sim::reset_cars(uint64_t seed) {
	std::memset(alive, 0, sizeof(alive));
	hi = 0; n_alive = 0; next_id = 1; tick = 0;
	std::fill(c_res.begin(), c_res.end(), (int16_t)0);
	std::fill(c_ask.begin(), c_ask.end(), -1); std::fill(c_ask_tick.begin(), c_ask_tick.end(), -1000000);
	rng_s = seed * 0x9E3779B97F4A7C15ULL + 0x853c49e6748fea9bULL;
	if (rng_s == 0) rng_s = 1;
	for (int i = 0; i < 8; i++) rnd();
	dens_ref = 1e-6f; carry_tick = -1; carry = 0.0f;
	events.clear();
	for (int i = 0; i < MAX_CARS; i++) { rt[i].clear(); kind[i] = 0; }
	trips_out.clear(); last_tod = -1.0;
	nd = nd_ext = 0;
	Stats keep = st;
	st = Stats();
	st.n_intrusions = keep.n_intrusions; st.n_blocked_lanes = keep.n_blocked_lanes; st.n_deadend_lanes = keep.n_deadend_lanes;
	st.n_conflict_pairs = keep.n_conflict_pairs; st.n_pass_lanes = keep.n_pass_lanes; st.build_ms = keep.build_ms;
}

// The map's own signal plan, the one its lamps show (city_kit/shaders/rt/rt_prop.gdshaderinc): a cycle of SIG_CYCLE
// seconds, green 40 %, amber 10 %, red 50 %; the street along x runs half a cycle after the street along z (l_phase 1);
// every junction starts its cycle at its own time (sig_off, by node: l_sig). There is no all-red time in that plan:
// one street's amber ends as the other's green begins.
int Sim::signal_state(int lane_, double t) const {
	if (lane_ < 0 || lane_ >= n_lanes || l_ctl[lane_] != C_SIGNAL) return -1;
	const int node = l_sig[lane_];
	const double off = node >= 0 && node < (int)sig_off.size() ? (double)sig_off[node] : 0.0;
	double ph = std::fmod((t + off) / SIG_CYCLE + (l_phase[lane_] ? 0.5 : 0.0), 1.0);
	if (ph < 0.0) ph += 1.0;
	return ph < 0.4 ? SIG_GREEN : (ph < 0.5 ? SIG_YELLOW : SIG_RED);
}

// seconds since the lane's signal turned red (0 when it is not red)
float Sim::signal_red_age(int lane_, double t) const {
	if (lane_ < 0 || lane_ >= n_lanes || l_ctl[lane_] != C_SIGNAL) return 0.0f;
	const int node = l_sig[lane_];
	const double off = node >= 0 && node < (int)sig_off.size() ? (double)sig_off[node] : 0.0;
	double ph = std::fmod((t + off) / SIG_CYCLE + (l_phase[lane_] ? 0.5 : 0.0), 1.0);
	if (ph < 0.0) ph += 1.0;
	return ph < 0.5 ? 0.0f : (float)((ph - 0.5) * SIG_CYCLE);
}

int Sim::nearest_lane(float qx, float qz, float max_d, float *out_s) const {
	int best = -1;
	float bd = max_d * max_d, bs = 0.0f;
	int cx0 = std::max(0, (int)((qx - max_d - gx0) / GC)), cx1 = std::min(gw - 1, (int)((qx + max_d - gx0) / GC));
	int cz0 = std::max(0, (int)((qz - max_d - gz0) / GC)), cz1 = std::min(gh - 1, (int)((qz + max_d - gz0) / GC));
	for (int cz = cz0; cz <= cz1; cz++) {
		for (int cx = cx0; cx <= cx1; cx++) {
			int c = cz * gw + cx;
			for (int e = sg_off[c]; e < sg_off[c + 1]; e++) {
				if (sg_piece[e] >= n_lanes) continue;
				int q = p_off[sg_piece[e]] + sg_pt[e];
				float t;
				float d2 = pt_seg_d2(qx, qz, ptx[q], ptz[q], ptx[q + 1], ptz[q + 1], t);
				if (d2 < bd) { bd = d2; best = sg_piece[e]; bs = ptc[q] + (ptc[q + 1] - ptc[q]) * t; }
			}
		}
	}
	if (out_s) *out_s = bs;
	return best;
}

void Sim::piece_pose(int piece, float s_, float lat_, float out[5]) const {
	int hint = 0;
	float o[7];
	pose_at(piece, s_, lat_, 0.0f, 0.0f, 1.0f, hint, o);
	out[0] = o[0]; out[1] = o[1]; out[2] = o[2]; out[3] = o[3]; out[4] = o[4];
}

// Independent check for the tests: plain pair tests of the cars' current boxes, no margins, not the veto code path.
void Sim::audit(int out[3]) const {
	out[0] = out[1] = out[2] = 0;
	for (int i = 0; i < hi; i++) {
		if (!alive[i]) continue;
		for (int j = i + 1; j < hi; j++) {
			if (!alive[j] || std::fabs(y[i] - y[j]) > 2.5f) continue;
			if (obb_overlap(x[i], z[i], fx[i], fz[i], hl[i], hw[i], x[j], z[j], fx[j], fz[j], hl[j], hw[j])) out[0]++;
		}
		if (static_overlap(x[i], y[i], z[i], fx[i], fz[i], hl[i], hw[i])) out[1]++;
		for (int d = 0; d < nd; d++) {
			if (d_kind[d] == DYN_XWALK || std::fabs(y[i] - d_y[d]) > 2.5f) continue;
			if (obb_overlap(x[i], z[i], fx[i], fz[i], hl[i], hw[i], d_x[d], d_z[d], d_fx[d], d_fz[d], d_hl[d], d_hw[d])) out[2]++;
		}
	}
}

bool Sim::static_overlap(float bx, float by, float bz, float bfx, float bfz, float bhl, float bhw) const {
	if (sb_x.empty()) return false;
	float R = std::sqrt(bhl * bhl + bhw * bhw) + 7.0f;   // + the largest static half diagonal
	int cx0 = std::max(0, (int)((bx - R - gx0) / GC)), cx1 = std::min(gw - 1, (int)((bx + R - gx0) / GC));
	int cz0 = std::max(0, (int)((bz - R - gz0) / GC)), cz1 = std::min(gh - 1, (int)((bz + R - gz0) / GC));
	for (int cz = cz0; cz <= cz1; cz++) {
		for (int cx = cx0; cx <= cx1; cx++) {
			int c = cz * gw + cx;
			for (int e = bg_off[c]; e < bg_off[c + 1]; e++) {
				int b = bg_idx[e];
				if (sb_y[b] > -900.0f && std::fabs(sb_y[b] - by) > 2.5f) continue;
				if (obb_overlap(bx, bz, bfx, bfz, bhl, bhw, sb_x[b], sb_z[b], sb_fx[b], sb_fz[b], sb_hl[b], sb_hw[b])) return true;
			}
		}
	}
	return false;
}

uint64_t Sim::state_hash() const {
	uint64_t h = 1469598103934665603ULL;
	auto mix = [&](uint32_t v_) { h ^= v_; h *= 1099511628211ULL; };
	auto mixf = [&](float f) { uint32_t u; std::memcpy(&u, &f, 4); mix(u); };
	mix((uint32_t)tick); mix((uint32_t)n_alive); mix((uint32_t)(rng_s & 0xffffffffu)); mix((uint32_t)(rng_s >> 32));
	for (int i = 0; i < hi; i++) {
		if (!alive[i]) continue;
		mix((uint32_t)id[i]); mix((uint32_t)lane[i]); mix((uint32_t)conn[i]); mix((uint32_t)nconn[i]); mix(flags[i]);
		mixf(s[i]); mixf(lat[i]); mixf(v[i]); mixf(x[i]); mixf(z[i]);
	}
	return h;
}

} // namespace tc
