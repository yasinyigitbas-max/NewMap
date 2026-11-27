// THE POSE COPY (28 Nov): an old figure's pose (CityPed, the Rocketbox bones) put on a new body's skeleton (the mixamo
// bones of the traversal character and of the new people), bone by bone. Used where the new bodies have no take of
// their own: people's acts (city_crowd_trav.cpp), the player at the wheel and on the bicycle (city_player.cpp).
#pragma once
#ifdef TRAV_IN_GAME
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <vector>

namespace godot {

struct TravMirror {
	bool on = false, map_ok = false;
	Skeleton3D *sk = nullptr;
	std::vector<int> m_old;            // per new bone: the old figure's bone, or -1
	std::vector<Basis> m_fix;          // per new bone: A * F * its rest, in the body's frame
	std::vector<Basis> m_old_rest_inv; // per new bone: the old bone's rest in the old figure's frame, inverted
	float m_scale = 1.0f;
	// p_body: the new body (its child "Character" has the skeleton, `skel`); p_old, p_os: the old figure and its skeleton
	bool map(Node3D *p_body, Node3D *p_old, Skeleton3D *p_os);
	// into and out of the copy (the body's own movement, animation and bone fitting stand still while it lasts), and,
	// while on, this frame's pose. Returns whether the copy is on.
	bool set(Node3D *p_body, Node3D *p_old, Skeleton3D *p_os, bool p_on);
};

} // namespace godot
#endif
