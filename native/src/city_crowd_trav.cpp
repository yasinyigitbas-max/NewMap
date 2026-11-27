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

// ---------------------------------------------------------------------------------------------- the pose copy
// The old figure (Rocketbox bones) goes on playing every act, not drawn; its pose is put on the new body's skeleton
// (the mixamo bones) bone by bone: how far each old bone is turned from its rest, in the figure's own frame, turns the
// new bone from ITS rest, once that rest has been turned to face as the old one does (F) and its bone to point as the
// old bone points at rest (A: the old bodies rest with their arms lower than the new ones). The hips are set where the
// old hips are, by the share of the two bodies' hip heights.
static const char *const MAP[][2] = {
	{ "Hips", "Pelvis" }, { "Spine", "Spine" }, { "Spine1", "Spine1" }, { "Spine2", "Spine2" }, { "Neck", "Neck" }, { "Head", "Head" },
	{ "LeftShoulder", "L_Clavicle" }, { "LeftArm", "L_UpperArm" }, { "LeftForeArm", "L_Forearm" }, { "LeftHand", "L_Hand" },
	{ "RightShoulder", "R_Clavicle" }, { "RightArm", "R_UpperArm" }, { "RightForeArm", "R_Forearm" }, { "RightHand", "R_Hand" },
	{ "LeftUpLeg", "L_Thigh" }, { "LeftLeg", "L_Calf" }, { "LeftFoot", "L_Foot" }, { "RightUpLeg", "R_Thigh" }, { "RightLeg", "R_Calf" }, { "RightFoot", "R_Foot" },
	{ "LeftHandThumb1", "L_Finger0" }, { "LeftHandThumb2", "L_Finger01" }, { "LeftHandThumb3", "L_Finger02" },
	{ "LeftHandIndex1", "L_Finger1" }, { "LeftHandIndex2", "L_Finger11" }, { "LeftHandIndex3", "L_Finger12" },
	{ "LeftHandMiddle1", "L_Finger2" }, { "LeftHandMiddle2", "L_Finger21" }, { "LeftHandMiddle3", "L_Finger22" },
	{ "LeftHandRing1", "L_Finger3" }, { "LeftHandRing2", "L_Finger31" }, { "LeftHandRing3", "L_Finger32" },
	{ "LeftHandPinky1", "L_Finger4" }, { "LeftHandPinky2", "L_Finger41" }, { "LeftHandPinky3", "L_Finger42" },
	{ "RightHandThumb1", "R_Finger0" }, { "RightHandThumb2", "R_Finger01" }, { "RightHandThumb3", "R_Finger02" },
	{ "RightHandIndex1", "R_Finger1" }, { "RightHandIndex2", "R_Finger11" }, { "RightHandIndex3", "R_Finger12" },
	{ "RightHandMiddle1", "R_Finger2" }, { "RightHandMiddle2", "R_Finger21" }, { "RightHandMiddle3", "R_Finger22" },
	{ "RightHandRing1", "R_Finger3" }, { "RightHandRing2", "R_Finger31" }, { "RightHandRing3", "R_Finger32" },
	{ "RightHandPinky1", "R_Finger4" }, { "RightHandPinky2", "R_Finger41" }, { "RightHandPinky3", "R_Finger42" },
};
// which bone a bone points at, at rest (new names); none: the two rests are only turned to face alike
static const char *const POINTS[][2] = {
	{ "Hips", "Spine" }, { "Spine", "Spine1" }, { "Spine1", "Spine2" }, { "Spine2", "Neck" }, { "Neck", "Head" },
	{ "LeftShoulder", "LeftArm" }, { "LeftArm", "LeftForeArm" }, { "LeftForeArm", "LeftHand" }, { "LeftHand", "LeftHandMiddle1" },
	{ "RightShoulder", "RightArm" }, { "RightArm", "RightForeArm" }, { "RightForeArm", "RightHand" }, { "RightHand", "RightHandMiddle1" },
	{ "LeftUpLeg", "LeftLeg" }, { "LeftLeg", "LeftFoot" }, { "RightUpLeg", "RightLeg" }, { "RightLeg", "RightFoot" },
};

static int new_bone(Skeleton3D *sk, const char *n) {
	int b = sk->find_bone(String("mixamorig_") + n);
	if (b < 0) b = sk->find_bone(String("mixamorig:") + n);
	return b;
}

bool CityCrowd::trav_map(TravNb &t, Near &nb) {
	if (t.map_ok) return true;
	Node *ch = t.body->get_node_or_null("Character");
	Skeleton3D *sk = ch ? Object::cast_to<Skeleton3D>((Object *)ch->get("skel")) : nullptr;
	Skeleton3D *os = nb.ped->skeleton();
	if (!sk || !os || !sk->is_inside_tree() || !os->is_inside_tree()) return false;
	t.sk = sk;
	const int nn = sk->get_bone_count();
	// both rests in their figure's own frame (the node the crowd moves; the body)
	const Basis on = (t.body->get_global_transform().affine_inverse() * sk->get_global_transform()).basis.orthonormalized();
	const Transform3D mo = nb.ped->get_global_transform().affine_inverse() * os->get_global_transform();
	const Basis oo = mo.basis.orthonormalized();
	const int nl = new_bone(sk, "LeftUpLeg"), nr = new_bone(sk, "RightUpLeg"), nh = new_bone(sk, "Hips");
	const int ol = os->find_bone("Bip01_L_Thigh"), orr = os->find_bone("Bip01_R_Thigh"), oh = os->find_bone("Bip01_Pelvis");
	if (nl < 0 || nr < 0 || nh < 0 || ol < 0 || orr < 0 || oh < 0) return false;
	Vector3 ln = on.xform(sk->get_bone_global_rest(nl).origin - sk->get_bone_global_rest(nr).origin);
	Vector3 lo = oo.xform(os->get_bone_global_rest(ol).origin - os->get_bone_global_rest(orr).origin);
	ln.y = 0; lo.y = 0;
	if (ln.length() < 1e-5f || lo.length() < 1e-5f) return false;
	const Basis F(Vector3(0, 1, 0), std::atan2(lo.x, lo.z) - std::atan2(ln.x, ln.z));   // the new rest turned to face as the old one
	t.m_old.assign((size_t)nn, -1); t.m_fix.assign((size_t)nn, Basis()); t.m_old_rest_inv.assign((size_t)nn, Basis());
	for (const auto &m : MAP) {
		const int b = new_bone(sk, m[0]), o = os->find_bone(String("Bip01_") + m[1]);
		if (b < 0 || o < 0) continue;
		const Basis rn = F * on * sk->get_bone_global_rest(b).basis.orthonormalized();
		const Basis ro = oo * os->get_bone_global_rest(o).basis.orthonormalized();
		Basis A;
		for (const auto &pt : POINTS) {
			if (String(pt[0]) != String(m[0])) continue;
			const int bc = new_bone(sk, pt[1]);
			int oc = -1;
			for (const auto &m2 : MAP) if (String(m2[0]) == String(pt[1])) oc = os->find_bone(String("Bip01_") + m2[1]);
			if (bc < 0 || oc < 0) break;
			const Vector3 dn = (F * on).xform(sk->get_bone_global_rest(bc).origin - sk->get_bone_global_rest(b).origin).normalized();
			const Vector3 dd = oo.xform(os->get_bone_global_rest(oc).origin - os->get_bone_global_rest(o).origin).normalized();
			if (dn.length() > 0.5f && dd.length() > 0.5f && dn.dot(dd) < 0.99999f && dn.dot(dd) > -0.999f) A = Basis(Quaternion(dn, dd));
			break;
		}
		t.m_old[(size_t)b] = o; t.m_fix[(size_t)b] = A * rn; t.m_old_rest_inv[(size_t)b] = ro.inverse();
	}
	const float hn = on.xform(sk->get_bone_global_rest(nh).origin).y * (t.body->get_global_transform().affine_inverse() * sk->get_global_transform()).basis.get_scale().y;
	const float ho = mo.xform(os->get_bone_global_rest(oh).origin).y;
	t.m_scale = ho > 0.2f && hn > 0.2f ? hn / ho : 1.0f;
	t.map_ok = true;
	return true;
}

// into and out of the pose copy: the body's own movement, animation and bone fitting stand still while it lasts
void CityCrowd::trav_mirror(TravNb &t, Near &nb, bool p_on) {
	if (p_on && !trav_map(t, nb)) p_on = false;
	if (t.mirror != p_on) {
		t.mirror = p_on;
		t.body->set_process_mode(p_on ? Node::PROCESS_MODE_DISABLED : Node::PROCESS_MODE_INHERIT);
		if (t.sk) {
			const TypedArray<Node> kids = t.sk->get_children();
			for (int c = 0; c < kids.size(); c++) {
				if (SkeletonModifier3D *md = Object::cast_to<SkeletonModifier3D>((Object *)kids[c])) md->set_active(!p_on);
				// (a thing in his hand, his phone: not while his pose is another figure's; their owners show them again)
				else if (p_on && !Object::cast_to<MeshInstance3D>((Object *)kids[c])) { if (Node3D *thing = Object::cast_to<Node3D>((Object *)kids[c])) thing->set_visible(false); }
			}
			if (!p_on) t.sk->reset_bone_poses();
		}
		if (!p_on) t.on = false;      // set down afresh where his walker is
	}
	if (!p_on) return;
	Skeleton3D *sk = t.sk, *os = nb.ped->skeleton();
	Transform3D at = nb.ped->get_global_transform();
	at.basis = at.basis.orthonormalized();
	t.body->set_global_transform(at);
	const Transform3D mn = at.affine_inverse() * sk->get_global_transform();
	const Basis on_inv = mn.basis.orthonormalized().inverse();
	const Transform3D mo = nb.ped->get_global_transform().affine_inverse() * os->get_global_transform();
	const Basis oo = mo.basis.orthonormalized();
	const int nn = sk->get_bone_count();
	static thread_local std::vector<Basis> g;      // each new bone's turn in the skeleton's frame, as set this frame
	g.assign((size_t)nn, Basis());
	std::vector<char> done((size_t)nn, 0);
	// (a parent before its children, whatever the order of the bones: the new bodies' root is their last bone)
	for (int pass = 0; pass < 8; pass++) {
		bool all = true;
		for (int b = 0; b < nn; b++) {
			if (done[(size_t)b]) continue;
			const int par = sk->get_bone_parent(b);
			if (par >= 0 && !done[(size_t)par]) { all = false; continue; }
			const Basis gp = par >= 0 ? g[(size_t)par] : Basis();
			const int o = t.m_old[(size_t)b];
			if (o < 0) { g[(size_t)b] = gp * sk->get_bone_rest(b).basis.orthonormalized(); sk->set_bone_pose_rotation(b, sk->get_bone_rest(b).basis.get_rotation_quaternion()); done[(size_t)b] = 1; continue; }
			const Basis go = oo * os->get_bone_global_pose(o).basis.orthonormalized();
			const Basis gn = on_inv * (go * t.m_old_rest_inv[(size_t)b] * t.m_fix[(size_t)b]);
			g[(size_t)b] = gn;
			sk->set_bone_pose_rotation(b, (gp.inverse() * gn).orthonormalized().get_rotation_quaternion());
			done[(size_t)b] = 1;
		}
		if (all) break;
	}
	const int nh = new_bone(sk, "Hips"), oh = os->find_bone("Bip01_Pelvis");
	if (nh >= 0 && oh >= 0) {
		const Vector3 p = mo.xform(os->get_bone_global_pose(oh).origin) * t.m_scale;      // in the figure's frame, at the new body's size
		const int par = sk->get_bone_parent(nh);
		const Transform3D pg = par >= 0 ? sk->get_bone_global_pose(par) : Transform3D();
		sk->set_bone_pose_position(nh, (mn * pg).affine_inverse().xform(p));
	}
}

// after near_update, every frame: each new body is led to where its old figure stands, sits where it sits (its own
// take), or is given its pose (the pose copy)
void CityCrowd::trav_people_update() {
	if (!trav_people) return;
	const int n = (int)near_pool.size();
	for (int k = 0; k < n; k++) {
		Near &nb = near_pool[(size_t)k];
		if (!nb.ped) continue;
		const int i = nb.walker >= 0 ? crowd->find(nb.walker) : -1;
		const int a = i >= 0 ? (int)crowd->act[i] : 0;
		const bool shown = i >= 0 && nb.ped->is_visible();
		if (shown) trav_make(k);
		TravNb *t = k < (int)trav_pool.size() ? &trav_pool[(size_t)k] : nullptr;
		if (!t || !t->body) { nb.ped->set_drawn(true); continue; }
		if (!shown) {
			if (t->mirror) trav_mirror(*t, nb, false);
			if (t->sit && trav_seat_busy == k) trav_seat_busy = -1;
			t->sit = 0;
			if (t->on || t->body->is_visible()) { t->body->set_visible(false); t->body->set_process_mode(Node::PROCESS_MODE_DISABLED); t->on = false; t->walker = -1; }
			nb.ped->set_drawn(true);
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
			trav_mirror(*t, nb, true);
			if (t->mirror) { nb.ped->set_drawn(false); if (nb.phone) nb.phone->set_visible(false); if (nb.phone2) nb.phone2->set_visible(false); }
			else { t->body->set_visible(false); nb.ped->set_drawn(true); }
			t->walker = nb.walker;
			continue;
		}
		if (t->mirror) trav_mirror(*t, nb, false);
		bool show = true;
		if (!t->on || t->walker != nb.walker) {
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
				if (t->sit) { if (trav_seat_busy == k) { trav_seat_busy = -1; if (t->seat) t->seat->remove_from_group("tl_seat"); } t->sit = 0; }
			}
		}
		if (!show) {
			if (t->on || t->body->is_visible()) { t->body->set_visible(false); t->body->set_process_mode(Node::PROCESS_MODE_DISABLED); t->on = false; t->walker = -1; }
			nb.ped->set_drawn(true);
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
