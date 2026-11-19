// CityGame: text, the game's state, settings and saves (see city_game.h). The screens are in city_game_ui.cpp.
#include "city_game.h"

#include <godot_cpp/classes/audio_server.hpp>
#include <godot_cpp/classes/dir_access.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/window.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <cmath>

namespace godot {

CityGame *CityGame::one = nullptr;
std::map<std::string, std::pair<String, String>> CityGame::strings;
bool CityGame::text_loaded = false;

namespace {
const int MAX_SLOTS = 4;
const char *const DEVICE_KEYS[] = { "pscale", "pcolors", "msaa" };
bool is_device_key(const String &k) { for (const char *d : DEVICE_KEYS) if (k == d) return true; return false; }
// One line of a CSV with quotes ("a, b" and "" inside quotes), from position i; it may run over line ends.
bool csv_row(const String &s, int64_t &i, PackedStringArray &out) {
	out.clear();
	const int64_t n = s.length();
	if (i >= n) return false;
	String cell; bool q = false;
	while (i < n) {
		const char32_t c = s[i];
		if (q) {
			if (c == '"') { if (i + 1 < n && s[i + 1] == '"') { cell += String::chr('"'); i += 2; continue; } q = false; i++; continue; }
			cell += String::chr(c); i++; continue;
		}
		if (c == '"') { q = true; i++; continue; }
		if (c == ',') { out.push_back(cell); cell = String(); i++; continue; }
		if (c == '\n' || c == '\r') { if (c == '\r' && i + 1 < n && s[i + 1] == '\n') i++; i++; break; }
		cell += String::chr(c); i++;
	}
	out.push_back(cell);
	return true;
}
String fill(String t, const Array &args) {
	if (args.is_empty()) return t;
	return t % args;
}
} // namespace

CityGame::CityGame() { if (!one) one = this; settings_defaults(); }
CityGame::~CityGame() { if (one == this) one = nullptr; }

// ---------------------------------------------------------------- text
void CityGame::load_text() {
	if (text_loaded) return;
	text_loaded = true;
	const String s = FileAccess::get_file_as_string("res://game/i18n/strings.txt");
	if (s.is_empty()) { UtilityFunctions::push_error("CityGame: no text (game/i18n/strings.txt)"); return; }
	int64_t i = 0;
	PackedStringArray row;
	int en = 1, tr = 2;
	if (csv_row(s, i, row)) for (int k = 0; k < row.size(); k++) { if (row[k] == "en") en = k; if (row[k] == "tr") tr = k; }
	while (csv_row(s, i, row)) {
		if (row.size() <= en || row[0].is_empty()) continue;
		strings[row[0].utf8().get_data()] = { row[en], row.size() > tr ? row[tr] : String() };
	}
}

bool CityGame::has_text(const String &p_key) { load_text(); return strings.count(p_key.utf8().get_data()) > 0; }

String CityGame::en(const String &p_key, const Array &p_args) {
	load_text();
	auto it = strings.find(p_key.utf8().get_data());
	if (it == strings.end() || it->second.first.is_empty()) return p_key;
	return fill(it->second.first, p_args);
}

String CityGame::helper(const String &p_key, const Array &p_args) {
	if (one && !one->helper_on) return String();
	load_text();
	auto it = strings.find(p_key.utf8().get_data());
	if (it == strings.end()) return String();
	return fill(it->second.second, p_args);
}

String CityGame::helper_text(const String &p_key) {
	load_text();
	auto it = strings.find(p_key.utf8().get_data());
	return it == strings.end() ? String() : it->second.second;
}

String CityGame::dual(const String &p_key, const Array &p_args, const String &p_sep) {
	const String a = en(p_key, p_args), b = helper(p_key, p_args);
	return b.is_empty() ? a : a + p_sep + b;
}

void CityGame::set_helper_enabled(bool p_on) {
	helper_on = p_on;
	settings["locale"] = p_on ? helper_locale : String("en");
	if (active_slot >= 0) { Dictionary sec = slot_sections.get("settings", Dictionary()); sec["locale"] = settings["locale"]; slot_sections["settings"] = sec; }
}

// ---------------------------------------------------------------- the game's state
void CityGame::set_time(double p_hour, int p_day) {
	hour = std::fmod(std::max(p_hour, 0.0), 24.0); day = std::max(p_day, 1);
	emit_signal("time_changed", hour);
}

String CityGame::hhmm() const {
	const int m = (int)std::floor(hour * 60.0 + 1e-6);
	return vformat("%02d:%02d", (m / 60) % 24, m % 60);
}

void CityGame::add_money(int p_amount) { money += p_amount; emit_signal("money_changed", money); }
void CityGame::set_flag(const String &p_key, const Variant &p_v) { flags[p_key] = p_v; }
Variant CityGame::get_flag(const String &p_key, const Variant &p_def) const { return flags.has(p_key) ? flags[p_key] : p_def; }

// ---------------------------------------------------------------- settings
void CityGame::settings_defaults() {
	settings = Dictionary();
	settings["master"] = 1.0; settings["music"] = 0.8; settings["voice"] = 1.0; settings["sfx"] = 0.9;
	settings["preset"] = "high"; settings["locale"] = "tr"; settings["cam_sens"] = 1.0; settings["invert_y"] = false;
	settings["touch_scale"] = 1.0; settings["pscale"] = 0.5; settings["pcolors"] = 0; settings["msaa"] = "auto"; settings["battery_saver"] = false;
}

void CityGame::load_device() {
	const String s = FileAccess::get_file_as_string("user://device_settings.json");
	if (s.is_empty()) return;
	const Variant v = JSON::parse_string(s);
	if (v.get_type() != Variant::DICTIONARY) return;
	const Dictionary d = v;
	for (const char *k : DEVICE_KEYS) if (d.has(k)) settings[k] = d[k];
	if ((int)d.get("gfx_rev", 0) < 2) { settings["pscale"] = 0.5; save_device(); }
}

void CityGame::save_device() {
	Dictionary d;
	d["gfx_rev"] = 2;
	for (const char *k : DEVICE_KEYS) d[k] = settings[k];
	Ref<FileAccess> f = FileAccess::open("user://device_settings.json", FileAccess::WRITE);
	if (f.is_valid()) f->store_string(JSON::stringify(d, "\t"));
}

Variant CityGame::get_setting(const String &p_key) const { return settings.get(p_key, Variant()); }

void CityGame::set_setting(const String &p_key, const Variant &p_v) {
	settings[p_key] = p_v;
	if (is_device_key(p_key)) save_device();
	else if (active_slot >= 0) {   // (kept in the slot at once, not only at the next save: a setting sticks when it is changed)
		Dictionary sec = slot_sections.get("settings", Dictionary()); sec[p_key] = p_v; slot_sections["settings"] = sec;
		Dictionary d = read_slot(active_slot);
		if (!d.is_empty()) { d["sections"] = slot_sections; write_slot(active_slot, d); }
	}
	if (p_key == "locale") helper_on = String(p_v).substr(0, 2) != "en";
	apply_settings();
	emit_signal("setting_changed", p_key);
}

// The sound buses (made if missing), the language, MSAA; the graphics preset and the render scale are kept for the
// city's own systems to read (the streamer, the pixel look): nothing here walks the scene tree.
void CityGame::apply_settings() {
	AudioServer *as = AudioServer::get_singleton();
	const char *buses[4] = { "Master", "Music", "Voice", "SFX" };
	const char *keys[4] = { "master", "music", "voice", "sfx" };
	for (int k = 0; k < 4; k++) {
		int b = as->get_bus_index(buses[k]);
		if (b < 0) { as->add_bus(); b = as->get_bus_count() - 1; as->set_bus_name(b, buses[k]); as->set_bus_send(b, "Master"); }
		const double v = std::max((double)settings.get(keys[k], 1.0), 1e-4);
		as->set_bus_volume_db(b, (float)(20.0 * std::log10(v)));
	}
	helper_on = String(settings.get("locale", "tr")).substr(0, 2) != "en";
	if (is_inside_tree()) {
		Viewport *vp = get_viewport();
		const String m = settings.get("msaa", "auto");
		const String pre = settings.get("preset", "high");
		const bool want = pre != "low";
		if (vp) vp->set_msaa_3d((m == "off" || (m == "auto" && !want) || (m == "on" && !want)) ? Viewport::MSAA_DISABLED : Viewport::MSAA_2X);
	}
	emit_signal("settings_applied");
}

// ---------------------------------------------------------------- saves
String CityGame::slot_path(int s) const { return saves_dir + vformat("slot_%d.json", s); }

Dictionary CityGame::read_slot(int s) const {
	if (s < 0 || s >= MAX_SLOTS) return Dictionary();
	const String t = FileAccess::get_file_as_string(slot_path(s));
	if (t.is_empty()) return Dictionary();
	const Variant v = JSON::parse_string(t);
	return v.get_type() == Variant::DICTIONARY ? (Dictionary)v : Dictionary();
}

bool CityGame::write_slot(int s, const Dictionary &d) {
	if (s < 0 || s >= MAX_SLOTS) return false;
	DirAccess::make_dir_recursive_absolute(saves_dir);
	const String p = slot_path(s), tmp = p + String(".tmp");
	{
		Ref<FileAccess> f = FileAccess::open(tmp, FileAccess::WRITE);
		if (f.is_null()) return false;
		f->store_string(JSON::stringify(d, "\t"));
	}
	Ref<DirAccess> da = DirAccess::open(saves_dir);
	if (da.is_null()) return false;
	if (FileAccess::file_exists(p)) da->remove(p);
	return da->rename(tmp, p) == OK;
}

Dictionary CityGame::snapshot() const {
	Dictionary st;
	st["version"] = 3;
	Dictionary g;
	g["day"] = day; g["hour"] = hour; g["money"] = money; g["flags"] = flags; g["voice"] = voice;
	Dictionary sd; sd["y"] = 2026; sd["m"] = 10; sd["d"] = 24; g["start_date"] = sd;
	st["game"] = g;
	st["economy"] = Dictionary(); st["needs"] = Dictionary(); st["health"] = Dictionary(); st["lessons"] = Dictionary(); st["npc_memory"] = Dictionary();
	Dictionary story; story["path"] = ""; story["id"] = ""; story["step"] = 0; st["story"] = story;
	Node3D *pl = player_id ? Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	if (pl && pl->is_inside_tree()) {
		Dictionary p;
		const Vector3 at = pl->get_global_position();
		Array pos; pos.push_back(at.x); pos.push_back(at.y); pos.push_back(at.z);
		p["pos"] = pos; p["yaw"] = pl->get_global_rotation().y; p["place"] = "";
		st["player"] = p;
	}
	return st;
}

void CityGame::apply_snapshot(const Dictionary &st) {
	const Dictionary g = st.get("game", Dictionary());
	day = (int)g.get("day", 1); hour = (double)g.get("hour", 9.0); money = (int)g.get("money", 50);
	flags = g.get("flags", Dictionary()); voice = g.get("voice", "f");
	Node3D *pl = player_id ? Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	const Dictionary p = st.get("player", Dictionary());
	if (pl && p.has("pos")) {
		const Array a = p["pos"];
		if (a.size() == 3) pl->set_global_position(Vector3((float)(double)a[0], (float)(double)a[1], (float)(double)a[2]));
	}
	emit_signal("time_changed", hour); emit_signal("money_changed", money);
}

Array CityGame::list_slots() const {
	Array out;
	for (int s = 0; s < MAX_SLOTS; s++) {
		const Dictionary d = read_slot(s);
		if (d.is_empty()) continue;
		const Dictionary pr = d.get("profile", Dictionary());
		Dictionary r;
		r["slot"] = s; r["name"] = pr.get("name", vformat("Player %d", s + 1)); r["last_played"] = pr.get("last_played", 0);
		r["created"] = pr.get("created", 0);
		const int64_t lp = (int64_t)pr.get("last_played", 0);
		r["last_played_text"] = lp > 0 ? Time::get_singleton()->get_datetime_string_from_unix_time(lp + (int64_t)(double)Time::get_singleton()->get_time_zone_from_system().get("bias", 0) * 60, true).substr(0, 16) : String::utf8("—");
		r["has_save"] = d.has("state");
		r["progress"] = 0.0;
		out.push_back(r);
	}
	return out;
}

int CityGame::most_recent_slot() const {
	int best = -1; int64_t bt = -1;
	for (int s = 0; s < MAX_SLOTS; s++) {
		const Dictionary d = read_slot(s);
		if (d.is_empty()) continue;
		const int64_t lp = (int64_t)((Dictionary)d.get("profile", Dictionary())).get("last_played", 0);
		if (lp > bt) { bt = lp; best = s; }
	}
	return best;
}

bool CityGame::any_save() const { return most_recent_slot() >= 0; }
bool CityGame::is_full() const { return list_slots().size() >= MAX_SLOTS; }
bool CityGame::has_save(int p_slot) const { return read_slot(p_slot).has("state"); }

int CityGame::create_slot(const String &p_name) {
	int s = -1;
	for (int k = 0; k < MAX_SLOTS; k++) if (read_slot(k).is_empty()) { s = k; break; }
	if (s < 0) return -1;
	Dictionary d, pr;
	const int64_t now = (int64_t)Time::get_singleton()->get_unix_time_from_system();
	pr["name"] = p_name.is_empty() ? vformat("Player %d", s + 1) : p_name; pr["created"] = now; pr["last_played"] = now;
	d["version"] = 3; d["profile"] = pr;
	Dictionary sec; sec["settings"] = Dictionary(); sec["checkpoints"] = Dictionary();
	d["sections"] = sec;
	if (!write_slot(s, d)) return -1;
	active_slot = s; slot_sections = sec; autosave_t = 0.0;
	emit_signal("slots_changed");
	return s;
}

bool CityGame::delete_slot(int p_slot) {
	if (read_slot(p_slot).is_empty()) return false;
	Ref<DirAccess> da = DirAccess::open(saves_dir);
	if (da.is_null() || da->remove(slot_path(p_slot)) != OK) return false;
	if (active_slot == p_slot) active_slot = -1;
	emit_signal("slots_changed");
	return true;
}

bool CityGame::rename_slot(int p_slot, const String &p_name) {
	Dictionary d = read_slot(p_slot);
	if (d.is_empty()) return false;
	Dictionary pr = d.get("profile", Dictionary()); pr["name"] = p_name; d["profile"] = pr;
	const bool ok = write_slot(p_slot, d);
	if (ok) emit_signal("slots_changed");
	return ok;
}

bool CityGame::save() {
	if (active_slot < 0) return false;
	Dictionary d = read_slot(active_slot);
	Dictionary pr = d.get("profile", Dictionary());
	pr["last_played"] = (int64_t)Time::get_singleton()->get_unix_time_from_system();
	if (!pr.has("name")) pr["name"] = vformat("Player %d", active_slot + 1);
	d["version"] = 3; d["profile"] = pr; d["state"] = snapshot(); d["sections"] = slot_sections;
	const bool ok = write_slot(active_slot, d);
	autosave_t = 0.0;
	if (ok) emit_signal("saved", active_slot);
	return ok;
}

bool CityGame::load_slot(int p_slot) {
	const Dictionary d = read_slot(p_slot);
	if (d.is_empty()) return false;
	active_slot = p_slot;
	slot_sections = d.get("sections", Dictionary());
	settings_defaults();
	const Dictionary sec = slot_sections.get("settings", Dictionary());
	const Array ks = sec.keys();
	for (int k = 0; k < ks.size(); k++) settings[ks[k]] = sec[ks[k]];
	load_device();
	apply_settings();
	if (d.has("state")) apply_snapshot(d["state"]);
	autosave_t = 0.0;
	emit_signal("loaded", p_slot);
	return true;
}

int CityGame::new_game() {
	const int s = create_slot("New player");
	if (s < 0) return -1;
	day = 1; hour = 9.0; money = 50; flags = Dictionary();
	settings_defaults(); load_device(); apply_settings();
	save();
	emit_signal("new_game_started", s);
	return s;
}

int CityGame::new_game_overwrite(int p_slot) { delete_slot(p_slot); return new_game(); }

int CityGame::continue_game(int p_slot) {
	if (!load_slot(p_slot)) return -1;
	emit_signal("game_continued", p_slot);
	return p_slot;
}

void CityGame::set_player(Object *p_player) { player_id = p_player ? (uint64_t)p_player->get_instance_id() : 0; }

void CityGame::_bind_methods() {
	ClassDB::bind_static_method("CityGame", D_METHOD("en", "key", "args"), &CityGame::en, DEFVAL(Array()));
	ClassDB::bind_static_method("CityGame", D_METHOD("helper", "key", "args"), &CityGame::helper, DEFVAL(Array()));
	ClassDB::bind_static_method("CityGame", D_METHOD("dual", "key", "args", "sep"), &CityGame::dual, DEFVAL(Array()), DEFVAL(String::utf8("  ·  ")));
	ClassDB::bind_static_method("CityGame", D_METHOD("has_text", "key"), &CityGame::has_text);
	ClassDB::bind_method(D_METHOD("set_helper_enabled", "on"), &CityGame::set_helper_enabled);
	ClassDB::bind_method(D_METHOD("get_helper_enabled"), &CityGame::get_helper_enabled);
	ClassDB::bind_method(D_METHOD("get_hour"), &CityGame::get_hour);
	ClassDB::bind_method(D_METHOD("get_day"), &CityGame::get_day);
	ClassDB::bind_method(D_METHOD("set_time", "hour", "day"), &CityGame::set_time);
	ClassDB::bind_method(D_METHOD("hhmm"), &CityGame::hhmm);
	ClassDB::bind_method(D_METHOD("get_money"), &CityGame::get_money);
	ClassDB::bind_method(D_METHOD("add_money", "amount"), &CityGame::add_money);
	ClassDB::bind_method(D_METHOD("set_flag", "key", "value"), &CityGame::set_flag);
	ClassDB::bind_method(D_METHOD("get_flag", "key", "default"), &CityGame::get_flag, DEFVAL(Variant()));
	ClassDB::bind_method(D_METHOD("set_clock_running", "on"), &CityGame::set_clock_running);
	ClassDB::bind_method(D_METHOD("get_clock_running"), &CityGame::get_clock_running);
	ClassDB::bind_method(D_METHOD("get_setting", "key"), &CityGame::get_setting);
	ClassDB::bind_method(D_METHOD("set_setting", "key", "value"), &CityGame::set_setting);
	ClassDB::bind_method(D_METHOD("get_settings"), &CityGame::get_settings);
	ClassDB::bind_method(D_METHOD("list_slots"), &CityGame::list_slots);
	ClassDB::bind_method(D_METHOD("most_recent_slot"), &CityGame::most_recent_slot);
	ClassDB::bind_method(D_METHOD("any_save"), &CityGame::any_save);
	ClassDB::bind_method(D_METHOD("is_full"), &CityGame::is_full);
	ClassDB::bind_method(D_METHOD("create_slot", "name"), &CityGame::create_slot);
	ClassDB::bind_method(D_METHOD("delete_slot", "slot"), &CityGame::delete_slot);
	ClassDB::bind_method(D_METHOD("rename_slot", "slot", "name"), &CityGame::rename_slot);
	ClassDB::bind_method(D_METHOD("save"), &CityGame::save);
	ClassDB::bind_method(D_METHOD("load_slot", "slot"), &CityGame::load_slot);
	ClassDB::bind_method(D_METHOD("has_save", "slot"), &CityGame::has_save);
	ClassDB::bind_method(D_METHOD("get_active_slot"), &CityGame::get_active_slot);
	ClassDB::bind_method(D_METHOD("new_game"), &CityGame::new_game);
	ClassDB::bind_method(D_METHOD("new_game_overwrite", "slot"), &CityGame::new_game_overwrite);
	ClassDB::bind_method(D_METHOD("continue_game", "slot"), &CityGame::continue_game);
	ClassDB::bind_method(D_METHOD("set_player", "player"), &CityGame::set_player);
	ClassDB::bind_method(D_METHOD("set_saves_dir", "dir"), &CityGame::set_saves_dir);
	ClassDB::bind_method(D_METHOD("get_saves_dir"), &CityGame::get_saves_dir);
	ClassDB::bind_method(D_METHOD("set_autosave_s", "seconds"), &CityGame::set_autosave_s);
	ClassDB::bind_method(D_METHOD("get_autosave_s"), &CityGame::get_autosave_s);
	ClassDB::bind_method(D_METHOD("open_menu"), &CityGame::open_menu);
	ClassDB::bind_method(D_METHOD("close_menu"), &CityGame::close_menu);
	ClassDB::bind_method(D_METHOD("is_menu_open"), &CityGame::is_menu_open);
	ClassDB::bind_method(D_METHOD("open_pause"), &CityGame::open_pause);
	ClassDB::bind_method(D_METHOD("close_pause"), &CityGame::close_pause);
	ClassDB::bind_method(D_METHOD("is_pause_open"), &CityGame::is_pause_open);
	ClassDB::bind_method(D_METHOD("game_over", "reason_en", "reason_tr", "title", "rewind"), &CityGame::game_over, DEFVAL(""), DEFVAL(""), DEFVAL(""));
	ClassDB::bind_method(D_METHOD("retry"), &CityGame::retry);
	ClassDB::bind_method(D_METHOD("is_game_over"), &CityGame::is_game_over);
	ClassDB::bind_method(D_METHOD("open_loading"), &CityGame::open_loading);
	ClassDB::bind_method(D_METHOD("set_loading", "progress", "key"), &CityGame::set_loading, DEFVAL(""));
	ClassDB::bind_method(D_METHOD("close_loading"), &CityGame::close_loading);
	ClassDB::bind_method(D_METHOD("current_screen"), &CityGame::current_screen);
	ClassDB::bind_method(D_METHOD("press", "key"), &CityGame::press);
	ClassDB::bind_method(D_METHOD("set_world_scene", "path"), &CityGame::set_world_scene);
	ClassDB::bind_method(D_METHOD("get_world_scene"), &CityGame::get_world_scene);
	ClassDB::bind_method(D_METHOD("is_playing"), &CityGame::is_playing);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "world_scene"), "set_world_scene", "get_world_scene");
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "saves_dir"), "set_saves_dir", "get_saves_dir");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "autosave_s"), "set_autosave_s", "get_autosave_s");
	ADD_SIGNAL(MethodInfo("time_changed", PropertyInfo(Variant::FLOAT, "hour")));
	ADD_SIGNAL(MethodInfo("minute_changed", PropertyInfo(Variant::INT, "day"), PropertyInfo(Variant::STRING, "hhmm")));
	ADD_SIGNAL(MethodInfo("day_changed", PropertyInfo(Variant::INT, "day")));
	ADD_SIGNAL(MethodInfo("money_changed", PropertyInfo(Variant::INT, "money")));
	ADD_SIGNAL(MethodInfo("setting_changed", PropertyInfo(Variant::STRING, "key")));
	ADD_SIGNAL(MethodInfo("settings_applied"));
	ADD_SIGNAL(MethodInfo("saved", PropertyInfo(Variant::INT, "slot")));
	ADD_SIGNAL(MethodInfo("loaded", PropertyInfo(Variant::INT, "slot")));
	ADD_SIGNAL(MethodInfo("slots_changed"));
	ADD_SIGNAL(MethodInfo("new_game_started", PropertyInfo(Variant::INT, "slot")));
	ADD_SIGNAL(MethodInfo("game_continued", PropertyInfo(Variant::INT, "slot")));
	ADD_SIGNAL(MethodInfo("play_started", PropertyInfo(Variant::INT, "slot")));
	ADD_SIGNAL(MethodInfo("menu_closed"));
	ADD_SIGNAL(MethodInfo("paused_changed", PropertyInfo(Variant::BOOL, "open")));
	ADD_SIGNAL(MethodInfo("game_over_shown"));
	ADD_SIGNAL(MethodInfo("retried", PropertyInfo(Variant::BOOL, "ok")));
}

} // namespace godot
