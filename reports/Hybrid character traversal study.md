# Build the walker one tested layer at a time

The safest way to get Rockstar-style movement in Godot 4.7 with Jolt is to build four separate layers in a fixed order and prove each on a measured test course before starting the next: a physics body that owns position, animation clips that own how the body looks, procedural corrections (leg and arm IK, head look, lean) that fit the clips to the world, and a ragdoll that takes over only on impacts. The physics body has to be your own code, because Godot does not use Jolt's ready-made character controller: `CharacterBody3D.move_and_slide` is Godot's own routine, it has no stair stepping, and under Jolt it deliberately throws away some floor and wall contacts ([Godot source](https://raw.githubusercontent.com/godotengine/godot/master/scene/3d/physics/character_body_3d.cpp), [Jolt module source](https://raw.githubusercontent.com/godotengine/godot/master/modules/jolt_physics/spaces/jolt_query_collectors.h)). Mixamo clips have no root bone and no data about the obstacle they fit, so every clip must pass through a pipeline that adds a root bone and then be measured by you ([inspected Mixamo file](https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/fbx/mixamo.fbx)). Rockstar has never published how its capsule, climb detection or clip fitting work; what is public is the list of clips, which shows climbs authored at fixed heights (20, 80, 140, 180, 220, 295) with stand, walk and run entries ([GTA V clip name dump](https://raw.githubusercontent.com/DurtyFree/gta-v-data-dumps/master/animDictsCompact.json)). Human measurements give matching bands: the cheapest step to climb is about a quarter of leg length, coaches vault obstacles from knee to shoulder height and climb anything higher, and standing grip reach is about 1.2 times body height ([Warren](https://digitalcommons.lib.uconn.edu/dissertations/AAI8309263), [MovNat](https://movnat.com/definitive-guide-to-vaulting/), [US Army body survey](https://multisite.eos.ncsu.edu/www-ergocenter-ncsu-edu/wp-content/uploads/sites/18/2016/06/Anthropometric-Detailed-Data-Tables.pdf)). Euphoria-style self-balancing characters are out of reach for now: Godot exposes none of Jolt's ragdoll motor tools, and the people who built Euphoria say it took years. The build order and its pass or fail tests are in the last third of this report and matter as much as the design.

**Update, 25 Nov 2026.** Part 3 also now covers the check of the missing clips against the Mixamo catalogue and seven clips generated with Kimodo for the gaps Mixamo cannot fill. Part 3 is new: all 408 Mixamo clips in the shared folder were measured directly, which settles most of the Mixamo unknowns named below and shows which clips fit which height band and which are missing.

**How to read this report.** A sentence followed by a link is a fact read from that page by the researchers. "Inferred" marks reasoning or arithmetic on top of sourced facts, by the note-takers or by me. "Unverified" marks something that could not be confirmed. Everything in the recommendation sections is my design advice built on those facts; none of it has been run in Godot, and the acceptance numbers I propose are targets, not sourced values. Nothing here comes from the existing game.

## Part 1. What was learned

### 1. A walking body moves very little, and joints stop where bones say

**Gait.** In walking each foot is on the ground about 60 % of the cycle and in the air 40 %, with two short periods (10 to 12 % each) when both feet are down ([Pirker and Katzenschlager](https://pmc.ncbi.nlm.nih.gov/articles/PMC5318488/)). As speed rises the foot-down share falls to **62 % walking, 31 % running, 22 % sprinting**, and the both-feet-down period is replaced by a flight phase ([Mann and Hagy](https://europepmc.org/article/MED/7416353)). People switch from walk to run at about **2.0 m/s** ([Hreljac](https://europepmc.org/article/MED/8231761)).

Comfortable adult walking is about **1.27 to 1.46 m/s**, and the fastest walk 1.75 to 2.53 m/s depending on age and sex ([Bohannon](https://europepmc.org/article/MED/9143432)). Young adults take 115 to 120 steps a minute with a 1.5 to 1.7 m stride (two steps) ([Pirker and Katzenschlager](https://pmc.ncbi.nlm.nih.gov/articles/PMC5318488/)). Runners on a treadmill at 2.5, 3.5 and 4.5 m/s used strides of 1.86, 2.46 and 2.96 m ([Fukuchi](https://pmc.ncbi.nlm.nih.gov/articles/PMC5426356/)). Top speeds of 33 people of mixed ability ranged from 6.2 to 11.1 m/s ([Weyand](https://europepmc.org/article/MED/11053354)); elite sprinters reach about 10.6 m/s with 2.25 m steps and only 0.09 s of ground contact ([Murphy](https://pmc.ncbi.nlm.nih.gov/articles/PMC8580521)).

The body bobs and sways less than most game characters do. The centre of mass rises and falls **2.7 to 4.8 cm** in walking, more at higher speed, while side-to-side sway shrinks from 7.0 to 3.9 cm as speed rises ([Orendurff](https://europepmc.org/article/MED/15685471)). In running the bob is 8 to 9.5 cm ([Fadillioglu](https://pmc.ncbi.nlm.nih.gov/articles/PMC9687194)). The pelvis moves only a few degrees at normal walking speed: about 3 degrees of tilt, 8.5 of side drop and 12 of rotation in total range ([Buganè](https://pmc.ncbi.nlm.nih.gov/articles/PMC4216872/)). Each arm swings with the opposite leg; holding the arms still costs 12 % more energy and swinging them with the same-side leg 26 % more ([Collins](https://pmc.ncbi.nlm.nih.gov/articles/PMC2817299/)). Arms stay mostly straight in walking and bent in running ([Yegian](https://europepmc.org/article/MED/31289110)).

**Joint curves in motion.** In walking the hip goes from 25 degrees of flexion to 10 of extension; the knee bends about 20 degrees as weight lands, straightens, is already 40 degrees bent at toe-off and peaks at 60 degrees in swing; the ankle goes from 10 degrees up to 20 degrees down ([Brunnekreef](https://pmc.ncbi.nlm.nih.gov/articles/PMC555760/)). The big toe must bend up at least 35 to 40 degrees at push-off ([QUT podiatry](https://podiatry-anatomy-app.qut.edu.au/content/joints/1st-mtp-joint-rom.html)). Running roughly doubles swing-knee bend (94 to 119 degrees) and raises hip flexion from 44 to 61 degrees between 2.5 and 4.5 m/s, while the ankle barely changes ([Fukuchi](https://pmc.ncbi.nlm.nih.gov/articles/PMC5426356/)). Inferred from these: a stance knee that stays locked, or a swing knee well short of 60 degrees, reads as stiff, and a rigid foot at push-off is wrong.

**Joint ranges.** A US government study of more than 600 people gives measured averages for ages 20 to 44 ([CDC](https://archive.cdc.gov/www_cdc_gov/ncbddd/jointROM/index.html)); other ranges come from a clinical chart and anatomy references. Sources disagree in places (hip flexion is 100 degrees on one chart, 130 to 134 measured, 140 in an atlas), so the table in Part 2 uses the measured values where they exist. Two facts matter most for IK. First, elbows and knees barely go past straight: **elbow 0.8 to 4.7 degrees, knee 1.0 to 1.6 degrees** on average ([CDC](https://archive.cdc.gov/www_cdc_gov/ncbddd/jointROM/index.html)). Second, the spine shares its movement unevenly: the neck turns 85 degrees each way, the mid-back 47, the lower back only 15, while the lower back does most of the forward bending (65 degrees) ([Anatomy Standard](https://anatomystandard.com/biomechanics/spine/rom-of-spine.html)). Raising an arm is shared between the shoulder joint and the shoulder blade at roughly 2 to 1, so the blade rotates about 40 degrees by the time the arm is at 120 ([Ludewig](https://pmc.ncbi.nlm.nih.gov/articles/PMC2657311/)). Forearm twist happens in the forearm, not the wrist ([Wikipedia: Wrist](https://en.wikipedia.org/wiki/Wrist)). Fingers curl about 100 degrees at the middle knuckle and 80 at the end knuckle ([Wikipedia: Interphalangeal joints](https://en.wikipedia.org/wiki/Interphalangeal_joints_of_the_hand)), and everyday grips use about 61, 60 and 39 degrees at the three finger joints ([Hume](https://europepmc.org/article/MED/2324451)).

**Turning, starting, stopping.** People turn head first. On curved paths the eyes lead the pelvis by about 0.56 s and the head by 0.26 s, with the head turned about 15 degrees into the turn ([Authié](https://www.frontiersin.org/journals/human-neuroscience/articles/10.3389/fnhum.2015.00312/full)). They also slow down: on a 1 m radius circle people chose 0.96 m/s against 1.61 m/s in a straight line ([Orendurff](https://europepmc.org/article/MED/16311202)), and lean into a 90 degree corner by 4.4, 6.8 and 12.7 degrees at slow, normal and fast walking speed ([Fino](https://pmc.ncbi.nlm.nih.gov/articles/PMC4274227)). Turning 180 degrees on the spot takes about 3 to 4 steps, with the head, chest, pelvis and feet starting in that order and the head peaking at 137 to 272 degrees a second ([Khobkhun](https://pmc.ncbi.nlm.nih.gov/articles/PMC8074235/)). A walk reaches about 90 % of its speed on the first step and steady speed in about three ([Anand](https://pmc.ncbi.nlm.nih.gov/articles/PMC5378148)). A walk stops in under two steps, with the front leg stiffened and the rear foot left planted ([Hase and Stein](https://europepmc.org/article/MED/9658047)); stopping from a flat-out run takes about **5 steps and 2.9 m**, with the body leaning back ([Cesar and Sigward](https://pmc.ncbi.nlm.nih.gov/articles/PMC4570872)).

**Balance and proportions.** The standing centre of mass sits at about 55 % of body height ([University of Oklahoma notes](https://ouhsc.edu/bserdac/dthompso/web/namics/mass.htm)). Quiet standing is never still: the pressure point under the feet drifts slowly, with a median sway frequency of about 0.33 Hz, and changes direction about every 0.2 s ([Yamamoto](https://pmc.ncbi.nlm.nih.gov/articles/PMC4393163/)). For a median US Army man 1.755 m tall, the eyes are at 1.64 m, shoulder 1.44 m, elbow 1.08 m, hip joint 0.90 m, and standing grip reach is 2.14 m, which is about 1.22 times height (the ratios are my arithmetic on the table) ([NC State tables](https://ergocenter.ncsu.edu/wp-content/uploads/sites/358/2026/02/01-Anthropometry-Summary-Tables.pdf)).

### 2. The city sorts itself into a few height bands, and people have a rule for each

**Real dimensions.** Building codes and manufacturers put most of a city into a handful of heights.

| Thing | Size | Source |
|---|---|---|
| Kerb above road | 0.10 to 0.20 m | [Wikipedia: Curb](https://en.wikipedia.org/wiki/Curb) |
| Stair riser | 0.10 to 0.18 m (US accessible), 0.15 to 0.22 m (UK homes), up to 0.24 m (US workplace) | [ADA ch.5](https://www.access-board.gov/ada/chapter/ch05/), [Designing Buildings](https://www.designingbuildings.co.uk/wiki/Stair_design), [OSHA 1910.25](https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.25) |
| Stair tread | 0.28 m minimum (US accessible) | [ADA ch.5](https://www.access-board.gov/ada/chapter/ch05/) |
| Bench seat | 0.43 to 0.485 m | [ADA ch.9](https://www.access-board.gov/ada/chapter/ch09/) |
| Jersey barrier | 0.81 m (tall version 1.07 m) | [Wikipedia: Jersey barrier](https://en.wikipedia.org/wiki/Jersey_barrier) |
| Tables and counters | 0.71 to 0.965 m | [ADA ch.9](https://www.access-board.gov/ada/chapter/ch09/) |
| Handrail | 0.865 to 0.965 m | [ADA ch.5](https://www.access-board.gov/ada/chapter/ch05/) |
| Guard rail | 1.07 m | [OSHA 1910.29](https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.29) |
| Chain-link fence | 0.91 to 2.4 m in 0.3 m steps | [Wikipedia: Chain-link fencing](https://en.wikipedia.org/wiki/Chain-link_fencing) |
| Garden wall or fence (England) | up to 1 m by a road, 2 m elsewhere | [Planning Portal](https://www.planningportal.co.uk/permission/common-projects/fences-gates-and-garden-walls/planning-permission) |
| Door opening and headroom | 0.815 m wide, 2.03 m high | [ADA ch.4](https://www.access-board.gov/ada/chapter/ch04/), [ADA ch.3](https://www.access-board.gov/ada/chapter/ch03/) |
| Car bonnet front edge | low up to 0.76 m, medium 0.76 to 1.02 m, tall above 1.02 m | [IIHS](https://www.iihs.org/news/detail/vehicles-with-higher-more-vertical-front-ends-pose-greater-risk-to-pedestrians) |
| Car roof | sedan 1.445 m, compact SUV 1.66 to 1.705 m | [Camry](https://en.wikipedia.org/wiki/Toyota_Camry_(XV70)), [RAV4](https://en.wikipedia.org/wiki/Toyota_RAV4_(XA50)) |

Accessible walking surfaces stop at a 1 in 20 slope and ramps at 1 in 12 ([ADA ch.4](https://www.access-board.gov/ada/chapter/ch04/)); the steepest real streets reach about 35 %, which is 19 degrees ([Wikipedia: Baldwin Street](https://en.wikipedia.org/wiki/Baldwin_Street)).

**Steps, kerbs and stairs.** People judge a step climbable without hands up to about **0.88 of leg length**, but the cheapest riser to climb is **0.26 of leg length**, about 0.22 m for a 0.85 m leg ([Warren](https://digitalcommons.lib.uconn.edu/dissertations/AAI8309263), [leg length sample](https://www.frontiersin.org/article/10.3389/fspor.2020.00063/full)). Older adults manage only 0.62 to 0.73 ([affordance abstracts](https://ouhsc.edu/bserdac/dthompso/web/mtrlrng/affabst.htm)). Stairs are climbed at about half a second per step: 0.51 s up and 0.47 s down ([Strathprints](https://strathprints.strath.ac.uk/id/eprint/14400)). Going up and going down are different movements, not one played backwards: peak hip flexion is 62 degrees going up but only 21 going down, while the ankle bends 31 degrees going down against 18.5 going up ([stair study](https://pmc.ncbi.nlm.nih.gov/articles/PMC4658237)). Stepping off a 14.6 cm kerb, people plant the last foot about 14 cm back from the edge, and the step is planned from what they saw two steps earlier ([kerb study](https://pmc.ncbi.nlm.nih.gov/articles/PMC3078928)). Over a 12 to 17 cm obstacle the trailing foot is planted 18 to 26 cm before it, toes clear it by 11 to 19 cm, and speed drops from 1.23 to about 1.1 m/s ([obstacle study](https://pmc.ncbi.nlm.nih.gov/articles/PMC12922988)). People step across a gap up to about **0.94 of leg length** and jump beyond that ([Harris and Wilmut](https://radar.brookes.ac.uk/radar/file/baf468a7-4a8a-40d1-9abb-b65cb06ab955/1/To%20step%20or%20to%20spring%20-%202020%20-%20Harris%20Wilmut.pdf)).

**Slopes.** Uphill the trunk tilts forward and the leg joints are more bent at foot contact; downhill the trunk tilts back ([slope study](https://pmc.ncbi.nlm.nih.gov/articles/PMC6842866)). The grip a walker needs roughly doubles between level ground (0.2) and going down a 20 degree ramp (0.45), and on metal walkways slips began at 10 degrees, with three quarters of all slips at 20 degrees on contaminated surfaces ([friction study](https://pmc.ncbi.nlm.nih.gov/articles/PMC4714842)).

**Crouching.** Walking under a ceiling at 93 % of standing height is still done at 1.15 m/s ([crouch study](https://pmc.ncbi.nlm.nih.gov/articles/PMC9597406)); walking with knees held at 45 degrees halves speed ([Korea Science](https://koreascience.or.kr/article/JAKO200416549674196.page)). Kneeling needs about 140 degrees of knee bend ([kneeling study](https://pmc.ncbi.nlm.nih.gov/articles/PMC3468826)). People duck only when a barrier is at or below the top of the head ([ducking study](https://pmc.ncbi.nlm.nih.gov/articles/PMC3482125)).

**Vaulting.** Coaches say most vaults suit obstacles between knee and hip height, shoulder height is the upper limit, and "anything higher should be climbed" ([MovNat](https://movnat.com/definitive-guide-to-vaulting/)). A police test requires vaulting a 0.86 m obstacle ([University of Arizona PD guide](https://www.uapd.arizona.edu/sites/default/files/2024-08/UAPD%20Recruit%20Study%20Guide%20.pdf)). Each vault has a fixed order of contacts. The step vault is one hand down, outside foot on top, inside leg swung through the gap, hand off. The speed vault is one hand down, take-off from one leg, legs kicked sideways over with no foot touching, landing in stride. The two-handed "kong" passes tucked legs between the arms ([Breaking Muscle](https://breakingmuscle.com/get-over-it-how-to-do-3-beginner-parkour-vaults/), [Wikipedia: Vault](https://en.wikipedia.org/wiki/Vault_(parkour))). Vaulting suits moderate to fast movement; at slow speed stepping or climbing over is more efficient ([MovNat](https://movnat.com/definitive-guide-to-vaulting/)).

**Climbing up.** From a hang with both hands on top and feet staggered on the wall, the climb-up is one pull while driving the upper knee into the wall, a turn of the hands from pulling to pressing as the chest clears the edge, then a press to bring the feet up; the beginner version puts elbows and then a knee on top ([Breaking Muscle climb-up](https://breakingmuscle.com/get-up-that-wall-mastering-the-parkour-climb-up/)). The police test uses a 1.83 m solid wall, taken with both hands and the forward foot hitting the wall together ([University of Arizona PD guide](https://www.uapd.arizona.edu/sites/default/files/2024-08/UAPD%20Recruit%20Study%20Guide%20.pdf)). A running wall-run puts a foot on the wall at thigh to waist height as a second jump, and 2.74 to 3.05 m walls are the hard end of that range ([Breaking Muscle wall run](https://breakingmuscle.com/go-run-up-a-wall-how-to-do-a-parkour-wall-run/)).

**Reach and hanging.** Standing grip reach averages **2.11 m for men and 1.95 m for women** ([US Army 1988 survey](https://multisite.eos.ncsu.edu/www-ergocenter-ncsu-edu/wp-content/uploads/sites/18/2016/06/Anthropometric-Detailed-Data-Tables.pdf)). An average standing jump adds 0.41 to 0.50 m for men and a run-up typically 0.10 to 0.20 m more ([Topend Sports](https://www.topendsports.com/testing/norms/vertical-jump.htm)). Hanging is done with straight arms and feet on the wall where possible; moving sideways is a repeated "bring the far hand in, shift weight, reach the near hand out" cycle, and is much harder with legs dangling ([Breaking Muscle shimmy](https://breakingmuscle.com/shimmy-shimmy-how-to-do-2-beginner-parkour-arm-traverses/)).

**Getting down.** Landing force climbs fast with height: untrained adults took **4.4 body weights from 0.45 m and 7.4 from 0.89 m**, landing on their heels, while trained athletes took 2.5 and 3.6 by landing on the forefoot and folding deep ([drop study](https://pmc.ncbi.nlm.nih.gov/articles/PMC4657414)). Force peaks 35 to 91 ms after contact (same study). From 0.75 m a roll cut the peak from 5.2 to 2.9 body weights ([Puddle and Maulder](https://jssm.org/jssm-12-122.xml-Fulltext)). Among experienced athletes dropping from 0.6 to 2.3 m, some began rolling as height rose and one refused above 1.7 m ([roll study](https://pmc.ncbi.nlm.nih.gov/articles/PMC5611495/)). The standard way to shorten a drop is to turn, hang from the edge and let go ([Wikipedia: Vault](https://en.wikipedia.org/wiki/Vault_(parkour))).

**Narrow and tight spaces.** Everyone can walk a 23 cm beam; on a 3.8 cm beam untrained people managed 2.7 m before stepping off, and on 1.8 cm only 1.55 m ([Sawers and Ting](https://scholarblogs.emory.edu/neuromechanicslab/files/2024/06/Sawers-and-Ting_2015.pdf)). Older adults slowed from 0.82 to 0.69 m/s as a beam narrowed from 10 to 6 cm ([beam study](https://pmc.ncbi.nlm.nih.gov/articles/PMC9046185/)). Young adults can sidle along a wall ledge as shallow as 8.7 cm on average ([ledge study](https://pmc.ncbi.nlm.nih.gov/articles/PMC3756555)). People turn their shoulders for a gap narrower than about 1.3 to 1.4 times shoulder width, begin turning about half a metre before it, and do not slow down ([Tomono](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2019.02651/full)); the narrowest doorway squeezed through sideways averaged 18.9 cm ([squeeze study](https://pmc.ncbi.nlm.nih.gov/articles/PMC3013505)).

**Cover.** Army and police teaching agree: look and fire around the side of cover, not over the top; stay 30 to 46 cm or an arm's length off the wall; come out lower than expected and never twice in the same place; keep exposure between positions to 3 to 5 seconds ([FM 3-06.11](https://www.theblackvault.com/documents/fm/fm30611/ch3.pdf), [Law Officer](https://lawofficer.com/tactics-weapons/appropriate-use-of-cover/), [Army ROTC text](https://www.uakron.edu/armyrotc/MS1/9.pdf)). On a car, the engine block is the part that stops rounds ([Police Magazine](https://www.policemag.com/patrol/article/15754205/using-patrol-vehicles-for-cover)).

**Doors and jumping.** Passing a push door adds about 2 to 3 s to walking through, a pull door about 4 s ([door study](https://ideas.repec.org/a/gam/jsusta/v12y2020i20p8453-d427709.html)). Door hardware sits 0.865 to 1.22 m above the floor ([ADA ch.4](https://www.access-board.gov/ada/chapter/ch04/)). An average standing long jump is about 2.2 to 2.3 m for men and 1.7 to 1.8 m for women, on a coaching site's own table ([Topend Sports](https://www.topendsports.com/testing/tests/longjump.htm)). A natural standing jump spends 0.70 s dipping and 0.30 s pushing, and dipping deeper adds almost no height ([jump study](https://pmc.ncbi.nlm.nih.gov/articles/PMC11208864)). How people get into and out of cars could not be sourced at all: every paper found was blocked.

### 3. A Mixamo clip is hip movement plus joint rotations, with nothing about the world

**The skeleton.** Two real Mixamo files were opened and read. The standard rig has **65 joints, starting at `mixamorig:Hips` with no root bone above it**; some characters add two eye joints ([X Bot file](https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/fbx/mixamo.fbx), [second file](https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/fbx/Samba%20Dancing.fbx)). The chain is Hips, Spine, Spine1, Spine2, Neck, Head; each arm is Shoulder, Arm, ForeArm, Hand with five four-joint fingers; each leg is UpLeg, Leg, Foot, ToeBase, Toe_End. Finger count is not fixed: Mixamo generates fingers from the mesh ([Adobe community](https://community.adobe.com/questions-696/mixamo-standard-65-bone-skeleton-589638)). The files are Y-up, face +Z, are in a T-pose, and use units in which the hips sit about 100 units up (inferred: centimetres). Joint orientations differ between the two files, which is why Godot's rest-pose fixing is needed even between Mixamo files (inferred from the inspection).

**What a clip contains.** In both files, 52 joints carry rotation keys and **only the Hips carry position keys**, at 30 frames a second. Hip position is absolute and includes forward travel, vertical bob and side sway in one track. The files contain nothing describing obstacle height, contact frames or events. The file header calls each clip a "Retargeted Clip" for one named character (same two files). Clips downloaded for one body slid their feet on a differently proportioned body; the best result reported came from uploading the game's own mesh for Mixamo to rig and downloading every clip against it ([Godot forum](https://forum.godotengine.org/t/retargeting-mixamo-animations-fails/39619)). When an already-rigged character was uploaded, Mixamo put the travel on the parent node and left the hips unanimated (same thread).

**Download options.** A third-party manual describes the dialog: with or without skin, 30 or 60 frames a second, keyframe reduction (none recommended), T-pose for the character ([Animancer docs](https://kybernetik.com.au/animancer/docs/manual/getting/mixamo)). The "In Place" tick box exists for some clips and not others, and packs download with default settings only ([Adobe community](https://community.adobe.com/questions-696/fix-missing-in-place-for-animations-that-moves-589474), [Adobe community](https://community.adobe.com/questions-696/in-place-parameter-for-the-pack-589782)). The dialog itself could not be opened.

**Root motion tools.** Because there is no root bone, Blender add-ons exist to make one from the hip movement. mixamo_converter offers per-axis choices and an "On Ground" option that keeps the root on the ground unless the hips rise above their rest height ([README](https://raw.githubusercontent.com/enziop/mixamo_converter/master/README.md)). "Import Mixamo - Root Motion" batch-imports, strips the name prefix and creates root bones ([Blender extensions](https://extensions.blender.org/add-ons/import-mixamo-root-motion/)). A third, "Mixamo Root", was reported by one user as failing on recent Blender versions ([Godot forum](https://forum.godotengine.org/t/blender-addon-for-mixamo-root-motion-in-blender-4-5-godot-4-5/135760)).

**The library.** The catalogue is behind a login and could not be opened, so no clip or pack name could be verified from public sources. The project's own folder of 408 downloaded clips was measured afterwards; see Part 3. A public mirror holds 2,453 animation files ([Hugging Face listing](https://huggingface.co/datasets/jasongzy/Mixamo)), and a 2016 forum post says the library includes climbing, hanging and climb-to-stand clips with root motion ([Unreal forum](https://forums.unrealengine.com/t/advanced-climbing-system/51566/36)).

**Licence.** Adobe says characters and animations may be used royalty-free in commercial games ([Adobe FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html)). A community-forum licensing post lists the one thing not allowed: distributing the raw character or animation files, with team collaboration excepted ([Adobe community](https://community.adobe.com/questions-696/mixamo-faq-licensing-royalties-ownership-eula-and-tos-589400)). Inferred: raw Mixamo files belong in a private repository only. The binding Adobe terms were not read.

### 4. Godot 4.7 has the parts, but no warping, no foot placement and no stair stepping

**Version.** Current stable is Godot 4.7.2, August 2026 ([Godot tags](https://github.com/godotengine/godot/tags)). The pieces arrived in steps: skeleton modifiers in 4.3; look-at, runtime retarget, built-in Jolt, 3D physics interpolation and animation markers in 4.4 ([4.4 release](https://godotengine.org/releases/4.4/)); bone constraints in 4.5 ([4.5 release](https://godotengine.org/releases/4.5/)); the IK family in 4.6, with Jolt made the default for new projects ([4.6 release](https://godotengine.org/releases/4.6/)); blend-space sync modes in 4.7 ([4.7 upgrade notes](https://github.com/godotengine/godot-docs/blob/stable/tutorials/migrating/upgrading_to_godot_4.7.rst)).

**How a frame is built.** Animation writes bone poses first. Then, once per frame, the skeleton runs each child modifier node in child order, sends the result to the mesh, and **rolls the bones back to the animation-only pose** ([skeleton source](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/skeleton_3d.cpp), [design article](https://godotengine.org/article/design-of-the-skeleton-modifier-3d/)). Two consequences follow. Code that reads a bone in `_process` or `_physics_process` sees the pose before IK; the final pose is available only when the `skeleton_updated` or `modification_processed` signals fire ([Skeleton3D reference](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/doc/classes/Skeleton3D.xml)). And if modifiers depend on physics, the skeleton's modifier timing must be set to physics (design article above).

**Modifiers that ship.** `TwoBoneIK3D` solves a two-bone limb exactly, with a pole target to control which way the knee or elbow points ([reference](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/doc/classes/TwoBoneIK3D.xml)). `LookAtModifier3D` turns a bone toward a target with angle limits and timed easing; a parent's look-at must sit above its child's in the list ([reference](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/doc/classes/LookAtModifier3D.xml)). The chain solvers accept joint limits, but the only limit shape is a cone ([reference](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/doc/classes/JointLimitationCone3D.xml)), and they move at most 2 degrees per pass, 4 passes a frame, by default ([reference](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/doc/classes/IterateIK3D.xml)). `BoneTwistDisperser3D` spreads twist along a limb, `LimitAngularVelocityModifier3D` caps how fast bones may turn, `ModifierBoneTarget3D` exposes a bone's final position, and `PhysicalBoneSimulator3D` is the ragdoll ([4.7.2 class list](https://github.com/godotengine/godot/tree/4.7.2-stable/doc/classes)). The old `SkeletonIK3D` is deprecated ([reference](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/doc/classes/SkeletonIK3D.xml)). There is no tutorial for the IK family yet, only the class reference.

**Animation tree.** `AnimationTree` blends clips through state machines, blend spaces, one-shots and filtered layers. Blend spaces in 4.7 can time-scale their clips to stay in step (`SYNC_MODE_CYCLIC_MUTABLE`) ([reference](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/doc/classes/AnimationNodeBlendSpace2D.xml)). A clip node can be stretched and offset so walk and run share a cycle and start on the same foot ([reference](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/doc/classes/AnimationNodeAnimation.xml)). Bone filters on blend nodes give upper and lower body layering ([reference](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/doc/classes/AnimationNode.xml)). Named markers can be placed on a clip and read by time ([reference](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/doc/classes/Animation.xml)). **Godot has no built-in motion matching, foot sync markers, motion warping, stride warping or foot placement**: no such class exists in 4.7.2 ([class list](https://github.com/godotengine/godot/tree/4.7.2-stable/doc/classes)).

**Root motion.** Point `root_motion_track` at a bone and the tree removes that bone's travel from the picture and hands it to code as a per-tick amount; with `root_motion_local` on, the documented recipe is to turn the body by the rotation amount and move it by its own facing times the position amount ([AnimationMixer reference](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/doc/classes/AnimationMixer.xml)). The humanoid profile expects a bone named `Root` above the hips at the world origin ([SkeletonProfile reference](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/doc/classes/SkeletonProfile.xml)). Inferred: the tree and the body must run on the same tick, or travel is lost or doubled.

**Import and retargeting.** FBX files import directly since 4.3 ([formats manual](https://github.com/godotengine/godot-docs/blob/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.rst)), are converted to metres, and have `:` in bone names replaced by `_` ([FBX source](https://raw.githubusercontent.com/godotengine/godot/master/modules/fbx/fbx_document.cpp), [skin tool source](https://raw.githubusercontent.com/godotengine/godot/master/modules/gltf/skin_tool.cpp)). In Godot 4 a bone's pose includes its rest position, so clips can be shared only between skeletons whose bone names and rest poses both match; the import-time fix is a `BoneMap` to `SkeletonProfileHumanoid` with "Overwrite Axis", which the manual calls "the most important option for sharing animations" ([retargeting manual](https://github.com/godotengine/godot-docs/blob/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.rst)). "Fix Silhouette" is not needed for T-pose models (same manual). By default the importer removes position tracks from every bone except Root and Hips and stores hip height as a scale factor so hip travel scales with leg length ([rest fixer source](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/editor/import/3d/post_import_plugin_skeleton_rest_fixer.cpp)). One 2026 report of arms clipping through the body on a Mixamo setup has no confirmed cause ([Godot forum](https://forum.godotengine.org/t/mixamo-animation-retarget/137067)).

**Ragdoll.** A ragdoll is a `PhysicalBoneSimulator3D` with `PhysicalBone3D` children; it can simulate a named subset of bones, and its `influence` blends it against animation ([ragdoll manual](https://github.com/godotengine/godot-docs/blob/stable/tutorials/physics/ragdoll_system.rst)). The manual advises cone joints for shoulders, hips and neck, hinges for elbows and knees, and one bone for a whole hand. `PhysicalBone3D` has **no motors**: the word does not appear in its source ([source](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/physics/physical_bone_3d.cpp)). A forum pattern for hit reactions is to start simulation at 0.8 influence and fade it to 0 over half a second with the animation tree left running ([Godot forum](https://forum.godotengine.org/t/active-ragdoll-in-godot-4-5-how-to-achieve-good-results/128728)).

**Body and interpolation.** `CharacterBody3D` handles floors, slopes, walls and moving platforms and has no step property ([reference](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/doc/classes/CharacterBody3D.xml)). Community stair methods sweep the body up, forward and down with `test_move` before `move_and_slide` ([stair blog](https://dresswithpockets.github.io/2025/03/19/godot-stair-stepping.html)). Physics interpolation smooths node movement between ticks but requires everything that moves things, animation included, to run on the physics tick, and the camera to be smoothed by hand ([interpolation manual](https://github.com/godotengine/godot-docs/blob/stable/tutorials/physics/interpolation/using_physics_interpolation.rst), [advanced manual](https://github.com/godotengine/godot-docs/blob/stable/tutorials/physics/interpolation/advanced_physics_interpolation.rst)). Inferred and untested: bone poses are not node transforms, so a skeleton animated on the physics tick is posed at tick rate while its node glides smoothly.

### 5. Jolt has a full character controller and ragdoll system; Godot exposes neither

**The central finding.** Jolt ships `CharacterVirtual`, a controller with stair walking, floor sticking, four ground states and slope handling ([Jolt architecture](https://raw.githubusercontent.com/jrouwe/JoltPhysics/master/Docs/Architecture.md), [CharacterVirtual header](https://raw.githubusercontent.com/jrouwe/JoltPhysics/master/Jolt/Physics/Character/CharacterVirtual.h)). **Godot compiles it but never calls it.** A search of Godot's Jolt module finds the character files only in the list of sources to build ([build list](https://raw.githubusercontent.com/godotengine/godot/master/modules/jolt_physics/SCsub)). `move_and_slide` remains Godot's own code calling `body_test_motion` ([source](https://raw.githubusercontent.com/godotengine/godot/master/scene/3d/physics/character_body_3d.cpp)). Whether Godot plans to expose it: no source found.

**How Godot's movement test works under Jolt.** Each test pushes the body out of overlaps (4 passes at 40 % each), searches along the motion for the first touch, then collects contacts ([direct space source](https://raw.githubusercontent.com/godotengine/godot/master/modules/jolt_physics/spaces/jolt_physics_direct_space_state_3d.cpp)). At the last step the code **discards any contact that does not oppose the motion**, with a source comment calling this "a deliberate divergence" that "is known to cause issues" but prevents "a problematic amount of ghost collisions" ([collector source](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/modules/jolt_physics/spaces/jolt_query_collectors.h)). Open bug reports trace wrong floor and wall flags to this ([issue 104969](https://github.com/godotengine/godot/issues/104969)); one related fault, missed collisions when wedged or at small time steps, was fixed for 4.7 ([issue 117857](https://github.com/godotengine/godot/issues/117857)). Inferred: moving level over a flat floor reports no floor contact, so ground must be found by its own downward test every tick.

**Ideas worth copying from Jolt's controller.** Its header documents a 2 cm padding kept from geometry, a 0.1 m look-ahead for contacts, a default step-up of 0.4 m and stick-down of 0.5 m, counting only contacts on the capsule's lower sphere as support, a second longer forward test for steps when the per-tick move is tiny, and four ground states (on ground, on steep ground, touching but unsupported, in air) ([CharacterVirtual header](https://raw.githubusercontent.com/jrouwe/JoltPhysics/master/Jolt/Physics/Character/CharacterVirtual.h), [CharacterBase header](https://raw.githubusercontent.com/jrouwe/JoltPhysics/master/Jolt/Physics/Character/CharacterBase.h)). Jolt's sample character is a capsule of radius 0.3 m ([sample](https://raw.githubusercontent.com/jrouwe/JoltPhysics/master/Samples/Tests/Character/CharacterBaseTest.h)), and Jolt calls cylinders "the least stable of all shapes" (architecture page above).

**Queries.** A ray is a true closest-hit ray. `cast_motion` is not a true sweep: it is a search of up to 16 overlap tests per nearby body, it **ignores anything the shape already overlaps at the start**, and a zero-length cast returns nothing ([direct space source](https://raw.githubusercontent.com/godotengine/godot/master/modules/jolt_physics/spaces/jolt_physics_direct_space_state_3d.cpp)). `collide_shape`, `intersect_shape` and `get_rest_info` answer "what overlaps here". Three traps are documented. Rays can slip between two triangles exactly on a shared edge; the workarounds are a second ray offset by about 1 mm or a 1 mm sphere cast, which "never slipped" in the reporter's tests ([issue 124689](https://github.com/godotengine/godot/issues/124689)). Triangle-mesh colliders are hollow and one-sided, so an overlap test fully inside or behind one reads as empty; a climbing probe that used a zero-length shape cast "only detects when its close to the edges" until back-face collision was switched on ([issue 104681](https://github.com/godotengine/godot/issues/104681)). And a sphere query placed at exactly the same centre as sphere colliders becomes very slow; a 1 mm offset cures it ([issue 110591](https://github.com/godotengine/godot/issues/110591)).

**Ghost bumps.** Sliding over the seam between two triangles or two boxes can stop or kick a body. Jolt removes these inside one body but, in Godot's words, "neither the active edge detection nor enhanced internal edge removal apply when dealing with ghost collisions between two different bodies" ([Godot Jolt manual](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/physics/using_jolt_physics.rst)). Within a mesh it needs shared edges and no T-junctions ([Jolt architecture](https://raw.githubusercontent.com/jrouwe/JoltPhysics/master/Docs/Architecture.md)).

**Settings and limits.** Godot steps Jolt once per physics tick at 60 ticks a second, the rate Jolt calls stable ([space source](https://raw.githubusercontent.com/godotengine/godot/master/modules/jolt_physics/spaces/jolt_space_3d.cpp)). Jolt is tuned for metres, moving objects 0.1 to 10 m in size, and a world within about 5 km of the origin ([Jolt architecture](https://raw.githubusercontent.com/jrouwe/JoltPhysics/master/Docs/Architecture.md)). Capsules get no collision margin in Godot's Jolt module, and a capsule's height must be at least twice its radius ([capsule source](https://raw.githubusercontent.com/godotengine/godot/master/modules/jolt_physics/shapes/jolt_capsule_shape_3d.cpp)). On cost, one report measured a scripted step-up as about 20 times dearer than `move_and_slide`, and one triangle mesh as far faster than many convex shapes for level geometry ([issue 93184](https://github.com/godotengine/godot/issues/93184)). The same thread reports a phone holding 60 frames a second at 60 ticks but 12 to 17 at 160 ticks.

**Platforms.** A character on a rotating platform drifts outward ([issue 102763](https://github.com/godotengine/godot/issues/102763)), and calling floor snap with a small upward speed on a moving platform can catapult the character ([issue 112315](https://github.com/godotengine/godot/issues/112315)); both are open.

**Ragdolls.** Jolt has a ragdoll layer with mass stabilising, parent-child collision filtering and "drive to this pose with motors" ([Ragdoll header](https://raw.githubusercontent.com/jrouwe/JoltPhysics/master/Jolt/Physics/Ragdoll/Ragdoll.h)). Godot compiles it and does not use it; Godot ragdolls are ordinary bodies and joints that Jolt runs as its own constraint types ([cone joint source](https://raw.githubusercontent.com/godotengine/godot/master/modules/jolt_physics/joints/jolt_cone_twist_joint_3d.cpp)). Jolt ignores the soft-limit settings on Godot joints ([Godot Jolt manual](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/physics/using_jolt_physics.rst)). The Jolt module does implement springs and motors on the standalone six-axis joint ([6DOF source](https://raw.githubusercontent.com/godotengine/godot/master/modules/jolt_physics/joints/jolt_generic_6dof_joint_3d.cpp)); whether those can match a full animated pose is untested.

### 6. Rockstar publishes almost nothing; the clip lists and outside studies fill the gaps

**What is on record.** Rockstar has not described its capsule, ground probe, climb detection, clip fitting, hand IK or cover generation in anything the researchers could fetch. What follows comes from three kinds of source: developer interviews and a patent, names recoverable from modding documentation (no leaked code was read), and third-party analysis. Nothing GTA IV-specific was found beyond its Euphoria interview and a feature summary.

**Euphoria.** Euphoria is not a canned ragdoll. In its makers' words it "runs on top of" Rockstar's physics and "controls the physical characters" by modelling "the body, the muscles but also the nervous system" ([TechRadar](https://www.techradar.com/news/gaming/the-technology-of-max-payne-3-1082751)). Motors on the ragdoll's joints act as muscles; Rockstar had built a special solver that treats the whole skeleton as one unbreakable linked body, which gave "joint strengths that matched what you set them to" and "avoided foot jitter"; a balancer takes "rapid, accurate stabilising steps" ([Eurogamer](https://www.eurogamer.net/one-thing-about-gta4-has-never-been-bettered)). GTA V's behaviour list is public by name: balance, stagger fall, brace for impact, catch fall, arms windmill, shot reactions, grab, high fall, roll down stairs, and about ninety balance settings including a step count and give-up thresholds ([behaviour list](https://docs.ragecoop.com/SHVDN/GTA.NaturalMotion.html), [message schemas](https://gist.github.com/alexguirre/915f90002f44622e09dc5c793c18b3ef)). The return to animation is a separate get-up stage with clips by lying direction (front, back, left, right), by stage (prone to knees or seated, then standing) and by state (standard, injured, drunk, armed) ([clip dump](https://raw.githubusercontent.com/DurtyFree/gta-v-data-dumps/master/animDictsCompact.json)). The warning for anyone copying it: "it was more computationally expensive than traditional methods", and "putting believable, dynamic, reactive characters in a fun sandbox world took us years to get right" ([Eurogamer](https://www.eurogamer.net/one-thing-about-gta4-has-never-been-bettered)).

**Locomotion.** GTA V runs on-foot movement as an animation network of state machines and blend nodes; blends between walk and run cycles are synchronised on left and right heel tags in the clips ([CodeWalker network parser](https://raw.githubusercontent.com/dexyfex/CodeWalker/master/CodeWalker.Core/GameFiles/FileTypes/MrfFile.cs)). Speed is one number from 0 to 3: still, walk, run, sprint ([native docs](https://raw.githubusercontent.com/citizenfx/natives/master/TASK/TaskFollowNavMeshToCoord.md)). The generic male movement set contains, besides idle, walk, run and sprint: stair and slope versions of walk and run; walk and run starts at 0, 90 and 180 degrees for each foot; walk stops by direction and foot, plus quick stops; run stops by foot; idle turns; moving turns in two or three sharpness grades per gait; 180 degree turns; and walk-to-run and run-to-walk changes by foot ([clip dump](https://raw.githubusercontent.com/DurtyFree/gta-v-data-dumps/master/animDictsCompact.json)). Inferred: about 66 clips per movement style. Aiming uses a separate eight-direction strafe set, and stealth and "action mode" are further full sets (same dump). Leg IK and a "root slope fixup" solver exist by name ([class list](https://raw.githubusercontent.com/citizenfx/fivem/master/code/components/gta-core-five/include/gta_vtables.h)).

**Capsule.** A capsule settings file in RDR2 format, redistributed by a community mod and possibly edited, gives the standard male: radius 0.25 m standing, 0.45 running, 0.5 crouched, 0.15 in cover; knee height -0.65 and capsule offset -0.75 from a root 1.0 m above ground; ground probe radius 0.1 ([pedbounds file](https://raw.githubusercontent.com/Hailey-Ross/redm-map-one/main/pedbounds.xml)). Inferred from the field names only, not documented anywhere: the character stands on a downward probe while the capsule covers roughly knee to head, so kerbs and steps pass under it; and the capsule changes width with state. RDR2 can switch stair stepping on and off per map volume ([RDR2 native list](https://raw.githubusercontent.com/alloc8or/rdr3-nativedb-data/master/natives.json)).

**The heavy feel.** Third parties measured it. GTA IV took 133 to 200 ms from trigger to animation ([Digital Foundry](https://www.eurogamer.net/digitalfoundry-lag-factor-article?page=2)). RDR2 needed 11 frames before reacting to input against 6 for Uncharted: The Lost Legacy and 4 for Assassin's Creed Odyssey, in one analyst's test ([Mein-MMO](https://mein-mmo.de/en/red-dead-redemption-2-experte-steuerung-traege,288771)). That analyst's explanation: most shooters take a character "from zero to 4.5 meters a second within about 10 frames", beyond human ability, and Rockstar's realistic model buys "very high quality animation; it just comes at the expense of game feel" ([Cartoon Brew](https://www.cartoonbrew.com/educational/an-analysis-of-animation-systems-in-red-dead-redemption-2-166968.html)).

**Traversal.** One task "climbs or vaults the nearest thing" ([native docs](https://raw.githubusercontent.com/citizenfx/natives/master/TASK/TaskClimb.md)), fed by a hand-hold detection result ([class list](https://raw.githubusercontent.com/citizenfx/fivem/master/code/components/gta-core-five/include/gta_vtables.h)). The climb clip library exposes the design by its names: standing climbs at **20, 80, 140, 180, 220 and 295**, with "low" and "high" variants and twins angled at 20; running versions of most; walking versions of two; vaults at 20 and 80 from standing; a shared pose on top of the ledge that branches to stand, walk, run, fall (in several widths), or dive; and bonnet slides ([clip dump](https://raw.githubusercontent.com/DurtyFree/gta-v-data-dumps/master/animDictsCompact.json)). Inferred, with units stated nowhere: these are hand-hold heights in centimetres, so GTA V's highest climb is about 2.95 m. Other sets cover jump launches by foot, height and length; landings by height and by exit speed, with a roll; drop-downs at walk and run; and ladders (same dump). RDR2 adds a per-object permission for automatic vaulting separate from climbing ([RDR2 native list](https://raw.githubusercontent.com/alloc8or/rdr3-nativedb-data/master/natives.json)). How the detector probes and how clips are fitted to a ledge is not public.

**Cover, vehicles, doors, shoves.** Cover clips are keyed by low or high, left or right, and approach angle, with idles, peeks, steps and turns ([clip dump](https://raw.githubusercontent.com/DurtyFree/gta-v-data-dumps/master/animDictsCompact.json)). Vehicle entry is a chain of named tasks (go to door, align, open door, enter seat, close door) with clip sets per vehicle layout ([class list](https://raw.githubusercontent.com/citizenfx/fivem/master/code/components/gta-core-five/include/gta_vtables.h)). Doors are opened with short arm sweep or shoulder barge clips (clip dump above). Shoves have both animated reactions and a ragdoll route.

**RDR2.** Rockstar says it "radically overhauled our entire animation system" ([VG247](https://www.vg247.com/red-dead-redemption-2-physics-ai-euphoria-phil-hooker-interview)). As reported from a Rockstar talk, the horse system assembled "thousands of smaller animations" on the fly, deliberately "added input lag", and "ended up being applied across the game much more widely" ([PC Gamer](https://www.pcgamer.com/the-mind-boggling-work-that-went-into-red-dead-2s-incredibly-lifelike-horses/)). A second summary of the same talk says each animation was analysed for the speeds it covers, with a minimum, ideal and maximum, and chosen and weighted at run time ([Game Developer](https://www.gamedeveloper.com/design/rockstar-s-quest-for-the-ultimate-video-game-horse)). A Take-Two patent describes motions grouped into styles grouped into character archetypes with fallbacks ([patent](https://patents.google.com/patent/US11620781B1/en)). **"RDR2 uses motion matching" is unverified**: no fetched Rockstar source says so.

**Published recipes that stand in where Rockstar is silent.** Daniel Holden describes the split this report recommends: a simple capsule moved by stick input through a smoothing spring, a character that follows it by animation, and a gentle clamped correction between them, with separate tuning for speed and turning ([Holden](https://theorangeduck.com/page/code-vs-data-driven-displacement)). His motion capture ran at just over 4 m/s forward and walked at about 1.75 m/s (same page). Epic's Paragon team scaled stride length rather than playback speed to match ground speed, and placed sync markers where a foot passes the root ([Game Developer](https://www.gamedeveloper.com/programming/most-inspiring-game-animation-tech-talks-of-2016)). Unreal's Motion Warping adjusts a clip's root motion inside marked windows so the body arrives at a measured target ([Unreal docs](https://dev.epicgames.com/documentation/en-us/unreal-engine/motion-warping-in-unreal-engine)). In Epic's sample project, traversal clips sit in a table where each row has a minimum and maximum obstacle height ([Epic forum](https://forums.unrealengine.com/t/game-animation-sample-increase-the-height-of-climbing/2347204/4)). A third-party plugin built on that design documents its outputs: the near ledge, the far ledge and the landing point ([Aurora Devs](https://coda.io/@aurora-devs/documentation-replicated-traversal-system/traversal-5)).

## Part 2. Recommendation

Everything below is design advice. It follows from Part 1 but has not been run.

### Four layers with one owner each, and a fixed rule for who moves the body

Most hybrid controllers fail because two systems both try to place the character. Give each job one owner.

**Layer 1, the body (physics).** One `CharacterBody3D` with a capsule. It alone decides where the character is. In normal movement it is driven by code: stick input becomes a target speed and heading, smoothed by a spring, as Holden describes. Animation never pushes it in this mode.

**Layer 2, clips (animation).** One `AnimationTree` set to the physics tick. In normal movement the clips play to match the body's speed; their root travel is cancelled by Godot and used only as a measurement. In a traversal move the roles swap for the length of that move: the clip's root travel, stretched to fit the measured obstacle, drives the body, with gravity and normal collision off. Rockstar's animation flags show the same options exist there (mover extraction, kinematic physics, ignore gravity, collision off) ([native docs](https://raw.githubusercontent.com/citizenfx/natives/master/TASK/TaskPlayAnim.md)).

**Layer 3, corrections (procedural).** Skeleton modifiers, in this child order under the skeleton: a pelvis height offset (custom), leg `TwoBoneIK3D`, arm `TwoBoneIK3D`, `BoneTwistDisperser3D` for forearms, look-at for spine then neck then head, `LimitAngularVelocityModifier3D` as a pop filter, and the ragdoll simulator last. This order is a design reading of the documented rules (child order is run order; parent look-at before child), not an official recipe. Each has its own `influence` so it can be faded.

**Layer 4, ragdoll.** `PhysicalBoneSimulator3D`, off by default. It takes over fully on hard impacts and long falls, and partially (a few bones at reduced influence) for hit reactions, then hands back through a get-up clip chosen by which way the body lies, as GTA V's clip sets do. Do not attempt a self-balancing ragdoll in this project phase.

**The body shape.** I recommend a floating capsule: a capsule that covers the body from about 0.35 m above the ground to the top of the head, held at the right height by one short downward probe each tick, with the body's height following the probe through a spring. Radius 0.25 m; for a 1.76 m character that is a capsule about 1.40 m tall, which satisfies Jolt's rule that height be at least twice the radius. The reasons: kerbs and stair risers (0.10 to 0.24 m in the codes above) pass under the capsule, so no step-up routine is needed; height changes are smoothed by construction; ground detection no longer relies on the contact filter that causes Jolt's floor-flag faults; and it costs one query a tick where a scripted step-up cost about 20 times `move_and_slide` in the one report available. It also matches the reading of Rockstar's capsule fields, but that reading is an inference from names. Run the body in `MOTION_MODE_FLOATING`, apply gravity yourself, and keep four ground states as Jolt's own controller does: on ground, on ground too steep, touching but unsupported, in air.

The fallback, if Stage 1 fails its tests, is a full-height capsule with the community up-forward-down sweep before `move_and_slide`. Decide by the Stage 1 tests, not by argument.

**Timing.** Physics at 60 ticks. `AnimationTree.callback_mode_process` and `Skeleton3D.modifier_callback_mode_process` both set to physics, so clips, IK and queries all see the same moment. Leave physics interpolation off until Stage 3, then test it; how skinned characters look with it is not documented.

### Detection: one measuring routine, tested on its own before any clip plays

Build obstacle detection as a separate piece that only measures and draws its result on screen. It should produce one record: obstacle top height above the character's ground, the near edge position and wall facing direction, depth (how far the top extends), whether the top has room to stand, the far edge and landing ground height if the obstacle is thin, and free width on top.

A query set that follows from the Jolt findings, in order:

1. **Forward.** A short sphere `cast_motion` from inside the character's own capsule, at two or three heights, in the travel direction. Start inside the capsule because a cast ignores whatever it starts inside; exclude the character itself. Then `get_rest_info` at the touch point for the wall direction. This is the same two-step method Godot's own `ShapeCast3D` uses.
2. **Top.** From above the maximum climb height, a thin sphere cast downward just beyond the wall face to find the top surface. Use a thin sphere, not a ray, because rays slip on shared triangle edges. Repeat at several distances forward to measure depth and find the far edge.
3. **Room.** An `intersect_shape` test of the standing (or crouching) capsule on top to see whether the character fits. Because triangle-mesh colliders are hollow and one-sided, this can read "free" wrongly; either use box or convex colliders for anything climbable, or switch on back-face collision for that geometry, and confirm with a short sweep from the open side.
4. **Landing.** For a thin obstacle, a downward thin sphere cast beyond the far edge for the landing height; a `test_move` of the capsule at the landing spot.
5. **Ceiling.** An upward cast for headroom before any move that raises the body.

Offset every sphere probe by a millimetre from the capsule's centre line to avoid the slow case with perfectly aligned curved shapes. Keep all casts short and on a dedicated collision layer for traversable geometry. How many such queries a phone can afford per tick is not known from any source; run detection only when the player asks for a move or walks into something, not every tick.

**Height bands.** These are derived from the human data for a character about 1.76 m tall. The band edges are the note-takers' synthesis of the cited figures, so treat them as starting values to tune, and scale them by character height.

| Obstacle top above ground | What a person does | Human basis | Rockstar clip height nearby (units inferred) |
|---|---|---|---|
| up to 0.30 m | walk over it, no move | kerbs 0.10 to 0.20 m, risers to 0.24 m; cheapest riser 0.26 of leg length | 20 |
| 0.30 to 0.50 m | deliberate high step | still far below the 0.88 leg-length hands-free limit | 20 |
| 0.50 to 1.10 m | vault if thin, climb on if deep; step vault at a walk, one-hand vault at a run | coaches: knee to hip is the main vault band; police vault 0.86 m; waist height 1.13 m | 80 |
| 1.10 to 1.45 m | two-hand mantle with a small jump | coaches: shoulder height (1.44 m) is the vault limit | 140 |
| 1.45 to 2.10 m | reach up, grab the top, climb up | standing grip reach 2.11 m; police wall 1.83 m | 180 |
| 2.10 to 2.60 m | jump, grab, climb up | average standing jump adds 0.41 to 0.50 m | 220 |
| 2.60 to 3.00 m | running wall-run only | run-up adds 0.10 to 0.20 m; coach calls 2.74 to 3.05 m the hard range | 295 |
| above 3.0 m | not climbable | | none |

Sources for the human column: [Warren](https://digitalcommons.lib.uconn.edu/dissertations/AAI8309263), [MovNat](https://movnat.com/definitive-guide-to-vaulting/), [University of Arizona PD guide](https://www.uapd.arizona.edu/sites/default/files/2024-08/UAPD%20Recruit%20Study%20Guide%20.pdf), [US Army 1988 survey](https://multisite.eos.ncsu.edu/www-ergocenter-ncsu-edu/wp-content/uploads/sites/18/2016/06/Anthropometric-Detailed-Data-Tables.pdf), [Topend Sports](https://www.topendsports.com/testing/norms/vertical-jump.htm), [Breaking Muscle wall run](https://breakingmuscle.com/go-run-up-a-wall-how-to-do-a-parkour-wall-run/).

**Going down.** Also a synthesis: up to 0.30 m, step down in stride; 0.30 to 1.0 m, step or hop off with a soft landing; 1.0 to 2.0 m, a heavy landing or a turn, hang and drop; 2.0 to 3.0 m, hang and drop preferred, with a roll for a running jump; above that, expect damage. The basis is the landing forces (4.4 body weights at 0.45 m, 7.4 at 0.89 m untrained) and the athletes' roll behaviour between 0.6 and 2.3 m. Hanging at full stretch puts the feet about 2.0 to 2.1 m below the hands (inferred from grip reach), so a 3 m ledge becomes a 1 m drop. Start the landing fold on the contact frame, since force peaks within 35 to 91 ms.

**Depth and width.** The human sources give no number for how deep an obstacle can be and still be vaulted (stated as not found in the notes), so the vault-or-climb-on split must come from the measured forward reach of the vault clip you choose. Width has real data: on a top surface 0.25 m or wider, walk normally; 0.10 to 0.25 m, walk slowly with arms out (about 0.7 to 0.8 m/s in the older-adult data); 0.04 to 0.10 m, slow heel-to-toe with frequent corrections; below 0.04 m, do not allow it. For a ledge with a wall behind, allow a sidle down to about 0.10 m. For gaps between walls: walk straight through at 0.60 m and wider, turn the shoulders from 0.45 to 0.60 m starting half a metre before, go fully sideways from 0.45 down to 0.25 m, and block below about 0.20 m. Duck when clearance is below head height; a light stoop covers down to about 93 % of height at nearly full speed, and a deep crouch moves at about half walking speed.

**Slopes.** Normal walking art covers 0 to 5 degrees, which is where accessible paths stop. Real streets reach 19 degrees, so the walkable limit must be above that; `CharacterBody3D`'s default of 45 degrees and Jolt's of 50 are both far above anything the slip data supports for grip. The right limit between is not given by any source in the notes; choose it in Stage 1 on the test ramp.

### What you must record for every clip, and how a clip is fitted to an obstacle

A Mixamo file carries no information about what it fits, so the game needs its own table, filled by measuring each clip after import. For every clip record:

| Field | Why |
|---|---|
| Duration, and whether it loops | playback and blending |
| Root travel start to end: forward, sideways, up, turn | to move the body and to choose the clip |
| For loops: speed (travel divided by duration) and the times each heel lands | to match playback to body speed and to line up walk with run |
| Which foot is forward at start and end | to chain clips without a stutter step |
| For traversal: time and hand position (relative to root) of first hand contact, and of release | to fit hands to the ledge |
| For traversal: the obstacle height and depth the clip was captured on, measured as hand height above the feet at contact | the clip's "native" obstacle |
| For traversal: time the feet leave the ground and time they land, and the landing position relative to start | the fitting windows |
| The height range the clip may be stretched to cover | selection |

Store the contact times as named markers on the clip (Godot 4.4 and later) so code can read them before playing; method-call tracks are skipped by seeks and fire a step late by default.

**Selecting.** Copy the shape of Rockstar's library and Epic's table: bucket clips by entry speed (stand, walk, run), by height band, and by what is beyond the edge (a top to stand on, a thin obstacle with ground behind, or a drop). Each row has a minimum and maximum height. Start with one clip per band and add variants only where a test shows a visible stretch.

**Fitting.** Godot has no motion warping, so this is project code. The method that follows from Unreal's documented approach and Godot's API:

1. Before the move, slide and turn the body over a short fixed time so it starts at the clip's native distance from the wall, facing it. Rockstar has a named "align" task before vehicle entry for the same reason.
2. Switch the body to traversal mode: gravity off, normal collision off, body moved only by the clip's root travel.
3. Between the start and the hand-contact marker, scale the root travel so the root arrives where the clip's hands would rest on the measured ledge; between hand contact and landing, scale it again to reach the measured landing point. Scaling stays small if the height bands are narrow.
4. From hand contact to release, hold the hands on the measured ledge points with arm `TwoBoneIK3D`, faded in and out by `influence`. Body proportions differ from the capture, so without this the hands will miss.
5. At the end, hand the body back to code-driven movement at the clip's exit speed, into the matching locomotion state.

One point must be settled by experiment at Stage 2: where a climb's upward travel lives. A root bone that takes only ground-plane travel leaves the rise in the hips, so the mesh climbs away from its own body node. Either extract vertical travel into the root for traversal clips, or keep it in the hips and move the body node up by measured amounts while offsetting the mesh. Godot's documentation says nothing on vertical root motion for climbs. Test both on one climb clip and keep whichever passes.

### The Mixamo pipeline: one character, a root bone added in Blender, one import recipe

1. **Fix the character first.** Upload the game's own mesh, unrigged, for Mixamo to rig, and download it in T-pose. Download every clip against that character. This is the route the forum evidence favours; clips taken on a differently proportioned body slide their feet.
2. **Download clips one at a time**, without skin, 30 frames a second, no keyframe reduction, not in place. Packs carry default settings only. Whether a mesh-less file gives Godot a sound rest pose was not verified, so check the first clip carefully; if it misbehaves, download with skin.
3. **Blender pass.** Batch-import, add a root bone that takes ground-plane travel and turning from the hips, leave the hips' vertical movement in the hips, strip the `mixamorig:` prefix, and export glTF. "Import Mixamo - Root Motion" or mixamo_converter do this; neither was run by the researchers. Never zero the hips' height track: a script that does so makes a crouch happen "in place" instead of lowering ([Babylon forum](https://forum.babylonjs.com/t/if-mixamo-transformations-and-bone-alignements-messed-up/29038)).
4. **Godot import, character.** In Advanced Import Settings select the skeleton, create a `BoneMap` with `SkeletonProfileHumanoid`, check that every bone shows green and that the new root is mapped to `Root`. Leave the defaults: rename bones on, unique skeleton name `GeneralSkeleton`, Overwrite Axis, normalise position tracks, Fix Silhouette off.
5. **Godot import, clips.** Import each clip file as an Animation Library with the same `BoneMap`. Set `root_motion_track` to the `Root` bone.
6. **Measure.** Run a small tool that plays each clip once and fills the table above.
7. **Keep raw Mixamo files out of any public repository.**

Expect the map to be the same every time: Mixamo's Spine, Spine1, Spine2 become Spine, Chest, UpperChest; Arm and ForeArm become UpperArm and LowerArm; UpLeg and Leg become UpperLeg and LowerLeg; ToeBase becomes Toes; the thirteen end joints map to nothing ([bone table](https://raw.githubusercontent.com/uzairdeveloper223/mixabridge/main/addons/mixabridge/mixamo_bone_table.gd)).

### Joint limits for the IK layer

Use measured averages where they exist. Godot's two-bone solver has no limit settings in its reference, so knee and elbow limits must be enforced by how the target is set: never let the target be further than the limb's length minus a small margin, and place the pole target in front of the knee and behind the elbow.

| Joint | Limit to enforce | Source |
|---|---|---|
| Knee | hinge, 0 to about 140 degrees of bend; no visible back-bend (measured 1 to 2 degrees) | [CDC](https://archive.cdc.gov/www_cdc_gov/ncbddd/jointROM/index.html) |
| Knee twist | none when straight; at 90 degrees of bend, about 10 inward and 30 to 40 outward | [Wikipedia: Knee](https://en.wikipedia.org/wiki/Knee) |
| Hip | flexion about 130, extension about 17; spread 50, cross 30; twist 30 out and 40 in (hip extended) | [CDC](https://archive.cdc.gov/www_cdc_gov/ncbddd/jointROM/index.html), [Wikipedia: Hip](https://en.wikipedia.org/wiki/Hip) |
| Ankle | 13 up, 55 to 62 down; tilt 30 in, 20 out | [CDC](https://archive.cdc.gov/www_cdc_gov/ncbddd/jointROM/index.html), [DSHS chart](https://www.dshs.wa.gov/sites/default/files/forms/pdf/13-585a.pdf) |
| Big toe | 70 to 90 up expected; 35 to 40 needed for walking | [QUT podiatry](https://podiatry-anatomy-app.qut.edu.au/content/joints/1st-mtp-joint-rom.html) |
| Elbow | hinge, 0 to about 145 to 150; no back-bend (measured 1 to 5 degrees) | [CDC](https://archive.cdc.gov/www_cdc_gov/ncbddd/jointROM/index.html) |
| Forearm twist | about 77 to 82 palm-down, 85 to 91 palm-up; done by the forearm bones | [CDC](https://archive.cdc.gov/www_cdc_gov/ncbddd/jointROM/index.html) |
| Wrist | bend 70 forward, 60 back; 20 toward thumb, 30 toward little finger; no twist | [Wikipedia: Wrist](https://en.wikipedia.org/wiki/Wrist) |
| Shoulder | arm raise about 170; shoulder blade follows at about 1 degree per 2 of arm | [CDC](https://archive.cdc.gov/www_cdc_gov/ncbddd/jointROM/index.html), [Ludewig](https://pmc.ncbi.nlm.nih.gov/articles/PMC2657311/) |
| Neck | 64 forward, 63 back, 49 side, 85 turn each way | [Anatomy Standard](https://anatomystandard.com/biomechanics/spine/rom-of-spine.html) |
| Mid-back | 26 forward, 22 back, 30 side, 47 turn each way | same |
| Lower back | 65 forward, 31 back, 30 side, 15 turn each way | same |
| Fingers | middle knuckle 100, end knuckle 80; grip pose about 61, 60, 39 | [Wikipedia: Interphalangeal joints](https://en.wikipedia.org/wiki/Interphalangeal_joints_of_the_hand), [Hume](https://europepmc.org/article/MED/2324451) |

Not found in any fetched source, so do not fill from memory: shoulder inward and outward rotation, the base finger knuckle's limits, and thumb base ranges.

For look-at, stay far inside these ends. Real turning uses 15 to 30 degrees of head lead, and the trunk does not lead at all. Share a look across spine, neck and head with most of the turn in the neck and almost none in the lower back, and cap head turn speed well under the 137 to 272 degrees a second measured for deliberate on-the-spot turns.

### Godot classes to use

| Job | Class | Note |
|---|---|---|
| Body | `CharacterBody3D` with `CapsuleShape3D`, floating mode | capsules get no margin under Jolt; avoid cylinders |
| Ground and obstacle probes | `PhysicsDirectSpaceState3D.cast_motion`, `get_rest_info`, `intersect_shape`; `PhysicsBody3D.test_move` | see the traps below |
| Clip blending | `AnimationTree` with `AnimationNodeStateMachine`, `AnimationNodeBlendSpace1D` or `2D` using `SYNC_MODE_CYCLIC_MUTABLE`, `AnimationNodeOneShot` | `deterministic` is on by default, so include a RESET animation |
| Clip alignment | `AnimationNodeAnimation` custom timeline with `start_offset` and `stretch_time_scale` | lines up feet between walk and run |
| Root motion | `AnimationMixer.root_motion_track`, `root_motion_local`, `get_root_motion_position`, `get_root_motion_rotation` | `RootMotionView` to inspect in the editor |
| Contact times | `Animation` markers | read before playing |
| Limb IK | `TwoBoneIK3D` with pole targets | exact and repeatable |
| Hand or prop targets | `ModifierBoneTarget3D`, `BoneConstraint3D` with a node reference | |
| Head and spine look | `LookAtModifier3D` | parent before child |
| Twist and pops | `BoneTwistDisperser3D`, `LimitAngularVelocityModifier3D` | |
| Custom corrections | a script extending `SkeletonModifier3D`, overriding `_process_modification_with_delta` | apply 100 %; let `influence` blend |
| Ragdoll | `PhysicalBoneSimulator3D`, `PhysicalBone3D` with cone and hinge joints | no motors |
| Retarget | `BoneMap`, `SkeletonProfileHumanoid` | at import |

Avoid `SkeletonIK3D` and the bone "global pose override" calls (deprecated), custom animation tree nodes in script (the old hook is deprecated and the new one is marked experimental), and the iterative IK solvers for arms and legs (rate-limited by default, so they lag fast targets).

### Jolt pitfalls to design around

**Floor and wall flags are unreliable.** Under Jolt, contacts that do not oppose the motion are dropped. Find the ground with your own downward probe every tick and do not trust `is_on_floor` or `is_on_wall`.

**There is no built-in step-up.** Either float the capsule or write the sweep; the engine will not do it.

**Seams between separate colliders cause bumps.** Edge smoothing does not work across bodies. Walkable ground should be one collider per reasonably large section, as a triangle mesh with shared edges and no T-junctions.

**Triangle meshes are hollow and one-sided.** Overlap tests inside or behind them read as empty, and large overlap shapes miss their middles. Sweep small shapes from the open side, and give climbable objects box or convex colliders or back-face collision.

**Rays slip on shared edges.** Use a thin sphere cast for anything that must not miss, such as ground and ledge tops.

**A cast ignores what it starts inside.** Start every probe from a place known to be free, inside the character's own capsule.

**A zero-length cast returns nothing.** "Is this space free" is `intersect_shape`, not `cast_motion`.

**Perfectly aligned curved shapes are slow.** Offset probes by a millimetre.

**Overlaps clear slowly.** One movement test removes about 87 % of an overlap (inferred from 4 passes at 40 %). After changing capsule size for crouch, test that the standing capsule fits before standing up.

**Platforms.** Rotating platforms make the character drift, and floor snap on a moving platform can catapult it. Keep vertical speed at zero while grounded, and leave moving platforms out until the core passes.

**Tick rate.** Stay at 60. Higher rates multiplied cost sharply in the one phone report, and smaller steps made the contact filter fault more often before 4.7.

**Separate physics thread.** Godot calls it experimental with Jolt. Leave it off.

**World size.** Keep play within about 5 km of the origin, or plan for origin shifting.

**Ragdoll.** Jolt ignores soft-limit settings on joints, so limits are hard; solver quality is raised with Jolt's own velocity and position step settings, since Godot's old solver-iterations setting does nothing under Jolt.

### Build order: nothing starts until the stage before it passes

Five attempts failed, and the usual cause of that pattern is building animation on an unproven body, then being unable to tell which layer is at fault. So: one stage at a time, each ending in a test that a non-programmer can watch and mark pass or fail. Record the result. If a later stage breaks an earlier test, stop and fix that first. The numbers in the tests are proposed targets.

**Stage 0. The test course and the instruments.** Build a grey-box course with every obstacle at a labelled real size: kerbs at 0.10, 0.15 and 0.20 m; stairs with 0.18 m risers and 0.28 m treads; single steps every 0.05 m from 0.10 to 0.60 m; ramps at 5, 10, 19, 30 and 45 degrees; walls at 0.5, 0.8, 1.1, 1.4, 1.8, 2.2, 2.6 and 3.0 m, each thin and deep; gaps of 0.5, 1.0, 1.5 and 2.0 m; beams 0.25, 0.10 and 0.05 m wide; door frames and wall gaps 0.4, 0.5, 0.6 and 0.8 m wide; overhangs at 1.9, 1.7 and 1.2 m; a floor made of many separate collider pieces and the same floor as one mesh. Add an on-screen readout: ground state, speed, body height, and a graph of height over time. Add a replay tool that feeds recorded stick input, so the same run can be repeated after every change.
*Pass when:* every obstacle shows its label, the readout works with a plain test body, and a recorded run plays back the same path twice.

**Stage 1. The body alone, shown as a bare capsule. No character, no animation.**
*Build:* the floating capsule, ground probe, height spring, gravity, four ground states, speed spring, slope limit, slide on too-steep ground.
*Pass when, all visible on the course:*
- It walks up and down every kerb and the stairs with a height graph that has no step larger than a few centimetres between ticks, at walk and run speed.
- It climbs single steps up to the chosen limit (0.30 m) and is stopped by every step above it, with no creeping up over time.
- It walks the 5, 10 and 19 degree ramps at steady speed, and slides off the ramps above the chosen limit.
- Run along and into walls at every angle for a minute: no sticking, no jitter, no speed gain.
- Cross the many-piece floor and the one-mesh floor: the height graph is flat on both. If the many-piece floor bumps, the rule "one collider per section" becomes a map rule.
- Walk off every ledge: state goes to "in air" at once and back to "on ground" on landing.
- A scripted random walk runs for ten minutes without getting stuck, falling through the floor or leaving the course.
- The readout's ground state matches what you see at all times.
If the floating capsule cannot pass, switch to the full-height capsule with the up-forward-down sweep and rerun the same tests.

**Stage 2. Import proof, in an empty scene.**
*Build:* the pipeline above for the character and three clips: idle, walk, run. Then one climb clip to settle the vertical root question.
*Pass when:* every bone in the map is green; the character stands in a clean T-pose at 1.76 m (or its real height) with feet on the grid; each clip plays with no arm or leg passing through the body and no twisted joint; with the root track set, the character stays on the spot and the root motion grid shows steady forward travel with no side-to-side wobble; the measuring tool prints a speed for walk and run that falls inside human ranges (walk near 1.3 to 1.75 m/s, run near 2.5 to 4.5 m/s); and for the climb clip, one of the two vertical methods lifts the character onto a box of the clip's native height with hands landing on the edge.

**Stage 3. Idle, walk, run on the proven body.**
*Build:* the animation tree with a speed blend space, playback matched to body speed from the measured clip speeds, walk and run lined up on the same foot, turn-rate limit, slow-down in tight turns, a few degrees of lean from speed and turn radius. Decide physics interpolation here.
*Pass when:* with a foot marker drawn on the ground, a planted foot drifts less than about 2 cm at steady walk and run; blending from walk to run shows no double step; all Stage 1 tests still pass with the character attached; the on-screen walk speed is within the measured human band; a full-stick start reaches walk speed in about three steps, not instantly; and the motion looks the same at 30 and 60 frames a second.

**Stage 4. Feet and head.**
*Build:* pelvis offset and leg IK from foot probes; look-at for head, neck and spine with the limits above.
*Pass when:* on the stairs and the 10 and 19 degree ramps both feet rest on the surface with no foot inside or floating above it by more than about 2 cm; knees never bend backward on any obstacle (step through frame by frame on the stairs); on flat ground turning IK on and off changes nothing visible; the head leads a turn and never passes its limit when the target goes behind.

**Stage 5. Starts, stops, turns.** Optional before traversal, required for the Rockstar feel.
*Build:* start, stop and turn-on-the-spot clips, chosen by direction and by which foot is forward.
*Pass when:* stopping from a walk takes one to two steps and from a run several, with no slide after the feet plant; a 180 degree turn on the spot takes about three steps; releasing and re-pressing the stick mid-stop recovers without a pop.

**Stage 6. Crouch.**
*Build:* crouch idle and walk, the smaller capsule, the fit test before standing.
*Pass when:* the character passes under the 1.2 m overhang crouched and cannot stand up beneath it; standing up in the open is instant; crouch speed is about half walk speed; Stage 1 tests pass in crouch.

**Stage 7. Detection only. No clips.**
*Build:* the measuring routine and a debug drawing of its record (edge line, top height, depth, landing point, fit box).
*Pass when:* at every wall, step and gap on the course, approached straight on and at 30 degrees, at walk and run, the drawn height is within 5 cm of the label and the depth within 10 cm; thin walls are reported thin and deep ones deep; nothing is reported on open ground; a wall with no headroom above it is reported as blocked; a hundred approaches in the replay tool give a hundred correct records. This stage is the one earlier attempts most likely skipped. Do not skip it.

**Stage 8 onward. One traversal move per stage.** Each move is built the same way (align, play, fit, hand IK, hand back) and passes the same four tests before the next is started:
- it plays on every course obstacle inside its height band and is refused on every obstacle outside it;
- hands rest on the edge within about 3 cm and feet land on the ground, checked on the lowest, middle and highest obstacle of the band;
- the body ends where the detection record said it would, standing on ground, in the right ground state, moving at the clip's exit speed;
- cancelling is impossible mid-move and every earlier stage's tests still pass.

Suggested order, easiest and most used first:

| Stage | Move | Band |
|---|---|---|
| 8 | step down and walk off a low edge | drops to 0.30 m, then to 1.0 m with a landing |
| 9 | high step up | 0.30 to 0.50 m |
| 10 | vault over a thin obstacle from a run | 0.50 to 1.10 m |
| 11 | step vault or climb on from a walk or stand | 0.50 to 1.10 m |
| 12 | mantle | 1.10 to 1.45 m |
| 13 | standing grab and climb up | 1.45 to 2.10 m |
| 14 | jump, grab and climb up | 2.10 to 2.60 m |
| 15 | turn, hang and drop | ledges above 1.0 m |
| 16 | jump across a gap, with landing and roll by height | gaps over about 0.9 m |
| 17 | narrow surfaces: beam walk and wall-ledge sidle | 0.10 to 0.25 m wide |
| 18 | shoulder turn and sideways squeeze through gaps | 0.25 to 0.60 m wide |
| 19 | ragdoll on hard impact and long fall, with get-up by lying direction | |
| 20 | partial ragdoll hit reactions | |
| 21 | cover: low and high, enter, peek, exit | low 0.8 to 1.1 m, high above head |
| 22 | doors: push, then pull | |
| 23 | cars: bonnet slide, then entry and exit | |

Cars come last because the human data for getting in and out could not be sourced, so that stage will rest on clip measurement alone. Phone testing of each stage follows the desktop pass.

## Part 3. Your Mixamo clips, measured

Added 25 Nov 2026, after the shared folder of clips arrived. Unlike Parts 1 and 2, this part is first-hand measurement: every one of the 408 files (356 loose, 52 in three packs) was downloaded and read directly, and the position of the hips, hands, feet and head was computed for every frame. The full table, one row per file, is in `research_notes/Hybrid character traversal study/clip_measurements/clip_measurements.csv`, next to the script that produced it. Nothing was played in Godot or Blender. The two game files in the folder (`NewMap_walk_test`, a `.dll`) were not opened.

Checks on the method: every standing clip puts the feet at 0.00 m and the head top at 1.81 m, and the stair clips come out at two even steps. Hand heights below are wrist joints; the gripping palm is about 0.08 m further along. Clip names are the file names in the folder, some of which you have renamed.

### The files are consistent, and that removes the largest unknown

- **One skeleton, one body.** All 408 files have the 65-joint Mixamo skeleton with identical limb lengths (hip to ankle 0.889 m, shoulder to wrist 0.562 m). They were all downloaded against the same character, so they can share one import recipe.
- **The character is 1.81 m to the top of the head**, with hips at 1.03 m. Part 2's bands were written for 1.76 m; the difference is 3 % and inside the tuning range.
- **Format.** All are binary FBX 7.7, 30 frames a second, in centimetres, with bone-aligned joints. 401 are without skin; 7 carry a mesh (`Idle`, `Idle (1)`, `Standing Idle`, `Orc Idle`, `Idle To Sprint`, `Running (4)`, `Running (5)`).
- **None is "in place".** Travel is in the hips in every moving clip, which is what the root-bone step in the pipeline needs.
- **54 files are duplicates** of another file under a different name (`Walking` and `Walking (2)`, `Stop Walking` and `L_Stop_Walking`, the three `Falling To Landing` files, and so on). There are 354 distinct motions.

### Walking and running: usable, but faster than a person and not lined up with each other

| Clip | Loop length | Travel per loop | Speed | Head height |
|---|---|---|---|---|
| Old Man Walk | 1.27 s | 0.51 m | 0.40 m/s | 1.65 to 1.75 m |
| Walking With Shopping Bag | 1.27 s | 1.34 m | 1.06 m/s | 1.75 to 1.78 m |
| Walking (1) | 0.97 s | 1.62 m | 1.68 m/s | 1.76 to 1.80 m |
| Walking | 1.03 s | 1.84 m | 1.79 m/s | 1.72 to 1.79 m |
| Running (3) | 0.83 s | 2.14 m | 2.57 m/s | 1.69 to 1.80 m |
| Slow Run | 0.73 s | 2.29 m | 3.13 m/s | 1.56 to 1.71 m |
| standard run (Locomotion Pack) | 0.73 s | 3.24 m | 4.42 m/s | 1.54 to 1.64 m |
| Running | 0.63 s | 3.75 m | 5.92 m/s | 1.69 to 1.77 m |
| Sprint | 0.53 s | 3.29 m | 6.17 m/s | 1.52 to 1.64 m |

- **Each loop is one full stride** (a left step and a right step).
- **The main walk is a brisk walk.** At 1.79 m/s it is above the comfortable human range of 1.3 to 1.45 m/s in Part 1 and at the low end of maximum walking speed. Played at about 0.75 speed it gives 1.35 m/s. Its stride of 1.84 m is also longer than the 1.5 to 1.7 m of the human data.
- **`Running` and `Sprint` are near-athlete speeds.** `Running (3)` and `Slow Run` sit in the human jogging range (2.5 to 3.5 m/s).
- **The loops start on different feet.** `Walking` starts with the right foot forward, `Running`, `Slow Run` and `Sprint` with the left, `Running (1)` with the right. Blended as they are, walk and run would fight each other. Each clip needs a start offset in the table so that all loops begin on the same foot; this is a Stage 3 task.
- **Turning arcs exist for one side only at a walk.** `Running Left Turn` and `Running Right Turn` curve 35.7 degrees per stride at 4.0 m/s. `Walking Left Turn` curves 36 degrees at 1.4 m/s; there is no walking right turn, so it must be mirrored.
- **Strafing** exists only in the Locomotion Pack: walk strafe 1.73 m/s, run strafe 4.52 m/s, both sides.

### Starts, stops and turns on the spot: a full set, with inexact angles

| Clip | Length | Travel | Turn |
|---|---|---|---|
| Start Walking | 2.93 s | 1.99 m | |
| Female Start Walking | 1.87 s | 1.74 m | |
| Stop Walking | 3.00 s | 1.21 m | |
| Female Stop Walking | 1.53 s | 1.51 m | |
| Idle To Sprint | 0.80 s | 1.67 m | |
| Run To Stop | 0.90 s | 0.81 m | |
| Left Turn 90 | 0.93 s | none | 90.0 degrees |
| Right Turn 90 | 0.93 s | none | 102.6 degrees |
| Left Turn | 0.93 s | none | 122.6 degrees |
| Right Turn | 1.00 s | 0.14 m | 95.5 degrees |
| Walking Turn 180 | 1.00 s | 0.13 m | 180.0 degrees |
| Running Turn 180 | 0.67 s | none | 180.0 degrees |
| Running To Turn 180 | 2.27 s | 4.01 m | 188.4 degrees |

- **`Start Walking` and `Stop Walking` are slow** (about 3 s each). The human data says walking speed is steady within about three steps and a walk stops in under two; the "Female" pair is closer to that.
- **Turn clips do not turn exact amounts.** "Right Turn 90" turns 102.6 degrees. The turn in each clip must be scaled to the angle the game needs, the same way a climb is scaled to a height.
- `Run To Stop Without climb` is a run that ends with both hands raised to 1.45 m, as if stopping against a wall. It is not a plain stop.

### Crouch: the idle and the walk are at very different heights

| Clip | Head height | Hips | Speed |
|---|---|---|---|
| Crouching Idle | 0.94 m | 0.50 m | |
| Crouch cover idle | 1.28 m | 0.59 m | |
| Sneaking Forward | 1.29 to 1.37 m | 0.80 m | 2.22 m/s |
| crouched sneaking left / right (pack) | 1.33 to 1.38 m | 0.73 to 0.76 m | 1.06 to 1.13 m/s, sideways |
| Crouched Walking | 1.35 to 1.46 m | 0.89 m | 1.42 m/s |
| Standing To Crouched / Crouched To Standing | | | 0.63 s each |

**There is no moving clip lower than 1.29 m.** `Crouched Walking` is a stoop, not a crouch, and is faster than a real crouch walk (Part 1: a 45 degree knee crouch halves walking speed). So the crouched body shape must be about 1.5 m tall, the Stage 6 test should use an overhang at about 1.5 m, not 1.2 m, and going under anything lower needs a clip that is not in the folder.

### Stairs: two steps per clip, on steep stairs

| Clip | Length | Up or down | Forward | Per step |
|---|---|---|---|---|
| Ascending Stairs | 1.37 s | up 0.49 m | 0.52 m | riser 0.245 m, tread 0.26 m |
| Walking Up The Stairs | 1.20 s | up 0.50 m | 0.51 m | riser 0.25 m, tread 0.255 m |
| Running Up Stairs | 0.60 s | up 0.48 m | 0.53 m | riser 0.24 m, tread 0.265 m |
| Descending Stairs | 0.93 s | down 0.51 m | 0.47 m | riser 0.255 m, tread 0.235 m |

These were captured on stairs with a riser of about 0.25 m, steeper than the 0.18 m of public stairs and above even the 0.22 m maximum for a UK private stair. On city stairs they will need the feet corrected by leg IK, or the simpler route in Part 2: play the normal walk on the stairs and let the foot IK of Stage 4 do the work. There is no running-down-stairs clip.

### Going up: what each clip natively fits

"Native height" is the height the feet end at above where they started, which is the obstacle the clip was captured on.

| Clip | Length | Native height | Forward travel | What it is |
|---|---|---|---|---|
| Jumping (2) | 1.23 s | 0.62 m | 1.53 m | two-step approach and a jump onto a box; no hands |
| Running Jump Climb | 2.17 s | 1.00 m | 2.29 m | run, jump, feet land on top at 0.8 s, stand up; no hand support |
| Braced Hang To Crouch | 1.13 s | rises 1.5 m from the hang (see the correction below) | 0.59 m | starts hanging with feet braced on the wall, ends crouched on top |
| Stand To Freehang | 1.70 s | hands to 2.29 m | 0.41 m | from standing, jump and catch a ledge; ends in the hang |
| Hanging Idle | 2.33 s loop | hands at 2.29 m | | toes hang 0.28 m above the ground the clip assumes |
| Climbing single | 3.83 s | 2.42 m | 0.41 m | from the hang, pull up to a crouch on top |
| Sprint To Wall Climb | 1.80 s | 2.46 m | 3.33 m | 2 m run-up, hands hit the top at 0.67 s (wrists 2.44 m), on top by 1.6 s |
| Climbing double | 3.83 s | 2.11 m | 4.14 m | 3 m run, then two ledges of about 1.05 m each |
| Jump To Hang | 2.00 s | hands 1.2 m above take-off | 1.10 m | a jump across a gap ending in a hang |

Set against the height bands of Part 2:

| Band | Clip in the folder | Fit |
|---|---|---|
| up to 0.30 m, walk over | none needed | covered by the body and foot IK |
| 0.30 to 0.50 m, high step | none | **missing** |
| 0.50 to 1.10 m, climb on | Jumping (2) at 0.62 m, Running Jump Climb at 1.00 m | covered at both ends of the band, as jumps |
| 0.50 to 1.10 m, vault over | Vault Over Box to Cover, Jumping Over Into Combat | **no clean vault**, see below |
| 1.10 to 1.45 m, mantle | none | **missing**; nearest are Running Jump Climb stretched up or Braced Hang To Crouch stretched down |
| 1.45 to 2.10 m, grab and climb | Braced Hang To Crouch | the climb-up exists; the clip from standing into the braced hang is on Mixamo but not in the folder |
| 2.10 to 2.60 m, jump, grab, climb | Stand To Freehang, Hanging Idle, Climbing single (ledge about 2.3 to 2.4 m); Sprint To Wall Climb at 2.46 m | covered, from a stand and from a run |
| 2.60 to 3.00 m, running wall-run | Sprint To Wall Climb stretched from 2.46 m | a stretch of up to 22 %, to be judged by eye |

Three findings matter for the build:

- **The hang chain joins up.** `Stand To Freehang` ends in exactly the pose `Hanging Idle` starts in (hips 1.32 m, wrists 2.29 m), and `Climbing single` starts within 0.08 m of it. That is a ready-made sequence for the 2.10 to 2.60 m band.
- **`Climbing single` takes 3.83 s**, which is slow for a game; `Sprint To Wall Climb` reaches the same height in 1.8 s. Expect to play the slow one faster.
- **The hands are not fixed in the climb clips.** In `Braced Hang To Crouch` the wrists rise from 1.45 m to 1.77 m during the part where the hands should be planted on the edge, and in `Climbing single` from 2.21 m to 2.46 m. So the start of each clip and its end disagree about where the ledge is by 0.15 to 0.25 m. Why is not known from the files. This confirms the fitting method in Part 2: the hands must be pinned to the measured ledge with arm IK from contact to release, and the body moved to suit, or they will visibly slide.

**Vaults.** There is no clip of a plain hand vault over a thin obstacle. The two candidates:
- `Vault Over Box to Cover` (3.53 s): runs 1.3 m, clears a box with the feet passing at about 1.0 m, then spins and drops into a crouch behind cover. Only its first 1.3 s is a vault.
- `Jumping Over Into Combat` (4.17 s): stands for a second, then hurdles with the feet clearing 0.74 to 0.91 m and lands in a fighting stance. Only about 1.0 to 2.6 s is the jump.

Either can be cut down, but a proper vault clip (one hand on the obstacle, from a run, landing into a run) should be added to the folder before Stage 10.

### Going down: the landings are well covered, the hang-and-drop is not

| Clip | Length | Drop | Forward | What it is |
|---|---|---|---|---|
| Climbing Down (2) | 3.43 s | 0.66 m | 0.72 m | steps down off a low ledge, slowly |
| Jumping Down (1) | 2.30 s | 0.93 m | 2.01 m | jumps out and down, ends in a deep crouch (does not stand up) |
| Falling To Landing | 1.07 s | 1.03 m | 0.08 m | feet touch at 0.27 s, standing by 0.9 s |
| Jumping Down (2) | 3.07 s | 1.13 m | 1.57 m | steps off, lands, stands |
| Jumping soft landing | 2.63 s | 1.16 m | 1.33 m | jump off with a soft landing |
| Climbing Down | 3.13 s | 1.55 m | 0.32 m | turns round on the edge (130 degrees), lowers, ends standing |
| Hard Landing | 2.50 s | 2.08 m | 1.03 m | feet touch at 0.6 s, hands on the ground, standing at 2.5 s |
| hard landing (pack) | 2.00 s | 0.42 m | 0.17 m | the landing and recovery only |
| falling to roll (pack) | 1.80 s | 0.42 m | 3.05 m | lands into a forward roll |
| Falling Idle | 0.70 s loop | | | the in-air pose |

These line up with Part 2's drop bands: about 1.0 m for the soft landing, about 2.0 m for the hard landing, a roll for a running drop, and an in-air loop to cover any height in between. **Missing:** a turn, hang and drop from a high ledge. `Climbing Down` is the closest, from 1.55 m. There is also no clip that goes from standing on top into the hang.

### Jumps

| Clip | Length | Forward | Hip rise | Notes |
|---|---|---|---|---|
| Jump | 2.17 s | none | 0.27 m | standing jump; dips to 0.75 m first |
| Jumping (1) | 1.90 s | none | 0.62 m | a high tucked jump |
| Running Jump | 0.90 s | 4.45 m | 0.47 m | one run stride with a leap of about 2.7 m in it; loops back into the run |
| Jump (1) | 1.00 s | 4.18 m | 1.10 m | a very high leap, feet at 1.39 m |

The standing `Jump` rises less than the 0.41 to 0.50 m average in Part 1, so it is a safe, unathletic jump. `Jump (1)` rises 1.10 m, which is beyond the human figures; treat it as stylised.

### Cover, doors, cars, ladders, falls

- **Cover.** A working set: `Cover Idle` (standing, head at 1.65 m), `Crouch cover idle` (head at 1.28 m), `stand to cover` in two variants (1.2 m approach, 111 and 133 degree turn), `cover to stand`, `left / right cover sneak` (1.34 m per loop at 1.18 m/s), `Crouch Cover To Cover` (2.07 m sideways in 1.57 s), `Crouch Cover Turn`, `Standing Cover Turn`, `Crouch Look Around Corner`, `Sneak off the cover`. One mismatch: in crouch cover the head is at 1.28 m, so behind the 0.8 to 1.1 m low cover of Part 2 the head shows by 0.2 m or more. Low cover for these clips needs to be about 1.3 m, or the pose lowered.
- **Doors.** `Open Door Outwards` takes 4.1 s over 2.21 m with the wrist reaching 1.17 m at 2.2 s; `Opening Door Inwards` takes 6.4 s over 1.75 m with the wrist at 1.10 m at 4.2 s. Both are slower than the 2 to 3 s (push) and 4 s (pull) of Part 1. `Opening slide door` and `Opening locked` are on the spot.
- **Cars.** `Entering Car` (5.47 s) walks 1.9 m, turns 97 degrees and sits with the hips at 0.88 m and the feet on a floor 0.29 m up. That is a tall seat, more van or truck than saloon; a normal car will need the sitting height brought down. `Exiting Car` (5.8 s) is the reverse. There is no bonnet slide.
- **Ladders.** A full set: `Start Climbing Ladder` (feet to 0.99 m), `Climbing ladder slow` (1.17 m in 2.97 s), `Climbing Ladder fast` (0.50 m in 0.77 s), `Climbing To Top ladder` (up 1.63 m and off the top), `Climbing Down ladder` (1.26 m in 2.0 s).
- **Falls and getting up**, for the ragdoll stages: falls (`Tripping`, `Stumble Backwards`, `Fall Flat`, `Falling Down on ass`, `Hit By Car`, `Shoulder Hit And Fall`, `Knocked Out`), standing reactions (`Shove Reaction`, `Hit Reaction`, `Hit To Body`, `Head Hit`, `Jogging Stumble`), lying loops (`Fallen Idle`, `Laying Idle`) and recoveries (`Getting Up` 2.7 s, `Standing Up` 1.67 s, `Push Up To Idle` 3.1 s from face down).

### What is missing from the folder

In build order, these are the clips the folder lacks. The next section checks each against the Mixamo catalogue.

1. A walk in the 1.3 to 1.45 m/s range (or accept `Walking` slowed to 0.75).
2. A high step up for 0.30 to 0.50 m.
3. A plain hand vault from a run, and a step vault from a walk.
4. A mantle for 1.10 to 1.45 m.
5. Standing into a braced hang, for 1.45 to 2.10 m.
6. From standing on top: turn, lower into a hang, and drop.
7. Shimmy along a ledge, left and right.
8. A real crouch walk with the head near 1.0 m.
9. Balance walking on a narrow beam, a sideways wall-ledge sidle, and a sideways squeeze through a gap.
10. Running down stairs.
11. A bonnet slide.


### The missing clips, checked against the Mixamo catalogue

Added later on 25 Nov 2026. The Mixamo site itself needs a login that this session does not have, so the check was made against a public copy of the catalogue: a Hugging Face dataset that lists 2,446 Mixamo animations by name and description ([dataset index](https://huggingface.co/datasets/Linzhan/Mixamo-Animations-Characters/resolve/main/metadata.csv)). It is a third party's copy, so a name may differ slightly on the live site. Many Mixamo clips share one name ("Jumping", "Climbing", "Walking"), so the description is what identifies a clip; search Mixamo by the name and pick the one whose description matches.

The candidate clips were also downloaded from that dataset and measured with the same script. They are on a different, shorter-legged body (hip to ankle 0.83 m against your 0.889 m), so the heights below are about 7 % lower than they will be on your character. Their rows are in `clip_measurements/catalogue_candidates.csv`.

| # | Missing | On Mixamo? | Name on Mixamo: description | Measured on the catalogue body |
|---|---|---|---|---|
| 1 | Slower walk | yes | Walking: "Male Standard Walk" | 1.04 m/s, 1.23 s loop |
| 2 | High step, 0.30 to 0.50 m | partly | Jumping: "Male Stepping Onto Platform" | steps (not jumps) onto 0.59 m in 1.37 s; nothing lower was found |
| 3 | Hand vault | yes | Jumping: "Male Jumping Over An Obstacle With 1 Hand Planted" | 1.17 s at 4.2 m/s, feet clear 1.19 m |
| 3 | Two-hand vault | yes | Jumping: "Male Jumping Over An Obstacle With 2 Hands Planted" | 1.2 s at 3.5 m/s, feet clear 1.38 m |
| 3 | Vault from a walk | partly | Jumping: "Step Up To Jump Over Object" | 2.87 s, feet clear 1.0 m, turns 95 degrees at the end |
| 4 | Mantle, 1.10 to 1.45 m | **no** | nothing found | |
| 5 | Standing into braced hang | yes | Idle To Braced Hang: "Jump To A Braced Hang From Standing Idle" | 1.27 s, wrists to 2.27 m, feet braced at 0.96 m |
| 6 | From on top, down into a hang | yes | Drop To Freehang: "Standing Drop To Freehang" | 2.4 s, turns round and lowers 2.04 m |
| 6 | Let go and land | yes | Freehang Drop: "Freehang Drop To Standing" | 1.33 s, feet drop 0.4 to 0.5 m |
| 6 | Let go from braced hang | yes | Braced Hang Drop: "Braced Hang Drop To Standing" | 1.67 s, feet drop 1.26 m |
| 7 | Shimmy, braced | yes | Braced Hang Shimmy: "Left Braced Hang Shimmy" and "Right Braced Hang Shimmy" | 1.17 s, 0.57 m sideways per cycle |
| 7 | Shimmy, free hang | yes | Left Shimmy / Right Shimmy: "Free Hanging Shimmy Left / Right" | 1.37 s, 0.37 m per cycle |
| 7 | Switch between hangs | yes | Braced To Free Hang; Free Hang To Braced | about 1 s each |
| 8 | Low crouch walk, head near 1.0 m | **no** | Crouch Walk Forward: "Walking Forward While Crouched" is the lowest found | head at 1.31 to 1.35 m, no lower than what you have |
| 9 | Narrow-beam balance walk | **no** | nearest: Walking: "Male Careful Walk" | 0.83 m/s, an ordinary slow walk |
| 9 | Losing balance on an edge | yes | Wobbling: "Wobbling On A Ledge"; Edge Slip: "Slipping Off An Edge Then Regaining Balance" | on the spot |
| 9 | Wall-ledge sidle, gap squeeze | **no** | nothing found | |
| 10 | Running down stairs | yes | Descending Stairs: "Running Down A Set Of Stairs" | 0.4 s, down 0.47 m |
| 11 | Bonnet slide | **no** | only Running Slide: "Running To Slide And Back To Running", a slide along the ground | 6.4 m in 1.53 s |

Also in the catalogue and useful: crouch walking left, right and backwards ("Crouch Walk Left / Right / Back"), crawling on hands and knees ("Crawling") for anything lower than the crouch, hops between hangs ("Braced Hang Hop Left / Right / Up", "Free Hang Hop Left / Right"), and "Freehang Climb: Freehang Climb To Standing" (3.87 s), which ends standing where your `Climbing single` ends crouched.

What this means for the build:

- **Update:** these clips have since been downloaded and measured; see "The 18 extra Mixamo clips, measured" below.
- **Seven of the eleven gaps can be filled from Mixamo:** the slower walk, the vaults, standing into the braced hang, the hang-and-drop, the shimmy, and running down stairs. Download them against the same character as the rest.
- **Four cannot, and need another answer:**
  - *Mantle (1.10 to 1.45 m):* stretch `Running Jump Climb` upward, or jump to a braced hang and climb, and judge by eye.
  - *Low crouch walk:* keep the crouched body at about 1.5 m, and use the crawl for lower gaps if they matter.
  - *Beam walk, sidle and squeeze:* build them from clips you have plus procedure: the careful walk with the feet narrowed and arms raised by IK for beams, and the strafe walk for sidling and squeezing.
  - *Bonnet slide:* leave it out, or source it elsewhere.
- **A correction.** The first version of this part gave `Braced Hang To Crouch` a native height of 1.70 m. That was a misreading: its numbers are measured from where the hang starts, not from the ground: the catalogue's entry clip puts the hands of a braced hang at about 2.3 to 2.4 m with the feet braced about 1.2 m below them. So this clip is not tied to 1.70 m. It suits any ledge high enough for the feet to be off the ground, roughly 1.6 m and up, and the height is set by how the character gets into the hang.

### The four gaps Mixamo cannot fill, generated with Kimodo

Added later on 25 Nov 2026. Kimodo is NVIDIA's text-to-motion model; it was run through Replicate (`sprited/kimodo`, an unofficial deployment, model `Kimodo-SOMA-RP-v1.1`). You type a sentence and it returns a motion. It can export onto a Mixamo skeleton, so one of your own files with a mesh (`Standing Idle.fbx`) was uploaded to Replicate as the target character; that file stays on Replicate for 24 hours.

24 takes were generated and measured with the same script as everything else. Seven were kept. They are on your exact skeleton (same 65 joints, same limb lengths), 30 frames a second.

| File | Length | Travel | Height | What it is |
|---|---|---|---|---|
| KM Crouch Walk Low | 3.97 s | 3.87 m forward, 0.98 m/s | head 1.12 to 1.26 m | a deep crouch walk, about 0.2 m lower than Mixamo's lowest |
| KM Mantle 0.82m | 4.97 s | 1.23 m forward | feet end 0.83 m up | hands up, jump, tuck onto a ledge, stand |
| KM Mantle 0.96m | 4.97 s | 0.90 m forward | feet end 0.96 m up | the same, a little higher |
| KM Mantle 1.16m | 4.97 s | 2.23 m forward | feet end 1.17 m up | the highest take; the only one inside the 1.10 to 1.45 m band |
| KM Beam Walk | 4.97 s | 4.50 m forward, 0.91 m/s | | slow walk, arms held out to the sides |
| KM Ledge Sidle Left | 3.97 s | 3.25 m to the left, 0.82 m/s | | upright side-steps with the arms spread low |
| KM Gap Squeeze Right | 3.97 s | 4.89 m to the right, 1.25 m/s | head 1.59 to 1.65 m | hunched side-steps with the arms in |

Their full rows, with the sentence used for each, are in `clip_measurements/kimodo_clips.csv`.

What to know before using them:

- **The bonnet slide failed.** Five takes with two different sentences all produced a run with a hop (the hips never drop to sitting height). Kimodo did not produce a slide, so that gap stays open.
- **Kimodo's FBX export had two faults, both repaired in these files.** It kept the uploaded character's own idle animation on a second layer, and it placed the hips wrongly: the body floated 0.84 to 1.12 m above the ground and planted feet slid up to 0.4 m. The repair removes the extra layer and rebuilds the hip path from Kimodo's own motion data, scaled to your leg length. After it, planted feet stay in place and the lowest joint sits on the ground. The two tools are `clean_kimodo.py` and `fix_kimodo.py` in `clip_measurements/`, for any later takes.
- **The files load in ufbx**, the FBX reader Godot uses. They have not been imported into Godot or played there.
- **They are not loops.** The crouch walk, beam walk, sidle and squeeze are 4 to 5 second walks, not a single clean stride. One stride has to be cut out of each and its ends matched before it can loop.
- **The crouch walk wanders** 0.29 m sideways over its 3.9 m and its feet are less firmly planted than a Mixamo walk (by the same measure: 0.42 m/s of foot movement while planted, against 0.07 for `Walking` and 0.15 for `Crouched Walking`). Foot IK will be needed.
- **The mantles are 5 seconds long** with about a second of standing at each end, and the model had no real ledge: the hands reach up and the body arrives on top, but the hands were never fixed to an edge. Pin them with arm IK as for the Mixamo climbs, and trim the ends.
- **The beam walk stands about 0.15 m above the ground** for part of the clip, as if the model stepped onto a low beam.
- **These files contain your character's mesh**, because Kimodo needs a skinned character to export. Treat them like raw Mixamo files and keep them out of a public repository.
- **Licence:** Kimodo's code is Apache-2.0 and this model is under the NVIDIA Open Model licence, according to NVIDIA's project page ([Kimodo README](https://raw.githubusercontent.com/nv-tlabs/kimodo/main/README.md)), which calls its training data "commercially-friendly". The licence text itself was not read.
- **Replicate credit:** the account has under $5 of credit, which limits it to 6 runs a minute. Each take took 4 to 7 seconds of compute.

### The 18 extra Mixamo clips, measured

Added later on 25 Nov 2026, after the clips from the download list were put in the shared folder. All 18 are on the same body as the rest (hip to ankle 0.889 m), without skin, 30 frames a second. Their rows are appended to `clip_measurements.csv` with the source `loose2`. `Crouch Walk` is the same motion as `Crouched Walking`, so 17 are new.

| Clip | Length | Travel | Height | Notes |
|---|---|---|---|---|
| Walking (4) | 1.23 s loop | 1.34 m, 1.09 m/s | | the slower walk; with `Walking` at 1.79 m/s the two bracket a comfortable 1.3 to 1.45 m/s |
| Vault 1 Hand | 1.17 s | 5.09 m at 4.37 m/s | feet clear 1.23 m | a running vault; this fills the vault gap |
| Vault 2 Hands | 1.20 s | 4.33 m at 3.61 m/s | feet clear 1.43 m | |
| Step Up Vault | 2.87 s | 4.44 m forward, 2.51 m to the right | feet clear 1.02 m | ends turned 95 degrees and well off to one side; only the first part is usable |
| Step Onto Platform | 1.37 s | 1.16 m | feet end 0.61 m up | a step, not a jump; the nearest thing to the high step |
| Jump To Braced Hang | 1.27 s | 0.19 m | wrists to 2.30 m, feet braced at 0.96 m | from standing into the braced hang |
| Braced Hang Shimmy Left / Right | 1.17 s loop | 0.59 m sideways per loop | | clean loops |
| Braced To Freehang | 0.93 s | | | ends in exactly the `Hanging Idle` pose |
| Freehang To Braced | 1.13 s | | | the reverse |
| Freehang Shimmy Left / Right | 1.37 / 1.40 s loop | 0.39 / 0.41 m per loop | | near-clean loops |
| Freehang Climb | 3.87 s | 0.64 m | feet end 2.46 m up | hang to standing on top |
| Drop To Freehang | 2.40 s | turns 225 degrees | starts with feet at 2.47 m | from standing on top, turn and lower into the hang |
| Freehang Drop | 1.33 s | 0.46 m backward | feet drop 0.45 m | let go and land standing |
| Braced Hang Drop | 1.67 s | 0.35 m backward | feet drop 1.27 m | let go from the braced hang and land |
| Run Down Stairs | 0.40 s | 0.48 m | down 0.49 m | two steps of about 0.245 m, like the other stair clips |

What this settles and what it adds:

- **The vault, the hang-and-drop, the shimmies, the braced-hang entry, the slower walk and running down stairs are now covered.** With the Kimodo clips, the only gaps left are the bonnet slide and a native high step for 0.30 to 0.50 m.
- **The free-hang clips agree with each other.** `Stand To Freehang`, `Drop To Freehang`, `Braced To Freehang` and the free-hang shimmies all sit at hips 1.32 m, toes 0.28 m, wrists about 2.28 m, the same as `Hanging Idle`.
- **The braced-hang clips do not agree on height.** Each has the same pose but a different height above its own origin: hips at 1.37 m at the end of `Jump To Braced Hang`, 1.45 m in `Braced To Freehang`, 1.59 m in the shimmies and 1.68 m at the start of `Braced Hang Drop`. Played one after another as they are, the body would jump up or down by as much as 0.31 m. Each clip therefore needs its hand height recorded in the table, and the body placed so the hands sit on the ledge, not so the clip origins match.
- **`Freehang Drop` starts 0.18 m higher than the hang it follows** (hips 1.50 m against 1.32 m), the same kind of mismatch.

### The game's character: the Meshy model, and how far it is from the clips' body

Checked on 25 Nov 2026. The model is `player_v3`, made with Meshy, on the branch `claude/cool-galileo-6y68se` (`assets/people/humanoid/player_v3.glb`, last changed 23 Nov). It was taken from git; nothing was downloaded from Meshy, because this session has no Meshy key (the project notes say the key is saved on a different environment, "NewMap"; this session runs on "Default"). Whether a newer model exists only on Meshy could not be checked. Only the skeleton and file facts were read; the model was not rendered or animated.

The file: 15,614 triangles, one material, 54 joints, no animations. Joint names are Meshy's, close to Mixamo's without the prefix, with two differences that matter: the spine is named the other way up (`Spine02` is the lowest, `Spine` the highest), and there are three joints per finger and no toe-end joints.

Every clip in the folder was made on Mixamo's stock X Bot. Rest-pose measurements of the two bodies:

| | Meshy player_v3 (left / right) | X Bot, the clips' body | Difference |
|---|---|---|---|
| Top of head | 1.81 m (mesh top 1.83 m) | 1.81 m | same height |
| Hips | 1.00 m | 1.03 m | 3 % lower |
| Thigh | 0.380 / 0.383 m | 0.444 m | 14 % shorter |
| Shin | 0.390 / 0.376 m | 0.445 m | 12 to 16 % shorter |
| Hip to ankle | 0.770 / 0.759 m | 0.889 m | 13 to 15 % shorter |
| Ankle joint height | 0.170 / 0.159 m | 0.092 m | 7 to 8 cm higher |
| Toe joint height | 0.052 / 0.039 m | 0.002 m | 4 to 5 cm higher |
| Shoulder to wrist | 0.475 / 0.489 m | 0.561 m | 13 to 15 % shorter |
| Shoulder joints apart | 0.43 m | 0.39 m | 10 % wider |
| Hip joints apart | 0.22 m | 0.26 m | 14 % narrower |

What this means for the build:

- **Same height, different joints.** The two bodies are the same height, but the Meshy rig has shorter leg and arm bones and makes up the leg length with an ankle joint 7 to 8 cm higher. A clip copies joint angles, so the same clip on this body takes strides about 13 % shorter and reaches about 8 cm less with each arm.
- **Feet will slide unless travel is scaled.** If the body moves the distance the clip was made for, the feet cover 13 % less ground. Root travel has to be scaled by the leg ratio (about 0.86), which turns the 1.79 m/s walk into about 1.55 m/s. The clip table should store speeds for this body, not for X Bot.
- **Hands will miss.** Shorter arms on wider shoulders mean hands arrive short of a ledge by up to about 8 cm. This is one more reason the hands must be placed by arm IK.
- **The rig is not symmetric.** The left ankle joint sits 9 cm further back than the right (0.100 m against 0.012 m behind the body's centre line), the left shin is 1.4 cm longer than the right, and the right arm is 1.4 cm longer than the left. A mirrored clip will not look mirrored, and the two feet will plant differently.
- **The ankle joint looks too high.** On X Bot it is 9 cm above the ground; here it is 16 to 17 cm. If that is where the rig put the joint and not where the model's ankle is, the foot will pivot from the wrong place, which shows as standing or running on the heels. This could not be confirmed without looking at the mesh.

(Later the same day this was tested by remaking the character on Meshy; see the next section, which replaces this recommendation.) Recommendation at the time: fix the skeleton before Stage 2. Make it symmetric (mirror one side's joints onto the other) and check the ankle and toe joints against the mesh. Every later test, starting with "a planted foot drifts less than 2 cm", is measured on this skeleton, so its faults would be chased as animation faults. Then record this body's own numbers (leg 0.77 m, arm 0.48 m, hips 1.00 m) in the clip table and scale the height bands of Part 2 by arm reach where they depend on it: the standing-grab limit drops by about 8 cm.

### A remake on Meshy does not change the skeleton's proportions

Tried on 25 Nov 2026, at Yasin's request, with the Meshy key saved on this session's environment. 46 credits were used.

Two things were made:

- **player_v3 rigged again by Meshy on its Mixamo skeleton** (Meshy's rigging now offers a `skeleton_template` of `mixamo`): the same mesh, new joints.
- **player_v4, a new character:** the concept picture redrawn by Meshy's image editor (same man, flat thin-soled shoes, straight trousers, arms out), turned into a 3D model in a T-pose, 15,587 triangles, rigged on the Mixamo skeleton, 1.81 m tall.

| | v3, first rig (left / right) | v3, Mixamo rig | v4, new character | X Bot, the clips' body |
|---|---|---|---|---|
| Hip to ankle | 0.770 / 0.759 m | 0.742 / 0.744 m | 0.756 / 0.756 m | 0.889 m |
| Hip joint height | 0.906 m | 0.897 m | 0.889 m | 0.960 m |
| Ankle joint height | 0.170 / 0.159 m | 0.160 / 0.156 m | 0.139 / 0.139 m | 0.092 m |
| Ankle behind the centre line | 0.100 / 0.012 m | 0.037 / 0.037 m | 0.050 / 0.050 m | |
| Shoulder to wrist | 0.475 / 0.489 m | 0.458 / 0.474 m | 0.473 / 0.477 m | 0.561 m |
| Joints | 54 | 36 | 36 | 65 |

What this shows:

- **The proportions barely moved.** Two different meshes and two different rig types all come out with legs about 0.75 m and arms about 0.47 m, 15 % shorter than X Bot. So an earlier statement in this report, that the body was fine and only the joints were misplaced, was wrong in part: this is simply where Meshy's rigger puts hip, ankle and wrist joints on a clothed character of this height. Generating him again will give the same numbers.
- **What the new rigs do fix is the lopsidedness.** Both are symmetric: the two ankles sit at the same depth, and on v4 the two legs and the two arms match to within 4 mm. v4's flat shoes also bring the ankle joint down 2 to 3 cm.
- **The Mixamo-skeleton rigs have no real fingers.** Asked for fingers, Meshy returned one chain of four joints per hand (named as the middle finger) plus one end bone. The whole hand bends as one piece. The 54-joint v3 file has three joints for each finger, added afterwards in the project.
- **The joint names match the clips exactly** (`mixamorig:Hips` and so on), so the bone map is automatic.

What to do with a body that is 15 % shorter in the limbs than the clips' body. Two routes:

1. **Have Mixamo rig him and re-download the clips for him** (needs the Mixamo login, so the PC). Upload the unrigged v4 mesh to Mixamo. Mixamo fits its own 65-joint skeleton with fingers to the mesh, and every clip downloaded for that character is fitted to his proportions by Mixamo. This is the only route where clips drop in with nothing to correct. Only the clips the build uses need downloading again, about 40, not all 426.
2. **Keep a Meshy rig and correct in the game.** Use v4 (symmetric, Mixamo names). Scale the body's travel by the leg ratio, 0.85, so feet do not slide, and let arm IK cover the 8 to 9 cm of missing reach. It is one number for every clip, because the mismatch is uniform, but hands and feet depend on IK from the first stage.

Route 1 is the recommendation. Whichever is chosen, the height bands that depend on reach should use this body's arm, not X Bot's.

### What this changes in Part 2

- **Mixamo pipeline, step 1** is already done in effect: all clips were taken against one body. Keep using that same character for every new download.
- **Stage 0 test course:** add walls at the clips' native heights (0.62, 1.00, 2.30 and 2.46 m) so each clip can first be tested unstretched, and build the test stairs twice: once at 0.18 m risers and once at 0.25 m.
- **Stage 2 import proof:** the character should stand 1.81 m tall, and the walk and run should print 1.79 and 5.92 m/s (or 3.13 m/s for `Slow Run`). Use `Running Jump Climb` on a 1.00 m box as the climb clip that settles the vertical root question, since its feet land cleanly on top.
- **Stage 3:** add a per-clip start offset so every loop begins on the same foot, and set the walk playback speed from the table.
- **Stage 6:** crouched body about 1.5 m tall and a 1.5 m overhang, until a lower crouch walk is found.
- **Stage 8 onward:** each traversal stage starts with its clip unstretched on the native-height wall, then is stretched across its band.

## What could not be verified

**Human movement.** The usual running elbow angle and arm swing size in degrees; trunk lean in walking, running, speeding up and slowing down in degrees; full joint-angle curves with spread from a gait laboratory dataset; base finger knuckle limits, thumb base ranges, and shoulder inward and outward rotation; the classic body-segment length and mass table (Winter, Drillis and Contini), which returned errors; NASA's body-size and reach tables, whose host was blocked; standing sway size in millimetres; the size and timing of the weight shift before a first step; steps needed to stop from a jog. Several pages were blocked outright, including Physiopedia, PubMed and the standard gait textbooks.

**City obstacles.** The official text of the US building code (only a summary was read); typical bonnet heights by car class, door sill and seat heights; heights of wheelie bins, dumpsters, park benches and typical garden fences; how people get into and out of cars (all papers blocked); sliding over or climbing onto a car; the largest obstacle depth that can be vaulted; shimmy speed, hang time norms, grip force by grip type; walking a round rail or pipe, and the effect of height above ground on balance; beam walking data for ordinary young adults (the figures are for older adults, dancers and novices); fracture or injury risk by drop height; deep-crouch, kneeling and prone body heights and crawl speeds; numeric trunk lean per degree of slope; the maximum walkable slope from the perception studies; the US Army's own manual text on cover and movement (blocked; a teaching text was used). The jump tables are a coaching site's own compilation, not a formal study. The height bands, drop bands and width bands in Part 2 are syntheses of cited figures, not measured thresholds.

**Mixamo.** The live site could not be opened, so the catalogue was checked only through a third party's public copy of it (Part 3); names and availability on the live site may differ, and the candidate clips were measured on a different body from the project's. Part 3 settles, by measurement, which clips are in the folder, their sizes, speeds and native obstacle heights, that they share one body and are not in place. Still unverified: the full list of download formats and frame rates; what "In Place" removes exactly; the skeleton options without fingers and their joint counts; why the hands drift in the climb clips; exact heel-strike times for the loops (only which foot leads was measured); how these clips behave once imported into Godot, since nothing was played there. The binding Adobe terms of use were not read; the licence reading rests on Adobe's FAQ and a community post whose author's status could not be confirmed. Neither Blender root-motion add-on was run.

**Godot.** Nothing was run in an actual Godot build; every Godot fact is from documentation and source text. Specifically unknown: whether root motion taken from a scaled hip track comes back in metres; how vertical root motion should be handled for climbs; how skinned characters and skeleton modifiers behave under physics interpolation; whether `TwoBoneIK3D` orients the hand or foot to the target; the cost of large animation trees or many modifiers; whether the bone map auto-fills correctly for a Mixamo rig (expected from the matching rules and forum reports, not tested); the cause of the 2026 "arms clip through body" report. There is no official IK tutorial and no official Mixamo tutorial. How people implement warping in Godot has no cited source; the method in Part 2 is inferred from the API.

**Jolt in Godot.** Performance on Android and affordable queries per tick; how many worker threads Jolt gets; whether Godot will expose Jolt's character controller; whether six-axis joint springs under Jolt can track a full animated pose, and whether the motor settings on cone and hinge joints can be reached from script; known ragdoll problems under Jolt (titles only were seen); the content of the 4.7 fix for missed collisions (known only from the issue page); best practice for moving platforms; whether overlap queries honour back faces on one-sided meshes beyond what the issue comments say. The inner workings of Jolt's own character controller were read from its header and overview only.

**Rockstar.** No Rockstar-authored description exists, in anything fetched, of the capsule and ground probe, how the capsule follows animation, climb detection, fitting clips to ledges, hand IK, cover point generation, or vehicle entry alignment; all of that is inferred from names. The capsule numbers come from an RDR2-format file redistributed by a mod and may have been edited; GTA V's and GTA IV's own values were not found. The units of the climb clip numbers (20 to 295) are not stated anywhere. No tuning values were found for any system, nor the rules for when a character is switched to Euphoria. No measurement-quality source gives climb heights, fall-damage heights, sprint rules or GTA V input delay. "RDR2 uses motion matching" is unverified. Wikipedia says Rockstar's engine uses the Bullet physics library while the Euphoria engineers describe Rockstar's own physics code; that conflict is unresolved. NaturalMotion's own documents and several interviews were unreachable. The comparable-systems material rests partly on press summaries of talks whose slides were not fetched.

## Conclusion

The research changes the shape of the problem. It was easy to assume that Jolt would supply the character controller and Mixamo the traversal animation, leaving only assembly. Neither is true. Jolt's controller is inside Godot's build and unreachable, and a Mixamo clip is a hip path and joint rotations with no knowledge of walls. What the project actually has to write is small in count but exact in nature: a body with its own ground probe, a measuring routine for obstacles, a table of measured facts about each clip, and a fitting step that stretches a clip onto what was measured. Rockstar's public traces and Epic's documented sample both point to that same loop of detect, measure, choose, fit.

The second change is where the risk sits. The human data and the Rockstar clip names agree closely enough on height bands that the design is not the uncertain part. The uncertain parts are the ones no source could settle: whether the needed Mixamo clips exist and at what heights they were captured, how vertical root motion behaves in Godot, and what a phone can afford. Each of those is answered by a cheap experiment early in the build order (Stage 2 for the first two, the phone pass after each stage for the third). An hour spent browsing the Mixamo library with the height table in hand, before any code is written, would remove the largest unknown in this report.
