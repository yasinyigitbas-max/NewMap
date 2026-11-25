// Lab B: the pose layer (layers 5-6 of the stack). A SkeletonModifier3D that writes the locomotion pose (interpolated
// between physics ticks) and then the procedural layers: whole-body lean, foot lock + leg IK (knee over the toes, soft
// reach, ankle limit), head leading the turn and staying level, forearm twist. DECISIONS 4.x.
#pragma once

#include "clip_library.h"

#include <godot_cpp/classes/skeleton_modifier3d.hpp>
#include <godot_cpp/variant/transform3d.hpp>

namespace lab {

struct LayerInput {
	Pose pose_prev, pose_cur;   // locomotion output at the last two physics ticks
	bool contact[2] = {true, true};
	float stride_scale = 1;
	godot::Vector3 vel_world;   // capsule velocity
	float accel_long = 0, accel_lat = 0;
	float head_yaw_target = 0;  // world yaw the head should face (stick direction)
	float body_yaw = 0;
	float ground_y[2] = {0, 0}; // ground under each foot (world), from the physics tick
	godot::Vector3 ground_n[2] = {godot::Vector3(0, 1, 0), godot::Vector3(0, 1, 0)};
	bool valid = false;
	int lean_enabled = 1;       // 0 in modes where the clip already leans (starts, stops)
};

class PoseLayer : public godot::SkeletonModifier3D {
	GDCLASS(PoseLayer, godot::SkeletonModifier3D)

public:
	LayerInput in;

	// test probes (read by the GDScript harness)
	godot::Vector3 get_foot_world(int side) const { return foot_world[side]; }
	bool get_foot_locked(int side) const { return locked[side]; }
	float get_lean_deg() const { return lean_total_deg; }
	float get_head_yaw_deg() const { return head_yaw_deg; }
	int get_ik_clamped() const { return ik_clamped; }
	int get_releases() const { return releases; }
	void set_layers(int mask) { layers = mask; }
	int get_layers() const { return layers; }
	void reset_lock() { for (int s = 0; s < 2; s++) { corr[s] = godot::Vector2(); have_prev[s] = false; locked[s] = false; } }

	void _process_modification_with_delta(double p_delta) override;

protected:
	static void _bind_methods();

private:
	bool ready_idx = false;
	int H = -1, HEAD = -1, NECK = -1, SPINE[3] = {-1, -1, -1};
	int UP[2] = {-1, -1}, LO[2] = {-1, -1}, FOOT[2] = {-1, -1}, TOE[2] = {-1, -1};
	int FARM[2] = {-1, -1}, HAND[2] = {-1, -1};
	float leg_len[2][2] = {{0, 0}, {0, 0}};
	float leg_reach[2] = {0, 0}; // rest hip->ankle (skeleton units): the mesh's straight leg
	float scale = 0.01f; // skeleton units -> metres
	Pose work;

	// lock state
	bool locked[2] = {false, false};
	godot::Vector2 corr[2];       // foot-lock correction (world XZ, metres)
	godot::Vector3 prev_a[2], prev_t[2];
	bool have_prev[2] = {false, false};
	float foot_rest_h = 0.17f;    // ankle height standing (metres)
	float toe_rest_h = 0.05f;     // toe-ball height standing (metres)
	float released[2] = {0, 0};   // forced release timer (s)
	int releases = 0;
	godot::Vector3 foot_world[2];

	// smoothed layers
	float pelvis_drop = 0, pelvis_drop_v = 0;
	float acc_f = 0, acc_fv = 0, acc_s = 0, acc_sv = 0; // smoothed acceleration lean
	float lean_f = 0, lean_s = 0, lean_fv = 0, lean_sv = 0;
	float head_yaw = 0, head_yaw_v = 0;
	float lean_total_deg = 0, head_yaw_deg = 0;
	int ik_clamped = 0;
	int layers = 0xFF; // bit 0 lean, 1 foot ik, 2 head, 3 twist

	void find_bones();
	void leg_ik(godot::Skeleton3D *sk, int side, const godot::Vector3 &target_sk, const godot::Basis &foot_basis_sk,
			const godot::Vector3 &pole_sk);
};

} // namespace lab
