extends SceneTree
## Piece g_v1_g4ne (gritty edge growth, recipe v1): G Ave x 4th, NE: industrial extension to the north (3rd St), the yards carry on.
## The site (junction, property lines, aprons, heights) is in review/grow_grt_blocks.json; the recipe in
## grt_grow_recipes.gd, the frame and the drape onto the streets in grt_grow_lib.gd. NOT locked (awaiting Yasin).
const R := preload("res://tools/city/pilot/pieces/grt_grow_recipes.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build("g_v1_g4ne")
	quit()
