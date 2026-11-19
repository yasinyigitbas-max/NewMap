// The walking crowd of the new map: who walks where on the pavements, plain C++ (no engine types), written new on
// Yasin's word of 19 Nov 2026 ("gta 5 level npcs ... they already do all of these but they do them terribly, needs a
// rewrite ... FULLY WRITTEN IN C PLUS PLUS"). Not the old game's crowd core (it was made for pavements 2-6 m wide and
// left people standing inside each other on this map's narrow ones).
//
// The idea, the same as the traffic's: a pavement is a little two-way street.
//  - It runs on the walk graph of streets.bin (StreetGraph): pavement lines between corner points, and crossings.
//  - PEOPLE KEEP RIGHT: every pavement has two files, one each way, as far apart as its width allows. A walker follows
//    the one in front, and PASSES through the other file when he is clearly faster and nobody comes; he goes back in
//    when somebody does. Where two meet head on they both lean to their own right edge and slow.
//  - NOBODY EVER MOVES INTO A BODY: every move is checked against everybody near (the traffic's "veto"). Who is held
//    for more than a second looks for a free place beside; who is held for long turns round.
//  - CROSSINGS: a walker goes to the kerb (clear of the pavement's two files) and waits there. At signals he walks
//    while the traffic he crosses has red (the traffic's own clock, the same number the lamps show) and only when he
//    will be over before it ends; elsewhere he looks, then takes a gap in the cars he is given.
//  - PEOPLE APPEAR on pavements of loaded cells in a ring round the camera, never close in front of it, as many as
//    the kind of street carries, and leave when they are far.
// One step moves everybody (20 a second, drawn between its last two poses, as the cars are). The step allocates
// nothing and the same seed gives the same crowd.
//
// Frame as everywhere: x east, z south, y up; heading (hx, hz), yaw = atan2(hx, hz); left of travel = (hz, -hx).
#pragma once

#include <cstdint>
#include <vector>

namespace sg {
struct StreetData;
}

namespace pc {

constexpr int MAX_PEDS = 512;
constexpr float RAD = 0.21f;            // a person seen from above: a circle this wide (shoulders 0.42 m)
constexpr float RAD_THIN = 0.14f;       // turned sideways to sidle past somebody (chest to back 0.28 m)
constexpr double SIG_CYCLE = 30.0;      // the map's signal cycle (traffic_sim.h)
constexpr float BIG = 1.0e9f;

enum { ST_WALK = 0, ST_WAIT = 1, ST_CROSS = 2, ST_PAUSE = 3 };
enum { WHY_NONE = 0, WHY_SIGNAL = 1, WHY_GAP = 2, WHY_FOLLOW = 3, WHY_BLOCKED = 4, WHY_PAUSE = 5, WHY_ONCOMING = 6, WHY_LOOK = 7 };

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
	float density = 1.0f;
	bool whole = false;         // tests: people anywhere on the map, no ring
	float ring_in = 40.0f, ring_out = 150.0f, despawn_r = 190.0f, view_r = 80.0f;
	bool pauses = true;         // now and then somebody stops for a few seconds (a phone, a shop window)
	float bold_after = 12.0f;   // s at a kerb without signals after which a walker steps out into a shorter gap (the traffic's cars brake for him)
};

struct Stats {
	int spawned = 0, despawned = 0, passes = 0, sidesteps = 0, turned = 0, crossings = 0, refused = 0, pauses = 0, spawn_in_view = 0, sidled = 0;
	double step_us = 0.0;
};

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

	// ---- the people (rows; a free row has alive = 0)
	uint8_t alive[MAX_PEDS];
	int32_t id[MAX_PEDS], seg[MAX_PEDS], nxt[MAX_PEDS], hint[MAX_PEDS];
	int8_t dir[MAX_PEDS];
	uint8_t state[MAX_PEDS], why[MAX_PEDS], pass[MAX_PEDS], looked[MAX_PEDS];
	uint8_t thin[MAX_PEDS];                     // 1 = turned sideways, sidling past somebody in a tight place
	float thin_t[MAX_PEDS];
	float u[MAX_PEDS], ls[MAX_PEDS];           // along its segment from node a; beside its line, + = left of a -> b
	float x[MAX_PEDS], y[MAX_PEDS], z[MAX_PEDS], yaw[MAX_PEDS], v[MAX_PEDS], v0[MAX_PEDS];
	float px[MAX_PEDS], py[MAX_PEDS], pz[MAX_PEDS], pyaw[MAX_PEDS];   // the pose before the last step
	float hx[MAX_PEDS], hz[MAX_PEDS];
	float wait_t[MAX_PEDS], blocked_t[MAX_PEDS], still_t[MAX_PEDS], pass_t[MAX_PEDS], pause_t[MAX_PEDS], side_t[MAX_PEDS], side_goal[MAX_PEDS], own_lat[MAX_PEDS], wait_lat[MAX_PEDS], hold_u[MAX_PEDS];
	float odo[MAX_PEDS];
	uint32_t look[MAX_PEDS];                    // who it is: body, colours (a hash, fixed for its life)
	uint64_t rs[MAX_PEDS];
	int hi = 0, n_alive = 0, next_id = 1, tick = 0;
	uint64_t rng = 0x9E3779B97F4A7C15ull;

	Config cfg;
	Stats st;

	// ---- what the game tells it
	float cam_x = 0, cam_z = 0, cam_fx = 0, cam_fz = 0;     // (fx, fz) = 0: no view (people may appear anywhere in the ring)
	std::vector<uint8_t> cell_ok;               // 64 x 64 cells of 200 m, 1 = loaded; empty = all
	std::vector<float> cars;                    // 7 per car: x, z, yaw, half length, half width, vx, vz

	bool build(const sg::StreetData &d);
	void reset(uint64_t seed);
	void set_view(float p_x, float p_z, float p_fx, float p_fz) { cam_x = p_x; cam_z = p_z; cam_fx = p_fx; cam_fz = p_fz; }
	void set_cells(const std::vector<uint8_t> &p_cells) { cell_ok = p_cells; cand_tick = -1000; }
	void set_cars(int n, const float *p_cars) { cars.assign(p_cars, p_cars + (size_t)n * 7); }
	void step(float dt, double clock);

	// where a point of a segment is: u metres from node a, ls beside the line; the line's direction there
	void at(const Seg &S, float p_u, float p_ls, int &r_hint, float &r_x, float &r_y, float &r_z, float &r_tx, float &r_tz) const;
	// may somebody walk on the road part of this crossing now? (a signalled one: its traffic has red)
	bool walk_light(const Seg &S, double clock, float *r_left = nullptr) const;
	// is walker i on the road part of a crossing (between the kerbs)?
	bool on_road(int i) const;
	// for the checks: [0] pairs standing inside each other, [1] people beside their pavement, [2] people on the road
	// part of a signalled crossing while its traffic has green, [3] people who have not moved for a minute
	void audit(double clock, int r[4]) const;
	uint64_t state_hash() const;
	int find(int p_id) const;

private:
	// neighbours: a grid of 2 m cells, rebuilt every step
	enum { GB = 4096 };
	int16_t g_head[GB];
	int16_t g_next[MAX_PEDS];
	std::vector<int32_t> cand;                  // pavements people may appear on now
	std::vector<float> cand_w;
	int cand_tick = -1000;
	float cand_sum = 0.0f;
	int target = 0;

	inline float rnd() { rng ^= rng >> 12; rng ^= rng << 25; rng ^= rng >> 27; return (float)((rng * 0x2545F4914F6CDD1Dull) >> 40) / 16777216.0f; }
	inline float rnd_of(int i) { uint64_t &r = rs[i]; r ^= r >> 12; r ^= r << 25; r ^= r >> 27; return (float)((r * 0x2545F4914F6CDD1Dull) >> 40) / 16777216.0f; }
	static inline int cell_of(float p_x, float p_z) { return (int)(((uint32_t)((int)std_floor(p_x * 0.5f) * 73856093) ^ (uint32_t)((int)std_floor(p_z * 0.5f) * 19349663)) & (GB - 1)); }
	static float std_floor(float f);
	void grid();
	bool free_at(int i, float nx, float nz) const;
	void pick_next(int i);
	void enter(int i, int to, int node);
	bool gap_in_cars(const Seg &S, float need) const;
	void population();
	void update(int i, float h, double clock);
};

} // namespace pc
