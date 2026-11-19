// The game's look: see ui_plate.h.
#include "ui_plate.h"

#include <godot_cpp/classes/atlas_texture.hpp>
#include <godot_cpp/classes/font_file.hpp>
#include <godot_cpp/classes/h_box_container.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/style_box_empty.hpp>
#include <godot_cpp/classes/style_box_flat.hpp>
#include <godot_cpp/classes/v_box_container.hpp>
#include <godot_cpp/variant/dictionary.hpp>

#include <algorithm>
#include <map>
#include <string>

namespace godot {
namespace plate {

// (plain numbers: Color::html() at load time runs before the engine is up and the library would not load)
const Color BLACK(0, 0, 0), RAISED = Color(0.0824f, 0.0980f, 0.1098f), RAISED_HI = Color(0.1451f, 0.1725f, 0.1961f), LINE(1, 1, 1, 0.16f), KEY(1, 1, 1, 0.28f);
const Color TEXT = Color(0.9569f, 0.9608f, 0.9529f), DIM = Color(0.6549f, 0.6824f, 0.6980f), OFF = Color(0.4196f, 0.4510f, 0.4706f);
const Color GREEN = Color(0.1216f, 0.6157f, 0.3882f), GREEN_LO = Color(0.0941f, 0.4902f, 0.3098f), AMBER = Color(0.8980f, 0.6588f, 0.1373f), RED = Color(0.8980f, 0.2824f, 0.3020f);

namespace {
std::map<int, Ref<FontVariation>> fonts;
std::map<std::string, Ref<StyleBox>> boxes;
Ref<Texture2D> atlas;
const char *const ICONS[] = { "phone", "use", "talk", "exit", "map", "settings", "grammar", "words", "learn", "films", "bank", "messages", "contacts",
	"radio", "delivery", "camera", "torch", "jobs", "transit", "menu", "social", "pay", "fuel", "prev", "next", "mic", "back", "home", "close", "hunger",
	"translate", "minus", "plus", "power", "chev", "down", "check", "buy", "drive", "games", "knock", "lie", "light", "open", "sit", "stand", "tv",
	"water", "lock", "speaker", "wrench", "trash", "pin", "energy", "bladder", "heart", "up", "dot", "arrow", "cafe", "star", "plus_med",
	"m_food", "m_cafe", "m_shop", "m_bank", "m_atm", "m_home", "m_place", "m_fuel", "m_health", "m_fun", "m_landmark", "m_job" };

Ref<StyleBoxFlat> flat(const Color &fill, int radius, float mx, float my) {
	Ref<StyleBoxFlat> b; b.instantiate();
	b->set_bg_color(fill);
	b->set_corner_radius_all(radius);
	b->set_content_margin(SIDE_LEFT, mx); b->set_content_margin(SIDE_RIGHT, mx);
	b->set_content_margin(SIDE_TOP, my); b->set_content_margin(SIDE_BOTTOM, my);
	return b;
}
// (the old PlateBox drew the fill and a keyline 2 px inside it; a flat box with a border inset by an expand margin of
// -2 is the same picture)
Ref<StyleBoxFlat> keyed(const Color &fill, const Color &line, int radius, float mx, float my) {
	Ref<StyleBoxFlat> b = flat(fill, radius, mx, my);
	b->set_border_width_all(1);
	b->set_border_color(line);
	return b;
}
} // namespace

Ref<FontVariation> font(int weight) {
	auto it = fonts.find(weight);
	if (it != fonts.end()) return it->second;
	Ref<FontVariation> fv; fv.instantiate();
	Ref<Font> base = ResourceLoader::get_singleton()->load("res://ui/fonts/Overpass.ttf");
	fv->set_base_font(base);
	Dictionary va; va["wght"] = weight;   // (the variable font's weight axis)
	fv->set_variation_opentype(va);
	Dictionary ft; ft["tnum"] = 1;
	fv->set_opentype_features(ft);
	fonts[weight] = fv;
	return fv;
}

Ref<StyleBox> box(const String &look) {
	const std::string k = look.utf8().get_data();
	auto it = boxes.find(k);
	if (it != boxes.end()) return it->second;
	Ref<StyleBox> r;
	if (k == "plate") r = keyed(BLACK, KEY, 3, 14, 10);
	else if (k == "plate_tight") r = keyed(BLACK, KEY, 3, 8, 6);
	else if (k == "mission") { Ref<StyleBoxFlat> b = keyed(BLACK, KEY, 3, 14, 9); b->set_content_margin(SIDE_LEFT, 24); b->set_border_width(SIDE_LEFT, 6); b->set_border_color(GREEN); r = b; }
	else if (k == "plate_go") r = keyed(BLACK, GREEN, 3, 14, 10);
	else if (k == "frame") { Ref<StyleBoxFlat> b = keyed(Color(0, 0, 0, 0), KEY, 3, 14, 10); b->set_draw_center(false); r = b; }
	else if (k == "screen") r = flat(BLACK, 0, 0, 0);
	else if (k == "raised") r = flat(RAISED, R, 14, 10);
	else if (k == "raised_hi") r = flat(RAISED_HI, R, 14, 10);
	else if (k == "raised_off") r = flat(Color(RAISED.r, RAISED.g, RAISED.b, 0.6f), R, 14, 10);
	else if (k == "green") r = keyed(GREEN, Color(1, 1, 1, 0.28f), R, 14, 10);
	else if (k == "green_lo") r = keyed(GREEN_LO, Color(1, 1, 1, 0.28f), R, 14, 10);
	else if (k == "field") r = keyed(RAISED, LINE, R, 12, 8);
	else if (k == "field_on") r = keyed(RAISED, GREEN, R, 12, 8);
	else if (k == "track") r = flat(RAISED, 3, 0, 0);
	else if (k == "slider") r = flat(RAISED_HI, 3, 0, 4);   // (a slider's track: 4 px over and under, or it has no height)
	else if (k == "track_world") r = flat(Color(1, 1, 1, 0.22f), 3, 0, 0);
	else if (k == "fill") r = flat(GREEN, 3, 0, 0);
	else if (k == "fill_text") r = flat(TEXT, 3, 0, 0);
	else if (k == "fill_amber") r = flat(AMBER, 3, 0, 0);
	else if (k == "fill_red") r = flat(RED, 3, 0, 0);
	else if (k == "seg") r = flat(Color(0, 0, 0, 0), 3, 12, 8);
	else if (k == "seg_on") r = flat(GREEN, 3, 12, 8);
	else if (k == "scrim") r = flat(Color(0, 0, 0, 0.6f), 0, 0, 0);
	else { Ref<StyleBoxEmpty> e; e.instantiate(); r = e; }
	boxes[k] = r;
	return r;
}

Label *label(const String &text, int size, const Color &col, int weight) {
	Label *l = memnew(Label);
	l->set_text(text);
	l->add_theme_font_override("font", font(weight));
	l->add_theme_font_size_override("font_size", size);
	l->add_theme_color_override("font_color", col);
	return l;
}

Label *caps(const String &text, const Color &col) {
	Label *l = label(text.to_upper(), FS_LABEL, col, 700);
	l->add_theme_constant_override("outline_size", 0);
	return l;
}

PanelContainer *panel(const String &look) {
	PanelContainer *p = memnew(PanelContainer);
	p->add_theme_stylebox_override("panel", box(look));
	p->set_meta("keep_style", true);
	return p;
}

Ref<Texture2D> icon(const String &name) {
	if (atlas.is_null()) atlas = ResourceLoader::get_singleton()->load("res://game/ui/icons.png");
	int idx = 57;   // "dot"
	for (int i = 0; i < (int)(sizeof(ICONS) / sizeof(ICONS[0])); i++) if (name == ICONS[i]) { idx = i; break; }
	Ref<AtlasTexture> t; t.instantiate();
	t->set_atlas(atlas);
	t->set_region(Rect2((float)((idx % 8) * 72), (float)((idx / 8) * 72), 72, 72));
	return t;
}

TextureRect *icon_rect(const String &name, int size, const Color &col) {
	TextureRect *r = memnew(TextureRect);
	r->set_texture(icon(name));
	r->set_expand_mode(TextureRect::EXPAND_IGNORE_SIZE);
	r->set_stretch_mode(TextureRect::STRETCH_KEEP_ASPECT_CENTERED);
	r->set_custom_minimum_size(Vector2((float)size, (float)size));
	r->set_modulate(col);
	r->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
	return r;
}

void style_button(Button *b, const String &look, int size) {
	String n = "raised", p = "raised_hi", d = "raised_off";
	Color fc = TEXT;
	if (look == "green") { n = "green"; p = "green_lo"; }
	else if (look == "quiet") { n = "none"; d = "none"; fc = DIM; }
	else if (look == "plate") { n = "plate"; }
	else if (look == "picked") { n = "plate_go"; }
	b->add_theme_stylebox_override("normal", box(n)); b->add_theme_stylebox_override("hover", box(n));
	b->add_theme_stylebox_override("pressed", box(p)); b->add_theme_stylebox_override("hover_pressed", box(p));
	b->add_theme_stylebox_override("disabled", box(d)); b->add_theme_stylebox_override("focus", box("none"));
	const char *cols[] = { "font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color" };
	for (const char *c : cols) b->add_theme_color_override(c, fc);
	b->add_theme_color_override("font_disabled_color", OFF); b->add_theme_color_override("icon_disabled_color", OFF);
	b->add_theme_font_override("font", font(700));
	b->add_theme_font_size_override("font_size", size);
	b->set_focus_mode(Control::FOCUS_NONE);
	b->set_meta("keep_style", true);
	b->set_meta("look", look);
}

Button *button(const String &text, const String &look, const String &icon_name) {
	Button *b = memnew(Button);
	b->set_text(text);
	style_button(b, look, FS_ACTION);
	b->set_custom_minimum_size(Vector2(0, TOUCH));
	if (!icon_name.is_empty()) { b->set_button_icon(icon(icon_name)); b->add_theme_constant_override("icon_max_width", 28); b->add_theme_constant_override("h_separation", 10); }
	return b;
}

Button *dual_button(const String &en, const String &tr, const String &look, const String &icon_name, bool chevron) {
	Button *b = memnew(Button);
	style_button(b, look, FS_ACTION);
	b->set_custom_minimum_size(Vector2(0, TOUCH));
	b->set_clip_contents(true);
	HBoxContainer *h = memnew(HBoxContainer);
	h->set_name("Content");
	h->set_anchors_preset(Control::PRESET_FULL_RECT);
	h->set_offset(SIDE_LEFT, 16); h->set_offset(SIDE_RIGHT, -12); h->set_offset(SIDE_TOP, 6); h->set_offset(SIDE_BOTTOM, -6);
	h->add_theme_constant_override("separation", 12);
	h->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
	b->add_child(h);
	if (!icon_name.is_empty()) h->add_child(icon_rect(icon_name, 28, look == "quiet" ? DIM : TEXT));
	VBoxContainer *v = memnew(VBoxContainer);
	v->set_name("Text");
	v->set_alignment(BoxContainer::ALIGNMENT_CENTER);
	v->add_theme_constant_override("separation", -3);
	v->set_h_size_flags(Control::SIZE_EXPAND_FILL);
	v->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
	h->add_child(v);
	Label *l = label(en, FS_ACTION, look == "quiet" ? DIM : TEXT, 700);
	l->set_name("Label"); l->set_text_overrun_behavior(TextServer::OVERRUN_TRIM_ELLIPSIS); l->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
	v->add_child(l);
	Label *t = label(tr, FS_HELP, look == "green" ? Color(1, 1, 1, 0.85f) : DIM, 600);
	t->set_name("Tr"); t->set_text_overrun_behavior(TextServer::OVERRUN_TRIM_ELLIPSIS); t->set_visible(!tr.is_empty()); t->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
	v->add_child(t);
	if (chevron) { Label *c = label(String::utf8("›"), FS_ACTION, DIM, 700); c->set_mouse_filter(Control::MOUSE_FILTER_IGNORE); h->add_child(c); }
	b->set_meta("dual_text", en + String("\n") + tr);
	return b;
}

Button *dual_from(const String &dual_text, const String &look, const String &icon_name, bool chevron) {
	const PackedStringArray p = dual_text.split("\n", true, 1);
	return dual_button(p.size() > 0 ? p[0] : String(), p.size() > 1 ? p[1] : String(), look, icon_name, chevron);
}

void set_dual(Button *b, const String &en, const String &tr) {
	Label *l = Object::cast_to<Label>(b->get_node_or_null(NodePath("Content/Text/Label")));
	Label *t = Object::cast_to<Label>(b->get_node_or_null(NodePath("Content/Text/Tr")));
	if (l) l->set_text(en);
	if (t) { t->set_text(tr); t->set_visible(!tr.is_empty()); }
	b->set_meta("dual_text", en + String("\n") + tr);
}

void set_disabled(Button *b, bool off) {
	b->set_disabled(off);
	Control *c = Object::cast_to<Control>(b->get_node_or_null(NodePath("Content")));
	if (c) c->set_modulate(Color(1, 1, 1, off ? 0.4f : 1.0f));
}

void relook(Button *b, const String &look) {
	style_button(b, look, FS_ACTION);
	Label *t = Object::cast_to<Label>(b->get_node_or_null(NodePath("Content/Text/Tr")));
	if (t) t->add_theme_color_override("font_color", look == "green" ? Color(1, 1, 1, 0.85f) : DIM);
}

namespace {
float ui_k(const Vector2 &sz) { return std::max(sz.y / 648.0f, 0.5f); }
Rect2 from_br(const Vector2 &sz, float right, float bottom, float w, float h) { const float k = ui_k(sz); return Rect2(sz.x - (right + w) * k, sz.y - (bottom + h) * k, w * k, h * k); }
} // namespace
Rect2 phone_rect(const Vector2 &sz) { return from_br(sz, 24, 24, 76, 76); }
Rect2 gas_rect(const Vector2 &sz) { return from_br(sz, 24, 24 + 76 + 8, 104, 144); }
Rect2 brake_rect(const Vector2 &sz) { return from_br(sz, 24 + 104 + 8, 24 + 76 + 8, 120, 96); }
Rect2 speed_rect(const Vector2 &sz) { const float k = ui_k(sz); return Rect2(24 * k, sz.y - (24 + 112) * k, 208 * k, 112 * k); }
Rect2 top_right_box(const Vector2 &sz) { const float k = ui_k(sz); return Rect2(sz.x - (24 + 76) * k, 24 * k, 76 * k, 76 * k); }   // (Yasin: the arrow box, the phone button's size)
Rect2 use_rect(const Vector2 &sz) { const float k = ui_k(sz); return Rect2(sz.x - (24 + 76) * k, (24 + 76 + 8) * k, 76 * k, 76 * k); }   // (Yasin: "make the use button as big as phone and map boxes")

} // namespace plate
} // namespace godot
