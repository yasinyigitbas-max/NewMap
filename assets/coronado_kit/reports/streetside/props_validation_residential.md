# Props validation (residential)

16/16 files pass. Checks: naming, one mesh/one material, no empties/cameras/lights/anim, POSITION/NORMAL/TANGENT(near)/UV0/COLOR_0 (baked AO), UV1 free, tri budget per class & tier, ground y=0 + origin bottom centre, degenerate/duplicate tris, winding vs normals, inward/enclosed faces (ray parity), faces under ground / hidden bottom faces, alpha only for allowed cut-outs, shared atlas textures <=2048 (trees <=1024), mid/far colour only, collision <=12 boxes or hull <=32 verts.

| file | tier | class | tris | budget | size (w,h,d m) | result | notes |
|---|---|---|---|---|---|---|---|
| prop_balcony_clutter_clean_far.glb | far | large | 16 | 20 | [3.0, 1.232, 1.2] | PASS |  |
| prop_balcony_clutter_clean_mid.glb | mid | large | 187 | 751 | [3.0, 1.232, 1.2] | PASS | warn: 20 tris may face inward / be enclosed |
| prop_balcony_clutter_clean_near.glb | near | large | 1442 | 2500 | [3.03, 1.413, 1.215] | PASS |  |
| prop_balcony_clutter_col.glb | col |  |  |  |  | PASS |  |
| prop_buzzer_panel_clean_far.glb | far | tiny | 12 | 20 | [0.28, 0.775, 0.06] | PASS |  |
| prop_buzzer_panel_clean_mid.glb | mid | tiny | 38 | 91 | [0.28, 0.771, 0.064] | PASS | warn: 3 tris may face inward / be enclosed |
| prop_buzzer_panel_clean_near.glb | near | tiny | 200 | 300 | [0.28, 0.775, 0.064] | PASS | warn: 27 tris may face inward / be enclosed |
| prop_buzzer_panel_col.glb | col |  |  |  |  | PASS |  |
| prop_clothesline_clean_far.glb | far | medium | 20 | 20 | [5.08, 2.05, 0.924] | PASS |  |
| prop_clothesline_clean_mid.glb | mid | medium | 78 | 361 | [5.06, 2.04, 1.717] | PASS |  |
| prop_clothesline_clean_near.glb | near | medium | 755 | 1200 | [5.2, 2.06, 1.75] | PASS | warn: 46 tris may face inward / be enclosed |
| prop_clothesline_col.glb | col |  |  |  |  | PASS |  |
| prop_dingbat_stair_clean_far.glb | far | large | 14 | 20 | [5.5, 3.95, 0.975] | PASS |  |
| prop_dingbat_stair_clean_mid.glb | mid | large | 206 | 751 | [5.85, 3.95, 1.1] | PASS | warn: 28 tris may face inward / be enclosed |
| prop_dingbat_stair_clean_near.glb | near | large | 1008 | 2500 | [5.96, 3.98, 1.135] | PASS |  |
| prop_dingbat_stair_col.glb | col |  |  |  |  | PASS |  |
