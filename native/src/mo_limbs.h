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
	float step_pull = 0.04f, step_after = 0.15f, step_s = 0.3f, step_h = 0.06f;
	float step_t[2] = { -1.0f, -1.0f }, held[2] = { 0.0f, 0.0f };
	Vector3 step_from[2];
	int steps = 0;   // (the tests)
	bool stepping(int s) const { return step_t[s] >= 0.0f; }
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
