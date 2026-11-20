// A person's body that keeps its own balance: see ped_body.h. Plain C++.
#include "ped_body.h"

#include <algorithm>
#include <cmath>

namespace pb {

using vd::clampf;
using vd::cross;
using vd::dot;
using vd::len;
using vd::norm;
using vd::rot;
using vd::spin;

namespace {
constexpr float GRAV = 9.81f;
constexpr int SUBSTEPS = 8;
constexpr float MU = 0.75f;          // shoes and clothes on a pavement
inline Q qmul(const Q &a, const Q &b) {
	return { a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y, a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
		a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w, a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z };
}
inline Q qconj(const Q &a) { return { -a.x, -a.y, -a.z, a.w }; }
inline Q qaxis(V3 axis, float ang) { const float s = std::sin(ang * 0.5f); return { axis.x * s, axis.y * s, axis.z * s, std::cos(ang * 0.5f) }; }
inline Q qalign(V3 a, V3 b) {   // the shortest turn that takes the direction a to the direction b
	const V3 c = cross(a, b);
	const float d = dot(a, b);
	if (d < -0.9999f) { const V3 ax = norm(cross(a, std::fabs(a.x) < 0.9f ? V3{ 1, 0, 0 } : V3{ 0, 1, 0 })); return { ax.x, ax.y, ax.z, 0 }; }
	Q q{ c.x, c.y, c.z, 1.0f + d };
	const float l = std::sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
	q.x /= l; q.y /= l; q.z /= l; q.w /= l;
	return q;
}
inline V3 qvec(Q q) {   // a turn as axis x angle
	if (q.w < 0) { q.x = -q.x; q.y = -q.y; q.z = -q.z; q.w = -q.w; }
	const float s = std::sqrt(q.x * q.x + q.y * q.y + q.z * q.z);
	if (s < 1.0e-6f) return { 2 * q.x, 2 * q.y, 2 * q.z };
	const float a = 2.0f * std::atan2(s, q.w) / s;
	return { q.x * a, q.y * a, q.z * a };
}
inline float wrap(float a) { while (a > 3.14159265f) a -= 6.2831853f; while (a < -3.14159265f) a += 6.2831853f; return a; }
inline float ess(float u) { u = clampf(u, 0.0f, 1.0f); return u * u * (3.0f - 2.0f * u); }
inline V3 flat(V3 v) { return { v.x, 0, v.z }; }
// the knee between a hip and an ankle (it bends toward `fwd`)
inline V3 knee_of(V3 hip, V3 ankle, float l1, float l2, V3 fwd) {
	V3 d = ankle - hip;
	float L = len(d);
	const V3 u = L > 1.0e-5f ? d * (1.0f / L) : V3{ 0, -1, 0 };
	L = clampf(L, std::fabs(l1 - l2) + 0.01f, l1 + l2 - 0.002f);
	const float a = (l1 * l1 - l2 * l2 + L * L) / (2.0f * L);
	const float h = std::sqrt(std::max(l1 * l1 - a * a, 0.0f));
	const V3 side = norm(fwd - u * dot(fwd, u));
	return hip + u * a + side * h;
}
}

void Person::build(const Rest &p_rest) {
	rest = p_rest;
	const float ms = rest.mass / 72.0f;
	auto set = [&](int i, V3 p0, V3 p1, float r, float m) {
		Body &B = b[i];
		const V3 c = (p0 + p1) * 0.5f;
		const float l = len(p1 - p0);
		B = Body();
		B.x = c; B.a = p0 - c; B.b = p1 - c; B.r = r; B.m = m * ms; B.inv_m = 1.0f / B.m;
		c_rest[i] = c;
		B.inv_i = 1.0f / (B.m * (l * l / 12.0f + 0.4f * r * r));   // one number for every axis: a limb twists a little too slowly, and nothing can blow up
	};
	const V3 up{ 0, 1, 0 };
	set(B_PELVIS, rest.pelvis + V3{ 0.09f, 0.03f, 0 }, rest.pelvis + V3{ -0.09f, 0.03f, 0 }, 0.115f, 11.0f);
	set(B_CHEST, rest.waist + V3{ 0, 0.06f, 0 }, rest.neck + V3{ 0, -0.10f, 0 }, 0.135f, 24.0f);
	set(B_HEAD, rest.head + V3{ 0, 0.02f, 0.01f }, V3{ 0, rest.head_top - 0.10f, rest.head.z + 0.01f }, 0.10f, 5.5f);
	for (int s = 0; s < 2; s++) {
		const V3 fa = norm(rest.wrist[s] - rest.elbow[s]);
		set(s == 0 ? B_UARM_L : B_UARM_R, rest.shoulder[s], rest.elbow[s], 0.045f, 2.1f);
		set(s == 0 ? B_FARM_L : B_FARM_R, rest.elbow[s], rest.wrist[s] + fa * 0.07f, 0.04f, 1.7f);
		set(s == 0 ? B_THIGH_L : B_THIGH_R, rest.hip[s], rest.knee[s], 0.075f, 7.5f);
		set(s == 0 ? B_CALF_L : B_CALF_R, rest.knee[s], rest.ankle[s], 0.055f, 3.4f);
		set(s == 0 ? B_FOOT_L : B_FOOT_R, rest.ankle[s] + V3{ 0, -0.04f, -rest.heel }, rest.ankle[s] + V3{ 0, -0.04f, rest.toe }, 0.045f, 1.1f);
	}
	m_legs = 2.0f * (7.5f + 3.4f + 1.1f) * ms;
	ankle_h = rest.ankle[0].y;
	l_thigh = len(rest.knee[0] - rest.hip[0]); l_calf = len(rest.ankle[0] - rest.knee[0]);
	leg_len = len(rest.ankle[0] - rest.hip[0]);
	leg_k = 20000.0f * ms; leg_pre = rest.mass * GRAV / (2.0f * leg_k); leg_c = 1.2f * std::sqrt(leg_k * rest.mass * 0.5f);
	// joints: where, how far they go, how hard their muscle pulls (N m per rad, N m s per rad, most N m)
	auto joint = [&](int k, int p, int c, V3 at, bool hinge, V3 axis, float lo, float hi, V3 bone, float swing, float twist, float kp, float tmax) {
		Joint &J = j[k];
		J = Joint();
		J.p = p; J.c = c; J.ap = at - b[p].x; J.ac = at - b[c].x; J.hinge = hinge; J.axis = axis; J.lo = lo; J.hi = hi;
		J.bone = bone; J.swing = swing; J.twist = twist; J.kp = kp; J.kd = 0.05f * kp; J.tmax = tmax;
	};
	joint(J_SPINE, B_PELVIS, B_CHEST, rest.waist, false, up, 0, 0, up, 0.55f, 0.5f, 600.0f, 250.0f);
	joint(J_NECK, B_CHEST, B_HEAD, rest.neck, false, up, 0, 0, up, 0.6f, 0.7f, 60.0f, 40.0f);
	for (int s = 0; s < 2; s++) {
		const V3 du = norm(rest.elbow[s] - rest.shoulder[s]);
		const V3 ea = norm(cross(du, V3{ 0, 0, 1 }));   // an elbow bends the forearm forward
		joint(s == 0 ? J_SHOULDER_L : J_SHOULDER_R, B_CHEST, s == 0 ? B_UARM_L : B_UARM_R, rest.shoulder[s], false, up, 0, 0, du, 1.6f, 0.9f, 90.0f, 70.0f);   // (was 1.9 / 1.3 rad: the arm went through the chest)
		joint(s == 0 ? J_ELBOW_L : J_ELBOW_R, s == 0 ? B_UARM_L : B_UARM_R, s == 0 ? B_FARM_L : B_FARM_R, rest.elbow[s], true, ea, -0.05f, 2.3f, du, 0, 0, 50.0f, 45.0f);   // (it bent 20 degrees the wrong way)
		joint(s == 0 ? J_HIP_L : J_HIP_R, B_PELVIS, s == 0 ? B_THIGH_L : B_THIGH_R, rest.hip[s], false, up, 0, 0, norm(norm(rest.knee[s] - rest.hip[s]) + V3{ 0, 0, 0.42f }), 1.15f, 0.45f, 500.0f, 220.0f);   // (a cone tipped forward: a leg goes far forward, little back or across; it went 86 degrees any way)
		joint(s == 0 ? J_KNEE_L : J_KNEE_R, s == 0 ? B_THIGH_L : B_THIGH_R, s == 0 ? B_CALF_L : B_CALF_R, rest.knee[s], true, V3{ 1, 0, 0 }, -0.05f, 2.4f, up, 0, 0, 350.0f, 180.0f);
		joint(s == 0 ? J_ANKLE_L : J_ANKLE_R, s == 0 ? B_CALF_L : B_CALF_R, s == 0 ? B_FOOT_L : B_FOOT_R, rest.ankle[s], false, up, 0, 0, V3{ 0, 0, 1 }, 0.7f, 0.4f, 120.0f, 80.0f);
		// arms hang by the sides, a little bent (the skeleton stands with them held out)
		arm_down[s] = qalign(du, norm(V3{ s == 0 ? 0.10f : -0.10f, -1.0f, 0.05f }));
		j[s == 0 ? J_SHOULDER_L : J_SHOULDER_R].want = arm_down[s];
		j[s == 0 ? J_ELBOW_L : J_ELBOW_R].want = qaxis(ea, 0.15f);
	}
	for (int i = 0; i < NB; i++) { b[i].x0 = b[i].x; }
	start(V3{}, 0.0f, V3{});
}

void Person::start(V3 at, float yaw, V3 vel) {
	const Q qy = qaxis(V3{ 0, 1, 0 }, yaw);
	// the standing pose: each body's centre = its parent's + the joint's two arms (joints are listed parent first)
	V3 c[NB];
	c[B_PELVIS] = rest.pelvis + V3{ 0, 0.03f, 0 };
	for (int k = 0; k < NJ; k++) c[j[k].c] = c[j[k].p] + j[k].ap - j[k].ac;   // (joints are listed parent first)
	for (int i = 0; i < NB; i++) {
		Body &B = b[i];
		B.x = at + rot(qy, c[i]); B.q = qy; B.v = vel; B.w = V3{}; B.on = i < B_THIGH_L;
		B.inv_m = 1.0f / B.m;
	}
	for (int s = 0; s < 2; s++) {
		const Joint &sh = j[s == 0 ? J_SHOULDER_L : J_SHOULDER_R], &el = j[s == 0 ? J_ELBOW_L : J_ELBOW_R];
		Body &U = b[sh.c], &F = b[el.c];
		const V3 sw = b[B_CHEST].x + rot(qy, sh.ap);
		U.q = qmul(qy, arm_down[s]); U.x = sw - rot(U.q, sh.ac);
		F.q = qmul(U.q, el.want); F.x = U.x + rot(U.q, el.ap) - rot(F.q, el.ac);
	}
	b[B_PELVIS].inv_m = 1.0f / (b[B_PELVIS].m + m_legs);   // while the legs only carry, their weight hangs on the pelvis
	for (int s = 0; s < 2; s++) {
		foot[s] = Foot();
		foot[s].p = at + rot(qy, V3{ rest.ankle[s].x, 0, rest.ankle[s].z });
		foot[s].p.y = ground_y(foot[s].p.x, foot[s].p.z);
		foot[s].planted = true;
		j[s == 0 ? J_SHOULDER_L : J_SHOULDER_R].want = arm_down[s];
		j[s == 0 ? J_HIP_L : J_HIP_R].want = Q(); j[s == 0 ? J_KNEE_L : J_KNEE_R].want = Q();
	}
	state = ST_BALANCE; steps = 0; tilt = 0; quiet = 0; t_state = 0; strength = 1.0f; settled = false; max_speed = 0; heading = yaw; lean_on = false; last_step = -1; stumble_t = 0;
	cop = flat(at); h_want = rest.pelvis.y + 0.03f;
	pose_legs();
}

void Person::start_pose(const V3 *px, const Q *pq, const V3 *pv, float yaw) {
	for (int i = 0; i < NB; i++) {
		Body &B = b[i];
		B.x = px[i]; B.q = pq[i]; B.v = pv[i]; B.w = V3{}; B.on = i < B_THIGH_L; B.inv_m = 1.0f / B.m;
	}
	b[B_PELVIS].inv_m = 1.0f / (b[B_PELVIS].m + m_legs);
	for (int s = 0; s < 2; s++) {
		const Joint &aj = j[s == 0 ? J_ANKLE_L : J_ANKLE_R];
		foot[s] = Foot();
		foot[s].p = flat(b[aj.p].x + rot(b[aj.p].q, aj.ap));   // the ankle as the animation has it, set on the ground
		foot[s].p.y = ground_y(foot[s].p.x, foot[s].p.z);
		foot[s].planted = true;
		j[s == 0 ? J_SHOULDER_L : J_SHOULDER_R].want = arm_down[s];
		j[s == 0 ? J_HIP_L : J_HIP_R].want = Q(); j[s == 0 ? J_KNEE_L : J_KNEE_R].want = Q();
	}
	state = ST_BALANCE; steps = 0; tilt = 0; quiet = 0; t_state = 0; strength = 1.0f; settled = false; max_speed = 0; heading = yaw; lean_on = false; last_step = -1; stumble_t = 0;
	cop = support(flat(com()), -1);
	h_want = b[B_PELVIS].x.y - ground_y(b[B_PELVIS].x.x, b[B_PELVIS].x.z);
	pose_legs();
}

void Person::impulse(int body, V3 point, V3 imp) {
	if (body < 0 || body >= NB) return;
	if (!b[body].on) body = B_PELVIS;   // a kick at a leg that is only carrying goes to the hips
	Body &B = b[body];
	B.v = B.v + imp * B.inv_m;
	B.w = B.w + cross(point - B.x, imp) * B.inv_i;
}

V3 Person::com() const {
	V3 s{}; float m = 0;
	for (int i = 0; i < NB; i++) if (b[i].on) { const float bm = 1.0f / b[i].inv_m; s = s + b[i].x * bm; m += bm; }
	return s * (1.0f / std::max(m, 1.0e-3f));
}
V3 Person::com_v() const {
	V3 s{}; float m = 0;
	for (int i = 0; i < NB; i++) if (b[i].on) { const float bm = 1.0f / b[i].inv_m; s = s + b[i].v * bm; m += bm; }
	return s * (1.0f / std::max(m, 1.0e-3f));
}

// ---------------------------------------------------------------- the small physics
void Person::pos_fix1(int i, V3 r, V3 n, float depth, V3 vb) {
	Body &B = b[i];
	const V3 rn = cross(r, n);
	const float w = B.inv_m + B.inv_i * dot(rn, rn);
	const float lam = std::min(depth, 0.03f) / w;   // (out of a surface a little at a time: a deep overlap must not become a shot)
	const V3 p = n * lam;
	if (n_hits < 96) hits[n_hits++] = Hit{ i, r, n, vb, lam };
	B.x = B.x + p * B.inv_m;
	spin(B.q, cross(r, p) * B.inv_i, 1.0f);
}

void Person::pos_fix2(int i, int k, V3 ri, V3 rk, V3 corr) {
	float c = len(corr);
	if (c < 1.0e-7f) return;
	const V3 n = corr * (1.0f / c);
	c = std::min(c, 0.06f);
	Body &A = b[i], &B = b[k];
	const V3 an = cross(ri, n), bn = cross(rk, n);
	const float wa = A.inv_m + A.inv_i * dot(an, an), wb = B.inv_m + B.inv_i * dot(bn, bn);
	const V3 p = n * (c / (wa + wb));
	A.x = A.x + p * A.inv_m; spin(A.q, cross(ri, p) * A.inv_i, 1.0f);
	B.x = B.x - p * B.inv_m; spin(B.q, cross(rk, p) * -B.inv_i, 1.0f);
}

void Person::ang_fix2(int i, int k, V3 dphi) {
	const float th = len(dphi);
	if (th < 1.0e-7f) return;
	if (th > 0.2f) dphi = dphi * (0.2f / th);
	Body &A = b[i], &B = b[k];
	const float s = 1.0f / (A.inv_i + B.inv_i);
	spin(A.q, dphi * (s * A.inv_i), 1.0f);
	spin(B.q, dphi * (-s * B.inv_i), 1.0f);
}

void Person::solve_joint(Joint &J) {
	Body &P = b[J.p], &C = b[J.c];
	if (!P.on || !C.on) return;
	{   // the two ends meet
		const V3 rp = rot(P.q, J.ap), rc = rot(C.q, J.ac);
		pos_fix2(J.c, J.p, rc, rp, (P.x + rp) - (C.x + rc));
	}
	if (J.hinge) {   // an elbow, a knee: one axis, and only so far
		const V3 ap = rot(P.q, J.axis), ac = rot(C.q, J.axis);
		ang_fix2(J.c, J.p, cross(ac, ap));
		const Q rel = qmul(qconj(P.q), C.q);
		const float phi = wrap(2.0f * std::atan2(rel.x * J.axis.x + rel.y * J.axis.y + rel.z * J.axis.z, rel.w));
		if (phi < J.lo) ang_fix2(J.c, J.p, ap * (J.lo - phi));
		else if (phi > J.hi) ang_fix2(J.c, J.p, ap * (J.hi - phi));
	} else {         // a shoulder, a hip, the spine: it swings in a cone and twists a little
		const V3 dp = rot(P.q, J.bone), dc = rot(C.q, J.bone);
		const float sw = std::acos(clampf(dot(dp, dc), -1.0f, 1.0f));
		if (sw > J.swing) ang_fix2(J.c, J.p, norm(cross(dc, dp)) * (sw - J.swing));
		const Q rel = qmul(qconj(P.q), C.q);
		const float tw = wrap(2.0f * std::atan2(rel.x * J.bone.x + rel.y * J.bone.y + rel.z * J.bone.z, rel.w));
		if (std::fabs(tw) > J.twist) ang_fix2(J.c, J.p, dp * (clampf(tw, -J.twist, J.twist) - tw));
	}
}

// THE LIMBS AGAINST THE BODY (Yasin, 20 Nov: "peoples arms and legs go thru their bodies"): each pair of parts that
// are not joined, capsule against capsule, pushed apart where they overlap: the arms against the trunk, the head and
// each other, the thighs and the calves against each other
static inline void seg_closest(V3 p1, V3 q1, V3 p2, V3 q2, V3 &c1, V3 &c2) {
	const V3 d1 = q1 - p1, d2 = q2 - p2, r = p1 - p2;
	const float a = dot(d1, d1), e = dot(d2, d2), f = dot(d2, r);
	float s = 0.0f, t = 0.0f;
	if (a <= 1e-8f && e <= 1e-8f) { c1 = p1; c2 = p2; return; }
	if (a <= 1e-8f) { t = clampf(f / e, 0.0f, 1.0f); }
	else {
		const float c = dot(d1, r);
		if (e <= 1e-8f) s = clampf(-c / a, 0.0f, 1.0f);
		else {
			const float bb = dot(d1, d2), den = a * e - bb * bb;
			s = den > 1e-8f ? clampf((bb * f - c * e) / den, 0.0f, 1.0f) : 0.0f;
			t = (bb * s + f) / e;
			if (t < 0.0f) { t = 0.0f; s = clampf(-c / a, 0.0f, 1.0f); }
			else if (t > 1.0f) { t = 1.0f; s = clampf((bb - c) / a, 0.0f, 1.0f); }
		}
	}
	c1 = p1 + d1 * s; c2 = p2 + d2 * t;
}

void Person::self_contacts() {
	static const int PAIRS[][2] = {
		{ B_FARM_L, B_CHEST }, { B_FARM_R, B_CHEST }, { B_FARM_L, B_PELVIS }, { B_FARM_R, B_PELVIS },
		{ B_UARM_L, B_PELVIS }, { B_UARM_R, B_PELVIS }, { B_FARM_L, B_HEAD }, { B_FARM_R, B_HEAD },
		{ B_UARM_L, B_HEAD }, { B_UARM_R, B_HEAD }, { B_FARM_L, B_FARM_R }, { B_UARM_L, B_FARM_R }, { B_UARM_R, B_FARM_L },
		{ B_FARM_L, B_THIGH_L }, { B_FARM_R, B_THIGH_R }, { B_FARM_L, B_THIGH_R }, { B_FARM_R, B_THIGH_L },
		{ B_THIGH_L, B_THIGH_R }, { B_CALF_L, B_CALF_R }, { B_CALF_L, B_THIGH_R }, { B_CALF_R, B_THIGH_L },
		{ B_FOOT_L, B_CALF_R }, { B_FOOT_R, B_CALF_L }, { B_FOOT_L, B_FOOT_R } };
	for (const auto &pr : PAIRS) {
		const int i = pr[0], k = pr[1];
		Body &A = b[i], &B = b[k];
		if (!A.on || !B.on) continue;
		const V3 a0 = A.x + rot(A.q, A.a), a1 = A.x + rot(A.q, A.b), b0 = B.x + rot(B.q, B.a), b1 = B.x + rot(B.q, B.b);
		V3 ca, cb; seg_closest(a0, a1, b0, b1, ca, cb);
		const V3 dd = ca - cb;
		const float dist = len(dd), need = A.r + B.r;
		if (dist >= need || dist < 1e-6f) continue;
		const V3 n = dd * (1.0f / dist);
		pos_fix2(i, k, (ca - n * A.r) - A.x, (cb + n * B.r) - B.x, n * (need - dist));
	}
}

// Every part against the ground and against the cars: pushed out along the surface
void Person::contacts() {
	for (int i = 0; i < NB; i++) {
		Body &B = b[i];
		if (!B.on) continue;
		for (int e = 0; e < 2; e++) {
			const V3 off = rot(B.q, e == 0 ? B.a : B.b);
			const V3 p = B.x + off;
			const float depth = B.r - (dot(p, gn) - gd);
			if (depth > 0.0f) pos_fix1(i, off - gn * B.r, gn, depth, V3{});
			for (int k = 0; k < n_box; k++) {
				const Box &bx = box[k];
				const float cy = std::cos(bx.yaw), sy = std::sin(bx.yaw);
				const V3 d = p - bx.c;
				const V3 l{ d.x * cy - d.z * sy, d.y, d.x * sy + d.z * cy };   // in the box's own frame
				const V3 q{ clampf(l.x, -bx.half.x, bx.half.x), clampf(l.y, -bx.half.y, bx.half.y), clampf(l.z, -bx.half.z, bx.half.z) };
				V3 nl = l - q;
				float dist = len(nl), dep;
				if (dist > 1.0e-5f) { if (dist >= B.r) continue; nl = nl * (1.0f / dist); dep = B.r - dist; }
				else {   // its middle is inside: out through the nearest side (or the top)
					const float ex = bx.half.x - std::fabs(l.x), ez = bx.half.z - std::fabs(l.z), ey = bx.half.y - l.y;
					if (ex <= ez && ex <= ey) { nl = V3{ l.x < 0 ? -1.0f : 1.0f, 0, 0 }; dep = B.r + ex; }
					else if (ez <= ey) { nl = V3{ 0, 0, l.z < 0 ? -1.0f : 1.0f }; dep = B.r + ez; }
					else { nl = V3{ 0, 1, 0 }; dep = B.r + ey; }
				}
				const V3 n{ nl.x * cy + nl.z * sy, nl.y, -nl.x * sy + nl.z * cy };
				const V3 vb = bx.v + cross(V3{ 0, bx.yaw_rate, 0 }, d);
				pos_fix1(i, off - n * B.r, n, dep, vb);
			}
		}
	}
}

// The muscles: every joint pulls toward its wanted pose, as hard as it is strong
void Person::muscles(float h) {
	for (int k = 0; k < NJ; k++) {
		Joint &J = j[k];
		Body &P = b[J.p], &C = b[J.c];
		if (!P.on || !C.on) continue;
		const float st = k == J_NECK ? std::max(strength, 0.5f) : strength;   // the neck gives up last
		const Q qe = qmul(qmul(P.q, J.want), qconj(C.q));
		V3 tq = qvec(qe) * (J.kp * st);
		const float tl = len(tq), tm = J.tmax * st;
		if (tl > tm) tq = tq * (tm / tl);
		C.w = C.w + tq * (C.inv_i * h); P.w = P.w - tq * (P.inv_i * h);
		const float si = P.inv_i + C.inv_i;
		const V3 dw = (C.w - P.w) * (1.0f - std::exp(-J.kd * st * si * h));
		C.w = C.w - dw * (C.inv_i / si); P.w = P.w + dw * (P.inv_i / si);
	}
}

// What its planted feet cover: the line from one ankle to the other, widened by a sole (toes 13 cm ahead of the ankle,
// the heel 5 cm behind, 4 cm to each side). The nearest point of that to q.
V3 Person::support(V3 q, int only) const {
	const V3 f{ std::sin(heading), 0, std::cos(heading) }, l{ std::cos(heading), 0, -std::sin(heading) };
	q.y = 0;
	V3 base;
	const bool a = foot[0].planted && only != 1, c = foot[1].planted && only != 0;
	if (a && c) {
		const V3 p0 = flat(foot[0].p), d = flat(foot[1].p) - p0;
		base = p0 + d * clampf(dot(q - p0, d) / std::max(dot(d, d), 1.0e-6f), 0.0f, 1.0f);
	} else if (a || c) base = flat(foot[a ? 0 : 1].p);
	else return q;
	const V3 e = q - base;
	return base + f * clampf(dot(e, f), -0.05f, 0.13f) + l * clampf(dot(e, l), -0.04f, 0.04f);
}

// BALANCE: the legs hold the hips up and push from the point under the feet the brain chose (cop): the body
// topples away from that point exactly as a standing body does. The hips hold the trunk upright and facing its way.
void Person::carry(float h) {
	Body &P = b[B_PELVIS];
	if (!foot[0].planted && !foot[1].planted) return;
	{
		const V3 c = com();
		const float hc = std::max(c.y - ground_y(cop.x, cop.z), 0.3f);
		const float hp = P.x.y - ground_y(P.x.x, P.x.z);
		// up: as a leg does, stiff but without a bounce, and no harder than twice its weight (a hard landing sinks it)
		const float fv = clampf(rest.mass * (GRAV + 144.0f * (h_want - hp) - 24.0f * P.v.y), 0.0f, 2.0f * rest.mass * GRAV);
		V3 fh = flat(c - cop) * (fv / hc);   // sideways: away from where it presses
		const float fl = len(fh);
		if (fl > MU * fv) fh = fh * (MU * fv / fl);   // (shoes slip beyond that)
		P.v = P.v + (fh + V3{ 0, fv, 0 }) * (P.inv_m * h);
	}
	for (int i = B_PELVIS; i <= B_CHEST; i++) {   // the hips and the back
		Body &B = b[i];
		const V3 up = rot(B.q, V3{ 0, 1, 0 }), fw = rot(B.q, V3{ 0, 0, 1 });
		V3 tq = cross(up, V3{ 0, 1, 0 }) * (i == B_PELVIS ? 500.0f : 300.0f);
		tq.y += 60.0f * wrap(heading - std::atan2(fw.x, fw.z));
		const float tl = len(tq), tm = (i == B_PELVIS ? 280.0f : 160.0f) * skill * strength;
		if (tl > tm) tq = tq * (tm / tl);
		B.w = B.w + tq * (B.inv_i * h);
		B.w = B.w * std::exp(-45.0f * B.inv_i * h);
	}
}

void Person::sub(float h) {
	n_hits = 0;
	for (int k = 0; k < n_box; k++) { box[k].c = box[k].c + box[k].v * h; box[k].yaw += box[k].yaw_rate * h; }
	for (int i = 0; i < NB; i++) if (b[i].on) b[i].v.y -= GRAV * h;
	muscles(h);
	if (state == ST_BALANCE) carry(h);
	for (int i = 0; i < NB; i++) {
		Body &B = b[i];
		if (!B.on) continue;
		B.x0 = B.x; B.q0 = B.q;
		B.x = B.x + B.v * h;
		spin(B.q, B.w, h);
	}
	V3 vpre[96];
	for (int it = 0; it < 2; it++) {
		for (int k = 0; k < NJ; k++) solve_joint(j[k]);
		self_contacts();
		const int n0 = n_hits;
		contacts();
		for (int q = n0; q < n_hits; q++) { const Body &B = b[hits[q].body]; vpre[q] = B.v + cross(B.w, hits[q].r) - hits[q].vb; }
	}
	for (int i = 0; i < NB; i++) {
		Body &B = b[i];
		if (!B.on) continue;
		B.v = (B.x - B.x0) * (1.0f / h);
		Q dq = qmul(B.q, qconj(B.q0));
		if (dq.w < 0) { dq.x = -dq.x; dq.y = -dq.y; dq.z = -dq.z; }
		B.w = V3{ dq.x, dq.y, dq.z } * (2.0f / h);
		B.w = B.w * (1.0f - 0.3f * h);
		const float vl = len(B.v), wl = len(B.w);
		if (vl > 28.0f) B.v = B.v * (28.0f / vl);
		if (wl > 40.0f) B.w = B.w * (40.0f / wl);
	}
	for (int q = 0; q < n_hits; q++) {   // at every touch: no bounce, and grip
		const Hit &c = hits[q];
		Body &B = b[c.body];
		V3 vp = B.v + cross(B.w, c.r) - c.vb;
		const float vn = dot(vp, c.n), vn0 = dot(vpre[q], c.n);
		const V3 rn = cross(c.r, c.n);
		const float wn = B.inv_m + B.inv_i * dot(rn, rn);
		if (vn > 0.0f && vn0 < vn) {   // the push out of the surface must not become a jump
			const V3 imp = c.n * ((std::max(vn0, 0.0f) - vn) / wn);
			B.v = B.v + imp * B.inv_m; B.w = B.w + cross(c.r, imp) * B.inv_i;
			vp = B.v + cross(B.w, c.r) - c.vb;
		}
		const V3 vt = vp - c.n * dot(vp, c.n);
		const float vtl = len(vt);
		if (vtl > 1.0e-5f) {
			const V3 t = vt * (1.0f / vtl);
			const V3 rt = cross(c.r, t);
			const float wt = B.inv_m + B.inv_i * dot(rt, rt);
			const V3 imp = t * -std::min(vtl / wt, MU * c.lam / h);
			B.v = B.v + imp * B.inv_m; B.w = B.w + cross(c.r, imp) * B.inv_i;
		}
	}
}

// ---------------------------------------------------------------- what it decides
// The legs while they only carry: thigh, calf and foot drawn from the hip to where the foot stands
void Person::pose_legs() {
	const Body &P = b[B_PELVIS];
	const V3 fwd = rot(P.q, V3{ 0, 0, 1 });
	const Q qh = qaxis(V3{ 0, 1, 0 }, heading);
	for (int s = 0; s < 2; s++) {
		const Joint &hj = j[s == 0 ? J_HIP_L : J_HIP_R], &kj = j[s == 0 ? J_KNEE_L : J_KNEE_R], &aj = j[s == 0 ? J_ANKLE_L : J_ANKLE_R];
		const V3 H = P.x + rot(P.q, hj.ap), A = foot[s].p + V3{ 0, ankle_h, 0 };
		const V3 K = knee_of(H, A, l_thigh, l_calf, fwd);
		Body &T = b[hj.c], &C = b[kj.c], &F = b[aj.c];
		const V3 td = norm(K - H), cd = norm(A - K);
		T.q = qmul(qalign(rot(P.q, hj.bone), td), P.q);
		T.x = H - rot(T.q, hj.ac);
		C.q = qmul(qalign(rot(P.q, norm(rest.ankle[s] - rest.knee[s])), cd), P.q);
		C.x = K - rot(C.q, kj.ac);
		F.q = qh;
		F.x = A - rot(F.q, aj.ac);
	}
}

void Person::go_fall() {
	const V3 pv = b[B_PELVIS].v, pw = b[B_PELVIS].w, px = b[B_PELVIS].x;
	pose_legs();
	b[B_PELVIS].inv_m = 1.0f / b[B_PELVIS].m;
	for (int i = B_THIGH_L; i < NB; i++) { b[i].on = true; b[i].v = pv + cross(pw, b[i].x - px); b[i].w = pw; }
	const V3 cv = flat(com_v());
	fall_dir = len(cv) > 0.3f ? norm(cv) : flat(rot(b[B_CHEST].q, V3{ 0, 1, 0 }));
	if (len(fall_dir) < 0.05f) fall_dir = V3{ 0, 0, 1 };
	fall_dir = norm(fall_dir);
	foot[0].planted = foot[1].planted = false;
	state = ST_FALL; t_state = 0; quiet = 0; settled = false; strength = 0.85f;
}

void Person::brain(float dt) {
	t_state += dt;
	const Body &P = b[B_PELVIS], &C = b[B_CHEST];
	tilt = std::acos(clampf(norm(b[B_HEAD].x - P.x).y, -1.0f, 1.0f));   // the line from its hips to its head (bending at the waist is not falling)
	if (state == ST_REST) return;
	if (state == ST_FALL) {
		// going down: the arms reach for the ground on the side it falls to, the knees and hips fold, the neck holds;
		// the strength drains away
		strength = std::max(0.12f, 0.85f * std::exp(-t_state / 0.9f));
		for (int s = 0; s < 2; s++) {
			const Q qc = C.q;
			const V3 side = rot(qc, V3{ s == 0 ? 1.0f : -1.0f, 0, 0 });
			const V3 u = norm(fall_dir * 0.75f + V3{ 0, -0.45f, 0 } + side * 0.25f);
			Joint &sh = j[s == 0 ? J_SHOULDER_L : J_SHOULDER_R];
			sh.want = qmul(qconj(qc), qmul(qalign(rot(qc, sh.bone), u), qc));
			j[s == 0 ? J_ELBOW_L : J_ELBOW_R].want = qaxis(j[s == 0 ? J_ELBOW_L : J_ELBOW_R].axis, 0.5f);
			j[s == 0 ? J_HIP_L : J_HIP_R].want = qaxis(V3{ 1, 0, 0 }, -0.5f);
			j[s == 0 ? J_KNEE_L : J_KNEE_R].want = qaxis(V3{ 1, 0, 0 }, 0.7f);
		}
		float vmax = 0;
		for (int i = 0; i < NB; i++) vmax = std::max(vmax, len(b[i].v));
		quiet = vmax < 0.35f ? quiet + dt : 0.0f;
		// (Yasin, 20 Nov: "they take forever to finish": still for 0.35 s, or 3 s at most; it was 0.7 s or 8 s)
		if (quiet > 0.35f || t_state > 3.0f) { state = ST_REST; t_state = 0; strength = 0.12f; face_up = rot(C.q, V3{ 0, 0, 1 }).y > 0.0f; }
		return;
	}
	// ---- BALANCE
	const V3 c = com(), cv = com_v();
	const float hc = std::max(c.y - ground_y(c.x, c.z), 0.3f);
	const float tc = std::sqrt(hc / GRAV);
	const V3 xi{ c.x + cv.x * tc, 0, c.z + cv.z * tc };   // the point on the ground it is falling toward
	for (int s = 0; s < 2; s++) {   // a foot in the air comes down where it was sent
		Foot &f = foot[s];
		if (f.planted) { f.p.y = ground_y(f.p.x, f.p.z); continue; }
		f.t += dt;
		const float u = f.t / f.T;
		if (u >= 1.0f) { f.p = f.to; f.p.y = ground_y(f.p.x, f.p.z); f.planted = true; continue; }
		f.p = f.from + (f.to - f.from) * ess(u);
		f.p.y = ground_y(f.p.x, f.p.z) + 0.09f * std::sin(3.14159265f * u);
	}
	const float speed = len(flat(cv));
	const float hp = P.x.y - ground_y(P.x.x, P.x.z);
	// stumbling along for three seconds without catching itself, and nothing pushing it: it goes down, as a person does
	stumble_t = (speed > 0.5f && n_hits == 0) ? stumble_t + dt : (speed < 0.3f || n_hits > 0 ? 0.0f : stumble_t);
	// (Yasin, 20 Nov: "people are very unlikely to fall and step countless times to balance themselves": a hard shove used
	// to be caught in 5-8 steps. A person catches a push in one to three steps or goes down: tests/people/sweep_shove.gd)
	// (Yasin, 20 Nov: "shoves drop people too easily now, they should try to balance for 3 steps as hard as they can then
	// fall if they still cant") for its first three steps it gives up only when it is truly overwhelmed (tipped past
	// 70 degrees, its hips at 40 % of their height, 5 m/s); a fourth step needed and it goes down (below). It gave up at
	// 3.4 m/s or 50 degrees at once: a hard shove dropped people where they stood.
	const bool fighting = steps < 3;
	if (tilt > (fighting ? 1.25f : 0.9f) || hp < (fighting ? 0.4f : 0.5f) * rest.pelvis.y || speed > (fighting ? 5.0f : 3.4f) || stumble_t > 1.6f) { go_fall(); return; }
	const bool swinging = !foot[0].planted || !foot[1].planted;
	const V3 left{ std::cos(heading), 0, -std::sin(heading) };
	const float out = len(xi - support(xi, -1));   // how far that point lies outside what its feet cover
	if (!swinging) {
		int s = -1;
		V3 tgt{};
		if (out > 0.03f && steps >= 3) { go_fall(); return; }   // (three steps did not catch it: down it goes)
		if (out > 0.03f) {
			// It is going over. One foot steps to where the point WILL be when that foot comes down (it runs away from
			// the standing foot faster and faster: e times as far every third of a second), and a little beyond.
			// Which foot: the far one (it swings past the standing one), unless that would cross its legs (falling to
			// the side): then the near one steps out sideways.
			s = len(flat(foot[0].p) - xi) > len(flat(foot[1].p) - xi) ? 0 : 1;
			for (int tries = 0; tries < 2; tries++) {
				const V3 stand = support(xi, 1 - s);
				const V3 dir = norm(xi - stand);
				float T = 0.20f / std::max(skill, 0.3f);
				for (int it = 0; it < 2; it++) {
					// ... and a little beyond: 5 cm, and 3.5 cm more with every step already taken. With a fixed 5 cm a body
					// pushed in the chest out of a fighter's stance stepped backwards at a steady 0.93 m/s for good (seen 20 Nov,
					// tests/people/test_acts.gd -- --trace: 28 steps in six seconds, never slower): each step only kept up
					// with the fall, none got ahead of it. A longer step each time does get ahead.
					tgt = stand + (xi - stand) * std::exp(T / tc) + dir * (0.05f + std::min(0.035f * (float)steps, 0.22f));
					T = clampf(0.14f + 0.10f * len(flat(tgt - foot[s].p)), 0.16f, 0.26f) / std::max(skill, 0.3f) * (steps < 3 ? 0.85f : 1.0f);   // (a step to save itself is a quick one; its first three as quick as it can)
				}
				const float gap = (dot(tgt, left) - dot(flat(foot[1 - s].p), left)) * (s == 0 ? 1.0f : -1.0f);   // how far it lands on its own side of the other foot
				if (gap >= 0.12f) break;
				// only a fall to the SIDE changes the foot; falling forward or back the trailing foot always steps, and
				// lands on its own side (a drift to one side used to make one foot hop again and again)
				if (std::fabs(dot(dir, left)) > 0.75f) {
					// to the side: the near foot steps out; and when it has just done so, the far foot crosses over in
					// front of it (a foot that only hops again and again catches nothing)
					if (tries == 0 && last_step != 1 - s) { s = 1 - s; continue; }
					tgt = tgt + V3{ std::sin(heading), 0, std::cos(heading) } * 0.15f;
					break;
				}
				tgt = tgt + left * ((0.12f - gap) * (s == 0 ? 1.0f : -1.0f));
				break;
			}
			lean_on = false;
		} else if (speed < 0.3f) {
			// Caught, with its feet apart: it shifts its weight over the foot that is nearer to where it is going, and
			// when it stands over that foot the other one comes up beside it.
			const float width = rest.hip[0].x - rest.hip[1].x + 0.06f;
			const V3 apart = flat(foot[0].p - foot[1].p) - left * width;
			lean_on = false;
			if (len(apart) > 0.16f) {
				const int k = len(flat(foot[0].p) - xi) > len(flat(foot[1].p) - xi) ? 0 : 1;   // the foot that will move
				lean_to = flat(foot[1 - k].p) + V3{ std::sin(heading), 0, std::cos(heading) } * 0.03f; lean_on = true;
				if (len(xi - lean_to) < 0.03f && speed < 0.12f) { s = k; tgt = flat(foot[1 - k].p) + left * (k == 0 ? width : -width); }
			}
		}
		if (s >= 0) {
			// no further than a leg reaches from where the hip will be
			const V3 hipf = flat(P.x + rot(P.q, j[s == 0 ? J_HIP_L : J_HIP_R].ap)) + flat(cv) * 0.2f;
			const V3 dv = tgt - hipf;
			const float dl = len(dv), reach = 0.55f * std::sqrt(skill);
			// (a step that cannot reach far enough is still taken, as long as a leg is: two or three such steps catch a
			// hard shove, the way a person runs a few steps to stay up. It goes down when the point is hopelessly far.)
			if (out > 0.85f * skill) { go_fall(); return; }
			if (dl > reach) tgt = hipf + dv * (reach / dl);
			Foot &f = foot[s];
			f.from = f.p; f.to = tgt; f.t = 0;
			f.T = clampf(0.14f + 0.10f * len(flat(tgt - f.p)), 0.16f, 0.26f) / std::max(skill, 0.3f);
			f.planted = false;
			last_step = s;
			if (out > 0.03f) steps++;
		}
	}
	{
		// Where it presses on its feet: beyond the point it is falling toward, on the far side from where it wants to
		// stand, as far as its feet reach. That pushes the point back to where it wants to stand.
		const bool both = foot[0].planted && foot[1].planted;
		const V3 want = (lean_on && both) ? lean_to : support((flat(foot[0].p) + flat(foot[1].p)) * 0.5f + V3{ std::sin(heading), 0, std::cos(heading) } * 0.03f, -1);
		cop = support(xi + (xi - want) * 1.6f, -1);
		// how high its legs let its hips stand over where its feet are (it sinks at once, it rises at a person's pace)
		float top = 10.0f;
		for (int s = 0; s < 2; s++) {
			if (!foot[s].planted) continue;
			const V3 d = flat(P.x + rot(P.q, j[s == 0 ? J_HIP_L : J_HIP_R].ap) - foot[s].p);
			top = std::min(top, std::sqrt(std::max(leg_len * leg_len - dot(d, d), 0.09f)));
		}
		const float stand_h = top + ankle_h + (b[B_PELVIS].x0.y * 0.0f) + 0.03f - 0.012f;
		h_want = stand_h < h_want ? stand_h : std::min(stand_h, h_want + 0.6f * skill * dt);
	}
	quiet = (speed < 0.2f && out < 0.01f && tilt < 0.15f && !swinging && !lean_on) ? quiet + dt : 0.0f;
	settled = quiet > 0.8f;
	if (quiet > 1.5f) { steps = 0; last_step = -1; }
}

void Person::step(float dt) {
	brain(dt);
	const float h = dt / (float)SUBSTEPS;
	for (int k = 0; k < SUBSTEPS; k++) sub(h);
	if (state == ST_BALANCE) pose_legs();
	for (int i = 0; i < NB; i++) if (b[i].on) max_speed = std::max(max_speed, len(b[i].v));
}

} // namespace pb
