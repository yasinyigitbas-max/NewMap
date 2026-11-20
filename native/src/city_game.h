// CityGame: the game's shell, all C++ (Yasin, 19 Nov: "HUD, minimap, the phone UI, menus, settings, loading screen,
// bring these over from the old game ... rewrite in c plus plus"; "saving and profiles"). The old game's autoloads
// I18n, GameState, GameSettings, SaveGame, Profiles, LoadingScreen, MainMenu, PauseMenu and GameOver in ONE node that
// lives on the root for the whole run (docs/GAME_PORT_BOARD.md; the spec of 19 Nov in docs/TRAFFIC_PEOPLE_PORT.md 37).
//
//  - TEXT: game/i18n/strings.txt (the old strings.csv: keys, en, tr; 1,818 rows) read once; English with the helper
//    language under it (en / helper / dual), %s and %d filled from the arguments.
//  - THE GAME'S STATE: the clock (one game hour = ten real minutes; day 1 = Saturday 24 Oct 2026), money, flags, the
//    player's voice.
//  - SETTINGS: the old keys and defaults; sound buses, language, graphics preset, camera; the per-phone ones (render
//    scale, colours, MSAA) in user://device_settings.json, the rest in the save slot's "sections.settings".
//  - SAVES: four slots, user://saves/slot_N.json, the old format (version 3), written to .tmp and renamed; an autosave
//    every 60 s while a slot is played. Profiles are the slots (name, created, last played).
//  - SCREENS, built with ui_plate: the loading screen (title, status, bar, a tip), the main menu (new game, continue,
//    lessons, settings, the slot picker with delete, credits, quit), pause (Esc / Android back), game over (retry /
//    rewind), the settings panel (sound, language, display, controls).
// The systems the old shell called that are not here yet (story, economy, needs, lessons, the phone) are left out of the
// save's "state" as empty sections, ready for them.
#pragma once

#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/canvas_layer.hpp>
#include <godot_cpp/classes/check_button.hpp>
#include <godot_cpp/classes/color_rect.hpp>
#include <godot_cpp/classes/h_slider.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/option_button.hpp>
#include <godot_cpp/classes/progress_bar.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/classes/texture_rect.hpp>
#include <godot_cpp/classes/v_box_container.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

#include <atomic>
#include <functional>
#include <map>
#include <string>
#include <vector>

namespace godot {

class CityGame : public Node {
	GDCLASS(CityGame, Node)

	static CityGame *one;          // the one that runs (the shell is one node for the whole run)

	// ---- text
	static std::map<std::string, std::pair<String, String>> strings;   // key -> (en, helper)
	static bool text_loaded;
	static void load_text();
	bool helper_on = true;
	String helper_locale = "tr";

	// ---- the game's state
	double hour = 9.0;
	int day = 1;
	double time_scale = 6.0;       // game seconds per real second
	bool clock_running = true;
	int money = 50;
	// the objective the HUD's arrow points to (none: it points north)
	bool objective_on = false; Vector3 objective_at;
	// the player's own targets on the phone's map (Yasin: "up to 3 targets should be routable and kept"): {x, z, name}, saved
	Array map_targets;
	Dictionary phone_data;         // the phone's contacts, messages, photos (CityPhone)
	// HEALTH AND NEEDS (Yasin: "integrate health and needs but keep them inactive for now"): kept and saved, never drained
	// while needs_active is off; the HUD's bars are hidden then
	float health = 1.0f, hunger = 1.0f, thirst = 1.0f, energy = 1.0f;
	bool needs_active = false;
	class CityHud *hud = nullptr;
	Dictionary flags;
	String voice = "f";

	// ---- settings
	Dictionary settings;           // the values now (defaults, the slot's, the phone's)
	void settings_defaults();
	void load_device();
	void save_device();
	void apply_settings();

	// ---- saves
	String saves_dir = "user://saves/";
	int active_slot = -1;
	double autosave_t = 0.0;
	double autosave_s = 60.0;
	Dictionary slot_sections;      // the active slot's "sections" (settings, checkpoints)
	uint64_t player_id = 0, crowd_id = 0, traffic_id = 0;
	uint64_t law_id = 0;            // the police, the ambulance, the crimes (CityLaw): made with the world
	void make_law();
	bool pending_new = false;        // a new game: set the player down at the start when the world gives him
	Dictionary pending_player;       // a loaded game: where he was, for when the world gives him
	Vector3 start_centre = Vector3(0, 0, -600);   // the city centre (Yasin: "start the player next to a bike and car in the city center")
	Dictionary start_info;
	void place_start();
	double start_hold = -1.0;        // held on the start spot until the ground's collision is under him (seconds held)
	Vector3 start_at; uint64_t start_bike = 0, start_car = 0;
	void hold_start(double p_delta);
	String slot_path(int s) const;
	Dictionary read_slot(int s) const;
	bool write_slot(int s, const Dictionary &d);
	Dictionary snapshot() const;
	void apply_snapshot(const Dictionary &st);

	// ---- screens
	CanvasLayer *loading = nullptr, *menu = nullptr, *pause = nullptr, *over = nullptr;
	ProgressBar *ld_bar = nullptr; Label *ld_status = nullptr;
	// THE SAVED GAME'S PICTURE (Yasin: "if there is a saved game, in the main menu, game should take a screenshot from the
	// game will load from, that screen should be shown on the loading menu and game should load into that scene directly,
	// seamlessly"; "if there isnt a saved game yet, that screen should have a black background"). Every save that happens
	// with nothing over the world (no menu, pause, game over or loading) also writes slot_N.jpg (640 wide) from the frame on
	// screen, with the player's place and view in the same save; the menu and the loading screen show it; the loaded game
	// stands the player there, looking the same way, and the loading screen fades off it into the live world.
	Control *ld_root = nullptr; TextureRect *ld_pic = nullptr;
	double ld_fade = -1.0;          // the loading screen fading out (seconds), -1 not fading
	int ld_slot = -1;               // the slot whose picture the loading screen shows (-1: black)
	double shot_ms = 0.0; int shots = 0;
	std::atomic<int> shot_busy{0};   // the picture being made 640 wide and written, on its own thread
	String shot_path(int s) const;
	bool take_shot();
	Ref<Texture2D> slot_picture(int s) const;
	std::map<std::string, Control *> screens;       // the main menu's screens
	VBoxContainer *menu_stack = nullptr;
	Control *menu_sheet = nullptr, *menu_bg_art = nullptr;
	ColorRect *menu_bg = nullptr;
	Button *b_continue = nullptr, *b_new = nullptr;
	Label *menu_notice = nullptr, *pause_note = nullptr, *over_title = nullptr, *over_reason = nullptr, *over_reason_tr = nullptr;
	Button *over_btn = nullptr;
	Control *pause_list = nullptr, *pause_settings = nullptr;
	VBoxContainer *picker_list = nullptr;
	Control *confirm = nullptr; Label *confirm_text = nullptr;
	std::function<void()> confirm_yes;
	bool picker_overwrite = false;
	bool menu_open = false, pause_open = false, over_open = false, was_paused = false;
	String rewind_to;
	struct SettingRow { String key; Control *ctl; int kind; };   // kind: 0 slider, 1 check, 2 option, 3 cycle
	std::vector<SettingRow> setting_rows;
	bool refreshing = false;
	void build_loading();
	void build_menu();
	void build_pause();
	void build_over();
	VBoxContainer *build_settings_panel(const std::function<void()> &on_back);
	void refresh_settings();
	void show_screen(const String &s);
	void fill_picker();
	void ask(const String &text, const std::function<void()> &yes);
	Button *menu_row(const String &key, const String &icon, bool chevron, const std::function<void()> &f);
	void on_any(Object *b, const std::function<void()> &f);   // a button's pressed signal -> a C++ function
	std::vector<std::function<void()>> actions;
	void _act(int p_i) { if (p_i >= 0 && p_i < (int)actions.size()) actions[p_i](); }
	void _setting_changed(const Variant &p_v, const String &p_key);

	// ---- going into the world
	String world_scene = "res://tools/city/rig/rig.tscn";
	int play_phase = 0;            // 0 none, 1 loading the scene, 2 waiting for it to settle
	double play_t = 0.0;
	int play_quiet = 0;
	std::function<int()> play_action;
	bool world_on = false;
	void enter_play(const std::function<int()> &action, int p_pic_slot = -1);
	void step_play(double p_delta);

protected:
	static void _bind_methods();

public:
	CityGame();
	~CityGame();
	static CityGame *get() { return one; }
	void _ready() override;
	void _process(double p_delta) override;
	void _unhandled_input(const Ref<InputEvent> &p_event) override;
	void _notification(int p_what);

	// ---- text (static: any C++ may ask; bound for tools and tests)
	static String en(const String &p_key, const Array &p_args = Array());
	static String helper(const String &p_key, const Array &p_args = Array());
	static String dual(const String &p_key, const Array &p_args = Array(), const String &p_sep = String::utf8("  ·  "));
	static String helper_text(const String &p_key);
	static bool has_text(const String &p_key);
	void set_helper_enabled(bool p_on);
	bool get_helper_enabled() const { return helper_on; }

	// ---- the game's state
	double get_hour() const { return hour; }
	int get_day() const { return day; }
	void set_time(double p_hour, int p_day);
	String hhmm() const;
	int get_money() const { return money; }
	void add_money(int p_amount);
	void set_flag(const String &p_key, const Variant &p_v);
	Variant get_flag(const String &p_key, const Variant &p_def = Variant()) const;
	void set_clock_running(bool p_on) { clock_running = p_on; }
	bool get_clock_running() const { return clock_running; }

	// ---- settings
	Variant get_setting(const String &p_key) const;
	void set_setting(const String &p_key, const Variant &p_v);
	Dictionary get_settings() const { return settings; }

	// ---- saves and profiles
	Array list_slots() const;
	int most_recent_slot() const;
	bool any_save() const;
	bool is_full() const;
	int create_slot(const String &p_name);
	bool delete_slot(int p_slot);
	bool rename_slot(int p_slot, const String &p_name);
	bool save();
	bool load_slot(int p_slot);
	bool has_save(int p_slot) const;
	int get_active_slot() const { return active_slot; }
	int new_game();
	int new_game_overwrite(int p_slot);
	int continue_game(int p_slot);
	void set_player(Object *p_player);
	// the world's crowd and traffic (the start is found on the crowd's pavements; the traffic is told of the car)
	void set_world(Object *p_crowd, Object *p_traffic);
	Dictionary get_start_info() const { return start_info; }
	// where the world should load first: the saved place (a loaded game) or the city centre (a new game)
	Vector3 world_start() const;
	void set_start_centre(const Vector3 &p_c) { start_centre = p_c; }
	Vector3 get_start_centre() const { return start_centre; }
	void set_saves_dir(const String &p_d) { saves_dir = p_d; }
	String get_saves_dir() const { return saves_dir; }
	void set_autosave_s(double p_s) { autosave_s = p_s; }
	double get_autosave_s() const { return autosave_s; }

	// ---- screens
	void open_menu();
	void close_menu();
	bool is_menu_open() const { return menu_open; }
	void open_pause();
	void close_pause();
	bool is_pause_open() const { return pause_open; }
	uint64_t get_player_id() const { return player_id; }
	uint64_t get_crowd_id() const { return crowd_id; }
	uint64_t get_traffic_id() const { return traffic_id; }
	Object *get_law() const;
	void set_objective(const Vector3 &p_at) { objective_on = true; objective_at = p_at; }
	void clear_objective() { objective_on = false; }
	bool get_objective_on() const { return objective_on; }
	Vector3 get_objective_at() const { return objective_at; }
	bool get_needs_active() const { return needs_active; }
	Array get_map_targets() const { return map_targets; }
	Dictionary get_phone_data() const { return phone_data; }
	void set_phone_data(const Dictionary &p_d) { phone_data = p_d; }
	VBoxContainer *make_settings_panel(const Callable &p_back) { return build_settings_panel([p_back]() { p_back.call(); }); }
	void set_map_targets(const Array &p_t) { map_targets = p_t; }
	void set_needs_active(bool p_on) { needs_active = p_on; }
	Object *get_hud() const;
	void game_over(const String &p_reason_en, const String &p_reason_tr, const String &p_title, const String &p_rewind);
	void retry();
	bool is_game_over() const { return over_open; }
	void open_loading();
	void set_loading(double p_p, const String &p_key);
	void close_loading();
	String current_screen() const;
	bool has_picture(int p_slot) const;
	bool menu_picture_shown() const { return menu_bg_art && menu_bg_art->is_visible() && menu_open; }
	bool loading_picture_shown() const { return loading && loading->is_visible() && ld_pic && ld_pic->get_texture().is_valid(); }
	bool is_loading_fading() const { return ld_fade >= 0.0; }
	double get_shot_ms() const { return shot_ms; }
	int get_shots() const { return shots; }
	bool is_shot_busy() const { return shot_busy.load() != 0; }
	// the tests press what a thumb would: a button by the text key it shows (on the screen that is open)
	bool press(const String &p_key);
	void set_world_scene(const String &p_s) { world_scene = p_s; }
	String get_world_scene() const { return world_scene; }
	bool is_playing() const { return world_on && play_phase == 0 && !menu_open; }
};

} // namespace godot
