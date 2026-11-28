// See trav_mods.h. Each function is its script's function, line for line.
#include "trav_mods.h"
#include "trav_probe.h"

#include "trav_math.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;
using namespace trav;

static const Vector3 UP(0, 1, 0);
static const Vector3 DOWN(0, -1, 0);
static inline double D(real_t x) { return (double)x; }
static inline Vector3 mul(const Vector3 &v, double s) { return v * (real_t)s; }
static inline Basis turned(const Vector3 &axis, double angle) { return Basis(axis, (real_t)angle); }

#define GETSET_BEGIN(cls) \
	bool cls::_get(const StringName &p_name, Variant &r_ret) const { \
		String n = p_name;
#define GET(name) \
	if (n == #name) { \
		r_ret = name; \
		return true; \
	}
#define GETSET_MID(cls) \
	return false; \
	} \
	bool cls::_set(const StringName &p_name, const Variant &p_value) { \
		String n = p_name;
#define SETD(name) \
	if (n == #name) { \
		name = (double)p_value; \
		return true; \
	}
#define SETV(name) \
	if (n == #name) { \
		name = p_value; \
		return true; \
	}
#define SETA(name) \
	if (n == #name) { \
		name = (Array)p_value; \
		return true; \
	}
#define GETSET_END \
	return false; \
	}

// ------------------------------------------------------------------------------------------------ arm_open.gd

GETSET_BEGIN(TravArmOpen)
GET(flat) GET(fwd_deg) GET(palm_back) GET(open_deg)
GETSET_MID(TravArmOpen)
SETD(flat) SETD(fwd_deg) SETD(palm_back) SETD(open_deg)
GETSET_END

void TravArmOpen::_skeleton_changed(Skeleton3D *p_old, Skeleton3D *p_new) {
	_bind(p_new);
}

void TravArmOpen::_bind(Skeleton3D *sk) {
	if (sk == nullptr) {
		return;
	}
	_arm[0] = sk->find_bone("mixamorig_LeftArm");
	_arm[1] = sk->find_bone("mixamorig_RightArm");
	_chest = sk->find_bone("mixamorig_Spine2");
	_fore[0] = sk->find_bone("mixamorig_LeftForeArm");
	_fore[1] = sk->find_bone("mixamorig_RightForeArm");
	_hand[0] = sk->find_bone("mixamorig_LeftHand");
	_hand[1] = sk->find_bone("mixamorig_RightHand");
	for (int f = 0; f < 2; f++) {
		_hand_rest_inv[f] = sk->get_bone_global_rest(_hand[f]).basis.orthonormalized().inverse();
	}
	if (_chest >= 0) {
		_chest_rest_inv = sk->get_bone_global_rest(_chest).basis.orthonormalized().inverse();
	}
}

void TravArmOpen::_process_modification_with_delta(double p_delta) {
	TRAV_PM(TRAV_MODS);
	Skeleton3D *sk = get_skeleton();
	if (sk == nullptr || open_deg == 0.0) {
		return;
	}
	if (_chest < 0) {
		_bind(sk);
	}
	if (_chest < 0 || _arm[0] < 0 || _arm[1] < 0) {
		return;
	}
	Vector3 fwd = (sk->get_bone_global_pose(_chest).basis.orthonormalized() * _chest_rest_inv).xform(Vector3(0.0, 0.0, 1.0));
	for (int side = 0; side < 2; side++) {
		Transform3D g = sk->get_bone_global_pose(_arm[side]);
		g.basis = turned(fwd.normalized(), deg_to_rad(open_deg) * (side == 0 ? 1.0 : -1.0)) * g.basis;
		sk->set_bone_global_pose(_arm[side], g);
		if (flat > 0.0) {
			const int pairs[2][2] = { { _arm[side], _fore[side] }, { _fore[side], _hand[side] } };
			for (int k = 0; k < 2; k++) {
				Transform3D b = sk->get_bone_global_pose(pairs[k][0]);
				Vector3 d = (sk->get_bone_global_pose(pairs[k][1]).origin - b.origin).normalized();
				Vector3 in_plane = d - mul(fwd.normalized(), D(d.dot(fwd.normalized())));
				if (D(in_plane.length()) < 0.2) {
					continue;
				}
				Vector3 axis = d.cross(in_plane.normalized());
				if (D(axis.length()) < 0.0001) {
					continue;
				}
				b.basis = turned(axis.normalized(), D(d.angle_to(in_plane.normalized())) * flat) * b.basis;
				sk->set_bone_global_pose(pairs[k][0], b);
			}
		}
		if (fwd_deg != 0.0) {
			Transform3D up_arm = sk->get_bone_global_pose(_arm[side]);
			up_arm.basis = turned(UP, deg_to_rad(fwd_deg) * (side == 0 ? -1.0 : 1.0)) * up_arm.basis;
			sk->set_bone_global_pose(_arm[side], up_arm);
		}
		if (palm_back > 0.0) {
			Transform3D fore = sk->get_bone_global_pose(_fore[side]);
			Transform3D hand = sk->get_bone_global_pose(_hand[side]);
			Vector3 along = (hand.origin - fore.origin).normalized();
			Vector3 palm = (hand.basis.orthonormalized() * _hand_rest_inv[side]).xform(DOWN);
			Vector3 back = -fwd.normalized();
			Vector3 p0 = palm - mul(along, D(palm.dot(along)));
			Vector3 p1 = back - mul(along, D(back.dot(along)));
			if (D(p0.length()) > 0.1 && D(p1.length()) > 0.1) {
				double ang = D(p0.normalized().signed_angle_to(p1.normalized(), along));
				fore.basis = turned(along, ang * palm_back) * fore.basis;
				sk->set_bone_global_pose(_fore[side], fore);
			}
		}
	}
}

// ------------------------------------------------------------------------------------------------ trunk_turn.gd

GETSET_BEGIN(TravTrunkTurn)
GET(head_deg) GET(turn_deg)
GETSET_MID(TravTrunkTurn)
SETD(head_deg) SETD(turn_deg)
GETSET_END

void TravTrunkTurn::_process_modification_with_delta(double p_delta) {
	TRAV_PM(TRAV_MODS);
	Skeleton3D *sk = get_skeleton();
	if (sk == nullptr || (turn_deg == 0.0 && head_deg == 0.0)) {
		return;
	}
	if (_low < 0) {
		_low = sk->find_bone("mixamorig_Spine");
		_mid = sk->find_bone("mixamorig_Spine1");
		_neck = sk->find_bone("mixamorig_Neck");
		_head = sk->find_bone("mixamorig_Head");
		_arms[0] = sk->find_bone("mixamorig_LeftArm");
		_arms[1] = sk->find_bone("mixamorig_RightArm");
	}
	if (_low < 0 || _mid < 0 || _neck < 0) {
		return;
	}
	const int bones[3] = { _low, _mid, _neck };
	const double share[3] = { 0.25, 0.75, -1.0 };
	for (int k = 0; k < 3; k++) {
		Transform3D g = sk->get_bone_global_pose(bones[k]);
		g.basis = turned(UP, deg_to_rad(turn_deg * share[k])) * g.basis;
		sk->set_bone_global_pose(bones[k], g);
	}
	for (int k = 0; k < 2; k++) {
		Transform3D g = sk->get_bone_global_pose(_arms[k]);
		g.basis = turned(UP, -deg_to_rad(turn_deg)) * g.basis;
		sk->set_bone_global_pose(_arms[k], g);
	}
	if (head_deg != 0.0 && _head >= 0) {
		const int hb[2] = { _neck, _head };
		for (int k = 0; k < 2; k++) {
			Transform3D g = sk->get_bone_global_pose(hb[k]);
			g.basis = turned(UP, deg_to_rad(head_deg * 0.5)) * g.basis;
			sk->set_bone_global_pose(hb[k], g);
		}
	}
}

// ------------------------------------------------------------------------------------------------ hand_hold.gd

GETSET_BEGIN(TravHandHold)
GET(place)
GETSET_MID(TravHandHold)
SETV(place)
GETSET_END

void TravHandHold::_process_modification_with_delta(double p_delta) {
	TRAV_PM(TRAV_MODS);
	Skeleton3D *sk = get_skeleton();
	Object *pl = place;
	if (sk == nullptr || pl == nullptr) {
		return;
	}
	if (_hand[0] < 0) {
		_hand[0] = sk->find_bone("mixamorig_LeftHand");
		_hand[1] = sk->find_bone("mixamorig_RightHand");
	}
	Array w = pl->get("hold_w");
	Basis world = sk->get_global_transform().basis.orthonormalized();
	for (int f = 0; f < 2; f++) {
		Transform3D g = sk->get_bone_global_pose(_hand[f]);
		if ((double)w[f] > 0.0 && (bool)((Array)pl->get("hold_turned"))[f]) {
			_on[f] = false;
			g.basis = g.basis.orthonormalized().slerp(((Basis)((Array)pl->get("hold_basis"))[f]).orthonormalized(), (real_t)clampf((double)w[f], 0.0, 1.0));
			sk->set_bone_global_pose(_hand[f], g);
			continue;
		}
		if ((double)w[f] <= 0.0 || (bool)((Array)pl->get("hold_loose"))[f]) {
			_on[f] = false;
			continue;
		}
		if (!_on[f]) {
			_on[f] = true;
			_kept[f] = (world * g.basis).orthonormalized();
		}
		Basis want = (world.inverse() * _kept[f]).orthonormalized();
		Array flat = pl->get("hold_flat");
		if ((bool)flat[f]) {
			want = (turned(UP, f == 0 ? -PI * 0.5 : PI * 0.5) * sk->get_bone_global_rest(_hand[f]).basis).orthonormalized();
		}
		g.basis = g.basis.orthonormalized().slerp(want, (real_t)clampf((double)w[f], 0.0, 1.0));
		sk->set_bone_global_pose(_hand[f], g);
	}
}

// ------------------------------------------------------------------------------------------------ foot_orient.gd

GETSET_BEGIN(TravFootOrient)
GET(place) GET(feet)
GETSET_MID(TravFootOrient)
SETV(place) SETV(feet)
GETSET_END

void TravFootOrient::_process_modification_with_delta(double p_delta) {
	TRAV_PM(TRAV_MODS);
	Skeleton3D *sk = get_skeleton();
	Object *pl = place;
	if (sk == nullptr || pl == nullptr) {
		return;
	}
	if (_foot[0] < 0) {
		_foot[0] = sk->find_bone("mixamorig_LeftFoot");
		_foot[1] = sk->find_bone("mixamorig_RightFoot");
	}
	Array goal = pl->get("goal");
	for (int f = 0; f < 2; f++) {
		Transform3D t = sk->get_bone_global_pose(_foot[f]);
		t.basis = (Basis)goal[f];
		sk->set_bone_global_pose(_foot[f], t);
	}
}

// ------------------------------------------------------------------------------------------------ finger_grip.gd

GETSET_BEGIN(TravFingerGrip)
GET(w) GET(deg) GET(thumb_to) GET(thumb_w)
GETSET_MID(TravFingerGrip)
SETA(w) SETA(deg) SETA(thumb_to) SETA(thumb_w)
GETSET_END

void TravFingerGrip::_bind_methods() {
	ClassDB::bind_method(D_METHOD("hand_frame", "sk", "f"), &TravFingerGrip::hand_frame);
}

TravFingerGrip::TravFingerGrip() {
	w.push_back(0.0);
	w.push_back(0.0);
	for (int f = 0; f < 2; f++) {
		Array one;
		one.push_back(61.0);
		one.push_back(60.0);
		one.push_back(39.0);
		deg.push_back(one);
		thumb_to.push_back(Vector3());
		thumb_w.push_back(0.0);
		for (int k = 0; k < 4; k++) {
			_thumb[f][k] = -1;
		}
		for (int k = 0; k < 3; k++) {
			_knuckle[f][k] = -1;
		}
	}
}

void TravFingerGrip::_bind(Skeleton3D *sk) {
	const char *side[2] = { "Left", "Right" };
	const char *names[4] = { "Index", "Middle", "Ring", "Pinky" };
	for (int f = 0; f < 2; f++) {
		_hand[f] = sk->find_bone(vformat("mixamorig_%sHand", side[f]));
		_knuckle[f][0] = sk->find_bone(vformat("mixamorig_%sHandIndex1", side[f]));
		_knuckle[f][1] = sk->find_bone(vformat("mixamorig_%sHandMiddle1", side[f]));
		_knuckle[f][2] = sk->find_bone(vformat("mixamorig_%sHandPinky1", side[f]));
		for (int k = 0; k < 4; k++) {
			for (int j = 0; j < 3; j++) {
				_fingers[f][k][j] = sk->find_bone(vformat("mixamorig_%sHand%s%d", side[f], names[k], j + 1));
			}
			_thumb[f][k] = sk->find_bone(vformat("mixamorig_%sHandThumb%d", side[f], k + 1));
		}
	}
	Vector3 rw = sk->get_bone_global_rest(_hand[1]).origin;
	Vector3 ri = sk->get_bone_global_rest(_knuckle[1][0]).origin;
	Vector3 rp = sk->get_bone_global_rest(_knuckle[1][2]).origin;
	_palm_sign = D((ri - rw).cross(rp - rw).dot(DOWN)) > 0.0 ? 1.0 : -1.0;
}

Array TravFingerGrip::hand_frame(Skeleton3D *sk, int f) {
	if (_hand[0] < 0) {
		_bind(sk);
	}
	Vector3 wr = sk->get_bone_global_pose(_hand[f]).origin;
	Vector3 i1 = sk->get_bone_global_pose(_knuckle[f][0]).origin;
	Vector3 m1 = sk->get_bone_global_pose(_knuckle[f][1]).origin;
	Vector3 p1 = sk->get_bone_global_pose(_knuckle[f][2]).origin;
	Vector3 along = (m1 - wr).normalized();
	Vector3 out = mul(mul((i1 - wr).cross(p1 - wr), _palm_sign), f == 0 ? -1.0 : 1.0).normalized();
	Array r;
	r.push_back(wr);
	r.push_back(along);
	r.push_back(out);
	r.push_back((i1 - p1).normalized());
	r.push_back(D((m1 - wr).length()));
	return r;
}

void TravFingerGrip::_process_modification_with_delta(double p_delta) {
	TRAV_PM(TRAV_MODS);
	Skeleton3D *sk = get_skeleton();
	if (sk == nullptr) {
		return;
	}
	if (_hand[0] < 0) {
		_bind(sk);
	}
	for (int f = 0; f < 2; f++) {
		double much = clampf((double)w[f], 0.0, 1.0);
		if (much <= 0.0 || _hand[f] < 0) {
			continue;
		}
		Array fr = hand_frame(sk, f);
		Vector3 axis = ((Vector3)fr[1]).cross((Vector3)fr[2]).normalized();
		Transform3D hand = sk->get_bone_global_pose(_hand[f]);
		for (int k = 0; k < 4; k++) {
			Transform3D parent = hand;
			for (int j = 0; j < 3; j++) {
				int b = _fingers[f][k][j];
				if (b < 0) {
					break;
				}
				Transform3D t = parent * sk->get_bone_rest(b);
				Basis bent = (turned(axis, deg_to_rad((double)((Array)deg[f])[j])) * t.basis).orthonormalized();
				Basis now = (parent.basis * sk->get_bone_pose(b).basis).orthonormalized();
				t.basis = now.slerp(bent, (real_t)much);
				sk->set_bone_global_pose(b, t);
				parent = t;
			}
		}
		double tw = clampf((double)thumb_w[f], 0.0, 1.0);
		if (tw > 0.0 && _thumb[f][0] >= 0) {
			Transform3D parent2 = sk->get_bone_global_pose(_hand[f]);
			for (int j = 0; j < 3; j++) {
				int b2 = _thumb[f][j];
				Transform3D t2 = parent2 * sk->get_bone_rest(b2);
				Vector3 from = t2.basis.xform(sk->get_bone_rest(_thumb[f][j + 1]).origin).normalized();
				Vector3 to = ((Vector3)thumb_to[f] - t2.origin).normalized();
				Vector3 ax = from.cross(to);
				Basis aimed = t2.basis.orthonormalized();
				if (D(ax.length()) > 0.0001) {
					aimed = (turned(ax.normalized(), D(from.angle_to(to))) * aimed).orthonormalized();
				}
				Basis now2 = (parent2.basis * sk->get_bone_pose(b2).basis).orthonormalized();
				t2.basis = now2.slerp(aimed, (real_t)tw);
				sk->set_bone_global_pose(b2, t2);
				parent2 = t2;
			}
		}
	}
}
