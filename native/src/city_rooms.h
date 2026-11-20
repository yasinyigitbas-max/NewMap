// CityRooms: the walk-in rooms of the city's shops, civic buildings and the like, woken by distance (B14, Yasin 20 Nov: "none
// of the shops appear in the game, i think they were forgotten to be cut in the bake step"; code work is C++).
//  - THE BAKE (tools/city/bake/bake_runtime.gd) cuts each enterable building's doors and ground-floor windows out of its
//    near model, opens its collision shell at the entrances, and lists the building's rooms on its node (meta "rooms":
//    [{"scn": merged room scene, "col": collision data, "centre": building-local}]). The rooms themselves are the interiors
//    sessions' scenes, merged for the phone (tools/city/rooms/room_merge.gd: a few draws a room).
//  - HERE: a room is loaded (on the engine's loader threads) when the camera comes within WAKE_M of it - the building's cut
//    near model shows to ~62 m, so the room must be there before its windows are seen - and handed back to the streamer's
//    cleanup thread beyond SLEEP_M. Each room's collision (its shell's faces and box colliders for its furniture, made by
//    the bake) is attached with it. Its lights fade with distance (none beyond LIGHT_M). At most MAX_LIVE rooms at once,
//    nearest first.
//  - THE DOORS: the rooms' hinged leaves (DoorLeaf_* nodes; their GDScript is dropped) swing away from whoever comes within
//    DOOR_TRIGGER of the door's middle, into the room or out to the street, and close behind them (the room builder's
//    rules, room_lib.gd / door_swing.gd: max angle, speed, ease).
// Made by CityStream (a child of it); follows its cells (cell_in / cell_out).
#pragma once
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/templates/hash_map.hpp>
#include <vector>

namespace godot {

class CityRooms : public Node3D {
	GDCLASS(CityRooms, Node3D)
	static constexpr float WAKE_M = 75.0f, SLEEP_M = 95.0f, LIGHT_M = 40.0f, DOOR_TRIGGER = 2.2f, DOOR_MAX_DEG = 95.0f, DOOR_SPEED = 2.6f;
	// MAX_LIGHTS: the engine's mobile light grid draws up to 32 lights for one fixed cost and drops the rest (sorted by view depth);
	// the city's lamps take 20 (rig / game Lights budget), so the rooms get the other 12: the nearest rooms' lights, room by room
	static constexpr int MAX_LIVE = 10, MAX_LIGHTS = 12;
	struct Leaf { uint64_t node = 0; Vector3 mid, out_dir; float sign = 1.0f, amount = 0.0f, dir = 1.0f; };
	struct Room {
		String cell, scn, raw, col; uint64_t building = 0; Vector3 centre_local, centre_world;
		int state = 0;           // 0 asleep, 1 loading, 2 awake
		uint64_t node = 0;       // the room's root (awake)
		std::vector<Leaf> leaves;
		std::vector<uint64_t> lights;      // the room's lights (on only while it is among the nearest lit rooms)
		bool lit = true;
	};
	std::vector<Room> rooms;
	HashMap<String, std::vector<int>> by_cell;
	std::vector<String> arriving;
	std::vector<int> free_slots;
	uint64_t stream_id = 0;
	int frame = 0, live = 0, loading = 0, woken = 0;
	void add_cell(const String &p_key);
	void drop_cell(const String &p_key);
	void wake(int i);
	void finish(int i);
	void sleep(int i);
	void doors(double p_delta, const Vector3 &p_cam);
	void light_rooms(const Vector3 &p_cam);
	void set_lit(Room &rm, bool p_on);
	void set_open(Room &rm, bool p_open);      // the building's near model: cut open (room in) or closed (no room)
protected:
	static void _bind_methods();
public:
	void set_stream(Object *p_stream);
	void _on_cell_in(const String &p_key) { arriving.push_back(p_key); }
	void _on_cell_out(const String &p_key) { drop_cell(p_key); }
	Dictionary get_state() const;
	void _process(double p_delta) override;
	void _exit_tree() override;
};

} // namespace godot
