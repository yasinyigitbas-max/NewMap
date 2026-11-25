# Clips the library lacks (for Yasin)

What is missing for step 4 (standing, walking, running, starts, stops, turns), with the height / speed / foot, and what the
lab does meanwhile. Speeds are for a normal adult (the clips run 14 % slower on player_v3's legs).

## Starts
| Wanted | Why | Meanwhile |
|---|---|---|
| Walk start, **left foot first** | only a right-foot start exists ("Start Walking" = "L_Start_Walking", same take) | mirror of the right one |
| Walk start turning **90° left / right** and **180° left / right** (4 clips) | study 2.5: a turn-start steps or spins with a weight shift | a straight start spun on the stance foot (up to 120°), a walking 180 above that |
| Run start (idle to run at ~4.5 m/s), **left and right foot first** | only "Idle To Sprint" (one foot) | its mirror |
| Jog start (idle to ~2.7 m/s) | half-stick starts use the walk start | walk start, then the loop speeds up |

## Stops
| Wanted | Why | Meanwhile |
|---|---|---|
| Walk stop from ~1.4 m/s in **1-2 steps**, **left foot planted** and **right foot planted** | "Stop Walking" takes 2+ slow steps (1.6 s); study 2.4 says 1-2 steps | the slow one and its mirror, handed to idle when the second foot is down |
| Run stop from ~4.5 m/s, **left / right planted**, ending **facing forward** | "Run To Stop" ends turned 37° | it and its mirror (the body ends turned) |
| Jog stop (~2.7 m/s) | in between | run stop |

## Turns
| Wanted | Why | Meanwhile |
|---|---|---|
| Run pivot 180°, **both directions x both planting feet** (4) | one take ("Running Turn 180"), turns 139° | it and its mirror, warped to 180° |
| Walk 180° from **standing** (left / right) | "Walking Turn 180" starts mid-step | it, entered at its first strike |
| Run curve loops (lean into a 5 m radius) | turning runs | straight loops + procedural lean (the "Running Left/Right Turn" loops exist, not used yet) |

## Loops and idle
| Wanted | Why | Meanwhile |
|---|---|---|
| Relaxed walk ~1.3 m/s (one stride, left strike at 0) | the walk is brisk (1.8 m/s on Mixamo) | the brisk walk slowed by rate and stride |
| Idle with a weight shift every 4-8 s (study 4.5) and its two re-plant steps | the idles stand still | "Idle" only |

## Later steps (not needed for step 4)
Step vault, speed vault, bonnet slide, step-over, climb-over a fence, mantles from standing at 0.5 / 1.0 / 1.5 m, stairs at
30-37°, running down stairs, jump and land per height: as the brief and study 3.1-3.3 list them. Will be written out at
steps 5 and 6.
