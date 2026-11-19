# House furniture and props — progress (Europe/Istanbul)

Plan: `_staging/house/PLAN.md`. Decor first (36), then rugs (8), then furniture (26). Total 70. Page H 1.75 MB, streamed with interiors, not in the 8 MB street cap. Main atlases A/B/C/W and page I are never written. Near+col only. No commits or pushes.

Work root: `/workspace/coronado_kit_v2/_staging/house`.

## Policy

- `tools/h_check.py` is the acceptance test (same rules as indoor `i_check.py`, page H, `props/house/**`).
- Budgets are maximums (tiny 300 / small 600 / medium 1200 / large 2500). Each prop has a target under its cap, with headroom.
- One material, page H only. Opaque kit glass. Collision on every piece. Pivot at the footprint centre, y = 0.
- Plain or blocky is a FAIL against test_ranch.
- One Blender box-wide; yield to the tree rollout. `-t 2`, nice 19, `--python-exit-code 1`. No `/dev/shm`.

## Status

| group | count | status |
|---|---|---|
| Decor | 36 | **36/36 PASS** `h_check` (requires `normalTexture` + `occlusionTexture`). Painted art is on the frames. Detail sheet: `previews/house_decor_detail.jpg`. |
| Rugs | 8 | **8/8 PASS** `h_check`, all `walkable`. Shag is a calm rust pile; floral bake sharpened. Detail: `previews/house_rugs_detail.jpg` (07:58 Europe/Istanbul). |
| Furniture | 26 | **26/26 PASS**. Case tops closed (carcass + overhang). Nightstand, toilet, enamel clawfoot tub, 1950s fridge, upper cabinet crown/gap/knobs fixed. Detail: `previews/house_furniture_detail.jpg` (08:01 Europe/Istanbul). |
| **Total** | **70** | **70/70 PASS** `h_check`. Nothing pushed. |

Page H runtime: 1024 colour / 512 normal / 256 ORM = **1.75 MB**. Street A+B+C+grime+W unchanged at 7.583 / 8 MB.

## Materials: occlusionTexture (glTF ORM)

`fix_glb` in `kit/props/_tools/pg.py` now writes all three maps on every house near material:

```
normalTexture            index 1
metallicRoughnessTexture index 2
occlusionTexture         index 2   # same ORM texture; AO in R
```

`tools/h_check.py` **FAIL**s a near glb that is missing `normalTexture` or `occlusionTexture`, or whose occlusion index does not match the ORM (`metallicRoughnessTexture`). All 36 existing decor near glbs were JSON-patched (no mesh rebuild) at 06:20 and passed 36/36 including the new checks. Future exports get the field from `fix_glb`.

AO confirmation (do not treat page H as flat-white overall):

- Unique bake tiles pack ORM as **R = Cycles AO**, G = roughness, B = metallic. Sampled bake slots have real variation (e.g. `frame_print_medium` R 0–233, std ~70; globe and bookends similar).
- Trim-tile ORM R is only subtle cavity AO from height (walnut ~242–255, std ~2). The composed 256 ORM R is min 0 / max 255 / mean ~228 because the bake slots darken it.
- Vertex AO is in **COLOR_0** (`Col`, VEC4 uint16 normalized) and is multiplied into base colour. Example: bookends min 0.015 / max 1.0 / mean 0.461 / std 0.335. Model shading AO is primarily COLOR_0; ORM R is real on unique and art slots, weak on trims.

## Art bank (page H, y=512–1023)

Eight painterly / poster works live in the reserved band and are composited into this kit’s page H only (`previews/house_art_bank.jpg`):

| key | subject | frame |
|---|---|---|
| `art_seascape` | beach horizon, sun glow, foam, wet sand | `frame_ocean` |
| `art_hotel` | Hotel del–style white body, red conical turrets | `frame_print_large` |
| `art_palms` | sunset silhouettes | `frame_print_tall` |
| `art_mcm` | mid-century abstract (navy / olive / coral / sun) | `frame_mcm_abstract` |
| `art_botanical` | fern botanical print | `frame_print_medium` |
| `art_surf` | CORONADO / SURF poster | `frame_print_small` |
| `art_floral` | motel floral | `frame_motel_floral` |
| `art_portrait` | mid-century bust portrait | `frame_stand_photo` |

Each frame now uses one inset `art_*` decal quad (stretch-fit, paper mat). JIT / trim tint skips `art_` faces so the paintings are not randomly multiplied. `tools/h_detail.py` will render `previews/house_decor_detail.jpg` (3/4, ~80 % fill, no figure) after the frame rebuild.

## Budget raises (all still under the class cap)

| prop | class | was | now | cap | near | why |
|---|---|---:|---:|---:|---:|---|
| clock_mantel | small | 400 | 520 | 600 | 502 | chamfer already off; kept the case, feet, face and glass |
| bowl_shell | tiny | 220 | 260 | 300 | 242 | lip lobes; under cap with headroom |
| figurine_horse | tiny | 280 | 290 | 300 | 282 | silhouette kept; 10 tris of cap headroom |

Cuts (stayed on the original target): `clock_wall_sunburst` 664→504 / 550 (12 rays); `vase_lava` 336→256 / 260 (five lumps); `candle_pair_brass` 308→212 / 280.

## Decor results (near tris / target)

| prop | class | near | budget | notes |
|---|---|---:|---:|---|
| frame_print_small | tiny | 218 | 250 | PASS |
| frame_print_medium | small | 310 | 400 | PASS |
| frame_print_large | small | 304 | 500 | PASS |
| frame_print_tall | small | 310 | 400 | PASS |
| frame_ocean | small | 390 | 450 | PASS |
| frame_mcm_abstract | small | 302 | 450 | PASS |
| frame_motel_floral | small | 433 | 450 | PASS |
| frame_stand_photo | tiny | 209 | 220 | PASS after origin shift |
| mirror_round | small | 514 | 550 | PASS |
| mirror_rect | small | 364 | 500 | PASS |
| clock_wall_sunburst | small | 504 | 550 | PASS (col hull lifted onto y=0; builder start raised for the next mesh rebuild) |
| clock_mantel | small | 502 | 520 | PASS |
| vase_tall | small | 224 | 350 | PASS |
| vase_bud | tiny | 176 | 180 | PASS |
| vase_ginger | small | 232 | 400 | PASS |
| vase_lava | tiny | 256 | 260 | PASS |
| bowl_ceramic | tiny | 186 | 250 | PASS |
| bowl_wood | tiny | 210 | 250 | PASS |
| bowl_shell | tiny | 242 | 260 | PASS |
| decorative_tray | tiny | 216 | 220 | PASS |
| candle_pair_brass | tiny | 212 | 280 | PASS |
| candle_pillar | tiny | 108 | 180 | PASS |
| hurricane_lamp | small | 282 | 400 | PASS |
| figurine_bird | tiny | 190 | 260 | PASS |
| figurine_cat | tiny | 224 | 280 | PASS |
| figurine_horse | tiny | 282 | 290 | PASS |
| statue_bust | small | 236 | 450 | PASS |
| sculpture_organic | small | 144 | 450 | PASS |
| sculpture_coral | tiny | 170 | 280 | PASS |
| wall_plate_fish | tiny | 224 | 250 | PASS |
| wall_plate_floral | tiny | 246 | 250 | PASS |
| bookends | small | 416 | 450 | PASS |
| globe_desktop | small | 500 | 550 | PASS |
| books_stack | tiny | 228 | 250 | PASS |
| decanter | tiny | 154 | 280 | PASS |
| woven_basket | small | 238 | 400 | PASS |

Sheets: `previews/house_decor_sheet.png`, `previews/house_decor_closeup.jpg`.

## Render review (06:13, self)

- Frames read clearly: mid-century colour fields, ocean horizon, gilt motel floral, tall stacked fields. Walnut and wash mouldings, mats and hanging wire are visible.
- Sunburst clock and mantel clock both read at a glance. Round rattan mirror and rect walnut mirror work; rattan was too dark and has been lightened in the atlas (no mesh rebuild).
- Bookends, globe, books_stack, decanter, hurricane lamp and the vase set are the strongest table pieces.
- Figurines and sculptures are correctly small (16–32 cm) and have readable silhouettes; they look modest next to the 1.8 m figure, which is right.
- The official four-side sheets include the 1.8 m figure, so the tiny pieces look like dots in the wide strip; the close-up sheet is the one to judge them by.

## Log

- 19 Nov 2026 05:58 Europe/Istanbul: Plan written. House staging kit created. Page H pipeline copied from indoor and pointed at this kit only. Tree Blender was running (`tree_ficus_laurel`); wrote trims and the decor builder first.
- 06:01 Page H trims composed (walnut, wash, paint, linen, metal, brass, ceramic, glass, rattan, stone + swatches). 1.75 MB.
- 06:05 First Blender pass failed: unique-area 0 (maker plates used a trim key) then missing `badge.clean` swatch. Fixed (badge swatch, unique plate on every piece). Basket rebuilt as a solid rattan vessel after an over-budget cage.
- 06:06–06:11 Full decor build, 36/36 meshes written, 29/36 first `h_check`. Failures: origin on the standing photo, four over-budget, two over class cap, later two leftover.
- 06:14 Rebuilt seven; 34/36 then 35/36 after raising `figurine_horse` to 290. `clock_wall_sunburst` collision starts 3 cm low once the wall-mount shift is applied; hull start raised in the builder. Tree Blender (`tree_monterey_cypress`) has the box; rebuild is queued.
- 06:15 Rattan tile lightened (cane holes were reading almost black). Atlas recomposed with the 35 existing bake tiles. Main A/B/C/W and page I not written. Nothing pushed.
- 06:17 `clock_wall_sunburst` collision lifted 3 cm onto y=0 so the wall-mount shift no longer buries the hull. **36/36 PASS** `h_check`. The builder start point is already raised for a later clean mesh rebuild. Nothing pushed.
- 06:20 `fix_glb` writes `occlusionTexture` index 2 (same ORM as `metallicRoughnessTexture`). `h_check` now fails a near glb missing `normalTexture` or `occlusionTexture`, or with a mismatched occlusion index. All 36 decor near glbs JSON-patched; **36/36 PASS**. ORM R holds baked AO on unique tiles (not flat white); COLOR_0 carries vertex AO. Confirmed by sampling glbs and the composed ORM.
- 06:23–06:26 Page H art bank painted (8 works) and composited. Preview: `previews/house_art_bank.jpg`. Seascape, hotel, surf, floral and portrait were tightened after a first pass that read as clip-art.
- 06:29 Frames switched from colour-block quads to `art_*` decal panels; JIT skip added in `cond_colors`. Stale frame bake tiles deleted. Frame rebuild is queued — an `ao_link` Blender compare (`render_ao_compare.py`) currently has the box. `tools/h_detail.py` is ready for the 80 % close-up sheet once Blender is free. Nothing pushed.
- 06:33 Replaced the procedural art bank with Yasin’s 8 painted works in `art_src/` (seascape, hotel, palms, mcm, botanical, surf, floral, portrait). Cropped each to its frame opening aspect, packed by on-screen importance (long side 128–256 px) into the y=512–1023 band. Oils (seascape, palms, floral, portrait) got canvas weave in the normal + ORM roughness; glazed prints (hotel, mcm, botanical, surf) got low ORM roughness with a soft glass sheen. Page H stays **1.75 MB**.
- 06:37 Eight frames rebuilt onto the painted decals. Mapping: `frame_ocean`→seascape, `frame_print_large`→hotel, `frame_print_tall`→palms, `frame_mcm_abstract`→mcm, `frame_print_medium`→botanical, `frame_print_small`→surf, `frame_motel_floral`→floral, `frame_stand_photo`→portrait. **36/36 PASS** `h_check`.
- 06:43 `previews/house_decor_detail.jpg` (3/4, ~80 % fill, no figure). Art and most table pieces read well (candles, bookends, basket, decanter, clocks, botanical/hotel/surf prints). Weak on the sheet: `statue_bust` did not read as a head, `wall_plate_fish` was abstract blocks, `bowl_ceramic` was a faceted puck, `globe_desktop` continents were square patches, `mirror_round` glass showed a UV starburst, frame hang tabs read as corner caps, tray maker-plate sat in the well. Rebuild of those (plus all 8 frames for the smaller hang hardware) is in flight at 06:46. Nothing pushed.
- 06:42 Rug pattern bands painted into the reserved page-H strip (y=192–255, x=256–1023): mcm, jute, floral panel, runner, accent, round medallion, terry, shag. Preview `previews/house_rug_bands.jpg`. `b_hrugs.py` (8 walkable rugs) is ready to build when Blender is free. Nothing pushed.
- 06:48 Weak-prop rebuild PASS (mirror glass no longer a UV fan; fish plate reads as a fish; bust is a stylised head and shoulders; globe continents are irregular masses; hang tabs shrunk). Opened the ceramic bowl lip (176 / 250) after the first rebuild still capped the well. **36/36 decor PASS**.
- 06:54 Eight rugs built on page H (`b_hrugs.py`), thin walkable collision, origin at the footprint centre. `rug_living_mcm` budget raised 450→480 (near 460, under cap 600) for short fringe. **8/8 PASS** and **44/44** house props PASS `h_check` (normal + occlusion required). Sheet paths: `previews/house_decor_detail.jpg`; rug close-ups rendering into `previews/house_rugs_detail.jpg`. Nothing pushed.
- 06:55 Detail sheets written: `previews/house_decor_detail.jpg`, `previews/house_rugs_detail.jpg`. Ceramic bowl now shows an open teal well. Rugs read as eight distinct patterns; shag pile is flatter in albedo than the others. 26 furniture pieces are next. Nothing pushed.

- 07:06 Europe/Istanbul: Yasin review pass started (figurines, hang tabs, rug camera / jute / shag / mcm). Budgets unchanged. Hang hardware is now a thin wire fully on the back (no D-ring or bumper boxes); frame_shell verticals sit between the rails so end-caps cannot read as corner tabs. Figurines, bust, coral and bowl_shell rewritten to spend remaining tris on smoother curves (seated cat, MCM horse with thick tapered legs, scallop dish, tapered coral forks). MCM rug is a one-shot bordered motif (slot 90×64, aspect ~1.41); jute normal has a 4-rib basket weave; shag has explicit pile clumps plus a soft geometric skirt. `h_detail.py` uses a 52° pitch on wide flat props and accepts `--batch` / `--out` / `--title`. `b_hfurn.py` (26 pieces) is written. Tree Blender (`tree_ficus_laurel`) still has the box; polish rebuild + furniture are queued. Nothing pushed.

- 07:36 Europe/Istanbul: Review fixes + 26 furniture are in. Budgets unchanged. Hang hardware is a thin back-only wire; frame corners no longer read as black tabs (confirmed on the 3/4 tiles). Figurines/bust/coral/shell rewritten for smoother silhouettes; horse 290/290, bird 248/260, cat 272/280, bust 412/450, coral 222/280, shell 172/260. MCM rug is a one-shot bordered motif; jute has a visible basket-weave normal; shag has pile-height clumps and a soft skirt. Rug sheet camera uses a 52° pitch. Page H bake area was full at 64×64 in y=256–511 (64 slots); opened the unused y=960–1023 strip (art ends at y=952) for the last six furniture slots. **70/70 PASS** `h_check` (36 decor + 8 rugs + 26 furniture), all at or under budget, normal + occlusion present. Furniture sheet: `previews/house_furniture_detail.jpg`. Also refreshed `previews/house_decor_detail.jpg` and `previews/house_rugs_detail.jpg`. Nothing pushed.

- 08:02 Europe/Istanbul: Furniture review-bug pass. Budgets unchanged, nothing pushed. Root cause of the "open / dark front" case pieces was coplanar carcass+lid faces (unique-bake AO punched black holes on the top), not missing faces or flipped normals. `carcass()` now builds a body with `skip=('top',)` and a slightly overhanging lid; doors sit proud via `door_y()`. Nightstand is one MCM box + drawer on tapered legs. Toilet rebuilt as a close-coupled white enamel (pedestal, bowl, seat, lid, tank on the deck). Bathtub is white enamel clawfoot (new `th_enamel` / `th_enamel_in` trims, R=28/14) with brass feet; no longer reads as stone. Fridge is a 1950s rounded cream cabinet with a split freezer door, chrome latch handles, and a single closed lid (the first multi-strip top still failed the AO-hole check at 20%; the one-piece lid bakes clean, `top_ao_dark=0`). Upper cabinet gained a door gap, knobs and a stepped crown. `rug_shag_oval` is a solid rust shag with a pile normal; `rug_motel_floral` slot widened and leaf/bloom falloff sharpened (still a little soft at 160×64 on a large rug). `h_check` now fails flipped normals (>15% area), an open/missing case top (<0.55×footprint), and a dark-AO case top (AO<0.30 on >18% of upward top verts, gate is now ≥4 verts so simple lids are included). `run.py` copies `defn['case']`. **70/70 PASS** `h_check`. Sheets: `previews/house_furniture_detail.jpg`, `previews/house_rugs_detail.jpg`. Floor lamp left light, as requested. Leftover visual notes: bathtub feet are simple brass pegs rather than ornate claws; toilet is readable but still a bit faceted (548/900); fridge chrome handles are thin; floral is sharper than before but not crisp.

- 08:29 Europe/Istanbul: Leftover polish while the push is on hold. Budgets unchanged, nothing pushed. Bathtub feet are now stylised brass claws (ball + 3 toes). Toilet bowl segs 16→20, tank is a rounded-rect with a single lid; chamfer aimed at ~750 (`ch_fill=0.84`, budget still 900) and landed at 750/900. Fridge chrome latch handles are thicker and stand off the doors with a backplate (926/1100). `rug_motel_floral` is no longer a blurry one-shot: the 160×64 band slot is unchanged (so neighbouring rugs did not shift) but the motif now tiles at 0.45×0.40 m with hard leaf/bloom edges, and a mesh bind carries the border. Page H stays 1024/512/256 = 1.75 MB. **70/70 PASS** `h_check`. Sheets: `previews/house_furniture_detail.jpg`, `previews/house_rugs_detail.jpg`. Also refreshed `previews/house_rug_bands.jpg`.
