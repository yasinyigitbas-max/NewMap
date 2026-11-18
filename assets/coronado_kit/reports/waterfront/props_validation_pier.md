# Props validation (pier)

16/16 files pass. Checks: naming, one mesh/one material, no empties/cameras/lights/anim, POSITION/NORMAL/TANGENT(near)/UV0/COLOR_0 (baked AO), UV1 free, tri budget per class & tier, ground y=0 + origin bottom centre, degenerate/duplicate tris, winding vs normals, inward/enclosed faces (ray parity), faces under ground / hidden bottom faces, alpha only for allowed cut-outs, shared atlas textures <=2048 (trees <=1024), mid/far colour only, collision <=12 boxes or hull <=32 verts.

| file | tier | class | tris | budget | size (w,h,d m) | result | notes |
|---|---|---|---|---|---|---|---|
| prop_pier_lamp_clean_far.glb | far | small | 14 | 20 | [0.37, 4.1, 0.37] | PASS |  |
| prop_pier_lamp_clean_mid.glb | mid | small | 170 | 181 | [0.4, 4.1, 0.4] | PASS |  |
| prop_pier_lamp_clean_near.glb | near | small | 406 | 600 | [0.4, 4.24, 0.38] | PASS |  |
| prop_pier_lamp_col.glb | col |  |  |  |  | PASS |  |
| prop_pier_rail_end_clean_far.glb | far | large | 20 | 20 | [4.0, 4.07, 6.0] | PASS |  |
| prop_pier_rail_end_clean_mid.glb | mid | large | 236 | 751 | [4.1, 4.07, 6.095] | PASS |  |
| prop_pier_rail_end_clean_near.glb | near | large | 1242 | 2500 | [4.182, 4.08, 6.095] | PASS | warn: 150 tris may face inward / be enclosed |
| prop_pier_rail_end_col.glb | col |  |  |  |  | PASS |  |
| prop_pier_straight_clean_far.glb | far | large | 16 | 20 | [4.0, 3.25, 6.0] | PASS |  |
| prop_pier_straight_clean_mid.glb | mid | large | 172 | 751 | [4.1, 3.25, 6.0] | PASS |  |
| prop_pier_straight_clean_near.glb | near | large | 1012 | 2500 | [4.182, 3.25, 6.0] | PASS | warn: 88 tris may face inward / be enclosed |
| prop_pier_straight_col.glb | col |  |  |  |  | PASS |  |
| prop_pier_thead_clean_far.glb | far | large | 20 | 20 | [12.0, 3.25, 6.462] | PASS |  |
| prop_pier_thead_clean_mid.glb | mid | large | 398 | 751 | [12.1, 3.25, 6.58] | PASS |  |
| prop_pier_thead_clean_near.glb | near | large | 2436 | 2500 | [12.1, 4.02, 6.582] | PASS |  |
| prop_pier_thead_col.glb | col |  |  |  |  | PASS |  |
