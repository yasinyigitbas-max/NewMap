// FootSteps: the sound of a figure's feet on what it walks on (B16, Yasin 20 Nov: "add footsteps to the game based on
// terrain"; standing rule: game systems in C++).
//  - WHEN: each foot bone of the watched CityPed is followed every frame; a step is the moment a foot comes down to its
//    own low mark (a running minimum of its height over the figure's feet, rising slowly so slopes and stairs keep up)
//    while the figure moves. Walking, running, stairs, the crowd's near bodies: the same rule, no clip tables.
//  - ON WHAT: the bake's surface-class map (far/ground_class.bin + .json, one byte every 2.5 m: hard, grass, sand,
//    dirt), loaded once for all FootSteps. (Decks and piers - wood - are not told apart yet: the bake gives every body
//    the same kind of name.)
//  - THE SOUNDS: audio/steps (Kenney, CC0), five of each kind, a random one each step, pitch and loudness varied a
//    little; louder when running. Two 3D players per figure, used in turn.
// Plain use: add as a child of the figure's owner, set_figure(ped). The test app (CityCrowd::set_player) gives the
// player one; near bodies of the crowd get theirs from the crowd, quieter.
#pragma once
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/audio_stream.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <cstdint>

namespace godot {

class AudioStreamPlayer3D;

class FootSteps : public Node3D {
	GDCLASS(FootSteps, Node3D)
public:
	enum { HARD = 0, GRASS, SAND, DIRT, WOOD, N_KINDS };
private:
	uint64_t fig_id = 0;
	int bone[2] = { -1, -1 };
	float low[2] = { 1e9f, 1e9f }, prev_h[2] = { 0, 0 };
	bool armed[2] = { false, false };
	double cool[2] = { 0, 0 };
	Vector3 last_pos; bool has_last = false;
	float speed = 0.0f;
	AudioStreamPlayer3D *pl[2] = { nullptr, nullptr };
	int next_pl = 0;
	float volume_db = -6.0f;
	int steps = 0, last_kind = -1;
	uint32_t rng = 0x9e3779b9u;
	// shared by every FootSteps of the run
	static PackedByteArray cls;
	static int cw, ch;
	static float cx0, cz0, ctex;
	static bool cls_tried;
	static Ref<AudioStream> snd[N_KINDS][5];
	static bool snd_tried;
	static void load_shared();
	float rnd() { rng ^= rng << 13; rng ^= rng >> 17; rng ^= rng << 5; return (float)(rng & 0xffffff) / 16777216.0f; }
	void step(int p_foot, const Vector3 &p_at);
protected:
	static void _bind_methods();
public:
	static int class_at(float p_x, float p_z);
	void set_figure(Object *p_ped);
	void set_volume_db(double p_db) { volume_db = (float)p_db; }
	double get_volume_db() const { return volume_db; }
	int get_steps() const { return steps; }
	int get_last_kind() const { return last_kind; }
	void _ready() override;
	void _process(double p_delta) override;
};

} // namespace godot
