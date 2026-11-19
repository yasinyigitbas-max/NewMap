// PeoplePlaces: the tool that finds the places people go on the map. See people_places.cpp and ped_places.h.
#pragma once

#include "ped_places.h"

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class PeoplePlaces : public RefCounted {
	GDCLASS(PeoplePlaces, RefCounted)

	pc::PlaceData data;

protected:
	static void _bind_methods();

public:
	// Reads streets.bin, the layout, the pieces and the shop list; returns the report's lines ("PLACES ...")
	PackedStringArray build(const String &p_streets, const String &p_layout, const String &p_pieces_dir, const String &p_rooms);
	// the sea: for every place on the beach a spot to swim at, from the sea's depth map (tools/city/look/sea_map.*).
	// Works on the places it holds (after build), or on a places.bin given (then save it again).
	PackedStringArray add_swim(const String &p_places, const String &p_sea_png, const String &p_sea_json);
	bool save(const String &p_path);
	int count() const;
};

} // namespace godot
