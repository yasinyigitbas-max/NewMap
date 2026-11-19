// CityGame: text, the game's state, settings and saves (see city_game.h). The screens are in city_game_ui.cpp.
#include "city_game.h"

#include <godot_cpp/classes/audio_server.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/classes/rigid_body3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/character_body3d.hpp>
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
#include <thread>

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
CityGame::~CityGame() { while (shot_busy.load()) std::this_thread::yield(); if (one == this) one = nullptr; }

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
	st["economy"] = Dictionary(); st["lessons"] = Dictionary(); st["npc_memory"] = Dictionary();
	st["map_targets"] = map_targets;
	{ Dictionary h; h["value"] = health; st["health"] = h; Dictionary n; n["hunger"] = hunger; n["thirst"] = thirst; n["energy"] = energy; n["active"] = needs_active; st["needs"] = n; }
	Dictionary story; story["path"] = ""; story["id"] = ""; story["step"] = 0; st["story"] = story;
	Node3D *pl = player_id ? Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	if (pl && pl->is_inside_tree()) {
		Dictionary p;
		const Vector3 at = pl->get_global_position();
		Array pos; pos.push_back(at.x); pos.push_back(at.y); pos.push_back(at.z);
		p["pos"] = pos; p["yaw"] = pl->get_global_rotation().y; p["place"] = "";
		if (pl->has_method("get_view")) p["view"] = pl->call("get_view");   // (the picture's view: the loaded game looks the same way)
		st["player"] = p;
	}
	return st;
}

void CityGame::apply_snapshot(const Dictionary &st) {
	const Dictionary g = st.get("game", Dictionary());
	day = (int)g.get("day", 1); hour = (double)g.get("hour", 9.0); money = (int)g.get("money", 50);
	flags = g.get("flags", Dictionary()); voice = g.get("voice", "f");
	map_targets = st.get("map_targets", Array());
	{ const Dictionary h = st.get("health", Dictionary()); health = (float)(double)h.get("value", 1.0);
	  const Dictionary n = st.get("needs", Dictionary()); hunger = (float)(double)n.get("hunger", 1.0); thirst = (float)(double)n.get("thirst", 1.0); energy = (float)(double)n.get("energy", 1.0); needs_active = (bool)n.get("active", false); }
	Node3D *pl = player_id ? Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	const Dictionary p = st.get("player", Dictionary());
	if (!pl && p.has("pos")) pending_player = p;   // (the world gives the player later)
	if (pl && p.has("pos")) {
		const Array a = p["pos"];
		if (a.size() == 3) pl->set_global_position(Vector3((float)(double)a[0], (float)(double)a[1], (float)(double)a[2]));
		const Array v = p.get("view", Array());
		if (v.size() == 3 && pl->has_method("set_view")) pl->call("set_view", v[0], v[1], v[2]);
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
	if (FileAccess::file_exists(shot_path(p_slot))) da->remove(shot_path(p_slot));
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
	// the picture, from the frame on screen, only when nothing is over the world (else the last picture stays)
	if (ok && world_on && !menu_open && !pause_open && !over_open && play_phase == 0 && !(loading && loading->is_visible())) take_shot();
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
	pending_new = true; pending_player = Dictionary();
	if (player_id && crowd_id) place_start();
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

void CityGame::set_player(Object *p_player) {
	player_id = p_player ? (uint64_t)p_player->get_instance_id() : 0;
	if (!p_player) return;
	if (pending_new) place_start();
	else if (!pending_player.is_empty()) { Dictionary st; st["player"] = pending_player; pending_player = Dictionary(); apply_snapshot(st); }
}

Vector3 CityGame::world_start() const {
	if (!pending_player.is_empty() && pending_player.has("pos")) { const Array a = pending_player["pos"]; if (a.size() == 3) return Vector3((float)(double)a[0], (float)(double)a[1], (float)(double)a[2]); }
	return start_centre;
}

void CityGame::hold_start(double p_delta) {
	start_hold += p_delta;
	Node3D *pl = player_id ? Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	Node3D *bike = start_bike ? Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(start_bike))) : nullptr;
	if (!pl || !pl->is_inside_tree()) { start_hold = -1.0; return; }
	PhysicsDirectSpaceState3D *ss = pl->get_world_3d().is_valid() ? pl->get_world_3d()->get_direct_space_state() : nullptr;
	float gy = -1e9f;
	if (ss) {
		Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(start_at + Vector3(0, 2.0f, 0), start_at - Vector3(0, 2.0f, 0), 1);
		const Dictionary h = ss->intersect_ray(q);
		if (!h.is_empty()) gy = ((Vector3)h["position"]).y;
	}
	if (gy < -1e8f && start_hold > 2.0 && ss) {   // the ground round him is there but not under him: a hole in a piece's collision; along the pavement to solid ground
		auto ground_at = [&](const Vector3 &p) -> float {
			Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(p + Vector3(0, 2.0f, 0), p - Vector3(0, 2.0f, 0), 1);
			const Dictionary h = ss->intersect_ray(q);
			return h.is_empty() ? -1e9f : ((Vector3)h["position"]).y;
		};
		const float yaw = (float)(double)start_info.get("yaw", 0.0);
		const Vector3 f(std::sin(yaw), 0, std::cos(yaw));
		bool moved = false;
		for (int k = 1; k <= 5 && !moved; k++) {
			for (int sgn = -1; sgn <= 1 && !moved; sgn += 2) {
				const Vector3 c = start_at + f * (2.0f * (float)k * (float)sgn);
				const float g1 = ground_at(c), g2 = ground_at(c + f * 1.8f);
				if (g1 > -1e8f && g2 > -1e8f && std::fabs(g1 - start_at.y) < 0.6f) {
					start_at = Vector3(c.x, g1, c.z); gy = g1; moved = true;
					if (bike) bike->set_global_position(Vector3(c.x, g2 + 0.03f, c.z) + f * 1.8f);
					Node3D *car = start_car ? Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(start_car))) : nullptr;
					if (car) car->set_global_position(car->get_global_position() + f * (2.0f * (float)k * (float)sgn));   // (the car goes along with them)
					start_info["moved_off_a_hole_m"] = 2.0f * (float)k;
				}
			}
		}
	}
	if (gy < -1e8f && start_hold < 20.0) {   // not yet: keep him on the spot
		pl->set_global_position(start_at + Vector3(0, 0.05f, 0));
		if (CharacterBody3D *cb = Object::cast_to<CharacterBody3D>(pl)) cb->set_velocity(Vector3());
		return;
	}
	if (gy > -1e8f) pl->set_global_position(Vector3(start_at.x, gy + 0.05f, start_at.z));
	if (bike && ss) {   // the bicycle's own spot must have ground under it too (a corner between pavement stretches may have none): else along to one that has
		auto ground_at = [&](const Vector3 &p) -> float {
			Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(p + Vector3(0, 2.0f, 0), p - Vector3(0, 2.0f, 0), 1);
			const Dictionary h = ss->intersect_ray(q);
			return h.is_empty() ? -1e9f : ((Vector3)h["position"]).y;
		};
		const float yaw = (float)(double)start_info.get("yaw", 0.0);
		const Vector3 f(std::sin(yaw), 0, std::cos(yaw)), sd(f.z, 0, -f.x);
		const Vector3 base(start_at.x, start_at.y, start_at.z);
		const Vector3 tries[8] = { base + f * 1.8f, base + f * 1.4f, base - f * 1.8f, base + sd * 1.2f, base - sd * 1.2f, base + f * 2.6f, base - f * 2.6f, base + f * 1.0f + sd * 0.8f };
		for (const Vector3 &c : tries) {
			const float g = ground_at(c);
			if (g > -1e8f && std::fabs(g - start_at.y) < 0.5f) { bike->set_global_position(Vector3(c.x, g + 0.03f, c.z)); start_info["bike"] = bike->get_global_position(); break; }
		}
	}
	pl->call("set_frozen", false);
	if (RigidBody3D *rb = Object::cast_to<RigidBody3D>(bike)) rb->set_freeze_enabled(false);
	start_info["ground_found_after_s"] = start_hold; start_info["ground"] = gy;
	start_hold = -1.0;
}

void CityGame::set_world(Object *p_crowd, Object *p_traffic) {
	crowd_id = p_crowd ? (uint64_t)p_crowd->get_instance_id() : 0;
	traffic_id = p_traffic ? (uint64_t)p_traffic->get_instance_id() : 0;
}

// A new game: the player on the pavement nearest the city centre (pavements are outdoors: never in or on a building),
// facing along it; his bicycle just ahead of him on the pavement; a car at the kerb beside him, on the road's side
// (the side where 3 m out is no longer pavement).
void CityGame::place_start() {
	pending_new = false;
	Node3D *pl = player_id ? Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	Object *crowd = crowd_id ? ObjectDB::get_instance(ObjectID(crowd_id)) : nullptr;
	start_info = Dictionary();
	if (!pl || !crowd) return;
	const Dictionary pv = crowd->call("pavement_near", start_centre, 400.0);
	if (!(bool)pv.get("ok", false)) return;
	const Vector3 at = pv["at"];
	const float yaw = (float)(double)pv["yaw"], hw = (float)(double)pv.get("half_width", 0.75);
	const Vector3 f(std::sin(yaw), 0, std::cos(yaw));
	Vector3 side = pv["side"];
	{   // which side is the road: 3 m out, the pavement is no longer under the point
		const Dictionary a = crowd->call("pavement_near", at + side * (hw + 2.0f), 2.0);
		const Dictionary b = crowd->call("pavement_near", at - side * (hw + 2.0f), 2.0);
		const bool a_pave = (bool)a.get("ok", false), b_pave = (bool)b.get("ok", false);
		if (a_pave && !b_pave) side = -side;
	}
	pl->set_global_position(at + Vector3(0, 0.05f, 0));
	pl->set_global_rotation(Vector3(0, yaw, 0));
	Node *parent = pl->get_parent();
	Node3D *bike = Object::cast_to<Node3D>(ClassDB::instantiate("CityBike"));
	if (bike && parent) {
		bike->set_name("StartBike");
		bike->set("player", true);
		bike->set("touch_hud", true);
		parent->add_child(bike);
		bike->set_global_transform(Transform3D(Basis(Vector3(0, 1, 0), yaw), at + f * 1.8f + side * std::min(hw * 0.4f, 0.4f) + Vector3(0, 0.03f, 0)));
		bike->call("set_rider_player", pl);
	}
	Node3D *car = Object::cast_to<Node3D>(ClassDB::instantiate("CityCar"));
	const Vector3 car_at = at + side * (hw + 1.35f) - f * 1.5f + Vector3(0, 0.1f, 0);
	if (car && parent) {
		car->set_name("StartCar");
		car->set("model", 2);
		parent->add_child(car);
		car->set_global_transform(Transform3D(Basis(Vector3(0, 1, 0), yaw), car_at));
		car->call("set_controls", 0.0, 1.0, 0.0, 1.0, false);   // (parked: the brakes on)
	}
	// held there (and the bicycle frozen) until the streamed ground's collision is under them: placed before it came, he
	// fell through to the plane under the city (seen in the first run of tests/game/test_start.gd)
	start_at = at; start_hold = 0.0; start_bike = bike ? (uint64_t)bike->get_instance_id() : 0; start_car = car ? (uint64_t)car->get_instance_id() : 0;
	pl->call("set_frozen", true);
	if (RigidBody3D *rb = Object::cast_to<RigidBody3D>(bike)) rb->set_freeze_enabled(true);
	start_info["player"] = at; start_info["yaw"] = yaw; start_info["bike"] = bike ? bike->get_global_position() : Vector3();
	start_info["car"] = car_at; start_info["pavement_half_width"] = hw; start_info["road_side"] = side;
	emit_signal("start_placed", start_info);
}

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
	ClassDB::bind_method(D_METHOD("set_world", "crowd", "traffic"), &CityGame::set_world);
	ClassDB::bind_method(D_METHOD("get_start_info"), &CityGame::get_start_info);
	ClassDB::bind_method(D_METHOD("world_start"), &CityGame::world_start);
	ClassDB::bind_method(D_METHOD("set_start_centre", "at"), &CityGame::set_start_centre);
	ClassDB::bind_method(D_METHOD("get_start_centre"), &CityGame::get_start_centre);
	ADD_SIGNAL(MethodInfo("start_placed", PropertyInfo(Variant::DICTIONARY, "info")));
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
	ClassDB::bind_method(D_METHOD("has_picture", "slot"), &CityGame::has_picture);
	ClassDB::bind_method(D_METHOD("set_objective", "at"), &CityGame::set_objective);
	ClassDB::bind_method(D_METHOD("clear_objective"), &CityGame::clear_objective);
	ClassDB::bind_method(D_METHOD("get_objective_on"), &CityGame::get_objective_on);
	ClassDB::bind_method(D_METHOD("get_needs_active"), &CityGame::get_needs_active);
	ClassDB::bind_method(D_METHOD("set_needs_active", "on"), &CityGame::set_needs_active);
	ClassDB::bind_method(D_METHOD("get_hud"), &CityGame::get_hud);
	ClassDB::bind_method(D_METHOD("get_map_targets"), &CityGame::get_map_targets);
	ClassDB::bind_method(D_METHOD("set_map_targets", "targets"), &CityGame::set_map_targets);
	ClassDB::bind_method(D_METHOD("menu_picture_shown"), &CityGame::menu_picture_shown);
	ClassDB::bind_method(D_METHOD("loading_picture_shown"), &CityGame::loading_picture_shown);
	ClassDB::bind_method(D_METHOD("is_loading_fading"), &CityGame::is_loading_fading);
	ClassDB::bind_method(D_METHOD("get_shot_ms"), &CityGame::get_shot_ms);
	ClassDB::bind_method(D_METHOD("get_shots"), &CityGame::get_shots);
	ClassDB::bind_method(D_METHOD("is_shot_busy"), &CityGame::is_shot_busy);
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
