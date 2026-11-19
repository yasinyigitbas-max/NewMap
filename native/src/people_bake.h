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
	enum { POSES = 13 };   // 0-7 the walk, 8 standing, 9 sitting on a seat, 10 lying on the back, 11 lying on the front, 12 sitting on the ground
	// Poses every body of p_dir (characters/rocketbox/) under p_parent (a node in the tree) and writes the table
	PackedStringArray bake(Node *p_parent, const String &p_dir, const String &p_out);
	int count() const { return n_bodies; }
};

} // namespace godot
