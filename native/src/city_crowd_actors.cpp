// CityCrowd's actors: walkers the game takes off their day (Yasin, 20 Nov, from the GTA IV list: "others come to help the
// victim", "paramedics come to the injured", "police on foot", "small crimes by NPCs", "crouch or hands up when a gun is
// aimed at them": "i want all of them"). An actor is held (pc::M_HELD) and moved by hand: it walks, jogs or runs to a
// point or after somebody, stands facing a way and plays a clip of its own. The hurt who stay down, the passers-by who
// come to them, and what the guns (none yet) will tell the people live here too. CityLaw (city_law.cpp) directs the
// police, the ambulance and the crimes through these hooks.
#include "city_crowd.h"

#include "city_ped.h"
#include "city_player.h"
#include "city_traffic.h"
#include "ped_crowd.h"

#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

CityCrowd::Actor *CityCrowd::actor_of(int p_walker) {
	for (Actor &a : actors) if (a.walker == p_walker) return &a;
	return nullptr;
}
const CityCrowd::Actor *CityCrowd::actor_of(int p_walker) const {
	for (const Actor &a : actors) if (a.walker == p_walker) return &a;
	return nullptr;
}
bool CityCrowd::is_actor(int p_walker) const { return actor_of(p_walker) != nullptr; }
int CityCrowd::actor_role(int p_walker) const { const Actor *a = actor_of(p_walker); return a ? a->role : 0; }

int CityCrowd::uniform_of(int p_walker) const {
	for (const auto &u : uniforms) if (u.first == p_walker) return u.second;
	return -1;
}

Vector3 CityCrowd::walker_at(int p_walker) const {
	if (!crowd) return Vector3();
	for (const Near &nb : near_pool) if (nb.walker == p_walker && nb.ped && nb.ped->get_mode() != CityPed::MODE_ANIM) return nb.ped->body_at();
	const int i = crowd->find(p_walker);
	return i >= 0 ? Vector3(crowd->x[i], crowd->y[i], crowd->z[i]) : Vector3();
}
bool CityCrowd::walker_alive(int p_walker) const { return crowd && crowd->find(p_walker) >= 0; }

bool CityCrowd::actor_take(int p_walker, int p_role) {
	if (!crowd) return false;
	if (Actor *a = actor_of(p_walker)) { a->role = p_role; return true; }
	const int i = crowd->find(p_walker);
	if (i < 0 || crowd->mode[i] == pc::M_BODY) return false;
	if (crowd->mode[i] != pc::M_HELD && !crowd->hold(p_walker, true, crowd->yaw[i])) return false;
	crowd->act[i] = pc::A_NONE; crowd->flags[i] &= (uint8_t)~(pc::F_FLEE | pc::F_FACE);
	Actor a; a.walker = p_walker; a.role = p_role; a.face = crowd->yaw[i];
	actors.push_back(a);
	return true;
}

int CityCrowd::actor_place(const Vector3 &p_at, int p_tag, double p_yaw, int p_role) {
	if (!crowd) return -1;
	static uint32_t seed = 0x2545F491u;
	seed = seed * 1664525u + 1013904223u;
	uint32_t look = seed ^ (seed >> 15);
	look &= ~8u;   // (a man: the uniformed bodies are of both; the voice is a man's)
	const int w = crowd->place_held_at((float)p_at.x, (float)p_at.z, look, (float)p_yaw);
	if (w < 0) return -1;
	if (p_tag > 0) uniforms.push_back({ w, p_tag });
	{   // (the near figure must be of the walker's kind: a uniform body of the other kind turns the walker's look round)
		const int i = crowd->find(w);
		float pq[4]; int bq = 0; float sq;
		if (i >= 0 && !bodies.empty()) {
			person_of(i, pq, bq, sq);
			if (bq >= 0 && bq < (int)bodies.size() && (int)((crowd->look[i] >> 3) & 1u) != bodies[bq].female) crowd->look[i] ^= 8u;
		}
	}
	Actor a; a.walker = w; a.role = p_role; a.placed = true; a.face = (float)p_yaw; a.facing = true;
	actors.push_back(a);
	return w;
}

bool CityCrowd::actor_go(int p_walker, const Vector3 &p_to, double p_speed, double p_near) {
	Actor *a = actor_of(p_walker);
	if (!a) return false;
	a->to = p_to; a->to_walker = -1; a->speed = (float)p_speed; a->near = (float)p_near; a->arrived = false; a->t = 0.0f;
	return true;
}

bool CityCrowd::actor_follow(int p_walker, int p_target, double p_speed, double p_near) {
	Actor *a = actor_of(p_walker);
	if (!a) return false;
	a->to_walker = p_target; a->speed = (float)p_speed; a->near = (float)p_near; a->arrived = false; a->t = 0.0f;
	return true;
}

bool CityCrowd::actor_stand(int p_walker, double p_yaw, const StringName &p_clip, double p_hold, int p_token) {
	Actor *a = actor_of(p_walker);
	if (!a) return false;
	if (a->talking) { a->s_clip = p_clip; a->s_hold = p_hold; a->s_token = p_token; a->s_face = (float)p_yaw; a->s_facing = true; return true; }   // (after the talk)
	a->speed = 0.0f; a->to_walker = -1; a->arrived = true; a->face = (float)p_yaw; a->facing = true;
	a->clip = p_clip; a->hold = p_hold; a->token = p_token; a->t = 0.0f;
	return true;
}

bool CityCrowd::actor_arrived(int p_walker) const { const Actor *a = actor_of(p_walker); return a && a->arrived; }

void CityCrowd::actor_release(int p_walker) {
	for (size_t k = 0; k < actors.size(); k++) {
		if (actors[k].walker != p_walker) continue;
		const bool placed = actors[k].placed;
		actors.erase(actors.begin() + (long)k);
		if (crowd) {
			if (placed) crowd->remove_walker(p_walker);
			else crowd->hold(p_walker, false, 0.0f);
		}
		break;
	}
	for (size_t k = 0; k < uniforms.size(); k++) if (uniforms[k].first == p_walker) { uniforms.erase(uniforms.begin() + (long)k); break; }
}

void CityCrowd::actor_free(int p_walker) {
	for (size_t k = 0; k < actors.size(); k++) if (actors[k].walker == p_walker) { actors.erase(actors.begin() + (long)k); break; }
	for (size_t k = 0; k < uniforms.size(); k++) if (uniforms[k].first == p_walker) { uniforms.erase(uniforms.begin() + (long)k); break; }
	if (!crowd) return;
	const int i = crowd->find(p_walker);
	if (i < 0) return;
	crowd->flags[i] &= (uint8_t)~pc::F_SCRIPT;
	crowd->act[i] = pc::A_NONE;
	crowd->hold(p_walker, false, 0.0f);
}

bool CityCrowd::actor_seat(int p_walker, double p_floor_y, double p_yaw, const StringName &p_clip) {
	Actor *a = actor_of(p_walker);
	if (!a || !crowd) return false;
	a->seated = true; a->floor_y = (float)p_floor_y;
	const int i = crowd->find(p_walker);
	if (i >= 0) { crowd->y[i] = crowd->py[i] = (float)p_floor_y; crowd->act[i] = pc::A_SIT; }
	return actor_stand(p_walker, p_yaw, p_clip, -1.0, 0);
}

bool CityCrowd::talkable_actor(int p_walker) const {
	const Actor *a = actor_of(p_walker);
	return a && (a->role == R_STAFF || a->role == R_SHOPPER || a->role == R_SITTER) && (a->arrived || a->speed <= 0.0f || a->seated);
}

bool CityCrowd::talk_hold(int p_walker, bool p_on, double p_yaw) {
	if (!crowd) return false;
	Actor *a = actor_of(p_walker);
	if (!a) return crowd->hold(p_walker, p_on, (float)p_yaw);
	if (p_on) {
		if (a->talking) return true;
		if (!talkable_actor(p_walker)) return false;
		a->s_clip = a->clip; a->s_hold = a->hold; a->s_token = a->token; a->s_face = a->face; a->s_facing = a->facing;
		a->talking = true;
		if (!a->seated) { a->face = (float)p_yaw; a->facing = true; }
		return true;
	}
	if (!a->talking) return true;
	a->talking = false;
	a->clip = a->s_clip; a->hold = a->s_hold; a->token = a->s_token; a->face = a->s_face; a->facing = a->s_facing;
	return true;
}

// the ground under a point: the world's collision (an actor off the pavements walks on the road, kerbs and all)
float CityCrowd::ground_y(const Vector3 &p_at, float p_def) const {
	Ref<World3D> w = get_world_3d();
	PhysicsDirectSpaceState3D *ss = w.is_valid() ? w->get_direct_space_state() : nullptr;
	if (!ss) return p_def;
	Ref<PhysicsRayQueryParameters3D> rq = PhysicsRayQueryParameters3D::create(p_at + Vector3(0, 1.2f, 0), p_at - Vector3(0, 2.5f, 0), 0xFFFFFFEF);
	const Dictionary h = ss->intersect_ray(rq);
	if (h.is_empty()) return p_def;
	return (float)((Vector3)h["position"]).y;
}

// What an actor's figure plays: on the move a walk, a jog or a run as fast as it goes; standing, its own clip
bool CityCrowd::actor_once(int p_walker, double p_yaw, const StringName &p_clip, bool p_gone) {
	Actor *a = actor_of(p_walker);
	if (!a) return false;
	double len = 0.0;
	for (const Near &nb : near_pool) if (nb.ped) { len = nb.ped->clip_len(p_clip); break; }
	if (len <= 0.0) { if (p_gone) { actor_release(p_walker); remove_walker(p_walker); } return false; }
	a->once = p_clip; a->once_left = (float)len; a->once_gone = p_gone; a->face = (float)p_yaw; a->speed = 0.0f; a->arrived = true;
	const int i = crowd->find(p_walker);
	if (i >= 0) crowd->hold(p_walker, true, a->face);
	return true;
}

void CityCrowd::actor_clip(const Actor &a, StringName &r_clip, double &r_speed, double &r_hold, int &r_token) const {
	if (a.once_left > 0.0f) { r_clip = a.once; r_hold = -2.0; r_token = 7700; r_speed = 1.0; return; }
	static const StringName WALK("ual/Walk_Loop"), JOG("ual/Jog_Fwd_Loop"), RUN("ual/Sprint_Loop"), IDLE("ual/Idle_Loop");
	if (a.speed > 0.0f && !a.arrived) {
		r_hold = -1.0; r_token = 0;
		if (a.speed < 2.0f) { r_clip = WALK; r_speed = a.speed / 1.35f; }
		else if (a.speed < 4.0f) { r_clip = JOG; r_speed = a.speed / 3.0f; }
		else { r_clip = RUN; r_speed = a.speed / 5.6f; }
		return;
	}
	if (a.talking && !a.seated) { static const StringName TALK("ual/Idle_Talking_Loop"); r_clip = TALK; r_hold = -1.0; r_token = 0; r_speed = 1.0; return; }
	if (!a.clip.is_empty()) { r_clip = a.clip; r_hold = a.hold; r_token = a.token; r_speed = 1.0; return; }
	if (r_clip.is_empty()) { r_clip = IDLE; r_hold = -1.0; r_token = 0; r_speed = 1.0; }
}

void CityCrowd::stay_down(int p_walker, bool p_on) {
	for (Near &nb : near_pool) if (nb.walker == p_walker && nb.ped) nb.ped->set_stay_down(p_on);
	if (p_on) {
		for (const Down &d : downs) if (d.walker == p_walker) return;
		downs.push_back(Down{ p_walker, 0.0 });
	}
}

bool CityCrowd::is_down(int p_walker) const {
	for (const Down &d : downs) if (d.walker == p_walker && !d.treated) return true;
	return false;
}

void CityCrowd::set_cpr(int p_walker, bool p_on) { for (Down &d : downs) if (d.walker == p_walker) d.cpr = p_on; }

void CityCrowd::treat(int p_walker) {
	for (Down &d : downs) if (d.walker == p_walker) { d.treated = true; d.cpr = false; }
	for (Near &nb : near_pool) if (nb.walker == p_walker && nb.ped) nb.ped->set_stay_down(false);
}

Array CityCrowd::downs_list() const {
	Array r;
	for (const Down &d : downs) {
		Dictionary e; e["walker"] = d.walker; e["at"] = walker_at(d.walker); e["t"] = d.t; e["treated"] = d.treated; e["helpers"] = d.helpers;
		r.push_back(e);
	}
	return r;
}

void CityCrowd::incident(const Vector3 &p_at, int p_kind, bool p_by_player, int p_victim, int p_hurt) {
	if (incidents.size() >= 64) incidents.erase(incidents.begin());
	incidents.push_back(Incident{ p_at, p_kind, p_by_player, p_victim, p_hurt, own_clock });
}

Array CityCrowd::take_incidents() {
	Array r;
	for (const Incident &e : incidents) {
		Dictionary d; d["at"] = e.at; d["kind"] = e.kind; d["by_player"] = e.by_player; d["victim"] = e.victim; d["hurt"] = e.hurt; d["t"] = e.t;
		r.push_back(d);
	}
	incidents.clear();
	return r;
}

// Somebody went down: one or two passers-by near it come over (Yasin's list: "others come to help the victim"). The
// first kneels by him, the second stands by and calls on the phone. Only people walking their way, not with others,
// not running from it already.
void CityCrowd::helpers_for(int p_victim, const Vector3 &p_at) {
	if (!crowd) return;
	int got = 0;
	for (Down &d : downs) if (d.walker == p_victim) got = d.helpers;
	if (got >= 2) return;
	struct Cand { float d2; int w; };
	std::vector<Cand> cs;
	for (int j = 0; j < crowd->hi; j++) {
		if (!crowd->alive[j] || crowd->id[j] == p_victim || crowd->mode[j] != pc::M_LINE || crowd->party[j] != 0) continue;
		if (crowd->flags[j] & (pc::F_SCRIPT | pc::F_HIDDEN | pc::F_FLEE)) continue;
		if (crowd->act[j] == pc::A_DUCK || crowd->act[j] == pc::A_FIGHT || crowd->act[j] == pc::A_ARGUE) continue;
		const float dx = crowd->x[j] - p_at.x, dz = crowd->z[j] - p_at.z, d2 = dx * dx + dz * dz;
		if (d2 > 28.0f * 28.0f || d2 < 1.0f) continue;
		if (is_actor(crowd->id[j])) continue;
		cs.push_back(Cand{ d2, crowd->id[j] });
	}
	std::sort(cs.begin(), cs.end(), [](const Cand &a, const Cand &b) { return a.d2 < b.d2; });
	for (const Cand &c : cs) {
		if (got >= 2) break;
		if (!actor_take(c.w, R_HELPER)) continue;
		Actor *a = actor_of(c.w);
		a->helps = p_victim;
		const Vector3 me = walker_at(c.w);
		Vector3 d = me - p_at; d.y = 0.0f;
		const float l = d.length();
		const Vector3 side = l > 0.05f ? d / l : Vector3(1, 0, 0);
		// (the first to the victim's side nearest him; the second a step further, round to the other side)
		const Vector3 spot = got == 0 ? p_at + side * 0.85f : p_at + Vector3(-side.z, 0, side.x) * 1.6f;
		actor_go(c.w, spot, 3.2, 0.25);
		got++; helpers_sent++;
	}
	for (Down &d : downs) if (d.walker == p_victim) d.helpers = got;
}

void CityCrowd::actors_update(double p_delta) {
	if (!crowd) return;
	const float dt = (float)p_delta;
	CityPlayer *pl = player_id ? Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	// the hurt who lie: a medic, or two minutes, or no body any more (he is far: he gets up unseen)
	for (size_t k = 0; k < downs.size();) {
		Down &d = downs[k];
		d.t += p_delta;
		bool has_body = false;
		for (Near &nb : near_pool) if (nb.walker == d.walker && nb.ped && (nb.ped->get_mode() != CityPed::MODE_ANIM || nb.cpr != 0)) { has_body = true; nb.ped->set_stay_down(!d.treated); }   // (lying in the CPR clip is lying too)
		if (d.t > 120.0 && !d.treated) treat(d.walker);
		if (!walker_alive(d.walker) || (!has_body && d.t > 3.0)) { downs.erase(downs.begin() + (long)k); continue; }
		k++;
	}
	for (size_t k = 0; k < actors.size();) {
		Actor &a = actors[k];
		const int i = crowd->find(a.walker);
		if (i < 0) { for (size_t q = 0; q < uniforms.size(); q++) if (uniforms[q].first == a.walker) { uniforms.erase(uniforms.begin() + (long)q); break; } actors.erase(actors.begin() + (long)k); continue; }
		a.t += dt; a.life += dt;
		if (crowd->mode[i] == pc::M_BODY) { k++; continue; }   // (knocked about: his body has him; he is ours again when he is up)
		if (crowd->mode[i] != pc::M_HELD) crowd->hold(a.walker, true, a.face);
		if (a.seated) { crowd->y[i] = crowd->py[i] = a.floor_y; }
		if (a.talking) { crowd->hold(a.walker, true, a.face); k++; continue; }   // (talked to: he stands, or sits, and listens)
		if (a.once_left > 0.0f) {   // a clip played through where he stands; then he is where it left him
			a.once_left -= dt;
			if (a.once_left <= 0.0f) {
				if (a.once_gone) { const int w = a.walker; actors.erase(actors.begin() + (long)k); remove_walker(w); continue; }
				for (const Near &nb : near_pool) if (nb.ped && nb.walker == a.walker) {
					const Vector3 tv = nb.ped->clip_len(a.once) > 0.0 ? (Vector3)Vector3() : Vector3();
					(void)tv;
					const double yl = nb.ped->clip_curve(a.once, "yaw", 1e6, 0.0);
					const Vector3 hips = nb.ped->clip_hips_at(a.once, nb.ped->clip_len(a.once)) - nb.ped->clip_hips_at(a.once, 0.0);
					const Vector3 mv = Basis(Vector3(0, 1, 0), a.face).xform(Vector3(hips.x, 0.0f, hips.z));
					crowd->x[i] = crowd->px[i] = crowd->x[i] + mv.x; crowd->z[i] = crowd->pz[i] = crowd->z[i] + mv.z;
					a.face += (float)yl;
				}
				a.once = StringName();
			}
			crowd->hold(a.walker, true, a.face); k++; continue;
		}
		Vector3 at(crowd->x[i], crowd->y[i], crowd->z[i]);
		Vector3 to = a.to;
		if (a.to_walker == -2 && pl) to = pl->get_global_position();
		else if (a.to_walker >= 0) { if (walker_alive(a.to_walker)) to = walker_at(a.to_walker); else { a.to_walker = -1; a.speed = 0.0f; a.arrived = true; } }
		if (a.speed > 0.0f) {
			Vector3 d = to - at; d.y = 0.0f;
			const float dist = d.length();
			if (a.to_walker != -1 && a.arrived && dist > a.near + 0.8f) a.arrived = false;   // (following: he is off again)
			if (!a.arrived) {
				if (dist <= a.near) a.arrived = true;
				else {
					const float step = std::min(a.speed * dt, dist - a.near * 0.9f);
					crowd->shift_held(i, crowd->x[i] + d.x / dist * step, crowd->z[i] + d.z / dist * step);
					a.face = std::atan2(d.x, d.z);
					crowd->hold(a.walker, true, a.face);
				}
			} else if (dist > 0.05f) { a.face = std::atan2(d.x, d.z); crowd->hold(a.walker, true, a.face); }
		} else if (a.facing) crowd->hold(a.walker, true, a.face);
		// on the road the pavement's height is wrong: the ground under him, now and then
		a.ground_t -= dt;
		if (a.ground_t <= 0.0f && !a.seated) {
			a.ground_t = 0.25f;
			const float gy = ground_y(Vector3(crowd->x[i], crowd->y[i], crowd->z[i]), crowd->y[i]);
			if (std::fabs(gy - crowd->y[i]) < 1.0f) { crowd->y[i] = gy; crowd->py[i] = gy; }
		}
		// THE HELPERS: once by the victim the first kneels, the second calls; up again (or treated, or long enough): off
		if (a.role == R_HELPER) {
			const bool still_down = is_down(a.helps);
			bool by_near = false;
			for (const Near &nb : near_pool) if (nb.walker == a.helps && nb.ped && nb.ped->get_mode() != CityPed::MODE_ANIM) by_near = true;
			if (a.arrived && a.st == 0) {
				const Vector3 v = walker_at(a.helps);
				const float yaw = std::atan2(v.x - crowd->x[i], v.z - crowd->z[i]);
				static const StringName KNEEL("ual/Fixing_Kneeling"), PHONE("ual/Idle_TalkingPhone_Loop");
				int first = 0;
				for (const Actor &o : actors) if (o.role == R_HELPER && o.helps == a.helps && o.st == 1 && o.clip == KNEEL) first++;
				actor_stand(a.walker, yaw, first == 0 ? KNEEL : PHONE, -1.0, 0);
				crowd->act[i] = first == 0 ? pc::A_DUCK : pc::A_CALL;   // (the far figure's pose)
				a.st = 1;
				if (first == 0) helpers_knelt++;
			}
			if ((a.st == 1 && !still_down && !by_near && a.t > 4.0f) || a.life > 70.0f) { actor_release(a.walker); continue; }
		}
		if (a.role == R_DRIVER) {
			if (a.st == 0 && a.t > 1.2f) {   // out: away from the player, shouting
				Vector3 pp = pl ? pl->get_global_position() : at - Vector3(0, 0, 1);
				Vector3 d = at - pp; d.y = 0.0f;
				if (d.length() < 0.1f) d = Vector3(1, 0, 0);
				d.normalize();
				actor_go(a.walker, at + d * 22.0f, 5.0, 0.6);
				alarm(at, 18.0f, 8.0f, 7);
				incident(at, 7, true, a.walker, 0);
				a.st = 1;
			} else if (a.st == 1 && (a.arrived || a.t > 8.0f)) {   // far enough: he calls
				static const StringName PHONE("ual/Idle_TalkingPhone_Loop");
				const Vector3 pp = pl ? pl->get_global_position() : at;
				actor_stand(a.walker, std::atan2(pp.x - at.x, pp.z - at.z), PHONE, -1.0, 0);
				crowd->act[i] = pc::A_CALL;
				a.st = 2;
			} else if (a.st == 2 && a.t > 9.0f) { actor_release(a.walker); continue; }
		}
		if (a.role == R_COWER && a.life > a.near) {   // (gun_aimed: near is how long it lasts) the aim is off him: he runs
			const Vector3 from = a.to;
			actor_release(a.walker);
			crowd->scare(from.x, from.z, from.distance_to(at) + 2.0f, 8.0f);
			continue;
		}
		k++;
	}
}

// A driver whose car the player took (CityTraffic::take_car, not fighting): out of the seat, he runs off 22 m away from
// the player, then stands and calls (the police: CityLaw hears of it as an incident)
void CityCrowd::driver_robbed(int p_walker) {
	if (!actor_take(p_walker, R_DRIVER)) return;
	static const StringName EXIT("ual/Sitting_Exit");
	Actor *a = actor_of(p_walker);
	actor_stand(p_walker, a->face, EXIT, -2.0, 7101);
	a->st = 0;
	drivers_robbed++;
}

bool CityCrowd::knock_down_walker(int p_walker) {
	for (Near &nb : near_pool) {
		if (nb.walker != p_walker || !nb.ped) continue;
		const Vector3 at = nb.ped->body_at();
		const float y = crowd ? crowd->yaw[std::max(crowd->find(p_walker), 0)] : 0.0f;
		const Vector3 back(-std::sin(y), 0.0f, -std::cos(y));
		nb.ped->knock_down(back * 2.5f, back * 40.0f, at + Vector3(0, 1.5f, 0));
		nb.push_cd = 1.0f; nb.why = 4;
		stay_down(p_walker, true);
		incident(at, 2, false, p_walker, 2);
		helpers_for(p_walker, at);
		return true;
	}
	return false;
}

// ---- guns (none yet): what they will tell the people

void CityCrowd::gun_aimed(const Vector3 &p_from, const Vector3 &p_dir, double p_seconds) {
	if (!crowd) return;
	Vector3 dir = p_dir; dir.y = 0.0f;
	if (dir.length() < 0.01f) return;
	dir.normalize();
	for (int j = 0; j < crowd->hi; j++) {
		if (!crowd->alive[j] || (crowd->flags[j] & pc::F_HIDDEN) || crowd->mode[j] == pc::M_BODY) continue;
		const float dx = crowd->x[j] - p_from.x, dz = crowd->z[j] - p_from.z;
		const float along = dx * dir.x + dz * dir.z;
		if (along < 0.5f || along > 25.0f) continue;
		const float side = std::fabs(dx * dir.z - dz * dir.x);
		if (side > 1.0f + 0.06f * along) continue;
		const int w = crowd->id[j];
		if (Actor *a = actor_of(w)) {
			if (a->role == R_COWER) a->near = a->life + (float)p_seconds;   // (still aimed at: it lasts)
			continue;
		}
		if (!actor_take(w, R_COWER)) continue;
		Actor *a = actor_of(w);
		a->to = p_from; a->near = (float)p_seconds;   // (cowering: where the gun is, how long)
		const float yaw = std::atan2(p_from.x - crowd->x[j], p_from.z - crowd->z[j]);
		// hands up (the start of the Surprise clip held where both hands are high) or down in a crouch: one in two
		static const StringName HANDS("x/cower"), CROUCH("ual/Crouch_Idle_Loop");   // (Mixamo's Terrified, 21 Nov)
		const bool up = (crowd->look[j] >> 9) & 1u;
		actor_stand(w, yaw, up ? HANDS : CROUCH, -1.0, 0);
		crowd->act[j] = up ? pc::A_STARE : pc::A_DUCK;
		cowering++;
	}
}

void CityCrowd::gunshot(const Vector3 &p_at, bool p_by_player) {
	if (!crowd) return;
	shots_heard++;
	alarm(p_at, 45.0f, 15.0f, 5);
	incident(p_at, 5, p_by_player, -1, 0);
	CityTraffic *trf = traffic_id ? Object::cast_to<CityTraffic>(ObjectDB::get_instance(ObjectID(traffic_id))) : nullptr;
	if (trf) trf->panic(p_at, 40.0, 12.0);
}
