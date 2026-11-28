// CityGame: the screens, the clock and the way into the world (see city_game.h). Every control is built here with
// ui_plate, after the old game's loading_screen.gd, main_menu.gd, pause_menu.gd, game_over.gd and settings_panel.gd.
#include "perf_marks.h"
#include "city_game.h"

#include "ui_plate.h"
#include "city_hud.h"

#include <godot_cpp/classes/display_server.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/grid_container.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/classes/viewport_texture.hpp>
#include <godot_cpp/classes/h_box_container.hpp>
#include <godot_cpp/classes/input_event_key.hpp>
#include <godot_cpp/classes/margin_container.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/scroll_container.hpp>
#include <godot_cpp/classes/texture_rect.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/window.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/callable_method_pointer.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <cmath>
#include <thread>

namespace godot {

using namespace plate;

namespace {
Control *gap(float h) { Control *c = memnew(Control); c->set_custom_minimum_size(Vector2(0, h)); c->set_mouse_filter(Control::MOUSE_FILTER_IGNORE); return c; }
Array one_arg(const Variant &v) { Array a; a.push_back(v); return a; }
} // namespace

void CityGame::on_any(Object *b, const std::function<void()> &f) {
	actions.push_back(f);
	b->connect("pressed", Callable(callable_mp(this, &CityGame::_act)).bind((int)actions.size() - 1));
}

// ---------------------------------------------------------------- the run
void CityGame::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) return;
	set_process_mode(PROCESS_MODE_ALWAYS);
	load_text();
	settings_defaults(); load_device(); apply_settings();
	{   // (Yasin, 28 Nov: "dpi settings are too high on phones, menu looks very very small. some of my friends couldnt read
		// what was written at all") the menus, the pause screen, the phone and every panel are laid out in fixed pixels:
		// on a phone 1080 px high they were drawn a third of the size they were made for. The whole 2D layer is scaled so the
		// shorter side of the screen counts as 480 px. The HUD lays itself out from the visible rectangle (ui_plate's ui_k),
		// which the scale shrinks by the same factor, so its plates keep their size on the screen (480 px: the Redmi 2.25x). `-- --uiscale=X` tries a
		// factor on a PC.
		Window *root = get_tree()->get_root();
		double f = 0.0;
		const PackedStringArray ua = OS::get_singleton()->get_cmdline_user_args();
		for (int i = 0; i < ua.size(); i++) if (ua[i].begins_with("--uiscale=")) f = ua[i].trim_prefix("--uiscale=").to_float();
		if (f <= 0.0 && OS::get_singleton()->has_feature("android")) {
			const Vector2i ws = DisplayServer::get_singleton()->window_get_size();
			f = std::max(1.0, (double)std::min(ws.x, ws.y) / 480.0);
		}
		if (f > 0.0 && root) root->set_content_scale_factor((float)f);
	}
	build_loading(); build_menu(); build_pause(); build_over();
	hud = memnew(CityHud);   // (the HUD shows itself only in play: CityHud::_process asks is_playing)
	add_child(hud);
	// the shell outlives every scene: it moves to the root (the boot scene is freed when the world comes)
	if (get_parent() && get_parent() != get_tree()->get_root()) { get_parent()->call_deferred("remove_child", this); get_tree()->get_root()->call_deferred("add_child", this); }
	set_process(true); set_process_unhandled_input(true);
	callable_mp(this, &CityGame::open_menu).call_deferred();
}

// The start's hold asks the world's collision (the ground under him): only in the physics step (the phones' physics thread)
void CityGame::_physics_process(double p_delta) {
	if (start_hold >= 0.0) hold_start(p_delta);
}

void CityGame::_process(double p_delta) {
	pm::Scope _pm(pm::GAME);   // (the slow-frame marks, perf_marks.h)
	SceneTree *tr = get_tree();
	const bool paused = tr && tr->is_paused();
	if (clock_running && !paused && world_on) {   // the game's clock: one game hour is ten real minutes
		const int m0 = (int)std::floor(hour * 60.0);
		hour += p_delta * time_scale / 3600.0;
		if (hour >= 24.0) { hour -= 24.0; day++; emit_signal("day_changed", day); }
		const int m1 = (int)std::floor(hour * 60.0);
		if (m1 != m0) { emit_signal("minute_changed", day, hhmm()); emit_signal("time_changed", hour); }
	}
	if (active_slot >= 0 && world_on && !paused && autosave_s > 0.0) {
		autosave_t += p_delta;
		if (autosave_t >= autosave_s) save();
	}
	if (play_phase) step_play(p_delta);
	if (ld_fade >= 0.0 && ld_root) {   // the loading screen fades off the picture into the live world
		// B21 (Yasin 20 Nov: "CONTINUE AFTER LOADING SNAPS BACK TO THE GAME HARD, AND JITTER A BIT"): the first frames in the
		// world are the heaviest and one long frame skipped most of a linear 0.8 s fade. Now at most a 30 fps step a frame,
		// eased in and out, over 1.2 s.
		ld_fade += std::min(p_delta, 1.0 / 30.0);
		const double u = std::min(1.0, ld_fade / 1.2);
		const double a = 1.0 - u * u * (3.0 - 2.0 * u);
		if (a <= 0.0) { loading->set_visible(false); ld_root->set_modulate(Color(1, 1, 1, 1)); ld_root->set_mouse_filter(Control::MOUSE_FILTER_STOP); ld_fade = -1.0; }
		else ld_root->set_modulate(Color(1, 1, 1, (float)a));
	}
}

void CityGame::_unhandled_input(const Ref<InputEvent> &p_event) {
	const InputEventKey *k = Object::cast_to<InputEventKey>(p_event.ptr());
	if (!k || !k->is_pressed() || k->is_echo() || k->get_keycode() != KEY_ESCAPE) return;
	if (pause_open) { if (pause_settings && pause_settings->is_visible()) { pause_settings->set_visible(false); pause_list->set_visible(true); } else close_pause(); }
	else if (world_on && !menu_open && !over_open && play_phase == 0) open_pause();
}

void CityGame::_notification(int p_what) {
	if ((p_what == NOTIFICATION_WM_CLOSE_REQUEST || p_what == NOTIFICATION_APPLICATION_PAUSED) && active_slot >= 0 && world_on && play_phase == 0) save();
	if (p_what == NOTIFICATION_WM_GO_BACK_REQUEST) {   // the Android back button: as Esc
		if (pause_open) close_pause(); else if (world_on && !menu_open && !over_open && play_phase == 0) open_pause();
	}
}

Object *CityGame::get_hud() const { return hud; }

// ---------------------------------------------------------------- the loading screen
void CityGame::build_loading() {
	loading = memnew(CanvasLayer);
	loading->set_layer(120);
	loading->set_process_mode(PROCESS_MODE_ALWAYS);
	add_child(loading);
	ColorRect *bg = memnew(ColorRect);
	bg->set_color(BLACK); bg->set_anchors_preset(Control::PRESET_FULL_RECT); bg->set_mouse_filter(Control::MOUSE_FILTER_STOP);
	loading->add_child(bg);
	ld_root = bg;
	ld_pic = memnew(TextureRect);
	ld_pic->set_expand_mode(TextureRect::EXPAND_IGNORE_SIZE); ld_pic->set_stretch_mode(TextureRect::STRETCH_KEEP_ASPECT_COVERED);
	ld_pic->set_anchors_preset(Control::PRESET_FULL_RECT); ld_pic->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
	bg->add_child(ld_pic);
	ColorRect *shade = memnew(ColorRect);   // (behind the words at the bottom, so they read over any picture)
	shade->set_color(Color(0, 0, 0, 0.5f)); shade->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
	shade->set_anchor(SIDE_LEFT, 0); shade->set_anchor(SIDE_RIGHT, 1); shade->set_anchor(SIDE_TOP, 1); shade->set_anchor(SIDE_BOTTOM, 1);
	shade->set_offset(SIDE_TOP, -250);
	bg->add_child(shade);
	VBoxContainer *v = memnew(VBoxContainer);
	v->add_theme_constant_override("separation", 10);
	v->set_anchor(SIDE_LEFT, 0); v->set_anchor(SIDE_RIGHT, 1); v->set_anchor(SIDE_TOP, 1); v->set_anchor(SIDE_BOTTOM, 1);
	v->set_offset(SIDE_LEFT, 56); v->set_offset(SIDE_RIGHT, -56); v->set_offset(SIDE_BOTTOM, -48);
	v->set_v_grow_direction(Control::GROW_DIRECTION_BEGIN);
	bg->add_child(v);
	v->add_child(label(en("menu.title"), FS_DISPLAY, TEXT, 800));
	const String h = helper_text("menu.title");
	if (!h.is_empty()) v->add_child(caps(h));
	v->add_child(gap(16));
	ld_status = label(dual("loading.text"), FS_BODY);
	v->add_child(ld_status);
	ld_bar = memnew(ProgressBar);
	ld_bar->set_min(0); ld_bar->set_max(100); ld_bar->set_show_percentage(false);
	ld_bar->set_custom_minimum_size(Vector2(0, 6));
	ld_bar->add_theme_stylebox_override("background", box("track")); ld_bar->add_theme_stylebox_override("fill", box("fill"));
	v->add_child(ld_bar);
	const int tip = 1 + (int)(UtilityFunctions::randi() % 5u);
	Label *t = label(dual(vformat("loading.tip%d", tip)), FS_HELP, DIM);
	t->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART);
	v->add_child(t);
	loading->set_visible(false);
}

void CityGame::open_loading() {
	if (!loading) return;
	ld_bar->set_value(0); ld_status->set_text(dual("loading.text"));
	ld_pic->set_texture(slot_picture(ld_slot));   // the save's picture, or black
	ld_fade = -1.0; ld_root->set_modulate(Color(1, 1, 1, 1)); ld_root->set_mouse_filter(Control::MOUSE_FILTER_STOP);
	loading->set_visible(true);
}
void CityGame::set_loading(double p_p, const String &p_key) {
	if (!loading) return;
	ld_bar->set_value(std::min(std::max(p_p, 0.0), 1.0) * 100.0);
	if (!p_key.is_empty()) ld_status->set_text(dual(p_key));
}
void CityGame::close_loading() {
	if (!loading || !loading->is_visible() || ld_fade >= 0.0) return;
	if (!world_on) { loading->set_visible(false); return; }   // (back to the menu: at once)
	ld_fade = 0.0; ld_root->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);   // into the world: a fade off the picture
}

String CityGame::shot_path(int s) const { return saves_dir + vformat("slot_%d.jpg", s); }
bool CityGame::has_picture(int p_slot) const { return p_slot >= 0 && FileAccess::file_exists(shot_path(p_slot)); }

Ref<Texture2D> CityGame::slot_picture(int s) const {
	if (!has_picture(s)) return Ref<Texture2D>();
	Ref<Image> im = Image::load_from_file(shot_path(s));
	if (im.is_null() || im->is_empty()) return Ref<Texture2D>();
	return ImageTexture::create_from_image(im);
}

// The frame on screen, made 640 wide, written as the slot's jpg. The main thread only reads the frame back from the GPU
// (once per save, a minute at most; timed in shot_ms); shrinking and writing it run on a thread of their own. A headless
// run has no frame: no picture.
bool CityGame::take_shot() {
	if (active_slot < 0 || !is_inside_tree() || shot_busy.load()) return false;
	const uint64_t t0 = Time::get_singleton()->get_ticks_usec();
	Viewport *vp = get_viewport();
	Ref<ViewportTexture> vt = vp ? vp->get_texture() : Ref<ViewportTexture>();
	Ref<Image> im = vt.is_valid() ? vt->get_image() : Ref<Image>();
	if (im.is_null() || im->is_empty() || im->get_width() < 16) return false;
	shot_ms = (double)(Time::get_singleton()->get_ticks_usec() - t0) / 1000.0;
	const String path = shot_path(active_slot);
	shot_busy.store(1); shots++;
	std::thread([this, im, path]() {
		const int w = 640, h = std::max(1, (int)std::lround(im->get_height() * 640.0 / im->get_width()));
		im->resize(w, h, Image::INTERPOLATE_BILINEAR);
		im->save_jpg(path, 0.85f);
		shot_busy.store(0);
	}).detach();
	return true;
}

// ---------------------------------------------------------------- the main menu
Button *CityGame::menu_row(const String &key, const String &icon_name, bool chevron, const std::function<void()> &f) {
	Button *b = dual_from(dual(key, Array(), "\n"), "raised", icon_name, chevron);
	b->set_custom_minimum_size(Vector2(0, 96));
	b->set_meta("key", key);
	on_any(b, f);
	return b;
}

void CityGame::build_menu() {
	menu = memnew(CanvasLayer);
	menu->set_layer(70);
	menu->set_process_mode(PROCESS_MODE_ALWAYS);
	add_child(menu);
	menu_bg = memnew(ColorRect);
	menu_bg->set_color(BLACK); menu_bg->set_anchors_preset(Control::PRESET_FULL_RECT);
	menu->add_child(menu_bg);
	TextureRect *art = memnew(TextureRect);
	art->set_expand_mode(TextureRect::EXPAND_IGNORE_SIZE); art->set_stretch_mode(TextureRect::STRETCH_KEEP_ASPECT_COVERED);
	art->set_anchors_preset(Control::PRESET_FULL_RECT); art->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
	menu_bg->add_child(art);
	menu_bg_art = art;
	ScrollContainer *page = memnew(ScrollContainer);
	page->set_anchors_preset(Control::PRESET_FULL_RECT);
	page->set_horizontal_scroll_mode(ScrollContainer::SCROLL_MODE_DISABLED);
	menu_bg->add_child(page);
	HBoxContainer *hb = memnew(HBoxContainer);
	hb->set_h_size_flags(Control::SIZE_EXPAND_FILL); hb->set_v_size_flags(Control::SIZE_EXPAND_FILL);
	page->add_child(hb);
	PanelContainer *sheet = panel("screen");
	sheet->set_v_size_flags(Control::SIZE_EXPAND_FILL);
	hb->add_child(sheet);
	menu_sheet = sheet;
	MarginContainer *mc = memnew(MarginContainer);
	mc->add_theme_constant_override("margin_left", 32); mc->add_theme_constant_override("margin_right", 32);
	mc->add_theme_constant_override("margin_top", 28); mc->add_theme_constant_override("margin_bottom", 16);
	sheet->add_child(mc);
	menu_stack = memnew(VBoxContainer);
	menu_stack->add_theme_constant_override("separation", 8);
	mc->add_child(menu_stack);
	Button *back_btn = nullptr;
	auto back = [&](const String &to) {
		back_btn = dual_from(dual("menu.back", Array(), "\n"), "plate", "back");
		back_btn->set_custom_minimum_size(Vector2(200, 72)); back_btn->set_h_size_flags(Control::SIZE_SHRINK_BEGIN);
		back_btn->set_meta("key", "menu.back");
		on_any(back_btn, [this, to]() { show_screen(to); });
		return back_btn;
	};
	auto title = [&](VBoxContainer *s, const String &key) {
		s->add_child(label(en(key), FS_TITLE, TEXT, 800));
		const String h = helper_text(key);
		if (!h.is_empty() && h != en(key)) s->add_child(caps(h));
	};
	// -- menu
	{
		VBoxContainer *s = memnew(VBoxContainer); s->add_theme_constant_override("separation", 8);
		Label *t = label(en("menu.title"), FS_DISPLAY, TEXT, 800);
		t->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART); t->add_theme_constant_override("line_spacing", -14); t->set_custom_minimum_size(Vector2(392, 0));
		s->add_child(t);
		s->add_child(caps(helper_text("menu.title")));
		s->add_child(gap(8));
		b_new = menu_row("menu.new_game", "", true, [this]() {
			if (is_full()) { picker_overwrite = true; show_screen("picker"); }
			else enter_play([this]() { return new_game(); });
		});
		b_continue = menu_row("menu.continue", "", true, [this]() { const int s = most_recent_slot(); if (s >= 0) enter_play([this, s]() { return continue_game(s); }, s); });
		s->add_child(b_new); s->add_child(b_continue);
		s->add_child(menu_row("menu.lessons", "", true, [this]() { show_screen("lessons"); }));
		s->add_child(menu_row("menu.settings", "", true, [this]() { show_screen("settings"); }));
		menu_notice = label("", FS_HELP, DIM);
		s->add_child(menu_notice);
		s->add_child(gap(12));
		const String bid = FileAccess::get_file_as_string("res://build_id.txt").strip_edges();
		s->add_child(caps(bid.is_empty() ? String("city kit") : bid, OFF));
		menu_stack->add_child(s); screens["menu"] = s;
	}
	// -- lessons (the phone's apps: not here yet)
	{
		VBoxContainer *s = memnew(VBoxContainer); s->add_theme_constant_override("separation", 8);
		title(s, "menu.lessons");
		Label *note = label("", FS_HELP, DIM);
		const char *keys[3] = { "menu.grammar", "menu.vocabulary", "menu.films" }, *icons[3] = { "grammar", "words", "films" };
		for (int k = 0; k < 3; k++) s->add_child(menu_row(keys[k], icons[k], true, [note]() { note->set_text(CityGame::dual("menu.soon")); }));
		s->add_child(note);
		s->add_child(back("menu"));
		menu_stack->add_child(s); screens["lessons"] = s;
	}
	// -- the slot picker
	{
		VBoxContainer *s = memnew(VBoxContainer); s->add_theme_constant_override("separation", 8);
		Label *t = label("", FS_TITLE, TEXT, 800); t->set_name("PickerTitle");
		s->add_child(t);
		ScrollContainer *sc = memnew(ScrollContainer);
		sc->set_custom_minimum_size(Vector2(620, 320)); sc->set_horizontal_scroll_mode(ScrollContainer::SCROLL_MODE_DISABLED);
		picker_list = memnew(VBoxContainer); picker_list->add_theme_constant_override("separation", 8); picker_list->set_h_size_flags(Control::SIZE_EXPAND_FILL);
		sc->add_child(picker_list);
		s->add_child(sc);
		PanelContainer *cf = panel("raised");
		VBoxContainer *cv = memnew(VBoxContainer); cv->add_theme_constant_override("separation", 8);
		confirm_text = label("", FS_BODY); confirm_text->set_custom_minimum_size(Vector2(520, 0)); confirm_text->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART);
		cv->add_child(confirm_text);
		HBoxContainer *ch = memnew(HBoxContainer); ch->add_theme_constant_override("separation", 8);
		Button *yes = dual_from(dual("ui.yes", Array(), "\n"), "green"); yes->set_custom_minimum_size(Vector2(160, 72)); yes->set_meta("key", "ui.yes");
		Button *no = dual_from(dual("ui.no", Array(), "\n"), "plate"); no->set_custom_minimum_size(Vector2(160, 72)); no->set_meta("key", "ui.no");
		on_any(yes, [this]() { confirm->set_visible(false); if (confirm_yes) { auto f = confirm_yes; confirm_yes = nullptr; f(); } });
		on_any(no, [this]() { confirm->set_visible(false); confirm_yes = nullptr; });
		ch->add_child(yes); ch->add_child(no);
		cv->add_child(ch);
		cf->add_child(cv);
		confirm = cf; confirm->set_visible(false);
		s->add_child(cf);
		s->add_child(back("settings"));
		menu_stack->add_child(s); screens["picker"] = s;
	}
	// -- settings (the hub and the panel)
	{
		VBoxContainer *s = memnew(VBoxContainer); s->add_theme_constant_override("separation", 8);
		HBoxContainer *hub = memnew(HBoxContainer); hub->add_theme_constant_override("separation", 8);
		Button *load = dual_from(dual("menu.load_game", Array(), "\n")); load->set_custom_minimum_size(Vector2(220, 72)); load->set_meta("key", "menu.load_game");
		on_any(load, [this]() { picker_overwrite = false; show_screen("picker"); });
		Button *cr = dual_from(dual("menu.credits", Array(), "\n")); cr->set_custom_minimum_size(Vector2(220, 72)); cr->set_meta("key", "menu.credits");
		on_any(cr, [this]() { show_screen("credits"); });
		Button *quit = dual_from(dual("menu.quit", Array(), "\n")); quit->set_custom_minimum_size(Vector2(180, 72)); quit->set_meta("key", "menu.quit");
		on_any(quit, [this]() { get_tree()->quit(); });
		hub->add_child(load); hub->add_child(cr); hub->add_child(quit);
		s->add_child(hub);
		s->add_child(build_settings_panel([this]() { show_screen("menu"); }));
		menu_stack->add_child(s); screens["settings"] = s;
	}
	// -- credits
	{
		VBoxContainer *s = memnew(VBoxContainer); s->add_theme_constant_override("separation", 8);
		title(s, "menu.credits");
		Label *a = label(en("menu.credits_text"), FS_BODY); a->set_custom_minimum_size(Vector2(620, 0)); a->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART);
		s->add_child(a);
		Label *b = label(helper_text("menu.credits_text"), FS_HELP, DIM); b->set_custom_minimum_size(Vector2(620, 0)); b->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART);
		s->add_child(b);
		s->add_child(back("settings"));
		menu_stack->add_child(s); screens["credits"] = s;
	}
	menu->set_visible(false);
}

void CityGame::show_screen(const String &s) {
	for (auto &kv : screens) kv.second->set_visible(String(kv.first.c_str()) == s);
	if (confirm) confirm->set_visible(false);
	const bool narrow = s == "menu" || s == "lessons";
	if (menu_sheet) {
		menu_sheet->set_h_size_flags(narrow ? Control::SIZE_SHRINK_BEGIN : Control::SIZE_EXPAND_FILL);
		menu_sheet->set_custom_minimum_size(Vector2(narrow ? 456.0f : 0.0f, 0));
	}
	if (s == "menu") {
		const bool any = any_save();
		set_disabled(b_continue, !any);
		relook(b_continue, any ? "green" : "raised");
		relook(b_new, any ? "raised" : "green");
	}
	if (s == "picker") {
		Label *t = Object::cast_to<Label>(screens["picker"]->get_node_or_null(NodePath("PickerTitle")));
		if (t) t->set_text(en(picker_overwrite ? "menu.pick_overwrite" : "menu.pick_load"));
		fill_picker();
	}
	if (s == "settings") refresh_settings();
}

String CityGame::current_screen() const {
	if (over_open) return "game_over";
	if (pause_open) return pause_settings && pause_settings->is_visible() ? "pause_settings" : "pause";
	if (loading && loading->is_visible() && ld_fade < 0.0) return "loading";
	if (menu_open) for (auto &kv : screens) if (kv.second->is_visible()) return String(kv.first.c_str());
	return world_on ? "world" : "none";
}

void CityGame::fill_picker() {
	for (int k = picker_list->get_child_count() - 1; k >= 0; k--) { Node *c = picker_list->get_child(k); picker_list->remove_child(c); c->queue_free(); }
	const Array sl = list_slots();
	if (sl.is_empty()) { picker_list->add_child(label(dual("menu.no_saves"), FS_BODY, DIM)); return; }
	for (int k = 0; k < sl.size(); k++) {
		const Dictionary d = sl[k];
		const int slot = d["slot"];
		const String name = d["name"];
		HBoxContainer *row = memnew(HBoxContainer); row->add_theme_constant_override("separation", 8);
		Button *b = dual_button(name, String(d["last_played_text"]), "raised", "contacts", true);
		b->set_custom_minimum_size(Vector2(480, 72)); b->set_h_size_flags(Control::SIZE_EXPAND_FILL);
		b->set_meta("key", vformat("slot_%d", slot));
		if (!picker_overwrite && !(bool)d["has_save"]) set_disabled(b, true);
		on_any(b, [this, slot, name]() {
			if (picker_overwrite) ask(en("menu.confirm_overwrite", one_arg(name)), [this, slot]() { enter_play([this, slot]() { return new_game_overwrite(slot); }); });
			else enter_play([this, slot]() { return continue_game(slot); }, slot);
		});
		Button *del = button("", "raised"); del->set_custom_minimum_size(Vector2(72, 72));
		del->set_button_icon(icon("trash")); del->add_theme_color_override("icon_normal_color", RED); del->set_tooltip_text(String::utf8("Delete / Sil"));
		del->set_meta("key", vformat("delete_%d", slot));
		on_any(del, [this, slot, name]() { ask(en("menu.confirm_delete", one_arg(name)), [this, slot]() { delete_slot(slot); fill_picker(); }); });
		row->add_child(b); row->add_child(del);
		picker_list->add_child(row);
	}
}

void CityGame::ask(const String &text, const std::function<void()> &yes) {
	confirm_text->set_text(text);
	confirm_yes = yes;
	confirm->set_visible(true);
}

void CityGame::open_menu() {
	if (!menu) return;
	menu_open = true;
	get_tree()->set_pause(true);
	menu_bg->set_color(world_on ? Color(0, 0, 0, 0) : BLACK);
	if (!world_on) {
		const Ref<Texture2D> pic = slot_picture(most_recent_slot());
		Object::cast_to<TextureRect>(menu_bg_art)->set_texture(pic);
		menu_bg_art->set_visible(pic.is_valid());
	} else menu_bg_art->set_visible(false);
	if (menu_notice) menu_notice->set_text("");
	menu->set_visible(true);
	show_screen("menu");
}

void CityGame::close_menu() {
	if (!menu) return;
	menu_open = false;
	menu->set_visible(false);
	get_tree()->set_pause(false);
	emit_signal("menu_closed");
}

// ---------------------------------------------------------------- the settings panel
VBoxContainer *CityGame::build_settings_panel(const std::function<void()> &on_back) {
	VBoxContainer *p = memnew(VBoxContainer); p->add_theme_constant_override("separation", 8);
	p->add_child(label(en("menu.settings"), FS_TITLE, TEXT, 800));
	GridContainer *g = memnew(GridContainer); g->set_columns(2); g->add_theme_constant_override("h_separation", 40);
	p->add_child(g);
	VBoxContainer *col[2] = { memnew(VBoxContainer), memnew(VBoxContainer) };
	for (VBoxContainer *c : col) { c->add_theme_constant_override("separation", 8); c->set_h_size_flags(Control::SIZE_EXPAND_FILL); g->add_child(c); }
	auto head = [&](VBoxContainer *c, const String &en_, const String &tr_) {
		HBoxContainer *h = memnew(HBoxContainer); h->add_theme_constant_override("separation", 10); h->set_custom_minimum_size(Vector2(0, 40));
		h->add_child(caps(en_, GREEN)); if (helper_on) h->add_child(caps(tr_));
		c->add_child(h);
	};
	auto row = [&](VBoxContainer *c, const String &key, Control *ctl) {
		HBoxContainer *h = memnew(HBoxContainer); h->add_theme_constant_override("separation", 16); h->set_custom_minimum_size(Vector2(0, 72));
		VBoxContainer *t = memnew(VBoxContainer); t->set_h_size_flags(Control::SIZE_EXPAND_FILL); t->set_alignment(BoxContainer::ALIGNMENT_CENTER);
		t->add_child(label(en(key), FS_BODY)); const String h2 = helper(key); if (!h2.is_empty()) t->add_child(label(h2, FS_HELP, DIM));
		h->add_child(t); ctl->set_v_size_flags(Control::SIZE_SHRINK_CENTER); h->add_child(ctl);
		c->add_child(h);
	};
	auto slider = [&](VBoxContainer *c, const String &key, double lo, double hi, double step) {
		HSlider *s = memnew(HSlider); s->set_min(lo); s->set_max(hi); s->set_step(step); s->set_custom_minimum_size(Vector2(240, 44));
		s->add_theme_stylebox_override("slider", box("slider")); s->add_theme_stylebox_override("grabber_area", box("fill")); s->add_theme_stylebox_override("grabber_area_highlight", box("fill"));
		s->connect("value_changed", callable_mp(this, &CityGame::_setting_changed).bind(key));
		setting_rows.push_back({ key, s, 0 });
		row(c, "settings." + key, s);
	};
	auto check = [&](VBoxContainer *c, const String &key, const String &text_key) {
		CheckButton *b = memnew(CheckButton); b->set_custom_minimum_size(Vector2(72, 56));
		b->connect("toggled", callable_mp(this, &CityGame::_setting_changed).bind(key));
		setting_rows.push_back({ key, b, 1 });
		row(c, text_key, b);
	};
	auto cycle = [&](VBoxContainer *c, const String &key, const String &text_key) {
		Button *b = button("", "raised"); b->set_custom_minimum_size(Vector2(160, 56));
		on_any(b, [this, key]() {
			const Variant cur = settings.get(key, Variant());
			Variant nx;
			if (key == "pscale") { const double v = cur; nx = v < 0.3 ? 0.5 : (v < 0.75 ? 1.0 : 0.25); }
			else if (key == "pcolors") { const int v = cur; nx = v == 0 ? 4096 : (v == 4096 ? 32768 : (v == 32768 ? 65536 : 0)); }
			else { const String v = cur; nx = v == "auto" ? String("on") : (v == "on" ? String("off") : String("auto")); }
			set_setting(key, nx); refresh_settings();
		});
		setting_rows.push_back({ key, b, 3 });
		row(c, text_key, b);
	};
	head(col[0], "Sound", "Ses");
	slider(col[0], "master", 0, 1, 0.05); slider(col[0], "music", 0, 1, 0.05); slider(col[0], "voice", 0, 1, 0.05); slider(col[0], "sfx", 0, 1, 0.05);
	head(col[0], "Language", "Dil");
	check(col[0], "locale", "settings.helper_captions");
	head(col[1], "Display", String::utf8("Görüntü"));
	{
		OptionButton *o = memnew(OptionButton); o->set_custom_minimum_size(Vector2(240, 56));
		o->add_item(en("settings.low")); o->add_item(en("settings.med")); o->add_item(en("settings.high"));
		o->connect("item_selected", callable_mp(this, &CityGame::_setting_changed).bind("preset"));
		setting_rows.push_back({ "preset", o, 2 });
		row(col[1], "settings.graphics", o);
	}
	cycle(col[1], "pscale", "settings.pscale"); cycle(col[1], "pcolors", "settings.pcolors"); cycle(col[1], "msaa", "settings.msaa");
	check(col[1], "battery_saver", "settings.battery_saver");
	head(col[1], "Controls", "Kontroller");
	slider(col[1], "cam_sens", 0.2, 3.0, 0.1);
	check(col[1], "invert_y", "settings.invert_y");
	Button *bk = dual_from(dual("menu.back", Array(), "\n"), "green", "back");
	bk->set_custom_minimum_size(Vector2(200, 72)); bk->set_h_size_flags(Control::SIZE_SHRINK_BEGIN); bk->set_meta("key", "settings.back");
	on_any(bk, on_back);
	p->add_child(bk);
	return p;
}

void CityGame::_setting_changed(const Variant &p_v, const String &p_key) {
	if (refreshing) return;
	if (p_key == "locale") { set_helper_enabled((bool)p_v); set_setting("locale", settings["locale"]); return; }
	if (p_key == "preset") { const int i = p_v; set_setting("preset", i == 0 ? String("low") : (i == 1 ? String("med") : String("high"))); return; }
	set_setting(p_key, p_v);
}

void CityGame::refresh_settings() {
	refreshing = true;
	for (const SettingRow &r : setting_rows) {
		const Variant v = settings.get(r.key, Variant());
		if (r.kind == 0) Object::cast_to<HSlider>(r.ctl)->set_value(v);
		else if (r.kind == 1) Object::cast_to<CheckButton>(r.ctl)->set_pressed_no_signal(r.key == "locale" ? helper_on : (bool)v);
		else if (r.kind == 2) { const String s = v; Object::cast_to<OptionButton>(r.ctl)->select(s == "low" ? 0 : (s == "med" ? 1 : 2)); }
		else {
			String t;
			if (r.key == "pscale") { const double d = v; t = d >= 0.99 ? String("1x") : String::num(d, 2); }
			else if (r.key == "pcolors") { const int c = v; t = c == 0 ? en("settings.pcolors_all") : vformat("%dk", c / 1024); }
			else t = en("settings.msaa_" + String(v));
			Object::cast_to<Button>(r.ctl)->set_text(t);
		}
	}
	refreshing = false;
}

// ---------------------------------------------------------------- pause
void CityGame::build_pause() {
	pause = memnew(CanvasLayer);
	pause->set_layer(55);
	pause->set_process_mode(PROCESS_MODE_ALWAYS);
	add_child(pause);
	ColorRect *bg = memnew(ColorRect);
	bg->set_color(Color(0, 0, 0, 0.6f)); bg->set_anchors_preset(Control::PRESET_FULL_RECT);
	pause->add_child(bg);
	PanelContainer *sheet = panel("screen");
	sheet->set_anchor(SIDE_BOTTOM, 1); sheet->set_custom_minimum_size(Vector2(456, 0));
	bg->add_child(sheet);
	MarginContainer *mc = memnew(MarginContainer);
	mc->add_theme_constant_override("margin_left", 32); mc->add_theme_constant_override("margin_right", 32);
	mc->add_theme_constant_override("margin_top", 40); mc->add_theme_constant_override("margin_bottom", 24);
	sheet->add_child(mc);
	VBoxContainer *outer = memnew(VBoxContainer);
	mc->add_child(outer);
	VBoxContainer *s = memnew(VBoxContainer); s->add_theme_constant_override("separation", 8);
	s->add_child(label(en("pause.title"), FS_TITLE, TEXT, 800));
	const String h = helper_text("pause.title"); if (!h.is_empty()) s->add_child(caps(h));
	s->add_child(gap(12));
	Button *res = dual_from(dual("pause.resume", Array(), "\n"), "green"); res->set_custom_minimum_size(Vector2(0, 96)); res->set_meta("key", "pause.resume");
	on_any(res, [this]() { close_pause(); });
	s->add_child(res);
	s->add_child(menu_row("menu.settings", "", true, [this]() { pause_list->set_visible(false); pause_settings->set_visible(true); refresh_settings(); }));
	s->add_child(menu_row("pause.save", "", false, [this]() { pause_note->set_text(save() ? dual("pause.saved") : dual("pause.no_slot")); }));
	pause_note = label("", FS_HELP, DIM);
	s->add_child(pause_note);
	s->add_child(menu_row("pause.main_menu", "", false, [this]() { close_pause(); open_menu(); }));
	s->add_child(menu_row("pause.quit", "", false, [this]() { get_tree()->quit(); }));
	outer->add_child(s);
	pause_list = s;
	VBoxContainer *ps = build_settings_panel([this]() { pause_settings->set_visible(false); pause_list->set_visible(true); });
	ps->set_visible(false);
	outer->add_child(ps);
	pause_settings = ps;
	pause->set_visible(false);
}

void CityGame::open_pause() {
	if (pause_open || !pause) return;
	pause_open = true;
	was_paused = get_tree()->is_paused();
	get_tree()->set_pause(true);
	pause_note->set_text("");
	pause_list->set_visible(true); pause_settings->set_visible(false);
	pause->set_visible(true);
	emit_signal("paused_changed", true);
}

void CityGame::close_pause() {
	if (!pause_open) return;
	pause_open = false;
	pause->set_visible(false);
	get_tree()->set_pause(was_paused);
	emit_signal("paused_changed", false);
}

// ---------------------------------------------------------------- game over
void CityGame::build_over() {
	over = memnew(CanvasLayer);
	over->set_layer(95);
	over->set_process_mode(PROCESS_MODE_ALWAYS);
	add_child(over);
	PanelContainer *p = panel("plate");
	p->set_anchor(SIDE_LEFT, 0.5f); p->set_anchor(SIDE_RIGHT, 0.5f); p->set_anchor(SIDE_TOP, 0.5f); p->set_anchor(SIDE_BOTTOM, 0.5f);
	p->set_offset(SIDE_LEFT, -280); p->set_offset(SIDE_RIGHT, 280); p->set_offset(SIDE_TOP, -130); p->set_offset(SIDE_BOTTOM, 130);
	p->set_name("Panel");
	over->add_child(p);
	MarginContainer *mc = memnew(MarginContainer);
	for (const char *m : { "margin_left", "margin_right", "margin_top", "margin_bottom" }) mc->add_theme_constant_override(m, 16);
	p->add_child(mc);
	VBoxContainer *v = memnew(VBoxContainer); v->set_alignment(BoxContainer::ALIGNMENT_CENTER); v->add_theme_constant_override("separation", 8);
	mc->add_child(v);
	over_title = label("", FS_TITLE, TEXT, 800); v->add_child(over_title);
	over_reason = label("", FS_BODY); over_reason->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART); v->add_child(over_reason);
	over_reason_tr = label("", FS_HELP, DIM); over_reason_tr->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART); v->add_child(over_reason_tr);
	over_btn = dual_from(dual("ui.retry", Array(), "\n"), "green");
	over_btn->set_custom_minimum_size(Vector2(240, 72)); over_btn->set_h_size_flags(Control::SIZE_SHRINK_BEGIN); over_btn->set_meta("key", "ui.retry");
	on_any(over_btn, [this]() { retry(); });
	v->add_child(over_btn);
	over->set_visible(false);
}

void CityGame::game_over(const String &p_reason_en, const String &p_reason_tr, const String &p_title, const String &p_rewind) {
	if (over_open) return;
	over_open = true;
	over_title->set_text(p_title.is_empty() ? en("gameover.title") : p_title);
	over_title->add_theme_color_override("font_color", p_title.is_empty() ? TEXT : RED);
	over_reason->set_text(p_reason_en); over_reason_tr->set_text(p_reason_tr); over_reason_tr->set_visible(!p_reason_tr.is_empty());
	Dictionary cps = slot_sections.get("checkpoints", Dictionary());
	rewind_to = (!p_rewind.is_empty() && cps.has(p_rewind)) ? p_rewind : String();
	set_dual(over_btn, en(rewind_to.is_empty() ? "ui.retry" : "gameover.rewind"), helper(rewind_to.is_empty() ? "ui.retry" : "gameover.rewind"));
	over->set_visible(true);
	get_tree()->set_pause(true);
	emit_signal("game_over_shown");
}

void CityGame::retry() {
	if (!over_open) return;
	over_open = false;
	over->set_visible(false);
	get_tree()->set_pause(false);
	bool ok = false;
	if (!rewind_to.is_empty()) { const Dictionary cps = slot_sections.get("checkpoints", Dictionary()); apply_snapshot(cps[rewind_to]); ok = true; }
	else if (active_slot >= 0) ok = load_slot(active_slot);
	emit_signal("retried", ok);
}

// ---------------------------------------------------------------- into the world
// The loading screen; the world's scene loaded on the engine's loader threads (0 .. 40 %), made the current scene
// (the boot scene goes), the slot started or loaded (50 %), then the world settles: 45 frames in a row under 40 ms, at
// most 20 s (50 .. 100 %). The menu closes when the slot is in.
void CityGame::enter_play(const std::function<int()> &action, int p_pic_slot) {
	if (play_phase) return;
	play_action = action;
	ld_slot = p_pic_slot;
	if (menu) menu->set_visible(false);
	open_loading();
	if (world_on) { play_phase = 2; play_t = 0.0; play_quiet = 0; const int s = play_action(); if (s < 0) { close_loading(); open_menu(); play_phase = 0; return; } close_menu(); emit_signal("play_started", s); return; }
	ResourceLoader::get_singleton()->load_threaded_request(world_scene);
	play_phase = 1; play_t = 0.0;
}

void CityGame::step_play(double p_delta) {
	play_t += p_delta;
	ResourceLoader *rl = ResourceLoader::get_singleton();
	if (play_phase == 1) {
		Array prog;
		const ResourceLoader::ThreadLoadStatus st = rl->load_threaded_get_status(world_scene, prog);
		if (st == ResourceLoader::THREAD_LOAD_IN_PROGRESS) { set_loading(0.4 * (prog.size() ? (double)prog[0] : 0.0), ""); return; }
		if (st != ResourceLoader::THREAD_LOAD_LOADED) {
			play_phase = 0; close_loading(); open_menu();
			if (menu_notice) menu_notice->set_text(String::utf8("Loading failed / Yükleme başarısız"));
			return;
		}
		Ref<PackedScene> ps = rl->load_threaded_get(world_scene);
		set_loading(0.4, "loading.building");
		Node *w = ps.is_valid() ? ps->instantiate() : nullptr;
		if (!w) { play_phase = 0; close_loading(); open_menu(); return; }
		// the slot first (new or loaded): the world asks where to load the moment it enters the tree
		const int s = play_action();
		if (s < 0) { memdelete(w); play_phase = 0; close_loading(); open_menu(); return; }
		SceneTree *tr = get_tree();
		Node *old = tr->get_current_scene();
		tr->get_root()->add_child(w);
		tr->set_current_scene(w);
		if (old && old != w && old != this && !old->is_ancestor_of(this)) old->queue_free();
		world_on = true;
		set_loading(0.5, "");
		close_menu();
		emit_signal("play_started", s);
		play_phase = 2; play_t = 0.0; play_quiet = 0;
		return;
	}
	// settling: 45 frames in a row under 40 ms AND the player in the world and let go (hold_start: the ground's collision
	// under him, he can move), at most 20 s. (B2, Yasin 20 Nov: "we can click the hud but being able to control the
	// character happens much later ... hide it behind the loading": the quiet frames alone ended it while he was still held.)
	// (B21: "quiet" is a frame under 25 ms - smooth on the phone's 60 Hz - and only after 8 s under 40 ms as before)
	play_quiet = p_delta < (play_t < 8.0 ? 0.025 : 0.040) ? play_quiet + 1 : 0;
	const bool free_to_move = player_id != 0 && start_hold < 0.0;
	set_loading(0.5 + 0.5 * std::min(free_to_move ? 1.0 : 0.95, std::max(play_t / 20.0, (double)play_quiet / 45.0)), "");
	if ((play_quiet >= 45 && free_to_move) || play_t > 20.0) { close_loading(); play_phase = 0; }
}

// ---------------------------------------------------------------- the tests' thumb
bool CityGame::press(const String &p_key) {
	std::vector<Node *> st{ this };
	while (!st.empty()) {
		Node *n = st.back(); st.pop_back();
		Button *b = Object::cast_to<Button>(n);
		if (b && b->has_meta("key") && String(b->get_meta("key")) == p_key && b->is_visible_in_tree() && !b->is_disabled()) { b->emit_signal("pressed"); return true; }
		for (int k = 0; k < n->get_child_count(); k++) st.push_back(n->get_child(k));
	}
	return false;
}

} // namespace godot
