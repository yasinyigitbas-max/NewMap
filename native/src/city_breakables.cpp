// CityBreakables: see city_breakables.h.
#include "perf_marks.h"
#include "city_breakables.h"
#include "el_sfx.h"
#include "city_stream.h"
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/collision_shape3d.hpp>
#include <godot_cpp/classes/convex_polygon_shape3d.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/multi_mesh.hpp>
#include <godot_cpp/classes/multi_mesh_instance3d.hpp>
#include <godot_cpp/classes/physics_server3d.hpp>
#include <godot_cpp/classes/rigid_body3d.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/window.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <algorithm>
#include <cmath>

namespace godot {

static float kind_mass(const String &k) {   // the old game's masses
	if (k.contains("cone")) return 3.0f;
	if (k.contains("bollard")) return 30.0f;
	if (k.contains("mailbox")) return 25.0f;
	if (k.contains("meter")) return 25.0f;
	if (k.contains("bin") || k.contains("newsbox")) return 14.0f;
	return 9.0f;   // signs
}

void CityBreakables::set_stream(Object *p_stream) {
	stream_id = p_stream ? (uint64_t)p_stream->get_instance_id() : 0;
	if (!p_stream) return;
	p_stream->connect("cell_in", Callable(this, "_on_cell_in"));
	p_stream->connect("cell_out", Callable(this, "_on_cell_out"));
	set_process(true);
}

void CityBreakables::make() {
	if (made || !is_inside_tree()) return;
	made = true;
	PhysicsServer3D *ps = PhysicsServer3D::get_singleton();
	const RID space = get_world_3d()->get_space();
	for (int k = 0; k < POOL; k++) {
		pool_body[k] = ps->body_create(); ps->body_set_mode(pool_body[k], PhysicsServer3D::BODY_MODE_STATIC);
		ps->body_set_collision_layer(pool_body[k], 1); ps->body_set_collision_mask(pool_body[k], 0);
		ps->body_set_space(pool_body[k], space); pool_item[k] = -1;
	}
	for (int k = 0; k < DEBRIS; k++) {
		Debris &d = debris[k];
		d.body = memnew(RigidBody3D); d.mi = memnew(MeshInstance3D); d.cs = memnew(CollisionShape3D);
		d.body->add_child(d.mi); d.body->add_child(d.cs);
		d.body->set_collision_layer(1); d.body->set_collision_mask(1 | 16);   // the city and the traffic's boxes
		d.body->set_freeze_enabled(true); d.body->set_visible(false); d.body->set_process_mode(PROCESS_MODE_DISABLED);
		add_child(d.body); d.body->set_as_top_level(true); d.body->set_global_position(Vector3(0, -900.0f - (float)k * 3.0f, 0));
	}
	set_process(true);
}

void CityBreakables::_exit_tree() {
	if (!made) return;
	PhysicsServer3D *ps = PhysicsServer3D::get_singleton();
	for (int k = 0; k < POOL; k++) if (pool_body[k].is_valid()) { ps->free_rid(pool_body[k]); pool_body[k] = RID(); }
	for (const KeyValue<int64_t, RID> &kv : shape_cache) if (kv.value.is_valid()) ps->free_rid(kv.value);
	shape_cache.clear();
	made = false;
}

RID CityBreakables::shape_for(const PackedVector3Array &p_pts) {
	int64_t h = (int64_t)p_pts.size();
	for (int i = 0; i < p_pts.size(); i++) h = h * 1000003 + (int64_t)std::lround(p_pts[i].x * 1000.0f) * 31 + (int64_t)std::lround(p_pts[i].y * 1000.0f) * 17 + (int64_t)std::lround(p_pts[i].z * 1000.0f);
	if (shape_cache.has(h)) return shape_cache[h];
	PhysicsServer3D *ps = PhysicsServer3D::get_singleton();
	const RID s = ps->convex_polygon_shape_create(); ps->shape_set_data(s, p_pts);
	shape_cache[h] = s;
	return s;
}

void CityBreakables::set_instance(Item &it, bool p_shown) {
	MultiMeshInstance3D *mmi = Object::cast_to<MultiMeshInstance3D>(ObjectDB::get_instance(ObjectID(it.mmi)));
	if (!mmi || mmi->get_multimesh().is_null()) return;
	Transform3D local = mmi->get_global_transform().affine_inverse() * it.home;
	if (!p_shown) local.basis = Basis().scaled(Vector3(0.0001f, 0.0001f, 0.0001f)), local.origin.y -= 50.0f;
	mmi->get_multimesh()->set_instance_transform(it.idx, local);
}

// ---------------------------------------------------------------- the cells
void CityBreakables::add_cell(const String &p_key) {
	CityStream *st = Object::cast_to<CityStream>(ObjectDB::get_instance(ObjectID(stream_id)));
	if (!st) return;
	Node3D *cn = st->cell_node(p_key);
	if (!cn) return;
	make();
	std::vector<int> &list = by_cell[p_key];
	// the bake puts them straight under the cell's Props node (bake_runtime.gd): no search of the whole cell (25 ms on the
	// phone: pb4_zones' 'cell add' with find_children)
	Node *props = cn->get_node_or_null(NodePath("Props"));
	if (!props) return;
	const int nch = props->get_child_count();
	for (int f = 0; f < nch; f++) {
		Node *ch = props->get_child(f);
		if (!String(ch->get_name()).begins_with("brk_")) continue;
		MultiMeshInstance3D *mmi = Object::cast_to<MultiMeshInstance3D>(ch);
		if (!mmi || mmi->get_multimesh().is_null() || mmi->get_multimesh()->get_mesh().is_null()) continue;
		const String kind = mmi->has_meta("brk_kind") ? String(mmi->get_meta("brk_kind")) : String(mmi->get_name());
		const Array cols = mmi->has_meta("brk_cols") ? Array(mmi->get_meta("brk_cols")) : Array();
		const AABB ab = mmi->get_multimesh()->get_mesh()->get_aabb();
		const Ref<MultiMesh> mm = mmi->get_multimesh();
		// the transforms read from the buffer in ONE call: get_instance_transform(i) asks the rendering server each time
		// (and with a render thread syncs with it each time: 80-150 ms for one cell on the PC, 20 Nov)
		// the places from the bake's meta "brk_xfs" (no rendering-server read: with a render thread one waits for it, 31-42 ms
		// a cell on the PC); an older bake: the buffer, read in one call
		const Array xfs = mmi->has_meta("brk_xfs") ? Array(mmi->get_meta("brk_xfs")) : Array();
		PackedFloat32Array buf; int stride = 12;
		if (xfs.is_empty()) { buf = mm->get_buffer(); stride = 12 + (mm->is_using_colors() ? 4 : 0) + (mm->is_using_custom_data() ? 4 : 0); }
		const Transform3D gx = mmi->get_global_transform();
		const int ninst = xfs.is_empty() ? std::min((int)mm->get_instance_count(), (int)(buf.size() / stride)) : (int)xfs.size();
		for (int i = 0; i < ninst; i++) {
			Item it; it.mmi = (uint64_t)mmi->get_instance_id(); it.idx = i; it.cell = p_key;
			Transform3D lx;
			if (!xfs.is_empty()) lx = xfs[i];
			else {
				const float *q = buf.ptr() + (int64_t)i * stride;   // a 3 x 4 matrix, row by row: basis row, origin
				lx = Transform3D(Basis(q[0], q[1], q[2], q[4], q[5], q[6], q[8], q[9], q[10]), Vector3(q[3], q[7], q[11]));
			}
			it.home = gx * lx; it.at = it.home.origin;
			it.radius = std::max(0.15f, 0.5f * std::max(ab.size.x, ab.size.z)); it.height = std::max(ab.size.y, 0.3f); it.mass = kind_mass(kind);
			float best = 0.6f * 0.6f;   // its collider: the nearest of the node's within 0.6 m
			for (int c = 0; c < cols.size(); c++) {
				const Array e = cols[c]; const Transform3D cx = e[1];
				const float d2 = Vector2(cx.origin.x - it.at.x, cx.origin.z - it.at.z).length_squared();
				if (d2 < best) { best = d2; it.pts = e[0]; it.col_xf = cx; it.has_col = true; }
			}
			int slot;
			if (!free_slots.empty()) { slot = free_slots.back(); free_slots.pop_back(); items[slot] = it; }
			else { slot = (int)items.size(); items.push_back(it); }
			list.push_back(slot);
		}
	}
}

void CityBreakables::drop_cell(const String &p_key) {
	for (size_t k = 0; k < arriving.size(); k++) if (arriving[k] == p_key) { arriving.erase(arriving.begin() + (long)k); break; }   // (left before it was looked at)
	if (!by_cell.has(p_key)) return;
	PhysicsServer3D *ps = PhysicsServer3D::get_singleton();
	for (int i : by_cell[p_key]) {
		Item &it = items[i];
		if (it.pool >= 0) { ps->body_clear_shapes(pool_body[it.pool]); pool_item[it.pool] = -1; it.pool = -1; }
		if (it.debris >= 0) { Debris &d = debris[it.debris]; d.item = -1; d.body->set_freeze_enabled(true); d.body->set_visible(false); d.body->set_process_mode(PROCESS_MODE_DISABLED); it.debris = -1; }
		if (it.broken) broken_n--;
		it = Item(); it.mmi = 0;
		free_slots.push_back(i);
	}
	by_cell.erase(p_key);
}

// ---------------------------------------------------------------- every frame
void CityBreakables::pool_update(const Vector3 &cam) {
	// the POOL standing props nearest the camera within POOL_R get colliders (re-chosen every 10th frame)
	PhysicsServer3D *ps = PhysicsServer3D::get_singleton();
	std::vector<std::pair<float, int>> near;
	for (const KeyValue<String, std::vector<int>> &kv : by_cell)
		for (int i : kv.value) {
			const Item &it = items[i];
			if (!it.mmi || it.broken || !it.has_col) continue;
			const float d2 = it.at.distance_squared_to(cam);
			if (d2 < POOL_R * POOL_R) near.push_back({ d2, i });
		}
	std::sort(near.begin(), near.end());
	if ((int)near.size() > POOL) near.resize(POOL);
	std::vector<bool> keep(POOL, false);
	for (auto &n : near) if (items[n.second].pool >= 0) keep[items[n.second].pool] = true;
	for (int k = 0; k < POOL; k++) if (!keep[k] && pool_item[k] >= 0) {   // let go of the ones no longer wanted
		if (pool_item[k] < (int)items.size()) items[pool_item[k]].pool = -1;
		ps->body_clear_shapes(pool_body[k]); pool_item[k] = -1;
	}
	for (auto &n : near) {
		Item &it = items[n.second];
		if (it.pool >= 0) continue;
		int k = 0; while (k < POOL && pool_item[k] >= 0) k++;
		if (k >= POOL) break;
		ps->body_clear_shapes(pool_body[k]);
		ps->body_add_shape(pool_body[k], shape_for(it.pts));
		ps->body_set_state(pool_body[k], PhysicsServer3D::BODY_STATE_TRANSFORM, it.col_xf);
		pool_item[k] = n.second; it.pool = k;
	}
}

void CityBreakables::hits(const Vector3 &cam) {
	struct Car { Vector3 at, vel; float half_len, half_w; };
	std::vector<Car> cars;
	SceneTree *tr = get_tree();
	const TypedArray<Node> veh = tr->get_nodes_in_group("vehicles");
	for (int i = 0; i < veh.size(); i++) {
		Node3D *v = Object::cast_to<Node3D>(veh[i]);
		RigidBody3D *rb = Object::cast_to<RigidBody3D>(veh[i]);
		if (!v || !rb || !rb->is_class("CityCar") || v->get_global_position().distance_squared_to(cam) > 80.0f * 80.0f) continue;   // (cars only: the old game's rule)
		cars.push_back(Car{ v->get_global_position(), rb->get_linear_velocity(), 2.4f, 1.0f });
	}
	// the traffic, found once; where there is none (the rig's drives), looked for again only every 2 s: the search walks the
	// whole tree (~29,000 nodes) and ran every other frame, 12-16 ms (phone, 20 Nov)
	if (!traffic_id && (frame - traffic_look) >= 120) {
		traffic_look = frame;
		const TypedArray<Node> t = tr->get_root()->find_children("*", "CityTraffic", true, false);
		if (t.size() > 0) traffic_id = (uint64_t)Object::cast_to<Object>(t[0])->get_instance_id();
	}
	if (Object *traffic = traffic_id ? ObjectDB::get_instance(ObjectID(traffic_id)) : nullptr) {
		const Array near = traffic->call("cars_near", cam, 60.0);
		for (int i = 0; i < near.size(); i++) {
			const Dictionary d = near[i];
			if ((bool)d.get("bike", false)) continue;
			const float yaw = (float)(double)d.get("yaw", 0.0), sp = (float)(double)d.get("speed", 0.0);
			cars.push_back(Car{ (Vector3)d.get("at", Vector3()), Vector3(std::sin(yaw), 0, std::cos(yaw)) * sp, 2.3f, 0.95f });
		}
	}
	for (const Car &c : cars) {
		const float sp = Vector2(c.vel.x, c.vel.z).length();
		if (sp < BREAK_SPEED) continue;
		const Vector3 fw = Vector3(c.vel.x, 0, c.vel.z) / sp, sd(fw.z, 0, -fw.x);
		// only the cell under the car and the eight round it (was: every prop of every loaded cell, 3-6 ms on the PC)
		const int cx = (int)std::floor(c.at.x / 200.0f), cz = (int)std::floor(c.at.z / 200.0f);
		for (int ox = -1; ox <= 1; ox++) for (int oz = -1; oz <= 1; oz++) {
			const std::vector<int> *lst = by_cell.getptr(vformat("%d_%d", cx + ox, cz + oz));
			if (!lst) continue;
			for (int i : *lst) {
				Item &it = items[i];
				if (!it.mmi || it.broken) continue;
				const Vector3 d = it.at - c.at;
				if (d.x * d.x + d.z * d.z > 16.0f || std::fabs(d.y) > 2.5f) continue;
				const float along = d.dot(fw), across = d.dot(sd);   // inside the car's box (its nose a little ahead) grown by the prop's radius
				if (std::fabs(along) < c.half_len + 0.35f + it.radius && std::fabs(across) < c.half_w + it.radius) knock(i, c.vel);
			}
		}
	}
}

void CityBreakables::knock(int i, const Vector3 &p_vel) {
	Item &it = items[i];
	int k = 0; while (k < DEBRIS && debris[k].item >= 0) k++;
	if (k >= DEBRIS) {   // all in use: the oldest goes back first
		int old = 0; for (int q = 1; q < DEBRIS; q++) if (debris[q].t > debris[old].t) old = q;
		put_back(debris[old].item); k = old;
	}
	MultiMeshInstance3D *mmi = Object::cast_to<MultiMeshInstance3D>(ObjectDB::get_instance(ObjectID(it.mmi)));
	if (!mmi) return;
	it.broken = true; it.down_t = 0.0f; broken_n++;
	{   // its sound (el_sfx.h): a bin, a fence, or anything else rings like a pole
		const String kind = (mmi->has_meta("brk_kind") ? String(mmi->get_meta("brk_kind")) : String(mmi->get_name())).to_lower();
		const char *set = kind.contains("bin") || kind.contains("newsbox") || kind.contains("trash") ? "hit_bin_" : (kind.contains("fence") || kind.contains("rail") || kind.contains("barrier") ? "hit_fence_" : "hit_pole_");
		elsfx::play(this, String("res://audio/sfx/car/") + String(set), std::min(-8.0f + p_vel.length() * 0.5f, 0.0f), 0.06f, to_local(it.at + Vector3(0, 0.6f, 0)), 50.0f);
	}
	set_instance(it, false);
	if (it.pool >= 0) { PhysicsServer3D::get_singleton()->body_clear_shapes(pool_body[it.pool]); pool_item[it.pool] = -1; it.pool = -1; }
	Debris &d = debris[k];
	d.item = i; d.t = 0.0f; it.debris = k;
	d.mi->set_mesh(mmi->get_multimesh()->get_mesh());
	d.mi->set_material_override(mmi->get_material_override());
	Ref<ConvexPolygonShape3D> cs; cs.instantiate();
	if (it.has_col) cs->set_points(it.pts);
	else { PackedVector3Array box; const float r = it.radius, h = it.height; for (int q = 0; q < 8; q++) box.push_back(Vector3((q & 1) ? r : -r, (q & 2) ? h : 0.0f, (q & 4) ? r : -r)); cs->set_points(box); }
	d.cs->set_shape(cs);
	d.cs->set_transform(it.has_col ? it.home.affine_inverse() * it.col_xf : Transform3D());
	d.body->set_process_mode(PROCESS_MODE_INHERIT); d.body->set_visible(true);
	d.body->set_global_transform(it.home);
	d.body->set_mass(it.mass);
	d.body->set_freeze_enabled(false);
	const float sp = p_vel.length();
	const Vector3 push = p_vel * 0.85f + Vector3(0, 1.5f + 0.08f * sp, 0);
	d.body->set_linear_velocity(push);
	d.body->set_angular_velocity(Vector3(p_vel.z, 0, -p_vel.x).normalized() * std::min(sp * 0.6f, 9.0f));   // it tips over its foot, away from the car
}

void CityBreakables::put_back(int i) {
	if (i < 0 || i >= (int)items.size()) return;
	Item &it = items[i];
	if (it.debris >= 0) { Debris &d = debris[it.debris]; d.item = -1; d.body->set_freeze_enabled(true); d.body->set_visible(false); d.body->set_process_mode(PROCESS_MODE_DISABLED); d.body->set_global_position(Vector3(0, -900.0f - (float)it.debris * 3.0f, 0)); it.debris = -1; }
	if (it.broken) { it.broken = false; broken_n--; set_instance(it, true); }
}

void CityBreakables::_process(double p_delta) {
	pm::Scope _pm(pm::BREAKABLES);   // (the slow-frame marks, perf_marks.h)
	if (!arriving.empty()) { pm::Scope _c(pm::BRK_CELL); const String k = arriving.front(); arriving.erase(arriving.begin()); add_cell(k); }   // one arrived cell a frame
	if (!made || items.empty()) return;
	Viewport *vp = get_viewport();
	Camera3D *cam = vp ? vp->get_camera_3d() : nullptr;
	if (!cam) return;
	const Vector3 cp = cam->get_global_position();
	frame++;
	if (frame % 10 == 0) { pm::Scope _p(pm::BRK_POOL); pool_update(cp); }
	if (frame % 2 == 0) { pm::Scope _h(pm::BRK_HITS); hits(cp); }
	// put back what lies out of sight long enough
	for (int k = 0; k < DEBRIS; k++) {
		Debris &d = debris[k];
		if (d.item < 0) continue;
		d.t += (float)p_delta;
		if (d.t < RESET_S) continue;
		const Item &it = items[d.item];
		if (!cam->is_position_in_frustum(it.at + Vector3(0, 0.5f, 0)) && !cam->is_position_in_frustum(d.body->get_global_position())) put_back(d.item);
	}
}

Dictionary CityBreakables::get_state() const {
	Dictionary d; int with_col = 0, pooled = 0, deb = 0;
	for (const Item &it : items) if (it.mmi && it.has_col) with_col++;
	for (int k = 0; k < POOL; k++) if (pool_item[k] >= 0) pooled++;
	for (int k = 0; k < DEBRIS; k++) if (debris[k].item >= 0) deb++;
	d["props"] = (int)items.size() - (int)free_slots.size(); d["with_collider"] = with_col; d["colliders_now"] = pooled; d["knocked"] = broken_n; d["debris"] = deb;
	return d;
}

void CityBreakables::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_stream", "stream"), &CityBreakables::set_stream);
	ClassDB::bind_method(D_METHOD("_on_cell_in", "key"), &CityBreakables::_on_cell_in);
	ClassDB::bind_method(D_METHOD("_on_cell_out", "key"), &CityBreakables::_on_cell_out);
	ClassDB::bind_method(D_METHOD("get_state"), &CityBreakables::get_state);
}

} // namespace godot
