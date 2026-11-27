// The things he holds. See trav_hold.h.
#include "trav_hold.h"

#include "trav_math.h"

#include <godot_cpp/classes/animation.hpp>
#include <godot_cpp/classes/animation_library.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;
using namespace trav;

static const Vector3 UP(0, 1, 0);

// What can be in his hands in the lab, in the order of the number keys.
static const TravHold::Item ITEMS[] = {
	{ "briefcase_leather", TravHold::HANG, "Walking_With_Shopping_Bag", 0.38, nullptr, 0.0 },
	{ "bag_plastic_thankyou", TravHold::HANG, "Walking_With_Shopping_Bag", 0.38, nullptr, 0.0 },
	{ "box_moving", TravHold::BOX, "Jogging_With_Box", 0.23, nullptr, 0.0 },
	{ "pistol_service", TravHold::PISTOL, "Pistol_Idle", 2.0, nullptr, 0.0 },
	{ "rifle", TravHold::LONG, "Rifle_Standing_Idle", 1.0, "Walking_While_Aiming_Rifle", 0.4 },
	{ "shotgun", TravHold::LONG, "Rifle_Standing_Idle", 1.0, "Walking_While_Aiming_Rifle", 0.4 },
};
static const int ITEM_COUNT = sizeof(ITEMS) / sizeof(ITEMS[0]);

int TravHold::count() const {
	return ITEM_COUNT;
}

String TravHold::label() const {
	return item > 0 ? String(ITEMS[item - 1].prop) + (aiming ? String(" (aimed)") : String("")) : String("nothing");
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
	Vector3 out = r_along.cross(r_across) * (side == 1 ? 1.0f : -1.0f);
	r_palm = w.lerp(k, (real_t)PALM_ALONG) + out * (real_t)PALM_OUT;
}

void TravHold::_take_up(int which) {
	if (_prop != nullptr) {
		_prop->queue_free();
		_prop = nullptr;
	}
	_shown = which;
	if (which <= 0 || _skel == nullptr) {
		return;
	}
	Ref<PackedScene> ps = ResourceLoader::get_singleton()->load(vformat("res://traversal/props/%s.scn", ITEMS[which - 1].prop));
	if (ps.is_null()) {
		return;
	}
	_prop = Object::cast_to<Node3D>(ps->instantiate());
	_prop->set_visible(false);
	_skel->add_child(_prop);
}

void TravHold::_physics_process(double dt) {
	if (body == nullptr || _chr == nullptr) {
		return;
	}
	Dictionary s = body->get("last_sample");
	int asked = (int)(int64_t)s.get("item", (int64_t)item);
	if (asked >= 0 && asked <= ITEM_COUNT) {
		item = asked;
	}
	aiming = (bool)s.get("aim", false) && item > 0 && ITEMS[item - 1].aim_take != nullptr;
	// the arms come off the thing he had before the next is taken up
	bool on = item > 0 && item == _shown;
	_w = move_toward(_w, on ? 1.0 : 0.0, dt / FADE);
	if (item != _shown && _w <= 0.0) {
		_take_up(item);
	}
	_aim_w = move_toward(_aim_w, aiming ? 1.0 : 0.0, dt / FADE);
	double w[2] = { 0.0, 0.0 };
	if (_shown > 0) {
		const Item &it = ITEMS[_shown - 1];
		int layer = it.kind == HANG ? 0 : 1;
		w[layer] = _w;
		bool aimed = _aim_w >= 0.5 && it.aim_take != nullptr;
		_chr->set(layer == 0 ? "hold_r_take" : "hold_b_take", String(aimed ? it.aim_take : it.take));
		_chr->set(layer == 0 ? "hold_r_t" : "hold_b_t", aimed ? it.aim_at : it.at);
		if (it.aim_take != nullptr) {
			// (from the hold to the aim and back: the arms go off the one and onto the other)
			w[layer] = _w * absf(_aim_w * 2.0 - 1.0);
		}
	}
	_chr->set("hold_r_w", w[0]);
	_chr->set("hold_b_w", w[1]);
	// the hands held on the thing itself: both on a box's sides, the left on a long gun's forend
	Array iw;
	iw.push_back(_shown > 0 && (ITEMS[_shown - 1].kind == BOX || ITEMS[_shown - 1].kind == LONG) ? _w : 0.0);
	iw.push_back(_shown > 0 && ITEMS[_shown - 1].kind == BOX ? _w : 0.0);
	_chr->set("item_hold_w", iw);
	_t_set = false;
	if (_prop != nullptr) {
		_prop->set_visible(_w > 0.5);
	}
}

// Before the arms are solved (called by the character at modifier time, with the take's pose on the skeleton): where
// the thing is, and where each hand that is held on it has to be for its palm to lie on the thing's own hand point.
void TravHold::_refit() {
	if (_prop == nullptr || _shown <= 0 || _bone[1][0] < 0) {
		return;
	}
	const Item &it = ITEMS[_shown - 1];
	if (it.kind != BOX && it.kind != LONG) {
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
	if (gr_n == nullptr || gl_n == nullptr) {
		return;
	}
	Vector3 gr = gr_n->get_position();
	Vector3 gl = gl_n->get_position();
	Array hold_at = hands->get("hold_at");
	Transform3D to_world = _skel->get_global_transform();
	Vector3 wrist[2] = { _skel->get_bone_global_pose(_bone[0][0]).origin, _skel->get_bone_global_pose(_bone[1][0]).origin };
	if (it.kind == BOX) {
		// the box in front of him where the take has his hands, level, facing as he does; then each palm on its side
		// (the kit's `grip_l` is at the box's own -X: his right as he holds it facing him... so each hand takes the
		// point on its own side)
		if (!_t_set) {
			_t = Transform3D(Basis(), (palm[0] + palm[1]) * 0.5f - (gr + gl) * 0.5f);
			_t_set = true;
		}
		Vector3 a = _t.xform(gl);
		Vector3 b = _t.xform(gr);
		bool a_left = (a - palm[0]).length_squared() <= (b - palm[0]).length_squared();
		Vector3 want[2] = { a_left ? a : b, a_left ? b : a };
		for (int f = 0; f < 2; f++) {
			hold_at[f] = to_world.xform(want[f] - (palm[f] - wrist[f]));
		}
	} else {
		// a long gun: it stays in the right hand; the left palm goes onto its forend
		if (!_t_set) {
			Vector3 z = along[1];
			Vector3 y = across[1];
			Basis b0 = Basis(y.cross(z).normalized(), y, z).orthonormalized();
			Vector3 have = b0.xform((gl - gr).normalized());
			Vector3 want_line = (palm[0] - palm[1]).normalized();
			Quaternion turn(have, want_line);
			Basis bb = Basis(turn.xform(y).cross(turn.xform(z)).normalized(), turn.xform(y), turn.xform(z)).orthonormalized();
			_t = Transform3D(bb, palm[1] - bb.xform(gr));
			_t_set = true;
		}
		hold_at[0] = to_world.xform(_t.xform(gl) - (palm[0] - wrist[0]));
	}
}

// Where the thing is, once the pose is finished: by the rules tried in tools/traversal/try_hold.gd.
void TravHold::_place() {
	if (_prop == nullptr || _shown <= 0 || _bone[1][0] < 0) {
		return;
	}
	const Item &it = ITEMS[_shown - 1];
	Vector3 palm[2], along[2], across[2];
	_hand(0, palm[0], along[0], across[0]);
	_hand(1, palm[1], along[1], across[1]);
	Node3D *gr_n = Object::cast_to<Node3D>(_prop->get_node_or_null("grip_r"));
	Node3D *gl_n = Object::cast_to<Node3D>(_prop->get_node_or_null("grip_l"));
	Vector3 gr = gr_n ? gr_n->get_position() : Vector3();
	Vector3 gl = gl_n ? gl_n->get_position() : gr;
	if (_t_set && (it.kind == BOX || it.kind == LONG)) {
		_prop->set_transform(_t);          // (as worked out before the arms were solved onto it)
		return;
	}
	// (the skeleton faces +Z in its own space; upright in the world is upright there)
	Transform3D t;
	if (it.kind == HANG) {
		Basis side_on(UP, (real_t)(PI * 0.5));
		t = Transform3D(side_on, palm[1] - side_on.xform(gr));
	} else if (it.kind == BOX) {
		t = Transform3D(Basis(), (palm[0] + palm[1]) * 0.5f - (gr + gl) * 0.5f);
	} else {
		Vector3 z = along[1];
		Vector3 y = across[1];
		if (it.kind == LONG && gl_n != nullptr) {
			Basis b0 = Basis(y.cross(z).normalized(), y, z).orthonormalized();
			Vector3 have = b0.xform((gl - gr).normalized());
			Vector3 want = (palm[0] - palm[1]).normalized();
			Quaternion turn(have, want);
			z = turn.xform(z);
			y = turn.xform(y);
		}
		Basis b = Basis(y.cross(z).normalized(), y, z).orthonormalized();
		t = Transform3D(b, palm[1] - b.xform(gr));
	}
	_prop->set_transform(t);
}

void TravHold::_bind_methods() {
	ClassDB::bind_method(D_METHOD("_place"), &TravHold::_place);
	ClassDB::bind_method(D_METHOD("_refit"), &TravHold::_refit);
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
	if (n == "_w") {
		r_ret = _w;
		return true;
	}
	if (n == "_prop") {
		r_ret = _prop;
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
