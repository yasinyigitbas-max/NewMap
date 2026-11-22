// mo::Motor: see mo_motor.h.
#include "mo_motor.h"

#include "city_ped.h"
#include "mo_inertial.h"
#include "mo_limbs.h"

#include <godot_cpp/classes/animation_mixer.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;
using namespace godot::mo;

namespace {
const float PI_F = 3.14159265f, TAU_F = 6.2831853f;
const Vector3 UP(0, 1, 0);
float wrapf(float a) { a = std::fmod(a + PI_F, TAU_F); if (a < 0.0f) a += TAU_F; return a - PI_F; }
float clampf(float x, float a, float b) { return std::min(std::max(x, a), b); }
Vector3 fwd_of(float y) { return Vector3(std::sin(y), 0.0f, std::cos(y)); }
Vector3 left_of(float y) { return Vector3(std::cos(y), 0.0f, -std::sin(y)); }
// "pwalk/walk_mx2" -> "mx2", "prun/jog_a" -> "jog_a": the suffix of the hand-over meta a start or turn holds per loop
String loop_key(const StringName &p_loop) {
	String s = String(p_loop).get_slice("/", 1);
	return s.begins_with("walk_") ? s.substr(5) : s;
}
} // namespace

float Clip::curve(const char *p_key, double p_t, float p_def) const {
	if (a.is_null() || !a->has_meta(p_key)) return p_def;
	const PackedFloat32Array p = a->get_meta(p_key);
	if (p.size() == 0) return p_def;
	const double f = std::min(std::max(p_t * FPS, 0.0), (double)(p.size() - 1));
	const int i = (int)f, j = std::min(i + 1, (int)p.size() - 1);
	return p[i] + (p[j] - p[i]) * (float)(f - i);
}

float Clip::meta(const char *p_key, float p_def) const {
	return (a.is_valid() && a->has_meta(p_key)) ? (float)(double)a->get_meta(p_key) : p_def;
}

int Motor::inert_switches() const { return inert ? inert->switches : 0; }
float Motor::inert_jump() const { return inert ? inert->last_jump : 0.0f; }
bool Motor::inert_live() const { return inert && inert->is_blending(); }
float Motor::foot_pull(int p_side) const { return limbs ? limbs->pull[p_side & 1] : 0.0f; }
int Motor::foot_locks() const { return limbs ? limbs->locks : 0; }

Array Motor::dump(const String &p_clip) const {
	Array out;
	if (!anim || !anim->has_animation(p_clip)) return out;
	const Ref<Animation> a = anim->get_animation(p_clip);
	const ClipData *d = clip_data(a, fig->skeleton(), fig->skel_frame());
	Clip c; c.a = a; c.d = d;
	for (int k = 0; k < (int)d->f.size(); k++) {
		const Frame &F = d->f[k];
		Array r;
		r.push_back(k / FPS); r.push_back(F.foot[0]); r.push_back(F.foot[1]); r.push_back(F.down[0]); r.push_back(F.down[1]);
		r.push_back(F.hips); r.push_back(d->root_v.empty() ? Vector3() : d->root_v[k]); r.push_back(c.curve("yaw", k / FPS, 0.0f));
		r.push_back(Vector3(c.curve("vx", k / FPS, 0.0f), 0.0f, c.curve("vz", k / FPS, 0.0f))); r.push_back(F.face);
		r.push_back(F.hand[0]); r.push_back(F.hand[1]); r.push_back((float)F.hand_v[0].length()); r.push_back((float)F.hand_v[1].length());
		out.push_back(r);
	}
	return out;
}

float Motor::rnd() { rng ^= rng << 13; rng ^= rng >> 17; rng ^= rng << 5; return (rng & 0xffffff) / 16777216.0f; }

const char *Motor::state_name() const {
	static const char *N[] = { "off", "idle", "start", "move", "stop", "turn", "pivot", "trav" };
	return N[st];
}

Clip Motor::load(const char *p_name) {
	Clip c;
	if (!anim || !anim->has_animation(p_name)) return c;
	c.name = StringName(p_name);
	c.a = anim->get_animation(c.name);
	c.d = clip_data(c.a, fig->skeleton(), fig->skel_frame());
	c.ground_v = c.meta("ground_v", 0.0f);
	c.yaw_end = c.d->yaw(c.d->len);
	return c;
}

bool Motor::attach(CityPed *p_fig) {
	fig = p_fig;
	anim = fig ? fig->anim_player() : nullptr;
	Skeleton3D *sk = fig ? fig->skeleton() : nullptr;
	if (!anim || !sk) { fig = nullptr; return false; }
	// festive's clip libraries (Yasin, 22 Nov: "take only clips from festive work")
	fig->add_library("pwalk", "player_walk"); fig->add_library("prun", "player_run"); fig->add_library("pidle", "player_idle");
	fig->add_library("ptrav", "player_trav"); fig->add_library("pact", "player_act");
	n_idles = 0;   // (the idles that face ahead: the -38 degree ones would turn the body in place)
	for (const char *n : { "pidle/base_idle", "pidle/base_loco", "pidle/base_standing" }) { Clip c = load(n); if (c.ok()) idles[n_idles++] = c; }
	n_fidgets_c = 0;
	for (const char *n : { "pidle/Arm_Stretching", "pidle/Bored", "pidle/Looking", "pidle/Neck_Stretching", "pidle/Looking_Around_idle" }) { Clip c = load(n); if (c.ok() && n_fidgets_c < 6) fidgets[n_fidgets_c++] = c; }
	n_loops = 0;
	for (const char *n : { "pwalk/walk_mx3", "pwalk/walk_mx2", "prun/jog_a", "prun/jog_d", "prun/jog_c", "prun/fast_b", "prun/fast_c", "prun/fast_d" }) { Clip c = load(n); if (c.ok() && c.ground_v > 0.2f) loops[n_loops++] = c; }
	std::sort(loops, loops + n_loops, [](const Clip &a, const Clip &b) { return a.ground_v < b.ground_v; });
	w_start[0] = load("pwalk/start_a"); w_start[1] = load("pwalk/start_b");
	r_start[0] = load("prun/start_a"); r_start[1] = load("prun/start_b");
	r_tstart[0] = load("prun/tstart_l"); r_tstart[1] = load("prun/tstart_r");
	w_stop[0] = load("pwalk/stop_a"); w_stop[1] = load("pwalk/stop_b");
	// the run stops and the run pivot as Mixamo made them (the "mx" library: retargeted only). Festive's prun copies were
	// tuned ("stance_fit": the legs bent toward the idle's stance; the turns' pace smoothed) and the stop had a hitch at
	// 0.17 s (Yasin, 22 Nov: "take only clips from festive work, not the code or the animation tuning")
	r_stop[0] = load("mx/Run_To_Stop"); r_stop[1] = load("mx/Run_To_Stop_2");
	if (!r_stop[0].ok()) r_stop[0] = load("prun/stop_a");
	if (!r_stop[1].ok()) r_stop[1] = load("prun/stop_b");
	n_tl = n_tr = 0;
	for (const char *n : { "pwalk/sturn_l", "pwalk/sturn_l1", "pwalk/sturn_l2" }) { Clip c = load(n); if (c.ok()) s_turn_l[n_tl++] = c; }
	for (const char *n : { "pwalk/sturn_r", "pwalk/sturn_r1", "pwalk/sturn_r2" }) { Clip c = load(n); if (c.ok()) s_turn_r[n_tr++] = c; }
	w_pivot[0] = load("pwalk/turn180_l"); w_pivot[1] = load("pwalk/turn180_r");
	r_pivot[0] = load("prun/turn180_l"); r_pivot[1] = load("mx/Running_Turn_180");   // (left: festive's mirror of it; no raw take that way)
	if (!r_pivot[1].ok()) r_pivot[1] = load("prun/turn180_r");
	// traversal (festive's ptrav takes: their travel in the hips): vault walking / running, climb low (to 1.15 m),
	// climb to 2.05 m walking / running
	// (the running vault: Vault_Over_Box_To_Cover has no clean hand plant - its hands drift 25 cm "planted", 22 Nov -
	// so a run vaults with the walking take too, entered later in it, until a better take comes)
	v_walk = load("ptrav/Jumping_Over_Into_Combat"); v_run = v_walk;
	c_low = load("ptrav/Running_Jump_Climb"); c_mid = load("ptrav/Climbing_Double"); c_mid_run = load("ptrav/Sprint_To_Wall_Climb");
	if (n_loops == 0 || n_idles == 0) { fig = nullptr; return false; }
	if (!inert) {   // first on the skeleton: it sees the clip's own pose, the IK after it sees the handed-over one
		inert = memnew(MoInertial);
		sk->add_child(inert);
		sk->move_child(inert, 0);
		if (OS::get_singleton()->get_cmdline_user_args().has("--no-inertial")) inert->set_active(false);   // (tests: the hand-overs off)
	}
	if (!limbs) {   // right after the hand-over: the feet pinned on the pose that is drawn
		limbs = memnew(MoLimbs);
		sk->add_child(limbs);
		sk->move_child(limbs, 1);
		if (OS::get_singleton()->get_cmdline_user_args().has("--no-footlock")) limbs->set_active(false);   // (tests)
	}
	rng ^= (uint32_t)(uint64_t)fig->get_instance_id();
	return true;
}

void Motor::align_contacts(const Clip &p_c, double p_t0) {
	if (!host || !limbs || !limbs->lock_on) return;
	const Frame f = p_c.d->lerp(p_t0);
	// where the new clip puts each foot, placed as the figure will be (the body's place, this frame's facing)
	const Basis R(UP, yaw);
	const Vector3 at = host->position();
	Vector3 sum; int m = 0;
	for (int s = 0; s < 2; s++) {
		if (!f.down[s] || !limbs->locked[s]) continue;
		const Vector3 p_new = at + R.xform(f.foot[s]);
		const Vector3 d = limbs->lock_w[s] - p_new;
		sum += Vector3(d.x, 0.0f, d.z); m++;
	}
	if (!m) return;
	const Vector3 by = sum / (float)m;
	last_align = (float)by.length();
	if (last_align < 0.005f || last_align > 0.45f) return;   // (nothing to do / too far: a different stance, not a slide)
	if (host->shift(by)) n_aligned++;
}

void Motor::play(const Clip &p_c, double p_t0, float p_blend) {
	align_contacts(p_c, p_t0);
	anim->play(p_c.name, 0.0);
	t = std::min(std::max(p_t0, 0.0), p_c.d->len);
	anim->seek(t, true);
	if (inert) inert->inertialize(p_blend);
	cur = &p_c; n_switch++;
}

void Motor::advance(float p_dt) {
	if (!cur) return;
	t += p_dt * rate;
	if (cur->d->loop && cur->d->len > 0.0) { t = std::fmod(t, cur->d->len); if (t < 0.0) t += cur->d->len; }
	else t = std::min(t, cur->d->len);
	anim->seek(t, true);
}

Vector3 Motor::clip_vel(const Clip &p_c, double p_t) const {
	// the clip's own travel, read from its planted feet (mo_clip root_v), turned as the clip turns
	const float y = turn_k * p_c.d->yaw(p_t);
	const Vector3 v = p_c.d->root_v.empty() ? fwd_of(y) * p_c.curve("vz", p_t, 0.0f) + left_of(y) * p_c.curve("vx", p_t, 0.0f) : Basis(UP, y).xform(p_c.d->root_vel(p_t));
	return Basis(UP, yaw0).xform(v) * rate;
}

int Motor::pick_loop(float p_speed, int p_keep) const {
	const float sp = std::max(p_speed, 0.3f);
	int best = 0;
	for (int i = 1; i < n_loops; i++) if (std::fabs(std::log(sp / loops[i].ground_v)) < std::fabs(std::log(sp / loops[best].ground_v))) best = i;
	if (p_keep >= 0 && p_keep < n_loops && std::fabs(std::log(sp / loops[p_keep].ground_v)) < std::fabs(std::log(sp / loops[best].ground_v)) + 0.15f) best = p_keep;
	return best;
}

void Motor::begin(float p_yaw, float p_speed) {
	if (!ready()) return;
	yaw = p_yaw; speed = p_speed; turn_k = 1.0f; rate = 1.0f;
	anim->set_callback_mode_process(AnimationMixer::ANIMATION_CALLBACK_MODE_PROCESS_MANUAL);
	// from the pose the old player drew: its clip, if it is one the motor can read
	const StringName was = fig->playing();
	const double was_t = fig->clip_pos();
	const ClipData *A = (was != StringName() && anim->has_animation(was)) ? clip_data(anim->get_animation(was), fig->skeleton(), fig->skel_frame()) : nullptr;
	if (p_speed > 0.3f) {
		loop_i = pick_loop(p_speed, -1);
		const Clip &L = loops[loop_i];
		const double e = A ? best_entry(*A, was_t, *L.d, 0.0, L.d->len, &last_entry_cost) : 0.0;
		play(L, e, blend_loop); st = MOVE;
	} else {
		to_idle(blend_idle);
	}
}

void Motor::end() {
	if (st == OFF) return;
	st = OFF; cur = nullptr;
	anim->set_callback_mode_process(AnimationMixer::ANIMATION_CALLBACK_MODE_PROCESS_IDLE);
	fig->forget_clip();
	if (limbs) { limbs->lock_on = false; limbs->unlock_all(); }
	fig->set_next_blend(0.0);   // (the old code's next clip cuts in; the hand-over smooths it)
	if (inert) inert->inertialize(blend_loop);
}

void Motor::to_idle(float p_blend) {
	int k = n_idles > 1 ? (int)(rnd() * n_idles) % n_idles : 0;
	if (k == last_idle && n_idles > 1) k = (k + 1) % n_idles;
	last_idle = k;
	const Clip &c = idles[k];
	const double e = cur ? best_entry(*cur->d, t, *c.d, 0.0, std::min(c.d->len, 3.0), &last_entry_cost) : 0.0;
	rate = 1.0f; turn_k = 1.0f;
	play(c, e, p_blend);
	st = IDLE; idle_t = 0.0f; fidget_in = 8.0f + 10.0f * rnd();
}

void Motor::to_loop(int p_i, float p_blend) {
	const Clip &L = loops[p_i];
	const double e = cur ? best_entry(*cur->d, t, *L.d, 0.0, L.d->len, &last_entry_cost) : 0.0;
	if (st == MOVE && p_i != loop_i) n_gait++;
	loop_i = p_i; turn_k = 1.0f; loop_t = 0.0f;
	rate = clampf(std::max(speed, 0.3f) / L.ground_v, 0.55f, 1.5f);
	play(L, e, p_blend);
	st = MOVE;
}

// stopping: the stop (either foot, walk or run by the pace) and the moment of it most like the feet now, at about
// this pace
void Motor::to_stop() {
	const Clip *set = speed > 2.0f ? r_stop : w_stop;
	const Frame now = cur->d->lerp(t);
	const Clip *best = nullptr; double best_t = 0.0; float best_c = 1e30f;
	for (int k = 0; k < 2; k++) {
		const Clip &c = set[k];
		if (!c.ok()) continue;
		for (double tt = 0.0; tt <= std::min(0.9, c.d->len * 0.4); tt += 1.0 / FPS) {
			const float dv = c.curve("vz", tt, 0.0f) - speed;
			const float cost = pose_cost(now, c.d->at(tt)) + 0.3f * dv * dv;
			if (cost < best_c) { best_c = cost; best = &c; best_t = tt; }
		}
	}
	stop_with(best, best_t, best_c);
}

void Motor::stop_with(const Clip *p_c, double p_t0, float p_cost) {
	if (!p_c) { to_idle(blend_idle); return; }
	last_entry_cost = p_cost;
	turn_k = 1.0f; rate = 1.0f;
	yaw0 = yaw - p_c->d->yaw(p_t0);
	play(*p_c, p_t0, blend_step);
	st = STOP; n_stops++;
}

void Motor::to_start(float p_angle, float p_want) {
	const bool run = p_want > 2.0f;
	loop_i = pick_loop(p_want, -1);
	if (n_loops > 1 && loops[loop_i].ground_v < 2.0f) {   // (the walks: never the same take twice running)
		int other = -1;
		for (int i = 0; i < n_loops; i++) if (i != loop_i && loops[i].ground_v < 2.0f && std::fabs(std::log(loops[i].ground_v / loops[loop_i].ground_v)) < 0.15f) other = i;
		if (other >= 0 && loop_i == last_walk) loop_i = other;
		last_walk = loop_i;
	}
	const Clip *c = nullptr;
	turn_k = 1.0f; yaw0 = yaw; rate = 1.0f;
	if (run && std::fabs(p_angle) > 1.2f && r_tstart[p_angle > 0.0f ? 0 : 1].ok()) {   // a run off to the side: the turning start
		c = &r_tstart[p_angle > 0.0f ? 0 : 1];
		turn_k = clampf(p_angle / c->yaw_end, 0.6f, 1.4f);
	} else {
		last_start ^= 1;
		c = run ? &r_start[last_start] : &w_start[last_start];
		if (!c->ok()) c = run ? &r_start[last_start ^ 1] : &w_start[last_start ^ 1];
	}
	if (!c || !c->ok()) { to_loop(loop_i, blend_loop); return; }
	const String key = String("out_at_") + loop_key(loops[loop_i].name);
	hand_at = c->a->has_meta(key) ? (double)c->a->get_meta(key) : c->d->len * 0.75;
	play(*c, 0.0, blend_step);
	st = START; n_starts++;
}

void Motor::to_turn(float p_angle) {
	const Clip *set = p_angle > 0.0f ? s_turn_l : s_turn_r;
	const int n = p_angle > 0.0f ? n_tl : n_tr;
	if (n == 0) { to_start(p_angle, 1.0f); return; }
	// the take whose own turn is nearest the angle wanted (the next one when two are as near: variety)
	int best = 0;
	for (int k = 1; k < n; k++) if (std::fabs(std::fabs(set[k].yaw_end) - std::fabs(p_angle)) < std::fabs(std::fabs(set[best].yaw_end) - std::fabs(p_angle)) - 0.05f) best = k;
	const Clip &c = set[best];
	turn_k = std::fabs(c.yaw_end) > 0.1f ? clampf(p_angle / c.yaw_end, 0.6f, 1.6f) : 1.0f;
	yaw0 = yaw; rate = 1.0f;
	play(c, 0.0, blend_step);
	st = TURN; n_turns++;
}

void Motor::to_pivot(float p_angle) {
	const Clip &c = (speed > 2.0f ? r_pivot : w_pivot)[p_angle > 0.0f ? 0 : 1];
	if (!c.ok()) return;
	const Frame now = cur->d->lerp(t);
	double best_t = 0.0; float best_c = 1e30f;
	for (double tt = 0.0; tt <= std::min(0.35, c.d->len * 0.4); tt += 1.0 / FPS) {
		const float dv = c.curve("vz", tt, 0.0f) - speed;
		const float cost = pose_cost(now, c.d->at(tt)) + 0.3f * dv * dv;
		if (cost < best_c) { best_c = cost; best_t = tt; }
	}
	last_entry_cost = best_c;
	turn_k = std::fabs(c.yaw_end) > 0.1f ? clampf(p_angle / c.yaw_end, 0.75f, 1.1f) : 1.0f;
	rate = 1.0f;
	yaw0 = yaw - turn_k * c.d->yaw(best_t);
	const String key = String("out_at_") + loop_key(loops[loop_i >= 0 ? loop_i : 0].name);
	hand_at = c.a->has_meta(key) ? (double)c.a->get_meta(key) : c.meta("done_at", (float)c.d->len);
	play(c, best_t, blend_step);
	st = PIVOT; n_pivots++;
}

void Motor::place(Host &p_host) {
	fig->set_global_transform(Transform3D(Basis(UP, yaw), p_host.position()));
}

void Motor::step(float p_dt, const Intent &p_in, Host &p_host) {
	if (st == OFF || !cur) return;
	host = &p_host;
	const Vector3 dir(p_in.dir.x, 0.0f, p_in.dir.z);
	const float wl = std::min((float)dir.length(), 1.0f);
	const bool want = wl > 0.1f;
	const float want_speed = p_in.speed * wl;
	const float d = want ? wrapf(std::atan2((float)dir.x, (float)dir.z) - yaw) : 0.0f;
	Vector3 vel;   // level velocity this frame (world)
	if (st == TRAV) {   // a vault or a climb: the clip has the body (mo_motor_trav.cpp)
		trav_step(p_dt);
		host = nullptr;
		return;
	}
	// a vault or a climb ahead, going the way he faces
	if (want && std::fabs(d) < 0.5f && (st == IDLE || st == START || st == MOVE) && trav_probe(fwd_of(yaw), std::max(speed, want_speed > 2.0f ? speed : 0.0f))) { host = nullptr; return; }
	switch (st) {
		case IDLE: {
			advance(p_dt); idle_t += p_dt;
			if (want) {
				if (std::fabs(d) > 0.9f && !(want_speed > 2.0f && std::fabs(d) < 2.2f)) to_turn(d);
				else to_start(d, want_speed);
				break;
			}
			// standing: now and then a fidget (stretch, look round), then the idle again
			bool fid = false;
			for (int k = 0; k < n_fidgets_c; k++) if (cur == &fidgets[k]) fid = true;
			if (fid && t >= cur->d->len - 0.02) { to_idle(0.45f); }
			else if (!fid && idle_t > fidget_in && n_fidgets_c > 0) {
				int k = (int)(rnd() * n_fidgets_c) % n_fidgets_c; if (k == last_fidget) k = (k + 1) % n_fidgets_c;
				last_fidget = k; rate = 1.0f;
				const double e = best_entry(*cur->d, t, *fidgets[k].d, 0.0, std::min(1.0, fidgets[k].d->len), &last_entry_cost);
				play(fidgets[k], e, 0.45f); n_fidgets++; idle_t = 0.0f; fidget_in = 9.0f + 12.0f * rnd();
			}
			break;
		}
		case TURN: {
			advance(p_dt);
			yaw = yaw0 + turn_k * cur->d->yaw(t);
			vel = clip_vel(*cur, t);
			if (t >= cur->d->len - 0.02) {
				if (want) {
					const float d2 = wrapf(std::atan2((float)dir.x, (float)dir.z) - yaw);
					to_start(d2, want_speed);
				} else to_idle(blend_step);
			}
			break;
		}
		case START: {
			advance(p_dt);
			if (!want) { if (t < 0.4) to_idle(blend_step); else to_stop(); break; }
			// steering on the way: the start's facing eased toward the way wanted
			const float y_now = yaw0 + turn_k * cur->d->yaw(t);
			const float d2 = wrapf(std::atan2((float)dir.x, (float)dir.z) - y_now);
			if (cur != &r_tstart[0] && cur != &r_tstart[1]) yaw0 += clampf(d2, -2.5f * p_dt, 2.5f * p_dt);
			yaw = yaw0 + turn_k * cur->d->yaw(t);
			vel = clip_vel(*cur, t);
			speed = (float)vel.length();
			if (t >= hand_at) to_loop(pick_loop(std::max(speed, want_speed), loop_i), blend_loop);
			break;
		}
		case MOVE: {
			if (!want) {
				// LET GO: a stop on the foot that fits. The loop runs on (at most a stride, its pace held) until its
				// stride is where a stop's opening pose is; then the stop from that moment of it (cut in anywhere, the
				// hand-over swept a planted foot 66 cm over the ground)
				if (speed <= 0.6f) { to_idle(blend_idle); break; }
				const Clip *set = speed > 2.0f ? r_stop : w_stop;
				const Clip &L = loops[loop_i];
				const double ahead = std::min(L.d->len, 0.7);
				double best_w = 0.0, best_t = 0.0; int best_k = -1; float best_c = 1e30f;
				for (double w = 0.0; w <= ahead + 1e-6; w += 1.0 / FPS) {
					const Frame lf = L.d->lerp(t + w * rate);
					for (int k = 0; k < 2; k++) {
						if (!set[k].ok()) continue;
						for (double tt = 0.0; tt <= std::min(0.25, set[k].d->len * 0.3); tt += 1.0 / FPS) {
							const float dv = set[k].curve("vz", tt, 0.0f) - speed;
							const float c = pose_cost(lf, set[k].d->at(tt)) + 0.3f * dv * dv + 0.05f * (float)w;   // (sooner is better)
							if (c < best_c) { best_c = c; best_w = w; best_k = k; best_t = tt; }
						}
					}
				}
				if (best_k < 0 || best_w < 0.5 / FPS) { stop_with(best_k >= 0 ? &set[best_k] : nullptr, best_t, best_c); break; }
				rate = clampf(std::max(speed, 0.3f) / L.ground_v, 0.55f, 1.5f);
				advance(p_dt);
				vel = Basis(UP, yaw).xform(L.d->root_v.empty() ? Vector3(0, 0, L.ground_v) : L.d->root_vel(t)) * rate;
				break;
			}
			if (std::fabs(d) > 2.4f && speed > 0.8f && (speed > 2.0f ? r_pivot[0].ok() : w_pivot[0].ok())) { to_pivot(d); break; }
			// the heavy body: it turns at a limited rate and slows into a sharp turn
			const float tr = speed > 2.0f ? run_turn_rate : walk_turn_rate;
			yaw += clampf(d, -tr * p_dt, tr * p_dt);
			const float target = want_speed * std::max(0.25f, std::cos(std::min(std::fabs(d), 1.5f)));
			const float acc = target > speed ? accel_up : accel_down;
			speed += clampf(target - speed, -acc * p_dt, acc * p_dt);
			// the gait by where the pace is going (speeding up into a run: the run, slow at first), held a while
			loop_t += p_dt;
			const int g = pick_loop(target > speed ? target : speed, loop_i);
			if (g != loop_i && loop_t >= gait_hold) { to_loop(g, blend_loop); }
			rate = clampf(std::max(speed, 0.3f) / loops[loop_i].ground_v, 0.55f, 1.5f);
			advance(p_dt);
			// the loop's own travel at the rate it plays (its pace through the stride, from its planted feet: the
			// foot stays where it is put); on average the pace wanted
			{
				const Clip &L = loops[loop_i];
				const Vector3 rv = L.d->root_v.empty() ? Vector3(0, 0, L.ground_v) : L.d->root_vel(t);
				vel = Basis(UP, yaw).xform(rv) * rate;
			}
			break;
		}
		case STOP: {
			advance(p_dt);
			yaw = yaw0 + cur->d->yaw(t);
			vel = clip_vel(*cur, t);
			speed = (float)vel.length();
			if (want && std::fabs(d) < 1.2f) { to_loop(pick_loop(std::max(speed, 0.8f), loop_i), blend_loop); break; }
			if (t >= cur->meta("still_at", (float)cur->d->len) || t >= cur->d->len - 0.02) to_idle(blend_idle);
			break;
		}
		case PIVOT: {
			advance(p_dt);
			yaw = yaw0 + turn_k * cur->d->yaw(t);
			vel = clip_vel(*cur, t);
			speed = (float)vel.length();
			if (t >= hand_at || t >= cur->d->len - 0.02) {
				if (want) { speed = std::max(speed, 0.8f); to_loop(pick_loop(std::max(speed, want_speed), loop_i), blend_loop); }   // (on at the pace wanted: a run's pivot runs on)
				else if (speed > 0.6f) to_stop(); else to_idle(blend_idle);
			}
			break;
		}
		default: break;
	}
	// the feet the clip has down are pinned where they landed (MoLimbs)
	if (limbs && cur) {
		const Frame fr = cur->d->lerp(t);
		limbs->lock_on = st != OFF;
		limbs->down[0] = fr.down[0]; limbs->down[1] = fr.down[1];
		limbs->ground_y = (float)p_host.position().y;
	}
	// the body: level motion as above, and down onto the ground
	Vector3 v = vel;
	v.y = p_host.on_floor() ? -0.5f : -4.0f;
	const Vector3 got = p_host.slide(v, p_dt);
	const float got_s = (float)Vector3(got.x, 0, got.z).length();
	if (st == MOVE) speed = std::min(speed, got_s + 0.6f);   // (into a wall he does not keep a pace he cannot walk)
	place(p_host);
	host = nullptr;
}
