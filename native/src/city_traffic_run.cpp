// CityTraffic at run time: the step on its own thread, the car batches, the parked cars, the streamer's cells, the
// collision pool. See city_traffic.h for how it hangs together.
#include "city_traffic.h"

#include "car_models.h"
#include "traffic_sim.h"

#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/physics_server3d.hpp>
#include <godot_cpp/classes/rendering_server.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/shader.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/aabb.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <cstdlib>
#include <chrono>
#include <cmath>
#include <cstring>

namespace godot {

namespace {

const int ROW = 20;             // floats a row: transform 12, colour 4, custom 4
const float STEP_S = 0.05f;     // the traffic steps 20 times a second
const int GRID = 64;            // cells are looked up in a 64 x 64 grid, cell (0, 0) at its middle
const float CELL_M = 200.0f;

// paint colours (linear), about as common as on a real street: white, black, silver, grey, dark blue, red, beige,
// dark green, light blue, dark red
const float PAINT[CityTraffic::N_COLOURS][3] = {
	{ 0.80f, 0.80f, 0.78f }, { 0.012f, 0.012f, 0.014f }, { 0.30f, 0.315f, 0.33f }, { 0.09f, 0.095f, 0.10f }, { 0.02f, 0.04f, 0.13f },
	{ 0.36f, 0.015f, 0.012f }, { 0.50f, 0.42f, 0.28f }, { 0.03f, 0.08f, 0.045f }, { 0.25f, 0.42f, 0.58f }, { 0.13f, 0.01f, 0.012f }
};

inline int64_t usec_now() {
	return std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

using tp::hash32;

inline float lerp_angle(float a, float b, float t) {
	float d = std::fmod(b - a + 3.14159265f, 6.2831853f);
	if (d < 0) d += 6.2831853f;
	return a + (d - 3.14159265f) * t;
}

inline int cell_index(float x, float z) {
	const int cx = (int)std::floor(x / CELL_M) + GRID / 2, cz = (int)std::floor(z / CELL_M) + GRID / 2;
	if (cx < 0 || cz < 0 || cx >= GRID || cz >= GRID) return -1;
	return cz * GRID + cx;
}

} // namespace

// ---------------------------------------------------------------- the step, on its own thread
void CityTraffic::step_once(double p_clock) {
	Input in;
	{
		std::lock_guard<std::mutex> lock(mx);
		in = input;
		input.cells_dirty = false;
	}
	sim->cfg.max_cars = std::min(in.max_cars, (int)MAX_ROWS - 2);
	sim->cfg.dens_scale = in.density;
	sim->cfg.hour_factor = 1.0f;
	if (in.cells_dirty) parking.set_cells(in.cells, in.cells_all);
	parking.on = in.parked;
	if (in.cells_dirty) { sim->cells_all = in.cells_all; sim->cell_ok = in.cells; sim->cg_x0 = -GRID / 2; sim->cg_z0 = -GRID / 2; sim->cg_w = GRID; sim->cg_h = GRID; sim->carry_tick = -1; }
	// the ring cars appear in runs ahead of the camera: 2 s of travel, 200 m at most (what the streamer leads by), and
	// in view no car appears nearer than 4 s of travel (160 m at least)
	const float speed = std::sqrt(in.vx * in.vx + in.vz * in.vz);
	sim->cfg.view_safe_r = std::min(std::max(160.0f, speed * 4.0f), 300.0f);
	sim->set_view(in.cx, in.cy, in.cz, in.fx, in.fz, in.fov);
	if (speed > 1.0f) {
		const float lead = std::min(speed * 2.0f, 200.0f);
		sim->set_ring(in.vx / speed * lead, in.vz / speed * lead);
	}
	parking.tick(*sim, STEP_S);
	sim->set_dynamic((int)parking.dyn.size() / tc::DYN_STRIDE, parking.dyn.data());
	sim->step(STEP_S, p_clock);
	sim->events.clear();
	static thread_local Snap s;
	s.n = 0;
	for (int i = 0; i < sim->hi && s.n < MAX_ROWS; i++) {
		if (!sim->alive[i]) continue;
		Row &r = s.rows[s.n++];
		r.id = sim->id[i]; r.model = sim->model[i]; r.colour = tp::Parking::car_colour(*sim, i); r.kind = sim->kind[i];
		r.flags = (uint8_t)(((sim->flags[i] & tc::F_BRAKE) ? 1 : 0) | ((sim->flags[i] & tc::F_IND_L) ? 2 : 0) | ((sim->flags[i] & tc::F_IND_R) ? 4 : 0));
		r.x = sim->x[i]; r.y = sim->y[i]; r.z = sim->z[i]; r.yaw = sim->yaw[i]; r.pitch = sim->pitch[i];
		r.px = sim->px[i]; r.py = sim->py[i]; r.pz = sim->pz[i]; r.pyaw = sim->pyaw[i]; r.ppitch = sim->ppitch[i];
		r.v = sim->v[i]; r.hl = sim->hl[i]; r.hw = sim->hw[i];
		r.tu = sim->tu[i]; r.span = std::max(1, (int)sim->span[i]);
	}
	s.tick = sim->tick; s.t_usec = usec_now(); s.clock = p_clock + STEP_S;
	s.step_us = (float)sim->st.last_step_us; s.carry = sim->carry;
	s.spawned = sim->st.spawned; s.despawned = sim->st.despawned;
	{
		std::lock_guard<std::mutex> lock(mx);
		shared = s;
		park_events.insert(park_events.end(), parking.events.begin(), parking.events.end());
		park_out = parking.pulled_out; park_in = parking.parked;
	}
	parking.events.clear();
}

void CityTraffic::thread_main() {
	using clk = std::chrono::steady_clock;
	auto next = clk::now();
	double t = 0.0;
	while (!quit.load()) {
		step_once(t);
		t += STEP_S;
		next += std::chrono::milliseconds(50);
		const auto nowt = clk::now();
		if (next < nowt - std::chrono::milliseconds(250)) next = nowt;   // fell far behind (the app was held): no catching up
		std::this_thread::sleep_until(next);
	}
}

// ---------------------------------------------------------------- batches
void CityTraffic::make_batch(Batch &b, const Ref<Mesh> &p_mesh, const Ref<ShaderMaterial> &p_mat, int p_cap, bool p_shadow) {
	RenderingServer *rs = RenderingServer::get_singleton();
	b.mm = rs->multimesh_create();
	b.cap = p_cap;
	rs->multimesh_allocate_data(b.mm, p_cap, RenderingServer::MULTIMESH_TRANSFORM_3D, true, true);
	if (p_mesh.is_valid()) rs->multimesh_set_mesh(b.mm, p_mesh->get_rid());
	rs->multimesh_set_visible_instances(b.mm, 0);
	b.inst = rs->instance_create2(b.mm, get_world_3d()->get_scenario());
	// one box for the whole city: a batch is never culled as a whole (its rows are everywhere), and it is hidden when empty
	rs->instance_set_custom_aabb(b.inst, AABB(Vector3(-4000, -200, -4000), Vector3(8000, 600, 8000)));
	if (p_mat.is_valid()) rs->instance_geometry_set_material_override(b.inst, p_mat->get_rid());
	rs->instance_geometry_set_cast_shadows_setting(b.inst, p_shadow ? RenderingServer::SHADOW_CASTING_SETTING_ON : RenderingServer::SHADOW_CASTING_SETTING_OFF);
	rs->instance_set_visible(b.inst, false);
	b.buf.resize((int64_t)p_cap * ROW);
	b.buf.fill(0.0f);
	b.shown = 0; b.n = 0; b.dirty = false;
}

void CityTraffic::grow(Batch &b, int p_need) {
	if (p_need <= b.cap) return;
	int cap = b.cap;
	while (cap < p_need) cap *= 2;
	RenderingServer *rs = RenderingServer::get_singleton();
	rs->multimesh_allocate_data(b.mm, cap, RenderingServer::MULTIMESH_TRANSFORM_3D, true, true);
	b.cap = cap;
	b.buf.resize((int64_t)cap * ROW);
	b.dirty = true;
}

void CityTraffic::send(Batch &b) {
	RenderingServer *rs = RenderingServer::get_singleton();
	if (b.dirty) {
		// rows past the last one keep whatever they had: they are never drawn (visible instances)
		rs->multimesh_set_buffer(b.mm, b.buf);
		b.dirty = false;
		cnt.uploads++;
	}
	if (b.n != b.shown) {
		rs->multimesh_set_visible_instances(b.mm, b.n);
		if ((b.n > 0) != (b.shown > 0)) rs->instance_set_visible(b.inst, b.n > 0);
		b.shown = b.n;
	}
}

// One row: where the car is, how it stands (yaw 0 = facing +z, pitch + = nose up), its size against the mesh, paint, lamps
void CityTraffic::put_row(float *r, float x, float y, float z, float yaw, float pitch, float sx, float sy, float sz, const float *col, float c0, float c1, float c2, float c3) {
	const float cp = std::cos(pitch), sp = std::sin(pitch), cy = std::cos(yaw), sy_ = std::sin(yaw);
	// the car's axes in the world: forward f, left l = up x f, up u = f x l
	const float fx = sy_ * cp, fy = sp, fz = cy * cp;
	float lx = fz, lz = -fx;   // (0, 1, 0) x f = (fz, 0, -fx)
	const float ll = std::sqrt(lx * lx + lz * lz);
	if (ll < 1.0e-4f) { lx = cy; lz = -sy_; } else { lx /= ll; lz /= ll; }
	const float ux = fy * lz, uy = fz * lx - fx * lz, uz = -fy * lx;   // f x l with l.y = 0
	r[0] = lx * sx; r[1] = ux * sy; r[2] = fx * sz; r[3] = x;
	r[4] = 0.0f; r[5] = uy * sy; r[6] = fy * sz; r[7] = y;
	r[8] = lz * sx; r[9] = uz * sy; r[10] = fz * sz; r[11] = z;
	r[12] = col[0]; r[13] = col[1]; r[14] = col[2]; r[15] = 1.0f;
	r[16] = c0; r[17] = c1; r[18] = c2; r[19] = c3;
}

// ---------------------------------------------------------------- parked cars
// Which stalls are taken, and by which car and colour: fixed by the stall's own number, so a street looks the same
// every time (docs: "the same street every time"). Kerb stalls are fuller than car parks.
void CityTraffic::seed_stalls() {
	const int ns = (int)streets.stall_i.size() / 4;
	stall_car.assign(ns, Parked{ 255, 0 });
	stall_mid.assign(ns, 0);
	cell_stalls.assign((size_t)GRID * GRID, std::vector<int32_t>());
	for (int k = 0; k < ns; k++) {
		const float *f = &streets.stall_f[(size_t)k * 8];
		const int ci = cell_index(f[0], f[2]);
		if (ci < 0) continue;
		cell_stalls[ci].push_back(k);
		tp::seed_stall(k, streets.stall_i[(size_t)k * 4] == 0, stall_car[k].model, stall_car[k].colour);
	}
}

// The taken stalls of the loaded cells, and the far batch of all of them. Runs when a cell comes or goes, not per frame.
void CityTraffic::rebuild_active() {
	active.clear();
	for (auto &v : mid_parked) v.clear();
	std::fill(stall_mid.begin(), stall_mid.end(), (uint8_t)0);
	band_cursor = 0;
	if (parked_on) {
		for (int ci = 0; ci < GRID * GRID; ci++) {
			if (!cells_all && !cells[ci]) continue;
			for (int32_t k : cell_stalls[ci]) if (stall_car[k].model != 255) active.push_back(k);
		}
	}
	grow(box_parked, (int)active.size());
	float *w = box_parked.buf.ptrw();
	for (size_t a = 0; a < active.size(); a++) {
		const int k = active[a];
		const float *f = &streets.stall_f[(size_t)k * 8];
		const cm::CarModel &m = cm::MODELS[stall_car[k].model];
		put_row(w + a * ROW, f[0], f[1] + 0.02f, f[2], f[3], f[4],
				m.half_w * 2.0f / box_size[0], m.height / (box_size[1] + box_y0), m.half_len * 2.0f / box_size[2], PAINT[stall_car[k].colour], 0.0f, 0.0f, 0.0f, 1.0f);
	}
	box_parked.n = (int)active.size();
	box_parked.dirty = true;
	active_dirty = false;
}

// ---------------------------------------------------------------- the streamer's cells
void CityTraffic::cell_set(const String &p_key, bool p_in) {
	const PackedStringArray q = p_key.split("_");
	if (q.size() < 2) return;
	const int cx = (int)q[0].to_int() + GRID / 2, cz = (int)q[1].to_int() + GRID / 2;
	if (cx < 0 || cz < 0 || cx >= GRID || cz >= GRID) return;
	const uint8_t v = p_in ? 1 : 0;
	if (cells[(size_t)cz * GRID + cx] == v) return;
	cells[(size_t)cz * GRID + cx] = v;
	active_dirty = true;
	if (!p_in && !cell_stalls.empty())   // a cell that leaves: its stalls go back to what they hold at first (the step does the same on its side)
		for (int32_t k : cell_stalls[(size_t)cz * GRID + cx]) tp::seed_stall(k, streets.stall_i[(size_t)k * 4] == 0, stall_car[k].model, stall_car[k].colour);
	std::lock_guard<std::mutex> lock(mx);
	input.cells = cells; input.cells_all = cells_all; input.cells_dirty = true;
}

void CityTraffic::_on_cell_in(const String &p_key) { cell_set(p_key, true); }
void CityTraffic::_on_cell_out(const String &p_key) { cell_set(p_key, false); }

void CityTraffic::attach(Object *p_streamer) {
	if (p_streamer == nullptr) return;
	streamer_id = (uint64_t)p_streamer->get_instance_id();
	cells.assign((size_t)GRID * GRID, 0);
	cells_all = false;
	p_streamer->connect("cell_in", Callable(this, "_on_cell_in"));
	p_streamer->connect("cell_out", Callable(this, "_on_cell_out"));
	// the cells that are in already (the start area): state 4 = IN (city_stream.gd)
	const Variant cv = p_streamer->get("cells");
	if (cv.get_type() == Variant::DICTIONARY) {
		const Dictionary d = cv;
		const Array keys = d.keys();
		for (int i = 0; i < keys.size(); i++) {
			const Variant ev = d[keys[i]];
			if (ev.get_type() != Variant::DICTIONARY) continue;
			if ((int)Dictionary(ev).get("state", 0) == 4) cell_set(String(keys[i]), true);
		}
	}
	active_dirty = true;
	std::lock_guard<std::mutex> lock(mx);
	input.cells = cells; input.cells_all = false; input.cells_dirty = true;
}

// ---------------------------------------------------------------- start and end
void CityTraffic::_ready() {
	if (!ready) load_streets(streets_path);
	if (!ready) {
		UtilityFunctions::push_error("CityTraffic: no streets (", streets_path, "): run tools/city/traffic/make_streets.gd");
		set_process(false); set_physics_process(false);
		return;
	}
	if (cells.empty()) cells.assign((size_t)GRID * GRID, 0);
	seed_stalls();
	// the models, their one material each way, the batches
	ResourceLoader *rl = ResourceLoader::get_singleton();
	mesh_near.resize(cm::N_MODELS); mesh_mid.resize(cm::N_MODELS);
	for (int m = 0; m < cm::N_MODELS; m++) {
		mesh_near[m] = rl->load(String("res://vehicles/models/lod/") + cm::MODELS[m].id + "_q.res");
		mesh_mid[m] = rl->load(String("res://vehicles/models/lod/") + cm::MODELS[m].id + "_far.res");
		if (mesh_mid[m].is_null()) mesh_mid[m] = mesh_near[m];
	}
	mesh_box = rl->load("res://vehicles/models/lod/stern_g_imp.res");
	if (mesh_box.is_valid()) {
		const AABB ab = mesh_box->get_aabb();
		box_size[0] = ab.size.x; box_size[1] = ab.size.y; box_size[2] = ab.size.z; box_y0 = ab.position.y;
	}
	Ref<Shader> sh_car = rl->load("res://map_dc/coronado/city_kit/traffic/shaders/traffic_car.gdshader");
	Ref<Shader> sh_box = rl->load("res://map_dc/coronado/city_kit/traffic/shaders/traffic_box.gdshader");
	Ref<Texture2D> atlas = rl->load("res://vehicles/models/Textures/car_atlas_1024.png");
	Ref<Texture2D> atlas_far = rl->load("res://vehicles/models/Textures/car_atlas_512.png");
	if (atlas_far.is_null()) atlas_far = atlas;
	mat_near.instantiate(); mat_near->set_shader(sh_car); mat_near->set_shader_parameter("atlas", atlas); mat_near->set_shader_parameter("parked_cut", (float)parked_mid_r);
	mat_mid.instantiate(); mat_mid->set_shader(sh_car); mat_mid->set_shader_parameter("atlas", atlas_far); mat_mid->set_shader_parameter("parked_cut", (float)parked_mid_r);
	mat_box.instantiate(); mat_box->set_shader(sh_box); mat_box->set_shader_parameter("atlas", atlas_far); mat_box->set_shader_parameter("parked_cut", (float)parked_mid_r);
	near_b.resize(cm::N_MODELS); mid_b.resize(cm::N_MODELS); mid_parked.assign(cm::N_MODELS, std::vector<int32_t>());
	for (int m = 0; m < cm::N_MODELS; m++) {
		make_batch(near_b[m], mesh_near[m], mat_near, 8, shadows);
		make_batch(mid_b[m], mesh_mid[m], mat_mid, 64, shadows);
	}
	make_batch(box_moving, mesh_box, mat_box, 256, false);
	// the lamp glows: four squares at the corners of a unit car (x = left / right, z = front / back), made here
	{
		PackedVector3Array v; PackedVector2Array uv, uv2; PackedInt32Array ix;
		for (int q = 0; q < 4; q++) {
			const float sx = (q & 1) ? 0.70f : -0.70f, sz = (q & 2) ? 1.01f : -1.01f, y = 0.47f, hx = 0.19f, hy = 0.075f;
			const int at = (int)v.size();
			v.push_back(Vector3(sx - hx, y - hy, sz)); v.push_back(Vector3(sx + hx, y - hy, sz)); v.push_back(Vector3(sx + hx, y + hy, sz)); v.push_back(Vector3(sx - hx, y + hy, sz));
			uv.push_back(Vector2(0, 0)); uv.push_back(Vector2(1, 0)); uv.push_back(Vector2(1, 1)); uv.push_back(Vector2(0, 1));
			for (int k = 0; k < 4; k++) uv2.push_back(Vector2((q & 2) ? 1.0f : 0.0f, 0.0f));
			const int tri[6] = { 0, 1, 2, 0, 2, 3 };
			for (int k = 0; k < 6; k++) ix.push_back(at + tri[k]);
		}
		Array arr; arr.resize(Mesh::ARRAY_MAX);
		arr[Mesh::ARRAY_VERTEX] = v; arr[Mesh::ARRAY_TEX_UV] = uv; arr[Mesh::ARRAY_TEX_UV2] = uv2; arr[Mesh::ARRAY_INDEX] = ix;
		Ref<ArrayMesh> am; am.instantiate();
		am->add_surface_from_arrays(Mesh::PRIMITIVE_TRIANGLES, arr);
		mesh_lamps = am;
		Ref<Shader> sh_lamps = rl->load("res://map_dc/coronado/city_kit/traffic/shaders/traffic_lamps.gdshader");
		mat_lamps.instantiate(); mat_lamps->set_shader(sh_lamps);
		make_batch(lamps_b, mesh_lamps, mat_lamps, 128, false);
	}
	make_batch(box_parked, mesh_box, mat_box, 1024, false);
	gfx = true;
	// the collision pool: made once, moved afterwards
	if (bodies_on) {
		PhysicsServer3D *ps = PhysicsServer3D::get_singleton();
		const RID space = get_world_3d()->get_space();
		for (int k = 0; k < POOL; k++) {
			pool_shape[k] = ps->box_shape_create();
			ps->shape_set_data(pool_shape[k], Vector3(0.95f, 0.7f, 2.2f));
			pool_body[k] = ps->body_create();
			ps->body_set_mode(pool_body[k], PhysicsServer3D::BODY_MODE_KINEMATIC);
			ps->body_add_shape(pool_body[k], pool_shape[k]);
			ps->body_set_collision_layer(pool_body[k], 16);   // layer 5: traffic (the rig's ground ray does not look at it)
			ps->body_set_collision_mask(pool_body[k], 0);
			ps->body_set_state(pool_body[k], PhysicsServer3D::BODY_STATE_TRANSFORM, Transform3D(Basis(), Vector3(0, -500.0f - k * 4.0f, 0)));
			ps->body_set_space(pool_body[k], space);
			pool_model[k] = -1;
		}
		pool_made = true;
	}
	{
		std::lock_guard<std::mutex> lock(mx);
		input.max_cars = max_cars; input.density = (float)density;
		input.cells = cells; input.cells_all = cells_all; input.cells_dirty = true;
	}
	if (streets.sig_grid.size() == 3) RenderingServer::get_singleton()->global_shader_parameter_set(StringName("ck_signal_grid"), Vector3(streets.sig_grid[0], streets.sig_grid[1], streets.sig_grid[2]));
	sim->reset_cars(20261119ull);
	quit.store(false);
	worker = std::thread(&CityTraffic::thread_main, this);
	threaded = true;
	set_process(true); set_physics_process(true);
}

void CityTraffic::_exit_tree() {
	if (threaded) {
		quit.store(true);
		if (worker.joinable()) worker.join();
		threaded = false;
	}
	RenderingServer *rs = RenderingServer::get_singleton();
	if (gfx) rs->global_shader_parameter_set(StringName("ck_signal_time"), -1.0f);   // the lamps go back to their own clock
	auto drop = [&](Batch &b) {
		if (b.inst.is_valid()) rs->free_rid(b.inst);
		if (b.mm.is_valid()) rs->free_rid(b.mm);
		b.inst = RID(); b.mm = RID();
	};
	if (gfx) {
		for (Batch &b : near_b) drop(b);
		for (Batch &b : mid_b) drop(b);
		drop(box_moving); drop(box_parked); drop(lamps_b);
		gfx = false;
	}
	if (pool_made) {
		PhysicsServer3D *ps = PhysicsServer3D::get_singleton();
		for (int k = 0; k < POOL; k++) { ps->free_rid(pool_body[k]); ps->free_rid(pool_shape[k]); }
		pool_made = false;
	}
}

// ---------------------------------------------------------------- every frame
void CityTraffic::_process(double p_delta) {
	if (!ready || !gfx) return;
	const int64_t t0 = usec_now();
	Viewport *vp = get_viewport();
	Camera3D *cam = vp ? vp->get_camera_3d() : nullptr;
	if (cam == nullptr) return;
	const Transform3D ct = cam->get_global_transform();
	const Vector3 cp = ct.origin, cf = -ct.basis.get_column(2);
	if (has_last_cam && p_delta > 1.0e-4) {
		const float ix = (float)((cp.x - last_cam.x) / p_delta), iz = (float)((cp.z - last_cam.z) / p_delta);
		if (ix * ix + iz * iz < 150.0f * 150.0f) { vel_x += (ix - vel_x) * 0.2f; vel_z += (iz - vel_z) * 0.2f; }   // (a teleport is no speed)
		else { vel_x = 0.0f; vel_z = 0.0f; }
	}
	last_cam = cp; has_last_cam = true;
	{
		std::lock_guard<std::mutex> lock(mx);
		input.cx = cp.x; input.cy = cp.y; input.cz = cp.z; input.fx = cf.x; input.fz = cf.z; input.fov = (float)cam->get_fov() * 1.6f;   // (the screen is wide: the cone is the horizontal view)
		input.vx = vel_x; input.vz = vel_z;
		input.max_cars = max_cars; input.density = (float)density; input.parked = parked_on;
		now = shared;
		park_now.swap(park_events); park_events.clear();
		cnt.park_out = park_out; cnt.park_in = park_in;
	}
	// stalls that changed: a car pulled out (its stall is empty now) or one parked (the stall takes its model and colour)
	for (const tp::Event &e : park_now) {
		if (e.stall < 0 || e.stall >= (int)stall_car.size()) continue;
		const int ci = cell_index(streets.stall_f[(size_t)e.stall * 8], streets.stall_f[(size_t)e.stall * 8 + 2]);
		if (!cells_all && (ci < 0 || !cells[ci])) continue;   // (its cell has left meanwhile)
		stall_car[e.stall].model = e.model; stall_car[e.stall].colour = e.colour;
		active_dirty = true;
	}
	park_now.clear();
	RenderingServer *rs = RenderingServer::get_singleton();
	const float alpha = std::min(std::max((float)(t0 - now.t_usec) / (STEP_S * 1.0e6f), 0.0f), 1.0f);
	// the lamps run on the traffic's clock: a car stops at the red the player sees
	rs->global_shader_parameter_set(StringName("ck_signal_time"), (float)std::fmod(now.clock - STEP_S + alpha * STEP_S, 3600.0));

	for (Batch &b : near_b) b.n = 0;
	for (Batch &b : mid_b) b.n = 0;
	box_moving.n = 0; lamps_b.n = 0;
	body_want.clear();

	// ---- parked cars
	if (active_dirty) rebuild_active();
	const float pm_in = (float)parked_mid_r + 2.0f, pm_out = (float)parked_mid_r + 6.0f;
	if (!active.empty()) {
		// which of them are near enough for the light model: a slice of the list a frame (they do not move; the camera does)
		const size_t slice = std::min(active.size(), (size_t)700);
		for (size_t q = 0; q < slice; q++) {
			if (band_cursor >= active.size()) band_cursor = 0;
			const int k = active[band_cursor++];
			const float *f = &streets.stall_f[(size_t)k * 8];
			const float dx = f[0] - cp.x, dz = f[2] - cp.z, d2 = dx * dx + dz * dz;
			const bool want = d2 < (stall_mid[k] ? pm_out * pm_out : pm_in * pm_in);
			if (want == (stall_mid[k] != 0)) continue;
			std::vector<int32_t> &lst = mid_parked[stall_car[k].model];
			if (want) lst.push_back(k);
			else { auto it = std::find(lst.begin(), lst.end(), k); if (it != lst.end()) { *it = lst.back(); lst.pop_back(); } }
			stall_mid[k] = want ? 1 : 0;
		}
	}
	int parked_mid_n = 0;
	const float lamps = (float)night;
	for (int m = 0; m < cm::N_MODELS; m++) {
		const std::vector<int32_t> &lst = mid_parked[m];
		if (lst.empty()) continue;
		grow(mid_b[m], (int)lst.size() + 16);
		float *w = mid_b[m].buf.ptrw();
		for (int32_t k : lst) {
			const float *f = &streets.stall_f[(size_t)k * 8];
			put_row(w + (size_t)mid_b[m].n * ROW, f[0], f[1] + 0.02f, f[2], f[3], f[4], 1.0f, 1.0f, 1.0f, PAINT[stall_car[k].colour], 0.0f, 0.0f, 0.0f, 1.0f);
			mid_b[m].n++; parked_mid_n++;
			const float dx = f[0] - cp.x, dz = f[2] - cp.z;
			if (bodies_on && dx * dx + dz * dz < 30.0f * 30.0f) body_want.push_back(BodyWant{ dx * dx + dz * dz, f[0], f[1], f[2], f[3], f[4], m });
		}
	}

	// ---- moving cars: each between its last two poses, by its own step length
	struct Near { float d2; int i; };
	Near nearest[16];
	int n_near = 0;
	static thread_local float pose[MAX_ROWS][6];   // x, y, z, yaw, pitch, d2
	for (int i = 0; i < now.n; i++) {
		const Row &r = now.rows[i];
		const float a = std::min(std::max(((float)(now.tick - r.tu) + alpha) / (float)r.span, 0.0f), 1.0f);
		float *p = pose[i];
		p[0] = r.px + (r.x - r.px) * a; p[1] = r.py + (r.y - r.py) * a; p[2] = r.pz + (r.z - r.pz) * a;
		p[3] = lerp_angle(r.pyaw, r.yaw, a); p[4] = r.ppitch + (r.pitch - r.ppitch) * a;
		const float dx = p[0] - cp.x, dy = p[1] - cp.y, dz = p[2] - cp.z;
		p[5] = dx * dx + dy * dy + dz * dz;
		if (p[5] < (float)(near_r * near_r) && near_max > 0) {   // the few nearest get the near model
			int at = n_near < near_max ? n_near++ : -1;
			if (at < 0) { int worst = 0; for (int q = 1; q < n_near; q++) if (nearest[q].d2 > nearest[worst].d2) worst = q; if (nearest[worst].d2 > p[5]) at = worst; }
			if (at >= 0) nearest[at] = Near{ p[5], i };
		}
	}
	int c_near = 0, c_mid = 0, c_box = 0;
	for (int i = 0; i < now.n; i++) {
		const Row &r = now.rows[i];
		const float *p = pose[i];
		if (r.model >= cm::N_MODELS) continue;
		const float *col = PAINT[r.colour % N_COLOURS];
		const float brake = (r.flags & 1) ? 1.0f : 0.0f, ind = (float)((r.flags >> 1) & 3);
		bool is_near = false;
		for (int q = 0; q < n_near; q++) if (nearest[q].i == i) is_near = true;
		if (is_near) {
			Batch &b = near_b[r.model];
			if (b.n < b.cap) { put_row(b.buf.ptrw() + (size_t)b.n * ROW, p[0], p[1], p[2], p[3], p[4], 1.0f, 1.0f, 1.0f, col, brake, ind, lamps, 0.0f); b.n++; c_near++; }
		} else if (p[5] < (float)(mid_r * mid_r)) {
			Batch &b = mid_b[r.model];
			grow(b, b.n + 1);
			put_row(b.buf.ptrw() + (size_t)b.n * ROW, p[0], p[1], p[2], p[3], p[4], 1.0f, 1.0f, 1.0f, col, brake, ind, lamps, 0.0f); b.n++; c_mid++;
		} else if (p[5] < (float)(far_r * far_r)) {
			const cm::CarModel &m = cm::MODELS[r.model];
			grow(box_moving, box_moving.n + 1);
			put_row(box_moving.buf.ptrw() + (size_t)box_moving.n * ROW, p[0], p[1], p[2], p[3], p[4], m.half_w * 2.0f / box_size[0], m.height / (box_size[1] + box_y0), m.half_len * 2.0f / box_size[2],
					col, brake, 0.0f, lamps, 0.0f);
			box_moving.n++; c_box++;
		}
		// its lamps: at night every car to lamps_r, by day a braking car's tail lights to 60 m
		if ((lamps > 0.01f && p[5] < (float)(lamps_r * lamps_r)) || (brake > 0.5f && p[5] < 60.0f * 60.0f)) {
			const cm::CarModel &m = cm::MODELS[r.model];
			grow(lamps_b, lamps_b.n + 1);
			put_row(lamps_b.buf.ptrw() + (size_t)lamps_b.n * ROW, p[0], p[1], p[2], p[3], p[4], m.half_w, m.height, m.half_len, PAINT[0], brake, 0.0f, lamps, 0.0f);
			lamps_b.n++;
		}
		if (bodies_on && p[5] < 70.0f * 70.0f) body_want.push_back(BodyWant{ p[5], p[0], p[1], p[2], p[3], p[4], (int)r.model });
	}
	// ---- the first frames: one small row of everything in front of the camera, so every shader is built at the start
	if (warm_frames > 0) {
		warm_frames--;
		const Vector3 wp = cp + cf * 8.0f;
		for (int m = 0; m < cm::N_MODELS; m++) {
			if (near_b[m].n == 0) { put_row(near_b[m].buf.ptrw(), wp.x, wp.y - 1.0f, wp.z, 0, 0, 0.02f, 0.02f, 0.02f, PAINT[0], 0, 0, 1, 0); near_b[m].n = 1; }
			if (mid_b[m].n == 0) { put_row(mid_b[m].buf.ptrw(), wp.x, wp.y - 1.0f, wp.z, 0, 0, 0.02f, 0.02f, 0.02f, PAINT[0], 0, 0, 1, 0); mid_b[m].n = 1; }
		}
		if (box_moving.n == 0) { put_row(box_moving.buf.ptrw(), wp.x, wp.y - 1.0f, wp.z, 0, 0, 0.02f, 0.02f, 0.02f, PAINT[0], 0, 0, 1, 0); box_moving.n = 1; }
		if (lamps_b.n == 0) { put_row(lamps_b.buf.ptrw(), wp.x, wp.y - 1.0f, wp.z, 0, 0, 0.02f, 0.02f, 0.02f, PAINT[0], 1, 0, 1, 0); lamps_b.n = 1; }
	}
	// ---- to the graphics card: a batch with rows this frame, or that had rows last frame; the parked far batch only when it changed
	int batches = 0;
	for (int m = 0; m < cm::N_MODELS; m++) {
		if (near_b[m].n > 0) { near_b[m].dirty = true; batches++; }
		if (mid_b[m].n > 0) { mid_b[m].dirty = true; batches++; }
		send(near_b[m]); send(mid_b[m]);
	}
	if (box_moving.n > 0) { box_moving.dirty = true; batches++; }
	send(box_moving);
	if (lamps_b.n > 0) { lamps_b.dirty = true; batches++; }
	send(lamps_b);
	if (box_parked.n > 0) batches++;
	send(box_parked);

	const double us = (double)(usec_now() - t0);
	cnt.frames++; cnt.main_us += us; cnt.main_us_worst = std::max(cnt.main_us_worst, us);
	cnt.step_us += now.step_us; cnt.step_us_worst = std::max(cnt.step_us_worst, (double)now.step_us); cnt.steps++;
	cnt.moving += now.n; cnt.moving_most = std::max(cnt.moving_most, now.n);
	cnt.near += c_near; cnt.mid += c_mid; cnt.box += c_box; cnt.parked_mid += parked_mid_n; cnt.parked_all += (double)active.size(); cnt.batches += batches; cnt.carry += now.carry;
}

// The pool's bodies go onto the cars nearest the camera (moving cars to 70 m, parked ones to 30 m). Only transforms
// are sent; a body changes its box only when it gets a car of another model.
void CityTraffic::_physics_process(double p_delta) {
	if (!pool_made || !bodies_on) return;
	PhysicsServer3D *ps = PhysicsServer3D::get_singleton();
	const int n = (int)body_want.size();
	const int use = std::min(n, (int)POOL);
	if (n > POOL) std::partial_sort(body_want.begin(), body_want.begin() + POOL, body_want.end(), [](const BodyWant &a, const BodyWant &b) { return a.d2 < b.d2; });
	for (int k = 0; k < POOL; k++) {
		if (k < use) {
			const BodyWant &w = body_want[k];
			const cm::CarModel &m = cm::MODELS[w.model];
			if (pool_model[k] != w.model) { ps->shape_set_data(pool_shape[k], Vector3(m.half_w, m.height * 0.5f, m.half_len)); pool_model[k] = w.model; }
			Basis bs = Basis(Vector3(0, 1, 0), w.yaw) * Basis(Vector3(1, 0, 0), -w.pitch);
			ps->body_set_state(pool_body[k], PhysicsServer3D::BODY_STATE_TRANSFORM, Transform3D(bs, Vector3(w.x, w.y + m.height * 0.5f, w.z)));
		} else if (pool_model[k] != -2) {
			ps->body_set_state(pool_body[k], PhysicsServer3D::BODY_STATE_TRANSFORM, Transform3D(Basis(), Vector3(0, -500.0f - k * 4.0f, 0)));
			pool_model[k] = -2;   // put away
		}
	}
}

String CityTraffic::report() {
	const double f = std::max(cnt.frames, 1);
	String s = vformat("cars moving avg %.1f most %d (the streets there carry %.0f, the cap is %d): near model %.1f, light model %.1f, far shape %.1f | parked: %.0f in the loaded cells, %.1f drawn with the light model | batches drawn avg %.1f, uploads a frame %.1f | main thread a frame: avg %.3f worst %.3f ms | the step (own thread): avg %.3f worst %.3f ms",
			cnt.moving / f, cnt.moving_most, cnt.carry / f, max_cars, cnt.near / f, cnt.mid / f, cnt.box / f, cnt.parked_all / f, cnt.parked_mid / f, cnt.batches / f, (double)cnt.uploads / f,
			cnt.main_us / f / 1000.0, cnt.main_us_worst / 1000.0, cnt.step_us / std::max(cnt.steps, 1) / 1000.0, cnt.step_us_worst / 1000.0);
	s += vformat(" | pulled out of a stall %d, parked %d (since the start)", cnt.park_out, cnt.park_in);
	cnt = Count();
	return s;
}

} // namespace godot
