// mo::Motor: see mo_motor.h.
#include "mo_motor.h"

#include "city_ped.h"
#include "mo_inertial.h"
#include "mo_layer.h"
#include "mo_limbs.h"

#include <godot_cpp/classes/animation_mixer.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <godot_cpp/variant/utility_functions.hpp>

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

void Motor::keep_loops(const PackedStringArray &p_names) {
	if (p_names.is_empty()) return;
	// (load any named that is not in the set yet, then keep only the named, by pace)
	Clip keep[12]; int n = 0;
	for (int i = 0; i < p_names.size() && n < 12; i++) {
		const String nm = p_names[i];
		int found = -1;
		for (int k = 0; k < n_loops; k++) if (String(loops[k].name) == nm) found = k;
		Clip c = found >= 0 ? loops[found] : load(nm.utf8().get_data());
		if (c.ok() && c.ground_v <= 0.2f && !c.d->root_v.empty()) { Vector3 sv; for (const Vector3 &v : c.d->root_v) sv += v; c.ground_v = (float)sv.length() / c.d->root_v.size(); }
		if (c.ok()) keep[n++] = c;
	}
	if (!n) return;
	std::sort(keep, keep + n, [](const Clip &a, const Clip &b) { return a.ground_v < b.ground_v; });
	for (int k = 0; k < n; k++) loops[k] = keep[k];
	n_loops = n; loop_i = std::min(loop_i, n_loops - 1);
}

float Motor::rnd() { rng ^= rng << 13; rng ^= rng >> 17; rng ^= rng << 5; return (rng & 0xffffff) / 16777216.0f; }

const char *Motor::state_name() const {
	static const char *N[] = { "off", "idle", "start", "move", "stop", "turn", "pivot", "trav", "crouch", "stance", "cover_in", "cover", "cover_out", "carry", "jump", "air", "land", "runjump", "descend", "sit_in", "sit", "sit_out" };
	return N[st];
}

Clip Motor::load(const char *p_name) {
	Clip c;
	if (!anim) return c;
	const char *alt = style_clip(style, p_name);
	if (alt && anim->has_animation(alt)) p_name = alt;
	if (!anim->has_animation(p_name)) return c;
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

// THE MOVEMENT SETS (Yasin, 24 Nov: "we need at least 2 more combination sets like this, with different animations that
// go well together"): every clip the motor plays is asked for by its set-1 name; mo_sets.cpp gives the set's own clip
// for it, or none (then set 1's). A set is changed only standing (applied in the idle), all clips loaded again.
void Motor::load_clips() {
	n_idles = 0;   // (the idles that face ahead: the -38 degree ones would turn the body in place)
	for (const char *n : { "pidle/base_idle" }) { Clip c = load(n); if (c.ok()) idles[n_idles++] = c; }   // (Yasin, 24 Nov: "idle 1 is standard" - the main idle; base_loco is the same take, base_standing went with the others)
	n_tired = 0;
	for (const char *n : { "ms/S2_Idle_Unarmed", "ms/S2_Idle_Unarmed_b", "ms/S2_Idle_Loop" }) { Clip c = load(n); if (c.ok()) tired_idles[n_tired++] = c; }
	if (n_idles > 0 && idles[0].d->ground_y > 0.03f && idles[0].d->ground_y < 0.2f) ankle_rest = idles[0].d->ground_y;   // (the standing ankle over the floor)
	n_fidgets_c = 0;
	// (Yasin, 24 Nov: "add all of the clips from festives idle gestures in between, main idle should have 2 loops before a
	// gesture ... gestures should be random too")
	for (const char *n : { "pidle/Arm_Stretching", "pidle/Bored", "pidle/Looking", "pidle/Neck_Stretching", "pidle/Looking_Around_idle", "pidle/Idle_Transition" }) { Clip c = load(n); if (c.ok() && n_fidgets_c < 6) fidgets[n_fidgets_c++] = c; }
	n_loops = 0;
	// (Yasin, 24 Nov: "set 1, 3 walk rotate randomly, set 1, 3 run rotate randomly" - set 3's walks and runs with set 1's;
	// pick_loop takes one at random among those near the pace wanted. Out (Yasin: "remove the parts that break the
	// quality chain"): set 3's walks and its happy run - on stairs and kerbs their planted feet floated 8-17 cm)
	for (const char *n : { "pwalk/walk_mx3", "pwalk/walk_mx2", "prun/jog_a", "prun/jog_d", "prun/jog_c", "prun/fast_b", "prun/fast_c", "prun/fast_d",
			"ms/S3_Run_Quick_b", "ms/S3_Run_Medium", "ms/S3_Run_Intention", "ms/S3_Sprint_Two_Cycle" }) {
		Clip c = load(n); if (c.ok() && c.ground_v > 0.2f && n_loops < 16) loops[n_loops++] = c;
	}
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
	c_low = load("ptrav/Running_Jump_Climb"); c_mid = load("ptrav/Climbing_Single");   // (Yasin, 23 Nov: "remove all the double climbs")
	c_hang = load("ptrav/Stand_To_Freehang"); c_braced = load("ptrav/Braced_Hang_To_Crouch"); c_mid_run = load("ptrav/Sprint_To_Wall_Climb");
	load_cover();
	load_carry();
	load_air();
	load_sit();
	load_phone();
}

void Motor::set_style(int p_style) {
	style_want = std::max(0, std::min(p_style, style_count() - 1));
	if (fig && (st == OFF || st == IDLE) && style_want != style) { style = style_want; load_clips(); to_idle(0.3f); }
}

bool Motor::attach(CityPed *p_fig) {
	fig = p_fig;
	anim = fig ? fig->anim_player() : nullptr;
	Skeleton3D *sk = fig ? fig->skeleton() : nullptr;
	if (!anim || !sk) { fig = nullptr; return false; }
	// festive's clip libraries (Yasin, 22 Nov: "take only clips from festive work")
	fig->add_library("pwalk", "player_walk"); fig->add_library("prun", "player_run"); fig->add_library("pidle", "player_idle");
	fig->add_library("ptrav", "player_trav"); fig->add_library("pact", "player_act");
	load_clips();
	if (n_loops == 0 || n_idles == 0) { fig = nullptr; return false; }
	if (!inert) {   // first on the skeleton: it sees the clip's own pose, the IK after it sees the handed-over one
		inert = memnew(MoInertial);
		sk->add_child(inert);
		sk->move_child(inert, 0);
		if (OS::get_singleton()->get_cmdline_user_args().has("--no-inertial")) inert->set_active(false);   // (tests: the hand-overs off)
	}
	if (!layer && !OS::get_singleton()->get_cmdline_user_args().has("--no-layer")) {   // the upper-body layer (the phone): before the hand-overs, so they smooth its changes too
		layer = memnew(MoLayer);
		sk->add_child(layer);
		sk->move_child(layer, 0);
	}
	if (!limbs) {   // right after the hand-over: the feet pinned on the pose that is drawn
		limbs = memnew(MoLimbs);
		sk->add_child(limbs);
		sk->move_child(limbs, inert ? inert->get_index() + 1 : 1);   // (right after the hand-overs - at a fixed index it fell behind the figure's own modifiers)
		if (OS::get_singleton()->get_cmdline_user_args().has("--no-footlock")) limbs->set_active(false);   // (tests)
	}
	rng ^= (uint32_t)(uint64_t)fig->get_instance_id();
	for (const String &a : OS::get_singleton()->get_cmdline_user_args()) if (a.begins_with("--mo-style=")) set_style(a.get_slice("=", 1).to_int());   // (tests, films: a movement set)
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
		const Vector3 p_new = at + R.xform(f.foot[s] - p_c.off);
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
	if (std::fabs(dy) < 0.005f || (std::fabs(dy) > 0.5f && !align_full)) return;
	yaw += dy; yaw0 += dy;
}

// ROOT ALIGNMENT: no foot to put on its pin: the new clip is placed so its hips start (level) where the hips are drawn.
// Left to the hand-over, their offset decays over its time and carries the whole figure with it, a foot pinned
// meanwhile too (the run pivot: the left foot planted 0.1 s into the hand-over was pulled 25 cm)
void Motor::align_hips(const Clip &p_c, double p_t0) {
	if (!host || st == TRAV) return;
	const Frame f = p_c.d->lerp(p_t0);
	const Vector3 drawn = fig->bone_world("Bip01_Pelvis");
	const Vector3 p_new = host->position() + Basis(UP, yaw).xform(f.hips - p_c.off);
	Vector3 by = drawn - p_new; by.y = 0.0f;
	last_align = (float)by.length();
	if (last_align < 0.005f || last_align > 0.4f) return;
	if (host->shift(by)) n_hips_aligned++;
}

void Motor::play(const Clip &p_c, double p_t0, float p_blend) {
	if (no_align) { no_align = false; into_loop = false; }   // (a root clip: its anchor places it)
	else if (face_only) { face_only = false; if (!into_loop) align_facing(p_c, p_t0); into_loop = false; }   // (cover: the wall places the body)
	else {
		if (!into_loop) align_facing(p_c, p_t0);   // (into a loop the facing is the way he travels: turned to the hips mid-turn at a pivot's end, the run's travel swung 1.5 m/s sideways)
		into_loop = false;
		if (!align_contacts(p_c, p_t0)) align_hips(p_c, p_t0);
	}
	anim->play(p_c.name, 0.0);
	t = std::min(std::max(p_t0, 0.0), p_c.d->len);
	anim->seek(t, true);
	if (cur && cur->ok()) {   // (between a set's own clip and one it shares with set 1 - a run stop, a pivot -
		// another actor's pose: a longer hand-over; at set 1's, the hips' speed jumped 1.4-2.7 m/s there)
		const String a = String(cur->name), b = String(p_c.name);
		const bool own_a = a.begins_with("ms/") || a.begins_with("yl/"), own_b = b.begins_with("ms/") || b.begins_with("yl/");
		if (own_a != own_b) p_blend = std::max(p_blend * 1.8f, 0.4f);
	}
	if (inert) inert->inertialize(p_blend);
	cur = &p_c; n_switch++;
}

void Motor::advance(float p_dt) {
	if (!cur) return;
	t += p_dt * rate;
	if (cur->lo > 0.0) { if (t > cur->d->len) t = cur->lo + std::fmod(t - cur->lo, cur->d->len - cur->lo); }   // (a held tail, looped)
	else if (cur->d->loop && cur->d->len > 0.0) { t = std::fmod(t, cur->d->len); if (t < 0.0) t += cur->d->len; }
	else t = std::min(t, cur->d->len);
	anim->seek(t, true);
}

Vector3 Motor::clip_vel(const Clip &p_c, double p_t) const {
	// the clip's own travel, read from its planted feet (mo_clip root_v), turned as the clip turns
	const float y = turn_k * p_c.d->yaw(p_t);
	const Vector3 v = p_c.d->root_v.empty() ? fwd_of(y) * p_c.curve("vz", p_t, 0.0f) + left_of(y) * p_c.curve("vx", p_t, 0.0f) : Basis(UP, y).xform(p_c.d->root_vel(p_t));
	return Basis(UP, yaw0).xform(v) * rate;
}

int Motor::pick_loop(float p_speed, int p_keep, bool p_random) {
	const float sp = std::max(p_speed, 0.3f);
	int best = 0;
	for (int i = 1; i < n_loops; i++) if (std::fabs(std::log(sp / loops[i].ground_v)) < std::fabs(std::log(sp / loops[best].ground_v))) best = i;
	const float lb = std::fabs(std::log(sp / loops[best].ground_v));
	if (p_keep >= 0 && p_keep < n_loops && std::fabs(std::log(sp / loops[p_keep].ground_v)) < lb + 0.15f) return p_keep;   // (on the move: the one he is in)
	if (!p_random) {   // (out of a pivot, a turn, a pace change: the nearest of set 1's - its transitions were made with them;
		// out of a run pivot into set 3's quick run the hips' speed jumped 1.5 m/s)
		int b1 = -1;
		for (int i = 0; i < n_loops; i++) if (!String(loops[i].name).begins_with("ms/") && (b1 < 0 || std::fabs(std::log(sp / loops[i].ground_v)) < std::fabs(std::log(sp / loops[b1].ground_v)))) b1 = i;
		return (b1 >= 0 && std::fabs(std::log(sp / loops[b1].ground_v)) < lb + 0.15f) ? b1 : best;
	}
	// a new one: at random among those as near the pace (within 15 %) - set 1's and set 3's takes rotate
	int cand[16]; int nc = 0;
	// (not jog_a unless it is the nearest: picked at random for a faster run, played sped up, its run stop jumped the hips'
	// speed 2.1 m/s and its run pivot popped them 4.3 cm - Yasin: "remove the parts that break the quality chain")
	for (int i = 0; i < n_loops; i++) if (std::fabs(std::log(sp / loops[i].ground_v)) < lb + 0.15f && (i == best || String(loops[i].name) != "prun/jog_a")) cand[nc++] = i;
	return nc > 0 ? cand[(int)(rnd() * nc) % nc] : best;
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
	idle_tired = tired && n_tired > 0;
	Clip *idles = idle_tired ? tired_idles : this->idles;
	const int n_idles = idle_tired ? n_tired : this->n_idles;
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
	if (stand_to_stand) no_align = true;   // (from a gesture: the feet stay planted)
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
	loop_i = pick_loop(p_want, -1, true);   // (from a stand: set 1's and set 3's takes at random)
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
	if (c->a->has_meta(key)) hand_at = (double)c->a->get_meta(key);
	else {   // (a loop the start was not measured for - another movement set's: the moment of its second half most like
		// the loop's own stride, at its pace; at 3/4 of it, set 2's run took over with the hips' speed jumping 1.8 m/s)
		const Clip &L = loops[loop_i];
		hand_at = c->d->len * 0.75; float best = 1e30f;
		// (within the span its measured hand-overs use: past them, start_a's hips stall for 3 frames - never played in set 1)
		double lo = c->d->len * 0.45, hi = c->d->len - 1.0 / FPS, mlo = 1e9, mhi = -1e9;
		const TypedArray<StringName> metas = c->a->get_meta_list();
		for (int mi = 0; mi < metas.size(); mi++) { const StringName m = metas[mi]; if (!String(m).begins_with("out_at_")) continue; const double v = (double)c->a->get_meta(m); mlo = std::min(mlo, v); mhi = std::max(mhi, v); }
		if (mhi > 0.0) { lo = std::max(0.0, mlo - 0.05); hi = std::min(hi, mhi + 0.03); }
		// (and before any jump in its own hips: prun/start_a's hips leap 8 cm back in one frame at 0.55 s - played into
		// set 1's slowest jog too, unseen there behind the hand-over to it)
		for (int k = (int)(lo * FPS); k + 1 < (int)c->d->f.size() && (k + 1) / FPS <= hi; k++)
			if ((c->d->f[k + 1].hips - c->d->f[k].hips).length() > 0.05f) { hi = std::max(lo, k / FPS - 1.0 / FPS); break; }
		for (double tt = lo; tt <= hi; tt += 1.0 / FPS) {
			float pc = 0.0f;
			best_entry(*c->d, tt, *L.d, 0.0, L.d->len, &pc);
			const float dv = (float)c->d->root_vel(tt).length() - L.ground_v;
			const float cost = pc + 0.3f * dv * dv;
			if (cost < best) { best = cost; hand_at = tt; }
		}
	}
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
	// (out into set 1's run nearest the pace: the pivot's hand-over was measured for those - from set 3's run, it handed
	// over at its end and the hips' speed jumped 1.7 m/s)
	if (loop_i >= 0 && String(loops[loop_i].name).begins_with("ms/")) loop_i = pick_loop(loops[loop_i].ground_v, -1);
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
	if (cur) at -= Basis(UP, yaw).xform(cur->off);
	fig->set_global_transform(Transform3D(Basis(UP, yaw), at));
}

void Motor::replace(Host &p_host) {
	if (!fig || st == TRAV || !draw_ok) return;
	Vector3 at = p_host.position(); at.y = draw_y;
	if (cur) at -= Basis(UP, yaw).xform(cur->off);
	fig->set_global_transform(Transform3D(Basis(UP, yaw), at));
}

// THE LANDING ON A STEP: the ground sampled every 2 cm along the foot (30 cm behind the heel to 30 cm past the toe);
// the level stretch (a tread, a kerb's top, the street) under the middle of the sole is where the foot goes: moved so
// the whole sole (heel 6 cm behind the ankle to the toe) is on it, or centred on it when it is shorter than the sole.
// Returns that level move (none: no step under the sole; a slope: the sole tilts onto it instead)
Vector3 Motor::step_clear(Host &p_host, const Vector3 &p_ankle, const Vector3 &p_toe) {
	Vector3 dir = p_toe - p_ankle; dir.y = 0.0f;
	const float flen = (float)dir.length();
	if (flen < 0.05f) return Vector3();
	dir /= flen;
	const float L = flen + 0.06f, pre = 0.30f, step = 0.02f;
	const Vector3 a0 = p_ankle - dir * 0.06f;
	const int n = (int)((L + 2.0f * pre) / step) + 1;
	float h[64]; bool ok[64];
	const int m = std::min(n, 64);
	bool any_face = false;
	for (int i = 0; i < m; i++) {
		const Vector3 q = a0 + dir * (-pre + step * i);
		Vector3 g2, n2;
		ok[i] = p_host.ray(q + Vector3(0, 0.6f, 0), q - Vector3(0, 0.6f, 0), g2, n2) && n2.y >= 0.97f;
		h[i] = ok[i] ? (float)g2.y : -1e9f;
	}
	const int i0 = (int)(pre / step), i1 = std::min((int)((pre + L) / step), m - 1), im = (int)((pre + 0.5f * L) / step);
	for (int i = i0; i <= i1; i++) { if (!ok[i]) return Vector3(); if (std::fabs(h[i] - h[i0]) > 0.04f) any_face = true; }
	if (!any_face) return Vector3();
	// the level stretch under the middle of the sole
	int s0 = im, s1 = im;
	while (s0 > 0 && ok[s0 - 1] && std::fabs(h[s0 - 1] - h[im]) < 0.02f) s0--;
	while (s1 < m - 1 && ok[s1 + 1] && std::fabs(h[s1 + 1] - h[im]) < 0.02f) s1++;
	const float u0 = -pre + step * s0, u1 = -pre + step * s1;   // (along the sole: 0 the heel, L the toe)
	float shift = 0.0f;
	if (u1 - u0 >= L + 0.02f) { if (u0 > 0.0f) shift = u0 + 0.01f; else if (u1 < L) shift = u1 - 0.01f - L; }
	else shift = 0.5f * (u0 + u1) - 0.5f * L;
	if (std::fabs(shift) < 0.005f) return Vector3();
	n_pin_fix++;
	return dir * shift;
}

// THE GROUND UNDER EACH FOOT (for MoLimbs): where the clip puts the foot this frame, a ray down there; the foot moved by
// the ground's height there against the figure's floor - fully while the clip has it on its floor, and, in the swing,
// only up (over a stair's edge; down, it stays where the clip swings it)
void Motor::ground_feet(Host &p_host) {
	if (!limbs || !cur) return;
	limbs->fwd_w = Vector3(std::sin(yaw), 0.0f, std::cos(yaw));
	limbs->ground_y = draw_y;
	limbs->fit_on = st != TRAV && st != OFF;
	if (!limbs->fit_on) return;
	const Frame fr = cur->d->lerp(t);
	const Transform3D X = fig->get_global_transform();
	// (a foot rests on the highest ground under its sole: under the ankle alone, a foot at a stair's edge was pulled
	// down onto the step below, 17 cm into the one it stood on)
	// (only at a STEP: level ground at both, 4 cm or more apart - on a ramp the toe's ground is higher by the slope and
	// the sole is tilted onto it instead)
	auto sole = [&](const Vector3 &p_ankle, const Vector3 &p_toe, Vector3 &r_g, Vector3 &r_n) {
		Vector3 g, gn;
		if (!p_host.ray(p_ankle + Vector3(0, 0.6f, 0), p_ankle - Vector3(0, 0.6f, 0), g, gn) || gn.y < 0.5f) return false;
		r_g = g; r_n = gn;
		if (gn.y < 0.97f) return true;
		// (onto the higher step only when the ball AND the middle of the sole are over it: most of the foot)
		Vector3 gt, nt, gm, nm;
		const Vector3 mid = p_ankle.lerp(p_toe, 0.5f);
		if (p_host.ray(p_toe + Vector3(0, 0.6f, 0), p_toe - Vector3(0, 0.6f, 0), gt, nt) && nt.y >= 0.97f && gt.y > r_g.y + 0.04f &&
				p_host.ray(mid + Vector3(0, 0.6f, 0), mid - Vector3(0, 0.6f, 0), gm, nm) && nm.y >= 0.97f && gm.y > r_g.y + 0.04f) { r_g = Vector3(p_ankle.x, std::min(gt.y, gm.y), p_ankle.z); r_n = nm; }
		return true;
	};
	for (int s = 0; s < 2; s++) {
		Vector3 fw = X.xform(Vector3(fr.foot[s].x, 0.0f, fr.foot[s].z)); fw.y = draw_y;
		Vector3 tw = X.xform(Vector3(fr.toe[s].x, 0.0f, fr.toe[s].z)); tw.y = draw_y;
		Vector3 g, gn;
		if (!sole(fw, tw, g, gn)) { g = fw; gn = UP; }
		const float h = (float)fr.foot[s].y - cur->d->ground_y;
		const float w = 1.0f - sstep(0.04f, 0.25f, h);
		const float off = (float)g.y - draw_y;
		limbs->fit_off[s] = off > 0.0f ? off : off * w;
		// a pin's height: the ground at the PIN (on stairs the clip's foot and the pin can be on different steps) plus
		// the clip's foot over its own floor plus the ankle's height standing (a raw Mixamo take's floor is not festive's)
		Vector3 gp = g;
		// A FOOT ACROSS A STEP'S FACE: decided in the swing, not after it lands (moved once pinned, it slid 7 cm). The
		// clip's landing looked up ahead (within 0.2 s), its spot predicted (the clip's foot then, the body's travel till
		// then), the sole there sampled heel to toe; across a face, the landing moved clear of it - back, or forward onto
		// the step if most of the sole is over it - eased in over the rest of the swing. Pinned, the pin holds it.
		if (!limbs->locked[s]) {
			Vector3 want_off;
			float k_in = 0.0f;
			for (float tau = 1.0f / 60.0f; tau <= 0.2f + 1e-4f; tau += 1.0f / 60.0f) {
				const double tl = t + tau * rate;
				if (!cur->d->loop && tl > cur->d->len) break;
				const Frame fl = cur->d->lerp(tl);
				if (!fl.down[s]) continue;
				Vector3 P = X.xform(Vector3(fl.foot[s].x, 0.0f, fl.foot[s].z)) + Vector3(last_vel.x, 0.0f, last_vel.z) * tau; P.y = draw_y;
				Vector3 T = X.xform(Vector3(fl.toe[s].x, 0.0f, fl.toe[s].z)) + Vector3(last_vel.x, 0.0f, last_vel.z) * tau; T.y = draw_y;
				want_off = step_clear(p_host, P, T);
				k_in = 1.0f - tau / 0.2f;
				break;
			}
			const Vector3 target = want_off * k_in;
			place_off[s] += (target - place_off[s]) * 0.35f;
			if (want_off.length() < 1e-4f && k_in <= 0.0f) place_off[s] *= 0.8f;   // (no landing near: gone)
			limbs->place_off[s] = place_off[s];
		}
		if (limbs->locked[s]) {
			Vector3 lp = limbs->lock_w[s]; lp.y = draw_y;
			Vector3 gn2;
			if (!sole(lp, lp + (tw - fw), gp, gn2)) gp = lp;
		}
		limbs->fit_y[s] = (float)gp.y + std::max((float)fr.foot[s].y - cur->d->ground_y, 0.0f) + ankle_rest;
		limbs->fit_w[s] = w; limbs->ground_n[s] = gn;
	}
}

void Motor::step(float p_dt, const Intent &p_in, Host &p_host) {
	stamina_step(p_dt);
	if (style_want != style && fig && st == IDLE) { style = style_want; load_clips(); to_idle(0.3f); }   // (a new movement set: taken while he stands)
	if (st == OFF || !cur) return;
	host = &p_host;
	// (the feet's pull as DRAWN last frame, read before this step seeks the clip: a pass made mid-step, with the clip
	// moved on and the figure not yet placed, gave a pull that alternated frame to frame - the body followed it, the
	// hips' speed jumped 1.4 m/s)
	if (limbs) for (int s = 0; s < 2; s++) { drawn_pull[s] = limbs->pull_v[s]; drawn_locked[s] = limbs->locked[s] && !limbs->stepping(s); }
	drawn_pel = fig->bone_world("Bip01_Pelvis");   // (as drawn last frame: mid-step, at a hand-over, it is the new clip's raw pose)
	Vector3 dir(p_in.dir.x, 0.0f, p_in.dir.z);
	float sp_in = p_in.speed;
	phone_step(p_dt, p_in);
	if (p_in.phone != 0 || ph_phase != 0) sp_in = std::min(sp_in, 1.6f);   // (the phone out: a walk at most - "we shouldnt be able to run while on a phone call")
	// SITTING (mo_motor_sit.cpp): on the seat, or into / out of it - the clip has the body; walking to a seat, the way to it
	if (st == SIT) { sit_step(p_dt, p_in); host = nullptr; return; }
	if (p_in.sit && (st == IDLE || st == START || st == MOVE || st == STOP || st == TURN)) {
		if (sit_approach(p_in, dir, sp_in) && st == IDLE) {
			const float dy = wrapf(p_in.seat_yaw - yaw);
			if (std::fabs(dy) > 0.45f) { to_turn(dy); host = nullptr; return; }   // (his back to it first)
			sit_start(p_in); host = nullptr; return;
		}
	}
	const float wl = std::min((float)dir.length(), 1.0f);
	const bool want = wl > 0.1f;
	const float want_speed = sp_in * wl;
	const float d = want ? wrapf(std::atan2((float)dir.x, (float)dir.z) - yaw) : 0.0f;
	Vector3 vel;   // level velocity this frame (world)
	if (st == TRAV) {   // a vault or a climb: the clip has the body (mo_motor_trav.cpp)
		trav_step(p_dt);
		host = nullptr;
		return;
	}
	// JUMPS AND FALLS (mo_motor_air.cpp)
	if (st == JUMP) {   // the take-off: then the flight
		advance(p_dt);
		if (t >= cur->d->len - 0.02) air_start(Vector3(air_v.x, jump_v, air_v.z), true);
		else place(p_host, p_dt);
		host = nullptr;
		return;
	}
	if (st == AIR) { air_step(p_dt, p_in); host = nullptr; return; }
	// ROOT CLIPS (mo_motor_cover.cpp): a stance change, into or out of cover, a landing, a running leap - the clip has the body
	if (st == STANCE || st == COVER_IN || st == COVER_OUT || st == LAND || st == RUNJUMP || st == DESCEND || st == SIT_IN || st == SIT_OUT) {
		const bool done = root_step(p_dt) || (st == SIT_OUT && t >= sit_up_at);
		if (limbs && cur) {
			const Frame fr = cur->d->lerp(t);
			limbs->lock_on = true; limbs->may_step = st == STANCE;   // (getting up / down: a foot far off the clip's re-plants)
			limbs->drop_max = (st == SIT_IN || st == SIT_OUT) ? 0.0f : 0.35f;   // (sitting down / up: the hips on the seat, the legs reach - dropped for the feet, they went 11 cm into a 60 cm seat)
			limbs->down[0] = fr.down[0]; limbs->down[1] = fr.down[1];
			// OFF A LEDGE: the hand that reaches down as he goes over is put on the ledge's corner (Yasin, 24 Nov: "the hand
			// doesnt reach the corner of the obstacle") - eased in and out of its reach, held where it first comes down
			if (st == DESCEND && dn_cur && dn_hand >= 0) {
				const int s = dn_hand;
				const float w = sstep((float)dn_h0 - 0.1f, (float)dn_h0 + 0.06f, (float)t) * (1.0f - sstep((float)dn_h1, (float)dn_h1 + 0.15f, (float)t));
				if (w > 0.001f && limbs->hand_w[s] <= 0.001f) {
					const Vector3 own = root_anchor(t) + Basis(UP, rp.yaw).xform(fr.hand[s]);
					const Vector3 side = UP.cross(dn_n).normalized();
					dn_hand_w = dn_edge + side * (float)(own - dn_edge).dot(side) + dn_n * 0.05f;   // (on the top, 5 cm in from its edge)
					dn_hand_w.y = dn_edge.y + 0.05f;   // (the wrist over the palm)
				}
				limbs->hand_w[s] = w; limbs->hand_target[s] = dn_hand_w;
			}
		}
		ground_feet(p_host);
		if (done) {
			if (limbs && st == DESCEND) { limbs->hand_w[0] = limbs->hand_w[1] = 0.0f; dn_cur = nullptr; }
			if (st == LAND) {
				if (rp.c == &ai_flat && ai_getup.ok()) { root_start(ai_getup, 0.0, 0.3f, yaw, nullptr, false); host = nullptr; return; }   // (down flat: up again)
				if (want) { speed = std::max(speed, 0.8f); to_loop(pick_loop(want_speed, loop_i), blend_loop); }
				else to_idle(0.35f);
				place(p_host);
				host = nullptr;
				return;
			}
			if (st == SIT_IN) { st = SIT; sit_t = 0.0f; sit_gesture = false; align_full = true; face_only = true; play(si_idle, 0.0, 0.35f); align_full = false; place_sit(); host = nullptr; return; }
			if (st == SIT_OUT) {
				yaw = sit_yaw; align_full = true;
				if (want) { speed = std::max(speed, 0.8f); to_loop(pick_loop(want_speed, -1), blend_loop); } else to_idle(0.35f);
				align_full = false; place(p_host); host = nullptr; return;
			}
			if (st == DESCEND) {   // (down: on as he was, facing as the clip ends)
				const Frame f0 = rp.c->d->lerp(0.0), f1 = rp.c->d->lerp(rp.c->d->len);
				yaw = rp.yaw + std::remainder((float)(f1.face - f0.face), 6.2831853f);
				align_full = true;
				if (want) { speed = std::max(speed, 0.8f); to_loop(pick_loop(want_speed, loop_i), blend_loop); }
				else to_idle(0.35f);
				align_full = false;
				place(p_host);
				host = nullptr;
				return;
			}
			if (st == RUNJUMP && rp.c == &ai_walk) {   // (the leap's end is in the air: on in the flight, its pace)
				const Frame a = rp.c->d->lerp(rp.c->d->len - 0.1), z = rp.c->d->lerp(rp.c->d->len);
				const Vector3 v = Basis(Vector3(0, 1, 0), rp.yaw).xform((z.hips - a.hips) / 0.1);
				air_start(Vector3(v.x, std::max(0.0f, (float)v.y), v.z), true);
				host = nullptr; return;
			}
			if (st == RUNJUMP && (rp.c == &ai_stand || rp.c == &ai_stand2)) {
				if (want) { speed = std::max(speed, 0.8f); to_loop(pick_loop(want_speed, loop_i), blend_loop); }
				else to_idle(0.3f);
				place(p_host);
				host = nullptr; return;
			}
			if (st == RUNJUMP) {
				const Vector3 b = p_host.position();
				const float gb = ground_below(b, 60.0f);
				if (gb < -1e8f || (float)b.y - gb > 0.5f) { air_start(fwd_of_yaw() * 3.5f, false); host = nullptr; return; }   // (over a drop: falling on)
				if (want) { speed = std::max(speed, 2.5f); to_loop(pick_loop(want_speed, loop_i), blend_loop); }
				else { speed = 2.5f; to_stop(); }
				place(p_host);
				host = nullptr;
				return;
			}
			if (st == STANCE) { if (stance_to == 1) to_crouch(0.3f); else to_idle(0.3f); }
			else if (st == COVER_IN) {
				const Clip &ci = cv_idle[cv_tall ? 1 : 0];
				st = COVER; cv_t = 0.0f; cv_dir = 0;
				align_full = true; face_only = true;
				play(ci, best_entry(*cur->d, t, *ci.d, 0.0, ci.d->len, &last_entry_cost), 0.3f);
				align_full = false;
			} else to_idle(0.35f);
			place(p_host);
		}
		host = nullptr;
		return;
	}
	// carrying: into it (a box, a bag) from standing or on the move
	if (p_in.carry != 0 && st != CARRY && (st == IDLE || st == START || st == MOVE || st == STOP || st == TURN || st == PIVOT)) {
		carry = p_in.carry;
		if (st == MOVE || st == START || st == PIVOT) { const Clip &L = carry == 1 ? ca_walk : (carry == 3 ? sb_walk : bg_walk); into_loop = true; play(L, best_entry(*cur->d, t, *L.d, 0.0, L.d->len, &last_entry_cost), 0.35f); }
		else to_carry_idle(0.35f);
		st = CARRY;
	}
	// A JUMP (the right double tap), OFF AN EDGE (the ground gone from under him, 0.5 m or more down)
	if (air_ready() && (st == IDLE || st == START || st == MOVE || st == STOP || st == TURN || st == PIVOT)) {
		if (p_in.jump) jump_pending = 0.4f;
		if (jump_pending > 0.0f) { jump_pending = 0.0f; jump_start(dir, want_speed); host = nullptr; return; }   // (at once: Yasin, 24 Nov, the running jump as it was)
		// walking at a ledge (not running): down it by a hop, a jump down or a climb down
		if (want && !p_in.sit && std::fabs(d) < 0.5f && want_speed <= 2.0f && speed <= 2.2f && descend_probe(fwd_of(yaw))) { host = nullptr; return; }
		if (!p_host.on_floor()) {
			const Vector3 b = p_host.position();
			const float gb = ground_below(b, 60.0f);
			if (gb < -1e8f || (float)b.y - gb > 0.5f) { air_start(Vector3(last_vel.x, 0.0f, last_vel.z), false); host = nullptr; return; }
		}
	}
	// INTO COVER (Yasin, 23 Nov: "once we get near a wall or low obstacles while crouching, cover automatically
	// initiates"): crouched, pushing into a wall within 0.75 m of him, from 0.6 m high. Asked for (an NPC's mind): the
	// nearest wall round him
	if (st == CROUCH && want && cover_probe(dir, 0.75f, false)) { host = nullptr; return; }
	if (p_in.cover && (st == IDLE || st == START || st == MOVE || st == STOP || st == CROUCH) && cover_probe(want ? dir : fwd_of(yaw), 1.6f, true)) { host = nullptr; return; }
	// into the crouch
	if (p_in.crouch && cr_idle.ok() && cr_walk.ok()) {
		if (st == IDLE || st == STOP || st == TURN) { to_stance(1); host = nullptr; return; }
		if (st == START || st == MOVE || st == PIVOT) {   // (on the move: into the crouched walk, in step)
			into_loop = true;
			play(cr_walk, best_entry(*cur->d, t, *cr_walk.d, 0.0, cr_walk.d->len, &last_entry_cost), 0.35f);
			st = CROUCH;
		}
	}
	// a vault or a climb ahead, going the way he faces
	if (want && !p_in.sit && std::fabs(d) < 0.5f && (st == IDLE || st == START || st == MOVE) && trav_probe(fwd_of(yaw), std::max(speed, want_speed > 2.0f ? speed : 0.0f))) { host = nullptr; return; }
	switch (st) {
		case CROUCH: crouch_step(p_dt, p_in, d, want, vel); break;
		case CARRY: carry_step(p_dt, p_in, d, want, vel); break;
		case COVER: cover_step(p_dt, p_in, vel); break;
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
			if (fid && t >= cur->d->len - 0.02) { stand_to_stand = true; to_idle(0.45f); stand_to_stand = false; }
			else if (!fid && (tired && n_tired > 0) != idle_tired) { to_idle(0.6f); }   // (out of breath / rested: the other idle)
			else if (!fid && !idle_tired && idle_t >= 2.0f * (float)cur->d->len && n_fidgets_c > 0) {   // (two loops of the idle, then a gesture)
				int k = (int)(rnd() * n_fidgets_c) % n_fidgets_c; if (k == last_fidget) k = (k + 1) % n_fidgets_c;
				last_fidget = k; rate = 1.0f;
				const double e = best_entry(*cur->d, t, *fidgets[k].d, 0.0, std::min(1.0, fidgets[k].d->len), &last_entry_cost);
				no_align = true;   // (standing into standing: the feet stay where they stand - re-aligned, both jumped 5 cm and one re-planted with a step "as if about to walk", Yasin 24 Nov)
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
			if (speed > 0.05f && host) {   // (a stop's last steps never carry him off an edge: let go at a ledge, he fell from it)
				const Vector3 p = host->position();
				const float here = ground_below(p, 0.6f);
				const Vector3 q = p + vel.normalized() * 0.3f;
				const float g = ground_below(Vector3(q.x, here + 1.2f, q.z), 4.2f);
				if (here > -1e8f && (g < -1e8f || g < here - 0.5f)) { vel = Vector3(); speed = 0.0f; }   // (a step under 0.5 m: stepped down)
			}
			if (t >= cur->meta("still_at", (float)cur->d->len) || t >= cur->d->len - 0.02) to_idle(blend_idle);
			break;
		}
		case PIVOT: {
			advance(p_dt);
			yaw = yaw0 + turn_k * cur->d->yaw(t);
			vel = clip_vel(*cur, t);
			speed = (float)vel.length();
			if (t >= hand_at || t >= cur->d->len - 0.02) {
				if (want) { speed = std::max(speed, 0.8f); to_loop(pick_loop(std::max(speed, want_speed), String(loops[loop_i].name).begins_with("ms/") ? -1 : loop_i), blend_loop); }   // (on at the pace wanted: a run's pivot runs on - into set 1's)
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
		// (standing in the idle and its gestures: a foot is moved only when 12 cm off the clip's stance, not 4 - the idle's
		// and gestures' stances differ by 4-7 cm and every idle began with a step "as if about to walk", Yasin 24 Nov)
		limbs->drop_max = 0.35f;
		limbs->step_pull = st == IDLE ? 0.12f : 0.04f; limbs->step_now = st == IDLE ? 0.25f : 0.12f;
		limbs->may_step = st == IDLE || st == STOP || (st == CROUCH && cur == &cr_idle) || (st == COVER && cv_dir == 0) || (st == CARRY && (cur == &ca_idle || cur == &bg_idle));   // (standing: a foot held off the clip's stance re-plants)
		limbs->down[0] = fr.down[0]; limbs->down[1] = fr.down[1];
	}
	// THE BODY FOLLOWS ITS PLANTED FEET: a foot pinned where the clip no longer has it (pinned during a hand-over, the
	// leg's offset then decayed away from it; or the clip's stance and its travel disagree) draws the body toward it,
	// 3 per second, at most 0.5 m/s, rather than bend the leg off the clip's pose (a walk stop held a leg 25 cm off for 0.6 s)
	if (limbs && st != COVER) {   // (in cover the wall places the body: followed, it drifted 30 cm off the wall)
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
	last_vel = vel;
	const Vector3 got = p_host.slide(v, p_dt);
	const float got_s = (float)Vector3(got.x, 0, got.z).length();
	if (st == MOVE) speed = std::min(speed, got_s + 0.6f);   // (into a wall he does not keep a pace he cannot walk)
	place(p_host, p_dt);
	ground_feet(p_host);
	carry_hands(p_dt);
	host = nullptr;
}

// STAMINA: tired after 30 s of running without a break, or a fifth jump each within 2 s of landing the one before; rested
// after 10 s without running or jumping (the clock of a jump chain starts at its landing)
void Motor::stamina_step(float p_dt) {
	const bool running = (st == MOVE || st == START || st == PIVOT || st == TURN || st == RUNJUMP) && (speed > 2.0f || run_t > 0.0f && speed > 1.0f);   // (its turns and pivots are running too)
	since_land += p_dt;
	if (running) { run_t += p_dt; rest_t = 0.0f; }
	else { run_t = std::max(0.0f, run_t - 0.5f * p_dt); if (st != JUMP && st != AIR && st != RUNJUMP && st != LAND) rest_t += p_dt; }
	if (st == JUMP || st == AIR || st == RUNJUMP) { rest_t = 0.0f; since_land = 0.0f; }
	if (!tired && (run_t >= 30.0f || jump_chain >= 5)) { tired = true; n_tired_spells++; rest_t = 0.0f; }
	if (tired && rest_t >= 10.0f) { tired = false; run_t = 0.0f; jump_chain = 0; }
}
