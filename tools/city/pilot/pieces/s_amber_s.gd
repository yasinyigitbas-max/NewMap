extends SceneTree
## Piece s_amber_s: Amber Ave south of 10th St (|z| 17.5 - 97.5). Run once; never re-run when locked.
## West side (SW block): pocket park (corner), bistro (terrace in the block), mixed-use stucco, hotel tower.
## East side (SE block): post office (corner, forecourt), boutique row, department store, seaside cafe.
const Seg := preload("res://tools/city/pilot/pieces/amber_seg.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var r := Seg.build("s_amber_s", 1.0, {
		"bus": true, "bus_at": 30.0,                       # southbound far-side stop, riders wait by the park
		"trees": [24.85, 38.25, 51.65, 65.05, 78.45, 91.85],
		"lamps": [31.55, 58.35, 85.15],
		"extra": [
			["prop_usps_collection_box", "worn", 1.0, 33.0, 0.75, -90.0],    # outside the post office
			["prop_park_bench", "worn", 1.0, 66.0, 4.15, -90.0],             # department store front
			["prop_park_bench", "worn", 1.0, 80.0, 4.15, -90.0],
			["prop_bike_rack", "worn", -1.0, 70.0, 0.75, 90.0],   # parallel to the kerb (17 Nov)               # hotel / mixed use
		]})
	K.save_piece(r, "s_amber_s")
	quit()
