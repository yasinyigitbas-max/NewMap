// CityBike: a bicycle the player rides, all C++ (Yasin, 19 Nov: "make a rideable bike for the player, make sure its
// designed for touch controls, make sure it moves realistic like the cars, our view should wobble riding it. add damage
// to the bikes, we should be able to get ejected if we hit a car hard enough. use all relevant animations"; "for crashes
// and ejection use your ragdoll system").
//
//  - THE BODY is one of the engine's rigid bodies (it does the crashes); this class works out how the bicycle goes, as
//    CityCar does for a car: two wheel rays on the ground, the steering of a single-track vehicle (the front wheel's
//    angle, the wheelbase: the turn), the lean a rider takes into a turn (as fast and as far as the turn asks, with a
//    little lag and overshoot), pedalling by power (a rider's watts, not a fixed push), brakes front and rear (the
//    rear wheel locks and slides), rolling resistance, the air, the slope. Grip limits the turn: too fast into one and
//    it slides.
//  - THE RIDER is a near figure (CityPed) with the Quaternius clips: getting on (Sitting_Enter), riding (Driving_Loop
//    for the arms and back), getting off (Sitting_Exit); his feet and hands are reached to the pedals and grips every
//    frame by BikeReach (a skeleton modifier, below), the feet going round with the crank.
//  - CRASHES: a knock that changes the bicycle's speed by 4.5 m/s in a step (a car, a wall), or a fall past 60 degrees,
//    throws the rider: his figure is handed to its balancing body (ped_body.h: he flies, tumbles, lands, lies) with the
//    speed he had and the blow, gets up by itself (LayToIdle), and the player walks from there. The bicycle goes on
//    as a loose body and falls. Never a clip for the fall itself.
//  - DAMAGE from every knock: past 30 the front wheel is bent (the bar wobbles as it turns), past 70 the chain is off
//    (pedalling does nothing), at 100 it cannot be ridden.
//  - THE VIEW: a camera behind and above that follows like the car's, and wobbles: it rolls with the lean, sways and
//    bobs with the pedalling (harder when sprinting), shakes over bumps.
//  - CONTROLS. Touch: the left half of the screen steers (a thumb slid sideways from where it landed); the right half
//    is the brake (inner) and the pedals (outer: slide the thumb up to sprint); the top right corner gets on or off.
//    A small overlay shows the zones while riding (touch_hud). Keys: W pedal, S brake, A D steer, Shift sprint, E on /
//    off; a pad: right trigger pedal, left trigger brake, stick steers, A sprint, X on / off.
#pragma once

#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/canvas_layer.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/classes/physics_direct_body_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/physics_shape_query_parameters3d.hpp>
#include <godot_cpp/classes/sphere_shape3d.hpp>
#include <godot_cpp/classes/rigid_body3d.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/classes/skeleton_modifier3d.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class CityPed;
class CityPlayer;
class MeshInstance3D;

// The rider's feet to the pedals and hands to the grips, after the clip has posed him (a two-bone reach each: hip,
// knee, ankle with the knee forward; shoulder, elbow, wrist with the elbow out and down), his back leant over the bars.
class BikeReach : public SkeletonModifier3D {
	GDCLASS(BikeReach, SkeletonModifier3D)
	int b_spine = -1, b_th[2] = { -1, -1 }, b_ca[2] = { -1, -1 }, b_ft[2] = { -1, -1 }, b_ua[2] = { -1, -1 }, b_fa[2] = { -1, -1 }, b_hd[2] = { -1, -1 };
	bool found = false;
	void find_bones(Skeleton3D *sk);
	void reach(Skeleton3D *sk, int a, int b, int c, const Vector3 &target, const Vector3 &pole);

protected:
	static void _bind_methods() {}

public:
	Vector3 foot[2], hand[2];    // world: left, right
	Vector3 lean_axis;           // world: the axis the back leans about (the bicycle's left)
	float lean = 0.0f;           // rad, the back over the bars (at least)
	float lean_used = 0.0f;      // what it took for the hands to reach the grips
	float hand_turn = 1.5707963f;   // each hand turned about its forearm, rad (+ = to the right, seen from behind the rider)
	Vector3 hips_w, shoulder_w, foot_w;   // (the tests) world places after the reach: the pelvis, the left shoulder, the left foot
	float miss_foot[2] = { 0, 0 }, miss_hand[2] = { 0, 0 };   // how far each ended from its target, m (the tests)
	void _process_modification_with_delta(double p_delta) override;
};

class CityBike : public RigidBody3D {
	GDCLASS(CityBike, RigidBody3D)

public:
	enum { ST_PARKED = 0, ST_MOUNT = 1, ST_RIDE = 2, ST_DISMOUNT = 3, ST_THROWN = 4 };

private:
	bool made = false, player = false, chase_camera = true, touch_hud = false;
	Color paint = Color(0.45f, 0.02f, 0.02f);
	String rider_body = "M1";
	uint64_t player_id = 0;       // the CityPlayer who rides it (hidden and still while he rides)
	int state = ST_PARKED;
	float st_t = 0.0f;
	// controls: 0..1 pedal, 0..1 brake, -1 (right) .. 1 (left) steer, 0..1 sprint
	float c_pedal = 0, c_brake = 0, c_steer = 0, c_sprint = 0;
	bool scripted = false, want_toggle = false, e_was = false;
	int t_steer_id = -1; float t_steer_x0 = 0, t_steer = 0;
	int t_zone[16] = { 0 }; float t_y0[16] = { 0 };   // per finger: 0 none, 1 brake, 2 pedal, 3 on/off; where it landed
	bool t_sprint = false;
	// the bicycle's own state
	float speed = 0.0f;           // m/s along its way
	float steer = 0.0f;           // the front wheel's angle, rad (+ = left)
	float lean = 0.0f, lean_v = 0.0f;   // the lean it is to have, rad (+ = left side up, as the traffic's rows)
	float crank = 0.0f;           // rad
	float wheel_ang = 0.0f;
	bool on_ground = false, fallen = false;
	float damage = 0.0f, hardest = 0.0f;
	Vector3 last_set_v, hit_v, pre_hit_v, thrown_v;   // (pre_hit_v: how it went the step before a knock: what the rider keeps)
	bool hit_now = false;
	float bump = 0.0f;            // how hard the ground pushes it about (for the view)
	float y_ground = 0.0f;
	double odo = 0.0;
	int throws = 0, vaults = 0;   // riders thrown; of them, over what they hit
	// the rider
	CityPed *rider = nullptr;
	BikeReach *reach_mod = nullptr;
	float clip_in = 1.0f, clip_out = 1.0f;
	// drawing and collision
	MeshInstance3D *mi = nullptr;
	Ref<ShaderMaterial> mat;
	// the beach cruiser's rig (bike_look.h): its parts turn: the crank with the pedalling (the pedals stay level), the
	// wheels with the way gone, the bars and front wheel about the steering axis
	class Node3D *rig = nullptr, *p_crank = nullptr, *p_pedal[2] = { nullptr, nullptr }, *p_steer = nullptr, *p_wheel[2] = { nullptr, nullptr };
	Transform3D r_crank, r_pedal[2], r_steer, r_wheel[2];
	void pose_parts(double p_delta);
	Ref<PhysicsRayQueryParameters3D> rq;
	Ref<class SphereShape3D> q_sphere;
	Ref<class PhysicsShapeQueryParameters3D> q_shape;
	// the view
	Camera3D *cam = nullptr;
	Vector3 cam_pos, cam_look;
	float cam_yaw = 0.0f, cam_roll = 0.0f, cam_bob = 0.0f, wobble_most = 0.0f;
	bool cam_set = false;
	CanvasLayer *hud = nullptr;

	void make();
	void read_player();
	void throw_rider(const Vector3 &p_blow);
	void place_rider(double p_delta);
	void view(double p_delta);
	void make_hud();
	static void zones(const Vector2 &sz, Rect2 r[4]);
	CityPlayer *the_player() const;
	void mount();
	void dismount();

protected:
	static void _bind_methods();

public:
	void _ready() override;
	void _input(const Ref<InputEvent> &p_event) override;
	void _integrate_forces(PhysicsDirectBodyState3D *p_state) override;
	void _process(double p_delta) override;

	void set_player(bool p_on) { player = p_on; }
	bool get_player() const { return player; }
	void set_chase_camera(bool p_on) { chase_camera = p_on; }
	bool get_chase_camera() const { return chase_camera; }
	void set_touch_hud(bool p_on) { touch_hud = p_on; }
	bool get_touch_hud() const { return touch_hud; }
	void set_paint(const Color &p_c) { paint = p_c; }
	Color get_paint() const { return paint; }
	void set_rider_body(const String &p_b) { rider_body = p_b; }
	String get_rider_body() const { return rider_body; }
	// The player who may ride it (the E key / the corner button gets him on when he stands by it)
	void set_rider_player(Object *p_player);
	// Get on (the player must stand within 2.5 m) / off (it must be nearly still); for tests and scenes too
	bool get_on();
	bool get_off();
	// Pedals and bar when nobody's hands are on the keys (tests, scenes): 0..1, 0..1, -1 (right) .. 1 (left), 0..1
	void set_controls(double p_pedal, double p_brake, double p_steer, double p_sprint);
	// speed, lean, steer, state, damage, bent wheel, chain off, wheels on the ground, the view's wobble, the rider's body...
	Dictionary get_state() const;
};

} // namespace godot
