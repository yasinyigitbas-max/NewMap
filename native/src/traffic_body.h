// The body of a traffic car: a STEERED car, not a dot on a line. Written new on Yasin's word, 19 Nov 2026 ("cars
// just slide into turns instead of steering into turns, take abrupt u turns").
//
// The old core put a car's middle on its lane's line and pointed its nose along the line: through a bend the whole
// car pivoted about its middle, and a lane change was a sideways slide. Now the core's (s, lat) is only THE LINE THE
// DRIVER AIMS FOR. The body is what a car is: front wheels that turn (at the rate of a driver's hands, no further
// than their lock), a rear axle that follows. The driver looks a few car lengths down his line and steers at that
// point; the heading only changes because the car moves on turned wheels. So it cannot turn on the spot, cannot
// turn tighter than its lock, cannot slide sideways, and a lane change is a steer out and a steer back.
// Plain C++, no state of its own: the caller keeps (x, z, yaw, steer).
#pragma once

#include "traffic_sim.h"

namespace tc {

struct Body { float x, z, yaw, steer; };

struct BodyRun {
	float s_c = 0;      // how far along the line the car's middle came (the window's own scale: 0 = where it was)
	float lat_c = 0;    // the middle's distance from the line's middle after the move, + = left
	float dyaw = 0;     // how far it turned
	bool sat = false;   // the wheel was at its lock and the line bends tighter still
};

// The nearest point of the window's line to (qx, qz), looked for round s_guess: how far along, how far to the side
// (+ = left). The first and the last stretch count as endless straight lines.
inline void win_project(const Window &w, float qx, float qz, float s_guess, float &s_out, float &lat_out) {
	float bd = BIG;
	s_out = s_guess; lat_out = 0.0f;
	for (int k = 0; k < w.n - 1; k++) {
		if (w.s[k + 1] < s_guess - 6.0f && k < w.n - 2) continue;
		if (w.s[k] > s_guess + 6.0f && bd < BIG * 0.5f) break;
		const float ux = w.x[k + 1] - w.x[k], uz = w.z[k + 1] - w.z[k], l2 = ux * ux + uz * uz;
		if (l2 < 1.0e-10f) continue;
		const float t = ((qx - w.x[k]) * ux + (qz - w.z[k]) * uz) / l2;
		const float tc_ = ((k == 0 && t < 0.0f) || (k == w.n - 2 && t > 1.0f)) ? t : (t < 0.0f ? 0.0f : (t > 1.0f ? 1.0f : t));
		const float dx = qx - (w.x[k] + ux * tc_), dz = qz - (w.z[k] + uz * tc_), d2 = dx * dx + dz * dz;
		if (d2 < bd) {
			bd = d2;
			const float sl = std::sqrt(l2);
			s_out = w.s[k] + sl * tc_;
			lat_out = ((qx - w.x[k]) * uz - (qz - w.z[k]) * ux) / sl;
		}
	}
}

// The point of the window's line at s and the line's direction there (beyond its ends: straight on)
inline void win_point(const Window &w, float s, float &ox, float &oz, float &tx, float &tz) {
	int k = 0;
	while (k < w.n - 2 && w.s[k + 1] < s) k++;
	float ux = w.x[k + 1] - w.x[k], uz = w.z[k + 1] - w.z[k];
	const float sl = std::sqrt(ux * ux + uz * uz);
	if (sl > 1.0e-5f) { ux /= sl; uz /= sl; } else { ux = 0.0f; uz = 1.0f; }
	const float d = s - w.s[k];
	ox = w.x[k] + ux * d; oz = w.z[k] + uz * d; tx = ux; tz = uz;
}

constexpr float BODY_STEP = 0.4f;      // metres a car moves between two looks at the road
constexpr float HANDS_RATE = 1.0f;     // how fast a driver turns the front wheels, rad/s
constexpr float SIDE_PUSH = 4.0f;      // the hardest sideways push a driver steers into, m/s^2 (the planner's own bends use 2.2)

// Drive the body d metres. v = its speed (for the look ahead and the hands). The line it aims for lies lat0 to the
// side of the window's line at the start of the move and lat1 at its end. The body FOLLOWS that line (a little behind
// it in a sideways move, never ahead of it: the core has only cleared the way as far as the line has gone).
inline BodyRun body_run(Body &b, const Window &w, float wb, float steer_max, float d, float v, float lat0, float lat1) {
	BodyRun r;
	if (w.n < 2 || d <= 0.0f) { win_project(w, b.x, b.z, 0.0f, r.s_c, r.lat_c); return r; }
	const int n = std::max(1, (int)std::ceil(d / BODY_STEP));
	const float dd = d / (float)n;
	const float yaw0 = b.yaw;
	float sg = -0.5f * wb;
	const float look = std::min(std::max(0.8f * wb + 0.3f * v, 2.6f), 12.0f);
	steer_max = std::min(steer_max, std::atan(wb * SIDE_PUSH / std::max(v * v, 1.0f)));
	for (int k = 0; k < n; k++) {
		const float lref = lat0 + (lat1 - lat0) * ((float)(k + 1) / (float)n);
		const float fx = std::sin(b.yaw), fz = std::cos(b.yaw);
		float rx = b.x - 0.5f * wb * fx, rz = b.z - 0.5f * wb * fz;   // the rear axle
		float sr, lr;
		win_project(w, rx, rz, sg, sr, lr);
		sg = sr;
		float ax, az, t0x, t0z, px, pz, tx, tz;
		win_point(w, sr, ax, az, t0x, t0z);
		win_point(w, sr + look, px, pz, tx, tz);
		// how much the line bends over the look ahead: the rear axle runs that much inside, so the car's MIDDLE is on the line
		const float bend = std::atan2(tx * t0z - tz * t0x, t0x * tx + t0z * tz) / look;
		const float off = lref + wb * wb * bend * 0.125f;
		const float ex = px + tz * off - rx, ez = pz - tx * off - rz;
		const float side = ex * fz - ez * fx;
		float want = std::atan(wb * 2.0f * side / std::max(ex * ex + ez * ez, 1.0f));
		if (want > steer_max) { want = steer_max; r.sat = true; } else if (want < -steer_max) { want = -steer_max; r.sat = true; }
		const float turn = HANDS_RATE * dd / std::max(v, 1.5f);
		b.steer += std::min(std::max(want - b.steer, -turn), turn);
		const float dyaw = dd * std::tan(b.steer) / wb, ym = b.yaw + 0.5f * dyaw;
		rx += dd * std::sin(ym); rz += dd * std::cos(ym);
		b.yaw += dyaw;
		b.x = rx + 0.5f * wb * std::sin(b.yaw); b.z = rz + 0.5f * wb * std::cos(b.yaw);
	}
	r.dyaw = b.yaw - yaw0;
	if (b.yaw > 3.14159265f) b.yaw -= 6.2831853f; else if (b.yaw < -3.14159265f) b.yaw += 6.2831853f;
	win_project(w, b.x, b.z, sg + 0.5f * wb, r.s_c, r.lat_c);
	return r;
}

} // namespace tc
