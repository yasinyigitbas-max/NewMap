// MoLimbs: the limbs reached to the world after the clip and the hand-over have posed the figure (the new movement
// system; docs/ANIMATION_PLAN.md). A SkeletonModifier3D, right after MoInertial on the skeleton.
// FOOT LOCK: a foot the clip has down (mo_clip contacts, told each frame by the motor) is pinned where it landed
// until the clip lifts it, so it does not slide while the body turns, while two stances hand over (a stop into the
// idle moved a planted foot 10 cm), or where the clip's own feet drift. On lifting, the pin's offset fades over
// release_s so the foot does not snap. Two-bone IK (thigh, calf, foot), the knee toward where the clip has it, the
// foot keeping the clip's own turn. A pin further than max_pull from where the clip has the foot lets go (a teleport,
// a body moved by another system).
// HANDS (later steps: vault and climb edges, carried props): a target and a weight per hand, the same reach.
#pragma once

#include <godot_cpp/classes/skeleton_modifier3d.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class MoLimbs : public SkeletonModifier3D {
	GDCLASS(MoLimbs, SkeletonModifier3D)

	int b_th[2] = { -1, -1 }, b_ca[2] = { -1, -1 }, b_ft[2] = { -1, -1 };
	int b_ua[2] = { -1, -1 }, b_fa[2] = { -1, -1 }, b_hd[2] = { -1, -1 };
	bool found = false;
	void find_bones(Skeleton3D *sk);

protected:
	static void _bind_methods() {}

public:
	// ---- the feet (set by the motor each frame)
	bool lock_on = false;            // foot lock wanted at all (the motor's states that walk on the ground)
	bool down[2] = { false, false }; // the clip has the foot planted now
	float ground_y = -1e9f;          // the ground the body stands on (world y): a foot is pinned only near it (a hand-over can
	                                 // still hold a foot 25 cm up while the new clip has it down: pinned there, it was dragged)
	float pin_h = 0.15f;             // the ankle at most this high over the ground to be pinned
	float release_s = 0.15f, max_pull = 0.30f;
	// state (world)
	bool locked[2] = { false, false };
	Vector3 lock_w[2], rel_off[2];   // where a pinned foot is held; the offset fading after a release
	float rel_t[2] = { 9.0f, 9.0f };
	void unlock_all() { locked[0] = locked[1] = false; rel_t[0] = rel_t[1] = 9.0f; step_t[0] = step_t[1] = -1.0f; held[0] = held[1] = 0.0f; }
	// RE-PLANT: standing (the motor allows it: idle, the end of a stop), a planted foot held well off where the clip has
	// it (a hand-over from another stance: the feet kept the old one, the legs bent off the clip's for as long as he
	// stood) lifts and steps there: an arc step_h high over step_s, one foot at a time, then pinned again
	bool may_step = false;
	float step_pull = 0.04f, step_now = 0.12f, step_after = 0.15f, step_s = 0.3f, step_h = 0.06f;
	float step_t[2] = { -1.0f, -1.0f }, held[2] = { 0.0f, 0.0f };
	Vector3 step_from[2];
	int steps = 0;   // (the tests)
	bool stepping(int s) const { return step_t[s] >= 0.0f; }
	// ---- the ground under each foot (the motor's rays, each frame): the foot fitted to it, the hips dropped for the
	// lower one, the sole turned onto its slope
	Vector3 fwd_w = Vector3(0, 0, 1);   // the way he faces (world): the knees bend that way
	Vector3 knee_pole(Skeleton3D *p_sk, const Transform3D &p_gi, const Vector3 &p_clip) const;
	bool fit_on = false;
	float fit_off[2] = { 0.0f, 0.0f };   // m, the clip's foot moved up / down to the ground there (already weighted)
	float fit_w[2] = { 0.0f, 0.0f };     // how much the clip has that foot on its floor (0 in the swing)
	Vector3 place_off[2];                // a level move of the foot's landing (off a step's face; the motor's)
	float floor_y[2] = { -1e9f, -1e9f };   // world: the lowest the ankle may be drawn - the ground under the foot plus a sole (never into it)
	float fit_y[2] = { 0.0f, 0.0f };     // world: the clip's own foot height on the ground there (no hand-over offset): a pin's height
	float lock_t[2] = { 9.0f, 9.0f };    // since a foot was pinned (its height eased onto fit_y over 0.1 s)
	Vector3 ground_n[2] = { Vector3(0, 1, 0), Vector3(0, 1, 0) };
	float drop = 0.0f, drop_v = 0.0f, drop_slack = 0.01f, drop_max = 0.35f, drop_down = 20.0f, drop_up = 9.0f;   // the hips lowered (m), its spring (rad/s down, up)
	int b_root = -1;
	uint64_t frame_id = ~0ull; float dt_frame = 1.0f / 60.0f;
	// ---- a thing held (the motor's carry): where it is held from the hips (his facing hold_yaw), placed on the hips AS
	// DRAWN, with the hands on it; the thing's node placed here too, in the same pass
	int hold_kind = 0;                 // 0 nothing, 1 a box (both hands on its sides), 2 a bag (the right hand on its handle)
	float hold_w = 0.0f, hold_yaw = 0.0f, box_w = 0.4f, box_d = 0.3f;
	Vector3 hold_l;                    // the hold point from the hips (his facing frame), m
	Transform3D hold_xf;               // where it was drawn (world)
	float ear_w = 0.0f;
	float hand_prop_face = 0.0f;   // (0..1: the phone turned upright, its screen to his eyes - eased in once it is out)
	bool hand_prop_both = false;
	bool hand_prop_two = false;    // (texting standing or seated: both hands brought to the phone; walking: the one-hand take)
	float two_w = 0.0f; bool two_owned = false;   // (texting with both hands: the phone between them, its screen to his eyes)   // (a call: the right hand held at the right ear as drawn, by this weight)
	Node3D *hand_prop = nullptr; bool hand_prop_on = false; Transform3D hand_prop_off;   // (a thing in the right hand - the phone: on the hand as drawn, last)
	Node3D *prop = nullptr;            // the thing's node (the game's), placed at hold_xf (a bag hangs 0.2 m under the hand)
	int b_pel = -1, b_head = -1, b_fing[2] = { -1, -1 }, b_lfing = -1; bool prop_owned_hands = false;
	// ---- the hands
	Vector3 hand_target[2]; float hand_w[2] = { 0.0f, 0.0f };
	// (the tests) how far each foot was moved from the clip's place this frame, m; locks taken
	float pull[2] = { 0, 0 };
	Vector3 pull_v[2];   // pinned place less the clip's place (world): the body follows its planted feet by it (the motor)
	int locks = 0;
	void _process_modification_with_delta(double p_delta) override;
	// a two-bone reach in skeleton space: a -> b -> c, c to the target, b toward the pole; c keeps its global turn
	static void reach(Skeleton3D *sk, int a, int b, int c, const Vector3 &p_target, const Vector3 &p_pole);
};

} // namespace godot
