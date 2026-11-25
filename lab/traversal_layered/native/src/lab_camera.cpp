#include "lab_camera.h"
#include "inertial.h"

#include <godot_cpp/classes/display_server.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/input_event_mouse_button.hpp>
#include <godot_cpp/classes/input_event_mouse_motion.hpp>
#include <godot_cpp/classes/input_event_screen_drag.hpp>
#include <godot_cpp/classes/input_event_screen_touch.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

namespace lab {

void LabCamera::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_target_path", "p"), &LabCamera::set_target_path);
	ClassDB::bind_method(D_METHOD("get_target_path"), &LabCamera::get_target_path);
	ClassDB::bind_method(D_METHOD("get_view_yaw"), &LabCamera::get_view_yaw);
	ClassDB::bind_method(D_METHOD("set_view_yaw", "y"), &LabCamera::set_view_yaw);
	ClassDB::bind_method(D_METHOD("set_view_pitch", "p"), &LabCamera::set_view_pitch);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "target_path"), "set_target_path", "get_target_path");
}

void LabCamera::_ready() {
	set_physics_interpolation_mode(PHYSICS_INTERPOLATION_MODE_OFF); // posed every frame from the interpolated target
	set_as_top_level(true);
}

void LabCamera::_input(const Ref<InputEvent> &ev) {
	Ref<InputEventMouseButton> mb = ev;
	if (mb.is_valid() && mb->is_pressed() && DisplayServer::get_singleton()->is_touchscreen_available() == false) {
		Input::get_singleton()->set_mouse_mode(Input::MOUSE_MODE_CAPTURED);
	}
	Ref<InputEventMouseMotion> mm = ev;
	if (mm.is_valid() && Input::get_singleton()->get_mouse_mode() == Input::MOUSE_MODE_CAPTURED) {
		yaw -= mm->get_relative().x * 0.0035f;
		pitch = std::clamp(pitch - mm->get_relative().y * 0.0035f, -1.2f, 0.9f);
	}
	// touch: the right half of the screen looks
	const float half = get_viewport()->get_visible_rect().size.x * 0.5f;
	Ref<InputEventScreenTouch> st = ev;
	if (st.is_valid()) {
		if (st->is_pressed() && st->get_position().x >= half && touch_look_idx < 0) touch_look_idx = st->get_index();
		else if (!st->is_pressed() && st->get_index() == touch_look_idx) touch_look_idx = -1;
	}
	Ref<InputEventScreenDrag> sd = ev;
	if (sd.is_valid() && sd->get_index() == touch_look_idx) {
		yaw -= sd->get_relative().x * 0.006f;
		pitch = std::clamp(pitch - sd->get_relative().y * 0.006f, -1.2f, 0.9f);
	}
}

void LabCamera::_process(double delta) {
	const float dt = (float)delta;
	Input *in = Input::get_singleton();
	// right stick
	const float rx = in->get_joy_axis(0, JOY_AXIS_RIGHT_X), ry = in->get_joy_axis(0, JOY_AXIS_RIGHT_Y);
	if (std::fabs(rx) > 0.15f) yaw -= rx * 2.6f * dt;
	if (std::fabs(ry) > 0.15f) pitch = std::clamp(pitch - ry * 1.8f * dt, -1.2f, 0.9f);

	Node3D *t = Object::cast_to<Node3D>(get_node_or_null(target_path));
	if (!t) return;
	const Vector3 want = t->get_global_transform_interpolated().origin + Vector3(0, height, 0);
	if (!have_pivot) {
		pivot = want;
		have_pivot = true;
		// start behind the player, looking where he faces
		const Vector3 f = t->get_global_transform().basis.get_column(2);
		yaw = std::atan2(f.x, f.z) + 3.14159265f;
	}
	// eased follow (never cut): critically damped toward the target
	for (int k = 0; k < 3; k++) {
		float e = pivot[k] - want[k];
		float v = pivot_v[k];
		spring_decay(e, v, k == 1 ? 0.08f : 0.04f, dt);
		pivot[k] = want[k] + e;
		pivot_v[k] = v;
	}
	const Basis b = Basis(Vector3(0, 1, 0), yaw) * Basis(Vector3(1, 0, 0), pitch);
	const Vector3 back = b.xform(Vector3(0, 0, 1));
	const Vector3 right = b.xform(Vector3(1, 0, 0));
	const Vector3 base = pivot + right * shoulder;
	float d = distance;
	// pull in in front of walls (world only)
	Ref<World3D> w = get_world_3d();
	if (w.is_valid()) {
		PhysicsDirectSpaceState3D *ss = w->get_direct_space_state();
		Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(pivot, base + back * (distance + 0.3f), 1);
		Dictionary hit = ss->intersect_ray(q);
		if (!hit.is_empty()) {
			const Vector3 p = hit["position"];
			d = std::max(0.6f, p.distance_to(base) - 0.3f);
		}
	}
	cur_dist = d < cur_dist ? d : cur_dist + (d - cur_dist) * std::min(1.0f, dt * 4.0f);
	Transform3D tr;
	tr.basis = b;
	tr.origin = base + back * cur_dist;
	set_global_transform(tr);
}

} // namespace lab
