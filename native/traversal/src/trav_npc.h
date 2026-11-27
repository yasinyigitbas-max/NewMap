// An NPC body on the player's clips: line-for-line translations of traversal_lab/traversal/npc/body_fit.gd and
// npc_character.gd. The reasons for each thing are in the scripts. The player's character is TravCharacter and is
// not changed by these.
#pragma once

#include "trav_character.h"

namespace godot {

class TravBodyFit : public SkeletonModifier3D {
	GDCLASS(TravBodyFit, SkeletonModifier3D)
	double leg = 1.0;
	double seat = 0.0;
	double moved = 0.0;
	int _hips = -1;
	int _chain[2][4];
	Vector3 _theirs[2][4];
	double _sole[2] = { 0.0, 0.0 };
	double _sole_p[2] = { 0.0, 0.0 };

protected:
	static void _bind_methods();
	bool _get(const StringName &p_name, Variant &r_ret) const;
	bool _set(const StringName &p_name, const Variant &p_value);

public:
	void bind(Skeleton3D *sk);
	void _process_modification_with_delta(double p_delta) override;
};

class TravNpcCharacter : public TravCharacter {
	GDCLASS(TravNpcCharacter, TravCharacter)
	static constexpr double SEAT_EASE = 0.2;
	SkeletonModifier3D *fit = nullptr;
	double leg = 1.0;
	double _seat = 0.0;

protected:
	static void _bind_methods() {}
	bool _get(const StringName &p_name, Variant &r_ret) const;
	Vector2 _gait_for(double v) override;
	void _measure(double dt) override;

public:
	void _ready() override;
	void _physics_process(double dt) override;
};

} // namespace godot
