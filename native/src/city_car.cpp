// CityCar: see city_car.h.
#include "city_car.h"

#include "car_models.h"

#include <godot_cpp/classes/box_shape3d.hpp>
#include <godot_cpp/classes/collision_shape3d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_material.hpp>
#include <godot_cpp/classes/physics_server3d.hpp>
#include <godot_cpp/classes/rendering_server.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/shader.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <cmath>

namespace godot {

// Made once: the nodes, the engine body's settings, the wheel ray, the camera. What depends on the model is in fit().
void CityCar::make() {
	if (made) return;
	made = true;
	set_center_of_mass_mode(CENTER_OF_MASS_MODE_CUSTOM);
	set_use_custom_integrator(true);
	set_can_sleep(false);
	set_use_continuous_collision_detection(true);
	set_linear_damp_mode(DAMP_MODE_REPLACE); set_linear_damp(0.0); set_angular_damp_mode(DAMP_MODE_REPLACE); set_angular_damp(0.0);
	Ref<PhysicsMaterial> pm; pm.instantiate(); pm->set_friction(0.35); pm->set_bounce(0.05);
	set_physics_material_override(pm);
	// two boxes: the body from sill to waist, the cabin above it
	sh_body.instantiate(); sh_top.instantiate();
	cs_body = memnew(CollisionShape3D); cs_body->set_shape(sh_body); add_child(cs_body);
	cs_top = memnew(CollisionShape3D); cs_top->set_shape(sh_top); add_child(cs_top);
	rq.instantiate();
	rq->set_collision_mask(wheel_mask);
	TypedArray<RID> ex; ex.push_back(get_rid());
	rq->set_exclude(ex);
	ResourceLoader *rl = ResourceLoader::get_singleton();
	Ref<Shader> sh = rl->load("res://vehicles/car_paint.gdshader");
	Ref<Texture2D> atlas = rl->load("res://vehicles/models/Textures/car_atlas_1024.png");
	if (sh.is_valid()) {
		// (the paint shader reads the global `refl_env`: whoever makes the car sees to it that it exists, as the rig does)
		mat.instantiate(); mat->set_shader(sh); mat->set_shader_parameter("atlas", atlas);
	}
	mi_body = memnew(MeshInstance3D);
	if (mat.is_valid()) mi_body->set_material_override(mat);
	add_child(mi_body);
	for (int i = 0; i < 4; i++) {
		MeshInstance3D *wi = memnew(MeshInstance3D);
		if (mat.is_valid()) wi->set_material_override(mat);
		add_child(wi);
		wheel_vis[i] = wi;
	}
	if (chase_camera) {
		cam = memnew(Camera3D);
		cam->set_as_top_level(true);
		cam->set_fov(62.0); cam->set_near(0.2); cam->set_far(1500.0);
		add_child(cam);
		cam->make_current();
	}
	fit();
}

// What depends on the model, the feel and the paint: the physical car, the engine body's weight and boxes, the meshes.
// (Called again by become(): a car of the traffic's pool takes the model of the car that was hit.)
void CityCar::fit() {
	const int m = std::min(std::max(model, 0), cm::N_MODELS - 1);
	const cm::CarModel &cmod = cm::MODELS[m];
	vd::Spec sp = vd::make_spec(m, feel);
	ResourceLoader *rl = ResourceLoader::get_singleton();
	const String base = String("res://vehicles/models/lod/") + cmod.id;

	// ---- the model: body and wheels apart when the model has them (the body mesh notes where its wheels are)
	Ref<Mesh> body_mesh;
	Ref<Mesh> wheel_mesh[4];
	Vector3 wc[4];
	float wr[4] = { 0, 0, 0, 0 };
	split = false;
	if (rl->exists(base + String("_q_body.res"))) {
		body_mesh = rl->load(base + String("_q_body.res"));
		if (body_mesh.is_valid() && body_mesh->has_meta("wheels")) {
			const Array wl = body_mesh->get_meta("wheels");
			if (wl.size() == 4) {
				split = true;
				for (int k = 0; k < 4 && split; k++) {
					const Dictionary w = wl[k];
					const Vector3 c = w.get("center", Vector3());
					// which wheel it is, by where it sits: +x = left, +z = front
					const int slot = (c.z > 0.0f ? 0 : 2) + (c.x > 0.0f ? 0 : 1);
					if (wheel_mesh[slot].is_valid()) { split = false; break; }
					wheel_mesh[slot] = rl->load(base + String("_q_w") + String::num_int64(k) + String(".res"));
					wc[slot] = c; wr[slot] = (float)(double)w.get("radius", 0.33);
					if (wheel_mesh[slot].is_null()) split = false;
				}
			}
		}
	}
	if (!split) body_mesh = rl->load(base + String("_q.res"));   // one mesh, wheels and all: it drives the same, its wheels do not turn
	float axle_z = 0.0f;   // the middle between the axles, in the model's frame
	if (split) {   // the physical car takes its wheels from the model
		sp.wheelbase = 0.5f * (wc[vd::FL].z + wc[vd::FR].z) - 0.5f * (wc[vd::RL].z + wc[vd::RR].z);
		sp.track_f = wc[vd::FL].x - wc[vd::FR].x; sp.track_r = wc[vd::RL].x - wc[vd::RR].x;
		sp.wheel_r = 0.25f * (wr[0] + wr[1] + wr[2] + wr[3]);
		axle_z = 0.25f * (wc[0].z + wc[1].z + wc[2].z + wc[3].z);
	}
	car = vd::Car();
	car.init(sp);
	const vd::Spec &s = car.s;
	com = Vector3(0.0f, s.cg_h, axle_z + s.wheelbase * (s.front_share - 0.5f));
	for (int i = 0; i < 4; i++) hub_local[i] = com + Vector3(car.wh[i].hub0.x, car.wh[i].hub0.y, car.wh[i].hub0.z);

	// ---- the engine's body: weight, where it balances, how it resists turning; no forces of the engine's own
	set_mass(s.mass);
	set_center_of_mass(com);
	set_inertia(Vector3(car.inertia[0], car.inertia[1], car.inertia[2]));
	const float clear = std::min(0.24f, s.wheel_r * 0.7f), waist = cmod.height * 0.58f;
	sh_body->set_size(Vector3(cmod.half_w * 2.0f - 0.16f, waist - clear, cmod.half_len * 2.0f - 0.06f));
	cs_body->set_position(Vector3(0.0f, 0.5f * (waist + clear), 0.0f));
	sh_top->set_size(Vector3(cmod.half_w * 2.0f - 0.36f, cmod.height - waist, cmod.half_len * 1.15f));
	cs_top->set_position(Vector3(0.0f, 0.5f * (cmod.height + waist), -0.08f * cmod.half_len));

	// ---- what is drawn
	if (mat.is_valid()) mat->set_shader_parameter("paint", paint);
	mi_body->set_mesh(body_mesh);
	for (int i = 0; i < 4; i++) {
		wheel_vis[i]->set_mesh(split ? wheel_mesh[i] : Ref<Mesh>());
		wheel_vis[i]->set_visible(split);
		wheel_vis[i]->set_position(hub_local[i]);
	}
	dir = 1; odo = 0.0; hardest_hit = 0.0f; last_v = Vector3();
}

void CityCar::become(int p_model, int p_feel, const Color &p_paint) {
	model = p_model; feel = p_feel; paint = p_paint;
	if (made) fit();
}

// Set down at a place with a speed, wheels already rolling at that speed (a traffic car that is hit goes on as it went).
void CityCar::launch(const Transform3D &p_at, const Vector3 &p_velocity) {
	if (!made) return;
	set_freeze_enabled(false);
	set_visible(true);
	set_global_transform(p_at);
	PhysicsServer3D *ps = PhysicsServer3D::get_singleton();
	ps->body_set_state(get_rid(), PhysicsServer3D::BODY_STATE_TRANSFORM, p_at);
	ps->body_set_state(get_rid(), PhysicsServer3D::BODY_STATE_LINEAR_VELOCITY, p_velocity);
	ps->body_set_state(get_rid(), PhysicsServer3D::BODY_STATE_ANGULAR_VELOCITY, Vector3());
	const float along = p_velocity.dot(p_at.basis.get_column(2));
	for (int i = 0; i < 4; i++) car.wh[i].omega = along / std::max(car.s.wheel_r, 0.1f);
	car.speed = along;
	last_v = p_velocity;
}

// Taken out of the world until it is needed again: no collision, not drawn, not stepped.
void CityCar::put_away(const Vector3 &p_where) {
	if (!made) return;
	set_freeze_enabled(true);
	set_visible(false);
	const Transform3D t(Basis(), p_where);
	set_global_transform(t);
	PhysicsServer3D::get_singleton()->body_set_state(get_rid(), PhysicsServer3D::BODY_STATE_TRANSFORM, t);
}

void CityCar::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) return;
	make();
	set_process(true);
}

// The keys and the pad. S (or the left trigger) brakes; once the car stands it becomes the reverse gear's pedal.
void CityCar::read_player() {
	Input *in = Input::get_singleton();
	const float up = std::max(in->is_key_pressed(KEY_W) || in->is_key_pressed(KEY_UP) ? 1.0f : 0.0f, std::max(0.0f, (float)in->get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)));
	const float down = std::max(in->is_key_pressed(KEY_S) || in->is_key_pressed(KEY_DOWN) ? 1.0f : 0.0f, std::max(0.0f, (float)in->get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)));
	float st = (in->is_key_pressed(KEY_A) || in->is_key_pressed(KEY_LEFT) ? 1.0f : 0.0f) - (in->is_key_pressed(KEY_D) || in->is_key_pressed(KEY_RIGHT) ? 1.0f : 0.0f);
	const float jx = (float)in->get_joy_axis(0, JOY_AXIS_LEFT_X);
	if (std::fabs(jx) > 0.12f) st -= jx;
	if (dir == 1 && down > 0.1f && up < 0.1f && car.speed < 0.8f) dir = -1;
	else if (dir == -1 && up > 0.1f && car.speed > -0.8f) dir = 1;
	c_throttle = dir == 1 ? up : down; c_brake = dir == 1 ? down : up;
	c_steer = std::min(std::max(st, -1.0f), 1.0f);
	c_handbrake = (in->is_key_pressed(KEY_SPACE) || in->is_joy_button_pressed(0, JOY_BUTTON_A)) ? 1.0f : 0.0f;
	if (up < 0.05f && down < 0.05f && std::fabs(car.speed) < 0.6f) c_brake = 0.35f;   // left alone at a standstill it holds itself (also on a hill)
}

void CityCar::set_controls(double p_throttle, double p_brake, double p_steer, double p_handbrake, bool p_reverse) {
	c_throttle = (float)p_throttle; c_brake = (float)p_brake; c_steer = (float)p_steer; c_handbrake = (float)p_handbrake;
	dir = p_reverse ? -1 : 1;
}

void CityCar::_integrate_forces(PhysicsDirectBodyState3D *p_state) {
	if (!made) return;
	const float dt = (float)p_state->get_step();
	if (dt <= 0.0f) return;
	const Transform3D t = p_state->get_transform();
	const Vector3 cg = t.xform(com), lv = p_state->get_linear_velocity(), av = p_state->get_angular_velocity();
	const Quaternion q = t.basis.get_rotation_quaternion();
	vd::Chassis c;
	c.p = { cg.x, cg.y, cg.z }; c.q = { q.x, q.y, q.z, q.w };
	c.v = { lv.x, lv.y, lv.z }; c.w = { av.x, av.y, av.z };
	// what this step did to it that the springs and tyres did not: a knock
	{
		const float g = (lv - last_v).length() / dt / vd::G;
		if (g > hardest_hit && g > 1.6f) hardest_hit = g;
	}
	PhysicsDirectSpaceState3D *ss = p_state->get_space_state();
	for (int i = 0; i < 4; i++) {
		vd::V3 from, d; float len;
		car.ray(i, c, from, d, len);
		bool hit = false;
		if (ss) {
			rq->set_from(Vector3(from.x, from.y, from.z));
			rq->set_to(Vector3(from.x + d.x * len, from.y + d.y * len, from.z + d.z * len));
			const Dictionary h = ss->intersect_ray(rq);
			if (!h.is_empty()) {
				const Vector3 hp = h["position"], hn = h["normal"];
				car.set_ground(i, true, vd::V3{ hp.x, hp.y, hp.z }, vd::V3{ hn.x, hn.y, hn.z }, 1.0f);
				hit = true;
			}
		}
		if (!hit) car.set_ground(i, false, vd::V3{}, vd::V3{ 0, 1, 0 }, 1.0f);
	}
	if (player) read_player();
	car.in.throttle = c_throttle; car.in.brake = c_brake; car.in.steer = c_steer; car.in.handbrake = c_handbrake; car.in.dir = dir;
	const int sub = std::min(std::max((int)std::lround(dt * 360.0f), 2), 12);
	car.step(c, dt, sub, false);
	const Vector3 nv(c.v.x, c.v.y, c.v.z);
	p_state->set_linear_velocity(nv);
	p_state->set_angular_velocity(Vector3(c.w.x, c.w.y, c.w.z));
	last_v = nv;
	odo += std::fabs(car.speed) * dt;
}

void CityCar::_process(double p_delta) {
	if (!made) return;
	for (int i = 0; i < 4; i++) {   // the wheels: on their springs, turned, spun
		if (!wheel_vis[i] || !split) continue;
		const vd::Wheel &w = car.wh[i];
		const Basis b = Basis(Vector3(0, 1, 0), w.front ? w.steer : 0.0f) * Basis(Vector3(1, 0, 0), w.angle);
		wheel_vis[i]->set_transform(Transform3D(b, hub_local[i] + Vector3(0, std::min(w.comp, car.s.travel_up), 0)));
	}
	if (cam) {   // behind the car, swinging round as it turns, a little further back and wider at speed
		const Transform3D t = get_global_transform();
		const Vector3 fwd = t.basis.get_column(2);
		const float sp = std::fabs(car.speed), dt = (float)std::min(p_delta, 0.1);
		const float want_yaw = std::atan2(fwd.x, fwd.z);
		if (!cam_set) { cam_yaw = want_yaw; }
		float dy = std::fmod(want_yaw - cam_yaw + 3.14159265f, 6.2831853f); if (dy < 0) dy += 6.2831853f; dy -= 3.14159265f;
		cam_yaw += dy * (1.0f - std::exp(-dt * (1.6f + sp * 0.12f)));
		const float dist = 5.6f + cm::MODELS[std::min(std::max(model, 0), cm::N_MODELS - 1)].half_len * 0.8f + sp * 0.035f, h = 2.1f + cm::MODELS[std::min(std::max(model, 0), cm::N_MODELS - 1)].height * 0.35f;
		const Vector3 look = t.origin + Vector3(0, 1.1f, 0);
		const Vector3 want = look - Vector3(std::sin(cam_yaw), 0, std::cos(cam_yaw)) * dist + Vector3(0, h - 1.1f, 0);
		if (!cam_set) { cam_pos = want; cam_look = look; cam_set = true; }
		const float k = 1.0f - std::exp(-dt * 9.0f);
		cam_pos += (want - cam_pos) * k; cam_look += (look - cam_look) * (1.0f - std::exp(-dt * 14.0f));
		cam->set_global_transform(Transform3D(Basis(), cam_pos).looking_at(cam_look, Vector3(0, 1, 0)));
		cam->set_fov(62.0 + std::min(sp, 60.0f) * 0.22);
	}
}

Dictionary CityCar::get_state() const {
	Dictionary d;
	d["speed"] = car.speed; d["kmh"] = car.speed * 3.6f; d["rpm"] = car.rpm(); d["gear"] = dir == -1 ? -1 : car.gear;
	d["side_g"] = car.lat_g; d["forward_g"] = car.long_g; d["clutch"] = car.clutch; d["steer"] = car.steer_now;
	d["metres"] = odo; d["hardest_knock_g"] = hardest_hit;
	int on = 0; float slip = 0;
	for (int i = 0; i < 4; i++) { if (car.wh[i].ground) on++; slip = std::max(slip, car.wh[i].slip); }
	d["wheels_on_ground"] = on; d["slip_most"] = slip;
	d["wheelbase"] = car.s.wheelbase; d["track"] = car.s.track_f; d["wheel_r"] = car.s.wheel_r; d["mass"] = car.s.mass;
	return d;
}

void CityCar::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_model", "model"), &CityCar::set_model);
	ClassDB::bind_method(D_METHOD("get_model"), &CityCar::get_model);
	ClassDB::bind_method(D_METHOD("set_feel", "feel"), &CityCar::set_feel);
	ClassDB::bind_method(D_METHOD("get_feel"), &CityCar::get_feel);
	ClassDB::bind_method(D_METHOD("set_paint", "colour"), &CityCar::set_paint);
	ClassDB::bind_method(D_METHOD("get_paint"), &CityCar::get_paint);
	ClassDB::bind_method(D_METHOD("set_player", "on"), &CityCar::set_player);
	ClassDB::bind_method(D_METHOD("get_player"), &CityCar::get_player);
	ClassDB::bind_method(D_METHOD("set_chase_camera", "on"), &CityCar::set_chase_camera);
	ClassDB::bind_method(D_METHOD("get_chase_camera"), &CityCar::get_chase_camera);
	ClassDB::bind_method(D_METHOD("set_wheel_mask", "mask"), &CityCar::set_wheel_mask);
	ClassDB::bind_method(D_METHOD("get_wheel_mask"), &CityCar::get_wheel_mask);
	ClassDB::bind_method(D_METHOD("set_controls", "throttle", "brake", "steer", "handbrake", "reverse"), &CityCar::set_controls);
	ClassDB::bind_method(D_METHOD("get_state"), &CityCar::get_state);
	ClassDB::bind_method(D_METHOD("become", "model", "feel", "paint"), &CityCar::become);
	ClassDB::bind_method(D_METHOD("launch", "at", "velocity"), &CityCar::launch);
	ClassDB::bind_method(D_METHOD("put_away", "where"), &CityCar::put_away);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "model"), "set_model", "get_model");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "feel"), "set_feel", "get_feel");
	ADD_PROPERTY(PropertyInfo(Variant::COLOR, "paint"), "set_paint", "get_paint");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "player"), "set_player", "get_player");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "chase_camera"), "set_chase_camera", "get_chase_camera");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "wheel_mask"), "set_wheel_mask", "get_wheel_mask");
}

} // namespace godot
