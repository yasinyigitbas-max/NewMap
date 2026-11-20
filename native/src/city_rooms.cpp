// CityRooms: see city_rooms.h.
#include "city_rooms.h"
#include "city_stream.h"
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/concave_polygon_shape3d.hpp>
#include <godot_cpp/classes/omni_light3d.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/static_body3d.hpp>
#include <godot_cpp/classes/spot_light3d.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <algorithm>
#include <cmath>

namespace godot {

void CityRooms::set_stream(Object *p_stream) {
	stream_id = p_stream ? (uint64_t)p_stream->get_instance_id() : 0;
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
	rm.state = 1; loading++;
}

void CityRooms::finish(int i) {
	Room &rm = rooms[i];
	ResourceLoader *rl = ResourceLoader::get_singleton();
	Node3D *bd = Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(rm.building)));
	Ref<PackedScene> ps = rl->load_threaded_get(rm.scn);
	loading--;
	if (!bd || ps.is_null()) { rm.state = 0; return; }
	Node3D *root = Object::cast_to<Node3D>(ps->instantiate());
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
		rm.leaves.push_back(f);
	}
	// the lights: faded out with distance, no shadows (a phone's light grid holds 32)
	const TypedArray<Node> lights = root->find_children("*", "Light3D", true, false);
	for (int k = 0; k < lights.size(); k++) {
		Light3D *L = Object::cast_to<Light3D>(lights[k]);
		if (!L) continue;
		L->set_shadow(false); L->set_enable_distance_fade(true); L->set_distance_fade_begin(LIGHT_M - 10.0f); L->set_distance_fade_length(10.0f);
	}
	// its collision (the bake's: the shell's faces and the furniture's boxes, room frame)
	if (!rm.col.is_empty() && rl->exists(rm.col)) {
		Ref<Resource> cd = rl->load(rm.col);
		if (cd.is_valid()) {
			const PackedVector3Array faces = cd->get("data");
			if (faces.size() >= 3) {
				StaticBody3D *body = memnew(StaticBody3D); body->set_name("room_col"); body->set_collision_layer(1); body->set_collision_mask(0);
				Ref<ConcavePolygonShape3D> sh; sh.instantiate(); sh->set_backface_collision_enabled(true); sh->set_faces(faces);
				const uint32_t ow = body->create_shape_owner(body); body->shape_owner_add_shape(ow, sh);
				root->add_child(body);
			}
		}
	}
	root->set_name("room");
	bd->add_child(root);
	rm.node = (uint64_t)root->get_instance_id(); rm.state = 2; live++; woken++;
}

void CityRooms::sleep(int i) {
	Room &rm = rooms[i];
	Node *root = Object::cast_to<Node>(ObjectDB::get_instance(ObjectID(rm.node)));
	CityStream *st = Object::cast_to<CityStream>(ObjectDB::get_instance(ObjectID(stream_id)));
	if (root) {
		if (Node *p = root->get_parent()) p->remove_child(root);
		if (st) st->give_away(root); else memdelete(root);
	}
	rm.node = 0; rm.leaves.clear(); rm.state = 0; live--;
}

// ---------------------------------------------------------------- the doors
void CityRooms::doors(double p_delta, const Vector3 &cam) {
	for (Room &rm : rooms) {
		if (rm.state != 2) continue;
		for (Leaf &f : rm.leaves) {
			Node3D *l = Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(f.node)));
			Node3D *par = l ? Object::cast_to<Node3D>(l->get_parent()) : nullptr;
			if (!l || !par) continue;
			const Vector3 mid = par->get_global_transform().xform(l->get_position() + f.mid);
			const float want = cam.distance_to(mid) < DOOR_TRIGGER ? 1.0f : 0.0f;
			if (f.amount <= 0.001f && want > 0.0f) {   // the side: away from the viewer (kept until shut again)
				const Vector3 outw = par->get_global_transform().basis.xform(f.out_dir);
				f.dir = (cam - mid).dot(outw) > 0.0f ? -1.0f : 1.0f;
			}
			const float step = DOOR_SPEED * (float)p_delta;
			f.amount = want > f.amount ? std::min(want, f.amount + step) : std::max(want, f.amount - step);
			const float e = f.amount * f.amount * (3.0f - 2.0f * f.amount);
			Vector3 rot = l->get_rotation(); rot.y = DOOR_MAX_DEG * 0.017453292f * e * f.sign * f.dir; l->set_rotation(rot);
		}
	}
}

void CityRooms::_process(double p_delta) {
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
	}
	doors(p_delta, cp);
}

void CityRooms::_exit_tree() {
	ResourceLoader *rl = ResourceLoader::get_singleton();
	for (Room &rm : rooms) if (rm.state == 1) (void)rl->load_threaded_get(rm.scn);   // (a pending load taken so the loader lets it go)
}

Dictionary CityRooms::get_state() const {
	Dictionary d; int known = 0;
	for (const Room &rm : rooms) if (!rm.cell.is_empty()) known++;
	d["known"] = known; d["live"] = live; d["loading"] = loading; d["woken_total"] = woken;
	return d;
}

void CityRooms::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_stream", "stream"), &CityRooms::set_stream);
	ClassDB::bind_method(D_METHOD("_on_cell_in", "key"), &CityRooms::_on_cell_in);
	ClassDB::bind_method(D_METHOD("_on_cell_out", "key"), &CityRooms::_on_cell_out);
	ClassDB::bind_method(D_METHOD("get_state"), &CityRooms::get_state);
}

} // namespace godot
