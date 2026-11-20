// CityStream: streams the baked city (city_kit/runtime) round a moving point with no loading stop. A C++ port of
// tools/city/bake/city_stream.gd (18-20 Nov; Yasin, 20 Nov: "Don't make anything other than c++ code when there is code
// work"), with the same properties, methods and signals, so the rig and the tools only change how they make it.
//
// Three layers: far/far_world.scn (the whole island, loaded once) - 200 m cells round the player - the rooms (not here).
// What makes it hold up at speed (each point measured on the phone, docs/RUNTIME_BAKE.md, docs/PERF_20NOV.md):
//  - FORWARD LEAD: the loading range is swept ahead of a moving player by lead_seconds of travel (at most max_lead).
//  - A QUEUE: wanted cells load nearest-first, at most max_loading at a time, on the streamer's OWN loader threads (low
//    priority), which also build (instantiate) the cell; a request the player has left behind is taken off the list, or
//    dropped when it arrives. Not the engine's thread pool: physics and drawing run their jobs there.
//  - NO HOLE: the far world shows a cell's far version until the cell is really in (global texture ck_cells_loaded).
//  - SHARED THINGS STAY: every material of the bake (manifest "keep") is held for the node's life.
//  - COLLISION IN STEPS: a cell's bodies (the bake's col markers: meta "col" = [[ColData, Transform3D], ...]) are made
//    nearest-first, bodies_per_frame / body_tris_per_frame / col_ms_per_frame a frame, within col_range of the player,
//    the lead and prepared places first; the shapes are built here in C++ from the ColData's plain data (no script runs).
//  - THE REAPER (20 Nov): leaving cells are taken apart and freed on a thread of the streamer's own (the 210 km/h drive
//    with traffic and people piled 6,686 parts the main thread could not free; their buildings kept their slots in the
//    engine's instance-uniform buffer and the app froze). reap_thread = false: the main thread in parts, as before.
//  - A MEMORY CAP: never more than max_cells in.
//  - prepare(pos) / is_ready(pos): get a place ready before the player is put there; no removals under load meanwhile
//    (a teleport drops a whole area: removing then met the loaders' locks, 236 / 386 ms frames, phone 20 Nov).
//  - B7 (Yasin 20 Nov: "far roads stay loaded, roads never load outside of the city, once we get out of the car they load
//    again"): set_player(p): while the player is hidden (riding: CityPlayer::set_riding freezes him where he got in),
//    update_focus follows the active camera (the car's / bicycle's chase camera) instead of the point it is given.
#pragma once
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/shader.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/classes/thread.hpp>
#include <godot_cpp/classes/static_body3d.hpp>
#include <godot_cpp/templates/hash_map.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <atomic>
#include <condition_variable>
#include <deque>
#include <mutex>
#include <vector>

namespace godot {

class Camera3D;

class CityStream : public Node3D {
	GDCLASS(CityStream, Node3D)
public:
	enum { NONE = 0, LOADING = 1, BUILDING = 2, READY = 3, IN = 4 };
	static constexpr int MAP = 64;
private:
	struct Body { Vector3 centre; Node *parent = nullptr; Node3D *marker = nullptr; int cell = -1; uint64_t arrive_ms = 0, inrange_ms = 0; };
	struct Built { Node3D *node = nullptr; std::vector<Body> bodies; };
	struct Cell {
		String key; float x0 = 0, z0 = 0; int state = NONE; bool cancel = false;
		Node3D *node = nullptr; std::vector<Body> bodies; uint64_t t_req = 0;
	};
	std::vector<Cell> cells;
	HashMap<String, int> cell_index;
	Dictionary manifest;
	float cell_m = 200.0f;
	Node3D *far_world = nullptr;
	Vector3 focus;
	double night = 0.0;
	Array keep;
	HashMap<uint64_t, Ref<Shader>> sh_plain;      // held material (instance id) -> the shader the bake gave it
	HashMap<String, Ref<Shader>> sh_variants;     // baked shader path + defines -> its copy
	Ref<Image> map_img; Ref<ImageTexture> map_tex; bool map_dirty = false;
	std::vector<Vector3> prepared, col_pts;
	std::vector<Body> pending;
	std::vector<Node *> leaving;                  // reap_thread off: freed in parts on the main thread
	HashMap<int, uint64_t> ramping;               // cell -> arrival usec while its switch to far sweeps out (tiers)
	Dictionary stats;
	std::vector<float> v_add_ms, v_ready_ms; int ready_dropped = 0;
	StaticBody3D *probe_body = nullptr;
	uint64_t player_id = 0;
	// warm-up (behind the loading screen): frames left of the warm scene, then the graphics-memory reserve
	Node3D *warm_node = nullptr; int warm_frames = 0, warm_phase = 0; double warm_prev_night = 0.0; std::vector<RID> warm_held; uint64_t warm_t0 = 0;
	// loader threads
	std::vector<Ref<Thread>> loaders;
	std::mutex mx; std::condition_variable cv;
	std::deque<std::pair<int, String>> jobs;        // [cell, path] nearest first
	std::vector<std::pair<int, Built>> done;
	bool quit = false;
	// the reaper
	Ref<Thread> reaper;
	mutable std::mutex rmx; std::condition_variable rcv;
	std::vector<Node *> reap_q; std::atomic<int> reaping{ 0 }; bool reap_quit = false;

	void loader_loop();
	void reap_loop();
	void build(const Ref<PackedScene> &p_ps, Built &r_out) const;
	void add_cell(int i);
	void remove_cell(int i);
	void away(Node *p_n);
	bool unqueue(int i);
	float dist(int i, const Vector3 &p) const;
	float col_d2(const Vector3 &c) const;
	String path_of(int i) const;
	void mark(int i, bool on);
	void set_texel(int i, float v);
	void ramp_cells();
	void flush_map();
	void apply_night(Node *cell);
	void make_body(Body &e);
	static int col_weight(const Variant &cd);
	static Ref<Shape3D> col_shape(const Variant &cd);
	void process_stream(uint64_t t0);
	void warm_step();
protected:
	static void _bind_methods();
public:
	// the properties (same names as city_stream.gd)
	String runtime_dir = "res://map_dc/coronado/city_kit/runtime/";
	double load_dist = 240.0, unload_dist = 300.0, lead_seconds = 2.0, max_lead = 200.0;
	int max_loading = 2, max_cells = 30;
	double frame_budget_ms = 1.5;
	bool reap_thread = true;
	double busy_remove_ms = 0.6; int leaving_backlog = 384;
	int bodies_per_frame = 6, body_tris_per_frame = 1200;
	bool attach_bodies = true, show_cells = true;
	int loader_mode = 0;
	double col_ms_per_frame = 2.0; int gpu_reserve_mb = 192;
	double ready_col_m = 70.0; bool probe = false; double urgent_m = 90.0;
	double col_range = 100.0; bool col_background = true; double prepare_boost = 4.0;
	bool tiers = false; double tier_band = 8.0, arrive_s = 0.5; bool far_ground = true;


	// accessors for the properties (bound in _bind_methods)
	void set_runtime_dir(const String & v) { runtime_dir = v; } String get_runtime_dir() const { return runtime_dir; }
	void set_load_dist(double v) { load_dist = v; } double get_load_dist() const { return load_dist; }
	void set_unload_dist(double v) { unload_dist = v; } double get_unload_dist() const { return unload_dist; }
	void set_lead_seconds(double v) { lead_seconds = v; } double get_lead_seconds() const { return lead_seconds; }
	void set_max_lead(double v) { max_lead = v; } double get_max_lead() const { return max_lead; }
	void set_max_loading(int v) { max_loading = v; } int get_max_loading() const { return max_loading; }
	void set_max_cells(int v) { max_cells = v; } int get_max_cells() const { return max_cells; }
	void set_frame_budget_ms(double v) { frame_budget_ms = v; } double get_frame_budget_ms() const { return frame_budget_ms; }
	void set_reap_thread(bool v) { reap_thread = v; } bool get_reap_thread() const { return reap_thread; }
	void set_busy_remove_ms(double v) { busy_remove_ms = v; } double get_busy_remove_ms() const { return busy_remove_ms; }
	void set_leaving_backlog(int v) { leaving_backlog = v; } int get_leaving_backlog() const { return leaving_backlog; }
	void set_bodies_per_frame(int v) { bodies_per_frame = v; } int get_bodies_per_frame() const { return bodies_per_frame; }
	void set_body_tris_per_frame(int v) { body_tris_per_frame = v; } int get_body_tris_per_frame() const { return body_tris_per_frame; }
	void set_attach_bodies(bool v) { attach_bodies = v; } bool get_attach_bodies() const { return attach_bodies; }
	void set_show_cells(bool v) { show_cells = v; } bool get_show_cells() const { return show_cells; }
	void set_loader_mode(int v) { loader_mode = v; } int get_loader_mode() const { return loader_mode; }
	void set_col_ms_per_frame(double v) { col_ms_per_frame = v; } double get_col_ms_per_frame() const { return col_ms_per_frame; }
	void set_gpu_reserve_mb(int v) { gpu_reserve_mb = v; } int get_gpu_reserve_mb() const { return gpu_reserve_mb; }
	void set_ready_col_m(double v) { ready_col_m = v; } double get_ready_col_m() const { return ready_col_m; }
	void set_probe(bool v) { probe = v; } bool get_probe() const { return probe; }
	void set_urgent_m(double v) { urgent_m = v; } double get_urgent_m() const { return urgent_m; }
	void set_col_range(double v) { col_range = v; } double get_col_range() const { return col_range; }
	void set_col_background(bool v) { col_background = v; } bool get_col_background() const { return col_background; }
	void set_prepare_boost(double v) { prepare_boost = v; } double get_prepare_boost() const { return prepare_boost; }
	void set_tiers_on(bool v) { tiers = v; } bool get_tiers() const { return tiers; }   // (the property; set_tiers(on, band, arrive) swaps the shaders)
	void set_tier_band(double v) { tier_band = v; } double get_tier_band() const { return tier_band; }
	void set_arrive_s(double v) { arrive_s = v; } double get_arrive_s() const { return arrive_s; }
	bool get_far_ground() const { return far_ground; }
	CityStream();
	~CityStream();
	void _ready() override;
	void _process(double p_delta) override;
	void _exit_tree() override;

	void update_focus(const Vector3 &p, bool p_now = false, const Vector3 &p_velocity = Vector3());
	void set_player(Object *p_player) { player_id = p_player ? (uint64_t)p_player->get_instance_id() : 0; }
	void set_tiers(bool p_on, double p_band = -1.0, double p_arrive = -1.0);
	Ref<Shader> shader_variant(const Ref<Shader> &p_plain, const PackedStringArray &p_defines);
	Ref<Shader> baked_shader(const Ref<ShaderMaterial> &p_m) const;
	void set_far_ground(bool p_on);
	int loaded_count() const;
	Array loading_keys() const;
	bool busy() const;
	bool is_ready(const Vector3 &p) const;
	void prepare(const Vector3 &p) { prepared.push_back(p); }
	void release_prepared() { prepared.clear(); }
	void set_night(double v);
	void warm_up(Camera3D *p_cam, int p_frames = 3);
	// for the rig and tools
	Dictionary get_cells() const;           // key -> {"state", "node"}: built on request (not per frame)
	Vector3 get_focus() const { return focus; }
	Dictionary get_stats() const { return stats; }
	PackedFloat32Array get_ready_ms() const;
	PackedFloat32Array get_add_ms() const;
	int get_ready_dropped() const { return ready_dropped; }
	Node3D *get_far_world() const { return far_world; }
	float cell_distance(const String &p_key, const Vector3 &p) const;
	Vector3 late_cells(const Vector3 &p) const;   // (cells not in within 60 m, within 220 m, the deepest reach into 220 m)
	int pending_count() const { return (int)pending.size(); }
	Node3D *cell_node(const String &p_key) const { return cell_index.has(p_key) ? cells[cell_index[p_key]].node : nullptr; }
	bool breakables = true;   // B9: a CityBreakables child follows the cells (set before the node enters the tree)
	void set_breakables(bool v) { breakables = v; } bool get_breakables() const { return breakables; }
	int leaving_count() const;
};

} // namespace godot
