// BodyLayer: see body_layer.h.
#include "body_layer.h"

#include <godot_cpp/core/object.hpp>
#include <godot_cpp/variant/quaternion.hpp>

#include <algorithm>
#include <cmath>

namespace godot {

namespace {
inline Basis arc2(Vector3 a, Vector3 b) {
	if (a.length_squared() < 1e-10f || b.length_squared() < 1e-10f) return Basis();
	a.normalize(); b.normalize();
	const Vector3 ax = a.cross(b);
	const float sn = ax.length(), cs = a.dot(b);
	if (sn < 1e-6f) return Basis();
	return Basis(ax / sn, std::atan2(sn, cs));
}
// a two-bone reach (shoulder, elbow, wrist) to a point, the elbow toward the pole (skeleton space)
void reach2(Skeleton3D *sk, int a, int b, int c, const Vector3 &target, const Vector3 &pole) {
	if (a < 0 || b < 0 || c < 0) return;
	const Transform3D Ga = sk->get_bone_global_pose(a), Gb = sk->get_bone_global_pose(b), Gc = sk->get_bone_global_pose(c);
	const Vector3 pa = Ga.origin, pb = Gb.origin, pc = Gc.origin;
	const float la = (pb - pa).length(), lb = (pc - pb).length();
	if (la < 1e-4f || lb < 1e-4f) return;
	const Vector3 tv = target - pa;
	const float d = std::min(std::max(tv.length(), std::fabs(la - lb) + 1e-3f), la + lb - 1e-3f);
	const Vector3 u = tv.normalized();
	Vector3 v = pole - u * pole.dot(u);
	if (v.length_squared() < 1e-8f) v = Vector3(0, 0, 1) - u * u.z;
	v.normalize();
	const float ca = std::min(std::max((la * la + d * d - lb * lb) / (2.0f * la * d), -1.0f), 1.0f);
	const Vector3 el = pa + (u * ca + v * std::sqrt(std::max(0.0f, 1.0f - ca * ca))) * la;
	sk->set_bone_global_pose(a, Transform3D(arc2(pb - pa, el - pa) * Ga.basis, pa));
	const Transform3D Gb2 = sk->get_bone_global_pose(b), Gc2 = sk->get_bone_global_pose(c);
	sk->set_bone_global_pose(b, Transform3D(arc2(Gc2.origin - Gb2.origin, pa + u * d - Gb2.origin) * Gb2.basis, Gb2.origin));
}
}

void BodyLayer::find_bones(Skeleton3D *sk) {
	found = true;
	b_sp[0] = sk->find_bone("Bip01_Spine"); b_sp[1] = sk->find_bone("Bip01_Spine1"); b_sp[2] = sk->find_bone("Bip01_Spine2");
	b_neck = sk->find_bone("Bip01_Neck"); b_head = sk->find_bone("Bip01_Head");
	for (int s = 0; s < 2; s++) {
		const String P = s == 0 ? "Bip01_L_" : "Bip01_R_";
		b_cl[s] = sk->find_bone(P + String("Clavicle")); b_ua[s] = sk->find_bone(P + String("UpperArm")); b_fa[s] = sk->find_bone(P + String("Forearm")); b_hd[s] = sk->find_bone(P + String("Hand"));
		b_f2[s] = sk->find_bone(P + String("Finger2"));
		arm_bones[s].clear();
		for (int b : { b_cl[s], b_ua[s], b_fa[s], b_hd[s] }) if (b >= 0) arm_bones[s].push_back(b);
		for (int f = 0; f <= 4; f++) for (int j = 0; j < 3; j++) {
			const int b = sk->find_bone(P + String("Finger") + String::num_int64(f) + (j == 0 ? String() : String::num_int64(j)));
			if (b >= 0) arm_bones[s].push_back(b);
		}
	}
}

void BodyLayer::overlay(Skeleton3D *sk) {
	if (clip.is_null() || mask == 0 || w <= 0.001f) return;
	if (track_of != clip.ptr()) {
		track_of = clip.ptr();
		trk.assign(sk->get_bone_count(), -1);
		for (int k = 0; k < clip->get_track_count(); k++) {
			if (clip->track_get_type(k) != Animation::TYPE_ROTATION_3D) continue;
			const String p = String(clip->track_get_path(k));
			const int c = p.find(":");
			const int b = sk->find_bone(c >= 0 ? p.substr(c + 1) : p);
			if (b >= 0) trk[b] = k;
		}
	}
	const double len = clip->get_length();
	double tt = t;
	if (len > 0.0) { tt = std::fmod(t, len); if (tt < 0.0) tt += len; }   // (a one-shot used as a hold, Carrying Turn: wrapped too)
	// the previous take's pose for the cross-fade (its own track map: the libraries' takes share the bones' order of
	// tracks only by chance)
	const bool fade = clip_prev.is_valid() && x < 0.999f;
	if (fade && track_prev_of != clip_prev.ptr()) {
		track_prev_of = clip_prev.ptr();
		trk_prev.assign(sk->get_bone_count(), -1);
		for (int k = 0; k < clip_prev->get_track_count(); k++) {
			if (clip_prev->track_get_type(k) != Animation::TYPE_ROTATION_3D) continue;
			const String p = String(clip_prev->track_get_path(k));
			const int c = p.find(":");
			const int b = sk->find_bone(c >= 0 ? p.substr(c + 1) : p);
			if (b >= 0) trk_prev[b] = k;
		}
	}
	double tp = t_prev;
	if (fade) { const double lp = clip_prev->get_length(); if (lp > 0.0) { tp = std::fmod(t_prev, lp); if (tp < 0.0) tp += lp; } }
	auto put = [&](int b, float k) {
		if (b < 0 || b >= (int)trk.size() || trk[b] < 0) return;
		Quaternion q = clip->rotation_track_interpolate(trk[b], tt);
		if (fade && b < (int)trk_prev.size() && trk_prev[b] >= 0) q = clip_prev->rotation_track_interpolate(trk_prev[b], tp).slerp(q, x);
		sk->set_bone_pose_rotation(b, sk->get_bone_pose_rotation(b).slerp(q, k));
	};
	if (mask == 2) { for (int i = 0; i < 3; i++) put(b_sp[i], w * 0.6f); for (int b : arm_bones[0]) put(b, w); }
	for (int b : arm_bones[1]) put(b, w);
}

void BodyLayer::place_prop(Skeleton3D *sk) {
	miss[0] = miss[1] = 0.0f;
	if (!prop || prop_id == 0 || !ObjectDB::get_instance(prop_id)) { prop = nullptr; return; }
	const Transform3D skx = sk->get_global_transform();
	const Transform3D to_sk = skx.affine_inverse();
	const Vector3 up(0, 1, 0);
	Vector3 f(fwd.x, 0, fwd.z); if (f.length_squared() < 1e-6f) f = Vector3(0, 0, 1); f.normalize();
	auto palm = [&](int s) -> Vector3 {
		const Vector3 h = skx.xform(sk->get_bone_global_pose(b_hd[s]).origin);
		if (b_f2[s] < 0) return h;
		return h + (skx.xform(sk->get_bone_global_pose(b_f2[s]).origin) - h) * 0.55f;
	};
	if (b_hd[0] < 0 || b_hd[1] < 0) return;
	if (!two) {
		const Vector3 p = palm(1);
		const Vector3 X = f, Y = up, Z = X.cross(Y);
		Basis Bc; Bc.set_column(0, X); Bc.set_column(1, Y); Bc.set_column(2, Z);
		Transform3D T(Bc, p - Bc.xform(grip_r.origin));
		if (blend < 1.0f) T = from.interpolate_with(T, std::max(blend, 0.0f));
		prop->set_global_transform(T);
		miss[1] = T.xform(grip_r.origin).distance_to(p);
		return;
	}
	// two hands: the prop between the palms, its grips' axis along them, level, clear of his chest
	const Vector3 L = palm(0), R = palm(1);
	Vector3 X = R - L; X.y = 0.0f;
	if (X.length_squared() < 1e-6f) X = up.cross(f);
	X.normalize();
	const Vector3 Y = up, Z = X.cross(Y);
	Basis Bc; Bc.set_column(0, X); Bc.set_column(1, Y); Bc.set_column(2, Z);
	const Vector3 mid_g = (grip_l.origin + grip_r.origin) * 0.5f;
	Vector3 o = (L + R) * 0.5f - Bc.xform(mid_g);
	const Vector3 chest = b_sp[2] >= 0 ? skx.xform(sk->get_bone_global_pose(b_sp[2]).origin) : (L + R) * 0.5f - f * 0.3f;
	// (the chest's own facing, from the shoulders: the walk's torso turns with each stride, and the box with it, so
	// the arms keep it in reach)
	{
		const Vector3 sl = skx.xform(sk->get_bone_global_pose(b_ua[0]).origin), sr = skx.xform(sk->get_bone_global_pose(b_ua[1]).origin);
		Vector3 fc = (sl - sr).cross(up); fc.y = 0.0f;
		if (fc.length_squared() > 1e-6f && fc.normalized().dot(f) > 0.5f) f = fc.normalized();
	}
	float gap = 1e9f;
	for (int i = 0; i < 8; i++) gap = std::min(gap, (Bc.xform(col.get_endpoint(i)) + o - chest).dot(f));
	if (col.size.length_squared() < 1e-8f) gap = 0.2f;
	const float want = 0.16f;   // (the chest's own depth in front of the spine, and a little air)
	if (gap < want) { o += f * (want - gap); gap = want; }
	// (in each arm's reach: a grip past it brings the box toward that shoulder, so the hand stays on it)
	for (int s = 0; s < 2; s++) {
		const Vector3 sh = skx.xform(sk->get_bone_global_pose(b_ua[s]).origin);
		const Vector3 el = skx.xform(sk->get_bone_global_pose(b_fa[s]).origin), wr = skx.xform(sk->get_bone_global_pose(b_hd[s]).origin);
		const float arm = (el - sh).length() + (wr - el).length();
		const Vector3 wt = Bc.xform((s == 0 ? grip_l : grip_r).origin) + o - (palm(s) - wr);   // (where the wrist goes)
		const float d = wt.distance_to(sh), lim = arm * 0.95f;
		if (d > lim) o += (sh - wt).normalized() * (d - lim);
	}
	gap = 1e9f;
	for (int i = 0; i < 8; i++) gap = std::min(gap, (Bc.xform(col.get_endpoint(i)) + o - chest).dot(f));
	if (col.size.length_squared() < 1e-8f) gap = 0.2f;
	chest_gap = gap;
	Transform3D T(Bc, o);
	if (blend < 1.0f) T = from.interpolate_with(T, std::max(blend, 0.0f));
	prop->set_global_transform(T);
	// each arm to its grip: the wrist where it puts the palm on the grip, the elbow out and down
	const float k = skx.basis.get_column(0).length();
	fit_min = 1.0f;
	for (int it = 0; it < 2; it++)   // (twice: the palm's offset from the wrist turns with the reach)
	for (int s = 0; s < 2; s++) {
		const Vector3 g = T.xform((s == 0 ? grip_l : grip_r).origin);
		const Vector3 wr = skx.xform(sk->get_bone_global_pose(b_hd[s]).origin);
		const Vector3 target = g - (palm(s) - wr);
		const Vector3 side = s == 0 ? -X : X;
		const Vector3 pole = to_sk.basis.xform(side * 1.0f - up * 0.8f);
		// (within its reach only: never stretched)
		const Vector3 sh = sk->get_bone_global_pose(b_ua[s]).origin, el = sk->get_bone_global_pose(b_fa[s]).origin, wr0 = sk->get_bone_global_pose(b_hd[s]).origin;
		const float arm = (el - sh).length() + (wr0 - el).length();
		Vector3 ts = to_sk.xform(target);
		const float fit = std::min(std::max((arm * 0.995f - (ts - sh).length()) / (0.04f * k), 0.0f), 1.0f);
		if (fit < 1.0f) ts = wr0.lerp(ts, fit);
		fit_min = std::min(fit_min, fit);
		reach2(sk, b_ua[s], b_fa[s], b_hd[s], ts, pole);
		miss[s] = palm(s).distance_to(g);
	}
}

void BodyLayer::look(Skeleton3D *sk, float dt) {
	look_w += ((look_on ? 1.0f : 0.0f) - look_w) * std::min(dt / 0.3f, 1.0f);
	if (b_neck < 0 || b_head < 0) return;
	const Transform3D skx = sk->get_global_transform();
	const Vector3 up(0, 1, 0);
	Vector3 f(fwd.x, 0, fwd.z); if (f.length_squared() < 1e-6f) f = Vector3(0, 0, 1); f.normalize();
	float ty = 0.0f, tp = 0.0f;
	if (look_on) {
		const Vector3 hp = skx.xform(sk->get_bone_global_pose(b_head).origin);
		const Vector3 d = look_p - hp;
		const Vector3 dh(d.x, 0, d.z);
		if (dh.length() > 0.05f) {
			ty = std::atan2(f.cross(dh).dot(up), f.dot(dh));
			tp = std::atan2(d.y, dh.length());
		}
		// (behind him: the head comes back round, it does not twist past the shoulder)
		if (std::fabs(ty) > 2.0f) ty = 0.0f;
		ty = std::min(std::max(ty, -1.22f), 1.22f); tp = std::min(std::max(tp, -0.52f), 0.52f);
	}
	const float e = std::min(dt / 0.25f, 1.0f);
	look_yaw += (ty - look_yaw) * e; look_pitch += (tp - look_pitch) * e;
	if (look_w < 0.001f && std::fabs(look_yaw) < 0.001f && std::fabs(look_pitch) < 0.001f) return;
	const float yw = look_yaw * look_w, pt = look_pitch * look_w;
	const Basis Ry(up, yw);
	const Vector3 ax = Ry.xform(f.cross(up)).normalized();
	const Quaternion R = Quaternion(Basis(ax, pt) * Ry);
	const Basis so = skx.basis.orthonormalized(), si = so.inverse();
	const Quaternion Rn = Quaternion().slerp(R, 0.4f);
	const Transform3D Gn = sk->get_bone_global_pose(b_neck);
	sk->set_bone_global_pose(b_neck, Transform3D(si * Basis(Rn) * so * Gn.basis, Gn.origin));
	const Transform3D Gh = sk->get_bone_global_pose(b_head);
	sk->set_bone_global_pose(b_head, Transform3D(si * Basis(R * Rn.inverse()) * so * Gh.basis, Gh.origin));
}

void BodyLayer::_process_modification_with_delta(double p_delta) {
	Skeleton3D *sk = get_skeleton();
	if (!sk) return;
	if (!found) find_bones(sk);
	overlay(sk);
	look(sk, (float)p_delta);
	place_prop(sk);
}

} // namespace godot
