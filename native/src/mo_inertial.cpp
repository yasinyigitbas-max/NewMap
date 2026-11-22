// MoInertial: see mo_inertial.h.
#include "mo_inertial.h"

#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

void MoInertial::_bind_methods() {
	ClassDB::bind_method(D_METHOD("inertialize", "seconds"), &MoInertial::inertialize);
	ClassDB::bind_method(D_METHOD("is_blending"), &MoInertial::is_blending);
	ClassDB::bind_method(D_METHOD("get_left"), &MoInertial::get_left);
}

float MoInertial::quintic(float x0, float v0, float T, float *c) {
	for (int i = 0; i < 6; i++) c[i] = 0.0f;
	if (x0 < 1e-6f || T <= 1e-4f) return 0.0f;
	if (v0 > 0.0f) v0 = 0.0f;                            // (moving away from the target: start from rest instead)
	if (v0 < 0.0f) T = std::min(T, -5.0f * x0 / v0);     // (no overshoot past the target)
	const float T2 = T * T, T3 = T2 * T, T4 = T3 * T, T5 = T4 * T;
	float a0 = (-8.0f * v0 * T - 20.0f * x0) / T2;
	if (a0 < 0.0f) a0 = 0.0f;
	c[0] = x0; c[1] = v0; c[2] = 0.5f * a0;
	c[3] = -(3.0f * a0 * T2 + 12.0f * v0 * T + 20.0f * x0) / (2.0f * T3);
	c[4] = (3.0f * a0 * T2 + 16.0f * v0 * T + 30.0f * x0) / (2.0f * T4);
	c[5] = -(a0 * T2 + 6.0f * v0 * T + 12.0f * x0) / (2.0f * T5);
	return T;
}

float MoInertial::eval(const float *c, float T, float t) {
	if (t >= T || T <= 0.0f) return 0.0f;
	return ((((c[5] * t + c[4]) * t + c[3]) * t + c[2]) * t + c[1]) * t + c[0];
}

double MoInertial::get_left() const {
	if (!live) return 0.0;
	float T = 0.0f;
	for (const Bone &b : bones) T = std::max(T, std::max(b.pT, b.qT));
	return std::max(0.0f, T - t);
}

// The switch: each bone's offset from where the last drawn pose was going (one frame on at its own speed) to the new
// clip's pose now, and that offset's speed
void MoInertial::start(Skeleton3D *sk, float dt) {
	const Transform3D G = sk->get_global_transform(), Gi = G.affine_inverse();
	const Quaternion Gq = G.basis.get_rotation_quaternion(), Gq1 = sk_g1.basis.get_rotation_quaternion(), Gq0 = sk_g.basis.get_rotation_quaternion();
	const float idt = dt > 1e-5f ? 1.0f / dt : 60.0f;
	last_jump = 0.0f;
	for (int b = 0; b < (int)bones.size(); b++) {
		Bone &B = bones[b];
		const Vector3 raw_p = sk->get_bone_pose_position(b);
		const Quaternion raw_q = sk->get_bone_pose_rotation(b);
		Vector3 want_p, vel_p; Quaternion want_q, vel_dq;
		if (B.parent < 0) {   // a root bone: where it was going in the world, in the skeleton's frame now
			const Vector3 W = sk_g.xform(B.p), W1 = sk_g1.xform(B.p1);
			want_p = Gi.xform(W + (W - W1));
			// (the offset's speed is the hips' own, against the figure: the body's travel in the world moves the new pose
			// too; taken whole, a run's 2.8 m/s cut the hand-over to a frame or two: a pop)
			vel_p = (B.p - B.p1) * idt;
			const Quaternion R = Gq0 * B.q, R1 = Gq1 * B.q1;
			const Quaternion d = (R * R1.inverse()).normalized();
			want_q = (Gq.inverse() * (d * R)).normalized();
			vel_dq = (B.q * B.q1.inverse()).normalized();
			last_jump = std::max(last_jump, (float)(want_p - raw_p).length());
		} else {
			want_p = B.p + (B.p - B.p1);
			vel_p = (B.p - B.p1) * idt;
			vel_dq = (B.q * B.q1.inverse()).normalized();
			want_q = (vel_dq * B.q).normalized();
		}
		// position
		const Vector3 dp = want_p - raw_p;
		B.px0 = (float)dp.length();
		if (B.px0 > 1e-5f) { B.pd = dp / B.px0; B.pT = quintic(B.px0, (float)vel_p.dot(B.pd), pend_T, B.pc); }
		else { B.pd = Vector3(); B.pT = 0.0f; }
		// rotation: the offset as an axis and an angle; the speed: the old pose's turn per second about that axis
		Quaternion qo = (want_q * raw_q.inverse()).normalized();
		if (qo.w < 0.0f) qo = -qo;
		// (the angle from the axis part's length: near no turn sqrt(1 - w*w) loses every digit in floats)
		const Vector3 qxyz(qo.x, qo.y, qo.z);
		const float s = (float)qxyz.length();
		const float ang = 2.0f * std::atan2(s, (float)qo.w);
		if (ang > 1e-5f && s > 1e-7f) {
			B.qa = qxyz / s;
			Quaternion qv = vel_dq; if (qv.w < 0.0f) qv = -qv;
			const Vector3 vxyz(qv.x, qv.y, qv.z);
			const float vs = (float)vxyz.length(), va = 2.0f * std::atan2(vs, (float)qv.w);
			const Vector3 w = vs > 1e-7f ? vxyz / vs * (va * idt) : Vector3();
			B.qx0 = ang; B.qT = quintic(ang, (float)w.dot(B.qa), pend_T, B.qc);
		} else { B.qx0 = 0.0f; B.qT = 0.0f; }
	}
	t = 0.0f; live = true;
	if (frame_id != start_frame) switches++;
}

void MoInertial::_process_modification_with_delta(double p_delta) {
	Skeleton3D *sk = get_skeleton();
	if (!sk) return;
	const int n = sk->get_bone_count();
	if ((int)bones.size() != n) {
		bones.assign(n, Bone());
		for (int b = 0; b < n; b++) bones[b].parent = sk->get_bone_parent(b);
		frames = 0; live = false; frame_id = ~0ull;
	}
	// A NEW FRAME: last frame's final output becomes the history (the skeleton may be posed more than once in a frame -
	// a clip seeked at once, then its own update - and only the last pose was drawn), the running hand-over moves on
	const uint64_t f = Engine::get_singleton()->get_process_frames();
	if (f != frame_id) {
		if (frame_id != ~0ull) {
			for (Bone &B : bones) { B.p1 = B.p; B.q1 = B.q; B.p = B.po; B.q = B.qo; }
			sk_g1 = sk_g; sk_g = sk_go;
			frames++;
			if (live) {
				t += dt_frame;
				float T = 0.0f;
				for (const Bone &B : bones) T = std::max(T, std::max(B.pT, B.qT));
				if (t >= T) live = false;
			}
		}
		frame_id = f;
		if (p_delta > 0.0) dt_frame = (float)p_delta;
	}
	if (pending) { pending = false; if (frames >= 2) { start(sk, dt_frame); start_frame = frame_id; } }
	else if (live && frame_id == start_frame) start(sk, dt_frame);   // (posed again in the switch's frame: the offsets from this pose and place)
	for (int b = 0; b < n; b++) {
		Bone &B = bones[b];
		Vector3 p = sk->get_bone_pose_position(b);
		Quaternion q = sk->get_bone_pose_rotation(b);
		if (live) {
			if (B.pT > 0.0f) p += B.pd * eval(B.pc, B.pT, t);
			if (B.qT > 0.0f) {
				const float a = eval(B.qc, B.qT, t);
				if (a > 1e-6f) q = (Quaternion(B.qa, a) * q).normalized();
			}
			sk->set_bone_pose_position(b, p);
			sk->set_bone_pose_rotation(b, q);
		}
		B.po = p; B.qo = q;
	}
	sk_go = sk->get_global_transform();
}
