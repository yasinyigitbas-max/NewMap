#include "lab_player.h"
#include "lab_camera.h"

#include <godot_cpp/classes/display_server.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/input_event_key.hpp>
#include <godot_cpp/classes/input_event_screen_drag.hpp>
#include <godot_cpp/classes/input_event_screen_touch.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

namespace lab {

// speeds (study 2.1, 2.2; DECISIONS 3.2, 7.1)
static const float WALK_MIN = 1.0f, WALK_FULL = 1.55f; // the walk clip is 1.54 m/s on this body
static const float RUN_MIN = 2.7f, RUN_FULL = 4.2f, RUN_SHIFT = 4.6f;

void LabPlayer::_bind_methods() {
	ClassDB::bind_method(D_METHOD("load_clips", "cache_path"), &LabPlayer::load_clips);
	ClassDB::bind_method(D_METHOD("set_camera_path", "p"), &LabPlayer::set_camera_path);
	ClassDB::bind_method(D_METHOD("get_camera_path"), &LabPlayer::get_camera_path);
	ClassDB::bind_method(D_METHOD("teleport", "pos", "yaw"), &LabPlayer::teleport);
	ClassDB::bind_method(D_METHOD("set_test_input", "dir_world", "speed", "active"), &LabPlayer::set_test_input);
	ClassDB::bind_method(D_METHOD("get_mode"), &LabPlayer::get_mode);
	ClassDB::bind_method(D_METHOD("get_clip"), &LabPlayer::get_clip);
	ClassDB::bind_method(D_METHOD("get_speed"), &LabPlayer::get_speed);
	ClassDB::bind_method(D_METHOD("get_yaw"), &LabPlayer::get_yaw);
	ClassDB::bind_method(D_METHOD("get_stride_scale"), &LabPlayer::get_stride_scale);
	ClassDB::bind_method(D_METHOD("get_play_rate"), &LabPlayer::get_play_rate);
	ClassDB::bind_method(D_METHOD("get_switches"), &LabPlayer::get_switches);
	ClassDB::bind_method(D_METHOD("get_contact", "side"), &LabPlayer::get_contact);
	ClassDB::bind_method(D_METHOD("is_ready_to_play"), &LabPlayer::is_ready_to_play);
	ClassDB::bind_method(D_METHOD("get_pose_layer"), &LabPlayer::get_pose_layer);
	ClassDB::bind_method(D_METHOD("get_crouch"), &LabPlayer::get_crouch);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "camera_path"), "set_camera_path", "get_camera_path");
}

static Node *find_class(Node *n, const String &cls) {
	if (n->is_class(cls)) return n;
	for (int i = 0; i < n->get_child_count(); i++) {
		Node *r = find_class(n->get_child(i), cls);
		if (r) return r;
	}
	return nullptr;
}

void LabPlayer::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) return;
	set_collision_layer(2);
	set_collision_mask(CAPSULE_MASK);
	set_floor_snap_length(0.25f);
	set_floor_constant_speed_enabled(true);
	set_floor_max_angle((float)Math::deg_to_rad(46.0));
	skel = Object::cast_to<Skeleton3D>(find_class(this, "Skeleton3D"));
	if (skel) {
		layer = memnew(PoseLayer);
		layer->set_name("PoseLayer");
		skel->add_child(layer);
	}
	cam = Object::cast_to<LabCamera>(get_node_or_null(camera_path));
	if (FileAccess::file_exists("user://clip_cache/clips.bin")) load_clips("user://clip_cache/clips.bin");
	set_physics_process(true);
	set_process_input(true);
}

bool LabPlayer::load_clips(const String &path) {
	lib.instantiate();
	if (!lib->load_cache(path)) return false;
	ready_ok = loco.init(lib.ptr());
	if (ready_ok && layer) {
		layer->in.pose_prev = loco.pose;
		layer->in.pose_cur = loco.pose;
		layer->in.valid = true;
	}
	return ready_ok;
}

void LabPlayer::teleport(Vector3 pos, float yaw) {
	set_global_position(pos);
	set_velocity(Vector3());
	loco.yaw = yaw;
	loco.velocity = Vector2();
	set_global_basis(Basis(Vector3(0, 1, 0), yaw));
	reset_physics_interpolation();
	if (layer) layer->reset_lock();
}

void LabPlayer::set_test_input(Vector2 dir, float speed, bool active) {
	test_dir = dir;
	test_speed = speed;
	test_active = active;
}

void LabPlayer::_input(const Ref<InputEvent> &ev) {
	Ref<InputEventKey> k = ev;
	if (k.is_valid() && k->is_pressed() && !k->is_echo()) {
		if (k->get_physical_keycode() == KEY_C) crouch = !crouch;
		if (k->get_physical_keycode() == KEY_SPACE) jump_req = true;
		if (k->get_physical_keycode() == KEY_ESCAPE) Input::get_singleton()->set_mouse_mode(Input::MOUSE_MODE_VISIBLE);
	}
	// touch: the left half is a floating stick; a double tap on the left = crouch, on the right = jump (brief)
	const float half = get_viewport()->get_visible_rect().size.x * 0.5f;
	Ref<InputEventScreenTouch> st = ev;
	if (st.is_valid()) {
		const int side = st->get_position().x < half ? 0 : 1;
		if (st->is_pressed()) {
			const float now = (float)Time::get_singleton()->get_ticks_msec() / 1000.0f;
			if (now - last_tap_time[side] < 0.3f && st->get_position().distance_to(last_tap_pos[side]) < 60.0f) {
				if (side == 0) crouch = !crouch;
				else jump_req = true;
				last_tap_time[side] = -10;
			} else {
				last_tap_time[side] = now;
				last_tap_pos[side] = st->get_position();
			}
			if (side == 0 && touch_stick_idx < 0) {
				touch_stick_idx = st->get_index();
				touch_origin = st->get_position();
				touch_vec = Vector2();
			}
		} else if (st->get_index() == touch_stick_idx) {
			touch_stick_idx = -1;
			touch_vec = Vector2();
		}
	}
	Ref<InputEventScreenDrag> sd = ev;
	if (sd.is_valid() && sd->get_index() == touch_stick_idx) {
		Vector2 d = (sd->get_position() - touch_origin) / touch_full_px;
		if (d.length() > 1.0f) d = d.normalized();
		touch_vec = d;
	}
}

void LabPlayer::read_input(Vector2 &dir_world, float &speed) {
	if (test_active) {
		dir_world = test_dir;
		speed = test_speed;
		return;
	}
	Input *in = Input::get_singleton();
	// stick in screen terms: x right, y forward
	Vector2 st;
	bool keyboard = false;
	if (in->is_physical_key_pressed(KEY_W)) { st.y += 1; keyboard = true; }
	if (in->is_physical_key_pressed(KEY_S)) { st.y -= 1; keyboard = true; }
	if (in->is_physical_key_pressed(KEY_D)) { st.x += 1; keyboard = true; }
	if (in->is_physical_key_pressed(KEY_A)) { st.x -= 1; keyboard = true; }
	const bool shift = in->is_physical_key_pressed(KEY_SHIFT);
	float mag = 0;
	if (keyboard) {
		if (st.length() > 0) st = st.normalized();
		mag = st.length() > 0 ? (shift ? 1.0f : 0.5f) : 0.0f;
	} else {
		Vector2 pad(in->get_joy_axis(0, JOY_AXIS_LEFT_X), -in->get_joy_axis(0, JOY_AXIS_LEFT_Y));
		if (touch_stick_idx >= 0) pad = Vector2(touch_vec.x, -touch_vec.y);
		mag = std::min(1.0f, pad.length());
		if (mag < 0.18f) mag = 0;
		st = mag > 0 ? pad / pad.length() : Vector2();
	}
	// analogue: walk up to 0.6 of the throw, run beyond; Shift runs (brief controls; study 2.2 band skipped)
	if (mag <= 0) speed = 0;
	else if (shift) speed = RUN_SHIFT;
	else if (keyboard) speed = WALK_FULL;
	else if (mag < 0.6f) speed = WALK_MIN + (WALK_FULL - WALK_MIN) * (mag - 0.18f) / 0.42f;
	else speed = RUN_MIN + (RUN_FULL - RUN_MIN) * (mag - 0.6f) / 0.4f;
	const float cy = cam ? cam->get_view_yaw() : 0.0f;
	// camera looks along -Z of its basis: screen-forward is (-sin yaw, -cos yaw)
	const Vector2 fwd(-std::sin(cy), -std::cos(cy));
	const Vector2 right(std::cos(cy), -std::sin(cy));
	dir_world = (right * st.x + fwd * st.y);
	if (dir_world.length() > 0) dir_world = dir_world.normalized();
}

void LabPlayer::probe_ground() {
	if (!layer) return;
	PhysicsDirectSpaceState3D *ss = get_world_3d()->get_direct_space_state();
	for (int s = 0; s < 2; s++) {
		Vector3 f = layer->get_foot_world(s);
		if (f == Vector3()) f = get_global_position();
		const Vector3 from(f.x, get_global_position().y + 0.6f, f.z);
		Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(from, from - Vector3(0, 1.4f, 0), PROBE_MASK);
		q->set_exclude(TypedArray<RID>::make(get_rid()));
		Dictionary hit = ss->intersect_ray(q);
		if (!hit.is_empty()) {
			layer->in.ground_y[s] = ((Vector3)hit["position"]).y;
			layer->in.ground_n[s] = hit["normal"];
		} else {
			layer->in.ground_y[s] = get_global_position().y;
			layer->in.ground_n[s] = Vector3(0, 1, 0);
		}
	}
}

void LabPlayer::_physics_process(double delta) {
	if (!ready_ok) return;
	const float dt = (float)delta;
	Vector2 dir;
	float speed = 0;
	read_input(dir, speed);
	jump_req = false; // jump has no clip yet: refused cleanly (CLIPS_WANTED / step 6)

	loco.tick(dt, dir, speed);

	Vector3 v = get_velocity();
	v.x = loco.velocity.x;
	v.z = loco.velocity.y;
	if (is_on_floor()) v.y = std::min(v.y, 0.0f);
	v.y -= 9.81f * dt;
	set_velocity(v);
	move_and_slide();
	const Vector3 rv = get_real_velocity();
	loco.set_actual_velocity(Vector2(rv.x, rv.z));
	set_global_basis(Basis(Vector3(0, 1, 0), loco.yaw));

	if (layer) {
		probe_ground();
		LayerInput &li = layer->in;
		li.pose_prev = loco.pose_old;
		li.pose_cur = loco.pose;
		li.contact[0] = loco.contact[0];
		li.contact[1] = loco.contact[1];
		li.stride_scale = loco.stride_scale;
		li.vel_world = Vector3(loco.velocity.x, 0, loco.velocity.y);
		li.accel_long = loco.accel_long;
		li.accel_lat = loco.accel_lat;
		li.body_yaw = loco.yaw;
		li.head_yaw_target = loco.has_input ? loco.desired_yaw : loco.yaw;
		li.lean_enabled = loco.mode == Mode::LOOP ? 1 : 0;
	}
}

} // namespace lab
