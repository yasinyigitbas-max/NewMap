// WayFloor: a thin collision floor under every road and pavement, 3 cm below the drawn surface, made and dropped in
// 100 m blocks round the camera (Yasin, 19 Nov: "fix all of them" - the holes in the city's collision on the ways:
// 89 found by tools/city/audit/collision_holes.gd, most on the seams between cells, and a 4 m one at a downtown corner).
// Where the city's own collision is whole it is met first and nothing changes; where it has a gap, a person, a car or a
// thrown body stands 3 cm lower instead of falling through. Fed by CityTraffic (lanes and junction paths) and CityCrowd
// (pavements and crossings) once; it touches no locked piece and no bake.
#pragma once

#include <godot_cpp/classes/physics_server3d.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/rid.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>
#include <unordered_map>
#include <vector>

namespace godot {

class WayFloor {
	struct Strip { float x0, y0, z0, x1, y1, z1, hw; };
	std::vector<Strip> strips;
	std::unordered_map<long long, std::vector<int>> by_block;   // block -> strips through it
	struct Built { RID body, shape; };
	std::unordered_map<long long, Built> built;
	static constexpr float BLOCK = 100.0f, NEAR = 170.0f, FAR = 260.0f, DROP = 0.03f;
	static long long key(int bx, int bz) { return ((long long)bx << 32) ^ (unsigned int)bz; }
	bool indexed = false;

public:
	int blocks_built = 0;
	void add(const Vector3 &a, const Vector3 &b, float hw) { strips.push_back(Strip{ a.x, a.y, a.z, b.x, b.y, b.z, hw }); indexed = false; }
	size_t size() const { return strips.size(); }
	int live() const { return (int)built.size(); }

	void index() {
		by_block.clear();
		for (int i = 0; i < (int)strips.size(); i++) {
			const Strip &s = strips[i];
			const float lo_x = std::fmin(s.x0, s.x1) - s.hw, hi_x = std::fmax(s.x0, s.x1) + s.hw;
			const float lo_z = std::fmin(s.z0, s.z1) - s.hw, hi_z = std::fmax(s.z0, s.z1) + s.hw;
			for (int bx = (int)std::floor(lo_x / BLOCK); bx <= (int)std::floor(hi_x / BLOCK); bx++)
				for (int bz = (int)std::floor(lo_z / BLOCK); bz <= (int)std::floor(hi_z / BLOCK); bz++) by_block[key(bx, bz)].push_back(i);
		}
		indexed = true;
	}

	// blocks within NEAR of p are made, those beyond FAR dropped (a few a call, so a teleport spreads over frames)
	void update(const Vector3 &p, const RID &space) {
		if (!space.is_valid() || strips.empty()) return;
		if (!indexed) index();
		PhysicsServer3D *ps = PhysicsServer3D::get_singleton();
		for (auto it = built.begin(); it != built.end();) {
			const int bx = (int)(it->first >> 32), bz = (int)(int32_t)(it->first & 0xffffffff);
			const float cx = ((float)bx + 0.5f) * BLOCK - p.x, cz = ((float)bz + 0.5f) * BLOCK - p.z;
			if (cx * cx + cz * cz > FAR * FAR) {   // (an empty block has no body: Jolt reports a free of nothing - B27, 20 Nov: 28 errors a run from the traffic's and the crowd's floors each)
				if (it->second.body.is_valid()) ps->free_rid(it->second.body);
				if (it->second.shape.is_valid()) ps->free_rid(it->second.shape);
				it = built.erase(it);
			} else ++it;
		}
		int made = 0;
		const int r = (int)std::ceil(NEAR / BLOCK);
		const int px = (int)std::floor(p.x / BLOCK), pz = (int)std::floor(p.z / BLOCK);
		for (int dz = -r; dz <= r && made < 3; dz++) {
			for (int dx = -r; dx <= r && made < 3; dx++) {
				const int bx = px + dx, bz = pz + dz;
				const float cx = ((float)bx + 0.5f) * BLOCK - p.x, cz = ((float)bz + 0.5f) * BLOCK - p.z;
				if (cx * cx + cz * cz > (NEAR + BLOCK * 0.71f) * (NEAR + BLOCK * 0.71f)) continue;
				const long long k = key(bx, bz);
				if (built.count(k)) continue;
				auto f = by_block.find(k);
				if (f == by_block.end()) { built[k] = Built{}; continue; }   // (no way through it: nothing to make)
				PackedVector3Array faces;
				for (int i : f->second) {
					const Strip &s = strips[i];
					float dxs = s.x1 - s.x0, dzs = s.z1 - s.z0;
					const float len = std::sqrt(dxs * dxs + dzs * dzs);
					if (len < 1e-3f) continue;
					dxs /= len; dzs /= len;
					const float ox = -dzs * s.hw, oz = dxs * s.hw, ex = dxs * 0.3f, ez = dzs * 0.3f;   // (each strip 0.3 m longer at both ends: no seam of its own)
					const Vector3 a(s.x0 - ex + ox, s.y0 - DROP, s.z0 - ez + oz), b(s.x0 - ex - ox, s.y0 - DROP, s.z0 - ez - oz);
					const Vector3 c(s.x1 + ex - ox, s.y1 - DROP, s.z1 + ez - oz), d(s.x1 + ex + ox, s.y1 - DROP, s.z1 + ez + oz);
					faces.push_back(a); faces.push_back(b); faces.push_back(c);
					faces.push_back(a); faces.push_back(c); faces.push_back(d);
				}
				Built bl;
				if (!faces.is_empty()) {
					bl.shape = ps->concave_polygon_shape_create();
					Dictionary data; data["faces"] = faces; data["backface_collision"] = true;
					ps->shape_set_data(bl.shape, data);
					bl.body = ps->body_create();
					ps->body_set_mode(bl.body, PhysicsServer3D::BODY_MODE_STATIC);
					ps->body_add_shape(bl.body, bl.shape);
					ps->body_set_collision_layer(bl.body, 1);
					ps->body_set_collision_mask(bl.body, 0);
					ps->body_set_space(bl.body, space);
					blocks_built++;
				}
				built[k] = bl;
				made++;
			}
		}
	}

	void clear() {
		PhysicsServer3D *ps = PhysicsServer3D::get_singleton();
		for (auto &kv : built) { if (kv.second.body.is_valid()) ps->free_rid(kv.second.body); if (kv.second.shape.is_valid()) ps->free_rid(kv.second.shape); }
		built.clear();
	}
};

} // namespace godot
