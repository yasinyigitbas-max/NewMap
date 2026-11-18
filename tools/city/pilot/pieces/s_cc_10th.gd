extends SceneTree
## Piece s_cc_10th (city centre): a 10th St leg with the city-centre cross-section - no parking, kerb on the lane edge,
## 6.4 m sidewalks under the tall blocks. Used on both legs (yaw 0 west, yaw 180 east), so street furniture only:
## trees in wells, lamps, a bin, a bike rack, a bench; the alley mouth at |x| 44-50. Run once; never when locked.
const T := preload("res://tools/city/pilot/pieces/tenth_seg.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	S.A_KERB = S.A_LANE; S.T_KERB = S.T_LANE
	var r := T.build("s_cc_10th", -1.0, 56.0, 999.0, [44.0, 50.0], {
		"no_park": [[0.0, 999.0]], "walk_wear": true,
		"wells": [[-1.0, 29.0], [-1.0, 39.0], [1.0, 29.0], [1.0, 39.0]],
		"extra": [
			# [base, cond, side (z sign), |x|, offset from kerb, yaw]
			["tree_jacaranda_a", "normal", -1.0, 29.0, 0.75, 20.0],
			["tree_jacaranda_b", "normal", -1.0, 39.0, 0.75, 80.0],
			["tree_jacaranda_b", "normal", 1.0, 29.0, 0.75, 140.0],
			["tree_jacaranda_a", "normal", 1.0, 39.0, 0.75, 200.0],
			["prop_lamp_victorian", "worn", -1.0, 34.0, 0.6, 0.0],
			["prop_lamp_victorian", "worn", 1.0, 34.0, 0.6, 0.0],
			["prop_trash_receptacle", "worn", 1.0, 25.5, 0.75, 0.0],
			["prop_bike_rack", "worn", -1.0, 25.5, 0.75, 0.0],   # parallel to the kerb
			["prop_park_bench", "worn", 1.0, 42.0, 1.0, 180.0],        # faces the street,
			["prop_lamp_victorian", "worn", -1.0, 53.0, 0.6, 0.0],
		]})
	K.save_piece(r, "s_cc_10th")
	quit()
