// CityPed: one person with a real body, all C++. The old game's 50-bone figure (characters/rocketbox: skeleton, body
// mesh, clips), animated as long as nothing touches it; when it is pushed or hit, the balancing body of ped_body.h
// takes over from the very pose the animation had, and the bones follow that body while it staggers, falls or lies;
// when it stands quietly again the animation takes over (blended), and from the ground it gets up (the "get_up" clip,
// blended in from how it lies).
// Written new on Yasin's word, 19 Nov 2026 ("gta 5 level npcs ... balance themselves, be able to pushed around and
// resist falls"; "you can get the old npcs from the game BUT FULLY WRITTEN IN C PLUS PLUS").
// This is the BODY of one person near the player. The walking crowd (who goes where) is another class; it will hand
// its nearest walkers to this one. Nothing here is called from script per frame.
#pragma once

#include "ped_body.h"

#include <godot_cpp/classes/animation_player.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class CityPed : public Node3D {
	GDCLASS(CityPed, Node3D)

public:
	enum { MODE_ANIM = 0, MODE_BODY = 1, MODE_GETUP = 2 };

private:
	pb::Person body;
	int mode = MODE_ANIM;
	String body_id = "M1", clip = "idle";
	double skill = 1.0;
	bool made = false;
	Node3D *model = nullptr;
	Skeleton3D *skel = nullptr;
	AnimationPlayer *anim = nullptr;
	int bone[pb::NB];
	Transform3D bone_rest[pb::NB];   // each driven bone standing, in this node's own frame
	Vector3 centre_rest[pb::NB];     // each body part's centre standing, in this node's own frame
	Transform3D skel_in_node;        // the skeleton node inside this node
	double t_mode = 0.0, getup_len = 3.0;
	struct Shove { int part; Vector3 imp; int frames; };
	Shove shove[4]; int n_shove = 0;
	pb::Box boxes[pb::MAX_BOXES]; int n_boxes = 0;
	// told
	double jump_at_takeover = 0.0;   // how far a driven bone moved when the body took over, m (must be ~0)
	int takeovers = 0, falls = 0, getups = 0;

	void make();
	void take_over(const Vector3 &p_vel);
	void write_bones();
	void to_animation(const StringName &p_clip, double p_blend, bool p_from_ground);

protected:
	static void _bind_methods();

public:
	void _ready() override;
	void _physics_process(double p_delta) override;

	void set_body_id(const String &p_id) { body_id = p_id; }
	String get_body_id() const { return body_id; }
	void set_clip(const String &p_clip);
	String get_clip() const { return clip; }
	void set_skill(double p_s) { skill = p_s; }
	double get_skill() const { return skill; }

	// A shove or a blow: p_impulse in N s, spread over a fifth of a second, on the part nearest to p_at (world)
	void push(const Vector3 &p_impulse, const Vector3 &p_at);
	// Something solid that moves (a car), for this step and until told again: box p_index at p_centre with half sizes,
	// heading and speed. p_count = how many boxes there are now.
	void set_box(int p_index, const Vector3 &p_centre, const Vector3 &p_half, double p_yaw, const Vector3 &p_velocity, int p_count);
	// mode (0 animation, 1 body, 2 getting up), the body's state (0 balance, 1 fall, 2 rest), steps, lean, heights, counts
	Dictionary get_state() const;
};

} // namespace godot
