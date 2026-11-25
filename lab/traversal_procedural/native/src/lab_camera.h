// Lab A (procedural): third-person camera behind the shoulder, ~3.4 m, eased, never cut, pulled in by walls (brief).
#pragma once

#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/classes/node3d.hpp>

namespace godot {

class LabCamera : public Node3D {
	GDCLASS(LabCamera, Node3D)

public:
	void _ready() override;
	void _process(double delta) override;
	void _unhandled_input(const Ref<InputEvent> &event) override;
	float get_yaw() const { return yaw; }
	void set_yaw(float y) { yaw = y; }
	void add_look(const Vector2 &d);
	void snap();
	void set_target_path(const NodePath &p) { target_path = p; }
	NodePath get_target_path() const { return target_path; }
	void set_distance(float d) { dist = d; }
	float get_distance() const { return dist; }

protected:
	static void _bind_methods();

private:
	NodePath target_path;
	Node3D *target = nullptr;
	Camera3D *cam = nullptr;
	float yaw = 0.0f, pitch = 0.25f, dist = 3.4f;
	float cur_dist = 3.4f;
	Vector3 pivot;
	bool have_pivot = false;
};

} // namespace godot
