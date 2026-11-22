// BodyLayer: the player's upper body on top of his legs' clip (Yasin, 22 Nov, the outdoor moves: carrying, the look-at).
// A skeleton modifier after his clip, the foot plant and the hand grip:
//  - CARRY: the arms (one: the right; or both and the spine) take their pose from a carry take (the Mixamo box / briefcase
//    clips: tools/people/make_player_actions.gd, "pact/...") while the legs keep his walk / run / idle, its starts, stops
//    and turns (so nothing of the tuned locomotion changes under a carry). The prop (map_dc/coronado/city_kit/carry,
//    page J) is drawn in his hand: one hand, its grip_r at the right palm, hanging (up stays up, its handle along his
//    way); two hands (boxes, crates), its middle between his palms, clear of his chest, and each arm reached to its grip
//    on the prop's sides.
//  - LOOK-AT: the neck and head turned toward a point (a person passing, a shop window), at most 70 degrees round and
//    30 up / down, eased.
#pragma once

#include <godot_cpp/classes/animation.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/classes/skeleton_modifier3d.hpp>
#include <godot_cpp/variant/aabb.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <vector>

namespace godot {

class BodyLayer : public SkeletonModifier3D {
	GDCLASS(BodyLayer, SkeletonModifier3D)
	bool found = false;
	int b_sp[3] = { -1, -1, -1 }, b_neck = -1, b_head = -1;
	int b_cl[2] = { -1, -1 }, b_ua[2] = { -1, -1 }, b_fa[2] = { -1, -1 }, b_hd[2] = { -1, -1 }, b_f2[2] = { -1, -1 };
	std::vector<int> arm_bones[2];   // each side's clavicle, arm, hand and fingers
	Animation *track_of = nullptr;   // (the clip the map below is for)
	std::vector<int> trk;            // bone -> its rotation track in the clip (-1: none)
	Animation *track_prev_of = nullptr; std::vector<int> trk_prev;
	void find_bones(Skeleton3D *sk);
	void overlay(Skeleton3D *sk);
	void place_prop(Skeleton3D *sk);
	void look(Skeleton3D *sk, float dt);
protected:
	static void _bind_methods() {}
public:
	// the carry: the take its arms come from and the moment in it; 1: the right arm, 2: both arms and the spine
	Ref<Animation> clip; double t = 0.0; int mask = 0; float w = 0.0f;
	Node3D *prop = nullptr; uint64_t prop_id = 0;   // (top-level: drawn where the hands are; the player owns it)
	bool two = false; Transform3D grip_r, grip_l; AABB col;
	float blend = 1.0f; Transform3D from;   // (taken up: the prop goes from where it lay to his hands)
	// (the previous carry take, cross-faded out over 0.25 s as another takes over)
	Ref<Animation> clip_prev; double t_prev = 0.0; float x = 1.0f;
	Vector3 fwd = Vector3(0, 0, 1);   // world: his way
	// the look-at
	bool look_on = false; Vector3 look_p; float look_w = 0.0f, look_yaw = 0.0f, look_pitch = 0.0f;
	// (the tests) how far each palm ended from its grip on the prop, metres; the prop's gap to his chest
	float miss[2] = { 0, 0 }, chest_gap = 0.0f, fit_min = 1.0f;
	void _process_modification_with_delta(double p_delta) override;
};

} // namespace godot
