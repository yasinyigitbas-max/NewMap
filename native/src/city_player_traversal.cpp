// CityPlayer's TRAVERSAL (Yasin, 22 Nov: "do the jumps, and crouches, again no ual ... fall after 15 seconds if we stand
// at an edge idle ... less than 2m land smooth, more than 3m land hard, taller than 5m fall and mess the landing 10
// percent, 90 land hard, taller than 7m fall landing. no land to roll ... thin and short: run jump over it (bushes), if
// walking vault over; short but thick: run jump and land running, or walk up slowly and climb onto it and get up ...
// crouching and approaching any collision we should enter cover, near another cover and pushed towards it switch cover,
// cover walk right left too"). Everything is the Mixamo takes of the "ptrav" library (tools/people/make_player_traversal.gd);
// the moves are kinematic: rays and the capsule's own sweeps find the world, the clip's root motion moves him.
// Without the library (an old export) none of it runs and the UAL jump / crouch / climb stay as they were.
//
// THRESHOLDS: a step (kerb) up to 0.24 m stays the plain step; an obstacle 0.26-1.2 m high is "short" (over it: 1.2 m),
// under 0.6 m deep "thin" (a bush strip); 1.2-2.5 m a climb; higher nothing. A drop from a ledge from 0.5 m. Landing by
// the height fallen: under 3 m soft (2-3 m was not given: soft), from 3 m hard, from 5 m hard 90 % / messed 10 %, from
// 7 m Falling Idle in the air and Falling To Landing. Cover: a wall from 0.6 m high (from 1.45 m: standing cover). An
// edge: ground 0.75 m or more down within 0.5 m of him.
#include "city_player.h"
#include "city_ped.h"
#include "el_sfx.h"
#include "foot_steps.h"
#include "hand_grip.h"

#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/world3d.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

namespace {
const float PI_F = 3.14159265f, TAU_F = 6.2831853f;
float wrapf(float a) { a = std::fmod(a + PI_F, TAU_F); if (a < 0.0f) a += TAU_F; return a - PI_F; }
float sstep(float a, float b, float x) {
	if (b <= a) return x >= b ? 1.0f : 0.0f;
	const float t = std::min(std::max((x - a) / (b - a), 0.0f), 1.0f);
	return t * t * (3.0f - 2.0f * t);
}
float yaw_of(const Vector3 &v) { return std::atan2(v.x, v.z); }
Vector3 fwd_of(float y) { return Vector3(std::sin(y), 0.0f, std::cos(y)); }
Vector3 left_of(float y) { return Vector3(std::cos(y), 0.0f, -std::sin(y)); }   // (the figure's +x)
const Vector3 UP(0, 1, 0);

struct Hit { bool ok = false; Vector3 p, n; };
Hit ray(PhysicsDirectSpaceState3D *ss, const RID &self, const Vector3 &a, const Vector3 &b) {
	Hit h;
	if (!ss) return h;
	Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(a, b, 1);
	TypedArray<RID> ex; ex.push_back(self); q->set_exclude(ex);
	const Dictionary d = ss->intersect_ray(q);
	if (d.is_empty()) return h;
	h.ok = true; h.p = d["position"]; h.n = d["normal"];
	return h;
}

#define TN(name) StringName("ptrav/" name)
// the pools (each never plays the same take twice running)
enum { P_STAND = 0, P_RJUMP, P_DROP, P_SOFT, P_HARD, P_MESS, P_PRONE_UP, P_CR_OUT, P_CW, P_CS_L, P_CS_R, P_HS_L, P_HS_R, P_CX_LOW, P_VAULT, P_CLIMB_RUN, P_CLIMB_MID, P_STAND_UP, P_COV_SW, P_N };
}

bool CityPlayer::trav_lib() const {
	static const StringName K(TN("Jump_a"));
	return fig && fig->clip_len(K) > 0.0;
}

int CityPlayer::trav_pick(int p_pool, int p_n) {
	if (p_n <= 1) { trv.last[p_pool] = 0; return 0; }
	trv.rng ^= trv.rng << 13; trv.rng ^= trv.rng >> 17; trv.rng ^= trv.rng << 5;
	const int last = trv.last[p_pool];
	int k = (int)(trv.rng % (uint32_t)(last >= 0 && last < p_n ? p_n - 1 : p_n));
	if (last >= 0 && last < p_n && k >= last) k++;
	trv.last[p_pool] = k;
	return k;
}

float CityPlayer::trav_ground(const Vector3 &p_at, float p_up, float p_down, bool *r_hit) const {
	PhysicsDirectSpaceState3D *ss = get_world_3d().is_valid() ? get_world_3d()->get_direct_space_state() : nullptr;
	const Hit h = ray(ss, get_rid(), p_at + Vector3(0, p_up, 0), p_at - Vector3(0, p_down, 0));
	if (r_hit) *r_hit = h.ok;
	return h.ok ? (float)h.p.y : (float)p_at.y - p_down;
}

static float clip_f(const CityPed *f, const StringName &c, const char *k, float def) { return (float)f->clip_meta(c, k, def); }
static float curve_f(const CityPed *f, const StringName &c, const char *k, double t, float def) { return (float)f->clip_curve(c, k, t, def); }
static float trav_yo(TravState &s, float p_dt);

// A clip move starts: the figure where he stands, its hips where his capsule is
void CityPlayer::trav_start(const StringName &p_clip, double p_t0, double p_end, float p_yaw, int p_then) {
	const double len = fig->clip_len(p_clip);
	TravState &s = trv;
	const Vector3 hl_old = trav_hips_now();
	const double blend = s.blend_req; s.blend_req = 0.2f;
	s.mode = TravState::CLIP; s.clip = p_clip; s.t0 = std::min(std::max(p_t0, 0.0), len); s.t = s.t0;
	s.t_end = p_end > 0.0 ? std::min(p_end, len) : len; s.rate = 1.0;
	if (p_then == TravState::THEN_RUN && p_end <= 0.0) {
		// (on running: handed over in a stride's flight, both feet up: handed over with a foot down, the foot the take had
		// planted went on with him at a run as its pose faded: it slid up to 0.6 m)
		const double land = fig->clip_meta(p_clip, "land_at", -1.0);
		for (double t = len - 1.0 / 30.0; t > std::max(land + 0.12, s.t0 + 0.3); t -= 1.0 / 60.0)
			if (curve_f(fig, p_clip, "elev", t, 0.0f) > 0.04f) { s.t_end = t; break; }
	}
	s.yaw = p_yaw; s.yaw_to = p_yaw; s.yaw_ease = 0.0f; s.turn_k = 0.0f;
	s.dy0 = s.dy1 = 0.0f; s.ya = s.yb = 0.0f; s.dxz = Vector3(); s.xa = s.xb = 0.0f; s.d0 = Vector3(); s.d0_t = 0.3f;
	s.lift = 0.0f; s.la = s.lb = 0.0f; s.hscale = 1.0f; s.then = p_then; s.air_at = -1.0; s.cancel_at = -1.0; s.air_vy = 0.0f;
	s.vel_out = Vector3(); s.nq = 0; s.plant_on = false; s.token++;
	s.loop_clip = !(bool)fig->clip_meta(p_clip, "root", true);
	s.h0 = fig->clip_hips_at(p_clip, s.t0);
	const Vector3 p = get_global_position();
	s.anchor = p - Basis(UP, p_yaw).xform(Vector3(s.h0.x, 0, s.h0.z));
	s.anchor.y = p.y - curve_f(fig, p_clip, "elev", s.t0, 0.0f);
	s.prev_body = p; s.last_fig_y = (float)s.anchor.y;
	s.last_move = String(p_clip).replace("ptrav/", "");
	step_mode = 0; yaw_r = 0.0f; pw_settle = 0.0f;
	idv_take = -1; idv_t = 0.0; idv_span = 0.0;
	fig->set_next_blend(blend);
	trav_hand(hl_old, s.anchor, p_yaw, blend);
	fig->set_next_seek(s.t0);
}

// where the figure stands and the hips are at clip time t (the fit's offsets included)
static void trav_pose(const CityPed *fig, const TravState &s, double t, float &r_yaw, Vector3 &r_fig, Vector3 &r_body) {
	float y = s.yaw;
	if (s.yaw_ease > 0.0f) y = s.yaw + wrapf(s.yaw_to - s.yaw) * sstep((float)s.t0, (float)s.t0 + s.yaw_ease, (float)t);
	if (s.turn_k != 0.0f) y += s.turn_k * curve_f(fig, s.clip, "yaw", t, 0.0f);
	const Basis R(UP, y);
	const Vector3 h = fig->clip_hips_at(s.clip, t);
	Vector3 fa = s.anchor + R.xform(Vector3(h.x - s.h0.x, 0, h.z - s.h0.z) * (s.hscale - 1.0f)) + s.dxz * sstep(s.xa, s.xb, (float)t)
			+ s.d0 * (1.0f - sstep((float)s.t0, (float)s.t0 + s.d0_t, (float)t));
	float arc = 0.0f;
	if (s.lift > 0.0f && s.lb > s.la) { const float u = std::min(std::max(((float)t - s.la) / (s.lb - s.la), 0.0f), 1.0f); arc = s.lift * std::sin(PI_F * u); }
	fa.y += s.dy0 + (s.dy1 - s.dy0) * sstep(s.ya, s.yb, (float)t) + arc;
	Vector3 body = fa + R.xform(Vector3(h.x, 0, h.z));
	body.y = fa.y + curve_f(fig, s.clip, "elev", t, 0.0f);
	r_yaw = y; r_fig = fa; r_body = body;
}

void CityPlayer::trav_clip(float p_dt, const Vector3 &p_want) {
	TravState &s = trv;
	s.t += p_dt * s.rate;
	const double t = std::min(s.t, s.t_end);
	if (s.loop_clip) {   // (a loop's travel is in its vz / vx curves, not its hips)
		const Basis R(UP, s.yaw);
		const float vz = curve_f(fig, s.clip, "vz", t, 0.0f), vx = curve_f(fig, s.clip, "vx", t, 0.0f);
		s.anchor += R.xform(Vector3(vx, 0, vz)) * (p_dt * (float)s.rate * s.hscale);
	}
	float y; Vector3 fa, body;
	trav_pose(fig, s, t, y, fa, body);
	set_global_position(body);
	const Vector3 vel = p_dt > 0.0f ? (body - s.prev_body) / p_dt : Vector3();
	set_velocity(vel);
	s.prev_body = body; s.last_fig_y = (float)fa.y;
	speed = Vector3(vel.x, 0, vel.z).length(); move_speed = 0.0f;
	yaw = y;
	fig->drive(Transform3D(Basis(UP, y + trav_yo(s, p_dt)), fa + trav_fo(p_dt)), s.clip, s.rate, -2.0, 7000 + (s.token & 255));
	fig_drawn_at = fa;
	if (plant) { plant->set_active(s.plant_on); plant->set_influence(s.plant_on ? 1.0f : 0.0f); plant->fwd = fwd_of(yaw); plant->floor_node = nullptr; }   // (the moves keep the pin as tuned, no ground fit)
	if (s.air_at >= 0.0 && t >= s.air_at) {   // off the ledge / up in the air: gravity has him
		Vector3 v = vel;
		if (s.air_vy > 0.0f) v = Vector3(s.vel_out.x, s.air_vy, s.vel_out.z);
		trav_air(v, s.from_y);
		return;
	}
	if (s.cancel_at >= 0.0 && t >= s.cancel_at && p_want.length() > 0.3f) { s.then = TravState::THEN_WALK; s.nq = 0; trav_done(); return; }
	if (s.t >= s.t_end) trav_done();
}

// the move's end: on to what follows it
void CityPlayer::trav_done() {
	TravState &s = trv;
	const double te = std::min(s.t, s.t_end);
	float y; Vector3 fa, body;
	trav_pose(fig, s, te, y, fa, body);
	const float face_e = curve_f(fig, s.clip, "face", te, 0.0f), face_s = curve_f(fig, s.clip, "face", s.t0, 0.0f);
	if (s.nq > 0) {   // the next clip of the chain: his hips go on from where they are
		const StringName c = s.q_clip[0]; const double t0 = s.q_t0[0], te2 = s.q_end[0]; const float fy = s.q_has_y[0] ? s.q_fig_y[0] : (float)fa.y;
		for (int i = 1; i < s.nq; i++) { s.q_clip[i - 1] = s.q_clip[i]; s.q_t0[i - 1] = s.q_t0[i]; s.q_end[i - 1] = s.q_end[i]; s.q_fig_y[i - 1] = s.q_fig_y[i]; s.q_has_y[i - 1] = s.q_has_y[i]; }
		const int nq = s.nq - 1, then = s.q_then;
		const float ny = y + wrapf(face_e - curve_f(fig, c, "face", t0, face_e));
		set_global_position(body);
		s.blend_req = 0.25f;
		trav_start(c, t0, te2, ny, nq > 0 ? TravState::THEN_IDLE : then);
		s.fo.y += s.anchor.y - fy;
		s.anchor.y = fy; s.last_fig_y = fy;
		s.nq = nq; s.q_then = then;
		return;
	}
	Vector3 p = body;
	bool hit = false;
	const float g = trav_ground(p, 0.6f, 0.45f, &hit);
	if (hit) p.y = g;
	set_global_position(p);
	s.mode = TravState::NONE;
	if (!hit && s.then != TravState::THEN_COVER) { trav_air(Vector3(s.vel_out.x, 0, s.vel_out.z), (float)body.y); return; }
	float ny = y;
	if (s.then == TravState::THEN_IDLE) ny = y + wrapf(face_e - (-0.68f));         // (the standing idles' hips face -39 degrees)
	else if (s.then == TravState::THEN_CROUCH) ny = y + wrapf(face_e - 0.087f);    // (the crouching idle's: +5)
	else if (s.then == TravState::THEN_WALK || s.then == TravState::THEN_RUN) ny = y + std::min(std::max(wrapf(face_e - face_s), -0.6f), 0.6f);
	if (s.then != TravState::THEN_COVER) yaw = ny;
	step_mode = 0; yaw_r = 0.0f; pw_settle = 0.0f; gait_i = -1; pw_main = -1; pw_join = 0.0f; step_lat = 0.0f;
	const double hb = 0.3;
	fig->set_next_blend(hb);
	trav_hand(trav_hips_now(), p, s.then == TravState::THEN_COVER ? y : yaw, hb);
	// (to the locomotion: the hand-over offset follows the old pose out as it is actually drawn; see trav_figure)
	s.fo_track = s.then != TravState::THEN_COVER && s.fo_t > 0.0f; s.fo_track_t = 0.0f; s.fo_c_n = 0;
	if (plant && s.then != TravState::THEN_COVER) plant->reset();   // (the walk's pins from before the move are stale)
	switch (s.then) {
		case TravState::THEN_RUN: {
			move_speed = std::max(s.vel_out.length(), run_speed); set_velocity(fwd_of(yaw) * move_speed + Vector3(0, -0.5f, 0)); crouch = false; break;
		}
		case TravState::THEN_WALK: move_speed = walk_speed * 0.8f; set_velocity(fwd_of(yaw) * move_speed + Vector3(0, -0.5f, 0)); crouch = false; break;
		case TravState::THEN_CROUCH: move_speed = 0.0f; set_velocity(Vector3()); crouch = true; break;
		case TravState::THEN_COVER: s.mode = TravState::COVER; s.cov_yaw_prev = y; s.cov_hand = StringName(); s.cov_stop = 0.0f; s.cov_move_t = 0.0f; s.cov_edge_t = 0.0f; s.cov_away_t = 0.0f; s.cov_clip = StringName(); set_velocity(Vector3()); break;
		default: move_speed = 0.0f; set_velocity(Vector3()); crouch = false; break;
	}
	s.crouch_was = crouch; crouch_prev = crouch; crouch_t = 99.0f;
	speed = Vector3(get_velocity().x, 0, get_velocity().z).length();
}

// the air clip's figure: its hips over the capsule (the clips' roots are left where the take began: a metre off, and the
// landing then slid the whole figure that metre as it took over)
static Vector3 air_fig(const CityPed *f, const StringName &c, double t, const Vector3 &p, float y) {
	const Vector3 h = f->clip_hips_at(c, t);
	return p - Basis(UP, y).xform(Vector3(h.x, 0, h.z));
}

// IN THE AIR: falling (or flying from a jump) under gravity; the clip by the fall ahead
void CityPlayer::trav_air(const Vector3 &p_v, float p_from_y) {
	TravState &s = trv;
	s.mode = TravState::AIR; s.air_v = p_v; s.from_y = p_from_y; s.air_t = 0.0f; s.token++;
	s.prev_body = get_global_position();
	bool hit = false;
	const float g = trav_ground(get_global_position(), 0.0f, 40.0f, &hit);
	const float drop = hit ? p_from_y - g : 99.0f;
	s.air_long = drop > 7.0f;
	static const StringName F_AIR(TN("Falling_Air")), F_IDLE(TN("Falling_Idle"));
	s.air_clip = s.air_long ? F_IDLE : F_AIR;
	fig->set_next_blend(0.3);
	trav_hand(trav_hips_now(), air_fig(fig, s.air_clip, 0.0, get_global_position(), yaw), yaw, 0.3);
	s.last_move = String(s.air_clip).replace("ptrav/", "");
}

void CityPlayer::trav_air_step(float p_dt) {
	TravState &s = trv;
	s.air_t += p_dt;
	Vector3 v = s.air_v; v.y -= 9.81f * p_dt;
	set_velocity(v);
	move_and_slide();
	const Vector3 got = get_velocity();
	s.air_v = Vector3(got.x, v.y, got.z);
	if (is_on_ceiling() && s.air_v.y > 0.0f) s.air_v.y = 0.0f;
	speed = 0.0f;
	const Vector3 p = get_global_position();
	s.prev_body = p;
	if (is_on_floor() && v.y <= 0.0f) { trav_land(s.from_y - (float)p.y); return; }
	if (p.y < s.from_y - 300.0f) { s.mode = TravState::NONE; return; }   // (nothing under him at all)
	const Vector3 fa = air_fig(fig, s.air_clip, fig->current_clip() == s.air_clip ? fig->clip_pos() : 0.0, p, yaw);
	fig->drive(Transform3D(Basis(UP, yaw + trav_yo(s, p_dt)), fa + trav_fo(p_dt)), s.air_clip, 1.0, -1.0);
	fig_drawn_at = fa;
	if (plant) { plant->set_active(false); plant->set_influence(0.0f); }
}

// LANDING, by the height fallen
void CityPlayer::trav_land(float p_drop) {
	TravState &s = trv;
	static const StringName SOFT[4] = { TN("Jumping_a"), TN("Jumping_Down_a"), TN("Jumping_Down_b"), TN("Jumping_Down_c") };
	static const StringName HARD[2] = { TN("Hard_Landing_a"), TN("Hard_Landing_b") };
	static const StringName MESS[3] = { TN("Falling_Flat_Impact"), TN("Fall_Flat"), TN("Falling_Down_On_Ass") };
	static const StringName BIG(TN("Falling_To_Landing")), FALLEN(TN("Fallen_Idle")), UP_SIT(TN("Standing_Up_a"));
	static const StringName UP_PRONE[2] = { TN("Getting_Up"), TN("Standing_Up_b") };
	s.last_drop = p_drop;
	StringName c; double t0 = 0.0; int kind = 0;   // 0 soft 1 hard 2 messed 3 the big fall
	if (p_drop > 7.0f) { c = BIG; kind = 3; }
	else if (p_drop > 5.0f) {
		s.rng ^= s.rng << 13; s.rng ^= s.rng >> 17; s.rng ^= s.rng << 5;
		if ((float)(s.rng % 10000u) < s.mess_chance * 10000.0f) { c = MESS[trav_pick(P_MESS, 3)]; kind = 2; }
		else { c = HARD[trav_pick(P_HARD, 2)]; kind = 1; }
	}
	else if (p_drop > 3.0f) { c = HARD[trav_pick(P_HARD, 2)]; kind = 1; }
	else { c = SOFT[trav_pick(P_SOFT, 4)]; kind = 0; }
	const double imp = fig->clip_meta(c, "impact_at", -1.0);
	if (c == MESS[1]) t0 = 0.65; else if (c == MESS[2]) t0 = 0.4; else t0 = imp > 0.0 ? std::max(imp - 0.03, 0.0) : 0.0;
	s.blend_req = 0.12f;
	trav_start(c, t0, 0.0, yaw, TravState::THEN_IDLE);
	if (plant) plant->reset();   // (no pin carried over from before the fall: its own reset is by wall-clock time)
	s.plant_on = kind != 2;
	if (kind == 0) { s.cancel_at = t0 + 0.45; s.n_soft++; s.last_land = "soft"; }
	else if (kind == 1) { s.cancel_at = t0 + 1.1; s.n_hard++; s.last_land = "hard"; }
	else if (kind == 3) { s.cancel_at = t0 + 0.6; s.n_big++; s.last_land = "fall_landing"; }
	else {
		s.n_mess++; s.last_land = "messed";
		if (c == MESS[2]) {   // down on his backside: a moment there, then up
			s.q_clip[0] = FALLEN; s.q_t0[0] = 0.0; s.q_end[0] = 1.0; s.q_has_y[0] = false;
			s.q_clip[1] = UP_SIT; s.q_t0[1] = 0.0; s.q_end[1] = 0.0; s.q_has_y[1] = false;
			s.nq = 2;
		} else {
			const int k = trav_pick(P_PRONE_UP, 2);
			s.q_clip[0] = UP_PRONE[k]; s.q_t0[0] = k == 1 ? 4.4 : 0.0; s.q_end[0] = 0.0; s.q_has_y[0] = false; s.nq = 1;
		}
		s.q_then = TravState::THEN_IDLE;
	}
	if (kind != 0 || p_drop > 1.5f) vox(V_LAND, 0.3);   // (the breath knocked out of him from 1.5 m, as before)
	{
		static const char *NAME[FootSteps::N_KINDS] = { "concrete", "grass", "sand", "dirt", "wood" };
		const Vector3 gp = get_global_position(); const int k = FootSteps::class_at(gp.x, gp.z);
		elsfx::play(this, String("res://audio/steps/footstep_land_") + String(NAME[k]) + String("_"), kind == 0 ? -5.0f : 0.0f, 0.05f, Vector3(), 25.0f, 0, 3);
	}
}

// JUMP (Space, pad A): off a ledge ahead he jumps down; running, a running jump at his pace; else a standing jump
bool CityPlayer::trav_jump(const Vector3 &p_want) {
	TravState &s = trv;
	PhysicsDirectSpaceState3D *ss = get_world_3d()->get_direct_space_state();
	const Vector3 p = get_global_position();
	const float wl = Vector3(p_want.x, 0, p_want.z).length();
	const Vector3 dir = wl > 0.3f ? Vector3(p_want.x, 0, p_want.z) / wl : fwd_of(yaw);
	const bool running = pr_tier >= 1 && speed > 2.0f;
	if (!running) {
		bool hit = false;
		const float g = trav_ground(p + dir * 0.75f, 0.4f, 40.0f, &hit);
		if ((!hit || p.y - g >= 0.5f) && !ray(ss, get_rid(), p + Vector3(0, 0.5f, 0), p + Vector3(0, 0.5f, 0) + dir * 0.8f).ok) {
			static const StringName DROP[3] = { TN("Jumping_Down_b"), TN("Jumping_Down_c"), TN("Jumping_a") };
			const StringName c = DROP[trav_pick(P_DROP, 3)];
			const double leave = fig->clip_meta(c, "leave_at", 0.5);
			trav_start(c, std::max(leave - 0.55, 0.0), leave + 0.05, yaw_of(dir), TravState::THEN_IDLE);
			s.air_at = leave; s.from_y = (float)p.y; s.n_drop++;
			vox(V_JUMP, 0.4, 0.6f);
			return true;
		}
	}
	if (running) {
		static const StringName RJ[2] = { TN("Running_Jump_a"), TN("Jump_b") };
		const int k = trav_pick(P_RJUMP, 2);
		const StringName c = RJ[k];
		const double len = fig->clip_len(c);
		const float tz = (float)(fig->clip_hips_at(c, len).z - fig->clip_hips_at(c, 0.0).z);
		const float hs = std::min(std::max(speed / std::max(tz / (float)len, 1.0f), 0.7f), 1.5f);
		const Vector3 f = fwd_of(yaw);
		const float reach = tz * hs + 0.3f;
		if (!ray(ss, get_rid(), p + Vector3(0, 0.5f, 0), p + Vector3(0, 0.5f, 0) + f * reach).ok && !ray(ss, get_rid(), p + Vector3(0, 1.3f, 0), p + Vector3(0, 1.3f, 0) + f * reach).ok) {
			trav_start(c, 0.0, 0.0, yaw, TravState::THEN_RUN);
			s.hscale = hs; s.vel_out = f * speed; s.n_rjump++;
			vox(V_JUMP, 0.4, 0.8f);
			return true;
		}
	}
	// something to get over or onto just ahead: the jump is that move
	if (trav_obstacle(fwd_of(yaw) * walk_speed, (float)get_physics_process_delta_time(), true)) return true;
	// standing (or walking: a take-off, the air, a landing)
	static const StringName SJ[4] = { TN("Jump_a"), TN("Jumping_b"), TN("Jumping_Up"), TN("Jumping_c") };
	const bool walking = speed > 0.5f;
	int k = walking ? 2 + trav_pick(P_STAND, 2) % 2 : trav_pick(P_STAND, 4);
	const StringName c = SJ[k];
	if (k < 2) {
		trav_start(c, 0.0, 0.0, yaw, TravState::THEN_IDLE);
		s.cancel_at = fig->clip_meta(c, "land_at", 1.0) + 0.25;
		s.plant_on = true;
	} else {
		const double air = std::max(fig->clip_meta(c, "air_at", 0.1), 0.05);
		trav_start(c, 0.0, air + 0.1, yaw, TravState::THEN_IDLE);
		s.air_at = air; s.air_vy = 3.3f; s.vel_out = Vector3(get_velocity().x, 0, get_velocity().z); s.from_y = (float)p.y;
	}
	s.n_jump++;
	vox(V_JUMP, 0.4, 0.8f);
	return true;
}

// OBSTACLES ahead, walking or running into them: over, onto, up
bool CityPlayer::trav_obstacle(const Vector3 &p_want, float p_dt, bool p_force) {
	TravState &s = trv;
	if (step_mode == 3) return false;
	PhysicsDirectSpaceState3D *ss = get_world_3d()->get_direct_space_state();
	const RID self = get_rid();
	const Vector3 p = get_global_position();
	const Vector3 dir = fwd_of(yaw);
	const float wl = Vector3(p_want.x, 0, p_want.z).length();
	if (!p_force && (wl < 0.3f || Vector3(p_want.x, 0, p_want.z).dot(dir) < 0.8f * wl)) return false;   // (only the way he faces and goes; a jump at it: whatever his pace)
	const bool running = pr_tier >= 1 && speed > 2.0f;
	const float look = running ? 2.8f : 1.3f;
	Hit face;
	for (float hgt : { 0.3f, 0.7f }) {
		const Hit h = ray(ss, self, p + Vector3(0, hgt, 0), p + Vector3(0, hgt, 0) + dir * look);
		if (h.ok && h.n.dot(dir) < -0.5f && std::fabs(h.n.y) < 0.5f && (!face.ok || (h.p - p).length() < (face.p - p).length())) face = h;
	}
	if (!face.ok) return false;
	const float D = Vector2(face.p.x - p.x, face.p.z - p.z).length();
	const Hit top = ray(ss, self, Vector3(face.p.x, p.y + 3.2f, face.p.z) + dir * 0.08f, Vector3(face.p.x, p.y + 0.05f, face.p.z) + dir * 0.08f);
	if (!top.ok || top.n.y < 0.7f) return false;
	const float h = (float)(top.p.y - p.y);
	if (h <= 0.26f || h > 2.5f) return false;
	float depth = 99.0f;
	for (float a = 0.15f; a <= 2.45f; a += 0.1f) {
		const Vector3 q = Vector3(face.p.x, 0, face.p.z) + dir * a;
		const Hit d = ray(ss, self, Vector3(q.x, top.p.y + 0.4f, q.z), Vector3(q.x, p.y - 1.0f, q.z));
		if (!d.ok || d.p.y < top.p.y - 0.15f) { depth = a - 0.05f; break; }
	}
	const bool thin = depth < 0.6f, short_ = h < 1.2f;
	auto room_at = [&](const Vector3 &at) { Transform3D tt = get_global_transform(); tt.origin = at; return !test_move(tt, Vector3(0, 0.05f, 0)); };
	const Vector3 on_top = Vector3(face.p.x, top.p.y + 0.02f, face.p.z) + dir * std::min(0.45f, std::max(depth * 0.5f, 0.3f));
	const float tol = std::max(speed, 0.5f) * p_dt + 0.02f;
	auto hips_z = [&](const StringName &c, double t) { return (float)fig->clip_hips_at(c, t).z; };
	s.last_obstacle = String("h ") + String::num(h, 2) + String(" depth ") + String::num(depth, 2) + String(running ? " running" : " walking");
	if (short_ && thin) {
		const float centre = D + depth * 0.5f;
		if (running) {   // OVER IT AT A RUN: the jump's apex over its middle, on running
			static const StringName RJ[2] = { TN("Running_Jump_a"), TN("Jump_b") };
			const int k = s.last[P_RJUMP] == 0 ? 1 : 0;
			const StringName c = RJ[k];
			const double len = fig->clip_len(c), apex = fig->clip_meta(c, "apex_at", len * 0.4);
			const float tz = hips_z(c, len) - hips_z(c, 0.0);
			const float hs = std::min(std::max(speed / std::max(tz / (float)len, 1.0f), 0.7f), 1.5f);
			const float lapex = (hips_z(c, apex) - hips_z(c, 0.0)) * hs;
			if (centre > lapex + tol) return false;   // (not yet)
			if (centre < lapex - 0.6f) return false;
			s.last[P_RJUMP] = k;
			trav_start(c, 0.0, 0.0, yaw, TravState::THEN_RUN);
			s.hscale = hs; s.vel_out = dir * speed;
			s.dxz = dir * (centre - lapex); s.xa = 0.0f; s.xb = (float)apex;
			s.lift = std::max(0.0f, h + 0.14f - curve_f(fig, c, "elev", apex, 0.3f));
			s.la = (float)fig->clip_meta(c, "air_at", 0.05); s.lb = (float)fig->clip_meta(c, "land_at", len * 0.7);
			s.n_run_over++; s.n_rjump++; vox(V_JUMP, 0.4, 0.7f);
			return true;
		}
		// WALKING: a vault over it
		static const StringName VA[2] = { TN("Vault_Over_Box_To_Cover"), TN("Jumping_Over_Into_Combat") };
		const int k = s.last[P_VAULT] == 0 ? 1 : 0;
		const StringName c = VA[k];
		const double key = fig->clip_meta(c, "key_at", 1.0);
		double t0 = std::max(key - 0.85, 0.0);
		float lkey = hips_z(c, key) - hips_z(c, t0);
		if (centre > lkey + tol && !(p_force && centre < lkey + 0.8f)) return false;
		while (centre < lkey - 0.05f && t0 < key - 0.3) { t0 += 1.0 / 30.0; lkey = hips_z(c, key) - hips_z(c, t0); }   // (already close: in later)
		if (centre < lkey - 0.6f) return false;
		s.last[P_VAULT] = k;
		trav_start(c, t0, std::min(key + (k == 0 ? 0.75 : 0.6), fig->clip_len(c)), yaw, TravState::THEN_WALK);
		s.dxz = dir * (centre - lkey); s.xa = (float)t0; s.xb = (float)key;
		const float ek = curve_f(fig, c, "elev", key, 0.3f);
		s.lift = std::max(0.0f, h + 0.1f - ek); s.la = (float)key - 0.45f; s.lb = (float)key + 0.45f;
		s.vel_out = dir * walk_speed;
		s.n_vault++; vox(V_CLIMB, 0.6, 0.5f);
		return true;
	}
	if (!room_at(on_top)) return false;
	if (short_) {
		if (running) {   // ONTO IT AT A RUN: the jump lands on its top, on running
			static const StringName RJ[2] = { TN("Running_Jump_a"), TN("Jump_b") };
			const int k = s.last[P_RJUMP] == 0 ? 1 : 0;
			const StringName c = RJ[k];
			const double len = fig->clip_len(c), land = fig->clip_meta(c, "land_at", len * 0.7), air = fig->clip_meta(c, "air_at", 0.05);
			const float tz = hips_z(c, len) - hips_z(c, 0.0);
			const float hs = std::min(std::max(speed / std::max(tz / (float)len, 1.0f), 0.7f), 1.5f);
			const float lland = (hips_z(c, land) - hips_z(c, 0.0)) * hs;
			const float target = D + 0.4f;
			if (target > lland + tol) return false;
			if (target < lland - 0.6f) return false;
			s.last[P_RJUMP] = k;
			trav_start(c, 0.0, 0.0, yaw, TravState::THEN_RUN);
			s.hscale = hs; s.vel_out = dir * speed;
			s.dxz = dir * (target - lland); s.xa = 0.0f; s.xb = (float)land;
			s.dy1 = h; s.ya = (float)air; s.yb = (float)land;
			s.lift = 0.12f; s.la = (float)air; s.lb = (float)land;
			s.n_run_onto++; s.n_rjump++; vox(V_JUMP, 0.4, 0.7f);
			return true;
		}
		// WALKING UP TO IT: he climbs onto it and gets up
		static const StringName C(TN("Running_Jump_Climb"));
		const double top_at = fig->clip_meta(C, "top_at", 0.75), air = fig->clip_meta(C, "air_at", 0.55);
		const double t0 = std::max(air - 0.3, 0.0);
		const float lface = hips_z(C, top_at) - 0.35f - hips_z(C, t0);
		if (D > lface + tol && !(p_force && D < lface + 0.8f)) return false;
		trav_start(C, t0, 0.0, yaw, TravState::THEN_IDLE);
		s.dxz = dir * (D - lface); s.xa = (float)t0; s.xb = (float)top_at;
		s.dy1 = h - clip_f(fig, C, "rise", 0.86f); s.ya = (float)air; s.yb = (float)top_at;
		s.n_climb++; vox(V_CLIMB, 0.6, 0.7f);
		return true;
	}
	// 1.2-2.5 m: up the wall
	static const StringName CTS[3] = { TN("Crouch_To_Stand_a"), TN("Crouch_To_Stand_b"), TN("Crouched_To_Standing") };
	auto stand_up_after = [&](float top_y) {
		const int k = trav_pick(P_STAND_UP, 3);
		s.q_clip[s.nq] = CTS[k]; s.q_t0[s.nq] = 0.0; s.q_end[s.nq] = 0.0; s.q_fig_y[s.nq] = top_y; s.q_has_y[s.nq] = true; s.nq++;
		s.q_then = TravState::THEN_IDLE;
	};
	if (running) {
		static const StringName CR[2] = { TN("Sprint_To_Wall_Climb"), TN("Climbing_Double") };
		const int k = s.last[P_CLIMB_RUN] == 0 ? 1 : 0;
		const StringName c = CR[k];
		const double top_at = fig->clip_meta(c, "top_at", 1.4), air = fig->clip_meta(c, "air_at", 0.1);
		const double t0 = std::max(air - 0.35, 0.0);
		const float lface = hips_z(c, top_at) - 0.35f - hips_z(c, t0);
		if (D > lface + tol || D < lface - 0.8f) return false;
		s.last[P_CLIMB_RUN] = k;
		trav_start(c, t0, 0.0, yaw, TravState::THEN_IDLE);
		s.dxz = dir * (D - lface); s.xa = (float)t0; s.xb = (float)top_at;
		s.dy1 = h - (clip_f(fig, c, "lo_end", 0.1f) - 0.10f) + clip_f(fig, c, "lo0", 0.1f) - 0.10f; s.ya = (float)air; s.yb = (float)top_at;
		if (k == 0) stand_up_after((float)top.p.y);
		s.n_climb_high++; vox(V_CLIMB, 0.6);
		return true;
	}
	if (h >= 1.9f) {   // a high wall: up to a hang from it, then pull up over it
		static const StringName FH(TN("Stand_To_Freehang")), CS(TN("Climbing_Single"));
		const double len = fig->clip_len(FH);
		const float lface = hips_z(FH, len) + 0.30f - hips_z(FH, 0.0);
		if (D > lface + tol) return false;
		const float hang = clip_f(fig, CS, "hand0", 2.2f);
		trav_start(FH, 0.0, 0.0, yaw, TravState::THEN_IDLE);
		s.dxz = dir * (D - lface); s.xa = 0.0f; s.xb = (float)len;
		s.dy1 = h - hang; s.ya = (float)fig->clip_meta(FH, "air_at", 0.6); s.yb = (float)fig->clip_meta(FH, "apex_at", 0.8);
		s.q_clip[0] = CS; s.q_t0[0] = 0.0; s.q_end[0] = 0.0; s.q_fig_y[0] = (float)top.p.y - hang; s.q_has_y[0] = true; s.nq = 1;
		stand_up_after((float)top.p.y);
		s.n_climb_high++; vox(V_CLIMB, 0.6);
		return true;
	}
	{   // 1.2-1.9 m walking: a braced climb from the wall, or the double climb
		static const StringName CM[2] = { TN("Braced_Hang_To_Crouch"), TN("Climbing_Double") };
		const int k = s.last[P_CLIMB_MID] == 0 ? 1 : 0;
		const StringName c = CM[k];
		if (k == 0) {
			if (D > 0.5f + tol) return false;
			s.last[P_CLIMB_MID] = k;
			const float hand = clip_f(fig, c, "hand0", 1.55f);
			s.blend_req = 0.35f;
			trav_start(c, 0.0, 0.0, yaw, TravState::THEN_IDLE);
			const Vector3 h0w = Basis(UP, yaw).xform(Vector3(s.h0.x, 0, s.h0.z));
			const Vector3 a_was = s.anchor;
			s.anchor = Vector3(face.p.x, 0, face.p.z) - dir * 0.33f - h0w; s.anchor.y = a_was.y;
			s.fo += a_was - s.anchor;   // (the hand-over keeps the hips where they were; the old pose fades into the hang at the wall)
			s.fo_len = s.fo_t = 0.35f;
			s.dy0 = h - hand; s.dy1 = h - (clip_f(fig, c, "lo_end", 1.5f) - 0.10f); s.ya = 0.0f; s.yb = (float)fig->clip_meta(c, "top_at", 0.8);
			s.fo.y -= s.dy0;   // (up to the hang as the walk fades out, not in one frame)
			stand_up_after((float)top.p.y);
		} else {
			const double top_at = fig->clip_meta(c, "top_at", 2.5), air = fig->clip_meta(c, "air_at", 0.1);
			const double t0 = std::max(air, 0.0);
			const float lface = hips_z(c, top_at) - 0.35f - hips_z(c, t0);
			if (D > lface + tol) return false;
			s.last[P_CLIMB_MID] = k;
			trav_start(c, t0, 0.0, yaw, TravState::THEN_IDLE);
			s.dxz = dir * (D - lface); s.xa = (float)t0; s.xb = (float)top_at;
			s.dy1 = h - (clip_f(fig, c, "lo_end", 1.9f) - 0.10f) + clip_f(fig, c, "lo0", 0.1f) - 0.10f; s.ya = (float)t0; s.yb = (float)top_at;
		}
		s.n_climb_high++; vox(V_CLIMB, 0.6);
		return true;
	}
}

// COVER: crouched, moving into a wall at least 0.6 m high
bool CityPlayer::trav_cover_enter(const Vector3 &p_want) {
	TravState &s = trv;
	PhysicsDirectSpaceState3D *ss = get_world_3d()->get_direct_space_state();
	const RID self = get_rid();
	const Vector3 p = get_global_position();
	const Vector3 dir = Vector3(p_want.x, 0, p_want.z).normalized();
	const Hit w = ray(ss, self, p + Vector3(0, 0.45f, 0), p + Vector3(0, 0.45f, 0) + dir * 0.9f);
	if (!w.ok || w.n.dot(dir) > -0.6f || std::fabs(w.n.y) > 0.4f) return false;
	const float D = Vector2(w.p.x - p.x, w.p.z - p.z).length();
	if (D > 0.62f) return false;
	if (!ray(ss, self, p + Vector3(0, 0.62f, 0), p + Vector3(0, 0.62f, 0) + dir * 1.0f).ok) return false;   // (under 0.6 m: nothing to hide behind)
	const bool high = ray(ss, self, p + Vector3(0, 1.45f, 0), p + Vector3(0, 1.45f, 0) + dir * 1.0f).ok;
	const Vector3 N = Vector3(w.n.x, 0, w.n.z).normalized();
	static const StringName IN_LOW(TN("Stand_To_Cover_b")), IN_HIGH(TN("Stand_To_Cover_a"));
	const StringName c = high ? IN_HIGH : IN_LOW;
	const float yd = yaw_of(-N);
	// (the clip's own steps carry him to the wall: it starts where the travel left in it is the way to go, so only a
	// little is left to slide in; a planted foot then stays put: the whole correction slid both feet 0.3 m)
	const double len = fig->clip_len(c);
	const Vector3 he = fig->clip_hips_at(c, len);
	double t0 = 0.3;
	{
		const Basis Rd(UP, yd);
		const Vector3 want_end0 = Vector3(w.p.x, p.y, w.p.z) + N * 0.33f;
		const float need = (want_end0 - p).dot(-N);
		float best = 1e9f;
		for (double t = 0.0; t <= len * 0.6; t += 1.0 / 30.0) {
			const Vector3 h = fig->clip_hips_at(c, t);
			const float go = Rd.xform(Vector3(he.x - h.x, 0, he.z - h.z)).dot(-N);
			const float e = std::fabs(go - need) + 0.05f * std::fabs((float)t - 0.3f);
			if (e < best) { best = e; t0 = t; }
		}
	}
	s.blend_req = 0.3f;
	trav_start(c, t0, 0.0, yd, TravState::THEN_COVER);
	const Vector3 end = s.anchor + Basis(UP, yd).xform(Vector3(he.x, 0, he.z));
	const Vector3 want_end = Vector3(w.p.x, p.y, w.p.z) + N * 0.33f;
	s.dxz = Vector3(want_end.x - end.x, 0, want_end.z - end.z); s.xa = (float)s.t0; s.xb = (float)len;
	s.plant_on = true;
	s.wall_p = w.p; s.wall_n = N; s.high = high; s.cov_dir = 0; s.cov_clip = StringName();
	s.n_cover++;
	return true;
}

void CityPlayer::trav_cover(float p_dt, const Vector3 &p_want) {
	TravState &s = trv;
	PhysicsDirectSpaceState3D *ss = get_world_3d()->get_direct_space_state();
	const RID self = get_rid();
	const Vector3 p = get_global_position();
	const Vector3 N = s.wall_n;
	const float yb = yaw_of(N);                 // (he faces away from the wall)
	const Vector3 T = left_of(yb);              // (his left along it)
	const Vector3 in(p_want.x, 0, p_want.z);
	const float il = in.length();
	const float a = il > 0.05f ? in.dot(T) / il : 0.0f, aw = il > 0.05f ? in.dot(-N) / il : 0.0f;
	s.cov_peek_cd = std::max(s.cov_peek_cd - p_dt, 0.0f);
	static const StringName OUT_LOW(TN("Cover_To_Stand_a")), OUT_HIGH(TN("Cover_To_Stand_b")), SNEAK_OFF(TN("Sneak_Off_The_Cover"));
	static const StringName IDLE_LOW(TN("Crouch_Cover_Idle")), IDLE_HIGH(TN("Cover_Idle"));
	static const StringName TURN_LOW(TN("Crouch_Cover_Turn")), TURN_HIGH(TN("Standing_Cover_Turn"));
	static const StringName SW[2] = { TN("Crouch_Cover_To_Cover"), TN("Crouch_Cover_To_Cover_M") };
	static const StringName PEEK[2] = { TN("Crouch_Look_Around_Corner"), TN("Crouch_Look_Around_Corner_M") };
	static const StringName VAULT(TN("Vault_Over_Box_To_Cover"));
	auto flip_of = [&](const StringName &c) { return (bool)fig->clip_meta(c, "flip", false); };
	auto draw_yaw = [&](const StringName &c) { return yb + (flip_of(c) ? PI_F : 0.0f); };
	yaw = yb;
	// OUT: the crouch let go: up out of cover
	if (!crouch) {
		const StringName c = s.high ? OUT_HIGH : OUT_LOW;
		trav_start(c, 0.0, 0.0, draw_yaw(c), TravState::THEN_IDLE); s.plant_on = true; s.n_cover_exit++;
		return;
	}
	// away from it: out (stood up, or backing off still crouched)
	if (il > 0.3f && aw < -0.6f) s.cov_away_t += p_dt; else s.cov_away_t = 0.0f;
	if (s.cov_away_t > 0.2f) {
		if (s.high) { trav_start(OUT_HIGH, 0.0, 0.0, draw_yaw(OUT_HIGH), TravState::THEN_IDLE); crouch = false; }
		else {
			const int k = trav_pick(P_CX_LOW, 2);
			if (k == 0) { trav_start(OUT_LOW, 0.0, 0.0, draw_yaw(OUT_LOW), TravState::THEN_IDLE); crouch = false; }
			else trav_start(SNEAK_OFF, 0.0, std::min(2.0, fig->clip_len(SNEAK_OFF)), yb + PI_F, TravState::THEN_CROUCH);
		}
		s.plant_on = true; s.n_cover_exit++;
		return;
	}
	// into it: a low thin cover is vaulted, into cover on its far side
	if (!s.high && il > 0.3f && aw > 0.75f) {
		s.cov_edge_t += p_dt;
		if (s.cov_edge_t > 0.35f) {
			float depth = 99.0f; float topy = -1e9f;
			const Hit tp = ray(ss, self, Vector3(s.wall_p.x, p.y + 1.5f, s.wall_p.z) - N * 0.08f, Vector3(s.wall_p.x, p.y + 0.05f, s.wall_p.z) - N * 0.08f);
			if (tp.ok) {
				topy = (float)tp.p.y;
				for (float d = 0.15f; d <= 1.0f; d += 0.1f) {
					const Vector3 q = Vector3(s.wall_p.x, 0, s.wall_p.z) - N * d;
					const Hit h2 = ray(ss, self, Vector3(q.x, topy + 0.3f, q.z), Vector3(q.x, p.y - 0.5f, q.z));
					if (!h2.ok || h2.p.y < topy - 0.15f) { depth = d - 0.05f; break; }
				}
			}
			if (tp.ok && depth < 0.6f && topy - p.y < 1.2f) {
				const float yd = yaw_of(-N);
				const double key = fig->clip_meta(VAULT, "key_at", 1.0);
				trav_start(VAULT, std::max(key - 0.45, 0.0), 0.0, yd, TravState::THEN_COVER);
				const Vector3 hk = fig->clip_hips_at(VAULT, key);
				const Vector3 at_key = s.anchor + Basis(UP, yd).xform(Vector3(hk.x, 0, hk.z));
				const Vector3 centre = Vector3(s.wall_p.x, 0, s.wall_p.z) - N * (depth * 0.5f);
				s.dxz = Vector3(centre.x - at_key.x, 0, centre.z - at_key.z); s.xa = (float)s.t0; s.xb = (float)key;
				s.lift = std::max(0.0f, (topy - (float)p.y) + 0.1f - curve_f(fig, VAULT, "elev", key, 0.3f)); s.la = (float)key - 0.4f; s.lb = (float)key + 0.4f;
				s.wall_p = Vector3(s.wall_p.x, s.wall_p.y, s.wall_p.z) - N * depth; s.wall_n = -N;
				s.n_cover_vault++; s.n_vault++; vox(V_CLIMB, 0.6, 0.5f);
				return;
			}
		}
	} else if (std::fabs(a) <= 0.5f) s.cov_edge_t = 0.0f;
	const float hgt = s.high ? 1.2f : 0.45f;
	Vector3 v(0, -0.5f, 0);
	StringName clip = s.high ? IDLE_HIGH : IDLE_LOW;
	double cs = 1.0;
	if (il > 0.3f && std::fabs(a) > 0.5f) {
		const int dir = a > 0.0f ? 1 : -1;
		const Vector3 ahead = p + T * (float)dir * 0.45f + Vector3(0, hgt, 0);
		const Hit cont = ray(ss, self, ahead, ahead - N * 0.9f);
		if (cont.ok && cont.n.dot(N) > 0.8f) {   // ALONG IT
			if (s.cov_dir != 0 && dir != s.cov_dir) {   // (back the other way: the cover turn)
				const StringName c = s.high ? TURN_HIGH : TURN_LOW;
				s.cov_dir = dir; s.cov_move_t = 0.0f;
				trav_start(c, 0.0, 0.0, draw_yaw(c), TravState::THEN_COVER); s.plant_on = true; s.n_cover_turn++;
				return;
			}
			if (dir != s.cov_dir || s.cov_clip == StringName()) {
				static const StringName LOW_L[1] = { TN("Crouched_Sneaking_Left") };
				static const StringName LOW_R[2] = { TN("Crouched_Sneaking_Right"), TN("Crouched_Sneaking_Right_aa") };
				static const StringName HI_L[2] = { TN("Left_Cover_Sneak_a"), TN("Left_Cover_Sneak_b") };
				static const StringName HI_R[2] = { TN("Right_Cover_Sneak_a"), TN("Right_Cover_Sneak_b") };
				// (by the side each take goes as drawn, "lat": the pack's mirrored takes go the other way to their names)
				StringName cand[7]; int nc = 0;
				const StringName *pools[2] = { s.high ? HI_L : LOW_L, s.high ? HI_R : LOW_R };
				const int pn[2] = { s.high ? 2 : 1, 2 };
				for (int q = 0; q < 2; q++) for (int i = 0; i < pn[q]; i++) if ((int)fig->clip_meta(pools[q][i], "lat", 0) == dir) cand[nc++] = pools[q][i];
				if (nc == 0) cand[nc++] = (dir > 0 ? pools[0][0] : pools[1][0]);
				s.cov_clip = cand[trav_pick(s.high ? (dir > 0 ? P_HS_L : P_HS_R) : (dir > 0 ? P_CS_L : P_CS_R), nc)];
			}
			s.cov_dir = dir; s.cov_move_t += p_dt; s.cov_edge_t = 0.0f; s.cov_stop = 0.0f;
			const Hit back = ray(ss, self, p + Vector3(0, hgt, 0), p + Vector3(0, hgt, 0) - N * 1.0f);
			const float dist = back.ok ? (float)(p - back.p).dot(N) : 0.33f;
			v += T * (float)dir * 0.95f + N * ((0.33f - dist) * 5.0f);
			if (back.ok) { s.wall_p = back.p; const Vector3 nn = Vector3(back.n.x, 0, back.n.z); if (nn.length() > 0.5f && nn.normalized().dot(N) > 0.8f) s.wall_n = nn.normalized(); }
			clip = s.cov_clip;
			const float gv = std::max(clip_f(fig, clip, "ground_v", 0.9f), 0.3f);
			cs = 0.95 / gv;
		} else {   // AT ITS EDGE: on to another cover across the gap, or a look round the corner
			s.cov_move_t = 0.0f; s.cov_edge_t += p_dt;
			if (s.cov_edge_t > 0.3f) {
				for (float d = 0.9f; d <= 2.75f; d += 0.3f) {
					const Vector3 q = p + T * (float)dir * d + Vector3(0, 0.45f, 0);
					const Hit o = ray(ss, self, q, q - N * 1.0f);
					if (!o.ok || o.n.dot(N) < 0.8f) continue;
					int k = 0;
					const float lx0 = (float)(fig->clip_hips_at(SW[0], fig->clip_len(SW[0])).x - fig->clip_hips_at(SW[0], 0.0).x);
					if ((lx0 > 0.0f ? 1 : -1) != dir) k = 1;
					const StringName c = SW[k];
					const float lx = (float)(fig->clip_hips_at(c, fig->clip_len(c)).x - fig->clip_hips_at(c, 0.0).x);
					trav_start(c, 0.0, 0.0, yb, TravState::THEN_COVER);
					const double len = fig->clip_len(c);
					s.dxz = T * (float)dir * (d - std::fabs(lx)) + N * (0.33f - (float)(Vector3(p.x, o.p.y, p.z) - o.p).dot(N));
					s.xa = 0.2f; s.xb = (float)len - 0.2f;
					s.wall_p = o.p; s.plant_on = true; s.cov_dir = dir; s.cov_edge_t = 0.0f;
					s.n_cover_switch++;
					return;
				}
				if (!s.high && s.cov_peek_cd <= 0.0f) {
					const float lean0 = (float)(fig->clip_hips_at(PEEK[0], 1.5).x - fig->clip_hips_at(PEEK[0], 0.0).x);
					const int k = (lean0 > 0.0f ? 1 : -1) == dir ? 0 : 1;
					trav_start(PEEK[k], 0.0, 0.0, yb, TravState::THEN_COVER); s.plant_on = true;
					s.cov_peek_cd = 2.0f; s.cov_edge_t = 0.0f; s.n_peek++;
					return;
				}
			}
		}
	} else if (s.cov_clip != StringName() && s.cov_dir != 0 && s.cov_stop < 0.3f) {
		// LET GO mid-sneak: the sneak and he slow down together (its planted foot stays where it is), then the idle
		s.cov_stop += p_dt;
		const float k = std::max(0.0f, 1.0f - s.cov_stop / 0.3f);
		clip = s.cov_clip;
		const float gv = std::max(clip_f(fig, clip, "ground_v", 0.9f), 0.3f);
		cs = std::max(0.95 / gv * k, 0.01);
		v += T * (float)s.cov_dir * 0.95f * k;
		if (s.cov_stop >= 0.3f) { s.cov_clip = StringName(); s.cov_move_t = 0.0f; clip = s.high ? IDLE_HIGH : IDLE_LOW; cs = 1.0; fig->set_next_blend(0.45); }
	} else { s.cov_move_t = 0.0f; s.cov_clip = StringName(); s.cov_stop = 0.0f; }
	// (while the hand-over into cover still runs, the clip it went to stays: a second change mid-way left the hips'
	// offset fading against the wrong pose, and the feet slid up to 0.6 m)
	if (s.fo_t > 0.0f) {
		if (s.cov_hand == StringName()) { s.cov_hand = clip; s.cov_hand_dir = s.cov_clip != StringName() ? s.cov_dir : 0; }
		else if (clip != s.cov_hand) {
			clip = s.cov_hand;
			const float lat = (float)v.dot(T);
			v -= T * lat;
			if (s.cov_hand_dir != 0) { v += T * (float)s.cov_hand_dir * 0.95f; cs = 0.95 / std::max(clip_f(fig, clip, "ground_v", 0.9f), 0.3f); } else cs = 1.0;
		}
	} else s.cov_hand = StringName();
	set_velocity(v);
	move_and_slide();
	speed = Vector3(get_velocity().x, 0, get_velocity().z).length();
	const Vector3 at = get_global_position();
	s.prev_body = at;
	const float dyw = draw_yaw(clip);
	if (std::fabs(wrapf(dyw - s.cov_yaw_prev)) > 0.3f) {   // (a cover take drawn turned round, or back: see TravState::yo)
		const float cur = s.yo_t > 0.0f ? s.yo * s.yo_t / s.yo_len : 0.0f;
		s.yo = cur + wrapf(s.cov_yaw_prev - dyw); s.yo_len = s.yo_t = s.cov_stop >= 0.3f ? 0.45f : 0.3f;
	}
	s.cov_yaw_prev = dyw;
	fig->drive(Transform3D(Basis(UP, dyw + trav_yo(s, p_dt)), at + trav_fo(p_dt)), clip, std::min(std::max(cs, s.cov_stop > 0.0f ? 0.01 : 0.3), 2.0), -1.0);
	fig_drawn_at = at;
	if (plant) { plant->set_active(true); plant->set_influence(1.0f); plant->skip = get_rid(); plant->fwd = fwd_of(yaw); plant->floor_node = nullptr; }
}

// AT AN EDGE: standing still with a drop beside him for 15 s, he loses his balance and falls
bool CityPlayer::trav_edge(float p_dt) {
	TravState &s = trv;
	const Vector3 p = get_global_position();
	s.edge_probe_t -= p_dt;
	if (s.edge_probe_t <= 0.0f) {
		s.edge_probe_t = 0.25f; s.edge_on = false;
		float best = -9.0f;
		for (int i = 0; i < 8; i++) {
			const float ang = yaw + (float)i * (TAU_F / 8.0f);
			const Vector3 d = fwd_of(ang);
			bool hit = false;
			const float g = trav_ground(p + d * 0.7f, 0.5f, 1.3f, &hit);
			if (!hit || p.y - g >= 0.75f) {
				const float score = d.dot(fwd_of(yaw));
				if (score > best) { best = score; s.edge_dir = d; s.edge_on = true; }
			}
			(void)g;
		}
	}
	if (!s.edge_on) { s.edge_t = 0.0f; return false; }
	s.edge_t += p_dt;
	if (s.edge_t < 15.0f) return false;
	s.edge_t = 0.0f;
	static const StringName C(TN("Falling_From_Losing_Balance"));
	const double leave = fig->clip_meta(C, "leave_at", 4.9);
	trav_start(C, 0.0, leave + 0.05, yaw, TravState::THEN_IDLE);
	s.yaw_to = yaw_of(s.edge_dir); s.yaw_ease = 1.2f;
	s.air_at = leave; s.from_y = (float)p.y; s.plant_on = true;
	s.n_balance++;
	return true;
}

// Each physics frame, before the rest of the player's: true when a traversal move has him this frame
bool CityPlayer::trav_physics(float p_dt, const Vector2 &p_mv, const Vector3 &p_fwd, const Vector3 &p_right) {
	if (!trav_lib()) return false;
	TravState &s = trv;
	Input *in = Input::get_singleton();
	if (!scripted && !frozen) {   // the pad: A jumps, B crouches
		const bool a = in->is_joy_button_pressed(0, JOY_BUTTON_A), b = in->is_joy_button_pressed(0, JOY_BUTTON_B);
		if (a && !s.pad_a) jump_want = true;
		if (b && !s.pad_b) crouch = !crouch;
		s.pad_a = a; s.pad_b = b;
	}
	const bool jw = jump_want; jump_want = false;     // (the UAL jump never: this one)
	crouch_prev = crouch; crouch_t = 99.0f;            // (and never the UAL crouch in / out)
	if (swimming || combat || frozen || act_left > 0.0 || climb != 0 || fig->get_mode() != CityPed::MODE_ANIM) {
		s.mode = TravState::NONE; s.crouch_was = crouch; s.strafe = false; s.edge_t = 0.0f;
		return false;
	}
	float top = pr_tier >= 2 ? fast_speed : (pr_tier >= 1 ? run_speed : walk_speed);
	if (crouch) top = walk_speed * 0.75f;
	const Vector3 want = (p_fwd * p_mv.y + p_right * p_mv.x) * top;
	const float wl = want.length();
	if (s.mode != TravState::NONE && (get_global_position() - s.prev_body).length() > 1.5f) { s.mode = TravState::NONE; s.fo_t = 0.0f; set_velocity(Vector3()); }   // (put somewhere else: the move is off)
	if (s.mode == TravState::CLIP) { trav_clip(p_dt, want); return true; }
	if (s.mode == TravState::AIR) { trav_air_step(p_dt); return true; }
	if (s.mode == TravState::COVER) { trav_cover(p_dt, want); return true; }
	const Vector3 p = get_global_position();
	const bool floor = is_on_floor();
	if (floor) { s.floor_y = (float)p.y; s.off_t = 0.0f; } else s.off_t += p_dt;
	// off a ledge (walked or run off it): falling, nothing under him
	if (!floor && s.off_t > 0.06f && get_velocity().y < -0.5f) {
		bool hit = false; trav_ground(p, 0.1f, 0.7f, &hit);
		if (!hit) { trav_air(get_velocity(), s.floor_y); return true; }
	}
	s.strafe = false;
	// THE CROUCH
	if (crouch != s.crouch_was) {
		s.crouch_was = crouch;
		if (crouch) s.n_crouch++;
		if (floor && speed < 0.5f) {
			if (crouch) { static const StringName IN(TN("Standing_To_Crouched")); trav_start(IN, 0.0, 0.0, yaw, TravState::THEN_CROUCH); s.plant_on = true; return true; }
			const float d = wl > 0.3f ? wrapf(yaw_of(want) - yaw) : 0.0f;
			static const StringName TURN(TN("Crouch_Turn_To_Stand"));
			const float ye = curve_f(fig, TURN, "yaw", fig->clip_len(TURN), 0.0f);
			if (wl > 0.3f && std::fabs(d) > 1.75f && std::fabs(ye) > 0.5f && (d * ye > 0.0f || std::fabs(d) > 2.6f)) {
				trav_start(TURN, 0.0, 0.0, yaw, TravState::THEN_WALK);
				s.turn_k = std::min(std::max(std::fabs(d) / std::fabs(ye), 0.6f), 1.4f) * (d * ye > 0.0f ? 1.0f : -1.0f);
				s.plant_on = true;
				return true;
			}
			static const StringName OUT[3] = { TN("Crouch_To_Stand_a"), TN("Crouch_To_Stand_b"), TN("Crouched_To_Standing") };
			trav_start(OUT[trav_pick(P_CR_OUT, 3)], 0.0, 0.0, yaw, TravState::THEN_IDLE); s.plant_on = true;
			return true;
		}
	}
	if (crouch && floor) {
		// up and away at a run: Crouched To Sprinting
		if (pr_tier >= 1 && wl > 0.3f && std::fabs(wrapf(yaw_of(want) - yaw)) < 1.2f) {
			static const StringName C(TN("Crouched_To_Sprinting"));
			crouch = false; s.crouch_was = false;
			trav_start(C, 0.0, 0.0, yaw_of(want), TravState::THEN_RUN);
			s.vel_out = fwd_of(yaw_of(want)) * (pr_tier >= 2 ? fast_speed : run_speed); s.plant_on = true; s.n_sprint_out++;
			return true;
		}
		if (wl > 0.3f && trav_cover_enter(want)) return true;
		// sideways (the stick across the view): he keeps facing the view and sneaks to the side
		if (wl > 0.3f && std::fabs(p_mv.x) > 0.45f && std::fabs(p_mv.x) > std::fabs(p_mv.y) * 1.2f) {
			s.strafe = true; s.strafe_yaw = yaw_of(p_fwd);
			yaw += std::min(std::max(wrapf(s.strafe_yaw - yaw), -4.0f * p_dt), 4.0f * p_dt);
		}
	}
	if (jw && floor) {
		if (crouch) { crouch = false; s.crouch_was = false; }
		else if (trav_jump(want)) return true;
	}
	if (!crouch && floor && wl > 0.3f && speed > 0.3f && trav_obstacle(want, p_dt, false)) return true;
	if (!crouch && floor && wl < 0.05f && speed < 0.05f && step_mode == 0) { if (trav_edge(p_dt)) return true; }
	else { s.edge_t = 0.0f; s.edge_probe_t = 0.0f; }
	return false;
}

// The figure's clip in the crouch (the normal flow moves him; this picks the Mixamo crouch loops)
void CityPlayer::trav_figure(StringName &r_clip, double &r_cs, double &r_hold, float &r_yaw_add, Vector3 &r_off) {
	TravState &s = trv;
	const float dt = (float)get_physics_process_delta_time();
	const float yoe = trav_lib() ? trav_yo(s, dt) : 0.0f;
	r_yaw_add = yoe;
	r_off = trav_lib() ? trav_fo(dt) : Vector3();
	// THE HAND-OVER TO THE LOCOMOTION, followed as drawn: the move's clip carried his hips metres along its root motion,
	// the walk / run / idle clips draw theirs over the figure's origin, so the figure is offset back by the old pose's
	// share of the hips while it fades. That share was assumed to fade linearly over the blend (fo, 0.3 s), but the
	// locomotion's clips cross-fade at their own rate (the stride-matched seek, the start handing to the loop): the hips
	// shot 0.2-0.3 m a frame into the jog and the planted foot went with them. So the share is read off the pose drawn
	// (the pelvis against the clip's own hips, a frame on by its last change) and the offset cancels exactly that.
	struct Track {
		CityPlayer *p; StringName &clip; Vector3 &off; float dt;
		~Track() {
			TravState &s = p->trv;
			if (!s.fo_track || !p->fig) return;
			if (s.mode != TravState::NONE) { s.fo_track = false; return; }
			s.fo_track_t += dt;
			const StringName cur = p->fig->current_clip();
			if (cur == s.clip) { off.x = s.fo.x; off.z = s.fo.z; return; }   // (the first frame: the old pose still whole, its whole offset)
			// (another clip of the locomotion's own: its cross-fade is not the move's; the offset held fades out plainly)
			if (s.fo_c_n == 0) s.fo_clip = cur;
			if (cur != s.fo_clip || s.fo_track_t > 1.2f) {
				s.fo_track = false;
				const float k = s.fo_t > 0.0f ? s.fo_t / s.fo_len : 0.0f;
				s.fo = Vector3(s.fo_off_dbg.x, s.fo.y * k, s.fo_off_dbg.z); s.fo_len = s.fo_t = 0.25f;
				off.x = s.fo.x; off.z = s.fo.z;
				return;
			}
			const Transform3D G = p->fig->get_global_transform();
			Vector3 c = G.affine_inverse().xform(p->pelvis_world()) - p->fig->clip_hips_at(cur, p->fig->clip_pos());
			c.y = 0.0f;
			Vector3 cp = c;
			if (s.fo_c_n > 0) cp = c + (c - s.fo_c_prev);
			else cp = c * std::max(1.0f - dt / std::max(s.fo_len, 0.05f), 0.0f);   // (no change seen yet: the blend's own rate)
			if (cp.dot(c) < 0.0f) cp = Vector3();
			s.fo_c_prev = c; s.fo_c_n++;
			const Vector3 o = G.basis.orthonormalized().xform(-cp);
			off.x = o.x; off.z = o.z; s.fo_off_dbg = off;
			if (s.fo_c_n > 3 && c.length() < 0.01f) { s.fo_track = false; s.fo.x = 0.0f; s.fo.z = 0.0f; }   // (done: the plain offset's sideways part is not to come back)
		}
	} track{ this, r_clip, r_off, dt };
	// (a crouch take drawn turned round, or back from one: the turn is the hand-over's, not a spin of the pose)
	auto add = [&](float a) {
		if (std::fabs(wrapf(a - s.add_prev)) > 0.3f && s.mode == TravState::NONE) {
			s.yo = yoe + wrapf(s.add_prev - a); s.yo_len = s.yo_t = 0.3f;
			r_yaw_add = a + yoe + wrapf(s.add_prev - a);
		} else r_yaw_add = a + yoe;
		s.add_prev = a;
	};
	if (!trav_lib() || trv.mode != TravState::NONE || !crouch || swimming || combat || airborne) { if (trav_lib() && trv.mode == TravState::NONE) add(0.0f); return; }
	static const StringName IDLE(TN("Crouching_Idle"));
	static const StringName FW[2] = { TN("Crouched_Walking"), TN("Sneaking_Forward") };
	static const StringName SL[1] = { TN("Crouched_Sneaking_Left") };
	static const StringName SR[2] = { TN("Crouched_Sneaking_Right"), TN("Crouched_Sneaking_Right_aa") };
	r_hold = -1.0;
	if (speed < 0.15f) { r_clip = IDLE; r_cs = 1.0; s.cw_side = 99; add(0.0f); return; }
	int side = 0;
	if (s.strafe) {
		const Vector3 v = get_velocity();
		side = Vector3(v.x, 0, v.z).dot(left_of(yaw)) > 0.0f ? 1 : -1;
	}
	if (side != s.cw_side || s.cw_clip == StringName()) {
		s.cw_side = side;
		if (side == 0) s.cw_clip = FW[trav_pick(P_CW, 2)];
		else {
			StringName cand[3]; int nc = 0;
			for (const StringName &c : SL) if ((int)fig->clip_meta(c, "lat", 0) == side) cand[nc++] = c;
			for (const StringName &c : SR) if ((int)fig->clip_meta(c, "lat", 0) == side) cand[nc++] = c;
			if (nc == 0) cand[nc++] = side > 0 ? SL[0] : SR[0];
			s.cw_clip = cand[trav_pick(side > 0 ? P_CS_L : P_CS_R, nc)];
		}
		s.cw_flip = (bool)fig->clip_meta(s.cw_clip, "flip", false);
	}
	r_clip = s.cw_clip;
	const float gv = std::max(clip_f(fig, r_clip, "ground_v", 1.0f), 0.3f);
	r_cs = speed / gv;
	add(s.cw_flip ? PI_F : 0.0f);
}

Dictionary CityPlayer::get_trav() const {
	const TravState &s = trv;
	Dictionary d;
	d["lib"] = trav_lib(); d["mode"] = s.mode; d["clip"] = s.clip; d["t"] = s.t; d["move"] = s.last_move; d["obstacle"] = s.last_obstacle;
	d["jump"] = s.n_jump; d["run_jump"] = s.n_rjump; d["drop"] = s.n_drop; d["run_over"] = s.n_run_over; d["run_onto"] = s.n_run_onto;
	d["vault"] = s.n_vault; d["climb"] = s.n_climb; d["climb_high"] = s.n_climb_high;
	d["soft"] = s.n_soft; d["hard"] = s.n_hard; d["messed"] = s.n_mess; d["fall_landing"] = s.n_big; d["balance"] = s.n_balance;
	d["last_land"] = s.last_land; d["last_drop"] = s.last_drop;
	d["crouches"] = s.n_crouch; d["sprint_out"] = s.n_sprint_out; d["strafe"] = s.strafe;
	d["cover"] = s.n_cover; d["cover_switch"] = s.n_cover_switch; d["cover_turn"] = s.n_cover_turn; d["peek"] = s.n_peek; d["cover_vault"] = s.n_cover_vault; d["cover_exit"] = s.n_cover_exit;
	d["in_cover"] = s.mode == TravState::COVER; d["cover_high"] = s.high; d["wall_n"] = s.wall_n; d["edge_t"] = s.edge_t; d["fo"] = s.fo; d["fo_t"] = s.fo_t; d["fo_track"] = s.fo_track; d["fo_off"] = s.fo_off_dbg;
	return d;
}

void CityPlayer::set_trav_mess(double p_chance) { trv.mess_chance = (float)p_chance; }

void CityPlayer::set_facing(double p_yaw) {
	yaw = (float)p_yaw; cam_yaw = (float)p_yaw + PI_F; yaw_r = 0.0f; move_speed = 0.0f; step_mode = 0;
	trv.mode = TravState::NONE; trv.edge_t = 0.0f; trv.fo_t = 0.0f; set_velocity(Vector3());
}

// the hips of the pose the figure shows now, in its own frame
Vector3 CityPlayer::trav_hips_now() const {
	if (!fig) return Vector3();
	const StringName cur = fig->current_clip();
	const double pos = cur == trv.clip ? std::min(trv.t, trv.t_end) : fig->clip_pos();
	return fig->clip_hips_at(cur, pos);
}

// A hand-over to a figure placed at p_fig turned p_yaw: while the old pose fades out (p_blend s) the figure is offset so
// the hips stay where they were drawn (the new clip's hips may start a metre from its origin: root motion)
void CityPlayer::trav_hand(const Vector3 &p_hl, const Vector3 &p_fig, float p_yaw, double p_blend) {
	const Transform3D G = fig->get_global_transform();
	const Vector3 drawn = G.xform(p_hl);
	const Vector3 zc = G.basis.get_column(2);
	trv.yo = wrapf(std::atan2((float)zc.x, (float)zc.z) - p_yaw);
	if (std::fabs(trv.yo) < 0.02f) trv.yo = 0.0f;
	trv.fo = drawn - (p_fig + Basis(UP, p_yaw + trv.yo).xform(p_hl));
	trv.fo_len = (float)std::max(p_blend, 0.05); trv.fo_t = trv.fo_len;
	trv.yo_len = trv.fo_len; trv.yo_t = trv.yo != 0.0f ? trv.yo_len : 0.0f; trv.add_prev = 0.0f;
	if (trv.fo.length() > 4.0f) { trv.fo = Vector3(); trv.fo_t = 0.0f; trv.yo_t = 0.0f; }   // (a teleport, not a hand-over)
}

// (the yaw offset as it fades: called once a frame, before trav_fo)
static float trav_yo(TravState &s, float p_dt) {
	if (s.yo_t <= 0.0f) return 0.0f;
	s.yo_t = std::max(s.yo_t - p_dt, 0.0f);
	return s.yo * (s.yo_t / s.yo_len);
}

Vector3 CityPlayer::trav_fo(float p_dt) {
	if (trv.fo_t <= 0.0f) return Vector3();
	trv.fo_t = std::max(trv.fo_t - p_dt, 0.0f);
	return trv.fo * (trv.fo_t / trv.fo_len);
}
