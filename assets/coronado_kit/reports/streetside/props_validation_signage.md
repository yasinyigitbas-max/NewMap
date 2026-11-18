# Props validation (signage)

12/12 files pass. Checks: naming, one mesh/one material, no empties/cameras/lights/anim, POSITION/NORMAL/TANGENT(near)/UV0/COLOR_0 (baked AO), UV1 free, tri budget per class & tier, ground y=0 + origin bottom centre, degenerate/duplicate tris, winding vs normals, inward/enclosed faces (ray parity), faces under ground / hidden bottom faces, alpha only for allowed cut-outs, shared atlas textures <=2048 (trees <=1024), mid/far colour only, collision <=12 boxes or hull <=32 verts.

| file | tier | class | tris | budget | size (w,h,d m) | result | notes |
|---|---|---|---|---|---|---|---|
| prop_bus_stop_sign_clean_far.glb | far | medium | 12 | 20 | [0.595, 3.31, 0.15] | PASS | warn: origin off footprint centre (0.17,0.03) - asymmetric parts? |
| prop_bus_stop_sign_clean_mid.glb | mid | medium | 32 | 361 | [0.595, 3.31, 0.137] | PASS | warn: origin off footprint centre (0.17,0.04) - asymmetric parts? |
| prop_bus_stop_sign_clean_near.glb | near | medium | 290 | 1200 | [0.625, 3.31, 0.304] | PASS | warn: origin off footprint centre (0.15,0.00) - asymmetric parts?; warn: 29 tris may face inward / be enclosed |
| prop_bus_stop_sign_col.glb | col |  |  |  |  | PASS |  |
| prop_drive_thru_menu_clean_far.glb | far | medium | 20 | 20 | [2.95, 2.42, 0.8] | PASS |  |
| prop_drive_thru_menu_clean_mid.glb | mid | medium | 74 | 361 | [2.96, 2.4, 1.01] | PASS | warn: 5 tris may face inward / be enclosed |
| prop_drive_thru_menu_clean_near.glb | near | medium | 744 | 1200 | [2.96, 2.67, 1.025] | PASS | warn: 74 tris may face inward / be enclosed |
| prop_drive_thru_menu_col.glb | col |  |  |  |  | PASS |  |
| prop_pylon_sign_clean_far.glb | far | large | 12 | 20 | [3.6, 7.52, 1.64] | PASS |  |
| prop_pylon_sign_clean_mid.glb | mid | large | 162 | 751 | [3.6, 7.52, 1.65] | PASS | warn: 12 tris may face inward / be enclosed |
| prop_pylon_sign_clean_near.glb | near | large | 1324 | 2500 | [3.6, 7.592, 1.65] | PASS | warn: 178 tris may face inward / be enclosed |
| prop_pylon_sign_col.glb | col |  |  |  |  | PASS |  |
