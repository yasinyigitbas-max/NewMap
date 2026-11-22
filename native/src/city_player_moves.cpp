// CityPlayer's outdoor moves after the traversal: see city_player_moves.h. Every take is the "pact" library's (Mixamo,
// his downloads and packs; tools/people/make_player_actions.gd) or the traversal's ("ptrav": the get-ups, the cover).
#include "city_player.h"
#include "body_layer.h"
#include "city_ped.h"
#include "hand_grip.h"

#include <godot_cpp/classes/animation_library.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/object.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

namespace {
const float PI_M = 3.14159265f, TAU_M = 6.2831853f;
float wrapm(float a) { a = std::fmod(a + PI_M, TAU_M); if (a < 0.0f) a += TAU_M; return a - PI_M; }
float yaw_m(const Vector3 &v) { return std::atan2(v.x, v.z); }
Vector3 fwd_m(float y) { return Vector3(std::sin(y), 0.0f, std::cos(y)); }
Vector3 left_m(float y) { return Vector3(std::cos(y), 0.0f, -std::sin(y)); }
const Vector3 UPM(0, 1, 0);
struct HitM { bool ok = false; Vector3 p, n; uint64_t id = 0; };
HitM ray_m(PhysicsDirectSpaceState3D *ss, const RID &self, const Vector3 &a, const Vector3 &b, uint32_t mask = 1) {
	HitM h;
	if (!ss) return h;
	Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(a, b, mask);
	TypedArray<RID> ex; ex.push_back(self); q->set_exclude(ex);
	const Dictionary d = ss->intersect_ray(q);
	if (d.is_empty()) return h;
	h.ok = true; h.p = d["position"]; h.n = d["normal"]; h.id = (uint64_t)(int64_t)d["collider_id"];
	return h;
}
#define AN(name) StringName("pact/" name)
#define TN2(name) StringName("ptrav/" name)
const char *CARRY_DIR = "res://map_dc/coronado/city_kit/carry/scenes/";
Node3D *live(uint64_t id) { return id ? Object::cast_to<Node3D>(ObjectDB::get_instance(id)) : nullptr; }
}

// ---------------------------------------------------------------- CARRYING

void CityPlayer::set_carry(const String &p_name) {
	MoveState &m = mvs;
	if (Node3D *old = live(m.prop_id)) { if (old->get_parent() == this) old->queue_free(); }
	m.prop = nullptr; m.prop_id = 0; m.carry = String(); m.two = false;
	if (p_name.is_empty()) return;
	Ref<PackedScene> ps = ResourceLoader::get_singleton()->load(String(CARRY_DIR) + p_name + ".scn");
	if (ps.is_null()) return;
	Node3D *n = Object::cast_to<Node3D>(ps->instantiate());
	if (!n) return;
	add_child(n); n->set_as_top_level(true);
	carry_take(n, p_name);
	m.prop_blend = 1.0f;
}

// a prop (in the world or just made) into his hands: its grips and how it is held
void CityPlayer::carry_take(Node3D *p_n, const String &p_name) {
	MoveState &m = mvs;
	m.prop = p_n; m.prop_id = p_n->get_instance_id(); m.carry = p_name;
	m.two = String(p_n->get_meta("hold", "")) == "two_hand_sides";
	Node3D *gr = Object::cast_to<Node3D>(p_n->get_node_or_null(NodePath("grip_r")));
	Node3D *gl = Object::cast_to<Node3D>(p_n->get_node_or_null(NodePath("grip_l")));
	m.grip_r = gr ? gr->get_transform() : Transform3D(); m.grip_l = gl ? gl->get_transform() : m.grip_r;
	m.col = p_n->get_meta("col", AABB());
	if (p_n->is_in_group("player_pickup")) p_n->remove_from_group("player_pickup");
}

String CityPlayer::get_carry() const { return live(mvs.prop_id) ? mvs.carry : String(); }

// the BodyLayer each frame: the carry take for what his legs do, the prop, the look-at
void CityPlayer::moves_layer(float p_dt) {
	MoveState &m = mvs;
	Skeleton3D *sk = fig ? fig->skeleton() : nullptr;
	if (!sk) return;
	if (!live(m.prop_id)) { m.prop = nullptr; m.prop_id = 0; }
	// the put down's settle: the prop let go onto what is under it
	if (m.drop_t >= 0.0f) {
		Node3D *d = live(m.drop_id);
		m.drop_t += p_dt;
		const float u = std::min(m.drop_t / 0.2f, 1.0f);
		if (d) d->set_global_transform(m.drop_from.interpolate_with(m.drop_to, u * u));
		if (u >= 1.0f || !d) m.drop_t = -1.0f;
	}
	const bool want_layer = m.prop || m.carry_w > 0.001f || m.look_set || m.look_auto_on || (m.layer && m.layer->look_w > 0.001f);
	if (!want_layer && !m.layer) return;
	if (!m.layer) { m.layer = memnew(BodyLayer); m.layer->set_name("BodyLayer"); sk->add_child(m.layer); }
	BodyLayer *L = m.layer;
	if (L->get_index() != sk->get_child_count() - 1) sk->move_child(L, -1);   // (after the foot plant and the hand grip)
	L->set_active(true);
	// which carry take: standing, walking, jogging, the fast run; none in a climb, a hang or on the bicycle
	const StringName cur = fig->current_clip();
	const String cs = String(cur);
	const bool hands_busy = climb != 0 || (grip && grip->is_active()) || cs.contains("Climb") || cs.contains("Hang") || cs.contains("Freehang") || cs.contains("Cover") || cs.begins_with("pact/");
	const bool on = m.prop && !hands_busy && !frozen;
	m.carry_w += ((on ? 1.0f : 0.0f) - m.carry_w) * std::min(p_dt / 0.2f, 1.0f);
	if (m.act == MoveState::PICKING) m.carry_w = std::min(m.carry_w, std::max(0.0f, (m.act_t - 0.0f) / 0.8f));   // (taken up: the arms come round to it as he stands)
	StringName up;
	float pace = 1.0f;   // (the take's own pace of travel, m/s: its time runs at his speed over it)
	const float sp = speed;
	if (m.two) {
		if (sp < 0.25f) { up = AN("Carrying_Turn"); pace = 0.0f; }
		else if (gait_i >= 2 || sp > 3.6f) { up = AN("Running_With_A_Box"); pace = 2.55f; }
		else if (gait_i == 1 || sp > 1.9f) { up = AN("Jogging_With_Box_a"); pace = 2.49f; }
		else { up = AN("Walking_Carry"); pace = 0.84f; }
	} else {
		if (sp < 0.25f) { up = AN("Briefcase_Idle"); pace = 0.0f; }
		else if (cs.contains("shop") || m.carry.begins_with("bag_")) { up = AN("Walking_With_Shopping_Bag"); pace = 0.91f; }
		else { up = AN("Walk_With_Briefcase"); pace = 1.40f; }
	}
	if (up != m.up_clip) {
		Ref<Animation> a = fig_anim(up);
		if (a.is_valid()) {
			L->clip_prev = L->clip; L->t_prev = L->t; L->x = L->clip.is_valid() ? 0.0f : 1.0f;
			L->clip = a; m.up_clip = up; m.up_t = 0.0;
		}
	}
	m.up_t += p_dt * (pace > 0.0f ? std::max(sp / pace, 0.5f) : 1.0f);
	L->t = m.up_t; L->t_prev += p_dt;
	L->x = std::min(L->x + p_dt / 0.25f, 1.0f);
	L->mask = m.two ? 2 : 1; L->w = m.carry_w;
	if (m.prop && (on || m.act == MoveState::PICKING || m.act == MoveState::PUTTING)) {
		L->prop = m.prop; L->prop_id = m.prop_id; L->two = m.two; L->grip_r = m.grip_r; L->grip_l = m.grip_l; L->col = m.col;
		if (m.prop_blend < 1.0f) { m.prop_blend = std::min(m.prop_blend + p_dt / 0.3f, 1.0f); }
		L->blend = m.prop_blend; L->from = m.prop_from;
	} else if (m.prop && hands_busy) {
		// (a climb, a hang: the prop stays in the right hand, the left lets go)
		L->prop = m.prop; L->prop_id = m.prop_id; L->two = false; L->grip_r = m.grip_r; L->grip_l = m.grip_r; L->col = m.col; L->blend = 1.0f;
	} else { L->prop = nullptr; L->prop_id = 0; }
	L->fwd = fwd_m(yaw);
	// the look-at: a point given, else what is near and ahead (a seat or a pick-up being gone to, a "player_look" point)
	m.look_scan_t -= p_dt;
	if (m.look_scan_t <= 0.0f) {
		m.look_scan_t = 0.3f; m.look_auto_on = false;
		if (m.act == MoveState::GO_SIT) { m.look_auto_on = true; m.look_auto_p = m.seat_p + Vector3(0, 0.3f, 0); }
		else if (m.act == MoveState::GO_PICK) { if (Node3D *pk = live(m.pick_id)) { m.look_auto_on = true; m.look_auto_p = pk->get_global_position(); } }
		else if (is_inside_tree()) {
			const Vector3 head = get_global_position() + Vector3(0, 1.6f, 0);
			float best = 1e9f;
			TypedArray<Node> pts = get_tree()->get_nodes_in_group("player_look");
			for (int i = 0; i < pts.size(); i++) {
				Node3D *n = Object::cast_to<Node3D>(pts[i]);
				if (!n) continue;
				const Vector3 d = n->get_global_position() - head;
				const float dl = d.length();
				if (dl > 8.0f || dl < 0.5f) continue;
				const Vector3 dh(d.x, 0, d.z);
				if (dh.length() < 0.3f || fwd_m(yaw).dot(dh.normalized()) < 0.0f) continue;   // (ahead or beside him, never behind)
				if (dl < best) { best = dl; m.look_auto_p = n->get_global_position(); m.look_auto_on = true; }
			}
		}
		if (m.look_auto_on || m.look_set) m.n_look++;
	}
	L->look_on = (m.look_set || m.look_auto_on) && trv.mode != TravState::AIR && m.act != MoveState::SITTING_DOWN && m.act != MoveState::STUMBLE;
	L->look_p = m.look_set ? m.look_p : m.look_auto_p;
	m.chest_gap = L->chest_gap;
	if (m.prop && on && m.carry_w > 0.95f) m.carry_miss_most = std::max(m.carry_miss_most, std::max(L->miss[0], L->miss[1]));
}

Ref<Animation> CityPlayer::fig_anim(const StringName &p_clip) const {
	const String c = String(p_clip);
	const int sl = c.find("/");
	if (sl < 0) return Ref<Animation>();
	const String lib = c.substr(0, sl), name = c.substr(sl + 1);
	if (lib != "pact") return Ref<Animation>();
	const String g = body_id.begins_with("F") ? "female" : "male";
	Ref<AnimationLibrary> L = ResourceLoader::get_singleton()->load("res://characters/rocketbox/clips_player_act_" + g + ".res");
	if (L.is_null() || !L->has_animation(name)) return Ref<Animation>();
	return L->get_animation(name);
}

// ---------------------------------------------------------------- THE MOVES' PHYSICS (from trav_physics)

// a move's clip started from where he stands, fitted so the hips end where they should: the rest of the way (what the
// walk there left) eased in over its first 0.6 s, the turn to its facing over 0.7 s
void CityPlayer::moves_start_fit(const StringName &p_clip, float p_yaw, const Vector3 &p_hips_at, double p_hips_t, int p_then, bool p_ground) {
	TravState &s = trv;
	const float y0 = yaw;
	trav_start(p_clip, 0.0, 0.0, p_yaw, p_then);
	const Vector3 h0 = fig->clip_hips_at(p_clip, 0.0), hk = fig->clip_hips_at(p_clip, p_hips_t);
	const Vector3 A = Vector3(p_hips_at.x, s.anchor.y, p_hips_at.z) - Basis(UPM, p_yaw).xform(Vector3(hk.x, 0, hk.z));
	const Vector3 p = get_global_position();
	const Vector3 start = Vector3(p.x, s.anchor.y, p.z) - Basis(UPM, y0).xform(Vector3(h0.x, 0, h0.z));
	s.anchor = A; s.d0 = start - A; s.d0.y = 0.0f; s.d0_t = 0.6f;
	if (p_ground) {
		// (p_hips_at.y is the ground he is to end on: the seat's foot; his capsule may have ridden up the seat's edge on the way)
		const float dy = p_hips_at.y - p.y;
		if (std::abs(dy) > 0.03f) { s.anchor.y += dy; s.d0.y = -dy; }
	}
	s.yaw = y0; s.yaw_to = p_yaw; s.yaw_ease = 0.7f;
	s.plant_on = true;
	mvs.go_miss = Vector3(s.d0.x, 0, s.d0.z).length();
}

// his walk to a point (the seat's, the pick-up's): his own walk steered there, a frame behind
void CityPlayer::moves_steer(const Vector3 &p_to, const Vector3 &p_fwd, const Vector3 &p_right) {
	const Vector3 d = Vector3(p_to.x - get_global_position().x, 0, p_to.z - get_global_position().z);
	const float dl = d.length();
	Vector2 c;
	if (dl > 0.01f) {
		const Vector3 u = d / dl;
		float k = std::min(std::max(dl / 0.8f, 0.5f), 1.0f);
		// (close and off to his side: slower, so he turns onto it rather than circling it)
		const float a = fwd_m(yaw).dot(u);
		if (dl < 1.5f && a < 0.7f) k = std::min(k, 0.6f);   // (close and off his heading: slower, a tighter turn)
		c = Vector2(u.dot(p_right), u.dot(p_fwd)) * k;
	}
	cmd = c; cmd_tier = 0; cmd_run = false; scripted = true;
}

void CityPlayer::moves_end_steer() {
	MoveState &m = mvs;
	scripted = m.scripted_was; cmd = m.scripted_was ? m.cmd_was : Vector2();
}

bool CityPlayer::moves_physics(float p_dt, const Vector2 &p_mv, const Vector3 &p_want, const Vector3 &p_fwd, const Vector3 &p_right) {
	MoveState &m = mvs; TravState &s = trv;
	m.bump_cd -= p_dt; m.trip_cd -= p_dt; m.side_cd -= p_dt; m.act_t += p_dt;
	const bool e = m.e_want; m.e_want = false;
	const float wl = p_want.length();
	PhysicsDirectSpaceState3D *ss = get_world_3d().is_valid() ? get_world_3d()->get_direct_space_state() : nullptr;
	const RID self = get_rid();
	const Vector3 p = get_global_position();
	static const StringName SIT_DOWN(AN("Stand_To_Sit")), SIT_IDLE(AN("Sitting_Idle_a")), SIT_UP(AN("Sit_To_Stand")), PLACE(AN("Tender_Placement"));
	// --- sitting: the idle looped until he moves or presses E again; then up
	if (m.act == MoveState::SITTING_DOWN && s.mode == TravState::CLIP && s.clip == SIT_IDLE) { m.act = MoveState::SITTING; m.act_t = 0.0f; }
	if (m.act == MoveState::SITTING) {
		if (s.mode != TravState::CLIP || s.clip != SIT_IDLE) { m.act = MoveState::NONE; return false; }
		const double len = fig->clip_len(SIT_IDLE);
		s.t_end = len + 1.0;   // (looped: its time wraps with the figure's)
		if (s.t >= len) s.t -= len;
		if ((wl > 0.3f && m.act_t > 0.5f) || e) {
			s.blend_req = 0.3f;
			trav_start(SIT_UP, 0.0, 0.0, s.yaw, wl > 0.3f ? TravState::THEN_WALK : TravState::THEN_IDLE);
			s.plant_on = true; m.act = MoveState::GETTING_UP; m.act_t = 0.0f; m.n_stand++; m.last = "Sit_To_Stand";
		}
		return false;
	}
	if ((m.act == MoveState::GETTING_UP || m.act == MoveState::SITTING_DOWN || m.act == MoveState::STUMBLE || m.act == MoveState::SIDESTEP) && s.mode == TravState::NONE) m.act = MoveState::NONE;
	// --- the sidestep: the strafe loop until he is through the gap
	if (m.act == MoveState::SIDESTEP) {
		if (s.mode == TravState::CLIP) {
			const double len = fig->clip_len(s.clip);
			s.t_end = len + 1.0;
			if (s.t >= len) s.t -= len;
			if (m.act_t >= m.side_len) { s.then = TravState::THEN_WALK; s.nq = 0; s.t_end = s.t; }
		}
		return false;
	}
	// --- the pick up / put down: the prop his (or let go) at the take's lowest
	if (m.act == MoveState::PICKING || m.act == MoveState::PUTTING) {
		const double at = fig->clip_meta(PLACE, "hands_low_at", 4.6);
		if (s.mode == TravState::CLIP && s.clip == PLACE && !m.attached && s.t >= at) {
			m.attached = true; m.act_t = 0.0f;
			if (m.act == MoveState::PICKING) {
				if (Node3D *pk = live(m.pick_id)) {
					m.prop_from = pk->get_global_transform(); m.prop_blend = 0.0f;
					carry_take(pk, String(pk->get_meta("carry", "")));
					m.n_pick++;
				}
			} else if (Node3D *pr = live(m.prop_id)) {
				// let go: level, onto what is under it
				Transform3D T = pr->get_global_transform();
				Basis B; const Vector3 X = Vector3(T.basis.get_column(0).x, 0, T.basis.get_column(0).z).normalized();
				B.set_column(0, X); B.set_column(1, UPM); B.set_column(2, X.cross(UPM));
				const Vector3 c = T.xform(m.col.get_center());
				const HitM g = ray_m(ss, self, c + Vector3(0, 0.2f, 0), c - Vector3(0, 2.0f, 0));
				Transform3D to(B, T.origin);
				if (g.ok) to.origin.y = g.p.y - m.col.position.y;
				m.drop_from = T; m.drop_to = to; m.drop_t = 0.0f; m.drop_id = m.prop_id;
				pr->set_meta("carry", m.carry); pr->add_to_group("player_pickup");
				m.prop = nullptr; m.prop_id = 0; m.carry = String(); m.n_put++;
			}
		}
		if (s.mode == TravState::NONE) { m.act = MoveState::NONE; }
		return false;
	}
	// --- walking to a seat or a pick-up, then the move
	if (m.act == MoveState::GO_SIT || m.act == MoveState::GO_PICK) {
		Vector3 to = m.go_p;
		// (from behind a seat: round its end first)
		if (m.act == MoveState::GO_SIT) {
			const Vector3 f = fwd_m(m.seat_yaw);
			if (m.go_wp == 0 && (p - m.seat_p).dot(f) < 0.1f) m.go_wp = 1;
			if (m.go_wp == 1) {
				// (round the end to a point out in front, the corner cut once he is near it: then in, a turn he can walk)
				const Vector3 X = left_m(m.seat_yaw);
				const float half = 0.5f * (float)(live(m.seat_id) ? (double)live(m.seat_id)->get_meta("seat_len", 0.6) : 0.6) + 0.55f;
				const float side = (p - m.seat_p).dot(X) >= 0.0f ? 1.0f : -1.0f;
				to = m.seat_p + X * side * half + f * 1.3f;
				if (Vector2(to.x - p.x, to.z - p.z).length() < 0.9f || (p - m.seat_p).dot(f) > 0.7f) { m.go_wp = 2; to = m.go_p; }
			}
		}
		// (straight there: the take turns him round itself and the fit eases the rest; only from beside a seat, a little out
		// in front of it till level with his place, or his capsule rides up the seat's edge)
		if (m.act == MoveState::GO_SIT && to.distance_to(m.go_p) < 0.01f) {
			const Vector3 f = fwd_m(m.seat_yaw), X = left_m(m.seat_yaw);
			const float e = std::abs((p - m.go_p).dot(X));
			to = m.go_p + f * 0.35f * std::min(std::max((e - 0.15f) / 0.6f, 0.0f), 1.0f);
		}
		m.go_to = to;
		const float dl = Vector2(to.x - p.x, to.z - p.z).length();
		const bool at_end = to.distance_to(m.go_p) < 0.4f;
		const float dg = Vector2(m.go_p.x - p.x, m.go_p.z - p.z).length();
		// (going past it: he'd circle back round, so he starts it there, the fit easing up to 0.6 m)
		const bool past = at_end && dg < 0.6f && dg > m.go_best + 0.03f;
		if (at_end) m.go_best = std::min(m.go_best, dg);
		if (past || (at_end && dg < 0.12f) || m.act_t > 20.0f || (at_end && dg < 0.35f && speed < 0.3f && m.act_t > 0.6f)) {
			moves_end_steer();
			if (m.act == MoveState::GO_SIT) {
				const double len = fig->clip_len(SIT_DOWN);
				s.blend_req = 0.3f;
				moves_start_fit(SIT_DOWN, m.seat_yaw, m.seat_p, len, TravState::THEN_IDLE, true);
				s.q_clip[0] = SIT_IDLE; s.q_t0[0] = 0.0; s.q_end[0] = 0.0; s.q_has_y[0] = false; s.nq = 1; s.q_then = TravState::THEN_IDLE;
				m.act = MoveState::SITTING_DOWN; m.act_t = 0.0f; m.n_sit++; m.last = "Stand_To_Sit";
			} else {
				Node3D *pk = live(m.pick_id);
				if (!pk) { m.act = MoveState::NONE; return false; }
				const double at = fig->clip_meta(PLACE, "hands_low_at", 4.6);
				s.blend_req = 0.3f;
				moves_start_fit(PLACE, m.go_yaw, m.pick_hips, at, TravState::THEN_IDLE);
				// (the hands' point at the lowest, not the hips': the fit's offset is the hands')
				m.act = MoveState::PICKING; m.act_t = 0.0f; m.attached = false; m.last = "Tender_Placement (pick up)";
			}
			return false;
		}
		// (near his place and it well round from his heading: his walking turn is over a metre round, so he stops, turns on
		// the spot and steps in, as anyone does by a bench)
		if (at_end && m.go_pause <= 0.0f && dg < 2.5f && dg > 0.3f && speed > 0.3f) {
			const Vector3 u = Vector3(m.go_p.x - p.x, 0, m.go_p.z - p.z) / dg;
			if (fwd_m(yaw).dot(u) < 0.25f) { m.go_pause = 1.0f; m.n_go_pause++; }
		}
		if (m.go_pause > 0.0f) {
			cmd = Vector2(); scripted = true;
			if (speed < 0.05f) m.go_pause = 0.0f;
		} else moves_steer(to, p_fwd, p_right);
		if (e) { moves_end_steer(); m.act = MoveState::NONE; }   // (E again: never mind)
		return false;
	}
	if (s.mode == TravState::COVER && e && m.n_lean > 0) { crouch = false; return false; }   // (leaning: E again, off the wall)
	if (s.mode != TravState::NONE) return false;
	const bool floor = is_on_floor();
	// --- E: sit on a seat near him, take up a prop near him, put down what he holds, lean on the wall he faces
	if (e && floor && is_inside_tree()) {
		if (moves_interact(p_fwd, p_right)) return false;
	}
	if (!floor || crouch) return false;
	const Vector3 v(get_velocity().x, 0, get_velocity().z);
	const float vl = v.length();
	const Vector3 vd = vl > 0.01f ? v / vl : fwd_m(yaw);
	// --- bumps: a pole or a person (something thin, not a wall: the traversal has walls) right in his way
	if (vl > 0.7f && m.bump_cd <= 0.0f && ss) {
		const float reach = 0.42f + vl * 0.06f;
		const Vector3 c = p + Vector3(0, 1.2f, 0);
		const HitM h = ray_m(ss, self, c, c + vd * reach, 1 | 16);   // (the ground's things and the crowd's bodies)
		if (h.ok && std::fabs(h.n.y) < 0.5f) {
			const Vector3 L = UPM.cross(vd).normalized();
			const HitM a = ray_m(ss, self, c + L * 0.32f, c + L * 0.32f + vd * (reach + 0.3f), 1 | 16);
			const HitM b = ray_m(ss, self, c - L * 0.32f, c - L * 0.32f + vd * (reach + 0.3f), 1 | 16);
			if (!a.ok && !b.ok) {
				m.bump_cd = 2.0f; m.n_bump++;
				if (vl < 2.0f) {
					static const StringName W(AN("Shove_Reaction_b"));
					s.blend_req = 0.15f; trav_start(W, 0.0, 0.0, yaw, TravState::THEN_IDLE); s.plant_on = true; m.last = "Shove_Reaction_b";
				} else {
					static const StringName R2[2] = { AN("Stumble_Backwards"), AN("Shoulder_Hit_And_Fall") };
					const StringName c2 = R2[vl > 3.6f ? 1 : 0];
					s.blend_req = 0.12f; trav_start(c2, 0.0, 0.0, yaw, TravState::THEN_IDLE);
					static const StringName UP_SIT(TN2("Standing_Up_a"));
					s.q_clip[0] = UP_SIT; s.q_t0[0] = 0.0; s.q_end[0] = 0.0; s.q_has_y[0] = false; s.nq = 1; s.q_then = TravState::THEN_IDLE;
					m.n_stumble++; m.last = String(c2).replace("pact/", "");
				}
				m.act = MoveState::STUMBLE; m.act_t = 0.0f;
				set_velocity(Vector3());
				return true;
			}
		}
	}
	// --- a kerb caught at a run: the stumble (or now and then the trip and fall)
	if (pr_tier >= 1 && vl > 2.0f && m.trip_cd <= 0.0f && ss) {
		bool h1 = false, h2 = false;
		const float g1 = trav_ground(p + vd * 0.25f, 0.4f, 0.3f, &h1), g2 = trav_ground(p + vd * 0.6f, 0.4f, 0.3f, &h2);
		const float rise = g2 - (float)p.y;
		if (h1 && h2 && rise > 0.08f && rise < 0.3f && g1 < (float)p.y + 0.04f) {
			m.trip_cd = 2.5f;
			m.rng ^= m.rng << 13; m.rng ^= m.rng >> 17; m.rng ^= m.rng << 5;
			const float r = (m.rng % 10000u) / 10000.0f;
			if (r < m.trip_chance) {
				const bool fall = r < m.trip_chance * 0.3f || pr_tier >= 2 && r < m.trip_chance * 0.5f;
				m.n_trip++;
				if (fall) {
					static const StringName T(AN("Tripping_a")), UPP(TN2("Getting_Up"));
					s.blend_req = 0.1f; trav_start(T, 0.0, 0.0, yaw_m(vd), TravState::THEN_IDLE);
					s.q_clip[0] = UPP; s.q_t0[0] = 0.0; s.q_end[0] = 0.0; s.q_has_y[0] = false; s.nq = 1; s.q_then = TravState::THEN_IDLE;
					m.last = "Tripping_a";
				} else {
					static const StringName J(AN("Jogging_Stumble"));
					s.blend_req = 0.1f; trav_start(J, 0.0, 0.0, yaw_m(vd), TravState::THEN_RUN);
					s.vel_out = vd * std::max(vl, run_speed); s.hscale = std::min(std::max(vl / 2.55f, 0.8f), 1.5f);
					m.last = "Jogging_Stumble";
				}
				s.dy0 = 0.0f; s.dy1 = rise; s.ya = 0.12f; s.yb = 0.4f;
				m.act = MoveState::STUMBLE; m.act_t = 0.0f;
				return true;
			}
		}
	}
	// --- the sidestep: a gap ahead narrower than his shoulders' swing (two posts, a person and a pole)
	if (pr_tier == 0 && vl > 0.5f && wl > 0.3f && m.side_cd <= 0.0f && ss) {
		const Vector3 L = UPM.cross(vd).normalized();
		auto gap_at = [&](float d, float &r_w) -> bool {
			const Vector3 c = p + vd * d + Vector3(0, 1.1f, 0);
			const HitM a = ray_m(ss, self, c, c + L * 0.6f, 1 | 16), b = ray_m(ss, self, c, c - L * 0.6f, 1 | 16);
			if (!a.ok || !b.ok) return false;
			r_w = a.p.distance_to(b.p); return true;
		};
		float w = 0.0f;
		if (gap_at(0.7f, w) && w > 0.3f && w < 0.68f && !ray_m(ss, self, p + Vector3(0, 1.1f, 0), p + Vector3(0, 1.1f, 0) + vd * 1.4f).ok) {
			float depth = 0.3f, w2 = 0.0f;
			for (float d = 0.9f; d < 3.0f; d += 0.2f) { if (gap_at(d, w2) && w2 < 0.75f) depth = d - 0.6f; else break; }
			static const StringName SL(AN("Left_Strafe_Walking")), SR(AN("Right_Strafe_Walking"));
			m.rng ^= m.rng << 13; m.rng ^= m.rng >> 17; m.rng ^= m.rng << 5;
			const bool left = (m.rng & 1u) != 0u;
			const StringName c = left ? SL : SR;
			// (its travel along his left (or right): turned so it goes the way he was going)
			const Vector3 tr(fig->clip_meta(c, "travel_x", left ? 1.54 : -1.54), 0, 0);
			const float yf = yaw_m(vd) + (left ? -PI_M * 0.5f : PI_M * 0.5f);
			s.blend_req = 0.25f; trav_start(c, 0.0, 0.0, yf, TravState::THEN_WALK);
			s.plant_on = true; s.vel_out = vd * walk_speed * 0.8f;
			const float sv = 1.49f;
			m.side_len = (depth + 1.0f) / sv; m.side_dir = vd; m.side_cd = m.side_len + 1.0f;
			m.act = MoveState::SIDESTEP; m.act_t = 0.0f; m.n_side++; m.last = String(c).replace("pact/", "");
			(void)tr;
			return true;
		}
	}
	return false;
}

// where the take's hands are at its lowest must be the prop's middle: that point (world)
Vector3 CityPlayer::moves_hands_target(Node3D *p_pk) const {
	const Transform3D T = p_pk->get_global_transform();
	Node3D *gr = Object::cast_to<Node3D>(p_pk->get_node_or_null(NodePath("grip_r")));
	Node3D *gl = Object::cast_to<Node3D>(p_pk->get_node_or_null(NodePath("grip_l")));
	const Vector3 mid = (gr && gl) ? (gr->get_position() + gl->get_position()) * 0.5f : (gr ? gr->get_position() : Vector3());
	return T.xform(mid);
}

bool CityPlayer::moves_interact(const Vector3 &p_fwd, const Vector3 &p_right) {
	MoveState &m = mvs; TravState &s = trv;
	const Vector3 p = get_global_position();
	static const StringName SIT_DOWN(AN("Stand_To_Sit")), PLACE(AN("Tender_Placement"));
	// a seat near him (not with a box in his arms)
	if (!(m.prop && m.two) && fig->clip_len(SIT_DOWN) > 0.0) {
		TypedArray<Node> seats = get_tree()->get_nodes_in_group("player_seat");
		float best = 3.0f; Node3D *bs = nullptr; Vector3 bp;
		for (int i = 0; i < seats.size(); i++) {
			Node3D *n = Object::cast_to<Node3D>(seats[i]);
			if (!n) continue;
			const Transform3D T = n->get_global_transform();
			const Vector3 X = Vector3(T.basis.get_column(0).x, 0, T.basis.get_column(0).z).normalized();
			const float half = 0.5f * (float)(double)n->get_meta("seat_len", 0.6) - 0.3f;
			const float u = std::min(std::max((p - T.origin).dot(X), -std::max(half, 0.0f)), std::max(half, 0.0f));
			const Vector3 sp = T.origin + X * u;
			const float d = Vector2(sp.x - p.x, sp.z - p.z).length();
			if (d < best) { best = d; bs = n; bp = sp; }
		}
		if (bs) {
			const Transform3D T = bs->get_global_transform();
			m.seat_p = bp; m.seat_yaw = yaw_m(Vector3(T.basis.get_column(2).x, 0, T.basis.get_column(2).z)); m.seat_id = bs->get_instance_id();
			// where he stands to sit: the take's hips at its start, from its hips at the end on the seat
			const double len = fig->clip_len(SIT_DOWN);
			const Vector3 h0 = fig->clip_hips_at(SIT_DOWN, 0.0), he = fig->clip_hips_at(SIT_DOWN, len);
			const Basis R(UPM, m.seat_yaw);
			const Vector3 A = m.seat_p - R.xform(Vector3(he.x, 0, he.z));
			m.go_p = A + R.xform(Vector3(h0.x, 0, h0.z)); m.go_p.y = p.y; m.go_yaw = m.seat_yaw;
			m.scripted_was = scripted; m.cmd_was = cmd;
			m.act = MoveState::GO_SIT; m.act_t = 0.0f; m.go_wp = 0; m.go_best = 1e9f; m.go_stall = 0.0f; m.go_pause = 0.0f;
			return true;
		}
	}
	// a prop to take up (his hands empty)
	if (!m.prop && fig->clip_len(PLACE) > 0.0) {
		TypedArray<Node> pks = get_tree()->get_nodes_in_group("player_pickup");
		float best = 3.0f; Node3D *bk = nullptr;
		for (int i = 0; i < pks.size(); i++) {
			Node3D *n = Object::cast_to<Node3D>(pks[i]);
			if (!n) continue;
			const float d = Vector2(n->get_global_position().x - p.x, n->get_global_position().z - p.z).length();
			if (d < best) { best = d; bk = n; }
		}
		if (bk) {
			const Vector3 c = moves_hands_target(bk);
			// (faced the way he comes from: from any side)
			Vector3 dir = Vector3(c.x - p.x, 0, c.z - p.z);
			if (dir.length() < 0.05f) dir = fwd_m(yaw);
			// (square to one of its sides, the nearest to the way he comes: a box on a stand or a shelf is reached across its face)
			float Y = yaw_m(dir);
			{
				const float by = bk->get_global_rotation().y, q = (float)Math_PI * 0.5f;
				Y = by + q * std::round((float)Math::wrapf(Y - by, -Math_PI, Math_PI) / q);
			}
			const double at = fig->clip_meta(PLACE, "hands_low_at", 4.6);
			const Vector3 hl((float)fig->clip_meta(PLACE, "hands_low_x", 0.0), 0, (float)fig->clip_meta(PLACE, "hands_low_z", 0.6));
			const Vector3 hk = fig->clip_hips_at(PLACE, at), h0 = fig->clip_hips_at(PLACE, 0.0);
			const Basis R(UPM, Y);
			// (the take's hands at the lowest are hl in its frame; its hips then hk: the hips' point so the hands are on c)
			const Vector3 hips_at = c - R.xform(Vector3(hl.x - hk.x, 0, hl.z - hk.z));
			const Vector3 A = hips_at - R.xform(Vector3(hk.x, 0, hk.z));
			m.go_p = A + R.xform(Vector3(h0.x, 0, h0.z)); m.go_p.y = p.y; m.go_yaw = Y;
			m.pick_hips = hips_at;
			m.pick_id = bk->get_instance_id();
			m.scripted_was = scripted; m.cmd_was = cmd;
			m.act = MoveState::GO_PICK; m.act_t = 0.0f; m.go_wp = 0; m.go_best = 1e9f; m.go_stall = 0.0f; m.go_pause = 0.0f;
			return true;
		}
	}
	// what he holds: set down in front of him
	if (m.prop && fig->clip_len(PLACE) > 0.0) {
		s.blend_req = 0.3f;
		trav_start(PLACE, 0.0, 0.0, yaw, TravState::THEN_IDLE); s.plant_on = true;
		m.act = MoveState::PUTTING; m.act_t = 0.0f; m.attached = false; m.last = "Tender_Placement (put down)";
		return true;
	}
	// a wall he faces, standing: he leans on it (his back to it: the standing cover's)
	if (speed < 0.3f && trav_lib() && !(m.prop && m.two)) {
		crouch = true; s.crouch_was = true;
		if (trav_cover_enter(fwd_m(yaw) * 1.0f)) { m.n_lean++; m.last = "lean"; return true; }
		crouch = false; s.crouch_was = false;
	}
	(void)p_fwd; (void)p_right;
	return false;
}

void CityPlayer::interact_move() { mvs.e_want = true; }
void CityPlayer::set_look(const Vector3 &p_at, bool p_on) { mvs.look_set = p_on; mvs.look_p = p_at; }
void CityPlayer::set_trip_chance(double p_c) { mvs.trip_chance = (float)p_c; }

// a push from someone (the crowd, a script): from behind he is shoved on, from the side spun, from the front set back
void CityPlayer::bump(const Vector3 &p_from_dir) {
	MoveState &m = mvs; TravState &s = trv;
	if (!fig || s.mode != TravState::NONE || !trav_lib()) return;
	const Vector3 d = Vector3(p_from_dir.x, 0, p_from_dir.z).normalized();   // (the way the push goes)
	const float a = wrapm(yaw_m(d) - yaw);
	static const StringName BACK(AN("Shove_Reaction_a")), SIDE(AN("Shoved_Reaction_With_Spin")), FRONT(AN("Shove_Reaction_b"));
	StringName c = std::fabs(a) < 0.8f ? BACK : (std::fabs(a) > 2.3f ? FRONT : SIDE);
	float y = yaw;
	if (c == SIDE) y = yaw_m(d);   // (its shove carries him along its forward)
	s.blend_req = 0.12f; trav_start(c, 0.0, 0.0, y, TravState::THEN_IDLE); s.plant_on = true;
	m.act = MoveState::STUMBLE; m.act_t = 0.0f; m.n_bump++; m.last = String(c).replace("pact/", "");
}

Dictionary CityPlayer::get_moves() const {
	const MoveState &m = mvs;
	Dictionary d;
	d["act"] = m.act; d["carry"] = get_carry(); d["two"] = m.two; d["carry_w"] = m.carry_w; d["up_clip"] = m.up_clip;
	d["sit"] = m.n_sit; d["go_to"] = m.go_to; d["go_p"] = m.go_p; d["go_wp"] = m.go_wp; d["go_pause"] = m.n_go_pause; d["stand"] = m.n_stand; d["bump"] = m.n_bump; d["trip"] = m.n_trip; d["stumble"] = m.n_stumble;
	d["side"] = m.n_side; d["pick"] = m.n_pick; d["put"] = m.n_put; d["lean"] = m.n_lean; d["look"] = m.n_look;
	d["go_miss"] = m.go_miss; d["carry_miss_most"] = m.carry_miss_most; d["chest_gap"] = m.chest_gap; d["last"] = m.last;
	d["look_w"] = m.layer ? m.layer->look_w : 0.0f; d["look_yaw"] = m.layer ? m.layer->look_yaw : 0.0f;
	d["fit"] = m.layer ? m.layer->fit_min : 1.0f; d["miss_l"] = m.layer ? m.layer->miss[0] : 0.0f; d["miss_r"] = m.layer ? m.layer->miss[1] : 0.0f;
	d["seat"] = m.seat_p; d["go_p"] = m.go_p;
	return d;
}
