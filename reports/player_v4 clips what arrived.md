# player_v4 clips: what arrived, what to rename, what is still missing

Checked 25 Nov 2026 by measuring every file in the Drive folder `player_v4` (366 clips) and comparing each with the X Bot clip of the same name (same length, travel, rise and turn means it is the same motion).

| Batch | Wanted | Arrived and right | Not there |
|---|---|---|---|
| 1 | 35 | 31 | 4 |
| 2 | 33 | 25 | 8 |
| 3 | 17 | 12 | 5 |
| 4 | 284 | 204 | 80 |
| all | 369 | 272 | 97 |

`sort_player_v4.ps1` (next to this file) does the renaming for you: run it in the `player_v4` folder and it gives each right file its final name and moves the 94 files that are not needed into a subfolder called `_unused`. It deletes nothing.

## Still to download: batches 1 to 3 (needed for the build)

| Batch | Save as | Search | Pick |
|---|---|---|---|
| 1 | Running Left Turn (2) | Running Left Turn | if it is not there, skip it; the right turn can be mirrored in the game |
| 1 | Running Right Turn | Running Right Turn | Turning Right While Running |
| 1 | Start Walking | Start Walking | Walking From Standing |
| 1 | Crouching Idle | Crouching Idle | Low Crouching Idle |
| 2 | falling to roll | Falling To Roll | Mid-Air Falling Into A Roll Game Blend |
| 2 | Running Jump | Running Jump | Jumping From A Sprint |
| 2 | Running Jump Climb | Running Jump | Fast Run To Jump Up Onto Higher Level |
| 2 | Jump To Braced Hang | Idle To Braced Hang | Jump To A Braced Hang From Standing Idle |
| 2 | Braced Hang Shimmy Right | Braced Hang Shimmy | Right Braced Hang Shimmy |
| 2 | Braced To Freehang | Braced To Free Hang | Braced Idle To Free Hang Idle |
| 2 | Drop To Freehang | Drop To Freehang | Standing Drop To Freehang |
| 2 | Push Up To Idle | Push Up To Idle | Basic Push Up Transition To Fitness Idle |
| 3 | stand to cover | Stand To Cover | Standing Ready To Standing Cover |
| 3 | cover to stand | Cover To Stand | Crouch Cover To Standing Ready |
| 3 | Right Cover Sneak | Right Cover Sneak | Right Standing Sneak Behind Cover |
| 3 | Standing Cover Turn | Standing Cover Turn | Changing Direction In Stand Cover |
| 3 | Entering Car | Entering Car | Entering Into The Driverside Of A Car |

The script reported most of these as downloaded, but no file with that motion is in the folder. The likely cause is that Mixamo's file server refused the page's own save, so the browser saved the clip under Mixamo's name, and a clip with the same Mixamo name overwrote or displaced it.

## Still to download: batch 4 (cinematics, not needed for the build)

| Save as | Search | Pick |
|---|---|---|
| Acknowledging | Acknowledging | Acknowledging Gesture |
| Aim Pistol sitting | Aim Pistol Sitting | not in the catalogue copy; search by this name |
| Aiming Gun | Aiming Gun | Picking Up Gun From Ground To Aiming |
| Angry Gesture | Angry Gesture | Angrily Pumping Fists Forward |
| Angry Gesture sitting | Angry Gesture Sitting | not in the catalogue copy; search by this name |
| Asking Question | Asking Question | Seated Idle With Hands On A Table |
| Being Carried out down | Being Carried Out Down | not in the catalogue copy; search by this name |
| Being Carried pick up | Being Carried Pick Up | not in the catalogue copy; search by this name |
| Being Carried walking | Being Carried Walking | not in the catalogue copy; search by this name |
| Box Idle | Box Idle | Carrying A Box |
| Carrying Turn | Carrying Turn | Carrying Someone To Turn Left |
| Climbing Down ladder | Climbing Down Ladder | not in the catalogue copy; search by this name |
| Climbing Ladder fast | Climbing Ladder Fast | not in the catalogue copy; search by this name |
| Climbing To Top ladder | Climbing To Top Ladder | not in the catalogue copy; search by this name |
| Climbing ladder slow | Climbing Ladder Slow | not in the catalogue copy; search by this name |
| Cocky Head Turn | Cocky Head Turn | Turning Head To The Side In A Cocky Manner |
| Counting | Counting | Counting To Five On One Hand |
| Dice Idle | Dice Idle | Tapping Fingers From A Sitting Position |
| Disappointed (2) | Disappointed | Disappointed "Awe-Shucks" |
| Drunk Idle Variation | Drunk Idle Variation | Drunk Idle Variation Stumble |
| Drunk Walking Turn | Drunk Walking Turn | Turning Left While Walking Left |
| Falling | Falling | Falling In The Air Idle |
| Falling Down on ass | Falling Down On Ass | not in the catalogue copy; search by this name |
| Falling Into Pool | Falling Into Pool | Losing Balance And Falling Sideways Into A Pool |
| Fast Run | Fast Run | Running Fast |
| Fight forwardstep | Fight Forwardstep | not in the catalogue copy; search by this name |
| Fight idle | Fight Idle | one of 2 clips with this name; pick by length |
| Fight sidestep (L) | Fight Sidestep (L) | not in the catalogue copy; search by this name |
| Finding | Finding | Finding Something On The Ground |
| Fistfight Taunt | Fistfight Taunt | not in the catalogue copy; search by this name |
| Hands Forward Gesture | Hands Forward Gesture | Two Handed Forward Gesture |
| Hit On The Back | Hit On The Back | Getting Hit On The Back With An Object While Running |
| Hit To Body | Hit To Body | Receiving A Body Hit By A Straight Punch or Receiving A Hit To The Body By A Straight |
| Hostage Situation Idle - Hostage | Hostage Situation Idle - Hostage | Armed Villain Holding A Hostage From Behind |
| Idle Transition | Idle Transition | Transition From Fitness Idle To Idle |
| Injured Walking arm | Injured Walking Arm | not in the catalogue copy; search by this name |
| Injured walking leg | Injured Walking Leg | not in the catalogue copy; search by this name |
| Jog In Circle | Jog In Circle | Jog In A Circle |
| Jump To Hang | Jump To Hang | Jump Grab To Free Hanging |
| Kick To The Groin | Kick To The Groin | Receive A Kick To The Groin To Falling Down |
| Left Turn W_Briefcase | Left Turn W_Briefcase | not in the catalogue copy; search by this name |
| Looking Around idle | Looking Around Idle | not in the catalogue copy; search by this name |
| Opening locked | Opening Locked | not in the catalogue copy; search by this name |
| Opening slide door | Opening Slide Door | not in the catalogue copy; search by this name |
| Orc Idle | Orc Idle | Male Orc Standing Idle |
| Paddling | Paddling | Paddling A Single Oar Canoe |
| Pointing back thumb | Pointing Back Thumb | not in the catalogue copy; search by this name |
| Praying | Praying | Falling To Knees In Prayer |
| Run To Stop Without climb | Run To Stop Without Climb | not in the catalogue copy; search by this name |
| Running Away Scared | Running Away Scared | not in the catalogue copy; search by this name |
| Seated table Idle | Seated Table Idle | not in the catalogue copy; search by this name |
| Shooting Gun | Shooting Gun | Shooting Handgun |
| Shoved Reaction With Spin | Shoved Reaction With Spin | Reaction To Getting Clipped While Walking Unaware |
| Sit To Type | Sit To Type | Sitting To Typing |
| Situp To Idle | Situp To Idle | Situp Transition To Fitness Idle |
| Sneak off the cover | Sneak Off The Cover | not in the catalogue copy; search by this name |
| Stand To Sit | Stand To Sit | Standing To Sitting Transition |
| Standing W_Briefcase Idle | Standing W_Briefcase Idle | not in the catalogue copy; search by this name |
| Stumble Backwards | Stumble Backwards | Slip And Fall Backwards |
| Talking (2) | Talking | one of 7 clips with this name; pick by length |
| Talking On Phone | Talking On Phone | Female Standing Talking On Phone |
| Taunt | Taunt | Taunting Pointing At Wrist |
| Texting And Walking one hand | Texting And Walking One Hand | not in the catalogue copy; search by this name |
| Thankful | Thankful | Being Thankful While Standing |
| Using A Filing Cabinet | Using A Filing Cabinet | Using The Top Drawer Of A Filing Cabinet |
| Vault Over Box to Cover | Vault Over Box To Cover | not in the catalogue copy; search by this name |
| Walk With Briefcase | Walk With Briefcase | Male Walk With Briefcase |
| Walk carry stop | Walk Carry Stop | not in the catalogue copy; search by this name |
| Working On Device crouched | Working On Device Crouched | not in the catalogue copy; search by this name |
| Yelling Out | Yelling Out | Stepping Forward And Yelling Out |
| sit Stand Up | Sit Stand Up | not in the catalogue copy; search by this name |
| sitting Pointing | Sitting Pointing | not in the catalogue copy; search by this name |
| crouched sneaking right | Crouched Sneaking Right | Crouched Cover Sneaking Right |
| idle (3) | Idle | Male Fitness Idle With Breathing or Ready Pose To Adjusting Stance |
| injured backwards turn left | Injured Backwards Turn Left | Injured Walking Backwards Left Turn |
| injured hurting idle | Injured Hurting Idle | Injured Holding Hurt Leg Idle |
| injured run backwards right turn | Injured Run Backwards Right Turn | Injured Running Backwards Turning Right |
| injured stumble idle | Injured Stumble Idle | Injured Stumbling Idle |
| injured walk right turn | Injured Walk Right Turn | Injured Walking Turning Right |
| left cover sneak | Left Cover Sneak | Left Standing Sneak Behind Cover |

## Files given their final name by the script

| File in the folder | Becomes |
|---|---|
| Standing Idle @@ Standing Idle.fbx | Standing Idle.fbx |
| Walking Backwards @@ Walking Backwards [case-duplicate name].fbx | Walking Backwards.fbx |
| 180 Turn W_ Briefcase @@ Male 180 Turn With Briefcase.fbx | 180 Turn W_ Briefcase.fbx |
| 180 Turn W_ Briefcase (1) @@ Female 180 Turn With Briefcase.fbx | 180 Turn W_ Briefcase (1).fbx |
| Talking (2) @@ Male Talking On The Cell Phone.fbx | Angry talking phone.fbx |
| Cheering @@ Male Cheering With Two Fists Pump.fbx | Cheering.fbx |
| Dancing @@ Female  African Noodle  Dance.fbx | Dancing.fbx |
| Dancing (1) @@ Boogaloo.fbx | Dancing (1).fbx |
| Dying @@ Dying Rear Impact Falling On Two Knees.fbx | Dying.fbx |
| Head Hit @@ Receiving A Big Hit To The Head From A Left Punch.fbx | Elbow Punching.fbx |
| Walking Backwards @@ One Foot At A Time In Combat Pose (1).fbx | Fight backstep.fbx |
| Walking (1) @@ Boxing Left Side Step Walk.fbx | Fight sidestep (R).fbx |
| Fist Pump @@ Big Standing Fist Pump From Sitting [case-duplicate name].fbx | Fist Pump.fbx |
| Head Hit @@ Receiving A Light Hit To The Head From A Left Punch.fbx | Head Hit.fbx |
| Kiss @@ Kissing A Shorter Person For A Short Period.fbx | Kiss.fbx |
| left turn @@ Standing Left Turn (2).fbx | Left Turn.fbx |
| Light Hit To Head @@ Receiving A Light Hit From A Straight Punch.fbx | Light Hit To Head.fbx |
| Punching @@ Hook Punch With The Rear Hand.fbx | Punching.fbx |
| Punching (1) @@ Hook Punch With The Rear Hand.fbx | Punching (1).fbx |
| Reloading @@ Gun Reload While Walking.fbx | Reloading.fbx |
| Right Turn @@ Standing Right Turn Sans Rotation.fbx | Right Turn.fbx |
| Right Turn W_ Briefcase @@ Male Right Turn With Briefcase.fbx | Right Turn W_ Briefcase.fbx |
| Running (1) @@ Action Move Running And Rolling.fbx | Rolling.fbx |
| Running (1) @@ Running Forward Quickly [case-duplicate name].fbx | Running (1).fbx |
| Running (1) @@ Running While Carrying Someone.fbx | Running with a box.fbx |
| Sitting Clap @@ Sitting Unethusiastic Clap.fbx | Sitting Clap.fbx |
| Talking (2) @@ Male Talking While Seated.fbx | Sitting talking.fbx |
| Sleeping Idle @@ Restless Sleeping.fbx | Sleeping Idle.fbx |
| Standing Arguing @@ Standing And Arguing With Another Person.fbx | Standing Arguing.fbx |
| Standing Arguing (1) @@ Standing And Arguing With Another Person.fbx | Standing Arguing (1).fbx |
| Standing Cheering @@ Sitting To Standing Big Fist Pump.fbx | Standing Cheering.fbx |
| Tender Placement @@ Tenderly Placing Someone On A Bed.fbx | Tender Placement.fbx |
| Walking (1) @@ Feminine Walk Forward.fbx | Walking (1).fbx |
| Walking (1) @@ Walking While Carrying Someone.fbx | Walking Carry.fbx |
| Walking (1) @@ Walking While Drunk.fbx | Walking Drunk.fbx |
| Waving (3) @@ Waving With Both Hands.fbx | Waving (1).fbx |
| Waving (3) @@ Waving.fbx | Waving (3).fbx |
| Wheelbarrow Walk @@ Walking With A Full Wheelbarrow.fbx | Wheelbarrow Walk.fbx |
| idle (2) @@ Standing Idle [case-duplicate name].fbx | idle (2).fbx |
| Left Turn @@ Standing Left Turn (1).fbx | left turn.fbx |
| Right Turn @@ Turning Right.fbx | right turn.fbx |
