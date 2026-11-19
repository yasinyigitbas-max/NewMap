// crowd2 phase 1: the crowd core, plain C++ (no Godot types; crowd_core.h/.cpp will be the thin Godot wrapper).
// A new model, not a port of map_dc/coronado/npc/crowd_layer.gd (Yasin 12 Nov: "rebuild it properly like traffic").
// Data-oriented like tc::Sim (traffic_sim.h): the walk graph is flat arrays, walkers are structure-of-arrays with a
// fixed capacity, the per-frame step allocates nothing and is deterministic for a given seed.
//
// Frame: x east, z south, y up. Heading is a unit vector (fx, fz); yaw = atan2(fx, fz) (0 = +z). "Left of travel" is
// (fz, -fx), the same as tc::Sim. Lateral offsets (lat) are positive to the left; people keep right (lat < 0).
//
// What the old crowd did per walker in GDScript and what this does instead:
//  - one script object with ~45 fields and its own copy of every leg's polyline  ->  rows in flat arrays; a walker
//    points INTO the shared graph points (first index, count, step +1 / -1), nothing is copied per leg;
//  - AStar2D calls from script per plan step                                      ->  A* here on the same graph;
//  - walkers ignored each other (two people could share one spot)                 ->  keep-right lanes, passing a
//    slower walker on the left when there is room, slowing behind when not, side-stepping standing people;
//  - a per-frame scan of every walker for the player side step                    ->  the player, cars and other
//    systems' bodies are "dynamic" circles looked up through the same spatial grid as the walkers;
//  - crossings: signalled ones waited on a script call per walker per frame       ->  the script pushes one green
//    mask per control near the player; unsignalled ones use gap acceptance against the moving dynamics (cars);
//  - "every 2nd frame beyond 40 m"                                                ->  three tiers by distance
//    (every step / every 2nd / every 4th, no interaction in the far tier), dt scaled so speeds stay right;
//  - spawn / retire bookkeeping in script every 0.25 s                            ->  population here from the
//    per-zone targets the script hands over (it owns the calendar and the density table).
// Still script (phase 1): day plans and opening hours (the script answers E_NEED_GOAL with set_goal), street
// activities, reactions / speech, the 18 skinned near bodies. Phase 2 moves the plan tables and the far-batch rows.
#pragma once

#include <cmath>
#include <cstdint>
#include <vector>

namespace cc {

constexpr int MAX_AGENTS = 1024;
constexpr int MAX_DYN = 256;
constexpr int MAX_ZONES = 8;
constexpr int GRID_BITS = 12;                 // spatial hash: 4096 buckets
constexpr float BIG = 1.0e9f;
constexpr int TRAIL_N = 16;                   // a party leader's last 16 path points, 0.25 m apart (4 m)
constexpr float TRAIL_STEP = 0.25f;

enum { S_WALK = 0, S_WAIT = 1, S_STAY = 2 };
enum { TIER_FULL = 0, TIER_MID = 1, TIER_FAR = 2 };
enum { SEG_WALK = 0, SEG_CROSS = 1 };
// walker flags (render + tests)
enum { F_MOVING = 1, F_SIT = 2, F_PASSING = 4, F_YIELD = 8, F_ENTER = 16, F_ON_LINK = 32, F_SCRIPT_GOAL = 64, F_HIDDEN = 128,
	F_FACE = 512 };   // 256 is internal (crowd_sim.cpp F_NEED); F_FACE: standing and turned towards face_yaw (talking)
// why a walker is not walking at its own pace (debug + tests)
enum { W_NONE = 0, W_SIGNAL = 1, W_GAP = 2, W_FOLLOW = 3, W_BLOCKED = 4, W_DWELL = 5, W_LOOK = 6,
	W_PHONE = 7, W_WINDOW = 8 };   // street pauses: a phone call where they stand, a look into a shop window
enum { E_SPAWN = 1, E_DESPAWN = 2, E_ARRIVE = 3, E_NEED_GOAL = 4, E_WAIT_CROSS = 5, E_LOOK_CROSS = 6, E_BUMP = 7,
	E_MEET = 8,     // two people who know each other met: id = the one who speaks first, aux = the other's id
	E_GIVE = 9,     // a passer-by gives a beggar a coin: id = the giver, aux = the beggar's id
	E_FIGHT = 10,   // a quarrel turned into a fight: id = one of the two
	E_SAY = 11 };   // somebody of a party walking together says the next line of their conversation: aux = conversation * 64 + line
enum { DYN_PLAYER = 0, DYN_CAR = 1, DYN_PED = 2, DYN_OTHER = 3 };
// places: where people come from and go to. HOME / SHOP / GATE are doors (a walker that reaches one goes in and is
// gone; shops remember how many went in and let them out again), BEACH / PARK are spots to stay at for a while.
// parties: people who walk together. One leader walks the route; the others keep a place beside / behind it.
enum { PK_NONE = 0, PK_COUPLE = 1, PK_FRIENDS = 2, PK_FAMILY = 3, PK_SAILORS = 4, PK_JOGGER = 5, PK_COUNT = 6 };
enum { PL_HOME = 0, PL_SHOP = 1, PL_BEACH = 2, PL_PARK = 3, PL_GATE = 4, PL_BUS = 5, PL_BENCH = 6 };   // PL_BUS: wait a while; PL_BENCH: sit a while
// what a walker is visibly doing besides walking / standing (drawn as a clip; reported in the render row's `why`)
enum { A_NONE = 0, A_DUCK = 20, A_FILM = 21, A_CALL = 22, A_BENCH = 23, A_BEG = 24, A_NIGHT = 25,
	A_REST_SIT = 30, A_REST_BACK = 31, A_REST_FRONT = 32,
	A_GREET = 33, A_CHAT = 34, A_ARGUE = 35, A_HUG = 36,   // a meeting: wave in passing, stop and talk, quarrel, embrace
	A_STARE = 37,   // stopped to look at a danger from a safe distance
	A_GIVE = 38,    // handing a beggar a coin
	A_FIGHT = 39,   // a quarrel that came to blows
	A_DRINK = 40,   // a drink in front of a cafe
	A_DOOR = 41 };  // opening a door, about to go in   // resting on the sand: sitting, lying on the back / front
enum { DESPAWN_FAR = 0, DESPAWN_DOOR = 1, DESPAWN_LEFT = 2, DESPAWN_SCRIPT = 3, DESPAWN_LOST = 4 };

struct Config {
	int max_agents = 900;
	double radius = 130.0;            // walkers live inside this distance of the view centre
	double retire_k = 1.2;            // ... and are retired past radius * retire_k
	double full_r = 40.0;             // tier borders
	double mid_r = 90.0;
	double ground_r = 170.0;          // feet follow the drawn ground within this of the player (>= the draw range); the
	                                  // far tier beyond it keeps the path's own height
	double pop_tick_s = 0.25;         // population pass
	double spawn_min_d = 35.0;        // never spawn nearer than this unless out of the view cone
	double speed_lo = 1.05;           // desired walking speed range (m/s), per walker
	double speed_hi = 1.55;
	double half_w[MAX_ZONES] = { 1.3, 1.1, 2.0, 3.0, 2.2, 1.6, 1.0, 1.0 };   // walkable half width per zone
	double half_w_cross = 1.5;
	double keep_right = 0.45;         // lane centre as a share of the half width, to the right
	double body_r = 0.26;             // walker body radius
	double look_ahead = 2.6;          // interaction range ahead (m)
	double lat_speed = 0.9;           // m/s sideways
	double gap_time_s = 4.5;          // unsignalled crossing: wait while a car reaches it sooner than this
	double gap_max_wait_s = 14.0;     // ... but step out after this long (cars yield to a walker on the road)
	double look_cross_p = 0.6;        // share of walkers that pause for a look before an unsignalled crossing
	double goal_min_m = 120.0;        // own goals (no script answer): straight-line distance range
	double goal_max_m = 520.0;
	double need_goal_wait_s = 0.0;    // how long E_NEED_GOAL waits for a script set_goal before the walker picks its own
	double door_spawn_p = 0.5;        // share of new walkers that come out of a door (the rest walk in from the edge)
	double door_min_d = 15.0;         // no door opens nearer than this to the player
	double stay_lo_s = 25.0;          // time spent at a beach / park spot
	double stay_hi_s = 90.0;
	double stuck_despawn_s = 45.0;    // blocked this long and out of view: retired
	double pace = 1.0;                // everybody's walking speed x this (rain: people hurry)
	bool pauses = true;               // phone calls / shop windows
	double rain = 0.0;                // > 0.5: it rains. Nobody sits down on a bench or the sand, those who do get up,
	                                  // and people shelter at shop fronts instead of looking into the windows
	double give_p = 0.15;             // share of lone passers-by who give a beggar a coin (always the same people)
	double fight_p = 0.25;            // share of quarrels that come to blows
	int meet_force = 0;               // tests / look checks: every meeting is this act (A_GREET .. A_HUG); 0 = by the pair
	double circle_p = 0.35;           // share of a party's street pauses that are "stand together and talk"
	double circle_r = 0.8;            // radius of that standing circle
	int max_circles = 2;              // standing circles near the player at once
	double talk_r = 9.0;              // a party walking or standing within this of the player is heard talking
	double talk_line_s = 3.2;         // time a line of a conversation takes
	double talk_gap_lo = 20.0, talk_gap_hi = 40.0;   // pause between two conversations
	double meet_p = 0.10;             // share of pairs of lone walkers passing each other near the player who know each
	                                  // other (always the same pairs: from their seeds); 0 = no meetings
	double pause_lo_s = 18.0;         // time between a walker's pause rolls
	double pause_hi_s = 50.0;
	bool interact = true;
	bool auto_population = true;
};

struct Stats {
	int agents = 0, spawned = 0, retired = 0, plans = 0, plan_fail = 0, passes = 0, follows = 0, waits_signal = 0, waits_gap = 0;
	int tier_n[3] = { 0, 0, 0 };
	int64_t astar_expanded = 0;
	double min_gap = BIG;             // smallest centre distance between two moving walkers seen (audit)
};

typedef double (*GroundFn)(void *p_user, double p_x, double p_z, double p_ref_y, bool p_has_ref);

class Sim {
public:
	Config cfg;
	Stats stats;

	// ---- graph (set once)
	int nn = 0, ns = 0;
	std::vector<float> node_x, node_z;
	std::vector<int32_t> seg_a, seg_b, seg_ctl, seg_p0, seg_np;
	std::vector<uint8_t> seg_kind, seg_zone;
	std::vector<float> seg_len;
	// NEW for the city kit map (19 Nov): every stretch of pavement has its own measured half width (streets.bin); empty =
	// the old way, one width per zone (cfg.half_w)
	std::vector<float> seg_hw;
	void set_seg_half_widths(const float *p_hw, int p_n) { seg_hw.assign(p_hw, p_hw + p_n); }
	// ... and the city streams in 200 m cells: people appear only where the cell is loaded and leave with it
	bool cells_all = true;
	std::vector<uint8_t> cell_ok;                 // 64 x 64, 1 = loaded
	float cell_m = 200.0f;
	int ck_x0 = -32, ck_z0 = -32, ck_w = 64, ck_h = 64;
	void set_cells(const std::vector<uint8_t> &p_cells, bool p_all) { cell_ok = p_cells; cells_all = p_all; q_x = BIG; }
	inline bool loaded_at(double p_x, double p_z) const {
		if (cells_all) return true;
		const int cx = (int)std::floor(p_x / cell_m) - ck_x0, cz = (int)std::floor(p_z / cell_m) - ck_z0;
		if (cx < 0 || cz < 0 || cx >= ck_w || cz >= ck_h || cell_ok.empty()) return false;
		return cell_ok[(size_t)cz * ck_w + cx] != 0;
	}
	// metres of pavement of each zone inside the radius (after the last query): what the population is set by
	double zone_metres(int p_zone) const { return p_zone >= 0 && p_zone < MAX_ZONES && !zq_cum[p_zone].empty() ? (double)zq_cum[p_zone].back() : 0.0; }
	std::vector<float> pts;                       // 3 per point: x, y (NaN = off the road mesh), z
	std::vector<int32_t> adj_first, adj_seg, adj_node;   // CSR: node -> (segment, other node)
	std::vector<int32_t> cell_first, cell_seg;    // segment midpoints per 50 m cell (spawn queries)
	int cgx0 = 0, cgz0 = 0, cgw = 0, cgh = 0;
	// signal controls: approach headings (unit vectors), green mask pushed by the script
	std::vector<int32_t> ctl_first;               // control -> first approach
	std::vector<float> ctl_hx, ctl_hz;
	std::vector<uint32_t> ctl_green;
	std::vector<uint8_t> ctl_known;               // 1 = the script pushed a mask this session (unknown = walk)
	std::vector<uint8_t> node_zone;               // zone of a walkway at the node

	// ---- places (set once)
	int n_places = 0;
	std::vector<uint8_t> pl_kind;
	std::vector<int32_t> pl_node, pl_link0, pl_occ;   // pl_link0: n_places + 1 offsets (points) into pl_link
	std::vector<float> pl_x, pl_z, pl_w, pl_yaw;   // pl_yaw: which way somebody at the place faces (benches)
	std::vector<float> pl_hours;                  // 28 per place: 7 days x 2 intervals x (open, close) in hours; 0, 0 = none
	std::vector<float> pl_link;                   // node -> door polylines, 3 per point
	std::vector<int32_t> plc_first, plc_idx;      // places per 50 m cell
	double hour = 12.0, sunrise = 6.0, sunset = 19.0;
	int weekday = 0;
	// what is inside the radius of the view centre (rebuilt after it moved 12 m)
	double q_x = BIG, q_z = BIG;
	std::vector<int32_t> zq_seg[MAX_ZONES];
	std::vector<float> zq_cum[MAX_ZONES];
	std::vector<int32_t> pq;

	// ---- walkers (structure of arrays, index = slot)
	int n_slots = 0;                              // high-water mark
	int next_id = 1;
	uint8_t alive[MAX_AGENTS];
	int32_t id[MAX_AGENTS];
	uint8_t state[MAX_AGENTS], tier[MAX_AGENTS], zone[MAX_AGENTS], why[MAX_AGENTS];
	uint16_t flags[MAX_AGENTS];
	uint32_t seed[MAX_AGENTS];
	float x[MAX_AGENTS], y[MAX_AGENTS], z[MAX_AGENTS];   // drawn feet
	float cx[MAX_AGENTS], cz[MAX_AGENTS];         // on the path centre line
	float fx[MAX_AGENTS], fz[MAX_AGENTS];         // heading (unit)
	float yaw[MAX_AGENTS];
	float v_des[MAX_AGENTS], v[MAX_AGENTS], v_ema[MAX_AGENTS];
	float lat[MAX_AGENTS], lat_t[MAX_AGENTS], half_w[MAX_AGENTS];
	float dwell[MAX_AGENTS], wait_s[MAX_AGENTS], blocked_s[MAX_AGENTS], need_s[MAX_AGENTS];
	float face_yaw[MAX_AGENTS];
	float pause_t[MAX_AGENTS];                    // s until the next pause roll
	uint8_t pausing[MAX_AGENTS];                  // 1 = standing for a street pause (walks on along its route after)
	uint8_t act[MAX_AGENTS];                      // A_*: set by the core (bench, duck) or the script (film, call, beg, night)
	float flee_t[MAX_AGENTS];                     // s left of running away from a danger
	float meet_cd[MAX_AGENTS];                    // s until this walker may meet somebody again
	uint8_t meet_x[MAX_AGENTS];                   // 1 = this quarrel will come to blows
	float lat_extra[MAX_AGENTS];                  // m a walker may leave the pavement's width by, while it dodges a car (decays)
	// ---- guests: walkers another system moves (the traffic core's: they cross at its signals, its cars yield to them).
	// The crowd only draws them, with the same bodies and the same far figures as its own people, and its own people
	// walk round them. A guest takes no part in the population, the plans, the meetings or the dangers.
	uint8_t guest[MAX_AGENTS];                    // 1 = a guest
	int32_t guest_of[MAX_AGENTS];                 // its id in the other system
	float g_tx[MAX_AGENTS], g_ty[MAX_AGENTS], g_tz[MAX_AGENTS], g_tyaw[MAX_AGENTS], g_sp[MAX_AGENTS];   // where the other system has it now
	uint8_t g_mv[MAX_AGENTS], g_seen[MAX_AGENTS];
	std::vector<int32_t> guests;                  // their slots
	void guests_begin();
	int guest_find(int p_ext) const;
	int guest_set(int p_ext, double p_x, double p_y, double p_z, double p_yaw, double p_speed, bool p_moving, uint32_t p_seed);
	void guests_end();
	void guest_move(int p_slot, double p_dt);
	std::vector<uint8_t> pl_flags;                // per place: bit 0 = serves drinks (a cafe, a bar, an ice-cream shop)
	void set_place_flags(const uint8_t *p_flags, int p_n) { pl_flags.assign(p_flags, p_flags + p_n); }
	bool disable_place(int p_place);              // nobody is sent there any more, whoever is there gets up (a knocked-over bench)
	// conversations of the parties (data: how many lines each has, and in which zones it fits, bit z = zone z, 0 = anywhere)
	std::vector<int32_t> conv_lines, conv_zones;
	void set_conversations(const int32_t *p_lines, const int32_t *p_zones, int p_n) { conv_lines.assign(p_lines, p_lines + p_n); conv_zones.assign(p_zones, p_zones + p_n); }
	int talk_party = 0, talk_conv = -1, talk_line = 0;   // the party talking now, its conversation, the next line
	double talk_t = 6.0;                          // s until the next line / the next conversation
	void talk_tick(double p_dt);
	bool can_meet(int p_slot) const;
	void start_meet(int p_a, int p_b, uint32_t p_hash, double p_ahead, double p_side);
	int32_t party[MAX_AGENTS];                    // 0 = alone, else the party's number
	int32_t lead[MAX_AGENTS];                     // slot of the party leader this walker follows, -1 = it leads / is alone
	uint8_t pkind[MAX_AGENTS];                    // PK_*
	float f_back[MAX_AGENTS], f_side[MAX_AGENTS]; // a follower's place: metres behind the leader, metres to its left
	float f_file[MAX_AGENTS];                     // 0 = side by side .. 1 = single file behind the leader (somebody is passing)
	uint8_t f_rank[MAX_AGENTS];                   // 1, 2, 3: place in the single file
	// where a party leader has just walked (centre line + heading): its followers stand on this trail, so they keep
	// their place round corners, across leg ends and while the leader waits at a kerb
	float trail_x[MAX_AGENTS][TRAIL_N], trail_z[MAX_AGENTS][TRAIL_N], trail_fx[MAX_AGENTS][TRAIL_N], trail_fz[MAX_AGENTS][TRAIL_N];
	uint8_t trail_head[MAX_AGENTS], trail_len[MAX_AGENTS];
	int next_party = 1;
	// drawing data per walker (set by the script once per walker: which far body, its colours, its height)
	int16_t look_donor[MAX_AGENTS];               // -1 = not set yet (not drawn)
	float look_c[MAX_AGENTS][4], look_h[MAX_AGENTS];
	uint8_t has_near[MAX_AGENTS];                 // 1 = a skinned near body shows this walker (the far figure dissolves near the camera)
	float walk_ph[MAX_AGENTS];                    // walk cycle phase 0..1
	// far rows per donor body, rebuilt by build_far(): 16 floats per figure (3 x 4 transform rows + 4 per-person values)
	std::vector<std::vector<float>> far_rows;
	std::vector<int32_t> far_n;
	std::vector<int32_t> unlooked;                // ids of walkers in draw range that still need set_look()
	// rest poses (sit on the sand, lie on the back, lie on the front) per donor body: how far the posed body must be
	// lowered to touch the ground, and its footprint in body space (x0, z0, width, length), 5 floats x 3 poses x donors
	std::vector<float> rest_info;
	std::vector<float> towel_rows;                // build_towels(): 16 floats per towel (3x4 transform + colours / pattern)
	void set_rest_info(const float *p_rows, int p_n) { rest_info.assign(p_rows, p_rows + p_n); }
	int build_towels(double p_cam_x, double p_cam_z, double p_r, int p_cap);
	double party_mix[MAX_ZONES][PK_COUNT] = { { 0 } };   // chance a new walker starts a party of that kind, per zone
	float gy_x[MAX_AGENTS], gy_z[MAX_AGENTS], gy[MAX_AGENTS];   // last ground sample (re-sampled after 0.2 m)
	// current leg: a run of points, either in `pts` (a graph segment) or in the walker's own `link`
	int32_t seg[MAX_AGENTS];                      // graph segment, -1 on a link
	int32_t p_first[MAX_AGENTS], p_n[MAX_AGENTS];
	int8_t p_step[MAX_AGENTS];
	int32_t pi[MAX_AGENTS];
	float pd[MAX_AGENTS];
	int32_t wait_ctl[MAX_AGENTS], wait_ap[MAX_AGENTS];
	// route + goal
	std::vector<int32_t> route[MAX_AGENTS];       // nodes; capacity kept between plans
	int32_t ri[MAX_AGENTS];
	std::vector<float> link[MAX_AGENTS];          // goal link polyline (node -> door), 3 per point
	std::vector<float> back[MAX_AGENTS];          // the link being walked back from a door (copy of the last goal's link)
	int32_t link_node[MAX_AGENTS];                // graph node the current / last link hangs on
	uint8_t link_phase[MAX_AGENTS];               // 0 none, 1 walk it after the route, 2 on it, 3 walking it back
	float goal_dwell[MAX_AGENTS];
	int32_t goal_tag[MAX_AGENTS];                 // place index (or the script's own value), returned in E_ARRIVE
	uint8_t errands[MAX_AGENTS];                  // places still to visit before going home / leaving the area

	// ---- dynamics (set every step by the script): circles with a velocity
	int n_dyn = 0;
	float dyn_x[MAX_DYN], dyn_z[MAX_DYN], dyn_r[MAX_DYN], dyn_vx[MAX_DYN], dyn_vz[MAX_DYN];
	uint8_t dyn_kind[MAX_DYN];

	// ---- view + population
	double view_x = 0, view_z = 0, view_fx = 0, view_fz = 1, view_cos = -1.0;   // cos(half fov); -1 = everything "seen"
	double player_x = BIG, player_z = BIG;
	double zone_target[MAX_ZONES] = { 0 };
	double pop_acc = 0.0;
	double clock = 0.0;
	int64_t tick_n = 0;
	uint64_t rng = 0x9E3779B97F4A7C15ull;

	GroundFn ground_fn = nullptr;
	void *ground_user = nullptr;

	std::vector<float> events;                    // stride 6: type, id, x, y, z, aux

	// ---- setup
	void set_graph(const float *p_node_xz, int p_nn, const int32_t *p_seg_a, const int32_t *p_seg_b, const uint8_t *p_kind,
			const uint8_t *p_zone, const int32_t *p_ctl, const int32_t *p_p0, const int32_t *p_np, const float *p_len, int p_ns,
			const float *p_pts, int p_npts);
	void set_places(const uint8_t *p_kind, const int32_t *p_node, const float *p_xz, const float *p_weight, const float *p_hours,
			const int32_t *p_link_first, const float *p_link_pts, int p_n, int p_link_n);
	void set_time(double p_hour, int p_weekday, double p_sunrise, double p_sunset);
	void set_party_mix(const double *p_mix, int p_zones);   // p_zones x PK_COUNT
	bool set_look(int p_id, int p_donor, const float *p_custom4, double p_height);
	void clear_near();
	bool set_near(int p_id, bool p_on);
	// fills far_rows / far_n: every walker within p_r of the camera, pose from its own walk phase
	int build_far(int p_donors, double p_cam_x, double p_cam_z, double p_r, double p_dt, int p_walk_frames, int p_pose_idle,
			int p_pose_sit, double p_pose_k, double p_stride_m);
	bool place_open(int p_place, double p_hour) const;
	void set_controls(const int32_t *p_first, int p_nctl, const float *p_heading_xz, int p_nap);
	void reset(uint64_t p_seed);

	// ---- per step inputs
	void set_view(double p_x, double p_z, double p_fx, double p_fz, double p_fov_deg);
	void set_player(double p_x, double p_z);
	void set_dynamic(const float *p_rows, int p_n);   // stride 6: x, z, radius, vx, vz, kind
	// buses standing at a stop right now (from the traffic core): stride 7 = id, x, z, heading x, heading z, half
	// length, half width. People waiting at that stop board through the front door, a few get off.
	void set_buses(const float *p_rows, int p_n) { buses.assign(p_rows, p_rows + (size_t)p_n * 7); }
	std::vector<float> buses;
	std::vector<int32_t> buses_served;            // ids of the buses whose current stop was already handled
	std::vector<int32_t> bus_places;              // place indices of kind PL_BUS (built on first use)
	double bus_acc = 0.0;
	int boarded = 0, alighted = 0;                // counters (tests, stats)
	void bus_tick();
	void set_zone_targets(const double *p_targets, int p_n);
	void set_signal(int p_ctl, uint32_t p_green_mask);

	void step(double p_dt);

	// ---- script side
	int spawn_at_segment(int p_seg, double p_s, bool p_from_a, int p_zone);   // -> id or -1
	bool remove(int p_id, int p_reason);
	bool set_goal(int p_id, int p_node, const float *p_link, int p_link_pts, double p_dwell, bool p_enter, bool p_sit, int p_tag);
	bool set_stay(int p_id, double p_dwell, bool p_sit);
	// talking: the walker stops where it is and turns to p_yaw until release(); release lets it walk on at once
	bool set_act(int p_id, int p_act);
	void set_place_yaw(const float *p_yaw, int p_n);
	// something frightening at (x, z): people within p_duck_r crouch for a few seconds, the others within p_flee_r
	// turn and run for p_flee_s seconds. -> how many reacted
	int danger(double p_x, double p_z, double p_duck_r, double p_flee_r, double p_flee_s);
	bool hold(int p_id, double p_yaw);
	bool release(int p_id);
	bool set_hidden(int p_id, bool p_on);
	int slot_of(int p_id) const;
	int count() const { return stats.agents; }
	int nearest_node(double p_x, double p_z) const;
	bool plan(int p_from, int p_to, std::vector<int32_t> &r_nodes);
	uint64_t state_hash() const;
	// audit for tests: walkers farther than their half width + 0.6 m from their leg, NaN positions, overlapping pairs
	void audit(int &r_off_path, int &r_nan, int &r_overlap) const;
	int audit_near() const;
	void refresh_query_for_test() { refresh_query(); }

private:
	// A* scratch (generation stamped, no clearing)
	std::vector<float> as_g;
	std::vector<int32_t> as_from, as_gen, as_heap;
	int as_cur = 0;
	// spatial hash of walkers + dynamics, rebuilt every step
	int32_t grid_head[1 << GRID_BITS];
	int32_t grid_next[MAX_AGENTS + MAX_DYN];
	int grid_cell(double p_x, double p_z) const;
	void grid_build();

	uint32_t rnd();
	double rndf();
	double rndf(double p_lo, double p_hi) { return p_lo + (p_hi - p_lo) * rndf(); }
	void emit(int p_type, int p_id, int p_slot, double p_aux);
	int free_slot();
	void kill(int p_slot, int p_reason);
	bool seen(double p_x, double p_z) const;
	void population();
	void refresh_query();
	int make_walker(int p_zone);
	void make_party(int p_leader);
	void follow(int p_slot, double p_dt);
	void reverse_leg(int p_slot);
	bool spawn_in_zone(int p_zone);
	bool spawn_at_door(int p_zone);
	bool own_goal(int p_slot);
	bool choose_goal(int p_slot);
	int pick_place(int p_slot);
	bool goal_place(int p_slot, int p_place);
	bool start_route(int p_slot, int p_from_node);
	void leg_from_segment(int p_slot, int p_seg, bool p_from_a);
	void leg_from_link(int p_slot, bool p_reverse);
	bool next_leg(int p_slot);
	void wait_spot(int p_slot);
	bool crossing_gate(int p_slot, int p_seg, int p_n0, int p_n1);
	bool gap_clear(int p_seg) const;
	void interact(int p_slot, double p_dt, double &r_v);
	void advance(int p_slot, double p_dt);
	void place(int p_slot, double p_dt);
	const float *leg_pt(int p_slot, int p_k) const;
	int node_at_leg_end(int p_slot) const;
};

} // namespace cc
