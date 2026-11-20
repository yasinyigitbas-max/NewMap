// The car as a physical thing, plain C++ (no Godot types): a rigid body on four sprung wheels with tyres that slip,
// an engine, a clutch, a gearbox and brakes. Written new for this map on Yasin's word, 19 Nov 2026 ("good car
// physics ... ride exactly like gta 4 if not gta 5 ... 100 % in C plus plus").
//
// Who owns the body: the caller. `Car::step` takes the body's state (place, turn, speed, spin), works out every force
// in small steps and leaves the new speed and spin in it. In the game the engine's physics body owns the place (it
// also does the crashes); in the console test (native/tests/veh_test.cpp) this file moves the body itself.
//
// Frame of the body: x = left, y = up, z = forward (right handed), origin at the centre of mass. The same as the
// traffic core: yaw = atan2(fx, fz), a larger yaw turns left.
//
// The model, part by part:
//  - SPRINGS: one ray per wheel straight down the body. Spring + damper (softer on the way in than on the way out),
//    a bump stop, an anti-roll bar per axle. The side force of a tyre pushes at the roll-centre height, not at the
//    ground: that height sets how much the body leans (low = the GTA 4 lean).
//  - TYRES: each tyre keeps how far its tread is bent forward and sideways (it grows with the slip and relaxes as the
//    wheel rolls on). That one state gives the grip curve at speed (rise, peak, a little less beyond the peak: the
//    slide), the pull of a locked wheel, AND a car that stands still on a hill. Forward and sideways grip share one
//    circle; grip per kilo falls a little as a tyre is loaded.
//  - DRIVE: engine torque by revs, a clutch that takes up from idle like an automatic, gears that change by revs and
//    pedal with a short cut in pull, an open differential with a little lock, front / rear / all wheel drive.
//  - BRAKES by axle share, a handbrake on the rear wheels, ABS on the cars that have it.
//  - STEERING: the lock shrinks with speed to what the tyres can use, the wheel turns at a hand's rate, the inner
//    wheel turns more than the outer, and the wheel eases toward a slide like a real one let loose.
#pragma once

#include <cmath>
#include <cstdint>

namespace vd {

struct V3 { float x = 0, y = 0, z = 0; };
inline V3 operator+(V3 a, V3 b) { return { a.x + b.x, a.y + b.y, a.z + b.z }; }
inline V3 operator-(V3 a, V3 b) { return { a.x - b.x, a.y - b.y, a.z - b.z }; }
inline V3 operator*(V3 a, float s) { return { a.x * s, a.y * s, a.z * s }; }
inline float dot(V3 a, V3 b) { return a.x * b.x + a.y * b.y + a.z * b.z; }
inline V3 cross(V3 a, V3 b) { return { a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x }; }
inline float len(V3 a) { return std::sqrt(dot(a, a)); }
inline V3 norm(V3 a) { const float l = len(a); return l > 1e-9f ? a * (1.0f / l) : V3{ 0, 1, 0 }; }
struct Q { float x = 0, y = 0, z = 0, w = 1; };
inline V3 rot(const Q &q, V3 v) { const V3 u{ q.x, q.y, q.z }; const V3 t = cross(u, v) * 2.0f; return v + t * q.w + cross(u, t); }
inline V3 irot(const Q &q, V3 v) { return rot(Q{ -q.x, -q.y, -q.z, q.w }, v); }
inline void spin(Q &q, V3 w, float dt) {   // turn q by the world spin w for dt
	const Q d{ 0.5f * dt * (w.x * q.w + w.y * q.z - w.z * q.y), 0.5f * dt * (w.y * q.w + w.z * q.x - w.x * q.z),
		0.5f * dt * (w.z * q.w + w.x * q.y - w.y * q.x), 0.5f * dt * (-w.x * q.x - w.y * q.y - w.z * q.z) };
	q.x += d.x; q.y += d.y; q.z += d.z; q.w += d.w;
	const float l = std::sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
	q.x /= l; q.y /= l; q.z /= l; q.w /= l;
}
inline float clampf(float v, float a, float b) { return v < a ? a : (v > b ? b : v); }

enum { DRIVE_FRONT = 0, DRIVE_REAR = 1, DRIVE_ALL = 2 };
enum { FEEL_IV = 0, FEEL_V = 1 };   // the soft, leaning, sliding car of GTA 4; the flatter, grippier car of GTA 5
enum { FL = 0, FR = 1, RL = 2, RR = 3 };
constexpr float G = 9.81f;
constexpr int MAX_GEARS = 8;

// What a car IS (never changes while it drives). Lengths in metres, kilos, seconds.
struct Spec {
	// body
	float mass = 1500.0f;
	float length = 4.5f, width = 1.8f, height = 1.45f;   // for the inertia
	float cg_h = 0.55f;             // centre of mass above the ground at rest
	float wheelbase = 2.7f, track_f = 1.55f, track_r = 1.55f;
	float front_share = 0.55f;      // share of the weight on the front axle
	float wheel_r = 0.33f, wheel_inertia = 1.3f;
	// springs
	float freq_f = 1.2f, freq_r = 1.35f;       // how fast each end bounces, Hz (soft 1.1 ... stiff 2.2)
	float damp_bump = 0.25f, damp_rebound = 0.4f;   // share of critical damping, in and out
	float travel_up = 0.10f, travel_down = 0.12f;
	float arb_f = 0.3f, arb_r = 0.2f;          // anti-roll bar, as a share of the spring rate
	float roll_centre_f = 0.06f, roll_centre_r = 0.10f;   // above the ground
	// tyres
	float mu = 0.95f;               // grip at the static load
	float mu_load = 0.12f;          // grip lost per doubling of the load
	float grip_front = 1.0f, grip_rear = 1.0f;   // balance: less in front = pushes wide, less at the rear = tail out
	float slip_peak_deg = 9.0f;     // slip angle of the most side grip
	float ratio_peak = 0.11f;       // wheel slip of the most pull
	float slide = 0.88f;            // grip left far beyond the peak, share of the peak
	float relax_x = 0.25f, relax_y = 0.38f;    // metres a tyre rolls before its force follows
	float rolling = 0.013f;
	// drive
	int drive = DRIVE_REAR;
	float torque = 300.0f;          // most engine torque, N m
	float rpm_idle = 800.0f, rpm_torque = 4200.0f, rpm_red = 6500.0f;
	float engine_inertia = 0.20f;
	int gears = 6;
	float ratio[MAX_GEARS] = { 4.17f, 2.34f, 1.52f, 1.14f, 0.87f, 0.69f, 0, 0 };
	float ratio_rev = 3.4f, final_drive = 3.2f;
	float shift_s = 0.30f;
	float diff_lock = 30.0f;        // N m per rad/s of difference across the axle
	float awd_front = 0.4f;         // all wheel drive: share of the pull to the front
	// brakes
	float brake_g = 1.05f;          // what the brakes could hold back if the tyres held, in g
	float brake_front = 0.64f;
	float handbrake_g = 0.9f;
	bool abs = false;
	// traction and stability control (B5, Yasin 20 Nov: "car is too prone to slide"): the pedal is eased off while a
	// driven wheel spins past its grip peak or the body slides wider than `tcs_beta_deg`. 0 = none, 1 = all the way
	float tcs = 0.0f;
	float tcs_beta_deg = 7.0f;
	// steering
	float lock_deg = 36.0f;
	float steer_rate = 2.4f;        // rad/s at a standstill
	float steer_assist = 0.25f;     // how much the wheel eases toward a slide by itself (0 none)
	// air
	float cda = 0.68f;              // drag area, m^2
	float cla = 0.0f;               // downforce area
};

struct Wheel {
	// made from the spec
	V3 hub0;                 // the hub at rest, body frame, from the centre of mass
	float k = 0, c_bump = 0, c_reb = 0, preload = 0, arb = 0, load0 = 0, roll_centre = 0, grip = 1;
	bool driven = false, front = false;
	// what the caller tells it before a step: the ground under it
	bool hit = false;
	V3 cp, cn;               // a point of the ground under the wheel and its normal
	float cmu = 1.0f;        // the surface (asphalt 1, wet 0.7, grass 0.55 ...)
	// state
	float omega = 0;         // spin, rad/s (+ = rolling forward)
	float angle = 0;         // how far it has turned (for drawing)
	float steer = 0;         // rad, + = left
	float comp = 0;          // spring: + = pushed in from rest
	float comp_v = 0;
	float load = 0;          // N on the tyre
	float xi_x = 0, xi_y = 0;   // the tread's bend, m
	float fx = 0, fy = 0;    // tyre force along and across the wheel, N
	float slip = 0;          // how hard it works: 1 = at the peak, more = sliding
	bool ground = false;
};

struct Input {
	float throttle = 0, brake = 0, handbrake = 0;   // 0..1
	float steer = 0;        // -1 right .. +1 left
	int dir = 1;            // 1 forward gears, -1 reverse, 0 neutral
};

struct Chassis {
	V3 p;      // centre of mass, world
	Q q;       // body to world
	V3 v, w;   // speed and spin, world
};

class Car {
public:
	Spec s;
	Wheel wh[4];
	Input in;
	// engine and gearbox
	float eng_w = 84.0f;     // rad/s
	int gear = 1;            // 1..gears (forward)
	float shift_t = 0;       // > 0: in the middle of a change
	float clutch = 0;        // 0 open .. 1 closed (told, for sound and tests)
	float tc_gain = 1;       // traction / stability control: the share of the pedal let through (1 = all)
	float steer_now = 0;     // rad, the steering as it stands (the middle of the two front wheels)
	// read by the caller
	float speed = 0;         // m/s along the body's nose
	float lat_g = 0, long_g = 0;   // what the body feels, in g (smoothed)
	float inertia[3] = { 1, 1, 1 };   // about x (pitch), y (yaw), z (roll)

	void init(const Spec &p_spec);
	// Where the ray of wheel i starts and how far it reaches (straight down the body), for the caller's ground query
	void ray(int i, const Chassis &c, V3 &r_from, V3 &r_dir, float &r_len) const;
	void set_ground(int i, bool p_hit, V3 p_point, V3 p_normal, float p_mu) { wh[i].hit = p_hit; wh[i].cp = p_point; wh[i].cn = p_normal; wh[i].cmu = p_mu; }
	// dt seconds in n small steps. move = this file also moves the body (console test); in the game the engine does.
	void step(Chassis &c, float dt, int n, bool move);
	float rpm() const { return eng_w * 9.5493f; }
	// the height of the body's origin (centre of mass) over flat ground at rest
	float rest_height() const { return s.cg_h; }

private:
	float curve_b = 2.0f, curve_c = 1.4f;
	float grip_curve(float sig) const { return std::sin(curve_c * std::atan(curve_b * sig)); }
	float engine_torque(float w, float thr) const;
	void steering(const Chassis &c, float dt);
	void substep(Chassis &c, float dt, bool move);
};

// The cars of this map (car_models.h order) as physical cars, in one of the two feels
Spec make_spec(int model, int feel);

} // namespace vd
