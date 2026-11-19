// The walking crowd of the city kit map (docs/TRAFFIC_PEOPLE_PORT.md, stage 3): the old game's crowd core (cc::Sim,
// crowd_sim.*: routes, keep right, passing, parties, meetings, pauses, crossings) on the pavements and crossings the
// streets tool measured (streets.bin). All C++.
#pragma once

#include "crowd_sim.h"
#include "street_build.h"

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <unordered_map>
#include <vector>

namespace godot {

class CityCrowd : public Node3D {
	GDCLASS(CityCrowd, Node3D)

public:
	enum { SIG_CYCLE_S = 30 };

private:
	cc::Sim *sim = nullptr;
	sg::StreetData streets;
	bool ready = false;
	// the walk graph as the core has it (the tool's stretches cut into short pieces: the core spawns and plans by piece)
	int n_nodes = 0, n_segs = 0, n_cross = 0, n_cross_signal = 0;
	double walk_m = 0.0;
	std::vector<float> gr_node_xz, gr_len, gr_hw, gr_pts;
	std::vector<int32_t> gr_a, gr_b, gr_ctl, gr_p0, gr_np;
	std::vector<uint8_t> gr_kind, gr_zone;
	void feed();
	// the pieces again, for the check "is this walker on a pavement or a crossing at all" (the test; later the drawing)
	std::vector<float> g_pts, g_hw;
	std::vector<int32_t> g_p0, g_np;
	std::unordered_map<int64_t, std::vector<int32_t>> g_cells;   // 16 m cells -> pieces
	std::vector<int32_t> ctl_node;       // per signal control: its junction (street node)
	std::vector<float> ctl_off;          // ... and its start in the signal cycle (s), the traffic's own number
	double dens[cc::MAX_ZONES] = { 1.0 / 45.0, 1.0 / 30.0, 1.0 / 14.0, 1.0 / 12.0, 1.0 / 40.0, 0, 0, 0 };   // walkers a metre of pavement, by zone, at the busiest hour
	int max_people = 120;
	double density = 1.0;

protected:
	static void _bind_methods();

public:
	CityCrowd();
	~CityCrowd();

	// Reads streets.bin and builds the crowd core on its pavements and crossings. false = no file.
	bool load_streets(const String &p_path);
	bool is_built() const { return ready; }
	Dictionary walk_stats() const;
	// the signals as the walkers see them at traffic time t: a walker starts across with the green of the street it
	// walks along, in that green's first seconds only (a crossing takes longer than the rest of the green)
	void push_signals(double p_clock);
	// how many walkers the pavements round the view carry now (by zone), given to the core
	void push_targets();
	// walkers that stand on no pavement and no crossing (farther from every piece's line than its half width + 0.35 m)
	int off_walk() const;
	// A run of the core alone, no drawing: the test's numbers
	Dictionary run_test(int p_people, double p_minutes, int64_t p_seed, const Vector3 &p_cam, double p_density);
};

} // namespace godot
