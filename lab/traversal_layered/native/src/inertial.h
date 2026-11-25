// Lab B: inertialization (study 4.2). On every switch the difference between the pose we were showing and the new
// source pose (and its velocity) is kept as an offset that decays with a critically damped spring, so the new clip
// takes over without a crossfade and without a pop. DECISIONS 3.6.
#pragma once

#include "clip_library.h"

#include <cmath>
#include <vector>

namespace lab {

inline Vector3 quat_to_rotvec(const Quaternion &q0) {
	Quaternion q = q0.w < 0 ? -q0 : q0;
	const float s = std::sqrt(q.x * q.x + q.y * q.y + q.z * q.z);
	if (s < 1e-6f) return Vector3(q.x, q.y, q.z) * 2.0f;
	const float ang = 2.0f * std::atan2(s, q.w);
	return Vector3(q.x, q.y, q.z) * (ang / s);
}

inline Quaternion rotvec_to_quat(const Vector3 &v) {
	const float ang = v.length();
	if (ang < 1e-6f) return Quaternion(v.x * 0.5f, v.y * 0.5f, v.z * 0.5f, 1.0f).normalized();
	return Quaternion(v / ang, ang);
}

// critically damped spring toward zero, exact step
inline void spring_decay(float &x, float &v, float halflife, float dt) {
	const float y = 2.0f * 0.69314718f / std::fmax(halflife, 1e-4f); // damping/2 = 2 ln2 / halflife
	const float j1 = v + x * y;
	const float eydt = std::exp(-y * dt);
	x = eydt * (x + j1 * dt);
	v = eydt * (v - j1 * y * dt);
}

struct Inertializer {
	std::vector<Vector3> rx, rv; // per bone rotation offset (rotation vector) and its velocity
	Vector3 hx, hv;              // hips position offset (skeleton units) and velocity
	float halflife = 0.07f;      // ~0.2 s to fade (study 4.2)
	bool active = false;

	void reset(int n) {
		rx.assign(n, Vector3());
		rv.assign(n, Vector3());
		hx = hv = Vector3();
		active = false;
	}

	// prev_out/prev_out_old: what we showed this tick and the tick before; src_now/src_old: the new source at the
	// same two moments. Keeps any offset still decaying (it is folded into prev_out already).
	void transition(const Pose &prev_out, const Pose &prev_out_old, const Pose &src_now, const Pose &src_old, float dt) {
		const int n = prev_out.size();
		if ((int)rx.size() != n) reset(n);
		for (int i = 0; i < n; i++) {
			rx[i] = quat_to_rotvec(prev_out.rot[i] * src_now.rot[i].inverse());
			const Vector3 w_out = quat_to_rotvec(prev_out.rot[i] * prev_out_old.rot[i].inverse()) / dt;
			const Vector3 w_src = quat_to_rotvec(src_now.rot[i] * src_old.rot[i].inverse()) / dt;
			rv[i] = w_out - w_src;
			// clamp silly velocities (first frames, wraps)
			if (rv[i].length() > 20.0f) rv[i] = rv[i].normalized() * 20.0f;
		}
		hx = prev_out.hips - src_now.hips;
		hv = ((prev_out.hips - prev_out_old.hips) - (src_now.hips - src_old.hips)) / dt;
		if (hv.length() > 400.0f) hv = hv.normalized() * 400.0f;
		active = true;
	}

	void step(float dt) {
		if (!active) return;
		float m = 0;
		for (size_t i = 0; i < rx.size(); i++) {
			for (int k = 0; k < 3; k++) spring_decay(rx[i][k], rv[i][k], halflife, dt);
			m = std::fmax(m, rx[i].length());
		}
		for (int k = 0; k < 3; k++) spring_decay(hx[k], hv[k], halflife, dt);
		if (m < 1e-4f && hx.length() < 1e-3f) active = false;
	}

	void apply(Pose &p) const {
		if (!active) return;
		for (int i = 0; i < p.size(); i++) p.rot[i] = (rotvec_to_quat(rx[i]) * p.rot[i]).normalized();
		p.hips += hx;
	}
};

} // namespace lab
