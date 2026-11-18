// The traffic core, plain C++ (no Godot types). Brought over from the old game (coronado-source native/src, 13 Nov
// 2026: traffic_sim.h, traffic_setup.cpp, traffic_step.cpp, traffic_route.cpp) on Yasin's word, 19 Nov 2026
// (docs/TRAFFIC_PEOPLE_PORT.md). Changed for the new map: it has no walkers of its own (the crowd core owns every
// walker and hands them over as moving boxes), the paths through junctions are the street tool's checked curves
// (street_curve.h), signals follow the map's own lamp plan, cars come and go with the streamed cells.
// What follows is the old game's own description of the model.
//
// Data-oriented: lanes and junction connectors are "pieces" (flat polylines), cars are structure-of-arrays with a
// fixed capacity, the step allocates nothing and is deterministic for a given seed.
//
// Frame: x east, z south, y up (the game frame). A box / car heading is a unit vector (fx, fz); yaw = atan2(fx, fz)
// (0 = +z, the convention of data/cars/parked.json). "Left of travel" for a direction (tx, tz) is (tz, -tx), the
// same as RoadsAPI.lane_points. Lateral offsets (lat) are positive to the left of travel.
//
// Model in short (see traffic_step.cpp):
//  - a car is on a piece at arc length s with a lateral offset; its short path is: [connector] -> lane -> chosen next
//    connector -> that connector's lane;
//  - sensing is geometric: every nearby box (cars, dynamic obstacles, parked boxes that reach into a lane) is
//    projected on the car's path ahead and becomes a "track" (interval along the path x lateral interval);
//  - speed: IDM car following against the tracks in the car's corridor + a safe-speed cap (can always stop behind
//    the leader), smooth stops at junction entry points until the movement through the junction is reserved;
//  - junctions: a connector is reserved before the car's nose passes the stop point; conflicting connectors are
//    never reserved at the same time, so cars cannot meet inside a junction;
//  - a move is committed only if the car's box at the new pose overlaps nothing ("veto"), so boxes never overlap.
#pragma once

#include <cmath>
#include <cstdint>
#include <unordered_set>
#include <vector>

namespace tc {

constexpr int MAX_CARS = 192;
constexpr int MAX_HELD = 6;
constexpr int MAX_CHAIN = 3;
constexpr int MAX_DYN = 256;
constexpr int MAX_ROUTES = 16;
constexpr int WIN_MAX = 72;
constexpr int TRK_MAX = 48;
constexpr float BIG = 1.0e9f;
constexpr double SIG_CYCLE = 30.0;   // the map's signal cycle, seconds (the bake's signal shader: signal_cycle)

enum { T_STRAIGHT = 0, T_LEFT = 1, T_RIGHT = 2, T_UTURN = 3 };
enum { C_NONE = 0, C_STOP = 1, C_SIGNAL = 2, C_GIVEWAY = 3 };
enum { TIER_FULL = 0, TIER_MID = 1, TIER_FAR = 2 };
enum { SIG_GREEN = 0, SIG_YELLOW = 1, SIG_RED = 2 };
// why a car is held back (debug + tests)
enum { W_NONE = 0, W_SIGNAL = 1, W_STOPSIGN = 2, W_YIELD = 3, W_EXIT = 4, W_LEADER = 5, W_OBSTACLE = 6, W_CRASH = 7, W_DEADEND = 8, W_GOAL = 9, W_WALKER = 10 };
// car flags (render + debug)
enum {
	F_BRAKE = 1, F_IND_L = 2, F_IND_R = 4, F_AVOID = 8, F_LANECHANGE = 16, F_PASS = 32, F_HARD = 64, F_EMERG = 128,
	F_RES = 256, F_LINE = 512
};
enum { LF_DRIVE = 1, LF_ROUNDABOUT = 2, LF_BLOCKED = 4, LF_DEADEND = 8,
	LF_EXIT = 16 };   // the lane runs out of the map (the far end of the bridge): cars drive on to its end and are gone
enum { E_HONK = 1, E_CRASH = 2, E_HARDBRAKE = 3, E_SPAWN = 4, E_DESPAWN = 5, E_ARRIVE = 6, E_PED_SPAWN = 7, E_PED_DESPAWN = 8 };
// car kinds: ambient traffic, timetable bus, scripted (CityRide: routed, stops at its goal, never despawned by the sim)
enum { K_AMBIENT = 0, K_BUS = 1, K_SCRIPTED = 2 };
// walker states
enum { P_WALK = 0, P_WAIT = 1, P_CROSS = 2, P_CORNER = 3, P_PAUSE = 4 };
enum { MAN_NONE = 0, MAN_LC_PEND = 1, MAN_PASS = 2, MAN_LC_MOVE = 3 };
enum { TRK_CAR = 0, TRK_DYN = 1, TRK_STATIC = 2, TRK_XWALK = 3 };
enum { DYN_PED = 0, DYN_PLAYER_CAR = 1, DYN_SCRIPTED_CAR = 2, DYN_OTHER = 3, DYN_XWALK = 4, DYN_PLAYER = 5 };
enum { DF_ON_ROAD = 1 };   // a walker that is on the carriageway (crossing), not waiting beside it
enum { DYN_STRIDE = 11 };  // set_dynamic: x, y, z, yaw, half length, half width, vx, vz, kind (DYN_*), id, flags (DF_*)

struct Config {
	int max_cars = 24;
	float bus_speed = 6.0f;          // timetable: average bus speed incl. stops (m/s)
	float bus_dwell = 18.0f;         // s at a stop
	float hour_factor = 1.0f;       // share of max_cars wanted right now (0..1)
	float spawn_r_in = 70.0f;       // no spawn closer than this (any direction)
	float spawn_r_out = 340.0f;
	float view_safe_r = 160.0f;     // no spawn inside the view cone closer than this
	float despawn_r = 430.0f;
	float behind_despawn_r = 220.0f;   // outside the view cone: despawn beyond this
	float cone_margin_deg = 6.0f;      // the cone used for spawn / despawn is this much wider than the camera fov
	float tier_full_r = 60.0f;
	float tier_mid_r = 180.0f;
	float a_lat = 2.2f;             // comfortable lateral acceleration in curves, m/s^2
	float b_curve = 1.5f;           // braking used to slow for a curve / turn ahead
	float b_hard = 6.0f;            // hardest normal braking
	float b_emerg = 9.0f;           // emergency braking (someone cut in)
	float stuck_despawn_s = 60.0f;  // an unseen car standing this long (not at a red light) is removed
	int n_colours = 5;
	// temperament: calm, normal, pushy
	float t_weight[3] = { 0.3f, 0.5f, 0.2f };
	float t_vf[3] = { 0.9f, 1.0f, 1.08f };       // desired speed = limit x this
	float t_cf[3] = { 0.9f, 1.0f, 1.12f };       // curve speed factor
	float t_T[3] = { 1.8f, 1.4f, 1.0f };         // time headway, s
	float t_s0[3] = { 2.6f, 2.0f, 1.6f };        // standstill gap, m
	float t_a[3] = { 1.4f, 1.9f, 2.5f };         // acceleration, m/s^2
	float t_b[3] = { 2.0f, 2.5f, 3.0f };         // comfortable braking, m/s^2
	float t_stop_wait[3] = { 1.4f, 0.9f, 0.5f }; // pause at a stop line, s
	float t_honk[3] = { 8.0f, 5.0f, 2.5f };      // blocked this long -> honk, s
	float t_gap[3] = { 2.5f, 1.5f, 0.8f };       // safety margin when taking a gap in crossing traffic, s
	float ask_after_s = 8.0f;        // at a stop line or a give-way: waited this long -> it asks for a way through
	float dens_scale = 1.0f;         // the streets' own cars-per-metre x this (tests and measurements: more or fewer cars)
	uint64_t seed = 1;
};

struct Stats {
	int spawned = 0, despawned = 0, stuck_despawned = 0, deadend_despawned = 0;
	int vetoes = 0, emergencies = 0, honks = 0, crashes = 0, hard_brakes = 0;
	int lane_changes = 0, passes = 0, reservations = 0, revoked = 0;
	int asks = 0, let_through = 0;   // times a waiting car asked for a way through; times another car held back for one
	int buses_spawned = 0, bus_stops_served = 0, arrivals = 0, reroutes = 0;
	// build
	int n_intrusions = 0, n_blocked_lanes = 0, n_deadend_lanes = 0, n_conflict_pairs = 0, n_pass_lanes = 0;
	double build_ms = 0.0, last_step_us = 0.0;
};

struct Track {
	float sa, sb;   // along the path, relative to the car's centre
	float la, lb;   // lateral interval, relative to the path centreline (+ left)
	float v;        // speed along the path (negative = oncoming)
	int16_t type, idx;
	bool facing;    // a car heading towards this car
};

struct Window {
	float x[WIN_MAX], z[WIN_MAX], s[WIN_MAX];
	int n = 0;
	int piece[4];
	float off[4];   // path distance from the car's centre to s = 0 of piece[k]
	int np = 0;
};

class Sim {
public:
	Config cfg;
	Stats st;

	// ---- pieces: lanes [0, n_lanes) then connectors [n_lanes, n_lanes + n_conns)
	int n_lanes = 0, n_conns = 0, n_pieces = 0;
	std::vector<int32_t> p_off, p_n;
	std::vector<float> ptx, pty, ptz, ptc, ptv;   // per point: position, cumulative length, speed cap
	std::vector<float> p_len, p_vmax, p_hw;
	// lanes
	std::vector<int32_t> l_edge, l_left, l_right, l_opp, l_node0, l_node1, l_sig, l_out_off, l_out_n;
	std::vector<uint8_t> l_dir, l_idx, l_ctl, l_phase, l_class, l_flags;
	std::vector<float> l_stop_s, l_dens;
	std::vector<int32_t> out_conn;
	// connectors
	std::vector<int32_t> c_from, c_to, c_node, c_prio, cf_off, cf_n, cf_idx;
	std::vector<uint8_t> c_turn;
	std::vector<int16_t> c_res;   // runtime: cars holding the connector
	// runtime: a car that has waited long at the head of its lane ASKS for its path (new for this map: with its short
	// greens and no left-turn phase, a left-turner or a side street's car found no gap in steady traffic, ever).
	// Who asked (car id), when (tick), how long it had waited. Drivers who can still stop comfortably let it go.
	std::vector<int32_t> c_ask, c_ask_tick;
	std::vector<float> c_ask_wait;
	std::vector<int32_t> raw_conns;
	std::vector<uint8_t> p_blocked;   // per piece: closed off by a parked box
	// static boxes (parked cars)
	std::vector<float> sb_x, sb_y, sb_z, sb_fx, sb_fz, sb_hl, sb_hw;
	// static boxes reaching into a piece: per piece, sorted by s0
	std::vector<int32_t> in_off, in_n;
	std::vector<float> in_s0, in_s1, in_l0, in_l1;
	// grids (cell GC m): segments (piece, point) and static boxes
	float gx0 = 0, gz0 = 0, GC = 16.0f;
	int gw = 0, gh = 0;
	std::vector<int32_t> sg_off, sg_piece, sg_pt;   // segment grid
	std::vector<int32_t> bg_off, bg_idx;            // box grid
	// models
	std::vector<float> m_hl, m_hw, m_w;
	float m_wsum = 0;
	bool built = false;

	// ---- per tick input
	float cam_x = 0, cam_y = 0, cam_z = 0, cam_fx = 0, cam_fz = 0, cam_cos = 2.0f;   // cam_cos > 1: nothing is "in view"
	double clock = 0.0;
	float dt = 0.05f;
	int tick = 0;
	bool auto_pop = true;
	int nd = 0;
	float d_x[MAX_DYN], d_y[MAX_DYN], d_z[MAX_DYN], d_fx[MAX_DYN], d_fz[MAX_DYN], d_hl[MAX_DYN], d_hw[MAX_DYN];
	float d_vx[MAX_DYN], d_vz[MAX_DYN];
	int32_t d_kind[MAX_DYN], d_id[MAX_DYN];
	uint8_t d_flag[MAX_DYN];   // DF_*

	// ---- cars (structure of arrays)
	int hi = 0;        // slots [0, hi) may be alive
	int n_alive = 0;
	int next_id = 1;
	uint8_t alive[MAX_CARS], kind[MAX_CARS], model[MAX_CARS], colour[MAX_CARS], temper[MAX_CARS], tier[MAX_CARS];
	uint8_t why[MAX_CARS], man[MAX_CARS], line_passed[MAX_CARS], touching[MAX_CARS], long_look[MAX_CARS];
	int8_t lc_dir[MAX_CARS];
	int32_t id[MAX_CARS], lane[MAX_CARS], conn[MAX_CARS], nconn[MAX_CARS], seg[MAX_CARS];
	int32_t tu[MAX_CARS], span[MAX_CARS], stop_tick[MAX_CARS];
	uint32_t flags[MAX_CARS];
	float s[MAX_CARS], lat[MAX_CARS], latv[MAX_CARS], hoff[MAX_CARS], v[MAX_CARS], acc[MAX_CARS];
	float x[MAX_CARS], y[MAX_CARS], z[MAX_CARS], fx[MAX_CARS], fz[MAX_CARS], yaw[MAX_CARS], pitch[MAX_CARS];
	float px[MAX_CARS], py[MAX_CARS], pz[MAX_CARS], pyaw[MAX_CARS], ppitch[MAX_CARS];
	float hl[MAX_CARS], hw[MAX_CARS], rad[MAX_CARS];
	float steer[MAX_CARS], latacc[MAX_CARS];
	float wait_t[MAX_CARS], blocked_t[MAX_CARS], honk_cd[MAX_CARS], crash_t[MAX_CARS], slow_t[MAX_CARS], lc_t[MAX_CARS];
	float pass_lat[MAX_CARS], pass_rem[MAX_CARS], hard_cd[MAX_CARS];
	int32_t h_conn[MAX_CARS][MAX_HELD];
	float h_rem[MAX_CARS][MAX_HELD];
	// routed cars (buses, scripted): rt = lanes in order (consecutive lanes joined by a connector, or neighbours of one
	// road = a lane change), rt_i = index of the current lane; goal = stop at s on route lane goal_ri (lat: kerb offset)
	std::vector<int32_t> rt[MAX_CARS];
	int32_t rt_i[MAX_CARS], goal_ri[MAX_CARS], route_of[MAX_CARS], next_stop[MAX_CARS];
	float goal_s[MAX_CARS], goal_lat[MAX_CARS], dwell[MAX_CARS], lc_stuck[MAX_CARS];
	int8_t lc_need[MAX_CARS];
	uint8_t arrived[MAX_CARS], pull[MAX_CARS];
	int64_t trip[MAX_CARS];
	int32_t lead_id[MAX_CARS];
	int32_t chain_c[MAX_CARS][MAX_CHAIN];   // the moves through a cluster of short links, reserved together with the move into it
	uint8_t chain_n[MAX_CARS];
	uint8_t hold_[MAX_CARS];   // a scene holds the car where it stands (boarding, cutscenes)
	int32_t veto_by[MAX_CARS];   // debug: what stopped the last move (car id, -2 parked, -3 dynamic, -1 none)
	float yinfo[MAX_CARS][3];   // debug: last refused reservation: reason (1 signal, 2 stop, 3 held, 4 give way, 5 exit, 6 slots), other car id, value

	// ---- bus routes (timetable)
	struct Route {
		std::vector<int32_t> lanes;
		std::vector<float> cum;            // route distance at the start of each route lane
		std::vector<int32_t> stop_ri;      // per stop: route lane index
		std::vector<float> stop_s;         // per stop: s on that lane
		float tph[24] = { 0 };             // trips per hour
		int model = 0;
		float length = 0.0f;
	};
	std::vector<Route> routes;
	std::unordered_set<int64_t> trips_out;   // trips already spawned (route << 32 | departure second of the day)
	double tod = 43200.0;                    // time of day, s
	double last_tod = -1.0;

	int nd_ext = 0;   // dynamic boxes handed in from outside this tick

	uint64_t rng_s = 0x853c49e6748fea9bULL;
	float dens_ref = 1e-6f;
	float carry = 0.0f;       // cars the lanes inside the spawn ring carry at the busiest hour (worked out every 2 s)
	int carry_tick = -1;
	std::vector<float> events;   // stride 6: type, id, x, y, z, aux

	// ---- setup
	// f_attr stride 6: vmax m/s, half width, trim at start, trim at end, stop line distance back from the untrimmed
	//   end (< 0: at the lane end), density (cars per metre at hour factor 1)
	// i_attr stride 12: edge, dir (0 f, 1 b), lane index, left neighbour lane or -1, right neighbour or -1, node at
	//   start, node at end, road class 0..6, flags (LF_DRIVE, LF_ROUNDABOUT), control kind at the end (C_*), signal
	//   control id, signal phase (0 / 1)
	void set_lanes(int n, const float *pts_xyz, const int32_t *pt_off, const float *f_attr, const int32_t *i_attr);
	// stride 5: from lane, to lane, turn (T_*), junction node id, reach of the path's curve in hundredths (street_curve.h)
	void set_connections(int n, const int32_t *conns);
	// per junction node: the start of its signal clock in the cycle, seconds (l_sig of a lane = its node)
	void set_signal_offsets(int n, const float *seconds) { sig_off.assign(seconds, seconds + n); }
	std::vector<float> sig_off;
	// stride 6: x, y, z, yaw, half length, half width
	void set_static_boxes(int n, const float *boxes);
	// stride 3: half length, half width, weight
	void set_models(int n, const float *models);
	bool build();
	void reset_cars(uint64_t seed);

	// ---- per tick
	void set_view(float x, float y, float z, float fx, float fz, float fov_deg);
	// stride DYN_STRIDE: x, y, z, yaw, half length, half width, vx, vz, kind (DYN_*), id, flags (DF_*)
	void set_dynamic(int n, const float *boxes);
	void step(float dt, double clock);
	void set_time_of_day(double s) { tod = s; }

	// ---- routes, buses, scripted cars (traffic_route.cpp)
	bool find_route(int from_lane, int to_lane, std::vector<int32_t> &out) const;
	int add_route(const int32_t *lanes, int n, const int32_t *stop_ri, const float *stop_s, int ns, const float *tph, int model);
	int spawn_routed(int kind_, int model_, const std::vector<int32_t> &route, int ri, float s_, float speed);
	int spawn_scripted(int model_, float fx_, float fz_, float tx, float tz, bool hidden);
	bool drive_to(int car_id, float tx, float tz);
	bool pull_over(int car_id, float tx, float tz, int side);
	bool release_car(int car_id);
	bool set_hold(int car_id, bool on);
	bool set_kerb_lat(int car_id, float lat_);
	bool teleport_car(int car_id, int lane_, float s_);
	int spawn_at(int model_, int lane_, float s_, float speed);
	int route_lanes(int car_id, int32_t *out, int max) const;
	int pick_routed(int i, int lane_);
	int peek_routed(int i, int after_lane);   // the connector a car will take out of after_lane (routed cars), -1 unknown
	bool short_link(int i, int lane_) const { return p_len[lane_] < 2.0f * hl[i] + 4.0f; }
	void buses_population();
	void route_advance(int i);

	// ---- output / queries
	int signal_state(int lane, double t) const;
	float signal_red_age(int lane, double t) const;
	int spawn_car(int lane, float s, float speed, int model, int temper);
	bool remove_car(int car_id);
	int find_car(int car_id) const;
	uint64_t state_hash() const;
	void audit(int out[3]) const;   // overlapping pairs: car-car, car-static, car-dynamic (independent of the veto code)
	int nearest_lane(float x, float z, float max_d, float *out_s) const;
	void piece_pose(int piece, float s, float lat, float out[5]) const;   // x, y, z, tx, tz

	// ---- internals
	inline float rnd() {   // xorshift64*, [0, 1)
		rng_s ^= rng_s >> 12; rng_s ^= rng_s << 25; rng_s ^= rng_s >> 27;
		return (float)((rng_s * 0x2545F4914F6CDD1DULL) >> 40) * (1.0f / 16777216.0f);
	}
	inline int cell_of(float px_, float pz_) const {
		int cx = (int)std::floor((px_ - gx0) / GC), cz = (int)std::floor((pz_ - gz0) / GC);
		if (cx < 0 || cz < 0 || cx >= gw || cz >= gh) return -1;
		return cz * gw + cx;
	}
	inline bool in_cone(float qx, float qz) const {
		float dx = qx - cam_x, dz = qz - cam_z;
		float d = std::sqrt(dx * dx + dz * dz);
		if (d < 1e-3f) return true;
		return (dx * cam_fx + dz * cam_fz) / d >= cam_cos;
	}
	void event(int type, int car, float aux);
	void sample(int piece, float s_, int &hint, float &ox, float &oy, float &oz) const;
	void pose_at(int piece, float s_, float lat_, float hoff_, float dfx, float dfz, int &hint, float out[7]) const;
	float vcap_at(int piece, float s_, int hint) const;
	bool conflict(int a, int b) const;
	int pick_next(int lane_);
	float entry_dist(int i) const;
	void build_window(int i, float LA, Window &w) const;
	bool make_track(const Window &w, float qx, float qz, float qfx, float qfz, float qhl, float qhw, float vx, float vz, float band, Track &t, float &vlat) const;
	int gather_tracks(int i, const Window &w, float LA, Track *tr) const;
	int try_reserve(int i, float de);
	void revoke(int i);
	void release_all(int i);
	int blocked_by(int i, float bx, float by, float bz, float bfx, float bfz, float infl);
	bool static_overlap(float bx, float by, float bz, float bfx, float bfz, float bhl, float bhw) const;
	void update_car(int i, float h);
	void commit_move(int i, float ds);
	void population();
	bool try_spawn();
	void despawn(int i, int reason);
	int place_car(int lane_, float s_, float speed, int model_, int temper_);
	bool lane_change_ok(int i, int nb, float &ns, float &nlat, bool relax = false) const;
	bool pass_clear(int i, const Window &w, const Track *tr, int nt, int blk, float lreq, float dpass) const;
	void build_connectors();
	void build_speed_caps();
	void build_conflicts();
	void build_grids();
	void build_intrusions();
	void build_flags();
};

inline bool obb_overlap(float ax, float az, float afx, float afz, float ahl, float ahw, float bx, float bz, float bfx, float bfz, float bhl, float bhw) {
	float dx = bx - ax, dz = bz - az;
	float c = std::fabs(afx * bfx + afz * bfz), sn = std::fabs(afx * bfz - afz * bfx);
	if (std::fabs(dx * afx + dz * afz) > ahl + bhl * c + bhw * sn) return false;
	if (std::fabs(dx * afz - dz * afx) > ahw + bhl * sn + bhw * c) return false;
	if (std::fabs(dx * bfx + dz * bfz) > bhl + ahl * c + ahw * sn) return false;
	if (std::fabs(dx * bfz - dz * bfx) > bhw + ahl * sn + ahw * c) return false;
	return true;
}

} // namespace tc
