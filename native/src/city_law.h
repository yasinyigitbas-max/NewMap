// CityLaw: the police, the ambulance and the small crimes of the street, all C++ (Yasin, 20 Nov, his GTA IV list:
// "police on foot or in cars, wanted level, chases", "paramedics come to the injured", "emergency vehicles with sirens",
// "small crimes by NPCs (mugging, police chasing them)": "i want all of them").
//
//  - WHAT THE LAW HEARS: CityCrowd's incidents (a blow, a car hitting somebody, a car taken, a shot, a mugging). A crime
//    of the player's is known at once if police are near (a policeman within 40 m, a police car within 60 m), else when
//    a witness has called (7 s, if anybody is within 35 m to call); nobody near, nobody calls.
//  - THE WANTED LEVEL: 1 to 5 stars (the HUD, under the money box). A blow or a car taken: one; somebody run down hard
//    or a shot: two; a crime again while wanted: one more (not more often than every 12 s). The police lose him when none
//    of them has seen him for 12 s + 6 s a star and he is 60 m from where they saw him last; the stars blink meanwhile.
//  - POLICE CARS: as many as the stars (four at most), the traffic's own cars of the game (CityTraffic::spawn_driver),
//    painted dark blue, a light bar on the roof (red and blue, flashing) and the siren (the wail; the yelp when close),
//    sent from 150-200 m away and driven after him. Near him on foot they pull over and two officers get out and run
//    after him; reaching him: BUSTED (a fine, the stars gone). He drives off: they go back to their car and chase on.
//  - THE AMBULANCE: somebody down who stays down (a hard knock): 10 s after (somebody called), a white van with its own
//    siren (hi-lo) comes, two paramedics get out, kneel by him, he gets up, they drive off.
//  - MUGGINGS: now and then (every 2-3 minutes, on foot) a man walks up to somebody near the player, threatens him, takes
//    something and runs; the victim calls; a police car comes for the mugger, an officer runs him down and takes him.
#pragma once

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <vector>

namespace godot {

class CityCrowd;
class CityTraffic;
class CityPlayer;
class AudioStreamPlayer3D;
class MeshInstance3D;
class StandardMaterial3D;

class CityLaw : public Node {
	GDCLASS(CityLaw, Node)

public:
	enum { U_POLICE = 0, U_AMBULANCE = 1 };
	enum { S_ORDERED = 0, S_DRIVE = 1, S_STOP = 2, S_FOOT = 3, S_BACK = 4, S_LEAVE = 5, S_TREAT = 6, S_DONE = 7 };

private:
	uint64_t crowd_id = 0, traffic_id = 0, player_id = 0;
	CityCrowd *crowd() const;
	CityTraffic *traffic() const;
	CityPlayer *player() const;

	// ---- the wanted level
	int wanted = 0;
	// police on foot (patrol_update): who, how long on his way, whether he has his gun on the player
	struct Patrol { int walker = -1; float t = 0.0f; bool aiming = false; };
	std::vector<Patrol> patrols;
	double patrol_next = 8.0;
	int n_patrols = 0, n_aims = 0;
	void patrol_update(double p_delta);
	bool seen = false;
	double unseen_t = 0.0, last_raise = -99.0, clock = 0.0;
	Vector3 last_seen;
	struct Report { Vector3 at; int stars; double due; };
	std::vector<Report> reports;
	void raise(int p_stars);
	void lose();
	// ---- the units: police cars and ambulances
	struct Unit {
		int kind = U_POLICE, st = S_ORDERED;
		int ticket = -1, car = -1;              // the order's ticket; the traffic's car (its id)
		int model = 2;
		float t = 0.0f, order_cd = 0.0f, life = 0.0f;
		Vector3 at, goal;                        // the car's place now; where it is sent
		float yaw = 0.0f, v = 0.0f;
		bool has_pose = false;
		int target = -2;                         // police: -2 the player, else a walker (a mugger); ambulance: the hurt one
		int crew[2] = { -1, -1 };
		AudioStreamPlayer3D *siren = nullptr;
		int siren_kind = -1;                     // 0 the wail, 1 the yelp, 2 the hi-lo
		MeshInstance3D *bar = nullptr;           // the light bar
		float stuck_t = 0.0f;
		int tries = 0;
	};
	std::vector<Unit> units;
	Ref<StandardMaterial3D> m_red, m_blue, m_off;
	void unit_make_gfx(Unit &u);
	void unit_free(Unit &u);
	void unit_update(Unit &u, double p_delta);
	void crew_out(Unit &u);
	void crew_back(Unit &u);
	bool crew_in(const Unit &u) const;
	Vector3 spawn_from(const Vector3 &p_to) const;
	int police_units() const;
	// ---- the ambulance's calls
	struct Call { int victim; Vector3 at; double due; bool sent = false; };
	std::vector<Call> calls;
	// ---- the muggings
	struct Mug { int mugger = -1, victim = -1, st = 0; float t = 0.0f; Vector3 at; };
	std::vector<Mug> mugs;
	double mug_next = 60.0;
	void mug_start();
	void mug_update(Mug &m, double p_delta);
	// ---- BUSTED
	double busted_t = -1.0;
	// settings
	bool police_on = true, ambulance_on = true, crimes_on = true;
	double mug_every = 150.0;
	// counts
	int n_reports = 0, n_cars = 0, n_out = 0, n_busted = 0, n_lost = 0, n_ambulances = 0, n_treated = 0, n_mugs = 0, n_mug_caught = 0, n_refused = 0;

protected:
	static void _bind_methods();

public:
	CityLaw();
	~CityLaw();
	void _ready() override;
	void _exit_tree() override;
	void _process(double p_delta) override;

	void set_world(Object *p_crowd, Object *p_traffic, Object *p_player);
	int get_wanted() const { return wanted; }
	void set_wanted(int p_level);          // (tests, a story's scene)
	bool get_seen() const { return seen; }
	void report(const Vector3 &p_at, int p_stars, double p_delay);   // (tests) a crime of the player's, known after p_delay s
	void call_ambulance(int p_walker);     // (tests) somebody hurt: an ambulance for him now
	void mug_now();                         // (tests) a mugging near the player now
	void set_police(bool p_on) { police_on = p_on; }
	bool get_police() const { return police_on; }
	void set_ambulance(bool p_on) { ambulance_on = p_on; }
	bool get_ambulance() const { return ambulance_on; }
	void set_crimes(bool p_on) { crimes_on = p_on; }
	bool get_crimes() const { return crimes_on; }
	void set_mug_every(double p_s) { mug_every = p_s; }
	double get_mug_every() const { return mug_every; }
	Array units_info() const;
	Dictionary stats() const;
};

} // namespace godot
