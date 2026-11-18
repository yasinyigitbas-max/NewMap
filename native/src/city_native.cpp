// CityNative: see city_native.h
#include "city_native.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/version.hpp>

#include <atomic>
#include <chrono>
#include <cstdint>
#include <thread>
#include <vector>

#define CITY_NATIVE_VERSION "0.1"

namespace godot {

String CityNative::version() {
#if defined(DEBUG_ENABLED)
	const char *kind = "debug";
#else
	const char *kind = "release";
#endif
#if defined(ANDROID_ENABLED)
	const char *plat = "android";
#elif defined(WINDOWS_ENABLED)
	const char *plat = "windows";
#elif defined(LINUX_ENABLED)
	const char *plat = "linux";
#else
	const char *plat = "other";
#endif
#if defined(__aarch64__)
	const char *arch = "arm64";
#elif defined(__x86_64__) || defined(_M_X64)
	const char *arch = "x86_64";
#else
	const char *arch = "other";
#endif
	return vformat("coronado_city %s %s %s %s, godot-cpp %d.%d", CITY_NATIVE_VERSION, kind, plat, arch, GODOT_VERSION_MAJOR, GODOT_VERSION_MINOR);
}

Dictionary CityNative::self_test(int p_threads, int p_count) {
	const int nt = p_threads < 1 ? 1 : (p_threads > 16 ? 16 : p_threads);
	const int64_t cnt = p_count < 1 ? 1 : p_count;
	std::atomic<int64_t> sum{ 0 };
	std::atomic<int> ran{ 0 };
	const auto t0 = std::chrono::steady_clock::now();
	std::vector<std::thread> th;
	th.reserve(nt);
	for (int k = 0; k < nt; k++) {
		th.emplace_back([&sum, &ran, cnt, k]() {
			// a little real work per step (the generator the traffic core uses), so the loop is not folded away
			uint64_t s = 0x853c49e6748fea9bULL + (uint64_t)k;
			int64_t local = 0;
			for (int64_t i = 0; i < cnt; i++) {
				s ^= s >> 12; s ^= s << 25; s ^= s >> 27;
				local += 1 + (int64_t)((s * 0x2545F4914F6CDD1DULL) >> 63) * 0;
			}
			sum.fetch_add(local, std::memory_order_relaxed);
			ran.fetch_add(1, std::memory_order_relaxed);
		});
	}
	for (std::thread &t : th) t.join();
	const double ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
	Dictionary out;
	out["ok"] = ran.load() == nt && sum.load() == (int64_t)nt * cnt;
	out["threads"] = nt;
	out["ms"] = ms;
	out["hw"] = (int)std::thread::hardware_concurrency();
	return out;
}

void CityNative::_bind_methods() {
	ClassDB::bind_static_method("CityNative", D_METHOD("version"), &CityNative::version);
	ClassDB::bind_static_method("CityNative", D_METHOD("self_test", "threads", "count"), &CityNative::self_test);
}

} // namespace godot
