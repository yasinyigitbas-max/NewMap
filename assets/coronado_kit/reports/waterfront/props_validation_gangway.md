# Props validation (gangway)

4/4 files pass. Checks: naming, one mesh/one material, no empties/cameras/lights/anim, POSITION/NORMAL/TANGENT(near)/UV0/COLOR_0 (baked AO), UV1 free, tri budget per class & tier, ground y=0 + origin bottom centre, degenerate/duplicate tris, winding vs normals, inward/enclosed faces (ray parity), faces under ground / hidden bottom faces, alpha only for allowed cut-outs, shared atlas textures <=2048 (trees <=1024), mid/far colour only, collision <=12 boxes or hull <=32 verts.

| file | tier | class | tris | budget | size (w,h,d m) | result | notes |
|---|---|---|---|---|---|---|---|
| prop_gangway_clean_far.glb | far | large | 12 | 20 | [1.3, 2.12, 11.0] | PASS |  |
| prop_gangway_clean_mid.glb | mid | large | 226 | 751 | [1.292, 2.118, 11.0] | PASS |  |
| prop_gangway_clean_near.glb | near | large | 2382 | 2500 | [1.29, 2.119, 11.0] | PASS |  |
| prop_gangway_col.glb | col |  |  |  |  | PASS |  |
