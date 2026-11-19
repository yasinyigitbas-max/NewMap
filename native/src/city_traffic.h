// CityTraffic: the new map's traffic (docs/TRAFFIC_PEOPLE_PORT.md). It owns the traffic core (tc::Sim), the streets
// it runs on (streets.bin, made by StreetGraph), the parked cars and how all of them are drawn. Everything per tick
// and per frame is in here, in C++; the test app's script only creates the node, sets numbers on it and asks for a
// report at the end of a drive.
//
// How it runs:
//  - THE STEP is on a thread of its own (never the engine's pool: physics and drawing run their jobs there), 20 times
//    a second. The main thread only reads the last state it left and blends each car between its last two poses.
//  - EVERY CAR IS A ROW IN A BATCH, no node per car: per model one batch of the near model (a few moving cars right
//    by the camera) and one of the light model (moving cars to mid range, parked cars close by); ONE batch of
//    60-triangle shapes for every far moving car and ONE for every parked car beyond 35 m. The number of draws depends
//    on how many MODELS are in view, not on how many cars.
//  - PARKED CARS never use a detailed model (Yasin: "high detailed ones break the game"). They come and go with the
//    streamed cells (the streamer's cell_in / cell_out), which stalls are taken and by which car is fixed by a seed,
//    and their far batch is sent to the graphics card only when a cell comes or goes.
//  - CARS APPEAR in a ring whose centre runs ahead of the camera by its speed, only on streets whose cell is loaded.
//  - COLLISION: a small pool of box bodies made once at start and only MOVED afterwards, onto the cars nearest the
//    camera's way. Nothing is created or attached while driving.
//  - A CAR THAT IS ABOUT TO BE HIT (by the player's car, or by a car already knocked loose) stops being a row and a box:
//    one of six physical cars made at the start (CityCar, the same springs and tyres the player drives) takes its
//    model, colour, place and speed a moment before the touch, so the knock itself is the engine's: it is shoved, spun,
//    rolled. Its driver brakes; once it stands on its wheels along a lane he drives on (the car is a row again), else
//    it stays where it lies, the traffic goes round it, and it is taken away when the camera is far.
#pragma once

#include "street_build.h"
#include "car_models.h"
#include "traffic_parking.h"

#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/rid.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <atomic>
#include <mutex>
#include <thread>
#include <vector>

namespace tc {
class Sim;
}

namespace godot {

class CityCar;

class CityTraffic : public Node3D {
	GDCLASS(CityTraffic, Node3D)

public:
	enum { MAX_ROWS = 192, POOL = 24, N_COLOURS = cm::N_COLOURS };

private:
	// ---- the core and its thread
	tc::Sim *sim = nullptr;
	sg::StreetData streets;
	bool ready = false;
	std::thread worker;
	std::mutex mx;
	std::atomic<bool> quit{ false };
	bool threaded = false;
	struct Input {   // what the main thread tells the step (under mx)
		float cx = 0, cy = 0, cz = 0, fx = 0, fz = 1, fov = 74.0f, vx = 0, vz = 0;
		int max_cars = 0;
		float density = 1.0f;
		bool cells_all = true;
		std::vector<uint8_t> cells;
		bool cells_dirty = false;
		bool parked = true;
		bool pc = false;            // the player's car (set_player_car): a box the drivers see, brake for and go round
		float pcx = 0, pcy = 0, pcz = 0, pcyaw = 0, pcvx = 0, pcvz = 0, pchl = 2.2f, pchw = 0.95f;
		// knocked cars: where each one is (a box the drivers see), which cars and stalls became one, which ask to drive on
		struct LooseBox { uint8_t on = 0; uint32_t serial = 0; float x = 0, y = 0, z = 0, yaw = 0, hl = 2.2f, hw = 0.95f, vx = 0, vz = 0; } lb[6];
		struct Adopt { int slot; uint32_t serial; int model, colour; float x, z, yaw; };
		std::vector<int32_t> kill_ids, kill_stalls;
		std::vector<Adopt> adopt;
		std::vector<float> walkers;   // the crowd's people the drivers must see (DYN_STRIDE floats each): on a road, or waiting to cross
	} input;
	struct AdoptDone { int slot; uint32_t serial; int32_t id; };
	std::vector<AdoptDone> adopt_done;      // (under mx) the step's answers: the row's id, or -1 = it cannot drive on from there
	uint32_t adopted_serial[6] = { 0, 0, 0, 0, 0, 0 };   // (the step's thread) the knock whose car is a row again: its box no longer counts
	uint64_t player_id = 0;
	float player_hl = 2.2f, player_hw = 0.95f;
	std::vector<float> dyn_all;   // (the step's thread) the boxes handed to the core this step
	struct Row {     // one moving car as the step left it: its pose now and before its last move
		int32_t id; uint8_t model, colour, flags, kind;
		float x, y, z, yaw, pitch, px, py, pz, pyaw, ppitch, v, hl, hw, roll, proll, steer;
		float psteer, odo, podo;   // the front wheels' angle before its last move; metres rolled, now and before (the wheels' spin)
		int32_t tu, span;
	};
	struct Snap {
		int tick = 0, n = 0;
		int64_t t_usec = 0;      // when the step finished
		double clock = 0.0;      // the traffic's own time (the signals run on it)
		float step_us = 0.0f, carry = 0.0f;
		int spawned = 0, despawned = 0;
		Row rows[MAX_ROWS];
	};
	Snap shared, now;           // shared: under mx; now: the main thread's copy
	tp::Parking parking;        // the stalls as the traffic knows them (the step's thread; the test)
	std::vector<tp::Event> park_now;      // (main thread) the ones taken this frame
	std::vector<tp::Event> park_events;   // stalls that changed (under mx): the main thread takes them
	int park_out = 0, park_in = 0;          // (under mx) cars that pulled out / parked, so far
	void step_once(double p_clock);
	void thread_main();

	// ---- settings (set by the test app before the node enters the tree, or any time)
	int max_cars = 0;
	bool parked_on = true;
	double density = 1.0;
	bool shadows = true;
	bool bodies_on = true;
	double night = 0.0;
	int debug_car = -1;          // tests: the history of this car is kept and handed back by run_test ("trace")
	String streets_path = "res://map_dc/coronado/city_kit/traffic/streets.bin";
	int near_max = 4;            // moving cars drawn with the near model, at most
	double near_r = 22.0, mid_r = 85.0, far_r = 420.0, parked_mid_r = 35.0;

	// ---- drawing: batches of rows (transform 12 + colour 4 + custom 4 floats)
	struct Batch {
		RID mm, inst;
		int cap = 0, shown = -1;
		PackedFloat32Array buf;
		int n = 0;
		bool dirty = false;
	};
	std::vector<Batch> near_b, mid_b;      // per model
	// The cars right by the camera have their wheels apart: ONE more batch a model, four rows a car (the one wheel mesh,
	// turned about for the right side). The front wheels turn with the driver's hands, all four roll with the road.
	std::vector<Batch> wheel_b;
	struct WheelSet { bool on = false; float h[4][3]; float r = 0.33f; };   // hubs: front left, front right, rear left, rear right (left, up, forward)
	std::vector<WheelSet> wheels;
	std::vector<Ref<Mesh>> mesh_nbody, mesh_wheel;
	std::vector<float> odo_now, odo_prev, steer_now, steer_prev;   // (the step's thread) per place in the core
	std::vector<int32_t> odo_id;
	static void put_wheels(float *w, const float *car_row, const WheelSet &ws, float steer, float odo);
	Batch box_moving, box_parked;
	Batch lamps_b;                 // the lamp glows of every car that shows a light (one draw)
	Ref<Mesh> mesh_lamps;
	Ref<ShaderMaterial> mat_lamps;
	double lamps_r = 140.0;        // m: lamps are drawn this far (at night; by day only the brake lights, to 60 m)
	std::vector<Ref<Mesh>> mesh_near, mesh_mid;
	Ref<Mesh> mesh_box;
	Ref<ShaderMaterial> mat_near, mat_mid, mat_box, mat_box_parked;
	float box_size[3] = { 1.73f, 1.2f, 4.29f };   // the shared far shape's own size (x, y, z)
	float box_y0 = 0.3f;
	bool gfx = false;
	void make_batch(Batch &b, const Ref<Mesh> &p_mesh, const Ref<ShaderMaterial> &p_mat, int p_cap, bool p_shadow);
	void grow(Batch &b, int p_need);
	void send(Batch &b);
	static void lean_row(float *r, float roll);   // a row already put: the body leans about its own length (near and light models)
	static void put_row(float *r, float x, float y, float z, float yaw, float pitch, float sx, float sy, float sz, const float *col, float c0, float c1, float c2, float c3);
	int warm_frames = 40;        // the first frames: one row of every batch in front of the camera, so its shaders are built behind the loading screen

	// ---- parked cars: the stalls of streets.bin, which are taken, and by what
	struct Parked { uint8_t model, colour; };   // model 255 = the stall is empty
	std::vector<Parked> stall_car;
	std::vector<std::vector<int32_t>> cell_stalls;   // per cell of the 64 x 64 grid: its stalls
	std::vector<int32_t> active;                     // taken stalls of the loaded cells
	std::vector<uint8_t> stall_mid;                  // per stall: drawn with the light model now (near the camera)
	std::vector<std::vector<int32_t>> mid_parked;    // per model: stalls drawn with the light model
	size_t band_cursor = 0;
	bool active_dirty = true;
	void seed_stalls();
	void rebuild_active();

	// ---- the streamer (tools/city/bake/city_stream.gd): its cells
	uint64_t streamer_id = 0;
	std::vector<uint8_t> cells;     // 64 x 64, 1 = in
	bool cells_all = true;
	void cell_set(const String &p_key, bool p_in);

	// ---- collision: a pool of box bodies, moved onto the nearest cars
	RID pool_body[POOL], pool_shape[POOL];
	int pool_model[POOL];
	bool pool_made = false;
	struct BodyWant { float d2, x, y, z, yaw, pitch; int model; int32_t id, stall; float v, steer; uint8_t colour; };
	std::vector<BodyWant> body_want;   // filled in _process, used in _physics_process

	// ---- knocked cars (see the top of this file)
	enum { LOOSE = 6 };
	struct LooseCar {
		CityCar *car = nullptr;
		bool on = false, parked = false;
		int model = 0, colour = 0;
		uint32_t serial = 0;
		float rest_t = 0, age = 0, ask_cd = 0;
	};
	LooseCar loose[LOOSE];
	bool knock_on = true;
	int knock_feel = 0;
	uint32_t loose_serial = 0;
	std::vector<Ref<Resource>> keep_models;   // every model's body and wheels, held so that a knock loads nothing
	struct Hidden { int32_t id; int frames; bool seen; };
	std::vector<Hidden> hidden;      // rows that are a physical car now: not drawn, no box, until the step has dropped them
	struct KnockCount { int moving = 0, parked = 0, rejoined = 0, taken_away = 0, no_slot = 0, refused = 0; } kc;
	bool knock(BodyWant &w);
	void loose_update(double p_delta);
	void loose_put_away(int k);

	// ---- counters for the report
	struct Count {
		int frames = 0;
		double main_us = 0, main_us_worst = 0, step_us = 0, step_us_worst = 0;
		double moving = 0, near = 0, mid = 0, box = 0, parked_mid = 0, parked_all = 0, batches = 0, carry = 0;
		int moving_most = 0, steps = 0;
		int uploads = 0;
		int park_out = 0, park_in = 0;
	} cnt;
	Vector3 last_cam;
	bool has_last_cam = false;
	float vel_x = 0, vel_z = 0;

protected:
	static void _bind_methods();

public:
	CityTraffic();
	~CityTraffic();

	void _ready() override;
	void _exit_tree() override;
	void _process(double p_delta) override;
	void _physics_process(double p_delta) override;

	// Reads streets.bin and builds the core on it. false = no file, or not a streets file.
	bool load_streets(const String &p_path);
	bool is_built() const { return ready; }
	// What the core made of the streets: lanes, paths, conflict pairs, dead ends, build time
	Dictionary street_stats() const;
	// The streamer whose cells the cars follow (its signals cell_in / cell_out). Without one every street counts.
	void attach(Object *p_streamer);
	void _on_cell_in(const String &p_key);
	void _on_cell_out(const String &p_key);
	// The car the player drives (any Node3D; a RigidBody3D gives its speed too): the traffic sees it as a moving box.
	// null = none.
	void set_player_car(Object *p_car, double p_half_len, double p_half_w);
	// For the crowd (CityCrowd, C++ only, main thread). The cars as boxes, 7 floats each (x, z, yaw, half length, half
	// width, vx, vz): the traffic's rows, the knocked cars, the player's car. The people the drivers must see
	// (DYN_STRIDE floats each). The traffic's own clock, which its signals run on.
	void cars_for_people(std::vector<float> &r_cars) const;
	void set_walkers(const float *p_dyn, int p_n);
	double signal_clock() const { return now.clock; }
	bool has_clock() const { return threaded; }
	// One line for the test app's log: what was drawn and what it cost since the last call
	String report();

	void set_max_cars(int p_n) { max_cars = p_n; }
	int get_max_cars() const { return max_cars; }
	void set_parked(bool p_on) { parked_on = p_on; active_dirty = true; }
	bool get_parked() const { return parked_on; }
	void set_density(double p_d) { density = p_d; }
	double get_density() const { return density; }
	void set_shadows(bool p_on) { shadows = p_on; }
	bool get_shadows() const { return shadows; }
	void set_bodies(bool p_on) { bodies_on = p_on; }
	bool get_bodies() const { return bodies_on; }
	void set_night(double p_n) { night = p_n; }
	double get_night() const { return night; }
	void set_knock(bool p_on) { knock_on = p_on; }
	bool get_knock() const { return knock_on; }
	void set_knock_feel(int p_f) { knock_feel = p_f; }
	int get_knock_feel() const { return knock_feel; }
	// for the tests: the moving cars and the parked ones round a point, and what became of the knocked ones
	Array cars_near(const Vector3 &p_at, double p_r) const;
	Array stalls_near(const Vector3 &p_at, double p_r) const;
	Dictionary knock_stats() const;
	void set_debug_car(int p_id) { debug_car = p_id; }
	int get_debug_car() const { return debug_car; }
	void set_streets_path(const String &p_path) { streets_path = p_path; }
	String get_streets_path() const { return streets_path; }

	// A run with no drawing, for the checks (tests/traffic): p_cars cars round p_cam for p_minutes of traffic time,
	// stepped as the game steps it (20 times a second). p_whole_city: cars everywhere on the map, every car stepped
	// every tick (the hardest case for the junctions), else as in the game (a ring round the camera, far cars stepped
	// less often). p_stuck_rule: the core's "a car that stands a minute unseen is taken away" rule on or off.
	// p_density: 1 = as many cars as the streets carry at their busiest hour (up to p_cars); 2 = twice that, and so on.
	// Returns counts: overlapping car pairs (must be 0), cars standing over 2 minutes not at a red light, the state
	// hash (the same seed must give the same hash), the time a step takes.
	Dictionary run_test(int p_cars, double p_minutes, int64_t p_seed, const Vector3 &p_cam, bool p_whole_city, bool p_stuck_rule, double p_density, bool p_parking = false);
};

} // namespace godot
