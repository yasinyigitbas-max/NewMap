extends SceneTree
## Piece g_v1_j4ne (gritty edge growth, recipe v1): J Ave x 4th, NE: backs onto the locked industrial sample (i_se); J Ave turns industrial north of the alley.
## The site (junction, property lines, aprons, heights) is in review/grow_grt_blocks.json; the recipe in
## grt_grow_recipes.gd, the frame and the drape onto the streets in grt_grow_lib.gd. NOT locked (awaiting Yasin).
const R := preload("res://tools/city/pilot/pieces/grt_grow_recipes.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build("g_v1_j4ne")
	quit()
