// Mixamo batch download for player_v4. Made 25 Nov 2026.
// It asks Mixamo for each clip in the list below, fitted to the character that is active on the page,
// and saves it under the Drive file name. It runs one clip after another and can be re-run: it skips what is done.
//
// NOT TESTED: it was written without a Mixamo login. It uses the same calls Mixamo's own page makes
// (the open-source gnuton/mixamo_anims_downloader script uses them too); Adobe can change them at any time.
//
// HOW TO RUN
//   1. Open mixamo.com in Chrome, sign in, and make player_v4 the active character (he is the one shown on the right).
//   2. Chrome: Settings > Privacy and security > Site settings > Additional permissions > Automatic downloads:
//      allow www.mixamo.com. Also turn OFF "Ask where to save each file before downloading".
//   3. Press F12, open the Console tab, paste this whole file, press Enter.
//   4. Leave the tab open. Progress is printed in the console. When it ends it saves "mixamo_download_report.csv".
//   To do only some batches, change BATCHES below (1 = walk/run/crouch/stairs, 2 = traversal, 3 = cover/doors/cars, 4 = the rest).
//   To start again from nothing, run:  localStorage.removeItem('mxdl_done')
//   When several clips share a name it picks by length if Mixamo reports one, never a clip with a prop (axe, rifle ...),
//   and skips the clip (listed in the report) when it still cannot tell.
(async () => {
  const BATCHES = [1, 2, 3, 4];
  const PAUSE_MS = 1500;          // wait between clips
  const MAX_SAME_NAME = 3;        // when clips cannot be told apart: download them only if there are this many or fewer, else skip
  const CLIPS = [
    {"n": 1, "b": 1, "q": "Standing Idle", "d": "", "len": 6.0, "save": "Standing Idle", "nd": 1},
    {"n": 2, "b": 1, "q": "Idle", "d": "Standing Idle", "len": 8.33, "save": "Idle"},
    {"n": 3, "b": 1, "q": "Walking", "d": "Male Standard Walk", "len": 1.23, "save": "Walking (4)"},
    {"n": 4, "b": 1, "q": "Walking", "d": "Walking With A Swagger", "len": 1.03, "save": "Walking"},
    {"n": 5, "b": 1, "q": "Slow Run", "d": "Slow Run Forward", "len": 0.73, "save": "Slow Run"},
    {"n": 6, "b": 1, "q": "Running", "d": "Male Weighted Run", "len": 0.83, "save": "Running (3)"},
    {"n": 7, "b": 1, "q": "Running", "d": "Running Leaning Back Or Forth", "len": 0.63, "save": "Running"},
    {"n": 8, "b": 1, "q": "Sprint", "d": "Standard Sprint", "len": 0.53, "save": "Sprint"},
    {"n": 9, "b": 1, "q": "Walking Backwards", "d": "", "len": 1.2, "save": "Walking Backwards", "nd": 1},
    {"n": 10, "b": 1, "q": "Walking Left Turn", "d": "Turning Left While Walking", "len": 1.2, "save": "Walking Left Turn"},
    {"n": 11, "b": 1, "q": "Running Left Turn", "d": "", "len": 0.77, "save": "Running Left Turn (2)"},
    {"n": 12, "b": 1, "q": "Running Right Turn", "d": "Turning Right While Running", "len": 0.77, "save": "Running Right Turn"},
    {"n": 13, "b": 1, "q": "Left Strafe Walking", "d": "Strafe Walking To The Left", "len": 1.03, "save": "left strafe walking"},
    {"n": 14, "b": 1, "q": "Right Strafe Walking", "d": "Strafe Walking To The Right", "len": 1.03, "save": "right strafe walking"},
    {"n": 15, "b": 1, "q": "Left Strafe", "d": "Running Strafe To The Left", "len": 0.67, "save": "left strafe"},
    {"n": 16, "b": 1, "q": "Right Strafe", "d": "Running Strafe To The Right", "len": 0.67, "save": "right strafe"},
    {"n": 17, "b": 1, "q": "Female Start Walking", "d": "", "len": 1.87, "save": "Female Start Walking", "nd": 1},
    {"n": 18, "b": 1, "q": "Female Stop Walking", "d": "", "len": 1.53, "save": "Female Stop Walking", "nd": 1},
    {"n": 19, "b": 1, "q": "Start Walking", "d": "Walking From Standing", "len": 2.93, "save": "Start Walking"},
    {"n": 20, "b": 1, "q": "Stop Walking", "d": "Walking To Standing Idle", "len": 3.0, "save": "Stop Walking"},
    {"n": 21, "b": 1, "q": "Idle To Sprint", "d": "Start Sprint From Action Idle", "len": 0.8, "save": "Idle To Sprint"},
    {"n": 22, "b": 1, "q": "Run To Stop", "d": "Fast Stop From Full Run", "len": 0.9, "save": "Run To Stop"},
    {"n": 23, "b": 1, "q": "Left Turn 90", "d": "Standing Left Turn", "len": 0.93, "save": "Left Turn 90"},
    {"n": 24, "b": 1, "q": "Right Turn 90", "d": "Standing Right Turn", "len": 0.93, "save": "Right Turn 90"},
    {"n": 25, "b": 1, "q": "Walking Turn 180", "d": "Turning 180 Degrees While Walking", "len": 1.0, "save": "Walking Turn 180"},
    {"n": 26, "b": 1, "q": "Running Turn 180", "d": "Turning 180 Degrees While Running", "len": 0.67, "save": "Running Turn 180"},
    {"n": 27, "b": 1, "q": "Crouching Idle", "d": "Low Crouching Idle", "len": 2.5, "save": "Crouching Idle"},
    {"n": 28, "b": 1, "q": "Crouched Walking", "d": "Crouched Walk", "len": 1.03, "save": "Crouched Walking"},
    {"n": 29, "b": 1, "q": "Standing To Crouched", "d": "Standing Adventure Idle To Crouched", "len": 0.63, "save": "Standing To Crouched"},
    {"n": 30, "b": 1, "q": "Crouched To Standing", "d": "Crouch To Stand Transition", "len": 0.63, "save": "Crouched To Standing"},
    {"n": 31, "b": 1, "q": "Sneaking Forward", "d": "Sneaking Forward Quickly", "len": 1.67, "save": "Sneaking Forward"},
    {"n": 32, "b": 1, "q": "Ascending Stairs", "d": "Walking Up A Set Of Stairs", "len": 1.37, "save": "Ascending Stairs"},
    {"n": 33, "b": 1, "q": "Descending Stairs", "d": "Walking Down A Set Of Stairs", "len": 0.93, "save": "Descending Stairs"},
    {"n": 34, "b": 1, "q": "Running Up Stairs", "d": "", "len": 0.6, "save": "Running Up Stairs", "nd": 1},
    {"n": 35, "b": 1, "q": "Descending Stairs", "d": "Running Down A Set Of Stairs", "len": 0.4, "save": "Run Down Stairs"},
    {"n": 36, "b": 2, "q": "Falling Idle", "d": "Mid-Air Falling Idle", "len": 0.7, "save": "Falling Idle"},
    {"n": 37, "b": 2, "q": "Falling To Landing", "d": "Landing From Falling Idle", "len": 1.07, "save": "Falling To Landing"},
    {"n": 38, "b": 2, "q": "Hard Landing", "d": "Mid-Air Falling To A Hard Landing", "len": 2.5, "save": "Hard Landing"},
    {"n": 39, "b": 2, "q": "Falling To Roll", "d": "Mid-Air Falling Into A Roll Game Blend", "len": 1.8, "save": "falling to roll"},
    {"n": 40, "b": 2, "q": "Jumping Down", "d": "Jumping Down Over A Railing", "len": 3.07, "save": "Jumping Down (2)"},
    {"n": 41, "b": 2, "q": "Jump", "d": "Jumping In Place", "len": 2.17, "save": "Jump"},
    {"n": 42, "b": 2, "q": "Running Jump", "d": "Jumping From A Sprint", "len": 0.9, "save": "Running Jump"},
    {"n": 43, "b": 2, "q": "Jumping", "d": "Male Stepping Onto Platform", "len": 1.37, "save": "Step Onto Platform"},
    {"n": 44, "b": 2, "q": "Jumping", "d": "Male Jumping Onto Platform", "len": 1.23, "save": "Jumping (2)"},
    {"n": 45, "b": 2, "q": "Running Jump", "d": "Fast Run To Jump Up Onto Higher Level", "len": 2.17, "save": "Running Jump Climb"},
    {"n": 46, "b": 2, "q": "Sprint To Wall Climb", "d": "Sprint To Wall Climb To Crouch Idle", "len": 1.8, "save": "Sprint To Wall Climb"},
    {"n": 47, "b": 2, "q": "Jumping", "d": "Male Jumping Over An Obstacle With 1 Hand Planted", "len": 1.17, "save": "Vault 1 Hand"},
    {"n": 48, "b": 2, "q": "Jumping", "d": "Male Jumping Over An Obstacle With 2 Hands Planted", "len": 1.2, "save": "Vault 2 Hands"},
    {"n": 49, "b": 2, "q": "Idle To Braced Hang", "d": "Jump To A Braced Hang From Standing Idle", "len": 1.27, "save": "Jump To Braced Hang"},
    {"n": 50, "b": 2, "q": "Braced Hang To Crouch", "d": "Climb Wall From Braced Hang To Crouch", "len": 1.13, "save": "Braced Hang To Crouch"},
    {"n": 51, "b": 2, "q": "Braced Hang Shimmy", "d": "Left Braced Hang Shimmy", "len": 1.17, "save": "Braced Hang Shimmy Left"},
    {"n": 52, "b": 2, "q": "Braced Hang Shimmy", "d": "Right Braced Hang Shimmy", "len": 1.17, "save": "Braced Hang Shimmy Right"},
    {"n": 53, "b": 2, "q": "Braced Hang Drop", "d": "Braced Hang Drop To Standing", "len": 1.67, "save": "Braced Hang Drop"},
    {"n": 54, "b": 2, "q": "Braced To Free Hang", "d": "Braced Idle To Free Hang Idle", "len": 0.93, "save": "Braced To Freehang"},
    {"n": 55, "b": 2, "q": "Free Hang To Braced", "d": "Free Hang Idle To Braced Idle", "len": 1.13, "save": "Freehang To Braced"},
    {"n": 56, "b": 2, "q": "Stand To Freehang", "d": "Standing Jump To Freehang", "len": 1.7, "save": "Stand To Freehang"},
    {"n": 57, "b": 2, "q": "Hanging Idle", "d": "Hanging By Hands Gently Swaying", "len": 2.33, "save": "Hanging Idle"},
    {"n": 58, "b": 2, "q": "Left Shimmy", "d": "Free Hanging Shimmy Left", "len": 1.37, "save": "Freehang Shimmy Left"},
    {"n": 59, "b": 2, "q": "Right Shimmy", "d": "Free Hanging Shimmy Right", "len": 1.4, "save": "Freehang Shimmy Right"},
    {"n": 60, "b": 2, "q": "Freehang Climb", "d": "Freehang Climb To Standing", "len": 3.87, "save": "Freehang Climb"},
    {"n": 61, "b": 2, "q": "Climbing", "d": "Pulling Up To A Ledge", "len": 3.83, "save": "Climbing single"},
    {"n": 62, "b": 2, "q": "Drop To Freehang", "d": "Standing Drop To Freehang", "len": 2.4, "save": "Drop To Freehang"},
    {"n": 63, "b": 2, "q": "Freehang Drop", "d": "Freehang Drop To Standing", "len": 1.33, "save": "Freehang Drop"},
    {"n": 64, "b": 2, "q": "Climbing Down", "d": "Climb Through Fence And Jump Down", "len": 3.13, "save": "Climbing Down"},
    {"n": 65, "b": 2, "q": "Climbing Down", "d": "Climbing Down To Standing", "len": 3.43, "save": "Climbing Down (2)"},
    {"n": 66, "b": 2, "q": "Getting Up", "d": "Getting Up From Being Knocked Down On The Ground", "len": 2.7, "save": "Getting Up"},
    {"n": 67, "b": 2, "q": "Standing Up", "d": "Standing Up From A Soccer Fall", "len": 1.67, "save": "Standing Up"},
    {"n": 68, "b": 2, "q": "Push Up To Idle", "d": "Basic Push Up Transition To Fitness Idle", "len": 3.1, "save": "Push Up To Idle"},
    {"n": 69, "b": 3, "q": "Cover Idle", "d": "Standing Cover Against Object", "len": 2.27, "save": "Cover Idle"},
    {"n": 70, "b": 3, "q": "Cover Idle", "d": "Crouched For Cover Against Object", "len": 2.57, "save": "Crouch cover idle"},
    {"n": 71, "b": 3, "q": "Stand To Cover", "d": "Standing Ready To Standing Cover", "len": 1.13, "save": "stand to cover"},
    {"n": 72, "b": 3, "q": "Stand To Cover", "d": "Standing To A Crouched Cover Position", "len": 1.27, "save": "stand to cover (2)"},
    {"n": 73, "b": 3, "q": "Cover To Stand", "d": "Crouch Cover To Standing Ready", "len": 1.5, "save": "cover to stand"},
    {"n": 74, "b": 3, "q": "Cover To Stand", "d": "Standing Cover To Standing Ready", "len": 1.4, "save": "cover to stand (2)"},
    {"n": 75, "b": 3, "q": "Left Cover Sneak", "d": "Left Standing Sneak Behind Cover", "len": 1.13, "save": "Left Cover Sneak (1)"},
    {"n": 76, "b": 3, "q": "Right Cover Sneak", "d": "Right Standing Sneak Behind Cover", "len": 1.13, "save": "Right Cover Sneak"},
    {"n": 77, "b": 3, "q": "Crouch Cover To Cover", "d": "", "len": 1.57, "save": "Crouch Cover To Cover", "nd": 1},
    {"n": 78, "b": 3, "q": "Standing Cover Turn", "d": "Changing Direction In Stand Cover", "len": 1.0, "save": "Standing Cover Turn"},
    {"n": 79, "b": 3, "q": "Crouch Cover Turn", "d": "Changing Direction In Crouch Cover", "len": 0.93, "save": "Crouch Cover Turn"},
    {"n": 80, "b": 3, "q": "Crouch Look Around Corner", "d": "Crouch Looking Around Corner", "len": 3.0, "save": "Crouch Look Around Corner"},
    {"n": 81, "b": 3, "q": "Open Door Outwards", "d": "Open Door Outwards While Walking", "len": 4.1, "save": "Open Door Outwards"},
    {"n": 82, "b": 3, "q": "Opening Door Inwards", "d": "Male Walking And Opening A Door Inwards", "len": 6.37, "save": "Opening Door Inwards"},
    {"n": 83, "b": 3, "q": "Entering Car", "d": "Entering Into The Driverside Of A Car", "len": 5.47, "save": "Entering Car"},
    {"n": 84, "b": 3, "q": "Exiting Car", "d": "Exiting Out Of The Driverside Of A Car", "len": 5.8, "save": "Exiting Car"},
    {"n": 85, "b": 3, "q": "Start Climbing Ladder", "d": "Standing To Climb Ladder Quickly", "len": 2.03, "save": "Start Climbing Ladder"},
    {"n": 86, "b": 4, "q": "180 Turn W_ Briefcase", "d": "", "len": 2.27, "save": "180 Turn W_ Briefcase"},
    {"n": 87, "b": 4, "q": "180 Turn W_ Briefcase", "d": "", "len": 2.23, "save": "180 Turn W_ Briefcase (1)"},
    {"n": 88, "b": 4, "q": "Acknowledging", "d": "Acknowledging Gesture", "len": 1.93, "save": "Acknowledging"},
    {"n": 89, "b": 4, "q": "Administering Cpr", "d": "Administering Cpr To A Victim On The Ground", "len": 8.63, "save": "Administering Cpr"},
    {"n": 90, "b": 4, "q": "Agreeing", "d": "Step Back Cautiously Agreeing", "len": 4.7, "save": "Agreeing"},
    {"n": 91, "b": 4, "q": "Aim Pistol Sitting", "d": "", "len": 5.43, "save": "Aim Pistol sitting"},
    {"n": 92, "b": 4, "q": "Aiming Gun", "d": "Picking Up Gun From Ground To Aiming", "len": 2.4, "save": "Aiming Gun"},
    {"n": 93, "b": 4, "q": "Angry", "d": "Standing Angrily", "len": 19.17, "save": "Angry"},
    {"n": 94, "b": 4, "q": "Angry Gesture", "d": "Angrily Pumping Fists Forward", "len": 3.27, "save": "Angry Gesture"},
    {"n": 95, "b": 4, "q": "Angry Gesture Sitting", "d": "", "len": 5.83, "save": "Angry Gesture sitting"},
    {"n": 96, "b": 4, "q": "Angry Talking Phone", "d": "", "len": 4.8, "save": "Angry talking phone"},
    {"n": 97, "b": 4, "q": "Arm Gesture", "d": "Gesturing With Arm To The Side", "len": 3.4, "save": "Arm Gesture"},
    {"n": 98, "b": 4, "q": "Arm Stretching", "d": "Stretching Arms By Pushing The Elbows", "len": 8.87, "save": "Arm Stretching"},
    {"n": 99, "b": 4, "q": "Asking Question", "d": "Seated Idle With Hands On A Table", "len": 5.83, "save": "Asking Question"},
    {"n": 100, "b": 4, "q": "Bartending", "d": "Pouring And Serving Drinks", "len": 13.57, "save": "Bartending"},
    {"n": 101, "b": 4, "q": "Being Carried Out Down", "d": "", "len": 10.17, "save": "Being Carried out down"},
    {"n": 102, "b": 4, "q": "Being Carried Pick Up", "d": "", "len": 5.23, "save": "Being Carried pick up"},
    {"n": 103, "b": 4, "q": "Being Carried Walking", "d": "", "len": 3.63, "save": "Being Carried walking"},
    {"n": 104, "b": 4, "q": "Being Strangled", "d": "Getting Snuck Up On And Strangled", "len": 17.6, "save": "Being Strangled"},
    {"n": 105, "b": 4, "q": "Big Hit To Head", "d": "Receiving A Big Hit From A Straight Punch", "len": 1.3, "save": "Big Hit To Head"},
    {"n": 106, "b": 4, "q": "Bored", "d": "Standing Around Bored Idle", "len": 10.67, "save": "Bored"},
    {"n": 107, "b": 4, "q": "Box Idle", "d": "Carrying A Box", "len": 6.3, "save": "Box Idle"},
    {"n": 108, "b": 4, "q": "Box Turn", "d": "Turning Right Carrying A Box", "len": 1.17, "save": "Box Turn"},
    {"n": 109, "b": 4, "q": "Box Turn", "d": "Turning Left Carrying A Box", "len": 1.53, "save": "Box Turn (1)"},
    {"n": 110, "b": 4, "q": "Box Walk Arc", "d": "Walking In A Left Arc Carrying A Box", "len": 1.23, "save": "Box Walk Arc"},
    {"n": 111, "b": 4, "q": "Cards", "d": "Dealing Cards", "len": 9.1, "save": "Cards"},
    {"n": 112, "b": 4, "q": "Carrying Turn", "d": "Carrying Someone To Turn Left", "len": 3.87, "save": "Carrying Turn"},
    {"n": 113, "b": 4, "q": "Cheering", "d": "", "len": 2.9, "save": "Cheering"},
    {"n": 114, "b": 4, "q": "Cheering While Sitting", "d": "Cheering While Sitting And Talking To Neighbor", "len": 4.33, "save": "Cheering While Sitting"},
    {"n": 115, "b": 4, "q": "Climbing Down Ladder", "d": "", "len": 2.0, "save": "Climbing Down ladder"},
    {"n": 116, "b": 4, "q": "Climbing Ladder Fast", "d": "", "len": 0.77, "save": "Climbing Ladder fast"},
    {"n": 117, "b": 4, "q": "Climbing To Top Ladder", "d": "", "len": 4.0, "save": "Climbing To Top ladder"},
    {"n": 118, "b": 4, "q": "Climbing", "d": "Run To Start Climbing", "len": 3.83, "save": "Climbing double"},
    {"n": 119, "b": 4, "q": "Climbing Ladder Slow", "d": "", "len": 2.97, "save": "Climbing ladder slow"},
    {"n": 120, "b": 4, "q": "Closing A Lid", "d": "Closing The Lid On A Chest Or Box", "len": 10.97, "save": "Closing A Lid"},
    {"n": 121, "b": 4, "q": "Cocky Head Turn", "d": "Turning Head To The Side In A Cocky Manner", "len": 2.53, "save": "Cocky Head Turn"},
    {"n": 122, "b": 4, "q": "Combo Punch", "d": "Eight Punch Combo", "len": 2.97, "save": "Combo Punch"},
    {"n": 123, "b": 4, "q": "Counting", "d": "Counting To Five On One Hand", "len": 6.63, "save": "Counting"},
    {"n": 124, "b": 4, "q": "Crouch To Stand", "d": "Male Crouch To Stand", "len": 2.57, "save": "Crouch To Stand"},
    {"n": 125, "b": 4, "q": "Crouch To Stand", "d": "Crouch To Stand With Pistol", "len": 3.33, "save": "Crouch To Stand (1)"},
    {"n": 126, "b": 4, "q": "Crouch Turn To Stand", "d": "Crouch Turn 180 To Stand", "len": 0.83, "save": "Crouch Turn To Stand"},
    {"n": 127, "b": 4, "q": "Crouched Sneaking Right", "d": "Crouched Cover Sneaking Right", "len": 1.1, "save": "Crouched Sneaking Right"},
    {"n": 128, "b": 4, "q": "Crouched To Sprinting", "d": "Crouch To Sprinting", "len": 0.5, "save": "Crouched To Sprinting"},
    {"n": 129, "b": 4, "q": "Dancing", "d": "", "len": 8.1, "save": "Dancing"},
    {"n": 130, "b": 4, "q": "Dancing", "d": "", "len": 16.27, "save": "Dancing (1)"},
    {"n": 131, "b": 4, "q": "Dice Idle", "d": "Tapping Fingers From A Sitting Position", "len": 4.8, "save": "Dice Idle"},
    {"n": 132, "b": 4, "q": "Disappointed", "d": "Disappointed \"Awe-Shucks\"", "len": 4.2, "save": "Disappointed"},
    {"n": 133, "b": 4, "q": "Disappointed", "d": "Disappointed \"Awe-Shucks\"", "len": 7.3, "save": "Disappointed (2)"},
    {"n": 134, "b": 4, "q": "Drinking Fountain", "d": "Stopping To Drink From Drinking Fountain", "len": 10.23, "save": "Drinking Fountain"},
    {"n": 135, "b": 4, "q": "Drunk Idle Variation", "d": "Drunk Idle Variation Stumble", "len": 5.4, "save": "Drunk Idle Variation"},
    {"n": 136, "b": 4, "q": "Drunk Turn", "d": "Drunken Turn Left In Place", "len": 1.57, "save": "Drunk Turn"},
    {"n": 137, "b": 4, "q": "Drunk Walking Turn", "d": "Turning Left While Walking Left", "len": 2.57, "save": "Drunk Walking Turn"},
    {"n": 138, "b": 4, "q": "Dying", "d": "", "len": 5.77, "save": "Dying"},
    {"n": 139, "b": 4, "q": "Elbow Punching", "d": "Male Elbow Punch", "len": 1.67, "save": "Elbow Punching"},
    {"n": 140, "b": 4, "q": "Excited", "d": "Super Excited", "len": 6.57, "save": "Excited"},
    {"n": 141, "b": 4, "q": "Fall Flat", "d": "Falling Flat On Face From A Hit To The Back While Running", "len": 2.53, "save": "Fall Flat"},
    {"n": 142, "b": 4, "q": "Fallen Idle", "d": "Hurt Ground Idle From A Soccer Fall", "len": 1.5, "save": "Fallen Idle"},
    {"n": 143, "b": 4, "q": "Falling", "d": "Falling In The Air Idle", "len": 4.5, "save": "Falling"},
    {"n": 144, "b": 4, "q": "Falling Down On Ass", "d": "", "len": 2.27, "save": "Falling Down on ass"},
    {"n": 145, "b": 4, "q": "Falling Flat Impact", "d": "Falling Flat On Face", "len": 1.57, "save": "Falling Flat Impact"},
    {"n": 146, "b": 4, "q": "Falling From Losing Balance", "d": "Losing Balance And Falling Off An Edge", "len": 6.67, "save": "Falling From Losing Balance"},
    {"n": 147, "b": 4, "q": "Falling Into Pool", "d": "Losing Balance And Falling Sideways Into A Pool", "len": 3.0, "save": "Falling Into Pool"},
    {"n": 148, "b": 4, "q": "Falling Into Pool", "d": "Losing Balance And Falling Forward Into A Pool", "len": 2.27, "save": "Falling Into Pool (1)"},
    {"n": 149, "b": 4, "q": "Fast Run", "d": "Running Fast", "len": 0.53, "save": "Fast Run"},
    {"n": 150, "b": 4, "q": "Female Peek And Aim", "d": "Female Turnaround Gun Aim", "len": 2.6, "save": "Female Peek And Aim"},
    {"n": 151, "b": 4, "q": "Fight Idle", "d": "Male Fight Idle Empty Stance", "len": 2.37, "save": "Fight Idle (1)"},
    {"n": 152, "b": 4, "q": "Fight Idle To Action Idle", "d": "Transition From Fight Idle To Action Idle", "len": 0.83, "save": "Fight Idle To Action Idle"},
    {"n": 153, "b": 4, "q": "Fight Backstep", "d": "", "len": 0.87, "save": "Fight backstep"},
    {"n": 154, "b": 4, "q": "Fight Forwardstep", "d": "", "len": 1.0, "save": "Fight forwardstep"},
    {"n": 155, "b": 4, "q": "Fight Idle", "d": "", "len": 3.63, "save": "Fight idle"},
    {"n": 156, "b": 4, "q": "Fight Sidestep (L)", "d": "", "len": 1.03, "save": "Fight sidestep (L)"},
    {"n": 157, "b": 4, "q": "Fight Sidestep (R)", "d": "", "len": 1.03, "save": "Fight sidestep (R)"},
    {"n": 158, "b": 4, "q": "Fighting Idle", "d": "Male Fight Idle Boxing Stance", "len": 3.3, "save": "Fighting Idle"},
    {"n": 159, "b": 4, "q": "Finding", "d": "Finding Something On The Ground", "len": 13.77, "save": "Finding"},
    {"n": 160, "b": 4, "q": "Fist Pump", "d": "", "len": 3.8, "save": "Fist Pump"},
    {"n": 161, "b": 4, "q": "Fistfight Taunt", "d": "", "len": 3.23, "save": "Fistfight Taunt"},
    {"n": 162, "b": 4, "q": "Hand Raising", "d": "Raising A Hand", "len": 4.07, "save": "Hand Raising"},
    {"n": 163, "b": 4, "q": "Hands Forward Gesture", "d": "Two Handed Forward Gesture", "len": 3.1, "save": "Hands Forward Gesture"},
    {"n": 164, "b": 4, "q": "Happy Right Turn", "d": "Turning Right", "len": 0.73, "save": "Happy Right Turn"},
    {"n": 165, "b": 4, "q": "Having A Meeting, Female", "d": "Having A Meeting W/ Another At A Desk", "len": 46.67, "save": "Having A Meeting, Female"},
    {"n": 166, "b": 4, "q": "Having A Meeting, Male", "d": "Having A Meeting W/ Another At A Desk", "len": 46.67, "save": "Having A Meeting, Male"},
    {"n": 167, "b": 4, "q": "Head Hit", "d": "", "len": 1.07, "save": "Head Hit"},
    {"n": 168, "b": 4, "q": "Hit By Car", "d": "Getting Hit By A Car While Tired", "len": 4.83, "save": "Hit By Car"},
    {"n": 169, "b": 4, "q": "Hit On The Back", "d": "Getting Hit On The Back With An Object While Running", "len": 2.5, "save": "Hit On The Back"},
    {"n": 170, "b": 4, "q": "Hit Reaction", "d": "Receive Punch To The Body", "len": 1.6, "save": "Hit Reaction"},
    {"n": 171, "b": 4, "q": "Hit To Body", "d": "", "len": 1.33, "save": "Hit To Body"},
    {"n": 172, "b": 4, "q": "Hook", "d": "Short Hook Punch To The Head", "len": 1.3, "save": "Hook"},
    {"n": 173, "b": 4, "q": "Hostage Situation Idle - Hostage", "d": "Armed Villain Holding A Hostage From Behind", "len": 5.0, "save": "Hostage Situation Idle - Hostage"},
    {"n": 174, "b": 4, "q": "Hostage Situation Idle - Villain", "d": "Armed Villain Holding A Hostage From Behind", "len": 5.0, "save": "Hostage Situation Idle - Villain"},
    {"n": 175, "b": 4, "q": "Idle", "d": "Standing Short Idle", "len": 1.97, "save": "Idle (1)"},
    {"n": 176, "b": 4, "q": "Idle To Push Up", "d": "Fitness Idle Transition To Basic Push Up", "len": 2.6, "save": "Idle To Push Up"},
    {"n": 177, "b": 4, "q": "Idle Transition", "d": "Transition From Fitness Idle To Idle", "len": 1.87, "save": "Idle Transition"},
    {"n": 178, "b": 4, "q": "Injured Run Jump", "d": "Injured Jumping While Running", "len": 0.73, "save": "Injured Run Jump"},
    {"n": 179, "b": 4, "q": "Injured Standing Jump", "d": "Injured Jumping While Standing", "len": 1.9, "save": "Injured Standing Jump"},
    {"n": 180, "b": 4, "q": "Injured Turn Left", "d": "Injured Standing Turning Left", "len": 0.9, "save": "Injured Turn Left"},
    {"n": 181, "b": 4, "q": "Injured Turn Right", "d": "Injured Standing Turning Right", "len": 0.7, "save": "Injured Turn Right"},
    {"n": 182, "b": 4, "q": "Injured Walking Arm", "d": "", "len": 1.0, "save": "Injured Walking arm"},
    {"n": 183, "b": 4, "q": "Injured Walking Leg", "d": "", "len": 1.63, "save": "Injured walking leg"},
    {"n": 184, "b": 4, "q": "Insult", "d": "Insulting With Rude Gesture", "len": 2.67, "save": "Insult"},
    {"n": 185, "b": 4, "q": "Jab To Elbow Punch", "d": "Jab To Elbow Combo", "len": 3.27, "save": "Jab To Elbow Punch"},
    {"n": 186, "b": 4, "q": "Jog In Circle", "d": "Jog In A Circle", "len": 5.93, "save": "Jog In Circle"},
    {"n": 187, "b": 4, "q": "Jogging Stumble", "d": "Brief Stumble While Jogging", "len": 1.17, "save": "Jogging Stumble"},
    {"n": 188, "b": 4, "q": "Jogging With Box", "d": "Jogging While Carrying A Box", "len": 0.77, "save": "Jogging With Box"},
    {"n": 189, "b": 4, "q": "Jump", "d": "Forward Running Jump", "len": 1.0, "save": "Jump (1)"},
    {"n": 190, "b": 4, "q": "Jump To Hang", "d": "Jump Grab To Free Hanging", "len": 2.0, "save": "Jump To Hang"},
    {"n": 191, "b": 4, "q": "Jumping", "d": "Male Jumping Down From 4 Feet", "len": 2.63, "save": "Jumping"},
    {"n": 192, "b": 4, "q": "Jumping", "d": "Jumping From Action Idle", "len": 1.9, "save": "Jumping (1)"},
    {"n": 193, "b": 4, "q": "Jumping Down", "d": "Jumping Down From Falling Idle Game Blend", "len": 0.37, "save": "Jumping Down"},
    {"n": 194, "b": 4, "q": "Jumping Down", "d": "Male Frog Style Jump Down", "len": 2.3, "save": "Jumping Down (1)"},
    {"n": 195, "b": 4, "q": "Jumping Over Into Combat", "d": "Jumping Over Obstacle Getting Ready To Fight", "len": 4.17, "save": "Jumping Over Into Combat"},
    {"n": 196, "b": 4, "q": "Jumping Rope", "d": "", "len": 2.57, "save": "Jumping Rope"},
    {"n": 197, "b": 4, "q": "Kick To The Groin", "d": "Receive A Kick To The Groin To Falling Down", "len": 4.13, "save": "Kick To The Groin"},
    {"n": 198, "b": 4, "q": "Kicking Out", "d": "Kicking While Sitting On Ground", "len": 1.6, "save": "Kicking Out"},
    {"n": 199, "b": 4, "q": "Kiss", "d": "", "len": 3.73, "save": "Kiss"},
    {"n": 200, "b": 4, "q": "Kneeling", "d": "Kneeling On One Knee Idle", "len": 4.67, "save": "Kneeling"},
    {"n": 201, "b": 4, "q": "Kneeling Pointing", "d": "Kneeling To Pointing", "len": 3.9, "save": "Kneeling Pointing"},
    {"n": 202, "b": 4, "q": "Knocked Out", "d": "Knocked Out Falling To Stomach", "len": 5.6, "save": "Knocked Out"},
    {"n": 203, "b": 4, "q": "Knocked Out", "d": "Knocked Out Falling To Back", "len": 4.93, "save": "Knocked Out (1)"},
    {"n": 204, "b": 4, "q": "Laying Idle", "d": "Laying On Back Looking Around", "len": 12.5, "save": "Laying Idle"},
    {"n": 205, "b": 4, "q": "Left Turn", "d": "", "len": 0.93, "save": "Left Turn"},
    {"n": 206, "b": 4, "q": "Left Turn W_Briefcase", "d": "", "len": 2.2, "save": "Left Turn W_Briefcase"},
    {"n": 207, "b": 4, "q": "Light Hit To Head", "d": "", "len": 0.83, "save": "Light Hit To Head"},
    {"n": 208, "b": 4, "q": "Look Behind Run", "d": "Running While Looking Behind", "len": 0.77, "save": "Look Behind Run"},
    {"n": 209, "b": 4, "q": "Looking", "d": "Looking At Something And Shading Eyes", "len": 4.87, "save": "Looking"},
    {"n": 210, "b": 4, "q": "Looking Around Idle", "d": "", "len": 6.33, "save": "Looking Around idle"},
    {"n": 211, "b": 4, "q": "Moonwalk", "d": "Walking Backwards Sliding Feet", "len": 1.03, "save": "Moonwalk"},
    {"n": 212, "b": 4, "q": "Neck Stretching", "d": "Stretching Neck Rolling Side To Side", "len": 3.2, "save": "Neck Stretching"},
    {"n": 213, "b": 4, "q": "No", "d": "Indicating No", "len": 5.0, "save": "No"},
    {"n": 214, "b": 4, "q": "Northern Soul Dance", "d": "Basic Northern Soul Step", "len": 16.07, "save": "Northern Soul Dance"},
    {"n": 215, "b": 4, "q": "Offensive Idle", "d": "Offensive Soccer Idle", "len": 10.57, "save": "Offensive Idle"},
    {"n": 216, "b": 4, "q": "Old Man Walk", "d": "Slow Old Man Shuffle Walk", "len": 1.27, "save": "Old Man Walk"},
    {"n": 217, "b": 4, "q": "Opening A Filing Cabinet", "d": "Using The Bottom Drawer Of A Filing Cabinet", "len": 14.17, "save": "Opening A Filing Cabinet"},
    {"n": 218, "b": 4, "q": "Opening Locked", "d": "", "len": 5.23, "save": "Opening locked"},
    {"n": 219, "b": 4, "q": "Opening Slide Door", "d": "", "len": 4.8, "save": "Opening slide door"},
    {"n": 220, "b": 4, "q": "Orc Idle", "d": "Male Orc Standing Idle", "len": 6.67, "save": "Orc Idle"},
    {"n": 221, "b": 4, "q": "Pacing And Talking On A Phone", "d": "Female Answers A Phone While Walking", "len": 37.63, "save": "Pacing And Talking On A Phone"},
    {"n": 222, "b": 4, "q": "Paddling", "d": "Paddling A Single Oar Canoe", "len": 7.23, "save": "Paddling"},
    {"n": 223, "b": 4, "q": "Patting", "d": "Patting On The Back", "len": 3.33, "save": "Patting"},
    {"n": 224, "b": 4, "q": "Pistol Idle", "d": "Ready Alert Two Hand Pistol Grip", "len": 4.0, "save": "Pistol Idle"},
    {"n": 225, "b": 4, "q": "Pointing", "d": "Pointing With Arm Bent", "len": 2.77, "save": "Pointing"},
    {"n": 226, "b": 4, "q": "Pointing Forward", "d": "Looking Down Then Pointing Forward", "len": 4.7, "save": "Pointing Forward"},
    {"n": 227, "b": 4, "q": "Pointing Back Thumb", "d": "", "len": 3.6, "save": "Pointing back thumb"},
    {"n": 228, "b": 4, "q": "Praying", "d": "Falling To Knees In Prayer", "len": 6.67, "save": "Praying"},
    {"n": 229, "b": 4, "q": "Praying", "d": "Standing Praying While Swaying", "len": 3.23, "save": "Praying (1)"},
    {"n": 230, "b": 4, "q": "Punching", "d": "", "len": 1.03, "save": "Punching"},
    {"n": 231, "b": 4, "q": "Punching", "d": "", "len": 1.0, "save": "Punching (1)"},
    {"n": 232, "b": 4, "q": "Push Stop", "d": "Stop Pushing A Heavy Object", "len": 2.6, "save": "Push Stop"},
    {"n": 233, "b": 4, "q": "Quick Formal Bow", "d": "", "len": 2.73, "save": "Quick Formal Bow", "nd": 1},
    {"n": 234, "b": 4, "q": "Rallying", "d": "Rallying The Crowd To Make Them Cheer", "len": 6.2, "save": "Rallying"},
    {"n": 235, "b": 4, "q": "Rapping", "d": "MC Rapping On The Microphone", "len": 7.9, "save": "Rapping"},
    {"n": 236, "b": 4, "q": "Receive Punch To The Face", "d": "Receive Stomach Uppercut", "len": 1.3, "save": "Receive Punch To The Face"},
    {"n": 237, "b": 4, "q": "Receiving Cpr", "d": "Receiving Cpr On The Ground", "len": 8.63, "save": "Receiving Cpr"},
    {"n": 238, "b": 4, "q": "Reloading", "d": "", "len": 3.67, "save": "Reloading"},
    {"n": 239, "b": 4, "q": "Restrain", "d": "Block And Restraining A Larger Person", "len": 7.57, "save": "Restrain"},
    {"n": 240, "b": 4, "q": "Rifle Start Run", "d": "Starting To Run With A Aimed Rifle", "len": 1.73, "save": "Rifle Start Run"},
    {"n": 241, "b": 4, "q": "Right Turn", "d": "", "len": 1.0, "save": "Right Turn"},
    {"n": 242, "b": 4, "q": "Right Turn W_ Briefcase", "d": "", "len": 2.13, "save": "Right Turn W_ Briefcase"},
    {"n": 243, "b": 4, "q": "Rolling", "d": "", "len": 2.53, "save": "Rolling"},
    {"n": 244, "b": 4, "q": "Run Look Back", "d": "Running Looking Back", "len": 2.23, "save": "Run Look Back"},
    {"n": 245, "b": 4, "q": "Run To Dive", "d": "Diving From A Run Pose", "len": 1.2, "save": "Run To Dive"},
    {"n": 246, "b": 4, "q": "Run To Stop Without Climb", "d": "", "len": 1.8, "save": "Run To Stop Without climb"},
    {"n": 247, "b": 4, "q": "Run With Sword", "d": "Running With A Sword In The Right Hand", "len": 0.8, "save": "Run With Sword"},
    {"n": 248, "b": 4, "q": "Running", "d": "", "len": 0.7, "save": "Running (1)"},
    {"n": 249, "b": 4, "q": "Running Away Scared", "d": "", "len": 1.63, "save": "Running Away Scared"},
    {"n": 250, "b": 4, "q": "Running To Turn", "d": "Fast Run To 180 Degree Turn", "len": 2.27, "save": "Running To Turn"},
    {"n": 251, "b": 4, "q": "Running With A Box", "d": "", "len": 1.27, "save": "Running with a box"},
    {"n": 252, "b": 4, "q": "Salute", "d": "Formal Military Salute", "len": 2.83, "save": "Salute"},
    {"n": 253, "b": 4, "q": "Sarcastic Head Nod", "d": "Sarcastically Nodding Head Yes", "len": 2.33, "save": "Sarcastic Head Nod"},
    {"n": 254, "b": 4, "q": "Seated Table Idle", "d": "", "len": 4.17, "save": "Seated table Idle"},
    {"n": 255, "b": 4, "q": "Shaking Hands 1", "d": "2 People Shaking Hands Part 1 -  Female", "len": 4.37, "save": "Shaking Hands 1"},
    {"n": 256, "b": 4, "q": "Shaking Hands 2", "d": "2 People Shaking Hands Part 2 -  Male", "len": 4.37, "save": "Shaking Hands 2"},
    {"n": 257, "b": 4, "q": "Shooting Gun", "d": "Shooting Handgun", "len": 5.3, "save": "Shooting Gun"},
    {"n": 258, "b": 4, "q": "Shopping Cart Dance", "d": "Shopping Cart Silly Dance", "len": 15.93, "save": "Shopping Cart Dance"},
    {"n": 259, "b": 4, "q": "Shoulder Hit And Fall", "d": "Hit In The Shoulder And Falls To The Ground", "len": 3.1, "save": "Shoulder Hit And Fall"},
    {"n": 260, "b": 4, "q": "Shove Reaction", "d": "Getting Shoved While Walking", "len": 2.43, "save": "Shove Reaction"},
    {"n": 261, "b": 4, "q": "Shove Reaction", "d": "Standing Reaction To Shove", "len": 3.0, "save": "Shove Reaction (1)"},
    {"n": 262, "b": 4, "q": "Shoved Reaction With Spin", "d": "Reaction To Getting Clipped While Walking Unaware", "len": 4.53, "save": "Shoved Reaction With Spin"},
    {"n": 263, "b": 4, "q": "Shuffling", "d": "Doing The Shuffling Dance", "len": 7.5, "save": "Shuffling"},
    {"n": 264, "b": 4, "q": "Silly Dancing", "d": "Silly Dancing The Cabbage Patch", "len": 3.83, "save": "Silly Dancing"},
    {"n": 265, "b": 4, "q": "Singing", "d": "Singing While Walking On Stage", "len": 13.97, "save": "Singing"},
    {"n": 266, "b": 4, "q": "Sit To Stand", "d": "Sitting To Standing", "len": 2.27, "save": "Sit To Stand"},
    {"n": 267, "b": 4, "q": "Sit To Type", "d": "Sitting To Typing", "len": 1.2, "save": "Sit To Type"},
    {"n": 268, "b": 4, "q": "Sitting Clap", "d": "", "len": 6.5, "save": "Sitting Clap"},
    {"n": 269, "b": 4, "q": "Sitting Disapproval", "d": "Sitting And Shaking Finger In Disapproval", "len": 3.93, "save": "Sitting Disapproval"},
    {"n": 270, "b": 4, "q": "Sitting Disbelief", "d": "Sitting In Disbelief With Head Forward", "len": 4.63, "save": "Sitting Disbelief"},
    {"n": 271, "b": 4, "q": "Sitting Idle", "d": "Sitting With Breathing Idle", "len": 4.3, "save": "Sitting Idle"},
    {"n": 272, "b": 4, "q": "Sitting Idle", "d": "Sitting On The Floor", "len": 10.87, "save": "Sitting Idle (1)"},
    {"n": 273, "b": 4, "q": "Sitting Thumbs Up", "d": "Giving Thumbs Up While Sitting", "len": 3.83, "save": "Sitting Thumbs Up"},
    {"n": 274, "b": 4, "q": "Sitting Yell", "d": "Short Yell Sitting Forward", "len": 1.97, "save": "Sitting Yell"},
    {"n": 275, "b": 4, "q": "Sitting Talking", "d": "", "len": 5.0, "save": "Sitting talking"},
    {"n": 276, "b": 4, "q": "Situp To Idle", "d": "Situp Transition To Fitness Idle", "len": 4.4, "save": "Situp To Idle"},
    {"n": 277, "b": 4, "q": "Sleeping Idle", "d": "", "len": 17.6, "save": "Sleeping Idle"},
    {"n": 278, "b": 4, "q": "Smoking", "d": "Idle Smoking", "len": 17.9, "save": "Smoking"},
    {"n": 279, "b": 4, "q": "Sneak Off The Cover", "d": "", "len": 3.0, "save": "Sneak off the cover"},
    {"n": 280, "b": 4, "q": "Spat In Face", "d": "Painfully Getting Spat On In The Face", "len": 2.53, "save": "Spat In Face"},
    {"n": 281, "b": 4, "q": "Spinning", "d": "Body Spin On Staff Tip", "len": 1.7, "save": "Spinning"},
    {"n": 282, "b": 4, "q": "Stand To Sit", "d": "Standing To Sitting Transition", "len": 2.23, "save": "Stand To Sit"},
    {"n": 283, "b": 4, "q": "Standing Arguing", "d": "", "len": 20.8, "save": "Standing Arguing"},
    {"n": 284, "b": 4, "q": "Standing Arguing", "d": "", "len": 20.8, "save": "Standing Arguing (1)"},
    {"n": 285, "b": 4, "q": "Standing Cheering", "d": "", "len": 3.43, "save": "Standing Cheering"},
    {"n": 286, "b": 4, "q": "Standing Greeting", "d": "Greeting While Standing", "len": 5.1, "save": "Standing Greeting"},
    {"n": 287, "b": 4, "q": "Standing Up", "d": "Standing Up From Lying On Stomach", "len": 11.4, "save": "Standing Up (1)"},
    {"n": 288, "b": 4, "q": "Standing Using Touchscreen Tablet", "d": "Female Using Touchscreen Tablet", "len": 33.13, "save": "Standing Using Touchscreen Tablet"},
    {"n": 289, "b": 4, "q": "Standing W_Briefcase Idle", "d": "", "len": 13.93, "save": "Standing W_Briefcase Idle"},
    {"n": 290, "b": 4, "q": "Step Hip Hop Dance", "d": "", "len": 7.8, "save": "Step Hip Hop Dance", "nd": 1},
    {"n": 291, "b": 4, "q": "Jumping", "d": "Step Up To Jump Over Object", "len": 2.87, "save": "Step Up Vault"},
    {"n": 292, "b": 4, "q": "Stomping", "d": "Stomping Foot On Ground", "len": 1.8, "save": "Stomping"},
    {"n": 293, "b": 4, "q": "Stop Walking With Rifle", "d": "Walking With A Rifle To A Stop", "len": 2.27, "save": "Stop Walking With Rifle"},
    {"n": 294, "b": 4, "q": "Stumble Backwards", "d": "Slip And Fall Backwards", "len": 3.33, "save": "Stumble Backwards"},
    {"n": 295, "b": 4, "q": "Stunned", "d": "Male Knocked Down From A Punch", "len": 2.13, "save": "Stunned"},
    {"n": 296, "b": 4, "q": "Swatting Bugs", "d": "Walking While Swatting At Bugs In The Air", "len": 6.67, "save": "Swatting Bugs"},
    {"n": 297, "b": 4, "q": "Taking Punch", "d": "Getting Hit In The Face From Various Angles", "len": 5.67, "save": "Taking Punch"},
    {"n": 298, "b": 4, "q": "Talking", "d": "Talking Finding Something Funny", "len": 5.93, "save": "Talking"},
    {"n": 299, "b": 4, "q": "Talking", "d": "Asking A Question With One Hand", "len": 3.77, "save": "Talking (1)"},
    {"n": 300, "b": 4, "q": "Talking", "d": "", "len": 3.93, "save": "Talking (2)"},
    {"n": 301, "b": 4, "q": "Talking", "d": "General Conversation", "len": 10.27, "save": "Talking (3)"},
    {"n": 302, "b": 4, "q": "Talking", "d": "Asking A Question", "len": 5.17, "save": "Talking (4)"},
    {"n": 303, "b": 4, "q": "Talking At Watercooler", "d": "Having A Chat At The Watercooler", "len": 44.57, "save": "Talking At Watercooler"},
    {"n": 304, "b": 4, "q": "Talking On A Cell Phone", "d": "Male Standing While Talking On A Cell Phone", "len": 37.23, "save": "Talking On A Cell Phone"},
    {"n": 305, "b": 4, "q": "Talking On Phone", "d": "Female Standing Talking On Phone", "len": 38.83, "save": "Talking On Phone"},
    {"n": 306, "b": 4, "q": "Talking Phone Pacing", "d": "Male Talking On The Cell Phone While Pacing Back And Forth", "len": 42.23, "save": "Talking Phone Pacing"},
    {"n": 307, "b": 4, "q": "Taunt", "d": "Taunting Pointing At Wrist", "len": 2.83, "save": "Taunt"},
    {"n": 308, "b": 4, "q": "Telling A Secret", "d": "", "len": 10.9, "save": "Telling A Secret", "nd": 1},
    {"n": 309, "b": 4, "q": "Tender Placement", "d": "", "len": 9.27, "save": "Tender Placement"},
    {"n": 310, "b": 4, "q": "Terrified", "d": "Being Terrified While Standing", "len": 20.0, "save": "Terrified"},
    {"n": 311, "b": 4, "q": "Texting And Walking One Hand", "d": "", "len": 3.3, "save": "Texting And Walking one hand"},
    {"n": 312, "b": 4, "q": "Texting While Standing", "d": "Texting On A Smart Phone While Standing", "len": 23.57, "save": "Texting While Standing"},
    {"n": 313, "b": 4, "q": "Thankful", "d": "Being Thankful While Standing", "len": 3.0, "save": "Thankful"},
    {"n": 314, "b": 4, "q": "Threatening", "d": "Being Threatening While Standing", "len": 4.4, "save": "Threatening"},
    {"n": 315, "b": 4, "q": "Tripping", "d": "Tripping Forward While Walking", "len": 2.77, "save": "Tripping"},
    {"n": 316, "b": 4, "q": "Tripping", "d": "Walk To Tripping And Falling", "len": 2.1, "save": "Tripping (1)"},
    {"n": 317, "b": 4, "q": "Turn To Running", "d": "Turn Right And Run", "len": 1.7, "save": "Turn To Running"},
    {"n": 318, "b": 4, "q": "Type To Sit", "d": "Typing To Sitting Idle", "len": 0.93, "save": "Type To Sit"},
    {"n": 319, "b": 4, "q": "Typing", "d": "Sitting At A Computer And Typing", "len": 16.47, "save": "Typing"},
    {"n": 320, "b": 4, "q": "Using A Filing Cabinet", "d": "Using The Top Drawer Of A Filing Cabinet", "len": 10.33, "save": "Using A Filing Cabinet"},
    {"n": 321, "b": 4, "q": "Vault Over Box To Cover", "d": "", "len": 3.53, "save": "Vault Over Box to Cover"},
    {"n": 322, "b": 4, "q": "Victory", "d": "Celebrating After A Win", "len": 8.53, "save": "Victory"},
    {"n": 323, "b": 4, "q": "Walk In Circle", "d": "Male Walking Counter Clockwise", "len": 17.37, "save": "Walk In Circle"},
    {"n": 324, "b": 4, "q": "Walk With Briefcase", "d": "Male Walk With Briefcase", "len": 1.03, "save": "Walk With Briefcase"},
    {"n": 325, "b": 4, "q": "Walk With Rifle", "d": "Walking With Rifle At Waist Level 3 Cycle", "len": 3.37, "save": "Walk With Rifle"},
    {"n": 326, "b": 4, "q": "Walk Carry Stop", "d": "", "len": 4.9, "save": "Walk carry stop"},
    {"n": 327, "b": 4, "q": "Walking", "d": "", "len": 0.97, "save": "Walking (1)"},
    {"n": 328, "b": 4, "q": "Walking Carry", "d": "", "len": 2.87, "save": "Walking Carry"},
    {"n": 329, "b": 4, "q": "Walking Drunk", "d": "", "len": 2.5, "save": "Walking Drunk"},
    {"n": 330, "b": 4, "q": "Walking Up The Stairs", "d": "Male Walk Up The Stairs", "len": 1.2, "save": "Walking Up The Stairs"},
    {"n": 331, "b": 4, "q": "Walking While Texting", "d": "Male Walking While Texting On A Smartphone", "len": 4.0, "save": "Walking While Texting"},
    {"n": 332, "b": 4, "q": "Walking With Shopping Bag", "d": "Male Walking With Shopping Bag", "len": 1.27, "save": "Walking With Shopping Bag"},
    {"n": 333, "b": 4, "q": "Waving", "d": "Emotional Waving Forward", "len": 4.73, "save": "Waving"},
    {"n": 334, "b": 4, "q": "Waving", "d": "Waving With Both Hands", "len": 3.17, "save": "Waving (1)"},
    {"n": 335, "b": 4, "q": "Waving", "d": "", "len": 0.53, "save": "Waving (3)", "nd": 1},
    {"n": 336, "b": 4, "q": "Wheelbarrow Dump", "d": "Dumping A Wheelbarrow", "len": 6.23, "save": "Wheelbarrow Dump"},
    {"n": 337, "b": 4, "q": "Wheelbarrow Walk", "d": "", "len": 0.97, "save": "Wheelbarrow Walk"},
    {"n": 338, "b": 4, "q": "Wiping Sweat", "d": "Wiping Sweat Idle", "len": 2.63, "save": "Wiping Sweat"},
    {"n": 339, "b": 4, "q": "Working On Device Crouched", "d": "", "len": 6.43, "save": "Working On Device crouched"},
    {"n": 340, "b": 4, "q": "Yelling", "d": "Yelling In Anger", "len": 7.83, "save": "Yelling"},
    {"n": 341, "b": 4, "q": "Yelling Out", "d": "Stepping Forward And Yelling Out", "len": 4.3, "save": "Yelling Out"},
    {"n": 342, "b": 4, "q": "Sit Stand Up", "d": "", "len": 4.83, "save": "sit Stand Up"},
    {"n": 343, "b": 4, "q": "Sitting Pointing", "d": "", "len": 3.43, "save": "sitting Pointing"},
    {"n": 344, "b": 4, "q": "Crouched Sneaking Left", "d": "Crouched Cover Sneaking Left", "len": 1.27, "save": "crouched sneaking left"},
    {"n": 345, "b": 4, "q": "Crouched Sneaking Right", "d": "Crouched Cover Sneaking Right", "len": 1.1, "save": "crouched sneaking right"},
    {"n": 346, "b": 4, "q": "Idle", "d": "", "len": 10.0, "save": "idle (2)"},
    {"n": 347, "b": 4, "q": "Idle", "d": "", "len": 3.27, "save": "idle (3)"},
    {"n": 348, "b": 4, "q": "Idle", "d": "Standing Cover Against Object", "len": 2.27, "save": "idle (5)"},
    {"n": 349, "b": 4, "q": "Injured Backwards Turn Left", "d": "Injured Walking Backwards Left Turn", "len": 0.73, "save": "injured backwards turn left"},
    {"n": 350, "b": 4, "q": "Injured Backwards Turn Right", "d": "Injured Walking Backwards Right Turn", "len": 0.7, "save": "injured backwards turn right"},
    {"n": 351, "b": 4, "q": "Injured Hurting Idle", "d": "Injured Holding Hurt Leg Idle", "len": 6.03, "save": "injured hurting idle"},
    {"n": 352, "b": 4, "q": "Injured Idle", "d": "Injured Standard Idle", "len": 9.33, "save": "injured idle"},
    {"n": 353, "b": 4, "q": "Injured Run", "d": "Injured Running", "len": 0.63, "save": "injured run"},
    {"n": 354, "b": 4, "q": "Injured Run Backwards", "d": "Injured Running Backwards", "len": 0.6, "save": "injured run backwards"},
    {"n": 355, "b": 4, "q": "Injured Run Backwards Left Turn", "d": "Injured Running Backwards Turning Left", "len": 0.5, "save": "injured run backwards left turn"},
    {"n": 356, "b": 4, "q": "Injured Run Backwards Right Turn", "d": "Injured Running Backwards Turning Right", "len": 0.53, "save": "injured run backwards right turn"},
    {"n": 357, "b": 4, "q": "Injured Run Left Turn", "d": "Injured Running Turning Left", "len": 0.6, "save": "injured run left turn"},
    {"n": 358, "b": 4, "q": "Injured Run Right Turn", "d": "Injured Running Turning Right", "len": 0.63, "save": "injured run right turn"},
    {"n": 359, "b": 4, "q": "Injured Stumble Idle", "d": "Injured Stumbling Idle", "len": 5.07, "save": "injured stumble idle"},
    {"n": 360, "b": 4, "q": "Injured Walk", "d": "Injured Walking", "len": 1.63, "save": "injured walk"},
    {"n": 361, "b": 4, "q": "Injured Walk Backwards", "d": "Injured Walking Backwards", "len": 1.67, "save": "injured walk backwards"},
    {"n": 362, "b": 4, "q": "Injured Walk Left Turn", "d": "Injured Walking Turning Left", "len": 2.0, "save": "injured walk left turn"},
    {"n": 363, "b": 4, "q": "Injured Walk Right Turn", "d": "Injured Walking Turning Right", "len": 1.83, "save": "injured walk right turn"},
    {"n": 364, "b": 4, "q": "Injured Wave Idle", "d": "Injured Wave For Help Idle", "len": 5.07, "save": "injured wave idle"},
    {"n": 365, "b": 4, "q": "Jumping Up", "d": "Jumping Up From Action Idle Game Blend", "len": 0.23, "save": "jumping up"},
    {"n": 366, "b": 4, "q": "Left Cover Sneak", "d": "Left Standing Sneak Behind Cover", "len": 1.13, "save": "left cover sneak"},
    {"n": 367, "b": 4, "q": "Left Turn", "d": "", "len": 1.03, "save": "left turn"},
    {"n": 368, "b": 4, "q": "Right Turn", "d": "", "len": 1.03, "save": "right turn"},
    {"n": 369, "b": 4, "q": "Standard Run", "d": "Standard Running", "len": 0.73, "save": "standard run"}
  ];

  const token = localStorage.access_token;
  if (!token) { console.error('Not signed in: no access_token on this page.'); return; }
  const H = { 'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token, 'X-Api-Key': 'mixamo2', 'X-Requested-With': 'XMLHttpRequest' };
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  const api = async (path, opt = {}) => {
    const r = await fetch('https://www.mixamo.com/api/v1' + path, Object.assign({ headers: H }, opt));
    if (!r.ok && r.status !== 202) throw new Error(path + ' -> ' + r.status);
    return r.json();
  };

  // the active character
  let character = null, charName = '';
  try { const p = await api('/characters/primary'); character = p.primary_character_id || p.id || (p.character && p.character.id); charName = p.primary_character_name || p.name || ''; } catch (e) {}
  if (!character) character = prompt('Could not read the active character. Paste the character id (from the address of a download request in the Network tab):');
  if (!character) { console.error('No character id.'); return; }
  if (!confirm('Download clips for this character?\n\n' + (charName || '(name not shown)') + '\n' + character + '\n\nPress Cancel if this is not player_v4.')) return;

  const norm = s => (s || '').toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
  const search = async q => {
    let out = [], page = 1, pages = 1;
    while (page <= pages && page <= 5) {
      const j = await api('/products?page=' + page + '&limit=96&order=&type=Motion&query=' + encodeURIComponent(q));
      out = out.concat(j.results || []); pages = (j.pagination && j.pagination.num_pages) || 1; page++;
    }
    return out;
  };
  const monitor = async () => {
    for (let i = 0; i < 180; i++) {
      const m = await api('/characters/' + character + '/monitor');
      if (m.status === 'completed') return m.job_result;
      if (m.status === 'failed') throw new Error('export failed: ' + JSON.stringify(m.job_result).slice(0, 200));
      await sleep(1000);
    }
    throw new Error('export timed out');
  };
  const exportOne = async (product, fileName) => {
    const det = await api('/products/' + product.id + '?similar=0&character_id=' + character);
    const g = det.details.gms_hash;
    const hash = Object.assign({}, g, { params: g.params.map(p => p[1]).join(','), inplace: false });
    let url = null, lastErr = null;
    for (const format of ['fbx7_2019', 'fbx7']) {
      try {
        await api('/animations/export', { method: 'POST', body: JSON.stringify({ character_id: character, gms_hash: [hash], preferences: { format, skin: 'false', fps: '30', reducekf: '0' }, product_name: product.name, type: 'Motion' }) });
        url = await monitor(); break;
      } catch (e) { lastErr = e; }
    }
    if (!url) throw lastErr;
    try {                                   // save under our own name
      const blob = await (await fetch(url)).blob();
      const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = fileName; document.body.appendChild(a); a.click(); a.remove();
      setTimeout(() => URL.revokeObjectURL(a.href), 60000);
      return 'saved as ' + fileName;
    } catch (e) {                           // the file server refused the page: let the browser save it under Mixamo's name
      const a = document.createElement('a'); a.href = url; a.download = fileName; document.body.appendChild(a); a.click(); a.remove();
      return 'saved under Mixamo name (rename to ' + fileName + ')';
    }
  };

  const EXTRA = ['axe', 'rifle', 'pistol', 'gun', 'sword', 'shield', 'bow', 'spell', 'magic', 'torch', 'briefcase', 'box', 'bag', 'phone', 'zombie', 'ninja', 'boxing', 'drunk', 'injured', 'sad', 'happy', 'female', 'carrying', 'aiming', 'crouched', 'crouch', 'swagger', 'silly', 'goofy', 'mutant', 'orc', 'old'];
  let toldKeys = false;
  const lengthOf = det => {            // seconds, or null when Mixamo does not say
    const d = det.details || {};
    if (!toldKeys) { toldKeys = true; console.log('Mixamo clip details hold: ' + Object.keys(d).join(', ') + ' | motion: ' + Object.keys(d.gms_hash || {}).join(', ')); }
    for (const o of [d, det, d.gms_hash || {}]) for (const key of Object.keys(o)) {
      const v = Number(o[key]); if (!isFinite(v) || v <= 0) continue;
      if (/^(duration|length|seconds|time)$/i.test(key)) return v > 200 ? v / 1000 : v;
      if (/frame/i.test(key) && v > 1) return (v - 1) / 30;
    }
    return null;
  };
  const done = new Set(JSON.parse(localStorage.getItem('mxdl_done') || '[]'));
  const report = [['n', 'save_as', 'searched', 'wanted_description', 'result', 'mixamo_name', 'mixamo_description']];
  const todo = CLIPS.filter(c => BATCHES.includes(c.b) && !done.has(c.save));
  console.log('Mixamo download: ' + todo.length + ' clips to do, ' + done.size + ' already done.');
  let k = 0;
  for (const c of todo) {
    k++;
    try {
      const res = await search(c.q);
      let same = res.filter(p => norm(p.name) === norm(c.q));
      if (!same.length) same = res.filter(p => norm(p.name).startsWith(norm(c.q)));
      let picks = c.d ? same.filter(p => norm(p.description) === norm(c.d)) : [];
      if (!picks.length && c.nd) picks = same.filter(p => !norm(p.description));
      let how = 'description';
      if (picks.length > 1) picks = picks.slice(0, 1);
      if (!picks.length && same.length === 1) { picks = same; how = 'only one with this name'; }
      if (!picks.length && same.length > 1) {
        // several clips share the name: first try to tell them apart by length, as Mixamo reports it
        const byLen = [];
        for (const p of same.slice(0, 30)) {
          try { const sec = lengthOf(await api('/products/' + p.id + '?similar=0&character_id=' + character)); if (sec !== null && Math.abs(sec - c.len) < 0.07) byLen.push(p); } catch (e) {}
        }
        if (byLen.length === 1) { picks = byLen; how = 'length ' + c.len + ' s'; }
        else {
          // then drop the ones that plainly are another clip: a prop or mood word that the wanted clip does not have
          const want = norm(c.save + ' ' + c.d);
          const pool = (byLen.length ? byLen : same).filter(p => !EXTRA.some(w => norm(p.description).split(' ').includes(w) && !want.split(' ').includes(w)));
          if (pool.length === 1) { picks = pool; how = 'only plain one with this name'; }
          else if (pool.length > 1 && pool.length <= MAX_SAME_NAME) { picks = pool; how = 'ALL ' + picks.length + ' plain ones with this name (sort later by length ' + c.len + ' s)'; }
          else { console.warn(k + '/' + todo.length + ' SKIPPED, cannot tell which: ' + c.save + ' (' + same.length + ' clips named "' + c.q + '", wanted length ' + c.len + ' s)'); report.push([c.n, c.save, c.q, c.d, 'SKIPPED cannot tell which of ' + same.length, '', same.map(p => p.description).join(' / ')]); continue; }
        }
      }
      if (!picks.length) { console.warn(k + '/' + todo.length + ' NOT FOUND: ' + c.save + ' (searched "' + c.q + '")'); report.push([c.n, c.save, c.q, c.d, 'NOT FOUND', '', '']); continue; }
      for (let i = 0; i < picks.length; i++) {
        const p = picks[i];
        const fn = (picks.length === 1 ? c.save : c.save + ' @@ ' + (p.description || 'variant ' + (i + 1)).replace(/[\\/:*?"<>|]/g, ' ')) + '.fbx';
        const r = await exportOne(p, fn);
        console.log(k + '/' + todo.length + ' ' + c.save + ' <- ' + p.name + ' | ' + p.description + ' | ' + how + ' | ' + r);
        report.push([c.n, c.save, c.q, c.d, how + '; ' + r, p.name, p.description]);
        await sleep(PAUSE_MS);
      }
      done.add(c.save); localStorage.setItem('mxdl_done', JSON.stringify([...done]));
    } catch (e) {
      console.error(k + '/' + todo.length + ' FAILED: ' + c.save + ' - ' + e.message); report.push([c.n, c.save, c.q, c.d, 'FAILED ' + e.message, '', '']);
      if (/-> 401|-> 403/.test(e.message)) { console.error('Signed out or refused. Sign in again and re-run; finished clips are skipped.'); break; }
      if (/-> 429/.test(e.message)) { console.warn('Mixamo asked to slow down; waiting a minute.'); await sleep(60000); }
    }
  }
  const csv = report.map(r => r.map(x => '"' + String(x).replace(/"/g, '""') + '"').join(',')).join('\n');
  const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv' })); a.download = 'mixamo_download_report.csv'; document.body.appendChild(a); a.click(); a.remove();
  console.log('Finished. Not found or failed: ' + report.filter(r => /NOT FOUND|FAILED/.test(r[4])).length + '. See mixamo_download_report.csv.');
})();
