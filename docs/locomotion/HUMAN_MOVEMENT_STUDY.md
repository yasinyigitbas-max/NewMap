# How people really move: a study for Coronado's locomotion and traversal

Written 25 Nov 2026 for Yasin, as a reference for the player's animation (CityPlayer, HandGrip, FootPlant in
`native/src`). Numbers are typical adult values (about 1.75 m tall, leg about 0.9 m) from standard gait and range-of-motion
references (Perry's gait analysis, AAOS joint ranges, stair and parkour studies). They are averages: real people vary
by about ±15 %.

Part 1 is the body. Part 2 is everyday walking and running. Part 3 is the city's obstacles, by height. Part 4 is why
animation usually looks wrong, and the techniques that fix it. Parts 5-8 (added the same day) are the tools and the
references: Mixamo files, Godot's skeleton system, Jolt physics, and how Rockstar's GTA IV / V and RDR 1 / 2 do it.

---

## Part 1 - The joints

### 1.1 Ranges (the most a joint can do) and what it really uses

| Joint | Type | Full range | Used walking | Used running / climbing |
|---|---|---|---|---|
| **Hip** | ball | flex 120° (knee bent), 90° (knee straight); ext 20-30°; abd 45°; add 30°; rotation 40° in / 45° out | 30° flex to 10° ext | swing 60-70° flex; high step / mantle 90-110° |
| **Knee** | hinge (+10° twist only when bent) | 0-140° flex; never bends sideways; at most 5° past straight | 15-20° when the heel lands, ~5° at midstance, 60-65° in swing | stance 40-45°, swing 90-130°; landing 60-90° |
| **Ankle** | hinge + subtalar roll | up (dorsiflex) 20°; down (plantarflex) 50°; roll in 35°, out 15° | 10° up in late stance, 15-20° down at push-off | full squat needs 30-35° up; landings use all of it |
| **Toes (ball of foot)** | hinge | bend up 70-90° | ~55° at push-off | sprinting / crouching on toes: full |
| **Spine, lumbar** | stack | flex 60°, ext 25°, side 25°, twist only ~5° | pelvis tilts ±2°, drops ±5° on the swing side | trunk lean forward 10-20° running, 30-45° climbing |
| **Spine, thoracic** | stack + ribs | twist ~35° each way; little flex | counter-twists the pelvis ±5-7° | arm reach and throws twist here, not in the low back |
| **Neck** | stack | flex 45-50°, ext 60-70°, turn 70-80°, side 45° | holds the head level and steady (eyes stabilised) | turns lead every change of direction |
| **Shoulder** | ball + shoulder blade | raise forward 180°, back 50-60°, side 180°, rotation 70° in / 90° out | arm swing ±15-20° | reaching above 30° the shoulder blade does a third of it (it slides and tips up) |
| **Elbow** | hinge | 0-145° | 20-45° bent, swinging slightly | running ~90° fixed; pull-up 0→130° |
| **Forearm twist** | two bones rolling | palm down 80° / palm up 80° | neutral (thumb forward) | palm down onto a ledge |
| **Wrist** | two-axis | flex 80°, ext 70°; toward thumb 20°, toward pinky 30° | relaxed, slightly extended | pushing down on a top (vault, mantle press): 60-90° extension |
| **Fingers** | three hinges each | knuckle 90°, middle 100-110°, end 80-90° | resting curl, more toward the pinky | hook grip on an edge, full wrap on a rail |

### 1.2 Rules that rigs and clips most often break

1. **Twist lives in the forearm, not the wrist.** The radius rolls round the ulna along the whole forearm. A rig that
   twists only the hand bone gives the "candy wrapper" wrist. Spread the twist over the forearm (twist bones, or share
   it 50/50 between the forearm and the hand).
2. **The shoulder blade moves.** Above about 30° of arm raise, roughly 1° of blade rotation for every 2° of arm. Hanging
   from a ledge the shoulders **shrug up toward the ears** (the blades rise). Reaching for a ledge the shoulder comes
   forward. A figure that hangs with the shoulders level looks dead.
3. **The knee only bends one way and points over the toes.** IK must keep the knee pole in front, over the second toe.
   Knees that collapse inward or swing outward are the most visible IK fault.
4. **The ankle runs out at 20° up.** On a steep uphill, a deep crouch or a high step the heel must **lift**; do not let IK
   bend the ankle further.
5. **The pelvis is not stuck to the hips' path.** Walking, it turns ±4-5° (the leg reaching forward takes its side of
   the pelvis with it), drops ±5° on the swing side, and shifts 2-4 cm over the standing foot. The chest turns the
   other way. Remove this and the walk looks robotic; overdo it and it looks like a catwalk.
6. **The head is stabilised.** The body bobs; the head stays nearly level and the eyes stay on the target. In a
   procedural look-at the head counter-rotates against the trunk's sway.
7. **Fingers are never straight at rest.** They are softly curled, more toward the pinky (index ~15-20°, pinky ~40-50°
   at the knuckle), the thumb relaxed beside the index.
8. **Grips:** on a square edge, a **hook grip** (knuckles straight-ish, middle and end joints bent over the edge, palm
   flat on top, thumb alongside the index, not under). On a round rail or pipe, a **full wrap** (all three joints bent,
   thumb round the other side). Pushing down on a top (vault), an **open palm**, fingers forward and spread, wrist
   extended 60-90°, the heel of the hand carrying the weight.

---

## Part 2 - Walking, running, starting, stopping, turning

### 2.1 The walk cycle (one stride = two steps)

| % of stride | Phase | What the body does |
|---|---|---|
| 0 | heel strike | heel down, ankle neutral, knee almost straight (~5°), hip 30° flex, opposite arm forward |
| 0-10 | loading | foot slaps flat (the ankle lets it down), knee flexes to 15-20° to absorb, **both feet down** |
| 10-30 | midstance | body vaults over the planted leg (inverted pendulum); **hips at their highest**; swing leg passes |
| 30-50 | terminal stance | heel lifts, body falls forward over the ball of the foot |
| 50-60 | pre-swing | push-off: toes bend up, ankle 15-20° down, **both feet down** again |
| 60-100 | swing | knee bends to 60-65° (toe clears the ground by only **1-2 cm**), then straightens to reach |

- Stance 60 %, swing 40 %. Two short spells of both feet down (about 10 % each). **If both feet are ever off the
  ground, it is not a walk.**
- Hips go up and down **4-5 cm** per step (highest at midstance), side to side **2-4 cm** (over the standing foot).
- Normal walk: **1.3-1.4 m/s**, 100-120 steps/min, step about 0.7 m. Brisk: 1.6-1.8 m/s. (The player's `walk_speed`
  of 1.6 is a brisk walk.)
- Step width (heel to heel, sideways) is only **8-12 cm**. Feet land nearly in line, toes out 5-10°.
- Arms swing opposite to the legs, mostly from the shoulder, ±15-20°; the elbow bends more on the forward swing.

### 2.2 Running

- People switch from walking to running at about **2.0-2.2 m/s** (the speed where walking costs more than running).
  Between 1.8 and 2.2 m/s neither looks right for long; a game should not let the player sit there (use the band as
  a fast transition, not a gait).
- No double support: a **flight phase** where both feet are off. Stance is under 40 % of the stride.
- Hips are **lowest at midstance** (the leg is a spring: it compresses on landing) - the opposite of walking.
  Bounce 6-10 cm.
- Jog 2.5-3.5 m/s, run 4-5 m/s (`run_speed` 4.6 is a solid run), sprint 7+ m/s. Cadence 160-180 steps/min, rising
  slowly with speed: up to ~7 m/s more speed comes mostly from longer strides, above that from quicker steps.
- Trunk leans forward 5-15° (more when accelerating). Elbows held at about 90°, hands relaxed, arms swing forward
  and slightly across the body, never across the centre line.
- Foot lands under the knee, close under the body (overstriding looks wrong).

### 2.3 Starting

1. Before the first step the weight shifts **sideways onto the standing leg** and slightly back (the body "unloads" the
   leg that will step).
2. The body leans forward (falls), then the first leg steps to catch it.
3. Full walking speed in 2-3 steps; full running speed in 3-5 steps (sprint 6-10).
4. The first step is shorter than the rest.

Starting a clip straight into the walk loop skips step 1 and looks like gliding off.

### 2.4 Stopping

- Walking: 1-2 steps; the last step is shorter, the body leans back slightly, the second foot comes alongside.
- Running: 2-4 steps; a stronger lean back, knees bend more to brake, the arms come forward.
- People stop **on whichever foot is next**: a stop that always plants the left foot is a foot slide waiting to happen.
  Pick the stop clip by the foot phase (2 clips: left foot planted / right foot planted).

### 2.5 Turning

- **Top-down order:** eyes → head → chest → pelvis → feet. The head leads the turn by about one step (~0.2-0.3 s).
  This is the single cheapest thing that makes a character look alive: turn the head first.
- **Small turns (< 45°)**: done within the steps (each step lands rotated a little).
- **Medium (45-135°)**: a step turn (the outside foot steps across) or spin turn on the inside foot.
- **About-face (180°) when running**: plant, brake with a wide step, pivot, push off the other way (a "pivot" clip,
  left and right versions). Rotating a run clip in place by 180° is the classic glide.
- Running round a curve, the body **leans into it**: lean angle = atan(v² / (g·r)). At 4.6 m/s on a 5 m radius that is
  about 23°. The lean is from the feet, not a bend at the waist.
- Accelerating or braking, the body leans forward / back by atan(a / g): a 3 m/s² push-off is about 17°.

### 2.6 Slopes and ramps

| | Uphill | Downhill |
|---|---|---|
| Trunk | leans forward (≈ the slope angle + a few degrees) | upright or slightly back |
| Steps | shorter, quicker | shorter, slower |
| Knee at landing | more bent (pushing up) | more bent (braking) - the knee absorbs |
| Foot | lands flatter; on steep ground the **heel lifts** (ankle limit) | heel first, ankle controls the drop |
| Arms | swing more, drive | held slightly out for balance |

- Up to ~5° (most streets, wheelchair ramps max ~4.8°): walking looks the same; feet align, nothing else.
- 5-15°: the trunk lean and shorter steps above are visible.
- 15-25°: steep (some San Diego / Coronado hill streets): strong lean, heels off uphill; people zigzag downhill.
- Over ~30°: they turn sideways, use hands, or scramble.
- Feet on a slope: the sole follows the ground, but the **leg stays vertical** (gravity), so on a side slope the ankle
  rolls and the downhill leg bends more. The pelvis takes the lower foot's height (that is what FootPlant's hips drop
  does).

### 2.7 Stairs

Typical steps: riser 15-19 cm, tread 25-30 cm (pitch 30-37°).

**Going up**
- The foot lands on the **forefoot or whole foot**, never heel first, about a third of the way onto the tread.
- The stance knee is bent ~60° and the hip ~60° at landing; the body rises by **straightening the knee and hip**
  (the leg pushes the body up).
- Trunk leans forward 10-15°. The swing knee lifts to 80-100° to clear the next nosing (toe clears by ~3-5 cm).
- Cadence ~90 steps/min; slower than walking. Running up: two steps at a time is common, on the balls of the feet.

**Going down**
- **Toes first**: the forefoot lands on the edge of the next tread, then the heel lowers. The landing knee is nearly
  straight and then bends to 80-90° as the body is lowered (the knee brakes all the way down).
- Trunk upright or slightly back; **eyes down** (the head tips 20-30°) for the first steps.
- Feet land further back on the tread (heel overhangs slightly on short treads).

**Animating stairs**: the hips travel on a **smooth line parallel to the stair pitch** (with a small bounce per step),
while the feet go to discrete heights. Lifting the root step by step is wrong; a smooth root plus foot IK onto each
tread, with the swing foot's arc raised to clear the nosing, is right. Adjust the step length so the feet land on
treads, not on the edges (stride warping toward the tread spacing).

### 2.8 Kerbs (curbs)

Coronado kerbs are ~10-16 cm.
- People do not stop. The **swing leg flexes more** at hip and knee in the step before (foot raised 3-5 cm above the
  kerb), lands flat or forefoot on the top, and the hips rise during that stance. The step onto it is a bit shorter.
- **2-3 steps before**, people adjust step length so no foot lands on the edge (they look at the kerb about 2 steps
  ahead).
- Down a kerb: the leading leg reaches down, lands forefoot-flat, the knee absorbs; the step is a little longer.
- Up to ~20 cm this all happens inside the walk cycle (no special clip). From about 20 cm people make an **obvious**
  bigger step: trunk forward, a pause in rhythm, sometimes a hand on the thigh.

---

## Part 3 - The city's obstacles, by height

Body landmarks (1.75 m adult) used to choose the action:

| Landmark | Height |
|---|---|
| ankle | 0.08 m |
| shin middle | 0.25 |
| knee | 0.50 |
| hip (hip joint) | 0.90 |
| waist | 1.05 |
| chest | 1.30 |
| shoulder | 1.45 |
| eyes / head top | 1.65 / 1.75 |
| standing reach (finger tips) | 2.20-2.30 |
| reach with a running jump | 2.60-2.80 (a wall-run step adds 0.3-0.6 m: an athletic 3.0-3.4 m) |

### 3.1 Going up

| Height | Name | What a real person does | Hands | Time |
|---|---|---|---|---|
| < 3 cm | lip | nothing; foot IK only | - | - |
| 3-20 cm | kerb, single step | stepped inside the walk (2.8) | - | in stride |
| 20-45 cm | bench seat, low wall, planter | **big step up**: hip 80-100° flex, trunk forward 20-30°, push off the back foot; thin (< 30 cm deep): **step over** | maybe one on the knee or the top | ~0.6-0.8 s |
| 45-80 cm | knee- to thigh-high wall | **low mantle**: both hands on top, hop, knee onto the top, stand up on it; or a **step-vault** if going over | both, palms down | 1.0-1.4 s |
| 80-120 cm | hip-chest: railing, car bonnet, fence | going over: **vault** (3.2); going onto: **mantle** - small jump, arms lock straight on top, swing a foot or knee up | both | 1.2-1.8 s |
| 1.2-1.8 m | chest to head: walls, van roof | **climb**: jump, hands on top, **pull** (elbows down and back, chest to the edge), then the **press**: elbows rotate up over the hands, wrists extend, push to straight arms, then a foot up beside the hands, stand | both; hook then push | 1.5-2.5 s |
| 1.8-2.5 m | above the head | **jump to hang**, or a **wall-run step** (one foot pushes off the wall at ~0.6-0.9 m) to catch the edge; then the pull-up and press as above | hang from the hook grip | 2-3 s |
| 2.5-3.2 m | high wall | only athletic (wall-run, two steps) | | |
| > 3.2 m | | **not climbable** without features: a drainpipe, ladder, window sills, a bin to step on | | |

Rules:
- **Pull then press.** The hardest-looking part of a climb is the change from pulling (hands in front of the chest,
  elbows below) to pushing (shoulders over the hands, elbows straight up). In that moment the chest comes over the
  edge and the elbows swing up from below to behind. Clips that skip it look like the body is lifted on a string.
- **Feet help.** On a wall the feet scrabble and push on the face (one or two steps up the wall) while pulling. A
  free-hanging pull with dangling legs is only for overhangs.
- **Hands land first, then the body comes to the hands.** The hands are pinned on the top from contact until they leave
  (HandGrip's "pinned till he lets go", bug B11, is right).
- **No room to stand?** If the top is narrower than a foot (< 25 cm) or there is no headroom (< 1.8 m clear), people do
  not mantle onto it: they vault over, or they stay hanging.

### 3.2 Going over (vaults)

All vaults hinge on the **takeoff spot**: 0.8-1.2 m before the obstacle when running, about one step when walking. The
steps before are adjusted to arrive on it (people do this 2-3 steps out).

| Vault | Height | Speed | How | Who |
|---|---|---|---|---|
| **step-over** | < 50 cm, thin | walk | lift the lead leg over, then the trail leg; hip turns | anyone |
| **step / safety vault** | 0.6-1.1 m | walk-jog | one hand on top, the **same-side foot** steps on top, the other leg passes between, land on the far side | anyone (most natural for a "normal" person) |
| **sit / slide-over** | 0.8-1.1 m, deep (car bonnet, table) | walk-jog | sit on the hip, swing both legs over, slide off; the **hood slide** on a car | anyone |
| **speed vault** | 0.8-1.2 m, thin | run | one hand on top, body turns sideways, both legs together over the side | fit |
| **lazy / turn-around vault** | 0.8-1.2 m | jog, diagonal approach | both hands in turn, legs swing over at an angle | fit |
| **kong / monkey** | 0.8-1.3 m, long | sprint | both hands on top, dive forward, knees tucked between arms, push off | athletic |

For a normal man the **step vault** (one hand, one foot on top) under 1.1 m and the **slide-over** on cars are the
believable defaults; the speed vault when he is running. His fence rule (0.5-1.4 m, left hand on the rail) fits a
speed vault; at 1.2-1.4 m most people would climb over (both hands, a foot on the top, swing over, drop) rather than
vault.

### 3.3 Going down

| Drop | What people do | Landing |
|---|---|---|
| < 20 cm | step down inside the walk | lead leg reaches, forefoot first, knee bends 20-30° |
| 20-50 cm | **step down** (keep walking): lead leg reaches down, the trail knee bends deep to lower the body | knee to 40-50° |
| 0.5-1.0 m | **hop / jump down** facing forward; or sit on the edge and slide off; slower people turn and step down backwards with a hand on the top | both feet, forefoot first, knees 50-70°, arms forward |
| 1.0-2.0 m | **jump down** with a deep landing (knees 80-100°, hips flexed, hands may touch); or **hang-drop**: turn round, crouch, hands on the edge, lower to hanging, drop (saves ~2 m: hands-to-feet length) | deep crouch, 0.2-0.4 s to recover |
| 2.0-3.0 m | hang-drop; with forward speed a **roll** (diagonal over one shoulder to the opposite hip) | roll or hard landing |
| > 3.0-3.5 m | hurt (stagger, fall, damage) | |

- **Landing order:** toes/ball → heel → ankle bends → knee → hip. The deeper the drop, the deeper and longer each.
  A landing that hits the knees and hips all at once looks like a pose swap.
- Stepping **off** an edge at walking speed, the body keeps its forward speed: the drop is a short arc, not straight down.
- **Climbing down a tall thing faces the wall.** Low things (< 1 m): face forward, hop. Mid (1-1.5 m): sit / turn side-on.
  Tall: turn round, kneel, hands on the edge, lower legs over, hang, drop. Mirror of the climb up.

### 3.4 Hanging and shimmying

- **Free hang:** arms straight, shoulders shrugged up, head between the arms (looking up or at the wall), body still
  swings a little (pendulum, ~2 s period for a 2 m body), legs together, toes pointing down, knees slightly bent.
- **Braced hang** (wall below): feet on the wall at about hip height below the hands, knees bent, hips away from the
  wall. More stable; this is how people mostly hang on buildings.
- **Shimmy** sideways: the leading hand moves first (lifts, slides 30-50 cm, re-grips), then the trailing hand follows
  (to ~shoulder width); the feet walk along the wall. Each hand move ~0.4-0.5 s.
- From a hang: pull up (3.1), drop (3.3), or move round a corner (hands cross the corner one at a time).

### 3.5 Narrow and wide surfaces (wall tops, kerbs edges, pipes, beams)

| Width | Behaviour |
|---|---|
| > 60 cm | normal walk (a pavement) |
| 30-60 cm (wall top) | step width shrinks toward 0, steps a bit shorter; people lean slightly away from the bigger drop |
| 10-30 cm (beam, kerb edge, narrow wall) | **balance walk**: feet in one line (heel in front of toe), toes out 10-20°, short steps (0.3-0.5 m), slow (0.5-0.8 m/s), knees soft, **arms out to the sides** (raised 40-80°, bent at the elbow), trunk upright, eyes 2-3 m ahead (not at the feet), corrections from the **hips** (the hip bends and the arms swing to catch a wobble) |
| < 10 cm, round (pipe, rail) | balance walk with the foot turned out ~20-30° and the arch over the pipe, even slower (0.3-0.5 m/s); or sideways shuffle; or straddle / crawl on hands and knees |

- On wide ground balance is held with the **ankles** (tiny invisible sways). On narrow ground the ankle cannot do it;
  the **hips and arms** do - visibly. That is the whole look of a balance walk.
- Running along a wall top is possible to ~20 cm width for athletic people; the arms stay out.
- A wobble: an arm swings up on the side away from the fall, the trunk bends the other way, a quick step or a crouch.
  If it fails, they crouch and grab the surface.

### 3.6 Crouching and crouch-walking

- **Crouch (ready / low):** hips down so the head is at ~1.0-1.2 m: knees 90-120°, hips 90-110°, trunk forward 20-40°,
  heels down if the ankle allows (20-35°) otherwise on the balls of the feet. Arms forward or a hand on the knee/ground.
- **Full squat:** head ~0.9 m, knees ~140°.
- **Crouch walk:** shorter steps (0.4-0.5 m), slower (0.8-1.5 m/s), wider stance (15-25 cm), the hips stay low with
  small bounce, foot lands flatter, trunk forward. Running in a crouch is a hunch-run, not a squat-walk.
- **Entering** takes 0.3-0.5 s (the hips drop first, the trunk tips forward with it); **leaving** 0.3-0.4 s.
- Crouch to clear headroom: the head goes under at ~1.2-1.3 m clearance.

### 3.7 Cover (walls, cars, corners)

- **Low cover** (0.8-1.2 m: car, planter, low wall): crouch with the back or the side to it; the shoulder touches;
  the head stays below the top. Peeking: rise from the crouch, head and shoulder over the top, or lean out at the end.
- **High cover** (wall, pillar, corner): stand with the back or a shoulder on it; the hands on the wall (fingers spread
  at chest height); peeking round a corner: lean the head and the near shoulder out from the waist, the feet stay put.
- **Moving between covers**: hunched run, then a sideways stop into the new cover (the shoulder meets it, a hand
  braces).
- **Behind a car**: the engine block and wheels stop things, so people kneel by the front wheel; along the car they
  move crouched, one hand trailing on the body.

### 3.8 Walls and corners in everyday movement

- People keep **20-40 cm off walls** when walking; nobody brushes them.
- Turning a tight corner fast, a hand goes out to the wall (a palm push) to turn round it.
- Leaning on a wall: one shoulder or the back; the feet 30-40 cm out; one knee bent with the foot against the wall.

### 3.9 Cars

- Around a parked car: 30-50 cm off it; past the mirror they turn the shoulder.
- **Over the bonnet**: sit-slide (hood slide) when in a hurry (bonnet ~0.8-1.0 m); hands on the bonnet, hip slides,
  legs swing, land on the far side.
- **Onto the roof** (1.4-1.6 m car, 1.8-2.0 m van): a foot on a wheel / the bumper / the bonnet first, then up; people
  never mantle straight onto a car roof from the ground.
- Getting in and out is done (F11).

### 3.10 Doors

- Approaching, people slow from ~1.4 to ~0.8 m/s in the last 1.5 m, and the **hand reaches before the body arrives**
  (the reach starts 0.5-0.7 m from the door). Handles are at ~0.95-1.05 m.
- **Push door** (opens away): hand on the handle or flat on the door at chest height, push, and **walk through while it
  is still opening**; the pushing arm stays on the door as the body passes, then lets go. No stop.
- **Pull door** (opens toward): stop, grab, step **back and to the hinge side's opposite** while pulling, the door
  swings past, then step round it and through. A stop and a sidestep are unavoidable.
- Doorways are 0.8-0.9 m: the shoulders turn slightly when two people pass, or when carrying something.
- The **hinge side** decides which hand: the hand nearest the handle side.

---

## Part 4 - Why animations look wrong, and how to fix each

### 4.1 Feet sliding on the ground

Cause: the body moves at a speed the clip's feet do not.
- **Know each clip's own speed** (measure the root or the planted foot over a cycle) and play it so that clip speed =
  body speed. Within ±20 % change the **playback rate**; beyond that change the **stride length** (stride warping: scale
  the feet's forward reach, keep the cycle time) or blend to the next clip.
- **Blend between clips of matching phase.** Walk and run blended 50/50 with the left foot down in one and the right in
  the other gives a shuffling mess. Mark each clip's foot contacts (left down at 0 %, right down at 50 %) and sync the
  blend by phase (a sync group), not by time.
- **Foot lock** (FootPlant has it): pin the planted foot from contact to lift-off. Good. It only hides small errors; it
  cannot hide a 30 % speed mismatch.

### 4.2 Pops, snaps and jitters between clips

- Never cut; blend over 0.15-0.3 s, or better **inertialize** (keep the old pose's velocity and decay the difference
  over ~0.2 s), which never blends two incompatible poses.
- Pick the transition clip by the **current foot**: stop-left / stop-right, start-left / start-right, pivot-left /
  pivot-right.
- Leave a clip **at a matching pose** (both feet down, weight centred). The "exit step / exit climb to idle" fix (0.3 s
  standing) is this.

### 4.3 Traversal clips that don't fit the obstacle (the hard part)

A climb clip was recorded on one wall of one height. Fitting it to a different wall is **motion warping**:

1. **Author contact marks in each clip:** the frame each hand touches the top, the frame each foot touches the top, the
   frame the hands let go, and where the top's edge is in the clip's own space (its height and distance).
2. **Measure the world:** the edge's position, height, depth and facing (a few rays: forward at knee, waist, chest,
   head; down from above to find the top and its depth; from above the far side to find the landing).
3. **Pick the clip whose authored height is nearest** (keep clips for ~0.5, 1.0, 1.5, 2.0 m) and **warp only within
   windows**: from the start to the hand contact, move and scale the root so the hands arrive exactly at the edge; from
   the hand contact to the foot contact, scale the vertical rise to the real height; after, unwarped. Keep each scale
   inside ±20 %: beyond that the clip looks wrong; use the next clip.
4. **IK last:** hands pinned on the edge (HandGrip), feet on the top (FootPlant), only while the clip says they are in
   contact (a weight curve per limb, faded 0.1 s in and out).
5. **Root comes from the clip**, never a separate tween. The current code takes the clip's own rise out and moves the
   body "up, then over" itself; it works, but tends to show as hips that move on a different rhythm from the arms.
   Using the clip's root motion, warped to the edge, keeps the two in step.

### 4.4 The approach

- Detect obstacles **1.5-3 m ahead** (more when running), not on contact.
- Shorten or stretch the **last 2 steps** (±15 %) so the takeoff foot lands at the right distance (vault 0.8-1.2 m,
  climb 0.4-0.6 m, kerb: no foot on the edge).
- Turn the body square to the edge over the last step (a climb facing 30° off the wall looks wrong).

### 4.5 Life on top of the clips (cheap, big gains)

- **Head look-at**: toward the move direction 0.2-0.3 s before turning; at the edge before a climb; down before a drop
  or stairs going down; at a person talked to.
- **Lean**: into turns (atan(v²/gr)) and with acceleration (atan(a/g)), on the pelvis/spine, smoothed over 0.1-0.2 s.
- **Pelvis follows the lower foot** on uneven ground (FootPlant does).
- **Arms out** on narrow ground, **hand to the wall** at tight fast corners, **hand toward the door** as it nears.
- **Breathing / weight shifts** in idle: the weight moves foot to foot every 4-8 s.

### 4.6 A checklist to look at any clip frame by frame (bug B10)

1. A planted foot moves more than 1 cm while down? (slide)
2. The knee points away from the toes, or bends backward? (IK pole)
3. The ankle bent past 20° up or the heel through the floor? (ankle limit, heel should lift)
4. Both feet off the ground in a walk? Both feet down in a run's flight?
5. Hips move more than ~2 cm in one frame at 60 fps when not jumping? (pop)
6. Hands off their contact point while gripping? Fingers through the surface?
7. Shoulders level while hanging? (they should be shrugged)
8. The forearm twisting only at the wrist? (candy wrapper)
9. Head bobbing with the body, or turning after the body? (should lead and stay steady)
10. The transition picked the wrong foot? (stop / start / pivot by phase)

---

## Appendix - the thresholds in one table (proposal for the player)

| Situation | Measured | Action |
|---|---|---|
| up, < 3 cm | step height | foot IK |
| up, 3-16 cm | | in-stride kerb step (done, F9) |
| up, 16-24 cm | | obvious step up (StepUp) (done) |
| up, 24-50 cm | | big step / low climb (ClimbUp_1m) (done) |
| up, 0.5-1.2 m, top ≥ 25 cm deep | | mantle (both hands, knee up) |
| over, 0.5-1.1 m, thin, walking | landing lower beyond | step vault (hand + foot on top) |
| over, 0.8-1.2 m, thin, running | | speed vault (one hand) (Vault: done for fences) |
| over, 0.8-1.0 m, deep (bonnet) | | slide-over |
| over, 1.2-1.5 m, thin | | climb over (both hands, foot on top, swing, drop) |
| up, 1.2-2.5 m | top has room to stand | jump, hang or catch, pull, press, stand (ClimbUp_2m) (done) |
| up, > 2.5 m | | nothing (or a pipe / ladder if marked) |
| down, < 0.5 m | | step down in stride |
| down, 0.5-1.0 m | | hop down |
| down, 1.0-2.0 m | | jump down, deep landing; at an edge with no speed: hang-drop |
| down, 2.0-3.0 m | | hang-drop, or roll if moving fast |
| down, > 3.5 m | | hurt |
| ground width 10-30 cm | rays left and right | balance walk |
| width < 10 cm round | | slow balance walk / shuffle |
| headroom < 1.3 m | ray up | crouch |
| wall 0.8-1.2 m beside, crouched | | low cover |
| door within 1.5 m ahead | | slow, reach, push through / pull and step round |

---

## Part 5 - Mixamo files

Mixamo (Adobe, free) auto-rigs an uploaded mesh and retargets a library of mocap clips onto it. Its skeleton has
become a de-facto standard: thousands of clips and asset-store characters use it.

### 5.1 The skeleton

About 65 bones with the fingers, **no root bone: `Hips` is the top**. Names carry a prefix: `mixamorig:` normally,
`mixamorig1:`, `mixamorig2:` ... when the same account rigged several characters (a common cause of "the clip does not
play on my character": the prefix differs). Godot cannot keep `:` in a bone path, so on import the names appear as
`mixamorig_Hips` etc.

```
Hips
├─ Spine ─ Spine1 ─ Spine2
│                     ├─ Neck ─ Head ─ HeadTop_End          (LeftEye / RightEye on some characters)
│                     ├─ LeftShoulder ─ LeftArm ─ LeftForeArm ─ LeftHand
│                     │      └─ LeftHandThumb1-4, LeftHandIndex1-4, LeftHandMiddle1-4, LeftHandRing1-4, LeftHandPinky1-4
│                     └─ RightShoulder ─ ... (mirror)
├─ LeftUpLeg ─ LeftLeg ─ LeftFoot ─ LeftToeBase ─ LeftToe_End
└─ RightUpLeg ─ ... (mirror)
```

Things it does **not** have: twist bones (forearm, upper arm, thigh), IK helper bones (hand / foot IK targets, a
ground-level root), a jaw, prop bones. The forearm twist (1.2 rule 1) has to be made by the engine (Godot 4.6
`BoneTwistDisperser3D`, 6.4) or by careful skin weights.

### 5.2 The files

- **FBX**, binary, **1 unit = 1 cm** (the file carries a 0.01 scale). After import check that the hips are at ~1 m,
  not 100 m, and that the scale was applied to position tracks too.
- **Rest pose: T-pose** (arms straight out sideways). Y is up, the character faces +Z. Each bone's local Y points
  along the bone toward its child.
- Download options: **With Skin** (mesh + skeleton + clip) or **Without Skin** (skeleton + clip only: use it for
  every clip after the first); **Frames per second** (24 / 30 / 60; 30 by default); **Keyframe reduction** (none /
  uniform / non-uniform: use none, reduction causes foot slide); **In Place** (for moving clips: removes the hips'
  horizontal travel, keeps the bob).
- Per-clip sliders on the site: **Character Arm-Space** (pushes the arms away from the body so they do not go through
  a bulky mesh), **Overdrive** (speed), **Trim**, **Mirror**, and clip-specific ones (stride, height, energy).

### 5.3 Root motion and Mixamo

Because there is no root bone, **the travel is on `Hips`**. For root motion you make a root yourself:
1. Export **without In Place**.
2. Add a `Root` bone on the ground under the hips (in Blender; Godot's humanoid profile has a `Root`).
3. Move each frame's horizontal hips travel and heading (yaw) to `Root`; leave the hips' up-down bob, tilt and sway on
   `Hips`.

In Place clips have no travel, so the game must guess the speed: that is where foot slide comes from. With In Place,
measure the clip's real speed (a planted foot's travel per cycle) and store it with the clip.

### 5.4 Known quirks

- Mocap clips are cleaned, but many still **slide slightly**, and many have **feet a few cm into or above the floor**
  (the auto-rig places the ankle by guesswork). Foot IK and foot lock (FootPlant) cover this.
- The auto-rig guesses the knees, elbows and chin from the mesh; on stylised meshes the knees can point a little in.
- Retargeting between different proportions changes the stride: a walk put on shorter legs takes the same steps with
  shorter legs and slides. Root motion must be **scaled by the leg-length ratio** (Godot's "Normalize Position
  Tracks", 6.3).
- Many clips start and end on different feet or poses and do not loop cleanly: check the loop seam.

### 5.5 The names side by side (Mixamo, Godot's humanoid profile, 3ds Max Biped)

The player's figure uses **3ds Max Biped** names (`Bip01_*`, as in `native/src/hand_grip.cpp`). The three standards:

| Mixamo | Godot `SkeletonProfileHumanoid` | 3ds Max Biped |
|---|---|---|
| (none) | `Root` | `Bip01` (the root, on the ground) |
| `Hips` | `Hips` | `Bip01_Pelvis` |
| `Spine`, `Spine1`, `Spine2` | `Spine`, `Chest`, `UpperChest` | `Bip01_Spine`, `Bip01_Spine1`, `Bip01_Spine2` |
| `Neck`, `Head` | `Neck`, `Head` | `Bip01_Neck`, `Bip01_Head` |
| `LeftShoulder` | `LeftShoulder` | `Bip01_L_Clavicle` |
| `LeftArm` | `LeftUpperArm` | `Bip01_L_UpperArm` |
| `LeftForeArm` | `LeftLowerArm` | `Bip01_L_Forearm` |
| `LeftHand` | `LeftHand` | `Bip01_L_Hand` |
| `LeftHandThumb1-3` | `LeftThumbMetacarpal`, `-Proximal`, `-Distal` | `Bip01_L_Finger0`, `Finger01`, `Finger02` |
| `LeftHandIndex1-3` | `LeftIndexProximal`, `-Intermediate`, `-Distal` | `Bip01_L_Finger1`, `Finger11`, `Finger12` |
| `LeftHandMiddle1-3` | `LeftMiddleProximal` ... | `Bip01_L_Finger2`, `Finger21`, `Finger22` |
| `LeftHandRing1-3` / `LeftHandPinky1-3` | `LeftRing...` / `LeftLittle...` | `Finger3x` / `Finger4x` |
| `LeftUpLeg` | `LeftUpperLeg` | `Bip01_L_Thigh` |
| `LeftLeg` | `LeftLowerLeg` | `Bip01_L_Calf` |
| `LeftFoot` | `LeftFoot` | `Bip01_L_Foot` |
| `LeftToeBase` | `LeftToes` | `Bip01_L_Toe0` |

Two Biped traps: in a default Biped the **clavicles hang from the neck**, and the **thighs hang from the first spine
bone, not the pelvis**. Rotating `Bip01_Pelvis` then does not carry the legs, and code written for Mixamo (legs under
the hips) moves the wrong bones. Check the player's hierarchy before writing any pelvis tilt or hips IK.

---

## Part 6 - Godot's skeleton system (4.4-4.6)

### 6.1 The pieces

| Node / resource | What it is |
|---|---|
| `Skeleton3D` | the bones: each has a **rest** (bind pose) and a **pose** (position, rotation, scale, local to its parent). `get_bone_pose*` is local; `get_bone_global_pose` is in the skeleton's space (times the node's `global_transform` for world). |
| `Skin` / `MeshInstance3D.skin` | binds the mesh to the bones |
| `BoneAttachment3D` | a node that follows (or drives) one bone: a prop in the hand, a camera on the head |
| `AnimationMixer` (base of `AnimationPlayer`, `AnimationTree`) | plays clips onto the skeleton |
| `AnimationTree` | the blend graph: `AnimationNodeStateMachine`, `BlendSpace1D` / `2D`, `BlendTree` with `OneShot`, `Transition`, `TimeScale`, `TimeSeek`, `Add2`, `Blend2` |
| `SkeletonModifier3D` (4.4+) | a child of `Skeleton3D` that changes the pose **after the animation**: IK, look-at, springs, constraints, ragdoll. The player's `HandGrip` and `FootPlant` are these. |
| `PhysicalBoneSimulator3D` + `PhysicalBone3D` | ragdoll: bones driven by physics bodies, blended by `influence` |

### 6.2 One frame, in order

1. The `AnimationMixer` advances and writes the clips' blended pose. Its `callback_mode_process` is **physics, idle or
   manual**. For a `CharacterBody3D` moved in `_physics_process`, use physics (or manual, calling `advance(delta)` right
   after moving the body) so the clip and the body move on the same tick.
2. **Root motion**: with the mixer's `root_motion_track` set (e.g. `%GeneralSkeleton:Root`), that bone's movement is
   **not** applied to the bone; it is handed over each tick (`get_root_motion_position()`,
   `get_root_motion_rotation()`, and accumulators). You move the body by it (velocity = the rotated root delta / delta,
   then `move_and_slide()`). Blended clips blend their root motion too.
3. The skeleton's **modifiers** run one after another (in their order as children; each sees the pose the one before
   left), each blended in by its `influence`. A modifier overrides `_process_modification_with_delta(delta)` and
   applies its full result (the skeleton applies the influence; `delta` may be 0 just after init). The signal
   `modification_processed` fires when one finishes: the moment to read the final pose.
4. Skinning: the mesh is drawn.

So a sensible modifier order for the player: foot plant / pelvis (legs and hips) → hand grip (arms; needs the hips
final) → look-at (head; needs the chest final) → twist disperser and angular-velocity limit last.

### 6.3 Importing and retargeting

- Import dock, **Retarget > Bone Map**: create a `BoneMap` with `SkeletonProfileHumanoid`. Godot auto-maps common English
  bone names (Mixamo maps by itself; Biped mostly, check the fingers and clavicles).
- **Rename Bones** renames the skeleton to the profile's names (`Hips`, `LeftUpperLeg` ...). After that, **every clip
  imported the same way plays on every character imported the same way**.
- **Rest Fixer** makes the rests match Godot's reference: T-pose, facing +Z, Y up, +Y from a joint to its child, +X
  rotation bends like the muscle contracting.
  - **Overwrite Axis**: rewrites every bone's axes to that convention. The page calls it the most important option for
    sharing clips; it breaks anything that relied on the original rest (bone rotations written in code).
  - **Fix Silhouette**: turns an A-pose model into a T-pose rest (a filter for bones to leave; a height adjustment for
    bent knees).
  - **Normalize Position Tracks**: divides position tracks by the hips' height (`motion_scale`), so root motion fits a
    taller or shorter body.
  - **Remove Tracks**: drop position tracks of unimportant bones (mocap has noisy position keys on every bone, which
    stretch limbs on another body); `Root` and `Hips` are kept.
- At runtime (4.4+) `RetargetModifier3D` lets one animated skeleton drive differently shaped bodies.

### 6.4 The modifier family (Godot's "Inverse kinematics returns to Godot 4.6" article and class reference)

| Version | Modifier | Use for the player |
|---|---|---|
| 4.4 | `LookAtModifier3D` | head and eyes leading turns; looking at an edge or a person |
| 4.4 | `RetargetModifier3D` | one clip skeleton for many bodies |
| 4.5 | `SpringBoneSimulator3D` | hair, jacket, bag straps: secondary motion |
| 4.5 | `BoneConstraint3D`: `AimModifier3D`, `CopyTransformModifier3D`, `ConvertTransformModifier3D` | e.g. a twist bone taking part of the hand's roll; in 4.6 it can target any `Node3D` |
| 4.5 | `ModifierBoneTarget3D` | a node that sits on a bone after modification |
| 4.6 | `TwoBoneIK3D` | legs and arms (always deterministic) |
| 4.6 | `ChainIK3D` > `SplineIK3D` (deterministic); `IterateIK3D` > `FABRIK3D`, `CCDIK3D`, `JacobianIK3D` | spines, fingers round a pipe |
| 4.6 | `BoneTwistDisperser3D` | spreads a child's twist up its parents: the forearm twist (1.2 rule 1) |
| 4.6 | `LimitAngularVelocityModifier3D` | caps how fast bones may turn: removes IK pops |

`SkeletonIK3D` (the old node) still exists, deprecated. `IterateIK3D` can carry its state between frames (smooth, but
the pose depends on history) or be deterministic (same input, same pose; with few iterations it may not reach). The
article suggests the angular-velocity limit to calm the jumps deterministic IK can make. The player's IK is hand-written
C++ (`HandGrip::reach`, a two-bone reach), which is fine; the 4.6 nodes are the drop-in alternative.

### 6.5 Other Godot pieces that matter for traversal

- **Animation markers** (4.4+): named times inside a clip. Use them for foot contacts (`L_down`, `R_down`), hand
  contacts (`hand_on_edge`) and warp windows (4.3).
- **BlendSpace `sync`**: keeps the clips of a blend space running at zero weight so they stay in step. It syncs by
  time, so the clips need **the same length and the same foot timing** (cut walk and run to one stride each, left foot
  down at 0).
- **Physics interpolation** (3D since 4.4): if physics ticks at 60 Hz and the screen draws at another rate, a body
  moved in physics and a figure posed in idle shake against each other. `project.godot` does not set it.

---

## Part 7 - Jolt physics

### 7.1 What it is

Jolt (by Jorrit Rouwe, open source; used in Horizon Forbidden West and Death Stranding 2) is a multi-core rigid-body
engine. Godot added it in 4.4 and made it the **default for new projects in 4.6**; existing projects keep their setting.

**This project:** `project.godot` sets only `3d/physics_engine.android="Jolt Physics"`. **The phone runs Jolt; the PC
runs the default engine (Godot Physics).** Every climb, kerb and step tested on the PC runs on a different collision
engine from the phone. Margins and contact normals differ (7.3), so a threshold tuned on the PC can behave differently
on the Redmi.

### 7.2 How it works (the parts that matter to a character)

- **Broad phase**: a tree of bounding boxes in layers (Godot maps its collision layers and masks onto it).
- **Narrow phase**: GJK / EPA on **convex shapes with a convex radius**: boxes and cylinders are slightly rounded.
- **Solver**: sequential impulses with position correction (the Baumgarte factor); bodies that stop fall asleep in
  islands.
- **Triangle meshes** (`ConcavePolygonShape3D`: the city's ground and buildings): a moving shape can catch on the inner
  edge between two triangles ("ghost collisions"). Jolt has active-edge detection and an enhanced internal-edge removal
  against it (7.3).
- Jolt has its own character controllers, `Character` (a rigid body) and `CharacterVirtual` (a kinematic shape with
  built-in stair walking and stick-to-floor). **Godot does not use them**: `CharacterBody3D` is Godot's own
  `move_and_slide()` on shape casts. So in Godot **no engine walks stairs for you**: kerbs and steps are the game's job
  (as CityPlayer does).

### 7.3 Differences from Godot Physics that touch the player (Godot 4.6 "Using Jolt Physics")

- **Collision margins**: Jolt shrinks the shape by the margin, then adds it back as a rounded shell: the size stays,
  **the corners round off**. The margin is `Collision Margin Fraction` × the shape's smallest side, capped by the
  shape's `margin`. The page warns margins can give odd normals in shape queries: a body touching a kerb's corner can
  get a tilted normal.
- **Ghost collisions**: `Collisions > Active Edge Threshold` and `Simulation > Use Enhanced Internal Edge Removal` (and
  the same for queries and motion queries). They do not help between two separate bodies (a kerb mesh meeting a road
  mesh).
- **Ray casts**: `face_index` is always -1 unless `Queries > Enable Ray Cast Face Index` is on (about 25 % more memory
  on triangle meshes). It matters if footstep sounds or surfaces are looked up by face.
- **Kinematic bodies** do not touch static or other kinematic bodies unless `Simulation > Generate All Kinematic
  Contacts` is on.
- **Contact impulses** are estimates (exact only when the two bodies touch nothing else): do not judge how hard a hit
  was from them.
- `Area3D` does not see static bodies by default (`simulation/areas_detect_static_bodies`).
- Physics on its own thread (`Run On Separate Thread`) is marked experimental; the phone rig uses it.

### 7.4 The capsule and the kerb (geometry, any engine)

`move_and_slide()` takes a contact as floor if its normal is within `floor_max_angle` (45° by default) of up. A capsule
of radius r touching the top edge of a step of height h gets a normal tilted by acos((r − h) / r):

| capsule radius | step 5 cm | step 10 cm | step 15 cm |
|---|---|---|---|
| 0.25 m | 37° (floor: rides up) | 53° (wall) | 66° (wall) |
| 0.30 m | 34° (floor) | 48° (wall) | 60° (wall) |
| 0.35 m | 31° (floor) | 44° (floor: rides up) | 55° (wall) |

A 0.3 m capsule rides over edges up to about 9 cm by itself (with a bump as it rolls over the edge) and stops at a
real kerb. So the step-up has to be the game's own (done), and it should decide alone: lift the body by the measured
height, and keep the capsule's bottom off small edges. The common pattern is a "floating capsule": the capsule held a
step-height above the ground by a ray or shape cast, so small edges never touch it. Other `CharacterBody3D` settings
that matter: `floor_snap_length` (stays on the ground going down kerbs and slopes), `floor_constant_speed` (same speed
up and down a slope), `floor_stop_on_slope`, `floor_block_on_wall`, `safe_margin` (0.001), `max_slides` (6).

---

## Part 8 - How Rockstar does it (GTA IV / V, RDR 1 / 2)

Sources: Rockstar's interviews about Euphoria, the GDC listing of Mike Jones's talk "Filling Marston's Boots: Player
Locomotion in Red Dead Redemption 2" (I found no slides or recording), what the games show, and what their modding
scene knows. Rockstar has published little about its animation internals; points marked *observed* come from watching
the games, not from Rockstar.

### 8.1 The technology

- **RAGE** (Rockstar Advanced Game Engine) runs all four games.
- **Euphoria** (NaturalMotion): an "active ragdoll". The body is simulated as physics, and small controllers drive its
  muscles: balance, a step to catch itself, arms out when falling, grabbing onto things, protecting the head. It is
  blended with ordinary animation: a person walks on clips, is hit, Euphoria takes the body, a get-up clip takes it
  back. GTA IV (2008) was its first big use; then RDR, GTA V, and RDR2, where Rockstar said it had "really evolved" it,
  for people and animals.
- **Animation data** (*from modding*): clips sit in "animation dictionaries"; walking styles are **clipsets** swapped
  per person (`move_m@drunk@...`, `move_m@brave`, `move_f@...`), so one locomotion system plays many personalities;
  blending runs in node networks ("MoVE" networks) that scripts drive.

### 8.2 GTA IV (2008) and RDR (2010): weight first

- *Observed:* heavy momentum: starts and stops take steps, turns at a run plant and pivot, the body leans into curves.
  Weighty, sometimes sluggish.
- Euphoria everywhere: stumbling down stairs when pushed, grabbing a car when hit, staggering when shot, drunk walking.
- Rockstar's first **cover system** (IV): a button snaps to cover; blind fire; peek over or round; move along it.
- *Observed:* climbing from one jump button: near a ledge it becomes a grab and pull-up, chosen by height. Ladders are
  their own mode. Low fences are climbed rather than vaulted at speed.

### 8.3 GTA V (2013): control first

- *Observed:* less momentum than IV: quicker starts, tighter turns, sprint by tapping; Euphoria toned down. A
  deliberate swap of realism for control.
- *Observed:* context traversal from the jump button: a low obstacle is vaulted, a mid one climbed, a high one jumped
  at and climbed if reachable, chosen by the measured height (the same idea as CityPlayer's height bands).
- Jumping down: a landing stumble or roll from medium heights; above that a Euphoria fall.
- A crouched stealth walk with its own clipset; per-character walking styles (Michael, Franklin, Trevor) by clipset.

### 8.4 RDR2 (2018): realism first

- *Observed:* Arthur's movement is **animation-led**: a step finishes before he turns, starts and stops pick the foot,
  a 180° turn is a real pivot. Many players called it sluggish; that is the price of the weight.
- Speed from the stick's lean plus tapping to run; a forced slow walk in camp; gaits change with terrain, and deep snow
  and mud slow him and lift his knees.
- *Observed:* feet and hips fitted to the ground everywhere (slopes, rocks, stairs) and **hands touching the world**
  (pushing doors open while walking through, a hand on a horse).
- People turn their heads to look at the player and at events.
- Climbing is contextual (fences, rocks, wagon beds, onto horses); fence vaults with a hand on the rail; no free
  climbing on walls.
- Bumping in crowds is physical: people shoulder each other and react.

### 8.5 What Coronado can take from them

1. **Choose the feel on purpose**: GTA V's responsive or RDR2's weighty. A touch-controlled phone game leans GTA V:
   commit to an animation only where it reads (a pivot, a climb) and keep starts and stops short (0.2-0.4 s).
2. **One button, chosen by height** (all four games): what CityPlayer already does. Add the vault / climb-over split by
   speed and the obstacle's depth (3.2).
3. **Walking styles as data** (clipsets): a set of clips per personality, swapped per person, for the crowd and for the
   player's states (tired, drunk, hurt).
4. **Physics balance under clips** (Euphoria): the crowd's ped_body already catches shoves with steps (F6); the same
   idea for the player on bumps and landings.
5. **Hands and eyes on the world**: look-at, a hand on doors and walls, pinned grips; the details people remember.

### Sources (parts 5-8)

- [Inverse kinematics returns to Godot 4.6](https://godotengine.org/article/inverse-kinematics-returns-to-godot-4-6/)
- [SkeletonModifier3D class reference (4.6)](https://docs.godotengine.org/en/4.6/classes/class_skeletonmodifier3d.html)
- [Retargeting 3D skeletons (4.6)](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/retargeting_3d_skeletons.html)
- [Using Jolt Physics (4.6)](https://docs.godotengine.org/en/4.6/tutorials/physics/using_jolt_physics.html)
- [Godot 4.6 release notes](https://godotengine.org/releases/4.6/)
- [GDC: Learn the secrets of Red Dead Redemption 2's player locomotion](https://gdconf.com/news/learn-secrets-red-dead-redemption-2s-player-locomotion-gdc)
- [Rockstar on Euphoria in RDR2 (wccftech)](https://wccftech.com/rockstar-euphoria-evolved-rdr2/)
- [Euphoria (software), Wikipedia](https://en.wikipedia.org/wiki/Euphoria_(software))
- [Mixamo bone naming (mocaponline guide)](https://mocaponline.com/blogs/mocap-news/skeleton-hierarchy-animation-guide)
