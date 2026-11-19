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

// THE PHONE'S MAP (board item 8; Yasin: "once clicked, it should review the full phone map, both should be adapted to the
// new layout of the map"): the new streets drawn, north up: the roads (every driven lane, as wide as a lane), the
// pavements and crossings (CityTraffic / CityCrowd map_lines: read once, drawn in one call each), the player (an arrow
// turned with his view), the objective (a green pin) and the way to it (CityTraffic.route, green). Drag pans, two fingers
// or the wheel zoom, the pin button centres on the player again.
class HudMap : public Control {
	GDCLASS(HudMap, Control)
	PackedVector2Array roads, walks, crossings, route;
	PackedVector3Array rooms;      // the enterable rooms' doors: x, z, the shop's kind
	Array targets_local;           // (no shell: the targets kept here)
	PackedVector2Array troute[3]; Vector2 troute_for[3];
	Vector2 press_at; bool press_moved = false;
	bool have_lines = false;
	Vector2 route_for = Vector2(1e9f, 1e9f);
	int touches = 0; Vector2 tp[2]; float pinch0 = 0.0f, mpp0 = 1.0f;
protected:
	static void _bind_methods();
public:
	Vector2 centre;                // world x, z at the map's middle
	float mpp = 0.6f;              // metres a pixel
	bool follow = true;            // centred on the player until dragged
	Vector2 player_xz; float player_yaw = 0.0f;   // (yaw: 0 = north, + = clockwise on the map)
	bool has_obj = false; Vector2 obj_xz;
	uint64_t traffic_id = 0, crowd_id = 0;
	void load_lines();
	void update_route();
	void _draw() override;
	void _gui_input(const Ref<InputEvent> &p_event) override;
	int get_road_lines() const { return roads.size() / 2; }
	int get_walk_lines() const { return walks.size() / 2; }
	int get_route_points() const { return route.size(); }
	// the player's targets (up to 3, kept in the save): a room tapped becomes one (again: it is dropped); a 4th the oldest goes
	Array targets() const;
	void set_targets(const Array &p_t);
	bool toggle_target(const Vector2 &p_xz, const String &p_name);
	int tap(const Vector2 &p_screen);   // a tap on the map: the room under it toggled as a target (its index, -1 none)
	int get_rooms() const { return rooms.size(); }
	Vector2 room_screen(int p_i) const;
	int get_target_count() const { return targets().size(); }
	int get_target_route_points(int p_k) const { return p_k >= 0 && p_k < 3 ? troute[p_k].size() : 0; }
};

class CityHud : public CanvasLayer {
	GDCLASS(CityHud, CanvasLayer)

	PanelContainer *b_money = nullptr, *b_arrow = nullptr, *b_inv = nullptr, *b_phone = nullptr;
	// THE USE BUTTON (the old game's Use plate; Yasin: "make the use button as big as phone and map boxes, vibrates and
	// makes sound when used but doesnt expand like the other buttons"): under the arrow box, green, shown only when there
	// is something to do: GET IN a car / GET ON a bicycle within reach (a vibration when a new one comes in reach), GET
	// OUT / GET OFF while driving or riding. A tap (or E): a tick, a vibration, done; nothing opens.
	PanelContainer *b_use = nullptr;
	Label *l_use_en = nullptr, *l_use_tr = nullptr;
	int use_kind = 0;              // 0 nothing, 1 get in, 2 get out, 3 get on, 4 get off
	uint64_t use_target = 0, use_last = 0;
	float use_scan = 0.0f;
	int uses = 0;
	bool e_was = false;
	void use_find(class CityPlayer *pl);
	void use_do();
	HudArrow *arrow = nullptr;
	HudMap *map = nullptr;
	uint64_t crowd_id = 0, traffic_id = 0;
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
	void recentre();

protected:
	static void _bind_methods();

public:
	void _ready() override;
	void _process(double p_delta) override;
	void _input(const Ref<InputEvent> &p_event) override;

	void set_player(Object *p_player) { player_id = p_player ? (uint64_t)p_player->get_instance_id() : 0; }
	void set_world(Object *p_crowd, Object *p_traffic) { crowd_id = p_crowd ? (uint64_t)p_crowd->get_instance_id() : 0; traffic_id = p_traffic ? (uint64_t)p_traffic->get_instance_id() : 0; }
	Object *get_map() const { return map; }
	// the tests (and keys: M map, P phone, I inventory): press as a thumb would
	void press(int p_what) { touch(p_what); }
	int get_open() const { return anim_dir >= 0 && open >= 0 && anim > 0.0f ? open : -1; }
	float get_anim() const { return anim; }
	int get_taps() const { return taps; }
	int get_use_kind() const { return use_kind; }
	int get_uses() const { return uses; }
	void press_use() { use_do(); }
	float get_arrow_angle() const { return arrow ? arrow->angle : 0.0f; }
	bool get_arrow_objective() const { return arrow && arrow->objective; }
	String get_money_text() const;
	String get_time_text() const;
	Rect2 box_rect(int p_what) const;   // 0 arrow, 1 phone, 2 inventory, 3 money
};

} // namespace godot
