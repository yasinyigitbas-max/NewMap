// MoLayer: an UPPER-BODY LAYER (Yasin, 24 Nov: "walking text whenever we open the phone, and standing talk and walking
// talk when we take a call"). The legs play what the motor plays (idle, walk, starts, stops, turns, a seat); the chosen
// bones above the hips take another clip's own rotations (the phone's), at its own time, by a weight. One clip's motion,
// untouched, on a part of the body - the studios' "layered" upper body.
// A SkeletonModifier3D, put FIRST on the figure's skeleton: MoInertial (after it) smooths its hand-overs too, MoLimbs
// (last) still pins the feet and hands.
#pragma once

#include <godot_cpp/classes/animation.hpp>
#include <godot_cpp/classes/skeleton_modifier3d.hpp>

#include <vector>

namespace godot {

class MoLayer : public SkeletonModifier3D {
	GDCLASS(MoLayer, SkeletonModifier3D)

	struct B { int bone = -1; int track = -1; float w = 1.0f; };
	std::vector<B> mask;
	Ref<Animation> anim;
	int mask_kind = -1;

protected:
	static void _bind_methods() {}

public:
	double t = 0.0;      // the layer clip's time
	float weight = 0.0f; // 0: the legs' clip everywhere; 1: the masked bones are the layer clip's
	// the clip and the bones it plays on: 1 both arms, the head and (part of) the spine - texting; 2 the right arm and the
	// head - a call held to the right ear, the left arm swinging with the walk
	void set_layer(const Ref<Animation> &p_anim, int p_mask);
	void _process_modification_with_delta(double p_delta) override;
};

} // namespace godot
