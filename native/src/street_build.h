// The street builder: from the locked skeleton (which street joins which junction) and the BAKED ground (where the
// asphalt, the kerbs, the pavements and the painted lines really are) to the data traffic and people run on.
// Plain C++, tool time only. See docs/TRAFFIC_PEOPLE_PORT.md sections 5 and 14.
//
// Frame: the grid frame of the pieces and the bake (x = u, z = v, y up). A direction (tx, tz) has its LEFT at
// (tz, -tx), as in the traffic core. Offsets across a street are positive to the left of its a -> b direction.
// Traffic keeps right: the lanes of direction a -> b lie at negative offsets.
#pragma once

#include "street_curve.h"
#include "street_ground.h"

#include <cstdint>
#include <string>
#include <vector>

namespace sg {

struct SkNode {
	double x = 0, z = 0, pad = 0;
	bool deadend = false;   // a street ends here (a hole in it, the far end of the bridge)
	bool diverge = false;   // a ramp leaves the road here: no junction, nobody stops
	bool inner = false;     // a point inside a block where its lanes change (two become one, a left-turn lane starts): no junction
};

struct SkBlock {
	std::string id, name, section;
	std::vector<double> pts;   // x, z pairs from a to b
};

// one side of a street as measured at one station or as the median of a block
struct Side {
	double m = 0;        // where the carriageway starts (0, or the half width of a median)
	double k = 0;        // the kerb: where the carriageway ends
	double w0 = 0, w1 = 0;   // the pavement: from, to (0, 0 = none found)
	bool ok = false;
};

enum { T_NONE = 0, T_LANE1 = 1, T_LANE1_PARK = 2, T_TRUCK = 3, T_ART = 4, T_BLVD = 5, T_BLVD_PARK = 6, T_BRIDGE = 7, T_GENERIC = 8, T_COUNT = 9 };
enum { CTL_NONE = 0, CTL_STOP = 1, CTL_SIGNAL = 2 };   // the traffic core's C_NONE / C_STOP / C_SIGNAL
enum { TURN_STRAIGHT = 0, TURN_LEFT = 1, TURN_RIGHT = 2 };

struct Edge {
	int block = -1, na = -1, nb = -1;
	std::vector<double> x, z, s;   // the centre line, about every 2 m, and its length so far
	double len = 0;
	Side med[2];                   // the typical section. Side 0 = right of a -> b (direction 0 drives there), 1 = left (direction 1)
	std::vector<Side> at[2];       // the section at every centre line point
	std::vector<uint8_t> tm[2];    // ... and which kind of street that is (T_*)
	int valid[2] = { 0, 0 }, stations = 0;
	double shift_max = 0;          // how far the built street lies off the skeleton line, at most (m)
	int nl[2] = { 0, 0 };          // lanes per direction
	std::vector<double> off[2][3]; // per direction, per lane (0 = innermost): metres from the centre line at every point
	bool pocket[2] = { false, false };   // per direction: its lane 0 is a left-turn lane on the centre line (the last metres before a signal on an arterial)
	std::vector<double> wc[2], whw[2];   // per side: the middle of the pavement (metres from the centre line) and its half width at every point; empty or 0 = none
	double lhw[2] = { 1.65, 1.65 };
	double trim[2] = { 0, 0 };     // at a, at b: metres from the node where the lanes begin / end
	double tan_pt[2] = { 0, 0 };   // at a, at b: where the kerb returns of the junction end (metres from the node)
	int ctl[2] = { 0, 0 };         // control of the approach that arrives at a (direction 1), at b (direction 0)
	int first_lane[2] = { -1, -1 };
	bool oneway = false;
	double vmax = 11.1, dens = 0.004;
	int cls = 1;
};

struct Report {
	std::vector<std::string> lines;
	int lane_pts = 0, lane_pts_off_road = 0, lane_pts_no_ground = 0;
	int walk_pts = 0, walk_pts_on_road = 0, walk_pts_no_ground = 0;
	double worst_kink = 0;         // the largest height kink at a lane point (m off the line through its two neighbours)
	double worst_grade = 0;        // the steepest lane stretch (rise / run)
	int generic_stations = 0, legs_unconnected = 0, stalls_unclassed = 0, approaches = 0, approaches_stop = 0, approaches_signal = 0;
	int nodes_signal = 0, nodes_stop = 0, nodes_free = 0, short_edges = 0;
	int heads_other_tile = 0, heads_no_junction = 0;   // signal heads against the lamps' clock tiles
	int path_pts = 0, path_pts_off_road = 0, paths_off_road = 0, paths_widened = 0;   // the paths through the junctions
	int lane_pts_tight = 0;        // lane points where a car's side would be off the asphalt
	int walks = 0, crossings = 0, crossings_signal = 0, crossings_unpainted = 0, walk_driveways = 0;
	int stalls_kerb = 0, stalls_park = 0, stalls_no_ground = 0, stalls_kerb_off_road = 0;
	int corners_no_ground = 0;
	int lane_changes = 0, pockets = 0;
};

// what the game loads (streets.bin)
struct StreetData {
	// lanes, in the traffic core's own layout (traffic_sim.h set_lanes / set_connections)
	std::vector<float> lane_pts;      // 3 per point
	std::vector<int32_t> lane_off;    // lanes + 1
	std::vector<float> lane_f;        // 6 per lane: limit m/s, half width, 0, 0, -1 (the lane ends at its stop line), cars per metre
	std::vector<int32_t> lane_i;      // 12 per lane: edge, dir, index (0 = innermost), left lane, right lane, node at start, node at end, class, flags, control at the end, node (signal clock), signal phase
	std::vector<int32_t> conns;       // 5 per connection: from lane, to lane, turn, node, reach of its curve in hundredths (street_curve.h)
	// junctions
	std::vector<float> node_f;        // 4 per node: x, y, z, 0
	std::vector<int32_t> node_i;      // 4 per node: control (0 none, 1 stop, 2 signals), legs, signal tile x, tile z
	// pavements and crossings
	std::vector<float> walk_node;     // 2 per node: x, z
	std::vector<int32_t> walk_seg;    // 8 per segment: node a, node b, kind (0 walk, 1 crossing), zone, junction (-1), phase of the traffic it crosses (-1 = no signal), first point, points
	std::vector<float> walk_seg_f;    // 2 per segment: length, half width
	std::vector<float> walk_pts;      // 3 per point
	// parking stalls
	std::vector<float> stall_f;       // 8 per stall: x, y, z, yaw (rad, 0 = +z), pitch (rad, nose up +), half length, half width, place along its lane (m)
	std::vector<int32_t> stall_i;     // 4 per stall: kind (0 kerb, 1 car park), lane (-1 = none), cell x, cell z
	std::vector<float> sig_grid;      // 3: the signal clock's tiles: tile = floor((x + [0]) / [2]), floor((z + [1]) / [2]); the lamps' shader gets the same (ck_signal_grid)

	enum { CONN = 5 };
	int lanes() const { return (int)lane_off.size() - 1; }
	int connections() const { return (int)conns.size() / CONN; }
	// the path of connection c through its junction (street_curve.h), x, y, z per point
	void path(int c, std::vector<float> &r_pts) const {
		const int a = conns[(size_t)c * CONN], b = conns[(size_t)c * CONN + 1];
		const float *pa = &lane_pts[(size_t)(lane_off[a + 1] - 1) * 3], *pb = &lane_pts[(size_t)lane_off[b] * 3];
		float adx = pa[0] - pa[-3], adz = pa[2] - pa[-1], bdx = pb[3] - pb[0], bdz = pb[5] - pb[2];
		const float la = std::sqrt(adx * adx + adz * adz), lb = std::sqrt(bdx * bdx + bdz * bdz);
		if (la > 1e-6f) { adx /= la; adz /= la; }
		if (lb > 1e-6f) { bdx /= lb; bdz /= lb; }
		junction_path(pa[0], pa[1], pa[2], adx, adz, pb[0], pb[1], pb[2], bdx, bdz, (float)conns[(size_t)c * CONN + 4] * 0.01f, r_pts);
	}
	void save(std::vector<uint8_t> &r_out) const;
	bool load(const uint8_t *p_data, size_t p_size);
};

class Builder {
public:
	const Ground *ground = nullptr;
	std::vector<SkNode> nodes;
	std::vector<SkBlock> blocks;
	std::vector<float> stalls;     // 6 per stall: x, y, z, yaw degrees, grade, cell index
	std::vector<float> signals;    // 3 per signal head
	std::vector<int32_t> cell_xz;  // 2 per cell index: cell x, cell z

	std::vector<Edge> edges;
	StreetData out;
	Report rep;

	void build();

	// tool pictures and checks
	Side measure_side(double px, double pz, double nx, double nz) const;

	// a point of an edge's centre line s metres from a, its direction, and a lane's offset there
	void edge_at(const Edge &e, double s, double &x, double &z, double &tx, double &tz) const;
	double lane_off_at(const Edge &e, int dir, int lane, double s) const;

private:
	struct Leg { int e, end; double hx, hz; };   // an edge end at a node, and the direction it leaves the node in
	struct LooseEnd { int block, end, node; };   // a block end that is not at a skeleton node: the node made for it
	std::vector<LooseEnd> loose;
	std::vector<std::vector<Leg>> legs;          // per node
	void make_edges();
	void measure_edges();
	bool retrace(Edge &e);
	void classify_edges();
	void split_edges();
	void layout_lanes();
	void junctions();
	void emit_lanes();
	void check_paths();
	void emit_walks();
	void emit_stalls();
	void say(const char *fmt, ...);
};

} // namespace sg
