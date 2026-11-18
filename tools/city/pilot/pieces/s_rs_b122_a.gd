extends SceneTree
## Piece s_rs_b122_a (resstd road kit, 17 Nov): Block b122 (10th St, (250.0, 0.0) -> (500.0, 0.0), 250 m), the leg
## from end A at (250, 0) [resstd junction, pad 10.0]: 10th St, a residential street (mixed street trees, no centre
## line). Height: the block rises -6.0 m from this end to the other (max grade 4.3 %). Joint: meets the leg from the
## other end at the seam (125.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 125.0, "start": "j", "prof": [[20.0, 230.0, -6.0]], "alleys": [[54.0, 60.0]], "zones": [[20.0, 125.0, "res", ""]], "bus": false}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b122_a", SPEC)
	quit()
