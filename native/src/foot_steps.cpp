// FootSteps: see foot_steps.h.
#include "perf_marks.h"
#include "rig_names.h"
#include "foot_steps.h"
#include "el_sfx.h"
#include "city_ped.h"
#include <godot_cpp/classes/audio_stream_player3d.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <algorithm>
#include <cmath>

namespace godot {

std::vector<uint8_t> FootSteps::cls;
int FootSteps::cw = 0, FootSteps::ch = 0;
float FootSteps::cx0 = 0.0f, FootSteps::cz0 = 0.0f, FootSteps::ctex = 2.5f;
bool FootSteps::cls_tried = false;
Ref<AudioStream> (*FootSteps::snd)[5] = nullptr;
bool FootSteps::snd_tried = false;

static const char *RUNTIME = "res://map_dc/coronado/city_kit/runtime/far/";

void FootSteps::load_shared() {
	if (!cls_tried) {
		cls_tried = true;
		const String js = FileAccess::get_file_as_string(String(RUNTIME) + "ground_class.json");
		const Variant v = JSON::parse_string(js);
		if (v.get_type() == Variant::DICTIONARY) {
			const Dictionary d = v;
			cw = (int)d.get("w", 0); ch = (int)d.get("h", 0);
			cx0 = (float)(double)d.get("x0", 0.0); cz0 = (float)(double)d.get("z0", 0.0); ctex = (float)(double)d.get("texel", 2.5);
			const PackedByteArray b = FileAccess::get_file_as_bytes(String(RUNTIME) + "ground_class.bin");
			if (b.size() == cw * ch) cls.assign(b.ptr(), b.ptr() + b.size()); else { cls.clear(); cw = ch = 0; }
		}
	}
	if (!snd_tried) {
		snd_tried = true;
		snd = new Ref<AudioStream>[N_KINDS][5];
		static const char *NAME[N_KINDS] = { "concrete", "grass", "sand", "dirt", "wood" };
		ResourceLoader *rl = ResourceLoader::get_singleton();
		for (int k = 0; k < N_KINDS; k++)
			for (int i = 0; i < 5; i++) {
				const String p = vformat("res://audio/steps/footstep_%s_%03d.ogg", NAME[k], i);
				if (rl->exists(p)) snd[k][i] = rl->load(p);
			}
	}
}

int FootSteps::class_at(float p_x, float p_z) {
	if (cw <= 0 || cls.empty()) return HARD;
	const int x = (int)std::floor((p_x - cx0) / ctex), z = (int)std::floor((p_z - cz0) / ctex);
	if (x < 0 || z < 0 || x >= cw || z >= ch) return SAND;   // (off the picture: the beach and the sea's edge)
	return (int)cls[z * cw + x];
}

void FootSteps::set_figure(Object *p_ped) {
	fig_id = p_ped ? (uint64_t)p_ped->get_instance_id() : 0;
	bone[0] = bone[1] = -1; low[0] = low[1] = 1e9f; armed[0] = armed[1] = false; has_last = false;
}

void FootSteps::_ready() {
	load_shared();
	for (int k = 0; k < 2; k++) {
		pl[k] = memnew(AudioStreamPlayer3D);
		pl[k]->set_unit_size(3.0f); pl[k]->set_max_distance(30.0f);
		add_child(pl[k]);
	}
	if (own) set_own(true);      // (set before the node was in the tree)
	rng ^= (uint32_t)get_instance_id();
	set_process(true);
}

void FootSteps::_process(double p_delta) {
	pm::Scope _pm(pm::STEPS);   // (the slow-frame marks, perf_marks.h)
	CityPed *ped = fig_id ? Object::cast_to<CityPed>(ObjectDB::get_instance(ObjectID(fig_id))) : nullptr;
	if (!ped || !ped->is_inside_tree() || !ped->is_visible_in_tree()) return;
	Skeleton3D *sk = ped->skeleton();
	if (!sk) return;
	if (bone[0] < 0) { bone[0] = rig::find(sk, "Bip01_L_Foot"); bone[1] = rig::find(sk, "Bip01_R_Foot"); if (bone[0] < 0 || bone[1] < 0) return; }
	const Vector3 base = ped->get_global_position();
	if (has_last && p_delta > 0.0) {
		const Vector3 d = base - last_pos;
		speed += (Vector2(d.x, d.z).length() / (float)p_delta - speed) * (float)std::min(1.0, p_delta * 8.0);
	}
	last_pos = base; has_last = true;
	const Transform3D sx = sk->get_global_transform();
	for (int f = 0; f < 2; f++) {
		cool[f] -= p_delta;
		const Vector3 at = sx.xform(sk->get_bone_global_pose(bone[f]).origin);
		const float h = at.y - base.y;
		low[f] = std::min(low[f] + (float)p_delta * 0.25f, h);   // the low mark rises 25 cm a second (slopes, stairs)
		if (h > low[f] + 0.06f) armed[f] = true;                  // lifted: the next landing is a step
		const bool landed = armed[f] && h < low[f] + 0.025f && h <= prev_h[f];
		prev_h[f] = h;
		if (landed && cool[f] <= 0.0 && speed > 0.4f) { armed[f] = false; cool[f] = 0.16; step(f, at); }
	}
}

void FootSteps::step(int p_foot, const Vector3 &p_at) {
	int kind = class_at(p_at.x, p_at.z);
	last_kind = kind; steps++;
	int i = (int)(rnd() * 4.999f);
	if (i == last_i) i = (i + 1 + (int)(rnd() * 3.999f)) % 5;   // (never the same take twice running)
	last_i = i;
	if (!snd) return;
	Ref<AudioStream> s = snd[kind][i].is_valid() ? snd[kind][i] : snd[HARD][i];
	if (speed > 2.2f) {   // running (the jog is 2.8 m/s, the walk 1.05-1.4): the run takes (heavier, a scuff), the same surface
		static const char *RUN[N_KINDS] = { "concrete", "grass", "sand", "dirt", "wood" };
		Ref<AudioStream> r = elsfx::pick(String("res://audio/steps/footstep_run_") + String(RUN[kind]) + String("_"), 0, 3);
		if (r.is_valid()) { s = r; runs++; }
	}
	if (s.is_null() || !pl[next_pl]) return;
	AudioStreamPlayer3D *p = pl[next_pl]; next_pl ^= 1;
	p->set_global_position(p_at);
	p->set_stream(s);
	p->set_pitch_scale(0.92f + 0.16f * rnd());
	const float run = std::min(std::max((speed - 1.6f) / 2.5f, 0.0f), 1.0f);   // walking 1.4 m/s .. running 4+ m/s
	p->set_volume_db(volume_db - 6.0f + 6.0f * run + 2.0f * rnd());
	p->play();
	(void)p_foot;
}

void FootSteps::set_own(bool p_own) {
	own = p_own;
	if (own) volume_db = 2.0f;
	for (int k = 0; k < 2; k++) if (pl[k]) {
		pl[k]->set_attenuation_model(own ? AudioStreamPlayer3D::ATTENUATION_DISABLED : AudioStreamPlayer3D::ATTENUATION_INVERSE_DISTANCE);
		pl[k]->set_attenuation_filter_db(own ? 0.0f : -24.0f);
	}
}

void FootSteps::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_figure", "ped"), &FootSteps::set_figure);
	ClassDB::bind_method(D_METHOD("set_volume_db", "db"), &FootSteps::set_volume_db);
	ClassDB::bind_method(D_METHOD("set_own", "own"), &FootSteps::set_own);
	ClassDB::bind_method(D_METHOD("get_volume_db"), &FootSteps::get_volume_db);
	ClassDB::bind_method(D_METHOD("get_steps"), &FootSteps::get_steps);
	ClassDB::bind_method(D_METHOD("get_run_steps"), &FootSteps::get_run_steps);
	ClassDB::bind_method(D_METHOD("get_last_kind"), &FootSteps::get_last_kind);
	ClassDB::bind_static_method("FootSteps", D_METHOD("class_at", "x", "z"), &FootSteps::class_at);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "volume_db"), "set_volume_db", "get_volume_db");
}

} // namespace godot
