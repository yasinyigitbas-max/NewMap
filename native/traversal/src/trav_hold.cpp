// The things he holds, and his fists. See trav_hold.h.
#include "trav_hold.h"
#include "trav_probe.h"
#include "trav_body.h"

#include "trav_math.h"

#include <godot_cpp/classes/animation.hpp>
#include <godot_cpp/classes/animation_library.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/omni_light3d.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/sphere_mesh.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;
using namespace trav;

static const Vector3 UP(0, 1, 0);
static const Vector3 ZERO(0, 0, 0);

// What can be in his hands in the lab, in the order of the number keys.
static const TravHold::Item ITEMS[] = {
	{ "briefcase_leather", TravHold::HANG, "Walking_With_Shopping_Bag", 0.38, nullptr },
	{ "bag_plastic_thankyou", TravHold::HANG, "Walking_With_Shopping_Bag", 0.38, nullptr },
	{ "box_moving", TravHold::BOX, "Jogging_With_Box", 0.23, nullptr },
	{ "pistol_service", TravHold::PISTOL, "Pistol_Idle", 2.0, "Gun_Reload_While_Walking" },
	{ "rifle", TravHold::LONG, "Rifle_Standing_Idle", 1.0, "Reloading_Rifle_While_Standing" },
	{ "shotgun", TravHold::LONG, "Rifle_Standing_Idle", 1.0, "Reloading_Rifle_While_Standing" },
	{ "smg", TravHold::LONG, "Rifle_Standing_Idle", 1.0, "Reloading_Rifle_While_Standing" },
	{ "shotgun_sawn", TravHold::LONG, "Rifle_Standing_Idle", 1.0, "Reloading_Rifle_While_Standing" },
	{ nullptr, TravHold::FIST, "Fight_Idle", -1.0, nullptr },
};
static const int ITEM_COUNT = sizeof(ITEMS) / sizeof(ITEMS[0]);
// Putting down and picking up: the part of each take that is played, and the moment in it the thing leaves, or
// comes into, his hands (measured on his body: his hands are lowest then). [from, to, at] in seconds of the take.
static const double PUT_BOX[3] = { 1.60, 4.20, 2.75 };
static const double PICK_BOX[3] = { 0.60, 3.70, 1.50 };
static const double PUT_BAG[3] = { 2.00, 4.40, 3.07 };
static const double PICK_BAG[3] = { 2.00, 4.60, 3.10 };
static const char *PUNCHES[3] = { "fight_cross", "fight_hook_l", "fight_hook_r" };
static const char *HITS[6] = { "fight_hit_ll", "fight_hit_lr", "fight_hit_m", "fight_hit_body", "fight_hit_bl", "fight_hit_br" };

static inline double smooth(double x) {
	x = clampf(x, 0.0, 1.0);
	return x * x * (3.0 - 2.0 * x);
}

int TravHold::count() const {
	return ITEM_COUNT;
}

String TravHold::label() const {
	if (item <= 0) {
		return "nothing";
	}
	const Item &it = ITEMS[item - 1];
	String s = it.prop ? String(it.prop) : String("fists");
	if (aiming) {
		s += " (aimed)";
	}
	if (_reload_t >= 0.0) {
		s += " (reloading)";
	}
	return s;
}

double TravHold::_len(const String &take) const {
	Ref<AnimationLibrary> lib = _chr->get("_lib");
	if (lib.is_null() || !lib->has_animation(take)) {
		return 1.0;
	}
	return (double)lib->get_animation(take)->get("length");
}

void TravHold::_ready() {
	if (body == nullptr) {
		return;
	}
	_chr = body->get_node_or_null("Character");
	if (_chr == nullptr) {
		return;
	}
	_skel = Object::cast_to<Skeleton3D>((Object *)_chr->get("skel"));
	if (_skel == nullptr) {
		return;
	}
	const char *side[2] = { "Left", "Right" };
	const char *part[4] = { "Hand", "HandMiddle1", "HandIndex1", "HandPinky1" };
	for (int s = 0; s < 2; s++) {
		for (int k = 0; k < 4; k++) {
			_bone[s][k] = _skel->find_bone(vformat("mixamorig_%s%s", side[s], part[k]));
		}
	}
	_head = _skel->find_bone("mixamorig_Head");
	_shoulder = _skel->find_bone("mixamorig_RightArm");
	_skel->connect("skeleton_updated", Callable(this, "_place"));
}

// One hand's frame, from its joints, in the skeleton's space.
void TravHold::_hand(int side, Vector3 &r_palm, Vector3 &r_along, Vector3 &r_across) const {
	Vector3 w = _skel->get_bone_global_pose(_bone[side][0]).origin;
	Vector3 k = _skel->get_bone_global_pose(_bone[side][1]).origin;
	Vector3 i = _skel->get_bone_global_pose(_bone[side][2]).origin;
	Vector3 p = _skel->get_bone_global_pose(_bone[side][3]).origin;
	r_along = (k - w).normalized();
	Vector3 across = (i - p).normalized();
	r_across = (across - r_along * across.dot(r_along)).normalized();
	Vector3 out = r_across.cross(r_along) * (side == 1 ? 1.0f : -1.0f);      // out of the palm (27 Nov, Yasin: they "look like they are attached to the back of his hands": it was the other way)
	r_palm = w.lerp(k, (real_t)PALM_ALONG) + out * (real_t)PALM_OUT;
}

void TravHold::_take_up(int which) {
	if (_prop != nullptr) {
		_prop->queue_free();
		_prop = nullptr;
		_flash = nullptr;
	}
	_shown = which;
	_t_set = false;
	if (which <= 0 || _skel == nullptr || ITEMS[which - 1].prop == nullptr) {
		return;
	}
	Ref<PackedScene> ps = ResourceLoader::get_singleton()->load(vformat("res://traversal/props/%s.scn", ITEMS[which - 1].prop));
	if (ps.is_null()) {
		return;
	}
	_prop = Object::cast_to<Node3D>(ps->instantiate());
	_prop->set_visible(false);
	_skel->add_child(_prop);
	Node3D *mz = Object::cast_to<Node3D>(_prop->get_node_or_null("muzzle"));
	Kind kd = ITEMS[which - 1].kind;
	// its butt: the rearmost point of its mesh, a little under its barrel line
	_has_butt = false;
	MeshInstance3D *mesh = Object::cast_to<MeshInstance3D>(_prop->get_node_or_null("Mesh"));
	if (kd == LONG && mesh != nullptr && mesh->get_mesh().is_valid()) {
		AABB box = mesh->get_transform().xform(mesh->get_mesh()->get_aabb());
		double line = mz != nullptr ? (double)mz->get_position().y : 0.05;
		_butt = Vector3(0, (real_t)(line - 0.045), box.position.z);
		_has_butt = -(double)box.position.z >= BUTT_LEAST;
	}
	if (mz != nullptr && (kd == PISTOL || kd == LONG)) {
		// the flash of a shot: a small bright ball and a light at the muzzle, shown for the first part of the kick
		_flash = memnew(Node3D);
		_flash->set_name("Flash");
		MeshInstance3D *ball = memnew(MeshInstance3D);
		Ref<SphereMesh> sm;
		sm.instantiate();
		sm->set_radius(0.035);
		sm->set_height(0.07);
		ball->set_mesh(sm);
		Ref<StandardMaterial3D> lit;
		lit.instantiate();
		lit->set_albedo(Color(1.0, 0.85, 0.4));
		lit->set_feature(BaseMaterial3D::FEATURE_EMISSION, true);
		lit->set_emission(Color(1.0, 0.75, 0.3));
		lit->set_emission_energy_multiplier(4.0);
		lit->set_shading_mode(BaseMaterial3D::SHADING_MODE_UNSHADED);
		ball->set_material_override(lit);
		ball->set_position(Vector3(0, 0, 0.04));
		_flash->add_child(ball);
		OmniLight3D *light = memnew(OmniLight3D);
		light->set_color(Color(1.0, 0.8, 0.45));
		light->set_param(Light3D::PARAM_ENERGY, 3.0);
		light->set_param(Light3D::PARAM_RANGE, 4.0);
		_flash->add_child(light);
		_flash->set_visible(false);
		mz->add_child(_flash);
	}
}

void TravHold::_begin(const String &key, const String &clip, double from, double to, double at) {
	_plan = Dictionary();
	_plan["key"] = key;
	_plan["clip"] = clip;
	_plan["from"] = from;
	_plan["to"] = to;
	_plan["at"] = at;
	_plan["pos"] = body->get_global_position();
	_plan["yaw"] = (double)body->get_rotation().y;
	plays += 1;
	last = key;
	body->call("begin_move", Callable(this, "_spot"), clip);
}

void TravHold::_physics_process(double dt) {
	TRAV_PM(TRAV_HOLD);
	if (body == nullptr || _chr == nullptr) {
		return;
	}
	_clock += dt;
	TravBody *tb = Object::cast_to<TravBody>(body);      // (28 Nov: read directly; a script body by name as before)
	Dictionary s = tb ? tb->last_sample : (Dictionary)body->get("last_sample");
	bool in_move = (bool)body->call("in_move");
	const char *names[4] = { "fire", "reload", "drop", "hit" };
	bool now[4];
	for (int k = 0; k < 4; k++) {
		bool held = (bool)s.get(names[k], false);
		now[k] = held && !_was[k];
		_was[k] = held;
	}
	// which thing: only a change of the key counts (a thing put down is not taken up again by the key still set)
	int asked = (int)(int64_t)s.get("item", (int64_t)-1);
	if (asked != _asked && asked >= 0 && asked <= ITEM_COUNT) {
		if (!in_move && _reload_t < 0.0) {
			item = asked;
			_asked = asked;
		}
	}
	const Item *it = (_shown > 0 && _shown == item && _w >= 1.0) ? &ITEMS[_shown - 1] : nullptr;
	bool gun = it != nullptr && (it->kind == PISTOL || it->kind == LONG);
	aiming = (bool)s.get("aim", false) && gun && !in_move && _reload_t < 0.0;
	bool grounded = (tb ? tb->state == 0 && !tb->crouched : ((int64_t)body->get("state") == 0 && !(bool)body->get("crouched")));
	if (it != nullptr && !in_move) {
		if (gun) {
			if (now[0] && _reload_t < 0.0) {
				_kick = 1.0;
				shots += 1;
			}
			if (now[1] && _reload_t < 0.0 && it->reload != nullptr) {
				_reload_t = 0.0;
			}
		} else if (it->kind == FIST && grounded) {
			if (now[0]) {
				// (with the aim key held: the combination)
				String key = (bool)s.get("aim", false) ? String("fight_combo") : String(PUNCHES[_punch_n % 3]);
				_punch_n += 1;
				_begin(key, key, 0.0, _len((String)((Dictionary)_chr->get("ACTS"))[key]), 1e9);
			} else if (now[1]) {
				_begin("fight_jab", "fight_jab", 0.0, _len("Fight_Jab_Elbow"), 1e9);
			}
		} else if ((it->kind == HANG || it->kind == BOX) && now[2] && grounded) {
			const double *tm = it->kind == BOX ? PUT_BOX : PUT_BAG;
			String key = it->kind == BOX ? "put_box" : "put_bag";
			_begin(key, key, tm[0], tm[1], tm[2]);
			_plan["put"] = true;
		}
	} else if (item == 0 && _shown == 0 && !in_move && now[2] && grounded) {
		// the nearest thing on the ground within reach: he is brought to where the take picks it up from, and takes it
		int best = -1;
		double best_d = PICK_NEAR;
		for (int k = 0; k < _dropped.size(); k++) {
			Array e = _dropped[k];
			Node3D *n = Object::cast_to<Node3D>((Object *)e[0]);
			if (n == nullptr) {
				continue;
			}
			Vector3 off = n->get_global_position() - body->get_global_position();
			off.y = 0.0f;
			if ((double)off.length() < best_d) {
				best_d = (double)off.length();
				best = k;
			}
		}
		if (best >= 0) {
			Array e = _dropped[best];
			Node3D *n = Object::cast_to<Node3D>((Object *)e[0]);
			int which = (int)(int64_t)e[1];
			Vector2 reach = e[2];       // where it lay from him as he put it down: [to his right, ahead] (m)
			bool box = ITEMS[which - 1].kind == BOX;
			const double *tm = box ? PICK_BOX : PICK_BAG;
			String key = box ? "pick_box" : "pick_bag";
			Vector3 d = n->get_global_position() - body->get_global_position();
			d.y = 0.0f;
			Vector3 dn = (double)d.length() > 0.05 ? d.normalized() : -body->get_global_transform().basis.get_column(2);
			Vector3 fwd = dn.rotated(UP, (real_t)std::atan2((double)reach.x, (double)reach.y));
			Vector3 right = fwd.cross(UP).normalized();
			Vector3 stand = n->get_global_position() - fwd * reach.y - right * reach.x;
			stand.y = body->get_global_position().y;
			_begin(key, key, tm[0], tm[1], tm[2]);
			_plan["pick"] = best;
			_plan["pos_to"] = stand;
			_plan["yaw_to"] = std::atan2(-(double)fwd.x, -(double)fwd.z);
		}
	}
	if (now[3] && !in_move && grounded && (item == 0 || (it != nullptr && it->kind == FIST)) && !_plan.has("pick")) {
		String key = HITS[_hit_n % 6];
		_hit_n += 1;
		_begin(key, key, 0.0, _len((String)((Dictionary)_chr->get("ACTS"))[key]), 1e9);
	}
	if (_reload_t >= 0.0) {
		_reload_t += dt;
		if (_shown <= 0 || ITEMS[_shown - 1].reload == nullptr || _reload_t >= _len(ITEMS[_shown - 1].reload)) {
			_reload_t = -1.0;
		}
	}
	_kick = move_toward(_kick, 0.0, dt / KICK_TIME);
	// the arms come off the thing he had before the next is taken up
	bool on = item > 0 && item == _shown;
	_w = move_toward(_w, on ? 1.0 : 0.0, dt / FADE);
	if (item != _shown && _w <= 0.0) {
		_take_up(item);
	}
	_layer = move_toward(_layer, (bool)body->call("in_move") ? 0.0 : 1.0, dt / FADE);
	_aim_w = move_toward(_aim_w, aiming ? 1.0 : 0.0, dt / AIM_TIME);
	// aimed from the shoulder, his trunk turned to his right (only then: with anything else it is left untouched)
	Object *hp = (Object *)_chr->get("hands");
	if (hp != nullptr) {
		bool shouldered = _shown > 0 && ITEMS[_shown - 1].kind == LONG && _has_butt && _reload_t < 0.0;
		hp->set("twist_deg", shouldered ? -TWIST_DEG * smooth(_aim_w) * _w * _layer : 0.0);
	}
	double w[2] = { 0.0, 0.0 };
	Array iw;
	Array itn;
	Array ig;
	double hold_l = 0.0, hold_r = 0.0;
	bool turn_l = false, turn_r = false;
	double grip_l = 0.0, grip_r = 0.0;
	if (_shown > 0) {
		const Item &sh = ITEMS[_shown - 1];
		int layer = sh.kind == HANG ? 0 : 1;
		w[layer] = _w * _layer;
		bool reloading = _reload_t >= 0.0 && sh.reload != nullptr;
		String take = reloading ? String(sh.reload) : String(sh.take);
		double at = reloading ? _reload_t : (sh.at < 0.0 ? std::fmod(_clock, _len(take)) : sh.at);
		_chr->set(layer == 0 ? "hold_r_take" : "hold_b_take", take);
		_chr->set(layer == 0 ? "hold_r_t" : "hold_b_t", at);
		double aim = smooth(_aim_w);
		// the hands held on the thing itself
		if (sh.kind == BOX) {
			hold_l = hold_r = _w;
		} else if (sh.kind == LONG) {
			hold_l = reloading ? 0.0 : _w;          // (the left hand is the reload take's own while it reloads)
			hold_r = _w * aim;
			turn_l = turn_r = true;
		} else if (sh.kind == PISTOL) {
			hold_l = hold_r = _w * aim;
			turn_l = turn_r = true;
		}
		// the fingers closed on it (a box is held with open hands)
		if (sh.kind == HANG) {
			grip_r = _w;
		} else if (sh.kind != BOX) {
			grip_l = grip_r = _w;
		}
	}
	_chr->set("hold_r_w", w[0]);
	_chr->set("hold_b_w", w[1]);
	iw.push_back(hold_l);
	iw.push_back(hold_r);
	_chr->set("item_hold_w", iw);
	itn.push_back(turn_l);
	itn.push_back(turn_r);
	_chr->set("item_turned", itn);
	ig.push_back(grip_l);
	ig.push_back(grip_r);
	_chr->set("item_grip_w", ig);
	_t_set = false;
	if (_prop != nullptr) {
		_prop->set_visible(_w > 0.5);
	}
	if (_flash != nullptr) {
		_flash->set_visible(_kick > 0.55);
	}
	// a thing put down settles onto the ground
	for (int k = 0; k < _dropped.size(); k++) {
		Array e = _dropped[k];
		double gone = (double)e[5];
		if (gone < DROP_EASE) {
			gone = minf(gone + dt, DROP_EASE);
			e[5] = gone;
			Node3D *n = Object::cast_to<Node3D>((Object *)e[0]);
			if (n != nullptr) {
				n->set_global_transform(((Transform3D)e[3]).interpolate_with((Transform3D)e[4], (real_t)smooth(gone / DROP_EASE)));
			}
		}
	}
}

// A move on the spot (put down, pick up, a punch, being hit): the take from `from` to `to`, the body where it stands
// (or brought to where the take picks the thing up from), and at `at` the thing leaves or comes into his hands.
Dictionary TravHold::_spot(double t) {
	Dictionary p = _plan;
	double ct = minf((double)p["from"] + t, (double)p["to"]);
	Vector3 pos = p["pos"];
	double yaw = p["yaw"];
	if (p.has("pos_to")) {
		double u = smooth(t / ALIGN);
		pos = pos.lerp((Vector3)p["pos_to"], (real_t)u);
		yaw = lerp_angle(yaw, (double)p["yaw_to"], u);
	}
	if (!p.has("done_at") && ct >= (double)p["at"]) {
		p["done_at"] = true;
		if ((bool)p.get("put", false) && _prop != nullptr && _shown > 0) {
			// out of his hands: it stays where it is and settles upright on the ground
			Node3D *n = _prop;
			Transform3D now_t = n->get_global_transform();
			Node *world = body->get_parent();
			_skel->remove_child(n);
			world->add_child(n);
			n->set_global_transform(now_t);
			Vector3 z = now_t.basis.get_column(2);
			Basis upright(UP, (real_t)std::atan2((double)z.x, (double)z.z));
			Vector3 at = now_t.origin;
			at.y = body->get_global_position().y;
			Vector3 off = at - body->get_global_position();
			Vector3 fwd = -body->get_global_transform().basis.get_column(2);
			Vector3 right = fwd.cross(UP).normalized();
			Array e;
			e.push_back(n);
			e.push_back(_shown);
			e.push_back(Vector2(off.dot(right), off.dot(fwd)));
			e.push_back(now_t);
			e.push_back(Transform3D(upright, at));
			e.push_back(0.0);
			_dropped.push_back(e);
			_prop = nullptr;
			_flash = nullptr;
			_shown = 0;
			item = 0;
			_w = 0.0;
		} else if (p.has("pick")) {
			int k = (int)(int64_t)p["pick"];
			if (k >= 0 && k < _dropped.size()) {
				Array e = _dropped[k];
				Node3D *n = Object::cast_to<Node3D>((Object *)e[0]);
				if (n != nullptr) {
					n->get_parent()->remove_child(n);
					_skel->add_child(n);
					_prop = n;
					_shown = (int)(int64_t)e[1];
					item = _shown;
					_w = 1.0;
				}
				_dropped.remove_at(k);
			}
		}
	}
	bool done = ct >= (double)p["to"];
	Dictionary out;
	out["done"] = done;
	out["pos"] = pos;
	out["yaw"] = yaw;
	out["clip"] = (String)p["clip"];
	out["clip_t"] = ct;
	out["air"] = false;
	out["landed"] = true;
	if (done) {
		out["exit"] = ZERO;
		_plan.erase("pick");
		_plan.erase("put");
		_plan.erase("pos_to");
	}
	return out;
}

// Where a thing is from the hands as the take has them: a bag upright and side-on at the right palm; a box upright
// between the two palms; a gun along the right hand, its top up, a long one turned to lie from palm to palm.
Transform3D TravHold::_held_pose(const Item &it, const Vector3 palm[2], const Vector3 along[2], const Vector3 across[2], const Vector3 &gr, const Vector3 &gl, bool has_l) const {
	if (it.kind == HANG) {
		Basis side_on(UP, (real_t)(PI * 0.5));
		return Transform3D(side_on, palm[1] - side_on.xform(gr));
	}
	if (it.kind == BOX) {
		return Transform3D(Basis(), (palm[0] + palm[1]) * 0.5f - (gr + gl) * 0.5f);
	}
	Vector3 z = along[1];
	Vector3 y = across[1];
	if (it.kind == LONG && has_l) {
		Basis b0 = Basis(y.cross(z).normalized(), y, z).orthonormalized();
		Vector3 have = b0.xform((gl - gr).normalized());
		Vector3 want = (palm[0] - palm[1]).normalized();
		Quaternion turn(have, want);
		z = turn.xform(z);
		y = turn.xform(y);
	} else if (it.kind == PISTOL) {
		// (its top up, not rolled with the hand: Yasin was shown it rolled about 45 degrees)
		Vector3 up = UP - z * UP.dot(z);
		if ((double)up.length() > 0.2) {
			y = up.normalized();
		}
	}
	Basis b = Basis(y.cross(z).normalized(), y, z).orthonormalized();
	return Transform3D(b, palm[1] - b.xform(gr));
}

// Before the arms are solved (called by the character at modifier time, with the take's pose on the skeleton): where
// the thing is, and where each hand that is held on it has to be for its palm to lie on the thing's own hand point.
void TravHold::_refit() {
	if (_prop == nullptr || _shown <= 0 || _bone[1][0] < 0) {
		return;
	}
	const Item &it = ITEMS[_shown - 1];
	if (it.kind == HANG || it.kind == FIST) {
		return;
	}
	Object *hands = (Object *)_chr->get("hands");
	if (hands == nullptr) {
		return;
	}
	Vector3 palm[2], along[2], across[2];
	_hand(0, palm[0], along[0], across[0]);
	_hand(1, palm[1], along[1], across[1]);
	Node3D *gr_n = Object::cast_to<Node3D>(_prop->get_node_or_null("grip_r"));
	Node3D *gl_n = Object::cast_to<Node3D>(_prop->get_node_or_null("grip_l"));
	Node3D *mz_n = Object::cast_to<Node3D>(_prop->get_node_or_null("muzzle"));
	Vector3 gr = gr_n ? gr_n->get_position() : Vector3();
	Vector3 gl = gl_n ? gl_n->get_position() : gr;
	Array hold_at = hands->get("hold_at");
	Array hold_basis = hands->get("hold_basis");
	Transform3D to_world = _skel->get_global_transform();
	Vector3 wrist[2] = { _skel->get_bone_global_pose(_bone[0][0]).origin, _skel->get_bone_global_pose(_bone[1][0]).origin };
	// A hand laid on the thing: turned so that its fingers run `fingers` and its palm faces `into`, and placed so
	// that its palm point is on `at` (27 Nov, Yasin: "it lands on the side of that hand instead of in the palm").
	// where a hand's wrist goes for its palm point to be on `at` (skeleton space)
	auto wrist_for = [&](int f, const Vector3 &at, const Vector3 &fingers, const Vector3 &into) -> Vector3 {
		Vector3 a = fingers.normalized();
		Vector3 o = (into - a * into.dot(a)).normalized();
		double reach = (double)(_skel->get_bone_global_pose(_bone[f][1]).origin - wrist[f]).length();
		return at - a * (real_t)(PALM_ALONG * reach) - o * (real_t)PALM_OUT;
	};
	auto lay = [&](int f, const Vector3 &at, const Vector3 &fingers, const Vector3 &into) {
		Vector3 a = fingers.normalized();
		Vector3 o = (into - a * into.dot(a)).normalized();
		hold_at[f] = to_world.xform(wrist_for(f, at, fingers, into));
		hold_basis[f] = _chr->call("hand_turned", f, a, o);
	};
	// each arm's shoulder joint and length (shoulder to elbow to wrist), as the take has them
	Vector3 arm_sh[2];
	double arm_len[2] = { 0.0, 0.0 };
	for (int f = 0; f < 2; f++) {
		int ua = _skel->find_bone(f == 0 ? "mixamorig_LeftArm" : "mixamorig_RightArm");
		int fa = _skel->find_bone(f == 0 ? "mixamorig_LeftForeArm" : "mixamorig_RightForeArm");
		if (ua >= 0 && fa >= 0) {
			arm_sh[f] = _skel->get_bone_global_pose(ua).origin;
			Vector3 el = _skel->get_bone_global_pose(fa).origin;
			arm_len[f] = (double)(el - arm_sh[f]).length() + (double)(wrist[f] - el).length();
		}
	}
	// held out in front (a pistol, or a long gun with no stock), the hands' fingers run along the gun and a little
	// down, so that each wrist stays nearly in line with its forearm (28 Nov, Yasin's frames: the wrists bent sharply)
	const Vector3 GX(1, 0, 0), GY(0, 1, 0), GZ(0, 0, 1);
	const Vector3 out_r = GZ * 0.94f - GY * (real_t)FINGERS_DOWN;
	const Vector3 out_l = GZ * 0.87f - GY * (real_t)CUP_DOWN;
	bool held_out = it.kind == PISTOL || (it.kind == LONG && !_has_butt);
	if (!_t_set) {
		_t = _held_pose(it, palm, along, across, gr, gl, gl_n != nullptr);
		if ((it.kind == LONG || it.kind == PISTOL) && _aim_w > 0.0 && _head >= 0) {
			// aimed: pointing the way he faces (the skeleton faces +Z; his right is -X)
			Vector3 head = _skel->get_bone_global_pose(_head).origin;
			Vector3 mz = mz_n ? mz_n->get_position() : Vector3(0, 0.05f, 0.2f);
			Transform3D aimed;
			if (held_out) {
				// a pistol: its sights at his eye, centred in front of his face; a long gun with no stock: at his chin and a
				// little to his right. Both held out with his arms nearly straight: the grip is brought back from
				// AHEAD_MOST until each wrist is within OUT_REACH of its shoulder (no further, or the hands bend his trunk)
				bool pistol = it.kind == PISTOL;
				double y = head.y + EYE_UP - (pistol ? 0.0 : SHORT_DOWN) - ((double)mz.y + SIGHT_OVER);
				double x = head.x - (pistol ? 0.0 : SHORT_RIGHT);
				for (double ahead = AHEAD_MOST;; ahead -= 0.01) {
					aimed = Transform3D(Basis(), Vector3((real_t)x, (real_t)y, (real_t)(head.z + ahead)) - gr);
					Vector3 wr = wrist_for(1, aimed.xform(gr) - GX * 0.015f, out_r, GX);
					Vector3 wl = pistol ? wrist_for(0, aimed.xform(gl) + GX * 0.02f, out_l, -GX) : wrist_for(0, aimed.xform(gl), GZ * 0.5f - GX * 0.85f, GY);
					bool fits = (double)(wr - arm_sh[1]).length() <= OUT_REACH * arm_len[1] && (double)(wl - arm_sh[0]).length() <= OUT_REACH * arm_len[0];
					if (fits || ahead <= AHEAD_LEAST) {
						break;
					}
				}
			} else {
				Vector3 at((real_t)(head.x - 0.03), (real_t)(head.y + EYE_UP - ((double)mz.y + SIGHT_OVER)), (real_t)(head.z + 0.17));
				aimed = Transform3D(Basis(), at - gr);
			}
			if (it.kind == LONG && _has_butt && _shoulder >= 0) {
				// a long gun with a stock: its butt on his right shoulder, the gun level and pointing the way he faces
				// (27 Nov, Yasin: "rifle goes into his face when aiming ... place the butt of the rifle onto his
				// shoulder and place hands according to that")
				Vector3 sh = _skel->get_bone_global_pose(_shoulder).origin;
				Vector3 butt_at = sh + Vector3((real_t)BUTT_IN, (real_t)-BUTT_DOWN, (real_t)BUTT_AHEAD);
				aimed = Transform3D(Basis(), butt_at - _butt);
			}
			_t = _t.interpolate_with(aimed, (real_t)smooth(_aim_w));
		}
		if (_kick > 0.0 && (it.kind == LONG || it.kind == PISTOL)) {
			_t = _t * Transform3D(Basis(Vector3(1, 0, 0), (real_t)(-deg_to_rad(KICK_UP_DEG) * _kick)), Vector3(0, 0, (real_t)(-KICK_BACK * _kick)));
		}
		_t_set = true;
	}
	Vector3 gx = _t.basis.get_column(0);
	Vector3 gy = _t.basis.get_column(1);
	Vector3 gz = _t.basis.get_column(2);
	if (it.kind == BOX) {
		// each hand as the take turns it, moved so that its palm point is on the box's side (Yasin, 27 Nov, of this:
		// "box is okay")
		Vector3 a = _t.xform(gl);
		Vector3 b = _t.xform(gr);
		bool a_left = (a - palm[0]).length_squared() <= (b - palm[0]).length_squared();
		Vector3 want[2] = { a_left ? a : b, a_left ? b : a };
		for (int f = 0; f < 2; f++) {
			hold_at[f] = to_world.xform(want[f] - (palm[f] - wrist[f]));
		}
	} else if (it.kind == LONG) {
		// the left hand under its forend, palm up, the fingers across it; aimed, the right hand on its grip
		// (no further along it than his arm reaches with a bend left in it: his arms are short, and reaching for
		// the forend's own point with the butt on his shoulder bent his whole trunk forward)
		Vector3 fore = gl;
		int la = _skel->find_bone("mixamorig_LeftArm");
		int lf = _skel->find_bone("mixamorig_LeftForeArm");
		if (la >= 0 && lf >= 0) {
			Vector3 sh_l = _skel->get_bone_global_pose(la).origin;
			double arm = (double)(_skel->get_bone_global_pose(lf).origin - sh_l).length() + (double)(wrist[0] - _skel->get_bone_global_pose(lf).origin).length();
			double hand_len = PALM_ALONG * (double)(_skel->get_bone_global_pose(_bone[0][1]).origin - wrist[0]).length();
			for (int k = 0; k < 30; k++) {
				Vector3 fingers = (gz * 0.5f - gx * 0.85f).normalized();
				Vector3 w_at = _t.xform(fore) - fingers * (real_t)hand_len - gy * (real_t)PALM_OUT;
				// (aimed from the shoulder, further along: 28 Nov, the left hand was back by the magazine)
				double most = REACH_MOST + (REACH_AIMED - REACH_MOST) * (_has_butt ? smooth(_aim_w) : 0.0);
				if ((double)(w_at - sh_l).length() <= arm * most || (double)(fore.z - gr.z) <= FORE_LEAST) {
					break;
				}
				fore.z -= 0.01f;
			}
		}
		lay(0, _t.xform(fore), gz * 0.5f - gx * 0.85f, gy);
		if (held_out) {
			lay(1, _t.xform(gr) - gx * 0.015f, _t.basis.xform(out_r), gx);
		} else {
			lay(1, _t.xform(gr) - gx * 0.015f, gz * 0.75f - gy * 0.65f, gx);
		}
	} else {
		// a pistol aimed: the right hand on its grip, the left closed round the right from the other side
		lay(1, _t.xform(gr) - gx * 0.015f, _t.basis.xform(out_r), gx);
		lay(0, _t.xform(gl) + gx * 0.02f, _t.basis.xform(out_l), -gx);
	}
}

// Where the thing is, once the pose is finished.
void TravHold::_place() {
	if (_prop == nullptr || _shown <= 0 || _bone[1][0] < 0) {
		return;
	}
	const Item &it = ITEMS[_shown - 1];
	if (_t_set && it.kind != HANG) {
		_prop->set_transform(_t);          // (as worked out before the arms were solved onto it)
		return;
	}
	Vector3 palm[2], along[2], across[2];
	_hand(0, palm[0], along[0], across[0]);
	_hand(1, palm[1], along[1], across[1]);
	Node3D *gr_n = Object::cast_to<Node3D>(_prop->get_node_or_null("grip_r"));
	Node3D *gl_n = Object::cast_to<Node3D>(_prop->get_node_or_null("grip_l"));
	Vector3 gr = gr_n ? gr_n->get_position() : Vector3();
	Vector3 gl = gl_n ? gl_n->get_position() : gr;
	Transform3D t = _held_pose(it, palm, along, across, gr, gl, gl_n != nullptr);
	if (_kick > 0.0 && (it.kind == LONG || it.kind == PISTOL)) {
		t = t * Transform3D(Basis(Vector3(1, 0, 0), (real_t)(-deg_to_rad(KICK_UP_DEG) * _kick)), Vector3(0, 0, (real_t)(-KICK_BACK * _kick)));
	}
	_prop->set_transform(t);
}

void TravHold::_bind_methods() {
	ClassDB::bind_method(D_METHOD("_place"), &TravHold::_place);
	ClassDB::bind_method(D_METHOD("_refit"), &TravHold::_refit);
	ClassDB::bind_method(D_METHOD("_spot", "t"), &TravHold::_spot);
	ClassDB::bind_method(D_METHOD("count"), &TravHold::count);
	ClassDB::bind_method(D_METHOD("label"), &TravHold::label);
}

bool TravHold::_get(const StringName &p_name, Variant &r_ret) const {
	String n = p_name;
	if (n == "body") {
		r_ret = body;
		return true;
	}
	if (n == "item") {
		r_ret = item;
		return true;
	}
	if (n == "aiming") {
		r_ret = aiming;
		return true;
	}
	if (n == "shots") {
		r_ret = shots;
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
	if (n == "_w") {
		r_ret = _w;
		return true;
	}
	if (n == "_aim_w") {
		r_ret = _aim_w;
		return true;
	}
	if (n == "_reload_t") {
		r_ret = _reload_t;
		return true;
	}
	if (n == "_prop") {
		r_ret = _prop;
		return true;
	}
	if (n == "_dropped") {
		r_ret = _dropped;
		return true;
	}
	return false;
}

bool TravHold::_set(const StringName &p_name, const Variant &p_value) {
	String n = p_name;
	if (n == "body") {
		body = Object::cast_to<CharacterBody3D>((Object *)p_value);
		return true;
	}
	if (n == "item") {
		item = (int)(int64_t)p_value;
		return true;
	}
	return false;
}
