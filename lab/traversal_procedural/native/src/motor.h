// Lab A (procedural): the motor. Plans footsteps, runs the gait clock and the centre-of-mass path, and writes
// world-space pose targets every physics tick. No clips. See DECISIONS.md section 2 and 3.
#pragma once

#include "labmath.h"
#include "move.h"

#include <functional>

namespace lab {

// Measured from the body's rest pose at start-up (DECISIONS 1.1).
struct BodyDims {
	float thigh[2] = { 0.38f, 0.38f }, shin[2] = { 0.38f, 0.38f };
	float ankle_h[2] = { 0.165f, 0.165f }; // ankle above the sole
	Vector3 ball[2]; // ball of the foot relative to the ankle's ground point, foot frame (x left, y up, z fwd)
	Vector3 heel[2]; // heel contact relative to the ankle's ground point, foot frame
	float toe_len[2] = { 0.06f, 0.06f };
	Vector3 hip_off[2]; // hip joint relative to the hips bone origin, rest (character frame)
	float hips_h = 1.0f; // rest hips-bone height above the soles
	Vector3 shoulder_off[2]; // upper-arm joint relative to the hips bone origin, rest
	float uarm[2] = { 0.22f, 0.22f }, farm[2] = { 0.25f, 0.25f };
	float leg(int i) const { return thigh[i] + shin[i]; }
};

// What the poser needs, in world space. Rotations are deltas from the rest pose (rest faces +Z).
struct Targets {
	Vector3 hips_pos;
	Quaternion hips_rot;
	Quaternion trunk_rot; // upper chest, world delta
	Quaternion head_rot; // head, world delta
	Vector3 ankle[2];
	Quaternion foot_rot[2];
	float toe_bend[2] = { 0, 0 }; // radians, toes bent up relative to the foot
	Vector3 knee_pole[2];
	Vector3 hand_off[2]; // hand target relative to the shoulder joint, world axes
	Vector3 elbow_pole[2];
	float finger_curl = 1.0f;
	// for metrics
	bool planted[2] = { true, true };
	int contact[2] = { 2, 2 }; // 0 swing, 1 heel pivot, 2 flat, 3 ball pivot
	Vector3 contact_pt[2]; // the world point that must not move while in contact
	float body_lean = 0; // radians, for the response metric
	// hands on the world (traversal): weight 0 = the locomotion arm, 1 = pinned at hand_pos
	float hand_w[2] = { 0, 0 };
	Vector3 hand_pos[2], hand_fingers[2], hand_palm[2], hand_pole[2];
	float grip[2] = { 0, 0 }; // 1 hook, -1 open palm push, 0.5 wrap, 0 rest curl
	bool hand_contact[2] = { false, false }; // pinned (for the hand-on-edge metric)
	int move = 0; // the move being played (MoveType), for tests
};

Targets lerp_targets(const Targets &a, const Targets &b, float t);

struct RayHit {
	bool hit = false;
	Vector3 pos;
	Vector3 normal = UP;
};
// from_inside: a ray that starts inside a shape reports a hit at its start (used to find walls in the profile)
using GroundFn = std::function<RayHit(const Vector3 &from, const Vector3 &to, bool from_inside)>;

// The ground along the path, probed live every tick (WORLD_CONTRACT 3: nothing kept across frames).
struct Profile {
	static constexpr int N = 72;
	static constexpr float DX = 0.04f;
	static constexpr float X0 = -0.40f;
	Vector3 origin, dir;
	int n = 0; // valid samples (stops at a wall)
	float h[N];
	int n_edges = 0;
	float edge_x[24], edge_rise[24];
	float slope = 0; // radians, + uphill along dir, over the next 1.2 m
	bool stairs = false;
	float tread = 0, riser = 0, first_stair = 1e9f;
	float x_of(const Vector3 &p) const { return (p - origin).dot(dir); }
	float h_at(float x) const;
	bool clear(float a, float b) const; // no edge between a and b
	float max_h(float a, float b) const;
};

struct MotorInput {
	Vector3 pos; // body origin (ground level under the capsule), world
	Vector3 vel; // actual horizontal velocity after the move
	Vector3 vel_des; // desired horizontal velocity
	Vector3 look_dir; // stick direction (world, flat); zero when the stick is idle
	float dt = 1.0f / 60.0f;
	bool grounded = true;
	float vy = 0; // vertical velocity (air / landing)
};

class Motor {
public:
	BodyDims d;
	GroundFn ground;

	void reset(const Vector3 &pos, float yaw);
	// Acceleration-limited velocity (DECISIONS 3.4). Returns the new horizontal velocity.
	Vector3 steer(const Vector3 &vel, const Vector3 &vel_des, float dt) const;
	void step(const MotorInput &in);
	const Targets &targets() const { return t; }
	// traversal (step 6)
	Move mv;
	Obstacle armed;
	bool move_active() const { return mv.type != MV_NONE; }
	Vector3 move_origin; // the capsule's position while a move runs (the player puts it there)
	bool move_launch = false; // a move just ended in the air: the player takes mv.launch as velocity
	Vector3 launch_vel;
	int moves_done[16] = {};
	int refusals = 0;
	const char *last_refusal = "";
	bool fall_hurt_report = false; // a landing from > 3 m: the damage system's hit(FALL) is called by the player
	float fall_height = 0;
	// terrain limits on the requested speed (stairs: a tread per step; steep slopes: slower), from the last tick
	float speed_cap = 1e9f;
	float slope_mult = 1.0f;
	Profile prof;
	int edge_landings = 0; // touchdowns with the foot across an edge (the planner failed)

	// state readable by the player / tests
	float yaw = 0;
	float look_yaw = 0;
	bool active = false;
	float phase = 0;
	int gait = 0; // 0 walk, 1 run
	float gait_w = 0;
	int steps_taken = 0;
	struct Foot {
		bool planted = true;
		Vector3 plant; // ground point under the ankle when the foot is flat
		float fyaw = 0;
		Vector3 normal = UP;
		Vector3 lift;
		Vector3 lift_rel;
		Vector3 target_rel;
		float lift_yaw = 0;
		float lift_beta = 0.6f;
		float lift_pitch = 0;
		float lift_toe = 0;
		Vector3 target;
		float target_yaw = 0;
		Vector3 target_normal = UP;
		float prev_p = 0;
		float t_rem = 0; // swing time left
		float land_pitch = 0; // pitch at touchdown: < 0 heel strike, 0 flat (stepping up), > 0 toes first (down)
		float choice_x = 0;
		bool has_choice = false;
		bool skip = false; // stayed down this stride (stopping, already in place)
		float pitch = 0; // + heel up (toes down)
		int pivot = 2; // 1 heel, 2 flat, 3 ball
		float toe = 0;
		float load = 0.5f; // share of the body's weight
		float u = 0; // swing progress
		Vector3 ground_ref; // current flat-foot ground reference (swing: moving)
		float clearance = 0;
	} foot[2];

private:
	Targets t;
	Vector3 accel_f; // smoothed acceleration (lean)
	Vector3 prev_vel;
	Spring1 hips_y;
	Spring3 hips_side;
	Spring3 lean_s;
	Vector3 lean_off; // horizontal shift of the hips by the lean
	float idle_time = 0;
	float idle_w_phase = 0;
	float beta_cur = 0.6f, freq_cur = 1.0f;
	float speed_s = 0;
	bool stopping = false;
	float breath = 0;
	float lean_pitch_f = 0;

	float walk_cadence(float s) const { return 75.0f + 30.0f * s; }
	float run_cadence(float s) const { return 150.0f + 5.0f * s; }
	float walk_beta(float s) const { return clampf(0.62f - 0.02f * s, 0.58f, 0.62f); }
	float run_beta(float s) const { return clampf(0.36f - 0.03f * (s - 2.5f), 0.28f, 0.36f); }
	float local_p(int i) const { return frac(phase - (i == 0 ? 0.0f : 0.5f)); }
	Vector3 idle_spot(int i, const Vector3 &pos, float yaw_) const;
	float idle_yaw(int i, float yaw_) const;
	RayHit probe(const Vector3 &xz, float ref_y) const;
	void plan_swing(int i, const MotorInput &in, float T_rem, float T_st);
	void foot_pose(int i, Vector3 &ankle, Basis &rot) const;
	void foot_geom(int i, const Vector3 &ref, const Basis &Rflat, float pitch, int pivot, Vector3 &ankle, Basis &rot) const;
	static constexpr float BALL_MAX = 45.0f * DEG; // toes bend up to ~45-55 deg before the foot rolls onto the tips
	void start(const MotorInput &in);
	// step 6
	Obstacle probe_obstacle(const MotorInput &in, float x_face, bool is_drop);
	void classify(Obstacle &O, float speed) const;
	bool begin_move(const MotorInput &in, int takeoff_foot);
	void build_move(const Obstacle &O, int i, const MotorInput &in);
	void build_land(const MotorInput &in, float v_impact);
	void run_move(const MotorInput &in);
	void finish_move(const MotorInput &in, bool aborted);
	void air_pose(const MotorInput &in);
	FootPose foot_now(int i) const;
	FootPose flat_foot(int i, const Vector3 &ground, float fyaw, float pitch = 0, int pivot = 2) const;
	float stand_h() const { return d.ankle_h[0] + 0.985f * d.leg(0) - d.hip_off[0].y; }
	bool in_air = false;
	float air_time = 0, air_vy_min = 0, air_start_y = 0;
	Targets blend_from;
	float blend_t = 1, blend_T = 0.2f;
	float wall_x = 1e9f; // where the profile met a wall (along prof.dir)
	void scan(const MotorInput &in, const Vector3 &dir);
	void choose_landing(int i, Vector3 &tgt, float yaw_td);
	float posture_extra = 0, look_down = 0;
};

} // namespace lab
