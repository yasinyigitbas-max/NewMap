// Lab A (procedural): the poser. A SkeletonModifier3D that turns the motor's world targets into the full-body pose:
// pelvis, spine, head, two-bone IK legs and arms with the study's joint limits, foot roll, toes, forearm twist,
// fingers. One solver for everything (brief A). Runs every drawn frame on the interpolated targets (6.5).
#pragma once

#include "motor.h"

#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/classes/skeleton_modifier3d.hpp>

#include <vector>

namespace godot {
class LabPlayer;

class LabPoser : public SkeletonModifier3D {
	GDCLASS(LabPoser, SkeletonModifier3D)

public:
	struct Metrics {
		float slide_max_cm = 0; // planted-foot slide (4.6 item 1)
		float hips_pop_max_cm = 0; // hips jump per frame relative to the body (4.6 item 5)
		int joint_violations = 0; // frames x joints past the study's ranges (1.1)
		int knee_violations = 0, ankle_violations = 0, hip_violations = 0, elbow_violations = 0;
		float knee_max_deg = 0, ankle_up_max_deg = 0, ankle_down_max_deg = 0, hip_flex_max_deg = 0, hip_ext_max_deg = 0;
		float elbow_max_deg = 0;
		int frames = 0;
		float cur_hip[2] = { 0, 0 }, cur_knee[2] = { 0, 0 }, cur_ankle[2] = { 0, 0 };
		int slide_frame = -1, slide_foot = -1, slide_kind = -1, pop_frame = -1;
	};

	bool bind_player(LabPlayer *p);
	lab::BodyDims dims() const { return dims_; }
	Metrics metrics;
	void reset_metrics();
	bool is_bound() const { return bound; }

	void _process_modification_with_delta(double p_delta) override;

protected:
	static void _bind_methods() {}

private:
	LabPlayer *player = nullptr;
	bool bound = false;
	lab::BodyDims dims_;
	int b_hips = -1, b_spine[3] = { -1, -1, -1 }, b_neck = -1, b_head = -1;
	int b_leg[2][4];
	int b_arm[2][4];
	struct Finger {
		int bone;
		float curl; // radians
	};
	std::vector<Finger> fingers[2];
	std::vector<Transform3D> rest_g; // global rest (skeleton space)
	std::vector<Transform3D> rest_l; // local rest
	float rest_foot_yaw[2] = { 0, 0 };
	// metric state
	int last_contact[2] = { -1, -1 };
	Vector3 contact_start[2];
	Vector3 last_hips_rel;
	bool have_last = false;

	void measure(Skeleton3D *sk);
	Vector3 child_origin(const Transform3D &parent_g, int bone) const { return parent_g.xform(rest_l[bone].origin); }
	void solve_two_bone(const Vector3 &root, const Vector3 &target, float l1, float l2, const Vector3 &pole,
			Vector3 &mid, Vector3 &end, float soft) const;
};

} // namespace godot
