// CityStream: see city_stream.h (a port of tools/city/bake/city_stream.gd; the comments there hold the measurements).
#include "city_stream.h"
#include "perf_marks.h"
#include "city_breakables.h"
#include "city_skyline.h"
#include "city_rooms.h"
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/collision_object3d.hpp>
#include <godot_cpp/classes/box_shape3d.hpp>
#include <godot_cpp/classes/collision_shape3d.hpp>
#include <godot_cpp/classes/concave_polygon_shape3d.hpp>
#include <godot_cpp/classes/convex_polygon_shape3d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/geometry_instance3d.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/physics_server3d.hpp>
#include <godot_cpp/classes/rendering_device.hpp>
#include <godot_cpp/classes/rendering_server.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/callable_method_pointer.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <algorithm>
#include <cmath>

namespace godot {

static const char *RT_SH = "res://map_dc/coronado/city_kit/shaders/rt/";
static const char *TIER_SHADERS[5] = { "rt_bldg", "rt_prop_", "rt_foliage_", "rt_far_cut", "rt_far_solid" };
static const int ADD_KEEP = 4096, REAP_BATCH = 24;
static uint64_t usec() { return Time::get_singleton()->get_ticks_usec(); }
static uint64_t msec() { return Time::get_singleton()->get_ticks_msec(); }

CityStream::CityStream() {}
CityStream::~CityStream() {}

// ---------------------------------------------------------------- start
void CityStream::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) return;
	stats["in"] = 0; stats["out"] = 0; stats["dropped"] = 0; stats["add_ms_worst"] = 0.0; stats["remove_ms_worst"] = 0.0;
	stats["ready_ms_worst"] = 0.0; stats["ready_ms_sum"] = 0.0; stats["capped"] = 0; stats["bodies"] = 0; stats["body_ms_worst"] = 0.0; stats["body_late"] = 0;
	const String mp = runtime_dir + "manifest.json";
	if (FileAccess::file_exists(mp)) { const Variant v = JSON::parse_string(FileAccess::get_file_as_string(mp)); if (v.get_type() == Variant::DICTIONARY) manifest = v; }
	cell_m = (float)(double)manifest.get("cell_m", 200.0);
	const Dictionary cd = manifest.get("cells", Dictionary());
	const Array keys = cd.keys();
	for (int i = 0; i < keys.size(); i++) {
		Cell c; c.key = keys[i];
		c.x0 = (float)c.key.get_slice("_", 0).to_int() * cell_m; c.z0 = (float)c.key.get_slice("_", 1).to_int() * cell_m;
		cell_index[c.key] = (int)cells.size(); cells.push_back(c);
	}
	ResourceLoader *rl = ResourceLoader::get_singleton();
	const Array kp = manifest.get("keep", Array());
	for (int i = 0; i < kp.size(); i++) { const String p = kp[i]; if (rl->exists(p)) keep.push_back(rl->load(p)); }
	map_img = Image::create_empty(MAP, MAP, false, Image::FORMAT_R8); map_img->fill(Color(0, 0, 0));
	map_tex = ImageTexture::create_from_image(map_img);
	RenderingServer::get_singleton()->global_shader_parameter_set("ck_cells_loaded", map_tex);
	if (loader_mode != 0) UtilityFunctions::push_warning("CityStream: loader_mode ", loader_mode, " is the script's comparison mode only; the C++ streamer always uses its own loader threads");
	for (int i = 0; i < std::max(max_loading, 1); i++) {
		Ref<Thread> t; t.instantiate(); t->start(callable_mp(this, &CityStream::loader_loop), Thread::PRIORITY_LOW); loaders.push_back(t);
	}
	if (reap_thread) { reaper.instantiate(); reaper->start(callable_mp(this, &CityStream::reap_loop), Thread::PRIORITY_LOW); }
	const String fp = runtime_dir + "far/far_world.scn";
	if (rl->exists(fp)) {
		Ref<PackedScene> ps = rl->load(fp);
		if (ps.is_valid()) { far_world = Object::cast_to<Node3D>(ps->instantiate()); if (far_world) add_child(far_world); }
	}
	if (skyline) { CitySkyline *sk = memnew(CitySkyline); sk->build(); add_child(sk); }   // San Diego round the horizon: one draw, never culled
	set_far_ground(far_ground);
	set_tiers(tiers, tier_band, arrive_s);
	if (rooms) { CityRooms *rr = memnew(CityRooms); rr->set_name("Rooms"); add_child(rr); rr->set_stream(this); }   // B14
	if (breakables) { CityBreakables *bk = memnew(CityBreakables); bk->set_name("Breakables"); add_child(bk); bk->set_stream(this); }   // B9
	set_process(true);
}

void CityStream::_exit_tree() {
	{ std::lock_guard<std::mutex> l(mx); quit = true; }
	cv.notify_all();
	for (Ref<Thread> &t : loaders) t->wait_to_finish();
	loaders.clear();
	for (auto &d : done) { for (Body &b : d.second.bodies) away(b.marker); away(d.second.node); }
	done.clear();
	if (reaper.is_valid()) {
		{ std::lock_guard<std::mutex> l(rmx); reap_quit = true; }
		rcv.notify_all(); reaper->wait_to_finish(); reaper.unref();
		for (Node *n : reap_q) if (n) memdelete(n);
		reap_q.clear();
	}
	for (Node *n : leaving) if (n) memdelete(n);
	leaving.clear();
	for (Body &b : pending) if (b.marker && !b.marker->is_inside_tree()) memdelete(b.marker);
	pending.clear();
}

// ---------------------------------------------------------------- tiers, far ground, night
void CityStream::set_tiers(bool p_on, double p_band, double p_arrive) {
	tiers = p_on;
	if (p_band >= 0.0) tier_band = std::min(std::max(p_band, 0.0), 8.0);
	if (p_arrive >= 0.0) arrive_s = std::max(p_arrive, 0.0);
	RenderingServer::get_singleton()->global_shader_parameter_set("ck_tier_band", tier_band);
	int n = 0;
	for (int i = 0; i < keep.size(); i++) {
		Ref<ShaderMaterial> m = keep[i];
		if (m.is_null()) continue;
		const uint64_t id = (uint64_t)m->get_instance_id();
		if (!sh_plain.has(id)) {
			Ref<Shader> s = m->get_shader();
			if (s.is_null() || !s->get_path().begins_with(RT_SH)) continue;
			const String f = s->get_path().get_file(); bool hit = false;
			for (const char *pre : TIER_SHADERS) hit = hit || f.begins_with(pre);
			if (!hit) continue;
			sh_plain[id] = s;
		}
		const Ref<Shader> plain = sh_plain[id];
		PackedStringArray d; d.push_back("CK_TIERS");
		m->set_shader(p_on ? shader_variant(plain, d) : plain);
		n++;
	}
	stats["tier_materials"] = n;
	if (!p_on) { for (const KeyValue<int, uint64_t> &kv : ramping) set_texel(kv.key, 1.0f); ramping.clear(); flush_map(); }
}

Ref<Shader> CityStream::shader_variant(const Ref<Shader> &p_plain, const PackedStringArray &p_defines) {
	if (p_plain.is_null()) return p_plain;
	const String key = p_plain->get_path() + "|" + String(",").join(p_defines);
	if (!sh_variants.has(key)) {
		String head = "shader_type spatial;";
		for (int i = 0; i < p_defines.size(); i++) head += "\n#define " + p_defines[i];
		Ref<Shader> sh; sh.instantiate();
		sh->set_code(p_plain->get_code().replace("#include \"", String("#include \"") + RT_SH).replace("shader_type spatial;", head));
		sh_variants[key] = sh;
	}
	return sh_variants[key];
}

Ref<Shader> CityStream::baked_shader(const Ref<ShaderMaterial> &p_m) const {
	if (p_m.is_null()) return Ref<Shader>();
	const uint64_t id = (uint64_t)p_m->get_instance_id();
	return sh_plain.has(id) ? sh_plain[id] : p_m->get_shader();
}

void CityStream::set_far_ground(bool p_on) {
	far_ground = p_on;
	if (far_world) if (Node3D *fg = Object::cast_to<Node3D>(far_world->get_node_or_null(NodePath("far_ground")))) fg->set_visible(p_on);
}

void CityStream::set_night(double v) {
	night = v;
	RenderingServer::get_singleton()->global_shader_parameter_set("ck_night", v);
	for (Cell &c : cells) if (c.state == IN && c.node) apply_night(c.node);
}

void CityStream::apply_night(Node *cell) {
	for (const char *nm : { "glow_halo", "glow_pool" })
		if (Node3D *g = Object::cast_to<Node3D>(cell->get_node_or_null(NodePath(nm)))) g->set_visible(night > 0.02);
}

// ---------------------------------------------------------------- the cells-loaded texture (the far world reads it)
void CityStream::set_texel(int i, float v) {
	const int x = cells[i].key.get_slice("_", 0).to_int() + MAP / 2, z = cells[i].key.get_slice("_", 1).to_int() + MAP / 2;
	if (x < 0 || z < 0 || x >= MAP || z >= MAP) return;
	map_img->set_pixel(x, z, Color(v, 0, 0)); map_dirty = true;
}

void CityStream::mark(int i, bool on) {
	ramping.erase(i);
	if (on && tiers && arrive_s > 0.0) { ramping[i] = usec(); set_texel(i, 1.0f / 255.0f); }
	else set_texel(i, on ? 1.0f : 0.0f);
}

void CityStream::ramp_cells() {
	if (ramping.is_empty()) return;
	const uint64_t now = usec(); std::vector<int> fin;
	for (const KeyValue<int, uint64_t> &kv : ramping) {
		const float r = std::min(std::max((float)((double)(now - kv.value) / (arrive_s * 1.0e6)), 1.0f / 255.0f), 1.0f);
		set_texel(kv.key, r);
		if (r >= 1.0f) fin.push_back(kv.key);
	}
	for (int k : fin) ramping.erase(k);
}

void CityStream::flush_map() { if (map_dirty) { map_tex->update(map_img); map_dirty = false; } }

// ---------------------------------------------------------------- queries
float CityStream::dist(int i, const Vector3 &p) const {
	const Cell &c = cells[i];
	const float dx = std::max(std::max(c.x0 - p.x, p.x - (c.x0 + cell_m)), 0.0f), dz = std::max(std::max(c.z0 - p.z, p.z - (c.z0 + cell_m)), 0.0f);
	return std::sqrt(dx * dx + dz * dz);
}
float CityStream::cell_distance(const String &p_key, const Vector3 &p) const { return cell_index.has(p_key) ? dist(cell_index[p_key], p) : 1.0e9f; }

float CityStream::col_d2(const Vector3 &c) const {
	float d = c.distance_squared_to(focus);
	for (const Vector3 &q : col_pts) d = std::min(d, c.distance_squared_to(q));
	for (const Vector3 &q : prepared) d = std::min(d, c.distance_squared_to(q));
	return d;
}

String CityStream::path_of(int i) const { return runtime_dir + String("cells/cell_") + cells[i].key + String(".scn"); }

int CityStream::loaded_count() const { int n = 0; for (const Cell &c : cells) if (c.state == IN) n++; return n; }

Array CityStream::loading_keys() const {
	Array a;
	for (const Cell &c : cells) if (c.state == LOADING || c.state == BUILDING || c.state == READY) a.push_back(vformat("%s:%d", c.key, c.state));
	return a;
}

int CityStream::leaving_count() const {
	int n = (int)leaving.size() + reaping.load();
	std::lock_guard<std::mutex> l(rmx); n += (int)reap_q.size();
	return n;
}

bool CityStream::busy() const {
	for (const Cell &c : cells) if (c.state == LOADING || c.state == BUILDING || c.state == READY) return true;
	return !pending.empty() || leaving_count() > 0;
}

bool CityStream::is_ready(const Vector3 &p) const {
	for (const Body &e : pending) if (e.centre.distance_to(p) < ready_col_m) return false;
	for (int i = 0; i < (int)cells.size(); i++) if (dist(i, p) <= load_dist && cells[i].state != IN) return false;
	const double stand = col_range <= 0.0 ? 120.0 : std::min(120.0, col_range);
	for (const Body &e : pending) if (e.centre.distance_to(p) < stand) return false;
	return true;
}

Dictionary CityStream::get_cells() const {
	uint64_t sig = 1469598103934665603ull;      // (FNV over every cell's state and node: a few hundred ns)
	for (const Cell &c : cells) { sig = (sig ^ (uint64_t)c.state) * 1099511628211ull; sig = (sig ^ (uint64_t)(uintptr_t)c.node) * 1099511628211ull; }
	if (cells_made && sig == cells_sig) return cells_cache;
	Dictionary d;
	for (const Cell &c : cells) { Dictionary e; e["state"] = c.state; e["node"] = c.node; d[c.key] = e; }
	cells_cache = d; cells_sig = sig; cells_made = true;
	return d;
}

Vector3 CityStream::late_cells(const Vector3 &p) const {
	int l60 = 0, l220 = 0; float deep = 0.0f;
	for (int i = 0; i < (int)cells.size(); i++) {
		if (cells[i].state == IN) continue;
		const float d = dist(i, p);
		if (d < 60.0f) l60++;
		if (d < 220.0f) { l220++; deep = std::max(deep, 220.0f - d); }
	}
	return Vector3((float)l60, (float)l220, deep);
}

PackedFloat32Array CityStream::get_ready_ms() const { PackedFloat32Array a; a.resize((int64_t)v_ready_ms.size()); for (size_t i = 0; i < v_ready_ms.size(); i++) a.set((int64_t)i, v_ready_ms[i]); return a; }
PackedFloat32Array CityStream::get_add_ms() const { PackedFloat32Array a; a.resize((int64_t)v_add_ms.size()); for (size_t i = 0; i < v_add_ms.size(); i++) a.set((int64_t)i, v_add_ms[i]); return a; }

// ---------------------------------------------------------------- collision: the bake's data made into bodies here
int CityStream::col_weight(const Variant &cdv) {
	Object *o = cdv; if (!o) return 0;
	const int kind = (int)o->get("kind"); const PackedVector3Array data = o->get("data");
	return kind == 0 ? (int)data.size() / 3 : (kind == 1 ? (int)data.size() : 1);
}

Ref<Shape3D> CityStream::col_shape(const Variant &cdv) {
	Object *o = cdv; if (!o) return Ref<Shape3D>();
	Ref<Shape3D> s = o->get("shape");   // made once, kept on the data (shared by every body that uses it)
	if (s.is_valid()) return s;
	const int kind = (int)o->get("kind"); const PackedVector3Array data = o->get("data");
	if (kind == 0) { Ref<ConcavePolygonShape3D> c; c.instantiate(); c->set_backface_collision_enabled((bool)o->get("backface")); c->set_faces(data); s = c; }
	else if (kind == 1) { Ref<ConvexPolygonShape3D> x; x.instantiate(); x->set_points(data); s = x; }
	else { Ref<BoxShape3D> b; b.instantiate(); if (data.size() > 0) b->set_size(data[0]); s = b; }
	o->set("shape", s);
	return s;
}

void CityStream::make_body(Body &e) {
	Node3D *mk = e.marker;
	StaticBody3D *body = memnew(StaticBody3D);
	body->set_name(mk->get_name()); body->set_transform(mk->get_transform());
	body->set_collision_layer((uint32_t)(int)mk->get_meta("layer")); body->set_collision_mask((uint32_t)(int)mk->get_meta("mask"));
	const Array col = mk->get_meta("col");
	for (int k = 0; k < col.size(); k++) {   // shapes straight on the body: no CollisionShape3D node each (24 of them cost 3.5 ms on the phone)
		const Array it = col[k];
		const uint32_t ow = body->create_shape_owner(body);
		body->shape_owner_set_transform(ow, it[1]);
		body->shape_owner_add_shape(ow, col_shape(it[0]));
	}
	e.parent->add_child(body);
	memdelete(mk); e.marker = nullptr;
}

// ---------------------------------------------------------------- the loop
void CityStream::update_focus(const Vector3 &p_in, bool p_now, const Vector3 &p_velocity) {
	Vector3 p = p_in;
	// B7: riding (the player hidden where he got in), stream round the active camera
	if (player_id) {
		Node3D *pl = Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(player_id)));
		if (pl && pl->is_inside_tree() && !pl->is_visible()) {
			Viewport *vp = get_viewport();
			if (Camera3D *cam = vp ? vp->get_camera_3d() : nullptr) p = cam->get_global_position();
		}
	}
	focus = p;
	Vector3 lead(p_velocity.x, 0, p_velocity.z); lead *= (float)lead_seconds;
	if (lead.length() > (float)max_lead) lead = lead.normalized() * (float)max_lead;
	const int steps = 1 + (int)(lead.length() / 60.0f);   // the range swept along the lead, a point every 60 m or less
	std::vector<Vector3> pts{ p };
	for (int i = 1; i <= steps; i++) pts.push_back(p + lead * ((float)i / (float)steps));
	for (const Vector3 &q : prepared) pts.push_back(q);
	col_pts = pts;
	Vector3 lo = p, hi = p;
	for (const Vector3 &q : pts) { lo = Vector3(std::min(lo.x, q.x), lo.y, std::min(lo.z, q.z)); hi = Vector3(std::max(hi.x, q.x), hi.y, std::max(hi.z, q.z)); }
	const float rb = (float)unload_dist + 1.0f;
	std::vector<std::pair<float, int>> want;
	for (int i = 0; i < (int)cells.size(); i++) {
		Cell &c = cells[i];
		if (c.state == NONE && (c.x0 > hi.x + rb || c.x0 + cell_m < lo.x - rb || c.z0 > hi.z + rb || c.z0 + cell_m < lo.z - rb)) continue;
		float d = 1.0e9f;
		for (const Vector3 &q : pts) d = std::min(d, dist(i, q));
		if (d <= (float)load_dist) { c.cancel = false; if (c.state == NONE) want.push_back({ d, i }); }
		else if (d > (float)unload_dist) {
			if (c.state == IN) remove_cell(i);
			else if (c.state == LOADING && unqueue(i)) { c.state = NONE; stats["dropped"] = (int)stats["dropped"] + 1; }   // not started yet: off the list
			else if (c.state != NONE) c.cancel = true;   // asked for, no longer needed: dropped when it arrives
		}
	}
	std::sort(want.begin(), want.end());
	if (p_now) {   // the loading screen: everything in range now, and its collision
		ResourceLoader *rl = ResourceLoader::get_singleton();
		for (auto &w : want) {
			Ref<PackedScene> ps = rl->load(path_of(w.second));
			if (ps.is_null()) continue;
			Built b; build(ps, b);
			cells[w.second].node = b.node; cells[w.second].bodies = b.bodies;
			add_cell(w.second);
		}
		col_pts = { p };
		for (int j = (int)pending.size() - 1; j >= 0; j--) {
			if (col_range > 0.0 && col_d2(pending[j].centre) > (float)(col_range * col_range)) continue;   // out of range: made when it comes near
			Body e = pending[j]; pending.erase(pending.begin() + j);
			make_body(e); stats["bodies"] = (int)stats["bodies"] + 1;
		}
		flush_map(); return;
	}
	int loading = 0, have = 0;
	for (const Cell &c : cells) { if (c.state == LOADING || c.state == BUILDING) loading++; if (c.state != NONE) have++; }
	for (auto &w : want) {
		if (loading >= max_loading) break;
		if (have >= max_cells) { stats["capped"] = (int)stats["capped"] + 1; break; }   // the cap: the rest stay far versions
		{ std::lock_guard<std::mutex> l(mx); jobs.push_back({ w.second, path_of(w.second) }); }
		cv.notify_one();
		cells[w.second].state = LOADING; cells[w.second].t_req = usec(); loading++; have++;
	}
}

void CityStream::_process(double) {
	if (Engine::get_singleton()->is_editor_hint()) return;
	const uint64_t t0 = usec();
	process_stream(t0);
	stats["proc_ms"] = (double)(usec() - t0) / 1000.0;
	stats["t_proc0"] = (int64_t)t0;
	if (probe) {   // what the servers take to digest this frame's hand-overs (a question with an answer waits for them)
		if (!probe_body) {
			probe_body = memnew(StaticBody3D); CollisionShape3D *cs = memnew(CollisionShape3D); Ref<BoxShape3D> bx; bx.instantiate(); cs->set_shape(bx);
			probe_body->add_child(cs); probe_body->set_position(Vector3(0, -2000.0f, 0)); add_child(probe_body);
		}
		const uint64_t t1 = usec();
		PhysicsServer3D::get_singleton()->body_get_state(probe_body->get_rid(), PhysicsServer3D::BODY_STATE_TRANSFORM);
		const uint64_t t2 = usec();
		RenderingServer::get_singleton()->force_sync();
		stats["phys_wait_ms"] = (double)(t2 - t1) / 1000.0; stats["rs_wait_ms"] = (double)(usec() - t2) / 1000.0;
	}
	stats["t_proc1"] = (int64_t)usec();
	if (warm_phase) warm_step();
	// a teleport loading: the worst frame (from this node's last _process to this one) and what was done in it
	const uint64_t now = usec();
	if (!prepared.empty() && prep_last_us) {
		const double fr = (double)(now - prep_last_us) / 1000.0;
		if (fr > prep_worst_ms) {
			prep_worst_ms = fr;
			int loading = 0; for (const Cell &c : cells) if (c.state == LOADING || c.state == BUILDING) loading++;
			prep_worst_what = vformat("frame %.0f ms: streamer %.2f ms, cells added %d, bodies made %d, cells loading %d, physics wait %s, render wait %s, bodies waiting %d",
				fr, (double)stats["proc_ms"], frame_adds, frame_bodies, loading, String(stats.get("phys_wait_ms", "-")), String(stats.get("rs_wait_ms", "-")), (int)pending.size());
		}
	}
	prep_last_us = prepared.empty() ? 0 : now;
	frame_adds = 0; frame_bodies = 0;
}

void CityStream::release_prepared() {
	if (!prepared.empty() && prep_worst_ms > 0.0) UtilityFunctions::print("RIG   teleport worst ", prep_worst_what);
	prepared.clear(); prep_worst_ms = 0.0; prep_worst_what = String(); prep_last_us = 0;
}

void CityStream::process_stream(uint64_t t0) {
	{   // what the loader threads finished since the last frame
		std::vector<std::pair<int, Built>> fin;
		{ std::lock_guard<std::mutex> l(mx); fin.swap(done); }
		for (auto &f : fin) { Cell &c = cells[f.first]; c.node = f.second.node; c.bodies = f.second.bodies; c.state = READY; }
	}
	// one arrival a frame, nearest first
	int best = -1; float bd = 1.0e9f;
	for (int i = 0; i < (int)cells.size(); i++) {
		Cell &c = cells[i];
		if (c.state != READY) continue;
		if (!c.node) { c.state = NONE; continue; }   // its file did not load: asked for again when wanted
		if (c.cancel) {
			for (Body &b : c.bodies) away(b.marker);
			away(c.node); c.bodies.clear(); c.node = nullptr; c.state = NONE; stats["dropped"] = (int)stats["dropped"] + 1; continue;
		}
		const float d = dist(i, focus);
		if (d < bd) { bd = d; best = i; }
	}
	if (best >= 0) {
		const uint64_t ta = usec(); add_cell(best); const float ms = (float)(usec() - ta) / 1000.0f;
		v_add_ms.push_back(ms); stats["add_ms_worst"] = std::max((double)stats["add_ms_worst"], (double)ms);
		if ((int)v_ready_ms.size() >= ADD_KEEP) {   // let the oldest half go (the rig counts from ready_ms.size() + ready_dropped)
			v_add_ms.erase(v_add_ms.begin(), v_add_ms.begin() + std::min((size_t)ADD_KEEP / 2, v_add_ms.size()));
			v_ready_ms.erase(v_ready_ms.begin(), v_ready_ms.begin() + ADD_KEEP / 2); ready_dropped += ADD_KEEP / 2;
		}
		const float rm = (float)(usec() - cells[best].t_req) / 1000.0f;
		v_ready_ms.push_back(rm); stats["ready_ms_worst"] = std::max((double)stats["ready_ms_worst"], (double)rm); stats["ready_ms_sum"] = (double)stats["ready_ms_sum"] + rm;
	}
	// While a loader thread builds a cell it holds the servers' locks for moments, and the main thread's own calls wait:
	// collision (beyond what is needed soon) and the main thread's removals run in the frames when nothing loads.
	bool quiet = true;
	for (const Cell &c : cells) if (c.state == LOADING || c.state == BUILDING) { quiet = false; break; }
	if (!pending.empty()) {
		int spent = 0; const uint64_t ta0 = usec();
		const double boost = prepared.empty() ? 1.0 : std::max(prepare_boost, 1.0);
		const uint64_t now_ms = msec(); const float r2 = (float)(col_range * col_range);
		for (Body &e : pending) if (e.inrange_ms == 0 && (col_range <= 0.0 || col_d2(e.centre) <= r2)) e.inrange_ms = now_ms;
		for (int i = 0; i < (int)(bodies_per_frame * boost); i++) {
			if (pending.empty()) break;
			if (i > 0 && (double)(usec() - ta0) > col_ms_per_frame * boost * 1000.0) break;
			int bi = -1, far_i = -1; float bdist = 1.0e18f, far_d = 1.0e18f;
			for (int j = 0; j < (int)pending.size(); j++) {
				const float dd = col_d2(pending[j].centre);
				if (col_range > 0.0 && dd > r2) { if (dd < far_d) { far_d = dd; far_i = j; } continue; }
				if (dd < bdist) { bdist = dd; bi = j; }
			}
			if (bi < 0 && quiet && col_background) bi = far_i;   // out of range: in the background, in quiet frames
			if (bi < 0) break;
			int cost = 0;   // only shapes not made yet cost
			const Array col = pending[bi].marker->get_meta("col");
			for (int k = 0; k < col.size(); k++) { const Array it = col[k]; Object *o = it[0]; if (o && Ref<Shape3D>(o->get("shape")).is_null()) cost += col_weight(it[0]); }
			if (i > 0 && spent + cost > body_tris_per_frame * boost) break;
			spent += cost;
			Body e = pending[bi]; pending.erase(pending.begin() + bi);
			const uint64_t tb = usec();
			const String nm = e.marker->get_name();
			make_body(e);
			const double bms = (double)(usec() - tb) / 1000.0;
			if (bms > (double)stats["body_ms_worst"]) { stats["body_ms_worst"] = bms; stats["body_worst_what"] = vformat("%s new=%d", nm, cost); }
			stats["bodies"] = (int)stats["bodies"] + 1; stats["col_units"] = (int)stats.get("col_units", 0) + cost; frame_bodies++;
			if (col_range <= 0.0 || e.inrange_ms > 0)
				stats["body_wait_ms_worst"] = std::max((int64_t)stats.get("body_wait_ms_worst", 0), (int64_t)(msec() - (e.inrange_ms > 0 ? e.inrange_ms : e.arrive_ms)));
		}
		for (const Body &e : pending) if (e.centre.distance_to(focus) < 40.0f) { stats["body_late"] = (int)stats["body_late"] + 1; break; }   // a hole in the ground
	}
	// reap_thread off: cells on their way out, a part at a time inside the frame budget (in busy frames a small one past
	// the backlog, never while a place is prepared)
	if (!leaving.empty()) {
		const uint64_t rm_from = quiet ? t0 : usec();
		const double budget = quiet ? frame_budget_ms : (((int)leaving.size() > leaving_backlog && prepared.empty()) ? busy_remove_ms : 0.0);
		while (!leaving.empty() && (double)(usec() - rm_from) / 1000.0 < budget) {
			const uint64_t tr = usec();
			Node *n = leaving.back();
			if (n->get_child_count() > 0 && !Object::cast_to<CollisionObject3D>(n)) { Node *ch = n->get_child(n->get_child_count() - 1); n->remove_child(ch); leaving.push_back(ch); }
			else { leaving.pop_back(); memdelete(n); }
			stats["remove_ms_worst"] = std::max((double)stats["remove_ms_worst"], (double)(usec() - tr) / 1000.0);
		}
	}
	ramp_cells();
	flush_map();
}

// ---------------------------------------------------------------- arrival and departure
void CityStream::build(const Ref<PackedScene> &p_ps, Built &r_out) const {
	Node3D *node = Object::cast_to<Node3D>(p_ps->instantiate());
	r_out.node = node;
	if (!node) return;
	const TypedArray<Node> found = node->find_children("col*", "Node3D", true, false);   // the bodies-to-be (bake_runtime.gd _col_marker)
	for (int i = 0; i < found.size(); i++) {
		Node3D *b = Object::cast_to<Node3D>(found[i]);
		if (!b || !b->has_meta("col")) continue;
		Node *par = b->get_parent();
		Vector3 centre = (par != node && Object::cast_to<Node3D>(par)) ? Object::cast_to<Node3D>(par)->get_position() : b->get_position();
		par->remove_child(b);
		Body e; e.centre = centre; e.parent = par; e.marker = b;
		r_out.bodies.push_back(e);
	}
}

void CityStream::add_cell(int i) {
	Cell &c = cells[i];
	if (!show_cells) c.node->set_visible(false);
	add_child(c.node); apply_night(c.node);
	const uint64_t now = msec();
	for (Body &b : c.bodies) {
		if (attach_bodies) { b.cell = i; b.arrive_ms = now; b.inrange_ms = 0; pending.push_back(b); }
		else away(b.marker);
	}
	c.bodies.clear();
	c.state = IN; stats["in"] = (int)stats["in"] + 1; mark(i, true); frame_adds++;
	emit_signal("cell_in", c.key);
}

void CityStream::remove_cell(int i) {
	Cell &c = cells[i];
	mark(i, false);   // the far world shows the cell's far versions from this frame on
	for (int j = (int)pending.size() - 1; j >= 0; j--) if (pending[j].cell == i) { away(pending[j].marker); pending.erase(pending.begin() + j); }   // never attached
	remove_child(c.node); away(c.node);
	c.node = nullptr; c.state = NONE; stats["out"] = (int)stats["out"] + 1;
	emit_signal("cell_out", c.key);
}

void CityStream::away(Node *n) {
	if (!n) return;
	if (reaper.is_null()) { leaving.push_back(n); return; }
	{ std::lock_guard<std::mutex> l(rmx); reap_q.push_back(n); }
	rcv.notify_one();
}

bool CityStream::unqueue(int i) {
	std::lock_guard<std::mutex> l(mx);
	for (auto it = jobs.begin(); it != jobs.end(); ++it) if (it->first == i) { jobs.erase(it); return true; }
	return false;
}

// ---------------------------------------------------------------- the threads
// A loader: loads a cell's file with everything in it, builds the cell and hands it over; never touches `cells`.
void CityStream::loader_loop() {
	ResourceLoader *rl = ResourceLoader::get_singleton();
	for (;;) {
		std::pair<int, String> job;
		{
			std::unique_lock<std::mutex> l(mx);
			cv.wait(l, [this] { return quit || !jobs.empty(); });
			if (quit) return;
			job = jobs.front(); jobs.pop_front();
		}
		Built b;
		Ref<PackedScene> ps = rl->load(job.second);
		if (ps.is_valid()) build(ps, b);
		std::lock_guard<std::mutex> l(mx);
		if (quit) { for (Body &e : b.bodies) if (e.marker) memdelete(e.marker); if (b.node) memdelete(b.node); return; }
		done.push_back({ job.first, std::move(b) });
	}
}

// The reaper: leaving nodes taken apart leaf by leaf (a body whole) and freed, outside the tree; a short pause every
// REAP_BATCH parts so the main thread gets at the servers.
void CityStream::reap_loop() {
	std::vector<Node *> work;
	for (;;) {
		{
			std::unique_lock<std::mutex> l(rmx);
			rcv.wait(l, [this] { return reap_quit || !reap_q.empty(); });
			if (reap_quit) return;
			work.insert(work.end(), reap_q.begin(), reap_q.end()); reap_q.clear();
			reaping.store((int)work.size());
		}
		int n_done = 0;
		while (!work.empty()) {
			{ std::lock_guard<std::mutex> l(rmx); if (reap_quit) { for (Node *n : work) reap_q.push_back(n); return; } }
			Node *n = work.back();
			if (n->get_child_count() > 0 && !Object::cast_to<CollisionObject3D>(n)) { Node *ch = n->get_child(n->get_child_count() - 1); n->remove_child(ch); work.push_back(ch); }
			else { work.pop_back(); memdelete(n); }
			if (++n_done % REAP_BATCH == 0) { reaping.store((int)work.size()); OS::get_singleton()->delay_usec(300); }
		}
		reaping.store(0);
	}
}

// ---------------------------------------------------------------- warm-up (behind the loading screen)
// One of every baked material drawn for `frames` frames (lib/warm.scn), the night variants too; then the graphics memory
// reserve: gpu_reserve_mb taken from the driver and given back, so its next big block is fetched now and not mid-drive
// (phone, 18 Nov: a 60-550 ms draw frame at the first cells otherwise). Emits `warmed_up` when done.
void CityStream::warm_up(Camera3D *p_cam, int p_frames) {
	const String wp = runtime_dir + "lib/warm.scn";
	ResourceLoader *rl = ResourceLoader::get_singleton();
	Ref<PackedScene> ps = rl->exists(wp) ? Ref<PackedScene>(rl->load(wp)) : Ref<PackedScene>();
	if (ps.is_null() || !p_cam) { call_deferred("emit_signal", "warmed_up"); return; }
	warm_node = Object::cast_to<Node3D>(ps->instantiate());
	add_child(warm_node);
	warm_node->set_global_transform(Transform3D(Basis(), p_cam->get_global_position() - p_cam->get_global_transform().basis.get_column(2) * 6.0f));
	const TypedArray<Node> g = warm_node->find_children("*", "GeometryInstance3D", true, false);
	for (int i = 0; i < g.size(); i++) if (GeometryInstance3D *gi = Object::cast_to<GeometryInstance3D>(g[i])) gi->set_visible(true);
	warm_prev_night = night; RenderingServer::get_singleton()->global_shader_parameter_set("ck_night", 1.0);
	warm_frames = std::max(p_frames, 1); warm_phase = 1;
}

void CityStream::_reserve_make() {
	RenderingDevice *rd = RenderingServer::get_singleton()->get_rendering_device();
	if (!rd) return;
	for (int i = 0; i < gpu_reserve_mb / 16; i++) warm_held.push_back(rd->vertex_buffer_create(16 * 1024 * 1024));
}

void CityStream::_reserve_free() {
	RenderingDevice *rd = RenderingServer::get_singleton()->get_rendering_device();
	for (const RID &r : warm_held) if (rd && r.is_valid()) rd->free_rid(r);
	warm_held.clear();
}

void CityStream::warm_step() {
	if (warm_phase == 1) {
		if (--warm_frames > 0) return;
		RenderingServer::get_singleton()->global_shader_parameter_set("ck_night", warm_prev_night);
		if (warm_node) { warm_node->queue_free(); warm_node = nullptr; }
		if (gpu_reserve_mb > 0 && RenderingServer::get_singleton()->get_rendering_device()) {
			// the RenderingDevice may only be used on the render thread (B28: with a separate render thread the 12 frees
			// below were refused from the main thread, "free_rid can only be called from the render thread", and the 192 MB
			// stayed taken): made and freed there, in that order (one queue)
			warm_t0 = msec();
			RenderingServer::get_singleton()->call_on_render_thread(Callable(this, "_reserve_make"));
			warm_frames = 2; warm_phase = 2; return;
		}
		warm_phase = 0; emit_signal("warmed_up"); return;
	}
	if (warm_phase == 2) {
		if (--warm_frames > 0) return;
		RenderingServer::get_singleton()->call_on_render_thread(Callable(this, "_reserve_free"));
		stats["reserve_ms"] = (int64_t)(msec() - warm_t0);
		warm_phase = 0; emit_signal("warmed_up");
	}
}

// ---------------------------------------------------------------- binding
Dictionary CityStream::perf_take() {
	Dictionary d;
	for (int k = 0; k < pm::N; k++) { if (pm::acc_ms[k] > 0.0) d[pm::NAME[k]] = pm::acc_ms[k]; pm::acc_ms[k] = 0.0; }
	return d;
}

void CityStream::_bind_methods() {
	ClassDB::bind_method(D_METHOD("_reserve_make"), &CityStream::_reserve_make); ClassDB::bind_method(D_METHOD("_reserve_free"), &CityStream::_reserve_free);
	ClassDB::bind_method(D_METHOD("perf_take"), &CityStream::perf_take);
	ADD_SIGNAL(MethodInfo("cell_in", PropertyInfo(Variant::STRING, "key")));
	ADD_SIGNAL(MethodInfo("cell_out", PropertyInfo(Variant::STRING, "key")));
	ADD_SIGNAL(MethodInfo("warmed_up"));
	BIND_CONSTANT(NONE); BIND_CONSTANT(LOADING); BIND_CONSTANT(BUILDING); BIND_CONSTANT(READY); BIND_CONSTANT(IN);
	ClassDB::bind_method(D_METHOD("update_focus", "pos", "now", "velocity"), &CityStream::update_focus, DEFVAL(false), DEFVAL(Vector3()));
	ClassDB::bind_method(D_METHOD("set_player", "player"), &CityStream::set_player);
	ClassDB::bind_method(D_METHOD("set_tiers", "on", "band", "arrive"), &CityStream::set_tiers, DEFVAL(-1.0), DEFVAL(-1.0));
	ClassDB::bind_method(D_METHOD("shader_variant", "plain", "defines"), &CityStream::shader_variant);
	ClassDB::bind_method(D_METHOD("baked_shader", "material"), &CityStream::baked_shader);
	ClassDB::bind_method(D_METHOD("set_far_ground", "on"), &CityStream::set_far_ground);
	ClassDB::bind_method(D_METHOD("get_far_ground"), &CityStream::get_far_ground);
	ClassDB::bind_method(D_METHOD("loaded_count"), &CityStream::loaded_count);
	ClassDB::bind_method(D_METHOD("loading_keys"), &CityStream::loading_keys);
	ClassDB::bind_method(D_METHOD("busy"), &CityStream::busy);
	ClassDB::bind_method(D_METHOD("is_ready", "pos"), &CityStream::is_ready);
	ClassDB::bind_method(D_METHOD("prepare", "pos"), &CityStream::prepare);
	ClassDB::bind_method(D_METHOD("release_prepared"), &CityStream::release_prepared);
	ClassDB::bind_method(D_METHOD("set_night", "v"), &CityStream::set_night);
	ClassDB::bind_method(D_METHOD("warm_up", "camera", "frames"), &CityStream::warm_up, DEFVAL(3));
	ClassDB::bind_method(D_METHOD("get_cells"), &CityStream::get_cells);
	ClassDB::bind_method(D_METHOD("get_focus"), &CityStream::get_focus);
	ClassDB::bind_method(D_METHOD("get_stats"), &CityStream::get_stats);
	ClassDB::bind_method(D_METHOD("get_ready_ms"), &CityStream::get_ready_ms);
	ClassDB::bind_method(D_METHOD("get_add_ms"), &CityStream::get_add_ms);
	ClassDB::bind_method(D_METHOD("get_ready_dropped"), &CityStream::get_ready_dropped);
	ClassDB::bind_method(D_METHOD("get_far_world"), &CityStream::get_far_world);
	ClassDB::bind_method(D_METHOD("cell_distance", "key", "pos"), &CityStream::cell_distance);
	ClassDB::bind_method(D_METHOD("late_cells", "pos"), &CityStream::late_cells);
	ClassDB::bind_method(D_METHOD("pending_count"), &CityStream::pending_count);
	ClassDB::bind_method(D_METHOD("leaving_count"), &CityStream::leaving_count);
	ClassDB::bind_method(D_METHOD("cell_node", "key"), &CityStream::cell_node);
	ClassDB::bind_method(D_METHOD("set_rooms", "v"), &CityStream::set_rooms); ClassDB::bind_method(D_METHOD("get_rooms"), &CityStream::get_rooms); ADD_PROPERTY(PropertyInfo(Variant::BOOL, "rooms"), "set_rooms", "get_rooms");
	ClassDB::bind_method(D_METHOD("set_skyline", "v"), &CityStream::set_skyline); ClassDB::bind_method(D_METHOD("get_skyline"), &CityStream::get_skyline); ADD_PROPERTY(PropertyInfo(Variant::BOOL, "skyline"), "set_skyline", "get_skyline");
	ClassDB::bind_method(D_METHOD("set_breakables", "v"), &CityStream::set_breakables); ClassDB::bind_method(D_METHOD("get_breakables"), &CityStream::get_breakables); ADD_PROPERTY(PropertyInfo(Variant::BOOL, "breakables"), "set_breakables", "get_breakables");
	ADD_PROPERTY(PropertyInfo(Variant::DICTIONARY, "cells", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_cells");
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "focus", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_focus");
	ADD_PROPERTY(PropertyInfo(Variant::DICTIONARY, "stats", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_stats");
	ADD_PROPERTY(PropertyInfo(Variant::PACKED_FLOAT32_ARRAY, "ready_ms", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_ready_ms");
	ADD_PROPERTY(PropertyInfo(Variant::PACKED_FLOAT32_ARRAY, "add_ms", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_add_ms");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "ready_dropped", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_ready_dropped");
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "far_world", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_far_world");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "far_ground"), "set_far_ground", "get_far_ground");
	ClassDB::bind_method(D_METHOD("set_runtime_dir", "v"), &CityStream::set_runtime_dir); ClassDB::bind_method(D_METHOD("get_runtime_dir"), &CityStream::get_runtime_dir); ADD_PROPERTY(PropertyInfo(Variant::STRING, "runtime_dir"), "set_runtime_dir", "get_runtime_dir");
	ClassDB::bind_method(D_METHOD("set_load_dist", "v"), &CityStream::set_load_dist); ClassDB::bind_method(D_METHOD("get_load_dist"), &CityStream::get_load_dist); ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "load_dist"), "set_load_dist", "get_load_dist");
	ClassDB::bind_method(D_METHOD("set_unload_dist", "v"), &CityStream::set_unload_dist); ClassDB::bind_method(D_METHOD("get_unload_dist"), &CityStream::get_unload_dist); ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "unload_dist"), "set_unload_dist", "get_unload_dist");
	ClassDB::bind_method(D_METHOD("set_lead_seconds", "v"), &CityStream::set_lead_seconds); ClassDB::bind_method(D_METHOD("get_lead_seconds"), &CityStream::get_lead_seconds); ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "lead_seconds"), "set_lead_seconds", "get_lead_seconds");
	ClassDB::bind_method(D_METHOD("set_max_lead", "v"), &CityStream::set_max_lead); ClassDB::bind_method(D_METHOD("get_max_lead"), &CityStream::get_max_lead); ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_lead"), "set_max_lead", "get_max_lead");
	ClassDB::bind_method(D_METHOD("set_max_loading", "v"), &CityStream::set_max_loading); ClassDB::bind_method(D_METHOD("get_max_loading"), &CityStream::get_max_loading); ADD_PROPERTY(PropertyInfo(Variant::INT, "max_loading"), "set_max_loading", "get_max_loading");
	ClassDB::bind_method(D_METHOD("set_max_cells", "v"), &CityStream::set_max_cells); ClassDB::bind_method(D_METHOD("get_max_cells"), &CityStream::get_max_cells); ADD_PROPERTY(PropertyInfo(Variant::INT, "max_cells"), "set_max_cells", "get_max_cells");
	ClassDB::bind_method(D_METHOD("set_frame_budget_ms", "v"), &CityStream::set_frame_budget_ms); ClassDB::bind_method(D_METHOD("get_frame_budget_ms"), &CityStream::get_frame_budget_ms); ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "frame_budget_ms"), "set_frame_budget_ms", "get_frame_budget_ms");
	ClassDB::bind_method(D_METHOD("set_reap_thread", "v"), &CityStream::set_reap_thread); ClassDB::bind_method(D_METHOD("get_reap_thread"), &CityStream::get_reap_thread); ADD_PROPERTY(PropertyInfo(Variant::BOOL, "reap_thread"), "set_reap_thread", "get_reap_thread");
	ClassDB::bind_method(D_METHOD("set_busy_remove_ms", "v"), &CityStream::set_busy_remove_ms); ClassDB::bind_method(D_METHOD("get_busy_remove_ms"), &CityStream::get_busy_remove_ms); ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "busy_remove_ms"), "set_busy_remove_ms", "get_busy_remove_ms");
	ClassDB::bind_method(D_METHOD("set_leaving_backlog", "v"), &CityStream::set_leaving_backlog); ClassDB::bind_method(D_METHOD("get_leaving_backlog"), &CityStream::get_leaving_backlog); ADD_PROPERTY(PropertyInfo(Variant::INT, "leaving_backlog"), "set_leaving_backlog", "get_leaving_backlog");
	ClassDB::bind_method(D_METHOD("set_bodies_per_frame", "v"), &CityStream::set_bodies_per_frame); ClassDB::bind_method(D_METHOD("get_bodies_per_frame"), &CityStream::get_bodies_per_frame); ADD_PROPERTY(PropertyInfo(Variant::INT, "bodies_per_frame"), "set_bodies_per_frame", "get_bodies_per_frame");
	ClassDB::bind_method(D_METHOD("set_body_tris_per_frame", "v"), &CityStream::set_body_tris_per_frame); ClassDB::bind_method(D_METHOD("get_body_tris_per_frame"), &CityStream::get_body_tris_per_frame); ADD_PROPERTY(PropertyInfo(Variant::INT, "body_tris_per_frame"), "set_body_tris_per_frame", "get_body_tris_per_frame");
	ClassDB::bind_method(D_METHOD("set_attach_bodies", "v"), &CityStream::set_attach_bodies); ClassDB::bind_method(D_METHOD("get_attach_bodies"), &CityStream::get_attach_bodies); ADD_PROPERTY(PropertyInfo(Variant::BOOL, "attach_bodies"), "set_attach_bodies", "get_attach_bodies");
	ClassDB::bind_method(D_METHOD("set_show_cells", "v"), &CityStream::set_show_cells); ClassDB::bind_method(D_METHOD("get_show_cells"), &CityStream::get_show_cells); ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_cells"), "set_show_cells", "get_show_cells");
	ClassDB::bind_method(D_METHOD("set_loader_mode", "v"), &CityStream::set_loader_mode); ClassDB::bind_method(D_METHOD("get_loader_mode"), &CityStream::get_loader_mode); ADD_PROPERTY(PropertyInfo(Variant::INT, "loader_mode"), "set_loader_mode", "get_loader_mode");
	ClassDB::bind_method(D_METHOD("set_col_ms_per_frame", "v"), &CityStream::set_col_ms_per_frame); ClassDB::bind_method(D_METHOD("get_col_ms_per_frame"), &CityStream::get_col_ms_per_frame); ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "col_ms_per_frame"), "set_col_ms_per_frame", "get_col_ms_per_frame");
	ClassDB::bind_method(D_METHOD("set_gpu_reserve_mb", "v"), &CityStream::set_gpu_reserve_mb); ClassDB::bind_method(D_METHOD("get_gpu_reserve_mb"), &CityStream::get_gpu_reserve_mb); ADD_PROPERTY(PropertyInfo(Variant::INT, "gpu_reserve_mb"), "set_gpu_reserve_mb", "get_gpu_reserve_mb");
	ClassDB::bind_method(D_METHOD("set_ready_col_m", "v"), &CityStream::set_ready_col_m); ClassDB::bind_method(D_METHOD("get_ready_col_m"), &CityStream::get_ready_col_m); ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "ready_col_m"), "set_ready_col_m", "get_ready_col_m");
	ClassDB::bind_method(D_METHOD("set_probe", "v"), &CityStream::set_probe); ClassDB::bind_method(D_METHOD("get_probe"), &CityStream::get_probe); ADD_PROPERTY(PropertyInfo(Variant::BOOL, "probe"), "set_probe", "get_probe");
	ClassDB::bind_method(D_METHOD("set_urgent_m", "v"), &CityStream::set_urgent_m); ClassDB::bind_method(D_METHOD("get_urgent_m"), &CityStream::get_urgent_m); ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "urgent_m"), "set_urgent_m", "get_urgent_m");
	ClassDB::bind_method(D_METHOD("set_col_range", "v"), &CityStream::set_col_range); ClassDB::bind_method(D_METHOD("get_col_range"), &CityStream::get_col_range); ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "col_range"), "set_col_range", "get_col_range");
	ClassDB::bind_method(D_METHOD("set_col_background", "v"), &CityStream::set_col_background); ClassDB::bind_method(D_METHOD("get_col_background"), &CityStream::get_col_background); ADD_PROPERTY(PropertyInfo(Variant::BOOL, "col_background"), "set_col_background", "get_col_background");
	ClassDB::bind_method(D_METHOD("set_prepare_boost", "v"), &CityStream::set_prepare_boost); ClassDB::bind_method(D_METHOD("get_prepare_boost"), &CityStream::get_prepare_boost); ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "prepare_boost"), "set_prepare_boost", "get_prepare_boost");
	ClassDB::bind_method(D_METHOD("set_tiers_on", "v"), &CityStream::set_tiers_on); ClassDB::bind_method(D_METHOD("get_tiers"), &CityStream::get_tiers); ADD_PROPERTY(PropertyInfo(Variant::BOOL, "tiers"), "set_tiers_on", "get_tiers");
	ClassDB::bind_method(D_METHOD("set_tier_band", "v"), &CityStream::set_tier_band); ClassDB::bind_method(D_METHOD("get_tier_band"), &CityStream::get_tier_band); ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "tier_band"), "set_tier_band", "get_tier_band");
	ClassDB::bind_method(D_METHOD("set_arrive_s", "v"), &CityStream::set_arrive_s); ClassDB::bind_method(D_METHOD("get_arrive_s"), &CityStream::get_arrive_s); ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "arrive_s"), "set_arrive_s", "get_arrive_s");
}

} // namespace godot
