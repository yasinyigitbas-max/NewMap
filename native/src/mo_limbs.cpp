// MoLimbs: see mo_limbs.h.
#include "mo_limbs.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/variant/quaternion.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

namespace {
// the turn taking direction a onto direction b
Basis arc(const Vector3 &a, const Vector3 &b) {
	const Vector3 u = a.normalized(), v = b.normalized();
	const Vector3 c = u.cross(v);
	const float d = (float)u.dot(v);
	if (c.length_squared() < 1e-12f) return d > 0.0f ? Basis() : Basis(Vector3(1, 0, 0).cross(u).length_squared() > 1e-6f ? Vector3(1, 0, 0).cross(u).normalized() : Vector3(0, 1, 0), 3.14159265f);
	return Basis(Quaternion(u, v));
}
} // namespace

void MoLimbs::find_bones(Skeleton3D *sk) {
	const char *TH[2] = { "Bip01_L_Thigh", "Bip01_R_Thigh" }, *CA[2] = { "Bip01_L_Calf", "Bip01_R_Calf" }, *FT[2] = { "Bip01_L_Foot", "Bip01_R_Foot" };
	const char *UA[2] = { "Bip01_L_UpperArm", "Bip01_R_UpperArm" }, *FA[2] = { "Bip01_L_Forearm", "Bip01_R_Forearm" }, *HD[2] = { "Bip01_L_Hand", "Bip01_R_Hand" };
	for (int s = 0; s < 2; s++) {
		b_th[s] = sk->find_bone(TH[s]); b_ca[s] = sk->find_bone(CA[s]); b_ft[s] = sk->find_bone(FT[s]);
		b_ua[s] = sk->find_bone(UA[s]); b_fa[s] = sk->find_bone(FA[s]); b_hd[s] = sk->find_bone(HD[s]);
	}
	b_pel = sk->find_bone("Bip01_Pelvis"); b_head = sk->find_bone("Bip01_Head");
	b_spine[0] = sk->find_bone("Bip01_Spine"); b_spine[1] = sk->find_bone("Bip01_Spine1"); b_spine[2] = sk->find_bone("Bip01_Spine2"); b_neck = sk->find_bone("Bip01_Neck");
	b_fing[0] = sk->find_bone("Bip01_R_Finger0"); b_fing[1] = sk->find_bone("Bip01_R_Finger2"); b_lfing = sk->find_bone("Bip01_L_Finger2");
	found = true;
}

void MoLimbs::reach(Skeleton3D *sk, int a, int b, int c, const Vector3 &p_target, const Vector3 &p_pole) {
	if (a < 0 || b < 0 || c < 0) return;
	const Transform3D Ga = sk->get_bone_global_pose(a), Gb = sk->get_bone_global_pose(b), Gc = sk->get_bone_global_pose(c);
	const Vector3 pa = Ga.origin, pb = Gb.origin, pc = Gc.origin;
	const float la = (float)(pb - pa).length(), lb = (float)(pc - pb).length();
	if (la < 1e-4f || lb < 1e-4f) return;
	const Vector3 tv = p_target - pa;
	const float d = std::min(std::max((float)tv.length(), std::fabs(la - lb) + 1e-3f), la + lb - 1e-3f);
	const Vector3 u = tv.normalized();
	Vector3 v = p_pole - u * p_pole.dot(u);
	if (v.length_squared() < 1e-10f) v = (pb - pa) - u * (pb - pa).dot(u);
	if (v.length_squared() < 1e-10f) return;
	v.normalize();
	const float ca = std::min(std::max((la * la + d * d - lb * lb) / (2.0f * la * d), -1.0f), 1.0f);
	const Vector3 knee = pa + (u * ca + v * std::sqrt(std::max(0.0f, 1.0f - ca * ca))) * la;
	sk->set_bone_global_pose(a, Transform3D(arc(pb - pa, knee - pa) * Ga.basis, pa));
	const Transform3D Gb2 = sk->get_bone_global_pose(b), Gc2 = sk->get_bone_global_pose(c);
	sk->set_bone_global_pose(b, Transform3D(arc(Gc2.origin - Gb2.origin, pa + u * d - Gb2.origin) * Gb2.basis, Gb2.origin));
	const Transform3D Gc3 = sk->get_bone_global_pose(c);
	sk->set_bone_global_pose(c, Transform3D(Gc.basis, Gc3.origin));   // (the foot / hand keeps the clip's own turn)
}

// THE KNEE'S WAY (Yasin, 23 Nov: "knees shouldnt be able to bend backwards"): forward, the way he faces. The clip's own knee direction taken whole bent swinging and
// fitted legs 12-21 cm backwards on stairs and a run up 22 degrees: near straight, its bend is noise.
Vector3 MoLimbs::knee_pole(Skeleton3D *p_sk, const Transform3D &p_gi, const Vector3 &p_clip) const {
	// (the way the drawn hips face, not the figure's: a clip taken facing another way - the low cover's left sneak
	// faces 157 degrees off his own - had its knees bent backwards; Yasin, 24 Nov: "when you move left in the cover,
	// his legs turn backwards")
	(void)p_clip;
	const Vector3 up = p_gi.basis.xform(Vector3(0, 1, 0)).normalized();
	if (b_th[0] >= 0 && b_th[1] >= 0) {
		const Vector3 th = p_sk->get_bone_global_pose(b_th[0]).origin - p_sk->get_bone_global_pose(b_th[1]).origin;
		Vector3 f = th.cross(up);   // (left thigh - right thigh = his left; left x up = forward)
		f -= up * f.dot(up);
		const Vector3 fw = p_gi.basis.xform(fwd_w);
		// (only a clip turned well away from him: in his own walks and runs the hips swing 20-30 degrees a stride, and
		// following that tipped a knee back 4 cm on the stairs)
		if (f.length_squared() > 1e-8f && fw.length_squared() > 1e-10f && f.normalized().dot(fw.normalized()) < 0.5f) return f.normalized();
	}
	Vector3 f = p_gi.basis.xform(fwd_w);
	if (f.length_squared() < 1e-10f) return p_clip;
	return f.normalized();   // (even half the clip's sideways lean tipped a knee back 12 cm with the foot far ahead: forward only)
}

void MoLimbs::_process_modification_with_delta(double p_delta) {
	Skeleton3D *sk = get_skeleton();
	if (!sk) return;
	if (!found) find_bones(sk);
	// (time moves once a frame: the skeleton can be posed more than once in one)
	const uint64_t fr = Engine::get_singleton()->get_process_frames();
	if (p_delta > 0.0) dt_frame = (float)p_delta;
	const float dt = fr != frame_id ? dt_frame : 0.0f;
	frame_id = fr;
	const Transform3D G = sk->get_global_transform(), Gi = G.affine_inverse();
	// THE GROUND: where the clip has each foot, fitted to the ground under it (fit_off, from the motor's rays: the ground
	// there against the figure's own floor, weighted by how near the clip has the foot to its floor). The HIPS DROP
	// when a fitted foot is lower than the clip's (downhill, a step down): the leg could not reach it straight
	Vector3 raw[2], fit[2];
	float need = 0.0f;
	for (int s = 0; s < 2; s++) {
		if (b_ft[s] < 0) continue;
		raw[s] = G.xform(sk->get_bone_global_pose(b_ft[s]).origin);
		fit[s] = raw[s] + Vector3(0, (lock_on && fit_on) ? fit_off[s] : 0.0f, 0) + ((lock_on && fit_on) ? place_off[s] : Vector3());
		if (!lock_on || !fit_on) continue;
		need = std::max(need, (float)(raw[s].y - fit[s].y));
		if (locked[s]) need = std::max(need, (float)(raw[s].y - lock_w[s].y));
	}
	need = std::max(0.0f, std::min(need - drop_slack, drop_max));
	// (on a critically damped spring, down quicker than back up: eased by a rate, the hips' rise jumped 4-5 cm a frame at
	// every stair, the ease starting at full speed)
	if (dt > 0.0f) {
		const float w = need > drop ? drop_down : drop_up;
		drop_v += (w * w * (need - drop) - 2.0f * w * drop_v) * dt;
		drop += drop_v * dt;
		if (drop < 0.0f) { drop = 0.0f; drop_v = std::max(drop_v, 0.0f); }
	}
	if (b_root < 0) { b_root = b_ft[0] >= 0 ? b_ft[0] : -1; while (b_root >= 0 && sk->get_bone_parent(b_root) >= 0) b_root = sk->get_bone_parent(b_root); }
	if (b_root >= 0 && drop > 1e-4f) sk->set_bone_pose_position(b_root, sk->get_bone_pose_position(b_root) + Gi.basis.xform(Vector3(0, -drop, 0)));
	// STANDING STRAIGHT (Yasin 23 Nov: "straighten his stand, as you said our animation was leaning back too, fix it"):
	// the idles lean back from the hips. Standing idle (the motor sets upright_on) the line from the pelvis to the neck is
	// held at least 3 degrees forward of upright, the turn spread over the upper spine (a bend, not a hinge);
	// leaning forward - a run - is left as it is. Eased in and out over 0.25 s with the states that ask for it
	if (dt > 0.0f) upright_w += std::max(-dt / 0.25f, std::min(dt / 0.25f, (upright_on ? 1.0f : 0.0f) - upright_w));
	if (upright_w > 0.001f && b_pel >= 0 && b_neck >= 0 && b_spine[0] >= 0 && b_spine[1] >= 0 && b_spine[2] >= 0 && fwd_w.length_squared() > 1e-8f) {
		const Vector3 up_s = Gi.basis.xform(Vector3(0, 1, 0)).normalized();
		Vector3 f_s = Gi.basis.xform(fwd_w); f_s -= up_s * f_s.dot(up_s);
		if (f_s.length_squared() > 1e-10f) {
			f_s.normalize();
			const Vector3 wv = sk->get_bone_global_pose(b_neck).origin - sk->get_bone_global_pose(b_pel).origin;
			const float up_c = (float)wv.dot(up_s), f_c = (float)wv.dot(f_s);
			const float min_f = std::fabs(up_c) * 0.0524f;   // (tan 3 degrees)
			if (f_c < min_f && wv.length_squared() > 1e-10f) {
				const Vector3 want = wv + f_s * ((min_f - f_c) * upright_w);
				const Quaternion q(wv.normalized(), want.normalized());
				// (over Spine1 and Spine2, half each: Bip01_Spine carries the thighs - turned, it swung the legs and the planted
				// feet slid 5 cm)
				const Quaternion part = Quaternion().slerp(q, 0.5f);
				for (int k = 1; k < 3; k++) {
					const int b = b_spine[k];
					const int par = sk->get_bone_parent(b);
					const Basis pg = par >= 0 ? sk->get_bone_global_pose(par).basis : Basis();
					const Basis g = sk->get_bone_global_pose(b).basis;
					sk->set_bone_pose_rotation(b, (pg.inverse() * (Basis(part) * g)).get_rotation_quaternion());
				}
			}
		}
	}
	for (int s = 0; s < 2; s++) {
		pull[s] = 0.0f; pull_v[s] = Vector3();
		if (b_th[s] < 0 || b_ca[s] < 0 || b_ft[s] < 0) continue;
		const Vector3 anim_w = fit[s];   // the clip's foot, on the ground here
		const Vector3 drawn = raw[s] - Vector3(0, drop, 0);
		if (!lock_on) { locked[s] = false; rel_t[s] = 9.0f; step_t[s] = -1.0f; held[s] = 0.0f; continue; }
		Vector3 want_w;
		bool have = false;
		// a re-plant step under way: from the old pin to where the clip has the foot, in an arc, then pinned there
		if (step_t[s] >= 0.0f) {
			if (!down[s]) {   // (the clip lifts it: the step's offset fades like a release)
				const float u = std::min(step_t[s] / step_s, 1.0f), e = u * u * (3.0f - 2.0f * u);
				rel_off[s] = step_from[s].lerp(anim_w, e) + Vector3(0, step_h * std::sin(3.14159265f * u), 0) - anim_w;
				rel_t[s] = 0.0f; step_t[s] = -1.0f; locked[s] = false;
			} else {
				step_t[s] += dt;
				const float u = std::min(step_t[s] / step_s, 1.0f), e = u * u * (3.0f - 2.0f * u);
				want_w = step_from[s].lerp(anim_w, e) + Vector3(0, step_h * std::sin(3.14159265f * u), 0);
				if (u >= 1.0f) { step_t[s] = -1.0f; locked[s] = true; lock_w[s] = anim_w; held[s] = 0.0f; want_w = anim_w; }
				pull[s] = (float)(want_w - anim_w).length();
				have = true;
			}
		}
		if (!have) {
			if (down[s]) {
				// (pinned only near the ground: the clip's foot near its floor; a hand-over can hold a foot up)
				if (!locked[s]) { if ((float)raw[s].y - ground_y < pin_h) { locked[s] = true; lock_w[s] = anim_w; rel_t[s] = 9.0f; lock_t[s] = 0.0f; locks++; } }
				else if ((lock_w[s] - anim_w).length() > max_pull) {
					// (standing: a step there, not a snap - a stop into the idle moved the clip's foot 27 cm in 0.1 s)
					// (any time the other foot holds him: a step; else let go with its offset fading - never a snap: a stand-up
					// and a cover's switch snapped a foot 30 cm)
					if (down[1 - s] && step_t[1 - s] < 0.0f) { step_t[s] = 0.0f; step_from[s] = lock_w[s]; steps++; }
					else { locked[s] = false; rel_off[s] = lock_w[s] - anim_w; rel_t[s] = 0.0f; }
				}
			} else if (locked[s]) {   // the clip lifts it: the pin lets go, its offset fading
				locked[s] = false; rel_off[s] = lock_w[s] - anim_w; rel_t[s] = 0.0f;
			}
			// held off the clip's place while standing, both feet down, the other not stepping: a re-plant step
			if (locked[s] && may_step && down[0] && down[1] && step_t[1 - s] < 0.0f && (lock_w[s] - anim_w).length() > step_pull) {
				held[s] += dt;
				if ((held[s] >= step_after && held[s] >= held[1 - s]) || (lock_w[s] - anim_w).length() > step_now) { step_t[s] = 0.0f; step_from[s] = lock_w[s]; steps++; }   // (held on its pin this frame; it lifts from the next)
			} else held[s] = 0.0f;
			// (a pin's HEIGHT is the clip's own contact height on this ground, eased onto over 0.1 s: taken from the pose
			// as drawn, a foot pinned during a hand-over stood 3 cm up for its whole contact)
			if (locked[s] && fit_on && lock_t[s] < 9.0f) {
				lock_t[s] += dt;
				const float u = std::min(lock_t[s] / 0.1f, 1.0f);
				lock_w[s].y += (fit_y[s] - (float)lock_w[s].y) * (u * u * (3.0f - 2.0f * u));
				if (u >= 1.0f) { lock_w[s].y = fit_y[s]; lock_t[s] = 9.0f; }
			}
			if (locked[s]) { want_w = lock_w[s]; if (step_t[s] >= 0.0f) locked[s] = false; }
			else if (rel_t[s] < release_s) {
				rel_t[s] += dt;
				const float u = std::min(rel_t[s] / release_s, 1.0f), f = 1.0f - u * u * (3.0f - 2.0f * u);
				want_w = anim_w + rel_off[s] * std::max(f, 0.0f);
			} else want_w = anim_w;
			pull[s] = (float)(want_w - anim_w).length();
			if (locked[s]) pull_v[s] = want_w - anim_w;
		}
		if (fit_on && want_w.y < floor_y[s]) { want_w.y = floor_y[s]; if (locked[s] && lock_w[s].y < floor_y[s]) lock_w[s].y = floor_y[s]; }
		if ((want_w - drawn).length() < 1e-4f) continue;
		// the knee toward where the clip has it (its own bend), a little forward of the line hip-foot
		const Vector3 hip = sk->get_bone_global_pose(b_th[s]).origin, knee = sk->get_bone_global_pose(b_ca[s]).origin;
		reach(sk, b_th[s], b_ca[s], b_ft[s], Gi.xform(want_w), knee_pole(sk, Gi, knee - hip));
		// the sole turned onto the ground's slope while the clip has the foot down (at most 30 degrees)
		if (fit_on && fit_w[s] > 0.01f && ground_n[s].y > 0.5f) {
			Vector3 n = ground_n[s];
			const float ang = (float)std::acos(std::min(1.0f, (float)n.y));
			if (ang > 0.52f) n = Vector3(0, 1, 0).slerp(n, 0.52f / ang);
			const Vector3 up_s = Gi.basis.xform(Vector3(0, 1, 0)).normalized(), n_s = Gi.basis.xform(n).normalized();
			const Quaternion q = Quaternion().slerp(Quaternion(up_s, n_s), std::min(fit_w[s], 1.0f));
			const Transform3D F = sk->get_bone_global_pose(b_ft[s]);
			sk->set_bone_global_pose(b_ft[s], Transform3D(Basis(q) * F.basis, F.origin));
		}
	}
	// A THING HELD: on the drawn hips, the hands on it
	if (hold_kind != 0 && b_pel >= 0) {
		const Vector3 pel = G.xform(sk->get_bone_global_pose(b_pel).origin);
		const Basis Rc(Vector3(0, 1, 0), hold_yaw);
		const Vector3 hc = pel + Rc.xform(hold_l);
		hold_xf = Transform3D(Rc, hc);
		if (hold_kind == 1) {   // (the palms on its sides, toward its back as one holds a box against oneself; the hand bone 2 cm out: the palm)
			const Vector3 left = Rc.xform(Vector3(1, 0, 0)), back = Rc.xform(Vector3(0, 0, -box_d * 0.15f));
			hand_target[0] = hc + left * (box_w * 0.5f + 0.02f) + back;
			hand_target[1] = hc - left * (box_w * 0.5f + 0.02f) + back;
			hand_w[0] = hand_w[1] = hold_w;
		} else { hand_target[1] = hc; hand_w[0] = 0.0f; hand_w[1] = hold_w; }
		if (prop && prop->is_inside_tree()) {
			Transform3D xf = hold_xf;
			if (hold_kind != 1) xf.origin += Vector3(0, -0.2f, 0);
			prop->set_global_transform(xf);
		}
	} else if (hold_kind == 0 && prop_owned_hands) { hand_w[0] = hand_w[1] = 0.0f; }
	prop_owned_hands = hold_kind != 0;
	// TEXTING WITH BOTH HANDS (Yasin, 25 Nov: "make sure it sits in between two hands", and a photo: the phone upright in
	// both hands in front of the belly, its screen to the eyes). The take holds his hands 30 cm apart, the left one tapping
	// the air: both wrists brought in to either side of the point between them, 13 cm apart (the phone's width and the
	// palms' cupping) - the phone then sits between the palms (below). Eased with the phone's own turn.
	{
		const float want = (hand_prop_two && hold_kind == 0 && ear_w <= 0.001f) ? hand_prop_face : 0.0f;
		two_w += std::max(-1.0f / 15.0f, std::min(1.0f / 15.0f, want - two_w));
		if (two_w > 0.001f && b_hd[0] >= 0 && b_hd[1] >= 0 && b_ua[0] >= 0 && b_ua[1] >= 0) {
			const Vector3 lw = G.xform(sk->get_bone_global_pose(b_hd[0]).origin), rw2 = G.xform(sk->get_bone_global_pose(b_hd[1]).origin);
			Vector3 rt = G.xform(sk->get_bone_global_pose(b_ua[1]).origin) - G.xform(sk->get_bone_global_pose(b_ua[0]).origin);
			rt.y = 0.0f; rt = rt.length_squared() > 1e-8f ? rt.normalized() : Vector3(1, 0, 0);
			const Vector3 c = (lw + rw2) * 0.5f;
			hand_target[0] = c - rt * 0.065f; hand_target[1] = c + rt * 0.065f;
			hand_w[0] = hand_w[1] = two_w; two_owned = true;
		} else if (two_owned) { hand_w[0] = hand_w[1] = 0.0f; two_owned = false; }
	}
	for (int s = 0; s < 2; s++) {
		if (s == 1 && ear_w > 0.001f && b_head >= 0) {   // A CALL: the wrist under the right ear, where the head is drawn (the arm a
			// standing take's on a walking spine put the phone 20 cm off the ear)
			const Vector3 hp = sk->get_bone_global_pose(b_head).origin;
			const Vector3 up_s = Gi.basis.xform(Vector3(0, 1, 0)).normalized();
			// (his right from his own shoulders, as drawn: from his facing, turned in the skeleton's frame, it was his left -
			// the hand went round the back of his head)
			Vector3 right = sk->get_bone_global_pose(b_ua[1]).origin - sk->get_bone_global_pose(b_ua[0]).origin;
			right -= up_s * right.dot(up_s); right = right.length_squared() > 1e-8f ? right.normalized() : Vector3(-1, 0, 0);
			const Vector3 f = up_s.cross(right).normalized();
			// (in METRES, in the world: the skeleton's own units are centimetres - offsets taken in them put the hand on the
			// head bone itself, inside his head)
			const Vector3 rw = G.basis.xform(right).normalized(), uw = G.basis.xform(up_s).normalized(), fw2 = G.basis.xform(f).normalized();
			hand_target[1] = G.xform(hp) + rw * 0.11f - uw * 0.11f + fw2 * 0.03f;   // (the wrist under the ear, out from the face: the phone in the palm runs up the cheek)
			hand_w[1] = ear_w;
		}
		if (hand_w[s] <= 0.001f || b_ua[s] < 0 || b_fa[s] < 0 || b_hd[s] < 0) continue;
		const Vector3 wr = sk->get_bone_global_pose(b_hd[s]).origin;
		const Vector3 tgt = wr.lerp(Gi.xform(hand_target[s]), std::min(hand_w[s], 1.0f));
		const Vector3 sh = sk->get_bone_global_pose(b_ua[s]).origin, el = sk->get_bone_global_pose(b_fa[s]).origin;
		// (the elbow out to the side and down, never in toward the ribs: with the hands on a box's sides the clip's own
		// elbow drawn in put the forearm into the body)
		Vector3 pole = el - sh;
		const Vector3 fw = Gi.basis.xform(fwd_w);
		if (fw.length_squared() > 1e-10f) {
			const Vector3 up_s = Gi.basis.xform(Vector3(0, 1, 0)).normalized(), f = fw.normalized();
			const Vector3 left_s = up_s.cross(f).normalized();   // (his left: up x forward)
			const Vector3 out = s == 0 ? left_s : -left_s;
			const float L = std::max((float)pole.length(), 1e-3f);
			pole = pole / L * 0.3f + out * 0.8f - up_s * 0.4f;
		}
		if (s == 1 && ear_w > 0.001f && b_ua[0] >= 0) {   // (a call: the elbow forward and down, a little out - the side pole
			// above, from the facing in the skeleton's turned frame, swung it up across the face)
			const Vector3 up_s = Gi.basis.xform(Vector3(0, 1, 0)).normalized();
			Vector3 right = sk->get_bone_global_pose(b_ua[1]).origin - sk->get_bone_global_pose(b_ua[0]).origin;
			right -= up_s * right.dot(up_s); right = right.normalized();
			const Vector3 f = up_s.cross(right).normalized();
			pole = pole.lerp(f * 0.6f - up_s * 0.6f + right * 0.3f, std::min(ear_w, 1.0f));
		}
		reach(sk, b_ua[s], b_fa[s], b_hd[s], tgt, pole);
	}
	// the thing in the right hand (the phone), on the hand as finally drawn
	if (hand_prop && hand_prop->is_inside_tree()) {
		hand_prop->set_visible(hand_prop_on);
		if (hand_prop_on && b_hd[1] >= 0 && b_fing[0] >= 0 && b_fing[1] >= 0) {
			// (in the palm, from the hand as drawn: its long side along the fingers - the wrist to the middle finger's root -
			// its screen facing out of the palm; centred in the palm, 1.5 cm off it. From the hand bone's own axes, guessed,
			// it stood out sideways; with the skeleton's scale - its bones in centimetres - it was a speck)
			const Transform3D SG = sk->get_global_transform();
			const Vector3 wr = SG.xform(sk->get_bone_global_pose(b_hd[1]).origin);
			const Vector3 mid = SG.xform(sk->get_bone_global_pose(b_fing[1]).origin), th = SG.xform(sk->get_bone_global_pose(b_fing[0]).origin);
			Vector3 along = mid - wr; const float L = (float)along.length();
			if (L > 1e-4f) {
				along /= L;
				// (into the palm: the other way it sat on the back of the hand, outside it - Yasin, 25 Nov)
				Vector3 n = (th - wr).cross(along); n = n.length_squared() > 1e-10f ? n.normalized() : Vector3(0, 0, 1);
				Vector3 at = wr + along * (L * 0.8f) + n * hand_prop_off.origin.z;
				Vector3 lng = along;
				if (ear_w > 0.5f && b_head >= 0) {
					// (on a call its lean mirrored - the top to the ear, the bottom toward the mouth: "phone would lean the other
					// way when held against the ear". In the palm it is already ~3 cm nearer his head than on the hand's back:
					// 5 cm more on top put it in his skull)
					Vector3 fwd = SG.basis.xform(Vector3(0, 0, 1)); // (placeholder, replaced below)
					const Vector3 rs = SG.xform(sk->get_bone_global_pose(b_ua[1]).origin), ls = SG.xform(sk->get_bone_global_pose(b_ua[0]).origin);
					Vector3 right = rs - ls; right.y = 0.0f;
					if (right.length() > 1e-4f) {
						right.normalize();
						fwd = Vector3(0, 1, 0).cross(right).normalized();
						lng = (lng - fwd * (2.0f * (float)lng.dot(fwd))).normalized();   // (its forward lean mirrored)
					}
				}
				Vector3 x = lng.cross(n).normalized();
				Vector3 nn = x.cross(lng).normalized();
				Basis bs(x, lng, nn);
				if (hand_prop_both && b_hd[0] >= 0 && b_lfing >= 0 && b_head >= 0) {
					// TEXTING WITH BOTH HANDS (Yasin, 25 Nov: "turn the phone 90 degrees to left before the hands meet ... he is
					// looking at the side of the phone ... make sure it sits in between two hands"): between his palms, its screen
					// turned to his eyes - eased in from the one hand's grip as the other hand comes to it (from 30 cm apart to 15)
					const Vector3 lw = SG.xform(sk->get_bone_global_pose(b_hd[0]).origin), lm = SG.xform(sk->get_bone_global_pose(b_lfing).origin);
					const Vector3 lpalm = lw + (lm - lw) * 0.8f, rpalm = wr + along * (L * 0.8f);
					const float apart = (float)(lpalm - rpalm).length();
					// (between the palms as they come together - from 30 cm apart to 15; held in the right hand when apart. Turned
					// upright, its screen to his eyes, by the take's times (hand_prop_face) - by the hands' distance alone it stayed on its
					// edge in the one hand's grip while the take held them apart)
					const float kp = std::min(1.0f, std::max(0.0f, (0.30f - apart) / 0.15f)) * hand_prop_face;
					const float k = hand_prop_face;
					if (k > 0.0f) {
						const Vector3 hold = rpalm.lerp((lpalm + rpalm) * 0.5f, kp);
						const Vector3 eye = SG.xform(sk->get_bone_global_pose(b_head).origin);
						Vector3 scr = (eye - hold).normalized();                     // (the screen to his eyes)
						// (upright - its top away from him, along his facing from the shoulders: from the hips to the hands it ran sideways,
						// the hands held to his right, and the phone lay landscape - Yasin, 25 Nov: "the phone is landscape ... it should
						// look like this", a photo of a phone held upright, its screen to the eyes)
						const Vector3 rs = SG.xform(sk->get_bone_global_pose(b_ua[1]).origin), ls = SG.xform(sk->get_bone_global_pose(b_ua[0]).origin);
						Vector3 rt = rs - ls; rt.y = 0.0f;
						Vector3 up2 = rt.length_squared() > 1e-8f ? Vector3(0, 1, 0).cross(rt.normalized()) : lng;
						if (up2.dot(hold - SG.xform(sk->get_bone_global_pose(b_pel).origin)) < 0.0f) up2 = -up2;
						up2 -= scr * up2.dot(scr);
						if (up2.length_squared() < 1e-8f) up2 = lng;
						up2.normalize();
						const Vector3 x2 = up2.cross(scr).normalized();
						const Basis b2(x2, up2, x2.cross(up2).normalized());
						bs = Basis(Quaternion(bs.orthonormalized()).slerp(Quaternion(b2.orthonormalized()), k));
						at = at.lerp(hold + scr * 0.01f, k);
					}
				}
				hand_prop->set_global_transform(Transform3D(bs, at));
			}
		}
	}
}
