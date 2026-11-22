// mo::Motor, step 5: the crouch and cover (docs/ANIMATION_PLAN.md; Yasin, 22 Nov: "build ... with every advanced
// feature like taking cover"). Festive's clips only (ptrav), none of its code.
//
// THE CROUCH: Standing_To_Crouched in, Crouched_To_Standing out (root clips: the hips carry the body a few cm), the
// crouched idle and walk between (Crouching_Idle, Crouched_Walking), steered like the walk.
// COVER: a wall ahead (cover_probe): its face and how high it is. From 1.45 m: standing cover (Cover_Idle); 0.6 to 1.45 m:
// crouched behind it (Crouch_Cover_Idle). In by Stand_To_Cover_a / _b (a root clip: a step to the wall and the turn to
// put his back to it), its end warped so the body ends at the cover distance from the real wall; along the wall by the
// cover sneaks (in-place loops that travel sideways), the body held at the wall's distance and stopped at its end; out
// by Cover_To_Stand_b / _a (a root clip back off the wall).
// The cover clips were captured in different frames (Cover_Idle is turned half round against the end of
// Stand_To_Cover_a): each hand-over in cover turns the new clip onto the drawn hips (align_full) - the clip's motion
// stays its own, only where it stands is fitted.
#include "mo_motor.h"

#include "city_ped.h"
#include "mo_inertial.h"
#include "mo_limbs.h"

#include <godot_cpp/classes/animation_player.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;
using namespace godot::mo;

namespace {
const Vector3 UP(0, 1, 0);
const float PI_C = 3.14159265f, TAU_C = 6.2831853f;
float wrapc(float a) { a = std::fmod(a + PI_C, TAU_C); if (a < 0.0f) a += TAU_C; return a - PI_C; }
float clampc(float x, float a, float b) { return std::min(std::max(x, a), b); }
float sstepc(double a, double b, double x) {
	if (b <= a) return x >= b ? 1.0f : 0.0f;
	const float u = clampc((float)((x - a) / (b - a)), 0.0f, 1.0f);
	return u * u * (3.0f - 2.0f * u);
}
Vector3 level(const Vector3 &v) { return Vector3(v.x, 0.0f, v.z); }
float yaw_of(const Vector3 &v) { return std::atan2((float)v.x, (float)v.z); }
} // namespace

void Motor::load_cover() {
	cr_idle = load("ptrav/Crouching_Idle"); cr_walk = load("ptrav/Crouched_Walking");
	cr_in = load("ptrav/Standing_To_Crouched"); cr_out = load("ptrav/Crouched_To_Standing");
	cv_in[0] = load("ptrav/Stand_To_Cover_b"); cv_in[1] = load("ptrav/Stand_To_Cover_a");
	cv_idle[0] = load("ptrav/Crouch_Cover_Idle"); cv_idle[1] = load("ptrav/Cover_Idle");
	cv_out[0] = load("ptrav/Cover_To_Stand_a"); cv_out[1] = load("ptrav/Cover_To_Stand_b");
	cv_sneak_l[0] = load("ptrav/Crouched_Sneaking_Left"); cv_sneak_r[0] = load("ptrav/Crouched_Sneaking_Right");
	cv_sneak_l[1] = load("ptrav/Left_Cover_Sneak_a"); cv_sneak_r[1] = load("ptrav/Right_Cover_Sneak_a");
}

// ---- ROOT CLIPS: the figure at an anchor (eased from where he is to where the clip must end, while it plays), the
// body following the clip's hips over the ground
void Motor::root_start(const Clip &p_c, double p_t0, float p_blend, float p_yaw, const Vector3 *p_end_hips, bool p_face) {
	if (p_face) {   // (turned onto the drawn hips: a clip captured in another frame than the one playing)
		const Vector3 th = fig->bone_world("Bip01_L_Thigh") - fig->bone_world("Bip01_R_Thigh");
		const Vector3 fw = -UP.cross(th);
		if (level(fw).length() > 1e-3f) p_yaw = wrapc(yaw_of(fw) - (float)p_c.d->lerp(p_t0).face);
	}
	rp = RootPlay();
	rp.c = &p_c; rp.yaw = p_yaw; rp.t0 = p_t0;
	const Basis R(UP, p_yaw);
	const Frame f0 = p_c.d->lerp(p_t0);
	// (from: the clip's hips now where the drawn hips are)
	const Vector3 drawn = fig->bone_world("Bip01_Pelvis");
	rp.a_from = level(drawn) - R.xform(level(f0.hips));
	rp.a_from.y = host ? (float)host->position().y : 0.0f;
	rp.a_to = rp.a_from;
	if (p_end_hips) {   // (to: the clip's last hips on the place wanted - the warp spread over the first 70 % of it)
		const Frame f1 = p_c.d->lerp(p_c.d->len);
		rp.a_to = level(*p_end_hips) - R.xform(level(f1.hips));
		rp.a_to.y = rp.a_from.y;
	}
	rp.t_warp = p_t0 + 0.7 * (p_c.d->len - p_t0);
	yaw = p_yaw; yaw0 = p_yaw; turn_k = 1.0f; rate = 1.0f;
	align_full = false;
	no_align = true;   // (its place and facing are the anchor's: no hand-over alignment)
	play(p_c, p_t0, p_blend);
	fig->set_global_transform(Transform3D(Basis(UP, rp.yaw), rp.a_from));   // (placed in the same frame as the clip changes)
}

Vector3 Motor::root_anchor(double p_t) const { return rp.a_from.lerp(rp.a_to, sstepc(rp.t0, rp.t_warp, p_t)); }

bool Motor::root_step(float p_dt) {
	advance(p_dt);
	const Vector3 A = root_anchor(t);
	const Frame f = rp.c->d->lerp(t);
	Vector3 body = A + Basis(UP, rp.yaw).xform(level(f.hips));
	body.y = A.y;
	host->teleport(body);
	speed = 0.0f;
	draw_y = (float)A.y; draw_v = 0.0f; draw_ok = true;
	fig->set_global_transform(Transform3D(Basis(UP, rp.yaw), A));
	return t >= rp.c->d->len - 1e-3;
}

// ---- THE CROUCH
void Motor::to_crouch(float p_blend) {
	const double e = cur ? best_entry(*cur->d, t, *cr_idle.d, 0.0, cr_idle.d->len, &last_entry_cost) : 0.0;
	rate = 1.0f; turn_k = 1.0f;
	// (the body stays: the crouched walk's hips ride 34 cm higher and further on than the idle's, the alignment jumped
	// the body that far)
	if (cur == &cr_walk) face_only = true;
	play(cr_idle, e, p_blend);
	st = CROUCH;
}

void Motor::to_stance(int p_to) {
	const Clip &c = p_to == 1 ? cr_in : cr_out;
	if (!c.ok()) { if (p_to == 1) to_crouch(0.35f); else to_idle(0.35f); return; }
	stance_to = p_to;
	root_start(c, 0.0, 0.25f, yaw, nullptr, false);
	st = STANCE;
}

void Motor::crouch_step(float p_dt, const Intent &p_in, float p_d, bool p_want, Vector3 &r_vel) {
	if (!p_in.crouch) { to_stance(0); return; }
	if (p_want) {
		if (cur != &cr_walk) { into_loop = true; face_only = cur == &cr_idle; play(cr_walk, best_entry(*cur->d, t, *cr_walk.d, 0.0, cr_walk.d->len, &last_entry_cost), 0.3f); rate = 0.45f; }
		yaw += clampc(p_d, -crouch_turn_rate * p_dt, crouch_turn_rate * p_dt);
		const float wl = std::min((float)p_in.dir.length(), 1.0f);
		// (no crouched start or stop clip: the walk's rate eased up from 0.45 and down to it - at full pace at once, the
		// hips' speed jumped 1.3-1.4 m/s)
		rate = std::min(clampc(wl, 0.5f, 1.0f), rate + 2.0f * p_dt);
		advance(p_dt);
		r_vel = Basis(UP, yaw).xform(cr_walk.d->root_v.empty() ? Vector3(0, 0, 1.1f) : cr_walk.d->root_vel(t)) * rate;
		speed = (float)r_vel.length();
	} else {
		if (cur == &cr_walk) {
			// (let go: the walk runs on, at most half a stride, to the moment most like the crouched idle's stance -
			// switched mid-stride, a planted foot slid 28 cm)
			double best_w = 0.0; float best_c = 1e30f;
			for (double w = 0.0; w <= std::min(0.5, cr_walk.d->len) + 1e-6; w += 1.0 / 30.0) {
				float c = 0.0f;
				best_entry(*cr_walk.d, t + w * rate, *cr_idle.d, 0.0, cr_idle.d->len, &c);
				c += 0.05f * (float)w;
				if (c < best_c) { best_c = c; best_w = w; }
			}
			rate = std::max(0.45f, rate - 2.0f * p_dt);
			if (best_w < 0.5 / 60.0 && rate <= 0.5f) to_crouch(0.3f);
			else {
				advance(p_dt);
				r_vel = Basis(UP, yaw).xform(cr_walk.d->root_v.empty() ? Vector3(0, 0, 1.1f) : cr_walk.d->root_vel(t)) * rate;
				speed = (float)r_vel.length();
				return;
			}
		}
		advance(p_dt);
		speed = 0.0f;
	}
}

// ---- COVER
float Motor::cover_dist(const Vector3 &p_at) const {
	if (!host) return -1.0f;
	Vector3 g, n;
	const Vector3 from = Vector3(p_at.x, draw_y + 0.5f, p_at.z);
	if (!host->ray(from, from - cv_n * 1.2f, g, n) || std::fabs((float)n.y) > 0.3f) return -1.0f;
	return (float)level(from - g).length();
}

float Motor::cover_gap() const { return st == COVER ? last_gap : -1.0f; }

// a wall ahead, its face within 1.6 m of the body: knee-high ray; its top by a ray down just behind its face
Vector3 Motor::fwd_dir() const { return Vector3(std::sin(yaw), 0.0f, std::cos(yaw)); }

bool Motor::cover_probe(const Vector3 &p_dir) {
	if (!host || !cv_in[1].ok() || !cv_idle[1].ok()) return false;
	const Vector3 p = host->position();
	Vector3 dir = level(p_dir);
	if (dir.length() < 1e-3f) dir = fwd_dir();
	dir.normalize();
	Vector3 g, n;
	const Vector3 k0(p.x, draw_y + 0.5f, p.z);
	// (the way he faces or pushes, 1.6 m; else the nearest wall round him within 1.6 m)
	bool hit = host->ray(k0, k0 + dir * 1.6f, g, n) && std::fabs((float)n.y) <= 0.3f && level(n).dot(dir) <= -0.5f;
	if (!hit) {
		float best = 1e9f;
		for (int i = 0; i < 12; i++) {
			const float a = TAU_C * i / 12.0f;
			const Vector3 d2(std::sin(a), 0.0f, std::cos(a));
			Vector3 g2, n2;
			if (host->ray(k0, k0 + d2 * 1.6f, g2, n2) && std::fabs((float)n2.y) <= 0.3f && level(n2).dot(d2) <= -0.5f && (float)level(g2 - k0).length() < best) { best = (float)level(g2 - k0).length(); g = g2; n = n2; dir = d2; hit = true; }
		}
	}
	if (!hit) return false;
	const Vector3 N = level(n).normalized();
	const Vector3 behind = Vector3(g.x, draw_y + 2.6f, g.z) - N * 0.12f;
	Vector3 gt, nt;
	float h = 2.6f;
	if (host->ray(behind, Vector3(behind.x, draw_y + 0.05f, behind.z), gt, nt)) h = (float)gt.y - draw_y;
	if (h < 0.6f) return false;
	const bool tall = h >= 1.45f;
	const Clip &cin = cv_in[tall ? 1 : 0];
	if (!cin.ok()) return false;
	cv_w = Vector3(g.x, draw_y, g.z); cv_n = N; cv_tall = tall; cv_dir = 0; cv_t = 0.0f;
	// in: facing the wall, the clip's end hips at the cover distance from it (along the line he came on)
	const float yaw_in = yaw_of(-N);
	const Vector3 side = UP.cross(N);
	const float along = (float)(level(p) - level(cv_w)).dot(side);
	const Vector3 end_hips = level(cv_w) + side * along + N * (tall ? cover_d_tall : cover_d_low);
	root_start(cin, 0.0, 0.25f, yaw_in, &end_hips, false);
	st = COVER_IN; n_covers++;
	if (limbs) { limbs->unlock_all(); }
	return true;
}

void Motor::cover_sneak(int p_dir) {
	const int k = cv_tall ? 1 : 0;
	const Clip &c = p_dir > 0 ? cv_sneak_l[k] : cv_sneak_r[k];
	if (!c.ok()) return;
	// the sneak's own travel, turned onto the wall: its frame was not the idle's
	Vector3 tv;
	for (const Vector3 &v : c.d->root_v) tv += v;
	if (level(tv).length() < 1e-3f) return;
	// (his left, his back to the wall facing out along N: up x N)
	// (turned onto the drawn hips like any hand-over - set so its travel ran along the wall, the figure turned 16 degrees
	// at once and the turn's offset swung a planted foot 35 cm; the travel is put along the wall instead, cover_step)
	const Vector3 left = UP.cross(cv_n);
	const Vector3 want = left * (float)p_dir;
	turn_k = 1.0f; rate = 1.0f;
	face_only = true; align_full = true;   // (the wall places the body: aligned to the sneak's hips, it jumped 18 cm off it)
	play(c, best_entry(*cur->d, t, *c.d, 0.0, c.d->len, &last_entry_cost), 0.25f);
	align_full = false;
	yaw0 = yaw;
	sneak_off = wrapc(yaw_of(want) - (yaw + yaw_of(level(tv))));   // how far its travel is off the wall: turned out over its first steps
	sneak_turned = 0.0f;
	cv_dir = p_dir; n_sneaks++;
}

void Motor::cover_step(float p_dt, const Intent &p_in, Vector3 &r_vel) {
	cv_t += p_dt;
	const Vector3 dir = level(p_in.dir);
	const Vector3 left = UP.cross(cv_n);
	// out: asked, or pushed away from the wall a while
	if ((p_in.cover && cv_t > 0.4f) || (dir.dot(cv_n) > 0.7f && cv_t > 0.5f)) {
		const Clip &c = cv_out[cv_tall ? 1 : 0];
		if (c.ok()) { root_start(c, 0.0, 0.25f, yaw, nullptr, true); st = COVER_OUT; return; }
	}
	// along the wall: the stick's share along it; stopped where the wall ends (40 cm ahead of the body, no wall)
	const float s = (float)dir.dot(left);
	int want = std::fabs(s) > 0.3f ? (s > 0.0f ? 1 : -1) : 0;
	if (want != 0 && cover_dist(host->position() + left * (0.85f * want)) < 0.0f) want = 0;
	if (cv_dir != 0 && want == -cv_dir) want = 0;   // (a reversal through the idle: sneak into sneak turned the figure 20 degrees under a planted foot)   // (the stop's stride and hand-over run on up to half a metre)
	// (let go: the sneak runs on, at most half a stride, to the moment most like the cover idle's stance - switched
	// mid-stride, a planted foot slid 30 cm)
	if (want == 0 && cv_dir != 0) {
		const Clip &ci = cv_idle[cv_tall ? 1 : 0];
		double best_w = 0.0; float best_c = 1e30f;
		for (double w = 0.0; w <= std::min(0.5, cur->d->len) + 1e-6; w += 1.0 / 30.0) {
			float c = 0.0f;
			best_entry(*cur->d, t + w * rate, *ci.d, 0.0, std::min(ci.d->len, 1.0), &c);
			c += 0.05f * (float)w;
			if (c < best_c) { best_c = c; best_w = w; }
		}
		if (best_w >= 0.5 / 60.0 && cover_dist(host->position() + left * (0.3f * cv_dir)) > 0.0f) want = cv_dir;
	}
	if (want != cv_dir) {
		if (want == 0) {
			cv_dir = 0;
			align_full = true; face_only = true;
			play(cv_idle[cv_tall ? 1 : 0], best_entry(*cur->d, t, *cv_idle[cv_tall ? 1 : 0].d, 0.0, cv_idle[cv_tall ? 1 : 0].d->len, &last_entry_cost), 0.3f);
			align_full = false;
		} else cover_sneak(want);
	}
	advance(p_dt);
	speed = 0.0f;
	if (cv_dir != 0) {
		// (turned onto the drawn hips its travel ran 15 degrees off the wall - festive's cover idle and sneaks were
		// captured at different hip angles; projected onto the wall, a planted foot drifted 30 cm: the figure turns till
		// the sneak's own travel runs along it, 6 per second)
		const float k = (sneak_off - sneak_turned) * std::min(1.0f, 6.0f * p_dt);
		yaw += k; yaw0 += k; sneak_turned += k;
		const Vector3 v = Basis(UP, yaw).xform(cur->d->root_v.empty() ? Vector3() : cur->d->root_vel(t)) * rate;
		r_vel = left * (float)v.dot(left);   // (along the wall only)
		dbg_v = r_vel; dbg_t = (float)t;
		speed = (float)r_vel.length();
	}
	// held at the wall's distance
	const float d = cover_dist(host->position());
	last_gap = d;
	if (d > 0.0f) host->shift(-cv_n * clampc((d - (cv_tall ? cover_d_tall : cover_d_low)) * std::min(1.0f, 6.0f * p_dt), -0.005f, 0.005f));
}
