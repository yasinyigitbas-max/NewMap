---
name: coronado-zone-growth
description: Grow a zone of Coronado's city kit round a locked sample - new block pieces AND their shop rooms together, as the commercial strip session did (18-19 Nov, six m_gr_* blocks, 26 g_strip_* rooms, locked). The method, the ground solve that meets the neighbours flush, the checkers to run, how to measure and report, and above all the mistakes made and Yasin's corrections, so they are not made again. Use for "grow the X zone", "fill the area round the sample", "make variants of the blocks", a new block next to locked pieces, a zone polish pass, or when Yasin points at a fault in a grown block (floor seam, cracks on grass, prop in the way, room clutter).
---

# Growing a zone (outdoors + indoors), lessons of the commercial strip (claude/grow-strip, 18-19 Nov)

Read first, as always: `map_dc/coronado/city_kit/JOB_BOARD.md`, `.claude/skills/coronado-city-kit/SKILL.md`,
`.claude/skills/coronado-city-interiors/SKILL.md`. This skill adds what a ZONE session learned; the worked example is
`map_dc/coronado/city_kit/review/grow_strip/README.md` and the code `tools/city/pilot/pieces/m_gr_*.gd` +
`strip_grow_lib.gd`, `tools/city/pilot/zoning/strip_grow_ground.py`, `tools/city/rooms/room_gen_strip.gd`.

## The job, as Yasin gives it
- Variants of the zone's blocks, each its own builder script, then fill a connected stretch; out- AND indoors together
  ("are you building indoors and outdoors at once?" - yes, every new shop gets its room in the same step).
- Think as **city planner + architect + exterior designer outdoors, interior designer + customer indoors**. Every
  block needs a reason to be what it is THERE (who comes, from where, when): write it in the script header ("Why this
  use"). A narrow lot with no driveway is not a shop: it became boat/RV storage. Across from a hospital: urgent care,
  visitor parking, coffee + flowers, a motel for families.
- "You are not limited to unused buildings or props, but when you are done make sure you've used every prop and
  building that makes sense in your part." Check it with a count (KIT_USAGE census vs your pieces) and say what is
  left unused and why it does not fit.
- Commit and push after every step; nothing locked until Yasin says ("lock your parts if you are done with them" ->
  `lock.py lock <pieces> --by=Yasin`, rooms with `lock.py lockfile <room.scn ...> --by=Yasin`, then the lock test).
- When he says "don't do X" (the 150 older rooms) or "just tell me", do not start it. Answer the question asked first.

## Ground: the floor must meet every neighbour flush (the costliest lesson)
Yasin: "floor is broken, grass underneath shows", "surface isnt even anymore", "how is this seam fixed?"
- A grown block's ground is solved (harmonic) over the empty rectangle from `zoning/piece_ground.npz` (1 m raster of
  every piece's ground). Sampling it CLAMPED inside the block leaves the edge row 1-12 cm off the street's walk ->
  a visible line where the terrain shows through. Fix in `strip_grow_ground.py`: every edge sample takes the
  neighbour's measured height just outside (the raster row has holes: search the row right outside, along +-2 m, never
  1-2 m further out - that is the road / kerb return, 0.15 lower), ease the correction in over 3 m (no lip, no 10 %
  ramp), and near block corners accept only < 0.14 m differences (a kerb drop is exactly 0.15).
- Two NEW blocks that touch must share one solved line: mark the closed rectangle (the raster row ON the line) as
  free, and sample exactly when all four cells round the point are solved or measured. Before this the E/F seam was
  25 cm apart. Check every shared seam with a script (both blocks' heights along the line, worst step) - aim < 2 cm.
- A 0.3 m skirt hanging under every block edge (`strip_grow_lib.skirt()`), in the edge's own material: any residual
  gap shows a face, never the grass below.
- Floor cells must not be merged into long runs (`K.painted_rect(..., merge=false)`): a merged run's long edge against
  two short cells is a T-joint and leaves hairline cracks on a slope. Costs triangles (zone ground 31k -> 68k), say it.
- Level pads per building blend into each other: two buildings with a gap between them make a HUMP in the gap. Give
  the gap its own pad at the buildings' height.
- Planting strips laid 0.2-0.3 m inside the block edge leave a dark sliver of lot asphalt between them and the walk:
  pave the sliver like the walk (`island()` does it now).
- How to check yourself before Yasin does: probe the ground meshes on both sides of an edge (heights at the same
  points), and take LOW shots (eye height 1.6-1.8 m) along every frontage and across every gap; top views hide seams.

## Wear and props: where things may stand
- Wear marks only on surfaces they belong to: cracks / sealant / patches on paving; oil, tyre ruts, grime also on
  gravel; nothing on grass or mulch, nothing over a block edge ("there is asphalt wear on the grass"). Filter every
  decal's four corners + centre against the paint map before building (`wear_on_paving()`).
- Nothing in front of a door AND nothing in front of a walk-up window ("pot in front of interaction zone"): kiosks get
  no door dressing at all.
- Nothing on a pedestrian walk ("ice fridge on peds way"); vending / ice go in an alcove against a side wall, off the
  walk, facing the way people come.
- Nothing under or in front of stairs ("golf car in the stairs").
- Every prop needs a reason ("why are those table and chairs there?"): a table set in an asphalt gap had none. If the
  reason is not obvious from the picture, the prop goes. Give a gap a use (the motel gap became the guests' paved way
  to 3rd St, through the planter to the lot) instead of filling it.
- A prop that only reads from one side can look broken from others: shade sails seen from above/below were a forest of
  bare poles - removed. Look at every new prop kind from eye height before keeping it.
- `free_at()` silently skips props that collide (stalls, door clearances, building + 0.3 m): COUNT what landed
  (MultiMesh instance counts per base) after a polish pass; half the bollards had not been placed.
- Kit facts: the boat trailer model carries its boat (one model per stored boat, never boat + trailer); a utility pole
  stands on a gravel pad, never asphalt; containers yaw 0; enclosure gates count as fence ends.
- The car wash: the kit has only `svc_carwash` (no tunnel wash / vacuum / menu board); asked Yasin for assets.

## Rooms (with the strip room generator; the interiors skill has the full rules)
Yasin's corrections in this zone, each now a rule in `room_gen_strip.gd` and the checker:
- "what are those shops filled with vending machines?" - a cap per kind per room (no repeated snack machines).
- "it looks as if you just filled every wall with paintings, its too repetitive" - at most 2 wall items per wall, and
  wall props must not overlap each other, windows or doors, nor reach into the ceiling.
- "there are wall props contacts but themselves arent there" - hidden frame backs on shared walls: inset 0.12 m.
- "why is there a filing cabinet in the middle of nowhere", "the bin is in the middle of the room", "chair is facing
  the wrong direction" - free-standing items go against a wall or with their desk; chairs face their desk / counter.
- "all of the props are overlapping, there isnt room for benches for people to sit, table is pushed all the way
  against them and the wall prop is overlapping a window, how can neither checker nor validator catch these?" ->
  the checker was upgraded (overlap with clearance, seat room, window test by hanging height) and sent to the PC
  session. Lesson: when Yasin finds a class of fault by eye, ADD IT TO THE CHECKER, then run it everywhere.
- "whats the shop on the left? trash store? it has 3 trash bins inside": a recycling booth's bins belong OUTSIDE.
- "lube room bench looking out looks awkward put it back": benches facing a window can look odd; revert when told.
- "why doesnt isla bistro have indoors?" - a neighbour's room loaded in a shot looked like a missing room: load only
  the rooms you shoot, name what you show.

## Checks to run (the strip area, then the city) and how
- Area layout: write a json with the instances near the zone and run with `CITYKIT_LAYOUT_ONLY=1
  CITYKIT_LAYOUT_EXTRA=res://...json` (export it in every new shell). Delete the json before committing.
- `validate.gd` (CHECKS 0), `check_life.gd -- --only=m_` and grep your prefix (with `--only=m_gr_` the NEIGHBOURS'
  fences are not loaded, so your fence ends falsely "lead nowhere"), `audit_trees.gd`, `sink_check.gd`,
  `interiors/rooms/check_rooms.gd -- --only=g_strip_ --quiet`, lock test. All 0 / PASS before showing.
- `tools/city/run/checks.sh` prints only the LAST 30 validator lines: for a whole-city count, run validate.gd yourself
  and grep your prefix. Other sessions' faults (r_q_* had 550) are theirs: report, do not fix.
- Two Godot runs at once in the cloud can be killed (exit 137): run heavy jobs one at a time. A Godot script that
  hits a SCRIPT ERROR does not quit: kill the stale process before starting the same job again.

## Numbers (how to measure a zone, as the other zone sessions did)
1. `python3 -I tools/city/bake/make_arrays.py` then `godot --headless --path . --import` (the bake needs runtime_tex).
2. Bake the area AFTER: `bake_runtime.gd -- --area=x,z,r --nofarground --out=res://OUT/rt_after/` (trailing slash!).
3. BEFORE: temporarily drop your rows from `city_grid_layout.json`, bake to `OUT/rt_before/`, `git checkout` the layout.
4. `rt_shots.gd -- --runtime=res://OUT/rt_X/ --cams=...` from the same viewpoints (each block from above and along its
   street at eye height); `--nofar` isolates the near content. Per-piece triangle breakdown by MultiMesh base shows the
   heavy items (strip: 31 boats on trailers 69k, wheel stops 68k, ground 68k).
5. Report draws (Yasin's first rule, phone ~150), triangles (say when over ~500k, with the cheap cuts), download (cell
   sizes before/after + lib). Strip: 44-70 draws, 443-822k tris, +11.7 MB (1.6 MB a block).

## Reporting to Yasin
- Short and plain; what changed, what is NOT done, what needs his word. Send the pictures you looked at.
- When he asks "is it done?" answer yes/no first, then the list of what is left.
- Say when a shot is the OLD state: he answered a picture taken before a fix ("how is this seam fixed?") - and it was
  a different seam. Re-shoot the exact view he sent after every fix.
- Preview shots have no shadows and draw buildings darker (lavapipe): say so if it matters.
- After a context compression he says "remind yourself of all the rules": re-read the job board's rules and the
  skills, then continue - do not restart work.
