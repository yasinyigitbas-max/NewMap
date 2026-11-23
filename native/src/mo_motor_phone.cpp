// mo::Motor: THE PHONE (Yasin, 24 Nov: "walking text whenever we open the phone, and standing talk and walking talk when
// we take a call, we shouldnt be able to run while on a phone call"). Clips from his library (yl/): Texting_While_Standing
// (23.6 s: the phone raised in both hands 0-2.2 s, texting 2.2-20.8 s, lowered 20.8-23.5 s), Texting_And_Walking_one_hand
// (a 3.3 s walking loop, the phone in the right hand), Talking_On_A_Cell_Phone (37.2 s: taken out and dialled 0-4.3 s, at
// the right ear 4.5-33.5 s, put away 34-37.2 s).
// They play as an UPPER-BODY LAYER (MoLayer) over whatever the legs play - the idle, walks, starts, stops, turns, a seat:
// texting - the spine in part, the head, both arms; a call - standing, the same (its left hand talks), walking, the right
// arm and the head only (the left arm swings with the walk). Out at a walk at most.
#include "mo_motor.h"

#include "city_ped.h"
#include "mo_inertial.h"
#include "mo_layer.h"
#include "mo_limbs.h"

#include <algorithm>
#include <cmath>

using namespace godot;
using namespace godot::mo;

namespace {
struct Seg { double in0, in1, loop0, loop1, out0, out1; };
const Seg TEXT = { 0.0, 2.2, 2.2, 20.8, 20.8, 23.5 };
const Seg CALL = { 0.0, 4.3, 4.5, 33.5, 34.0, 37.2 };
} // namespace

void Motor::load_phone() {
	ph_text = load("yl/Texting_While_Standing"); ph_text_walk = load("yl/Texting_And_Walking_one_hand"); ph_call = load("yl/Talking_On_A_Cell_Phone");
}

void Motor::phone_step(float p_dt, const Intent &p_in) {
	if (!layer) return;
	const int want = (p_in.phone == 1 && ph_text.ok()) ? 1 : ((p_in.phone == 2 && ph_call.ok()) ? 2 : 0);
	const Seg &S = ph_kind == 2 ? CALL : TEXT;
	// take it out / put it away / change from texting to a call (away first, then out again)
	if (ph_phase == 0 && want != 0) { ph_kind = want; ph_phase = 1; ph_t = (want == 2 ? CALL : TEXT).in0; n_phone++; }
	else if ((ph_phase == 1 || ph_phase == 2) && want != ph_kind) { ph_phase = 3; ph_t = std::max(S.out0, ph_phase == 1 ? S.out0 + (S.in1 - ph_t) * 0.0 : S.out0); if (inert) inert->inertialize(0.35f); }
	if (ph_phase == 0) { ph_w = std::max(0.0f, ph_w - p_dt / 0.25f); layer->weight = ph_w; ph_visible = false; if (limbs) { limbs->hand_prop_on = false; if (limbs->ear_w > 0.0f) { limbs->ear_w = 0.0f; limbs->hand_w[1] = 0.0f; } } return; }
	const Seg &G = ph_kind == 2 ? CALL : TEXT;
	ph_t += p_dt;
	if (ph_phase == 1 && ph_t >= G.in1) { ph_phase = 2; ph_t = G.loop0; }
	if (ph_phase == 2 && ph_t >= G.loop1) { ph_t = G.loop0; if (inert) inert->inertialize(0.5f); }   // (its long middle again: the jump smoothed)
	if (ph_phase == 3 && ph_t >= G.out1) { ph_phase = 0; ph_kind = 0; }
	ph_w = std::min(1.0f, ph_w + p_dt / 0.25f);
	// walking texting: the walking take's own arms and head (a standing take's on a walk held the phone too still)
	const bool moving = speed > 0.3f && st != SIT && st != SIT_IN && st != SIT_OUT;
	if (moving != ph_walking) { ph_walking = moving; if (inert) inert->inertialize(0.35f); }
	if (ph_kind == 1 && ph_phase == 2 && moving && ph_text_walk.ok()) {
		layer->set_layer(ph_text_walk.a, 1);
		layer->t = std::fmod(clip_time() * 0.0 + ph_t, ph_text_walk.d->len);
	} else {
		layer->set_layer((ph_kind == 2 ? ph_call : ph_text).a, (ph_kind == 2 && moving) ? 2 : 1);
		layer->t = ph_t;
	}
	layer->weight = ph_phase == 0 ? 0.0f : ph_w;
	// in his hand from when it comes out (0.8 s in) until it is put away
	ph_visible = (ph_phase == 1 && ph_t > G.in0 + 0.8) || ph_phase == 2 || (ph_phase == 3 && ph_t < G.out1 - 0.8);
	if (limbs) {
		limbs->hand_prop_on = ph_visible;
		limbs->hand_prop_both = ph_kind == 1 && !ph_walking;   // (texting standing / seated: both hands; walking: the one-hand take)
		// (a call held: the right hand at the ear - eased in after it is dialled, out as it is put away)
		const float ew = ph_kind == 2 ? (ph_phase == 2 ? 1.0f : (ph_phase == 1 ? (float)std::min(1.0, std::max(0.0, (ph_t - (G.in1 - 0.4)) / 0.4)) : (float)std::min(1.0, std::max(0.0, (G.out0 + 0.8 - ph_t) / 0.8)))) : 0.0f;
		limbs->ear_w = ew;
		if (ew <= 0.0f && ph_kind == 2) limbs->hand_w[1] = 0.0f;
	}
}

void Motor::set_hand_prop(Node3D *p_prop, const Transform3D &p_off) {
	if (!limbs) return;
	limbs->hand_prop = p_prop; limbs->hand_prop_off = p_off;
}
