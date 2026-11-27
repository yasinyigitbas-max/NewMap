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
#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/class_db_singleton.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
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
		for (TravNb &t : trav_pool) { if (t.body) t.body->queue_free(); if (t.tape) t.tape->queue_free(); }
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
	const char *parts[2][2] = { { "TravNpcCharacter", "Character" }, { "TravTraverse", "Traverse" } };
	add_child(t.body);
	for (int j = 0; j < 2; j++) {
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

// after near_update, every frame: each new body is led to where its old figure stands
void CityCrowd::trav_people_update() {
	if (!trav_people) return;
	const int n = (int)near_pool.size();
	for (int k = 0; k < n; k++) {
		Near &nb = near_pool[(size_t)k];
		if (!nb.ped) continue;
		const bool want = nb.walker >= 0 && nb.ped->is_visible() && nb.ped->get_mode() == CityPed::MODE_ANIM;
		if (want) trav_make(k);
		TravNb *t = k < (int)trav_pool.size() ? &trav_pool[(size_t)k] : nullptr;
		if (!t || !t->body) { nb.ped->set_drawn(true); continue; }
		const Transform3D at = nb.ped->get_global_transform();
		bool show = want;
		if (show && (!t->on || t->walker != nb.walker)) {
			// set down where the old figure stands, if the ground is there (the streamer's collision reaches less far than
			// the figures do: without ground under him he would fall out of the world)
			Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(at.origin + Vector3(0, 1.0f, 0), at.origin - Vector3(0, 2.0f, 0), 1);
			const Dictionary hit = get_world_3d()->get_direct_space_state()->intersect_ray(q);
			if (hit.is_empty()) show = false;
			else {
				const Vector3 p = hit["position"];
				t->body->set_process_mode(Node::PROCESS_MODE_INHERIT);
				t->body->call("place", p + Vector3(0, 0.02f, 0));
				t->body->set_rotation(Vector3(0, std::atan2(at.basis.get_column(2).x, at.basis.get_column(2).z), 0));
				t->on = true; t->walker = nb.walker; t->going = false;
			}
		}
		if (!show) {
			if (t->on) { t->body->set_visible(false); t->body->set_process_mode(Node::PROCESS_MODE_DISABLED); t->on = false; t->walker = -1; }
			nb.ped->set_drawn(true);
			continue;
		}
		t->body->set_visible(true);
		nb.ped->set_drawn(false);
		if (nb.phone) nb.phone->set_visible(false);
		if (nb.phone2) nb.phone2->set_visible(false);
		const Vector3 b = t->body->get_global_position();
		const float dx = at.origin.x - b.x, dz = at.origin.z - b.z, d = std::sqrt(dx * dx + dz * dz);
		// fallen under the world, or left far behind (a walker set somewhere else): set down again next frame
		if (b.y < at.origin.y - 4.0f || d > 6.0f) { t->on = false; continue; }
		// he sets off when the place is 0.4 m ahead of him and stops within 0.12 m of it; the further behind, the faster
		// his walk (0.85 to 1.5 of his own pace, so that he keeps up with a walker of any pace); left 4 m behind he runs
		if (!t->going && d > 0.4f) t->going = true;
		if (t->going && d < 0.12f) t->going = false;
		t->body->set("pace", (double)(t->base_pace * std::min(std::max(0.85f + d * 0.6f, 0.85f), 1.5f)));
		Dictionary &s = t->tape->s;
		s["mx"] = 0.0; s["mz"] = t->going ? -1.0 : 0.0;
		// (the stick pushed ahead, mz -1, goes along -Z of the view: the view is turned so that -Z points at the place)
		if (t->going) s["yaw"] = (double)std::atan2(-dx, -dz);
		s["run"] = t->going && d > 4.0f;
		s["jump"] = false; s["crouch"] = false; s["act"] = false; s["text"] = false; s["call"] = false;
	}
}
#endif
