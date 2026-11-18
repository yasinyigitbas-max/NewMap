# Props validation (promenade)

12/12 files pass. Checks: naming, one mesh/one material, no empties/cameras/lights/anim, POSITION/NORMAL/TANGENT(near)/UV0/COLOR_0 (baked AO), UV1 free, tri budget per class & tier, ground y=0 + origin bottom centre, degenerate/duplicate tris, winding vs normals, inward/enclosed faces (ray parity), faces under ground / hidden bottom faces, alpha only for allowed cut-outs, shared atlas textures <=2048 (trees <=1024), mid/far colour only, collision <=12 boxes or hull <=32 verts.

| file | tier | class | tris | budget | size (w,h,d m) | result | notes |
|---|---|---|---|---|---|---|---|
| prop_prom_boardwalk_clean_far.glb | far | medium | 10 | 20 | [4.0, 0.32, 3.0] | PASS |  |
| prop_prom_boardwalk_clean_mid.glb | mid | medium | 92 | 361 | [4.0, 0.32, 3.0] | PASS | warn: 12 tris may face inward / be enclosed |
| prop_prom_boardwalk_clean_near.glb | near | medium | 520 | 1200 | [4.0, 0.32, 3.004] | PASS | warn: 34 tris may face inward / be enclosed |
| prop_prom_boardwalk_col.glb | col |  |  |  |  | PASS |  |
| prop_prom_rail_clean_far.glb | far | medium | 10 | 20 | [4.04, 1.07, 0.14] | PASS |  |
| prop_prom_rail_clean_mid.glb | mid | medium | 184 | 361 | [4.0, 1.07, 0.14] | PASS |  |
| prop_prom_rail_clean_near.glb | near | medium | 544 | 1200 | [4.09, 1.078, 0.17] | PASS |  |
| prop_prom_rail_col.glb | col |  |  |  |  | PASS |  |
| prop_prom_rail_wall_clean_far.glb | far | medium | 8 | 20 | [2.02, 1.07, 0.14] | PASS |  |
| prop_prom_rail_wall_clean_mid.glb | mid | medium | 126 | 361 | [2.0, 1.1, 0.17] | PASS |  |
| prop_prom_rail_wall_clean_near.glb | near | medium | 332 | 1200 | [2.045, 1.1, 0.17] | PASS | warn: 20 tris may face inward / be enclosed |
| prop_prom_rail_wall_col.glb | col |  |  |  |  | PASS |  |
