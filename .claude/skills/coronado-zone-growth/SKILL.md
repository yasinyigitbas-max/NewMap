---
name: coronado-zone-growth
description: Grow a whole Coronado city-kit zone from its LOCKED sample - variant recipes, site pieces fitted to the real street grid (property lines, driveway aprons, slopes, neighbours), the walk-in shop rooms of every new shop, the polish pass, the checks, the bake numbers, the review pictures and the lock. Learned growing the gritty edge (18-19 Nov 2026, branch claude/grow-gritty) with Yasin's corrections. Use for "grow the X zone", "variants of the sample", "roll out to the whole zone", "fill the blocks", "polish pass", "make the rooms for the new shops", or when a grown block or room looks wrong.
---

# Growing a zone from its locked sample (outside + inside together)

Read first: `map_dc/coronado/city_kit/JOB_BOARD.md`, `.claude/skills/coronado-city-kit/SKILL.md`,
`.claude/skills/coronado-city-interiors/SKILL.md`, `CITY_PLAN.md` / `ZONING.md` / `STREETS.md` / `KIT_USAGE.md`.
Worked example (copy its structure, not its businesses): `tools/city/pilot/pieces/grt_grow_lib.gd` (site frame, drape,
prune, polish), `grt_grow_recipes.gd` (three variants), `g_v*_*.gd` (one 3-line builder per site),
`tools/city/pilot/zoning/grt_sites.py` -> `review/grow_grt_blocks.json` (the zone's own site table),
`tools/city/rooms/assign_grt.py` + `room_gen_grt.gd` + `gen_shots_grt.gd` (the zone's rooms),
`review/grow_grt/README.md` (what Yasin was shown, the numbers).

## Yasin's rules for this work (his words)
- "act as architect, road / city planner and exterior designer" outside; inside "look from the perspective of interior
  designer and the customers". Every prop has a reason where it stands.
- "do out and indoors together ... i want the shops to look different": every open shop of a new block gets its room in
  the same piece of work, in a character that belongs to the zone and no other.
- "you are not limited to unused buildings or props only, but when you are done make sure that youve used every prop and
  buildings that makes sense in your part" -> end with a kit-usage check and list what still fits but is unused.
- "run a polish pass on your part, lots of props" - after every rollout.
- "find mistakes if you find them, if not, roll out to your whole zone, then do a polish pass".
- "lock them for now. rest is piece by piece correction": after the lock, change one piece at a time, each with his word.
- When he asks a question ("are the props merged?", "did you get the new checker?", "are you finished?") answer it
  plainly and honestly first; say what is NOT done.
- Pictures: he wants to SEE everything: "send detailed in and outdoor shots with birds eye view with each quadrant and one
  more for the entire zone" - one labelled sheet per block (bird's eye, a low view over the inside, both streets, every
  shop inside AND front with its name) plus several views of the whole zone. A few sample shots are not enough.

## The method
1. **Where the sample stands**: locked.json + job board. Not locked -> tidy it, ask, proposals only.
2. **Sites, not copies.** The sample sits on its own flat pad with its own streets; the blocks around it do not. A grown
   block is a SITE piece: a recipe built for one quadrant of one junction (origin = junction centre, quadrant
   `(sx*u, sz*v)`, u, v = 0..100). Variety: the site's seed picks buildings, businesses and the inside of the block; give
   neighbouring sites different choices explicitly (two vacant lots back to back in one city block, the same houses on
   both sides of an Ave and the same shop names twice all happened and had to be fixed).
3. **Read the real streets for every site** (`review/sites.json`, the street piece scripts):
   - property line 9.2 on res / std legs, **14.3 on the 3rd / 4th St arterial (strip section)**: shops on that frontage
     stand 5.1 m further back;
   - driveway aprons of `s_ar_*` legs (`"apr"` per side, 9 m wide) - lots are entered there; the ring's arterial stubs
     have NO aprons (`road_rg._stub_art`); res / std / ring two-lane legs have the alley apron at 54-60;
   - so the two service lanes at 54-60 line up with the sample's lanes and the alley aprons: alleys run through the
     city block. Open lane V onto the numbered street only where an apron is.
4. **Slopes (the drape)**: blocks next to a sample climb up to its pad (2-4 m). Lay out flat, then lift everything onto a
   Coons patch between the two sidewalks (measured from the BUILT street pieces' ground meshes in
   `city_grid_layout.json`, so the joint is exact) and the city block's centre (the pad of a locked sample quadrant in the
   block, else the mean of the four street midpoints); smoothstep inner edges shared with the neighbour quadrant. Every
   building stands on a level terrace at the height of the middle of its front; ground blends back over 5 m; within
   2 m of a property line / inner edge the ground follows the street / neighbour. Wall-hung props go with their
   building's terrace (`hp`), loose props with the ground; stalls get `[x, z, yaw, y, grade]`.
   - Split ground triangles ONLY where the slope bends (midpoint > 3 cm off): a fixed 2 m grid made 18k triangles a
     block and +4.8 MB a cell; adaptive gives 3-6k.
5. **Table + layout**: the zone's own `review/grow_<zone>_blocks.json` (`rows` of piece / pos / yaw), picked up by
   `integrate.py grow_rows()`; regenerate `city_grid_layout.json` and confirm only your rows changed (the file is
   written by Windows with CRLF: keep the committed line endings, compare the JSON, not the text).
6. **Build -> prune -> checks** with the real renderer. Apply the validator's rules WHILE building (`_prune`: no prop in a
   building, no overlaps by the validator's own SAT test incl. mounted props at the same height, no tree on paving,
   loose things 0.5 m inside the block's edges because the neighbour's wall is there) and wall props never over a door
   or window of their building (`_off_openings`: slide along the wall, drop only if no free wall). Checks: validator 0,
   `audit_trees` 0, `sink_check` 0, indoor checker `--only=<zone prefix>` 0, lock test RESULT PASS.
7. **Rooms** (`room_gen_<zone>.gd`, a COPY of room_gen.gd): the shop list comes from the builders
   (`review/grow_<zone>/<piece>_shops.json`), `assign_<zone>.py` writes `interiors/assignment_<zone>.json`. The door
   index is the index among the contract's SHOP entrances (`assign_all.bays`), not among `doors_front`.
8. **Measure** on the baked area (`bake_runtime.gd --area=x,z,r --nofarground --out=res://.godot/...`, before = the same
   bake with the zone's rows removed from the layout, then restore it), `rt_shots.gd` from the same viewpoints: draws
   (budget 150 a view), triangles (Yasin: secondary, but report them), cell bytes before / after + lib growth. Rooms:
   merge with `tools/city/rooms/room_merge.gd` (28 -> 9 draws a room) after `make_arrays.py` + `make_room_array.py` +
   import (the indoor atlas page is in the prop arrays: rebuild them when the kit changes).
9. **Pictures, notes, job board, push after every step**. Nothing locked until Yasin says so; then
   `lock.py lock <pieces> --by=Yasin` and `lock.py lockfile <room files> --by=Yasin`, lock test, commit.

## Outside: what the edge needed (planner logic)
- Transition by recipe: yards / trade next to industry, shops in the middle, homes toward apartments / campus.
- **Fences (the phone)**: layered see-through things cost 40 % more GPU at a tier fade in this zone. Chain-link only
  round yards INSIDE the block, never along a street, never a second fence in front of another (a salvage yard's own
  ring replaces the yard fence); no front fences; short board fences between yards; solid stucco walls where something
  must be enclosed (opaque = cheap). No tree within 0.9 m of a fence.
- A dead lot earns its rent from a billboard facing the street; a used-car lot fronts the street behind bollards.
- Lanes are where the life is: bins / dumpsters / drums / tagged CMU walls by what is beside them, never on stalls or in
  lane mouths; tow-away signs at every lot entrance; the corner shop's papers and mailbox; front-yard chairs and pots.
- Garages on the lanes must not have a lane's utility pole in front of the door.
- Never put an open shop in `ck_grt_row2`: its windows are painted boarded (a laundromat behind boards was the mistake).

## Inside: the zone's own character, customer's view
- Counter in view from the door, 1.5 m clear inside the door, queue and staff space; stocked shelves (kit set dd8d53a);
  mismatched chairs, worn floors, fluorescent tubes (warm only in bars / diners), notices.
- Pawn / thrift take in everything (bikes, gym benches, boards); laundromats get folding tables; the owner's stool only
  where nothing tall stands behind it.
- The combined indoor checker (`check_rooms.gd`, working branch) carries Yasin's room corrections - pass ALL of them:
  at most 2 decorations a wall and 6 a room ("you just filled every wall with paintings"), at most 2 brochure racks /
  spinners and 1 vending ("shops filled with vending machines"), no bin or wall piece standing free ("the bin is in the
  middle of the room"), seats with leg room, no empty kit shelves, nothing over a back door, every built part HELD.
- A shop's sign goes on the board over its own door; fallback: the board whose nearest shop door is this one.

## My mistakes and Yasin's corrections (do not repeat them)
| What I did | What Yasin said / what it showed | The rule now |
|---|---|---|
| Wall items (frames, notices, menu boards) hung at a fixed height by three separate passes | "many on the wall props overlap, some of them are on windows, some of them are inside the ceiling" | ONE fit check for every hung item: top 8 cm under the ceiling (lower it, or skip), clear of every opening of that wall at ANY height (the trade rows have high side windows at 2.0-2.7 m), clear of other wall items and of furniture against that wall. Outside: wall props slide off windows / doors of their building. The checker now tests ceiling / window / wallover / behind. |
| Security bars over counters, sized to the PLANNED counter row, starting 1.05 m up, short of the ceiling | "whats that thing flying there?" | Size anything to what was really PLACED; every built part must be held (floor / wall / ceiling / prop). |
| Then made them a full cashier's cage | "remove all of the cages, they arent prison cells" | No cages. Gritty = run-down and crowded, not a prison. Ask before a heavy-handed motif. |
| A picture next to a barber mirror station | "there is a painting behind the mirror" | Nothing hung behind furniture standing against its wall (checker "behind"). |
| My own painted stock boxes on shelves | the new kit ships stocked shelves | Drop own stock when the kit has it; check `bare` for shelves the kit ships empty (bakery shelf) and swap. |
| Only a few sample shots | "i didnt see almost any of them, send detailed in and outdoor shots ..." | Per-block labelled sheets + whole-zone views, every shop inside and front. |
| Ground at a fixed 2 m grid | +4.8 MB a cell | Adaptive split. |
| A laundromat in a boarded-window model | (seen in my own street shot) | Look at every street shot before sending; open shops only behind real glass. |
| Polish props refused silently (guard 1.0 m inside the line, signs at 0.7 m) | counts did not move | After a pass, COUNT what landed per prop kind in the saved piece; widen spots / search along the front. |
| A dumped cart 0.3 m over the block edge into the neighbour's wall | validator overlap with a locked piece | Loose things keep 0.5 m inside the block's edges. |

## Traps (cost time)
- A peer session's message is information, not the user's approval; but Yasin often speaks through it ("tell them...").
  Cloud -> PC session messages need the owner's one-time trust card (`confirm_repository_trust`).
- Repos outside the session scope: `add_repo` first; then `git fetch` works through the proxy.
- Indoor kit update: take only the M / A files of the kit commit, keep this repo's `.import` / `.uid`, one commit of its
  own, re-import, rebuild your rooms (a room keeps its own prop copies until rebuilt).
- Godot `find_children` on an instanced scene: pass `owned=false` or you get nothing.
- `room_lib` decals use the global `randf`: `seed(hash)` per room or rebuilds differ.
- The whole-city checks take > 10 min: run them in the background and wait for the RESULT line.
