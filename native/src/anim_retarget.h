// AnimRetarget: the tool that fits the Quaternius animation library's clips to this game's figure. See anim_retarget.cpp.
#pragma once

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class AnimRetarget : public RefCounted {
	GDCLASS(AnimRetarget, RefCounted)

	PackedStringArray skip;
	int n_skipped = 0, n_layered = 0;
	Array layers;

	int n_clips = 0;

protected:
	static void _bind_methods();

public:
	// Reads the library's .glb files, fits every clip to the male and the female figure of p_dir
	// (characters/rocketbox/) and saves clips_ual_male.res / clips_ual_female.res there. Returns the report's lines.
	PackedStringArray retarget(Node *p_parent, const PackedStringArray &p_sources, const String &p_dir);
	int count() const { return n_clips; }
	// clips whose name holds one of these are not fitted (swords, bows, spells ...: nothing a street needs)
	void set_skip(const PackedStringArray &p_skip) { skip = p_skip; }
	PackedStringArray get_skip() const { return skip; }
	int skipped() const { return n_skipped; }
	// mixed clips, each [name, base, top]: the base clip with the arms, neck and head of the top one laid over it
	// (walking while talking, sitting with a phone ...); made after the fitting, saved with the others
	void set_layers(const Array &p_layers) { layers = p_layers; }
	int layered() const { return n_layered; }
};

} // namespace godot
