// Lab B: the validator (study v2 9.1). A SkeletonModifier3D placed LAST: it reads the drawn pose, in world space,
// and tests every HARD rule of v2 11.2. Read-only. The limiter (10.2) shares body.h and the static rules below.
#pragma once

#include "body.h"

#include <godot_cpp/classes/skeleton_modifier3d.hpp>
#include <godot_cpp/classes/capsule_shape3d.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>

#include <deque>
#include <map>
#include <string>
#include <vector>

namespace lab {

// controller state, given each physics tick by the player (validator rules depend on it)
enum CheckState { CS_IDLE = 0, CS_START = 1, CS_LOOP = 2, CS_STOP = 3, CS_PIVOT = 4, CS_TRAVERSE = 5, CS_AIR = 6, CS_GESTURE = 7 };

struct FrameIn {
	int state = CS_IDLE;
	float speed = 0;             // capsule horizontal speed (m/s)
	godot::Vector3 vel;          // capsule velocity (world)
	bool planted[2] = {false, false}; // the base motion says this foot is down
	bool grip[2] = {false, false};    // a hand is meant to grip the world
	float mu = 0.7f;             // ground friction (3.1)
};

struct Contacts {
	bool pt[2][SOLE_N];          // within 1 cm of the surface
	float h[2][SOLE_N];          // height above the surface (m), + above
	godot::Vector3 n[2];         // ground normal under each foot (heel / ball rays averaged)
	bool any[2];
};

struct Hit {
	const char *rule;
	int side;
	float value, limit;
};

// static (single-frame) rules shared by the validator and the limiter's pre-check
void check_static(const Measures &me, const Contacts &c, const FrameIn &in, std::vector<Hit> &out);

class PoseCheck : public godot::SkeletonModifier3D {
	GDCLASS(PoseCheck, godot::SkeletonModifier3D)

public:
	BodyModel model;
	FrameIn in;
	bool use_flat_ground = false;
	float flat_ground_y = 0;
	int seed = 0;
	int limiter_acted = 0;       // set by the limiter, read here

	void _process_modification_with_delta(double p_delta) override;

	// GDScript API
	void set_frame_input(int state, float speed, godot::Vector3 vel, bool pl, bool pr, bool gl, bool gr);
	void set_flat_ground(bool on, float y) { use_flat_ground = on; flat_ground_y = y; }
	void set_seed(int s) { seed = s; }
	void set_active(bool a) { active = a; }
	void reset();
	godot::Dictionary get_counts() const;
	godot::PackedStringArray get_log() const;
	godot::Dictionary measure_now();               // all measures of the current pose
	godot::PackedStringArray check_static_now();   // static rules on the current pose
	godot::PackedStringArray step_manual(double dt); // the full per-frame pipeline on the current pose; returns rules hit this frame
	int get_frames() const { return frames; }
	bool is_model_ok() { ensure_model(); return model.ok; }
	godot::String get_model_error() const { return model.error; }
	godot::Vector3 get_com() const { return last.com; }
	godot::Vector3 get_sole_point(int side, int k) const { return last.sole_w[side][k]; }
	// clips without a scene: pose by forward kinematics from a clip-cache frame (fast path for tools and tests)
	void set_fk_pose(const godot::PackedFloat32Array &rot, const godot::PackedFloat32Array &hips, const godot::PackedFloat32Array &root, int f);
	void clear_fk_pose() { fk_on = false; }
	godot::PackedVector3Array clip_lowest_soles(const godot::PackedFloat32Array &rot, const godot::PackedFloat32Array &hips,
			const godot::PackedFloat32Array &root, int frames); // per frame: the 4 sole points of L, then R (world)

protected:
	static void _bind_methods();

private:
	bool active = true;
	std::vector<godot::Transform3D> W;
	bool fk_on = false;
	std::vector<godot::Transform3D> W_fk;
	void pose_W();
	Measures last;
	Contacts lastc;
	int frames = 0;
	double t = 0;
	std::map<std::string, int> counts;
	std::vector<std::string> log;
	std::vector<std::string> fired_now;

	// time series (v2 1.8): raw samples, evaluated at the centre of a +-40 ms window
	struct Sample {
		double t;
		Measures m;
		Contacts c;
		FrameIn in;
	};
	std::deque<Sample> buf;
	// contact episodes per sole point
	bool ep_on[2][SOLE_N] = {};
	godot::Vector3 ep_start[2][SOLE_N];
	float ep_max[2][SOLE_N] = {};
	bool ep_logged[2][SOLE_N] = {};
	bool flat_on[2] = {false, false};
	float flat_yaw0[2] = {0, 0};
	bool spin_logged[2] = {false, false};
	bool any_contact_prev[2] = {false, false};
	double both_down_since = -1;
	// flight
	bool in_flight = false;
	godot::Vector3 to_pos, to_vel;
	double to_t = 0;
	// steps (between contact starts)
	double step_t0 = -1;
	godot::Vector3 step_lean_sum, step_v0;
	int step_n = 0;
	godot::Vector3 last_step_lean; // tangent of the step-averaged whole-body lean (x = side, y = fwd)
	bool have_step = false;
	float step_heading0 = 0;
	bool have_heading = false;
	// turn and stop
	double turn20_since = -1;
	float prev_heading_ = 0;
	double prev_t_ = -1;
	float omega_f_ = 0;
	bool was_running = false;
	int stop_contacts = 0;
	// head pitch over a stride
	std::deque<std::pair<double, float>> head_pitch_hist;
	// grip
	bool grip_on[2] = {false, false};
	godot::Vector3 grip_start[2];
	godot::Vector3 cop_w;
	godot::Ref<godot::CapsuleShape3D> cap_shape;

	void contacts_for(const Measures &me, Contacts &c);
	void hit(const char *rule, int side, float value, float limit);
	void evaluate(double dt);
	void ensure_model();
	godot::Skeleton3D *skel() const;
};

} // namespace lab
