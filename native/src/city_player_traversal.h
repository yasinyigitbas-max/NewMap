// CityPlayer's traversal state (city_player_traversal.cpp): jumps, drops and landings, the fall off a ledge he stood at
// too long, the crouch, cover, vaults and climbs, all from the "ptrav" library (tools/people/make_player_traversal.gd).
#pragma once

#include <cstdint>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/string_name.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

struct TravState {
	enum { NONE = 0, CLIP, AIR, COVER };
	enum { THEN_IDLE = 0, THEN_WALK, THEN_RUN, THEN_CROUCH, THEN_COVER };
	int mode = NONE;
	// A CLIP MOVE: the figure stands at one place (its anchor) and the mocap's own root motion carries the hips, so the
	// feet stay where they land; his capsule follows the hips. Fitted to the world by offsets ramped over the clip's
	// windows (a height dy, a shift dxz, an arc lift), its travel scaled by hscale.
	StringName clip;
	double t = 0.0, t0 = 0.0, t_end = 0.0, rate = 1.0;
	Vector3 anchor, h0, prev_body;
	float yaw = 0.0f, yaw_to = 0.0f, yaw_ease = 0.0f, turn_k = 0.0f;
	float dy0 = 0.0f, dy1 = 0.0f, ya = 0.0f, yb = 0.0f;
	Vector3 dxz; float xa = 0.0f, xb = 0.0f;
	Vector3 d0; float d0_t = 0.3f;
	float lift = 0.0f, la = 0.0f, lb = 0.0f, hscale = 1.0f;
	int then = THEN_IDLE, token = 0;
	double air_at = -1.0, cancel_at = -1.0;
	float air_vy = 0.0f, from_y = 0.0f, last_fig_y = 0.0f;
	Vector3 vel_out;
	bool loop_clip = false, plant_on = false;
	// what follows the clip (a get-up after a messed landing, standing up on top after a climb)
	StringName q_clip[3]; double q_t0[3] = {}, q_end[3] = {}; float q_fig_y[3] = {}; bool q_has_y[3] = {}; int nq = 0, q_then = THEN_IDLE;
	// IN THE AIR
	float air_t = 0.0f, floor_y = 0.0f, off_t = 0.0f; StringName air_clip; Vector3 air_v; bool air_long = false;
	// COVER: the wall's point and its normal (out toward him), high (standing) or low (crouched) cover
	Vector3 wall_p, wall_n; bool high = false;
	int cov_dir = 0; float cov_move_t = 0.0f, cov_edge_t = 0.0f, cov_away_t = 0.0f, cov_peek_cd = 0.0f; StringName cov_clip; bool cov_flip = false;
	float cov_stop = 0.0f; StringName cov_hand; int cov_hand_dir = 0;   // (cov_hand: the clip handed to as cover began, kept while the hand-over runs)   // (the sneak let go: it slows to a stop with him before the idle takes over, its feet kept on the floor)
	// THE CROUCH: strafing (he keeps facing the view and sneaks sideways), the loop picked
	bool crouch_was = false, strafe = false; float strafe_yaw = 0.0f;
	StringName cw_clip; int cw_side = 99; bool cw_flip = false;
	// AT AN EDGE, standing still: how long, the way down
	float edge_t = 0.0f, edge_probe_t = 0.0f; bool edge_on = false; Vector3 edge_dir;
	bool pad_a = false, pad_b = false;
	// the hand-over between two clips: the figure offset that keeps the hips where they were drawn while the poses cross-fade
	Vector3 fo; float fo_t = 0.0f, fo_len = 0.2f, blend_req = 0.2f;
	// the hand-over's turn: the figure's yaw offset so the old pose keeps facing the way it was drawn while it fades (a
	// take drawn turned round, or the stance's facing, changes the figure's yaw by up to 180 degrees: blended in the
	// figure's own frame the pose spun through it, the feet swinging round the hips)
	float yo = 0.0f, yo_t = 0.0f, yo_len = 0.3f, add_prev = 0.0f, cov_yaw_prev = 0.0f;
	float mess_chance = 0.10f;
	int last[24];
	uint32_t rng = 0x7f4a7c15u;
	// (the tests)
	int n_jump = 0, n_rjump = 0, n_drop = 0, n_run_over = 0, n_run_onto = 0, n_vault = 0, n_climb = 0, n_climb_high = 0;
	int n_soft = 0, n_hard = 0, n_mess = 0, n_big = 0, n_balance = 0, n_crouch = 0, n_sprint_out = 0;
	int n_cover = 0, n_cover_switch = 0, n_cover_turn = 0, n_peek = 0, n_cover_vault = 0, n_cover_exit = 0;
	String last_land, last_move, last_obstacle; float last_drop = 0.0f;
	TravState() { for (int i = 0; i < 24; i++) last[i] = -1; }
};

} // namespace godot
