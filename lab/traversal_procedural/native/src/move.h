// Lab A (procedural): traversal moves. A move is not a clip: it is a set of contacts found on the measured geometry
// (feet on the ground, on a top or braced on a wall; hands pinned on an edge or pushing on a top) and a smooth body
// path through them, built at the moment the move starts from the obstacle's real numbers (study 4.3, 3.1-3.3).
// The same poser solves it (one solver for everything, brief A).
#pragma once

#include "labmath.h"

#include <vector>

namespace lab {

struct KeyV {
	float t;
	Vector3 v;
};
struct KeyF {
	float t;
	float v;
};

// Cubic Hermite through keys, tangents from the neighbours (Catmull-Rom in time); the first and last tangents are
// given (the body's velocity going in and out), so a move joins the walk or run without a kink.
Vector3 eval_track(const std::vector<KeyV> &k, float t, const Vector3 &v_in, const Vector3 &v_out);
float eval_trackf(const std::vector<KeyF> &k, float t);

struct FootKey {
	float t0, t1; // in contact from t0 to t1
	Vector3 ankle; // ankle position while in contact
	Basis rot; // canonical foot frame (x left, y up, z fwd) while in contact
	int contact = 2; // 2 flat on a surface, 3 on the ball, 5 braced on a wall (for the metrics)
	Vector3 pt; // the contact point that must not move (metrics)
	Vector3 ground; // ground point under the ankle (to resume walking)
	float yaw = 0;
	Vector3 via; // the swing that ENDS at this key passes through this point (if has_via)
	bool has_via = false;
};

struct HandKey {
	float t0, t1; // gripping from t0 to t1; the hand reaches in over REACH s before and lets go over RELEASE s after
	Vector3 pos; // palm centre on the surface
	Vector3 fingers; // where the fingers point
	Vector3 palm; // palm normal (out of the palm)
	float grip = 1; // 1 hook grip over an edge, -1 open palm pushing down, 0.5 wrap
	Vector3 pole; // elbow direction
};

enum MoveType {
	MV_NONE = 0,
	MV_BIGSTEP,
	MV_MANTLE,
	MV_STEPVAULT,
	MV_SPEEDVAULT,
	MV_CLIMBOVER,
	MV_CLIMBUP,
	MV_THROUGH, // through a window opening
	MV_DROP, // push off an edge (the fall and the landing are physics + MV_LAND)
	MV_HANGDROP,
	MV_LAND,
};
const char *move_name(int type);

struct Move {
	int type = MV_NONE;
	float T = 1;
	float t = 0;
	float t_commit = 0; // before this the move may be cancelled (brief: abort until the hands or feet commit)
	float yaw = 0; // facing
	Vector3 n; // into the obstacle (horizontal)
	std::vector<KeyV> hips, origin;
	std::vector<KeyF> pelvis_pitch, pelvis_yaw, trunk_pitch, head_pitch, arm_out;
	std::vector<FootKey> feet[2];
	std::vector<HandKey> hands[2];
	Vector3 v_in, v_out; // body velocity entering and leaving
	Vector3 launch; // MV_DROP / MV_HANGDROP: the velocity the body leaves with into the fall
	bool ends_in_air = false;
	Vector3 look; // where the eyes go (an edge, the landing)
	float depth = 0; // MV_LAND: how deep the hips go
	bool hurt = false;
};

// The measured obstacle (or drop) a move is built on.
struct Obstacle {
	bool valid = false;
	Vector3 n; // horizontal, into the obstacle (square to its face)
	Vector3 face; // the face at ground level, on the path
	float y0 = 0; // ground before
	float H = 0; // top height (absolute)
	float D = 0; // depth of the top along n
	float F = 0; // ground beyond (absolute); F_hit false = nothing found within 6 m
	bool F_hit = false;
	float headroom = 9; // free height above the top
	bool opening = false; // a gap in a wall (a window): sill at H, head at H + opening_h
	float opening_h = 0;
	bool drop = false; // a drop ahead instead of an obstacle
	float drop_d = 0; // how deep
	int choice = MV_NONE;
	float takeoff = 0.5f; // ankle-to-face (or ankle-to-edge) distance the move starts from
	const char *why = "";
};

struct FootPose {
	Vector3 ankle;
	Basis rot;
};

} // namespace lab
