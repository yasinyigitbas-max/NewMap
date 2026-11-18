// The baked ground as the street tool sees it: every ground triangle of every baked cell with its surface kind
// (the layer of the bake's ground texture array), in a grid for point queries. Tool time only (StreetGraph::build);
// nothing of this is in the game. Plain C++.
#pragma once

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <vector>

namespace sg {

// tools/city/bake/make_arrays.py 'ground': the order of the ground texture array
enum { G_ASPHALT = 0, G_CONCRETE = 1, G_GRASS = 2, G_DRY = 3, G_TRAVERTINE = 4, G_PAINT_WHITE = 5, G_PAINT_YELLOW = 6, G_GRAVEL = 7, G_SAND = 8, G_OTHER = 9, G_NONE = -1 };

inline bool is_road(int layer) { return layer == G_ASPHALT || layer == G_PAINT_WHITE || layer == G_PAINT_YELLOW; }

struct Ground {
	std::vector<float> tri;      // 9 per triangle: ax, ay, az, bx, by, bz, cx, cy, cz
	std::vector<int8_t> layer;   // per triangle
	float cell = 4.0f;
	float x0 = 0, z0 = 0;
	int gw = 0, gh = 0;
	std::vector<int32_t> off, idx;   // CSR: cell -> triangles

	void add(const float *a, const float *b, const float *c, int p_layer) {
		// a triangle that stands on its edge (a kerb face) has no area from above: it answers no point query
		const float area = (b[0] - a[0]) * (c[2] - a[2]) - (b[2] - a[2]) * (c[0] - a[0]);
		if (std::fabs(area) < 1.0e-5f) return;
		for (int k = 0; k < 3; k++) { tri.push_back(a[k]); }
		for (int k = 0; k < 3; k++) { tri.push_back(b[k]); }
		for (int k = 0; k < 3; k++) { tri.push_back(c[k]); }
		layer.push_back((int8_t)p_layer);
	}
	int count() const { return (int)layer.size(); }

	void build() {
		const int n = count();
		float x1 = -1e9f, z1 = -1e9f;
		x0 = 1e9f; z0 = 1e9f;
		for (int i = 0; i < n; i++) {
			for (int k = 0; k < 3; k++) {
				const float x = tri[i * 9 + k * 3], z = tri[i * 9 + k * 3 + 2];
				if (x < x0) x0 = x;
				if (x > x1) x1 = x;
				if (z < z0) z0 = z;
				if (z > z1) z1 = z;
			}
		}
		if (n == 0) { x0 = z0 = 0; x1 = z1 = 1; }
		gw = (int)((x1 - x0) / cell) + 1; gh = (int)((z1 - z0) / cell) + 1;
		std::vector<int32_t> cnt((size_t)gw * gh + 1, 0);
		auto each = [&](bool fill) {
			for (int i = 0; i < n; i++) {
				const float *t = &tri[(size_t)i * 9];
				const float ax = std::fmin(t[0], std::fmin(t[3], t[6])), bx = std::fmax(t[0], std::fmax(t[3], t[6]));
				const float az = std::fmin(t[2], std::fmin(t[5], t[8])), bz = std::fmax(t[2], std::fmax(t[5], t[8]));
				const int cx0 = (int)((ax - x0) / cell), cx1 = (int)((bx - x0) / cell), cz0 = (int)((az - z0) / cell), cz1 = (int)((bz - z0) / cell);
				for (int cz = cz0; cz <= cz1; cz++) {
					for (int cx = cx0; cx <= cx1; cx++) {
						const int c = cz * gw + cx;
						if (!fill) cnt[c]++;
						else idx[off[c] + cnt[c]++] = i;
					}
				}
			}
		};
		each(false);
		off.assign((size_t)gw * gh + 1, 0);
		for (int c = 0; c < gw * gh; c++) off[c + 1] = off[c] + cnt[c];
		idx.assign(off[(size_t)gw * gh], 0);
		std::fill(cnt.begin(), cnt.end(), 0);
		each(true);
	}

	// The surface at (x, z): the highest one (a road on a bridge is over the ground below it). false = no ground there.
	bool query(float x, float z, float &r_y, int &r_layer) const {
		const int cx = (int)std::floor((x - x0) / cell), cz = (int)std::floor((z - z0) / cell);
		if (cx < 0 || cz < 0 || cx >= gw || cz >= gh) return false;
		const int c = cz * gw + cx;
		bool hit = false;
		float best = -1e9f;
		for (int k = off[c]; k < off[c + 1]; k++) {
			const int i = idx[k];
			const float *t = &tri[(size_t)i * 9];
			const float v0x = t[3] - t[0], v0z = t[5] - t[2], v1x = t[6] - t[0], v1z = t[8] - t[2], px = x - t[0], pz = z - t[2];
			const float den = v0x * v1z - v1x * v0z;
			if (std::fabs(den) < 1.0e-9f) continue;
			const float u = (px * v1z - v1x * pz) / den, w = (v0x * pz - px * v0z) / den;
			if (u < -1.0e-4f || w < -1.0e-4f || u + w > 1.0001f) continue;
			const float y = t[1] + (t[4] - t[1]) * u + (t[7] - t[1]) * w;
			if (y > best) { best = y; r_layer = layer[i]; hit = true; }
		}
		if (hit) r_y = best;
		return hit;
	}
	int layer_at(float x, float z) const {
		float y; int l = G_NONE;
		return query(x, z, y, l) ? l : G_NONE;
	}
};

} // namespace sg
