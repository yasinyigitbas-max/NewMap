// The hands (the study: "From hand contact to release, hold the hands on the measured ledge points with arm
// `TwoBoneIK3D`"). A line-for-line translation of traversal_lab/traversal/character/hand_place.gd; the reasons for
// each thing are in the script.
#pragma once

#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/classes/skeleton_modifier3d.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/callable.hpp>

namespace godot {

class TravHandPlace : public SkeletonModifier3D {
	GDCLASS(TravHandPlace, SkeletonModifier3D)

public:
	static constexpr double PALM = 0.08;
	static constexpr double BAND = 0.15;
	static constexpr double STRAIGHT = 0.995;
	static constexpr double HIPS_MOST = 0.20;
	static constexpr double EASE = 0.10;
	static constexpr double BEND_MOST_DEG = 65.0;
	static constexpr double BEND_RATE_DEG = 600.0;

private:
	Variant body;
	Array hold_at;
	Array hold_w;
	Array hold_turned;
	Array hold_basis;
	Array hold_loose;
	Array hold_flat;
	Callable refit;
	bool on = false;
	double clip_slope = 0.0;
	double hand_low = 0.0;
	Array target;
	Array pole;
	Array ik;
	double hips_down = 0.0;
	Array reach;
	double bend_deg = 0.0;
	int _spine = -1;
	int _upper[2] = { -1, -1 };
	int _fore[2] = { -1, -1 };
	int _hand[2] = { -1, -1 };
	double _len[2] = { 0.0, 0.0 };

protected:
	static void _bind_methods();
	bool _get(const StringName &p_name, Variant &r_ret) const;
	bool _set(const StringName &p_name, const Variant &p_value);

public:
	TravHandPlace();
	void bind(Skeleton3D *sk);
	void _process_modification_with_delta(double p_delta) override;
};

} // namespace godot
