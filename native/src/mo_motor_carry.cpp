// mo::Motor, step 6: carrying (docs/ANIMATION_PLAN.md; Yasin, 22 Nov: "picking objects ... different animation
// shuffles"). Festive's clips only (pact), none of its code.
//
// A BOX in both hands: Walking_Carry and Jogging_With_Box_a as loops (no carried start: the rate eased up from 0.45, and
// down to it on letting go, on to the stride most like the idle), the idle the held tail of Walk_Carry_Stop (3.0 s on,
// looped; its hips stand 1.4 m from the clip's origin: played in place by the clip's figure offset). The box is drawn
// where the clip's hands hold it (their middle, on a spring: a hand-over does not jump it), the same width in every
// clip, and the HANDS PINNED to its sides (MoLimbs' hand reach) so no clip's hands float off it or into it.
// A BRIEFCASE or a SHOPPING BAG in the right hand: Briefcase_Idle, Walk_With_Briefcase / Walking_With_Shopping_Bag; the
// bag hangs from the hand as drawn.
// What is drawn is the game's (CityPlayer draws a placeholder): the motor says where (carry_xf).
#include "mo_motor.h"

#include "city_ped.h"
#include "mo_limbs.h"

#include <algorithm>
#include <cmath>

using namespace godot;
using namespace godot::mo;

namespace {
const Vector3 UP(0, 1, 0);
float clampk(float x, float a, float b) { return std::min(std::max(x, a), b); }
} // namespace

void Motor::load_carry() {
	ca_walk = load("pact/Walking_Carry"); ca_jog = load("pact/Jogging_With_Box_a");
	ca_idle = load("pact/Walk_Carry_Stop");
	if (ca_idle.ok()) {
		ca_idle.lo = std::min(3.0, ca_idle.d->len * 0.6);
		const Frame f = ca_idle.d->lerp(ca_idle.lo);
		ca_idle.off = Vector3(f.hips.x, 0.0f, f.hips.z);
	}
	bg_idle = load("pact/Briefcase_Idle"); bg_walk = load("pact/Walk_With_Briefcase"); sb_walk = load("pact/Walking_With_Shopping_Bag");
	if (ca_walk.ok()) {   // the box's width: the carry walk's palms apart, on average
		float w = 0.0f; int m = 0;
		for (const Frame &f : ca_walk.d->f) { w += (float)(f.hand[0] - f.hand[1]).length(); m++; }
		if (m) box_w = std::max(0.30f, w / m - 0.06f);   // (the box between the hand bones less the palms)
	}
}

void Motor::to_carry_idle(float p_blend) {
	const Clip &c = carry == 1 ? ca_idle : bg_idle;
	if (!c.ok()) return;
	rate = 1.0f; turn_k = 1.0f;
	const double lo = c.lo;
	const double e = cur ? best_entry(*cur->d, t, *c.d, lo, std::min(c.d->len, lo + 1.5), &last_entry_cost) : lo;
	play(c, e, p_blend);
}

void Motor::carry_step(float p_dt, const Intent &p_in, float p_d, bool p_want, Vector3 &r_vel) {
	// put down: back to the plain stand / walk (the hands let go over 0.3 s)
	if (p_in.carry != carry) {
		carry = p_in.carry;
		if (carry == 0) {
			if (p_want) to_loop(pick_loop(std::max(speed, 0.8f), loop_i), blend_loop);
			else to_idle(0.35f);
			return;
		}
	}
	const bool box = carry == 1;
	const Clip &idle = box ? ca_idle : bg_idle;
	const Clip &walk = box ? (p_in.speed > 2.0f && ca_jog.ok() ? ca_jog : ca_walk) : (carry == 3 && sb_walk.ok() ? sb_walk : bg_walk);
	if (p_want) {
		if (cur != &walk) {
			const bool from_idle = cur == &idle;
			into_loop = true;
			face_only = from_idle;   // (the body stays: the idle's stance against a stride, the contact alignment jumped it 40 cm)
			play(walk, best_entry(*cur->d, t, *walk.d, 0.0, walk.d->len, &last_entry_cost), 0.3f);
			if (from_idle) {   // (from a stand at about 0.6 m/s whatever the loop's pace: a jog at 0.45 of its rate jumped 1.3 m/s)
				Vector3 sv; for (const Vector3 &v : walk.d->root_v) sv += v;
				const float vm = walk.d->root_v.empty() ? 1.0f : (float)sv.length() / walk.d->root_v.size();
				rate = clampk(0.6f / std::max(vm, 0.1f), 0.2f, 0.45f);
			}
		}
		yaw += clampk(p_d, -carry_turn_rate * p_dt, carry_turn_rate * p_dt);
		const float wl = std::min((float)p_in.dir.length(), 1.0f);
		// (no carried start: the loop's rate eased up from 0.45; and slowed into a sharp turn)
		const float want_rate = clampk(wl, 0.5f, 1.0f) * std::max(0.5f, std::cos(std::min(std::fabs(p_d), 1.5f)));
		rate = std::min(want_rate, rate + 2.0f * p_dt);
		advance(p_dt);
		r_vel = Basis(UP, yaw).xform(walk.d->root_v.empty() ? Vector3(0, 0, walk.ground_v) : walk.d->root_vel(t)) * rate;
		speed = (float)r_vel.length();
		return;
	}
	if (cur != &idle) {
		// let go: the loop runs on (its rate eased down, at most half a stride) to the moment most like the idle's stance
		double best_w = 0.0; float best_c = 1e30f;
		for (double w = 0.0; w <= std::min(0.5, cur->d->len) + 1e-6; w += 1.0 / 30.0) {
			float c = 0.0f;
			best_entry(*cur->d, t + w * rate, *idle.d, idle.lo, std::min(idle.d->len, idle.lo + 1.5), &c);
			c += 0.05f * (float)w;
			if (c < best_c) { best_c = c; best_w = w; }
		}
		rate = std::max(0.45f, rate - 2.0f * p_dt);
		if (best_w < 0.5 / 60.0 && rate <= 0.5f) to_carry_idle(0.35f);
		else {
			advance(p_dt);
			r_vel = Basis(UP, yaw).xform(cur->d->root_v.empty() ? Vector3() : cur->d->root_vel(t)) * rate;
			speed = (float)r_vel.length();
			return;
		}
	}
	// the idle: its held tail looped (a hand-over at the seam)
	if (cur == &idle && idle.lo > 0.0 && t + p_dt * rate >= idle.d->len - 1e-3) { play(idle, idle.lo, 0.5f); }
	advance(p_dt);
	speed = 0.0f;
}

Vector3 Motor::carry_hand_target(int s) const { return limbs ? limbs->hand_target[s & 1] : Vector3(); }

// the prop's place and the hands on it, every frame (also while letting go)
void Motor::carry_hands(float p_dt) {
	if (!limbs || !cur || !fig) return;
	const bool on = carry != 0 && st == CARRY;
	carry_w = clampk(carry_w + (on ? 1.0f : -1.0f) * p_dt / 0.3f, 0.0f, 1.0f);
	limbs->hold_w = carry_w;
	if (carry_w <= 0.0f && !on) { limbs->hold_kind = 0; hc_ok = false; carry_yaw_ok = false; return; }
	if (limbs->hold_kind != 0) carry_xf = limbs->hold_xf;   // (where it was drawn last frame: for tests; the thing itself is placed by MoLimbs)
	const Frame f = cur->d->lerp(t);
	const bool box = carry == 1 || (carry == 0 && carry_was_box);
	if (carry != 0) carry_was_box = carry == 1;
	// HOW IT IS HELD, from the hips: the clip's hands (their middle for the box, the right one for a bag) against the
	// clip's own hips, in his facing (a spring smooths the clip changes). WHERE is the drawn hips' - only a modifier sees
	// the drawn pose (MoLimbs: it places the thing and the hands in the same pass; read here, mid-step, the skeleton
	// holds the clip's raw pose, and at a hand-over its hips jumped 30 cm: the bag with them)
	Vector3 hl = (box ? (f.hand[0] + f.hand[1]) * 0.5f : f.hand[1]) - f.hips;
	if (box) {
		// (Yasin, 23 Nov: "both box and hands go into the body, neither should be able to do that"): the clip holds its
		// box close, the hands 20 cm in front of the hips - a box centred there was half inside the belly. Its back face
		// kept 2 cm off the belly (14 cm in front of the hips' middle), whatever the clip
		const float need = belly + box_d * 0.5f + 0.02f;
		if (hl.z < need) hl.z = need;
	}
	if (!hc_ok) { hc_l = hl; hc_v = Vector3(); hc_ok = true; }
	else if (p_dt > 0.0f) {
		const float w = box ? 14.0f : 18.0f;
		hc_v += (w * w * (hl - hc_l) - 2.0f * w * hc_v) * p_dt;
		hc_l += hc_v * p_dt;
	}
	// (its facing eased: a hand-over turns the facing at once, the drawn figure through the blend)
	if (!carry_yaw_ok) { carry_yaw = yaw; carry_yaw_ok = true; }
	else carry_yaw += std::remainder(yaw - carry_yaw, 6.2831853f) * std::min(1.0f, 10.0f * p_dt);
	limbs->hold_kind = box ? 1 : 2;
	limbs->hold_l = hc_l; limbs->hold_yaw = carry_yaw;
	limbs->box_w = box_w; limbs->box_d = box_d;
}

void Motor::set_prop(Node3D *p_node) { if (limbs) limbs->prop = p_node; }
