// mo::Motor's traversal: vaults and climbs (see mo_motor.h "TRAVERSAL"; docs/ANIMATION_PLAN.md step 3).
// Yasin, 22 Nov: "hands should hold edges of things when we interact with them like when we vault, character shouldnt
// jump to the sky after initiating climbs".
// The clips are festive's traversal library ("ptrav": the Mixamo takes, their travel in the hips). Each move:
//  - starts at the moment of its clip whose own distance to its hand contact is the distance to the real edge (so the
//    warp is small), the figure anchored where his hips are;
//  - is WARPED: the anchor shifts so the clip's hand contact lands on the real edge - level over the approach, in
//    height only from just before the take-off (feet off the ground) to the contact; a vault comes down to the real
//    ground beyond after the hand lets go;
//  - has the HANDS PINNED during the clip's own contact windows (where its hand is still and up at the edge), on the
//    real top, eased in and out;
//  - moves the body with the clip's hips (the capsule put there; the clip owns the motion), and hands over to the
//    locomotion at its end, standing on the top or beyond.
#include "mo_motor.h"
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include "city_ped.h"
#include "mo_inertial.h"
#include "mo_limbs.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>

using namespace godot;
using namespace godot::mo;

namespace {
const Vector3 UP(0, 1, 0);
float clampf(float x, float a, float b) { return std::min(std::max(x, a), b); }
float sstep(double a, double b, double x) {
	if (b <= a) return x >= b ? 1.0f : 0.0f;
	const float u = clampf((float)((x - a) / (b - a)), 0.0f, 1.0f);
	return u * u * (3.0f - 2.0f * u);
}
Vector3 level(const Vector3 &v) { return Vector3(v.x, 0.0f, v.z); }
} // namespace

// The anchor (where the figure stands) at clip time t: the start's, plus the warp as far as its windows have come
Vector3 Motor::trav_anchor(double p_t) const {
	Vector3 a = tr.anchor0;
	const Vector3 dxz = level(tr.delta);
	a += dxz * sstep(tr.t0, tr.tw, p_t);   // (level: over the approach)
	float dy = (float)tr.delta.y * sstep(tr.ty0, tr.ty1, p_t);
	if (tr.vault && p_t > tr.he) dy += (tr.land_dy - (float)tr.delta.y) * sstep(tr.he, tr.land_t, p_t);   // (down to the ground beyond)
	a.y += dy;
	return a;
}

// AHEAD, going the way he faces: a face, its top, how deep it is, the ground beyond: a vault or a climb, if one fits
bool Motor::trav_probe(const Vector3 &p_dir, float p_speed) {
	if (!host || !c_low.ok()) return false;
	const Vector3 p = host->position();
	const Vector3 dir = level(p_dir).normalized();
	const bool running = p_speed > 2.0f;
	const float look = running ? 2.6f : 1.5f;
	Vector3 face, fn; bool has = false;
	for (float hgt : { 0.35f, 0.75f }) {
		Vector3 hp, hn;
		if (host->ray(p + Vector3(0, hgt, 0), p + Vector3(0, hgt, 0) + dir * look, hp, hn) && hn.dot(dir) < -0.6f && std::fabs((float)hn.y) < 0.5f) {
			if (!has || (hp - p).length() < (face - p).length()) { face = hp; fn = level(hn).normalized(); has = true; }
		}
	}
	if (!has) return false;
	Vector3 top, tn;
	const Vector3 over = Vector3(face.x, 0, face.z) - fn * 0.08f;
	if (!host->ray(Vector3(over.x, p.y + 2.8f, over.z), Vector3(over.x, p.y + 0.2f, over.z), top, tn) || tn.y < 0.7f) return false;
	const float h = (float)(top.y - p.y);
	if (h < 0.55f || h > 2.1f) return false;   // (lower: a step or the old low climb; higher: not yet)
	// how deep: rays down past the face until the ground is lower than the top
	float depth = 9.0f; float land_y = (float)p.y;
	for (float a = 0.12f; a <= 1.6f; a += 0.1f) {
		const Vector3 q = Vector3(face.x, 0, face.z) - fn * a;
		Vector3 hp, hn;
		const bool hit = host->ray(Vector3(q.x, top.y + 0.3f, q.z), Vector3(q.x, p.y - 1.5f, q.z), hp, hn);
		if (!hit || hp.y < top.y - 0.15f) { depth = a - 0.05f; break; }
	}
	const bool thin = depth < 0.7f;
	if (thin) {
		if (h > 1.25f) return false;
		const Vector3 q = Vector3(face.x, 0, face.z) - fn * (depth + 0.7f);
		Vector3 hp, hn;
		if (!host->ray(Vector3(q.x, top.y + 0.3f, q.z), Vector3(q.x, p.y - 1.5f, q.z), hp, hn)) return false;
		land_y = (float)hp.y;
		if (!host->room_at(hp + Vector3(0, 0.03f, 0))) return false;
		const Clip &c = running && v_run.ok() ? v_run : v_walk;
		return trav_start(c, face, fn, (float)top.y, land_y, true);
	}
	// up onto it: room to stand on the top
	const Vector3 on = Vector3(face.x, top.y + 0.03f, face.z) - fn * 0.45f;
	if (!host->room_at(on)) return false;
	// (Yasin, 23 Nov: "remove all the double climbs"): up to 1.15 m the running jump climb; to 1.75 m a pull-up from a
	// braced hang to a crouch on the top, then up; higher the jump up to a hang and the climb from it; run at from 1.6 m,
	// the sprint up the wall
	if (h <= 1.15f) return trav_start(c_low, face, fn, (float)top.y, (float)top.y, false);
	if (running && h >= 1.6f && c_mid_run.ok()) return trav_start(c_mid_run, face, fn, (float)top.y, (float)top.y, false);
	if (h <= 1.75f && c_braced.ok() && cr_out.ok()) return trav_start(c_braced, face, fn, (float)top.y, (float)top.y, false, false, nullptr, 1);
	// (Yasin, 24 Nov, the 2 m climb "sinking into the shape": Stand_To_Freehang was taken hanging from a bar - its body
	// swings 18-25 cm past its hands, into a wall; Climbing_Single is a wall's climb, its body behind its hands throughout)
	if (c_mid.ok()) return trav_start(c_mid, face, fn, (float)top.y, (float)top.y, false);
	return false;
}

bool Motor::trav_start(const Clip &p_c, const Vector3 &p_face, const Vector3 &p_n, float p_top_y, float p_land_y, bool p_vault, bool p_chain, const Clip *p_then, int p_after) {
	if (!p_c.ok()) return false;
	const ClipData &D = *p_c.d;
	const int n = (int)D.f.size();
	// THE CONTACT: the moment the hands are most still, up at the edge (over the hips' height less 0.35 m), while the
	// body moves: its time, the hand, its place (figure frame)
	int kc = -1, hc = 0; float best = 1e9f;
	// (Climbing_Single goes hand over hand up the wall: its grip on the TOP is its highest - on his body the stillest
	// hand came at 0.5 s, a hold half way up, and no start was ever near enough)
	float hand_top = -1e9f;
	if (&p_c == &c_mid) for (const Frame &F : D.f) hand_top = std::max(hand_top, (float)std::max(F.hand[0].y, F.hand[1].y));
	auto reach_ok = [&](const Frame &F, int s) {
		if (F.hips_v.length() < (p_chain ? 0.0f : 0.3f)) return false;
		if ((float)F.hand[s].y < hand_top - 0.12f) return false;
		if (F.hand[s].y < F.hips.y - hips_lift - 0.35f) return false;
		const Vector3 d = F.hand[s] - F.hips;
		const float ahead = (float)(d.x * std::sin(F.face) + d.z * std::cos(F.face));
		return !(ahead < 0.12f && (float)F.hand[s].y < (float)F.hips.y - hips_lift + 0.30f);
	};
	for (int k = 0; k < n; k++) {
		const Frame &F = D.f[k];
		if (F.hips_v.length() < (p_chain ? 0.0f : 0.3f)) continue;
		for (int s = 0; s < 2; s++) {
			if (!reach_ok(F, s)) continue;
			if (F.hand[s].y < F.hips.y - hips_lift - 0.35f) continue;   // (from the hip joints: hips_lift)
			{   // (a grip is a REACH: the hand 12 cm or more ahead of the hips the way he faces, or 30 cm over them - a running
				// arm's still moment at its swing's end passed for the contact: his Running_Jump_Climb took 0.07 s, the hands
				// never on the box and the body shoved 55 cm across it)
				const Vector3 d = F.hand[s] - F.hips;
				const float ahead = (float)(d.x * std::sin(F.face) + d.z * std::cos(F.face));
				if (ahead < 0.12f && (float)F.hand[s].y < (float)F.hips.y - hips_lift + 0.30f) continue;
			}
			const float sp = (float)F.hand_v[s].length();
			if (sp < best) { best = sp; kc = k; hc = s; }
		}
	}
	if (kc < 0 || best > 1.0f) return false;
	{   // (the FIRST time a reaching hand settles, not the stillest of all: his hands lie on the top longer while the body
		// passes over them - the stillest came at 1.57 s of Sprint_To_Wall_Climb, the old figure's at 0.8, and the warp
		// put his hands 32 cm off the edge)
		// (not Climbing_Single: hand over hand up the wall, its grip on the top is its LAST reach - taken at the first, the
		// 2 m wall found no start)
		const float near = std::max(best * 1.5f, best + 0.25f);
		for (int k = 0; k < kc && &p_c != &c_mid; k++) {
			bool hit = false;
			for (int s = 0; s < 2 && !hit; s++) if (reach_ok(D.f[k], s) && (float)D.f[k].hand_v[s].length() < near) { kc = k; hc = s; hit = true; }
			if (hit) break;
		}
	}
	const double tc = kc / FPS;
	const Vector3 C = D.f[kc].hand[hc];
	const float clip_top = (float)C.y - 0.05f;   // (the palm on the top: the wrist about 5 cm over it)
	const Trav was = tr;   // (kept if this move does not start)
	tr = Trav();
	// each hand's window: around its own stillest moment near the contact, while it stays still and up there
	for (int s = 0; s < 2; s++) {
		int km = -1; float bm = 1e9f;
		for (int k = std::max(0, kc - (int)(0.5 * FPS)); k < std::min(n, kc + (int)(0.6 * FPS)); k++) {
			const Frame &F = D.f[k];
			if (std::fabs((float)F.hand[s].y - (float)C.y) > 0.15f) continue;
			const float sp = (float)F.hand_v[s].length();
			if (sp < bm) { bm = sp; km = k; }
		}
		tr.hs[s] = tr.hend[s] = -1.0;
		if (km < 0 || bm > 1.2f) continue;
		// in contact while the hand stays within 4 cm of where it is stillest (a planted hand does not move while the body
		// goes over it; by "slow" alone the window began with the hand still 10 cm away, out of the arm's reach)
		const Vector3 spot = D.f[km].hand[s];
		int a = km, b = km;
		while (a > 0 && (D.f[a - 1].hand[s] - spot).length() < 0.04f) a--;
		while (b < n - 1 && (D.f[b + 1].hand[s] - spot).length() < 0.04f) b++;
		if (b - a < 3) continue;   // (a touch shorter than 0.1 s is not a hold)
		tr.hs[s] = a / FPS; tr.hend[s] = b / FPS; tr.hk[s] = km / FPS;
	}
	// THE START: the moment whose own distance (hips to the contact, along the way) is his distance to the edge
	const Vector3 p = host->position();
	const Vector3 fwd = -p_n;   // (into the obstacle)
	const float yaw_m = std::atan2((float)fwd.x, (float)fwd.z);
	const Basis R(UP, yaw_m);
	const Vector3 edge = Vector3(p_face.x, p_top_y, p_face.z);
	const float dist = (float)level(edge - p).dot(fwd);   // his feet (the body) to the edge
	double t0 = 0.0; float best_e = 1e9f;
	if (p_chain) best_e = 0.0f;   // (the second move on an edge: from its start, where the first left him)
	else for (int k = 0; k <= std::max(0, kc - (int)(0.35 * FPS)); k++) {
		const float clip_dist = (float)(C.z - D.f[k].hips.z);
		const float e = std::fabs(clip_dist - dist);
		if (e < best_e) { best_e = e; t0 = k / FPS; }
	}
	if (OS::get_singleton()->get_environment("MO_TRAV_TRACE") != "") UtilityFunctions::print("TRAVSTART ", p_c.name, " dist ", dist, " best_e ", best_e, " t0 ", t0, " tc ", tc, " chain ", p_chain);
	if (best_e > (&p_c == &c_mid && !p_chain ? 0.2f : 0.45f)) { tr = was; return false; }   // (Climbing_Single from the ground: begun only once he is where its own steps up start, its warp small)   // (too far yet, or too close to fit it: walking on, the old moves)
	const Frame &F0 = D.f[(int)std::lround(t0 * FPS)];
	tr.c = &p_c; tr.t0 = t0; tr.tc = tc; tr.yaw = yaw_m; tr.edge_p = edge; tr.edge_n = p_n; tr.top_y = p_top_y; tr.start_y = (float)p.y; tr.vault = p_vault;
	tr.c_contact = C;
	tr.anchor0 = p - R.xform(Vector3(F0.hips.x, 0.0f, F0.hips.z));   // (the clip's hips over his body now)
	tr.anchor0.y = p.y;                                                 // (the clip's floor on his ground)
	{   // (a clip begun with its feet up - Climbing_Single starts on footholds 21 cm up - its feet on his ground)
		const float lo = std::min((float)F0.foot[0].y, (float)F0.foot[1].y) - 0.10f;
		if (!p_chain && &p_c == &c_mid && lo > 0.03f) tr.anchor0.y -= lo;
	}
	if (p_chain) {   // (its hips where the drawn hips are: the hang held)
		const Vector3 dh = fig->bone_world("Bip01_Pelvis");
		tr.anchor0 = dh - R.xform(F0.hips);
	}
	tr.then = p_then; tr.after = p_after;
	// the warp: the contact hand onto the edge (its own sideways place kept), its height onto the top
	const Vector3 c_world = tr.anchor0 + R.xform(C);
	Vector3 target = c_world;
	{
		const Vector3 side = R.xform(Vector3(1, 0, 0));
		const float lat = (float)(c_world - edge).dot(side);
		target = edge + side * lat - p_n * 0.06f;   // (the palm 6 cm in from the edge, on the top)
		target.y = p_top_y + ((float)C.y - clip_top);
	}
	tr.delta = target - c_world;
	// (the braced hang and the sprint up the wall: their knees bend into the wall - taken where it was thinner - 16-18 cm;
	// the body set back from it that much, the hands still on the edge by their IK)
	// (a standard-skeleton body - the player v3: his thighs and shins are thicker, his knees went 11 cm into the wall at
	// 0.16 - is set back the 11 cm more; the old figure's 0.16 as it was)
	// (his body's extra set back from the wall, m: tuned on his body - env MO_SET_BRACED / MO_SET_SPRINT to tune)
	static const float set_braced = OS::get_singleton()->get_environment("MO_SET_BRACED").is_empty() ? 0.08f : OS::get_singleton()->get_environment("MO_SET_BRACED").to_float();
	static const float set_sprint = OS::get_singleton()->get_environment("MO_SET_SPRINT").is_empty() ? 0.04f : OS::get_singleton()->get_environment("MO_SET_SPRINT").to_float();
	if (!p_vault && (&p_c == &c_braced || &p_c == &c_mid_run)) tr.delta += p_n * (0.16f + (hips_lift > 0.01f ? (&p_c == &c_braced ? set_braced : set_sprint) : 0.0f));   // (the sprint up the wall: 4 cm nearer for him - at 0.16 his hands hung 7 cm off the edge)
	// (the braced hang: hung where the take hangs, his hands came 8 cm OVER the edge - his reach from the hang is longer
	// for his size than the old figure's; the body 8 cm lower for him: hands 1.2 cm off)
	static const float hang_up = OS::get_singleton()->get_environment("MO_HANG_UP").is_empty() ? -0.08f : OS::get_singleton()->get_environment("MO_HANG_UP").to_float();
	if (!p_vault && &p_c == &c_braced && hips_lift > 0.01f) tr.delta.y += hang_up;
	if (!p_vault && &p_c == &c_mid && !p_chain) tr.delta += p_n * (0.06f + (hips_lift > 0.01f ? 0.10f : 0.0f));   // (+10 cm for the player v3: his feet went 9.9 cm into the wall on its footholds)   // (Climbing_Single: a knee 10 cm in at the mantle - 6 cm back enough once its rise was spread, 10 left the hands 8 cm short)
	// the warp is all done by the first hand touch (still ramping as a hand came down on the rail, the body was too high
	// for the arm: the hand hung 9-16 cm over the top)
	tr.tw = tc;
	for (int s = 0; s < 2; s++) if (tr.hs[s] >= 0.0) tr.tw = std::min(tr.tw, std::max(tr.hs[s] - 0.1, t0 + 0.1));
	tr.ty0 = std::max(t0, tr.tw - (&p_c == &c_mid ? 0.9 : 0.45));   // (Climbing_Single lifted from 21 cm under his ground: over 0.45 s the hips' rise popped 4 cm)
	// (the rise never shorter than 0.25 s - on past the hand's touch if need be, the hand held on the edge by its IK while
	// the body finishes rising: joined late, close to a 2 m wall, 40 cm went up in 0.1 s - a 3.9 cm pop, and the hand
	// eased in at the end of it 8 cm short, 25 Nov)
	tr.ty1 = std::max(tr.tw, tr.ty0 + 0.25);
	// the end: a vault where it lands (the clip's own landing, else 0.6 s after the hand lets go); a climb at its end
	const double he = std::max(tr.hend[0], tr.hend[1]);
	tr.he = he > 0.0 ? he : tc + 0.3;
	const float land_meta = p_c.meta("land_at", -1.0f);
	if (p_vault) {
		tr.land_t = land_meta > tr.he ? land_meta : tr.he + 0.6;
		tr.t_end = std::min(D.len, tr.land_t + 0.25);
		tr.land_dy = p_land_y - tr.start_y;
	} else {
		tr.land_t = D.len; tr.t_end = D.len;
	}
	tr.clip_clear = -1e9f;
	for (int k = (int)(t0 * FPS); k <= (int)(tr.t_end * FPS) && k < n; k++) tr.clip_clear = std::max(tr.clip_clear, (float)D.f[k].hips.y - clip_top);
	trav_warp = (float)tr.delta.length(); trav_top = p_top_y - (float)p.y;
	trav_hips_over = -1e9f; trav_hand_miss = 0.0f; trav_hand_dy = 0.0f; trav_wmax = 0.0f;
	last_trav = String(p_c.name);
	if (p_vault) n_vaults++; else n_climbs++;
	// the figure turns to face the obstacle square (the hand-over smooths it), the clip from t0
	yaw = yaw_m; yaw0 = yaw_m; turn_k = 1.0f; rate = 1.0f;
	if (limbs) { limbs->lock_on = false; limbs->unlock_all(); }
	play(p_c, t0, blend_step);
	st = TRAV;
	// placed in the same frame as the clip changes (a frame late, the hand-over had already been taken: the hips jumped
	// a metre)
	fig->set_global_transform(Transform3D(Basis(UP, tr.yaw), tr.anchor0));
	return true;
}

void Motor::trav_step(float p_dt) {
	advance(p_dt);
	const ClipData &D = *tr.c->d;
	const Basis R(UP, tr.yaw);
	const Vector3 A = trav_anchor(t);
	const Frame f = D.lerp(t);
	// the body follows the clip's hips; its feet on the clip's floor under them
	Vector3 body = A + R.xform(Vector3(f.hips.x, 0.0f, f.hips.z));
	body.y = A.y + std::max(0.0f, std::min((float)f.foot[0].y, (float)f.foot[1].y) - 0.10f);
	// (never over the top: in the mantle both feet tuck up and the body followed the lower one 73 cm over a 1.6 m wall -
	// the drawn figure is the clip's, the body is only for collision)
	body.y = std::min((float)body.y, tr.top_y + 0.02f);
	host->teleport(body);
	speed = 0.0f;
	// THE HANDS: pinned on the top in their windows (eased 0.1 s in and out), where the clip's hand meets the edge
	if (limbs) {
		for (int s = 0; s < 2; s++) {
			float w = 0.0f;
			// (eased in from the touch, over 0.08 s: full from the first frame of the touch, the arm was still 5 cm short)
			const double ease = tr.c == &c_mid ? 0.3 : 0.08;   // (Climbing_Single's hand comes up fast to its hold: full at once, it was 20 cm short for 2 frames)
			if (tr.hs[s] >= 0.0) w = sstep(tr.hs[s], tr.hs[s] + ease, t) * (1.0f - sstep(tr.hend[s], tr.hend[s] + 0.1, t));
			if (w > 0.001f && !tr.hand_set[s]) {
				// the hand's spot: where the warped clip puts it at its own stillest moment (not where it is as the pin
				// starts to ease in: still moving there, 10-20 cm short), on the top
				const double tk = tr.hk[s] >= 0.0 ? tr.hk[s] : t;
				Vector3 hw = trav_anchor(tk) + R.xform(D.lerp(tk).hand[s]);
				const float in = (float)(hw - tr.edge_p).dot(-tr.edge_n);
				if (in < 0.04f) hw += -tr.edge_n * (0.04f - in);   // (on the top, not off its edge)
				hw.y = tr.top_y + 0.05f;   // (the wrist 5 cm over the top: the palm on it)
				tr.hand_w[s] = hw; tr.hand_set[s] = true;
			}
			limbs->hand_w[s] = w; trav_wmax = std::max(trav_wmax, w);
			if (tr.hand_set[s]) limbs->hand_target[s] = tr.hand_w[s];
			if (w > 0.95f) {
				const Vector3 drawn = fig->bone_world(s == 0 ? "Bip01_L_Hand" : "Bip01_R_Hand");
				trav_hand_miss = std::max(trav_hand_miss, (float)(drawn - tr.hand_w[s]).length());
				trav_hand_dy = std::max(trav_hand_dy, std::fabs((float)drawn.y - (float)tr.hand_w[s].y));
			}
		}
	}
	// (tests) the hips over the top, against the clip's own
	if (!tr.vault || t < tr.he) trav_hips_over = std::max(trav_hips_over, (A.y + (float)f.hips.y - tr.top_y) - tr.clip_clear);
	fig->set_global_transform(Transform3D(Basis(UP, tr.yaw), A));
	// THE END: standing on the top / beyond, the locomotion takes him (the hand-over smooths the hips)
	if (t >= tr.t_end - 1e-3) {
		if (tr.then) {   // (the second move on the same edge, from here)
			const Clip *nx = tr.then;
			const Vector3 edge = tr.edge_p, en = tr.edge_n; const float top = tr.top_y;
			if (trav_start(*nx, edge, en, top, top, false, true, nullptr, 0)) return;
		}
		if (limbs) { limbs->hand_w[0] = limbs->hand_w[1] = 0.0f; }
		if (tr.after == 1) {   // (crouched on the top: up by the crouch's own clip)
			Vector3 g, gn;
			if (host->ray(body + Vector3(0, 0.6f, 0), body - Vector3(0, 0.8f, 0), g, gn)) host->teleport(Vector3(body.x, g.y + 0.01f, body.z));
			yaw = tr.yaw;
			draw_y = (float)host->position().y; draw_ok = true;
			to_stance(0);
			return;
		}
		Vector3 g, gn;
		if (host->ray(body + Vector3(0, 0.6f, 0), body - Vector3(0, 0.8f, 0), g, gn)) host->teleport(Vector3(body.x, g.y + 0.01f, body.z));
		yaw = tr.yaw;
		// (a vault ends crouched, the hips 20 cm under standing: a slower hand-over up into the stand; at 0.3 s the
		// hips' rise changed 4.6 cm a frame)
		to_idle(tr.vault ? 0.5f : blend_idle);
		place(*host);   // (the figure on the body in the same frame as the clip changes)
	}
}

Array Motor::trav_hands() const {
	Array a;
	for (int s = 0; s < 2; s++) { a.push_back(limbs ? limbs->hand_target[s] : Vector3()); a.push_back(limbs && st == TRAV ? limbs->hand_w[s] : 0.0f); }
	return a;
}
