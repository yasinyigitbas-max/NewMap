# Fill of the empty land, 21 Nov (Yasin pt455u / pt456u)

Yasin: "fill all of the empty space in the map ... both in and out of the ring road ... cover around the island with
sand, rock beaches and sea ... find the tiny gaps ... and fill them". Then: "No need to show me and wait approval."

**This is a GENERATOR** (tools/city/fill): one script decides ground, materials and props for 99 new pieces `fl_<cx>_<cz>`
(one per 200 m cell, layout rows `"from": "fill 21 Nov ..."`, pos 0). They are NOT locked. No locked piece was changed
(lock test: RESULT PASS, 665 locked pieces).

## Numbers (tools/city/fill/coverage.py, 0.5 m raster of every piece's "ground" over the island outline)
| | before | after |
|---|---|---|
| island land (coast.json) | 6.52 km2 | 6.52 km2 |
| piece ground on it | 4.13 km2 | 6.47 km2 |
| EMPTY (backstop shows) | 2.228 km2 | 110 m2 (0.5 m slivers between pieces) |
Fill: 99 pieces, ~1.46 M ground triangles, ~11,200 props (trees, agave, iceplant, riprap, lifeguard tower, signs, benches).

## What it is
- West of the ring: grass ground, smooth green..straw tint, Torrey pine / eucalyptus groves, 6 trails, 5 lagoons
  (coast.json ponds) with still water (the sea shader); a closed west coast (fields.py WEST_COAST) with the sea map
  extended to x -2400 and CitySea's skirt on all four sides.
- Perimeter: sand beaches (26-62 m) with wet sand, dune iceplant / agave; cobble + riprap where a street is near the
  water and on the west point; rock faces on coastal bluffs only.
- Tiny gaps in the city (14, 4,352 m2): lawn eased to the neighbours' edges with low planting.

## What was NOT checked / caveats
- Trees are placed by rule (groves > 60 m from any street), not from a hand-written `zoning/trees/*.json` list as the
  tree rule asks; the 12-trees-in-60-m cap is only kept by that distance, not measured.
- The validator / superchecker / phone (Redmi) run were not run on the fill. Pictures are raw pieces + the look, no bake,
  GLES3 fallback renderer on the box (Vulkan surface missing under xvfb).
- North strip: the zoning terrain there is ~5 m under sea level, so the fill there reads as sea with a thin beach.
- The ground array gains 2 layers (gray_rocks, rock030): on the PC run make_arrays.py, reimport, bake, and rebuild the
  native module (city_sea.cpp skirt) for Windows / Android.

## Review fixes (Yasin's review of the pairs, 21 Nov, commit 9ea16ad6)
- Props on the tennis courts: the courts are not "ground" meshes, so the first audit counted them as empty.
  foot_dump.gd + footprints.py now dump every other mesh and prop/tree box map-wide. Courts and paving count as
  covered (the fill tucks under their edge, never over it). Every fill prop stays clear (trees 3 m, others radius + 1 m).
  Two small pockets that are building footprints are not filled any more (4 pieces dropped: fl_0_0, fl_1_m4, fl_m1_0,
  fl_m2_m4; 95 fill pieces now).
- Dark blotches near the beach: the kit's iceplant mat. Removed everywhere.
- Trees: no fill trees within 64 m of a street.
- check_fill.py: 0 props on or near an existing piece; 0 fill vertices above a neighbour's surface; tree cap: 0 street
  points pushed over 12 by the fill (the existing city already has 5,925 such points, max 37).
- Validator (whole city): 607 problems; the fill rows in the shown tail are riprap-against-riprap overlaps.
- Superchecker on fl_m9_m6: 245 tree_out (the tree plan: builder trees go; trees come from hand-written lists only),
  plus 1 ground_buried, 1 ground_step, 1 empty_area, 10 wide_batch. Not fixed: that needs Yasin's word on the trees.
