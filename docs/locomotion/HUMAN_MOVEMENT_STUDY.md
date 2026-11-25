# How people really move: a study for Coronado's locomotion and traversal

Written 25 Nov 2026 for Yasin, as a reference for the player's animation (CityPlayer, HandGrip, FootPlant in
`native/src`). Numbers are typical adult values (about 1.75 m tall, leg about 0.9 m) from standard gait and range-of-motion
references (Perry's gait analysis, AAOS joint ranges, stair and parkour studies). They are averages: real people vary
by about ±15 %.

Part 1 is the body. Part 2 is everyday walking and running. Part 3 is the city's obstacles, by height. Part 4 is why
animation usually looks wrong, and the techniques that fix it.

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
