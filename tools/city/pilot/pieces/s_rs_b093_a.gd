extends SceneTree
## Piece s_rs_b093_a (resstd road kit, 17 Nov): Block b093 (6th St, (0.0, -800.0) -> (250.0, -800.0), 250 m), the leg
## from end A at (0, -800) [amber junction, pad 6.0]: 6th St off Amber in the city centre: the centre section
## (s_cc_10th) from the Amber tile (23.5, as j_amber_10th / j_cc), the centre's alley at 44-50, a bus shelter on the
## far side for the westbound / eastbound buses. Height: flat. Joint: meets the leg from the other end at the seam
## (125.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 23.5, "z1": 125.0, "start": "amber", "prof": [], "alleys": [[44.0, 50.0]], "zones": [[23.5, 125.0, "cc", "apt"]], "bus": true}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b093_a", SPEC)
	quit()
