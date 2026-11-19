// CityPlayer: a person to walk the city with, all C++. A stand-in for the game's own player, so that the crowd can be
// walked through, bumped into and talked to in the test app: a body that walks and runs on the engine's physics (it
// stands on the world, and stops at cars and at the capsules that stand on the people round it), the same animated
// figure the crowd's people have (the Quaternius clips by its pace), and a camera behind it.
//  - W A S D or the left stick walk, Shift (right trigger) runs, the mouse (or the arrows, the right stick) turns the
//    view, E (pad X) = "interact" (a signal: the crowd's talk hangs on it).
//  - `set_move` drives it instead of the keys (tests).
#pragma once

#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class CityPed;

class CityPlayer : public CharacterBody3D {
	GDCLASS(CityPlayer, CharacterBody3D)

	CityPed *fig = nullptr;
	Camera3D *cam = nullptr;
	String body_id = "M2";
	bool capture_mouse = false, scripted = false, cmd_run = false, e_was = false, cam_set = false, frozen = false;
	Vector2 cmd;
	float cam_yaw = 0.0f, cam_pitch = -0.18f, cam_dist = 3.4f, yaw = 0.0f, speed = 0.0f;
	float walk_speed = 1.6f, run_speed = 4.6f;
	Vector3 cam_pos, knock_v;
	double water_y = -1000.0;   // the water's surface (-1000 = there is none): deeper than his chest he swims
	bool swimming = false;

protected:
	static void _bind_methods();

public:
	void _ready() override;
	void _exit_tree() override;
	void _input(const Ref<InputEvent> &p_event) override;
	void _physics_process(double p_delta) override;
	void _process(double p_delta) override;

	// (tests) walk this way instead of by the keys: x = to its right, y = ahead, seen from the camera
	void set_move(const Vector2 &p_dir, bool p_run);
	// he stands and takes no keys (while a line is typed to somebody)
	void set_frozen(bool p_on) { frozen = p_on; }
	bool is_frozen() const { return frozen; }
	// somebody hits him: he is knocked that way (m/s)
	void knock(const Vector3 &p_v) { knock_v += p_v; }
	// water: he walks in; where it is deeper than 1.15 m he swims at the surface; where it gets shallower than 0.9 m he
	// stands up and walks out
	void set_water_y(double p_y) { water_y = p_y; }
	double get_water_y() const { return water_y; }
	bool is_swimming() const { return swimming; }
	String get_clip() const;
	double get_speed() const { return speed; }
	CityPed *figure() { return fig; }
	// on a bicycle (CityBike): he is not there as a body while he rides (no collision, not drawn, no keys); back on his
	// feet at a place facing a way, with his own view again
	void set_riding(bool p_on);
	void stand_at(const Vector3 &p_at, double p_yaw);
	void take_view() { if (cam) { cam->make_current(); cam_set = false; } }
	void set_body_id(const String &p_id) { body_id = p_id; }
	String get_body_id() const { return body_id; }
	void set_capture_mouse(bool p_on) { capture_mouse = p_on; }
	bool get_capture_mouse() const { return capture_mouse; }
	void set_walk_speed(double p_s) { walk_speed = (float)p_s; }
	double get_walk_speed() const { return walk_speed; }
	void set_run_speed(double p_s) { run_speed = (float)p_s; }
	double get_run_speed() const { return run_speed; }
};

} // namespace godot
