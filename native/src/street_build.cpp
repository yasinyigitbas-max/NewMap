// The street builder: see street_build.h
#include "street_build.h"
#include "traffic_body.h"

#include <algorithm>
#include <cmath>
#include <cstdarg>
#include <cstdio>
#include <cstring>

namespace sg {

namespace {

const double STEP = 0.25;        // the cross-section is sampled this fine, then each edge is found to a centimetre
const double PT_STEP = 2.0;      // centre line points
const double END_SKIP = 30.0;    // stations this near a block's end are not used for its typical section (junction mouths)

inline bool is_walk(int l) { return l == G_CONCRETE || l == G_TRAVERTINE; }

double median(std::vector<double> &v) {
	if (v.empty()) return 0.0;
	std::sort(v.begin(), v.end());
	return v[v.size() / 2];
}

} // namespace

void Builder::say(const char *fmt, ...) {
	char buf[1024];
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(buf, sizeof(buf), fmt, ap);
	va_end(ap);
	rep.lines.push_back(buf);
}

// One side of the street at a point of its centre line: outward along (nx, nz) from the centre to the kerb and over
// the pavement. Edges are found on the 0.25 m samples and then narrowed to under a centimetre.
Side Builder::measure_side(double px, double pz, double nx, double nz) const {
	Side s;
	auto road = [&](double o) { return is_road(ground->layer_at((float)(px + nx * o), (float)(pz + nz * o))); };
	auto walk = [&](double o) { return is_walk(ground->layer_at((float)(px + nx * o), (float)(pz + nz * o))); };
	auto edge = [&](double a, double b, bool walk_test, bool a_state) {   // the state changes between a and b
		for (int k = 0; k < 6; k++) {
			const double mid = (a + b) * 0.5;
			if ((walk_test ? walk(mid) : road(mid)) == a_state) a = mid; else b = mid;
		}
		return (a + b) * 0.5;
	};
	double o = 0.0;
	if (!road(0.0)) {   // a median, or this is not a street here
		while (o <= 4.0 && !road(o)) o += STEP;
		if (o > 4.0) return s;
		s.m = edge(o - STEP, o, false, false);
	}
	double o2 = o;
	while (o2 <= 24.0 && road(o2)) o2 += STEP;
	if (o2 > 24.0) return s;   // open asphalt (a side street's mouth, a yard): no kerb to be found here
	s.k = edge(o2 - STEP, o2, false, true);
	double o3 = o2;
	while (o3 <= s.k + 3.5 && !walk(o3)) o3 += STEP;
	if (o3 <= s.k + 3.5) {
		s.w0 = o3 > o2 ? edge(o3 - STEP, o3, true, false) : s.k;
		double o4 = o3;
		while (o4 <= s.w0 + 8.0 && walk(o4)) o4 += STEP;
		s.w1 = o4 <= s.w0 + 8.0 ? edge(o4 - STEP, o4, true, true) : s.w0 + 8.0;
	}
	s.ok = true;
	return s;
}

// The skeleton's blocks as edges between junction nodes.
//  - A block end that is not at a node but on another block (the bridge's off-ramp) makes a node there. The skeleton
//    draws such a ramp from the middle of the road it leaves; on the ground it runs inside that road's carriageway for
//    a while. The ramp's edge starts where its own asphalt has parted from the road, and the node is put on the road
//    a little before that, so the lane that leaves gets a gentle way over.
//  - A block with a HOLE in it (no street built for 10 m and more: the place kept for the ferry landing) is cut at the
//    hole; both cut ends are dead ends.
void Builder::make_edges() {
	auto node_at = [&](double x, double z, double tol) {
		int best = -1; double bd = tol;
		for (size_t i = 0; i < nodes.size(); i++) {
			const double d = std::hypot(nodes[i].x - x, nodes[i].z - z);
			if (d < bd) { bd = d; best = (int)i; }
		}
		return best;
	};
	auto road_at = [&](double x, double z) { return is_road(ground->layer_at((float)x, (float)z)); };
	// nearest point of a block's line: -> distance, the point, the segment it lies on
	auto project = [&](const std::vector<double> &q, double ex, double ez, double &qx, double &qz, int &seg) {
		double best = 1e18;
		for (size_t k = 0; k + 3 < q.size(); k += 2) {
			const double ux = q[k + 2] - q[k], uz = q[k + 3] - q[k + 1], l2 = ux * ux + uz * uz;
			if (l2 < 1e-9) continue;
			const double t = std::min(1.0, std::max(0.0, ((ex - q[k]) * ux + (ez - q[k + 1]) * uz) / l2));
			const double px = q[k] + ux * t, pz = q[k + 1] + uz * t, d = std::hypot(ex - px, ez - pz);
			if (d < best) { best = d; qx = px; qz = pz; seg = (int)k; }
		}
		return best;
	};
	// a line every 2 m
	auto resample = [&](const std::vector<double> &p, std::vector<double> &x, std::vector<double> &z) {
		x.clear(); z.clear();
		for (size_t k = 0; k + 3 < p.size(); k += 2) {
			const double ax = p[k], az = p[k + 1], bx = p[k + 2], bz = p[k + 3], l = std::hypot(bx - ax, bz - az);
			if (l < 1e-6) continue;
			const int n = std::max(1, (int)std::ceil(l / PT_STEP));
			for (int j = (x.empty() ? 0 : 1); j <= n; j++) {
				const double u = (double)j / n;
				x.push_back(ax + (bx - ax) * u); z.push_back(az + (bz - az) * u);
			}
		}
	};
	// loose ends
	const size_t nb0 = blocks.size();
	for (size_t bi = 0; bi < nb0; bi++) {
		for (int end = 0; end < 2; end++) {
			std::vector<double> p = blocks[bi].pts;
			if (end == 1) {   // look at the block from its loose end
				std::vector<double> r;
				for (size_t k = p.size(); k >= 2; k -= 2) { r.push_back(p[k - 2]); r.push_back(p[k - 1]); }
				p = r;
			}
			if (node_at(p[0], p[1], 1.5) >= 0) continue;
			int host = -1, hseg = -1; double hd = 6.0, hx = 0, hz = 0;
			for (size_t bj = 0; bj < blocks.size(); bj++) {
				if (bj == bi) continue;
				double qx, qz; int seg = 0;
				const double d = project(blocks[bj].pts, p[0], p[1], qx, qz, seg);
				if (d < hd) { hd = d; host = (int)bj; hseg = seg; hx = qx; hz = qz; }
			}
			SkNode n; n.x = p[0]; n.z = p[1];
			if (host < 0) {
				n.deadend = true;
				say("LOOSE end of block %s at (%.1f, %.1f): no node and no block there, a dead end", blocks[bi].id.c_str(), p[0], p[1]);
				nodes.push_back(n);
				continue;
			}
			// where the block's own asphalt has parted from its host: between it and the host's centre line there is ground
			// that is not road (beyond the host's median)
			std::vector<double> x, z;
			resample(p, x, z);
			int sep = -1, run = 0;
			for (size_t i = 0; i < x.size() && sep < 0; i++) {
				double qx, qz; int seg = 0;
				const double d = project(blocks[host].pts, x[i], z[i], qx, qz, seg);
				bool parted = false;
				if (d > 8.0) {
					for (double t = 5.0; t < d - 1.0 && !parted; t += 0.5) parted = !road_at(qx + (x[i] - qx) * t / d, qz + (z[i] - qz) * t / d);
				}
				run = parted ? run + 1 : 0;
				if (run >= 5) sep = (int)i - 4;
			}
			if (sep > 0) {
				const int start = std::max(0, sep - 8);          // 16 m before its asphalt is on its own
				const int at_host = std::max(0, start - 15);     // the node on the host: 30 m before that
				int seg = 0;
				project(blocks[host].pts, x[at_host], z[at_host], hx, hz, seg);
				hseg = seg;
				std::vector<double> np;
				for (size_t i = (size_t)start; i < x.size(); i++) { np.push_back(x[i]); np.push_back(z[i]); }
				if (end == 1) {
					std::vector<double> r;
					for (size_t k = np.size(); k >= 2; k -= 2) { r.push_back(np[k - 2]); r.push_back(np[k - 1]); }
					np = r;
				}
				blocks[bi].pts = np;
				n.diverge = true;
				say("RAMP block %s: its asphalt parts from %s %.0f m along; it starts at (%.1f, %.1f), leaving %s at (%.1f, %.1f)", blocks[bi].id.c_str(), blocks[host].id.c_str(),
						sep * PT_STEP, x[start], z[start], blocks[host].id.c_str(), hx, hz);
			}
			n.x = hx; n.z = hz;
			SkBlock a = blocks[host], b = blocks[host];
			a.id += "_a"; b.id += "_b";
			a.pts.assign(blocks[host].pts.begin(), blocks[host].pts.begin() + hseg + 2);
			a.pts.push_back(hx); a.pts.push_back(hz);
			b.pts.clear(); b.pts.push_back(hx); b.pts.push_back(hz);
			b.pts.insert(b.pts.end(), blocks[host].pts.begin() + hseg + 2, blocks[host].pts.end());
			say("SPLIT block %s at (%.1f, %.1f): %s leaves it there", blocks[host].id.c_str(), hx, hz, blocks[bi].id.c_str());
			blocks[host] = a; blocks.push_back(b);
			nodes.push_back(n);
			loose.push_back({ (int)bi, end, (int)nodes.size() - 1 });
		}
	}
	edges.clear();
	for (size_t bi = 0; bi < blocks.size(); bi++) {
		const std::vector<double> &p = blocks[bi].pts;
		std::vector<double> x, z;
		resample(p, x, z);
		const int n = (int)x.size();
		if (n < 2) continue;
		int na = node_at(p[0], p[1], 1.5), nb = node_at(p[p.size() - 2], p[p.size() - 1], 1.5);
		for (const LooseEnd &le : loose) {
			if (le.block != (int)bi) continue;
			if (le.end == 0) na = le.node; else nb = le.node;
		}
		// holes: no street within 30 m of the line, across it, for 10 m and more
		std::vector<char> hole(n, 0);
		for (int i = 0; i < n; i++) {
			const int i0 = std::max(i - 1, 0), i1 = std::min(i + 1, n - 1);
			double tx = x[i1] - x[i0], tz = z[i1] - z[i0];
			const double tl = std::hypot(tx, tz);
			if (tl < 1e-9) continue;
			tx /= tl; tz /= tl;
			bool any = false;
			for (double o = -30.0; o <= 30.0 && !any; o += 1.0) any = road_at(x[i] + tz * o, z[i] - tx * o);
			hole[i] = any ? 0 : 1;
		}
		auto piece = [&](int from, int to, int n_from, int n_to) {
			if (to - from < 10) return;   // under 20 m: no street to speak of
			Edge e;
			e.block = (int)bi; e.na = n_from; e.nb = n_to;
			e.oneway = blocks[bi].name.find("off-ramp") != std::string::npos;
			double acc = 0.0;
			for (int k = from; k <= to; k++) {
				if (k > from) acc += std::hypot(x[k] - x[k - 1], z[k] - z[k - 1]);
				e.x.push_back(x[k]); e.z.push_back(z[k]); e.s.push_back(acc);
			}
			e.len = acc;
			edges.push_back(e);
		};
		int from = 0, node_from = na, i = 0;
		while (i < n) {
			if (!hole[i]) { i++; continue; }
			int j = i;
			while (j < n && hole[j]) j++;
			if (j - i < 5) { i = j; continue; }
			say("HOLE in block %s (%s): no street from (%.1f, %.1f) to (%.1f, %.1f), %.0f m. The street is cut there", blocks[bi].id.c_str(), blocks[bi].name.c_str(),
					x[i], z[i], x[j - 1], z[j - 1], (j - i) * PT_STEP);
			SkNode d0; d0.x = x[std::max(i - 1, 0)]; d0.z = z[std::max(i - 1, 0)]; d0.deadend = true;
			nodes.push_back(d0);
			piece(from, i - 1, node_from, (int)nodes.size() - 1);
			SkNode d1; d1.x = x[std::min(j, n - 1)]; d1.z = z[std::min(j, n - 1)]; d1.deadend = true;
			nodes.push_back(d1);
			node_from = (int)nodes.size() - 1; from = j; i = j;
		}
		piece(from, n - 1, node_from, nb);
	}
}

// Draws a block's centre line again by following the built street from its a end: a step of 2 m straight on, then
// across to the middle between the kerbs there. Where a kerb is missing (a side street's mouth) it goes straight on.
// It stops when it has come level with the b end. false = it lost the street (the old line stays).
bool Builder::retrace(Edge &e) {
	const int n = (int)e.x.size();
	const double bx = e.x[n - 1], bz = e.z[n - 1];
	const int k0 = std::min(n - 1, 4);
	double hx = e.x[k0] - e.x[0], hz = e.z[k0] - e.z[0];
	double hl = std::hypot(hx, hz);
	if (hl < 1e-6) return false;
	hx /= hl; hz /= hl;
	std::vector<double> x, z;
	double px = e.x[0], pz = e.z[0];
	x.push_back(px); z.push_back(pz);
	const int max_steps = (int)(e.len * 1.7 / PT_STEP) + 20;
	int lost = 0;
	bool arrived = false;
	for (int step = 0; step < max_steps; step++) {
		double qx = px + hx * PT_STEP, qz = pz + hz * PT_STEP;
		const double lx = hz, lz = -hx;
		const Side r = measure_side(qx, qz, -lx, -lz), l = measure_side(qx, qz, lx, lz);
		if (r.ok && l.ok && r.k + l.k < 30.0) {
			const double c = (l.k - r.k) * 0.5;
			qx += lx * c; qz += lz * c;
			lost = 0;
		} else if (!is_road(ground->layer_at((float)qx, (float)qz))) {
			if (++lost > 15) break;   // 30 m with no street under it
		}
		double nx = qx - px, nz = qz - pz;
		const double nl = std::hypot(nx, nz);
		if (nl > 1e-6) {
			nx /= nl; nz /= nl;
			hx = hx * 0.4 + nx * 0.6; hz = hz * 0.4 + nz * 0.6;
			hl = std::hypot(hx, hz); hx /= hl; hz /= hl;
		}
		px = qx; pz = qz;
		x.push_back(px); z.push_back(pz);
		const double db = std::hypot(bx - px, bz - pz);
		if (db < 25.0 && (bx - px) * hx + (bz - pz) * hz <= 0.5) { arrived = true; break; }   // level with the b end
	}
	if (!arrived) {
		say("FOLLOW block %s: the street was lost at (%.1f, %.1f) after %d m; its skeleton line is kept", blocks[e.block].id.c_str(), px, pz, (int)(x.size() * PT_STEP));
		return false;
	}
	e.x = x; e.z = z;
	e.s.assign(x.size(), 0.0);
	for (size_t i = 1; i < x.size(); i++) e.s[i] = e.s[i - 1] + std::hypot(x[i] - x[i - 1], z[i] - z[i - 1]);
	const double was = e.len;
	e.len = e.s.back();
	say("FOLLOW block %s (%s): its line was drawn again along the built street, %.1f m (the skeleton line: %.1f m, up to %.1f m beside the street)", blocks[e.block].id.c_str(),
			blocks[e.block].name.c_str(), e.len, was, e.shift_max);
	return true;
}

// Every block's cross-section at every point of its centre line, and its typical one (the median over the points
// away from the junctions). The skeleton says where a street runs to within a few metres; the BUILT street says where
// its centre is: midway between its kerbs (every street family is built symmetric). Where the two differ (the ring's
// curves, the legs that swing over to the waterfront) the centre line is moved onto the street, in a few passes.
void Builder::measure_edges() {
	for (Edge &e : edges) {
		int n = (int)e.x.size();
		const double skip = e.len > 3.0 * END_SKIP ? END_SKIP : e.len * 0.25;
		auto road_at = [&](double x, double z) { return is_road(ground->layer_at((float)x, (float)z)); };
		bool retraced = false;
		double prev_worst = 1e9;
		for (int pass = 0; pass < 8; pass++) {
			n = (int)e.x.size();
			std::vector<Side> *at = e.at;
			at[0].assign(n, Side()); at[1].assign(n, Side());
			std::vector<double> c(n, 0.0), wd(n, 0.0);
			std::vector<char> has(n, 0);
			double track = 0.0;   // where the last point found the middle of the street, metres left of the line
			int n_moved = 0;      // points where the street had to be looked for beside the line
			for (int i = 0; i < n; i++) {
				const int i0 = std::max(i - 1, 0), i1 = std::min(i + 1, n - 1);
				double tx = e.x[i1] - e.x[i0], tz = e.z[i1] - e.z[i0];
				const double tl = std::hypot(tx, tz);
				if (tl < 1e-9) continue;
				tx /= tl; tz /= tl;
				const double lx = tz, lz = -tx;   // left of a -> b
				const double px = e.x[i], pz = e.z[i];
				at[0][i] = measure_side(px, pz, -lx, -lz);
				at[1][i] = measure_side(px, pz, lx, lz);
				// On the carriageway, or on a median (asphalt a like distance away on both sides)? Else the skeleton line
				// runs beside the street here: the street is looked for where the last point found it, then nearby.
				const bool on_road = road_at(px, pz);
				const bool on_median = !on_road && at[0][i].ok && at[1][i].ok && at[0][i].m > 0.5 && std::fabs(at[0][i].m - at[1][i].m) < 0.8;
				double moved = 0.0;
				if ((!on_road && !on_median) || std::fabs(track) > 3.0) {
					double found = 1e9;
					if (road_at(px + lx * track, pz + lz * track)) found = track;
					for (double o = 0.5; o <= 16.0 && found > 1e8; o += 0.5) {
						if (road_at(px + lx * (track + o), pz + lz * (track + o))) found = track + o + 1.0;
						else if (road_at(px + lx * (track - o), pz + lz * (track - o))) found = track - o - 1.0;
					}
					if (found < 1e8 && std::fabs(found) < 70.0) moved = found;
				}
				Side r = at[0][i], l = at[1][i];
				if (moved != 0.0) {
					n_moved++;
					r = measure_side(px + lx * moved, pz + lz * moved, -lx, -lz);
					l = measure_side(px + lx * moved, pz + lz * moved, lx, lz);
					at[0][i] = Side(); at[1][i] = Side();   // (measured from beside the line: not the section at this point)
				}
				if (r.ok && l.ok && r.k + l.k < 34.0) {
					wd[i] = r.k + l.k;
					c[i] = moved + (l.k - r.k) * 0.5;   // the middle between the kerbs, metres left of the line
					has[i] = 1;
					track = c[i];
				}
			}
			// the typical section
			std::vector<double> vm[2], vk[2], vw0[2], vw1[2], vwide;
			e.stations = 0;
			for (int i = 0; i < n; i++) {
				if (e.s[i] < skip || e.s[i] > e.len - skip) continue;
				e.stations++;
				if (has[i]) vwide.push_back(wd[i]);
				for (int sd = 0; sd < 2; sd++) {
					if (!at[sd][i].ok) continue;
					vm[sd].push_back(at[sd][i].m); vk[sd].push_back(at[sd][i].k);
					if (at[sd][i].w1 > at[sd][i].w0) { vw0[sd].push_back(at[sd][i].w0); vw1[sd].push_back(at[sd][i].w1); }
				}
			}
			for (int sd = 0; sd < 2; sd++) {
				e.valid[sd] = (int)vk[sd].size();
				e.med[sd] = Side();
				if (vk[sd].empty()) continue;
				e.med[sd].ok = true;
				e.med[sd].m = median(vm[sd]); e.med[sd].k = median(vk[sd]);
				e.med[sd].w0 = median(vw0[sd]); e.med[sd].w1 = median(vw1[sd]);
			}
			if (vwide.empty() || pass == 7) break;
			// only points where the street is as wide as it typically is say where its middle is (not a junction's mouth,
			// not a driveway)
			const double wide = median(vwide);
			double worst = 0.0;
			for (int i = 0; i < n;) {
				if (!has[i] || std::fabs(wd[i] - wide) <= 0.6) { i++; continue; }
				int j = i;
				while (j < n && has[j] && std::fabs(wd[j] - wide) > 0.6) j++;
				// a few points of another width: a driveway, the mouth of a junction. Many in a row (24 m and more, away
				// from the ends of the block): the street really changes its section there, and its middle counts
				const bool lasting = j - i >= 12 && e.s[i] > 25.0 && e.s[j - 1] < e.len - 25.0;
				if (!lasting) for (int k = i; k < j; k++) has[k] = 0;
				i = j;
			}
			for (int i = 0; i < n; i++) if (has[i]) worst = std::max(worst, std::fabs(c[i]));
			if (pass == 0 && !retraced) e.shift_max = worst;
			// The skeleton line lies metres beside the built street (the ring at the waterfront leaves it by up to 20 m):
			// the line is drawn again by FOLLOWING the street from a to b, then measured as every other block.
			if (worst > 1.5 && !retraced && !e.oneway) {
				retraced = true;
				if (retrace(e)) { pass = -1; prev_worst = 1e9; continue; }
			}
			if (worst > prev_worst * 0.8) break;   // another pass no longer brings the line nearer the middle
			prev_worst = worst;
			if (worst < 0.05) break;
			// points with no answer take their neighbours'; then a 5-point mean, so the line stays smooth
			int last = -1;
			for (int i = 0; i < n; i++) {
				if (!has[i]) continue;
				if (last < 0) { for (int j = 0; j < i; j++) c[j] = c[i]; }
				else { for (int j = last + 1; j < i; j++) c[j] = c[last] + (c[i] - c[last]) * (double)(j - last) / (double)(i - last); }
				last = i;
			}
			if (last < 0) break;
			for (int j = last + 1; j < n; j++) c[j] = c[last];
			std::vector<double> nx(n), nz(n);
			for (int i = 0; i < n; i++) {
				double a = 0.0; int cnt = 0;
				for (int j = std::max(0, i - 2); j <= std::min(n - 1, i + 2); j++) { a += c[j]; cnt++; }
				const int i0 = std::max(i - 1, 0), i1 = std::min(i + 1, n - 1);
				double tx = e.x[i1] - e.x[i0], tz = e.z[i1] - e.z[i0];
				const double tl = std::hypot(tx, tz);
				tx /= tl; tz /= tl;
				nx[i] = e.x[i] + tz * (a / cnt); nz[i] = e.z[i] - tx * (a / cnt);
			}
			e.x = nx; e.z = nz;
			e.s[0] = 0.0;
			for (int i = 1; i < n; i++) e.s[i] = e.s[i - 1] + std::hypot(e.x[i] - e.x[i - 1], e.z[i] - e.z[i - 1]);
			e.len = e.s[n - 1];
		}
		const SkBlock &b = blocks[e.block];
		say("EDGE %-7s %-18s %-8s len %6.1f st %3d | right ok %3d m %.2f kerb %5.2f walk %5.2f-%5.2f | left ok %3d m %.2f kerb %5.2f walk %5.2f-%5.2f | off skeleton %.2f%s",
				b.id.c_str(), b.name.substr(0, 18).c_str(), b.section.c_str(), e.len, e.stations,
				e.valid[0], e.med[0].m, e.med[0].k, e.med[0].w0, e.med[0].w1, e.valid[1], e.med[1].m, e.med[1].k, e.med[1].w0, e.med[1].w1, e.shift_max,
				(e.na < 0 || e.nb < 0) ? " NO NODE AT AN END" : "");
	}
	// a junction is where its streets really meet: the node moves to where the centre lines of its legs cross (they
	// were moved with their streets); legs that all run one way (a bend, a joint) give the mean of their ends
	for (size_t ni = 0; ni < nodes.size(); ni++) {
		double sx = 0.0, sz = 0.0, a11 = 0.0, a12 = 0.0, a22 = 0.0, b1 = 0.0, b2 = 0.0; int cnt = 0;
		for (const Edge &e : edges) {
			const int n = (int)e.x.size();
			for (int end = 0; end < 2; end++) {
				if ((end == 0 ? e.na : e.nb) != (int)ni) continue;
				const double px = end == 0 ? e.x[0] : e.x[n - 1], pz = end == 0 ? e.z[0] : e.z[n - 1];
				// the leg's direction over its first 10 m
				const int k = std::min(n - 1, 5);
				double hx = end == 0 ? e.x[k] - e.x[0] : e.x[n - 1 - k] - e.x[n - 1], hz = end == 0 ? e.z[k] - e.z[0] : e.z[n - 1 - k] - e.z[n - 1];
				const double hl = std::hypot(hx, hz);
				if (hl < 1e-9) continue;
				hx /= hl; hz /= hl;
				const double qx = hz, qz = -hx, r = qx * px + qz * pz;   // the line: q . X = r
				a11 += qx * qx; a12 += qx * qz; a22 += qz * qz; b1 += qx * r; b2 += qz * r;
				sx += px; sz += pz; cnt++;
			}
		}
		if (cnt == 0) continue;
		double mx = sx / cnt, mz = sz / cnt;
		const double det = a11 * a22 - a12 * a12;
		if (cnt >= 2 && det > 0.05) { mx = (b1 * a22 - b2 * a12) / det; mz = (a11 * b2 - a12 * b1) / det; }
		const double d = std::hypot(mx - nodes[ni].x, mz - nodes[ni].z);
		if (d > 0.3) say("NODE %d moved %.2f m onto its streets: (%.1f, %.1f) -> (%.1f, %.1f)", (int)ni, d, nodes[ni].x, nodes[ni].z, mx, mz);
		if (d < 30.0 && !nodes[ni].diverge) { nodes[ni].x = mx; nodes[ni].z = mz; }
	}
}

// ---------------------------------------------------------------- lanes across the street
namespace {

struct Tmpl { int n; double off[2]; double hw; double park; };
// lane centres in metres from the centre line (the piece libraries' own numbers: apt_lib, ind_lib, strip_lib,
// road_amber; measured for the bridge), half width, and the centre of the kerb parking lane
const Tmpl TMPL[T_COUNT] = {
	{ 0, { 0, 0 }, 0, 0 },
	{ 1, { 1.65, 1.65 }, 1.65, 0 },       // T_LANE1: one lane to the kerb at 3.3 (centre side streets)
	{ 1, { 1.65, 1.65 }, 1.65, 4.5 },     // T_LANE1_PARK: one lane, parking 3.3 - 5.7 (residential, standard, high street sides)
	{ 1, { 2.1, 2.1 }, 2.1, 0 },          // T_TRUCK: one 4.2 m lane, shoulder to 6.7
	{ 2, { 3.55, 7.05 }, 1.75, 0 },       // T_ART: turn lane to 1.8, lanes to 5.3 and 8.8, bike lane to 10.3 (3rd / 4th St, the ring)
	{ 2, { 4.15, 7.45 }, 1.65, 0 },       // T_BLVD: Amber, median to 2.5, lanes to 5.8 and 9.1 (centre: kerb at 9.1)
	{ 2, { 4.15, 7.45 }, 1.65, 10.3 },    // T_BLVD_PARK: Amber with parking to 11.5
	{ 2, { 4.05, 8.15 }, 2.0, 0 },        // T_BRIDGE: the approach, median to 2.0, two lanes to 10.2
	{ 1, { 0, 0 }, 1.65, 0 },             // T_GENERIC: worked out from the kerbs where it is used
};

int classify(const Side &s) {
	if (!s.ok) return T_NONE;
	if (s.m < 0.6) {
		if (s.k > 2.9 && s.k < 3.75) return T_LANE1;
		if (s.k > 5.2 && s.k <= 6.2) return T_LANE1_PARK;
		if (s.k > 6.2 && s.k < 7.3) return T_TRUCK;
		if (s.k > 9.6 && s.k < 11.0) return T_ART;
		return T_GENERIC;
	}
	if (s.m > 1.5 && s.m < 3.2) {
		if (s.k > 8.5 && s.k <= 9.7) return T_BLVD;
		if (s.k > 9.7 && s.k < 10.7) return T_BRIDGE;
		if (s.k >= 10.9 && s.k < 12.1) return T_BLVD_PARK;
	}
	return T_GENERIC;
}

} // namespace

void Builder::edge_at(const Edge &e, double s, double &x, double &z, double &tx, double &tz) const {
	const int n = (int)e.x.size();
	s = std::min(std::max(s, 0.0), e.len);
	int i = (int)(std::upper_bound(e.s.begin(), e.s.end(), s) - e.s.begin()) - 1;
	i = std::min(std::max(i, 0), n - 2);
	const double l = e.s[i + 1] - e.s[i], u = l > 1e-9 ? (s - e.s[i]) / l : 0.0;
	x = e.x[i] + (e.x[i + 1] - e.x[i]) * u; z = e.z[i] + (e.z[i + 1] - e.z[i]) * u;
	// the direction: between the directions at the two points, so an offset lane has no corners
	auto dir_at = [&](int k, double &ox, double &oz) {
		const int k0 = std::max(k - 1, 0), k1 = std::min(k + 1, n - 1);
		ox = e.x[k1] - e.x[k0]; oz = e.z[k1] - e.z[k0];
		const double ll = std::hypot(ox, oz);
		if (ll > 1e-9) { ox /= ll; oz /= ll; }
	};
	double ax, az, bx, bz;
	dir_at(i, ax, az); dir_at(i + 1, bx, bz);
	tx = ax + (bx - ax) * u; tz = az + (bz - az) * u;
	const double tl = std::hypot(tx, tz);
	if (tl > 1e-9) { tx /= tl; tz /= tl; }
}

double Builder::lane_off_at(const Edge &e, int dir, int lane, double s) const {
	const std::vector<double> &o = e.off[dir][lane];
	const int n = (int)e.x.size();
	s = std::min(std::max(s, 0.0), e.len);
	int i = (int)(std::upper_bound(e.s.begin(), e.s.end(), s) - e.s.begin()) - 1;
	i = std::min(std::max(i, 0), n - 2);
	const double l = e.s[i + 1] - e.s[i], u = l > 1e-9 ? (s - e.s[i]) / l : 0.0;
	return o[i] + (o[i + 1] - o[i]) * u;
}

// Which kind of street each side is at every point of the centre line (T_*).
void Builder::classify_edges() {
	for (Edge &e : edges) {
		const int n = (int)e.x.size();
		const SkBlock &b = blocks[e.block];
		for (int sd = 0; sd < 2; sd++) {
			std::vector<uint8_t> t(n, T_NONE);
			int known = 0;
			for (int i = 0; i < n; i++) {
				t[i] = (uint8_t)classify(e.at[sd][i]);
				if (t[i] != T_NONE && t[i] != T_GENERIC) known++;
			}
			// inside a junction's kerb returns the street is wider than any kind: where the block has known stretches,
			// such a point is no answer; only a block that is unknown all along stays "generic"
			if (known * 4 >= n) {
				for (int i = 0; i < n; i++) if (t[i] == T_GENERIC) t[i] = T_NONE;
			}
			// a point with no answer (a side street's mouth, a junction) takes the nearest answer
			int last = -1;
			for (int i = 0; i < n; i++) {
				if (t[i] == T_NONE) continue;
				if (last < 0) { for (int j = 0; j < i; j++) t[j] = t[i]; }
				else { for (int j = last + 1; j < i; j++) t[j] = (j - last <= i - j) ? t[last] : t[i]; }
				last = i;
			}
			if (last >= 0) { for (int j = last + 1; j < n; j++) t[j] = t[last]; }
			else {
				const int c = classify(e.med[sd]);
				for (int j = 0; j < n; j++) t[j] = (uint8_t)(c == T_NONE ? T_GENERIC : c);
			}
			// single odd points (a driveway apron read as a kerb) follow their neighbours: the most frequent kind within 8 m
			std::vector<uint8_t> f(n);
			int cnt[T_COUNT] = { 0 };
			for (int i = 0; i < n; i++) {
				int c9[T_COUNT] = { 0 };
				for (int j = std::max(0, i - 4); j <= std::min(n - 1, i + 4); j++) c9[t[j]]++;
				int best = t[i];
				for (int k = 0; k < T_COUNT; k++) if (c9[k] > c9[best]) best = k;
				f[i] = (uint8_t)best;
				cnt[best]++;
			}
			e.tm[sd] = f;
			if (!e.oneway) rep.generic_stations += cnt[T_GENERIC];
			if (cnt[T_GENERIC] > 0 && !e.oneway) say("KIND UNKNOWN block %s (%s) side %d: %d of %d points (typical there: carriageway from %.2f to %.2f m)", b.id.c_str(), b.name.c_str(), sd, cnt[T_GENERIC], n, e.med[sd].m, e.med[sd].k);
		}
	}
}

// A part of an edge, from point i0 to point i1, as an edge of its own
static Edge slice(const Edge &e, int i0, int i1) {
	Edge r;
	r.block = e.block; r.oneway = e.oneway; r.shift_max = e.shift_max;
	r.med[0] = e.med[0]; r.med[1] = e.med[1]; r.valid[0] = e.valid[0]; r.valid[1] = e.valid[1];
	for (int i = i0; i <= i1; i++) {
		r.x.push_back(e.x[i]); r.z.push_back(e.z[i]); r.s.push_back(e.s[i] - e.s[i0]);
		for (int sd = 0; sd < 2; sd++) { r.at[sd].push_back(e.at[sd][i]); r.tm[sd].push_back(e.tm[sd][i]); }
	}
	r.len = r.s.back();
	r.stations = (int)r.x.size();
	return r;
}

// A street does not always keep its lanes from one junction to the next:
//  - a block whose two halves were built by different pieces has two lanes each way on one half and one on the other.
//    The edge is cut where the street changes, with a node of its own there (no junction: nobody stops): the two
//    lanes merge into one, or one opens into two, WHERE THE STREET DOES IT;
//  - the arterials (3rd / 4th St, the ring) paint a left-turn lane in the middle before a signal (the white arrows).
//    The last 55 m before such a junction become an edge with that lane as the arriving direction's innermost lane:
//    cars that turn left wait there, the two through lanes stay free.
void Builder::split_edges() {
	std::vector<Edge> res;
	int cuts = 0, pockets = 0;
	auto lanes_at = [&](const Edge &e, int d, int i) { return e.oneway ? (d == 0 ? 1 : 0) : TMPL[e.tm[d][i]].n; };
	// 1. where the lane count changes
	for (const Edge &e : edges) {
		const int n = (int)e.x.size();
		std::vector<int> key(n);
		for (int i = 0; i < n; i++) key[i] = lanes_at(e, 0, i) * 4 + lanes_at(e, 1, i);
		// a stretch under 30 m that differs from both its neighbours is not a street of its own: it takes the fewer lanes
		for (int i = 0; i < n;) {
			int j = i;
			while (j < n && key[j] == key[i]) j++;
			if (j - i < 15 && (i > 0 || j < n)) {
				const int a = i > 0 ? key[i - 1] : key[j < n ? j : i], b = j < n ? key[j] : a;
				const int take = std::min(a, b);
				for (int k = i; k < j; k++) key[k] = take;
			}
			i = j;
		}
		std::vector<int> at;
		for (int i = 1; i < n; i++) if (key[i] != key[i - 1]) at.push_back(i);
		// a cut needs 30 m of street on both sides
		std::vector<int> good;
		int prev = 0;
		for (int c : at) { if (c - prev >= 15 && n - 1 - c >= 15) { good.push_back(c); prev = c; } }
		if (good.empty()) { res.push_back(e); continue; }
		int from = 0, node_from = e.na;
		for (size_t k = 0; k <= good.size(); k++) {
			const int to = k < good.size() ? good[k] : n - 1;
			Edge p = slice(e, from, to);
			// each part keeps only its own kind of street (the points of the other part near the cut would mix them)
			p.na = node_from;
			if (k < good.size()) {
				SkNode in; in.x = e.x[to]; in.z = e.z[to]; in.inner = true;
				nodes.push_back(in);
				p.nb = (int)nodes.size() - 1; node_from = p.nb;
				cuts++;
				say("LANES CHANGE in block %s (%s) at (%.1f, %.1f): %d + %d lanes before, %d + %d after", blocks[e.block].id.c_str(), blocks[e.block].name.c_str(), e.x[to], e.z[to],
						key[to - 1] / 4, key[to - 1] % 4, key[to] / 4, key[to] % 4);
			} else p.nb = e.nb;
			for (int sd = 0; sd < 2; sd++) {   // the part's own kind, at all its points
				int cnt[T_COUNT] = { 0 };
				const int want = (sd == 0 ? key[from + (to - from) / 2] / 4 : key[from + (to - from) / 2] % 4);
				for (uint8_t t : p.tm[sd]) if (TMPL[t].n == want) cnt[t]++;
				int best = -1;
				for (int q = 0; q < T_COUNT; q++) if (cnt[q] > 0 && (best < 0 || cnt[q] > cnt[best])) best = q;
				if (best >= 0) for (uint8_t &t : p.tm[sd]) if (TMPL[t].n != want) t = (uint8_t)best;
			}
			res.push_back(p);
			from = to;
		}
	}
	edges = res;
	// 2. left-turn pockets: white arrows on the centre line, 10 to 50 m before a junction, on an arterial
	res.clear();
	std::vector<int> deg(nodes.size(), 0);
	for (const Edge &e : edges) { if (e.na >= 0) deg[e.na]++; if (e.nb >= 0) deg[e.nb]++; }
	for (const Edge &e0 : edges) {
		Edge e = e0;
		const int n = (int)e.x.size();
		bool has[2] = { false, false };   // at a, at b
		for (int end = 0; end < 2 && !e.oneway; end++) {
			const int node = end == 0 ? e.na : e.nb, din = end == 0 ? 1 : 0;
			if (node < 0 || deg[node] < 3 || nodes[node].inner || nodes[node].diverge) continue;
			int hits = 0;
			bool art = true;
			for (int i = 0; i < n; i++) {
				const double d = end == 0 ? e.s[i] : e.len - e.s[i];
				if (d < 10.0 || d > 50.0) continue;
				if (e.tm[din][i] != T_ART) art = false;
				const int i0 = std::max(i - 1, 0), i1 = std::min(i + 1, n - 1);
				double tx = e.x[i1] - e.x[i0], tz = e.z[i1] - e.z[i0];
				const double tl = std::hypot(tx, tz);
				tx /= tl; tz /= tl;
				for (double a = 0.0; a < PT_STEP; a += 0.5) {
					bool w = false;
					for (double o = -0.6; o <= 0.61 && !w; o += 0.3) w = ground->layer_at((float)(e.x[i] + tx * a + tz * o), (float)(e.z[i] + tz * a - tx * o)) == G_PAINT_WHITE;
					if (w) hits++;
				}
			}
			// ... and a street to turn left into (at a T-junction the side with no such street has hatching on its centre
			// lane, which is white paint too)
			bool left_exists = false;
			{
				const double ox = end == 0 ? e.x[1] - e.x[0] : e.x[n - 2] - e.x[n - 1], oz = end == 0 ? e.z[1] - e.z[0] : e.z[n - 2] - e.z[n - 1];
				const double ol = std::hypot(ox, oz), ix = -ox / ol, iz = -oz / ol;   // the way the arriving traffic drives
				for (const Edge &f : edges) {
					for (int fe = 0; fe < 2; fe++) {
						if ((fe == 0 ? f.na : f.nb) != node || (&f == &e0 && fe == end)) continue;
						const int fn = (int)f.x.size();
						double hx = fe == 0 ? f.x[1] - f.x[0] : f.x[fn - 2] - f.x[fn - 1], hz = fe == 0 ? f.z[1] - f.z[0] : f.z[fn - 2] - f.z[fn - 1];
						const double hl = std::hypot(hx, hz);
						hx /= hl; hz /= hl;
						const double ang = std::atan2(hx * iz - hz * ix, ix * hx + iz * hz);
						if (ang > 0.70 && ang < 2.6) left_exists = true;
					}
				}
			}
			has[end] = art && hits >= 6 && left_exists;   // 3 m of arrow and more
		}
		const double POCKET = 55.0;
		if ((has[0] || has[1]) && e.len < POCKET * (has[0] && has[1] ? 2.0 : 1.0) + 40.0) {
			say("POCKET NOT MADE in block %s: the block is %.0f m, too short for its left-turn lane%s", blocks[e.block].id.c_str(), e.len, has[0] && has[1] ? "s" : "");
			has[0] = has[1] = false;
		}
		if (!has[0] && !has[1]) { res.push_back(e); continue; }
		int ia = 0, ib = n - 1;
		if (has[0]) { while (ia < n - 1 && e.s[ia] < POCKET) ia++; }
		if (has[1]) { while (ib > 0 && e.len - e.s[ib] < POCKET) ib--; }
		int node_from = e.na;
		if (has[0]) {
			Edge p = slice(e, 0, ia);
			SkNode in; in.x = e.x[ia]; in.z = e.z[ia]; in.inner = true;
			nodes.push_back(in);
			p.na = e.na; p.nb = (int)nodes.size() - 1; p.pocket[1] = true;   // direction 1 arrives at a
			res.push_back(p); node_from = p.nb; pockets++;
		}
		{
			Edge m = slice(e, ia, ib);
			m.na = node_from;
			if (has[1]) {
				SkNode in; in.x = e.x[ib]; in.z = e.z[ib]; in.inner = true;
				nodes.push_back(in);
				m.nb = (int)nodes.size() - 1;
			} else m.nb = e.nb;
			res.push_back(m);
			node_from = m.nb;
		}
		if (has[1]) {
			Edge p = slice(e, ib, n - 1);
			p.na = node_from; p.nb = e.nb; p.pocket[0] = true;   // direction 0 arrives at b
			res.push_back(p); pockets++;
		}
	}
	edges = res;
	rep.lane_changes = cuts; rep.pockets = pockets;
}

// The lanes: how many per direction and how far from the centre line, point by point (the lanes follow a change of
// the street's section over a 20 m taper).
void Builder::layout_lanes() {
	static const double VMAX[T_COUNT] = { 11.1, 11.1, 11.1, 11.1, 15.3, 13.9, 13.9, 19.4, 11.1 };   // 40 / 55 / 50 / 70 km/h
	for (Edge &e : edges) {
		const int n = (int)e.x.size();
		const SkBlock &b = blocks[e.block];
		int mode_all[2] = { T_NONE, T_NONE };
		for (int sd = 0; sd < 2; sd++) {
			int cnt[T_COUNT] = { 0 };
			for (int i = 0; i < n; i++) cnt[e.tm[sd][i]]++;
			int best = e.tm[sd][0];
			for (int k = 0; k < T_COUNT; k++) if (cnt[k] > cnt[best]) best = k;
			mode_all[sd] = best;
		}
		for (int d = 0; d < 2; d++) {
			if (e.oneway && d == 1) { e.nl[1] = 0; continue; }
			// lanes: as many as the narrowest stretch of the edge has (edges are cut where the count changes)
			int nl = 2;
			double hw = 9.0;
			for (int i = 0; i < n; i++) { nl = std::min(nl, TMPL[e.tm[d][i]].n); hw = std::min(hw, TMPL[e.tm[d][i]].hw); }
			if (e.oneway) nl = 1;
			const int pk = e.pocket[d] ? 1 : 0;   // a left-turn lane on the centre line is this direction's lane 0
			e.nl[d] = nl + pk; e.lhw[d] = hw;
			if (pk) e.off[d][0].assign(n, 0.0);
			for (int j = 0; j < nl; j++) {
				std::vector<double> raw(n);
				for (int i = 0; i < n; i++) {
					const Tmpl &t = TMPL[e.tm[d][i]];
					double o = t.off[std::min(j, t.n - 1)];
					const Side &sd = e.at[d][i].ok ? e.at[d][i] : e.med[d];
					if (e.tm[d][i] == T_GENERIC) o = sd.m + (sd.k - sd.m) * (sd.k - sd.m > 5.0 ? 0.3 : 0.5);   // a wide unknown side: the lane keeps to the centre line, the rest is taken as parking
					if (e.oneway) {   // the ramp: one lane in the middle of its asphalt
						const Side &r = e.at[0][i].ok ? e.at[0][i] : e.med[0], &l = e.at[1][i].ok ? e.at[1][i] : e.med[1];
						o = (r.k - l.k) * 0.5;
					}
					raw[i] = o;
				}
				std::vector<double> sm(n);
				for (int i = 0; i < n; i++) {
					double a = 0.0; int c = 0;
					for (int k = std::max(0, i - 5); k <= std::min(n - 1, i + 5); k++) { a += raw[k]; c++; }
					sm[i] = a / c;
				}
				e.off[d][j + pk] = sm;
			}
			if (e.oneway) e.lhw[0] = std::min(2.0, std::max(1.5, (e.med[0].k + e.med[1].k) * 0.5 - 0.9));
		}
		// speed, how busy, and its rank at junctions: from the kind of street most of the edge is
		const int kind = mode_all[0] != T_NONE ? mode_all[0] : mode_all[1];
		e.vmax = VMAX[kind];
		const bool busy = b.section == "hs" || b.section == "cc" || b.section == "strip";
		// How busy: cars per metre of lane at the busiest hour. Chosen so that the flow (cars per metre x speed) is about
		// half of what the junctions pass: a signal lane on this map's plan (green 40 % of 30 s) passes about 0.18
		// cars a second, an all-way stop about 0.07 per approach.
		switch (kind) {
			case T_ART: e.dens = 0.0065; e.cls = 4; break;
			case T_BLVD: case T_BLVD_PARK: e.dens = 0.0070; e.cls = 5; break;
			case T_BRIDGE: e.dens = 0.0060; e.cls = 5; break;
			case T_TRUCK: e.dens = 0.0030; e.cls = 2; break;
			default: e.dens = busy ? 0.0050 : (b.section == "std" ? 0.0040 : 0.0027); e.cls = busy ? 3 : (b.section == "std" ? 2 : 1); break;
		}
		if (e.oneway) { e.dens = 0.0040; e.cls = 3; }
	}
}

// ---------------------------------------------------------------- junctions
// For every edge end at a node: where the junction's kerb returns end (the street is straight from there on), whether a
// stop bar is painted across the approach and where, and so where the lanes end and what holds the approach.
void Builder::junctions() {
	const int nn = (int)nodes.size();
	legs.assign(nn, std::vector<Leg>());
	for (size_t ei = 0; ei < edges.size(); ei++) {
		const Edge &e = edges[ei];
		const int n = (int)e.x.size();
		if (e.na >= 0) {
			Leg l; l.e = (int)ei; l.end = 0; l.hx = e.x[1] - e.x[0]; l.hz = e.z[1] - e.z[0];
			const double d = std::hypot(l.hx, l.hz); l.hx /= d; l.hz /= d;
			legs[e.na].push_back(l);
		}
		if (e.nb >= 0) {
			Leg l; l.e = (int)ei; l.end = 1; l.hx = e.x[n - 2] - e.x[n - 1]; l.hz = e.z[n - 2] - e.z[n - 1];
			const double d = std::hypot(l.hx, l.hz); l.hx /= d; l.hz /= d;
			legs[e.nb].push_back(l);
		}
	}
	std::vector<int> heads(nn, 0);
	std::vector<int> head_node(signals.size() / 3, -1);
	double sig_grid[3] = { 100.0, 100.0, 200.0 };
	for (size_t k = 0; k + 2 < signals.size(); k += 3) {
		int best = -1; double bd = 45.0;
		for (int i = 0; i < nn; i++) {
			const double d = std::hypot(nodes[i].x - signals[k], nodes[i].z - signals[k + 2]);
			if (d < bd) { bd = d; best = i; }
		}
		head_node[k / 3] = best;
		if (best >= 0) heads[best]++; else rep.heads_no_junction++;
	}
	// The signal clock's tiles. The lamps' shader finds a head's junction by the tile the head stands in, so every head
	// of a junction with signals has to stand in its junction's tile, or the lamp and the traffic (and the lamps of one
	// junction among themselves) would run on different clocks. The junctions are not on one lattice (x = 0, 250, 500,
	// -951 ...): the tile size and where the tiles begin are searched for, the widest margin wins.
	{
		double best_m = -1.0;
		for (double size = 200.0; size <= 400.0 && best_m < 3.0; size += 40.0) {
			double o[2] = { 0, 0 }, m[2] = { -1, -1 };
			for (int ax = 0; ax < 2; ax++) {
				for (double off = 0.0; off < size; off += 2.5) {
					double mn = 1.0e9;
					for (size_t k = 0; k + 2 < signals.size() && mn >= 0.0; k += 3) {
						const int n = head_node[k / 3];
						if (n < 0 || heads[n] < 2) continue;
						const double h = signals[k + ax * 2] + off, c = (ax == 0 ? nodes[n].x : nodes[n].z) + off;
						if (std::floor(h / size) != std::floor(c / size)) { mn = -1.0; break; }
						const double fh = h - std::floor(h / size) * size, fc = c - std::floor(c / size) * size;
						mn = std::min(mn, std::min(std::min(fh, size - fh), std::min(fc, size - fc)));
					}
					if (mn > m[ax]) { m[ax] = mn; o[ax] = off; }
				}
			}
			if (std::min(m[0], m[1]) > best_m) { best_m = std::min(m[0], m[1]); sig_grid[0] = o[0]; sig_grid[1] = o[1]; sig_grid[2] = size; }
		}
		rep.heads_other_tile = 0;
		for (size_t k = 0; k + 2 < signals.size(); k += 3) {
			const int n = head_node[k / 3];
			if (n < 0 || heads[n] < 2) continue;
			if (std::floor((signals[k] + sig_grid[0]) / sig_grid[2]) != std::floor((nodes[n].x + sig_grid[0]) / sig_grid[2]) ||
					std::floor((signals[k + 2] + sig_grid[1]) / sig_grid[2]) != std::floor((nodes[n].z + sig_grid[1]) / sig_grid[2])) {
				rep.heads_other_tile++;
				say("SIGNAL HEAD at (%.1f, %.1f) lies in another clock tile than its junction at (%.1f, %.1f)", signals[k], signals[k + 2], nodes[n].x, nodes[n].z);
			}
		}
		say("SIGNAL CLOCK tiles of %.0f m beginning at (%.1f, %.1f): every head is at least %.1f m inside its junction's tile", sig_grid[2], -sig_grid[0], -sig_grid[1], best_m);
		out.sig_grid.assign(sig_grid, sig_grid + 3);
	}
	out.node_f.assign((size_t)nn * 4, 0.0f); out.node_i.assign((size_t)nn * 4, 0);
	for (int ni = 0; ni < nn; ni++) {
		const bool sig = heads[ni] >= 2;
		int node_ctl = CTL_NONE;
		for (const Leg &lg : legs[ni]) {
			Edge &e = edges[lg.e];
			const double reach = std::min(60.0, e.len * 0.5);
			auto s_of = [&](double d) { return lg.end == 0 ? d : e.len - d; };
			auto side_at = [&](double d, int sd) {
				double x, z, tx, tz; edge_at(e, s_of(d), x, z, tx, tz);
				return sd == 0 ? measure_side(x, z, -tz, tx) : measure_side(x, z, tz, -tx);
			};
			// 1. where the kerbs run straight again, on each side
			double tp = 2.0;
			for (int sd = 0; sd < 2; sd++) {
				std::vector<double> ref;
				for (double d = 20.0; d <= reach; d += 2.0) {
					const Side s = side_at(d, sd);
					if (s.ok) ref.push_back(s.k);
				}
				const double kref = ref.empty() ? e.med[sd].k : median(ref);
				double found = -1.0; int run = 0;
				for (double d = 1.0; d <= reach; d += 0.5) {
					const Side s = side_at(d, sd);
					if (s.ok && std::fabs(s.k - kref) < 0.12) {
						if (run == 0) found = d;
						run++;
						if (run >= 9) break;
					} else { run = 0; found = -1.0; }
				}
				if (run >= 9 && found > tp) tp = found;
			}
			e.tan_pt[lg.end] = tp;
			// 2. a stop bar across the lanes that arrive here: a white line at least 0.3 m deep that runs right across the
			//    approach (from its innermost lane's inner edge to its outermost lane's outer edge). Turn arrows are narrow,
			//    a crossing's stripes cover half of the width, its border lines are thin: none of them passes. Looked for
			//    from 45 m out towards the junction; the first one met is the bar.
			const int din = lg.end == 0 ? 1 : 0;   // the direction that arrives at this end
			double bar = -1.0;
			if (e.nl[din] > 0 && legs[ni].size() >= 3 && !nodes[ni].diverge) {
				auto white = [&](double d, double o) {
					double x, z, tx, tz; edge_at(e, s_of(d), x, z, tx, tz);
					return ground->layer_at((float)(x + tz * o), (float)(z - tx * o)) == G_PAINT_WHITE;
				};
				const double far = std::min(45.0, e.len * 0.5);
				for (double d = far; d >= 5.0 && bar < 0.0; d -= 0.1) {
					const double sgn = din == 0 ? -1.0 : 1.0;
					// (across the through lanes: a left-turn lane has its own short bar, or hatching)
					const int pk = e.pocket[din] ? 1 : 0;
					const double o0 = lane_off_at(e, din, pk, s_of(d)) - e.lhw[din] * 0.7, o1 = lane_off_at(e, din, e.nl[din] - 1, s_of(d)) + e.lhw[din] * 0.7;
					int hit = 0, all = 0;
					for (double o = o0; o <= o1 + 1e-6; o += 0.35) {
						all++;
						if (white(d, o * sgn) && white(d - 0.3, o * sgn)) hit++;
					}
					if (all >= 4 && hit * 10 >= all * 8) bar = d;
				}
			}
			int ctl = CTL_NONE;
			double trim = tp + 1.0;
			if (trim > 24.0) trim = 24.0;   // (a street that changes its width near the junction: its lanes still reach the junction)
			if (bar > 0.0) { ctl = sig ? CTL_SIGNAL : CTL_STOP; trim = bar + 0.25; }
			if (legs[ni].size() == 2) trim = 1.0;      // a bend or a joint of two blocks: the lanes run on
			if (nodes[ni].inner) trim = std::min(12.0, e.len * 0.2);   // lanes change here: 24 m for the cars to move over
			if (legs[ni].size() == 1) trim = 2.0;      // the street ends here
			if (nodes[ni].diverge) { trim = e.oneway ? 0.5 : 1.0; ctl = CTL_NONE; }   // a ramp leaves: nobody stops
			e.trim[lg.end] = trim; e.ctl[lg.end] = ctl;
			node_ctl = std::max(node_ctl, ctl);
			if (e.nl[din] > 0) {
				rep.approaches++;
				if (ctl == CTL_STOP) rep.approaches_stop++;
				if (ctl == CTL_SIGNAL) rep.approaches_signal++;
			}
		}
		float y = (float)nodes[ni].pad; int l = G_NONE;
		ground->query((float)nodes[ni].x, (float)nodes[ni].z, y, l);
		out.node_f[(size_t)ni * 4] = (float)nodes[ni].x; out.node_f[(size_t)ni * 4 + 1] = y; out.node_f[(size_t)ni * 4 + 2] = (float)nodes[ni].z;
		out.node_i[(size_t)ni * 4] = node_ctl; out.node_i[(size_t)ni * 4 + 1] = (int)legs[ni].size();
		out.node_i[(size_t)ni * 4 + 2] = (int)std::floor((nodes[ni].x + sig_grid[0]) / sig_grid[2]); out.node_i[(size_t)ni * 4 + 3] = (int)std::floor((nodes[ni].z + sig_grid[1]) / sig_grid[2]);
		if (legs[ni].size() >= 3) {
			if (node_ctl == CTL_SIGNAL) rep.nodes_signal++;
			else if (node_ctl == CTL_STOP) rep.nodes_stop++;
			else rep.nodes_free++;
		}
		std::string desc;
		for (const Leg &lg : legs[ni]) {
			const Edge &e = edges[lg.e];
			char buf[200];
			snprintf(buf, sizeof(buf), " [%s %s returns end %.1f, lanes end %.1f, %s]", blocks[e.block].id.c_str(), lg.end == 0 ? "a" : "b", e.tan_pt[lg.end], e.trim[lg.end],
					e.ctl[lg.end] == CTL_SIGNAL ? "SIGNAL" : (e.ctl[lg.end] == CTL_STOP ? "STOP" : "free"));
			desc += buf;
		}
		say("NODE %3d (%7.1f, %7.1f) legs %d signal heads %d:%s", ni, nodes[ni].x, nodes[ni].z, (int)legs[ni].size(), heads[ni], desc.c_str());
	}
	for (Edge &e : edges) {
		if (e.len - e.trim[0] - e.trim[1] < 6.0) {
			rep.short_edges++;
			say("SHORT block %s: %.1f m between its junctions' lane ends (%.1f + %.1f of %.1f)", blocks[e.block].id.c_str(), e.len - e.trim[0] - e.trim[1], e.trim[0], e.trim[1], e.len);
			const double k = std::max(0.0, (e.len - 6.0)) / std::max(e.trim[0] + e.trim[1], 1e-6);
			if (k < 1.0) { e.trim[0] *= k; e.trim[1] *= k; }
		}
	}
}

// ---------------------------------------------------------------- lanes and connections out
namespace {
// keep the points a line needs: straight and evenly sloped stretches lose theirs (to 3 cm)
void simplify(const std::vector<float> &p, std::vector<float> &o) {
	const int n = (int)p.size() / 3;
	std::vector<char> keep(n, 0);
	keep[0] = keep[n - 1] = 1;
	std::vector<std::pair<int, int>> st;
	st.push_back({ 0, n - 1 });
	while (!st.empty()) {
		const int a = st.back().first, b = st.back().second;
		st.pop_back();
		if (b - a < 2) continue;
		const float ax = p[a * 3], ay = p[a * 3 + 1], az = p[a * 3 + 2], dx = p[b * 3] - ax, dy = p[b * 3 + 1] - ay, dz = p[b * 3 + 2] - az;
		const float l2 = dx * dx + dy * dy + dz * dz;
		int worst = -1; float wd = 0.03f * 0.03f;
		for (int i = a + 1; i < b; i++) {
			const float qx = p[i * 3] - ax, qy = p[i * 3 + 1] - ay, qz = p[i * 3 + 2] - az;
			const float t = l2 > 1e-12f ? std::min(1.0f, std::max(0.0f, (qx * dx + qy * dy + qz * dz) / l2)) : 0.0f;
			const float ex = qx - dx * t, ey = qy - dy * t, ez = qz - dz * t, d2 = ex * ex + ey * ey + ez * ez;
			if (d2 > wd) { wd = d2; worst = i; }
		}
		if (worst >= 0) { keep[worst] = 1; st.push_back({ a, worst }); st.push_back({ worst, b }); }
	}
	o.clear();
	for (int i = 0; i < n; i++) {
		if (!keep[i]) continue;
		o.push_back(p[i * 3]); o.push_back(p[i * 3 + 1]); o.push_back(p[i * 3 + 2]);
	}
}
} // namespace

void Builder::emit_lanes() {
	out.lane_off.assign(1, 0);
	float worst_g[2] = { 0, 0 }, worst_k[2] = { 0, 0 };
	for (size_t ei = 0; ei < edges.size(); ei++) {
		Edge &e = edges[ei];
		const double s0 = e.trim[0], s1 = e.len - e.trim[1];
		int edge_off = 0, edge_none = 0, edge_bad_h = 0;
		float first_bad[2] = { 0, 0 };
		for (int d = 0; d < 2; d++) {
			e.first_lane[d] = e.nl[d] > 0 ? out.lanes() : -1;
			for (int j = 0; j < e.nl[d]; j++) {
				std::vector<double> ss;
				ss.push_back(s0);
				for (double s : e.s) if (s > s0 + 0.5 && s < s1 - 0.5) ss.push_back(s);
				ss.push_back(s1);
				if (d == 1) std::reverse(ss.begin(), ss.end());
				std::vector<float> raw;
				float last_y = (float)nodes[e.na >= 0 ? e.na : 0].pad;
				for (double s : ss) {
					double x, z, tx, tz; edge_at(e, s, x, z, tx, tz);
					const double o = lane_off_at(e, d, j, s) * (d == 0 ? -1.0 : 1.0);   // direction 0 keeps to the right of a -> b
					const float px = (float)(x + tz * o), pz = (float)(z - tx * o);
					float y = last_y; int l = G_NONE;
					rep.lane_pts++;
					if (!ground->query(px, pz, y, l)) {
						rep.lane_pts_no_ground++;
						if (edge_off + edge_none == 0) { first_bad[0] = px; first_bad[1] = pz; }
						edge_none++;
					} else if (!is_road(l)) {
						rep.lane_pts_off_road++;
						if (edge_off + edge_none == 0) { first_bad[0] = px; first_bad[1] = pz; }
						edge_off++;
					}
					else if (!is_road(ground->layer_at((float)(px + tz * 0.95), (float)(pz - tx * 0.95))) || !is_road(ground->layer_at((float)(px - tz * 0.95), (float)(pz + tx * 0.95)))) {
						rep.lane_pts_tight++;
						if (edge_off + edge_none == 0) { first_bad[0] = px; first_bad[1] = pz; }
						edge_off++;
					}
					last_y = y;
					raw.push_back(px); raw.push_back(y); raw.push_back(pz);
				}
				const int np = (int)raw.size() / 3;
				for (int i = 1; i < np; i++) {
					const float run = std::hypot(raw[i * 3] - raw[i * 3 - 3], raw[i * 3 + 2] - raw[i * 3 - 1]);
					const double grade = run > 0.2f ? (double)std::fabs(raw[i * 3 + 1] - raw[i * 3 - 2]) / run : 0.0;
					const double kink = i + 1 < np ? (double)std::fabs(raw[i * 3 + 1] - 0.5f * (raw[i * 3 - 2] + raw[i * 3 + 4])) : 0.0;
					if (grade > rep.worst_grade) { rep.worst_grade = grade; worst_g[0] = raw[i * 3]; worst_g[1] = raw[i * 3 + 2]; }
					if (kink > rep.worst_kink) { rep.worst_kink = kink; worst_k[0] = raw[i * 3]; worst_k[1] = raw[i * 3 + 2]; }
					if (grade > 0.09 || kink > 0.04) edge_bad_h++;
				}
				std::vector<float> pts;
				simplify(raw, pts);
				out.lane_pts.insert(out.lane_pts.end(), pts.begin(), pts.end());
				out.lane_off.push_back((int32_t)(out.lane_pts.size() / 3));
				const int id = out.lanes() - 1;
				const float f[6] = { (float)e.vmax, (float)e.lhw[d], 0.0f, 0.0f, -1.0f, (float)e.dens };
				out.lane_f.insert(out.lane_f.end(), f, f + 6);
				const int n_start = d == 0 ? e.na : e.nb, n_end = d == 0 ? e.nb : e.na;
				const int ctl = e.ctl[d == 0 ? 1 : 0];
				// which clock phase the approach is on: the signal shader gives heads facing along x half a cycle later
				const float hx = pts[pts.size() - 3] - pts[pts.size() - 6], hz = pts[pts.size() - 1] - pts[pts.size() - 4];
				const int phase = std::fabs(hx) > std::fabs(hz) ? 1 : 0;
				// flags: 1 = a driving lane; 16 = it runs out of the map (it ends at a node with no other street that is not a
				// hole in a street: the far end of the bridge)
				const bool exits = n_end >= 0 && legs[n_end].size() == 1 && !nodes[n_end].deadend;
				// neighbours for lane changes; a left-turn lane has none (it is entered at its start, left at the junction)
				const int pk = e.pocket[d] ? 1 : 0;
				const int left = (j > pk) ? id - 1 : -1, right = (j + 1 < e.nl[d] && j >= pk) ? id + 1 : -1;
				const int32_t ia[12] = { (int32_t)ei, d, j, left, right, n_start, n_end, e.cls, 1 | (exits ? 16 : 0), ctl, n_end, phase };
				out.lane_i.insert(out.lane_i.end(), ia, ia + 12);
			}
		}
		if (edge_off + edge_none + edge_bad_h > 0) {
			say("LANES NOT ON THE STREET block %s (%s, %s): %d points off the asphalt, %d with no ground under them (first at %.1f, %.1f), %d steep or kinked", blocks[e.block].id.c_str(),
					blocks[e.block].name.c_str(), blocks[e.block].section.c_str(), edge_off, edge_none, first_bad[0], first_bad[1], edge_bad_h);
		}
	}
	say("WORST steepest stretch at (%.1f, %.1f), largest kink at (%.1f, %.1f)", worst_g[0], worst_g[1], worst_k[0], worst_k[1]);
	// connections: every lane that arrives at a node to the lanes that leave it on the other legs
	out.conns.clear();
	for (size_t ni = 0; ni < legs.size(); ni++) {
		for (const Leg &in : legs[ni]) {
			const Edge &ei = edges[in.e];
			const int din = in.end == 0 ? 1 : 0;
			if (ei.nl[din] == 0) continue;
			int made = 0;
			for (const Leg &ot : legs[ni]) {
				if (ot.e == in.e && ot.end == in.end) continue;
				const Edge &eo = edges[ot.e];
				const int dout = ot.end == 0 ? 0 : 1;
				if (eo.nl[dout] == 0) continue;
				const double ix = -in.hx, iz = -in.hz;   // the way the approach travels
				const double dot = ix * ot.hx + iz * ot.hz, left = ot.hx * iz - ot.hz * ix;
				const double ang = std::atan2(left, dot);
				if (std::fabs(ang) > 2.6) continue;      // back the way it came
				const int turn = std::fabs(ang) < 0.70 ? TURN_STRAIGHT : (ang > 0 ? TURN_LEFT : TURN_RIGHT);
				const int n_in = ei.nl[din], n_out = eo.nl[dout];
				auto add = [&](int a, int b) {
					const int32_t c[5] = { ei.first_lane[din] + a, eo.first_lane[dout] + b, turn, (int32_t)ni, 40 };
					out.conns.insert(out.conns.end(), c, c + 5);
					made++;
				};
				const int pin = ei.pocket[din] ? 1 : 0, pout = eo.pocket[dout] ? 1 : 0;   // a left-turn lane as lane 0
				if (turn == TURN_STRAIGHT && eo.oneway && nodes[ni].diverge) add(n_in - 1, 0);   // a ramp is left from the outer lane
				else if (turn == TURN_STRAIGHT) {
					// through lanes to through lanes, innermost to innermost (a left-turn lane is not a through lane)
					const int ti = n_in - pin, to = n_out - pout;
					for (int a = 0; a < ti; a++) add(a + pin, std::min(a, to - 1) + pout);
					for (int b = ti; b < to; b++) add(n_in - 1, b + pout);   // the street gains a lane: the outer lane opens into it
					if (pout) {   // a left-turn lane starts here: it is entered from the innermost through lane
						const int32_t c[5] = { ei.first_lane[din] + pin, eo.first_lane[dout], TURN_LEFT, (int32_t)ni, 40 };
						out.conns.insert(out.conns.end(), c, c + 5);
					}
				}
				else if (turn == TURN_LEFT) add(0, pout);
				else add(n_in - 1, n_out - 1);
			}
			if (made == 0 && legs[ni].size() > 1) {
				rep.legs_unconnected++;
				say("APPROACH WITH NO WAY ON: block %s at node %d", blocks[ei.block].id.c_str(), (int)ni);
			}
		}
	}
}

// Every path through every junction, every 1.5 m of it, as wide as a car (0.95 m each side of the path): on the
// asphalt? A turn whose plain curve would touch a kerb corner takes a wider one: the tool tries wider curves in turn
// and keeps the first that is clear; the choice is stored with the connection, and the traffic drives exactly that.
void Builder::check_paths() {
	static const int REACH[7] = { 40, 50, 60, 70, 80, 90, 100 };
	const double HALF_CAR = 0.95;
	const int nc = out.connections();
	std::vector<float> pts;
	std::vector<int> bad_at_node(nodes.size(), 0);
	auto count_bad = [&]() {
		int bad = 0;
		const int np = (int)pts.size() / 3;
		for (int i = 0; i < np; i++) {
			const int i0 = std::max(i - 1, 0), i1 = std::min(i + 1, np - 1);
			double tx = pts[i1 * 3] - pts[i0 * 3], tz = pts[i1 * 3 + 2] - pts[i0 * 3 + 2];
			const double tl = std::hypot(tx, tz);
			if (tl > 1e-9) { tx /= tl; tz /= tl; }
			bool ok = true;
			for (int w = -1; w <= 1 && ok; w++) ok = is_road(ground->layer_at((float)(pts[i * 3] + tz * w * HALF_CAR), (float)(pts[i * 3 + 2] - tx * w * HALF_CAR)));
			if (!ok) bad++;
		}
		return bad;
	};
	// A STEERED car (the traffic's body, traffic_body.h: the longest and widest car, at a turn's speed) driven from 20 m
	// before the path to 12 m after it: points of its body (four corners, the middle of each side) that are not on the
	// asphalt while its middle is on the path, and how far its middle strays from the path.
	int drive_n = 0; float drive_miss = 0.0f;
	auto drive_bad = [&](int c) {
		const int a = out.conns[(size_t)c * StreetData::CONN], b = out.conns[(size_t)c * StreetData::CONN + 1];
		tc::Window w;
		w.n = 0;
		std::vector<float> line;   // x, z of the lane before, the path, the lane after
		{
			const int o0 = out.lane_off[a], o1 = out.lane_off[a + 1];
			int k = o1 - 1; float back = 0.0f;
			while (k > o0 && back < 22.0f) { back += std::hypot(out.lane_pts[(size_t)k * 3] - out.lane_pts[(size_t)(k - 1) * 3], out.lane_pts[(size_t)k * 3 + 2] - out.lane_pts[(size_t)(k - 1) * 3 + 2]); k--; }
			for (; k < o1 - 1; k++) { line.push_back(out.lane_pts[(size_t)k * 3]); line.push_back(out.lane_pts[(size_t)k * 3 + 2]); }
		}
		const int i_path0 = (int)line.size() / 2;
		for (size_t q = 0; q + 2 < pts.size() + 1; q += 3) { line.push_back(pts[q]); line.push_back(pts[q + 2]); }
		const int i_path1 = (int)line.size() / 2 - 1;
		{
			const int o0 = out.lane_off[b], o1 = out.lane_off[b + 1];
			float fwd = 0.0f;
			for (int k = o0 + 1; k < o1 && fwd < 14.0f; k++) {
				fwd += std::hypot(out.lane_pts[(size_t)k * 3] - out.lane_pts[(size_t)(k - 1) * 3], out.lane_pts[(size_t)k * 3 + 2] - out.lane_pts[(size_t)(k - 1) * 3 + 2]);
				line.push_back(out.lane_pts[(size_t)k * 3]); line.push_back(out.lane_pts[(size_t)k * 3 + 2]);
			}
		}
		float acc = 0.0f, s_path0 = 0.0f, s_path1 = 0.0f;
		for (size_t q = 0; q * 2 < line.size() && w.n < tc::WIN_MAX; q++) {
			if (q > 0) { const float d = std::hypot(line[q * 2] - line[q * 2 - 2], line[q * 2 + 1] - line[q * 2 - 1]); if (d < 0.05f) continue; acc += d; }
			if ((int)q <= i_path0) s_path0 = acc;
			if ((int)q <= i_path1) s_path1 = acc;
			w.x[w.n] = line[q * 2]; w.z[w.n] = line[q * 2 + 1]; w.s[w.n] = acc; w.n++;
		}
		if (w.n < 3) return 0;
		const float HL = 2.6f, HW = 0.95f, WB = 3.05f;
		// how sharply the path turns decides the speed it is driven at (the traffic's own rule: 2.2 m/s^2 sideways)
		float tight = 1.0e9f;
		for (int k = 1; k + 1 < w.n; k++) {
			if (w.s[k] < s_path0 || w.s[k] > s_path1) continue;
			const float d0x = w.x[k] - w.x[k - 1], d0z = w.z[k] - w.z[k - 1], d1x = w.x[k + 1] - w.x[k], d1z = w.z[k + 1] - w.z[k];
			const float turn = std::fabs(std::atan2(d0x * d1z - d0z * d1x, d0x * d1x + d0z * d1z));
			const float seg = 0.5f * (std::hypot(d0x, d0z) + std::hypot(d1x, d1z));
			if (turn > 1.0e-4f) tight = std::min(tight, seg / turn);
		}
		const float v = std::min(std::max(std::sqrt(2.2f * tight), 2.0f), 12.0f);
		tc::Body bd{ w.x[0], w.z[0], std::atan2(w.x[1] - w.x[0], w.z[1] - w.z[0]), 0.0f };
		int bad = 0;
		float done = 0.0f;
		// (the window's own scale starts at its first point: shift it as the car goes, as the core's window does)
		const float total = w.s[w.n - 1];
		std::vector<float> s0(w.s, w.s + w.n);
		while (done < total - 1.0f) {
			for (int k = 0; k < w.n; k++) w.s[k] = s0[k] - done;
			const tc::BodyRun r = tc::body_run(bd, w, WB, 0.61f, 0.4f, v, 0.0f, 0.0f);
			done += std::max(r.s_c, 0.05f);
			if (done < s_path0 - 1.0f || done > s_path1 + 3.0f) continue;
			drive_miss = std::max(drive_miss, std::fabs(r.lat_c));
			const float fx = std::sin(bd.yaw), fz = std::cos(bd.yaw);
			const float px[6] = { HL, HL, -HL, -HL, 0.0f, 0.0f }, pl[6] = { HW, -HW, HW, -HW, HW, -HW };
			bool ok = true;
			for (int q = 0; q < 6 && ok; q++) ok = is_road(ground->layer_at(bd.x + fx * px[q] + fz * pl[q], bd.z + fz * px[q] - fx * pl[q]));
			drive_n++;
			if (!ok) bad++;
		}
		return bad;
	};
	for (int c = 0; c < nc; c++) {
		int best = 40, best_bad = 1 << 30;
		for (int k = 0; k < 7 && best_bad > 0; k++) {
			out.conns[(size_t)c * StreetData::CONN + 4] = REACH[k];
			pts.clear();
			out.path(c, pts);
			const int bad = count_bad() + drive_bad(c);   // the path itself as wide as a car, and the steered car on it
			if (bad < best_bad) { best_bad = bad; best = REACH[k]; }
		}
		out.conns[(size_t)c * StreetData::CONN + 4] = best;
		pts.clear();
		out.path(c, pts);
		rep.path_pts += (int)pts.size() / 3;
		{
			drive_n = 0; drive_miss = 0.0f;
			const int db = drive_bad(c);
			rep.body_pts += drive_n; rep.body_pts_off_road += db; if (db > 0) rep.body_paths_off_road++;
			rep.body_miss_max = std::max(rep.body_miss_max, drive_miss);
			best_bad = count_bad();   // (the lines below report the path's own points, as before)
			if (db > 0 && best_bad == 0) {
				const int node = out.conns[(size_t)c * StreetData::CONN + 3];
				if (bad_at_node[node]++ < 4) say("A STEERED CAR'S BODY LEAVES THE ASPHALT at node %d (%.1f, %.1f), path %d: %d of %d places, even on the best curve", node, nodes[node].x, nodes[node].z, c, db, drive_n);
			}
		}
		if (best != 40) rep.paths_widened++;
		if (best_bad > 0) {
			rep.path_pts_off_road += best_bad; rep.paths_off_road++;
			const int node = out.conns[(size_t)c * StreetData::CONN + 3];
			if (bad_at_node[node]++ < 4) {
				const int a = out.conns[(size_t)c * StreetData::CONN], b = out.conns[(size_t)c * StreetData::CONN + 1], turn = out.conns[(size_t)c * StreetData::CONN + 2];
				say("PATH TOUCHES A KERB at node %d (%.1f, %.1f): %s from block %s to block %s, %d of %d points even on the best curve", node, nodes[node].x, nodes[node].z,
						turn == TURN_LEFT ? "left" : (turn == TURN_RIGHT ? "right" : "straight on"), blocks[edges[out.lane_i[(size_t)a * 12]].block].id.c_str(),
						blocks[edges[out.lane_i[(size_t)b * 12]].block].id.c_str(), best_bad, (int)pts.size() / 3);
			}
		}
	}
}

// ---------------------------------------------------------------- pavements, corners, crossings
// Every street side that has a pavement gets a walk line down its middle. At a junction the walk lines of two
// neighbouring legs meet in a corner point (one node of the walk graph, shared), so people turn the corner on the
// pavement. Where an approach has a stop bar there is a painted crossing just inside it: a crossing segment joins the
// two pavements of that leg there. At signals the crossing knows which traffic it crosses (the clock phase of that
// leg's lanes): people walk while that traffic has red. Elsewhere they take a gap and cars give way.
void Builder::emit_walks() {
	const int ne = (int)edges.size();
	// 1. the walk line of every edge side, point by point: its distance from the centre line and its half width
	for (Edge &e : edges) {
		const int n = (int)e.x.size();
		for (int sd = 0; sd < 2; sd++) {
			e.wc[sd].assign(n, 0.0); e.whw[sd].assign(n, 0.0);
			const Side &m = e.med[sd];
			if (!m.ok || m.w1 - m.w0 < 0.8) continue;   // no pavement on this side (the bridge's deck)
			// A point's own pavement counts when it is found there and about as far out as the block's typical one; the
			// points between (a driveway, an alley's mouth, a junction) lie on the line from one found point to the next.
			// The line is NOT averaged over a long stretch: where a street flares the pavement swings out within a few
			// metres, and an averaged line would cut the corner over the road.
			std::vector<double> raw(n, 0.0), hw(n, 0.0);
			std::vector<char> own(n, 0);
			int n_own = 0;
			for (int i = 0; i < n; i++) {
				const Side &s = e.at[sd][i];
				if (!(s.ok && s.w1 - s.w0 >= 0.8 && std::fabs(s.w0 - m.w0) < 8.0)) continue;
				const double w1 = std::min(s.w1, s.w0 + 7.0);
				raw[i] = (s.w0 + w1) * 0.5; hw[i] = std::max(0.5, (w1 - s.w0) * 0.5 - 0.25);
				own[i] = 1; n_own++;
			}
			if (n_own * 10 < n * 6) continue;   // most of this side has no pavement (the bridge, its ramp): none at all
			int last = -1;
			for (int i = 0; i < n; i++) {
				if (!own[i]) continue;
				if (last < 0) { for (int j = 0; j < i; j++) { raw[j] = raw[i]; hw[j] = hw[i]; } }
				else {
					for (int j = last + 1; j < i; j++) {
						const double u = (double)(j - last) / (double)(i - last);
						raw[j] = raw[last] + (raw[i] - raw[last]) * u; hw[j] = std::min(hw[last], hw[i]);
					}
				}
				last = i;
			}
			for (int j = last + 1; j < n; j++) { raw[j] = raw[last]; hw[j] = hw[last]; }
			for (int i = 0; i < n; i++) {
				double a = 0.0, b = 1e9; int c = 0;
				for (int k = std::max(0, i - 1); k <= std::min(n - 1, i + 1); k++) { a += raw[k]; b = std::min(b, hw[k]); c++; }
				e.wc[sd][i] = a / c; e.whw[sd][i] = b;
			}
		}
	}
	auto walk_at = [&](const Edge &e, int sd, double s, double &hw) {
		const int n = (int)e.x.size();
		s = std::min(std::max(s, 0.0), e.len);
		int i = (int)(std::upper_bound(e.s.begin(), e.s.end(), s) - e.s.begin()) - 1;
		i = std::min(std::max(i, 0), n - 2);
		const double l = e.s[i + 1] - e.s[i], u = l > 1e-9 ? (s - e.s[i]) / l : 0.0;
		hw = std::min(e.whw[sd][i], e.whw[sd][i + 1]);
		return e.wc[sd][i] + (e.wc[sd][i + 1] - e.wc[sd][i]) * u;
	};
	auto add_node = [&](double x, double z) {
		out.walk_node.push_back((float)x); out.walk_node.push_back((float)z);
		return (int)out.walk_node.size() / 2 - 1;
	};
	// 2. the corners: per edge, side, end -> walk graph node and how far from the edge's end the walk line ends
	struct End { int node = -1; double d = 0.0; };
	std::vector<End> ends((size_t)ne * 4);   // edge * 4 + side * 2 + end
	auto end_of = [&](int e, int sd, int end) -> End & { return ends[(size_t)e * 4 + sd * 2 + end]; };
	std::vector<int> mouth_nodes;   // walk graph nodes that stand on asphalt on purpose
	for (size_t ni = 0; ni < legs.size(); ni++) {
		std::vector<Leg> L = legs[ni];
		if (L.empty()) continue;
		std::sort(L.begin(), L.end(), [](const Leg &a, const Leg &b) { return std::atan2(a.hx, a.hz) < std::atan2(b.hx, b.hz); });
		const int nlg = (int)L.size();
		// the walk line of a leg's side near the junction: where it is 25 m out (clear of the kerb returns)
		auto mouth = [&](const Leg &lg, int sd) {
			const Edge &e = edges[lg.e];
			double hw;
			const double d = std::min(25.0, e.len * 0.5);
			return walk_at(e, sd, lg.end == 0 ? d : e.len - d, hw);
		};
		if (nlg == 1) {   // the street ends: so do its pavements
			for (int sd = 0; sd < 2; sd++) {
				const Edge &e = edges[L[0].e];
				if (e.wc[sd].empty() || mouth(L[0], sd) <= 0.0) continue;
				double x, z, tx, tz; edge_at(e, L[0].end == 0 ? 2.0 : e.len - 2.0, x, z, tx, tz);
				const double o = mouth(L[0], sd) * (sd == 0 ? -1.0 : 1.0);
				End &en = end_of(L[0].e, sd, L[0].end);
				en.node = add_node(x + tz * o, z - tx * o); en.d = 2.0;
			}
			continue;
		}
		for (int k = 0; k < nlg; k++) {
			const Leg &A = L[k], &B = L[(k + 1) % nlg];   // B is the next leg to the LEFT of A (seen leaving the node)
			const int sa = A.end == 0 ? 1 : 0, sb = B.end == 0 ? 0 : 1;   // A's side towards B, B's side towards A
			const double wa = mouth(A, sa), wb = mouth(B, sb);
			const double nax = A.hz, naz = -A.hx, nbx = -B.hz, nbz = B.hx;   // across each leg, towards the other
			double t = 0.0, u = 0.0, px, pz;
			bool mouth_node = false;
			const double det = A.hx * (-B.hz) - (-B.hx) * A.hz;
			const double rx = nbx * wb - nax * wa, rz = nbz * wb - naz * wa;
			if (std::fabs(det) > 0.26 && wa > 0.0 && wb > 0.0) {
				t = (rx * (-B.hz) - (-B.hx) * rz) / det; u = (A.hx * rz - A.hz * rx) / det;
				t = std::min(std::max(t, 0.0), 40.0); u = std::min(std::max(u, 0.0), 40.0);
				px = nodes[ni].x + A.hx * t + nax * wa; pz = nodes[ni].z + A.hz * t + naz * wa;
			} else if (wa > 0.0 && wb > 0.0) {   // the two legs run on in one line: their pavements join across the node
				px = nodes[ni].x + (nax * wa + nbx * wb) * 0.5; pz = nodes[ni].z + (naz * wa + nbz * wb) * 0.5;
			} else if (wa > 0.0) { t = 12.0; px = nodes[ni].x + A.hx * t + nax * wa; pz = nodes[ni].z + A.hz * t + naz * wa; }
			else if (wb > 0.0) { u = 12.0; px = nodes[ni].x + B.hx * u + nbx * wb; pz = nodes[ni].z + B.hz * u + nbz * wb; }
			else continue;
			// The corner must stand on a pavement.
			//  - On the road: a wide kerb return (12 m at the truck junctions) cuts the corner off, the two lines cross
			//    on the asphalt. The point is pushed out, away from the junction, until it is on the pavement.
			//  - No ground: an unbuilt lot behind the pavement. It is pulled in, towards the junction.
			auto on_walk = [&](double x, double z) {
				float y; int l = G_NONE;
				return ground->query((float)x, (float)z, y, l) && !is_road(l);
			};
			const bool joined = !(std::fabs(det) > 0.26) && wa > 0.0 && wb > 0.0;
			if (joined && is_road(ground->layer_at((float)px, (float)pz))) {
				// two pavements that run on in one line, and asphalt between them: the mouth of a side street or a car park
				// that the skeleton does not list. People walk across it; the point stays where it is.
				mouth_node = true; rep.walk_driveways++;
			} else if (!on_walk(px, pz)) {
				double dx = px - nodes[ni].x, dz = pz - nodes[ni].z;
				const double dl = std::hypot(dx, dz);
				dx /= dl; dz /= dl;
				const bool road_here = is_road(ground->layer_at((float)px, (float)pz));
				bool found = false;
				for (double m = 0.25; m <= 12.0 && !found; m += 0.25) {
					const double sgn = road_here ? 1.0 : -1.0;
					if (m * (road_here ? 0.0 : 1.0) > dl) break;
					if (on_walk(px + dx * m * sgn, pz + dz * m * sgn) && on_walk(px + dx * (m + 0.5) * sgn, pz + dz * (m + 0.5) * sgn)) {
						px += dx * (m + 0.5) * sgn; pz += dz * (m + 0.5) * sgn; found = true;
					}
				}
				if (!found) {
					rep.corners_no_ground++;
					say("CORNER WITHOUT PAVEMENT at node %d (%.1f, %.1f): no pavement at (%.1f, %.1f) nor near it. The map has a hole there", (int)ni, nodes[ni].x, nodes[ni].z, px, pz);
				}
			}
			// each of the two walk lines ends where it is still on its pavement (beyond the kerb return), and goes
			// straight to the corner point from there
			auto line_end = [&](const Leg &lg, int sd, double from) {
				const Edge &e = edges[lg.e];
				int run = 0;
				for (double d = from; d <= std::min(45.0, e.len * 0.5); d += 0.5) {
					double x, z, tx, tz, hw; edge_at(e, lg.end == 0 ? d : e.len - d, x, z, tx, tz);
					const double o = walk_at(e, sd, lg.end == 0 ? d : e.len - d, hw) * (sd == 0 ? -1.0 : 1.0);
					run = on_walk(x + tz * o, z - tx * o) ? run + 1 : 0;
					if (run >= 7) return d - 3.0;   // on its pavement from here on, for 3 m at least
				}
				return from;
			};
			if (wa > 0.0) t = line_end(A, sa, t);
			if (wb > 0.0) u = line_end(B, sb, u);
			const int wn = add_node(px, pz);
			if (mouth_node) mouth_nodes.push_back(wn);
			if (wa > 0.0) { End &en = end_of(A.e, sa, A.end); en.node = wn; en.d = t; }
			if (wb > 0.0) { End &en = end_of(B.e, sb, B.end); en.node = wn; en.d = u; }
		}
	}
	// 3. the walk lines between their corners, cut where a crossing starts; then the crossings
	auto add_seg = [&](int a, int b, int kind, int zone, int junction, int phase, const std::vector<float> &pts, double hw) {
		double len = 0.0;
		for (size_t k = 3; k + 2 < pts.size(); k += 3) len += std::hypot(pts[k] - pts[k - 3], pts[k + 2] - pts[k - 1]);
		const int32_t si[8] = { a, b, kind, zone, junction, phase, (int32_t)(out.walk_pts.size() / 3), (int32_t)(pts.size() / 3) };
		out.walk_seg.insert(out.walk_seg.end(), si, si + 8);
		out.walk_seg_f.push_back((float)len); out.walk_seg_f.push_back((float)hw);
		out.walk_pts.insert(out.walk_pts.end(), pts.begin(), pts.end());
	};
	int said = 0;
	for (int ei = 0; ei < ne; ei++) {
		const Edge &e = edges[ei];
		const SkBlock &b = blocks[e.block];
		// where the crossings are, per end: just inside the stop bar (bar, a gap of 1.2 m, a 3 m crossing)
		double xs[2] = { -1.0, -1.0 };
		for (int end = 0; end < 2; end++) {
			if (e.ctl[end] == CTL_NONE) continue;
			const double dx = e.trim[end] - 0.25 - 3.1;
			if (dx > 3.0) xs[end] = end == 0 ? dx : e.len - dx;
		}
		int xnode[2][2] = { { -1, -1 }, { -1, -1 } };   // [end][side]
		int edge_none = 0, edge_road = 0;
		float first_bad[2] = { 0, 0 };
		for (int sd = 0; sd < 2; sd++) {
			const End &ea = end_of(ei, sd, 0), &eb = end_of(ei, sd, 1);
			if (ea.node < 0 || eb.node < 0) continue;
			const double s0 = ea.d, s1 = e.len - eb.d;
			if (s1 - s0 < 1.0) continue;
			const bool busy = b.section == "hs" || b.section == "cc" || b.section == "strip";
			const int zone = (e.med[sd].w1 - e.med[sd].w0 > 3.6 && b.section == "ring") ? 3 : (busy ? 2 : (e.cls >= 4 ? 4 : (e.cls == 2 ? 1 : 0)));
			// the cuts along this walk line
			std::vector<std::pair<double, int>> cut;
			cut.push_back({ s0, ea.node });
			for (int end = 0; end < 2; end++) {
				if (xs[end] <= s0 + 0.5 || xs[end] >= s1 - 0.5) continue;
				double x, z, tx, tz, hw; edge_at(e, xs[end], x, z, tx, tz);
				const double o = walk_at(e, sd, xs[end], hw) * (sd == 0 ? -1.0 : 1.0);
				xnode[end][sd] = add_node(x + tz * o, z - tx * o);
				cut.push_back({ xs[end], xnode[end][sd] });
			}
			cut.push_back({ s1, eb.node });
			std::sort(cut.begin(), cut.end());
			for (size_t c = 0; c + 1 < cut.size(); c++) {
				std::vector<float> pts;
				std::vector<char> flag;
				double hw_min = 9.0;
				std::vector<double> ss;
				ss.push_back(cut[c].first);
				for (double s : e.s) if (s > cut[c].first + 0.5 && s < cut[c + 1].first - 0.5) ss.push_back(s);
				ss.push_back(cut[c + 1].first);
				float last_y = (float)nodes[e.na >= 0 ? e.na : 0].pad;
				for (size_t k = 0; k < ss.size(); k++) {
					double x, z, tx, tz, hw; edge_at(e, ss[k], x, z, tx, tz);
					const double o = walk_at(e, sd, ss[k], hw) * (sd == 0 ? -1.0 : 1.0);
					float px = (float)(x + tz * o), pz = (float)(z - tx * o);
					// the ends are the graph's nodes themselves (a corner point is where two legs' lines cross)
					if (k == 0) { px = out.walk_node[(size_t)cut[c].second * 2]; pz = out.walk_node[(size_t)cut[c].second * 2 + 1]; }
					if (k + 1 == ss.size()) { px = out.walk_node[(size_t)cut[c + 1].second * 2]; pz = out.walk_node[(size_t)cut[c + 1].second * 2 + 1]; }
					hw_min = std::min(hw_min, hw);
					float y = last_y; int l = G_NONE;
					rep.walk_pts++;
					int state = 0;   // 1 = no ground, 2 = on asphalt
					if (!ground->query(px, pz, y, l)) state = 1;
					else if (is_road(l)) state = 2;
					flag.push_back((char)state);
					last_y = y;
					pts.push_back(px); pts.push_back(y); pts.push_back(pz);
				}
				// asphalt across a pavement for a few metres is a driveway or an alley mouth: people walk over it. More than
				// 12 m of it, or no ground at all, is the walk line off its pavement.
				for (size_t k = 0; k < flag.size();) {
					if (flag[k] == 0) { k++; continue; }
					size_t j = k;
					while (j < flag.size() && flag[j] == flag[k]) j++;
					const double run = std::hypot(pts[(j - 1) * 3] - pts[k * 3], pts[(j - 1) * 3 + 2] - pts[k * 3 + 2]);
					const bool at_mouth = (k == 0 && std::find(mouth_nodes.begin(), mouth_nodes.end(), cut[c].second) != mouth_nodes.end()) ||
							(j == flag.size() && std::find(mouth_nodes.begin(), mouth_nodes.end(), cut[c + 1].second) != mouth_nodes.end());
					if (flag[k] == 2 && run <= 12.0 && ((k > 0 && j < flag.size()) || at_mouth)) { if (!at_mouth) rep.walk_driveways++; }
					else {
						if (flag[k] == 1) { rep.walk_pts_no_ground += (int)(j - k); edge_none += (int)(j - k); }
						else { rep.walk_pts_on_road += (int)(j - k); edge_road += (int)(j - k); }
						if (edge_none + edge_road == (int)(j - k)) { first_bad[0] = pts[k * 3]; first_bad[1] = pts[k * 3 + 2]; }
					}
					k = j;
				}
				std::vector<float> simple;
				simplify(pts, simple);
				add_seg(cut[c].second, cut[c + 1].second, 0, zone, -1, -1, simple, hw_min);
				rep.walks++;
			}
		}
		if (edge_none + edge_road > 0) {
			say("PAVEMENT LINE OFF ITS PAVEMENT block %s (%s, %s): %d points with no ground, %d on the road (first at %.1f, %.1f)", b.id.c_str(), b.name.c_str(), b.section.c_str(), edge_none, edge_road,
					first_bad[0], first_bad[1]);
		}
		for (int end = 0; end < 2; end++) {
			if (xnode[end][0] < 0 || xnode[end][1] < 0) continue;
			const float ax = out.walk_node[(size_t)xnode[end][0] * 2], az = out.walk_node[(size_t)xnode[end][0] * 2 + 1];
			const float bx = out.walk_node[(size_t)xnode[end][1] * 2], bz = out.walk_node[(size_t)xnode[end][1] * 2 + 1];
			const double len = std::hypot(bx - ax, bz - az);
			const int np = std::max(2, (int)std::ceil(len / 1.0) + 1);
			std::vector<float> pts;
			float last_y = 0.0f; int painted = 0, on_road = 0;
			for (int k = 0; k < np; k++) {
				const float u = (float)k / (np - 1), px = ax + (bx - ax) * u, pz = az + (bz - az) * u;
				float y = last_y; int l = G_NONE;
				ground->query(px, pz, y, l);
				if (is_road(l)) on_road++;
				// paint: stripes, or two border lines 3 m apart: anything white within 1.8 m of the line, along the street
				const float cx = (bz - az) / (float)len, cz = -(bx - ax) / (float)len;
				for (float t = -1.8f; t <= 1.8f && painted == 0; t += 0.2f) if (ground->layer_at(px + cx * t, pz + cz * t) == G_PAINT_WHITE) painted++;
				last_y = y;
				pts.push_back(px); pts.push_back(y); pts.push_back(pz);
			}
			// which traffic it crosses: this leg's lanes. Their clock phase, as the lanes carry it (heads facing along x
			// run half a cycle late)
			const int n = (int)e.x.size();
			const double hx = end == 0 ? e.x[1] - e.x[0] : e.x[n - 1] - e.x[n - 2], hz = end == 0 ? e.z[1] - e.z[0] : e.z[n - 1] - e.z[n - 2];
			const int phase = e.ctl[end] == CTL_SIGNAL ? (std::fabs(hx) > std::fabs(hz) ? 1 : 0) : -1;
			add_seg(xnode[end][0], xnode[end][1], 1, 0, end == 0 ? e.na : e.nb, phase, pts, 1.4);
			rep.crossings++;
			if (e.ctl[end] == CTL_SIGNAL) rep.crossings_signal++;
			if (painted == 0) { rep.crossings_unpainted++; if (said++ < 14) say("CROSSING WITHOUT PAINT block %s end %s at (%.1f, %.1f)", b.id.c_str(), end == 0 ? "a" : "b", (ax + bx) * 0.5f, (az + bz) * 0.5f); }
		}
	}
}

// ---------------------------------------------------------------- parking stalls
// The stalls the pieces recorded (through the bake: [x, y, z, yaw, grade]). A stall beside a lane, in the parking
// lane, turned along the street, is a KERB stall: it is tied to the lane it lies beside and to its place along it, so
// the traffic knows it, and a car can pull into it and out of it. Every other stall is in a car park.
void Builder::emit_stalls() {
	const int ns = (int)stalls.size() / 6;
	for (int k = 0; k < ns; k++) {
		const float *st = &stalls[(size_t)k * 6];
		const double x = st[0], z = st[2];
		const double yaw = st[3] * 3.14159265358979 / 180.0;
		// the nearest centre line point of any street
		int be = -1, bi = -1; double bd = 30.0 * 30.0;
		for (size_t ei = 0; ei < edges.size(); ei++) {
			const Edge &e = edges[ei];
			for (size_t i = 0; i < e.x.size(); i++) {
				const double d = (e.x[i] - x) * (e.x[i] - x) + (e.z[i] - z) * (e.z[i] - z);
				if (d < bd) { bd = d; be = (int)ei; bi = (int)i; }
			}
		}
		int kind = 1, lane = -1; double s_lane = 0.0, out_yaw = yaw;
		if (be >= 0) {
			const Edge &e = edges[be];
			const int n = (int)e.x.size(), i0 = std::max(bi - 1, 0), i1 = std::min(bi + 1, n - 1);
			double tx = e.x[i1] - e.x[i0], tz = e.z[i1] - e.z[i0];
			const double tl = std::hypot(tx, tz);
			tx /= tl; tz /= tl;
			const double along = (x - e.x[bi]) * tx + (z - e.z[bi]) * tz, across = (x - e.x[bi]) * tz - (z - e.z[bi]) * tx;   // + = left of a -> b
			const int sd = across > 0.0 ? 1 : 0;
			const double kerb = e.at[sd][bi].ok ? e.at[sd][bi].k : e.med[sd].k;
			const double s = e.s[bi] + along;
			// turned along the street? (either way round)
			const double rel = std::fabs(std::remainder(yaw - std::atan2(tx, tz), 3.14159265358979));
			const int d = sd == 0 ? 0 : 1;
			if (e.nl[d] > 0 && std::fabs(across) < kerb - 0.1 && std::fabs(across) > kerb - 2.7 && rel < 0.35 && s > e.trim[0] + 1.0 && s < e.len - e.trim[1] - 1.0) {
				kind = 0;
				lane = e.first_lane[d] + e.nl[d] - 1;   // the outermost lane of the direction that drives on this side
				s_lane = d == 0 ? s - e.trim[0] : (e.len - e.trim[1]) - s;
				out_yaw = d == 0 ? std::atan2(tx, tz) : std::atan2(-tx, -tz);   // parked the way the traffic beside it drives
			}
		}
		float y = st[1]; int l = G_NONE;
		if (!ground->query((float)x, (float)z, y, l)) rep.stalls_no_ground++;
		else if (kind == 0 && !is_road(l)) rep.stalls_kerb_off_road++;
		if (kind == 0) rep.stalls_kerb++; else rep.stalls_park++;
		const int cell = (int)st[5];
		// the car's pitch there: from the ground 1.8 m ahead of and behind its middle, along the way it stands
		float pitch = 0.0f;
		{
			const float hx = (float)std::sin(out_yaw), hz = (float)std::cos(out_yaw);
			float ya = y, yb = y; int la = G_NONE, lb = G_NONE;
			if (ground->query((float)x + hx * 1.8f, (float)z + hz * 1.8f, ya, la) && ground->query((float)x - hx * 1.8f, (float)z - hz * 1.8f, yb, lb)) pitch = std::atan2(ya - yb, 3.6f);
		}
		const float f[8] = { (float)x, y, (float)z, (float)out_yaw, pitch, 2.4f, 1.0f, (float)s_lane };
		const int32_t ia[4] = { kind, lane, cell >= 0 && (size_t)cell * 2 + 1 < cell_xz.size() ? cell_xz[(size_t)cell * 2] : 0, cell >= 0 && (size_t)cell * 2 + 1 < cell_xz.size() ? cell_xz[(size_t)cell * 2 + 1] : 0 };
		out.stall_f.insert(out.stall_f.end(), f, f + 8);
		out.stall_i.insert(out.stall_i.end(), ia, ia + 4);
	}
}

void Builder::build() {
	rep = Report();
	out = StreetData();
	make_edges();
	measure_edges();
	classify_edges();
	split_edges();
	layout_lanes();
	junctions();
	emit_lanes();
	check_paths();
	emit_walks();
	emit_stalls();
	double lane_m = 0.0;
	for (int i = 0; i < out.lanes(); i++) {
		for (int k = out.lane_off[i]; k + 1 < out.lane_off[i + 1]; k++) {
			lane_m += std::hypot(out.lane_pts[k * 3 + 3] - out.lane_pts[k * 3], out.lane_pts[k * 3 + 5] - out.lane_pts[k * 3 + 2]);
		}
	}
	say("TOTAL edges %d, nodes %d, lanes %d (%.1f km, %d points kept of %d checked), connections %d", (int)edges.size(), (int)nodes.size(), out.lanes(), lane_m / 1000.0,
			(int)out.lane_pts.size() / 3, rep.lane_pts, out.connections());
	say("CHECK lane points off the asphalt %d, without ground %d (both must be 0)", rep.lane_pts_off_road, rep.lane_pts_no_ground);
	say("CHECK paths through the junctions: %d (%d take a wider curve to keep off a kerb), %d points checked as wide as a car: %d touch a kerb, on %d paths (must be 0)", out.connections(), rep.paths_widened,
			rep.path_pts, rep.path_pts_off_road, rep.paths_off_road);
	say("CHECK a steered car driven along every path (the traffic's own body, the longest car): %d places, its body off the asphalt in %d, on %d paths (must be 0) | its middle strays from the path by at most %.2f m",
			rep.body_pts, rep.body_pts_off_road, rep.body_paths_off_road, rep.body_miss_max);
	say("CHECK lane points where a car's side would be off the asphalt: %d (must be 0)", rep.lane_pts_tight);
	say("CHECK steepest lane %.1f %%, largest height kink at a lane point %.3f m", rep.worst_grade * 100.0, rep.worst_kink);
	say("CHECK junctions (3 legs and more): %d with signals, %d with stop bars, %d with neither | approaches %d: %d signal, %d stop, %d free", rep.nodes_signal, rep.nodes_stop, rep.nodes_free,
			rep.approaches, rep.approaches_signal, rep.approaches_stop, rep.approaches - rep.approaches_signal - rep.approaches_stop);
	double walk_m = 0.0;
	for (size_t k = 0; k + 1 < out.walk_seg_f.size(); k += 2) if (out.walk_seg[k * 4 + 2] == 0) walk_m += out.walk_seg_f[k];
	say("TOTAL pavements %d stretches (%.1f km), %d walk points, %d crossings (%d at signals), parking stalls %d at the kerb, %d in car parks", rep.walks, walk_m / 1000.0, (int)out.walk_node.size() / 2,
			rep.crossings, rep.crossings_signal, rep.stalls_kerb, rep.stalls_park);
	say("CHECK pavement points on the road %d, without ground %d (both must be 0) of %d | driveways and alley mouths walked over %d | crossings with no paint under them %d", rep.walk_pts_on_road,
			rep.walk_pts_no_ground, rep.walk_pts, rep.walk_driveways, rep.crossings_unpainted);
	say("CHECK pavement corners with no ground under them (holes in the map, listed above): %d", rep.corners_no_ground);
	say("CHECK kerb stalls not on the asphalt %d, stalls without ground %d (both must be 0)", rep.stalls_kerb_off_road, rep.stalls_no_ground);
	say("CHECK signal heads in another clock tile than their junction %d (must be 0), heads with no junction within 45 m %d of %d", rep.heads_other_tile, rep.heads_no_junction, (int)signals.size() / 3);
	say("TOTAL places where a street changes its lanes mid-block %d, left-turn lanes before signals %d", rep.lane_changes, rep.pockets);
	say("CHECK approaches with no way on %d, blocks too short for their junctions %d, points of an unknown street kind %d", rep.legs_unconnected, rep.short_edges, rep.generic_stations);
}

// ---------------------------------------------------------------- streets.bin
namespace {
const char MAGIC[8] = { 'C', 'K', 'S', 'T', 'R', '0', '0', '1' };

template <class T>
void put(std::vector<uint8_t> &o, const std::vector<T> &v) {
	const uint32_t n = (uint32_t)v.size();
	const size_t at = o.size();
	o.resize(at + 4 + (size_t)n * sizeof(T));
	std::memcpy(o.data() + at, &n, 4);
	if (n) std::memcpy(o.data() + at + 4, v.data(), (size_t)n * sizeof(T));
}

template <class T>
bool get(const uint8_t *d, size_t size, size_t &at, std::vector<T> &v) {
	if (at + 4 > size) return false;
	uint32_t n;
	std::memcpy(&n, d + at, 4);
	at += 4;
	if (at + (size_t)n * sizeof(T) > size) return false;
	v.resize(n);
	if (n) std::memcpy(v.data(), d + at, (size_t)n * sizeof(T));
	at += (size_t)n * sizeof(T);
	return true;
}
} // namespace

void StreetData::save(std::vector<uint8_t> &o) const {
	o.assign(MAGIC, MAGIC + 8);
	put(o, lane_pts); put(o, lane_off); put(o, lane_f); put(o, lane_i); put(o, conns);
	put(o, node_f); put(o, node_i);
	put(o, walk_node); put(o, walk_seg); put(o, walk_seg_f); put(o, walk_pts);
	put(o, stall_f); put(o, stall_i);
	put(o, sig_grid);
}

bool StreetData::load(const uint8_t *d, size_t size) {
	if (size < 8 || std::memcmp(d, MAGIC, 8) != 0) return false;
	size_t at = 8;
	return get(d, size, at, lane_pts) && get(d, size, at, lane_off) && get(d, size, at, lane_f) && get(d, size, at, lane_i) && get(d, size, at, conns) &&
			get(d, size, at, node_f) && get(d, size, at, node_i) &&
			get(d, size, at, walk_node) && get(d, size, at, walk_seg) && get(d, size, at, walk_seg_f) && get(d, size, at, walk_pts) &&
			get(d, size, at, stall_f) && get(d, size, at, stall_i) && get(d, size, at, sig_grid) && sig_grid.size() == 3;
}

} // namespace sg
