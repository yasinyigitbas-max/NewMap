extends SceneTree
## Piece g_v3_j5nw (gritty edge growth, zone rollout 19 Nov, recipe v3): J Ave x 5th, NW: homes behind a phone shop and a laundromat.
## The site (junction, property lines, aprons, heights) is in review/grow_grt_blocks.json; the recipe in
## grt_grow_recipes.gd, the frame and the drape onto the streets in grt_grow_lib.gd. NOT locked (awaiting Yasin).
const R := preload("res://tools/city/pilot/pieces/grt_grow_recipes.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build("g_v3_j5nw")
	quit()
