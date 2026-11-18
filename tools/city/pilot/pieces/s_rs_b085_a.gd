extends SceneTree
## Piece s_rs_b085_a (resstd road kit, 17 Nov): Block b085 (5th St, (0.0, -1000.0) -> (250.0, -1000.0), 250 m), the
## leg from end A at (0, -1000) [amber junction, pad 12.0]: 5th St, a residential street (mixed street trees, no
## centre line). Height: the block rises -6.0 m from this end to the other (max grade 4.4 %). Joint: meets the leg
## from the other end at the seam (125.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 23.5, "z1": 125.0, "start": "amber", "prof": [[23.5, 230.0, -6.0]], "alleys": [[44.0, 50.0]], "zones": [[23.5, 125.0, "res", ""]], "bus": false}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b085_a", SPEC)
	quit()
