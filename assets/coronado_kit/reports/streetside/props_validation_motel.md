# Props validation (motel)

12/12 files pass. Checks: naming, one mesh/one material, no empties/cameras/lights/anim, POSITION/NORMAL/TANGENT(near)/UV0/COLOR_0 (baked AO), UV1 free, tri budget per class & tier, ground y=0 + origin bottom centre, degenerate/duplicate tris, winding vs normals, inward/enclosed faces (ray parity), faces under ground / hidden bottom faces, alpha only for allowed cut-outs, shared atlas textures <=2048 (trees <=1024), mid/far colour only, collision <=12 boxes or hull <=32 verts.

| file | tier | class | tris | budget | size (w,h,d m) | result | notes |
|---|---|---|---|---|---|---|---|
| prop_ice_chest_clean_far.glb | far | small | 10 | 20 | [1.36, 1.24, 0.78] | PASS |  |
| prop_ice_chest_clean_mid.glb | mid | small | 24 | 181 | [1.36, 1.24, 0.783] | PASS | warn: 4 tris may face inward / be enclosed |
| prop_ice_chest_clean_near.glb | near | small | 414 | 600 | [1.642, 1.266, 1.337] | PASS | warn: origin off footprint centre (-0.08,-0.21) - asymmetric parts?; warn: 52 tris may face inward / be enclosed |
| prop_ice_chest_col.glb | col |  |  |  |  | PASS |  |
| prop_vending_snack_clean_far.glb | far | small | 10 | 20 | [1.0, 1.83, 0.9] | PASS |  |
| prop_vending_snack_clean_mid.glb | mid | small | 16 | 181 | [1.0, 1.83, 0.903] | PASS |  |
| prop_vending_snack_clean_near.glb | near | small | 410 | 600 | [1.057, 1.83, 1.43] | PASS | warn: origin off footprint centre (-0.02,-0.22) - asymmetric parts?; warn: 45 tris may face inward / be enclosed |
| prop_vending_snack_col.glb | col |  |  |  |  | PASS |  |
| prop_vending_soda_clean_far.glb | far | small | 10 | 20 | [0.95, 1.83, 0.85] | PASS |  |
| prop_vending_soda_clean_mid.glb | mid | small | 16 | 181 | [0.95, 1.83, 0.853] | PASS |  |
| prop_vending_soda_clean_near.glb | near | small | 474 | 600 | [1.032, 1.83, 1.425] | PASS | warn: origin off footprint centre (0.04,-0.20) - asymmetric parts?; warn: 55 tris may face inward / be enclosed |
| prop_vending_soda_col.glb | col |  |  |  |  | PASS |  |
