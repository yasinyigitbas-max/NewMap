// EngineSound: a car's engine, made sample by sample from what the physical car does (B4, Yasin 20 Nov: "high quality
// car sounds with convincing shifts and higher gears"; standing rule: game systems in C++).
//  - No recorded loop is pitched up and down: every cylinder FIRES. Firing pulses at the engine's own rate
//    (rpm / 60 x cylinders / 2) ring two resonators - the exhaust note, tuned to follow the revs, and the pipe's boom -
//    and a burst of noise rings a third (the intake and exhaust rasp, louder under load). A V8's uneven firing order
//    (the burble), a diesel's knock, a high-revving engine's scream come from the firing pattern and the tunings per
//    model, not from separate samples.
//  - SHIFTS are heard because they happen in the car: the revs drop with the next gear (veh_dyn's gearbox, 5 to 7
//    gears), the pull is cut while the clutch is open (the note goes thin and quiet), and lifting off at high revs
//    crackles (a few random pops in the exhaust).
//  - Load (the pedal and the clutch) opens the tone (a low-pass that follows the throttle), and the whole engine is
//    louder under load and at high revs.
//  - Cost: one generator voice at 22,050 Hz, a few multiplies a sample (~370 samples a frame), on the main thread.
// Use: a child of a CityCar; it reads the car through CityCar::dyn(). CityCar makes one for the player's car.
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
	AudioStreamPlayer3D *pl = nullptr;
	float sr = 22050.0f;
	// the engine's character (by model)
	int cyl = 4; float pattern[8] = { 1, 1, 1, 1, 1, 1, 1, 1 }; float pipe_hz = 110.0f, note_mul = 2.0f, rasp_hz = 1400.0f, rasp = 0.35f, knock = 0.0f, gain = 1.0f;
	// running state
	double phase = 0.0; int fire_i = 0;
	float env = 0.0f, nenv = 0.0f, lp = 0.0f, lp_k = 0.2f, rpm_s = 800.0f, load_s = 0.0f, vol_s = 0.0f, last_gear = 1, pop_t = 0.0f;
	Reso note, pipe, rasp_r;
	uint32_t rng = 0x68e31da4u;
	float noise() { rng ^= rng << 13; rng ^= rng >> 17; rng ^= rng << 5; return (float)(rng & 0xffff) / 32768.0f - 1.0f; }
	void character(int p_model);
	void fill(AudioStreamGeneratorPlayback *p_pb, int p_n, float p_rpm, float p_load, float p_vol);
protected:
	static void _bind_methods();
public:
	float volume_db = 0.0f;
	void set_car(Object *p_car);
	void set_volume_db(double p_db) { volume_db = (float)p_db; }
	double get_volume_db() const { return volume_db; }
	void _ready() override;
	void _process(double p_delta) override;
};

} // namespace godot
