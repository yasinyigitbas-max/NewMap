// CityPhone: the phone's screens, all C++ (docs/GAME_PORT_BOARD.md item 9; Yasin, 20 Nov: "CONTINUE BRINGING THE OLD
// SYSTEMS OF THE GAME BACK ONE BY ONE, ONLY C PLUS PLUS"; the old game's ui/phone/*). Inside the HUD's phone panel (it
// grows out of the phone button): a header (the app's name in English over Turkish, Back to the home screen, Close), the
// HOME screen (a grid of app tiles drawn in code, as the old phone_style.gd: a rounded gradient square, a white line
// glyph, the name under it) and one page per app:
//  - Map: the HUD's map (HudMap, board item 8), the arrow box opens the phone straight on it.
//  - Camera: Take photo hides the HUD for a frame, grabs the game view, saves user://photos/<time>.png (1280 wide).
//  - Photos: the gallery, newest first; tap one to see it whole.
//  - Contacts and Messages: kept in the save (CityGame "phone"); other systems add contacts and send / receive lines
//    (add_contact, receive_message, send_message): every line in English with Turkish under it.
//  - Call: an incoming call (ring: the phone opens on it), Answer / Decline, on the call a timer and Hang up; signals.
//  - Settings: the game's own settings panel.
//  - Bank, Transit, Delivery (money: board item 10), Jobs (item 11), Learn, Films (item 12), Radio (a car radio): their
//    page says what they wait for, until those systems are in.
#pragma once

#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/grid_container.hpp>
#include <godot_cpp/classes/h_box_container.hpp>
#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/scroll_container.hpp>
#include <godot_cpp/classes/texture_rect.hpp>
#include <godot_cpp/classes/v_box_container.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>

#include <map>
#include <vector>

namespace godot {

// One app tile on the home screen: drawn in code
class PhoneTile : public Control {
	GDCLASS(PhoneTile, Control)
protected:
	static void _bind_methods() {}
public:
	String app, en;
	Color col;
	int glyph = 0;
	bool waiting = false;          // its system is not in yet: drawn dimmer
	void _draw() override;
	void _gui_input(const Ref<InputEvent> &p_event) override;
	class CityPhone *phone = nullptr;
};

class CityPhone : public Control {
	GDCLASS(CityPhone, Control)
	friend class PhoneTile;
	struct App { String id, en, tr; Color col; int glyph; String waits_en, waits_tr; };
	std::vector<App> apps;
	String cur = "home";
	Label *t_en = nullptr, *t_tr = nullptr;
	Button *b_back = nullptr, *b_close = nullptr;
	Control *body = nullptr;                     // the pages live here
	std::map<String, Control *> pages;
	Control *map_page = nullptr;                 // (the HUD's map)
	Button *b_pin = nullptr;
	// camera and photos
	int photo_frames = -1;                       // >= 0: taking a photo, frames since the HUD was hidden
	String last_photo;
	GridContainer *gallery = nullptr;
	TextureRect *photo_full = nullptr;
	std::map<String, Ref<ImageTexture>> thumbs;
	Label *cam_note = nullptr;
	// contacts, messages
	VBoxContainer *contact_list = nullptr, *thread_list = nullptr, *thread_view = nullptr;
	String thread_of;
	Dictionary local;                            // (no game: the phone's data kept here)
	// a call
	String caller;
	int call_state = 0;                          // 0 none, 1 ringing, 2 on the call
	double call_t = 0.0;
	Label *call_name = nullptr, *call_line = nullptr;
	Button *b_answer = nullptr, *b_decline = nullptr, *b_hang = nullptr;
	String before_call = "home";

	void build();
	Control *page(const String &id);
	Control *waiting_page(const App &a);
	void show_page(const String &id);
	void refresh_gallery();
	void refresh_contacts();
	void refresh_threads();
	void refresh_thread();
	Dictionary data() const;
	void set_data(const Dictionary &d);
	void tap_feedback();
	void close_phone();
	const App *app_of(const String &id) const;

protected:
	static void _bind_methods();

public:
	class CityHud *hud = nullptr;
	void set_map(Control *p_map, Button *p_pin);
	void _ready() override;
	void _process(double p_delta) override;

	void open_app(const String &p_id);           // "home", "map", "camera", "photos", "contacts", "messages", "call", "settings", ...
	void go_home() { open_app("home"); }
	String get_app() const { return cur; }
	PackedStringArray get_apps() const;
	bool app_waits(const String &p_id) const;
	// camera
	void take_photo();
	bool is_taking_photo() const { return photo_frames >= 0; }
	String get_last_photo() const { return last_photo; }
	PackedStringArray get_photos() const;
	void view_photo(const String &p_path);
	// contacts and messages
	void add_contact(const String &p_id, const String &p_name, const String &p_number, const String &p_note);
	Array get_contacts() const;
	void receive_message(const String &p_contact, const String &p_en, const String &p_tr);
	void send_message(const String &p_contact, const String &p_en, const String &p_tr);
	Array get_thread(const String &p_contact) const;
	void open_thread(const String &p_contact);
	// a call
	void ring(const String &p_caller);
	void ringtone(bool p_on);
	void answer();
	void hang_up();
	int get_call_state() const { return call_state; }
};

} // namespace godot
