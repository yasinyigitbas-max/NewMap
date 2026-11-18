# Coronado building and prop kit: model rules and performance budget (15 Nov 2026)

For whoever makes the models. The game runs on Android phones. The weakest target is a **Redmi Note class phone (Mali GPU)**,
which today is **GPU-bound at about 18-20 ms a frame at half render scale**. Every model must make the frame cheaper or
cost almost nothing. These are hard limits, not suggestions. A model over a limit goes back.

Where a frame really goes on this phone, in order:
1. pixels (shader cost per pixel, overdraw, alpha cut-outs: cut-outs alone measured 5.5 ms);
2. draw calls and materials (CPU: every separate material or mesh is one more draw);
3. texture memory;
4. triangles (only last; they matter mostly in bulk).

So most rules below are about materials, textures and transparency, not triangles.

---

## 1. Hard rules for every model

**File and frame**
- `.glb` (glTF 2.0 binary), one model per file, named `<category>_<name>_<tier>.glb` (e.g. `house_spanish_cottage_near.glb`).
- Metres, Y up, **front (the door side) faces +Z**, origin at the **bottom centre of the footprint**, ground at y = 0.
- Real scale: doors 2.0-2.2 m high, storeys 3.0 m (ground floor of shops 3.5-4.0 m), a person is 1.8 m.

**Mesh**
- **One mesh and one material per tier.** Two materials only for a landmark, and only if one of them is the shared glass/night
  material. No loose separate objects, no empties, lights, cameras, animations or hidden objects.
- Triangulated, no degenerate or duplicate faces, **all faces pointing outward**, closed where the model is seen from all sides.
- **No hidden faces:** no interior walls or floors, no faces under the ground, inside walls, under other roofs, or the back of
  anything that is against a wall.
- Normals and tangents exported (tangents are needed for the normal map).
- UV0 = the atlas UVs (section 3). **UV1 (second UV set) left free** for the game. Up to 65,000 vertices per mesh.
- Vertex colour channel allowed for tint variation (one model, several wall colours) and baked AO.

**Transparency: none on buildings**
- **No alpha cut-out and no alpha blending anywhere on a building:** no cut-out railings, lattice, grilles, leaves on walls,
  awning fringes or fences on the model. Model them as solid thin geometry, or paint them into the texture.
- **Glass is opaque:** a dark, slightly reflective region of the atlas (with a faint interior or curtain painted in), never
  transparent.
- Alpha cut-out is allowed ONLY for: tree and plant leaves, chain-link fence panels, and shade-sail mesh. Even there, keep the
  cut-out area as small as possible (tight cards, no big empty quads).

**Detail**
- Windows and doors: a **shallow inset (5-15 cm) with the frame, mullions, sill and trim in the normal map and colour**, not full 3D
  frames. Real geometry only where it changes the silhouette: porches, eaves, balconies, chimneys, towers, awnings, arches.
- Bake ambient occlusion **into the base colour** (under eaves, in window and door recesses, at the foot of walls, under
  balconies). No separate AO texture. No reliance on screen-space AO (the game's mobile renderer has none).
- No emissive geometry except the window night-glow region of the shared atlas (the game turns window lights on at night).

**Collision**
- A separate mesh named `col` per model: **at most 12 boxes** (or one convex hull of at most 32 vertices) that follow the walls.
  Porches and steps: one box per step run. Props: one box or one cylinder.

---

## 2. Distance tiers

Every building and every prop taller than 1 m comes in three tiers. Small props have near only (they are not drawn past 60 m).

| Tier | Drawn from-to | What it is |
|---|---|---|
| near | 0-60 m | full model, colour + normal + packed ORM |
| mid | 60-220 m | same shape simplified: about 30 % of the near triangles, **colour only** (no normal map), no small parts (gutters, lamps, AC, dishes, railings) |
| far | 220-1,500 m | a **closed box hull** of the main masses with the facade **baked into a far atlas** (windows painted), roof planes kept, under the far limit below |

The far tier must line up with the mid tier (same footprint and height), so there is no jump when it switches.

---

## 3. Textures

**Everything comes from shared atlases. No model has its own texture set.**

| Atlas | Size (max) | Maps | Used by |
|---|---|---|---|
| Building walls and trims | 2048 x 2048 | colour (AO baked in) + normal + ORM | all buildings, near and mid (mid: colour only) |
| Roofs, doors, windows, glass, awnings | 2048 x 2048 | colour + normal + ORM | all buildings |
| Building far | 2048 x 2048 | colour only | far tier of all buildings (baked facades) |
| Props | 2048 x 2048 | colour + normal + ORM | all street and house props |
| Trees and plants | 1024 x 1024 per species group (bark 512 x 512) | colour + normal | trees, palms, shrubs (cut-out leaves allowed here) |

- **No texture larger than 2048 x 2048. A single prop or building never gets its own texture above 512 x 512.** If one truly
  needs its own (a landmark sign, a mural), at most 512 x 512, colour only.
- ORM = one packed map: red = occlusion, green = roughness, blue = metallic.
- Walls and roofs use **tiling regions or trim-sheet strips** of the atlas, so texel density stays high without huge textures:
  target **about 256 px per metre** on walls up close, never under 128 px per metre.
- Wall colour variety comes from **vertex colour tint**, not from more textures: author walls in a light neutral (white or
  pale cream stucco, light brick) so the tint works.
- Deliver source textures as PNG; the game compresses them (ETC2 / ASTC with mipmaps). Do not pre-compress.
- Texture memory caps after compression (whole game): buildings 20 MB, props 8 MB, trees and plants 16 MB.

---

## 4. Triangle budget per model

Near / mid / far, triangles. "Box" = closed box hull with baked facade.

### Buildings
| Category | Near | Mid | Far |
|---|---|---|---|
| Garage, shed, carport, granny flat (ADU) | 300 | 100 | 12 (box) |
| Small house (footprint under 120 m²) | 1,500 | 450 | 40 |
| Large house, two-storey house, duplex | 2,500 | 750 | 60 |
| Apartment block, bungalow court, condo (per building up to 30 m long) | 3,500 | 1,000 | 80 |
| Large apartment / condo block, motel (over 30 m long) | 5,000 | 1,500 | 120 |
| Shop bay, cafe, restaurant (per 6 m of frontage) | 1,200 | 350 | 20 |
| Corner shop, bank, liquor store, gas station, strip mall unit | 2,500 | 750 | 60 |
| Civic: school wing, church, library, fire / police station, post office, community center | 5,000 | 1,500 | 120 |
| High-rise tower (per 10 storeys) | 4,000 | 1,200 | 80 |
| Warehouse, hangar, barracks, parking garage | 2,000 | 600 | 40 |
| Landmark (Hotel del style resort, bandstand, ferry pavilion, lookout tower) | 8,000 | 2,500 | 200 |
| Hotel Bel itself (the one hero) | 15,000 | 4,000 | 300 |

### Props (near only unless marked; drawn to 60 m)
| Category | Near | Notes |
|---|---|---|
| Tiny: hydrant, meter, mailbox, house number, hose, gas / electric meter, vent, sprinkler | 150-300 | no mid tier |
| Small: bin, trash cart, bench, chair, AC unit (window or condenser), satellite dish, porch light, potted plant, propane tank, newspaper box, bollard | 300-600 | no mid tier |
| Medium: lamp post, traffic light, sign post with sign, bike rack, BBQ, patio set, picnic table, drinking fountain, golf cart, dumpster | 600-1,200 | mid 30 % for lamp posts and traffic lights (seen far) |
| Large: bus shelter, play structure, swing set, lifeguard tower, utility pole with transformer, bandstand piece | 1,500-2,500 | mid 30 %, far 20 |
| Fence / wall panel (2 m) + post | 60 solid; chain-link 4 (one cut-out quad) | must join end to end |
| Hedge (2 m panel) | 200 | |
| Wires between poles | not modelled | drawn by the game |

### Trees and plants
| Category | Near | Mid | Far |
|---|---|---|---|
| Street / park tree (crown 5-12 m) | 2,500 | 800 | 2 (camera-facing card from the trees atlas) |
| Palm (fan, date, king, queen) | 1,500 | 500 | 2 |
| Yard tree, Norfolk pine | 2,000 | 600 | 2 |
| Shrub, agave, bird-of-paradise, bougainvillea | 300-500 | none | none |

---

## 5. What the whole scene may cost (the game enforces these; the models must make them possible)

Redmi, worst street view (Orange Avenue / downtown), at half render scale:

| Item | Budget |
|---|---|
| Building triangles drawn | 250,000 (near + mid + far) |
| Prop triangles drawn | 120,000 |
| Tree and plant triangles drawn | 200,000 |
| Building draw calls | 60 (the game merges models per 100 m chunk per tier: needs one material per model) |
| Prop draw calls | 80 (one MultiMesh per prop type: needs one mesh, one material per prop) |
| Tree draw calls | 40 |
| Alpha cut-out pixels | trees and fences only; no building pixel may be cut-out |
| Shadow casters | near tier only; mid and far never cast shadows |
| Extra GPU time vs today | at most +1.0 ms on the Redmi for the whole kit, measured on the same lap |

---

## 6. Delivery and acceptance

Per batch:
- the `.glb` files (near / mid / far / col), the shared atlases as PNG, and `CREDITS.md` (source, author, licence for anything
  not made from scratch; CC0 or CC-BY only);
- a table per model: triangles per tier, materials, atlas regions used, footprint (w x d), height, door position along the
  front (x), storeys;
- one picture per model: four sides at the same scale with a 1.8 m figure, plus the three tiers side by side.

We check every model from four sides (holes, inward faces, scale, dark patches, transparency), then put one full street of the
batch into the game and run a lap on the Redmi against today's numbers. A batch that costs more than +1.0 ms GPU or adds more
than 10 draw calls on that lap is cut further before it goes anywhere else.
