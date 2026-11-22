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
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/string_name.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cstdint>

namespace godot {

class CityPed;
class MoInertial;
class MoLimbs;

namespace mo {

// What the controller wants this frame
struct Intent {
	Vector3 dir;          // world, level; length 0..1 (0: stand)
	float speed = 0.0f;   // m/s wanted at full stick
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
	bool ok() const { return d != nullptr; }
	float curve(const char *p_key, double p_t, float p_def = 0.0f) const;
	float meta(const char *p_key, float p_def) const;
};

class Motor {
public:
	enum State { OFF = 0, IDLE, START, MOVE, STOP, TURN, PIVOT, TRAV };

	bool attach(CityPed *p_fig);   // loads the libraries, puts MoInertial first on the skeleton; false: no clips
	bool ready() const { return fig != nullptr && n_loops > 0; }
	// take the figure over (from whatever played it) / give it back; p_speed, p_yaw: the body's now
	void begin(float p_yaw, float p_speed);
	void end();
	bool active() const { return st != OFF; }
	void step(float p_dt, const Intent &p_in, Host &p_host);
	bool in_trav() const { return st == TRAV; }

	// the state for the rest of the game (the camera, the old code when it takes over again)
	float yaw = 0.0f, speed = 0.0f;
	State st = OFF;
	const char *state_name() const;
	String clip_name() const { return cur ? String(cur->name) : String(); }
	double clip_time() const { return t; }
	bool foot_down(int p_side) const { return cur && cur->d->lerp(t).down[p_side & 1]; }   // the clip has that foot planted now
	// tuning (Yasin's notes go here first)
	float walk_turn_rate = 3.4f, run_turn_rate = 2.3f, idle_turn_rate = 5.0f;   // rad/s while moving
	float accel_up = 2.8f, accel_down = 3.5f;                                  // m/s2 in a loop
	float blend_loop = 0.25f, blend_step = 0.2f, blend_idle = 0.3f;            // hand-over times, s
	float gait_hold = 0.4f;                                                    // s in a loop before another gait
	// (the tests)
	int n_starts = 0, n_stops = 0, n_turns = 0, n_pivots = 0, n_gait = 0, n_fidgets = 0, n_switch = 0;
	float last_entry_cost = 0.0f;
	int n_aligned = 0; float last_align = 0.0f;   // (tests) contact alignments made, the last one's size (m)
	int inert_switches() const;
	float inert_jump() const;
	bool inert_live() const;
	float foot_pull(int p_side) const;   // (tests) how far the foot lock moved that foot from the clip this frame, m
	int foot_locks() const;
	Array dump(const String &p_clip) const;   // (tests / tools) a clip's measured frames: t, feet, down, hips, root_v, yaw

private:
	CityPed *fig = nullptr;
	AnimationPlayer *anim = nullptr;
	MoInertial *inert = nullptr;
	MoLimbs *limbs = nullptr;
	Clip idles[4]; int n_idles = 0;
	Clip fidgets[6]; int n_fidgets_c = 0;
	Clip loops[12]; int n_loops = 0;               // sorted by ground_v
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

	Clip load(const char *p_name);
	void play(const Clip &p_c, double p_t0, float p_blend);
	int pick_loop(float p_speed, int p_keep) const;
	void to_idle(float p_blend);
	void to_loop(int p_i, float p_blend);
	void to_stop();
	void stop_with(const Clip *p_c, double p_t0, float p_cost);
	void to_start(float p_angle, float p_want);
	void to_turn(float p_angle);
	void to_pivot(float p_angle);
	Vector3 clip_vel(const Clip &p_c, double p_t) const;   // world, from the clip's vz / vx and the turn so far
	void advance(float p_dt);   // the clip's time on, the pose set
	// CONTACT ALIGNMENT: at a hand-over the new clip is placed so its planted foot lands on the foot already pinned there
	// (the hand-over smooths the hips; the foot does not move). Without it the pin held the old foot while the hand-over
	// pulled the drawn foot 27 cm toward the new clip's, and it let go.
	void align_contacts(const Clip &p_c, double p_t0);
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
	};
	Trav tr;
	Clip v_walk, v_run, c_low, c_mid, c_mid_run;
	bool trav_probe(const Vector3 &p_dir, float p_speed);
	bool trav_start(const Clip &p_c, const Vector3 &p_face, const Vector3 &p_n, float p_top_y, float p_land_y, bool p_vault);
	void trav_step(float p_dt);
	Vector3 trav_anchor(double p_t) const;

public:
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
	void place(Host &p_host);   // the figure on the body, its feet on the ground under it (a ray: not the capsule's height)
	float ground_at(Host &p_host, const Vector3 &p_at) const;   // the ground's height under a point (its own y when none near)
};

} // namespace mo
} // namespace godot
