# City kit job board (read me FIRST, and again after every context compression)

This file is the session's memory of what to do and how Yasin wants it done. Keep it current: tick items, add new
ones the moment Yasin asks for them, never delete his rules. Method and traps live in the skill
`.claude/skills/coronado-city-kit/SKILL.md`; the zone plan in `CITY_PLAN.md`.

## WHERE WE ARE (17 Nov ~11:50 UTC, written before a context compaction)
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
