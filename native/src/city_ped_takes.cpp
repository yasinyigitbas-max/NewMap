// THE MIXAMO TAKES (the Animator, 21 Nov; Yasin: "i want every action in the game animated. literally every action";
// "scrap existing ones and replace what we have with these, if our old pack had the act but this list doesnt have
// anything to replace it, keep the old one. make sure to use enter exits for every action possible. some of them have
// variety, use the varied ones in rotation"). The game's systems ask for their clips by the old names; each name here
// plays a Mixamo take instead (tools/people/make_mixamo.gd, library "mx"). A name with no row, or whose takes the
// figure lacks, plays the old clip. A loop keeps the same take for one person (their own walk, their own idle: by
// set_variant); a one-off plays the next take each time it starts (a punch, a wave, a hit).
#include "city_ped.h"

#include <godot_cpp/classes/animation.hpp>
#include <godot_cpp/classes/animation_player.hpp>

namespace godot {

namespace {
// cycle: a loop that goes on to its next take each time one has played through (a phone call's takes one after another,
// texting with one hand then two, an idle's moods); otherwise a loop keeps one take for one person (a walk)
struct Takes { const char *old; const char *take[8]; bool cycle = false; };
const Takes TAKES[] = {
	// standing
	{ "step/idle", { "mx/Idle_Transition", "mx/Looking_Around_idle", "mx/Idle_Transition", "mx/Neck_Stretching", "mx/Idle_Transition", "mx/Arm_Stretching" }, true },
	{ "ual/Idle_Loop", { "mx/Idle_Transition", "mx/Looking_Around_idle" }, true },
	{ "idle", { "mx/Idle_Transition" } },
	{ "ual/Idle_LookAround_Loop", { "mx/Looking_Around_idle", "mx/Looking" }, true },
	// walking, running
	{ "walk", { "mx/Walking" } }, { "walk_slow", { "mx/Walking" } }, { "walk_fast", { "mx/Walking" } },
	{ "step/walk", { "mx/Walking" } }, { "ual/Walk_Loop", { "mx/Walking" } },
	{ "ual/Walk_Formal_Loop", { "mx/Walk_With_Briefcase", "mx/Walking" } },
	{ "run", { "mx/Slow_Run", "mx/Running_4" } }, { "jog", { "mx/Slow_Run", "mx/Running_4" } },
	{ "step/jog", { "mx/Slow_Run", "mx/Running_4" } }, { "ual/Jog_Fwd_Loop", { "mx/Slow_Run", "mx/Running_4" } },
	{ "ual/Sprint_Loop", { "mx/Running_2", "mx/Running_3", "mx/Fast_Run" } },
	{ "step/rb_start", { "mx/Start_Walking" } }, { "step/start", { "mx/Start_Walking" } },
	{ "step/rb_stop_l", { "mx/Stop_Walking" } }, { "step/rb_stop_r", { "mx/Stop_Walking" } },
	{ "step/stop_l", { "mx/Stop_Walking" } }, { "step/stop_r", { "mx/Stop_Walking" } },
	{ "step/turn_l", { "mx/Left_Turn_90", "mx/Left_Turn" } }, { "step/turn_r", { "mx/Right_Turn_90", "mx/Right_Turn" } },
	// walking with something
	{ "ual/Walk_Text_Loop", { "mx/Texting_And_Walking_one_hand", "mx/Walking_While_Texting" } },
	{ "ual/Walk_Hurt_Loop", { "mx/Injured_Walking_arm", "mx/Injured_walking_leg" } },
	{ "ual/Walk_Carry_Loop", { "mx/Walking_With_Shopping_Bag", "mx/Walking_Carry" } },
	// crouching
	{ "ual/Crouch_Fwd_Loop", { "mx/Crouched_Walking", "mx/Sneaking_Forward" } },
	{ "ual/Crouch_Idle_Loop", { "mx/Crouching_Idle", "mx/Crouch_cover_idle" } },
	{ "ual/Crouch_Exit", { "mx/Crouch_To_Stand" } },
	// talking, the phone
	{ "ual/Idle_Talking_Loop", { "mx/Talking", "mx/Talking_2", "mx/Talking_3", "mx/Talking_4", "mx/Talking_5", "mx/Asking_Question", "mx/Telling_A_Secret" }, true },
	{ "ual/Idle_TalkingPhone_Loop", { "mx/Talking_On_Phone", "mx/Talking_On_A_Cell_Phone", "mx/Talking_on_phone_arguing", "mx/Talking_Phone_Pacing" }, true },
	{ "ual/Idle_Lantern_Loop", { "mx/Texting_While_Standing", "mx/Standing_Using_Touchscreen_Tablet" }, true },
	{ "ual/Yes", { "mx/Agreeing", "mx/Acknowledging" } },
	{ "ual/Idle_No_Loop", { "mx/No", "mx/Disappointed" } },
	{ "ual/Counter_Angry", { "mx/Angry_Gesture", "mx/Standing_Arguing", "mx/Threatening", "mx/Insult", "mx/Yelling" }, true },
	{ "ual/Celebration", { "mx/Cheering", "mx/Standing_Cheering", "mx/Victory", "mx/Fist_Pump", "mx/Excited" } },
	// work
	{ "ual/Counter_Idle_Loop", { "mx/Bartending" } },
	{ "ual/Fixing_Kneeling", { "mx/Working_On_Device_crouched" } },
	// sitting
	{ "ual/Sitting_Enter", { "mx/Stand_To_Sit" } },
	{ "ual/Sitting_Exit", { "mx/Sit_To_Stand", "mx/sit_Stand_Up" } },
	{ "ual/Sitting_Idle_Loop", { "mx/Sitting_Idle", "mx/Sitting_Idle_2" }, true },
	{ "ual/Sitting_Idle02_Loop", { "mx/Sitting_Idle_2", "mx/Seated_table_Idle" }, true },
	{ "ual/Sitting_Idle03_Loop", { "mx/Seated_table_Idle", "mx/Sitting_Idle" }, true },
	{ "ual/Sitting", { "mx/Sitting_Idle", "mx/Sitting_Idle_2" } },
	{ "ual/Sitting_Talking_Loop", { "mx/Sitting_talking" } },
	// fighting
	{ "ual/PunchKick_Enter", { "mx/Fight_Idle_To_Action_Idle" } },
	// the crowd (Yasin, 21 Nov: "some people carrying boxes or bags or brief cases in the crowd, i want a living city"):
	// carrying, walking and standing; waiting in many ways; cowering; the police; the medics
	{ "x/carry_bag", { "mx/Walking_With_Shopping_Bag" } }, { "x/carry_box", { "mx/Walking_Carry" } }, { "x/carry_case", { "mx/Walk_With_Briefcase" } },
	{ "x/carry_box_idle", { "mx/Box_Idle" } }, { "x/carry_case_idle", { "mx/Standing_W_Briefcase_Idle" } },
	{ "x/wait_bored", { "mx/Idle_Transition", "mx/Neck_Stretching", "mx/Looking_Around_idle", "mx/Arm_Stretching" }, true },
	{ "x/wait_smoke", { "mx/Smoking" } },
	{ "x/phone_angry", { "mx/Angry_talking_phone", "mx/Talking_on_phone_arguing", "mx/Talking_Phone_Pacing" }, true },   // (Yasin: "some of thm should speak angry on the phone")
	{ "x/seller", { "mx/Yelling_Out", "mx/Hands_Forward_Gesture", "mx/Counting", "mx/Talking_3", "mx/Pointing_Forward" }, true },   // (a street seller: calling out, offering, counting his money)
	{ "x/sit_chat", { "mx/Sitting_talking", "mx/Sitting_Idle", "mx/Sitting_talking", "mx/Sitting_Thumbs_Up" }, true },   // (two on a bench: talking)
	{ "x/wait_drunk", { "mx/Drunk_Idle_Variation" } },
	{ "x/cower", { "mx/Terrified" } },
	{ "x/car_out", { "mx/Exiting_Car" } }, { "x/car_in", { "mx/Entering_Car" } },   // (Yasin, 21 Nov: "make sure every npc use car get in get out too")
	// gestures that fit the line (Yasin, 21 Nov: "make sure the gesures are context relevant for the lines", "especially for the
	// player"): city_talk.cpp line_gesture reads the line; standing and seated
	{ "x/g_wave", { "mx/Waving", "mx/Waving_2", "mx/Standing_Greeting", "mx/Waving_4" } },
	{ "x/g_ask", { "mx/Asking_Question", "mx/Hands_Forward_Gesture", "mx/Arm_Gesture" } },
	{ "x/g_thanks", { "mx/Thankful", "mx/Quick_Formal_Bow" } },
	{ "x/g_point", { "mx/Pointing", "mx/Pointing_Forward", "mx/Pointing_back_thumb" } },
	{ "x/g_angry", { "mx/Angry_Gesture", "mx/Insult", "mx/Threatening", "mx/Yelling" } },
	{ "x/g_secret", { "mx/Telling_A_Secret" } },
	{ "x/g_unsure", { "mx/Disappointed_2", "mx/Sarcastic_Head_Nod" } },
	{ "x/g_sorry", { "mx/Disappointed" } },
	{ "x/g_cheer", { "mx/Cheering", "mx/Fist_Pump", "mx/Excited" } },
	{ "x/gs_talk", { "mx/Sitting_talking" } }, { "x/gs_yes", { "mx/Sitting_Thumbs_Up" } }, { "x/gs_no", { "mx/Sitting_Disapproval" } },
	{ "x/gs_point", { "mx/sitting_Pointing" } }, { "x/gs_angry", { "mx/Angry_Gesture_sitting", "mx/Sitting_Yell" } }, { "x/gs_ask", { "mx/Sitting_Disbelief" } },
	{ "x/gs_cheer", { "mx/Cheering_While_Sitting", "mx/Sitting_Clap" } },
	{ "x/kneel_caught", { "mx/Kneeling" } },
	{ "x/police_aim", { "mx/Pistol_Idle" } },
	{ "x/arrest", { "mx/Restrain" } },
	{ "x/cpr_give", { "mx/Administering_Cpr" } },
	{ "x/cpr_take", { "mx/Receiving_Cpr" } },
	{ "x/up_from_back", { "mx/Getting_Up", "mx/Situp_To_Idle" } },
	{ "x/mug_victim", { "mx/Hostage_Situation_Idle_Hostage" } },
	{ "ual/Surprise", { "mx/Looking", "mx/Terrified" } },
	{ "x/fight_stance", { "mx/Fighting_Idle", "mx/Fight_idle" }, true },   // (the stance held, its takes one after another)
	{ "x/fight_taunt", { "mx/Fistfight_Taunt", "mx/Taunt" } },
	{ "x/fight_step", { "mx/Fight_forwardstep" } },
	{ "x/fight_back", { "mx/Fight_walk_backwards", "mx/Fight_backstep" } },
	{ "x/fight_left", { "mx/Fight_sidestep_L" } }, { "x/fight_right", { "mx/Fight_sidestep_R" } },
	{ "ual/Punch_Jab", { "mx/Punching", "mx/Punching_2" } },
	{ "ual/Punch_Cross", { "mx/Hook", "mx/Elbow_Punching", "mx/Kicking_Out" } },
	{ "ual/Melee_Hook", { "mx/Hook" } },
	{ "ual/Kick", { "mx/Kicking_Out" } },
	{ "ual/Hit_Chest", { "mx/Hit_To_Body", "mx/Hit_Reaction" } },
	{ "ual/Hit_Stomach", { "mx/Hit_To_Body", "mx/Hit_Reaction" } },
	{ "ual/Hit_Head", { "mx/Head_Hit", "mx/Light_Hit_To_Head", "mx/Big_Hit_To_Head", "mx/Receive_Punch_To_The_Face" } },
};

// the takes of a name this figure has; 0 when none (the old clip plays)
int takes_for(const AnimationPlayer *anim, const StringName &p_clip, StringName *r_out, bool *r_cycle = nullptr) {
	static HashMap<StringName, const Takes *> index;
	if (index.is_empty()) for (const Takes &t : TAKES) index[StringName(t.old)] = &t;
	const HashMap<StringName, const Takes *>::ConstIterator it = index.find(p_clip);
	if (it == index.end()) return 0;
	if (r_cycle) *r_cycle = it->value->cycle;
	int n = 0;
	for (const char *c : it->value->take) {
		if (!c) break;
		const StringName s(c);
		if (anim->has_animation(s)) r_out[n++] = s;
	}
	return n;
}
} // namespace

StringName CityPed::take_of(const StringName &p_clip) const {
	if (p_clip == cur_req && cur_clip != StringName()) return cur_clip;   // (what plays for it now)
	if (!alias_on || !anim) return p_clip;
	StringName t[8];
	const int n = takes_for(anim, p_clip, t);
	if (n == 0) return p_clip;
	if (n == 1) return t[0];
	const HashMap<StringName, int>::ConstIterator u = var_uses.find(p_clip);
	bool cyc = false; takes_for(anim, p_clip, t, &cyc);
	const bool loop = !cyc && anim->get_animation(t[0]).is_valid() && anim->get_animation(t[0])->get_loop_mode() != Animation::LOOP_NONE;
	return t[(var_seed + (loop ? 0u : (uint32_t)(u == var_uses.end() ? 0 : u->value))) % (uint32_t)n];
}

StringName CityPed::take_next(const StringName &p_clip) {
	// a fresh pick (not the take that runs for it now): this person's take of a loop, the next take of a one-off
	const StringName keep_req = cur_req; cur_req = StringName();
	const StringName r = take_of(p_clip);
	cur_req = keep_req;
	var_uses[p_clip] = (var_uses.has(p_clip) ? var_uses[p_clip] : 0) + 1;
	return r;
}

bool CityPed::stride_any(const StringName &p_clip, double &r_left_down, int &r_strides) const {
	if (anim && anim->has_animation(p_clip)) {
		const Ref<Animation> a = anim->get_animation(p_clip);
		if (a.is_valid() && a->has_meta("left_down")) { r_left_down = (double)a->get_meta("left_down"); r_strides = 1; return true; }
	}
	return stride_of(p_clip, r_left_down, r_strides);
}

bool CityPed::stride_now(double &r_left_down, int &r_strides) const { return cur_clip != StringName() && stride_any(cur_clip, r_left_down, r_strides); }

double CityPed::ground_v(const StringName &p_clip, double p_def) const {
	const StringName t = take_of(p_clip);
	if (!anim || !anim->has_animation(t)) return p_def;
	const Ref<Animation> a = anim->get_animation(t);
	return (a.is_valid() && a->has_meta("ground_v") && (double)a->get_meta("ground_v") > 0.2) ? (double)a->get_meta("ground_v") : p_def;
}

bool CityPed::take_cycles(const StringName &p_clip) const {
	if (!alias_on || !anim) return false;
	StringName t[8]; bool cyc = false;
	return takes_for(anim, p_clip, t, &cyc) > 1 && cyc;
}

} // namespace godot
