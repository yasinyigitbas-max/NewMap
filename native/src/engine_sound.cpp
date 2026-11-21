// EngineSound: see engine_sound.h.
#include "perf_marks.h"
#include "engine_sound.h"
#include "city_car.h"
#include "el_sfx.h"
#include <godot_cpp/classes/audio_stream_generator.hpp>
#include <godot_cpp/classes/audio_stream_generator_playback.hpp>
#include <godot_cpp/classes/audio_stream_player3d.hpp>
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <initializer_list>

namespace godot {

void EngineSound::Reso::tune(float f, float q, float s) {   // a two-pole resonator at f (Hz), its sharpness q
	const float w = 6.2831853f * std::min(f, 0.45f * s) / s;
	const float r = std::exp(-w / (2.0f * std::max(q, 0.5f)));
	a1 = 2.0f * r * std::cos(w); a2 = -r * r; g = (1.0f - r * r) * 0.5f;
}
float EngineSound::Reso::run(float x) { const float y = g * x + a1 * y1 + a2 * y2; y2 = y1; y1 = y; return y; }

// the engines, by car_models.h order: cylinders, firing pattern (the strength of each cylinder in turn: an even inline
// engine is even; a cross-plane V8 bunches its pulses and burbles), the pipe's boom, the note's tuning against the
// firing rate, the rasp's band and strength, a diesel's knock, loudness
void EngineSound::character(int m) {
	auto set = [&](int c, std::initializer_list<float> pat, float pipe, float nm, float rh, float ra, float kn, float gn) {
		cyl = c; int i = 0; for (float v : pat) { if (i < 8) pattern[i++] = v; }
		for (; i < 8; i++) pattern[i] = 1.0f;
		pipe_hz = pipe; note_mul = nm; rasp_hz = rh; rasp = ra; knock = kn; gain = gn;
	};
	switch (m) {
		case 0: set(6, { 1.0f, 0.92f, 1.04f, 0.95f, 1.02f, 0.9f }, 95.0f, 1.5f, 1200.0f, 0.30f, 0.0f, 1.0f); break;   // stern_e: a big saloon's V6
		case 1: set(4, { 1.0f, 0.96f, 1.02f, 0.94f }, 140.0f, 2.0f, 1800.0f, 0.42f, 0.0f, 0.85f); break;              // volt_s: a buzzy four
		case 2: set(6, { 1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f }, 105.0f, 1.5f, 1500.0f, 0.34f, 0.0f, 0.95f); break;     // stern_g: a smooth straight six
		case 3: set(4, { 1.0f, 0.95f, 1.03f, 0.95f }, 120.0f, 2.0f, 1600.0f, 0.38f, 0.0f, 0.9f); break;               // volt_x: a turbo four
		case 4: set(8, { 1.3f, 0.7f, 1.15f, 0.8f, 1.25f, 0.75f, 1.1f, 0.85f }, 70.0f, 1.0f, 900.0f, 0.30f, 0.0f, 1.15f); break;   // sakura_t: a pickup's lazy V8, the burble
		case 5: set(3, { 1.0f, 0.9f, 1.05f }, 150.0f, 2.0f, 1900.0f, 0.45f, 0.0f, 0.8f); break;                         // sakura: a little three
		case 6: set(6, { 1.0f, 0.9f, 1.05f, 0.92f, 1.0f, 0.88f }, 85.0f, 1.5f, 1100.0f, 0.32f, 0.0f, 1.0f); break;     // van: a V6
		case 7: set(8, { 1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f }, 160.0f, 2.0f, 2400.0f, 0.55f, 0.0f, 1.2f); break;      // fiamma_r: a flat-plane V8 that screams
		case 8: set(8, { 1.0f, 0.98f, 1.02f, 0.97f, 1.0f, 0.99f, 1.01f, 0.98f }, 120.0f, 1.5f, 2000.0f, 0.45f, 0.0f, 1.15f); break; // fiamma_gt: smooth and deep
		case 9: set(6, { 1.0f, 0.93f, 1.03f, 0.94f, 1.0f, 0.92f }, 95.0f, 1.5f, 1200.0f, 0.30f, 0.0f, 0.95f); break;   // taxi: a V6
		default: set(6, { 1.0f, 0.95f, 1.0f, 0.97f, 1.0f, 0.96f }, 60.0f, 1.0f, 700.0f, 0.25f, 0.55f, 1.25f); break;   // the buses: a diesel six, knocking
	}
}

namespace {

const int kCap = 10;
const int kTSlots = 6;
const char *kLayName[3] = { "EngIdle", "EngLow", "EngHigh" };
const char *kLaySuf[3] = { "engine_idle_", "engine_rev_low_", "engine_rev_high_" };

int g_frame = -1, g_left = kCap, g_loose_left = 4, g_player_left = 3;

void budget_begin() {
	Engine *e = Engine::get_singleton();
	const int f = e ? (int)e->get_process_frames() : 0;
	if (f == g_frame) return;
	g_frame = f;
	g_left = kCap;
	g_loose_left = 4;
	g_player_left = 3;
}

int budget_take(int p_want, bool p_player, bool p_loose) {
	budget_begin();
	if (p_want <= 0) return 0;
	int held = 0;
	if (!p_player) held += g_player_left;
	if (!p_loose && !p_player) held += g_loose_left;
	int cap = std::min(p_want, std::max(0, g_left - held));
	if (p_loose) cap = std::min(cap, g_loose_left);
	if (cap < 1) return 0;
	g_left -= cap;
	if (p_player) g_player_left = 0;
	if (p_loose) g_loose_left -= cap;
	return cap;
}

void blend_eq(float p_t, float p_load, float p_w[3]) {
	const float u = std::min(std::max(p_t + 0.18f * p_load, 0.0f), 1.0f);
	const float h = 1.57079632679f;
	if (u <= 0.30f) {
		const float x = u / 0.30f;
		p_w[0] = std::cos(x * h); p_w[1] = std::sin(x * h); p_w[2] = 0.0f;
	} else if (u <= 0.62f) {
		const float x = (u - 0.30f) / 0.32f;
		p_w[0] = 0.0f; p_w[1] = std::cos(x * h); p_w[2] = std::sin(x * h);
	} else {
		const float x = std::min((u - 0.62f) / 0.38f, 1.0f);
		p_w[0] = 0.0f; p_w[1] = std::cos(x * h); p_w[2] = std::sin(x * h);
	}
	for (int i = 0; i < 3; i++) p_w[i] = std::min(std::max(p_w[i], 0.0f), 1.0f);
}

float layer_pitch(int p_i, float p_t) {
	const float a = (p_i == 0) ? 0.0f : (p_i == 1) ? 0.05f : 0.45f;
	const float b = (p_i == 0) ? 0.30f : (p_i == 1) ? 0.70f : 1.00f;
	const float x = std::min(std::max((p_t - a) / (b - a), 0.0f), 1.0f);
	return 0.85f + 0.40f * x;
}

void mute_to(float p_w[3], int p_nlay) {
	if (p_nlay >= 3) return;
	if (p_nlay <= 0) { p_w[0] = p_w[1] = p_w[2] = 0.0f; return; }
	if (p_nlay == 1) {
		int k = 0;
		if (p_w[1] > p_w[k]) k = 1;
		if (p_w[2] > p_w[k]) k = 2;
		for (int i = 0; i < 3; i++) if (i != k) p_w[i] = 0.0f;
		return;
	}
	int drop = 0;
	if (p_w[1] < p_w[drop]) drop = 1;
	if (p_w[2] < p_w[drop]) drop = 2;
	p_w[drop] = 0.0f;
}

String layer_base(const String &p_cls, int p_i) {
	return String("res://audio/sfx/car/") + String(kLaySuf[p_i]) + p_cls + String("_");
}

bool class_complete(const String &p_cls) {
	return elsfx::set_size(layer_base(p_cls, 0), 0, 1, true) > 0
		&& elsfx::set_size(layer_base(p_cls, 1), 0, 1, true) > 0
		&& elsfx::set_size(layer_base(p_cls, 2), 0, 1, true) > 0;
}

void free_named(Node *p_o, const char *p_name) {
	if (!p_o) return;
	if (Node *n = p_o->get_node_or_null(NodePath(p_name))) n->queue_free();
}

void stop_named_layers(Node *p_o) {
	for (int i = 0; i < 3; i++) free_named(p_o, kLayName[i]);
}

int apply_layers(Node3D *p_owner, const String &p_cls, int p_take, float p_rpm, float p_idle, float p_red, float p_load,
		float p_dt, float *p_pitch, float *p_gain, int p_nlay, bool p_player, float p_range, float p_vol_db) {
	if (!p_owner || p_nlay <= 0) {
		if (p_owner) {
			for (int i = 0; i < 3; i++) {
				if (AudioStreamPlayer3D *a = Object::cast_to<AudioStreamPlayer3D>(p_owner->get_node_or_null(NodePath(kLayName[i])))) {
					if (a->is_playing()) a->stop();
				}
			}
		}
		if (p_gain) { p_gain[0] = p_gain[1] = p_gain[2] = 0.0f; }
		return 0;
	}
	const float t = (p_red > p_idle + 1.0f) ? std::min(std::max((p_rpm - p_idle) / (p_red - p_idle), 0.0f), 1.0f) : 0.0f;
	float w[3];
	blend_eq(t, p_load, w);
	mute_to(w, p_nlay);
	const float vol = 0.55f + 0.28f * std::min(std::max(p_load, 0.0f), 1.0f) + 0.22f * t;
	const float dt = std::max(p_dt, 0.0f);
	int voices = 0;
	for (int i = 0; i < 3; i++) {
		if (p_gain) p_gain[i] += (w[i] - p_gain[i]) * std::min(1.0f, dt * 10.0f);
		const float g = p_gain ? p_gain[i] : w[i];
		const float want_p = layer_pitch(i, t);
		if (p_pitch) p_pitch[i] += (want_p - p_pitch[i]) * std::min(1.0f, dt * 8.0f);
		const float p = p_pitch ? p_pitch[i] : want_p;
		const float db = (g * vol < 0.02f) ? -80.0f : p_vol_db + 20.0f * std::log10(std::max(g * vol, 1e-5f));
		AudioStreamPlayer3D *a = elsfx::loop(p_owner, String(kLayName[i]), layer_base(p_cls, i), db, p, p_range, p_take);
		if (db < -60.0f || !a) continue;
		voices++;
		if (p_player) {
			a->set_attenuation_model(AudioStreamPlayer3D::ATTENUATION_DISABLED);
			a->set_attenuation_filter_db(0.0f);
			a->set_max_distance(0.0f);
		}
	}
	return voices;
}

int lod_layers(float p_dist) {
	if (p_dist < 18.0f) return 3;
	if (p_dist < 35.0f) return 2;
	if (p_dist < 70.0f) return 1;
	return 0;
}

struct TSlot {
	Node3D *n = nullptr;
	int64_t key = 0;
	String cls;
	int take = 0;
	float pitch[3] = { 1, 1, 1 }, gain[3] = {};
};
// (made on first use: a String must not be built as a C++ static — it crashed the library at load)
TSlot *tslots = nullptr;
uint64_t t_host = 0;

void ensure_slots() {
	if (!tslots) tslots = new TSlot[kTSlots];
}

void reset_slots() {
	if (!tslots) return;
	for (int i = 0; i < kTSlots; i++) {
		if (tslots[i].n && tslots[i].n->is_inside_tree()) {
			stop_named_layers(tslots[i].n);
			tslots[i].n->queue_free();
		}
		tslots[i] = TSlot();
	}
	t_host = 0;
}

} // namespace

void EngineSound::set_car(Object *p_car) {
	car_id = p_car ? (uint64_t)p_car->get_instance_id() : 0;
	if (CityCar *c = Object::cast_to<CityCar>(p_car)) {
		character(c->get_model());
		const String nc = String(CityCar::engine_class_for(c->get_model()));
		if (nc != cls) {
			stop_layers();
			tried_samples = false;
			use_samples = false;
			cls = nc;
		}
	}
}

void EngineSound::set_sample_class(const String &p_cls) {
	if (p_cls == cls && tried_samples) return;
	stop_layers();
	cls = p_cls;
	tried_samples = false;
	use_samples = false;
	take = 0;
}

void EngineSound::ensure_synth() {
	if (pl) return;
	Ref<AudioStreamGenerator> gen;
	gen.instantiate();
	gen->set_mix_rate(sr);
	gen->set_buffer_length(0.12f);
	pl = memnew(AudioStreamPlayer3D);
	pl->set_stream(gen);
	// B30 (Yasin, 20 Nov: "engine sound becomes unhearable when throttled a lot"): the chase camera trails further back the
	// faster the car goes (9.5 m + its follow lag, ~16 m at 200 km/h), and the 3D fall-off (unit size 6 m) and distance filter
	// made the player's own engine ~9 dB quieter and duller exactly at full throttle. His own car's engine: no fall-off,
	// no distance filter; it still pans with the car's place on screen.
	pl->set_attenuation_model(AudioStreamPlayer3D::ATTENUATION_DISABLED);
	pl->set_attenuation_filter_db(0.0f);
	pl->set_max_distance(0.0f);
	add_child(pl);
	pl->play();
	pipe.tune(pipe_hz, 2.0f, sr);
	rasp_r.tune(rasp_hz, 1.5f, sr);
	rng ^= (uint32_t)get_instance_id();
}

void EngineSound::stop_synth() {
	if (!pl) return;
	pl->stop();
	pl->queue_free();
	pl = nullptr;
}

void EngineSound::stop_layers() {
	stop_named_layers(this);
	voices = 0;
	gain_w[0] = gain_w[1] = gain_w[2] = 0.0f;
}

bool EngineSound::try_samples() {
	if (tried_samples) return use_samples;
	tried_samples = true;
	if (cls.is_empty()) {
		CityCar *c = car_id ? Object::cast_to<CityCar>(ObjectDB::get_instance(ObjectID(car_id))) : nullptr;
		if (!c) { use_samples = false; return false; }
		cls = String(CityCar::engine_class_for(c->get_model()));
	}
	if (!class_complete(cls)) { use_samples = false; return false; }
	const int n = elsfx::set_size(layer_base(cls, 0), 0, 1, true);
	take = n > 0 ? (int)(UtilityFunctions::randi() % (uint32_t)n) : 0;
	use_samples = true;
	return true;
}

void EngineSound::maybe_blip(float p_pedal, float p_dt, bool p_player) {
	if (!p_player || !use_samples) return;
	blip_cd = std::max(0.0f, blip_cd - p_dt);
	const float jump = p_pedal - pedal_prev;
	const float rate = p_dt > 1.0e-4f ? jump / p_dt : 0.0f;
	pedal_prev = p_pedal;
	if (blip_cd > 0.0f) return;
	if (!((jump > 0.35f || rate > 2.5f) && p_pedal > 0.4f)) return;
	blip_cd = 0.8f + 0.4f * (float)UtilityFunctions::randf();
	const String base = String("res://audio/sfx/car/engine_rev_up_") + cls + String("_");
	Node *n = elsfx::play(this, base, volume_db - 2.0f, 0.04f, Vector3(), 40.0f);
	blips++;
	if (AudioStreamPlayer3D *a = Object::cast_to<AudioStreamPlayer3D>(n)) {
		a->set_attenuation_model(AudioStreamPlayer3D::ATTENUATION_DISABLED);
		a->set_attenuation_filter_db(0.0f);
		a->set_max_distance(0.0f);
	}
}

void EngineSound::_ready() { set_process(true); }

void EngineSound::_exit_tree() {
	stop_layers();
	stop_synth();
}

void EngineSound::fill(AudioStreamGeneratorPlayback *pb, int n, float rpm, float load, float vol) {
	const float fire_hz = rpm / 60.0f * (float)cyl * 0.5f;   // a four-stroke fires half its cylinders a turn
	note.tune(std::min(fire_hz * note_mul, 2400.0f), 3.0f + 2.0f * load, sr);
	lp_k = 0.08f + 0.5f * load + 0.12f * std::min(rpm / 7000.0f, 1.0f);   // the tone opens with the pedal
	const double step = (double)fire_hz / (double)sr;
	for (int i = 0; i < n; i++) {
		phase += step;
		float x = 0.0f;
		if (phase >= 1.0) {   // a cylinder fires
			phase -= 1.0;
			const float a = pattern[fire_i % cyl] * (0.85f + 0.3f * (0.5f + 0.5f * noise()));   // (no two combustions alike)
			fire_i++;
			env = a * (0.35f + 0.65f * load);
			nenv = a * (0.25f + 0.75f * load);
			if (knock > 0.0f) x += knock * a * (0.6f + 0.4f * load) * 2.0f;   // a diesel's hard edge
		}
		x += env;
		env *= 0.86f;                                    // the pulse dies away within a few milliseconds
		const float nz = noise() * nenv; nenv *= 0.93f;
		float y = note.run(x) * 3.0f + pipe.run(x) * 2.2f + rasp_r.run(nz) * rasp * (0.3f + load);
		if (pop_t > 0.0f) { pop_t -= 1.0f / sr; if (noise() > 0.995f) y += noise() * 1.6f; }   // crackles on the overrun
		lp += lp_k * (y - lp);
		const float o = std::tanh(lp * 1.4f) * vol;
		pb->push_frame(Vector2(o, o));
	}
}

void EngineSound::_process(double p_delta) {
	pm::Scope _pm(pm::ENGINE);   // (the slow-frame marks, perf_marks.h)
	CityCar *c = car_id ? Object::cast_to<CityCar>(ObjectDB::get_instance(ObjectID(car_id))) : nullptr;
	if (!c) return;
	const String nc = String(CityCar::engine_class_for(c->get_model()));
	if (nc != cls) {
		stop_layers();
		tried_samples = false;
		use_samples = false;
		cls = nc;
		character(c->get_model());
	}
	const bool player = c->get_player();
	const bool want = c->is_inside_tree() && c->is_visible() && (player || c->get_global_position().y > -20.0f);
	const float dt = (float)p_delta;
	if (!want) {
		running = false;
		on_t = 0.0f;
		pedal_prev = 0.0f;
		stop_layers();
		stop_synth();
		return;
	}
	if (player && !running) {
		on_t += dt;
		if (on_t < 0.7f) return;   // let engine_start be heard first
	}
	running = true;
	const vd::Car &d = c->dyn();
	const float rpm = std::max(d.rpm(), 300.0f);
	const float pedal = std::min(std::max(d.in.throttle, 0.0f), 1.0f);
	const float load = pedal * (d.shift_t > 0.0f ? 0.15f : 1.0f) * (0.4f + 0.6f * d.clutch);   // the pull cut while the clutch is open
	idle_rpm = d.s.rpm_idle;
	red_rpm = d.s.rpm_red;
	if (try_samples()) {
		stop_synth();
		float dist = 0.0f;
		if (!player) {
			dist = 25.0f;
			if (Viewport *vp = get_viewport()) {
				if (Camera3D *cam = vp->get_camera_3d()) dist = get_global_position().distance_to(cam->get_global_position());
			}
		}
		int nlay = player ? 3 : lod_layers(dist);
		nlay = budget_take(nlay, player, !player);
		n_layers = nlay;
		const float range = player ? 50.0f : 55.0f;
		voices = apply_layers(this, cls, take, rpm, idle_rpm, red_rpm, load, dt, pitch_s, gain_w, nlay, player, range, volume_db);
		maybe_blip(pedal, dt, player);
		return;
	}
	if (!player) {   // traffic / loose cars stay silent if the recorded files are missing
		stop_synth();
		return;
	}
	stop_layers();
	ensure_synth();
	if (!pl) return;
	Ref<AudioStreamGeneratorPlayback> pb = pl->get_stream_playback();
	if (pb.is_null()) { pl->play(); return; }
	if (d.gear != (int)last_gear) { last_gear = (float)d.gear; if (rpm > 0.6f * d.s.rpm_red) pop_t = 0.25f; }   // a shift at high revs: a few pops
	if (pedal < 0.05f && load_s > 0.5f && rpm > 0.55f * d.s.rpm_red) pop_t = 0.6f;   // lifting off high: the overrun crackles
	rpm_s += (rpm - rpm_s) * std::min(1.0f, dt * 25.0f);
	load_s += (load - load_s) * std::min(1.0f, dt * (load > load_s ? 12.0f : 6.0f));
	const float vol = gain * (0.35f + 0.45f * load_s + 0.25f * std::min(rpm_s / std::max(d.s.rpm_red, 1.0f), 1.0f));
	vol_s += (vol - vol_s) * std::min(1.0f, dt * 10.0f);
	pl->set_volume_db(volume_db);
	const int n = pb->get_frames_available();
	if (n > 0) fill(pb.ptr(), n, rpm_s, load_s, vol_s * 0.5f);
}

PackedFloat32Array EngineSound::get_layer_gains() const {
	PackedFloat32Array a;
	a.resize(3);
	a.set(0, gain_w[0]);
	a.set(1, gain_w[1]);
	a.set(2, gain_w[2]);
	return a;
}

PackedFloat32Array EngineSound::blend_gains(double p_rpm, double p_load) const {
	const float idle = idle_rpm > 1.0f ? idle_rpm : 800.0f;
	const float red = red_rpm > idle + 1.0f ? red_rpm : 6500.0f;
	const float t = std::min(std::max(((float)p_rpm - idle) / (red - idle), 0.0f), 1.0f);
	float w[3];
	blend_eq(t, (float)p_load, w);
	PackedFloat32Array a;
	a.resize(3);
	a.set(0, w[0]);
	a.set(1, w[1]);
	a.set(2, w[2]);
	return a;
}

void EngineSound::debug_drive(double p_rpm, double p_throttle, double p_dt) {
	running = true;
	idle_rpm = 800.0f;
	red_rpm = 6500.0f;
	if (!try_samples()) { voices = 0; return; }
	const float load = std::min(std::max((float)p_throttle, 0.0f), 1.0f);
	n_layers = 3;
	voices = apply_layers(this, cls, take, (float)p_rpm, idle_rpm, red_rpm, load, (float)p_dt, pitch_s, gain_w, 3, true, 50.0f, volume_db);
	maybe_blip(load, (float)p_dt, true);
}

void EngineSound::update_traffic(Node3D *p_host, const Vector3 &p_listen, const TrafCar *p_cars, int p_n, double p_dt) {
	if (!p_host || !p_host->is_inside_tree()) return;
	ensure_slots();
	const uint64_t hid = (uint64_t)p_host->get_instance_id();
	if (hid != t_host) {
		reset_slots();
		t_host = hid;
	}
	struct Cand { int i; float d; };
	Cand cands[48];
	int nc = 0;
	const int n = std::min(p_n, 48);
	for (int i = 0; i < n; i++) {
		const float d = p_cars[i].at.distance_to(p_listen);
		if (d < 70.0f && nc < 48) cands[nc++] = Cand{ i, d };
	}
	std::sort(cands, cands + nc, [](const Cand &a, const Cand &b) { return a.d < b.d; });
	bool used[kTSlots] = {};
	int assigned = 0;
	const float dt = p_dt > 0.0 ? (float)p_dt : 0.016f;
	for (int ci = 0; ci < nc && assigned < kTSlots; ci++) {
		const int nwant = lod_layers(cands[ci].d);
		const int nlay = budget_take(nwant, false, false);
		if (nlay <= 0) continue;
		const TrafCar &car = p_cars[cands[ci].i];
		int slot = -1;
		for (int s = 0; s < kTSlots; s++) if (tslots[s].n && tslots[s].key == car.key) { slot = s; break; }
		if (slot < 0) {
			for (int s = 0; s < kTSlots; s++) if (!tslots[s].n) { slot = s; break; }
		}
		if (slot < 0) {
			int worst = -1;
			float wd = -1.0f;
			for (int s = 0; s < kTSlots; s++) if (!used[s] && tslots[s].n) {
				const float d = tslots[s].n->get_global_position().distance_to(p_listen);
				if (d > wd) { wd = d; worst = s; }
			}
			if (worst < 0) continue;
			stop_named_layers(tslots[worst].n);
			tslots[worst].n->queue_free();
			tslots[worst] = TSlot();
			slot = worst;
		}
		used[slot] = true;
		assigned++;
		TSlot &s = tslots[slot];
		if (!s.n) {
			s.n = memnew(Node3D);
			s.n->set_name(String("TEng") + String::num_int64(slot));
			p_host->add_child(s.n);
		}
		const String ncls = String(CityCar::engine_class_for(car.model));
		if (s.key != car.key || s.cls != ncls) {
			stop_named_layers(s.n);
			s.key = car.key;
			s.cls = ncls;
			s.pitch[0] = s.pitch[1] = s.pitch[2] = 1.0f;
			s.gain[0] = s.gain[1] = s.gain[2] = 0.0f;
			if (!class_complete(ncls)) { s.take = 0; continue; }   // no synth for traffic
			const int ns = elsfx::set_size(layer_base(ncls, 0), 0, 1, true);
			s.take = ns > 0 ? (int)(UtilityFunctions::randi() % (uint32_t)ns) : 0;
		}
		s.n->set_global_position(car.at);
		const float u = std::min(std::max(car.speed / 28.0f, 0.0f), 1.0f);
		const float rpm = 800.0f + (6500.0f * 0.9f - 800.0f) * u;
		const float load = 0.25f + 0.50f * std::min(std::max(car.speed / 20.0f, 0.0f), 1.0f);
		apply_layers(s.n, s.cls, s.take, rpm, 800.0f, 6500.0f, load, dt, s.pitch, s.gain, nlay, false, 55.0f, 0.0f);
	}
	for (int s = 0; s < kTSlots; s++) if (!used[s] && tslots[s].n) {
		stop_named_layers(tslots[s].n);
		tslots[s].n->queue_free();
		tslots[s] = TSlot();
	}
}

void EngineSound::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_car", "car"), &EngineSound::set_car);
	ClassDB::bind_method(D_METHOD("set_volume_db", "db"), &EngineSound::set_volume_db);
	ClassDB::bind_method(D_METHOD("get_volume_db"), &EngineSound::get_volume_db);
	ClassDB::bind_method(D_METHOD("is_using_samples"), &EngineSound::is_using_samples);
	ClassDB::bind_method(D_METHOD("get_sample_class"), &EngineSound::get_sample_class);
	ClassDB::bind_method(D_METHOD("get_layer_voices"), &EngineSound::get_layer_voices);
	ClassDB::bind_method(D_METHOD("get_blip_count"), &EngineSound::get_blip_count);
	ClassDB::bind_method(D_METHOD("get_layer_gains"), &EngineSound::get_layer_gains);
	ClassDB::bind_method(D_METHOD("blend_gains", "rpm", "load"), &EngineSound::blend_gains);
	ClassDB::bind_method(D_METHOD("set_sample_class", "cls"), &EngineSound::set_sample_class);
	ClassDB::bind_method(D_METHOD("debug_drive", "rpm", "throttle", "dt"), &EngineSound::debug_drive);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "volume_db"), "set_volume_db", "get_volume_db");
}

} // namespace godot
