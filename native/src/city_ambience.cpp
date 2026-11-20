// CityAmbience: see city_ambience.h. Numbers from the old game's ambience.gd unless said.
#include "perf_marks.h"
#include "city_ambience.h"
#include "city_crowd.h"
#include "foot_steps.h"
#include <godot_cpp/classes/audio_stream_player.hpp>
#include <godot_cpp/classes/audio_stream_player3d.hpp>
#include <godot_cpp/classes/audio_stream_ogg_vorbis.hpp>
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <algorithm>
#include <cmath>

namespace godot {

static const char *DIR = "res://audio/amb/";
static const char *BED_FILE[CityAmbience::N_BEDS] = { "pacific_surf", "bay_lapping", "gulls_shore", "park_birds", "night_crickets", "wind", "traffic_far", "rain_loop" };
static const float BED_DB[CityAmbience::N_BEDS] = { -4.0f, -9.0f, -14.0f, -12.0f, -16.0f, -12.0f, -14.0f, -10.0f };
static const float RINGS[4] = { 25.0f, 70.0f, 150.0f, 260.0f };
// the sea map's extent (tools/city/look/sea_map.json): beyond it is open water
static float SX0 = -1800.0f, SZ0 = -1950.0f, SX1 = 1904.0f, SZ1 = 906.0f;
static bool sea_box_read = false;

static float lin_db(float g) { return 20.0f * std::log10(std::max(g, 0.0001f)); }
static float clamp01(float v) { return std::min(std::max(v, 0.0f), 1.0f); }
static float sstep(float a, float b, float x) { const float t = clamp01((x - a) / (b - a)); return t * t * (3.0f - 2.0f * t); }

bool CityAmbience::water(float x, float z) const {
	if (x < SX0 || z < SZ0 || x > SX1 || z > SZ1) return true;
	CityCrowd *c = crowd_id ? Object::cast_to<CityCrowd>(ObjectDB::get_instance(ObjectID(crowd_id))) : nullptr;
	return c && c->sea_depth(x, z) > 0.4f;
}

bool CityAmbience::pacific(float x, float z) const {   // no land toward the open ocean (south and south-west: +z, -x)
	static const float D[4] = { 400.0f, 900.0f, 1600.0f, 2500.0f };
	static const float V[2][2] = { { -0.6f, 0.8f }, { -0.2f, 1.0f } };
	for (float d : D) for (const auto &v : V) if (!water(x + v[0] * d, z + v[1] * d)) return false;
	return true;
}

void CityAmbience::sample(const Vector3 &p) {
	float ds = 9999.0f, db = 9999.0f; int n = 0, g = 0, h = 0;
	if (water(p.x, p.z)) { if (pacific(p.x, p.z)) ds = 0.0f; else db = 0.0f; }
	for (float r : RINGS)
		for (int i = 0; i < 8; i++) {
			const float a = 6.2831853f * (float)i / 8.0f + r * 0.01f;
			const float qx = p.x + std::cos(a) * r, qz = p.z + std::sin(a) * r;
			if (water(qx, qz)) { if (pacific(qx, qz)) ds = std::min(ds, r); else db = std::min(db, r); continue; }
			if (r <= 70.0f) {
				n++;
				const int k = FootSteps::class_at(qx, qz);
				if (k == FootSteps::GRASS) g++;
				else if (k == FootSteps::HARD) h++;
			}
		}
	near_sea = ds; near_bay = db;
	green = n ? (float)g / (float)n : 0.0f; hard = n ? (float)h / (float)n : 0.0f;
}

void CityAmbience::gains(double hour, float rain) {
	const float hr = (float)hour;
	const float day = clamp01(1.0f - std::fabs(hr - 13.0f) / 8.5f);
	const float night = 1.0f - sstep(0.0f, 1.0f, clamp01((std::fabs(hr - 12.5f) - 6.0f) * -0.7f + 1.0f));
	gain[SURF] = clamp01(1.0f - near_sea / 300.0f) * (1.0f + clamp01((wind_ms - 6.0f) / 12.0f));
	gain[BAY] = clamp01(1.0f - near_bay / 180.0f);
	gain[GULLS] = std::max(gain[SURF], gain[BAY]) * (0.25f + 0.75f * day) * (1.0f - rain * 0.8f);
	gain[BIRDS] = green * (0.1f + 0.9f * day) * (1.0f - night) * (1.0f - rain);
	gain[CRICKETS] = clamp01(green + 0.25f) * night * (1.0f - rain);
	gain[WIND] = clamp01((wind_ms - 2.0f) / 10.0f);
	const float rush = clamp01(std::max(1.0f - std::fabs(hr - 8.0f) / 2.0f, 1.0f - std::fabs(hr - 17.5f) / 2.5f));
	const float busy = std::min(std::max(0.15f + 0.6f * day + 0.35f * rush, 0.1f), 1.0f);
	gain[TRAFFIC] = (0.35f * clamp01(0.3f + 0.7f * day) + 0.6f * hard * busy) * (1.0f - rain * 0.3f);   // (hard ground round him stands in for the old game's road grid)
	gain[RAIN] = clamp01(rain);
	for (float &v : gain) v = clamp01(v);
}

void CityAmbience::_ready() {
	if (!sea_box_read) {
		sea_box_read = true;
		const Variant v = JSON::parse_string(FileAccess::get_file_as_string("res://tools/city/look/sea_map.json"));
		if (v.get_type() == Variant::DICTIONARY) {
			const Dictionary d = v;
			const float st = (float)(double)d.get("step", 8.0);
			SX0 = (float)(double)d.get("x0", SX0); SZ0 = (float)(double)d.get("z0", SZ0);
			SX1 = SX0 + st * (float)(int)d.get("w", 463); SZ1 = SZ0 + st * (float)(int)d.get("h", 357);
		}
	}
	ResourceLoader *rl = ResourceLoader::get_singleton();
	for (int k = 0; k < N_BEDS; k++) {
		bed[k] = memnew(AudioStreamPlayer);
		const String p = String(DIR) + BED_FILE[k] + ".ogg";
		if (rl->exists(p)) {
			Ref<AudioStream> st = rl->load(p);
			// B29 (Yasin, 20 Nov: "ambient sounds cut off a lot"): the beds' files are imported without looping, so each one
			// played to its end (20-60 s from its random start), fell silent and faded back in over ~5 s; a bed loops
			Ref<AudioStreamOggVorbis> ogg = st;
			if (ogg.is_valid()) ogg->set_loop(true);
			bed[k]->set_stream(st);
		}
		add_child(bed[k]);
	}
	for (int i = 0; i < 5; i++) { const String p = vformat("%sgull_call_%d.ogg", DIR, i + 1); if (rl->exists(p)) gull_s[i] = rl->load(p); }
	for (int i = 0; i < 2; i++) { const String p = vformat("%snavy_jet_flyover_%d.ogg", DIR, i + 1); if (rl->exists(p)) jet_s[i] = rl->load(p); }
	if (rl->exists(String(DIR) + "helicopter_flyover.ogg")) heli_s = rl->load(String(DIR) + "helicopter_flyover.ogg");
	gull = memnew(AudioStreamPlayer3D); gull->set_unit_size(8.0f); gull->set_max_distance(120.0f); add_child(gull);
	fly = memnew(AudioStreamPlayer3D); fly->set_unit_size(60.0f); fly->set_max_distance(2500.0f); add_child(fly);
	rng ^= (uint32_t)get_instance_id();
	set_process(true);
}

void CityAmbience::_process(double p_delta) {
	pm::Scope _pm(pm::AMBIENCE);   // (the slow-frame marks, perf_marks.h)
	const float dt = (float)p_delta;
	Viewport *vp = get_viewport();
	Camera3D *cam = vp ? vp->get_camera_3d() : nullptr;
	if (!cam || !cam->is_inside_tree()) return;
	const Vector3 p = cam->get_global_position();
	CityCrowd *c = crowd_id ? Object::cast_to<CityCrowd>(ObjectDB::get_instance(ObjectID(crowd_id))) : nullptr;
	const double hour = c ? c->get_hour() : 12.0;
	const float rain = c ? (float)c->get_rain() : 0.0f;
	sample_t -= p_delta;
	if (sample_t <= 0.0) { sample_t = 0.5; sample(p); gains(hour, rain); }
	for (int k = 0; k < N_BEDS; k++) {
		AudioStreamPlayer *b = bed[k];
		if (!b || b->get_stream().is_null()) continue;
		const float g = muted ? 0.0f : gain[k];
		float v = b->get_volume_db();
		if (g < 0.02f) {
			if (b->is_playing()) { v = std::max(v - dt * 20.0f, -60.0f); b->set_volume_db(v); if (v <= -59.0f) b->stop(); }
			continue;
		}
		const float tgt = master_db + BED_DB[k] + lin_db(g);
		if (!b->is_playing()) { b->set_volume_db(-60.0f); b->play(rnd() * std::max((float)b->get_stream()->get_length() - 1.0f, 0.0f)); v = -60.0f; }
		v = v < tgt ? std::min(v + dt * 12.0f, tgt) : std::max(v - dt * 12.0f, tgt);
		b->set_volume_db(v);
	}
	if (muted) { if (gull->is_playing()) gull->stop(); if (fly->is_playing()) { fly->stop(); fly_t = -1.0; } return; }
	// a gull now and then near the water
	next_gull -= p_delta;
	if (next_gull <= 0.0) {
		const float g = gain[GULLS];
		next_gull = (6.0 + 14.0 * rnd()) / std::max(g, 0.15f);
		const Ref<AudioStream> s = gull_s[(int)(rnd() * 4.999f)];
		if (g >= 0.1f && !gull->is_playing() && s.is_valid()) {
			const float a = rnd() * 6.2831853f;
			gull->set_stream(s);
			gull->set_global_position(p + Vector3(std::cos(a) * 30.0f, 8.0f + 17.0f * rnd(), std::sin(a) * 30.0f));
			gull->set_volume_db(master_db - 8.0f + lin_db(g)); gull->play();
		}
	}
	// a navy jet or a helicopter across the sky (by day, now and then)
	if (fly_t >= 0.0) {
		fly_t += p_delta;
		const float k = clamp01((float)(fly_t / std::max(fly_len, 1.0)));
		fly->set_global_position(fly_from.lerp(fly_to, k));
		if (k >= 1.0f || !fly->is_playing()) { fly_t = -1.0; fly->stop(); }
		return;
	}
	const double rate = (hour < 7.0 || hour > 22.0) ? 0.05 : 1.0;
	next_heli -= p_delta * rate; next_jet -= p_delta * rate;
	Ref<AudioStream> s;
	if (next_heli <= 0.0) { next_heli = 360.0 + 360.0 * rnd(); s = heli_s; }
	else if (next_jet <= 0.0) { next_jet = 900.0 + 900.0 * rnd(); s = jet_s[rnd() < 0.5f ? 0 : 1]; }
	if (s.is_valid()) {
		const float a = rnd() * 6.2831853f, alt = s == heli_s ? 120.0f : 450.0f, half = s == heli_s ? 700.0f : 2000.0f;
		const Vector3 dir(std::cos(a), 0.0f, std::sin(a));
		fly_from = p + Vector3(0, alt, 0) - dir * half; fly_to = p + Vector3(0, alt, 0) + dir * half;
		fly_len = s->get_length(); fly_t = 0.0;
		fly->set_stream(s); fly->set_global_position(fly_from); fly->set_volume_db(master_db - 2.0f); fly->play();
	}
}

Dictionary CityAmbience::get_state() const {
	Dictionary d;
	d["near_sea"] = near_sea; d["near_bay"] = near_bay; d["green"] = green; d["hard"] = hard;
	static const char *N[N_BEDS] = { "surf", "bay", "gulls", "birds", "crickets", "wind", "traffic", "rain" };
	for (int k = 0; k < N_BEDS; k++) d[N[k]] = gain[k];
	return d;
}

void CityAmbience::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_crowd", "crowd"), &CityAmbience::set_crowd);
	ClassDB::bind_method(D_METHOD("set_wind", "metres_a_second"), &CityAmbience::set_wind);
	ClassDB::bind_method(D_METHOD("set_muted", "muted"), &CityAmbience::set_muted);
	ClassDB::bind_method(D_METHOD("set_master_db", "db"), &CityAmbience::set_master_db);
	ClassDB::bind_method(D_METHOD("get_state"), &CityAmbience::get_state);
}

} // namespace godot
