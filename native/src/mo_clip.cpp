// mo_clip: see mo_clip.h.
#include "mo_clip.h"

#include <godot_cpp/variant/node_path.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>

#include <algorithm>
#include <cmath>
#include <unordered_map>

using namespace godot;

namespace {
std::unordered_map<uint64_t, mo::ClipData *> g_cache;

float curve(const Ref<Animation> &a, const char *k, double t) {
	if (!a->has_meta(k)) return 0.0f;
	const PackedFloat32Array p = a->get_meta(k);
	if (p.size() == 0) return 0.0f;
	const double f = std::min(std::max(t * mo::FPS, 0.0), (double)(p.size() - 1));
	const int i = (int)f, j = std::min(i + 1, (int)p.size() - 1);
	return p[i] + (p[j] - p[i]) * (float)(f - i);
}

float wrap(float a) { a = std::fmod(a + 3.14159265f, 6.2831853f); if (a < 0.0f) a += 6.2831853f; return a - 3.14159265f; }
} // namespace

int mo::ClipData::idx(double t) const {
	if (f.empty()) return 0;
	if (loop && len > 0.0) { t = std::fmod(t, len); if (t < 0.0) t += len; }
	return std::min(std::max((int)std::lround(t * FPS), 0), (int)f.size() - 1);
}

const mo::Frame &mo::ClipData::at(double t) const { return f[idx(t)]; }

float mo::ClipData::yaw(double t) const {
	if (yaw_c.empty()) return 0.0f;
	const double x = std::min(std::max(t * FPS, 0.0), (double)(yaw_c.size() - 1));
	const int i = (int)x, j = std::min(i + 1, (int)yaw_c.size() - 1);
	return yaw_c[i] + (yaw_c[j] - yaw_c[i]) * (float)(x - i);
}

Vector3 mo::ClipData::root_vel(double t) const {
	if (root_v.empty()) return Vector3();
	if (loop && len > 0.0) { t = std::fmod(t, len); if (t < 0.0) t += len; }
	const double x = std::min(std::max(t * FPS, 0.0), (double)(root_v.size() - 1));
	const int i = (int)x, j = std::min(i + 1, (int)root_v.size() - 1);
	return root_v[i].lerp(root_v[j], (float)(x - i));
}

mo::Frame mo::ClipData::lerp(double t) const {
	if (f.size() < 2) return f.empty() ? Frame() : f[0];
	if (loop && len > 0.0) { t = std::fmod(t, len); if (t < 0.0) t += len; }
	const double x = std::min(std::max(t * FPS, 0.0), (double)(f.size() - 1));
	const int i = (int)x, j = std::min(i + 1, (int)f.size() - 1);
	const float u = (float)(x - i);
	const Frame &a = f[i], &b = f[j];
	Frame r = a;
	r.hips = a.hips.lerp(b.hips, u);
	for (int s = 0; s < 2; s++) {
		r.foot[s] = a.foot[s].lerp(b.foot[s], u); r.toe[s] = a.toe[s].lerp(b.toe[s], u); r.hand[s] = a.hand[s].lerp(b.hand[s], u);
		r.foot_v[s] = a.foot_v[s].lerp(b.foot_v[s], u); r.hand_v[s] = a.hand_v[s].lerp(b.hand_v[s], u);
		r.down[s] = u < 0.5f ? a.down[s] : b.down[s];
	}
	r.hips_v = a.hips_v.lerp(b.hips_v, u);
	r.face = a.face + wrap(b.face - a.face) * u;
	return r;
}

const mo::ClipData *mo::clip_data(const Ref<Animation> &p_anim, Skeleton3D *p_skel, const Transform3D &p_skel_in_node) {
	if (p_anim.is_null() || !p_skel) return nullptr;
	const uint64_t key = (uint64_t)p_anim->get_instance_id();
	{   // (made and read on the main thread only)
		auto it = g_cache.find(key);
		if (it != g_cache.end()) return it->second;
	}
	ClipData *d = new ClipData();
	const Ref<Animation> &a = p_anim;
	d->len = a->get_length();
	d->loop = a->get_loop_mode() != Animation::LOOP_NONE;
	d->in_place = a->has_meta("vz");
	const int nb = p_skel->get_bone_count();
	// the tracks' bones, once
	std::vector<int> tb(a->get_track_count(), -1);
	for (int ti = 0; ti < a->get_track_count(); ti++) {
		const NodePath path = a->track_get_path(ti);
		if (path.get_subname_count() >= 1) tb[ti] = p_skel->find_bone(path.get_subname(0));
	}
	const int b_hips = p_skel->find_bone("Bip01_Pelvis");
	const int b_ft[2] = { p_skel->find_bone("Bip01_L_Foot"), p_skel->find_bone("Bip01_R_Foot") };
	const int b_toe[2] = { p_skel->find_bone("Bip01_L_Toe0"), p_skel->find_bone("Bip01_R_Toe0") };
	const int b_hd[2] = { p_skel->find_bone("Bip01_L_Hand"), p_skel->find_bone("Bip01_R_Hand") };
	const int b_th[2] = { p_skel->find_bone("Bip01_L_Thigh"), p_skel->find_bone("Bip01_R_Thigh") };
	const int n = std::max(1, (int)std::lround(d->len * FPS) + 1);
	d->f.resize(n);
	std::vector<Transform3D> loc(nb), glob(nb);
	auto G = [&](int b) { return b >= 0 ? (p_skel_in_node * glob[b]).origin : Vector3(); };
	for (int k = 0; k < n; k++) {
		const double t = std::min(k / FPS, d->len);
		for (int b = 0; b < nb; b++) loc[b] = p_skel->get_bone_rest(b);
		for (int ti = 0; ti < (int)tb.size(); ti++) {
			const int b = tb[ti];
			if (b < 0) continue;
			const Animation::TrackType ty = a->track_get_type(ti);
			if (ty == Animation::TYPE_POSITION_3D) loc[b].origin = a->position_track_interpolate(ti, t);
			else if (ty == Animation::TYPE_ROTATION_3D) loc[b].basis = Basis(a->rotation_track_interpolate(ti, t)).scaled_local(loc[b].basis.get_scale());
		}
		for (int b = 0; b < nb; b++) { const int par = p_skel->get_bone_parent(b); glob[b] = (par >= 0 && par < b) ? glob[par] * loc[b] : loc[b]; }
		Frame &F = d->f[k];
		F.hips = G(b_hips);
		for (int s = 0; s < 2; s++) { F.foot[s] = G(b_ft[s]); F.toe[s] = b_toe[s] >= 0 ? G(b_toe[s]) : F.foot[s]; F.hand[s] = G(b_hd[s]); }
		const Vector3 th = G(b_th[0]) - G(b_th[1]);
		const Vector3 fw = -Vector3(0, 1, 0).cross(th);
		F.face = std::atan2((float)fw.x, (float)fw.z);
	}
	// IN PLACE only when the hips do not carry the travel themselves: festive's traversal clips (and a raw climb) keep
	// their vz / vx meta but have the travel back in the hips; taken as in place, their travel was counted twice
	if (d->in_place) {
		float vz_travel = 0.0f;
		for (int k = 0; k < n; k++) vz_travel += std::fabs(curve(a, "vz", k / FPS)) / (float)FPS;
		const Vector3 dh = d->f[n - 1].hips - d->f[0].hips;
		const float hips_travel = (float)Vector3(dh.x, 0.0f, dh.z).length();
		if ((a->has_meta("root") && (bool)a->get_meta("root")) || (vz_travel > 0.2f && hips_travel > 0.5f * vz_travel)) d->in_place = false;
	}
	// is the turn in the pose or in the yaw curve? (the pose's own facing change against the curve's)
	{
		const float yend = d->in_place ? curve(a, "yaw", d->len) : 0.0f;
		const float fturn = wrap(d->f[n - 1].face - d->f[0].face);
		d->yaw_turns = !(std::fabs(yend) > 0.2f && std::fabs(fturn) > 0.5f * std::fabs(yend) && fturn * yend > 0.0f);
		if (d->in_place && a->has_meta("yaw")) { d->yaw_c.resize(n); for (int k = 0; k < n; k++) d->yaw_c[k] = d->yaw_turns ? curve(a, "yaw", k / FPS) : 0.0f; }
	}
	// speeds over the ground: an in-place clip's own travel (its vz / vx, in the figure's turning frame) added back
	float gy = 1e9f;
	for (int k = 0; k < n; k++) {
		Frame &F = d->f[k];
		const int k0 = std::max(k - 1, 0), k1 = std::min(k + 1, n - 1);
		const float dt = (float)((k1 - k0) / FPS);
		const Vector3 trav = d->in_place ? Vector3(curve(a, "vx", k / FPS), 0.0f, curve(a, "vz", k / FPS)) : Vector3();
		if (dt > 0.0f) {
			F.hips_v = (d->f[k1].hips - d->f[k0].hips) / dt + trav;
			for (int s = 0; s < 2; s++) { F.foot_v[s] = (d->f[k1].foot[s] - d->f[k0].foot[s]) / dt + trav; F.hand_v[s] = (d->f[k1].hand[s] - d->f[k0].hand[s]) / dt + trav; }
		}
		gy = std::min(gy, (float)std::min(F.foot[0].y, F.foot[1].y));
	}
	d->ground_y = gy;
	// a foot is down: slow over the ground and near the lowest it gets within 0.4 s either side (a climb's feet are
	// down on the top too)
	const int w = (int)(0.4 * FPS);
	const bool turns = d->in_place && std::fabs(d->yaw(d->len)) > 1.0f;
	for (int k = 0; k < n; k++) {
		for (int s = 0; s < 2; s++) {
			float lo = 1e9f;
			for (int j = std::max(k - w, 0); j <= std::min(k + w, n - 1); j++) lo = std::min(lo, (float)d->f[j].foot[s].y);
			const Frame &F = d->f[k];
			// (by height and the vertical speed only: the level speed over the ground needs the clip's travel, which is
			// what this is used to find)
			// (a clip that turns the body round keeps a foot low while it steps round the other: on flat ground, the clip's
			// floor is the measure there; elsewhere the foot's own lowest nearby)
			const float floor_y = turns ? gy + 0.02f : lo + 0.05f;
			d->f[k].down[s] = F.foot[s].y < floor_y && std::fabs((float)F.foot_v[s].y) < 0.3f;
		}
	}
	// the travel from the planted feet (in-place clips)
	if (d->in_place) {
		std::vector<Vector3> rv(n);
		for (int k = 0; k < n; k++) {
			const Frame &F = d->f[k];
			const double tk = k / FPS;
			const Vector3 trav(curve(a, "vx", tk), 0.0f, curve(a, "vz", tk));
			const float om = (d->yaw(std::min(tk + 1.0 / FPS, d->len)) - d->yaw(std::max(tk - 1.0 / FPS, 0.0))) / (float)(2.0 / FPS);
			Vector3 sum; int m = 0;
			for (int s = 0; s < 2; s++) {
				if (!F.down[s]) continue;
				const Vector3 rel = F.foot_v[s] - trav;            // the foot against the figure
				const Vector3 fp(F.foot[s].x, 0.0f, F.foot[s].z);
				const Vector3 spin(om * (float)fp.z, 0.0f, -om * (float)fp.x);   // (the frame's turn under the foot)
				sum += -(rel + spin); m++;
			}
			// (both down: their average. Taking the lower foot alone was tried, 22 Nov: the walks' planted feet then slid
			// 35 cm; the 180-degree pivots stay open, docs/ANIMATION_PLAN.md)
			rv[k] = m ? Vector3(sum.x / m, 0.0f, sum.z / m) : trav;

		}
		d->root_v.resize(n);
		for (int k = 0; k < n; k++) {   // smoothed over 5 frames (a loop wraps)
			Vector3 acc; int m = 0;
			for (int j = k - 2; j <= k + 2; j++) {
				int jj = j;
				if (d->loop) jj = ((j % (n - 1)) + (n - 1)) % (n - 1); else jj = std::min(std::max(j, 0), n - 1);
				acc += rv[jj]; m++;
			}
			d->root_v[k] = acc / (float)m;
		}
	}
	g_cache[key] = d;
	return d;
}

float mo::pose_cost(const Frame &a, const Frame &b) {
	// each in its own facing: the feet relative to the hips, their speeds, the hips' height and speed
	const Basis ra(Vector3(0, 1, 0), -a.face), rb(Vector3(0, 1, 0), -b.face);
	float c = 0.0f;
	for (int s = 0; s < 2; s++) {
		c += 1.0f * (ra.xform(a.foot[s] - a.hips) - rb.xform(b.foot[s] - b.hips)).length_squared();
		c += 0.02f * (ra.xform(a.foot_v[s]) - rb.xform(b.foot_v[s])).length_squared();
		c += 0.15f * (ra.xform(a.hand[s] - a.hips) - rb.xform(b.hand[s] - b.hips)).length_squared();
		if (a.down[s] != b.down[s]) c += 0.05f;
	}
	c += 0.5f * (float)((a.hips.y - b.hips.y) * (a.hips.y - b.hips.y));
	c += 0.02f * (ra.xform(a.hips_v) - rb.xform(b.hips_v)).length_squared();
	return c;
}

double mo::best_entry(const ClipData &A, double ta, const ClipData &B, double lo, double hi, float *r_cost) {
	const Frame fa = A.lerp(ta);
	double best_t = lo; float best = 1e30f;
	lo = std::max(lo, 0.0); hi = std::min(hi, B.len);
	for (double t = lo; t <= hi + 1e-6; t += 1.0 / FPS) {
		const float c = pose_cost(fa, B.at(t));
		if (c < best) { best = c; best_t = t; }
	}
	if (r_cost) *r_cost = best;
	return best_t;
}
