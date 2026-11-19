# Superchecker over the city: how one piece is done (19 Nov 2026)

Yasin's words for this job (in the chat): "run it on the entire city ... make judgement calls and fix everything,
including planting trees, removing old ones, filling their wells, and moving props, and when in doubt erase problematic
props"; then "be more prone to deleting then replacing, don't force it. Operate like a bug fixer of a game, be prone to
deleting rather than making a risky replacement decision about props"; "just delete them if you are unsure"; "this only
applies to props and road wear, no roads or surfaces should be deleted". His word covers installing the superchecker's
PROVEN fixes (PROOF RESULT PASS) into locked pieces and rooms for this job, nothing else.

## Two sessions, one list
`map_dc/coronado/city_kit/review/superchecker/ORDER.txt` is the list. The PC session works from the TOP down, the cloud
session from the BOTTOM up. Before starting a piece: `bash tools/city/super/run/claim.sh <piece> <who>`. Exit 0 = yours.
Exit 1 = claimed or done by the other session: you have met in the middle - STOP (write the report). Never touch a piece
claimed by the other session. Always work on branch `claude/festive-faraday-20ltx2` and pull before every push.

## One piece (after claiming it)
1. `bash tools/city/super/run/block.sh <piece>` - check, decide, apply, fix with proof, and if the fixed copy shows a new
   fault caused by a move, that item is erased instead (up to 3 rounds). Read its output: it must end on PROOF RESULT PASS.
   The decisions (`sc_review.py decide`): a short slide (<= 1.2 m) of a wall item along its own wall when that clears the
   opening; dishes on roofs, balcony things, play items on grass or gravel KEPT (false alarms); EVERYTHING ELSE that needs a
   new place is ERASED. Read `OUT/super/decisions/<piece>.txt`; edit a line if it is plainly wrong, then
   `python3 -I tools/city/super/sc_review.py apply <piece> <file>` and `sc.py fix <piece>` again.
2. `bash tools/city/super/run/rooms_and_trees.sh <piece>` - every open room line erased, each room fixed with proof; then
   the spots where the builder trees stood, tested.
3. Trees, BY HAND (docs/TREE_PLAN.md, its zone table): write `map_dc/coronado/city_kit/zoning/trees/<area>.json` (format:
   `grt_j4ne.json`, `ind_w600_n1600_se.json`), keeping a FEW of the old spots that test well, as the zone's rule says
   (gritty: 1-2 a block; industrial: only eucalyptus screens toward homes; residential yards: about half; apartments: one a
   court; city centre: few; waterfront: palms only). Every line has its WHY. `python3 -I tools/city/super/sc.py trees <area>`
   must say ok. No trees in the zone's rule -> no list.
4. `bash tools/city/super/run/phase_b.sh <piece> "<commit first line>"` - installs the piece, its tree piece and its proven
   rooms (relocks them), runs the lock test (must be RESULT PASS, else nothing is committed), commits, pulls, pushes.
   If the pull hits a conflict in `locked.json`, `city_grid_layout.json` or `review/superchecker/log.jsonl`: keep BOTH
   sides' entries (they are different pieces), `git add`, `git rebase --continue`, run the lock test again, push.

## The streets and junctions (second list, 19 Nov evening)
Yasin: "start the streets with the cloud session, again you start from top, they start from bottom, you meet in between".
The list is `review/superchecker/ORDER_STREETS.txt` (357 `s_*` / `j_*` pieces in the layout, by family). Same claims
folder, same steps 1-4 above, with these differences:
- The checker was first tried on `s_rs_b002_a`: its red kerb paint (15 cm strips on the kerb top, by a hydrant and a
  bus stop) read "paint on grass" because street pieces keep the kerb top in their grass / sidewalk surface. Fixed in
  `sc_find.py` (`kerb_paint`): a paint strip at most 25 cm wide running against the asphalt is kerb paint. Grime and
  pale patches on the parkway grass are still erased (road wear, Yasin: deleting it is fine). No road, kerb, sidewalk
  or ground surface is ever deleted.
- 36 street pieces stand in the layout more than once: a change to the piece shows at every place it stands. The
  tree list is in WORLD coordinates (grid frame, like every `t_*`), so it holds the trees of every place it stands.
- Trees, from docs/TREE_PLAN.md section 2 (one list per street piece, area = the piece name without `s_` / `j_`):
  residential streets (`rs`, `res`): parkway trees, runs of ONE species per block face, 20-30 m apart, gaps at
  driveways and lamps; pines and palms on hill streets, broadleaf on the flat. Ring boulevard (`rg`): palms; broadleaf
  only at park edges. Amber spine (`am`, `amber`) and arterials (`ar`): trees in wells on the shop side, palms
  alternating on Amber. Bridge (`br`), waterfront (`wf`, `wfd`): palms only, spaced. City centre (`cc`): wells on the
  wide pavements only. Strip: the palm parkway. Gritty (`grt`), industrial (`ind`): none. Junctions: usually none
  (sight lines at the corners). Keeping a builder tree's old spot is fine when the plan's spacing puts one there
  (Yasin: "if the plan puts new trees in old spots it is fine, stick to the plan"). A tree that stays in a WELL: write
  the list BEFORE `block.sh`, so its well is not paved. Every line has its why.

## Never
- run a piece's building script, rebuild a piece or room, change the land, delete roads or ground surfaces;
- write code that chooses places or trees for many items: the decide step only deletes or slides along a wall;
- work on a piece another session claimed.

## Setup in the cloud
`git fetch origin && git checkout claude/festive-faraday-20ltx2`; `apt-get update && apt-get install -y mesa-vulkan-drivers
xvfb`; `godot --headless --path . --import` (let it finish; never two Godots during an import). A wrapper
`/usr/local/bin/godot-x` = `exec xvfb-run -a godot --rendering-driver vulkan "$@"`; then
`export SC_GODOT=/usr/local/bin/godot-x SC_PY=python3 SC_GODOT_HEADLESS="godot --headless"`.
Prove the setup: `python3 -I tools/city/super/sc.py check g_v1_j4ne` must say the lock is unchanged and 0 findings with one
right answer (that piece is done). Then claim the LAST unclaimed piece of ORDER.txt and go upward.
