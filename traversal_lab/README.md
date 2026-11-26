# Traversal lab

A self-contained Godot 4.7 project for building the player's movement and traversal one tested stage at a time
(`reports/Hybrid character traversal study.md`, Part 2). Jolt physics, 60 ticks a second. The code is in
`traversal/` (`res://traversal/`), so it can be copied into the game at the same path when it is ready.

## Working rule: the movement study first, at every step (Yasin, 25 Nov)
"do not forget to remind yourself of the movement study and acting according to it at every step."
Before building or changing anything in a stage:
1. Re-read the part of `reports/Hybrid character traversal study.md` that the stage touches (Part 1 for how people
   move, Part 3 for this character's own measured numbers).
2. Every number in the code that describes movement carries a comment saying which finding it follows. A number the
   study does not give is marked `NOT in the study` and is a value to tune by eye, never passed off as sourced.
3. The stage's table below lists what the study says and what the code does, so the two can be compared.

## 26 Nov 2026: the study gate and the rebuild (read this before the rest)
- **The study is the authority and the checks are locked.** Read `study/README.md`. The one audit is
  `tests/audit.gd`; its bars are the study's own sentences (`study/bars.json`). The older tests named further down
  (`test_study`, `test_feet`, `test_starts`, `test_turn`) are gone: their bars were looser than the study.
- **The character is being rebuilt as the study describes it** (Yasin: "Rebuild as the study says"): a Root bone on
  the rig (`tools/build_rig.gd`), an animation library made from the baked clips (`tools/build_library.gd`), one
  `AnimationTree` on the physics tick with a synced walk / jog / run blend space whose root travel is cancelled and
  used as a measurement, and skeleton modifiers for the corrections (`traversal/character/character.gd`).
  - Stage 3 (idle, walk, run, the change from walk to run at 2.0 m/s, lean, jump, falling, landing): rebuilt.
  - Stage 4 (feet and head) and Stage 5 (starts, stops, turns on the spot), stairs and steep-ground clips: NOT
    rebuilt yet. Until they are he walks stairs and slopes with the plain walk, and those audit lines fail.
  - The earlier code-posed character is kept as `character_v1.gd`: run the lab with `-- --v1` to compare.
- Everything below this section describes the build as it was before the rebuild, and is kept as a record.

## Run it (PC)
Open this folder (`traversal_lab`) as a project in Godot 4.7.2 and press Play, or:

    Godot_v4.7.2-stable_win64.exe --path traversal_lab

| Key | Does |
|---|---|
| W A S D / left stick | move (relative to the camera) |
| Shift | run |
| mouse | look round; Esc frees the mouse |
| `[` and `]` | previous / next station |
| R | back to the start of this station |
| F5 / F6 | start / stop recording your input |
| F7 | replay the recording from where it began |
| F8 / F9 | save / load the recording |

## Automatic test

    Godot_v4.7.2-stable_win64.exe --headless --path traversal_lab -s res://tests/test_stage0.gd
    Godot_v4.7.2-stable_win64.exe --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_stage1.gd -- --minutes=10

Each must end with `RESULT PASS`. `--plain` after `--` runs the lab with the old stand-in body.

## Stages
| Stage | What | State |
|---|---|---|
| 0 | the measured course (62 stations), the readout, record / replay | automatic test passes; needs Yasin's eyes once |
| 1 | the body alone (capsule): kerbs, stairs, ramps, walls, ledges | automatic test passes; **needs Yasin's eyes** |
| 2-3 (first pass) | player_v4 on the body with idle, two walks, jog, run and a jump | built, seen in pictures; **needs Yasin's eyes**; no automatic test yet |

## Stage 0: what to look at
The automatic test already measures every obstacle against its label and checks that a replay repeats exactly.
What it cannot see, and Yasin should check once by walking the course with `]`:
1. Every station shows its label and the label is readable.
2. The readout (top left) changes as you move: state, speed, height, and the green height graph.
3. Record a short walk (F5, walk, F6), press F7 twice: the body takes the same path both times.


## The character (first pass of Stages 2 and 3)
Built early, out of order, because a bare capsule with no jump could not be judged (Yasin, 25 Nov).
- `traversal/character/player_v4.scn`: Mixamo's rig of player_v4 (65 joints, full fingers), made by
  `tools/build_character.gd` from the rigged FBX. The raw FBX and the raw clips stay in `assets_src/` (not in git).
- `traversal/character/clips/*.res`: clips baked onto his skeleton by `tools/build_clips.gd`, a rotation per bone per
  frame plus the hips' path. No Blender step and no root bone: the travel is taken out when the clip is sampled.
- `traversal/character/character.gd` poses the skeleton. It only looks; the body alone decides where he is.
- Moving: the two loops either side of the body's speed are blended at the same point of the stride, and the stride
  advances by distance covered, so the feet keep pace with the ground. Clip speeds on him: slow walk 1.07 m/s, walk
  1.76, jog 2.53, run 5.82.
- Jump: a push-off first (0.30 s standing, as the study gives for the push-off of a standing jump; 0.10 s from a run,
  the take-off time of the Running Jump clip), then the body rises 0.45 m (an average standing jump raises the body
  0.41 to 0.50 m). The pose comes from the `Jump` clip; landings from `Falling To Landing` and `Hard Landing`.

- Arms (Yasin's play-test, 25 Nov: "his arms are almost sticking to his body"): each upper arm is swung 9 degrees out
  from the chest (`arm_open_deg`; set by eye, not from the study). The clips were captured on a slimmer body.
- Lean: he leans into a turn by tan(lean) = speed x turn rate / g, capped at what was measured on people (6.8 degrees
  at a normal walk, 13 at a run).

### Feet (Stage 4): `traversal/character/feet.gd`
- A foot the clip has on the ground (low, and not travelling over the ground) is held where it was planted until the
  clip lifts it. It is let slide only once it is 10 cm from where the clip wants it.
- Each foot is raised or lowered to the ground under it and tilted to it (at most 20 degrees: the ankle's range in
  walking, and the steepest streets are 19). The hips come down only as far as a planted foot needs to reach.
- The legs are solved by Godot's `TwoBoneIK3D`, as the study recommends, with the knee pointed the way the clip had it.
- The head turns toward where he is asked to go, up to 30 degrees, shared between neck and head ("people turn head
  first"), at 100 degrees a second at most.
- Measured (`tests/test_feet.gd`, the report's bar is 2 cm): planted feet drift 0.0 cm at a walk and at a run (4.0 cm
  before); on flat ground the fitting changes nothing (0.0 mm); 10 and 19 degree ramps 0.0 cm; walking up stairs
  1.3 cm, walking down 1.6 cm, running up 0.0 to 0.3 cm. **Running down stairs fails (a foot held about 9 cm high
  at times); walking down the steep 0.25 / 0.26 m stairs fails (17 cm)**; those stairs are steeper than any
  building code in the study allows.

### Stairs: their own gait
- The study: "stairs are climbed at about half a second per step: 0.51 s up and 0.47 s down", and going up and going
  down are different movements. The body finds stairs (level surfaces stepping the same way twice ahead of him; a
  kerb is one step, a ramp is not level), measures the tread from the edges he crosses, and takes one step per
  0.51 s up, 0.47 s down walking; running, his own clips' 0.30 s up and 0.20 s down. Measured: 0.51 s a step walking
  up. That is 0.55 m/s along the ground, much slower than the 1.4 m/s it was.
- **Running on stairs is not in the study** (its notes: "two-steps-at-a-time mechanics, running on stairs: not
  found"), so those figures are ours, set at Yasin's word on 26 Nov: 0.28 s a step up (1.0 m/s on 0.28 m treads),
  0.22 s a step down (1.3 m/s). They are in `body.gd` (`STEP_TIME_RUN_UP`, `STEP_TIME_RUN_DOWN`) to tune by feel.
- Clips, two steps a loop, played by where he is on the stairs so each foot comes down mid-tread: walking up is
  Mixamo's `Ascending Stairs`; walking down, running up and running down were made with Kimodo (26 Nov), one stride
  cut from each and its end eased into its start. The clip's own stairs are taken out from under its feet and the
  real steps put in by the foot fitting. Kimodo gave one step at a time for running up even when asked for two.
- **Mixamo's two going-down clips are damaged** (on X Bot and on him alike): the hips go down 0.5 m but no foot ever
  goes below the floor, so the legs fold into a squat. They are no longer used.

### The study audit (26 Nov)
Yasin: "Why am I still finding things that don't follow the study? ... MAKE DAMN SURE YOU TAKE THE STUDY INTO
CONSIDERATION AT EVERY STEP! IF A MIXAMO CLIP VIOLATES IT EVEN IN IDLES, CHANGE IT WITH A KIMODO CLIP".
`tests/test_study.gd` measures what the build shows, on the finished skeleton after blending and IK, against the
study's own numbers: speed, steps a minute, stride, each foot's share on the ground, both-feet-down share or flight,
rise and fall and sway of the hips, thigh swing, knee bend in swing and as weight lands, pelvis turn and drop, elbow
bend, arms against legs, feet apart sideways, and that standing is never still. It is run with the other tests.

What it found and what was done:
| Found | Study | Now |
|---|---|---|
| Mixamo walk: 108 steps a minute | 115 to 120 | Kimodo walk: passes |
| both feet down 5 % of the stride | 10 to 12 | passes |
| hips rise and fall 5.6 cm | 2.7 to 4.8 | passes |
| thigh 35 deg forward | 25 | passes |
| knee bends 30 deg as weight lands | about 20 | passes |
| feet 0.32 m apart sideways | 0.08 to 0.10 | 0.08 m |
| heavy landing from 1.5 m | from 1.0 m | 1.0 m |
| no gain going gently downhill | Tobler: fastest on a 2.9 degree descent, 6 km/h against 5 on the flat | up to +19 % |
| run: knee peaks at 125 deg in swing | 94 to 119 | STILL 125 (Mixamo run; Kimodo's fastest run was 2.8 m/s, too slow to stand in) |

- The two Mixamo walks are gone. Six Kimodo walks were auditioned through the audit; the one in use passes all of it.
- **His legs.** His T-pose has the thighs splayed and the feet turned out, and every clip is a set of turns from a true
  T-pose, so every clip came out bow-legged and toes out. First tried pulling the feet in with the IK, which left the
  knees out (Yasin: "knees are bent outwards because you pulled only the feet together"). Now each leg bone's T-pose
  is corrected at the bake (`tools/build_clips.gd`): thigh and shin straight and angled in to the study's step
  width, foot and toe pointing ahead. The feet-only pull is off.
- Still open against the study: the run's knee (above); planted feet drift 2.7 to 3.2 cm at a walk with the Kimodo
  walk (bar 2); stairs, slopes, starts, stops and idles are not yet in the audit, only walk, run and standing.

### Steep ground (26 Nov)
Yasin: "we should be able to climb even higher than 35-40 degrees, there are mountain climbers and trekkers who do
that all the time". Researched first (`research_notes/Hybrid character traversal study/steep_slopes.md`), then the
clips were ordered from Kimodo with prompts written from it.

| What the research says | What the build does |
|---|---|
| uphill, what limits a person is the rate of gaining height: 0.35 m/s steady on 9 to 39 degree treadmills (0.70 m/s along a 30 degree belt); a fast run up 30 degrees was 2.06 m/s along the slope; the best racers hold 0.6 m/s of height for half an hour | uphill speed = rate of climb over the slope's rise: 0.35 m/s of height walking, 1.0 running. On the course: 19 degrees 1.02 / 2.90 m/s, 30 degrees 0.61 / 1.73 m/s |
| "walking down a slope of 30 degrees was done at the same speed as walking up a slope of 16 degrees" | downhill a slope counts as one 16/30 as steep |
| NO source gives the angle at which hands come into use. Shoe grip on dry concrete runs out at 31 to 40 degrees; one measured ankle could not bend past 24; a 37 degree ski-jump race is described as run "on all four" | hands and feet from 35 degrees: a reasoned figure, not a sourced one |
| climbing rubber on granite holds to 44 to 50 degrees | ground over 50 degrees cannot be stood on (he slides); the course has a 60 degree ramp to prove it |
| on hands and feet "the footfall of a lower limb usually followed that of the same-side upper limb"; comfortable at about 0.83 m/s on the flat, tested at 0.56 m/s on a 35 degree incline | Kimodo crawl clips made to that description; 0.35 m/s of height, 0.6 with run held (the 0.6 is not measured for crawling) |
| "face inwards for steep slopes, but otherwise face out" | over 35 degrees he comes down backwards, facing the slope |

- **Second pass, 26 Nov, after Yasin's look** ("going up 30 deg slope is terrible, he pulls his legs up as if
  stretching ... why is the ramp a crawl? we look like a small baby ... long strides assisted by hands only at some
  steps"). The fault with the first clips: Kimodo had made the uphill walk on the FLAT, and a flat walk fitted to a
  30 degree slope by the foot IK lifts the knees absurdly. The rule now: a slope clip must itself climb or descend at
  about the slope it is used on (measured from the take), so the IK has only the difference to make up.
  - 20 to 35 degrees up: a take that rises at 29 degrees with long strides. Down: one that drops at 27 degrees.
  - 35 to 50 degrees up: a take that rises at 44 degrees, on foot. Down: one that drops at 27 degrees, facing
    downhill (no take came down steeper facing forward; Kimodo mostly backs down a hill).
  - The crawl and the facing-in descent are out. No take put a hand on the ground, whatever the wording (see the
    third pass for the arm IK that does it).
  - On ground steeper than the ankle bends (23 degrees here; one measured ankle stopped at 24) the heel comes off
    and he stands on the ball of the foot.
- **Third pass, 26 Nov** (Yasin: "zero forward lean, extremely small steps making it look like this is a joke rather
  than a hard walk"; downhill "he takes such little steps that it's both unreal and impractical"). I had chosen takes
  by the slope they climbed and nothing else. Every stride of every climbing take was then measured: strides really
  do shorten as the hill steepens (1.00 m at 28 degrees, 0.91 m at 37, 0.4 to 0.7 m at 45 and over), and the longest
  are now used, played slowly by the ground covered: about 80 steps a minute on the 30 degree ramp. Downhill uses a
  take with a 1.0 m stride (the first had 0.62 m, about 236 steps a minute at his pace); with run held, one that
  jogs down.
  - The trunk leans with the slope: 0.9 of the slope over 8 degrees going up (20 degrees on the 30 degree ramp, 33
    on the 45), a quarter of it back going down. The study says it leans and that it grows; the amounts are ours.
  - On the 45 degree ramp going up, once a stride he bends and puts his left hand on the slope ahead (arm IK,
    Godot's `TwoBoneIK3D`). One hand only so far.
- What was learned about wording Kimodo: one sentence (a full stop starts a new motion), no decimal points, and SHORT.
  The long descriptive prompts did worst: four of four "30 degree hillside" takes stood on the spot. Every take is
  measured (slope climbed, speed, foot sliding) before it is used; the numbers are in `kimodo_clips.csv`.
- Not done: hands on steep ground; sideways traverse and zig-zag; a slide down ground over 50.

### Walking or running off an edge
Yasin: "looks stuck and frozen on air before landing, no limbs move to balance itself". The Mixamo falling loop
barely moves. Now `KM_Ledge_Walk_Off` / `KM_Ledge_Run_Off` (Kimodo): the clip's own time in the air plays while he
falls and its landing carries on from where the feet touch; a fall longer than the clip has goes to the old loop.

### Stairs were jittery
First attempt (smoothing the hop of the hips) made no difference to the eye (Yasin: "there isnt any visual
difference"). Measuring every joint found it: a foot passing a step edge had its ground jump a whole step and was
snapped there at up to 8 cm a tick, and the stride itself jumped a few hundredths at every edge because it was tied
to a measured tread that is never exact. Jolts of feet and knees were 300 to 500 m/s2 on stairs against under 60 on
the flat. Now a moving foot feels a step edge 12 cm before and behind and rises across it; the stride runs on by
distance and is only drawn toward its place on the stairs; a little knee bend is kept. Feet now jolt at about 100
m/s2 going up and down, knees about 110 going up, still up to 280 going down.
Running up stairs has a new Kimodo take whose stride matches real steps (two steps of 18 cm in 55 cm, climbing at 30
degrees).

### Stance
Yasin: "legs are too spread apart". Measured: 0.32 m between the ankles at a walk, where people were measured at 0.08
to 0.10 m. It comes from his T-pose (legs splayed) which every clip inherits. The feet are brought in by half with
the leg IK: 0.16 m walking, 0.14 m running.

### Jump at a run, landings, turning round at a run
- A jump at a run plays `Running Jump` (one stride with a leap in it) and runs on without stopping. Measured: a leap
  of 2.33 m (the clip's own is about 2.7 m).
- After a drop of 0.35 m or more the stick is not obeyed for 0.30 s (0.90 s from 1.5 m or more) while he gathers
  himself. Those two times are not from the study.
- Running, asked to run the other way: he brakes ("a sudden turn starts with a braking action like a rapid stop"),
  plants and turns round with `Running Turn 180` (0.67 s, 270 degrees a second), and runs off. Measured: running
  back at 2.5 m/s after 1.63 s, carried 1.77 m on (his `Running To Turn` clip: 2.27 s and 4.0 m).

### Starts, stops, turns on the spot (Stage 5)
- The body keeps its own study-based speeds. The clips are played by distance (a start by how far he has gone, a stop
  by how far he still has to go) and a turn by angle, so the feet keep pace with the body.
- Clips: `Female Start Walking`, `Idle To Sprint`, `Female Stop Walking`, `Run To Stop`, `Left Turn 90`,
  `Walking Turn 180`; mirror images are made in code for the other foot and the other way round.
- From rest, a direction more than 60 degrees off his facing is turned to on the spot first (180 deg/s walking,
  270 running), then he sets off. The 60 is not from the study.
- Measured (`tests/test_starts.gd`): walk stop 0.58 s and 0.39 m (study: under two steps); run stop 1.32 s and 2.20 m
  (study: 5 steps and 2.9 m flat out); feet move 0.3 to 0.5 cm once still; 180 on the spot 0.90 s walking (his clip:
  1.00 s), 0.60 s with run held; let go and press again mid-stop: no pop.

Not done yet, and known: going down stairs and running up them (above); starts at an angle under 60 degrees just
curve; a walking turn-round is still an arc; no roll out of a running drop (`falling to roll` is downloaded).

## Stage 1: the body alone
`traversal/body/body.gd`. A floating capsule: the capsule covers the body from 0.32 m above the feet to the top of
the head, and one short downward sphere probe finds the ground, so kerbs and stair risers pass under it. The thin
"leg" under the capsule in the lab is only there to show the float.

What it does not use, and why: `move_and_slide()` (under Jolt it has no stair stepping, unreliable floor flags, and
in floating mode it keeps full speed along a wall), so the body slides by its own rule.

| The study says | The body does |
|---|---|
| comfortable walking 1.3 to 1.45 m/s; running 2.5 to 4.5 m/s | walk 1.4, run 4.5 (Stage 3 replaces these with the clips' own speeds) |
| a walk reaches about 90 % of its speed on the first step, steady by the third | 90 % of walking speed after about 0.55 s |
| a walk stops in under two steps | stops from a walk in 0.6 s |
| stopping from a flat-out run: 5 steps, 2.9 m | brakes at 6.2 m/s2 from a run: 0.73 s and 1.6 m from 4.5 m/s |
| a sharp turn is a step or spin turn of about 75 deg a step, made within one step; his Walking Turn 180 clip takes 1.00 s and Running Turn 180 0.67 s; over 300 deg a second is outside the data | the heading turns at 180 deg a second at a walk and 270 at a run (`tests/test_turn.gd`: a right angle in 0.47 s walking, 0.30 s running). The first version used the gentle-curve figure (36 deg a stride) for every turn, which Yasin found "very very slow" |
| people slow to turn (0.96 m/s on a 1 m circle against 1.61 straight) and a sudden turn starts with braking | up to 40 % of the speed is given up in a right-angle turn; a turn-round at a run brakes to 2.0 m/s first (that 2.0 is not from the study) |
| people lean into a corner by 4.4, 6.8 and 12.7 deg at slow, normal and fast walking; 13.6 deg on a sprinted curve | the figure leans about its feet, capped at 6.8 deg walking and 13 running |
| people do not reverse at speed | asked to go nearly the opposite way, it brakes first |
| kerbs 0.10 to 0.20 m, risers to 0.25 m are walked over; 0.30 m is the top of "walk over it" | anything up to 0.30 m is stepped onto, 0.35 m and above is a wall |
| real streets reach 19 deg | walks 19 deg; ground steeper than 28 deg cannot be stood on (the 28 is NOT in the study) |
| steps to reach a run: not found | 0.6 s time constant, marked as a value to tune |

On steep stairs the feet can only follow the ground so fast, so the body slows down at a run, going up and down.

### Stage 1: what to look at (Yasin)
The automatic test checks heights, speeds, states and a ten-minute random walk. What it cannot judge is the feel:
1. **Kerbs and stairs** (stations 1 to 3, 15, 16): walk and run up and down. The body should rise and sink smoothly,
   with no hop and no hitch at the top or bottom.
2. **Single steps** (stations 4 to 14): it climbs up to 0.30 m and is stopped dead by 0.35 m and higher.
3. **Ramps** (17 to 21): 5, 10 and 19 degrees are walked at a steady speed; on 30 and 45 it cannot climb and slides back.
4. **Walls** (22 onward): run into one head-on and at an angle. It should stop or slide along, with no shaking.
5. **Ledges** (stations 15, 16): walk up the stairs and off the side of the top landing. It should fall at once
   and land without a bounce. Walking off a kerb should be a step down, not a fall.
6. **Weight**: this is the main one. Starting takes about a step, stopping from a run takes a few strides, and a
   turn takes about a step (a turn-round at a run brakes first). Say if that feels too heavy or too light.
