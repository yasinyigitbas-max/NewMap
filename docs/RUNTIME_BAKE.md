# Runtime bake and the four trials (18 Nov 2026)

Yasin, after the audit (`AUDIT_PERF_LIFE_18NOV.md`): "do the 4 things you mentioned. show me samples where its
possible before a map wide roll out." Later: "triangles are fine ... try to keep draw calls as low as possible."
And: the engine's mobile light grid (`docs/engine`) gives up to 32 live lights for a fixed cost: use it for lights.

Nothing in the locked pieces changed (lock test RESULT PASS). Sample pictures: `map_dc/coronado/city_kit/review/samples_18nov/`.
The sample area is the city centre, apartments, civic band and stadium (32 cells of 200 m).

## Status
| Item | State |
|---|---|
| Stale plan picture | replaced (`zoning/city_assembled_wip.png`) |
| 1. Kit textures compressed with mipmaps | DONE for the whole kit (it cannot be done per sample). Texture memory 143 -> 38 MB |
| 2. Runtime bake | tool works; baked for the SAMPLE AREA only. Not rolled out |
| 3. Movement | wind, cycling signals, night windows / lamps: in the bake's shaders, shown on the sample |
| 4. Paint tint and shop-name plates | trial on the apartments sample, in memory only |

## 2. The runtime bake
`tools/city/bake/`. It reads the locked pieces and the layout and writes game-ready data to
`map_dc/coronado/city_kit/runtime/` (not in git: it is derived, see "Decisions"). It never writes a piece.

| Output | What |
|---|---|
| `lib/` | every model, collision shape and runtime material once, named by a hash of its content |
| `cells/cell_X_Z.scn` | one scene per 200 m cell: buildings (near, mid), ground, wear marks, props, collision, stalls, lamp anchors |
| `far/far_world.scn` | the far tier of the whole island, always loaded |
| `manifest.json` | which pieces (sha256) each cell came from |

How it gets the draw calls down:
- **Far world:** all far building boxes, tree cards and big far props of the island in a few meshes (2 materials, 1 km
  chunks). Small props (under 2.5 m) get no far version.
- **Texture arrays** (`make_arrays.py` -> `runtime_tex/`): the prop pages, the plant pages and the nine ground textures
  each become one array, so every prop of a batch shares one material, every plant another, the ground a third.
- **Merged batches:** near props per 64 m (models over 1,000 triangles stay instanced), mid props per cell, the
  ground of a cell in one draw, the wear marks of a cell in one draw.
- **Each prop still switches tier at its own distance:** the shaders collapse a prop outside its distance window, so
  a big batch does not pop as a block.
- **Wear level rides with each prop,** so clean / worn / dirty no longer split materials.

### Measured on the sample area (20 street views, same method as the audit)
| | Draw calls (median / worst) | Triangles sent (median / worst) |
|---|---|---|
| Raw pieces, whole city loaded | 942 / 1,412 | 383k / 548k |
| Raw pieces, 300 m radius, no skyline | 126 / 213 | 72k / 112k |
| **Baked: streamed cells + far world (whole skyline)** | **65 / 87** | 329k / 454k |
| Budget (the game's gate, everything included) | 150 | 300k |

- Triangles are above the gate's 300k in the densest views. They are triangles SENT; props outside their distance
  window are collapsed and draw nothing. Finer batches send fewer (down to 179k) but cost draws (up to 128), so per
  Yasin's word the big batches stay. A cut that costs no draws is still open: re-triangulating flat ground.
- Loaded set (12-14 cells + far world): 224 MB video memory (79 textures, 134 meshes).
- A cell loads in 18 ms on average, 46 ms worst (this machine, warm), on a loader thread; it is built on a worker
  thread; adding it to the scene costs at most 1.9 ms on the main thread.
- Drive through the sample (840 m, 14 cells streamed in), cloud machine at about 10 frames a second:
  15 and 30 m/s: no cell late. 60 m/s: no cell late for the near tier (60 m); cells arrived up to 11 m late for the
  mid tier (220 m). A cell takes 0.4 s on average, 1.0 s worst, from request to in-scene here. The streaming distance
  is the same in every direction (load 240 m from the cell's edge, unload 300 m): the 20 m between 240 and 220 is
  the whole margin, 0.67 s at 30 m/s. A forward lead by speed is the fix for fast cars (not built).
- Disk: 79 MB of cells + 14 MB of models for the 32 sample cells. Merging trees is what makes cells big (46 MB with a
  600-triangle merge limit, at about 8 more draws a view).
- `bake_runtime.gd --check`: 32 cells, 0 stale.

### Commands (repo root, real renderer)
```bash
python3 tools/city/bake/make_arrays.py
```
```bash
godot --headless --path . --import
```
```bash
xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/bake/bake_runtime.gd -- --area=60,-600,520
```
`--all` bakes the whole city, `--check` lists cells whose pieces changed since the bake.
Preview and measure: `tools/city/bake/rt_shots.gd` (`--cams`, `--probe --detail`, `--drive`, `--night`, `--lights`,
`--tint`, `--plates`, `--frames`). The streamer the game can use: `tools/city/bake/city_stream.gd`.

## 3. Movement (all in the bake's shaders, `city_kit/shaders/rt`)
- **Wind:** crowns sway, leaves flutter, trunks stay put. Global values `ck_wind_strength`, `ck_wind_dir`. No extra draw.
- **Signals:** red / amber / green cycle on a 30 s clock, cross streets half a cycle apart.
  KNOWN FLAW: the green street-name board on the mast arm has the same green as the lens and lights with it. The
  lens faces need marking (in the kit model, or by the bake; a first try at the bake did not finish).
- **Night:** `ck_night` 0..1. Windows come on bay by bay (the kit's glow mask), each lamp gets a halo and a pool of
  light on the ground (2 draws a cell, hidden by day), and the bake records every lamp as a light anchor.
  `city_lights.gd` puts real lights on the nearest anchors: meant for the light grid (budget 20 of the 32, the rest
  for rooms and cars). The sample pictures use 8 real lights, the stock engine's limit per mesh.
- The interior rooms' light counts (up to 17) are fine with the light grid; no room was changed.

## 4. Tint and shop-name plates (trial, in memory only)
- **Tint:** `rt_bldg.gdshader` takes a paint tint and a wear offset per building (no extra material or draw). The tint
  fades out on dark and on saturated texels, so glass and coloured trims keep their colour. Light trims are tinted
  with the wall.
- **Plates:** `sign_plates.gd` puts a plate 2 cm in front of every painted or blank sign board (rectangles from the
  interiors' `room_contracts.json`), name from a list. 34 plates on the apartments sample. Civic boards that already
  say what the building is are kept.

## Found on the way
- **The cloud preview draws buildings too dark.** The original `bldg_wear.gdshader` renders about 40 % darker on the
  cloud's software GPU in the Mobile renderer than the same shader in OpenGL or Forward+ (0.32 against 0.44 mean).
  One more uniform in the shader and the Mobile result matches the other two. So every cloud shot so far showed
  buildings darker than a real GPU should. The baked city shows the brighter (matching) result. Worth one look on the PC.
- **Most near props have no normal or roughness map bound.** `kit_lib.prop_wear_mat` names its material files by the
  colour atlas only; the first prop to create `pw_props_color_clean_55.tres` was a mid tier (no normal, no ORM), and
  every near prop of that page reuses it. The bake keeps this look. Binding the maps is a look change: Yasin's call.
- With mipmaps, cut-out leaves thin out at a distance. The bake's plant shader corrects it; raw pieces do not.

## Not done
- Whole-city bake and the game side (the game repo's streamer and global shader values).
- Signals: the flaw above. Far buildings do not light their windows at night (the far atlas has no glow mask).
- Far ground: beyond the loaded cells the game's terrain shows, not the roads.
- No phone measurement. Times are from the cloud machine.

## Decisions for Yasin
1. Roll the bake out to the whole city? (`--all`; a few minutes by my estimate, the sample area took 45 s.)
2. Baked data in git, or baked at integration? It is derived and large (about 90 MB for the sample area).
3. Merge limit: 1,000 triangles (65 draws a view, 79 MB of cells) or 600 (about 73 draws, 46 MB)?
4. Wind, night and signals: keep as shown, or change strength / colours first?
5. Tint and plates: roll out to all samples, change the palette or the name lists, or drop?
6. Bind the props' normal and roughness maps (see "Found on the way")?
