// mo_clip: what a clip does with the body, measured once from its own tracks (the new movement system, docs/
// ANIMATION_PLAN.md; .claude/skills/coronado-animation). For every clip a figure plays: the hips, feet, toes and hands
// 30 times a second in the figure's frame (the node the figure stands on: faces +z, +x its left), the body's facing,
// each foot's and hand's speed over the ground, and which feet are down. Shared by every figure of the same skeleton
// (the clips are the same resources), made the first time a clip is asked for.
// Used for: the hand-over moment and entry frame between two clips (pose matching: the feet where they are, going the
// way they go), foot contacts (no warping while a foot is down), and later the hand contacts of a vault or climb.
#pragma once

#include <godot_cpp/classes/animation.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <vector>

namespace godot {
namespace mo {

enum { L = 0, R = 1 };

struct Frame {
	Vector3 hips, foot[2], toe[2], hand[2];   // figure frame, m
	float face = 0.0f;                        // the hips' facing (rad, from the thighs; 0 = +z, + to his left)
	Vector3 foot_v[2], hand_v[2], hips_v;     // over the ground, m/s (an in-place clip's own travel added back)
	bool down[2] = { false, false };          // the foot is planted
};

struct ClipData {
	double len = 0.0;
	bool loop = false, in_place = false;       // in_place: the travel was taken out of the hips into vz / vx / yaw
	// the converter's "yaw" curve is the body's turn only when the pose does not turn by itself: a raw Mixamo stop's
	// pose turns -43 degrees AND its yaw says -47 (played both, the body turned twice). False: ignore "yaw".
	bool yaw_turns = true;
	float yaw(double t) const;                  // the body's turn by t (0 when the pose holds it), rad
	float ground_y = 0.0f;                      // the lowest foot over the whole clip (its floor)
	std::vector<Frame> f;                       // 30 a second, f.size() = round(len * 30) + 1
	// THE BODY'S TRAVEL READ FROM ITS FEET (an in-place clip): while a foot is down the body moves so that foot stays
	// still on the ground (its speed against the hips, and the clip's own turn, undone); with both feet up, the clip's
	// own vz / vx. Figure frame (it turns with the clip's yaw), m/s, a little smoothed. The converter's smooth pace curve
	// does not match the feet: moved by it, a run stop's hips went back 2 cm for two frames and planted feet slid 6-12 cm.
	std::vector<Vector3> root_v;
	std::vector<float> yaw_c;                   // the "yaw" curve at 30 Hz (empty: none)
	Vector3 root_vel(double t) const;
	const Frame &at(double t) const;            // the nearest frame (no blend: for costs and contacts)
	Frame lerp(double t) const;                 // blended between frames
	int idx(double t) const;
};

static const double FPS = 30.0;

// The data for a clip on a skeleton (skel_in_node: the skeleton in the figure's node frame). Never null for a valid
// animation; made once per Animation resource.
const ClipData *clip_data(const Ref<Animation> &p_anim, Skeleton3D *p_skel, const Transform3D &p_skel_in_node);

// How unlike two moments are (the feet relative to the hips and how they move, the hips' height; in each one's own
// facing). 0 = the same pose and motion.
float pose_cost(const Frame &a, const Frame &b);

// The moment of B in [lo, hi] most like A at ta (a loop wraps; step 1/30 s). r_cost: its cost.
double best_entry(const ClipData &A, double ta, const ClipData &B, double lo, double hi, float *r_cost = nullptr);

} // namespace mo
} // namespace godot
