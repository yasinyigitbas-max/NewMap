#include "mo_layer.h"

#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/variant/quaternion.hpp>

#include <cstring>

using namespace godot;

void MoLayer::set_layer(const Ref<Animation> &p_anim, int p_mask) {
	if (p_anim == anim && p_mask == mask_kind) return;
	anim = p_anim; mask_kind = p_mask;
	mask.clear();
	Skeleton3D *sk = get_skeleton();
	if (!sk || anim.is_null()) return;
	struct M { const char *name; float w; };
	// (the spine's lower bones only part: the legs' hips and lower back carry the walk; all of it from a standing clip
	// stiffened the walk's sway)
	static const M TEXT[] = { { "Bip01_Spine1", 0.4f }, { "Bip01_Spine2", 0.7f }, { "Bip01_Neck", 1.0f }, { "Bip01_Head", 1.0f },
		{ "Bip01_L_Clavicle", 1.0f }, { "Bip01_L_UpperArm", 1.0f }, { "Bip01_L_Forearm", 1.0f }, { "Bip01_L_Hand", 1.0f },
		{ "Bip01_R_Clavicle", 1.0f }, { "Bip01_R_UpperArm", 1.0f }, { "Bip01_R_Forearm", 1.0f }, { "Bip01_R_Hand", 1.0f }, { nullptr, 0 } };
	static const M CALL[] = { { "Bip01_Spine2", 0.3f }, { "Bip01_Neck", 0.8f }, { "Bip01_Head", 0.8f },
		{ "Bip01_R_Clavicle", 1.0f }, { "Bip01_R_UpperArm", 1.0f }, { "Bip01_R_Forearm", 1.0f }, { "Bip01_R_Hand", 1.0f }, { nullptr, 0 } };
	const M *list = p_mask == 2 ? CALL : TEXT;
	for (int i = 0; list[i].name; i++) {
		B b; b.bone = sk->find_bone(list[i].name); b.w = list[i].w;
		if (b.bone < 0) continue;
		// the clip's rotation track for that bone (its path ends ":<bone>")
		for (int k = 0; k < anim->get_track_count(); k++) {
			if (anim->track_get_type(k) != Animation::TYPE_ROTATION_3D) continue;
			const String path = String(anim->track_get_path(k));
			if (path.get_slice(":", path.get_slice_count(":") - 1) == list[i].name) { b.track = k; break; }
		}
		if (b.track >= 0) mask.push_back(b);
	}
	// the fingers go with their hand (a phone held: the clip's own grip)
	const bool right_only = p_mask == 2;
	for (int bi = 0; bi < sk->get_bone_count(); bi++) {
		const String n = sk->get_bone_name(bi);
		if (!n.contains("_Finger")) continue;
		if (right_only && !n.begins_with("Bip01_R_")) continue;
		for (int k = 0; k < anim->get_track_count(); k++) {
			if (anim->track_get_type(k) != Animation::TYPE_ROTATION_3D) continue;
			const String path = String(anim->track_get_path(k));
			if (path.get_slice(":", path.get_slice_count(":") - 1) == n) { B b; b.bone = bi; b.track = k; mask.push_back(b); break; }
		}
	}
}

void MoLayer::_process_modification_with_delta(double p_delta) {
	(void)p_delta;
	Skeleton3D *sk = get_skeleton();
	if (!sk || anim.is_null() || weight <= 0.001f) return;
	const double tt = std::min(std::max(t, 0.0), (double)anim->get_length());
	for (const B &b : mask) {
		const Quaternion q = anim->rotation_track_interpolate(b.track, tt);
		const Quaternion cur = sk->get_bone_pose_rotation(b.bone);
		sk->set_bone_pose_rotation(b.bone, cur.slerp(q, std::min(1.0f, weight * b.w)));
	}
}
