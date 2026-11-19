// CityPed: see city_ped.h.
#include "city_ped.h"

#include <godot_cpp/classes/animation.hpp>
#include <godot_cpp/classes/animation_library.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/skin.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <vector>
#include <cmath>

namespace godot {

static const double GETUP_GATHER = 1.0;   // s: (the figure's old clip only) from lying into the clip's seated start
static const double GETUP_SLOW = 0.3;     // the clip's pace meanwhile
static const char *const GETUP_CLIP = "ual/LayToIdle";   // the Quaternius library's rise from lying on the back

namespace {
const char *BONE_NAMES[pb::NB] = { "Bip01_Pelvis", "Bip01_Spine1", "Bip01_Head", "Bip01_L_UpperArm", "Bip01_L_Forearm", "Bip01_R_UpperArm", "Bip01_R_Forearm",
	"Bip01_L_Thigh", "Bip01_L_Calf", "Bip01_L_Foot", "Bip01_R_Thigh", "Bip01_R_Calf", "Bip01_R_Foot" };
inline vd::V3 v3(const Vector3 &v) { return { (float)v.x, (float)v.y, (float)v.z }; }
inline Vector3 gv(const vd::V3 &v) { return Vector3(v.x, v.y, v.z); }
}

static bool clip_start(Skeleton3D *skel, const Ref<Animation> &a, const Transform3D &skel_in_node, int b_hips, int b_head, Vector3 &r_hips, Vector3 &r_head);

void CityPed::make() {
	if (made) return;
	made = true;
	ResourceLoader *rl = ResourceLoader::get_singleton();
	const bool female = body_id.begins_with("F");
	const String g = female ? "female" : "male", dir = "res://characters/rocketbox/";
	Ref<PackedScene> ps = rl->load(dir + String("hero_") + g + String(".scn"));
	if (ps.is_null()) { UtilityFunctions::push_error("CityPed: no skeleton scene for ", g); return; }
	model = Object::cast_to<Node3D>(ps->instantiate());
	if (!model) return;
	add_child(model);
	const TypedArray<Node> sks = model->find_children("*", "Skeleton3D", true, false);
	if (sks.size() == 0) { UtilityFunctions::push_error("CityPed: the scene has no skeleton"); return; }
	skel = Object::cast_to<Skeleton3D>(sks[0]);
	// the scene carries the player's own model: out with its meshes, in with this person's body
	const TypedArray<Node> old = model->find_children("*", "MeshInstance3D", true, false);
	for (int i = 0; i < old.size(); i++) { Node *n = Object::cast_to<Node>(old[i]); if (n) { n->get_parent()->remove_child(n); n->queue_free(); } }
	Ref<Mesh> mesh = rl->load(dir + String("bodies/") + body_id + String(".res"));
	Ref<Skin> skin = rl->load(dir + String("skin_") + g + String(".res"));
	if (mesh.is_valid()) {
		mi = memnew(MeshInstance3D);
		mi->set_mesh(mesh);
		if (skin.is_valid()) mi->set_skin(skin);
		// (the people's own look, their texture arrays and outfit colours, comes with the crowd's drawing; until then
		// one plain colour, so that the BODY can be seen)
		Ref<StandardMaterial3D> m; m.instantiate(); m->set_albedo(Color(0.62f, 0.56f, 0.5f)); m->set_roughness(0.9f);
		mi->set_material_override(m);
		skel->add_child(mi);
		mi->set_skeleton_path(NodePath(".."));
	}
	anim = memnew(AnimationPlayer);
	model->add_child(anim);
	anim->set_root_node(NodePath(".."));
	Ref<AnimationLibrary> lib = rl->load(dir + String("clips_") + g + String(".res"));
	if (lib.is_valid()) {
		anim->add_animation_library(StringName(), lib);
		// the Quaternius library's clips, fitted to this figure (tool make_anims.gd): "ual/Walk_Loop" and so on
		Ref<AnimationLibrary> ual = rl->load(dir + String("clips_ual_") + g + String(".res"));
		if (ual.is_valid()) anim->add_animation_library(StringName("ual"), ual);
		if (lib->has_animation("get_up")) { Ref<Animation> a = lib->get_animation("get_up"); getup_len = a->get_length(); }
		if (anim->has_animation(clip)) { anim->play(clip); if (clip_at >= 0.0) { anim->seek(clip_at, true); anim->pause(); } }
	}
	// the standing figure in this node's own frame: where each driven bone is, and from them the body's own measures.
	// (after the facing below is settled, the get-up clip's lying start is read: see the end of this function)
	// The body's frame is: facing +z, +x to its left. A figure that faces the other way is turned round first.
	{
		const int hand = skel->find_bone("Bip01_L_Hand"), fing = skel->find_bone("Bip01_L_Finger1");
		const Transform3D t0 = get_global_transform().affine_inverse() * skel->get_global_transform();
		if (hand >= 0 && fing >= 0 && ((t0 * skel->get_bone_global_rest(fing)).origin.z - (t0 * skel->get_bone_global_rest(hand)).origin.z) < 0.0) model->rotate_y(3.14159265);
	}
	skel_in_node = get_global_transform().affine_inverse() * skel->get_global_transform();
	bool ok = true;
	for (int i = 0; i < pb::NB; i++) {
		bone[i] = skel->find_bone(BONE_NAMES[i]);
		if (bone[i] < 0) { ok = false; continue; }
		bone_rest[i] = skel_in_node * skel->get_bone_global_rest(bone[i]);
	}
	auto at = [&](const char *name) { const int k = skel->find_bone(name); return k >= 0 ? (skel_in_node * skel->get_bone_global_rest(k)).origin : Vector3(); };
	if (!ok) { UtilityFunctions::push_error("CityPed: the skeleton is not the Bip01 figure"); skel = nullptr; return; }
	pb::Rest r;
	// the figure's feet on the ground: its ankles are 8.5 cm over it
	const float lift = 0.085f - (float)std::min(at("Bip01_L_Foot").y, at("Bip01_R_Foot").y);
	auto P = [&](const char *name) { const Vector3 p = at(name); return vd::V3{ (float)p.x, (float)p.y + lift, (float)p.z }; };
	const bool l_is_left = at("Bip01_L_Thigh").x > at("Bip01_R_Thigh").x;   // (+x is left for a figure that faces +z)
	const char *LN[2][5] = { { "Bip01_L_UpperArm", "Bip01_L_Forearm", "Bip01_L_Hand", "Bip01_L_Thigh", "Bip01_L_Calf" }, { "Bip01_R_UpperArm", "Bip01_R_Forearm", "Bip01_R_Hand", "Bip01_R_Thigh", "Bip01_R_Calf" } };
	const char *FN[2] = { "Bip01_L_Foot", "Bip01_R_Foot" };
	r.pelvis = P("Bip01_Pelvis");
	{ const vd::V3 a = P("Bip01_Spine"), c = P("Bip01_Spine1"); r.waist = (a + c) * 0.5f; }
	r.neck = P("Bip01_Neck"); r.head = P("Bip01_Head"); r.head_top = r.head.y + 0.20f;
	for (int s = 0; s < 2; s++) {
		const int k = l_is_left ? s : 1 - s;   // the body's side 0 is its LEFT
		r.shoulder[s] = P(LN[k][0]); r.elbow[s] = P(LN[k][1]); r.wrist[s] = P(LN[k][2]); r.hip[s] = P(LN[k][3]); r.knee[s] = P(LN[k][4]); r.ankle[s] = P(FN[k]);
	}
	if (!l_is_left) {   // then the figure's "L" bones are the body's right side: the driven bones swap with them
		for (int i = 0; i < 3; i++) { std::swap(bone[pb::B_THIGH_L + i], bone[pb::B_THIGH_R + i]); std::swap(bone_rest[pb::B_THIGH_L + i], bone_rest[pb::B_THIGH_R + i]); }
		for (int i = 0; i < 2; i++) { std::swap(bone[pb::B_UARM_L + i], bone[pb::B_UARM_R + i]); std::swap(bone_rest[pb::B_UARM_L + i], bone_rest[pb::B_UARM_R + i]); }
	}
	r.mass = female ? 60.0f : 74.0f;
	body.skill = (float)skill;
	body.build(r);
	for (int i = 0; i < pb::NB; i++) centre_rest[i] = gv(body.c_rest[i]) - Vector3(0, lift, 0);
	if (anim && anim->has_animation(GETUP_CLIP)) {   // the Quaternius rise from lying: where its figure lies at its start
		Ref<Animation> a = anim->get_animation(GETUP_CLIP);
		Vector3 hips, head;
		if (clip_start(skel, a, skel_in_node, skel->find_bone("Bip01_Pelvis"), skel->find_bone("Bip01_Head"), hips, head)) {
			has_getup = true; getup_len = a->get_length(); getup_hips = hips; getup_axis = std::atan2(head.x - hips.x, head.z - hips.z);
		}
	}
}

// Where the get-up clip's figure lies at its start: read from the clip's own tracks, bone by bone (node frame).
static bool clip_start(Skeleton3D *skel, const Ref<Animation> &a, const Transform3D &skel_in_node, int b_hips, int b_head, Vector3 &r_hips, Vector3 &r_head) {
	if (a.is_null() || b_hips < 0 || b_head < 0) return false;
	const int n = skel->get_bone_count();
	std::vector<Transform3D> loc(n), glob(n);
	for (int b = 0; b < n; b++) loc[b] = skel->get_bone_rest(b);
	for (int ti = 0; ti < a->get_track_count(); ti++) {
		const NodePath path = a->track_get_path(ti);
		if (path.get_subname_count() < 1) continue;
		const int b = skel->find_bone(path.get_subname(0));
		if (b < 0) continue;
		if (a->track_get_type(ti) == Animation::TYPE_POSITION_3D) loc[b].origin = a->position_track_interpolate(ti, 0.0);
		else if (a->track_get_type(ti) == Animation::TYPE_ROTATION_3D) loc[b].basis = Basis(a->rotation_track_interpolate(ti, 0.0)).scaled_local(loc[b].basis.get_scale());
	}
	for (int b = 0; b < n; b++) { const int par = skel->get_bone_parent(b); glob[b] = (par >= 0 && par < b) ? glob[par] * loc[b] : loc[b]; }
	r_hips = (skel_in_node * glob[b_hips]).origin; r_head = (skel_in_node * glob[b_head]).origin;
	return true;
}

void CityPed::become(const String &p_body, const Ref<Mesh> &p_mesh, const Ref<ShaderMaterial> &p_look, bool p_can_body) {
	body_id = p_body; can_body = p_can_body;
	if (!made || !mi) return;
	if (p_mesh.is_valid()) mi->set_mesh(p_mesh);
	if (p_look.is_valid()) mi->set_material_override(p_look);
	if (mode != MODE_ANIM) { mode = MODE_ANIM; t_mode = 0.0; }
	n_shove = 0; n_boxes = 0;
	cur_clip = StringName(); cur_hold = -1.0; cur_token = 0;
	if (anim) anim->set_speed_scale(1.0);
}

// While it is animated: where it stands, which clip, how fast the clip runs (a walk follows the walker's pace), or
// the moment of the clip it is held at (lying).
void CityPed::drive(const Transform3D &p_at, const StringName &p_clip, double p_speed, double p_hold, int p_token) {
	if (!made || mode != MODE_ANIM) return;
	set_global_transform(p_at);
	if (!anim || !anim->has_animation(p_clip)) return;
	if (p_clip != cur_clip || p_hold != cur_hold || p_token != cur_token) {
		const bool again = p_clip == cur_clip;
		cur_clip = p_clip; cur_hold = p_hold; cur_token = p_token;
		if (p_hold >= 0.0) { anim->play(p_clip, 0.0); anim->seek(p_hold, true); anim->pause(); }
		else { anim->play(p_clip, p_hold < -1.5 ? 0.18 : 0.3); if (again || p_hold < -1.5) anim->seek(0.0, true); }
	} else if (p_hold < 0.0 && p_hold > -1.5 && !anim->is_playing()) anim->play(p_clip, 0.1);   // (a clip that ends starts again while the act lasts)
	if (p_hold < 0.0) anim->set_speed_scale((float)p_speed);
}

double CityPed::clip_len(const StringName &p_clip) const {
	if (!anim || !anim->has_animation(p_clip)) return 0.0;
	const Ref<Animation> a = anim->get_animation(p_clip);
	return a.is_valid() ? a->get_length() : 0.0;
}

Vector3 CityPed::body_at() const {
	if (mode == MODE_BODY) return gv(body.b[pb::B_PELVIS].x);
	return get_global_transform().origin;
}

void CityPed::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) return;
	make();
	set_physics_process(true);
}

void CityPed::set_clip(const String &p_clip) {
	clip = p_clip;
	if (made && anim && mode == MODE_ANIM && anim->has_animation(clip)) anim->play(clip, 0.25);
}

// For pictures and checks: the clip held still at a moment of it (seconds); below 0 = it runs
void CityPed::set_clip_at(double p_t) {
	clip_at = p_t;
	if (!made || !anim || mode != MODE_ANIM || !anim->has_animation(clip)) return;
	if (clip_at >= 0.0) { anim->play(clip, 0.0); anim->seek(clip_at, true); anim->pause(); } else anim->play(clip, 0.25);
}

// The body takes over from the animation: every part where its bone is at this moment
void CityPed::take_over(const Vector3 &p_vel) {
	if (!skel) return;
	const Transform3D S = skel->get_global_transform();
	vd::V3 px[pb::NB], pv[pb::NB]; vd::Q pq[pb::NB];
	Vector3 before[pb::NB];
	for (int i = 0; i < pb::NB; i++) {
		const Transform3D now = S * skel->get_bone_global_pose(bone[i]);
		const Basis R = now.basis.orthonormalized() * bone_rest[i].basis.orthonormalized().inverse();   // its turn from standing
		const Quaternion q = R.get_rotation_quaternion();
		const Vector3 x = now.origin + R.xform(centre_rest[i] - bone_rest[i].origin);
		px[i] = v3(x); pq[i] = vd::Q{ (float)q.x, (float)q.y, (float)q.z, (float)q.w }; pv[i] = v3(p_vel);
		before[i] = now.origin;
	}
	const Vector3 f = get_global_transform().basis.get_column(2);
	body.skill = (float)skill;
	body.gn = vd::V3{ 0, 1, 0 }; body.gd = (float)get_global_transform().origin.y;
	body.start_pose(px, pq, pv, (float)std::atan2(f.x, f.z));
	if (anim) anim->pause();
	mode = MODE_BODY; t_mode = 0.0; takeovers++;
	write_bones();
	// (told: the upper body's bones must be where they were; the legs go to where the feet stand)
	jump_at_takeover = 0.0;
	for (int i = 0; i < pb::B_THIGH_L; i++) jump_at_takeover = std::max(jump_at_takeover, (double)(S * skel->get_bone_global_pose(bone[i])).origin.distance_to(before[i]));
}

// The bones follow the body
void CityPed::write_bones() {
	if (!skel) return;
	const Transform3D Sinv = skel->get_global_transform().affine_inverse();
	int order[pb::NB];
	for (int i = 0; i < pb::NB; i++) order[i] = i;
	std::sort(order, order + pb::NB, [&](int a, int c) { return bone[a] < bone[c]; });   // a parent before its children
	for (int k = 0; k < pb::NB; k++) {
		const int i = order[k];
		const pb::Body &B = body.b[i];
		const Basis R(Quaternion(B.q.x, B.q.y, B.q.z, B.q.w));
		const Transform3D world(R * bone_rest[i].basis, gv(B.x) + R.xform(bone_rest[i].origin - centre_rest[i]));
		skel->set_bone_global_pose(bone[i], Sinv * world);
	}
}

// Back to animation: the node goes to where the body is, the clip blends in from the pose the body left
void CityPed::to_animation(const StringName &p_clip, double p_blend, bool p_from_ground) {
	const pb::Body &P = body.b[pb::B_PELVIS];
	Vector3 at = gv(P.x);
	float yaw = body.heading;
	StringName play = p_clip;
	double blend = p_blend;
	if (p_from_ground && has_getup) {
		// The Quaternius rise from lying on the back. The node is set so that the clip's lying figure lies where the body
		// lies: hips on hips, head toward head. A body on its face is turned onto its back by a longer blend first.
		const vd::V3 d = body.b[pb::B_HEAD].x - P.x;
		yaw = std::atan2(d.x, d.z) - getup_axis;
		const Basis rb(Vector3(0, 1, 0), yaw);
		at = Vector3(P.x.x, 0, P.x.z) - rb.xform(Vector3(getup_hips.x, 0, getup_hips.z));
		play = StringName(GETUP_CLIP);
		blend = body.face_up ? 0.3 : 0.7;
	} else if (p_from_ground) {   // (the figure's old clip: it rises from a seat)
		const vd::V3 d = body.b[pb::B_HEAD].x - P.x;
		yaw = std::atan2(d.x, d.z) + (body.face_up ? 3.14159265f : 0.0f);
		blend = GETUP_GATHER;
	} else at = (gv(body.foot[0].p) + gv(body.foot[1].p)) * 0.5;
	at.y = body.gd;
	// the same pose under the node's new place: the bones are written once more after the move
	set_global_transform(Transform3D(Basis(Vector3(0, 1, 0), yaw).scaled(get_global_transform().basis.get_scale()), at));
	write_bones();
	if (anim && anim->has_animation(play)) {
		anim->set_speed_scale((p_from_ground && !has_getup) ? GETUP_SLOW : 1.0);
		anim->play_with_capture(play, blend);
	}
	cur_clip = StringName(); cur_hold = -1.0; cur_token = 0;
	mode = p_from_ground ? MODE_GETUP : MODE_ANIM;
	t_mode = 0.0;
}

void CityPed::push(const Vector3 &p_impulse, const Vector3 &p_at) {
	if (!made || !skel || !can_body) return;
	if (mode != MODE_BODY) take_over(Vector3());
	int part = pb::B_CHEST; float best = 1.0e9f;
	for (int i = 0; i < pb::NB; i++) { const float d = (float)gv(body.b[i].x).distance_squared_to(p_at); if (d < best) { best = d; part = i; } }
	if (n_shove < 4) shove[n_shove++] = Shove{ part, p_impulse / 12.0, 12 };
}

void CityPed::set_box(int p_index, const Vector3 &p_centre, const Vector3 &p_half, double p_yaw, const Vector3 &p_velocity, int p_count) {
	n_boxes = std::min(std::max(p_count, 0), (int)pb::MAX_BOXES);
	if (p_index < 0 || p_index >= pb::MAX_BOXES) return;
	pb::Box &b = boxes[p_index];
	b.c = v3(p_centre); b.half = v3(p_half); b.yaw = (float)p_yaw; b.v = v3(p_velocity); b.yaw_rate = 0;
}

void CityPed::_physics_process(double p_delta) {
	if (!made || !skel) return;
	t_mode += p_delta;
	if (mode == MODE_ANIM) {
		// a car that reaches it knocks it over: any box whose side is within arm's length of its middle
		const Vector3 o = get_global_transform().origin + Vector3(0, 1.0, 0);
		for (int k = 0; k < n_boxes; k++) {
			const pb::Box &b = boxes[k];
			const float cy = std::cos(b.yaw), sy = std::sin(b.yaw);
			const vd::V3 d = v3(o) - b.c;
			const float lx = d.x * cy - d.z * sy, lz = d.x * sy + d.z * cy;
			if (can_body && std::fabs(lx) < b.half.x + 0.35f && std::fabs(lz) < b.half.z + 0.35f && std::fabs(d.y) < b.half.y + 1.0f && vd::len(b.v) > 0.3f) { take_over(Vector3()); break; }
		}
		return;
	}
	if (mode == MODE_GETUP) {
		if (has_getup) {
			if (t_mode >= getup_len) { mode = MODE_ANIM; t_mode = 0.0; getups++; cur_clip = StringName(); if (anim && anim->has_animation(clip)) anim->play(clip, 0.3); }
			return;
		}
		if (t_mode >= GETUP_GATHER && anim) anim->set_speed_scale(1.0);
		if (t_mode >= GETUP_GATHER + getup_len - GETUP_GATHER * GETUP_SLOW) { mode = MODE_ANIM; t_mode = 0.0; getups++; if (anim && anim->has_animation(clip)) anim->play(clip, 0.3); }
		return;
	}
	// ---- the body is the person now
	{   // the ground under it (one ray)
		Ref<World3D> w = get_world_3d();
		PhysicsDirectSpaceState3D *ss = w.is_valid() ? w->get_direct_space_state() : nullptr;
		if (ss) {
			const Vector3 p = gv(body.b[pb::B_PELVIS].x);
			Ref<PhysicsRayQueryParameters3D> rq = PhysicsRayQueryParameters3D::create(p + Vector3(0, 0.6, 0), p - Vector3(0, 3.0, 0), 0xFFFFFFEF);
			const Dictionary h = ss->intersect_ray(rq);
			if (!h.is_empty()) body.gd = (float)((Vector3)h["position"]).y;
		}
	}
	for (int k = 0; k < n_shove;) {
		Shove &s = shove[k];
		body.impulse(s.part, body.b[s.part].x, v3(s.imp));
		if (--s.frames <= 0) { shove[k] = shove[n_shove - 1]; n_shove--; } else k++;
	}
	body.n_box = n_boxes;
	for (int k = 0; k < n_boxes; k++) body.box[k] = boxes[k];
	const int was = body.state;
	body.step((float)p_delta);
	if (was == pb::ST_BALANCE && body.state != pb::ST_BALANCE) falls++;
	write_bones();
	// (on its feet but never quiet for six seconds: it is taken back anyway. Seen 20 Nov: after a blow in a fight a body
	// kept stepping backwards at a steady 1.1 m/s for as long as it was watched.)
	if (body.state == pb::ST_BALANCE && n_shove == 0 && ((body.settled && t_mode > 0.8) || t_mode > 6.0)) to_animation(clip, body.settled ? 0.35 : 0.6, false);
	else if (body.state == pb::ST_REST && body.t_state > 1.2f) to_animation("get_up", 0.5, true);
}

Dictionary CityPed::get_state() const {
	Dictionary d;
	d["mode"] = mode; d["state"] = body.state; d["steps"] = body.steps; d["lean_deg"] = body.tilt * 57.2958f;
	d["takeovers"] = takeovers; d["falls"] = falls; d["getups"] = getups; d["jump_at_takeover"] = jump_at_takeover;
	d["strength"] = body.strength; d["fastest_part"] = body.max_speed;
	// (the balancing, for a trace) which feet stand, where; where it presses; its middle and how fast that goes; its heading
	{ const vd::V3 c = body.com(), cv = body.com_v(); d["feet_down"] = (body.foot[0].planted ? 1 : 0) + (body.foot[1].planted ? 2 : 0); d["foot0"] = gv(body.foot[0].p); d["foot1"] = gv(body.foot[1].p); d["presses_at"] = gv(body.pressing_at()); d["middle"] = gv(c); d["middle_v"] = gv(cv); d["heading"] = body.heading; d["quiet_s"] = body.quiet; d["settled"] = body.settled; d["boxes"] = n_boxes; d["shoves"] = n_shove; }
	if (skel) {
		const Transform3D S = skel->get_global_transform();
		d["head"] = (S * skel->get_bone_global_pose(bone[pb::B_HEAD])).origin;
		d["pelvis"] = (S * skel->get_bone_global_pose(bone[pb::B_PELVIS])).origin;
		d["foot_l"] = (S * skel->get_bone_global_pose(bone[pb::B_FOOT_L])).origin;
		d["foot_r"] = (S * skel->get_bone_global_pose(bone[pb::B_FOOT_R])).origin;
		bool fine = true;
		for (int i = 0; i < skel->get_bone_count(); i++) { const Vector3 o = skel->get_bone_global_pose(i).origin; if (!std::isfinite((double)o.x) || !std::isfinite((double)o.y) || !std::isfinite((double)o.z) || o.length() > 1.0e5) fine = false; }
		d["bones_fine"] = fine; d["bones"] = skel->get_bone_count();
	}
	return d;
}

void CityPed::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_body_id", "id"), &CityPed::set_body_id);
	ClassDB::bind_method(D_METHOD("get_body_id"), &CityPed::get_body_id);
	ClassDB::bind_method(D_METHOD("set_clip", "clip"), &CityPed::set_clip);
	ClassDB::bind_method(D_METHOD("set_clip_at", "seconds"), &CityPed::set_clip_at);
	ClassDB::bind_method(D_METHOD("get_clip_at"), &CityPed::get_clip_at);
	ClassDB::bind_method(D_METHOD("get_clip"), &CityPed::get_clip);
	ClassDB::bind_method(D_METHOD("set_skill", "skill"), &CityPed::set_skill);
	ClassDB::bind_method(D_METHOD("get_skill"), &CityPed::get_skill);
	ClassDB::bind_method(D_METHOD("push", "impulse", "at"), &CityPed::push);
	ClassDB::bind_method(D_METHOD("set_box", "index", "centre", "half", "yaw", "velocity", "count"), &CityPed::set_box);
	ClassDB::bind_method(D_METHOD("get_state"), &CityPed::get_state);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "body_id"), "set_body_id", "get_body_id");
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "clip"), "set_clip", "get_clip");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "clip_at"), "set_clip_at", "get_clip_at");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "skill"), "set_skill", "get_skill");
}

} // namespace godot
