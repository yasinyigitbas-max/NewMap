# Superchecker over the streets: the cloud-top session's report (from line 24 of ORDER_STREETS.txt down)

**Status: DONE, met in the middle.** This session took over the PC session's half (its Windows Godot runs were too
slow) and worked `review/superchecker/ORDER_STREETS.txt` from line 24 (`j_amber_10th`) down. It stopped at line 108:
`j_rg_nw_w1000_n600` is claimed by the bottom-up cloud session (2026-11-19 22:24Z). Lines 24-107 are all claimed. The
PC session left these unfinished: `s_am_b042_b`, `s_am_b043_a`, `s_am_b044_b`. They were released (`db77ea6b`) and
done here.

**Not done by anyone yet:** `s_am_b041_b`, `s_am_b042_a`, `s_am_fill_cc`, `s_am_fill_hs`. They are still claimed by
pc-session and have no `<piece>.fixes.json` on the branch. I was told 042_a and the two fills were done, but their
records never reached the branch. I did not touch them because they are the PC session's claims.

Branch `claude/festive-faraday-20ltx2`. For each piece: `claim.sh <piece> cloud-top`, then `block.sh` (check, decide
with "erase when unsure", fix on a copy, **PROOF RESULT PASS**). Then trees picked by hand with `street_trees.py write`
(every line with its why), `sc.py trees <area>` ending "built", and `phase_b.sh` (install under Yasin's word for this
run, relock, lock test **RESULT PASS**, commit, pull, push). No road, kerb, sidewalk or ground surface was deleted. No
piece script was run. The final lock test on the branch after the last install says RESULT PASS.

## Totals (87 pieces, from their `<piece>.fixes.json`)
| op | count |
|---|---|
| builder trees out | 482 |
| tree wells filled with their rim's material | 90 |
| wear marks removed (off their surface, over an edge, on grass / gravel / sidewalk) | 502 |
| props erased (in doubt, no plainly safe place) | 20 (6 park benches, 5 shopping carts, 3 trash cans, 2 no-parking signs, 2 signal posts and 2 street-name signs at `j_cc`, see below) |
| props moved | 5 (2 of them are `j_cc`'s signal mast arms, 0.15 m down, see below) |
| trees placed by hand | 274 in the city (one list line per place: a piece standing 2, 5 or 6 times gets its picks at each place) |

Trees by family, as picked:
- Amber (`s_am_*`, `s_amber_*`, `s_cc_amber_*`): 2 median queen palms a piece, about 36 m apart, in step with the
  pieces next to them. One parkway palm on `s_am_b042_b`. Every side spot on Amber was a well, so no side trees.
- Arterials (`s_ar_*`): only where a grass strip is. Mostly 4 a piece, one species a face. Palms or Torrey pines where
  the broadleaf in view reached 8. `s_ar_b057_a` and `s_ar_b058_b` had wells only, so they got none.
- Bridge approaches (`s_br_appr_*`): queen palms only, about 30-32 m apart along the curve. The ramps had no trees.
- Residential (`s_res_*`), apartments (`s_apt`) and civic (`s_civ`): parkway grass, one species a face. The in-view
  limit (12 trees, 8 broadleaf within 60 m) cut most of them to 2-4 a place. `s_res_up2_b` got only 1 palm a place,
  because its neighbours' trees already fill the limit. Pines and palms on the hill streets (`dn4`, `dn6`, `dn8`, `up4_b`).
- Gritty (`s_grt`), industrial (`s_ind`), city-centre side streets with wells only (`s_cc_10th`), and every junction:
  no trees.

## Checks changed, and why
1. **`walk_narrow` (sc_more.py): a signal post is reported, not moved or erased.** The decide step erased the traffic
   signal post at `j_ar_ad3`, `j_ar_ad5` and `j_ar_g3` because it "left 0.8 m of a 2.0 m walk". A signal post has one
   right place, its corner, and erasing it leaves an approach with no signal. All three pieces were redone from their
   files as they stood before the install, so the posts are back. The proofs PASS and the records are replaced.
2. **`lane_mouth` (sc_more.py): signal props are not lane-mouth faults.** The same thing happened to the signal mast
   arms at `j_rg_e660_n1000` and `j_rg_nw_e0_n1600`. Both pieces were redone the same way and the masts are back. The
   bottom-up session lost two mast arms the same way, at `j_rg_nw_w952_n1200` and `j_rg_se_e0_s340`. Those are its
   pieces and I did not touch them. They need the same redo.
3. **Tree read-back (sc.py `trees`): compares within 2 cm.** The file keeps float32, so the exact compare of 2-decimal
   roundings called `ar_b066_b`'s right build "WRONG". The palms and places were the same.
   `t_ar_b066_b` was re-put from the build that reads back OK.
4. **`street_trees.py write`: reads each place's own ground.** For a piece standing twice on a slope (`s_res_dn2_a`),
   the second place's heights came out 6 cm off, because the ground was read only in the first place's context.
   `sc.py trees` refused the list, so nothing wrong was built.

## One piece to look at: `j_cc`
At two corners of the city-centre junction the checker found a signal post, a street-name sign and a signal mast arm
standing "over no ground of any piece". It looks like a gap in the ground at the corner: the before pictures are in
`review/superchecker/cloud_top_looks/j_cc_corner_*_before.png`, and the ne view shows the mast over a black patch. Per
"delete when unsure", the 2 posts and 2 signs were erased and the 2 mast arms set 0.15 m down. The ground gap itself is
NOT fixed, because surfaces are not deleted or changed in this job. If the gap is a dump fault and the corner really
has ground, those 4 props should come back. That needs a look and Yasin's word.

## What was NOT checked
- Nobody looked at every picture. Only `j_cc`'s corner was rendered (`sc.py look`). The other 86 pieces were judged
  by the checker's numbers, the decide step and the tree tool's list.
- The checks see props against their own piece's ground and the neighbours loaded within reach. They do not see
  whether a prop makes sense, or faults of the "reported only" kinds (edge steps, ground steps, drives with no apron,
  lone patches): those are surfaces and were left alone.
- The in-view tree limit counts the hand-placed lists only. It does not count builder trees still standing in pieces
  nobody has done yet.
- The runtime bake was not run, and nothing was run on the phone (Redmi).

## Pieces (line in ORDER_STREETS.txt)
| line | piece | props erased | props moved | wear marks out | wells filled | builder trees out | trees placed (all places) |
|---|---|---|---|---|---|---|---|
| 19 | s_am_b042_b | 0 | 0 | 6 | 0 | 15 | 3 |
| 20 | s_am_b043_a | 2 | 0 | 3 | 11 | 17 | 2 |
| 21 | s_am_b044_b | 1 | 0 | 10 | 11 | 17 | 2 |
| 24 | j_amber_10th | 0 | 0 | 0 | 0 | 0 | 0 |
| 25 | s_amber_n | 1 | 0 | 10 | 12 | 18 | 2 |
| 26 | s_amber_s | 2 | 0 | 4 | 12 | 18 | 2 |
| 27 | j_apt | 0 | 0 | 0 | 0 | 0 | 24 |
| 28 | s_apt | 0 | 0 | 17 | 0 | 13 | 24 |
| 29 | j_ar_ad3 | 0 | 0 | 0 | 0 | 0 | 0 |
| 30 | j_ar_ad5 | 0 | 0 | 2 | 0 | 0 | 0 |
| 31 | j_ar_b3 | 0 | 0 | 4 | 0 | 0 | 0 |
| 32 | j_ar_b4 | 0 | 0 | 4 | 0 | 0 | 0 |
| 33 | j_ar_c3 | 0 | 0 | 4 | 0 | 0 | 0 |
| 34 | j_ar_c4 | 0 | 0 | 4 | 0 | 0 | 0 |
| 35 | j_ar_e3 | 1 | 0 | 4 | 0 | 0 | 0 |
| 36 | j_ar_e4 | 1 | 0 | 4 | 0 | 0 | 0 |
| 37 | j_ar_g3 | 1 | 0 | 4 | 0 | 0 | 0 |
| 38 | j_ar_g4 | 1 | 0 | 1 | 0 | 0 | 0 |
| 39 | j_ar_j4 | 1 | 0 | 1 | 0 | 0 | 0 |
| 40 | s_ar_b057_a | 0 | 0 | 4 | 8 | 8 | 0 |
| 41 | s_ar_b058_b | 0 | 0 | 5 | 8 | 8 | 0 |
| 42 | s_ar_b065_b | 0 | 0 | 18 | 0 | 1 | 1 |
| 43 | s_ar_b066_a | 0 | 0 | 10 | 0 | 7 | 4 |
| 44 | s_ar_b066_b | 0 | 0 | 15 | 0 | 6 | 4 |
| 45 | s_ar_b067_a | 0 | 1 | 7 | 0 | 6 | 4 |
| 46 | s_ar_b067_b | 0 | 0 | 8 | 0 | 7 | 4 |
| 47 | s_ar_b068_a | 0 | 0 | 8 | 0 | 7 | 4 |
| 48 | s_ar_b068_b | 0 | 0 | 6 | 0 | 7 | 4 |
| 49 | s_ar_b069_a | 0 | 0 | 11 | 0 | 6 | 4 |
| 50 | s_ar_b069_b | 0 | 0 | 8 | 0 | 7 | 4 |
| 51 | s_ar_b070_a | 0 | 0 | 10 | 0 | 6 | 4 |
| 52 | s_ar_b070_b | 0 | 0 | 16 | 0 | 6 | 4 |
| 53 | s_ar_b073_a | 0 | 0 | 10 | 0 | 8 | 4 |
| 54 | s_ar_b073_b | 0 | 0 | 13 | 0 | 3 | 2 |
| 55 | s_ar_b074_a | 0 | 1 | 12 | 0 | 3 | 2 |
| 56 | s_ar_b074_b | 0 | 0 | 16 | 0 | 8 | 4 |
| 57 | s_ar_b075_a | 0 | 0 | 5 | 0 | 6 | 4 |
| 58 | s_ar_b075_b | 0 | 0 | 8 | 0 | 7 | 4 |
| 59 | s_ar_b076_a | 0 | 1 | 7 | 0 | 5 | 3 |
| 60 | s_ar_b076_b | 0 | 0 | 9 | 0 | 7 | 4 |
| 61 | s_ar_b077_a | 0 | 0 | 8 | 0 | 10 | 5 |
| 62 | s_ar_b077_b | 0 | 0 | 10 | 0 | 7 | 4 |
| 63 | s_ar_b078_a | 0 | 0 | 16 | 0 | 8 | 4 |
| 64 | s_br_appr_1 | 2 | 0 | 3 | 0 | 5 | 3 |
| 65 | s_br_appr_2 | 0 | 0 | 2 | 0 | 5 | 2 |
| 66 | s_br_appr_3 | 0 | 0 | 2 | 0 | 6 | 3 |
| 67 | s_br_appr_4 | 0 | 0 | 2 | 0 | 11 | 6 |
| 68 | s_br_appr_5 | 0 | 0 | 1 | 0 | 6 | 3 |
| 69 | s_br_appr_6 | 0 | 0 | 4 | 0 | 4 | 2 |
| 70 | s_br_ramp_1 | 0 | 0 | 2 | 0 | 0 | 0 |
| 71 | s_br_ramp_2 | 0 | 0 | 2 | 0 | 0 | 0 |
| 72 | s_br_ramp_3 | 0 | 0 | 2 | 0 | 0 | 0 |
| 73 | s_br_ramp_4 | 0 | 0 | 1 | 0 | 0 | 0 |
| 74 | s_br_ramp_5 | 0 | 0 | 0 | 0 | 0 | 0 |
| 75 | j_cc | 4 | 2 | 1 | 0 | 0 | 0 |
| 76 | s_cc_10th | 0 | 0 | 3 | 4 | 4 | 0 |
| 77 | s_cc_amber_n | 1 | 0 | 7 | 12 | 18 | 2 |
| 78 | s_cc_amber_s | 1 | 0 | 8 | 12 | 18 | 2 |
| 79 | s_civ | 0 | 0 | 11 | 0 | 13 | 20 |
| 80 | s_grt | 0 | 0 | 20 | 0 | 7 | 0 |
| 81 | j_ind | 0 | 0 | 0 | 0 | 0 | 0 |
| 82 | s_ind | 1 | 0 | 0 | 0 | 0 | 0 |
| 83 | j_res | 0 | 0 | 0 | 0 | 0 | 0 |
| 84 | s_res_a | 0 | 0 | 8 | 0 | 9 | 12 |
| 85 | s_res_b | 0 | 0 | 4 | 0 | 8 | 8 |
| 86 | s_res_c | 0 | 0 | 8 | 0 | 9 | 8 |
| 87 | s_res_dn2_a | 0 | 0 | 7 | 0 | 10 | 8 |
| 88 | s_res_dn2_b | 0 | 0 | 7 | 0 | 9 | 8 |
| 89 | s_res_dn4_a | 0 | 0 | 10 | 0 | 9 | 6 |
| 90 | s_res_dn4_b | 0 | 0 | 6 | 0 | 8 | 4 |
| 91 | s_res_dn6 | 0 | 0 | 2 | 0 | 10 | 6 |
| 92 | s_res_dn8 | 0 | 0 | 4 | 0 | 7 | 3 |
| 93 | s_res_up2_a | 0 | 0 | 5 | 0 | 8 | 6 |
| 94 | s_res_up2_b | 0 | 0 | 2 | 0 | 10 | 2 |
| 95 | s_res_up4_a | 0 | 0 | 6 | 0 | 9 | 6 |
| 96 | s_res_up4_b | 0 | 0 | 5 | 0 | 9 | 4 |
| 97 | s_res_up6 | 0 | 0 | 6 | 0 | 9 | 6 |
| 98 | s_res_up8 | 0 | 0 | 7 | 0 | 9 | 4 |
| 99 | j_rg_e660_n1000 | 0 | 0 | 2 | 0 | 0 | 0 |
| 100 | j_rg_nw_e0_n1600 | 0 | 0 | 2 | 0 | 0 | 0 |
| 101 | j_rg_nw_e250_n1600 | 0 | 0 | 2 | 0 | 0 | 0 |
| 102 | j_rg_nw_e500_n1600 | 0 | 0 | 1 | 0 | 0 | 0 |
| 103 | j_rg_nw_e657_n800 | 0 | 0 | 2 | 0 | 0 | 0 |
| 104 | j_rg_nw_e660_n1200 | 0 | 0 | 3 | 0 | 0 | 0 |
| 105 | j_rg_nw_e660_n1400 | 0 | 0 | 6 | 0 | 0 | 0 |
| 106 | j_rg_nw_w1000_n200 | 0 | 0 | 2 | 0 | 0 | 0 |
| 107 | j_rg_nw_w1000_n400 | 0 | 0 | 2 | 0 | 0 | 0 |
