// CityNative: the module's own face. Stage 1 of docs/TRAFFIC_PEOPLE_PORT.md: one small class that proves the module
// is built, packed and loaded on the PC and on the phone, and that the things the traffic and the crowd will stand on
// work inside it there: its own threads (never the engine's pool) and a steady clock.
#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class CityNative : public RefCounted {
	GDCLASS(CityNative, RefCounted)

protected:
	static void _bind_methods();

public:
	// "coronado_city <version> <debug|release> <platform> <arch>, godot-cpp <api>": printed by the test app at start
	static String version();
	// Starts p_threads threads of the module's own, each counts to p_count, joins them. Returns what happened:
	// ok (every thread ran and the sum is right), threads, ms (wall time), hw (hardware threads the system reports).
	static Dictionary self_test(int p_threads, int p_count);
};

} // namespace godot
