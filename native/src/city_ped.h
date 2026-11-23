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
#include <godot_cpp/templates/hash_map.hpp>

#include "ped_body.h"

#include <godot_cpp/classes/animation_player.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/shader_material.hpp>
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
	double skill = 1.0, clip_at = -1.0;
	bool made = false;
	Node3D *model = nullptr;
	Skeleton3D *skel = nullptr;
	AnimationPlayer *anim = nullptr;
	MeshInstance3D *mi = nullptr;
	StringName cur_clip;             // (driven by the crowd) the clip that runs, and the moment it is held at (-1 = it runs)
	StringName cur_req;              // the clip asked for (an old name the Mixamo table may play another clip for)
	uint32_t var_seed = 0;           // this person's own pick among the takes of an action (set_variant)
	HashMap<StringName, int> var_uses;   // how often each action was played (the next take of a one-off, in turn)
	bool alias_on = true;            // (the car's driver, the bicycle's rider: their clips are fitted by hand, kept)
	double cur_hold = -1.0;
	int cur_token = 0;
	// getting up: the Quaternius clip "LayToIdle" (lying on the back to standing). Where its figure lies at its start, in
	// this node's frame: the way from its hips to its head, and where its hips are
	bool has_getup = false;
	float getup_axis = 0.0f;
	Vector3 getup_hips;
	bool can_body = true;            // (a child's figure is drawn smaller: it has no physical body of its own size)
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
	bool stay_down = false;          // (the hurt who wait for a medic) lying, it does not get up until let

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
	String std_body_scene() const;           // a body on the standard skeleton: its scene (empty: the Rocketbox figure)
	String lib_path(const String &p_stem) const;   // a clip library for this body ("" the base one)
	void set_clip(const String &p_clip);
	String get_clip() const { return clip; }
	void set_clip_at(double p_t);
	double get_clip_at() const { return clip_at; }
	void set_skill(double p_s) { skill = p_s; }
	double get_skill() const { return skill; }

	// ---- for the crowd (C++ only): this figure becomes another person; while it is animated the crowd says where it
	// stands and what it does; what the crowd needs to know of its body
	void become(const String &p_body, const Ref<Mesh> &p_mesh, const Ref<ShaderMaterial> &p_look, bool p_can_body);
	// p_hold: >= 0 held at that moment of the clip; -1 it runs (and starts again when it ends); -2 played once and
	// held on its last frame. A new p_token starts the same clip again (the next blow of a fight).
	void drive(const Transform3D &p_at, const StringName &p_clip, double p_speed, double p_hold, int p_token = 0);
	double clip_len(const StringName &p_clip) const;
	// (a car's wheel over a downed body, the Animator 20 Nov) the highest top of its body's parts within p_r of p
	// (level distance), or -1e9: only while its physical body has it (lying, falling, getting up)
	float top_over(const Vector3 &p_at, float p_r) const;
	double clip_pace(const StringName &p_clip, double p_t) const;
	double clip_curve(const StringName &p_clip, const String &p_key, double p_t, double p_def) const;
	double clip_meta(const StringName &p_clip, const String &p_key, double p_def) const;
	// a clip's hips at a moment of it, read from its own tracks (the figure's own frame, metres): how far the clip itself
	// carries the body (a climb's rise and travel); and the moment the playing clip is at now
	Vector3 clip_hips_at(const StringName &p_clip, double p_t) const;
	double clip_pos() const;
	static bool stride_of(const StringName &p_clip, double &r_left_down, int &r_strides);
	StringName current_clip() const { return cur_req; }
	// THE MIXAMO TAKES (Yasin, 21 Nov: "scrap existing ones and replace what we have with these, if our old pack had the
	// act but this list doesnt have anything to replace it, keep the old one ... some of them have variety, use the varied
	// ones in rotation"): an old clip name asked for plays a Mixamo take (city_ped_takes.cpp); a loop keeps this
	// person's own take, a one-off plays the next take each time. What plays: the take for a name, the stride of the
	// clip that runs now, a loop's own ground pace (m/s, its meta, or p_def)
	StringName take_of(const StringName &p_clip) const;
	StringName take_next(const StringName &p_clip);
	bool take_cycles(const StringName &p_clip) const;
	double take_last_pos = -1.0;   // (a cycling loop: where its take was, to see it come round)
	bool stride_any(const StringName &p_clip, double &r_left_down, int &r_strides) const;
	StringName playing() const { return cur_clip; }
	bool stride_now(double &r_left_down, int &r_strides) const;
	double ground_v(const StringName &p_clip, double p_def) const;
	void set_variant(int p_seed) { var_seed = (uint32_t)p_seed; }
	void set_alias(bool p_on) { alias_on = p_on; }
	// (the Animator, 21 Nov; Yasin: "paramedic should do cpr and rceiving npc shoud lay flat") its body lying on the ground
	// hands over to a lying clip: the clip's figure laid where the body lies (hips on hips, head toward head), the clip
	// running; false when it is not lying in its body or has no such clip
	bool lie_as(const StringName &p_clip);
	void start_at(double p_t) { pending_seek = p_t; }
	void set_next_blend(double p_s) { next_blend = p_s; }   // (the next fresh clip blends in over this long: 0 a cut, where two roots far apart would swing the hips through the blend)
	double next_blend = -1.0;   // (the next fresh clip starts this far in: a start clip's still lead-in skipped)
	double pending_seek = -1.0;
	// what this figure looks like (its body's mesh and its clothes): another figure of the same person takes them on
	String get_body() const { return body_id; }
	Ref<Mesh> get_body_mesh() const;
	Ref<ShaderMaterial> get_look() const;
	Vector3 bone_world(const char *p_bone) const;   // (traces) a bone's place as drawn, world
	int get_mode() const { return mode; }
	// a hard knock: once down it lies until told (a medic has been); false: it gets up as it would
	void set_stay_down(bool p_on) { stay_down = p_on; }
	bool get_stay_down() const { return stay_down; }
	// ---- the new movement system (mo_motor.h; docs/ANIMATION_PLAN.md): it plays the clips itself, so it reaches the
	// figure's player, the skeleton's place in this node, and loads the player's clip libraries ("pwalk", "prun", "pidle",
	// "ptrav", "pact": characters/rocketbox/clips_player_<walk|run|idle|trav|act>_<g>.res) beside the crowd's
	AnimationPlayer *anim_player() const { return anim; }
	Transform3D skel_frame() const { return skel_in_node; }
	bool add_library(const StringName &p_name, const String &p_stem);
	// the clip CityPed::drive played is forgotten (another system played clips meanwhile): its next drive starts fresh
	void forget_clip() { cur_req = StringName(); cur_clip = StringName(); cur_hold = -1.0; cur_token = 0; }
	Skeleton3D *skeleton() const { return skel; }   // (the player's bicycle reaches its feet and hands to the pedals and grips)
	Vector3 body_at() const;
	float body_yaw() const { return body.heading; }
	// A shove or a blow: p_impulse in N s, spread over a fifth of a second, on the part nearest to p_at (world)
	void push(const Vector3 &p_impulse, const Vector3 &p_at);
	// Thrown as a whole (off a bicycle, by a car): every part of the body leaves at p_velocity (m/s), and p_impulse (N s)
	// on the part nearest p_at turns it over (a push on one part with the whole body's momentum flew it up like a kite)
	void launch(const Vector3 &p_velocity, const Vector3 &p_impulse, const Vector3 &p_at);
	// ... and beaten: thrown so, it falls (it does not catch itself) and lies; it gets up by itself later
	void knock_down(const Vector3 &p_velocity, const Vector3 &p_impulse, const Vector3 &p_at);
	// Something solid that moves (a car), for this step and until told again: box p_index at p_centre with half sizes,
	// heading and speed. p_count = how many boxes there are now.
	void set_box(int p_index, const Vector3 &p_centre, const Vector3 &p_half, double p_yaw, const Vector3 &p_velocity, int p_count);
	// mode (0 animation, 1 body, 2 getting up), the body's state (0 balance, 1 fall, 2 rest), steps, lean, heights, counts
	Dictionary get_state() const;
};

} // namespace godot
