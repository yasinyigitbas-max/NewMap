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

## Round 3: key poses + Kimodo in-betweening, 16 samples, automatic scoring (25 Nov, ~$0.60)
**Two facts found:**
1. **A pin is a whole-body keyframe**: Kimodo matches every joint of the pinned pose exactly (0° off), hips included. So
   the pinned poses decide the move. I built 4-5 key poses per move from study v2 6.1 / 6.2 with my own IK on Kimodo's
   skeleton (hands on the edge, the press, a foot up, standing on top) and let Kimodo make the motion between them.
2. **A period in the prompt starts a new segment** on this deployment: "1.5 meter" split the prompt in two and doubled the
   clip; the second half kept "climbing" by itself. That broke the vault and climb of rounds 1 and 2 (the step-up had no
   decimal point and was the good one). Heights are now written in words.

**Scores (best of 16; hands = how far the hands slide on the edge between key poses; wall = deepest point inside the
wall; knees = frames with a knee bent backward, signed as study v2 1.3):**
| Move | Hands | Wall | Ends on top / lands | Knees | Looked at on the body |
|---|---|---|---|---|---|
| climb 1.5 m | 14 cm | 11 cm (toes / shins at the face) | yes, within 4 cm | 0 | **Believable**: walks in, crouches, jumps, hands on the edge, chest over, legs swing up, stands on top. |
| mantle 0.8 m | 13 cm | 4 cm | yes, within 4 cm | 0 | **Good**: hands on top, hop, foot up, stands. Reads like a real low mantle. |
| step vault 1.0 m | 10 cm | 14 cm | lands, but then jumps again | 1 | **Not usable**: crouches on top, drops back, then a big extra jump. |

**What the layered system would still do to them** (normal work, study v2 10.7): pin the hands on the real edge with IK
while they grip (removes the 13-14 cm slide), keep toes and shins out of the wall face, warp the height ±20 %, and run
them through the v2 validator. The vault needs better key poses (the take-off, the hand, the foot on top, the landing,
running on) and another round.

## Correction (same evening)
Yasin's screenshots showed the mid-section going through the wall and a backward knee in the round 3 climb and mantle.
Both come from my side, not Kimodo's: my retargeter bends player_v3's mesh knee ~29° backward whenever the source leg is
straight (STATUS #14), and the retargeted motion is scaled by the leg ratio so it no longer meets the wall I drew
(STATUS #15). My scores were measured on Kimodo's skeleton, not on the body (STATUS #16). **The round 3 verdict
("believable", "good") is withdrawn** until the retargeter is fixed and the clips are re-checked on the body.

## Round 3, redone after Yasin's review (25 Nov, late evening, ~$1.20 more)
Yasin saw backward knees and a lost mid-section. Measured on the body (`tests/clip_audit.gd`, now with its own forward
kinematics and a mutation test), the causes were, in order found:
1. **My retargeter** swung each leg bone separately and bent the mesh knee 16-19° backward (fixed: limbs swung whole;
   STATUS #14).
2. **My key poses**: thighs twisted round 116-171° (knee pointing back) and hips folded 167-180° (the waist mesh
   collapses). The key-pose builder now refuses any pose past the study's hip rotation (in 40° / out 50°) and hip
   flexion (125°) and any body volume inside the wall (capsules, 3 cm), before a run is paid for.
3. **My first audit tool never applied the pose** (it measured the rest pose); rewritten.

**Result of the redone round (16 samples each, judged on the body):**
| Move | Samples with 0 frames past the joint limits | Body inside the wall (best sample) | Looked at |
|---|---|---|---|
| climb 1.5 m | 6 of 16 | **24 cm** (a thigh, frame 69) | believable climb, but the knees go into the wall face as the legs come up |
| mantle 0.8 m | 6 of 16 | **11 cm** (a thigh, frame 53) | good mantle, thighs into the wall during the hop |
| step vault 1.0 m | left out: its key poses didn't pass the gates | | |

**Why the wall can't be fixed by picking samples:** the key poses are clear of the wall on Kimodo's skeleton, but
retargeting scales the legs and hips (0.84) and not the arms, so with the hands on the edge the body sits closer to the
wall than in the source. Keeping the body out of the wall has to happen after retargeting, in the layered system's
traversal layer (study v2 10.7 warping + 6.12 contacts, with the v2 validator): hands pinned on the real edge, the body
moved back and the knees kept off the wall face. That is step 6 work.

**Answer to "is there hope for Kimodo clips":** for locomotion and gestures, yes. For climbs and mantles, yes as base
motion, but only together with the traversal layer that fits them to the wall on the body; they are not usable raw.
The vault needs more work.
