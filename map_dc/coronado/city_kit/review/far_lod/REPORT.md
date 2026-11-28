# Far world in tiles with LOD (28 Nov 2026, cloud session)

Yasin: "how long would it take?", "cant the far world be done on a cloud session? its bound to be faster than this pc?",
"yes start it in the cloud". Branch `claude/far-world-lod`, from `claude/night-28nov`. Only the bake changed
(`tools/city/bake/bake_runtime.gd`), plus two view options in `tools/city/bake/rt_shots.gd`. No shader, no locked piece,
no layout, no C++ changed. The streamer needs no change.

## Layout for loaders (read first)
- There is still ONE file, `runtime/far/far_world.scn`. Its children are now 82 tiles plus `far_ground` (before: 23 chunks
  plus `far_ground`). Tile names: `far_X_Z_KIND` (X, Z = 400 m tile; plants `far_X_Z_cut` keep 1 km chunks), and fence
  tiles `far_X_Z_solid_e500`.
- Every tile mesh is now INDEXED and carries LOD index arrays. Godot picks a level from the distance to the tile's box.
  **An orthographic camera (e.g. `tools/city/look/city_light_bake.gd`, the top-down height map on the look branch) picks
  LODs from a fixed distance, so it can get coarse levels.** Set that viewport's `mesh_lod_threshold = 0.0` to always
  draw full detail.
- The fence tiles (`*_e500`) have `visibility_range_end` set (500 m + the tile's radius, measured from the tile box's
  centre). A camera far above the island (a top-down render) would hide them. Set `visibility_range_end = 0` on
  the far tiles in such a tool.
- Per-vertex data is unchanged: every vertex of every LOD level is an original vertex (same UV, UV2 packing, COLOR,
  normal, CUSTOM0 pivot and far end). Only the index lists are shorter. rt_far's night window lights read the same
  data (night views below: identical).

## What changed and why
The bake made the far world as 24 big meshes of 1 km. They were so big that nearly all of it was drawn every frame. The
bake now writes, per far object, exactly the same triangles as before, but:
1. **Tiles**: buildings and far props in 400 m tiles (one per material), plants in 1 km chunks (2 % of the triangles,
   kept big to save draws). The engine culls tiles outside the view and beyond the camera's 900 m.
2. **Fence tiles end where fences end**: fences were **81 % of the far world** (86,080 fence pieces, 804,296 of 995,893
   triangles; they are the only far props exempt from the 2.5 m size cut, and rt_far hides each one from 500 m). They
   now have tiles of their own whose `visibility_range_end` is 500 m + the tile's radius. A tile goes only when EVERY
   fence in it is already past 500 m, where the shader collapses it anyway. So this is exact.
3. **LOD**: each far object (each distinct kit far mesh, once) is simplified on its own with Godot's
   `ImporterMesh.generate_lods` (meshoptimizer, borders locked, seams kept). A tile's level k takes each object's
   coarsest level whose error is under a step (0.03 m ... 8 m), and the level's key is the largest error used. Godot
   uses a level only where that error is under 1 screen pixel (mesh_lod_threshold 1 px of the 2460 px wide phone
   screen). No triangle ever joins two objects, so each object still collapses exactly where it did.
   **Fences are left whole by default**: their posts are 5 cm thick, much thinner than a pixel, and a simplified post
   lights other single pixels (the one difference found, picture `option_farlodfence_posts.jpg`). `--farlodfence`
   simplifies them too (68 % cut instead of 61 %, those post pixels change).
- Switches: `--nofarlod` bakes the far world exactly as before (1 km chunks, no LOD, no fence tiles). `--fartile=M`
  sets another tile size.

## The far world, whole island
| | before | after |
|---|---:|---:|
| meshes (draw nodes) | 24 (23 chunks + far ground) | 83 (82 tiles + far ground) |
| triangles at full detail | 995,893 | 995,893 (identical) |
| triangles at each tile's coarsest level | 995,893 | 928,811 (fences whole; 893,411 in the tiles + 35,400 far ground) |
| `far_world.scn` on disk | 15.3 MB | 21.7 MB (the LOD index lists) |

What it is made of (`BAKE far LOD mix`: objects, triangles, triangles at their own coarsest level):
buildings 2,862 / 87,340 / 49,448; far props 3,052 / 53,729 / 21,667; fences 86,080 / 804,296 / (561,488, used only with
`--farlodfence`); plants 7,564 / 15,128 / 15,128. So the static simplification is small (−7 %). Most of the win per
frame comes from the tiles: what is behind the camera, beyond 900 m and (for fences) beyond 500 m is no longer drawn.

## Per view: triangles and draws, before and after
Measured in the cloud (Godot 4.7.2 mobile renderer on lavapipe, a software GPU: **no GPU timings here; the phone
measures milliseconds**). Window 2460 x 1080 (the Redmi's screen; LOD selection depends on the width), camera fov 74
and far 900 (the game's driving camera). Day, the census views of `tools/city/rig/rig.gd` at street eye height in their
own direction (`_street`), and the same places from 45 m up looking 600 m out (`_high`). "Far world" = the frame's
triangles minus the same frame with the far world hidden (`--nofar`). Note: rt_shots' frames include its own sun
shadow (220 m, 4 splits, not the game's 50 m), so the frame totals are larger than the phone's census. Only ~12 cells
were in at each view (the cloud loads slowly): more far versions show than on the phone, the same in both runs.
"Far-world pixels compared / changed": pixels where the far world shows and that do not move between two renders of
the same bake (wind, traffic signals), and how many of them differ by more than 16/255 before → after.

| view | frame triangles before → after | frame draws before → after | far world triangles before → after | cut | far world draws before → after | with --farlodfence: far triangles (cut) | far-world pixels compared / changed |
|---|---|---|---|---:|---|---|---|
| centre_street | 1,432,317 → 1,286,747 | 166 → 181 | 432,475 → 286,905 | 34 % | 8 → 23 | 237,479 (45 %) | 1,747 / 1,273 |
| centre_high | 1,257,688 → 1,112,118 | 132 → 147 | 430,805 → 285,235 | 34 % | 7 → 22 | 222,145 (48 %) | 117,265 / 43 |
| apartments_street | 1,900,131 → 1,664,976 | 176 → 188 | 437,435 → 202,280 | 54 % | 11 → 23 | 180,612 (59 %) | 102 / 2 |
| apartments_high | 1,479,189 → 1,244,034 | 137 → 149 | 437,435 → 202,280 | 54 % | 11 → 23 | 166,948 (62 %) | 277,432 / 254 |
| gritty_street | 1,664,051 → 900,989 | 134 → 147 | 980,123 → 217,061 | 78 % | 13 → 26 | 188,665 (81 %) | 4,664 / 50 |
| gritty_high | 1,493,991 → 735,799 | 114 → 128 | 980,123 → 221,931 | 77 % | 13 → 27 | 193,535 (80 %) | 283,476 / 163 |
| waterfront_street | 2,057,638 → 1,449,013 | 141 → 150 | 845,084 → 236,459 | 72 % | 12 → 21 | 196,025 (77 %) | 1,850 / 479 |
| waterfront_high | 1,691,943 → 1,083,318 | 111 → 120 | 845,084 → 236,459 | 72 % | 12 → 21 | 188,377 (78 %) | 251,766 / 115 |
| industrial_street | 1,371,502 → 700,929 | 186 → 199 | 831,624 → 161,051 | 81 % | 11 → 24 | 152,273 (82 %) | 3,908 / 1 |
| industrial_high | 1,243,832 → 573,259 | 158 → 171 | 831,624 → 161,051 | 81 % | 11 → 24 | 152,273 (82 %) | 240,679 / 67 |
| pilot_street | 1,419,918 → 1,410,822 | 153 → 159 | 269,546 → 260,450 | 3 % | 8 → 14 | 212,308 (21 %) | 2,770 / 7 |
| pilot_high | 976,960 → 967,864 | 123 → 129 | 269,546 → 260,450 | 3 % | 8 → 14 | 209,156 (22 %) | 254,388 / 253 |
| civic_street | 1,406,970 → 1,095,313 | 153 → 171 | 700,800 → 389,143 | 44 % | 9 → 27 | 298,397 (57 %) | 26,580 / 22 |
| civic_high | 1,292,897 → 981,240 | 128 → 146 | 700,800 → 389,143 | 44 % | 9 → 27 | 293,701 (58 %) | 338,499 / 17 |
| **all 14 views** | | | **8,992,504 → 3,509,898** | **61 %** | | **2,891,894 (68 %)** | |

## Does anything look different?
- **Day, 14 views, and night, 14 views: no difference I can find in the far world.** The pictures in this folder show
  each view before (left) and after (right), and the densest far-world area of the view at 2x, pixel for pixel. The far
  pixels that differ (table above) are under 0.1 % in the views from 45 m up. Where a street view shows more, the
  marked pixels were near things that also differ between two renders of the SAME bake: palm and tree edges in the wind
  and the traffic signals (centre_street, waterfront_street). Night (`--night=1`): at most 0.2 % of a frame differs,
  in the same places. The far window lights look the same.
- **The one real difference** was with fences simplified: single pixels of far fence posts appear or vanish
  (`option_farlodfence_posts.jpg`). Fences are therefore left whole by default.
- **Not checked**: the phone itself (GPU ms, how the Mali handles the extra draws), sunrise / dusk colours, the
  `CK_TIERS` variant (it uses the same per-vertex data, so it should behave the same), and moving shots (a LOD level
  switches per tile as the camera moves; by construction the switch is under one pixel). The trees near the camera
  render black in the cloud renderer (lavapipe). They are near tiers, the same in both runs.

## Costs and trade-offs
- **The pilot view gains only 3 %**: almost every far tile it sees is in front of the camera and within reach. The
  cut is big where the far world lies behind the camera or beyond 500 m of fences (gritty, industrial, waterfront).
- **Draw calls**: +6 to +18 per view for the far world (before 7-13, after 14-27). Yasin's rule is draws first:
  tiles were made bigger where they buy nothing (plants back to 1 km, props share the building tiles). A first try
  with a tile per kind and end distance cost +12 to +40 draws.
- The far world file is 6.4 MB bigger (the LOD index lists). Its vertex buffer is now indexed: fewer vertices.
- Bake time: about +20 s.

## For the phone run (night session)
Merge, rebake (`bash tools/city/rig/phone_rig.sh bake`, the log shows `BAKE far tile ...` lines and
`BAKE far world: 83 meshes, 995893 triangles`), and run the census. `hide_far` still hides all far tiles (the rig
hides every child of the far world but `far_ground`). For an A/B, the old far world comes back by adding `--nofarlod` to the bake's command line (phone_rig.sh's `-- --all`).

## The per-tile table (fences whole, as baked)
| tile (x_z = 400 m tile; plants: 1 km) | objects | triangles | vertices | LOD levels [error m, triangles] | coarsest |
|---|---:|---:|---:|---|---:|
| far_-1_-1_cut | 835 | 1670 | 3340 | - | 1670 |
| far_-1_-1_solid | 261 | 6426 | 12048 | 0.006:6078 0.059:5702 0.447:5412 1.985:4852 3.729:4320 6.284:3538 | 3538 |
| far_-1_-1_solid_e500 | 5804 | 55916 | 144652 | - | 55916 |
| far_-1_-2_cut | 379 | 758 | 1516 | - | 758 |
| far_-1_-2_solid | 157 | 4100 | 7816 | 0.01:3438 0.059:3190 0.937:3022 1.966:2512 3.729:2312 6.888:2176 | 2176 |
| far_-1_-2_solid_e500 | 741 | 9920 | 21832 | - | 9920 |
| far_-1_-3_solid | 264 | 6412 | 11942 | 0.011:6090 0.059:5654 0.447:5352 1.966:4986 3.858:4226 6.284:3512 | 3512 |
| far_-1_-3_solid_e500 | 4383 | 43132 | 110372 | - | 43132 |
| far_-1_-4_solid | 207 | 5745 | 10651 | 0.005:5257 0.059:4623 0.447:4167 1.985:3763 3.858:3385 6.013:3139 | 3139 |
| far_-1_-4_solid_e500 | 3570 | 32464 | 84716 | - | 32464 |
| far_-1_-5_solid | 14 | 370 | 644 | 0.083:190 0.173:88 | 88 |
| far_-1_0_cut | 506 | 1012 | 2024 | - | 1012 |
| far_-1_0_solid | 296 | 7140 | 13562 | 0.059:6368 0.184:6022 0.447:5558 1.985:5026 3.858:4354 7.518:3632 | 3632 |
| far_-1_0_solid_e500 | 6485 | 57718 | 156186 | - | 57718 |
| far_-2_-1_cut | 1378 | 2756 | 5512 | - | 2756 |
| far_-2_-1_solid | 397 | 9067 | 17050 | 0.059:8051 0.447:7461 1.985:6775 3.858:5973 6.284:4923 | 4923 |
| far_-2_-1_solid_e500 | 10778 | 103112 | 275680 | - | 103112 |
| far_-2_-2_cut | 1222 | 2444 | 4888 | - | 2444 |
| far_-2_-2_solid | 61 | 1594 | 3222 | 0.01:1494 0.055:1350 0.123:1278 1.665:1058 3.578:906 5.189:848 | 848 |
| far_-2_-2_solid_e500 | 113 | 678 | 2034 | - | 678 |
| far_-2_-3_solid | 253 | 5731 | 11148 | 0.009:5043 0.059:4643 0.491:4267 1.9:4003 3.578:3643 7.011:3161 | 3161 |
| far_-2_-3_solid_e500 | 1199 | 10988 | 32424 | - | 10988 |
| far_-2_-4_solid | 365 | 7116 | 16464 | 0.059:6674 0.937:5158 1.912:4608 6.438:3542 | 3542 |
| far_-2_-4_solid_e500 | 1824 | 14494 | 43014 | - | 14494 |
| far_-2_-5_solid | 12 | 314 | 548 | 0.083:162 0.173:76 | 76 |
| far_-2_0_cut | 1719 | 3438 | 6876 | - | 3438 |
| far_-2_0_solid | 298 | 6823 | 12660 | 0.059:6127 0.447:5531 1.985:5153 3.858:4499 6.284:3667 | 3667 |
| far_-2_0_solid_e500 | 8318 | 71204 | 189864 | - | 71204 |
| far_-2_1_solid | 1 | 14 | 42 | - | 14 |
| far_-3_-1_solid | 84 | 2987 | 5323 | 0.059:2631 0.447:2427 0.937:2267 1.985:2077 3.858:1623 6.284:1415 | 1415 |
| far_-3_-1_solid_e500 | 3708 | 22648 | 67944 | - | 22648 |
| far_-3_-2_solid | 74 | 2429 | 4439 | 0.008:2293 0.059:2005 0.447:1789 1.985:1681 3.858:1341 6.284:1109 | 1109 |
| far_-3_-2_solid_e500 | 3744 | 22864 | 68592 | - | 22864 |
| far_-3_-3_solid | 87 | 2104 | 4064 | 0.005:1934 0.059:1746 0.447:1582 1.9:1472 3.578:1302 6.013:1130 | 1130 |
| far_-3_-3_solid_e500 | 828 | 7064 | 20824 | - | 7064 |
| far_-3_-4_solid | 441 | 5372 | 14377 | 0.173:5024 1.9:4728 7.011:4450 | 4450 |
| far_-3_-4_solid_e500 | 1114 | 15246 | 41302 | - | 15246 |
| far_-3_-5_solid | 6 | 146 | 260 | 0.055:134 0.083:78 0.173:40 | 40 |
| far_-3_0_solid | 21 | 512 | 920 | 0.083:390 0.173:322 2.119:304 4.649:190 | 190 |
| far_-3_0_solid_e500 | 674 | 4128 | 12384 | - | 4128 |
| far_-4_1_solid | 1 | 14 | 42 | - | 14 |
| far_0_-1_cut | 528 | 1056 | 2112 | - | 1056 |
| far_0_-1_solid | 346 | 8557 | 15822 | 0.011:7695 0.059:7127 0.447:6687 1.985:6143 3.858:5163 6.284:4557 | 4557 |
| far_0_-1_solid_e500 | 6256 | 54318 | 145582 | - | 54318 |
| far_0_-2_cut | 407 | 814 | 1628 | - | 814 |
| far_0_-2_solid | 313 | 8466 | 15798 | 0.011:7124 0.059:6512 0.447:5964 3.729:4804 | 4804 |
| far_0_-2_solid_e500 | 2845 | 33724 | 78032 | - | 33724 |
| far_0_-3_solid | 399 | 9517 | 17669 | 0.009:8765 0.059:7997 0.447:7397 1.985:6721 3.858:5867 6.284:4969 | 4969 |
| far_0_-3_solid_e500 | 8097 | 80472 | 209860 | - | 80472 |
| far_0_-4_solid | 267 | 6755 | 12468 | 0.009:6403 0.059:6019 0.447:5665 1.934:5291 3.858:4527 6.284:3811 | 3811 |
| far_0_-4_solid_e500 | 5277 | 51768 | 133340 | - | 51768 |
| far_0_-5_solid | 129 | 2364 | 4966 | 0.055:1906 0.105:1366 0.184:1182 0.481:1088 1.912:906 | 906 |
| far_0_-5_solid_b | 1 | 96 | 166 | - | 96 |
| far_0_0_cut | 543 | 1086 | 2172 | - | 1086 |
| far_0_0_solid | 229 | 6582 | 12602 | 0.059:5780 0.184:5312 0.447:4816 1.985:4366 3.77:3854 7.011:3296 | 3296 |
| far_0_0_solid_e500 | 3723 | 46328 | 109880 | - | 46328 |
| far_0_0_solid_h | 1 | 292 | 444 | 5.071:132 | 132 |
| far_1_-1_cut | 44 | 88 | 176 | - | 88 |
| far_1_-1_solid | 133 | 3020 | 5881 | 0.059:2764 0.925:2584 1.9:2440 3.578:2060 6.013:1756 | 1756 |
| far_1_-1_solid_e500 | 2564 | 22410 | 60278 | - | 22410 |
| far_1_-2_cut | 3 | 6 | 12 | - | 6 |
| far_1_-2_solid | 92 | 2641 | 4959 | 0.005:2333 0.059:2117 0.447:1931 3.172:1737 | 1737 |
| far_1_-2_solid_e500 | 1332 | 9354 | 27838 | - | 9354 |
| far_1_-3_solid | 120 | 2925 | 5823 | 0.012:2619 0.059:2455 0.491:2261 1.781:1845 6.013:1633 | 1633 |
| far_1_-3_solid_e500 | 427 | 3774 | 9542 | - | 3774 |
| far_1_-4_solid | 155 | 4005 | 8876 | 0.055:3717 0.206:3393 0.925:2383 1.966:2031 7.13:1707 | 1707 |
| far_1_-4_solid_e500 | 533 | 5908 | 17320 | - | 5908 |
| far_1_-5_solid | 43 | 1006 | 2162 | 0.049:826 0.105:606 0.206:404 0.414:294 0.925:266 2.768:248 4.167:222 | 222 |
| far_1_0_solid | 316 | 8623 | 18742 | 0.059:8155 0.105:7163 0.206:6145 0.481:5473 0.962:4015 1.912:3623 3.578:3429 5.312:3135 | 3135 |
| far_1_0_solid_e500 | 1207 | 19232 | 44280 | - | 19232 |
| far_2_-1_solid | 19 | 576 | 1110 | 0.09:310 0.184:182 0.414:150 0.937:130 | 130 |
| far_2_-2_solid | 11 | 334 | 676 | 0.09:236 0.184:172 0.414:140 3.578:94 | 94 |
| far_2_-2_solid_e500 | 114 | 616 | 1848 | - | 616 |
| far_2_-3_solid | 9 | 168 | 382 | 0.049:148 0.105:108 0.206:88 0.309:76 | 76 |
| far_2_-3_solid_e500 | 239 | 2596 | 7564 | - | 2596 |
| far_2_-4_solid | 16 | 328 | 750 | 0.09:272 0.206:172 0.309:112 | 112 |
| far_3_-1_solid | 5 | 122 | 326 | 0.184:82 0.414:50 | 50 |
| far_3_-1_solid_e500 | 51 | 1428 | 4080 | - | 1428 |
| far_3_-2_solid | 9 | 262 | 606 | 0.09:122 0.184:102 0.414:86 | 86 |
| far_3_-2_solid_e500 | 68 | 408 | 1224 | - | 408 |
| far_3_-3_solid | 1 | 14 | 42 | - | 14 |
| far_3_-3_solid_e500 | 64 | 384 | 1152 | - | 384 |
| **all 82 tiles** | | **960493** | | | **893411** |
