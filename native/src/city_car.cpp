// CityCar: see city_car.h.
#include "city_car.h"
#include "ui_plate.h"

#include "car_models.h"
#include "city_player.h"

#include <godot_cpp/classes/box_shape3d.hpp>
#include <godot_cpp/classes/collision_shape3d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/audio_server.hpp>
#include <godot_cpp/classes/audio_stream.hpp>
#include <godot_cpp/classes/audio_stream_player3d.hpp>
#include <godot_cpp/classes/cpu_particles3d.hpp>
#include <godot_cpp/classes/curve.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/gradient.hpp>
#include <godot_cpp/classes/gradient_texture2d.hpp>
#include <godot_cpp/classes/quad_mesh.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/variant/packed_vector4_array.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/classes/input_event_screen_drag.hpp>
#include <godot_cpp/classes/v_box_container.hpp>
#include <godot_cpp/classes/panel_container.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/canvas_layer.hpp>
#include <godot_cpp/classes/input_event_screen_touch.hpp>
#include <godot_cpp/classes/viewport.hpp>
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
		// the damage's photo detail and the street reflected in the paint (the old game's car_models.gd)
		mat->set_shader_parameter("damage_detail", rl->load("res://vehicles/tex/car_damage_detail.png"));
		mat->set_shader_parameter("glass_cracks", rl->load("res://vehicles/tex/car_glass_cracks.png"));
		mat->set_shader_parameter("env_pano", rl->load("res://vehicles/tex/car_env.jpg"));
		mat_wheel = mat->duplicate();
	}
	mi_body = memnew(MeshInstance3D);
	if (mat.is_valid()) mi_body->set_material_override(mat);
	add_child(mi_body);
	for (int i = 0; i < 4; i++) {
		MeshInstance3D *wi = memnew(MeshInstance3D);
		if (mat_wheel.is_valid()) wi->set_material_override(mat_wheel);
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
	if (mat_wheel.is_valid()) mat_wheel->set_shader_parameter("paint", paint);
	mi_body->set_mesh(body_mesh);
	set_car_maps();
	// the driver's door: behind the front-left wheel's arch, 0.42 of the wheelbase long (0.95-1.25 m), from the sill to under
	// the roof, the outer part of the body's left side; hinged at its front edge
	{
		const float r = split ? wr[0] : 0.33f, wb = split ? sp.wheelbase : cmod.half_len * 1.2f;
		const float zf = (split ? wc[0].z : cmod.half_len * 0.62f) - r * 1.15f;
		const float L = std::min(std::max(0.42f * wb, 0.95f), 1.25f);
		const float y0 = (split ? wc[0].y : r) - r * 0.12f;   // (lower took a sliver of the underbody with it)
		door_lo = Vector3(cmod.half_w * 0.42f, y0, zf - L);
		door_hi = Vector3(cmod.half_w + 0.2f, cmod.height * 0.87f, zf);
		door_hinge = Vector2(cmod.half_w * 0.9f, zf);
		if (mat.is_valid()) { mat->set_shader_parameter("door_lo", door_lo); mat->set_shader_parameter("door_hi", door_hi); mat->set_shader_parameter("door_hinge", door_hinge); }
		set_door(0.0f);
	}
	// the hull the dents are placed on: the drawn body
	if (body_mesh.is_valid()) { const AABB a = body_mesh->get_aabb(); if (a.size.length() > 1.0f) hull = a; }
	base_torque = car.s.torque;
	repair();
	for (int i = 0; i < 4; i++) {
		wheel_vis[i]->set_mesh(split ? wheel_mesh[i] : Ref<Mesh>());
		wheel_vis[i]->set_visible(split);
		wheel_vis[i]->set_position(hub_local[i]);
	}
	dir = 1; odo = 0.0; hardest_hit = 0.0f; last_v = Vector3();
}

// ---------------------------------------------------------------- the new car textures
// car-tex r3 (the assets branch, 19 Nov): the near model's UV is ONE shared trim sheet (lamps, grille, plate, tyres,
// wheels, trim), its UV2 the car's own unwrap with its normal map (panel gaps) and its AO / grime / cabin map:
// car_paint.gdshader's map_mode 2. stern_g shares volt_x's maps. A model without them keeps the old atlas.
static String cartex_id(const String &p_id) { return p_id == "stern_g" ? String("volt_x") : p_id; }

void CityCar::set_car_maps() {
	if (mat.is_null()) return;
	const String base = "res://vehicles/models/cartex/";
	const String t = cartex_id(cm::MODELS[std::min(std::max(model, 0), cm::N_MODELS - 1)].id);
	ResourceLoader *rl = ResourceLoader::get_singleton();
	const Ref<Mesh> bm = mi_body->get_mesh();
	const bool ok = rl->exists(base + t + String("_car_normal.png")) && bm.is_valid() && bm->has_meta("cartex");
	for (Ref<ShaderMaterial> m : { mat, mat_wheel }) {
		if (m.is_null()) continue;
		m->set_shader_parameter("map_mode", ok ? 2 : 0);
		if (!ok) continue;
		m->set_shader_parameter("trim_albedo", rl->load(base + String("trim_albedo.png")));
		m->set_shader_parameter("trim_normal", rl->load(base + String("trim_normal.png")));
		m->set_shader_parameter("trim_orm", rl->load(base + String("trim_orm.png")));
		m->set_shader_parameter("car_normal", rl->load(base + t + String("_car_normal.png")));
		m->set_shader_parameter("car_orm", rl->load(base + t + String("_car_orm.png")));
	}
}

// ---------------------------------------------------------------- damage
void CityCar::hit(const Vector3 &p_dv) {
	if (!made) return;
	const float sev = p_dv.length();
	if (sev < 0.01f) return;
	const Vector3 ld = (get_global_transform().basis.inverse().xform(p_dv)).normalized();   // the body's frame; the obstacle is on the -ld side
	const Vector3 c = hull.get_center(), h = hull.size * 0.5f, d = -ld;
	float t = 1e9f;
	for (int k = 0; k < 3; k++) if (std::fabs(d[k]) > 1e-4f) t = std::min(t, h[k] / std::fabs(d[k]));
	Vector3 pt = c + d * t;
	pt.y = std::min(std::max(pt.y, hull.position.y + hull.size.y * 0.25f), hull.position.y + hull.size.y * 0.6f);
	const float depth = std::min(std::max((sev - 2.0f) * 0.022f, 0.02f), 0.22f);
	const float rad = std::min(std::max(0.35f + sev * 0.035f, 0.4f), 0.9f);
	add_dent(pt, ld * depth, rad);
	health = std::max(0.0f, health - sev * sev * 0.0012f);
	hits++;
	apply_health();
	crash_sound(sev);
	emit_signal("damaged", sev, health);
}

void CityCar::add_dent(const Vector3 &p_at, const Vector3 &p_push, float p_r) {
	for (Dent &e : dents) {
		if (e.at.distance_to(p_at) < e.r * 0.5f) {   // close to one: it deepens
			e.push = (e.push + p_push * 0.7f).limit_length(0.3f); e.r = std::min(std::max(e.r, p_r) + 0.05f, 1.0f);
			upload_dents(); return;
		}
	}
	dents.push_back(Dent{ p_at, p_push, p_r });
	if (dents.size() > 8) {   // the oldest folds into its nearest neighbour
		const Dent o = dents.front(); dents.erase(dents.begin());
		Dent *best = &dents[0];
		for (Dent &e : dents) if (e.at.distance_to(o.at) < best->at.distance_to(o.at)) best = &e;
		best->push = (best->push + o.push * 0.5f).limit_length(0.3f);
	}
	upload_dents();
}

void CityCar::upload_dents() {
	if (mat.is_null()) return;
	PackedVector4Array P, D;
	for (const Dent &e : dents) { P.push_back(Vector4(e.at.x, e.at.y, e.at.z, e.r)); D.push_back(Vector4(e.push.x, e.push.y, e.push.z, 0.0f)); }
	while (P.size() < 8) { P.push_back(Vector4()); D.push_back(Vector4()); }
	mat->set_shader_parameter("dent_p", P); mat->set_shader_parameter("dent_d", D);
	mat->set_shader_parameter("dent_n", (int)dents.size());
}

void CityCar::apply_health() {
	if (base_torque > 0.0f) car.s.torque = base_torque * (0.45f + 0.55f * std::min(std::max(health / 0.6f, 0.0f), 1.0f));
	if (health < 0.5f) {
		if (!smoke) {
			smoke = memnew(CPUParticles3D);
			smoke->set_position(Vector3(hull.get_center().x, hull.get_end().y - 0.15f, hull.get_end().z - 0.6f));
			smoke->set_lifetime(2.2); smoke->set_use_local_coordinates(false);
			smoke->set_direction(Vector3(0, 1, 0)); smoke->set_spread(18.0f);
			smoke->set_param_min(CPUParticles3D::PARAM_INITIAL_LINEAR_VELOCITY, 0.6f); smoke->set_param_max(CPUParticles3D::PARAM_INITIAL_LINEAR_VELOCITY, 1.4f);
			smoke->set_gravity(Vector3(0, 0.6f, 0));
			smoke->set_param_min(CPUParticles3D::PARAM_SCALE, 0.5f); smoke->set_param_max(CPUParticles3D::PARAM_SCALE, 1.1f);
			Ref<Curve> cv; cv.instantiate(); cv->add_point(Vector2(0, 0.4f)); cv->add_point(Vector2(1, 2.2f)); smoke->set_param_curve(CPUParticles3D::PARAM_SCALE, cv);
			Ref<Gradient> gr; gr.instantiate(); gr->set_color(0, Color(1, 1, 1, 0.9f)); gr->set_color(1, Color(1, 1, 1, 0.0f)); smoke->set_color_ramp(gr);
			Ref<GradientTexture2D> puff; puff.instantiate();
			puff->set_fill(GradientTexture2D::FILL_RADIAL); puff->set_fill_from(Vector2(0.5f, 0.5f)); puff->set_fill_to(Vector2(1.0f, 0.5f)); puff->set_width(64); puff->set_height(64);
			Ref<Gradient> pg; pg.instantiate(); pg->set_color(0, Color(1, 1, 1, 1)); pg->set_color(1, Color(1, 1, 1, 0)); puff->set_gradient(pg);
			Ref<StandardMaterial3D> m; m.instantiate();
			m->set_shading_mode(BaseMaterial3D::SHADING_MODE_UNSHADED); m->set_transparency(BaseMaterial3D::TRANSPARENCY_ALPHA);
			m->set_billboard_mode(BaseMaterial3D::BILLBOARD_PARTICLES); m->set_flag(BaseMaterial3D::FLAG_ALBEDO_FROM_VERTEX_COLOR, true);
			m->set_texture(BaseMaterial3D::TEXTURE_ALBEDO, puff);
			Ref<QuadMesh> q; q.instantiate(); q->set_size(Vector2(0.7f, 0.7f)); q->set_material(m);
			smoke->set_mesh(q);
			smoke->set_cast_shadows_setting(GeometryInstance3D::SHADOW_CASTING_SETTING_OFF);
			add_child(smoke);
		}
		const bool thick = health < 0.2f;
		smoke->set_amount(thick ? 28 : 14);
		smoke->set_color(thick ? Color(0.12f, 0.12f, 0.12f, 0.75f) : Color(0.75f, 0.75f, 0.75f, 0.45f));
		smoke->set_emitting(true);
	} else if (smoke) smoke->set_emitting(false);
}

void CityCar::crash_sound(float p_sev) {
	if (clock_t - snd_t < 0.25 || !is_inside_tree()) return;
	snd_t = clock_t;
	const char *bank = p_sev >= 10.0f ? "car_crash_heavy_" : (p_sev >= 5.0f ? "car_crash_mid_" : "car_bump_");
	const String nm = String(bank) + String::num_int64((int64_t)(UtilityFunctions::randi() % 3u));
	const String path = String("res://audio/sfx/") + nm + String(".ogg");
	Ref<AudioStream> st = ResourceLoader::get_singleton()->load(path);
	last_sound = nm;
	if (st.is_null()) return;
	if (!snd) {
		snd = memnew(AudioStreamPlayer3D);
		snd->set_bus(AudioServer::get_singleton()->get_bus_index("SFX") >= 0 ? StringName("SFX") : StringName("Master"));
		snd->set_unit_size(6.0f); snd->set_max_distance(90.0f);
		add_child(snd);
	}
	snd->set_stream(st);
	snd->set_volume_db(std::min(std::max(-10.0f + p_sev * 1.2f, -10.0f), 4.0f));
	snd->set_pitch_scale((float)UtilityFunctions::randf_range(0.92, 1.06));
	snd->play();
}

void CityCar::repair() {
	dents.clear(); health = 1.0f; jolt_acc = Vector3(); hits_due.clear();
	if (base_torque > 0.0f) car.s.torque = base_torque;
	upload_dents();
	if (smoke) smoke->set_emitting(false);
}

Dictionary CityCar::get_damage() const {
	Dictionary d;
	d["health"] = health; d["dents"] = (int)dents.size(); d["hits"] = hits; d["last_sound"] = last_sound;
	d["torque"] = car.s.torque; d["base_torque"] = base_torque; d["smoke"] = smoke && smoke->is_emitting();
	float deepest = 0.0f; for (const Dent &e : dents) deepest = std::max(deepest, e.push.length());
	d["deepest"] = deepest;
	d["map_mode"] = mat.is_valid() ? mat->get_shader_parameter("map_mode") : Variant(0);
	return d;
}

void CityCar::take_wheel(bool p_on) {
	if (!made) return;
	player = p_on;
	if (p_on) {
		chase_camera = true;
		if (!cam) {
			cam = memnew(Camera3D);
			cam->set_as_top_level(true);
			cam->set_fov(62.0); cam->set_near(0.2); cam->set_far(1500.0);
			add_child(cam);
		}
		cam_set = false;
		cam->make_current();
		c_handbrake = 0.0f; c_brake = 0.0f;
	} else {
		set_controls(0.0, 1.0, 0.0, 1.0, false);   // (left parked: brakes and handbrake on)
		for (int i = 0; i < 16; i++) t_zone[i] = 0;
		t_steer_id = -1; t_steer = 0.0f;
	}
}

bool CityCar::enter_node(Node3D *p_player) { return enter(Object::cast_to<CityPlayer>(p_player)); }

void CityCar::set_door(float p_open) {
	door = std::min(std::max(p_open, 0.0f), 1.0f);
	if (mat.is_valid()) mat->set_shader_parameter("door_open", door * door * (3.0f - 2.0f * door));
}

Vector3 CityCar::door_spot() const {
	const float z = 0.5f * (door_lo.z + door_hi.z) + 0.15f;
	return Vector3(door_hinge.x / 0.9f + 0.55f, 0.0f, z);
}

Vector3 CityCar::seat_hips() const {
	const float half_w = door_hinge.x / 0.9f;
	// (low enough that his head clears the roof: a seated figure's head top is about 0.88 m over its hips; the first seat,
	// 0.42 m over the sill, put the head through the roof: tests/game/test_car_entry.gd)
	const float roof = door_hi.y / 0.87f;
	return Vector3(half_w * 0.36f, std::min(door_lo.y + 0.30f, roof - 0.98f), 0.5f * (door_lo.z + door_hi.z) - 0.18f);
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

// Touch driving: the old game's scheme (docs/OLD_CONTROLS_SPEC.md; Yasin: "copy it as it was"): the left half of the screen is
// an invisible stick for the wheel (full lock at 80 px, a dead zone of 0.08); GAS and BRAKE are the old plates above the
// phone button's corner (BRAKE held at a standstill reverses). Many fingers at once.
void CityCar::_input(const Ref<InputEvent> &p_event) {
	if (!player) return;
	Viewport *vp = get_viewport();
	if (!vp) return;
	const Vector2 sz = vp->get_visible_rect().size;
	if (sz.x < 1.0f || sz.y < 1.0f) return;
	const float k = std::max(sz.y / 648.0f, 0.5f);
	auto zone = [&](const Vector2 &p) { return plate::gas_rect(sz).grow(8.0f).has_point(p) ? 2 : (plate::brake_rect(sz).grow(8.0f).has_point(p) ? 1 : 0); };
	if (const InputEventScreenTouch *t = Object::cast_to<InputEventScreenTouch>(p_event.ptr())) {
		const int id = t->get_index();
		const Vector2 p = t->get_position();
		if (t->is_pressed()) {
			const int zk = zone(p);
			if (zk && id >= 0 && id < 16) t_zone[id] = zk;
			else if (p.x < sz.x * 0.5f && t_steer_id < 0) { t_steer_id = id; t_steer_x0 = p.x; t_steer = 0.0f; }
		} else {
			if (id == t_steer_id) { t_steer_id = -1; t_steer = 0.0f; }
			if (id >= 0 && id < 16) t_zone[id] = 0;
		}
		return;
	}
	if (const InputEventScreenDrag *d = Object::cast_to<InputEventScreenDrag>(p_event.ptr())) {
		const int id = d->get_index();
		const Vector2 p = d->get_position();
		if (id == t_steer_id) { const float sx = std::min(std::max(-(p.x - t_steer_x0) / (80.0f * k), -1.0f), 1.0f); t_steer = std::fabs(sx) > 0.08f ? sx : 0.0f; }
		else if (id >= 0 && id < 16 && t_zone[id] != 0) { const int zk = zone(p); if (zk) t_zone[id] = zk; }   // (a thumb may slide between the pedals)
	}
}

void CityCar::make_hud() {
	hud = memnew(CanvasLayer);
	hud->set_layer(40);
	add_child(hud);
	auto pedal = [&](const char *en_, const char *tr_, const char *look) {
		PanelContainer *p = plate::panel(look);
		p->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
		VBoxContainer *v = memnew(VBoxContainer);
		v->set_alignment(BoxContainer::ALIGNMENT_END); v->add_theme_constant_override("separation", -2); v->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
		Label *a = plate::label(en_, plate::FS_ACTION, plate::TEXT, 700); a->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER);
		Label *b = plate::label(tr_, plate::FS_HELP, plate::DIM, 600); b->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER);
		v->add_child(a); v->add_child(b); p->add_child(v); hud->add_child(p);
		return p;
	};
	hud_gas = pedal("GAS", "GAZ", "plate_go");
	hud_brake = pedal("BRAKE", "FREN", "plate");
	PanelContainer *sp = plate::panel("plate");
	sp->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
	sp->set_name("Speed");
	VBoxContainer *v = memnew(VBoxContainer); v->add_theme_constant_override("separation", -6);
	hud_kmh = plate::label("0", plate::FS_DISPLAY, plate::TEXT, 700);
	v->add_child(hud_kmh); v->add_child(plate::caps("km/h"));
	sp->add_child(v); hud->add_child(sp);
}

// The keys and the pad. S (or the left trigger) brakes; once the car stands it becomes the reverse gear's pedal.
void CityCar::read_player() {
	Input *in = Input::get_singleton();
	bool tg = false, tb = false, th = false;
	for (int i = 0; i < 16; i++) { tb = tb || t_zone[i] == 1; tg = tg || t_zone[i] == 2; }
	const float up = std::max(in->is_key_pressed(KEY_W) || in->is_key_pressed(KEY_UP) || tg ? 1.0f : 0.0f, std::max(0.0f, (float)in->get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)));
	const float down = std::max(in->is_key_pressed(KEY_S) || in->is_key_pressed(KEY_DOWN) || tb ? 1.0f : 0.0f, std::max(0.0f, (float)in->get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)));
	float st = (in->is_key_pressed(KEY_A) || in->is_key_pressed(KEY_LEFT) ? 1.0f : 0.0f) - (in->is_key_pressed(KEY_D) || in->is_key_pressed(KEY_RIGHT) ? 1.0f : 0.0f) + t_steer;
	const float jx = (float)in->get_joy_axis(0, JOY_AXIS_LEFT_X);
	if (std::fabs(jx) > 0.12f) st -= jx;
	if (dir == 1 && down > 0.1f && up < 0.1f && car.speed < 0.8f) dir = -1;
	else if (dir == -1 && up > 0.1f && car.speed > -0.8f) dir = 1;
	c_throttle = dir == 1 ? up : down * 0.6f; c_brake = dir == 1 ? down : up;   // (reverse at 0.6, as the old game)
	if (dir == -1 && car.speed < -4.2f) c_throttle = 0.0f;   // (and no faster than 15 km/h backwards: held, it reached 50)
	c_steer = std::min(std::max(st, -1.0f), 1.0f);
	c_handbrake = (in->is_key_pressed(KEY_SPACE) || in->is_joy_button_pressed(0, JOY_BUTTON_A) || th) ? 1.0f : 0.0f;
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
		// an impact: steps that change the flat speed by more than 1 m/s each, summed until a quiet step
		Vector3 dv = lv - last_v; dv.y = 0.0f;
		if (dv.length() > 1.0f) jolt_acc += dv;
		else if (jolt_acc.length_squared() > 0.0f) { if (jolt_acc.length() >= 2.5f) hits_due.push_back(jolt_acc); jolt_acc = Vector3(); }
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
	clock_t += p_delta;
	door_update(p_delta);
	if (!hits_due.empty()) { const std::vector<Vector3> hd = hits_due; hits_due.clear(); for (const Vector3 &dv : hd) hit(dv); }
	if (player) {   // the old pedals and the speed plate, while the player drives
		if (!hud) make_hud();
		Viewport *vp = get_viewport();
		if (vp) {
			const Vector2 sz = vp->get_visible_rect().size;
			const Rect2 g = plate::gas_rect(sz), b = plate::brake_rect(sz), s = plate::speed_rect(sz);
			hud_gas->set_position(g.position); hud_gas->set_size(g.size);
			hud_brake->set_position(b.position); hud_brake->set_size(b.size);
			if (Control *sp = Object::cast_to<Control>(hud->get_node_or_null("Speed"))) { sp->set_position(s.position); sp->set_size(s.size); }
			bool tb = false, tg = false;
			for (int i = 0; i < 16; i++) { tb = tb || t_zone[i] == 1; tg = tg || t_zone[i] == 2; }
			hud_gas->add_theme_stylebox_override("panel", plate::box(tg ? "raised_hi" : "plate_go"));
			hud_brake->add_theme_stylebox_override("panel", plate::box(tb ? "raised_hi" : "plate"));
			hud_kmh->set_text(String::num_int64((int64_t)std::lround(std::fabs(car.speed) * 3.6f)));
		}
		hud->set_visible(true);
	} else if (hud) hud->set_visible(false);
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
	ClassDB::bind_method(D_METHOD("hit", "dv"), &CityCar::hit);
	ClassDB::bind_method(D_METHOD("take_wheel", "on"), &CityCar::take_wheel);
	ClassDB::bind_method(D_METHOD("set_door", "open"), &CityCar::set_door);
	ClassDB::bind_method(D_METHOD("enter", "player"), &CityCar::enter_node);
	ClassDB::bind_method(D_METHOD("leave"), &CityCar::leave);
	ClassDB::bind_method(D_METHOD("get_entry_state"), &CityCar::get_entry_state);
	ClassDB::bind_method(D_METHOD("is_seated"), &CityCar::is_seated);
	ClassDB::bind_method(D_METHOD("get_driver_hips"), &CityCar::get_driver_hips);
	ClassDB::bind_method(D_METHOD("get_door"), &CityCar::get_door);
	ClassDB::bind_method(D_METHOD("repair"), &CityCar::repair);
	ClassDB::bind_method(D_METHOD("get_damage"), &CityCar::get_damage);
	ADD_SIGNAL(MethodInfo("damaged", PropertyInfo(Variant::FLOAT, "severity"), PropertyInfo(Variant::FLOAT, "health")));
	ADD_PROPERTY(PropertyInfo(Variant::INT, "model"), "set_model", "get_model");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "feel"), "set_feel", "get_feel");
	ADD_PROPERTY(PropertyInfo(Variant::COLOR, "paint"), "set_paint", "get_paint");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "player"), "set_player", "get_player");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "chase_camera"), "set_chase_camera", "get_chase_camera");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "wheel_mask"), "set_wheel_mask", "get_wheel_mask");
}

} // namespace godot
