// CityHud: see city_hud.h.
#include "perf_marks.h"
#include "city_hud.h"
#include "city_phone.h"
#include "el_sfx.h"

#include "city_game.h"
#include "city_player.h"
#include "city_crowd.h"
#include "city_traffic.h"
#include "city_shops.h"
#include "city_car.h"
#include "city_bike.h"
#include "car_models.h"

#include <godot_cpp/classes/scene_tree.hpp>

#include <godot_cpp/classes/input_event_mouse_motion.hpp>
#include <godot_cpp/classes/input_event_screen_drag.hpp>
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
	// (Yasin: "put the arrow into the dead center of the box": the wedge's own middle, between its tip and its back, on the
	// box's middle, whichever way it turns)
	auto P = [&](float x, float y, const Vector2 &off) { y += r * 0.11f; return c + off + Vector2(x * cs - y * sn, x * sn + y * cs); };
	// the wedge: tip, back corners, the notch in its back
	const float tip = -r, back = r * 0.78f, notch = r * 0.30f, wide = r * 0.80f;
	auto shape = [&](const Vector2 &off) {
		PackedVector2Array a; a.push_back(P(0, tip, off)); a.push_back(P(wide, back, off)); a.push_back(P(0, notch, off)); a.push_back(P(-wide, back, off)); return a;
	};
	draw_colored_polygon(shape(Vector2(r * 0.04f, r * 0.08f)), Color(0, 0, 0, 0.35f));    // its shadow on the plate
	draw_colored_polygon(shape(Vector2(0, r * 0.06f)), edge);                              // its thickness (seen from a little above)
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

// ---------------------------------------------------------------- the phone's map
void HudMap::load_lines() {
	CityTraffic *tr = traffic_id ? Object::cast_to<CityTraffic>(ObjectDB::get_instance(ObjectID(traffic_id))) : nullptr;
	CityCrowd *cr = crowd_id ? Object::cast_to<CityCrowd>(ObjectDB::get_instance(ObjectID(crowd_id))) : nullptr;
	if (tr && roads.is_empty()) roads = tr->map_lines();
	if (cr && walks.is_empty()) { walks = cr->map_lines(0); crossings = cr->map_lines(1); rooms = cr->map_rooms(); }
	have_lines = !roads.is_empty() || !walks.is_empty();
}

Array HudMap::targets() const { CityGame *g = CityGame::get(); return g ? g->get_map_targets() : targets_local; }
void HudMap::set_targets(const Array &p_t) { CityGame *g = CityGame::get(); if (g) g->set_map_targets(p_t); else targets_local = p_t; }

bool HudMap::toggle_target(const Vector2 &p_xz, const String &p_name) {
	Array t = targets().duplicate();
	for (int k = 0; k < t.size(); k++) {
		const Dictionary d = t[k];
		if (Vector2((float)(double)d["x"], (float)(double)d["z"]).distance_to(p_xz) < 1.0f) { t.remove_at(k); set_targets(t); return false; }
	}
	Dictionary d; d["x"] = p_xz.x; d["z"] = p_xz.y; d["name"] = p_name;
	t.push_back(d);
	while (t.size() > 3) t.remove_at(0);
	set_targets(t);
	return true;
}

Vector2 HudMap::room_screen(int p_i) const {
	if (p_i < 0 || p_i >= rooms.size()) return Vector2();
	const float k = 1.0f / std::max(mpp, 0.02f);
	return get_size() * 0.5f + (Vector2(rooms[p_i].x, rooms[p_i].y) - centre) * k;
}

int HudMap::tap(const Vector2 &p_screen) {
	int best = -1; float bd = 26.0f;
	for (int i = 0; i < rooms.size(); i++) { const float d = room_screen(i).distance_to(p_screen); if (d < bd) { bd = d; best = i; } }
	if (best < 0) return -1;
	CityCrowd *cr = crowd_id ? Object::cast_to<CityCrowd>(ObjectDB::get_instance(ObjectID(crowd_id))) : nullptr;
	toggle_target(Vector2(rooms[best].x, rooms[best].y), cr ? cr->room_name(best) : String("Room"));
	queue_redraw();
	return best;
}

void HudMap::update_route() {
	{   // the player's targets: each its way (asked again when a target changes or the player has gone 40 m)
		CityTraffic *tr = traffic_id ? Object::cast_to<CityTraffic>(ObjectDB::get_instance(ObjectID(traffic_id))) : nullptr;
		const Array t = targets();
		for (int k = 0; k < 3; k++) {
			if (k >= t.size()) { troute[k].clear(); troute_for[k] = Vector2(1e9f, 1e9f); continue; }
			const Dictionary d = t[k];
			const Vector2 to((float)(double)d["x"], (float)(double)d["z"]);
			if (troute_for[k].distance_to(to) < 1.0f && !troute[k].is_empty() && troute[k][0].distance_to(player_xz) < 40.0f) continue;
			troute[k].clear(); troute_for[k] = to;
			if (!tr) continue;
			const Dictionary r = tr->route(Vector3(player_xz.x, 0, player_xz.y), Vector3(to.x, 0, to.y), false);
			if (!(bool)r.get("ok", false)) continue;
			const PackedVector3Array pts = r.get("points", PackedVector3Array());
			troute[k].push_back(player_xz);
			for (int q = 0; q < pts.size(); q++) troute[k].push_back(Vector2(pts[q].x, pts[q].z));
			troute[k].push_back(to);
		}
	}
	if (!has_obj) { route.clear(); route_for = Vector2(1e9f, 1e9f); return; }
	if (route_for.distance_to(obj_xz) < 1.0f && !route.is_empty()) return;
	CityTraffic *tr = traffic_id ? Object::cast_to<CityTraffic>(ObjectDB::get_instance(ObjectID(traffic_id))) : nullptr;
	route.clear(); route_for = obj_xz;
	if (!tr) return;
	const Dictionary r = tr->route(Vector3(player_xz.x, 0, player_xz.y), Vector3(obj_xz.x, 0, obj_xz.y), false);
	if (!(bool)r.get("ok", false)) return;
	const PackedVector3Array pts = r.get("points", PackedVector3Array());
	route.push_back(player_xz);
	for (int k = 0; k < pts.size(); k++) route.push_back(Vector2(pts[k].x, pts[k].z));
	route.push_back(obj_xz);
}

void HudMap::_draw() {
	const Vector2 s = get_size(), mid = s * 0.5f;
	draw_rect(Rect2(Vector2(), s), Color(0.075f, 0.085f, 0.095f));   // (the land; the streets drawn over it)
	const float k = 1.0f / std::max(mpp, 0.02f);
	auto W = [&](const Vector2 &w) { return mid + (w - centre) * k; };
	draw_set_transform(mid - centre * k, 0.0f, Vector2(k, k));   // world x, z straight to the screen: north up
	if (!walks.is_empty()) draw_multiline(walks, Color(0.36f, 0.37f, 0.38f), 2.4f);
	if (!crossings.is_empty()) draw_multiline(crossings, Color(0.62f, 0.62f, 0.6f), 2.0f);
	if (!roads.is_empty()) draw_multiline(roads, Color(0.24f, 0.25f, 0.27f), 3.4f);
	draw_set_transform(Vector2(), 0.0f, Vector2(1, 1));
	// the enterable rooms: a small plate each, coloured and lettered by the shop's kind
	{
		static const char *const L = "BOFCRSCSBPBCKJSGSGCISVG";   // (a letter per SHOP_KINDS)
		const Color cols[6] = { Color(1.0f, 0.55f, 0.3f), Color(0.4f, 0.75f, 0.9f), Color(0.85f, 0.6f, 0.95f), Color(0.95f, 0.85f, 0.35f), Color(0.55f, 0.9f, 0.6f), Color(0.9f, 0.9f, 0.9f) };
		const float side = mpp < 1.2f ? 14.0f : 8.0f;
		Ref<Font> f = plate::font(800);
		for (int i = 0; i < rooms.size(); i++) {
			const Vector2 q = W(Vector2(rooms[i].x, rooms[i].y));
			if (q.x < -20 || q.y < -20 || q.x > s.x + 20 || q.y > s.y + 20) continue;
			const int sub = (int)rooms[i].z;
			if (sub == 100) {   // the player's home (player_home.json), not a shop letter
				draw_circle(q + Vector2(0, -14), 10.0f, Color(0.85f, 0.28f, 0.20f));
				PackedVector2Array tri; tri.push_back(q); tri.push_back(q + Vector2(-7, -10)); tri.push_back(q + Vector2(7, -10));
				draw_colored_polygon(tri, Color(0.85f, 0.28f, 0.20f));
				draw_circle(q + Vector2(0, -14), 3.5f, Color(0.97f, 0.95f, 0.90f));
				if (side > 10.0f) draw_string(f, q + Vector2(-14, -30), "Home", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.97f, 0.95f, 0.90f));
				continue;
			}
			const Color c = cols[sub % 6];
			draw_rect(Rect2(q - Vector2(side, side) * 0.5f, Vector2(side, side)), c);
			if (side > 10.0f && sub < 23) draw_string(f, q + Vector2(-4, 5), String::chr(L[sub]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.05f, 0.05f, 0.06f));
		}
	}
	// the player's targets: their ways (white, as the old phone's own routes) and a numbered ring on each
	{
		const Array t = targets();
		for (int k = 0; k < 3; k++) if (troute[k].size() >= 2) { PackedVector2Array sp; for (int i = 0; i < troute[k].size(); i++) sp.push_back(W(troute[k][i])); draw_polyline(sp, Color(0.95f, 0.95f, 0.92f, 0.85f), 4.0f, true); }
		for (int k = 0; k < t.size(); k++) {
			const Dictionary d = t[k];
			const Vector2 q = W(Vector2((float)(double)d["x"], (float)(double)d["z"]));
			draw_arc(q, 13.0f, 0.0f, 6.2831853f, 24, Color(0.97f, 0.97f, 0.95f), 3.0f, true);
			draw_string(plate::font(800), q + Vector2(-5, -18), String::num_int64(k + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.97f, 0.97f, 0.95f));
		}
	}
	if (route.size() >= 2) {
		PackedVector2Array sp; for (int i = 0; i < route.size(); i++) sp.push_back(W(route[i]));
		draw_polyline(sp, Color(0.2f, 0.8f, 0.4f), 5.0f, true);
	}
	if (has_obj) {   // the objective: a green pin
		const Vector2 o = W(obj_xz);
		draw_circle(o + Vector2(0, -16), 11.0f, Color(0.2f, 0.8f, 0.4f));
		PackedVector2Array tri; tri.push_back(o); tri.push_back(o + Vector2(-8, -12)); tri.push_back(o + Vector2(8, -12));
		draw_colored_polygon(tri, Color(0.2f, 0.8f, 0.4f));
		draw_circle(o + Vector2(0, -16), 4.0f, Color(0.05f, 0.2f, 0.1f));
	}
	{   // the player: a white arrow with a dark rim, turned his way
		const Vector2 p = W(player_xz);
		const float cs = std::cos(player_yaw), sn = std::sin(player_yaw);
		auto R = [&](float x, float y) { return p + Vector2(x * cs - y * sn, x * sn + y * cs); };
		PackedVector2Array a; a.push_back(R(0, -14)); a.push_back(R(10, 10)); a.push_back(R(0, 5)); a.push_back(R(-10, 10));
		draw_circle(p, 18.0f, Color(1, 1, 1, 0.12f));
		draw_colored_polygon(a, Color(0.97f, 0.97f, 0.95f));
		a.push_back(a[0]); draw_polyline(a, Color(0.05f, 0.05f, 0.06f), 2.0f, true);
	}
	// the scale: 100 m
	const float bar = 100.0f * k;
	draw_line(Vector2(24, s.y - 28), Vector2(24 + bar, s.y - 28), Color(1, 1, 1, 0.8f), 3.0f);
	draw_string(plate::font(700), Vector2(24, s.y - 36), "100 m", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.8f));
	if (!have_lines) draw_string(plate::font(600), mid + Vector2(-90, 0), "no streets loaded", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.5f));
}

void HudMap::_gui_input(const Ref<InputEvent> &p_event) {
	if (const InputEventScreenTouch *t = Object::cast_to<InputEventScreenTouch>(p_event.ptr())) {
		const int i = t->get_index();
		if (i < 2) { tp[i] = t->get_position(); }
		if (i == 0 && t->is_pressed()) { press_at = t->get_position(); press_moved = false; }
		if (i == 0 && !t->is_pressed() && !press_moved && touches <= 1) tap(t->get_position());
		touches = std::max(0, touches + (t->is_pressed() ? 1 : -1));
		if (touches == 2) { pinch0 = tp[0].distance_to(tp[1]); mpp0 = mpp; }
		accept_event(); return;
	}
	if (const InputEventScreenDrag *d = Object::cast_to<InputEventScreenDrag>(p_event.ptr())) {
		const int i = d->get_index();
		if (i < 2) tp[i] = d->get_position();
		if (touches >= 2 && pinch0 > 10.0f) mpp = std::min(std::max(mpp0 * pinch0 / std::max(tp[0].distance_to(tp[1]), 1.0f), 0.08f), 8.0f);
		else if (i == 0) { centre -= d->get_relative() * mpp; follow = false; }
		if (d->get_position().distance_to(press_at) > 12.0f) press_moved = true;
		queue_redraw(); accept_event(); return;
	}
	// (28 Nov night) a touch also makes mouse events of its own (Godot's mouse from touch, device -1): the touch is already
	// handled above; read again, a tap on the map fired twice and its second undid the first (toggle_target)
	if (const InputEventMouse *me = Object::cast_to<InputEventMouse>(p_event.ptr())) { if (me->get_device() == -1) return; }
	if (const InputEventMouseMotion *mm = Object::cast_to<InputEventMouseMotion>(p_event.ptr())) {
		if (mm->get_button_mask().has_flag(MOUSE_BUTTON_MASK_LEFT) && touches == 0) { centre -= mm->get_relative() * mpp; follow = false; if (mm->get_position().distance_to(press_at) > 12.0f) press_moved = true; queue_redraw(); accept_event(); }
		return;
	}
	if (const InputEventMouseButton *mb = Object::cast_to<InputEventMouseButton>(p_event.ptr())) {
		if (mb->get_button_index() == MOUSE_BUTTON_LEFT && touches == 0) {
			if (mb->is_pressed()) { press_at = mb->get_position(); press_moved = false; }
			else if (!press_moved) tap(mb->get_position());
		}
		if (mb->is_pressed() && mb->get_button_index() == MOUSE_BUTTON_WHEEL_UP) { mpp = std::max(mpp / 1.2f, 0.08f); queue_redraw(); accept_event(); }
		else if (mb->is_pressed() && mb->get_button_index() == MOUSE_BUTTON_WHEEL_DOWN) { mpp = std::min(mpp * 1.2f, 8.0f); queue_redraw(); accept_event(); }
	}
}

void HudMap::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_road_lines"), &HudMap::get_road_lines);
	ClassDB::bind_method(D_METHOD("get_walk_lines"), &HudMap::get_walk_lines);
	ClassDB::bind_method(D_METHOD("get_route_points"), &HudMap::get_route_points);
	ClassDB::bind_method(D_METHOD("tap", "screen"), &HudMap::tap);
	ClassDB::bind_method(D_METHOD("get_rooms"), &HudMap::get_rooms);
	ClassDB::bind_method(D_METHOD("room_screen", "i"), &HudMap::room_screen);
	ClassDB::bind_method(D_METHOD("get_target_count"), &HudMap::get_target_count);
	ClassDB::bind_method(D_METHOD("get_target_route_points", "k"), &HudMap::get_target_route_points);
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
		case 4: return Rect2(sz.x - m - b, m + b + 8.0f * k, b, b);   // the Use button: under the arrow box
		default: return Rect2(m, m, b, b);                    // money and the clock: top left
	}
}

void HudStars::_draw() {
	if (level <= 0) return;
	const Vector2 sz = get_size();
	const float r = std::min(sz.y * 0.48f, sz.x / 10.5f), gap = (sz.x - 10.0f * r) / 4.0f;
	const bool dim = !seen && std::fmod(clock, 0.8f) > 0.4f;
	for (int k = 0; k < 5; k++) {
		const Vector2 c(r + (float)k * (2.0f * r + gap), sz.y * 0.5f);
		PackedVector2Array pts;
		for (int q = 0; q < 10; q++) {
			const float a = -1.5707963f + (float)q * 0.62831853f, rr = (q & 1) ? r * 0.45f : r;
			pts.push_back(c + Vector2(std::cos(a), std::sin(a)) * rr);
		}
		PackedVector2Array ring = pts; ring.push_back(pts[0]);
		if (k < level) {
			const Color gold = dim ? Color(0.55f, 0.42f, 0.12f, 0.75f) : Color(1.0f, 0.78f, 0.18f);
			PackedColorArray cs; cs.push_back(gold);
			draw_polygon(pts, cs);
			draw_polyline(ring, Color(0.18f, 0.12f, 0.02f, 0.9f), 1.5f, true);
		} else draw_polyline(ring, Color(1.0f, 1.0f, 1.0f, 0.45f), 1.5f, true);
	}
}

void CityHud::set_wanted(int p_level, bool p_seen) {
	if (!stars) return;
	const int l = std::min(std::max(p_level, 0), 5);
	if (l != stars->level || p_seen != stars->seen) { stars->level = l; stars->seen = p_seen; stars->queue_redraw(); }
}

void CityHud::note(const String &p_en, const String &p_tr, double p_seconds) {
	if (!b_note) return;
	l_note_en->set_text(p_en); l_note_tr->set_text(p_tr); l_note_tr->set_visible(!p_tr.is_empty());
	note_t = (float)p_seconds;
	b_note->set_visible(true);
	b_note->reset_size();
}

String CityHud::get_note() const { return b_note && b_note->is_visible() && l_note_en ? l_note_en->get_text() : String(); }

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
	// the wanted stars (under the money box) and the word in the middle (BUSTED)
	stars = memnew(HudStars); stars->set_mouse_filter(Control::MOUSE_FILTER_IGNORE); add_child(stars);
	b_note = box("plate"); b_note->set_visible(false);
	{
		VBoxContainer *v = memnew(VBoxContainer); v->set_alignment(BoxContainer::ALIGNMENT_CENTER); v->add_theme_constant_override("separation", -2); v->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
		l_note_en = plate::label("", plate::FS_TITLE, Color(1.0f, 0.82f, 0.25f), 900); l_note_en->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER);
		l_note_tr = plate::label("", plate::FS_BODY, plate::TEXT, 700); l_note_tr->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER);
		v->add_child(l_note_en); v->add_child(l_note_tr); b_note->add_child(v);
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
	arrow = memnew(HudArrow); arrow->set_mouse_filter(Control::MOUSE_FILTER_IGNORE); add_child(arrow);   // (over the box, exactly its rectangle)
	b_inv = box("plate");
	{ TextureRect *ic = plate::icon_rect("buy", 36); ic->set_mouse_filter(Control::MOUSE_FILTER_IGNORE); ic->set_stretch_mode(TextureRect::STRETCH_KEEP_ASPECT_CENTERED); b_inv->add_child(ic); }
	b_use = box("green");
	{
		VBoxContainer *v = memnew(VBoxContainer); v->set_alignment(BoxContainer::ALIGNMENT_CENTER); v->add_theme_constant_override("separation", -3); v->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
		l_use_en = plate::label("GET IN", plate::FS_HELP, plate::TEXT, 800); l_use_en->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER);
		l_use_tr = plate::label(String::utf8("BİN"), plate::FS_HELP, Color(1, 1, 1, 0.85f), 600); l_use_tr->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER);
		v->add_child(l_use_en); v->add_child(l_use_tr); b_use->add_child(v);
		b_use->set_visible(false);
	}
	b_phone = box("plate");
	{ TextureRect *ic = plate::icon_rect("phone", 36); ic->set_mouse_filter(Control::MOUSE_FILTER_IGNORE); ic->set_stretch_mode(TextureRect::STRETCH_KEEP_ASPECT_CENTERED); b_phone->add_child(ic); }
	// the panels that open out of their boxes
	for (int p = 0; p < 2; p++) {
		PanelContainer *pn = plate::panel("screen");
		pn->set_visible(false); pn->set_clip_contents(true);
		MarginContainer *mc = memnew(MarginContainer);
		for (const char *side : { "margin_left", "margin_right", "margin_top", "margin_bottom" }) mc->add_theme_constant_override(side, 18);
		VBoxContainer *v = memnew(VBoxContainer); v->add_theme_constant_override("separation", 10);
		if (p == 0) {   // the phone: its own header, home and apps (city_phone.cpp); the map is one of its apps
			phone = memnew(CityPhone); phone->hud = this;
			phone->set_v_size_flags(Control::SIZE_EXPAND_FILL); phone->set_h_size_flags(Control::SIZE_EXPAND_FILL);
			v->add_child(phone);
			map = memnew(HudMap);
			map->set_clip_contents(true); map->set_mouse_filter(Control::MOUSE_FILTER_STOP);
			Button *me = plate::button("", "raised", "pin");   // centre on the player again
			me->set_custom_minimum_size(Vector2(56, 56));
			me->connect("pressed", callable_mp(this, &CityHud::recentre));
			mc->add_child(v); pn->add_child(mc);
			add_child(pn);
			pan[p] = pn;
			phone->set_map(map, me);
			continue;
		}
		HBoxContainer *top = memnew(HBoxContainer);
		VBoxContainer *tt = memnew(VBoxContainer); tt->set_h_size_flags(Control::SIZE_EXPAND_FILL);
		tt->add_child(plate::label(p == 0 ? "MAP" : "WEAPONS", plate::FS_TITLE, plate::TEXT, 800));
		tt->add_child(plate::caps(p == 0 ? String::utf8("HARİTA") : String::utf8("SİLAHLAR")));
		top->add_child(tt);
		Button *close = plate::button(String::utf8("✕"), "raised");
		close->set_custom_minimum_size(Vector2(56, 56));
		close->connect("pressed", callable_mp(this, &CityHud::touch).bind(3));
		top->add_child(close);
		v->add_child(top);
		if (p == 0) {
			map = memnew(HudMap);
			map->set_v_size_flags(Control::SIZE_EXPAND_FILL); map->set_h_size_flags(Control::SIZE_EXPAND_FILL);
			map->set_clip_contents(true); map->set_mouse_filter(Control::MOUSE_FILTER_STOP);
			v->add_child(map);
			Button *me = plate::button("", "raised", "pin");   // centre on the player again
			me->set_custom_minimum_size(Vector2(56, 56));
			me->connect("pressed", callable_mp(this, &CityHud::recentre));
			top->add_child(me); top->move_child(me, 1);
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
	put(b_use, box_rect(4));
	put(b_arrow, box_rect(0)); put(arrow, box_rect(0)); put(b_phone, box_rect(1)); put(b_inv, box_rect(2)); put(b_money, box_rect(3));
	if (stars) { const Rect2 m = box_rect(3); stars->set_position(Vector2(m.position.x, m.position.y + m.size.y + 6.0f)); stars->set_size(Vector2(m.size.x * 1.6f, m.size.y * 0.26f)); }
	{ const Rect2 m = box_rect(3); put(needs_box, Rect2(m.position.x, m.get_end().y + 6.0f * k, m.size.x, 32.0f * k)); }
	// the phone grows out of its button to a phone held up at the right; the inventory out of its box, up the left
	// (Yasin: "all revealed screens should be full screen")
	from_rect[0] = box_rect(1); to_rect[0] = Rect2(Vector2(), sz);
	from_rect[1] = box_rect(2); to_rect[1] = Rect2(Vector2(), sz);
	(void)k;
}

void CityHud::feedback() {
	taps++;
	if (tick && tick->get_stream().is_valid()) tick->play();
	Input::get_singleton()->vibrate_handheld(15);
}

bool CityHud::stinger(const String &p_kind) {
	static const char *const OK[] = { "mission_start", "mission_pass", "mission_fail", "notify", "msg_ping", "app_tap", "camera_shutter" };
	for (const char *k : OK) if (p_kind == k) {
		const bool loud = p_kind.begins_with("mission");
		return elsfx::play(this, String("res://audio/ui/") + p_kind + String("_"), loud ? -3.0f : -8.0f, 0.0f) != nullptr;
	}
	return false;
}

void CityHud::touch(int p_what) {
	feedback();
	const int want = p_what == 3 ? -1 : (p_what == 2 ? 1 : 0);   // the arrow and the phone open the phone (on its map)
	if (want < 0 || (open == want && anim_dir >= 0)) { if (open >= 0) anim_dir = -1; return; }
	if (open >= 0 && open != want) { pan[open]->set_visible(false); anim = 0.0f; }
	open = want; anim_dir = 1;
	if (want == 0) from_rect[0] = box_rect(p_what == 0 ? 0 : 1);   // (the map out of the arrow box, the phone out of its button)
	if (want == 0 && phone) phone->open_app(p_what == 0 ? String("map") : String("home"));   // (the arrow: the map; the phone button: its home)
	pan[open]->set_visible(true);
}

void CityHud::open_phone() {
	if (open == 0 && anim_dir >= 0) return;
	if (open >= 0 && open != 0) { pan[open]->set_visible(false); anim = 0.0f; }
	open = 0; anim_dir = 1; from_rect[0] = box_rect(1);
	pan[0]->set_visible(true);
}

Object *CityHud::get_phone() const { return phone; }

void CityHud::recentre() { feedback(); if (map) { map->follow = true; map->queue_redraw(); } }

// What the Use button offers: the car or bicycle the player drives or rides (out / off), else the nearest one in reach
// (a car: within 1.4 m of its side or ends; a bicycle: 2.5 m). The cars and bicycles of the world are the nodes of the
// "vehicles" group (the start car and bicycle, and any the game places); the traffic's knocked cars are not.
void CityHud::use_find(CityPlayer *pl) {
	use_kind = 0; use_target = 0;
	SceneTree *tr = get_tree();
	if (!tr || !pl) return;
	const TypedArray<Node> vs = tr->get_nodes_in_group("vehicles");
	const bool on_foot = pl->is_visible_in_tree();
	const Vector3 pp = pl->get_global_position();
	float best = 1e9f;
	for (int i = 0; i < vs.size(); i++) {
		Node *n = Object::cast_to<Node>(vs[i]);
		if (CityCar *c = Object::cast_to<CityCar>(n)) {
			if (c->get_player()) { use_kind = 2; use_target = c->get_instance_id(); return; }
			if (!on_foot || !c->is_visible_in_tree() || ((c->get_collision_layer() & 16u) && !c->has_meta("takeable"))) continue;
			const Transform3D t = c->get_global_transform();
			const Vector3 lp = t.affine_inverse().xform(pp);
			const cm::CarModel &m = cm::MODELS[std::min(std::max(c->get_model(), 0), cm::N_MODELS - 1)];
			const float dx = std::max(std::fabs(lp.x) - m.half_w, 0.0f), dz = std::max(std::fabs(lp.z) - m.half_len, 0.0f);
			const float d = std::sqrt(dx * dx + dz * dz);
			if (d < 1.4f && std::fabs(lp.y) < 2.0f && d < best) { best = d; use_kind = 1; use_target = c->get_instance_id(); }
		} else if (CityBike *b = Object::cast_to<CityBike>(n)) {
			const int st = b->get_ride_state();
			if (st == CityBike::ST_RIDE) { use_kind = 4; use_target = b->get_instance_id(); return; }
			if (st != CityBike::ST_PARKED || !on_foot) continue;
			const float d = b->get_global_position().distance_to(pp);
			if (d < 2.5f && d < best) { best = d; use_kind = 3; use_target = b->get_instance_id(); }
		}
	}
	// BUYING (Yasin: "add us and npcs giving money receiving things animations"): on foot at a shop's counter, its cashier free
	if (use_kind == 0 && on_foot) {
		CityGame *g = CityGame::get();
		if (CityShops *sh = g ? Object::cast_to<CityShops>(g->get_shops()) : nullptr) if (sh->can_buy()) use_kind = 6;
	}
	// TAKING A CAR (Yasin's GTA IV list): on foot by a car of the traffic that stands or crawls (a red light, a jam)
	use_row = -1;
	if (use_kind == 0 && on_foot) {
		CityGame *g = CityGame::get();
		CityTraffic *trf = traffic_id ? Object::cast_to<CityTraffic>(ObjectDB::get_instance(ObjectID(traffic_id))) : nullptr;
		if (!trf && g) trf = Object::cast_to<CityTraffic>(ObjectDB::get_instance(ObjectID(g->get_traffic_id())));
		if (trf) { const int32_t id = trf->car_to_take(pp, 1.3, 2.5); if (id != -1) { use_kind = 5; use_row = id; } }      // (-2 - stall: a parked car)
	}
}

void CityHud::use_do() {
	if (use_kind == 0) return;
	CityGame *g = CityGame::get();
	CityPlayer *pl = player_id ? Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	if (!pl && g) pl = Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(g->get_player_id())));
	if (use_kind == 6 && pl) {   // at a counter: he pays and takes what he bought (CityShops)
		if (CityShops *sh = g ? Object::cast_to<CityShops>(g->get_shops()) : nullptr) if (sh->buy()) { feedback(); uses++; }
		use_scan = 0.0f;
		return;
	}
	if (use_kind == 5 && pl) {   // the car is taken from its driver: he gets out (to fight, two in five, or to run), the player gets in
		CityTraffic *trf = traffic_id ? Object::cast_to<CityTraffic>(ObjectDB::get_instance(ObjectID(traffic_id))) : nullptr;
		if (!trf && g) trf = Object::cast_to<CityTraffic>(ObjectDB::get_instance(ObjectID(g->get_traffic_id())));
		CityCar *c = trf ? Object::cast_to<CityCar>(trf->take_car(use_row, UtilityFunctions::randf() < 0.4)) : nullptr;
		if (!c) return;
		use_kind = 0; use_row = -1;      // (taken: nothing more to take until the next scan)
		feedback(); uses++; cars_taken++;
		const cm::CarModel &m = cm::MODELS[std::min(std::max(c->get_model(), 0), cm::N_MODELS - 1)];
		if (c->enter(pl)) trf->set_player_car(c, m.half_len, m.half_w);
		use_scan = 0.0f;
		return;
	}
	Object *o = use_target ? ObjectDB::get_instance(ObjectID(use_target)) : nullptr;
	if (!pl || !o) return;
	feedback(); uses++;
	CityTraffic *trf = traffic_id ? Object::cast_to<CityTraffic>(ObjectDB::get_instance(ObjectID(traffic_id))) : nullptr;
	if (!trf && g) trf = Object::cast_to<CityTraffic>(ObjectDB::get_instance(ObjectID(g->get_traffic_id())));
	if (CityCar *c = Object::cast_to<CityCar>(o)) {
		const cm::CarModel &m = cm::MODELS[std::min(std::max(c->get_model(), 0), cm::N_MODELS - 1)];
		if (use_kind == 1) {   // in: the wheel is his
			if (!c->enter(pl)) return;   // (he walks to the door, opens it, sits in, closes it: then the wheel is his)
			if (trf) trf->set_player_car(c, m.half_len, m.half_w);
		} else if (use_kind == 2) {   // out, beside the driver's door (the car's left), when it has (nearly) stopped
			if (!c->leave()) return;   // (the door opens, he gets out and stands by it as the player)
			if (trf) trf->set_player_car(nullptr, 0.0, 0.0);
		}
	} else if (CityBike *b = Object::cast_to<CityBike>(o)) {
		if (use_kind == 3) { b->set_rider_player(pl); b->get_on(); }
		else if (use_kind == 4) b->get_off();
	}
	use_scan = 0.0f;
}

String CityHud::get_money_text() const { return l_money ? l_money->get_text() : String(); }
String CityHud::get_time_text() const { return l_time ? l_time->get_text() : String(); }

void CityHud::_process(double p_delta) {
	pm::Scope _pm(pm::HUD);   // (the slow-frame marks, perf_marks.h)
	CityGame *g = CityGame::get();
	Viewport *vp = get_viewport();
	if (!vp) return;
	const Vector2 sz = vp->get_visible_rect().size;
	if (sz != last_sz) layout(sz);
	bool show = !g || (g->is_playing() && !g->is_pause_open());
	if (photo_hide > 0) { photo_hide--; show = false; }   // (a photo: the view without the HUD and the phone)
	set_visible(show);
	if (!show) return;
	if (b_note && b_note->is_visible()) {   // the word in the middle: a moment, then gone
		note_t -= (float)p_delta;
		if (note_t <= 0.0f) b_note->set_visible(false);
		else { const Vector2 ns = b_note->get_combined_minimum_size(); b_note->set_size(ns); b_note->set_position(Vector2((sz.x - ns.x) * 0.5f, sz.y * 0.26f)); }
	}
	CityPlayer *pl = player_id ? Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	if (!pl && g) pl = Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(g->get_player_id())));
	const bool on_foot = pl && pl->is_visible_in_tree();
	// the phone in his hands (the Animator, 20 Nov: the phone had no animation): at his ear on a call, held up for the
	// camera, in his hand while its screen is open
	if (pl) pl->set_phone(!phone ? 0 : (phone->get_call_state() == 2 ? 2 : (!phone->is_visible_in_tree() ? 0 : (phone->get_app() == "camera" ? 3 : 1))));
	b_inv->set_visible(on_foot);
	use_scan -= (float)p_delta;
	if (use_scan <= 0.0f) {
		use_scan = 0.1f;
		const int was = use_kind;
		use_find(pl);
		if (use_kind != was || use_target != use_last) {
			static const char *const EN[7] = { "", "GET IN", "GET OUT", "GET ON", "GET OFF", "TAKE CAR", "BUY" };
			static const char *const TR[7] = { "", "BİN", "İN", "BİN", "İN", "ARABAYI AL", "SATIN AL" };
			l_use_en->set_text(EN[use_kind]); l_use_tr->set_text(String::utf8(TR[use_kind]));
			if ((use_kind == 1 || use_kind == 3) && use_target != use_last) Input::get_singleton()->vibrate_handheld(200);   // (the old spec: a new target in reach)
			use_last = use_target;
		}
		b_use->set_visible(use_kind != 0 && open < 0);
	}
	{
		Input *in = Input::get_singleton();
		const bool e = in->is_key_pressed(KEY_E) || in->is_joy_button_pressed(0, JOY_BUTTON_X);
		if (e && !e_was && open < 0) use_do();
		e_was = e;
	}   // (in a car or on the bike the lower left is the steering; the inventory is for on foot)
	// money and the clock
	if (g) {
		l_money->set_text(String("$") + String::num_int64(g->get_money()));
		if (stars && stars->level > 0 && !stars->seen) { stars->clock += (float)p_delta; stars->queue_redraw(); }
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
		arrow->queue_redraw();
	}
	// the map, while it shows: the player, the view's heading, the objective and its way
	if (map && open == 0 && pl) {
		if (!traffic_id && g) { traffic_id = g->get_traffic_id(); crowd_id = g->get_crowd_id(); }
		map->traffic_id = traffic_id; map->crowd_id = crowd_id;
		if (!map->get_road_lines()) map->load_lines();
		const Vector3 pp = pl->is_visible_in_tree() ? pl->get_global_position() : (vp->get_camera_3d() ? vp->get_camera_3d()->get_global_position() : pl->get_global_position());
		map->player_xz = Vector2(pp.x, pp.z);
		if (Camera3D *c = vp->get_camera_3d()) { const Vector3 f = -c->get_global_transform().basis.get_column(2); map->player_yaw = std::atan2(f.x, -f.z); }
		map->has_obj = g && g->get_objective_on();
		if (map->has_obj) { const Vector3 o = g->get_objective_at(); map->obj_xz = Vector2(o.x, o.z); }
		if (map->follow) map->centre = map->player_xz;
		map->update_route();
		map->queue_redraw();
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
		pl->set_no_touch(0, b_use->is_visible() ? box_rect(4) : Rect2());
	}
}

void CityHud::_input(const Ref<InputEvent> &p_event) {
	if (!is_visible()) return;
	Vector2 p; bool tap = false;
	if (const InputEventScreenTouch *t = Object::cast_to<InputEventScreenTouch>(p_event.ptr())) { if (t->is_pressed()) { p = t->get_position(); tap = true; } }
	else if (const InputEventMouseButton *mb = Object::cast_to<InputEventMouseButton>(p_event.ptr())) {
		// (28 Nov: a touch also makes a click of its own, Godot's mouse made from touch, device -1: read as a second tap it
		// did every button twice: a hijack took the car twice, two cars one over the other)
		if (mb->get_device() != -1 && mb->is_pressed() && mb->get_button_index() == MOUSE_BUTTON_LEFT && Input::get_singleton()->get_mouse_mode() != Input::MOUSE_MODE_CAPTURED && !mb->is_echo()) { p = mb->get_position(); tap = true; }
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
	if (b_use->is_visible() && box_rect(4).has_point(p)) { use_do(); get_viewport()->set_input_as_handled(); return; }
	for (int w = 0; w < 3; w++) {
		if (w == 2 && !b_inv->is_visible()) continue;
		if (box_rect(w).has_point(p)) { touch(w); get_viewport()->set_input_as_handled(); return; }
	}
}

void CityHud::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_player", "player"), &CityHud::set_player);
	ClassDB::bind_method(D_METHOD("stinger", "kind"), &CityHud::stinger);
	ClassDB::bind_method(D_METHOD("get_phone"), &CityHud::get_phone);
	ClassDB::bind_method(D_METHOD("press", "what"), &CityHud::press);
	ClassDB::bind_method(D_METHOD("get_open"), &CityHud::get_open);
	ClassDB::bind_method(D_METHOD("get_anim"), &CityHud::get_anim);
	ClassDB::bind_method(D_METHOD("get_taps"), &CityHud::get_taps);
	ClassDB::bind_method(D_METHOD("get_arrow_angle"), &CityHud::get_arrow_angle);
	ClassDB::bind_method(D_METHOD("get_arrow_objective"), &CityHud::get_arrow_objective);
	ClassDB::bind_method(D_METHOD("get_money_text"), &CityHud::get_money_text);
	ClassDB::bind_method(D_METHOD("get_time_text"), &CityHud::get_time_text);
	ClassDB::bind_method(D_METHOD("box_rect", "what"), &CityHud::box_rect);
	ClassDB::bind_method(D_METHOD("set_world", "crowd", "traffic"), &CityHud::set_world);
	ClassDB::bind_method(D_METHOD("get_map"), &CityHud::get_map);
	ClassDB::bind_method(D_METHOD("get_use_kind"), &CityHud::get_use_kind);
	ClassDB::bind_method(D_METHOD("get_uses"), &CityHud::get_uses);
	ClassDB::bind_method(D_METHOD("press_use"), &CityHud::press_use);
}

} // namespace godot
