// A person's body that keeps its own balance, plain C++ (no Godot types). Written new on Yasin's word, 19 Nov 2026
// ("they need to balance themselves, be able to pushed around and resist falls, just like in the euphoria engine").
//
// When is it used: a walker of the crowd is animation while nothing touches it. The moment something does (a shove
// from the player, a car, another body flying into it) its pose and speed are handed to this body, which then IS the
// person until it stands quietly again (then animation takes over) or lies still (then it gets up).
//
// What it is: thirteen jointed bodies (pelvis, chest, head, upper arms, forearms, thighs, calves, feet) with a small
// physics of their own in here (position-based, 8 small steps a frame): the same on the PC and on the phone, no
// engine joints, a few microseconds a person. Around it:
//  - MUSCLES: every joint pulls toward a wanted pose (the animation's, or a reflex's) with a strength that can fade.
//  - BALANCE (state BALANCE): the upper body is real; the LEGS CARRY IT: they hold the hips up and push from one
//    point under the feet, and the body topples away from that point as a standing body does. It keeps itself up the
//    way a person does. It watches THE POINT ON THE GROUND IT IS FALLING TOWARD (where it is + its speed x a third
//    of a second). While that point is under its feet it only moves where it presses on them (toes, heels, one foot
//    or the other): small pushes are held without a step. When that point leaves its feet it STEPS, quickly, to
//    where the point will be when the foot comes down, and presses there; then again if it must: it staggers the
//    way it was pushed until its feet are under it. Then it shifts its weight onto one foot and brings the other
//    home. The hips hold the trunk upright; the arms swing with it.
//  - FALL (state FALL): when no step can catch it (pushed too hard, hit by a car, tripped) the legs become bodies too
//    and it goes down as a rag doll, but not limp at once: the arms reach for the ground on the side it falls to,
//    the neck holds the head off the ground, and the strength drains away over a second or so.
//  - REST: it lies still. The caller blends into the get-up animation from there.
// Its surroundings come from the caller every step: the ground (a plane here; the game gives the height under it) and
// moving boxes (cars) with their speed.
#pragma once

#include "veh_dyn.h"

namespace pb {

using vd::V3;
using vd::Q;

enum { B_PELVIS, B_CHEST, B_HEAD, B_UARM_L, B_FARM_L, B_UARM_R, B_FARM_R, B_THIGH_L, B_CALF_L, B_FOOT_L, B_THIGH_R, B_CALF_R, B_FOOT_R, NB };
enum { J_SPINE, J_NECK, J_SHOULDER_L, J_ELBOW_L, J_SHOULDER_R, J_ELBOW_R, J_HIP_L, J_KNEE_L, J_ANKLE_L, J_HIP_R, J_KNEE_R, J_ANKLE_R, NJ };
enum { ST_BALANCE, ST_FALL, ST_REST };
constexpr int MAX_BOXES = 8;

// The standing skeleton, metres: x = left, y = up, z = forward, the origin on the ground under the pelvis. [0] = left.
struct Rest {
	V3 pelvis{ 0, 0.879f, 0 }, waist{ 0, 1.10f, -0.006f }, neck{ 0, 1.505f, -0.012f }, head{ 0, 1.571f, 0.008f };
	float head_top = 1.77f;
	V3 shoulder[2] = { { 0.210f, 1.412f, -0.025f }, { -0.210f, 1.412f, -0.025f } };
	V3 elbow[2] = { { 0.416f, 1.214f, -0.019f }, { -0.416f, 1.214f, -0.019f } };
	V3 wrist[2] = { { 0.588f, 1.029f, 0.081f }, { -0.588f, 1.029f, 0.081f } };
	V3 hip[2] = { { 0.088f, 0.879f, 0 }, { -0.088f, 0.879f, 0 } };
	V3 knee[2] = { { 0.109f, 0.481f, 0.016f }, { -0.109f, 0.481f, 0.016f } };
	V3 ankle[2] = { { 0.117f, 0.085f, -0.015f }, { -0.117f, 0.085f, -0.015f } };
	float toe = 0.17f, heel = 0.06f;
	float mass = 72.0f;
};

struct Body {
	V3 x, v, w;          // centre, speed, spin (world)
	Q q;                 // turn from the standing pose (identity = as it stands)
	float m = 1, inv_m = 1, inv_i = 1;
	V3 a, b;             // the ends of its capsule, in its own frame (from its centre)
	float r = 0.05f;
	bool on = true;      // a real body now (the legs are not while they only carry)
	V3 x0; Q q0;         // at the start of the small step
};

struct Joint {
	int p = 0, c = 0;
	V3 ap, ac;           // where it sits, in the parent's and in the child's frame
	bool hinge = false;
	V3 axis;             // a hinge's axis (the same in both frames when standing)
	float lo = 0, hi = 0;   // a hinge's range, rad from the standing pose
	V3 bone;             // the child's own direction (for how far it may swing and twist)
	float swing = 1.5f, twist = 0.8f;
	Q want;              // the pose the muscle pulls to: the child's turn against the parent's (identity = standing)
	float kp = 0, kd = 0, tmax = 0;
};

struct Box {             // something solid that moves (a car): centre, half sizes, heading, speed
	V3 c, half, v;
	float yaw = 0, yaw_rate = 0;
};

struct Foot {
	V3 p;                // where the ankle stands over the ground
	bool planted = true;
	V3 from, to;         // a step in the air
	float t = 0, T = 0;
};

class Person {
public:
	Rest rest;
	Body b[NB];
	Joint j[NJ];
	Foot foot[2];
	int state = ST_BALANCE;
	// the caller's numbers
	float skill = 1.0f;          // how good its balance is: 1 = an able adult, 0.6 = old or drunk, 1.3 = an athlete
	V3 gn{ 0, 1, 0 }; float gd = 0;   // the ground: the plane gn . p = gd
	Box box[MAX_BOXES]; int n_box = 0;
	// told, for the caller and the tests
	int steps = 0;               // steps taken since it was last standing quietly
	float tilt = 0;              // how far the trunk leans, rad
	float quiet = 0;             // seconds it has been standing quietly (BALANCE) or lying still (FALL)
	float t_state = 0;           // seconds in this state
	float strength = 1.0f;       // the muscles' strength now (fades in a fall)
	bool settled = false;        // BALANCE and standing quietly for a while: animation may take over again
	bool face_up = true;         // lying on its back (REST)
	float max_speed = 0;         // the fastest any part has moved (tests: nothing may explode)
	float heading = 0;           // which way it faces, rad (0 = +z)

	void build(const Rest &p_rest);
	// Stand it at a place, facing a way, with a speed (what the animation had), in BALANCE
	void start(V3 at, float yaw, V3 vel);
	// A knock: an impulse (N s) on a part at a point of the world
	void impulse(int body, V3 point, V3 imp);
	void step(float dt);
	V3 com() const;
	V3 com_v() const;

private:
	float leg_len = 0.79f, leg_k = 0, leg_c = 0, leg_pre = 0, ankle_h = 0.085f, l_thigh = 0.4f, l_calf = 0.4f;
	float m_legs = 0;
	Q arm_down[2];
	V3 fall_dir;
	V3 lean_to; bool lean_on = false;   // BALANCE: the place it shifts its weight over (the foot that stays, before the other comes home)
	V3 cop;                              // BALANCE: the point under its feet it presses on now
	int last_step = -1;                  // BALANCE: the foot that stepped last
	float h_want = 0.9f;                 // BALANCE: how high its legs let its hips stand over where its feet are
	V3 support(V3 q, int only) const;    // the nearest point of what its planted feet cover (only = one foot, -1 = both)
	struct Hit { int body; V3 r, n, vb; float lam; };
	Hit hits[96]; int n_hits = 0;
	void sub(float h);
	void brain(float dt);
	void pose_legs();
	void go_fall();
	void muscles(float h);
	void carry(float h);
	void solve_joint(Joint &jt);
	void contacts();
	void pos_fix1(int i, V3 r, V3 n, float depth, V3 vb);
	void pos_fix2(int i, int k, V3 ri, V3 rk, V3 corr);
	void ang_fix2(int i, int k, V3 dphi);   // (dphi by value: it is cut to a small turn)
	float ground_y(float x, float z) const { return (gd - gn.x * x - gn.z * z) / gn.y; }
};

} // namespace pb
