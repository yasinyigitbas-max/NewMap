// Microbenchmark for the fast rays (docs/FAST_RAYS.md). Test-only: never part of the game. It times the traversal's own
// helpers from native/traversal/src/trav_probe.h on one physics space, from C++ (as the game calls them):
//   old    trav::ray_from     one intersect_ray each (query object reused, a Dictionary back), reading position + normal
//   hit1   trav::hit_from     one ray per engine call through intersect_rays (or the old way on a stock engine)
//   hitN   trav::rays_from    N rays per engine call (N = 2, 3: what the game batches; and 64, 1024)
// and checks that every way hit the same points and normals, bit for bit.
#include <chrono>
#include <cstring>
#include <vector>
#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include "trav_probe.h"

using namespace godot;

class RayBench : public CharacterBody3D {
	GDCLASS(RayBench, CharacterBody3D);

protected:
	static void _bind_methods() {
		ClassDB::bind_method(D_METHOD("run", "rays", "spread"), &RayBench::run);
		ClassDB::bind_method(D_METHOD("fast"), &RayBench::fast);
	}

public:
	bool fast() { return trav::fast_rays(); }
	Dictionary run(int n, double spread) {
		std::vector<Vector3> pr(2 * n);
		uint32_t s = 12345u;
		auto rnd = [&s]() { s = s * 1664525u + 1013904223u; return (double)(s >> 8) / 16777216.0; };
		for (int i = 0; i < n; i++) {
			const double x = (rnd() - 0.5) * spread, z = (rnd() - 0.5) * spread;
			pr[2 * i] = Vector3((real_t)x, 3.0f, (real_t)z);
			pr[2 * i + 1] = Vector3((real_t)(x + (rnd() - 0.5)), -1.0f, (real_t)(z + (rnd() - 0.5)));
		}
		std::vector<trav::Hit> ref(n), got(n);
		Dictionary out;
		using clk = std::chrono::steady_clock;
		auto us = [](clk::time_point a, clk::time_point b) { return std::chrono::duration<double, std::micro>(b - a).count(); };
		// old way
		auto t0 = clk::now();
		for (int i = 0; i < n; i++) {
			const Dictionary d = trav::ray_from(this, pr[2 * i], pr[2 * i + 1], __FILE__, __LINE__);
			ref[i] = trav::Hit();
			if (!d.is_empty()) {
				ref[i].hit = true;
				ref[i].position = d["position"];
				ref[i].normal = d["normal"];
			}
		}
		auto t1 = clk::now();
		out["old_us_per_ray"] = us(t0, t1) / n;
		int hits = 0;
		for (int i = 0; i < n; i++) {
			hits += ref[i].hit ? 1 : 0;
		}
		out["hits"] = hits;
		const int sizes[5] = { 1, 2, 3, 64, 1024 };
		bool same = true;
		for (int k = 0; k < 5; k++) {
			const int m = sizes[k];
			auto a = clk::now();
			for (int i = 0; i < n; i += m) {
				const int c = (i + m <= n) ? m : n - i;
				trav::rays_from(this, &pr[2 * i], c, &got[i], __FILE__, __LINE__);
			}
			auto b = clk::now();
			out[vformat("batch%d_us_per_ray", m)] = us(a, b) / n;
			for (int i = 0; i < n; i++) {
				const trav::Hit &p = ref[i], &q = got[i];
				if (p.hit != q.hit || (p.hit && (std::memcmp(&p.position, &q.position, sizeof(Vector3)) != 0 || std::memcmp(&p.normal, &q.normal, sizeof(Vector3)) != 0))) {
					same = false;
				}
			}
		}
		out["identical"] = same;
		out["fast_rays"] = trav::fast_rays();
		return out;
	}
};

static void init(ModuleInitializationLevel l) {
	if (l == MODULE_INITIALIZATION_LEVEL_SCENE) {
		GDREGISTER_CLASS(RayBench);
	}
}
static void term(ModuleInitializationLevel l) {}
extern "C" GDExtensionBool GDE_EXPORT bench_rays_init(GDExtensionInterfaceGetProcAddress a, const GDExtensionClassLibraryPtr l, GDExtensionInitialization *r) {
	GDExtensionBinding::InitObject o(a, l, r);
	o.register_initializer(init);
	o.register_terminator(term);
	o.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
	return o.init();
}
