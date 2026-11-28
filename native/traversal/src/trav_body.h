// The body (the study, Layer 1): "One `CharacterBody3D` with a capsule. It alone decides where the character is."
// A line-for-line translation of traversal_lab/traversal/body/body.gd (the script version, the reference): the same
// names, the same numbers, the same order of work. Every comment on WHY a thing is so is in the script; this file
// only says where it departs from the script's wording, which is nowhere on purpose.
// (Yasin, 27 Nov 2026: "make all the code c plus plus and make god damn sure nothing ever breaks".)
#pragma once

#include <godot_cpp/classes/box_shape3d.hpp>
#include <godot_cpp/classes/physics_shape_query_parameters3d.hpp>
#include <godot_cpp/classes/capsule_shape3d.hpp>
#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/collision_shape3d.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/sphere_shape3d.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/variant.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

// The script's constants, by the script's names. X(name, value)
#define TRAV_BODY_CONSTS(X) \
	X(HEIGHT, 1.80) \
	X(RADIUS, 0.25) \
	X(FLOAT, 0.32) \
	X(STEP_DOWN, 0.30) \
	X(PROBE_R, 0.15) \
	X(SLOPE_WALK_DEG, 20.0) \
	X(SLOPE_HANDS_DEG, 35.0) \
	X(SLOPE_LIMIT_DEG, 50.0) \
	X(CLIMB_WALK, 0.35) \
	X(CLIMB_RUN, 1.0) \
	X(CLIMB_HANDS_RUN, 0.6) \
	X(DOWN_EASE, 16.0 / 30.0) \
	X(WALK, 1.45) \
	X(RUN, 4.5) \
	X(START_TIME_WALK, 0.24) \
	X(START_TAIL_WALK, 0.33) \
	X(START_TIME_RUN, 0.60) \
	X(STOP_WALK, 2.3) \
	X(STOP_RUN, 6.2) \
	X(TURN_RATE_WALK, 3.14) \
	X(TURN_RATE_RUN, 4.7) \
	X(TURN_SLOW, 0.6) \
	X(TURN_SLOW_ANGLE_DEG, 90.0) \
	X(CURVE_PULL_WALK, (0.96 / 1.61 * 1.45) * (0.96 / 1.61 * 1.45) / 1.0) \
	X(CURVE_TIME, 0.25) \
	X(REVERSE_ANGLE_DEG, 135.0) \
	X(SPOT_START_DEG, 60.0) \
	X(SPOT_END_DEG, 15.0) \
	X(SPOT_RATE, 3.14159265358979323846 / (3.5 * 60.0 / 117.5)) \
	X(RUN_OUT, 2.5) \
	X(STEP_TIME_UP, 0.51) \
	X(STEP_TIME_DOWN, 0.47) \
	X(STEP_TIME_RUN_UP, 0.28) \
	X(STEP_TIME_RUN_DOWN, 0.22) \
	X(LAND_HOLD_SOFT, 0.30) \
	X(LAND_HOLD_HARD, 0.90) \
	X(HARD_DROP, 1.0) \
	X(TREAD, 0.28) \
	X(REVERSE_SPEED, 2.0) \
	X(RISE_SPEED, 2.4) \
	X(SINK_SPEED, 3.0) \
	X(GRAVITY, 9.8) \
	X(TERMINAL, 50.0) \
	X(TURN_SPEED, 12.0) \
	X(JUMP_RISE, 0.45) \
	X(JUMP_DIP_STAND, 0.0) \
	X(JUMP_PUSH_STAND, 0.30) \
	X(JUMP_RISE_RUN, 0.60) \
	X(JUMP_PUSH_RUN, 0.10) \
	X(CROUCH_SPEED, 1.46 * 0.5 * 1.1) \
	X(NARROW_SPEED, 0.75) \
	X(NARROW_SPEED_LEAST, 0.40) \
	X(STEP_HEIGHT_FOR_NARROW, 0.25) \
	X(NARROW_STAY, 0.04) \
	X(LEDGE_PULL, 6.0) \
	X(SQUEEZE_AHEAD, 0.5) \
	X(SQUEEZE_SLOW_TIME, 0.8) \
	X(SQUEEZE_PLAY, 0.02) \
	X(SQUEEZE_SEEN, 0.01) \
	X(SQUEEZE_SPEED, 0.67) \
	X(CROUCH_HEIGHT, 1.15) \
	X(STAND_ROOM, 0.03) \
	X(PHONE_SPEED, 1.3)

// The script's variables, by the script's names: every one can be read and set from outside, as in the script.
#define TRAV_BODY_VARS(X) \
	X(tape) X(state) X(hvel) X(vy) X(ground_y) X(ground_normal) X(_wish) X(_touched) X(_wall) X(jump_timer) \
	X(air_time) X(from_jump) X(_jump_held) X(_air_peak) X(_jump_still) X(slope_deg) X(grade) X(face_in) X(terrain) \
	X(stairs) X(stair_tread) X(stair_edge) X(stair_dir) X(stair_riser) X(stair_count) X(_ray_y) X(_ray_ok) \
	X(_since_edge) X(spot_total) X(spot_left) X(spot_run) X(spot_walk) X(land_hold) X(_wish_yaw) X(_wish_turn) \
	X(_wish_on) X(_stood_y) X(move_path) X(move_clip) X(move_clip_t) X(move_t) X(move_landed) X(move_free) \
	X(move_landing) X(move_step) X(move_base) X(move_hand) X(move_soft) X(_wish_was_moving) X(narrow) X(stick_held) \
	X(squeeze) X(stick_wish) X(squeeze_side) X(squeeze_w) X(ledge_wall) X(ledge_out) X(squeeze_mid) \
	X(squeeze_across) X(_gap_mid) X(_gap_n) X(radius) X(stick_dir) X(cover_drop) X(act_held) X(act_now) X(phone) \
	X(auto_on) X(auto_to) X(_text_was) X(_call_was) X(run_asked) X(crouched) X(last_sample) X(pace)

class TravBody : public CharacterBody3D {
	GDCLASS(TravBody, CharacterBody3D)

public:
	enum State { GROUND = 0, STEEP = 1, UNSUPPORTED = 2, AIR = 3 };

#define X(n, v) static constexpr double n = v;
	TRAV_BODY_CONSTS(X)
#undef X

	Variant tape;
	Dictionary last_sample;         // the keys of this tick, as read from the tape (for the things he holds: trav_hold)
	int state = AIR;
	Vector3 hvel;
	double vy = 0.0;
	double ground_y = 0.0;
	Vector3 ground_normal = Vector3(0, 1, 0);
	Vector3 _wish;
	bool _touched = false;
	Vector3 _wall;
	double jump_timer = 0.0;
	double air_time = 0.0;
	bool from_jump = false;
	bool _jump_held = false;
	double _air_peak = 0.0;
	bool _jump_still = false;
	double slope_deg = 0.0;
	double grade = 0.0;
	bool face_in = false;
	int terrain = 0;
	int stairs = 0;
	double stair_tread = TREAD;
	Vector3 stair_edge;
	Vector3 stair_dir;
	double stair_riser = 0.0;
	int stair_count = 0;
	double _ray_y = 0.0;
	bool _ray_ok = false;
	double _since_edge = 99.0;
	double spot_total = 0.0;
	double spot_left = 0.0;
	bool spot_run = false;
	bool spot_walk = false;
	double land_hold = 0.0;
	double _wish_yaw = 0.0;
	double _wish_turn = 0.0;
	bool _wish_on = false;
	double _stood_y = 0.0;
	Callable move_path;
	String move_clip;
	double move_clip_t = 0.0;
	double move_t = 0.0;
	bool move_landed = false;
	bool move_free = false;
	String move_landing = "soft";
	Array move_step;
	double move_base = 0.0;
	Array move_hand;
	double move_soft = 0.0;
	bool _wish_was_moving = false;
	int narrow = 0;
	bool stick_held = false;
	int squeeze = 0;
	Vector3 stick_wish;
	int squeeze_side = 1;
	double squeeze_w = INFINITY;
	Vector3 ledge_wall;
	Vector3 ledge_out = Vector3(1, 0, 0);
	Vector3 squeeze_mid;
	Vector3 squeeze_across = Vector3(1, 0, 0);
	Vector3 _gap_mid;
	// (28 Nov night, the phone) one box over all the squeeze rays' reach: empty, the rays are not cast (_find_squeeze)
	Ref<BoxShape3D> _clear_box;
	Ref<PhysicsShapeQueryParameters3D> _clear_q;
	Vector3 _gap_n = Vector3(1, 0, 0);
	double radius = RADIUS;
	Vector3 stick_dir;
	double cover_drop = 0.0;
	double pace = 1.0;              // a share of the walking, running and crouching pace (27 Nov, Yasin: "Yes to all"): 1 for the player; an NPC body sets its own (trav_npc.cpp)
	bool act_held = false;
	bool act_now = false;
	int phone = 0;
	bool auto_on = false;
	Vector3 auto_to;
	bool _text_was = false;
	bool _call_was = false;
	bool run_asked = false;
	bool crouched = false;

private:
	Ref<SphereShape3D> _probe;
	Ref<CapsuleShape3D> _fit;
	CollisionShape3D *_col = nullptr;
	CollisionShape3D *_skirt = nullptr;
	Array _look;

	void _set_crouched(bool low);
	bool _is_steep(const Dictionary &g);
	double _gap_at(const Vector3 &at, const Vector3 &across);
	Dictionary _ledge_at(const Vector3 &at, const Vector3 &across);
	void _find_squeeze();
	void _set_radius(double r);
	int _narrow_now();
	void _run_move(double dt);
	Vector3 _steer(Vector3 v, const Vector3 &wish, double dt);
	double _start_time(double speed, double want, double fast);
	void _find_stairs(double dt);
	void _read_slope(const Vector3 &n, const Vector3 &dir);
	double _slope_speed(bool run);
	double _stair_speed(bool run);
	void _move(Vector3 motion, bool flat);
	void _slow_for_rising_ground();
	void _update_ground(double dt);
	Dictionary _ray(const Vector3 &from, const Vector3 &to);
	double _rot_y() const;
	void _set_rot_y(double y);

protected:
	static void _bind_methods();
	bool _get(const StringName &p_name, Variant &r_ret) const;
	bool _set(const StringName &p_name, const Variant &p_value);

public:
	void _ready() override;
	void _physics_process(double dt) override;

	bool can_stand();
	void show_capsule(bool on);
	Dictionary probe(const Vector3 &feet, double from_up = FLOAT + RADIUS, double reach = STEP_DOWN + 0.05);
	void begin_move(const Callable &path, const String &clip);
	bool start_jump();
	bool in_move() const;
	double stop_distance();
	Dictionary _ray_down(const Vector3 &at);
	Dictionary landing_ahead();
	Dictionary get_readout();
	void place(const Vector3 &at);
	String native_version() const;
};

} // namespace godot
