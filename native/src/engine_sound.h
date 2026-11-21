// EngineSound: a car's running engine (B4, then the recorded loops, 21 Nov: Yasin "no record the engine sounds").
//  - Recorded layers (eleven_text_to_sound_v3, audio/sfx/car/engine_{idle,rev_low,rev_high,rev_up}_<class>_0..1):
//    the class is the same as engine_start (CityCar::engine_class_for: compact / v6 / v8 / diesel / ev). One random
//    take for all three loops of a car. Equal-power crossfade idle -> low -> high by revs and the pedal; each layer
//    is pitch-shifted 0.85..1.25 so speed changes stay continuous. A sharp throttle-on plays engine_rev_up once.
//  - The player's car (no distance fall-off: B30, the chase camera) and the nearest few traffic cars get the full
//    three layers; further cars get low or idle only; the rest are silent. At most 10 loop voices (a Redmi Note).
//  - If the recorded files are missing, the old sample-by-sample generator is the fallback (the player's car only).
// Use: a child of a CityCar (made in CityCar::_process). CityTraffic::update_engine_layers drives the traffic cars.
#pragma once
#include <godot_cpp/classes/node3d.hpp>
#include <cstdint>

namespace godot {

class AudioStreamPlayer3D;
class AudioStreamGeneratorPlayback;
class CityCar;

class EngineSound : public Node3D {
	GDCLASS(EngineSound, Node3D)
	struct Reso { float a1 = 0, a2 = 0, g = 0, y1 = 0, y2 = 0; void tune(float f, float q, float sr); float run(float x); };
	uint64_t car_id = 0;
	AudioStreamPlayer3D *pl = nullptr;   // the synth generator (fallback only)
	float sr = 22050.0f;
	int cyl = 4; float pattern[8] = { 1, 1, 1, 1, 1, 1, 1, 1 }; float pipe_hz = 110.0f, note_mul = 2.0f, rasp_hz = 1400.0f, rasp = 0.35f, knock = 0.0f, gain = 1.0f;
	double phase = 0.0; int fire_i = 0;
	float env = 0.0f, nenv = 0.0f, lp = 0.0f, lp_k = 0.2f, rpm_s = 800.0f, load_s = 0.0f, vol_s = 0.0f, last_gear = 1, pop_t = 0.0f;
	Reso note, pipe, rasp_r;
	uint32_t rng = 0x68e31da4u;
	float noise() { rng ^= rng << 13; rng ^= rng >> 17; rng ^= rng << 5; return (float)(rng & 0xffff) / 32768.0f - 1.0f; }
	void character(int p_model);
	void fill(AudioStreamGeneratorPlayback *p_pb, int p_n, float p_rpm, float p_load, float p_vol);
	// recorded layers
	bool tried_samples = false, use_samples = false, running = false;
	String cls;
	int take = 0, n_layers = 0, blips = 0, voices = 0;
	float gain_w[3] = { 0, 0, 0 }, pitch_s[3] = { 1, 1, 1 }, pedal_prev = 0, blip_cd = 0, on_t = 0, idle_rpm = 800.0f, red_rpm = 6500.0f;
	void ensure_synth();
	void stop_synth();
	void stop_layers();
	bool try_samples();
	void maybe_blip(float p_pedal, float p_dt, bool p_player);
protected:
	static void _bind_methods();
public:
	float volume_db = 0.0f;
	void set_car(Object *p_car);
	void set_volume_db(double p_db) { volume_db = (float)p_db; }
	double get_volume_db() const { return volume_db; }
	bool is_using_samples() const { return use_samples && running; }
	String get_sample_class() const { return cls; }
	int get_layer_voices() const { return voices; }
	int get_blip_count() const { return blips; }
	PackedFloat32Array get_layer_gains() const;
	PackedFloat32Array blend_gains(double p_rpm, double p_load) const;
	void _ready() override;
	void _exit_tree() override;
	void _process(double p_delta) override;
	void set_sample_class(const String &p_cls);
	void debug_drive(double p_rpm, double p_throttle, double p_dt);
	struct TrafCar { Vector3 at; float speed; int model; int64_t key; };
	// the nearest moving traffic cars (CityTraffic::_process): already without hidden / bicycle rows.
	static void update_traffic(Node3D *p_host, const Vector3 &p_listen, const TrafCar *p_cars, int p_n, double p_dt);
};

} // namespace godot
