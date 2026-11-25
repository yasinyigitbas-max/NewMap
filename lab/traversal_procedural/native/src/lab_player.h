// Lab A (procedural): the player body. Reads the controls (PC and touch), moves a floating capsule on Jolt, runs the
// motor every physics tick and keeps the last two target sets for the poser to interpolate (6.5).
#pragma once

#include "lab_poser.h"
#include "motor.h"

#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {
class LabCamera;

class LabPlayer : public CharacterBody3D {
	GDCLASS(LabPlayer, CharacterBody3D)

public:
	void _ready() override;
	void _physics_process(double delta) override;
	void _input(const Ref<InputEvent> &event) override;

	lab::Targets interp_targets(float t) const { return lab::lerp_targets(prev_t, cur_t, t); }

	// properties
	void set_walk_speed(float v) { walk_speed = v; }
	float get_walk_speed() const { return walk_speed; }
	void set_run_speed(float v) { run_speed = v; }
	float get_run_speed() const { return run_speed; }
	void set_camera_path(const NodePath &p) { camera_path = p; }
	NodePath get_camera_path() const { return camera_path; }

	// tests: drive the stick directly (x right, y forward, camera-relative), and read the numbers
	void set_scripted_input(const Vector2 &stick, bool run, bool enabled);
	Dictionary get_metrics() const;
	void reset_metrics();
	void teleport(const Vector3 &pos, float yaw);
	float get_body_yaw() const { return motor.yaw; }
	bool is_gait_active() const { return motor.active; }
	Vector3 get_horizontal_velocity() const { return lab::flat(get_velocity()); }

protected:
	static void _bind_methods();

private:
	lab::Motor motor;
	lab::Targets prev_t, cur_t;
	LabPoser *poser = nullptr;
	LabCamera *camera = nullptr;
	NodePath camera_path;
	float walk_speed = 1.4f; // 2.1: normal walk 1.3-1.4 m/s
	float run_speed = 4.6f; // 2.2: a solid run
	bool ready_ok = false;
	Vector3 ground_pos;
	bool grounded = true;
	float vy = 0;
	float float_h = 0.25f;

	// input
	bool scripted = false;
	Vector2 script_stick;
	bool script_run = false;
	Vector2 touch_stick;
	int touch_move_idx = -1, touch_look_idx = -1;
	Vector2 touch_move_origin;
	double last_tap_left = -1, last_tap_right = -1;
	bool crouch_toggle = false;
	bool jump_request = false;

	// metrics: response
	Vector2 last_stick;
	int tick = 0;
	int change_tick = -1;
	float base_head = 0, base_lean = 0, base_yaw = 0;
	Vector3 base_hips_rel;
	bool base_planted[2] = { true, true };
	float latency_max_ms = 0, latency_last_ms = -1;
	int latency_count = 0;
	float latency_sum_ms = 0;

	void setup_input_map();
	Vector2 read_stick(bool &run) const;
	lab::RayHit ray(const Vector3 &from, const Vector3 &to) const;
	void track_response(const Vector2 &stick);
};

} // namespace godot
