// The walking crowd of the new map: who walks where, what they do there, plain C++ (no engine types), written new on
// Yasin's word of 19 Nov 2026 ("gta 5 level npcs ... they already do all of these but they do them terribly, needs a
// rewrite ... FULLY WRITTEN IN C PLUS PLUS"). Not the old game's crowd core (it was made for pavements 2-6 m wide and
// left people standing inside each other on this map's narrow ones).
//
// The idea, the same as the traffic's: a pavement is a little two-way street.
//  - It runs on the walk graph of streets.bin (StreetGraph): pavement lines between corner points, and crossings; and
//    on places.bin (PeoplePlaces): doors, benches, bus stops, beach and park places, cafe seats.
//  - PEOPLE KEEP RIGHT: every pavement has two files, one each way. A walker follows the one in front, and PASSES
//    through the other file when he is clearly faster and nobody comes. Head on, both lean to their own right edge.
//  - NOBODY EVER MOVES INTO A BODY (a person, the player, a car): every move is checked against everything near. Who is
//    held for a second looks for a free place beside; after three he turns sideways and sidles past; after nine he
//    turns round.
//  - CROSSINGS: to the kerb, wait there; at signals by the traffic's own clock; elsewhere a look, then a gap in the
//    cars; a brisk pace on the crossing and a jog when the light runs out.
//  - EVERYBODY IS GOING SOMEWHERE: a route (shortest way over the graph) to a place 120-520 m off, chosen by the hour
//    and the weather: a door (he goes in and is gone; shops let people out again), a bench, a beach or park place, a
//    cafe table, a bus stop. Off the pavement's line he walks the last metres straight to the door or seat.
//  - PEOPLE WALK TOGETHER: couples, friends, families, sailors: one leads, the others keep their places beside or
//    behind him on his own trail, abreast where there is room and nobody comes, in single file where not.
//  - STREET LIFE: a phone call, a shop window, people who know each other meet (a wave, a chat, a hug, a quarrel),
//    a coin for a beggar, a group that stops in a circle and talks, shelter from rain, night workers.
//  - DANGER: near it people duck, farther they run, some stand and stare, film or call; a car coming at somebody
//    makes him jump aside, off the pavement if he must.
//  - PEOPLE APPEAR on pavements of loaded cells in a ring round the camera or out of a door, never close in front of
//    the camera, as many as the kind of street carries at that hour, and leave when they are far.
// One step moves everybody (20 a second, drawn between each one's last two poses, as the cars are); people far from
// the player are stepped less often. A step allocates nothing and the same seed gives the same crowd.
//
// Frame as everywhere: x east, z south, y up; heading (hx, hz), yaw = atan2(hx, hz); left of travel = (hz, -hx).
#pragma once

#include "ped_places.h"

#include <cstdint>
#include <vector>

namespace sg {
struct StreetData;
}

namespace pc {

constexpr int MAX_PEDS = 1024;
constexpr float RAD = 0.21f;            // a person seen from above: a circle this wide (shoulders 0.42 m)
constexpr float RAD_THIN = 0.14f;       // turned sideways to sidle past somebody (chest to back 0.28 m)
constexpr double SIG_CYCLE = 30.0;      // the map's signal cycle (traffic_sim.h)
constexpr float BIG = 1.0e9f;
constexpr int ROUTE_N = 40;             // pavements and crossings of a planned way, at most
constexpr int TRAIL_N = 32;             // a party leader's last points, a quarter metre apart (8 m)
constexpr float TRAIL_STEP = 0.25f;
constexpr int MAX_PARTY = 4;

// what a walker is doing on the pavement's line
enum { ST_WALK = 0, ST_WAIT = 1, ST_CROSS = 2, ST_PAUSE = 3 };
// how it moves: on the line; straight to a place off it; staying there; straight back; behind its party's leader;
// jumping out of a car's way; held where it is by the game; a physical body has it (the game moves it)
enum { M_LINE = 0, M_OFF = 1, M_STAY = 2, M_BACK = 3, M_FOLLOW = 4, M_DODGE = 5, M_HELD = 6, M_BODY = 7 };
enum { WHY_NONE = 0, WHY_SIGNAL = 1, WHY_GAP = 2, WHY_FOLLOW = 3, WHY_BLOCKED = 4, WHY_PAUSE = 5, WHY_ONCOMING = 6, WHY_LOOK = 7, WHY_PLAYER = 8, WHY_CAR = 9 };
// what its body shows (the drawing picks the animation by this)
enum { A_NONE = 0, A_SIT = 1, A_LIE_BACK = 2, A_LIE_FRONT = 3, A_PHONE = 4, A_WINDOW = 5, A_FILM = 6, A_DUCK = 7, A_BEG = 8, A_WAVE = 9, A_CHAT = 10, A_ARGUE = 11,
	A_HUG = 12, A_FIGHT = 13, A_GIVE = 14, A_DRINK = 15, A_DOOR = 16, A_TALK = 17, A_STARE = 18, A_CALL = 19, A_WAIT = 20, A_SHELTER = 21,
	A_RISE = 22,     // leaving an act that takes a moment to leave (up from a seat, out of a crouch): rise_from, rise_t
	A_GSIT = 23,     // sitting on the ground (the sand, the grass)
	A_CHEER = 24,    // he has won a fight: his arms go up
	A_COUNT = 25 };
enum { PK_NONE = 0, PK_COUPLE = 1, PK_FRIENDS = 2, PK_FAMILY = 3, PK_SAILORS = 4, PK_JOGGER = 5, PK_COUNT = 6 };
enum { TIER_FULL = 0, TIER_MID = 1, TIER_FAR = 2 };
enum { E_SPAWN = 1, E_DESPAWN = 2, E_ARRIVE = 3, E_NEED_GOAL = 4, E_WAIT_CROSS = 5, E_LOOK_CROSS = 6, E_BUMP = 7,
	E_MEET = 8,      // two people who know each other met: id = the one who speaks first, aux = the other's id, f = the kind (0 wave, 1 chat, 2 hug, 3 quarrel)
	E_GIVE = 9,      // a passer-by gives a beggar a coin: id = the giver, aux = the beggar's id
	E_FIGHT = 10,    // a quarrel came to blows
	E_SAY = 11,      // somebody of a group says the next line of their conversation: aux = conversation * 64 + line
	E_SCREAM = 12, E_LOOKOUT = 13, E_BOARD = 14, E_ALIGHT = 15 };
// flags for the drawing and the tests
enum { F_MOVING = 1, F_HIDDEN = 2, F_RESIDENT = 4, F_FLEE = 8, F_FACE = 16, F_THIN = 32, F_SCRIPT = 64, F_UMBRELLA = 128 };

struct Seg {
	int32_t a = 0, b = 0;       // walk graph nodes
	int32_t kind = 0;           // 0 pavement, 1 crossing
	int32_t zone = 0;           // 0 quiet, 1 ordinary, 2 busy (high street, centre, strip), 3 the promenade, 4 a main road
	int32_t node = -1;          // a crossing's junction (its signal clock), -1 = none
	int32_t phase = -1;         // the clock phase of the traffic it crosses, -1 = no signal
	int32_t p0 = 0, np = 0;     // its points
	float len = 0, hw = 0.75f;  // length, half width people may use
	int32_t cell = -1;
	float mx = 0, mz = 0;       // its middle
	float ka = 1.0f, kb = 1.0f; // a crossing: how far from its two ends the kerbs are (the pavement's half width there)
};

struct Config {
	int max_peds = 200;
	float rise_s[A_COUNT] = {};   // per act: seconds it takes to leave it (0 = at once); the game sets them by its animations
	float fight_s = 4.0f;         // how long blows last
	int fight_one_in = 5;         // of the long quarrels (a quarter of all) one in so many comes to blows
	bool swim = false;            // people on the beach go for a swim afterwards (the game: on; half of them, by day, in the dry)
	float cheer_s = 0.0f;         // how long the winner of a fight celebrates (0 = he just goes)
	float hurt_s = 0.0f;          // how long the loser of a fight walks slowly afterwards, hurt (the game sets 45)
	float density = 1.0f;
	bool whole = false;         // tests: people anywhere on the map, no ring
	float ring_in = 40.0f, ring_out = 130.0f, despawn_r = 156.0f, view_r = 80.0f;
	bool pauses = true;         // phone calls and shop windows
	float bold_after = 12.0f;   // s at a kerb without signals after which a walker steps out into a shorter gap (the traffic's cars brake for him)
	bool goals = true;          // everybody is going somewhere (off: they turn at random at every corner)
	bool parties = true;        // couples, friends, families, sailors, joggers
	bool life = true;           // meetings, beggars' coins, group talk, night workers
	bool tiers = true;          // people far from the player are stepped less often
	float tier_full = 40.0f, tier_mid = 90.0f;
	float door_share = 0.5f;    // of the people who appear, this share comes out of a door
	float stuck_s = 45.0f;      // held this long and out of view: taken away
	float pace = 1.0f;          // everybody's pace (rain: people hurry)
};

struct Stats {
	int spawned = 0, despawned = 0, passes = 0, sidesteps = 0, turned = 0, crossings = 0, refused = 0, pauses = 0, spawn_in_view = 0, sidled = 0;
	int plans = 0, plan_fails = 0, arrivals = 0, went_in = 0, came_out = 0, sat = 0, lay = 0, drank = 0, bus_waits = 0, boarded = 0, alighted = 0;
	int parties = 0, meetings = 0, fights = 0, coins = 0, lines_said = 0, circles = 0, ducks = 0, fled = 0, stared = 0, dodges = 0, lookouts = 0, bumps = 0, sheltered = 0;
	int taken_stuck = 0, taken_extra = 0;
	double step_us = 0.0;
};

struct Event { int16_t type; int32_t id, aux; float f; };

class Crowd {
public:
	// ---- the walk graph
	std::vector<float> node_xz;                 // 2 per node
	std::vector<Seg> segs;
	std::vector<float> pts;                     // 3 per point
	std::vector<float> pts_s;                   // per point: metres from its segment's first point
	std::vector<std::vector<int32_t>> node_segs;
	std::vector<float> sig_off;                 // per junction: the start of its signal clock, seconds
	double total_len = 0.0;
	bool built = false;

	// ---- the places
	std::vector<Place> places;
	std::vector<int32_t> place_from_file;       // the number a place has in places.bin -> its number here (-1: left out)
	std::vector<int32_t> swim_of;               // a place on the beach -> its spot in the sea (-1: none)
	std::vector<int32_t> occ;                   // per place: who is there or on his way (a walker's id), -1 = free
	std::vector<int16_t> inside;                // per shop door: how many are in the shop
	std::vector<uint8_t> place_off;             // per place: 1 = switched off by the game (a knocked-over bench)
	std::vector<std::vector<int32_t>> seg_places;   // per pavement: its places
	int n_place_kind[PL_KINDS] = { 0 };

	// ---- the people (rows; a free row has alive = 0)
	uint8_t alive[MAX_PEDS];
	int32_t id[MAX_PEDS], seg[MAX_PEDS], nxt[MAX_PEDS], hint[MAX_PEDS];
	int8_t dir[MAX_PEDS];
	uint8_t state[MAX_PEDS], why[MAX_PEDS], pass[MAX_PEDS], looked[MAX_PEDS], mode[MAX_PEDS], act[MAX_PEDS], tier[MAX_PEDS], flags[MAX_PEDS];
	uint8_t thin[MAX_PEDS];                     // 1 = turned sideways, sidling past somebody in a tight place
	float thin_t[MAX_PEDS];
	float u[MAX_PEDS], ls[MAX_PEDS];           // along its segment from node a; beside its line, + = left of a -> b
	float x[MAX_PEDS], y[MAX_PEDS], z[MAX_PEDS], yaw[MAX_PEDS], v[MAX_PEDS], v0[MAX_PEDS];
	float px[MAX_PEDS], py[MAX_PEDS], pz[MAX_PEDS], pyaw[MAX_PEDS];   // the pose before its last step
	int32_t tu[MAX_PEDS];                       // the tick of its last step
	uint8_t span[MAX_PEDS];                     // ... and how many ticks that step covered
	float hx[MAX_PEDS], hz[MAX_PEDS];
	float wait_t[MAX_PEDS], blocked_t[MAX_PEDS], still_t[MAX_PEDS], pass_t[MAX_PEDS], pause_t[MAX_PEDS], side_t[MAX_PEDS], side_goal[MAX_PEDS], own_lat[MAX_PEDS], wait_lat[MAX_PEDS], hold_u[MAX_PEDS];
	float odo[MAX_PEDS], file_bias[MAX_PEDS];   // file_bias: its own line, a little off the file's middle
	uint32_t look[MAX_PEDS];                    // who it is: body, colours, whom it knows (a hash, fixed for its life)
	uint64_t rs[MAX_PEDS];
	// going somewhere
	int32_t goal[MAX_PEDS];                     // a place, -1 = none, -2 = a point of a pavement (goal_seg, goal_u)
	int32_t goal_seg[MAX_PEDS];
	float goal_u[MAX_PEDS];
	int16_t route[MAX_PEDS][ROUTE_N];
	int8_t route_n[MAX_PEDS], route_i[MAX_PEDS];
	float tx[MAX_PEDS], tz[MAX_PEDS], ty[MAX_PEDS], tyaw[MAX_PEDS];   // off the line: where to, and how to face there
	float rise_t[MAX_PEDS], kept_stay[MAX_PEDS];
	float hurt_t[MAX_PEDS], hurt_v0[MAX_PEDS];  // hurt (he lost a fight): seconds of slow walking left, and his own pace to go back to
	uint8_t swam[MAX_PEDS];                     // it has had its swim
	uint8_t fwin[MAX_PEDS];                     // in a fight: 1 = he will win it
	int32_t kept_goal[MAX_PEDS];                // where it was going when its body was knocked about (-1 = nowhere): it goes on there afterwards
	uint8_t kept_enter[MAX_PEDS], kept_kind[MAX_PEDS];
	int32_t kept_mate[MAX_PEDS];                // one of the people it walked with when it was knocked about (an id, 0 = it walked alone): it goes back to them
	uint8_t rise_from[MAX_PEDS];
	int32_t mate[MAX_PEDS];                     // whom it met (the other's id) while the meeting lasts, else 0
	float act_t[MAX_PEDS], stay_t[MAX_PEDS], roll_t[MAX_PEDS], meet_cd[MAX_PEDS], flee_t[MAX_PEDS], say_cd[MAX_PEDS], bump_cd[MAX_PEDS], lookout_cd[MAX_PEDS];
	float face_yaw[MAX_PEDS];
	float bx[MAX_PEDS], bz[MAX_PEDS];           // off the line: the place on the line it left and goes back to
	float lagf[MAX_PEDS];                       // a leader: 1 = its people keep up, less = it slows for them
	uint8_t enter_goal[MAX_PEDS];               // at the goal: 1 = go in (a door), 0 = stay there
	uint8_t boarding[MAX_PEDS];                 // 1 = on its way to a bus's door
	mutable uint8_t veto_what = 0;              // what refused the last move asked of free_at: 1 a person, 2 the player, 3 a car
	// walking together
	int32_t party[MAX_PEDS];                    // 0 = alone; else the party's number
	int16_t leader[MAX_PEDS];                   // the row of its party's leader (its own row if it leads), -1 = alone
	uint8_t pkind[MAX_PEDS], slot[MAX_PEDS], psize[MAX_PEDS], abreast[MAX_PEDS];
	uint8_t left_far[MAX_PEDS];                 // a leader: somebody comes along the other file within 9 m (its people fall in behind it)
	float trail[MAX_PEDS][TRAIL_N][3];          // a leader's last points (x, y, z), newest at trail_at
	uint8_t trail_at[MAX_PEDS];
	float trail_d[MAX_PEDS];
	int hi = 0, n_alive = 0, next_id = 1, next_party = 1, tick = 0;
	uint64_t rng = 0x9E3779B97F4A7C15ull;

	Config cfg;
	Stats st;
	std::vector<Event> events;                  // what happened since the game last took them (it clears the list)

	// ---- what the game tells it
	float cam_x = 0, cam_z = 0, cam_fx = 0, cam_fz = 0;     // (fx, fz) = 0: no view (people may appear anywhere in the ring)
	std::vector<uint8_t> cell_ok;               // 64 x 64 cells of 200 m, 1 = loaded; empty = all
	std::vector<float> cars;                    // 7 per car: x, z, yaw, half length, half width, vx, vz
	bool has_player = false;
	float pl_x = 0, pl_z = 0, pl_vx = 0, pl_vz = 0;
	float hour = 12.0f;                         // 0..24
	int weekday = 2;                            // 0 = Monday
	float sunrise = 6.5f, sunset = 19.0f;
	float rain = 0.0f;                          // 0 dry .. 1 raining
	// a bus standing at a stop: its front door
	struct Bus { int32_t place; float dx, dz; int16_t off; uint8_t on; };
	std::vector<Bus> buses;
	// something frightening
	struct Scare { float x, z, r, t; };
	std::vector<Scare> scares;
	// conversations a group may have, per zone: how many there are and how many lines each has (the words are the game's)
	uint8_t conv_n[5] = { 6, 6, 6, 6, 6 }, conv_lines = 6;

	bool build(const sg::StreetData &d);
	void set_places(const PlaceData &p);
	void reset(uint64_t seed);
	void set_view(float p_x, float p_z, float p_fx, float p_fz) { cam_x = p_x; cam_z = p_z; cam_fx = p_fx; cam_fz = p_fz; }
	void set_cells(const std::vector<uint8_t> &p_cells) { cell_ok = p_cells; cand_tick = -1000; }
	void set_cars(int n, const float *p_cars) { cars.assign(p_cars, p_cars + (size_t)n * 7); }
	void set_player(bool p_on, float p_x, float p_z, float p_vx, float p_vz) { has_player = p_on; pl_x = p_x; pl_z = p_z; pl_vx = p_vx; pl_vz = p_vz; }
	void set_time(float p_hour, int p_weekday, float p_sunrise, float p_sunset) { hour = p_hour; weekday = p_weekday; sunrise = p_sunrise; sunset = p_sunset; }
	void set_rain(float p_rain) { rain = p_rain; }
	void step(float dt, double clock);

	// ---- hooks for the rest of the game (each returns false / -1 when it cannot)
	int place_walker(float p_x, float p_z, uint32_t p_look);       // a person on the pavement nearest that point; its id
	int place_held_at(float p_x, float p_z, uint32_t p_look, float p_yaw);   // a person exactly there (off the pavement too), held facing p_yaw
	void shift_held(int p_row, float p_x, float p_z) { if (p_row >= 0 && p_row < hi && mode[p_row] == M_HELD) move_row(p_row, p_x, p_z); }   // (a held person stepped somewhere: a fight's dodge)
	bool remove_walker(int p_id);
	bool set_goal(int p_id, int p_place, float p_stay_s, bool p_enter);   // go to a place; stay there so long, or go in
	bool set_goal_point(int p_id, float p_x, float p_z, float p_stay_s);  // go to the pavement nearest a point and stay
	bool stay(int p_id, float p_seconds);                          // stand where it is
	bool set_act(int p_id, int p_act, float p_seconds);
	bool hold(int p_id, bool p_on, float p_yaw);                   // held in place facing a way (a talk, a scene); off = released
	bool hide(int p_id, bool p_on);
	bool to_body(int p_id, bool p_on, float p_x, float p_z);       // a physical body has it (on), or gives it back at that place (off)
	void scare(float p_x, float p_z, float p_radius, float p_seconds);
	void bus_at(int p_place, bool p_on, float p_door_x, float p_door_z, int p_get_off);
	bool fight(int p_a, int p_b);                                   // (the game) two people come to blows where they stand
	void conv_end() { conv_line = 99; }                            // the game: this conversation has no more lines
	void bench_off(int p_place, bool p_off);                       // a knocked-over bench: whoever sits there gets up, nobody sits down

	// where a point of a segment is: u metres from node a, ls beside the line; the line's direction there
	void at(const Seg &S, float p_u, float p_ls, int &r_hint, float &r_x, float &r_y, float &r_z, float &r_tx, float &r_tz) const;
	int nearest_walk(float p_x, float p_z, float max_d, float &r_u, float &r_d, float &r_px, float &r_pz, float &r_py) const;
	bool walk_light(const Seg &S, double clock, float *r_left = nullptr) const;
	bool on_road(int i) const;
	bool shop_open(int p_place) const;
	float hour_factor(int zone) const;          // how full the streets of a zone are at this hour (0..1)
	// for the checks: [0] pairs standing inside each other, [1] people beside their pavement, [2] people OUT IN THE ROAD
	// (more than 1.5 m from either kerb) of a signalled crossing while its traffic has had green for 2.5 s, [3] people who
	// have not moved for a minute though they should, [4] rows with a bad number, [5] people of a party more than 10 m
	// from their leader, [6] people within 1.5 m of a kerb at such a moment (held up by the people standing at it)
	void audit(double clock, int r[7]) const;
	uint64_t state_hash() const;
	int find(int p_id) const;

private:
	// neighbours: a grid of 2 m cells, rebuilt every step
	enum { GB = 8192 };
	int16_t g_head[GB];
	int16_t g_next[MAX_PEDS];
	std::vector<int32_t> cand;                  // pavements people may appear on now
	std::vector<float> cand_w;
	std::vector<int32_t> door_cand;             // doors people may come out of now
	int cand_tick = -1000;
	float cand_sum = 0.0f;
	int target = 0;
	// planning: scratch, kept between calls
	std::vector<float> pl_cost;
	std::vector<int32_t> pl_from, pl_heap;
	std::vector<std::vector<int32_t>> place_grid;   // places by 100 m square
	int circles_now = 0;
	float conv_cd = 5.0f;
	int conv_party = 0, conv_id = 0, conv_line = 0;
	float conv_t = 0.0f;

	inline float rnd() { rng ^= rng >> 12; rng ^= rng << 25; rng ^= rng >> 27; return (float)((rng * 0x2545F4914F6CDD1Dull) >> 40) / 16777216.0f; }
	inline float rnd_of(int i) { uint64_t &r = rs[i]; r ^= r >> 12; r ^= r << 25; r ^= r >> 27; return (float)((r * 0x2545F4914F6CDD1Dull) >> 40) / 16777216.0f; }
	static int cell_of(float p_x, float p_z);
	void event(int type, int p_id, int aux, float f) { if (events.size() < 512) events.push_back(Event{ (int16_t)type, p_id, aux, f }); }

	// ped_crowd.cpp: the walking
	void grid();
	bool free_at(int i, float nx, float nz, int self = -1) const;   // (i = -1: is there room for a whole body? `self` is not counted)
	void move_row(int i, float nx, float nz);                       // a row set somewhere else at once (out of a door, to a spot)
	bool car_at(float nx, float nz, float r) const;
	void pick_next(int i);
	void enter(int i, int to, int node);
	bool gap_in_cars(const Seg &S, float need) const;
	void population(double clock);
	int new_row(int k, float su, int d, float sl, uint32_t p_look);
	void kill(int i, int reason);
	void update(int i, float h, double clock);
	void walk_line(int i, float h, double clock);
	bool free_move(int i, float gx, float gz, float speed, float h);   // a straight step toward a point off the line; true = there
	// ped_goals.cpp: going somewhere
	bool plan(int i, int to_seg, float to_u);
	void pick_goal(int i);
	void leave_line(int i);
	void arrive(int i);
	void stay_step(int i, float h);
	bool rising(int i, float h);
	void fight_begins(int i);
	bool rejoin(int i, int mate_id, int kind);
	void walk_away_from(int i, int o);
	void come_out(int place, bool from_bus, float dx, float dz);
	void free_place(int i);
	void doors_step(float h);
	// ped_party.cpp: walking together
	void make_party(int lead, int kind);
	void trail_push(int i);
	void follow(int i, float h);
	void party_step(float h);
	void leave_party(int i);
	// ped_life.cpp: street life, danger, the player
	void life_roll(int i, float h);
	void meet(int i, int j);
	void danger_step(float h);
	bool dodge(int i, float h);
	void residents();
};

} // namespace pc
