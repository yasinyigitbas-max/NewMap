// Moves on things in the world that are not climbed: doors (stage 22), cars (stage 23), sitting, cover (stage 21).
// A line-for-line translation of traversal_lab/traversal/moves/interact.gd (the script version, the reference): the
// same names, the same numbers, the same order of work. The reasons for each thing are in the script.
#include "trav_interact.h"
#include "trav_probe.h"

#include "trav_math.h"

#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>

using namespace godot;
using namespace trav;

static const Vector3 UP(0, 1, 0);
static const Vector3 ZERO(0, 0, 0);
static inline double D(real_t x) { return (double)x; }
static inline double F(const Variant &v) { return (double)v; }
static inline Vector3 V(double x, double y, double z) { return Vector3((real_t)x, (real_t)y, (real_t)z); }
static inline Vector3 mul(const Vector3 &v, double s) { return v * (real_t)s; }
static inline Vector3 lerp3(const Vector3 &a, const Vector3 &b, double w) { return a.lerp(b, (real_t)w); }
static inline Dictionary sub(const Dictionary &d, const char *k) { return d[k]; }
// Dictionary.merge without overwrite, one key at a time
static inline void merge_new(Dictionary &d, const Variant &k, const Variant &v) {
	if (!d.has(k)) {
		d[k] = v;
	}
}
// the engine's own formulas, in doubles (core/math/math_funcs.h, 4.7)
static inline double smoothstep(double p_from, double p_to, double p_s) {
	if (is_equal_approx(p_from, p_to)) {
		if (p_from <= p_to) {
			return p_s <= p_from ? 0.0 : 1.0;
		} else {
			return p_s <= p_to ? 1.0 : 0.0;
		}
	}
	double s = clampf((p_s - p_from) / (p_to - p_from), 0.0, 1.0);
	return s * s * (3.0 - 2.0 * s);
}
static inline double fposmod(double p_x, double p_y) {
	double value = std::fmod(p_x, p_y);
	if (((value < 0) && (p_y > 0)) || ((value > 0) && (p_y < 0))) {
		value += p_y;
	}
	value += 0.0;
	return value;
}

TravInteract::TravInteract() {
#include "trav_interact_ctor.inc"
}

void TravInteract::_ready() {
	Array dk = DOOR.keys();
	for (int k = 0; k < dk.size(); k++) {
		_load((String)((Dictionary)DOOR[dk[k]])["clip"]);
	}
	Array sk = SIT.keys();
	for (int k = 0; k < sk.size(); k++) {
		_load((String)((Dictionary)SIT[sk[k]])["clip"]);
	}
	Array ck = CAR.keys();
	for (int k = 0; k < ck.size(); k++) {
		_load((String)((Dictionary)CAR[ck[k]])["clip"]);
	}
	Array vk = COVER.keys();
	const char *parts[4] = { "in", "out", "peek", "idle_clip" };
	for (int k = 0; k < vk.size(); k++) {
		for (int q = 0; q < 4; q++) {
			_load((String)((Dictionary)COVER[vk[k]])[parts[q]]);
		}
	}
}

void TravInteract::_load(const String &clip) {
	Ref<Resource> c = ResourceLoader::get_singleton()->load(vformat(CLIPS, clip));
	PackedVector3Array hips = c->get("hips");
	_fps = F(c->get("fps"));
	Vector3 net = hips[hips.size() - 1] - hips[0];
	net.y = 0.0f;
	Vector3 dir = D(net.length()) > 0.02 ? net.normalized() : ZERO;
	PackedFloat32Array t;
	for (int f = 0; f < hips.size(); f++) {
		Vector3 rel = hips[f] - hips[0];
		t.append(V(D(rel.x), 0.0, D(rel.z)).dot(dir));
	}
	_along[clip] = t;
	_dir[clip] = COVER_AIM.has(clip) ? dir.rotated(UP, (real_t)deg_to_rad(F(COVER_AIM[clip]))) : dir;
	_yaw[clip] = c->get("yaw");
	_len[clip] = (double)(hips.size() - 1) / _fps;
}

double TravInteract::_at(const PackedFloat32Array &table, double t) {
	double x = clampf(t * _fps, 0.0, (double)table.size() - 1.001);
	int i = (int)x;
	return lerpf(D(table[i]), D(table[i + 1]), x - i);
}

void TravInteract::_physics_process(double _dt) {
	if (body == nullptr || !enabled || (bool)body->call("in_move")) {
		return;
	}
	if ((int64_t)body->get("state") != 0 || (bool)body->get("crouched")) {
		return;
	}
	if (_to_seat != nullptr) {
		_walk_to_seat(_dt);
		return;
	}
	if (_to_car != nullptr) {
		_walk_to_car(_dt);
		return;
	}
	if (!_to_cover.is_empty()) {
		_walk_to_cover(_dt);
		return;
	}
	if ((bool)body->get("act_now") && (_try_seat() || _try_car() || _try_cover())) {
		return;
	}
	Vector3 wish = body->get("stick_wish");
	if (D(wish.length()) > 0.05) {
		_try_door(wish.normalized());
	}
}

double TravInteract::_keyed(const Array &keys, double t) {
	double out = F(((Array)keys[0])[1]);
	for (int i = 0; i < keys.size() - 1; i++) {
		Array a = keys[i];
		Array b = keys[i + 1];
		if (t >= F(a[0])) {
			out = lerpf(F(a[1]), F(b[1]), clampf((t - F(a[0])) / (F(b[0]) - F(a[0])), 0.0, 1.0));
		}
	}
	return out;
}

// ---------------------------------------------------------------------------------------------------------- doors

bool TravInteract::_try_door(const Vector3 &dir) {
	TypedArray<Node> doors = get_tree()->get_nodes_in_group("tl_door");
	for (int k = 0; k < doors.size(); k++) {
		Node3D *door = Object::cast_to<Node3D>((Object *)doors[k]);
		if (F(door->get("open_deg")) > 2.0) {
			continue;
		}
		Vector3 hinge = door->get_global_position();
		Vector3 out = door->get_global_transform().basis.get_column(2);
		out = V(D(out.x), 0.0, D(out.z)).normalized();
		Vector3 rel = body->get_global_position() - hinge;
		if (absf(D(rel.y)) > 0.1) {
			continue;
		}
		bool front = D(rel.dot(out)) > 0.0;
		Dictionary p = DOOR[front ? "pull" : "push"];
		Vector3 into = front ? -out : out;
		if (D(dir.dot(into)) < 0.7) {
			continue;
		}
		Vector3 right = into.cross(UP).normalized();
		Vector3 start = hinge - mul(right, F(p["hinge"])) - mul(into, F(p["plane"]) + (F(door->get("THICK")) * 0.5));
		start.y = body->get_global_position().y;
		Vector3 off = body->get_global_position() - start;
		if (D(off.dot(into)) > 0.10 || D(off.dot(into)) < -DOOR_NEAR || absf(D(off.dot(right))) > DOOR_ASIDE) {
			continue;
		}
		PackedFloat32Array table = _along[(String)p["clip"]];
		double end_t = F(p["end"]);
		_plan = Dictionary();
		_plan["key"] = front ? "door_pull" : "door_push";
		_plan["p"] = p;
		_plan["door"] = door;
		_plan["front"] = front;
		_plan["from"] = body->get_global_position();
		_plan["start"] = start;
		_plan["into"] = into;
		_plan["yaw0"] = _rot_y();
		_plan["yaw"] = std::atan2(-D(into.x), -D(into.z));
		_plan["table"] = table;
		_plan["exit_speed"] = (_at(table, end_t) - _at(table, end_t - 0.2)) / 0.2 * F(p["rate"]);
		plays += 1;
		last = (String)_plan["key"];
		body->call("begin_move", Callable(this, "_door"), (String)p["input"]);
		return true;
	}
	return false;
}

Dictionary TravInteract::_door(double t) {
	Dictionary pl = _plan;
	Dictionary p = pl["p"];
	double ct = t * F(p["rate"]);
	Vector3 into = pl["into"];
	Vector3 pos = (Vector3)pl["start"] + mul(into, _at((PackedFloat32Array)pl["table"], ct));
	if (p.has("aside")) {
		pos += mul(into.cross(UP).normalized(), _keyed(p["aside"], ct));
	}
	pos = lerp3((Vector3)pl["from"], pos, smoothstep(0.0, ALIGN_TIME, t));
	Node3D *door = Object::cast_to<Node3D>((Object *)pl["door"]);
	door->set("open_deg", _keyed(p["swing"], ct));
	door->set("held", true);
	double hold = clampf(minf((ct - F(p["hand_on"])) / HAND_FADE + 1.0, (F(p["hand_off"]) - ct) / HAND_FADE + 1.0), 0.0, 1.0);
	hold = hold * hold * (3.0 - 2.0 * hold);
	bool front = pl["front"];
	Vector3 at = (Vector3)door->call("bar_at", _keyed(p["hand_at"], ct), front) + mul((Vector3)door->call("face", front), PALM - 0.03);
	bool done = ct >= F(p["end"]);
	Dictionary out;
	out["done"] = done;
	out["pos"] = pos;
	out["clip_t"] = ct;
	out["air"] = false;
	out["landed"] = true;
	out["yaw"] = lerp_angle(F(pl["yaw0"]), F(pl["yaw"]), smoothstep(0.0, ALIGN_TIME, t));
	Array one;
	one.append((int64_t)p["hand"]);
	one.append(at);
	one.append(hold);
	Array hand;
	hand.append(one);
	out["hand"] = hand;
	if (done) {
		out["exit"] = mul(into, F(pl["exit_speed"]));
	}
	return out;
}

// -------------------------------------------------------------------------------------------------------- sitting

Vector3 TravInteract::_seat_side(Node3D *seat) {
	Vector3 f = (bool)seat->get_meta("desk") ? (Vector3)seat->get_meta("side") : seat->get_global_transform().basis.get_column(2);
	return V(D(f.x), 0.0, D(f.z)).normalized();
}

Vector3 TravInteract::_seat_stand(Node3D *seat) {
	double back = _at((PackedFloat32Array)_along[(String)sub(SIT, "down")["clip"]], 99.0);
	return seat->get_global_position() + mul(_seat_side(seat), back);
}

bool TravInteract::_try_seat() {
	Node3D *best = nullptr;
	double best_d = SIT_REACH;
	TypedArray<Node> seats = get_tree()->get_nodes_in_group("tl_seat");
	for (int k = 0; k < seats.size(); k++) {
		Node3D *seat = Object::cast_to<Node3D>((Object *)seats[k]);
		double d = D(body->get_global_position().distance_to(_seat_stand(seat)));
		if (d < best_d && absf(D(seat->get_global_position().y) - D(body->get_global_position().y)) < 0.1) {
			best = seat;
			best_d = d;
		}
	}
	if (best == nullptr) {
		return false;
	}
	_to_seat = best;
	_walked = 0.0;
	return true;
}

void TravInteract::_walk_to_seat(double dt) {
	_walked += dt;
	Vector3 stand = _seat_stand(_to_seat);
	Vector3 off = stand - body->get_global_position();
	off.y = 0.0f;
	if (((bool)body->get("stick_held") && _walked > 0.2) || _walked > SIT_WALK_MOST) {
		body->set("auto_on", false);
		_to_seat = nullptr;
		return;
	}
	if (D(off.length()) > SIT_AT) {
		body->set("auto_on", true);
		body->set("auto_to", stand);
		return;
	}
	body->set("auto_on", false);
	Node3D *seat = _to_seat;
	_to_seat = nullptr;
	Vector3 side = _seat_side(seat);
	Vector3 face = seat->get_global_transform().basis.get_column(2);
	face = V(D(face.x), 0.0, D(face.z)).normalized();
	double yaw_side = std::atan2(-D(side.x), -D(side.z));
	double turn = absf(wrapf(yaw_side - _rot_y(), -PI, PI));
	_plan = Dictionary();
	_plan["key"] = "sit";
	_plan["seat"] = seat;
	_plan["at"] = seat->get_global_position();
	_plan["stand"] = stand;
	_plan["side"] = side;
	_plan["desk"] = (bool)seat->get_meta("desk");
	_plan["from"] = body->get_global_position();
	_plan["yaw0"] = _rot_y();
	_plan["yaw_side"] = yaw_side;
	_plan["yaw_face"] = std::atan2(-D(face.x), -D(face.z));
	_plan["turn_time"] = maxf(TURN_TIME * turn / PI, ALIGN_TIME);
	_plan["phase"] = "turn";
	_plan["t0"] = 0.0;
	_plan["held"] = 0.0;
	_plan["last_t"] = 0.0;
	plays += 1;
	last = "sit";
	seated = true;
	body->call("begin_move", Callable(this, "_sit"), (String)sub(SIT, "down")["input"]);
}

Dictionary TravInteract::_sit(double t) {
	Dictionary pl = _plan;
	double dt = t - F(pl["last_t"]);
	pl["last_t"] = t;
	String ph = pl["phase"];
	double tau = t - F(pl["t0"]);
	Vector3 at = pl["at"];
	Vector3 side = pl["side"];
	bool desk = pl["desk"];
	Dictionary out;
	out["done"] = false;
	out["pos"] = at;
	out["yaw"] = desk ? F(pl["yaw_face"]) : F(pl["yaw_side"]);
	out["clip"] = "sit_idle";
	out["clip_t"] = 0.0;
	out["air"] = false;
	out["landed"] = true;
	String next = "";
	pl["held"] = (bool)body->get("stick_held") ? F(pl["held"]) + dt : 0.0;
	bool up_asked = (bool)body->get("act_now") || F(pl["held"]) >= UP_HOLD;
	if (ph == "turn") {
		double u = smoothstep(0.0, F(pl["turn_time"]), tau);
		out["pos"] = lerp3((Vector3)pl["from"], (Vector3)pl["stand"], u);
		out["yaw"] = lerp_angle(F(pl["yaw0"]), F(pl["yaw_side"]), u);
		out["clip"] = "sit_down";
		if (tau >= F(pl["turn_time"])) {
			next = "down";
		}
	} else if (ph == "down") {
		String clip = sub(SIT, "down")["clip"];
		out["pos"] = (Vector3)pl["stand"] - mul(side, _at((PackedFloat32Array)_along[clip], tau));
		out["yaw"] = F(pl["yaw_side"]);
		out["clip"] = "sit_down";
		out["clip_t"] = minf(tau, F(_len[clip]));
		if (tau >= F(_len[clip])) {
			next = desk ? "swivel_in" : "idle";
		}
	} else if (ph == "idle") {
		out["clip_t"] = fposmod(tau, F(_len[(String)sub(SIT, "idle")["clip"]]));
		if (up_asked && tau > 0.3) {
			next = desk ? "swivel_out" : "up";
		} else if (desk && (int64_t)body->get("phone") == 1) {
			body->set("phone", 0);
			next = "hands_on";
		}
	} else if (ph == "swivel_in" || ph == "swivel_out") {
		double u2 = smoothstep(0.0, SWIVEL_TIME, tau);
		out["yaw"] = lerp_angle(F(pl["yaw_side"]), F(pl["yaw_face"]), ph == "swivel_in" ? u2 : 1.0 - u2);
		if (tau >= SWIVEL_TIME) {
			next = ph == "swivel_in" ? "hands_on" : "up";
		}
	} else if (ph == "hands_on" || ph == "hands_off") {
		double hl = F(_len[(String)sub(SIT, "hands")["clip"]]);
		out["clip"] = "type_to_sit";
		out["clip_t"] = clampf(ph == "hands_on" ? hl - tau : tau, 0.0, hl);
		if (tau >= hl) {
			next = ph == "hands_on" ? "type" : ((bool)pl.get("leaving", false) ? "swivel_out" : "idle");
		}
	} else if (ph == "type") {
		out["clip"] = "sit_type";
		out["clip_t"] = fposmod(tau, F(_len[(String)sub(SIT, "type")["clip"]]));
		if ((int64_t)body->get("phone") != 0) {
			body->set("phone", 0);
			pl["leaving"] = false;
			next = "hands_off";
		} else if (up_asked && tau > 0.3) {
			pl["leaving"] = true;
			next = "hands_off";
		}
	} else if (ph == "up") {
		String clip2 = sub(SIT, "up")["clip"];
		out["pos"] = at + mul(side, _at((PackedFloat32Array)_along[clip2], tau));
		out["yaw"] = F(pl["yaw_side"]);
		out["clip"] = "sit_up";
		out["clip_t"] = minf(tau, F(_len[clip2]));
		if (tau >= F(_len[clip2])) {
			out["done"] = true;
			out["exit"] = ZERO;
			seated = false;
		}
	}
	if (next != "") {
		pl["phase"] = next;
		pl["t0"] = t;
	}
	sit_phase = !(bool)out["done"] ? (String)pl["phase"] : String("");
	return out;
}

// ----------------------------------------------------------------------------------------------------------- cars

Array TravInteract::_travel(const String &clip, double t) {
	PackedFloat32Array yaw = _yaw[clip];
	double x = clampf(t * _fps, 0.0, (double)yaw.size() - 1.001);
	int i = (int)x;
	Array out;
	out.append(_at((PackedFloat32Array)_along[clip], t));
	out.append(lerpf(D(yaw[i]), D(yaw[i + 1]), x - i));
	return out;
}

Vector3 TravInteract::_line(const String &clip, const Vector3 &fwd) {
	Vector3 d = _dir[clip];
	Vector3 right = fwd.cross(UP).normalized();
	return (fwd * d.z - right * d.x).normalized();
}

Array TravInteract::_car_start(Node3D *car) {
	String clip = sub(CAR, "in")["clip"];
	Vector3 ahead = -car->get_global_transform().basis.get_column(2);
	ahead = V(D(ahead.x), 0.0, D(ahead.z)).normalized();
	Array whole = _travel(clip, 99.0);
	Vector3 fwd = ahead.rotated(UP, (real_t)(-F(whole[1])));
	Array out;
	out.append(car->get_global_position() - mul(_line(clip, fwd), F(whole[0])));
	out.append(fwd);
	return out;
}

bool TravInteract::_try_car() {
	TypedArray<Node> cars = get_tree()->get_nodes_in_group("tl_car");
	for (int k = 0; k < cars.size(); k++) {
		Node3D *car = Object::cast_to<Node3D>((Object *)cars[k]);
		Vector3 start = _car_start(car)[0];
		if (D(body->get_global_position().distance_to(start)) < CAR_REACH && absf(D(start.y) - D(body->get_global_position().y)) < 0.1) {
			_to_car = car;
			_walked = 0.0;
			return true;
		}
	}
	return false;
}

void TravInteract::_walk_to_car(double dt) {
	_walked += dt;
	Array st = _car_start(_to_car);
	Vector3 start = st[0];
	Vector3 off = start - body->get_global_position();
	off.y = 0.0f;
	if (((bool)body->get("stick_held") && _walked > 0.2) || _walked > SIT_WALK_MOST) {
		body->set("auto_on", false);
		_to_car = nullptr;
		return;
	}
	if (D(off.length()) > SIT_AT) {
		body->set("auto_on", true);
		body->set("auto_to", start);
		return;
	}
	body->set("auto_on", false);
	Node3D *car = _to_car;
	_to_car = nullptr;
	Vector3 fwd = st[1];
	double yaw_in = std::atan2(-D(fwd.x), -D(fwd.z));
	Vector3 ahead = -car->get_global_transform().basis.get_column(2);
	ahead = V(D(ahead.x), 0.0, D(ahead.z)).normalized();
	double turn = absf(wrapf(yaw_in - _rot_y(), -PI, PI));
	_plan = Dictionary();
	_plan["key"] = "car";
	_plan["car"] = car;
	_plan["start"] = start;
	_plan["fwd"] = fwd;
	_plan["ahead"] = ahead;
	_plan["from"] = body->get_global_position();
	_plan["yaw0"] = _rot_y();
	_plan["yaw_in"] = yaw_in;
	_plan["yaw_seat"] = std::atan2(-D(ahead.x), -D(ahead.z));
	_plan["turn_time"] = maxf(TURN_TIME * turn / PI, ALIGN_TIME);
	_plan["phase"] = "turn";
	_plan["t0"] = 0.0;
	plays += 1;
	last = "car";
	body->call("begin_move", Callable(this, "_car"), (String)sub(CAR, "in")["input"]);
}

Dictionary TravInteract::_car(double t) {
	Dictionary pl = _plan;
	String ph = pl["phase"];
	double tau = t - F(pl["t0"]);
	Node3D *car = Object::cast_to<Node3D>((Object *)pl["car"]);
	Vector3 seat = car->get_global_position();
	String c_in = sub(CAR, "in")["clip"];
	String c_out = sub(CAR, "out")["clip"];
	Dictionary out;
	out["done"] = false;
	out["pos"] = seat;
	out["yaw"] = F(pl["yaw_seat"]);
	out["clip"] = "car_in";
	out["clip_t"] = F(_len[c_in]);
	out["air"] = false;
	out["free"] = true;
	String next = "";
	if (ph == "turn") {
		double u = smoothstep(0.0, F(pl["turn_time"]), tau);
		out["pos"] = lerp3((Vector3)pl["from"], (Vector3)pl["start"], u);
		out["yaw"] = lerp_angle(F(pl["yaw0"]), F(pl["yaw_in"]), u);
		out["clip_t"] = 0.0;
		out["free"] = false;
		out["landed"] = true;
		if (tau >= F(pl["turn_time"])) {
			next = "in";
		}
	} else if (ph == "in") {
		Array tr = _travel(c_in, tau);
		out["pos"] = (Vector3)pl["start"] + mul(_line(c_in, (Vector3)pl["fwd"]), F(tr[0]));
		out["yaw"] = F(pl["yaw_in"]) + F(tr[1]);
		out["clip_t"] = minf(tau, F(_len[c_in]));
		car->set("door_deg", _keyed(sub(CAR, "in")["door"], tau));
		car->set("held", true);
		if (tau >= F(_len[c_in])) {
			next = "seated";
			in_car = true;
		}
	} else if (ph == "seated") {
		if ((bool)body->get("act_now") && tau > 0.3) {
			next = "out";
		}
	} else if (ph == "out") {
		Array tr2 = _travel(c_out, tau);
		out["pos"] = seat + mul(_line(c_out, (Vector3)pl["ahead"]), F(tr2[0]));
		out["yaw"] = F(pl["yaw_seat"]) + F(tr2[1]);
		out["clip"] = "car_out";
		out["clip_t"] = minf(tau, F(_len[c_out]));
		car->set("door_deg", _keyed(sub(CAR, "out")["door"], tau));
		car->set("held", true);
		in_car = false;
		if (tau >= F(_len[c_out])) {
			out["done"] = true;
			out["exit"] = ZERO;
		}
	}
	if (next != "") {
		pl["phase"] = next;
		pl["t0"] = t;
	}
	return out;
}

// ---------------------------------------------------------------------------------------------------------- cover

Dictionary TravInteract::_ray(const Vector3 &from, const Vector3 &to) {
	TypedArray<RID> ex;
	ex.append(body->get_rid());
	return TRAV_RAY(body, PhysicsRayQueryParameters3D::create(from, to, trav::probe_mask(body), ex));
}

double TravInteract::_cover_wall(const Vector3 &at, const Vector3 &n) {
	Dictionary hit = _ray(at + V(0.0, 0.5, 0.0), at + V(0.0, 0.5, 0.0) - mul(n, COVER_OFF + 0.25));
	if (hit.is_empty() || D(((Vector3)hit["normal"]).dot(n)) < 0.9) {
		return 0.0;
	}
	Vector3 inside = (Vector3)hit["position"] - mul(n, 0.05);
	Dictionary top = _ray(V(D(inside.x), D(at.y) + 3.5, D(inside.z)), V(D(inside.x), D(at.y) + 0.3, D(inside.z)));
	return !top.is_empty() ? D(((Vector3)top["position"]).y) - D(at.y) : 3.5;
}

bool TravInteract::_cover_on(const Vector3 &at, const Vector3 &way, const Vector3 &n) {
	return _cover_wall(at + mul(way, COVER_END + 0.03), n) >= COVER_LOW - 0.02 && _ray(at + V(0.0, 0.6, 0.0), at + V(0.0, 0.6, 0.0) + mul(way, 0.5)).is_empty();
}

bool TravInteract::_try_cover() {
	Vector3 face = -body->get_global_transform().basis.get_column(2);
	face = V(D(face.x), 0.0, D(face.z)).normalized();
	Vector3 feet = body->get_global_position();
	Dictionary hit = _ray(feet + V(0.0, 0.5, 0.0), feet + V(0.0, 0.5, 0.0) + mul(face, COVER_REACH));
	if (hit.is_empty()) {
		return false;
	}
	Vector3 n = hit["normal"];
	n = V(D(n.x), 0.0, D(n.z));
	if (D(n.length()) < 0.9 || D(n.normalized().dot(face)) > -0.7) {
		return false;
	}
	n = n.normalized();
	Vector3 at = V(D(((Vector3)hit["position"]).x), D(feet.y), D(((Vector3)hit["position"]).z)) + mul(n, COVER_OFF);
	double high = _cover_wall(at, n);
	if (high < COVER_LOW - 0.02) {
		return false;
	}
	String kind = high >= COVER_HIGH ? "high" : "low";
	Dictionary c = COVER[kind];
	String clip = c["in"];
	double yaw_n = std::atan2(-D(n.x), -D(n.z));
	Array whole = _travel(clip, 99.0);
	Vector3 start;
	double yaw_start = 0.0;
	if ((bool)c["in_back"]) {
		start = at + mul(_line(clip, n), F(whole[0]));
		yaw_start = yaw_n + F(whole[1]);
	} else {
		yaw_start = yaw_n - F(whole[1]);
		Vector3 fwd0 = V(-std::sin(yaw_start), 0.0, -std::cos(yaw_start));
		start = at - mul(_line(clip, fwd0), F(whole[0]));
	}
	if (_ray(start + V(0.0, 1.0, 0.0), start + V(0.0, -0.3, 0.0)).is_empty()) {
		return false;
	}
	_to_cover = Dictionary();
	_to_cover["key"] = "cover";
	_to_cover["kind"] = kind;
	_to_cover["c"] = c;
	_to_cover["at"] = at;
	_to_cover["n"] = n;
	_to_cover["high"] = high;
	_to_cover["yaw_n"] = yaw_n;
	_to_cover["start"] = start;
	_to_cover["yaw_start"] = yaw_start;
	_walked = 0.0;
	return true;
}

void TravInteract::_walk_to_cover(double dt) {
	_walked += dt;
	Vector3 start = _to_cover["start"];
	Vector3 off = start - body->get_global_position();
	off.y = 0.0f;
	if (((bool)body->get("stick_held") && _walked > 0.2) || _walked > SIT_WALK_MOST) {
		body->set("auto_on", false);
		_to_cover = Dictionary();
		return;
	}
	if (D(off.length()) > SIT_AT) {
		body->set("auto_on", true);
		body->set("auto_to", start);
		return;
	}
	body->set("auto_on", false);
	_plan = _to_cover;
	_to_cover = Dictionary();
	double turn = absf(wrapf(F(_plan["yaw_start"]) - _rot_y(), -PI, PI));
	merge_new(_plan, "from", body->get_global_position());
	merge_new(_plan, "yaw0", _rot_y());
	merge_new(_plan, "turn_time", maxf(TURN_TIME * turn / PI, ALIGN_TIME));
	merge_new(_plan, "phase", "turn");
	merge_new(_plan, "t0", 0.0);
	merge_new(_plan, "last_t", 0.0);
	merge_new(_plan, "pos", _plan["at"]);
	merge_new(_plan, "side_t", 0.0);
	merge_new(_plan, "pushed", 0.0);
	merge_new(_plan, "away", 0.0);
	merge_new(_plan, "peek_side", 1.0);
	plays += 1;
	last = String("cover_") + (String)_plan["kind"];
	body->call("begin_move", Callable(this, "_cover"), (String)((Dictionary)_plan["c"])["in_key"]);
}

double TravInteract::_drop_for(double head, double high) {
	return clampf(head - (high - COVER_HEAD_ROOM), 0.0, COVER_DROP_MOST);
}

Dictionary TravInteract::_cover(double t) {
	Dictionary pl = _plan;
	Dictionary c = pl["c"];
	double dt = t - F(pl["last_t"]);
	pl["last_t"] = t;
	String ph = pl["phase"];
	double tau = t - F(pl["t0"]);
	Vector3 n = pl["n"];
	Vector3 left = UP.cross(n).normalized();
	Vector3 at = pl["pos"];
	double yaw_n = F(pl["yaw_n"]);
	String kind = pl["kind"];
	Dictionary out;
	out["done"] = false;
	out["pos"] = at;
	out["yaw"] = yaw_n;
	out["clip"] = (String)c["idle"];
	out["clip_t"] = 0.0;
	out["air"] = false;
	out["landed"] = true;
	String next = "";
	double drop = 0.0;
	Vector3 stick = body->get("stick_dir");
	double along = D(stick.dot(left));
	double outward = D(stick.dot(n));
	pl["away"] = outward > 0.6 ? F(pl["away"]) + dt : 0.0;
	bool out_asked = (bool)body->get("act_now") || F(pl["away"]) >= UP_HOLD;
	if (ph == "turn") {
		double u = smoothstep(0.0, F(pl["turn_time"]), tau);
		out["pos"] = lerp3((Vector3)pl["from"], (Vector3)pl["start"], u);
		out["yaw"] = lerp_angle(F(pl["yaw0"]), F(pl["yaw_start"]), u);
		out["clip"] = (String)c["in_key"];
		out["clip_t"] = (bool)c["in_back"] ? F(_len[(String)c["in"]]) : 0.0;
		if (tau >= F(pl["turn_time"])) {
			next = "in";
		}
	} else if (ph == "in") {
		String clip = c["in"];
		double l = F(_len[clip]);
		double ct = clampf((bool)c["in_back"] ? l - tau : tau, 0.0, l);
		Array tr = _travel(clip, ct);
		if ((bool)c["in_back"]) {
			out["pos"] = (Vector3)pl["at"] + mul(_line(clip, n), F(tr[0]));
			out["yaw"] = yaw_n + F(tr[1]);
		} else {
			Vector3 fwd0 = V(-std::sin(F(pl["yaw_start"])), 0.0, -std::cos(F(pl["yaw_start"])));
			out["pos"] = (Vector3)pl["start"] + mul(_line(clip, fwd0), F(tr[0]));
			out["yaw"] = F(pl["yaw_start"]) + F(tr[1]);
		}
		out["clip"] = (String)c["in_key"];
		out["clip_t"] = ct;
		drop = _drop_for(F(c["head"]), F(pl["high"])) * smoothstep(0.0, l, tau);
		if (tau >= l) {
			next = "idle";
			in_cover = kind;
		}
	} else if (ph == "idle") {
		out["clip_t"] = fposmod(tau, F(_len[(String)c["idle_clip"]]));
		drop = _drop_for(F(c["head"]), F(pl["high"]));
		if (out_asked && tau > 0.3) {
			next = "out";
		} else if (absf(along) > 0.5) {
			double way = signf(along);
			if (_cover_on(at, mul(left, way), n)) {
				pl["side"] = way;
				pl["pushed"] = 0.0;
				next = "side";
			} else {
				pl["pushed"] = F(pl["pushed"]) + dt;
				if (F(pl["pushed"]) >= PEEK_AFTER && _cover_wall(at + mul(left, way * 0.6), n) < COVER_LOW - 0.02) {
					pl["peek_side"] = way;
					next = "peek";
				}
			}
		} else {
			pl["pushed"] = 0.0;
		}
	} else if (ph == "side") {
		double way2 = F(pl["side"]);
		pl["side_t"] = fposmod(F(pl["side_t"]) + dt, COVER_SIDE_LEN);
		out["clip"] = way2 > 0.0 ? "cover_left" : "cover_right";
		out["clip_t"] = F(pl["side_t"]);
		drop = kind == "low" ? _drop_for(F(c["head_side"]), F(pl["high"])) : 0.0;
		Vector3 step = mul(left, way2 * COVER_PACE * dt);
		bool on = signf(along) == way2 && absf(along) > 0.5;
		if (on && _cover_on(at, mul(left, way2), n)) {
			at += step;
			pl["pos"] = at;
			out["pos"] = at;
			pl["high"] = _cover_wall(at, n);
		} else {
			next = "idle";
		}
	} else if (ph == "peek") {
		String clip2 = c["peek"];
		double l2 = F(_len[clip2]);
		bool mirrored = signf(F(pl["peek_side"])) != F(c["peek_to"]);
		out["clip"] = (String)c["peek_key"] + (mirrored ? String("_m") : String(""));
		drop = _drop_for(F(c["head"]), F(pl["high"]));
		if (kind == "low") {
			out["clip_t"] = minf(tau, l2);
			if (tau >= l2) {
				next = "idle";
			}
		} else {
			double ct2 = tau < l2 + PEEK_HOLD ? clampf(tau, 0.0, l2) : clampf(2.0 * l2 + PEEK_HOLD - tau, 0.0, l2);
			Array tr2 = _travel(clip2, ct2);
			double m = mirrored ? -1.0 : 1.0;
			Vector3 d2 = _dir[clip2];
			out["pos"] = F(tr2[0]) > 0.0 ? at + mul((n * d2.z - mul(left * (-d2.x), m)).normalized(), F(tr2[0])) : at;
			out["yaw"] = yaw_n + F(tr2[1]) * m;
			out["clip_t"] = ct2;
			if (tau >= 2.0 * l2 + PEEK_HOLD) {
				next = "idle";
			}
		}
	} else if (ph == "out") {
		String clip3 = c["out"];
		double l3 = F(_len[clip3]);
		Array tr3 = _travel(clip3, minf(tau, l3));
		out["pos"] = at + mul(_line(clip3, n), F(tr3[0]));
		out["yaw"] = yaw_n + F(tr3[1]);
		out["clip"] = (String)c["out_key"];
		out["clip_t"] = minf(tau, l3);
		drop = _drop_for(F(c["head"]), F(pl["high"])) * (1.0 - smoothstep(0.0, l3 * 0.5, tau));
		in_cover = "";
		if (tau >= l3) {
			out["done"] = true;
			out["exit"] = ZERO;
		}
	}
	body->set("cover_drop", drop);
	if (next != "") {
		pl["phase"] = next;
		pl["t0"] = t;
	}
	cover_phase = !(bool)out["done"] ? (String)pl["phase"] : String("");
	return out;
}

// ------------------------------------------------------------------------------------------------ for the other scripts

void TravInteract::_bind_methods() {
	ClassDB::bind_method(D_METHOD("_door", "t"), &TravInteract::_door);
	ClassDB::bind_method(D_METHOD("_sit", "t"), &TravInteract::_sit);
	ClassDB::bind_method(D_METHOD("_car", "t"), &TravInteract::_car);
	ClassDB::bind_method(D_METHOD("_cover", "t"), &TravInteract::_cover);
	ClassDB::bind_method(D_METHOD("_seat_stand", "seat"), &TravInteract::_seat_stand);
	ClassDB::bind_method(D_METHOD("_car_start", "car"), &TravInteract::_car_start);
}

bool TravInteract::_get(const StringName &p_name, Variant &r_ret) const {
	String n = p_name;
	if (n == "body") {
		r_ret = body;
		return true;
	}
	if (n == "enabled") {
		r_ret = enabled;
		return true;
	}
	if (n == "plays") {
		r_ret = plays;
		return true;
	}
	if (n == "last") {
		r_ret = last;
		return true;
	}
	if (n == "_plan") {
		r_ret = _plan;
		return true;
	}
	if (n == "in_car") {
		r_ret = in_car;
		return true;
	}
	if (n == "in_cover") {
		r_ret = in_cover;
		return true;
	}
	if (n == "cover_phase") {
		r_ret = cover_phase;
		return true;
	}
	if (n == "seated") {
		r_ret = seated;
		return true;
	}
	if (n == "sit_phase") {
		r_ret = sit_phase;
		return true;
	}
	if (n == "_to_seat") {
		r_ret = _to_seat;
		return true;
	}
	if (n == "_to_car") {
		r_ret = _to_car;
		return true;
	}
	if (n == "_to_cover") {
		r_ret = _to_cover;
		return true;
	}
	if (n == "_walked") {
		r_ret = _walked;
		return true;
	}
#include "trav_interact_get.inc"
	return false;
}

bool TravInteract::_set(const StringName &p_name, const Variant &p_value) {
	String n = p_name;
	if (n == "body") {
		body = Object::cast_to<CharacterBody3D>((Object *)p_value);
		return true;
	}
	if (n == "enabled") {
		enabled = p_value;
		return true;
	}
	if (n == "plays") {
		plays = (int)(int64_t)p_value;
		return true;
	}
	return false;
}
