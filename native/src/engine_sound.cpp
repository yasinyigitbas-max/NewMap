// EngineSound: see engine_sound.h.
#include "engine_sound.h"
#include "city_car.h"
#include <godot_cpp/classes/audio_stream_generator.hpp>
#include <godot_cpp/classes/audio_stream_generator_playback.hpp>
#include <godot_cpp/classes/audio_stream_player3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <algorithm>
#include <cmath>

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

void EngineSound::set_car(Object *p_car) {
	car_id = p_car ? (uint64_t)p_car->get_instance_id() : 0;
	if (CityCar *c = Object::cast_to<CityCar>(p_car)) character(c->get_model());
}

void EngineSound::_ready() {
	Ref<AudioStreamGenerator> gen; gen.instantiate();
	gen->set_mix_rate(sr); gen->set_buffer_length(0.12f);
	pl = memnew(AudioStreamPlayer3D);
	pl->set_stream(gen);
	// B30 (Yasin, 20 Nov: "engine sound becomes unhearable when throttled a lot"): the chase camera trails further back the
	// faster the car goes (9.5 m + its follow lag, ~16 m at 200 km/h), and the 3D fall-off (unit size 6 m) and distance filter
	// made the player's own engine ~9 dB quieter and duller exactly at full throttle. His own car's engine: no fall-off,
	// no distance filter; it still pans with the car's place on screen.
	pl->set_attenuation_model(AudioStreamPlayer3D::ATTENUATION_DISABLED); pl->set_attenuation_filter_db(0.0f);
	pl->set_max_distance(0.0f);
	add_child(pl);
	pl->play();
	pipe.tune(pipe_hz, 2.0f, sr); rasp_r.tune(rasp_hz, 1.5f, sr);
	rng ^= (uint32_t)get_instance_id();
	set_process(true);
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
	CityCar *c = car_id ? Object::cast_to<CityCar>(ObjectDB::get_instance(ObjectID(car_id))) : nullptr;
	if (!c || !pl) return;
	Ref<AudioStreamGeneratorPlayback> pb = pl->get_stream_playback();
	if (pb.is_null()) { pl->play(); return; }
	const vd::Car &d = c->dyn();
	const float dt = (float)p_delta;
	const float rpm = std::max(d.rpm(), 300.0f);
	const float pedal = std::min(std::max(d.in.throttle, 0.0f), 1.0f);
	const float load = pedal * (d.shift_t > 0.0f ? 0.15f : 1.0f) * (0.4f + 0.6f * d.clutch);   // the pull cut while the clutch is open
	if (d.gear != (int)last_gear) { last_gear = (float)d.gear; if (rpm > 0.6f * d.s.rpm_red) pop_t = 0.25f; }   // a shift at high revs: a few pops
	if (pedal < 0.05f && load_s > 0.5f && rpm > 0.55f * d.s.rpm_red) pop_t = 0.6f;   // lifting off high: the overrun crackles
	rpm_s += (rpm - rpm_s) * std::min(1.0f, dt * 25.0f);
	load_s += (load - load_s) * std::min(1.0f, dt * (load > load_s ? 12.0f : 6.0f));
	const float vol = gain * (0.35f + 0.45f * load_s + 0.25f * std::min(rpm_s / d.s.rpm_red, 1.0f));
	vol_s += (vol - vol_s) * std::min(1.0f, dt * 10.0f);
	pl->set_volume_db(volume_db);
	const int n = pb->get_frames_available();
	if (n > 0) fill(pb.ptr(), n, rpm_s, load_s, vol_s * 0.5f);
}

void EngineSound::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_car", "car"), &EngineSound::set_car);
	ClassDB::bind_method(D_METHOD("set_volume_db", "db"), &EngineSound::set_volume_db);
	ClassDB::bind_method(D_METHOD("get_volume_db"), &EngineSound::get_volume_db);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "volume_db"), "set_volume_db", "get_volume_db");
}

} // namespace godot
