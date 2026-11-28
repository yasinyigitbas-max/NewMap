# ALIEN STATUS: cutscenes and animation

Yasin, 28 Nov: "lots of cut scenes and animations everywhere based on the animations we have (both used and
unused ones yet and with custom takes from kimodo if need be)."

This file says how the 115 cutscenes in the mission files are made from the clips that exist, which unused clips
they bring into use, and which new takes they need. Clip names are exactly as in the libraries (surveyed 28 Nov):
- **mx/** = the Mixamo set fitted to the crowd figures, 310 clips (`characters/mixamo/_index.json`). Many are
  fitted but not called by any code yet: those are marked *(unused)* the first time they appear.
- **ual/** = Quaternius UAL, 159 fitted (`OUT/make_anims_pro.log`).
- **lab** = the new player body's own 130 clips (`traversal_lab/traversal/character/clips/`), with the Kimodo
  takes `KM_*`.
- **batch 4** = the same Mixamo catalogue downloaded for the new body (`reports/Mixamo clip list by name.md`,
  rows 86–369): 272 arrived, most not baked yet.

## 1. What exists today, and what that means
| Fact (from the code and the boards) | So the cutscenes... |
|---|---|
| **No cutscene or camera-direction system.** Only the player's, the car's and the bike's cameras. | need a small director built first (section 2). |
| **No faces, no lip sync, no eye look.** Talk is a voice clip, a body gesture and a caption. | are acted with the whole body, staged wide or over a shoulder, and never held on a talking face. |
| The new player body has few acting clips baked (sit, type, phone, doors, car, carry, the fight set). The acting catalogue for it is **batch 4, downloaded and unbaked.** | need a batch-4 bake for the hero: the clips in section 4 marked **H**. |
| Near NPCs on the new bodies show the old figures' acts by pose copy. | can use any mx/ clip on any NPC now. |
| The crowd already has acts that are scenes in themselves: sit, phone, film, duck, beg, wave, chat, argue, fight, give, stare, call, cheer, nod, no. And hooks: place an actor, walk or run them to a point, start a fight between two people, make onlookers stare and film, pull a car over, drive a car to a point, hold a car. | are mostly these hooks, in order, with a camera. |
| **No hug** (a handshake plays), no hands-up (ual/Surprise is held), no real driving clip (hands are placed by IK), no swim stroke (canoe paddling plays), no eating or sleeping in use, no floor sit (kneeling plays), no melee-weapon swing, no throw. | avoid them, cheat them, or order them (section 5). |
| **Birds are sound only. No shark. No boat moves.** | need a bird model with five poses and a fin (section 6). |
| No children's bodies among the new NPCs (the crowd scales adults down). | keep children far from the camera. |

## 2. The director (to build; small)
A cutscene is a list of steps, like the old game's `StoryDirector` list, with seven step kinds:
1. **shot**: put the camera on a named mark; static, slow push, pan, or follow an actor. Over-shoulder marks hang
   off an actor.
2. **place**: put an actor on a mark (the crowd's actor hook), with a body and an outfit.
3. **move**: walk, jog or run an actor to a mark (the crowd hook).
4. **clip**: play a clip on an actor, once or looped, with a blend in.
5. **say**: a voice clip and its caption (English, Turkish under it), with a talk gesture underneath.
6. **prop**: show, hide or attach a thing (a glass, a paper, a stamp, a net, a bird).
7. **world**: a traffic or crowd hook (drive a car to a point, pull one over, start a fight, make onlookers film,
   set the hour, start the rain).
Hold to skip, as in the old intro (*"Hold to skip"* `(old)`). A cutscene always starts and ends in the same
camera the player has, so there is no cut to black between play and scene.

## 3. House style
- **20 to 60 seconds.** Three to six shots. The long ones (the offer, the hearing) are broken by a choice.
- **Something moves in every shot**, and it is not a mouth: a car arrives, a glass breaks, a paper is stamped,
  somebody sits down hard.
- **Wide and over the shoulder.** We have bodies and no faces, so the camera reads posture: Vince's hand on a
  shoulder, Rhodes sitting perfectly still, Finch never lowering the binoculars, Ivan filling a door.
- **Every speaker has a body of their own:**
  - {H}: quick, hands everywhere (mx/Talking_3, Arm_Gesture, Hands_Forward_Gesture), then mx/Drunk_Idle_Variation.
  - Sal: turns right round in his seat (mx/Sitting_talking, sitting_Pointing, Sitting_Thumbs_Up).
  - Reyes: hardly moves (mx/Seated_table_Idle, Acknowledging); takes his glasses off (a new take).
  - Rhodes: still. mx/Standing_W_Briefcase_Idle, Cocky_Head_Turn *(unused)*, and nothing else. The stillness is
    the character.
  - Vince: big and warm (mx/Standing_Greeting, Patting *(unused)*, Counting, Pointing_back_thumb).
  - Finch: mx/Looking (hand shading eyes) with binoculars attached, Telling_A_Secret, Counting, Terrified.
  - Ivan: mx/Fighting_Idle as his normal standing pose, Taunt, Fist_Pump, Shaking_Hands_1.
  - Grace: mx/Talking_At_Watercooler *(unused)*, Hand_Raising *(unused)*, Thankful.
  - Orla: slow, tall, mx/Old_Man_Walk *(unused)* slowed for the long tired walk, Quick_Formal_Bow, Arm_Gesture.
  - Zib: mx/Waving at everything, Excited, Sitting_Clap, and writing (a new take).
  - Goo: no skeleton. A blob with a squash, a stretch and a split.
- **A bird in every frame.** One prop bird on a wire, a post, a sill or a roof in every cutscene, never at the
  centre, its head turned to the hero. Nobody mentions it until W1. It is in the old ink sketches' margins too.
- **Voices** as the old game cast them (five women, five men; never two with the same voice in a scene).

## 4. The clips, by what the scenes need
**H** = the hero needs it, so it must be baked from batch 4 for the new body. *(unused)* = fitted today and not
called by any code: these scenes are what bring it into use.

| Need | Clips we have |
|---|---|
| Stand and talk | mx/Talking, Talking_2, Talking_3, Talking_4, Talking_5, Asking_Question, Telling_A_Secret **H**; mx/Talking_At_Watercooler *(unused)* |
| Small reactions | mx/Agreeing, Acknowledging, No, Sarcastic_Head_Nod, Disappointed, Disappointed_2, Thankful **H**; mx/Thankful_2, Cocky_Head_Turn, Hand_Raising *(unused)* |
| Greeting | mx/Waving, Waving_2, Waving_4, Standing_Greeting, Shaking_Hands_1, Shaking_Hands_2 **H**; mx/Waving_3, Salute, Quick_Formal_Bow, Patting, Kiss *(unused)* |
| Pointing and showing | mx/Pointing, Pointing_Forward, Pointing_back_thumb, Hands_Forward_Gesture, Arm_Gesture, Counting **H** |
| Anger | mx/Angry_Gesture, Insult, Threatening, Yelling, Yelling_Out, Standing_Arguing; mx/Standing_Arguing_2, Angry, Stomping *(unused)* |
| Joy | mx/Cheering, Standing_Cheering, Fist_Pump, Victory, Excited **H**; mx/Rallying *(unused)* |
| Fear and shock | mx/Terrified, Looking; ual/Surprise; mx/Running_Away_Scared, Look_Behind_Run, Run_Look_Back, Stumble_Backwards *(unused)* |
| Sitting | mx/Stand_To_Sit, Sit_To_Stand, Sitting_Idle, Seated_table_Idle, Sitting_talking, sitting_Pointing, Sitting_Thumbs_Up, Sitting_Disapproval, Sitting_Disbelief, Sitting_Yell, Sitting_Clap, Cheering_While_Sitting, Angry_Gesture_sitting; mx/Having_A_Meeting_Male, Having_A_Meeting_Female, Dice_Idle, Cards *(unused)*; lab Stand_To_Sit, Sitting_Idle, Sit_To_Stand |
| On the floor | mx/Kneeling, Kneeling_Pointing, Laying_Idle, Getting_Up, Situp_To_Idle; mx/Sitting_Idle_2 (a real floor sit), Fallen_Idle, Sleeping_Idle, Praying, Praying_2 *(unused)* |
| Desk and paper | mx/Typing, Sit_To_Type, Type_To_Sit, Opening_A_Filing_Cabinet, Using_A_Filing_Cabinet, Closing_A_Lid *(unused)*; lab Typing, Type_To_Sit |
| Phone | mx/Talking_On_Phone, Talking_On_A_Cell_Phone, Talking_Phone_Pacing, Talking_on_phone_arguing, Angry_talking_phone, Texting_While_Standing, Standing_Using_Touchscreen_Tablet; mx/Start_Talking_On_A_Cell_Phone, Pacing_And_Talking_On_A_Phone *(unused)*; lab Male_Talking_On_The_Cell_Phone, Texting_While_Standing |
| Doors | lab Open_Door_Outwards, Opening_Door_Inwards; mx/Opening_locked, Opening_slide_door *(unused)* |
| Giving and taking | ual/Counter_Give, Counter_Show, Interact; mx/Tender_Placement, Bartending |
| Carrying | lab KM_Pick_Box, KM_Put_Box, KM_Pick_Bag, KM_Put_Bag, Walking_With_Shopping_Bag, Jogging_With_Box; mx/Walking_Carry, Box_Idle, Walk_With_Briefcase |
| Carrying a person | mx/Carrying_Turn, Being_Carried_pick_up, Being_Carried_walking, Being_Carried_out_down *(unused)* |
| Drunk, hurt, tired | mx/Drunk_Idle_Variation, Injured_Walking_arm, Injured_walking_leg, Wiping_Sweat, Neck_Stretching; mx/Walking_Drunk, Drunk_Turn, Drunk_Walking_Turn, Injured_Turn_Left *(unused)*; ual/Bandage_Loop, Idle_Tired_Loop |
| Fights | lab Fight_Idle, Fight_Cross, Fight_Hook_Lead, Fight_Hook_Rear, Fight_Combo, Fight_Jab_Elbow and the six Fight_Hit clips; mx/Fistfight_Taunt, Taunt, Punching, Hook, Head_Hit, Big_Hit_To_Head, Hit_To_Body |
| Going down, getting up | mx/Knocked_Out, Knocked_Out_2, Fall_Flat, Falling_Down_on_ass, Shoulder_Hit_And_Fall, Hit_On_The_Back, Shove_Reaction, Shoved_Reaction_With_Spin, Tripping, Stunned, Spat_In_Face, Standing_Up, Standing_Up_2 *(mostly unused)*; mx/Hit_By_Car *(unused)* |
| Caught | mx/Restrain, Kneeling, Hostage_Situation_Idle_Hostage; mx/Hostage_Situation_Idle_Villain, Being_Strangled *(unused)* |
| Guns | mx/Pistol_Idle, Aiming_Gun, Shooting_Gun, Reloading, Walk_With_Rifle; lab Pistol_Idle, Rifle_Standing_Idle, Walking_While_Aiming_Rifle (aim and shot are solved in code) |
| Sneaking and cover | lab Cover_Idle, Crouch_Cover_Idle, Stand_To_Cover, Crouch_Look_Around_Corner, KM_Crouch_Walk; mx/Sneaking_Forward |
| Climbing and falling | everything in the lab's traversal set (Running_Jump_Climb, Jump_To_Braced_Hang, Braced_Hang_To_Crouch, Sprint_To_Wall_Climb, KM_Climb_Up, KM_Beam_Walk, KM_Ledge_Sidle_Left, Vault_1_Hand, Vault_2_Hands, KM_Land_Roll, Hard_Landing, Climbing_Down); mx ladder set *(unused)*: Start_Climbing_Ladder, Climbing_ladder_slow, Climbing_Ladder_fast, Climbing_To_Top_ladder, Climbing_Down_ladder |
| Cars | lab Entering_Car, Exiting_Car; hands on the wheel by IK |
| Medical | mx/Administering_Cpr, Receiving_Cpr; ual/Bandage_Loop, Fixing_Kneeling |
| Work | mx/Bartending, Working_On_Device_crouched; mx/Wheelbarrow_Walk, Push_Stop *(unused)*; ual/Push_Loop, Farm_Watering, Fish_Cast, Fish_Reel *(unused)* |
| Dance and show | mx/Dancing, Dancing_2, Northern_Soul_Dance, Shuffling, Silly_Dancing, Step_Hip_Hop_Dance, Shopping_Cart_Dance, Rapping, Singing, Moonwalk *(all unused)*; ual/Dance_Loop |
| Waiting | mx/Idle_Transition, Looking_Around_idle, Arm_Stretching, Smoking; mx/Swatting_Bugs, Jumping_Rope, Drinking_Fountain, Finding *(unused)* |

That is about ninety clips that are fitted today and never played, brought into use by the scenes below.

## 5. New takes to order
Kept short on purpose (Yasin: be frugal; check the Drive first; one plain sentence, no full stop inside it, no
decimals; Kimodo is weak at anything held in the hands, so every take below is empty-handed, and props are
attached afterwards).

**First, from batch 4, already on the Drive:** bake the **H** clips of section 4 for the new body. No new
downloads.

**Then, Kimodo, 24 takes** (name; the prompt, as one sentence):
| Take | Prompt |
|---|---|
| KM_Hands_Up | a frightened person slowly raises both open hands above the head and stands still |
| KM_Hands_On_Head_Kneel | a person drops to both knees and puts both hands on top of the head |
| KM_Caught_Ankle_Fall | a person climbing a fence is pulled backward and falls onto the ground on the chest |
| KM_Hug | a person steps forward and wraps both arms around someone in a warm hug |
| KM_Lifted_Hug | a small person is lifted off the ground in a bear hug with arms pinned and legs hanging |
| KM_Cant_Move_Bed | a person lying on the back strains to lift the head and shoulders but cannot move the arms |
| KM_Float_Up | a person lying on the back rises stiffly into the air with arms and legs hanging |
| KM_Melt | a standing person sags at the knees and sinks straight down to the floor as if melting |
| KM_Reform | a person lying curled on the floor uncurls and sits up slowly looking at both hands in confusion |
| KM_Stamp_Paper | a seated person lifts one fist and brings it down hard on a desk like stamping a paper |
| KM_Glasses_Off | a seated person takes off glasses with one hand and rubs the eyes with the other |
| KM_Write_Notebook | a small person holds one palm flat like a notebook and writes on it quickly with the other hand |
| KM_Throw_Keys | a person tosses a small object underhand to someone a few steps away |
| KM_Catch_Keys | a person catches a small object with one hand at chest height |
| KM_Glass_Smash | a drunk angry person swings one arm wide and hits a wall then pulls the hand back in pain |
| KM_Hold_Hurt_Hand | a person hunches over holding one wrist tightly against the stomach in pain |
| KM_Sign_Here | a big friendly man leans over a table and taps it three times with one finger |
| KM_Count_Money | a person flicks through a stack of notes with both hands counting quickly |
| KM_Binoculars | a person holds both fists up to the eyes like binoculars and slowly scans the sky |
| KM_Walk_Backwards_Wary | a nervous person walks slowly backward while watching something above |
| KM_Netted | a person is knocked down by a thrown net and struggles on the ground with arms tangled |
| KM_Swim_Crawl | a person swims front crawl with strong arm strokes |
| KM_Pulled_Under | a swimmer treading water is suddenly pulled straight down |
| KM_Touch_Wall | a swimmer stops and reaches out one hand to touch a flat wall in front in disbelief |

Anything with a thing in the hand (the Puddler, a bat, a frying pan, a pool cue) is done the way the lab already
does guns: the prop is placed and the arms are solved to it. A **melee swing** is the one hand-held take worth
trying anyway (*a person swings a bat hard with both hands from the right shoulder*); if it fails like the gun
takes did, Mixamo's own bat and sword swings are the fallback.

## 6. Things that are not people
| Thing | Needs |
|---|---|
| **Bird** (gull, pigeon, crow: one rig, three skins) | perch idle with a blink; head turn to follow a target; hop; take off and land; and the one that matters: **head turns right round, eye goes green, no blink.** |
| **Shark** | a fin that circles and goes under; one lunge from below. Never seen whole. |
| **Orla, Zib** | on the same skeleton as the NPCs, so every clip above works. Zib scaled to one metre twenty with six-finger hands; Orla scaled to two metres ten, all her clips slowed a fifth. |
| **Goo** | a soft body: idle wobble, squash and stretch, split into five, flow under a door, fill a tank. |
| **Puddle** | a person becomes one and comes back: KM_Melt into a flat green mesh that keeps the hat; KM_Reform out of it. |
| **The ship** | hover, a beam, a glass floor showing the baked city far below, water rising off the hull. |

## 7. Animations everywhere (not cutscenes)
The world between scenes is never a still picture. All of this exists already and is switched on wherever it
fits:
- every **stranger** is doing something when you find them: mx/Looking_Around_idle with a map, Yelling_Out,
  Working_On_Device_crouched at a dead car, Kneeling_Pointing by a drain, Texting_While_Standing;
- every **shop** has the cashier's ual/Counter_Idle_Loop, Counter_Show and Counter_Give, and people browsing;
- every **club** has its own loop: mx/Dancing set at Dance Night, ual/Fish_Cast and Fish_Reel on the pier,
  mx/Dice_Idle and Cards at Yusuf's table, Jumping_Rope and Push_Up_To_Idle at Sweat Circuit, Singing and
  Rapping for the busker;
- every **race** has a start line: a flag girl (mx/Rallying), a crowd (Cheering, Fist_Pump), drivers leaning on
  doors (Idle_Transition, Smoking);
- **busted:** mx/Restrain on you, then you wake on a bench (Sitting_Idle to Sit_To_Stand);
- **wasted:** mx/Knocked_Out; then your bed (Sleeping_Idle, Situp_To_Idle) or the hospital (Laying_Idle);
- **puddled** people: KM_Melt, twenty seconds, KM_Reform, then mx/Looking_Around_idle and Disappointed;
- the crowd's own life goes on behind everything: phone calls, quarrels, people filming you.

## 8. The cutscenes
One row each. Clips are the main ones; talk gestures (section 4, first row) are under every spoken line.
**New** = a take from section 5.

### Prologue
| Cut | Who | Clips | New |
|---|---|---|---|
| P2-1 Over the Side | twenty runners, a gull | mx/Climbing_Down_ladder, Hard_Landing, Crouching_Idle, Looking, Turn_To_Running | bird |
| P2-2 They Caught Us | you, guards, the line | lab Sprint_To_Wall_Climb, Jump_To_Braced_Hang; mx/Fall_Flat, Restrain, Kneeling | KM_Caught_Ankle_Fall, KM_Hands_On_Head_Kneel |
| P3-1 Welcome to the Camp | guard, the line | mx/Standing_W_Briefcase_Idle (clipboard), Pointing, Idle_Transition | |
| P3-2 Waiting | the line, Grace | mx/Idle_Transition, Looking_Around_idle, Hand_Raising, Talking_At_Watercooler | |
| P3-3 Your Shoes | Ivan, you, a ring of people | mx/Insult, Pointing, Threatening, Shove_Reaction; crowd A_STARE | |
| P3-4 We Are Friends? | Ivan, you, guard | mx/Falling_Down_on_ass, Standing_Up, Shaking_Hands_1, Yelling | |
| P3-5 Goodbye | Grace, you, guard | mx/Thankful, Waving, Pointing_back_thumb | |
| P4-1 Another One | officer, you | mx/Seated_table_Idle, Having_A_Meeting_Male, Asking_Question | |
| P4-2 Status | officer | mx/Closing_A_Lid | KM_Stamp_Paper |
| P5-1 Thirty Days | Reyes, you | mx/Hands_Forward_Gesture (phone, paper), Pointing, Quick_Formal_Bow, Acknowledging | |
| P5-2 Too Fast | Sal, you | lab Entering_Car; mx/Sitting_talking, sitting_Pointing, Sitting_Disbelief, Sitting_Thumbs_Up | |
| P5-3 Good People | the other driver, Sal | traffic hook (a car hits the taxi); lab Exiting_Car; mx/Yelling, Angry_Gesture | KM_Hands_Up |
| P5-4 Not You | Sal | traffic hook (drive to you); mx/sitting_Pointing | |
| P5-5 Next Time You Pay | Sal, you | lab Exiting_Car; mx/Sitting_talking, Waving_2 | |

### Chapter 1
| Cut | Who | Clips | New |
|---|---|---|---|
| 1.1-1 The Door | {H}, you | lab Opening_Door_Inwards; mx/Standing_Greeting, Shaking_Hands_2, Arm_Gesture | |
| 1.1-2 Enjoy Your Meal | courier, thief on a bike, {H} | ual/Counter_Give; traffic hook (a cyclist passes); mx/Looking, Yelling_Out | |
| 1.1-3 Delicious | {H}, you | mx/Seated_table_Idle, Sitting_talking, Sit_To_Stand; ual/Consume | |
| 1.2-1 Rise and Shine | {H}, you | mx/Situp_To_Idle, Standing_Up; mx/Talking_3, Counting (the pen), Pointing_Forward | KM_Write_Notebook |
| 1.2-2 Welcome Aboard | Mr. Dunn | mx/Having_A_Meeting_Male, Seated_table_Idle | |
| W1-1 Don't Look Up | Finch, three pigeons | mx/Looking | KM_Binoculars, KM_Walk_Backwards_Wary, bird |
| W1-2 The Van | Finch | mx/Telling_A_Secret, Counting, Pointing | |
| W1-3 Now You Know | Finch | mx/Using_A_Filing_Cabinet (pinning), Pointing, Looking | |
| 1.3-1 Over Here | {H} | mx/Sitting_Idle, Waving_3 (seated: the arm only) | |
| 1.3-2 Nice to Meet You | {F}, {H}, you | mx/Sitting_talking, Sitting_Thumbs_Up, Sitting_Clap, Sit_To_Stand | |
| 1.3-3 Race You | {F} | mx/Pointing, Turn_To_Running; bike mount (IK) | |
| 1.3-4 The Buoys | {F}, a gull | mx/Pointing_Forward, Looking, No | bird |
| 1.4-1 Tell Me Everything | {H} | mx/Sitting_talking, Sitting_Disbelief, Cheering_While_Sitting | |
| 1.4-2 Not in That | {H} | mx/Sarcastic_Head_Nod, Arm_Gesture | KM_Throw_Keys (a shirt) |
| 1.4-3 My Uniform | three sailors, bartender | mx/Shoulder_Hit_And_Fall (onto your table), Looking, Standing_Up_2, Threatening, Bartending | |
| 1.4-4 Back Door | {H} | lab Open_Door_Outwards; mx/Yelling_Out, Pointing | |
| 1.4-5 Good Night | {H}, you | mx/Neck_Stretching, Waving | |
| 1.5-1 Beep | you, {H} | mx/Sleeping_Idle, Situp_To_Idle; mx/Talking_2 | |
| 1.5-2 The Rules | Mr. Dunn, Sam | mx/Counting (four rules on four fingers), Standing_Greeting, Pointing | |
| 1.5-3 Hey! | Sam, a thief | mx/Yelling_Out, Pointing_Forward, Running_Away_Scared | |
| 1.5-4 See You Tomorrow | Mr. Dunn, Sam | ual/Counter_Give (the pay), mx/Waving_2 | |
| 1.6-1 Green | you, three pigeons | mx/Sleeping_Idle | KM_Cant_Move_Bed, KM_Float_Up, bird |
| 1.6-2 An Abduction | Orla, Zib | mx/Old_Man_Walk, Arm_Gesture, Waving, Excited | |
| 1.6-3 The File | Orla, Zib | mx/Pointing, Sitting_Clap (standing: the hands), No | |
| 1.6-4 The Deal | Orla | mx/Hands_Forward_Gesture, Opening_slide_door | |
| 1.6-5 Rebel | Orla, you | mx/Aiming_Gun, Shooting_Gun | KM_Melt, KM_Reform |
| 1.6-6 Was It a Dream? | you, Goo | mx/Sleeping_Idle, Situp_To_Idle, Looking_Around_idle | Goo |

### Chapter 2
| Cut | Who | Clips | New |
|---|---|---|---|
| 2.1-1 Hello, Student | Goo, you | mx/Situp_To_Idle, Stumble_Backwards | Goo |
| 2.1-2 Catch Me | Goo, a neighbour | ual/Farm_Watering; mx/Looking | Goo split |
| 2.1-3 Where Are You?! | you | mx/Sitting_Idle_2 (on the kerb), Talking_On_A_Cell_Phone, Disappointed | |
| 2.1-4 A Present | Goo, you | mx/Stand_To_Sit, Finding (picking it up) | |
| 2.1-5 Certificate | Goo, {H} | lab Opening_Door_Inwards; mx/Talking_3, Sarcastic_Head_Nod | Goo flow |
| 2.2-1 You're Fired | Mr. Dunn, you, Sam | mx/Stand_To_Sit, Having_A_Meeting_Male, Sitting_Disapproval, Sit_To_Stand; ual/Counter_Give | |
| 2.2-2 Come Now | you | mx/Disappointed_2, Start_Talking_On_A_Cell_Phone, Turn_To_Running | |
| 2.2-3 You're Hired | Ms. Bell, {F} | mx/Asking_Question, Agreeing, Shaking_Hands_1, Fist_Pump | |
| W2-1 How Many | you | mx/Talking_On_Phone, Looking_Around_idle | bird |
| W2-2 Thirty Seconds | you, a pigeon | mx/Idle_Transition | bird (lands) |
| 2.3-1 Host Weekly Report | you | lab Opening_Door_Inwards; mx/Looking_Around_idle, Opening_A_Filing_Cabinet | |
| 2.3-2 After Two Days? | {H} | mx/Drunk_Idle_Variation, Arm_Gesture, Standing_Arguing | |
| 2.3-3 The Glass | {H}, you | mx/Drunk_Turn, Yelling | KM_Glass_Smash, KM_Hold_Hurt_Hand |
| 2.4-1 Here Are the Keys | {H}, you | mx/Injured_Walking_arm | KM_Hold_Hurt_Hand, KM_Throw_Keys, KM_Catch_Keys |
| 2.4-2 What Happened? | receptionist, {H}, you | mx/Seated_table_Idle, Typing, Stand_To_Sit, Sitting_Idle | |
| 2.5-1 She Should | doctor, {H} | mx/Counting (six orders), Pointing; ual/Bandage_Loop | KM_Write_Notebook |
| 2.5-2 What Should I Do? | {H}, you | mx/Sitting_talking, Sitting_Disbelief, Sitting_Disapproval, Thankful | |
| 2.5-3 Not a Laser | Orla, Zib | mx/Hands_Forward_Gesture, Quick_Formal_Bow | KM_Melt, KM_Reform (Zib mimes them) |
| 2.6-1 The Number | the waiting room, Lina, Rhodes | mx/Sitting_Idle, Sitting_Thumbs_Up (Lina), Seated_table_Idle (Rhodes, still) | |
| 2.6-2 Keep an Eye Out | Reyes, Rhodes | mx/Standing_W_Briefcase_Idle, Cocky_Head_Turn, Hands_Forward_Gesture (the card) | KM_Stamp_Paper, KM_Glasses_Off |
| 2.7-1 Just a Word | four men in white | traffic hook (two vans block); lab Exiting_Car; mx/Walk_With_Rifle, Hands_Forward_Gesture | |
| 2.7-2 No Hard Feelings | eight men in white | mx/Sitting_Idle_2, Looking_Around_idle, Disappointed | KM_Reform |

### Chapter 3
| Cut | Who | Clips | New |
|---|---|---|---|
| 3.1-1 One Day | Orla, Zib | mx/Counting (the list), Excited | |
| 3.1-2 Tourist | Zib, you | mx/Looking_Around_idle, Waving | KM_Float_Up (reversed: coming down), KM_Write_Notebook |
| 3.1-3 The Sea | Zib, six gulls | mx/Walking, Stop_Walking, Looking | bird |
| 3.1-4 Earth Is Very Good | Zib, Orla | mx/Waving_2 | KM_Float_Up, KM_Reform |
| 3.2-1 No Licence? | Sal (voice) | mx/Talking_On_Phone | |
| 3.2-2 Island Cab | the young driver, Sal | mx/Insult, Cocky_Head_Turn, Taunt; Sal: Disappointed | KM_Throw_Keys, KM_Catch_Keys |
| 3.2-3 This One Is on Me | Sal, you, a sailor | lab Entering_Car; ual/Counter_Give; mx/Fist_Pump | bird |
| 3.3-1 Friend? | Ivan, you | mx/Fighting_Idle, Standing_Greeting, Pointing | KM_Lifted_Hug |
| 3.3-2 Up | Ivan, you | mx/Kneeling_Pointing (the clamp), Praying (crossing himself: the first second) | |
| 3.3-3 Friends | Ivan | mx/Shaking_Hands_2, Pointing, Counting | |
| 3.4-1 Bring a Friend | Grace, Yusuf | mx/Talking_At_Watercooler, Hand_Raising, Sitting_Idle (asleep: head forward) | |
| 3.4-2 Insurance | two of Vince's men, Lina | mx/Sitting_Idle (on a machine), Counting, Threatening, Terrified | KM_Count_Money |
| 3.4-3 Now You Teach | the class | mx/Sitting_Clap, Cheering_While_Sitting, Sitting_Thumbs_Up, Rallying | |
| W3-1 Where They Sleep | Finch | mx/Pointing, Telling_A_Secret, Disappointed | |
| W3-2 They Don't Sleep | a thousand birds | ual/PickUp_Kneeling | bird (the turn) |
| W3-3 They Are Ours | Finch, Orla, Zib | mx/Stand_To_Sit, Sitting_Disbelief; Zib: Waving with a bird in hand | bird |
| 3.5-1 Can You Cook? | {H} | mx/Seated_table_Idle, Asking_Question | KM_Hold_Hurt_Hand |
| 3.5-2 Uncle Vince | Vince, two men, {H} | lab Opening_Door_Inwards; mx/Standing_Greeting, Patting, Pointing_back_thumb | KM_Hug (Vince on {H}), KM_Count_Money, KM_Sign_Here |
| 3.6-1 A Little Driving | Vince, Dale | mx/Using_A_Filing_Cabinet (the safe dial), Seated_table_Idle | KM_Throw_Keys |
| 3.6-2 She's Not Here | Dale, Lina, you | lab Exiting_Car; mx/Threatening, Cocky_Head_Turn, Terrified | |
| 3.6-3 Clause Four | Vince (voice) | mx/Talking_On_A_Cell_Phone | |
| 3.7-1 A Delivery | Dale, one more, you | mx/Seated_table_Idle (at the wheel, IK), lab Exiting_Car | |
| 3.7-2 Your Share | Vince | mx/Patting, Sarcastic_Head_Nod | KM_Count_Money |
| 3.8-1 A Big Hat | Orla, Zib | mx/Arm_Gesture, Pointing | KM_Write_Notebook |
| 3.8-2 Look! | the crowd | crowd A_STARE, A_FILM, mx/Looking, Cheering | |
| 3.8-3 No Papers | Orla, Zib, you | mx/Sitting_Idle, Sitting_talking, Sitting_Disbelief | KM_Write_Notebook |
| 3.9-1 Double or Nothing | Vince; then the crowd at Big Al's | mx/Hands_Forward_Gesture, Shaking_Hands_1; Rallying, Dancing_2, Shuffling, Smoking | |
| 3.9-2 Clause Nine | Vince, Ivan, the crowd | mx/Victory, Fist_Pump, Cheering; Vince: Sitting_Clap (standing, slow), Patting; Ivan: Fighting_Idle | |
| 3.10-1 All Paper | Ivan, Sal | mx/Kneeling_Pointing (drawing in the dirt), Sitting_talking | |
| 3.10-2 Sign Here | Vince | mx/Walk_With_Rifle, Aiming_Gun, Stomping (small) | |
| 3.10-3 Slowly, Sir | lawyer, Vince, an officer, {H} | mx/Opening_A_Filing_Cabinet, Sitting_Disbelief; Vince: Standing_Arguing_2, Arm_Gesture; officer: Hand_Raising | |
| 3.11-1 A Judge | Reyes | mx/Seated_table_Idle, Hands_Forward_Gesture (the card) | KM_Stamp_Paper |
| 3.11-2 The Offer | Rhodes, you, seven gulls | mx/Seated_table_Idle, Cards (the photographs, dealt), Having_A_Meeting_Male; then nothing: he sits still | bird |

### Chapter 4 and the epilogue
| Cut | Who | Clips | New |
|---|---|---|---|
| 4.1-1 It Must Sleep | Orla, Zib | mx/Stumble_Backwards (the floor leans), Old_Man_Walk | |
| 4.1-2 Splash | you, Zib, Orla | mx/Laying_Idle (Zib floating), Walking (Orla, under water), Wiping_Sweat | KM_Swim_Crawl, bird |
| 4.1-3 New Flatmates | {H}, Orla, Zib | mx/Idle_Transition (a very long one), Standing_Greeting, Waving, Stunned | |
| W4-1 Thirty Years | Finch | mx/Using_A_Filing_Cabinet (taking pictures down), Disappointed_2 | |
| W4-2 Members | Finch, Zib, Orla | mx/Falling_Down_on_ass (slow), Sitting_Idle_2, Waving; Quick_Formal_Bow | bird (waves) |
| 4.2-1 The Drains | two men in overalls | mx/Walk_With_Briefcase, Walking_Carry, Standing_Greeting | |
| 4.2-2 The Plan | the class, Grace, Zib | mx/Hand_Raising, Sitting_talking, sitting_Pointing, Sitting_Thumbs_Up, Talking_At_Watercooler; Ivan: Sit_To_Stand | KM_Write_Notebook |
| 4.2-3 Class Is Not Over | the expert, Goo | mx/Seated_table_Idle, Sitting_Disbelief, Sit_To_Stand, Thankful_2 | Goo fills a tank |
| 4.2-4 Tomorrow: School | Goo | | Goo flow |
| 4.3-1 Tonight | Finch (voice), {H} | mx/Looking, Ascending_Stairs | KM_Throw_Keys (to herself: a jingle) |
| 4.3-2 It Knows Your Voice | everybody | traffic hooks (four vehicles arrive); lab Exiting_Car; Ivan: Fighting_Idle; {H}: Taunt; Finch: Looking | KM_Binoculars |
| 4.3-3 Up | Orla, you | mx/Disappointed, Pointing, Stand_To_Sit | |
| 4.3-4 You Speak Too Fast | Rhodes (voice), Orla, you | mx/Sitting_talking, Seated_table_Idle | |
| 4.4-1 A Word on a Paper | Orla, Zib, you | mx/Pointing, Asking_Question, Agreeing; Zib: Excited | |
| 4.4-2 Good Human | Orla, you | mx/Quick_Formal_Bow, Waving_4 | KM_Float_Up (reversed), bird |
| 4.5-1 Slowly, Please | judge, Rhodes, Reyes, the benches | mx/Seated_table_Idle, Hand_Raising; Rhodes: Talking_4, then Disappointed; benches: Sitting_Clap, Cheering_While_Sitting | |
| 4.5-2 The Last Report | {H}, Sal, Grace, Ivan, Finch, Mr. Dunn | mx/Sit_To_Stand, Thankful, Sitting_Thumbs_Up; Ivan: Standing_Up_2 | |
| 4.5-3 You Made It | judge, Reyes, Sal, every bird | mx/Shaking_Hands_1, Salute (Reyes: his only one), lab Entering_Car | KM_Stamp_Paper, bird (rows of them) |
| E1-1 Pizza or Tacos | {H}, Goo | mx/Bartending (at the cooker), Talking_3, Asking_Question | Goo |

### The sea and the birds
| Cut | Clips | New |
|---|---|---|
| Shark | | KM_Swim_Crawl, KM_Pulled_Under, the fin |
| The edge, visit 1 | lab Jump_To_Braced_Hang (the ladder) | KM_Touch_Wall, bird |
| The edge, visit 2 | mx/Sneaking_Forward, lab Crouch_Look_Around_Corner | |
| The edge, visit 3 | Zib: mx/Typing, Type_To_Sit, Sitting_Disbelief, Sitting_talking | |
| A bird is hit | | bird (the turn) |
| Six horror games | mx/Old_Man_Walk and Walking_Backwards for the bird-headed line; mx/Sleeping_Idle | KM_Cant_Move_Bed |
