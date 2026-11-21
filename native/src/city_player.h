// CityPlayer: a person to walk the city with, all C++. A stand-in for the game's own player, so that the crowd can be
// walked through, bumped into and talked to in the test app: a body that walks and runs on the engine's physics (it
// stands on the world, and stops at cars and at the capsules that stand on the people round it), the same animated
// figure the crowd's people have (the Quaternius clips by its pace), and a camera behind it.
//  - W A S D or the left stick walk, Shift (right trigger) runs, the mouse (or the arrows, the right stick) turns the
//    view, E (pad X) = "interact" (a signal: the crowd's talk hangs on it).
//  - `set_move` drives it instead of the keys (tests).
#pragma once

#include <algorithm>
#include <vector>

#include <godot_cpp/classes/audio_stream.hpp>
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class CityPed;
class AudioStreamPlayer3D;

class CityPlayer : public CharacterBody3D {
	GDCLASS(CityPlayer, CharacterBody3D)

	CityPed *fig = nullptr;
	Camera3D *cam = nullptr;
	String body_id = "M2";
	// HIS VOICE (Yasin, 20 Nov: "make sure players sounds have variety, same grunt shouldnt play everytime ... at least
	// 4 varieties"; one recorded voice per gender, audio/player/<m|f>/<kind>_NN.ogg): a random take of the kind, never
	// the one played last, from the set of his body's gender
public:
	enum { V_JUMP = 0, V_CLIMB, V_LAND, V_HURT, V_PAIN, V_DEATH, V_BREATH, V_PUNCH, V_THROW, V_KINDS };
private:
	AudioStreamPlayer3D *vox_pl = nullptr;
	std::vector<Ref<AudioStream>> vox_bank[V_KINDS];
	String vox_gender;
	int vox_last[V_KINDS] = { -1, -1, -1, -1, -1, -1, -1, -1, -1 };
	double vox_at[V_KINDS] = { -9, -9, -9, -9, -9, -9, -9, -9, -9 };
	double vox_clock = 0.0;
	uint32_t vox_rng = 0x6b43a9b5u;
	int vox_count = 0;
	float air_min_vy = 0.0f, run_t = 0.0f;
	void vox_load();
	bool vox(int p_kind, double p_gap = 0.3, float p_chance = 1.0f);
	bool capture_mouse = false, scripted = false, cmd_run = false, e_was = false, cam_set = false, frozen = false;
	Vector2 cmd;
	float cam_yaw = 0.0f, cam_pitch = -0.18f, cam_dist = 3.4f, yaw = 0.0f, speed = 0.0f;
	// THE GAIT (the Animator, 20 Nov; Yasin: "i want RDR like grounded heavy bodied people and not rushed movements";
	// "just open the hands of quaternius animations and use them for walk"; "just make one normal mode, lets drop the
	// angry entirely"): the Quaternius walk and jog with the hands open (tools/people/make_steps.gd: "step/walk",
	// "step/jog", "step/idle"), each played near its own speed (before: the walk x1.74, the sprint x1.48,
	// tests/people/gait_film.gd).
	float walk_speed = 1.35f, run_speed = 2.8f;   // (the Mixamo walk's own pace is 1.53 m/s, its jog's 2.69: near their own rate; 21 Nov)
	float turn_dir = 0.0f;   // (a turn while moving: the clip's own way round)
	float taunt_t = 0.0f;    // (in his stance without a blow: a taunt now and then)
	bool jump_run = false, land_hard = false;   // (a jump at a run; a landing from high up)
	bool climb_fast = false;   // (the double climb taken at a run: up the wall at a sprint)          // the walk at x1.14, the jog at x1.17
	int gait_i = -1;              // the walking clip of the set playing now (kept a little past the midpoint: no flicker)
	float move_speed = 0.0f;      // the pace he means (his body turns, then goes the way it faces)
	Vector3 lean_a;               // his acceleration, smoothed: the body leans into a turn and into a start
	float last_speed = 0.0f;
	int step_mode = 0;            // a step clip playing: 1 the start, 2 a stop, 3 a turn on the spot (tools/people/make_steps.gd)
	StringName step_clip;
	float step_t = 0.0f, step_cs = 1.0f, step_v0 = 0.0f;
	double stop_ph_prev = -1.0;   // (waiting for the footfall to stop on: the stride's share last frame)
	int starts = 0, stops = 0, turns = 0;    // (the tests)
	// IN A TALK (CityTalk; Yasin, 20 Nov: "starting chat with npc doesnt play any animation"): he faces whom he talks to
	// and his body talks when he says a line; 0 talking (ual/Idle_Talking_Loop), 1 a nod (ual/Yes), 2 no (Idle_No_Loop),
	// 3 bending down to lift something (ual/PickUp_Kneeling: a fallen bicycle)
	bool talk_on = false; Vector3 talk_at;
	int gest_kind = 0; float gest_t = 0.0f;
public:
	void talk_face(bool p_on, const Vector3 &p_at) { talk_on = p_on; talk_at = p_at; }
	void gesture(int p_kind, double p_seconds) { gest_kind = p_kind; gest_t = (float)p_seconds; }
	// the phone in his hands (CityHud): 0 none, 1 in his hand, 2 at his ear (a call), 3 held up (the camera)
	int phone_kind = 0;
	bool fig_was_body = false;   // (his figure was on its physical body last frame: knocked down, getting up)
	void set_phone(int p_kind) { phone_kind = p_kind; }
	// walking to a spot by himself (another system's: the bicycle he goes to lift); done when he is within 12 cm
	bool auto_on = false; Vector3 auto_to;
	float auto_stuck = 0.0f;   // (walking into something on the way there: done once he has not moved for 0.4 s)
	void walk_to(const Vector3 &p_at) { auto_on = true; auto_to = p_at; auto_stuck = 0.0f; }
	// stop dead where he is (another system takes over his body: the bicycle he kneels to lift)
	// where his gesture's clip is (s), or -1 when it is not playing (the bicycle's lift follows the kneel's own time)
	double gesture_time() const;
	void halt() { auto_on = false; move_speed = 0.0f; step_mode = 0; stop_ph_prev = -1.0; set_velocity(Vector3()); }
	bool walk_done() const { return !auto_on; }
	// his hands held to two points by another system (the climb's HandGrip: the bicycle's grip and saddle as he lifts it)
	bool hold_on = false; Vector3 hold_p[2], hold_out, hold_side; float hold_w = 0.0f;
	void hold_points(bool p_on, const Vector3 &p_l, const Vector3 &p_r, const Vector3 &p_out, float p_w) {
		hold_on = p_on; hold_p[0] = p_l; hold_p[1] = p_r; hold_out = p_out; hold_side = Vector3(0, 1, 0).cross(-p_out).normalized(); hold_w = p_w;
	}
private:
	float turn_yaw0 = 0.0f, turn_k = 1.0f;   // a turn on the spot (step_mode 3): the way he faced, the clip's turn scaled to the angle
	Vector3 cam_pos, knock_v;
	uint64_t view_id = 0;                 // the car or bicycle his camera frames (0: him)
	Vector3 cam_pivot;                    // what the camera turns round, eased
	float cam_d = 1.7f, cam_side = 0.72f, cam_fov = 56.0f, look_idle = 9.0f;
	float side_sign = 1.0f, side_cd = 0.0f, cam_lift = 0.0f;   // the shoulder it is over (+1 right), its hold, its rise over a blocked view
	// THE OLD GAME'S TOUCH SCHEME (docs/OLD_CONTROLS_SPEC.md; Yasin: "copy it as it was"): the left half of the screen is
	// an invisible floating stick (full at 80 px), the right half looks (0.25 deg a pixel x 1.2), a double tap (0.32 s,
	// 110 px) on the left crouches, on the right jumps
	Vector2 move_start[16]; bool move_on[16] = {}; Vector2 touch_mv;
	double tap_t[2] = { -9, -9 }; Vector2 tap_p[2];
	bool crouch = false, jump_want = false, space_was = false, c_was = false, airborne = false;
	float land_t = 0.0f;
	bool crouch_prev = false; float crouch_t = 9.0f;   // (into and out of the crouch: Crouch_Enter / Crouch_Exit played through)
	int steps_up = 0;   // (the tests) small heights stepped up
	// CLIMBING (Yasin: "put climb animation on up to 50 cm, then above that should require a jump, but if our height allows
	// it we should be able to clinch and pull ourselves up"; "maybe limit it around 2.5 m"): walking into a ledge 24-50 cm
	// high he climbs onto it (ClimbUp_1m); one 0.5-2.5 m over the ground he jumped from he grabs in the jump and pulls
	// himself up (ClimbUp_2m); higher, or no room to stand up there: nothing. He is moved up, then over, as the clip plays.
	int climb = 0;                 // 0 none, 1 onto a low ledge, 2 up a high one (from the jump), 3 a step (8-24 cm: StepUp;
	                               // Yasin: "make 24 cm step an obvious over step though, he just walked casually over 20 cm")
	float climb_t = 0.0f, climb_len = 1.0f, jump_y = 0.0f;
	Vector3 climb_from, climb_to, climb_hang;
	// the hands on the edge (Yasin: "make sure the characters hands follow the edge and clinch to the edge of the surface on
	// climbs"): the edge's middle (where the wall's face meets the top), the way off it toward him, his left
	Vector3 edge_at, edge_out, edge_side;
	class HandGrip *grip = nullptr;
	class FootPlant *plant = nullptr;
	float vis_dy = 0.0f, kerb_t = 0.0f;   // the drawn figure under the body after a lift onto a kerb (eased away)
	// the clip's own rise and travel (its hips move the figure up as it climbs): taken out, so his hips follow the climb's
	// path (Yasin: "lower climb needs better placement"; "step up was off too")
	Vector3 pel_rest, fig_drawn_at, clip_off;
	bool pel_rest_set = false;
	Vector3 pelvis_world() const;
	bool cur_clip_is(const StringName &p_clip) const;
	float grip_w = 0.0f, grip_miss_most = 0.0f, grip_on_s = 0.0f, grip_tip_most = 0.0f;
	bool hang_set = false;   // (a high climb: hung from the edge by the clip's own hands, on its first frame)
	void grip_update();
	int climbs_low = 0, climbs_high = 0, vaults = 0;
	// a FENCE (Yasin: "we should be able to jump over fences, same rules apply, hand on the rail"): a thin top with lower
	// ground beyond: up to 50 cm walking, 0.5-1.4 m from a jump: over it (Vault), the left hand on the rail; climb 4
	Vector3 vault_over;
	// out of a step or climb (Yasin: "character looks to be not playing exit step up or exit climb to idle and immediately
	// gets into walking which looks jittery"): 0.3 s standing (Idle), the clip's last offset fading out, then he goes on
	float settle_t = 9.0f; Vector3 settle_off;
	bool try_climb(const Vector3 &p_dir);
	double clock_s = 0.0;
	Rect2 no_touch[8]; int n_no_touch = 0;   // screen rectangles that are buttons (the Use plate, the phone): not move / look
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
	StringName act_clip; double act_left = 0.0; float act_yaw = 0.0f; int acts = 0;
	Vector3 acc_lp; bool acc_init = false;
	double acc_spike_t = -9.0, mic_spike_t = -9.0;
	float mic_avg = 0.01f;
	float gyro_peak = 0.0f, acc_peak = 0.0f;
	Vector3 acc_prev; bool acc_prev_ok = false; float tap_score = 0.0f; double mic_on_t = 0.0;   // (the back tap: last frame's reading, the last jerk score, time since the mic started)   // (the swing: each sensor's peak over the last quarter second)
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
	// AN ACT (Yasin, 20 Nov: "add us and npcs giving money receiving things animations"): a clip played once where he stands,
	// turned to p_yaw, his feet still while it lasts (paying at a counter, taking what he bought)
	void act(const StringName &p_clip, double p_seconds, double p_yaw);
	String get_act() const { return act_left > 0.0 ? String(act_clip) : String(); }
	int get_acts() const { return acts; }
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
	int get_steps_up() const { return steps_up; }
	int get_climbs_low() const { return climbs_low; }
	int get_climbs_high() const { return climbs_high; }
	int get_vaults() const { return vaults; }
	bool is_climbing() const { return climb != 0; }
	float get_grip_weight() const { return grip_w; }
	float get_hips_drop() const;
	Vector3 get_pelvis() const { return pelvis_world(); }
	float get_grip_miss_most() const { return grip_miss_most; }   // the farthest a gripping wrist ended from its point (m)
	float get_grip_seconds() const { return grip_on_s; }
	float get_grip_tip_most() const { return grip_tip_most; }
	Vector3 get_grip_now() const;
	Dictionary get_frame_log() const;   // (traces) the climb's progress, the two wrists' miss now   // the farthest a gripping fingertip was over or under the edge's top (m)
	Vector3 get_edge_at() const { return edge_at; }
	Array get_hand_points() const;
	void take_hit() { hit_t = 0.0; hits_taken++; vox(V_HURT, 0.4); }   // a blow taken on his feet (the hit clip)
	int get_hits_taken() const { return hits_taken; }
	bool get_crouch() const { return crouch; }
	void jump() { jump_want = true; }
	// a button's rectangle on the screen that move / look must not take (k 0..3)
	void set_no_touch(int p_k, const Rect2 &p_r) { if (p_k >= 0 && p_k < 8) { no_touch[p_k] = p_r; n_no_touch = std::max(n_no_touch, p_k + 1); } }
	Vector2 get_touch_move() const { return touch_mv; }
	bool is_frozen() const { return frozen; }
	// somebody hits him: he is knocked that way (m/s)
	void knock(const Vector3 &p_v) { knock_v += p_v; const float k = p_v.length(); if (k > 6.0f) vox(V_PAIN, 0.8); else if (k > 2.0f) vox(V_HURT, 0.4); }   // (a hard blow: a groan)
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
	float get_yaw() const { return yaw; }
	Array get_view() const { Array a; a.push_back(yaw); a.push_back(cam_yaw); a.push_back(cam_pitch); return a; }
	void set_view(double p_yaw, double p_cam_yaw, double p_cam_pitch) { yaw = (float)p_yaw; cam_yaw = (float)p_cam_yaw; cam_pitch = (float)p_cam_pitch; }
	// THE ONE CAMERA (Yasin, 21 Nov: "why do we even have 2 camera set ups anyway? unify the camera, make it a god of war
	// like shoulder camera that follows us everywhere"): his camera is the only one. On foot it sits over his right
	// shoulder; getting into a car or onto the bike it follows his body to the seat; driving or riding it frames the
	// vehicle, a little further back, easing round behind it when nobody turns the view. It never cuts: every change of
	// framing is eased. A ray keeps it out of walls and the ground.
	void view_vehicle(Node3D *p_vehicle) { view_id = p_vehicle ? (uint64_t)p_vehicle->get_instance_id() : 0; look_idle = 0.0f; if (cam) cam->make_current(); }
	void take_view() { view_id = 0; if (cam) cam->make_current(); }
	Camera3D *get_camera() const { return cam; }
	void set_body_id(const String &p_id) { body_id = p_id; }
	bool vocal(const String &p_kind);           // a vocal sound by name ("jump", "throw", ...): other systems' (a shove)
	int get_vocal_count() const { return vox_count; }
	String get_vocal_gender() const { return body_id.begins_with("F") ? "f" : "m"; }
	String get_body_id() const { return body_id; }
	void set_capture_mouse(bool p_on) { capture_mouse = p_on; }
	bool get_capture_mouse() const { return capture_mouse; }
	void set_walk_speed(double p_s) { walk_speed = (float)p_s; }
	double get_walk_speed() const { return walk_speed; }
	void set_run_speed(double p_s) { run_speed = (float)p_s; }
	double get_run_speed() const { return run_speed; }
};

} // namespace godot
