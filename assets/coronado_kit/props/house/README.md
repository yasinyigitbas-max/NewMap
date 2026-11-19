# Coronado house interior set (page H)

Interior furniture, rugs and decorative objects for houses and stores, built from scratch to SPEC.md. **Near and collision tiers only** — these pieces are viewed at close range indoors and are not drawn at mid or far distances. All 70 pass `tools/house/h_check.py` (19 Nov 2026).

The existing exterior house props (AC condensers, gutters, mailboxes, porch lights, and so on) stay as flat files in this folder, on pages A/B as before. They are not part of this set.

```
props/house/decor/      36 decorative objects (frames, statues, lamps, vessels)
props/house/rugs/       8 rugs and mats
props/house/furn/       26 furniture pieces (living, kitchen, dining, bedroom, bath, laundry)
props/house/_bake/      slots_h.json: page H bake slots
props/manifest_h*.json  one manifest per category (hdecor, hrugs, hfurn)
atlases/props_h_{color_clean,normal,orm}.png
tools/house/            h_check.py, builders, trims, sheets
previews/house/         one hero per piece + detail/grid sheets
reports/house/          PLAN.md, PROGRESS.md, h_check.json
```

The glbs reference page H as `../../../atlases/props_h_*.png` (same depth as indoor, waterfront and streetside), so keep the layout. One material and one draw call per prop.

## Texture budget

Page H is a new atlas: **1024 colour / 512 normal / 256 ORM = 1.75 MB** (ASTC 4x4 with mips).

It is **streamed only with interiors**. It is **not** part of the 8 MB street-resident props cap. Street pages A + B + C + grime + W stay at **7.583 MB of 8 MB**. This set never writes to those pages, or to page I.

Shared trim tiles use the `th_*` prefix. Page H swatches that share a name with page A are recorded in `props_atlas.json` as `h_<name>` (e.g. `h_brass.clean`). Unique lettering and artwork go in bake slots (see `_bake/slots_h.json`).

## Tiers and checks

- Tiers: **near + col only**. Mid and far are not built and are not required.
- `tools/house/h_check.py` is the acceptance test: naming, near+col present, one mesh / one material, triangle cap, page H textures only, `normalTexture` and `occlusionTexture` on the ORM, origin at the footprint centre, ground at y=0.
- Budgets are maximums (tiny 300 / small 600 / medium 1200 / large 2500). Nothing in this set exceeds its target.

## Pieces (tris near, collision, footprint w x d, height in metres)

| group | piece | footprint, height (m) | near | budget | col |
|---|---|---|---:|---:|---:|
| decor | frame_print_small | 0.28 x 0.05, 0.36 | 218 | 250 | 12 |
| decor | frame_print_medium | 0.50 x 0.06, 0.65 | 218 | 400 | 12 |
| decor | frame_print_large | 0.90 x 0.06, 0.70 | 218 | 500 | 12 |
| decor | frame_print_tall | 0.40 x 0.06, 0.90 | 218 | 400 | 12 |
| decor | frame_ocean | 0.70 x 0.06, 0.50 | 282 | 450 | 12 |
| decor | frame_mcm_abstract | 0.60 x 0.06, 0.60 | 218 | 450 | 12 |
| decor | frame_motel_floral | 0.46 x 0.06, 0.57 | 246 | 450 | 12 |
| decor | frame_stand_photo | 0.16 x 0.20, 0.20 | 206 | 220 | 12 |
| decor | mirror_round | 0.63 x 0.05, 0.66 | 526 | 550 | 28 |
| decor | mirror_rect | 0.50 x 0.07, 0.80 | 288 | 500 | 12 |
| decor | clock_wall_sunburst | 0.52 x 0.05, 0.54 | 504 | 550 | 28 |
| decor | clock_mantel | 0.28 x 0.13, 0.32 | 502 | 520 | 12 |
| decor | vase_tall | 0.18 x 0.18, 0.43 | 224 | 350 | 28 |
| decor | vase_bud | 0.08 x 0.08, 0.17 | 176 | 180 | 28 |
| decor | vase_ginger | 0.22 x 0.22, 0.28 | 232 | 400 | 28 |
| decor | vase_lava | 0.18 x 0.19, 0.27 | 256 | 260 | 28 |
| decor | bowl_ceramic | 0.27 x 0.28, 0.10 | 176 | 250 | 28 |
| decor | bowl_wood | 0.32 x 0.32, 0.10 | 210 | 250 | 28 |
| decor | bowl_shell | 0.27 x 0.19, 0.06 | 172 | 260 | 12 |
| decor | decorative_tray | 0.39 x 0.24, 0.03 | 216 | 220 | 12 |
| decor | candle_pair_brass | 0.20 x 0.07, 0.26 | 212 | 280 | 12 |
| decor | candle_pillar | 0.10 x 0.11, 0.17 | 108 | 180 | 28 |
| decor | hurricane_lamp | 0.16 x 0.14, 0.30 | 282 | 400 | 28 |
| decor | figurine_bird | 0.10 x 0.10, 0.14 | 248 | 260 | 12 |
| decor | figurine_cat | 0.10 x 0.11, 0.19 | 272 | 280 | 12 |
| decor | figurine_horse | 0.15 x 0.13, 0.14 | 290 | 290 | 12 |
| decor | statue_bust | 0.18 x 0.15, 0.27 | 412 | 450 | 12 |
| decor | sculpture_organic | 0.17 x 0.14, 0.27 | 144 | 450 | 12 |
| decor | sculpture_coral | 0.14 x 0.13, 0.22 | 222 | 280 | 12 |
| decor | wall_plate_fish | 0.29 x 0.03, 0.30 | 214 | 250 | 28 |
| decor | wall_plate_floral | 0.25 x 0.03, 0.26 | 246 | 250 | 28 |
| decor | bookends | 0.35 x 0.16, 0.34 | 416 | 450 | 12 |
| decor | globe_desktop | 0.25 x 0.23, 0.33 | 500 | 550 | 28 |
| decor | books_stack | 0.26 x 0.31, 0.15 | 228 | 250 | 12 |
| decor | decanter | 0.11 x 0.11, 0.28 | 154 | 280 | 28 |
| decor | woven_basket | 0.28 x 0.28, 0.27 | 238 | 400 | 28 |
| rugs | rug_living_mcm | 2.40 x 1.80, 0.03 | 370 | 480 | 12 |
| rugs | rug_living_jute | 2.00 x 1.40, 0.02 | 154 | 400 | 12 |
| rugs | rug_motel_floral | 1.80 x 1.20, 0.02 | 124 | 400 | 12 |
| rugs | rug_runner | 2.49 x 0.70, 0.02 | 312 | 350 | 12 |
| rugs | rug_accent | 1.20 x 0.80, 0.02 | 70 | 250 | 12 |
| rugs | rug_round | 1.52 x 1.52, 0.02 | 112 | 450 | 28 |
| rugs | bath_mat | 0.80 x 0.50, 0.03 | 92 | 200 | 12 |
| rugs | rug_shag_oval | 1.67 x 1.15, 0.04 | 132 | 450 | 12 |
| furn | sofa_3seat | 2.12 x 0.87, 0.86 | 784 | 1100 | 12 |
| furn | lounge_chair | 0.71 x 0.71, 0.90 | 548 | 900 | 12 |
| furn | ottoman | 0.70 x 0.55, 0.40 | 304 | 500 | 12 |
| furn | coffee_table | 1.20 x 0.60, 0.40 | 460 | 550 | 12 |
| furn | side_table | 0.50 x 0.50, 0.55 | 268 | 500 | 28 |
| furn | credenza | 1.82 x 0.49, 0.75 | 480 | 1100 | 12 |
| furn | floor_lamp | 0.43 x 0.44, 1.55 | 160 | 550 | 28 |
| furn | tv_console | 1.22 x 0.44, 0.55 | 522 | 900 | 12 |
| furn | fridge_home | 0.78 x 0.87, 1.70 | 926 | 1100 | 12 |
| furn | range_gas | 0.76 x 0.69, 0.92 | 588 | 1100 | 12 |
| furn | sink_base | 1.23 x 0.69, 1.06 | 672 | 1100 | 12 |
| furn | upper_cabinet | 0.86 x 0.36, 0.70 | 310 | 800 | 12 |
| furn | dining_table | 1.50 x 0.90, 0.75 | 472 | 900 | 12 |
| furn | dining_chair | 0.42 x 0.41, 0.86 | 412 | 550 | 12 |
| furn | sideboard | 1.62 x 0.49, 0.85 | 788 | 1100 | 12 |
| furn | bed_queen | 1.76 x 2.09, 0.96 | 696 | 1100 | 12 |
| furn | nightstand | 0.52 x 0.44, 0.58 | 418 | 500 | 12 |
| furn | dresser | 1.32 x 0.54, 0.80 | 902 | 1100 | 12 |
| furn | toilet | 0.51 x 0.69, 0.76 | 750 | 900 | 12 |
| furn | vanity_sink | 0.92 x 0.54, 0.97 | 528 | 1000 | 12 |
| furn | bathtub | 1.69 x 0.70, 0.60 | 956 | 1100 | 12 |
| furn | washer_home | 0.68 x 0.73, 0.95 | 282 | 1000 | 12 |
| furn | dryer_home | 0.68 x 0.76, 0.95 | 324 | 1000 | 12 |
| furn | laundry_hamper | 0.41 x 0.41, 0.59 | 220 | 400 | 28 |
| furn | storage_cabinet | 0.91 x 0.48, 1.80 | 428 | 1000 | 12 |
| furn | workbench_garage | 1.53 x 0.60, 1.00 | 392 | 1000 | 12 |

