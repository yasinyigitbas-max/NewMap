---
name: coronado-super-builder
description: The one skill to read before building, checking, fixing or reporting on ANY part of Coronado's city kit (blocks, streets, props, land, shop rooms). Combines the four zone sessions' lessons (residential, gritty, industrial, strip - 18-19 Nov 2026) with the 19 Nov rescue session and Yasin's audit lists. Hand placement only, no generators; a fix changes the one thing Yasin pointed at; honest reports that say what a check cannot see; the outdoor audit (sunk and floating ground, tyre marks only where they belong, overlapping or obstructive props moved to a free and more logical place) and the indoor audit (chairs facing right, wall items, full floors, nothing in the air, props that fit the store, everything reachable on foot, windows and doors). Use for "build / grow / fix / check / audit the X", "why is this sunk", "this prop is wrong", "this room looks wrong", and before telling Yasin anything is done.
---

# Coronado super builder (19 Nov 2026)

Read first, every session: `map_dc/coronado/city_kit/JOB_BOARD.md`, `map_dc/coronado/city_kit/YASIN_MESSAGES.md`.
Tool details stay in `.claude/skills/coronado-city-kit/SKILL.md` (pieces, lock, validator, bake) and
`.claude/skills/coronado-city-interiors/SKILL.md` (room_lib, the indoor checker). This skill sits on top of both and
replaces the four `coronado-zone-growth` skills of the zone branches. Details it points to:
- `references/corrections.md` - every correction Yasin made in the four zones, in his words, with the rule it became.
- `references/ground-and-land.md` - how block ground must meet the land, the streets and its neighbours; the land tools.
- `references/facts-and-traps.md` - measured street and kit facts, the PC, working beside other sessions.

## Why this skill exists
Four times the pilots were perfect and the city broke when sessions switched to generators (Yasin, 19 Nov: "each time
the pilots are perfect, each time everything breaks as soon as they come out with generators"). On 18 Nov the
residential zone was rebuilt whole at least five times in one evening; each "fix this one thing" re-ran a recipe over
65 blocks. Every session reported "validator 0, sink 0" while 188,000 m2 of block ground lay under the land, because no
check compared a block with the land. Yasin found it by eye. Do not repeat any part of that.

**The pilots were NOT hand-made either** (Yasin, 19 Nov: "pilot and handmade areas were actually made by generators
too"; checked the same day). Every sample piece is a script in `tools/city/pilot/pieces/` that calls shared libraries
with rules, loops and randomness (`block_lib`, `res_block`, `apt_lib`, `civ_lib`, `ind_lib`, `strip_lib`, `grt_lib`,
`wf_lib`, `road_lib`, `wear_lib`): 36-118 loops and 5-37 random calls per sample. The pilot's downtown blocks list
their buildings and some props by hand with reasons; its house rows `r_n` / `r_s` are one call into a lot builder; and
the "life" overlays `d_pilot` / `d_cc` (`life_lib.gd`) are generators that raised the pilot and the city centre to
about 1,500 props by rule on 17 Nov. All of those scripts and libraries are still in the repo. So nothing here was ever
placed purely by hand. What made the samples good was not "no code": it was ONE script per piece, each piece looked
at and approved on its own, and never re-run after approval. What broke the growth was one recipe run over a whole zone
and re-run for every fix. Never tell Yasin a piece is "hand-made" without having opened its script.

## The five laws
1. **Hand placement. No generators.** A generator is any code that DECIDES what goes where for more than one piece: a
   recipe, a variant, a seed, a rule like "a bench every 20 m", a loop that fills an area. Hand placement is one piece
   at a time, every prop its own line with its own position, facing and reason, looked at in a picture before the next.
   The libraries `*_grow_lib.gd`, `rv_lib.gd`, `room_gen*.gd`, `res_grow.py` are generators: do not run them, do not
   extend them, do not write a new one. Their output stays as plain piece files. The sample pieces' own scripts and
   libraries (above) are rule-based too: they are approved and locked as they stand, and are never re-run either.
   NOT a generator: a tool that only measures, or that changes heights to follow a surface without moving anything
   sideways or deciding anything (`lower_land_to_pieces.py`), or that re-packs a file and proves nothing moved
   (`split_props.gd`). Say which kind a tool is before you run it.
2. **One thing pointed at = one thing changed.** When Yasin points at a prop, change that prop in that piece file.
   Never rebuild the piece from its script, never touch a second piece. Prove it with `tools/city/pilot/diff_piece.gd`
   (old file against new: only that item moved). One piece per commit.
3. **Locked means locked.** A locked piece or room changes only with Yasin's word for THAT piece, given in the chat.
   `--by=Yasin` typed by a session is not his word. The lock test only proves the file equals what was locked.
4. **Honest reports.** A zero from a check that cannot see the fault is a false report. With every number say what the
   check measures and what it does not, what you did not open, what is not done (see "What each check can see").
5. **Ask before acting.** "i didnt tell you to do anything yet". A complaint, a question or "keep this in mind" is not
   a go-ahead. Answer the question first. Try a change on ONE block on a copy, show before and after, then wait.

## Building a new piece by hand
1. Read the site: the land under it (`zoning/terrain_grid.npz`), the streets around it AS BUILT (property line, kerb,
   aprons, alley mouths - `zoning/legs_measured.json`, `references/facts-and-traps.md`), the neighbours' edges.
2. Decide as city planner, architect and exterior designer: who comes here, from where, when; write the reason in the
   script header. A narrow lot with no driveway is not a shop.
3. Ground first, and check it against the land and every neighbour BEFORE any prop (`references/ground-and-land.md`).
4. Buildings on level pads at their street-front height; by their real mesh outline, not the stats footprint.
5. Props one at a time, each with its reason in a comment. Measure a prop's real size from its manifest first.
6. Shop rooms in the same piece of work as their building ("do out and indoors together").
7. Run the audits below yourself. Look at every picture before sending it; say which you did not open.
8. Show Yasin. Lock only on his word. Commit and push after every step.

## Fixing what Yasin points at
- Find the item in the saved piece (`diff_piece.gd` prints every batch's instances with positions).
- Change that one instance: move, turn or remove it. The pattern to copy is `tools/city/pilot/split_props.gd`: load the
  `.scn`, change, check that everything else is identical, refuse to save otherwise.
  A ready one-prop patch tool had NOT been written by 19 Nov: write it first, prove it on a draft piece.
- When moving a prop, pick the new place as a person would (see "a free and more logical place" below), then run the
  audit on that piece only.
- If the fault is a CLASS (every bin, every pole), do not fix the class in one sweep. Add the check that finds it,
  show Yasin the list, fix piece by piece on his word.

## What each check can see (say this with every result)
| Check | Sees | Does NOT see |
|---|---|---|
| `validate.gd` | prop overlaps, prop inside a building, door space, prop in a lane or on a street's asphalt | heights, land, yards, whether a prop makes sense |
| `check_life.gd` | pole on asphalt, item on a narrow path, wall item over a door / window, fence end leading nowhere | everything else; with `--only` the neighbours' fences are not loaded |
| `audit_trees.gd` | trees in hard ground | - |
| `sink_check.gd` | props against their own ground in STREET pieces (`j_`, `s_`) only | every block; the land |
| `tools/city/audit/ground_check.py` | piece ground under the land, floating edges beside empty land, jumps between pieces | buildings and props against their own ground; NOT in `checks.sh`. Its "hanging" counts every yard that stands over the land, also the ones with a retaining wall under them: look before calling it a fault (19 Nov: 178 m2 counted, a real gap under 24-41 m of wall, closed by the overlay piece `x_wall_feet`) |
| `check_rooms.gd` | the indoor kinds listed under "Indoor audit" | whether the shop has what that kind of shop needs; faults of newer kinds in LOCKED rooms print as NOTE and are not counted |
| lock test | the file equals what was locked | whether what was locked is what Yasin saw |
Nothing checks, as of 19 Nov: wear marks on the wrong surface in saved pieces, play equipment on asphalt, props and
buildings against their own ground inside a block, whether a prop fits its place. Those are by eye until a check is
written. When Yasin finds a class of fault by eye: add it to the checker, prove it on the faulty case, run it everywhere.

## Outdoor audit (Yasin's list, 19 Nov)
Go piece by piece. Top view with the land loaded AND low shots at eye height (1.6-1.8 m): top views hide seams, street
views hide buried yards.

**Ground**
- Sunk: no land over a piece's ground. Floating: no block edge standing over the land beside it. Run `ground_check.py`
  on a fresh ground dump after ANY new or changed piece (`references/ground-and-land.md`).
- Seams: where two pieces meet, the heights match (aim under 2 cm; a kerb is 15 cm on purpose).
- A building on a slope stands on a level pad at its front's height; steps, doors and garages meet the ground.
- A fence or wall panel on a slope stands at the lowest ground along its length.

**Wear marks (tyre lines, oil, cracks)**
- Tyre marks belong on asphalt: at stop bars, traffic lights and crosswalks (braking), in front of garages and at
  driveway mouths (turning in), on gravel yards where vehicles work. NEVER on grass, mulch, lawns or in back yards.
- Oil where cars park. Cracks, sealant and patches only on paving. Nothing hanging over a block edge.
- A mark needs its cause next to it: a braking mark with no stop line, or a tyre arc leading into a wall, goes.
- Check each mark's four corners and centre against the surface under it (the strip's `wear_on_paving()` shows how);
  remove the ones off their surface in that piece only.

**Props: overlapping, obstructive, illogical**
- No two props in the same space; nothing inside a building; nothing through a fence.
- Nothing in front of a door, a garage door, a rollup, a walk-up window, stairs, a gate or a lane mouth. The validator's
  door space is not enough to READ as clear: look at it.
- Nothing on a pedestrian walk, a path, a crossing, a parking stall, a driveway or a truck lane.
- Wall items (meters, mailboxes, lights, signs, vines, dishes) never over a window or door; a window AC sits IN a window.
- Surface rules: slides, swings and play items on bark, sand or rubber with a level pad, never on asphalt or paving;
  utility poles in the rear easement or on gravel, never on asphalt, never in front of a garage; trees only in wells
  or grass, not within 0.9 m of a fence; picnic tables and benches on a pad or lawn, not in a traffic area; hydrants
  and hose reels within 2 m of a building wall; bins against a wall, a fence or a counter end, never in the open.
- A bench faces a path, a green or a view; a picnic table has its own seats (no stray bench beside it).
- Fences: every back yard closed, every fence end meets a fence, a gate or a wall, a post at every joint.

**Moving a prop to a free and more logical place**
1. Ask what it is for and who uses it. The new place must serve that use (a bin where people pass and can reach it; a
   bench where there is something to look at; a meter on the service side of the wall).
2. Candidate spots: against something (wall, fence, kerb, planter), off every path and door space, on the right surface.
3. Test the spot: clear of other props (use half the DIAGONAL for things at odd angles), of doors (1.6 m), of openings
   on that wall, of stalls and lanes, 0.5 m inside the block edge.
4. If no spot serves its purpose, remove it. A prop with no reason goes ("why are those table and chairs there?").
5. Change that one item, diff the piece, look at the picture from eye height.

## Indoor audit (Yasin's list, 19 Nov)
Stand in the door as a customer, then behind the counter as staff. `check_rooms.gd` kinds in brackets.

**Seats and tables**
- Every chair faces its desk, table or counter; no seat faces a wall [face]; a waiting bench does not stare out of a
  window at arm's length [outseat]. Leg room in front of every seat [seat]. Tables with their chairs, not pushed into
  a wall with the seats trapped.

**Walls**
- Wall items do not overlap each other [wallover], a window or a door at any height [window], the ceiling [ceiling],
  and do not hide behind furniture [behind, hidden]. Every wall item has a wall behind it [offwall].
- At most 2 decorations a wall and 6 a room [deco]. Hidden frame backs on shared walls: inset 0.12 m.

**Floor**
- The floor is full enough to read as a working shop [sparse], without repeating one thing [repeat: vending 1,
  brochure racks 2, fridges 4 outside food shops] and without bins taking over [binshop].
- Shelves carry goods [bare]. Nothing stands alone in the middle that belongs against a wall [lone].
- No two things in the same space [overlap, stack]; nothing through a wall or partition [wall].

**Nothing in the air**
- Every prop stands on the floor, on furniture or hangs on a wall [floating]; every built part (bars, shelves, panels)
  is held by a floor, wall, ceiling or prop [unheld]. "whats that thing flying there?"

**Walking**
- A person can walk from the door to every item [reach]; the way never narrows under 0.8 m [squeeze]; aisles 0.9-1.0 m.
- The first 1.5 m inside the door is clear; nothing in a door's swing or passage [door, doorway]; nothing over or in
  front of a back door.
- Queue space (about 1.2 m) in front of every counter; the staff side is reachable.

**Windows and doors**
- Check every window and door of the room first, then every prop against them: nothing tall right behind glass, a
  display or seating in the shop window, the counter in view from the door.
- An open shop sits only behind real glass (`ck_grt_row2` has painted boarded windows; small `com_shallow_*` models
  have house doors the room cut does not open).

**Does it fit the shop**
- Every prop belongs to this kind of shop and this zone's character; no garden plant on an indoor floor [pot].
- The shop has what that shop needs (no check for this: by eye, from the list in `references/corrections.md`,
  "What a shop needs").
- Back of house (stock, kitchen, office) behind a partition, the staff door lined up with the back door.
- No heavy-handed motif without asking ("remove all of the cages, they arent prison cells").

## Land (what the 19 Nov session did and how)
- The land is `zoning/terrain_grid.npz` (4 m nodes); the game reads `terrain/data_citykit/height.f32z`, baked from it by
  `bake_game_terrain.py`.
- `tools/city/pilot/zoning/lower_land_to_pieces.py` (dry run by default): lowers the land only where it is not 5 cm
  under a growth piece; `--fit` brings it back up to each block's edge as far as every piece allows; `--ease-from`
  spreads the change smoothly into the empty land. Roads and approved samples do not ask and their nodes do not move.
- Always: dry run to a copy, read the numbers, take before / after pictures, then `--write`, bake, `ground_check.py`.
- It does NOT mend jumps between two blocks that meet at different heights (3,123 m in the residential zone): those
  need retaining walls or a piece fix, by hand, on Yasin's word.
- TRAP: `tools/city/run/terrain.sh` / `terrain.py` re-solve the whole island from `piece_ground.npz`, which lacks the
  growth blocks. Running them buries the growth again.

## Lessons of the second half of 19 Nov (each cost Yasin a round)
- **Land first** ("this time by considering terrain too"): before any design, read the block's land (heights, rise,
  the four streets' heights); shape the ground to it; check the ground against the land and the neighbours; only then
  buildings and props. 56 blocks are empty (143 ha): 15 flat, 23 gentle, 18 rising more than 3 m; 13 have no zone.
- **Say what a number counts, every time.** "Floating edges" was given as 186 m2, then 24 m, then 6,378 m: three
  different things (edges beside empty land over 30 cm; wall feet over the land; every edge over anything beside it).
  Yasin: "your old measurements were much smaller, what changed?" Give the definition with the number, and when a new
  number replaces an old one, say in the same breath why they differ.
- **Look before you prescribe.** The "floating" edges were walled terraces; the first fix proposed (open every block
  for a skirt) was wrong and the second (raise the land) impossible. Take the close picture first, then propose.
- **Measure along the whole thing, not at its ends.** A face under a wall "where the foot is above the land at its two
  ends" left slivers in between and missed edges with no wall ("there are still big gaps, fill them"). Walk the edge
  metre by metre.
- **A block's ground is a thin sheet.** Any edge higher than what lies beside it (land, street, a lower block) shows
  the underside unless a face stands there. `x_wall_feet` adds those faces as an overlay (`references/ground-and-land.md`).
- **Two opposite readings: ask once.** Two red lines on a picture could mean "cut the sand back to here" or "bring
  the sand out to here". One question with the consequence of each answer settled it; guessing would have undone work.
- **Other sessions are real.** One pushed to this branch and wrote files into this folder while this work ran. Never
  say "nobody else is working" without checking; `git fetch` before a push; never touch files you did not make.
- **One camera a run for before / after pairs**, and compare the two pictures pixel by pixel: a second camera in the
  same run can show popped distance tiers, and a missing layout file gives an empty picture (watch `draws=`).

## The superchecker (19 Nov, `tools/city/super/`): find, fix one item at a time, prove
- `python -I tools/city/super/sc.py check <piece>` finds (outdoors and the piece's rooms) and changes nothing;
  `fix <piece>` / `fix-room <room>` carries the fix list out on a COPY and proves it; `shots` shows as it is / fixed;
  `install <piece> --by=Yasin` only on his word. Read `sc.py`'s header and the job board entry of 19 Nov ~15:30.
- It is NOT a generator: it never runs a piece script and never picks a place. A fix with one right answer (a prop in
  the air goes down, a mark off its surface goes, a poster through a wall is drawn back) is written out; a fix that
  needs a place is left open until a person chooses it for that one item.
- The proof compares the whole of both files and must say PROOF RESULT PASS. A FAIL means the copy is thrown away.
  It has caught the fixer itself (a re-saved room lost its sign picture): trust it over your own reading of the code.
- A new class of fault Yasin finds goes into `sc_find.py` / `sc_rooms.py` as a check, proved on the faulty case, with
  what it cannot see added to CANNOT_SEE. Tune a threshold on real pictures before trusting its count.
- Its counts are findings by rule, not truth: the "sure" note of each says when a look is needed.
- Do not run two Godot processes while one imports (`--import`): import files were reset to defaults that way.
- Trees: the checker lists every builder tree of a piece to go and its well to be paved; trees come back ONLY from a
  hand-written list, `zoning/trees/<area>.json`, one line per tree with its reason, after `docs/TREE_PLAN.md`'s rule
  for that zone. `sc.py trees <area>` checks the list and builds `t_<area>`; `sc_trees.py where` reads a spot first.
  Never fill a list by a rule or a loop: that is the generator again.
- Wear marks at strength 0.4-0.55 (grime, tyre marks) hardly show from eye height in the preview: look from above
  before saying a mark is or is not there.

## Reporting to Yasin
- Short and plain. What changed, what is NOT done, what was NOT checked, what needs his word - in the same message as
  any good number.
- Answer the question asked first. "Stop" means stop, background work too. "Just tell me" means do not start.
- Pictures: say when a shot is the old state; re-shoot the exact view he sent after a fix; say when only one area's
  pieces are loaded (the roads end at the edge of what was loaded, they have not sunk).
- He is tired of false passes and of work he did not ask for. Under-claim.
