// See trav_detector.h. Translated from traversal_lab/traversal/detect/detector.gd, in the script's order.
#include "trav_detector.h"
#include "trav_probe.h"

#include "trav_math.h"

#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/typed_array.hpp>

using namespace godot;
using namespace trav;

static const Vector3 UP(0, 1, 0);
static const Vector3 DOWN(0, -1, 0);
static const Vector3 ZERO(0, 0, 0);
static const Vector3 OFF(0.001, 0.0, 0.001);
static const double FWD_HEIGHTS[4] = { 0.06, 0.5, 1.0, 1.5 };

static inline double D(real_t x) { return (double)x; }
static inline Vector3 V(double x, double y, double z) { return Vector3((real_t)x, (real_t)y, (real_t)z); }
static inline Vector3 mul(const Vector3 &v, double s) { return v * (real_t)s; }

TravDetector::TravDetector() {
	_shape.instantiate();
	_capsule.instantiate();
}

void TravDetector::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_body", "body"), &TravDetector::set_body);
	ClassDB::bind_method(D_METHOD("get_body"), &TravDetector::get_body);
	ClassDB::bind_method(D_METHOD("set_queries", "queries"), &TravDetector::set_queries);
	ClassDB::bind_method(D_METHOD("get_queries"), &TravDetector::get_queries);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "body", PROPERTY_HINT_NODE_TYPE, "CharacterBody3D", PROPERTY_USAGE_NONE), "set_body", "get_body");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "queries", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "set_queries", "get_queries");
	ClassDB::bind_method(D_METHOD("_fits", "feet", "tall"), &TravDetector::_fits);
	ClassDB::bind_method(D_METHOD("measure", "dir", "from_y", "gap_most"), &TravDetector::measure, DEFVAL((double)INFINITY), DEFVAL(GAP_MOST));
	ClassDB::bind_method(D_METHOD("measure_edge", "dir", "gap_most", "step", "far_down"), &TravDetector::measure_edge, DEFVAL(GAP_MOST), DEFVAL(STEP_DOWN), DEFVAL(STEP_DOWN));
}

Ref<PhysicsShapeQueryParameters3D> TravDetector::_q(double r, const Vector3 &at, const Vector3 &motion) {
	_shape->set_radius(r);
	Ref<PhysicsShapeQueryParameters3D> q;
	q.instantiate();
	q->set_shape(_shape);
	TypedArray<RID> ex;
	ex.push_back(body->get_rid());
	q->set_exclude(ex);
	q->set_collision_mask(trav::probe_mask(body));
	q->set_transform(Transform3D(Basis(), at));
	q->set_motion(motion);
	queries += 1;
	return q;
}

double TravDetector::_sweep(const Vector3 &at, const Vector3 &motion, double r) {
	if (D(motion.length()) < 0.0005) {
		return -1.0;
	}
	PackedFloat32Array f = _space->cast_motion(_q(r, at, motion));
	if (f.is_empty() || D(f[1]) >= 1.0) {
		return -1.0;
	}
	return D(motion.length()) * D(f[1]);
}

double TravDetector::_down(const Vector3 &at, double reach) {
	double d = _sweep(at, mul(DOWN, reach));
	return d < 0.0 ? (double)NAN : D(at.y) - d - R;
}

double TravDetector::_step_down(const Vector3 &from, const Vector3 &to, double reach) {
	if (_sweep(from, to - from) >= 0.0) {
		return INFINITY;
	}
	return _down(to, reach);
}

bool TravDetector::_fits(const Vector3 &feet, double tall) {
	_space = TRAV_SPACE(body);
	if (!_space) {
		return false;
	}
	double fl = (double)body->get("FLOAT");
	_capsule->set_radius((double)body->get("RADIUS") - 0.03);
	_capsule->set_height(maxf(tall - fl - 0.03, 2.0 * D(_capsule->get_radius())));
	Ref<PhysicsShapeQueryParameters3D> q;
	q.instantiate();
	q->set_shape(_capsule);
	TypedArray<RID> ex;
	ex.push_back(body->get_rid());
	q->set_exclude(ex);
	q->set_collision_mask(trav::probe_mask(body));
	q->set_transform(Transform3D(Basis(), feet + mul(UP, fl + (tall - fl) * 0.5)));
	queries += 1;
	return _space->intersect_shape(q, 1).is_empty();
}

Dictionary TravDetector::measure(Vector3 dir, double from_y, double gap_most) {
	queries = 0;
	_space = TRAV_SPACE(body);
	if (!_space) {
		Dictionary none;
		none["kind"] = "none";
		return none;
	}
	dir = V(D(dir.x), 0.0, D(dir.z));
	if (D(dir.length()) < 0.001) {
		Dictionary none;
		none["kind"] = "none";
		return none;
	}
	dir = dir.normalized();
	Vector3 feet = body->get_global_position();
	Vector3 col = feet + OFF;
	double ground = (int)(int64_t)body->get("state") == 0 ? (double)body->get("_stood_y") : D(feet.y);
	if (absf(ground - D(feet.y)) > STEP_DOWN) {
		ground = D(feet.y);
	}
	if (from_y != (double)INFINITY) {
		feet.y = (real_t)from_y;
		col = feet + OFF;
		ground = from_y;
	}
	Dictionary rec = _wall(col, ground, dir);
	if (rec.is_empty()) {
		rec = _edge(col, ground, dir, gap_most);
	}
	if (rec.is_empty()) {
		rec = Dictionary();
		rec["kind"] = "none";
	}
	rec["queries"] = queries;
	return rec;
}

Dictionary TravDetector::measure_edge(Vector3 dir, double gap_most, double step, double far_down) {
	_space = TRAV_SPACE(body);
	if (!_space) {
		return Dictionary();
	}
	dir = V(D(dir.x), 0.0, D(dir.z));
	if (D(dir.length()) < 0.001) {
		return Dictionary();
	}
	dir = dir.normalized();
	Vector3 feet = body->get_global_position();
	double ground = (int)(int64_t)body->get("state") == 0 ? (double)body->get("_stood_y") : D(feet.y);
	if (absf(ground - D(feet.y)) > STEP_DOWN) {
		ground = D(feet.y);
	}
	return _edge(feet + OFF, ground, dir, gap_most, step, far_down);
}

Dictionary TravDetector::_wall(const Vector3 &col, double ground, const Vector3 &dir) {
	double best = INFINITY;
	Vector3 n = ZERO;
	double h0 = 0.0;
	for (int k = 0; k < 4; k++) {
		double h = FWD_HEIGHTS[k];
		Vector3 from = col + mul(UP, h);
		double d = _sweep(from, mul(dir, REACH), R_FWD);
		if (d < 0.0 || d >= best) {
			continue;
		}
		Ref<PhysicsShapeQueryParameters3D> q = _q(R_FWD, from + mul(dir, d), ZERO);
		q->set_margin(0.02);
		Dictionary info = _space->get_rest_info(q);
		if (info.is_empty()) {
			continue;
		}
		Vector3 normal = info["normal"];
		if (D(normal.y) > std::cos(deg_to_rad(WALK_SLOPE_DEG))) {
			continue;
		}
		Vector3 flat = V(D(normal.x), 0.0, D(normal.z));
		if (D(flat.length()) < 0.2) {
			continue;
		}
		best = d;
		n = flat.normalized();
		h0 = h;
	}
	if (best == (double)INFINITY || D(n.dot(dir)) > -0.2) {
		return Dictionary();
	}
	Vector3 fwd = -n;
	double face = D(mul(dir, best).dot(fwd)) + R_FWD;
	if (face > REACH) {
		return Dictionary();
	}
	Vector3 up_from = col + mul(UP, 1.0);
	double ceil_d = _sweep(up_from, mul(UP, LOOK_UP - 1.0), R_FWD);
	double cap = ceil_d < 0.0 ? LOOK_UP : 1.0 + ceil_d - 0.02;
	double solid = h0;
	double free = -1.0;
	double h = h0;
	while (h < cap) {
		h = minf(h + 0.25, cap);
		double d = _sweep(col + mul(UP, h), mul(fwd, face + 0.08));
		if (d < 0.0) {
			free = h;
			break;
		}
		solid = h;
	}
	Dictionary rec;
	rec["kind"] = "obstacle";
	rec["normal"] = n;
	rec["face"] = face;
	rec["from"] = col;
	rec["ground"] = ground;
	rec["ceiling"] = ceil_d >= 0.0 ? cap : (double)INFINITY;
	if (free < 0.0) {
		rec["top"] = (double)INFINITY;
		rec["blocked"] = ceil_d >= 0.0;
		rec["too_high"] = ceil_d < 0.0;
		rec["edge"] = col + mul(fwd, face) + mul(UP, cap);
		return rec;
	}
	for (int i = 0; i < 5; i++) {
		double mid = (solid + free) * 0.5;
		if (_sweep(col + mul(UP, mid), mul(fwd, face + 0.08)) < 0.0) {
			free = mid;
		} else {
			solid = mid;
		}
	}
	Vector3 over = col + mul(UP, free) + mul(fwd, face + 0.06);
	double top_y = _down(over, free + 0.2);
	if (std::isnan(top_y)) {
		top_y = ground + free - R;
	}
	double top = top_y - ground;
	if (top < 0.03) {
		return Dictionary();
	}
	rec["top"] = top;
	rec["too_high"] = top > CLIMB_MOST;
	Vector3 edge = V(D(col.x), top_y, D(col.z)) + mul(fwd, face);
	rec["edge"] = edge;
	double clear_d = _sweep(over, mul(UP, 2.2));
	double clear = (clear_d < 0.0 ? 2.2 : clear_d + R) + (D(over.y) - top_y);
	rec["clear"] = clear;
	double crouch_tall = (double)body->get("CROUCH_HEIGHT");
	double tall = (double)body->get("HEIGHT");
	rec["blocked"] = clear < crouch_tall;
	double ride = top_y + minf(0.15, clear * 0.5);
	Vector3 start = V(D(over.x), ride, D(over.z));
	if (_sweep(over, start - over) >= 0.0) {
		start = over;
	}
	Dictionary d_res = _follow(start, fwd, top_y, DEPTH_MOST, 0.25);
	double depth = (double)d_res["len"] + 0.06;
	rec["depth"] = depth;
	rec["depth_open"] = (bool)d_res["open"];
	rec["backed"] = (bool)d_res["shut"];
	rec["thin"] = depth < THIN_UNDER;
	rec["far_edge"] = edge + mul(fwd, depth);
	double rad = (double)body->get("RADIUS");
	Vector3 on_top = V(D(col.x), top_y, D(col.z)) + mul(fwd, face + rad + 0.05);
	rec["stand_at"] = on_top;
	rec["stand_room"] = depth >= THIN_UNDER && _fits(on_top, tall);
	rec["crouch_room"] = depth >= THIN_UNDER && ((bool)rec["stand_room"] || _fits(on_top, crouch_tall));
	if (!(bool)d_res["open"] && !(bool)d_res["shut"]) {
		Vector3 end = d_res["end"];
		Vector3 beyond = end + mul(fwd, rad + 0.10);
		double ly = _step_down(end, beyond, (ride - ground) + DROP_MOST);
		if (ly != (double)INFINITY && !std::isnan(ly)) {
			rec["landing"] = ly - ground;
			rec["land_at"] = V(D(beyond.x), ly, D(beyond.z));
			rec["landing_ok"] = _fits(V(D(beyond.x), ly, D(beyond.z)), tall);
		}
	}
	Vector3 side = fwd.cross(UP).normalized();
	Vector3 w_from = start + mul(fwd, minf(0.04, depth * 0.3));
	Dictionary right = _follow(w_from, side, top_y, WIDTH_MOST, 0.2);
	Dictionary left = _follow(w_from, -side, top_y, WIDTH_MOST, 0.2);
	rec["width"] = (double)right["len"] + (double)left["len"];
	rec["width_right"] = (double)right["len"];
	rec["width_left"] = (double)left["len"];
	rec["width_open"] = (bool)right["open"] && (bool)left["open"];
	return rec;
}

static Dictionary follow_rec(double len, bool open, bool shut, const Vector3 &end) {
	Dictionary d;
	d["len"] = len;
	d["open"] = open;
	d["shut"] = shut;
	d["end"] = end;
	return d;
}

Dictionary TravDetector::_follow(const Vector3 &start, const Vector3 &way, double top_y, double most, double step) {
	double reach = (D(start.y) - top_y) + 0.12;
	double good = 0.0;
	Vector3 at = start;
	double s = 0.0;
	while (s < most) {
		double next_s = minf(s + step, most);
		double y = _step_down(at, start + mul(way, next_s), reach);
		if (y == (double)INFINITY) {
			double d = _sweep(at, start + mul(way, next_s) - at);
			return follow_rec(s + maxf(d, 0.0) + R, false, true, at + mul(way, maxf(d, 0.0)));
		}
		if (std::isnan(y) || absf(y - top_y) > SAME_TOP) {
			double lo = good;
			double hi = next_s;
			for (int i = 0; i < 6; i++) {
				double mid = (lo + hi) * 0.5;
				double ym = _step_down(start + mul(way, lo), start + mul(way, mid), reach);
				if (ym == (double)INFINITY || std::isnan(ym) || absf(ym - top_y) > SAME_TOP) {
					hi = mid;
				} else {
					lo = mid;
				}
			}
			return follow_rec(lo, false, false, start + mul(way, hi));
		}
		good = next_s;
		at = start + mul(way, next_s);
		s = next_s;
	}
	return follow_rec(most, true, false, at);
}

double TravDetector::_ground_end(const Vector3 &from, const Vector3 &way, double ground, double most, double first, double step) {
	double reach = (D(from.y) - ground) + step + 0.02;
	double good = 0.0;
	double s = first;
	Vector3 at = from;
	while (true) {
		double y = _step_down(at, from + mul(way, s), reach);
		if (y == (double)INFINITY) {
			return -2.0;
		}
		if (std::isnan(y)) {
			double lo = good;
			double hi = s;
			for (int i = 0; i < 6; i++) {
				double mid = (lo + hi) * 0.5;
				double ym = _step_down(from + mul(way, lo), from + mul(way, mid), reach);
				if (ym == (double)INFINITY || std::isnan(ym)) {
					hi = mid;
				} else {
					lo = mid;
				}
			}
			return lo;
		}
		good = s;
		at = from + mul(way, s);
		if (s >= most) {
			return -1.0;
		}
		s = minf(s + 0.1, most);
	}
	return -1.0;
}

Dictionary TravDetector::_edge(const Vector3 &col, double ground, const Vector3 &dir, double gap_most, double step, double far_down) {
	Vector3 from = col + mul(UP, 0.4);
	double end = _ground_end(from, dir, ground, REACH, 0.1, step);
	if (end < 0.0) {
		return Dictionary();
	}
	Vector3 side = dir.cross(UP).normalized();
	Vector3 m = dir;
	double a = INFINITY;
	double b = INFINITY;
	if (_sweep(from, mul(side, 0.2)) < 0.0 && _sweep(from, mul(-side, 0.2)) < 0.0) {
		a = _ground_end(from + mul(side, 0.2), dir, ground, REACH + 0.5, 0.1, step);
		b = _ground_end(from - mul(side, 0.2), dir, ground, REACH + 0.5, 0.1, step);
	}
	if (a != (double)INFINITY && a >= 0.0 && b >= 0.0) {
		Vector3 along = ((from + mul(side, 0.2) + mul(dir, a)) - (from - mul(side, 0.2) + mul(dir, b))).normalized();
		m = along.cross(UP).normalized();
		if (D(m.dot(dir)) < 0.0) {
			m = -m;
		}
	}
	Vector3 edge = V(D(col.x), ground, D(col.z)) + mul(dir, end);
	Dictionary rec;
	rec["kind"] = "drop";
	rec["normal"] = -m;
	rec["edge"] = edge;
	rec["face"] = D(mul(dir, end).dot(m));
	rec["from"] = col;
	rec["ground"] = ground;
	rec["top"] = 0.0;
	Vector3 out = from + mul(dir, end) + mul(m, 0.12);
	if (_sweep(from, out - from) >= 0.0) {
		return rec;
	}
	double by = _down(out, 0.4 + DROP_MOST);
	rec["drop"] = std::isnan(by) ? (double)INFINITY : ground - by;
	double reach = 0.4 + far_down + 0.02;
	double s = 0.1;
	Vector3 at = out;
	double last_open = 0.0;
	while (s <= gap_most) {
		double y = _step_down(at, out + mul(m, s), reach);
		if (y == (double)INFINITY) {
			double d = _sweep(at, out + mul(m, s) - at);
			rec["kind"] = "gap";
			rec["gap"] = 0.12 + (s > 0.1 ? s - 0.1 : 0.0) + maxf(d, 0.0) + R;
			rec["far_wall"] = true;
			break;
		}
		if (!std::isnan(y)) {
			double lo = last_open;
			double hi = s;
			for (int i = 0; i < 6; i++) {
				double mid = (lo + hi) * 0.5;
				double ym = _step_down(out + mul(m, lo), out + mul(m, mid), reach);
				if (ym == (double)INFINITY || std::isnan(ym)) {
					lo = mid;
				} else {
					hi = mid;
				}
			}
			rec["kind"] = "gap";
			rec["gap"] = 0.12 + hi;
			rec["far_wall"] = false;
			rec["landing"] = y - ground;
			double rad = (double)body->get("RADIUS");
			Vector3 land = edge + mul(m, 0.12 + hi + rad + 0.10);
			land.y = (real_t)y;
			rec["land_at"] = land;
			rec["landing_ok"] = _fits(land, (double)body->get("HEIGHT"));
			rec["far_edge"] = V(D(edge.x), y, D(edge.z)) + mul(m, 0.12 + hi);
			break;
		}
		last_open = s;
		at = out + mul(m, s);
		s += 0.1;
	}
	if ((String)rec["kind"] == String("drop") && rec.has("drop") && (double)rec["drop"] != (double)INFINITY) {
		Vector3 land = edge + mul(m, (double)body->get("RADIUS") + 0.10);
		land.y = (real_t)(ground - (double)rec["drop"]);
		rec["land_at"] = land;
		rec["landing"] = -(double)rec["drop"];
		rec["landing_ok"] = _fits(land, (double)body->get("HEIGHT"));
	}
	return rec;
}
