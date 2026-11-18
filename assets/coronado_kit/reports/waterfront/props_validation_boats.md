# Props validation (boats)

16/16 files pass. Checks: naming, one mesh/one material, no empties/cameras/lights/anim, POSITION/NORMAL/TANGENT(near)/UV0/COLOR_0 (baked AO), UV1 free, tri budget per class & tier, ground y=0 + origin bottom centre, degenerate/duplicate tris, winding vs normals, inward/enclosed faces (ray parity), faces under ground / hidden bottom faces, alpha only for allowed cut-outs, shared atlas textures <=2048 (trees <=1024), mid/far colour only, collision <=12 boxes or hull <=32 verts.

| file | tier | class | tris | budget | size (w,h,d m) | result | notes |
|---|---|---|---|---|---|---|---|
| prop_boat_express_clean_far.glb | far | large | 20 | 20 | [2.62, 3.047, 9.322] | PASS |  |
| prop_boat_express_clean_mid.glb | mid | large | 254 | 751 | [2.62, 3.027, 9.452] | PASS |  |
| prop_boat_express_clean_near.glb | near | large | 2341 | 2500 | [2.835, 5.247, 9.492] | PASS | warn: 194 tris may face inward / be enclosed |
| prop_boat_express_col.glb | col |  |  |  |  | PASS |  |
| prop_boat_skiff_clean_far.glb | far | medium | 15 | 20 | [1.6, 1.08, 5.218] | PASS |  |
| prop_boat_skiff_clean_mid.glb | mid | medium | 148 | 361 | [1.58, 1.1, 5.198] | PASS | warn: 16 tris may face inward / be enclosed |
| prop_boat_skiff_clean_near.glb | near | medium | 1076 | 1200 | [1.622, 1.116, 5.228] | PASS | warn: 129 tris may face inward / be enclosed |
| prop_boat_skiff_col.glb | col |  |  |  |  | PASS |  |
| prop_boat_sloop_clean_far.glb | far | large | 19 | 20 | [3.1, 13.986, 9.22] | PASS |  |
| prop_boat_sloop_clean_mid.glb | mid | large | 361 | 751 | [2.976, 13.699, 9.2] | PASS |  |
| prop_boat_sloop_clean_near.glb | near | large | 2378 | 2500 | [3.22, 14.597, 9.488] | PASS | warn: 221 tris may face inward / be enclosed |
| prop_boat_sloop_col.glb | col |  |  |  |  | PASS |  |
| prop_boat_troller_clean_far.glb | far | large | 20 | 20 | [3.94, 14.56, 11.937] | PASS |  |
| prop_boat_troller_clean_mid.glb | mid | large | 278 | 751 | [3.82, 14.562, 11.917] | PASS | warn: 18 tris may face inward / be enclosed |
| prop_boat_troller_clean_near.glb | near | large | 2088 | 2500 | [4.106, 14.562, 11.917] | PASS |  |
| prop_boat_troller_col.glb | col |  |  |  |  | PASS |  |
