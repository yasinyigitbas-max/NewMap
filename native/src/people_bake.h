// PeopleBake: the tool that poses the far figures. See people_bake.cpp.
#pragma once

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class PeopleBake : public RefCounted {
	GDCLASS(PeopleBake, RefCounted)

	int n_bodies = 0;

protected:
	static void _bind_methods();

public:
	// 0-7 the walk, 8 standing, 9 sitting on a seat, 10 lying on the back, 11 lying on the front, 12 sitting on the ground,
	// 13-16 riding a bicycle (the crank a quarter turn on from one to the next; the traffic's cyclists)
	enum { POSES = 17, RIDE0 = 13, RIDE_N = 4 };
	// where the bicycle is in a riding pose: the figure's origin is on the ground under the crank's axle, +z forward
	// the bicycle the riders sit on (the beach cruiser, bike_look.h; its frame: the crank's axle over the origin): crank,
	// the grips' middles (forward, to the side, and how far over the hips), the hips behind the crank
	static constexpr float BB_Y = 0.28f, CRANK = 0.17f, BAR_Z = 0.144f, BAR_W = 0.31f, BAR_OVER_HIPS = 0.086f, HIPS_BACK = 0.22f, BACK_LEAN = 0.12f;
	// Poses every body of p_dir (characters/rocketbox/) under p_parent (a node in the tree) and writes the table
	PackedStringArray bake(Node *p_parent, const String &p_dir, const String &p_out);
	int count() const { return n_bodies; }
};

} // namespace godot
