// The feet (the study, stage 4: "pelvis offset and leg IK from foot probes"). A line-for-line translation of
// traversal_lab/traversal/character/foot_place.gd; the reasons for each thing are in the script.
#pragma once

#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/classes/skeleton_modifier3d.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include "trav_probe.h"

namespace godot {

#define TRAV_FOOT_CONSTS(X) \
	X(CONTACT, 0.025) X(PLANT_SHARE, 0.45) X(PLANT_LEAST, 0.5) X(HOLD_SHARE, 1.1) X(HOLD_LEAST, 1.2) X(PIN_MOST, 0.10) \
	X(LET_GO, 0.10) X(REACH, 0.45) X(FOOT_SPEED, 5.0) X(HIPS_DOWN, 1.5) X(HIPS_TIME, 0.10) X(HIPS_MOST, 0.25) \
	X(TILT_MOST, 0.35) X(NEAR, 0.10) X(STRAIGHT, 0.995) X(SAME_STEP, 0.10) X(WEIGHT_TIME, 0.12) X(STEP_SOFT, 0.15) \
	X(SHOE_HALF, 0.05) X(SHOE_EDGE, 0.04) X(SHOE_LONG, 0.27) X(IN_TIME, 0.15) X(SHOE_CLEAR, 0.04) X(BACK_OFF, 0.13) \
	X(HEEL_OFF, 0.07)

class TravFootPlace : public SkeletonModifier3D {
	GDCLASS(TravFootPlace, SkeletonModifier3D)

public:
#define X(n, v) static constexpr double n = v;
	TRAV_FOOT_CONSTS(X)
#undef X

	Variant body;
	Array target;
	Array pole;
	Array goal;
	double weight = 0.0;
	double clip_slope = 0.0;
	bool stride_fit = false;
	Vector3 stride_dir;
	Array land_at;
	bool by_speed = false;
	double stand_wide = 0.0;
	Variant hands;
	double step_high = 0.0;
	double step_edge = 0.0;
	double step_rise = 0.0;
	double step_real = 0.0;
	double base = 0.0;
	double hips_fit = 0.0;
	double stand_on = 0.0;
	double gap_fit = 0.0;
	double ledge_fit = 0.0;
	bool pinning = true;
	bool grounding = true;
	double _toe_rest = 0.0;
	double _ankle_rest = 0.0;
	double _pelvis = 0.0;
	double _ride = 0.0;

private:
	Vector3 _in[2];
	Vector3 _gap_in[2];
	Vector3 _hips_out;
	int _hips = -1;
	int _thigh[2] = { -1, -1 };
	int _shin[2] = { -1, -1 };
	int _foot[2] = { -1, -1 };
	int _toe[2] = { -1, -1 };
	double _leg_len[2] = { 0.0, 0.0 };
	double _front[2] = { 1.0, 1.0 };
	bool _planted[2] = { false, false };
	Vector3 _pin[2];
	Vector3 _corr[2];
	Vector3 _was[2];
	bool _was_ok = false;
	double _g[2] = { 0.0, 0.0 };
	bool _g_ok = false;
	double _swing[2] = { 0.0, 0.0 };
	Vector3 _hold_p[2];
	double _hold_g[2] = { 0.0, 0.0 };
	Vector3 _from_p[2];
	double _from_g[2] = { 0.0, 0.0 };
	Vector3 _to_p[2];
	double _to_g[2] = { 0.0, 0.0 };
	double _lump[2] = { 0.0, 0.0 };
	bool _bound[2] = { false, false };
	uint64_t _last_frame = 0;      // (the physics frame of the last call: a long gap is a fresh start, see the .cpp)

	trav::Hit _ground(CharacterBody3D *bd, const Vector3 &at, double feet_y);
	void _onto(CharacterBody3D *bd, Skeleton3D *sk, const Transform3D &xf, double feet_y, Vector3 out[2]);

protected:
	static void _bind_methods();
	bool _get(const StringName &p_name, Variant &r_ret) const;
	bool _set(const StringName &p_name, const Variant &p_value);

public:
	TravFootPlace();
	void bind(Skeleton3D *sk);
	void _process_modification_with_delta(double p_delta) override;
};

} // namespace godot
