# Props validation (parking)

16/16 files pass. Checks: naming, one mesh/one material, no empties/cameras/lights/anim, POSITION/NORMAL/TANGENT(near)/UV0/COLOR_0 (baked AO), UV1 free, tri budget per class & tier, ground y=0 + origin bottom centre, degenerate/duplicate tris, winding vs normals, inward/enclosed faces (ray parity), faces under ground / hidden bottom faces, alpha only for allowed cut-outs, shared atlas textures <=2048 (trees <=1024), mid/far colour only, collision <=12 boxes or hull <=32 verts.

| file | tier | class | tris | budget | size (w,h,d m) | result | notes |
|---|---|---|---|---|---|---|---|
| prop_cart_corral_clean_far.glb | far | large | 20 | 20 | [4.175, 2.0, 1.645] | PASS |  |
| prop_cart_corral_clean_mid.glb | mid | large | 276 | 751 | [4.161, 2.0, 2.003] | PASS | warn: 42 tris may face inward / be enclosed |
| prop_cart_corral_clean_near.glb | near | large | 672 | 2500 | [4.25, 2.0, 2.08] | PASS | warn: 96 tris may face inward / be enclosed |
| prop_cart_corral_col.glb | col |  |  |  |  | PASS |  |
| prop_shopping_cart_clean_far.glb | far | medium | 14 | 20 | [0.56, 1.06, 1.02] | PASS |  |
| prop_shopping_cart_clean_mid.glb | mid | medium | 104 | 361 | [0.544, 1.049, 1.039] | PASS |  |
| prop_shopping_cart_clean_near.glb | near | medium | 1012 | 1200 | [0.58, 1.046, 1.059] | PASS | warn: 74 tris may face inward / be enclosed |
| prop_shopping_cart_col.glb | col |  |  |  |  | PASS |  |
| prop_wheel_stop_concrete_clean_far.glb | far | tiny | 10 | 20 | [1.83, 0.1, 0.15] | PASS |  |
| prop_wheel_stop_concrete_clean_mid.glb | mid | tiny | 18 | 91 | [1.83, 0.1, 0.15] | PASS |  |
| prop_wheel_stop_concrete_clean_near.glb | near | tiny | 142 | 300 | [1.83, 0.108, 0.15] | PASS |  |
| prop_wheel_stop_concrete_col.glb | col |  |  |  |  | PASS |  |
| prop_wheel_stop_rubber_clean_far.glb | far | tiny | 10 | 20 | [1.83, 0.1, 0.15] | PASS |  |
| prop_wheel_stop_rubber_clean_mid.glb | mid | tiny | 18 | 91 | [1.83, 0.095, 0.15] | PASS |  |
| prop_wheel_stop_rubber_clean_near.glb | near | tiny | 146 | 300 | [1.83, 0.104, 0.15] | PASS |  |
| prop_wheel_stop_rubber_col.glb | col |  |  |  |  | PASS |  |
