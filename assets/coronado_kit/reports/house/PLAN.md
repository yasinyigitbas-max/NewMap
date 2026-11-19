# Coronado household furniture and props — plan

Work root: `/workspace/coronado_kit_v2/_staging/house`.
Build order is fixed: **decor first**, then **carpets and rugs**, then **the rest of the house furniture**.
Nothing here is committed or pushed until Yasin approves.

This set dresses the interiors of Coronado houses (ranch, Craftsman, Spanish, mid-century, beach cottage, dingbat/motel apartment). It is built to the same indoor rules as the 62 shop props on page I. Shop props are not renamed or overwritten; residential pieces get their own names.

## Policy (same as indoor, plus house notes)

- Tiers: **near + col only**. No mid, no far.
- Acceptance: `tools/h_check.py` (same checks as `i_check.py`, pointing at this kit and page H).
- One mesh, one material, one draw call per prop. Page H only. Opaque kit glass (`th_glass`). No alpha.
- Origin at the **bottom centre of the footprint**, ground at y = 0, front faces +Z (glTF; builders use Blender −Y). Real-world scale (person 1.8 m).
- Wall-hung pieces (frames, mirrors, clock, wall plates) sit on y = 0 at the **bottom of the frame**, back flush, same as `gallery_frame`. The level places them at hanging height (~1.45–1.55 m to centre).
- Collision on every prop: one box, or one cylinder for round pieces. Rugs get a thin box and must be flagged **walkable** in the game (no character collision).
- Class caps are hard maximums: tiny 300, small 600, medium 1200, large 2500. The **tri target** for each prop is below its cap, with headroom. A raise is allowed only up to the class cap and must be logged.
- Plain or blocky is a FAIL (detail floor: `test_ranch`). Spend triangles on silhouette; bevels, hardware, lettering, weave and art go into geometry or the normal / colour bake.
- Never overwrite main atlases A / B / C / W, the main `props_atlas.json`, or page I. Do not touch `/dev/shm`.
- One Blender box-wide, `-t 2`, `nice 19`, `--python-exit-code 1`. Yield to the tree rollout.

## Interior design (rooms as sets, not a junk drawer)

Three palettes, used together in a house or apartment, never all jumbled in one room:

| Palette | Where it lives | Materials and colour |
|---|---|---|
| **Mid-century** (c. 1955–70) | ranch and MCM houses, nicer apartments | walnut and teak, mustard, olive, burnt orange, cream, polished brass, white ceramic, smoke glass |
| **Beach-casual** | cottages, craftsman/Spanish near the water, shops and cafes | whitewashed wood, rattan and seagrass, sea-glass aqua, sand, coral, linen, weathered paint |
| **Motel / dingbat** | older apartments, dated rooms, some store windows | gilt rococo frames, faded floral, lava-glaze ceramic, wood-tone plastic, smoked glass, gold anodised |

Pieces are written so a living room can be dressed as one of these three. The same decor also works in gift shops, galleries, furniture stores, hotel lobbies and cafes (Yasin: homes **and** stores).

Clearances to respect when the furniture is built and when rooms are laid out:

- Walkway past a sofa or bed: ≥ 0.45 m. Coffee table 0.40–0.45 m in front of the sofa.
- Dining: 0.70–0.75 m behind a pulled-out chair; table seating at 0.60 m per person.
- Kitchen counter height 0.90 m, island stool knee space 0.30 m, fridge door swing clear.
- Bedroom: nightstand flush to the head of the bed; lamp switch reachable from the mattress.
- Bathroom: 0.60 m clear in front of the toilet and the vanity.

## Texture plan — new page H (recommended)

Page I is already the shop atlas (62 props, trim row 0, goods bands, bake slots from y = 256, ~343k px still free). Cramming house walnut, rattan, ceramic, gilt and rug patterns onto I would risk a rebake of the shop set and still be tight.

**New page H**, same recipe as I and W:

| Map | Size | ASTC 4x4 + mips |
|---|---|---|
| Colour | 1024 | 1.333 MB |
| Normal | 512 | 0.333 MB |
| ORM | 256 | 0.083 MB |
| **Total** | | **1.75 MB** |

- Streamed with interiors only. **Not** part of the 8 MB street-resident cap.
- Street pages A + B + C + grime + W stay at **7.583 / 8 MB**.
- Interior streamed total becomes I 1.75 + H 1.75 = **3.50 MB** when a scene has both shops and homes (or a shop that instances this decor).
- Files live only under this kit: `kit/atlases/props_h_{color_clean,normal,orm}.png` and this kit's `props_atlas.json`.
- Trim tiles at 128 px/m (inner 112 px = 0.875 m). Row y = 0: `th_walnut`, `th_wash`, `th_paint`, `th_linen`, `th_metal`, `th_brass`, `th_ceramic`, `th_glass`. Row y = 128: `th_rattan`, `th_stone`, plus tint swatches for the high-poly bake. Rows y = 160–255 reserved for rug pattern bands. Bake slots from y = 256.
- Vertex-colour tints give walnut→teak, paint→mustard/olive/coral, linen→sand, ceramic glazes, etc.

**Decision for Yasin (does not block the build):** shops that place these decor pieces will need to stream page H as well as I. The other option is to extend I later; that is not the first build.

## Build order

1. **Decor (36)** — this batch, first. Report when 30+ pass `h_check`.
2. **Carpets and rugs (8).**
3. **House furniture (26),** room by room: living, kitchen, dining, bedroom, bathroom, laundry, garage.
4. Contact sheets per category, self-review, budget table, then wait for a push OK.

Total planned set: **70 props**.

Every prop's acceptance checklist (also used in `PROGRESS.md`):

- [ ] `h_check` PASS (naming, near+col, one mesh / one material, page H, origin, ground)
- [ ] near tris ≤ this prop's target, and ≤ class cap, with headroom
- [ ] collision present (one box or one cylinder; rugs thin + walkable flag)
- [ ] not plain or blocky in the hero / sheet (silhouette, hardware, bevels, art or weave)

---

## 1. Decor (36) — homes and stores

Wall pieces: origin at the bottom-centre of the frame. Table pieces sit on the floor (or a table, once placed).

### Framed prints and paintings

| prop | palette | footprint w×d, h (m) | class | target | cap | collision | What keeps it from reading blocky | reuse / pair |
|---|---|---|---|---:|---:|---|---|---|
| frame_print_small | shared | 0.28 × 0.045, 0.36 | tiny | 250 | 300 | 1 box (thin) | hollow moulding, inner step, white mat, designed print, D-rings and hanging wire | same frame language as the other prints |
| frame_print_medium | shared | 0.50 × 0.050, 0.65 | small | 400 | 600 | 1 box | same, wider mat, signature line | pairs with small / tall on a wall |
| frame_print_large | shared | 0.90 × 0.055, 0.70 | small | 500 | 600 | 1 box | landscape moulding, two hangers | over a sofa or shop wall |
| frame_print_tall | shared | 0.40 × 0.050, 0.90 | small | 400 | 600 | 1 box | portrait, stacked with medium | hallway pair |
| frame_ocean | beach | 0.70 × 0.050, 0.50 | small | 450 | 600 | 1 box | weathered wash frame, horizon bands, sun, shore | with rattan mirror, shell bowl |
| frame_mcm_abstract | MCM | 0.60 × 0.050, 0.60 | small | 450 | 600 | 1 box | walnut + brass corner keys, colour-field print | with sunburst clock, organic sculpture |
| frame_motel_floral | motel | 0.45 × 0.055, 0.55 | small | 450 | 600 | 1 box | gilt rococo outer, faded floral, linen mat | with lava vase, gold photo |
| frame_stand_photo | motel / shared | 0.16 × 0.10, 0.20 | tiny | 220 | 300 | 1 box | easel back, gilt or walnut edge, photo mat | nightstand, shop counter |

### Mirrors and clocks

| prop | palette | footprint w×d, h (m) | class | target | cap | collision | Detail | pair |
|---|---|---|---|---:|---:|---|---|---|
| mirror_round | beach / MCM | 0.62 × 0.070, 0.62 | small | 550 | 600 | 1 cyl | rattan wrap or brass sunburst rim, opaque glass with a window reflection, hanging loop | over a credenza or shop wall |
| mirror_rect | shared | 0.50 × 0.060, 0.80 | small | 500 | 600 | 1 box | stepped wood frame, bevel painted in the colour, D-rings | hall, bedroom, clothing shop |
| clock_wall_sunburst | MCM | 0.55 × 0.080, 0.55 | small | 550 | 600 | 1 cyl | brass rays, enamelled face, ticks, hands, hub nut, stem | living room or boutique |
| clock_mantel | motel / shared | 0.28 × 0.12, 0.32 | small | 400 | 600 | 1 box | wood case, brass feet, convex glass, face and hands | mantel, motel dresser |

### Vases, bowls, trays

| prop | palette | footprint w×d, h (m) | class | target | cap | collision | Detail | pair |
|---|---|---|---|---:|---:|---|---|---|
| vase_tall | MCM | 0.18 × 0.18, 0.42 | small | 350 | 600 | 1 cyl | foot, belly, neck, rolled lip, glaze band | credenza pair with bud vase |
| vase_bud | beach | 0.08 × 0.08, 0.16 | tiny | 180 | 300 | 1 cyl | pinched neck, sea-glass tint, tight lip | shelf, cafe table |
| vase_ginger | shared | 0.22 × 0.22, 0.28 | small | 400 | 600 | 1 cyl | lid and finial, shoulder, glaze | dining sideboard |
| vase_lava | motel | 0.16 × 0.16, 0.26 | tiny | 260 | 300 | 1 cyl | fat lava glaze lumps on the shoulder, dark well | motel dresser |
| bowl_ceramic | beach | 0.28 × 0.28, 0.10 | tiny | 250 | 300 | 1 cyl | foot ring, thick rim, interior glaze | coffee table |
| bowl_wood | MCM | 0.32 × 0.32, 0.09 | tiny | 250 | 300 | 1 cyl | turned rings, heartwood tint at the well | coffee table, shop display |
| bowl_shell | beach | 0.24 × 0.18, 0.08 | tiny | 220 | 300 | 1 box | abalone lip, iridescent well (opaque) | with ocean print |
| decorative_tray | shared | 0.36 × 0.24, 0.04 | tiny | 220 | 300 | 1 box | gallery rail, brass handles, inset | coffee table, shop counter |

### Candles

| prop | palette | footprint w×d, h (m) | class | target | cap | collision | Detail | pair |
|---|---|---|---|---:|---:|---|---|---|
| candle_pair_brass | MCM | 0.22 × 0.10, 0.28 | tiny | 280 | 300 | 1 box | two heights, faceted stems, wax drip, wick, felt pads | mantel with sunburst clock |
| candle_pillar | shared | 0.12 × 0.12, 0.16 | tiny | 180 | 300 | 1 cyl | melted crown, wick, saucer | tray or tub edge |
| hurricane_lamp | beach | 0.16 × 0.16, 0.32 | small | 400 | 600 | 1 cyl | glass chimney (opaque), brass gallery, handle, candle | porch table, cafe |

### Figurines, statues, sculptures

| prop | palette | footprint w×d, h (m) | class | target | cap | collision | Detail | pair |
|---|---|---|---|---:|---:|---|---|---|
| figurine_bird | beach | 0.14 × 0.10, 0.16 | tiny | 260 | 300 | 1 box | shorebird: beak, eye, legs, tail, glazed base | shelf, gift shop |
| figurine_cat | MCM | 0.12 × 0.08, 0.22 | tiny | 280 | 300 | 1 box | stylised seated cat, ears, collar, walnut base | credenza |
| figurine_horse | motel | 0.18 × 0.08, 0.16 | tiny | 280 | 300 | 1 box | rearing ceramic, mane, gilt hooves, oval base | motel dresser |
| statue_bust | motel / shared | 0.16 × 0.14, 0.32 | small | 450 | 600 | 1 box | plaster head and shoulders, socle, name plate | landing, shop window |
| sculpture_organic | MCM | 0.18 × 0.14, 0.28 | small | 450 | 600 | 1 box | biomorphic walnut / stone, pierced hole, plinth | with abstract print |
| sculpture_coral | beach | 0.16 × 0.14, 0.22 | tiny | 280 | 300 | 1 box | branch silhouette, foot, sand-coloured plinth | with shell bowl |

### Wall plates, books, globe, other clutter

| prop | palette | footprint w×d, h (m) | class | target | cap | collision | Detail | pair |
|---|---|---|---|---:|---:|---|---|---|
| wall_plate_fish | beach | 0.28 × 0.05, 0.28 | tiny | 250 | 300 | 1 cyl | rim, well, painted fish motif, wire hanger | kitchen or cafe wall |
| wall_plate_floral | motel | 0.24 × 0.05, 0.24 | tiny | 250 | 300 | 1 cyl | gilt rim, floral well, hanger | with motel floral frame |
| bookends | MCM | 0.28 × 0.16, 0.22 | small | 450 | 600 | 1 box | brass horse or block ends, 3–4 bound books with spines and labels | credenza, bookshop |
| globe_desktop | MCM | 0.22 × 0.22, 0.36 | small | 550 | 600 | 1 cyl | meridians, axis, claw feet, ocean/land in colour fields, cartouche | desk, study, shop |
| books_stack | shared | 0.22 × 0.18, 0.14 | tiny | 250 | 300 | 1 box | three offset books, spines, headbands, bookmark | table, nightstand |
| decanter | MCM | 0.12 × 0.12, 0.28 | tiny | 280 | 300 | 1 cyl | stopper, neck ring, faceted body, pour lip | sideboard, bar |
| woven_basket | beach | 0.28 × 0.28, 0.22 | small | 400 | 600 | 1 cyl | woven bands, rim wrap, two handles | living, laundry later, shop |

Decor subtotal: **36 props**.

---

## 2. Carpets and rugs (8)

Thin floor pieces, origin at the centre of the cloth, pile height 1.5–4 cm (shag a little taller). Collision is a thin box; **game must mark walkable**. Patterns go on reserved page-H bands (y = 160–255), not on street atlases.

| prop | palette | footprint w×d, h (m) | class | target | cap | collision | Detail |
|---|---|---|---|---:|---:|---|---|
| rug_living_mcm | MCM | 2.40 × 1.70, 0.025 | small | 450 | 600 | thin box, walkable | geometric field, bound edge, short fringe |
| rug_living_jute | beach | 2.00 × 1.40, 0.020 | small | 400 | 600 | thin box, walkable | woven jute, stitched edge |
| rug_motel_floral | motel | 1.80 × 1.20, 0.020 | small | 400 | 600 | thin box, walkable | faded floral, dark border |
| rug_runner | shared | 2.40 × 0.70, 0.018 | small | 350 | 600 | thin box, walkable | hall runner, end fringe |
| rug_accent | shared | 1.20 × 0.80, 0.018 | tiny | 250 | 300 | thin box, walkable | small sitting-room rug |
| rug_round | beach / MCM | 1.50 × 1.50, 0.020 | small | 450 | 600 | thin cyl, walkable | round, bound edge |
| bath_mat | shared | 0.80 × 0.50, 0.025 | tiny | 200 | 300 | thin box, walkable | terry texture in the normal, hem |
| rug_shag_oval | motel | 1.60 × 1.10, 0.040 | small | 450 | 600 | thin box, walkable | taller pile silhouette, oval |

---

## 3. House furniture (26)

Residential pieces, not replacements for shop fixtures. The shop `washer` / `dryer` stay coin-op; the house gets `washer_home` / `dryer_home`. Do not rebuild yard `patio_set_4`, `bbq_*`, or `adirondack_*`.

Tri targets stay under the class cap. Large case goods (sofa, bed, fridge, range, bathtub) are **medium** (cap 1200) unless a silhouette truly needs large (cap 2500) — only then, and logged.

### Living

| prop | palette | footprint w×d, h (m) | class | target | cap | collision | Detail / pairs |
|---|---|---|---|---:|---:|---|---|
| sofa_3seat | MCM / beach (tint) | 2.10 × 0.90, 0.86 | medium | 1100 | 1200 | 1 box | tapered legs, welt, cushions, back piping; pairs with lounge_chair + ottoman + coffee_table |
| lounge_chair | MCM | 0.78 × 0.85, 0.92 | medium | 900 | 1200 | 1 box | angled back, open arms, seat cushion; faces the coffee table |
| ottoman | MCM | 0.70 × 0.55, 0.42 | small | 500 | 600 | 1 box | matching welt and legs |
| coffee_table | MCM | 1.20 × 0.60, 0.40 | small | 550 | 600 | 1 box | walnut top, lowered shelf, brass caps |
| side_table | shared | 0.50 × 0.50, 0.55 | small | 500 | 600 | 1 box | or 1 cyl if round; holds table_lamp_living |
| credenza | MCM | 1.80 × 0.45, 0.75 | medium | 1100 | 1200 | 1 box | sliding doors, tapered legs, pulls; under the sunburst clock |
| floor_lamp | MCM | 0.45 × 0.45, 1.55 | small | 550 | 600 | 1 cyl | tripod or disc base, brass stem, cone shade |
| tv_console | shared | 1.20 × 0.40, 0.55 | medium | 900 | 1200 | 1 box | doors, vents, cable slot; under tv_crt |

### Kitchen

| prop | palette | footprint w×d, h (m) | class | target | cap | collision | Detail / pairs |
|---|---|---|---|---:|---:|---|---|
| fridge_home | shared | 0.76 × 0.80, 1.70 | medium | 1100 | 1200 | 1 box | door gasket, handle, badge, vent, feet (not the shop drinks fridge) |
| range_gas | shared | 0.76 × 0.66, 0.92 | medium | 1100 | 1200 | 1 box | four grates, knobs, oven window (opaque), handle |
| sink_base | shared | 1.20 × 0.62, 0.90 | medium | 1100 | 1200 | 1 box | doors, farm or drop-in sink, faucet, drip rail |
| upper_cabinet | shared | 0.80 × 0.32, 0.70 | medium | 800 | 1200 | 1 box | wall-hung (pivot at bottom), two doors, inset panels, knob |

### Dining

| prop | palette | footprint w×d, h (m) | class | target | cap | collision | Detail / pairs |
|---|---|---|---|---:|---:|---|---|
| dining_table | shared | 1.50 × 0.90, 0.75 | medium | 900 | 1200 | 1 box | apron, tapered or turned legs; seats four chairs facing in |
| dining_chair | shared | 0.46 × 0.52, 0.86 | small | 550 | 600 | 1 box | seat pad, back slats or hoop; pairs with the table |
| sideboard | shared | 1.60 × 0.45, 0.85 | medium | 1100 | 1200 | 1 box | drawers, doors, legs; holds ginger jar and decanter |

### Bedroom

| prop | palette | footprint w×d, h (m) | class | target | cap | collision | Detail / pairs |
|---|---|---|---|---:|---:|---|---|
| bed_queen | shared | 1.70 × 2.15, 1.05 | medium | 1100 | 1200 | 1 box | headboard, rails, two pillows, coverlet fold, turned or tapered legs |
| nightstand | shared | 0.50 × 0.40, 0.58 | small | 500 | 600 | 1 box | drawer, pull, shelf; flush to the headboard, one each side |
| dresser | shared | 1.30 × 0.50, 0.80 | medium | 1100 | 1200 | 1 box | six drawers, pulls, mirror-optional (use mirror_rect above) |

### Bathroom

| prop | palette | footprint w×d, h (m) | class | target | cap | collision | Detail / pairs |
|---|---|---|---|---:|---:|---|---|
| toilet | shared | 0.52 × 0.70, 0.80 | medium | 900 | 1200 | 1 box | lid, seat, tank, supply, flush lever |
| vanity_sink | shared | 0.90 × 0.50, 0.88 | medium | 1000 | 1200 | 1 box | bowl, faucet, doors, legs or kick |
| bathtub | shared | 1.70 × 0.75, 0.58 | medium | 1100 | 1200 | 1 box | rolled rim, feet or apron, spout, overflow |

### Laundry

| prop | palette | footprint w×d, h (m) | class | target | cap | collision | Detail / pairs |
|---|---|---|---|---:|---:|---|---|
| washer_home | shared | 0.68 × 0.70, 0.95 | medium | 1000 | 1200 | 1 box | home front- or top-load, glass (opaque), badge, soap door — not the shop coin-op |
| dryer_home | shared | 0.68 × 0.70, 0.95 | medium | 1000 | 1200 | 1 box | lint door, matching badge, vent cuff |
| laundry_hamper | shared | 0.40 × 0.40, 0.58 | small | 400 | 600 | 1 cyl or box | ventilated sides or woven, lid |

### Garage / patio (indoor-adjacent only)

| prop | palette | footprint w×d, h (m) | class | target | cap | collision | Detail / pairs |
|---|---|---|---|---:|---:|---|---|
| storage_cabinet | shared | 0.90 × 0.45, 1.80 | medium | 1000 | 1200 | 1 box | metal or painted wood, handles, vents |
| workbench_garage | shared | 1.50 × 0.60, 0.90 | medium | 1000 | 1200 | 1 box | wood top, vice block, lower shelf — distinct from the shop workbench |

Yard BBQ, patio set and Adirondacks already exist; they are not rebuilt.

---

## Totals and memory

| Batch | Count | When |
|---|---:|---|
| Decor | 36 | first |
| Rugs | 8 | second |
| Furniture | 26 | third |
| **Set** | **70** | |

| Texture | Runtime | Cap |
|---|---|---|
| Street A+B+C+grime+W | 7.583 MB | 8 MB street (unchanged) |
| Page I (shops, already shipped) | 1.75 MB | streamed interiors |
| **Page H (this set)** | **1.75 MB** | streamed interiors |
| Interiors I+H together | 3.50 MB | not in the street cap |

## Decisions for Yasin (build is not blocked)

1. **New page H at 1.75 MB**, streamed with interiors, rather than extending page I. Shops that instance this decor will also load H.
2. **Rugs are walkable** — thin collision ships, the game should ignore it for the player.
3. **Wall decor pivots at the bottom of the frame**; the level lifts them to hanging height.
4. **Shop washer / dryer / bookcase stay**; house versions are new names.

No commits or pushes until he says so.
