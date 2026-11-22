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
float sstep(float a, float b, float x) { if (b <= a) return x >= b ? 1.0f : 0.0f; const float u = std::min(std::max((x - a) / (b - a), 0.0f), 1.0f); return u * u * (3.0f - 2.0f * u); }
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
float Motor::hips_drop() const { return limbs ? limbs->drop : 0.0f; }
int Motor::foot_steps() const { return limbs ? limbs->steps : 0; }
bool Motor::foot_stepping(int s) const { return limbs && limbs->stepping(s); }
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
	// (cubic between the 30 Hz keys: played in straight lines, a fast turn kinked at every key - the run pivot's hips
	// changed speed 1.3 m/s in a frame between them)
	for (int i = 0; i < c.a->get_track_count(); i++) {
		const Animation::TrackType ty = c.a->track_get_type(i);
		if ((ty == Animation::TYPE_POSITION_3D || ty == Animation::TYPE_ROTATION_3D) && c.a->track_get_interpolation_type(i) != Animation::INTERPOLATION_CUBIC)
			c.a->track_set_interpolation_type(i, Animation::INTERPOLATION_CUBIC);
	}
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
	if (n_idles > 0 && idles[0].d->ground_y > 0.03f && idles[0].d->ground_y < 0.2f) ankle_rest = idles[0].d->ground_y;   // (the standing ankle over the floor)
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

bool Motor::align_contacts(const Clip &p_c, double p_t0) {
	if (!host || !limbs || !limbs->lock_on) return false;
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
	if (!m) return false;
	const Vector3 by = sum / (float)m;
	last_align = (float)by.length();
	if (last_align < 0.005f || last_align > 0.45f) return true;   // (nothing to do / too far: a different stance, not a slide)
	if (host->shift(by)) n_aligned++;
	return true;
}

// FACING ALIGNMENT: the new clip turned so its hips face the way the drawn hips face. Left to the hand-over, the hips'
// turn offset decays over its time and swings the whole figure about the hips (a foot a metre under them, pinned
// meanwhile, was pulled 10 cm in the run pivot)
void Motor::align_facing(const Clip &p_c, double p_t0) {
	if (!host || st == TRAV) return;
	const Vector3 th = fig->bone_world("Bip01_L_Thigh") - fig->bone_world("Bip01_R_Thigh");
	const Vector3 fw = -UP.cross(th);
	if (Vector2(fw.x, fw.z).length() < 1e-3) return;
	const float drawn = std::atan2((float)fw.x, (float)fw.z);
	const float dy = wrapf(drawn - (yaw + (float)p_c.d->lerp(p_t0).face));
	last_align_yaw = dy;
	if (std::fabs(dy) < 0.005f || std::fabs(dy) > 0.5f) return;
	yaw += dy; yaw0 += dy;
}

// ROOT ALIGNMENT: no foot to put on its pin: the new clip is placed so its hips start (level) where the hips are drawn.
// Left to the hand-over, their offset decays over its time and carries the whole figure with it, a foot pinned
// meanwhile too (the run pivot: the left foot planted 0.1 s into the hand-over was pulled 25 cm)
void Motor::align_hips(const Clip &p_c, double p_t0) {
	if (!host || st == TRAV) return;
	const Frame f = p_c.d->lerp(p_t0);
	const Vector3 drawn = fig->bone_world("Bip01_Pelvis");
	const Vector3 p_new = host->position() + Basis(UP, yaw).xform(f.hips);
	Vector3 by = drawn - p_new; by.y = 0.0f;
	last_align = (float)by.length();
	if (last_align < 0.005f || last_align > 0.4f) return;
	if (host->shift(by)) n_hips_aligned++;
}

void Motor::play(const Clip &p_c, double p_t0, float p_blend) {
	if (!into_loop) align_facing(p_c, p_t0);   // (into a loop the facing is the way he travels: turned to the hips mid-turn at a pivot's end, the run's travel swung 1.5 m/s sideways)
	into_loop = false;
	if (!align_contacts(p_c, p_t0)) align_hips(p_c, p_t0);
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
	double e = 0.0;
	if (cur && st != IDLE) {
		// coming to a stand (a stop, a turn, a landing): the idle and the moment of it whose stance is most like the feet
		// now (a random one stood 28 cm off: the feet re-planted with a big shuffle)
		float best = 1e30f;
		for (int i = 0; i < n_idles; i++) {
			float c = 0.0f;
			const double ei = best_entry(*cur->d, t, *idles[i].d, 0.0, std::min(idles[i].d->len, 3.0), &c);
			if (i == last_idle) c += 0.01f;   // (a little against the same one twice)
			if (c < best) { best = c; k = i; e = ei; }
		}
		last_entry_cost = best;
	} else if (cur) e = best_entry(*cur->d, t, *idles[k].d, 0.0, std::min(idles[k].d->len, 3.0), &last_entry_cost);
	last_idle = k;
	const Clip &c = idles[k];
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
	into_loop = true;
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

void Motor::to_pivot(const Clip &c, double best_t, float p_angle, float p_cost) {
	last_entry_cost = p_cost;
	turn_k = std::fabs(c.yaw_end) > 0.1f ? clampf(p_angle / c.yaw_end, 0.75f, 1.1f) : 1.0f;
	rate = 1.0f;
	yaw0 = yaw - turn_k * c.d->yaw(best_t);
	const String key = String("out_at_") + loop_key(loops[loop_i >= 0 ? loop_i : 0].name);
	hand_at = c.a->has_meta(key) ? (double)c.a->get_meta(key) : c.meta("done_at", (float)c.d->len);
	play(c, best_t, blend_step);
	st = PIVOT; n_pivots++;
}

// TURNING BACK while moving: the pivot (left or right; for a full reversal either, whichever fits the feet) and the
// moment of it most like the stride ahead, at most a step ahead (cut in on whatever foot was down, the hand-over bent
// the planted leg 29 cm off the clip's). Returns false while the loop should run on to that stride.
bool Motor::pivot_when(float p_d) {
	const Clip *set = speed > 2.0f ? r_pivot : w_pivot;
	const Clip &L = loops[loop_i];
	const double ahead = std::min(L.d->len, 0.35);
	double best_w = 0.0, best_t = 0.0; int best_k = -1; float best_c = 1e30f, best_a = p_d;
	for (int k = 0; k < 2; k++) {
		const Clip &c = set[k];
		if (!c.ok()) continue;
		// (k 0 turns left, positive; the other way round is the angle less a full turn)
		const bool same = (k == 0) == (p_d > 0.0f);
		if (!same && std::fabs(p_d) < 2.8f) continue;
		const float ang = same ? p_d : p_d - std::copysign(TAU_F, p_d);
		for (double w = 0.0; w <= ahead + 1e-6; w += 1.0 / FPS) {
			const Frame lf = L.d->lerp(t + w * rate);
			for (double tt = 0.0; tt <= std::min(0.35, c.d->len * 0.4); tt += 1.0 / FPS) {
				const float dv = c.curve("vz", tt, 0.0f) - speed;
				const float cost = pose_cost(lf, c.d->at(tt)) + 0.3f * dv * dv + 0.1f * (float)w + (same ? 0.0f : 0.02f);
				if (cost < best_c) { best_c = cost; best_w = w; best_k = k; best_t = tt; best_a = ang; }
			}
		}
	}
	if (best_k < 0) return false;
	if (best_w < 0.5 / FPS) { to_pivot(set[best_k], best_t, best_a, best_c); return true; }
	return false;
}

// (the capsule's height is not the ground's: on the floor it bobs 4 mm every other frame, and after a vault's snap it
// sank 3 cm for a frame: the drawn hips dipped with it)
float Motor::ground_at(Host &p_host, const Vector3 &p_at) const {
	Vector3 g, gn;
	if (p_host.ray(p_at + Vector3(0, 0.4f, 0), p_at - Vector3(0, 0.4f, 0), g, gn) && gn.y > 0.5f) return (float)g.y;
	return (float)p_at.y;
}

void Motor::place(Host &p_host, float p_dt) {
	Vector3 at = p_host.position();
	if (st == TRAV) { draw_ok = false; fig->set_global_transform(Transform3D(Basis(UP, yaw), at)); return; }
	// the figure's floor: the ground under the body, followed on a stiff spring (a kerb or a stair lifts the body at once;
	// drawn so, the hips popped the step's height in a frame). Flat ground: exactly the ground
	const float g = ground_at(p_host, at);
	if (p_dt <= 0.0f || !draw_ok || std::fabs(g - draw_y) > 0.45f) {   // (more than a kerb or a stair: a teleport, a drop)
		draw_y = g; draw_v = 0.0f; draw_ok = true; }
	else {
		const float w = draw_omega;
		draw_v += (w * w * (g - draw_y) - 2.0f * w * draw_v) * p_dt;
		draw_y += draw_v * p_dt;
	}
	at.y = draw_y;
	fig->set_global_transform(Transform3D(Basis(UP, yaw), at));
}

void Motor::replace(Host &p_host) {
	if (!fig || st == TRAV || !draw_ok) return;
	Vector3 at = p_host.position(); at.y = draw_y;
	fig->set_global_transform(Transform3D(Basis(UP, yaw), at));
}

// THE GROUND UNDER EACH FOOT (for MoLimbs): where the clip puts the foot this frame, a ray down there; the foot moved by
// the ground's height there against the figure's floor - fully while the clip has it on its floor, and, in the swing,
// only up (over a stair's edge; down, it stays where the clip swings it)
void Motor::ground_feet(Host &p_host) {
	if (!limbs || !cur) return;
	limbs->ground_y = draw_y;
	limbs->fit_on = st != TRAV && st != OFF;
	if (!limbs->fit_on) return;
	const Frame fr = cur->d->lerp(t);
	const Transform3D X = fig->get_global_transform();
	for (int s = 0; s < 2; s++) {
		Vector3 fw = X.xform(Vector3(fr.foot[s].x, 0.0f, fr.foot[s].z)); fw.y = draw_y;
		Vector3 g, gn;
		if (!p_host.ray(fw + Vector3(0, 0.6f, 0), fw - Vector3(0, 0.6f, 0), g, gn) || gn.y < 0.5f) { g = fw; gn = UP; }
		const float h = (float)fr.foot[s].y - cur->d->ground_y;
		const float w = 1.0f - sstep(0.04f, 0.25f, h);
		const float off = (float)g.y - draw_y;
		limbs->fit_off[s] = off > 0.0f ? off : off * w;
		// a pin's height: the ground at the PIN (on stairs the clip's foot and the pin can be on different steps) plus
		// the clip's foot over its own floor plus the ankle's height standing (a raw Mixamo take's floor is not festive's)
		Vector3 gp = g;
		if (limbs->locked[s]) {
			Vector3 lp = limbs->lock_w[s]; lp.y = draw_y;
			Vector3 gn2;
			if (!p_host.ray(lp + Vector3(0, 0.6f, 0), lp - Vector3(0, 0.6f, 0), gp, gn2) || gn2.y < 0.5f) gp = lp;
		}
		limbs->fit_y[s] = (float)gp.y + std::max((float)fr.foot[s].y - cur->d->ground_y, 0.0f) + ankle_rest;
		limbs->fit_w[s] = w; limbs->ground_n[s] = gn;
	}
}

void Motor::step(float p_dt, const Intent &p_in, Host &p_host) {
	if (st == OFF || !cur) return;
	host = &p_host;
	// (the feet's pull as DRAWN last frame, read before this step seeks the clip: a pass made mid-step, with the clip
	// moved on and the figure not yet placed, gave a pull that alternated frame to frame - the body followed it, the
	// hips' speed jumped 1.4 m/s)
	if (limbs) for (int s = 0; s < 2; s++) { drawn_pull[s] = limbs->pull_v[s]; drawn_locked[s] = limbs->locked[s] && !limbs->stepping(s); }
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
			if (std::fabs(d) > 2.4f && speed > 0.8f && (speed > 2.0f ? r_pivot[0].ok() : w_pivot[0].ok())) {
				if (pivot_when(d)) break;
				// (on to the stride that fits: straight on at the pace held, at most a step)
				advance(p_dt);
				const Clip &L = loops[loop_i];
				vel = Basis(UP, yaw).xform(L.d->root_v.empty() ? Vector3(0, 0, L.ground_v) : L.d->root_vel(t)) * rate;
				break;
			}
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
		limbs->may_step = st == IDLE || st == STOP;   // (standing: a foot held off the clip's stance re-plants)
		limbs->down[0] = fr.down[0]; limbs->down[1] = fr.down[1];
	}
	// THE BODY FOLLOWS ITS PLANTED FEET: a foot pinned where the clip no longer has it (pinned during a hand-over, the
	// leg's offset then decayed away from it; or the clip's stance and its travel disagree) draws the body toward it,
	// 3 per second, at most 0.5 m/s, rather than bend the leg off the clip's pose (a walk stop held a leg 25 cm off for 0.6 s)
	if (limbs) {
		Vector3 sum; int m = 0;
		for (int s = 0; s < 2; s++) if (drawn_locked[s]) { sum += Vector3(drawn_pull[s].x, 0.0f, drawn_pull[s].z); m++; }
		Vector3 want_v = m ? sum / (float)m * follow_rate : Vector3();
		if (want_v.length() > follow_max) want_v = want_v.normalized() * follow_max;   // (at most this fast)
		// (its speed changes at most follow_acc: stepped in at once, its 0.5 m/s jumped the hips' speed 1.4 m/s in a stop)
		Vector3 dv = want_v - follow_v;
		if (dv.length() > follow_acc * p_dt) dv = dv.normalized() * follow_acc * p_dt;
		follow_v += dv;
		const Vector3 by = follow_v * p_dt;
		last_follow = by;
		if (by.length() > 1e-5f && p_host.shift(by)) follow_sum += (float)by.length();
	}
	// the body: level motion as above, and down onto the ground
	Vector3 v = vel;
	v.y = p_host.on_floor() ? -0.5f : -4.0f;
	const Vector3 got = p_host.slide(v, p_dt);
	const float got_s = (float)Vector3(got.x, 0, got.z).length();
	if (st == MOVE) speed = std::min(speed, got_s + 0.6f);   // (into a wall he does not keep a pace he cannot walk)
	place(p_host, p_dt);
	ground_feet(p_host);
	host = nullptr;
}
