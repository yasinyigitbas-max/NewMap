# City kit job board (read me FIRST, and again after every context compression)

This file is the session's memory of what to do and how Yasin wants it done. Keep it current: tick items, add new
ones the moment Yasin asks for them, never delete his rules. Method and traps live in the skill
`.claude/skills/coronado-city-kit/SKILL.md`; the zone plan in `CITY_PLAN.md`.

## WHERE WE ARE (17 Nov ~11:50 UTC, written before a context compaction)
- 19 Nov ~22:45 (PC session): THE LAND FITTED UNDER THE WATERFRONT FILL TOO (Yasin, shown the trial pictures:
  "Show me first", then "Yes, fit it"). Only the land: `lower_land_to_pieces.py --only=grow_wf --fit --ease-from`
  wrote exactly the trial he saw: 2,333 nodes lowered (usual 0.24 m, largest 1.64 m), 2,641 raised back to the blocks'
  edges, no node of another family, no sea node, none pushed under the beach line. Game land baked; x_wall_feet
  rebuilt (87 blocks, 7,423 faces). AFTER: the six n_wf_* pieces 0 m2 under the land (16,334 before); every growth
  family 0; lock test RESULT PASS. Pictures OUT/super/work/wf_shots, wf_e_shots.
  NOT CHECKED: 90 spots where the lowered land meets a node under a neighbouring piece with a step over 1 m (under or
  between pieces, not seen in the pictures); a right-angled line in the empty land east of the north block in the
  trial's top view (maybe the preview's height lines); the runtime bake and the phone.
- 19 Nov ~22:00 (PC session): THE LAND FITTED UNDER THE APARTMENT FILL (Yasin: "apartmen block still built under the
  terrain fix it"; "they were supposed to be careful from th start"; "CONSIDER THE ELEVATION" - "i deliberately wrote
  this to all of them"). The apartment and waterfront fill branches had been merged into this branch that afternoon
  (commits a4874e33, 3c77453a) and their 14 pieces added to the layout; the land was not fitted to them.
  MEASURED BEFORE: apartments 38,813 m2 of 88,318 m2 of block ground under the land. Blocks 1 and 2: up to 26 cm
  under on 3-64 % of each piece. Block 3 (n_apt_b3_w / _e): 76 % and 83 % under, up to 0.70 m and 1.03 m: that block
  did not follow the land. Waterfront fill: 16,334 m2 under, 8,462 m2 by more than 30 cm, deepest 1.42 m.
  DONE (ONLY THE LAND; no piece, no lock): `lower_land_to_pieces.py OUT/super/ground --only=grow_apt --fit
  --ease-from=<the land before>` (new option --only: of the growth zones only these families ask and are fitted):
  4,671 nodes lowered (usual 0.13 m, largest 1.19 m), 715 raised back to the blocks' edges, none of another family,
  no sea node; changed nodes lie in x 256..492, z -784..-296. Game land baked again (height.f32z); `x_wall_feet`
  rebuilt for the new land and the new blocks (87 blocks, 7,417 faces). AFTER: apartments 0 m2 under the land; every
  other family as before; lock test RESULT PASS (510 pieces, 153 files). Pictures as it was / fitted:
  OUT/super/work/apt_shots (sent to Yasin).
  NEW TOOL: `tools/city/super/sc_ground.py` writes the whole city's ground in the form ground_check.py and the land
  tools read, from the superchecker's read-outs (30 s; the Godot whole-city dump dies on this PC's card).
  NOT DONE: THE WATERFRONT FILL IS STILL 16,334 m2 UNDER THE LAND (not asked; it lies at the shore that was redrawn on
  19 Nov morning: a look first). The runtime bake and the phone have not been run with this land. Block 3's own
  ground still ignores the hill: the land was cut to it (up to 1.19 m), the block was not rebuilt.
- 19 Nov ~20:30 (PC session): THE FIRST BLOCK IS INSTALLED BY THE SUPERCHECKER: g_v1_j4ne (gritty, J Ave x 4th) AND ITS
  TWO ROOMS (Yasin, asked "Put the proven fixes into the first block (g_v1_j4ne) now?": "Yes, install it").
  WHAT CHANGED IN THE MAP, AND NOTHING ELSE: `pieces/g_v1_j4ne.scn` (96 single changes: 5 builder trees out, 54 wear
  marks off their surface, 12 oil marks with no car place, 10 roof items down onto their roof, 15 collision boxes for
  columns and posts); the new piece `pieces/t_grt_j4ne.scn` (ONE hand-placed tree, from `zoning/trees/grt_j4ne.json`)
  with one new row in `city_grid_layout.json` (554 rows); the rooms `g_grt_v1_j4ne_trade_corner_0` (1 poster drawn
  back out of the wall to the next shop) and `_1` (2 posters); `locked.json` (the block and the two rooms opened and
  locked again by the install, on his word). Every change is a line in `review/superchecker/<name>.fixes.json` with
  its proof beside it (`.proof.txt`: PROOF RESULT PASS for all three) and `log.jsonl`. The old files are kept in
  OUT/super/backup/ (and in git).
  CHECKED AFTER: lock test RESULT PASS (496 pieces, 103 files); the installed block checks exactly as its proven copy
  did (0 findings left with one right answer); the validator on this area (block + 10 pieces round it): 0 problems
  before, 0 after; the life check: the same 37 lines naming this block before and after (they are the kinds that need
  a place chosen: 19 wall items on glass, 10 fence ends, 7 poles on asphalt, 1 on a path); the tree audit: 0 in hard
  ground; the old indoor checker on the two rooms: 0 problems; two pictures of the installed block opened.
  STILL OPEN ON THIS BLOCK: 66 findings that need a place chosen by hand, one at a time; 35 reported only (4 back
  yards open, 10 fence ends, 7 poles with no wire, the old station and the car wash with a shop door and no room,
  the wall between the two shops with no thickness, shelves across the back roll-up door of Rim & Tire).
  NOT DONE: the runtime bake and the phone with this block; the streets round it still carry their builder trees.
- 19 Nov ~19:30 (PC session): THE SUPERCHECKER'S LIST IS FULL + COLLISIONS (Yasin: "why arent the check list full yet?
  write them in"; "checker should add collisions to everything that sit on the ground, including columns of
  buildings, some of them lack it. speed it up"). STILL NOTHING OF THE MAP CHANGED: copies only.
  THE LAST REPORT UNDER-COUNTED: it named five missing rows of the 89 given to Yasin; about thirty were missing or half
  done. They are written now (`tools/city/super/sc_more.py`); `tools/city/super/CHECKS.md` is the list row by row:
  the kind each finding carries, how it is fixed (auto / a place chosen by hand / report), what no check sees.
  COLLISIONS: `no_collision` (a thing standing on the ground with no collider: it gets the kit's own shape for that
  prop, as kit_lib gives the others; roof items are left out) and `column_no_collision` (a column or post of a
  building's own mesh, 0.4-1.6 m up, that the model's collision shape does not cover: a box under that building's
  collision body). Both are single lines of the fix list with their own proof.
  TRIED ON COPIES: g_v1_j4ne 96 changes (15 column boxes: the trade corner's posts, the car wash, the old station)
  proof PASS; r_q_m800_m200_ne 153 changes (14 prop collisions - stucco wall panels among them - 12 column boxes) proof
  PASS; both copies check clean of what was fixed and show no new fault. Twelve rooms run without error.
  ALSO FOUND: the city layout names no missing file; 8 piece files are placed by no row (j_rg_e0_s340, j_rg_e627_s0,
  s_rg_b009, s_rg_b131_1/2, s_rg_b136_w, s_rg_b161_2/w); the residential block's 7 houses have back yards you can walk
  out of; the gritty block's 7 utility poles carry no wire (no wire piece reaches the growth).
  NOT DONE: the new kinds were tuned on these two blocks only (expect false alarms elsewhere until pictures are
  looked at); no install; no city-wide run; a column box is measured from the mesh's points, big ones need a look.
- 19 Nov ~17:00 (PC session): THE HAND-PLACED TREES, WRITTEN INTO THE SUPERCHECKER (Yasin: "removing existing trees
  entirely from every area it inspects, and only places them by hand according to tree plantation plan we made";
  then, asked what next, "Trees first"). STILL NOTHING OF THE MAP CHANGED: copies only.
  A TREE LIST is a plain file written BY HAND, `zoning/trees/<area>.json`: its piece, its zone, the plan's rule for
  that zone in the plan's words (docs/TREE_PLAN.md), and one line per tree: model, place, turn, size, WHY.
  `python -I tools/city/super/sc.py trees <area>` checks every line (`sc_trees.py`: soft ground or an open well, the
  line's height = the ground's, 0.9 m off fences, 1.2 m off walls, 2.5 m off doors and outdoor stairs, the trunk clear
  of every prop, not on a stall, 3 m between trees, a reason given; and the plan's in-view limit from the streets
  round it: 8 broadleaf, 12 of any kind within 60 m), then builds the list into a COPY of the piece `t_<area>`
  (`sc_trees.gd`: kit_lib's own prop builder, 64 m squares) and reads the copy back: it must hold exactly the list's
  trees. It chooses no tree and no place. `sc_trees.py where <piece> <x> <z>` says what the ground is at a spot.
  `install` puts t_<area> in place and adds its layout row (tested on a copy of the layout: one row more, every other
  row and the file's format unchanged); `integrate.py` keeps such rows when it regenerates. A well in which a list's
  tree stands is not paved (0.7 m, as in the bake). The bake's `--notrees` already keeps t_* trees.
  FIRST LIST: `zoning/trees/grt_j4ne.json` for the gritty block g_v1_j4ne (rule: almost none): its five builder trees
  go, ONE comes back, a eucalyptus 2.2 m behind the bench that faces the swing. Check ok, built, picture taken
  (as it is / the fixed copy). Counter-tests: a tree on asphalt, at a wall and in a bin, at a wrong height, with no
  reason: each refused.
  ALSO: "show me what worn grass look against tire marks": three views from straight above sent. Both are faint
  (strength 0.4-0.55); from eye height neither shows in the preview. What reads strongly on grass are cracks, oil and
  patch marks (0.9). The tool still removes every mark on grass; Yasin has not said whether worn-grass bands stay.
  NOT DONE: no list for any other block or street; the new lighter tree models have not arrived (lists name today's
  models; a model is one word of a line); nothing installed.
- 19 Nov ~15:30 (PC session): THE SUPERCHECKER, FIRST WORKING STATE + THE KIT UPDATED (Yasin: "make a superchecker for
  both indoors and outdoors that changes irregularities that they find by hand and checks that nothing else other than
  the irregularity was changed? THIS TOOL MUSTNT CHANGE THE ENTIRE BLOCK WITH A GENERATOR"; "if it can prove that it is
  fixing things by hand, it can do all of the block at once after finding all the faults"; "remove all of the trees in
  the area and fill the wells with the material surrounding it"; "many walls indoors are very thin and the next shops
  props can show on the other side, add that check, also i want no tire marks on the sidewalks too").
  NO PIECE AND NO ROOM OF THE MAP HAS BEEN CHANGED: everything below ran on COPIES in OUT/super/work.
  `tools/city/super/` (read `sc.py`'s header): ONE command, `python -I tools/city/super/sc.py check <piece>` (finds,
  outdoors and that piece's rooms, changes nothing), `fix <piece>` / `fix-room <room>` (carries the fix list out on a
  COPY, proves it, checks the copy again), `shots <piece> --cams=...` (the same view as it is / the fixed copy, side by
  side), `install <piece> --by=Yasin` (puts the proven copy in place, keeps the old file, opens and closes the lock,
  writes review/superchecker/: ONLY on his word, never run yet).
  HOW IT FIXES: `sc_fix.gd` loads the SAVED scene and changes single items from a list (move / remove one prop in all
  its detail tiers with its collider; remove one wear mark; pave one tree well with the bake's own well filler). No
  piece script runs, nothing is placed by a rule. A fix whose new place must be chosen is written without one and is
  NOT carried out until a person fills it in ("chosen": true). THE PROOF loads both files and compares everything in
  them (every node, every mesh, the ground triangle by triangle, every prop instance of every tier, every collider,
  every wear mark, lights, a room's built-in sign picture by its pixels): what differs must be exactly the listed
  items by exactly the listed amounts, else PROOF RESULT FAIL. It starts from the raw differences, not from the
  fixer's own search. Counter-test: two changes left off the list -> FAIL. It caught a real fault of the fixer itself:
  a re-saved room lost its sign picture (Godot drops a built-in compressed picture unless told to keep it; fixed).
  WHAT IT CHECKS: outdoors, 40 kinds (`sc_find.py` WHAT_IT_CHECKS and CANNOT_SEE): trees and wells; props in the air /
  sunk; fences; overlaps; props in buildings, at doors, shop fronts, roll-ups, garages; wall items against walls,
  roofs, doors and windows; surface rules (play on bark, poles, bins, hydrants, seats facing walls, stalls, roads);
  wear marks against their surface (NO tyre marks, oil or asphalt patches on a sidewalk); the piece's ground against
  the land, its buildings and its neighbours (reported only); faults of the file. Indoors (`sc_rooms.py`): the old
  indoor checker's 25 kinds taken over (its notes for locked rooms COUNTED) + new: doors and windows blocked, counter
  in view, queue space, tills turned wrong, things turned to a wall, tables without seats, what a shop needs (a
  DRAFT list, not approved), lights, same layout as another room, THIN WALLS between two shops and props showing
  through them.
  TRIED: gritty block g_v1_j4ne: 142 outdoor findings (69 with one right answer, 58 needing a place chosen by hand, 27
  reported only); on the copy 69 changes, proof PASS, no new fault; its two rooms: the wall between them has NO
  thickness (one sheet), a poster of each shows in the other; shelves stand across the back roll-up door and a
  window; the old indoor checker says 0 problems for both. Residential r_q_m800_m200_ne: 106 wear marks on grass or
  mulch, 14 trees, 2 overlaps. Amber street piece: 18 trees out, 12 wells paved, proof PASS.
  OPEN FOR YASIN: (1) 72 of the 106 marks on the residential lawns are "grime" (16 Nov: "worn grass where people cut
  corners"; 19 Nov: "asphalt wear on the grass"): the tool removes them as it stands; say if worn-grass marks stay.
  (2) The hand-placed trees are NOT written: the tree lists (zoning/trees/<area>.json, each tree a line) and their
  piece builder come next; docs/TREE_PLAN.md is the rule per zone. (3) Nothing is installed.
  NOT DONE / NOT CHECKED: walk widths, empty parks, repeated trees, room openings against the building, unnamed sign
  boards (rows 18, 48, 49, 68, 79 of the list given to Yasin); no city-wide run; the checks' thresholds were tuned on
  two blocks only; pictures were opened for two views.
  THE KIT (Yasin: "find the assets branch on the main repo and copy over its contents"): assets/coronado_kit now equals
  the game repo's assets branch at e3d085dc (19 Nov 11:15): +244 files (the house interior set: 36 decor, 8 rugs, 26
  furniture, page H) and 548 changed (545 prop / fence near models gained an occlusion link; mesh data identical).
  THERE ARE NO NEW TREE MODELS on that branch (foliage unchanged; the three other asset branches there are from 13-14
  Nov and hold no kit). Lock test RESULT PASS after it. TRAP: do not run a second Godot while `--import` runs: two
  import files were reset to defaults that way (restored).
- 20 Nov ~03:00 (PC session): PEOPLE, STEP 3: THE WHOLE BRAIN AND THE PLACES, C++ (Yasin: "build all of the missing
  parts of npcs and crowds, dont call it done unless its 100 percent native code and all features implemented").
  Read docs/TRAFFIC_PEOPLE_PORT.md section 26: it has THE LEDGER of his list, line by line (BRAIN / GAME / NOT).
  NEW TOOL `tools/city/traffic/make_places.gd` (C++ class `PeoplePlaces`): 2,102 places from the pieces' own props
  and buildings and the shop list -> `traffic/places.bin`. RUN IT AFTER make_streets.gd AFTER EVERY BAKE / NEW BLOCK
  (nothing of the map is in the code). THE BRAIN (`ped_crowd.*`, `ped_goals.cpp`, `ped_party.cpp`, `ped_life.cpp`):
  routes and goals, doors, shops with hours, benches, beach, park, cafe, bus stops, groups on their leader's trail,
  phone calls, shop windows, meetings, beggars, night workers, rain, fright, jumping out of a car's way, the player,
  the hooks and events. `bash native/tests/run_crowd_test.sh` RESULT PASS with three seeds (846 people, 30 minutes: 0
  inside each other, 0 beside the pavement, 0 standing a minute; 0.57 ms a step).
  20 Nov ~06:00: THE CROWD IS IN THE GAME AND DRAWN (doc section 27): class `CityCrowd` (joined to the traffic,
  the streamer's cells, the hour), the far figures as ONE draw (tool `make_people.gd` -> `far_poses.bin`, the old
  game's person shader), test app `--people=N`. One picture `review/people_19nov/crowd_first.jpg`.
  20 Nov ~09:00: QUATERNIUS ANIMATIONS + THE NEAR BODIES (doc section 28; Yasin: "download quaternius universal
  animation library 1 and 2 ... keep your custom animations for pushes and impacts ... use quaternius animations for
  getting up"). The free Standard packs (CC0) are in `characters/quaternius_ual/`; tool `make_anims.gd` (C++
  `AnimRetarget`) fits 84 clips to our figure; the far figures are posed from them; the nearest 12 people are real
  animated bodies with a clip for every act; pushes and impacts stay the physical body; getting up is LayToIdle.
  Order after a change of clips: make_anims.gd, then make_people.gd.
  20 Nov ~11:00: A PLAYER ON FOOT AND THE CROWD ROUND HIM (doc section 29), all C++: class `CityPlayer`
  (walks, runs, camera behind, the Quaternius clips by his pace; `CityCrowd::set_player`), 12 capsules on the people
  round him (he cannot walk through a standing person), running into a walker hands him to his balancing body and he
  walks on afterwards, umbrellas in rain, towels on the beach, the murmur at talking groups.
  `tests/people/test_crowd_game.gd` RESULT PASS. Nothing of it seen in motion yet.
  20 Nov ~14:00: TALKING TO THE PLAYER (doc section 30), all C++: class `CityTalk` (the old game's lines and flow:
  refusals and grudges, three lines, say it by microphone / typing / skip, answers with a real shop's name, the
  direction, minutes, the clock, a mission; "Hi again"; the groups' own conversations; captions and buttons made in
  code; the recorded voices). Words and 842 clips a voice carried over by `tools/city/traffic/make_talk.py`.
  `tests/people/test_talk.gd` RESULT PASS. Test app: `--walk=1 --people=N`, E speaks to somebody. The phone's speech
  plugin is not in this repo's app yet; this map's shop names have no recordings (captions only).
  20 Nov ~16:00: THE BUSES (doc section 31), C++: `CityTraffic::make_bus_lines` makes loop lines from the map's own
  bus stops when the streets load (today 2 lines, 14 stops each), the old core's timetable buses drive them (every
  5 minutes by day), a bus at a stop opens its door to the people waiting (`buses_at_stops` -> the crowd's `bus_at`).
  `tests/traffic/test_bus.gd` RESULT PASS, the traffic core test RESULT PASS with them. Mended on the way: a parked
  car pulling out into a car parked in another row stood for good (traffic_parking.h). NOT tried: people boarding a
  real bus in the engine; nobody has seen a bus.
  20 Nov ~19:00: THE PRO QUATERNIUS PACKS (doc section 32; Yasin bought both Source packs: "replace them ... use
  enter and exit animations ... use them for crowd fights too", "use everything we can", "one side should win ...
  they shouldnt kill each other", "voices will come later, dont hold back on using animations based on voices").
  159 clips a figure + 9 mixed ones (walk + talk / phone, sit + phone / drink, a beggar asking, a hurt walk); every
  act has its way in and out (the brain's A_RISE: he gets up where he is, then walks); fights with turns, hits and
  dodges, a winner who celebrates and a loser who walks away hurt (the last blow a real shove); after the player's
  shove he tells the player off or hits back, people look, and he goes on to where he was going.
  `tests/people/test_acts.gd` + the other four people tests RESULT PASS. KEPT AS MY OWN, NOT CLIPS: ragdoll, pushes,
  balancing, impacts, falls. OPEN: a body pushed from the front may never come to rest (taken back after 6 s);
  swimming not used yet. WAITS FOR YASIN'S GO, after all shops are in: people INSIDE the stores (keeper at the
  counter, customers), with the counter clips.
  Then: the player swims (`CityPlayer.water_y`, `tests/people/test_swim.gd` RESULT PASS; `--walk=1 --water=Y`); the
  crowd does not swim yet (needs places in the sea). Lock test RESULT PASS at the end of the round.
  STILL TO DO FOR "DONE": the game's node (join to the traffic, draw far figures and the 18 near bodies with the
  acts' animations, the balancing body for a walker who is pushed or hit, capsules round the player, umbrellas,
  towels, murmur), a player on foot, the talking, a bus line, the real get-up. NO PICTURE OF THE CROWD EXISTS YET.
- 19 Nov ~23:00 (PC session): PEOPLE, STEP 2: THE WALKING CROWD'S CORE, WRITTEN NEW, PLAIN C++ (`native/src/
  ped_crowd.*`, class `pc::Crowd`). Read docs/TRAFFIC_PEOPLE_PORT.md section 25. A pavement is a little two-way
  street: people keep right in two files, follow, pass when nobody comes, never move into a body (held: side step,
  then sidle past sideways, then turn round), wait at the kerb for the traffic's own signal clock, step out and jog
  on the map's long crossings, take gaps in cars where there are no signals, appear in a ring round the camera.
  Console test `bash native/tests/run_crowd_test.sh` RESULT PASS: 500 people, 30 minutes, 0 inside each other, 0
  beside the pavement, 0 on the road at green, 0 standing a minute; same seed same crowd; 0.22 ms a step.
  NOT DONE: it is the BRAIN ONLY, nothing is drawn or in the game; not joined to the traffic (cars do not know of
  walkers yet); no groups, places, reactions, speaking; a second seed leaves one near miss with a test car open.
- 19 Nov (cloud, branch claude/fill-apartments): APARTMENT FILL, THE WHOLE ZONE (Yasin: "go on populate the entire
  zone"): blocks 1-3 drafts, 8 pieces n_apt_*, 15 rooms g_apt_*, land first on measured street heights (blocks 2-3 on
  slopes: level pads, retaining faces on the residential line). Draws 64-134, triangles over 500k. LOCKED on Yasin's
  word ("just lock them if you are done with placements"): 8 pieces + 15 rooms, lock test PASS (504 / 118). POLISHED and
  relocked ("run a polish pass ... plenty of props", "have variety"): +510 props outdoors, rooms refilled with variety. Read
  review/fill_apt/README.md.
- 19 Nov (cloud, branch claude/fill-apartments): APARTMENT FILL BLOCK 1 (B Ave - Adela, 7th - 8th St, the L round
  a_ne) DRAFT, waiting for Yasin's word before blocks 2 and 3. Three pieces n_apt_b1_bw / _be / _7th + 10 shop rooms
  g_apt_*; land first (level at the walk, all seams 0.000 m, dry land trial only); own tables grow_apt_blocks.json,
  assignment_apt.json. Draws 64-133 a view, triangles over 500k. Read review/fill_apt/README.md. Nothing locked.
- 19 Nov (cloud, branch claude/fill-waterfront): WATERFRONT FILL BLOCKS 1 + 2 built and LOCKED on Yasin's word (n_wf_b1w/m/e, n_wf_b2w/m/e + 35 rooms g_wfa_*). Not yet in city_grid_layout.json (table review/grow_wf_blocks.json for integrate.py); the land fit (lower_land_to_pieces --fit --ease-from) must run with them. Read review/fill_wf/README.md.
- 19 Nov late (claude/fill-city-centre): CITY-CENTRE FILL, ALL SIX BLOCKS BUILT, NOT SHOWN, NOT LOCKED. 17 pieces n_cc_b1..b6_* in review/grow_cc_blocks.json (own table, not integrated), 162 rooms g_cc_* (checker 0). Towers alternate glass 59 m / condo 50 m (b1 glass, b2 condo, b3 glass, b4 condo, b5 glass, b6 condo). Blocks 3-6 on the slope: pads at each walk's highest point + paved frontage strips, open ground on the land eased to the edges, retaining faces; the housing squares' lanes run on as alleys to 6th St's existing aprons, lanes without an apron end in parking courts (an apron on 8th St at u 190..196 would let block 6 through: Yasin's call). Land NOT written (dry trial: largest -1.21 m under block 4's lane flats). Pictures of blocks 4-6 skipped at Yasin's word. Read review/fill_cc/README.md.
- 19 Nov evening (claude/fill-city-centre): CITY-CENTRE FILL, BLOCK 1 BUILT, NOT SHOWN, NOT LOCKED. Four pieces n_cc_b1_* (Amber wall with the 59 m glass tower on Amber x 6th, 6th St row, C Ave corner + church, the COURTHOUSE on its square on 7th St beside city hall + the district garage), 22 rooms g_cc_b1_*, own table review/grow_cc_blocks.json, own tool copies (cc_fill_lib, room_gen_cc, split_props_cc ...). Flat block: ground 0 buried / 0 hanging / 0.0 cm seams; land NOT written (dry trial asks 43 nodes -6 cm). Validator 0 in these pieces, rooms 0, lock PASS. Read review/fill_cc/README.md. Waiting for Yasin's word before block 2. Yasin: "add one very tall building to every block you make, alternative in between them" (glass 59 m / condo 50 m alternating).
- 19 Nov ~20:00 (PC session): A TRAFFIC CAR THAT IS HIT IS A REAL CAR, ALL C++ (Yasin after the compaction: "act like
  a developer working for rockstars next GTA and tackle the problems"). Read docs/TRAFFIC_PEOPLE_PORT.md section 23.
  Six physical cars (`CityCar`) are made at the start; a moving or parked car of the traffic that the player's car
  (or an already knocked car) is about to touch becomes one of them a moment before the touch, with its model,
  colour, place and speed: it is shoved, spun, rolled by the engine. A hit driver brakes; when his car stands on its
  wheels along a lane with nothing in its way he drives on as traffic, else the car stays and the traffic goes
  round it. Before this the player's car drove THROUGH the traffic (its mask lacked their layer). Test
  `tests/traffic/test_knock.gd` RESULT PASS (parked car shoved 7 m; head-on with a moving car; the driver drives on
  0.3 s after the way is clear); car engine test PASS again.
  ALSO (doc section 24): the four nearest traffic cars have their wheels apart: the front ones turn with the
  driver's hands, all four roll (one more draw a model; one picture, `review/traffic_19nov/wheels_sheet.jpg`).
  NOT DONE: nobody has seen it (no window opened); not in the streamed city, not on the phone; a car across the
  road or on its roof stays for good; no damage, no sound; the 12-run traffic test was not rerun (core untouched).
- 19 Nov ~17:00 (PC session): PEOPLE, STEP 1: A BODY THAT KEEPS ITS OWN BALANCE, ALL C++ (Yasin: "gta 5 level npcs
  ... balance themselves, be able to pushed around and resist falls, just like in the euphoria engine"). Read
  docs/TRAFFIC_PEOPLE_PORT.md section 22. `native/src/ped_body.*` (plain C++): thirteen jointed bodies with muscles
  and their own small physics; it holds small pushes without a step, STEPS to where it will be falling, staggers
  3-7 steps under hard shoves and stands again, goes down as a rag doll that braces when it cannot be caught, lies
  still. `native/src/city_ped.*` (class `CityPed`): the old game's 50-bone figure; the body takes over from the pose
  the animation had (no jump), the bones follow it, the animation or the "get_up" clip is blended back in.
  `characters/rocketbox/` brought from the old game (41 bodies, skeleton, clips, textures, 36 MB, MIT).
  Console test PASS (26 cases: holds up to 170 N s from front or back, 80 from the side; a frail person falls at 120;
  cars at 30 / 60 km/h throw it 12 / 27 m), engine test PASS (the real figure: shove, charge, car, gets up).
  One sheet of five pictures: `review/people_19nov/body_sheet.jpg`.
  THE GET-UP (evening): the clip set has NO rise from lying (get_up = wake_up = stand_up = a rise from a seat; die =
  idle). Interim: it gathers into the clip's seated start for a second, then rises (3.2 s; `getup_sheet.jpg`). The
  real one (the body pushes itself up, or two new clips) is still to do.
  NOT DONE: never seen in motion (the get-up looks too quick in the one picture); plain colour, not the people's
  look; NO WALKING CROWD here (the body of one person only); nothing in the test app uses it; not on the phone.
- 19 Nov ~14:00 (PC session): CARS THAT STEER + A CAR TO DRIVE, ALL C++ (Yasin: "a moving traffic system and good car
  physics ... ride exactly like gta 4 if not gta 5 ... cars just slide into turns instead of steering into turns, take
  abrupt u turns, lock the traffic up ... ALL MUST BE WRITTEN 100% IN C PLUS PLUS"; second: "gta 5 level npcs ...
  balance themselves, be able to pushed around and resist falls"; then "you can get the old npcs from the game BUT
  FULLY WRITTEN IN C PLUS PLUS" and "i have about 40 animated bodies standard with 50 bones"). Read
  docs/TRAFFIC_PEOPLE_PORT.md section 21. KEPT: the old core's brain (following, junction go-aheads, signals, right of
  way, the parking's books). NEW: every traffic car is a STEERED BODY (`native/src/traffic_body.h`): front wheels at a
  hand's rate and within their lock, the rear follows, no sideways slide, no turn tighter than a car's; lane changes
  and the way into / out of a kerb stall are steered S-curves; cars lean and dip. Traffic test RESULT PASS, 12 runs
  (0 overlaps, 0 crashes, 0 refused moves, nobody stuck, hardest sideways push 4 m/s2 where it was up to 11). NEW: the
  PHYSICAL car (`veh_dyn.*`: springs, tyres that slip, engine, gears, brakes; two feels, IV soft and sliding, V
  flatter and grippier, for all 12 models) and `CityCar`, a car to drive on the engine's physics (`--car=stern_g` in
  the rig); console test PASS for 24 car x feel pairs, engine test PASS. Lock test RESULT PASS.
  NOT DONE: nobody has driven it (the feel is tuned to numbers only); `--car` was tried unattended only (the car
  stands on its wheels in the streamed city: `-- --car=stern_g --at=-600,-1000,90 --traffic=20`); no phone run; a
  hit traffic car is not yet handed to the physical car; traffic wheels do not turn on screen; PEOPLE not started.
  FOUND IN THE MAP: on today's bake the streets tool measures Amber Ave between z -1100 and -800 (b038 / b039) as a
  1 + 1 lane street with the kerb 4.5 m from the middle (it was 2 + 2 lanes, 11.5 m): 9 junction paths touch a kerb
  there and the whole-city traffic jams at (-8, -826) on a streets file made from it. Something lies over Amber's
  outer lanes since the growth. NOT looked at, nothing changed; the committed streets.bin (older bake) stays until
  Yasin says. A fresh bake + `make_streets.gd` is needed before the kerb check of the steered cars counts.
- 19 Nov ~10:45 (PC session): x_wall_feet REDONE FROM THE BLOCKS' EDGES (Yasin on the first version: "there are still big
  gaps, fill them"). The first version (entry below) only put a face under a wall foot measured above the land at its
  two ends: stretches in between and edges with no wall stayed open. Now `wall_feet.py` walks every growth block's
  ground edge (holes too) and gives a face to every metre that stands more than 8 cm over what is right outside - the
  land OR another piece's lower ground (a street, a neighbouring block) - from the edge 30 cm into that surface, 2 cm
  inside the edge (hidden behind the block's own wall where it has one). 79 blocks, 7,267 faces, 29,068 triangles
  (both sides), 6,378 m of edge: over 15 cm 4,967 m, over 50 cm 2,258 m, over 1 m 849 m, highest 2.86 m; 5,821 m of
  it beside another piece, 557 m beside empty land. THAT IS THE LENGTH THAT GETS A FACE, NOT THE LENGTH THAT WAS OPEN:
  how much was visibly open is not measured. Seen in pictures (one camera a run, pixel-compared): the wall bases
  beside empty land are closed without a sliver; three views of lines where two blocks meet show NO visible change
  (walls and fences already stood there). Piece 375 KB; in the bake the faces merge into the cells' ground. No locked
  piece, no land changed (599 LOCKED ok). NOT CHECKED: validator / check_life (cloud), the bake, the phone, how the
  29 k triangles weigh there. Pictures `review/wall_feet_19nov/`.
- 19 Nov ~10:00 (PC session): THE "FLOATING" EDGES ARE WALLED TERRACES; A FACE UNDER THE WALL FEET (Yasin: "show them to
  me first", then on the trial picture "Yes, add it"). WHAT ground_check.py "hanging" REALLY IS: a block's yard surface
  more than 30 cm over the land beside empty land. Of 178 m2 counted, 104 have a wall face of the block down to the
  land, 56 have their wall as a prop or are a quay / the approved rows r_n, r_s (fence to the land), and the rest a wall
  that stops short. Measured at the wall FEET of the growth blocks (1,506 m of outer wall): foot more than 15 cm over
  the land on 24-41 m (by how the 4 m land squares are split), at most 37 cm; the land cannot rise there (0 nodes: a
  lower piece of ground lies within the same 4 m). NEW: overlay piece `x_wall_feet` (unlocked, like x_shore_foam): 272
  stretches / 534 m of wall foot in 20 growth blocks get a face from the foot to 30 cm into the land, in the walls' own
  material, as "ground" meshes (the bake merges them: no draw of their own); 1,088 triangles. Data
  `zoning/wall_feet.json` from `tools/city/pilot/zoning/wall_feet.py` (measures, decides nothing), builder
  `pieces/x_wall_feet.gd`, one new row in `city_grid_layout.json` (553 rows; `integrate.py` adds it when it
  regenerates). No locked piece changed (599 LOCKED ok), the land not changed. Pictures `review/wall_feet_19nov/`.
  NOT CHECKED: validator / check_life on the whole city (they need the cloud), the runtime bake and the phone with the
  new piece. Rebuild `x_wall_feet` after any change of the land or of a growth block (wall_feet.py --write, then
  x_wall_feet.gd). Preview trap met here: two cameras in ONE shots.gd run can leave distance tiers popped on the second
  picture; take before / after pairs one camera a run.
- 19 Nov ~08:30 (PC session): THE SHORE AT THE WATERFRONT PIER AND BEACH (Yasin, on the bird's-eye view: "can you erase
  the sand under the pier and that irregularity on the second shot, make it smooth"; then two red lines drawn on the
  picture and "Yes, sand to the lines", "make them approach smoothly like this", "and make the foam follow that line";
  then "make the bubbles follow sand better and unifiy it, i can see patches on it"). WHAT WAS WRONG: the smooth coast
  (coast.json) ran across the beach block f_sw's own shallow water: a sand bar with a lagoon behind it, the pier and its
  moored boats standing in sand. NOW (tool `tools/city/pilot/zoning/waterfront_shore.py`, dry run by default): the
  water line is one smooth curve from the north beach's water line (z 190) into f_sw's OWN wavy water line (z 258),
  along it, and from the block's south end (z 299) into the coast's water line (z 326); the pocket between the old bar
  and the beach is filled with sand up to that curve; one even beach face through the water line (no 4 m teeth under
  the foam). The foam strip follows it: `zoning/shore_foam.json` chunks 44 and 45 redrawn there, `x_shore_foam`
  rebuilt (unlocked piece, a mesh only). At the south corner the new foam fades in exactly where f_sw's own foam fades
  out. CHANGED: terrain_grid.npz (392 nodes), shore_foam.json, pieces/x_shore_foam.scn, the game land (460 height
  samples inside 140 x 132 m; class / shore_dist / water_dist / ground_params follow). No locked piece (599 LOCKED ok).
  MEASURE: `ground_check.py` "sample block buried" 308 -> 350 m2: that IS the sand the red lines ask for, lying over
  f_sw's shallow water on purpose. Floating edges 187 -> 186 m2.
  LEFT: (1) for about 20 m north of z 258 f_sw's own foam comes out from under the new sand next to the new foam:
  taking it out there means opening the LOCKED f_sw (Yasin's word). (2) The larger moored boat's bow now touches the
  water line. (3) Preview only: the land's sand is paler than f_sw's beach, so the filled pocket reads as a paler
  wedge. (4) coast.json is NOT updated: terrain.py would bring the old bar back. (5) The six small boats north of the
  pier (another piece) still lie on sand: not looked at. Pictures `review/waterfront_19nov/`.
- 19 Nov ~07:15 (PC session): ONE SKILL FOR ALL BUILDING: `.claude/skills/coronado-super-builder/` (Yasin: "fetch the
  skill files from all 4 city extenders branches, combine it with your knowledge from this session, add the notes
  below and make a super builder skill"). It merges the four `coronado-zone-growth` skills (branches grow-residential,
  grow-gritty, grow-industrial, grow-strip), the 19 Nov land work and his two audit lists (outdoor: sunk areas, tyre
  marks only on asphalt at lights / crossings / garages, overlapping and obstructive props moved to a free and more
  logical place; indoor: chairs facing right, wall items, full floors, nothing in the air, props that fit the store,
  everything reachable, windows and doors). It says which of those a check sees and which are by eye only. The zone
  skills' generator METHOD is not carried over: hand placement only. Nothing in the map changed with this.
- 19 Nov ~06:40 (PC session): BANKS EASED AND BLOCK EDGES FITTED, CITY WIDE (Yasin, on the picture of a block in a
  notch of the hillside: "lower the land in the places that go above the blocks like in the last pic you sent"; "and
  make sure all land is under blocks but blocks dont float too"; "roll it city wide and measure again"). ONLY THE
  LAND AGAIN: no piece, layout row, lock entry or room (lock.py status 599 LOCKED ok). Two more steps in
  `lower_land_to_pieces.py`, both dry-run by default: `--fit` raises every node a growth cell rests on back up toward
  the piece ground right at the node, never past what every piece cell it carries allows (roads included): 30,476
  nodes raised, usual 0.11 m; `--ease-from=<the 18 Nov grid>` moves the EMPTY land between the pieces by a harmonic
  field that equals the change on the piece nodes (0 at roads, samples, sea): 8,061 nodes lowered (usual 0.09 m,
  largest 3.21 m), 6,515 raised (usual 0.05 m, largest 1.62 m). No node a road or a sample alone rests on moved.
  MEASURED AGAIN (`ground_check.py`, whole city; 18 Nov land -> first lowering -> now): piece ground under the land
  311,101 -> 308 -> 308 m2 (f_sw, not touched); FLOATING block edges beside empty land (more than 30 cm over it)
  784 -> 880 -> 187 m2 (growth 138, the approved samples r_n / r_s and others 49: not touched); road kit 0 / 0.
  Banks from a piece node up to the empty land beside it: over 1 m 58 -> 3, over 2 m 27 -> 0, largest 3.91 -> 1.18 m.
  Island lowest -0.99 m, highest 14.10 m. Pictures `review/land_19nov/land_3steps_*.jpg` (three stages).
  STILL NOT MENDED: the jumps where two residential blocks meet (3,123 m, the pieces' own); 138 m2 of growth edge
  still floats (worst r_q_250_m200_nw 30 m2: a lower terrace within the same 4 m of land grid); the 4 m land grid
  cannot follow a terrace edge closer than that. NOT CHECKED: the running game, the phone, buildings and props
  against their own ground.
  To redo from the 18 Nov land:  git show bac444bc:map_dc/coronado/city_kit/zoning/terrain_grid.npz >
  OUT/terrain_grid_before_lowering.npz; ground dump in parts; `lower_land_to_pieces.py OUT/ground --fit
  --ease-from=OUT/terrain_grid_before_lowering.npz --write`; `bake_game_terrain.py`.
- 19 Nov ~06:00 (PC session): THE LAND IS LOWERED TO THE GROWTH BLOCKS, MAP WIDE (Yasin, after a one-block and an
  eight-block test with before / after pictures: "go to repo apply the fix map wide"). ONLY THE LAND CHANGED: no
  piece, no layout row, no lock entry, no room (lock.py status: 599 LOCKED ok, as before; git shows two changed data
  files). New tool `tools/city/pilot/zoning/lower_land_to_pieces.py` (dry run by default, `--write` to apply): where
  the land is not 5 cm under a GROWTH piece's lowest ground it lowers only the 4 m land nodes those cells rest on;
  never raises, never touches a sea node, does not re-solve the island. Then `bake_game_terrain.py`.
  NUMBERS (`tools/city/audit/ground_check.py` on a fresh ground dump, before -> after): piece ground under the land
  311,101 -> 308 m2 (more than 30 cm under: 187,944 -> 205; more than 1 m: 58,626 -> 59). The 308 m2 left is the
  approved beach block f_sw: NOT touched (its ground reaches under the sea level; Yasin's call). Road kit: 0 before,
  0 after. Land grid: 34,567 of 378,338 land nodes lowered (9.1 %), usual 0.27 m, largest 3.68 m, none raised;
  island lowest -0.99 m as before, highest 14.11 -> 14.10 m. Game land (data_citykit/height.f32z): 1.34 % of the
  samples lowered, none raised; every other data_citykit file byte-identical.
  WHAT IT DOES NOT MEND (unchanged, the pieces' own): residential blocks meeting mid-block at different heights,
  3,123 m of 5,072 m of shared edge jump more than 20 cm (usual 0.66 m, largest 2.86 m): they need retaining walls
  or a piece fix; 6-12 % of the residential edge against the streets steps about 0.27 m. NEW, from the lowering:
  banks where lowered land meets untouched land: 600 spots over 0.5 m, 153 over 1 m (55 of those beside empty
  land, largest 3.91 m at grid 148, 100: picture land_bank_b); "hanging" block edges 784 -> 880 m2.
  Pictures (preview tool, real pieces, only the pieces of each area loaded): `review/land_19nov/`.
  NOT DONE / NOT CHECKED: the running game and the phone; buildings and props against their own block's ground;
  `zoning/terrain.png` (the hillshade picture) and `zoning/piece_ground.npz` are still from 18 Nov 16:00.
  TRAP: `tools/city/run/terrain.sh` / `terrain.py` re-solve the whole island from `piece_ground.npz`, which does
  not have the growth blocks: running them now would bury the growth again. `ground_check.py` is still not in
  `checks.sh`. The whole-city `ground_dump.gd` run dies on the PC (2 GB card) after ~250 pieces and leaves cut-short
  files: dump in parts (rows 0-70, 70-140, ...) and join them.
  YASIN TODAY, HIS RULES AGAIN (read YASIN_MESSAGES.md, 19 Nov): no generators, hand-place; a fix for one thing he
  saw must change that one thing, never rebuild a zone; "all pass" reports from checks that do not measure the
  thing are false reports. Ask before acting: "i didnt tell you to do anything yet".
- 19 Nov ~04:15 (PC session): THE GROUND IS NOT CHECKED, AND PART OF THE GROWTH IS SUNK (Yasin, on the bird's-eye view:
  "Many areas are sunk in too... I think these validators and checkers don't do what they are supposed to do"). He is
  right. MEASURED with two new tools (`tools/city/audit/ground_dump.gd` + `ground_check.py`, 1 m grid, every piece's
  ground against the terrain and against its neighbours; picture `review/top_19nov/city_ground_check.jpg`: red = more
  than 30 cm under the land, orange 5-30 cm, yellow = a jump between two pieces):
  RESIDENTIAL GROWTH (43 quadrants): 30 % of its ground (114,592 m2) lies more than 30 cm under the terrain, 38,800 m2
  more than 1 m, deepest 3.5 m; 58 % of the edges where two quadrants meet mid-block JUMP (1,879 m of 3,248 m, usual
  0.63 m, up to 2.86 m); against the streets 6-10 % of the edge jumps (usual 0.3 m, up to 0.85 m). GRITTY growth:
  5,773 m2 more than 30 cm under (deepest 0.83 m). INDUSTRIAL growth: 14,480 m2 5-30 cm under, none deeper. STRIP: clean.
  Road kit: clean against the terrain. Locked samples: 205 m2 at the beach block f_sw, 57 m of jumps to their streets.
  WHY NO CHECK SAW IT: `sink_check.gd` only compares PROPS with their own piece's ground, and only in street pieces
  (j_ / s_): a block is never looked at. The validator checks props, doors and building overlaps, not heights.
  `terrain_check.gd` (piece against terrain) exists but is not in `checks.sh` and has not been run since 17 Nov; the
  terrain itself was last fitted on 18 Nov 16:00, BEFORE the growth (the pipeline says: rerun whenever pieces are
  added). Nothing compares a piece with its NEIGHBOUR. So "validator 0, sink 0" from the zone sessions said nothing
  about this, and the PC session passed those lines on without saying so. Part of the red is the terrain not being
  refitted (a refit lowers the land to the pieces); the jumps between pieces are the pieces' own and a refit cannot
  mend them. NOT measured: buildings against their own ground. NOTHING changed, nothing told to the zone sessions
  (Yasin: "do nothing for now").
- 19 Nov ~04:00 (PC session): TREES-OUT SWITCH IN THE BAKE + BIRD'S-EYE VIEW (Yasin: "yes add it. then show me a
  birdseye view of the entire city"; "can that same bake fill every tree well once they are gone too? with the same
  material as around the well"). `bake_runtime.gd --notrees` (OFF by default; docs/RUNTIME_BAKE.md "Trees out"): all
  4,432 builder trees and palms and their trunk colliders left out, the 215 tree wells paved level in their rim's
  material (collision lifted too), a well under a hand-placed `t_*` tree stays open. No piece touched. Bake 399 ->
  266 MB, draw nodes 7,186 -> 6,336. NOT on the phone, walking over a filled well not tried. New tool
  `tools/city/bake/rt_top.gd`; pictures `review/top_19nov/` (whole city as built / without trees, an Amber close-up).
  WHAT THE BIRD'S-EYE VIEW SHOWS: about a quarter of the land inside the ring road is built (the 8 samples + the four
  zones' growth); the rest is roads with empty blocks. The hand-placed tree pieces are NOT started (the four open
  questions of docs/TREE_PLAN.md are now three).
- 19 Nov ~03:00 (PC session): TWO PROPOSALS WRITTEN, NOTHING IN THE MAP CHANGED, WAITING FOR YASIN.
  (1) `docs/BUDGET.md` (Yasin: "we are gonna shoot way above budget once the cars and these areas land ... scripts
  arent even in yet"; "yes go ahead"): each system's share of the 150 draws (city 100, rooms 12, cars 15, people 15,
  sky 4, HUD 4), of the main thread (11 ms used, 5.7 spare) and of the GPU, the memory cap (1.2 GB proposed), and the
  whole-game gate. The city alone is at 79-118 draws standing and up to 198 driving.
  (2) `docs/TREE_PLAN.md` (Yasin: "which areas having trees make sense and which dont"; "we can turn off the trees
  entirely from the current builders and place your hand placed trees instead"): counted with the new
  `tools/city/audit/tree_census.gd`: 2,411 trees, 2,021 palms, 3,101 other plants; 72 % of trees and palms are STREET
  trees in locked road pieces, the four zone builders hold 22 %. Plan: one switch in the runtime bake leaves every
  builder tree out (no piece touched, locks intact), hand-placed `t_<area>` pieces replace them (about 3,050 from
  4,432; broadleaf 2,411 -> about 1,400), with an in-view cap. Four open questions at its end (empty wells, when,
  order, hedges).
  ALSO (Yasin, 19 Nov, on the zone sessions fixing by generator: every fix rewrote ALL of a zone's rooms or blocks):
  "damage is done... we need to let them build all, lock all, then chck them one by one, lock and move onto the other
  one..."; then "do nothing for now". NOTHING was told to the extenders about it.
- 19 Nov: INDUSTRIAL ZONE LOCKED (Yasin: "lock them for now, rest will be handmade adjustments"): the 11 pieces
  (i_va_*, i_vb_*, i_vc_*, i_green_w951_n1400_se, the sample's overlay i_life_w800_n1400) in locked.json
  "pieces", and the 16 rooms (interiors/rooms/g_ind_*.scn) in "files". Lock test RESULT PASS. From now on a change is
  a hand-made adjustment on Yasin's word: lock.py unlock / unlockfile --by=Yasin, rebuild, check, relock.
- 19 Nov (cloud, `claude/grow-industrial`): THE WHOLE INDUSTRIAL ZONE IS BUILT, NOTHING LOCKED (Yasin: "roll out to your
  whole zone, then do a polish pass"). Four more pieces:
  - movers + storage and the brewery south of 3rd St, draped onto G Ave's slope
  - the freight station's empties depot and Alameda Green on the Alameda strips
  - a life overlay `i_life_w800_n1400` for the locked sample
  16 rooms (two new: movers' office, brewery taproom). Fixed from Yasin's pictures: services on doors and rollups,
  the sunk shop on the slope, the stray benches, the shadow-like patches. Zone checks: validator 0, trees 0, sink 0,
  rooms 0, lock PASS. The LOCKED sample still has the shadow-like patches (and maybe services by its doors): needs
  Yasin's word. List: review/grow_ind/README.md. Baked numbers for the four new pieces not measured.
- 19 Nov ~01:30 (PC session, after a context compaction; Yasin: "read all the rules performance budgets and my words
  from the chat"): everything pushed is MERGED again into `claude/festive-faraday-20ltx2` (df0c2dc): the whole
  residential zone (19 new quadrants, 5 rooms), gritty (4 more blocks, rooms rebuilt with boxes recorded), strip
  (blocks against check_life), industrial (the rest of the zone), and the streaming session's collision work.
  Layout regenerated: 526 rows. Lock test RESULT PASS. Combined indoor checker on all 236 rooms: 319 problems, ALL in
  the 150 older generated rooms (g_a/b/c/f/g/i/m/r/v, the strip session's `tools/city/rooms/room_gen.gd`); the four
  zone sessions' own 74 rooms: 0; 24 notes in the 12 locked rooms (Yasin's call). 42 rooms record their boxes now
  ('unheld' tested there: 0). STREAMING: collision within 100 m first, the rest in quiet frames, is the DEFAULT, and
  BOTH phone gates PASS for the first time (`colbg_zones`, `colbg_stream`; RUNTIME_BAKE.md "Collision per place").
  NOT on the phone yet: this merged build with all the growth (waits for traffic / people in C++, Yasin's word).
- 19 Nov: RESIDENTIAL ZONE GROWN AND LOCKED (branch claude/grow-residential; Yasin: "roll out to your whole zone, then
  do a polish pass", then "skip them and lock it"). 65 quadrant pieces r_q_* (24 blocks: the west / Country Club Ridge,
  Crown Hill, Glorietta Heights) + wires w_rv, from four variants (rv_designs.gd: V1 village bungalows, V2 spanish hill,
  V3 beach cottages, V4 mid-century) built by rv_lib.gd; table review/grow_res_blocks.json (integrate.py grow_rows),
  zone list tools/city/pilot/zoning/res_zone.py, scripts by res_grow.py. Ground fitted to the four streets of each
  block as BUILT (leg profiles + property lines measured: zoning/legs_measured.json, leg_measure.gd); lots on level
  terraces with retaining walls. Five corner shops with hand-made rooms (interiors/rooms/rooms_res.gd, g_res_books /
  cafe / surf / wash / market; table interiors/assignment_res.json). LOCKED by Yasin's word: the 66 pieces and the 5
  rooms (lock test RESULT PASS). DEFECT, found by Yasin's top views after the lock: 45 of the 65 quadrants lie UNDER
  the approved terrain (up to 2.85 m, most of each quadrant covered): their ground was fitted to the four streets only,
  never to the terrain's hills inside the blocks, and no check compared the two (check_life 0 and seams 0 only cover
  piece against piece). Yasin: "leave it alone" (the part will be remade). Do not trust this zone's check results.
  New checkers from Yasin's corrections: tools/city/pilot/check_life.gd (pole on asphalt, item in a path, fence end
  that leads nowhere, wall item over glass), check_rooms "cover" (merged into the combined checker); room_lib records
  "openings". NOT DONE: the 12 ring-road residential blocks (curved / irregular), the bake numbers for the zone (draws,
  triangles, download size), KIT_USAGE lines. Known: com_shallow_books / _cafe have house doors (O_apt_door) that the
  shared cut does not open (their glass shop door hides behind the painted door) - shared-tools fix, passed to the PC.
- 19 Nov (cloud, `claude/grow-industrial`): the combined indoor checker (8e42e9a) is merged here, and the 14 industrial
  rooms are rebuilt to fit it. `check_rooms.gd -- --only=g_ind_` gives 0 problems (it was 20: repeat, lone, deco,
  window). room_gen_ind.gd now caps repeats with the checker's limits, puts bins only at walls, allows 2 boards a wall
  and 5 a room, and hangs no board over a window at any height. The rooms now record their openings.
  Hello's question about the ck_grt_row2 band (Yasin's picture): the reddish band across that door was room_lib's
  storefront BULKHEAD (room_lib.gd ~184, Tiles101 tinted 0.62/0.30/0.26), so it was in the ROOM file, not the
  building mesh. It showed up in my two rooms in that model, which were moved to ck/mod_fastfood and
  ck/ck_svc_pawn_fast. If the gritty rooms in ck_grt_row2 show no band today, they were built with a different bay
  or window set. Not tested from gen_shots' cut.
  Still open: the outdoor checks from Yasin's corrections in validate.gd (a building reaching into the street, props
  inside a building's real outline, a wider clear zone at shop doors).
- 19 Nov (cloud, branch `claude/grow-strip`): COMMERCIAL STRIP GROWTH, stage 1 + 2 done, LOCKED (Yasin 19 Nov: "lock your parts if you
  are done with them": six m_gr_* pieces + 26 g_strip_* rooms; lock test PASS). Read `review/grow_strip/README.md`. Six blocks round the strip sample (`m_gr_*`, table
  `review/grow_strip_blocks.json`): A car care corner, B used-car lot at the bridge mouth, C neighbourhood centre by
  the houses, D hospital side (urgent care, visitor parking), E motel + 24-hour gym, F boat / RV storage. 26 shop rooms
  (`interiors/assignment_strip.json`, `tools/city/rooms/room_gen_strip.gd`). Ground `zoning/strip_grow_ground.py`
  (edges take the walk's measured height, shared seams solved once, skirts, no T-joint cracks); wear only on paving.
  Checks: validator 0, check_life 0, trees 0, sink 0, rooms 0, lock PASS. Baked: 44-70 draws a view, 443-822k tris
  (over 500k in 9 of 12 views: said in the README), +11.7 MB download. Yasin 19 Nov: the 150 older generated rooms
  (319 indoor-checker problems, the PC session's request) are NOT this session's job ("Don't do those 150").
- 18 Nov (strip session, claude/grow-strip): NEW INDOOR PROPS (Yasin, relayed by the PC session: "there are new indoor
  assets to replace old lower quality ones ... fetch them and replace all indoor props with them"; asked directly in
  this session whether the 12 locked hand-made rooms may be unlocked and relocked for it: "Yes, unlock and relock").
  Taken: coronado-source `assets` dd8d53a, only its 178 indoor files (models, page I atlas, manifests, previews,
  tools, report); .import / .uid of this repo kept. Rebuilt with them: the 18 strip rooms (g_strip_*), the 150
  generated rooms of the existing map (tools/city/rooms/room_gen.gd, unchanged), the 12 hand-made rooms (unlocked
  --by=Yasin, rebuilt from rooms_civic_apt.gd / rooms_waterfront.gd unchanged, none needed re-dressing, relocked).
  Lock test RESULT PASS. Indoor checker: 1 problem left in a generated room of the sample (g_m_nw__crown_plaza__2,
  a grocery shelf grew and cannot be walked up to).
- 19 Nov (PC session, branch `claude/strange-jang-5426ac`, not merged): TRAFFIC AND PEOPLE IN C++ (Yasin: "bring the
  traffic and people here as completely cplus plus first, then we run the extensions on the phone"; "all of them must
  fit into the new map flawlessly, improve the code whereevr you can ... everything must be in C PLUS PLUS").
  STAGE 0 DONE: the inventory and plan, `docs/TRAFFIC_PEOPLE_PORT.md` (read it first). The old game's two plain C++
  cores come over; its script layer (which still runs every tick) does not: it is written new in C++ for this map
  (own threads, cars as batches, a spawn ring that moves with speed, one walker system). The new map must get its own
  lane graph, pavements, crossings and signal plan, made by a C++ tool from the locked skeleton and checked against
  the baked ground. The module's binaries and its `.gdextension` file stay OUT of git (built by `native/build.sh`), so
  cloud sessions never load it. YASIN ANSWERED the talking question (19 Nov): "does your work include every single
  one of npc related systems right? npcs meeting, ractions, city life, speaking to them etc": ALL of it is in the
  job, in C++ (reactions and city life = stage 3c, speaking = stage 4; the voice clips that name OLD places need new
  recordings once the new map's place names are fixed). STAGE 1 DONE, PC and PHONE: `native/` builds the Windows dll
  and the Android .so in under a minute (`bash native/build.sh`; `phone_rig.sh export` runs it), the rig prints
  `RIG native coronado_city ...` on both; phone run `review/phone/native1_stream.txt`: STREAM HEALTH PASS, engine
  `coronado_all7`; lock test RESULT PASS. Baseline for what comes next (same run): draws 79-82 average, 198 worst,
  GPU 13.5 ms. PARKED CARS ARE IN (Yasin 19 Nov: "tell it to bring parked cars to the game", "i think the traffic code
  needs to know about the parked cars locations right?"): doc section 14. The bake carries 4,524 stalls (3,008 at
  the kerb, 1,516 in car parks); parked and moving cars are one pool; driveways are NOT recorded by the pieces, so
  only kerb stalls take part in traffic until they are (a note, nothing changed). STAGE 2a DONE (19 Nov 01:45): the streets tool
  `tools/city/traffic/make_streets.gd` (C++ `StreetGraph`) -> `city_kit/traffic/streets.bin`, report and pictures in
  `review/traffic/`; run it after every bake. 449 lanes (75.3 km), 974 junction paths, 61 km of pavement lines, 276
  crossings, 3,010 kerb stalls: 0 lane points off the asphalt, 0 junction paths touching a kerb (checked as wide as a
  car). FOUND IN THE MAP: a 54 m hole in 1st St (ferry landing), no ground under the four pavement corners of the
  centre junction (Amber x 7th). Doc section 15. STAGE 2b DONE (19 Nov 03:40): the old traffic core drives on the
  new streets (`native/src/traffic_*`, class `CityTraffic`). `tests/traffic/test_traffic_core.gd` RESULT PASS: nine
  30-minute runs, no overlap, no crash, nobody stuck at the busiest hour with the stuck-car rule off, the same
  result every time; a step for 190 cars 0.32 ms on the PC. The streets now have 761 lanes, 60 left-turn lanes found
  from the paint, lanes that change where the street narrows. What had to change in the old core: doc section 16.
  STAGE 2c DONE ON THE PC (19 Nov, doc section 17): the traffic is DRAWN in the test app: `--traffic=N --parked=1|0
  --density=x`. Cars are rows of a few batches (near model for the 4 nearest, light model to 85 m, one 60-triangle
  shape beyond), parked cars on the cells' stalls with the LOW models only (the same street every time), lamp glows,
  a pool of 24 collision boxes, cars come and go with the streamed cells, the ring runs ahead with the speed (24 cars
  round the camera at 281 km/h). The signal lamps run on the traffic's clock (two lines in `rt_prop.gdshaderinc`; a
  lattice fault that put 9 signal heads on a wrong clock is fixed by the streets tool, check = 0). Two real faults
  in the driving fixed (straight before left; a car on its line lets others through): the traffic test PASSES and
  nobody stands over 2 min even at twice the busiest hour. Pictures `review/traffic/pc/`. Lock test PASS. PC cost:
  0.1 ms a frame on the main thread, 5-6 draws. NOT YET: parked cars pulling out / in, wheels turning, indicators.
  RUN `tools/city/traffic/make_streets.gd` AFTER EVERY BAKE (streets.bin).
  STAGE 2d DONE (19 Nov, doc section 18): THE PHONE. Stream gate PASS with 20 and 40 cars (twice each on the final
  app; the very first run after an install had one 59 ms frame) and with "80" (the streets hold 57 at most). A
  street with traffic and parked cars costs about 12 draws, 125 k triangles, 0.26 ms of the main thread, under
  0.1 ms of GPU median; parked cars alone 5 draws, 85 k triangles. PARKED CARS PULL OUT AND MOVING CARS PARK
  (`native/src/traffic_parking.h`; test: no moving car ever touches a parked one). The zones plan fails on this branch
  with AND without traffic (a collision body waits 5 s at one night teleport: the streamer, not the traffic).
  STAGE 3a STARTED: the old crowd core walks the new pavements (`native/src/crowd_sim.*`, `city_crowd.*`,
  `tests/crowd/test_crowd_core.gd`): routes, signals and queues work, nobody leaves a pavement in 4 of 6 places;
  NOT PASSING YET (people still stand inside each other on the narrow pavements), nothing drawn yet.
- 18 Nov (cloud, branch `claude/grow-industrial`): INDUSTRIAL GROWTH, stage 1 + 2 done, NOTHING LOCKED, WAITING for
  Yasin's word on the variants. Read `review/grow_ind/README.md`. Three variants (A port, B fleet, C cold chain),
  each dressed twice = six 100 m blocks round the sample. They form the pilot area u -900..-500, v -1600..-1400
  (1st St to 3rd St, J Ave to the house edge). Table `review/grow_ind_blocks.json` (the shared grow_* form).
  `pieces/ind_grow_lib.gd` MEASURES the road pieces, so every block meets the walk flush and its gates sit on the
  street's aprons. 14 rooms with an industrial character: `tools/city/rooms/room_gen_ind.gd` + `assign_ind.py`
  (stocked shelves only). Checks in the area: validator 0, trees 0, sink 0, rooms 0, lock PASS. Baked: worst view
  78 draws / 387k tris; +5.8 MB download; rooms not in the bake (21-36 draws, 4-6 lights each, unmerged). Not done:
  the two sloped blocks south of 3rd St at G Ave, the Alameda strip, pictures in the GTA IV look (they need a full
  bake on the PC), the phone.
- 19 Nov (PC session, after the census): EVERYTHING PUSHED IS MERGED into `claude/festive-faraday-20ltx2` (Yasin: "merge
  them yes i saw their works"; "dont leave anything unmerged"): the look pack (he chose "gta4 look"), the tier work
  and the DRAWING CENSUS (`docs/DRAW_CENSUS.md`, `docs/TREE_ARTIST_BRIEF.md`), and the four zone sessions' first work
  (gritty 8 blocks, industrial 6, residential 25, strip 3: unlocked, waiting for his approval). `OUT/sweep.sh` (local)
  merges every pushed branch; `city_grid_layout.json` is regenerated after such a merge with
  `python tools/city/pilot/zoning/integrate.py` (needs numpy + shapely; it reads `review/grow_*_blocks.json`).
  Yasin: "i like the new terrain" (the far ground / roads in the far world). The rig now draws the night once in the
  warm-up by default (the census found it removes the first-dusk frames). CENSUS IN ONE LINE: at 720p the phone
  lowers its GPU clock, so "13-14 ms of GPU" there is NOT a limit; with the GPU kept busy (1.5 x full screen) the
  costs are trees 11 / 3 ms (apartments / gritty), near buildings 7 / 3, sun shadows 5 / 3, sky reflection 5 / 3,
  FXAA 4 / 4, near props 3 / 1, wear marks 2 / 2; the mid tier and the look's building parts cost almost nothing.
  NOT on the phone yet: the merged build with the grown blocks.
- 19 Nov ~01:00 (PC time): COLLISION PER PLACE (the growth doubled the gritty edge's collision; teleport 3.6 s). Branch
  `claude/ecstatic-archimedes-922d2c`, docs/RUNTIME_BAKE.md "Collision per place". ON: a teleport's destination's
  collision first, and 4 x the collision budget while a teleport prepares: teleports 0.1-1.3 s, stream gate PASS; zones
  gate failed on one body (3.2 s, gritty night). Then (Yasin: "keep digging") collision within 100 m first and the
  rest in quiet frames (the first try left far collision unmade and gave a draw stall of 86-414 ms per lap while the
  growth's heavy cell loaded: cured by the background work, cause not understood). NOW BOTH GATES PASS (`colbg_zones`,
  the first zones PASS; `colbg_stream`): teleports 0.2-1.6 s, collision waits under 0.6 s, worst frame 39 ms.
- 19 Nov ~00:30 (PC time): DRAWING CENSUS ON THE PHONE (Yasin: "queue the drawing cost census"), branch
  `claude/ecstatic-archimedes-922d2c`, not merged. Full account: docs/DRAW_CENSUS.md. Rig `--plan=census` (states one at
  a time, standing viewpoints, day / night, `--warmnight`). KEY FINDING: at 720p the phone lowers its GPU clock, so GPU
  time there does not show costs (half the pixels saved 0.0-0.3 ms); the census was read at 1.5 x full screen. Biggest
  costs (apartments / gritty): plants 10.9 / 3.4 ms (cut-out leaves 4.0 / 2.8 of it), near buildings 7.0 / 3.3, sun
  shadows 4.9 / 3.4, sky reflection 5.1 / 3.2, FXAA 3.9 / 3.6, near props 2.6 / 1.3, wear marks 1.9 / 1.9. Cheap: mid
  tiers, far world, far ground, the look's parts (0.6 together). The first dusk of a session (40-120 ms frames) is
  first-time building, gone with `--warmnight`: NOW THE RIG'S DEFAULT (Yasin: "Yes, add it"; night drives with no
  frame over 33 ms). Zones gate still fails, newly: the growth doubled the gritty edge's collision, teleport 3.6 s. Switching
  the sky reflection back on left the GPU ~28 ms slower until a teleport (not explained). NEW: docs/TREE_ARTIST_BRIEF.md
  (Yasin: new tree models; what they must be). Stream gate on the merged build (look + tiers code + growth): PASS.
  Release build not made (Yasin: "dont make the release build yet"). Lock test RESULT PASS.
- 18 Nov (cloud session, branch `claude/grow-gritty`): GRITTY EDGE GROWTH, Stage 1 + 2 done, WAITING FOR YASIN (nothing
  locked, nothing merged by me). Read `review/grow_grt/README.md`. Three variants of the locked gritty sample (v1 yard edge,
  v2 trade street, v3 walk-up homes; recipes `tools/city/pilot/pieces/grt_grow_recipes.gd`, site frame + slope drape
  `grt_grow_lib.gd`) filling the PILOT AREA u -800..-500, v -1300..-900 between the industrial and the gritty samples:
  8 block pieces `g_v1_j4ne g_v2_g4nw g_v1_g4ne g_v2_j4se g_v3_g4sw g_v3_g4se g_v2_j5ne g_v3_j5se` (table
  `review/grow_grt_blocks.json`, rows picked up by `integrate.py`'s new `grow_rows()`; city_grid_layout regenerated). 25 shop
  rooms (Yasin: "do out and indoors together"): `interiors/assignment_grt.json`, `tools/city/rooms/room_gen_grt.gd` (copy),
  `gen_shots_grt.gd`. Yasin's fix in the same round: "many on the wall props overlap, some of them are on windows, some of
  them are inside the ceiling" -> one fit check for every hung item indoors; outdoors wall props slide off windows / doors.
  Checks: validator 0, trees 0, sink 0, rooms 0, lock test RESULT PASS. Numbers in the README (GRT_NUMBERS).
  19 Nov: GRITTY ZONE LOCKED (Yasin: "lock them for now. rest is piece by piece correction"): the 12 block pieces
  g_v1_* / g_v2_* / g_v3_* and the 37 room files interiors/rooms/g_grt_*.scn in locked.json; lock test RESULT PASS
  (413 pieces, 56 files). Further changes piece by piece, each with Yasin's word (lock.py unlock / unlockfile).
  19 Nov later: WHOLE GRITTY ZONE FILLED (Yasin: "roll out to your whole zone, then do a polish pass"): 12 blocks (+4
  between J Ave and the ring: g_v1_j4nw g_v2_j4sw g_v3_j5nw g_v3_j5sw), 37 rooms; polish pass 2; checks 0/0/0/0, lock PASS.
  See review/grow_grt/README.md. Still WAITING for Yasin's word on the variants; nothing locked.
  19 Nov: counter cages REMOVED from every gritty room (Yasin: "remove all of the cages, they arent prison cells").
  Combined indoor checker (working branch 8e42e9a) on the gritty rooms: 19 -> 0 (deco: at most 2 decorations a wall,
  6 a room; repeat: at most 2 leaflet racks / spinners, 1 vending; lone: no bin at the counter end).
  GYM ("what floats", answer to the PC session): a checker that knows only props cannot see it; the floating thing in
  the gritty rooms was the room's OWN build (a box of bars). Rule to add for the room's own boxes (room_lib.box and
  the fittings): every built part must be HELD - its bottom on the floor (within 2 cm) or on a prop's top, or one face
  against a wall / partition (within 3 cm), or its top at the ceiling (within 3 cm); anything else floats. A grille
  or rail must be held at BOTH ends. Needs room_lib to record its boxes (meta "boxes": [centre, size, key]).
  OPEN QUESTIONS FOR YASIN: (1) approve / change the three variants before any wider growth; (2) the same "wall props on
  windows" fault is very likely in the LOCKED samples too (shared dress helper): fix needs his word to unlock;
  (3) the modular map rows (`@map:brk3_row3`, `shop_row4`, `svb_row*`, `stg_row*`) would suit the next gritty round: merge them?
  NOTE for the PC / strip session (cloud could not message the PC): new indoor kit dd8d53a is on this branch (546f76f, file
  for file the same as `claude/kit-indoor-props` 9fce731); after it the indoor checker reports 12 problems, ALL in the old
  rooms (generated / hand-made), none in the gritty rooms. Polish pass done (Yasin: "run a polish pass ... lots of props").
- 18 Nov ~21:50 (PC time): YASIN DECIDED THE DAY LOOK: "i go for gta4 look" (the sky session's current default palette
  stays; the half-haze and clear-day variants are not needed). He also asked whether merging must wait for the census
  ("do we have to wait for the cencus?"): no. MERGED into the working branch: the tier session's branch
  `claude/ecstatic-archimedes-922d2c` as of bd74fd0 (far ground ON, tiers built and OFF). Still NOT merged:
  `claude/look-sky`, `claude/look-buildings`, the four `claude/grow-*` branches. FOUR ZONE SESSIONS started in the
  cloud (Yasin: "start 4 of them, since we have 4 different zones"; "tell them to do out and indoors together. thats
  the point of having 4 different agents, i want the shops to look different"; "fetch the tool and give it to them"):
  residential, commercial strip, industrial, gritty edge, each on `claude/grow-<zone>`, variants + one pilot area +
  their own shop rooms with the room tool (`tools/city/rooms/`, copied here from `claude/look-buildings`, 3203b2d).
  Nothing of theirs is locked; they wait for Yasin's approval. The tier session is now running a DRAWING-COST CENSUS
  on the phone (brief: where the 13-14 ms of GPU at 720p go, one switch at a time; result `docs/DRAW_CENSUS.md` on
  its branch).
- 18 Nov ~22:30 (PC time): THE TIERS (Yasin: "it snaps from near to far directly"), branch
  `claude/ecstatic-archimedes-922d2c`, not merged. Full account: docs/RUNTIME_BAKE.md "The tiers". (1) FAR GROUND, ON:
  the streets and ground of all 100 cells that have ground in the far world, 1 draw, 20k triangles, one 1.3 MB
  picture, no GPU cost measured. (2) An arriving cell's objects take over nearest first and (3) dithered fades at
  60 m / 220 m: built, behind ONE switch (`--tiers`, streamer `tiers`), OFF. On the Redmi they cost 0.1-0.4 ms of GPU
  in most zones and 4 ms (40 %) in the gritty edge. Gate: `tiers_off_stream` and `tiers_on_stream` PASS. The zones
  fail only on the known day-to-night frame (as `zones_final`; the same without the far ground). Also fixed: a
  start load attaches its collision at once (it trickled in, one body 9.9 s late). NEW: rig `--plan=shots`,
  `phone_rig.sh shots NAME`, `gpu_ms` on the map line; pictures `review/tiers/before|after_farground|after_tiers`.
  WAITING FOR YASIN: look at the pictures and at `--tiers` on the phone; fades for buildings only (cheaper) is the
  next thing to try. Lock test RESULT PASS.
- 18 Nov ~20:50 (PC time): WHILE THE TIER SESSION WORKS (Yasin: "do 1 and 2 together"). (1) LOOK PACK ON A REAL GRAPHICS
  CARD: `claude/look-sky` + `claude/look-buildings` merged onto the working branch in a scratch worktree
  (`OUT/look_wt`, branch `claude/look-merge-test`, local only, NOT merged anywhere): collisions only in rig.gd's
  option dictionary / list, the job board and one .uid. Pictures on the PC's NVIDIA card in
  `OUT/look_wt/OUT/look_pc/` (pair_*.jpg, times_*.jpg), shown to Yasin. My read, told to him: night, dusk and
  overcast clearly better; day is a flat beige sky, trees lose their purple, murky; golden hour brown. The sky session
  got a third queue from that (three day variants for Yasin to choose, visible clouds, a golden golden hour, numbers
  for "murky", the 50 m shadow end, a hand-over page for the game). WAITING for Yasin's word on the day palette.
  (2) SOAK of the new streamer on the PC, 48 drives / 25 minutes: no leak, nothing piling up (RUNTIME_BAKE.md
  "SOAK"). A start-area bug from the collision change was found by the sky session and fixed (e31d850): the
  evening's phone runs were taken before it; the tier session was told to take a fresh baseline. Tier session:
  "Streaming: tier fades and far roads", an Opus session on this PC in its own worktree, branch
  `claude/ecstatic-archimedes-922d2c`; it has the phone.
- 18 Nov ~22:30 (PC time): THE TIERS (Yasin: "it snaps from near to far directly"), branch
  `claude/ecstatic-archimedes-922d2c`, not merged. Full account: docs/RUNTIME_BAKE.md "The tiers". (1) FAR GROUND, ON:
  the streets and ground of all 100 cells that have ground in the far world, 1 draw, 20k triangles, one 1.3 MB
  picture, no GPU cost measured. (2) An arriving cell's objects take over nearest first and (3) dithered fades at
  60 m / 220 m: built, behind ONE switch (`--tiers`, streamer `tiers`), OFF. On the Redmi they cost 0.1-0.4 ms of GPU
  in most zones and 4 ms (40 %) in the gritty edge. Gate: `tiers_off_stream` and `tiers_on_stream` PASS. The zones
  fail only on the known day-to-night frame (as `zones_final`; the same without the far ground). Also fixed: a
  start load attaches its collision at once (it trickled in, one body 9.9 s late). NEW: rig `--plan=shots`,
  `phone_rig.sh shots NAME`, `gpu_ms` on the map line; pictures `review/tiers/before|after_farground|after_tiers`.
  WAITING FOR YASIN: look at the pictures and at `--tiers` on the phone; fades for buildings only (cheaper) is the
  next thing to try. Lock test RESULT PASS.
- 18 Nov late (cloud session, branch `claude/look-sky`, NOT merged): LOOK QUEUES 2 AND 3 (from the PC session for
  Yasin). Read `docs/LOOK_OVERVIEW.md` (every switch), `docs/LOOK_FOR_THE_GAME.md` (how the game uses the look),
  `docs/LOOK_PHONE_TESTS.md` (the phone runs in order; the FIRST must be `phone_rig.sh all` from a checkout with this
  branch: the look's files are new). Queue 2: running day `--cycle=120`, sun / moon / stars `--celestial`, the sea
  `--sea` (from coast.json + terrain depths, meets the shore foam), weather `--weather=mist|hazy|storm|rain`, life in
  the air `--air` (off), car paint / glass reflect the look's sky (`--cars` demo). Queue 3 (a real GPU showed the day
  beige and murky): `tools/city/look/measure.py` (sky saturation halved: 21 % against 41 %), day variants
  `--look=day_half` / `day_clear` for YASIN TO PICK (default `day` unchanged; sheets `review/look_18nov/variants/`),
  golden and morning less brown, the sun shadow's end fades (2 blended splits, `--shadowtune`; also fixes the cloud's
  black trees). FOUND and fixed: sun east / west were swapped; streamer now-path without collision (fixed by the PC
  session). Lock test RESULT PASS.
- 18 Nov ~20:10 (PC time): STREAMING MADE HEALTHY ON THE PHONE (Yasin: "streaming is the backbone of this game, we
  need it to work healthy agile and robust ... think that you are the streaming engineer in rockstar studios"; "do
  whatever you need"). Full account: docs/RUNTIME_BAKE.md "The streamer on the phone". Six causes found and fixed one
  by one, each proven on the Redmi: (1) a 7,000-25,000 triangle collision body per cell -> pieces of 400; (2) threaded
  loading filled the engine's thread pool, which the physics step runs on -> the streamer's own loader threads;
  (3) 600 small collision files a cell -> the data in the cell's file (`tools/city/bake/col_data.gd`: collision is
  plain data, the streamer makes the bodies, by weight and by time a frame); (4) the first cell with a new kind of
  material -> warmed and held, bake check line; (5) the driver fetching graphics memory at the first streamed cells ->
  192 MB taken and given back in the warm-up; (6) too much body-making in one frame -> 2 ms a frame, shapes straight on
  the body. Loop at 108 / 210 / 281 km/h, frames over 33 / 50 / 100 ms: 36 / 12 / 1 -> 1 / 0 / 0, no cell late.
  Zones: 36 / 3 / 0 -> 6 / 1 / 0, teleports 1.0-5.5 s -> 0.6-2.7 s. NEW: `tools/city/rig/health.py` (the streaming
  budget, PASS / FAIL after every run), plan `--plan=stream`, `--probe`, `--nocol`, `--hide`, `--loader=`,
  `--coltris=`, `--colms=`, `--gpureserve=`; audit tools col_census.gd, cell_deps.gd, mat_census.gd. The bake now
  writes 141 cells (ground pieces go to the cell they lie in), manifest version 6. Lock test RESULT PASS (19:00).
  NOT DONE: tier fades and far roads (the visible pop, next streaming job); the 584 MB of graphics memory (probably
  the driver's block size: an engine-build matter); a release build; repeats. Cloud sessions were given queues of
  further look jobs (Yasin: "give them all the improvements lists and have them do them non stop"; "we already have
  real indoor windows, and id like to keep them, in the shops on water front": told the buildings session).
- 18 Nov evening (cloud session, branch `claude/look-sky`, NOT merged): THE LOOK QUEUE (from the PC session for Yasin:
  "give them all the improvements lists and have them do them non stop"). Read `docs/LOOK_OVERVIEW.md` (every look
  switch on both branches, cost, safe or not) and `docs/LOOK_SKY.md` "The look queue". 1 times of day `--look=morning|
  noon|day|golden|dusk|night|overcast` (`review/look_18nov/times/sheet_*`). 2 upscaler `--upscale=1 --sharp=0.2`
  (SGSR via the FSR 1 mode, patch c): a patched Linux engine built in the cloud, 18-30 % sharper (`upscale/crop_*`);
  phone test steps in LOOK_SKY.md. 3 lamp glow `--glow=1` (own shader, the bake's untouched; patch note). 4 blob
  shadows past 50 m `--blobs=1` (OFF: reads meshes at load; +5-8 draws; bake patch note). 5 sky map `ck_sky_map` +
  snippet `tools/city/look/sky_reflect.gdshaderinc` for glass / wet ground, `--wet=0..1` demo. 6 the overview.
  FOUND: `docs/look_patches/streamer_now.md`: `update_focus(p, true)` adds cells WITHOUT collision since the streamer
  rewrite (the rig's start uses it): one-line fix in the note. Shaders in `city_kit/shaders/` not edited (Yasin's
  brief: the building session's). Lock test RESULT PASS.
- 18 Nov (cloud session, branch `claude/look-sky`, NOT merged): LOOK PACK, SKY HALF (Yasin: "a visible jump"; mid-way:
  "we are going for a gta 4 like look"; "does the bloom cost that much?"). Read `docs/LOOK_SKY.md`. New
  `tools/city/look/` (sky shader + 256 px noise texture, look.gd: haze = distance fog in the sky's horizon colour,
  amber sun / grey-blue shade, Filmic + a 16^3 colour table: held-back colours, warm highlights, smoggy blacks; night:
  brown-orange smog glow, few stars). Rig: `--look=1|0` (default 1), `--bloom=0|1` (default 0: costs pixels, guessed
  1-2 ms, NOT measured), `--reflect=1|0`, `--shots=FOLDER`. Pictures: `review/look_18nov/sky/` (cloud: no shadows, no
  sky reflection - the software GPU draws near trees black with either on - and buildings ~40 % too dark).
  NEXT (PC session): `--plan=zones` with `--look=0`, `--look=1`, `--look=1 --bloom=1` on the Redmi, and the real
  pictures. Told Yasin the bloom answer: a blur chain + one read a pixel; the 720p runs sit at the 60 fps step.
  Same draws with and without the look; lock test RESULT PASS.
- 18 Nov (cloud, branch `claude/look-buildings`, NOT merged): THE PC QUEUE OF LOOK JOBS DONE (Yasin: "start and work
  non stop to clear your queue"). 1 fake rooms: dropped (real rooms instead, above). 2 props read their ORM map again
  (`ck_look_propmaps`; why they lost it, normal maps = bake patch). 3 close-up wall grain (`ck_look_detail`). 4 contact
  shadows between models, prototype (`ck_look_between`, pavement at building feet, walls under awnings). 5 far
  buildings' night windows (mask in the far atlas alpha, patch for rt_far). 6 shop signs glow at night, some flicker
  (`ck_look_signs`). 7 the summary table: top of `docs/LOOK_BUILDINGS.md`. Bake / rt_far parts in `docs/look_patches/`
  for the PC session. Lock test PASS. NOTHING measured on the phone. WAITING for Yasin / the PC session's phone run.
- 18 Nov (cloud, branch `claude/look-buildings`, NOT merged): ROOMS ON ALL SHOPS (Yasin: "we had fake windows, i didnt
  like them"; "ideally, id like to have those store signs, real windows and see thru doors of those shops all over the
  map"; "i want them on all shops"). The PC queue's job 1 (fake rooms behind glass) DROPPED. Every shop of the map has a
  shop (`interiors/assignment_all.json`, 161) and a room (150 generated by `tools/city/rooms/room_gen.gd` + the 12
  hand-made), indoor checker 0 problems, lock test PASS. Pictures `review/rooms_18nov/`. Room merge prototype: 26 -> 9
  draws a room. NOT in the streamed city: the bake part is `docs/look_patches/rooms_bake.md` (PC session). The PC
  queue's jobs 2-7 are paused. WAITING for Yasin: look at the rooms; which kinds want a hand pass; enterable or not.
- 18 Nov (cloud session, branch `claude/look-buildings`, NOT merged): LOOK PACK, BUILDINGS (Yasin: "we need a visible
  jump"; the sky / haze / colour half is another cloud session in rig.gd). Read `docs/LOOK_BUILDINGS.md`. Three changes
  in `shaders/rt/rt_bldg.gdshader`, each behind a global switch (`ck_look_contact`, `ck_look_windows`, `ck_look_glass`,
  0 off / 1 on, default on): the kit's own AO also dims sunlight + a thin line at the wall foot (no second AO: the kit
  has it, PC session's correction); night windows found per window, each its own colour / brightness; day glass reflects
  a sky gradient (`ck_look_sky_top` / `_horizon`). No texture read, no draw, no re-bake added. Pictures
  `review/look_18nov/buildings/` (cloud: ~40 % too dark, no shadows). Lock test PASS. NOT checked on the phone: look and
  cost (the PC session takes the real pictures). WAITING for Yasin: keep / tune / drop each.
  Ground bump maps (grass / gravel / paving normal maps in rt_ground): Yasin asked "is it gonna improve the looks
  significantly ... how major of a cost?", told him: small gain, one more texture read on those pixels, a bake change;
  Yasin: "ok skip it then". NOT to do.
- 18 Nov ~18:40 (PC time): LOOK PACK IN TWO CLOUD SESSIONS (Yasin: "do them on cloud sessions"): "Look pack: sky, haze
  and colour" -> branch `claude/look-sky` (rig.gd environment, tools/city/look/), "Look pack: building shader" ->
  `claude/look-buildings` (rt_bldg.gdshader, shader globals). Neither merges; the PC session takes the real phone
  pictures when they are pushed. AO CHECK (Yasin: "our assets were supposed to have ao already"): he is right. Kit
  SPEC.md 32, 45-46: AO baked into the base colour + ORM R channel; rt_bldg.gdshader uses it (`AO = orm.r`, cavity,
  wall-foot band), baked building materials have the ORM bound; rt_prop reads the props' ORM array too. What is NOT
  there: anything between models (building to pavement, under trees and cars), AO on direct sun (Godot's AO dims
  ambient light only), the mid tier (colour only), the ground (rt_ground uses no occlusion; ground_orm.png has one).
  The building-shader session was told to add only what is missing. My earlier list item "wall darkening" mostly
  exists already.
- 18 Nov ~18:10 (PC time): SETTING TESTS at 720p done (Yasin: "ok run the tests"; "make the games default resolution
  720p ... just inject it": rig default is now 720 lines, app not rebuilt, runs pass --scale=0.6667). Table in
  RUNTIME_BAKE.md "THE SETTING TESTS AT 720p". --loading=1 and --bodies=1 change nothing measurable (two identical
  baselines differ by as much); 0 / 1 / 20 lights cost the same (Yasin's light grid: confirmed); at 720p the phone
  holds the 60 fps step in every zone, 29-36 frames over 33 ms a run, no late cell. The hitches fall on frames that
  attach a collision body or take a cell in: physics thread or first draw, NOT told apart (needs a rig switch + a
  rebuild). YASIN WANTS A VISIBLE JUMP IN LOOK ("we need a visible jump"; asked about deferred lighting: told him no,
  it only pays with many lights and costs pixels; the light grid already covers lights). Gave him 14 look changes
  ranked by work (colour grade, sky + haze, upscaler, wall darkening, night windows, glass reflection, normal maps,
  blob shadows, detail texture, baked AO, tier fades + far roads, fake interiors, far shadows, life) and which fit an
  Opus session. PROPOSED two separate sessions (sky / haze / colour; building shader). WAITING for his pick.
- 18 Nov ~15:00: OLD GAME REVIEW (Yasin: "check old games systems one by one ... tell me which ones can be made faster
  and honestly tell me if you cant"): `docs/OLD_GAME_SYSTEMS_REVIEW.md` (read-only in coronado-source, nothing run).
  Clearly faster: cell packages, far areas, building streaming, walk-in rooms (waiting time), loading, road and sea
  shaders, parked cars drawn twice. Cannot improve: sky, simple shaders, HUD, physics, colliders, save, story, jobs.
  Also lists what breaks at 280 km/h. No work started from it.
- 18 Nov ~17:30 (PC time): FULL-RESOLUTION zones run (Yasin: "i need a test run at full res too"; "check the results
  of both runs and tell me what can be done"): `review/phone/zones_full.txt`, written up in RUNTIME_BAKE.md. The phone
  is pixel-limited: medians 16-25 ms by day and 31 ms in the night centre at 2460x1080 (half res: 9-16 / 16.4); 15
  frames over 50 ms, one of 181 ms with two cells loading; most hitches fall on frames that attach collision bodies
  or take a cell in. Yasin also saw the tiers snap ("snaps from near to far directly"): hard cuts, far -> mid per
  whole cell, no far roads (see RUNTIME_BAKE.md "THE TIERS"). TOLD Yasin the options (resolution + upscaler, the free
  setting tests --loading=1 / --bodies=1 / --lights=8 / --scale=0.75, tier fades + far ground, cells in parts,
  lighter centre / apartments, teleport behind a fade, the 0.9 GB memory). WAITING for his pick. Nothing started.
- 18 Nov ~17:15 (PC time): ZONES RUN on the Redmi (Yasin: "the test was mostly in empty ground ... make it
  teleport between gritty, city center, waterfront etc"; "can you inject this run to the apk instead of rebuilding").
  New plan `--plan=zones` in rig.gd (9 zones by day at 60 km/h, 7th St at 210, centre + gritty at night) and
  `--drive=NAME/ROUTE/KMH/SECONDS/NIGHT` (own drives, no rebuild). Result `review/phone/zones1.txt`, table in
  docs/RUNTIME_BAKE.md. 22,841 frames: 5 over 33 ms, 1 over 50 (93 ms, night centre, two cells loading at once), none
  late. Day zones clean (worst 36 ms). Teleport 2.0-3.9 s, frames stutter while it loads (up to 245 ms). Night zones
  at 60 fps or under. Memory 873 MB at 60 s (583 graphics): not understood. NEXT, if Yasin wants: the same run with
  `--loading=1`. WAITING for Yasin as below.
- 18 Nov ~17:00 (PC time): PHONE TEST DONE on the Redmi by the session on Yasin's PC (Yasin: "go ahead"). Result
  `review/phone/run1.txt`, full write-up in docs/RUNTIME_BAKE.md "The phone test". Clone is at C:\Users\yasin\NewMap.
  Numbers: by day median 8.6-10.1 ms (the 120 Hz cap), 99 % 19-27 ms; night centre median 16.8 ms; 18,681 frames,
  11 over 33 ms, 3 over 50 ms (64, 76, 59), none over 100; no cell late at 50-280 km/h; draws max 119 by day, 205 at
  night (budget 150); 607 MB. Engine `coronado_all7` (light grid present). Open question answered: a loading cell
  does hitch on the phone, rarely (2 frames of 59 / 76 ms in 215 s). WAITING for Yasin: cells in parts or not; the
  night centre over the draw budget. Script fixed for Windows (gradle daemon hang, template copy, git push path, git
  author); rig fixed (ground ray in the physics step: the first run had the camera sunk into the road, Yasin saw it,
  that run was discarded); `.gitattributes` added (a Windows clone failed the lock test on line endings). Lock test
  RESULT PASS. Not run yet: `--nowarm`, `--plan=speed`, `--loading=1`, a release build.
- 18 Nov ~14:00: HANDOVER TO A SESSION ON YASIN'S PC (Yasin: "i did both but nothing happens, can you handover the work
  to a local session on my pc?"). Read `docs/HANDOVER_PHONE_TEST.md`: the job is one clean run of
  `tools/city/rig/phone_rig.sh all run1` on the Redmi (the script has never run on Windows: debug it step by step),
  the result pushed to `review/phone/run1.txt`, and a plain report to Yasin.
  ~14:10: the brief was SENT to Yasin's session "Hello" running on the PC (Remote Control); it started working. The
  card's own session came up as a cloud session and cannot reach the phone: ignore it.
- 18 Nov ~13:30: STREAMING (Yasin: "go for it"; "try not to copy anything at all" from the old game; "i hope we can go
  for speeds like 280km"; no fast travel; "triangles are fine ... keep draw calls as low as possible"). Streamer
  rewritten (`tools/city/bake/city_stream.gd`, read docs/RUNTIME_BAKE.md "The streamer"), whole city baked locally (140
  cells; `runtime/` is not in git), cloud drives pass at 209 / 281 / 360 km/h with no cell late. Phone rig +
  `tools/city/rig/phone_rig.sh all run1` pushed for Yasin to run on the PC (Redmi on adb); the result lands in
  `review/phone/run1.txt` on the branch. WAITING for that run: fetch the branch and read it. First attempt on the PC
  said "no such directory" (no clone at /c/NewMap): told him to clone into ~ and run from ~/NewMap. Remote Control:
  his PC lists folders `project` and the Godot folder but refuses them to cloud sessions.
  Yasin asked if the repo is a good fresh start: told him honestly: foundation good, ORDER wrong (content before a
  phone-proven slice, nothing judged on real hardware, top speed / camera not decided). Next after the phone data:
  cells in parts if uploads hitch; then a playable slice (player, one car) on the phone.
- 18 Nov ~11:40: THE 4 THINGS (Yasin: "yes replace it and do the 4 things ... show me samples where its possible before
  a map wide roll out"; "triangles are fine ... keep draw calls as low as possible"; the engine's light grid gives 32
  live lights: "use that for the lights problem"). Read `docs/RUNTIME_BAKE.md`. DONE: plan picture replaced; kit atlases
  compressed + mipmaps (whole kit, 143 -> 38 MB); runtime bake tool `tools/city/bake/` + shaders `city_kit/shaders/rt/`
  (far world, texture arrays, merged batches, per-prop distance window, wind, signals, night glow + lamp anchors,
  per-building tint slot); baked the SAMPLE AREA only (centre + apartments + civic + stadium): 65 draws median / 87
  worst a view with the whole skyline (raw: 942; budget 150), triangles sent 329k (over the 300k gate, Yasin: fine);
  tint + shop-name plates trial on the apartments sample (in memory). Samples: `review/samples_18nov/`. Lock test PASS.
  Bake output (`runtime/`, `runtime_tex/`) is NOT in git (derived). WAITING for Yasin: the six decisions at the end of
  RUNTIME_BAKE.md (roll out, data in git or not, merge limit, movement tuning, tint / plates, prop normal maps).
  NOT rolled out map-wide. Known flaw: the green street-name board lights with the green signal lens.
  FOUND: the cloud preview draws bldg_wear buildings ~40 % too dark (software GPU, Mobile renderer); OpenGL and
  Forward+ agree with the brighter look. Tell Yasin's PC check.
- 18 Nov: AUDIT (Yasin: "check the performance ... find inefficiencies, include how we can make it more lively and
  varied ... zero loadings"): `docs/AUDIT_PERF_LIFE_18NOV.md`, tools in `tools/city/audit/` (census.gd, probe.gd,
  probe_whatif.gd, load_times.gd: read-only, real renderer). NOTHING in the map changed, lock test PASS. Measured: whole
  city loaded = 916 draws median per street view (budget 150): far tier 2,331 draws for 70k tris, ground with no
  distance limit, every piece embeds its own model copies (lamp stored 305 times), kit atlases uncompressed without
  mipmaps (113 MB), 43 % of prop batches hold one prop; with a 300 m streaming radius 108 draws / 61k tris. Only the
  shore foam moves. WAITING for Yasin's four decisions at the end of the report (texture import, runtime bake before
  growth, which movement first, tint / shop-name trial on one sample). No work started on them.
- 18 Nov: THE NEW MAP HAS ITS OWN REPO (Yasin: "completely separate the new map from the old one ... sessions take too
  long to start"; chose "map only"): yasinyigitbas-max/NewMap, fresh history (~0.5 GB vs the game repo's ~7 GB). Work
  here from now on; the repo root is the Godot project (CLAUDE.md, tools/city/run/*.sh). The game repo
  (coronado-source) keeps the game and the --citykit terrain switch; integration copies city_kit + terrain/data_citykit
  back (same paths). The ferry plan waits (Yasin: "keep the ferry plan waiting").
- 18 Nov ~00:30: HAND-MADE ROAD PIECES (Yasin: "start making the handmade pieces for roads, remember to act like a road
  and city planner"). BRIDGE OPTION A BUILT (road_bridge.gd): j_rg_nw_e660_n1200 / _n1400 rebuilt as 4-way signals
  (unlocked by Yasin's go; the town mouth exactly as the ring T, the east mouth = approach / ramp sections fitted inside
  the T's tile so no neighbour moved); s_rg_nw_b142_1 / b143_1 rebuilt through the old bridge node (no gap); the
  divided approach s_br_appr_1..6 (exact path: 45 m straight, R 234 reverse curve, 40 m onto the deck; palms in the
  median, lamps, walks 70 m then bench pads; 4.0 -> 6.9 m) with the diverge (90 m taper, dotted lane drop, chevron
  gore, kerbed nose with a rounded tip) and the off-ramp s_br_ramp_1..5 (R 222 / 220 arcs tangent onto 3rd St, widens
  to 2 lanes over the last 70 m, 5.2 -> 2.0 m). review/sites.json: roadkit_sites.py hero_overrides() (W 1.35 + option
  A) so regeneration keeps them. review/bridge_sites.json (zz_bridge_write.gd). Checks (bridge area): validator 0
  (after removing posts that stood in the 4-way's arm poles), trees 0, sink 0, ground holes 0. NOT LOCKED (awaiting
  Yasin). LOCKED 18 Nov (Yasin "you can lock it"): the 2 crosses, b142_1, b143_1, s_br_appr_1..6, s_br_ramp_1..5.
  Yasin: the east bay shore showed "our cut" (the terrain box edge at u 1300 met today's steep straight bank) -> terrain
  box +700 m east (coast.py U1 1900, terrain.py U1 1700): smooth coast + beach + foam there too (one water line round
  the island, p99 bend 7.6 deg / m). Asset wish: ONE WAY / DO NOT ENTER signs for the ramp mouth. NEXT: the ferry entrance in the 1st St gap
  (after Yasin's OK on ferry_plan.png rev 2), then the ferry landing itself.
- 17 Nov ~21:45: TERRAIN (article 3, Yasin "start with article 3 then 2"; mid-work: "dont forget to work like a city
  planner, no jagged edges, elevations smooth, no jumps"). terrain.py now fits the ground to the pieces AS BUILT
  (piece_ground.gd raster, edge fit), beach from the smooth coast polylines, box +300 m on the land sides pinned to
  today's ground. Checks (terrain_check.gd, assembled city): shows-through 0 of 3.4 M samples, pokes 2 (4 cm, beach),
  open edge drops 133 (all in the locked pilot's hill yards). GAME: bake_game_terrain.py -> terrain/data_citykit/,
  user arg --citykit (CoronadoTerrain.data_dir(); without it nothing changes; data/ untouched; outside the box +
  the cut today's ground is identical). OPEN for Yasin: 1st St (ring north, v -1600, 5 junctions + 9 legs) is graded
  at 0.0 m = the game's sea plane (grading blur near the bay; real ground ~3.9 m) -> water z-fights the road; proposal:
  raise those pads to +2 m (locked grading + ring_nw pieces: needs his word). 1st St west (u -850) runs 8 m from the
  bay: a 1.7 m grass bank (~21 %) -> wants a riprap / seawall edge (with the ferry landing work). NEXT: article 2
  (bridge Y + ferry landing by hand).
  ~22:00 Yasin (looking at my first draft shots): "shores look jagged", "white", "all the shores should have the bubbles
  of waterfront". Fixed: preview colour (sRGB), coast.py box widened (the NW beach had no smooth line to follow),
  submerged piece ground (boat-ramp toe) no longer digs the beach; water line p99 bend 7.5 / 9.1 deg per 1 m on the two
  coasts. NEW piece x_shore_foam (shore_foam.py + pieces/x_shore_foam.gd): the waterfront's foam strip along 6.5 km of
  beach (skips seawalls / piers / pieces at the water), 56 chunks culled at 220 m, row in city_grid_layout.
  ~22:20 Yasin: "1 is okay 2 is no porblem for now just ont forget it for later." -> (1) 1st St raised: grading.json
  (unlockfile by Yasin) 5 pads 0 -> 2 m, review/sites.json regenerated (waterfront 1.35 hand edit kept), 26 ring NW
  pieces unlocked + rebuilt (5 T's at n1600, b145-b150, b163, stubs b010 b018 b028 b046 b056). (2) BRIDGE PARKED, DO NOT
  FORGET: option A needs j_rg_nw_e660_n1200 (4th St) and j_rg_nw_e660_n1400 (3rd St) rebuilt as 4-ways (approach +
  off-ramp) and a plain ring leg in the 45 m gap at (660, -1100); Yasin will say when.
- ALL samples built and LOCKED: pilot (+ d_pilot overlay), city centre (+ d_cc), industrial, commercial strip,
  apartment band, civic + parks, stadium + tennis, gritty edge (g_*), waterfront (s_wf, f_*). Lock test PASS,
  validator 0 problems (15,231 props), trees 0 in hard ground. Every building records meta "kit". Prop batches are
  split into cells (split_props.gd runs after every build via scratch build.sh).
- Yasin's last answers: civic/stadium OK; batch split done; waterfront + gritty locked; "all zones same standards".
- 17 Nov ~12:40: ZONING MAP APPROVED + LOCKED (Yasin "do 1 and 2"): plan.py, zones.py, zoning_map.png in
  locked.json "files" (lock test checks them).
- 17 Nov ~13:20: STREET SKELETON DRAFT 1 shown (STREETS.md, zoning/streets_draft1.png): 200 m junction lattice, samples
  snapped, island ring boulevard, superblocks; checks clean (93 junctions, <= 8 %). Waiting: Crown Hill main-road grades
  (7.5 %) keep or widen; diagonals + 2nd St dropped OK?
- 17 Nov ~22:00: BUS STOPS -> ROUTES (Yasin: "cut down to routes"). Now 154 stop signs (~77 pairs, one per ~220 m,
  nearly every std street). Plan: 4 routes, stops ~300-400 m both ways, ~40 pairs / ~80 stops:
  R1 Amber spine (1st St -> Ocean Blvd, stops at the Amber junctions), R2 3rd/4th St (bridge -> base gate, every
  second junction), R3 the ring loop (~400 m), R4 crosstown on 7th St (campus - civic - centre - apartments) and 5th St
  (gritty edge). Every other leg loses its stop: unlock (Yasin's word given), rebuild with bus=false (road_lib
  apt_street, road_resstd legs, sample street legs s_apt/s_civ/s_grt/s_wfd/s_ind), check, relock. The bus system
  (traffic) reads the route stops. NOT STARTED (usage); next session.
  BUS SHELTER FIX (Yasin "fix the bus shelter too"): its panes sample near-black atlas texels (~0.03), black in any
  light (tested flat ambient and sky + reflections; kit and our material alike). New prop condition "glass"
  (shaders/prop_glass.gdshader, materials pg_*.tres, kit_lib Props.build): darkest neutral/blue texels -> pale glass
  with a sky sheen; frame, bench, sign keep their look (review/shots/shelter_glass_before_after.png). APPLY in the
  route rebuild: every kept shelter placed with cond "glass" (pieces with shelters must be unlocked + rebuilt).
- 17 Nov ~21:30: ROAD KIT GROUPS 2-5 BUILT AND REVIEWED (coordinator review, Yasin: "do the reviews without ultracode";
  workflow stopped after ring SE). Assembled city (zoning/integrate.py -> city_grid_layout.json, 445 rows): every
  junction and block served except the bridge hero. Checks on the assembled city: validator 0 (23,034 props), trees 0
  (3,435), lock PASS, sink 0. Fixes: validator building yaw (world), 140 street sprinklers removed (Amber), speed signs
  off driveway aprons (art). NOT LOCKED: awaiting Yasin. Open: bus shelter asset renders black (kit), mast arm reach
  6.5 m (kit wish), bridge Y + ferry landing heroes, ring stop spacing ~400 m.
- 17 Nov ~20:00: MERGED claude/city-kit-audit-fixes (the other session's audit fixes #3 #4 #6 #9 #10 #11 + f_sw beach
  rework + shore foam; 17 block pieces relocked by Yasin, 5 new merged ck_svc_* buildings). No overlap with the road
  fleet's files. After the merge: lock test PASS (80 pieces, 7 plan files), validator 0 (15,991 props, 242 buildings),
  trees 0 in hard ground.
- 17 Nov ~19:10: fleet builders ring-core + resstd DONE (checks clean per their reports); art + amber building; Yasin
  approved the 7 builder decisions (ROADKIT_SPEC.md section 7).
- 17 Nov ~18:30: HERO SITES approved (HERO_DESIGN.md): bridge option A with smooth arcs (hero_geom.py), ferry landing
  plan. Yasin: no jagged roads, smooth shore everywhere ("looks like minecraft now"): the terrain step bakes the coast
  from smoothed vector lines. Build both by hand after the fleet.
- 17 Nov ~17:40: ROAD KIT GROUPS 2-5 FLEET RUNNING (ultracode, Yasin "go on and good luck"): workflow wf_b480fbd0-bc1,
  families ring (core + NW/SE site builders), resstd, art, amber; each build -> 2 reviewers (geometry / designer) ->
  fix -> verify. Brief: ROADKIT_SPEC.md; inventory review/sites.json (tools/city/pilot/zoning/roadkit_sites.py);
  Yasin's words for agents: scratchpad/yasin_messages.md. Review rows live in review/*.json (CITYKIT_LAYOUT_EXTRA),
  never in city_layout.json. DECISION to report: 3rd / 4th St are two-way arterials on the strip section (the
  locked strip sample carries 4th St), not the one-way couplet the skeleton picture labelled. CONFIRMED by Yasin ("they are okay").
- 17 Nov ~17:10: GRADING PLAN (zoning/grading.py/.json, all blocks <= 7.5 %) + residential RISE CLASSES LOCKED (Yasin "Grade is okay"):
  s_res_up/dn2_a/b, up/dn4_a/b, up/dn6; review chains at x 1100 / 1400 (+ zz_review_chain_a/b PREVIEW ONLY).
  NEXT after approval: groups 2-5 (ultracode, cost estimate first), hero pieces (bridge Y, ferry) by hand.
- 17 Nov ~16:00: ROAD KIT GROUP 1 LOCKED (Yasin "Approved"): j_res (residential all-way stop), s_res (flat leg),
  [17 Nov ~16:40, Yasin: "trees look copy pasted ... variety": s_res -> s_res_a/b/c, mixed street trees RES_MIX: runs of
  one species, young to mature (Props.add scale), irregular 11-14 m rhythm, ~8 % gaps; low crowns over the road OK.]
  s_res_up8 / s_res_dn8 (a block rising 8 m, 7.5 % max, halves meet at mid-block), review street at x 800 in the layout
  (+ zz_review_ground, PREVIEW ONLY). Torrey pines: every kit broadleaf hangs below 2.5 m (wish list: street-pruned
  coral / magnolia / jacaranda). After approval: groups 2-5 (ultracode suggested), slope classes per skeleton segment.
- 17 Nov ~14:30: STREET SKELETON LOCKED (Yasin "all 3 are okay"). AUDIT street fixes done (Yasin: "go for 1 and 2"),
  RELOCKED 17 Nov (Yasin "lock them"): j_amber_10th + j_cc (#1 poles r+1 -> r-1, on the corner sidewalk), s_ind (#13 pads
  tinted), s_apt (#15 bus pad, posts spread), s_amber_n/s + s_cc_amber_n/s (#12 queen palms alternate with the
  jacarandas; these 4 were NOT in the named unlock list: tell Yasin), NEW drafts s_civ / s_grt / s_wfd (#5 zone dress,
  layout swapped). Other agent (audit block/prop fixes #2-4, 6-11, 14, 15 vending/billboard) is WAITING for Yasin.
  Asset wish: street-pruned jacaranda (crown >= 4.5 m over the road).
- (history) 17 Nov ~12:25: zoning map DRAFT 2 (ZONING.md): Crown Hill approved; pilot keeps its built hill rows (not flat, not
  reworked); coast CUT south of the hotel (Strand / Shores / south base -> sea, island + bridge + ferry). Waiting.
- (was NEXT) ZONING MAP over Coronado's OSM streets, drafted as a PICTURE first for approval,
  deciding together: where each zone goes (transitions, never hard jumps), where the HILLS go (residential /
  apartment areas, sloped variants; flat centre / industrial / strip / stadium / waterfront), and the MUST sites
  (hospital, university, museum, courthouse) in their zone extensions. Yasin may raise my effort for this.
- Open: KIT_USAGE.md lists unused kit (about 30 house types wait for residential variants; hero landmarks).
- Session scratch: preview project + build.sh in the scratchpad (see skill "Cloud preview project").

## Yasin's standing instruction (17 Nov, verbatim)
> start the civic and parks and their sub chapters, again dont forget to act like an achitect, exterior designer and
> city planner, lots of props, lively, wear and tear, no jagged edges, update your skills with your experiences so far
> and scan the conversation for my inputs. lock the parts that dont need work, dont break anything thats done.
> also check assets folders hourly for new asssets, integrate the ones that come, add the missing prompts that you are
> waiting for, theyll be done in a few hours. actually make a job board with every standing queue article, rules and
> this message to remind yourself of doing things our way. and as an auto check, remind yourself rules budgets and
> skills my words right after context compressions.

## How we work (never skip)
1. **Act as architect, exterior designer and city planner at once.** Every building, prop and mark exists for a
   reason, in the right place, at the right time (who uses it, when, why there). "Logically placed."
2. **Lots of props, lively, lived-in, never brand new.** Wear and tear everywhere it would happen (oil where cars stand,
   tyre marks where they turn and brake, cracks, patches, gutter grime, worn grass where people walk, dirt at wall feet,
   rust, tags by the bins). Polish pass on every sample.
3. **Variety**: no two courts, yards or blocks dressed the same; unused kit pieces go into VARIANTS (extensions), not
   into locked samples.
4. **No jagged edges**: exact polygons (arrows, paths, kerb returns), no stair-stepped shapes, no lifted layers
   (paint is cut into the asphalt, one plane).
5. **Done = locked. Never break anything that is done.** Locked pieces change only with Yasin's word
   (`lock.py unlock --by=Yasin`), are rebuilt, re-checked and relocked. NEVER put a locked piece in a build batch by
   mistake (17 Nov: w_ind was rebuilt while locked; the lock test caught it, restored from git). Run the lock test
   after every batch: `res://tests/city_kit/test_locked_pieces.gd` must say PASS.
6. **Check before showing**: validator `CHECKS 0 problems`, tree audit `0 in hard ground`, look at EVERY shot myself;
   say which ones I did not open; never claim more than the checks cover. Shots have no shadows (lavapipe): say so.
7. **Commit and push after every step** (stop hook insists); develop on `claude/epic-ramanujan-42qll6`.
8. **Reports to Yasin**: short, plain, what changed and why, what is NOT done, what needs his decision. No Redmi
   numbers exist yet: say so. Budgets: buildings 1.5-5k tris near, cables ~700 tris per area in one draw, props within
   the kit budgets; draw counts in preview shots are inflated by preview cars (game batches them).

## Yasin's rules collected from the whole conversation
- (17 Nov, terrain) "work like a city planner, no jagged edges, elevations smooth, no jumps": ground meets every piece
  edge flush, smooth water lines, no cliffs at seams.
- ZERO-LOADING INTERIORS (Yasin 17 Nov: "indoors arent in other worlds, user will simply walk to doors from outdoors to
  indoors, theyll open automatically and walk into a readily waiting indoorroom whenever they want ... zero loading open
  world"). Every enterable room sits INSIDE its city-kit building behind one of the model's real doors, at the
  building's floor height, streamed with the city. The 169 shop fronts (shops/data/shops.json) are anchored to OSM
  footprints that the kit replaces: integration re-anchors each room to a kit building (model "room contract": inside
  volume, doors, windows) and re-assigns 60-80 enterable shops spread out. A parallel interiors session may draft the
  room contracts + the shop assignment for the locked samples (own branch, reads the city kit only). Not started:
  Yasin said "keep this in mind", no new work now.
- Roads: no half kerbs, no trees in buildings or in cement (trees stand in WELLS or grass), no half lane markers, no
  sharp turns, no lifted patches, no uneven or abruptly ending pavements, even radii, correct arrows and splitters.
  Smooth arrows (polygons, not steps). Arrow arms stay inside their lane.
- OSM road layer only, never satellite pictures (shadows look like road ends).
- No whole-city generators: hand-made pieces, frozen, locked; a fix in one place never changes another place.
- City = a dense GTA IV-like caricature of Coronado, not a replica; other-style kit pieces are welcome variety.
- Fewer shops, spread out (~60-80 enterable), corner shops in every neighbourhood.
- Hills OK but smooth, no sudden steep rises (max ~8 % in the pilot).
- Denser than Coronado: centre = continuous 4-6 storey walls, towers on corners; industrial = perimeter blocks, one
  quarter may be a single big warehouse; apartment band = street row + rear row around shared courts.
- Lived in: wear, clutter, back-of-house services on every building, bins beside garages, red kerbs at hydrants / bus
  zones, dirt at building feet, worn grass shortcuts.
- Banned: grass tufts (`plant_lawn_patch`), square dry mats. Park enclosures: closed hedge/fence with ONE gate.
- Fences: a post at every panel joint, no floating or stretched panels, no gaps.
- Benches face what people want to watch (the street, the play area), never a wall.
- Bike racks parallel to the kerb or shopfront, never across a walk; shops on narrow walks get a forecourt.
- Bus stops in BOTH directions in every area (far side of a junction, red kerb, bench facing the street).
- Swings, slides and sitting spots in open green, placed by use (courts between rows, behind buildings, along side
  walls), never near alleys, pads or the street.
- Cables within budget (~700 tris/area, "3100 for cables, really?"); power lines along alleys / back-lot lines,
  service drops to the wall facing the pole.
- Industrial kit batch (warehouse, factory, repair, containers, tanks, water tower, substation, dumpsters, construction
  props, chain-link / barbed / CMU / graffiti / rolling gate) and all other unused kit belong in the city somewhere.
- Tennis courts and the park pieces belong in the transition areas; there are no gyms or stadium yet - place them.
- Hero buildings are hand-made one-of-a-kind sites, never grown by agents.
- Redmi run comes LAST (after the map, streaming and the other systems).

## Queue (in order; keep ticking)
- [x] Pilot (residential + high street), city centre, industrial, commercial strip, apartment band - locked.
- [x] Bike racks, bus stops both ways, smooth arrows, tree wells, fence posts - city-wide fixes, relocked.
- [x] Waterfront set 1 brought in from the assets branch (17 Nov 03:26 commit 306563f).
- [~] **Civic + parks band (built 17 Nov: four quadrants v_* + stadium st_stadium; awaiting Yasin's approval)** and its sub-chapters: tennis centre, skate park + shed, dog run, playground
      village, memorial green, succulent garden, town square, rec centre as the gym, schools, library, post office,
      police, fire station, community centre; the stadium with its parking. Transition rules apply.
- [x] Kit batch 2 props in the strip, apartments, streets, stadium (17 Nov): validator 0, trees 0, lock PASS, relocked.
      Stadium gates sized for the mid-tier opening (Yasin: "close both sides"); m_sw vending off the stair foot.
- [x] Civic + parks band and stadium: LOCKED 17 Nov (Yasin: "civic and stadium are okay").
- [~] **Gritty edge (built 17 Nov: g_ne/g_nw/g_se/g_sw + w_grt at (400,-400), four merged ck_ buildings; awaiting Yasin)**
      Open question for Yasin: shade sails stand BETWEEN two picnic tables (shading neither) in locked a_ne, v_nw, v_sw,
      m_ne - fix needs his word to unlock. (industrial -> apartments): boarded / abandoned fronts, fire escapes, pawn, laundry, dingbats,
      graffiti, billboards, weathered board fences. (Real buildings if Yasin promotes the kit's `_staging/gritty`.)
- [x] Prop culling bug fixed 17 Nov (Yasin: "go with the batch split"): split_props.gd on every piece, instances
      identical, validator 0, lock test PASS after re-fingerprinting the 39 locked pieces.
- [ ] **ELEVATION (Yasin 17 Nov: "i see no elevation anywhere ... i think it was forgotten")** - only the pilot's hill
      rows have grades; every later sample was built flat and hills fell off this queue. Plan in the report; to be
      done with the zoning map (where the hills go) + slope variants of the samples that sit on them.
- [x] 17 Nov fixes: sails over each table (a_ne v_nw v_sw m_ne), stadium court-gap tables/sails removed, tennis nets
      two-sided see-through with tape, balconies black iron over brick entries only (apartment rows: none). a_* unlocked
      until Yasin sees the balconies.
- [~] **Waterfront sample (built 17 Nov at (-400,0,400): s_wf pier plaza + pier, f_se marina, f_sw beach, f_ne / f_nw
      bayfront blocks with boat storage + beach parking inside, w_wf; awaiting Yasin).** Water is preview-only meta.
- [x] Prop density of the two oldest samples raised 17 Nov by overlays d_pilot (+615 -> ~1,380) and d_cc (+789 ->
      ~1,135) built by life_lib.gd from the locked pieces (roof plant, service sides, downspouts, house numbers, hose
      reels, golf carts, window ACs, solar, tower roof terraces); locked pieces untouched. EVERYTHING locked 17 Nov
      (Yasin: "then lock them all"): apartment band, gritty edge, waterfront, overlays.
- [ ] **MUST for the extension phase (Yasin 17 Nov, "critical"): hospital, university, museum, courthouse** in the zone
      extensions they belong to (hospital + university near the civic / apartment side with parking and an ambulance bay,
      museum by the centre or the waterfront, courthouse in the city centre). They are workplaces for many game jobs and
      the player can end up hospitalized: entrances, parking, drop-offs must work. Kit: pub_hospital / ext_hospital,
      pub_university, pub_museum / civ_museum, urb_courthouse.
- [ ] Hero sites (hand-made): hotel annex / city hall at the avenue's end, chapels on a rise, Glorietta mansion,
      hospital, university.
- [~] **Zoning map draft 1 (17 Nov ~12:10): `ZONING.md` + `zoning/zoning_draft1.png`, awaiting Yasin.** His rule: samples
      on FLAT ground, elevation only in transitions / extensions (no rework of done parts). The real dome at 3rd-5th St
      became Crown Hill; all grades <= 8 %; 40 m flat margin round every sample.
- [ ] Zoning map over Coronado's OSM street layout; then variants of every sample (unused kit); then growth with
      agents (needs Yasin's go-ahead for multi-agent runs).
- [ ] Integration: streaming, parked-car layer reads the "stalls" meta, traffic lanes, the wear shader on far tiers.
- [ ] Redmi perf run + build (last).
- [ ] Add-when-they-arrive (Yasin is modelling them, "done in a few hours"): shopping carts + cart corral, pylon
      signs, vending machines, ice chest, drive-thru menu board, wheel stops, bus-stop pole sign, balconies with
      clutter, outdoor stairs, intercom panel, clotheslines; waterfront: marina floats/fingers, moored boats,
      boardwalk + seaside railing, life-ring stand, buoys, fuel dock pump, boat trailer, kayak rack, beach shower,
      volleyball net, beach umbrellas.

## Hourly asset check (PAUSED 17 Nov 17:42 by Yasin: "stop the hourly check there wont be anything there until tomorrow"; scheduled task disabled, re-enable when he says)
Every hour: `git fetch origin assets` and compare `assets/coronado_kit` with ours. Bring in ADDITIVE changes only
(`git checkout FETCH_HEAD -- <added/modified paths>`, never the .uid deletions), register new manifests in
`kit_lib.manifest()`, check shared shaders / atlas pages did not change (they would alter locked pieces' look - ask
Yasin first if they did), commit, then use the new parts where they belong (queue above) and tell Yasin.
Last check: 17 Nov 17:40 UTC (unchanged since 13:52), assets head cff7acc (indoor shop props 62 on atlas page I, near + collision only, 10 manifests) - INTEGRATED: files in (additive; props_atlas.json only gained page I regions, no existing region changed), manifests registered in kit_lib.manifest(). Use: shop interiors (coronado-interiors), not the street kit.
