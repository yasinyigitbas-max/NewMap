// mo::Motor: SITTING (Yasin, 24 Nov: "add sitting animations and phone animations in"). The clips are from his library
// (yl/, tools/people/make_ylib.gd): Stand_To_Sit (his back to the seat, the hips 40 cm back and down to 0.49 m: its seat
// about 0.42 m high), Sitting_Idle (4.3 s loop), Sitting_Idle_1 (10.9 s: the gesture between), Sit_To_Stand.
// The seat is given (Intent.seat: the middle of its top; seat_yaw: the way he faces on it) - by the game's benches and
// chairs, or an NPC's mind. He walks to the spot in front of it (the clip's own 40 cm), turns his back to it, sits -
// the clip's hips warped onto the seat while he goes down, its floor raised or lowered so they land on its real height -
// sits (two loops of the idle, then the gesture, as standing), and stands when the sit is let go or the stick pushed away
// from the seat.
#include "mo_motor.h"
#include "rig_names.h"
#include <godot_cpp/classes/skeleton3d.hpp>

#include "city_ped.h"
#include "mo_inertial.h"
#include "mo_limbs.h"

#include <algorithm>
#include <cmath>

using namespace godot;
using namespace godot::mo;

namespace {
const Vector3 UP(0, 1, 0);
Vector3 lvl(const Vector3 &v) { return Vector3(v.x, 0.0f, v.z); }
Vector3 fwd_of(float y) { return Vector3(std::sin(y), 0.0f, std::cos(y)); }
float wrapf(float a) { return std::remainder(a, 6.2831853f); }
const float SEAT_OVER = 0.07f;   // (the hips joint sits 7 cm over the seat's top)
} // namespace

void Motor::load_sit() {
	si_in = load("yl/Stand_To_Sit"); si_idle = load("yl/Sitting_Idle"); si_out = load("yl/sit_Stand_Up");   // (not Sit_To_Stand: its hips leap 13 cm forward-up in one frame at 1.03 s)
	// the gestures between (chair sits all - Sitting_Idle_1 is sat on the floor, its hips 12 cm up: for the ground later)
	n_si_gest = 0;
	for (const char *n : { "yl/Sitting_talking", "yl/Sitting_Disapproval", "yl/Sitting_Disbelief" }) { Clip c = load(n); if (c.ok()) si_gest[n_si_gest++] = c; }
}

// the spot to stand on before sitting: the seat's middle, as far in front of it as the clip's hips travel back
bool Motor::sit_approach(const Intent &p_in, Vector3 &r_dir, float &r_speed) {
	if (!si_in.ok() || !si_idle.ok() || !si_out.ok() || !host) return false;
	const Frame f0 = si_in.d->lerp(0.0), f1 = si_in.d->lerp(si_in.d->len);
	const float back = (float)(f0.hips.z - f1.hips.z);   // (0.4 m)
	const Vector3 spot = lvl(p_in.seat) + fwd_of(p_in.seat_yaw) * back;
	Vector3 to = spot - lvl(host->position());
	const float dist = (float)to.length();
	// (near enough: he stands, and the sit's own warp takes up the rest - its starts and stops have their own steps, aimed at
	// a 12 cm spot he walked round it)
	if (dist < 0.6f) { r_dir = Vector3(); return true; }
	r_dir = to / dist * std::min(1.0f, dist / 0.6f);   // (slowing in the last 60 cm)
	r_speed = std::min(r_speed, 1.3f);                    // (walked to, not run)
	return false;
}

void Motor::sit_start(const Intent &p_in) {
	if (limbs) { limbs->lock_on = false; limbs->unlock_all(); }
	sit_yaw = p_in.seat_yaw; sit_ground = (float)host->position().y;
	// (its end hips over the seat's middle - the warp over its first 70 %)
	const Vector3 end = lvl(p_in.seat);
	root_start(si_in, 0.0, 0.3f, sit_yaw, &end, false);
	rp.c = &si_in;
	// (going down: its floor moved so its seated hips are at the real seat's height)
	const Frame f1 = si_in.d->lerp(si_in.d->len);
	double t_down = 0.0, t_sat = si_in.d->len;
	const ClipData &D = *si_in.d;
	for (int k = 0; k < (int)D.f.size(); k++) if ((float)D.f[k].hips.y < (float)D.f[0].hips.y - 0.04f) { t_down = k / 30.0; break; }
	for (int k = (int)D.f.size() - 1; k > 0; k--) if ((float)D.f[k].hips.y > (float)f1.hips.y + 0.01f) { t_sat = (k + 1) / 30.0; break; }
	rp.vy_on = true;
	rp.ay_from = sit_ground;
	// (the hip JOINTS 7 cm over the seat: on the old figure its pelvis bone sits at them; the player v3's (standard skeleton)
	// sits 9.3 cm above them - "the pelvis 7 cm over" sat him 9 cm high, his feet 5.7 cm off the ground)
	float pel_over = 0.0f;
	if (Skeleton3D *sk = fig->skeleton()) {
		const int p = rig::find(sk, "Bip01_Pelvis"), l = rig::find(sk, "Bip01_L_Thigh"), r = rig::find(sk, "Bip01_R_Thigh");
		if (p >= 0 && l >= 0 && r >= 0) {
			const Transform3D X = sk->get_global_transform();
			pel_over = (float)(X.xform(sk->get_bone_global_rest(p).origin).y - (X.xform(sk->get_bone_global_rest(l).origin).y + X.xform(sk->get_bone_global_rest(r).origin).y) * 0.5);
		}
	}
	rp.ay_to = (float)p_in.seat.y + SEAT_OVER + pel_over - (float)f1.hips.y;
	rp.vy_t0 = t_down; rp.vy_t1 = std::max(t_sat, t_down + 0.2);
	rp.a_from.y = rp.ay_from; rp.a_to.y = rp.ay_to;
	fig->set_global_transform(Transform3D(Basis(UP, rp.yaw), root_anchor(0.0)));
	st = SIT_IN; n_sits++;
}

// seated: the figure held where the sit left it (the anchor at its end), the body on the seat
void Motor::place_sit() {
	// (the idle's own hips where the sit left them: the sit ends with its hips 40 cm behind its start, the idle's are at its
	// origin - on the sit's anchor the hips jumped 43 cm)
	const Frame fe = si_in.d->lerp(si_in.d->len), fi = si_idle.d->lerp(0.0);
	sit_A = root_anchor(si_in.d->len) + Basis(UP, sit_yaw).xform(lvl(fe.hips) - lvl(fi.hips));
	const Vector3 h = sit_A + Basis(UP, sit_yaw).xform(lvl(fi.hips));
	host->teleport(Vector3(h.x, sit_ground, h.z));   // (the body under his hips, on the ground: the camera holds)
	fig->set_global_transform(Transform3D(Basis(UP, sit_yaw), sit_A));   // (after the body: the figure is its child)
	speed = 0.0f; yaw = sit_yaw;
}

void Motor::sit_step(float p_dt, const Intent &p_in) {
	sit_t += p_dt;
	advance(p_dt);
	// up: the sit let go, or the stick pushed away from the seat
	const Vector3 dir = lvl(p_in.dir);
	if (sit_t > 0.6f && (!p_in.sit || (dir.length() > 0.5f && dir.normalized().dot(fwd_of(sit_yaw)) > 0.3f))) { sit_out(); return; }
	// two loops of the idle, then a gesture at random (never the same twice running), and back - as standing
	if (!sit_gesture && n_si_gest > 0 && sit_t >= 2.0f * (float)si_idle.d->len) {
		int k = (int)(rnd() * n_si_gest) % n_si_gest; if (k == si_last && n_si_gest > 1) k = (k + 1) % n_si_gest;
		si_last = k; si_cur = k; sit_gesture = true; no_align = true; play(si_gest[k], 0.0, 0.5f);
	} else if (sit_gesture && t >= cur->d->len - 0.02) {
		sit_gesture = false; si_cur = -1; sit_t = 0.0f; no_align = true; play(si_idle, 0.0, 0.5f);
	}
	// (each take's own hips on the seat: they were taken on seats 49 to 68 cm high)
	Vector3 off;
	if (sit_gesture && si_cur >= 0) {
		const Frame fi = si_idle.d->lerp(0.0), f2 = si_gest[si_cur].d->lerp(0.0);
		off = Basis(UP, sit_yaw).xform(lvl(fi.hips) - lvl(f2.hips)) + Vector3(0, (float)(fi.hips.y - f2.hips.y), 0);
	}
	fig->set_global_transform(Transform3D(Basis(UP, sit_yaw), sit_A + off));
	if (limbs) { const Frame fr = cur->d->lerp(t); limbs->lock_on = true; limbs->may_step = false; limbs->drop_max = 0.0f; limbs->down[0] = fr.down[0]; limbs->down[1] = fr.down[1]; }
	if (host) ground_feet(*host);
}

void Motor::sit_out() {
	if (limbs) { limbs->lock_on = false; limbs->unlock_all(); }
	rp = RootPlay();
	rp.c = &si_out; rp.yaw = sit_yaw; rp.t0 = 0.0; rp.t_warp = si_out.d->len;
	// (its own seated hips where the idle's are: taken on a 60 cm seat, its hips 18 cm over the idle's)
	const Frame fi = si_idle.d->lerp(0.0), fo = si_out.d->lerp(0.0);
	rp.a_from = sit_A + Basis(UP, sit_yaw).xform(lvl(fi.hips) - lvl(fo.hips)) + Vector3(0, (float)(fi.hips.y - fo.hips.y), 0);
	rp.a_to = rp.a_from;
	// (up: its floor back from the seat's to the ground while he rises)
	const ClipData &D = *si_out.d;
	double t_up0 = 0.0, t_up1 = D.len;
	for (int k = 0; k < (int)D.f.size(); k++) if ((float)D.f[k].hips.y > (float)D.f[0].hips.y + 0.04f) { t_up0 = k / 30.0; break; }
	for (int k = 0; k < (int)D.f.size(); k++) if ((float)D.f[k].hips.y > (float)D.f[D.f.size() - 1].hips.y - 0.02f) { t_up1 = k / 30.0; break; }
	rp.vy_on = true; rp.ay_from = (float)rp.a_from.y; rp.ay_to = sit_ground;
	sit_up_at = t_up1 + 0.3;   // (up: on from there - the take stands on a while)
	rp.vy_t0 = std::max(0.0, t_up0 - 0.1); rp.vy_t1 = std::max(t_up1, t_up0 + 0.2);
	yaw = sit_yaw; yaw0 = sit_yaw; turn_k = 1.0f; rate = 1.0f;
	no_align = true;
	play(si_out, 0.0, 0.35f);
	fig->set_global_transform(Transform3D(Basis(UP, rp.yaw), root_anchor(0.0)));
	st = SIT_OUT;
}
