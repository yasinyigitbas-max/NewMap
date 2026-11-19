// The physical car: see veh_dyn.h for the model. Plain C++.
#include "veh_dyn.h"

#include <algorithm>

namespace vd {

namespace {
constexpr float RAY_M = 0.30f;   // the wheel's ray starts this far above the top of its travel
constexpr float SMAX = 1.6f;     // the tread bends no further than this many times its relaxation length
constexpr float RPM = 9.5493f;   // rad/s -> revs a minute
constexpr float AIR = 0.6f;      // half the air's density
inline float sgn(float v) { return v < 0.0f ? -1.0f : 1.0f; }
}

void Car::init(const Spec &p_spec) {
	s = p_spec;
	inertia[0] = s.mass * (s.length * s.length + s.height * s.height) / 12.0f * 0.85f;
	inertia[1] = s.mass * (s.length * s.length + s.width * s.width) / 12.0f * 0.90f;
	inertia[2] = s.mass * (s.width * s.width + s.height * s.height) / 12.0f * 0.95f;
	const float a = s.wheelbase * (1.0f - s.front_share), b = s.wheelbase * s.front_share;
	for (int i = 0; i < 4; i++) {
		Wheel &w = wh[i];
		w = Wheel();
		w.front = i < 2;
		const bool left = (i & 1) == 0;
		const float half = 0.5f * (w.front ? s.track_f : s.track_r);
		w.hub0 = { left ? half : -half, s.wheel_r - s.cg_h, w.front ? a : -b };
		const float mc = s.mass * (w.front ? s.front_share : 1.0f - s.front_share) * 0.5f;
		const float wn = 6.2832f * (w.front ? s.freq_f : s.freq_r);
		w.k = mc * wn * wn;
		w.c_bump = 2.0f * s.damp_bump * std::sqrt(w.k * mc);
		w.c_reb = 2.0f * s.damp_rebound * std::sqrt(w.k * mc);
		w.load0 = mc * G;
		w.preload = w.load0 / w.k;
		w.arb = w.k * (w.front ? s.arb_f : s.arb_r);
		w.roll_centre = w.front ? s.roll_centre_f : s.roll_centre_r;
		w.grip = w.front ? s.grip_front : s.grip_rear;
		w.driven = s.drive == DRIVE_ALL || (s.drive == DRIVE_FRONT) == w.front;
		w.load = w.load0;
	}
	// the grip curve: 1 at the peak, `slide` far beyond it
	curve_c = 0.63662f * (3.14159f - std::asin(clampf(s.slide, 0.5f, 0.995f)));
	curve_b = std::tan(1.5708f / curve_c);
	eng_w = s.rpm_idle / RPM;
	gear = 1; shift_t = 0; clutch = 0; steer_now = 0; speed = 0; lat_g = long_g = 0;
}

void Car::ray(int i, const Chassis &c, V3 &r_from, V3 &r_dir, float &r_len) const {
	const Wheel &w = wh[i];
	r_from = c.p + rot(c.q, V3{ w.hub0.x, w.hub0.y + s.travel_up + RAY_M, w.hub0.z });
	r_dir = rot(c.q, V3{ 0, -1, 0 });
	r_len = s.travel_up + RAY_M + s.travel_down + s.wheel_r;
}

float Car::engine_torque(float w, float thr) const {
	const float r = w * RPM;
	float sh;
	if (r < s.rpm_torque) { const float x = (s.rpm_torque - r) / s.rpm_torque; sh = 1.0f - 0.55f * x * x; }
	else { const float x = (r - s.rpm_torque) / std::max(s.rpm_red - s.rpm_torque, 1.0f); sh = 1.0f - 0.32f * x * x; }
	if (r > s.rpm_red) thr = 0.0f;   // the limiter
	return thr * s.torque * std::max(sh, 0.0f) - s.torque * (0.05f + 0.11f * r / s.rpm_red);
}

// The steering wheel: how far it may turn at this speed, how fast a hand turns it, and its own pull toward a slide
void Car::steering(const Chassis &c, float dt) {
	const V3 fw = rot(c.q, V3{ 0, 0, 1 }), lf = rot(c.q, V3{ 1, 0, 0 });
	const float vf = dot(c.v, fw), vl = dot(c.v, lf), sp = std::fabs(vf);
	const float peak = s.slip_peak_deg * 0.017453f, lock_max = s.lock_deg * 0.017453f;
	// no more lock than the tyres can use at this speed (the turn they can hold + a little past their peak)
	const float usable = std::atan(s.wheelbase * s.mu * G / std::max(sp * sp, 1.0f)) + 1.5f * peak;
	float target = clampf(in.steer, -1.0f, 1.0f) * std::min(lock_max, usable);
	if (vf > 4.0f && s.steer_assist > 0.0f)   // sliding: the wheel eases toward where the car is really going
		target = clampf(target + s.steer_assist * std::atan2(vl, sp) * clampf((vf - 4.0f) / 6.0f, 0.0f, 1.0f), -lock_max, lock_max);
	float rate = s.steer_rate / (1.0f + sp / 22.0f);
	if (std::fabs(target) < std::fabs(steer_now)) rate *= 1.5f;   // it comes back faster than it goes
	steer_now += clampf(target - steer_now, -rate * dt, rate * dt);
	// the inner wheel turns more than the outer
	const float t = std::tan(steer_now), half = 0.5f * s.track_f;
	wh[FL].steer = std::atan(s.wheelbase * t / (s.wheelbase - half * t));
	wh[FR].steer = std::atan(s.wheelbase * t / (s.wheelbase + half * t));
}

void Car::substep(Chassis &c, float dt, bool move) {
	const V3 lf = rot(c.q, V3{ 1, 0, 0 }), up = rot(c.q, V3{ 0, 1, 0 }), fw = rot(c.q, V3{ 0, 0, 1 });
	V3 F{ 0, -s.mass * G, 0 }, T{};
	{   // the air: drag against the motion, downforce into the ground
		const float sp = len(c.v);
		F = F - c.v * (AIR * s.cda * sp) - up * (AIR * s.cla * sp * sp);
	}
	const float tan_peak = std::tan(s.slip_peak_deg * 0.017453f);

	// ---- where each wheel stands on its spring
	float tt[4];
	for (int i = 0; i < 4; i++) {
		Wheel &w = wh[i];
		w.ground = false;
		const float un = w.hit ? dot(up, w.cn) : 0.0f;
		if (un > 0.25f) {
			const V3 o = c.p + rot(c.q, V3{ w.hub0.x, w.hub0.y + s.travel_up + RAY_M, w.hub0.z });
			tt[i] = dot(o - w.cp, w.cn) / un;
			const float comp = s.travel_up + RAY_M - (tt[i] - s.wheel_r);
			if (comp >= -s.travel_down) { w.ground = true; w.comp = std::min(comp, s.travel_up + 0.15f); }
		}
		if (!w.ground) { w.comp = -s.travel_down; w.comp_v = 0; w.load = 0; w.fx = w.fy = 0; w.slip = 0; w.xi_x *= 0.9f; w.xi_y *= 0.9f; }
	}

	// ---- spring and tyre of each wheel on the ground
	for (int i = 0; i < 4; i++) {
		Wheel &w = wh[i];
		if (!w.ground) continue;
		const V3 o = c.p + rot(c.q, V3{ w.hub0.x, w.hub0.y + s.travel_up + RAY_M, w.hub0.z });
		const V3 cpt = o - up * tt[i];
		const V3 r = cpt - c.p;
		const V3 vc = c.v + cross(c.w, r);
		w.comp_v = -dot(vc, w.cn);
		float fs = w.k * (w.comp + w.preload) + (w.comp_v > 0.0f ? w.c_bump : w.c_reb) * w.comp_v;
		const float over = w.comp - 0.8f * s.travel_up;
		if (over > 0.0f) fs += 4.0f * w.k * over;            // the bump stop
		fs += w.arb * (w.comp - wh[i ^ 1].comp);              // the anti-roll bar
		fs = clampf(fs, 0.0f, 8.0f * w.load0);
		w.load = fs;

		// the tyre's own directions on the ground
		const float st = w.front ? w.steer : 0.0f;
		const V3 hd = fw * std::cos(st) + lf * std::sin(st);
		const V3 tf = norm(hd - w.cn * dot(hd, w.cn));
		const V3 tl = cross(w.cn, tf);
		const float vlong = dot(vc, tf), vlat = dot(vc, tl), va = std::fabs(vlong);
		const float vsx = w.omega * s.wheel_r - vlong;
		// the tread's bend: grows with the slip, is rolled out as the wheel turns
		w.xi_x = (w.xi_x + vsx * dt) / (1.0f + va * dt / s.relax_x);
		w.xi_y = (w.xi_y + vlat * dt) / (1.0f + va * dt / s.relax_y);
		const float sx = clampf(w.xi_x / s.relax_x, -SMAX, SMAX), sy = clampf(w.xi_y / s.relax_y, -SMAX, SMAX);
		w.xi_x = sx * s.relax_x; w.xi_y = sy * s.relax_y;
		float mu = s.mu * w.cmu * w.grip * (1.0f - s.mu_load * (fs / w.load0 - 1.0f));
		mu = clampf(mu, 0.35f * s.mu * w.cmu, 1.12f * s.mu * w.cmu * w.grip);
		const float fmax = mu * fs;
		const float nx = sx / s.ratio_peak, ny = sy / tan_peak, sig = std::sqrt(nx * nx + ny * ny);
		float fx = 0.0f, fy = 0.0f;
		if (sig > 1.0e-6f) { const float g = grip_curve(sig); fx = fmax * g * nx / sig; fy = -fmax * g * ny / sig; }
		{   // standing and creeping: the bend is a spring, this is its damper (fades out with speed)
			const float lo = 1.0f / (1.0f + va * va * 0.5f), mw = fs / G, bc = curve_b * curve_c;
			const float cy = 1.2f * std::sqrt(fmax * bc / (tan_peak * s.relax_y) * mw);
			const float cx = std::min(1.2f * std::sqrt(fmax * bc / (s.ratio_peak * s.relax_x) * mw), 0.5f * s.wheel_inertia / (s.wheel_r * s.wheel_r * dt));
			fy -= cy * lo * vlat; fx += cx * lo * vsx;
		}
		const float fm = std::sqrt(fx * fx + fy * fy);
		if (fm > fmax && fm > 0.0f) { fx *= fmax / fm; fy *= fmax / fm; }   // one circle of grip for both
		w.fx = fx; w.fy = fy; w.slip = sig;
		const V3 f1 = w.cn * fs + tf * fx, f2 = tl * fy;
		F = F + f1 + f2;
		T = T + cross(r, f1) + cross(r + w.cn * w.roll_centre, f2);
	}

	// ---- engine, clutch, gears
	float share[4] = { 0, 0, 0, 0 };
	for (int i = 0; i < 4; i++) {
		if (!wh[i].driven) continue;
		share[i] = s.drive == DRIVE_ALL ? 0.5f * (wh[i].front ? s.awd_front : 1.0f - s.awd_front) : 0.5f;
	}
	auto input_w = [&](const float *wv) { float a = 0; for (int i = 0; i < 4; i++) a += share[i] * wv[i]; return a; };
	float wnow[4] = { wh[0].omega, wh[1].omega, wh[2].omega, wh[3].omega };
	if (in.dir != 1) gear = 1;
	shift_t = std::max(0.0f, shift_t - dt);
	const float thr = clampf(in.throttle, 0.0f, 1.0f);
	if (in.dir == 1 && shift_t <= 0.0f) {   // change by the revs the wheels ask for and by the pedal
		const float rin = input_w(wnow) * s.ratio[gear - 1] * s.final_drive * RPM;
		const float up_r = s.rpm_red * (0.42f + 0.50f * thr), down_r = s.rpm_red * (0.20f + 0.30f * thr);
		if (gear < s.gears && rin > up_r) { gear++; shift_t = s.shift_s; }
		else if (gear > 1 && rin < down_r && rin * s.ratio[gear - 2] / s.ratio[gear - 1] < 0.92f * s.rpm_red) { gear--; shift_t = s.shift_s; }
	}
	const float gr = in.dir == 1 ? s.ratio[gear - 1] * s.final_drive : (in.dir == -1 ? -s.ratio_rev * s.final_drive : 0.0f);
	const float w_idle = s.rpm_idle / RPM;
	float te = engine_torque(eng_w, thr);
	if (eng_w < w_idle) te += clampf((w_idle - eng_w) * 0.04f * s.torque, 0.0f, 0.7f * s.torque);   // the idle holds itself
	float cap = 0.0f;
	clutch = 0.0f;
	if (gr != 0.0f) {   // the take-up: open at idle, closed well above it; a touch of creep with the brakes off
		float e = clampf((eng_w - 1.05f * w_idle) / (0.9f * w_idle), 0.0f, 1.0f);
		if (in.brake < 0.05f && in.handbrake < 0.05f) e = std::max(e, 0.05f);
		if (shift_t > 0.0f) { const float u = shift_t / s.shift_s; e *= u > 0.45f ? 0.0f : 1.0f - u / 0.45f; }   // the cut in pull of a gear change
		cap = e * 1.8f * s.torque; clutch = e;
	}
	float ew = eng_w + te / s.engine_inertia * dt;
	float wn[4];
	for (int i = 0; i < 4; i++) {
		const Wheel &w = wh[i];
		const float tq = -w.fx * s.wheel_r - s.rolling * w.load * s.wheel_r * clampf(w.omega * 2.0f, -1.0f, 1.0f);
		wn[i] = w.omega + tq / s.wheel_inertia * dt;
	}
	if (cap > 0.0f) {   // the clutch passes what would lock engine and wheels together, up to what it can hold
		float s2 = 0; for (int i = 0; i < 4; i++) s2 += share[i] * share[i];
		const float den = 1.0f / s.engine_inertia + gr * gr * s2 / s.wheel_inertia;
		const float tc = clampf((ew - gr * input_w(wn)) / (dt * den), -cap, cap);
		ew -= tc / s.engine_inertia * dt;
		for (int i = 0; i < 4; i++) wn[i] += tc * gr * share[i] / s.wheel_inertia * dt;
	}
	eng_w = clampf(ew, 0.5f * w_idle, 1.08f * s.rpm_red / RPM);
	for (int a = 0; a < 4; a += 2) {   // a little lock across each driven axle
		if (!wh[a].driven) continue;
		const float d = wn[a] - wn[a + 1];
		const float tq = sgn(d) * std::min(s.diff_lock * std::fabs(d), 0.25f * s.wheel_inertia * std::fabs(d) / dt);
		wn[a] -= tq / s.wheel_inertia * dt; wn[a + 1] += tq / s.wheel_inertia * dt;
	}
	// ---- brakes: a wheel the brake can stop within this step is locked
	const float t_all = s.brake_g * s.mass * G * s.wheel_r * clampf(in.brake, 0.0f, 1.0f);
	const float vbody = std::fabs(dot(c.v, fw));
	for (int i = 0; i < 4; i++) {
		Wheel &w = wh[i];
		float tb = t_all * 0.5f * (w.front ? s.brake_front : 1.0f - s.brake_front);
		if (s.abs && w.ground && vbody > 3.0f && w.xi_x / s.relax_x < -1.3f * s.ratio_peak) tb *= 0.25f;   // ABS lets go of a locking wheel
		if (!w.front) tb += clampf(in.handbrake, 0.0f, 1.0f) * s.handbrake_g * 1.5f * w.load0 * s.wheel_r;
		const float dw = tb / s.wheel_inertia * dt;
		if (std::fabs(wn[i]) <= dw) wn[i] = 0.0f; else wn[i] -= sgn(wn[i]) * dw;
		w.omega = wn[i];
		w.angle += w.omega * dt;
		if (w.angle > 6283.0f || w.angle < -6283.0f) w.angle = 0.0f;
	}

	// ---- the body
	c.v = c.v + F * (dt / s.mass);
	{
		V3 wb = irot(c.q, c.w);
		const V3 tb = irot(c.q, T);
		const V3 gy = cross(wb, V3{ inertia[0] * wb.x, inertia[1] * wb.y, inertia[2] * wb.z });
		wb.x += (tb.x - gy.x) / inertia[0] * dt; wb.y += (tb.y - gy.y) / inertia[1] * dt; wb.z += (tb.z - gy.z) / inertia[2] * dt;
		c.w = rot(c.q, wb);
	}
	c.p = c.p + c.v * dt;
	spin(c.q, c.w, dt);
	(void)move;
}

void Car::step(Chassis &c, float dt, int n, bool move) {
	steering(c, dt);
	const Chassis c0 = c;
	const float h = dt / (float)std::max(n, 1);
	for (int k = 0; k < std::max(n, 1); k++) substep(c, h, move);
	const V3 a = (c.v - c0.v) * (1.0f / dt) + V3{ 0, G, 0 };   // what the body feels
	const V3 lf = rot(c.q, V3{ 1, 0, 0 }), fw = rot(c.q, V3{ 0, 0, 1 });
	const float u = clampf(dt * 8.0f, 0.0f, 1.0f);
	lat_g += (dot(a, lf) / G - lat_g) * u; long_g += (dot(a, fw) / G - long_g) * u;
	speed = dot(c.v, fw);
	if (!move) { c.p = c0.p; c.q = c0.q; }   // the engine's body keeps its own place; only speed and spin go back
}

// ---------------------------------------------------------------- the cars of this map
namespace {
struct Base {
	float mass, length, width, height, cg, wheelbase, front_share, wheel_r;
	int drive;
	float torque, idle, rpm_t, red;
	int box;       // 0 = five gears, 1 = six, 2 = seven (sports), 3 = bus
	float cda;
	int kind;      // 0 car, 1 sports, 2 heavy (pickup, van), 3 bus
};
// car_models.h order. Sizes are the meshes' own; weights, engines and gearing are those of real cars of each kind.
const Base BASE[12] = {
	{ 1780, 5.16f, 2.08f, 1.41f, 0.55f, 3.02f, 0.52f, 0.34f, DRIVE_REAR, 370, 750, 4000, 6400, 1, 0.70f, 0 },    // stern_e, a large saloon
	{ 1280, 4.32f, 1.72f, 1.46f, 0.54f, 2.55f, 0.61f, 0.31f, DRIVE_FRONT, 205, 800, 4200, 6500, 0, 0.66f, 0 },   // volt_s, a compact
	{ 1520, 4.28f, 1.88f, 1.52f, 0.56f, 2.62f, 0.54f, 0.33f, DRIVE_REAR, 280, 800, 4200, 6500, 1, 0.70f, 0 },    // stern_g, a saloon
	{ 1650, 4.28f, 1.88f, 1.52f, 0.63f, 2.62f, 0.57f, 0.35f, DRIVE_ALL, 300, 800, 3800, 6200, 1, 0.78f, 0 },     // volt_x, a crossover
	{ 2150, 5.22f, 2.10f, 1.85f, 0.72f, 3.25f, 0.57f, 0.39f, DRIVE_REAR, 470, 700, 3200, 5200, 1, 1.05f, 2 },    // sakura_t, a pickup
	{ 1120, 3.84f, 1.82f, 1.45f, 0.53f, 2.38f, 0.62f, 0.30f, DRIVE_FRONT, 165, 850, 4400, 6800, 0, 0.64f, 0 },   // sakura, a small car
	{ 2250, 4.90f, 2.36f, 1.93f, 0.80f, 3.10f, 0.55f, 0.36f, DRIVE_REAR, 330, 750, 2800, 4800, 1, 1.25f, 2 },    // van
	{ 1390, 4.34f, 1.96f, 1.34f, 0.44f, 2.60f, 0.43f, 0.34f, DRIVE_REAR, 540, 950, 5600, 8200, 2, 0.62f, 1 },    // fiamma_r, a sports car
	{ 1560, 4.40f, 1.88f, 1.38f, 0.46f, 2.68f, 0.49f, 0.34f, DRIVE_REAR, 620, 900, 4800, 7500, 2, 0.64f, 1 },    // fiamma_gt
	{ 1820, 5.20f, 2.08f, 1.53f, 0.57f, 3.02f, 0.53f, 0.34f, DRIVE_REAR, 330, 750, 3800, 6000, 1, 0.74f, 0 },    // taxi
	{ 12500, 12.2f, 2.60f, 3.08f, 1.25f, 5.90f, 0.38f, 0.48f, DRIVE_REAR, 1250, 600, 1300, 2400, 3, 4.6f, 3 },   // bus_city
	{ 4600, 7.42f, 2.38f, 2.65f, 0.98f, 4.20f, 0.42f, 0.39f, DRIVE_REAR, 520, 700, 2000, 3800, 3, 3.2f, 3 },     // bus_mini
};
const float BOX[4][MAX_GEARS] = {
	{ 3.55f, 1.95f, 1.30f, 0.97f, 0.76f, 0, 0, 0 },
	{ 4.17f, 2.34f, 1.52f, 1.14f, 0.87f, 0.69f, 0, 0 },
	{ 3.40f, 2.20f, 1.60f, 1.25f, 1.00f, 0.84f, 0.70f, 0 },
	{ 6.90f, 4.10f, 2.50f, 1.55f, 1.00f, 0.72f, 0, 0 },
};
const int BOX_N[4] = { 5, 6, 7, 6 };
const float BOX_FINAL[4] = { 4.05f, 3.20f, 3.85f, 5.60f };
}

Spec make_spec(int model, int feel) {
	const Base &b = BASE[model < 0 || model > 11 ? 2 : model];
	Spec s;
	s.mass = b.mass; s.length = b.length; s.width = b.width; s.height = b.height; s.cg_h = b.cg;
	s.wheelbase = b.wheelbase; s.front_share = b.front_share; s.wheel_r = b.wheel_r;
	s.track_f = s.track_r = b.width - (b.kind == 3 ? 0.42f : 0.34f);
	s.wheel_inertia = (b.kind == 3 ? 9.0f : 11.0f) * b.wheel_r * b.wheel_r * (b.kind == 3 ? 4.0f : 1.0f);
	s.drive = b.drive; s.torque = b.torque; s.rpm_idle = b.idle; s.rpm_torque = b.rpm_t; s.rpm_red = b.red;
	s.engine_inertia = b.kind == 3 ? 1.6f : (b.kind == 1 ? 0.14f : 0.20f);
	s.gears = BOX_N[b.box]; s.final_drive = BOX_FINAL[b.box];
	for (int k = 0; k < MAX_GEARS; k++) s.ratio[k] = BOX[b.box][k];
	s.ratio_rev = BOX[b.box][0] * 0.85f;
	s.shift_s = b.kind == 1 ? 0.18f : (b.kind == 3 ? 0.6f : 0.32f);
	s.cda = b.cda;
	const bool v = feel == FEEL_V;
	// the two feels: IV = soft springs, little damping, a low roll centre (it leans, dives and squats), tyres that
	// let go early and gently; V = stiffer and flatter, more grip, quicker hands, ABS
	s.freq_f = v ? 1.50f : 1.10f; s.freq_r = v ? 1.70f : 1.25f;
	s.damp_bump = v ? 0.35f : 0.22f; s.damp_rebound = v ? 0.55f : 0.36f;
	s.travel_up = v ? 0.09f : 0.11f; s.travel_down = v ? 0.10f : 0.13f;
	s.arb_f = v ? 0.5f : 0.25f; s.arb_r = v ? 0.35f : 0.15f;
	s.roll_centre_f = v ? 0.10f : 0.04f; s.roll_centre_r = v ? 0.14f : 0.08f;
	s.mu = v ? 1.10f : 0.90f; s.slip_peak_deg = v ? 7.5f : 9.5f; s.slide = v ? 0.92f : 0.86f;
	s.steer_rate = v ? 3.0f : 2.0f; s.steer_assist = v ? 0.5f : 0.2f;
	s.abs = v; s.brake_g = v ? 1.25f : 1.0f; s.cla = v ? 0.25f : 0.0f;
	s.lock_deg = 36.0f;
	if (b.kind == 1) {   // sports: stiffer, lower, wider tyres, a tighter differential
		s.freq_f *= 1.25f; s.freq_r *= 1.25f; s.arb_f *= 1.4f; s.arb_r *= 1.4f; s.mu *= 1.10f; s.slip_peak_deg -= 1.0f;
		s.travel_up -= 0.02f; s.travel_down -= 0.03f; s.diff_lock = 90.0f; s.brake_g *= 1.1f; s.cla += 0.35f; s.steer_rate *= 1.15f;
	} else if (b.kind == 2) {   // pickup and van: tall, on hard narrow tyres
		s.mu *= 0.92f; s.slip_peak_deg += 1.0f; s.freq_r *= 1.1f; s.steer_rate *= 0.85f; s.travel_up += 0.02f; s.travel_down += 0.02f;
	} else if (b.kind == 3) {   // buses: the same in both feels
		s.freq_f = 1.25f; s.freq_r = 1.45f; s.damp_bump = 0.3f; s.damp_rebound = 0.5f; s.arb_f = 0.6f; s.arb_r = 0.6f;
		s.mu = 0.80f; s.slip_peak_deg = 8.0f; s.slide = 0.9f; s.lock_deg = 44.0f; s.steer_rate = 1.2f; s.steer_assist = 0.1f;
		s.brake_g = 0.75f; s.abs = true; s.travel_up = 0.10f; s.travel_down = 0.12f; s.roll_centre_f = 0.3f; s.roll_centre_r = 0.4f;
		s.diff_lock = 150.0f; s.cla = 0.0f; s.brake_front = 0.5f;
	}
	if (b.drive == DRIVE_FRONT) s.brake_front = 0.68f;
	return s;
}

} // namespace vd
