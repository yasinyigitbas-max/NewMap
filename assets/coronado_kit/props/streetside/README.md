# Coronado streetside props (batch 2)

Fourteen standalone props for shop fronts, motel lots, parking and dingbat yards. Every piece passed the 17 Nov 2026 audit (`reports/streetside/`). They bake into the already-shipped waterfront page W, so they add **0 MB**.

```
props/streetside/signage/       pylon_sign, drive_thru_menu, bus_stop_sign
props/streetside/motel/         vending_soda, vending_snack, ice_chest
props/streetside/parking/       wheel_stop_concrete, wheel_stop_rubber, shopping_cart, cart_corral
props/streetside/residential/   balcony_clutter, dingbat_stair, buzzer_panel, clothesline
props/streetside/_rails/        <piece>_rails.json: rail / post polylines for railcheck + collision split
props/manifest_b2a.json, manifest_b2b.json
atlases/props_w_color_clean.png (1024), props_w_normal.png (512), props_w_orm.png (256)
tools/streetside/               checks, builders, sheets (see below)
previews/streetside/            one hero strip per piece + _contact_sheet_streetside_{signage,motel,parking,residential}.jpg
```

The glbs reference page W as `../../../atlases/props_w_*.png` (one folder deeper than the city / street batches), so keep the layout.
One material and one draw call per tier. Mid and far tiers sample the colour page only.

## Pieces (tris near / mid / far, collision boxes main + rail)
Budgets are maximums. Large: near 2500, mid 750, far 20. Medium: near 1200, mid 361, far 20. Small: near 600, mid 181, far 20. Tiny: near 300, mid 91, far 20.

| group | piece | footprint w x d, height (m) | near | mid | far | col main / rail | notes |
|---|---|---|---|---|---|---|---|
| signage | pylon_sign | 3.60 x 1.65, 7.59 | 1324 | 162 | 12 | 5 / 0 | cabinet on two legs; 256² bake slot |
| signage | drive_thru_menu | 2.96 x 1.03, 2.67 | 744 | 74 | 20 | 3 / 1 | island pad, speaker post, rear access panels |
| signage | bus_stop_sign | 0.63 x 0.30, 3.31 | 290 | 32 | 12 | 1 / 1 | pole + flag sign |
| motel | vending_soda | 1.03 x 1.43, 1.83 | 474 | 16 | 10 | 1 / 0 | small class |
| motel | vending_snack | 1.06 x 1.43, 1.83 | 410 | 16 | 10 | 1 / 0 | small class |
| motel | ice_chest | 1.64 x 1.34, 1.27 | 414 | 24 | 10 | 1 / 0 | small class |
| parking | wheel_stop_concrete | 1.83 x 0.15, 0.11 | 142 | 18 | 10 | 1 / 0 | tiny class |
| parking | wheel_stop_rubber | 1.83 x 0.15, 0.10 | 146 | 18 | 10 | 1 / 0 | tiny class |
| parking | shopping_cart | 0.58 x 1.06, 1.05 | 1012 | 104 | 14 | 2 / 0 | medium class |
| parking | cart_corral | 4.25 x 2.08, 2.00 | 672 | 276 | 20 | 0 / 4 | rails end on the posts |
| residential | balcony_clutter | 3.03 x 1.22, 1.41 | 1442 | 187 | 16 | 3 / 3 | wall mount; chairs, plants, drying rack |
| residential | dingbat_stair | 5.96 x 1.14, 3.98 | 1008 | 206 | 14 | 5 / 5 | run and landing butt a wall at y = +0.5 |
| residential | buzzer_panel | 0.28 x 0.06, 0.78 | 200 | 38 | 12 | 1 / 0 | wall mount; place the panel bottom at 1.15 m |
| residential | clothesline | 5.20 x 1.75, 2.06 | 755 | 78 | 20 | 1 / 4 | posts grounded, line rails end on the posts |

## Placement
- Ground-mounted pieces have their origin at the ground (glTF Y = 0).
- **buzzer_panel**: wall mount, wall plane at builder y = 0 (the back flange sits flush). Place the panel bottom at 1.15 m.
- **balcony_clutter**: wall mount; the balcony slab sits against the wall.
- **dingbat_stair**: the run and the top door landing butt a building wall at builder y = +0.5. The wall handrail returns end on rosette plates; the landing end guard dies into a cast wall flange.

## Page W
Shared with the waterfront set. Colour 1024, normal 512, ORM 256 = **1.75 MB** in VRAM (ASTC 4x4 + mips). Props total stays **7.58 MB of the 8 MB cap**. Batch 2 uses 233,216 px of bake slots plus the existing trim tiles (`tw_galv`, `tw_paint`, `tw_conc_top`, `tw_rubber`). Far tiers use the `twf_flat` swatch. Worn / dirty use the shared `shaders/prop_wear.gdshader`.

## Checks (all 14 pass)
`tools/streetside/b2_check.py <piece> ...` runs: the props validator (SPEC s1-s4), far_match (gated front / plan silhouette IoU ≥ 0.8, ΔE ≤ 15; side views of thin frames are info only), railcheck (SPEC s7: every rail end within 1.5 cm of a post, wall flange or grounded foot, ≤ 1 cm buried), collision split (≤ 12 main + ≤ 16 rail boxes) and the **uvsrc guard** (every near/mid triangle samples a page-W trim tile or its own bake slot; no slot overlaps a tile or another slot).
The validator's "may face inward / be enclosed" and "origin off footprint centre" notes are warnings (closed cabinets, the bus-stop flag, the finger-style asymmetric parts), not errors.

## Rebuilding
The tools still carry the staging paths (`/workspace/coronado_kit_v2/_staging/props_batch2/...` and the shared page-W kit under `_staging/waterfront/kit`) they were run from.
- `tools/streetside/b_b2a.py`, `b_b2b.py`: the Blender builders. They run inside the kit's props pipeline (`pg.py`, `run.py`, `props_compose.py`, not in this repo), like the other prop batches.
- `b2_check.py`, `b2_sheet.py`, `b2_jobs.py`, `b2_progress.py`, `diag_far.py`: checks, contact sheets and job lists.

Texture sources: the existing page-W CC0 Poly Haven tiles, listed in `CREDITS_props.md`. No new photo sources.
