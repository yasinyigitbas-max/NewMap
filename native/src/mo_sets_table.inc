// SET 2 ("athletic": one actor, Mixamo's newer Standing / Unarmed pack - its walk, run, sprint, turns, jumps, landings,
// crouch walks forward and to the sides, idles; its run also for the jog (Yasin's Slow Run was taken In Place: its hips surge 0.6-3.4 m/s a stride))
const Row SET1[] = {
	{ "pidle/base_idle", "ms/S2_Idle_Unarmed" }, { "pidle/base_loco", "ms/S2_Idle_Loop" }, { "pidle/base_standing", "ms/S2_Idle_Unarmed_b" },
	{ "pidle/Arm_Stretching", "ms/S2_Idle_Looking_1" }, { "pidle/Bored", "ms/S2_Idle_Looking_2" }, { "pidle/Looking", "ms/S2_Idle_Looking_Around" },
	{ "pidle/Neck_Stretching", "yl/AA_Idle_3" }, { "pidle/Looking_Around_idle", "yl/AA_Idle_5" },
	{ "pwalk/walk_mx3", "ms/S2_Walk_Forward" }, { "pwalk/walk_mx2", "ms/S2_Walk_Forward" },
	{ "prun/jog_a", "ms/S2_Run_Forward" }, { "prun/jog_c", "ms/S2_Run_Forward" }, { "prun/jog_d", "ms/S2_Run_Forward" },
	{ "prun/fast_b", "ms/S2_Sprint_Forward" }, { "prun/fast_c", "ms/S2_Sprint_Forward" }, { "prun/fast_d", "ms/S2_Sprint_Forward" },
	{ "pwalk/sturn_l", "ms/S2_Turn_Left_90" }, { "pwalk/sturn_l1", "ms/S2_Turn_Left_90" }, { "pwalk/sturn_l2", "ms/S2_Turn_Left_90" },
	{ "pwalk/sturn_r", "ms/S2_Turn_Right_90" }, { "pwalk/sturn_r1", "ms/S2_Turn_Right_90" }, { "pwalk/sturn_r2", "ms/S2_Turn_Right_90" },
	{ "ptrav/Jump_a", "ms/S2_Jump_Standing" }, { "ptrav/Running_Jump_a", "ms/S2_Leap_Moving" },
	{ "ptrav/Hard_Landing_b", "ms/S2_Landing_Fall_B" },   // (its "Fall A" soft landing starts from another fall pose: the feet met the ground 40 cm off - set 1's kept)
	// (its crouch idle and crouched walks: into low cover, the cover entry's planted foot slid 6-10 cm - set 1's crouch kept
	// until they are fitted to it)
	// (its crouched walks to the sides, along low cover: the feet slid 10.6 cm - the cover sneaks stay set 1's)
	{ nullptr, nullptr }
};
// SET 3 ("casual": the classic Mixamo male library - standard and hurried walks, quick / medium / intent runs, a two-cycle
// sprint, breathing / neutral / weight-shift idles and their fidgets, 45 and 90 degree turns, a jump in place, a forward
// running jump, a landing, a low crouch idle)
const Row SET2[] = {
	{ "pidle/base_idle", "ms/S3_Idle_Breathing" }, { "pidle/base_loco", "ms/S3_Idle_Neutral" }, { "pidle/base_standing", "ms/S3_Idle_Weight_Shift" },
	{ "pidle/Arm_Stretching", "ms/S3_Idle_Wiping_Sweat" }, { "pidle/Bored", "ms/S3_Idle_Standing_d" }, { "pidle/Looking", "ms/S3_Idle_Looking_Behind" },
	{ "pidle/Neck_Stretching", "ms/S3_Idle_Happy_1" }, { "pidle/Looking_Around_idle", "ms/S3_Idle_Looking_Around" },
	{ "pwalk/walk_mx3", "ms/S3_Walk_Standard" }, { "pwalk/walk_mx2", "ms/S3_Walk_Hurried" },
	{ "prun/jog_a", "ms/S3_Run_Happy" }, { "prun/jog_c", "ms/S3_Run_Medium" }, { "prun/jog_d", "ms/S3_Run_Quick_b" },
	{ "prun/fast_b", "ms/S3_Run_Intention" }, { "prun/fast_c", "ms/S3_Sprint_Two_Cycle" }, { "prun/fast_d", "ms/S3_Sprint_Two_Cycle" },
	{ "pwalk/sturn_l", "ms/S3_Turn_Left_45" }, { "pwalk/sturn_l1", "ms/S3_Turn_Left_b" }, { "pwalk/sturn_l2", "ms/S3_Turn_Left_180" },
	{ "pwalk/sturn_r", "ms/S3_Turn_Right_c" }, { "pwalk/sturn_r1", "ms/S3_Turn_Right_b" }, { "pwalk/sturn_r2", "ms/S3_Turn_Right_180" },   // (not "Quick 90": 2.8 s, an idle around it)
	{ "ptrav/Jump_a", "ms/S3_Jump_In_Place" }, { "ptrav/Running_Jump_a", "ms/S3_Leap_Forward_Moving" },
	{ "ptrav/Hard_Landing_b", "yl/Hard_Landing" },
	{ "ptrav/Crouching_Idle", "ms/S3_Crouch_Idle_Low" },
	{ nullptr, nullptr }
};
