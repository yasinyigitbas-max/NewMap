#include "el_sfx.h"
#include <godot_cpp/classes/audio_server.hpp>
#include <godot_cpp/classes/audio_stream_ogg_vorbis.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <string>
#include <unordered_map>
#include <vector>

namespace godot {
namespace elsfx {

namespace {
struct Set {
	std::vector<Ref<AudioStream>> v;
	int last = -1;
};
// (made on first use and never freed: no Godot object may be built or torn down as a static)
std::unordered_map<std::string, Set> *sets = nullptr;
int n_played = 0;

Set &get(const String &p_base, int p_first, int p_width, bool p_loop) {
	if (!sets) sets = new std::unordered_map<std::string, Set>();
	const std::string key = std::string(p_base.utf8().get_data());
	auto it = sets->find(key);
	if (it != sets->end()) return it->second;
	Set &s = (*sets)[key];
	ResourceLoader *rl = ResourceLoader::get_singleton();
	for (int n = p_first; n < p_first + 16; n++) {
		const String path = p_base + String::num_int64(n).pad_zeros(p_width) + String(".ogg");
		Ref<AudioStream> st;
		if (rl->exists(path)) st = rl->load(path);
		if (st.is_null() && FileAccess::file_exists(path)) st = AudioStreamOggVorbis::load_from_file(path);
		if (st.is_null()) break;
		Ref<AudioStreamOggVorbis> ogg = st;
		if (p_loop && ogg.is_valid()) ogg->set_loop(true);
		s.v.push_back(st);
	}
	return s;
}

StringName bus() {
	return AudioServer::get_singleton()->get_bus_index("SFX") >= 0 ? StringName("SFX") : StringName("Master");
}
} // namespace

int set_size(const String &p_base, int p_first, int p_width, bool p_loop) { return (int)get(p_base, p_first, p_width, p_loop).v.size(); }

Ref<AudioStream> pick(const String &p_base, int p_first, int p_width, bool p_loop) {
	Set &s = get(p_base, p_first, p_width, p_loop);
	if (s.v.empty()) return Ref<AudioStream>();
	const int n = (int)s.v.size();
	int i = (int)(UtilityFunctions::randi() % (uint32_t)n);
	if (n > 1 && i == s.last) i = (i + 1 + (int)(UtilityFunctions::randi() % (uint32_t)(n - 1))) % n;
	s.last = i;
	return s.v[i];
}

Node *play(Node *p_owner, const String &p_base, float p_db, float p_pitch_var, const Vector3 &p_at, float p_range, int p_first, int p_width) {
	if (!p_owner || !p_owner->is_inside_tree()) return nullptr;
	Ref<AudioStream> st = pick(p_base, p_first, p_width, false);
	if (st.is_null()) return nullptr;
	const float pitch = 1.0f + (float)UtilityFunctions::randf_range(-p_pitch_var, p_pitch_var);
	n_played++;
	if (Object::cast_to<Node3D>(p_owner)) {
		AudioStreamPlayer3D *a = memnew(AudioStreamPlayer3D);
		a->set_bus(bus()); a->set_stream(st); a->set_volume_db(p_db); a->set_pitch_scale(pitch);
		a->set_unit_size(std::max(1.0f, p_range * 0.12f)); a->set_max_distance(p_range);
		p_owner->add_child(a);
		a->set_position(p_at);
		a->connect("finished", Callable(a, "queue_free"));
		a->play();
		return a;
	}
	AudioStreamPlayer *a = memnew(AudioStreamPlayer);
	a->set_bus(bus()); a->set_stream(st); a->set_volume_db(p_db); a->set_pitch_scale(pitch);
	p_owner->add_child(a);
	a->connect("finished", Callable(a, "queue_free"));
	a->play();
	return a;
}

AudioStreamPlayer3D *loop(Node3D *p_owner, const String &p_name, const String &p_base, float p_db, float p_pitch, float p_range, int p_take) {
	if (!p_owner || !p_owner->is_inside_tree()) return nullptr;
	AudioStreamPlayer3D *a = Object::cast_to<AudioStreamPlayer3D>(p_owner->get_node_or_null(NodePath(p_name)));
	if (p_db < -60.0f) { if (a && a->is_playing()) a->stop(); return a; }
	if (!a) {
		Ref<AudioStream> st;
		if (p_take >= 0) {
			Set &s = get(p_base, 0, 1, true);
			if (p_take < (int)s.v.size()) st = s.v[p_take];
		} else st = pick(p_base, 0, 1, true);
		if (st.is_null()) return nullptr;
		a = memnew(AudioStreamPlayer3D);
		a->set_name(p_name); a->set_bus(bus()); a->set_stream(st);
		a->set_unit_size(std::max(1.0f, p_range * 0.12f)); a->set_max_distance(p_range);
		p_owner->add_child(a);
	}
	a->set_volume_db(p_db); a->set_pitch_scale(std::max(0.5f, std::min(p_pitch, 2.0f)));
	if (!a->is_playing()) { a->play(); n_played++; }
	return a;
}

int played() { return n_played; }

void clear() { if (sets) { delete sets; sets = nullptr; } }

} // namespace elsfx
} // namespace godot
