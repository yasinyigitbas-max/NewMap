// See trav_npc.h. Translated from traversal_lab/traversal/npc/body_fit.gd and npc_character.gd, line for line.
#include "trav_npc.h"

#include "trav_math.h"

#include <godot_cpp/classes/animation.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;
using namespace trav;

static inline double D(real_t x) { return (double)x; }
static const char *PLAYER = "res://traversal/character/player_v4_rooted.scn";
static const char *LEG[4] = { "UpLeg", "Leg", "Foot", "ToeBase" };

static Skeleton3D *find_skel(Node *n) {
	Skeleton3D *s = Object::cast_to<Skeleton3D>(n);
	if (s) {
		return s;
	}
	for (int i = 0; i < n->get_child_count(); i++) {
		Skeleton3D *c = find_skel(n->get_child(i));
		if (c) {
			return c;
		}
	}
	return nullptr;
}

void TravBodyFit::_bind_methods() {
	ClassDB::bind_method(D_METHOD("bind", "sk"), &TravBodyFit::bind);
}

bool TravBodyFit::_get(const StringName &p_name, Variant &r_ret) const {
	String n = p_name;
	if (n == "leg") {
		r_ret = leg;
		return true;
	}
	if (n == "seat") {
		r_ret = seat;
		return true;
	}
	if (n == "moved") {
		r_ret = moved;
		return true;
	}
	return false;
}

bool TravBodyFit::_set(const StringName &p_name, const Variant &p_value) {
	String n = p_name;
	if (n == "seat") {
		seat = (double)p_value;
		return true;
	}
	return false;
}

void TravBodyFit::bind(Skeleton3D *sk) {
	Ref<PackedScene> ps = ResourceLoader::get_singleton()->load(PLAYER);
	Node *scene = ps->instantiate();
	Skeleton3D *p = find_skel(scene);
	_hips = sk->find_bone("mixamorig_Hips");
	const char *side[2] = { "Left", "Right" };
	for (int f = 0; f < 2; f++) {
		for (int k = 0; k < 4; k++) {
			String name = vformat("mixamorig_%s%s", side[f], LEG[k]);
			_chain[f][k] = sk->find_bone(name);
			_theirs[f][k] = p->get_bone_rest(p->find_bone(name)).origin;
		}
	}
	double mine_len = D(sk->get_bone_rest(_chain[0][1]).origin.length()) + D(sk->get_bone_rest(_chain[0][2]).origin.length());
	leg = mine_len / (D(_theirs[0][1].length()) + D(_theirs[0][2].length()));
	_sole[0] = D(sk->get_bone_global_rest(_chain[0][2]).origin.y);
	_sole[1] = D(sk->get_bone_global_rest(_chain[0][3]).origin.y);
	_sole_p[0] = D(p->get_bone_global_rest(p->find_bone("mixamorig_LeftFoot")).origin.y);
	_sole_p[1] = D(p->get_bone_global_rest(p->find_bone("mixamorig_LeftToeBase")).origin.y);
	memdelete(scene);
}

void TravBodyFit::_process_modification_with_delta(double p_delta) {
	Skeleton3D *sk = get_skeleton();
	if (sk == nullptr || _hips < 0) {
		return;
	}
	Transform3D hips = sk->get_bone_global_pose(_hips);
	double low = INFINITY;
	double low_p = INFINITY;
	for (int f = 0; f < 2; f++) {
		Transform3D g(hips.basis.orthonormalized(), hips.origin);
		for (int k = 0; k < 4; k++) {
			int b = _chain[f][k];
			g = g * Transform3D(Basis(sk->get_bone_pose_rotation(b)), _theirs[f][k]);
			if (k >= 2) {
				low_p = minf(low_p, D(g.origin.y) - _sole_p[k - 2]);
				low = minf(low, D(sk->get_bone_global_pose(b).origin.y) - _sole[k - 2]);
			}
		}
	}
	moved = low - low_p;
	if (seat > 0.0) {
		double joint = 0.0;
		for (int f = 0; f < 2; f++) {
			joint += (D(sk->get_bone_global_pose(_chain[f][0]).origin.y) - D(hips.basis.orthonormalized().xform(_theirs[f][0]).y) - D(hips.origin.y)) * 0.5;
		}
		moved = lerpf(moved, joint, clampf(seat, 0.0, 1.0));
	}
	hips.origin.y = (real_t)(D(hips.origin.y) - moved);
	sk->set_bone_global_pose(_hips, hips);
}

// ------------------------------------------------------------------------------------------------ npc_character.gd

bool TravNpcCharacter::_get(const StringName &p_name, Variant &r_ret) const {
	String n = p_name;
	if (n == "fit") {
		r_ret = fit;
		return true;
	}
	if (n == "leg") {
		r_ret = leg;
		return true;
	}
	if (n == "_seat") {
		r_ret = _seat;
		return true;
	}
	return TravCharacter::_get(p_name, r_ret);
}

void TravNpcCharacter::_ready() {
	TravCharacter::_ready();
	fit = memnew(TravBodyFit);
	fit->set_name("BodyFit");
	skel->add_child(fit);
	skel->move_child(fit, 0);
	fit->call("bind", skel);
	leg = (double)fit->get("leg");
}

Vector2 TravNpcCharacter::_gait_for(double v) {
	Vector2 g = TravCharacter::_gait_for(v / leg);
	return Vector2(g.x, (real_t)(D(g.y) * leg));
}

void TravNpcCharacter::_measure(double dt) {
	TravCharacter::_measure(dt);
	_measured *= leg;
}

void TravNpcCharacter::_physics_process(double dt) {
	TravCharacter::_physics_process(dt);
	if (body == nullptr) {
		return;
	}
	double want = 0.0;
	bool seated = _act == "sit_idle" || _act == "sit_type" || _act == "type_to_sit";
	bool to_seat = _act == "sit_down" || _act == "sit_up" || _act == "car_in" || _act == "car_out";
	if (_mode == "move" && seated) {
		want = 1.0;
	} else if (_mode == "move" && to_seat && ACTS.has(_act)) {
		Ref<Animation> a = _lib->get_animation((String)ACTS[_act]);
		int t = a->find_track(NodePath("Skeleton3D:mixamorig_Hips"), Animation::TYPE_POSITION_3D);
		if (t >= 0) {
			double alen = (double)a->get("length");
			double h0 = D(a->position_track_interpolate(t, 0.0).y);
			double h1 = D(a->position_track_interpolate(t, alen).y);
			double h = D(a->position_track_interpolate(t, clampf(_act_t, 0.0, alen)).y);
			if (absf(h1 - h0) > 0.05) {
				want = clampf((maxf(h0, h1) - h) / absf(h1 - h0), 0.0, 1.0);
			}
		}
	}
	_seat = move_toward(_seat, want, dt / SEAT_EASE);
	fit->set("seat", _seat);
}
