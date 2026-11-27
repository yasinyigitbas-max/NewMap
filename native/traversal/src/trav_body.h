// The body (the study, Layer 1): the translation of traversal_lab/traversal/body/body.gd. Not translated yet: this is
// the empty class that proves the build and the loading (step 0 of the port).
#pragma once

#include <godot_cpp/classes/character_body3d.hpp>

namespace godot {

class TravBody : public CharacterBody3D {
	GDCLASS(TravBody, CharacterBody3D)

protected:
	static void _bind_methods();

public:
	String native_version() const;
};

} // namespace godot
