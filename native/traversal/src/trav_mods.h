// The small corrections (the study, Layer 3: "Custom corrections: a script extending `SkeletonModifier3D`"), each a
// line-for-line translation of its script in traversal_lab/traversal/character/: arm_open.gd, trunk_turn.gd,
// hand_hold.gd, foot_orient.gd, finger_grip.gd. The same names; every variable the character sets by name can be
// set by name here. The reasons for each thing are in the scripts.
#pragma once

#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/classes/skeleton_modifier3d.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/basis.hpp>

namespace godot {

class TravArmOpen : public SkeletonModifier3D {
	GDCLASS(TravArmOpen, SkeletonModifier3D)
	double flat = 0.0;
	double fwd_deg = 0.0;
	double palm_back = 0.0;
	double open_deg = 9.0;
	Basis _hand_rest_inv[2];
	int _fore[2] = { -1, -1 };
	int _hand[2] = { -1, -1 };
	int _arm[2] = { -1, -1 };
	int _chest = -1;
	Basis _chest_rest_inv;
	void _bind(Skeleton3D *sk);

protected:
	static void _bind_methods() {}
	bool _get(const StringName &p_name, Variant &r_ret) const;
	bool _set(const StringName &p_name, const Variant &p_value);

public:
	void _skeleton_changed(Skeleton3D *p_old, Skeleton3D *p_new) override;
	void _process_modification_with_delta(double p_delta) override;
};

class TravTrunkTurn : public SkeletonModifier3D {
	GDCLASS(TravTrunkTurn, SkeletonModifier3D)
	double head_deg = 0.0;
	double turn_deg = 0.0;
	int _low = -1;
	int _mid = -1;
	int _neck = -1;
	int _head = -1;
	int _arms[2] = { -1, -1 };

protected:
	static void _bind_methods() {}
	bool _get(const StringName &p_name, Variant &r_ret) const;
	bool _set(const StringName &p_name, const Variant &p_value);

public:
	void _process_modification_with_delta(double p_delta) override;
};

class TravHandHold : public SkeletonModifier3D {
	GDCLASS(TravHandHold, SkeletonModifier3D)
	Variant place;
	int _hand[2] = { -1, -1 };
	Basis _kept[2];
	bool _on[2] = { false, false };

protected:
	static void _bind_methods() {}
	bool _get(const StringName &p_name, Variant &r_ret) const;
	bool _set(const StringName &p_name, const Variant &p_value);

public:
	void _process_modification_with_delta(double p_delta) override;
};

class TravFootOrient : public SkeletonModifier3D {
	GDCLASS(TravFootOrient, SkeletonModifier3D)
	Variant place;
	Variant feet;               // (set by the first version of the character only; kept so that setting it is not an error)
	int _foot[2] = { -1, -1 };

protected:
	static void _bind_methods() {}
	bool _get(const StringName &p_name, Variant &r_ret) const;
	bool _set(const StringName &p_name, const Variant &p_value);

public:
	void _process_modification_with_delta(double p_delta) override;
};

class TravFingerGrip : public SkeletonModifier3D {
	GDCLASS(TravFingerGrip, SkeletonModifier3D)
	Array w;
	Array deg;
	Array thumb_to;
	Array thumb_w;
	int _thumb[2][4];
	int _hand[2] = { -1, -1 };
	int _knuckle[2][3];
	int _fingers[2][4][3];
	double _palm_sign = 1.0;
	void _bind(Skeleton3D *sk);

protected:
	static void _bind_methods();
	bool _get(const StringName &p_name, Variant &r_ret) const;
	bool _set(const StringName &p_name, const Variant &p_value);

public:
	TravFingerGrip();
	Array hand_frame(Skeleton3D *sk, int f);
	void _process_modification_with_delta(double p_delta) override;
};

} // namespace godot
