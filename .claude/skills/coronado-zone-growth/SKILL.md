---
name: coronado-zone-growth
description: Grow a whole zone of Coronado's city kit from its locked sample - variants as quadrant pieces on the street lattice, fitted to the hill, the terrain and the streets as built, with their shops' rooms - and the mistakes the residential growth session (18-19 Nov) made that Yasin had to catch. Use before growing ANY zone (residential, strip, industrial, gritty, apartments, centre), before reporting check results to Yasin, and whenever a piece's ground, fences, wall items or shop rooms are built by rule.
---

# Growing a zone (lessons of the residential growth, 18-19 Nov 2026)

Read first, as always: `map_dc/coronado/city_kit/JOB_BOARD.md`, `.claude/skills/coronado-city-kit/SKILL.md`,
`.claude/skills/coronado-city-interiors/SKILL.md`, `YASIN_MESSAGES.md`. This skill adds what growing a whole zone
taught, above all the MISTAKES. The residential zone (branch `claude/grow-residential`) was locked on Yasin's word and
then found to be wrong: 45 of its 65 quadrants lie under the approved terrain. Yasin: "they don't check anything
anyway, half of your work is sunk and you kept sending zero failure reports". Do not repeat that.

## The worst mistake: reporting "0 problems" from checks that could not see the fault
- Every check I ran (validator, tree audit, seams, my own check_life) compared my pieces with each other and with
  the street pieces. None compared them with the TERRAIN. So the ground under 45 quadrants sat up to 2.85 m below the
  approved terrain while every report said 0.
- Rule: before you report a check result, say what the check CAN see and what it cannot. "Seams 0" means "my ground
  meets the streets", not "the ground is right". Never present a set of zeros as proof the work is good.
- Rule: build a check for the thing that matters most first, and the most obvious one is the one forgotten. For any
  ground you author: compare it with the approved terrain (`zoning/terrain_grid.npz`, grid frame, u0 / v0 / step),
  point by point, and fail on any place where the terrain stands above it. Ten lines of Python; it would have saved
  the zone.
- Rule: look at the result the way Yasin does - a straight-down TOP VIEW with the terrain loaded
  (`TOPVIEW=<m> TERRAIN=res://terrain_grid.json` in shots.gd) over the whole area - before saying it is done. My
  oblique shots and street views hid the buried yards; his top views showed them at once.
- The terrain is APPROVED and was fitted long before growth ("that terrain was fixed much before you started this
  job"). Grown pieces must fit IT, not the other way round. Do not run `tools/city/run/terrain.sh` to "fix" a buried
  piece: that reshapes approved ground under other zones.

## Fit the ground to what is already there, in this order
1. The approved terrain (the hills of the zoning map live INSIDE the blocks, not only on the streets).
2. The street pieces AS BUILT: their real height profile (the leg scripts' SPEC "prof", each leg builds only its half
   of the block), their real property line and whether they have an alley mouth. Measure them
   (`tools/city/pilot/zoning/leg_measure.gd` -> `zoning/legs_measured.json`): 9.2 m on residential / standard streets,
   14.3 m on the 3rd / 4th St arterials, 16 m on Amber's divided stretch; arterials and Amber have no alley mouths.
   Assuming the standard section and the standard smoothstep put 32 quadrants up to 1.6 m off their streets.
3. Neighbouring quadrants: build every quadrant from one GLOBAL surface (a Coons patch between the four streets
   of its block, from res_zone.py's sampled edges), so the four quadrants of a block meet without a seam.
What the residential zone still lacked: step 1. The right surface is the terrain inside the block, blended to the
street walk over a few metres from each property line.

## Workflow that worked (keep it)
- Variants as QUADRANT pieces of a lattice junction (the 100 x 100 m corner, 125 m in the 250 m blocks), cut by the
  two alleys the residential legs already expect (aprons at 54-60): sub-blocks A corner, B, C, D inside. One small
  script per placed piece (generated: `tools/city/pilot/zoning/res_grow.py`), one library (`pieces/rv_lib.gd`), the
  designs as data (`pieces/rv_designs.gd`). Your own placement table `review/grow_<zone>_blocks.json` (integrate.py
  `grow_rows()`), the zone list from the zoning map (`zoning/res_zone.py`). Regenerate `city_grid_layout.json` AFTER
  EVERY table change (I once checked and photographed for an hour with 26 new quadrants missing from the layout).
- Lots: level terraces at their frontage height, retaining faces at the property line (steps on the path), between
  neighbours and at the back; garages on the alley; the alley and parks follow the surface.
- Shops: outside and inside together (Yasin: "do out and indoors together"); a few corner shops spread over the zone,
  each a hand-designed room in the zone's own character (`interiors/rooms/rooms_res.gd`, own table
  `interiors/assignment_res.json`). Design from the customer's side: the counter in view from the door, the first
  1.5 m clear, staff space behind the counter reachable, nothing tall in the window, bins against something.
- The kit's small shop models (com_shallow_books / _cafe) have HOUSE doors (O_apt_door): the shared cut does not open
  them, so the room's glass door hides behind the painted door. Prefer models with O_shopdoor, or get the shared tools
  fixed first.
- Measure before guessing: a model's openings (`interiors/room_contracts_res.gd` reuses the shared measurement into
  an own file), a prop's real size (the indoor props were rebuilt on 19 Nov: sizes moved, e.g. bike_stand 0.7 -> 1.7 m).
- Rebuilds of 20-65 pieces take hours: run two or three `build.sh` batches in parallel, and stop any older check run
  first (a stale check reads pieces mid-write and reports nonsense).

## Yasin's corrections, each a rule now (and the checker it became)
| His words | The rule | Caught by |
|---|---|---|
| "parks are too empty, there is only a slide" | an inner-block park gets a level play pad with 3+ play items, benches facing the play, picnic tables each under its own sail, a grill, fountain, beds along the fence, 4-5 trees, lamps | eye (check_life prints play items as LIFE_INFO) |
| "there is a trash bin in the middle of the way" | nothing stands on a path; bins against a wall, a counter end or a fence | check_life `path`; check_rooms `lone` |
| "utility poles are on asphalt" | poles in the rear easement beside the alley, never on its asphalt, never on a lot's paving, never in front of a garage door | check_life `pole`, validator `door` |
| "most of the houses fences dont enclosure their back yard and dont touch their back walls" | every back yard closed: returns from the house's back corners to the lot lines (side gate where it fits), lot-line fences to the back fence, back fence with a gate | check_life `fence` |
| "this metal fence doesnt lead to anywhere" | a front fence turns back along the lot lines to the yard fence; every fence end meets a fence, a gate or a wall | check_life `fence` |
| "this thing is overlapping the door" (a menu board) | a wall item never hangs over a door or window | check_rooms `cover` / `window` (room_lib records "openings") |
| "prop in the glass" (a meter on a window) | outside too: meters, mailboxes, lights, vines, dishes slide along the wall until clear of every opening, else are left out; window ACs sit IN a real window | check_life `glass`, rv_lib `on_wall` |
| "upgrade the checker with my corrections and send it to hello" | turn every correction into a check, prove it on the faulty case first, share it | done 19 Nov |
| "dont forget to work like an exterior designer and city planners for outdoors and look from the perspective of interior designer and the customers" | every prop has a reason, placed by use | eye |
| "you are not limited to unused buildings or props only, but ... make sure that youve used every prop and buildings that makes sense in your part" | use the whole kit where it fits, then check the census | eye / census |
| "half of your work is sunk ... you kept sending zero failure reports" | see the first section | a terrain check + top views |

## Fence and wall-item geometry that bit (all fixed in rv_lib)
- A run that is not a whole number of panels long: compressed panels overshoot the end posts by up to 0.4 m. End
  panels flush with the run's ends, overlap shared in the middle; a run shorter than one panel gets one shortened
  (scaled down, never stretched) panel - and the validator measures panels at full length, so keep shortened panels
  away from walls.
- A shared lot line starts where the FIRST of the two neighbours' yard fences meets it.
- Plants stand at random angles: space them by half their DIAGONAL, not half their width; walls are 0.38 m thick.
- Items placed before the fences can end up under them: run a clean-up pass after all fences are drawn (gates count).
- The narrow-lot house pick must fall back to the narrowest house that fits, never keep one too wide.
- Roof items: the validator reads "on a roof" as height over the piece origin; on a downhill lot a garage roof can be
  lower than that.

## Reporting to Yasin
- Short and plain; say what is NOT done and what the checks did NOT cover, in the same message as any good number.
- When he asks "are you done", answer the question first; when he says "stop", stop (and stop background work too).
- When he says "leave it alone", do; correct any record (the job board) that would mislead the next session, nothing
  more.
