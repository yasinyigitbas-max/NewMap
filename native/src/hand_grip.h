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
	int b_pel = -1, b_th[2] = { -1, -1 }, b_ca[2] = { -1, -1 }, b_ft[2] = { -1, -1 };
	float ankle_h = 0.08f;
	bool found = false;
	void find_bones(Skeleton3D *sk);
protected:
	static void _bind_methods() {}
public:
	RID skip;              // the player's own body (not ground)
	Vector3 fwd;           // world: the way he faces (the knees forward)
	float hips_drop = 0.0f, foot_off[2] = { 0, 0 };   // (the tests) how far the hips went down, how far each sole ended from its ground
	void _process_modification_with_delta(double p_delta) override;
};

} // namespace godot
