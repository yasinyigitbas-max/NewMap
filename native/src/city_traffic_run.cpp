// CityTraffic at run time: the step on its own thread, the car batches, the parked cars, the streamer's cells, the
// collision pool. See city_traffic.h for how it hangs together.
#include "perf_marks.h"
#include "city_traffic.h"
#include "el_sfx.h"
#include "city_sfx.h"
#include <godot_cpp/classes/audio_stream_player3d.hpp>
#include "bike_look.h"

#include <godot_cpp/classes/box_shape3d.hpp>
#include <godot_cpp/classes/collision_shape3d.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/physics_material.hpp>
#include <godot_cpp/classes/rigid_body3d.hpp>

#include "car_models.h"
#include "city_car.h"
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
// bicycle frames (linear): red, black, white, teal, orange, navy, mint, yellow
const float BIKE_PAINT[8][3] = {
	{ 0.45f, 0.02f, 0.02f }, { 0.015f, 0.015f, 0.017f }, { 0.75f, 0.75f, 0.72f }, { 0.02f, 0.25f, 0.25f },
	{ 0.70f, 0.20f, 0.02f }, { 0.02f, 0.04f, 0.16f }, { 0.35f, 0.62f, 0.45f }, { 0.75f, 0.55f, 0.03f }
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
		input.kill_ids.clear(); input.kill_stalls.clear(); input.adopt.clear(); input.orders.clear(); input.panics.clear();
	}
	sim->cfg.max_cars = std::min(in.max_cars, (int)MAX_ROWS - 2);
	sim->cfg.max_bikes = in.bikes;
	if (!in.orders.empty()) {   // the game's own cars: routed by the core's finder, answered by ticket
		std::vector<std::pair<int, int>> done;
		for (const Input::Order &o : in.orders) done.push_back({ o.ticket, exec_order(o) });
		std::lock_guard<std::mutex> lock(mx);
		order_done.insert(order_done.end(), done.begin(), done.end());
	}
	for (size_t k = 0; k + 2 < in.panics.size(); k += 3) {   // shots heard: the drivers round them drive off hard
		const float r2 = in.panics[k + 2] * in.panics[k + 2];
		for (int i = 0; i < sim->hi; i++) {
			if (!sim->alive[i] || sim->kind[i] != tc::K_AMBIENT) continue;
			const float dx = sim->x[i] - in.panics[k], dz = sim->z[i] - in.panics[k + 1];
			if (dx * dx + dz * dz <= r2 && sim->temper[i] != 2) { sim->temper[i] = 2; panicked++; }
		}
	}
	// the buses: a timetable in real seconds; every 5 minutes by day, every 15 in the evening, every half hour at night
	{
		const float tph = in.bus_tph > 0.0f ? in.bus_tph : ((in.hour >= 6.0f && in.hour < 21.0f) ? 12.0f : (in.hour >= 5.0f ? 4.0f : 2.0f));
		for (tc::Sim::Route &R : sim->routes) for (int k = 0; k < 24; k++) R.tph[k] = tph;
		sim->set_time_of_day(std::fmod(p_clock, 86400.0));
	}
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
	// cars and parked cars that became physical cars since the last step: out of the core's books
	for (int32_t kid : in.kill_ids) { const int ki = sim->find_car(kid); if (ki >= 0) sim->despawn(ki, 8); }
	for (int32_t ks : in.kill_stalls) parking.knock_out(ks);
	parking.tick(*sim, STEP_S);
	// the boxes the drivers see beside each other: parked cars near a car that pulls in or out, the player's car, the
	// knocked cars (all but `skip`, and not one that is a row again)
	auto boxes = [&](int skip) {
		dyn_all = parking.dyn;
		if (in.pc) {
			const float b[tc::DYN_STRIDE] = { in.pcx, in.pcy, in.pcz, in.pcyaw, in.pchl, in.pchw, in.pcvx, in.pcvz, (float)tc::DYN_PLAYER_CAR, -2.0f, 0.0f };
			dyn_all.insert(dyn_all.end(), b, b + tc::DYN_STRIDE);
		}
		for (int k = 0; k < LOOSE; k++) {
			const Input::LooseBox &q = in.lb[k];
			if (!q.on || k == skip || q.serial == adopted_serial[k]) continue;
			const float b[tc::DYN_STRIDE] = { q.x, q.y, q.z, q.yaw, q.hl, q.hw, q.vx, q.vz, (float)tc::DYN_OTHER, (float)(200000 + k), 0.0f };
			dyn_all.insert(dyn_all.end(), b, b + tc::DYN_STRIDE);
		}
		// the crowd's people on a road or waiting to cross (as many as the core's list still takes)
		const size_t room = (size_t)tc::MAX_DYN * tc::DYN_STRIDE;
		if (!in.walkers.empty() && dyn_all.size() < room) dyn_all.insert(dyn_all.end(), in.walkers.begin(), in.walkers.begin() + std::min(in.walkers.size(), ((room - dyn_all.size()) / tc::DYN_STRIDE) * tc::DYN_STRIDE));
		sim->set_dynamic((int)dyn_all.size() / tc::DYN_STRIDE, dyn_all.data());
	};
	// a knocked car whose driver wants to drive on: it must stand along a lane, near it, with nothing in its place
	std::vector<AdoptDone> done;
	for (const Input::Adopt &a : in.adopt) {
		if (a.slot < 0 || a.slot >= LOOSE || a.serial == adopted_serial[a.slot]) continue;
		boxes(a.slot);
		int nid = -1;   // (or why not: -1 no lane within 3.6 m, -2 at a lane's end, -3 it stands across the lane, -4 the core is full, -5 something stands in its way)
		float as = 0.0f;
		const int L = sim->nearest_lane(a.x, a.z, 3.6f, &as);
		if (L >= 0 && !(as > 3.0f && as < sim->p_len[L] - 6.0f)) nid = -2;
		if (L >= 0 && as > 3.0f && as < sim->p_len[L] - 6.0f) {
			float o[7]; int hint = 0;
			sim->pose_at(L, as, 0.0f, 0.0f, 0.0f, 1.0f, hint, o);
			float dy = std::fmod(a.yaw - o[6] + 3.14159265f, 6.2831853f); if (dy < 0.0f) dy += 6.2831853f; dy -= 3.14159265f;
			nid = -3;
			if (std::fabs(dy) < 0.40f) {
				const float lat = (a.x - o[0]) * o[4] - (a.z - o[2]) * o[3];   // + = left of travel
				const int i = sim->unpark(L, as, lat, a.model, 1);
				nid = -4;
				if (i >= 0) {   // where it really stands: its body steers back to the lane's middle from there
					sim->x[i] = sim->px[i] = a.x; sim->z[i] = sim->pz[i] = a.z; sim->yaw[i] = sim->pyaw[i] = a.yaw;
					sim->fx[i] = std::sin(a.yaw); sim->fz[i] = std::cos(a.yaw);
					if (sim->blocked_by(i, sim->x[i], sim->y[i], sim->z[i], sim->fx[i], sim->fz[i], 0.06f)) { sim->alive[i] = 0; sim->n_alive--; nid = -5; }
					else { sim->colour[i] = (uint8_t)(100 + a.colour); nid = sim->id[i]; adopted_serial[a.slot] = a.serial; }
				}
			}
		}
		done.push_back(AdoptDone{ a.slot, a.serial, nid });
	}
	boxes(-1);
	sim->step(STEP_S, p_clock);
	sim->events.clear();
	static thread_local Snap s;
	s.n = 0;
	if (odo_id.empty()) { odo_id.assign(tc::MAX_CARS, -1); odo_now.assign(tc::MAX_CARS, 0.0f); odo_prev = odo_now; steer_now = odo_now; steer_prev = odo_now; }
	for (int i = 0; i < sim->hi && s.n < MAX_ROWS; i++) {
		if (!sim->alive[i]) continue;
		if (odo_id[i] != sim->id[i]) { odo_id[i] = sim->id[i]; odo_now[i] = odo_prev[i] = 0.0f; steer_now[i] = steer_prev[i] = sim->steer[i]; }
		else if (sim->tu[i] == sim->tick) {   // it moved this step
			const float mx_ = sim->x[i] - sim->px[i], mz_ = sim->z[i] - sim->pz[i];
			odo_prev[i] = odo_now[i]; odo_now[i] += std::sqrt(mx_ * mx_ + mz_ * mz_) * (sim->v[i] < 0.0f ? -1.0f : 1.0f);
			if (odo_now[i] > 4000.0f) { odo_now[i] -= 4000.0f; odo_prev[i] -= 4000.0f; }
			steer_prev[i] = steer_now[i]; steer_now[i] = sim->steer[i];
		}
		Row &r = s.rows[s.n++];
		r.odo = odo_now[i]; r.podo = odo_prev[i]; r.psteer = steer_prev[i];
		r.id = sim->id[i]; r.model = sim->model[i]; r.colour = tp::Parking::car_colour(*sim, i); r.kind = sim->kind[i];
		r.flags = (uint8_t)(((sim->flags[i] & tc::F_BRAKE) ? 1 : 0) | ((sim->flags[i] & tc::F_IND_L) ? 2 : 0) | ((sim->flags[i] & tc::F_IND_R) ? 4 : 0));
		r.x = sim->x[i]; r.y = sim->y[i]; r.z = sim->z[i]; r.yaw = sim->yaw[i]; r.pitch = sim->pitch[i];
		r.px = sim->px[i]; r.py = sim->py[i]; r.pz = sim->pz[i]; r.pyaw = sim->pyaw[i]; r.ppitch = sim->ppitch[i];
		r.v = sim->v[i]; r.hl = sim->hl[i]; r.hw = sim->hw[i]; r.roll = sim->roll[i]; r.proll = sim->proll[i]; r.steer = steer_now[i];
		r.tu = sim->tu[i]; r.span = std::max(1, (int)sim->span[i]);
		r.stop = sim->bus_stop_tag(i);
	}
	std::vector<float> downs;
	for (const tc::Sim::BikeDown &b : sim->bike_downs) {
		const float f[9] = { b.x, b.y, b.z, b.yaw, b.v, b.hvx, b.hvz, (float)b.id, (float)b.colour };
		downs.insert(downs.end(), f, f + 9);
	}
	sim->bike_downs.clear();
	s.tick = sim->tick; s.t_usec = usec_now(); s.clock = p_clock + STEP_S;
	s.step_us = (float)sim->st.last_step_us; s.carry = sim->carry;
	s.spawned = sim->st.spawned; s.despawned = sim->st.despawned; s.buses = sim->st.buses_spawned; s.bus_stops = sim->st.bus_stops_served;
	{
		std::lock_guard<std::mutex> lock(mx);
		shared = s;
		adopt_done.insert(adopt_done.end(), done.begin(), done.end());
		park_events.insert(park_events.end(), parking.events.begin(), parking.events.end());
		park_out = parking.pulled_out; park_in = parking.parked;
		downs_shared.insert(downs_shared.end(), downs.begin(), downs.end());
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
// A cyclist came off (d: x, y, z, yaw, speed, the car's vx, vz, id, paint): his bicycle is thrown on in the way it
// went and pushed by the car, tumbles and lies. The oldest of the four is taken when all are lying somewhere.
void CityTraffic::bike_fall(const float *d) {
	bikes_down_n++;
	if (!bodies_on) return;
	Fallen &fb = fallen[fallen_next];
	fallen_next = (fallen_next + 1) % FALLEN;
	if (!fb.body) return;
	const float yaw = d[3], v = d[4];
	const Vector3 f(std::sin(yaw), 0.0f, std::cos(yaw));
	fb.body->set_freeze_enabled(false);
	fb.body->set_global_transform(Transform3D(Basis(Vector3(0, 1, 0), yaw), Vector3(d[0], d[1] + 0.02f, d[2])));
	const Vector3 hit(d[5], 0.0f, d[6]);
	fb.body->set_linear_velocity(f * v * 0.8f + hit * 0.7f + Vector3(0, 1.2f, 0));
	const float side = (hit.x * f.z - hit.z * f.x) >= 0.0f ? 1.0f : -1.0f;   // it goes over away from the blow
	fb.body->set_angular_velocity(f * (3.5f * side) + Vector3(0, 1.0f * side, 0));
	const float *col = BIKE_PAINT[((int)d[8]) % 8];
	fb.mat->set_shader_parameter("paint_u", Vector3(col[0], col[1], col[2]));
	fb.body->set_visible(true);
	fb.on = true; fb.t = 0.0f; fb.slow = 0.0f;
}

Dictionary CityTraffic::bike_stats() const {
	Dictionary d;
	d["down"] = bikes_down_n;
	Array lying;
	for (const Fallen &fb : fallen) {
		if (!fb.on || !fb.body) continue;
		Dictionary b;
		const Transform3D t = fb.body->get_global_transform();
		b["at"] = t.origin; b["up"] = t.basis.get_column(1).y; b["speed"] = fb.body->get_linear_velocity().length(); b["age"] = fb.t; b["frozen"] = fb.body->is_freeze_enabled(); b["still_s"] = fb.slow; b["spin"] = fb.body->get_angular_velocity().length();
		lying.push_back(b);
	}
	d["fallen"] = lying;
	return d;
}

String CityTraffic::bike_shader_code() {
	return String(
				"shader_type spatial;\n"
				"// the traffic's bicycles (CityTraffic::make_bike_mesh): UV.x 0 = the frame (the row's paint), 1 = rubber, 2 = metal, 3 = saddle and grips\n"
				"uniform vec3 paint_u = vec3(-1.0);   // (a fallen bicycle: a body of its own, not a row)\n"
				"varying vec3 paint;\n"
				"varying float part;\n"
				"void vertex() { paint = paint_u.x >= 0.0 ? paint_u : INSTANCE_CUSTOM.rgb; part = UV.x; }\n"
				"void fragment() {\n"
				"\tvec3 c = part < 0.5 ? paint : (part < 1.5 ? vec3(0.03) : (part < 2.5 ? vec3(0.55) : vec3(0.08, 0.06, 0.05)));\n"
				"\tALBEDO = c; ROUGHNESS = part < 0.5 ? 0.45 : (part < 2.5 && part > 1.5 ? 0.3 : 0.85); METALLIC = part > 1.5 && part < 2.5 ? 0.8 : 0.0;\n"
				"}\n");
}

// A bicycle, made here (no file): the rider's frame of the far figures' riding poses (people_bake.h): origin on the
// ground under the crank's axle, +z forward, wheels of 0.34 m. Tubes are four-sided rods; UV.x says what each part is
// (0 frame, 1 rubber, 2 metal, 3 saddle and grips). About 600 triangles.
Ref<Mesh> CityTraffic::make_bike_mesh() {
	PackedVector3Array v, nrm; PackedVector2Array uv; PackedInt32Array ix;
	auto rod = [&](Vector3 a, Vector3 b, float r, float part) {
		Vector3 d = b - a;
		if (d.length_squared() < 1e-8f) return;
		d.normalize();
		Vector3 s1 = std::fabs(d.y) < 0.9f ? d.cross(Vector3(0, 1, 0)).normalized() : d.cross(Vector3(1, 0, 0)).normalized();
		const Vector3 s2 = d.cross(s1);
		const Vector3 side[4] = { s1, s2, -s1, -s2 };
		for (int k = 0; k < 4; k++) {
			const Vector3 o0 = side[k] * r, o1 = side[(k + 1) & 3] * r, nn = (side[k] + side[(k + 1) & 3]).normalized();
			const int at = (int)v.size();
			v.push_back(a + o0); v.push_back(a + o1); v.push_back(b + o1); v.push_back(b + o0);
			for (int q = 0; q < 4; q++) { nrm.push_back(nn); uv.push_back(Vector2(part, 0)); }
			const int tri[6] = { 0, 2, 1, 0, 3, 2 };
			for (int q = 0; q < 6; q++) ix.push_back(at + tri[q]);
		}
	};
	auto wheel = [&](float zc) {
		const float R = 0.34f, yc = 0.34f;
		const int N = 14;
		for (int k = 0; k < N; k++) {
			const float a0 = 6.2831853f * k / N, a1 = 6.2831853f * (k + 1) / N;
			rod(Vector3(0, yc + R * std::cos(a0), zc + R * std::sin(a0)), Vector3(0, yc + R * std::cos(a1), zc + R * std::sin(a1)), 0.028f, 1.0f);
			rod(Vector3(0, yc + 0.30f * std::cos(a0), zc + 0.30f * std::sin(a0)), Vector3(0, yc + 0.30f * std::cos(a1), zc + 0.30f * std::sin(a1)), 0.012f, 2.0f);
		}
		for (int k = 0; k < 4; k++) {   // spokes, a few
			const float a = 3.14159265f * k / 4;
			rod(Vector3(0, yc + 0.29f * std::cos(a), zc + 0.29f * std::sin(a)), Vector3(0, yc - 0.29f * std::cos(a), zc - 0.29f * std::sin(a)), 0.004f, 2.0f);
		}
	};
	const Vector3 bb(0, 0.28f, 0), rear(0, 0.34f, -0.42f), front(0, 0.34f, 0.60f);
	const Vector3 seat_top(0, 0.80f, -0.15f), head_top(0, 0.92f, 0.47f), head_bot(0, 0.76f, 0.52f);
	wheel(rear.z); wheel(front.z);
	rod(bb, seat_top, 0.018f, 0.0f);          // seat tube
	rod(bb, head_bot, 0.022f, 0.0f);          // down tube
	rod(seat_top, head_top, 0.018f, 0.0f);    // top tube
	rod(bb, rear, 0.012f, 0.0f);              // chain stay
	rod(seat_top, rear, 0.011f, 0.0f);        // seat stay
	rod(head_bot, head_top, 0.022f, 0.0f);    // head tube
	rod(head_bot, front, 0.014f, 0.0f);       // fork
	rod(seat_top, Vector3(0, 0.90f, -0.17f), 0.012f, 2.0f);   // seat post
	rod(Vector3(0, 0.91f, -0.27f), Vector3(0, 0.91f, -0.05f), 0.055f, 3.0f);   // saddle
	rod(head_top, Vector3(0, 1.06f, 0.42f), 0.013f, 2.0f);    // stem
	rod(Vector3(-0.26f, 1.06f, 0.40f), Vector3(0.26f, 1.06f, 0.40f), 0.012f, 2.0f);   // bar
	rod(Vector3(-0.26f, 1.06f, 0.40f), Vector3(-0.17f, 1.06f, 0.40f), 0.018f, 3.0f);  // grips
	rod(Vector3(0.17f, 1.06f, 0.40f), Vector3(0.26f, 1.06f, 0.40f), 0.018f, 3.0f);
	rod(Vector3(-0.09f, 0.28f, 0.0f), Vector3(0.09f, 0.28f, 0.0f), 0.04f, 2.0f);      // the crank's axle and chainring
	Array arr; arr.resize(Mesh::ARRAY_MAX);
	arr[Mesh::ARRAY_VERTEX] = v; arr[Mesh::ARRAY_NORMAL] = nrm; arr[Mesh::ARRAY_TEX_UV] = uv; arr[Mesh::ARRAY_INDEX] = ix;
	Ref<ArrayMesh> am; am.instantiate();
	am->add_surface_from_arrays(Mesh::PRIMITIVE_TRIANGLES, arr);
	return am;
}

static const float NEAR_BAND = 4.0f, MID_BAND = 10.0f;   // B6: metres a car crosses between two of its models

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

// The four wheels of a car whose row (not yet leaned) is car_row: each at its hub, the front ones turned by `steer`
// (rad, + = left), all rolled by the metres the car has gone. The right-hand wheels are the same mesh turned about.
void CityTraffic::put_wheels(float *w, const float *car_row, const WheelSet &ws, float steer, float odo) {
	const float L[3] = { car_row[0], car_row[4], car_row[8] }, U[3] = { car_row[1], car_row[5], car_row[9] }, F[3] = { car_row[2], car_row[6], car_row[10] };
	const float roll = std::fmod(odo / std::max(ws.r, 0.1f), 6.2831853f);
	for (int k = 0; k < 4; k++) {
		const bool front = k < 2, left = (k & 1) == 0;
		const float a = (front ? steer : 0.0f) + (left ? 0.0f : 3.14159265f), b = left ? roll : -roll;
		const float ca = std::cos(a), sa = std::sin(a), cb = std::cos(b), sb = std::sin(b);
		// the wheel's own axes in the car's (left, up, forward): a turn about up, then a roll about its axle
		const float m[3][3] = { { ca, 0.0f, -sa }, { sa * sb, cb, ca * sb }, { sa * cb, -sb, ca * cb } };
		float *r = w + (size_t)k * ROW;
		for (int e = 0; e < 3; e++) {
			for (int c = 0; c < 3; c++) r[e * 4 + c] = L[e] * m[c][0] + U[e] * m[c][1] + F[e] * m[c][2];
			r[e * 4 + 3] = car_row[e * 4 + 3] + L[e] * ws.h[k][0] + U[e] * ws.h[k][1] + F[e] * ws.h[k][2];
		}
		for (int c = 12; c < 20; c++) r[c] = car_row[c];
	}
}

void CityTraffic::lean_row(float *r, float roll) {
	if (roll > -1.0e-4f && roll < 1.0e-4f) return;
	const float c = std::cos(roll), sn = std::sin(roll);
	for (int k = 0; k < 3; k++) {   // left and up turn about forward: + = the left side rises
		const float l = r[k * 4], u = r[k * 4 + 1];
		r[k * 4] = l * c + u * sn; r[k * 4 + 1] = u * c - l * sn;
	}
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
	{   // the new car textures (car-tex r3): each model its own near and light material; the far shape is volt_x's (stern_g_imp)
		const String cx = "res://vehicles/models/cartex/";
		mat_near_m.resize(cm::N_MODELS); mat_mid_m.resize(cm::N_MODELS);
		for (int m = 0; m < cm::N_MODELS; m++) {
			const String id = cm::MODELS[m].id, t = id == "stern_g" ? String("volt_x") : id;
			const String base = String("res://vehicles/models/lod/") + id;
			Ref<Mesh> qb = rl->exists(base + String("_q_body.res")) ? Ref<Mesh>(rl->load(base + String("_q_body.res"))) : Ref<Mesh>();
			const bool ok = rl->exists(cx + t + String("_car_normal.png")) && rl->exists(cx + t + String("_far_albedo.png")) && qb.is_valid() && qb->has_meta("cartex");
			if (!ok) { mat_near_m[m] = mat_near; mat_mid_m[m] = mat_mid; continue; }
			Ref<ShaderMaterial> n = mat_near->duplicate(), f = mat_mid->duplicate();
			n->set_shader_parameter("map_mode", 2);
			n->set_shader_parameter("trim_albedo", rl->load(cx + String("trim_albedo.png")));
			n->set_shader_parameter("trim_normal", rl->load(cx + String("trim_normal.png")));
			n->set_shader_parameter("trim_orm", rl->load(cx + String("trim_orm.png")));
			n->set_shader_parameter("car_normal", rl->load(cx + t + String("_car_normal.png")));
			n->set_shader_parameter("car_orm", rl->load(cx + t + String("_car_orm.png")));
			f->set_shader_parameter("map_mode", 1);
			f->set_shader_parameter("albedo_map", rl->load(cx + t + String("_far_albedo.png")));
			f->set_shader_parameter("orm_map", rl->load(cx + t + String("_far_orm.png")));
			mat_near_m[m] = n; mat_mid_m[m] = f;
		}
		if (rl->exists(cx + String("volt_x_far_albedo.png"))) mat_box->set_shader_parameter("atlas", rl->load(cx + String("volt_x_far_albedo.png")));
	}
	near_b.resize(cm::N_MODELS); mid_b.resize(cm::N_MODELS); mid_parked.assign(cm::N_MODELS, std::vector<int32_t>());
	wheel_b.resize(cm::N_MODELS); wheels.assign(cm::N_MODELS, WheelSet()); mesh_nbody.resize(cm::N_MODELS); mesh_wheel.resize(cm::N_MODELS);
	for (int m = 0; m < cm::N_MODELS; m++) {
		// the body without its wheels and one wheel, when the model has them (the body mesh notes where its wheels are)
		const String base = String("res://vehicles/models/lod/") + cm::MODELS[m].id;
		if (rl->exists(base + String("_q_body.res"))) {
			Ref<Mesh> bm = rl->load(base + String("_q_body.res"));
			if (bm.is_valid() && bm->has_meta("wheels")) {
				const Array wl = bm->get_meta("wheels");
				int got = 0, fl = -1;
				float rsum = 0.0f;
				for (int k = 0; k < (int)wl.size() && wl.size() == 4; k++) {
					const Dictionary w = wl[k];
					const Vector3 c = w.get("center", Vector3());
					const int slot = (c.z > 0.0f ? 0 : 2) + (c.x > 0.0f ? 0 : 1);
					wheels[m].h[slot][0] = c.x; wheels[m].h[slot][1] = c.y; wheels[m].h[slot][2] = c.z;
					rsum += (float)(double)w.get("radius", 0.33);
					got |= 1 << slot;
					if (slot == 0) fl = k;
				}
				if (got == 15 && fl >= 0) mesh_wheel[m] = rl->load(base + String("_q_w") + String::num_int64(fl) + String(".res"));
				if (mesh_wheel[m].is_valid()) { wheels[m].on = true; wheels[m].r = rsum * 0.25f; mesh_nbody[m] = bm; }
			}
		}
		make_batch(near_b[m], wheels[m].on ? mesh_nbody[m] : mesh_near[m], mat_near_m[m], 8, shadows);
		if (wheels[m].on) make_batch(wheel_b[m], mesh_wheel[m], mat_near_m[m], 32, false);
	}
	for (int m = 0; m < cm::N_MODELS; m++) make_batch(mid_b[m], mesh_mid[m], mat_mid_m[m], 64, shadows);
	make_batch(box_moving, mesh_box, mat_box, 256, false);
	{   // the bicycles: a mesh and a small material of their own
		if (bike_look::available()) {   // the beach cruiser's mid tier (1,460 triangles), no normal map at this size
			mesh_bike = bike_look::tier("mid");
			mat_bike = bike_look::material(false);
		}
		if (mesh_bike.is_null()) {
			mesh_bike = make_bike_mesh();
			Ref<Shader> sh; sh.instantiate();
			sh->set_code(bike_shader_code());
			mat_bike.instantiate(); mat_bike->set_shader(sh);
		}
		make_batch(bike_b, mesh_bike, mat_bike, 32, shadows);
		// the bicycles of cyclists who come off: four physical ones, made now and put away
		if (bodies_on) {
			for (int k = 0; k < FALLEN; k++) {
				RigidBody3D *rb = memnew(RigidBody3D);
				rb->set_mass(14.0);
				rb->set_linear_damp(0.8f); rb->set_angular_damp(2.0f);   // (on its side it scrapes along the road and stops)
				{ Ref<PhysicsMaterial> pm; pm.instantiate(); pm->set_friction(0.9f); pm->set_bounce(0.05f); rb->set_physics_material_override(pm); }
				rb->set_collision_layer(16); rb->set_collision_mask(1);   // (the world only: the traffic's boxes are moved onto cars every frame and shoved it along)
				CollisionShape3D *cs = memnew(CollisionShape3D);
				Ref<BoxShape3D> bx; bx.instantiate(); bx->set_size(Vector3(0.14f, 0.95f, 1.70f));
				cs->set_shape(bx); cs->set_position(Vector3(0, 0.55f, 0.09f));
				rb->add_child(cs);
				MeshInstance3D *mi = memnew(MeshInstance3D);
				mi->set_mesh(mesh_bike);
				fallen[k].mat = mat_bike->duplicate();
				mi->set_material_override(fallen[k].mat);
				rb->add_child(mi);
				add_child(rb);
				rb->set_visible(false); rb->set_freeze_enabled(true); rb->set_global_position(Vector3(0, -600.0f - (float)k * 3.0f, 0));
				fallen[k].body = rb;
			}
		}
	}
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
			// (static, not kinematic: a kinematic body that is moved from one car to another, or put away, counts that jump
			// as its speed for a step and hands it to whatever it touches: a knocked car left at 28,000 m/s. A real
			// hit is always a physical car's by then: see knock().)
			ps->body_set_mode(pool_body[k], PhysicsServer3D::BODY_MODE_STATIC);
			ps->body_add_shape(pool_body[k], pool_shape[k]);
			ps->body_set_collision_layer(pool_body[k], 16);   // layer 5: traffic (the rig's ground ray does not look at it)
			ps->body_set_collision_mask(pool_body[k], 0);
			ps->body_set_state(pool_body[k], PhysicsServer3D::BODY_STATE_TRANSFORM, Transform3D(Basis(), Vector3(0, -500.0f - k * 4.0f, 0)));
			ps->body_set_space(pool_body[k], space);
			pool_model[k] = -1;
		}
		pool_made = true;
	}
	// the six physical cars a hit car becomes: made now, put away, and every model's meshes held, so a knock makes and
	// loads nothing
	if (bodies_on && knock_on) {
		for (int m = 0; m < cm::N_MODELS; m++) {
			const String base = String("res://vehicles/models/lod/") + cm::MODELS[m].id;
			if (!rl->exists(base + String("_q_body.res"))) continue;
			keep_models.push_back(rl->load(base + String("_q_body.res")));
			for (int k = 0; k < 4; k++) if (rl->exists(base + String("_q_w") + String::num_int64(k) + String(".res"))) keep_models.push_back(rl->load(base + String("_q_w") + String::num_int64(k) + String(".res")));
		}
		for (int k = 0; k < LOOSE; k++) {
			CityCar *c = memnew(CityCar);
			c->set_wheel_mask((int)0xFFFFFFEF);   // its wheels stand on the world, not on the traffic's boxes
			c->set_collision_layer(0); c->set_collision_mask(0);
			add_child(c);
			loose[k] = LooseCar();
			loose[k].car = c;
			loose_put_away(k);
		}
	}
	{
		std::lock_guard<std::mutex> lock(mx);
		input.max_cars = max_cars; input.density = (float)density;
		input.cells = cells; input.cells_all = cells_all; input.cells_dirty = true;
	}
	if (streets.sig_grid.size() == 3) RenderingServer::get_singleton()->global_shader_parameter_set(StringName("ck_signal_grid"), Vector3(streets.sig_grid[0], streets.sig_grid[1], streets.sig_grid[2]));
	for (int pc = 0; pc < sim->n_pieces; pc++) {   // the floor under the lanes and junction paths
		if (pc < sim->n_lanes && !(sim->l_flags[pc] & tc::LF_DRIVE)) continue;
		const int o = sim->p_off[pc], n = sim->p_n[pc];
		for (int k = 0; k + 1 < n; k++) way_floor.add(Vector3(sim->ptx[o + k], sim->pty[o + k], sim->ptz[o + k]), Vector3(sim->ptx[o + k + 1], sim->pty[o + k + 1], sim->ptz[o + k + 1]), sim->p_hw[pc] + 0.2f);
	}
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
	for (int k = 0; k < LOOSE; k++) loose[k] = LooseCar();   // (the cars themselves are this node's children: they go with it)
	keep_models.clear(); hidden.clear();
	RenderingServer *rs = RenderingServer::get_singleton();
	if (gfx) rs->global_shader_parameter_set(StringName("ck_signal_time"), -1.0f);   // the lamps go back to their own clock
	way_floor.clear();
	auto drop = [&](Batch &b) {
		if (b.inst.is_valid()) rs->free_rid(b.inst);
		if (b.mm.is_valid()) rs->free_rid(b.mm);
		b.inst = RID(); b.mm = RID();
	};
	if (gfx) {
		for (Batch &b : near_b) drop(b);
		for (Batch &b : mid_b) drop(b);
		for (Batch &b : wheel_b) drop(b);
		drop(box_moving); drop(box_parked); drop(lamps_b); drop(bike_b);
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
	pm::Scope _pm(pm::TRAFFIC);   // (the slow-frame marks, perf_marks.h)
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
	if (get_world_3d().is_valid()) way_floor.update(cp, get_world_3d()->get_space());
	bool pc = false;
	Vector3 pcp, pcv; float pcyaw = 0.0f;
	if (player_id != 0) {
		Node3D *pn = Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(player_id)));
		if (pn && pn->is_inside_tree()) {
			const Transform3D pt = pn->get_global_transform();
			const Vector3 pf = pt.basis.get_column(2);
			pcp = pt.origin; pcyaw = std::atan2(pf.x, pf.z); pc = true;
			RigidBody3D *rb = Object::cast_to<RigidBody3D>(pn);
			if (rb) pcv = rb->get_linear_velocity();
			else if (pc_has_last && p_delta > 1.0e-4) { pcv = (pcp - pc_last) / (float)p_delta; if (pcv.length_squared() > 90.0f * 90.0f) pcv = Vector3(); }   // (moved by a scene or a test: its speed from where it was)
			pc_last = pcp; pc_has_last = true;
		} else player_id = 0;
	}
	{
		std::lock_guard<std::mutex> lock(mx);
		input.pc = pc; input.pcx = pcp.x; input.pcy = pcp.y; input.pcz = pcp.z; input.pcyaw = pcyaw; input.pcvx = pcv.x; input.pcvz = pcv.z; input.pchl = player_hl; input.pchw = player_hw;
		input.cx = cp.x; input.cy = cp.y; input.cz = cp.z; input.fx = cf.x; input.fz = cf.z; input.fov = (float)cam->get_fov() * 1.6f;   // (the screen is wide: the cone is the horizontal view)
		input.vx = vel_x; input.vz = vel_z;
		input.max_cars = max_cars; input.density = (float)density; input.parked = parked_on; input.bikes = cyclists;
		for (int k = 0; k < LOOSE; k++) {
			Input::LooseBox &q = input.lb[k];
			q.on = loose[k].on ? 1 : 0; q.serial = loose[k].serial;
			if (!loose[k].on || !loose[k].car) continue;
			const Transform3D lt = loose[k].car->get_global_transform();
			const Vector3 lf = lt.basis.get_column(2), lv = loose[k].car->get_linear_velocity();
			const cm::CarModel &lm = cm::MODELS[loose[k].model];
			q.x = lt.origin.x; q.y = lt.origin.y; q.z = lt.origin.z; q.yaw = std::atan2(lf.x, lf.z); q.hl = lm.half_len; q.hw = lm.half_w; q.vx = lv.x; q.vz = lv.z;
		}
		for (const AdoptDone &a : adopt_done) {   // a knocked car is a row again from this very state on: the physical one goes
			if (a.slot < 0 || a.slot >= LOOSE || !loose[a.slot].on || loose[a.slot].serial != a.serial) continue;
			if (a.id >= 0) { loose_put_away(a.slot); kc.rejoined++; }
			else kc.refused = a.id;
		}
		adopt_done.clear();
		now = shared;
		park_now.swap(park_events); park_events.clear();
		downs_now.swap(downs_shared); downs_shared.clear();
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
	for (Batch &b : wheel_b) b.n = 0;
	box_moving.n = 0; lamps_b.n = 0; bike_b.n = 0;
	bike_draw.clear();
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
			if (bodies_on && dx * dx + dz * dz < 30.0f * 30.0f) body_want.push_back(BodyWant{ dx * dx + dz * dz, f[0], f[1], f[2], f[3], f[4], m, -1, k, 0.0f, 0.0f, stall_car[k].colour });
		}
	}

	// ---- moving cars: each between its last two poses, by its own step length
	struct Near { float d2; int i; };
	Near nearest[16];
	int n_near = 0;
	static thread_local float pose[MAX_ROWS][8];   // x, y, z, yaw, pitch, d2, roll, how far between its last two poses
	for (int i = 0; i < now.n; i++) {
		const Row &r = now.rows[i];
		const float a = std::min(std::max(((float)(now.tick - r.tu) + alpha) / (float)r.span, 0.0f), 1.0f);
		float *p = pose[i];
		p[0] = r.px + (r.x - r.px) * a; p[1] = r.py + (r.y - r.py) * a; p[2] = r.pz + (r.z - r.pz) * a;
		p[3] = lerp_angle(r.pyaw, r.yaw, a); p[4] = r.ppitch + (r.pitch - r.ppitch) * a;
		const float dx = p[0] - cp.x, dy = p[1] - cp.y, dz = p[2] - cp.z;
		p[5] = dx * dx + dy * dy + dz * dz;
		p[6] = r.proll + (r.roll - r.proll) * a; p[7] = a;
		bool hide = false;
		for (Hidden &h : hidden) if (h.id == r.id) { h.seen = true; hide = true; }
		if (hide) { p[5] = 1.0e12f; continue; }   // it is a physical car now: no row, no lamps, no box
		if (p[5] < (float)(near_r * near_r) && near_max > 0) {   // the few nearest get the near model
			int at = n_near < near_max ? n_near++ : -1;
			if (at < 0) { int worst = 0; for (int q = 1; q < n_near; q++) if (nearest[q].d2 > nearest[worst].d2) worst = q; if (nearest[worst].d2 > p[5]) at = worst; }
			if (at >= 0) nearest[at] = Near{ p[5], i };
		}
	}
	if ((++bus_frame & 3) == 0) bus_stop_sounds(cp);
	for (size_t h = 0; h < hidden.size();) {   // the step has dropped it: forget it
		hidden[h].frames++;
		if (!hidden[h].seen && hidden[h].frames > 30) { hidden[h] = hidden.back(); hidden.pop_back(); continue; }
		hidden[h].seen = false; h++;
	}
	int c_near = 0, c_mid = 0, c_box = 0;
	for (int i = 0; i < now.n; i++) {
		const Row &r = now.rows[i];
		const float *p = pose[i];
		if (r.kind == tc::K_BIKE) {   // a cyclist: the bicycle here, its rider in the crowd's far batch (bike_draw)
			if (p[5] > (float)(mid_r * mid_r) * 2.0f) continue;
			const float lean = std::min(std::max(-6.0f * p[6], -0.35f), 0.35f);   // (into the turn, as a bicycle leans)
			if (std::find(bike_hide.begin(), bike_hide.end(), (int)r.id) == bike_hide.end()) {   // (a near rider's has its own rig)
				grow(bike_b, bike_b.n + 1);
				float *row = bike_b.buf.ptrw() + (size_t)bike_b.n * ROW;
				const float *col = BIKE_PAINT[r.colour % 8];
				put_row(row, p[0], p[1], p[2], p[3], p[4], 1.0f, 1.0f, 1.0f, PAINT[0], col[0], col[1], col[2], 0.0f);
				lean_row(row, lean); bike_b.n++;
			}
			const float odo = r.podo + (r.odo - r.podo) * p[7];
			bike_draw.push_back(p[0]); bike_draw.push_back(p[1]); bike_draw.push_back(p[2]); bike_draw.push_back(p[3]);
			bike_draw.push_back(lean); bike_draw.push_back(odo / 5.2f); bike_draw.push_back((float)r.id); bike_draw.push_back((float)(r.colour % 8));
			continue;
		}
		if (r.model >= cm::N_MODELS) continue;
		const float *col = PAINT[r.colour % N_COLOURS];
		const float brake = (r.flags & 1) ? 1.0f : 0.0f, ind = (float)((r.flags >> 1) & 3);
		bool is_near = false;
		for (int q = 0; q < n_near; q++) if (nearest[q].i == i) is_near = true;
		if (is_near) {
			Batch &b = near_b[r.model];
			if (b.n < b.cap) {
				float *row = b.buf.ptrw() + (size_t)b.n * ROW;
				put_row(row, p[0], p[1], p[2], p[3], p[4], 1.0f, 1.0f, 1.0f, col, brake, ind, lamps, 0.0f);
				Batch &wb = wheel_b[r.model];
				bool wheels_put = false;
				if (wheels[r.model].on && wb.n + 4 <= wb.cap) {   // its wheels stay on the road while the body leans over them
					wheels_put = true;
					put_wheels(wb.buf.ptrw() + (size_t)wb.n * ROW, row, wheels[r.model], r.psteer + (r.steer - r.psteer) * p[7], r.podo + (r.odo - r.podo) * p[7]);
					wb.n += 4;
				}
				lean_row(row, p[6]); b.n++; c_near++;
				// B6: over its last NEAR_BAND metres the near model fades out into the light model (complementary dither)
				const float dn = std::sqrt(p[5]);
				if (dn > (float)near_r - NEAR_BAND) {
					const float f = std::min(std::max(((float)near_r - dn) / NEAR_BAND, 0.0f), 1.0f);
					row[15] = std::max(f, 0.001f);
					if (wheels_put) for (int w = 1; w <= 4; w++) wb.buf.ptrw()[(size_t)(wb.n - w) * ROW + 15] = std::max(f, 0.001f);
					Batch &mb = mid_b[r.model];
					grow(mb, mb.n + 1);
					float *mrow = mb.buf.ptrw() + (size_t)mb.n * ROW;
					put_row(mrow, p[0], p[1], p[2], p[3], p[4], 1.0f, 1.0f, 1.0f, col, brake, ind, lamps, 0.0f); lean_row(mrow, p[6]);
					mrow[15] = 1.0f + f; mb.n++; c_mid++;
				}
			}
		} else if (p[5] < (float)(mid_r * mid_r)) {
			Batch &b = mid_b[r.model];
			grow(b, b.n + 1);
			float *mrow = b.buf.ptrw() + (size_t)b.n * ROW;
			put_row(mrow, p[0], p[1], p[2], p[3], p[4], 1.0f, 1.0f, 1.0f, col, brake, ind, lamps, 0.0f); lean_row(mrow, p[6]); b.n++; c_mid++;
			// B6: over its last MID_BAND metres the light model fades out into the far shape
			const float dm = std::sqrt(p[5]);
			if (dm > (float)mid_r - MID_BAND) {
				const float f = std::min(std::max(((float)mid_r - dm) / MID_BAND, 0.0f), 1.0f);
				mrow[15] = std::max(f, 0.001f);
				const cm::CarModel &m = cm::MODELS[r.model];
				grow(box_moving, box_moving.n + 1);
				float *brow = box_moving.buf.ptrw() + (size_t)box_moving.n * ROW;
				put_row(brow, p[0], p[1], p[2], p[3], p[4], m.half_w * 2.0f / box_size[0], m.height / (box_size[1] + box_y0), m.half_len * 2.0f / box_size[2], col, brake, 0.0f, lamps, 0.0f);
				brow[15] = 1.0f + f; box_moving.n++; c_box++;
			}
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
		if (bodies_on && p[5] < 70.0f * 70.0f) body_want.push_back(BodyWant{ p[5], p[0], p[1], p[2], p[3], p[4], (int)r.model, r.id, -1, r.v, r.steer, r.colour });
	}
	// ---- cyclists who came off: their bicycles fall (the riders are the crowd's); the fallen ones lie a while
	for (size_t k = 0; k + 8 < downs_now.size(); k += 9) bike_fall(&downs_now[k]);
	for (Fallen &fb : fallen) {
		if (!fb.on || !fb.body) continue;
		fb.t += (float)p_delta;
		const Vector3 bp = fb.body->get_global_position();
		if (!fb.body->is_freeze_enabled()) {   // at rest on its side it is put down for good (a thin body on the road rocks for ever)
			// (by how far it goes, not its speed: a thin body rocking in place reads 0.4 m/s and several rad/s for ever)
			if ((bp.x - fb.rest_at.x) * (bp.x - fb.rest_at.x) + (bp.z - fb.rest_at.z) * (bp.z - fb.rest_at.z) > 0.08f * 0.08f) { fb.rest_at = bp; fb.slow = 0.0f; } else fb.slow += (float)p_delta;   // (along the ground: it rocks up and down by 5 cm)
			if (fb.slow > 1.0f && fb.t > 1.5f) { fb.body->set_linear_velocity(Vector3()); fb.body->set_angular_velocity(Vector3()); fb.body->set_freeze_enabled(true); }
		}
		const float d2 = (bp.x - cp.x) * (bp.x - cp.x) + (bp.z - cp.z) * (bp.z - cp.z);
		if ((fb.t > 40.0f && d2 > 60.0f * 60.0f) || fb.t > 150.0f || bp.y < cp.y - 150.0f) {
			fb.on = false; fb.body->set_visible(false); fb.body->set_freeze_enabled(true); fb.body->set_global_position(Vector3(0, -600.0f, 0));
		}
	}
	// ---- the first frames: one small row of everything in front of the camera, so every shader is built at the start
	if (warm_frames > 0) {
		warm_frames--;
		const Vector3 wp = cp + cf * 8.0f;
		for (int m = 0; m < cm::N_MODELS; m++) {
			if (near_b[m].n == 0) { put_row(near_b[m].buf.ptrw(), wp.x, wp.y - 1.0f, wp.z, 0, 0, 0.02f, 0.02f, 0.02f, PAINT[0], 0, 0, 1, 0); near_b[m].n = 1; }
			if (wheels[m].on && wheel_b[m].n == 0) { put_row(wheel_b[m].buf.ptrw(), wp.x, wp.y - 1.0f, wp.z, 0, 0, 0.02f, 0.02f, 0.02f, PAINT[0], 0, 0, 1, 0); wheel_b[m].n = 1; }
			if (mid_b[m].n == 0) { put_row(mid_b[m].buf.ptrw(), wp.x, wp.y - 1.0f, wp.z, 0, 0, 0.02f, 0.02f, 0.02f, PAINT[0], 0, 0, 1, 0); mid_b[m].n = 1; }
		}
		if (box_moving.n == 0) { put_row(box_moving.buf.ptrw(), wp.x, wp.y - 1.0f, wp.z, 0, 0, 0.02f, 0.02f, 0.02f, PAINT[0], 0, 0, 1, 0); box_moving.n = 1; }
		if (bike_b.n == 0) { put_row(bike_b.buf.ptrw(), wp.x, wp.y - 1.0f, wp.z, 0, 0, 0.02f, 0.02f, 0.02f, PAINT[0], 0, 0, 1, 0); bike_b.n = 1; }
		if (lamps_b.n == 0) { put_row(lamps_b.buf.ptrw(), wp.x, wp.y - 1.0f, wp.z, 0, 0, 0.02f, 0.02f, 0.02f, PAINT[0], 1, 0, 1, 0); lamps_b.n = 1; }
	}
	// ---- to the graphics card: a batch with rows this frame, or that had rows last frame; the parked far batch only when it changed
	int batches = 0;
	for (int m = 0; m < cm::N_MODELS; m++) {
		if (near_b[m].n > 0) { near_b[m].dirty = true; batches++; }
		if (mid_b[m].n > 0) { mid_b[m].dirty = true; batches++; }
		if (wheels[m].on) { if (wheel_b[m].n > 0) { wheel_b[m].dirty = true; batches++; } send(wheel_b[m]); }
		send(near_b[m]); send(mid_b[m]);
	}
	if (box_moving.n > 0) { box_moving.dirty = true; batches++; }
	send(box_moving);
	if (bike_b.n > 0) { bike_b.dirty = true; batches++; }
	send(bike_b);
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

// Two cars' boxes seen from above: do they overlap? (a = one car, b = the other; yaw, half length, half width)
static bool boxes_touch(float ax, float az, float ayaw, float ahl, float ahw, float bx, float bz, float byaw, float bhl, float bhw) {
	const float afx = std::sin(ayaw), afz = std::cos(ayaw), bfx = std::sin(byaw), bfz = std::cos(byaw);
	const float dx = bx - ax, dz = bz - az;
	const float ax4[4][2] = { { afx, afz }, { afz, -afx }, { bfx, bfz }, { bfz, -bfx } };
	for (int k = 0; k < 4; k++) {
		const float ux = ax4[k][0], uz = ax4[k][1];
		const float d = std::fabs(dx * ux + dz * uz);
		const float ra = ahl * std::fabs(afx * ux + afz * uz) + ahw * std::fabs(afz * ux - afx * uz);
		const float rb = bhl * std::fabs(bfx * ux + bfz * uz) + bhw * std::fabs(bfz * ux - bfx * uz);
		if (d > ra + rb) return false;
	}
	return true;
}

// A knocked car's driver gets out: a person at the driver's door (the car's left, +x), facing out; the crowd takes him
void CityTraffic::driver_out(int k, int p_foe, uint32_t p_foe_serial) {
	LooseCar &L = loose[k];
	L.driver_out = true;
	const Transform3D t = L.car->get_global_transform();
	const cm::CarModel &lm = cm::MODELS[L.model];
	const Vector3 side = t.basis.get_column(0).normalized(), fwd = t.basis.get_column(2).normalized();
	const Vector3 door = t.origin + side * (lm.half_w + 0.45f) + fwd * (lm.half_len * 0.1f);
	rage_out.push_back(RageOut{ door.x, door.y, door.z, std::atan2(side.x, side.z), L.serial, p_foe, p_foe_serial });
	kc.drivers_out++;
}

void CityTraffic::loose_put_away(int k) {
	LooseCar &L = loose[k];
	if (!L.car) return;
	L.car->set_collision_layer(0); L.car->set_collision_mask(0);
	L.car->put_away(Vector3(0.0f, -700.0f - 8.0f * (float)k, 0.0f));
	L.on = false; L.rest_t = 0.0f;
	if (L.alarm) L.alarm->stop();
	L.alarm_rang = false; L.alarm_t = 0.0f;
	if (L.taken) { L.taken = false; if (L.car->is_in_group("vehicles")) L.car->remove_from_group("vehicles"); L.car->remove_meta("takeable"); }
}

// A car of the traffic (a row, or a parked one) becomes a physical car where it is, with the speed it has.
bool CityTraffic::knock(BodyWant &w) {
	int slot = -1;
	for (int k = 0; k < LOOSE; k++) if (loose[k].car && !loose[k].on) { slot = k; break; }
	if (slot < 0) {   // all six are out: the one that lies still farthest from the camera gives its place
		float far2 = 40.0f * 40.0f;
		for (int k = 0; k < LOOSE; k++) {
			if (!loose[k].car || loose[k].rest_t < 2.0f) continue;
			const Vector3 o = loose[k].car->get_global_transform().origin;
			const float d2 = (o.x - last_cam.x) * (o.x - last_cam.x) + (o.z - last_cam.z) * (o.z - last_cam.z);
			if (d2 > far2) { far2 = d2; slot = k; }
		}
		if (slot < 0) { kc.no_slot++; return false; }
		loose_put_away(slot); kc.taken_away++;
	}
	LooseCar &L = loose[slot];
	const float *c = PAINT[w.colour % N_COLOURS];
	L.car->become(w.model, knock_feel, Color(c[0], c[1], c[2]));
	const Basis bs = Basis(Vector3(0, 1, 0), w.yaw) * Basis(Vector3(1, 0, 0), -w.pitch);
	L.car->set_collision_layer(16); L.car->set_collision_mask(1 | 16);
	L.car->launch(Transform3D(bs, Vector3(w.x, w.y + 0.03f, w.z)), bs.get_column(2) * w.v);
	L.parked = w.stall >= 0;
	L.alarm_rang = false; L.alarm_t = 0.0f;
	if (L.alarm) L.alarm->stop();
	// a parked car stands with its handbrake on; a driver who is hit holds his wheel for a moment, then brakes
	L.car->set_controls(0.0, 0.0, L.parked ? 0.0 : std::min(std::max(w.steer / 0.61f, -1.0f), 1.0f), L.parked ? 1.0 : 0.0, false);
	L.on = true; L.model = w.model; L.colour = w.colour; L.serial = ++loose_serial; L.rest_t = 0.0f; L.age = 0.0f; L.ask_cd = 0.0f;
	// who hit it: the player's car (near it now), or another knocked car (the nearest within reach); a parked car has
	// nobody in it
	L.by_player = false; L.driver_out = false; L.hit_by = -1; L.hit_by_serial = 0;
	if (!L.parked) {
		const float reach = cm::MODELS[w.model].half_len + 3.0f;
		Node3D *pc = player_id ? Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
		if (pc && pc->is_inside_tree()) {
			const Vector3 o = pc->get_global_position();
			if (Vector2(o.x - w.x, o.z - w.z).length() < reach + player_hl) L.by_player = true;
		}
		if (!L.by_player) {
			float best = 1e9f;
			for (int k = 0; k < LOOSE; k++) {
				if (k == slot || !loose[k].on || !loose[k].car) continue;
				const Vector3 o = loose[k].car->get_global_transform().origin;
				const float d = Vector2(o.x - w.x, o.z - w.z).length();
				if (d < reach + cm::MODELS[loose[k].model].half_len && d < best) { best = d; L.hit_by = k; L.hit_by_serial = loose[k].serial; }
			}
		}
	}
	{
		std::lock_guard<std::mutex> lock(mx);
		if (w.id >= 0) input.kill_ids.push_back(w.id); else input.kill_stalls.push_back(w.stall);
	}
	if (w.id >= 0) { hidden.push_back(Hidden{ w.id, 0, true }); kc.moving++; }
	else { stall_car[w.stall].model = 255; active_dirty = true; kc.parked++; }
	return true;
}

int32_t CityTraffic::car_to_take(const Vector3 &p_at, double p_r, double p_max_v) const {
	int32_t best = -1; float bd = (float)(p_r * p_r);
	for (int k = 0; k < now.n; k++) {
		const Row &r = now.rows[k];
		if (r.kind != tc::K_AMBIENT || std::fabs(r.v) > (float)p_max_v || std::fabs(r.y - (float)p_at.y) > 2.5f) continue;
		bool hid = false;
		for (const Hidden &h : hidden) if (h.id == r.id) hid = true;
		if (hid) continue;
		// (the distance to its box, not its centre: the player stands by a door)
		const float sx = std::sin(r.yaw), cz = std::cos(r.yaw);
		const float dx = (float)p_at.x - r.x, dz = (float)p_at.z - r.z;
		const float along = dx * sx + dz * cz, side = dx * cz - dz * sx;
		const float ox = std::max(std::fabs(side) - r.hw, 0.0f), oz = std::max(std::fabs(along) - r.hl, 0.0f);
		const float d2 = ox * ox + oz * oz;
		if (d2 < bd) { bd = d2; best = r.id; }
	}
	return best;
}

Object *CityTraffic::take_car(int32_t p_id, bool p_fight) {
	if (!loose[0].car) return nullptr;
	const Row *row = nullptr;
	for (int k = 0; k < now.n; k++) if (now.rows[k].id == p_id) row = &now.rows[k];
	if (!row || row->kind != tc::K_AMBIENT) return nullptr;
	BodyWant w{ 0.0f, row->x, row->y, row->z, row->yaw, row->pitch, (int)row->model, row->id, -1, 0.0f, 0.0f, row->colour };
	if (!knock(w)) return nullptr;
	int slot = -1;
	for (int k = 0; k < LOOSE; k++) if (loose[k].on && loose[k].serial == loose_serial) slot = k;
	if (slot < 0) return nullptr;
	LooseCar &L = loose[slot];
	L.taken = true; L.by_player = false; L.hit_by = -1;
	L.car->set_controls(0.0, 1.0, 0.0, 1.0, false);   // (it stands: the driver has his foot down as he is pulled out)
	L.car->set_meta("takeable", true);
	if (!L.car->is_in_group("vehicles")) L.car->add_to_group("vehicles");
	driver_out(slot, p_fight ? -1 : -5, 0);
	L.driver_out = true;
	cars_taken++;
	return L.car;
}

// The knocked cars, every physics step: the driver's foot, who may drive on, who is taken away.
void CityTraffic::loose_update(double p_delta) {
	const float dt = (float)p_delta;
	for (int k = 0; k < LOOSE; k++) {
		LooseCar &L = loose[k];
		if (!L.on || !L.car) continue;
		const Transform3D t = L.car->get_global_transform();
		const Vector3 v = L.car->get_linear_velocity(), av = L.car->get_angular_velocity();
		L.age += dt; L.ask_cd -= dt;
		L.rest_t = (v.length_squared() < 0.12f && av.length_squared() < 0.09f) ? L.rest_t + dt : 0.0f;
		const float dx = t.origin.x - last_cam.x, dz = t.origin.z - last_cam.z, d2 = dx * dx + dz * dz;
		if (L.taken && (L.car->get_player() || L.car->get_entry_state() != 0)) { L.rest_t = 0.0f; continue; }   // (he drives it, or gets in or out: it goes where he goes)
		if (t.origin.y < last_cam.y - 120.0f || d2 > 180.0f * 180.0f || (d2 > 120.0f * 120.0f && L.rest_t > 1.0f)) { loose_put_away(k); kc.taken_away++; continue; }
		if (L.parked) {   // nobody in it: its alarm rings once it is shoved (20 s)
			if (!L.alarm_rang && L.age > 0.05f && v.length() > 0.4f) {
				L.alarm_rang = true; kc.alarms++;
				if (!L.alarm) {
					L.alarm = memnew(AudioStreamPlayer3D);
					L.alarm->set_stream(city_sfx("car_alarm.wav", true));
					L.alarm->set_unit_size(7.0); L.alarm->set_max_distance(90.0); L.alarm->set_volume_db(-3.0);
					L.car->add_child(L.alarm);
				}
				if (L.alarm->get_stream().is_valid()) L.alarm->play();
				L.alarm_t = 20.0f;
			}
			if (L.alarm && L.alarm->is_playing()) { L.alarm_t -= dt; if (L.alarm_t <= 0.0f) L.alarm->stop(); }
			continue;
		}
		if (L.taken) continue;   // (the player's now)
		if (L.age > 0.35f) L.car->set_controls(0.0, 0.7, 0.0, 0.0, false);
		// ROAD RAGE (Yasin: "once collided, the driver should get out and attack us, unless its a parked car"; "if other cars
		// hit each other, they should try to attack the aggressor car instead"): once it stands, its driver gets out
		if (!L.driver_out && L.rest_t > 1.0f && t.basis.get_column(1).y > 0.8f && (L.by_player || L.hit_by >= 0)) {
			if (!L.by_player) {   // the one who hit it gets out too (to be gone for), if his car stands and he is in it
				LooseCar &A = loose[L.hit_by];
				if (A.on && A.car && A.serial == L.hit_by_serial && !A.parked && !A.driver_out && A.rest_t > 0.5f) driver_out(L.hit_by, -2, 0);
			}
			driver_out(k, L.by_player ? -1 : L.hit_by, L.hit_by_serial);
		}
		// (a dented car does not drive on as a row of the traffic, which has no dents: it stays a wreck where it came to rest,
		// the traffic goes round it, until it is far enough away to be taken; Yasin: "every other car should get damaged too")
		if (L.rest_t > 3.5f && L.ask_cd <= 0.0f && t.basis.get_column(1).y > 0.94f && !L.car->is_damaged() && !L.driver_out) {   // it stands on its wheels: may its driver drive on?
			const Vector3 f = t.basis.get_column(2);
			std::lock_guard<std::mutex> lock(mx);
			input.adopt.push_back(Input::Adopt{ k, L.serial, L.model, L.colour, t.origin.x, t.origin.z, std::atan2(f.x, f.z) });
			L.ask_cd = 2.5f;
		}
	}
}

// The pool's bodies go onto the cars nearest the camera (moving cars to 70 m, parked ones to 30 m). Only transforms
// are sent; a body changes its box only when it gets a car of another model. A car that the player's car, or a car
// already knocked loose, will touch within a sixth of a second becomes a physical car instead of a box.
void CityTraffic::_physics_process(double p_delta) {
	pm::Scope _pm(pm::TRAFFIC_PHYS);   // (the slow-frame marks, perf_marks.h)
	if (!pool_made || !bodies_on) return;
	loose_update(p_delta);
	PhysicsServer3D *ps = PhysicsServer3D::get_singleton();
	const int n = (int)body_want.size();
	const int use = std::min(n, (int)POOL);
	if (n > POOL) std::partial_sort(body_want.begin(), body_want.begin() + POOL, body_want.end(), [](const BodyWant &a, const BodyWant &b) { return a.d2 < b.d2; });
	struct Striker { Vector3 p, v; float yaw, hl, hw; };
	Striker hit[LOOSE + 1];
	int nh = 0;
	if (knock_on && loose[0].car) {
		if (player_id != 0) {
			RigidBody3D *rb = Object::cast_to<RigidBody3D>(ObjectDB::get_instance(ObjectID(player_id)));
			if (rb && rb->is_inside_tree()) {
				const Transform3D pt = rb->get_global_transform();
				const Vector3 pf = pt.basis.get_column(2);
				hit[nh++] = Striker{ pt.origin, rb->get_linear_velocity(), std::atan2(pf.x, pf.z), player_hl, player_hw };
			}
		}
		for (int k = 0; k < LOOSE; k++) {
			if (!loose[k].on) continue;
			const Transform3D pt = loose[k].car->get_global_transform();
			const Vector3 pf = pt.basis.get_column(2);
			hit[nh++] = Striker{ pt.origin, loose[k].car->get_linear_velocity(), std::atan2(pf.x, pf.z), cm::MODELS[loose[k].model].half_len, cm::MODELS[loose[k].model].half_w };
		}
	}
	for (int k = 0; k < POOL; k++) {
		bool put = false;
		if (k < use && body_want[k].model >= 0) {
			BodyWant &w = body_want[k];
			const cm::CarModel &m = cm::MODELS[w.model];
			bool gone = false;
			for (int h = 0; h < nh && !gone; h++) {
				const Striker &q = hit[h];
				if (std::fabs(q.p.y - w.y) > 2.5f) continue;
				const float rvx = q.v.x - std::sin(w.yaw) * w.v, rvz = q.v.z - std::cos(w.yaw) * w.v;   // how the striker comes at it
				const float rv2 = rvx * rvx + rvz * rvz;
				if (rv2 < 1.2f * 1.2f) continue;
				const float dx = w.x - q.p.x, dz = w.z - q.p.z;
				if (dx * rvx + dz * rvz <= 0.0f) continue;   // (going apart)
				const float reach = q.hl + m.half_len + std::sqrt(rv2) * 0.17f + 0.6f;
				if (dx * dx + dz * dz > reach * reach) continue;
				for (int e = 1; e <= 3 && !gone; e++) {
					const float te = 0.055f * (float)e;
					if (boxes_touch(q.p.x + rvx * te, q.p.z + rvz * te, q.yaw, q.hl + 0.08f, q.hw + 0.08f, w.x, w.z, w.yaw, m.half_len, m.half_w)) gone = knock(w);
				}
			}
			if (gone) w.model = -1;   // (this list lives until the next frame: not twice)
			else {
				if (pool_model[k] != w.model) { ps->shape_set_data(pool_shape[k], Vector3(m.half_w, m.height * 0.5f, m.half_len)); pool_model[k] = w.model; }
				Basis bs = Basis(Vector3(0, 1, 0), w.yaw) * Basis(Vector3(1, 0, 0), -w.pitch);
				ps->body_set_state(pool_body[k], PhysicsServer3D::BODY_STATE_TRANSFORM, Transform3D(bs, Vector3(w.x, w.y + m.height * 0.5f, w.z)));
				put = true;
			}
		}
		if (!put && pool_model[k] != -2) {
			ps->body_set_state(pool_body[k], PhysicsServer3D::BODY_STATE_TRANSFORM, Transform3D(Basis(), Vector3(0, -500.0f - k * 4.0f, 0)));
			pool_model[k] = -2;   // put away
		}
	}
}

Array CityTraffic::cars_near(const Vector3 &p_at, double p_r) const {
	Array out;
	for (int i = 0; i < now.n; i++) {
		const Row &r = now.rows[i];
		const float dx = r.x - p_at.x, dz = r.z - p_at.z;
		if (dx * dx + dz * dz > (float)(p_r * p_r)) continue;
		Dictionary d;
		d["id"] = r.id; d["at"] = Vector3(r.x, r.y, r.z); d["yaw"] = r.yaw; d["speed"] = r.v; d["model"] = (int)r.model; d["steer"] = r.steer;
		d["kind"] = (int)r.kind; d["bike"] = r.kind == tc::K_BIKE;
		out.push_back(d);
	}
	return out;
}

Array CityTraffic::stalls_near(const Vector3 &p_at, double p_r) const {
	Array out;
	for (int32_t k : active) {
		const float *f = &streets.stall_f[(size_t)k * 8];
		const float dx = f[0] - p_at.x, dz = f[2] - p_at.z;
		if (dx * dx + dz * dz > (float)(p_r * p_r) || stall_car[k].model == 255) continue;
		Dictionary d;
		d["stall"] = k; d["at"] = Vector3(f[0], f[1], f[2]); d["yaw"] = f[3]; d["model"] = (int)stall_car[k].model; d["kerb"] = streets.stall_i[(size_t)k * 4] == 0;
		out.push_back(d);
	}
	return out;
}

Dictionary CityTraffic::knock_stats() const {
	Dictionary d;
	d["moving"] = kc.moving; d["parked"] = kc.parked; d["rejoined"] = kc.rejoined; d["drivers_out"] = kc.drivers_out; d["alarms"] = kc.alarms; d["yields"] = sim ? sim->yields : 0; d["cars_taken"] = cars_taken; d["panicked"] = panicked; d["taken_away"] = kc.taken_away; d["no_slot"] = kc.no_slot; d["last_refusal"] = kc.refused;
	Array a;
	for (int k = 0; k < LOOSE; k++) {
		if (!loose[k].on || !loose[k].car) continue;
		const Transform3D t = loose[k].car->get_global_transform();
		Dictionary c;
		c["at"] = t.origin; c["speed"] = loose[k].car->get_linear_velocity().length(); c["spin"] = loose[k].car->get_angular_velocity().length();
		c["up"] = t.basis.get_column(1).y; c["parked"] = loose[k].parked; c["model"] = loose[k].model; c["still_s"] = loose[k].rest_t; c["damage"] = loose[k].car->get_damage();
		a.push_back(c);
	}
	d["out"] = a;
	return d;
}

void CityTraffic::bus_stop_sounds(const Vector3 &p_l) {
	std::vector<std::pair<int, int>> keep;
	for (int i = 0; i < now.n; i++) {
		const Row &r = now.rows[i];
		if (r.kind != tc::K_BUS) continue;
		const Vector3 at(r.x, r.y + 1.5f, r.z);
		const bool near = at.distance_squared_to(p_l) < 70.0f * 70.0f;
		int was = -1;
		for (const auto &b : bus_stopped) if (b.first == (int)r.id) was = b.second;
		if (r.stop >= 0) keep.push_back({ (int)r.id, r.stop });
		if (!near || was == r.stop) continue;
		const Vector3 loc = to_local(at);
		const Vector3 door = to_local(at + Vector3(std::cos(r.yaw), 0.0f, -std::sin(r.yaw)) * r.hw);   // (the kerb side)
		if (r.stop >= 0 && was < 0) {   // it has stopped
			elsfx::play(this, "res://audio/sfx/bus/bus_air_brake_", -3.0f, 0.04f, loc, 80.0f);
			elsfx::play(this, "res://audio/sfx/bus/bus_kneel_beep_", -8.0f, 0.0f, door, 35.0f);
			elsfx::play(this, "res://audio/sfx/bus/bus_door_open_", -5.0f, 0.03f, door, 40.0f);
			bus_sounds += 3;
		} else if (r.stop < 0 && was >= 0) {   // it leaves
			elsfx::play(this, "res://audio/sfx/bus/bus_door_close_", -5.0f, 0.03f, door, 40.0f);
			bus_sounds++;
		}
	}
	bus_stopped.swap(keep);
}

void CityTraffic::buses_at_stops(std::vector<float> &r_buses) const {
	r_buses.clear();
	for (int i = 0; i < now.n; i++) {
		const Row &r = now.rows[i];
		if (r.stop < 0) continue;
		const float q[7] = { (float)r.stop, r.x, r.z, r.yaw, r.hl, r.hw, (float)r.id };
		r_buses.insert(r_buses.end(), q, q + 7);
	}
}

void CityTraffic::cars_for_people(std::vector<float> &r_cars) const {
	r_cars.clear();
	for (int i = 0; i < now.n; i++) {
		const Row &r = now.rows[i];
		bool gone = false;
		for (const Hidden &h : hidden) if (h.id == r.id) gone = true;
		if (gone) continue;
		const float q[7] = { r.x, r.z, r.yaw, r.hl, r.hw, std::sin(r.yaw) * r.v, std::cos(r.yaw) * r.v };
		r_cars.insert(r_cars.end(), q, q + 7);
	}
	for (int k = 0; k < LOOSE; k++) {
		if (!loose[k].on || !loose[k].car) continue;
		const Transform3D t = loose[k].car->get_global_transform();
		const Vector3 f = t.basis.get_column(2), v = loose[k].car->get_linear_velocity();
		const float q[7] = { (float)t.origin.x, (float)t.origin.z, (float)std::atan2(f.x, f.z), cm::MODELS[loose[k].model].half_len, cm::MODELS[loose[k].model].half_w, (float)v.x, (float)v.z };
		r_cars.insert(r_cars.end(), q, q + 7);
	}
	if (player_id != 0) {
		RigidBody3D *rb = Object::cast_to<RigidBody3D>(ObjectDB::get_instance(ObjectID(player_id)));
		if (rb && rb->is_inside_tree()) {
			const Transform3D t = rb->get_global_transform();
			const Vector3 f = t.basis.get_column(2), v = rb->get_linear_velocity();
			const float q[7] = { (float)t.origin.x, (float)t.origin.z, (float)std::atan2(f.x, f.z), player_hl, player_hw, (float)v.x, (float)v.z };
			r_cars.insert(r_cars.end(), q, q + 7);
		}
	}
}

void CityTraffic::set_walkers(const float *p_dyn, int p_n) {
	std::lock_guard<std::mutex> lock(mx);
	input.walkers.assign(p_dyn, p_dyn + (size_t)std::max(p_n, 0) * tc::DYN_STRIDE);
}

void CityTraffic::set_player_car(Object *p_car, double p_half_len, double p_half_w) {
	player_id = p_car ? (uint64_t)p_car->get_instance_id() : 0;
	player_hl = (float)p_half_len; player_hw = (float)p_half_w;
	// it meets the traffic's cars (their layer is 5), and the cars it knocks loose take its feel
	CollisionObject3D *co = Object::cast_to<CollisionObject3D>(p_car);
	if (co) co->set_collision_mask(co->get_collision_mask() | 16);
	CityCar *cc = Object::cast_to<CityCar>(p_car);
	if (cc) knock_feel = cc->get_feel();
}

String CityTraffic::report() {
	const double f = std::max(cnt.frames, 1);
	String s = vformat("cars moving avg %.1f most %d (the streets there carry %.0f, the cap is %d): near model %.1f, light model %.1f, far shape %.1f | parked: %.0f in the loaded cells, %.1f drawn with the light model | batches drawn avg %.1f, uploads a frame %.1f | main thread a frame: avg %.3f worst %.3f ms | the step (own thread): avg %.3f worst %.3f ms",
			cnt.moving / f, cnt.moving_most, cnt.carry / f, max_cars, cnt.near / f, cnt.mid / f, cnt.box / f, cnt.parked_all / f, cnt.parked_mid / f, cnt.batches / f, (double)cnt.uploads / f,
			cnt.main_us / f / 1000.0, cnt.main_us_worst / 1000.0, cnt.step_us / std::max(cnt.steps, 1) / 1000.0, cnt.step_us_worst / 1000.0);
	s += vformat(" | pulled out of a stall %d, parked %d (since the start)", cnt.park_out, cnt.park_in);
	s += vformat(" | bus lines %d: buses put on the road %d, stops served %d", (int)lines_info.size(), now.buses, now.bus_stops);
	s += vformat(" | knocked loose: %d moving, %d parked; drove on %d, taken away %d, no free physical car %d", kc.moving, kc.parked, kc.rejoined, kc.taken_away, kc.no_slot);
	cnt = Count();
	return s;
}

const float *CityTraffic::bike_paint(int p_colour) { return BIKE_PAINT[((p_colour % 8) + 8) % 8]; }

} // namespace godot
