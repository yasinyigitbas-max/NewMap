# Coronado waterfront set: quay / seawall edge, timber pier, marina, boats, promenade and small props

Snap-in props for building the water edge: 6 quay pieces (5 seawall modules and the pier root), 5 pier pieces, 5 marina pieces,
4 moored boats, 3 promenade pieces and 11 small props (34 pieces). Every piece passed the waterfront audit of 17 Nov 2026
(`reports/waterfront/`). Texture page W shipped with set 1; the marina, boats, promenade and small props share it (0 MB added).
The planned ferry was skipped on Yasin's call (17 Nov 2026): it is not in this set.

```
props/waterfront/quay/     prop_<piece>_clean_{near,mid,far}.glb + prop_<piece>_col.glb
props/waterfront/pier/     (same)
props/waterfront/gangway/  (same)
props/waterfront/marina/   (same: float, finger, pile, dock_box, pedestal)
props/waterfront/boats/    (same: sloop, express, troller, skiff)
props/waterfront/promenade/ (same: rail, rail_wall, boardwalk)
props/waterfront/small/    (same: 11 small props)
props/waterfront/_rails/   <piece>_rails.json: rail / post polylines for railcheck + collision split
props/waterfront/_bake/    slots_w.json: page W bake slots per piece (read by the uvsrc guard)
props/manifest_wfquay.json, manifest_wfpier.json, manifest_wfgang.json, manifest_wfmarina.json,
                           manifest_wfboats.json, manifest_wfprom.json, manifest_wfsmall.json
atlases/props_w_color_clean.png (1024), props_w_normal.png (512), props_w_orm.png (256)
tools/waterfront/          checks, snap tests, trims, renders, builders (see below)
previews/waterfront/       one hero strip per piece + _contact_sheet_waterfront_{quay,pier,marina,boats,promenade,small}.jpg
```

The glbs reference page W as `../../../atlases/props_w_*.png` (one folder deeper than the other prop batches), so keep the layout.
One material and one draw call per tier. Mid and far tiers sample the colour page only.

## Pieces (tris near / mid / far, collision boxes main + rail)
Budgets are maximums. Large prop class: near 2500, mid 750, far 20. Medium (marina_pile): near 1200, mid 361, far 20. Small (pier_lamp, dock_box, marina_pedestal): near 600, mid 181, far 20.

| group | piece | footprint w x d, height (m) | near | mid | far | col main / rail | notes |
|---|---|---|---|---|---|---|---|
| quay | quay_straight | 6.0 x 2.025, 3.7 | 1638 | 234 | 6 | 3 / 4 | ladder + safety line |
| quay | quay_straight_bollards | 6.0 x 2.025, 3.54 | 1606 | 332 | 6 | 1 / 4 | mooring bollards, timber fender piles |
| quay | quay_stair | 6.0 x 2.025, 4.07 | 1848 | 308 | 14 | 12 / 5 | stair down to a landing, handrail |
| quay | quay_corner_out | 2.025 x 2.025, 3.54 | 1229 | 241 | 12 | 2 / 3 | rounded outside corner, hanging fender |
| quay | quay_corner_in | 4.0 x 4.0, 3.12 | 1100 | 228 | 8 | 2 / 3 | inside corner |
| quay | quay_pier_root | 6.0 x 2.025, 3.0 | 634 | 188 | 6 | 1 / 6 | quay module the pier starts from |
| pier | pier_straight | 4.18 x 6.0, 3.25 | 1012 | 172 | 16 | 5 / 8 | plank deck on piles, curbs, cleats |
| pier | pier_thead | 12.1 x 6.58, 4.02 | 2436 | 398 | 20 | 12 / 14 | T-head end, ladder, gangway landing gap |
| pier | pier_rail_end | 4.18 x 6.1, 4.08 | 1242 | 236 | 20 | 2 / 11 | railed end |
| pier | pier_lamp | 0.4 x 0.38, 4.24 | 406 | 170 | 14 | 0 / 1 | small class |
| pier | gangway | 1.29 x 11.0, 2.12 | 2382 | 226 | 12 | 6 / 8 | hinged aluminium gangway to a float deck |
| marina | marina_float | 6.05 x 2.72, 0.87 | 1470 | 134 | 10 | 5 / 0 | 6 m pontoon, snaps end to end |
| marina | marina_finger | 3.09 x 7.62, 0.87 | 1172 | 94 | 16 | 2 / 0 | 7.5 m finger; origin at the float-side root |
| marina | marina_pile | 0.60 x 0.71, 5.46 | 510 | 112 | 14 | 1 / 1 | pile from harbour bed, guide hoop at the float deck |
| marina | dock_box | 1.54 x 0.74, 0.62 | 266 | 18 | 10 | 1 / 0 | small class; origin on the deck |
| marina | marina_pedestal | 0.40 x 0.36, 1.17 | 188 | 30 | 12 | 0 / 1 | small class; shore power + water |
| boats | boat_sloop | 3.22 x 9.49, 14.60 | 2379 | 362 | 19 | 4 / 3 | 9.2 m sloop, WL 1.40; mast, boom, pulpit + lifelines |
| boats | boat_express | 2.84 x 9.49, 5.25 | 2343 | 255 | 20 | 5 / 6 | express cruiser, WL 0.70; all-trim (no slot); edge loop under the sheer |
| boats | boat_troller | 4.11 x 11.92, 14.56 | 2089 | 279 | 20 | 5 / 3 | 40 ft (12 m) wooden troller, WL 1.35; wheelhouse, stowed trolling poles |
| boats | boat_skiff | 1.62 x 5.23, 1.12 | 1077 | 149 | 15 | 3 / 0 | medium class; skiff, WL 0.30, outboard |
| promenade | prom_rail | 4.09 x 0.17, 1.08 | 544 | 184 | 10 | 0 / 1 | medium; 4 m seaside railing, grounded end posts |
| promenade | prom_rail_wall | 2.04 x 0.17, 1.10 | 332 | 126 | 8 | 0 / 1 | medium; end module into bolted wall flanges (no slot) |
| promenade | prom_boardwalk | 4.00 x 3.00, 0.32 | 520 | 92 | 10 | 1 / 0 | medium; 4 x 3 m boardwalk strip (no slot) |
| small | lifering_stand | 0.69 x 0.26, 1.77 | 490 | 108 | 16 | 1 / 1 | small; 16-segment ring, heaving line tied to it, sign |
| small | buoy_mooring | 1.03 x 1.62, 2.45 | 446 | 96 | 16 | 1 / 1 | small; harbour datum, sinker + chain |
| small | buoy_nun | 0.80 x 1.79, 2.95 | 345 | 68 | 15 | 1 / 1 | small; red channel marker, harbour datum |
| small | buoy_can | 0.80 x 1.79, 2.68 | 325 | 68 | 14 | 1 / 1 | small; green channel marker, harbour datum |
| small | fuel_pump | 1.40 x 1.10, 1.78 | 912 | 68 | 18 | 2 / 2 | medium; fuel-dock pump, drooping hoses, extinguisher, bollards |
| small | boat_trailer | 2.00 x 6.74, 1.75 | 2239 | 373 | 18 | 7 / 0 | large; skiff on a galvanized trailer, winch strap to the bow eye |
| small | kayak_rack | 3.60 x 1.86, 2.05 | 1182 | 260 | 20 | 2 / 6 | medium; 4 kayaks on a 2-level galvanized rack |
| small | beach_shower | 1.10 x 1.11, 2.45 | 466 | 56 | 10 | 1 / 1 | small; post shower on a teak grate |
| small | volleyball_net | 13.32 x 2.12, 3.23 | 1056 | 224 | 18 | 1 / 2 | medium; padded posts, net, guy lines |
| small | beach_umbrella | 1.94 x 1.94, 2.52 | 546 | 70 | 14 | 1 / 1 | small; open, weighted base (no slot) |
| small | beach_umbrella_closed | 0.60 x 0.60, 2.46 | 346 | 78 | 13 | 1 / 1 | small; furled (no slot) |

## Datum and snap grid
- Z-up in the builders (glTF +Y up). Harbour bed at the wall toe z = 0, still water z = 1.5, coping / deck top z = 3.0.
  Water side is -Y in the builders (+Z in glTF).
- All module origins sit on the 0.5 m grid; rotations are 90° steps.
- Quay: straight-type modules are 6 m long and chain end to end (straight, bollards, stair, pier root). Inside corner arm b
  meets a straight at (1.0, -5.0) rz -90; outside corner arm b meets a straight at origin x 0.
  Wall cross-sections match within 0.013 m at every joint (`reports/waterfront/quay_snap.json`).
- Pier: root at the quay origin, straights at y -4, -10, -16, ... (6 m steps), then a T-head or rail end at the next 6 m step.
  Deck section Hausdorff ≤ 0.011 m, walk-top deviation 0.000 m (`reports/waterfront/pier_snap.json`). Stringers continue
  across the straight | T-head joint.
- Gangway: origin = (x, deck_edge - 5.0) at float-deck height (1.95); shown at (-11.0, -15.5, 1.95) rz -90 off the
  T-head west gap. It is hinged, so it has no snap joint.

- Marina: still water z = 1.5. A float placed with its pontoon underside at world z = 1.20 has the deck top at 1.95
  (same height as the gangway landing). Floats are 6 m long and chain on 6 m centres (ends at x = ±3 in the builder;
  corner bumpers stay on the module and sit a few centimetres proud). A finger's root face is at y = 0 and bolts to a
  float side; origin = (x, float deck-edge y) with -Y pointing away from the float, tip at y = -7.5. marina_pile origin
  is the harbour bed (z = 0), like the quay; the guide hoop sits at the float deck (world 1.95). dock_box and
  marina_pedestal origins sit on the deck surface.
- Boats: origin = lowest point (keel / skeg) centre, bow towards -Y. Each boat has its designed waterline at local z = WL
  (sloop 1.40, express 0.70, troller 1.35, skiff 0.30); place it at world z = 1.5 - WL to float on the harbour WL 1.5.
  Hulls are clean: no ports, windows, registration or name plates on any tier.
- Promenade: origin = bottom centre on the walk surface (e.g. z 3.0 on the quay). prom_rail modules are 4 m and snap end
  to end (end posts form a bolted twin post); prom_rail_wall (2 m) ends a run in wall flanges at x = +1.0. Every run ends on
  a grounded post or a wall flange. prom_boardwalk is 4 x 3 m with open snap ends at x = ±2.0, deck top 0.32.
- Small props: origin = bottom centre on the surface they stand on. buoy_* use the harbour datum (sinker on the bed z 0,
  float at WL 1.5).

## Page W (waterfront props atlas)
- Colour 1024, normal 512, ORM 256 = **1.75 MB** in VRAM (ASTC 4x4 + mips). Props total with page W: 5.83 + 1.75 =
  **7.58 MB of the 8 MB cap** (pages A 3.0, grime 0.33, B 1.75, C 0.75, W 1.75). Approved by Yasin on 17 Nov 2026.
  The boats, promenade and small props add no page: still 7.58 MB.
- Rows 0-383 hold 16 tiling trim tiles at 128 px/m (`tw_deck`, `tw_deck_brown`, `tw_timber`, `tw_conc`, `tw_conc_top`,
  `tw_tide`, `tw_tide_hi`, `tw_granite`, `tw_paver`, `tw_galv`, `tw_paint`, `tw_rubber`, `tw_canvas`, `tw_teak`,
  `tw_foul`, `tw_rust`), plus 5 boat tiles in row 256 (`tw_gelcoat`, `tw_nonskid`, `tw_sail`, `tw_plank`, `tw_vinyl`, built
  by `wf_trims_boat.py` into a region that was empty), plus the far swatch `twf_flat`; regions are in `atlases/props_atlas.json` (`page: "w"`).
  Rows 384-1023 are per-piece bake slots (48²-256², 33-122 px/m unique detail). After the marina and the streetside
  batch, 96,512 px (14.7 %) of the slot area was free. After the boats, promenade and small props (13 new slots of 48² / 64²;
  express, prom_rail_wall, prom_boardwalk and both umbrellas are all-trim with no slot), 52,224 px (7.97 %) is free, with
  no free 64² block. Existing tiles and slots are unchanged.
- Worn / dirty use the shared `shaders/prop_wear.gdshader`; no condition pages ship for W.

## Checks (all 34 waterfront pieces pass)
`tools/waterfront/wf_check.py <piece> ...` runs: the props validator (SPEC s1-s4), far_match (gated front / side / plan
silhouette IoU ≥ 0.8, ΔE ≤ 15; open snap-end views are info only), railcheck (SPEC s7: every rail end within 1.5 cm of
geometry, ≤ 1 cm buried, every post foot grounded), collision split (≤ 12 main + ≤ 16 rail boxes) and the **uvsrc guard**
(every near/mid triangle samples a page-W trim tile or its own bake slot; no slot overlaps a tile or another slot).
`wf_snap.py` / `wf_snap_pier.py` test the quay and pier joints. Marina floats chain on 6 m centres; there is no separate marina snap script. For the boats, promenade and small props
far_match gates on front + plan. `wc_w/` is the wall-evenness check (staging copy of the kit's wallcheck
with a page-W mask, needs Blender); all five quay walls pass with cast shadows off. With grazing-sun shadows on,
quay_corner_out front/right reads 0.043 / 0.027 against 0.025 only from its own fender shadows.
The validator's "may face inward / be enclosed" notes on some near tiers are warnings (closed piles and curbs), not errors.

## Rebuilding
The tools still carry the staging paths (`/workspace/coronado_kit_v2/_staging/waterfront/...`) they were run from.
- `tools/waterfront/wf_trims.py`: builds the page-W trim tiles, then `props_compose.py w` composes the page (kit props pipeline).
- `tools/waterfront/builders/b_wfquay.py`, `b_wfpier.py`, `b_wfgang.py`, `b_wfmarina.py`, `b_wfboats.py`, `b_wfprom.py`,
  `b_wfsmall.py` + `wf_parts.py`, `wf_boat.py` (hull lofting): the Blender builders. They run
  inside the kit's props pipeline (`pg.py`, `run.py`, `props_compose.py`, not in this repo), like the other prop batches.
- `wf_render.py` / `wf_sheet.py`: hero strips and contact sheets (`wf_*_jobs.py`, `wf_tier_jobs.py` write the job files);
  `wf_diag_far.py` diffs far vs mid silhouettes; `wf_pagew.py` reports page-W slot usage. `validate_props.py`: the validator copy the checks call.

Texture sources: CC0 Poly Haven photos, listed in `CREDITS_props.md`.
