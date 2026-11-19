// CityHud: the HUD in play, all C++ (Yasin, 19 Nov: "upper right mini map should be a phone icon sized box, displaying
// a 3d looking 2d arrow head like shape showing the mission direction in green color, if there is no objective, golden
// yellow colored arrow head showing north. once clicked, it should review the full phone map"; "left corner money and
// time should fit into same sized box as phone and map"; "integrate health and needs but keep them inactive for now";
// "make sure the expansions happens animated along several frames for both the map and the phone, with sound effects and
// vibration when touched. also put an inventory on the left down corner stick to the ui standards again, phone sized,
// when clicked displays weapons we have, none for now in the game").
//
// Four boxes the size of the phone button (76 x 76 at 1152 x 648, the old spec's corners and margins), the ui_plate look:
//  - top left: money and the clock;  - top right: the arrow (HudArrow);  - bottom left: the inventory;
//  - bottom right: the phone button (the old one).
// The phone and the inventory open as panels that grow out of their box over 0.28 s (eased), with a tick and a 15 ms
// vibration on every touch; the arrow box opens the phone on its map. The phone's map is board item 8 (a panel waits for
// it). Health and needs: bars built under the money box, hidden while CityGame keeps them inactive.
// Hidden under menus and pause (CityGame); the boxes are kept out of the player's move / look touches.
#pragma once

#include <godot_cpp/classes/canvas_layer.hpp>
#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class Label;
class PanelContainer;
class AudioStreamPlayer;
class VBoxContainer;

// The arrowhead, drawn: two halves lit and shaded about its spine (it reads as a 3D wedge), a soft shadow and a keyline.
// Green to the objective, golden yellow to the north when there is none. Turned by the bearing from the camera's view.
class HudArrow : public Control {
	GDCLASS(HudArrow, Control)
protected:
	static void _bind_methods() {}
public:
	float angle = 0.0f;            // rad, 0 = up the screen (straight ahead), + = clockwise
	bool objective = false;
	void _draw() override;
};

class CityHud : public CanvasLayer {
	GDCLASS(CityHud, CanvasLayer)

	PanelContainer *b_money = nullptr, *b_arrow = nullptr, *b_inv = nullptr, *b_phone = nullptr;
	HudArrow *arrow = nullptr;
	Label *l_money = nullptr, *l_time = nullptr;
	Control *needs_box = nullptr;
	// the two panels that open: 0 the phone (its map), 1 the inventory
	PanelContainer *pan[2] = { nullptr, nullptr };
	int open = -1;                 // which panel is open (or opening / closing)
	float anim = 0.0f;             // 0 closed .. 1 open
	int anim_dir = 0;              // +1 opening, -1 closing
	Rect2 from_rect[2], to_rect[2];
	AudioStreamPlayer *tick = nullptr;
	uint64_t player_id = 0;
	Vector2 last_sz;
	int taps = 0;
	void build();
	void layout(const Vector2 &sz);
	void touch(int p_what);        // 0 the arrow, 1 the phone, 2 the inventory, 3 a panel's close
	void feedback();               // the tick and the vibration of a touch

protected:
	static void _bind_methods();

public:
	void _ready() override;
	void _process(double p_delta) override;
	void _input(const Ref<InputEvent> &p_event) override;

	void set_player(Object *p_player) { player_id = p_player ? (uint64_t)p_player->get_instance_id() : 0; }
	// the tests (and keys: M map, P phone, I inventory): press as a thumb would
	void press(int p_what) { touch(p_what); }
	int get_open() const { return anim_dir >= 0 && open >= 0 && anim > 0.0f ? open : -1; }
	float get_anim() const { return anim; }
	int get_taps() const { return taps; }
	float get_arrow_angle() const { return arrow ? arrow->angle : 0.0f; }
	bool get_arrow_objective() const { return arrow && arrow->objective; }
	String get_money_text() const;
	String get_time_text() const;
	Rect2 box_rect(int p_what) const;   // 0 arrow, 1 phone, 2 inventory, 3 money
};

} // namespace godot
