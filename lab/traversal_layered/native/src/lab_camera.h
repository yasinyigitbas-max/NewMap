// Lab B: third-person camera behind the shoulder, ~3.4 m, eased, never cut (brief). Mouse, right stick, or a drag on
// the right half of the screen turns it.
#pragma once

#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/input_event.hpp>

namespace lab {

class LabCamera : public godot::Camera3D {
	GDCLASS(LabCamera, godot::Camera3D)

public:
	void _ready() override;
	void _process(double delta) override;
	void _input(const godot::Ref<godot::InputEvent> &event) override;

	void set_target_path(const godot::NodePath &p) { target_path = p; }
	godot::NodePath get_target_path() const { return target_path; }
	float get_view_yaw() const { return yaw; }
	void set_view_yaw(float y) { yaw = y; }
	void set_view_pitch(float p) { pitch = p; }

	float distance = 3.4f;
	float shoulder = 0.35f;
	float height = 1.55f;

protected:
	static void _bind_methods();

private:
	godot::NodePath target_path;
	float yaw = 0, pitch = -0.2f;
	godot::Vector3 pivot, pivot_v;
	bool have_pivot = false;
	float cur_dist = 3.4f;
	int touch_look_idx = -1;
};

} // namespace lab
