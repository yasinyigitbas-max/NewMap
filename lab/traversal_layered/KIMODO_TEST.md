# Kimodo test (NVIDIA motion model, via replicate.com/sprited/kimodo), 25 Nov 2026

Asked by Yasin: can it give one consistent, gap-free set of locomotion, traversal and gesture mocap?
14 runs (about $0.40), text prompts only, no constraints yet. Each clip went through the **same retargeter** as the
Mixamo clips (only a bone-name map added: `tools/clip_build.gd` `SOMA_TO_MIXAMO`) and was looked at on player_v3
(`tests/clip_view.gd`, side and front). The generated files are kept out of the repo.

## What it gives
- 30 fps, 77-joint skeleton **with fingers and toes**, per-frame foot contacts, metres, Y up, facing +Z. Its GLB rest is a
  clean T-pose, so it retargets the same way as Mixamo.
- ~30 s per run on Replicate, ~3 US cents. Up to 16 samples per run. Commercial use allowed by the model card
  ("ready for commercial use", NVIDIA Open Model License): Yasin should read the licence.
- Pins: whole-body pose at chosen frames, the ground path, each hand and foot (position and rotation). No foot-contact
  input, no "continue from this pose" (pin the whole body at frame 0 instead). Not aware of objects (model card).

## What it did (looked at on the body)
| Clip | Verdict |
|---|---|
| walk (6 s) | **Good.** Natural walk, heel strikes, real double support (60/40), arms in phase. Came with its own start and stop. |
| run (5 s) | **Good.** Start, run with flight, stop. Slower than asked (a jog). |
| walk stop (3 samples) | **Good.** Stops in about 2 steps (Mixamo's stop takes 3 slow ones). The samples stop on different feet, so left- and right-foot stops come from picking samples. |
| run stop (2) | Usable. |
| run pivot 180 (2) | One sample did a real braking reversal (plant, turn, run back); the other ignored the turn. |
| start turning 90° left (2) | **Good.** 90° and 98°: turns, then walks. |
| idle with weight shifts | Usable. |
| wave, talk + point | **Good.** Clear gestures, hands and fingers moving. |
| step up 40 cm | Plausible step-up motion onto an imagined step (height not controlled). |
| vault 1 m | **Not usable as is.** Jumps up onto an imagined box; no hand on a top that I can line up with our wall. |
| climb 1.5 m | **Not usable as is.** Hops up onto an imagined wall; no clear hands-on-top, pull and press. |
| drop 1 m | Plausible hop down (not yet looked at closely). |

## Answer
- **Locomotion and gestures: yes, it can fill the gaps consistently.** It's one style and one skeleton, and it can make
  exactly the clips Mixamo lacks (stops per foot, turn-starts, pivots, weight shifts). Expect to make 2-4 samples per
  clip and keep the best.
- **Traversal: not from text alone.** It doesn't know the obstacle, so heights, hand contacts and timing are invented.
  Still to test: pinning the hands on the edge and the feet on the top at chosen frames, then judging whether the
  pull-and-press (study v2 6.1) comes out right. Untested, so unknown.
- **"Gap-free" is not guaranteed.** Some samples ignore the prompt, and the clips still need our measuring, cutting,
  warping and the v2 validator like any other source.

## Round 2: heights in metres and pinned hands / feet (25 Nov, 3 runs x 4 samples, ~$0.15)
Pins built in Kimodo's own pose format (checked: my forward kinematics matches its joints to 0.001 mm). Poses taken
from earlier Kimodo frames (or built: arms up for the climb), turned to face the wall and moved so the hand / foot lands
exactly on the edge; plus the ground path. Scripts and pins kept outside the repo with the outputs.

| Test | Pins | Result |
|---|---|---|
| step vault, 1.0 m wall 0.3 m thick | left hand on top (frame 33), left foot on top (39), path | Pins hit exactly (0.0 cm). Between them the body does whatever it likes: a leap, a walk, a jump up to 2.4-2.7 m hip height, a crouch; 3 of 4 samples end standing 1.3-1.5 m up in the air. **Not usable.** |
| climb, 1.5 m wall | both hands on the edge (38 and 70), left foot on top (105), path | Pins hit exactly. Hands drift 9-108 cm between the two hand pins (not held), and the body keeps climbing invisible things: hips reach 3.6-4.3 m. **Not usable.** |
| step up, 0.4 m box | right foot on top (45), left foot (72), path | Pins hit (3 of 4 within 1 cm). A real big step up: knee lifts, weight goes over the front foot, he stands on top. Ends ~13 cm higher than the box. **Usable with a little fixing.** |

**Why**: a pin is met only on its own frame; the model still doesn't know the obstacle exists, so it doesn't keep hands
on the edge or feet on the top between pins, and doesn't stop at the top. Denser pins (every few frames) would force it,
but then the pins are the animation and the model adds little.
