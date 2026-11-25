// Lab A (procedural): the player body. See lab_player.h, DECISIONS.md section 3-4.
#include "lab_player.h"
#include "lab_camera.h"

#include <godot_cpp/classes/display_server.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/input_event_joypad_button.hpp>
#include <godot_cpp/classes/input_event_joypad_motion.hpp>
#include <godot_cpp/classes/input_event_key.hpp>
#include <godot_cpp/classes/input_event_screen_drag.hpp>
#include <godot_cpp/classes/input_event_screen_touch.hpp>
#include <godot_cpp/classes/input_map.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;
using namespace lab;

void LabPlayer::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_walk_speed", "v"), &LabPlayer::set_walk_speed);
	ClassDB::bind_method(D_METHOD("get_walk_speed"), &LabPlayer::get_walk_speed);
	ClassDB::bind_method(D_METHOD("set_run_speed", "v"), &LabPlayer::set_run_speed);
	ClassDB::bind_method(D_METHOD("get_run_speed"), &LabPlayer::get_run_speed);
	ClassDB::bind_method(D_METHOD("set_camera_path", "p"), &LabPlayer::set_camera_path);
	ClassDB::bind_method(D_METHOD("get_camera_path"), &LabPlayer::get_camera_path);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "walk_speed"), "set_walk_speed", "get_walk_speed");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "run_speed"), "set_run_speed", "get_run_speed");
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "camera_path"), "set_camera_path", "get_camera_path");
	ClassDB::bind_method(D_METHOD("set_scripted_input", "stick", "run", "enabled"), &LabPlayer::set_scripted_input);
	ClassDB::bind_method(D_METHOD("get_metrics"), &LabPlayer::get_metrics);
	ClassDB::bind_method(D_METHOD("reset_metrics"), &LabPlayer::reset_metrics);
	ClassDB::bind_method(D_METHOD("teleport", "pos", "yaw"), &LabPlayer::teleport);
	ClassDB::bind_method(D_METHOD("get_body_yaw"), &LabPlayer::get_body_yaw);
	ClassDB::bind_method(D_METHOD("is_gait_active"), &LabPlayer::is_gait_active);
	ClassDB::bind_method(D_METHOD("get_horizontal_velocity"), &LabPlayer::get_horizontal_velocity);
}

static void add_key(const StringName &action, Key k) {
	Ref<InputEventKey> e;
	e.instantiate();
	e->set_physical_keycode(k);
	InputMap::get_singleton()->action_add_event(action, e);
}
static void add_axis(const StringName &action, JoyAxis a, float v) {
	Ref<InputEventJoypadMotion> e;
	e.instantiate();
	e->set_axis(a);
	e->set_axis_value(v);
	InputMap::get_singleton()->action_add_event(action, e);
}
static void add_button(const StringName &action, JoyButton b) {
	Ref<InputEventJoypadButton> e;
	e.instantiate();
	e->set_button_index(b);
	InputMap::get_singleton()->action_add_event(action, e);
}

// Yasin's controls (brief): W A S D or the left stick, Shift runs, C crouch, Space jump, mouse or right stick looks.
void LabPlayer::setup_input_map() {
	InputMap *im = InputMap::get_singleton();
	auto act = [&](const char *n, float dz) {
		if (!im->has_action(n)) im->add_action(n, dz);
	};
	act("kb_left", 0.5f);
	act("kb_right", 0.5f);
	act("kb_forward", 0.5f);
	act("kb_back", 0.5f);
	act("pad_left", 0.05f);
	act("pad_right", 0.05f);
	act("pad_forward", 0.05f);
	act("pad_back", 0.05f);
	act("look_left", 0.1f);
	act("look_right", 0.1f);
	act("look_up", 0.1f);
	act("look_down", 0.1f);
	act("run", 0.5f);
	act("crouch", 0.5f);
	act("jump", 0.5f);
	if (im->action_get_events("kb_left").size() == 0) {
		add_key("kb_left", KEY_A);
		add_key("kb_right", KEY_D);
		add_key("kb_forward", KEY_W);
		add_key("kb_back", KEY_S);
		add_axis("pad_left", JOY_AXIS_LEFT_X, -1.0f);
		add_axis("pad_right", JOY_AXIS_LEFT_X, 1.0f);
		add_axis("pad_forward", JOY_AXIS_LEFT_Y, -1.0f);
		add_axis("pad_back", JOY_AXIS_LEFT_Y, 1.0f);
		add_axis("look_left", JOY_AXIS_RIGHT_X, -1.0f);
		add_axis("look_right", JOY_AXIS_RIGHT_X, 1.0f);
		add_axis("look_up", JOY_AXIS_RIGHT_Y, -1.0f);
		add_axis("look_down", JOY_AXIS_RIGHT_Y, 1.0f);
		add_key("run", KEY_SHIFT);
		add_key("crouch", KEY_C);
		add_key("jump", KEY_SPACE);
		add_button("jump", JOY_BUTTON_A);
		add_button("crouch", JOY_BUTTON_B);
	}
}

void LabPlayer::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) return;
	setup_input_map();
	// world contract 1: the player's capsule is on layer 2 and collides with world, breakables, openings, cars, people
	set_collision_layer(lab::LAYER_PLAYER);
	set_collision_mask(lab::CAPSULE_MASK);
	TypedArray<Node> ps = find_children("*", "LabPoser", true, false);
	if (ps.size() > 0) poser = Object::cast_to<LabPoser>(ps[0]);
	if (!poser) {
		TypedArray<Node> sks = find_children("*", "Skeleton3D", true, false);
		if (sks.size() > 0) {
			poser = memnew(LabPoser);
			poser->set_name("LabPoser");
			Object::cast_to<Node>(sks[0])->add_child(poser);
		}
	}
	if (!poser || !poser->bind_player(this)) {
		UtilityFunctions::push_error("LabPlayer: needs a LabPoser under its Skeleton3D");
		return;
	}
	if (!camera_path.is_empty()) camera = Object::cast_to<LabCamera>(get_node_or_null(camera_path));
	motor.d = poser->dims();
	motor.ground = [this](const Vector3 &a, const Vector3 &b) { return ray(a, b); };
	float yaw0 = get_rotation().y;
	set_rotation(Vector3());
	motor.reset(get_global_position(), yaw0);
	prev_t = cur_t = motor.targets();
	ready_ok = true;
}

void LabPlayer::teleport(const Vector3 &pos, float yaw) {
	set_global_position(pos);
	set_velocity(Vector3());
	reset_physics_interpolation();
	motor.reset(pos, yaw);
	prev_t = cur_t = motor.targets();
	if (camera) camera->snap();
}

RayHit LabPlayer::ray(const Vector3 &from, const Vector3 &to) const {
	RayHit r;
	PhysicsDirectSpaceState3D *ss = get_world_3d()->get_direct_space_state();
	if (!ss) return r;
	TypedArray<RID> ex;
	ex.push_back(get_rid());
	Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(from, to, lab::PROBE_MASK, ex);
	Dictionary d = ss->intersect_ray(q);
	if (d.is_empty()) return r;
	r.hit = true;
	r.pos = d["position"];
	r.normal = d["normal"];
	return r;
}

void LabPlayer::set_scripted_input(const Vector2 &stick, bool run, bool enabled) {
	scripted = enabled;
	script_stick = stick;
	script_run = run;
}

// Stick in camera space: x right, y forward. Magnitude 0..1 (DECISIONS 4.1).
Vector2 LabPlayer::read_stick(bool &run) const {
	if (scripted) {
		run = script_run;
		return script_stick;
	}
	Input *in = Input::get_singleton();
	run = in->is_action_pressed("run");
	Vector2 kb(in->get_action_strength("kb_right") - in->get_action_strength("kb_left"),
			in->get_action_strength("kb_forward") - in->get_action_strength("kb_back"));
	if (kb.length() > 0.1f) return kb.normalized() * 0.7f; // keys: a walk (run with Shift)
	Vector2 pad(in->get_action_strength("pad_right") - in->get_action_strength("pad_left"),
			in->get_action_strength("pad_forward") - in->get_action_strength("pad_back"));
	if (touch_stick.length() > pad.length()) pad = touch_stick;
	if (pad.length() > 1.0f) pad = pad.normalized();
	return pad;
}

void LabPlayer::_input(const Ref<InputEvent> &event) {
	// Touch (brief): left half a floating stick (full at 80 px), right half looks; double taps crouch / jump.
	Ref<InputEventScreenTouch> t = event;
	Vector2 vp = get_viewport()->get_visible_rect().size;
	if (t.is_valid()) {
		bool left = t->get_position().x < vp.x * 0.5f;
		double now = Time::get_singleton()->get_ticks_msec() / 1000.0;
		if (t->is_pressed()) {
			if (left && touch_move_idx < 0) {
				touch_move_idx = t->get_index();
				touch_move_origin = t->get_position();
				if (last_tap_left > 0 && now - last_tap_left < 0.3) crouch_toggle = !crouch_toggle;
				last_tap_left = now;
			} else if (!left && touch_look_idx < 0) {
				touch_look_idx = t->get_index();
				if (last_tap_right > 0 && now - last_tap_right < 0.3) jump_request = true;
				last_tap_right = now;
			}
		} else {
			if (t->get_index() == touch_move_idx) {
				touch_move_idx = -1;
				touch_stick = Vector2();
			}
			if (t->get_index() == touch_look_idx) touch_look_idx = -1;
		}
		return;
	}
	Ref<InputEventScreenDrag> dr = event;
	if (dr.is_valid()) {
		if (dr->get_index() == touch_move_idx) {
			Vector2 dv = (dr->get_position() - touch_move_origin) / 80.0f;
			if (dv.length() > 1.0f) dv = dv.normalized();
			touch_stick = Vector2(dv.x, -dv.y);
		} else if (dr->get_index() == touch_look_idx && camera) {
			camera->add_look(dr->get_relative() * 0.005f);
		}
	}
}

void LabPlayer::_physics_process(double delta) {
	if (Engine::get_singleton()->is_editor_hint() || !ready_ok) return;
	float dt = (float)delta;
	tick++;
	bool run = false;
	Vector2 stick = read_stick(run);
	float m = stick.length();
	// stick to speed (DECISIONS 4.1): the 1.8-2.2 m/s band is never a held speed (2.2)
	float speed = 0;
	bool analog = scripted ? !run && m < 0.99f : false;
	if (!scripted) {
		Input *in = Input::get_singleton();
		Vector2 kb(in->get_action_strength("kb_right") - in->get_action_strength("kb_left"),
				in->get_action_strength("kb_forward") - in->get_action_strength("kb_back"));
		analog = kb.length() < 0.1f;
	}
	if (m > 0.2f) {
		if (run) {
			speed = run_speed;
		} else if (!analog) {
			speed = walk_speed;
		} else if (m < 0.75f) {
			speed = lerpf(0.7f, 1.5f, (m - 0.2f) / 0.55f);
		} else if (m < 0.85f) {
			speed = 1.5f;
		} else {
			speed = lerpf(3.0f, run_speed, clampf((m - 0.85f) / 0.14f, 0.0f, 1.0f));
		}
	}
	float cam_yaw = camera ? camera->get_yaw() : 0.0f;
	Vector3 cf = yaw_fwd(cam_yaw), cr = -yaw_left(cam_yaw);
	Vector3 dir = cf * stick.y + cr * stick.x;
	Vector3 look = m > 0.2f ? dir.normalized() : Vector3();
	Vector3 vel_des = m > 0.2f ? dir.normalized() * speed : Vector3();

	Vector3 v = motor.steer(get_velocity(), vel_des, dt);
	// floating capsule (7.4): held float_h above the ground by a ray, so small edges never touch it
	Vector3 pos = get_global_position();
	RayHit g = ray(pos + Vector3(0, 0.6f, 0), pos - Vector3(0, 0.6f, 0));
	if (g.hit && pos.y - g.pos.y < 0.35f && vy <= 0.5f) {
		grounded = true;
		vy = clampf((g.pos.y - pos.y) * 15.0f, -6.0f, 6.0f);
	} else {
		grounded = false;
		vy -= GRAV * dt;
	}
	set_velocity(Vector3(v.x, vy, v.z));
	move_and_slide();
	Vector3 vr = get_real_velocity();
	set_velocity(Vector3(vr.x, vy, vr.z));
	pos = get_global_position();
	Vector3 ground_pt = pos; // the body origin is at the soles' level

	MotorInput mi;
	mi.pos = ground_pt;
	mi.vel = flat(vr);
	mi.vel_des = vel_des;
	mi.look_dir = look;
	mi.dt = dt;
	mi.grounded = grounded;
	prev_t = cur_t;
	motor.step(mi);
	cur_t = motor.targets();
	track_response(stick);
}

// Stick-to-response latency (brief: the body visibly answers within ~0.1 s): ticks from a stick change to the first
// tick where the head turns >2 deg, the lean changes >1 deg, the body turns >2 deg, a foot lifts or the hips move 1 cm.
void LabPlayer::track_response(const Vector2 &stick) {
	bool changed = false;
	if ((stick - last_stick).length() > 0.5f) changed = true;
	if (stick.length() > 0.5f && last_stick.length() > 0.5f && std::fabs(stick.angle_to(last_stick)) > 30.0f * DEG)
		changed = true;
	last_stick = stick;
	auto head_yaw = [&]() { return yaw_of(Basis(cur_t.head_rot).xform(Vector3(0, 0, 1))); };
	if (changed) {
		change_tick = tick;
		base_head = yaw_of(Basis(prev_t.head_rot).xform(Vector3(0, 0, 1)));
		base_lean = prev_t.body_lean;
		base_yaw = motor.yaw;
		base_hips_rel = prev_t.hips_pos - get_global_position();
		base_planted[0] = prev_t.planted[0];
		base_planted[1] = prev_t.planted[1];
	}
	if (change_tick >= 0) {
		bool resp = std::fabs(wrap_pi(head_yaw() - base_head)) > 2.0f * DEG || std::fabs(cur_t.body_lean - base_lean) > 1.0f * DEG ||
				cur_t.planted[0] != base_planted[0] || cur_t.planted[1] != base_planted[1] ||
				(cur_t.hips_pos - get_global_position()).distance_to(base_hips_rel) > 0.01f;
		if (resp) {
			float ms = (tick - change_tick + 1) * 1000.0f / 60.0f; // +1: the pose is drawn the frame after the tick
			latency_last_ms = ms;
			latency_max_ms = std::max(latency_max_ms, ms);
			latency_sum_ms += ms;
			latency_count++;
			change_tick = -1;
		} else if (tick - change_tick > 60) {
			change_tick = -1;
		}
	}
}

void LabPlayer::reset_metrics() {
	if (poser) poser->reset_metrics();
	latency_max_ms = 0;
	latency_last_ms = -1;
	latency_sum_ms = 0;
	latency_count = 0;
	motor.steps_taken = 0;
}

Dictionary LabPlayer::get_metrics() const {
	Dictionary d;
	if (poser) {
		const LabPoser::Metrics &m = poser->metrics;
		d["slide_max_cm"] = m.slide_max_cm;
		d["hips_pop_max_cm"] = m.hips_pop_max_cm;
		d["joint_violations"] = m.joint_violations;
		d["knee_violations"] = m.knee_violations;
		d["ankle_violations"] = m.ankle_violations;
		d["hip_violations"] = m.hip_violations;
		d["elbow_violations"] = m.elbow_violations;
		d["knee_max_deg"] = m.knee_max_deg;
		d["ankle_up_max_deg"] = m.ankle_up_max_deg;
		d["ankle_down_max_deg"] = m.ankle_down_max_deg;
		d["hip_flex_max_deg"] = m.hip_flex_max_deg;
		d["hip_ext_max_deg"] = m.hip_ext_max_deg;
		d["elbow_max_deg"] = m.elbow_max_deg;
		d["frames"] = m.frames;
		d["slide_frame"] = m.slide_frame;
		d["slide_foot"] = m.slide_foot;
		d["slide_kind"] = m.slide_kind;
		d["pop_frame"] = m.pop_frame;
		d["joints"] = Vector3(m.cur_hip[0], m.cur_knee[0], m.cur_ankle[0]);
		d["joints_r"] = Vector3(m.cur_hip[1], m.cur_knee[1], m.cur_ankle[1]);
	}
	d["latency_max_ms"] = latency_max_ms;
	d["latency_last_ms"] = latency_last_ms;
	d["latency_avg_ms"] = latency_count > 0 ? latency_sum_ms / latency_count : -1.0f;
	d["steps"] = motor.steps_taken;
	d["gait"] = motor.gait;
	d["phase"] = motor.phase;
	d["active"] = motor.active;
	d["hips_y"] = cur_t.hips_pos.y - get_global_position().y;
	d["planted_l"] = cur_t.planted[0];
	d["planted_r"] = cur_t.planted[1];
	d["speed"] = flat(get_velocity()).length();
	d["yaw"] = motor.yaw;
	d["hips_rel"] = cur_t.hips_pos - get_global_position();
	d["contact_l"] = cur_t.contact[0];
	d["ankle_l"] = cur_t.ankle[0] - get_global_position();
	d["ankle_r"] = cur_t.ankle[1] - get_global_position();
	d["lean_deg"] = cur_t.body_lean / DEG;
	d["contact_r"] = cur_t.contact[1];
	return d;
}
