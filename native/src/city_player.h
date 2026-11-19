// CityPlayer: a person to walk the city with, all C++. A stand-in for the game's own player, so that the crowd can be
// walked through, bumped into and talked to in the test app: a body that walks and runs on the engine's physics (it
// stands on the world, and stops at cars and at the capsules that stand on the people round it), the same animated
// figure the crowd's people have (the Quaternius clips by its pace), and a camera behind it.
//  - W A S D or the left stick walk, Shift (right trigger) runs, the mouse (or the arrows, the right stick) turns the
//    view, E (pad X) = "interact" (a signal: the crowd's talk hangs on it).
//  - `set_move` drives it instead of the keys (tests).
#pragma once

#include <algorithm>

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
	// THE OLD GAME'S TOUCH SCHEME (docs/OLD_CONTROLS_SPEC.md; Yasin: "copy it as it was"): the left half of the screen is
	// an invisible floating stick (full at 80 px), the right half looks (0.25 deg a pixel x 1.2), a double tap (0.32 s,
	// 110 px) on the left crouches, on the right jumps
	Vector2 move_start[16]; bool move_on[16] = {}; Vector2 touch_mv;
	double tap_t[2] = { -9, -9 }; Vector2 tap_p[2];
	bool crouch = false, jump_want = false, space_was = false, c_was = false, airborne = false;
	float land_t = 0.0f;
	double clock_s = 0.0;
	Rect2 no_touch[4]; int n_no_touch = 0;   // screen rectangles that are buttons (the Use plate, the phone): not move / look
	// COMBAT (Yasin: "when phone is swung down in landscape, we should enter combat mode ... tapping the back [throws] a
	// punch, alternating between right and left"; "gyro accelero and mic ... at the same time to detect those taps").
	// The crowd (CityCrowd) locks the target and keeps the score; this holds the stance, faces the target, throws the
	// punches. On a PC: F fights, a left click or J punches.
	bool combat = false, combat_req = false, punch_req = false, f_was = false, j_was = false, m_was = false;
	Vector3 combat_target;
	int punch_side = 0;            // 0 the left (jab), 1 the right (cross): taken in turn
	double punch_t = 9.0, punch_len = 0.6, swing_cd = 0.0, tap_cd = 0.0;
	int punches = 0, hits_taken = 0;
	double combat_t = 9.0, uncombat_t = 9.0;
	double hit_t = 9.0;
	Vector3 acc_lp; bool acc_init = false;
	double acc_spike_t = -9.0, mic_spike_t = -9.0;
	float mic_avg = 0.01f;
	class AudioEffectCapture *mic_cap = nullptr;
	void sense(double p_dt);
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
	void set_crouch(bool p_on) { crouch = p_on; }
	// combat: asked for (a swing / F) and punches (a back tap / J / click) are taken by the crowd
	void request_combat() { combat_req = true; }
	void punch() { if (combat) punch_req = true; }
	bool take_combat_request() { const bool r = combat_req; combat_req = false; return r; }
	int take_punch();   // 0 none, else 1 + the side of a punch that starts now
	// (Yasin: "use punch kick enter exit animations too"): into the guard with PunchKick_Enter played through, out of it with PunchKick_Exit
	void set_combat(bool p_on, const Vector3 &p_target) { if (p_on && !combat) combat_t = 0.0; if (!p_on && combat) uncombat_t = 0.0; combat = p_on; combat_target = p_target; if (!p_on) punch_req = false; }
	bool get_combat() const { return combat; }
	int get_punches() const { return punches; }
	void take_hit() { hit_t = 0.0; hits_taken++; }   // a blow taken on his feet (the hit clip)
	int get_hits_taken() const { return hits_taken; }
	bool get_crouch() const { return crouch; }
	void jump() { jump_want = true; }
	// a button's rectangle on the screen that move / look must not take (k 0..3)
	void set_no_touch(int p_k, const Rect2 &p_r) { if (p_k >= 0 && p_k < 4) { no_touch[p_k] = p_r; n_no_touch = std::max(n_no_touch, p_k + 1); } }
	Vector2 get_touch_move() const { return touch_mv; }
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
	Array get_view() const { Array a; a.push_back(yaw); a.push_back(cam_yaw); a.push_back(cam_pitch); return a; }
	void set_view(double p_yaw, double p_cam_yaw, double p_cam_pitch) { yaw = (float)p_yaw; cam_yaw = (float)p_cam_yaw; cam_pitch = (float)p_cam_pitch; }
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
