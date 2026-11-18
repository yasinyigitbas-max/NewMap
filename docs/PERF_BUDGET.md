# Performance budget (what the new map must stay under)

## The game's gate (copied 18 Nov from coronado-source; it runs there, on the game, after integration)
`docs/perf_budget_game/`: `perf_budget.sh` (the merge gate), `perf_budget.gd` (the probe), `tri_budget.gd` (per-group
draw / triangle census). They load the game's scenes and spots, so they do not run in this repo: kept here so the
numbers and the method are at hand while building.
- At every busy spot, High preset, mid-range phone (Redmi): **<= 150 draw calls, <= 300k triangles, <= 1 GB video
  memory** (`BUDGET` in perf_budget.gd). Measured with a real renderer (xvfb + opengl3), one spot per process.

## The kit's own budgets
`docs/kit_branch/KIT_BUDGET.md` (from Yasin's assets branch): per-model triangle / texture budgets of the kit.
City-kit rules on top (JOB_BOARD "How we work" 8): buildings 1.5-5k tris near, cables ~700 tris per area in one draw,
props within the kit budgets. Preview shot draw counts are inflated by the preview cars (the game batches them).
Nothing has been measured on the Redmi yet: the phone run comes last (Yasin).

## Other docs from the assets branch (`docs/kit_branch/`)
CCBY_BRIEF.md (CC-BY credits the game must show for the Sketchfab models), HANDOVER.md + tools_city review notes +
maps_README.md: the 14 Nov "Plan C" generator pipeline that the hand-made kit replaced (reference only; its 109 MB of
data and scripts were not copied).
