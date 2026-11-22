// MoInertial: hand-overs between two clips without a crossfade (inertialization, D. Bollo, "Inertialization:
// High-Performance Animation Transitions in Gears of War", GDC 2018). The new clip plays at full weight at once; at the
// switch each bone's difference from the pose last drawn (and how fast that difference was changing) is kept, and it
// decays to nothing over the blend time on a quintic curve that starts at the old motion's speed and ends at rest. One
// pose is evaluated, not two, and a clip that carries its body in its hips (root motion) does not swing the hips through
// a blend with a loop drawn in place.
// A SkeletonModifier3D, the FIRST on the figure's skeleton (it sees the clip's own pose; IK comes after it). The
// figure's node may jump at the switch (a move re-anchored where the clip says): the root bones' difference is taken in
// the world, carried on at the speed they had, so the drawn body does not jump with the node.
#pragma once

#include <godot_cpp/classes/skeleton_modifier3d.hpp>
#include <godot_cpp/variant/quaternion.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <vector>

namespace godot {

class MoInertial : public SkeletonModifier3D {
	GDCLASS(MoInertial, SkeletonModifier3D)

	struct Bone {
		Vector3 p, p1;            // the pose drawn last frame and the frame before (local)
		Quaternion q, q1;
		Vector3 po; Quaternion qo;   // this frame's output so far (a frame can pose the skeleton more than once: its last counts)
		// the running offset: position (direction, quintic in its length) and rotation (axis, quintic in its angle)
		Vector3 pd; float px0 = 0.0f, pc[6] = {};
		Vector3 qa; float qx0 = 0.0f, qc[6] = {};
		float pT = 0.0f, qT = 0.0f;
		int parent = -1;
	};
	std::vector<Bone> bones;
	Transform3D sk_g, sk_g1;     // the skeleton's world transform last frame and the frame before
	Transform3D sk_go;           // this frame's
	uint64_t frame_id = ~0ull;   // the engine frame the outputs po / qo belong to
	float dt_frame = 1.0f / 60.0f;
	int frames = 0;              // poses recorded (two are needed for the speeds)
	bool pending = false;
	float pend_T = 0.2f;
	float t = 0.0f;              // since the switch
	bool live = false;           // an offset is decaying
	void start(Skeleton3D *sk, float dt);

protected:
	static void _bind_methods();

public:
	// the next pose the skeleton gets is a new clip: hand over to it over p_seconds (0.15-0.3 is usual)
	void inertialize(double p_seconds) { pending = true; pend_T = (float)std::max(p_seconds, 0.02); }
	bool is_blending() const { return live; }
	double get_left() const;   // seconds the running hand-over still has
	float last_jump = 0.0f;    // (the tests) the largest root-bone world difference taken at the last switch, m
	int switches = 0;          // (the tests)
	void _process_modification_with_delta(double p_delta) override;
	// a quintic from (x0, v0) to rest at T (Bollo): coefficients c[0..5] for t^0..t^5; returns the T used
	static float quintic(float x0, float v0, float T, float *c);
	static float eval(const float *c, float T, float t);
};

} // namespace godot
