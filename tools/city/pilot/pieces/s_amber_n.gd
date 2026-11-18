extends SceneTree
## Piece s_amber_n: Amber Ave north of 10th St (|z| 17.5 - 97.5). Run once; never re-run when locked.
## West side fronts (NW block): brick corner, Orange row, bakery, bar, brick row, surf shop, realty.
## East side fronts (NE block): Spanish arcade (corner), village theatre, Orange arcade, brick row.
const Seg := preload("res://tools/city/pilot/pieces/amber_seg.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var r := Seg.build("s_amber_n", -1.0, {
		"bus": true, "bus_at": 36.5,                       # northbound far-side stop, by the theatre but clear of its doors
		"trees": [24.85, 38.25, 51.65, 65.05, 78.45, 91.85],   # stall mid-points, every second stall
		"lamps": [31.55, 58.35, 85.15],                    # between trees
		"extra": [
			# [base, cond, side, |z|, offset from kerb, yaw]
			["prop_newspaper_box_red", "worn", -1.0, 22.45, 0.75, 90.0],     # by the corner shop
			["prop_newspaper_box_blue", "worn", -1.0, 23.0, 0.75, 90.0],
			["prop_bike_rack", "worn", -1.0, 44.9, 0.75, 90.0],   # parallel to the kerb (17 Nov)               # bakery customers
			["prop_park_bench", "worn", -1.0, 48.0, 4.15, 90.0],             # against the bakery front, facing the street
		]})
	K.save_piece(r, "s_amber_n")
	quit()
