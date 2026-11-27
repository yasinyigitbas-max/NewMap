// The things he holds: a bag or a briefcase in one hand, a box in two, a gun (27 Nov 2026, Yasin: "we are supposed to
// have a one hand briefcase or plastic bag carry and two handed box carry ... we have new weapons ... lets just make
// sure the look correct in player hand"). C++ only: there is no script version of this (C++ is the default since
// trav96). The legs and the trunk are the movement's own; the arms come from a hold take, laid over it by the
// character (the study: "Bone filters on blend nodes give upper and lower body layering"); the thing itself is placed
// at his hand each tick, from its own hand points (the kit's `grip_r`, `grip_l`).
#pragma once

#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

class TravHold : public Node {
	GDCLASS(TravHold, Node)

public:
	enum Kind { HANG = 0, BOX = 1, PISTOL = 2, LONG = 3 };
	struct Item {
		const char *prop;       // traversal/props/<prop>.scn
		Kind kind;
		const char *take;       // the take whose arms hold it
		double at;              // the moment of that take that is the hold (s)
		const char *aim_take;   // ... and aimed (guns), or nullptr
		double aim_at;
	};
	// NOT in the study: every figure here is mine, found by looking at frames (tools/traversal/try_hold.gd)
	static constexpr double FADE = 0.25;        // seconds for the arms to come onto, and off, a hold
	static constexpr double PALM_ALONG = 0.75;  // the palm point: this share of the way from the wrist to the middle knuckle
	static constexpr double PALM_OUT = 0.03;    // ... and this far out of the palm (m)

	CharacterBody3D *body = nullptr;
	int item = 0;               // 0 = nothing; 1.. = ITEMS[item - 1]
	bool aiming = false;

protected:
	Node *_chr = nullptr;
	Skeleton3D *_skel = nullptr;
	Node3D *_prop = nullptr;
	int _shown = 0;             // the item whose prop is made
	double _w = 0.0;            // how far the arms are on the hold
	double _aim_w = 0.0;
	int _bone[2][4] = { { -1, -1, -1, -1 }, { -1, -1, -1, -1 } };   // hand, middle, index, pinky knuckles; [0] left, [1] right

	void _hand(int side, Vector3 &r_palm, Vector3 &r_along, Vector3 &r_across) const;
	void _take_up(int which);

	static void _bind_methods();
	bool _get(const StringName &p_name, Variant &r_ret) const;
	bool _set(const StringName &p_name, const Variant &p_value);

public:
	void _ready() override;
	void _physics_process(double dt) override;
	void _place();
	int count() const;
	String label() const;
};

} // namespace godot
