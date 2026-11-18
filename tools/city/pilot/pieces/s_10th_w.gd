extends SceneTree
## Piece s_10th_w: 10th St west of Amber (|x| 23.5 - 56), downtown side street. Run once; never when locked.
## North side: the corner building's flank, then the small cafe (shade tree in front of it). South side: the pocket
## park's hedge line. Alley mouth at x -50..-44 (apron, no stalls 1.5 m either side).
const T := preload("res://tools/city/pilot/pieces/tenth_seg.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var r := T.build("s_10th_w", -1.0, 56.0, 999.0, [44.0, 50.0], {
		"wells": [[-1.0, 37.75], [1.0, 33.0]],
		"extra": [
			# [base, cond, side (z sign), |x|, offset from kerb, yaw]
			["tree_jacaranda_a", "normal", -1.0, 37.75, 0.75, 20.0],      # shade for the cafe front
			["tree_jacaranda_b", "normal", 1.0, 33.0, 0.75, 140.0],       # beside the park
			["prop_lamp_victorian", "worn", -1.0, 29.0, 0.6, 0.0],
			["prop_lamp_victorian", "worn", 1.0, 41.0, 0.6, 0.0],
			["prop_trash_receptacle", "worn", 1.0, 28.5, 0.75, 0.0],
			["prop_bike_rack", "worn", -1.0, 41.2, 0.75, 0.0],
		]})
	K.save_piece(r, "s_10th_w")
	quit()
