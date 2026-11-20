// CityShops: the people in the shops, all C++ (Yasin, 20 Nov: "add npcs into shops, some customers and a cashier, add us
// and npcs giving money receiving things animations").
//  - WHERE: tools/city/rooms/room_people.gd reads every room once (traffic/room_people.json): behind the till or counter
//    (the staff spot), in front of it (the queue), before shelves and fridges (browse spots), just in and just out of the
//    door, all in the room's own frame.
//  - WHO: the rooms CityRooms has awake within SHOP_M of the camera, the MAX_SHOPS nearest: a cashier behind the counter
//    (Counter_Idle_Loop), and up to two customers at a time who come in at the door, look at a shelf or two
//    (Idle_LookAround_Loop), queue, and pay: the cashier rings it up (Counter_Show), the customer hands the money over
//    (Counter_Give), the cashier hands the goods over (Counter_Give) and the customer takes them (Interact); then out of
//    the door and on along the pavement. They are the crowd's actors (CityCrowd: city_crowd_actors.cpp).
//  - THE PLAYER: on foot at a shop's queue spot with the cashier free, the Use button says BUY (SATIN AL): the same four
//    moves with him (CityPlayer::act), the money taken (the shop's kind sets what and how much), a word on the HUD; not
//    enough money: the cashier shakes his head.
#pragma once

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/transform3d.hpp>

#include <vector>

namespace godot {

class CityShops : public Node {
	GDCLASS(CityShops, Node)
public:
	static constexpr float SHOP_M = 45.0f;
	static constexpr int MAX_SHOPS = 4, MAX_CUSTOMERS = 2;
	enum { C_IN = 0, C_BROWSE = 1, C_LOOK = 2, C_QUEUE = 3, C_WAIT = 4, C_PAY = 5, C_OUT = 6, C_GONE = 7 };

private:
	uint64_t crowd_id = 0, player_id = 0, rooms_id = 0;
	struct Spots { String kind, name; Vector3 staff, queue, door_in, door_out; float staff_yaw = 0.0f, queue_yaw = 0.0f; std::vector<Vector3> browse; std::vector<float> browse_yaw; bool ok = false; };
	Dictionary data;            // room_people.json "rooms"
	bool loaded = false;
	struct Customer { int walker = -1, st = C_IN; float t = 0.0f, look = 0.0f; int looks = 0, spot = -1; };
	struct Shop {
		String room; Transform3D xf; Spots sp;
		int cashier = -1;
		std::vector<Customer> cust;
		float next = 0.0f;           // seconds to the next customer
		int pay_who = -2;            // who is paying now: -1 the player, a walker, -2 nobody
		float pay_t = 0.0f; int pay_step = 0;
		bool seen = true, manual = false, no_money = false;
	};
	std::vector<Shop> shops;
	float scan_t = 0.0f;
	Spots spots_of(const String &p_room) const;
	Vector3 w(const Shop &s, const Vector3 &p_local) const;
	float wyaw(const Shop &s, float p_yaw) const;
	void open_shop(const String &p_room, const Transform3D &p_xf);
	void close_shop(Shop &s);
	void shop_update(Shop &s, double p_delta);
	void pay_update(Shop &s, double p_delta);
	String price_item(const String &p_kind, int &r_price, String &r_tr) const;
	int buys = 0, sales = 0, refused = 0, customers_in = 0, customers_out = 0;

protected:
	static void _bind_methods();

public:
	void set_world(Object *p_crowd, Object *p_player);
	void _ready() override;
	void _process(double p_delta) override;
	void _exit_tree() override;
	// the player: is he at a shop's queue spot with its cashier free (the HUD's BUY); buy there
	bool can_buy() const;
	bool buy();
	Array shops_info() const;
	Dictionary stats() const;
	// (tests) a room as if CityRooms had it awake: the room's name (room_people.json) and where it stands
	bool open_room(const String &p_room, const Transform3D &p_xf);
};

} // namespace godot
