// See trav_body.h. The script this is translated from: traversal_lab/traversal/body/body.gd. The functions are in
// the script's order and each line stands where the script's line stands. Scalars are doubles and every part of a
// Vector3 is widened to a double before it is used in arithmetic, as GDScript does (trav_math.h).
#include "trav_body.h"
#include "trav_probe.h"

#include "trav_math.h"

#include <godot_cpp/classes/box_mesh.hpp>
#include <godot_cpp/classes/capsule_mesh.hpp>
#include <godot_cpp/classes/cylinder_mesh.hpp>
#include <godot_cpp/classes/cylinder_shape3d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/kinematic_collision3d.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/physics_shape_query_parameters3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/templates/hash_map.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/vector2.hpp>

using namespace godot;
using namespace trav;

static const Vector3 UP(0, 1, 0);
static const Vector3 DOWN(0, -1, 0);
static const Vector3 ZERO(0, 0, 0);
static const double NARROW_SIDE[2] = { 0.115, 0.04 };
static const double LEDGE_BAND[2] = { 0.10, 0.30 };
static const double SQUEEZE_BAND[3] = { 0.25, 0.60, 0.60 };
static const double SQUEEZE_LOOK[3] = { 0.5, 1.0, 1.5 };
static const char *STATE_NAMES[4] = { "on ground", "too steep", "touching, unsupported", "in air" };

static inline double D(real_t x) { return (double)x; }
static inline Vector3 V(double x, double y, double z) { return Vector3((real_t)x, (real_t)y, (real_t)z); }
static inline Vector3 mul(const Vector3 &v, double s) { return v * (real_t)s; }
static inline Vector3 div(const Vector3 &v, double s) { return v / (real_t)s; }
static inline Vector3 limit(const Vector3 &v, double len) { return v.limit_length((real_t)len); }

// ---- reading and setting the script's variables and constants by name, as `get()` and `set()` do on the script

enum { TRAV_FIRST = 0,
#define X(n) VAR_##n,
	TRAV_BODY_VARS(X)
#undef X
#define X(n, v) CONST_##n,
			TRAV_BODY_CONSTS(X)
#undef X
};

static HashMap<StringName, int> &names() {
	static HashMap<StringName, int> map;
	if (map.is_empty()) {
#define X(n) map[StringName(#n)] = VAR_##n;
		TRAV_BODY_VARS(X)
#undef X
#define X(n, v) map[StringName(#n)] = CONST_##n;
		TRAV_BODY_CONSTS(X)
#undef X
	}
	return map;
}

static inline void take(double &d, const Variant &v) { d = (double)v; }
static inline void take(bool &d, const Variant &v) { d = (bool)v; }
static inline void take(int &d, const Variant &v) { d = (int)(int64_t)v; }
static inline void take(Vector3 &d, const Variant &v) { d = (Vector3)v; }
static inline void take(String &d, const Variant &v) { d = (String)v; }
static inline void take(Array &d, const Variant &v) { d = (Array)v; }
static inline void take(Callable &d, const Variant &v) { d = (Callable)v; }
static inline void take(Dictionary &d, const Variant &v) { d = (Dictionary)v; }
static inline void take(Variant &d, const Variant &v) { d = v; }

bool TravBody::_get(const StringName &p_name, Variant &r_ret) const {
	const HashMap<StringName, int> &map = names();
	HashMap<StringName, int>::ConstIterator it = map.find(p_name);
	if (!it) {
		return false;
	}
	switch (it->value) {
#define X(n) \
	case VAR_##n: \
		r_ret = n; \
		return true;
		TRAV_BODY_VARS(X)
#undef X
#define X(n, v) \
	case CONST_##n: \
		r_ret = (double)n; \
		return true;
		TRAV_BODY_CONSTS(X)
#undef X
	}
	return false;
}

bool TravBody::_set(const StringName &p_name, const Variant &p_value) {
	const HashMap<StringName, int> &map = names();
	HashMap<StringName, int>::ConstIterator it = map.find(p_name);
	if (!it) {
		return false;
	}
	switch (it->value) {
#define X(n) \
	case VAR_##n: \
		take(n, p_value); \
		return true;
		TRAV_BODY_VARS(X)
#undef X
	}
	return false;
}

void TravBody::_bind_methods() {
	ClassDB::bind_method(D_METHOD("can_stand"), &TravBody::can_stand);
	ClassDB::bind_method(D_METHOD("show_capsule", "on"), &TravBody::show_capsule);
	ClassDB::bind_method(D_METHOD("probe", "feet", "from_up", "reach"), &TravBody::probe, DEFVAL(FLOAT + RADIUS), DEFVAL(STEP_DOWN + 0.05));
	ClassDB::bind_method(D_METHOD("begin_move", "path", "clip"), &TravBody::begin_move);
	ClassDB::bind_method(D_METHOD("start_jump"), &TravBody::start_jump);
	ClassDB::bind_method(D_METHOD("in_move"), &TravBody::in_move);
	ClassDB::bind_method(D_METHOD("stop_distance"), &TravBody::stop_distance);
	ClassDB::bind_method(D_METHOD("_ray_down", "at"), &TravBody::_ray_down);
	ClassDB::bind_method(D_METHOD("landing_ahead"), &TravBody::landing_ahead);
	ClassDB::bind_method(D_METHOD("get_readout"), &TravBody::get_readout);
	ClassDB::bind_method(D_METHOD("place", "at"), &TravBody::place);
	ClassDB::bind_method(D_METHOD("native_version"), &TravBody::native_version);
	ADD_SIGNAL(MethodInfo("jump_started", PropertyInfo(Variant::FLOAT, "push_time")));
	ADD_SIGNAL(MethodInfo("jumped"));
	ADD_SIGNAL(MethodInfo("landed", PropertyInfo(Variant::FLOAT, "drop")));
}

String TravBody::native_version() const {
	return "traversal native: the body";
}

double TravBody::_rot_y() const {
	return D(get_rotation().y);
}

void TravBody::_set_rot_y(double y) {
	Vector3 r = get_rotation();
	r.y = (real_t)y;
	set_rotation(r);
}

Dictionary TravBody::_ray(const Vector3 &from, const Vector3 &to) {
	TypedArray<RID> ex;
	ex.push_back(get_rid());
	return get_world_3d()->get_direct_space_state()->intersect_ray(PhysicsRayQueryParameters3D::create(from, to, trav::probe_mask(this), ex));
}

void TravBody::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	_probe.instantiate();
	_fit.instantiate();
	set_motion_mode(CharacterBody3D::MOTION_MODE_FLOATING);
	set_wall_min_slide_angle(0.0);
	set_max_slides(6);
	Ref<CapsuleShape3D> shape;
	shape.instantiate();
	shape->set_radius(RADIUS);
	shape->set_height(HEIGHT - FLOAT);
	CollisionShape3D *col = memnew(CollisionShape3D);
	col->set_shape(shape);
	col->set_position(V(0.0, FLOAT + (HEIGHT - FLOAT) * 0.5, 0.0));
	add_child(col);
	_col = col;
	_fit->set_radius(RADIUS - STAND_ROOM);
	_fit->set_height(HEIGHT - FLOAT - STAND_ROOM);
	Ref<CylinderShape3D> skirt_shape;
	skirt_shape.instantiate();
	skirt_shape->set_radius(RADIUS - 0.004);
	skirt_shape->set_height(RADIUS + 0.06);
	CollisionShape3D *skirt = memnew(CollisionShape3D);
	skirt->set_shape(skirt_shape);
	_skirt = skirt;
	skirt->set_position(V(0.0, FLOAT + D(skirt_shape->get_height()) * 0.5, 0.0));
	add_child(skirt);
	_probe->set_radius(PROBE_R);
	Ref<CapsuleMesh> mesh;
	mesh.instantiate();
	mesh->set_radius(RADIUS);
	mesh->set_height(HEIGHT - FLOAT);
	MeshInstance3D *mi = memnew(MeshInstance3D);
	mi->set_mesh(mesh);
	mi->set_position(V(0.0, D(col->get_position().y), 0.0));
	add_child(mi);
	_look.append(mi);
	MeshInstance3D *leg = memnew(MeshInstance3D);
	Ref<CylinderMesh> lm;
	lm.instantiate();
	lm->set_top_radius(0.06);
	lm->set_bottom_radius(0.06);
	lm->set_height(FLOAT + 0.2);
	leg->set_mesh(lm);
	leg->set_position(V(0.0, (FLOAT + 0.2) * 0.5, 0.0));
	add_child(leg);
	_look.append(leg);
	MeshInstance3D *nose = memnew(MeshInstance3D);
	Ref<BoxMesh> nm;
	nm.instantiate();
	nm->set_size(V(0.08, 0.08, 0.3));
	nose->set_mesh(nm);
	nose->set_position(V(0, 1.6, -0.3));
	add_child(nose);
	_look.append(nose);
}

void TravBody::_set_crouched(bool low) {
	crouched = low;
	double top = low ? CROUCH_HEIGHT : HEIGHT;
	Ref<CapsuleShape3D> cs = _col->get_shape();
	cs->set_height(top - FLOAT);
	Vector3 p = _col->get_position();
	p.y = (real_t)(FLOAT + (top - FLOAT) * 0.5);
	_col->set_position(p);
	if (_look.size() > 0) {
		MeshInstance3D *m0 = Object::cast_to<MeshInstance3D>(_look[0]);
		Ref<CapsuleMesh> cm = m0->get_mesh();
		cm->set_height(top - FLOAT);
		Vector3 mp = m0->get_position();
		mp.y = _col->get_position().y;
		m0->set_position(mp);
	}
}

bool TravBody::can_stand() {
	Ref<PhysicsShapeQueryParameters3D> q;
	q.instantiate();
	q->set_shape(_fit);
	q->set_transform(Transform3D(Basis(), get_global_position() + mul(UP, FLOAT + (HEIGHT - FLOAT) * 0.5)));
	TypedArray<RID> ex;
	ex.push_back(get_rid());
	q->set_exclude(ex);
	q->set_collision_mask(trav::probe_mask(this));
	return get_world_3d()->get_direct_space_state()->intersect_shape(q, 1).is_empty();
}

void TravBody::show_capsule(bool on) {
	for (int i = 0; i < _look.size(); i++) {
		Object::cast_to<Node3D>(_look[i])->set_visible(on);
	}
}

Dictionary TravBody::probe(const Vector3 &feet, double from_up, double reach) {
	PhysicsDirectSpaceState3D *space = get_world_3d()->get_direct_space_state();
	Ref<PhysicsShapeQueryParameters3D> q;
	q.instantiate();
	q->set_shape(_probe);
	TypedArray<RID> ex;
	ex.push_back(get_rid());
	q->set_exclude(ex);
	q->set_collision_mask(trav::probe_mask(this));
	Vector3 start = feet + mul(UP, from_up);
	double length = from_up - PROBE_R + reach;
	q->set_transform(Transform3D(Basis(), start));
	q->set_motion(mul(DOWN, length));
	PackedFloat32Array f = space->cast_motion(q);
	Dictionary out;
	if (f.is_empty() || D(f[1]) >= 1.0) {
		out["hit"] = false;
		return out;
	}
	double y = D(start.y) - length * D(f[0]) - PROBE_R;
	q->set_transform(Transform3D(Basis(), start + mul(mul(DOWN, length), D(f[1]))));
	q->set_motion(ZERO);
	q->set_margin(0.02);
	Dictionary r = space->get_rest_info(q);
	Vector3 n = r.get("normal", UP);
	if (r.has("point")) {
		y = D(((Vector3)r["point"]).y) + PROBE_R * (D(n.y) - 1.0);
	}
	out["hit"] = true;
	out["y"] = y;
	out["normal"] = n;
	out["point"] = r.get("point", V(D(feet.x), y, D(feet.z)));
	return out;
}

bool TravBody::_is_steep(const Dictionary &g) {
	Vector3 n = g["normal"];
	double angle = std::acos(clampf(D(n.y), -1.0, 1.0));
	if (angle <= deg_to_rad(SLOPE_LIMIT_DEG)) {
		return false;
	}
	Vector3 down = V(D(n.x), 0.0, D(n.z));
	if (D(down.length()) < 0.001) {
		return false;
	}
	Vector3 gp = get_global_position();
	Dictionary under = _ray_down(V(D(gp.x), (double)g["y"], D(gp.z)));
	if (!under.is_empty()) {
		return std::acos(clampf(D(((Vector3)under["normal"]).y), -1.0, 1.0)) > deg_to_rad(SLOPE_LIMIT_DEG);
	}
	down = down.normalized();
	double rise = std::tan(angle) * 0.2;
	Vector3 feet = V(D(gp.x), (double)g["y"], D(gp.z));
	Dictionary lo = probe(feet + mul(down, 0.2), FLOAT + RADIUS + rise, STEP_DOWN + rise + 0.1);
	Dictionary hi = probe(feet - mul(down, 0.2), FLOAT + RADIUS + rise, STEP_DOWN + rise + 0.1);
	if (!(bool)lo["hit"] || !(bool)hi["hit"]) {
		return false;
	}
	return absf((double)lo["y"] - (D(feet.y) - rise)) < 0.05 && absf((double)hi["y"] - (D(feet.y) + rise)) < 0.05;
}

void TravBody::begin_move(const Callable &path, const String &clip) {
	move_path = path;
	move_clip = clip;
	move_t = 0.0;
	move_landed = false;
	land_hold = 0.0;
	jump_timer = 0.0;
	spot_total = 0.0;
}

bool TravBody::start_jump() {
	if (state != GROUND || jump_timer > 0.0 || crouched || move_path.is_valid()) {
		return false;
	}
	_jump_still = D(hvel.length()) < 2.0;
	jump_timer = _jump_still ? (JUMP_DIP_STAND + JUMP_PUSH_STAND) : JUMP_PUSH_RUN;
	emit_signal("jump_started", jump_timer);
	return true;
}

double TravBody::_gap_at(const Vector3 &at, const Vector3 &across) {
	double least = INFINITY;
	for (int k = 0; k < 3; k++) {
		double h = SQUEEZE_LOOK[k];
		Vector3 from = at + V(0.0, h, 0.0);
		Dictionary a = _ray(from, from + mul(across, 0.5));
		Dictionary b = _ray(from, from - mul(across, 0.5));
		if (a.is_empty() || b.is_empty()) {
			continue;
		}
		Vector3 n = a["normal"];
		n = V(D(n.x), 0.0, D(n.z));
		if (D(n.length()) < 0.5) {
			continue;
		}
		n = n.normalized();
		Dictionary a2 = _ray(from, from - mul(n, 0.6));
		Dictionary b2 = _ray(from, from + mul(n, 0.6));
		if (a2.is_empty() || b2.is_empty()) {
			continue;
		}
		double wide = D(from.distance_to((Vector3)a2["position"])) + D(from.distance_to((Vector3)b2["position"]));
		if (wide < least) {
			least = wide;
			_gap_mid = mul((Vector3)a2["position"] + (Vector3)b2["position"], 0.5);
			_gap_n = n;
		}
	}
	return least;
}

Dictionary TravBody::_ledge_at(const Vector3 &at, const Vector3 &across) {
	Vector3 from = at + V(0.0, 1.0, 0.0);
	Dictionary a = _ray(from, from + mul(across, 0.6));
	Dictionary b = _ray(from, from - mul(across, 0.6));
	if (a.is_empty() == b.is_empty()) {
		return Dictionary();
	}
	Dictionary hit = a.is_empty() ? b : a;
	Vector3 n = hit["normal"];
	n = V(D(n.x), 0.0, D(n.z));
	if (D(n.length()) < 0.5) {
		return Dictionary();
	}
	n = n.normalized();
	Vector3 hp = hit["position"];
	Vector3 foot = V(D(hp.x), D(at.y), D(hp.z));
	double wide = 0.0;
	double s = 0.01;
	while (s < 0.40) {
		Vector3 p = foot + mul(n, s);
		Dictionary g = _ray(p + V(0.0, 0.3, 0.0), p - V(0.0, 0.3, 0.0));
		if (g.is_empty() || absf(D(((Vector3)g["position"]).y) - D(at.y)) > 0.10) {
			break;
		}
		wide = s;
		s += 0.01;
	}
	Dictionary out;
	out["wide"] = s < 0.40 ? wide + 0.005 : (double)INFINITY;
	out["wall"] = foot;
	out["out"] = n;
	return out;
}

void TravBody::_find_squeeze() {
	PhysicsDirectSpaceState3D *space = get_world_3d()->get_direct_space_state();
	Vector3 gp = get_global_position();
	Vector3 fwd = -get_global_transform().basis.get_column(2);
	fwd = V(D(fwd.x), 0.0, D(fwd.z)).normalized();
	if (D(_wish.length()) > 0.05 && state == GROUND) {
		fwd = _wish.normalized();
	}
	Vector3 across = fwd.cross(UP).normalized();
	double w = _gap_at(gp, across);
	Vector3 mid = _gap_mid;
	Vector3 mid_n = _gap_n;
	if (D(_wish.length()) > 0.05 && state == GROUND) {
		const double ahead[2] = { SQUEEZE_AHEAD * 0.5, SQUEEZE_AHEAD };
		for (int k = 0; k < 2; k++) {
			double d = ahead[k];
			Vector3 from = gp + V(0.0, 1.0, 0.0);
			if (!_ray(from, from + mul(fwd, d)).is_empty()) {
				break;
			}
			double wd = _gap_at(gp + mul(fwd, d), across);
			if (wd < w) {
				w = wd;
				mid = _gap_mid;
				mid_n = _gap_n;
			}
		}
		double far = D(hvel.length()) > WALK + 0.1 ? D(hvel.length()) * SQUEEZE_SLOW_TIME : 0.0;
		double d2 = SQUEEZE_AHEAD + 0.25;
		while (d2 <= far && w >= SQUEEZE_BAND[1] - SQUEEZE_SEEN) {
			Vector3 from2 = gp + V(0.0, 1.0, 0.0);
			if (!_ray(from2, from2 + mul(fwd, d2)).is_empty()) {
				break;
			}
			double wf = _gap_at(gp + mul(fwd, d2), across);
			if (wf < SQUEEZE_BAND[1] - SQUEEZE_SEEN && wf >= SQUEEZE_BAND[0] - SQUEEZE_SEEN) {
				w = wf;
				mid = _gap_mid;
				mid_n = _gap_n;
			}
			d2 += 0.25;
		}
	}
	int kind = 0;
	if (w >= SQUEEZE_BAND[0] - SQUEEZE_SEEN && w < SQUEEZE_BAND[2] - SQUEEZE_SEEN) {
		kind = w < SQUEEZE_BAND[1] - SQUEEZE_SEEN ? 2 : 1;
	}
	double want_r = kind > 0 ? minf(RADIUS, w * 0.5 - SQUEEZE_PLAY) : RADIUS;
	if (kind == 0 && state == GROUND) {
		Dictionary led = _ledge_at(gp, across);
		if (D(_wish.length()) > 0.05) {
			const double ahead[2] = { SQUEEZE_AHEAD * 0.5, SQUEEZE_AHEAD };
			for (int k = 0; k < 2; k++) {
				Dictionary l2 = _ledge_at(gp + mul(fwd, ahead[k]), across);
				if (!l2.is_empty() && (led.is_empty() || (double)l2["wide"] < (double)led["wide"])) {
					led = l2;
				}
			}
		}
		if (!led.is_empty() && (double)led["wide"] >= LEDGE_BAND[0] - SQUEEZE_SEEN && (double)led["wide"] < LEDGE_BAND[1]) {
			kind = 3;
			w = (double)led["wide"];
			want_r = w * 0.5 - 0.01;
			ledge_wall = led["wall"];
			ledge_out = led["out"];
			mid = (Vector3)led["wall"] + mul((Vector3)led["out"], w * 0.5);
			mid_n = led["out"];
		}
	}
	if (kind == 0 && squeeze == 3 && radius < RADIUS) {
		Dictionary lw = _ledge_at(gp, across);
		if (!lw.is_empty()) {
			double off_wall = D((gp - (Vector3)lw["wall"]).dot((Vector3)lw["out"]));
			if (off_wall < RADIUS + 0.01) {
				_set_radius(clampf(off_wall - 0.01, radius, RADIUS));
				_wish += mul((Vector3)lw["out"], 0.6);
				return;
			}
		}
	}
	if (want_r > radius) {
		Ref<PhysicsShapeQueryParameters3D> q;
		q.instantiate();
		Ref<CapsuleShape3D> trial;
		trial.instantiate();
		trial->set_radius(want_r - 0.005);
		Ref<CapsuleShape3D> cs = _col->get_shape();
		trial->set_height(cs->get_height());
		q->set_shape(trial);
		q->set_transform(Transform3D(Basis(), gp + mul(UP, D(_col->get_position().y))));
		TypedArray<RID> ex;
		ex.push_back(get_rid());
		q->set_exclude(ex);
		q->set_collision_mask(trav::probe_mask(this));
		if (!space->intersect_shape(q, 1).is_empty()) {
			return;
		}
	}
	if (kind == 3) {
		Vector3 facing = -get_global_transform().basis.get_column(2);
		squeeze_side = D(mid_n.dot(V(D(facing.x), 0.0, D(facing.z)).cross(UP))) > 0.0 ? -1 : 1;
		double side_off = D((mid - gp).dot(mid_n));
		_wish = limit(_wish, SQUEEZE_SPEED * clampf(1.0 - (absf(side_off) - 0.03) / 0.25, 0.25, 1.0));
		_wish += mul(mid_n, clampf(side_off * LEDGE_PULL, -0.6, 0.6));
	} else if (kind > 0 && squeeze == 0) {
		double off = D((gp - mid).dot(across));
		squeeze_side = off < -0.01 ? -1 : 1;
	}
	squeeze = kind;
	squeeze_w = w;
	squeeze_mid = mid;
	squeeze_across = mid_n;
	if (!is_equal_approx(want_r, radius)) {
		_set_radius(want_r);
	}
}

void TravBody::_set_radius(double r) {
	radius = r;
	Ref<CapsuleShape3D> cs = _col->get_shape();
	cs->set_radius(r);
	Ref<CylinderShape3D> ss = _skirt->get_shape();
	ss->set_radius(r - 0.004);
	if (_look.size() > 0) {
		Ref<CapsuleMesh> cm = Object::cast_to<MeshInstance3D>(_look[0])->get_mesh();
		cm->set_radius(r);
	}
}

int TravBody::_narrow_now() {
	if (state != GROUND) {
		return 0;
	}
	Vector3 gp = get_global_position();
	Vector3 side = get_global_transform().basis.get_column(0);
	side = V(D(side.x), 0.0, D(side.z)).normalized();
	int out = 0;
	for (int k = 0; k < 2; k++) {
		double reach = NARROW_SIDE[k] + (narrow > k ? NARROW_STAY : 0.0);
		const double ways[2] = { 1.0, -1.0 };
		for (int j = 0; j < 2; j++) {
			Dictionary hit = _ray_down(gp + mul(side, ways[j] * reach));
			if (!hit.is_empty() && D(((Vector3)hit["position"]).y) > D(gp.y) - STEP_HEIGHT_FOR_NARROW) {
				return out;
			}
		}
		out = k + 1;
	}
	return out;
}

bool TravBody::in_move() const {
	return move_path.is_valid();
}

void TravBody::_run_move(double dt) {
	move_t += dt;
	Dictionary r = move_path.call(move_t);
	Vector3 was = get_global_position();
	set_global_position((Vector3)r["pos"]);
	_set_rot_y((double)r["yaw"]);
	if (r.has("clip")) {
		move_clip = (String)r["clip"];
	}
	move_clip_t = (double)r["clip_t"];
	move_landed = (bool)r.get("landed", false);
	move_soft = (double)r.get("soft", 0.0);
	move_step = r.get("step", Array());
	move_base = (double)r.get("base", 0.0);
	move_hand = r.get("hand", Array());
	move_free = (bool)r.get("free", false);
	move_landing = (String)r.get("landing", "soft");
	state = (bool)r["air"] ? AIR : GROUND;
	Vector3 step = get_global_position() - was;
	hvel = div(V(D(step.x), 0.0, D(step.z)), dt);
	vy = 0.0;
	set_velocity(ZERO);
	ground_y = D(get_global_position().y);
	ground_normal = UP;
	air_time = 0.0;
	from_jump = false;
	_air_peak = D(get_global_position().y);
	if ((bool)r["done"]) {
		hvel = r["exit"];
		state = GROUND;
		_stood_y = D(get_global_position().y);
		_wish_was_moving = false;
		move_path = Callable();
		move_step = Array();
		move_hand = Array();
		move_base = 0.0;
	}
}

void TravBody::_physics_process(double dt) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	Dictionary s;
	Object *tape_o = tape;
	if (tape_o) {
		s = tape_o->call("sample");
	}
	last_sample = s;
	bool act = (bool)s.get("act", false);
	act_now = act && !act_held;
	act_held = act;
	bool text = (bool)s.get("text", false);
	bool call = (bool)s.get("call", false);
	if (text && !_text_was) {
		phone = phone == 1 ? 0 : 1;
	}
	if (call && !_call_was) {
		phone = phone == 2 ? 0 : 2;
	}
	_text_was = text;
	_call_was = call;
	double mx = (double)s.get("mx", 0.0);
	double mz = (double)s.get("mz", 0.0);
	double yaw = (double)s.get("yaw", 0.0);
	stick_dir = V(mx, 0.0, mz).rotated(UP, (real_t)yaw).limit_length(1.0);
	if (move_path.is_valid()) {
		stick_held = D(Vector2((real_t)mx, (real_t)mz).length()) > 0.2;
		_run_move(dt);
		return;
	}
	Vector3 stick = V(mx, 0.0, mz);
	if (D(stick.length()) > 1.0) {
		stick = stick.normalized();
	}
	bool want_low = (bool)s.get("crouch", false);
	narrow = _narrow_now();
	if (want_low && !crouched && state == GROUND && jump_timer <= 0.0 && narrow == 0) {
		_set_crouched(true);
	} else if (crouched && (!want_low || narrow > 0) && can_stand()) {
		_set_crouched(false);
	}
	run_asked = (bool)s.get("run", false);
	stick_held = D(stick.length()) > 0.2;
	_wish = mul(stick.rotated(UP, (real_t)yaw), (crouched ? CROUCH_SPEED : ((bool)s.get("run", false) ? RUN : WALK)) * pace);
	if (narrow > 0 && D(_wish.length()) > (narrow == 1 ? NARROW_SPEED : NARROW_SPEED_LEAST)) {
		_wish = mul(_wish.normalized(), narrow == 1 ? NARROW_SPEED : NARROW_SPEED_LEAST);
	}
	if (squeeze >= 2 && D(_wish.length()) > 0.05 && absf(wrapf(std::atan2(-D(_wish.x), -D(_wish.z)) - _rot_y(), -PI, PI)) > PI * 0.5) {
		_set_rot_y(wrapf(_rot_y() + PI, -PI, PI));
		squeeze_side = -squeeze_side;
		spot_total = 0.0;
		hvel = ZERO;
	}
	if (auto_on) {
		Vector3 to = auto_to - get_global_position();
		to.y = 0.0;
		_wish = D(to.length()) > 0.02 ? mul(to.normalized(), minf(WALK, maxf(D(to.length()) * 4.0, 0.3))) : ZERO;
	}
	if (phone > 0) {
		_wish = limit(_wish, PHONE_SPEED);
	}
	stick_wish = _wish;
	_find_squeeze();
	if (squeeze >= 2) {
		_wish = limit(_wish, SQUEEZE_SPEED);
	}

	if (D(_wish.length()) > 0.05) {
		double wy = std::atan2(D(_wish.x), D(_wish.z));
		double step = _wish_on ? absf(wrapf(wy - _wish_yaw, -PI, PI)) / dt : 0.0;
		if (step > deg_to_rad(400.0)) {
			step = 0.0;
		}
		_wish_turn += (step - _wish_turn) * (1.0 - std::exp(-dt / CURVE_TIME));
		_wish_yaw = wy;
		_wish_on = true;
		if (_wish_turn > 0.05 && D(_wish.length()) <= WALK + 0.1) {
			_wish = limit(_wish, CURVE_PULL_WALK / _wish_turn);
		}
	} else {
		_wish_on = false;
		_wish_turn = 0.0;
	}
	if (land_hold > 0.0) {
		land_hold -= dt;
		_wish = ZERO;
	}
	_find_stairs(dt);
	if (stairs != 0 && D(_wish.length()) > 0.05) {
		_wish = limit(_wish, _stair_speed(D(_wish.length()) > WALK + 0.1));
	} else if (state == GROUND && D(_wish.length()) > 0.05) {
		bool running = D(_wish.length()) > WALK + 0.1;
		if (grade < 0.0) {
			double gain = std::exp(-3.5 * absf(grade + 0.05)) / std::exp(-3.5 * 0.05);
			if (gain > 1.0) {
				_wish *= (real_t)gain;
			}
		}
		_wish = limit(_wish, _slope_speed(running));
	}
	face_in = false;

	bool jump_now = (bool)s.get("jump", false);
	if (state == GROUND && jump_now && !_jump_held && jump_timer <= 0.0 && !crouched) {
		_jump_still = D(hvel.length()) < 2.0;
		jump_timer = _jump_still ? (JUMP_DIP_STAND + JUMP_PUSH_STAND) : JUMP_PUSH_RUN;
		emit_signal("jump_started", jump_timer);
	}
	_jump_held = jump_now;
	if (jump_timer > 0.0) {
		if (state != GROUND) {
			jump_timer = 0.0;
		} else {
			if (_jump_still) {
				_wish = ZERO;
			}
			jump_timer -= dt;
			if (jump_timer <= 0.0) {
				jump_timer = 0.0;
				state = AIR;
				vy = std::sqrt(2.0 * GRAVITY * (_jump_still ? JUMP_RISE : JUMP_RISE_RUN));
				from_jump = true;
				air_time = 0.0;
				_air_peak = D(get_global_position().y);
				emit_signal("jumped");
			}
		}
	}

	switch (state) {
		case GROUND: {
			Vector3 wish = _wish;
			if (_wall != ZERO) {
				if (test_move(get_global_transform(), mul(-_wall, 0.03))) {
					if (D(wish.dot(_wall)) < 0.0) {
						wish = wish.slide(_wall);
					}
				} else {
					_wall = ZERO;
				}
			}
			hvel = _steer(hvel, wish, dt);
			_slow_for_rising_ground();
			vy = 0.0;
			_move(mul(hvel, dt), true);
		} break;
		case STEEP: {
			Vector3 n = ground_normal;
			Vector3 along = mul(DOWN - mul(n, D(DOWN.dot(n))), GRAVITY);
			hvel += mul(V(D(along.x), 0.0, D(along.z)), dt);
			Vector3 uphill = -V(D(n.x), 0.0, D(n.z)).normalized();
			double up_speed = D(hvel.dot(uphill));
			if (up_speed > 0.0) {
				hvel -= mul(uphill, up_speed);
			}
			vy = 0.0;
			_move(mul(hvel, dt), true);
		} break;
		default: {
			spot_total = 0.0;
			hvel += mul(_wish - hvel, 1.0 - std::exp(-dt / 1.5));
			vy = maxf(vy - GRAVITY * dt, -TERMINAL);
			_move(mul(V(D(hvel.x), vy, D(hvel.z)), dt), false);
		} break;
	}
	set_velocity(V(D(hvel.x), vy, D(hvel.z)));
	_update_ground(dt);

	if (D(hvel.length()) > 0.2 && state == GROUND && spot_total == 0.0) {
		double want = face_in ? std::atan2(D(hvel.x), D(hvel.z)) : std::atan2(-D(hvel.x), -D(hvel.z));
		if (squeeze >= 2 && absf(wrapf(want - _rot_y(), -PI, PI)) > PI * 0.5) {
			_set_rot_y(want);
			squeeze_side = -squeeze_side;
		}
		_set_rot_y(rotate_toward(_rot_y(), want, TURN_SPEED * dt));
	}
}

Vector3 TravBody::_steer(Vector3 v, const Vector3 &wish, double dt) {
	double speed = D(v.length());
	double want = D(wish.length());
	double fast = clampf((maxf(speed, want) - WALK) / (RUN - WALK), 0.0, 1.0);
	double brake = lerpf(STOP_WALK, STOP_RUN, clampf((speed - WALK) / (RUN - WALK), 0.0, 1.0));
	if (want < 0.05) {
		spot_total = 0.0;
		return speed > 0.0001 ? mul(v.normalized(), maxf(speed - brake * dt, 0.0)) : ZERO;
	}
	Vector3 wdir = div(wish, want);
	double off = wrapf(std::atan2(-D(wdir.x), -D(wdir.z)) - _rot_y(), -PI, PI);
	if (spot_total != 0.0) {
		if (absf(off) > deg_to_rad(SPOT_END_DEG)) {
			double rate = spot_run ? TURN_RATE_RUN : lerpf(TURN_RATE_WALK, TURN_RATE_RUN, fast);
			_set_rot_y(_rot_y() + signf(off) * minf(rate * dt, absf(off)));
			spot_left = wrapf(std::atan2(-D(wdir.x), -D(wdir.z)) - _rot_y(), -PI, PI);
			return speed > 0.0001 ? mul(v.normalized(), maxf(speed - STOP_RUN * dt, 0.0)) : ZERO;
		}
		spot_total = 0.0;
		if (spot_run && want > WALK + 0.1) {
			spot_run = false;
			return mul(wdir, RUN_OUT);
		}
		if (spot_walk && want > 0.05) {
			return mul(wdir, minf(want, 0.9 * WALK));
		}
		if (speed >= 0.3) {
			return ZERO;
		}
	}
	if (speed < 0.3) {
		if (absf(off) > deg_to_rad(SPOT_START_DEG) && !crouched) {
			spot_total = off;
			spot_left = off;
			spot_run = false;
			spot_walk = false;
			return ZERO;
		}
		speed += (want - speed) * (1.0 - std::exp(-dt / _start_time(speed, want, fast)));
		return mul(wdir, speed);
	}
	Vector3 dir = div(v, speed);
	double ang = D(dir.angle_to(wdir));
	if (ang > deg_to_rad(REVERSE_ANGLE_DEG)) {
		if (speed > REVERSE_SPEED && want <= WALK + 0.1) {
			return mul(dir, maxf(speed - brake * dt, 0.0));
		}
		if (want > WALK + 0.1) {
			spot_total = off;
			spot_left = off;
			spot_run = true;
			spot_walk = false;
			return mul(dir, speed);
		}
		spot_total = off;
		spot_left = off;
		spot_run = false;
		spot_walk = true;
		return mul(dir, speed);
	}
	double turn = lerpf(TURN_RATE_WALK, TURN_RATE_RUN, fast) * dt;
	if (ang > 0.0001) {
		Vector3 axis = dir.cross(wdir);
		axis = D(axis.length()) < 0.0001 ? UP : axis.normalized();
		dir = dir.rotated(axis, (real_t)minf(ang, turn)).normalized();
	}
	want *= lerpf(1.0, TURN_SLOW, clampf(ang / deg_to_rad(TURN_SLOW_ANGLE_DEG), 0.0, 1.0));
	if (want > speed) {
		speed += (want - speed) * (1.0 - std::exp(-dt / _start_time(speed, want, fast)));
	} else {
		speed = maxf(speed - brake * dt, want);
	}
	return mul(dir, speed);
}

double TravBody::_start_time(double speed, double want, double fast) {
	double walk_time = speed < 0.9 * want ? START_TIME_WALK : START_TAIL_WALK;
	return lerpf(walk_time, START_TIME_RUN, fast);
}

Dictionary TravBody::_ray_down(const Vector3 &at) {
	return _ray(at + V(0.0, 0.6, 0.0), at - V(0.0, 0.8, 0.0));
}

void TravBody::_find_stairs(double dt) {
	Vector3 gp = get_global_position();
	double speed = D(hvel.length());
	Vector3 dir = speed > 0.2 ? div(hvel, speed) : (D(_wish.length()) > 0.05 ? _wish.normalized() : ZERO);
	Dictionary here = _ray_down(gp);
	if (state == GROUND && !here.is_empty() && absf(D(((Vector3)here["position"]).y) - ground_y) < 0.05) {
		_stood_y = D(((Vector3)here["position"]).y);
	}
	if (state != GROUND || here.is_empty() || dir == ZERO) {
		stairs = 0;
		_ray_ok = false;
		if (state != GROUND || here.is_empty()) {
			terrain = 0;
			slope_deg = 0.0;
		}
		return;
	}
	double y = D(((Vector3)here["position"]).y);
	_read_slope((Vector3)here["normal"], dir);
	_since_edge += speed * dt;
	if (_ray_ok && absf(y - _ray_y) > 0.06 && D(((Vector3)here["normal"]).y) > 0.98) {
		if (_since_edge > 0.15 && _since_edge < 0.45 && stairs != 0) {
			stair_tread = _since_edge;
		}
		_since_edge = 0.0;
		stair_edge = gp;
		stair_count += 1;
		stair_riser = absf(y - _ray_y);
	}
	_ray_y = y;
	_ray_ok = true;
	Dictionary a = _ray_down(gp + mul(dir, 0.35));
	Dictionary b = _ray_down(gp + mul(dir, 0.70));
	int way = 0;
	if (!a.is_empty() && !b.is_empty() && D(((Vector3)a["normal"]).y) > 0.98 && D(((Vector3)b["normal"]).y) > 0.98) {
		double d1 = D(((Vector3)a["position"]).y) - y;
		double d2 = D(((Vector3)b["position"]).y) - D(((Vector3)a["position"]).y);
		if (d1 > 0.08 && d2 > 0.08) {
			way = 1;
		} else if (d1 < -0.08 && d2 < -0.08) {
			way = -1;
		}
		if (way != 0 && stairs != way) {
			stair_riser = absf(d1) < 0.3 ? absf(d1) : absf(d1) * 0.5;
		}
	}
	if (way != 0) {
		if (stairs != way) {
			stair_tread = TREAD;
			stair_count = 0;
			stair_edge = gp;
			double last_y = y;
			for (int i = 1; i < 26; i++) {
				Dictionary r = _ray_down(gp + mul(dir, i * 0.02));
				if (!r.is_empty() && absf(D(((Vector3)r["position"]).y) - last_y) > 0.06) {
					stair_edge = gp + mul(dir, i * 0.02 - TREAD);
					break;
				}
			}
			_since_edge = D((gp - stair_edge).dot(dir));
		}
		stairs = way;
		stair_dir = dir;
	} else if (stairs != 0) {
		bool level_ahead = !a.is_empty() && absf(D(((Vector3)a["position"]).y) - y) < 0.03;
		if ((level_ahead && _since_edge > 0.06) || _since_edge > stair_tread * 1.3) {
			stairs = 0;
		}
	}
}

void TravBody::_read_slope(const Vector3 &n, const Vector3 &dir) {
	slope_deg = rad_to_deg(std::acos(clampf(D(n.y), -1.0, 1.0)));
	grade = -(D(n.x) * D(dir.x) + D(n.z) * D(dir.z)) / maxf(D(n.y), 0.01);
	double up_one = terrain < 1 ? 1.0 : -1.0;
	double up_two = terrain < 2 ? 1.0 : -1.0;
	terrain = slope_deg > SLOPE_HANDS_DEG + up_two ? 2 : (slope_deg > SLOPE_WALK_DEG + up_one ? 1 : 0);
}

double TravBody::_slope_speed(bool run) {
	bool hands = terrain == 2;
	double angle = std::atan(absf(grade));
	if (grade < 0.0) {
		angle *= DOWN_EASE;
	}
	if (angle < 0.02) {
		return 1000.0;
	}
	return (!run ? CLIMB_WALK : (hands ? CLIMB_HANDS_RUN : CLIMB_RUN)) / std::tan(angle);
}

double TravBody::_stair_speed(bool run) {
	if (stairs > 0) {
		return stair_tread / (run ? STEP_TIME_RUN_UP : STEP_TIME_UP);
	}
	return stair_tread / (run ? STEP_TIME_RUN_DOWN : STEP_TIME_DOWN);
}

double TravBody::stop_distance() {
	double speed = D(hvel.length());
	double d = 0.0;
	double dt = 1.0 / (double)Engine::get_singleton()->get_physics_ticks_per_second();
	for (int i = 0; i < 600; i++) {
		if (speed <= 0.0) {
			break;
		}
		speed = maxf(speed - lerpf(STOP_WALK, STOP_RUN, clampf((speed - WALK) / (RUN - WALK), 0.0, 1.0)) * dt, 0.0);
		d += speed * dt;
	}
	return d;
}

void TravBody::_move(Vector3 motion, bool flat) {
	_touched = false;
	for (int i = 0; i < 4; i++) {
		if (D(motion.length()) < 0.00001) {
			break;
		}
		Ref<KinematicCollision3D> c = move_and_collide(motion);
		if (c.is_null()) {
			break;
		}
		_touched = true;
		Vector3 n = c->get_normal();
		if (flat) {
			n = V(D(n.x), 0.0, D(n.z));
			if (D(n.length()) < 0.2) {
				break;
			}
			n = n.normalized();
			_wall = n;
		}
		motion = c->get_remainder().slide(n);
		if (flat) {
			motion.y = 0.0;
		}
		Vector3 v = V(D(hvel.x), vy, D(hvel.z));
		if (D(v.dot(n)) < 0.0) {
			v = v.slide(n);
		}
		hvel = V(D(v.x), 0.0, D(v.z));
		if (!flat) {
			vy = D(v.y);
		}
	}
}

void TravBody::_slow_for_rising_ground() {
	double speed = D(hvel.length());
	if (speed < 0.3) {
		return;
	}
	Vector3 dir = div(hvel, speed);
	Vector3 gp = get_global_position();
	Dictionary g = probe(gp + mul(dir, 0.3), FLOAT + RADIUS + 0.3, STEP_DOWN + 0.05);
	if (!(bool)g["hit"]) {
		return;
	}
	double rise = (double)g["y"] - maxf(ground_y, D(gp.y));
	double cap = 1000.0;
	if (rise > 0.02 && rise <= FLOAT) {
		cap = RISE_SPEED * 0.9 / (rise / 0.3);
	} else if (rise < -0.02) {
		cap = SINK_SPEED * 0.9 / (-rise / 0.3);
	}
	if (speed > cap) {
		hvel = mul(dir, cap);
	}
}

void TravBody::_update_ground(double dt) {
	Vector3 feet = get_global_position();
	if (state == GROUND || state == STEEP) {
		Dictionary g = probe(feet);
		if (!(bool)g["hit"] || (double)g["y"] - D(feet.y) > FLOAT - 0.005) {
			if (!(bool)g["hit"]) {
				state = AIR;
				vy = 0.0;
				from_jump = false;
				air_time = 0.0;
				_air_peak = (_stood_y > D(feet.y) && _stood_y - D(feet.y) < STEP_DOWN) ? _stood_y : D(feet.y);
			}
			return;
		}
		ground_y = (double)g["y"];
		ground_normal = g["normal"];
		state = _is_steep(g) ? STEEP : GROUND;
		double err = ground_y - D(feet.y);
		if (stairs < 0) {
			Dictionary ahead = _ray_down(feet + mul(stair_dir, stair_tread));
			if (!ahead.is_empty()) {
				double drop = ground_y - D(((Vector3)ahead["position"]).y);
				if (drop > 0.02 && drop < 0.3) {
					err = ground_y - drop * clampf(_since_edge / stair_tread, 0.0, 1.0) - D(feet.y);
				}
			}
		}
		double up = RISE_SPEED;
		double down = SINK_SPEED;
		if (stairs != 0 && stair_riser > 0.0) {
			double follow = maxf(D(hvel.length()) * stair_riser / stair_tread * 1.5, 0.25);
			up = minf(up, follow);
			down = minf(down, follow);
		}
		double dy = err > 0.0 ? minf(err, up * dt) : maxf(err, -down * dt);
		if (absf(dy) > 0.00001) {
			move_and_collide(V(0.0, dy, 0.0));
		}
	} else {
		air_time += dt;
		_air_peak = maxf(_air_peak, D(feet.y));
		double fall = maxf(0.02, -vy * dt + 0.01);
		Dictionary g = probe(feet, FLOAT + RADIUS, fall);
		if ((bool)g["hit"] && vy <= 0.0 && D(feet.y) - (double)g["y"] <= fall && (double)g["y"] - D(feet.y) <= FLOAT - 0.005) {
			ground_y = (double)g["y"];
			ground_normal = g["normal"];
			move_and_collide(V(0.0, ground_y - D(feet.y), 0.0));
			vy = 0.0;
			state = _is_steep(g) ? STEEP : GROUND;
			double drop = _air_peak - ground_y;
			if (!(from_jump && drop < 0.9)) {
				land_hold = drop >= HARD_DROP ? LAND_HOLD_HARD : (drop > STEP_DOWN ? LAND_HOLD_SOFT : 0.0);
			}
			emit_signal("landed", drop);
			from_jump = false;
		} else {
			state = _touched ? UNSUPPORTED : AIR;
		}
	}
}

Dictionary TravBody::landing_ahead() {
	Vector3 gp = get_global_position();
	Dictionary hit = _ray(gp + V(0.0, 0.3, 0.0), gp - V(0.0, 6.0, 0.0));
	if (hit.is_empty()) {
		return Dictionary();
	}
	double y = D(((Vector3)hit["position"]).y);
	double d = maxf(D(gp.y) - y, 0.0);
	double down = -vy;
	Dictionary out;
	out["time"] = (-down + std::sqrt(maxf(down * down + 2.0 * GRAVITY * d, 0.0))) / GRAVITY;
	out["drop"] = _air_peak - y;
	return out;
}

Dictionary TravBody::get_readout() {
	Dictionary out;
	out["state"] = String(STATE_NAMES[state]);
	out["speed"] = D(hvel.length());
	out["height"] = D(get_global_position().y);
	out["note"] = vformat("ground %.3f m   slope %.0f deg", ground_y, rad_to_deg(std::acos(clampf(D(ground_normal.y), -1.0, 1.0))));
	return out;
}

void TravBody::place(const Vector3 &at) {
	set_global_position(at);
	hvel = ZERO;
	vy = 0.0;
	set_velocity(ZERO);
	jump_timer = 0.0;
	from_jump = false;
	air_time = 0.0;
	_air_peak = D(at.y);
	_stood_y = D(at.y);
	state = AIR;
}
