// The game's look ("Plate"), in C++: the old game's ui/kit/plate.gd and plate_box.gd brought over number for number
// (docs/GAME_PORT_BOARD.md item 3 on; the spec of 19 Nov). Black plates with a thin keyline, one green accent, the
// Overpass font in three weights, 72 px touch targets, the dual button (English over the helper language). Every
// screen of the game shell (loading, menus, pause, game over, settings, later the HUD and the phone) builds its
// controls with these, from C++.
#pragma once

#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/font_variation.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/panel_container.hpp>
#include <godot_cpp/classes/style_box.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/classes/texture_rect.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {
namespace plate {

// colours
extern const Color BLACK, RAISED, RAISED_HI, LINE, KEY, TEXT, DIM, OFF, GREEN, GREEN_LO, AMBER, RED;
// geometry and the type scale
constexpr int R = 5, R_IN = 3, GRID = 4, MARGIN = 24, GAP = 8, TOUCH = 72;
constexpr int FS_LABEL = 15, FS_HELP = 17, FS_BODY = 21, FS_ACTION = 24, FS_FIGURE = 27, FS_TITLE = 40, FS_DISPLAY = 64;

Ref<FontVariation> font(int weight = 600);          // Overpass at that weight, tabular figures (cached)
Ref<StyleBox> box(const String &look);              // plate, plate_tight, mission, plate_go, frame, screen, raised, raised_hi, raised_off,
                                                    // green, green_lo, field, field_on, track, fill, seg, seg_on, scrim; else empty
Label *label(const String &text, int size = FS_BODY, const Color &col = TEXT, int weight = 600);
Label *caps(const String &text, const Color &col = DIM);
PanelContainer *panel(const String &look = "plate");
Ref<Texture2D> icon(const String &name);             // a cell of the 72 px icon atlas (game/ui/icons.png)
TextureRect *icon_rect(const String &name, int size = 24, const Color &col = TEXT);
void style_button(Button *b, const String &look = "raised", int size = FS_ACTION);
Button *button(const String &text, const String &look = "raised", const String &icon_name = "");
// English on top, the helper language under it (hidden when empty); an icon on the left, a chevron on the right
Button *dual_button(const String &en, const String &tr, const String &look = "raised", const String &icon_name = "", bool chevron = false);
Button *dual_from(const String &dual_text, const String &look = "raised", const String &icon_name = "", bool chevron = false);   // "EN\nTR"
void set_dual(Button *b, const String &en, const String &tr);
void set_disabled(Button *b, bool off);
void relook(Button *b, const String &look);

// The old game's control places (docs/OLD_CONTROLS_SPEC.md), at its 1152x648 canvas, scaled to the screen by its height and
// kept to the right / bottom edges: the phone button (76x76, 24 from the corner), GAS (104x144) and BRAKE (120x96) above
// it, right edges aligned, 8 apart; the speed plate bottom left (208x112); the Use plate under the top right box.
Rect2 phone_rect(const Vector2 &sz);
Rect2 gas_rect(const Vector2 &sz);
Rect2 brake_rect(const Vector2 &sz);
Rect2 speed_rect(const Vector2 &sz);
Rect2 top_right_box(const Vector2 &sz);
Rect2 use_rect(const Vector2 &sz);

} // namespace plate
} // namespace godot
