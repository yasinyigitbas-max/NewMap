# Brief: zero-loading interiors for the city kit (parallel session, 17 Nov)

To start the session, paste this into a new cloud session on this repository:
> Read map_dc/coronado/city_kit/INTERIORS_BRIEF.md from start to finish and do what it says. Work on your own branch.

## 0. Read first, start to finish
1. Every message Yasin wrote in the city-kit session, in order: `map_dc/coronado/city_kit/YASIN_MESSAGES.md` (extracted 17 Nov ~14:50; later decisions are on the JOB_BOARD).
2. `map_dc/coronado/city_kit/JOB_BOARD.md`: the rules. Read "ZERO-LOADING INTERIORS" first.
3. `.claude/skills/coronado-city-kit/SKILL.md`: how the city kit works (pieces, locks, the preview project, checks).
4. `.claude/skills/coronado-interiors/SKILL.md`: how rooms work today (shop_interior.gd, layouts, plans, styles, clutter, signs, fixtures, grime, people, packages).
5. `.claude/skills/coronado-rules/SKILL.md`: the house rules.
6. The kit: `assets/coronado_kit/README.md`, `SPEC.md`, `props/indoor/README.md` (62 indoor props, page I).
7. Today's shops: `map_dc/coronado/shops/data/shops.json` (169 fronts anchored to OSM footprints), `shops/front_doors.gd`, `map_dc/coronado/doors/door_gate.gd`, `shops/interior/*`.

## 1. The premise (Yasin, 17 Nov, his words)
> "indoors arent in other worlds, user will simply walk to doors from outdoors to indoors, theyll open automatically and
> walk into a readily waiting indoorroom whenever they want. thats one of the premises of the game, zero loading open world."

- **The city is being rebuilt** from hand-made, locked city-kit pieces (`map_dc/coronado/city_kit/`).
- **Every enterable room** must sit inside its kit building, behind one of that model's real doors, at the building's floor height, and stream in with the city. There are no separate worlds and no loading screens.
- **Today's 169 shop rooms** are anchored to OSM building footprints that the kit replaces, so each room has to be re-anchored to a kit building.
- **Yasin's shop rules:** fewer shops, spread out; about 60-80 enterable for the WHOLE MAP (Yasin confirmed 17 Nov), not per area; corner shops in every neighbourhood; one of each type per district; the rest are non-enterable fronts, offices or flats.

## 2. The key technical fact to solve first
**Kit buildings are closed shells.** `assets/coronado_kit/SPEC.md` says: no interior faces, opaque glass, no cut-outs. Their doors are painted atlas regions (O_shopdoor, O_apt_door, O_patio ...), not openings.

The game today already makes walkable doors in its baked buildings (the "door cuts" of the cell-package bake, stage D in the coronado-split-bake skill; front_doors.gd; door_gate.gd). Find out exactly how, then propose how a kit building gets a real door:
- cut the door region out of the near tier at bake time
- or swap it for a door prop that opens
- or both
- plus what the mid / far tiers do (they stay closed)
- plus collision

Say what it costs (triangles, draws, bake steps) and what Yasin must decide.

**Do not edit the kit assets:** `assets/coronado_kit` comes from Yasin's assets branch.

## 3. What to produce (your branch only)
1. **A room contract per kit building model the city uses.** The models are recorded on every placed building as meta "kit"; the list is in the layout pieces. For each model:
   - inside volume: footprint minus walls; floor heights per storey (stats: footprint_wd, height, storeys)
   - its doors (stats doors_front: type and offset), which are real entrances, and which floor each serves
   - its windows per facade
   - which room types fit (shop sizes, a flat, an office, a hotel lobby, the civic interiors)
   - Write it to `map_dc/coronado/city_kit/interiors/room_contracts.json`, with a script that regenerates it from the kit stats and meshes.
2. **The shop assignment for the 8 LOCKED samples.** Their buildings are final: about 80 shop buildings and 100 doors.
   - Which buildings get an enterable room, of what type, and behind which door.
   - Re-home as many of today's 169 named shops as fit (keep their names, goods and hours from shops.json). Each sample is a different zone (pilot high street, city centre, industrial, commercial strip, apartment band, civic band, gritty edge, waterfront).
   - The 8 samples are only part of the map: give them their fair share of the WHOLE-MAP total of 60-80, about 20-30 rooms. The city centre and the high street get the most; industrial, the apartment band and the gritty edge only a few (a corner shop, a laundromat, a diner); the civic band gets the civic interiors (city hall, library, post office, police ...).
   - Leave the rest of the 60-80 for the extensions that are still being built. Write the planned per-district totals for the whole map in PLAN.md, so the later districts know their share.
   - Respect Yasin's spread rules.
   - Write it to `map_dc/coronado/city_kit/interiors/assignment_samples.json` with the reasons, plus a picture per sample for Yasin to approve (a top view with the enterable doors marked, and a list).
3. **A short plan** (`map_dc/coronado/city_kit/interiors/PLAN.md`) for the integration:
   - how rooms are placed with the city (piece / building / door -> room transform, floor height on the grading pads)
   - how they stream with the cells
   - what the bake needs
   - the door-opening proposal from section 2, with its costs
   - what must wait for the rest of the city (areas the road fleet is still building, and the blocks that are still empty)
4. **Optional, if time allows:** room contents by type and size using the 62 indoor props. Work in shops/interior (layouts, plans), following the coronado-interiors skill.

## 4. Rules
- **Work only on your own branch** (start it from claude/epic-ramanujan-42qll6). Never push to claude/epic-ramanujan-42qll6. Tell Yasin the branch name when done; the city-kit session merges it.
- **The city kit is read-only for you:** never edit `map_dc/coronado/city_kit/pieces`, `city_layout.json`, `locked.json`, `tools/city/`, `zoning/`, `review/`, or any locked file.
  - Lock state: `python3 -I tools/city/pilot/lock.py status`.
  - The lock test `tests/city_kit/test_locked_pieces.gd` must still say `RESULT PASS` at the end.
- **Don't touch today's live game data** (shops.json, the baked packages) beyond reading them. The switch-over happens at integration.
- **Think like an architect, an interior and exterior designer, and a city planner:** every room and door has a reason (who uses it, when, why there); a lived-in look, never brand new; variety; no jagged edges.
- **The city-kit road fleet may be building in another container at the same time.** Don't depend on its unfinished files (review/*_sites.json may still change).
- **Report:**
  - what you produced (files)
  - the door-opening proposal and its costs
  - the open decisions for Yasin
  - what you could not do and why
  - say plainly what is measured and what is a guess; nothing is measured on the Redmi
