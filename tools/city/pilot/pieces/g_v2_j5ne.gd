extends SceneTree
## Piece g_v2_j5ne (gritty edge growth, recipe v2): J Ave x 5th, NE: 5th St shops facing the sample (bus route on 5th St).
## The site (junction, property lines, aprons, heights) is in review/grow_grt_blocks.json; the recipe in
## grt_grow_recipes.gd, the frame and the drape onto the streets in grt_grow_lib.gd. NOT locked (awaiting Yasin).
const R := preload("res://tools/city/pilot/pieces/grt_grow_recipes.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build("g_v2_j5ne")
	quit()
