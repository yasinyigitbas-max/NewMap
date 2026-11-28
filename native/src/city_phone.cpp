// CityPhone: see city_phone.h.
#include "city_phone.h"
#include "city_game.h"
#include "city_hud.h"
#include "el_sfx.h"
#include <godot_cpp/classes/audio_stream_player.hpp>
#include "ui_plate.h"

#include <godot_cpp/classes/dir_access.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/input_event_mouse_button.hpp>
#include <godot_cpp/classes/input_event_screen_touch.hpp>
#include <godot_cpp/classes/margin_container.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/classes/style_box_flat.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/viewport_texture.hpp>
#include <godot_cpp/core/class_db.hpp>

#include <algorithm>
#include <cmath>

namespace godot {

namespace {
enum { G_MAP, G_CAMERA, G_PHOTOS, G_MESSAGES, G_CONTACTS, G_BANK, G_TRANSIT, G_DELIVERY, G_JOBS, G_LEARN, G_FILMS, G_RADIO, G_SETTINGS };
inline String PHOTO_DIR() { return String("user://photos"); }
}

// ---------------------------------------------------------------- the tiles
void PhoneTile::_draw() {
	const Vector2 sz = get_size();
	const float s = std::min(sz.x, sz.y - 26.0f);
	const Rect2 r(Vector2((sz.x - s) * 0.5f, 0.0f), Vector2(s, s));
	const float a = waiting ? 0.45f : 1.0f;
	// soft shadow, the squircle (lighter at the top), a gloss
	Ref<StyleBoxFlat> sh; sh.instantiate(); sh->set_bg_color(Color(0, 0, 0, 0.35f * a)); sh->set_corner_radius_all((int)(s * 0.24f));
	draw_style_box(sh, Rect2(r.position + Vector2(0, 3), r.size));
	Ref<StyleBoxFlat> sq; sq.instantiate(); sq->set_bg_color(Color(col.r, col.g, col.b, a)); sq->set_corner_radius_all((int)(s * 0.24f));
	draw_style_box(sq, r);
	Ref<StyleBoxFlat> gl; gl.instantiate(); gl->set_bg_color(Color(1, 1, 1, 0.14f * a)); gl->set_corner_radius_all((int)(s * 0.24f));
	draw_style_box(gl, Rect2(r.position, Vector2(s, s * 0.48f)));
	// the glyph: white lines in the middle 56 %
	const Color w(1, 1, 1, 0.95f * a);
	const Vector2 c = r.get_center();
	const float u = s * 0.28f, lw = std::max(2.0f, s * 0.045f);
	auto L = [&](float x0, float y0, float x1, float y1) { draw_line(c + Vector2(x0, y0) * u, c + Vector2(x1, y1) * u, w, lw, true); };
	auto R = [&](float x0, float y0, float x1, float y1) { L(x0, y0, x1, y0); L(x1, y0, x1, y1); L(x1, y1, x0, y1); L(x0, y1, x0, y0); };
	auto C = [&](float x, float y, float rr) { draw_arc(c + Vector2(x, y) * u, rr * u, 0.0f, 6.2831853f, 28, w, lw, true); };
	switch (glyph) {
		case G_MAP: L(-1, -0.7f, -0.35f, -1); L(-0.35f, -1, 0.35f, -0.7f); L(0.35f, -0.7f, 1, -1); L(1, -1, 1, 0.7f); L(1, 0.7f, 0.35f, 1); L(0.35f, 1, -0.35f, 0.7f); L(-0.35f, 0.7f, -1, 1); L(-1, 1, -1, -0.7f); L(-0.35f, -1, -0.35f, 0.7f); L(0.35f, -0.7f, 0.35f, 1); break;
		case G_CAMERA: R(-1, -0.55f, 1, 0.8f); C(0, 0.12f, 0.42f); L(-0.45f, -0.55f, -0.3f, -0.85f); L(-0.3f, -0.85f, 0.3f, -0.85f); L(0.3f, -0.85f, 0.45f, -0.55f); break;
		case G_PHOTOS: R(-1, -0.8f, 1, 0.8f); L(-1, 0.6f, -0.3f, -0.1f); L(-0.3f, -0.1f, 0.2f, 0.4f); L(0.2f, 0.4f, 0.5f, 0.1f); L(0.5f, 0.1f, 1, 0.6f); C(0.45f, -0.4f, 0.18f); break;
		case G_MESSAGES: R(-1, -0.8f, 1, 0.45f); L(-0.5f, 0.45f, -0.7f, 0.9f); L(-0.7f, 0.9f, -0.1f, 0.45f); L(-0.6f, -0.35f, 0.6f, -0.35f); L(-0.6f, 0.0f, 0.3f, 0.0f); break;
		case G_CONTACTS: C(0, -0.4f, 0.42f); draw_arc(c + Vector2(0, 0.95f) * u, 0.85f * u, 3.4f, 6.02f, 24, w, lw, true); break;
		case G_BANK: L(-1, -0.4f, 0, -0.95f); L(0, -0.95f, 1, -0.4f); L(-1, -0.4f, 1, -0.4f); L(-0.65f, -0.25f, -0.65f, 0.6f); L(0, -0.25f, 0, 0.6f); L(0.65f, -0.25f, 0.65f, 0.6f); L(-1, 0.8f, 1, 0.8f); break;
		case G_TRANSIT: R(-0.85f, -0.9f, 0.85f, 0.6f); L(-0.85f, -0.2f, 0.85f, -0.2f); C(-0.45f, 0.85f, 0.18f); C(0.45f, 0.85f, 0.18f); break;
		case G_DELIVERY: R(-0.9f, -0.5f, 0.9f, 0.9f); L(-0.9f, -0.5f, -0.5f, -0.95f); L(-0.5f, -0.95f, 0.5f, -0.95f); L(0.5f, -0.95f, 0.9f, -0.5f); L(0, -0.5f, 0, 0.2f); break;
		case G_JOBS: R(-1, -0.45f, 1, 0.85f); R(-0.35f, -0.85f, 0.35f, -0.45f); L(-1, 0.1f, 1, 0.1f); break;
		case G_LEARN: L(0, -0.7f, 0, 0.85f); L(0, -0.7f, -0.95f, -0.9f); L(-0.95f, -0.9f, -0.95f, 0.65f); L(-0.95f, 0.65f, 0, 0.85f); L(0, -0.7f, 0.95f, -0.9f); L(0.95f, -0.9f, 0.95f, 0.65f); L(0.95f, 0.65f, 0, 0.85f); break;
		case G_FILMS: R(-1, -0.7f, 1, 0.7f); for (int k = 0; k < 4; k++) { const float x = -0.75f + 0.5f * (float)k; L(x, -0.7f, x, -0.45f); L(x, 0.45f, x, 0.7f); } L(-0.2f, -0.25f, -0.2f, 0.25f); L(-0.2f, -0.25f, 0.25f, 0.0f); L(0.25f, 0.0f, -0.2f, 0.25f); break;
		case G_RADIO: R(-1, -0.4f, 1, 0.85f); C(0.45f, 0.22f, 0.3f); L(-0.7f, 0.0f, -0.1f, 0.0f); L(-0.7f, 0.4f, -0.1f, 0.4f); L(-0.6f, -0.4f, 0.6f, -0.95f); break;
		case G_SETTINGS: C(0, 0, 0.38f); for (int k = 0; k < 8; k++) { const float an = 0.785398f * (float)k; L(std::cos(an) * 0.6f, std::sin(an) * 0.6f, std::cos(an) * 0.92f, std::sin(an) * 0.92f); } break;
		default: break;
	}
	// the name under it
	Ref<Font> f = plate::font(700);
	const int fs = (int)std::max(12.0f, s * 0.17f);
	const float tw = f->get_string_size(en, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x;
	draw_string(f, Vector2((sz.x - tw) * 0.5f, s + fs + 6.0f), en, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, waiting ? 0.55f : 0.92f));
}

void PhoneTile::_gui_input(const Ref<InputEvent> &p_event) {
	Ref<InputEventMouseButton> mb = p_event;
	Ref<InputEventScreenTouch> st = p_event;
	// (28 Nov night) one touch is also an emulated click (device -1): only one of the two opens the app; and a finger that
	// scrolled the grid opens nothing where it lifts (more than 12 px from where it went down)
	if (mb.is_valid() && mb->get_device() == -1) return;
	Vector2 at; bool down = false, up = false;
	if (mb.is_valid() && mb->get_button_index() == MOUSE_BUTTON_LEFT) { at = mb->get_position(); down = mb->is_pressed(); up = !down; }
	else if (st.is_valid()) { at = st->get_position(); down = st->is_pressed(); up = !down; }
	if (down) { press_at = at; return; }
	if (up && phone && at.distance_to(press_at) <= 12.0f) { phone->tap_feedback(); phone->open_app(app); accept_event(); }
}

// ---------------------------------------------------------------- the phone
const CityPhone::App *CityPhone::app_of(const String &id) const {
	for (const App &a : apps) if (a.id == id) return &a;
	return nullptr;
}

void CityPhone::_ready() { build(); set_process(true); }

void CityPhone::tap_feedback() { if (hud) hud->feedback(); }
void CityPhone::close_phone() { if (hud) hud->touch(3); }

void CityPhone::build() {
	if (!apps.empty()) return;
	const String money_en = "Comes with money and the bank (board item 10).", money_tr = String::utf8("Para ve banka ile gelecek.");
	apps = {
		{ "map", "Map", "Harita", Color(0.16f, 0.55f, 0.36f), G_MAP, "", "" },
		{ "camera", "Camera", "Kamera", Color(0.22f, 0.24f, 0.28f), G_CAMERA, "", "" },
		{ "photos", "Photos", String::utf8("Fotoğraflar"), Color(0.85f, 0.42f, 0.18f), G_PHOTOS, "", "" },
		{ "messages", "Messages", "Mesajlar", Color(0.18f, 0.62f, 0.32f), G_MESSAGES, "", "" },
		{ "contacts", "Contacts", String::utf8("Kişiler"), Color(0.45f, 0.47f, 0.52f), G_CONTACTS, "", "" },
		{ "settings", "Settings", "Ayarlar", Color(0.35f, 0.37f, 0.42f), G_SETTINGS, "", "" },
		{ "bank", "Bank", "Banka", Color(0.15f, 0.35f, 0.68f), G_BANK, money_en, money_tr },
		{ "transit", "Transit", String::utf8("Ulaşım"), Color(0.9f, 0.62f, 0.12f), G_TRANSIT, "Bus tickets come with money (board item 10).", String::utf8("Otobüs bileti para ile gelecek.") },
		{ "delivery", "Delivery", String::utf8("Sipariş"), Color(0.82f, 0.22f, 0.22f), G_DELIVERY, money_en, money_tr },
		{ "jobs", "Jobs", String::utf8("İşler"), Color(0.42f, 0.3f, 0.66f), G_JOBS, "Comes with jobs and deliveries (board item 11).", String::utf8("İşler ve teslimatlar ile gelecek.") },
		{ "learn", "Learn", String::utf8("Öğren"), Color(0.2f, 0.5f, 0.8f), G_LEARN, "Comes with the lessons (board item 12).", String::utf8("Dersler ile gelecek.") },
		{ "films", "Films", "Filmler", Color(0.6f, 0.15f, 0.45f), G_FILMS, "Comes with the lessons (board item 12).", String::utf8("Dersler ile gelecek.") },
		{ "radio", "Radio", "Radyo", Color(0.12f, 0.55f, 0.6f), G_RADIO, "Only in a car with a radio: not in the game yet.", String::utf8("Sadece radyolu bir arabada: henüz oyunda yok.") },
	};
	VBoxContainer *v = memnew(VBoxContainer); v->add_theme_constant_override("separation", 10);
	v->set_anchors_and_offsets_preset(Control::PRESET_FULL_RECT);
	add_child(v);
	HBoxContainer *top = memnew(HBoxContainer); top->add_theme_constant_override("separation", 8);
	b_back = plate::button(String::utf8("‹"), "raised"); b_back->set_custom_minimum_size(Vector2(56, 56));
	b_back->connect("pressed", callable_mp(this, &CityPhone::go_home));
	top->add_child(b_back);
	VBoxContainer *tt = memnew(VBoxContainer); tt->set_h_size_flags(Control::SIZE_EXPAND_FILL);
	t_en = plate::label("PHONE", plate::FS_TITLE, plate::TEXT, 800); t_tr = plate::caps("TELEFON");
	tt->add_child(t_en); tt->add_child(t_tr);
	top->add_child(tt);
	b_close = plate::button(String::utf8("✕"), "raised"); b_close->set_custom_minimum_size(Vector2(56, 56));
	b_close->connect("pressed", callable_mp(this, &CityPhone::close_phone));
	top->add_child(b_close);
	v->add_child(top);
	body = memnew(Control); body->set_v_size_flags(Control::SIZE_EXPAND_FILL); body->set_h_size_flags(Control::SIZE_EXPAND_FILL);
	body->set_clip_contents(true);
	v->add_child(body);
	// home: the tiles
	{
		ScrollContainer *sc = memnew(ScrollContainer);
		sc->set_horizontal_scroll_mode(ScrollContainer::SCROLL_MODE_DISABLED);
		GridContainer *g = memnew(GridContainer); g->set_columns(5); g->set_h_size_flags(Control::SIZE_EXPAND_FILL);
		g->add_theme_constant_override("h_separation", 14); g->add_theme_constant_override("v_separation", 14);
		for (const App &a : apps) {
			PhoneTile *t = memnew(PhoneTile);
			t->app = a.id; t->en = a.en; t->col = a.col; t->glyph = a.glyph; t->waiting = !a.waits_en.is_empty(); t->phone = this;
			t->set_custom_minimum_size(Vector2(96, 122)); t->set_h_size_flags(Control::SIZE_EXPAND_FILL);
			t->set_mouse_filter(Control::MOUSE_FILTER_STOP);
			t->set_name(String("tile_") + a.id);
			g->add_child(t);
		}
		sc->add_child(g);
		pages["home"] = sc;
	}
	for (auto &kv : pages) { kv.second->set_anchors_and_offsets_preset(Control::PRESET_FULL_RECT); body->add_child(kv.second); }
	show_page("home");
}

void CityPhone::set_map(Control *p_map, Button *p_pin) {
	build();
	map_page = p_map; b_pin = p_pin;
	if (p_map->get_parent()) p_map->get_parent()->remove_child(p_map);
	p_map->set_anchors_and_offsets_preset(Control::PRESET_FULL_RECT);
	body->add_child(p_map);
	pages["map"] = p_map;
	if (b_pin) { if (b_pin->get_parent()) b_pin->get_parent()->remove_child(b_pin); b_close->get_parent()->add_child(b_pin); b_close->get_parent()->move_child(b_pin, 2); }
	show_page(cur);
}

Control *CityPhone::waiting_page(const App &a) {
	MarginContainer *m = memnew(MarginContainer);
	for (const char *side : { "margin_left", "margin_right", "margin_top" }) m->add_theme_constant_override(side, 16);
	VBoxContainer *v = memnew(VBoxContainer); v->add_theme_constant_override("separation", 6);
	Label *l = plate::label(a.waits_en, plate::FS_BODY, plate::TEXT, 700); l->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART);
	Label *t = plate::caps(a.waits_tr); t->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART);
	v->add_child(l); v->add_child(t);
	m->add_child(v);
	return m;
}

Control *CityPhone::page(const String &id) {
	auto it = pages.find(id);
	if (it != pages.end()) return it->second;
	const App *a = app_of(id);
	Control *p = nullptr;
	if (a && !a->waits_en.is_empty()) p = waiting_page(*a);
	else if (id == "camera") {
		VBoxContainer *v = memnew(VBoxContainer); v->add_theme_constant_override("separation", 12);
		Button *shot = plate::dual_button("Take photo", String::utf8("Fotoğraf çek"), "green", "", false);
		shot->set_custom_minimum_size(Vector2(0, plate::TOUCH));
		shot->connect("pressed", callable_mp(this, &CityPhone::take_photo));
		v->add_child(shot);
		cam_note = plate::label("", plate::FS_HELP, plate::DIM, 600); cam_note->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART);
		v->add_child(cam_note);
		Button *gal = plate::dual_button("Photos", String::utf8("Fotoğraflar"), "raised", "", true);
		gal->set_custom_minimum_size(Vector2(0, plate::TOUCH));
		gal->connect("pressed", callable_mp(this, &CityPhone::open_app).bind("photos"));
		v->add_child(gal);
		p = v;
	} else if (id == "photos") {
		ScrollContainer *sc = memnew(ScrollContainer); sc->set_horizontal_scroll_mode(ScrollContainer::SCROLL_MODE_DISABLED);
		gallery = memnew(GridContainer); gallery->set_columns(4); gallery->set_h_size_flags(Control::SIZE_EXPAND_FILL);
		gallery->add_theme_constant_override("h_separation", 8); gallery->add_theme_constant_override("v_separation", 8);
		sc->add_child(gallery);
		p = sc;
	} else if (id == "photo") {
		photo_full = memnew(TextureRect);
		photo_full->set_expand_mode(TextureRect::EXPAND_IGNORE_SIZE); photo_full->set_stretch_mode(TextureRect::STRETCH_KEEP_ASPECT_CENTERED);
		p = photo_full;
	} else if (id == "contacts" || id == "messages" || id == "thread") {
		ScrollContainer *sc = memnew(ScrollContainer); sc->set_horizontal_scroll_mode(ScrollContainer::SCROLL_MODE_DISABLED);
		VBoxContainer *v = memnew(VBoxContainer); v->add_theme_constant_override("separation", 8); v->set_h_size_flags(Control::SIZE_EXPAND_FILL);
		sc->add_child(v);
		if (id == "contacts") contact_list = v; else if (id == "messages") thread_list = v; else thread_view = v;
		p = sc;
	} else if (id == "call") {
		VBoxContainer *v = memnew(VBoxContainer); v->add_theme_constant_override("separation", 14); v->set_alignment(BoxContainer::ALIGNMENT_CENTER);
		call_name = plate::label("", plate::FS_DISPLAY, plate::TEXT, 800); call_name->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER);
		call_line = plate::label("", plate::FS_BODY, plate::DIM, 600); call_line->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER);
		v->add_child(call_name); v->add_child(call_line);
		HBoxContainer *h = memnew(HBoxContainer); h->set_alignment(BoxContainer::ALIGNMENT_CENTER); h->add_theme_constant_override("separation", 24);
		b_decline = plate::dual_button("Decline", "Reddet", "raised"); b_decline->set_custom_minimum_size(Vector2(200, plate::TOUCH));
		b_answer = plate::dual_button("Answer", "Cevapla", "green"); b_answer->set_custom_minimum_size(Vector2(200, plate::TOUCH));
		b_hang = plate::dual_button("Hang up", "Kapat", "raised"); b_hang->set_custom_minimum_size(Vector2(200, plate::TOUCH));
		b_decline->connect("pressed", callable_mp(this, &CityPhone::hang_up));
		b_answer->connect("pressed", callable_mp(this, &CityPhone::answer));
		b_hang->connect("pressed", callable_mp(this, &CityPhone::hang_up));
		h->add_child(b_decline); h->add_child(b_answer); h->add_child(b_hang);
		v->add_child(h);
		p = v;
	} else if (id == "settings") {
		CityGame *g = CityGame::get();
		ScrollContainer *sc = memnew(ScrollContainer); sc->set_horizontal_scroll_mode(ScrollContainer::SCROLL_MODE_DISABLED);
		if (g) { Control *sp = g->make_settings_panel(callable_mp(this, &CityPhone::go_home)); sp->set_h_size_flags(Control::SIZE_EXPAND_FILL); sc->add_child(sp); }
		else sc->add_child(plate::label("No game: no settings.", plate::FS_BODY));
		p = sc;
	}
	if (!p) return nullptr;
	p->set_anchors_and_offsets_preset(Control::PRESET_FULL_RECT);
	p->set_visible(false);
	body->add_child(p);
	pages[id] = p;
	return p;
}

void CityPhone::show_page(const String &id) {
	for (auto &kv : pages) kv.second->set_visible(kv.first == id);
	const App *a = app_of(id);
	String en = "PHONE", tr = "TELEFON";
	if (a) { en = a->en.to_upper(); tr = a->tr.to_upper(); }
	else if (id == "call") { en = "CALL"; tr = "ARAMA"; }
	else if (id == "photo") { en = "PHOTO"; tr = String::utf8("FOTOĞRAF"); }
	else if (id == "thread") { en = thread_of.to_upper(); tr = "MESAJLAR"; }
	if (t_en) { t_en->set_text(en); t_tr->set_text(tr); }
	if (b_back) b_back->set_visible(id != "home" && id != "call");
	if (b_pin) b_pin->set_visible(id == "map");
}

void CityPhone::open_app(const String &p_id) {
	build();
	String id = p_id;
	if (id == "map" && !map_page) id = "home";
	if (call_state != 0 && id != "call") { cur = "call"; show_page("call"); return; }   // (a call takes the screen)
	if (!page(id)) id = "home";
	if (id != cur && id != "home" && id != "call" && hud) hud->stinger("app_tap");
	cur = id;
	if (id == "photos") refresh_gallery();
	if (id == "contacts") refresh_contacts();
	if (id == "messages") refresh_threads();
	if (id == "thread") refresh_thread();
	if (id == "camera" && cam_note) cam_note->set_text(last_photo.is_empty() ? String("The view as you see it, without the buttons.") : String("Saved: ") + last_photo.get_file());
	show_page(id);
}

PackedStringArray CityPhone::get_apps() const { PackedStringArray r; for (const App &a : apps) r.push_back(a.id); return r; }
bool CityPhone::app_waits(const String &p_id) const { const App *a = app_of(p_id); return a && !a->waits_en.is_empty(); }

// ---------------------------------------------------------------- data (the save's "phone")
Dictionary CityPhone::data() const { CityGame *g = CityGame::get(); return g ? g->get_phone_data() : local; }
void CityPhone::set_data(const Dictionary &d) { CityGame *g = CityGame::get(); if (g) g->set_phone_data(d); else local = d; }

// ---------------------------------------------------------------- camera and photos
void CityPhone::take_photo() {
	if (photo_frames >= 0) return;
	tap_feedback();
	if (hud) hud->stinger("camera_shutter");
	photo_frames = 0;
	if (hud) hud->photo_hide = 3;   // (the HUD and this phone are not in the photo)
}

void CityPhone::_process(double p_delta) {
	if (call_state == 2) {
		call_t += p_delta;
		if (call_line) call_line->set_text(String("On call  ") + String::num_int64((int64_t)call_t / 60) + String(":") + String::num_int64((int64_t)call_t % 60).pad_zeros(2));
	}
	if (photo_frames < 0) return;
	if (++photo_frames < 3) return;   // (two frames drawn without the HUD)
	photo_frames = -1;
	Viewport *vp = get_viewport();
	Ref<Image> im = vp && vp->get_texture().is_valid() ? vp->get_texture()->get_image() : Ref<Image>();
	if (im.is_null() || im->is_empty()) { if (cam_note) cam_note->set_text("No picture (no screen)."); return; }
	if (im->get_width() > 1280) im->resize(1280, (int)((double)im->get_height() * 1280.0 / (double)im->get_width()), Image::INTERPOLATE_BILINEAR);
	DirAccess::make_dir_recursive_absolute(PHOTO_DIR());
	const Dictionary dt = Time::get_singleton()->get_datetime_dict_from_system();
	const String name = String("photo_") + String::num_int64((int64_t)dt["year"]) + String::num_int64((int64_t)dt["month"]).pad_zeros(2) + String::num_int64((int64_t)dt["day"]).pad_zeros(2) +
			String("_") + String::num_int64((int64_t)dt["hour"]).pad_zeros(2) + String::num_int64((int64_t)dt["minute"]).pad_zeros(2) + String::num_int64((int64_t)dt["second"]).pad_zeros(2) +
			String("_") + String::num_int64((int64_t)(Time::get_singleton()->get_ticks_msec() % 1000)).pad_zeros(3) + String(".png");
	const String path = PHOTO_DIR() + String("/") + name;
	if (im->save_png(path) != OK) { if (cam_note) cam_note->set_text("Could not save the photo."); return; }
	last_photo = path;
	Dictionary d = data();
	PackedStringArray ph = d.get("photos", PackedStringArray());
	ph.push_back(path);
	d["photos"] = ph; set_data(d);
	if (cam_note) cam_note->set_text(String("Saved: ") + name);
	if (cur == "photos") refresh_gallery();
}

PackedStringArray CityPhone::get_photos() const { return data().get("photos", PackedStringArray()); }

void CityPhone::refresh_gallery() {
	if (!gallery) return;
	for (int i = gallery->get_child_count() - 1; i >= 0; i--) { Node *n = gallery->get_child(i); gallery->remove_child(n); n->queue_free(); }
	const PackedStringArray ph = get_photos();
	if (ph.is_empty()) { gallery->add_child(plate::label("No photos yet", plate::FS_BODY, plate::TEXT, 700)); gallery->add_child(plate::caps(String::utf8("HENÜZ FOTOĞRAF YOK"))); return; }
	for (int i = ph.size() - 1; i >= 0; i--) {   // newest first
		const String p = ph[i];
		Ref<ImageTexture> tex;
		auto it = thumbs.find(p);
		if (it != thumbs.end()) tex = it->second;
		else {
			Ref<Image> im = Image::load_from_file(p);
			if (im.is_null() || im->is_empty()) continue;
			im->resize(240, (int)(240.0 * (double)im->get_height() / (double)im->get_width()), Image::INTERPOLATE_BILINEAR);
			tex = ImageTexture::create_from_image(im); thumbs[p] = tex;
		}
		Button *b = memnew(Button);
		b->set_button_icon(tex); b->set_expand_icon(true); b->set_custom_minimum_size(Vector2(150, 90)); b->set_h_size_flags(Control::SIZE_EXPAND_FILL);
		b->set_flat(true);
		b->connect("pressed", callable_mp(this, &CityPhone::view_photo).bind(p));
		gallery->add_child(b);
	}
}

void CityPhone::view_photo(const String &p_path) {
	tap_feedback();
	page("photo");
	Ref<Image> im = Image::load_from_file(p_path);
	if (photo_full && im.is_valid() && !im->is_empty()) photo_full->set_texture(ImageTexture::create_from_image(im));
	cur = "photo"; show_page("photo");
}

// ---------------------------------------------------------------- contacts and messages
void CityPhone::add_contact(const String &p_id, const String &p_name, const String &p_number, const String &p_note) {
	Dictionary d = data();
	Array cs = d.get("contacts", Array());
	for (int i = 0; i < cs.size(); i++) if (String(((Dictionary)cs[i]).get("id", "")) == p_id) { cs.remove_at(i); break; }
	Dictionary c; c["id"] = p_id; c["name"] = p_name; c["number"] = p_number; c["note"] = p_note;
	cs.push_back(c); d["contacts"] = cs; set_data(d);
	if (cur == "contacts") refresh_contacts();
}

Array CityPhone::get_contacts() const { return data().get("contacts", Array()); }

static String name_of(const Array &cs, const String &id) {
	for (int i = 0; i < cs.size(); i++) { const Dictionary c = cs[i]; if (String(c.get("id", "")) == id) return c.get("name", id); }
	return id;
}

void CityPhone::receive_message(const String &p_contact, const String &p_en, const String &p_tr) {
	Dictionary d = data();
	Dictionary th = d.get("threads", Dictionary());
	Array t = th.get(p_contact, Array());
	Dictionary m; m["in"] = true; m["en"] = p_en; m["tr"] = p_tr; m["at"] = Time::get_singleton()->get_unix_time_from_system();
	t.push_back(m); th[p_contact] = t; d["threads"] = th; set_data(d);
	if (hud) hud->stinger("msg_ping");
	emit_signal("message_received", p_contact, p_en);
	if (cur == "messages") refresh_threads();
	if (cur == "thread" && thread_of == p_contact) refresh_thread();
}

void CityPhone::send_message(const String &p_contact, const String &p_en, const String &p_tr) {
	Dictionary d = data();
	Dictionary th = d.get("threads", Dictionary());
	Array t = th.get(p_contact, Array());
	Dictionary m; m["in"] = false; m["en"] = p_en; m["tr"] = p_tr; m["at"] = Time::get_singleton()->get_unix_time_from_system();
	t.push_back(m); th[p_contact] = t; d["threads"] = th; set_data(d);
	emit_signal("message_sent", p_contact, p_en);
	if (cur == "thread" && thread_of == p_contact) refresh_thread();
}

Array CityPhone::get_thread(const String &p_contact) const { return ((Dictionary)data().get("threads", Dictionary())).get(p_contact, Array()); }

void CityPhone::open_thread(const String &p_contact) { tap_feedback(); thread_of = p_contact; page("thread"); open_app("thread"); }

void CityPhone::refresh_contacts() {
	if (!contact_list) return;
	for (int i = contact_list->get_child_count() - 1; i >= 0; i--) { Node *n = contact_list->get_child(i); contact_list->remove_child(n); n->queue_free(); }
	const Array cs = get_contacts();
	if (cs.is_empty()) { contact_list->add_child(plate::label("No contacts yet", plate::FS_BODY, plate::TEXT, 700)); contact_list->add_child(plate::caps(String::utf8("HENÜZ KİŞİ YOK"))); return; }
	for (int i = 0; i < cs.size(); i++) {
		const Dictionary c = cs[i];
		Button *b = plate::dual_button(c.get("name", ""), String(c.get("number", "")) + (String(c.get("note", "")).is_empty() ? String() : String("  ") + String(c.get("note", ""))), "raised", "", true);
		b->set_custom_minimum_size(Vector2(0, plate::TOUCH));
		b->connect("pressed", callable_mp(this, &CityPhone::open_thread).bind(c.get("id", "")));
		contact_list->add_child(b);
	}
}

void CityPhone::refresh_threads() {
	if (!thread_list) return;
	for (int i = thread_list->get_child_count() - 1; i >= 0; i--) { Node *n = thread_list->get_child(i); thread_list->remove_child(n); n->queue_free(); }
	const Dictionary th = data().get("threads", Dictionary());
	const Array cs = get_contacts();
	if (th.is_empty()) { thread_list->add_child(plate::label("No messages yet", plate::FS_BODY, plate::TEXT, 700)); thread_list->add_child(plate::caps(String::utf8("HENÜZ MESAJ YOK"))); return; }
	const Array keys = th.keys();
	for (int i = 0; i < keys.size(); i++) {
		const Array t = th[keys[i]];
		const String last = t.is_empty() ? String() : String(((Dictionary)t[t.size() - 1]).get("en", ""));
		Button *b = plate::dual_button(name_of(cs, keys[i]), last, "raised", "", true);
		b->set_custom_minimum_size(Vector2(0, plate::TOUCH));
		b->connect("pressed", callable_mp(this, &CityPhone::open_thread).bind(keys[i]));
		thread_list->add_child(b);
	}
}

void CityPhone::refresh_thread() {
	if (!thread_view) return;
	for (int i = thread_view->get_child_count() - 1; i >= 0; i--) { Node *n = thread_view->get_child(i); thread_view->remove_child(n); n->queue_free(); }
	const Array t = get_thread(thread_of);
	if (t.is_empty()) { thread_view->add_child(plate::label("No messages yet", plate::FS_BODY, plate::TEXT, 700)); return; }
	for (int i = 0; i < t.size(); i++) {   // a bubble a line: theirs on the left, dark; his on the right, green; English over Turkish
		const Dictionary m = t[i];
		const bool in = m.get("in", true);
		HBoxContainer *row = memnew(HBoxContainer);
		PanelContainer *bub = plate::panel(in ? "raised" : "green_lo");
		bub->set_custom_minimum_size(Vector2(0, 0)); bub->set_h_size_flags(Control::SIZE_SHRINK_BEGIN);
		MarginContainer *mc = memnew(MarginContainer);
		for (const char *side : { "margin_left", "margin_right", "margin_top", "margin_bottom" }) mc->add_theme_constant_override(side, 10);
		VBoxContainer *v = memnew(VBoxContainer);
		Label *en = plate::label(m.get("en", ""), plate::FS_BODY, plate::TEXT, 600); en->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART); en->set_custom_minimum_size(Vector2(380, 0));
		v->add_child(en);
		if (!String(m.get("tr", "")).is_empty()) { Label *tr = plate::label(m.get("tr", ""), plate::FS_HELP, plate::DIM, 600); tr->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART); tr->set_custom_minimum_size(Vector2(380, 0)); v->add_child(tr); }
		mc->add_child(v); bub->add_child(mc);
		Control *sp = memnew(Control); sp->set_h_size_flags(Control::SIZE_EXPAND_FILL);
		if (in) { row->add_child(bub); row->add_child(sp); } else { row->add_child(sp); row->add_child(bub); }
		thread_view->add_child(row);
	}
}

// ---------------------------------------------------------------- a call
// the ring (one recorded ring cycle, looped) until he answers or declines
void CityPhone::ringtone(bool p_on) {
	AudioStreamPlayer *a = Object::cast_to<AudioStreamPlayer>(get_node_or_null(NodePath("Ringtone")));
	if (!p_on) { if (a) a->stop(); return; }
	if (!a) {
		a = memnew(AudioStreamPlayer); a->set_name("Ringtone"); add_child(a);
	}
	Ref<AudioStream> st = elsfx::pick("res://audio/ui/ringtone_", 0, 1, true);
	if (st.is_null()) return;
	a->set_stream(st); a->set_volume_db(-4.0f); a->play();
}

void CityPhone::ring(const String &p_caller) {
	caller = p_caller; call_state = 1; call_t = 0.0;
	if (cur != "call") before_call = cur;
	page("call");
	call_name->set_text(p_caller); call_line->set_text("Incoming call");
	b_answer->set_visible(true); b_decline->set_visible(true); b_hang->set_visible(false);
	cur = "call"; show_page("call");
	if (hud) hud->open_phone();
	ringtone(true);
	emit_signal("call_ringing", p_caller);
}

void CityPhone::answer() {
	if (call_state != 1) return;
	tap_feedback();
	call_state = 2; call_t = 0.0;
	ringtone(false);
	b_answer->set_visible(false); b_decline->set_visible(false); b_hang->set_visible(true);
	emit_signal("call_answered", caller);
}

void CityPhone::hang_up() {
	if (call_state == 0) return;
	tap_feedback();
	const bool was_on = call_state == 2;
	call_state = 0;
	ringtone(false);
	emit_signal("call_ended", caller, was_on);
	open_app(before_call == "call" ? String("home") : before_call);
}

void CityPhone::_bind_methods() {
	ClassDB::bind_method(D_METHOD("open_app", "id"), &CityPhone::open_app);
	ClassDB::bind_method(D_METHOD("go_home"), &CityPhone::go_home);
	ClassDB::bind_method(D_METHOD("get_app"), &CityPhone::get_app);
	ClassDB::bind_method(D_METHOD("get_apps"), &CityPhone::get_apps);
	ClassDB::bind_method(D_METHOD("app_waits", "id"), &CityPhone::app_waits);
	ClassDB::bind_method(D_METHOD("take_photo"), &CityPhone::take_photo);
	ClassDB::bind_method(D_METHOD("is_taking_photo"), &CityPhone::is_taking_photo);
	ClassDB::bind_method(D_METHOD("get_last_photo"), &CityPhone::get_last_photo);
	ClassDB::bind_method(D_METHOD("get_photos"), &CityPhone::get_photos);
	ClassDB::bind_method(D_METHOD("view_photo", "path"), &CityPhone::view_photo);
	ClassDB::bind_method(D_METHOD("add_contact", "id", "name", "number", "note"), &CityPhone::add_contact);
	ClassDB::bind_method(D_METHOD("get_contacts"), &CityPhone::get_contacts);
	ClassDB::bind_method(D_METHOD("receive_message", "contact", "en", "tr"), &CityPhone::receive_message);
	ClassDB::bind_method(D_METHOD("send_message", "contact", "en", "tr"), &CityPhone::send_message);
	ClassDB::bind_method(D_METHOD("get_thread", "contact"), &CityPhone::get_thread);
	ClassDB::bind_method(D_METHOD("open_thread", "contact"), &CityPhone::open_thread);
	ClassDB::bind_method(D_METHOD("ring", "caller"), &CityPhone::ring);
	ClassDB::bind_method(D_METHOD("answer"), &CityPhone::answer);
	ClassDB::bind_method(D_METHOD("hang_up"), &CityPhone::hang_up);
	ClassDB::bind_method(D_METHOD("get_call_state"), &CityPhone::get_call_state);
	ADD_SIGNAL(MethodInfo("message_received", PropertyInfo(Variant::STRING, "contact"), PropertyInfo(Variant::STRING, "en")));
	ADD_SIGNAL(MethodInfo("message_sent", PropertyInfo(Variant::STRING, "contact"), PropertyInfo(Variant::STRING, "en")));
	ADD_SIGNAL(MethodInfo("call_ringing", PropertyInfo(Variant::STRING, "caller")));
	ADD_SIGNAL(MethodInfo("call_answered", PropertyInfo(Variant::STRING, "caller")));
	ADD_SIGNAL(MethodInfo("call_ended", PropertyInfo(Variant::STRING, "caller"), PropertyInfo(Variant::BOOL, "answered")));
}

} // namespace godot
