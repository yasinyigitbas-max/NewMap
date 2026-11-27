// CityLaw (city_law.h says what it does).
#include "city_law.h"

#include "city_car.h"
#include "city_crowd.h"
#include "city_game.h"
#include "city_hud.h"
#include "city_player.h"
#include "city_sfx.h"
#include "city_traffic.h"
#include "car_models.h"
#include "ped_crowd.h"

#include <godot_cpp/classes/audio_stream_player3d.hpp>
#include <godot_cpp/classes/box_mesh.hpp>
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

namespace {
// (27 Nov, wiring the new cars in) the police and the ambulance drive their own models, which carry their own livery
// (the paint colour does not show on them): the patrol car police_e, every other chase unit the police_x, and the
// ambulance. Before: stern_g in dark blue, and the white van.
const int POLICE_MODEL = 12, POLICE_MODEL_B = 13, POLICE_PAINT = 0;
const int AMBULANCE_MODEL = 14, AMBULANCE_PAINT = 0;
const float SEE_CAR = 60.0f, SEE_COP = 40.0f;
float rnd() { return (float)UtilityFunctions::randf(); }
} // namespace

CityLaw::CityLaw() {}
CityLaw::~CityLaw() {}

CityCrowd *CityLaw::crowd() const { return crowd_id ? Object::cast_to<CityCrowd>(ObjectDB::get_instance(ObjectID(crowd_id))) : nullptr; }
CityTraffic *CityLaw::traffic() const { return traffic_id ? Object::cast_to<CityTraffic>(ObjectDB::get_instance(ObjectID(traffic_id))) : nullptr; }
CityPlayer *CityLaw::player() const { return player_id ? Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr; }

void CityLaw::set_world(Object *p_crowd, Object *p_traffic, Object *p_player) {
	crowd_id = p_crowd ? (uint64_t)p_crowd->get_instance_id() : 0;
	traffic_id = p_traffic ? (uint64_t)p_traffic->get_instance_id() : 0;
	player_id = p_player ? (uint64_t)p_player->get_instance_id() : 0;
}

void CityLaw::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) return;
	auto lamp = [](const Color &c, float e) {
		Ref<StandardMaterial3D> m; m.instantiate();
		m->set_shading_mode(BaseMaterial3D::SHADING_MODE_UNSHADED);
		m->set_albedo(c);
		m->set_feature(BaseMaterial3D::FEATURE_EMISSION, true); m->set_emission(c); m->set_emission_energy_multiplier(e);
		return m;
	};
	m_red = lamp(Color(1.0f, 0.06f, 0.05f), 3.0f);
	m_blue = lamp(Color(0.1f, 0.25f, 1.0f), 3.0f);
	m_off = lamp(Color(0.15f, 0.15f, 0.17f), 0.0f);
	set_process(true);
}

void CityLaw::_exit_tree() {
	for (Unit &u : units) unit_free(u);
	units.clear();
}

// where the player is: on foot, or in his car (he is hidden in it)
static Vector3 player_at(CityPlayer *pl, Node *any) {
	if (!pl) return Vector3();
	if (pl->is_visible_in_tree() || !any || !any->get_tree()) return pl->get_global_position();
	const TypedArray<Node> vs = any->get_tree()->get_nodes_in_group("vehicles");
	for (int i = 0; i < vs.size(); i++) if (CityCar *c = Object::cast_to<CityCar>(vs[i])) if (c->get_player()) return c->get_global_position();
	return pl->get_global_position();
}

static bool on_foot(CityPlayer *pl) { return pl && pl->is_visible_in_tree(); }

// ---------------------------------------------------------------- the wanted level

void CityLaw::raise(int p_stars) {
	if (!police_on) return;
	const int was = wanted;
	if (wanted == 0) wanted = std::min(p_stars, 5);
	else if (p_stars > wanted) wanted = std::min(p_stars, 5);
	else if (clock - last_raise > 12.0) wanted = std::min(wanted + 1, 5);
	if (wanted != was) last_raise = clock;
	if (was == 0 && wanted > 0) { CityPlayer *pl = player(); last_seen = player_at(pl, this); unseen_t = 0.0; }
}

void CityLaw::lose() {
	if (wanted > 0) n_lost++;
	wanted = 0; reports.clear();
	for (Unit &u : units) if (u.kind == U_POLICE && u.target == -2 && u.st != S_LEAVE) { u.st = crew_in(u) ? S_LEAVE : S_BACK; u.t = 0.0f; if (u.st == S_BACK) crew_back(u); }
}

void CityLaw::set_wanted(int p_level) {
	const int was = wanted;
	wanted = std::min(std::max(p_level, 0), 5);
	if (wanted == 0 && was > 0) lose();
	if (was == 0 && wanted > 0) { last_seen = player_at(player(), this); unseen_t = 0.0; last_raise = clock; }
}

void CityLaw::report(const Vector3 &p_at, int p_stars, double p_delay) {
	reports.push_back(Report{ p_at, p_stars, clock + p_delay });
}

void CityLaw::call_ambulance(int p_walker) {
	CityCrowd *cr = crowd();
	if (!cr) return;
	calls.push_back(Call{ p_walker, cr->walker_at(p_walker), clock });
}

int CityLaw::police_units() const {
	int n = 0;
	for (const Unit &u : units) if (u.kind == U_POLICE && u.target == -2 && u.st != S_LEAVE) n++;
	return n;
}

// a place on the streets 150-200 m from p_to, behind the camera if it can be (the car is not seen to appear)
Vector3 CityLaw::spawn_from(const Vector3 &p_to) const {
	Vector3 back(0, 0, 1);
	if (Viewport *vp = get_viewport()) if (Camera3D *c = vp->get_camera_3d()) { back = c->get_global_transform().basis.get_column(2); back.y = 0.0f; }
	if (back.length() < 0.1f) back = Vector3(0, 0, 1);
	back.normalize();
	const float a = (rnd() - 0.5f) * 1.6f, d = 150.0f + 50.0f * rnd();
	const Vector3 dir(back.x * std::cos(a) - back.z * std::sin(a), 0.0f, back.x * std::sin(a) + back.z * std::cos(a));
	return p_to + dir * d;
}

// ---------------------------------------------------------------- the units

void CityLaw::unit_make_gfx(Unit &u) {
	if (!u.siren) {
		u.siren = memnew(AudioStreamPlayer3D);
		u.siren->set_unit_size(10.0); u.siren->set_max_distance(260.0); u.siren->set_volume_db(-2.0);
		add_child(u.siren);
	}
	if (!u.bar) {
		u.bar = memnew(MeshInstance3D);
		Ref<BoxMesh> bm; bm.instantiate();
		bm->set_size(Vector3(1.0f, 0.12f, 0.22f));
		u.bar->set_mesh(bm);
		u.bar->set_cast_shadows_setting(GeometryInstance3D::SHADOW_CASTING_SETTING_OFF);
		// (two halves: the bar is one box drawn twice, each half its colour)
		MeshInstance3D *half = memnew(MeshInstance3D);
		Ref<BoxMesh> hm; hm.instantiate(); hm->set_size(Vector3(0.48f, 0.13f, 0.23f));
		half->set_mesh(hm); half->set_position(Vector3(-0.26f, 0, 0)); half->set_name("L");
		half->set_cast_shadows_setting(GeometryInstance3D::SHADOW_CASTING_SETTING_OFF);
		MeshInstance3D *half2 = memnew(MeshInstance3D);
		half2->set_mesh(hm); half2->set_position(Vector3(0.26f, 0, 0)); half2->set_name("R");
		half2->set_cast_shadows_setting(GeometryInstance3D::SHADOW_CASTING_SETTING_OFF);
		u.bar->add_child(half); u.bar->add_child(half2);
		u.bar->set_material_override(m_off);
		add_child(u.bar);
		u.bar->set_visible(false);
	}
}

void CityLaw::unit_free(Unit &u) {
	if (u.siren) { u.siren->queue_free(); u.siren = nullptr; }
	if (u.bar) { u.bar->queue_free(); u.bar = nullptr; }
	CityCrowd *cr = crowd();
	for (int k = 0; k < 2; k++) if (u.crew[k] >= 0) { if (cr) cr->actor_release(u.crew[k]); u.crew[k] = -1; }
}

bool CityLaw::crew_in(const Unit &u) const { return u.crew[0] < 0 && u.crew[1] < 0; }

// the crew out at their doors: officers or paramedics, as actors in their clothes
void CityLaw::crew_out(Unit &u) {
	CityCrowd *cr = crowd();
	if (!cr || !u.has_pose) return;
	const cm::CarModel &m = cm::MODELS[u.model];
	const Vector3 f(std::sin(u.yaw), 0.0f, std::cos(u.yaw)), side(f.z, 0.0f, -f.x);
	for (int k = 0; k < 2; k++) {
		if (u.crew[k] >= 0) continue;
		const float sx = k == 0 ? 1.0f : -1.0f;   // the driver's side, the other
		const Vector3 at = u.at + side * (sx * (m.half_w + 0.55f)) + f * (m.half_len * 0.12f);
		u.crew[k] = cr->actor_place(at, u.kind == U_POLICE ? 2 : 3, std::atan2(side.x * sx, side.z * sx), u.kind == U_POLICE ? CityCrowd::R_COP : CityCrowd::R_MEDIC);
		if (u.crew[k] >= 0) n_out++;
		// (Yasin, 21 Nov: "make sure every npc use car get in get out too") out of the car: Mixamo's Exiting_Car, seated
		// facing the way the car faces, turning out through the door as he stands
		static const StringName OUT("x/car_out");
		if (u.crew[k] >= 0) cr->actor_once(u.crew[k], u.yaw, OUT, false);
	}
}

// the crew back to their doors (and in: let go, they are gone)
void CityLaw::crew_back(Unit &u) {
	CityCrowd *cr = crowd();
	if (!cr) return;
	const cm::CarModel &m = cm::MODELS[u.model];
	const Vector3 f(std::sin(u.yaw), 0.0f, std::cos(u.yaw)), side(f.z, 0.0f, -f.x);
	for (int k = 0; k < 2; k++) {
		if (u.crew[k] < 0) continue;
		const float sx = k == 0 ? 1.0f : -1.0f;
		cr->actor_go(u.crew[k], u.at + side * (sx * (m.half_w + 0.55f)), 4.2, 0.5);
	}
}

void CityLaw::unit_update(Unit &u, double p_delta) {
	const float dt = (float)p_delta;
	u.t += dt; u.life += dt; u.order_cd -= dt;
	CityTraffic *tr = traffic();
	CityCrowd *cr = crowd();
	CityPlayer *pl = player();
	if (!tr || !cr) return;
	if (u.st == S_ORDERED) {   // the traffic answers the spawn
		const int r = tr->order_result(u.ticket);
		if (r == -9) return;
		if (r < 0) {   // (no route or no room where it was asked: again from another place, five times)
			n_refused++;
			if (++u.tries > 5) { u.st = S_DONE; return; }
			const Vector3 to = u.kind == U_POLICE && u.target == -2 ? last_seen : (u.target >= 0 && cr->walker_alive(u.target) ? cr->walker_at(u.target) : u.goal);
			u.ticket = tr->spawn_driver(spawn_from(to), to, u.model, u.kind == U_POLICE ? POLICE_PAINT : AMBULANCE_PAINT);
			return;
		}
		u.car = r; u.st = S_DRIVE; u.t = 0.0f; u.order_cd = 2.0f;
		unit_make_gfx(u);
		return;
	}
	if (u.car >= 0) {
		Vector3 a; float yaw = 0.0f, v = 0.0f;
		u.has_pose = tr->car_pose(u.car, a, yaw, v);
		if (u.has_pose) { u.at = a; u.yaw = yaw; u.v = v; }
		else if (u.st != S_DONE) { u.st = S_DONE; return; }   // (the traffic took it away)
	}
	// where it goes: the player (where last seen, or where he is when they see him), the mugger, the hurt
	Vector3 goal = u.goal;
	if (u.kind == U_POLICE) {
		if (u.target == -2) goal = seen ? player_at(pl, this) : last_seen;
		else if (cr->walker_alive(u.target)) goal = cr->walker_at(u.target);
	}
	const float dist = Vector2(u.at.x - goal.x, u.at.z - goal.z).length();
	switch (u.st) {
		case S_DRIVE: {
			if (u.order_cd <= 0.0f) { tr->drive_car_to(u.car, goal); u.order_cd = 2.5f; }
			const bool foot_goal = u.kind == U_AMBULANCE || u.target >= 0 || on_foot(pl);
			if (dist < (u.kind == U_AMBULANCE ? 20.0f : 24.0f) && foot_goal) {
				tr->pull_car_over(u.car, goal, 0);
				u.st = S_STOP; u.t = 0.0f;
			}
			u.stuck_t = u.v < 0.5f ? u.stuck_t + dt : 0.0f;
			if (u.stuck_t > 6.0f && dist < 90.0f && foot_goal) { u.st = S_STOP; u.t = 0.0f; }   // (in a jam near him: they get out there)
		} break;
		case S_STOP: {
			if (u.v < 0.4f || u.t > 5.0f) {
				crew_out(u);
				u.st = u.kind == U_POLICE ? S_FOOT : S_TREAT; u.t = 0.0f;
				if (u.kind == U_AMBULANCE) for (int k = 0; k < 2; k++) if (u.crew[k] >= 0) cr->actor_go(u.crew[k], goal + Vector3(k == 0 ? 0.8f : -0.8f, 0, 0.3f), 3.6, 0.3);
			}
		} break;
		case S_FOOT: {   // the officers after him on foot
			bool any = false;
			for (int k = 0; k < 2; k++) {
				const int c = u.crew[k];
				if (c < 0 || !cr->walker_alive(c)) { u.crew[k] = -1; continue; }
				any = true;
				if (u.target == -2) {
					if (!on_foot(pl)) continue;
					// (Yasin, 21 Nov: "once they find us they should keep a gun at us") the second officer covers him from a few
					// metres, turned to him, his gun on him; the first runs him down
					{
						const Vector3 cq = cr->walker_at(c), pq = pl->get_global_position();
						const float dq = Vector2(cq.x - pq.x, cq.z - pq.z).length();
						if (k == 1 && dq < 9.0f) { static const StringName AIM("x/police_aim"); cr->actor_stand(c, std::atan2(pq.x - cq.x, pq.z - cq.z), AIM, -1.0, 0); continue; }
					}
					cr->actor_follow(c, -2, 5.4, 1.0);
					const Vector3 cp = cr->walker_at(c), pp = pl->get_global_position();
					if (Vector2(cp.x - pp.x, cp.z - pp.z).length() < 1.35f && busted_t < 0.0) {   // BUSTED
						busted_t = 0.0; n_busted++;
						pl->set_frozen(true);
						CityGame *g = CityGame::get();
						if (g) { const int fine = std::min(g->get_money(), 50 * std::max(wanted, 1)); if (fine > 0) g->add_money(-fine); }
						if (g) if (CityHud *h = Object::cast_to<CityHud>(g->get_hud())) h->note("BUSTED", String::utf8("YAKALANDIN"), 3.5);
						wanted = 0; reports.clear();
					}
				} else if (cr->walker_alive(u.target)) {   // a mugger: run him down, then he gives up
					cr->actor_follow(c, u.target, 5.6, 1.0);
					const Vector3 cp = cr->walker_at(c), mp = cr->walker_at(u.target);
					if (k == 0 && Vector2(cp.x - mp.x, cp.z - mp.z).length() < 1.3f) {
						static const StringName CROUCH("x/kneel_caught"), POINT("x/police_aim");   // (he kneels; they aim at him: Mixamo, 21 Nov)
						if (!cr->is_actor(u.target)) cr->actor_take(u.target, CityCrowd::R_MUGGER);
						cr->actor_stand(u.target, std::atan2(cp.x - mp.x, cp.z - mp.z), CROUCH, -1.0, 0);
						for (int q = 0; q < 2; q++) if (u.crew[q] >= 0) cr->actor_stand(u.crew[q], std::atan2(mp.x - cp.x, mp.z - cp.z), POINT, -1.0, 0);
						for (Mug &m : mugs) if (m.mugger == u.target) m.st = 9;   // (caught: his part is the law's now)
						u.goal = mp; u.target = -3; u.t = 0.0f; n_mug_caught++;
					}
				}
			}
			if (u.target == -3 && u.t > 5.0f) {   // the mugger taken away; the officers back to their car
				for (Mug &m : mugs) if (m.st == 9 && cr->walker_alive(m.mugger)) { cr->actor_release(m.mugger); cr->remove_walker(m.mugger); m.st = 10; }
				u.st = S_BACK; u.t = 0.0f; crew_back(u);
			}
			if (!any) { u.st = S_LEAVE; u.t = 0.0f; break; }
			if (u.target == -2 && (wanted == 0 || !on_foot(pl))) {   // he got away in a car (or it is over): back to the car
				if (busted_t < 0.0 || busted_t > 3.0) { u.st = S_BACK; u.t = 0.0f; crew_back(u); }
			} else if (u.target == -2 && pl && dist > 70.0f) { u.st = S_BACK; u.t = 0.0f; crew_back(u); }
		} break;
		case S_BACK: {   // to their doors, then in: on after him, or away
			bool all = true;
			for (int k = 0; k < 2; k++) {
				if (u.crew[k] < 0) continue;
				// at his door: in (Mixamo's Entering_Car), then he is gone
				if (cr->walker_alive(u.crew[k]) && cr->actor_arrived(u.crew[k]) && u.t <= 15.0f) { static const StringName IN("x/car_in"); cr->actor_once(u.crew[k], u.yaw + 3.14159265, IN, true); u.crew[k] = -1; }
				else if (!cr->walker_alive(u.crew[k]) || u.t > 15.0f) { cr->actor_release(u.crew[k]); u.crew[k] = -1; }
				else all = false;
			}
			if (all) {
				u.t = 0.0f;
				if (u.kind == U_POLICE && u.target == -2 && wanted > 0 && police_units() <= std::min(wanted, 4)) { u.st = S_DRIVE; u.order_cd = 0.0f; tr->drive_car_to(u.car, goal); }
				else u.st = S_LEAVE;
			}
		} break;
		case S_TREAT: {   // the paramedics by the hurt one: they kneel; after 8 s he is treated and gets up
			const bool down = cr->is_down(u.target);
			if (!down && u.t < 1.0f) { u.st = S_BACK; crew_back(u); break; }   // (up already, or gone)
			const Vector3 vp = cr->walker_at(u.target);
			bool there = true;
			for (int k = 0; k < 2; k++) {
				const int c = u.crew[k];
				if (c < 0) continue;
				if (cr->actor_arrived(c) && cr->actor_role(c) == CityCrowd::R_MEDIC) {
					const Vector3 cp = cr->walker_at(c);
					// (Yasin, 21 Nov: "paramedic should do cpr") the first gives CPR, the second kneels by him
					static const StringName CPR("x/cpr_give"), KNEEL("ual/Fixing_Kneeling");
					if (u.goal.y > -9000.0f) cr->actor_stand(c, std::atan2(vp.x - cp.x, vp.z - cp.z), k == 0 ? CPR : KNEEL, -1.0, 0);
				} else if (!cr->actor_arrived(c)) there = false;
			}
			if (there && u.goal.y > -9000.0f) { u.goal.y = -9999.0f; u.t = 0.0f; cr->set_cpr(u.target, true); }   // (all knelt: the clock starts; he takes the CPR)
			if (u.goal.y <= -9000.0f && u.t > 8.0f) {
				cr->treat(u.target); n_treated++;
				u.st = S_BACK; u.t = 0.0f; crew_back(u);
			}
			if (u.t > 40.0f) { u.st = S_BACK; u.t = 0.0f; crew_back(u); }
		} break;
		case S_LEAVE: {
			for (int k = 0; k < 2; k++) if (u.crew[k] >= 0) { cr->actor_release(u.crew[k]); u.crew[k] = -1; }
			if (u.car >= 0) tr->let_car_go(u.car);
			u.st = S_DONE;
		} break;
		default: break;
	}
	// the lights and the siren: on while it is sent somewhere and while its crew is out (police); off when it leaves
	const bool lit = u.st != S_LEAVE && u.st != S_DONE && u.has_pose;
	if (u.bar) {
		u.bar->set_visible(lit);
		if (lit) {
			const cm::CarModel &m = cm::MODELS[u.model];
			u.bar->set_global_transform(Transform3D(Basis(Vector3(0, 1, 0), u.yaw), u.at + Vector3(0, m.height + 0.05f, 0) + Vector3(std::sin(u.yaw), 0, std::cos(u.yaw)) * (u.kind == U_AMBULANCE ? m.half_len * 0.35f : -0.1f)));
			const bool ph = std::fmod(u.life, 0.5f) < 0.25f;
			if (MeshInstance3D *l = Object::cast_to<MeshInstance3D>(u.bar->get_node_or_null("L"))) l->set_material_override(ph ? m_red : m_off);
			if (MeshInstance3D *r = Object::cast_to<MeshInstance3D>(u.bar->get_node_or_null("R"))) r->set_material_override(ph ? m_off : (u.kind == U_AMBULANCE ? m_red : m_blue));
		}
	}
	if (u.siren) {
		int want = -1;
		if (lit && (u.st == S_DRIVE || u.st == S_STOP)) {
			if (u.kind == U_AMBULANCE) want = 2;
			else want = (pl && Vector2(u.at.x - player_at(pl, this).x, u.at.z - player_at(pl, this).z).length() < 60.0f) ? 1 : 0;
		}
		if (want != u.siren_kind) {
			u.siren_kind = want;
			if (want < 0) u.siren->stop();
			else {
				static const char *const NAMES[3] = { "siren_police.wav", "siren_yelp.wav", "siren_ambulance.wav" };
				u.siren->set_stream(city_sfx(NAMES[want], true));
				if (u.siren->get_stream().is_valid()) u.siren->play();
			}
		}
		if (u.has_pose) u.siren->set_global_position(u.at + Vector3(0, 1.2f, 0));
	}
}

// ---------------------------------------------------------------- the muggings

void CityLaw::mug_now() { mug_next = clock; }

void CityLaw::mug_start() {
	CityCrowd *cr = crowd();
	CityPlayer *pl = player();
	if (!cr || !pl || !cr->brain()) return;
	pc::Crowd *b = cr->brain();
	const Vector3 pp = pl->get_global_position();
	// the victim: somebody walking alone 12-45 m from the player; the mugger: a man walking alone within 25 m of him
	int victim = -1, mugger = -1;
	for (int pass = 0; pass < 2 && victim < 0; pass++) {
		for (int i = 0; i < b->hi; i++) {
			if (!b->alive[i] || b->mode[i] != pc::M_LINE || b->party[i] != 0 || (b->flags[i] & (pc::F_SCRIPT | pc::F_HIDDEN | pc::F_FLEE)) || b->act[i] != pc::A_NONE) continue;
			const float d = Vector2(b->x[i] - pp.x, b->z[i] - pp.z).length();
			if (d < 12.0f || d > (pass == 0 ? 45.0f : 90.0f) || cr->is_actor(b->id[i])) continue;
			for (int j = 0; j < b->hi; j++) {
				if (j == i || !b->alive[j] || b->mode[j] != pc::M_LINE || b->party[j] != 0 || (b->flags[j] & (pc::F_SCRIPT | pc::F_HIDDEN | pc::F_FLEE))) continue;
				if (((b->look[j] >> 3) & 1u) != 0u || cr->is_actor(b->id[j])) continue;
				const float dd = Vector2(b->x[j] - b->x[i], b->z[j] - b->z[i]).length();
				if (dd < 3.0f || dd > 25.0f) continue;
				victim = b->id[i]; mugger = b->id[j]; break;
			}
			if (victim >= 0) break;
		}
	}
	if (victim < 0) return;
	if (!cr->actor_take(victim, CityCrowd::R_VICTIM) || !cr->actor_take(mugger, CityCrowd::R_MUGGER)) { cr->actor_release(victim); cr->actor_release(mugger); return; }
	Mug m; m.mugger = mugger; m.victim = victim; m.st = 0; m.at = cr->walker_at(victim);
	cr->actor_follow(mugger, victim, 1.7, 0.85);
	static const StringName IDLE("ual/Idle_Loop");
	const Vector3 mp = cr->walker_at(mugger);
	cr->actor_stand(victim, std::atan2(mp.x - m.at.x, mp.z - m.at.z), IDLE, -1.0, 0);
	mugs.push_back(m);
	n_mugs++;
}

void CityLaw::mug_update(Mug &m, double p_delta) {
	CityCrowd *cr = crowd();
	if (!cr) { m.st = 10; return; }
	m.t += (float)p_delta;
	if (!cr->walker_alive(m.victim) || (m.st < 9 && !cr->walker_alive(m.mugger))) { if (cr->walker_alive(m.victim)) cr->actor_release(m.victim); if (cr->walker_alive(m.mugger)) cr->actor_release(m.mugger); m.st = 10; return; }
	const Vector3 vp = cr->walker_at(m.victim), mp = cr->walker_at(m.mugger);
	static const StringName THREAT("ual/Counter_Angry"), GIVE("ual/Counter_Give"), PHONE("ual/Idle_TalkingPhone_Loop");
	switch (m.st) {
		case 0:   // he walks up to him
			if (cr->actor_arrived(m.mugger) || m.t > 25.0f) {
				cr->actor_stand(m.mugger, std::atan2(vp.x - mp.x, vp.z - mp.z), THREAT, -2.0, 7201);
				cr->actor_stand(m.victim, std::atan2(mp.x - vp.x, mp.z - vp.z), GIVE, -2.0, 7202);
				m.st = 1; m.t = 0.0f;
			}
			break;
		case 1:   // the threat, the hand-over; then he runs
			if (m.t > 2.6f) {
				Vector3 away = mp - vp; away.y = 0.0f;
				CityPlayer *pl = player();
				if (pl) { Vector3 fp = mp - pl->get_global_position(); fp.y = 0.0f; if (fp.length() > 0.1f) away = away.normalized() + fp.normalized(); }
				if (away.length() < 0.1f) away = Vector3(1, 0, 0);
				away.normalize();
				cr->actor_go(m.mugger, mp + away * 40.0f, 5.6, 0.8);
				cr->alarm(vp, 20.0f, 8.0f, 6);
				cr->incident(vp, 6, false, m.victim, 0);
				cr->actor_stand(m.victim, std::atan2(mp.x - vp.x, mp.z - vp.z), PHONE, -1.0, 0);
				m.st = 2; m.t = 0.0f;
			}
			break;
		case 2:   // gone round the corner: he walks on as anybody (unless the law has him); the victim calls a while
			if (m.t > 10.0f && cr->is_actor(m.victim)) cr->actor_release(m.victim);
			if (cr->actor_arrived(m.mugger) || m.t > 12.0f) {
				bool chased = false;
				for (const Unit &u : units) if (u.target == m.mugger) chased = true;
				if (!chased) { cr->actor_release(m.mugger); if (!cr->is_actor(m.victim)) m.st = 10; else m.st = 3; }
				else if (cr->is_actor(m.mugger)) cr->actor_release(m.mugger);   // (walking now: the officer runs him down)
			}
			break;
		case 3:
			if (m.t > 10.0f) { if (cr->is_actor(m.victim)) cr->actor_release(m.victim); m.st = 10; }
			break;
		default: break;
	}
}

// ---------------------------------------------------------------- every frame

// POLICE ON FOOT (Yasin, 21 Nov: "make the police patrol the streets too, not very many of them, but once they find us
// they should keep a gun at us"): at most two officers walk the pavements near him (placed 60-90 m off, walking from one
// pavement spot to another near him, gone once he is far). Wanted and seen within 9 m: the officer stands and keeps his
// gun on him (Mixamo's Pistol_Idle; the gun itself comes with the props), turned to him as he moves; wanted and seen
// further off: he goes after him.
void CityLaw::patrol_update(double p_delta) {
	CityCrowd *cr = crowd();
	CityPlayer *pl = player();
	if (!cr || !pl || !police_on) return;
	const Vector3 pp = player_at(pl, this);
	patrol_next -= p_delta;
	for (size_t k = 0; k < patrols.size();) {
		Patrol &pt = patrols[k];
		pt.t += (float)p_delta;
		if (!cr->walker_alive(pt.walker)) { patrols.erase(patrols.begin() + (long)k); continue; }
		const Vector3 cp = cr->walker_at(pt.walker);
		const float d = Vector2(cp.x - pp.x, cp.z - pp.z).length();
		if (d > 160.0f) { cr->actor_release(pt.walker); cr->remove_walker(pt.walker); patrols.erase(patrols.begin() + (long)k); continue; }
		if (wanted > 0 && on_foot(pl) && d < 9.0f) {
			static const StringName AIM("x/police_aim");
			cr->actor_stand(pt.walker, std::atan2(pp.x - cp.x, pp.z - cp.z), AIM, -1.0, 0);
			pt.aiming = true; n_aims++;
		} else if (wanted > 0 && on_foot(pl) && d < SEE_COP) {
			cr->actor_follow(pt.walker, -2, 4.2, 6.0); pt.aiming = false;
		} else if (pt.aiming || cr->actor_arrived(pt.walker) || pt.t > 40.0f) {
			// his beat: another pavement spot near the player
			const float a = (float)std::fmod(clock * 1.7 + (double)pt.walker * 0.37, 6.2831853);
			const Dictionary pv = cr->pavement_near(pp + Vector3(std::cos(a), 0.0f, std::sin(a)) * 35.0f, 40.0);
			if ((bool)pv.get("ok", false)) cr->actor_go(pt.walker, (Vector3)pv["at"], 1.2, 1.0);
			pt.aiming = false; pt.t = 0.0f;
		}
		k++;
	}
	if (patrols.size() < 2 && patrol_next <= 0.0) {
		patrol_next = 25.0;
		const float a = (float)std::fmod(clock * 2.3, 6.2831853);
		const Dictionary pv = cr->pavement_near(pp + Vector3(std::cos(a), 0.0f, std::sin(a)) * 75.0f, 30.0);
		if ((bool)pv.get("ok", false)) {
			const int w = cr->actor_place((Vector3)pv["at"], 2, (double)pv.get("yaw", 0.0), CityCrowd::R_COP);
			if (w >= 0) { Patrol pt; pt.walker = w; patrols.push_back(pt); n_patrols++; cr->actor_go(w, pp, 1.2, 8.0); }
		}
	}
}

void CityLaw::_process(double p_delta) {
	CityCrowd *cr = crowd();
	CityTraffic *tr = traffic();
	CityPlayer *pl = player();
	if (!cr || !tr || !pl) return;
	clock += p_delta;
	const Vector3 pp = player_at(pl, this);
	patrol_update(p_delta);
	// what happened
	std::vector<CityCrowd::Incident> &inc = cr->incidents_raw();
	for (const CityCrowd::Incident &e : inc) {
		if (e.hurt >= 2 && e.victim >= 0 && ambulance_on) calls.push_back(Call{ e.victim, e.at, clock + 10.0 });
		if (e.kind == 6 && police_on) {   // a mugging: a car for the mugger
			for (Mug &m : mugs) if (m.victim == e.victim && m.mugger >= 0) {
				Unit u; u.kind = U_POLICE; u.target = m.mugger; u.model = POLICE_MODEL; u.goal = e.at;
				u.ticket = tr->spawn_driver(spawn_from(e.at), e.at, POLICE_MODEL, POLICE_PAINT);
				units.push_back(u); n_cars++;
			}
		}
		if (!e.by_player) continue;
		int stars = 1;
		if (e.kind == 2 && e.hurt >= 2) stars = 2;
		if (e.kind == 5) stars = 2;
		if (e.victim >= 0 && cr->actor_role(e.victim) == CityCrowd::R_COP) stars++;
		// known at once with the police near; else a witness calls (if there is one)
		bool near = false;
		for (const Unit &u : units) {
			if (u.kind != U_POLICE) continue;
			if (u.has_pose && u.at.distance_to(e.at) < SEE_CAR) near = true;
			for (int k = 0; k < 2; k++) if (u.crew[k] >= 0 && cr->walker_at(u.crew[k]).distance_to(e.at) < SEE_COP) near = true;
		}
		const int witnesses = cr->people_near(e.at, 35.0).size();
		if (near) reports.push_back(Report{ e.at, stars, clock });
		else if (witnesses > 1) reports.push_back(Report{ e.at, stars, clock + 7.0 });
	}
	inc.clear();
	for (size_t k = 0; k < reports.size();) {
		if (reports[k].due <= clock) { raise(reports[k].stars); n_reports++; reports.erase(reports.begin() + (long)k); continue; }
		k++;
	}
	// seen?
	seen = false;
	if (wanted > 0) {
		for (const Unit &u : units) {
			if (u.kind != U_POLICE || u.target != -2) continue;
			if (u.has_pose && Vector2(u.at.x - pp.x, u.at.z - pp.z).length() < SEE_CAR) seen = true;
			for (int k = 0; k < 2; k++) if (u.crew[k] >= 0 && Vector2(cr->walker_at(u.crew[k]).x - pp.x, cr->walker_at(u.crew[k]).z - pp.z).length() < SEE_COP) seen = true;
		}
		for (const Patrol &pt : patrols) if (cr->walker_alive(pt.walker) && Vector2(cr->walker_at(pt.walker).x - pp.x, cr->walker_at(pt.walker).z - pp.z).length() < SEE_COP) seen = true;
		if (seen || clock - last_raise < 2.0) { last_seen = pp; unseen_t = 0.0; }
		else unseen_t += p_delta;
		if (unseen_t > 12.0 + 6.0 * wanted && Vector2(pp.x - last_seen.x, pp.z - last_seen.z).length() > 60.0f) lose();
	}
	// BUSTED: held a moment, then free
	if (busted_t >= 0.0) {
		busted_t += p_delta;
		if (busted_t > 3.5) { pl->set_frozen(false); busted_t = -1.0; lose(); }
	}
	// the cars after him: as many as the stars, four at most
	if (wanted > 0 && police_on) {
		int have = police_units();
		while (have < std::min(wanted, 4)) {
			Unit u; u.kind = U_POLICE; u.target = -2; u.model = (police_units() & 1) ? POLICE_MODEL_B : POLICE_MODEL; u.goal = last_seen;
			u.ticket = tr->spawn_driver(spawn_from(last_seen), last_seen, u.model, POLICE_PAINT);
			units.push_back(u); have++; n_cars++;
		}
	}
	// the ambulances
	for (Call &c : calls) {
		if (c.sent || c.due > clock) continue;
		c.sent = true;
		if (!cr->is_down(c.victim)) continue;
		Unit u; u.kind = U_AMBULANCE; u.target = c.victim; u.model = AMBULANCE_MODEL; u.goal = c.at;
		u.ticket = tr->spawn_driver(spawn_from(c.at), c.at, AMBULANCE_MODEL, AMBULANCE_PAINT);
		units.push_back(u); n_ambulances++;
	}
	calls.erase(std::remove_if(calls.begin(), calls.end(), [](const Call &c) { return c.sent; }), calls.end());
	// the muggings
	if (crimes_on && on_foot(pl) && clock >= mug_next && mugs.size() < 2) { mug_start(); mug_next = clock + mug_every * (0.8 + 0.4 * rnd()); }
	for (Mug &m : mugs) if (m.st < 9 || m.st == 9) mug_update(m, p_delta);
	mugs.erase(std::remove_if(mugs.begin(), mugs.end(), [](const Mug &m) { return m.st >= 10; }), mugs.end());
	// the units
	for (Unit &u : units) unit_update(u, p_delta);
	for (size_t k = 0; k < units.size();) {
		if (units[k].st == S_DONE) { unit_free(units[k]); units.erase(units.begin() + (long)k); continue; }
		k++;
	}
	// the HUD
	if (CityGame *g = CityGame::get()) if (CityHud *h = Object::cast_to<CityHud>(g->get_hud())) h->set_wanted(wanted, seen);
}

Array CityLaw::units_info() const {
	Array r;
	static const char *const ST[8] = { "ordered", "drive", "stop", "foot", "back", "leave", "treat", "done" };
	for (const Unit &u : units) {
		Dictionary d;
		d["kind"] = u.kind == U_POLICE ? "police" : "ambulance"; d["state"] = ST[u.st]; d["car"] = u.car; d["at"] = u.at; d["speed"] = u.v;
		d["target"] = u.target; d["crew"] = Array::make(u.crew[0], u.crew[1]); d["siren"] = u.siren_kind; d["lit"] = u.bar && u.bar->is_visible(); d["t"] = u.t;
		r.push_back(d);
	}
	return r;
}

Dictionary CityLaw::stats() const {
	Dictionary d;
	d["wanted"] = wanted; d["seen"] = seen; d["unseen_s"] = unseen_t; d["reports"] = n_reports; d["pending"] = (int)reports.size();
	d["police_cars"] = n_cars; d["officers_out"] = n_out; d["busted"] = n_busted; d["lost"] = n_lost; d["refused"] = n_refused;
	d["ambulances"] = n_ambulances; d["treated"] = n_treated; d["muggings"] = n_mugs; d["muggers_caught"] = n_mug_caught; d["units"] = (int)units.size();
	return d;
}

void CityLaw::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_world", "crowd", "traffic", "player"), &CityLaw::set_world);
	ClassDB::bind_method(D_METHOD("get_wanted"), &CityLaw::get_wanted);
	ClassDB::bind_method(D_METHOD("set_wanted", "level"), &CityLaw::set_wanted);
	ClassDB::bind_method(D_METHOD("get_seen"), &CityLaw::get_seen);
	ClassDB::bind_method(D_METHOD("report", "at", "stars", "delay"), &CityLaw::report);
	ClassDB::bind_method(D_METHOD("call_ambulance", "walker"), &CityLaw::call_ambulance);
	ClassDB::bind_method(D_METHOD("mug_now"), &CityLaw::mug_now);
	ClassDB::bind_method(D_METHOD("set_police", "on"), &CityLaw::set_police);
	ClassDB::bind_method(D_METHOD("get_police"), &CityLaw::get_police);
	ClassDB::bind_method(D_METHOD("set_ambulance", "on"), &CityLaw::set_ambulance);
	ClassDB::bind_method(D_METHOD("get_ambulance"), &CityLaw::get_ambulance);
	ClassDB::bind_method(D_METHOD("set_crimes", "on"), &CityLaw::set_crimes);
	ClassDB::bind_method(D_METHOD("get_crimes"), &CityLaw::get_crimes);
	ClassDB::bind_method(D_METHOD("set_mug_every", "seconds"), &CityLaw::set_mug_every);
	ClassDB::bind_method(D_METHOD("get_mug_every"), &CityLaw::get_mug_every);
	ClassDB::bind_method(D_METHOD("units_info"), &CityLaw::units_info);
	ClassDB::bind_method(D_METHOD("stats"), &CityLaw::stats);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "police"), "set_police", "get_police");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "ambulance"), "set_ambulance", "get_ambulance");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "crimes"), "set_crimes", "get_crimes");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "mug_every"), "set_mug_every", "get_mug_every");
}
