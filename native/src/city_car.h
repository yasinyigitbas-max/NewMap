// CityCar: a car you can drive (and crash), all C++. The physical car of veh_dyn.h on one of the engine's rigid
// bodies: the engine keeps the body's place and does the crashes; this class works out every force the springs,
// tyres, engine and brakes put on it, 6 small steps inside each physics step, and hands back its speed and spin.
// Written new on Yasin's word, 19 Nov 2026 ("good car physics ... ride exactly like gta 4 if not gta 5").
//
//  - One ray per wheel a physics step (4 a car), against the world only. No VehicleBody3D, no wheel nodes with scripts.
//  - The car's own length, track and wheel size come from its model's wheel positions (the body mesh's "wheels" note),
//    so the physical wheels are where the drawn ones are.
//  - Body and four wheels are drawn apart: the wheels spin, steer and ride their springs.
//  - `player` on: it reads the keys (W A S D or the arrows, Space = handbrake) and a pad (triggers, left stick, A).
//    S brakes and, once the car stands, reverses, as in GTA. Off: `set_controls` drives it (tests, later the traffic's
//    drivers when a traffic car is knocked off its line).
//  - `chase_camera` on: a camera that follows like GTA's (behind the car, swinging round as it turns, wider at speed).
// The test app's script only makes the node and sets these numbers; nothing is called per frame from script.
#pragma once

#include "veh_dyn.h"

#include <godot_cpp/classes/box_shape3d.hpp>
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/collision_shape3d.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/classes/physics_direct_body_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/rigid_body3d.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class CityCar : public RigidBody3D {
	GDCLASS(CityCar, RigidBody3D)

	vd::Car car;
	bool made = false;
	int model = 2, feel = vd::FEEL_IV;
	Color paint = Color(0.55f, 0.57f, 0.6f);
	bool player = false, chase_camera = false;
	float c_throttle = 0, c_brake = 0, c_steer = 0, c_handbrake = 0;
	int dir = 1;
	// touch driving (20 Nov): one finger steers (left half), others press brake / gas / handbrake (right half)
	int t_steer_id = -1;
	float t_steer_x0 = 0, t_steer = 0;
	int t_zone[16] = { 0 };      // per finger index: 0 none, 1 brake, 2 gas, 3 handbrake
	Vector3 com;                 // the centre of mass in the node's own frame (the node's origin is on the ground under the car)
	MeshInstance3D *wheel_vis[4] = { nullptr, nullptr, nullptr, nullptr };
	MeshInstance3D *mi_body = nullptr;
	CollisionShape3D *cs_body = nullptr, *cs_top = nullptr;
	Ref<BoxShape3D> sh_body, sh_top;
	Ref<ShaderMaterial> mat;
	bool split = false;          // the model has its wheels apart: they spin, steer and ride their springs
	Vector3 hub_local[4];        // the hubs at rest, node frame
	Camera3D *cam = nullptr;
	Vector3 cam_pos, cam_look;
	float cam_yaw = 0;
	bool cam_set = false;
	Ref<PhysicsRayQueryParameters3D> rq;
	uint32_t wheel_mask = 1;     // what the wheels stand on: the world
	// for the tests and a dashboard
	double odo = 0.0;
	float hardest_hit = 0.0f;
	Vector3 last_v;

	void make();
	void fit();
	void read_player();

protected:
	static void _bind_methods();

public:
	void _ready() override;
	void _input(const Ref<InputEvent> &p_event) override;
	void _integrate_forces(PhysicsDirectBodyState3D *p_state) override;
	void _process(double p_delta) override;

	void set_model(int p_model) { model = p_model; }
	int get_model() const { return model; }
	void set_feel(int p_feel) { feel = p_feel; }
	int get_feel() const { return feel; }
	void set_paint(const Color &p_c) { paint = p_c; }
	Color get_paint() const { return paint; }
	void set_player(bool p_on) { player = p_on; }
	bool get_player() const { return player; }
	void set_chase_camera(bool p_on) { chase_camera = p_on; }
	bool get_chase_camera() const { return chase_camera; }
	void set_wheel_mask(int p_mask) { wheel_mask = (uint32_t)p_mask; }
	int get_wheel_mask() const { return (int)wheel_mask; }

	// Pedals and wheel when no player drives: 0..1, 0..1, -1 (right) .. 1 (left), 0..1; reverse = the reverse gear
	void set_controls(double p_throttle, double p_brake, double p_steer, double p_handbrake, bool p_reverse);
	// A car of a pool takes another model, feel and paint (no node is made or freed), is set down with a speed, is taken away
	void become(int p_model, int p_feel, const Color &p_paint);
	void launch(const Transform3D &p_at, const Vector3 &p_velocity);
	void put_away(const Vector3 &p_where);
	bool is_split() const { return split; }
	// speed m/s, km/h, revs, gear, side and forward g, each wheel's load / slip / on the ground, metres driven, hardest knock (g)
	Dictionary get_state() const;
	// the car's half length, half width, speed along x and z: what the traffic needs to see it as a box
	const vd::Car &physics() const { return car; }
};

} // namespace godot
