// CityRooms: see city_rooms.h.
#include "perf_marks.h"
#include "city_rooms.h"
#include "el_sfx.h"
#include <godot_cpp/classes/audio_stream_player3d.hpp>
#include "city_stream.h"
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/concave_polygon_shape3d.hpp>
#include <godot_cpp/classes/omni_light3d.hpp>
#include <godot_cpp/classes/light3d.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/static_body3d.hpp>
#include <godot_cpp/classes/collision_shape3d.hpp>
#include <godot_cpp/classes/collision_object3d.hpp>
#include <godot_cpp/classes/cpu_particles3d.hpp>
#include <godot_cpp/classes/geometry_instance3d.hpp>
#include <godot_cpp/classes/spot_light3d.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <algorithm>
#include <cmath>

namespace godot {

void CityRooms::set_stream(Object *p_stream) {
	stream_id = p_stream ? (uint64_t)p_stream->get_instance_id() : 0;
	if (!is_in_group("city_rooms")) add_to_group("city_rooms");   // (CityShops finds it so)
	if (!p_stream) return;
	p_stream->connect("cell_in", Callable(this, "_on_cell_in"));
	p_stream->connect("cell_out", Callable(this, "_on_cell_out"));
	set_process(true);
}

// ---------------------------------------------------------------- the cells' buildings with rooms
void CityRooms::add_cell(const String &p_key) {
	CityStream *st = Object::cast_to<CityStream>(ObjectDB::get_instance(ObjectID(stream_id)));
	Node3D *cn = st ? st->cell_node(p_key) : nullptr;
	if (!cn) return;
	std::vector<int> &list = by_cell[p_key];
	// the bake puts buildings straight under the cell's Buildings node; only those with rooms carry the meta
	Node *bn = cn->get_node_or_null(NodePath("Buildings"));
	if (!bn) return;
	const int nb = bn->get_child_count();
	for (int b = 0; b < nb; b++) {
		Node3D *bd = Object::cast_to<Node3D>(bn->get_child(b));
		if (!bd || !bd->has_meta("rooms")) continue;
		const Array rs = bd->get_meta("rooms");
		for (int r = 0; r < rs.size(); r++) {
			const Dictionary d = rs[r];
			Room rm; rm.cell = p_key; rm.scn = d.get("scn", ""); rm.raw = d.get("raw", ""); rm.col = d.get("col", ""); rm.building = (uint64_t)bd->get_instance_id();
			rm.centre_local = d.get("centre", Vector3()); rm.centre_world = bd->get_global_transform().xform(rm.centre_local);
			int slot;
			if (!free_slots.empty()) { slot = free_slots.back(); free_slots.pop_back(); rooms[slot] = rm; } else { slot = (int)rooms.size(); rooms.push_back(rm); }
			list.push_back(slot);
		}
	}
}

void CityRooms::drop_cell(const String &p_key) {
	for (size_t k = 0; k < arriving.size(); k++) if (arriving[k] == p_key) { arriving.erase(arriving.begin() + (long)k); break; }
	if (!by_cell.has(p_key)) return;
	for (int i : by_cell[p_key]) {
		// the room is a child of its building, which leaves with the cell: no hand-over needed, only the books kept
		if (rooms[i].state == 2) live--;
		if (rooms[i].state == 1) loading--;
		rooms[i] = Room(); free_slots.push_back(i);
	}
	by_cell.erase(p_key);
}

// ---------------------------------------------------------------- waking and sleeping
void CityRooms::wake(int i) {
	Room &rm = rooms[i];
	ResourceLoader *rl = ResourceLoader::get_singleton();
	if (!rm.scn.is_empty() && !rl->exists(rm.scn)) rm.scn = rm.raw;      // (no merged copy: the room as its builders saved it)
	if (rm.scn.is_empty()) return;
	rl->load_threaded_request(rm.scn);
	if (!rm.col.is_empty() && rl->exists(rm.col)) rl->load_threaded_request(rm.col);
	rm.state = 1; loading++;
}

void CityRooms::finish(int i) {
	Room &rm = rooms[i];
	ResourceLoader *rl = ResourceLoader::get_singleton();
	Node3D *bd = Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(rm.building)));
	Ref<PackedScene> ps;
	{ pm::Scope _g(pm::ROOM_GET); ps = rl->load_threaded_get(rm.scn); }
	loading--;
	if (!bd || ps.is_null()) { rm.state = 0; return; }
	Node3D *root = nullptr;
	{ pm::Scope _n(pm::ROOM_INST); root = Object::cast_to<Node3D>(ps->instantiate()); }
	if (!root) { rm.state = 0; return; }
	// the doors: the leaves' script dropped (C++ swings them, below), their measures kept
	rm.leaves.clear();
	const TypedArray<Node> lv = root->find_children("DoorLeaf_*", "Node3D", true, false);
	for (int k = 0; k < lv.size(); k++) {
		Node3D *l = Object::cast_to<Node3D>(lv[k]);
		if (!l) continue;
		l->set_script(Variant());
		Leaf f; f.node = (uint64_t)l->get_instance_id();
		f.mid = l->has_meta("mid") ? (Vector3)l->get_meta("mid") : Vector3();
		f.out_dir = l->has_meta("out_dir") ? (Vector3)l->get_meta("out_dir") : Vector3(0, 0, 1);
		f.sign = l->has_meta("open_sign") ? (float)(double)l->get_meta("open_sign") : 1.0f;
		f.bid = bid_of(l, rm.scn); f.hp = DOOR_HP;
		if (breakables.has(f.bid)) {      // (as it was left: broken stays broken across streaming)
			const Dictionary st = breakables[f.bid];
			f.hp = (float)(double)st.get("hp", DOOR_HP);
			if (String(st.get("state", "")) == "broken") { f.broken = true; leaf_broken(l); }
		}
		rm.leaves.push_back(f);
	}
	// the breakable windows: their script dropped too (an older bake still carried builtin_window.gd), swapped here
	rm.wins.clear();
	const TypedArray<Node> wv = root->find_children("Window_*", "Node3D", true, false);
	for (int k = 0; k < wv.size(); k++) {
		Node3D *w = Object::cast_to<Node3D>(wv[k]);
		if (!w || !w->get_node_or_null(NodePath("pane"))) continue;
		w->set_script(Variant());      // (22 Nov) as the doors: no GDScript per window in the game, C++ cracks/breaks it (shards + sound)
		Win wi; wi.node = (uint64_t)w->get_instance_id(); wi.bid = bid_of(w, rm.scn); wi.hp = WINDOW_HP;
		if (breakables.has(wi.bid)) {
			const Dictionary st = breakables[wi.bid];
			wi.hp = (float)(double)st.get("hp", WINDOW_HP);
			const Array uv = st.get("uv", Array());
			if (uv.size() == 2) wi.uv = Vector2((float)(double)uv[0], (float)(double)uv[1]);
			const String sv = st.get("state", "");
			const Array hs = st.get("holes", Array());
			for (int h = 0; h + 1 < hs.size(); h += 2) wi.holes.push_back(Vector2((float)(double)hs[h], (float)(double)hs[h + 1]));
			if (!wi.holes.empty() && sv != "broken" && !w->has_method("damage")) win_holes(w, wi.holes);
			if (!w->has_method("damage")) {
				if (sv == "broken") { wi.broken = true; win_broken(w, wi.uv, false); }
				else if (sv == "cracked") { wi.cracked = true; win_cracked(w, wi.uv); }
			} else if (sv == "broken") wi.broken = true;
		}
		rm.wins.push_back(wi);
	}
	// the lights: faded out with distance, no shadows (a phone's light grid holds 32)
	const TypedArray<Node> lights = root->find_children("*", "Light3D", true, false);
	for (int k = 0; k < lights.size(); k++) {
		Light3D *L = Object::cast_to<Light3D>(lights[k]);
		if (!L) continue;
		L->set_shadow(false); L->set_enable_distance_fade(true); L->set_distance_fade_begin(LIGHT_M - 10.0f); L->set_distance_fade_length(10.0f);
		rm.lights.push_back((uint64_t)L->get_instance_id());
	}
	rm.lit = true; set_lit(rm, false);      // (lit by light_rooms when it is among the nearest)
	// its collision (the bake's: the shell's faces and the furniture's boxes, room frame)
	// (loaded with the room on the loader threads; its faces go in piece by piece, add_col)
	rm.col_faces = PackedVector3Array(); rm.col_at = 0; rm.body = 0;
	if (!rm.col.is_empty() && rl->exists(rm.col)) {
		Ref<Resource> cd = rl->load_threaded_get_status(rm.col) != ResourceLoader::THREAD_LOAD_INVALID_RESOURCE ? rl->load_threaded_get(rm.col) : rl->load(rm.col);
		if (cd.is_valid()) rm.col_faces = cd->get("data");
		if (rm.col_faces.size() >= 3) {
			StaticBody3D *body = memnew(StaticBody3D); body->set_name("room_col"); body->set_collision_layer(1); body->set_collision_mask(0);
			root->add_child(body); rm.body = (uint64_t)body->get_instance_id();
		}
	}
	root->set_name("room");
	{ pm::Scope _a(pm::ROOM_ADD); bd->add_child(root); }
	rm.node = (uint64_t)root->get_instance_id(); rm.state = 2; live++; woken++;
	set_open(rm, true);
}

void CityRooms::awake_rooms(std::vector<std::pair<String, Transform3D>> &r_out) const {
	for (const Room &rm : rooms) {
		if (rm.state != 2) continue;
		Node3D *root = Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(rm.node)));
		if (!root || !root->is_inside_tree()) continue;
		const String nm = (rm.raw.is_empty() ? rm.scn : rm.raw).get_file().get_basename();
		r_out.push_back({ nm, root->get_global_transform() });
	}
}

void CityRooms::sleep(int i) {
	Room &rm = rooms[i];
	Node *root = Object::cast_to<Node>(ObjectDB::get_instance(ObjectID(rm.node)));
	CityStream *st = Object::cast_to<CityStream>(ObjectDB::get_instance(ObjectID(stream_id)));
	bool other = false;      // (a building with several rooms closes when its last room sleeps)
	for (int k = 0; k < (int)rooms.size(); k++) if (k != i && rooms[k].state == 2 && rooms[k].building == rm.building) other = true;
	if (!other) set_open(rm, false);
	if (root) {
		if (Node *p = root->get_parent()) p->remove_child(root);
		if (st) st->give_away(root); else memdelete(root);
	}
	rm.node = 0; rm.leaves.clear(); rm.wins.clear(); rm.lights.clear(); rm.state = 0; live--;
	rm.col_faces = PackedVector3Array(); rm.col_at = 0; rm.body = 0;
}

// ---------------------------------------------------------------- the doors
int CityRooms::room_kind(const String &p_scn) {
	const String s = p_scn.get_file().to_lower();
	for (const char *k : { "apt_", "condo", "house", "home", "cottage", "bungalow", "_row", "ck_brk" }) if (s.contains(k)) return 1;
	for (const char *k : { "cv_", "office", "bank", "clinic", "hall", "library", "police", "school", "church", "hospital", "rec_center", "post" }) if (s.contains(k)) return 2;
	return 0;
}

void CityRooms::door_sound(Node3D *p_leaf, const Vector3 &p_at, bool p_open, int p_kind) {
	const String nm = String(p_leaf->get_name()).to_lower();
	const char *mat = nm.contains("glass") || (p_kind == 0 && !nm.contains("wood")) ? "glass" : (nm.contains("metal") || nm.contains("steel") ? "metal" : "wood");
	const Vector3 local = get_global_transform().affine_inverse().xform(p_at);
	elsfx::play(this, String("res://audio/sfx/door/door_") + String(mat) + String(p_open ? "_open_" : "_close_"), -4.0f, 0.05f, local, 25.0f);
	if (p_open && p_kind == 0) elsfx::play(this, "res://audio/sfx/door/door_shop_bell_", -8.0f, 0.02f, local + Vector3(0, 1.2f, 0), 20.0f);
	door_sounds++;
}

// the nearest awake room's tone, from its middle (heard inside and at its door, not out on the street)
void CityRooms::room_tone(const Vector3 &cam) {
	int best = -1; float bd = 14.0f;
	for (int i = 0; i < (int)rooms.size(); i++) {
		if (rooms[i].state != 2) continue;
		const float d = rooms[i].centre_world.distance_to(cam);
		if (d < bd) { bd = d; best = i; }
	}
	static const char *TONE[3] = { "res://audio/amb/room/room_shop_", "res://audio/amb/room/room_home_", "res://audio/amb/room/room_office_" };
	AudioStreamPlayer3D *a = Object::cast_to<AudioStreamPlayer3D>(get_node_or_null(NodePath("RoomTone")));
	if (best < 0) { if (a && a->is_playing()) a->stop(); tone_room = -1; return; }
	if (best != tone_room || !a || !a->is_playing()) {
		const Ref<AudioStream> st = elsfx::pick(TONE[room_kind(rooms[best].scn)], 0, 1, true);
		if (st.is_null()) return;
		if (!a) {
			a = memnew(AudioStreamPlayer3D); a->set_name("RoomTone");
			a->set_unit_size(3.0f); a->set_max_distance(12.0f); a->set_volume_db(-8.0f);
			a->set_attenuation_filter_db(-6.0f);
			add_child(a);
		}
		if (a->get_stream() != st) a->set_stream(st);
		if (!a->is_playing()) a->play();
		tone_room = best;
	}
	a->set_global_position(rooms[best].centre_world + Vector3(0, 1.5f, 0));
}

void CityRooms::doors(double p_delta, const Vector3 &cam) {
	for (Room &rm : rooms) {
		if (rm.state != 2) continue;
		for (Leaf &f : rm.leaves) {
			Node3D *l = Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(f.node)));
			Node3D *par = l ? Object::cast_to<Node3D>(l->get_parent()) : nullptr;
			if (!l || !par) continue;
			if (f.broken) continue;
			const Vector3 mid = par->get_global_transform().xform(l->get_position() + f.mid);
			if (f.hold != 0 && cam.distance_to(mid) > HOLD_M) f.hold = 0;
			const float want = f.hold == 1 ? 1.0f : (f.hold == 2 ? 0.0f : (cam.distance_to(mid) < DOOR_TRIGGER ? 1.0f : 0.0f));
			if (f.amount <= 0.001f && want > 0.0f) {   // the side: away from the viewer (kept until shut again)
				const Vector3 outw = par->get_global_transform().basis.xform(f.out_dir);
				f.dir = (cam - mid).dot(outw) > 0.0f ? -1.0f : 1.0f;
			}
			const float step = DOOR_SPEED * (float)p_delta;
			const float was = f.amount;
			f.amount = want > f.amount ? std::min(want, f.amount + step) : std::max(want, f.amount - step);
			if (was <= 0.001f && f.amount > 0.001f) door_sound(l, mid, true, room_kind(rm.scn));
			else if (was > 0.001f && f.amount <= 0.001f) door_sound(l, mid, false, room_kind(rm.scn));
			const float e = f.amount * f.amount * (3.0f - 2.0f * f.amount);
			Vector3 rot = l->get_rotation(); rot.y = DOOR_MAX_DEG * 0.017453292f * e * f.sign * f.dir; l->set_rotation(rot);
		}
	}
}

// the building shows its openings only while its room is in (the bake keeps both near models on the near node's metas)
void CityRooms::set_open(Room &rm, bool p_open) {
	Node3D *bd = Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(rm.building)));
	MeshInstance3D *nr = bd ? Object::cast_to<MeshInstance3D>(bd->get_node_or_null(NodePath("near"))) : nullptr;
	if (!nr || !nr->has_meta("open") || !nr->has_meta("closed")) return;
	const Ref<Mesh> m = nr->get_meta(p_open ? "open" : "closed");
	if (m.is_valid() && nr->get_mesh() != m) nr->set_mesh(m);
}

void CityRooms::add_col(const Vector3 &cam) {
	int best = -1; float bd = COL_M;
	for (int i = 0; i < (int)rooms.size(); i++) {
		const Room &rm = rooms[i];
		if (rm.state != 2 || rm.body == 0 || rm.col_at >= rm.col_faces.size()) continue;
		const float d = rm.centre_world.distance_to(cam);
		if (d < bd) { bd = d; best = i; }
	}
	if (best < 0) return;
	Room &rm = rooms[best];
	StaticBody3D *body = Object::cast_to<StaticBody3D>(ObjectDB::get_instance(ObjectID(rm.body)));
	if (!body) { rm.col_at = rm.col_faces.size(); return; }
	const int n = std::min((int)rm.col_faces.size() - rm.col_at, COL_TRIS * 3);
	Ref<ConcavePolygonShape3D> sh; sh.instantiate(); sh->set_backface_collision_enabled(true);
	sh->set_faces(rm.col_faces.slice(rm.col_at, rm.col_at + n));
	const uint32_t ow = body->create_shape_owner(body); body->shape_owner_add_shape(ow, sh);
	rm.col_at += n;
	if (rm.col_at >= rm.col_faces.size()) rm.col_faces = PackedVector3Array();   // (all in: the copy is not needed)
}

void CityRooms::set_lit(Room &rm, bool p_on) {
	if (rm.lit == p_on) return;
	rm.lit = p_on;
	for (uint64_t id : rm.lights) if (Light3D *L = Object::cast_to<Light3D>(ObjectDB::get_instance(ObjectID(id)))) L->set_visible(p_on);
}

// the light budget: the nearest awake rooms within LIGHT_M keep their lights on while their lights fit in MAX_LIGHTS (a room is
// lit whole or not at all); the rest are off, so the light grid never overflows and drops the city's own lamps
void CityRooms::light_rooms(const Vector3 &cam) {
	std::vector<std::pair<float, int>> near;
	for (int i = 0; i < (int)rooms.size(); i++) {
		if (rooms[i].state != 2) continue;
		const float d = rooms[i].centre_world.distance_to(cam);
		if (d < LIGHT_M) near.push_back({ d, i }); else set_lit(rooms[i], false);
	}
	std::sort(near.begin(), near.end());
	int used = 0;
	for (size_t k = 0; k < near.size(); k++) {
		Room &rm = rooms[near[k].second];
		const int n = (int)rm.lights.size();
		const bool on = used + n <= MAX_LIGHTS;
		if (on) used += n;
		set_lit(rm, on);
	}
}

void CityRooms::_process(double p_delta) {
	pm::Scope _pm(pm::ROOMS);   // (the slow-frame marks, perf_marks.h)
	if (!arriving.empty()) { const String k = arriving.front(); arriving.erase(arriving.begin()); add_cell(k); }
	Viewport *vp = get_viewport();
	Camera3D *cam = vp ? vp->get_camera_3d() : nullptr;
	if (!cam) return;
	const Vector3 cp = cam->get_global_position();
	ResourceLoader *rl = ResourceLoader::get_singleton();
	// loads that finished: put them in (one a frame)
	for (int i = 0; i < (int)rooms.size(); i++) {
		if (rooms[i].state != 1) continue;
		const ResourceLoader::ThreadLoadStatus s = rl->load_threaded_get_status(rooms[i].scn);
		if (s == ResourceLoader::THREAD_LOAD_LOADED) { finish(i); break; }
		if (s == ResourceLoader::THREAD_LOAD_FAILED || s == ResourceLoader::THREAD_LOAD_INVALID_RESOURCE) { rooms[i].state = 0; loading--; rooms[i].scn = String(); }
	}
	if (++frame % 8 == 0) {   // every 8th frame: who wakes, who sleeps (nearest first, at most MAX_LIVE)
		std::vector<std::pair<float, int>> want;
		for (int i = 0; i < (int)rooms.size(); i++) {
			Room &rm = rooms[i];
			if (rm.cell.is_empty()) continue;
			const float d = rm.centre_world.distance_to(cp);
			if (rm.state == 2 && d > SLEEP_M) sleep(i);
			else if (rm.state == 0 && d < WAKE_M) want.push_back({ d, i });
		}
		std::sort(want.begin(), want.end());
		for (auto &w : want) { if (live + loading >= MAX_LIVE || loading >= 2) break; wake(w.second); }
		light_rooms(cp);
	}
	add_col(cp);
	// B34 (Yasin, 20 Nov: "doors of the places open too late and we see our character clipping into them"): the doors
	// open for the player (the camera trails him by ~3.4 m); the camera only when there is no player (the rig's drives)
	Vector3 who = cp;
	if (CityStream *st = Object::cast_to<CityStream>(ObjectDB::get_instance(ObjectID(stream_id)))) {
		Node3D *pl = st->get_player_id() ? Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(st->get_player_id()))) : nullptr;
		if (pl && pl->is_inside_tree() && pl->is_visible_in_tree()) who = pl->get_global_position() + Vector3(0, 1.0f, 0);
	}
	doors(p_delta, who);
	if ((frame & 7) == 0) room_tone(who);   // (8 frames apart: it follows him in and out)
}

void CityRooms::_exit_tree() {
	ResourceLoader *rl = ResourceLoader::get_singleton();
	for (Room &rm : rooms) if (rm.state == 1) (void)rl->load_threaded_get(rm.scn);   // (a pending load taken so the loader lets it go)
}

// ---------------------------------------------------------------- the door / window hooks
String CityRooms::bid_of(Node *p_n, const String &p_scn) {
	if (p_n->has_meta("bid")) return String(p_n->get_meta("bid"));
	return p_scn.get_file().get_basename() + "|" + String(p_n->get_name());
}

void CityRooms::leaf_broken(Node3D *p_leaf) {
	Vector3 r = p_leaf->get_rotation(); r.y = 0.0f; p_leaf->set_rotation(r);
	if (Node3D *a = Object::cast_to<Node3D>(p_leaf->get_node_or_null(NodePath("leaf")))) a->set_visible(false);
	if (Node3D *b = Object::cast_to<Node3D>(p_leaf->get_node_or_null(NodePath("leaf_broken")))) b->set_visible(true);
	if (Node *body = p_leaf->get_node_or_null(NodePath("body")))      // the doorway is free
		for (int k = 0; k < body->get_child_count(); k++) if (CollisionShape3D *c = Object::cast_to<CollisionShape3D>(body->get_child(k))) c->set_deferred("disabled", true);
}

Vector2 CityRooms::win_uv(Node3D *p_win, const Vector3 &p_at) {
	const Vector2 sz = p_win->has_meta("size") ? (Vector2)p_win->get_meta("size") : Vector2(1, 1);
	const Vector3 l = p_win->get_global_transform().affine_inverse().xform(p_at);      // (origin: the pane's bottom-left, +X along, +Y up)
	return Vector2(std::clamp(l.x / sz.x, 0.05f, 0.95f), std::clamp(1.0f - l.y / sz.y, 0.05f, 0.95f));
}

void CityRooms::win_cracked(Node3D *p_win, const Vector2 &p_uv) {
	if (GeometryInstance3D *p = Object::cast_to<GeometryInstance3D>(p_win->get_node_or_null(NodePath("pane")))) {
		p->set_instance_shader_parameter("crack", 1.0f); p->set_instance_shader_parameter("crack_at", p_uv);
	}
}

void CityRooms::win_broken(Node3D *p_win, const Vector2 &p_uv, bool p_burst) {
	if (Node3D *a = Object::cast_to<Node3D>(p_win->get_node_or_null(NodePath("pane")))) a->set_visible(false);
	if (Node3D *b = Object::cast_to<Node3D>(p_win->get_node_or_null(NodePath("remnant")))) b->set_visible(true);
	if (Node *body = p_win->get_node_or_null(NodePath("body")))
		for (int k = 0; k < body->get_child_count(); k++) if (CollisionShape3D *c = Object::cast_to<CollisionShape3D>(body->get_child(k))) c->set_deferred("disabled", true);
	if (!p_burst) return;
	const Vector2 sz = p_win->has_meta("size") ? (Vector2)p_win->get_meta("size") : Vector2(1, 1);
	const Vector3 hit_local(p_uv.x * sz.x, (1.0f - p_uv.y) * sz.y, 0.0f);
	if (CPUParticles3D *sh = Object::cast_to<CPUParticles3D>(p_win->get_node_or_null(NodePath("shards")))) {
		sh->set_position(hit_local); sh->restart(); sh->set_emitting(true);
	}
	const Vector3 at = get_global_transform().affine_inverse().xform(p_win->get_global_transform().xform(hit_local));
	elsfx::play(this, "res://audio/sfx/car/glass_shatter_", -3.0f, 0.06f, at, 35.0f);
	shard_bursts++;
}

bool CityRooms::interact_door(const Vector3 &p_at, float p_radius) {
	Leaf *best = nullptr; Room *brm = nullptr; float bd = p_radius; Vector3 bmid;
	for (Room &rm : rooms) {
		if (rm.state != 2) continue;
		for (Leaf &f : rm.leaves) {
			Node3D *l = Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(f.node)));
			Node3D *par = l ? Object::cast_to<Node3D>(l->get_parent()) : nullptr;
			if (!l || !par || f.broken) continue;
			const Vector3 mid = par->get_global_transform().xform(l->get_position() + f.mid);
			const float d = mid.distance_to(p_at);
			if (d < bd) { bd = d; best = &f; brm = &rm; bmid = mid; }
		}
	}
	if (!best) return false;
	const bool open = best->amount < 0.5f;
	best->hold = open ? 1 : 2;
	if (open && best->amount <= 0.001f) {
		Node3D *l = Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(best->node)));
		const Vector3 outw = Object::cast_to<Node3D>(l->get_parent())->get_global_transform().basis.xform(best->out_dir);
		best->dir = (p_at - bmid).dot(outw) > 0.0f ? -1.0f : 1.0f;
	}
	(void)brm;
	emit_signal("door_toggled", best->bid, open);
	return true;
}

String CityRooms::damage_at(const Vector3 &p_at, float p_amount, float p_radius) {
	const Dictionary r = hit_opening(p_at, p_amount, p_radius, false);
	return r.is_empty() ? String() : String(r.get("bid", ""));
}

Dictionary CityRooms::hit_opening(const Vector3 &p_at, double p_amount_d, double p_radius, bool p_hole) {
	const float p_amount = (float)p_amount_d;
	Leaf *bl = nullptr; Win *bw = nullptr; float bd = (float)p_radius;
	for (Room &rm : rooms) {
		if (rm.state != 2) continue;
		for (Leaf &f : rm.leaves) {
			Node3D *l = Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(f.node)));
			Node3D *par = l ? Object::cast_to<Node3D>(l->get_parent()) : nullptr;
			if (!l || !par || f.broken) continue;
			const float d = par->get_global_transform().xform(l->get_position() + f.mid).distance_to(p_at);
			if (d < bd) { bd = d; bl = &f; bw = nullptr; }
		}
		for (Win &w : rm.wins) {
			Node3D *n = Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(w.node)));
			if (!n || w.broken) continue;
			const Vector2 sz = n->has_meta("size") ? (Vector2)n->get_meta("size") : Vector2(1, 1);
			const Vector3 c = n->get_global_transform().xform(Vector3(sz.x * 0.5f, sz.y * 0.5f, 0));      // (window origin: its lower corner, +X along it)
			const float d = std::max(0.0f, c.distance_to(p_at) - sz.x * 0.5f);
			if (d < bd) { bd = d; bw = &w; bl = nullptr; }
		}
	}
	Dictionary r;
	if (bl) {
		bl->hp = std::max(0.0f, bl->hp - p_amount);
		Dictionary st; st["hp"] = bl->hp; st["state"] = bl->hp <= 0.0f ? "broken" : "closed";
		breakables[bl->bid] = st;
		const bool now = bl->hp <= 0.0f;
		if (now) {
			bl->broken = true; bl->amount = 0.0f;
			if (Node3D *l = Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(bl->node)))) leaf_broken(l);
			emit_signal("door_broken", bl->bid, p_at);
		}
		r["bid"] = bl->bid; r["what"] = "door"; r["state"] = st["state"]; r["now"] = now; r["hp"] = bl->hp;
		return r;
	}
	if (bw) {
		Node3D *n = Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(bw->node)));
		bw->hp = std::max(0.0f, bw->hp - p_amount);
		const bool scripted = n && n->has_method("damage");
		if (scripted) n->call("damage", p_amount, p_at);      // (a preview with its script: it does the crack, shards, sound)
		if (!bw->cracked && !bw->broken && n) bw->uv = win_uv(n, p_at);
		// a bullet: a hole where it went through (the pane holds MAX_HOLES; after that a new one replaces the oldest)
		if (p_hole && n && bw->hp > 0.0f) {
			if ((int)bw->holes.size() >= MAX_HOLES) bw->holes.erase(bw->holes.begin());
			bw->holes.push_back(win_uv(n, p_at));
			if (!scripted) win_holes(n, bw->holes);
		}
		bool now = false;
		if (bw->hp <= 0.0f) {
			bw->broken = true; now = true;
			if (n && !scripted) win_broken(n, p_hole ? win_uv(n, p_at) : bw->uv, true);
			emit_signal("window_broken", bw->bid, p_at);
		} else if (bw->hp <= WINDOW_CRACK_HP && !bw->cracked) {
			bw->cracked = true;
			if (p_hole && n) bw->uv = win_uv(n, p_at);      // (the star round the hole that cracked it)
			if (n && !scripted) {
				win_cracked(n, bw->uv);
				elsfx::play(this, "res://audio/sfx/door/door_glass_close_", -10.0f, 0.1f, get_global_transform().affine_inverse().xform(p_at), 20.0f);
			}
			emit_signal("window_cracked", bw->bid, p_at);
		}
		Dictionary st; st["hp"] = bw->hp; st["state"] = bw->broken ? "broken" : (bw->cracked ? "cracked" : "intact");
		Array uv; uv.push_back(bw->uv.x); uv.push_back(bw->uv.y); st["uv"] = uv;
		Array hs; for (const Vector2 &h : bw->holes) { hs.push_back(h.x); hs.push_back(h.y); }
		st["holes"] = hs;
		breakables[bw->bid] = st;
		r["bid"] = bw->bid; r["what"] = "window"; r["state"] = st["state"]; r["now"] = now; r["hp"] = bw->hp; r["holes"] = (int)bw->holes.size();
		return r;
	}
	return r;
}

void CityRooms::win_holes(Node3D *p_win, const std::vector<Vector2> &p_holes) {
	GeometryInstance3D *p = Object::cast_to<GeometryInstance3D>(p_win->get_node_or_null(NodePath("pane")));
	if (!p) return;
	for (int k = 0; k < 4; k++) {
		Vector4 v(-9.0f, -9.0f, -9.0f, -9.0f);
		if (2 * k < (int)p_holes.size()) { v.x = p_holes[2 * k].x; v.y = p_holes[2 * k].y; }
		if (2 * k + 1 < (int)p_holes.size()) { v.z = p_holes[2 * k + 1].x; v.w = p_holes[2 * k + 1].y; }
		p->set_instance_shader_parameter(StringName(vformat("holes%d", k)), v);
	}
	p->set_instance_shader_parameter("hole_n", (float)p_holes.size());
}

Dictionary CityRooms::get_state() const {
	Dictionary d; int known = 0;
	for (const Room &rm : rooms) if (!rm.cell.is_empty()) known++;
	d["known"] = known; d["live"] = live; d["loading"] = loading; d["woken_total"] = woken;
	d["door_sounds"] = door_sounds; d["tone_room"] = tone_room; d["shard_bursts"] = shard_bursts;
	return d;
}

void CityRooms::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_stream", "stream"), &CityRooms::set_stream);
	ClassDB::bind_method(D_METHOD("_on_cell_in", "key"), &CityRooms::_on_cell_in);
	ClassDB::bind_method(D_METHOD("_on_cell_out", "key"), &CityRooms::_on_cell_out);
	ClassDB::bind_method(D_METHOD("get_state"), &CityRooms::get_state);
	ClassDB::bind_method(D_METHOD("interact_door", "at", "radius"), &CityRooms::interact_door, DEFVAL(2.0));
	ClassDB::bind_method(D_METHOD("damage_at", "at", "amount", "radius"), &CityRooms::damage_at, DEFVAL(1.0));
	ClassDB::bind_method(D_METHOD("hit_opening", "at", "amount", "radius", "hole"), &CityRooms::hit_opening, DEFVAL(0.6), DEFVAL(false));
	ClassDB::bind_method(D_METHOD("get_breakables"), &CityRooms::get_breakables);
	ClassDB::bind_method(D_METHOD("set_breakables", "states"), &CityRooms::set_breakables);
	ADD_SIGNAL(MethodInfo("door_toggled", PropertyInfo(Variant::STRING, "bid"), PropertyInfo(Variant::BOOL, "open")));
	ADD_SIGNAL(MethodInfo("door_broken", PropertyInfo(Variant::STRING, "bid"), PropertyInfo(Variant::VECTOR3, "at")));
	ADD_SIGNAL(MethodInfo("window_broken", PropertyInfo(Variant::STRING, "bid"), PropertyInfo(Variant::VECTOR3, "at")));
	ADD_SIGNAL(MethodInfo("window_cracked", PropertyInfo(Variant::STRING, "bid"), PropertyInfo(Variant::VECTOR3, "at")));
}

} // namespace godot
