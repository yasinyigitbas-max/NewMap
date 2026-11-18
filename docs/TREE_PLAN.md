# Trees by area: the plan (19 Nov 2026, PROPOSAL, waiting for Yasin; nothing changed in the map)

Yasin: "according to our zones, which areas having trees make sense and which dont?" and "we can turn off the trees
entirely from the current builders and place your hand placed trees instead". Trees are the most expensive thing the
phone draws (`docs/DRAW_CENSUS.md`: 11 ms of 41 in the apartments, 15 of 37 in the civic band, at 1.5 x full screen).

## 1. Where the trees are today
Counted in the merged city (526 pieces in the layout) with `tools/city/audit/tree_census.gd`:
**2,411 trees, 2,021 palms, 3,101 other plants** (hedge panels 858, agaves 938, bird of paradise 467, pots 539, ...).

| Where | Pieces | Trees | Palms | Other plants | Locked? |
|---|---|---|---|---|---|
| Residential streets (road kit) | 142 legs | 907 | 451 | 0 | yes |
| Ring boulevard | 96 legs | 219 | 946 | 574 | yes |
| Amber spine and the arterials | 40 legs | 145 | 194 | 20 | yes |
| Bridge approach and ramp | 11 | 0 | 37 | 0 | yes |
| The eight samples' own street legs | 32 legs | 164 | 137 | 2 | yes |
| The eight samples' blocks (and stadium, overlays) | 37 | 187 | 81 | 755 | yes |
| Residential growth (yards) | 43 quadrants | 662 | 151 | 1,447 | no |
| Gritty growth | 12 blocks | 73 | 0 | 182 | no |
| Industrial growth | 10 blocks | 37 | 0 | 36 | no |
| Strip growth | 3 blocks | 17 | 24 | 85 | no |

THE POINT: 72 % of all trees and palms (3,200 of 4,432) are STREET trees inside locked road pieces. The four zone
builders hold 22 % (964). Turning the trees off in the builders alone would leave three quarters standing.

By sample (200 m x 200 m, its four blocks + its street legs), against what the phone measured there:

| Sample | Trees | Palms | Other plants | Plants' cost on the phone (ms at 1.5 x) |
|---|---|---|---|---|
| Civic and parks (with the stadium) | 126 | 28 | 74 | 15.2 |
| Apartments | 87 | 30 | 235 | 10.9 |
| High street (pilot) | 43 | 24 | 140 | 5.7 |
| Gritty edge | 23 | 13 | 82 | 3.4 |
| City centre | 22 | 26 | 50 | 0.8 |
| Waterfront | 20 | 48 | 91 | 0.6 |
| Industrial | 14 | 0 | 0 | about 0 |
| Commercial strip | 16 | 49 | 85 | not measured |

A READING, NOT A MEASUREMENT: the cost follows the broadleaf trees (jacaranda, coral, magnolia, ficus: big cut-out
crowns), not the palms. The waterfront has 48 palms and pays 0.6 ms; the centre has 26 palms and 22 trees and pays 0.8.
The apartments' 235 hedge panels and plants may be part of their 10.9. To be measured before any tree is placed: the
census with palms, broadleaf trees, and hedges / small plants hidden each on its own (three new states).

## 2. Which areas should have trees (as a city planner would decide)

| Area | Trees? | The rule | Now | Target |
|---|---|---|---|---|
| Residential streets | yes | street trees in the parkway, runs of one species per block face, 20-30 m apart, gaps where a driveway or a lamp is; pines and palms on the hill streets (light crowns), broadleaf on the flat | 1,358 | about 850 |
| Residential yards | yes | one yard tree for every two or three houses, in back yards and at lot corners, never against a fence or a wall | 813 | about 400 |
| Civic and parks | yes, grouped | a park is where trees are the point: clumps of 3-5 at the edges and round the seating, open lawn in the middle; street trees thinner beside a park (the park does the job) | 154 | about 100 |
| Apartments | some | one tree per court, placed for the seating; a street row; hedges only where they close a yard | 117 | about 60 |
| High street (pilot), Amber spine, arterials | yes | trees in wells on the shop side, palms alternating on Amber: the avenue's signature | 406 | about 360 |
| Ring boulevard | palms | the palm boulevard round the island; broadleaf only at the park edges | 1,165 | about 1,000, palms |
| City centre | few | wells on the wide pavements only, none in courts or alleys | 48 | about 40 |
| Commercial strip | few | the palm parkway; one tree per car-park island end | 106 | about 80 |
| Waterfront, bridge approach | palms only | spaced palms on the promenade and the median | 105 | about 95 |
| Gritty edge | almost none | one scrappy tree in a vacant lot, weeds at fences; a street here lost its trees long ago | 109 | about 30 |
| Industrial | none | only the screen of eucalyptus where a yard faces homes | 51 | about 30 |
| Stadium | edges | the car park's edges, none among the stalls | (in civic) | |
| TOTAL trees and palms | | | 4,432 | about 3,050 |

Broadleaf trees go from 2,411 to roughly 1,400; palms from 2,021 to about 1,650. The targets are a first estimate by the PC
session: the phone corrects them.

One rule on top, because cost is what is IN VIEW, not what is in the city: from any point of any street, at most
8 broadleaf crowns and 12 trees of any kind within 60 m (the near tier, where a tree costs most). Starting figures; the
check is easy once the trees are a list of positions.

## 3. How: the builders' trees off, hand-placed trees instead

1. **Off, in ONE place, without touching a piece.** The runtime bake gets a switch that leaves out every `tree_*` and
   `palm_*` batch of every piece. The pieces and their locks stay as they are (the lock test keeps passing); the
   baked city simply has no builder trees. This reaches all 4,432, the locked streets included. Hedges, agaves, pots and
   wall plants stay: they belong to yards and fences (their cost is one of the three things to measure first).
2. **The hand-placed layer.** New pieces `t_<area>` in world coordinates (like the wire pieces `w_*`), one per area,
   each written once by its own script: every tree a line with its place, species, size and the reason it is there.
   Built, checked, shown to Yasin, locked. A fix to one area's trees cannot move a tree anywhere else.
3. **Where a tree may stand:** in a well or on grass / mulch (the tree audit must say 0 in hard ground), so street trees
   reuse the wells the streets already have. The hand layer chooses WHICH wells keep a tree.
4. **Checks before showing:** `audit_trees.gd` (ground under the trunk), the validator (doors, building walls, 0.9 m off
   fences, 2.5 m clear at stair feet), the in-view cap of section 2, and the census on the phone before / after
   (`hide_plants`): the goal is the budget's 4 ms (`docs/BUDGET.md`), from 11-15.
5. **The four zone builders** get the same switch for their future builds, so nobody grows new builder trees. Not now:
   Yasin's order is build all, lock all, then check one by one.

## 4. Open questions for Yasin
1. **Empty wells.** A well with no tree reads as "a tree is missing". Options: leave bare soil (looks neglected: right
   for the gritty edge, wrong for the centre); a low plant in it; or an iron grate over it. A cover needs a small kit
   part or a ground patch.
2. **When.** Positions do not depend on the tree models, so the layer can be placed before the new trees arrive and the
   species swapped in. Or wait for the models and do both once.
3. **Order of areas.** Suggested: apartments and civic first (they pay the most), then the residential streets (the
   largest count), then the rest.
4. **Hedges and small plants** (3,101): keep with the builders, or thin them too once they are measured.
