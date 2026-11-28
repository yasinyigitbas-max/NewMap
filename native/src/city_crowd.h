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
#include <unordered_map>

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
#include "trav_mirror.h"

namespace godot {

class CityTraffic;
class CityPed;
class AudioStreamPlayer3D;

class CityCrowd : public Node3D {
	GDCLASS(CityCrowd, Node3D)
	friend class CityLaw;   // (the law directs the actors: city_law.cpp)
	friend class CityShops;   // (the shops' people are actors too: city_shops.cpp)

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
	float car_hit_cd = 0.0f, car_hit_v = 0.0f; int cars_hit_player = 0;   // (a car reaching the player on foot: player_fight)
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
	// who is saying a line from his seat (CityTalk: a seated person keeps his act; his body shows the seated talk)
	std::unordered_map<int, double> speak_until;
public:
	void speaking_for(int p_id, double p_seconds) { speak_until[p_id] = own_clock + p_seconds; }
	// the gesture of what he says now (CityTalk::line_gesture), for that long
	void talk_gesture(int p_id, int p_kind, double p_seconds) { gest_kind[p_id] = p_kind; gest_until[p_id] = own_clock + p_seconds; }
	std::unordered_map<int, int> gest_kind;
	std::unordered_map<int, double> gest_until;
	int gesture_now(int p_id) const { const auto u = gest_until.find(p_id); if (u == gest_until.end() || u->second < own_clock) return -1; const auto k = gest_kind.find(p_id); return k == gest_kind.end() ? -1 : k->second; }
	bool speaking(int p_id) const { auto it = speak_until.find(p_id); return it != speak_until.end() && it->second > own_clock; }
private:
	struct Near { CityPed *ped = nullptr; class FootPlant *plant = nullptr; int plant_walker = -1; Vector3 last_at; bool has_last = false; int walker = -1; int female = 0; bool in_body = false; float push_cd = 0; Ref<ShaderMaterial> look; int act = -1; float act_t = 99.0f, v_s = 0.0f; int why = 0, after_kind = 0; float after_t = 0.0f, after_len = 0.0f; bool after_hit = false; bool stepping = false; float y_s = 0.0f; bool has_y = false;
		// the walk start / stop (tools/people/make_steps.gd) for the walker it shows: 1 setting off, 2 stopping
		int st_mode = 0, st_walker = -1; float st_t = 0.0f; bool st_moving = false; StringName st_clip;
		// CPR (the Animator, 21 Nov): 1 lying as the clip lies while a medic works on him, 2 getting up from his back
		int cpr = 0; float cpr_t = 0.0f; Transform3D cpr_xf;
		class MeshInstance3D *phone2 = nullptr;   // the phone of a call or a text (in the hand at his ear, or held in front of him)
		// a phone in his raised hand while he films (Yasin, 20 Nov: "put a rectangular phone like shape in npcs hands when
		// they are recording"): made the first time it is needed, shown only then
		class MeshInstance3D *phone = nullptr; Vector3 phone_base; float phone_k = 0.01f; };   // act, act_t: what it shows and for how long (the way INTO an act is played once)
	// how long the clips into and out of an act are (read from the figure once it is made)
	bool lens_ok = false;
	int fight_falls = 0;
	// who the player has shoved lately (by who the person is), so that a second shove is answered differently
	struct Shove { uint32_t look = 0; double t = -1e9; int n = 0; };
	std::vector<Shove> shoves;
	int n_shoved = 0, n_told_off = 0, n_hit_back = 0;
	double l_sit_in = 0, l_sit_out = 0, l_gsit_in = 0, l_gsit_out = 0, l_lie_in = 0, l_lie_out = 0, l_duck_in = 0, l_duck_out = 0, l_fight_in = 0, l_fight_out = 0, l_surprise = 0, l_cheer = 0;
	std::vector<Near> near_pool;
#ifdef TRAV_IN_GAME
	// the new people (city_crowd_trav.cpp): each near figure drawn as a new body on the traversal system
	struct TravNb { class CharacterBody3D *body = nullptr; class CityTravTape *tape = nullptr; bool on = false, going = false, failed = false; int walker = -1; float base_pace = 1.0f;
		// sitting with the body's own take: 0 not, 1 asked (its seat is the one seat in the group "tl_seat"), 2 seated, 3 getting up
		int sit = 0; float sit_t = 0.0f; class Node3D *seat = nullptr;
		// his walker's own motion, as drawn (28 Nov night: followed by its velocity, not by stop-and-go on the gap)
		Vector3 prev_at, wv; double prev_t = 0.0; bool prev_set = false;
		TravMirror mir; };      // the pose copy (an act the new bodies have no take for): trav_mirror.h
	std::vector<TravNb> trav_pool;
	std::vector<String> trav_ids;
	bool trav_people = false;
	bool trav_due = false;      // a frame was drawn since the last trav_people_update (set in _process)
	void trav_make(int k);
	int trav_seat_busy = -1;
	// the benches near the player as seats his own sitting take can use (the lab's group "tl_seat"): the nearest four
	class Node3D *trav_bench[4] = { nullptr, nullptr, nullptr, nullptr }; int trav_bench_t = 0;
	void trav_benches();
	void trav_people_update();
public:
	void set_trav_people(bool p_on);
	bool get_trav_people() const { return trav_people; }
private:
#endif
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
	int alarms[8] = { 0, 0, 0, 0, 0, 0, 0, 0 }, cars_hit_people = 0;
	void alarm(const Vector3 &p_at, float p_radius, float p_seconds, int p_kind);
	// what happened that the law (CityLaw) should hear of: kind as the alarm's (1 the player hits someone, 2 a car hits
	// someone, 3 a cyclist comes off, 4 a fight between ours, 5 a shot, 6 a mugging, 7 a car taken); by the player or
	// not; the person hurt (-1 none) and how badly (0 a blow, 1 down, 2 down and staying down: an ambulance is wanted)
	struct Incident { Vector3 at; int kind; bool by_player; int victim; int hurt; double t; };
	std::vector<Incident> incidents;
	void incident(const Vector3 &p_at, int p_kind, bool p_by_player, int p_victim, int p_hurt);

	// ---- ACTORS (city_crowd_actors.cpp): a walker the game takes off its day to do something of the game's: walk or
	// run to a point or after somebody, stand facing a way, play a clip of its own. Held (M_HELD) while it is one; let go,
	// it walks back to the pavement and on (or is taken away if the game placed it). The helpers, the paramedics, the
	// police on foot, a mugger and his victim, a driver pulled out of his car are actors.
	struct Actor {
		int walker = -1, role = 0, st = 0;
		float t = 0.0f, life = 0.0f;              // seconds in this state; in all
		Vector3 to; int to_walker = -1;           // where it goes (or after whom: to_walker >= 0 follows him; -2 the player)
		float speed = 0.0f, near = 0.6f;          // m/s (0: it stands); how near is there
		bool arrived = false, placed = false;     // placed: made by the game (taken away when let go)
		float face = 0.0f; bool facing = false;   // standing: turned this way
		StringName clip; double hold = -1.0; int token = 0;   // its own clip while it stands (empty: the crowd's own)
		int helps = -1;                           // (helpers, medics) the one he kneels by
		StringName once; float once_left = 0.0f; bool once_gone = false;   // a clip played through where he stands (out of a car, into one), then moved to where it left him; gone: taken away after it
		float ground_t = 0.0f;
		// TALKED TO (CityTalk): he stops what he does, turns to the player (not seated), and goes on after; his own clip kept
		bool talking = false; StringName s_clip; double s_hold = -1.0; int s_token = 0; float s_face = 0.0f; bool s_facing = false;
		// SEATED (a chair): his height is the floor's, never the seat's (the room's furniture collision is under him)
		bool seated = false; float floor_y = 0.0f;
	};
	std::vector<Actor> actors;
	std::vector<std::pair<int, int>> uniforms;   // walker -> body tag (2 police, 3 medical): the clothes of the job
	enum { R_NONE = 0, R_HELPER = 1, R_MEDIC = 2, R_COP = 3, R_MUGGER = 4, R_VICTIM = 5, R_DRIVER = 6, R_COWER = 7, R_CALLER = 8, R_STAFF = 9, R_SHOPPER = 10, R_SITTER = 11 };
	Actor *actor_of(int p_walker);
	const Actor *actor_of(int p_walker) const;
	void actor_clip(const Actor &p_a, StringName &r_clip, double &r_speed, double &r_hold, int &r_token) const;
	float ground_y(const Vector3 &p_at, float p_def) const;
	void actors_update(double p_delta);
	void stay_down(int p_walker, bool p_on);
	void driver_robbed(int p_walker);
	int drivers_robbed = 0;
	int uniform_of(int p_walker) const;
	// the hurt who stay down (a hard knock): the body lies until a medic has been (or two minutes)
	struct Down { int walker; double t; bool treated = false; int helpers = 0; bool cpr = false; };
	std::vector<Down> downs;
	void helpers_for(int p_victim, const Vector3 &p_at);
	int helpers_sent = 0, helpers_knelt = 0, steps_in = 0, n_cpr = 0;
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
	bool strike_due = false; Vector3 strike_a, strike_b; uint64_t strike_by = 0;   // (a blow for the damage system, made in the physics step)
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
	// (the Animator, 20 Nov: "we should drive over them and car should be lifted a bit off the ground") the crowd a car
	// asks what is under its wheels: the highest downed body's top within 0.25 m of p, or -1e9
	static CityCrowd *the;
	float body_under(const Vector3 &p_at) const;
	// a car as the bodies feel it: a low box for the bonnet and the boot (0.22-0.85 m over the road: a body slides under
	// its sills and is swept onto it) and one for the cabin on top; 2 boxes from box k on
	static int car_boxes(CityPed *p_ped, int k, const float *q, float p_ground_y);

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
	// ---- actors (see the private part): the game's hands on a walker
	bool actor_take(int p_walker, int p_role);
	int actor_place(const Vector3 &p_at, int p_tag, double p_yaw, int p_role);   // a new person in the clothes of tag (0 own)
	bool actor_go(int p_walker, const Vector3 &p_to, double p_speed, double p_near);
	bool actor_follow(int p_walker, int p_target, double p_speed, double p_near);   // p_target -2: the player
	bool actor_stand(int p_walker, double p_yaw, const StringName &p_clip, double p_hold, int p_token);
	// a clip played once where he stands, turned p_yaw (out of a car, into one: Mixamo's, which walk and turn as they go):
	// after it he stands where the clip left him, turned as it left him; p_gone: then he is taken away (into the car)
	bool actor_once(int p_walker, double p_yaw, const StringName &p_clip, bool p_gone);
	bool actor_arrived(int p_walker) const;
	bool is_actor(int p_walker) const;
	int actor_role(int p_walker) const;
	void actor_release(int p_walker);
	// let go as one of the crowd's own (even one the game placed): he walks back to the pavement and on with his day
	void actor_free(int p_walker);
	// seated on a chair: the floor's height kept (p_floor_y), a sitting clip
	bool actor_seat(int p_walker, double p_floor_y, double p_yaw, const StringName &p_clip);
	// TALKING (Yasin: "all of them should be interactible like normal npcs"): the shop's people may be talked to as anybody;
	// CityTalk holds and lets go through this (an actor pauses and goes on; anybody else is held as before)
	bool talkable_actor(int p_walker) const;
	bool talk_hold(int p_walker, bool p_on, double p_yaw);
	Vector3 walker_at(int p_walker) const;
	bool walker_alive(int p_walker) const;
	// the hurt who lie until a medic comes: is he one; the medic has been (he gets up)
	bool is_down(int p_walker) const;
	void set_cpr(int p_walker, bool p_on);
	// carrying something (Yasin, 21 Nov: "some people carrying boxes or bags or brief cases"): his shopping, and one walker
	// in eight always; what: 0 a bag, 1 a box, 2 a briefcase (by his look)
	bool carries(int i) const;
	int carry_kind(int i) const;   // (the medics: one gives CPR, the one down lies flat and takes it)
	void treat(int p_walker);
	Array downs_list() const;   // [{walker, at, t, treated}]
	// what happened since the last call (CityLaw): [{at, kind, by_player, victim, hurt}]
	Array take_incidents();
	std::vector<Incident> &incidents_raw() { return incidents; }
	// GUNS (none yet; Yasin, 20 Nov: "they dont exist yet but they will be"): what the weapons will tell the people. Aimed
	// at: whoever stands in the line within 25 m puts his hands up or cowers while it lasts, then runs. A shot: everybody
	// near ducks or runs, farther ones film or call, and the traffic round it is told (CityTraffic::panic).
	void gun_aimed(const Vector3 &p_from, const Vector3 &p_dir, double p_seconds);
	void gunshot(const Vector3 &p_at, bool p_by_player);
	// (tests, scenes) a walker near the camera knocked down hard: he lies until a medic has been; false if he has no body near
	bool knock_down_walker(int p_walker);
	int cowering = 0, shots_heard = 0;
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


#ifdef TRAV_IN_GAME
// what a new body is told each tick (TravBody reads its tape's sample()): filled by CityCrowd::trav_people_update
class CityTravTape : public Node {
	GDCLASS(CityTravTape, Node)
protected:
	static void _bind_methods();
public:
	Dictionary s;
	Dictionary sample() const { return s; }
};
#endif

} // namespace godot
