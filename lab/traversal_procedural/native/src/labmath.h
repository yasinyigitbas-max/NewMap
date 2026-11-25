// Lab A (procedural): small math helpers shared by the motor and the poser.
#pragma once

#include <godot_cpp/variant/basis.hpp>
#include <godot_cpp/variant/quaternion.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>

namespace lab {
using namespace godot;

constexpr float PI_F = 3.14159265358979f;
constexpr float DEG = PI_F / 180.0f;
constexpr float GRAV = 9.81f;
static const Vector3 UP(0, 1, 0);

// WORLD_CONTRACT.md section 1 (shared with the game's damage system): layers as bits.
constexpr uint32_t LAYER_WORLD = 1, LAYER_PLAYER = 2, LAYER_BREAKABLE = 4, LAYER_OPENING = 8, LAYER_CARS = 16,
				   LAYER_PEOPLE = 32, LAYER_DEBRIS = 64;
constexpr uint32_t PROBE_MASK = LAYER_WORLD | LAYER_BREAKABLE | LAYER_OPENING; // never debris
constexpr uint32_t CAPSULE_MASK = LAYER_WORLD | LAYER_BREAKABLE | LAYER_OPENING | LAYER_CARS | LAYER_PEOPLE;

inline float clampf(float x, float a, float b) { return x < a ? a : (x > b ? b : x); }
inline float lerpf(float a, float b, float t) { return a + (b - a) * t; }
inline float smooth01(float x) {
	x = clampf(x, 0.0f, 1.0f);
	return x * x * (3.0f - 2.0f * x);
}
// Minimum-jerk position profile 0..1 (zero speed and acceleration at both ends).
inline float minjerk(float u) {
	u = clampf(u, 0.0f, 1.0f);
	return u * u * u * (10.0f + u * (-15.0f + 6.0f * u));
}
inline float wrap_pi(float a) {
	while (a > PI_F) a -= 2.0f * PI_F;
	while (a < -PI_F) a += 2.0f * PI_F;
	return a;
}
inline float frac(float x) { return x - std::floor(x); }
inline Vector3 flat(Vector3 v) {
	v.y = 0;
	return v;
}
// Rest faces +Z. yaw turns +Z toward +X (the body's left).
inline Vector3 yaw_fwd(float yaw) { return Vector3(std::sin(yaw), 0, std::cos(yaw)); }
inline Vector3 yaw_left(float yaw) { return Vector3(std::cos(yaw), 0, -std::sin(yaw)); }
inline Basis rot_axis(const Vector3 &axis, float angle) { return Basis(axis.normalized(), angle); }
inline Basis yaw_basis(float yaw) { return Basis(UP, yaw); }
inline float yaw_of(const Vector3 &v) { return std::atan2(v.x, v.z); }

// Orthonormal frame with columns x, y (y made perpendicular to x), z = x cross y.
inline Basis frame(Vector3 x, Vector3 y) {
	x = x.normalized();
	y = y - x * x.dot(y);
	if (y.length_squared() < 1e-10f) {
		y = std::fabs(x.y) < 0.9f ? UP - x * x.y : Vector3(1, 0, 0) - x * x.x;
	}
	y = y.normalized();
	Vector3 z = x.cross(y);
	Basis b;
	b.set_column(0, x);
	b.set_column(1, y);
	b.set_column(2, z);
	return b;
}
// The rotation that takes frame (x0,y0) onto frame (x1,y1).
inline Basis frame_delta(const Vector3 &x0, const Vector3 &y0, const Vector3 &x1, const Vector3 &y1) {
	return frame(x1, y1) * frame(x0, y0).transposed();
}
inline Quaternion qslerp(const Quaternion &a, const Quaternion &b, float t) {
	Quaternion bb = b;
	if (a.dot(b) < 0) bb = -b;
	return a.slerp(bb, t).normalized();
}
// Twist angle of rotation q about unit axis a (swing-twist decomposition).
inline float twist_angle(const Quaternion &q, const Vector3 &a) {
	float p = q.x * a.x + q.y * a.y + q.z * a.z;
	return 2.0f * std::atan2(p, q.w);
}
inline float angle_between(const Vector3 &a, const Vector3 &b) {
	float d = clampf(a.normalized().dot(b.normalized()), -1.0f, 1.0f);
	return std::acos(d);
}
// Exponential smoothing toward target with time constant tau.
inline float approach(float cur, float target, float tau, float dt) {
	if (tau <= 0) return target;
	return target + (cur - target) * std::exp(-dt / tau);
}
inline Vector3 approach(const Vector3 &cur, const Vector3 &target, float tau, float dt) {
	if (tau <= 0) return target;
	return target + (cur - target) * std::exp(-dt / tau);
}
inline float approach_angle(float cur, float target, float tau, float dt) {
	return cur + wrap_pi(target - cur) * (1.0f - std::exp(-dt / tau));
}
// Smooth minimum (polynomial), k = blend width.
inline float smin(float a, float b, float k) {
	float h = clampf(0.5f + 0.5f * (b - a) / k, 0.0f, 1.0f);
	return lerpf(b, a, h) - k * h * (1.0f - h);
}

// Critically damped spring for a scalar (value + velocity), natural frequency w.
struct Spring1 {
	float x = 0, v = 0;
	void step(float target, float w, float dt) {
		float a = w * w * (target - x) - 2.0f * w * v;
		v += a * dt;
		x += v * dt;
	}
};
struct Spring3 {
	Vector3 x, v;
	void step(const Vector3 &target, float w, float dt) {
		Vector3 a = (target - x) * (w * w) - v * (2.0f * w);
		v += a * dt;
		x += v * dt;
	}
};

} // namespace lab
