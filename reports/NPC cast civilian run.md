# NPC cast: one civilian run of every body (27 Nov 2026)

Yasin, 27 Nov: "can you test the other npcs while adding the new moves?"

Every one of the 50 NPC bodies, and the player as the yardstick, was put through the same run in the lab on the C++
version: standing, walking and running on the flat, two kerbs, two single steps, two ramps, both stairs, the text
key, the bench (walk to it, sit, get up) and the car (in, out). The run only measures; it has no pass bar of its
own. The numbers were read; the bodies were NOT looked at in frames in this run.

**What it shows**
- All 51 runs finished with no error. Every body completed every move: walked both stairs to the top (1.08 m and
  1.50 m), sat on the bench and stood up again, got into the car and out, and ended standing on the ground.
- Walking, the lowest foot joint of every body stays at one height to within about 1 cm, like the player's, except
  **npc_09** (2.6 to 6.7 cm) and **npc_18** (2.3 to 4.8 cm): their planted foot rises and falls. To look at.
- Every body walks at the player's pace (1.43 m/s) and runs at his (4.19 m/s): they have their own stride but not
  yet their own pace (open on the job board).
- Seated on the bench the player's lowest foot joint is 3.0 cm over the ground. The shorter bodies' feet hang:
  **npc_14** 9.9 cm, **npc_09** 8.7 cm, **npc_17** 8.2 cm, **npc_25** 8.1 cm; 22 bodies are over 5 cm.
- Seated, the hips of **npc_18** (50.9 cm) and **npc_31** (52.9 cm) are lower than the others' (57 to 62 cm), and
  **npc_09**'s are higher (65.1 cm). To look at.
- Not measured here: the hands (the texting grip, hands on the wheel), the head, the door, cover, and how any of it
  looks.

| body | hips standing (m) | head joint (m) | lowest foot, walking (cm) | walk (m/s) | run (m/s) | seated hips over the ground (cm) | seated lowest foot (cm) | sat and got up | lowest foot in the car (cm over its floor point) | in and out |
|---|---|---|---|---|---|---|---|---|---|---|
| npc_01 | 0.97 | 1.54 | 2.4 to 2.8 | 1.43 | 4.19 | 59.4 | 2.4 | yes | 33.4 | yes |
| npc_03 | 0.95 | 1.49 | 3.7 to 4.0 | 1.43 | 4.19 | 58.3 | 3.7 | yes | 35.7 | yes |
| npc_04 | 0.90 | 1.39 | 3.7 to 4.1 | 1.43 | 4.19 | 58.1 | 7.3 | yes | 38.1 | yes |
| npc_05 | 1.02 | 1.57 | 4.7 to 5.1 | 1.43 | 4.19 | 59.6 | 4.7 | yes | 32.9 | yes |
| npc_06 | 0.93 | 1.41 | 3.1 to 3.5 | 1.43 | 4.19 | 59.0 | 4.4 | yes | 35.1 | yes |
| npc_07 | 1.00 | 1.55 | 3.8 to 4.2 | 1.43 | 4.19 | 61.1 | 4.3 | yes | 34.4 | yes |
| npc_08 | 0.93 | 1.40 | 3.5 to 4.2 | 1.43 | 4.19 | 58.4 | 7.3 | yes | 36.5 | yes |
| npc_09 | 0.88 | 1.35 | 2.6 to 6.7 | 1.43 | 4.19 | 65.1 | 8.7 | yes | 40.0 | yes |
| npc_10 | 0.99 | 1.48 | 2.9 to 3.2 | 1.43 | 4.19 | 62.1 | 6.7 | yes | 36.9 | yes |
| npc_11 | 1.01 | 1.57 | 3.5 to 3.8 | 1.43 | 4.19 | 61.1 | 3.5 | yes | 32.4 | yes |
| npc_12 | 0.90 | 1.37 | 3.0 to 3.3 | 1.43 | 4.19 | 57.9 | 6.9 | yes | 36.1 | yes |
| npc_13 | 0.91 | 1.45 | 2.7 to 3.6 | 1.43 | 4.19 | 57.8 | 5.1 | yes | 35.4 | yes |
| npc_14 | 0.87 | 1.31 | 3.3 to 4.4 | 1.43 | 4.19 | 57.5 | 9.9 | yes | 37.8 | yes |
| npc_15 | 0.96 | 1.48 | 3.1 to 3.5 | 1.43 | 4.19 | 58.7 | 5.7 | yes | 35.6 | yes |
| npc_16 | 1.02 | 1.53 | 3.3 to 3.6 | 1.43 | 4.19 | 59.7 | 3.3 | yes | 32.3 | yes |
| npc_17 | 0.88 | 1.33 | 2.3 to 3.3 | 1.43 | 4.19 | 57.1 | 8.2 | yes | 37.1 | yes |
| npc_18 | 0.85 | 1.43 | 2.3 to 4.8 | 1.43 | 4.19 | 50.9 | 4.6 | yes | 31.7 | yes |
| npc_19 | 0.93 | 1.49 | 3.4 to 3.8 | 1.43 | 4.19 | 61.3 | 3.4 | yes | 34.8 | yes |
| npc_20 | 0.93 | 1.46 | 3.2 to 3.5 | 1.43 | 4.19 | 58.3 | 5.0 | yes | 34.9 | yes |
| npc_21 | 0.95 | 1.52 | 4.6 to 4.9 | 1.43 | 4.19 | 58.3 | 4.6 | yes | 34.4 | yes |
| npc_22 | 0.90 | 1.38 | 2.6 to 3.7 | 1.43 | 4.19 | 59.9 | 6.4 | yes | 37.5 | yes |
| npc_23 | 0.99 | 1.51 | 3.5 to 3.8 | 1.43 | 4.19 | 59.9 | 3.5 | yes | 32.7 | yes |
| npc_24 | 0.96 | 1.44 | 2.9 to 3.3 | 1.43 | 4.19 | 58.9 | 5.1 | yes | 35.3 | yes |
| npc_25 | 0.93 | 1.41 | 2.6 to 2.9 | 1.43 | 4.19 | 61.0 | 8.1 | yes | 38.2 | yes |
| npc_26 | 0.95 | 1.50 | 5.0 to 5.3 | 1.43 | 4.19 | 61.1 | 5.8 | yes | 35.5 | yes |
| npc_27 | 0.93 | 1.47 | 3.1 to 3.4 | 1.43 | 4.19 | 60.7 | 4.2 | yes | 36.4 | yes |
| npc_28 | 0.92 | 1.40 | 3.0 to 3.8 | 1.43 | 4.19 | 58.1 | 5.3 | yes | 35.7 | yes |
| npc_29 | 1.02 | 1.66 | 3.4 to 3.7 | 1.43 | 4.19 | 59.1 | 3.4 | yes | 31.9 | yes |
| npc_30 | 0.87 | 1.37 | 2.8 to 3.1 | 1.43 | 4.19 | 58.1 | 7.1 | yes | 37.7 | yes |
| npc_31 | 0.96 | 1.55 | 4.2 to 4.6 | 1.43 | 4.19 | 52.9 | 4.2 | yes | 31.1 | yes |
| npc_32 | 1.04 | 1.57 | 4.9 to 5.9 | 1.43 | 4.19 | 60.0 | 4.9 | yes | 31.0 | yes |
| npc_33 | 0.94 | 1.47 | 3.9 to 4.3 | 1.43 | 4.19 | 58.2 | 5.2 | yes | 34.9 | yes |
| npc_34 | 0.90 | 1.43 | 3.8 to 4.2 | 1.43 | 4.19 | 57.2 | 5.4 | yes | 36.2 | yes |
| npc_35 | 0.92 | 1.44 | 3.5 to 3.8 | 1.43 | 4.19 | 60.4 | 5.7 | yes | 36.2 | yes |
| npc_36 | 0.94 | 1.44 | 2.3 to 2.9 | 1.43 | 4.19 | 59.6 | 5.8 | yes | 34.6 | yes |
| npc_37 | 1.04 | 1.55 | 3.4 to 3.8 | 1.43 | 4.19 | 59.6 | 3.4 | yes | 30.8 | yes |
| npc_38 | 0.98 | 1.50 | 4.2 to 4.5 | 1.43 | 4.19 | 58.0 | 4.2 | yes | 35.5 | yes |
| npc_39 | 0.93 | 1.42 | 3.4 to 3.7 | 1.43 | 4.19 | 58.5 | 5.3 | yes | 36.0 | yes |
| npc_40 | 1.08 | 1.64 | 4.2 to 4.7 | 1.43 | 4.19 | 61.5 | 4.2 | yes | 31.5 | yes |
| npc_41 | 0.99 | 1.49 | 3.1 to 3.4 | 1.43 | 4.19 | 58.8 | 3.1 | yes | 31.9 | yes |
| npc_42 | 0.95 | 1.40 | 2.8 to 3.1 | 1.43 | 4.19 | 62.1 | 2.8 | yes | 33.7 | yes |
| npc_43 | 0.96 | 1.50 | 2.8 to 3.3 | 1.43 | 4.19 | 60.3 | 5.4 | yes | 35.8 | yes |
| npc_44 | 0.99 | 1.55 | 4.6 to 5.4 | 1.43 | 4.19 | 59.8 | 4.6 | yes | 34.5 | yes |
| npc_45 | 0.92 | 1.39 | 3.7 to 4.0 | 1.43 | 4.19 | 57.0 | 3.7 | yes | 35.1 | yes |
| npc_46 | 1.00 | 1.53 | 3.6 to 4.3 | 1.43 | 4.19 | 61.6 | 3.6 | yes | 34.5 | yes |
| npc_47 | 0.96 | 1.50 | 4.1 to 4.5 | 1.43 | 4.19 | 58.6 | 4.1 | yes | 33.4 | yes |
| npc_48 | 0.89 | 1.35 | 3.0 to 3.5 | 1.43 | 4.19 | 58.0 | 5.3 | yes | 35.8 | yes |
| npc_49 | 0.96 | 1.45 | 3.0 to 4.4 | 1.43 | 4.19 | 58.8 | 3.1 | yes | 34.3 | yes |
| npc_50 | 0.99 | 1.60 | 3.2 to 3.8 | 1.43 | 4.19 | 58.7 | 3.2 | yes | 32.5 | yes |
| npc_51 | 0.95 | 1.43 | 2.7 to 3.3 | 1.43 | 4.19 | 58.1 | 2.7 | yes | 32.5 | yes |
| player | 0.98 | 1.57 | 1.2 to 1.5 | 1.43 | 4.19 | 55.1 | 3.0 | yes | 33.5 | yes |

The run is a script kept outside the lab for now; it is to become the NPCs' own civilian test, with bars, at his word.
