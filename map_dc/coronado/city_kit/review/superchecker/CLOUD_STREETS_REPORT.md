# Superchecker over the streets - the cloud session's report (19-20 Nov 2026)

Status: DONE from the bottom of `ORDER_STREETS.txt` up; met the sessions working from the top (pc-session, cloud-top).
Every piece below has PROOF RESULT PASS and a lock test RESULT PASS before its commit; all are pushed on
`claude/festive-faraday-20ltx2`.

## Pieces
250 claimed, 249 done: 110 residential streets (`s_rs_*`), 18 residential junctions (`j_rs_*`), 95 ring boulevard
pieces (`s_rg_*`), 21 ring junctions (`j_rg_*`), the strip (`s_strip_art`, `s_strip_side`, `j_strip`), the waterfront
drive (`s_wf`, `s_wfd`). Left unchecked on purpose: `s_rg_nw_b071` (below).

## What changed (from the fix lists)
- 2,241 builder trees out (Yasin: every builder tree goes); the wells among them paved over (97 well lines, the fixer
  skips the ones that turn out to be beds). No tree stays in a well.
- 1,053 trees back BY HAND, only on parkway grass or planting beds, one written list per piece (`zoning/trees/<area>.json`,
  every line with its why), each `sc.py trees` ok:
  - ring boulevard 542 (palms only: fan and queen palms, one species a side, 20-30 m, staggered; the median row kept on
    `s_rg_nw_b036`), residential streets 487 (one species a side, 20-30 m; broadleaf on the flat where the view allows,
    pines / palms on the slopes and where the broadleaf room in view was used up), strip 12, waterfront drive 12.
  - species: fan palm 422, queen palm 312, jacaranda 112, Torrey pine 97, coral 70, magnolia 37, Canary date palm 3.
  - The in-view limit (8 broadleaf / 12 trees within 60 m, counting every list) decided the count on most streets: many
    have 2-5 trees, a few 1 or none (all-well streets and full stretches have no list).
- 791 wear marks off their surface removed; 561 colliders added (mostly the plaza beds' agaves and birds of paradise,
  sized to each plant).
- 29 props erased in doubt (Yasin: delete when unsure): 15 bike racks standing across the walk, 4 bus-stop benches in
  front of shop doors / windows, 4 mail collection boxes narrowing the walk, 2 bus shelters (one left 1.0 m of a 5.4 m
  walk, one stood in front of a condo patio), 2 signal mast arms in a lane mouth (`j_rg_se_e0_s340`,
  `j_rg_nw_w952_n1200`: the traffic code does not use these props, but the pole is gone - look), 1 bin, 1 shopping cart.
- 4 props set down onto sloping ground (bus stop signs, a cobra lamp; checked under each foot).

## Kept against the checker (false findings, each tested on the piece)
- Kerb inlets "sunk": the inlet's origin is at the kerb face at road level, the grate in the gutter; the check read the
  kerb top behind it. Kept wherever road-level asphalt lies within 0.4 m (the PC session then fixed the finder).
- Signal masts "hanging": the overhead arm's footprint, the foot stands flush on the corner sidewalk (`j_strip`).
- Benches and a bin on the pier head deck "over no ground" (`s_wf`): a pier deck is a prop, not a ground surface.
- A parking meter at a paved well's rim (`s_rg_b045`): lowering it into the old well bottom would have sunk it.

## Tool changes and faults found
- `sc_trees.py check` now reads every place a piece stands (it read only the first, so multi-place lists failed).
- FIXER FAULT, open: `remove_decal` re-saves the wear mesh and Godot re-encodes sideways marks' normals (~0.0002); the
  proof rightly fails (`s_rg_nw_b071`'s twin case was `s_rg_nw_b163_1`: its 4 off-surface marks were kept instead).
  Real fix in the HOWTO.
- `s_rg_nw_b071` NOT CHECKED: its six ground surfaces lost their names in commit ce6fff84 ("Emergency Drive off 3rd
  St"); the checker is blind there (it wanted to erase all 384 wear marks). Give the names back from its twin
  `s_rg_nw_b072`, then run it. Claimed by cloud-session so nobody runs it blind.

## Not done / not checked
- No pictures were taken of the street pieces: the proofs show what changed, not how it looks.
- Trees back against the builder count on these pieces: residential streets 487 of 1,062 (45 %; plan about 63 %), ring
  boulevard 542 of 1,149 (47 %; plan about 85 %), strip 12 of 17, waterfront drive 12 of 13. The in-view limit, with
  the yard lists from the block pass and the neighbouring pieces, is what held the street counts down.
- Pieces claimed by pc-session but not done: s_am_b041_b, s_am_b042_a, s_am_fill_cc, s_am_fill_hs (not mine to touch).
