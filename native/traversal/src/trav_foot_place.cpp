// See trav_foot_place.h. Translated from traversal_lab/traversal/character/foot_place.gd, line for line.
#include "trav_foot_place.h"
#include "trav_probe.h"

#include "trav_math.h"

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

using namespace godot;
using namespace trav;

static const Vector3 UP(0, 1, 0);
static const Vector3 ZERO(0, 0, 0);
static inline double D(real_t x) { return (double)x; }
static inline Vector3 V(double x, double y, double z) { return Vector3((real_t)x, (real_t)y, (real_t)z); }
static inline Vector3 mul(const Vector3 &v, double s) { return v * (real_t)s; }

// the engine's own smoothstep, in doubles (core/math/math_funcs.h)
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

TravFootPlace::TravFootPlace() {
	goal.push_back(Basis());
	goal.push_back(Basis());
	land_at.push_back(Vector3());
	land_at.push_back(Vector3());
}

void TravFootPlace::_bind_methods() {
	ClassDB::bind_method(D_METHOD("bind", "sk"), &TravFootPlace::bind);
}

#define FP_VARS(X) X(body) X(target) X(pole) X(goal) X(weight) X(clip_slope) X(stride_fit) X(stride_dir) X(land_at) \
	X(by_speed) X(stand_wide) X(hands) X(step_high) X(step_edge) X(step_rise) X(step_real) X(base) X(hips_fit) \
	X(stand_on) X(gap_fit) X(ledge_fit) X(pinning) X(grounding) X(_toe_rest) X(_ankle_rest) X(_pelvis) X(_ride)

static inline void take(double &d, const Variant &v) { d = (double)v; }
static inline void take(bool &d, const Variant &v) { d = (bool)v; }
static inline void take(Array &d, const Variant &v) { d = (Array)v; }
static inline void take(Vector3 &d, const Variant &v) { d = (Vector3)v; }
static inline void take(Variant &d, const Variant &v) { d = v; }

bool TravFootPlace::_get(const StringName &p_name, Variant &r_ret) const {
	String n = p_name;
#define X(v) \
	if (n == #v) { \
		r_ret = v; \
		return true; \
	}
	FP_VARS(X)
#undef X
#define X(c, v) \
	if (n == #c) { \
		r_ret = (double)c; \
		return true; \
	}
	TRAV_FOOT_CONSTS(X)
#undef X
	return false;
}

bool TravFootPlace::_set(const StringName &p_name, const Variant &p_value) {
	String n = p_name;
#define X(v) \
	if (n == #v) { \
		take(v, p_value); \
		return true; \
	}
	FP_VARS(X)
#undef X
	return false;
}

void TravFootPlace::bind(Skeleton3D *sk) {
	_hips = sk->find_bone("mixamorig_Hips");
	const char *side[2] = { "Left", "Right" };
	for (int f = 0; f < 2; f++) {
		_thigh[f] = sk->find_bone(vformat("mixamorig_%sUpLeg", side[f]));
		_shin[f] = sk->find_bone(vformat("mixamorig_%sLeg", side[f]));
		_foot[f] = sk->find_bone(vformat("mixamorig_%sFoot", side[f]));
		_toe[f] = sk->find_bone(vformat("mixamorig_%sToeBase", side[f]));
		_leg_len[f] = D(sk->get_bone_rest(_shin[f]).origin.length()) + D(sk->get_bone_rest(_foot[f]).origin.length());
		Vector3 side_rest = sk->get_bone_global_rest(_thigh[f]).basis.get_column(0).normalized();
		Vector3 down_rest = (sk->get_bone_global_rest(_foot[f]).origin - sk->get_bone_global_rest(_thigh[f]).origin).normalized();
		_front[f] = D(side_rest.cross(down_rest).z) > 0.0 ? 1.0 : -1.0;
	}
	_toe_rest = D(sk->get_bone_global_rest(_toe[0]).origin.y);
	_ankle_rest = D(sk->get_bone_global_rest(_foot[0]).origin.y);
}

Dictionary TravFootPlace::_ground(CharacterBody3D *bd, const Vector3 &at, double feet_y) {
	TypedArray<RID> ex;
	ex.push_back(bd->get_rid());
	return TRAV_RAY(bd, PhysicsRayQueryParameters3D::create(V(D(at.x), feet_y + REACH, D(at.z)), V(D(at.x), feet_y - REACH, D(at.z)), trav::probe_mask(bd), ex));
}

void TravFootPlace::_process_modification_with_delta(double dt) {
	TRAV_PM(TRAV_MODS);
	Skeleton3D *sk = get_skeleton();
	CharacterBody3D *bd = Object::cast_to<CharacterBody3D>((Object *)body);
	if (sk == nullptr || bd == nullptr || _hips < 0 || target.size() < 2) {
		return;
	}
	bool on_ground = (int)(int64_t)bd->get("state") == 0;
	weight = move_toward(weight, on_ground ? 1.0 : 0.0, dt / WEIGHT_TIME);
	if (on_ground && bd->has_method("in_move") && (bool)bd->call("in_move") && (bool)bd->get("move_landed")) {
		weight = 1.0;
	}
	Transform3D xf = sk->get_global_transform();
	Transform3D inv = xf.affine_inverse();
	double feet_y = D(bd->get_global_position().y) + base;
	double pace = D(((Vector3)bd->get("hvel")).length());
	double let_go = 1.0 - std::exp(-dt / LET_GO);
	double want_pelvis = 0.0;
	Vector3 ankle_goal[2];
	Vector3 hip_at[2];
	Vector3 hinge_at[2];
	Vector3 want_in[2];
	if (stand_on > 0.0 && on_ground && grounding) {
		_onto(bd, sk, xf, feet_y, want_in);
	}
	for (int f = 0; f < 2; f++) {
		_in[f] = _in[f].lerp(mul(want_in[f], stand_on), (real_t)(1.0 - std::exp(-dt / IN_TIME)));
	}
	for (int f = 0; f < 2; f++) {
		Transform3D hip_t = sk->get_bone_global_pose(_thigh[f]);
		Transform3D ankle_t = sk->get_bone_global_pose(_foot[f]);
		Transform3D ball_t = sk->get_bone_global_pose(_toe[f]);
		Vector3 hip = xf.xform(hip_t.origin);
		Vector3 ankle = xf.xform(ankle_t.origin);
		Vector3 ball = xf.xform(ball_t.origin);
		Basis basis = (xf.basis * ankle_t.basis).orthonormalized();
		hip_at[f] = hip;
		hinge_at[f] = hip_t.basis.get_column(0).normalized();
		double own_floor = 0.0;
		if (step_high != 0.0) {
			own_floor = step_high * smoothstep(step_edge - STEP_SOFT, step_edge, D(ball_t.origin.z)) - step_rise;
		}
		double ball_h = D(ball_t.origin.y) - clip_slope * D(ball_t.origin.z) - own_floor;
		bool low = on_ground && (by_speed || ball_h < _toe_rest + CONTACT);
		double over = _was_ok ? D(Vector2((real_t)(D(ball.x) - D(_was[f].x)), (real_t)(D(ball.z) - D(_was[f].z))).length()) / dt : 0.0;
		_was[f] = ball;
		bool slow = over < (_planted[f] ? maxf(HOLD_LEAST, pace * HOLD_SHARE) : maxf(PLANT_LEAST, pace * PLANT_SHARE));
		bool planted = low && slow;
		if (planted && pinning) {
			Vector3 flat = V(D(ball.x), 0.0, D(ball.z));
			if (!_planted[f]) {
				_pin[f] = flat + _corr[f];
			}
			Vector3 c = _pin[f] - flat;
			if (D(c.length()) > PIN_MOST) {
				c = mul(c.normalized(), PIN_MOST);
				_pin[f] = flat + c;
			}
			_corr[f] = c;
		} else {
			_corr[f] = mul(_corr[f], 1.0 - let_go);
		}
		bool was_planted = _planted[f];
		_planted[f] = planted;
		ball += _corr[f];
		ankle += _corr[f];
		if (stand_wide != 0.0) {
			Vector3 side = xf.basis.get_column(0).normalized();
			Vector3 out = mul(side, signf(D((ankle - xf.xform(sk->get_bone_global_pose(_hips).origin)).dot(side))) * stand_wide);
			ball += out;
			ankle += out;
		}
		ball += _in[f];
		ankle += _in[f];
		if (gap_fit > 0.0) {
			Vector3 n = bd->get("squeeze_across");
			double half = (double)bd->get("squeeze_w") * 0.5 - SHOE_CLEAR;
			Vector3 mid_line = bd->get("squeeze_mid");
			double ca = D((ankle - mid_line).dot(n));
			double cb = D((ball - mid_line).dot(n));
			double move = 0.0;
			if (absf(ca - cb) >= 2.0 * half) {
				move = -(ca + cb) * 0.5;
			} else {
				move = clampf(0.0, -half - minf(ca, cb), half - maxf(ca, cb));
			}
			_gap_in[f] = std::isfinite(half) ? _gap_in[f].lerp(mul(n, move), (real_t)(1.0 - std::exp(-dt / IN_TIME))) : ZERO;
		} else if (ledge_fit > 0.0) {
			Vector3 out_n = bd->get("ledge_out");
			double from_wall = D((ankle - (Vector3)bd->get("ledge_wall")).dot(out_n));
			_gap_in[f] = _gap_in[f].lerp(mul(out_n, HEEL_OFF - from_wall), (real_t)(1.0 - std::exp(-dt / IN_TIME)));
		} else {
			_gap_in[f] = mul(_gap_in[f], std::exp(-dt / IN_TIME));
		}
		double fit_w = maxf(gap_fit, ledge_fit);
		ball += mul(_gap_in[f], fit_w > 0.0 ? fit_w : 1.0);
		ankle += mul(_gap_in[f], fit_w > 0.0 ? fit_w : 1.0);
		double want_g = feet_y;
		Vector3 normal = UP;
		if (grounding && on_ground) {
			Dictionary gb = _ground(bd, ball, feet_y);
			Dictionary ga = _ground(bd, ankle, feet_y);
			if (!gb.is_empty()) {
				want_g = D(((Vector3)gb["position"]).y);
				normal = gb["normal"];
				if (!ga.is_empty() && D(normal.y) > 0.98 && D(((Vector3)ga["normal"]).y) > 0.98) {
					want_g = maxf(want_g, D(((Vector3)ga["position"]).y));
				}
			} else if (!ga.is_empty()) {
				want_g = D(((Vector3)ga["position"]).y);
				normal = ga["normal"];
			}
		}
		if (!_g_ok || !on_ground) {
			_g[f] = want_g;
		}
		_g[f] = move_toward(_g[f], want_g, FOOT_SPEED * dt);
		Vector3 flat_ball = V(D(ball.x), 0.0, D(ball.z));
		if (planted) {
			_hold_p[f] = flat_ball;
			_hold_g[f] = _g[f];
		} else if (stride_fit && on_ground) {
			Vector3 la = land_at[f];
			Vector3 next = V(D(la.x), 0.0, D(la.z));
			if (was_planted) {
				_from_p[f] = _hold_p[f];
				_from_g[f] = _hold_g[f];
				_to_p[f] = next;
				_bound[f] = true;
			} else if (_bound[f] && D(next.distance_to(_to_p[f])) < SAME_STEP) {
				_to_p[f] = next;
			}
			if (_bound[f]) {
				Vector3 at = _to_p[f];
				TypedArray<RID> ex;
				ex.push_back(bd->get_rid());
				Dictionary gl = TRAV_RAY(bd, PhysicsRayQueryParameters3D::create(V(D(at.x), feet_y + 2.0 * REACH, D(at.z)), V(D(at.x), feet_y - 2.0 * REACH, D(at.z)), trav::probe_mask(bd), ex));
				_to_g[f] = !gl.is_empty() ? D(((Vector3)gl["position"]).y) : _from_g[f];
			}
		}
		if (!stride_fit || !on_ground) {
			_bound[f] = false;
		}
		_swing[f] = move_toward(_swing[f], (_bound[f] && !planted) ? 1.0 : 0.0, dt / LET_GO);
		double ground_f = _g[f];
		if (_swing[f] > 0.0) {
			Vector3 span = _to_p[f] - _from_p[f];
			double u = clampf(D((flat_ball - _from_p[f]).dot(span)) / maxf(D(span.length_squared()), 0.0025), 0.0, 1.0);
			ground_f = lerpf(ground_f, lerpf(_from_g[f], _to_g[f], u), _swing[f]);
		}
		if (by_speed && planted) {
			_lump[f] = lerpf(_lump[f], _toe_rest - ball_h, let_go);
		} else if (!by_speed) {
			_lump[f] = lerpf(_lump[f], 0.0, let_go);
		}
		double lift = clampf(ground_f - feet_y, -REACH, REACH) - clip_slope * D(ball_t.origin.z) + _lump[f] - own_floor;
		bool stepping = step_high != 0.0;
		if (stepping) {
			double past = smoothstep(step_edge - STEP_SOFT, step_edge, D(ball_t.origin.z));
			lift = (step_real - step_high) * (past - step_rise / step_high);
		}
		double near = clampf(1.0 - (ball_h + _lump[f] - _toe_rest) / NEAR, 0.0, 1.0);
		Vector3 axis = UP.cross(normal);
		Basis tilt;
		if (D(axis.length()) > 0.001 && near > 0.0) {
			tilt = Basis(axis.normalized(), (real_t)(minf(D(UP.angle_to(normal)), TILT_MOST) * near));
		}
		Vector3 ball_goal = ball + V(0.0, lift, 0.0);
		if (grounding && on_ground && !stepping) {
			Dictionary gt = _ground(bd, ball_goal, feet_y);
			if (!gt.is_empty() && D(((Vector3)gt["normal"]).y) > 0.3) {
				double off_t = D((ball_goal - (Vector3)gt["position"]).dot((Vector3)gt["normal"]));
				if (off_t < _toe_rest) {
					ball_goal.y = (real_t)(D(ball_goal.y) + (_toe_rest - off_t) / D(((Vector3)gt["normal"]).y));
				}
			}
		}
		ankle_goal[f] = ball_goal + tilt.xform(ankle - ball);
		if (grounding && on_ground && !stepping) {
			Dictionary gh = _ground(bd, ankle_goal[f], feet_y);
			if (!gh.is_empty() && D(((Vector3)gh["normal"]).y) > 0.3) {
				double off = D((ankle_goal[f] - (Vector3)gh["position"]).dot((Vector3)gh["normal"]));
				if (off < _ankle_rest) {
					ankle_goal[f] = ankle_goal[f] + V(0.0, (_ankle_rest - off) / D(((Vector3)gh["normal"]).y), 0.0);
				}
			}
		}
		goal[f] = (xf.basis.orthonormalized().inverse() * (tilt * basis)).orthonormalized();
		double flat_gap = D(Vector2((real_t)(D(ankle_goal[f].x) - D(hip.x)), (real_t)(D(ankle_goal[f].z) - D(hip.z))).length());
		double most = _leg_len[f] * STRAIGHT;
		if (planted && flat_gap < most) {
			want_pelvis = minf(want_pelvis, std::sqrt(most * most - flat_gap * flat_gap) - (D(hip.y) - D(ankle_goal[f].y)));
		}
	}
	_was_ok = true;
	_g_ok = true;
	double off = 0.0;
	if (stride_fit && on_ground && (_planted[0] || _bound[0]) && (_planted[1] || _bound[1])) {
		Vector3 p[2];
		double g[2];
		for (int f = 0; f < 2; f++) {
			p[f] = (!_planted[f] && _bound[f]) ? _to_p[f] : _hold_p[f];
			g[f] = (!_planted[f] && _bound[f]) ? _to_g[f] : _hold_g[f];
		}
		double span = D((p[1] - p[0]).dot(stride_dir));
		Vector3 bp = bd->get_global_position();
		Vector3 here = V(D(bp.x), 0.0, D(bp.z));
		double u = absf(span) > 0.05 ? clampf(D((here - p[0]).dot(stride_dir)) / span, -2.0, 3.0) : 0.5;
		off = feet_y - lerpf(g[0], g[1], u);
	}
	_ride += (off - _ride) * (1.0 - std::exp(-dt / HIPS_TIME));
	Object *hands_o = hands;
	double for_hands = hands_o ? (double)hands_o->get("hips_down") : 0.0;
	want_pelvis = on_ground ? maxf(minf(want_pelvis, hips_fit - _ride) - for_hands, -HIPS_MOST) : 0.0;
	if (want_pelvis < _pelvis) {
		_pelvis = maxf(want_pelvis, _pelvis - HIPS_DOWN * dt);
	} else {
		_pelvis += (want_pelvis - _pelvis) * (1.0 - std::exp(-dt / HIPS_TIME));
	}
	Transform3D hips_t = sk->get_bone_global_pose(_hips);
	hips_t.origin.y = (real_t)(D(hips_t.origin.y) + _pelvis);
	Vector3 want_out = ZERO;
	if (ledge_fit > 0.0) {
		Vector3 out_n = bd->get("ledge_out");
		double hips_from = D((xf.xform(hips_t.origin) - (Vector3)bd->get("ledge_wall")).dot(out_n));
		want_out = mul(mul(out_n, maxf(BACK_OFF - hips_from, 0.0)), ledge_fit);
	}
	_hips_out = _hips_out.lerp(want_out, (real_t)(1.0 - std::exp(-dt / IN_TIME)));
	hips_t.origin += inv.basis.xform(_hips_out);
	sk->set_bone_global_pose(_hips, hips_t);
	for (int f = 0; f < 2; f++) {
		Vector3 hip = hip_at[f] + V(0.0, _pelvis, 0.0) + _hips_out;
		Vector3 to = ankle_goal[f] - hip;
		double most = _leg_len[f] * STRAIGHT;
		if (D(to.length()) > most) {
			to = mul(to.normalized(), most);
		}
		Node3D *tn = Object::cast_to<Node3D>((Object *)target[f]);
		tn->set_position(inv.xform(hip + to));
		Vector3 hip_now = inv.xform(hip);
		Vector3 ankle_now = tn->get_position();
		Vector3 line = (ankle_now - hip_now).normalized();
		Vector3 hinge = hinge_at[f];
		Vector3 front = mul(hinge.cross(line), _front[f]);
		if (D(front.length()) < 0.2) {
			Vector3 fwd = sk->get_bone_global_pose(_hips).basis.xform(V(0.0, 0.0, 1.0));
			Vector3 lead = (fwd + UP).normalized();
			front = lead - mul(line, D(lead.dot(line)));
		}
		Object::cast_to<Node3D>((Object *)pole[f])->set_position(mul(hip_now + ankle_now, 0.5) + mul(front.normalized(), 0.6));
	}
}

void TravFootPlace::_onto(CharacterBody3D *bd, Skeleton3D *sk, const Transform3D &xf, double feet_y, Vector3 out[2]) {
	out[0] = ZERO;
	out[1] = ZERO;
	Vector3 side = bd->get_global_transform().basis.get_column(0);
	side = V(D(side.x), 0.0, D(side.z)).normalized();
	Vector3 fwd = -bd->get_global_transform().basis.get_column(2);
	fwd = V(D(fwd.x), 0.0, D(fwd.z)).normalized();
	Vector3 centre = bd->get_global_position();
	Vector3 mid[2];
	bool any = false;
	for (int f = 0; f < 2; f++) {
		Vector3 ankle = xf.xform(sk->get_bone_global_pose(_foot[f]).origin);
		Vector3 ball = xf.xform(sk->get_bone_global_pose(_toe[f]).origin);
		mid[f] = mul(ankle + ball, 0.5) + _corr[f];
		if (stand_wide != 0.0) {
			Vector3 sk_side = xf.basis.get_column(0).normalized();
			mid[f] = mid[f] + mul(sk_side, signf(D((ankle - xf.xform(sk->get_bone_global_pose(_hips).origin)).dot(sk_side))) * stand_wide);
		}
		double lat = D((mid[f] - centre).dot(side));
		Vector3 o = mul(side, lat != 0.0 ? signf(lat) : 1.0);
		Vector3 outer = mid[f] + mul(o, SHOE_EDGE);
		if (!_ground(bd, outer, feet_y).is_empty()) {
			continue;
		}
		double s = 0.01;
		bool found = false;
		while (s <= absf(lat) + 0.15 + SHOE_EDGE) {
			if (!_ground(bd, outer - mul(o, s), feet_y).is_empty()) {
				found = true;
				break;
			}
			s += 0.01;
		}
		if (!found) {
			continue;
		}
		double run = 0.0;
		while (run < 2.0 * SHOE_EDGE && !_ground(bd, outer - mul(o, s + run + 0.01), feet_y).is_empty()) {
			run += 0.01;
		}
		out[f] = mul(-o, run >= 2.0 * SHOE_EDGE ? (s + 0.01) : (s + run * 0.5 - SHOE_EDGE));
		any = true;
	}
	if (any) {
		Vector3 a = mid[0] + out[0];
		Vector3 b = mid[1] + out[1];
		double apart = absf(D((a - b).dot(side)));
		double along = D((a - b).dot(fwd));
		double short_ = SHOE_LONG - absf(along);
		if (apart < 2.0 * SHOE_HALF && short_ > 0.0) {
			Vector3 push = mul(fwd, (along >= 0.0 ? 1.0 : -1.0) * short_ * 0.5 * (1.0 - apart / (2.0 * SHOE_HALF)));
			if (!_ground(bd, a + push, feet_y).is_empty() && !_ground(bd, b - push, feet_y).is_empty()) {
				out[0] = out[0] + push;
				out[1] = out[1] - push;
			}
		}
	}
}
