// CityCrowd: the people of the new map in the game, all C++. It owns the crowd's brain (pc::Crowd, ped_crowd.h: who
// walks where and what they do), steps it 20 times a second, joins it to the traffic (the walkers see the cars; the
// drivers see the walkers on a road or waiting to cross; one signal clock), and draws everybody.
//
// How it is drawn:
//  - FAR: every person is a posed figure out of ONE table (characters/rocketbox/far_poses.bin, made once by the tool
//    PeopleBake: 41 bodies x 12 poses), one batch, ONE draw for the whole crowd, with the people's own shader
//    (rb_person.gdshader: skin, hair, eyes and clothes coloured per person from who he is).
//  - NEAR: the nearest ones get a real animated body with the 50-bone skeleton (class CityPed, a pool made at the
//    start); the far figure dissolves as the body takes over. A near body that is pushed or hit balances, staggers,
//    falls and gets up by itself (ped_body.h), and its walker goes on from where it stands afterwards.
// The test app's script only makes the node and sets numbers; nothing here is called from script per frame.
#pragma once

#include "ped_crowd.h"
#include "street_build.h"

#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/material.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/rid.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <vector>

namespace godot {

class CityTraffic;
class CityPed;
class AudioStreamPlayer3D;

class CityCrowd : public Node3D {
	GDCLASS(CityCrowd, Node3D)

public:
	enum { ROW = 16, POSES = 12, NEAR_MAX = 18 };

private:
	pc::Crowd *crowd = nullptr;
	bool ready = false, gfx = false;
	String streets_path = "res://map_dc/coronado/city_kit/traffic/streets.bin";
	String places_path = "res://map_dc/coronado/city_kit/traffic/places.bin";
	String people_dir = "res://characters/rocketbox/";
	// settings
	int max_people = 300;
	double density = 1.0, hour = 12.0, clock_rate = 0.0, rain = 0.0;   // clock_rate: game hours a real second (0 = the hour stands)
	int weekday = 2;
	double near_r = 24.0, near_fade = 6.0;
	int near_max = 12;
	bool draw_on = true;
	// the step
	double acc = 0.0, own_clock = 0.0;
	uint64_t traffic_id = 0, player_id = 0, streamer_id = 0;
	std::vector<uint8_t> cells;
	bool cells_all = true, cells_dirty = false;
	std::vector<float> cars, dyn;
	std::vector<pc::Event> ev_keep;   // what happened, until the game takes it (take_events)
	Vector3 last_player; bool has_last_player = false;
	// the far figures
	struct Body { String id; int layer = 0, female = 0, corners = 0; float height = 1.8f; int tag = 0; Ref<Mesh> near_mesh; };   // tag: 0 casual, 1 office, 2 police, 3 medical, 4 trade, 5 swim, 6 navy, 7 night
	std::vector<Body> bodies;
	std::vector<int> pool_casual[2], pool_tag[8];
	int tex_w = 0, tex_h = 0, corner_h = 1, block_rows = 0, corners_max = 0;
	float stride[2] = { 1.4f, 1.3f };
	float gait[2][6] = { { 1.4f, 1.3f, 2.4f, 0.9f, 3.6f, 0.7f }, { 1.3f, 1.3f, 2.2f, 0.9f, 3.3f, 0.7f } };   // per kind: metres and seconds of a round of the walk, the jog, the sprint
	Ref<ImageTexture> pose_tex;
	Ref<ShaderMaterial> mat_far, mat_near;
	Ref<Mesh> far_mesh;
	RID mm, inst;
	PackedFloat32Array buf;
	int shown = -1;
	// the near bodies
	struct Near { CityPed *ped = nullptr; int walker = -1; int female = 0; bool in_body = false; float push_cd = 0; Ref<ShaderMaterial> look; };
	std::vector<Near> near_pool;
	// the smaller things (city_crowd_extra.cpp): capsules round the player, umbrellas, towels, the murmur
	enum { CAPSULES = 12 };
	bool extras = false;
	RID cap_body[CAPSULES], cap_shape[CAPSULES];
	bool cap_on[CAPSULES];
	Ref<Mesh> mesh_umb, mesh_towel;
	Ref<Material> mat_prop;
	RID prop_mm[2], prop_inst[2];
	PackedFloat32Array prop_buf[2];
	int prop_shown[2] = { 0, 0 };
	AudioStreamPlayer3D *murmur[2] = { nullptr, nullptr };
	Vector3 lie_c;              // a lying figure's middle, in its own frame, and the way it lies (for the towel under it)
	float lie_yaw = 0.0f;
	void make_extras();
	void free_extras();
	void extras_update(double p_alpha);
	void make_near();
	void near_update(double p_delta, double p_alpha);
	void clip_of(int i, StringName &r_clip, double &r_speed, double &r_hold) const;
	// counters
	struct Count { int frames = 0, steps = 0; double step_us = 0, step_us_worst = 0, main_us = 0, main_us_worst = 0, people = 0, near = 0, umbrellas = 0; int most = 0; } cnt;

	bool load();
	void make_look();
	void person_of(int i, float r[4], int &r_body, float &r_scale) const;
	int pose_of(int i) const;
	void step_brain(double p_delta);
	void draw(double p_alpha);
	void cell_set(const String &p_key, bool p_in);

protected:
	static void _bind_methods();

public:
	CityCrowd();
	~CityCrowd();

	void _ready() override;
	void _exit_tree() override;
	void _process(double p_delta) override;
	void _physics_process(double p_delta) override;

	// who else there is: the traffic (cars to see and to be seen by, the signals' clock), the streamer (its cells),
	// the player on foot (any Node3D; people step aside for him and may be talked to)
	void set_traffic(Object *p_traffic);
	void attach(Object *p_streamer);
	void _on_cell_in(const String &p_key);
	void _on_cell_out(const String &p_key);
	void set_player(Object *p_player);

	void set_max_people(int p_n) { max_people = p_n; }
	int get_max_people() const { return max_people; }
	void set_density(double p_d) { density = p_d; }
	double get_density() const { return density; }
	void set_hour(double p_h) { hour = p_h; }
	double get_hour() const { return hour; }
	void set_clock_rate(double p_r) { clock_rate = p_r; }
	double get_clock_rate() const { return clock_rate; }
	void set_weekday(int p_d) { weekday = p_d; }
	int get_weekday() const { return weekday; }
	void set_rain(double p_r) { rain = p_r; }
	double get_rain() const { return rain; }
	void set_near_max(int p_n) { near_max = p_n; }
	int get_near_max() const { return near_max; }
	void set_streets_path(const String &p_path) { streets_path = p_path; }
	String get_streets_path() const { return streets_path; }
	void set_places_path(const String &p_path) { places_path = p_path; }
	String get_places_path() const { return places_path; }

	// ---- hooks for the rest of the game (ped_crowd.h says what each does)
	int place_walker(const Vector3 &p_at, int p_look);
	bool remove_walker(int p_id);
	bool set_goal(int p_id, int p_place, double p_stay_s, bool p_enter);
	bool set_goal_point(int p_id, const Vector3 &p_at, double p_stay_s);
	bool stay(int p_id, double p_seconds);
	bool set_act(int p_id, int p_act, double p_seconds);
	bool hold(int p_id, bool p_on, double p_yaw);
	bool hide(int p_id, bool p_on);
	void scare(const Vector3 &p_at, double p_radius, double p_seconds);
	void bus_at(int p_place, bool p_on, const Vector3 &p_door, int p_get_off);
	void bench_off(int p_place, bool p_off);
	// the place of a kind nearest a point (-1 = none within the radius); kinds: ped_places.h PL_*
	int place_near(const Vector3 &p_at, int p_kind, double p_radius) const;
	Dictionary place_info(int p_place) const;
	// the people round a point: id, at, yaw, speed, mode, act, state, party
	Array people_near(const Vector3 &p_at, double p_radius) const;
	// what happened since the last call: [type, id, aux, f] each (ped_crowd.h E_*); also sent as the signal "crowd_event"
	Array take_events();
	Dictionary stats() const;
	// one line for the test app's log: how many, what it cost, since the last call
	String report();
	pc::Crowd *brain() { return crowd; }
};

} // namespace godot
