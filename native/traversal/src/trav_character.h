// The character on the body (the study, Layer 2: "One `AnimationTree` set to the physics tick. In normal movement the
// clips play to match the body's speed"). A line-for-line translation of
// traversal_lab/traversal/character/character.gd (the script version, the reference): the same names, the same
// numbers, the same order of work. The reasons for each thing are in the script.
#pragma once

#include <godot_cpp/classes/animation_library.hpp>
#include <godot_cpp/classes/animation_node_animation.hpp>
#include <godot_cpp/classes/animation_node_blend_tree.hpp>
#include <godot_cpp/classes/animation_player.hpp>
#include <godot_cpp/classes/animation_tree.hpp>
#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/classes/skeleton_modifier3d.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class TravCharacter : public Node3D {
	GDCLASS(TravCharacter, Node3D)

public:
	struct JumpDef {
		const char *clip;
		double low, off, land;
	};
	struct DropDef {
		const char *clip;
		double leaves, touch;
	};

	static constexpr double SWITCH = 2.0;
	static constexpr double WALK_STRIDE = 1.506;
	static constexpr double SWITCH_BAND = 0.1;
	static constexpr double FADE = 0.20;
	static constexpr double SCALE_LEAST = 0.5;
	static constexpr double SCALE_MOST = 1.8;
	static constexpr double LEAN_SLOW_DEG = 4.4;
	static constexpr double LEAN_WALK_DEG = 6.8;
	static constexpr double LEAN_FAST_DEG = 12.7;
	static constexpr double LEAN_RUN_DEG = 13.0;
	static constexpr double LEAN_TIME = 0.15;
	static constexpr double LEAN_OVER = 0.05;
	static constexpr double LAND_SOFT_CONTACT = 0.27;
	static constexpr double LAND_HEAVY_CONTACT = 0.60;
	static constexpr double RUN_FROM = 2.5;
	static constexpr double SOFT_DROP = 0.30;
	static constexpr double HARD_DROP = 1.0;
	static constexpr double JUMP_BELOW = 0.15;
	static constexpr double SHOULDER_TURN_DEG = 40.0;
	static constexpr double SIDE_ARMS_DEG = 45.0;
	static constexpr double SIDLE_ARMS_FWD_DEG = 14.0;
	static constexpr double SIDE_HEAD_DEG = 70.0;
	static constexpr double PHONE_FADE = 0.4;
	static constexpr double SIDE_REST = 0.6;
	static constexpr double BEAM_ARMS_DEG = 60.0;
	static constexpr double NARROW_FADE = 0.3;
	static constexpr double CROUCH_FADE = 0.3;
	static constexpr double HEAD_ROOM = 0.03;
	static constexpr double HEAD_OVER_JOINT = 0.23;
	static constexpr bool WALK_TO_RUN_CLIP = false;
	static constexpr double TURN_BIG_DEG = 120.0;
	static constexpr bool STOP_CLIP = true;
	static constexpr bool STOP_BY_POSE = false;
	static constexpr double START_OVER = 1.35;
	static constexpr double START_OVER_MORE = 0.3;
	static constexpr double STEEP_ARMS_DEG = 8.0;
	static constexpr double STEEP_ARMS_UP_DEG = 19.0;
	static constexpr double STEEP_STEP = 0.75;
	static constexpr double STAND_WIDE = 0.03;
	static constexpr double STEEP_TURN = 0.1;
	static constexpr double STAIR_RUN = 0.4;
	static constexpr double STAIR_PULL = 3.0;

	CharacterBody3D *body = nullptr;
	Skeleton3D *skel = nullptr;
	AnimationTree *tree = nullptr;
	AnimationPlayer *player = nullptr;
	String model_path;
	String note;
	String landing_kind;
	double lean = 0.0;
	double arm_open_deg = 9.0;

protected:
	Node3D *_pivot = nullptr;
	Ref<AnimationLibrary> _lib;
	Dictionary ACTS;                // input -> clip, in the script's order
	Dictionary _stride;
	Dictionary _length;
	String _mode = "ground";
	String _act = "ground";
	double _act_t = 0.0;
	double _mode_t = 0.0;
	double _moving = 0.0;
	double _scale = 1.0;
	double _natural = 0.0;
	double _settled = 0.0;
	const JumpDef *_jump = nullptr;
	double _jump_e = 0.0;
	bool _jump_still = true;
	double _flight = 0.6;
	const DropDef *_drop = nullptr;
	Vector3 _last_dir;
	double _measured = 0.0;
	SkeletonModifier3D *feet = nullptr;
	SkeletonModifier3D *_leg_ik = nullptr;
	SkeletonModifier3D *_orient = nullptr;
	int _chest_i = -1;
	double _lean_s = 0.0;
	double _own_mean = 0.0;
	double _stair_phase = 0.0;
	bool _stair_on = false;
	bool _steep_on = false;
	bool _steep_up = true;
	double _steep_phase = 0.0;
	double _steep_w = 0.0;
	SkeletonModifier3D *_arms = nullptr;
	String _sub;
	String _sub_in;
	double _let_go_at = -1.0;
	String _slope_in = "steep_down_start";
	String _slope_sub;
	double _stop_from = 0.0;
	double _stop_left = 0.0;
	double _gone = 0.0;
	Dictionary _yaw;
	Dictionary _fastest;
	double _change_from = 0.0;
	bool _slowing = false;
	double _wish_was = 0.0;
	double _lead_last = 0.0;
	bool _lead_rising = false;
	Dictionary _dist;
	SkeletonModifier3D *hands = nullptr;
	double _slope = 0.0;
	double _hips_fit = 0.0;
	double _slope_from = 0.0;
	double _slope_to = 0.0;
	double _slope_t = 0.0;
	int _foot_i[2] = { -1, -1 };
	double _foot_len = 0.0;
	double _jump_low = 0.5;
	double _free = 0.0;
	double _jump_y0 = 0.0;
	double _soft = 0.0;
	double _low_w = 0.0;
	double _narrow_w = 0.0;
	double _squeeze_w = 0.0;
	double _side_t = 0.0;
	SkeletonModifier3D *_trunk = nullptr;
	double _turn_deg = 0.0;
	double _phone_w = 0.0;
	double _phone_kind = 0.0;
	MeshInstance3D *_phone_box = nullptr;
	MeshInstance3D *_phone_box_l = nullptr;
	SkeletonModifier3D *_grip = nullptr;
	double _beam_arms = 0.0;
	bool _low_was = false;
	int _head_i = -1;
	// Things in the hand (trav_hold.cpp sets these each tick; NOT in the script version): the arms of a hold take
	// laid over the movement. [0] = the right arm only (a bag, a briefcase); [1] = both arms (a box, a gun).
	Ref<AnimationNodeAnimation> _hold_anim[2];
	String hold_take[2];
	double hold_w[2] = { 0.0, 0.0 };
	double hold_t[2] = { 0.0, 0.0 };
	double item_w[2] = { 0.0, 0.0 };       // a hand held on the thing itself (a box's side, a gun's forend): [left, right]

	Ref<AnimationNodeBlendTree> _make_tree();
	void _head_frame(Vector3 &r_at, Basis &r_turn);
	Transform3D _text_phone();
	Transform3D _call_phone();
	Basis _hand_turned(int f, const Vector3 &along, const Vector3 &out);
	void _phone_hold(Vector3 r_at[2], Basis r_basis[2], double r_w[2]);
	void _phone_thumbs();
	double _phase_offset(const String &n);
	void _set_mode(const String &m);
	void _show(const String &input, double t);
	void _seek();
	double _clip_length(const String &input);
	void _stairs(double dt, int st, double speed);
	double _time_for(const String &input, double d);
	void _to_loops();
	double _time_for_yaw(const String &input, double angle);
	void _turn(double dt, double wish);
	void _change(double dt, double speed, double wish);
	void _begin_change(const String &kind, double speed);
	void _start_or_stop(double dt, double speed, double wish);
	void _slope_stop(double dt, double speed);
	bool _steep_ahead();
	void _steep(double dt, double speed);
	void _ground(double dt, double speed);
	virtual Vector2 _gait_for(double v);
	virtual void _measure(double dt);
	void _lean(double dt, bool on_ground);
	double _lean_most(double pace);

	static void _bind_methods();
	bool _get(const StringName &p_name, Variant &r_ret) const;
	bool _set(const StringName &p_name, const Variant &p_value);

public:
	TravCharacter();
	void _ready() override;
	void _physics_process(double dt) override;
	void _on_jump_started(double push);
	void _on_landed(double drop);
	void _phone_refit();
	void _place_phones();
	double _lead_now();
};

} // namespace godot
