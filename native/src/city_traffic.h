// CityTraffic: the new map's traffic (docs/TRAFFIC_PEOPLE_PORT.md). It owns the traffic core (tc::Sim) and the streets
// it runs on (streets.bin, made by StreetGraph). Everything per tick and per frame is in here, in C++; the test app's
// script only creates the node and sets numbers on it.
#pragma once

#include "street_build.h"

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace tc {
class Sim;
}

namespace godot {

class CityTraffic : public Node3D {
	GDCLASS(CityTraffic, Node3D)

	tc::Sim *sim = nullptr;
	sg::StreetData streets;
	bool ready = false;

protected:
	static void _bind_methods();

public:
	CityTraffic();
	~CityTraffic();

	// Reads streets.bin and builds the core on it. false = no file, or not a streets file.
	bool load_streets(const String &p_path);
	bool is_built() const { return ready; }
	// What the core made of the streets: lanes, paths, conflict pairs, dead ends, build time
	Dictionary street_stats() const;
	// A run with no drawing, for the checks (tests/traffic): p_cars cars round p_cam for p_minutes of traffic time,
	// stepped as the game steps it (20 times a second). p_whole_city: cars everywhere on the map, every car stepped
	// every tick (the hardest case for the junctions), else as in the game (a ring round the camera, far cars stepped
	// less often). p_stuck_rule: the core's "a car that stands a minute unseen is taken away" rule on or off.
	// Returns counts: overlapping car pairs (must be 0), cars standing over 2 minutes not at a red light, the state
	// hash (the same seed must give the same hash), the time a step takes.
	// p_density: 1 = as many cars as the streets carry at their busiest hour (up to p_cars); 2 = twice that, and so on.
	Dictionary run_test(int p_cars, double p_minutes, int64_t p_seed, const Vector3 &p_cam, bool p_whole_city, bool p_stuck_rule, double p_density);
};

} // namespace godot
