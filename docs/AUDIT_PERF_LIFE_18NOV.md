# Audit: performance, zero loading, and how to make the city more lively and varied (18 Nov 2026)

Asked by Yasin: "check the performance of the game in this repo and find inefficiencies, include how we can make it more
lively and varied ... it is supposed to be an open world game with zero loadings."

Nothing in the map was changed. The lock test says RESULT PASS (401 pieces, 19 plan files). The audit added four
read-only measuring scripts in `tools/city/audit/` and this report.

**Update, same day:** Yasin said to do the four things. What was built and measured since is in `RUNTIME_BAKE.md`
(sample area: 65 draw calls a view with the whole skyline). Finding P8 changes: the engine's mobile light grid gives 32
live lights for a fixed cost, so the rooms' light counts are fine as they are.

## The short version

1. **The street-level detail is cheap. The far view is what breaks the budget.** Standing in the street with the whole
   city loaded, a typical view costs **916 draw calls** against the budget of 150. About 580 of them are the far tier
   (distant tree cards, distant props, distant building boxes) and about 140 are road surfaces with no distance limit.
   The props, trees and buildings within 220 m cost about 90.
2. **Zero loading needs two layers that do not exist yet:** pieces streamed in and out around the player (about 300 m),
   and one small, always-loaded "far world" for the skyline. The whole city's far tier is only about 70,000 triangles,
   so it can stay in memory for the entire island. Today it is spread over 2,331 separate draws.
3. **Every piece file carries its own copy of every model it uses.** The same street lamp is stored 305 times. This is
   why pieces are 162 MB on disk, why the loaded city holds 313 MB of mesh data instead of about 92 MB, and why a block
   takes 50-110 ms to load instead of a few.
4. **The kit's textures load uncompressed and without mipmaps:** about 113 MB where about 25-30 MB is expected, and
   distant surfaces sparkle. One import setting, no piece changes.
5. **The map is limited by draw calls, not triangles.** With streaming, a view is about 61,000 triangles against a
   budget of 300,000. Once the draws are merged there is room for three to four times more props, longer prop ranges,
   and movement.
6. **Lively: nothing in the city moves.** One shader in the whole map animates (the shore foam). There are no lights,
   night windows are not wired, and about 9 of roughly 85 city blocks are built. The cheapest big wins are wind in the
   3,468 trees and palms, signals and night lights, and turning the 23,172 placed props into things people and cars
   use.

## How this was measured, and what it does not cover

| Tool (`tools/city/audit/`) | What it measures |
|---|---|
| `census.gd` | every piece on its own: file size, load and instantiate time, nodes, models, batches, collision shapes |
| `probe.gd` | the assembled city (457 placed pieces) from 13 street-level spots x 4 directions: draw calls and triangles, then each group hidden in turn |
| `probe_whatif.gd` | the same views with a 300 m streaming radius, and with a merged far world |
| `load_times.gd` | warm load times (the piece itself, shared textures already in memory), and the 12 interior rooms |

Same method as the game's gate (`docs/perf_budget_game/perf_budget.gd`): camera at eye height, 70 degree view, far
plane 2,600 m, counts from the renderer.

Limits, so the numbers are read correctly:
- **No phone was used.** Draw calls, triangles and memory are counts and are the same on any device. Times are from
  this cloud machine's desktop-class CPU; a mid-range phone is roughly 3-5 times slower (my estimate, not measured).
- Rendered on a software GPU, so frame times mean nothing and are not reported. The shadow pass is not counted
  reliably; the game will add shadow draws for everything in the near tier.
- The map only. Traffic, pedestrians, the game's terrain, sea, sky and streaming code live in the game repo, which
  this session cannot open. Parked cars are not in these numbers.
- "After" figures in the fix sections are estimates unless marked measured.

## Part 1: performance

### The numbers against the budget (150 draws, 300k triangles, 1 GB video memory)

| Case, 52 views | Draw calls (median / worst) | Triangles (median / worst) | Views over 150 draws |
|---|---|---|---|
| Whole city loaded, as the piece files ask today | 916 / 1,659 | 347k / 763k | 45 of 52 |
| Only pieces within 300 m loaded (measured) | 108 / 215 | 61k / 112k | 10 of 52 |

Whole city in memory: 474 MB video memory (313 MB mesh data, 143 MB textures), 562 MB RAM, 35,092 nodes, 19,744
collision shapes. That is with about one block in ten built, so "load everything" will not fit once the city is full.

Where an average view's draw calls go with the whole city loaded:

| Group | Draws | Triangles |
|---|---|---|
| Far tree and palm cards (218-1,500 m) | 360 | 1,800 |
| Road and ground surfaces (no distance limit) | 139 | 303,000 |
| Far props | 133 | 5,000 |
| Far building boxes | 58 | 1,800 |
| Far fences | 28 | 8,000 |
| Near and mid props, trees, fences | 74 | 19,000 |
| Near and mid buildings | 10 | 12,600 |
| Wear marks, wires, foam | 9 | 2,800 |

### Findings, most important first

**P1. The far tier is 2,331 separate draws for about 70,000 triangles.**
Each prop type in each piece has its own far batch, drawn out to 1,500 m. A wheel stop, a shopping cart and a door
buzzer panel also have far versions drawn to 1,500 m. The far tier needs its piece loaded, so showing the skyline today
means keeping the whole city in memory.
- Fix: bake one "far world" for the island: building boxes, tree cards and the big far props merged into a few meshes
  with two materials (one solid, one cut-out for trees). Always loaded. Roughly 10-20 draws instead of about 580.
- A first try that merged per 200 m cell and per existing material gave 478 meshes (14 materials) and still cost about
  150 draws per view, so it must be merged harder: big cells, two materials.
- Small props should have no far tier at all. Past about 300 m they are smaller than a pixel.

**P2. Road and ground surfaces have no distance limit and no simple far version.**
447 ground meshes, 2,552 surfaces (one per material: asphalt, concrete, kerb, grass, white paint, yellow paint ...),
971,000 triangles, 48 MB. Every piece to the horizon is drawn in full: 139 draws and 303,000 triangles in an average
view, which alone is over the triangle budget. Inside 300 m the same ground is 11 draws and 26,000 triangles.
- Fix 1: far ground goes into the far world as plain road rectangles (a few triangles per street).
- Fix 2: one ground material with all surfaces in one texture set, so a piece's ground is one draw instead of five or
  six.
- Fix 3: flat stretches are cut into 4 m squares they do not need. Flat ground can be re-triangulated at bake time
  with no visible change.

**P3. Every piece embeds its own copy of every model.**
1,437 different meshes exist (92 MB). The piece files store 10,927 copies (255 MB). The cobra lamp is in 304 pieces as
305 copies. Result: 162 MB of piece files, 313 MB of mesh memory when loaded, slower loads, and no chance for the
renderer to treat the same lamp in two pieces as the same lamp.
- Fix: a shared model library. Pieces keep only "which model, where". This is done in a bake step that reads the
  locked pieces and writes game data, so the locked files stay byte-identical.
- Expected: piece data shrinks to a small fraction, loads drop from tens of milliseconds to a few.

**P4. Kit textures are uncompressed and have no mipmaps.**
All 36 kit atlases (`assets/coronado_kit/textures`, `atlases`) are imported with compression "lossless" and mipmaps
off. Measured in memory: three 2048 atlases at 12 MB each, twenty-one 1024 atlases at 3-4 MB each, about 113 MB in
total. The kit's own budget is 44 MB after compression. Without mipmaps, distant walls and tree crowns sparkle (the
preview shots show it) and the phone's GPU works harder on every distant pixel. The kit budget names pixels as the
number one cost on the Redmi.
- Fix: import them VRAM-compressed with mipmaps (normal maps flagged as normal maps). About 25-30 MB.
- This does not touch any piece file, but it changes how locked pieces look at a distance (calmer, slightly softer),
  so it needs Yasin's word. Worth checking that the game repo's copy of the kit has the same setting.

**P5. Prop batches hold almost nothing.**
11,062 batches for 47,681 instances. 43 % of batches hold one prop, 67 % hold one or two. Yet 2,016 of the near
batches share one single material. A batch is a draw call whatever it holds.
- Fix: merge per 64 m cell and per material, as the other agent proposed on 17 Nov. Counted on the real pieces: near
  batches 6,393 -> about 2,600, mid 2,580 -> about 1,300.
- The wear level (clean / worn / dirty) splits materials today. The prop shader already reads a per-prop value, so
  wear can ride with each prop and the split disappears.

**P6. Loading spikes that would be felt as hitches.**
- First touch: the first piece that needs a shared texture or shader pays for it: up to 1.4 s on this machine. Fix:
  load the shared atlases, materials and shaders once at game start, and draw each material once off-screen so
  shaders are compiled before the player moves.
- A sample's quadrants share one origin, so about 13 pieces cross any radius in the same frame (4.2 s of load work
  cold, about 0.4-0.5 s warm, on this machine). Fix: stream by each piece's own bounds, nearest and ahead-of-travel first.
- Putting a piece into the scene runs on the main thread: 2-13 ms for most, 54-84 ms for the stadium (2,084 nodes).
  On a phone that is one to several dropped frames. Fix: load and build on a worker thread, add at most one piece per
  frame, split the stadium.
- Driving at 30 m/s with a 300 m radius needs about 100 ms (warm) to 280 ms (cold) of load work per second with today's files. One background
  thread can carry that on this machine; on a phone it is too close. P3 fixes it.

**P7. The wear shaders run at full cost at every distance.**
A near building pixel reads five textures (colour, ORM, grime twice, normal). The mid tier, 58-222 m away, still
reads grime twice, although grime is invisible at that distance. Far props still use the four-read wear shader.
- Fix: mid and far tiers get a plain one-read material. Far props go into the far world anyway.

**P8. Interior rooms: 32-41 draws and 4-17 real lights each.**
Six of the twelve rooms have more than 8 lights (library 17, city hall 16, rec centre 16, police 13, market 10, bar
9). Godot's mobile renderer lights a mesh with at most 8 omni lights, so some will drop out, and each one costs GPU
time on every pixel it reaches. Two live rooms plus the street would use more than half the 150-draw budget.
- Fix: at most 2-4 real lights per room, the rest baked into the room's colours or shown as glowing fittings. Merge a
  room's props per material. Rooms have no collision yet (known: visuals first).

**P9. Shore foam: 185,712 triangles in 65 chunks** for 6.5 km of beach (about 28 per metre), alpha blended. A strip
needs 2-4 triangles per metre. It is culled at 220 m, so it is a small cost, but an easy tenfold cut.

**P10. Tier switches pop.** Fading is off, and small props vanish at 60 m, which is about two seconds ahead of a car.
Once draws are merged (P5) there is triangle room to keep small props to 120-150 m.

### What zero loading needs from the map (the design in one place)

1. **Three layers.** (a) Far world: whole island, always in memory, about 70k triangles, 10-20 draws. (b) Streamed
   pieces: everything within about 300 m, dropped past about 360 m. (c) Rooms: woken at 35 m as the interiors plan
   says.
2. **A runtime bake** that turns the locked pieces into game data: shared model library, merged batches per cell,
   one-draw ground, the far world. Locked pieces remain the source and are never rewritten. A fix to one piece
   re-bakes one cell.
3. **Never wait on the main thread:** threaded loads, one piece added per frame, shared resources and shaders ready
   at start.
4. **A gate in this repo:** `probe.gd` already prints draws and triangles per spot. With a `--budget` switch it can
   fail a build the way the game's gate does, so the map is checked before integration, not after.

### Estimated result (estimates, not measured, except the first row)

| Step | Draws, typical view |
|---|---|
| Streaming at 300 m (measured) | 108 |
| + far world in two materials | about 120 |
| + props merged per cell and material | about 80 |
| + one-draw ground | about 70 |

That leaves about 80 draws of the 150 for cars, people, terrain, sea, sky, rooms and shadows, and about 200,000
triangles spare.

Do this before the city is filled in. Every one of these costs grows with the number of blocks, and about nine blocks
in ten are still to come.

## Part 2: more lively, more varied

### What is there today
- 23,172 props of 202 types, 242 buildings of 99 types, 3,995 parking stalls, 12 walk-in rooms, 9 district samples.
- Nothing moves except the shore foam. No lights. The night window glow exists in the building shader but nothing
  drives it.
- Pieces tell the game only where parking stalls and poles are. Benches, bus stops, doors, courts and lamps are
  drawn, but the game cannot find them.

### A. Movement that costs no draw calls
All of this is a few lines in the vertex part of a shader. No new models, no new draws.
1. **Wind in the 3,468 trees and palms and the hedges.** The biggest single change to how alive a street feels. One
   shared foliage shader also replaces the separate tree materials (near, mid and far each have their own today).
2. **Cloth and boats:** 29 shade sails, 16 clotheslines, 15 beach umbrellas, awnings and flags sway; 15 moored boats
   and the buoys bob.
3. **Traffic signals that cycle:** 107 signals (61 mast arms, 46 posts), driven by the traffic system, as glowing texture regions.
4. **Night:** window glow (already in the shader), 1,209 street lamps and 204 porch lights with glowing heads and a
   soft pool of light painted on the ground. No real lights outdoors: they are too costly on the phone.
5. **Small effects with a cap per view:** the 21 sprinklers running on a timer, factory stack smoke, rooftop vent
   steam, leaves and litter in the gritty quarter.
6. **Birds:** gulls over the pier and marina, pigeons on plazas that take off when the player walks up. One draw for
   a whole flock.
7. **Sound zones from the zoning map:** harbour, industrial hum, school bell, church bells on the hour, stadium
   crowd. The zone outlines already exist in `zones.py`.

### B. Let people and cars use what is already placed
Every prop was placed for a reason, so each reason can become an activity. A bake step reads the pieces and writes a
list of "life anchors". Locked pieces are not touched.
- 392 benches: someone sits, facing what the bench faces.
- 154 bus-stop signs: people wait, the bus stops (after the route cut-down on the job board).
- 34 picnic tables, the tennis courts, skate park, dog run and playgrounds: used at the right hours.
- Doors, from the room contracts that already list every door of 99 building models: people go in and come out,
  shops open and close by the hours in `shops.json`.
- 3,995 stalls: parked cars by district (work vans in the industrial quarter, older cars at the gritty edge, golf
  carts by the beach), and cars that pull in and out.
- Time of day: school run, lunch queues at food shops, bar at night, match day at the stadium filling its car park.

### C. Variety, backed by the counts
1. **Fill the blocks.** About 9 of roughly 85 blocks are built; the ring roads run through open grass. This is the
   largest lively-and-varied gain there is, and it is already next on the job board.
2. **Unused kit:** 51 of 150 building models have never been placed, including 29 of 41 house types, 9 of 10
   landmarks, the hospital, museum, university and courthouse. 24 outdoor prop types are unused.
3. **Repetition:** two models make up 40 of the 242 buildings (`ck_apt3_row2` 23 times, `ck_apt3_row3` 17 times).
   The kiosk appears 13 times. Fix without new models: a per-building paint tint and wear amount, chosen from the
   building's position. No extra draws.
4. **Painted shop names repeat and sit in the wrong place.** The preview shows SUGAR CROWN BAKERY, VILLAGE THEATRE and
   CROWN CAFE in the industrial quarter; 15 models say VILLAGE THEATRE. The sign plates built for the walk-in rooms
   (`r.sign`, `make_signs`) can cover every shopfront from a name list per district.
5. **Every district has the same road and pavement.** One asphalt, one near-white concrete, and 60 % of the street lamps are
   the cobra type. Vary by district with colour and wear only: fresh black asphalt in the centre, patched grey in the
   industrial and gritty quarters, sandy at the beach, faded paint on back streets.
6. **Weather and hours.** Wet roads after rain (a wet mask is already in `assets/roads`), puddles at the 648 storm
   drains, morning haze at the bay, sunset. This changes the whole city without placing anything.
7. **Small scenes that change by day,** built as overlay pieces like `d_pilot` and `d_cc`, so locked pieces stay
   locked: bin collection day, a street repair crew (the cones, barricades and K-rails are in the kit), a moving van,
   a yard sale, market day on the town square, a food truck by the park, a wedding at the chapel.

### What liveliness costs
- Shader movement, tints, signs from one sheet, glowing lamps: no extra draws.
- Overlays and filled blocks: normal props, which is why the merging in Part 1 comes first.
- Birds and particles: one or two draws each, capped per view.
- People and cars are the game's systems; the map only hands them the anchors.

## Suggested order
1. Texture import fix (P4). Smallest job, large memory and image-quality gain.
2. The runtime bake: model library, merged batches, one-draw ground, far world (P1, P2, P3, P5, P7).
3. Streaming and loading rules (P6), with `probe.gd` as the map's own gate.
4. Wind, signals, night glow (A1, A3, A4).
5. Life anchors (B), then tint, signs and district surfaces (C3-C5).
6. Fill the blocks (C1, C2) on the fixed pipeline, then overlays (C7).
7. Room lights and batches (P8) before more rooms are made.

## Decisions for Yasin
1. May the kit textures be switched to compressed with mipmaps? No piece file changes, but locked pieces will look
   calmer at a distance.
2. Build the runtime bake before the growth phase? Recommended: the costs it removes multiply with every block.
3. Which movement first? Recommended: wind in the trees, then signals and night lights.
4. Per-building tint and shop-name plates change how locked samples look without changing their files. OK to try on
   one sample and show it?
