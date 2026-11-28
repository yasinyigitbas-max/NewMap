// CityCarLights (look uplift, 28 Nov; Yasin: "lights dont cost us almost anything, we added grid lighting at a fixed
// cost"). The traffic's headlights were lamps you could see but they lit nothing: at night the road in front of a car
// stayed black. This keeps a small pool of real spot lights (the engine's light grid: the nearest 32 spot lights for a
// fixed cost) on the moving cars nearest the camera, pointed down the road ahead of each, and off by day.
// Ten times a second it asks the traffic for the cars near the camera (CityTraffic::cars_near) and moves the pool.
// rig.gd adds one beside the traffic. No light has a shadow.
#pragma once
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/spot_light3d.hpp>
#include <vector>

namespace godot {

class CityCarLights : public Node3D {
	GDCLASS(CityCarLights, Node3D)
	uint64_t traffic_id = 0;
	std::vector<SpotLight3D *> pool;
	int count = 8;
	double reach = 26.0, energy = 3.2, every = 0.1, t = 0.0;
protected:
	static void _bind_methods();
public:
	void set_traffic(Node *p_traffic);
	void set_count(int p_n) { count = p_n; }
	int get_count() const { return count; }
	void set_energy(double p_e) { energy = p_e; }
	double get_energy() const { return energy; }
	int lit = 0;
	int get_lit() const { return lit; }
	void _ready() override;
	void _process(double p_delta) override;
};

} // namespace godot
