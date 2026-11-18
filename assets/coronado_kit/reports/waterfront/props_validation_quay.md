# Props validation (quay)

24/24 files pass. Checks: naming, one mesh/one material, no empties/cameras/lights/anim, POSITION/NORMAL/TANGENT(near)/UV0/COLOR_0 (baked AO), UV1 free, tri budget per class & tier, ground y=0 + origin bottom centre, degenerate/duplicate tris, winding vs normals, inward/enclosed faces (ray parity), faces under ground / hidden bottom faces, alpha only for allowed cut-outs, shared atlas textures <=2048 (trees <=1024), mid/far colour only, collision <=12 boxes or hull <=32 verts.

| file | tier | class | tris | budget | size (w,h,d m) | result | notes |
|---|---|---|---|---|---|---|---|
| prop_quay_corner_in_clean_far.glb | far | large | 8 | 20 | [4.0, 3.0, 4.0] | PASS |  |
| prop_quay_corner_in_clean_mid.glb | mid | large | 228 | 751 | [4.0, 3.119, 4.0] | PASS |  |
| prop_quay_corner_in_clean_near.glb | near | large | 1100 | 2500 | [4.0, 3.123, 4.0] | PASS | warn: 74 tris may face inward / be enclosed |
| prop_quay_corner_in_col.glb | col |  |  |  |  | PASS |  |
| prop_quay_corner_out_clean_far.glb | far | large | 12 | 20 | [1.85, 3.0, 1.85] | PASS |  |
| prop_quay_corner_out_clean_mid.glb | mid | large | 241 | 751 | [2.01, 3.535, 2.01] | PASS | warn: 21 tris may face inward / be enclosed |
| prop_quay_corner_out_clean_near.glb | near | large | 1229 | 2500 | [2.025, 3.535, 2.025] | PASS | warn: 99 tris may face inward / be enclosed |
| prop_quay_corner_out_col.glb | col |  |  |  |  | PASS |  |
| prop_quay_pier_root_clean_far.glb | far | large | 6 | 20 | [6.0, 3.0, 1.85] | PASS |  |
| prop_quay_pier_root_clean_mid.glb | mid | large | 188 | 751 | [6.0, 3.0, 2.01] | PASS | warn: 16 tris may face inward / be enclosed |
| prop_quay_pier_root_clean_near.glb | near | large | 634 | 2500 | [6.0, 3.002, 2.025] | PASS |  |
| prop_quay_pier_root_col.glb | col |  |  |  |  | PASS |  |
| prop_quay_stair_clean_far.glb | far | large | 14 | 20 | [6.0, 3.0, 1.85] | PASS |  |
| prop_quay_stair_clean_mid.glb | mid | large | 308 | 751 | [6.0, 3.535, 2.01] | PASS |  |
| prop_quay_stair_clean_near.glb | near | large | 1848 | 2500 | [6.0, 4.07, 2.025] | PASS |  |
| prop_quay_stair_col.glb | col |  |  |  |  | PASS |  |
| prop_quay_straight_bollards_clean_far.glb | far | large | 6 | 20 | [6.0, 3.0, 1.85] | PASS |  |
| prop_quay_straight_bollards_clean_mid.glb | mid | large | 332 | 751 | [6.0, 3.535, 2.01] | PASS |  |
| prop_quay_straight_bollards_clean_near.glb | near | large | 1606 | 2500 | [6.0, 3.535, 2.025] | PASS | warn: 97 tris may face inward / be enclosed |
| prop_quay_straight_bollards_col.glb | col |  |  |  |  | PASS |  |
| prop_quay_straight_clean_far.glb | far | large | 6 | 20 | [6.0, 3.0, 1.85] | PASS |  |
| prop_quay_straight_clean_mid.glb | mid | large | 234 | 751 | [6.0, 3.535, 2.01] | PASS |  |
| prop_quay_straight_clean_near.glb | near | large | 1638 | 2500 | [6.0, 3.7, 2.025] | PASS |  |
| prop_quay_straight_col.glb | col |  |  |  |  | PASS |  |
