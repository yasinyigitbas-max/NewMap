// The path a car takes through a junction from the end of one lane to the start of another. ONE function, used by the
// street tool (which checks every such path against the built ground) and by the traffic core (which drives on it),
// so what was checked is what is driven.
// From the old game's traffic core (traffic_setup.cpp build_connectors): a cubic Bezier tangent to both lanes; where
// that would loop or overshoot (the two ends side by side in a wide junction), a quadratic through the point where
// the two lanes' directions meet.
#pragma once

#include <algorithm>
#include <cmath>
#include <vector>

namespace sg {

// a = the last point of the lane that arrives, (adx, adz) its direction there; b = the first point of the lane that
// leaves, (bdx, bdz) its direction there (unit vectors). Heights run evenly from ay to by. Appends x, y, z per point.
// p_reach: how far the curve keeps to each lane's own direction before it turns, as a share of the distance between
// the two ends (0.4 = the old game's curve; more = a wider turn that goes deeper into the junction first). The street
// tool picks it per path so that a car on the path keeps off the kerbs, and stores it with the connection.
inline void junction_path(float ax, float ay, float az, float adx, float adz, float bx, float by, float bz, float bdx, float bdz, float p_reach, std::vector<float> &out) {
	const float dist = std::sqrt((bx - ax) * (bx - ax) + (bz - az) * (bz - az));
	if (dist < 0.3f) {
		out.push_back(ax); out.push_back(ay); out.push_back(az);
		out.push_back(bx); out.push_back(by); out.push_back(bz);
		return;
	}
	const float k = dist * p_reach;
	const int n = std::max(4, (int)(dist / 1.5f));
	const size_t base = out.size();
	auto bez = [&](bool quad, float cx, float cz) {
		out.resize(base);
		for (int i = 0; i <= n; i++) {
			const float u = (float)i / n, w = 1.0f - u;
			float px, pz;
			if (!quad) {
				const float c1x = ax + adx * k, c1z = az + adz * k, c2x = bx - bdx * k, c2z = bz - bdz * k;
				px = w * w * w * ax + 3 * w * w * u * c1x + 3 * w * u * u * c2x + u * u * u * bx;
				pz = w * w * w * az + 3 * w * w * u * c1z + 3 * w * u * u * c2z + u * u * u * bz;
			} else {
				px = w * w * ax + 2 * w * u * cx + u * u * bx;
				pz = w * w * az + 2 * w * u * cz + u * u * bz;
			}
			out.push_back(px); out.push_back(ay + (by - ay) * u); out.push_back(pz);
		}
	};
	bez(false, 0, 0);
	auto adiff = [](float a, float b) {
		float d = std::fmod(b - a + 3.14159265f, 6.2831853f);
		if (d < 0) d += 6.2831853f;
		return d - 3.14159265f;
	};
	const float want = adiff(std::atan2(adx, adz), std::atan2(bdx, bdz));
	float turned = 0.0f;
	const int np = (int)(out.size() - base) / 3;
	for (int i = 1; i + 1 < np; i++) {
		const float *p = &out[base + (size_t)i * 3];
		const float d0x = p[0] - p[-3], d0z = p[2] - p[-1], d1x = p[3] - p[0], d1z = p[5] - p[2];
		if (d0x * d0x + d0z * d0z > 1e-8f && d1x * d1x + d1z * d1z > 1e-8f) turned += adiff(std::atan2(d0x, d0z), std::atan2(d1x, d1z));
	}
	if (std::fabs(turned - want) > 0.6f) {
		const float cr = adx * bdz - adz * bdx;
		float cx = (ax + bx) * 0.5f, cz = (az + bz) * 0.5f;
		if (std::fabs(cr) > 1e-3f) {
			const float wx = bx - ax, wz = bz - az;
			const float ta = (wx * bdz - wz * bdx) / cr, tb = (wx * adz - wz * adx) / cr;
			if (ta > 0.0f && tb > 0.0f) { cx = ax + adx * ta; cz = az + adz * ta; }
		}
		bez(true, cx, cz);
	}
}

} // namespace sg
