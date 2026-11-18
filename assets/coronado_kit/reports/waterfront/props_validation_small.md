# Props validation (small)

44/44 files pass. Checks: naming, one mesh/one material, no empties/cameras/lights/anim, POSITION/NORMAL/TANGENT(near)/UV0/COLOR_0 (baked AO), UV1 free, tri budget per class & tier, ground y=0 + origin bottom centre, degenerate/duplicate tris, winding vs normals, inward/enclosed faces (ray parity), faces under ground / hidden bottom faces, alpha only for allowed cut-outs, shared atlas textures <=2048 (trees <=1024), mid/far colour only, collision <=12 boxes or hull <=32 verts.

| file | tier | class | tris | budget | size (w,h,d m) | result | notes |
|---|---|---|---|---|---|---|---|
| prop_beach_shower_clean_far.glb | far | small | 10 | 20 | [1.1, 2.45, 1.1] | PASS |  |
| prop_beach_shower_clean_mid.glb | mid | small | 56 | 181 | [1.1, 2.455, 1.1] | PASS |  |
| prop_beach_shower_clean_near.glb | near | small | 466 | 600 | [1.1, 2.452, 1.11] | PASS | warn: 60 tris may face inward / be enclosed |
| prop_beach_shower_col.glb | col |  |  |  |  | PASS |  |
| prop_beach_umbrella_clean_far.glb | far | small | 14 | 20 | [1.94, 2.32, 1.94] | PASS |  |
| prop_beach_umbrella_clean_mid.glb | mid | small | 70 | 181 | [1.94, 2.32, 1.94] | PASS | warn: 20 tris may face inward / be enclosed |
| prop_beach_umbrella_clean_near.glb | near | small | 546 | 600 | [1.94, 2.52, 1.94] | PASS | warn: 190 tris may face inward / be enclosed |
| prop_beach_umbrella_closed_clean_far.glb | far | small | 13 | 20 | [0.6, 2.45, 0.52] | PASS |  |
| prop_beach_umbrella_closed_clean_mid.glb | mid | small | 78 | 181 | [0.6, 2.32, 0.52] | PASS | warn: 8 tris may face inward / be enclosed |
| prop_beach_umbrella_closed_clean_near.glb | near | small | 346 | 600 | [0.6, 2.46, 0.6] | PASS | warn: 26 tris may face inward / be enclosed |
| prop_beach_umbrella_closed_col.glb | col |  |  |  |  | PASS |  |
| prop_beach_umbrella_col.glb | col |  |  |  |  | PASS |  |
| prop_boat_trailer_clean_far.glb | far | large | 18 | 20 | [2.0, 1.611, 6.58] | PASS |  |
| prop_boat_trailer_clean_mid.glb | mid | large | 372 | 751 | [2.0, 1.811, 6.614] | PASS | warn: 49 tris may face inward / be enclosed |
| prop_boat_trailer_clean_near.glb | near | large | 2238 | 2500 | [2.0, 1.75, 6.737] | PASS | warn: 313 tris may face inward / be enclosed |
| prop_boat_trailer_col.glb | col |  |  |  |  | PASS |  |
| prop_buoy_can_clean_far.glb | far | small | 14 | 20 | [0.88, 2.16, 1.761] | PASS | warn: origin off footprint centre (0.00,-0.50) - asymmetric parts? |
| prop_buoy_can_clean_mid.glb | mid | small | 68 | 181 | [0.727, 2.15, 1.795] | PASS | warn: origin off footprint centre (0.00,-0.48) - asymmetric parts? |
| prop_buoy_can_clean_near.glb | near | small | 325 | 600 | [0.799, 2.681, 1.795] | PASS | warn: origin off footprint centre (0.00,-0.48) - asymmetric parts? |
| prop_buoy_can_col.glb | col |  |  |  |  | PASS |  |
| prop_buoy_mooring_clean_far.glb | far | small | 16 | 20 | [0.84, 2.0, 1.534] | PASS | warn: origin off footprint centre (0.00,-0.40) - asymmetric parts? |
| prop_buoy_mooring_clean_mid.glb | mid | small | 96 | 181 | [0.8, 2.08, 1.577] | PASS | warn: origin off footprint centre (0.00,-0.39) - asymmetric parts? |
| prop_buoy_mooring_clean_near.glb | near | small | 446 | 600 | [1.03, 2.45, 1.62] | PASS | warn: origin off footprint centre (0.11,-0.41) - asymmetric parts? |
| prop_buoy_mooring_col.glb | col |  |  |  |  | PASS |  |
| prop_buoy_nun_clean_far.glb | far | small | 15 | 20 | [0.88, 2.45, 1.761] | PASS | warn: origin off footprint centre (0.00,-0.50) - asymmetric parts? |
| prop_buoy_nun_clean_mid.glb | mid | small | 68 | 181 | [0.727, 2.45, 1.795] | PASS | warn: origin off footprint centre (0.00,-0.48) - asymmetric parts? |
| prop_buoy_nun_clean_near.glb | near | small | 345 | 600 | [0.799, 2.951, 1.795] | PASS | warn: origin off footprint centre (0.00,-0.48) - asymmetric parts?; warn: 29 tris may face inward / be enclosed |
| prop_buoy_nun_col.glb | col |  |  |  |  | PASS |  |
| prop_fuel_pump_clean_far.glb | far | medium | 18 | 20 | [1.4, 1.78, 1.1] | PASS | warn: origin off footprint centre (0.00,-0.12) - asymmetric parts? |
| prop_fuel_pump_clean_mid.glb | mid | medium | 68 | 361 | [1.4, 1.78, 1.1] | PASS | warn: origin off footprint centre (0.00,-0.12) - asymmetric parts? |
| prop_fuel_pump_clean_near.glb | near | medium | 912 | 1200 | [1.4, 1.78, 1.1] | PASS | warn: origin off footprint centre (0.00,-0.12) - asymmetric parts?; warn: 60 tris may face inward / be enclosed |
| prop_fuel_pump_col.glb | col |  |  |  |  | PASS |  |
| prop_kayak_rack_clean_far.glb | far | medium | 20 | 20 | [3.6, 2.05, 1.594] | PASS |  |
| prop_kayak_rack_clean_mid.glb | mid | medium | 252 | 361 | [3.6, 2.05, 1.8] | PASS |  |
| prop_kayak_rack_clean_near.glb | near | medium | 1174 | 1200 | [3.6, 2.05, 1.86] | PASS | warn: 88 tris may face inward / be enclosed |
| prop_kayak_rack_col.glb | col |  |  |  |  | PASS |  |
| prop_lifering_stand_clean_far.glb | far | small | 16 | 20 | [0.66, 1.78, 0.2] | PASS |  |
| prop_lifering_stand_clean_mid.glb | mid | small | 108 | 181 | [0.708, 1.75, 0.2] | PASS | warn: 16 tris may face inward / be enclosed |
| prop_lifering_stand_clean_near.glb | near | small | 490 | 600 | [0.688, 1.774, 0.26] | PASS | warn: 86 tris may face inward / be enclosed |
| prop_lifering_stand_col.glb | col |  |  |  |  | PASS |  |
| prop_volleyball_net_clean_far.glb | far | medium | 18 | 20 | [10.22, 2.6, 0.18] | PASS |  |
| prop_volleyball_net_clean_mid.glb | mid | medium | 224 | 361 | [10.191, 2.6, 0.22] | PASS | warn: 24 tris may face inward / be enclosed |
| prop_volleyball_net_clean_near.glb | near | medium | 1056 | 1200 | [13.32, 3.23, 2.12] | PASS | warn: 82 tris may face inward / be enclosed |
| prop_volleyball_net_col.glb | col |  |  |  |  | PASS |  |
