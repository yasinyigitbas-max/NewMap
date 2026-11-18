# The budget: each system's share (19 Nov 2026, PROPOSAL, waiting for Yasin)

Yasin: "i think we are gonna shoot way above budget once the cars and these areas land. we need a way to trim down
costs somehow. scripts arent even in yet". This page gives every system a share of the frame, so that a system is
judged against ITS share the day it lands, not against whatever is left. The shares are a proposal by the PC session;
the measured numbers are from the Redmi (Mali-G610), debug build, one run each.

Target (Yasin, the game's rule): locked 60 fps = 16.7 ms a frame. The Redmi at 720p is the test phone.

## 1. Draw calls: 150 in the worst view (Yasin: "keep draw calls as low as possible")

Measured today, standing street views (`review/phone/census_x15_day.txt`; a kind's draws = the view's draws minus the
draws with that kind hidden). Nothing of cars, people or rooms is in these numbers.

| Kind | centre | apartments | gritty | waterfront | industrial | pilot | civic |
|---|---|---|---|---|---|---|---|
| ALL | 103 | 118 | 100 | 112 | 96 | 79 | 106 |
| sun shadow pass (near things drawn a second time) | 21 | 37 | 28 | 35 | 22 | 22 | 29 |
| props near + mid | 30 | 37 | 35 | 34 | 25 | 32 | 35 |
| trees and plants | 23 | 28 | 21 | 27 | 14 | 16 | 28 |
| buildings near + mid | 26 | 34 | 18 | 28 | 31 | 12 | 18 |
| ground, wear marks, far world, far ground, other | 21 | 16 | 23 | 20 | 23 | 16 | 22 |

(The kinds add up to more than ALL: hiding a kind also removes its draws from the shadow pass.)
While DRIVING the worst view is higher: 196-198 draws (`native1_stream`, 79-82 on average); apartments 189 and
7th St 191 in the zones test. So the city alone is over 150 in its worst views before anything else lands.

What is coming (estimates of the sessions that build them, not measured):
- cars, moving and parked: 10-25 draws, up to 28 (`docs/TRAFFIC_PEOPLE_PORT.md`);
- people: about 30 (18 animated bodies near the player + far figures);
- rooms: 21-41 draws EACH as built today, 9 in the merge prototype; not in the phone build at all yet.

THE SHARES (worst view, everything on):

| System | Share | Today | What has to happen |
|---|---|---|---|
| City: buildings | 22 | 12-34 | hold |
| City: props | 25 | 25-37 | bigger near batches, small props out of the mid tier sooner |
| City: trees and plants | 13 | 14-28 | the tree plan (`docs/TREE_PLAN.md`) |
| City: ground, wear, far world, other | 20 | 16-23 | hold |
| City: sun shadow pass | 20 | 21-37 | only buildings and the nearest trees cast; props under 2.5 m do not |
| Rooms in view | 12 | 0 (not in) | 3 draws a room (the bake's texture arrays), at most 4 rooms drawn at once |
| Cars, moving and parked | 15 | 0 (not in) | one batch per model and distance; a small set of car models per district |
| People | 15 | 0 (not in) | 8-10 animated bodies near the player, the rest in one or two batches, blob shadows |
| Sky, sea, weather, effects | 4 | not counted on its own | hold |
| HUD and menus | 4 | not in | hold |
| TOTAL | 150 | | |

The city's share is 100. It is at 79-118 standing and up to 198 while driving, so the first job is to find what the
driving worst view is made of (the census stood still; `rt_shots.gd --probe --detail` on the PC gives counts by kind for
any camera, and counts are valid on the PC).

## 2. The main thread: 11 ms of the 16.7, the rest spare

| Work on the main thread | Share (ms) | Today |
|---|---|---|
| The engine sending the draws | 3.0 | 2.4-2.9 at 1.5 x, 1.1-2.8 at 720p |
| The streamer (cells in and out, collision bodies) | 2.0 | inside it: 2 ms a frame for bodies, 1.5 ms for removal |
| Traffic and people (their thinking runs on their own threads; this is only handing results over) | 1.5 | not in |
| Game scripts: player, camera, missions, jobs, shops, save | 2.5 | not in |
| Waiting for the physics thread | 1.0 | 0.5 median, 6-7 at 99 % |
| HUD, sound, input, everything else | 1.0 | not in |
| SPARE (heat, a slow frame, a busy moment) | 5.7 | |

Rule that follows: nothing that runs every frame for every car or every person may be a script. That is already
Yasin's word for traffic and people ("everything must be in C PLUS PLUS").

## 3. The graphics chip (GPU)

At 720p the phone slows its GPU clock while it can still make 60 fps, so GPU time read there does not show how much room
is left (`docs/DRAW_CENSUS.md`). Costs can only be compared with the GPU kept busy: the census at 1.5 x the full screen.
So the GPU budget is written for THAT measurement, and the real pass / fail is the gate in section 5.

| At 1.5 x full screen, heaviest view | Share (ms) | Today (apartments / civic) |
|---|---|---|
| Trees and plants | 4 | 10.9 / 15.2 |
| Near buildings | 5 | 7.0 |
| Sun shadows | 3 | 4.9 |
| Sky reflection | 2 | 5.1 |
| Smoothing pass (FXAA) or the upscaler | 3 | 3.9 |
| Near props | 2.5 | 2.6 |
| Wear marks | 1 | 1.9 |
| Ground, far world, mid tiers, other | 2.5 | about 2 |
| Cars | 3 | not in |
| People | 2 | not in |
| Rooms | 2 | not in |
| TOTAL | 30 | 40.9 / 37.2 with none of the last three |

Where the cuts are, largest first (all measured, apartments / gritty):
1. Trees 10.9 / 3.4: new models (`docs/TREE_ARTIST_BRIEF.md`), fewer and better placed (`docs/TREE_PLAN.md`), plants to
   the mid tier sooner, only the nearest trees in the shadow.
2. Sky reflection 5.1 / 3.2: a plain sky colour for everything but glass and water. A look change: Yasin's call.
3. Near buildings 7.0 / 3.3: the detailed shader only within about 30 m (3.8 / 2.5 of it is the shader).
4. Sun shadows 4.9 / 3.4: a 2048 map saves 2.4 / 2.0.
5. FXAA 3.9 / 3.6: goes when the engine's upscaler does the smoothing.
6. Wear marks 1.9 / 1.9: fade out at 40-50 m, not 90 m.

## 4. Memory, collision, streaming
- Memory: 905 MB in all at 60 s today, 584 MB of it graphics (the engine's own count: 190-290 MB; the rest is thought
  to be the driver's block size, an engine-build matter, not proven). PROPOSED CAP: 1.2 GB with everything on. That
  leaves about 300 MB for cars, people, rooms, sound and scripts. Yasin's call; a phone with less memory than the
  Redmi needs a lower one.
- Collision: at most 216k units within 100 m of the road ahead (today's densest place: about a quarter of that).
- Streaming: the gate in `tools/city/rig/health.py`, unchanged.

## 5. The gate (what PASS means for the whole game on the phone)
A run of the zones test and the stream loop at 720p with EVERYTHING on, after the phone is warm (15 minutes in):
- the streaming gate passes (no late cell, no frame over 50 ms, at most 0.2 % of frames over 33 ms, teleports in 3 s);
- the median frame sits on the 60 fps step in every zone, day and night;
- no view over 150 draws;
- memory under the cap at the end.
Each system that lands brings a table against the same run WITHOUT it: draws, main-thread ms, GPU ms, memory. Over its
share = it goes back, however good it looks. The traffic plan already works this way (stages 2d, 3b).

## 6. What is not known
- How much room the phone has at 720p (the GPU clock hides it). Only the gate run with everything on answers it.
- What a release build gains. Every number is from a debug build (Yasin: "dont make the release build yet").
- The grown zones (residential above all) and the rooms have never been on the phone.
- The shares are judgment, not measurement. They are a starting split to be corrected by the first real numbers.
