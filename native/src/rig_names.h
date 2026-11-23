// The bone names the movement code knows (the Rocketbox "Bip01" figure's) and the same bones on Godot's standard humanoid
// skeleton (SkeletonProfileHumanoid: "Hips", "LeftUpperArm" ...). Every body imported onto the standard skeleton
// (tools/people/humanoid: the player v3 and any later character) is driven by the same code through this table.
// rig::find(sk, "Bip01_L_Hand") finds the old name, else the standard one ("LeftHand"). Toes are left out on purpose:
// Meshy's toe joint sits at ankle height, and with none the code takes the ball of the foot 13 cm ahead of the ankle.
#pragma once

#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {
namespace rig {

inline String standard(const String &p_bip) {
	if (!p_bip.begins_with("Bip01_")) return String();
	const String n = p_bip.substr(6);
	static const char *const MID[][2] = { { "Pelvis", "Hips" }, { "Spine", "Spine" }, { "Spine1", "Chest" }, { "Spine2", "UpperChest" },
		{ "Neck", "Neck" }, { "Head", "Head" } };
	for (const auto &m : MID) if (n == m[0]) return m[1];
	if (n.length() < 3 || n[1] != '_') return String();
	const String side = n[0] == 'L' ? "Left" : (n[0] == 'R' ? "Right" : "");
	if (side.is_empty()) return String();
	const String part = n.substr(2);
	static const char *const LIMB[][2] = { { "Clavicle", "Shoulder" }, { "UpperArm", "UpperArm" }, { "Forearm", "LowerArm" }, { "Hand", "Hand" },
		{ "Thigh", "UpperLeg" }, { "Calf", "LowerLeg" }, { "Foot", "Foot" } };
	for (const auto &m : LIMB) if (part == m[0]) return side + String(m[1]);
	if (part.begins_with("Finger") && part.length() >= 7) {   // Finger<f><j>: f 0 thumb .. 4 little, j none / 1 / 2
		static const char *const F[5] = { "Thumb", "Index", "Middle", "Ring", "Little" };
		const int f = part[6] - '0';
		const int j = part.length() > 7 ? part[7] - '0' : 0;
		if (f < 0 || f > 4 || j < 0 || j > 2) return String();
		static const char *const PH[3] = { "Proximal", "Intermediate", "Distal" }, *const PT[3] = { "Metacarpal", "Proximal", "Distal" };
		return side + String(F[f]) + String(f == 0 ? PT[j] : PH[j]);
	}
	return String();
}

inline int find(const Skeleton3D *p_sk, const String &p_name) {
	if (!p_sk) return -1;
	const int b = p_sk->find_bone(p_name);
	if (b >= 0) return b;
	const String s = standard(p_name);
	return s.is_empty() ? -1 : p_sk->find_bone(s);
}

inline bool is_finger(const String &p_bone) {
	return p_bone.contains("_Finger") || ((p_bone.begins_with("Left") || p_bone.begins_with("Right")) &&
			(p_bone.contains("Thumb") || p_bone.contains("Index") || p_bone.contains("Middle") || p_bone.contains("Ring") || p_bone.contains("Little")));
}
inline bool is_right(const String &p_bone) { return p_bone.begins_with("Bip01_R_") || p_bone.begins_with("Right"); }

} // namespace rig
} // namespace godot
