// StreetGraph: the tool that makes the new map's streets usable by traffic and people (docs/TRAFFIC_PEOPLE_PORT.md,
// sections 5 and 14). It reads what was BUILT: the baked cells' ground (asphalt, pavement, painted lines), their
// parking stalls and their signal heads, and the locked street skeleton for the topology; it writes streets.bin.
// Tool time only: the game loads streets.bin, it never runs this.
#pragma once

#include "street_build.h"
#include "street_ground.h"

#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <vector>

namespace godot {

class Node;

class StreetGraph : public RefCounted {
	GDCLASS(StreetGraph, RefCounted)

	sg::Ground ground;
	std::vector<float> stalls;    // 6 per stall: x, y, z, yaw (degrees), grade, cell index
	std::vector<float> signals;   // 3 per signal head prop: x, y, z
	int cells_read = 0, grounds_other = 0;
	std::vector<int32_t> cell_xz; // 2 per cell read: its cell x, cell z
	sg::Builder builder;

	void read_cell(Node *p_root, int p_cell);

protected:
	static void _bind_methods();

public:
	// Reads every baked cell under p_runtime_dir (".../runtime/"). Needs a real renderer (mesh data is read back).
	// Returns the number of cells read.
	int load_bake(const String &p_runtime_dir);
	Dictionary stats() const;
	// Builds the streets from the skeleton (review/sites.json) and what load_bake read. Returns the report, line by line.
	PackedStringArray build(const String &p_sites_json);
	// The ground along a line, every p_step metres: pairs (surface kind, height); kind -1 = no ground
	PackedFloat32Array profile(const Vector3 &p_from, const Vector3 &p_to, double p_step) const;
	// A top view of the surface kinds (tool check pictures)
	Ref<Image> layer_image(double p_x0, double p_z0, double p_x1, double p_z1, double p_m_per_px) const;
	// the same with the lanes, their ends and the connections through the junctions drawn over it
	Ref<Image> lanes_image(double p_x0, double p_z0, double p_x1, double p_z1, double p_m_per_px) const;
	// writes streets.bin; false = could not write
	bool save(const String &p_path) const;
	PackedFloat32Array get_stalls() const;
	PackedFloat32Array get_signals() const;
};

} // namespace godot
