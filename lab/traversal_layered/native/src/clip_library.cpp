#include "clip_library.h"

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>

#include <cmath>

using namespace godot;

namespace lab {

void pose_blend(const Pose &a, const Pose &b, float w, Pose &out) {
	const int n = a.size();
	out.rot.resize(n);
	for (int i = 0; i < n; i++) {
		out.rot[i] = a.rot[i].slerp(b.rot[i], w);
	}
	out.hips = a.hips.lerp(b.hips, w);
}

static float wrap_cycle(const Clip &c, float f) {
	if (c.loop && c.cycle_b > c.cycle_a) {
		const float len = c.cycle_b - c.cycle_a;
		float x = std::fmod(f - c.cycle_a, len);
		if (x < 0) x += len;
		return c.cycle_a + x;
	}
	if (f < 0) return 0;
	if (f > c.frames - 1) return (float)(c.frames - 1);
	return f;
}

RootSample Clip::root_at(float t) const {
	const float f = std::fmin(std::fmax(t * fps, 0.0f), (float)(frames - 1));
	const int i0 = (int)std::floor(f);
	const int i1 = std::min(i0 + 1, frames - 1);
	const float w = f - i0;
	RootSample r;
	r.x = root[i0].x + (root[i1].x - root[i0].x) * w;
	r.z = root[i0].z + (root[i1].z - root[i0].z) * w;
	r.yaw = root[i0].yaw + (root[i1].yaw - root[i0].yaw) * w;
	return r;
}

float Clip::root_dist_at(float t) const {
	const float f = std::fmin(std::fmax(t * fps, 0.0f), (float)(frames - 1));
	const int i0 = (int)std::floor(f);
	float d = 0;
	for (int i = 1; i <= i0; i++) {
		d += std::hypot(root[i].x - root[i - 1].x, root[i].z - root[i - 1].z);
	}
	if (i0 + 1 < frames) {
		const float w = f - i0;
		d += w * std::hypot(root[i0 + 1].x - root[i0].x, root[i0 + 1].z - root[i0].z);
	}
	return d;
}

void Clip::sample(float t, int bones, Pose &out) const {
	const float f = wrap_cycle(*this, t * fps);
	int i0 = (int)std::floor(f);
	int i1 = i0 + 1;
	float w = f - i0;
	if (loop && cycle_b > cycle_a && i1 > (int)cycle_b) i1 = (int)cycle_a + 1;
	if (i1 > frames - 1) i1 = frames - 1;
	if (i0 > frames - 1) { i0 = frames - 1; w = 0; }
	out.rot.resize(bones);
	const Quaternion *a = &rot[(size_t)i0 * bones];
	const Quaternion *b = &rot[(size_t)i1 * bones];
	for (int i = 0; i < bones; i++) {
		out.rot[i] = a[i].slerp(b[i], w);
	}
	out.hips = hips[i0].lerp(hips[i1], w);
}

float Clip::loop_frame(float phase) const {
	const float len = (cycle_b > cycle_a) ? (cycle_b - cycle_a) : (float)(frames - 1);
	float p = phase - std::floor(phase);
	return wrap_cycle(*this, phase_f0 + p * len);
}

bool Clip::contact_at_frame(int side, float f) const {
	const float w = wrap_cycle(*this, f);
	const int i = std::min((int)std::lround(w), frames - 1);
	return contact[side][i] != 0;
}

bool Clip::contact_at(int side, float t) const {
	const float f = wrap_cycle(*this, t * fps);
	const int i = std::min((int)std::lround(f), frames - 1);
	return contact[side][i] != 0;
}

static float num(const Dictionary &d, const char *k, float def) {
	return d.has(k) ? (float)d[k] : def;
}

bool ClipLibrary::load_cache(const String &path) {
	Ref<FileAccess> f = FileAccess::open(path, FileAccess::READ);
	if (f.is_null()) {
		UtilityFunctions::push_error("ClipLibrary: cannot open ", path);
		return false;
	}
	Dictionary root = f->get_var();
	PackedStringArray bn = root.get("bones", PackedStringArray());
	bone_names.clear();
	for (int i = 0; i < bn.size(); i++) bone_names.push_back(bn[i].utf8().get_data());
	const int B = (int)bone_names.size();
	Dictionary cd = root.get("clips", Dictionary());
	Array keys = cd.keys();
	clips.clear();
	for (int k = 0; k < keys.size(); k++) {
		Dictionary d = cd[keys[k]];
		Clip c;
		c.name = String(keys[k]).utf8().get_data();
		c.frames = (int)d.get("frames", 0);
		c.fps = num(d, "fps", 30);
		c.loop = (bool)d.get("loop", false);
		PackedFloat32Array r = d["rot"];
		PackedFloat32Array h = d["hips"];
		PackedFloat32Array rt = d["root"];
		if (c.frames <= 0 || r.size() != c.frames * B * 4) {
			UtilityFunctions::push_error("ClipLibrary: bad clip ", keys[k]);
			continue;
		}
		c.rot.resize((size_t)c.frames * B);
		for (size_t i = 0; i < c.rot.size(); i++) {
			c.rot[i] = Quaternion(r[i * 4], r[i * 4 + 1], r[i * 4 + 2], r[i * 4 + 3]);
		}
		c.hips.resize(c.frames);
		c.root.resize(c.frames);
		for (int i = 0; i < c.frames; i++) {
			c.hips[i] = Vector3(h[i * 3], h[i * 3 + 1], h[i * 3 + 2]);
			c.root[i].x = rt[i * 3];
			c.root[i].z = rt[i * 3 + 1];
			c.root[i].yaw = rt[i * 3 + 2];
		}
		for (int s = 0; s < 2; s++) {
			PackedByteArray ca = d[s == 0 ? "contact_l" : "contact_r"];
			PackedFloat32Array fh = d[s == 0 ? "foot_h_l" : "foot_h_r"];
			c.contact[s].resize(c.frames);
			c.foot_h[s].resize(c.frames);
			for (int i = 0; i < c.frames; i++) {
				c.contact[s][i] = i < ca.size() ? ca[i] : 0;
				c.foot_h[s][i] = i < fh.size() ? fh[i] : 0.0f;
			}
		}
		c.cycle_a = num(d, "cycle_a", -1);
		c.cycle_b = num(d, "cycle_b", -1);
		c.move_a = num(d, "move_a", -1);
		c.exit_f = num(d, "exit_f", -1);
		c.exit_phase = num(d, "exit_phase", 0);
		c.phase_f0 = num(d, "phase_f0", 0);
		c.entry_f = num(d, "entry_f", -1);
		c.entry_foot = (int)num(d, "entry_foot", -1);
		c.still_f = num(d, "still_f", -1);
		c.speed = num(d, "speed", 0);
		c.dist = num(d, "dist", 0);
		c.turn = num(d, "turn", 0);
		c.cycle_dist = num(d, "cycle_dist", 0);
		c.cycle_time = num(d, "cycle_time", 0);
		clips[c.name] = std::move(c);
	}
	UtilityFunctions::print("ClipLibrary: ", (int)clips.size(), " clips, ", B, " bones");
	return !clips.empty();
}

const Clip *ClipLibrary::get(const std::string &name) const {
	auto it = clips.find(name);
	return it == clips.end() ? nullptr : &it->second;
}

PackedStringArray ClipLibrary::clip_names() const {
	PackedStringArray a;
	for (auto &kv : clips) a.push_back(String(kv.first.c_str()));
	return a;
}

float ClipLibrary::clip_length(const String &name) const {
	const Clip *c = get(name.utf8().get_data());
	return c ? c->length() : 0.0f;
}

void ClipLibrary::_bind_methods() {
	ClassDB::bind_method(D_METHOD("load_cache", "path"), &ClipLibrary::load_cache);
	ClassDB::bind_method(D_METHOD("clip_names"), &ClipLibrary::clip_names);
	ClassDB::bind_method(D_METHOD("has_clip", "name"), &ClipLibrary::has_clip);
	ClassDB::bind_method(D_METHOD("clip_length", "name"), &ClipLibrary::clip_length);
	ClassDB::bind_method(D_METHOD("bone_count"), &ClipLibrary::bone_count);
}

} // namespace lab
