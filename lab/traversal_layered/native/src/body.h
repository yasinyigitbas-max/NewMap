// Lab B: the body model and every measurement of study v2 Part 1, on world-space bone transforms.
// One set of functions is used by the validator (9.1), the final limiter (10.2) and the clip audit, so they can't
// disagree at the edges (v2 1.5). DECISIONS 8.x.
#pragma once

#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/variant/basis.hpp>
#include <godot_cpp/variant/quaternion.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <vector>

namespace lab {

static const float RAD = 0.017453292519943295f;
static const float DEG = 57.29577951308232f;

enum SolePt { HEEL = 0, BALL_IN = 1, BALL_OUT = 2, TOE_TIP = 3, SOLE_N = 4 };

// Bone indices on player_v3 (Meshy names) under the study's Mixamo names (v2 1.1, 12.5).
struct BodyBones {
	int hips = -1, lumbar_top = -1 /*Spine1 = Spine01*/, spine_low = -1 /*Spine02*/, chest = -1 /*Spine2 = Spine*/;
	int neck = -1, head = -1, head_end = -1;
	int up[2] = {-1, -1}, lo[2] = {-1, -1}, foot[2] = {-1, -1}, toe[2] = {-1, -1};
	int clav[2] = {-1, -1}, arm[2] = {-1, -1}, farm[2] = {-1, -1}, hand[2] = {-1, -1};
	int finger[2][4][3]; // index, middle, ring, pinky x 3 joints (thumb not measured: own axes)
	int knuckle_mid[2] = {-1, -1};
};

// Everything captured once on the runtime skeleton's rest (v2 1.0, 1.2). Index 0 = left, 1 = right.
struct BodyModel {
	BodyBones b;
	int bone_count = 0;
	std::vector<int> parent;
	std::vector<godot::Transform3D> rest_g;    // skeleton-space global rest
	std::vector<godot::Basis> anat_local;      // anatomical frame (x = body left, y = up, z = forward) in each bone's frame
	std::vector<float> bone_len;               // metres, parent origin -> origin
	float unit = 0.01f;                        // skeleton units -> metres (Armature scale)
	// legs
	godot::Vector3 knee_hinge_local[2];        // in UpLeg's frame (v2 1.2, 1.3)
	godot::Vector3 knee_hinge_shin_local[2];   // in Leg's frame
	float knee_rest_signed[2] = {0, 0};        // the rig's own bent rest (player_v3: knee bones bent, mesh straight)
	float knee_rest_varus[2] = {0, 0};
	godot::Vector3 thigh_dir0[2];              // rest hip->knee, anatomical (= world at rest)
	godot::Vector3 sole_local[2][SOLE_N];      // heel in Foot's frame; balls and toe tip in ToeBase's frame (v2 1.1)
	godot::Vector3 foot_F0[2], foot_U0[2];     // rest foot forward / sole up (anatomical)
	godot::Vector3 toe_dir0[2];
	float ankle_rest[2][3] = {{0, 0, 0}, {0, 0, 0}}; // dorsi, abd, roll of the rest foot in the shin frame
	float trunk_rest_fwd = 0, trunk_rest_side = 0; // the rig's upright stance (neck base sits behind the hips)
	float leg_reach[2] = {0, 0};               // rest hip -> ankle, metres (the mesh's straight leg)
	float thigh_len[2] = {0, 0}, shin_len[2] = {0, 0};
	// arms
	godot::Vector3 arm_dir0[2], farm_dir0[2], hand_dir0[2];
	godot::Vector3 elbow_hinge_local[2];       // in Arm's frame
	float elbow_rest_signed[2] = {0, 0};
	godot::Vector3 finger_dir0[2][4][3];
	bool ok = false;
	godot::String error;

	bool init(godot::Skeleton3D *sk);
};

// The measured pose (degrees, metres, world space). Signs as v2 Part 1.
struct Measures {
	// legs [side]
	float knee_flex[2], knee_varus[2], knee_twist[2];
	float hip_flex[2], hip_abd[2], hip_rot[2];
	float ankle_dorsi[2], ankle_inv[2], foot_abd[2], toe_bend[2];
	float knee_over_toe[2];
	float leg_extension[2];                    // hip->ankle / rest reach
	// spine, neck
	float lumbar_flex, lumbar_side, lumbar_twist;
	float thor_flex, thor_side, thor_twist;
	float neck_flex, neck_side, neck_turn;
	// arms [side]
	float sh_elev[2], sh_back[2], sh_across[2], sh_twist[2];
	float elbow_flex[2], forearm_twist[2], wrist_flex[2], wrist_dev[2];
	float finger_min, finger_max_excess;       // most negative joint; most degrees past its limit
	// whole body
	godot::Vector3 com, pelvis_c, neck_base, head_pos;
	godot::Vector3 pelvis_f, pelvis_l;         // world, flattened
	float trunk_fwd, trunk_side;               // pelvis centre -> neck base against vertical, signed by pelvis frame
	float head_roll, head_pitch;
	godot::Vector3 sole_w[2][SOLE_N];
	godot::Vector3 foot_U[2], foot_F[2];
	float pelvis_yaw;                          // radians, world
	float max_bone_len_err_mm;
	int worst_bone;
};

void measure(const BodyModel &m, const godot::Transform3D *W, Measures &out);

// world-space global transforms of every bone (orthonormalised bases, metres)
void world_pose(const BodyModel &m, godot::Skeleton3D *sk, std::vector<godot::Transform3D> &W);

// helpers shared with the limiter
godot::Basis anat(const BodyModel &m, const godot::Transform3D *W, int bone);
float signed_angle(const godot::Vector3 &a, const godot::Vector3 &b, const godot::Vector3 &axis);
godot::Quaternion arc(const godot::Vector3 &a, const godot::Vector3 &b);
void swing_twist(const godot::Quaternion &q, const godot::Vector3 &axis, godot::Quaternion &swing, float &twist_rad);

// segment capsules (v2 2.4)
struct Capsule {
	godot::Vector3 a, b;
	float r;
	int id;
};
enum CapId { CAP_TRUNK, CAP_THIGH_L, CAP_THIGH_R, CAP_SHIN_L, CAP_SHIN_R, CAP_UARM_L, CAP_UARM_R, CAP_FARM_L, CAP_FARM_R, CAP_HEAD, CAP_N };
void capsules(const BodyModel &m, const godot::Transform3D *W, const Measures &me, Capsule *out);
float seg_seg_dist(const godot::Vector3 &p1, const godot::Vector3 &q1, const godot::Vector3 &p2, const godot::Vector3 &q2);

} // namespace lab
