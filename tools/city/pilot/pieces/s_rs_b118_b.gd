extends SceneTree
## Piece s_rs_b118_b (resstd road kit, 17 Nov): Block b118 (10th St, (-600.0, 0.0) -> (-400.0, 0.0), 200 m), the leg
## from end B at (-400, 0) [resstd junction, pad 6.0]: 10th St, a residential street (mixed street trees, no centre
## line). Height: the block rises +6.0 m from this end to the other (max grade 5.6 %). Joint: meets the leg from the
## other end at the seam (100.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 100.0, "start": "j", "prof": [[20.0, 180.0, 6.0]], "alleys": [[54.0, 60.0]], "zones": [[20.0, 100.0, "res", ""]], "bus": false}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b118_b", SPEC)
	quit()
