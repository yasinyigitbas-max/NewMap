// CityTalk: talking to the people of the crowd, all C++ (the old game's npc_talk.gd, npc_talk_ui.gd and the part of
// voice.gd it used, rewritten). English practice at beginner level with a Turkish helper line; nothing is generated:
// every line is one of the old game's, filled with a place's name, a direction, walking minutes or the clock
// (map_dc/coronado/city_kit/traffic/talk.json, written by tools/city/traffic/make_talk.py).
//  - Anybody within 2 m of the player on foot can be spoken to (the Talk button, or the player's "interact").
//  - He may refuse (in a hurry; a group more often; at night and in rain more often; a jogger always), and then bears
//    a grudge for a day. Else he and his group stand still, he turns to the player and greets him.
//  - Three lines to choose from: a real place near by, the mission (or a hint: a job, food, sights), one small-talk
//    topic. The player taps a line and must SAY it: into the microphone where the phone's speech plugin is there
//    (three tries), else typed, or skipped.
//  - The answer is a caption (English and Turkish) and the recorded clip in a woman's or a man's voice, a templated
//    line as its clips one after the other (res://audio/npc/<f|m>/); a line that has no recording is a caption only.
//  - He remembers the player: "Hi again!" within ten game minutes, the grudge for 24 game hours.
//  - Walking 6 m away ends it; so does his being knocked over or leaving.
// The groups' own conversations (the crowd's event E_SAY) get their words, captions and voices here too.
// Everything on the screen is made here in code: a caption box, the choice buttons, the "say it" box.
#pragma once

#include <godot_cpp/classes/audio_stream.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/templates/hash_map.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <vector>

namespace godot {

class AudioStreamPlayer3D;
class Button;
class CanvasLayer;
class CityCrowd;
class Control;
class Label;
class LineEdit;
class PanelContainer;

class CityTalk : public Node {
	GDCLASS(CityTalk, Node)

public:
	enum { MAX_OPTS = 4, MAX_TRIES = 3 };

private:
	struct Opt { String id, kind, en, tr, place, hint; PackedStringArray accept; Vector2 goal; bool has_goal = false; };
	struct Conv { int zones = 0, kinds = 0; Array lines; };
	struct Mem { double busy_until = -1.0, met_until = -1.0; int met = 0; };

	String data_path = "res://map_dc/coronado/city_kit/traffic/talk.json";
	String clips_dir = "res://audio/npc/";
	uint64_t crowd_id = 0, player_id = 0;
	Dictionary data;
	bool loaded = false, ui_on = true, audio_on = true, need_say = true;
	std::vector<Conv> convs;
	// the talk in hand
	int active = -1;                 // the walker's id, -1 = nobody
	std::vector<int> held;           // he and his group, held still
	std::vector<Opt> options;
	PackedStringArray done;
	int selected = -1, tries = 0;
	bool saying = false, listening = false;
	String last_result;
	HashMap<uint32_t, Mem> memory;   // by who the walker is (his look), so the same person remembers
	double now_h = 0.0, hours_per_second = 0.0;
	// tests: fixed rolls (< 0 = roll)
	double force_roll = -1.0, force_cut = -1.0, force_refuse = -1.0, force_unknown = -1.0;
	String force_small;
	// the mission, or the hint when there is none
	String mission_en, mission_tr, hint = "HV";
	Vector3 mission_at; bool has_mission = false;
	// counts
	int n_talks = 0, n_lines = 0, n_voiced = 0, n_silent = 0, n_conv_lines = 0;
	uint32_t rng = 0x2f6b1d35u;
	// the voices
	AudioStreamPlayer3D *voice[2] = { nullptr, nullptr };    // [0] the one spoken to, [1] the groups' own talk
	std::vector<Ref<AudioStream>> queue[2];
	int voice_walker[2] = { -1, -1 };
	HashMap<String, Ref<AudioStream>> clips;
	// the screen
	CanvasLayer *layer = nullptr;
	Control *root = nullptr;
	PanelContainer *cap_panel = nullptr, *say_panel = nullptr;
	Control *opt_box = nullptr;
	Label *cap_who = nullptr, *cap_en = nullptr, *cap_tr = nullptr, *say_en = nullptr, *say_tr = nullptr, *say_status = nullptr;
	Button *talk_btn = nullptr, *opt_btn[MAX_OPTS + 1] = {}, *skip_btn = nullptr, *back_btn = nullptr;
	LineEdit *say_edit = nullptr;
	double cap_t = 0.0;
	int target = -1;                 // whom the Talk button would speak to now
	// the phone's speech plugin (singleton "GodotSpeech"), when the app has it: held by its id, never as a pointer. B1 (20 Nov):
	// on the phone the plugin's object was already freed when the world left the tree, and _exit_tree's is_connected on the
	// kept pointer locked its destroyed mutex: SIGABRT (review/phone/crash_20nov_0314/tombstone_19nov_*.txt, symbolised)
	uint64_t speech_id = 0;
	Object *speech_obj() const { return speech_id ? ObjectDB::get_instance(ObjectID(speech_id)) : nullptr; }

	CityCrowd *crowd_node() const;
	Vector3 player_pos() const;
	bool has_player() const;
	double randf();
	Dictionary pick(const Variant &p_arr);
	Dictionary sys(const char *p_key) const;
	Mem &mem_of(int p_row);
	static String fill(const String &p_s, const Dictionary &p_sub);
	static String slug(const String &p_en);
	static String normalize(const String &p_s);
	static bool heard(const String &p_said, const PackedStringArray &p_accept);
	static PackedStringArray segments(const String &p_tmpl, const Dictionary &p_sub);
	Ref<AudioStream> clip(const String &p_voice, const String &p_text);
	void speak(int p_ch, int p_row, const Dictionary &p_line, const Dictionary &p_sub);
	void say(int p_row, const Dictionary &p_line, const Dictionary &p_sub = Dictionary());
	void caption(const String &p_who, const String &p_en, const String &p_tr, double p_seconds);
	void start(int p_row);
	void offer(const std::vector<Opt> &p_items);
	Opt topic_item(const String &p_tid);
	Opt make_item(const String &p_id, const String &p_kind, const Dictionary &p_say, const Dictionary &p_sub);
	std::vector<Opt> three_items(int p_row);
	int nearest_place(const Vector2 &p_at, const char *const *p_kinds, bool p_unused_only, float *r_d) const;
	String dir_word(const Vector2 &p_d) const;
	void answer(const Opt &p_o);
	void answer_three(int p_row, const Opt &p_o);
	void answer_topic(int p_row, const String &p_tid);
	String doing(int p_row, Dictionary &r_sub) const;
	void said(bool p_ok, const String &p_how);
	void open_say();
	void close_say();
	void listen();
	void build_ui();
	void show_options();
	void freeze_player(bool p_on);
	void player_body(const char *p_method, const Variant &p_a, const Variant &p_b);
	void refuse(int p_row);
	int find_target() const;

protected:
	static void _bind_methods();

public:
	void _ready() override;
	void _exit_tree() override;
	void _process(double p_delta) override;
	void _input(const Ref<InputEvent> &p_event) override;

	void set_crowd(Object *p_crowd);
	void set_player(Object *p_player);
	bool load_data();
	// the talk
	String begin(int p_id);                   // "talk", "hi_again", "busy", "private", "jogger", "reject", "" (nobody there)
	String talk_to_nearest();                 // the Talk button / the player's "interact"
	void choose(int p_index);                 // the player picked a line (then he must say it)
	void say_typed(const String &p_text);     // ... typed it ("" = skipped)
	void back();                              // ... or goes back to the lines
	void end(const String &p_outcome);
	bool is_active() const { return active >= 0; }
	int get_active() const { return active; }
	Array get_options() const;
	Dictionary stats() const;
	// the mission the "can you help me" line is about (none: a hint, "HJ" a job, "HF" food, "HV" sights)
	void set_mission(const String &p_en, const String &p_tr, const Vector3 &p_at);
	void clear_mission() { has_mission = false; }
	void set_hint(const String &p_kind) { hint = p_kind; }
	// who remembers the player (for the game's save file)
	Dictionary get_memory() const;
	void set_memory(const Dictionary &p_m);
	void set_now_hours(double p_h) { now_h = p_h; }
	double get_now_hours() const { return now_h; }
	// signals' receivers
	void _on_crowd_event(int p_type, int p_id, int p_aux, double p_f);
	void _on_interact();
	void _on_option(int p_index);
	void _on_talk_pressed();
	void _on_skip();
	void _on_back();
	void _on_typed(const String &p_text);
	void _on_speech_result(const String &p_text, const PackedStringArray &p_alt);
	void _on_speech_error(int p_code, const String &p_msg);
	void _on_resize();

	void set_data_path(const String &p_p) { data_path = p_p; }
	String get_data_path() const { return data_path; }
	void set_clips_dir(const String &p_p) { clips_dir = p_p; }
	String get_clips_dir() const { return clips_dir; }
	void set_ui(bool p_on) { ui_on = p_on; }
	bool get_ui() const { return ui_on; }
	void set_audio(bool p_on) { audio_on = p_on; }
	bool get_audio() const { return audio_on; }
	void set_need_say(bool p_on) { need_say = p_on; }
	bool get_need_say() const { return need_say; }
	void set_hours_per_second(double p_r) { hours_per_second = p_r; }
	double get_hours_per_second() const { return hours_per_second; }
	void set_force(double p_roll, double p_cut, double p_refuse, double p_unknown, const String &p_small) { force_roll = p_roll; force_cut = p_cut; force_refuse = p_refuse; force_unknown = p_unknown; force_small = p_small; }
};

} // namespace godot
