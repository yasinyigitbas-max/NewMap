// HandGrip: the player's hands on a ledge's edge while he climbs (Yasin, 20 Nov: "make sure the characters hands follow
// the edge and clinch to the edge of the surface on climbs"). A skeleton modifier on his figure, after the clip has posed
// him: each arm reached to its point on the edge (shoulder, elbow, wrist: a two-bone reach, the elbow out and down), the
// hand turned palm down onto the top, its fingers curled over the edge. CityPlayer sets the points and how much (0..1).
#pragma once

#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/classes/skeleton_modifier3d.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class HandGrip : public SkeletonModifier3D {
	GDCLASS(HandGrip, SkeletonModifier3D)
	int b_ua[2] = { -1, -1 }, b_fa[2] = { -1, -1 }, b_hd[2] = { -1, -1 };
	int b_fing[2][15];
	int n_fing[2] = { 0, 0 };
	bool found = false;
	void find_bones(Skeleton3D *sk);
	void reach(Skeleton3D *sk, int a, int b, int c, const Vector3 &target, const Vector3 &pole);

protected:
	static void _bind_methods() {}

public:
	Vector3 grip[2];     // world: the left and the right hand's place on the edge
	Vector3 out;         // world: the way off the edge, out over the drop (toward the climber), level
	Vector3 side;        // world: the climber's left
	float curl = 1.25f;  // rad: how far each finger joint bends over the edge
	bool one_hand = false;   // a fence's rail: the left hand only
	bool held[2] = { false, false };   // each hand on its point now (within its reach); else it is letting go
	float miss[2] = { 0, 0 };   // (the tests) how far each wrist ended from its point, metres
	float tip_dy[2] = { 0, 0 }; // (the tests) the middle finger's tip over (+) or under (-) the edge's top, metres
	void _process_modification_with_delta(double p_delta) override;
};

// FootPlant: the player's feet on what is under them (Yasin, 20 Nov: "make their feet align automatically with collision
// like the hands with climbs"). After the clip: a ray down under each foot finds the ground; a foot over lower ground
// takes the hips down with it (so both reach), each leg is reached so its sole is on its ground (a step, a kerb's edge,
// a slope, the top of a climb). Off when he is in the air.
class FootPlant : public SkeletonModifier3D {
	GDCLASS(FootPlant, SkeletonModifier3D)
	int b_pel = -1, b_th[2] = { -1, -1 }, b_ca[2] = { -1, -1 }, b_ft[2] = { -1, -1 }, b_toe[2] = { -1, -1 };
	float ankle_h = 0.08f;
	bool found = false;
	void find_bones(Skeleton3D *sk);
protected:
	static void _bind_methods() {}
public:
	RID skip;              // the player's own body (not ground)
	Vector3 fwd;           // world: the way he faces (the knees forward)
	float hips_drop = 0.0f, foot_off[2] = { 0, 0 };
	// the node standing on the clip's floor (the figure), when the skeleton is not at its feet (the player's: its origin is
	// at the hips, so the ground fit took every foot as 0.8 m off and did nothing; Yasin 22 Nov, slopes); null: the
	// skeleton's origin. (It holds the skeleton: it outlives this modifier.)
	Node3D *floor_node = nullptr;
	float d_s[2] = { 0, 0 }, drop_s = 0.0f, tilt_w[2] = { 0, 0 };   // (tilt_w: how far a foot's sole is turned onto the slope under it, eased)
	Vector3 gn[2] = { Vector3(0, 1, 0), Vector3(0, 1, 0) }, sole_w[2][2];   // (the ground's normal under each foot; (traces) its heel and ball as drawn, world)   // (the fit eased: a foot's height change and the hips' drop, over 0.06 / 0.08 s; on a slope they jumped as a foot came down or lifted: the hips 0.2-0.3 m a frame)
	Vector3 foot_w[2], toe_w[2], pelvis_w, slide_w[2];   // (traces) the feet and hips as drawn this frame, world
	// FOOT LOCK (Yasin, 20 Nov: "i want them pixel perfect"; a planted foot slid on the ground with the clip): a foot the clip
	// puts down is pinned where it landed until it lifts; on lifting, the rest of the pin's offset fades in 0.1 s
	bool locked[2] = { false, false };
	bool lock_on = true;   // (off for the player's pwalk clips: they plant their own feet, and the pin's catch-up popped them: Yasin, 21 Nov "why are those jerks")
	Vector3 lock_w[2], rel_off[2], prev_fw[2], prev_root;
	float toe_y0[2] = { 0, 0 };   // the ball of the foot's height over the floor as it was pinned (it is held while it stays down)
	float rel_t[2] = { 0, 0 };   // since the pin let go
	bool have_prev = false;
	uint64_t last_us = 0;
	float gap_sum = 0.0f, gap_most = 0.0f; int gap_n = 0, gap_by_lift = 0;   // (traces) the pins' gaps as they let go   // (the tests) how far the hips went down, how far each sole ended from its ground
	// THE GROUND UNDER EACH FOOT IS ASKED IN THE PHYSICS STEP (21 Nov): on the phones physics runs on its own thread and the
	// world's collision can be asked only then ("Space state is inaccessible right now", 35,000 a minute on the S23: no foot
	// ever planted there). The step casts each foot's ray where the clip will have it by the next drawn frame (its last place
	// plus its own speed); the modifier takes the answer when it was cast within 30 cm of the foot's place now.
	Vector3 clip_fw[2], clip_v[2];   // the clip's foot as last drawn, world, and how fast it moves
	Vector3 probe_at[2], probe_n[2] = { Vector3(0, 1, 0), Vector3(0, 1, 0) }; float probe_y[2] = { 0, 0 }; bool probe_hit[2] = { false, false }, probe_ok[2] = { false, false };
	int probes = 0;   // (the tests) rays cast in the physics step
	void _ready() override;
	void _physics_process(double p_delta) override;
	void _process_modification_with_delta(double p_delta) override;
	void reset() { locked[0] = locked[1] = false; rel_off[0] = rel_off[1] = Vector3(); have_prev = false; d_s[0] = d_s[1] = drop_s = 0.0f; tilt_w[0] = tilt_w[1] = 0.0f; }   // (another person in the same figure)
};

// Posture: everyone's shoulders forward (Yasin, 20 Nov: "everyones shoulders are too far back, push all of them both player
// and npcs shoulders forward"). The first modifier on every CityPed figure (player, crowd, riders): after the clip, each
// collarbone is turned round the chest's own up (pelvis to neck) so the shoulder joint comes forward; the arm follows.
class Posture : public SkeletonModifier3D {
	GDCLASS(Posture, SkeletonModifier3D)
	int b_cl[2] = { -1, -1 }, b_ua[2] = { -1, -1 }, b_pel = -1, b_neck = -1;
	bool found = false;
protected:
	static void _bind_methods();
public:
	float angle = 0.21f;   // rad (12 degrees): how far each collarbone turns forward
	float moved[2] = { 0, 0 };   // (the tests) how far each shoulder joint came forward this frame, metres
	void set_angle(float a) { angle = a; }
	float get_angle() const { return angle; }
	float get_moved() const { return 0.5f * (moved[0] + moved[1]); }
	void _process_modification_with_delta(double p_delta) override;
};

} // namespace godot
