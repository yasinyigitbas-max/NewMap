# Coronado modular starter set (snap-in houses + storefronts)

Snap-in pieces for authoring houses and storefronts on a fixed grid, plus a **merge/bake step** that turns a finished
assembly into one ordinary building (`mod_<name>_{near,mid,far,col}.glb`) that validates exactly like the 80 main buildings.

> **Loose pieces are for editor authoring only. Never ship them in a scene.** Ship only the merged output of
> `tools/merge_assembly.py`. The target is Godot 4 on Vulkan with the **Mobile renderer** (Redmi Note-class GPUs).
> On Mobile every mesh surface costs its own draw call in the opaque pass and in each shadow-casting pass, plus its own
> culling and LOD instance. A loose 9×7.5 m house is 12–16 pieces, so it costs 12–16 opaque draws, the same again per
> shadow cascade, and 12–16 visibility/LOD tests. The merged house costs **1 draw per tier per pass** and one instance to
> cull, and it switches near/mid/far as one object (no piece-by-piece LOD popping). The triangle counts are the same
> either way, so merging only removes overhead.

## Layout
```
modular/
  pieces/houses/<piece>/mod_<piece>_{near,mid,far,col}.glb + stats.json   (house atlas: bld_*)
  pieces/shops/<piece>/...                                                 (city atlas: storefronts, awnings, signs)
  examples/<name>/mod_<name>_{near,mid,far,col}.glb + layout.json          (merged, ready to ship)
  previews/closeups/<example>_<view>.png                                   (near-tier close-ups, Cycles 64 spp)
  reports/validation_modular.{md,json}
  tools/  mod_core.py (grid + Piece)  mod_pieces.py (catalogue)  make_modular.py (export pieces)
          assemble.py (example layouts -> layout.json -> merge)  merge_assembly.py (merge/bake step)
          validate_modular.py  render_examples.sh
  godot/export_layout.gd   (EditorScript: assembly scene -> layout.json)
```

## Grid and modules
| | value |
|---|---|
| sub-grid | **0.5 m**. Every snap point and module length is a multiple of it |
| house wall modules | **3.0 m** (standard), **1.5 m** and **4.5 m** (filler / long walls) |
| house depth | **7.5 m** (side-gable roof span), wall height (plate) **3.5 m** = 0.5 m foundation + 3.0 m storey |
| house wall slab | 0.30 m deep. Exterior face 0.15 m in front of the piece origin |
| shop bay | **6.0 m** frontage. Shop depth module **12.0 m** |
| shop heights | ground storey 3.8 m, plate 4.2 m, parapet 0.9 m (top 5.1 m) |
| shop front slab | 0.60 m (door recessed 0.45 m). Sides and back 0.30 m |
| rotations | 90° steps about +Y only: front 0°, right 90°, back 180°, left 270° |

A house footprint is W × 7.5 m, where W is a sum of wall modules (9.0 m in the examples). A shop footprint is
(6 m × bays) × 12 m.

## Snap rules
1. **Pieces butt edge to edge. They never overlap.** Each piece is open on its snap planes: wall pieces have no end caps
   at ±module/2, no back face and no top face. Roof run pieces have no gable ends. The faces that two neighbours would
   share are simply absent, so an assembly has no hidden or coincident faces (z-fighting) and no wasted triangles.
2. **Wall pieces** come in three finishes with identical geometry: `_stucco` (cream), `_stucco_white` and `_siding`
   (blue-grey, with corner boards). Clay gable ends match: `clay_stucco` (cream) and `clay_stucco_white`. Wall pieces carry their origin on the centre of the wall's back plane at ground. Place them along each side,
   left to right as seen from outside. The module lengths of a side must add up exactly to that side's length (the
   assembler asserts this). The house corners close because each wall's exterior face runs exactly to the corner edge.
3. **Chimney** (`house_roof_chimney_brick` for composition roofs, `house_roof_chimney_brick_clay` for the lower-pitched
   clay roofs): the origin is on the house centre line (z = 0) at ground. Place it at
   (x, 0, 0) on any 3 m roof piece, with x on the 0.5 m grid and at least 0.5 m from a gable end. Its foot is clipped to
   the roof slopes. The merge step removes the roof tiles hidden inside the stack (`cut_box` in its stats). Every
   snap-in house gets one.
4. **Corner trims** (`house_trim_corner_white`) have their origin at the outer corner point. Use them on sided houses
   only. Stucco corners stay plain. **Cornice corners** (`shop_trim_cornice_corner_r/l`) return the shop cornice around
   both front corners.
5. **House roofs:** clay pieces use the main-kit Spanish pitch (0.36, ridge 5.19 m) and composition pieces use 0.45
   (ridge 5.57 m). Never mix the two families on one house. Use one 3 m roof piece over every 3 m of house width, on the centre line (z = 0). It carries its own
   height, so place it at y = 0 and it lands on the 3.5 m plate. The leftmost piece is `…endl…` (gable at −X), the
   rightmost is `…endr…` (gable at +X), and every piece between is `…run…`. Each end piece brings one downspout (endl at
   the back-left corner, endr at the front-right corner, 0.25 m in from the corner), so a house gets two diagonal
   downspouts.
6. **Shops:** one `shop_front_6m_*` per bay, `shop_side_12m_stucco` on the right side and its mirror `shop_side_12m_stucco_l` on the left side (so the service door sits toward the back on both sides), one `shop_back_6m_stucco` per bay,
   and roof decks `shop_roof_6m_single` (1 bay) or `_end` (rotated 180° at the right end) plus `_mid` for wider rows.
   The side piece's parapet runs the full 12 m and closes the corners. The front and back parapets end open at the
   corners.
7. **Logic (SPEC §7):** openings are part of a piece and are never cut. Pieces are whole modules, so a window or door
   can't be split by a seam or a corner. Every door has its stoop, threshold or recessed step baked in, and the house door stoop has iron handrails on both sides of its steps. Each handrail runs back to the facade onto a wall
   bracket plate and down to a newel on the bottom step (SPEC §7 railing termination, checked by `tools/railcheck.py`).
   Clay-roof houses use the `_clayhood` door variants (clay-tile entry canopy with terracotta edges). Fixtures sit on
   the wall they serve (lamp by its door, meter low on the wall, downspout from the gutter or scupper to the ground). Do
   not place a door piece where it would open onto nothing, for example against a neighbour's wall.

## Authoring → runtime
1. Author: place the loose `*_near.glb` pieces as children of one root Node3D in the Godot editor. Keep them on the
   0.5 m grid, in 90° steps. Set root metadata `group` (`houses`|`shops`) and `outline`
   (`{kind, W, D, wall, tint, roof, budget}`). Run `godot/export_layout.gd` (File → Run) to write `layout.json`.
   (`tools/assemble.py` writes the same file for the examples in code.)
2. Bake: `python3 tools/merge_assembly.py path/to/layout.json`. This needs no Blender (numpy plus the kit exporter).
   - **near / mid:** every placed piece is transformed and merged into **one mesh, one primitive, one material** on the
     shared atlas (house atlas for houses, city atlas for shops), keeping its normal and AO bakes.
   - **far:** one closed hull, generated from the snapped outline with the openings collected from the placed wall
     pieces and baked onto the far atlas, exactly like a main building's far tier. (A sum of per-piece far tiers would
     not be closed and would blow the far budget.)
   - **col:** ≤12 boxes from the same outline.
3. Validate: `python3 tools/validate_modular.py`. It runs the main kit's `validate.check_file` on every merged tier
   with the building's real budget class, so a merged assembly passes or fails exactly like a regular building.

Measured draw calls per tier (glTF primitives = Godot surfaces = draws per pass):

| model | near | mid | far | materials | col boxes |
|---|---|---|---|---|---|
| main buildings (80) | 1 | 1 | 1 | 1 | ≤12 |
| 5 merged examples | 1 | 1 | 1 | 1 | 1–2 |
| same examples as loose pieces | 13 / 17 / 13 / 10 / 7 | same | n/a | 1 per piece | per piece |

## Budgets
Pieces have their own small `mod_*` budgets (in `stats.json`). They exist to keep the merged sum under the building
budget. The merged assembly is what counts: small house (<120 m², one storey) 1500/450/40, shop 1200/350/20 per 6 m bay,
corner shop 2500/750/60.
**Snap-in houses use their own cap, `mod_house_small` = 1650/500/40** (SPEC §7, approved by Yasin 15 Nov 2026 19:36),
instead of the small-house 1500/450/40, because they meet the full house detail floor (chimney and step railing
included). Footprint must stay under 120 m² and single storey.

The validator differs from the main one for **pieces only**:
- no size, origin-centre or ground checks (pieces are partial by design);
- roof base must be on the plate, using the mid tier when a near-only downspout reaches the ground;
- far open edges are allowed only on snap planes and the ground;
- the mid ≤ 50 % of near rule is waived for trims under 60 near tris.

Pieces also get extra snap checks: nothing crosses the snap ends, and modules sit on the 0.5 m grid.

## Examples
| example | pieces | near / mid / far | budget |
|---|---|---|---|
| ex_house_ranch_stucco (9×7.5) | 13 | 1630 / 364 / 22 | 1650/500/40 |
| ex_house_garage_siding (9×7.5, corner boards) | 17 | 1622 / 388 / 22 | 1650/500/40 |
| ex_house_cottage_clay (9×7.5, white stucco, clay roof) | 13 | 1620 / 372 / 22 | 1650/500/40 |
| ex_shop_row_cafe_books (2 bays, 12×12) | 10 | 1960 / 424 / 10 | 2400/700/40 |
| ex_shop_corner_bakery (1 bay, 6×12) | 7 | 1356 / 306 / 10 | 2500/750/60 |

The placed pieces of each example are listed in `examples/<name>/layout.json`.

## Known limits (starter set)
- The front and back copings lap under the full-length side coping at the corners (it sits 1 cm proud).
- The house examples are close to the 1650 cap (1620–1630), so extra house features need trims elsewhere.
- Clay rake fascia: the clay tile row can only wrap horizontally, so on the sloped rake it smeared into streaks. Sloped
  barrel-end strips are now a terracotta barge strip (`T_terracotta`, `Piece._fix_sloped_bands`). This is in the
  modular pieces only; the main generator `tools/build.py` is unchanged.
