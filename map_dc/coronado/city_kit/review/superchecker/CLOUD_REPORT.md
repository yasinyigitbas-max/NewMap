# Superchecker over the city: the cloud session's report (from the bottom of ORDER.txt upward)

**Status: IN PROGRESS** (this file is rewritten as pieces are done; the final version says DONE and where the two
sessions met).

Branch `claude/festive-faraday-20ltx2`. Every piece below was claimed with `claim.sh <piece> cloud-session`, checked,
decided (`sc_review.py decide`: erase when unsure, slide a wall item <= 1.2 m along its own wall, keep the known false
alarms), fixed on a copy with **PROOF RESULT PASS**, given a hand-written tree list (`zoning/trees/<area>.json`, every
line with its why, `sc.py trees` ok), installed with `--by=Yasin` under Yasin's word for this run, and committed and
pushed only after the lock test said **RESULT PASS**. Roads and ground surfaces were never touched.

## Pieces done
| # | Piece | Zone | Props erased | Props moved | Wear marks out | Colliders | Trees out | Trees back |
|---|---|---|---|---|---|---|---|---|
| 1 | n_wf_b2e | waterfront | 18 | 20 | 60 | 15 | 4 | 2 |
| 2 | n_wf_b2m | waterfront | 16 | 10 | 0 | 17 | 9 | 3 |
| 3 | n_wf_b2w | waterfront | 20 | 36 | 0 | 16 | 12 | 3 |
| 4 | n_wf_b1e | waterfront | 26 | 7 | 5 | 18 | 19 | 6 |
| 5 | n_wf_b1m | waterfront | 29 | 8 | 0 | 18 | 10 | 3 |
| 6 | n_wf_b1w | waterfront | 28 | 8 | 0 | 16 | 13 | 3 |
| 7 | m_gr_e4n | commercial strip | 0 | 0 | 37 | 0 | 8 | 0 |
| 8 | m_gr_ad3se | commercial strip | 14 | 18 | 41 | 10 | 21 | 6 |
| 9 | m_gr_ad3sw | commercial strip | 18 | 12 | 48 | 9 | 13 | 3 |
| 10 | m_gr_ad5nw | commercial strip | 24 | 17 | 88 | 11 | 10 | 2 |
| 11 | m_gr_e4s | commercial strip | 8 | 6 | 22 | 3 | 10 | 4 |
| 12 | m_gr_ad5ne | commercial strip | 29 | 26 | 82 | 13 | 21 | 7 |
| 13 | r_q_500_0_nw | residential yards | 12 | 7 | 133 | 43 | 18 | 7 |
| 14 | r_q_500_m200_sw | residential yards | 13 | 18 | 169 | 64 | 28 | 9 |
| 15 | r_q_500_m200_nw | residential yards | 7 | 18 | 153 | 39 | 20 | 6 |
| 16 | r_q_250_200_nw | residential yards | 9 | 17 | 143 | 43 | 18 | 6 |
| 17 | r_q_250_0_ne | residential yards | 9 | 20 | 160 | 42 | 20 | 6 |
| 18 | r_q_250_m200_se | residential yards | 9 | 13 | 127 | 42 | 18 | 5 |
| 19 | r_q_250_m200_ne | residential yards | 12 | 12 | 190 | 65 | 28 | 7 |
| 20 | r_q_250_m200_sw | residential yards | 6 | 16 | 151 | 41 | 20 | 6 |
| 21 | r_q_250_m200_nw | residential yards | 9 | 4 | 138 | 36 | 23 | 5 |
| 22 | r_q_250_m1000_se | residential yards | 6 | 0 | 144 | 37 | 21 | 5 |
| 23 | r_q_250_m1000_ne | residential yards | 14 | 1 | 161 | 65 | 26 | 6 |
| 24 | r_q_250_m1000_sw | residential yards | 13 | 10 | 170 | 42 | 22 | 5 |

| Zone | Builder trees out | Trees back by hand |
|---|---|---|
| waterfront | 67 | 20 |
| commercial strip | 83 | 22 |
| residential yards | 262 | 73 |

(Props moved = set back on the ground / lifted out of it where the check had one right answer, plus short slides along
their own wall. Colliders = boxes added to columns and props that had none. The numbers are lines of each piece's
`<piece>.fixes.json`, each with its reason; its `.proof.txt` beside it.)

## Where I changed what the tools would have done, and why
- **Poles that carry a wire are kept.** The decide step erased `prop_utility_pole(_transformer)` items standing in front
  of a garage or overlapping a prop. A wire point was 0.2-0.7 m from each of them: erasing the pole leaves the power line
  hanging in the air. I turned those lines into `keep` (in r_q_500_m200_sw, r_q_500_m200_nw, r_q_250_m200_ne,
  r_q_250_m200_nw x2, r_q_250_m1000_se, r_q_250_m1000_ne, r_q_250_m1000_sw). I checked the earlier pieces: no wired pole
  was erased there (the only pole erased, in m_gr_e4s, was a car-park light).
- **Doubled fence posts.** In most residential quadrants the fixer refused a "lift the sunk post" line because two
  identical posts stand on the same spot. For each, one post is lifted (`nth 0`) and its duplicate erased (`nth 1`,
  kind `double_post`), so the joint keeps one post. The proof covers both lines.
- **Wells:** every builder tree's well line ran; on the waterfront, strip and residential yards the trees stood in grass
  or plain mulch, the fixer found no cut well and paved nothing (0 wells). Two coral trees stood on mulch patches
  (n_wf_b1e, n_wf_b1m): the patches stay, with no tree (ground surfaces are not touched).
- **Line endings:** my Linux install rewrote `city_grid_layout.json` with LF (the file is CRLF, no final newline); fixed
  in the next commit and in every later one, so the file's diff is only the added tree rows.

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
  6 m) and the trees 3 m from the house fronts went. This is about 28 % of the old trees: the plan's zone total is ~half
  (813 -> 400), its rule per house is what I followed.

## Reported only (left as they are: not props or road wear, or not mine to decide)
Per piece the checker also lists items it does not fix: `building_sunk`, `edge_step`, `ground_step`, `garage_step`
(ground), `double_fence` (a stucco wall 0.9 m behind an iron fence, by design of the yards), `chainlink_street`,
`yard_open`, `park_empty`, `wire_in_building` (the wire pieces), `pole_no_wire` (m_gr_ad3sw, m_gr_e4s: poles with no wire
piece near), `sail_over_nothing`, `no_reason`, `empty_batch`. They are in each piece's `OUT/super/find/<piece>.faults.json`
when the check is run again.

## Not checked
No pictures were taken of the fixed pieces (the proof says what changed, not how it looks). The phone run is not part
of this job.
