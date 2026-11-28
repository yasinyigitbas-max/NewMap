// The things he holds, and his fists: a bag or a briefcase in one hand, a box in two, a gun aimed, fired and reloaded,
// putting a thing down and picking it up, and the fist fight (27 Nov 2026, Yasin: "we are supposed to have a one hand
// briefcase or plastic bag carry and two handed box carry, , pick up from ground for both"; "get shooting aiming down
// sight reload for both single and two handed weapons"; "after the fist fight animations come too"). C++ only: there
// is no script version (C++ is the default since trav96). The legs and the trunk are the movement's own; the arms come
// from a hold take, laid over it by the character (the study: "Bone filters on blend nodes give upper and lower body
// layering"); the thing itself is placed at his hand each tick, from its own hand points (the kit's `grip_r`,
// `grip_l`, `muzzle`); a move on the spot (put down, pick up, a punch, being hit) is begun on the body as the other
// moves are (the study: "align, play, fit, hand IK, hand back").
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
	enum Kind { HANG = 0, BOX = 1, PISTOL = 2, LONG = 3, FIST = 4 };
	struct Item {
		const char *prop;       // traversal/props/<prop>.scn, or nullptr (his fists)
		Kind kind;
		const char *take;       // the take whose arms hold it
		double at;              // the moment of that take that is the hold (s); under 0 = the take runs as a loop
		const char *reload;     // the take whose arms reload it, or nullptr
	};
	// NOT in the study: every figure here is mine, found by looking at frames (tools/traversal/try_hold.gd and the lab)
	static constexpr double FADE = 0.25;        // seconds for the arms to come onto, and off, a hold
	static constexpr double AIM_TIME = 0.22;    // seconds to bring a gun up to the eye, and down
	static constexpr double PALM_ALONG = 0.75;  // the palm point: this share of the way from the wrist to the middle knuckle
	static constexpr double PALM_OUT = 0.03;    // ... and this far out of the palm (m)
	static constexpr double EYE_UP = 0.09;      // his eye over his head joint, and ahead of it (m)
	static constexpr double EYE_FWD = 0.09;
	static constexpr double SIGHT_OVER = 0.035; // a gun's sights over its barrel line (m)
	static constexpr double REACH_MOST = 0.90;  // a hand is laid no further off than this share of his arm's length
	static constexpr double FORE_LEAST = 0.09;  // ... and the left hand never nearer the grip than this along the gun (m)
	static constexpr double BUTT_LEAST = 0.20;  // a gun whose butt is this far behind its grip is aimed from the shoulder (m); a shorter one from the eye
	static constexpr double BUTT_IN = 0.07;     // its butt this far in toward his chest from his shoulder joint, (m): in the pocket, under his cheek (28 Nov: was 0.035)
	static constexpr double BUTT_DOWN = -0.10;  // ... this far under it (under 0: over it; 28 Nov: was 0.02, the gun at his chest, his head far over the stock)
	static constexpr double BUTT_AHEAD = 0.07;  // ... and this far ahead of it (the joint is inside his shoulder; the butt is on its front)
	// Aimed and held out in front (a pistol, and a long gun with no stock: the smg, the sawn-off). 28 Nov, Yasin: "SMG,
	// shotgun, pistol holds are still terrible, need a good fix". The grip was set a fixed way ahead of his head joint:
	// 0.50 m for the pistol was past his reach (the hands bent his trunk 17 degrees forward, and the gun, placed at his
	// eye before the bend, ended over his head), 0.17 m for the short long guns put his hands at his mouth.
	// Now the grip is brought back from AHEAD_MOST until both wrists are within OUT_REACH of his arm from their shoulders.
	static constexpr double AHEAD_MOST = 0.60;  // the furthest a held-out gun's grip is tried ahead of his head joint (m)
	static constexpr double AHEAD_LEAST = 0.25; // ... and the nearest
	static constexpr double OUT_REACH = 0.90;   // held out, each wrist this share of his arm's length from its shoulder: a slight bend left
	static constexpr double SHORT_DOWN = 0.08;  // a long gun with no stock: its sights this far under his eye (at his chin, not at his eye)
	static constexpr double SHORT_RIGHT = 0.05; // ... and its grip this far to his right of his head joint (m)
	static constexpr double REACH_AIMED = 0.97; // aimed from the shoulder, the left hand goes along the forend to this share of his arm
	static constexpr double TWIST_DEG = 35.0;   // aimed from the shoulder, his trunk turned this far to his right (his left shoulder forward,
	                                            // his head kept facing ahead): the left hand cannot reach the forend of a gun on his right
	                                            // shoulder with his chest square (his arm, shoulder to wrist, is 0.465 m; the shotgun's forend
	                                            // is 0.40 m ahead of its grip)
	static constexpr double FINGERS_DOWN = 0.34; // a hand held out on a pistol grip: its knuckles this far down per 0.94 forward (about 20 degrees), the wrist nearly straight with the forearm
	static constexpr double CUP_DOWN = 0.50;    // ... the left hand cupped round the right: steeper (about 30 degrees)
	static constexpr double KICK_TIME = 0.14;   // seconds a shot's kick takes to die away
	static constexpr double KICK_BACK = 0.03;   // ... how far the gun comes back (m)
	static constexpr double KICK_UP_DEG = 7.0;  // ... and how far its muzzle rises
	static constexpr double DROP_EASE = 0.15;   // seconds a thing put down takes to settle on the ground
	static constexpr double PICK_NEAR = 1.6;    // a thing on the ground is picked up from within this (m)
	static constexpr double ALIGN = 0.35;       // the study: "slide and turn the body over a short fixed time": this long (s)

	CharacterBody3D *body = nullptr;
	int item = 0;               // 0 = nothing; 1.. = ITEMS[item - 1]
	bool aiming = false;
	int shots = 0;              // fired since the start (for the tests)
	int plays = 0;              // moves begun here (for the tests)
	String last;                // the key of the last one

protected:
	Node *_chr = nullptr;
	Skeleton3D *_skel = nullptr;
	Node3D *_prop = nullptr;
	Node3D *_flash = nullptr;
	int _shown = 0;             // the item whose prop is made
	double _w = 0.0;            // how far the thing is in his hands
	double _layer = 1.0;        // ... and how far the arms' take is on (off during a move: the move's own take has the arms)
	double _aim_w = 0.0;
	double _kick = 0.0;
	double _reload_t = -1.0;    // seconds into a reload, or under 0
	double _clock = 0.0;
	Transform3D _t;             // where the thing is, in the skeleton's space, as worked out before the arms are solved
	bool _t_set = false;
	int _bone[2][4] = { { -1, -1, -1, -1 }, { -1, -1, -1, -1 } };   // hand, middle, index, pinky knuckles; [0] left, [1] right
	int _head = -1;
	bool _was[5] = { false, false, false, false, false };       // fire, reload, drop, hit, (spare): the keys as they were
	Dictionary _plan;
	Array _dropped;             // the things lying on the ground: [node, item]
	int _asked = -2;            // the item key as it was (only a change of it counts)
	Vector3 _butt;              // a long gun's butt, in its own space (from its mesh)
	bool _has_butt = false;
	int _shoulder = -1;
	int _punch_n = 0;
	int _hit_n = 0;

	void _hand(int side, Vector3 &r_palm, Vector3 &r_along, Vector3 &r_across) const;
	void _take_up(int which);
	double _len(const String &take) const;
	Transform3D _held_pose(const Item &it, const Vector3 palm[2], const Vector3 along[2], const Vector3 across[2], const Vector3 &gr, const Vector3 &gl, bool has_l) const;
	void _begin(const String &key, const String &clip, double from, double to, double at);

	static void _bind_methods();
	bool _get(const StringName &p_name, Variant &r_ret) const;
	bool _set(const StringName &p_name, const Variant &p_value);

public:
	void _ready() override;
	void _physics_process(double dt) override;
	void _place();
	void _refit();
	Dictionary _spot(double t);
	int count() const;
	String label() const;
};

} // namespace godot
