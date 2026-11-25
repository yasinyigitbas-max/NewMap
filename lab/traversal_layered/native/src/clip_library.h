// Lab B: the clip library. Reads the cache the clip build tool wrote (retargeted onto player_v3, measured), and
// samples poses and root motion. DECISIONS 1.x, 2.x.
#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/quaternion.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>

#include <string>
#include <unordered_map>
#include <vector>

namespace lab {

using godot::Quaternion;
using godot::Vector3;

// A full-body pose in the body's skeleton space: local rotations of every bone and the hips' position
// (skeleton units, relative to the clip's root frame).
struct Pose {
	std::vector<Quaternion> rot;
	Vector3 hips;
	void resize(int n) { rot.assign(n, Quaternion()); }
	int size() const { return (int)rot.size(); }
};

void pose_blend(const Pose &a, const Pose &b, float w, Pose &out); // out = a..b by w (slerp per bone)

struct RootSample {
	float x = 0, z = 0, yaw = 0; // clip root on the ground, metres / radians
};

struct Clip {
	std::string name;
	int frames = 0;
	float fps = 30;
	bool loop = false;
	std::vector<Quaternion> rot; // frames * bones
	std::vector<Vector3> hips;   // frames
	std::vector<RootSample> root;
	std::vector<uint8_t> contact[2];  // 0 left, 1 right
	std::vector<float> foot_h[2];
	// marks (frames, from the build tool; -1 = none)
	float cycle_a = -1, cycle_b = -1; // loops: left strike .. next left strike
	float move_a = -1;                // starts: first motion
	float exit_f = -1;                // starts: frame to hand over to the loop
	float exit_phase = 0;             // loop phase at exit_f
	float phase_f0 = 0;               // loops: frame of the left heel strike (phase 0)
	float entry_f = -1;               // stops / pivots: the frame the first planted foot strikes
	int entry_foot = -1;              // 0 left / 1 right
	float still_f = -1;               // stops: the frame the body is still
	float speed = 0, dist = 0, turn = 0;
	float cycle_dist = 0, cycle_time = 0; // loops

	float length() const { return (frames - 1) / fps; }
	RootSample root_at(float t) const;
	float root_dist_at(float t) const; // distance travelled along the root path from frame 0
	void sample(float t, int bones, Pose &out) const; // clamped, or wrapped inside the cycle for loops
	bool contact_at(int side, float t) const;
	float loop_frame(float phase) const; // loops: frame for a foot phase 0..1 (0 = left strike)
	bool contact_at_frame(int side, float f) const;
};

class ClipLibrary : public godot::RefCounted {
	GDCLASS(ClipLibrary, godot::RefCounted)

public:
	bool load_cache(const godot::String &path);
	int bone_count() const { return (int)bone_names.size(); }
	const Clip *get(const std::string &name) const;
	godot::PackedStringArray clip_names() const;
	bool has_clip(const godot::String &name) const { return get(name.utf8().get_data()) != nullptr; }
	float clip_length(const godot::String &name) const;

	std::vector<std::string> bone_names;
	std::unordered_map<std::string, Clip> clips;

protected:
	static void _bind_methods();
};

} // namespace lab
