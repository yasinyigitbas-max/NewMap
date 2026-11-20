// CityShops (city_shops.h says what it does).
#include "city_shops.h"

#include "city_crowd.h"
#include "city_game.h"
#include "city_hud.h"
#include "city_player.h"
#include "city_rooms.h"
#include "ped_crowd.h"

#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

namespace {
const char *const PEOPLE_JSON = "res://map_dc/coronado/city_kit/traffic/room_people.json";
float rnd() { return (float)UtilityFunctions::randf(); }
const StringName &C_IDLE() { static const StringName s("ual/Counter_Idle_Loop"); return s; }
const StringName &C_SHOW() { static const StringName s("ual/Counter_Show"); return s; }
const StringName &C_GIVE() { static const StringName s("ual/Counter_Give"); return s; }
const StringName &TAKE() { static const StringName s("ual/Interact"); return s; }
const StringName &LOOK() { static const StringName s("ual/Idle_LookAround_Loop"); return s; }
const StringName &IDLE() { static const StringName s("ual/Idle_Loop"); return s; }
const StringName &NO() { static const StringName s("ual/Idle_No_Loop"); return s; }
// the pay: four moves, 1.4 s each: rung up, the money over, the goods over, taken
const float STEP_S = 1.4f;
} // namespace

void CityShops::set_world(Object *p_crowd, Object *p_player) {
	crowd_id = p_crowd ? (uint64_t)p_crowd->get_instance_id() : 0;
	player_id = p_player ? (uint64_t)p_player->get_instance_id() : 0;
}

void CityShops::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) return;
	if (FileAccess::file_exists(PEOPLE_JSON)) {
		const Variant v = JSON::parse_string(FileAccess::get_file_as_string(PEOPLE_JSON));
		if (v.get_type() == Variant::DICTIONARY) { data = ((Dictionary)v).get("rooms", Dictionary()); loaded = true; }
	}
	if (!loaded) UtilityFunctions::push_warning("CityShops: no ", PEOPLE_JSON, " (run tools/city/rooms/room_people.gd)");
	set_process(true);
}

void CityShops::_exit_tree() {
	for (Shop &s : shops) close_shop(s);
	shops.clear();
}

CityShops::Spots CityShops::spots_of(const String &p_room) const {
	Spots sp;
	if (!data.has(p_room)) return sp;
	const Dictionary d = data[p_room];
	auto v3 = [](const Array &a) { return Vector3((float)(double)a[0], 0.0f, (float)(double)a[1]); };
	const Array st = d.get("staff", Array()), qu = d.get("queue", Array()), di = d.get("door_in", Array()), dout = d.get("door_out", Array()), br = d.get("browse", Array());
	if (st.size() < 3 || qu.size() < 3 || di.size() < 2 || dout.size() < 2) return sp;
	sp.kind = d.get("kind", ""); sp.name = d.get("name", "");
	sp.staff = v3(st); sp.staff_yaw = (float)(double)st[2];
	sp.queue = v3(qu); sp.queue_yaw = (float)(double)qu[2];
	sp.door_in = v3(di); sp.door_out = v3(dout);
	for (int k = 0; k < br.size(); k++) { const Array b = br[k]; if (b.size() >= 3) { sp.browse.push_back(v3(b)); sp.browse_yaw.push_back((float)(double)b[2]); } }
	const Array se = d.get("seats", Array());
	for (int k = 0; k < se.size(); k++) { const Array b = se[k]; if (b.size() >= 3) { sp.seats.push_back(v3(b)); sp.seat_yaw.push_back((float)(double)b[2]); } }
	sp.ok = true;
	return sp;
}

Vector3 CityShops::w(const Shop &s, const Vector3 &p_local) const { return s.xf.xform(p_local); }
float CityShops::wyaw(const Shop &s, float p_yaw) const {
	const Vector3 f = s.xf.basis.xform(Vector3(std::sin(p_yaw), 0.0f, std::cos(p_yaw)));
	return std::atan2(f.x, f.z);
}

void CityShops::open_shop(const String &p_room, const Transform3D &p_xf) {
	CityCrowd *cr = crowd_id ? Object::cast_to<CityCrowd>(ObjectDB::get_instance(ObjectID(crowd_id))) : nullptr;
	if (!cr) return;
	Shop s; s.room = p_room; s.xf = p_xf; s.sp = spots_of(p_room);
	if (!s.sp.ok) return;
	s.cashier = cr->actor_place(w(s, s.sp.staff), 0, wyaw(s, s.sp.staff_yaw), 9);
	if (s.cashier < 0) return;
	cr->actor_stand(s.cashier, wyaw(s, s.sp.staff_yaw), C_IDLE(), -1.0, 0);
	s.next = 1.0f + 4.0f * rnd();
	s.floor_y = p_xf.origin.y + 0.02f;   // (the room's floor: 2 cm over its piece's ground, the interiors' rule)
	static const char *const SERVES[] = { "cafe", "restaurant", "bar", "bakery", "fast_food", "diner", "ice_cream", "taqueria", "canteen", "taproom", "panaderia", "coffee" };
	for (const char *k : SERVES) if (s.sp.kind == k) s.serves = true;
	// people already sitting: about a third of the seats (one at least where there are seats), four at most
	s.seat_taken.assign(s.sp.seats.size(), 0);
	shops.push_back(s);
	Shop &sh = shops.back();
	const int want = std::min((int)sh.sp.seats.size() == 0 ? 0 : std::max(1, (int)sh.sp.seats.size() / 3), 4);
	for (int k = 0; k < want; k++) {
		const int st = free_seat(sh);
		if (st < 0) break;
		const int wk = cr->actor_place(w(sh, sh.sp.seats[st]), 0, wyaw(sh, sh.sp.seat_yaw[st]), CityCrowd::R_SITTER);
		if (wk >= 0) seat(sh, wk, st, 30.0f + 90.0f * rnd(), true);
	}
}

bool CityShops::open_room(const String &p_room, const Transform3D &p_xf) {
	const size_t n = shops.size();
	open_shop(p_room, p_xf);
	if (shops.size() == n) return false;
	shops.back().manual = true;
	return true;
}

void CityShops::close_shop(Shop &s) {
	CityCrowd *cr = crowd_id ? Object::cast_to<CityCrowd>(ObjectDB::get_instance(ObjectID(crowd_id))) : nullptr;
	if (!cr) return;
	if (s.cashier >= 0) cr->actor_release(s.cashier);
	for (Customer &c : s.cust) if (c.walker >= 0 && cr->is_actor(c.walker)) cr->actor_release(c.walker);
	for (Sitter &t : s.sit) if (t.walker >= 0 && cr->is_actor(t.walker)) cr->actor_release(t.walker);
	s.cashier = -1; s.cust.clear(); s.sit.clear();
	CityPlayer *pl = player_id ? Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	if (s.pay_who == -1 && pl) pl->set_frozen(false);
}

// what a shop of a kind sells, and for how much (English; the helper language in r_tr)
String CityShops::price_item(const String &p_kind, int &r_price, String &r_tr) const {
	struct It { const char *kinds; const char *en; const char *tr; int price; };
	static const It ITEMS[] = {
		{ "cafe,coffee", "a coffee", "bir kahve", 4 }, { "bakery,panaderia,pastry", "some bread", "ekmek", 3 },
		{ "restaurant,diner,taqueria,fast_food,canteen,drive_thru", "a meal", "bir yemek", 9 },
		{ "bar,taproom,liquor,venue", "a drink", "bir içecek", 6 }, { "ice_cream", "an ice cream", "bir dondurma", 4 },
		{ "store,corner_shop,corner,bodega,grocery,discount,gas,market", "a snack", "atıştırmalık", 3 },
		{ "pharmacy,clinic,physio", "some medicine", "ilaç", 7 }, { "books,library,print", "a book", "bir kitap", 12 },
		{ "clothes,thrift,workwear", "a shirt", "bir gömlek", 20 }, { "shoes", "a pair of shoes", "bir çift ayakkabı", 35 },
		{ "sport,bike,bikes,gym", "a water bottle", "bir su şişesi", 5 }, { "souvenir,gallery", "a postcard", "bir kartpostal", 2 },
		{ "keys", "a key", "bir anahtar", 5 }, { "cleaners,laundry,laundromat,dry_cleaner", "clean clothes", "temiz giysiler", 8 },
	};
	for (const It &it : ITEMS) {
		const PackedStringArray ks = String(it.kinds).split(",");
		for (int k = 0; k < ks.size(); k++) if (p_kind == ks[k]) { r_price = it.price; r_tr = String::utf8(it.tr); return String(it.en); }
	}
	r_price = 5; r_tr = String::utf8("bir şey");
	return String("something");
}

bool CityShops::can_buy() const {
	CityPlayer *pl = player_id ? Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	if (!pl || !pl->is_visible_in_tree() || pl->is_frozen()) return false;
	const Vector3 pp = pl->get_global_position();
	for (const Shop &s : shops) {
		if (s.cashier < 0 || s.pay_who != -2) continue;
		const Vector3 q = w(s, s.sp.queue);
		if (Vector2(pp.x - q.x, pp.z - q.z).length() < 1.0f && std::fabs(pp.y - q.y) < 1.5f) return true;
	}
	return false;
}

bool CityShops::buy() {
	CityPlayer *pl = player_id ? Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	if (!pl || !can_buy()) return false;
	const Vector3 pp = pl->get_global_position();
	for (Shop &s : shops) {
		const Vector3 q = w(s, s.sp.queue);
		if (s.cashier < 0 || s.pay_who != -2 || Vector2(pp.x - q.x, pp.z - q.z).length() >= 1.0f) continue;
		if (purchase_screen) return open_purchase(s.cashier);
		s.pay_who = -1; s.pay_t = 0.0f; s.pay_step = 0; s.custom = false;
		buys++;
		return true;
	}
	return false;
}

bool CityShops::is_cashier(int p_walker) const {
	for (const Shop &s : shops) if (s.cashier == p_walker && p_walker >= 0) return true;
	return false;
}

// THE PURCHASE SCREEN's hook: the cashier waits for the player, facing him; the screen is told what the shop is
bool CityShops::open_purchase(int p_cashier) {
	CityCrowd *cr = crowd_id ? Object::cast_to<CityCrowd>(ObjectDB::get_instance(ObjectID(crowd_id))) : nullptr;
	for (Shop &s : shops) {
		if (s.cashier != p_cashier || p_cashier < 0) continue;
		if (s.pay_who != -2) return false;   // (busy with a customer)
		s.pay_who = -3; s.pay_t = 0.0f; s.pay_step = 0;
		if (cr) cr->actor_stand(s.cashier, wyaw(s, s.sp.staff_yaw), C_IDLE(), -1.0, 0);
		int price = 0; String tr; const String item = price_item(s.sp.kind, price, tr);
		Dictionary d;
		d["room"] = s.room; d["kind"] = s.sp.kind; d["name"] = s.sp.name; d["cashier"] = s.cashier; d["item"] = item; d["item_tr"] = tr; d["price"] = price;
		screens++;
		emit_signal("purchase_requested", d);
		return true;
	}
	return false;
}

bool CityShops::complete_purchase(const String &p_item, const String &p_item_tr, int p_price) {
	for (Shop &s : shops) {
		if (s.pay_who != -3) continue;
		s.custom = true; s.c_item = p_item; s.c_tr = p_item_tr; s.c_price = std::max(p_price, 0);
		s.pay_who = -1; s.pay_t = 0.0f; s.pay_step = 0;
		buys++;
		return true;
	}
	return false;
}

void CityShops::cancel_purchase() {
	for (Shop &s : shops) if (s.pay_who == -3) { s.pay_who = -2; s.pay_t = 0.0f; s.pay_step = 0; }
}

// the pay at the counter, for a customer or the player: rung up, the money over, the goods over, taken (four moves)
void CityShops::pay_update(Shop &s, double p_delta) {
	CityCrowd *cr = Object::cast_to<CityCrowd>(ObjectDB::get_instance(ObjectID(crowd_id)));
	CityPlayer *pl = player_id ? Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	if (!cr || s.pay_who == -2 || s.pay_who == -3) return;   // (nobody paying; the purchase screen open: he waits)
	const float sy = wyaw(s, s.sp.staff_yaw), qy = wyaw(s, s.sp.queue_yaw);
	const bool player = s.pay_who == -1;
	s.pay_t += (float)p_delta;
	if (s.no_money && s.pay_t < 2.2f) return;   // (he shakes his head a moment, then it is over)
	const int step = s.no_money ? 3 : (int)(s.pay_t / STEP_S);
	if (step == s.pay_step && s.pay_t > 0.05f) return;
	s.pay_step = step;
	int price = 0; String tr; String item = price_item(s.sp.kind, price, tr);
	if (player && s.custom) { item = s.c_item; tr = s.c_tr; price = s.c_price; }
	CityGame *g = CityGame::get();
	if (player && step == 0 && g && g->get_money() < price) {   // not enough: he shakes his head
		cr->actor_stand(s.cashier, sy, NO(), -1.0, 0);
		if (CityHud *h = Object::cast_to<CityHud>(g->get_hud())) h->note(String("Not enough money (") + item + String(": $") + String::num_int64(price) + String(")"), String::utf8("Paran yetmiyor"), 2.5);
		refused++; s.no_money = true; s.pay_t = 0.0f;
		return;
	}
	switch (step) {
		case 0:   // rung up
			cr->actor_stand(s.cashier, sy, C_SHOW(), -2.0, 8101 + (int)(s.pay_t * 0.0f) + sales * 4);
			if (player && pl) pl->act(IDLE(), STEP_S, qy);
			break;
		case 1:   // the money over
			cr->actor_stand(s.cashier, sy, C_IDLE(), -1.0, 0);
			if (player && pl) pl->act(C_GIVE(), STEP_S, qy);
			else cr->actor_stand(s.pay_who, qy, C_GIVE(), -2.0, 8102 + sales * 4);
			break;
		case 2:   // the goods over
			cr->actor_stand(s.cashier, sy, C_GIVE(), -2.0, 8103 + sales * 4);
			if (player && pl) pl->act(TAKE(), STEP_S, qy);
			else cr->actor_stand(s.pay_who, qy, TAKE(), -2.0, 8104 + sales * 4);
			break;
		default:  // done
			if (player && g && !s.no_money) {
				g->add_money(-price);
				if (CityHud *h = Object::cast_to<CityHud>(g->get_hud())) h->note(String("Bought ") + item + String("  -$") + String::num_int64(price), tr + String::utf8(" aldın"), 2.5);
			}
			cr->actor_stand(s.cashier, sy, C_IDLE(), -1.0, 0);
			sales++;
			for (Customer &c : s.cust) {
				if (c.walker != s.pay_who) continue;
				const int st = s.serves && rnd() < 0.6f ? free_seat(s) : -1;
				if (st >= 0) {   // with what he bought, to a free seat a while
					Sitter t; t.walker = c.walker; t.seat = st; t.st = S_GO; t.stay = 25.0f + 50.0f * rnd();
					s.seat_taken[st] = 1; s.sit.push_back(t);
					cr->actor_go(c.walker, w(s, s.sp.seats[st]), 1.2, 0.15);
					if (CityCrowd::Actor *a = cr->actor_of(c.walker)) a->role = CityCrowd::R_SITTER;
					c.st = C_GONE;   // (a sitter now)
				} else { c.st = C_OUT; c.t = 0.0f; cr->actor_go(c.walker, w(s, s.sp.door_in), 1.3, 0.35); }
			}
			s.pay_who = -2; s.pay_t = 0.0f; s.pay_step = 0; s.no_money = false;
			break;
	}
}

void CityShops::shop_update(Shop &s, double p_delta) {
	CityCrowd *cr = Object::cast_to<CityCrowd>(ObjectDB::get_instance(ObjectID(crowd_id)));
	if (!cr) return;
	const float dt = (float)p_delta;
	if (s.cashier >= 0 && !cr->walker_alive(s.cashier)) s.cashier = -1;
	if (s.cashier < 0) return;
	// a new customer now and then, at the door
	s.next -= dt;
	if (s.next <= 0.0f && (int)s.cust.size() < MAX_CUSTOMERS) {
		const Vector3 at = w(s, s.sp.door_out), in = w(s, s.sp.door_in);
		const int c = cr->actor_place(at, 0, std::atan2(in.x - at.x, in.z - at.z), 10);
		if (c >= 0) { Customer cu; cu.walker = c; cu.st = C_IN; s.cust.push_back(cu); cr->actor_go(c, in, 1.25, 0.3); customers_in++; }
		s.next = 8.0f + 10.0f * rnd();
	}
	for (Customer &c : s.cust) {
		if (c.st == C_GONE) continue;
		if (!cr->walker_alive(c.walker) || !cr->is_actor(c.walker)) { c.st = C_GONE; continue; }
		c.t += dt;
		switch (c.st) {
			case C_IN:   // in at the door: to a shelf, or straight to the counter if there is none
				if (cr->actor_arrived(c.walker) || c.t > 12.0f) {
					if (!s.sp.browse.empty()) { c.spot = (int)(rnd() * (float)s.sp.browse.size()) % (int)s.sp.browse.size(); cr->actor_go(c.walker, w(s, s.sp.browse[c.spot]), 1.2, 0.25); c.st = C_BROWSE; }
					else { cr->actor_go(c.walker, w(s, s.sp.queue), 1.2, 0.2); c.st = C_QUEUE; }
					c.t = 0.0f;
				}
				break;
			case C_BROWSE:   // at the shelf: he looks along it a while
				if (cr->actor_arrived(c.walker) || c.t > 15.0f) {
					cr->actor_stand(c.walker, wyaw(s, s.sp.browse_yaw[c.spot]), LOOK(), -1.0, 0);
					c.look = 4.0f + 5.0f * rnd(); c.looks++; c.st = C_LOOK; c.t = 0.0f;
				}
				break;
			case C_LOOK:
				if (c.t > c.look) {
					if (c.looks < 2 && s.sp.browse.size() > 1 && rnd() < 0.5f) { c.spot = (c.spot + 1 + (int)(rnd() * (float)(s.sp.browse.size() - 1))) % (int)s.sp.browse.size(); cr->actor_go(c.walker, w(s, s.sp.browse[c.spot]), 1.2, 0.25); c.st = C_BROWSE; }
					else c.st = C_QUEUE;
					c.t = 0.0f;
					if (c.st == C_QUEUE) {   // to the counter, or behind whoever is at it
						bool taken = s.pay_who != -2;
						for (const Customer &o : s.cust) if (&o != &c && (o.st == C_QUEUE || o.st == C_PAY)) taken = true;
						const Vector3 q = w(s, s.sp.queue), back = s.xf.basis.xform(Vector3(-std::sin(s.sp.queue_yaw), 0.0f, -std::cos(s.sp.queue_yaw)));
						if (taken) { cr->actor_go(c.walker, q + back * 1.1f, 1.2, 0.2); c.st = C_WAIT; }
						else cr->actor_go(c.walker, q, 1.2, 0.2);
					}
				}
				break;
			case C_WAIT: {   // behind the one at the counter: forward when it is free
				bool taken = s.pay_who != -2;
				for (const Customer &o : s.cust) if (&o != &c && (o.st == C_QUEUE || o.st == C_PAY)) taken = true;
				if (cr->actor_arrived(c.walker) && cr->actor_role(c.walker) == 10) cr->actor_stand(c.walker, wyaw(s, s.sp.queue_yaw), IDLE(), -1.0, 0);
				if (!taken) { cr->actor_go(c.walker, w(s, s.sp.queue), 1.0, 0.2); c.st = C_QUEUE; c.t = 0.0f; }
			} break;
			case C_QUEUE:   // at the counter: his turn when the cashier is free
				if ((cr->actor_arrived(c.walker) || c.t > 15.0f) && s.pay_who == -2) {
					cr->actor_stand(c.walker, wyaw(s, s.sp.queue_yaw), IDLE(), -1.0, 0);
					s.pay_who = c.walker; s.pay_t = 0.0f; s.pay_step = 0; c.st = C_PAY; c.t = 0.0f;
				}
				break;
			case C_OUT:   // out of the door, onto the pavement, and on his way as anybody
				if (c.t < 30.0f && cr->actor_arrived(c.walker) && cr->walker_at(c.walker).distance_to(w(s, s.sp.door_in)) < 0.6f) { cr->actor_go(c.walker, w(s, s.sp.door_out), 1.3, 0.3); c.t = 30.0f; }
				else if (c.t > 30.0f && (cr->actor_arrived(c.walker) || c.t > 45.0f)) { cr->actor_free(c.walker); c.st = C_GONE; customers_out++; }
				break;
			default: break;
		}
	}
	s.cust.erase(std::remove_if(s.cust.begin(), s.cust.end(), [](const Customer &c) { return c.st == C_GONE; }), s.cust.end());
	pay_update(s, p_delta);
	sit_update(s, p_delta);
}

int CityShops::free_seat(const Shop &s) const {
	std::vector<int> fr;
	for (int k = 0; k < (int)s.seat_taken.size(); k++) if (!s.seat_taken[k]) fr.push_back(k);
	if (fr.empty()) return -1;
	return fr[(size_t)(rnd() * (float)fr.size()) % fr.size()];
}

// he sits: on the seat's spot, the floor's height, a sitting clip of his own (idle, a drink, a word, the phone)
void CityShops::seat(Shop &s, int p_walker, int p_seat, float p_stay, bool p_placed) {
	CityCrowd *cr = Object::cast_to<CityCrowd>(ObjectDB::get_instance(ObjectID(crowd_id)));
	if (!cr) return;
	static const StringName SITS[6] = { StringName("ual/Sitting_Idle_Loop"), StringName("ual/Sitting_Idle02_Loop"), StringName("ual/Sitting_Drink_Loop"), StringName("ual/Sitting_Talking_Loop"), StringName("ual/Sitting_Phone_Loop"), StringName("ual/Sitting_Text_Loop") };
	const int pick = (int)(rnd() * 6.0f) % 6;
	const StringName &clip = (s.serves && rnd() < 0.5f) ? SITS[2] : SITS[pick];
	cr->actor_seat(p_walker, s.floor_y, wyaw(s, s.sp.seat_yaw[p_seat]), clip);
	if (p_placed) { Sitter t; t.walker = p_walker; t.seat = p_seat; t.st = S_SIT; t.stay = p_stay; s.sit.push_back(t); }
	s.seat_taken[p_seat] = 1;
	sat_down++;
}

void CityShops::sit_update(Shop &s, double p_delta) {
	CityCrowd *cr = Object::cast_to<CityCrowd>(ObjectDB::get_instance(ObjectID(crowd_id)));
	if (!cr) return;
	static const StringName RISE("ual/Sitting_Exit");
	for (Sitter &t : s.sit) {
		if (t.st == S_DONE) continue;
		if (!cr->walker_alive(t.walker) || !cr->is_actor(t.walker)) { if (t.seat >= 0) s.seat_taken[t.seat] = 0; t.st = S_DONE; continue; }
		CityCrowd::Actor *a = cr->actor_of(t.walker);
		if (a && a->talking) continue;   // (talked to: he stays put)
		t.t += (float)p_delta;
		switch (t.st) {
			case S_GO:   // to his seat with what he bought
				if (cr->actor_arrived(t.walker) || t.t > 15.0f) { seat(s, t.walker, t.seat, t.stay, false); t.st = S_SIT; t.t = 0.0f; }
				break;
			case S_SIT:
				if (t.t > t.stay) { cr->actor_stand(t.walker, wyaw(s, s.sp.seat_yaw[t.seat]), RISE, -2.0, 7301 + got_up); t.st = S_RISE; t.t = 0.0f; }
				break;
			case S_RISE:   // up out of the seat; then out of the door
				if (t.t > 1.3f) {
					if (a) a->seated = false;
					s.seat_taken[t.seat] = 0;
					cr->actor_go(t.walker, w(s, s.sp.door_in), 1.3, 0.35);
					t.st = S_LEAVE; t.t = 0.0f; got_up++;
				}
				break;
			case S_LEAVE:
				if (cr->actor_arrived(t.walker) || t.t > 20.0f) { cr->actor_go(t.walker, w(s, s.sp.door_out), 1.3, 0.3); t.st = S_GO + 10; t.t = 0.0f; }
				break;
			default:   // (13) out on the pavement: on his way as anybody
				if (cr->actor_arrived(t.walker) || t.t > 15.0f) { cr->actor_free(t.walker); t.st = S_DONE; customers_out++; }
				break;
		}
	}
	s.sit.erase(std::remove_if(s.sit.begin(), s.sit.end(), [](const Sitter &t) { return t.st == S_DONE; }), s.sit.end());
}

void CityShops::_process(double p_delta) {
	CityCrowd *cr = crowd_id ? Object::cast_to<CityCrowd>(ObjectDB::get_instance(ObjectID(crowd_id))) : nullptr;
	if (!cr || !loaded) return;
	Vector3 cam;
	if (Viewport *vp = get_viewport()) if (Camera3D *c = vp->get_camera_3d()) cam = c->get_global_position();
	// which shops: the awake rooms nearest the camera (CityRooms), now and then
	scan_t -= (float)p_delta;
	if (scan_t <= 0.0f) {
		scan_t = 0.5f;
		CityRooms *rooms = nullptr;
		if (!rooms_id && get_tree()) { const TypedArray<Node> rs = get_tree()->get_nodes_in_group("city_rooms"); if (rs.size() > 0) rooms_id = Object::cast_to<Node>(rs[0])->get_instance_id(); }
		rooms = rooms_id ? Object::cast_to<CityRooms>(ObjectDB::get_instance(ObjectID(rooms_id))) : nullptr;
		std::vector<std::pair<String, Transform3D>> awake;
		if (rooms) rooms->awake_rooms(awake);
		struct Want { float d; int k; };
		std::vector<Want> want;
		for (int k = 0; k < (int)awake.size(); k++) {
			if (!data.has(awake[k].first)) continue;
			const float d = awake[k].second.origin.distance_to(cam);
			if (d < SHOP_M) want.push_back(Want{ d, k });
		}
		std::sort(want.begin(), want.end(), [](const Want &a, const Want &b) { return a.d < b.d; });
		if ((int)want.size() > MAX_SHOPS) want.resize(MAX_SHOPS);
		for (Shop &s : shops) {
			if (s.manual) continue;
			bool keep = false;
			for (const Want &q : want) if (awake[q.k].first == s.room && awake[q.k].second.origin.distance_squared_to(s.xf.origin) < 1.0f) keep = true;
			if (!keep) { close_shop(s); s.room = String(); }
		}
		shops.erase(std::remove_if(shops.begin(), shops.end(), [](const Shop &s) { return s.room.is_empty(); }), shops.end());
		for (const Want &q : want) {
			bool have = false;
			for (const Shop &s : shops) if (s.room == awake[q.k].first && s.xf.origin.distance_squared_to(awake[q.k].second.origin) < 1.0f) have = true;
			if (!have) open_shop(awake[q.k].first, awake[q.k].second);
		}
	}
	for (Shop &s : shops) shop_update(s, p_delta);
}

Array CityShops::shops_info() const {
	Array r;
	for (const Shop &s : shops) {
		Dictionary d;
		d["room"] = s.room; d["kind"] = s.sp.kind; d["cashier"] = s.cashier; d["paying"] = s.pay_who; d["step"] = s.pay_step;
		d["staff"] = w(s, s.sp.staff); d["queue"] = w(s, s.sp.queue); d["door_out"] = w(s, s.sp.door_out);
		Array cs; for (const Customer &c : s.cust) { Dictionary e; e["walker"] = c.walker; e["state"] = c.st; cs.push_back(e); }
		d["customers"] = cs;
		Array ss; for (const Sitter &t : s.sit) { Dictionary e; e["walker"] = t.walker; e["state"] = t.st; e["seat"] = t.seat; ss.push_back(e); }
		d["sitters"] = ss; d["seats"] = (int)s.sp.seats.size(); d["serves"] = s.serves;
		r.push_back(d);
	}
	return r;
}

Dictionary CityShops::stats() const {
	Dictionary d;
	d["shops"] = (int)shops.size(); d["sales"] = sales; d["buys"] = buys; d["refused"] = refused; d["customers_in"] = customers_in; d["customers_out"] = customers_out; d["sat_down"] = sat_down; d["got_up"] = got_up; d["screens"] = screens; d["loaded"] = loaded; d["rooms_known"] = data.size();
	return d;
}

void CityShops::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_world", "crowd", "player"), &CityShops::set_world);
	ClassDB::bind_method(D_METHOD("can_buy"), &CityShops::can_buy);
	ClassDB::bind_method(D_METHOD("buy"), &CityShops::buy);
	ClassDB::bind_method(D_METHOD("open_room", "room", "xf"), &CityShops::open_room);
	ClassDB::bind_method(D_METHOD("shops_info"), &CityShops::shops_info);
	ClassDB::bind_method(D_METHOD("stats"), &CityShops::stats);
	ClassDB::bind_method(D_METHOD("set_purchase_screen", "on"), &CityShops::set_purchase_screen);
	ClassDB::bind_method(D_METHOD("get_purchase_screen"), &CityShops::get_purchase_screen);
	ClassDB::bind_method(D_METHOD("open_purchase", "cashier"), &CityShops::open_purchase);
	ClassDB::bind_method(D_METHOD("complete_purchase", "item", "item_tr", "price"), &CityShops::complete_purchase);
	ClassDB::bind_method(D_METHOD("cancel_purchase"), &CityShops::cancel_purchase);
	ClassDB::bind_method(D_METHOD("is_cashier", "walker"), &CityShops::is_cashier);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "purchase_screen"), "set_purchase_screen", "get_purchase_screen");
	ADD_SIGNAL(MethodInfo("purchase_requested", PropertyInfo(Variant::DICTIONARY, "shop")));
}
