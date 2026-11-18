# Props validation (marina)

20/20 files pass. Checks: naming, one mesh/one material, no empties/cameras/lights/anim, POSITION/NORMAL/TANGENT(near)/UV0/COLOR_0 (baked AO), UV1 free, tri budget per class & tier, ground y=0 + origin bottom centre, degenerate/duplicate tris, winding vs normals, inward/enclosed faces (ray parity), faces under ground / hidden bottom faces, alpha only for allowed cut-outs, shared atlas textures <=2048 (trees <=1024), mid/far colour only, collision <=12 boxes or hull <=32 verts.

| file | tier | class | tris | budget | size (w,h,d m) | result | notes |
|---|---|---|---|---|---|---|---|
| prop_dock_box_clean_far.glb | far | small | 10 | 20 | [1.535, 0.62, 0.639] | PASS |  |
| prop_dock_box_clean_mid.glb | mid | small | 18 | 181 | [1.543, 0.62, 0.645] | PASS |  |
| prop_dock_box_clean_near.glb | near | small | 266 | 600 | [1.543, 0.62, 0.74] | PASS |  |
| prop_dock_box_col.glb | col |  |  |  |  | PASS |  |
| prop_marina_finger_clean_far.glb | far | large | 16 | 20 | [3.0, 0.75, 7.58] | PASS | warn: origin off footprint centre (0.00,3.79) - asymmetric parts? |
| prop_marina_finger_clean_mid.glb | mid | large | 94 | 751 | [3.0, 0.75, 7.56] | PASS | warn: origin off footprint centre (0.00,3.78) - asymmetric parts?; warn: 16 tris may face inward / be enclosed |
| prop_marina_finger_clean_near.glb | near | large | 1172 | 2500 | [3.085, 0.869, 7.617] | PASS | warn: origin off footprint centre (0.00,3.75) - asymmetric parts?; warn: 204 tris may face inward / be enclosed |
| prop_marina_finger_col.glb | col |  |  |  |  | PASS |  |
| prop_marina_float_clean_far.glb | far | large | 10 | 20 | [6.0, 0.75, 2.62] | PASS |  |
| prop_marina_float_clean_mid.glb | mid | large | 134 | 751 | [6.0, 0.84, 2.62] | PASS | warn: 16 tris may face inward / be enclosed |
| prop_marina_float_clean_near.glb | near | large | 1470 | 2500 | [6.047, 0.869, 2.72] | PASS | warn: 191 tris may face inward / be enclosed |
| prop_marina_float_col.glb | col |  |  |  |  | PASS |  |
| prop_marina_pedestal_clean_far.glb | far | small | 12 | 20 | [0.4, 1.17, 0.34] | PASS |  |
| prop_marina_pedestal_clean_mid.glb | mid | small | 30 | 181 | [0.4, 1.15, 0.34] | PASS |  |
| prop_marina_pedestal_clean_near.glb | near | small | 188 | 600 | [0.404, 1.17, 0.356] | PASS | warn: 20 tris may face inward / be enclosed |
| prop_marina_pedestal_col.glb | col |  |  |  |  | PASS |  |
| prop_marina_pile_clean_far.glb | far | medium | 14 | 20 | [0.6, 5.3, 0.71] | PASS |  |
| prop_marina_pile_clean_mid.glb | mid | medium | 112 | 361 | [0.6, 5.46, 0.706] | PASS |  |
| prop_marina_pile_clean_near.glb | near | medium | 510 | 1200 | [0.6, 5.46, 0.706] | PASS | warn: 112 tris may face inward / be enclosed |
| prop_marina_pile_col.glb | col |  |  |  |  | PASS |  |
