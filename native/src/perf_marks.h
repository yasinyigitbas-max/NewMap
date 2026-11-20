// Per-system frame timers (Yasin, 20 Nov: "find and fix the slow frames"). Each system's _process / _physics_process opens a
// pm::Scope; the time adds up per system until the rig takes it (CityStream.perf_take(), once a frame) and prints the
// biggest with each slow frame. Plain statics only (a Godot type as a static breaks the library's load on Windows).
#pragma once
#include <chrono>

namespace pm {

enum Id { ROOMS, BREAKABLES, CROWD, CROWD_PHYS, TRAFFIC, TRAFFIC_PHYS, AMBIENCE, CAR, PLAYER, PLAYER_PHYS, PED_PHYS, BIKE,
	HUD, TALK, STEPS, ENGINE, GAME, N };
inline const char *NAME[N] = { "rooms", "breakables", "crowd", "crowd_phys", "traffic", "traffic_phys", "ambience", "car",
	"player", "player_phys", "ped_phys", "bike", "hud", "talk", "steps", "engine", "game" };
inline double acc_ms[N] = {};

struct Scope {
	int id;
	std::chrono::steady_clock::time_point t0;
	explicit Scope(int p_id) : id(p_id), t0(std::chrono::steady_clock::now()) {}
	~Scope() { acc_ms[id] += std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count(); }
};

} // namespace pm
