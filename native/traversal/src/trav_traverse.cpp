// The traversal moves (the study, stage 8 onward: "Each move is built the same way (align, play, fit, hand IK, hand
// back)"). A line-for-line translation of traversal_lab/traversal/moves/traverse.gd (the script version, the
// reference): the same names, the same numbers, the same order of work. The reasons for each thing are in the script.
#include "trav_traverse.h"

#include "trav_math.h"

#include <godot_cpp/classes/class_db_singleton.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

using namespace godot;
using namespace trav;

static const Vector3 UP(0, 1, 0);
static const Vector3 ZERO(0, 0, 0);
static inline double D(real_t x) { return (double)x; }
static inline Vector3 V(double x, double y, double z) { return Vector3((real_t)x, (real_t)y, (real_t)z); }
static inline Vector3 mul(const Vector3 &v, double s) { return v * (real_t)s; }
static inline Vector3 div(const Vector3 &v, double s) { return v / (real_t)s; }
static inline Vector3 lerp3(const Vector3 &a, const Vector3 &b, double w) { return a.lerp(b, (real_t)w); }
static inline Ref<Resource> res(const Variant &path) { return ResourceLoader::get_singleton()->load((String)path); }
static inline double F(const Variant &v) { return (double)v; }
// Dictionary.merge without overwrite, one key at a time
static inline void merge_new(Dictionary &d, const Variant &k, const Variant &v) {
	if (!d.has(k)) {
		d[k] = v;
	}
}
// the engine's own formula, in doubles (core/math/math_funcs.h, 4.7)
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

// clip_data.gd, rise_of
static PackedFloat32Array rise_of(const PackedVector3Array &hips) {
	PackedFloat32Array out;
	int n = hips.size();
	double whole = D(hips[n - 1].y) - D(hips[0].y);
	double most = 0.0;
	for (int f = 0; f < n; f++) {
		most = maxf(most, absf(whole) > 0.01 ? clampf((D(hips[f].y) - D(hips[0].y)) / whole, 0.0, 1.0) : 0.0);
		out.append((real_t)most);
	}
	return out;
}

TravTraverse::TravTraverse() {
#include "trav_traverse_ctor.inc"
}

void TravTraverse::_ready() {
	if (!OS::get_singleton()->get_cmdline_user_args().has("--script") && ClassDBSingleton::get_singleton()->class_exists("TravDetector")) {
		detector = ClassDBSingleton::get_singleton()->instantiate("TravDetector");
	} else {
		Ref<Resource> script = ResourceLoader::get_singleton()->load("res://traversal/detect/detector.gd");
		detector = script->call("new");
	}
	det()->set("body", body);
	Array mkeys = MOVES.keys();
	for (int k = 0; k < mkeys.size(); k++) {
		String key = mkeys[k];
		Ref<Resource> c = res(((Dictionary)MOVES[key])["res"]);
		PackedVector3Array hips = c->get("hips");
		_fps = (double)c->get("fps");
		int last = hips.size() - 1;
		double drop = D(hips[0].y) - D(hips[last].y);
		PackedFloat32Array fwd;
		PackedFloat32Array high;
		for (int f = 0; f < hips.size(); f++) {
			fwd.append((real_t)(D(hips[f].z) - D(hips[0].z)));
			high.append((real_t)clampf((D(hips[f].y) - D(hips[last].y)) / drop, 0.0, 1.0));
		}
		_fwd[key] = fwd;
		_high[key] = high;
	}
	Array ckeys = CLIMBS.keys();
	for (int k = 0; k < ckeys.size(); k++) {
		String key = ckeys[k];
		Ref<Resource> up = res(((Dictionary)CLIMBS[key])["res"]);
		PackedVector3Array up_hips = up->get("hips");
		PackedFloat32Array up_fwd;
		for (int f = 0; f < up_hips.size(); f++) {
			up_fwd.append((real_t)(D(up_hips[f].z) - D(up_hips[0].z)));
		}
		_c_fwd[key] = up_fwd;
		_c_rise[key] = rise_of(up_hips);
		_c_high[key] = D(up_hips[up_hips.size() - 1].y) - D(up_hips[0].y);
	}
	body->connect("landed", Callable(this, "_on_landed"));
	PackedVector3Array j_hips = res(JUMP["res"])->get("hips");
	for (int f = 0; f < j_hips.size(); f++) {
		_j_fwd.append((real_t)(D(j_hips[f].z) - D(j_hips[0].z)));
	}
	PackedVector3Array o_hips = res(OVER["res"])->get("hips");
	for (int f = 0; f < o_hips.size(); f++) {
		_o_fwd.append((real_t)(D(o_hips[f].z) - D(o_hips[0].z)));
	}
	_o_rise = rise_of(o_hips);
	_o_high = D(o_hips[o_hips.size() - 1].y) - D(o_hips[0].y);
	PackedVector3Array g1 = res(GRAB["jump_res"])->get("hips");
	_g_rise1 = rise_of(g1);
	PackedVector3Array g2 = res(GRAB["climb_res"])->get("hips");
	_g_rise2 = rise_of(g2);
	for (int f = 0; f < g2.size(); f++) {
		_g_fwd2.append((real_t)(D(g2[f].z) - D(g2[0].z)));
	}
	PackedVector3Array wh = res(WALLRUN["res"])->get("hips");
	_w_rise = rise_of(wh);
	for (int f = 0; f < wh.size(); f++) {
		_w_fwd.append((real_t)(D(wh[f].z) - D(wh[0].z)));
	}
	PackedVector3Array dh = res(DOWN["res"])->get("hips");
	double d_fallen = 0.0;
	int d_from = (int)std::round((double)DOWN["lower_from"] * 30.0);
	for (int f = 0; f < dh.size(); f++) {
		_d_xz.append(Vector2((real_t)(D(dh[f].x) - D(dh[0].x)), (real_t)(D(dh[f].z) - D(dh[0].z))));
		if (f >= d_from) {
			d_fallen = maxf(d_fallen, clampf((D(dh[d_from].y) - D(dh[f].y)) / (D(dh[d_from].y) - D(dh[dh.size() - 1].y)), 0.0, 1.0));
		}
		_d_fall.append((real_t)d_fallen);
	}
	PackedVector3Array bh = res(BALANCE["res"])->get("hips");
	int b_from = (int)std::round((double)BALANCE["over"] * 30.0);
	double b_fallen = 0.0;
	for (int f = 0; f < bh.size(); f++) {
		_b_xz.append(Vector2((real_t)(D(bh[f].x) - D(bh[0].x)), (real_t)(D(bh[f].z) - D(bh[0].z))));
		if (f >= b_from) {
			b_fallen = maxf(b_fallen, clampf((D(bh[b_from].y) - D(bh[f].y)) / (D(bh[b_from].y) - D(bh[bh.size() - 1].y)), 0.0, 1.0));
		}
		_b_fall.append((real_t)b_fallen);
	}
	PackedVector3Array t_hips = res(TUCK["res"])->get("hips");
	for (int f = 0; f < t_hips.size(); f++) {
		_t_fwd.append((real_t)(D(t_hips[f].z) - D(t_hips[0].z)));
	}
	PackedVector3Array v_hips = res(VAULT["res"])->get("hips");
	for (int f = 0; f < v_hips.size(); f++) {
		_v_fwd.append((real_t)(D(v_hips[f].z) - D(v_hips[0].z)));
		_v_hips.append(v_hips[f].y);
	}
}

void TravTraverse::_on_landed(double drop) {
	if (!enabled || (bool)body->call("in_move") || (bool)body->get("crouched")) {
		return;
	}
	Vector3 v = body->get("hvel");
	if (drop <= (double)BAND[1] + MEASURED_WITHIN || drop > ROLL_MOST + ROLL_JUMP_MORE || D(v.length()) < RUN_FROM) {
		return;
	}
	Dictionary mv = MOVES["roll"];
	PackedFloat32Array fwd = _fwd["roll"];
	Vector3 dir = v.normalized();
	Vector3 feet = body->get_global_position();
	double travel = _at(fwd, (double)mv["exit"]) - _at(fwd, (double)mv["down"]);
	const double shares[3] = { 0.0, 0.5, 1.0 };
	for (int k = 0; k < 3; k++) {
		Vector3 p = feet + mul(dir, travel * shares[k]);
		Dictionary g = body->call("probe", V(D(p.x), D(feet.y), D(p.z)));
		if (!(bool)g["hit"] || absf((double)g["y"] - D(feet.y)) > LAND_WITHIN || !(bool)det()->call("_fits", V(D(p.x), D(feet.y), D(p.z)), (double)body->get("HEIGHT"))) {
			refused = "no room to roll out of the landing";
			return;
		}
	}
	refused = "";
	_plan = Dictionary();
	_plan["key"] = "roll_only";
	_plan["from"] = feet;
	_plan["end"] = feet + mul(dir, travel);
	_plan["m"] = dir;
	_plan["yaw"] = std::atan2(-D(dir.x), -D(dir.z));
	_plan["exit_speed"] = (_at(fwd, (double)mv["exit"]) - _at(fwd, (double)mv["exit"] - 0.2)) / 0.2;
	plays += 1;
	body->call("begin_move", Callable(this, "_roll_only"), (String)mv["input"]);
}

Dictionary TravTraverse::_roll_only(double t) {
	Dictionary mv = MOVES["roll"];
	PackedFloat32Array fwd = _fwd["roll"];
	Dictionary p = _plan;
	double u = clampf(t / ((double)mv["exit"] - (double)mv["down"]), 0.0, 1.0);
	double ct = lerpf((double)mv["down"], (double)mv["exit"], u);
	double f0 = _at(fwd, (double)mv["down"]);
	double f1 = _at(fwd, (double)mv["exit"]);
	Array free = mv["free"];
	Dictionary out;
	out["done"] = u >= 1.0;
	out["pos"] = lerp3((Vector3)p["from"], (Vector3)p["end"], (_at(fwd, ct) - f0) / maxf(f1 - f0, 0.001));
	out["yaw"] = (double)p["yaw"];
	out["clip_t"] = ct;
	out["air"] = false;
	out["landed"] = true;
	out["landing"] = "heavy";
	out["free"] = ct >= (double)free[0] && ct <= (double)free[1];
	if (u >= 1.0) {
		out["exit"] = mul((Vector3)p["m"], (double)p["exit_speed"]);
	}
	return out;
}

double TravTraverse::_at(const PackedFloat32Array &table, double t) {
	double x = clampf(t * _fps, 0.0, (double)table.size() - 1.001);
	int i = (int)x;
	return lerpf(D(table[i]), D(table[i + 1]), x - i);
}

void TravTraverse::_physics_process(double _dt) {
	if (body == nullptr || !enabled || (bool)body->call("in_move")) {
		return;
	}
	if ((bool)body->get("auto_on")) {
		record = Dictionary();
		return;
	}
	_tick += 1;
	Vector3 v = body->get("hvel");
	double wish = D(((Vector3)body->get("_wish")).length());
	if ((int)(int64_t)body->get("narrow") > 0 && (int)(int64_t)body->get("squeeze") != 3 && (int)(int64_t)body->get("state") == 0 && D(v.length()) < 0.1) {
		_still += 1.0 / 60.0;
		if (_still >= BALANCE_AFTER) {
			_still = 0.0;
			if (_try_balance_fall()) {
				return;
			}
		}
	} else {
		_still = 0.0;
	}
	if ((int)(int64_t)body->get("squeeze") == 3) {
		Vector3 sw = body->get("stick_wish");
		if (D(sw.length()) < 0.05 || D(sw.normalized().dot(-(Vector3)body->get("ledge_out"))) < 0.5) {
			record = Dictionary();
			return;
		}
	}
	if (_catch_next > 0) {
		_catch_next -= 1;
		if ((int)(int64_t)body->get("state") >= 2) {
			body->set("from_jump", true);
			body->set("_jump_still", true);
			_catch_next = 0;
		}
	}
	if ((int)(int64_t)body->get("state") >= 2 && _try_air(v)) {
		return;
	}
	if (_try_step_up(v, (Vector3)body->get("_wish"))) {
		return;
	}
	if ((bool)body->get("crouched") && (int)(int64_t)body->get("state") == 0 && wish > 0.05 && D(v.length()) > 0.2) {
		if (_tick % AGAIN == 0) {
			Dictionary rec = det()->call("measure", v.normalized());
			double d = (double)rec.get("drop", (double)INFINITY);
			if ((String)rec["kind"] == "drop" && d > (double)DOWN_BAND[0] + MEASURED_WITHIN && d <= (double)DOWN_BAND[1] + MEASURED_WITHIN) {
				record = rec;
				_try_climb_down(v.normalized(), d);
				if (!(bool)body->call("in_move")) {
					record = Dictionary();
				}
			}
		}
		return;
	}
	bool walking = (int)(int64_t)body->get("state") == 0 && !(bool)body->get("crouched") && D(v.length()) > 0.5 && wish > 0.05 && (int)(int64_t)body->get("stairs") == 0 && (int)(int64_t)body->get("terrain") == 0;
	String key = (wish > (double)body->get("WALK") + 0.1 && D(v.length()) > RUN_FROM) ? "run" : "walk";
	_narrow_ago = (int)(int64_t)body->get("narrow") > 0 ? 0 : _narrow_ago + 1;
	if (_narrow_ago < 45 && (bool)body->get("run_asked")) {
		key = "run";
	}
	Dictionary mv = MOVES[key];
	PackedFloat32Array fwd = _fwd[key];
	if (!walking) {
		record = Dictionary();
		return;
	}
	Vector3 dir = v.normalized();
	if (record.is_empty()) {
		Dictionary ahead = body->call("_ray_down", body->get_global_position() + mul(dir, maxf(LOOK, D(v.length()) * LOOK_TIME)));
		if (!ahead.is_empty() && D(((Vector3)ahead["position"]).y) > D(body->get_global_position().y) - GAP_DEEP_LEAST) {
			return;
		}
	}
	if (record.is_empty() || _tick % AGAIN == 0 || (String)record.get("kind", "") == "gap") {
		record = det()->call("measure", dir, (double)INFINITY, GAP_LOOK);
		if ((String)record["kind"] != "gap") {
			Dictionary e = det()->call("measure_edge", dir, GAP_LOOK, GAP_DEEP_LEAST, GAP_DOWN);
			if (!e.is_empty() && (String)e["kind"] == "gap" && (double)e["gap"] >= GAP_LEAST && !(bool)e.get("far_wall", false)) {
				record = e;
			} else if (!e.is_empty() && (String)record["kind"] == "obstacle" && (double)record.get("top", (double)INFINITY) != (double)INFINITY && !(bool)record.get("blocked", true)) {
				Vector3 em = -(Vector3)e["normal"];
				double across = D(((Vector3)record["edge"] - (Vector3)e["edge"]).dot(em));
				if (across >= GAP_LEAST) {
					e["kind"] = "gap";
					e["gap"] = across;
					e["far_wall"] = false;
					e["landing"] = (double)record["top"];
					e["landing_ok"] = (bool)record.get("stand_room", false);
					record = e;
				}
			}
		}
		if ((String)record["kind"] == "gap") {
			Dictionary gap_rec = record;
			record = Dictionary();
			if (!_try_gap(v, dir, gap_rec, key == "run") && refused == "coming up to the gap") {
				record = gap_rec;
			}
			return;
		}
		if ((String)record["kind"] != "drop") {
			refused = (String)record["kind"] == "none" ? String("") : vformat("not a plain drop (%s)", record["kind"]);
			record = Dictionary();
			return;
		}
	}
	double drop = (double)record.get("drop", (double)INFINITY);
	if (drop <= (double)BAND[0] + MEASURED_WITHIN) {
		refused = "low enough to step down in stride";
		return;
	}
	if (drop > (double)BAND[1] + MEASURED_WITHIN) {
		if (key != "run" || drop > ROLL_MOST + MEASURED_WITHIN) {
			refused = vformat("too high for a step off (%.2f m)", drop);
			return;
		}
		key = "roll";
		mv = MOVES[key];
		fwd = _fwd[key];
	}
	Vector3 m = -(Vector3)record["normal"];
	if (rad_to_deg(D(dir.angle_to(m))) > MOST_OFF_DEG) {
		refused = "not heading at the edge";
		return;
	}
	double from_t = (double)mv["from"];
	double edge_at = (double)mv["edge"];
	double to_edge = edge_at - _at(fwd, from_t);
	double here = D(((Vector3)record["edge"] - body->get_global_position()).dot(m));
	if (here > to_edge) {
		return;
	}
	Vector3 feet = body->get_global_position();
	double top_y = (double)record["ground"];
	double land_y = top_y - drop;
	double speed_in = maxf(D(v.length()), 0.8);
	double t_air = std::sqrt(2.0 * drop / (double)body->get("GRAVITY"));
	double t_rest = (double)mv["exit"] - (double)mv["down"];
	double exit_speed = (_at(fwd, (double)mv["exit"]) - _at(fwd, (double)mv["exit"] - 0.2)) / 0.2;
	Vector3 leave = feet + mul(m, here + _at(fwd, (double)mv["leaves"]) - edge_at);
	Vector3 down = leave + mul(m, key != "walk" ? speed_in * t_air : _at(fwd, (double)mv["down"]) - _at(fwd, (double)mv["leaves"]));
	Vector3 end = down + mul(m, key == "run" ? (speed_in + exit_speed) * 0.5 * t_rest : _at(fwd, (double)mv["exit"]) - _at(fwd, (double)mv["down"]));
	const Vector3 spots[3] = { down, lerp3(down, end, 0.5), end };
	for (int k = 0; k < 3; k++) {
		Vector3 p = spots[k];
		Dictionary g = body->call("probe", V(D(p.x), land_y, D(p.z)));
		if (!(bool)g["hit"] || absf((double)g["y"] - land_y) > LAND_WITHIN) {
			refused = "the ground where he would land is not level with the drop measured";
			return;
		}
		if (!(bool)det()->call("_fits", V(D(p.x), land_y, D(p.z)), (double)body->get("HEIGHT"))) {
			refused = "no room to land";
			return;
		}
	}
	refused = "";
	_plan = Dictionary();
	_plan["key"] = key;
	_plan["from"] = feet;
	_plan["leave"] = V(D(leave.x), top_y, D(leave.z));
	_plan["down"] = V(D(down.x), land_y, D(down.z));
	_plan["end"] = V(D(end.x), land_y, D(end.z));
	_plan["m"] = m;
	_plan["yaw0"] = _rot_y();
	_plan["yaw1"] = std::atan2(-D(m.x), -D(m.z));
	_plan["drop"] = drop;
	_plan["t_step"] = maxf(D((leave - feet).dot(m)), 0.05) / speed_in;
	_plan["t_air"] = t_air;
	_plan["t_rest"] = t_rest;
	_plan["exit_speed"] = exit_speed;
	bool run_on = key == "run" && drop <= RUN_ON_MOST + MEASURED_WITHIN;
	if (run_on) {
		_plan["end"] = _plan["down"];
		_plan["exit_speed"] = speed_in;
		_plan["run_on"] = true;
	}
	double share = key == "roll" ? 1.0 : clampf(drop / (double)mv["native"], 0.0, 1.0);
	_plan["soft"] = 1.0 - share;
	_plan["t_rest"] = (double)_plan["t_rest"] * lerpf(REST_LEAST, 1.0, share);
	plays += 1;
	record = Dictionary();
	body->call("begin_move", Callable(this, "_step_off"), run_on ? String("ground") : (String)mv["input"]);
}

Dictionary TravTraverse::_step_off(double t) {
	Dictionary p = _plan;
	String dk = p.get("drop_key", p["key"]);
	Dictionary mv = MOVES[dk];
	PackedFloat32Array fwd = _fwd[dk];
	PackedFloat32Array high = _high[dk];
	Vector3 m = p["m"];
	double t_step = (double)p["t_step"];
	double t_air = (double)p["t_air"];
	double t_rest = (double)p["t_rest"];
	Dictionary out;
	out["done"] = false;
	out["yaw"] = lerp_angle((double)p["yaw0"], (double)p["yaw1"], clampf(t / maxf(t_step, 0.05), 0.0, 1.0));
	if (t < t_step) {
		double u = t / t_step;
		out["pos"] = lerp3((Vector3)p["from"], (Vector3)p["leave"], u);
		out["clip_t"] = lerpf((double)mv["from"], (double)mv["leaves"], u);
		out["air"] = false;
	} else if (t < t_step + t_air) {
		double u = (t - t_step) / t_air;
		double ct = lerpf((double)mv["leaves"], (double)mv["down"], u);
		double f0 = _at(fwd, (double)mv["leaves"]);
		double f1 = _at(fwd, (double)mv["down"]);
		double along = (_at(fwd, ct) - f0) / maxf(f1 - f0, 0.001);
		Vector3 pos = lerp3((Vector3)p["leave"], (Vector3)p["down"], along);
		double h0 = _at(high, (double)mv["leaves"]);
		double h1 = _at(high, (double)mv["down"]);
		pos.y = (real_t)(D(((Vector3)p["down"]).y) + (double)p["drop"] * clampf((_at(high, ct) - h1) / maxf(h0 - h1, 0.001), 0.0, 1.0));
		out["pos"] = pos;
		out["clip_t"] = ct;
		out["air"] = true;
		out["soft"] = (double)p["soft"] * u;
	} else if ((bool)p.get("run_on", false)) {
		out["pos"] = p["down"];
		out["clip_t"] = 0.0;
		out["air"] = false;
		out["done"] = true;
		out["exit"] = mul(m, (double)p["exit_speed"]);
	} else {
		double u = clampf((t - t_step - t_air) / t_rest, 0.0, 1.0);
		double ct = lerpf((double)mv["down"], (double)mv["exit"], u);
		double f0 = _at(fwd, (double)mv["down"]);
		double f1 = _at(fwd, (double)mv["exit"]);
		out["pos"] = lerp3((Vector3)p["down"], (Vector3)p["end"], (_at(fwd, ct) - f0) / maxf(f1 - f0, 0.001));
		out["clip_t"] = ct;
		out["air"] = false;
		out["landed"] = true;
		Array free = mv.get("free", Array());
		out["free"] = free.size() == 2 && ct >= (double)free[0] && ct <= (double)free[1];
		out["landing"] = (String)mv.get("landing", "soft");
		out["soft"] = (double)p["soft"];
		if (u >= 1.0) {
			out["done"] = true;
			out["exit"] = mul(m, (double)p["exit_speed"]);
		}
	}
	return out;
}

// ------------------------------------------------------------------------------------------------ stage 9: the high step up

bool TravTraverse::_try_step_up(const Vector3 &v, const Vector3 &wish) {
	if ((int64_t)body->get("state") != 0 || (bool)body->get("crouched") || D(wish.length()) < 0.05 || (int64_t)body->get("stairs") != 0 || (int64_t)body->get("terrain") != 0) {
		_up_record = Dictionary();
		return false;
	}
	Vector3 dir = wish.normalized();
	if (_up_record.is_empty()) {
		Vector3 from = body->get_global_position() + mul(UP, F(UP_BAND[0]) + 0.03);
		TypedArray<RID> ex;
		ex.append(body->get_rid());
		Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(from, from + mul(dir, UP_LOOK_RUN), body->get_collision_mask(), ex);
		if (body->get_world_3d()->get_direct_space_state()->intersect_ray(q).is_empty()) {
			return false;
		}
	}
	if (_up_record.is_empty() || _tick % (D(v.length()) > RUN_FROM ? 1 : AGAIN) == 0) {
		_up_record = det()->call("measure", dir);
		if ((String)_up_record["kind"] != "obstacle") {
			_up_record = Dictionary();
			return false;
		}
	}
	Dictionary rec = _up_record;
	double top = F(rec["top"]);
	if (_try_vault(v, wish, rec)) {
		return true;
	}
	if (top <= F(UP_BAND[0]) + MEASURED_WITHIN) {
		return false;
	}
	if (top > F(ON_BAND[1]) + MEASURED_WITHIN && top <= F(MANTLE_BAND[1]) + MEASURED_WITHIN && !(bool)rec["thin"]) {
		return _try_mantle(v, wish, rec);
	}
	// (A wall whose top cannot be seen, under a ceiling, has no "thin" in its record. The script stops here on it with
	// an error and hands back false; its exported game reads nothing for it, goes on, and hands back false further
	// down with `refused` set. Nothing is begun either way. This does as the script run by the tests does.)
	if (!rec.has("thin")) {
		return false;
	}
	if (!(bool)rec["thin"] && top > F(WALLRUN_BAND[0]) + MEASURED_WITHIN && top <= F(WALLRUN_BAND[1]) + MEASURED_WITHIN && D(wish.length()) > F(body->get("WALK")) + 0.1 && D(v.length()) > RUN_FROM) {
		if (_try_wallrun(v, wish, rec)) {
			return true;
		}
		if (refused == "coming up to the wall climb") {
			return false;
		}
	}
	if (top > F((bool)rec["thin"] ? VAULT_BAND[1] : MANTLE_BAND[1]) + MEASURED_WITHIN && top <= F(HIGH_BAND[1]) + MEASURED_WITHIN) {
		return _try_grab(wish, rec);
	}
	if (top > F(ON_BAND[1]) + MEASURED_WITHIN) {
		refused = vformat("too high to step or climb onto (%.2f m)", top);
		return false;
	}
	if ((bool)rec["blocked"] || !(bool)rec["stand_room"]) {
		refused = "no room to stand on top";
		return false;
	}
	Vector3 m = -(Vector3)rec["normal"];
	if (rad_to_deg(D(dir.angle_to(m))) > MOST_OFF_DEG) {
		refused = "not heading at it";
		return false;
	}
	bool running = D(wish.length()) > F(body->get("WALK")) + 0.1 && D(v.length()) > RUN_FROM;
	String row = "step_up";
	if (top <= F(UP_BAND[1]) + MEASURED_WITHIN) {
		if (_try_run_up(v, wish, rec, m, top)) {
			return true;
		}
		if (!refused.is_empty()) {
			return false;
		}
	} else {
		row = (top <= STEP_ON_MOST + MEASURED_WITHIN && !running) ? "step_on" : "jump_on";
	}
	Dictionary cl = CLIMBS[row];
	PackedFloat32Array c_fwd = _c_fwd[row];
	bool moving = D(v.length()) > 0.5;
	double from_t = moving ? F(cl["from_moving"]) : F(cl["from"]);
	double exit_t = F(cl["exit"]);
	double here = D(((Vector3)rec["edge"] - body->get_global_position()).dot(m));
	if (running && cl.has("from_run")) {
		double far_d = F(cl["edge"]) - _at(c_fwd, F(cl["from_run"]));
		if (here > far_d) {
			refused = "coming up to the jump onto it";
			return false;
		}
		if (here > far_d - 0.45) {
			from_t = F(cl["from_run"]);
		}
	}
	double native_d = F(cl["edge"]) - _at(c_fwd, from_t);
	if (here > native_d + 0.02 + (moving ? D(v.length()) * EARLY : 0.0)) {
		return false;
	}
	bool mirror = false;
	Node *ch = body->get_node_or_null("Character");
	if (moving && (bool)cl["mirrored"] && ch != nullptr && ch->has_method("_lead_now")) {
		mirror = (F(ch->call("_lead_now")) > 0.0) != (bool)cl["wants_left"];
	}
	double inward = _at(c_fwd, exit_t) - F(cl["edge"]);
	if (F(rec["depth"]) < inward + F(body->get("RADIUS"))) {
		refused = "the top is not deep enough to step onto";
		return false;
	}
	Vector3 feet = body->get_global_position();
	double ground = F(rec["ground"]);
	Vector3 end = feet + mul(m, here + inward);
	end.y = (real_t)(ground + top);
	if (!_fits(end)) {
		refused = "no room where he would end";
		return false;
	}
	refused = "";
	_plan = Dictionary();
	_plan["key"] = row == "step_up" ? String("up") : row;
	_plan["row"] = row;
	_plan["from"] = V(D(feet.x), ground, D(feet.z));
	_plan["end"] = end;
	_plan["m"] = m;
	_plan["yaw0"] = _rot_y();
	_plan["yaw1"] = std::atan2(-D(m.x), -D(m.z));
	_plan["top"] = top;
	_plan["here"] = here;
	_plan["from_t"] = from_t;
	_plan["stretch"] = (here + inward) / maxf(_at(c_fwd, exit_t) - _at(c_fwd, from_t), 0.01);
	_plan["exit_speed"] = maxf((_at(c_fwd, exit_t) - _at(c_fwd, exit_t - 0.2)) / 0.2, 0.0);
	plays += 1;
	_up_record = Dictionary();
	record = Dictionary();
	body->call("begin_move", Callable(this, "_step_up"), (String)cl["input"] + (mirror ? String("_m") : String("")));
	return true;
}

Dictionary TravTraverse::_step_up(double t) {
	Dictionary p = _plan;
	Dictionary cl = CLIMBS[p["row"]];
	PackedFloat32Array c_fwd = _c_fwd[p["row"]];
	PackedFloat32Array c_rise = _c_rise[p["row"]];
	double high = F(_c_high[p["row"]]);
	Vector3 m = p["m"];
	double from_t = F(p["from_t"]);
	double exit_t = F(cl["exit"]);
	double ct = minf(from_t + t, exit_t);
	double gone = _at(c_fwd, ct) - _at(c_fwd, from_t);
	double rise = _at(c_rise, ct);
	Vector3 pos = (Vector3)p["from"] + mul(m, gone * F(p["stretch"]));
	pos.y = (real_t)(D(((Vector3)p["from"]).y) + F(p["top"]) * rise);
	Dictionary out;
	out["done"] = ct >= exit_t;
	out["pos"] = pos;
	out["clip_t"] = ct;
	out["air"] = false;
	out["yaw"] = lerp_angle(F(p["yaw0"]), F(p["yaw1"]), clampf(t / 0.2, 0.0, 1.0));
	Array step;
	step.append(F(cl["edge"]) - _at(c_fwd, ct));
	step.append(high);
	step.append(high * rise);
	step.append(F(p["top"]));
	out["step"] = step;
	if (ct >= exit_t) {
		out["pos"] = p["end"];
		out["exit"] = mul(m, F(p["exit_speed"]));
	}
	return out;
}

bool TravTraverse::_try_run_up(const Vector3 &v, const Vector3 &wish, Dictionary rec, const Vector3 &m, double top) {
	refused = "";
	double speed = D(v.length());
	if (D(wish.length()) <= F(body->get("WALK")) + 0.1 || speed <= RUN_FROM) {
		return false;
	}
	double here = D(((Vector3)rec["edge"] - body->get_global_position()).dot(m));
	double take_off = speed * RUN_UP_AIR * RUN_UP_FACE;
	double beyond = speed * RUN_UP_AIR * (1.0 - RUN_UP_FACE);
	double out_run = speed * (F(RUN_UP["exit"]) - F(RUN_UP["land"]));
	if (F(rec["depth"]) < beyond + out_run + F(body->get("RADIUS"))) {
		return false;
	}
	if (here < take_off - 0.15) {
		return false;
	}
	if (here > take_off) {
		refused = "coming up to the leap";
		return false;
	}
	Vector3 feet = body->get_global_position();
	double ground = F(rec["ground"]);
	Vector3 land = feet + mul(m, here + beyond);
	land.y = (real_t)(ground + top);
	Vector3 end = land + mul(m, out_run);
	const Vector3 spots[2] = { land, end };
	for (int k = 0; k < 2; k++) {
		if (!_fits(spots[k])) {
			return false;
		}
	}
	_plan = Dictionary();
	_plan["key"] = "run_up";
	_plan["from"] = V(D(feet.x), ground, D(feet.z));
	_plan["land"] = land;
	_plan["end"] = end;
	_plan["m"] = m;
	_plan["yaw0"] = _rot_y();
	_plan["yaw1"] = std::atan2(-D(m.x), -D(m.z));
	_plan["top"] = top;
	_plan["speed"] = speed;
	_plan["exit_speed"] = speed;
	plays += 1;
	_up_record = Dictionary();
	record = Dictionary();
	body->call("begin_move", Callable(this, "_run_up"), (String)RUN_UP["input"]);
	return true;
}

Dictionary TravTraverse::_run_up(double t) {
	Dictionary p = _plan;
	Vector3 m = p["m"];
	Dictionary out;
	out["done"] = false;
	out["yaw"] = lerp_angle(F(p["yaw0"]), F(p["yaw1"]), clampf(t / 0.15, 0.0, 1.0));
	if (t < RUN_UP_AIR) {
		double u = t / RUN_UP_AIR;
		Vector3 pos = lerp3((Vector3)p["from"], (Vector3)p["land"], u);
		pos.y = (real_t)(D(((Vector3)p["from"]).y) + F(p["top"]) * u + 4.0 * RUN_UP_ARC * u * (1.0 - u));
		out["pos"] = pos;
		out["clip_t"] = lerpf(F(RUN_UP["off"]), F(RUN_UP["land"]), u);
		out["air"] = true;
	} else {
		double rest = F(RUN_UP["exit"]) - F(RUN_UP["land"]);
		double u = clampf((t - RUN_UP_AIR) / rest, 0.0, 1.0);
		out["pos"] = lerp3((Vector3)p["land"], (Vector3)p["end"], u);
		out["clip_t"] = lerpf(F(RUN_UP["land"]), F(RUN_UP["exit"]), u);
		out["air"] = false;
		if (u >= 1.0) {
			out["done"] = true;
			out["exit"] = mul(m, F(p["exit_speed"]));
		}
	}
	return out;
}

// ------------------------------------------------------------------------------------------------ stage 10: the vault

bool TravTraverse::_try_vault(const Vector3 &v, const Vector3 &wish, Dictionary rec, double adds) {
	double top = F(rec["top"]);
	if (top == (double)INFINITY || top < F(VAULT_BAND[0]) - MEASURED_WITHIN || top > F(VAULT_BAND[1]) + adds + MEASURED_WITHIN) {
		return false;
	}
	if (!(bool)rec["thin"] || (bool)rec["blocked"]) {
		return false;
	}
	double speed = D(v.length());
	bool slow = D(wish.length()) <= F(body->get("WALK")) + 0.1 || speed <= RUN_FROM;
	if (slow && adds > 0.0) {
		return false;
	}
	if (slow && top <= JUMP_MOST + MEASURED_WITHIN) {
		return _try_tuck(v, wish, rec, true);
	}
	if (slow && speed < 0.5) {
		return _try_over(wish, rec);
	}
	Vector3 m = -(Vector3)rec["normal"];
	if (rad_to_deg(D(wish.normalized().angle_to(m))) > MOST_OFF_DEG) {
		refused = "not heading at it";
		return false;
	}
	if (!rec.has("landing") || absf(F(rec["landing"])) > LAND_LEVEL || !(bool)rec.get("landing_ok", false)) {
		refused = "the ground beyond it is not level with his, or has no room";
		return false;
	}
	double depth = F(rec["depth"]);
	double to_mid = D(((Vector3)rec["edge"] - body->get_global_position()).dot(m)) + depth * 0.5;
	double first_t = adds > 0.0 ? F(VAULT["off"]) : F(VAULT["from"]);
	double start = F(VAULT["at"]) - _at(_v_fwd, first_t);
	if (to_mid > start) {
		refused = "coming up to the vault";
		return false;
	}
	double from_t = first_t;
	while (from_t < (adds > 0.0 ? F(VAULT["hand_on"]) - 0.08 : F(VAULT["off"])) && F(VAULT["at"]) - _at(_v_fwd, from_t) > to_mid) {
		from_t += 1.0 / 60.0;
	}
	if (F(VAULT["at"]) - _at(_v_fwd, from_t) > to_mid + 0.08) {
		refused = "too near already to vault it";
		return false;
	}
	Vector3 feet = body->get_global_position();
	double ground = F(rec["ground"]);
	Vector3 mid = feet + mul(m, to_mid);
	mid.y = (real_t)ground;
	Vector3 land = mid + mul(m, _at(_v_fwd, F(VAULT["down"])) - F(VAULT["at"]));
	Vector3 end = mid + mul(m, _at(_v_fwd, F(VAULT["exit"])) - F(VAULT["at"]));
	const Vector3 spots[2] = { land, end };
	for (int k = 0; k < 2; k++) {
		Vector3 p = spots[k];
		Dictionary g = body->call("probe", p);
		if (!(bool)g["hit"] || absf(F(g["y"]) - ground) > LAND_LEVEL || !_fits(V(D(p.x), F(g["y"]), D(p.z)))) {
			refused = "no level, free ground to land on";
			return false;
		}
	}
	refused = "";
	double pace = slow ? VAULT_SLOW : clampf(speed / F(VAULT["speed"]), F(VAULT_PACE[0]), F(VAULT_PACE[1]));
	Vector3 left = UP.cross(m).normalized();
	bool mirror = false;
	Node *ch = body->get_node_or_null("Character");
	if (ch != nullptr && ch->has_method("_lead_now")) {
		mirror = F(ch->call("_lead_now")) < 0.0;
	}
	if (force_mirror >= 0) {
		mirror = force_mirror == 1;
	}
	if (mirror) {
		left = -left;
	}
	_plan = Dictionary();
	_plan["key"] = "vault";
	_plan["from"] = V(D(feet.x), ground, D(feet.z));
	_plan["mid"] = mid;
	_plan["end"] = V(D(end.x), ground, D(end.z));
	_plan["m"] = m;
	_plan["yaw0"] = _rot_y();
	_plan["yaw1"] = std::atan2(-D(m.x), -D(m.z));
	_plan["top"] = top;
	_plan["pace"] = pace;
	_plan["to_mid"] = to_mid;
	_plan["from_t"] = from_t;
	_plan["hand_at"] = V(D(mid.x), ground + top + PALM, D(mid.z)) - mul(m, 0.04) + mul(left, F(VAULT["hand_side"]));
	_plan["hand"] = mirror ? 1 : 0;
	_plan["exit_speed"] = F(VAULT["speed"]) * pace;
	if (adds > 0.0) {
		merge_new(_plan, "air", true);
		merge_new(_plan, "y_from", D(feet.y));
		merge_new(_plan, "hold_from", from_t + 0.17);
	}
	plays += 1;
	_up_record = Dictionary();
	record = Dictionary();
	body->call("begin_move", Callable(this, "_vault"), (String)VAULT["input"] + (mirror ? String("_m") : String("")));
	return true;
}

Dictionary TravTraverse::_vault(double t) {
	Dictionary p = _plan;
	Vector3 m = p["m"];
	double from_t = F(p["from_t"]);
	double exit_t = F(VAULT["exit"]);
	double ct = minf(from_t + t * F(p["pace"]), exit_t);
	double z = _at(_v_fwd, ct) - F(VAULT["at"]);
	double out_by = F(p["to_mid"]) - (F(VAULT["at"]) - _at(_v_fwd, from_t));
	if (z < 0.0) {
		z -= out_by * clampf(z / minf(_at(_v_fwd, from_t) - F(VAULT["at"]), -0.01), 0.0, 1.0);
	}
	Vector3 pos = (Vector3)p["mid"] + mul(m, z);
	bool air = ct >= F(VAULT["off"]) && ct < F(VAULT["down"]);
	bool higher = F(p["top"]) > F(VAULT["high"]);
	double over = 0.0;
	if (ct >= F(VAULT["off"]) - LIFT_EARLY && ct < F(VAULT["down"])) {
		double up = higher ? smoothstep(F(VAULT["off"]) - LIFT_EARLY, F(VAULT["off"]) + LIFT_EARLY, ct) : smoothstep(F(VAULT["off"]), F(VAULT["hand_on"]), ct);
		over = minf(up, 1.0 - smoothstep(F(VAULT["hand_off"]), F(VAULT["down"]), ct));
	}
	double more = higher ? CLEAR_MORE * (1.0 - smoothstep(F(VAULT["hand_on"]) - 0.07, F(VAULT["hand_on"]), ct)) : 0.0;
	pos.y = (real_t)(D(pos.y) + (F(p["top"]) - F(VAULT["high"]) + more) * over);
	if (p.has("y_from")) {
		pos.y = (real_t)lerpf(F(p["y_from"]), D(pos.y), smoothstep(from_t, maxf(F(VAULT["hand_on"]) - HAND_FADE, from_t + 0.02), ct));
	}
	double hold = clampf(minf((ct - maxf(F(VAULT["hand_on"]), F(p.get("hold_from", 0.0)))) / HAND_FADE + 1.0, (F(VAULT["hand_off"]) - ct) / HAND_FADE + 1.0), 0.0, 1.0);
	hold = hold * hold * (3.0 - 2.0 * hold);
	Dictionary out;
	out["done"] = ct >= exit_t;
	out["pos"] = pos;
	out["clip_t"] = ct;
	out["air"] = air;
	out["free"] = true;
	out["yaw"] = lerp_angle(F(p["yaw0"]), F(p["yaw1"]), clampf(t / 0.15, 0.0, 1.0));
	Array hand;
	hand.append((int64_t)p["hand"]);
	hand.append(p["hand_at"]);
	hand.append(hold);
	out["hand"] = hand;
	if (ct >= exit_t) {
		out["pos"] = p["end"];
		out["exit"] = mul(m, F(p["exit_speed"]));
	}
	return out;
}

Array TravTraverse::_hands(const Vector3 &on_top, const Vector3 &left, double side, Dictionary rec) {
	double l = clampf(F(rec.get("width_left", (double)INFINITY)) - HAND_IN, HAND_LEAST, side);
	double r = clampf(F(rec.get("width_right", (double)INFINITY)) - HAND_IN, HAND_LEAST, side);
	Array out;
	out.append(on_top + mul(left, l));
	out.append(on_top - mul(left, r));
	return out;
}

// the two hands' holds, as the moves hand them to the body: [[0, place, hold], [1, place, hold]]
static Array two_hands(const Variant &hands_at, double hold) {
	Array at = hands_at;
	Array l;
	l.append((int64_t)0);
	l.append(at[0]);
	l.append(hold);
	Array r;
	r.append((int64_t)1);
	r.append(at[1]);
	r.append(hold);
	Array out;
	out.append(l);
	out.append(r);
	return out;
}

bool TravTraverse::_try_tuck(const Vector3 &v, const Vector3 &wish, Dictionary rec, bool low) {
	double top = F(rec["top"]);
	Vector3 m = -(Vector3)rec["normal"];
	if (rad_to_deg(D(wish.normalized().angle_to(m))) > MOST_OFF_DEG) {
		refused = "not heading at it";
		return false;
	}
	if (!rec.has("landing") || absf(F(rec["landing"])) > LAND_LEVEL || !(bool)rec.get("landing_ok", false)) {
		refused = "the ground beyond it is not level with his, or has no room";
		return false;
	}
	Dictionary mv = low ? JUMP : TUCK;
	PackedFloat32Array fwd = low ? _j_fwd : _t_fwd;
	double depth = F(rec["depth"]);
	double to_mid = D(((Vector3)rec["edge"] - body->get_global_position()).dot(m)) + depth * 0.5;
	double from_t = F(mv["from"]);
	double reach = low ? 0.75 : F(mv["at"]) - _at(fwd, from_t) + 0.05;
	if (to_mid > reach) {
		refused = "coming up to it";
		return false;
	}
	if (!low) {
		while (from_t < F(mv["hands_on"]) - 0.1 && F(mv["at"]) - _at(fwd, from_t) > to_mid) {
			from_t += 1.0 / 60.0;
		}
	}
	Vector3 feet = body->get_global_position();
	double ground = F(rec["ground"]);
	Vector3 mid = feet + mul(m, to_mid);
	mid.y = (real_t)ground;
	Vector3 end = mid + mul(m, low ? BEYOND : _at(fwd, F(mv["exit"])) - F(mv["at"]));
	Dictionary g = body->call("probe", end);
	if (!(bool)g["hit"] || absf(F(g["y"]) - ground) > LAND_LEVEL || !_fits(V(D(end.x), F(g["y"]), D(end.z)))) {
		refused = "no level, free ground to land on";
		return false;
	}
	refused = "";
	Vector3 left = UP.cross(m).normalized();
	Vector3 on_top = V(D(mid.x), ground + top + PALM, D(mid.z)) - mul(m, depth * 0.5 - 0.04);
	_plan = Dictionary();
	_plan["key"] = low ? "vault_jump" : "vault_tuck";
	_plan["low"] = low;
	_plan["from"] = V(D(feet.x), ground, D(feet.z));
	_plan["mid"] = mid;
	_plan["end"] = V(D(end.x), ground, D(end.z));
	_plan["m"] = m;
	_plan["yaw0"] = _rot_y();
	_plan["yaw1"] = std::atan2(-D(m.x), -D(m.z));
	_plan["top"] = top;
	_plan["to_mid"] = to_mid;
	_plan["from_t"] = from_t;
	_plan["hand"] = low ? -1 : 2;
	_plan["exit_speed"] = 0.0;
	_plan["hands_at"] = _hands(on_top, left, F(TUCK["hand_side"]), rec);
	plays += 1;
	_up_record = Dictionary();
	record = Dictionary();
	body->call("begin_move", Callable(this, "_tuck"), (String)mv["input"]);
	return true;
}

Dictionary TravTraverse::_tuck(double t) {
	Dictionary p = _plan;
	bool low = p["low"];
	Dictionary mv = low ? JUMP : TUCK;
	PackedFloat32Array fwd = low ? _j_fwd : _t_fwd;
	Vector3 m = p["m"];
	double from_t = F(p["from_t"]);
	double exit_t = F(mv["exit"]);
	double ct = minf(from_t + t, exit_t);
	bool air = ct >= F(mv["off"]) && ct < F(mv["down"]);
	Vector3 pos;
	if (low) {
		if (ct <= F(mv["top"])) {
			pos = lerp3((Vector3)p["from"], (Vector3)p["mid"], clampf((ct - F(mv["off"])) / (F(mv["top"]) - F(mv["off"])), 0.0, 1.0));
		} else {
			pos = lerp3((Vector3)p["mid"], (Vector3)p["end"], clampf((ct - F(mv["top"])) / (F(mv["down"]) - F(mv["top"])), 0.0, 1.0));
		}
	} else {
		double z = _at(fwd, ct) - F(mv["at"]);
		double out_by = F(p["to_mid"]) - (F(mv["at"]) - _at(fwd, from_t));
		if (z < 0.0) {
			z -= out_by * clampf(z / minf(_at(fwd, from_t) - F(mv["at"]), -0.01), 0.0, 1.0);
		}
		pos = (Vector3)p["mid"] + mul(m, z);
	}
	double more = maxf(F(p["top"]) - F(mv["high"]), 0.0);
	if (more > 0.0) {
		more += CLEAR_MORE;
	}
	if (air) {
		pos.y = (real_t)(D(pos.y) + more * minf(smoothstep(F(mv["off"]), F(mv["off"]) + 0.12, ct), 1.0 - smoothstep(F(mv["top"]) + 0.2, F(mv["down"]), ct)));
	}
	Dictionary out;
	out["done"] = ct >= exit_t;
	out["pos"] = pos;
	out["clip_t"] = ct;
	out["air"] = air;
	out["free"] = air;
	out["yaw"] = lerp_angle(F(p["yaw0"]), F(p["yaw1"]), clampf(t / 0.2, 0.0, 1.0));
	if (!low) {
		double hold = clampf(minf((ct - F(mv["hands_on"])) / HAND_FADE + 1.0, (F(mv["hands_off"]) - ct) / HAND_FADE + 1.0), 0.0, 1.0);
		hold = hold * hold * (3.0 - 2.0 * hold);
		out["hand"] = two_hands(p["hands_at"], hold);
	}
	if (ct >= exit_t) {
		out["pos"] = p["end"];
		out["exit"] = ZERO;
	}
	return out;
}

// ------------------------------------------------------------------------- the climb over a thin wall from standing

bool TravTraverse::_try_over(const Vector3 &wish, Dictionary rec, double air_ct) {
	double top = F(rec["top"]);
	Vector3 m = -(Vector3)rec["normal"];
	if (rad_to_deg(D(wish.normalized().angle_to(m))) > MOST_OFF_DEG) {
		refused = "not heading at it";
		return false;
	}
	if (!rec.has("landing") || absf(F(rec["landing"])) > LAND_LEVEL || !(bool)rec.get("landing_ok", false)) {
		refused = "the ground beyond it is not level with his, or has no room";
		return false;
	}
	double depth = F(rec["depth"]);
	double here = D(((Vector3)rec["edge"] - body->get_global_position()).dot(m));
	if (air_ct < 0.0 && here > OVER_NEAR) {
		refused = "coming up to it";
		return false;
	}
	Vector3 feet = body->get_global_position();
	double ground = F(rec["ground"]);
	Vector3 mid = feet + mul(m, here + depth * 0.5);
	mid.y = (real_t)(ground + top);
	Vector3 back = V(D(feet.x), ground, D(feet.z)) - mul(m, maxf(OVER_BACK + (air_ct >= 0.0 ? 0.05 : 0.0) - here, 0.0));
	if (air_ct < 0.0 && !_fits(back)) {
		refused = "no room behind him to jump up from";
		return false;
	}
	Dictionary mv = MOVES["walk"];
	PackedFloat32Array fwd = _fwd["walk"];
	Vector3 leave = mid + mul(m, depth * 0.5 + 0.15);
	Vector3 down = leave + mul(m, _at(fwd, F(mv["down"])) - _at(fwd, F(mv["leaves"])));
	Vector3 end = down + mul(m, _at(fwd, F(mv["exit"])) - _at(fwd, F(mv["down"])));
	const Vector3 spots[2] = { down, end };
	for (int k = 0; k < 2; k++) {
		Vector3 p = spots[k];
		Dictionary g = body->call("probe", V(D(p.x), ground, D(p.z)));
		if (!(bool)g["hit"] || absf(F(g["y"]) - ground) > LAND_LEVEL || !_fits(V(D(p.x), F(g["y"]), D(p.z)))) {
			refused = "no level, free ground to land on";
			return false;
		}
	}
	refused = "";
	double share = clampf(top / F(mv["native"]), 0.0, 1.0);
	Vector3 left = UP.cross(m).normalized();
	Vector3 on_top = V(D(mid.x), ground + top + PALM, D(mid.z)) - mul(m, depth * 0.5 - 0.01);
	_plan = Dictionary();
	_plan["key"] = "climb_over";
	_plan["drop_key"] = "walk";
	_plan["a_from"] = V(D(feet.x), ground, D(feet.z));
	_plan["a_back"] = back;
	_plan["a_yaw0"] = _rot_y();
	_plan["mid"] = mid;
	_plan["top"] = top;
	_plan["ground"] = ground;
	_plan["from"] = mid;
	_plan["leave"] = V(D(leave.x), ground + top, D(leave.z));
	_plan["down"] = V(D(down.x), ground, D(down.z));
	_plan["end"] = V(D(end.x), ground, D(end.z));
	_plan["m"] = m;
	_plan["yaw0"] = std::atan2(-D(m.x), -D(m.z));
	_plan["yaw1"] = std::atan2(-D(m.x), -D(m.z));
	_plan["drop"] = top;
	_plan["t_step"] = F(mv["leaves"]) - F(mv["from"]);
	_plan["t_air"] = std::sqrt(2.0 * top / F(body->get("GRAVITY")));
	_plan["t_rest"] = (F(mv["exit"]) - F(mv["down"])) * lerpf(REST_LEAST, 1.0, share);
	_plan["soft"] = 1.0 - share;
	_plan["exit_speed"] = (_at(fwd, F(mv["exit"])) - _at(fwd, F(mv["exit"]) - 0.2)) / 0.2;
	_plan["hand"] = 2;
	_plan["hands_at"] = _hands(on_top, left, F(OVER["hand_side"]), rec);
	if (air_ct >= 0.0) {
		merge_new(_plan, "air", true);
		merge_new(_plan, "from_t", air_ct);
		merge_new(_plan, "hands_on", air_ct);
		merge_new(_plan, "y_from", D(feet.y));
	}
	plays += 1;
	_up_record = Dictionary();
	record = Dictionary();
	body->call("begin_move", Callable(this, "_over"), (String)OVER["input"]);
	return true;
}

Dictionary TravTraverse::_over(double t) {
	Dictionary p = _plan;
	double from_t = F(p.get("from_t", OVER["from"]));
	double top_t = F(OVER["top"]);
	if (t >= top_t - from_t) {
		if (!p.has("a_done")) {
			p["a_done"] = true;
			p["from"] = body->get_global_position();
			p["stay"] = !(bool)body->get("stick_held");
		}
		if ((bool)p["stay"]) {
			double cs = minf(from_t + t, F(MANTLE["exit"]));
			Vector3 mid_s = p["mid"];
			Vector3 here_s = V(D(mid_s.x), _climb_y(p, cs, t), D(mid_s.z));
			bool done_s = cs >= F(MANTLE["exit"]);
			Dictionary out_s;
			out_s["done"] = done_s;
			out_s["pos"] = done_s ? mid_s : here_s;
			out_s["clip_t"] = cs;
			out_s["clip"] = (String)OVER["input"];
			out_s["air"] = false;
			out_s["free"] = false;
			out_s["base"] = F(p["ground"]) + F(p["top"]) - D(here_s.y);
			out_s["yaw"] = F(p["yaw1"]);
			if (done_s) {
				out_s["exit"] = ZERO;
			}
			return out_s;
		}
		Dictionary r = _step_off(t - (top_t - from_t));
		r["clip"] = (String)((Dictionary)MOVES["walk"])["input"];
		return r;
	}
	double ct = from_t + t;
	double u = smoothstep(F(OVER_ACROSS[0]), F(OVER_ACROSS[1]), ct);
	Vector3 a = lerp3((Vector3)p["a_from"], (Vector3)p["a_back"], smoothstep(0.0, 0.2, t));
	Vector3 mid = p["mid"];
	Vector3 pos = V(lerpf(D(a.x), D(mid.x), u), _climb_y(p, ct, t), lerpf(D(a.z), D(mid.z), u));
	double hold = clampf(minf((ct - F(p.get("hands_on", OVER["hands_on"]))) / HAND_FADE + 1.0, (F(OVER["hands_off"]) - ct) / HAND_FADE + 1.0), 0.0, 1.0);
	hold = hold * hold * (3.0 - 2.0 * hold);
	Dictionary out;
	out["done"] = false;
	out["pos"] = pos;
	out["clip_t"] = ct;
	out["clip"] = (String)OVER["input"];
	out["air"] = false;
	out["free"] = ct > 1.25 && ct < FEET_FROM;
	out["base"] = ct >= FEET_FROM ? F(p["ground"]) + F(p["top"]) - D(pos.y) : 0.0;
	out["yaw"] = lerp_angle(F(p["a_yaw0"]), F(p["yaw1"]), clampf(t / 0.2, 0.0, 1.0));
	out["hand"] = two_hands(p["hands_at"], hold);
	return out;
}

// ------------------------------------------------------------------------------------------------ stage 12: the mantle

bool TravTraverse::_try_mantle(const Vector3 &v, const Vector3 &wish, Dictionary rec, double air_ct) {
	double top = F(rec["top"]);
	if ((bool)rec["blocked"] || !(bool)rec["stand_room"]) {
		refused = "no room to stand on top";
		return false;
	}
	Vector3 m = -(Vector3)rec["normal"];
	if (rad_to_deg(D(wish.normalized().angle_to(m))) > MOST_OFF_DEG) {
		refused = "not heading at it";
		return false;
	}
	double here = D(((Vector3)rec["edge"] - body->get_global_position()).dot(m));
	bool moving = D(v.length()) > 0.5 && air_ct < 0.0;
	double exit_t = F(MANTLE["exit"]);
	double edge_at = F(MANTLE["edge"]);
	double from_t = F(OVER["from"]);
	double hands_on = F(OVER["hands_on"]);
	if (moving && here > OVER_NEAR) {
		if (here > edge_at - _at(_o_fwd, 0.0) + D(v.length()) * EARLY) {
			refused = "coming up to the mantle";
			return false;
		}
		if (here < edge_at - _at(_o_fwd, from_t) - 0.05) {
			refused = "coming up to it";
			return false;
		}
		from_t = 0.0;
		while (from_t < F(OVER["from"]) && edge_at - _at(_o_fwd, from_t) > here) {
			from_t += 1.0 / 60.0;
		}
		hands_on = from_t;
		while (hands_on < F(OVER["hands_off"]) && here - (_at(_o_fwd, hands_on) - _at(_o_fwd, from_t)) > OVER_BACK + 0.02) {
			hands_on += 1.0 / 60.0;
		}
	} else if (moving) {
		moving = false;
	} else if (air_ct < 0.0 && here > OVER_NEAR) {
		refused = "coming up to it";
		return false;
	}
	double inward = _at(_o_fwd, exit_t) - edge_at;
	if (F(rec["depth"]) < inward + F(body->get("RADIUS"))) {
		refused = "the top is not deep enough to stand on";
		return false;
	}
	Vector3 feet = body->get_global_position();
	double ground = F(rec["ground"]);
	Vector3 end = feet + mul(m, here + inward);
	end.y = (real_t)(ground + top);
	if (!_fits(end)) {
		refused = "no room where he would end";
		return false;
	}
	Vector3 back = V(D(feet.x), ground, D(feet.z)) + mul(m, here - OVER_BACK - (air_ct >= 0.0 ? 0.05 : 0.0));
	if (air_ct >= 0.0) {
		from_t = air_ct;
		hands_on = air_ct;
	}
	if (air_ct < 0.0 && !moving && here < OVER_BACK && !_fits(back)) {
		refused = "no room behind him to jump up from";
		return false;
	}
	double run_v = (air_ct < 0.0 && D(wish.length()) > F(body->get("WALK")) + 0.1 && D(v.length()) > RUN_FROM) ? D(v.length()) : 0.0;
	Array ro = RUN_OUT["mantle"];
	double run_d = run_v * (F(ro[1]) - F(ro[0])) * 0.5;
	if (run_v > 0.0 && (F(rec["depth"]) < inward + run_d + F(body->get("RADIUS")) + 0.5 || !_fits(end + mul(m, run_d)))) {
		run_v = 0.0;
	}
	if (run_v > 0.0) {
		end += mul(m, run_d);
	}
	refused = "";
	Vector3 left = UP.cross(m).normalized();
	Vector3 on_top = feet + mul(m, here + 0.04);
	on_top.y = (real_t)(ground + top + PALM);
	_plan = Dictionary();
	_plan["key"] = "mantle";
	_plan["moving"] = moving;
	_plan["a_from"] = V(D(feet.x), ground, D(feet.z));
	_plan["a_back"] = back;
	_plan["a_yaw0"] = _rot_y();
	_plan["end"] = end;
	_plan["top"] = top;
	_plan["ground"] = ground;
	_plan["m"] = m;
	_plan["yaw1"] = std::atan2(-D(m.x), -D(m.z));
	_plan["here"] = here;
	_plan["from_t"] = from_t;
	_plan["exit_speed"] = run_v;
	_plan["run_d"] = run_v > 0.0 ? run_d : 0.0;
	_plan["hand"] = 2;
	_plan["hands_on"] = hands_on;
	_plan["hands_at"] = _hands(on_top, left, F(OVER["hand_side"]), rec);
	if (air_ct >= 0.0) {
		merge_new(_plan, "air", true);
		merge_new(_plan, "y_from", D(feet.y));
	}
	plays += 1;
	_up_record = Dictionary();
	record = Dictionary();
	body->call("begin_move", Callable(this, "_mantle"), (String)OVER["input"]);
	return true;
}

Dictionary TravTraverse::_mantle(double t) {
	Dictionary p = _plan;
	Vector3 m = p["m"];
	double from_t = F(p["from_t"]);
	double run_d = F(p.get("run_d", 0.0));
	Array ro = RUN_OUT["mantle"];
	Array across = MANTLE["across"];
	double exit_t = run_d > 0.0 ? F(ro[1]) : F(MANTLE["exit"]);
	double ct = minf(from_t + t, exit_t);
	Vector3 a = p["a_from"];
	Vector3 end = (Vector3)p["end"] - mul(m, run_d);
	Vector3 pos;
	double on = F(p["hands_on"]);
	Vector3 back = p["a_back"];
	if ((bool)p["moving"]) {
		back = a + mul(m, minf(_at(_o_fwd, ct) - _at(_o_fwd, from_t), F(p["here"]) - OVER_BACK));
	} else {
		back = lerp3(a, back, smoothstep(0.0, 0.2, t));
	}
	pos = lerp3(back, end, smoothstep(F(across[0]), F(across[1]), ct));
	if (run_d > 0.0) {
		double gather = clampf((ct - F(ro[0])) / (F(ro[1]) - F(ro[0])), 0.0, 1.0);
		pos += mul(m, run_d * gather * gather);
	}
	pos.y = (real_t)_climb_y(p, ct, t);
	if (run_d > 0.0) {
		double g2 = clampf((ct - F(ro[0])) / (F(ro[1]) - F(ro[0])), 0.0, 1.0);
		pos.y = (real_t)lerpf(D(pos.y), F(p["ground"]) + F(p["top"]), g2 * g2);
	}
	double hold = clampf(minf((ct - on) / HAND_FADE + 1.0, (F(OVER["hands_off"]) - ct) / HAND_FADE + 1.0), 0.0, 1.0);
	hold = hold * hold * (3.0 - 2.0 * hold);
	Dictionary out;
	out["done"] = ct >= exit_t;
	out["pos"] = pos;
	out["clip_t"] = ct;
	out["air"] = false;
	out["free"] = ct > 1.25 && ct < FEET_FROM;
	out["base"] = ct >= FEET_FROM ? F(p["ground"]) + F(p["top"]) - D(pos.y) : 0.0;
	out["yaw"] = lerp_angle(F(p["a_yaw0"]), F(p["yaw1"]), clampf(t / 0.2, 0.0, 1.0));
	out["hand"] = two_hands(p["hands_at"], hold);
	if (ct >= exit_t) {
		out["pos"] = p["end"];
		out["exit"] = mul(m, F(p["exit_speed"]));
	}
	return out;
}

double TravTraverse::_climb_y(Dictionary p, double ct, double t) {
	double rise = _at(_o_rise, ct);
	double top = F(p["top"]);
	double y = F(p["ground"]) + lerpf(top * rise, top - _o_high * (1.0 - rise), smoothstep(F(OVER["from"]), F(OVER["hands_off"]), ct));
	if (p.has("y_from")) {
		y = lerpf(F(p["y_from"]), y, smoothstep(0.0, 0.2, t));
	}
	return y;
}

// ------------------------------------------------------------------------------- a jump into a climb or over a wall

bool TravTraverse::_try_air(const Vector3 &v) {
	Vector3 wish = body->get("_wish");
	if (!(bool)body->get("from_jump")) {
		return false;
	}
	if (_tick % 2 != 0) {
		return false;
	}
	Vector3 dir = D(wish.length()) >= 0.05 ? wish.normalized() : (D(v.length()) >= 0.5 ? v.normalized() : -body->get_global_transform().basis.get_column(2));
	dir = V(D(dir.x), 0.0, D(dir.z)).normalized();
	Vector3 here_p = body->get_global_position();
	TypedArray<RID> ex;
	ex.append(body->get_rid());
	Ref<PhysicsRayQueryParameters3D> q_down = PhysicsRayQueryParameters3D::create(here_p + V(0.0, 0.6, 0.0), here_p - V(0.0, 6.0, 0.0), body->get_collision_mask(), ex);
	Dictionary below = body->get_world_3d()->get_direct_space_state()->intersect_ray(q_down);
	double under_y = !below.is_empty() ? D(((Vector3)below["position"]).y) : D(here_p.y) - 3.0;
	Dictionary rec = det()->call("measure", dir, under_y);
	if ((String)rec["kind"] != "obstacle" || (bool)rec["blocked"] || F(rec["top"]) == (double)INFINITY) {
		return false;
	}
	Vector3 m = -(Vector3)rec["normal"];
	if (rad_to_deg(D(dir.angle_to(m))) > MOST_OFF_DEG) {
		return false;
	}
	double top = F(rec["top"]);
	double feet_up = D(body->get_global_position().y) - F(rec["ground"]);
	double left = top - feet_up;
	if (left <= 0.05) {
		return false;
	}
	double here = D(((Vector3)rec["edge"] - body->get_global_position()).dot(m));
	if ((bool)rec["thin"] && !(bool)body->get("_jump_still") && D(v.length()) > RUN_FROM) {
		if (_try_vault(v, D(wish.length()) >= 0.05 ? wish : v, rec, F(body->get("JUMP_RISE_RUN")))) {
			return true;
		}
	}
	if (here > OVER_BACK + 0.05 || F(body->get("vy")) > 0.5) {
		return false;
	}
	bool thin = rec["thin"];
	double adds = F((bool)body->get("_jump_still") ? body->get("JUMP_RISE") : body->get("JUMP_RISE_RUN"));
	if (feet_up < adds * 0.5) {
		return false;
	}
	if (top > F(thin ? VAULT_BAND[1] : MANTLE_BAND[1]) + adds + MEASURED_WITHIN) {
		if (top > minf(F(HIGH_BAND[1]) + adds, NOT_ABOVE) + MEASURED_WITHIN) {
			refused = vformat("too high even with the jump (%.2f m)", top);
			return false;
		}
		return _try_grab(dir, rec, true);
	}
	if (top > F(thin ? VAULT_BAND[1] : MANTLE_BAND[1]) + adds + MEASURED_WITHIN) {
		refused = vformat("too high even with the jump (%.2f m)", top);
		return false;
	}
	double ct = F(OVER["from"]);
	bool begun = thin ? _try_over(dir, rec, ct) : _try_mantle(v, dir, rec, ct);
	return begun;
}

// ------------------------------------------------------------------------------------------ stage 13: the grab and climb

bool TravTraverse::_try_grab(const Vector3 &wish, Dictionary rec, bool air) {
	double top = F(rec["top"]);
	bool thin = rec["thin"];
	if ((bool)rec["blocked"] || (!thin && !(bool)rec["stand_room"])) {
		refused = "no room on top";
		return false;
	}
	if (thin && (!rec.has("landing") || absf(F(rec["landing"])) > LAND_LEVEL || !(bool)rec.get("landing_ok", false))) {
		refused = "the ground beyond it is not level with his, or has no room";
		return false;
	}
	Vector3 m = -(Vector3)rec["normal"];
	if (rad_to_deg(D(wish.normalized().angle_to(m))) > MOST_OFF_DEG) {
		refused = "not heading at it";
		return false;
	}
	double here = D(((Vector3)rec["edge"] - body->get_global_position()).dot(m));
	if (here > GRAB_NEAR) {
		refused = "coming up to it";
		return false;
	}
	Vector3 feet = body->get_global_position();
	double ground = F(rec["ground"]);
	Vector3 hang = V(D(feet.x), ground, D(feet.z)) + mul(m, here - F(GRAB["hang_at"]));
	if (!air && here < F(GRAB["hang_at"]) && !_fits(hang)) {
		refused = "no room behind him to jump up from";
		return false;
	}
	double inward = _at(_g_fwd2, F(GRAB["exit"])) - F(GRAB["hang_at"]);
	if (!thin && F(rec["depth"]) < inward + F(body->get("RADIUS"))) {
		refused = "the top is not deep enough";
		return false;
	}
	double onto = thin ? F(rec["depth"]) * 0.5 : inward;
	Vector3 end = feet + mul(m, here + onto);
	end.y = (real_t)(ground + top);
	if (!thin && !_fits(end, "CROUCH_HEIGHT")) {
		refused = "no room where he would end";
		return false;
	}
	Vector3 v_in = body->get("hvel");
	Vector3 w_in = body->get("_wish");
	double run_v = (!air && !thin && D(w_in.length()) > F(body->get("WALK")) + 0.1 && D(v_in.length()) > RUN_FROM) ? D(v_in.length()) : 0.0;
	Array ro = RUN_OUT["grab"];
	double run_d = run_v * (F(ro[1]) - F(ro[0])) * 0.5;
	if (run_v > 0.0 && (F(rec["depth"]) < inward + run_d + F(body->get("RADIUS")) + 0.5 || !_fits(end + mul(m, run_d)))) {
		run_v = 0.0;
	}
	if (run_v > 0.0) {
		end += mul(m, run_d);
	}
	refused = "";
	Vector3 left = UP.cross(m).normalized();
	Vector3 on_top = feet + mul(m, here + WRIST_IN);
	on_top.y = (real_t)(ground + top + WRIST_OVER);
	_plan = Dictionary();
	_plan["key"] = "grab";
	_plan["from"] = V(D(feet.x), ground, D(feet.z));
	_plan["hang"] = hang;
	_plan["end"] = end;
	_plan["top"] = top;
	_plan["ground"] = ground;
	_plan["m"] = m;
	_plan["yaw0"] = _rot_y();
	_plan["yaw1"] = std::atan2(-D(m.x), -D(m.z));
	_plan["exit_speed"] = run_v;
	_plan["run_d"] = run_v > 0.0 ? run_d : 0.0;
	_plan["hand"] = 2;
	_plan["onto_more"] = onto - inward;
	_plan["hang_y"] = ground + top + WRIST_OVER - F(GRAB["wrist"]) + F(GRAB["jump_by"]);
	_plan["from_t"] = air ? F(GRAB["off"]) + 0.08 : 0.0;
	_plan["hands_at"] = _hands(on_top, left, F(GRAB["hand_side"]), rec);
	if (thin) {
		Vector3 leave = feet + mul(m, here + F(rec["depth"]) + 0.22);
		leave.y = (real_t)(ground + top);
		merge_new(_plan, "over", true);
		merge_new(_plan, "leave", leave);
	}
	if (air) {
		merge_new(_plan, "air", true);
		merge_new(_plan, "y_from", D(feet.y));
	}
	plays += 1;
	_up_record = Dictionary();
	record = Dictionary();
	body->call("begin_move", Callable(this, "_grab"), (String)GRAB["jump"]);
	return true;
}

// the two hands' holds with the grip turned: [[0, place, hold, true], [1, place, hold, true]]
static Array two_hands_grip(const Variant &hands_at, const Vector3 &grip, double hold) {
	Array at = hands_at;
	Array l;
	l.append((int64_t)0);
	l.append((Vector3)at[0] + grip);
	l.append(hold);
	l.append(true);
	Array r;
	r.append((int64_t)1);
	r.append((Vector3)at[1] + grip);
	r.append(hold);
	r.append(true);
	Array out;
	out.append(l);
	out.append(r);
	return out;
}

Dictionary TravTraverse::_grab(double t) {
	Dictionary p = _plan;
	Vector3 m = p["m"];
	double from_t = F(p["from_t"]);
	double t1 = F(GRAB["hang"]) - from_t;
	double ground = F(p["ground"]);
	Vector3 hang = p["hang"];
	double hold = 0.0;
	Dictionary out;
	out["done"] = false;
	out["air"] = true;
	out["free"] = true;
	out["yaw"] = lerp_angle(F(p["yaw0"]), F(p["yaw1"]), clampf(t / 0.2, 0.0, 1.0));
	if (t < t1) {
		double ct = from_t + t;
		Vector3 pos = lerp3((Vector3)p["from"], hang, smoothstep(0.0, 0.15, t));
		pos.y = (real_t)(ground + (F(p["hang_y"]) - ground) * _at(_g_rise1, ct));
		if (p.has("y_from")) {
			pos.y = (real_t)lerpf(F(p["y_from"]), D(pos.y), smoothstep(0.0, F(GRAB["catch"]) - from_t, t));
		}
		// (Dictionary.merge without overwrite: "air" stays as it was set above)
		merge_new(out, "pos", pos);
		merge_new(out, "clip_t", ct);
		merge_new(out, "clip", (String)GRAB["jump"]);
		merge_new(out, "air", ct >= F(GRAB["off"]));
		hold = clampf((ct - F(GRAB["catch"])) / HAND_FADE + 1.0, 0.0, 1.0);
	} else {
		double ct = minf(t - t1, F(GRAB["exit"]));
		double rise = _at(_g_rise2, ct);
		double by = F(GRAB["climb_by"]);
		double out_by = by + WRIST_OVER - F(GRAB["climb_wrist"]);
		double run_d = F(p.get("run_d", 0.0));
		Array ro = RUN_OUT["grab"];
		double gather = clampf((ct - F(ro[0])) / (F(ro[1]) - F(ro[0])), 0.0, 1.0);
		Vector3 pos = hang + mul(m, _at(_g_fwd2, ct) + run_d * gather * gather + F(p.get("onto_more", 0.0)) * smoothstep(F(GRAB["feet_on"]), F(GRAB["exit"]), ct));
		pos.y = (real_t)(ground + F(p["top"]) - (by - out_by) * (1.0 - rise));
		bool feet_down = ct >= F(GRAB["feet_on"]);
		out["pos"] = pos;
		out["clip_t"] = ct;
		out["clip"] = (String)GRAB["climb"];
		out["free"] = !feet_down;
		out["base"] = feet_down ? ground + F(p["top"]) - D(pos.y) : 0.0;
		hold = clampf((F(GRAB["feet_on"]) - ct) / HAND_FADE + 1.0, 0.0, 1.0);
		if (ct >= F(GRAB["exit"]) && (bool)p.get("over", false) && !p.has("stay")) {
			p["stay"] = !(bool)body->get("stick_held");
		}
		if (ct >= F(GRAB["exit"]) && (bool)p.get("over", false) && !(bool)p["stay"]) {
			Dictionary mv = MOVES["walk"];
			double span = F(mv["leaves"]) - F(mv["from"]);
			double u = clampf((t - t1 - F(GRAB["exit"])) / span, 0.0, 1.0);
			out["pos"] = lerp3((Vector3)p["end"], (Vector3)p["leave"], u);
			out["clip"] = (String)mv["input"];
			out["clip_t"] = lerpf(F(mv["from"]), F(mv["leaves"]), u);
			out["air"] = false;
			out["free"] = false;
			out["landed"] = true;
			if (u >= 1.0) {
				PackedFloat32Array wf = _fwd["walk"];
				out["done"] = true;
				out["exit"] = mul(m, (_at(wf, F(mv["leaves"])) - _at(wf, F(mv["from"]))) / span);
			}
		} else if (ct >= F(GRAB["exit"]) && F(p.get("run_d", 0.0)) <= 0.0) {
			double u = clampf((t - t1 - F(GRAB["exit"])) / STAND_UP_TIME, 0.0, 1.0);
			out["pos"] = p["end"];
			out["clip"] = "crouch_up";
			out["clip_t"] = lerpf(F(STAND_UP[0]), F(STAND_UP[1]), u);
			out["air"] = false;
			out["free"] = false;
			out["landed"] = true;
			out["base"] = 0.0;
			if (u >= 1.0) {
				out["done"] = true;
				out["exit"] = ZERO;
			}
		} else if (ct >= F(GRAB["exit"])) {
			out["done"] = true;
			out["air"] = false;
			out["pos"] = p["end"];
			out["exit"] = mul(m, F(p["exit_speed"]));
		}
	}
	hold = hold * hold * (3.0 - 2.0 * hold);
	Vector3 grip = mul(-m, (GRIP_OUT + WRIST_IN) * (1.0 - (t >= t1 ? smoothstep(F(GRIP_TURN[0]), F(GRIP_TURN[1]), t - t1) : 0.0)));
	out["hand"] = two_hands_grip(p["hands_at"], grip, hold);
	return out;
}

// -------------------------------------------------------------------------------------------- the running wall climb

bool TravTraverse::_try_wallrun(const Vector3 &v, const Vector3 &wish, Dictionary rec) {
	double top = F(rec["top"]);
	if ((bool)rec["blocked"] || !(bool)rec["stand_room"]) {
		return false;
	}
	Vector3 m = -(Vector3)rec["normal"];
	if (rad_to_deg(D(wish.normalized().angle_to(m))) > MOST_OFF_DEG) {
		return false;
	}
	double here = D(((Vector3)rec["edge"] - body->get_global_position()).dot(m));
	double face = F(WALLRUN["face"]);
	double least = face - _at(_w_fwd, F(WALLRUN["from_most"]));
	if (here > face - _at(_w_fwd, 0.0) + D(v.length()) * EARLY) {
		refused = "coming up to the wall climb";
		return false;
	}
	if (here < least - 0.15) {
		return false;
	}
	double from_t = 0.0;
	while (from_t < F(WALLRUN["from_most"]) && face - _at(_w_fwd, from_t) > here) {
		from_t += 1.0 / 60.0;
	}
	double exit_t = F(WALLRUN["exit"]);
	double inward = _at(_w_fwd, exit_t) - face;
	Vector3 feet = body->get_global_position();
	double ground = F(rec["ground"]);
	Vector3 end = feet + mul(m, here + inward);
	end.y = (real_t)(ground + top);
	double run_v = D(v.length());
	Array ro = WALLRUN["run_out"];
	double run_d = run_v * (F(ro[1]) - F(ro[0])) * 0.5;
	if (F(rec["depth"]) < inward + run_d + F(body->get("RADIUS")) + 0.5 || !_fits(end + mul(m, run_d))) {
		run_v = 0.0;
		run_d = 0.0;
		if (F(rec["depth"]) < inward + F(body->get("RADIUS")) || !_fits(end, "CROUCH_HEIGHT")) {
			return false;
		}
	}
	refused = "";
	Vector3 left = UP.cross(m).normalized();
	Vector3 on_top = feet + mul(m, here + WRIST_IN);
	on_top.y = (real_t)(ground + top + WRIST_OVER);
	_plan = Dictionary();
	_plan["key"] = "wallrun";
	_plan["from"] = V(D(feet.x), ground, D(feet.z));
	_plan["end"] = end + mul(m, run_d);
	_plan["top"] = top;
	_plan["ground"] = ground;
	_plan["m"] = m;
	_plan["yaw0"] = _rot_y();
	_plan["yaw1"] = std::atan2(-D(m.x), -D(m.z));
	_plan["exit_speed"] = run_v;
	_plan["run_d"] = run_d;
	_plan["hand"] = 2;
	_plan["from_t"] = from_t;
	_plan["stretch"] = (here + inward) / maxf(_at(_w_fwd, exit_t) - _at(_w_fwd, from_t), 0.01);
	_plan["hands_at"] = _hands(on_top, left, F(WALLRUN["hand_side"]), rec);
	plays += 1;
	_up_record = Dictionary();
	record = Dictionary();
	body->call("begin_move", Callable(this, "_wallrun"), (String)WALLRUN["input"]);
	return true;
}

Dictionary TravTraverse::_wallrun(double t) {
	Dictionary p = _plan;
	Vector3 m = p["m"];
	double from_t = F(p["from_t"]);
	double exit_t = F(WALLRUN["exit"]);
	double ct = minf(from_t + t, exit_t);
	double top = F(p["top"]);
	double high = F(WALLRUN["high"]);
	double rise = _at(_w_rise, ct);
	double run_d = F(p["run_d"]);
	Array ro = WALLRUN["run_out"];
	double gather = clampf((ct - F(ro[0])) / (F(ro[1]) - F(ro[0])), 0.0, 1.0);
	Vector3 pos = (Vector3)p["from"] + mul(m, (_at(_w_fwd, ct) - _at(_w_fwd, from_t)) * F(p["stretch"]) + run_d * gather * gather);
	pos.y = (real_t)(F(p["ground"]) + lerpf(top * rise, top - high * (1.0 - rise), smoothstep(F(WALLRUN["kick"]), F(WALLRUN["hands_on"]), ct)));
	double hold = clampf(minf((ct - F(WALLRUN["hands_on"])) / HAND_FADE + 1.0, (F(WALLRUN["hands_off"]) - ct) / HAND_FADE + 1.0), 0.0, 1.0);
	hold = hold * hold * (3.0 - 2.0 * hold);
	Array turn = WALLRUN["grip_turn"];
	Vector3 grip = mul(-m, (F(WALLRUN["grip_out"]) + WRIST_IN) * (1.0 - smoothstep(F(turn[0]), F(turn[1]), ct)));
	Dictionary out;
	out["done"] = ct >= exit_t;
	out["pos"] = pos;
	out["clip_t"] = ct;
	out["air"] = ct >= F(WALLRUN["kick"]) && ct < F(WALLRUN["hands_off"]);
	out["free"] = true;
	out["yaw"] = lerp_angle(F(p["yaw0"]), F(p["yaw1"]), clampf(t / 0.15, 0.0, 1.0));
	out["hand"] = two_hands_grip(p["hands_at"], grip, hold);
	if (ct >= exit_t) {
		out["air"] = false;
		out["pos"] = p["end"];
		out["exit"] = mul(m, F(p["exit_speed"]));
	}
	return out;
}

// ------------------------------------------------------------------------------- stage 15: turn, hang and drop

Vector2 TravTraverse::_at2(const PackedVector2Array &table, double t) {
	double f = clampf(t * _fps, 0.0, (double)(table.size() - 1));
	int i = MIN((int)f, (int)table.size() - 2);
	return table[i].lerp(table[i + 1], (real_t)(f - (double)i));
}

bool TravTraverse::_try_climb_down(const Vector3 &dir, double drop) {
	Vector3 m = -(Vector3)record["normal"];
	if (rad_to_deg(D(dir.angle_to(m))) > MOST_OFF_DEG) {
		refused = "not heading at the edge";
		return false;
	}
	double here = D(((Vector3)record["edge"] - body->get_global_position()).dot(m));
	if (here > DOWN_NEAR) {
		refused = "coming up to the edge";
		return false;
	}
	Vector3 feet = body->get_global_position();
	double top_y = F(record["ground"]);
	double land_y = top_y - drop;
	Vector3 fwd = m.cross(UP).normalized();
	Vector3 start = feet + mul(m, here - F(DOWN["face"]));
	start.y = (real_t)top_y;
	Vector2 last = _d_xz[_d_xz.size() - 1];
	Vector3 end = start + mul(m, F(DOWN["face"]) + DOWN_OUT) + mul(fwd, D(last.y));
	end.y = (real_t)land_y;
	Dictionary g = body->call("probe", V(D(end.x), land_y, D(end.z)));
	if (!(bool)g["hit"] || absf(F(g["y"]) - land_y) > LAND_WITHIN || !_fits(V(D(end.x), land_y, D(end.z)))) {
		refused = "no level, free ground under the edge to come down on";
		return false;
	}
	refused = "";
	Array hl = DOWN["hand_l"];
	Array hr = DOWN["hand_r"];
	_plan = Dictionary();
	_plan["key"] = "climb_down";
	_plan["from"] = feet;
	_plan["start"] = start;
	_plan["end"] = end;
	_plan["m"] = m;
	_plan["fwd"] = fwd;
	_plan["top_y"] = top_y;
	_plan["land_y"] = land_y;
	_plan["drop"] = drop;
	_plan["yaw0"] = _rot_y();
	_plan["yaw1"] = std::atan2(-D(fwd.x), -D(fwd.z));
	_plan["yaw_end"] = std::atan2(D(m.x), D(m.z));
	_plan["exit_speed"] = 0.0;
	_plan["hand"] = 2;
	_plan["t_air"] = std::sqrt(2.0 * maxf(drop - HANG_FEET, 0.0) / F(body->get("GRAVITY")));
	_plan["land"] = drop - HANG_FEET > F(BAND[1]) ? LAND_HARD : LAND_SOFT;
	Array hands_at;
	hands_at.append(start + mul(m, F(hl[0])) + mul(UP, F(hl[1])) + mul(fwd, F(hl[2])));
	hands_at.append(start + mul(m, F(hr[0])) + mul(UP, F(hr[1])) + mul(fwd, F(hr[2])));
	_plan["hands_at"] = hands_at;
	plays += 1;
	record = Dictionary();
	_up_record = Dictionary();
	body->call("begin_move", Callable(this, "_climb_down"), (String)DOWN["input"]);
	return true;
}

Dictionary TravTraverse::_climb_down(double t) {
	Dictionary p = _plan;
	double off = F(DOWN["hands_off"]);
	Vector3 m = p["m"];
	Vector3 start = p["start"];
	if (t <= off) {
		Vector2 xz = _at2(_d_xz, t);
		Vector3 pos = start + mul(m, D(xz.x)) + mul((Vector3)p["fwd"], D(xz.y));
		pos = lerp3((Vector3)p["from"], pos, smoothstep(0.0, 0.3, t));
		pos.y = (real_t)(F(p["top_y"]) - F(DOWN["high"]) * _at(_d_fall, t));
		pos.y = (real_t)(D(pos.y) + 0.07 * smoothstep(0.0, 0.06, t) * (1.0 - smoothstep(0.15, 0.35, t)));
		double hold = clampf(minf((t - F(DOWN["hands_on"])) / HAND_FADE + 1.0, (off - t) / HAND_FADE + 1.0), 0.0, 1.0);
		hold = hold * hold * (3.0 - 2.0 * hold);
		Dictionary o;
		o["done"] = false;
		o["pos"] = pos;
		o["clip_t"] = t;
		o["air"] = false;
		o["free"] = t > 0.60;
		o["landed"] = t <= 0.60;
		o["yaw"] = lerp_angle(F(p["yaw0"]), F(p["yaw1"]), smoothstep(0.0, 0.3, t));
		o["hand"] = two_hands(p["hands_at"], hold);
		return o;
	}
	double tau = t - off;
	Dictionary land = p["land"];
	double t_air = F(p["t_air"]);
	Vector2 xz0 = _at2(_d_xz, off);
	Vector3 from = start + mul(m, D(xz0.x)) + mul((Vector3)p["fwd"], D(xz0.y));
	Vector3 pos2 = lerp3(from, (Vector3)p["end"], smoothstep(0.0, 0.20, tau));
	double y_let = F(p["top_y"]) - F(DOWN["high"]) * _at(_d_fall, off);
	double y_fall = maxf(F(p["land_y"]), F(p["top_y"]) - HANG_FEET - 0.5 * F(body->get("GRAVITY")) * tau * tau);
	pos2.y = (real_t)lerpf(y_let, y_fall, smoothstep(0.0, 0.12, tau));
	bool down = tau >= t_air;
	double ct = !down ? maxf(F(land["touch"]) - (t_air - tau), 0.0) : minf(F(land["touch"]) + (tau - t_air), F(land["exit"]));
	bool done = down && ct >= F(land["exit"]);
	Dictionary out;
	out["done"] = done;
	out["pos"] = pos2;
	out["clip"] = (String)land["input"];
	out["clip_t"] = ct;
	out["air"] = !down;
	out["free"] = !down;
	out["landed"] = down;
	out["landing"] = (String)land["kind"];
	out["yaw"] = lerp_angle(F(p["yaw1"]), F(p["yaw_end"]), smoothstep(0.0, 0.15, tau));
	if (done) {
		out["pos"] = p["end"];
		out["exit"] = ZERO;
	}
	return out;
}

// ------------------------------------------------------------------------------------------- stage 16: across a gap

bool TravTraverse::_try_gap(const Vector3 &v, const Vector3 &dir, Dictionary rec, bool running) {
	Vector3 m = -(Vector3)rec["normal"];
	if (rad_to_deg(D(dir.angle_to(m))) > MOST_OFF_DEG) {
		refused = "not heading across it";
		return false;
	}
	if ((bool)rec.get("far_wall", false) || !rec.has("landing") || !(bool)rec.get("landing_ok", false)) {
		refused = "no far side to come down on";
		return false;
	}
	double gap = F(rec["gap"]);
	double landing = F(rec["landing"]);
	bool shallow = F(rec.get("drop", (double)INFINITY)) <= F(UP_BAND[0]) + MEASURED_WITHIN && landing <= F(UP_BAND[0]) + MEASURED_WITHIN;
	if (shallow && (running || gap > STEP_ACROSS * LEG + MEASURED_WITHIN)) {
		refused = "";
		return false;
	}
	double here = D(((Vector3)rec["edge"] - body->get_global_position()).dot(m));
	double rad = F(body->get("RADIUS"));
	if (running) {
		double g = F(body->get("GRAVITY"));
		double rise = F(body->get("JUMP_RISE_RUN"));
		double vy0 = std::sqrt(2.0 * g * rise);
		double pace = maxf(D(v.length()), 0.1);
		double t_far = (GAP_OFF + gap + rad + GAP_ON) / pace;
		bool catching = false;
		if (vy0 * t_far - 0.5 * g * t_far * t_far < landing) {
			double t_face = (GAP_OFF + gap - OVER_BACK) / pace;
			double y_face = vy0 * t_face - 0.5 * g * t_face * t_face;
			if (landing - y_face > F(MANTLE_BAND[1]) - 0.10) {
				refused = vformat("too wide for the running jump, and the far edge is out of reach (%.2f m)", gap);
				return false;
			}
			catching = true;
		}
		double push = D(v.length()) * F(body->get("JUMP_PUSH_RUN"));
		if (here > GAP_OFF + push + D(v.length()) / 60.0) {
			refused = "coming up to the gap";
			return false;
		}
		refused = "";
		if ((bool)body->call("start_jump")) {
			plays += 1;
			_plan = Dictionary();
			_plan["key"] = catching ? "gap_catch" : "gap_run";
			_plan["gap"] = gap;
			return true;
		}
		return false;
	}
	Vector3 feet = body->get_global_position();
	double ground = F(rec["ground"]);
	Vector3 end = feet + mul(m, here + gap + rad + GAP_ON);
	end.y = (real_t)(ground + landing);
	if (gap <= STEP_ACROSS * LEG + MEASURED_WITHIN && absf(landing) <= F(UP_BAND[0]) + MEASURED_WITHIN) {
		if (!_fits(end)) {
			refused = "no room on the far side";
			return false;
		}
		if (here > 0.10 + D(v.length()) / 60.0 * (double)AGAIN) {
			refused = "coming up to the gap";
			return false;
		}
		refused = "";
		double pace_w = maxf(D(v.length()), 0.8);
		_plan = Dictionary();
		_plan["key"] = "gap_step";
		_plan["from"] = V(D(feet.x), ground, D(feet.z));
		_plan["end"] = end;
		_plan["m"] = m;
		_plan["yaw0"] = _rot_y();
		_plan["yaw1"] = std::atan2(-D(m.x), -D(m.z));
		_plan["time"] = D((end - feet).dot(m)) / pace_w;
		_plan["exit_speed"] = pace_w;
		_plan["gap"] = gap;
		plays += 1;
		_up_record = Dictionary();
		body->call("begin_move", Callable(this, "_gap_step"), String("ground"));
		return true;
	}
	bool catching_w = gap > LONG_JUMP + MEASURED_WITHIN || landing > GAP_UP + MEASURED_WITHIN;
	if (gap > LONG_JUMP + CATCH_REACH + MEASURED_WITHIN || landing - CATCH_UNDER > F(body->get("JUMP_RISE")) || landing < -GAP_DOWN - MEASURED_WITHIN) {
		refused = vformat("too wide, too high or too far down to jump from a walk (%.2f m across, far side %+.2f m)", gap, landing);
		return false;
	}
	if (catching_w) {
		end = feet + mul(m, here + gap - OVER_BACK);
		end.y = (real_t)(ground + landing - CATCH_UNDER);
	} else if (!_fits(end)) {
		refused = "no room on the far side";
		return false;
	}
	if (here > 0.35) {
		refused = "coming up to the gap";
		return false;
	}
	refused = "";
	Vector3 off = feet + mul(m, maxf(here - GAP_OFF, 0.0));
	off.y = (real_t)ground;
	_plan = Dictionary();
	_plan["key"] = "gap_jump";
	_plan["from"] = V(D(feet.x), ground, D(feet.z));
	_plan["off"] = off;
	_plan["end"] = end;
	_plan["m"] = m;
	_plan["yaw0"] = _rot_y();
	_plan["yaw1"] = std::atan2(-D(m.x), -D(m.z));
	_plan["exit_speed"] = 0.0;
	_plan["gap"] = gap;
	_plan["catch"] = catching_w;
	plays += 1;
	_up_record = Dictionary();
	body->call("begin_move", Callable(this, "_gap_jump"), (String)JUMP["input"]);
	return true;
}

Dictionary TravTraverse::_gap_step(double t) {
	Dictionary p = _plan;
	double u = clampf(t / F(p["time"]), 0.0, 1.0);
	Dictionary out;
	out["done"] = u >= 1.0;
	out["pos"] = lerp3((Vector3)p["from"], (Vector3)p["end"], u);
	out["clip_t"] = 0.0;
	out["air"] = false;
	out["free"] = true;
	out["yaw"] = lerp_angle(F(p["yaw0"]), F(p["yaw1"]), clampf(t / 0.15, 0.0, 1.0));
	if (u >= 1.0) {
		out["exit"] = mul((Vector3)p["m"], F(p["exit_speed"]));
	}
	return out;
}

Dictionary TravTraverse::_gap_jump(double t) {
	Dictionary p = _plan;
	double from_t = F(JUMP["from"]);
	double exit_t = F(JUMP["exit"]);
	double ct = minf(from_t + t, exit_t);
	double off_t = F(JUMP["off"]);
	double down_t = F(JUMP["down"]);
	bool air = ct >= off_t && ct < down_t;
	Vector3 pos = lerp3((Vector3)p["from"], (Vector3)p["off"], smoothstep(0.0, off_t - from_t, t));
	if (ct >= off_t) {
		pos = lerp3((Vector3)p["off"], (Vector3)p["end"], clampf((ct - off_t) / (down_t - off_t), 0.0, 1.0));
	}
	if ((bool)p.get("catch", false)) {
		if (ct >= down_t - 0.10) {
			_catch_next = 3;
			Dictionary o;
			o["done"] = true;
			o["pos"] = pos;
			o["clip_t"] = ct;
			o["air"] = true;
			o["free"] = true;
			o["yaw"] = F(p["yaw1"]);
			o["exit"] = mul((Vector3)p["m"], 1.5);
			return o;
		}
	}
	Dictionary out;
	out["done"] = ct >= exit_t;
	out["pos"] = pos;
	out["clip_t"] = ct;
	out["air"] = air;
	out["free"] = air;
	out["landed"] = ct >= down_t;
	out["yaw"] = lerp_angle(F(p["yaw0"]), F(p["yaw1"]), clampf(t / 0.2, 0.0, 1.0));
	if (ct >= exit_t) {
		out["pos"] = p["end"];
		out["exit"] = ZERO;
	}
	return out;
}

// -------------------------------------------------------------------------------- losing his balance on something narrow

bool TravTraverse::_try_balance_fall() {
	Vector3 feet = body->get_global_position();
	Vector3 face = -body->get_global_transform().basis.get_column(2);
	face = V(D(face.x), 0.0, D(face.z)).normalized();
	Vector2 last = _b_xz[_b_xz.size() - 1];
	TypedArray<RID> ex;
	ex.append(body->get_rid());
	const double ways[2] = { 1.0, -1.0 };
	for (int w = 0; w < 2; w++) {
		double way = ways[w];
		Vector3 m0 = mul(face.cross(UP).normalized(), way);
		Vector3 e0 = feet + mul(m0, BALANCE_OUT);
		Dictionary g0 = body->get_world_3d()->get_direct_space_state()->intersect_ray(PhysicsRayQueryParameters3D::create(e0 + V(0.0, 0.5, 0.0), e0 - V(0.0, 6.0, 0.0), body->get_collision_mask(), ex));
		if (g0.is_empty()) {
			continue;
		}
		double gy0 = D(((Vector3)g0["position"]).y);
		if (gy0 > D(feet.y) - 0.05 || D(feet.y) - gy0 >= HARD_FALL_FROM || !_fits(V(D(e0.x), gy0, D(e0.z)))) {
			continue;
		}
		refused = "";
		_plan = Dictionary();
		_plan["key"] = "balance_land";
		_plan["on_feet"] = true;
		_plan["from"] = feet;
		_plan["end"] = V(D(e0.x), gy0, D(e0.z));
		_plan["m"] = m0;
		_plan["top_y"] = D(feet.y);
		_plan["land_y"] = gy0;
		_plan["yaw0"] = _rot_y();
		_plan["yaw1"] = std::atan2(-D(m0.x), -D(m0.z));
		_plan["exit_speed"] = 0.0;
		plays += 1;
		record = Dictionary();
		_up_record = Dictionary();
		body->call("begin_move", Callable(this, "_balance_fall"), (String)BALANCE["input"]);
		return true;
	}
	const double reaches[3] = { 1.0, 0.8, 0.65 };
	const double alongs[4] = { 0.7, 0.0, -0.6, -1.1 };
	for (int r = 0; r < 3; r++) {
		double reach = reaches[r];
		for (int w = 0; w < 2; w++) {
			double way = ways[w];
			Vector3 m = mul(face.cross(UP).normalized(), way);
			Vector3 end = feet + mul(m, D(last.y) * reach);
			Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(end + V(0.0, 0.5, 0.0), end - V(0.0, 6.0, 0.0), body->get_collision_mask(), ex);
			Dictionary hit = body->get_world_3d()->get_direct_space_state()->intersect_ray(q);
			if (hit.is_empty()) {
				continue;
			}
			double gy = D(((Vector3)hit["position"]).y);
			if (gy > D(feet.y) - 0.05) {
				continue;
			}
			bool ok = true;
			for (int a = 0; a < 4; a++) {
				Vector3 at = end + mul(m, alongs[a]);
				Dictionary g = body->call("probe", V(D(at.x), gy, D(at.z)));
				if (!(bool)g["hit"] || absf(F(g["y"]) - gy) > LAND_LEVEL || !_fits(V(D(at.x), gy, D(at.z)), "CROUCH_HEIGHT")) {
					ok = false;
				}
			}
			if (!ok) {
				continue;
			}
			refused = "";
			_plan = Dictionary();
			_plan["key"] = "balance_fall";
			_plan["from"] = feet;
			_plan["end"] = V(D(end.x), gy, D(end.z));
			_plan["m"] = m;
			_plan["top_y"] = D(feet.y);
			_plan["land_y"] = gy;
			_plan["reach"] = reach;
			_plan["yaw0"] = _rot_y();
			_plan["yaw1"] = std::atan2(-D(m.x), -D(m.z));
			_plan["exit_speed"] = 0.0;
			plays += 1;
			record = Dictionary();
			_up_record = Dictionary();
			body->call("begin_move", Callable(this, "_balance_fall"), (String)BALANCE["input"]);
			return true;
		}
	}
	return false;
}

Dictionary TravTraverse::_balance_fall(double t) {
	Dictionary p = _plan;
	double from_t = F(BALANCE["from"]);
	double fall_len = F(BALANCE["end"]) - from_t;
	Vector3 m = p["m"];
	if ((bool)p.get("on_feet", false)) {
		double wob = F(BALANCE["over"]) - from_t;
		if (t < wob) {
			Dictionary o;
			o["done"] = false;
			o["pos"] = p["from"];
			o["clip_t"] = from_t + t;
			o["air"] = false;
			o["free"] = true;
			o["yaw"] = lerp_angle(F(p["yaw0"]), F(p["yaw1"]), smoothstep(0.0, 1.0, t));
			return o;
		}
		double tau = t - wob;
		double drop_h = F(p["top_y"]) - F(p["land_y"]);
		double t_air = std::sqrt(2.0 * drop_h / F(body->get("GRAVITY")));
		Vector3 pos = lerp3((Vector3)p["from"], (Vector3)p["end"], smoothstep(0.0, maxf(t_air, 0.25), tau));
		pos.y = (real_t)maxf(F(p["land_y"]), F(p["top_y"]) - 0.5 * F(body->get("GRAVITY")) * tau * tau);
		bool down = tau >= t_air;
		double ct = !down ? maxf(F(LAND_HARD["touch"]) - (t_air - tau), 0.0) : minf(F(LAND_HARD["touch"]) + (tau - t_air), F(LAND_HARD["exit"]));
		bool fin = down && ct >= F(LAND_HARD["exit"]);
		Dictionary o;
		o["done"] = fin;
		o["pos"] = pos;
		o["clip"] = (String)LAND_HARD["input"];
		o["clip_t"] = ct;
		o["air"] = !down;
		o["free"] = !down;
		o["landed"] = down;
		o["landing"] = "heavy";
		o["yaw"] = F(p["yaw1"]);
		if (fin) {
			o["pos"] = p["end"];
			o["exit"] = ZERO;
		}
		return o;
	}
	if (t < fall_len) {
		double ct = from_t + t;
		Vector2 xz = _at2(_b_xz, ct);
		Vector3 pos = (Vector3)p["from"] + mul(m, D(xz.y) * F(p["reach"]));
		pos.y = (real_t)(F(p["land_y"]) + (F(p["top_y"]) - F(p["land_y"])) * (1.0 - _at(_b_fall, ct)));
		Dictionary o;
		o["done"] = false;
		o["pos"] = pos;
		o["clip_t"] = ct;
		o["air"] = ct >= F(BALANCE["over"]) && _at(_b_fall, ct) < 0.95;
		o["free"] = true;
		o["yaw"] = lerp_angle(F(p["yaw0"]), F(p["yaw1"]), smoothstep(0.0, 1.0, t));
		return o;
	}
	double tu = t - fall_len - F(BALANCE["lie"]);
	if (tu < 0.0) {
		Dictionary o;
		o["done"] = false;
		o["pos"] = p["end"];
		o["clip_t"] = F(BALANCE["end"]);
		o["air"] = false;
		o["free"] = true;
		o["yaw"] = F(p["yaw1"]);
		return o;
	}
	bool done = tu >= F(BALANCE["up_len"]);
	Dictionary out;
	out["done"] = done;
	out["pos"] = p["end"];
	out["clip"] = (String)BALANCE["up"];
	out["clip_t"] = minf(tu, F(BALANCE["up_len"]));
	out["air"] = false;
	out["free"] = tu < F(BALANCE["up_len"]) - 0.5;
	out["landed"] = true;
	out["yaw"] = F(p["yaw1"]);
	if (done) {
		out["exit"] = ZERO;
	}
	return out;
}

// ------------------------------------------------------------------------------------------------ for the other scripts

bool TravTraverse::_fits(const Vector3 &at, const char *height) {
	return (bool)det()->call("_fits", at, F(body->get(height)));
}

void TravTraverse::_bind_methods() {
	ClassDB::bind_method(D_METHOD("_on_landed", "drop"), &TravTraverse::_on_landed);
	ClassDB::bind_method(D_METHOD("_roll_only", "t"), &TravTraverse::_roll_only);
	ClassDB::bind_method(D_METHOD("_step_off", "t"), &TravTraverse::_step_off);
	ClassDB::bind_method(D_METHOD("_step_up", "t"), &TravTraverse::_step_up);
	ClassDB::bind_method(D_METHOD("_run_up", "t"), &TravTraverse::_run_up);
	ClassDB::bind_method(D_METHOD("_vault", "t"), &TravTraverse::_vault);
	ClassDB::bind_method(D_METHOD("_tuck", "t"), &TravTraverse::_tuck);
	ClassDB::bind_method(D_METHOD("_over", "t"), &TravTraverse::_over);
	ClassDB::bind_method(D_METHOD("_mantle", "t"), &TravTraverse::_mantle);
	ClassDB::bind_method(D_METHOD("_grab", "t"), &TravTraverse::_grab);
	ClassDB::bind_method(D_METHOD("_wallrun", "t"), &TravTraverse::_wallrun);
	ClassDB::bind_method(D_METHOD("_climb_down", "t"), &TravTraverse::_climb_down);
	ClassDB::bind_method(D_METHOD("_gap_step", "t"), &TravTraverse::_gap_step);
	ClassDB::bind_method(D_METHOD("_gap_jump", "t"), &TravTraverse::_gap_jump);
	ClassDB::bind_method(D_METHOD("_balance_fall", "t"), &TravTraverse::_balance_fall);
}

bool TravTraverse::_get(const StringName &p_name, Variant &r_ret) const {
	String n = p_name;
	if (n == "body") {
		r_ret = body;
		return true;
	}
	if (n == "detector") {
		r_ret = detector;
		return true;
	}
	if (n == "record") {
		r_ret = record;
		return true;
	}
	if (n == "force_mirror") {
		r_ret = force_mirror;
		return true;
	}
	if (n == "enabled") {
		r_ret = enabled;
		return true;
	}
	if (n == "refused") {
		r_ret = refused;
		return true;
	}
	if (n == "plays") {
		r_ret = plays;
		return true;
	}
	if (n == "_plan") {
		r_ret = _plan;
		return true;
	}
	if (n == "_up_record") {
		r_ret = _up_record;
		return true;
	}
	if (n == "_tick") {
		r_ret = _tick;
		return true;
	}
	if (n == "_catch_next") {
		r_ret = _catch_next;
		return true;
	}
	if (n == "_still") {
		r_ret = _still;
		return true;
	}
#include "trav_traverse_get.inc"
	return false;
}

bool TravTraverse::_set(const StringName &p_name, const Variant &p_value) {
	String n = p_name;
	if (n == "body") {
		body = Object::cast_to<CharacterBody3D>((Object *)p_value);
		return true;
	}
	if (n == "record") {
		record = p_value;
		return true;
	}
	if (n == "force_mirror") {
		force_mirror = (int)(int64_t)p_value;
		return true;
	}
	if (n == "enabled") {
		enabled = p_value;
		return true;
	}
	if (n == "refused") {
		refused = p_value;
		return true;
	}
	if (n == "plays") {
		plays = (int)(int64_t)p_value;
		return true;
	}
	if (n == "_plan") {
		_plan = p_value;
		return true;
	}
	return false;
}
