// Lab B: the clip-driven locomotion core (layer 1-3 of the stack). Capsule-led like GTA V: the stick sets a desired
// velocity, this picks and plays clips (idle, starts, phase-synced loops, stops, pivots), inertializes every switch,
// and hands back the capsule's velocity and facing for this tick plus the pose. DECISIONS 3.x.
#pragma once

#include "clip_library.h"
#include "inertial.h"

#include <godot_cpp/variant/vector2.hpp>

namespace lab {

enum class Mode { IDLE = 0, START = 1, LOOP = 2, STOP = 3, PIVOT = 4 };

struct LoopSet {
	const Clip *clip[4] = {nullptr, nullptr, nullptr, nullptr}; // walk, jog, run, run_fast
	int count = 0;
};

class Locomotion {
public:
	bool init(const ClipLibrary *lib);

	// desired_dir: world XZ (unit, or zero), desired_speed m/s. dt fixed physics step.
	void tick(float dt, godot::Vector2 desired_dir, float desired_speed);
	// after the capsule moved: what it really did (walls)
	void set_actual_velocity(godot::Vector2 v);

	// ---- outputs ----
	godot::Vector2 velocity;   // world XZ m/s for this tick
	float yaw = 0;             // facing (radians, 0 = +Z, positive turns toward +X)
	Pose pose;                 // output pose (inertialized)
	Pose pose_old;             // last tick's output pose
	bool contact[2] = {true, true};
	float phase = 0;           // loop foot phase
	float stride_scale = 1;    // stride warping factor (study 4.1)
	float play_rate = 1;
	float accel_long = 0;      // m/s^2 along facing (smoothed by the pose layer)
	float accel_lat = 0;       // m/s^2 sideways (v * turn rate)
	Mode mode = Mode::IDLE;
	const char *clip_name = "";
	float clip_time = 0;
	int switches = 0;          // number of inertialized switches (test counter)
	float desired_yaw = 0;     // where the stick points (for the head)
	bool has_input = false;

	const ClipLibrary *lib = nullptr;

private:
	int B = 0;
	LoopSet loops;
	const Clip *idle = nullptr;
	const Clip *walk_start[2] = {}, *walk_stop[2] = {}, *run_start[2] = {}, *run_stop[2] = {};
	const Clip *run_pivot[2] = {}, *walk_pivot[2] = {}, *run_start_turn[2] = {};

	Inertializer inert;
	Pose stance;               // legs + hips held in idle after a stop (layered idle, DECISIONS 3.8)
	bool has_stance = false;
	std::vector<int> lower;    // bone indices of the hips and legs
	void idle_pose(float t, Pose &out);
	void capture_stance();
	Pose src, src_old, tmp_a, tmp_b;

	const Clip *cur = nullptr; // clip of a root-motion mode
	float t = 0;               // its time
	float rate = 1;            // its playback rate
	float align = 0;           // world yaw minus clip root yaw (root frame alignment)
	float motion_scale = 1;
	bool stop_swung = false;   // stop: the second foot has lifted
	float speed_cap = 10;
	float pivot_cool = 0;      // seconds until another pivot may start      // root-motion modes: max capsule speed    // root-motion scale (stride warping on starts/stops)
	float idle_t = 0;
	float speed = 0;           // capsule speed (m/s)
	godot::Vector2 prev_vel;
	float prev_yaw = 0;

	void switch_to(Mode m, float dt);
	void sample_source(float dt_back);
	void loop_pose(float ph, float v, Pose &out, int &dominant);
	void loop_speeds(float v, int &i0, int &i1, float &w) const;
	float loop_cycle_time(float v) const;
	float time_to_strike(int foot) const;
	void enter_start(float dt, float ang, float want_speed);
	void enter_stop(float dt);
	void enter_pivot(float dt, float ang);
	void root_motion_step(float dt, float steer_rate, float target_yaw, float end_t);
	static float wrap_pi(float a);
};

} // namespace lab
