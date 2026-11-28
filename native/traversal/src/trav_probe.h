// What the traversal's rays and shape tests look at (27 Nov, the game's world contract, docs/damage/WORLD_CONTRACT.md:
// "Traversal and locomotion probes ... use mask" the world, not people). A body may carry the meta "probe_mask": then
// every probe (ground, step, wall, ledge, room to stand, feet, hands) uses it and only the capsule's own moving uses
// the body's collision mask. Without the meta (the lab, the tests) a probe uses the body's mask, as before.
#pragma once
#include <godot_cpp/classes/class_db_singleton.hpp>
#include <godot_cpp/classes/collision_object3d.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/engine_ptrcall.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace trav {
inline uint32_t probe_mask(godot::CollisionObject3D *b) {
	static const godot::StringName K("probe_mask");
	return b->has_meta(K) ? (uint32_t)(int64_t)b->get_meta(K) : b->get_collision_mask();
}
// The physics space for a query, or null. On the phone physics runs on its own thread (Jolt, project.godot) and the
// space can be read only inside the physics step: anywhere else the engine hands back null. (28 Nov: the first phone
// build crashed at the start of a new game on such a null.) A caller must take null as "nothing known": TRAV_RAY gives
// an empty hit. The first few misses are printed with their place in the code, so the caller can be moved into the step.
inline godot::PhysicsDirectSpaceState3D *space_at(godot::Node3D *n, const char *file, int line) {
	godot::PhysicsDirectSpaceState3D *s = nullptr;
	if (n && n->is_inside_tree()) {
		godot::Ref<godot::World3D> w = n->get_world_3d();
		if (w.is_valid()) s = w->get_direct_space_state();
	}
	if (!s) {
		static int said = 0;
		if (said < 8) { said++; godot::UtilityFunctions::print("TRAV no physics space outside the physics step: ", file, ":", line); }
	}
	return s;
}
inline godot::Dictionary ray_at(godot::Node3D *n, const godot::Ref<godot::PhysicsRayQueryParameters3D> &q, const char *file, int line) {
	godot::PhysicsDirectSpaceState3D *s = space_at(n, file, line);
	return s ? s->intersect_ray(q) : godot::Dictionary();
}
// A ray from a body that leaves the body itself out, on the world's probe mask: the same query as
// PhysicsRayQueryParameters3D::create(from, to, probe_mask(b), [b's RID]) (the same defaults: bodies, no areas, back
// faces hit, not from inside), but one query object per thread is reused instead of a new one made and freed for every
// ray (28 Nov night: the bodies cast hundreds of rays a frame on the phone; each new query was an object, an array and
// four calls into the engine). The object is never freed (it must outlive the engine's teardown of the thread).
inline godot::Dictionary ray_from(godot::CollisionObject3D *b, const godot::Vector3 &from, const godot::Vector3 &to, const char *file, int line) {
	thread_local godot::Ref<godot::PhysicsRayQueryParameters3D> *q = nullptr;
	thread_local uint64_t ex_id = 0;
	if (q == nullptr) {
		q = new godot::Ref<godot::PhysicsRayQueryParameters3D>();
		q->instantiate();
	}
	const godot::RID r = b->get_rid();
	if (r.get_id() != ex_id) {
		godot::TypedArray<godot::RID> ex;
		ex.push_back(r);
		(*q)->set_exclude(ex);
		ex_id = r.get_id();
	}
	(*q)->set_from(from);
	(*q)->set_to(to);
	(*q)->set_collision_mask(probe_mask(b));
	return ray_at(b, *q, file, line);
}

// ---- Fast rays (28 Nov, docs/FAST_RAYS.md; performance only, the same hits) ----
// What a ray from a body hit: the two values the traversal reads from intersect_ray's Dictionary ("position",
// "normal"), held as plain values. is_empty() is the Dictionary's is_empty(): true when the ray hit nothing.
struct Hit {
	bool hit = false;
	godot::Vector3 position;
	godot::Vector3 normal;
	bool is_empty() const { return !hit; }
};
// Coronado's engine build (coronado-source engine/patches/p_fast_rays.patch) has
// PhysicsDirectSpaceState3D.intersect_rays(rays, collision_mask, exclude, bodies, areas, back_faces, from_inside):
// every from, to pair is the same query as intersect_ray, run through the same intersect_ray of the physics server,
// and the result is 8 floats a ray (hit, position xyz, normal xyz, shape) instead of a Dictionary a ray. Asked once per
// process; a stock engine has no such method and every ray goes the old way (ray_from), one query at a time.
// RAYS_HASH is the method's hash in the patched engine's extension_api.json (godot --dump-extension-api).
static constexpr int64_t RAYS_HASH = 776707625;
static constexpr int RAYS_STRIDE = 8;
inline GDExtensionMethodBindPtr rays_bind() {
	static const GDExtensionMethodBindPtr mb = []() -> GDExtensionMethodBindPtr {
#ifdef REAL_T_IS_DOUBLE
		return nullptr; // (the result is 32-bit floats: with 64-bit vectors the old way is the exact one)
#else
		const godot::StringName cls("PhysicsDirectSpaceState3D");
		const godot::StringName m("intersect_rays");
		godot::ClassDBSingleton *db = godot::ClassDBSingleton::get_singleton();
		GDExtensionMethodBindPtr p = nullptr;
		if (db != nullptr && db->class_has_method(cls, m, true)) {
			p = godot::internal::gdextension_interface_classdb_get_method_bind(cls._native_ptr(), m._native_ptr(), RAYS_HASH);
		}
		// (one line in the log, to check in an A/B run which way the rays went)
		godot::UtilityFunctions::print(p ? "TRAV fast rays: on (intersect_rays)" : "TRAV fast rays: off (intersect_ray, one ray at a time)");
		return p;
#endif
	}();
	return mb;
}
inline bool fast_rays() { return rays_bind() != nullptr; }
// n rays from a body, each the same query as ray_from(b, from, to) (the body left out, the probe mask, bodies, no
// areas, back faces hit, not from inside), in one call to the engine when it can: pairs[2 i] = from, pairs[2 i + 1] = to,
// out[i] = what ray i hit. The rays must not depend on each other's hits (none of them changes the world).
inline void rays_from(godot::CollisionObject3D *b, const godot::Vector3 *pairs, int n, Hit *out, const char *file, int line) {
	const GDExtensionMethodBindPtr mb = rays_bind();
	if (mb == nullptr) {
		for (int i = 0; i < n; i++) {
			const godot::Dictionary d = ray_from(b, pairs[2 * i], pairs[2 * i + 1], file, line);
			out[i] = Hit();
			if (!d.is_empty()) {
				out[i].hit = true;
				out[i].position = d["position"];
				out[i].normal = d["normal"];
			}
		}
		return;
	}
	for (int i = 0; i < n; i++) {
		out[i] = Hit();
	}
	godot::PhysicsDirectSpaceState3D *s = space_at(b, file, line);
	if (s == nullptr) {
		return; // (as ray_at: no space, nothing hit)
	}
	// one rays array and one exclude list per thread, reused (never freed, as ray_from's query)
	thread_local godot::PackedVector3Array *rays = nullptr;
	thread_local godot::TypedArray<godot::RID> *ex = nullptr;
	thread_local uint64_t ex_id = 0;
	if (rays == nullptr) {
		rays = new godot::PackedVector3Array();
		ex = new godot::TypedArray<godot::RID>();
	}
	const godot::RID r = b->get_rid();
	if (ex->is_empty() || (uint64_t)r.get_id() != ex_id) {
		ex->clear();
		ex->push_back(r);
		ex_id = r.get_id();
	}
	if (rays->size() != 2 * n) {
		rays->resize(2 * n);
	}
	godot::Vector3 *w = rays->ptrw();
	for (int i = 0; i < 2 * n; i++) {
		w[i] = pairs[i];
	}
	const int64_t mask = (int64_t)probe_mask(b);
	const int8_t bodies = 1, areas = 0, back_faces = 1, from_inside = 0;
	const godot::PackedFloat32Array res = godot::internal::_call_native_mb_ret<godot::PackedFloat32Array>(mb, s->_owner, rays, &mask, ex, &bodies, &areas, &back_faces, &from_inside);
	if (res.size() != n * RAYS_STRIDE) {
		return;
	}
	const float *f = res.ptr();
	for (int i = 0; i < n; i++) {
		const float *o = f + i * RAYS_STRIDE;
		if (o[0] != 0.0f) {
			out[i].hit = true;
			out[i].position = godot::Vector3(o[1], o[2], o[3]);
			out[i].normal = godot::Vector3(o[4], o[5], o[6]);
		}
	}
}
inline Hit hit_from(godot::CollisionObject3D *b, const godot::Vector3 &from, const godot::Vector3 &to, const char *file, int line) {
	const godot::Vector3 p[2] = { from, to };
	Hit h;
	rays_from(b, p, 1, &h, file, line);
	return h;
}
} // namespace trav
// TRAV_HIT_FROM: one ray, as TRAV_RAY_FROM, read as a Hit; TRAV_RAYS_FROM: n independent rays in one engine call
#define TRAV_HIT_FROM(b, from, to) trav::hit_from((b), (from), (to), __FILE__, __LINE__)
#define TRAV_RAYS_FROM(b, pairs, n, out) trav::rays_from((b), (pairs), (n), (out), __FILE__, __LINE__)
#define TRAV_RAY_FROM(b, from, to) trav::ray_from((b), (from), (to), __FILE__, __LINE__)
#define TRAV_SPACE(n) trav::space_at((n), __FILE__, __LINE__)
#define TRAV_RAY(n, q) trav::ray_at((n), (q), __FILE__, __LINE__)
// the game's per-system frame timers (native/src/perf_marks.h; 28 Nov night: what the new bodies cost on the phone);
// nothing in the lab's own build
#ifdef TRAV_IN_GAME
#include "perf_marks.h"
#define TRAV_PM(id) pm::Scope _trav_pm(pm::id)
#else
#define TRAV_PM(id)
#endif
