// The street builder: see street_build.h
#include "street_build.h"

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

// Which kind of street each side is at every point of the centre line, and from that the lanes: how many per direction
// and how far from the centre line, point by point (a block whose two halves were built by different pieces changes
// its section on the way; the lanes follow it over a 20 m taper).
void Builder::layout_lanes() {
	static const double VMAX[T_COUNT] = { 11.1, 11.1, 11.1, 11.1, 15.3, 13.9, 13.9, 19.4, 11.1 };   // 40 / 55 / 50 / 70 km/h
	for (Edge &e : edges) {
		const int n = (int)e.x.size();
		const SkBlock &b = blocks[e.block];
		int mode_all[2] = { T_NONE, T_NONE };
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
			for (int i = 0; i < n; i++) {
				int cnt[T_COUNT] = { 0 };
				for (int j = std::max(0, i - 4); j <= std::min(n - 1, i + 4); j++) cnt[t[j]]++;
				int best = t[i];
				for (int k = 0; k < T_COUNT; k++) if (cnt[k] > cnt[best]) best = k;
				f[i] = (uint8_t)best;
			}
			e.tm[sd] = f;
			int cnt[T_COUNT] = { 0 };
			for (int i = 0; i < n; i++) cnt[f[i]]++;
			int best = f[0];
			for (int k = 0; k < T_COUNT; k++) if (cnt[k] > cnt[best]) best = k;
			mode_all[sd] = best;
			if (!e.oneway) rep.generic_stations += cnt[T_GENERIC];
			if (cnt[T_GENERIC] > 0 && !e.oneway) say("KIND UNKNOWN block %s (%s) side %d: %d of %d points (typical there: carriageway from %.2f to %.2f m)", b.id.c_str(), b.name.c_str(), sd, cnt[T_GENERIC], n, e.med[sd].m, e.med[sd].k);
		}
		for (int d = 0; d < 2; d++) {
			if (e.oneway && d == 1) { e.nl[1] = 0; continue; }
			// lanes: as many as the narrowest stretch of the block has
			int nl = 2;
			double hw = 9.0;
			for (int i = 0; i < n; i++) { nl = std::min(nl, TMPL[e.tm[d][i]].n); hw = std::min(hw, TMPL[e.tm[d][i]].hw); }
			if (e.oneway) nl = 1;
			e.nl[d] = nl; e.lhw[d] = hw;
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
				e.off[d][j] = sm;
			}
			if (e.oneway) e.lhw[0] = std::min(2.0, std::max(1.5, (e.med[0].k + e.med[1].k) * 0.5 - 0.9));
		}
		// speed, how busy, and its rank at junctions: from the kind of street most of the block is
		const int kind = mode_all[0] != T_NONE ? mode_all[0] : mode_all[1];
		e.vmax = VMAX[kind];
		const bool busy = b.section == "hs" || b.section == "cc" || b.section == "strip";
		switch (kind) {
			case T_ART: e.dens = 0.016; e.cls = 4; break;
			case T_BLVD: case T_BLVD_PARK: e.dens = 0.016; e.cls = 5; break;
			case T_BRIDGE: e.dens = 0.018; e.cls = 5; break;
			case T_TRUCK: e.dens = 0.006; e.cls = 2; break;
			default: e.dens = busy ? 0.012 : (b.section == "std" ? 0.007 : 0.004); e.cls = busy ? 3 : (b.section == "std" ? 2 : 1); break;
		}
		if (e.oneway) { e.dens = 0.012; e.cls = 3; }
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
	for (size_t k = 0; k + 2 < signals.size(); k += 3) {
		int best = -1; double bd = 45.0;
		for (int i = 0; i < nn; i++) {
			const double d = std::hypot(nodes[i].x - signals[k], nodes[i].z - signals[k + 2]);
			if (d < bd) { bd = d; best = i; }
		}
		if (best >= 0) heads[best]++;
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
					const double o0 = lane_off_at(e, din, 0, s_of(d)) - e.lhw[din] * 0.7, o1 = lane_off_at(e, din, e.nl[din] - 1, s_of(d)) + e.lhw[din] * 0.7;
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
		out.node_i[(size_t)ni * 4 + 2] = (int)std::floor((nodes[ni].x + 100.0) / 200.0); out.node_i[(size_t)ni * 4 + 3] = (int)std::floor((nodes[ni].z + 100.0) / 200.0);
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
				const int32_t ia[12] = { (int32_t)ei, d, j, j > 0 ? id - 1 : -1, j + 1 < e.nl[d] ? id + 1 : -1, n_start, n_end, e.cls, 1, ctl, n_end, phase };
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
				if (turn == TURN_STRAIGHT && eo.oneway && nodes[ni].diverge) add(n_in - 1, 0);   // a ramp is left from the outer lane
				else if (turn == TURN_STRAIGHT) { for (int a = 0; a < n_in; a++) add(a, std::min(a, n_out - 1)); }
				else if (turn == TURN_LEFT) add(0, 0);
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
	for (int c = 0; c < nc; c++) {
		int best = 40, best_bad = 1 << 30;
		for (int k = 0; k < 7 && best_bad > 0; k++) {
			out.conns[(size_t)c * StreetData::CONN + 4] = REACH[k];
			pts.clear();
			out.path(c, pts);
			const int bad = count_bad();
			if (bad < best_bad) { best_bad = bad; best = REACH[k]; }
		}
		out.conns[(size_t)c * StreetData::CONN + 4] = best;
		pts.clear();
		out.path(c, pts);
		rep.path_pts += (int)pts.size() / 3;
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

void Builder::build() {
	rep = Report();
	out = StreetData();
	make_edges();
	measure_edges();
	layout_lanes();
	junctions();
	emit_lanes();
	check_paths();
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
	say("CHECK lane points where a car's side would be off the asphalt: %d (must be 0)", rep.lane_pts_tight);
	say("CHECK steepest lane %.1f %%, largest height kink at a lane point %.3f m", rep.worst_grade * 100.0, rep.worst_kink);
	say("CHECK junctions (3 legs and more): %d with signals, %d with stop bars, %d with neither | approaches %d: %d signal, %d stop, %d free", rep.nodes_signal, rep.nodes_stop, rep.nodes_free,
			rep.approaches, rep.approaches_signal, rep.approaches_stop, rep.approaches - rep.approaches_signal - rep.approaches_stop);
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
}

bool StreetData::load(const uint8_t *d, size_t size) {
	if (size < 8 || std::memcmp(d, MAGIC, 8) != 0) return false;
	size_t at = 8;
	return get(d, size, at, lane_pts) && get(d, size, at, lane_off) && get(d, size, at, lane_f) && get(d, size, at, lane_i) && get(d, size, at, conns) &&
			get(d, size, at, node_f) && get(d, size, at, node_i) &&
			get(d, size, at, walk_node) && get(d, size, at, walk_seg) && get(d, size, at, walk_seg_f) && get(d, size, at, walk_pts) &&
			get(d, size, at, stall_f) && get(d, size, at, stall_i);
}

} // namespace sg
