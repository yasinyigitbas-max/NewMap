// What the traversal's rays and shape tests look at (27 Nov, the game's world contract, docs/damage/WORLD_CONTRACT.md:
// "Traversal and locomotion probes ... use mask" the world, not people). A body may carry the meta "probe_mask": then
// every probe (ground, step, wall, ledge, room to stand, feet, hands) uses it and only the capsule's own moving uses
// the body's collision mask. Without the meta (the lab, the tests) a probe uses the body's mask, as before.
#pragma once
#include <godot_cpp/classes/collision_object3d.hpp>

namespace trav {
inline uint32_t probe_mask(godot::CollisionObject3D *b) {
	static const godot::StringName K("probe_mask");
	return b->has_meta(K) ? (uint32_t)(int64_t)b->get_meta(K) : b->get_collision_mask();
}
} // namespace trav
