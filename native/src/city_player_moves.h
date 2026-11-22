// CityPlayer's outdoor moves after the traversal (city_player_moves.cpp; Yasin, 22 Nov): carrying (bags and briefcases
// in one hand, boxes and crates in two), benches (sit down from any side, sit, get up), bumps and stumbles (a person or
// a pole in the way, a kerb caught at a run), the sidestep through a tight gap, the look-at, pick up / put down, and the
// lean on a wall (the standing cover's). The takes: the "pact" library (tools/people/make_player_actions.gd).
#pragma once

#include <cstdint>
#include <godot_cpp/variant/aabb.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/string_name.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class Node3D;
class BodyLayer;

struct MoveState {
	// CARRYING: the prop (a top-level node of his), how it is held, its grips and box (its own frame)
	String carry; Node3D *prop = nullptr; uint64_t prop_id = 0; bool two = false;
	Transform3D grip_r, grip_l; AABB col;
	BodyLayer *layer = nullptr;
	float carry_w = 0.0f;         // (the arms' share of the carry take, eased in and out)
	StringName up_clip; double up_t = 0.0;
	// A SEAT / A PICK-UP: walking there first (the way to it his own walk), then the move
	enum { NONE = 0, GO_SIT, SITTING_DOWN, SITTING, GETTING_UP, GO_PICK, PICKING, PUTTING, SIDESTEP, STUMBLE };
	int act = NONE; float act_t = 0.0f;
	Vector3 go_p, go_to; float go_yaw = 0.0f;   // where he is to stand and the way to face for the move
	float go_best = 1e9f, go_stall = 0.0f, go_pause = 0.0f;   // (circling: no nearer for 1.5 s, he stops, turns on the spot, goes on)
	int go_wp = 0;                       // the way round (0 none yet, 1 on the way to the point round, 2 past it)
	Vector3 seat_p; float seat_yaw = 0.0f; uint64_t seat_id = 0;   // (seat_yaw: the way a sitter faces)
	Vector3 pick_hips; uint64_t pick_id = 0; bool attached = false; float drop_t = -1.0f; Transform3D drop_from, drop_to; Node3D *drop_node = nullptr; uint64_t drop_id = 0;   // (the pick up / put down: the prop his at the take's lowest; set down, it settles onto what is under it)
	float side_len = 0.0f; Vector3 side_dir; float prop_blend = 1.0f; Transform3D prop_from;
	bool scripted_was = false; Vector2 cmd_was;
	bool e_want = false;          // E / pad X this frame
	// BUMPS AND STUMBLES
	float bump_cd = 0.0f, trip_cd = 0.0f; float trip_chance = 0.15f; uint32_t rng = 0x2545f491u;
	// THE SIDESTEP through a gap
	float side_cd = 0.0f;
	// THE LOOK-AT
	bool look_set = false; Vector3 look_p; float look_scan_t = 0.0f; bool look_auto_on = false; Vector3 look_auto_p;
	// (the tests)
	int n_sit = 0, n_stand = 0, n_bump = 0, n_trip = 0, n_stumble = 0, n_side = 0, n_pick = 0, n_put = 0, n_lean = 0, n_look = 0, n_go_pause = 0;
	float go_miss = 0.0f, carry_miss_most = 0.0f, chest_gap = 0.0f; String last;
};

} // namespace godot
