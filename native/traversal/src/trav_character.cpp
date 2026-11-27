// See trav_character.h. Translated from traversal_lab/traversal/character/character.gd, in the script's order.
#include "trav_character.h"

#include "trav_foot_place.h"
#include "trav_hand_place.h"
#include "trav_math.h"
#include "trav_mods.h"

#include <godot_cpp/classes/animation.hpp>
#include <godot_cpp/classes/animation_node_animation.hpp>
#include <godot_cpp/classes/animation_node_blend2.hpp>
#include <godot_cpp/classes/animation_node_time_scale.hpp>
#include <godot_cpp/classes/animation_node_time_seek.hpp>
#include <godot_cpp/classes/animation_node_transition.hpp>
#include <godot_cpp/classes/box_mesh.hpp>
#include <godot_cpp/classes/class_db_singleton.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/typed_array.hpp>

using namespace godot;
using namespace trav;

static const Vector3 UP(0, 1, 0);
static const Vector3 DOWN(0, -1, 0);
static const Vector3 ZERO(0, 0, 0);
static inline double D(real_t x) { return (double)x; }
static inline Vector3 V(double x, double y, double z) { return Vector3((real_t)x, (real_t)y, (real_t)z); }
static inline Vector3 mul(const Vector3 &v, double s) { return v * (real_t)s; }
static inline Vector3 div(const Vector3 &v, double s) { return v / (real_t)s; }
// (an animation's length is a double in the engine and in the script; the C++ binding returns it as a float)
static inline double len(const Ref<Animation> &a) { return (double)a->get("length"); }

static const char *MODEL = "res://traversal/character/player_v4_rooted.scn";
static const char *LIBRARY = "res://traversal/character/library.res";
static const char *SKEL = "Skeleton3D";
static const char *IDLE = "Standing_Idle";
static const char *WALK = "KM_Walk";
static const char *JOG = "KM_Run";
static const char *RUN = "Running";
static const char *FALL = "Falling_Idle";
static const char *CROUCH_IDLE = "KM_Crouch_Idle";
static const char *CROUCH_WALK = "KM_Crouch_Walk";
static const char *BEAM_WALK = "KM_Beam_Walk";
static const char *SIDE_STEP = "KM_Side_Step";
static const char *PHONE_TEXT = "Texting_While_Standing";
static const char *PHONE_CALL = "Male_Talking_On_The_Cell_Phone";
static const TravCharacter::JumpDef JUMP = { "Jump", 0.50, 0.80, 1.30 };
static const TravCharacter::JumpDef RUN_JUMP = { "Running_Jump", 0.0, 0.10, 0.67 };
static const TravCharacter::DropDef DROP_WALK = { "KM_Ledge_Walk_Off", 2.10, 2.62 };
static const TravCharacter::DropDef DROP_RUN = { "KM_Ledge_Run_Off", 1.92, 2.72 };
static const char *SOFTEN_KEY[2] = { "drop_walk", "drop_run" };
static const double SOFTEN_AT[2] = { 3.30, 3.70 };
// (the parts of a Vector2 or a Vector3 are floats in the script too)
static const Vector3 PHONE_SIZE(0.072, 0.148, 0.008);
static const Vector2 PHONE_TEXT_AT(0.27, 0.20);
static const Vector3 PHONE_TEXT_HOLD(0.090, 0.075, 0.020);
static const Vector3 PHONE_CALL_HOLD(0.050, 0.085, 0.030);
static const double PHONE_TEXT_CURL[3] = { 45.0, 70.0, 50.0 };
static const Vector3 PHONE_TEXT_ALONG(0.10, 0.92, -0.30);
static const Vector3 PHONE_TEXT_PALM(0.85, 0.0, 0.35);
static const Vector2 PHONE_CALL_ALONG(0.50, 0.85);
static const double PHONE_CALL_CURL[3] = { 10.0, 75.0, 35.0 };
static const Vector3 PHONE_EAR(0.078, 0.105, 0.012);
static const double CHANGE_PACE[2] = { 0.8, 1.3 };
static const double TURN_PACE[2] = { 0.6, 1.5 };

// the engine's own fposmod, in doubles
static inline double fposmod(double p_x, double p_y) {
	double value = std::fmod(p_x, p_y);
	if (((value < 0) && (p_y > 0)) || ((value > 0) && (p_y < 0))) {
		value += p_y;
	}
	value += 0.0;
	return value;
}

static Array arr3(const double v[3]) {
	Array a;
	a.push_back(v[0]);
	a.push_back(v[1]);
	a.push_back(v[2]);
	return a;
}

TravCharacter::TravCharacter() {
	model_path = MODEL;
	_jump = &JUMP;
	ACTS["cover_in"] = "Stand_To_Cover";
	ACTS["cover_out"] = "Cover_To_Stand";
	ACTS["cover_out_high"] = "Cover_To_Stand_High";
	ACTS["cover_idle"] = "Cover_Idle";
	ACTS["cover_idle_low"] = "Crouch_Cover_Idle";
	ACTS["cover_left"] = "Left_Cover_Sneak";
	ACTS["cover_right"] = "Right_Cover_Sneak";
	ACTS["cover_peek"] = "Crouch_Look_Around_Corner";
	ACTS["cover_peek_high"] = "Standing_Cover_Turn";
	ACTS["cover_peek_m"] = "Crouch_Look_Around_Corner_M";
	ACTS["cover_peek_high_m"] = "Standing_Cover_Turn_M";
	ACTS["door_pull"] = "Open_Door_Outwards";
	ACTS["door_push"] = "Opening_Door_Inwards";
	ACTS["car_in"] = "Entering_Car";
	ACTS["car_out"] = "Exiting_Car";
	ACTS["sit_down"] = "Stand_To_Sit";
	// things in the hand and the fist fight (27 Nov; trav_hold.cpp begins these; NOT in the script version)
	ACTS["pick_box"] = "KM_Pick_Box";
	ACTS["put_box"] = "KM_Put_Box";
	ACTS["pick_bag"] = "KM_Pick_Bag";
	ACTS["put_bag"] = "KM_Put_Bag";
	ACTS["fight_cross"] = "Fight_Cross";
	ACTS["fight_hook_l"] = "Fight_Hook_Lead";
	ACTS["fight_hook_r"] = "Fight_Hook_Rear";
	ACTS["fight_combo"] = "Fight_Combo";
	ACTS["fight_jab"] = "Fight_Jab_Elbow";
	ACTS["fight_hit_ll"] = "Fight_Hit_Light_L";
	ACTS["fight_hit_lr"] = "Fight_Hit_Light_R";
	ACTS["fight_hit_m"] = "Fight_Hit_Medium_R";
	ACTS["fight_hit_bl"] = "Fight_Hit_Big_L";
	ACTS["fight_hit_br"] = "Fight_Hit_Big_R";
	ACTS["fight_hit_body"] = "Fight_Hit_Body";
	ACTS["sit_idle"] = "Sitting_Idle";
	ACTS["sit_up"] = "Sit_To_Stand";
	ACTS["sit_type"] = "Typing";
	ACTS["type_to_sit"] = "Type_To_Sit";
	ACTS["jump"] = "Jump";
	ACTS["run_jump"] = "Running_Jump";
	ACTS["land_soft"] = "Falling_To_Landing";
	ACTS["land_heavy"] = "Hard_Landing";
	ACTS["drop_walk"] = "KM_Ledge_Walk_Off";
	ACTS["drop_run"] = "KM_Ledge_Run_Off";
	ACTS["drop_roll"] = "KM_Land_Roll";
	ACTS["step_up"] = "KM_Step_Up";
	ACTS["step_up_m"] = "KM_Step_Up_M";
	ACTS["vault"] = "Vault_1_Hand";
	ACTS["vault_m"] = "Vault_1_Hand_M";
	ACTS["vault_tuck"] = "KM_Vault_Stand";
	ACTS["climb_up"] = "KM_Climb_Up";
	ACTS["grab_jump"] = "Jump_To_Braced_Hang";
	ACTS["wallrun"] = "Sprint_To_Wall_Climb";
	ACTS["climb_down"] = "Climbing_Down";
	ACTS["balance_fall"] = "Falling_From_Losing_Balance";
	ACTS["get_up_front"] = "Push_Up_To_Idle";
	ACTS["grab_climb"] = "Braced_Hang_To_Crouch";
	ACTS["vault_jump"] = "KM_Jump_Over";
	ACTS["step_on"] = "Step_Onto_Platform";
	ACTS["step_on_m"] = "Step_Onto_Platform_M";
	ACTS["jump_on"] = "Running_Jump_Climb";
	ACTS["jump_on_m"] = "Running_Jump_Climb_M";
	ACTS["stairs_up_walk"] = "Ascending_Stairs";
	ACTS["stairs_up_run"] = "KM_Stairs_Run_Up_D";
	ACTS["stairs_down_walk"] = "KM_Stairs_Walk_Down";
	ACTS["stairs_down_run"] = "KM_Stairs_Run_Down";
	ACTS["steep_up"] = "KM_Climb_Hard";
	ACTS["steep_down"] = "KMY_Down_Hands_Balance_Long";
	ACTS["start_walk"] = "KM_Start_Walk";
	ACTS["start_run"] = "KM_Start_Run";
	ACTS["stop_walk"] = "KM_Stop_Walk";
	ACTS["stop_walk_m"] = "KM_Stop_Walk_M";
	ACTS["steep_down_start"] = "KM_Slope_Down_Start";
	ACTS["steep_down_stop"] = "KM_Slope_Down_Stop";
	ACTS["steep_up_start"] = "KM_Slope_Up_Start";
	ACTS["steep_up_stop"] = "KM_Slope_Up_Stop";
	ACTS["walk_to_run"] = "KM_Walk_To_Run";
	ACTS["walk_to_run_m"] = "KM_Walk_To_Run_M";
	ACTS["run_to_walk"] = "KM_Run_To_Walk";
	ACTS["run_to_walk_m"] = "KM_Run_To_Walk_M";
	ACTS["turn_90"] = "Left_Turn_90";
	ACTS["turn_90_m"] = "Left_Turn_90_M";
	ACTS["turn_180_walk"] = "Walking_Turn_180";
	ACTS["turn_180_walk_m"] = "Walking_Turn_180_M";
	ACTS["turn_180_run"] = "Running_Turn_180";
	ACTS["turn_180_run_m"] = "Running_Turn_180_M";
	ACTS["turn_180_step"] = "KM_Turn_180";
	ACTS["turn_180_step_m"] = "KM_Turn_180_M";
	ACTS["crouch_down"] = "KM_Crouch_Down";
	ACTS["crouch_up"] = "KM_Crouch_Up";
}

void TravCharacter::_bind_methods() {
	ClassDB::bind_method(D_METHOD("_on_jump_started", "push"), &TravCharacter::_on_jump_started);
	ClassDB::bind_method(D_METHOD("_on_landed", "drop"), &TravCharacter::_on_landed);
	ClassDB::bind_method(D_METHOD("_phone_refit"), &TravCharacter::_phone_refit);
	ClassDB::bind_method(D_METHOD("_place_phones"), &TravCharacter::_place_phones);
	ClassDB::bind_method(D_METHOD("hand_turned", "hand", "along", "out"), &TravCharacter::_hand_turned);
	ClassDB::bind_method(D_METHOD("_lead_now"), &TravCharacter::_lead_now);
}

bool TravCharacter::_get(const StringName &p_name, Variant &r_ret) const {
	String n = p_name;
#define G(v) \
	if (n == #v) { \
		r_ret = v; \
		return true; \
	}
	G(ACTS) G(body) G(skel) G(tree) G(player) G(model_path) G(note) G(landing_kind) G(lean) G(arm_open_deg) G(_mode) G(_act)
	G(_act_t) G(_mode_t) G(_moving) G(_scale) G(_natural) G(_settled) G(_measured) G(feet) G(_leg_ik) G(_orient)
	G(_stair_phase) G(_stair_on) G(_steep_on) G(_steep_up) G(_steep_phase) G(_steep_w) G(_arms) G(_sub) G(_sub_in)
	G(hands) G(_slope) G(_hips_fit) G(_free) G(_soft) G(_low_w) G(_narrow_w) G(_squeeze_w) G(_side_t) G(_trunk)
	G(_turn_deg) G(_phone_w) G(_phone_kind) G(_phone_box) G(_phone_box_l) G(_grip) G(_beam_arms) G(_lib) G(_pivot)
	G(_foot_len) G(_jump_low) G(_lean_s) G(_own_mean) G(_gone) G(_slope_sub) G(_slope_in)
#undef G
	return false;
}

bool TravCharacter::_set(const StringName &p_name, const Variant &p_value) {
	String n = p_name;
	if (n == "body") {
		body = Object::cast_to<CharacterBody3D>((Object *)p_value);
		return true;
	}
	if (n == "model_path") {
		model_path = p_value;
		return true;
	}
	if (n == "arm_open_deg") {
		arm_open_deg = p_value;
		return true;
	}
	if (n == "item_grip_w") {
		Array ig = p_value;
		item_grip[0] = ig[0];
		item_grip[1] = ig[1];
		return true;
	}
	if (n == "item_turned") {
		Array itn = p_value;
		item_turned[0] = itn[0];
		item_turned[1] = itn[1];
		return true;
	}
	if (n == "item_hold_w") {
		Array iw = p_value;
		item_w[0] = iw[0];
		item_w[1] = iw[1];
		return true;
	}
	for (int k = 0; k < 2; k++) {
		const char *pre = k == 0 ? "hold_r_" : "hold_b_";
		if (n == String(pre) + "take") {
			if (hold_take[k] != (String)p_value) {
				hold_take[k] = p_value;
				if (_hold_anim[k].is_valid()) {
					_hold_anim[k]->set_animation(hold_take[k]);
				}
			}
			return true;
		}
		if (n == String(pre) + "w") {
			hold_w[k] = p_value;
			return true;
		}
		if (n == String(pre) + "t") {
			hold_t[k] = p_value;
			return true;
		}
	}
	return false;
}

static SkeletonModifier3D *two_bone_ik() {
	return Object::cast_to<SkeletonModifier3D>((Object *)ClassDBSingleton::get_singleton()->instantiate("TwoBoneIK3D"));
}

void TravCharacter::_ready() {
	Ref<PackedScene> ps = ResourceLoader::get_singleton()->load(model_path);
	Node3D *model = Object::cast_to<Node3D>(ps->instantiate());
	Vector3 mr = model->get_rotation();
	mr.y = (real_t)PI;
	model->set_rotation(mr);
	_pivot = memnew(Node3D);
	add_child(_pivot);
	_pivot->add_child(model);
	skel = Object::cast_to<Skeleton3D>(model->get_node_or_null(NodePath(SKEL)));
	_chest_i = skel->find_bone("mixamorig_Spine2");
	_head_i = skel->find_bone("mixamorig_Head");
	_foot_i[0] = skel->find_bone("mixamorig_LeftFoot");
	_foot_i[1] = skel->find_bone("mixamorig_RightFoot");
	_foot_len = D(skel->get_bone_global_rest(skel->find_bone("mixamorig_LeftToeBase")).origin.z) - D(skel->get_bone_global_rest(skel->find_bone("mixamorig_LeftFoot")).origin.z);
	skel->set_modifier_callback_mode_process(Skeleton3D::MODIFIER_CALLBACK_MODE_PROCESS_PHYSICS);
	_lib = ResourceLoader::get_singleton()->load(LIBRARY);
	player = memnew(AnimationPlayer);
	player->set_name("AnimationPlayer");
	model->add_child(player);
	player->add_animation_library(StringName(""), _lib);
	const char *loops[8] = { WALK, JOG, RUN, "KM_Climb_Hard", "KMY_Down_Hands_Balance_Long", CROUCH_WALK, BEAM_WALK, SIDE_STEP };
	for (int k = 0; k < 8; k++) {
		Ref<Animation> a = _lib->get_animation(loops[k]);
		_length[String(loops[k])] = len(a);
		int t = a->find_track(NodePath(vformat("%s:Root", SKEL)), Animation::TYPE_POSITION_3D);
		_stride[String(loops[k])] = D((a->position_track_interpolate(t, len(a)) - a->position_track_interpolate(t, 0.0)).length());
	}
	const char *turns[8] = { "turn_90", "turn_90_m", "turn_180_walk", "turn_180_walk_m", "turn_180_run", "turn_180_run_m", "turn_180_step", "turn_180_step_m" };
	for (int k = 0; k < 8; k++) {
		Ref<Animation> a = _lib->get_animation((String)ACTS[turns[k]]);
		int t = a->find_track(NodePath(vformat("%s:Root", SKEL)), Animation::TYPE_ROTATION_3D);
		PackedFloat32Array table;
		double turned = 0.0;
		double last = 0.0;
		int n = (int)(len(a) * 60.0) + 1;
		for (int i = 0; i < n; i++) {
			Quaternion q = a->rotation_track_interpolate(t, i / 60.0);
			double yaw = wrapf(2.0 * std::atan2(D(q.y), D(q.w)), -PI, PI);
			turned += wrapf(yaw - last, -PI, PI);
			last = yaw;
			table.append((real_t)turned);
		}
		_yaw[String(turns[k])] = table;
	}
	const char *dists[12] = { "start_walk", "start_run", "stop_walk", "stop_walk_m", "steep_down_start", "steep_down_stop", "steep_up_start", "steep_up_stop", "walk_to_run", "walk_to_run_m", "run_to_walk", "run_to_walk_m" };
	for (int k = 0; k < 12; k++) {
		Ref<Animation> a = _lib->get_animation((String)ACTS[dists[k]]);
		int t = a->find_track(NodePath(vformat("%s:Root", SKEL)), Animation::TYPE_POSITION_3D);
		PackedFloat32Array table;
		Vector3 from = a->position_track_interpolate(t, 0.0);
		int n = (int)(len(a) * 60.0) + 1;
		for (int i = 0; i < n; i++) {
			table.append((real_t)maxf(D(a->position_track_interpolate(t, i / 60.0).distance_to(from)), i > 0 ? D(table[i - 1]) : 0.0));
		}
		_dist[String(dists[k])] = table;
		double top = 0.0;
		for (int i = 12; i < table.size(); i++) {
			top = maxf(top, (D(table[i]) - D(table[i - 12])) / 0.2);
		}
		_fastest[String(dists[k])] = top;
	}
	Ref<Animation> ja = _lib->get_animation(JUMP.clip);
	int jt = ja->find_track(NodePath(vformat("%s:mixamorig_Hips", SKEL)), Animation::TYPE_POSITION_3D);
	double lowest = INFINITY;
	for (int i = 0; i < (int)(JUMP.off * 60.0); i++) {
		double y = D(ja->position_track_interpolate(jt, i / 60.0).y);
		if (y < lowest) {
			lowest = y;
			_jump_low = i / 60.0;
		}
	}
	tree = memnew(AnimationTree);
	tree->set_name("AnimationTree");
	tree->set_tree_root(_make_tree());
	tree->set_callback_mode_process(AnimationMixer::ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS);
	model->add_child(tree);
	tree->set_animation_player(tree->get_path_to(player));
	tree->set_root_node(tree->get_path_to(model));
	tree->set_root_motion_track(NodePath(vformat("%s:Root", SKEL)));
	tree->set_active(true);
	const char *side[2] = { "Left", "Right" };
	if (body) {
		feet = memnew(TravFootPlace);
		feet->set_name("FootPlace");
		feet->set("body", body);
		feet->call("bind", skel);
		skel->add_child(feet);
		SkeletonModifier3D *ik = two_bone_ik();
		ik->set_name("LegIK");
		skel->add_child(ik);
		ik->set("setting_count", 2);
		Array targets;
		Array poles;
		for (int f = 0; f < 2; f++) {
			Node3D *t = memnew(Node3D);
			t->set_name(vformat("%sFootTarget", side[f]));
			skel->add_child(t);
			targets.push_back(t);
			Node3D *p = memnew(Node3D);
			p->set_name(vformat("%sKneePole", side[f]));
			skel->add_child(p);
			poles.push_back(p);
			ik->call("set_root_bone", f, skel->find_bone(vformat("mixamorig_%sUpLeg", side[f])));
			ik->call("set_middle_bone", f, skel->find_bone(vformat("mixamorig_%sLeg", side[f])));
			ik->call("set_end_bone", f, skel->find_bone(vformat("mixamorig_%sFoot", side[f])));
			ik->call("set_target_node", f, ik->get_path_to(t));
			ik->call("set_pole_node", f, ik->get_path_to(p));
		}
		feet->set("target", targets);
		feet->set("pole", poles);
		_leg_ik = ik;
		_orient = memnew(TravFootOrient);
		_orient->set_name("FootOrient");
		_orient->set("place", feet);
		skel->add_child(_orient);
	}
	Ref<BoxMesh> slab;
	slab.instantiate();
	slab->set_size(Vector3(PHONE_SIZE.x, PHONE_SIZE.y, PHONE_SIZE.z));
	Ref<StandardMaterial3D> black;
	black.instantiate();
	black->set_albedo(Color(0.05, 0.05, 0.06));
	Ref<StandardMaterial3D> lit;
	lit.instantiate();
	lit->set_albedo(Color(0.55, 0.75, 0.95));
	lit->set_feature(BaseMaterial3D::FEATURE_EMISSION, true);
	lit->set_emission(Color(0.35, 0.5, 0.7));
	Ref<BoxMesh> face;
	face.instantiate();
	face->set_size(V(D(PHONE_SIZE.x) - 0.008, D(PHONE_SIZE.y) - 0.012, 0.001));
	for (int k = 0; k < 2; k++) {
		MeshInstance3D *box = memnew(MeshInstance3D);
		box->set_name(k == 0 ? "Phone" : "PhoneAtEar");
		box->set_mesh(slab);
		box->set_material_override(black);
		box->set_visible(false);
		MeshInstance3D *screen = memnew(MeshInstance3D);
		screen->set_mesh(face);
		screen->set_material_override(lit);
		screen->set_position(V(0.0, 0.0, D(PHONE_SIZE.z) * 0.5 + 0.0006));
		box->add_child(screen);
		skel->add_child(box);
		if (k == 0) {
			_phone_box = box;
		} else {
			_phone_box_l = box;
		}
	}
	skel->connect("skeleton_updated", Callable(this, "_place_phones"));
	_trunk = memnew(TravTrunkTurn);
	_trunk->set_name("TrunkTurn");
	skel->add_child(_trunk);
	SkeletonModifier3D *arms = memnew(TravArmOpen);
	arms->set_name("ArmOpen");
	arms->set("open_deg", arm_open_deg);
	skel->add_child(arms);
	_arms = arms;
	if (body) {
		hands = memnew(TravHandPlace);
		hands->set_name("HandPlace");
		hands->set("body", body);
		hands->set("refit", Callable(this, "_phone_refit"));
		hands->call("bind", skel);
		skel->add_child(hands);
		Array h_targets;
		Array h_poles;
		Array h_ik;
		for (int f = 0; f < 2; f++) {
			Node3D *t = memnew(Node3D);
			t->set_name(vformat("%sHandTarget", side[f]));
			skel->add_child(t);
			h_targets.push_back(t);
			Node3D *p = memnew(Node3D);
			p->set_name(vformat("%sElbowPole", side[f]));
			skel->add_child(p);
			h_poles.push_back(p);
			SkeletonModifier3D *one = two_bone_ik();
			one->set_name(vformat("%sArmIK", side[f]));
			skel->add_child(one);
			one->set("setting_count", 1);
			one->call("set_root_bone", 0, skel->find_bone(vformat("mixamorig_%sArm", side[f])));
			one->call("set_middle_bone", 0, skel->find_bone(vformat("mixamorig_%sForeArm", side[f])));
			one->call("set_end_bone", 0, skel->find_bone(vformat("mixamorig_%sHand", side[f])));
			one->call("set_target_node", 0, one->get_path_to(t));
			one->call("set_pole_node", 0, one->get_path_to(p));
			one->set_influence(0.0);
			h_ik.push_back(one);
		}
		hands->set("target", h_targets);
		hands->set("pole", h_poles);
		hands->set("ik", h_ik);
		SkeletonModifier3D *hand_hold = memnew(TravHandHold);
		hand_hold->set_name("HandHold");
		hand_hold->set("place", hands);
		skel->add_child(hand_hold);
		feet->set("hands", hands);
	}
	_grip = memnew(TravFingerGrip);
	_grip->set_name("FingerGrip");
	skel->add_child(_grip);
	if (body) {
		body->connect("jump_started", Callable(this, "_on_jump_started"));
		body->connect("landed", Callable(this, "_on_landed"));
	}
}

static Ref<AnimationNodeAnimation> clip_node(const String &name) {
	Ref<AnimationNodeAnimation> n;
	n.instantiate();
	n->set_animation(name);
	return n;
}

template <class T>
static Ref<T> fresh() {
	Ref<T> n;
	n.instantiate();
	return n;
}

Ref<AnimationNodeBlendTree> TravCharacter::_make_tree() {
	Ref<AnimationNodeBlendTree> bt;
	bt.instantiate();
	bt->add_node("idle", clip_node(IDLE), Vector2(0, 0));
	Ref<AnimationRootNode> gait = Object::cast_to<AnimationRootNode>((Object *)ClassDBSingleton::get_singleton()->instantiate("AnimationNodeBlendSpace1D"));
	gait->set("min_space", 0.0);
	gait->set("max_space", 2.0);
	gait->set("sync_mode", 2);      // AnimationNodeBlendSpace1D.SYNC_MODE_CYCLIC_MUTABLE
	double at = 0.0;
	const char *three[3] = { WALK, JOG, RUN };
	for (int k = 0; k < 3; k++) {
		Ref<AnimationNodeAnimation> node = clip_node(three[k]);
		node->set_use_custom_timeline(true);
		node->set_timeline_length(1.0);
		node->set_stretch_time_scale(true);
		node->set_start_offset(_phase_offset(three[k]) / (double)_length[String(three[k])]);
		node->set_loop_mode(Animation::LOOP_LINEAR);
		gait->call("add_blend_point", node, at, -1, StringName(three[k]));
		at += 1.0;
	}
	bt->add_node("gait", gait, Vector2(0, 200));
	bt->add_node("gait_speed", fresh<AnimationNodeTimeScale>(), Vector2(200, 200));
	bt->connect_node("gait_speed", 0, "gait");
	bt->add_node("gait_seek", fresh<AnimationNodeTimeSeek>(), Vector2(300, 200));
	bt->connect_node("gait_seek", 0, "gait_speed");
	bt->add_node("ground", fresh<AnimationNodeBlend2>(), Vector2(400, 100));
	bt->connect_node("ground", 0, "idle");
	bt->connect_node("ground", 1, "gait_seek");
	bt->add_node("crouch_idle", clip_node(CROUCH_IDLE), Vector2(0, -300));
	bt->add_node("crouch_walk", clip_node(CROUCH_WALK), Vector2(0, -200));
	bt->add_node("crouch_speed", fresh<AnimationNodeTimeScale>(), Vector2(200, -200));
	bt->connect_node("crouch_speed", 0, "crouch_walk");
	bt->add_node("crouch_ground", fresh<AnimationNodeBlend2>(), Vector2(400, -250));
	bt->connect_node("crouch_ground", 0, "crouch_idle");
	bt->connect_node("crouch_ground", 1, "crouch_speed");
	bt->add_node("stance", fresh<AnimationNodeBlend2>(), Vector2(600, 0));
	bt->connect_node("stance", 0, "ground");
	bt->connect_node("stance", 1, "crouch_ground");
	Ref<AnimationNodeTransition> act = fresh<AnimationNodeTransition>();
	act->set_xfade_time(FADE);
	act->set_input_count(ACTS.size() + 2);
	act->call("set_input_name", 0, "ground");
	act->set_input_reset(0, false);
	bt->add_node("act", act, Vector2(800, 100));
	bt->add_node("beam_idle", clip_node(IDLE), Vector2(0, -500));
	bt->add_node("beam_walk", clip_node(BEAM_WALK), Vector2(0, -400));
	bt->add_node("beam_speed", fresh<AnimationNodeTimeScale>(), Vector2(200, -400));
	bt->connect_node("beam_speed", 0, "beam_walk");
	bt->add_node("beam_ground", fresh<AnimationNodeBlend2>(), Vector2(400, -450));
	bt->connect_node("beam_ground", 0, "beam_idle");
	bt->connect_node("beam_ground", 1, "beam_speed");
	bt->add_node("narrow", fresh<AnimationNodeBlend2>(), Vector2(700, -100));
	bt->connect_node("narrow", 0, "stance");
	bt->connect_node("narrow", 1, "beam_ground");
	bt->add_node("side_step", clip_node(SIDE_STEP), Vector2(0, -600));
	bt->add_node("seek_side", fresh<AnimationNodeTimeSeek>(), Vector2(200, -600));
	bt->connect_node("seek_side", 0, "side_step");
	bt->add_node("squeeze", fresh<AnimationNodeBlend2>(), Vector2(750, -200));
	bt->connect_node("squeeze", 0, "narrow");
	bt->add_node("side_step_m", clip_node(String(SIDE_STEP) + "_M"), Vector2(0, -700));
	bt->add_node("seek_side_m", fresh<AnimationNodeTimeSeek>(), Vector2(200, -700));
	bt->connect_node("seek_side_m", 0, "side_step_m");
	bt->add_node("side_pick", fresh<AnimationNodeBlend2>(), Vector2(450, -650));
	bt->connect_node("side_pick", 0, "seek_side");
	bt->connect_node("side_pick", 1, "seek_side_m");
	bt->connect_node("squeeze", 1, "side_pick");
	bt->connect_node("act", 0, "squeeze");
	bt->add_node("fall_anim", clip_node(FALL), Vector2(400, 300));
	act->call("set_input_name", 1, "fall");
	bt->connect_node("act", 1, "fall_anim");
	int i = 2;
	Array keys = ACTS.keys();
	for (int k = 0; k < keys.size(); k++) {
		String key = keys[k];
		bt->add_node(StringName("anim_" + key), clip_node((String)ACTS[key]), Vector2(400, 300 + i * 100));
		bt->add_node(StringName("seek_" + key), fresh<AnimationNodeTimeSeek>(), Vector2(600, 300 + i * 100));
		bt->connect_node(StringName("seek_" + key), 0, StringName("anim_" + key));
		act->call("set_input_name", i, key);
		if (key == SOFTEN_KEY[0] || key == SOFTEN_KEY[1]) {
			bt->add_node(StringName("held_" + key), clip_node((String)ACTS[key]), Vector2(400, 350 + i * 100));
			bt->add_node(StringName("hold_" + key), fresh<AnimationNodeTimeSeek>(), Vector2(600, 350 + i * 100));
			bt->connect_node(StringName("hold_" + key), 0, StringName("held_" + key));
			bt->add_node(StringName("soft_" + key), fresh<AnimationNodeBlend2>(), Vector2(700, 320 + i * 100));
			bt->connect_node(StringName("soft_" + key), 0, StringName("seek_" + key));
			bt->connect_node(StringName("soft_" + key), 1, StringName("hold_" + key));
			bt->connect_node("act", i, StringName("soft_" + key));
		} else {
			bt->connect_node("act", i, StringName("seek_" + key));
		}
		i += 1;
	}
	bt->add_node("phone_text", clip_node(PHONE_TEXT), Vector2(800, 400));
	bt->add_node("phone_call", clip_node(PHONE_CALL), Vector2(800, 500));
	bt->add_node("phone_pick", fresh<AnimationNodeBlend2>(), Vector2(1000, 450));
	bt->connect_node("phone_pick", 0, "phone_text");
	bt->connect_node("phone_pick", 1, "phone_call");
	Ref<AnimationNodeBlend2> phone = fresh<AnimationNodeBlend2>();
	phone->set_filter_enabled(true);
	for (int b = 0; b < skel->get_bone_count(); b++) {
		String bn = skel->get_bone_name(b);
		if (bn.contains("Arm") || bn.contains("Hand") || bn.contains("Shoulder") || bn.contains("Neck") || bn.contains("Head")) {
			phone->set_filter_path(NodePath(vformat("%s:%s", SKEL, bn)), true);
		}
	}
	bt->add_node("phone", phone, Vector2(1200, 200));
	bt->connect_node("phone", 0, "act");
	bt->connect_node("phone", 1, "phone_pick");
	// Things in the hand (27 Nov, Yasin: "one hand briefcase or plastic bag carry and two handed box carry"; the
	// study: "Bone filters on blend nodes give upper and lower body layering"): the arms of a hold take over the
	// movement as it is; the legs and the trunk stay the movement's own. With nothing held both weights are 0.
	const char *last = "phone";
	for (int k = 0; k < 2; k++) {
		_hold_anim[k] = clip_node(k == 0 ? "Walking_With_Shopping_Bag" : "Jogging_With_Box");
		StringName an = k == 0 ? "hold_r_anim" : "hold_b_anim";
		StringName sn = k == 0 ? "hold_r_seek" : "hold_b_seek";
		StringName hn = k == 0 ? "hold_r" : "hold_b";
		bt->add_node(an, _hold_anim[k], Vector2(1200, 500 + k * 200));
		bt->add_node(sn, fresh<AnimationNodeTimeSeek>(), Vector2(1400, 500 + k * 200));
		bt->connect_node(sn, 0, an);
		Ref<AnimationNodeBlend2> hb = fresh<AnimationNodeBlend2>();
		hb->set_filter_enabled(true);
		for (int b = 0; b < skel->get_bone_count(); b++) {
			String bn = skel->get_bone_name(b);
			bool arm = bn.contains("Arm") || bn.contains("Hand") || bn.contains("Shoulder");
			if (arm && (k == 1 || bn.contains("Right"))) {
				hb->set_filter_path(NodePath(vformat("%s:%s", SKEL, bn)), true);
			}
		}
		bt->add_node(hn, hb, Vector2(1600, 200 + k * 200));
		bt->connect_node(hn, 0, last);
		bt->connect_node(hn, 1, sn);
		last = k == 0 ? "hold_r" : "hold_b";
	}
	bt->connect_node("output", 0, last);
	return bt;
}

void TravCharacter::_head_frame(Vector3 &r_at, Basis &r_turn) {
	int hb = skel->find_bone("mixamorig_Head");
	Transform3D head = skel->get_bone_global_pose(hb);
	r_at = head.origin;
	r_turn = head.basis.orthonormalized() * skel->get_bone_global_rest(hb).basis.orthonormalized().inverse();
}

Transform3D TravCharacter::_text_phone() {
	Vector3 head;
	Basis turn;
	_head_frame(head, turn);
	Vector3 hips = skel->get_bone_global_pose(skel->find_bone("mixamorig_Hips")).origin;
	Vector3 at = V((D(head.x) + D(hips.x)) * 0.5, D(head.y) - D(PHONE_TEXT_AT.x), D(hips.z) + D(PHONE_TEXT_AT.y));
	Vector3 eyes = head + turn.xform(V(0.0, 0.10, 0.09));
	Vector3 face = (eyes - at).normalized();
	Vector3 wide = (V(1.0, 0.0, 0.0) - mul(face, D(face.x))).normalized();
	return Transform3D(Basis(-wide, face.cross(-wide).normalized(), face), at);
}

Transform3D TravCharacter::_call_phone() {
	Vector3 head;
	Basis turn;
	_head_frame(head, turn);
	Vector3 side = turn.xform(V(1.0, 0.0, 0.0)).normalized();
	Vector3 ear = head + turn.xform(PHONE_EAR) + mul(side, D(PHONE_SIZE.z) * 0.5 + 0.004);
	Vector3 up = turn.xform(V(0.0, 0.75, -0.65)).normalized();
	up = (up - mul(side, D(up.dot(side)))).normalized();
	return Transform3D(Basis(up.cross(-side).normalized(), up, -side), ear - mul(up, D(PHONE_SIZE.y) * 0.5 - 0.03));
}

Basis TravCharacter::_hand_turned(int f, const Vector3 &along, const Vector3 &out) {
	const char *side = f == 0 ? "Left" : "Right";
	int hb = skel->find_bone(vformat("mixamorig_%sHand", side));
	Transform3D rest = skel->get_bone_global_rest(hb);
	Vector3 a0 = (skel->get_bone_global_rest(skel->find_bone(vformat("mixamorig_%sHandMiddle1", side))).origin - rest.origin).normalized();
	Vector3 o0 = (DOWN - mul(a0, D(DOWN.dot(a0)))).normalized();
	Vector3 a = along.normalized();
	Vector3 o = (out - mul(a, D(out.dot(a)))).normalized();
	return (Basis(a, o, a.cross(o)) * Basis(a0, o0, a0.cross(o0)).inverse() * rest.basis.orthonormalized()).orthonormalized();
}

void TravCharacter::_phone_hold(Vector3 r_at[2], Basis r_basis[2], double r_w[2]) {
	for (int f = 0; f < 2; f++) {
		r_at[f] = ZERO;
		r_basis[f] = Basis();
		r_w[f] = 0.0;
	}
	double texting = _phone_w * (1.0 - _phone_kind);
	double calling = _phone_w * _phone_kind;
	if (texting > 0.0 && calling <= 0.0) {
		Transform3D ph = _text_phone();
		Vector3 bx = ph.basis.get_column(0);
		Vector3 by = ph.basis.get_column(1);
		Vector3 bz = ph.basis.get_column(2);
		for (int f = 0; f < 2; f++) {
			double side = f == 0 ? -1.0 : 1.0;
			Vector3 wrist = ph.origin + mul(bx, side * D(PHONE_TEXT_HOLD.x)) - by * PHONE_TEXT_HOLD.y - bz * PHONE_TEXT_HOLD.z;
			Vector3 along = mul(bx, -side * D(PHONE_TEXT_ALONG.x)) + by * PHONE_TEXT_ALONG.y + bz * PHONE_TEXT_ALONG.z;
			Vector3 palm = mul(bx, -side * D(PHONE_TEXT_PALM.x)) + by * PHONE_TEXT_PALM.y + bz * PHONE_TEXT_PALM.z;
			r_at[f] = skel->get_global_transform().xform(wrist);
			r_basis[f] = _hand_turned(f, along, palm);
			r_w[f] = texting;
		}
	} else if (calling > 0.0) {
		Transform3D pc = _call_phone();
		Vector3 bx = pc.basis.get_column(0);
		Vector3 by = pc.basis.get_column(1);
		Vector3 bz = pc.basis.get_column(2);
		Vector3 wrist2 = pc.origin + bx * PHONE_CALL_HOLD.x - by * PHONE_CALL_HOLD.y - bz * PHONE_CALL_HOLD.z;
		r_at[0] = skel->get_global_transform().xform(wrist2);
		r_basis[0] = _hand_turned(0, -bx * PHONE_CALL_ALONG.x + by * PHONE_CALL_ALONG.y, bz);
		r_w[0] = calling;
	}
}

void TravCharacter::_phone_thumbs() {
	if (_grip == nullptr) {
		return;
	}
	Array to;
	if (_phone_kind >= 0.5) {
		Transform3D pc = _call_phone();
		to.push_back(pc.origin + mul(pc.basis.get_column(0), D(PHONE_SIZE.x) * 0.5) - mul(pc.basis.get_column(1), 0.02) + mul(pc.basis.get_column(2), 0.006));
		to.push_back(ZERO);
	} else {
		Transform3D pt = _text_phone();
		Vector3 low = pt.origin - mul(pt.basis.get_column(1), 0.035) + mul(pt.basis.get_column(2), D(PHONE_SIZE.z) * 0.5 + 0.008);
		to.push_back(low - mul(pt.basis.get_column(0), 0.014));
		to.push_back(low + mul(pt.basis.get_column(0), 0.014));
	}
	_grip->set("thumb_to", to);
}

void TravCharacter::_phone_refit() {
	if (hands != nullptr && (item_w[0] > 0.0 || item_w[1] > 0.0)) {
		Node *hold = body->get_node_or_null("Hold");
		if (hold != nullptr) {
			hold->call("_refit");
		}
	}
	if (hands == nullptr || _phone_w <= 0.0) {
		return;
	}
	Array turned = hands->get("hold_turned");
	if (!((bool)turned[0] || (bool)turned[1])) {
		return;
	}
	Vector3 at[2];
	Basis bs[2];
	double w[2];
	_phone_hold(at, bs, w);
	Array hold_at = hands->get("hold_at");
	Array hold_basis = hands->get("hold_basis");
	for (int f = 0; f < 2; f++) {
		if ((bool)turned[f] && w[f] > 0.0) {
			hold_at[f] = at[f];
			hold_basis[f] = bs[f];
		}
	}
	_phone_thumbs();
}

void TravCharacter::_place_phones() {
	if (_phone_box == nullptr) {
		return;
	}
	if (_phone_box->is_visible()) {
		_phone_box->set_transform(_text_phone());
	}
	if (_phone_box_l->is_visible()) {
		_phone_box_l->set_transform(_call_phone());
	}
}

double TravCharacter::_phase_offset(const String &n) {
	Ref<Resource> c = ResourceLoader::get_singleton()->load(vformat("res://traversal/character/clips/%s.res", n));
	return fposmod((double)c->get("phase_offset"), (double)c->get("length"));
}

void TravCharacter::_on_jump_started(double push) {
	_jump_still = (bool)body->get("_jump_still");
	_jump = _jump_still ? &JUMP : &RUN_JUMP;
	_jump_e = 0.0;
	_jump_y0 = D(body->get_global_position().y);
	double rise = _jump_still ? (double)body->get("JUMP_RISE") : (double)body->get("JUMP_RISE_RUN");
	_flight = 2.0 * std::sqrt(2.0 * rise / (double)body->get("GRAVITY"));
	_set_mode("jump");
	_show(_jump_still ? "jump" : "run_jump", 0.0);
}

void TravCharacter::_on_landed(double drop) {
	if (_mode == "jump" && drop < 0.9) {
		landing_kind = "jump";
		_set_mode("land");
		_show(_act, _jump->land);
	} else if (drop >= HARD_DROP) {
		landing_kind = "heavy";
		_set_mode("land");
		_show("land_heavy", LAND_HEAVY_CONTACT);
	} else if (_mode == "fall" && _drop != nullptr && drop > SOFT_DROP) {
		landing_kind = "soft";
		_set_mode("land");
		_show(_act.begins_with("drop_") ? _act : String(_drop == &DROP_RUN ? "drop_run" : "drop_walk"), _drop->touch);
	} else if (drop > SOFT_DROP) {
		landing_kind = "soft";
		_set_mode("land");
		_show("land_soft", LAND_SOFT_CONTACT);
	} else {
		_set_mode("ground");
		_show("ground", 0.0);
	}
}

void TravCharacter::_set_mode(const String &m) {
	if (m != "land") {
		landing_kind = "";
	}
	_mode = m;
	_mode_t = 0.0;
}

void TravCharacter::_show(const String &input, double t) {
	String in = input;      // (a copy: `input` may be _act itself)
	if (in != _act) {
		tree->set("parameters/act/transition_request", in);
		_settled = 0.0;
	}
	_act = in;
	_act_t = t;
	_seek();
}

void TravCharacter::_seek() {
	if (ACTS.has(_act)) {
		tree->set(StringName(vformat("parameters/seek_%s/seek_request", _act)), _act_t);
	}
}

double TravCharacter::_clip_length(const String &input) {
	return len(_lib->get_animation((String)ACTS[input]));
}

void TravCharacter::_physics_process(double dt) {
	if (body == nullptr) {
		return;
	}
	bool in_air = (int)(int64_t)body->get("state") >= 2;
	double speed = D(((Vector3)body->get("hvel")).length());
	_mode_t += dt;
	_settled += dt;
	_measure(dt);
	double lead = _lead_now();
	_lead_rising = lead > _lead_last;
	_lead_last = lead;
	if ((bool)body->call("in_move")) {
		if (_mode != "move") {
			_set_mode("move");
			_sub = "";
			_slope_sub = "";
			_stair_on = false;
			_steep_on = false;
		}
		_show((String)body->get("move_clip"), (double)body->get("move_clip_t"));
		_soft = (double)body->get("move_soft");
		landing_kind = (bool)body->get("move_landed") ? (String)body->get("move_landing") : String("");
	} else if (_mode == "move") {
		_set_mode("ground");
		_to_loops();
	}
	if (_mode != "move") {
		_soft = move_toward(_soft, 0.0, dt / FADE);
	}
	for (int k = 0; k < 2; k++) {
		tree->set(StringName(vformat("parameters/soft_%s/blend_amount", SOFTEN_KEY[k])), _act == SOFTEN_KEY[k] ? _soft : 0.0);
		tree->set(StringName(vformat("parameters/hold_%s/seek_request", SOFTEN_KEY[k])), SOFTEN_AT[k]);
	}
	if (_mode == "ground") {
		int st = (int)(int64_t)body->get("stairs");
		double wish = D(((Vector3)body->get("_wish")).length());
		bool low = (bool)body->get("crouched");
		bool plain = !in_air && st == 0 && (int)(int64_t)body->get("terrain") == 0 && !low && (int)(int64_t)body->get("narrow") == 0 && (int)(int64_t)body->get("squeeze") < 2;
		if (low != _low_was) {
			_low_was = low;
			if (speed < 0.3 && !in_air && !_stair_on && !_steep_on && (_act == "ground" || _sub == "crouch")) {
				bool back = _sub == "crouch";
				_sub = "crouch";
				_sub_in = low ? "crouch_down" : "crouch_up";
				_low_w = low ? 0.0 : 1.0;
				_show(_sub_in, back ? clampf(_clip_length(_sub_in) - _act_t, 0.0, _clip_length(_sub_in) - 0.1) : 0.0);
			} else if (_sub != "" || (ACTS.has(_act) && !_stair_on && !_steep_on)) {
				_sub = "";
				_show("ground", 0.0);
			}
		}
		if (_wish_was > RUN_FROM && wish > 0.05 && wish <= SWITCH) {
			_slowing = true;
		} else if (wish > SWITCH || wish < 0.05 || speed <= SWITCH || _sub != "") {
			_slowing = false;
		}
		if (wish > 0.05) {
			_let_go_at = -1.0;
		} else if (_let_go_at < 0.0) {
			_let_go_at = speed;
		}
		if (_sub != "" && _sub != "crouch" && !plain) {
			_sub = "";
			if (!_stair_on && !_steep_on) {
				_show("ground", 0.0);
			}
		}
		if (_sub == "crouch") {
			_act_t += dt;
			if (_act_t >= _clip_length(_sub_in) - 0.05 || speed > 0.3 || in_air) {
				if (_act_t >= _clip_length(_sub_in) - 0.05) {
					_low_w = low ? 1.0 : 0.0;
				}
				_sub = "";
				_show("ground", 0.0);
			} else {
				_seek();
			}
		} else if (_sub == "turn") {
			_turn(dt, wish);
		} else if (_sub == "change") {
			_change(dt, speed, wish);
		} else if (_sub != "") {
			_start_or_stop(dt, speed, wish);
		} else if (plain && _act == "ground" && !_stair_on && !_steep_on) {
			double spot = (double)body->get("spot_total");
			if (spot != 0.0) {
				String kind = (bool)body->get("spot_run") ? "turn_180_run" : (absf(spot) > deg_to_rad(TURN_BIG_DEG) ? "turn_180_walk" : "turn_90");
				PackedFloat32Array base = _yaw[kind];
				_sub = "turn";
				_sub_in = (D(base[base.size() - 1]) > 0.0) == (spot > 0.0) ? kind : kind + String("_m");
				_show(_sub_in, 0.0);
			} else if (WALK_TO_RUN_CLIP && _moving >= 1.0 && _wish_was <= SWITCH && wish > RUN_FROM && speed > 1.0 && speed < SWITCH + 0.3) {
				_begin_change("walk_to_run", speed);
			} else if (_moving >= 1.0 && _slowing && speed > SWITCH) {
				_begin_change("run_to_walk", speed);
			} else if (speed < 0.3 && wish > 0.05 && _moving < 0.5) {
				_sub = "start";
				_sub_in = wish > RUN_FROM ? "start_run" : "start_walk";
				_gone = 0.0;
				_show(_sub_in, 0.0);
			} else if (STOP_CLIP && wish < 0.05 && speed > 0.3 && _let_go_at <= RUN_FROM && _moving >= 1.0) {
				PackedFloat32Array sw = _dist["stop_walk"];
				double total = D(sw[sw.size() - 1]);
				double left = (double)body->call("stop_distance");
				if (left <= total) {
					PackedFloat32Array lead_clip = _lib->get_animation((String)ACTS["stop_walk"])->get_meta("lead", PackedFloat32Array());
					double now = _lead_now();
					double latest = _time_for("stop_walk", total - left);
					double t = latest;
					double best = INFINITY;
					int n = STOP_BY_POSE ? (int)(latest * 30.0) + 1 : 0;
					for (int i = 0; i < n; i++) {
						double gap = absf(absf(D(lead_clip[MIN(i, (int)lead_clip.size() - 1)])) - absf(now));
						if (gap <= best) {
							best = gap;
							t = i / 30.0;
						}
					}
					bool clip_left = D(lead_clip[MIN((int)(t * 30.0), (int)lead_clip.size() - 1)]) > 0.0;
					_sub = "stop";
					_sub_in = clip_left == (now > 0.0) ? "stop_walk" : "stop_walk_m";
					_stop_from = t;
					_stop_left = maxf(left, 0.01);
					_show(_sub_in, t);
				}
			}
		}
		if (_sub != "") {
		} else if (_slope_sub == "stop" && !in_air && (int)(int64_t)body->get("terrain") == 2 && wish < 0.05) {
			_slope_stop(dt, speed);
		} else if (!in_air && st != 0 && speed > 0.15 && !low) {
			_steep_on = false;
			_stairs(dt, st, speed);
		} else if (!in_air && (int)(int64_t)body->get("terrain") == 2 && speed > 0.1 && !low && _steep_ahead()) {
			_stair_on = false;
			if (_steep_on && wish < 0.05 && _slope_sub == "" && (_act == "steep_down" || _act == "steep_up")) {
				_slope_sub = "stop";
				_slope_in = _steep_up ? "steep_up_stop" : "steep_down_stop";
				PackedFloat32Array stop_table = _dist[_slope_in];
				_show(_slope_in, _time_for(_slope_in, D(stop_table[stop_table.size() - 1]) - (double)body->call("stop_distance")));
			} else {
				_steep(dt, speed);
			}
		} else if (_stair_on || _steep_on) {
			if (_stair_on && ACTS.has(_act)) {
				Ref<Animation> a = _lib->get_animation((String)ACTS[_act]);
				double since_left = fposmod(_stair_phase - _phase_offset((String)ACTS[_act]) / len(a), 1.0);
				tree->set("parameters/gait_seek/seek_request", since_left);
			}
			_stair_on = false;
			_steep_on = false;
			_show("ground", 0.0);
		}
		if (in_air) {
			_sub = "";
			_slope_sub = "";
			_stair_on = false;
			_steep_on = false;
			_drop = speed > RUN_FROM ? &DROP_RUN : &DROP_WALK;
			_set_mode("fall");
			_show(speed > RUN_FROM ? "drop_run" : "drop_walk", _drop->leaves);
		}
		_wish_was = wish;
	} else if (_mode == "jump") {
		_jump_e += dt;
		if (in_air) {
			double air = clampf((double)body->get("air_time") / _flight, 0.0, 1.0);
			_act_t = lerpf(_jump->off, _jump->land, air);
			if ((double)body->get("air_time") > _flight + 0.3 || D(body->get_global_position().y) < _jump_y0 - JUMP_BELOW) {
				_drop = nullptr;
				_set_mode("fall");
				_show("fall", 0.0);
			}
		} else if ((double)body->get("jump_timer") > 0.0) {
			if (_jump_still) {
				double dip = (double)body->get("JUMP_DIP_STAND");
				double push = (double)body->get("JUMP_PUSH_STAND");
				if (_jump_e < dip) {
					_act_t = _jump_low * _jump_e / dip;
				} else {
					_act_t = lerpf(_jump_low, _jump->off, clampf((_jump_e - dip) / push, 0.0, 1.0));
				}
			} else {
				_act_t = minf(_act_t + dt, _jump->off);
			}
		} else if (_mode_t > 0.2) {
			_set_mode("ground");
			_show("ground", 0.0);
		}
		_seek();
	} else if (_mode == "fall") {
		Dictionary ahead;
		if (in_air) {
			ahead = body->call("landing_ahead");
		}
		String meet = "";
		if (!ahead.is_empty()) {
			if ((double)ahead["drop"] >= HARD_DROP && (double)ahead["time"] <= LAND_HEAVY_CONTACT) {
				meet = "land_heavy";
			} else if ((double)ahead["drop"] > SOFT_DROP && (double)ahead["drop"] < HARD_DROP && _drop == nullptr && (double)ahead["time"] <= LAND_SOFT_CONTACT) {
				meet = "land_soft";
			}
		}
		if (!in_air) {
			_set_mode("ground");
			_show("ground", 0.0);
		} else if (meet != "") {
			_drop = nullptr;
			_show(meet, (meet == "land_heavy" ? LAND_HEAVY_CONTACT : LAND_SOFT_CONTACT) - (double)ahead["time"]);
		} else if (_act.begins_with("land_")) {
		} else if (_drop != nullptr) {
			_act_t += dt;
			if (_act_t >= _drop->touch - 0.04) {
				_drop = nullptr;
				_show("fall", 0.0);
			} else {
				_seek();
			}
		}
	} else if (_mode == "land") {
		if (in_air) {
			_drop = nullptr;
			_set_mode("fall");
			_show("fall", 0.0);
		} else {
			_act_t += dt;
			bool done = _act_t >= _clip_length(_act) - 0.05;
			if (done || (speed > 1.0 && _mode_t > 0.45 && _act != "run_jump")) {
				_set_mode("ground");
				_show("ground", 0.0);
			} else {
				_seek();
			}
		}
	}
	_ground(dt, speed);
	_lean(dt, !in_air);
	if (feet) {
		double want_slope = ((_stair_on || _steep_on) && ACTS.has(_act)) ? (double)_lib->get_animation((String)ACTS[_act])->get_meta("slope", 0.0) : 0.0;
		feet->set("by_speed", _steep_on);
		Array st_m;
		if ((bool)body->call("in_move")) {
			st_m = body->get("move_step");
		}
		feet->set("step_high", st_m.size() >= 3 ? (double)st_m[1] : 0.0);
		feet->set("step_edge", st_m.size() >= 3 ? (double)st_m[0] : 0.0);
		feet->set("step_rise", st_m.size() >= 3 ? (double)st_m[2] : 0.0);
		feet->set("step_real", st_m.size() >= 4 ? (double)st_m[3] : 0.0);
		feet->set("base", (bool)body->call("in_move") ? (double)body->get("move_base") : 0.0);
		feet->set("stand_wide", _act == "ground" ? STAND_WIDE * (1.0 - _moving) * (1.0 - _low_w) : 0.0);
		feet->set("stand_on", _act == "ground" ? (1.0 - _moving) : 0.0);
		if (want_slope != _slope_to) {
			_slope_from = _slope;
			_slope_to = want_slope;
			_slope_t = 0.0;
		}
		_slope_t += dt;
		_slope = lerpf(_slope_from, _slope_to, clampf(_slope_t / FADE, 0.0, 1.0));
		feet->set("clip_slope", _slope);
		double riser = (double)body->get("stair_riser");
		bool on_stairs = _stair_on && riser > 0.0 && ACTS.has(_act);
		double want_fit = 0.0;
		if (on_stairs) {
			Ref<Animation> a = _lib->get_animation((String)ACTS[_act]);
			double real = signf((double)(int)(int64_t)body->get("stairs")) * riser / (double)body->get("stair_tread");
			want_fit = -(want_slope - real) * (double)a->get_meta("pivot", 0.0);
			double tread = (double)body->get("stair_tread");
			Vector3 dir = body->get("stair_dir");
			double down = _phase_offset((String)ACTS[_act]) / len(a);
			Array lands;
			for (int f = 0; f < 2; f++) {
				double to_go = fposmod(down + 0.5 * f - _stair_phase, 1.0);
				lands.push_back(body->get_global_position() + mul(dir, to_go * 2.0 * tread + (double)a->get_meta("reach", 0.0)));
			}
			feet->set("land_at", lands);
			feet->set("stride_dir", dir);
		}
		feet->set("stride_fit", on_stairs);
		if (_low_w > 0.0 && _act == "ground") {
			double top = D(skel->get_global_transform().xform(skel->get_bone_global_pose(_head_i).origin).y) - D(body->get_global_position().y) + HEAD_OVER_JOINT;
			want_fit -= maxf(top - ((double)body->get("CROUCH_HEIGHT") - HEAD_ROOM), 0.0) * _low_w;
		}
		want_fit -= (double)body->get("cover_drop");
		_hips_fit += (want_fit - _hips_fit) * minf(dt / FADE, 1.0);
		feet->set("hips_fit", _hips_fit);
		double w = (double)feet->get("weight");
		_free = move_toward(_free, ((bool)body->call("in_move") && (bool)body->get("move_free")) ? 1.0 : 0.0, dt / 0.15);
		w *= 1.0 - _free;
		feet->set_influence(1.0 - _free);
		_leg_ik->set_influence(w);
		_orient->set_influence(w);
	}
	_steep_w = move_toward(_steep_w, _steep_on ? 1.0 : 0.0, dt / FADE);
	_beam_arms = move_toward(_beam_arms, (_mode != "move" && (int)(int64_t)body->get("squeeze") < 2) ? _narrow_w * (1.0 - _moving) : 0.0, dt / FADE);
	int ph = (int)(int64_t)body->get("phone");
	bool seated = _mode == "move" && (_act == "sit_idle" || _act == "sit_down" || _act == "sit_up");
	bool phone_ok = ph > 0 && (seated || (_mode == "ground" && !(bool)body->get("crouched") && (int)(int64_t)body->get("narrow") == 0 && (int)(int64_t)body->get("squeeze") < 2));
	phone_ok = phone_ok && hold_w[0] <= 0.0 && hold_w[1] <= 0.0;       // (not with something else in his hands)
	_phone_w = move_toward(_phone_w, phone_ok ? 1.0 : 0.0, dt / PHONE_FADE);
	if (ph > 0 && _phone_w < 0.05) {
		_phone_kind = (double)(ph - 1);
	}
	_phone_kind = move_toward(_phone_kind, ph > 0 ? (double)(ph - 1) : _phone_kind, dt / PHONE_FADE);
	tree->set("parameters/phone/blend_amount", _phone_w);
	tree->set("parameters/hold_r/blend_amount", hold_w[0]);
	tree->set("parameters/hold_b/blend_amount", hold_w[1]);
	if (hold_w[0] > 0.0) {
		tree->set("parameters/hold_r_seek/seek_request", hold_t[0]);
	}
	if (hold_w[1] > 0.0) {
		tree->set("parameters/hold_b_seek/seek_request", hold_t[1]);
	}
	tree->set("parameters/phone_pick/blend_amount", _phone_kind);
	if (_phone_box) {
		_phone_box->set_visible(_phone_w > 0.5 && _phone_kind < 0.5);
		_phone_box_l->set_visible(_phone_w > 0.5 && _phone_kind >= 0.5);
	}
	_arms->set("palm_back", _squeeze_w);
	_arms->set("flat", _squeeze_w);
	_arms->set("fwd_deg", (int)(int64_t)body->get("squeeze") == 3 ? SIDLE_ARMS_FWD_DEG * _squeeze_w : 0.0);
	_arms->set("open_deg", arm_open_deg * (1.0 - maxf(maxf(absf(_turn_deg) / SHOULDER_TURN_DEG, _squeeze_w), _phone_w)) + SIDE_ARMS_DEG * _squeeze_w + (_steep_up ? STEEP_ARMS_UP_DEG : STEEP_ARMS_DEG) * _steep_w + BEAM_ARMS_DEG * _beam_arms);
	if (hands) {
		Array mh;
		if ((bool)body->call("in_move")) {
			mh = body->get("move_hand");
		}
		double w[2] = { 0.0, 0.0 };
		Array held;
		if (mh.size() == 3 && mh[0].get_type() != Variant::ARRAY) {
			held.push_back(mh);
		} else {
			held = mh;
		}
		bool flat[2] = { false, false };
		Array hold_at = hands->get("hold_at");
		Array hold_basis = hands->get("hold_basis");
		for (int k = 0; k < held.size(); k++) {
			Array one = held[k];
			int which = (int)(int64_t)one[0];
			w[which] = (double)one[2];
			hold_at[which] = one[1];
			flat[which] = one.size() > 3 && (bool)one[3];
		}
		bool turned[2] = { false, false };
		if (_phone_w > 0.0 && w[0] <= 0.0 && w[1] <= 0.0) {
			Vector3 at[2];
			Basis bs[2];
			double hw[2];
			_phone_hold(at, bs, hw);
			for (int f = 0; f < 2; f++) {
				if (hw[f] > 0.0) {
					hold_at[f] = at[f];
					hold_basis[f] = bs[f];
					w[f] = hw[f];
					turned[f] = true;
				}
			}
		}
		// a hand on the thing he holds (its place is set at modifier time, from the finished pose: _phone_refit)
		for (int f = 0; f < 2; f++) {
			if (item_w[f] > 0.0 && w[f] <= 0.0) {
				w[f] = item_w[f];
				turned[f] = item_turned[f];     // (turned to lie on it: its turn is set with its place)
			}
		}
		Array a_turned;
		a_turned.push_back(turned[0]);
		a_turned.push_back(turned[1]);
		hands->set("hold_turned", a_turned);
		if (_grip) {
			double calling = _phone_w * _phone_kind;
			double texting = _phone_w * (1.0 - _phone_kind);
			Array gw;
			gw.push_back(turned[0] ? w[0] : 0.0);
			gw.push_back(turned[1] ? w[1] : 0.0);
			_grip->set("w", gw);
			Array gd;
			gd.push_back(arr3(calling >= texting ? PHONE_CALL_CURL : PHONE_TEXT_CURL));
			gd.push_back(arr3(PHONE_TEXT_CURL));
			_grip->set("deg", gd);
			Array tw;
			tw.push_back(turned[0] ? w[0] : 0.0);
			tw.push_back(turned[1] ? w[1] : 0.0);
			_grip->set("thumb_w", tw);
			_phone_thumbs();
			if (item_grip[0] > 0.0 || item_grip[1] > 0.0 || item_w[0] > 0.0 || item_w[1] > 0.0) {
				// a thing in the hand: the study, "everyday grips use about 61, 60 and 39 degrees at the three finger
				// joints"; a hand that lies flat on it (a box's side) stays open
				static const double ITEM_CURL[3] = { 61.0, 60.0, 39.0 };
				Array gw2;
				gw2.push_back(item_grip[0]);
				gw2.push_back(item_grip[1]);
				_grip->set("w", gw2);
				Array gd2;
				gd2.push_back(arr3(ITEM_CURL));
				gd2.push_back(arr3(ITEM_CURL));
				_grip->set("deg", gd2);
				Array tw2;
				tw2.push_back(0.0);
				tw2.push_back(0.0);
				_grip->set("thumb_w", tw2);
			}
		}
		Array a_loose;
		a_loose.push_back(false);
		a_loose.push_back(false);
		hands->set("hold_loose", a_loose);
		Array a_w;
		a_w.push_back(w[0]);
		a_w.push_back(w[1]);
		hands->set("hold_w", a_w);
		Array a_flat;
		a_flat.push_back(flat[0]);
		a_flat.push_back(flat[1]);
		hands->set("hold_flat", a_flat);
		hands->set("on", _steep_on && ACTS.has(_act));
		if (_steep_on && ACTS.has(_act)) {
			Ref<Animation> a = _lib->get_animation((String)ACTS[_act]);
			hands->set("clip_slope", (double)a->get_meta("slope", 0.0));
			hands->set("hand_low", (double)a->get_meta("hand_low", 0.0));
		}
	}
	note = vformat("%s  gait x%.2f", _mode != "land" ? _mode : vformat("land (%s)", landing_kind), _scale);
}

void TravCharacter::_stairs(double dt, int st, double speed) {
	double tread = (double)body->get("stair_tread");
	bool run = D(((Vector3)body->get("_wish")).length()) > tread / STAIR_RUN;
	String input = vformat("stairs_%s_%s", st > 0 ? "up" : "down", run ? "run" : "walk");
	Ref<Animation> a = _lib->get_animation((String)ACTS[input]);
	double along = D((body->get_global_position() - (Vector3)body->get("stair_edge")).dot((Vector3)body->get("stair_dir")));
	double steps = (double)(int)(int64_t)body->get("stair_count") + clampf(along / tread, 0.0, 1.0);
	double lands = 0.5 - (double)a->get_meta("reach", 0.0) / tread;
	if (st < 0) {
		lands += 0.5 * _foot_len / tread;
	}
	double cycle = _phase_offset((String)ACTS[input]) / len(a) + (steps - lands) * 0.5;
	_stair_phase += speed * dt / (2.0 * tread);
	if (!_stair_on) {
		double lead = D(skel->get_bone_global_pose(_foot_i[0]).origin.z) - D(skel->get_bone_global_pose(_foot_i[1]).origin.z);
		double since_left = fposmod(cycle - _phase_offset((String)ACTS[input]) / len(a), 1.0);
		bool clip_left = since_left < 0.25 || since_left > 0.75;
		_stair_phase = clip_left == (lead > 0.0) ? cycle : cycle + 0.5;
	} else {
		_stair_phase += wrapf(cycle - _stair_phase, -0.25, 0.25) * minf(dt * STAIR_PULL, 1.0);
	}
	_stair_on = true;
	_show(input, fposmod(_stair_phase, 1.0) * len(a));
}

double TravCharacter::_lead_now() {
	return D(skel->get_bone_global_pose(_foot_i[0]).origin.z) - D(skel->get_bone_global_pose(_foot_i[1]).origin.z);
}

double TravCharacter::_time_for(const String &input, double d) {
	PackedFloat32Array table = _dist[input];
	for (int i = 0; i < table.size(); i++) {
		if (D(table[i]) >= d) {
			return i / 60.0;
		}
	}
	return (table.size() - 1) / 60.0;
}

void TravCharacter::_to_loops() {
	_sub = "";
	double speed = D(((Vector3)body->get("hvel")).length());
	PackedFloat32Array loop = _lib->get_animation(speed < SWITCH ? WALK : JOG)->get_meta("lead", PackedFloat32Array());
	double now = _lead_now();
	double at = now > 0.0 ? 0.0 : 0.5;
	if (loop.size() > 2) {
		double best = INFINITY;
		for (int i = 0; i < loop.size() - 1; i++) {
			if ((D(loop[i + 1]) > D(loop[i])) != _lead_rising) {
				continue;
			}
			double gap = absf(D(loop[i]) - now);
			if (gap < best) {
				best = gap;
				at = (double)i / (double)(loop.size() - 1);
			}
		}
	}
	tree->set("parameters/gait_seek/seek_request", at);
	_show("ground", 0.0);
}

double TravCharacter::_time_for_yaw(const String &input, double angle) {
	PackedFloat32Array table = _yaw[input];
	for (int i = 0; i < table.size(); i++) {
		if (absf(D(table[i])) >= angle) {
			return i / 60.0;
		}
	}
	return (table.size() - 1) / 60.0;
}

void TravCharacter::_turn(double dt, double wish) {
	double total = (double)body->get("spot_total");
	if (total == 0.0) {
		if (_sub_in.begins_with("turn_180_run") || (bool)body->get("spot_walk")) {
			_moving = 1.0;
		}
		_to_loops();
		return;
	}
	PackedFloat32Array table = _yaw[_sub_in];
	double done = 1.0 - absf((double)body->get("spot_left")) / maxf(absf(total), 0.001);
	double want = _time_for_yaw(_sub_in, absf(D(table[table.size() - 1])) * clampf(done, 0.0, 1.0));
	_act_t = clampf(want, _act_t + dt * TURN_PACE[0], _act_t + dt * TURN_PACE[1]);
	_seek();
}

void TravCharacter::_change(double dt, double speed, double wish) {
	Ref<Animation> a = _lib->get_animation((String)ACTS[_sub_in]);
	bool to_run = _sub_in.begins_with("walk_to_run");
	_gone += speed * dt;
	_act_t = maxf(_act_t, _time_for(_sub_in, _change_from + _gone));
	bool over = to_run ? (speed > (double)_fastest[_sub_in]) : (speed < SWITCH);
	bool called_off = wish < 0.05 || (to_run && wish <= SWITCH) || (!to_run && wish > RUN_FROM);
	if (_act_t >= len(a) - 0.1 || over || called_off) {
		_to_loops();
	} else {
		_seek();
	}
}

void TravCharacter::_begin_change(const String &kind, double speed) {
	PackedFloat32Array table = _dist[kind];
	PackedFloat32Array lead_clip = _lib->get_animation((String)ACTS[kind])->get_meta("lead", PackedFloat32Array());
	double now = _lead_now();
	int at = -1;
	bool mirror = false;
	double best = INFINITY;
	for (int i = 6; i < table.size() - 6; i += 2) {
		double own = (D(table[i + 6]) - D(table[i - 6])) / 0.2;
		if (own < speed * CHANGE_PACE[0] || own > speed * CHANGE_PACE[1]) {
			continue;
		}
		int f = MIN((int)(i / 2.0), (int)lead_clip.size() - 2);
		for (int mk = 0; mk < 2; mk++) {
			bool m = mk == 1;
			double here = m ? -D(lead_clip[f]) : D(lead_clip[f]);
			double next = m ? -D(lead_clip[f + 1]) : D(lead_clip[f + 1]);
			if ((next > here) != _lead_rising) {
				continue;
			}
			if (absf(here - now) < best) {
				best = absf(here - now);
				at = i;
				mirror = m;
			}
		}
	}
	if (at < 0) {
		return;
	}
	_sub = "change";
	_sub_in = mirror ? kind + String("_m") : kind;
	_change_from = D(table[at]);
	_gone = 0.0;
	_show(_sub_in, at / 60.0);
}

void TravCharacter::_start_or_stop(double dt, double speed, double wish) {
	Ref<Animation> a = _lib->get_animation((String)ACTS[_sub_in]);
	PackedFloat32Array table = _dist[_sub_in];
	if (_sub == "start") {
		if (wish < 0.05) {
			_to_loops();
			return;
		}
		_gone += speed * dt;
		_act_t = maxf(_act_t, _time_for(_sub_in, _gone));
		int n = table.size();
		double end_speed = (D(table[n - 1]) - D(table[MAX(n - 13, 0)])) / 0.2;
		if (_act_t >= len(a) - 0.12 || speed > end_speed * START_OVER + START_OVER_MORE) {
			_to_loops();
		} else {
			_seek();
		}
	} else {
		if (wish > 0.05) {
			_to_loops();
			return;
		}
		if (speed > 0.05) {
			if (STOP_BY_POSE) {
				double done = 1.0 - (double)body->call("stop_distance") / _stop_left;
				_act_t = maxf(_act_t, lerpf(_stop_from, _time_for(_sub_in, D(table[table.size() - 1])), clampf(done, 0.0, 1.0)));
			} else {
				_act_t = maxf(_act_t, _time_for(_sub_in, D(table[table.size() - 1]) - (double)body->call("stop_distance")));
			}
		} else {
			_act_t += dt;
		}
		if (_act_t >= len(a) - 0.02) {
			_sub = "";
			_show("ground", 0.0);
		} else {
			_seek();
		}
	}
}

void TravCharacter::_slope_stop(double dt, double speed) {
	PackedFloat32Array table = _dist[_slope_in];
	if (speed > 0.05) {
		_act_t = maxf(_act_t, _time_for(_slope_in, D(table[table.size() - 1]) - (double)body->call("stop_distance")));
	} else {
		_act_t += dt;
	}
	if (_act_t >= _clip_length(_slope_in) - 0.02) {
		_slope_sub = "";
		_steep_on = false;
		_show("ground", 0.0);
	} else {
		_seek();
	}
}

bool TravCharacter::_steep_ahead() {
	Vector3 v = body->get("hvel");
	if (D(v.length()) < 0.05) {
		return true;
	}
	double here = deg_to_rad((double)body->get("slope_deg"));
	Vector3 at = body->get_global_position() + mul(v.normalized(), STEEP_STEP * std::cos(here));
	TypedArray<RID> ex;
	ex.push_back(body->get_rid());
	Dictionary hit = body->get_world_3d()->get_direct_space_state()->intersect_ray(PhysicsRayQueryParameters3D::create(at + V(0.0, 1.5, 0.0), at - V(0.0, 1.5, 0.0), body->get_collision_mask(), ex));
	if (hit.is_empty()) {
		return false;
	}
	return rad_to_deg(std::acos(clampf(D(((Vector3)hit["normal"]).y), -1.0, 1.0))) > (double)body->get("SLOPE_HANDS_DEG");
}

void TravCharacter::_steep(double dt, double speed) {
	double grade = (double)body->get("grade");
	if (!_steep_on) {
		_steep_up = grade >= 0.0;
	} else if (absf(grade) > STEEP_TURN) {
		_steep_up = grade > 0.0;
	}
	if (!_steep_on && speed < 0.4) {
		_slope_sub = "start";
		_slope_in = _steep_up ? "steep_up_start" : "steep_down_start";
		_gone = 0.0;
		_steep_on = true;
		_show(_slope_in, 0.0);
		return;
	}
	if (_slope_sub == "start") {
		if (_steep_up != (_slope_in == "steep_up_start")) {
			_slope_sub = "";
		} else {
			_gone += speed * dt;
			_act_t = maxf(_act_t, _time_for(_slope_in, _gone));
			if (_act_t >= _clip_length(_slope_in) - 0.05) {
				_slope_sub = "";
				_steep_phase = 0.0;
			} else {
				_seek();
				return;
			}
		}
	}
	_slope_sub = "";
	String input = _steep_up ? "steep_up" : "steep_down";
	Ref<Animation> a = _lib->get_animation((String)ACTS[input]);
	_steep_phase = fposmod(_steep_phase + speed * dt / maxf((double)_stride[(String)ACTS[input]], 0.1), 1.0);
	_steep_on = true;
	_show(input, _steep_phase * len(a));
}

void TravCharacter::_ground(double dt, double speed) {
	double want = speed > 0.15 ? 1.0 : 0.0;
	_moving = move_toward(_moving, want, dt / FADE);
	tree->set("parameters/ground/blend_amount", _moving);
	bool low = (bool)body->get("crouched");
	if (_sub != "crouch") {
		_low_w = move_toward(_low_w, low ? 1.0 : 0.0, dt / CROUCH_FADE);
	}
	tree->set("parameters/stance/blend_amount", _low_w);
	tree->set("parameters/crouch_ground/blend_amount", _moving);
	tree->set("parameters/crouch_speed/scale", clampf(maxf(speed, 0.3) / ((double)_stride[String(CROUCH_WALK)] / (double)_length[String(CROUCH_WALK)]), SCALE_LEAST, SCALE_MOST));
	_narrow_w = move_toward(_narrow_w, ((int)(int64_t)body->get("narrow") > 0 && !low) ? 1.0 : 0.0, dt / NARROW_FADE);
	tree->set("parameters/narrow/blend_amount", _narrow_w);
	tree->set("parameters/beam_ground/blend_amount", _moving);
	tree->set("parameters/beam_speed/scale", clampf(maxf(speed, 0.2) / ((double)_stride[String(BEAM_WALK)] / (double)_length[String(BEAM_WALK)]), SCALE_LEAST, SCALE_MOST));
	int sq = !low ? (int)(int64_t)body->get("squeeze") : 0;
	_squeeze_w = move_toward(_squeeze_w, sq >= 2 ? 1.0 : 0.0, dt / NARROW_FADE);
	tree->set("parameters/squeeze/blend_amount", _squeeze_w);
	if (feet) {
		feet->set("gap_fit", (int)(int64_t)body->get("squeeze") == 2 ? _squeeze_w : 0.0);
		feet->set("ledge_fit", (int)(int64_t)body->get("squeeze") == 3 ? _squeeze_w : 0.0);
	}
	double side_len = (double)_length[String(SIDE_STEP)];
	if (speed > 0.05) {
		_side_t = fposmod(_side_t + dt * speed / ((double)_stride[String(SIDE_STEP)] / side_len), side_len);
	} else if (_side_t > 0.0) {
		_side_t = _side_t + dt * SIDE_REST;
		if (_side_t >= side_len) {
			_side_t = 0.0;
		}
	}
	tree->set("parameters/seek_side/seek_request", _side_t);
	tree->set("parameters/seek_side_m/seek_request", _side_t);
	double turned = (double)(int)(int64_t)body->get("squeeze_side");
	if (_squeeze_w <= 0.0 || sq >= 2) {
		tree->set("parameters/side_pick/blend_amount", turned > 0.0 ? 0.0 : 1.0);
	}
	_turn_deg = move_toward(_turn_deg, (sq == 1 && _mode == "ground") ? SHOULDER_TURN_DEG * turned : 0.0, SHOULDER_TURN_DEG * dt / FADE);
	_trunk->set("turn_deg", _turn_deg);
	_trunk->set("head_deg", -SIDE_HEAD_DEG * _squeeze_w * ((double)tree->get("parameters/side_pick/blend_amount") < 0.5 ? 1.0 : -1.0));
	Vector2 g = _gait_for(maxf(speed, 0.3));
	tree->set("parameters/gait/blend_position", D(g.x));
	_natural = D(g.y);
	double natural = (_measured > 0.0 && D(g.x) > 0.0) ? _measured : _natural;
	_scale = clampf(maxf(speed, 0.3) / maxf(natural, 0.05), SCALE_LEAST, SCALE_MOST);
	double own_time = D(g.x) <= 1.0 ? lerpf((double)_length[String(WALK)], (double)_length[String(JOG)], D(g.x)) : lerpf((double)_length[String(JOG)], (double)_length[String(RUN)], D(g.x) - 1.0);
	tree->set("parameters/gait_speed/scale", _scale / own_time);
}

Vector2 TravCharacter::_gait_for(double v) {
	double s_walk = (double)_stride[String(WALK)], s_jog = (double)_stride[String(JOG)], s_run = (double)_stride[String(RUN)];
	double l_walk = (double)_length[String(WALK)], l_jog = (double)_length[String(JOG)], l_run = (double)_length[String(RUN)];
	double lo = SWITCH - SWITCH_BAND;
	double hi = SWITCH + SWITCH_BAND;
	if (v <= lo) {
		return Vector2(0.0, (real_t)(WALK_STRIDE / l_walk));
	}
	if (v < hi) {
		double w = (v - lo) / (hi - lo);
		return Vector2((real_t)w, (real_t)(lerpf(s_walk, s_jog, w) / lerpf(l_walk, l_jog, w)));
	}
	double jog = s_jog / l_jog;
	if (v <= jog) {
		return Vector2(1.0, (real_t)jog);
	}
	double ds = s_run - s_jog;
	double dl = l_run - l_jog;
	double w2 = clampf((v * l_jog - s_jog) / maxf(ds - v * dl, 0.001), 0.0, 1.0);
	return Vector2((real_t)(1.0 + w2), (real_t)(lerpf(s_jog, s_run, w2) / lerpf(l_jog, l_run, w2)));
}

void TravCharacter::_measure(double dt) {
	double covered = D(tree->get_root_motion_position().length());
	if (_act == "ground" && _settled > FADE + 0.05 && _moving >= 1.0 && _scale > 0.0 && covered > 0.0001 && _low_w <= 0.0) {
		double seen = covered / (dt * _scale);
		_measured = absf(seen - _natural) < 0.2 * _natural ? seen : 0.0;
	} else {
		_measured = 0.0;
	}
}

void TravCharacter::_lean(double dt, bool on_ground) {
	Vector3 v = body->get("hvel");
	double speed = D(v.length());
	double raw = 0.0;
	double most = deg_to_rad(_lean_most(D(((Vector3)body->get("_wish")).length())));
	Vector3 chest = skel->get_bone_global_pose(_chest_i).origin;
	double own = std::atan2(D(chest.x), D(chest.y));
	if (on_ground && speed > 0.5) {
		_own_mean += (own - _own_mean) * (1.0 - std::exp(-dt / 1.0));
		Vector3 dir = div(v, speed);
		if (_last_dir != ZERO) {
			double rate = std::atan2(D(_last_dir.cross(dir).y), D(_last_dir.dot(dir))) / dt;
			raw = clampf(std::atan(speed * rate / 9.8), -most - LEAN_OVER, most + LEAN_OVER);
		}
		_last_dir = dir;
	} else {
		_last_dir = ZERO;
		_own_mean = own;
	}
	_lean_s += (raw - _lean_s) * (1.0 - std::exp(-dt / LEAN_TIME));
	double dev = own - _own_mean;
	lean = absf(_lean_s) > absf(dev) ? clampf(_lean_s, -most - dev, most - dev) : _lean_s;
	Vector3 pr = _pivot->get_rotation();
	pr.z = (real_t)lean;
	_pivot->set_rotation(pr);
}

double TravCharacter::_lean_most(double pace) {
	double walk = (double)body->get("WALK");
	if (pace <= walk) {
		return lerpf(LEAN_SLOW_DEG, LEAN_WALK_DEG, clampf((pace - 0.8 * walk) / (0.2 * walk), 0.0, 1.0));
	}
	if (pace <= SWITCH) {
		return lerpf(LEAN_WALK_DEG, LEAN_FAST_DEG, (pace - walk) / (SWITCH - walk));
	}
	return LEAN_RUN_DEG;
}
