// The traversal moves (the study, stage 8 onward: "Each move is built the same way (align, play, fit, hand IK, hand
// back)"). A line-for-line translation of traversal_lab/traversal/moves/traverse.gd (the script version, the
// reference): the same names, the same numbers, the same order of work. The reasons for each thing are in the script.
#pragma once

#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class TravTraverse : public Node {
	GDCLASS(TravTraverse, Node)

public:
#include "trav_traverse_consts.inc"

	CharacterBody3D *body = nullptr;
	Variant detector;
	Dictionary record;
	int force_mirror = -1;
	bool enabled = true;
	String refused;
	int plays = 0;

protected:
	int _tick = 0;
	Dictionary _fwd;
	Dictionary _high;
	double _fps = 30.0;
	Dictionary _plan;
	Dictionary _c_fwd;
	Dictionary _c_rise;
	Dictionary _c_high;
	Dictionary _up_record;
	PackedFloat32Array _v_fwd;
	PackedFloat32Array _v_hips;
	PackedFloat32Array _t_fwd;
	PackedFloat32Array _j_fwd;
	PackedFloat32Array _o_fwd;
	PackedFloat32Array _o_rise;
	PackedFloat32Array _g_rise1;
	PackedFloat32Array _g_rise2;
	PackedFloat32Array _g_fwd2;
	PackedFloat32Array _w_fwd;
	PackedFloat32Array _w_rise;
	PackedVector2Array _d_xz;
	PackedFloat32Array _d_fall;
	PackedFloat32Array _d_yaw;
	int _catch_next = 0;
	int _narrow_ago = 999;
	PackedVector2Array _b_xz;
	PackedFloat32Array _b_fall;
	double _still = 0.0;
	double _o_high = 0.0;

	Object *det() const { return (Object *)detector; }
	double _rot_y() const { return (double)body->get_rotation().y; }
	bool _fits(const Vector3 &at, const char *height = "HEIGHT");

	double _at(const PackedFloat32Array &table, double t);
	Vector2 _at2(const PackedVector2Array &table, double t);
	bool _try_step_up(const Vector3 &v, const Vector3 &wish);
	bool _try_run_up(const Vector3 &v, const Vector3 &wish, Dictionary rec, const Vector3 &m, double top);
	bool _try_vault(const Vector3 &v, const Vector3 &wish, Dictionary rec, double adds = 0.0);
	Array _hands(const Vector3 &on_top, const Vector3 &left, double side, Dictionary rec);
	bool _try_tuck(const Vector3 &v, const Vector3 &wish, Dictionary rec, bool low);
	bool _try_over(const Vector3 &wish, Dictionary rec, double air_ct = -1.0);
	bool _try_mantle(const Vector3 &v, const Vector3 &wish, Dictionary rec, double air_ct = -1.0);
	double _climb_y(Dictionary p, double ct, double t);
	bool _try_air(const Vector3 &v);
	bool _try_grab(const Vector3 &wish, Dictionary rec, bool air = false);
	bool _try_wallrun(const Vector3 &v, const Vector3 &wish, Dictionary rec);
	bool _try_climb_down(const Vector3 &dir, double drop);
	bool _try_gap(const Vector3 &v, const Vector3 &dir, Dictionary rec, bool running);
	bool _try_balance_fall();

	static void _bind_methods();
	bool _get(const StringName &p_name, Variant &r_ret) const;
	bool _set(const StringName &p_name, const Variant &p_value);

public:
	TravTraverse();
	void _ready() override;
	void _physics_process(double dt) override;
	void _on_landed(double drop);
	// where the body is `t` seconds into each move (handed to the body's begin_move)
	Dictionary _roll_only(double t);
	Dictionary _step_off(double t);
	Dictionary _step_up(double t);
	Dictionary _run_up(double t);
	Dictionary _vault(double t);
	Dictionary _tuck(double t);
	Dictionary _over(double t);
	Dictionary _mantle(double t);
	Dictionary _grab(double t);
	Dictionary _wallrun(double t);
	Dictionary _climb_down(double t);
	Dictionary _gap_step(double t);
	Dictionary _gap_jump(double t);
	Dictionary _balance_fall(double t);
};

} // namespace godot
