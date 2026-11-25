// Lab B: the player. A CharacterBody3D (Jolt) moved by the locomotion core; owns input (keyboard, pad, touch) and
// feeds the pose layer. Layers per WORLD_CONTRACT (capsule layer 2, mask 1|4|8|16|32; probes 1|4|8).
#pragma once

#include "clip_library.h"
#include "loco.h"
#include "pose_layer.h"

#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>

namespace lab {

class LabCamera;

class LabPlayer : public godot::CharacterBody3D {
	GDCLASS(LabPlayer, godot::CharacterBody3D)

public:
	static const uint32_t PROBE_MASK = 1 | 4 | 8;          // contract 1
	static const uint32_t CAPSULE_MASK = 1 | 4 | 8 | 16 | 32;

	void _ready() override;
	void _physics_process(double delta) override;
	void _input(const godot::Ref<godot::InputEvent> &event) override;

	bool load_clips(const godot::String &cache_path);
	void set_camera_path(const godot::NodePath &p) { camera_path = p; }
	godot::NodePath get_camera_path() const { return camera_path; }

	// test harness
	void set_test_input(godot::Vector2 dir_world, float speed, bool active);
	void teleport(godot::Vector3 pos, float yaw);
	int get_mode() const { return (int)loco.mode; }
	godot::String get_clip() const { return godot::String(loco.clip_name); }
	float get_speed() const { return loco.velocity.length(); }
	float get_yaw() const { return loco.yaw; }
	float get_stride_scale() const { return loco.stride_scale; }
	float get_play_rate() const { return loco.play_rate; }
	int get_switches() const { return loco.switches; }
	bool get_contact(int side) const { return loco.contact[side]; }
	bool is_ready_to_play() const { return ready_ok; }
	godot::Object *get_pose_layer() const { return layer; }
	bool get_crouch() const { return crouch; }

	// touch tuning (brief: full stick at 80 px)
	float touch_full_px = 80.0f;

protected:
	static void _bind_methods();

private:
	godot::Ref<ClipLibrary> lib;
	Locomotion loco;
	PoseLayer *layer = nullptr;
	godot::Skeleton3D *skel = nullptr;
	godot::NodePath camera_path;
	LabCamera *cam = nullptr;
	bool ready_ok = false;

	// input
	bool test_active = false;
	godot::Vector2 test_dir;
	float test_speed = 0;
	bool crouch = false;
	bool jump_req = false;
	int touch_stick_idx = -1;
	godot::Vector2 touch_origin, touch_vec;
	float last_tap_time[2] = {-10, -10};
	godot::Vector2 last_tap_pos[2];

	void read_input(godot::Vector2 &dir_world, float &speed);
	void probe_ground();
};

} // namespace lab
