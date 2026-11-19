// CityHud: see city_hud.h.
#include "city_hud.h"

#include "city_game.h"
#include "city_player.h"
#include "ui_plate.h"

#include <godot_cpp/classes/audio_server.hpp>
#include <godot_cpp/classes/audio_stream.hpp>
#include <godot_cpp/classes/audio_stream_player.hpp>
#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/h_box_container.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/input_event_key.hpp>
#include <godot_cpp/classes/input_event_mouse_button.hpp>
#include <godot_cpp/classes/input_event_screen_touch.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/margin_container.hpp>
#include <godot_cpp/classes/panel_container.hpp>
#include <godot_cpp/classes/progress_bar.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/texture_rect.hpp>
#include <godot_cpp/classes/v_box_container.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>

#include <cmath>

namespace godot {

// ---------------------------------------------------------------- the arrowhead
void HudArrow::_draw() {
	const Vector2 s = get_size(), c = s * 0.5f;
	const float r = std::min(s.x, s.y) * 0.34f;
	const Color base = objective ? Color(0.20f, 0.80f, 0.40f) : Color(0.97f, 0.76f, 0.16f);
	const Color lit = base.lightened(0.38f), shade = base.darkened(0.30f), edge = base.darkened(0.62f);
	const float cs = std::cos(angle), sn = std::sin(angle);
	auto P = [&](float x, float y, const Vector2 &off) { return c + off + Vector2(x * cs - y * sn, x * sn + y * cs); };
	// the wedge: tip, back corners, the notch in its back
	const float tip = -r, back = r * 0.78f, notch = r * 0.30f, wide = r * 0.80f;
	auto shape = [&](const Vector2 &off) {
		PackedVector2Array a; a.push_back(P(0, tip, off)); a.push_back(P(wide, back, off)); a.push_back(P(0, notch, off)); a.push_back(P(-wide, back, off)); return a;
	};
	draw_colored_polygon(shape(Vector2(r * 0.06f, r * 0.14f)), Color(0, 0, 0, 0.35f));    // its shadow on the plate
	draw_colored_polygon(shape(Vector2(0, r * 0.10f)), edge);                              // its thickness (seen from a little above)
	PackedVector2Array L, R;
	L.push_back(P(0, tip, Vector2())); L.push_back(P(-wide, back, Vector2())); L.push_back(P(0, notch, Vector2()));
	R.push_back(P(0, tip, Vector2())); R.push_back(P(0, notch, Vector2())); R.push_back(P(wide, back, Vector2()));
	draw_colored_polygon(L, lit);      // the lit half
	draw_colored_polygon(R, shade);    // the shaded half
	PackedVector2Array o = shape(Vector2()); o.push_back(o[0]);
	draw_polyline(o, edge, std::max(1.0f, r * 0.05f), true);
	draw_line(P(0, tip, Vector2()), P(0, notch, Vector2()), lit.lightened(0.3f), std::max(1.0f, r * 0.03f), true);   // the spine's highlight
	if (!objective) {   // north: an N under it
		Ref<Font> f = plate::font(800);
		const int fs = (int)std::max(10.0f, r * 0.42f);
		const Vector2 np = P(0, -r * 1.32f, Vector2());
		draw_string(f, np + Vector2(-fs * 0.32f, fs * 0.36f), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.9f));
	}
}

// ---------------------------------------------------------------- the HUD
static float ui_k_of(const Vector2 &sz) { return std::max(std::min(sz.x / 1152.0f, sz.y / 648.0f), 0.5f); }

Rect2 CityHud::box_rect(int p_what) const {
	const Vector2 sz = last_sz;
	const float k = ui_k_of(sz), m = 24.0f * k, b = 76.0f * k;
	switch (p_what) {
		case 0: return Rect2(sz.x - m - b, m, b, b);          // the arrow: top right
		case 1: return Rect2(sz.x - m - b, sz.y - m - b, b, b);   // the phone: bottom right
		case 2: return Rect2(m, sz.y - m - b, b, b);          // the inventory: bottom left
		default: return Rect2(m, m, b, b);                    // money and the clock: top left
	}
}

void CityHud::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) return;
	set_layer(30);
	build();
	set_process(true); set_process_input(true);
}

void CityHud::build() {
	auto box = [&](const char *look) { PanelContainer *p = plate::panel(look); p->set_mouse_filter(Control::MOUSE_FILTER_IGNORE); add_child(p); return p; };
	// money and the clock
	b_money = box("plate");
	{
		VBoxContainer *v = memnew(VBoxContainer); v->set_alignment(BoxContainer::ALIGNMENT_CENTER); v->add_theme_constant_override("separation", -4); v->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
		l_money = plate::label("$0", plate::FS_BODY, Color(0.55f, 0.92f, 0.62f), 800); l_money->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER);
		l_time = plate::label("00:00", plate::FS_BODY, plate::TEXT, 700); l_time->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER);
		v->add_child(l_money); v->add_child(l_time); b_money->add_child(v);
	}
	// health and needs (inactive: hidden while CityGame keeps them off)
	{
		VBoxContainer *v = memnew(VBoxContainer); v->add_theme_constant_override("separation", 3); v->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
		const char *names[4] = { "health", "hunger", "thirst", "energy" };
		const Color cols[4] = { Color(0.86f, 0.22f, 0.2f), Color(0.95f, 0.62f, 0.2f), Color(0.3f, 0.62f, 0.95f), Color(0.75f, 0.75f, 0.3f) };
		for (int k = 0; k < 4; k++) {
			ProgressBar *pb = memnew(ProgressBar);
			pb->set_name(names[k]); pb->set_min(0); pb->set_max(100); pb->set_value(100); pb->set_show_percentage(false);
			pb->set_custom_minimum_size(Vector2(0, 5)); pb->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
			Ref<StyleBox> fill = plate::box("fill"); pb->add_theme_stylebox_override("background", plate::box("track")); pb->add_theme_stylebox_override("fill", fill);
			pb->set_self_modulate(cols[k]);
			v->add_child(pb);
		}
		needs_box = v; add_child(v); v->set_visible(false);
	}
	b_arrow = box("plate");
	arrow = memnew(HudArrow); arrow->set_mouse_filter(Control::MOUSE_FILTER_IGNORE); b_arrow->add_child(arrow);
	b_inv = box("plate");
	{ TextureRect *ic = plate::icon_rect("buy", 36); ic->set_mouse_filter(Control::MOUSE_FILTER_IGNORE); ic->set_stretch_mode(TextureRect::STRETCH_KEEP_ASPECT_CENTERED); b_inv->add_child(ic); }
	b_phone = box("plate");
	{ TextureRect *ic = plate::icon_rect("phone", 36); ic->set_mouse_filter(Control::MOUSE_FILTER_IGNORE); ic->set_stretch_mode(TextureRect::STRETCH_KEEP_ASPECT_CENTERED); b_phone->add_child(ic); }
	// the panels that open out of their boxes
	for (int p = 0; p < 2; p++) {
		PanelContainer *pn = plate::panel("screen");
		pn->set_visible(false); pn->set_clip_contents(true);
		MarginContainer *mc = memnew(MarginContainer);
		for (const char *side : { "margin_left", "margin_right", "margin_top", "margin_bottom" }) mc->add_theme_constant_override(side, 18);
		VBoxContainer *v = memnew(VBoxContainer); v->add_theme_constant_override("separation", 10);
		HBoxContainer *top = memnew(HBoxContainer);
		VBoxContainer *tt = memnew(VBoxContainer); tt->set_h_size_flags(Control::SIZE_EXPAND_FILL);
		tt->add_child(plate::label(p == 0 ? "MAP" : "WEAPONS", plate::FS_TITLE, plate::TEXT, 800));
		tt->add_child(plate::caps(p == 0 ? "HARİTA" : String::utf8("SİLAHLAR")));
		top->add_child(tt);
		Button *close = plate::button(String::utf8("✕"), "raised");
		close->set_custom_minimum_size(Vector2(56, 56));
		close->connect("pressed", callable_mp(this, &CityHud::touch).bind(3));
		top->add_child(close);
		v->add_child(top);
		if (p == 0) {
			Label *l = plate::label("The phone's map comes here (next on the board).", plate::FS_HELP, plate::DIM);
			l->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART); l->set_name("MapHolder");
			v->add_child(l);
		} else {
			v->add_child(plate::label("None yet", plate::FS_BODY, plate::TEXT, 700));
			v->add_child(plate::caps(String::utf8("HENÜZ YOK")));
		}
		mc->add_child(v); pn->add_child(mc);
		add_child(pn);
		pan[p] = pn;
	}
	tick = memnew(AudioStreamPlayer);
	tick->set_stream(ResourceLoader::get_singleton()->load("res://audio/sfx/ui_tick.wav"));
	tick->set_bus(AudioServer::get_singleton()->get_bus_index("SFX") >= 0 ? StringName("SFX") : StringName("Master"));
	tick->set_volume_db(-6.0f);
	add_child(tick);
}

void CityHud::layout(const Vector2 &sz) {
	last_sz = sz;
	const float k = ui_k_of(sz);
	auto put = [](Control *c, const Rect2 &r) { c->set_position(r.position); c->set_size(r.size); };
	put(b_arrow, box_rect(0)); put(b_phone, box_rect(1)); put(b_inv, box_rect(2)); put(b_money, box_rect(3));
	{ const Rect2 m = box_rect(3); put(needs_box, Rect2(m.position.x, m.get_end().y + 6.0f * k, m.size.x, 32.0f * k)); }
	// the phone grows out of its button to a phone held up at the right; the inventory out of its box, up the left
	const float ph = sz.y - 48.0f * k, pw = std::min(ph * 0.56f, sz.x * 0.5f);
	from_rect[0] = box_rect(1); to_rect[0] = Rect2(sz.x - 24.0f * k - pw, 24.0f * k, pw, ph);
	from_rect[1] = box_rect(2); to_rect[1] = Rect2(24.0f * k, sz.y - 24.0f * k - 300.0f * k, 360.0f * k, 300.0f * k);
}

void CityHud::feedback() {
	taps++;
	if (tick && tick->get_stream().is_valid()) tick->play();
	Input::get_singleton()->vibrate_handheld(15);
}

void CityHud::touch(int p_what) {
	feedback();
	const int want = p_what == 3 ? -1 : (p_what == 2 ? 1 : 0);   // the arrow and the phone open the phone (on its map)
	if (want < 0 || (open == want && anim_dir >= 0)) { if (open >= 0) anim_dir = -1; return; }
	if (open >= 0 && open != want) { pan[open]->set_visible(false); anim = 0.0f; }
	open = want; anim_dir = 1;
	pan[open]->set_visible(true);
}

String CityHud::get_money_text() const { return l_money ? l_money->get_text() : String(); }
String CityHud::get_time_text() const { return l_time ? l_time->get_text() : String(); }

void CityHud::_process(double p_delta) {
	CityGame *g = CityGame::get();
	Viewport *vp = get_viewport();
	if (!vp) return;
	const Vector2 sz = vp->get_visible_rect().size;
	if (sz != last_sz) layout(sz);
	const bool show = !g || (g->is_playing() && !g->is_pause_open());
	set_visible(show);
	if (!show) return;
	CityPlayer *pl = player_id ? Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	if (!pl && g) pl = Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(g->get_player_id())));
	const bool on_foot = pl && pl->is_visible_in_tree();
	b_inv->set_visible(on_foot);   // (in a car or on the bike the lower left is the steering; the inventory is for on foot)
	// money and the clock
	if (g) {
		l_money->set_text(String("$") + String::num_int64(g->get_money()));
		l_time->set_text(g->hhmm());
		needs_box->set_visible(g->get_needs_active());
	}
	// the arrow: from the camera's view to the objective, or to the north (-z)
	if (Camera3D *cam = vp->get_camera_3d()) {
		const Basis cb = cam->get_global_transform().basis;
		Vector3 f = -cb.get_column(2); f.y = 0.0f; Vector3 rt = cb.get_column(0); rt.y = 0.0f;
		Vector3 d(0, 0, -1);
		const bool obj = g && g->get_objective_on();
		if (obj) { d = g->get_objective_at() - cam->get_global_position(); d.y = 0.0f; }
		if (f.length_squared() > 1e-6f && d.length_squared() > 1e-6f) {
			f.normalize(); rt.normalize(); d.normalize();
			arrow->angle = std::atan2(d.dot(rt), d.dot(f));
		}
		arrow->objective = obj;
		arrow->set_size(b_arrow->get_size() - Vector2(8, 8)); arrow->queue_redraw();
	}
	// a panel growing out of its box / shrinking back (0.28 s, eased: several frames)
	if (open >= 0 && anim_dir != 0) {
		anim = std::min(std::max(anim + (float)anim_dir * (float)p_delta / 0.28f, 0.0f), 1.0f);
		const float e = 1.0f - (1.0f - anim) * (1.0f - anim) * (1.0f - anim);
		const Rect2 a = from_rect[open], b = to_rect[open];
		pan[open]->set_position(a.position.lerp(b.position, e));
		pan[open]->set_size(a.size.lerp(b.size, e));
		pan[open]->set_modulate(Color(1, 1, 1, std::min(1.0f, 0.25f + e)));
		if (anim <= 0.0f && anim_dir < 0) { pan[open]->set_visible(false); open = -1; anim_dir = 0; }
		else if (anim >= 1.0f && anim_dir > 0) anim_dir = 0;
	}
	// the boxes (and an open panel: the whole screen) are not the player's move / look
	if (pl) {
		pl->set_no_touch(4, box_rect(0)); pl->set_no_touch(5, box_rect(1)); pl->set_no_touch(6, b_inv->is_visible() ? box_rect(2) : Rect2());
		pl->set_no_touch(7, open >= 0 ? Rect2(Vector2(), sz) : box_rect(3));
	}
}

void CityHud::_input(const Ref<InputEvent> &p_event) {
	if (!is_visible()) return;
	Vector2 p; bool tap = false;
	if (const InputEventScreenTouch *t = Object::cast_to<InputEventScreenTouch>(p_event.ptr())) { if (t->is_pressed()) { p = t->get_position(); tap = true; } }
	else if (const InputEventMouseButton *mb = Object::cast_to<InputEventMouseButton>(p_event.ptr())) {
		if (mb->is_pressed() && mb->get_button_index() == MOUSE_BUTTON_LEFT && Input::get_singleton()->get_mouse_mode() != Input::MOUSE_MODE_CAPTURED && !mb->is_echo()) { p = mb->get_position(); tap = true; }
	} else if (const InputEventKey *k = Object::cast_to<InputEventKey>(p_event.ptr())) {
		if (k->is_pressed() && !k->is_echo()) {
			if (k->get_keycode() == KEY_M) { touch(0); get_viewport()->set_input_as_handled(); }
			else if (k->get_keycode() == KEY_P) { touch(1); get_viewport()->set_input_as_handled(); }
			else if (k->get_keycode() == KEY_I) { touch(2); get_viewport()->set_input_as_handled(); }
		}
		return;
	}
	if (!tap) return;
	if (open >= 0) return;   // (an open panel: its own close button)
	for (int w = 0; w < 3; w++) {
		if (w == 2 && !b_inv->is_visible()) continue;
		if (box_rect(w).has_point(p)) { touch(w); get_viewport()->set_input_as_handled(); return; }
	}
}

void CityHud::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_player", "player"), &CityHud::set_player);
	ClassDB::bind_method(D_METHOD("press", "what"), &CityHud::press);
	ClassDB::bind_method(D_METHOD("get_open"), &CityHud::get_open);
	ClassDB::bind_method(D_METHOD("get_anim"), &CityHud::get_anim);
	ClassDB::bind_method(D_METHOD("get_taps"), &CityHud::get_taps);
	ClassDB::bind_method(D_METHOD("get_arrow_angle"), &CityHud::get_arrow_angle);
	ClassDB::bind_method(D_METHOD("get_arrow_objective"), &CityHud::get_arrow_objective);
	ClassDB::bind_method(D_METHOD("get_money_text"), &CityHud::get_money_text);
	ClassDB::bind_method(D_METHOD("get_time_text"), &CityHud::get_time_text);
	ClassDB::bind_method(D_METHOD("box_rect", "what"), &CityHud::box_rect);
}

} // namespace godot
