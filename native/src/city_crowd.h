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

#include "way_floor.h"

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
	enum { ROW = 16, POSES = 17, NEAR_MAX = 18 };   // (POSES: as PeopleBake makes them; 13-16 ride a bicycle)

private:
	pc::Crowd *crowd = nullptr;
	bool ready = false, gfx = false;
	String streets_path = "res://map_dc/coronado/city_kit/traffic/streets.bin";
	String places_path = "res://map_dc/coronado/city_kit/traffic/places.bin";
	String people_dir = "res://characters/rocketbox/";
	// the sea: its depth map and its surface's height
	String sea_path = "res://tools/city/look/sea_map.png";
	double sea_y = 0.0;
	std::vector<float> sea_d;
	int sea_w = 0, sea_h = 0;
	float sea_x0 = 0, sea_z0 = 0, sea_step = 8.0f;
	// settings
	int max_people = 300;
	double density = 1.0, hour = 12.0, clock_rate = 0.0, rain = 0.0;   // clock_rate: game hours a real second (0 = the hour stands)
	int weekday = 2;
	double near_r = 24.0, near_fade = 6.0;
	int near_max = 12;
	bool draw_on = true;
	// the step
	double acc = 0.0, own_clock = 0.0;
	uint64_t traffic_id = 0, player_id = 0, streamer_id = 0, car_id = 0;
	float car_hl = 2.3f, car_hw = 1.0f;     // the car the player drives: a box the people see, like the traffic's cars
	Vector3 car_last; bool has_car_last = false;
	std::vector<uint8_t> cells;
	bool cells_all = true, cells_dirty = false;
	std::vector<float> cars, dyn, bus_buf;
	std::vector<int> bus_here;          // the stops (places) a bus stands at now
	int buses_served = 0;
	std::vector<String> place_names;   // the shops' names (places.bin)
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
	struct Near { CityPed *ped = nullptr; class FootPlant *plant = nullptr; int plant_walker = -1; Vector3 last_at; bool has_last = false; int walker = -1; int female = 0; bool in_body = false; float push_cd = 0; Ref<ShaderMaterial> look; int act = -1; float act_t = 99.0f, v_s = 0.0f; int why = 0, after_kind = 0; float after_t = 0.0f, after_len = 0.0f; bool after_hit = false; bool stepping = false; float y_s = 0.0f; bool has_y = false;
		// the walk start / stop (tools/people/make_steps.gd) for the walker it shows: 1 setting off, 2 stopping
		int st_mode = 0, st_walker = -1; float st_t = 0.0f; bool st_moving = false; StringName st_clip; };   // act, act_t: what it shows and for how long (the way INTO an act is played once)
	// how long the clips into and out of an act are (read from the figure once it is made)
	bool lens_ok = false;
	int fight_falls = 0;
	// who the player has shoved lately (by who the person is), so that a second shove is answered differently
	struct Shove { uint32_t look = 0; double t = -1e9; int n = 0; };
	std::vector<Shove> shoves;
	int n_shoved = 0, n_told_off = 0, n_hit_back = 0;
	double l_sit_in = 0, l_sit_out = 0, l_gsit_in = 0, l_gsit_out = 0, l_lie_in = 0, l_lie_out = 0, l_duck_in = 0, l_duck_out = 0, l_fight_in = 0, l_fight_out = 0, l_surprise = 0, l_cheer = 0;
	std::vector<Near> near_pool;
	// the smaller things (city_crowd_extra.cpp): capsules round the player, umbrellas, towels, the murmur
	enum { CAPSULES = 12 };
	bool extras = false;
	int cap_steps = 0;   // (tests) physics steps the capsules were placed
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
	void clip_of(int i, float p_t, float p_v, StringName &r_clip, double &r_speed, double &r_hold, int &r_token) const;
	void clip_lengths();
	void onlookers(int p_row, int p_most, float p_seconds, bool p_film, bool p_call = false);
	// Something people react to (B31, Yasin 20 Nov: "they were supposed to call the police or take pictures videos ...
	// and try to run away"): kind 1 the player hits someone, 2 a car hits someone, 3 a cyclist comes off, 4 a fight
	// between two of ours knocks one down. The crowd's scare at that spot (near ones duck, others run, some at a safe
	// distance stare, film or call). The same spot again within 3 s is one alarm.
	struct Alarm { Vector3 at; double t; };
	std::vector<Alarm> alarms_recent;
	int alarms[5] = { 0, 0, 0, 0, 0 }, cars_hit_people = 0;
	void alarm(const Vector3 &p_at, float p_radius, float p_seconds, int p_kind);
	// counters
	WayFloor way_floor;      // a collision floor 3 cm under every pavement and crossing (the city's collision has holes)
	int riders_drawn = 0;   // the traffic's cyclists drawn as riders this frame
	// the nearest cyclists as real riders on a cruiser rig of their own (city_crowd_riders.cpp)
	static constexpr int RIDERS_NEAR = 3;
	struct NearRider { CityPed *ped = nullptr; class BikeReach *reach = nullptr; Node3D *rig = nullptr, *crank = nullptr, *pedal[2] = { nullptr, nullptr }, *wheel[2] = { nullptr, nullptr };
		Transform3D r_crank, r_pedal[2], r_wheel[2]; Ref<ShaderMaterial> look, paint; int id = -1, linger = 0; float seat = 0.0f; };   // seat: how far under the usual saddle place this person sits (shorter legs)
	std::vector<NearRider> rider_pool;
	std::vector<int> rider_ids;
	int riders_near = 0; float riders_miss = 0.0f; bool riders_miss_hand = false; String riders_limbs;
	void near_riders(const std::vector<float> &p_bikes, const Vector3 &p_cam, CityTraffic *p_trf);
	// THE PLAYER'S FIGHT (Yasin: "locking onto the nearest npc, and keep locked on until they are or we are defeated. give
	// npcs some low health that takes a few jabs"; "make npcs defend themselves attack back or try to dodge sideways once we
	// hit them, they shouldnt get into combat mode unless we hit them"). Locked on the nearest person; he goes on with his
	// day until he is hit; from the first blow he faces the player and fights: steps in, hits back, or dodges sideways.
	// Four jabs beat him, eight blows beat the player; the beaten one goes down by his balancing body (never killed).
	struct PFight {
		int walker = -1, hp = 4, php = 8, st = 0, dodge_dir = 1;   // st: 0 guard, 1 a blow, 2 a dodge, 3 stepping in
		bool angry = false, hit_done = false, player_down = false;
		float ai_t = 0.0f, st_t = 0.0f, punch_in = -1.0f, in_t = 0.0f;   // (in_t: since he went into his guard: PunchKick_Enter played through)
		int landed = 0, missed = 0, attacks = 0, hits_on_player = 0, dodges = 0, npc_beaten = 0, player_beaten = 0, locks = 0;
	} pf;
	void player_fight(double p_delta);
	// ROAD RAGE: the drivers who got out of hit cars (CityTraffic::take_rage). Each gets out (Sitting_Exit), yells and
	// waves his arms (Counter_Angry), then goes for whoever hit him: the player (put into combat, locked on him, the
	// moment the player is on foot and sees him: Yasin "whenever there is an aggressor in the screen, we should get into
	// the combat mode") or the other driver (the two come to blows). foe: -1 the player, a walker id, -3 nobody (the one
	// who did the hitting: he only gets out)
	// (Yasin, 20 Nov: "dont make us automatically go out, we should be able to hit and run too, just make them angry, and
	// if we get out of the car, they chase us and we fight"): while the player stays in his car the driver only yells;
	// the player driving off (60 m away) is a hit and run: he gives up and walks off; the player on foot: he runs after
	// him and the fight starts when he reaches him
	// the run: Sprint_Enter into it, Sprint_Loop, Sprint_Exit as he reaches the player (Yasin: "use enter exit run animations")
	struct Rager { int walker; float t; int foe; bool chase = false; float away_t = 0.0f, chase_t = 0.0f, arrive_t = -1.0f, dist = 0.0f; };
	std::vector<Rager> ragers;
	int rages = 0, rage_fights = 0, rage_npc_fights = 0, rage_chases = 0, rage_given_up = 0;
	void rage_update(double p_delta);
	void end_fight(bool p_release);
	Dictionary fight_stats() const;
	// cyclists who came off (CityTraffic::bikes_down_now): each is a person on the road now, given a near body at once
	// and thrown by the blow; if no body can be his within 1.5 s (far from the camera) he just walks to the pavement
	struct Thrown { int walker; Vector3 vel, imp, at; float t; };
	std::vector<Thrown> thrown;
	int riders_thrown = 0, riders_bodied = 0;
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
	// the car the player drives (any Node3D that looks along its +z): people get out of its way, and are knocked over by it
	void set_player_car(Object *p_car, double p_half_length, double p_half_width);
	void attach(Object *p_streamer);
	void _on_cell_in(const String &p_key);
	void _on_cell_out(const String &p_key);
	void set_player(Object *p_player);
	// (for the talk, city_talk.cpp) the brain, the player, a shop's name, whether a walker is a woman
	pc::Crowd *brain() const { return crowd; }
	uint64_t get_player_id() const { return player_id; }
	String place_name(int p_place) const { if (!crowd || p_place < 0 || p_place >= (int)crowd->places.size()) return String(); const int n = crowd->places[p_place].kind == pc::PL_SWIM ? -1 : crowd->places[p_place].name; return n >= 0 && n < (int)place_names.size() ? place_names[n] : String(); }
	bool walker_female(int p_row) const { return crowd && ((crowd->look[p_row] >> 3) & 1u) != 0; }

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
	// (the game, and tests) somebody is knocked about by something of the game's own: his walker is where the game says
	// until it lets him go (on = false: he walks back to the pavement, to his people, and on to where he was going)
	bool to_body(int p_id, bool p_on, const Vector3 &p_at) { return crowd && crowd->to_body(p_id, p_on, (float)p_at.x, (float)p_at.z); }
	void load_sea();
	int place_from_file(int p_n) const { return crowd && p_n >= 0 && p_n < (int)crowd->place_from_file.size() ? crowd->place_from_file[p_n] : -1; }
	int swim_spot_of(int p_place) const { return crowd && p_place >= 0 && p_place < (int)crowd->swim_of.size() ? crowd->swim_of[p_place] : -1; }
	float sea_depth(float p_x, float p_z) const;    // metres of water at a place (0 = land)
	void set_sea_path(const String &p_p) { sea_path = p_p; }
	String get_sea_path() const { return sea_path; }
	void set_sea_y(double p_y) { sea_y = p_y; }
	double get_sea_y() const { return sea_y; }
	Array near_bodies() const;     // (tests) every animated body: whose it is and which clip it plays
	bool fight(int p_a, int p_b) { return crowd && crowd->fight(p_a, p_b); }
	void scare(const Vector3 &p_at, double p_radius, double p_seconds);
	void bus_at(int p_place, bool p_on, const Vector3 &p_door, int p_get_off);
	void bench_off(int p_place, bool p_off);
	// the place of a kind nearest a point (-1 = none within the radius); kinds: ped_places.h PL_*
	int place_near(const Vector3 &p_at, int p_kind, double p_radius) const;
	Dictionary place_info(int p_place) const;
	// The nearest point of the pavement to p_at (within p_max_d): {ok, at (on the pavement, its height), yaw (along it),
	// edge (the kerb's side: a unit vector to the road), half_width}. Pavements are outdoors: never in or on a building.
	Dictionary pavement_near(const Vector3 &p_at, double p_max_d) const;
	// (audits) every pavement and crossing as points p_step metres apart, at their height
	PackedVector3Array walk_points(double p_step) const;
	PackedVector2Array map_lines(int p_kind) const;   // the phone's map: pavements (0) or crossings (1) as (x, z) pairs
	// the phone's map: every enterable room's door (x, z, the shop's kind); its name
	PackedVector3Array map_rooms() const;
	String room_name(int p_i) const;
	// (audits) the same over the WHOLE width people may use: on each pavement and crossing a row of points across it
	// (from -half width + p_margin to +half width - p_margin, p_across apart) every p_step metres along it.
	// {points: PackedVector3Array, kinds: PackedByteArray (0 pavement, 1 crossing)}
	Dictionary walk_points_across(double p_step, double p_across, double p_margin) const;
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
