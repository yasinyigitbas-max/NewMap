// The recorded sound sets (ElevenLabs takes, 20 Nov 2026; docs/AUDIO_EL_HOOKUPS.md): a set is the numbered files of one
// sound (".../door_wood_open_0.ogg" .. "_3.ogg"), one played at random and never the one played last (Yasin: "same
// grunt shouldnt play everytime"). One-shots go on a player that frees itself when done; loops stay on their own player.
#pragma once
#include <godot_cpp/classes/audio_stream.hpp>
#include <godot_cpp/classes/audio_stream_player.hpp>
#include <godot_cpp/classes/audio_stream_player3d.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/node3d.hpp>

namespace godot {
namespace elsfx {

// a set by its path without the number ("res://audio/sfx/car/car_door_open_"); p_first: its first number (0 or 1),
// p_width: the digits ("_000" sets: 3). Loaded once and kept. A loop set's streams loop.
int set_size(const String &p_base, int p_first = 0, int p_width = 1, bool p_loop = false);
Ref<AudioStream> pick(const String &p_base, int p_first = 0, int p_width = 1, bool p_loop = false);
// a one-shot at p_owner (a 3D node: there, local offset p_at; any other node: flat, as UI). Returns the player or null.
Node *play(Node *p_owner, const String &p_base, float p_db = 0.0f, float p_pitch_var = 0.04f, const Vector3 &p_at = Vector3(), float p_range = 40.0f, int p_first = 0, int p_width = 1);
// a looped sound kept on a named child player of p_owner (made on first use); p_db < -60 stops it
AudioStreamPlayer3D *loop(Node3D *p_owner, const String &p_name, const String &p_base, float p_db, float p_pitch = 1.0f, float p_range = 50.0f);
// the number of sounds played (the tests)
int played();

} // namespace elsfx
} // namespace godot
