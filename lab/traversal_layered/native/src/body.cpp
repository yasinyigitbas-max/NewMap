#include "body.h"

#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/skin.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

namespace lab {

static const Vector3 UPV(0, 1, 0);

Quaternion arc(const Vector3 &a, const Vector3 &b) {
	const Vector3 an = a.normalized(), bn = b.normalized();
	const float d = an.dot(bn);
	if (d > 0.999999f) return Quaternion();
	if (d < -0.99999f) {
		Vector3 ax = an.cross(Vector3(1, 0, 0));
		if (ax.length_squared() < 1e-6f) ax = an.cross(Vector3(0, 0, 1));
		return Quaternion(ax.normalized(), 3.14159265f);
	}
	return Quaternion(an, bn);
}

float signed_angle(const Vector3 &a, const Vector3 &b, const Vector3 &axis) {
	const Vector3 n = axis.normalized();
	const Vector3 ap = a - n * a.dot(n), bp = b - n * b.dot(n);
	if (ap.length_squared() < 1e-10f || bp.length_squared() < 1e-10f) return 0;
	return std::atan2(ap.cross(bp).dot(n), ap.dot(bp));
}

// v2 1.5: q = swing * twist, twist about `axis` (in q's child frame), canonicalised (w >= 0)
void swing_twist(const Quaternion &qin, const Vector3 &axis, Quaternion &swing, float &twist) {
	Quaternion q = qin;
	if (q.w < 0) q = Quaternion(-q.x, -q.y, -q.z, -q.w);
	const Vector3 d = axis.normalized();
	const Vector3 v(q.x, q.y, q.z);
	const float p = v.dot(d);
	twist = 2.0f * std::atan2(p, q.w);
	if (twist > 3.14159265f) twist -= 6.2831853f;
	Quaternion tw(d.x * p, d.y * p, d.z * p, q.w);
	const float l = std::sqrt(tw.x * tw.x + tw.y * tw.y + tw.z * tw.z + tw.w * tw.w);
	if (l < 1e-6f) { // 180 deg swing: twist undefined (v2 1.5) - report a huge twist so it fires
		swing = q;
		twist = 3.14159265f;
		return;
	}
	tw = Quaternion(tw.x / l, tw.y / l, tw.z / l, tw.w / l);
	swing = q * tw.inverse();
}

static float wrap(float a) {
	while (a > 3.14159265f) a -= 6.2831853f;
	while (a < -3.14159265f) a += 6.2831853f;
	return a;
}

static float elev(const Vector3 &v) { // angle above the horizontal plane (y up)
	return std::atan2(v.y, std::sqrt(v.x * v.x + v.z * v.z));
}

Basis anat(const BodyModel &m, const Transform3D *W, int b) {
	return W[b].basis * m.anat_local[b];
}

void world_pose(const BodyModel &m, Skeleton3D *sk, std::vector<Transform3D> &W) {
	W.resize(m.bone_count);
	Transform3D g;
	if (sk->is_inside_tree())
		g = sk->is_physics_interpolated_and_enabled() ? sk->get_global_transform_interpolated() : sk->get_global_transform();
	else // tools and tests before the tree is ready: walk the parents
		for (Node *n = sk; n; n = n->get_parent()) {
			Node3D *n3 = Object::cast_to<Node3D>(n);
			if (n3) g = n3->get_transform() * g;
		}
	for (int i = 0; i < m.bone_count; i++) {
		Transform3D t = g * sk->get_bone_global_pose(i);
		t.basis.orthonormalize();
		W[i] = t;
	}
}

// ---- shared raw measures (used at init on the rest, and per frame) ----
// ankle angles in the shin frame (y = up the shin, x = the knee hinge carried by the shin, z = shin forward):
// dorsi = elevation of F above the plane normal to the shin; abd = F's azimuth about the shin (+ toes out);
// roll = U about F against the shin's vertical plane (+ sole turned to the middle). Raw (not rest-relative).
static void ankle_raw(const BodyModel &m, const Transform3D *W, int s, const Vector3 &F, const Vector3 &U, float &dorsi, float &abd, float &roll) {
	const Vector3 y = (W[m.b.lo[s]].origin - W[m.b.foot[s]].origin).normalized();
	Vector3 x = W[m.b.lo[s]].basis.xform(m.knee_hinge_shin_local[s]);
	x = (x - y * x.dot(y)).normalized();
	const Vector3 z = x.cross(y).normalized();
	const float lat = s == 0 ? 1.0f : -1.0f;
	const float fy = F.dot(y), fx = F.dot(x), fz = F.dot(z);
	dorsi = std::atan2(fy, std::sqrt(fx * fx + fz * fz)) * DEG;
	abd = std::atan2(fx, fz) * DEG * lat;
	Vector3 ref = y - F * y.dot(F);
	if (ref.length_squared() < 1e-8f) { roll = 0; return; }
	ref.normalize();
	const float r = signed_angle(ref, U, F);
	const float sg = F.cross(ref).dot(x * lat) >= 0 ? 1.0f : -1.0f;
	roll = r * sg * DEG;
}

static void knee_raw(const BodyModel &m, const Transform3D *W, int s, float &flex, float &varus, float &twist) {
	const Vector3 hip = W[m.b.up[s]].origin, knee = W[m.b.lo[s]].origin, ankle = W[m.b.foot[s]].origin;
	const Vector3 t = (knee - hip).normalized(), sv = (ankle - knee).normalized();
	const Vector3 a = (W[m.b.up[s]].basis.xform(m.knee_hinge_local[s])).normalized();
	const Vector3 tp = (t - a * t.dot(a)).normalized(), sp = (sv - a * sv.dot(a)).normalized();
	const float mag = std::acos(std::clamp(tp.dot(sp), -1.0f, 1.0f));
	const Vector3 ft = t.cross(a).normalized(); // the thigh's own forward (checked at init: points forward)
	const float sign = (ankle - knee).dot(ft) < 0 ? 1.0f : -1.0f; // ankle behind the hip->knee line = normal bend
	flex = sign * mag * DEG;
	varus = std::asin(std::clamp(sv.dot(a), -1.0f, 1.0f)) * DEG * (s == 0 ? -1.0f : 1.0f);
	const Vector3 as = (W[m.b.lo[s]].basis.xform(m.knee_hinge_shin_local[s])).normalized();
	twist = signed_angle(a, as, sv) * DEG;
}

static void elbow_raw(const BodyModel &m, const Transform3D *W, int s, float &flex) {
	const Vector3 sh = W[m.b.arm[s]].origin, el = W[m.b.farm[s]].origin, wr = W[m.b.hand[s]].origin;
	const Vector3 u = (el - sh).normalized(), f = (wr - el).normalized();
	const Vector3 e = W[m.b.arm[s]].basis.xform(m.elbow_hinge_local[s]).normalized();
	const Vector3 up_ = (u - e * u.dot(e)).normalized(), fp = (f - e * f.dot(e)).normalized();
	const float mag = std::acos(std::clamp(up_.dot(fp), -1.0f, 1.0f));
	const Vector3 front = e.cross(u).normalized(); // the arm's front (palm side), set at init
	flex = (f.dot(front) >= 0 ? 1.0f : -1.0f) * mag * DEG;
}

bool BodyModel::init(Skeleton3D *sk) {
	ok = false;
	if (!sk) { error = "no skeleton"; return false; }
	bone_count = sk->get_bone_count();
	auto F = [&](const char *n) { return sk->find_bone(n); };
	b.hips = F("Hips");
	b.spine_low = F("Spine02");
	b.lumbar_top = F("Spine01");
	b.chest = F("Spine");
	b.neck = F("neck");
	b.head = F("Head");
	b.head_end = F("head_end");
	const char *sd[2] = {"Left", "Right"};
	const char *fn[4] = {"Index", "Middle", "Ring", "Pinky"};
	for (int s = 0; s < 2; s++) {
		String p = sd[s];
		b.up[s] = sk->find_bone(p + "UpLeg");
		b.lo[s] = sk->find_bone(p + "Leg");
		b.foot[s] = sk->find_bone(p + "Foot");
		b.toe[s] = sk->find_bone(p + "ToeBase");
		b.clav[s] = sk->find_bone(p + "Shoulder");
		b.arm[s] = sk->find_bone(p + "Arm");
		b.farm[s] = sk->find_bone(p + "ForeArm");
		b.hand[s] = sk->find_bone(p + "Hand");
		for (int f = 0; f < 4; f++)
			for (int j = 0; j < 3; j++) b.finger[s][f][j] = sk->find_bone(p + "Hand" + fn[f] + String::num_int64(j + 1));
		b.knuckle_mid[s] = b.finger[s][1][0];
	}
	const int need[] = {b.hips, b.lumbar_top, b.chest, b.neck, b.head, b.up[0], b.lo[0], b.foot[0], b.toe[0], b.up[1], b.lo[1],
			b.foot[1], b.toe[1], b.arm[0], b.farm[0], b.hand[0], b.arm[1], b.farm[1], b.hand[1]};
	for (int i : need)
		if (i < 0) { error = "missing bone"; return false; }

	parent.resize(bone_count);
	rest_g.resize(bone_count);
	anat_local.resize(bone_count);
	bone_len.resize(bone_count);
	Node3D *arm_node = Object::cast_to<Node3D>(sk->get_parent());
	unit = arm_node ? arm_node->get_transform().basis.get_scale().x : 1.0f;
	std::vector<Transform3D> W(bone_count); // the rest in "world" = skeleton space, metres
	for (int i = 0; i < bone_count; i++) {
		parent[i] = sk->get_bone_parent(i);
		rest_g[i] = sk->get_bone_global_rest(i);
		Basis bb = rest_g[i].basis.orthonormalized();
		anat_local[i] = bb.inverse(); // anatomical frame = skeleton axes at rest (the body faces +Z, left = +X)
		W[i] = Transform3D(bb, rest_g[i].origin * unit);
	}
	for (int i = 0; i < bone_count; i++)
		bone_len[i] = parent[i] >= 0 ? W[i].origin.distance_to(W[parent[i]].origin) : 0;

	// sanity at load (v2 1.0)
	if (W[b.up[0]].origin.x <= W[b.up[1]].origin.x) { error = "LeftUpLeg is not on the body's left (+X)"; return false; }
	if (W[b.head].origin.y <= W[b.hips].origin.y) { error = "head below hips"; return false; }
	if (W[b.toe[0]].origin.z <= W[b.foot[0]].origin.z) { error = "toes not ahead of the ankle"; return false; }

	for (int s = 0; s < 2; s++) {
		const Vector3 hip = W[b.up[s]].origin, knee = W[b.lo[s]].origin, ankle = W[b.foot[s]].origin;
		thigh_len[s] = hip.distance_to(knee);
		shin_len[s] = knee.distance_to(ankle);
		leg_reach[s] = hip.distance_to(ankle);
		if (thigh_len[s] < 0.33f || thigh_len[s] > 0.52f || shin_len[s] < 0.33f || shin_len[s] > 0.50f)
			UtilityFunctions::push_warning("body: leg bone lengths outside v2 1.0's 0.40-0.50 / 0.38-0.48 range: ", thigh_len[s], " ", shin_len[s]);
		const Vector3 t = (knee - hip).normalized();
		thigh_dir0[s] = t;
		const Vector3 L(1, 0, 0);
		Vector3 a = (L - t * L.dot(t)).normalized(); // perpendicular to the rest thigh (v2 1.2)
		if (t.cross(a).z < 0) a = -a;                 // the thigh's forward = cross(t, a) must point forward
		knee_hinge_local[s] = W[b.up[s]].basis.inverse().xform(a);
		knee_hinge_shin_local[s] = W[b.lo[s]].basis.inverse().xform(a);
		// elbow hinge: perpendicular to the upper arm and the body's forward, so the arm's front is the palm side of
		// a T-pose with palms down (v2 1.2 says capture it from a bent frame; checked against a running clip instead:
		// tests/body_check.gd asserts run frames read +70..+110)
		const Vector3 u = (W[b.farm[s]].origin - W[b.arm[s]].origin).normalized();
		Vector3 e = u.cross(Vector3(0, 0, 1)).normalized();
		if (e.cross(u).z < 0) e = -e;
		elbow_hinge_local[s] = W[b.arm[s]].basis.inverse().xform(e);
		arm_dir0[s] = u;
		farm_dir0[s] = (W[b.hand[s]].origin - W[b.farm[s]].origin).normalized();
		hand_dir0[s] = b.knuckle_mid[s] >= 0 ? (W[b.knuckle_mid[s]].origin - W[b.hand[s]].origin).normalized() : farm_dir0[s];
		for (int f = 0; f < 4; f++)
			for (int j = 0; j < 3; j++) {
				const int bi = b.finger[s][f][j];
				finger_dir0[s][f][j] = bi >= 0 ? W[bi].basis.get_column(1).normalized() : Vector3(0, 1, 0);
			}
	}

	// sole points from the mesh (v2 1.1): vertices skinned mostly to Foot / ToeBase, at rest, in skeleton space
	MeshInstance3D *mi = nullptr;
	for (int i = 0; i < sk->get_child_count(); i++) {
		mi = Object::cast_to<MeshInstance3D>(sk->get_child(i));
		if (mi && mi->get_skin().is_valid()) break;
		mi = nullptr;
	}
	if (!mi) { error = "no skinned mesh under the skeleton"; return false; }
	Ref<Skin> skin = mi->get_skin();
	Ref<Mesh> mesh = mi->get_mesh();
	std::vector<int> bind_bone(skin->get_bind_count());
	std::vector<Transform3D> bind_xf(skin->get_bind_count());
	for (int i = 0; i < skin->get_bind_count(); i++) {
		int bb = skin->get_bind_bone(i);
		if (bb < 0) bb = sk->find_bone(skin->get_bind_name(i));
		bind_bone[i] = bb;
		bind_xf[i] = rest_g[bb] * skin->get_bind_pose(i);
	}
	std::vector<Vector3> pts[2];
	for (int surf = 0; surf < mesh->get_surface_count(); surf++) {
		Array arr = mesh->surface_get_arrays(surf);
		PackedVector3Array V = arr[Mesh::ARRAY_VERTEX];
		PackedInt32Array BI = arr[Mesh::ARRAY_BONES];
		PackedFloat32Array BW = arr[Mesh::ARRAY_WEIGHTS];
		if (V.size() == 0 || BI.size() == 0) continue;
		const int per = (int)(BI.size() / V.size());
		const Transform3D mxf = mi->get_transform();
		for (int v = 0; v < V.size(); v++) {
			Vector3 p;
			float wsum = 0, wfoot[2] = {0, 0};
			for (int k = 0; k < per; k++) {
				const int bi = BI[v * per + k];
				const float w = BW[v * per + k];
				if (w <= 0 || bi < 0 || bi >= (int)bind_bone.size()) continue;
				p += bind_xf[bi].xform(mxf.xform(V[v])) * w;
				wsum += w;
				for (int s = 0; s < 2; s++)
					if (bind_bone[bi] == b.foot[s] || bind_bone[bi] == b.toe[s]) wfoot[s] += w;
			}
			if (wsum <= 0) continue;
			p /= wsum;
			for (int s = 0; s < 2; s++)
				if (wfoot[s] > 0.6f * wsum) pts[s].push_back(p * unit);
		}
	}
	for (int s = 0; s < 2; s++) {
		if (pts[s].size() < 20) { error = "too few foot vertices"; return false; }
		float miny = 1e9f;
		for (auto &p : pts[s]) miny = std::min(miny, p.y);
		const float ball_z = W[b.toe[s]].origin.z;
		const float med = s == 0 ? -1.0f : 1.0f; // medial direction along X
		Vector3 heel(0, 0, 1e9f), tip(0, 0, -1e9f), bin(0, 0, 0), bout(0, 0, 0);
		float bin_m = -1e9f, bout_m = 1e9f;
		for (auto &p : pts[s]) {
			if (p.y > miny + 0.015f) continue; // the sole layer
			if (p.z < heel.z) heel = p;
			if (p.z > tip.z) tip = p;
			if (std::fabs(p.z - ball_z) < 0.02f) {
				if (p.x * med > bin_m) { bin_m = p.x * med; bin = p; }
				if (p.x * med < bout_m) { bout_m = p.x * med; bout = p; }
			}
		}
		if (bin_m < -1e8f) { error = "no ball vertices"; return false; }
		// sole points sit on the sole plane (lowest layer)
		heel.y = bin.y = bout.y = tip.y = miny;
		sole_local[s][HEEL] = W[b.foot[s]].affine_inverse().xform(heel) / unit;
		sole_local[s][BALL_IN] = W[b.toe[s]].affine_inverse().xform(bin) / unit;
		sole_local[s][BALL_OUT] = W[b.toe[s]].affine_inverse().xform(bout) / unit;
		sole_local[s][TOE_TIP] = W[b.toe[s]].affine_inverse().xform(tip) / unit;
		const Vector3 mid = (bin + bout) * 0.5f;
		foot_F0[s] = (mid - heel).normalized();
		Vector3 U = (bin - heel).cross(bout - heel).normalized();
		if (U.y < 0) U = -U;
		foot_U0[s] = U;
		toe_dir0[s] = (tip - mid).normalized();
	}
	ok = true;
	// the rig's own rest knee and elbow readings (player_v3's knee bones are bent while the mesh leg is straight):
	// every angle is rest-relative (v2 1.2)
	for (int s = 0; s < 2; s++) {
		float fl, va, tw;
		knee_raw(*this, W.data(), s, fl, va, tw);
		knee_rest_signed[s] = fl;
		knee_rest_varus[s] = va;
		float ef;
		elbow_raw(*this, W.data(), s, ef);
		elbow_rest_signed[s] = ef;
		ankle_raw(*this, W.data(), s, foot_F0[s], foot_U0[s], ankle_rest[s][0], ankle_rest[s][1], ankle_rest[s][2]);
	}
	return true;
}

void measure(const BodyModel &m, const Transform3D *W, Measures &o) {
	const BodyBones &b = m.b;
	const float u = m.unit;
	// sole points, world
	for (int s = 0; s < 2; s++) {
		o.sole_w[s][HEEL] = W[b.foot[s]].xform(m.sole_local[s][HEEL] * u);
		for (int k = 1; k < SOLE_N; k++) o.sole_w[s][k] = W[b.toe[s]].xform(m.sole_local[s][k] * u);
		const Vector3 mid = (o.sole_w[s][BALL_IN] + o.sole_w[s][BALL_OUT]) * 0.5f;
		o.foot_F[s] = (mid - o.sole_w[s][HEEL]).normalized();
		Vector3 U = (o.sole_w[s][BALL_IN] - o.sole_w[s][HEEL]).cross(o.sole_w[s][BALL_OUT] - o.sole_w[s][HEEL]).normalized();
		// keep the normal's rest orientation (the sole's top side), whatever the foot does
		const Basis Af = anat(m, W, b.foot[s]);
		if (U.dot(Af.xform(m.foot_U0[s])) < 0) U = -U;
		o.foot_U[s] = U;
	}
	const Basis Ah = anat(m, W, b.hips);
	const Basis AhT = Ah.transposed();
	o.pelvis_c = (W[b.up[0]].origin + W[b.up[1]].origin) * 0.5f;
	o.neck_base = W[b.neck].origin;
	o.head_pos = W[b.head].origin;
	{
		Vector3 f = Ah.get_column(2);
		f.y = 0;
		o.pelvis_f = f.length_squared() > 1e-6f ? f.normalized() : Vector3(0, 0, 1);
		o.pelvis_l = UPV.cross(o.pelvis_f).normalized();
		o.pelvis_yaw = std::atan2(o.pelvis_f.x, o.pelvis_f.z);
	}
	for (int s = 0; s < 2; s++) {
		const float lat = s == 0 ? 1.0f : -1.0f; // lateral along anatomical X
		const Vector3 hip = W[b.up[s]].origin, knee = W[b.lo[s]].origin, ankle = W[b.foot[s]].origin;
		// knee (1.3), rest-relative
		float fl, va, tw;
		knee_raw(m, W, s, fl, va, tw);
		o.knee_flex[s] = fl - m.knee_rest_signed[s];
		o.knee_varus[s] = va - m.knee_rest_varus[s];
		o.knee_twist[s] = tw;
		// hip (1.5): thigh in the pelvis frame
		const Vector3 d = AhT.xform((knee - hip).normalized()), d0 = m.thigh_dir0[s];
		o.hip_flex[s] = (std::atan2(d.z, -d.y) - std::atan2(d0.z, -d0.y)) * DEG;
		o.hip_abd[s] = (std::asin(std::clamp(d.x * lat, -1.0f, 1.0f)) - std::asin(std::clamp(d0.x * lat, -1.0f, 1.0f))) * DEG;
		{
			const Vector3 a_now = AhT.xform(W[b.up[s]].basis.xform(m.knee_hinge_local[s]));
			const Vector3 a0 = m.rest_g[b.up[s]].basis.orthonormalized().xform(m.knee_hinge_local[s]);
			const Vector3 a0s = arc(d0, d).xform(a0);
			const float r = signed_angle(a0s, a_now, d);
			o.hip_rot[s] = r * DEG * (s == 0 ? -1.0f : 1.0f); // + = knee turned outward
		}
		o.leg_extension[s] = hip.distance_to(ankle) / m.leg_reach[s];
		// ankle (1.4): yaw about the shin's long axis, pitch, then roll about the foot's forward, against rest
		{
			float dd, ab, ro;
			ankle_raw(m, W, s, o.foot_F[s], o.foot_U[s], dd, ab, ro);
			o.ankle_dorsi[s] = dd - m.ankle_rest[s][0];
			o.foot_abd[s] = wrap((ab - m.ankle_rest[s][1]) * RAD) * DEG;
			o.ankle_inv[s] = wrap((ro - m.ankle_rest[s][2]) * RAD) * DEG;
		}
		{
			const Basis Af = anat(m, W, b.foot[s]);
			const Vector3 mid = (o.sole_w[s][BALL_IN] + o.sole_w[s][BALL_OUT]) * 0.5f;
			const Vector3 td = Af.transposed().xform((o.sole_w[s][TOE_TIP] - mid).normalized());
			o.toe_bend[s] = (elev(td) - elev(m.toe_dir0[s])) * DEG;
		}
		// knee over the toes (2.4): shin forward vs foot forward, flattened
		{
			const Vector3 sv = (ankle - knee).normalized();
			const Vector3 as = W[b.lo[s]].basis.xform(m.knee_hinge_shin_local[s]).normalized();
			Vector3 fs = sv.cross(as);
			fs.y = 0;
			Vector3 ff = o.foot_F[s];
			ff.y = 0;
			o.knee_over_toe[s] = (fs.length_squared() > 1e-6f && ff.length_squared() > 1e-6f)
					? std::acos(std::clamp(fs.normalized().dot(ff.normalized()), -1.0f, 1.0f)) * DEG
					: 0;
		}
	}
	// spine and neck: relative anatomical rotations, swing-twist about the up axis (1.5)
	auto spine = [&](int pb, int cb, float &flex, float &side, float &twist) {
		const Basis R = anat(m, W, pb).transposed() * anat(m, W, cb);
		Quaternion sw;
		float tw;
		swing_twist(R.get_rotation_quaternion(), UPV, sw, tw);
		const Vector3 up = sw.xform(UPV);
		flex = std::atan2(up.z, up.y) * DEG;
		side = std::atan2(up.x, up.y) * DEG;
		twist = tw * DEG;
	};
	spine(b.hips, b.lumbar_top, o.lumbar_flex, o.lumbar_side, o.lumbar_twist);
	spine(b.lumbar_top, b.chest, o.thor_flex, o.thor_side, o.thor_twist);
	spine(b.chest, b.head, o.neck_flex, o.neck_side, o.neck_turn);
	// arms
	const Basis Ac = anat(m, W, b.chest), AcT = Ac.transposed();
	o.finger_min = 0;
	o.finger_max_excess = 0;
	for (int s = 0; s < 2; s++) {
		const float lat = s == 0 ? 1.0f : -1.0f;
		const Vector3 sh = W[b.arm[s]].origin, el = W[b.farm[s]].origin;
		const Vector3 d = AcT.xform((el - sh).normalized());
		o.sh_elev[s] = std::acos(std::clamp(-d.y, -1.0f, 1.0f)) * DEG;
		o.sh_back[s] = std::asin(std::clamp(std::max(0.0f, -d.z), 0.0f, 1.0f)) * DEG;
		o.sh_across[s] = 0;
		if (d.y > -0.5f) { // horizontal adduction only means something with the arm raised past 60 deg
			const float hx = -d.x * lat, hz = d.z;
			if (hx > 0) o.sh_across[s] = std::atan2(hx, std::max(hz, 1e-4f)) * DEG * (hz > 0 ? 1.0f : 1.0f);
			if (hx > 0 && hz <= 0) o.sh_across[s] = 90.0f + std::atan2(-hz, hx) * DEG;
		}
		{
			const Basis R = AcT * anat(m, W, b.arm[s]);
			Quaternion sw;
			float tw;
			swing_twist(R.get_rotation_quaternion(), m.arm_dir0[s], sw, tw);
			o.sh_twist[s] = tw * DEG * lat; // + = internal
		}
		float ef;
		elbow_raw(m, W, s, ef);
		o.elbow_flex[s] = ef - m.elbow_rest_signed[s];
		{
			const Basis R = anat(m, W, b.arm[s]).transposed() * anat(m, W, b.hand[s]);
			Quaternion sw;
			float tw;
			swing_twist(R.get_rotation_quaternion(), m.farm_dir0[s], sw, tw);
			o.forearm_twist[s] = tw * DEG;
		}
		{
			const Basis R = anat(m, W, b.farm[s]).transposed() * anat(m, W, b.hand[s]);
			Quaternion sw;
			float tw;
			swing_twist(R.get_rotation_quaternion(), m.hand_dir0[s], sw, tw);
			const Vector3 h0 = m.hand_dir0[s], h = sw.xform(h0);
			const Vector3 palm(0, -1, 0), radial(0, 0, 1);
			o.wrist_flex[s] = (std::atan2(h.dot(palm), h.dot(h0))) * DEG;  // + flexion (toward the palm)
			o.wrist_dev[s] = (std::atan2(h.dot(radial), h.dot(h0))) * DEG; // + radial
		}
		const float lim[3] = {90, 110, 90};
		for (int f = 0; f < 4; f++)
			for (int j = 0; j < 3; j++) {
				const int bi = b.finger[s][f][j];
				if (bi < 0) continue;
				const int pb = m.parent[bi];
				const Vector3 dd = anat(m, W, pb).transposed().xform(W[bi].basis.get_column(1).normalized());
				const Vector3 d0 = m.finger_dir0[s][f][j];
				const float curl = (std::atan2(-dd.y, std::max(1e-4f, dd.dot(Vector3(d0.x, 0, d0.z).normalized()))) - std::atan2(-d0.y, Vector3(d0.x, 0, d0.z).length())) * DEG;
				o.finger_min = std::min(o.finger_min, curl);
				o.finger_max_excess = std::max(o.finger_max_excess, curl - lim[j]);
			}
	}
	// head
	{
		const Basis Ahd = anat(m, W, b.head);
		o.head_roll = std::asin(std::clamp(Ahd.get_column(0).y, -1.0f, 1.0f)) * DEG;
		o.head_pitch = -std::asin(std::clamp(Ahd.get_column(2).y, -1.0f, 1.0f)) * DEG; // + = looking down
	}
	// trunk lean (1.6)
	{
		const Vector3 v = o.neck_base - o.pelvis_c;
		o.trunk_fwd = std::atan2(v.dot(o.pelvis_f), v.y) * DEG;
		o.trunk_side = std::atan2(v.dot(o.pelvis_l), v.y) * DEG;
	}
	// centre of mass (1.6, de Leva)
	{
		Vector3 c;
		const Vector3 headtop = b.head_end >= 0 ? W[b.head_end].origin : o.head_pos + UPV * 0.2f;
		c += (o.neck_base + headtop) * 0.5f * 0.069f;
		c += (o.pelvis_c + (o.neck_base - o.pelvis_c) * 0.5f) * 0.435f;
		for (int s = 0; s < 2; s++) {
			const Vector3 sh = W[b.arm[s]].origin, el = W[b.farm[s]].origin, wr = W[b.hand[s]].origin;
			const Vector3 kn = b.knuckle_mid[s] >= 0 ? W[b.knuckle_mid[s]].origin : wr;
			c += (sh + (el - sh) * 0.58f) * 0.027f;
			c += (el + (wr - el) * 0.46f) * 0.016f;
			c += (wr + (kn - wr) * 0.79f) * 0.006f;
			const Vector3 hip = W[b.up[s]].origin, knee = W[b.lo[s]].origin, ankle = W[b.foot[s]].origin;
			c += (hip + (knee - hip) * 0.41f) * 0.142f;
			c += (knee + (ankle - knee) * 0.44f) * 0.043f;
			c += (o.sole_w[s][HEEL] + (o.sole_w[s][TOE_TIP] - o.sole_w[s][HEEL]) * 0.44f) * 0.014f;
		}
		o.com = c;
	}
	// bone lengths (6.12)
	o.max_bone_len_err_mm = 0;
	o.worst_bone = -1;
	for (int i = 0; i < m.bone_count; i++) {
		if (m.parent[i] < 0) continue;
		const float e = std::fabs(W[i].origin.distance_to(W[m.parent[i]].origin) - m.bone_len[i]) * 1000.0f;
		if (e > o.max_bone_len_err_mm) { o.max_bone_len_err_mm = e; o.worst_bone = i; }
	}
}

void capsules(const BodyModel &m, const Transform3D *W, const Measures &me, Capsule *c) {
	const BodyBones &b = m.b;
	c[CAP_TRUNK] = {me.pelvis_c, me.neck_base, 0.14f, CAP_TRUNK};
	for (int s = 0; s < 2; s++) {
		c[CAP_THIGH_L + s] = {W[b.up[s]].origin, W[b.lo[s]].origin, 0.07f, CAP_THIGH_L + s};
		c[CAP_SHIN_L + s] = {W[b.lo[s]].origin, W[b.foot[s]].origin, 0.05f, CAP_SHIN_L + s};
		c[CAP_UARM_L + s] = {W[b.arm[s]].origin, W[b.farm[s]].origin, 0.05f, CAP_UARM_L + s};
		c[CAP_FARM_L + s] = {W[b.farm[s]].origin, W[b.hand[s]].origin, 0.04f, CAP_FARM_L + s};
	}
	const Vector3 top = b.head_end >= 0 ? W[b.head_end].origin : me.head_pos + Vector3(0, 0.2f, 0);
	c[CAP_HEAD] = {me.head_pos + (top - me.head_pos) * 0.3f, me.head_pos + (top - me.head_pos) * 0.6f, 0.10f, CAP_HEAD};
}

float seg_seg_dist(const Vector3 &p1, const Vector3 &q1, const Vector3 &p2, const Vector3 &q2) {
	const Vector3 d1 = q1 - p1, d2 = q2 - p2, r = p1 - p2;
	const float a = d1.dot(d1), e = d2.dot(d2), f = d2.dot(r);
	float s, t;
	if (a <= 1e-9f && e <= 1e-9f) return r.length();
	if (a <= 1e-9f) {
		s = 0;
		t = std::clamp(f / e, 0.0f, 1.0f);
	} else {
		const float c = d1.dot(r);
		if (e <= 1e-9f) {
			t = 0;
			s = std::clamp(-c / a, 0.0f, 1.0f);
		} else {
			const float bb = d1.dot(d2), den = a * e - bb * bb;
			s = den != 0 ? std::clamp((bb * f - c * e) / den, 0.0f, 1.0f) : 0;
			t = (bb * s + f) / e;
			if (t < 0) { t = 0; s = std::clamp(-c / a, 0.0f, 1.0f); }
			else if (t > 1) { t = 1; s = std::clamp((bb - c) / a, 0.0f, 1.0f); }
		}
	}
	return ((p1 + d1 * s) - (p2 + d2 * t)).length();
}

} // namespace lab
