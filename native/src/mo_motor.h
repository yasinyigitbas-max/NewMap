// mo::Motor: a character's movement and its animation, as one thing (the new movement system; docs/ANIMATION_PLAN.md,
// .claude/skills/coronado-animation). Written new on Yasin's word, 22 Nov 2026: "studio quality animations", "you might
// have to make a new system from scratch for players movement. I eventually want every npc to have players
// capabilities too".
// It belongs to no kind of character: a controller (the player's keys today, an NPC's mind later) says where it
// wants to go and how fast (Intent); a Host moves its body in the world (the player's CharacterBody3D today). The motor
// picks the clips, plays them itself (the figure's AnimationPlayer in manual mode, its time and rate set every
// frame), and owns the body's motion: in a loop the controller's pace moves the body and the loop plays at it; in a
// start, a stop or a turn the clip's own travel (its vz / vx / yaw curves) moves the body, so the planted foot stays
// where the mocap put it. Never both at once.
// Every change of clip is a hand-over (MoInertial, no crossfade) into the moment of the new clip whose feet are most
// like the feet now (mo_clip pose matching): a stop on the right foot, a loop changed in step.
// THIS STEP (22 Nov): locomotion on flat or gently sloped ground: idle (with fidgets), starts (walk / run, turning
// starts), the walk / jog / run loops, stops, turns on the spot, pivots while moving. Everything else (jumps, climbs,
// crouch, cover, acts) is still the old code's: the motor hands the figure back and takes it again (begin / end).
#pragma once

#include "mo_clip.h"

#include <godot_cpp/classes/animation_player.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/string_name.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cstdint>

namespace godot {

class CityPed;
class Node3D;
class MoInertial;
class MoLimbs;

namespace mo {

// What the controller wants this frame
struct Intent {
	Vector3 dir;          // world, level; length 0..1 (0: stand)
	float speed = 0.0f;   // m/s wanted at full stick
	bool crouch = false;  // crouched (held as a state by the controller)
	bool cover = false;   // into cover at the nearest wall / out of it (a request: an NPC's mind; the player's cover is automatic)
	bool jump = false;    // a jump (a request, this frame)
	int carry = 0;        // carrying: 0 nothing, 1 a box (both hands), 2 a briefcase, 3 a shopping bag (right hand)
};

// What moves the body in the world
struct Host {
	virtual ~Host() {}
	virtual Vector3 position() const = 0;
	// move by this velocity for dt (it slides along walls); the velocity it actually got
	virtual Vector3 slide(const Vector3 &p_vel, float p_dt) = 0;
	virtual bool on_floor() const = 0;
	// moved at once by this (level, a few cm: a hand-over lines up the new clip's planted foot with the one down);
	// false when something is in the way (it then stays)
	virtual bool shift(const Vector3 &p_by) = 0;
	// the world, for traversal: a ray (the body itself left out); the body put somewhere without colliding (a move's own
	// path: the clip owns it); can a standing body be at a place
	virtual bool ray(const Vector3 &p_from, const Vector3 &p_to, Vector3 &r_pos, Vector3 &r_normal) const = 0;
	virtual void teleport(const Vector3 &p_at) = 0;
	virtual bool room_at(const Vector3 &p_at) const = 0;
};

// One clip as the motor knows it
struct Clip {
	StringName name;
	Ref<Animation> a;
	const ClipData *d = nullptr;
	float ground_v = 0.0f, yaw_end = 0.0f;
	Vector3 off;           // the figure drawn this far back of the body (figure frame, level): a clip whose hips stand
	                       // away from its origin played in place (the box idle: the tail of a walk-stop, 1.4 m on)
	double lo = 0.0;       // a loop over [lo, its end] only (the box idle's held tail)
	bool ok() const { return d != nullptr; }
	float curve(const char *p_key, double p_t, float p_def = 0.0f) const;
	float meta(const char *p_key, float p_def) const;
};

class Motor {
public:
	enum State { OFF = 0, IDLE, START, MOVE, STOP, TURN, PIVOT, TRAV, CROUCH, STANCE, COVER_IN, COVER, COVER_OUT, CARRY, JUMP, AIR, LAND, RUNJUMP, DESCEND };

	bool attach(CityPed *p_fig);
	// the movement set (0, 1, 2: different clips that go together; mo_sets.cpp) - changed when he next stands
	void set_style(int p_style);
	int get_style() const { return style; }
	static int style_count();
	static const char *style_clip(int p_style, const char *p_set1);
	int style = 0, style_want = 0;
	// STAMINA (Yasin, 24 Nov: "it will happen after running for 30 second or jumping 5 times back to back"): out of it,
	// the idle is set 2's ("idle 2 is after stamina runs out"); back after a rest
	bool tired = false, idle_tired = false;
	float run_t = 0.0f, rest_t = 0.0f, since_land = 99.0f;
	int jump_chain = 0, n_tired_spells = 0;
	void stamina_step(float p_dt);   // loads the libraries, puts MoInertial first on the skeleton; false: no clips
	bool ready() const { return fig != nullptr && n_loops > 0; }
	// take the figure over (from whatever played it) / give it back; p_speed, p_yaw: the body's now
	void begin(float p_yaw, float p_speed);
	void end();
	bool active() const { return st != OFF; }
	void step(float p_dt, const Intent &p_in, Host &p_host);
	bool in_trav() const { return st == TRAV; }
	bool air_ready_pub() const { return air_ready(); }
	bool in_air() const { return st == JUMP || st == AIR || st == LAND || st == RUNJUMP || st == DESCEND; }
	bool in_cover() const { return st == COVER_IN || st == COVER || st == COVER_OUT; }
	bool crouched() const { return st == CROUCH || (st == STANCE && stance_to == 1) || (in_cover() && !cv_tall); }

	// the state for the rest of the game (the camera, the old code when it takes over again)
	float yaw = 0.0f, speed = 0.0f;
	State st = OFF;
	const char *state_name() const;
	String clip_name() const { return cur ? String(cur->name) : String(); }
	double clip_time() const { return t; }
	bool foot_down(int p_side) const { return cur && cur->d->lerp(t).down[p_side & 1]; }   // the clip has that foot planted now
	// tuning (Yasin's notes go here first)
	float walk_turn_rate = 3.4f, run_turn_rate = 2.3f, idle_turn_rate = 5.0f, crouch_turn_rate = 2.5f, carry_turn_rate = 2.6f;   // rad/s while moving
	float accel_up = 2.8f, accel_down = 3.5f;                                  // m/s2 in a loop
	float blend_loop = 0.25f, blend_step = 0.2f, blend_idle = 0.3f;            // hand-over times, s
	float gait_hold = 0.4f;                                                    // s in a loop before another gait
	// (the tests)
	int n_starts = 0, n_stops = 0, n_turns = 0, n_pivots = 0, n_gait = 0, n_fidgets = 0, n_switch = 0;
	float last_entry_cost = 0.0f;
	bool into_loop = false;
	Vector3 last_follow; int n_pin_fix = 0;
	Vector3 drawn_pull[2]; bool drawn_locked[2] = { false, false }; Vector3 drawn_pel;
	Vector3 follow_v; float follow_acc = 4.0f;
	float follow_rate = 3.0f, follow_max = 0.5f, follow_sum = 0.0f;   // the body drawn toward its planted feet (per second; (tests) the total, m)
	int n_hips_aligned = 0; float last_align_yaw = 0.0f; int n_aligned = 0; float last_align = 0.0f;   // (tests) contact alignments made, the last one's size (m)
	int inert_switches() const;
	float inert_jump() const;
	bool inert_live() const;
	float foot_pull(int p_side) const;   // (tests) how far the foot lock moved that foot from the clip this frame, m
	int foot_locks() const;
	int foot_steps() const;
	float hips_drop() const;
	float floor_y() const { return draw_y; }   // (tests) the figure's floor as drawn
	bool foot_stepping(int s) const;
	Array dump(const String &p_clip) const;
	void keep_loops(const PackedStringArray &p_names);   // (tuning) only these loops, by name ("pwalk/walk_mx3", "prun/fast_b" ...)   // (tests / tools) a clip's measured frames: t, feet, down, hips, root_v, yaw

private:
	CityPed *fig = nullptr;
	AnimationPlayer *anim = nullptr;
	MoInertial *inert = nullptr;
	MoLimbs *limbs = nullptr;
	Clip idles[4]; int n_idles = 0;
	Clip tired_idles[4]; int n_tired = 0;          // played while out of stamina (set 2's idles)
	Clip fidgets[6]; int n_fidgets_c = 0;
	Clip loops[16]; int n_loops = 0;               // sorted by ground_v
	Clip w_start[2], r_start[2], r_tstart[2];      // walk starts (two feet), run starts, run turning starts (L, R)
	Clip w_stop[2], r_stop[2];
	Clip s_turn_l[3], s_turn_r[3]; int n_tl = 0, n_tr = 0;   // standing turns
	Clip w_pivot[2], r_pivot[2];                   // 180s while walking / running (L, R)
	const Clip *cur = nullptr;
	double t = 0.0;                 // time in the current clip
	float rate = 1.0f;
	float yaw0 = 0.0f, turn_k = 1.0f;   // a clip that turns: the facing it began at, its turn scaled to the angle wanted
	double hand_at = -1.0;          // a start / pivot: when it hands over to the loop
	int loop_i = -1;                // the loop playing (MOVE) or to go on to
	float loop_t = 0.0f;            // how long this loop has played (a gait is held at least gait_hold)
	float idle_t = 0.0f, fidget_in = 10.0f;
	int last_idle = -1, last_fidget = -1, last_start = 0, last_walk = -1;
	uint32_t rng = 0x2545f491u;
	float rnd();

	Clip load(const char *p_name);   // (by its set-1 name: the set's own clip for it, mo_sets.cpp)
	void load_clips();
	void play(const Clip &p_c, double p_t0, float p_blend);
	int pick_loop(float p_speed, int p_keep, bool p_random = false);
	void to_idle(float p_blend);
	void to_loop(int p_i, float p_blend);
	void to_stop();
	void stop_with(const Clip *p_c, double p_t0, float p_cost);
	void to_start(float p_angle, float p_want);
	void to_turn(float p_angle);
	void to_pivot(const Clip &c, double best_t, float p_angle, float p_cost);
	bool pivot_when(float p_d);
	Vector3 clip_vel(const Clip &p_c, double p_t) const;   // world, from the clip's vz / vx and the turn so far
	void advance(float p_dt);   // the clip's time on, the pose set
	// CONTACT ALIGNMENT: at a hand-over the new clip is placed so its planted foot lands on the foot already pinned there
	// (the hand-over smooths the hips; the foot does not move). Without it the pin held the old foot while the hand-over
	// pulled the drawn foot 27 cm toward the new clip's, and it let go.
	bool align_contacts(const Clip &p_c, double p_t0);   // (true: a planted foot was there to align)
	void align_hips(const Clip &p_c, double p_t0);
	void align_facing(const Clip &p_c, double p_t0);
	Host *host = nullptr;       // (the body, while step runs)

	// ---- TRAVERSAL (mo_motor_trav.cpp; step 3 of docs/ANIMATION_PLAN.md): vaults and climbs as root-motion clips,
	// fitted to the world by MOTION WARPING (the anchor shifted so the clip's hand contact lands on the real edge: level
	// over the approach, height only while the feet are off the ground) and the HANDS PINNED to the real top during the
	// clip's own contact windows. The body follows the clip's hips; nothing else moves it.
	struct Trav {
		const Clip *c = nullptr;
		double t0 = 0.0, t_end = 0.0, tc = 0.0, tw = 0.0, ty0 = 0.0, he = 0.0, land_t = 0.0;   // (tw: the warp done by the first hand touch)
		Vector3 anchor0, delta, edge_p, edge_n;   // the anchor at the start; the warp's full shift; the edge (world), out toward him
		float yaw = 0.0f, top_y = 0.0f, start_y = 0.0f, land_dy = 0.0f;
		bool vault = false;
		double hs[2] = { -1, -1 }, hend[2] = { -1, -1 };   // each hand's contact window (clip time)
		double hk[2] = { -1, -1 };                          // each hand's stillest moment in it (its spot is where the clip has it then)
		bool hand_set[2] = { false, false }; Vector3 hand_w[2];
		Vector3 c_contact;                       // the primary hand at contact (figure frame)
		float clip_clear = 0.0f;                 // the clip's own hips over its top, at most (m)
		const Clip *then = nullptr;              // a second move on the same edge, from where this one ends (the hang, then the climb)
		int after = 0;                           // 1: it ends crouched on the top - stood up by Crouched_To_Standing
	};
	Trav tr;
	Clip v_walk, v_run, c_low, c_mid, c_mid_run, c_hang, c_braced;
	bool trav_probe(const Vector3 &p_dir, float p_speed);
	bool trav_start(const Clip &p_c, const Vector3 &p_face, const Vector3 &p_n, float p_top_y, float p_land_y, bool p_vault,
			bool p_chain = false, const Clip *p_then = nullptr, int p_after = 0);
	void trav_step(float p_dt);
	Vector3 trav_anchor(double p_t) const;

	// ---- JUMPS, FALLS, LANDINGS (mo_motor_air.cpp; step 7)
	Clip ai_up, ai_loop, ai_run, ai_stand, ai_stand2, ai_walk, ai_soft, ai_hard, ai_flat, ai_getup;
	double tc_soft = 0.0, tc_hard = 0.0, tc_flat = 0.0;   // each landing's first touch of the feet (clip time)
	Vector3 air_v; float air_top = 0.0f, air_t = 0.0f, jump_v = 4.3f;
	void load_air();
	bool air_ready() const;
	float ground_below(const Vector3 &p_at, float p_down) const;
	void jump_start(const Vector3 &p_dir, float p_want_speed);
	bool run_jump_when();
	float jump_pending = 0.0f;   // a jump asked while running, waiting for its stride (s left)
	void air_start(const Vector3 &p_vel, bool p_from_jump);
	void air_step(float p_dt, const Intent &p_in);
	Vector3 fwd_of_yaw() const;
	// DOWN OFF A LEDGE, not running (Yasin, 23 Nov: "implement step down or slower jump down or climb down when not running
	// at height"): a hop (to 0.65 m), a jump down landing standing (to 1.2 m), a climb down (to 2 m)
	struct Descent { Clip c; float ledge_h = 0.0f; double t_off = 0.0, t_land = 0.0, t_drop = 0.0; float edge_z = 0.3f;
		int hand = -1; double h0 = 0.0, h1 = 0.0; };   // (t_drop: its feet below its ledge; edge_z: its edge ahead of its start; the hand that reaches for the corner and when)
	const Descent *dn_cur = nullptr; Vector3 dn_hand_w; Vector3 dn_edge; Vector3 dn_n; int dn_hand = -1; double dn_h0 = 0.0, dn_h1 = 0.0;
	Descent dn_hop, dn_jump, dn_climb;
	void load_descent(Descent &r_d, const char *p_name);
	bool descend_probe(const Vector3 &p_fwd);
public:
	int n_descents = 0;
	int n_jumps = 0, n_falls = 0, n_landings = 0, n_soft = 0, n_hard = 0, n_flat = 0;   // (tests)
	float land_fallen = 0.0f;                                                          // (tests) the last landing's height fallen
private:

	// ---- CARRYING (mo_motor_carry.cpp; step 6): a box in both hands (walk, jog, its own held idle), a briefcase or a
	// shopping bag in the right hand; the box's hands pinned to its sides, the box where the clip's hands hold it
	Clip ca_walk, ca_jog, ca_idle, bg_idle, bg_walk, sb_walk;
	int carry = 0;
	float carry_w = 0.0f;           // the hands on the prop (eased in and out)
	float carry_yaw = 0.0f; bool carry_yaw_ok = false;
	Vector3 hc_s, hc_l, hc_v; bool hc_ok = false, carry_was_box = false;   // the box's centre, on a spring
	float box_w = 0.42f;            // the box's width (between the palms), m: from the carry walk's hands
	float box_d = 0.30f, belly = 0.14f;   // its depth; the belly in front of the hips' middle (m)
	void load_carry();
	void carry_step(float p_dt, const Intent &p_in, float p_d, bool p_want, Vector3 &r_vel);
	void carry_hands(float p_dt);
	void to_carry_idle(float p_blend);

	// ---- CROUCH AND COVER (mo_motor_cover.cpp; step 5): the crouch (its own idle and walk, in and out by their clips) and
	// cover against a wall (standing behind one from 1.45 m, crouched behind a lower one from 0.6 m): in by a clip warped
	// onto the wall, along it by the cover sneaks at the wall's distance, out by a clip. Clips that carry the body in their
	// hips (in, out, the stance changes) play as ROOT clips: the figure held at an anchor, the body following the hips.
	Clip cr_idle, cr_walk, cr_in, cr_out;
	Clip cv_in[2], cv_idle[2], cv_out[2], cv_sneak_l[2], cv_sneak_r[2];   // [0] low (crouched), [1] tall
	struct RootPlay { const Clip *c = nullptr; Vector3 a_from, a_to; float yaw = 0.0f; double t0 = 0.0, t_warp = 0.0; bool vy_on = false; float ay_from = 0.0f, ay_to = 0.0f; double vy_t0 = 0.0, vy_t1 = 0.0; };
	RootPlay rp;
	int stance_to = 0;              // STANCE: 0 to standing, 1 to crouched
	Vector3 cv_w, cv_n; bool cv_tall = true; int cv_dir = 0; float cv_t = 0.0f;
	bool align_full = false;        // the next hand-over may turn the figure any amount to the drawn hips (cover's own frames)
	void load_cover();
	bool cover_probe(const Vector3 &p_dir, float p_reach, bool p_around);
	Vector3 fwd_dir() const;
	void root_start(const Clip &p_c, double p_t0, float p_blend, float p_yaw, const Vector3 *p_end_hips, bool p_face);
	bool no_align = false, face_only = false;
	float last_gap = -1.0f;
public:
	float sneak_off = 0.0f, sneak_turned = 0.0f; Vector3 dbg_v; float dbg_t = 0.0f;
private:
	Vector3 root_anchor(double p_t) const;
	bool root_step(float p_dt);     // true at the clip's end
	void to_crouch(float p_blend);
	void to_stance(int p_to);
	void crouch_step(float p_dt, const Intent &p_in, float p_d, bool p_want, Vector3 &r_vel);
	void cover_step(float p_dt, const Intent &p_in, Vector3 &r_vel);
	void cover_sneak(int p_dir);
	float cover_dist(const Vector3 &p_at) const;   // the body's distance to the cover's wall (-1: no wall there)

public:
	float cover_d_tall = 0.30f, cover_d_low = 0.38f;   // the body's distance from the wall in cover (m)
	int carrying() const { return carry; }
	Transform3D carry_xf;                              // where the carried thing is drawn (world): the box's centre / the bag's handle
	float carry_weight() const { return carry_w; }
	float box_width() const { return box_w; }
	float box_depth() const { return box_d; }
	void set_prop(Node3D *p_node);   // the carried thing's node: placed on the drawn hips each frame (MoLimbs)
	Vector3 carry_hand_target(int s) const;            // (tests) where each hand is pinned (world)
	int n_covers = 0, n_sneaks = 0;                    // (tests)
	float cover_gap() const;                           // (tests) the body's distance to the wall now (m)
	// (tests) traversal: counts, the last move, and how well it fitted
	int n_vaults = 0, n_climbs = 0;
	String last_trav;
	float trav_hand_miss = 0.0f;    // the worst distance a pinned hand was drawn from its point on the edge (m)
	float trav_hand_dy = 0.0f;      // the worst a pinned hand's height was off the top + its rest (m)
	float trav_hips_over = 0.0f;    // the hips' height over the top, at most, minus the clip's own (m): "the sky"
	float trav_warp = 0.0f;         // the warp's size at the last start (m)
	float trav_top = 0.0f;          // the top's height over where he stood (m)
	Vector3 trav_win() const { return Vector3((float)tr.tc, (float)tr.hs[0], (float)tr.hs[1]); }   // (tests) contact, hand windows' starts
	float trav_wmax = 0.0f;         // (tests) the largest hand weight given
	Array trav_hands() const;       // (tests) [L target, L weight, R target, R weight] now
private:
	void place(Host &p_host, float p_dt = 0.0f);
	void ground_feet(Host &p_host);
	Vector3 step_clear(Host &p_host, const Vector3 &p_ankle, const Vector3 &p_toe);
public:
	void replace(Host &p_host);   // the figure put back on its floor after the host moved the body (a kerb's lift)
private:
	float ankle_rest = 0.105f;
	Vector3 place_off[2]; Vector3 last_vel;   // a landing moved off a step's face; the body's level velocity last step   // a pin moved off a step's face   // the ankle's height over the ground standing (the idle's, set at begin)
	float draw_y = 0.0f, draw_v = 0.0f, draw_omega = 10.0f; bool draw_ok = false;   // the figure's floor, eased   // the figure on the body, its feet on the ground under it (a ray: not the capsule's height)
	float ground_at(Host &p_host, const Vector3 &p_at) const;   // the ground's height under a point (its own y when none near)
};

} // namespace mo
} // namespace godot
