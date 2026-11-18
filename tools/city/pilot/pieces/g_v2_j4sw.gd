extends SceneTree
## Piece g_v2_j4sw (gritty edge growth, zone rollout 19 Nov, recipe v2): J Ave x 4th, SW: the 4th St shop front toward the ring.
## The site (junction, property lines, aprons, heights) is in review/grow_grt_blocks.json; the recipe in
## grt_grow_recipes.gd, the frame and the drape onto the streets in grt_grow_lib.gd. NOT locked (awaiting Yasin).
const R := preload("res://tools/city/pilot/pieces/grt_grow_recipes.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build("g_v2_j4sw")
	quit()
