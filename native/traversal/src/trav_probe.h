// What the traversal's rays and shape tests look at (27 Nov, the game's world contract, docs/damage/WORLD_CONTRACT.md:
// "Traversal and locomotion probes ... use mask" the world, not people). A body may carry the meta "probe_mask": then
// every probe (ground, step, wall, ledge, room to stand, feet, hands) uses it and only the capsule's own moving uses
// the body's collision mask. Without the meta (the lab, the tests) a probe uses the body's mask, as before.
#pragma once
#include <godot_cpp/classes/collision_object3d.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
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
} // namespace trav
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
