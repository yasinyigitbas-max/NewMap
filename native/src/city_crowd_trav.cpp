// THE NEW PEOPLE (28 Nov, Yasin: "i need the new npcs in", "make all of them replace the old ones"). A first, crippled
// step, said so to him: every NEAR figure of the crowd (the pool of real skeletons, near_max) is drawn as one of the new
// bodies (assets/people/meshy, res://traversal/npc/) on the traversal system: a TravBody with its NPC character and its
// moves, which WALKS AFTER the place the crowd's brain gives its walker (the old figure is still driven there, not
// drawn). What the old figure does beyond walking and standing (sitting, a phone, a fight, lying) is NOT shown on the new
// body yet; while the old figure's own physical body has it (shoved, knocked down) the old figure is drawn. The far
// figures (one MultiMesh of baked poses) are still the old bodies.
// Every number here is mine, none is the study's.
#ifdef TRAV_IN_GAME
#include "city_crowd.h"
#include "city_ped.h"
#include "trav_mirror.h"
#include "trav_probe.h"
#include "ped_crowd.h"
#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/class_db_singleton.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/classes/skeleton_modifier3d.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <cmath>

using namespace godot;

void CityTravTape::_bind_methods() {
	ClassDB::bind_method(D_METHOD("sample"), &CityTravTape::sample);
}

void CityCrowd::set_trav_people(bool p_on) {
	if (p_on == trav_people) return;
	ClassDBSingleton *db = ClassDBSingleton::get_singleton();
	if (p_on && !(db->class_exists("TravBody") && db->class_exists("TravNpcCharacter"))) return;
	trav_people = p_on;
	if (!p_on) {
		for (TravNb &t : trav_pool) { if (t.body) t.body->queue_free(); if (t.tape) t.tape->queue_free(); if (t.seat) t.seat->queue_free(); }
		trav_seat_busy = -1;
		trav_pool.clear();
		for (Near &nb : near_pool) if (nb.ped) nb.ped->set_drawn(true);
	}
}

// one new body for pool place k, made the first time it is needed (a body is 1 to 2 MB of mesh and picture: not all at once)
void CityCrowd::trav_make(int k) {
	if ((int)trav_pool.size() <= k) trav_pool.resize((size_t)k + 1);
	TravNb &t = trav_pool[(size_t)k];
	if (t.body || t.failed) return;
	ResourceLoader *rl = ResourceLoader::get_singleton();
	if (trav_ids.empty()) {
		for (int n = 1; n <= 60; n++) {
			const String id = String("npc_") + String::num_int64(n).pad_zeros(2);
			if (rl->exists(String("res://traversal/npc/") + id + String(".scn"))) trav_ids.push_back(id);
		}
	}
	if (trav_ids.empty()) { t.failed = true; return; }
	ClassDBSingleton *db = ClassDBSingleton::get_singleton();
	t.body = Object::cast_to<CharacterBody3D>((Object *)db->instantiate("TravBody"));
	if (!t.body) { t.failed = true; return; }
	t.tape = memnew(CityTravTape);
	add_child(t.tape);
	t.body->set("tape", t.tape);
	t.body->set_name(String("TravNpc") + String::num_int64(k));
	// (no layer: the crowd's own capsules round the player stand for these people; the world only, so that two of them
	// or a parked car do not jam one that is led along a line)
	t.body->set_collision_layer(0);
	t.body->set_collision_mask(1);
	const char *parts[4][2] = { { "TravNpcCharacter", "Character" }, { "TravInteract", "Interact" }, { "TravTraverse", "Traverse" }, { "TravHold", "Hold" } };
	add_child(t.body);
	for (int j = 0; j < 4; j++) {
		if (!db->class_exists(parts[j][0])) continue;
		Node *n = Object::cast_to<Node>((Object *)db->instantiate(parts[j][0]));
		n->set_name(parts[j][1]);
		n->set("body", t.body);
		if (j == 0) n->set("model_path", String("res://traversal/npc/") + trav_ids[(size_t)((k * 7 + 3) % (int)trav_ids.size())] + String(".scn"));
		t.body->add_child(n);
	}
	if (t.body->has_method("show_capsule")) t.body->call("show_capsule", false);   // (the lab draws the body's capsule: not in the game)
	t.base_pace = (float)(double)t.body->get("pace");   // (the body's own pace, set by its character from its legs)
	if (!(t.base_pace > 0.1f)) t.base_pace = 1.0f;
	t.body->set_visible(false);
	t.body->set_process_mode(Node::PROCESS_MODE_DISABLED);
}

// The player's seats: once a second the four nearest free benches within 30 m of him are given to the lab's seat
// group, each a point on the ground under the sitter and the way he faces (USE within reach of one: he walks the last
// steps, sits down, sits; the stick held gets him up). The ground's height is read at the bench's pavement point.
void CityCrowd::trav_benches() {
	if (trav_bench_t-- > 0) return;
	trav_bench_t = 60;
	Node3D *pl = player_id ? Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	int pick[4] = { -1, -1, -1, -1 }; float pd[4] = { 1e9f, 1e9f, 1e9f, 1e9f };
	if (pl) {
		const Vector3 at = pl->get_global_position();
		const int np = (int)crowd->places.size();
		for (int k = 0; k < np; k++) {
			const pc::Place &P = crowd->places[(size_t)k];
			if (P.kind != pc::PL_BENCH || crowd->occ[(size_t)k] >= 0) continue;
			const float dx = P.x - at.x, dz = P.z - at.z, d = dx * dx + dz * dz;
			if (d > 30.0f * 30.0f) continue;
			for (int q = 0; q < 4; q++) if (d < pd[q]) { for (int r = 3; r > q; r--) { pd[r] = pd[r - 1]; pick[r] = pick[r - 1]; } pd[q] = d; pick[q] = k; break; }
		}
	}
	for (int q = 0; q < 4; q++) {
		if (pick[q] < 0) { if (trav_bench[q] && trav_bench[q]->is_in_group("tl_seat")) trav_bench[q]->remove_from_group("tl_seat"); continue; }
		if (!trav_bench[q]) { trav_bench[q] = memnew(Node3D); trav_bench[q]->set_meta("desk", false); trav_bench[q]->set_meta("side", Vector3()); add_child(trav_bench[q]); }
		const pc::Place &P = crowd->places[(size_t)pick[q]];
		float y = P.y;
		Ref<PhysicsRayQueryParameters3D> rq = PhysicsRayQueryParameters3D::create(Vector3(P.ax, P.y + 1.5f, P.az), Vector3(P.ax, P.y - 2.0f, P.az), 1);
		const Dictionary hit = TRAV_RAY(this, rq);
		if (!hit.is_empty()) y = ((Vector3)hit["position"]).y;
		const Vector3 f(std::sin(P.yaw), 0, std::cos(P.yaw));
		trav_bench[q]->set_global_transform(Transform3D(Basis::looking_at(-f, Vector3(0, 1, 0)), Vector3(P.x, y, P.z)));
		if (!trav_bench[q]->is_in_group("tl_seat")) trav_bench[q]->add_to_group("tl_seat");
	}
}

// every physics step (CityCrowd::_physics_process): each new body is led to where its old figure stands, sits where it sits (its own
// take), or is given its pose (the pose copy)
void CityCrowd::trav_people_update() {
	if (!trav_people) return;
	// (Yasin, 28 Nov: "there are still npcs from the old version, i need them to be out of the game entirely"; "some near
	// people are also old npcs") with the new people on, an old figure is never drawn: a body not made, not set down or
	// whose pose cannot be copied leaves its walker unseen (set_drawn(false) below), as the far crowd is (CityCrowd::draw)
	trav_benches();
	const int n = (int)near_pool.size();
	for (int k = 0; k < n; k++) {
		Near &nb = near_pool[(size_t)k];
		if (!nb.ped) continue;
		const int i = nb.walker >= 0 ? crowd->find(nb.walker) : -1;
		const int a = i >= 0 ? (int)crowd->act[i] : 0;
		const bool shown = i >= 0 && nb.ped->is_visible();
		if (shown) trav_make(k);
		TravNb *t = k < (int)trav_pool.size() ? &trav_pool[(size_t)k] : nullptr;
		if (!t || !t->body) { nb.ped->set_drawn(false); continue; }
		if (!shown) {
			if (t->mir.on) t->mir.set(t->body, nb.ped, nb.ped->skeleton(), false), t->on = false;
			if (t->sit && trav_seat_busy == k) trav_seat_busy = -1;
			t->sit = 0;
			if (t->on || t->body->is_visible()) { t->body->set_visible(false); t->body->set_process_mode(Node::PROCESS_MODE_DISABLED); t->on = false; t->walker = -1; }
			nb.ped->set_drawn(false);
			continue;
		}
		// what his walker does. Walking, standing, waiting, talking, looking, a phone, a thing carried: the new body's own
		// movement. A seat: its own take. Anything else (the ground, lying, a fight, a hug, a wave, ducking, the jump out of
		// a car's way, shoved, knocked down, a medic's work): the pose copy.
		const bool plain = a == pc::A_NONE || a == pc::A_PHONE || a == pc::A_CALL || a == pc::A_WINDOW || a == pc::A_STARE || a == pc::A_WAIT || a == pc::A_TALK || a == pc::A_CHAT || a == pc::A_SHELTER || a == pc::A_DOOR;
		const bool seat_act = a == pc::A_SIT || a == pc::A_DRINK;
		const bool own = nb.ped->get_mode() == CityPed::MODE_ANIM && nb.cpr == 0 && crowd->mode[i] != pc::M_DODGE;
		const Transform3D at = nb.ped->get_global_transform();
		Node *inter = t->body->get_node_or_null("Interact");
		const bool seated_now = inter && (bool)inter->get("seated");
		bool copy = !own || !(plain || seat_act || t->sit != 0);
		if (t->sit != 0 && !own) { copy = true; }      // (knocked off his seat)
		if (seat_act && t->sit == 0 && own) {
			// a seat of his own where the old figure sits, the only one in the lab's group while he takes it (two on a
			// bench would each take the nearer); if his take cannot be begun in 4 s, the pose copy sits him
			if (t->sit_t > 4.0f) copy = true;
			else if (t->on && (trav_seat_busy < 0 || trav_seat_busy == k)) {
				if (!t->seat) { t->seat = memnew(Node3D); t->seat->set_meta("desk", false); t->seat->set_meta("side", Vector3()); add_child(t->seat); }
				const Vector3 b = t->body->get_global_position();
				const Vector3 f = Vector3(at.basis.get_column(2).x, 0, at.basis.get_column(2).z).normalized();
				t->seat->set_global_transform(Transform3D(Basis::looking_at(-f, Vector3(0, 1, 0)), Vector3(at.origin.x, b.y, at.origin.z)));
				const Vector3 stand = inter ? (Vector3)inter->call("_seat_stand", t->seat) : at.origin;
				if (b.distance_to(stand) < 2.3f) { t->seat->add_to_group("tl_seat"); trav_seat_busy = k; t->sit = 1; t->sit_t = 0.0f; }
			}
		}
		if (!seat_act && t->sit == 0) t->sit_t = 0.0f;
		if (copy) {
			if (t->sit) { if (trav_seat_busy == k) { trav_seat_busy = -1; if (t->seat) t->seat->remove_from_group("tl_seat"); } t->sit = 0; }
			if (!t->body->is_visible()) t->body->set_visible(true);
			t->mir.set(t->body, nb.ped, nb.ped->skeleton(), true);
			if (t->mir.on) { nb.ped->set_drawn(false); if (nb.phone) nb.phone->set_visible(false); if (nb.phone2) nb.phone2->set_visible(false); }
			else { t->body->set_visible(false); nb.ped->set_drawn(false); }
			t->walker = nb.walker;
			continue;
		}
		if (t->mir.on) t->mir.set(t->body, nb.ped, nb.ped->skeleton(), false), t->on = false;
		bool show = true;
		if (!t->on || t->walker != nb.walker) {
			// set down where the old figure stands, if the ground is there (the streamer's collision reaches less far than
			// the figures do: without ground under him he would fall out of the world)
			Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(at.origin + Vector3(0, 1.0f, 0), at.origin - Vector3(0, 2.0f, 0), 1);
			const Dictionary hit = TRAV_RAY(this, q);
			if (hit.is_empty()) show = false;
			else {
				const Vector3 p = hit["position"];
				t->body->set_process_mode(Node::PROCESS_MODE_INHERIT);
				t->body->call("place", p + Vector3(0, 0.02f, 0));
				t->body->set_rotation(Vector3(0, std::atan2(at.basis.get_column(2).x, at.basis.get_column(2).z), 0));
				t->on = true; t->walker = nb.walker; t->going = false;
				if (t->sit) { if (trav_seat_busy == k) { trav_seat_busy = -1; if (t->seat) t->seat->remove_from_group("tl_seat"); } t->sit = 0; }
			}
		}
		if (!show) {
			if (t->on || t->body->is_visible()) { t->body->set_visible(false); t->body->set_process_mode(Node::PROCESS_MODE_DISABLED); t->on = false; t->walker = -1; }
			nb.ped->set_drawn(false);
			continue;
		}
		t->body->set_visible(true);
		nb.ped->set_drawn(false);
		if (nb.phone) nb.phone->set_visible(false);
		if (nb.phone2) nb.phone2->set_visible(false);
		const Vector3 b = t->body->get_global_position();
		const float dx = at.origin.x - b.x, dz = at.origin.z - b.z, d = std::sqrt(dx * dx + dz * dz);
		Dictionary &s = t->tape->s;
		s["mx"] = 0.0; s["mz"] = 0.0; s["run"] = false;
		s["jump"] = false; s["crouch"] = false; s["act"] = false; s["text"] = false; s["call"] = false;
		s["item"] = 0; s["aim"] = false; s["fire"] = false; s["reload"] = false; s["drop"] = false; s["hit"] = false;
		if (t->sit != 0) {
			// 1: the key held until his take has him (the body walks the last steps to it itself); 2: seated for as long
			// as his walker sits; 3: the stick held, which is how he gets up, until he stands
			t->sit_t += 1.0f / 60.0f;
			if (t->sit == 1) {
				s["act"] = true;
				if (seated_now) { t->sit = 2; t->seat->remove_from_group("tl_seat"); if (trav_seat_busy == k) trav_seat_busy = -1; }
				else if (t->sit_t > 8.0f) { t->sit = 0; t->sit_t = 9.0f; t->seat->remove_from_group("tl_seat"); if (trav_seat_busy == k) trav_seat_busy = -1; }
			} else if (t->sit == 2) {
				if (!seat_act) t->sit = 3;
			} else {
				s["mz"] = -1.0; s["yaw"] = (double)std::atan2(-at.basis.get_column(2).x, -at.basis.get_column(2).z);
				if (!seated_now && !(bool)t->body->call("in_move")) { t->sit = 0; t->sit_t = 0.0f; }
			}
			continue;
		}
		// fallen under the world, or left far behind (a walker set somewhere else): set down again next frame
		if (b.y < at.origin.y - 4.0f || d > 6.0f) { t->on = false; continue; }
		// he sets off when the place is 0.4 m ahead of him and stops within 0.12 m of it; the further behind, the faster
		// his walk (0.85 to 1.5 of his own pace, so that he keeps up with a walker of any pace); left 4 m behind he runs
		if (!t->going && d > 0.4f) t->going = true;
		if (t->going && d < 0.12f) t->going = false;
		t->body->set("pace", (double)(t->base_pace * std::min(std::max(0.85f + d * 0.6f, 0.85f), 1.5f)));
		s["mz"] = t->going ? -1.0 : 0.0;
		// (the stick pushed ahead, mz -1, goes along -Z of the view: the view is turned so that -Z points at the place)
		if (t->going) s["yaw"] = (double)std::atan2(-dx, -dz);
		s["run"] = t->going && d > 4.0f;
		// a phone: at his ear on a call, in front of him for a text (the body's own phone holds); a thing carried: the
		// plastic bag, the box or the briefcase in his hand (trav_hold: 2, 3, 1), put away while he is on the phone
		const bool on_phone = a == pc::A_PHONE || a == pc::A_CALL;
		const int ph = !on_phone ? 0 : ((a == pc::A_CALL || !((crowd->look[i] >> 13) & 1u)) ? 2 : 1);
		if ((int)(int64_t)t->body->get("phone") != ph) t->body->set("phone", ph);
		static const int ITEM_OF[3] = { 2, 3, 1 };
		s["item"] = (!on_phone && carries(i)) ? ITEM_OF[std::min(std::max(carry_kind(i), 0), 2)] : 0;
	}
}
#endif
