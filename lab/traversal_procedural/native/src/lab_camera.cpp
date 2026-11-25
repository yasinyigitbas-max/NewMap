// Lab A (procedural): camera. See lab_camera.h.
#include "lab_camera.h"
#include "labmath.h"

#include <godot_cpp/classes/collision_object3d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/input_event_key.hpp>
#include <godot_cpp/classes/input_event_mouse_button.hpp>
#include <godot_cpp/classes/input_event_mouse_motion.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;
using namespace lab;

void LabCamera::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_yaw"), &LabCamera::get_yaw);
	ClassDB::bind_method(D_METHOD("set_yaw", "y"), &LabCamera::set_yaw);
	ClassDB::bind_method(D_METHOD("snap"), &LabCamera::snap);
	ClassDB::bind_method(D_METHOD("set_target_path", "p"), &LabCamera::set_target_path);
	ClassDB::bind_method(D_METHOD("get_target_path"), &LabCamera::get_target_path);
	ClassDB::bind_method(D_METHOD("set_distance", "d"), &LabCamera::set_distance);
	ClassDB::bind_method(D_METHOD("get_distance"), &LabCamera::get_distance);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "target_path"), "set_target_path", "get_target_path");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "distance"), "set_distance", "get_distance");
}

void LabCamera::_ready() {
	set_physics_interpolation_mode(PHYSICS_INTERPOLATION_MODE_OFF); // moved every drawn frame from interpolated data
	if (Engine::get_singleton()->is_editor_hint()) return;
	target = Object::cast_to<Node3D>(get_node_or_null(target_path));
	for (int i = 0; i < get_child_count(); i++) {
		if (Camera3D *c = Object::cast_to<Camera3D>(get_child(i))) cam = c;
	}
	if (!cam) {
		cam = memnew(Camera3D);
		add_child(cam);
	}
	cam->set_physics_interpolation_mode(PHYSICS_INTERPOLATION_MODE_OFF);
	cam->set_current(true);
	cur_dist = dist;
}

void LabCamera::add_look(const Vector2 &d) {
	yaw = wrap_pi(yaw - d.x);
	pitch = clampf(pitch + d.y, -0.6f, 1.1f);
}

void LabCamera::snap() { have_pivot = false; }

void LabCamera::_unhandled_input(const Ref<InputEvent> &event) {
	Input *in = Input::get_singleton();
	Ref<InputEventMouseMotion> mm = event;
	if (mm.is_valid() && in->get_mouse_mode() == Input::MOUSE_MODE_CAPTURED) {
		add_look(mm->get_relative() * 0.0025f);
		return;
	}
	Ref<InputEventMouseButton> mb = event;
	if (mb.is_valid() && mb->is_pressed()) in->set_mouse_mode(Input::MOUSE_MODE_CAPTURED);
	Ref<InputEventKey> k = event;
	if (k.is_valid() && k->is_pressed() && k->get_keycode() == KEY_ESCAPE) in->set_mouse_mode(Input::MOUSE_MODE_VISIBLE);
}

void LabCamera::_process(double delta) {
	if (Engine::get_singleton()->is_editor_hint() || !target || !cam) return;
	float dt = (float)delta;
	Input *in = Input::get_singleton();
	Vector2 rs(in->get_action_strength("look_right") - in->get_action_strength("look_left"),
			in->get_action_strength("look_down") - in->get_action_strength("look_up"));
	if (rs.length() > 0.1f) add_look(rs * 2.5f * dt);
	Vector3 tp = target->get_global_transform_interpolated().origin;
	Vector3 fwd = yaw_fwd(yaw);
	Vector3 right = -yaw_left(yaw);
	Vector3 want = tp + Vector3(0, 1.55f, 0) + right * 0.35f; // behind the right shoulder
	if (!have_pivot) {
		pivot = want;
		have_pivot = true;
	}
	pivot = approach(pivot, want, 0.08f, dt); // eased, never cut
	Vector3 view = (fwd * std::cos(pitch) + Vector3(0, -std::sin(pitch), 0)).normalized();
	float d = dist;
	PhysicsDirectSpaceState3D *ss = get_world_3d()->get_direct_space_state();
	if (ss) {
		TypedArray<RID> ex;
		if (CollisionObject3D *co = Object::cast_to<CollisionObject3D>(target)) ex.push_back(co->get_rid());
		Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(pivot, pivot - view * (dist + 0.2f), lab::PROBE_MASK, ex);
		Dictionary hit = ss->intersect_ray(q);
		if (!hit.is_empty()) d = std::max(0.4f, pivot.distance_to(hit["position"]) - 0.2f);
	}
	cur_dist = d < cur_dist ? d : approach(cur_dist, d, 0.25f, dt); // in fast (walls), out slowly
	Vector3 cp = pivot - view * cur_dist;
	cam->set_global_position(cp);
	cam->look_at(cp + view, Vector3(0, 1, 0));
}
