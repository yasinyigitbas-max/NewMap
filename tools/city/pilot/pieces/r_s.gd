extends SceneTree
## Piece r_s: residential lots south of 10th St on the hill (6 lots, x 56..146). Run once; never when locked.
## Houses and their reasons are in tools/city/pilot/site.gd LOTS; the lot logic in res_block.gd.
const R := preload("res://tools/city/pilot/pieces/res_block.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	K.save_piece(R.build("r_s", 1.0), "r_s")
	quit()
