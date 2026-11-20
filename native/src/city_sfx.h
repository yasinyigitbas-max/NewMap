// The street's warning sounds (tools/city/audio/make_sfx.py writes them to audio/sfx/*.wav): a sound as the engine
// imported it, or the raw file when it was not imported (a fresh checkout, a test); looped or not.
#pragma once
#include <godot_cpp/classes/audio_stream.hpp>
#include <godot_cpp/classes/audio_stream_wav.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/resource_loader.hpp>

namespace godot {

inline Ref<AudioStream> city_sfx(const String &p_name, bool p_loop) {
	const String path = String("res://audio/sfx/") + p_name;
	Ref<AudioStreamWAV> w;
	if (ResourceLoader::get_singleton()->exists(path)) w = ResourceLoader::get_singleton()->load(path);
	if (w.is_null() && FileAccess::file_exists(path)) w = AudioStreamWAV::load_from_file(path);
	if (w.is_null()) return Ref<AudioStream>();
	if (p_loop && w->get_loop_mode() != AudioStreamWAV::LOOP_FORWARD) {
		const int64_t bytes = w->get_data().size();
		const int frames = (int)(bytes / 2);   // (16-bit mono)
		w->set_loop_mode(AudioStreamWAV::LOOP_FORWARD); w->set_loop_begin(0); w->set_loop_end(frames);
	}
	return w;
}

} // namespace godot
