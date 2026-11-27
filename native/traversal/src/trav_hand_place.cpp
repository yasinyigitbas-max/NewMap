// See trav_hand_place.h. Translated from traversal_lab/traversal/character/hand_place.gd, line for line.
#include "trav_hand_place.h"
#include "trav_probe.h"

#include "trav_math.h"

#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/typed_array.hpp>

using namespace godot;
using namespace trav;

static const Vector3 DOWN(0, -1, 0);
static const Vector3 RIGHT(1, 0, 0);
static inline double D(real_t x) { return (double)x; }
static inline Vector3 V(double x, double y, double z) { return Vector3((real_t)x, (real_t)y, (real_t)z); }
static inline Vector3 mul(const Vector3 &v, double s) { return v * (real_t)s; }

TravHandPlace::TravHandPlace() {
	for (int f = 0; f < 2; f++) {
		hold_at.push_back(Vector3());
		hold_w.push_back(0.0);
		hold_turned.push_back(false);
		hold_basis.push_back(Basis());
		hold_loose.push_back(false);
		hold_flat.push_back(false);
		reach.push_back(0.0);
	}
}

void TravHandPlace::_bind_methods() {
	ClassDB::bind_method(D_METHOD("bind", "sk"), &TravHandPlace::bind);
}

#define HP_VARS(X) X(body) X(hold_at) X(hold_w) X(hold_turned) X(hold_basis) X(hold_loose) X(hold_flat) X(refit) X(on) \
	X(clip_slope) X(hand_low) X(target) X(pole) X(ik) X(hips_down) X(reach) X(bend_deg)

static inline void take(double &d, const Variant &v) { d = (double)v; }
static inline void take(bool &d, const Variant &v) { d = (bool)v; }
static inline void take(Array &d, const Variant &v) { d = (Array)v; }
static inline void take(Callable &d, const Variant &v) { d = (Callable)v; }
static inline void take(Variant &d, const Variant &v) { d = v; }

bool TravHandPlace::_get(const StringName &p_name, Variant &r_ret) const {
	String n = p_name;
#define X(v) \
	if (n == #v) { \
		r_ret = v; \
		return true; \
	}
	HP_VARS(X)
#undef X
#define C(v) \
	if (n == #v) { \
		r_ret = (double)v; \
		return true; \
	}
	C(PALM) C(BAND) C(STRAIGHT) C(HIPS_MOST) C(EASE) C(BEND_MOST_DEG) C(BEND_RATE_DEG)
#undef C
	return false;
}

bool TravHandPlace::_set(const StringName &p_name, const Variant &p_value) {
	String n = p_name;
#define X(v) \
	if (n == #v) { \
		take(v, p_value); \
		return true; \
	}
	HP_VARS(X)
#undef X
	return false;
}

void TravHandPlace::bind(Skeleton3D *sk) {
	const char *side[2] = { "Left", "Right" };
	for (int f = 0; f < 2; f++) {
		_upper[f] = sk->find_bone(vformat("mixamorig_%sArm", side[f]));
		_fore[f] = sk->find_bone(vformat("mixamorig_%sForeArm", side[f]));
		_hand[f] = sk->find_bone(vformat("mixamorig_%sHand", side[f]));
		_len[f] = D(sk->get_bone_rest(_fore[f]).origin.length()) + D(sk->get_bone_rest(_hand[f]).origin.length());
	}
	_spine = sk->find_bone("mixamorig_Spine");
}

void TravHandPlace::_process_modification_with_delta(double dt) {
	Skeleton3D *sk = get_skeleton();
	CharacterBody3D *bd = Object::cast_to<CharacterBody3D>((Object *)body);
	if (sk == nullptr || bd == nullptr || target.size() < 2 || ik.size() < 2 || _hand[0] < 0) {
		return;
	}
	Transform3D xf = sk->get_global_transform();
	Transform3D inv = xf.affine_inverse();
	if (refit.is_valid()) {
		refit.call();
	}
	double want_bend = 0.0;
	if (_spine >= 0 && (double)hold_w[0] > 0.0 && (double)hold_w[1] > 0.0) {
		Vector3 pivot = sk->get_bone_global_pose(_spine).origin;
		double best = INFINITY;
		for (int d = 0; d < (int)BEND_MOST_DEG + 1; d++) {
			Basis rot(RIGHT, (real_t)deg_to_rad((double)d));
			double short_by = 0.0;
			for (int f = 0; f < 2; f++) {
				Vector3 sh = pivot + rot.xform(sk->get_bone_global_pose(_upper[f]).origin - pivot);
				short_by = maxf(short_by, D(sh.distance_to(inv.xform((Vector3)hold_at[f]))) - _len[f] * STRAIGHT);
			}
			if (short_by < best - 0.001) {
				best = short_by;
				want_bend = (double)d;
			}
			if (short_by <= 0.0) {
				break;
			}
		}
		want_bend *= minf((double)hold_w[0], (double)hold_w[1]);
	}
	bend_deg = move_toward(bend_deg, want_bend, BEND_RATE_DEG * dt);
	if (_spine >= 0 && bend_deg > 0.01) {
		Transform3D g = sk->get_bone_global_pose(_spine);
		g.basis = Basis(RIGHT, (real_t)deg_to_rad(bend_deg)) * g.basis;
		sk->set_bone_global_pose(_spine, g);
		if (refit.is_valid()) {
			refit.call();
		}
	}
	bool grounded = (int)(int64_t)bd->get("state") == 0;
	double short_ = -1.0;
	bool reaching = false;
	for (int f = 0; f < 2; f++) {
		Vector3 shoulder_s = sk->get_bone_global_pose(_upper[f]).origin;
		Vector3 elbow_s = sk->get_bone_global_pose(_fore[f]).origin;
		Vector3 hand_s = sk->get_bone_global_pose(_hand[f]).origin;
		double want = 0.0;
		Vector3 goal = hand_s;
		if (on && grounded) {
			double over = D(hand_s.y) - clip_slope * D(hand_s.z) - hand_low;
			want = clampf(1.0 - over / BAND, 0.0, 1.0);
			if (want > 0.0) {
				Vector3 hand = xf.xform(hand_s);
				TypedArray<RID> ex;
				ex.push_back(bd->get_rid());
				Dictionary hit = bd->get_world_3d()->get_direct_space_state()->intersect_ray(PhysicsRayQueryParameters3D::create(hand + V(0.0, 1.0, 0.0), hand - V(0.0, 1.5, 0.0), trav::probe_mask(bd), ex));
				if (hit.is_empty()) {
					want = 0.0;
				} else {
					goal = inv.xform((Vector3)hit["position"] + mul((Vector3)hit["normal"], PALM));
				}
			}
		}
		if ((double)hold_w[f] > 0.0) {
			goal = inv.xform((Vector3)hold_at[f]);
			reach[f] = (double)hold_w[f];
		} else {
			reach[f] = move_toward((double)reach[f], want, dt / EASE);
		}
		Vector3 to = goal - shoulder_s;
		double most = _len[f] * STRAIGHT;
		if (want > 0.0) {
			reaching = true;
			short_ = maxf(short_, (D(to.length()) - most) * want);
		}
		if (D(to.length()) > most) {
			to = mul(to.normalized(), most);
		}
		Object::cast_to<Node3D>((Object *)target[f])->set_position(shoulder_s + to);
		Vector3 line = to.normalized();
		Vector3 bend = elbow_s - mul(shoulder_s + hand_s, 0.5);
		Vector3 square = bend - mul(line, D(bend.dot(line)));
		if ((double)hold_w[f] > 0.0 && (bool)hold_turned[f]) {
			Vector3 hang = DOWN + V(f == 0 ? 0.35 : -0.35, 0.0, 0.0);
			square = square.lerp(hang - mul(line, D(hang.dot(line))), (real_t)clampf((double)hold_w[f], 0.0, 1.0));
		}
		if (D(square.length()) < 0.02) {
			Vector3 back = sk->get_bone_global_pose(sk->get_bone_parent(_upper[f])).basis.xform(V(0.0, 0.0, -1.0)) + DOWN;
			square = back - mul(line, D(back.dot(line)));
		}
		Object::cast_to<Node3D>((Object *)pole[f])->set_position(shoulder_s + mul(to, 0.5) + mul(square.normalized(), 0.5));
		SkeletonModifier3D *one = Object::cast_to<SkeletonModifier3D>((Object *)ik[f]);
		one->set_influence((double)reach[f]);
		one->set_active((double)reach[f] > 0.0);
	}
	if (reaching) {
		hips_down = clampf(hips_down + short_ * 0.5, 0.0, HIPS_MOST);
	} else {
		hips_down = move_toward(hips_down, 0.0, HIPS_MOST * dt / (3.0 * EASE));
	}
}
