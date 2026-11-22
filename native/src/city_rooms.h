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
	static constexpr float WAKE_M = 75.0f, SLEEP_M = 95.0f, LIGHT_M = 40.0f, DOOR_TRIGGER = 3.0f, DOOR_MAX_DEG = 95.0f, DOOR_SPEED = 3.6f;      // B34: 3 m from the player (was 2.2 m from the camera, 3.4 m behind him), open in ~0.3 s
	// MAX_LIGHTS: the engine's mobile light grid draws up to 32 lights for one fixed cost and drops the rest (sorted by view depth);
	// the city's lamps take 20 (rig / game Lights budget), so the rooms get the other 12: the nearest rooms' lights, room by room
	static constexpr int MAX_LIVE = 10, MAX_LIGHTS = 12;
	// a room's collision (median 1,040 triangles, up to 3,760) went in as ONE shape the moment the room came: the physics
	// thread built it in one step and the frame waited 46-90 ms for it (phone, 20 Nov: none of those with the rooms off).
	// Now in pieces of COL_TRIS, one piece a frame over all rooms, and only within COL_M (nobody touches a wall from 75 m)
	static constexpr int COL_TRIS = 400;
	static constexpr float COL_M = 40.0f;
	// hold: 0 = by proximity, 1 = held open, 2 = held shut (interact_door; let go when nobody is within HOLD_M)
	struct Leaf { uint64_t node = 0; Vector3 mid, out_dir; float sign = 1.0f, amount = 0.0f, dir = 1.0f, hp = 60.0f; int hold = 0; bool broken = false; String bid; };
	struct Win { uint64_t node = 0; String bid; float hp = 25.0f; bool broken = false, cracked = false; Vector2 uv = Vector2(0.5f, 0.55f); };
	static constexpr float HOLD_M = 8.0f, DOOR_HP = 60.0f, WINDOW_HP = 25.0f, WINDOW_CRACK_HP = 15.0f;
	struct Room {
		String cell, scn, raw, col; uint64_t building = 0; Vector3 centre_local, centre_world;
		int state = 0;           // 0 asleep, 1 loading, 2 awake
		uint64_t node = 0;       // the room's root (awake)
		std::vector<Leaf> leaves;
		std::vector<Win> wins;           // the breakable windows (Window_* with pane / remnant / body: built-in interiors)
		std::vector<uint64_t> lights;      // the room's lights (on only while it is among the nearest lit rooms)
		bool lit = true;
		PackedVector3Array col_faces;      // its collision, put in COL_TRIS at a time once the camera is within COL_M
		int col_at = 0;
		uint64_t body = 0;
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
	// the recorded sounds (el_sfx.h): a door's swing and shut (wood, glass or metal; a shop's bell), the nearest room's tone
	static int room_kind(const String &p_scn);   // 0 shop, 1 home, 2 office
	void door_sound(Node3D *p_leaf, const Vector3 &p_at, bool p_open, int p_kind);
	void room_tone(const Vector3 &p_cam);
	int tone_room = -1, door_sounds = 0, shard_bursts = 0;
	void set_lit(Room &rm, bool p_on);
	void set_open(Room &rm, bool p_open);
	// the breakables' states this session, by stable id (meta "bid", else "<room scene>|<node>"): {"state": "broken"|..., "hp"}
	// a room that wakes again shows them; the game's save takes them with get_breakables / set_breakables
	Dictionary breakables;
	static String bid_of(Node *p_n, const String &p_scn);
	void leaf_broken(Node3D *p_leaf);
	// a window as builtin_window.gd had it (its script is dropped in the game's rooms): cracked = the pane shader's crack
	// star at uv; broken = pane hidden, remnant shown, body off, the "shards" CPUParticles3D burst at the hit (p_burst), and
	// the sounds (glass_shatter_* / a tick for the crack) played from here
	static Vector2 win_uv(Node3D *p_win, const Vector3 &p_at);
	static void win_cracked(Node3D *p_win, const Vector2 &p_uv);
	void win_broken(Node3D *p_win, const Vector2 &p_uv, bool p_burst);
		void add_col(const Vector3 &p_cam);      // the next piece of the nearest room's collision      // the building's near model: cut open (room in) or closed (no room)
protected:
	static void _bind_methods();
public:
	void set_stream(Object *p_stream);
	void _on_cell_in(const String &p_key) { arriving.push_back(p_key); }
	void _on_cell_out(const String &p_key) { drop_cell(p_key); }
	Dictionary get_state() const;
	// the door / window hooks (22 Nov, INDOORS rollout: the C++ swing used to drop the leaves' GDScript, and with it these):
	//   interact_door(at, radius)       the nearest leaf within radius: open (away from `at`) or shut, held so until nobody is near
	//   damage_at(at, amount, radius)   the nearest door leaf or window within radius takes damage; at 0 hp it breaks (state
	//                                   swap: leaf -> leaf_broken, collision off; window: its own script, else pane -> remnant)
	//   returns the bid hit ("" none). Signals: door_toggled(bid, open), door_broken(bid, at), window_broken(bid, at)
	bool interact_door(const Vector3 &p_at, float p_radius);
	String damage_at(const Vector3 &p_at, float p_amount, float p_radius);
	Dictionary get_breakables() const { return breakables.duplicate(true); }
	void set_breakables(const Dictionary &p_d) { breakables = p_d.duplicate(true); }
	// the rooms awake now: the room's name (its scene's, as interiors/room_people.json names it) and where it stands
	void awake_rooms(std::vector<std::pair<String, Transform3D>> &r_out) const;
	void _process(double p_delta) override;
	void _exit_tree() override;
};

} // namespace godot
