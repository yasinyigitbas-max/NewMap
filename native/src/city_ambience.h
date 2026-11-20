// CityAmbience: the sound of the place round the listener (B3, Yasin 20 Nov: "add ambient sounds based on zones";
// standing rule: game systems in C++). A port of the old game's world_fx/ambience.gd onto the new map.
//  - BEDS: looping sounds whose loudness follows the place, the hour and the weather: Pacific surf, bay lapping, gulls
//    on the shore, park birds (by day, near grass), crickets (by night), wind, the distant traffic hum (hard ground
//    round the listener, busier at rush hours), rain. A bed near silence is stopped (a phone runs few decoders).
//  - THE PLACE, sampled twice a second in rings round the listener (25, 70, 150, 260 m; 8 points each): water from the
//    crowd's sea map (CityCrowd::sea_depth) and which side it is (the Pacific: no land within 0.4 - 2.5 km to the south
//    and south-west, as the old game tested), grass and hard ground from the bake's surface classes
//    (FootSteps::class_at).
//  - ONE-SHOTS: a gull's call near the water every 6 - 20 s, a navy jet or a helicopter crossing the sky now and then
//    by day (3D sounds that move).
//  - The hour and the rain come from the crowd (CityCrowd: hour, rain); wind from set_wind. The street murmur is the
//    crowd's own (city_crowd_extra), not here.
#pragma once
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/audio_stream.hpp>
#include <cstdint>

namespace godot {

class AudioStreamPlayer;
class AudioStreamPlayer3D;

class CityAmbience : public Node {
	GDCLASS(CityAmbience, Node)
public:
	enum { SURF = 0, BAY, GULLS, BIRDS, CRICKETS, WIND, TRAFFIC, RAIN, N_BEDS };
private:
	uint64_t crowd_id = 0;
	AudioStreamPlayer *bed[N_BEDS] = {};
	float gain[N_BEDS] = {};
	float near_sea = 9999.0f, near_bay = 9999.0f, green = 0.0f, hard = 0.0f;
	double sample_t = 0.0, next_gull = 8.0, next_heli = 300.0, next_jet = 900.0, fly_t = -1.0, fly_len = 40.0;
	Vector3 fly_from, fly_to;
	AudioStreamPlayer3D *gull = nullptr, *fly = nullptr;
	Ref<AudioStream> gull_s[5], jet_s[2], heli_s;
	float wind_ms = 3.0f;
	float master_db = 0.0f;
	bool muted = false;
	uint32_t rng = 0x2545f491u;
	float rnd() { rng ^= rng << 13; rng ^= rng >> 17; rng ^= rng << 5; return (float)(rng & 0xffffff) / 16777216.0f; }
	bool water(float x, float z) const;
	bool pacific(float x, float z) const;
	void sample(const Vector3 &p);
	void gains(double hour, float rain);
	// THE ZONE BED (audio/amb/zone/zone_<name>_0.ogg, stereo loops; docs/AUDIO_EL_HOOKUPS.md): the place's own bed under the
	// others, from what the rings found (no zone map yet: beach by the Pacific, marina by the bay, parks on grass, downtown on
	// wide hard ground, homes elsewhere; hospital / campus / industrial wait for one), crossfaded in 3 s on a change
	AudioStreamPlayer *zone_pl[2] = {};
	int zone = -1, zone_cur = 0, zone_cand = -1;
	float zone_wait = 0.0f;   // (a new zone must hold 3 s: no flicker at its edge)
	int zone_of() const;
	void zone_bed(float dt);
public:
	int get_zone() const { return zone; }
private:
protected:
	static void _bind_methods();
public:
	void set_crowd(Object *p_crowd) { crowd_id = p_crowd ? (uint64_t)p_crowd->get_instance_id() : 0; }
	void set_wind(double p_ms) { wind_ms = (float)p_ms; }
	void set_muted(bool p_m) { muted = p_m; }
	void set_master_db(double p_db) { master_db = (float)p_db; }
	Dictionary get_state() const;
	void _ready() override;
	void _process(double p_delta) override;
};

} // namespace godot
