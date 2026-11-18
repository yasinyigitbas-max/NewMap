# Coronado modular urban family (snap-in pieces for the 1 km map)

Wall-slab pieces for brick rows, walk-up apartments, service fronts and big boxes, self-storage, warehouses, towers,
civic halls and grit/abandoned fronts. They are authored on the same 0.5 m grid as the house and shop sets
(see `README.md`) and are merged into one building per assembly before shipping. **Loose pieces are for editor
authoring only.** Ship the merged `modular/examples_map/<name>/mod_<name>_{near,mid,far,col}.glb`.

```
modular/pieces/urban/<piece>/mod_<piece>_{near,mid,far,col}.glb + stats.json     (city atlas)
modular/examples_map/<name>/...  + layout.json                                   (merged rows, ready to ship)
modular/examples_renamed/<name>/                                                 (phase-B examples without the mod_mod_ prefix)
tools/  mod_phased.py   phase-B urban catalogue (owned by its own job; not edited by the map work)
        mod_map.py      map additions: closing pieces, door-free backs, returns, civic side/back/roof
        mod_map_houses.py  house additions: peach / pink stucco, hip roofs, porch wall, 6 m deep roofs
        make_map_pieces.py / make_map_house_pieces.py   export the additions (same exporter as make_modular.py)
        assemble_map.py  merged map layouts (+ hidden-face cull at merge)   validate_map.py  validate_map_pieces.py
        fix_mod_prefix.py  clean-named copies of the phase-B examples
```

## Modules and heights
| family | bay | depth | plate / parapet top | front slab | notes |
|---|---|---|---|---|---|
| brick row `urb_brk_*` | 6 m | 14 m (3 sty) / 16 m (4 sty) | 9.3 / 10.3, 12.3 / 13.3 | 0.45 | floor 0.3, 3.0 m storeys |
| apartment `urb_apt_*` | 6 m | 12 m | 9.3 / 10.1 | 0.45 | balcony bay + separate balcony piece |
| service front `urb_svc_front_6m_*` | 6 m | 12 m | 4.2 / 5.1 | 0.45 | bank, cinema, fastfood, laundry, pawn, pharmacy |
| big box `urb_svc_*_bigbox` | 6 m | 12 m | 5.4 / 6.5 | 0.45 | own side / back / roof since 16 Nov |
| self-storage `urb_stg_*` | 6 m | 12 m | 4.2 / 4.8 | 0.30 | |
| warehouse `urb_wh_*` | 12 m | 24 m | 6.6 / 7.4 | 0.30 | flat, sawtooth or shed roof |
| tower `urb_twr_*` | 8 m | 20 m | 30.3 / 31.2 | 0.45 | 10 storeys, punched or glass |
| civic `urb_civ_*` | 6 m | 12 m | 4.8 / 5.24 | 0.45 entry, 0.30 window | floor 0.6; cornice and pediment sit on the 4.8 plate |

Rotations are 90° steps about +Y: front 0°, right side 90°, back 180°, left side 270°.

## Placement (merged layouts, origin = footprint centre at ground)
* **Fronts** at `z = D/2 - T/2` (T = slab depth: 0.45 or 0.30). **Backs** at `z = -D/2 + 0.15`, rot 180, placed right to left.
* **Sides** at `x = ±(W/2 - 0.15)`: rot 90 on the right, rot 270 on the left. A side runs the full depth and closes the corners.
* **Roofs** one per bay on the centre line (`x = bay centre, z = 0`). They sit on the plate and tuck under the parapets.
  Brick rows of 3 or more bays: put the full deck (RTU, hatch) on the middle bay and `urb_brk_roof_6x14_3sty_run` on the rest.
* **Civic stack**: `urb_civ_cornice_6m` at `y = 4.8, z = D/2 + 0.14`; `urb_civ_pediment_6m` at `y = 4.8, z = D/2 + 0.24`
  over the entry bay. Civic halls have no rooftop units or hatch: plant would show over the cornice.

## Corner rules
1. **Plain corner**: the side piece runs the full depth at `x = ±(W/2 - 0.15)`. Each front slab runs to the corner edge.
   Nothing else is needed.
2. **Corner piers** (`urb_brk_corner_pier_{3,4}sty`, `urb_twr_corner_pier_10sty`): 1 m square, centred on its origin,
   full height to the parapet top. Place it at `(±(W/2 - 0.35), D/2 - 0.35)`, so it stands 0.15 m proud of both the front
   and the side and covers the slab ends. The faces buried in the walls are removed by the hidden-face cull at merge.
   Use a pier on a street corner only, and at most two per building (each costs ~270 near tris). Demo: `brk3_corner2`
   (corner-entry bay `urb_brk_front_6m_3sty_corner` at the corner).
3. **Service-front returns** (`urb_svc_trim_return_{l,r}`, `_bigbox` for the 5.4 m plate): origin at the outer front corner at
   ground, rot 0. Each is a 6 cm pilaster over the exposed 0.45 m slab end plus an L coping cap that laps the front coping
   and runs 0.75 m back along the side. Use them wherever a service front ends at a side wall.
4. **Civic returns** (`urb_civ_trim_return_{l,r}`): origin at the outer front corner at ground, rot 0. Each is a moulded
   block from the architrave line to the cornice top, 1.0 m along the side. It closes the open snap ends of the front
   cornice and window mouldings and of the side cornice. Pair `urb_civ_side_12m_r` (rot 90) with `_return_r`, and
   `_side_12m_l` (rot 270) with `_return_l`.
5. Shop rows keep their own `shop_trim_cornice_corner_{l,r}` (see `README.md`).

## Door-free backs (rows standing back to back)
`urb_brk_back_6m_{3,4}sty_blank`, `urb_apt_back_6m_blank`, `urb_wh_back_12m_blank`, `urb_svc_back_6m_bigbox_blank`,
`urb_civ_back_6m_blank`, `shop_back_6m_stucco_blank`. They have windows, louvres and meters, with no door and no stoop,
so two rows can stand back to back across a narrow service gap. Every building still needs one door somewhere. Keep at
least one door back (or a side door) per row unless a service lane serves the other row.

## Big box set
`urb_svc_front_6m_bigbox` + `urb_svc_side_12m_bigbox` + `urb_svc_back_6m_bigbox` (service door + stoop + lamp) /
`_dock` (3.2 m roll-up, bumpers, lamp) / `_blank` + `urb_svc_roof_6x12_bigbox`. Demos: `svb_row2`, `svb_row3`. At far range
the entry bays read as one glazed band: outline `far_gap` 0.8 merges bays across the 0.7 m piers.

## Merged-layout far (outline) options in `assemble_map.outline_building`
`far_punch` (blank strip, front openings punched), `far_gap` (merge openings closer than this into one band),
`far_front` (explicit far list of front openings), `far_pediments` (8-tri prisms), `far_tint`.
Merge removes hidden faces (`cull_hidden`, the same ray test as validate.py) from near and mid.

## Budgets
Pieces carry their own budget in stats.json. Merged layouts use the building classes: `apartment` 3500/1000/80,
`shop` 1200/350/20 per 6 m bay, `civic` 5000/1500/120, `tower` 4000/1200/80 per 10 storeys, `warehouse` 2000/600/40.

## Validation
* `python3 tools/validate_map_pieces.py` writes `reports/map16/validation_map_pieces.{md,json}` (the map additions).
* `python3 tools/validate_map.py` (no args, for the full report) writes `reports/map16/validation_examples_map.{md,json}`.
  It runs the validate_modular example checks plus far_match on the front elevation, and checks that every piece used passes.
* `modular/reports/validation_modular.*` belongs to the phase-B job. The map work does not rewrite it.

## The mod_mod_ prefix
The phase-B examples' layout names already start with `mod_`, and merge adds another, so they ship as
`examples/mod_<x>/mod_mod_<x>_<tier>.glb`. `tools/fix_mod_prefix.py` writes clean-named copies to
`examples_renamed/<x>/mod_<x>_<tier>.glb`. Geometry is unchanged; only the glTF node, mesh and material names are renamed.
The originals are left in place for their owner. Re-merging them from today's pieces is not equivalent: the phase-B
pieces have grown since 15 Nov, and brk_row, twr_office and wh_shed would go over budget.
