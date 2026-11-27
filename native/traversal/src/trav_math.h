// The number work of the script version, done the way GDScript does it, so that the C++ version gives the same
// numbers tick for tick: a GDScript `float` is a 64-bit double, a Vector3's parts are 32-bit floats, and the global
// functions (wrapf, lerpf, rotate_toward ...) work in doubles. These are the engine's own formulas
// (core/math/math_funcs.h, 4.7), written out here because godot-cpp's versions follow real_t (a float).
#pragma once

#include <cmath>

namespace trav {

const double PI = 3.14159265358979323846;
const double TAU = 6.28318530717958647692;
const double CMP_EPS = 0.00001;

inline double minf(double a, double b) { return a < b ? a : b; }
inline double maxf(double a, double b) { return a > b ? a : b; }
inline double absf(double a) { return a < 0.0 ? -a : a; }
inline double clampf(double v, double lo, double hi) { return v < lo ? lo : (v > hi ? hi : v); }
inline double lerpf(double a, double b, double t) { return a + (b - a) * t; }
inline double signf(double a) { return a > 0.0 ? 1.0 : (a < 0.0 ? -1.0 : 0.0); }
inline double deg_to_rad(double d) { return d * (PI / 180.0); }
inline double rad_to_deg(double r) { return r * (180.0 / PI); }

inline bool is_equal_approx(double a, double b) {
	if (a == b) {
		return true;
	}
	double tolerance = CMP_EPS * absf(a);
	if (tolerance < CMP_EPS) {
		tolerance = CMP_EPS;
	}
	return absf(a - b) < tolerance;
}

inline bool is_zero_approx(double s) { return absf(s) < CMP_EPS; }

inline double wrapf(double value, double min, double max) {
	double range = max - min;
	if (is_zero_approx(range)) {
		return min;
	}
	double result = value - (range * std::floor((value - min) / range));
	if (is_equal_approx(result, max)) {
		return min;
	}
	return result;
}

inline double angle_difference(double from, double to) {
	double difference = std::fmod(to - from, TAU);
	return std::fmod(2.0 * difference, TAU) - difference;
}

inline double rotate_toward(double from, double to, double delta) {
	double difference = angle_difference(from, to);
	double abs_difference = absf(difference);
	return from + clampf(delta, abs_difference - PI, abs_difference) * (difference >= 0.0 ? 1.0 : -1.0);
}

inline double move_toward(double from, double to, double delta) {
	return absf(to - from) <= delta ? to : from + signf(to - from) * delta;
}

} // namespace trav
