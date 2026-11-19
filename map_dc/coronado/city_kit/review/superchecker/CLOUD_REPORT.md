# Superchecker over the city: the cloud session's report (from the bottom of ORDER.txt upward)

**Status: DONE.** The two sessions met at line 49 of ORDER.txt: `n_hs_b1_amber` is claimed by pc-session
(2026-11-19 18:45Z). This session did **lines 50-150, 101 pieces**, from `n_wf_b2e` (line 150) up to `n_hs_b1_tenth`
(line 50). Every one: PROOF RESULT PASS, lock test RESULT PASS, committed and pushed.

Totals over the 101 pieces (lines of their `<piece>.fixes.json`): 975 props erased (no plainly safe place, in an
opening, over an edge, bins in the open ...), 963 props set on the ground / lifted / slid along a wall, 9,441 wear marks
off their surface removed, 3,110 colliders added (of them 910 later resized to the prop's own size, see "Colliders"),
1,674 builder trees out, 50 duplicate fence posts erased, 1 tree well paved; the rooms of these pieces fixed with their
own proofs where they had faults. Trees back by hand: see the zone table.

Branch `claude/festive-faraday-20ltx2`. Every piece below was claimed with `claim.sh <piece> cloud-session`, checked,
decided (`sc_review.py decide`: erase when unsure, slide a wall item <= 1.2 m along its own wall, keep the known false
alarms), fixed on a copy with **PROOF RESULT PASS**, given a hand-written tree list (`zoning/trees/<area>.json`, every
line with its why, `sc.py trees` ok), installed with `--by=Yasin` under Yasin's word for this run, and committed and
pushed only after the lock test said **RESULT PASS**. Roads and ground surfaces were never touched.

## Pieces done (101, from the bottom of the list up)
| # | Piece | Zone | Props erased | Props moved | Wear marks out | Colliders added | Colliders resized later | Trees out | Trees back |
|---|---|---|---|---|---|---|---|---|---|
| 1 | n_wf_b2e | waterfront | 18 | 20 | 60 | 15 | 0 | 4 | 2 |
| 2 | n_wf_b2m | waterfront | 16 | 10 | 0 | 17 | 0 | 9 | 3 |
| 3 | n_wf_b2w | waterfront | 20 | 36 | 0 | 16 | 0 | 12 | 3 |
| 4 | n_wf_b1e | waterfront | 26 | 7 | 5 | 18 | 0 | 19 | 6 |
| 5 | n_wf_b1m | waterfront | 29 | 8 | 0 | 18 | 0 | 10 | 3 |
| 6 | n_wf_b1w | waterfront | 28 | 8 | 0 | 16 | 0 | 13 | 3 |
| 7 | m_gr_e4n | commercial strip | 0 | 0 | 37 | 0 | 0 | 8 | 0 |
| 8 | m_gr_ad3se | commercial strip | 14 | 18 | 41 | 10 | 0 | 21 | 6 |
| 9 | m_gr_ad3sw | commercial strip | 18 | 12 | 48 | 9 | 0 | 13 | 3 |
| 10 | m_gr_ad5nw | commercial strip | 24 | 17 | 88 | 11 | 0 | 10 | 2 |
| 11 | m_gr_e4s | commercial strip | 8 | 6 | 22 | 3 | 0 | 10 | 4 |
| 12 | m_gr_ad5ne | commercial strip | 29 | 26 | 82 | 13 | 0 | 21 | 7 |
| 13 | r_q_500_0_nw | residential yards | 12 | 7 | 133 | 43 | 26 | 18 | 7 |
| 14 | r_q_500_m200_sw | residential yards | 13 | 18 | 169 | 64 | 48 | 28 | 9 |
| 15 | r_q_500_m200_nw | residential yards | 7 | 18 | 153 | 39 | 33 | 20 | 6 |
| 16 | r_q_250_200_nw | residential yards | 9 | 17 | 143 | 43 | 36 | 18 | 6 |
| 17 | r_q_250_0_ne | residential yards | 9 | 20 | 160 | 42 | 34 | 20 | 6 |
| 18 | r_q_250_m200_se | residential yards | 9 | 13 | 127 | 42 | 27 | 18 | 5 |
| 19 | r_q_250_m200_ne | residential yards | 12 | 12 | 190 | 65 | 49 | 28 | 7 |
| 20 | r_q_250_m200_sw | residential yards | 6 | 16 | 151 | 41 | 34 | 20 | 6 |
| 21 | r_q_250_m200_nw | residential yards | 9 | 4 | 138 | 36 | 24 | 23 | 5 |
| 22 | r_q_250_m1000_se | residential yards | 6 | 0 | 144 | 37 | 26 | 21 | 5 |
| 23 | r_q_250_m1000_ne | residential yards | 14 | 1 | 161 | 65 | 49 | 26 | 6 |
| 24 | r_q_250_m1000_sw | residential yards | 13 | 10 | 170 | 42 | 32 | 22 | 5 |
| 25 | r_q_250_m1000_nw | residential yards | 12 | 7 | 119 | 43 | 26 | 19 | 5 |
| 26 | r_q_250_m1200_se | residential yards | 7 | 7 | 138 | 41 | 26 | 20 | 6 |
| 27 | r_q_250_m1200_ne | residential yards | 8 | 23 | 171 | 62 | 49 | 26 | 6 |
| 28 | r_q_250_m1200_sw | residential yards | 15 | 10 | 134 | 36 | 27 | 17 | 5 |
| 29 | r_q_250_m1200_nw | residential yards | 10 | 33 | 139 | 44 | 33 | 19 | 5 |
| 30 | r_q_250_m1400_se | residential yards | 7 | 0 | 135 | 44 | 27 | 20 | 6 |
| 31 | r_q_250_m1400_sw | residential yards | 15 | 48 | 182 | 58 | 48 | 29 | 7 |
| 32 | r_q_0_m1000_se | residential yards | 10 | 17 | 157 | 37 | 30 | 21 | 6 |
| 33 | r_q_0_m1000_ne | residential yards | 10 | 20 | 148 | 46 | 36 | 20 | 6 |
| 34 | r_q_0_m1000_sw | residential yards | 11 | 19 | 162 | 47 | 38 | 24 | 7 |
| 35 | r_q_0_m1000_nw | residential yards | 9 | 2 | 116 | 18 | 14 | 21 | 5 |
| 36 | r_q_0_m1200_se | residential yards | 8 | 14 | 174 | 62 | 48 | 30 | 7 |
| 37 | r_q_0_m1200_ne | residential yards | 13 | 18 | 141 | 42 | 32 | 19 | 6 |
| 38 | r_q_0_m1200_sw | residential yards | 4 | 9 | 119 | 31 | 23 | 13 | 5 |
| 39 | r_q_0_m1200_nw | residential yards | 8 | 0 | 101 | 23 | 12 | 15 | 5 |
| 40 | r_q_0_m1400_se | residential yards | 12 | 5 | 121 | 33 | 23 | 20 | 5 |
| 41 | r_q_0_m1400_sw | residential yards | 12 | 25 | 132 | 31 | 0 | 18 | 5 |
| 42 | r_q_m200_200_ne | residential yards | 9 | 4 | 125 | 32 | 0 | 14 | 5 |
| 43 | r_q_m200_200_nw | residential yards | 7 | 1 | 112 | 30 | 0 | 17 | 5 |
| 44 | r_q_m200_0_se | residential yards | 9 | 0 | 150 | 47 | 0 | 28 | 7 |
| 45 | r_q_m200_0_ne | residential yards | 5 | 1 | 107 | 31 | 0 | 17 | 5 |
| 46 | r_q_m200_0_sw | residential yards | 9 | 10 | 138 | 28 | 0 | 14 | 5 |
| 47 | r_q_m200_0_nw | residential yards | 9 | 0 | 124 | 31 | 0 | 15 | 5 |
| 48 | r_q_m200_m200_se | residential yards | 7 | 4 | 148 | 48 | 0 | 24 | 7 |
| 49 | r_q_m200_m200_sw | residential yards | 8 | 5 | 143 | 31 | 0 | 14 | 5 |
| 50 | r_q_m200_m1000_se | residential yards | 4 | 4 | 100 | 24 | 0 | 14 | 4 |
| 51 | r_q_m200_m1000_ne | residential yards | 8 | 12 | 130 | 34 | 0 | 16 | 5 |
| 52 | r_q_m200_m1200_se | residential yards | 12 | 0 | 166 | 48 | 0 | 26 | 6 |
| 53 | r_q_m200_m1200_ne | residential yards | 6 | 22 | 135 | 34 | 0 | 15 | 5 |
| 54 | r_q_m200_m1400_se | residential yards | 12 | 37 | 159 | 52 | 0 | 22 | 7 |
| 55 | r_q_m400_200_ne | residential yards | 15 | 4 | 162 | 51 | 0 | 28 | 7 |
| 56 | r_q_m400_200_nw | residential yards | 8 | 16 | 121 | 29 | 0 | 17 | 5 |
| 57 | r_q_m400_0_se | residential yards | 6 | 11 | 123 | 30 | 0 | 17 | 5 |
| 58 | r_q_m400_0_ne | residential yards | 12 | 0 | 163 | 52 | 0 | 26 | 7 |
| 59 | r_q_m400_0_sw | residential yards | 7 | 29 | 121 | 31 | 0 | 14 | 5 |
| 60 | r_q_m400_0_nw | residential yards | 4 | 4 | 126 | 31 | 0 | 16 | 4 |
| 61 | r_q_m400_m200_se | residential yards | 6 | 0 | 129 | 30 | 0 | 14 | 4 |
| 62 | r_q_m400_m200_sw | residential yards | 6 | 0 | 128 | 30 | 0 | 18 | 5 |
| 63 | r_q_m600_200_ne | residential yards | 14 | 35 | 146 | 54 | 0 | 27 | 7 |
| 64 | r_q_m600_200_nw | residential yards | 11 | 25 | 130 | 33 | 0 | 17 | 5 |
| 65 | r_q_m600_0_se | residential yards | 6 | 8 | 105 | 27 | 0 | 17 | 5 |
| 66 | r_q_m600_0_ne | residential yards | 8 | 24 | 157 | 54 | 0 | 23 | 6 |
| 67 | r_q_m600_0_sw | residential yards | 7 | 17 | 138 | 31 | 0 | 17 | 5 |
| 68 | r_q_m600_0_nw | residential yards | 8 | 17 | 118 | 30 | 0 | 15 | 5 |
| 69 | r_q_m600_m200_se | residential yards | 5 | 18 | 106 | 30 | 0 | 12 | 5 |
| 70 | r_q_m600_m200_ne | residential yards | 7 | 0 | 150 | 50 | 0 | 24 | 7 |
| 71 | r_q_m600_m200_sw | residential yards | 0 | 1 | 109 | 27 | 0 | 16 | 5 |
| 72 | r_q_m600_m200_nw | residential yards | 7 | 2 | 142 | 29 | 0 | 15 | 5 |
| 73 | r_q_m800_200_ne | residential yards | 11 | 35 | 165 | 50 | 0 | 23 | 6 |
| 74 | r_q_m800_0_se | residential yards | 3 | 2 | 105 | 39 | 0 | 13 | 5 |
| 75 | r_q_m800_0_ne | residential yards | 7 | 13 | 160 | 51 | 0 | 21 | 6 |
| 76 | r_q_m800_m200_se | residential yards | 6 | 12 | 127 | 32 | 0 | 18 | 5 |
| 77 | r_q_m800_m200_ne | residential yards | 4 | 0 | 113 | 26 | 0 | 14 | 4 |
| 78 | n_hs_b6_garden | high street | 2 | 0 | 6 | 25 | 0 | 11 | 4 |
| 79 | n_hs_b6_tenth | high street | 1 | 1 | 0 | 25 | 0 | 18 | 5 |
| 80 | n_hs_b6_hill | high street | 13 | 1 | 0 | 17 | 0 | 16 | 4 |
| 81 | n_hs_b6_ninth | high street | 12 | 1 | 0 | 9 | 0 | 8 | 3 |
| 82 | n_hs_b6_amber | high street | 12 | 0 | 0 | 8 | 0 | 2 | 2 |
| 83 | n_hs_b5_school | high street (school grounds) | 4 | 0 | 1 | 10 | 0 | 14 | 4 |
| 84 | n_hs_b5_tenth | high street | 0 | 1 | 1 | 24 | 0 | 17 | 3 |
| 85 | n_hs_b5_hill | park (hill park in the high-street band) | 3 | 1 | 0 | 8 | 0 | 17 | 8 |
| 86 | n_hs_b5_eleventh | high street | 9 | 0 | 0 | 10 | 0 | 4 | 2 |
| 87 | n_hs_b5_amber | high street | 10 | 0 | 1 | 14 | 0 | 5 | 3 |
| 88 | n_hs_b4_ocean | ring boulevard (Ocean) and park lawn | 4 | 0 | 0 | 5 | 0 | 19 | 13 |
| 89 | n_hs_b4_cottages | high street band, cottage row (residential yards) | 29 | 1 | 7 | 28 | 0 | 17 | 5 |
| 90 | n_hs_b4_eleventh | high street | 18 | 0 | 0 | 22 | 0 | 15 | 6 |
| 91 | n_hs_b4_amber | high street | 14 | 0 | 0 | 17 | 0 | 4 | 4 |
| 92 | n_hs_b3_motel | high street band, motel by Ocean | 7 | 0 | 0 | 17 | 0 | 10 | 6 |
| 93 | n_hs_b3_cottages | high street band, cottage row (residential yards) | 7 | 1 | 6 | 20 | 0 | 10 | 4 |
| 94 | n_hs_b3_dingbats | high street | 19 | 1 | 0 | 25 | 0 | 14 | 5 |
| 95 | n_hs_b3_amber | high street | 15 | 0 | 1 | 9 | 0 | 4 | 3 |
| 96 | n_hs_b2_ninth | high street | 3 | 0 | 2 | 5 | 0 | 9 | 3 |
| 97 | n_hs_b2_mews | high street band, mews (residential yards) | 13 | 18 | 7 | 29 | 0 | 9 | 3 |
| 98 | n_hs_b2_park | park (in the high-street band) | 5 | 1 | 3 | 18 | 0 | 8 | 4 |
| 99 | n_hs_b2_amber | ? | 16 | 0 | 0 | 15 | 0 | 0 | 0 |
| 100 | n_hs_b1_eleventh | high street band (yards and lawn) | 3 | 1 | 7 | 15 | 0 | 12 | 4 |
| 101 | n_hs_b1_tenth | high street | 13 | 1 | 7 | 15 | 0 | 10 | 2 |

| Zone | Builder trees out | Trees back by hand |
|---|---|---|
| waterfront | 67 | 20 |
| commercial strip | 83 | 22 |
| residential yards | 1271 | 364 |
| high street | 137 | 49 |
| high street (school grounds) | 14 | 4 |
| park (hill park in the high-street band) | 17 | 8 |
| ring boulevard (Ocean) and park lawn | 19 | 13 |
| high street band, cottage row (residential yards) | 27 | 9 |
| high street band, motel by Ocean | 10 | 6 |
| high street band, mews (residential yards) | 9 | 3 |
| park (in the high-street band) | 8 | 4 |
| high street, no trees (n_hs_b2_amber) | 0 | 0 |
| high street band (yards and lawn) | 12 | 4 |

(Colliders resized later: see "Colliders" below. Props moved = set back on the ground / lifted out of it where the check had one right answer, plus short slides along
their own wall. Colliders = boxes added to columns and props that had none. The numbers are lines of each piece's
`<piece>.fixes.json`, each with its reason; its `.proof.txt` beside it.)

## Where I changed what the tools would have done, and why
- **Poles that carry a wire are kept.** The decide step erased `prop_utility_pole(_transformer)` items standing in front
  of a garage or overlapping a prop. A wire point was 0.2-0.7 m from each of them: erasing the pole leaves the power line
  hanging in the air. I turned those lines into `keep` in every residential quadrant where it happened (about 30 poles; each such
  commit says "the wired pole kept", the decision line says why). The checked waterfront and strip pieces erased no
  wired pole (the only pole erased, in m_gr_e4s, was a car-park light).
- **Doubled fence posts.** In the first ~43 pieces the fixer refused a "lift the sunk post" line because two
  identical posts stand on the same spot. For each, one post is lifted (`nth 0`) and its duplicate erased (`nth 1`,
  kind `double_post`), so the joint keeps one post. The proof covers both lines. From r_q_m200_200_nw on I follow the PC
  session's newer rule in `block.sh` (a doubled post is left as it stands).
- **Wells:** every builder tree's well line ran; on the waterfront, strip and residential yards the trees stood in grass
  or plain mulch, the fixer found no cut well and paved nothing (0 wells). Two coral trees stood on mulch patches
  (n_wf_b1e, n_wf_b1m): the patches stay, with no tree (ground surfaces are not touched).
- **Line endings:** my Linux install rewrote `city_grid_layout.json` with LF (the file is CRLF, no final newline); fixed
  in the next commit and in every later one, so the file's diff is only the added tree rows.


## Colliders: what I found, fixed and redid (Yasin: "Fix and redo")
- **Oversized colliders.** `sc_fix.gd`'s add_collider put the kit's collision shape at full kit size (its basis
  orthonormalized), ignoring the prop's scale; `kit_lib.gd`, which made every collider the builders placed, scales it.
  Most yard fence panels are shortened (scale 0.45-0.9), so each added collider stuck out past its panel, up to about
  1 m, into gates and gaps. 910 of the 946 add_collider lines in my pieces were on such panels.
  Fixed in `sc_fix.gd`: the prop's scale is baked into the convex shape's points (no scaled shape for physics), and a new
  op `resize_collider` swaps one oversized collider for a right-sized one at the same spot (the proof checks one collider
  gone and one come there, nothing else). Every installed piece was redone, one commit each, PROOF PASS and lock PASS;
  its record is `<piece>.colfix.fixes.json` / `.colfix.proof.txt` beside the first one.
  Measured afterwards (`OUT/super/tmp/colsize.gd`: every fence collider's box against its visible panel's box, real
  renderer): 0 colliders sticking out more than 0.15 m in all my pieces; largest overhang 0.04 m. **The PC session's
  pieces with add_collider lines on scaled panels will have the same fault: not checked, not mine to change.**
- **Lost colliders.** The fixer added new colliders with a fast auto name that can repeat a saved sibling's name; the
  save then dropped the old one. The proof caught it twice (two hedge colliders gone). Fixed: `add_child(c, true)`.
  Before the fix, in r_q_250_m1000_nw I left two fence panels' add_collider lines out to get a clean proof: those two
  panels (local (-122.25|-124.47, 2.76, -25.85)) were left without a collider. FIXED afterwards: the two lines carried out
  alone (`r_q_250_m1000_nw.fence2.fixes.json`), PROOF RESULT PASS (all 935 old colliders identical, the hedges' included),
  both new colliders within 0.04 m of their panels (colsize: 815 -> 817 fence colliders, 0 bigger), lock test RESULT PASS.
- **Boxes for building columns/posts** (add_box) are sized from the measured column and were not affected.

## Other fixes to the shared run tools
- `run/block.sh`: the doubled-post line (the PC session's, keeps a doubled post as it stands) had a raw control byte
  where `\1` was meant, so the loop spun five rounds without fixing; fixed. From r_q_m200_200_nw on I follow that rule
  (doubled posts left as they stand). In my earlier pieces each doubled sunk post was lifted (`nth 0`) and its twin
  erased (`nth 1`), both proven.
- I could not tell the PC session directly (a cloud session may not message a session on Yasin's computer).

## Trees: what the plan says and what I did
New trees stand only on old builder spots that the tree check passes (HOWTO step 3; Yasin: "if the plan puts new trees
in old spots it is fine, stick to the plan").
- **Waterfront (palms only):** every broadleaf out; palms kept on the promenade-side grass and along the beach road.
  The promenade row of n_wf_b1e stood on the plaza with no well (the check refuses it) and stays out. In the b2 blocks
  I kept about half the palms (spots among flats and cottages, not on the promenade): below the plan's target of ~95
  of 105 for the zone; Yasin can ask for more of the old palm spots back.
- **Commercial strip (few: the palm parkway, one tree per car-park island end):** parkway palms about every other old
  one, kept clear of the pylon signs; one tree at each island end; none in the fenced boat / RV storage yard (m_gr_e4n).
- **Residential yards (one tree for every two or three houses, never against a fence or a wall):** 5-9 per quadrant,
  where people sit (grills, chairs, swings, picnic tables) and on open lot corners; the tight back-fence rows (one every
  6 m) and the trees 3 m from the house fronts went. This is about 29 % of the old trees (364 of 1,271): the plan's zone total is ~half (813 -> 400), its rule per
  house is what I followed; Yasin can ask for more of the old spots back.


## The high-street band, parks and Ocean (lines 50-73)
- **Wells.** Only `n_hs_b3_amber` had trees in paved wells (four Amber palms). Its tree list was written before
  `block.sh` (another session's tip: the check leaves listed trees' wells open), so the kept palms stand in their wells.
  One palm was then dropped for the in-view limit and its well paved; the finder had given that well line the palm
  model's height (-1.48 m local, the ground is +0.09), so the proof (which looks for ground triangles within 0.4 m of that
  height) said "no well was paved". I set that one line's height to the measured ground; proof PASS, the well check 1 -> 0.
  **For whoever keeps sc_find.py: a well line should take the ground's height, not the tree's.**
- **Parks and the school grounds** (`n_hs_b5_hill`, `n_hs_b2_park`, `n_hs_b5_school`, the lawn of `n_hs_b4_ocean`) follow
  the plan's park rule: clumps at the edges round the seating (picnic tables, benches), open lawn in the middle.
- **Ocean Boulevard** (`n_hs_b4_ocean`): all seven boulevard palms kept on their spots (ring boulevard = palms).
- **Amber**: every palm on Amber kept (the avenue's signature), except one in `n_hs_b3_amber` for the in-view limit.
- **In-view limit.** `sc.py trees` counts every hand-placed tree seen from the streets round a block, the neighbours'
  too (8 broadleaf, 12 of any kind). In `n_hs_b5_tenth`, `n_hs_b2_park`, `n_hs_b1_tenth`, `n_hs_b3_amber` I dropped trees
  until it said ok.
- **A slip of mine, put right:** `n_hs_b2_park` was installed while its tree list was still over the limit (my command
  checked that the list line printed, not that it said ok). The piece itself was proven and fine, but no tree piece went
  in with it and the committed list did not pass. The next commit makes the list pass and puts `t_hs_b2_park` in place
  with its layout row (the same two steps `install` does). From then on the install ran only after an exact "ok".

## Reported only (left as they are: not props or road wear, or not mine to decide)
Per piece the checker also lists items it does not fix: `building_sunk`, `edge_step`, `ground_step`, `garage_step`
(ground), `double_fence` (a stucco wall 0.9 m behind an iron fence, by design of the yards), `chainlink_street`,
`yard_open`, `park_empty`, `wire_in_building` (the wire pieces), `pole_no_wire` (m_gr_ad3sw, m_gr_e4s: poles with no wire
piece near), `sail_over_nothing`, `no_reason`, `empty_batch`. They are in each piece's `OUT/super/find/<piece>.faults.json`
when the check is run again.

## Not checked
The PC session's pieces (lines 1-49) are not mine: not checked here, including for the oversized colliders.
No pictures were taken of the fixed pieces (the proof says what changed, not how it looks). The phone run is not part
of this job.
